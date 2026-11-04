@
@ gbass.s -- GBASS (Game Boy Advance Sound System) by Stephane Hockenhull, 2000
@ Reassemblable disassembly of the distributed object gbass.o (ELF32 ARM, REL).
@
@ Rebuild:   arm-none-eabi-as -mcpu=arm7tdmi -mthumb-interwork -o gbass.o gbass.s
@            (needs gbass_agbdefs.inc and gbass_wavedata.bin beside it)
@ Check:     python3 verify_gbass.py original/gbass.o gbass.o   -> RESULT: IDENTICAL
@            (every section is byte-identical after relocation; all 1547 symbols match)
@
@ The object is an `ld -r` of four inputs, kept in this order:
@    .text 0x0000-0x028F  hand-written ARM mixer (runs from IWRAM after GBASS_Init copies it)
@    .text 0x0290-0x48DF  gbass.c  (gcc 2.x, -mthumb, player + API)
@    .text 0x48E0-0x50B3  digi.c   (gcc 2.x, -mthumb, DirectSound/DMA/timer layer)
@    .rodata/.data/RAM    converter output: pitch tables, samples, instruments, songs
@ Function names are the original symbols; everything else (struct fields, labels
@ .Lxxxxx = offset in .text, comments) is reconstructed.
@
@ ------------------------------------------------------------------------------
@ gbass_module (.data 0x7B6EC, 80 bytes) -- the only link between code and content
@   +00 u32 default audio rate (1/2/4/8 = 64/128/256/512 samples per frame)  = 4
@   +04 u32 song count            +08 Song*        gbass_SongTable
@   +0C u32 instrument count      +10 u8**         gbass_InstrumentTable
@   +14 u8* instrument types      +18 u32 wave count   +1C Wave* gbass_WaveTable
@   +20 u32 digital channel pairs +24 Mixer[2n]    music mixers   (.medram2)
@   +28 Mixer[2n] sfx mixers (.medram3)            +2C PairBlock[n] digital channels
@   +30 u32 mix buffers           +34 s8[64][b]    mix buffers    (.medram1)
@   +38 u8[b] buffer modes        +3C PairBlock[2] GB channels 0-3
@   +40 s8[] DMA buffers          +44 u8* silence  (script ptr for idle levels)
@   +48 IWRAM area for the ARM routines            +4C u32 copy mask (bit n = Mix_Table entry n)
@
@ gbass_ram (.slowram 0x10, 112 bytes)
@   +00 DMA half being played (0 or rate; DMACriticalProcess flips it)
@   +04 cleared by Init/AudioRateDivide, otherwise unused
@   +08 API lock depth          +0C GBASS_Process calls deferred while locked
@   +10 song master volume 31..256    +14 sfx master volume 0..256
@   +18 -> Mix_Buffers (IWRAM)  +1C -> CrossMix   +20 -> Mov_None
@   +24 -> Mov_2MOD (buffer mode bit3 clear)      +28 -> Mov_2MOD copy (bit3 set)
@   +2C u16[4], +38 u16[4] GB per-channel words (reset to 0x200; ch3 to 0)
@   +34 u8[4] GB music channel volume, +40 u8[4] GB sfx channel volume (0xFF)
@   +44 flags: b0 wave-RAM bank, b1 single-buffer direct mix, b2 headphone cross-mix,
@              b3 reverb clear request, b4 reverb on, b5-8 reverb mode, b14 no-music mode
@   +48 song time (ticks)       +4C current rate      +50 audio mode (buffers mixed)
@   +54 active channel pairs    +58 u8 rate shift     +59 u8 next sfx id
@   +5C transpose (1/16 semitone, -768..768)          +60 song speed (16.16)
@   +64 tick accumulator (16.16)                      +68 tempo factor (16.16, cmd 97)
@   +6C u8 NR51 shadow (current) +6D u8 NR51 shadow (music) +6E u8 NR10 shadow (music)
@   +6F u8 mask of GB channels whose music registers must be restored
@
@ PairBlock (96 bytes, two channels): channel c at +32c, then status records
@   channel: four 8-byte script levels  L0 song track  L1 pattern  L2 music instrument
@            L3 sfx instrument;  level = {u16 wait, u8 loop count, u8 release, u8* pc}
@            (L1.+3 = byte +11 doubles as the sfx tag: priority<<6 | id)
@   +64/+72 music status ch0/ch1, +80/+88 sfx status ch0/ch1:
@            {u8 note (0-191, 1/16 semitones), u8 octave, u8 wave, u8 effect,
@             u16 effect param A, u16 effect param B}
@
@ Mixer (32 bytes, MIX_* equates): +00 sample ptr  +04 volume 0-255  +08 pos 16.16
@   +0C end 16.16  +10 speed 16.16 (note ratio)  +14 loop length 16.16 (== speed: one-shot)
@   +18 u16 channel volume 0-256  +1A u16 master volume  +1C wave rate 16.16

	.syntax unified
	.cpu	arm7tdmi
	.include "gbass_agbdefs.inc"

	.text
	.arm

@
@ GBASS_Mix_Table: five {start, end} pairs naming the ARM routines that GBASS_Init
@ copies to IWRAM (gbass_module+48) when the matching bit of gbass_module+4C is set:
@   0 Mix_Buffers  1 CrossMix  2 Mov_None  3 Mov_2MOD  4 Mov_2MOD (second copy)
	.global	GBASS_Mix_Table
GBASS_Mix_Table:
	.4byte	GBASS_Mix_Buffers
	.4byte	GBASS_CrossMix
	.4byte	GBASS_CrossMix
	.4byte	GBASS_Mix_BLOCKEND
	.4byte	GBASS_Mov_None
	.4byte	GBASS_Mov_2MOD
	.4byte	GBASS_Mov_2MOD
	.4byte	GBASS_Mix_Buffers
	.4byte	GBASS_Mov_2MOD
	.4byte	GBASS_Mix_Buffers
	.4byte	0x00000000	@ andeq	r0, r0, r0

@
@ GBASS_Mov_None(r2 = dest): writes 64 zero bytes (silent buffer). ARM, IWRAM.
GBASS_Mov_None:
	mov	ip, #64
	eor	r3, r3, r3
GBASS_Mov_None_loop:
	strb	r3, [r2], #1
	subs	ip, ip, #1
	bne	GBASS_Mov_None_loop
	bx	lr
GBASS_Mov_NoneEnd:

@
@ GBASS_Mov_2MOD(r0 = Mixer A, r1 = Mixer B, r2 = dest s8[64]) -- the voice mixer.
@ Mixes two voices into one 64-byte buffer:
@   vol  = (vol * cvol * mvol) >> 16          (per voice)
@   step = (speed * rate) >> 16               (16.16 sample increment, smull)
@   out  = (A[pos>>16]*volA + B[pos>>16]*volB) >> 9
@ At pos >= end the position is pulled back by the loop length; a one-shot voice
@ (loop == speed) is pulled back by one step, so it sits on its last sample.
@ Switches to Undefined mode (CPSR = 0x1B) to use the banked r13_und as a work
@ register, so the caller must not be in Undefined mode (see GBASS docs).
GBASS_Mov_2MOD:
	push	{r4, r5, r6, r7, r8, r9, sl, fp}
	mrs	r4, CPSR
	str	r4, savepsr
	bic	r4, r4, #31
	orr	r4, r4, #27
	msr	CPSR_fc, r4
	str	r2, savedest
	mov	lr, #64
	ldm	r1, {r7, r8, r9, sl, fp}
	ldm	r0, {r2, r3, r4, r5, r6}
	ldrh	ip, [r0, #24]
	mul	sp, ip, r3
	ldrh	ip, [r0, #26]
	mul	r3, ip, sp
	asr	r3, r3, #16
	ldrh	ip, [r1, #24]
	mul	sp, ip, r8
	ldrh	ip, [r1, #26]
	mul	r8, ip, sp
	asr	r8, r8, #16
	ldr	ip, [r0, #28]
	smull	r6, sp, ip, r6
	lsr	r6, r6, #16
	orr	r6, r6, sp, lsl #16
	ldr	ip, [r1, #28]
	smull	fp, sp, ip, fp
	lsr	fp, fp, #16
	orr	fp, fp, sp, lsl #16
	ldr	ip, [r0, #20]
	ldr	sp, [r0, #16]
	cmp	sp, ip
	strne	ip, loop1
	streq	r6, loop1
	ldr	ip, [r1, #20]
	ldr	sp, [r1, #16]
	cmp	sp, ip
	strne	ip, loop2
	streq	fp, loop2
	str	r1, saver1
	ldr	r1, savedest
GBASS_Mov_2MOD_loop:
	lsr	ip, r4, #16
	ldrsb	ip, [r2, ip]
	mul	sp, ip, r3
	lsr	ip, r9, #16
	ldrsb	ip, [r7, ip]
	mla	sp, ip, r8, sp
	asr	sp, sp, #9
	strb	sp, [r1], #1
	add	r4, r4, r6
	cmp	r4, r5
	ldrcs	ip, loop1
	subcs	r4, r4, ip
	add	r9, r9, fp
	cmp	r9, sl
	ldrcs	ip, loop2
	subcs	r9, r9, ip
	subs	lr, lr, #1
	bne	GBASS_Mov_2MOD_loop
	str	r4, [r0, #8]
	ldr	r1, saver1
	str	r9, [r1, #8]
	ldr	r0, savepsr
	msr	CPSR_fc, r0
	pop	{r4, r5, r6, r7, r8, r9, sl, fp}
	bx	lr
savepsr:
	.4byte	0x00000000	@ andeq	r0, r0, r0
loop1:
	.4byte	0x00000000	@ andeq	r0, r0, r0
loop2:
	.4byte	0x00000000	@ andeq	r0, r0, r0
savedest:
	.4byte	0x00000000	@ andeq	r0, r0, r0
saver1:
	.4byte	0x00000000	@ andeq	r0, r0, r0

@
@ GBASS_Mix_Buffers(r0 = s8 buffers[n][64], r1 = dest s8[64], r2 = n 1..8)
@ Sums n 64-byte buffers sample by sample with saturation to -128..127. The add
@ chain is unrolled 8x; the routine patches its own entry instruction (mod_load)
@ to start the chain at buffer n, then restores it (mod_add). Must run from RAM.
GBASS_Mix_Buffers:
GBASS_Mov_2MODEnd:
	push	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r8, #64
	mov	r7, #128
	rsb	r7, r7, #0
	lsl	r6, r2, #6
	sub	r6, r6, #1
	add	r5, pc, #16
	rsb	r2, r2, #8
	add	r5, r5, r2, lsl #3
	ldr	r3, mod_load
	str	r3, [r5]
	bx	r5
GBASS_Mix_Buffers_loop:
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	ldrsb	r4, [r0], #64
	add	r3, r3, r4
	eor	r4, r3, r3, lsr #1
	ands	r4, r4, #3968
	blne	clip
	strb	r3, [r1], #1
	sub	r0, r0, r6
	subs	r8, r8, #1
	bxne	r5
	ldr	r3, mod_add
	str	r3, [r5]
	pop	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
	bx	lr
clip:
	cmp	r3, #128
	movge	r3, #127
	cmplt	r3, r7
	movlt	r3, #128
	bx	lr
mod_load:
	.4byte	0xe0d034d0	@ ldrsb	r3, [r0], #64
mod_add:
	.4byte	0xe0833004	@ add	r3, r3, r4
GBASS_Mix_BuffersEnd:

@
@ GBASS_CrossMix(r0 = left s8[], r1 = right s8[], r2 = rate)
@ Headphone filter: L' = L + R/2, R' = R + L/2, saturated, over rate*64 samples.
GBASS_CrossMix:
	push	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
	mov	r3, #64
	mul	r8, r3, r2
	mov	r7, #128
	rsb	r7, r7, #0
GBASS_CrossMix_loop:
	ldrsb	r4, [r0]
	ldrsb	r3, [r1]
	add	r2, r4, r3, asr #1
	add	r3, r3, r4, asr #1
	eor	r4, r2, r2, lsr #1
	ands	r4, r4, #3968
	blne	cclip2
	eor	r4, r3, r3, lsr #1
	ands	r4, r4, #3968
	blne	cclip
	strb	r2, [r0], #1
	strb	r3, [r1], #1
	subs	r8, r8, #1
	bne	GBASS_CrossMix_loop
	pop	{r4, r5, r6, r7, r8, r9, sl, fp, lr}
	bx	lr
cclip:
	cmp	r3, #128
	movge	r3, #127
	cmplt	r3, r7
	movlt	r3, #128
	bx	lr
cclip2:
	cmp	r2, #128
	movge	r2, #127
	cmplt	r2, r7
	movlt	r2, #128
	bx	lr
GBASS_CrossMixEnd:

@
@ GBASS_Mix_BLOCKEND: bx lr -- end marker of the copied block, and the default
@ (do-nothing) target for the mixer pointers before GBASS_Init copies the code.
	.global	GBASS_Mix_BLOCKEND
GBASS_Mix_BLOCKEND:
	bx	lr

	.thumb
	@ ---- start of a gcc2-compiled C unit (original object has a local .gcc2_compiled. marker here) ----

@
@ u16 GBASS_GBTranspose(note, octave): applies the song transpose (ram+5C) and
@ returns the GB frequency register value 2048 - (gb_notes[note] scaled by octave).
@ Octave is clamped to 3..8 (C3 = 65 Hz ... B8). gb_notes[] = 131072/f for octave 5.
	.global	GBASS_GBTranspose
	.thumb_func
	.type	GBASS_GBTranspose, %function
GBASS_GBTranspose:
	adds	r2, r0, #0
	adds	r3, r1, #0
	ldr	r0, .L002ac
	ldr	r0, [r0, #92]
	adds	r2, r2, r0
	ldr	r1, .L002b0
	cmp	r2, #0
	bge.n	.L002b8
.L002a0:
	subs	r3, #1
	adds	r2, #192
	cmp	r2, #0
	blt.n	.L002a0
	b.n	.L002b8
	movs	r0, r0
.L002ac:
	.4byte	gbass_ram
.L002b0:
	.4byte	gb_notes
.L002b4:
	adds	r3, #1
	subs	r2, #192
.L002b8:
	cmp	r2, #191
	bgt.n	.L002b4
	cmp	r3, #2
	bgt.n	.L002c4
	movs	r3, #3
	movs	r2, #0
.L002c4:
	cmp	r3, #8
	ble.n	.L002cc
	movs	r3, #8
	movs	r2, #191
.L002cc:
	cmp	r3, #4
	bgt.n	.L002de
	lsls	r0, r2, #1
	adds	r0, r0, r1
	movs	r1, #5
	subs	r1, r1, r3
	ldrh	r0, [r0, #0]
	lsls	r0, r1
	b.n	.L002e8
.L002de:
	lsls	r0, r2, #1
	adds	r0, r0, r1
	subs	r1, r3, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
.L002e8:
	adds	r1, r0, #0
	movs	r2, #128
	lsls	r2, r2, #4
	adds	r0, r2, #0
	subs	r0, r0, r1
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	bx	lr

@
@ u32 GBASS_DigiTranspose(note, octave): transposed digital pitch,
@ digi_notes[note] << (octave-5)  (octave clamped 0..9); digi_notes[n] = 2^(n/192) 16.16.
	.global	GBASS_DigiTranspose
	.thumb_func
	.type	GBASS_DigiTranspose, %function
GBASS_DigiTranspose:
	push	{r4, lr}
	adds	r2, r0, #0
	adds	r3, r1, #0
	ldr	r0, .L00314
	ldr	r0, [r0, #92]
	adds	r2, r2, r0
	ldr	r4, .L00318
	cmp	r2, #0
	bge.n	.L00320
.L0030a:
	subs	r3, #1
	adds	r2, #192
	cmp	r2, #0
	blt.n	.L0030a
	b.n	.L00320
.L00314:
	.4byte	gbass_ram
.L00318:
	.4byte	digi_notes
.L0031c:
	adds	r3, #1
	subs	r2, #192
.L00320:
	cmp	r2, #191
	bgt.n	.L0031c
	cmp	r3, #0
	bge.n	.L0032c
	movs	r3, #0
	movs	r2, #0
.L0032c:
	cmp	r3, #9
	ble.n	.L00334
	movs	r3, #9
	movs	r2, #191
.L00334:
	cmp	r3, #4
	bgt.n	.L00346
	lsls	r1, r2, #2
	adds	r1, r1, r4
	movs	r0, #5
	subs	r0, r0, r3
	ldr	r2, [r1, #0]
	lsrs	r2, r0
	b.n	.L00350
.L00346:
	lsls	r0, r2, #2
	adds	r0, r0, r4
	subs	r1, r3, #5
	ldr	r2, [r0, #0]
	lsls	r2, r1
.L00350:
	adds	r0, r2, #0
	pop	{r4}
	pop	{r1}
	bx	r1

@
@ int GBASS_GetNewSFXID(void): next 6-bit id from ram+59 that is not in use as the
@ tag (byte +11 / +43) of any digital channel.
	.global	GBASS_GetNewSFXID
	.thumb_func
	.type	GBASS_GetNewSFXID, %function
GBASS_GetNewSFXID:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	ldr	r0, .L003ec
	adds	r0, #89
	mov	r9, r0
	movs	r2, #63
	mov	sl, r2
	movs	r0, #1
	negs	r0, r0
	mov	r8, r0
	ldr	r2, .L003f0
	mov	ip, r2
.L00376:
	movs	r7, #0
	mov	r0, r9
	ldrb	r1, [r0, #0]
	adds	r0, r1, #1
	mov	r2, r9
	strb	r0, [r2, #0]
	mov	r4, sl
	ands	r4, r1
	movs	r5, #0
	ldr	r0, .L003ec
	ldr	r2, [r0, #84]
	subs	r2, #1
	cmp	r2, r8
	beq.n	.L003d6
	mov	r0, ip
	ldr	r1, [r0, #44]
	mov	r0, sl
	ldrb	r1, [r1, #11]
	ands	r0, r1
	cmp	r0, r4
	beq.n	.L00376
.L003a0:
	mov	r0, ip
	ldr	r3, [r0, #44]
	lsls	r1, r5, #1
	adds	r1, r1, r5
	lsls	r1, r1, #5
	adds	r1, r1, r3
	adds	r1, #43
	movs	r6, #63
	adds	r0, r6, #0
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, r4
	beq.n	.L00376
	adds	r5, #1
	subs	r2, #1
	cmp	r2, r8
	beq.n	.L003d6
	lsls	r0, r5, #1
	adds	r0, r0, r5
	lsls	r0, r0, #5
	adds	r0, r0, r3
	adds	r1, r6, #0
	ldrb	r0, [r0, #11]
	ands	r1, r0
	cmp	r1, r4
	bne.n	.L003a0
	movs	r7, #1
.L003d6:
	cmp	r7, #0
	bne.n	.L00376
	adds	r0, r4, #0
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0
.L003ec:
	.4byte	gbass_ram
.L003f0:
	.4byte	gbass_module

@
@ GBASS_Process_GB(Status *st, Channel *ch, int gbchan 0-3, int level 0|3)
@ One tick of a GB (PSG) channel: runs the script levels (0..2 for music, 3 for a
@ sound effect), then the effect (arpeggio/porta/slide/vibrato), and finally writes
@ the PSG registers for the channel. Command set: see GBASS_Process_Digital.
@ GB specifics: 'wave n' = duty (ch0/1) or noise width; on ch2 'wave n' uploads
@ 32 samples of digital wave n as 4-bit data into the idle wave-RAM bank and flips
@ banks; 'vol' is the NRx2 envelope byte (scaled by the channel volume); 9x
@ pan/sweep/trigger commands drive NR51/NR10/NRx4. A music tick does not touch the
@ registers while a sound effect owns the channel (ch+24 != 0); when the effect
@ ends the channel is flagged in ram+6F and the music registers are rewritten.
	.global	GBASS_Process_GB
	.thumb_func
	.type	GBASS_Process_GB, %function
GBASS_Process_GB:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #20
	adds	r7, r0, #0
	adds	r6, r1, #0
	mov	sl, r2
	str	r3, [sp, #0]
	movs	r0, #0
	str	r0, [sp, #4]
	ldr	r2, .L00484
	adds	r4, r2, #0
	adds	r4, #111
	ldrb	r1, [r4, #0]
	adds	r0, r1, #0
	mov	r3, sl
	asrs	r0, r3
	movs	r3, #1
	ands	r0, r3
	str	r2, [sp, #16]
	cmp	r0, #0
	beq.n	.L0043e
	movs	r0, #13
	str	r0, [sp, #4]
	ldrb	r2, [r7, #0]
	mov	r9, r2
	ldrb	r0, [r7, #1]
	str	r0, [sp, #12]
	adds	r0, r3, #0
	mov	r2, sl
	lsls	r0, r2
	bics	r1, r0
	strb	r1, [r4, #0]
	movs	r3, #0
	str	r3, [sp, #8]
.L0043e:
	ldr	r4, [sp, #0]
	mov	r8, r4
.L00442:
	mov	r1, r8
	lsls	r0, r1, #3
	adds	r1, r0, r6
	ldrh	r0, [r1, #0]
	cmp	r0, #0
	bne.n	.L00452
	bl	.L00c52
.L00452:
	subs	r0, #1
	strh	r0, [r1, #0]
	lsls	r0, r0, #16
	cmp	r0, #0
	beq.n	.L00460
	bl	.L00c52
.L00460:
	mov	r3, r8
	lsls	r2, r3, #3
	adds	r1, r2, r6
	ldr	r0, [r1, #4]
	ldrb	r3, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsrs	r0, r3, #4
	adds	r4, r2, #0
	cmp	r0, #9
	bls.n	.L0047a
	bl	.L00c52
.L0047a:
	lsls	r0, r0, #2
	ldr	r1, .L00488
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L00484:
	.4byte	gbass_ram
.L00488:
	.4byte	.L0048c
.L0048c:
	.4byte	.L004b4
	.4byte	.L00538
	.4byte	.L0056c
	.4byte	.L005e0
	.4byte	.L0060c
	.4byte	.L00692
	.4byte	.L006a8
	.4byte	.L0072c
	.4byte	.L00828
	.4byte	.L0099a
.L004b4:
	cmp	r3, #0
	bne.n	.L004c6
	adds	r2, r4, r6
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	strh	r0, [r2, #0]
	adds	r1, #1
	str	r1, [r2, #4]
	b.n	.L004ca
.L004c6:
	adds	r0, r4, r6
	strh	r3, [r0, #0]
.L004ca:
	adds	r0, r4, r6
	ldrh	r0, [r0, #0]
	cmp	r0, #0
	beq.n	.L004d4
	b.n	.L00c52
.L004d4:
	ldr	r4, [sp, #0]
	cmp	r4, #3
	beq.n	.L004dc
	b.n	.L00c52
.L004dc:
	ldr	r1, [sp, #16]
	adds	r1, #111
	movs	r0, #1
	mov	r2, sl
	lsls	r0, r2
	ldrb	r3, [r1, #0]
	orrs	r0, r3
	strb	r0, [r1, #0]
	ldr	r2, [sp, #16]
	adds	r2, #108
	ldrb	r3, [r2, #0]
	movs	r0, #17
	mov	r4, sl
	lsls	r0, r4
	adds	r1, r3, #0
	bics	r1, r0
	ldr	r4, [sp, #16]
	adds	r4, #109
	ldrb	r4, [r4, #0]
	ands	r0, r4
	orrs	r1, r0
	strb	r1, [r2, #0]
	cmp	r3, r1
	beq.n	.L00514
	movs	r0, #16
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
.L00514:
	mov	r2, sl
	cmp	r2, #0
	bne.n	.L00524
	ldr	r1, .L00534
	ldr	r0, [sp, #16]
	adds	r0, #110
	ldrb	r0, [r0, #0]
	strb	r0, [r1, #0]
.L00524:
	movs	r3, #0
	str	r3, [sp, #8]
	movs	r0, #4
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
	b.n	.L00c52
	movs	r0, r0
.L00534:
	.4byte	0x04000060
.L00538:
	mov	r0, r8
	lsls	r3, r0, #3
	adds	r3, r3, r6
	ldr	r0, [r3, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r3, #4]
	ldrb	r4, [r0, #0]
	lsls	r1, r4, #8
	orrs	r2, r1
	adds	r4, r0, #1
	str	r4, [r3, #4]
	ldrb	r0, [r0, #1]
	lsls	r0, r0, #16
	orrs	r2, r0
	adds	r1, r4, #1
	str	r1, [r3, #4]
	ldrb	r4, [r4, #1]
	lsls	r0, r4, #24
	orrs	r2, r0
	adds	r1, #1
	str	r1, [r3, #4]
	str	r2, [r3, #12]
	movs	r0, #1
	strh	r0, [r3, #8]
	b.n	.L00460
.L0056c:
	movs	r0, #15
	ands	r0, r3
	adds	r1, r0, #0
	cmp	r1, #0
	bge.n	.L00578
	b.n	.L00c52
.L00578:
	cmp	r1, #11
	ble.n	.L00582
	cmp	r1, #12
	beq.n	.L00594
	b.n	.L00c52
.L00582:
	lsls	r0, r0, #4
	strb	r0, [r7, #0]
	mov	r9, r0
	ldrb	r0, [r7, #1]
	str	r0, [sp, #12]
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
.L00594:
	mov	r2, r8
	lsls	r0, r2, #3
	adds	r0, r0, r6
	ldr	r1, [r0, #4]
	ldrb	r2, [r1, #0]
	adds	r1, #1
	str	r1, [r0, #4]
	ldr	r1, .L005c8
	ldr	r0, [r1, #12]
	cmp	r2, r0
	blt.n	.L005ac
	b.n	.L00460
.L005ac:
	ldr	r3, [sp, #0]
	cmp	r3, #0
	bne.n	.L005cc
	ldr	r1, [r1, #16]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	str	r0, [r6, #20]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r6, #16]
	strb	r1, [r6, #19]
	b.n	.L00460
	movs	r0, r0
.L005c8:
	.4byte	gbass_module
.L005cc:
	ldr	r1, [r1, #16]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	str	r0, [r6, #28]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r6, #24]
	strb	r1, [r6, #27]
	b.n	.L00460
.L005e0:
	movs	r2, #15
	ands	r2, r3
	cmp	r2, #14
	bne.n	.L005ea
	b.n	.L00460
.L005ea:
	cmp	r2, #14
	ble.n	.L00600
	cmp	r2, #15
	bne.n	.L00600
	mov	r4, r8
	lsls	r1, r4, #3
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
.L00600:
	cmp	r2, #0
	bge.n	.L00606
	b.n	.L00460
.L00606:
	strb	r2, [r7, #2]
	movs	r0, #8
	b.n	.L00a1a
.L0060c:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #15
	bls.n	.L00616
	b.n	.L00460
.L00616:
	lsls	r0, r0, #2
	ldr	r1, .L00620
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L00620:
	.4byte	.L00624
.L00624:
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00664
	.4byte	.L00678
	.4byte	.L00674
	.4byte	.L00686
	.4byte	.L0068c
.L00664:
	movs	r0, #15
	ands	r3, r0
	lsls	r0, r3, #4
	strb	r0, [r7, #0]
	mov	r9, r0
	ldrb	r2, [r7, #1]
	str	r2, [sp, #12]
	b.n	.L0069e
.L00674:
	movs	r0, #0
	strh	r0, [r6, #16]
.L00678:
	movs	r0, #255
	strb	r0, [r7, #0]
	mov	r9, r0
	ldrb	r4, [r7, #1]
	str	r4, [sp, #12]
	movs	r0, #1
	b.n	.L00a1a
.L00686:
	movs	r0, #0
	strh	r0, [r6, #16]
	b.n	.L00460
.L0068c:
	movs	r0, #1
	strb	r0, [r6, #19]
	b.n	.L00460
.L00692:
	movs	r0, #15
	ands	r0, r3
	strb	r0, [r7, #1]
	str	r0, [sp, #12]
	ldrb	r2, [r7, #0]
	mov	r9, r2
.L0069e:
	movs	r0, #1
	ldr	r3, [sp, #4]
	orrs	r3, r0
	str	r3, [sp, #4]
	b.n	.L00460
.L006a8:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #1
	beq.n	.L006e0
	cmp	r0, #1
	bgt.n	.L006ba
	cmp	r0, #0
	beq.n	.L006d8
	b.n	.L00c52
.L006ba:
	cmp	r0, #2
	beq.n	.L006c4
	cmp	r0, #3
	beq.n	.L006f2
	b.n	.L00c52
.L006c4:
	adds	r1, r4, r6
	ldrb	r0, [r1, #2]
	cmp	r0, #0
	bne.n	.L006d4
	ldr	r0, [r1, #4]
	adds	r0, #4
	str	r0, [r1, #4]
	b.n	.L00460
.L006d4:
	subs	r0, #1
	strb	r0, [r1, #2]
.L006d8:
	mov	r4, r8
	lsls	r3, r4, #3
	adds	r3, r3, r6
	b.n	.L006fe
.L006e0:
	mov	r1, r8
	lsls	r0, r1, #3
	adds	r0, r0, r6
	ldr	r2, [r0, #4]
	ldrb	r1, [r2, #0]
	strb	r1, [r0, #2]
	adds	r2, #1
	str	r2, [r0, #4]
	b.n	.L00460
.L006f2:
	mov	r2, r8
	lsls	r0, r2, #3
	adds	r3, r0, r6
	ldrb	r0, [r3, #3]
	cmp	r0, #0
	bne.n	.L00724
.L006fe:
	ldr	r0, [r3, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r3, #4]
	ldrb	r4, [r0, #0]
	lsls	r1, r4, #8
	orrs	r2, r1
	adds	r1, r0, #1
	str	r1, [r3, #4]
	ldrb	r0, [r0, #1]
	lsls	r0, r0, #16
	orrs	r2, r0
	adds	r0, r1, #1
	str	r0, [r3, #4]
	ldrb	r1, [r1, #1]
	lsls	r0, r1, #24
	orrs	r2, r0
	str	r2, [r3, #4]
	b.n	.L00460
.L00724:
	ldr	r0, [r3, #4]
	adds	r0, #4
	str	r0, [r3, #4]
	b.n	.L00460
.L0072c:
	movs	r2, #15
	adds	r0, r2, #0
	ands	r0, r3
	cmp	r0, #1
	beq.n	.L00752
	cmp	r0, #1
	bgt.n	.L00740
	cmp	r0, #0
	beq.n	.L0074a
	b.n	.L00c52
.L00740:
	cmp	r0, #2
	beq.n	.L007ac
	cmp	r0, #3
	beq.n	.L007d6
	b.n	.L00c52
.L0074a:
	movs	r0, #0
	str	r0, [sp, #8]
	movs	r0, #4
	b.n	.L00a1a
.L00752:
	mov	r3, r8
	lsls	r1, r3, #3
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r4, [r0, #0]
	str	r4, [sp, #8]
	adds	r0, #1
	str	r0, [r1, #4]
	ldr	r0, [sp, #0]
	cmp	r0, #3
	bne.n	.L00788
	movs	r1, #240
	ands	r1, r4
	ldr	r0, [sp, #16]
	adds	r0, #64
	add	r0, sl
	ldrb	r0, [r0, #0]
	muls	r0, r1
	asrs	r0, r0, #8
	ands	r4, r2
	movs	r2, #16
	negs	r2, r2
	adds	r1, r2, #0
	ands	r0, r1
	orrs	r4, r0
	str	r4, [sp, #8]
	b.n	.L007a8
.L00788:
	movs	r1, #240
	ldr	r3, [sp, #8]
	ands	r1, r3
	ldr	r0, [sp, #16]
	adds	r0, #52
	add	r0, sl
	ldrb	r0, [r0, #0]
	muls	r0, r1
	asrs	r0, r0, #8
	ands	r3, r2
	movs	r4, #16
	negs	r4, r4
	adds	r1, r4, #0
	ands	r0, r1
	orrs	r3, r0
	str	r3, [sp, #8]
.L007a8:
	movs	r0, #4
	b.n	.L00a1a
.L007ac:
	ldr	r2, [sp, #0]
	cmp	r2, #3
	bne.n	.L007be
	ldr	r3, [sp, #16]
	adds	r3, #64
	add	r3, sl
	mov	r4, r8
	lsls	r2, r4, #3
	b.n	.L007c8
.L007be:
	ldr	r3, [sp, #16]
	adds	r3, #52
	add	r3, sl
	mov	r0, r8
	lsls	r2, r0, #3
.L007c8:
	adds	r2, r2, r6
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	strb	r0, [r3, #0]
	adds	r1, #1
	str	r1, [r2, #4]
	b.n	.L00460
.L007d6:
	adds	r2, r4, r6
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	ldr	r3, [sp, #16]
	str	r0, [r3, #16]
	adds	r1, #1
	str	r1, [r2, #4]
	movs	r4, #0
	ldr	r1, .L00820
	ldr	r0, [r1, #32]
	lsls	r3, r0, #1
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	mov	ip, r1
	cmp	r3, r0
	beq.n	.L00810
	ldr	r5, [sp, #16]
	adds	r2, r0, #0
.L007fc:
	mov	r1, ip
	ldr	r0, [r1, #36]
	lsls	r1, r4, #5
	adds	r1, r1, r0
	ldr	r0, [r5, #16]
	strh	r0, [r1, #26]
	adds	r4, #1
	subs	r3, #1
	cmp	r3, r2
	bne.n	.L007fc
.L00810:
	ldr	r2, [sp, #16]
	ldr	r0, [r2, #16]
	asrs	r4, r0, #5
	lsls	r0, r4, #4
	orrs	r4, r0
	ldr	r0, .L00824
	strb	r4, [r0, #0]
	b.n	.L00460
.L00820:
	.4byte	gbass_module
.L00824:
	.4byte	0x04000080
.L00828:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #11
	bls.n	.L00832
	b.n	.L00c52
.L00832:
	lsls	r0, r0, #2
	ldr	r1, .L0083c
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L0083c:
	.4byte	.L00840
.L00840:
	.4byte	.L00870
	.4byte	.L00880
	.4byte	.L008b0
	.4byte	.L008ba
	.4byte	.L008d8
	.4byte	.L008f8
	.4byte	.L00c52
	.4byte	.L00c52
	.4byte	.L0092c
	.4byte	.L00c52
	.4byte	.L00970
	.4byte	.L00976
.L00870:
	movs	r0, #0
	strb	r0, [r7, #3]
	ldrb	r3, [r7, #0]
	mov	r9, r3
	ldrb	r4, [r7, #1]
	str	r4, [sp, #12]
	movs	r0, #1
	b.n	.L00a1a
.L00880:
	movs	r3, #0
	movs	r0, #1
	strb	r0, [r7, #3]
	mov	r2, r8
	lsls	r1, r2, #3
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsls	r1, r2, #8
	ldr	r4, .L008ac
	adds	r0, r4, #0
	ands	r1, r0
	lsls	r2, r2, #4
	movs	r0, #240
	ands	r2, r0
	orrs	r1, r2
	strh	r1, [r7, #4]
	strh	r3, [r7, #6]
	b.n	.L00460
	movs	r0, r0
.L008ac:
	.4byte	0xfffff000
.L008b0:
	movs	r0, #2
	strb	r0, [r7, #3]
	mov	r0, r8
	lsls	r1, r0, #3
	b.n	.L008c2
.L008ba:
	movs	r0, #3
	strb	r0, [r7, #3]
	mov	r2, r8
	lsls	r1, r2, #3
.L008c2:
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsrs	r0, r2, #4
	strh	r0, [r7, #6]
	movs	r0, #15
	ands	r2, r0
	strh	r2, [r7, #4]
	b.n	.L00460
.L008d8:
	movs	r0, #4
	strb	r0, [r7, #3]
	mov	r3, r8
	lsls	r2, r3, #3
	adds	r2, r2, r6
	ldr	r0, [r2, #4]
	ldrb	r4, [r0, #0]
	lsls	r1, r4, #4
	strh	r1, [r7, #4]
	adds	r0, #1
	str	r0, [r2, #4]
	ldrb	r1, [r0, #0]
	strh	r1, [r7, #6]
	adds	r0, #1
	str	r0, [r2, #4]
	b.n	.L00460
.L008f8:
	mov	r0, r8
	lsls	r2, r0, #3
	adds	r2, r2, r6
	ldr	r0, [r2, #4]
	ldrb	r1, [r0, #0]
	adds	r0, #1
	str	r0, [r2, #4]
	movs	r3, #16
	negs	r3, r3
	adds	r2, r3, #0
	adds	r0, r1, #0
	ands	r0, r2
	movs	r2, #5
	movs	r4, #0
	orrs	r0, r2
	strb	r0, [r7, #3]
	movs	r0, #15
	ands	r1, r0
	adds	r1, #4
	movs	r0, #128
	lsls	r0, r0, #7
	bl	__divsi3
	strh	r0, [r7, #4]
	strh	r4, [r7, #6]
	b.n	.L00460
.L0092c:
	mov	r4, sl
	cmp	r4, #1
	beq.n	.L00958
	cmp	r4, #1
	bgt.n	.L0093c
	cmp	r4, #0
	beq.n	.L00946
	b.n	.L00460
.L0093c:
	mov	r0, sl
	cmp	r0, #3
	ble.n	.L00944
	b.n	.L00460
.L00944:
	b.n	.L00964
.L00946:
	ldr	r1, [sp, #0]
	cmp	r1, #3
	beq.n	.L00952
	ldrh	r0, [r6, #24]
	cmp	r0, #0
	bne.n	.L00958
.L00952:
	ldr	r0, .L0096c
	mov	r2, sl
	strb	r2, [r0, #0]
.L00958:
	movs	r0, #2
	strb	r0, [r7, #2]
	movs	r0, #8
	ldr	r3, [sp, #4]
	orrs	r3, r0
	str	r3, [sp, #4]
.L00964:
	movs	r4, #240
	str	r4, [sp, #8]
	movs	r0, #4
	b.n	.L00a1a
.L0096c:
	.4byte	0x04000060
.L00970:
	mov	r2, r8
	lsls	r1, r2, #3
	b.n	.L00b40
.L00976:
	mov	r3, r8
	lsls	r0, r3, #3
	adds	r0, r0, r6
	ldr	r1, [r0, #4]
	ldrb	r2, [r1, #0]
	adds	r1, #1
	str	r1, [r0, #4]
	cmp	r2, #0
	bne.n	.L0098a
	b.n	.L00460
.L0098a:
	movs	r0, #0
	strb	r0, [r7, #3]
	ldrb	r4, [r7, #0]
	mov	r9, r4
	ldrb	r0, [r7, #1]
	str	r0, [sp, #12]
	movs	r0, #1
	b.n	.L00a1a
.L0099a:
	movs	r0, #15
	ands	r3, r0
	subs	r0, r3, #2
	cmp	r0, #9
	bls.n	.L009a6
	b.n	.L00c52
.L009a6:
	lsls	r0, r0, #2
	ldr	r1, .L009b0
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L009b0:
	.4byte	.L009b4
.L009b4:
	.4byte	.L00b0c
	.4byte	.L009dc
	.4byte	.L00a28
	.4byte	.L00a74
	.4byte	.L00aa4
	.4byte	.L00b16
	.4byte	.L00b34
	.4byte	.L00b3c
	.4byte	.L00b4a
	.4byte	.L00bc0
.L009dc:
	ldr	r3, [sp, #0]
	cmp	r3, #3
	beq.n	.L009fc
	ldr	r3, [sp, #16]
	adds	r3, #109
	movs	r0, #1
	mov	r4, sl
	lsls	r0, r4
	ldrb	r1, [r3, #0]
	orrs	r0, r1
	movs	r2, #3
	subs	r2, r2, r4
	ldr	r1, .L00a24
	asrs	r1, r2
	ands	r0, r1
	strb	r0, [r3, #0]
.L009fc:
	ldr	r3, [sp, #16]
	adds	r3, #108
	movs	r1, #1
	mov	r2, sl
	lsls	r1, r2
	ldrb	r4, [r3, #0]
	orrs	r1, r4
	movs	r2, #3
	mov	r0, sl
	subs	r2, r2, r0
	ldr	r0, .L00a24
	asrs	r0, r2
	ands	r1, r0
	strb	r1, [r3, #0]
	movs	r0, #16
.L00a1a:
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	b.n	.L00460
	movs	r0, r0
.L00a24:
	.4byte	0x00000f7f
.L00a28:
	ldr	r2, [sp, #0]
	cmp	r2, #3
	beq.n	.L00a48
	ldr	r3, [sp, #16]
	adds	r3, #109
	movs	r0, #16
	mov	r4, sl
	lsls	r0, r4
	ldrb	r1, [r3, #0]
	orrs	r0, r1
	movs	r2, #3
	subs	r2, r2, r4
	ldr	r1, .L00a70
	asrs	r1, r2
	ands	r0, r1
	strb	r0, [r3, #0]
.L00a48:
	ldr	r3, [sp, #16]
	adds	r3, #108
	movs	r4, #16
	adds	r1, r4, #0
	mov	r2, sl
	lsls	r1, r2
	ldrb	r0, [r3, #0]
	orrs	r1, r0
	movs	r2, #3
	mov	r0, sl
	subs	r2, r2, r0
	ldr	r0, .L00a70
	asrs	r0, r2
	ands	r1, r0
	strb	r1, [r3, #0]
	ldr	r1, [sp, #4]
	orrs	r1, r4
	str	r1, [sp, #4]
	b.n	.L00460
	movs	r0, r0
.L00a70:
	.4byte	0x00000ff7
.L00a74:
	ldr	r2, [sp, #0]
	cmp	r2, #3
	beq.n	.L00a8a
	ldr	r1, [sp, #16]
	adds	r1, #109
	movs	r0, #17
	mov	r3, sl
	lsls	r0, r3
	ldrb	r4, [r1, #0]
	orrs	r0, r4
	strb	r0, [r1, #0]
.L00a8a:
	ldr	r0, [sp, #16]
	adds	r0, #108
	movs	r1, #17
	mov	r2, sl
	lsls	r1, r2
	ldrb	r3, [r0, #0]
	orrs	r1, r3
	strb	r1, [r0, #0]
	movs	r0, #16
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
	b.n	.L00460
.L00aa4:
	mov	r0, sl
	cmp	r0, #0
	beq.n	.L00ab0
	mov	r2, r8
	lsls	r1, r2, #3
	b.n	.L00b40
.L00ab0:
	ldr	r3, [sp, #0]
	cmp	r3, #3
	bne.n	.L00ad0
	ldr	r3, .L00acc
	mov	r4, r8
	lsls	r2, r4, #3
	adds	r2, r2, r6
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	strb	r0, [r3, #0]
	adds	r1, #1
	str	r1, [r2, #4]
	b.n	.L00b0c
	movs	r0, r0
.L00acc:
	.4byte	0x04000060
.L00ad0:
	ldrh	r0, [r6, #24]
	cmp	r0, #0
	bne.n	.L00af8
	mov	r0, r8
	lsls	r1, r0, #3
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	ldr	r3, [sp, #16]
	adds	r3, #110
	strb	r2, [r3, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	ldr	r1, .L00af4
	ldrb	r0, [r3, #0]
	strb	r0, [r1, #0]
	b.n	.L00b0c
	movs	r0, r0
.L00af4:
	.4byte	0x04000060
.L00af8:
	mov	r1, r8
	lsls	r0, r1, #3
	adds	r0, r0, r6
	ldr	r1, [r0, #4]
	ldrb	r2, [r1, #0]
	ldr	r3, [sp, #16]
	adds	r3, #110
	strb	r2, [r3, #0]
	adds	r1, #1
	str	r1, [r0, #4]
.L00b0c:
	movs	r0, #2
	ldr	r2, [sp, #4]
	orrs	r2, r0
	str	r2, [sp, #4]
	b.n	.L00460
.L00b16:
	mov	r3, r8
	lsls	r5, r3, #3
	adds	r5, r5, r6
	ldr	r4, [r5, #4]
	ldrb	r1, [r4, #0]
	lsls	r0, r1, #17
	movs	r1, #150
	lsls	r1, r1, #1
	bl	__divsi3
	ldr	r2, [sp, #16]
	str	r0, [r2, #104]
	adds	r4, #1
	str	r4, [r5, #4]
	b.n	.L00460
.L00b34:
	adds	r1, r4, r6
	movs	r0, #100
	strh	r0, [r1, #0]
	b.n	.L00c52
.L00b3c:
	mov	r3, r8
	lsls	r1, r3, #3
.L00b40:
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	adds	r0, #1
	str	r0, [r1, #4]
	b.n	.L00460
.L00b4a:
	mov	r4, r8
	lsls	r1, r4, #3
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r3, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	ldr	r2, .L00b9c
	ldr	r1, [r2, #16]
	lsls	r0, r3, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	ip, r2
	ldrb	r1, [r0, #0]
	cmp	r1, #153
	beq.n	.L00b6c
	b.n	.L00460
.L00b6c:
	ldrb	r0, [r0, #1]
	mov	r8, r0
	cmp	r0, #3
	ble.n	.L00b76
	b.n	.L00460
.L00b76:
	asrs	r1, r0, #1
	movs	r2, #1
	ands	r1, r2
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	mov	r4, ip
	ldr	r1, [r4, #60]
	adds	r1, r1, r0
	mov	r0, r8
	ands	r0, r2
	lsls	r0, r0, #5
	adds	r2, r1, r0
	ldr	r0, [sp, #0]
	cmp	r0, #3
	beq.n	.L00ba0
	ldrb	r0, [r6, #11]
	b.n	.L00ba6
	movs	r0, r0
.L00b9c:
	.4byte	gbass_module
.L00ba0:
	adds	r0, r6, #0
	subs	r0, #16
	ldrb	r0, [r0, #3]
.L00ba6:
	strb	r0, [r2, #11]
	mov	r4, ip
	ldr	r1, [r4, #16]
	lsls	r0, r3, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	adds	r0, #2
	str	r0, [r2, #28]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r2, #24]
	strb	r1, [r2, #27]
	b.n	.L00460
.L00bc0:
	mov	r0, r8
	lsls	r1, r0, #3
	adds	r1, r1, r6
	ldr	r0, [r1, #4]
	ldrb	r5, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	ldrb	r4, [r0, #0]
	adds	r0, #2
	str	r0, [r1, #4]
	ldr	r2, .L00c2c
	ldr	r1, [r2, #16]
	lsls	r0, r5, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	ip, r2
	ldrb	r1, [r0, #0]
	cmp	r1, #153
	beq.n	.L00be8
	b.n	.L00460
.L00be8:
	ldrb	r0, [r0, #1]
	mov	r8, r0
	cmp	r0, #3
	ble.n	.L00bf2
	b.n	.L00460
.L00bf2:
	asrs	r1, r0, #1
	movs	r3, #1
	ands	r1, r3
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	ldr	r2, [r2, #60]
	adds	r2, r2, r0
	mov	r0, r8
	ands	r0, r3
	lsls	r1, r0, #5
	adds	r3, r2, r1
	adds	r0, #2
	lsls	r0, r0, #3
	adds	r2, r2, r0
	movs	r1, #15
	adds	r0, r4, #0
	ands	r0, r1
	adds	r1, r2, #0
	adds	r1, #64
	strb	r0, [r1, #0]
	asrs	r0, r4, #4
	adds	r2, #65
	strb	r0, [r2, #0]
	ldr	r2, [sp, #0]
	cmp	r2, #3
	beq.n	.L00c30
	ldrb	r0, [r6, #11]
	b.n	.L00c36
.L00c2c:
	.4byte	gbass_module
.L00c30:
	adds	r0, r6, #0
	subs	r0, #16
	ldrb	r0, [r0, #3]
.L00c36:
	strb	r0, [r3, #11]
	mov	r4, ip
	ldr	r1, [r4, #16]
	lsls	r0, r5, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	adds	r0, #2
	str	r0, [r3, #28]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r3, #24]
	strb	r1, [r3, #27]
	bl	.L00460
.L00c52:
	movs	r0, #1
	add	r8, r0
	mov	r1, r8
	cmp	r1, #2
	bgt.n	.L00c60
	bl	.L00442
.L00c60:
	ldr	r2, [sp, #0]
	cmp	r8, r2
	bne.n	.L00c6a
	bl	.L00442
.L00c6a:
	mov	r3, r9
	cmp	r3, #255
	bne.n	.L00c72
	b.n	.L00f52
.L00c72:
	ldrb	r0, [r7, #3]
	movs	r1, #15
	ands	r1, r0
	adds	r4, r0, #0
	cmp	r1, #5
	bls.n	.L00c80
	b.n	.L00f52
.L00c80:
	lsls	r0, r1, #2
	ldr	r1, .L00c8c
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
	movs	r0, r0
.L00c8c:
	.4byte	.L00c90
.L00c90:
	.4byte	.L00f52
	.4byte	.L00ca8
	.4byte	.L00d30
	.4byte	.L00d8e
	.4byte	.L00df0
	.4byte	.L00ee8
.L00ca8:
	ldrh	r1, [r7, #6]
	cmp	r1, #1
	beq.n	.L00cd0
	cmp	r1, #1
	bgt.n	.L00cb8
	cmp	r1, #0
	beq.n	.L00cbe
	b.n	.L00f52
.L00cb8:
	cmp	r1, #2
	beq.n	.L00d00
	b.n	.L00f52
.L00cbe:
	ldrb	r4, [r7, #0]
	mov	r9, r4
	ldrb	r0, [r7, #1]
	str	r0, [sp, #12]
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	b.n	.L00f50
.L00cd0:
	ldrh	r2, [r7, #4]
	lsrs	r0, r2, #8
	ldrb	r3, [r7, #0]
	adds	r3, r3, r0
	mov	r9, r3
	ldrb	r4, [r7, #1]
	str	r4, [sp, #12]
	cmp	r3, #191
	bls.n	.L00cf6
	adds	r0, r4, #0
	adds	r0, #1
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
	mov	r0, r9
	subs	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
.L00cf6:
	ldr	r0, [sp, #4]
	orrs	r0, r1
	str	r0, [sp, #4]
	movs	r0, #2
	b.n	.L00f50
.L00d00:
	ldrb	r1, [r7, #0]
	ldrb	r2, [r7, #4]
	adds	r1, r1, r2
	mov	r9, r1
	ldrb	r3, [r7, #1]
	str	r3, [sp, #12]
	cmp	r1, #191
	bls.n	.L00d24
	adds	r0, r3, #0
	adds	r0, #1
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
	mov	r0, r9
	subs	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
.L00d24:
	movs	r0, #1
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
	movs	r0, #0
	b.n	.L00f50
.L00d30:
	ldrh	r0, [r7, #6]
	lsrs	r1, r0, #8
	adds	r3, r0, #0
	ldrb	r0, [r7, #6]
	cmp	r1, r0
	bne.n	.L00d86
	ldrb	r1, [r7, #1]
	str	r1, [sp, #12]
	ldrb	r0, [r7, #4]
	adds	r0, #1
	ldrb	r2, [r7, #0]
	adds	r0, r2, r0
	strb	r0, [r7, #0]
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	mov	r9, r0
	cmp	r0, #191
	bls.n	.L00d78
	cmp	r1, #9
	bne.n	.L00d60
	movs	r0, #191
	strb	r0, [r7, #0]
	mov	r9, r0
	b.n	.L00d78
.L00d60:
	ldr	r1, [sp, #12]
	adds	r1, #1
	lsls	r0, r1, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
	strb	r1, [r7, #1]
	mov	r1, r9
	subs	r1, #192
	lsls	r0, r1, #16
	lsrs	r0, r0, #16
	mov	r9, r0
	strb	r1, [r7, #0]
.L00d78:
	movs	r0, #1
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
	movs	r0, #255
	ands	r0, r3
	b.n	.L00f50
.L00d86:
	movs	r1, #128
	lsls	r1, r1, #1
	adds	r0, r3, r1
	b.n	.L00f50
.L00d8e:
	ldrh	r0, [r7, #6]
	lsrs	r1, r0, #8
	adds	r3, r0, #0
	ldrb	r2, [r7, #6]
	cmp	r1, r2
	bne.n	.L00de8
	ldrb	r4, [r7, #1]
	str	r4, [sp, #12]
	ldrb	r1, [r7, #0]
	ldrh	r2, [r7, #4]
	subs	r0, r1, r2
	subs	r0, #1
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
	mov	r4, r9
	strb	r4, [r7, #0]
	cmp	r0, #191
	bls.n	.L00dda
	ldr	r1, [sp, #12]
	cmp	r1, #0
	bne.n	.L00dc2
	strb	r1, [r7, #0]
	movs	r4, #0
	mov	r9, r4
	b.n	.L00dda
.L00dc2:
	ldr	r1, [sp, #12]
	subs	r1, #1
	lsls	r0, r1, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
	strb	r1, [r7, #1]
	mov	r0, r9
	adds	r0, #192
	strb	r0, [r7, #0]
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	mov	r9, r0
.L00dda:
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	movs	r0, #255
	ands	r0, r3
	b.n	.L00f50
.L00de8:
	movs	r2, #128
	lsls	r2, r2, #1
	adds	r0, r3, r2
	b.n	.L00f50
.L00df0:
	ldrb	r0, [r7, #1]
	ldrh	r1, [r7, #4]
	lsrs	r2, r1, #8
	adds	r3, r0, #0
	adds	r4, r1, #0
	cmp	r0, r2
	bhi.n	.L00e0c
	cmp	r0, r2
	bne.n	.L00e6e
	movs	r0, #255
	ands	r0, r4
	ldrb	r1, [r7, #0]
	cmp	r1, r0
	bls.n	.L00e6e
.L00e0c:
	str	r3, [sp, #12]
	ldrb	r2, [r7, #0]
	ldrh	r3, [r7, #6]
	subs	r0, r2, r3
	subs	r0, #1
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
	mov	r0, r9
	strb	r0, [r7, #0]
	mov	r1, r9
	cmp	r1, #191
	bls.n	.L00e52
	movs	r2, #255
.L00e28:
	ldr	r3, [sp, #12]
	cmp	r3, #0
	bne.n	.L00e36
	strb	r3, [r7, #0]
	movs	r1, #0
	mov	r9, r1
	b.n	.L00e4c
.L00e36:
	ldr	r0, [sp, #12]
	subs	r0, #1
	lsls	r1, r0, #24
	lsrs	r1, r1, #24
	str	r1, [sp, #12]
	strb	r0, [r7, #1]
	mov	r0, r9
	adds	r0, #192
	strb	r0, [r7, #0]
	ands	r0, r2
	mov	r9, r0
.L00e4c:
	mov	r3, r9
	cmp	r3, #191
	bhi.n	.L00e28
.L00e52:
	lsls	r0, r4, #16
	lsrs	r2, r0, #24
	ldrb	r1, [r7, #1]
	adds	r0, r2, #0
	cmp	r1, r0
	bcc.n	.L00ece
	cmp	r1, r0
	bne.n	.L00ede
	movs	r0, #255
	ands	r0, r4
	ldrb	r1, [r7, #0]
	cmp	r1, r0
	bhi.n	.L00ede
	b.n	.L00ece
.L00e6e:
	str	r3, [sp, #12]
	ldrb	r0, [r7, #6]
	adds	r0, #1
	ldrb	r3, [r7, #0]
	adds	r0, r3, r0
	strb	r0, [r7, #0]
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	mov	r9, r0
	cmp	r0, #191
	bls.n	.L00eb2
	movs	r3, #191
	movs	r2, #255
.L00e88:
	ldr	r0, [sp, #12]
	cmp	r0, #9
	bne.n	.L00e96
	strb	r3, [r7, #0]
	movs	r1, #191
	mov	r9, r1
	b.n	.L00eac
.L00e96:
	ldr	r0, [sp, #12]
	adds	r0, #1
	lsls	r1, r0, #24
	lsrs	r1, r1, #24
	str	r1, [sp, #12]
	strb	r0, [r7, #1]
	mov	r0, r9
	adds	r0, #64
	strb	r0, [r7, #0]
	ands	r0, r2
	mov	r9, r0
.L00eac:
	mov	r0, r9
	cmp	r0, #191
	bhi.n	.L00e88
.L00eb2:
	adds	r3, r4, #0
	lsls	r0, r3, #16
	lsrs	r2, r0, #24
	ldrb	r1, [r7, #1]
	adds	r0, r2, #0
	cmp	r1, r0
	bhi.n	.L00ece
	cmp	r1, r0
	bne.n	.L00ede
	movs	r0, #255
	ands	r0, r3
	ldrb	r1, [r7, #0]
	cmp	r1, r0
	bcc.n	.L00ede
.L00ece:
	movs	r0, #0
	strb	r0, [r7, #3]
	strb	r2, [r7, #1]
	str	r2, [sp, #12]
	strb	r4, [r7, #0]
	lsls	r0, r4, #24
	lsrs	r0, r0, #24
	mov	r9, r0
.L00ede:
	movs	r0, #1
	ldr	r2, [sp, #4]
	orrs	r2, r0
	str	r2, [sp, #4]
	b.n	.L00f52
.L00ee8:
	ldrb	r3, [r7, #1]
	str	r3, [sp, #12]
	ldr	r2, .L00f28
	ldrh	r3, [r7, #6]
	lsrs	r0, r3, #8
	movs	r1, #63
	ands	r0, r1
	adds	r0, r0, r2
	movs	r1, #0
	ldrsb	r1, [r0, r1]
	lsls	r0, r4, #24
	lsrs	r0, r0, #28
	adds	r0, #1
	muls	r0, r1
	asrs	r0, r0, #7
	ldrb	r4, [r7, #0]
	adds	r0, r4, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
	movs	r0, #128
	lsls	r0, r0, #8
	cmp	r9, r0
	bls.n	.L00f2c
	mov	r0, r9
	adds	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
	ldr	r0, [sp, #12]
	subs	r0, #1
	b.n	.L00f3e
.L00f28:
	.4byte	vibrato_table
.L00f2c:
	mov	r0, r9
	cmp	r0, #192
	bls.n	.L00f44
	subs	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	mov	r9, r0
	ldr	r0, [sp, #12]
	adds	r0, #1
.L00f3e:
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
.L00f44:
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	ldrh	r2, [r7, #4]
	adds	r0, r2, r3
.L00f50:
	strh	r0, [r7, #6]
.L00f52:
	ldr	r3, [sp, #4]
	cmp	r3, #0
	bne.n	.L00f5a
	b.n	.L015aa
.L00f5a:
	ldr	r4, [sp, #0]
	cmp	r4, #3
	beq.n	.L00f68
	ldrh	r0, [r6, #24]
	cmp	r0, #0
	beq.n	.L00f68
	b.n	.L015aa
.L00f68:
	movs	r0, #16
	ldr	r6, [sp, #4]
	ands	r0, r6
	cmp	r0, #0
	beq.n	.L00f7c
	ldr	r0, .L00f98
	ldr	r1, [sp, #16]
	adds	r1, #108
	ldrb	r1, [r1, #0]
	strb	r1, [r0, #0]
.L00f7c:
	movs	r0, #4
	ldr	r1, [sp, #4]
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L00f88
	b.n	.L01070
.L00f88:
	mov	r2, sl
	cmp	r2, #1
	beq.n	.L00fb0
	cmp	r2, #1
	bgt.n	.L00f9c
	cmp	r2, #0
	beq.n	.L00fa8
	b.n	.L01070
.L00f98:
	.4byte	0x04000081
.L00f9c:
	mov	r3, sl
	cmp	r3, #2
	beq.n	.L00fc8
	cmp	r3, #3
	beq.n	.L01060
	b.n	.L01070
.L00fa8:
	ldr	r0, .L00fac
	b.n	.L01062
.L00fac:
	.4byte	0x04000063
.L00fb0:
	ldr	r0, .L00fc4
	mov	r1, sp
	ldrb	r1, [r1, #8]
	strb	r1, [r0, #0]
	movs	r0, #2
	ldr	r2, [sp, #4]
	orrs	r2, r0
	str	r2, [sp, #4]
	b.n	.L01070
	movs	r0, r0
.L00fc4:
	.4byte	0x04000069
.L00fc8:
	ldr	r3, [sp, #8]
	lsrs	r1, r3, #4
	movs	r0, #15
	ands	r1, r0
	cmp	r1, #15
	bhi.n	.L01070
	lsls	r0, r1, #2
	ldr	r1, .L00fe0
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
	movs	r0, r0
.L00fe0:
	.4byte	.L00fe4
.L00fe4:
	.4byte	.L01024
	.4byte	.L01030
	.4byte	.L01030
	.4byte	.L01030
	.4byte	.L01030
	.4byte	.L0103c
	.4byte	.L0103c
	.4byte	.L0103c
	.4byte	.L0103c
	.4byte	.L01048
	.4byte	.L01048
	.4byte	.L01048
	.4byte	.L01048
	.4byte	.L01054
	.4byte	.L01054
	.4byte	.L01054
.L01024:
	ldr	r1, .L0102c
	movs	r0, #0
	strb	r0, [r1, #0]
	b.n	.L01070
.L0102c:
	.4byte	0x04000073
.L01030:
	ldr	r1, .L01038
	movs	r0, #96
	strb	r0, [r1, #0]
	b.n	.L01070
.L01038:
	.4byte	0x04000073
.L0103c:
	ldr	r1, .L01044
	movs	r0, #64
	strb	r0, [r1, #0]
	b.n	.L01070
.L01044:
	.4byte	0x04000073
.L01048:
	ldr	r1, .L01050
	movs	r0, #128
	strb	r0, [r1, #0]
	b.n	.L01070
.L01050:
	.4byte	0x04000073
.L01054:
	ldr	r1, .L0105c
	movs	r0, #32
	strb	r0, [r1, #0]
	b.n	.L01070
.L0105c:
	.4byte	0x04000073
.L01060:
	ldr	r0, .L0108c
.L01062:
	mov	r4, sp
	ldrb	r4, [r4, #8]
	strb	r4, [r0, #0]
	movs	r0, #2
	ldr	r6, [sp, #4]
	orrs	r6, r0
	str	r6, [sp, #4]
.L01070:
	movs	r0, #8
	ldr	r1, [sp, #4]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L01138
	mov	r2, sl
	cmp	r2, #1
	beq.n	.L010ac
	cmp	r2, #1
	bgt.n	.L01090
	cmp	r2, #0
	beq.n	.L0109c
	b.n	.L01138
	movs	r0, r0
.L0108c:
	.4byte	0x04000079
.L01090:
	mov	r3, sl
	cmp	r3, #2
	beq.n	.L010bc
	cmp	r3, #3
	beq.n	.L01130
	b.n	.L01138
.L0109c:
	ldr	r1, .L010a8
	ldrb	r4, [r7, #2]
	lsls	r0, r4, #6
	strb	r0, [r1, #0]
	b.n	.L01138
	movs	r0, r0
.L010a8:
	.4byte	0x04000062
.L010ac:
	ldr	r1, .L010b8
	ldrb	r6, [r7, #2]
	lsls	r0, r6, #6
	strb	r0, [r1, #0]
	b.n	.L01138
	movs	r0, r0
.L010b8:
	.4byte	0x04000068
.L010bc:
	ldrb	r1, [r7, #2]
	ldr	r2, .L01120
	ldr	r0, [r2, #24]
	cmp	r1, r0
	bge.n	.L01114
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, [r2, #28]
	adds	r1, r1, r0
	ldr	r1, [r1, #0]
	ldr	r0, .L01124
	ands	r1, r0
	movs	r3, #0
	movs	r0, #240
	mov	r8, r0
	movs	r5, #136
	ldr	r4, .L01128
.L010e0:
	mov	r2, r8
	ldrb	r6, [r1, #0]
	ands	r2, r6
	adds	r1, #1
	ldrb	r6, [r1, #0]
	lsrs	r0, r6, #4
	orrs	r2, r0
	adds	r1, #1
	eors	r2, r5
	adds	r0, r3, r4
	strb	r2, [r0, #0]
	adds	r3, #1
	cmp	r3, #15
	ble.n	.L010e0
	ldr	r1, [sp, #16]
	ldr	r0, [r1, #68]
	movs	r1, #1
	eors	r0, r1
	ldr	r2, [sp, #16]
	str	r0, [r2, #68]
	ands	r0, r1
	lsls	r0, r0, #6
	movs	r1, #128
	orrs	r0, r1
	ldr	r1, .L0112c
	strb	r0, [r1, #0]
.L01114:
	movs	r0, #2
	ldr	r3, [sp, #4]
	orrs	r3, r0
	str	r3, [sp, #4]
	b.n	.L01138
	movs	r0, r0
.L01120:
	.4byte	gbass_module
.L01124:
	.4byte	0x0fffffff
.L01128:
	.4byte	0x04000090
.L0112c:
	.4byte	0x04000070
.L01130:
	movs	r0, #1
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
.L01138:
	movs	r3, #1
	ldr	r0, [sp, #4]
	ands	r0, r3
	cmp	r0, #0
	bne.n	.L01144
	b.n	.L014f0
.L01144:
	mov	r6, r9
	cmp	r6, #191
	bhi.n	.L0115c
	mov	r0, sl
	cmp	r0, #3
	beq.n	.L01156
	ldr	r1, [sp, #12]
	cmp	r1, #2
	bls.n	.L0115c
.L01156:
	ldr	r2, [sp, #12]
	cmp	r2, #8
	bls.n	.L011bc
.L0115c:
	mov	r3, sl
	cmp	r3, #1
	beq.n	.L0118c
	cmp	r3, #1
	bgt.n	.L0116c
	cmp	r3, #0
	beq.n	.L01178
	b.n	.L014f0
.L0116c:
	mov	r4, sl
	cmp	r4, #2
	beq.n	.L0119c
	cmp	r4, #3
	beq.n	.L011ac
	b.n	.L014f0
.L01178:
	ldr	r0, .L01184
	mov	r6, sl
	strb	r6, [r0, #0]
	ldr	r1, .L01188
	movs	r0, #128
	b.n	.L014ee
.L01184:
	.4byte	0x04000063
.L01188:
	.4byte	0x04000065
.L0118c:
	ldr	r1, .L01198
	movs	r0, #0
	strb	r0, [r1, #0]
	adds	r1, #4
	movs	r0, #128
	b.n	.L014ee
.L01198:
	.4byte	0x04000069
.L0119c:
	ldr	r1, .L011a8
	movs	r0, #0
	strb	r0, [r1, #0]
	adds	r1, #2
	movs	r0, #128
	b.n	.L014ee
.L011a8:
	.4byte	0x04000073
.L011ac:
	ldr	r1, .L011b8
	movs	r0, #0
	strb	r0, [r1, #0]
	adds	r1, #4
	movs	r0, #128
	b.n	.L014ee
.L011b8:
	.4byte	0x04000079
.L011bc:
	ldr	r0, [sp, #0]
	cmp	r0, #3
	beq.n	.L011c4
	b.n	.L01338
.L011c4:
	mov	r1, sl
	cmp	r1, #1
	beq.n	.L01254
	cmp	r1, #1
	bgt.n	.L011d4
	cmp	r1, #0
	beq.n	.L011e2
	b.n	.L014f0
.L011d4:
	mov	r2, sl
	cmp	r2, #2
	beq.n	.L012c4
	cmp	r2, #3
	bne.n	.L011e0
	b.n	.L014c8
.L011e0:
	b.n	.L014f0
.L011e2:
	ldr	r4, .L011f4
	ldr	r0, [r4, #92]
	cmp	r0, #0
	beq.n	.L011f8
	mov	r0, r9
	ldr	r1, [sp, #12]
	bl	GBASS_GBTranspose
	b.n	.L0123a
.L011f4:
	.4byte	gbass_ram
.L011f8:
	ldr	r3, [sp, #12]
	cmp	r3, #4
	bhi.n	.L01220
	ldr	r0, .L0121c
	mov	r6, r9
	lsls	r1, r6, #1
	adds	r1, r1, r0
	movs	r0, #5
	subs	r0, r0, r3
	ldrh	r1, [r1, #0]
	lsls	r1, r0
	adds	r0, r1, #0
	movs	r2, #128
	lsls	r2, r2, #4
	adds	r1, r2, #0
	subs	r0, r1, r0
	b.n	.L0123a
	movs	r0, r0
.L0121c:
	.4byte	gb_notes
.L01220:
	ldr	r1, .L01248
	mov	r3, r9
	lsls	r0, r3, #1
	adds	r0, r0, r1
	ldr	r1, [sp, #12]
	subs	r1, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
	adds	r1, r0, #0
	movs	r6, #128
	lsls	r6, r6, #4
	adds	r0, r6, #0
	subs	r0, r0, r1
.L0123a:
	strh	r0, [r4, #56]
	ldr	r1, .L0124c
	ldr	r2, .L01250
	ldrh	r0, [r2, #56]
	strh	r0, [r1, #0]
	subs	r1, #2
	b.n	.L01432
.L01248:
	.4byte	gb_notes
.L0124c:
	.4byte	0x04000064
.L01250:
	.4byte	gbass_ram
.L01254:
	ldr	r4, .L01268
	ldr	r0, [r4, #92]
	cmp	r0, #0
	beq.n	.L0126c
	mov	r0, r9
	ldr	r1, [sp, #12]
	bl	GBASS_GBTranspose
	b.n	.L012ae
	movs	r0, r0
.L01268:
	.4byte	gbass_ram
.L0126c:
	ldr	r0, [sp, #12]
	cmp	r0, #4
	bhi.n	.L01294
	ldr	r0, .L01290
	mov	r2, r9
	lsls	r1, r2, #1
	adds	r1, r1, r0
	movs	r0, #5
	ldr	r3, [sp, #12]
	subs	r0, r0, r3
	ldrh	r1, [r1, #0]
	lsls	r1, r0
	adds	r0, r1, #0
	movs	r6, #128
	lsls	r6, r6, #4
	adds	r1, r6, #0
	subs	r0, r1, r0
	b.n	.L012ae
.L01290:
	.4byte	gb_notes
.L01294:
	ldr	r1, .L012b8
	mov	r2, r9
	lsls	r0, r2, #1
	adds	r0, r0, r1
	ldr	r1, [sp, #12]
	subs	r1, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
	adds	r1, r0, #0
	movs	r3, #128
	lsls	r3, r3, #4
	adds	r0, r3, #0
	subs	r0, r0, r1
.L012ae:
	strh	r0, [r4, #58]
	ldr	r1, .L012bc
	ldr	r2, .L012c0
	ldrh	r0, [r2, #58]
	b.n	.L0142e
.L012b8:
	.4byte	gb_notes
.L012bc:
	.4byte	0x0400006c
.L012c0:
	.4byte	gbass_ram
.L012c4:
	ldr	r4, .L012d8
	ldr	r0, [r4, #92]
	cmp	r0, #0
	beq.n	.L012dc
	mov	r0, r9
	ldr	r1, [sp, #12]
	bl	GBASS_GBTranspose
	b.n	.L0131e
	movs	r0, r0
.L012d8:
	.4byte	gbass_ram
.L012dc:
	ldr	r6, [sp, #12]
	cmp	r6, #4
	bhi.n	.L01304
	ldr	r0, .L01300
	mov	r2, r9
	lsls	r1, r2, #1
	adds	r1, r1, r0
	movs	r0, #5
	subs	r0, r0, r6
	ldrh	r1, [r1, #0]
	lsls	r1, r0
	adds	r0, r1, #0
	movs	r3, #128
	lsls	r3, r3, #4
	adds	r1, r3, #0
	subs	r0, r1, r0
	b.n	.L0131e
	movs	r0, r0
.L01300:
	.4byte	gb_notes
.L01304:
	ldr	r1, .L0132c
	mov	r6, r9
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldr	r1, [sp, #12]
	subs	r1, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
	adds	r1, r0, #0
	movs	r2, #128
	lsls	r2, r2, #4
	adds	r0, r2, #0
	subs	r0, r0, r1
.L0131e:
	movs	r2, #0
	strh	r0, [r4, #60]
	ldr	r1, .L01330
	ldr	r3, .L01334
	ldrh	r0, [r3, #60]
	b.n	.L014ac
	movs	r0, r0
.L0132c:
	.4byte	gb_notes
.L01330:
	.4byte	0x04000074
.L01334:
	.4byte	gbass_ram
.L01338:
	mov	r0, sl
	cmp	r0, #1
	beq.n	.L013cc
	cmp	r0, #1
	bgt.n	.L01348
	cmp	r0, #0
	beq.n	.L01358
	b.n	.L014f0
.L01348:
	mov	r1, sl
	cmp	r1, #2
	bne.n	.L01350
	b.n	.L01448
.L01350:
	cmp	r1, #3
	bne.n	.L01356
	b.n	.L014c8
.L01356:
	b.n	.L014f0
.L01358:
	ldr	r4, .L0136c
	ldr	r0, [r4, #92]
	cmp	r0, #0
	beq.n	.L01370
	mov	r0, r9
	ldr	r1, [sp, #12]
	bl	GBASS_GBTranspose
	b.n	.L013b2
	movs	r0, r0
.L0136c:
	.4byte	gbass_ram
.L01370:
	ldr	r2, [sp, #12]
	cmp	r2, #4
	bhi.n	.L01398
	ldr	r0, .L01394
	mov	r3, r9
	lsls	r1, r3, #1
	adds	r1, r1, r0
	movs	r0, #5
	subs	r0, r0, r2
	ldrh	r1, [r1, #0]
	lsls	r1, r0
	adds	r0, r1, #0
	movs	r6, #128
	lsls	r6, r6, #4
	adds	r1, r6, #0
	subs	r0, r1, r0
	b.n	.L013b2
	movs	r0, r0
.L01394:
	.4byte	gb_notes
.L01398:
	ldr	r1, .L013c0
	mov	r2, r9
	lsls	r0, r2, #1
	adds	r0, r0, r1
	ldr	r1, [sp, #12]
	subs	r1, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
	adds	r1, r0, #0
	movs	r3, #128
	lsls	r3, r3, #4
	adds	r0, r3, #0
	subs	r0, r0, r1
.L013b2:
	strh	r0, [r4, #44]
	ldr	r1, .L013c4
	ldr	r2, .L013c8
	ldrh	r0, [r2, #44]
	strh	r0, [r1, #0]
	subs	r1, #2
	b.n	.L01432
.L013c0:
	.4byte	gb_notes
.L013c4:
	.4byte	0x04000064
.L013c8:
	.4byte	gbass_ram
.L013cc:
	ldr	r4, .L013e0
	ldr	r0, [r4, #92]
	cmp	r0, #0
	beq.n	.L013e4
	mov	r0, r9
	ldr	r1, [sp, #12]
	bl	GBASS_GBTranspose
	b.n	.L01426
	movs	r0, r0
.L013e0:
	.4byte	gbass_ram
.L013e4:
	ldr	r6, [sp, #12]
	cmp	r6, #4
	bhi.n	.L0140c
	ldr	r0, .L01408
	mov	r2, r9
	lsls	r1, r2, #1
	adds	r1, r1, r0
	movs	r0, #5
	subs	r0, r0, r6
	ldrh	r1, [r1, #0]
	lsls	r1, r0
	adds	r0, r1, #0
	movs	r3, #128
	lsls	r3, r3, #4
	adds	r1, r3, #0
	subs	r0, r1, r0
	b.n	.L01426
	movs	r0, r0
.L01408:
	.4byte	gb_notes
.L0140c:
	ldr	r1, .L0143c
	mov	r6, r9
	lsls	r0, r6, #1
	adds	r0, r0, r1
	ldr	r1, [sp, #12]
	subs	r1, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
	adds	r1, r0, #0
	movs	r2, #128
	lsls	r2, r2, #4
	adds	r0, r2, #0
	subs	r0, r0, r1
.L01426:
	strh	r0, [r4, #46]
	ldr	r1, .L01440
	ldr	r2, .L01444
	ldrh	r0, [r2, #46]
.L0142e:
	strh	r0, [r1, #0]
	subs	r1, #4
.L01432:
	ldrb	r7, [r7, #2]
	lsls	r0, r7, #6
	strb	r0, [r1, #0]
	str	r2, [sp, #16]
	b.n	.L014f0
.L0143c:
	.4byte	gb_notes
.L01440:
	.4byte	0x0400006c
.L01444:
	.4byte	gbass_ram
.L01448:
	ldr	r4, .L0145c
	ldr	r0, [r4, #92]
	cmp	r0, #0
	beq.n	.L01460
	mov	r0, r9
	ldr	r1, [sp, #12]
	bl	GBASS_GBTranspose
	b.n	.L014a2
	movs	r0, r0
.L0145c:
	.4byte	gbass_ram
.L01460:
	ldr	r3, [sp, #12]
	cmp	r3, #4
	bhi.n	.L01488
	ldr	r0, .L01484
	mov	r6, r9
	lsls	r1, r6, #1
	adds	r1, r1, r0
	movs	r0, #5
	subs	r0, r0, r3
	ldrh	r1, [r1, #0]
	lsls	r1, r0
	adds	r0, r1, #0
	movs	r2, #128
	lsls	r2, r2, #4
	adds	r1, r2, #0
	subs	r0, r1, r0
	b.n	.L014a2
	movs	r0, r0
.L01484:
	.4byte	gb_notes
.L01488:
	ldr	r1, .L014b8
	mov	r3, r9
	lsls	r0, r3, #1
	adds	r0, r0, r1
	ldr	r1, [sp, #12]
	subs	r1, #5
	ldrh	r0, [r0, #0]
	asrs	r0, r1
	adds	r1, r0, #0
	movs	r6, #128
	lsls	r6, r6, #4
	adds	r0, r6, #0
	subs	r0, r0, r1
.L014a2:
	movs	r2, #0
	strh	r0, [r4, #48]
	ldr	r1, .L014bc
	ldr	r3, .L014c0
	ldrh	r0, [r3, #48]
.L014ac:
	strh	r0, [r1, #0]
	ldr	r0, .L014c4
	strb	r2, [r0, #0]
	str	r3, [sp, #16]
	b.n	.L014f0
	movs	r0, r0
.L014b8:
	.4byte	gb_notes
.L014bc:
	.4byte	0x04000074
.L014c0:
	.4byte	gbass_ram
.L014c4:
	.4byte	0x04000072
.L014c8:
	ldr	r2, .L01510
	ldrb	r0, [r7, #0]
	adds	r0, #48
	movs	r4, #16
	negs	r4, r4
	adds	r1, r4, #0
	bics	r1, r0
	movs	r0, #7
	ldrb	r6, [r7, #1]
	ands	r0, r6
	orrs	r1, r0
	adds	r0, r3, #0
	ldrb	r7, [r7, #2]
	ands	r0, r7
	lsls	r0, r0, #3
	orrs	r1, r0
	strb	r1, [r2, #0]
	ldr	r1, .L01514
	movs	r0, #0
.L014ee:
	strb	r0, [r1, #0]
.L014f0:
	movs	r0, #2
	ldr	r1, [sp, #4]
	ands	r1, r0
	cmp	r1, #0
	beq.n	.L015aa
	ldr	r2, [sp, #0]
	cmp	r2, #3
	bne.n	.L01554
	mov	r3, sl
	cmp	r3, #1
	beq.n	.L01534
	cmp	r3, #1
	bgt.n	.L01518
	cmp	r3, #0
	beq.n	.L01524
	b.n	.L015aa
.L01510:
	.4byte	0x0400007c
.L01514:
	.4byte	0x04000078
.L01518:
	mov	r4, sl
	cmp	r4, #2
	beq.n	.L01544
	cmp	r4, #3
	beq.n	.L015a4
	b.n	.L015aa
.L01524:
	ldr	r0, .L01530
	ldr	r6, [sp, #16]
	ldrh	r6, [r6, #56]
	lsrs	r1, r6, #8
	b.n	.L01598
	movs	r0, r0
.L01530:
	.4byte	0x04000065
.L01534:
	ldr	r0, .L01540
	ldr	r2, [sp, #16]
	ldrh	r2, [r2, #58]
	lsrs	r1, r2, #8
	b.n	.L01598
	movs	r0, r0
.L01540:
	.4byte	0x0400006d
.L01544:
	ldr	r0, .L01550
	ldr	r3, [sp, #16]
	ldrh	r3, [r3, #60]
	lsrs	r1, r3, #8
	b.n	.L01598
	movs	r0, r0
.L01550:
	.4byte	0x04000075
.L01554:
	mov	r4, sl
	cmp	r4, #1
	beq.n	.L01580
	cmp	r4, #1
	bgt.n	.L01564
	cmp	r4, #0
	beq.n	.L01570
	b.n	.L015aa
.L01564:
	mov	r6, sl
	cmp	r6, #2
	beq.n	.L01590
	cmp	r6, #3
	beq.n	.L015a4
	b.n	.L015aa
.L01570:
	ldr	r0, .L0157c
	ldr	r2, [sp, #16]
	ldrh	r2, [r2, #44]
	lsrs	r1, r2, #8
	b.n	.L01598
	movs	r0, r0
.L0157c:
	.4byte	0x04000065
.L01580:
	ldr	r0, .L0158c
	ldr	r3, [sp, #16]
	ldrh	r3, [r3, #46]
	lsrs	r1, r3, #8
	b.n	.L01598
	movs	r0, r0
.L0158c:
	.4byte	0x0400006d
.L01590:
	ldr	r0, .L015a0
	ldr	r4, [sp, #16]
	ldrh	r4, [r4, #48]
	lsrs	r1, r4, #8
.L01598:
	movs	r2, #128
	orrs	r1, r2
	strb	r1, [r0, #0]
	b.n	.L015aa
.L015a0:
	.4byte	0x04000075
.L015a4:
	ldr	r1, .L015bc
	movs	r0, #128
	strb	r0, [r1, #0]
.L015aa:
	add	sp, #20
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L015bc:
	.4byte	0x0400007d

@
@ GBASS_Process_Digital(Status *st, Channel *ch, Mixer *mx, int level 0|3)
@ One tick of a software channel. For each level (0,1,2 for music; 3 for sfx):
@ decrement the wait counter; at zero, interpret commands until a wait:
@   0n / 00 nn   wait n / nn ticks (00 00 = stop this level)
@   1x pppp      start pointer at the next level (track -> pattern -> instrument)
@   2n ii        note n (0-11), instrument ii (2C ii = instrument only)
@   3n / 3F ww   select wave n / ww; 3E = stop looping, play on to the release end
@   4n           pitch n without instrument; 4C key off; 4D stop instrument + key off
@                4E stop instrument; 4F release (lets 63 sustain loops fall through)
@   5n           octave n
@   60 pppp jump  61 nn loop count  62 pppp loop  63 pppp jump while not released
@   70 vol 0  71 vv volume  72 vv channel volume  73 vv song master volume
@   80 fx off  81 arpeggio  82/83 porta up/down  84 tn ss slide to note
@   85 vibrato  86 ss volume slide  87 ss chvol slide  88 slides off/vol 255
@   89 wave sweep  8A sample offset  8B retrigger
@   92 trigger  93/94/95 pan R/L/C (GB)  96 sweep (GB)  97 tempo  98 wait sample end
@   99 nn GB header (skipped)  9A ii / 9B ii xy zz  start GB sound effect ii
@                (9B presets its octave x / note byte y; zz unused)
@   unknown codes stop the level (its wait counter stays 0)
@ Afterwards applies the slides and effect and sets mx->speed from digi_notes.
@ A wave whose data pointer has bit 31 set is tempo-synced (rate * song speed).
	.global	GBASS_Process_Digital
	.thumb_func
	.type	GBASS_Process_Digital, %function
GBASS_Process_Digital:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #16
	mov	r8, r0
	adds	r7, r1, #0
	mov	sl, r2
	str	r3, [sp, #0]
	movs	r0, #0
	str	r0, [sp, #4]
	mov	r9, r3
.L015da:
	mov	r1, r9
	lsls	r0, r1, #3
	adds	r1, r0, r7
	ldrh	r0, [r1, #0]
	cmp	r0, #0
	bne.n	.L015e8
	b.n	.L01d76
.L015e8:
	subs	r0, #1
	strh	r0, [r1, #0]
	lsls	r0, r0, #16
	cmp	r0, #0
	beq.n	.L015f4
	b.n	.L01d76
.L015f4:
	mov	r3, r9
	lsls	r2, r3, #3
	adds	r1, r2, r7
	ldr	r0, [r1, #4]
	ldrb	r3, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsrs	r0, r3, #4
	cmp	r0, #9
	bls.n	.L0160a
	b.n	.L01d76
.L0160a:
	lsls	r0, r0, #2
	ldr	r1, .L01614
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L01614:
	.4byte	.L01618
.L01618:
	.4byte	.L01640
	.4byte	.L01658
	.4byte	.L0168c
	.4byte	.L01700
	.4byte	.L017d0
	.4byte	.L01864
	.4byte	.L0187c
	.4byte	.L01900
	.4byte	.L0199c
	.4byte	.L01bcc
.L01640:
	cmp	r3, #0
	bne.n	.L01652
	adds	r2, r2, r7
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	strh	r0, [r2, #0]
	adds	r1, #1
	str	r1, [r2, #4]
	b.n	.L01d76
.L01652:
	adds	r0, r2, r7
	strh	r3, [r0, #0]
	b.n	.L01d76
.L01658:
	mov	r4, r9
	lsls	r3, r4, #3
	adds	r3, r3, r7
	ldr	r0, [r3, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r3, #4]
	ldrb	r4, [r0, #0]
	lsls	r1, r4, #8
	orrs	r2, r1
	adds	r4, r0, #1
	str	r4, [r3, #4]
	ldrb	r0, [r0, #1]
	lsls	r0, r0, #16
	orrs	r2, r0
	adds	r1, r4, #1
	str	r1, [r3, #4]
	ldrb	r4, [r4, #1]
	lsls	r0, r4, #24
	orrs	r2, r0
	adds	r1, #1
	str	r1, [r3, #4]
	str	r2, [r3, #12]
	movs	r0, #1
	strh	r0, [r3, #8]
	b.n	.L015f4
.L0168c:
	movs	r0, #15
	ands	r0, r3
	adds	r1, r0, #0
	cmp	r1, #0
	bge.n	.L01698
	b.n	.L01d76
.L01698:
	cmp	r1, #11
	ble.n	.L016a2
	cmp	r1, #12
	beq.n	.L016b6
	b.n	.L01d76
.L016a2:
	lsls	r0, r0, #4
	mov	r1, r8
	strb	r0, [r1, #0]
	str	r0, [sp, #12]
	ldrb	r2, [r1, #1]
	str	r2, [sp, #8]
	movs	r0, #1
	ldr	r3, [sp, #4]
	orrs	r3, r0
	str	r3, [sp, #4]
.L016b6:
	mov	r4, r9
	lsls	r0, r4, #3
	adds	r0, r0, r7
	ldr	r1, [r0, #4]
	ldrb	r2, [r1, #0]
	adds	r1, #1
	str	r1, [r0, #4]
	ldr	r1, .L016e8
	ldr	r0, [r1, #12]
	cmp	r2, r0
	bge.n	.L015f4
	ldr	r0, [sp, #0]
	cmp	r0, #0
	bne.n	.L016ec
	ldr	r1, [r1, #16]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	str	r0, [r7, #20]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r7, #16]
	strb	r1, [r7, #19]
	b.n	.L015f4
	movs	r0, r0
.L016e8:
	.4byte	gbass_module
.L016ec:
	ldr	r1, [r1, #16]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	str	r0, [r7, #28]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r7, #24]
	strb	r1, [r7, #27]
	b.n	.L015f4
.L01700:
	movs	r2, #15
	ands	r2, r3
	cmp	r2, #14
	beq.n	.L017a6
	cmp	r2, #14
	ble.n	.L0171e
	cmp	r2, #15
	bne.n	.L0171e
	mov	r2, r9
	lsls	r1, r2, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
.L0171e:
	cmp	r2, #0
	blt.n	.L017a6
	mov	r3, r8
	strb	r2, [r3, #2]
	ldr	r1, .L01778
	ldr	r0, [r1, #24]
	cmp	r2, r0
	blt.n	.L01730
	b.n	.L015f4
.L01730:
	lsls	r0, r2, #1
	adds	r0, r0, r2
	lsls	r0, r0, #3
	ldr	r1, [r1, #28]
	adds	r5, r1, r0
	ldr	r0, [r5, #0]
	ldr	r1, .L0177c
	ands	r0, r1
	mov	r4, sl
	str	r0, [r4, #0]
	ldr	r0, [r5, #8]
	str	r0, [r4, #8]
	ldr	r0, [r5, #12]
	str	r0, [r4, #12]
	ldr	r0, [r5, #0]
	cmp	r0, #0
	bge.n	.L01784
	ldr	r4, .L01780
	adds	r2, r4, #0
	adds	r2, #88
	ldr	r0, [r5, #4]
	ldrb	r2, [r2, #0]
	lsls	r0, r2
	asrs	r1, r0, #31
	ldr	r2, [r4, #96]
	movs	r3, #0
	bl	__muldi3
	lsls	r3, r1, #16
	lsrs	r2, r0, #16
	adds	r0, r3, #0
	orrs	r0, r2
	mov	r2, sl
	str	r0, [r2, #28]
	b.n	.L01792
	movs	r0, r0
.L01778:
	.4byte	gbass_module
.L0177c:
	.4byte	0x0fffffff
.L01780:
	.4byte	gbass_ram
.L01784:
	ldr	r1, .L0179c
	adds	r1, #88
	ldr	r0, [r5, #4]
	ldrb	r1, [r1, #0]
	lsls	r0, r1
	mov	r3, sl
	str	r0, [r3, #28]
.L01792:
	ldr	r0, [r5, #16]
	cmp	r0, #0
	bne.n	.L017a0
	mov	r4, sl
	b.n	.L017c4
.L0179c:
	.4byte	gbass_ram
.L017a0:
	mov	r1, sl
	str	r0, [r1, #20]
	b.n	.L015f4
.L017a6:
	mov	r3, r8
	ldrb	r2, [r3, #2]
	ldr	r1, .L017cc
	ldr	r0, [r1, #24]
	cmp	r2, r0
	blt.n	.L017b4
	b.n	.L015f4
.L017b4:
	lsls	r0, r2, #1
	adds	r0, r0, r2
	lsls	r0, r0, #3
	ldr	r1, [r1, #28]
	adds	r1, r1, r0
	ldr	r0, [r1, #20]
	mov	r4, sl
	str	r0, [r4, #12]
.L017c4:
	ldr	r0, [r4, #16]
	str	r0, [r4, #20]
	b.n	.L015f4
	movs	r0, r0
.L017cc:
	.4byte	gbass_module
.L017d0:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #15
	bls.n	.L017da
	b.n	.L015f4
.L017da:
	lsls	r0, r0, #2
	ldr	r1, .L017e4
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L017e4:
	.4byte	.L017e8
.L017e8:
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01828
	.4byte	.L01846
	.4byte	.L01842
	.4byte	.L01858
	.4byte	.L0185e
.L01828:
	movs	r0, #15
	ands	r3, r0
	lsls	r0, r3, #4
	mov	r1, r8
	strb	r0, [r1, #0]
	str	r0, [sp, #12]
	ldrb	r2, [r1, #1]
	str	r2, [sp, #8]
	movs	r0, #1
	ldr	r3, [sp, #4]
	orrs	r3, r0
	str	r3, [sp, #4]
	b.n	.L015f4
.L01842:
	movs	r0, #0
	strh	r0, [r7, #16]
.L01846:
	movs	r0, #255
	mov	r4, r8
	strb	r0, [r4, #0]
	str	r0, [sp, #12]
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	b.n	.L015f4
.L01858:
	movs	r0, #0
	strh	r0, [r7, #16]
	b.n	.L015f4
.L0185e:
	movs	r0, #1
	strb	r0, [r7, #19]
	b.n	.L015f4
.L01864:
	movs	r0, #15
	ands	r0, r3
	mov	r2, r8
	strb	r0, [r2, #1]
	str	r0, [sp, #8]
	ldrb	r3, [r2, #0]
	str	r3, [sp, #12]
	movs	r0, #1
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
	b.n	.L015f4
.L0187c:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #1
	beq.n	.L018b4
	cmp	r0, #1
	bgt.n	.L0188e
	cmp	r0, #0
	beq.n	.L018ac
	b.n	.L01d76
.L0188e:
	cmp	r0, #2
	beq.n	.L01898
	cmp	r0, #3
	beq.n	.L018c6
	b.n	.L01d76
.L01898:
	adds	r2, r2, r7
	ldrb	r0, [r2, #2]
	cmp	r0, #0
	bne.n	.L018a8
	ldr	r0, [r2, #4]
	adds	r0, #4
	str	r0, [r2, #4]
	b.n	.L015f4
.L018a8:
	subs	r0, #1
	strb	r0, [r2, #2]
.L018ac:
	mov	r0, r9
	lsls	r3, r0, #3
	adds	r3, r3, r7
	b.n	.L018d2
.L018b4:
	mov	r1, r9
	lsls	r0, r1, #3
	adds	r0, r0, r7
	ldr	r2, [r0, #4]
	ldrb	r1, [r2, #0]
	strb	r1, [r0, #2]
	adds	r2, #1
	str	r2, [r0, #4]
	b.n	.L015f4
.L018c6:
	mov	r2, r9
	lsls	r0, r2, #3
	adds	r3, r0, r7
	ldrb	r0, [r3, #3]
	cmp	r0, #0
	bne.n	.L018f8
.L018d2:
	ldr	r0, [r3, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r3, #4]
	ldrb	r4, [r0, #0]
	lsls	r1, r4, #8
	orrs	r2, r1
	adds	r1, r0, #1
	str	r1, [r3, #4]
	ldrb	r0, [r0, #1]
	lsls	r0, r0, #16
	orrs	r2, r0
	adds	r0, r1, #1
	str	r0, [r3, #4]
	ldrb	r1, [r1, #1]
	lsls	r0, r1, #24
	orrs	r2, r0
	str	r2, [r3, #4]
	b.n	.L015f4
.L018f8:
	ldr	r0, [r3, #4]
	adds	r0, #4
	str	r0, [r3, #4]
	b.n	.L015f4
.L01900:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #1
	beq.n	.L01922
	cmp	r0, #1
	bgt.n	.L01912
	cmp	r0, #0
	beq.n	.L0191c
	b.n	.L01d76
.L01912:
	cmp	r0, #2
	beq.n	.L01932
	cmp	r0, #3
	beq.n	.L01946
	b.n	.L01d76
.L0191c:
	mov	r1, sl
	str	r0, [r1, #4]
	b.n	.L015f4
.L01922:
	mov	r3, r9
	lsls	r2, r3, #3
	adds	r2, r2, r7
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	mov	r4, sl
	str	r0, [r4, #4]
	b.n	.L01940
.L01932:
	mov	r0, r9
	lsls	r2, r0, #3
	adds	r2, r2, r7
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	mov	r3, sl
	strh	r0, [r3, #24]
.L01940:
	adds	r1, #1
	str	r1, [r2, #4]
	b.n	.L015f4
.L01946:
	ldr	r3, .L01990
	adds	r2, r2, r7
	ldr	r1, [r2, #4]
	ldrb	r0, [r1, #0]
	str	r0, [r3, #16]
	adds	r1, #1
	str	r1, [r2, #4]
	movs	r5, #0
	ldr	r1, .L01994
	ldr	r0, [r1, #32]
	lsls	r4, r0, #1
	subs	r4, #1
	movs	r0, #1
	negs	r0, r0
	adds	r6, r1, #0
	cmp	r4, r0
	beq.n	.L01982
	mov	ip, r6
	adds	r2, r3, #0
	adds	r6, r0, #0
.L0196e:
	mov	r1, ip
	ldr	r0, [r1, #36]
	lsls	r1, r5, #5
	adds	r1, r1, r0
	ldr	r0, [r2, #16]
	strh	r0, [r1, #26]
	adds	r5, #1
	subs	r4, #1
	cmp	r4, r6
	bne.n	.L0196e
.L01982:
	ldr	r0, [r3, #16]
	asrs	r5, r0, #5
	lsls	r0, r5, #4
	orrs	r5, r0
	ldr	r0, .L01998
	strb	r5, [r0, #0]
	b.n	.L015f4
.L01990:
	.4byte	gbass_ram
.L01994:
	.4byte	gbass_module
.L01998:
	.4byte	0x04000080
.L0199c:
	movs	r0, #15
	ands	r0, r3
	cmp	r0, #11
	bls.n	.L019a6
	b.n	.L01d76
.L019a6:
	lsls	r0, r0, #2
	ldr	r1, .L019b0
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L019b0:
	.4byte	.L019b4
.L019b4:
	.4byte	.L019e4
	.4byte	.L01a04
	.4byte	.L01a38
	.4byte	.L01a5a
	.4byte	.L01a7a
	.4byte	.L01aca
	.4byte	.L01b02
	.4byte	.L01b1a
	.4byte	.L01b36
	.4byte	.L01a9e
	.4byte	.L01b4c
	.4byte	.L01b84
.L019e4:
	movs	r0, #0
	mov	r2, r8
	strb	r0, [r2, #3]
	movs	r1, #1
	ldr	r0, [sp, #4]
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L019fc
	ldrb	r3, [r2, #0]
	str	r3, [sp, #12]
	ldrb	r4, [r2, #1]
	str	r4, [sp, #8]
.L019fc:
	ldr	r0, [sp, #4]
	orrs	r0, r1
	str	r0, [sp, #4]
	b.n	.L015f4
.L01a04:
	movs	r3, #0
	movs	r0, #1
	mov	r1, r8
	strb	r0, [r1, #3]
	mov	r2, r9
	lsls	r1, r2, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsls	r1, r2, #8
	ldr	r4, .L01a34
	adds	r0, r4, #0
	ands	r1, r0
	lsls	r2, r2, #4
	movs	r0, #240
	ands	r2, r0
	orrs	r1, r2
	mov	r0, r8
	strh	r1, [r0, #4]
	strh	r3, [r0, #6]
	b.n	.L015f4
	movs	r0, r0
.L01a34:
	.4byte	0xfffff000
.L01a38:
	movs	r0, #2
	mov	r1, r8
	strb	r0, [r1, #3]
	mov	r2, r9
	lsls	r1, r2, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsrs	r0, r2, #4
	mov	r3, r8
	strh	r0, [r3, #6]
	movs	r0, #15
	ands	r2, r0
	strh	r2, [r3, #4]
	b.n	.L015f4
.L01a5a:
	movs	r0, #3
	mov	r4, r8
	strb	r0, [r4, #3]
	mov	r0, r9
	lsls	r1, r0, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	lsrs	r0, r2, #4
	strh	r0, [r4, #6]
	movs	r0, #15
	ands	r2, r0
	strh	r2, [r4, #4]
	b.n	.L015f4
.L01a7a:
	movs	r0, #4
	mov	r1, r8
	strb	r0, [r1, #3]
	mov	r3, r9
	lsls	r2, r3, #3
	adds	r2, r2, r7
	ldr	r0, [r2, #4]
	ldrb	r4, [r0, #0]
	lsls	r1, r4, #4
	mov	r3, r8
	strh	r1, [r3, #4]
	adds	r0, #1
	str	r0, [r2, #4]
	ldrb	r1, [r0, #0]
	strh	r1, [r3, #6]
	adds	r0, #1
	str	r0, [r2, #4]
	b.n	.L015f4
.L01a9e:
	mov	r4, r9
	lsls	r2, r4, #3
	adds	r2, r2, r7
	ldr	r0, [r2, #4]
	ldrb	r1, [r0, #0]
	adds	r0, #1
	str	r0, [r2, #4]
	movs	r0, #16
	negs	r0, r0
	adds	r2, r0, #0
	adds	r0, r1, #0
	ands	r0, r2
	movs	r2, #9
	movs	r4, #0
	orrs	r0, r2
	mov	r2, r8
	strb	r0, [r2, #3]
	movs	r0, #15
	ands	r1, r0
	adds	r1, #1
	lsls	r1, r1, #4
	b.n	.L01af2
.L01aca:
	mov	r4, r9
	lsls	r2, r4, #3
	adds	r2, r2, r7
	ldr	r0, [r2, #4]
	ldrb	r1, [r0, #0]
	adds	r0, #1
	str	r0, [r2, #4]
	movs	r0, #16
	negs	r0, r0
	adds	r2, r0, #0
	adds	r0, r1, #0
	ands	r0, r2
	movs	r2, #5
	movs	r4, #0
	orrs	r0, r2
	mov	r2, r8
	strb	r0, [r2, #3]
	movs	r0, #15
	ands	r1, r0
	adds	r1, #4
.L01af2:
	movs	r0, #128
	lsls	r0, r0, #7
	bl	__divsi3
	mov	r3, r8
	strh	r0, [r3, #4]
	strh	r4, [r3, #6]
	b.n	.L015f4
.L01b02:
	movs	r0, #1
	ldr	r4, [sp, #0]
	ands	r0, r4
	lsls	r0, r0, #3
	adds	r0, r0, r7
	mov	r1, r9
	lsls	r3, r1, #3
	adds	r3, r3, r7
	ldr	r2, [r3, #4]
	ldrb	r1, [r2, #0]
	strb	r1, [r0, #2]
	b.n	.L01b30
.L01b1a:
	movs	r0, #1
	ldr	r2, [sp, #0]
	ands	r0, r2
	lsls	r0, r0, #3
	adds	r0, r0, r7
	mov	r4, r9
	lsls	r3, r4, #3
	adds	r3, r3, r7
	ldr	r2, [r3, #4]
	ldrb	r1, [r2, #0]
	strb	r1, [r0, #3]
.L01b30:
	adds	r2, #1
	str	r2, [r3, #4]
	b.n	.L015f4
.L01b36:
	movs	r0, #1
	ldr	r1, [sp, #0]
	ands	r0, r1
	lsls	r0, r0, #3
	adds	r0, r0, r7
	movs	r1, #0
	strb	r1, [r0, #2]
	movs	r0, #255
	mov	r2, sl
	str	r0, [r2, #4]
	b.n	.L015f4
.L01b4c:
	mov	r3, r9
	lsls	r0, r3, #3
	adds	r0, r0, r7
	ldr	r1, [r0, #4]
	ldrb	r2, [r1, #0]
	adds	r1, #1
	str	r1, [r0, #4]
	mov	r4, r8
	ldrb	r1, [r4, #2]
	ldr	r3, .L01b80
	ldr	r0, [r3, #24]
	cmp	r1, r0
	blt.n	.L01b68
	b.n	.L015f4
.L01b68:
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, [r3, #28]
	adds	r1, r1, r0
	lsls	r2, r2, #24
	ldr	r0, [r1, #8]
	adds	r0, r0, r2
	mov	r1, sl
	str	r0, [r1, #8]
	b.n	.L015f4
	movs	r0, r0
.L01b80:
	.4byte	gbass_module
.L01b84:
	mov	r2, r9
	lsls	r1, r2, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r2, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	cmp	r2, #0
	bne.n	.L01bbc
	mov	r3, r8
	ldrb	r1, [r3, #2]
	ldr	r2, .L01bb8
	ldr	r0, [r2, #24]
	cmp	r1, r0
	blt.n	.L01ba4
	b.n	.L015f4
.L01ba4:
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, [r2, #28]
	adds	r1, r1, r0
	ldr	r0, [r1, #8]
	mov	r4, sl
	str	r0, [r4, #8]
	b.n	.L015f4
	movs	r0, r0
.L01bb8:
	.4byte	gbass_module
.L01bbc:
	movs	r0, #11
	mov	r1, r8
	strb	r0, [r1, #3]
	movs	r0, #15
	ands	r0, r2
	strh	r0, [r1, #4]
	strh	r0, [r1, #6]
	b.n	.L015f4
.L01bcc:
	movs	r0, #15
	ands	r3, r0
	subs	r0, r3, #2
	cmp	r0, #9
	bls.n	.L01bd8
	b.n	.L01d76
.L01bd8:
	lsls	r0, r0, #2
	ldr	r1, .L01be4
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
	movs	r0, r0
.L01be4:
	.4byte	.L01be8
.L01be8:
	.4byte	.L01c10
	.4byte	.L015f4
	.4byte	.L015f4
	.4byte	.L015f4
	.4byte	.L01c1a
	.4byte	.L01c20
	.4byte	.L01c44
	.4byte	.L01c68
	.4byte	.L01c76
	.4byte	.L01ce6
.L01c10:
	movs	r0, #2
	ldr	r2, [sp, #4]
	orrs	r2, r0
	str	r2, [sp, #4]
	b.n	.L015f4
.L01c1a:
	mov	r3, r9
	lsls	r1, r3, #3
	b.n	.L01c6c
.L01c20:
	ldr	r6, .L01c40
	mov	r4, r9
	lsls	r5, r4, #3
	adds	r5, r5, r7
	ldr	r4, [r5, #4]
	ldrb	r1, [r4, #0]
	lsls	r0, r1, #17
	movs	r1, #150
	lsls	r1, r1, #1
	bl	__divsi3
	str	r0, [r6, #104]
	adds	r4, #1
	str	r4, [r5, #4]
	b.n	.L015f4
	movs	r0, r0
.L01c40:
	.4byte	gbass_ram
.L01c44:
	mov	r3, sl
	ldr	r1, [r3, #20]
	ldr	r0, [r3, #16]
	cmp	r1, r0
	bne.n	.L01c5a
	ldr	r0, [r3, #8]
	adds	r0, r0, r1
	ldr	r1, [r3, #12]
	cmp	r0, r1
	bcc.n	.L01c5a
	b.n	.L015f4
.L01c5a:
	adds	r0, r2, r7
	ldr	r1, [r0, #4]
	subs	r1, #1
	str	r1, [r0, #4]
	movs	r1, #1
	strh	r1, [r0, #0]
	b.n	.L01d76
.L01c68:
	mov	r4, r9
	lsls	r1, r4, #3
.L01c6c:
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	adds	r0, #1
	str	r0, [r1, #4]
	b.n	.L015f4
.L01c76:
	mov	r0, r9
	lsls	r1, r0, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r3, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	ldr	r2, .L01cc4
	ldr	r1, [r2, #16]
	lsls	r0, r3, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	adds	r6, r2, #0
	ldrb	r1, [r0, #0]
	cmp	r1, #153
	beq.n	.L01c98
	b.n	.L015f4
.L01c98:
	ldrb	r0, [r0, #1]
	mov	r9, r0
	cmp	r0, #3
	ble.n	.L01ca2
	b.n	.L015f4
.L01ca2:
	asrs	r1, r0, #1
	movs	r2, #1
	ands	r1, r2
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	ldr	r1, [r6, #60]
	adds	r1, r1, r0
	mov	r0, r9
	ands	r0, r2
	lsls	r0, r0, #5
	adds	r2, r1, r0
	ldr	r4, [sp, #0]
	cmp	r4, #3
	beq.n	.L01cc8
	ldrb	r0, [r7, #11]
	b.n	.L01cce
.L01cc4:
	.4byte	gbass_module
.L01cc8:
	adds	r0, r7, #0
	subs	r0, #16
	ldrb	r0, [r0, #3]
.L01cce:
	strb	r0, [r2, #11]
	ldr	r1, [r6, #16]
	lsls	r0, r3, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	adds	r0, #2
	str	r0, [r2, #28]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r2, #24]
	strb	r1, [r2, #27]
	b.n	.L015f4
.L01ce6:
	mov	r0, r9
	lsls	r1, r0, #3
	adds	r1, r1, r7
	ldr	r0, [r1, #4]
	ldrb	r5, [r0, #0]
	adds	r0, #1
	str	r0, [r1, #4]
	ldrb	r4, [r0, #0]
	adds	r0, #2
	str	r0, [r1, #4]
	ldr	r2, .L01d54
	ldr	r1, [r2, #16]
	lsls	r0, r5, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	adds	r6, r2, #0
	ldrb	r1, [r0, #0]
	cmp	r1, #153
	beq.n	.L01d0e
	b.n	.L015f4
.L01d0e:
	ldrb	r0, [r0, #1]
	mov	r9, r0
	cmp	r0, #3
	ble.n	.L01d18
	b.n	.L015f4
.L01d18:
	asrs	r1, r0, #1
	movs	r3, #1
	ands	r1, r3
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	ldr	r2, [r6, #60]
	adds	r2, r2, r0
	mov	r0, r9
	ands	r0, r3
	lsls	r1, r0, #5
	adds	r3, r2, r1
	adds	r0, #2
	lsls	r0, r0, #3
	adds	r2, r2, r0
	movs	r1, #15
	adds	r0, r4, #0
	ands	r0, r1
	adds	r1, r2, #0
	adds	r1, #64
	strb	r0, [r1, #0]
	asrs	r0, r4, #4
	adds	r2, #65
	strb	r0, [r2, #0]
	ldr	r2, [sp, #0]
	cmp	r2, #3
	beq.n	.L01d58
	ldrb	r0, [r7, #11]
	b.n	.L01d5e
	movs	r0, r0
.L01d54:
	.4byte	gbass_module
.L01d58:
	adds	r0, r7, #0
	subs	r0, #16
	ldrb	r0, [r0, #3]
.L01d5e:
	strb	r0, [r3, #11]
	ldr	r1, [r6, #16]
	lsls	r0, r5, #2
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	adds	r0, #2
	str	r0, [r3, #28]
	movs	r1, #0
	movs	r0, #1
	strh	r0, [r3, #24]
	strb	r1, [r3, #27]
	b.n	.L015f4
.L01d76:
	movs	r3, #1
	add	r9, r3
	mov	r4, r9
	cmp	r4, #2
	bgt.n	.L01d82
	b.n	.L015da
.L01d82:
	ldr	r0, [sp, #0]
	cmp	r9, r0
	bne.n	.L01d8a
	b.n	.L015da
.L01d8a:
	movs	r0, #1
	ldr	r1, [sp, #0]
	ands	r0, r1
	lsls	r0, r0, #3
	adds	r2, r0, r7
	ldrb	r0, [r2, #2]
	cmp	r0, #0
	beq.n	.L01dbe
	movs	r1, #2
	ldrsb	r1, [r2, r1]
	mov	r3, sl
	ldr	r0, [r3, #4]
	adds	r0, r0, r1
	str	r0, [r3, #4]
	cmp	r0, #0
	bge.n	.L01db0
	movs	r0, #0
	str	r0, [r3, #4]
	b.n	.L01dbc
.L01db0:
	cmp	r0, #255
	ble.n	.L01dbe
	movs	r0, #255
	mov	r4, sl
	str	r0, [r4, #4]
	movs	r0, #0
.L01dbc:
	strb	r0, [r2, #2]
.L01dbe:
	ldr	r0, [sp, #0]
	cmp	r0, #3
	beq.n	.L01dfe
	movs	r0, #1
	ldr	r1, [sp, #0]
	ands	r0, r1
	lsls	r0, r0, #3
	adds	r1, r0, r7
	ldrb	r0, [r1, #3]
	cmp	r0, #0
	beq.n	.L01dfe
	movs	r0, #3
	ldrsb	r0, [r1, r0]
	mov	r2, sl
	ldrh	r2, [r2, #24]
	adds	r0, r2, r0
	movs	r2, #0
	mov	r3, sl
	strh	r0, [r3, #24]
	lsls	r0, r0, #16
	asrs	r0, r0, #16
	cmp	r0, #0
	bge.n	.L01df2
	movs	r0, #0
	strh	r0, [r3, #24]
	b.n	.L01dfc
.L01df2:
	cmp	r0, #255
	ble.n	.L01dfe
	movs	r0, #255
	mov	r4, sl
	strh	r0, [r4, #24]
.L01dfc:
	strb	r2, [r1, #3]
.L01dfe:
	ldr	r0, [sp, #12]
	cmp	r0, #255
	bne.n	.L01e06
	b.n	.L021ea
.L01e06:
	mov	r1, r8
	ldrb	r0, [r1, #3]
	movs	r1, #15
	ands	r1, r0
	adds	r6, r0, #0
	cmp	r1, #11
	bls.n	.L01e16
	b.n	.L021ea
.L01e16:
	lsls	r0, r1, #2
	ldr	r1, .L01e20
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
.L01e20:
	.4byte	.L01e24
.L01e24:
	.4byte	.L021ea
	.4byte	.L01e54
	.4byte	.L01eec
	.4byte	.L01f54
	.4byte	.L01fc6
	.4byte	.L020d4
	.4byte	.L021ea
	.4byte	.L021ea
	.4byte	.L021ea
	.4byte	.L02152
	.4byte	.L021ea
	.4byte	.L021bc
.L01e54:
	mov	r2, r8
	ldrh	r1, [r2, #6]
	cmp	r1, #1
	beq.n	.L01e82
	cmp	r1, #1
	bgt.n	.L01e66
	cmp	r1, #0
	beq.n	.L01e6c
	b.n	.L021ea
.L01e66:
	cmp	r1, #2
	beq.n	.L01eb8
	b.n	.L021ea
.L01e6c:
	mov	r3, r8
	ldrb	r3, [r3, #0]
	str	r3, [sp, #12]
	mov	r4, r8
	ldrb	r4, [r4, #1]
	str	r4, [sp, #8]
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	b.n	.L01f46
.L01e82:
	mov	r3, r8
	ldrh	r3, [r3, #4]
	lsrs	r0, r3, #8
	mov	r4, r8
	ldrb	r4, [r4, #0]
	adds	r0, r4, r0
	str	r0, [sp, #12]
	mov	r0, r8
	ldrb	r0, [r0, #1]
	str	r0, [sp, #8]
	ldr	r2, [sp, #12]
	cmp	r2, #191
	bls.n	.L01eae
	adds	r0, #1
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #8]
	adds	r0, r2, #0
	subs	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
.L01eae:
	ldr	r3, [sp, #4]
	orrs	r3, r1
	str	r3, [sp, #4]
	movs	r0, #2
	b.n	.L021b6
.L01eb8:
	mov	r0, r8
	ldrb	r1, [r0, #0]
	ldrb	r0, [r0, #4]
	adds	r0, r1, r0
	str	r0, [sp, #12]
	mov	r1, r8
	ldrb	r1, [r1, #1]
	str	r1, [sp, #8]
	cmp	r0, #191
	bls.n	.L01ee0
	adds	r0, r1, #0
	adds	r0, #1
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #8]
	ldr	r0, [sp, #12]
	subs	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
.L01ee0:
	movs	r0, #1
	ldr	r2, [sp, #4]
	orrs	r2, r0
	str	r2, [sp, #4]
	movs	r0, #0
	b.n	.L0214c
.L01eec:
	mov	r4, r8
	ldrh	r0, [r4, #6]
	lsrs	r1, r0, #8
	adds	r5, r0, #0
	ldrb	r0, [r4, #6]
	cmp	r1, r0
	bne.n	.L01f4c
	ldrb	r1, [r4, #1]
	str	r1, [sp, #8]
	ldrb	r0, [r4, #4]
	adds	r0, #1
	ldrb	r2, [r4, #0]
	adds	r0, r2, r0
	strb	r0, [r4, #0]
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
	cmp	r0, #191
	bls.n	.L01f3a
	cmp	r1, #9
	bne.n	.L01f20
	movs	r0, #191
	strb	r0, [r4, #0]
	movs	r3, #191
	str	r3, [sp, #12]
	b.n	.L01f3a
.L01f20:
	ldr	r1, [sp, #8]
	adds	r1, #1
	lsls	r0, r1, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #8]
	mov	r4, r8
	strb	r1, [r4, #1]
	ldr	r1, [sp, #12]
	subs	r1, #192
	lsls	r0, r1, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
	strb	r1, [r4, #0]
.L01f3a:
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	movs	r0, #255
	ands	r0, r5
.L01f46:
	mov	r2, r8
	strh	r0, [r2, #6]
	b.n	.L021ea
.L01f4c:
	movs	r3, #128
	lsls	r3, r3, #1
	adds	r0, r5, r3
	b.n	.L021b6
.L01f54:
	mov	r1, r8
	ldrh	r0, [r1, #6]
	lsrs	r1, r0, #8
	adds	r5, r0, #0
	mov	r2, r8
	ldrb	r2, [r2, #6]
	cmp	r1, r2
	bne.n	.L01fba
	mov	r3, r8
	ldrb	r3, [r3, #1]
	str	r3, [sp, #8]
	mov	r4, r8
	ldrb	r1, [r4, #0]
	ldrh	r4, [r4, #4]
	subs	r0, r1, r4
	subs	r0, #1
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
	mov	r1, r8
	strb	r0, [r1, #0]
	ldr	r2, [sp, #12]
	cmp	r2, #191
	bls.n	.L01fac
	cmp	r3, #0
	bne.n	.L01f90
	strb	r3, [r1, #0]
	movs	r4, #0
	str	r4, [sp, #12]
	b.n	.L01fac
.L01f90:
	ldr	r1, [sp, #8]
	subs	r1, #1
	lsls	r0, r1, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #8]
	mov	r0, r8
	strb	r1, [r0, #1]
	ldr	r0, [sp, #12]
	adds	r0, #192
	mov	r1, r8
	strb	r0, [r1, #0]
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
.L01fac:
	movs	r0, #1
	ldr	r2, [sp, #4]
	orrs	r2, r0
	str	r2, [sp, #4]
	movs	r0, #255
	ands	r0, r5
	b.n	.L0214c
.L01fba:
	movs	r4, #128
	lsls	r4, r4, #1
	adds	r0, r5, r4
	mov	r1, r8
	strh	r0, [r1, #6]
	b.n	.L021ea
.L01fc6:
	mov	r2, r8
	ldrb	r0, [r2, #1]
	ldrh	r1, [r2, #4]
	lsrs	r2, r1, #8
	adds	r3, r0, #0
	adds	r4, r1, #0
	cmp	r0, r2
	bhi.n	.L01fe6
	cmp	r0, r2
	bne.n	.L02050
	movs	r0, #255
	ands	r0, r4
	mov	r1, r8
	ldrb	r1, [r1, #0]
	cmp	r1, r0
	bls.n	.L02050
.L01fe6:
	str	r3, [sp, #8]
	mov	r2, r8
	ldrb	r3, [r2, #0]
	ldrh	r2, [r2, #6]
	subs	r0, r3, r2
	subs	r0, #1
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
	mov	r3, r8
	strb	r0, [r3, #0]
	ldr	r0, [sp, #12]
	cmp	r0, #191
	bls.n	.L02030
	movs	r2, #255
.L02004:
	ldr	r1, [sp, #8]
	cmp	r1, #0
	bne.n	.L02012
	mov	r3, r8
	strb	r1, [r3, #0]
	movs	r0, #0
	b.n	.L02028
.L02012:
	ldr	r0, [sp, #8]
	subs	r0, #1
	lsls	r1, r0, #24
	lsrs	r1, r1, #24
	str	r1, [sp, #8]
	mov	r1, r8
	strb	r0, [r1, #1]
	ldr	r0, [sp, #12]
	adds	r0, #192
	strb	r0, [r1, #0]
	ands	r0, r2
.L02028:
	str	r0, [sp, #12]
	ldr	r3, [sp, #12]
	cmp	r3, #191
	bhi.n	.L02004
.L02030:
	lsls	r0, r4, #16
	lsrs	r2, r0, #24
	mov	r0, r8
	ldrb	r1, [r0, #1]
	adds	r0, r2, #0
	cmp	r1, r0
	bcc.n	.L020b8
	cmp	r1, r0
	bne.n	.L020ca
	movs	r0, #255
	ands	r0, r4
	mov	r1, r8
	ldrb	r1, [r1, #0]
	cmp	r1, r0
	bhi.n	.L020ca
	b.n	.L020b8
.L02050:
	str	r3, [sp, #8]
	mov	r1, r8
	ldrb	r0, [r1, #6]
	adds	r0, #1
	ldrb	r2, [r1, #0]
	adds	r0, r2, r0
	strb	r0, [r1, #0]
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
	cmp	r0, #191
	bls.n	.L02098
	movs	r3, #191
	movs	r2, #255
.L0206c:
	ldr	r0, [sp, #8]
	cmp	r0, #9
	bne.n	.L0207a
	mov	r1, r8
	strb	r3, [r1, #0]
	movs	r0, #191
	b.n	.L02090
.L0207a:
	ldr	r0, [sp, #8]
	adds	r0, #1
	lsls	r1, r0, #24
	lsrs	r1, r1, #24
	str	r1, [sp, #8]
	mov	r1, r8
	strb	r0, [r1, #1]
	ldr	r0, [sp, #12]
	adds	r0, #64
	strb	r0, [r1, #0]
	ands	r0, r2
.L02090:
	str	r0, [sp, #12]
	ldr	r0, [sp, #12]
	cmp	r0, #191
	bhi.n	.L0206c
.L02098:
	adds	r3, r4, #0
	lsls	r0, r3, #16
	lsrs	r2, r0, #24
	mov	r0, r8
	ldrb	r1, [r0, #1]
	adds	r0, r2, #0
	cmp	r1, r0
	bhi.n	.L020b8
	cmp	r1, r0
	bne.n	.L020ca
	movs	r0, #255
	ands	r0, r3
	mov	r1, r8
	ldrb	r1, [r1, #0]
	cmp	r1, r0
	bcc.n	.L020ca
.L020b8:
	movs	r0, #0
	mov	r3, r8
	strb	r0, [r3, #3]
	strb	r2, [r3, #1]
	str	r2, [sp, #8]
	strb	r4, [r3, #0]
	lsls	r0, r4, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #12]
.L020ca:
	movs	r0, #1
	ldr	r4, [sp, #4]
	orrs	r4, r0
	str	r4, [sp, #4]
	b.n	.L021ea
.L020d4:
	mov	r0, r8
	ldrb	r0, [r0, #1]
	str	r0, [sp, #8]
	ldr	r2, .L02120
	mov	r1, r8
	ldrh	r3, [r1, #6]
	lsrs	r0, r3, #8
	movs	r1, #63
	ands	r0, r1
	adds	r0, r0, r2
	movs	r1, #0
	ldrsb	r1, [r0, r1]
	lsls	r0, r6, #24
	lsrs	r0, r0, #28
	adds	r0, #1
	muls	r0, r1
	asrs	r0, r0, #7
	mov	r2, r8
	ldrb	r2, [r2, #0]
	adds	r0, r2, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
	movs	r0, #128
	lsls	r0, r0, #8
	adds	r5, r3, #0
	ldr	r3, [sp, #12]
	cmp	r3, r0
	bls.n	.L02124
	adds	r0, r3, #0
	adds	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
	ldr	r0, [sp, #8]
	subs	r0, #1
	b.n	.L02138
	movs	r0, r0
.L02120:
	.4byte	vibrato_table
.L02124:
	ldr	r4, [sp, #12]
	cmp	r4, #192
	bls.n	.L0213e
	adds	r0, r4, #0
	subs	r0, #192
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [sp, #12]
	ldr	r0, [sp, #8]
	adds	r0, #1
.L02138:
	lsls	r0, r0, #24
	lsrs	r0, r0, #24
	str	r0, [sp, #8]
.L0213e:
	movs	r0, #1
	ldr	r1, [sp, #4]
	orrs	r1, r0
	str	r1, [sp, #4]
	mov	r2, r8
	ldrh	r2, [r2, #4]
	adds	r0, r2, r5
.L0214c:
	mov	r3, r8
	strh	r0, [r3, #6]
	b.n	.L021ea
.L02152:
	mov	r4, r8
	ldrb	r1, [r4, #2]
	ldr	r2, .L021a0
	ldr	r0, [r2, #24]
	ldrh	r5, [r4, #6]
	cmp	r1, r0
	bge.n	.L021b0
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r3, [r2, #28]
	adds	r3, r3, r0
	ldr	r2, [r3, #0]
	ldr	r0, .L021a4
	ands	r2, r0
	ldr	r4, .L021a8
	lsrs	r1, r5, #8
	movs	r0, #63
	ands	r1, r0
	adds	r1, r1, r4
	lsls	r0, r6, #24
	lsrs	r0, r0, #28
	adds	r0, #1
	ldrb	r1, [r1, #0]
	muls	r0, r1
	asrs	r0, r0, #4
	adds	r2, r2, r0
	mov	r0, sl
	str	r2, [r0, #0]
	ldr	r0, [r3, #12]
	mov	r1, sl
	str	r0, [r1, #12]
	ldr	r0, [r3, #16]
	cmp	r0, #0
	bne.n	.L021ac
	ldr	r0, [r1, #16]
	str	r0, [r1, #20]
	b.n	.L021b0
	movs	r0, r0
.L021a0:
	.4byte	gbass_module
.L021a4:
	.4byte	0x0fffffff
.L021a8:
	.4byte	wavevibrato_table
.L021ac:
	mov	r2, sl
	str	r0, [r2, #20]
.L021b0:
	mov	r3, r8
	ldrh	r3, [r3, #4]
	adds	r0, r3, r5
.L021b6:
	mov	r4, r8
	strh	r0, [r4, #6]
	b.n	.L021ea
.L021bc:
	mov	r1, r8
	ldrh	r0, [r1, #6]
	subs	r0, #1
	strh	r0, [r1, #6]
	lsls	r0, r0, #16
	cmp	r0, #0
	bne.n	.L021ea
	ldrb	r1, [r1, #2]
	mov	r2, r8
	ldrh	r0, [r2, #4]
	strh	r0, [r2, #6]
	ldr	r2, .L02248
	ldr	r0, [r2, #24]
	cmp	r1, r0
	bge.n	.L021ea
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #3
	ldr	r1, [r2, #28]
	adds	r1, r1, r0
	ldr	r0, [r1, #8]
	mov	r3, sl
	str	r0, [r3, #8]
.L021ea:
	ldr	r4, [sp, #4]
	cmp	r4, #0
	bne.n	.L021f2
	b.n	.L02372
.L021f2:
	movs	r0, #1
	ands	r4, r0
	cmp	r4, #0
	bne.n	.L021fc
	b.n	.L02372
.L021fc:
	ldr	r0, [sp, #12]
	cmp	r0, #191
	bls.n	.L02204
	b.n	.L0236c
.L02204:
	mov	r2, sl
	ldr	r1, [r2, #20]
	ldr	r0, [r2, #16]
	cmp	r1, r0
	bne.n	.L022c4
	ldr	r0, .L02248
	mov	r3, r8
	ldrb	r3, [r3, #2]
	lsls	r1, r3, #1
	mov	r4, r8
	ldrb	r4, [r4, #2]
	adds	r1, r1, r4
	lsls	r1, r1, #3
	ldr	r0, [r0, #28]
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	cmp	r0, #0
	bge.n	.L02270
	ldr	r0, [sp, #8]
	cmp	r0, #4
	bhi.n	.L02250
	ldr	r1, .L0224c
	ldr	r2, [sp, #12]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	movs	r1, #5
	ldr	r3, [sp, #8]
	subs	r1, r1, r3
	ldr	r0, [r0, #0]
	lsrs	r0, r1
	mov	r4, sl
	str	r0, [r4, #16]
	b.n	.L02264
	movs	r0, r0
.L02248:
	.4byte	gbass_module
.L0224c:
	.4byte	digi_notes
.L02250:
	ldr	r1, .L0226c
	ldr	r2, [sp, #12]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	ldr	r1, [sp, #8]
	subs	r1, #5
	ldr	r0, [r0, #0]
	lsls	r0, r1
	mov	r3, sl
	str	r0, [r3, #16]
.L02264:
	mov	r4, sl
	ldr	r0, [r4, #16]
	str	r0, [r4, #20]
	b.n	.L02372
.L0226c:
	.4byte	digi_notes
.L02270:
	ldr	r0, .L02284
	ldr	r0, [r0, #92]
	cmp	r0, #0
	beq.n	.L02288
	ldr	r0, [sp, #12]
	ldr	r1, [sp, #8]
	bl	GBASS_DigiTranspose
	adds	r1, r0, #0
	b.n	.L022b8
.L02284:
	.4byte	gbass_ram
.L02288:
	ldr	r0, [sp, #8]
	cmp	r0, #4
	bhi.n	.L022a8
	ldr	r0, .L022a4
	ldr	r2, [sp, #12]
	lsls	r1, r2, #2
	adds	r1, r1, r0
	movs	r0, #5
	ldr	r3, [sp, #8]
	subs	r0, r0, r3
	ldr	r1, [r1, #0]
	lsrs	r1, r0
	b.n	.L022b8
	movs	r0, r0
.L022a4:
	.4byte	digi_notes
.L022a8:
	ldr	r0, .L022c0
	ldr	r4, [sp, #12]
	lsls	r1, r4, #2
	adds	r1, r1, r0
	ldr	r0, [sp, #8]
	subs	r0, #5
	ldr	r1, [r1, #0]
	lsls	r1, r0
.L022b8:
	mov	r0, sl
	str	r1, [r0, #16]
	str	r1, [r0, #20]
	b.n	.L02372
.L022c0:
	.4byte	digi_notes
.L022c4:
	ldr	r0, .L022fc
	mov	r2, r8
	ldrb	r2, [r2, #2]
	lsls	r1, r2, #1
	mov	r3, r8
	ldrb	r3, [r3, #2]
	adds	r1, r1, r3
	lsls	r1, r1, #3
	ldr	r0, [r0, #28]
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	cmp	r0, #0
	bge.n	.L0231c
	ldr	r4, [sp, #8]
	cmp	r4, #4
	bhi.n	.L02304
	ldr	r1, .L02300
	ldr	r2, [sp, #12]
	lsls	r0, r2, #2
	adds	r0, r0, r1
	movs	r1, #5
	subs	r1, r1, r4
	ldr	r0, [r0, #0]
	lsrs	r0, r1
	mov	r3, sl
	str	r0, [r3, #16]
	b.n	.L02372
	movs	r0, r0
.L022fc:
	.4byte	gbass_module
.L02300:
	.4byte	digi_notes
.L02304:
	ldr	r1, .L02318
	ldr	r4, [sp, #12]
	lsls	r0, r4, #2
	adds	r0, r0, r1
	ldr	r1, [sp, #8]
	subs	r1, #5
	ldr	r0, [r0, #0]
	lsls	r0, r1
	b.n	.L0236e
	movs	r0, r0
.L02318:
	.4byte	digi_notes
.L0231c:
	ldr	r0, .L02330
	ldr	r0, [r0, #92]
	cmp	r0, #0
	beq.n	.L02334
	ldr	r0, [sp, #12]
	ldr	r1, [sp, #8]
	bl	GBASS_DigiTranspose
	adds	r1, r0, #0
	b.n	.L02360
.L02330:
	.4byte	gbass_ram
.L02334:
	ldr	r2, [sp, #8]
	cmp	r2, #4
	bhi.n	.L02350
	ldr	r0, .L0234c
	ldr	r3, [sp, #12]
	lsls	r1, r3, #2
	adds	r1, r1, r0
	movs	r0, #5
	subs	r0, r0, r2
	ldr	r1, [r1, #0]
	lsrs	r1, r0
	b.n	.L02360
.L0234c:
	.4byte	digi_notes
.L02350:
	ldr	r0, .L02368
	ldr	r4, [sp, #12]
	lsls	r1, r4, #2
	adds	r1, r1, r0
	ldr	r0, [sp, #8]
	subs	r0, #5
	ldr	r1, [r1, #0]
	lsls	r1, r0
.L02360:
	mov	r0, sl
	str	r1, [r0, #16]
	b.n	.L02372
	movs	r0, r0
.L02368:
	.4byte	digi_notes
.L0236c:
	movs	r0, #0
.L0236e:
	mov	r1, sl
	str	r0, [r1, #16]
.L02372:
	add	sp, #16
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0

@
@ GBASS_SilentMix(Mixer *m): advances a mixer by 64 samples without output (used
@ for music voices covered by a sound effect, so they stay in time).
	.global	GBASS_SilentMix
	.thumb_func
	.type	GBASS_SilentMix, %function
GBASS_SilentMix:
	push	{r4, r5, r6, lr}
	adds	r6, r0, #0
	ldr	r5, [r6, #16]
	adds	r0, r5, #0
	movs	r1, #0
	ldr	r4, [r6, #28]
	adds	r2, r4, #0
	asrs	r3, r4, #31
	bl	__muldi3
	lsls	r3, r1, #16
	lsrs	r2, r0, #16
	adds	r0, r3, #0
	orrs	r0, r2
	adds	r4, r0, #0
	ldr	r3, [r6, #12]
	ldr	r2, [r6, #20]
	cmp	r5, r2
	beq.n	.L023ac
	adds	r0, r2, #0
.L023ac:
	ldr	r2, [r6, #8]
	movs	r1, #15
	movs	r5, #1
	negs	r5, r5
.L023b4:
	adds	r2, r2, r4
	cmp	r2, r3
	bls.n	.L023bc
	subs	r2, r2, r0
.L023bc:
	adds	r2, r2, r4
	cmp	r2, r3
	bls.n	.L023c4
	subs	r2, r2, r0
.L023c4:
	adds	r2, r2, r4
	cmp	r2, r3
	bls.n	.L023cc
	subs	r2, r2, r0
.L023cc:
	adds	r2, r2, r4
	cmp	r2, r3
	bls.n	.L023d4
	subs	r2, r2, r0
.L023d4:
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L023b4
	str	r2, [r6, #8]
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
	movs	r0, r0

@
@ void GBASS_Process(void)  [API] -- once per frame, after DMACriticalProcess.
@ If an API call holds the lock (ram+8) it only counts a deferred call.
@ Otherwise: accumulates speed*tempo; for every whole tick runs all music
@ channels (Process_Digital level 0 per digital channel, Process_GB per GB
@ channel) and bumps the song time; then runs the sound-effect levels; then mixes
@ rate x 64 samples: per mix buffer, two voices per pair via Mov_2MOD (sfx mixer
@ replaces the music mixer while an sfx plays; the music mixer is advanced by
@ SilentMix unless no-music mode), buffers summed into the left/right DMA halves
@ by Mix_Buffers (or written directly in single-buffer mode); finally CrossMix
@ if headphone mode is on.
	.global	GBASS_Process
	.thumb_func
	.type	GBASS_Process, %function
GBASS_Process:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #28
	ldr	r4, .L02400
	ldr	r0, [r4, #8]
	cmp	r0, #0
	beq.n	.L02404
	ldr	r0, [r4, #12]
	adds	r0, #1
	str	r0, [r4, #12]
	b.n	.L02b76
.L02400:
	.4byte	gbass_ram
.L02404:
	ldr	r0, [r4, #96]
	movs	r1, #0
	ldr	r2, [r4, #104]
	movs	r3, #0
	bl	__muldi3
	lsls	r3, r1, #16
	lsrs	r2, r0, #16
	adds	r0, r3, #0
	orrs	r0, r2
	ldr	r2, [r4, #100]
	adds	r2, r2, r0
	str	r2, [r4, #100]
	ldr	r0, .L02610
	cmp	r2, r0
	bhi.n	.L024da
	ldr	r0, .L02614
	cmp	r2, r0
	bls.n	.L024da
	mov	r9, r4
.L0242c:
	mov	r1, r9
	ldr	r0, [r1, #100]
	ldr	r2, .L02618
	adds	r0, r0, r2
	str	r0, [r1, #100]
	ldr	r0, [r1, #72]
	adds	r0, #1
	str	r0, [r1, #72]
	ldr	r7, [r1, #84]
	subs	r7, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r7, r0
	beq.n	.L0248e
	ldr	r3, .L0261c
	mov	sl, r3
	ldr	r0, [r3, #36]
	adds	r6, r0, #0
	adds	r6, #32
	adds	r5, r0, #0
	movs	r4, #0
	mov	r8, r4
.L02458:
	mov	r0, sl
	ldr	r4, [r0, #44]
	add	r4, r8
	adds	r0, r4, #0
	adds	r0, #64
	adds	r1, r4, #0
	adds	r2, r5, #0
	movs	r3, #0
	bl	GBASS_Process_Digital
	adds	r0, r4, #0
	adds	r0, #72
	adds	r4, #32
	adds	r1, r4, #0
	adds	r2, r6, #0
	movs	r3, #0
	bl	GBASS_Process_Digital
	adds	r6, #64
	adds	r5, #64
	movs	r1, #96
	add	r8, r1
	subs	r7, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r7, r0
	bne.n	.L02458
.L0248e:
	ldr	r0, .L0261c
	ldr	r4, [r0, #60]
	adds	r0, r4, #0
	adds	r0, #64
	adds	r1, r4, #0
	movs	r2, #0
	movs	r3, #0
	bl	GBASS_Process_GB
	adds	r0, r4, #0
	adds	r0, #72
	adds	r1, r4, #0
	adds	r1, #32
	movs	r2, #1
	movs	r3, #0
	bl	GBASS_Process_GB
	adds	r0, r4, #0
	adds	r0, #160
	adds	r1, r4, #0
	adds	r1, #96
	movs	r2, #2
	movs	r3, #0
	bl	GBASS_Process_GB
	adds	r0, r4, #0
	adds	r0, #168
	adds	r1, r4, #0
	adds	r1, #128
	movs	r2, #3
	movs	r3, #0
	bl	GBASS_Process_GB
	mov	r2, r9
	ldr	r1, [r2, #100]
	ldr	r0, .L02614
	cmp	r1, r0
	bhi.n	.L0242c
.L024da:
	ldr	r0, .L02620
	ldr	r7, [r0, #84]
	subs	r7, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r7, r0
	beq.n	.L0252e
	ldr	r3, .L0261c
	mov	r9, r3
	ldr	r0, [r3, #40]
	adds	r6, r0, #0
	adds	r6, #32
	adds	r5, r0, #0
	movs	r4, #0
	mov	r8, r4
.L024f8:
	mov	r0, r9
	ldr	r4, [r0, #44]
	add	r4, r8
	adds	r0, r4, #0
	adds	r0, #80
	adds	r1, r4, #0
	adds	r2, r5, #0
	movs	r3, #3
	bl	GBASS_Process_Digital
	adds	r0, r4, #0
	adds	r0, #88
	adds	r4, #32
	adds	r1, r4, #0
	adds	r2, r6, #0
	movs	r3, #3
	bl	GBASS_Process_Digital
	adds	r6, #64
	adds	r5, #64
	movs	r1, #96
	add	r8, r1
	subs	r7, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r7, r0
	bne.n	.L024f8
.L0252e:
	ldr	r4, .L0261c
	ldr	r1, [r4, #60]
	ldrh	r0, [r1, #24]
	cmp	r0, #0
	beq.n	.L02544
	adds	r0, r1, #0
	adds	r0, #80
	movs	r2, #0
	movs	r3, #3
	bl	GBASS_Process_GB
.L02544:
	ldr	r1, [r4, #60]
	ldrh	r0, [r1, #56]
	cmp	r0, #0
	beq.n	.L0255a
	adds	r0, r1, #0
	adds	r0, #88
	adds	r1, #32
	movs	r2, #1
	movs	r3, #3
	bl	GBASS_Process_GB
.L0255a:
	ldr	r1, [r4, #60]
	adds	r0, r1, #0
	adds	r0, #120
	ldrh	r0, [r0, #0]
	cmp	r0, #0
	beq.n	.L02574
	adds	r0, r1, #0
	adds	r0, #176
	adds	r1, #96
	movs	r2, #2
	movs	r3, #3
	bl	GBASS_Process_GB
.L02574:
	ldr	r1, [r4, #60]
	adds	r0, r1, #0
	adds	r0, #152
	ldrh	r0, [r0, #0]
	cmp	r0, #0
	beq.n	.L0258e
	adds	r0, r1, #0
	adds	r0, #184
	adds	r1, #128
	movs	r2, #3
	movs	r3, #3
	bl	GBASS_Process_GB
.L0258e:
	ldr	r2, .L02620
	ldr	r0, [r2, #68]
	movs	r1, #2
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L0259c
	b.n	.L0285c
.L0259c:
	ldr	r3, [r2, #0]
	str	r3, [sp, #4]
	ldr	r0, [r2, #76]
	subs	r0, #1
	subs	r1, #3
	cmp	r0, r1
	bne.n	.L025ac
	b.n	.L02b4c
.L025ac:
	movs	r4, #0
	mov	r8, r4
	movs	r1, #0
	str	r1, [sp, #0]
	ldr	r2, .L02620
	ldr	r7, [r2, #80]
	subs	r7, #1
	subs	r0, #1
	str	r0, [sp, #8]
	ldr	r3, [sp, #4]
	adds	r3, #1
	str	r3, [sp, #12]
	subs	r4, #1
	cmp	r7, r4
	bne.n	.L025cc
	b.n	.L026f2
.L025cc:
	ldr	r0, .L0261c
	mov	sl, r0
	mov	r9, r1
.L025d2:
	mov	r2, r8
	asrs	r1, r2, #1
	mov	r3, sl
	ldr	r2, [r3, #44]
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	adds	r0, r0, r2
	ldrh	r0, [r0, #24]
	adds	r4, r1, #0
	cmp	r0, #0
	beq.n	.L02624
	ldr	r0, [r3, #40]
	mov	r1, r9
	adds	r6, r0, r1
	ldr	r2, .L02620
	ldr	r1, [r2, #68]
	movs	r0, #128
	lsls	r0, r0, #7
	ands	r1, r0
	mov	r3, r8
	lsls	r5, r3, #5
	cmp	r1, #0
	bne.n	.L02630
	mov	r1, sl
	ldr	r0, [r1, #36]
	add	r0, r9
	bl	GBASS_SilentMix
	b.n	.L02630
	movs	r0, r0
.L02610:
	.4byte	0x7ffffffe
.L02614:
	.4byte	0x0000ffff
.L02618:
	.4byte	0xffff0000
.L0261c:
	.4byte	gbass_module
.L02620:
	.4byte	gbass_ram
.L02624:
	mov	r2, sl
	ldr	r0, [r2, #36]
	mov	r3, r9
	adds	r6, r0, r3
	mov	r0, r8
	lsls	r5, r0, #5
.L02630:
	ldr	r2, .L02664
	ldr	r0, [r2, #44]
	lsls	r1, r4, #1
	adds	r1, r1, r4
	lsls	r1, r1, #5
	adds	r1, r1, r0
	ldrh	r0, [r1, #56]
	cmp	r0, #0
	beq.n	.L0266c
	ldr	r0, [r2, #40]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #32
	ldr	r1, .L02668
	ldr	r0, [r1, #68]
	movs	r1, #128
	lsls	r1, r1, #7
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L02674
	ldr	r0, [r2, #36]
	adds	r0, r0, r5
	adds	r0, #32
	bl	GBASS_SilentMix
	b.n	.L02674
.L02664:
	.4byte	gbass_module
.L02668:
	.4byte	gbass_ram
.L0266c:
	ldr	r0, [r2, #36]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #32
.L02674:
	ldr	r2, .L0269c
	ldr	r1, [r2, #56]
	ldr	r3, [sp, #0]
	adds	r1, r1, r3
	movs	r0, #8
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L026a4
	ldr	r1, [sp, #4]
	lsls	r0, r1, #6
	ldr	r2, [r2, #64]
	adds	r2, r2, r0
	ldr	r0, .L026a0
	ldr	r3, [r0, #40]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
	b.n	.L026b8
.L0269c:
	.4byte	gbass_module
.L026a0:
	.4byte	gbass_ram
.L026a4:
	ldr	r1, [sp, #4]
	lsls	r0, r1, #6
	ldr	r2, [r2, #64]
	adds	r2, r2, r0
	ldr	r0, .L026d4
	ldr	r3, [r0, #36]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
.L026b8:
	mov	r2, sl
	ldr	r1, [r2, #56]
	ldr	r3, [sp, #0]
	adds	r1, r1, r3
	movs	r0, #1
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L026d8
	movs	r4, #128
	add	r9, r4
	movs	r0, #4
	add	r8, r0
	b.n	.L026e0
.L026d4:
	.4byte	gbass_ram
.L026d8:
	movs	r1, #64
	add	r9, r1
	movs	r2, #2
	add	r8, r2
.L026e0:
	ldr	r3, [sp, #0]
	adds	r3, #1
	str	r3, [sp, #0]
	subs	r7, #1
	movs	r4, #1
	negs	r4, r4
	cmp	r7, r4
	beq.n	.L026f2
	b.n	.L025d2
.L026f2:
	movs	r0, #0
	mov	r8, r0
	movs	r1, #0
	str	r1, [sp, #0]
	ldr	r2, .L02768
	ldr	r7, [r2, #80]
	subs	r7, #1
	movs	r3, #1
	negs	r3, r3
	cmp	r7, r3
	bne.n	.L0270a
	b.n	.L0284a
.L0270a:
	adds	r4, r2, #0
	mov	sl, r4
	mov	r9, r1
.L02710:
	ldr	r0, .L0276c
	ldr	r1, [r0, #56]
	ldr	r2, [sp, #0]
	adds	r1, r1, r2
	movs	r0, #1
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L02724
	b.n	.L02830
.L02724:
	mov	r3, r8
	asrs	r1, r3, #1
	ldr	r4, .L0276c
	ldr	r2, [r4, #44]
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	adds	r0, r0, r2
	adds	r0, #96
	ldrh	r0, [r0, #24]
	adds	r4, r1, #0
	cmp	r0, #0
	beq.n	.L02770
	ldr	r1, .L0276c
	ldr	r0, [r1, #40]
	add	r0, r9
	adds	r6, r0, #0
	adds	r6, #64
	mov	r2, sl
	ldr	r1, [r2, #68]
	movs	r0, #128
	lsls	r0, r0, #7
	ands	r1, r0
	lsls	r5, r3, #5
	cmp	r1, #0
	bne.n	.L0277e
	ldr	r3, .L0276c
	ldr	r0, [r3, #36]
	add	r0, r9
	adds	r0, #64
	bl	GBASS_SilentMix
	b.n	.L0277e
	movs	r0, r0
.L02768:
	.4byte	gbass_ram
.L0276c:
	.4byte	gbass_module
.L02770:
	ldr	r1, .L027b4
	ldr	r0, [r1, #36]
	add	r0, r9
	adds	r6, r0, #0
	adds	r6, #64
	mov	r2, r8
	lsls	r5, r2, #5
.L0277e:
	ldr	r2, .L027b4
	ldr	r0, [r2, #44]
	lsls	r1, r4, #1
	adds	r1, r1, r4
	lsls	r1, r1, #5
	adds	r1, r1, r0
	adds	r1, #96
	ldrh	r0, [r1, #56]
	cmp	r0, #0
	beq.n	.L027b8
	ldr	r0, [r2, #40]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #96
	mov	r3, sl
	ldr	r0, [r3, #68]
	movs	r1, #128
	lsls	r1, r1, #7
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L027c0
	ldr	r0, [r2, #36]
	adds	r0, r0, r5
	adds	r0, #96
	bl	GBASS_SilentMix
	b.n	.L027c0
.L027b4:
	.4byte	gbass_module
.L027b8:
	ldr	r0, [r2, #36]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #96
.L027c0:
	ldr	r2, .L027f0
	ldr	r1, [r2, #56]
	ldr	r0, [sp, #0]
	adds	r1, r1, r0
	movs	r0, #8
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L027f4
	mov	r1, sl
	ldr	r0, [r1, #76]
	lsls	r0, r0, #1
	ldr	r3, [sp, #4]
	adds	r0, r3, r0
	lsls	r0, r0, #6
	ldr	r2, [r2, #64]
	adds	r2, r2, r0
	ldr	r3, [r1, #40]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
	b.n	.L0280e
	movs	r0, r0
.L027f0:
	.4byte	gbass_module
.L027f4:
	mov	r1, sl
	ldr	r0, [r1, #76]
	lsls	r0, r0, #1
	ldr	r3, [sp, #4]
	adds	r0, r3, r0
	lsls	r0, r0, #6
	ldr	r2, [r2, #64]
	adds	r2, r2, r0
	ldr	r3, [r1, #36]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
.L0280e:
	ldr	r4, .L0282c
	ldr	r0, [r4, #56]
	ldr	r1, [sp, #0]
	adds	r0, r0, r1
	movs	r1, #1
	ldrb	r0, [r0, #0]
	ands	r1, r0
	cmp	r1, #0
	beq.n	.L02830
	movs	r2, #128
	add	r9, r2
	movs	r3, #4
	add	r8, r3
	b.n	.L02838
	movs	r0, r0
.L0282c:
	.4byte	gbass_module
.L02830:
	movs	r4, #64
	add	r9, r4
	movs	r0, #2
	add	r8, r0
.L02838:
	ldr	r1, [sp, #0]
	adds	r1, #1
	str	r1, [sp, #0]
	subs	r7, #1
	movs	r2, #1
	negs	r2, r2
	cmp	r7, r2
	beq.n	.L0284a
	b.n	.L02710
.L0284a:
	ldr	r3, [sp, #12]
	str	r3, [sp, #4]
	ldr	r0, [sp, #8]
	movs	r4, #1
	negs	r4, r4
	cmp	r0, r4
	beq.n	.L0285a
	b.n	.L025ac
.L0285a:
	b.n	.L02b4c
.L0285c:
	ldr	r0, [r2, #0]
	str	r0, [sp, #4]
	ldr	r0, [r2, #76]
	subs	r0, #1
	b.n	.L02b42
.L02866:
	movs	r1, #0
	mov	r8, r1
	movs	r2, #0
	str	r2, [sp, #0]
	ldr	r3, .L028d4
	ldr	r7, [r3, #80]
	subs	r7, #1
	subs	r0, #1
	str	r0, [sp, #8]
	ldr	r4, [sp, #4]
	lsls	r4, r4, #6
	str	r4, [sp, #16]
	ldr	r0, [sp, #4]
	adds	r0, #1
	str	r0, [sp, #12]
	subs	r1, #1
	cmp	r7, r1
	bne.n	.L0288c
	b.n	.L029b0
.L0288c:
	ldr	r2, .L028d8
	mov	sl, r2
	movs	r3, #0
	str	r3, [sp, #20]
	mov	r9, r3
.L02896:
	mov	r4, r8
	asrs	r1, r4, #1
	mov	r0, sl
	ldr	r2, [r0, #44]
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	adds	r0, r0, r2
	ldrh	r0, [r0, #24]
	adds	r4, r1, #0
	cmp	r0, #0
	beq.n	.L028dc
	mov	r1, sl
	ldr	r0, [r1, #40]
	mov	r2, r9
	adds	r6, r0, r2
	ldr	r3, .L028d4
	ldr	r1, [r3, #68]
	movs	r0, #128
	lsls	r0, r0, #7
	ands	r1, r0
	mov	r0, r8
	lsls	r5, r0, #5
	cmp	r1, #0
	bne.n	.L028e8
	mov	r1, sl
	ldr	r0, [r1, #36]
	add	r0, r9
	bl	GBASS_SilentMix
	b.n	.L028e8
.L028d4:
	.4byte	gbass_ram
.L028d8:
	.4byte	gbass_module
.L028dc:
	mov	r2, sl
	ldr	r0, [r2, #36]
	mov	r3, r9
	adds	r6, r0, r3
	mov	r0, r8
	lsls	r5, r0, #5
.L028e8:
	ldr	r2, .L0291c
	ldr	r0, [r2, #44]
	lsls	r1, r4, #1
	adds	r1, r1, r4
	lsls	r1, r1, #5
	adds	r1, r1, r0
	ldrh	r0, [r1, #56]
	cmp	r0, #0
	beq.n	.L02924
	ldr	r0, [r2, #40]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #32
	ldr	r1, .L02920
	ldr	r0, [r1, #68]
	movs	r1, #128
	lsls	r1, r1, #7
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L0292c
	ldr	r0, [r2, #36]
	adds	r0, r0, r5
	adds	r0, #32
	bl	GBASS_SilentMix
	b.n	.L0292c
.L0291c:
	.4byte	gbass_module
.L02920:
	.4byte	gbass_ram
.L02924:
	ldr	r0, [r2, #36]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #32
.L0292c:
	ldr	r2, .L02954
	ldr	r1, [r2, #56]
	ldr	r3, [sp, #0]
	adds	r1, r1, r3
	movs	r0, #8
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L0295c
	ldr	r2, [r2, #52]
	ldr	r0, [sp, #20]
	adds	r2, r2, r0
	ldr	r1, .L02958
	ldr	r3, [r1, #40]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
	b.n	.L0296e
	movs	r0, r0
.L02954:
	.4byte	gbass_module
.L02958:
	.4byte	gbass_ram
.L0295c:
	ldr	r2, [r2, #52]
	ldr	r3, [sp, #20]
	adds	r2, r2, r3
	ldr	r0, .L0298c
	ldr	r3, [r0, #36]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
.L0296e:
	mov	r2, sl
	ldr	r1, [r2, #56]
	ldr	r3, [sp, #0]
	adds	r1, r1, r3
	movs	r0, #1
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L02990
	movs	r4, #128
	add	r9, r4
	movs	r0, #4
	add	r8, r0
	b.n	.L02998
	movs	r0, r0
.L0298c:
	.4byte	gbass_ram
.L02990:
	movs	r1, #64
	add	r9, r1
	movs	r2, #2
	add	r8, r2
.L02998:
	ldr	r3, [sp, #20]
	adds	r3, #64
	str	r3, [sp, #20]
	ldr	r4, [sp, #0]
	adds	r4, #1
	str	r4, [sp, #0]
	subs	r7, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r7, r0
	beq.n	.L029b0
	b.n	.L02896
.L029b0:
	ldr	r1, .L02a3c
	ldr	r0, [r1, #52]
	ldr	r1, [r1, #64]
	ldr	r2, [sp, #16]
	adds	r1, r1, r2
	ldr	r3, .L02a40
	ldr	r2, [r3, #80]
	ldr	r3, [r3, #24]
	bl	_call_via_r3
	movs	r4, #0
	mov	r8, r4
	movs	r0, #0
	str	r0, [sp, #0]
	ldr	r1, .L02a40
	ldr	r7, [r1, #80]
	subs	r7, #1
	movs	r2, #1
	negs	r2, r2
	cmp	r7, r2
	bne.n	.L029dc
	b.n	.L02b1c
.L029dc:
	ldr	r3, .L02a3c
	mov	sl, r3
	mov	r9, r0
	str	r4, [sp, #24]
.L029e4:
	mov	r0, sl
	ldr	r1, [r0, #56]
	ldr	r2, [sp, #0]
	adds	r1, r1, r2
	movs	r0, #1
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L029f8
	b.n	.L02afc
.L029f8:
	mov	r3, r8
	asrs	r1, r3, #1
	mov	r4, sl
	ldr	r2, [r4, #44]
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #5
	adds	r0, r0, r2
	adds	r0, #96
	ldrh	r0, [r0, #24]
	adds	r4, r1, #0
	cmp	r0, #0
	beq.n	.L02a44
	mov	r1, sl
	ldr	r0, [r1, #40]
	add	r0, r9
	adds	r6, r0, #0
	adds	r6, #64
	ldr	r2, .L02a40
	ldr	r1, [r2, #68]
	movs	r0, #128
	lsls	r0, r0, #7
	ands	r1, r0
	lsls	r5, r3, #5
	cmp	r1, #0
	bne.n	.L02a52
	mov	r3, sl
	ldr	r0, [r3, #36]
	add	r0, r9
	adds	r0, #64
	bl	GBASS_SilentMix
	b.n	.L02a52
	movs	r0, r0
.L02a3c:
	.4byte	gbass_module
.L02a40:
	.4byte	gbass_ram
.L02a44:
	mov	r1, sl
	ldr	r0, [r1, #36]
	add	r0, r9
	adds	r6, r0, #0
	adds	r6, #64
	mov	r2, r8
	lsls	r5, r2, #5
.L02a52:
	ldr	r2, .L02a88
	ldr	r0, [r2, #44]
	lsls	r1, r4, #1
	adds	r1, r1, r4
	lsls	r1, r1, #5
	adds	r1, r1, r0
	adds	r1, #96
	ldrh	r0, [r1, #56]
	cmp	r0, #0
	beq.n	.L02a90
	ldr	r0, [r2, #40]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #96
	ldr	r3, .L02a8c
	ldr	r0, [r3, #68]
	movs	r1, #128
	lsls	r1, r1, #7
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L02a98
	ldr	r0, [r2, #36]
	adds	r0, r0, r5
	adds	r0, #96
	bl	GBASS_SilentMix
	b.n	.L02a98
.L02a88:
	.4byte	gbass_module
.L02a8c:
	.4byte	gbass_ram
.L02a90:
	ldr	r0, [r2, #36]
	add	r0, r9
	adds	r4, r0, #0
	adds	r4, #96
.L02a98:
	ldr	r2, .L02ac0
	ldr	r1, [r2, #56]
	ldr	r0, [sp, #0]
	adds	r1, r1, r0
	movs	r0, #8
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L02ac8
	ldr	r2, [r2, #52]
	ldr	r1, [sp, #24]
	adds	r2, r2, r1
	ldr	r0, .L02ac4
	ldr	r3, [r0, #40]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
	b.n	.L02ada
	movs	r0, r0
.L02ac0:
	.4byte	gbass_module
.L02ac4:
	.4byte	gbass_ram
.L02ac8:
	ldr	r2, [r2, #52]
	ldr	r1, [sp, #24]
	adds	r2, r2, r1
	ldr	r0, .L02af8
	ldr	r3, [r0, #36]
	adds	r0, r6, #0
	adds	r1, r4, #0
	bl	_call_via_r3
.L02ada:
	mov	r2, sl
	ldr	r1, [r2, #56]
	ldr	r3, [sp, #0]
	adds	r1, r1, r3
	movs	r0, #1
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L02afc
	movs	r4, #128
	add	r9, r4
	movs	r0, #4
	add	r8, r0
	b.n	.L02b04
	movs	r0, r0
.L02af8:
	.4byte	gbass_ram
.L02afc:
	movs	r1, #64
	add	r9, r1
	movs	r2, #2
	add	r8, r2
.L02b04:
	ldr	r3, [sp, #24]
	adds	r3, #64
	str	r3, [sp, #24]
	ldr	r4, [sp, #0]
	adds	r4, #1
	str	r4, [sp, #0]
	subs	r7, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r7, r0
	beq.n	.L02b1c
	b.n	.L029e4
.L02b1c:
	ldr	r1, .L02b88
	ldr	r0, [r1, #52]
	ldr	r3, .L02b8c
	ldr	r2, [r3, #76]
	lsls	r2, r2, #1
	ldr	r4, [sp, #4]
	adds	r2, r4, r2
	lsls	r2, r2, #6
	ldr	r1, [r1, #64]
	adds	r1, r1, r2
	ldr	r3, .L02b88
	ldr	r2, [r3, #48]
	ldr	r4, .L02b8c
	ldr	r3, [r4, #24]
	bl	_call_via_r3
	ldr	r0, [sp, #12]
	str	r0, [sp, #4]
	ldr	r0, [sp, #8]
.L02b42:
	movs	r1, #1
	negs	r1, r1
	cmp	r0, r1
	beq.n	.L02b4c
	b.n	.L02866
.L02b4c:
	ldr	r5, .L02b8c
	ldr	r0, [r5, #68]
	movs	r1, #4
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L02b72
	ldr	r1, .L02b88
	ldr	r4, [r5, #0]
	lsls	r0, r4, #6
	ldr	r1, [r1, #64]
	adds	r0, r1, r0
	ldr	r2, [r5, #76]
	lsls	r3, r2, #1
	adds	r3, r3, r4
	lsls	r3, r3, #6
	adds	r1, r1, r3
	ldr	r3, [r5, #28]
	bl	_call_via_r3
.L02b72:
	movs	r0, #0
	str	r0, [r5, #12]
.L02b76:
	add	sp, #28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L02b88:
	.4byte	gbass_module
.L02b8c:
	.4byte	gbass_ram

@
@ void GBASS_DMACriticalProcess(void)  [API] -- first thing in the V-Blank IRQ.
@ Restarts DMA1/DMA2 on the half of the double buffer that was just mixed
@ (DigiReSeekStereo) and flips ram+0. Timing errors here are audible.
	.global	GBASS_DMACriticalProcess
	.thumb_func
	.type	GBASS_DMACriticalProcess, %function
GBASS_DMACriticalProcess:
	push	{r4, lr}
	ldr	r1, .L02bbc
	ldr	r4, .L02bc0
	ldr	r3, [r4, #0]
	lsls	r0, r3, #6
	ldr	r1, [r1, #64]
	adds	r0, r1, r0
	ldr	r2, [r4, #76]
	lsls	r2, r2, #1
	adds	r3, r3, r2
	lsls	r3, r3, #6
	adds	r1, r1, r3
	bl	DigiReSeekStereo
	ldr	r0, [r4, #0]
	ldr	r1, [r4, #76]
	eors	r0, r1
	str	r0, [r4, #0]
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L02bbc:
	.4byte	gbass_module
.L02bc0:
	.4byte	gbass_ram

@
@ GBASS_MixerReset(Mixer *m, int mastervol): silence ptr, vol 255, pos 0, end 1.0,
@ speed/loop 0, cvol 256, mvol = mastervol, rate 1.0.
	.global	GBASS_MixerReset
	.thumb_func
	.type	GBASS_MixerReset, %function
GBASS_MixerReset:
	ldr	r2, .L02bec
	ldr	r2, [r2, #68]
	str	r2, [r0, #0]
	movs	r2, #255
	str	r2, [r0, #4]
	movs	r3, #0
	str	r3, [r0, #8]
	movs	r2, #128
	lsls	r2, r2, #11
	str	r2, [r0, #12]
	str	r3, [r0, #16]
	str	r3, [r0, #20]
	movs	r2, #128
	lsls	r2, r2, #1
	strh	r2, [r0, #24]
	strh	r1, [r0, #26]
	movs	r1, #128
	lsls	r1, r1, #9
	str	r1, [r0, #28]
	bx	lr
.L02bec:
	.4byte	gbass_module

@
@ GBASS_ScriptPtrReset(Level *l): wait 0, loop 0, release 0, pc = silence byte.
	.global	GBASS_ScriptPtrReset
	.thumb_func
	.type	GBASS_ScriptPtrReset, %function
GBASS_ScriptPtrReset:
	movs	r2, #0
	movs	r1, #0
	strh	r1, [r0, #0]
	strb	r2, [r0, #2]
	strb	r2, [r0, #3]
	ldr	r1, .L02c04
	ldr	r1, [r1, #68]
	str	r1, [r0, #4]
	bx	lr
	movs	r0, r0
.L02c04:
	.4byte	gbass_module

@
@ GBASS_PlayerStatusReset(Status *s): clears the 8-byte status record.
	.global	GBASS_PlayerStatusReset
	.thumb_func
	.type	GBASS_PlayerStatusReset, %function
GBASS_PlayerStatusReset:
	movs	r1, #0
	strb	r1, [r0, #0]
	strb	r1, [r0, #1]
	strb	r1, [r0, #2]
	strb	r1, [r0, #3]
	strh	r1, [r0, #4]
	strh	r1, [r0, #6]
	bx	lr

@
@ int GBASS_PlayerChannelMusicStop(PairBlock *p, int ch): resets music status and
@ levels 0-2 (keeping the sfx tag byte); returns the sfx-active word (ch+24).
	.global	GBASS_PlayerChannelMusicStop
	.thumb_func
	.type	GBASS_PlayerChannelMusicStop, %function
GBASS_PlayerChannelMusicStop:
	push	{r4, r5, r6, lr}
	adds	r4, r0, #0
	lsrs	r2, r1, #31
	adds	r2, r1, r2
	asrs	r2, r2, #1
	lsls	r0, r2, #1
	adds	r0, r0, r2
	lsls	r0, r0, #5
	adds	r4, r4, r0
	movs	r0, #1
	ands	r1, r0
	lsls	r0, r1, #3
	adds	r0, #64
	adds	r0, r4, r0
	lsls	r1, r1, #5
	adds	r4, r4, r1
	bl	GBASS_PlayerStatusReset
	adds	r0, r4, #0
	bl	GBASS_ScriptPtrReset
	ldrb	r5, [r4, #11]
	ldrb	r6, [r4, #10]
	adds	r0, r4, #0
	adds	r0, #8
	bl	GBASS_ScriptPtrReset
	strb	r5, [r4, #11]
	strb	r6, [r4, #10]
	adds	r0, r4, #0
	adds	r0, #16
	bl	GBASS_ScriptPtrReset
	ldrh	r0, [r4, #24]
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1
	movs	r0, r0

@
@ GBASS_PlayerChannelOrderSet(PairBlock *p, int ch, u8 *track, int hwchan):
@ starts a song track on a channel (level 0 wait = 1, pc = track).
	.global	GBASS_PlayerChannelOrderSet
	.thumb_func
	.type	GBASS_PlayerChannelOrderSet, %function
GBASS_PlayerChannelOrderSet:
	push	{r4, r5, r6, lr}
	adds	r4, r0, #0
	adds	r6, r2, #0
	adds	r5, r3, #0
	lsrs	r2, r1, #31
	adds	r2, r1, r2
	asrs	r2, r2, #1
	lsls	r0, r2, #1
	adds	r0, r0, r2
	lsls	r0, r0, #5
	adds	r4, r4, r0
	movs	r0, #1
	ands	r1, r0
	lsls	r0, r1, #3
	adds	r0, #64
	adds	r0, r4, r0
	lsls	r1, r1, #5
	adds	r4, r4, r1
	bl	GBASS_PlayerStatusReset
	adds	r0, r4, #0
	bl	GBASS_ScriptPtrReset
	movs	r0, #1
	cmp	r5, #3
	bgt.n	.L02c9a
	movs	r0, #2
.L02c9a:
	strh	r0, [r4, #0]
	str	r6, [r4, #4]
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0

@
@ GBASS_PlayerReset(PairBlock *p): resets all 8 levels and 4 status records.
	.global	GBASS_PlayerReset
	.thumb_func
	.type	GBASS_PlayerReset, %function
GBASS_PlayerReset:
	push	{r4, r5, r6, r7, lr}
	adds	r6, r0, #0
	movs	r5, #7
	movs	r7, #1
	negs	r7, r7
	adds	r4, r6, #0
.L02cb0:
	adds	r0, r4, #0
	bl	GBASS_ScriptPtrReset
	adds	r4, #8
	subs	r5, #1
	cmp	r5, r7
	bne.n	.L02cb0
	movs	r5, #3
	movs	r7, #1
	negs	r7, r7
	adds	r4, r6, #0
	adds	r4, #64
.L02cc8:
	adds	r0, r4, #0
	bl	GBASS_PlayerStatusReset
	adds	r4, #8
	subs	r5, #1
	cmp	r5, r7
	bne.n	.L02cc8
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0

@
@ GBASS_Reset_GBCChannel(int ch 0-3): silences one PSG channel (envelope 0 +
@ trigger; wave channel: NR30 off, keeps the bank bit).
	.global	GBASS_Reset_GBCChannel
	.thumb_func
	.type	GBASS_Reset_GBCChannel, %function
GBASS_Reset_GBCChannel:
	adds	r2, r0, #0
	cmp	r2, #1
	beq.n	.L02d14
	cmp	r2, #1
	bgt.n	.L02cec
	cmp	r2, #0
	beq.n	.L02cf6
	b.n	.L02d58
.L02cec:
	cmp	r2, #2
	beq.n	.L02d1c
	cmp	r2, #3
	beq.n	.L02d44
	b.n	.L02d58
.L02cf6:
	ldr	r0, .L02d10
	strb	r2, [r0, #0]
	adds	r0, #2
	movs	r1, #128
	strb	r1, [r0, #0]
	adds	r0, #1
	strb	r2, [r0, #0]
	adds	r0, #1
	strb	r2, [r0, #0]
	adds	r0, #1
	strb	r1, [r0, #0]
	b.n	.L02d58
	movs	r0, r0
.L02d10:
	.4byte	0x04000060
.L02d14:
	ldr	r0, .L02d18
	b.n	.L02d46
.L02d18:
	.4byte	0x04000068
.L02d1c:
	ldr	r0, .L02d38
	ldr	r0, [r0, #68]
	movs	r1, #1
	ands	r0, r1
	lsls	r0, r0, #6
	movs	r2, #128
	orrs	r0, r2
	ldr	r1, .L02d3c
	strb	r0, [r1, #0]
	adds	r1, #3
	movs	r0, #0
	strb	r0, [r1, #0]
	ldr	r0, .L02d40
	b.n	.L02d56
.L02d38:
	.4byte	gbass_ram
.L02d3c:
	.4byte	0x04000070
.L02d40:
	.4byte	0x04000075
.L02d44:
	ldr	r0, .L02d5c
.L02d46:
	movs	r2, #128
	strb	r2, [r0, #0]
	adds	r0, #1
	movs	r1, #0
	strb	r1, [r0, #0]
	adds	r0, #3
	strb	r1, [r0, #0]
	adds	r0, #1
.L02d56:
	strb	r2, [r0, #0]
.L02d58:
	bx	lr
	movs	r0, r0
.L02d5c:
	.4byte	0x04000078

@
@ GBASS_Reset_GBC(void): writes NR51 from ram, resets GB channel words/volumes,
@ silences the four PSG channels and sets NR50 = 0x77.
	.global	GBASS_Reset_GBC
	.thumb_func
	.type	GBASS_Reset_GBC, %function
GBASS_Reset_GBC:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	ldr	r0, .L02ddc
	ldr	r2, .L02de0
	adds	r1, r2, #0
	adds	r1, #108
	ldrb	r1, [r1, #0]
	strb	r1, [r0, #0]
	movs	r3, #0
	mov	ip, r2
	movs	r7, #128
	lsls	r7, r7, #2
	movs	r6, #255
	movs	r0, #64
	add	r0, ip
	mov	r8, r0
	mov	r5, ip
	adds	r5, #44
	adds	r2, #52
	mov	r4, ip
	adds	r4, #56
.L02d8c:
	strh	r7, [r5, #0]
	strh	r7, [r4, #0]
	ldrb	r0, [r2, #0]
	orrs	r0, r6
	strb	r0, [r2, #0]
	mov	r0, r8
	adds	r1, r3, r0
	ldrb	r0, [r1, #0]
	orrs	r0, r6
	strb	r0, [r1, #0]
	adds	r5, #2
	adds	r2, #1
	adds	r4, #2
	adds	r3, #1
	cmp	r3, #3
	ble.n	.L02d8c
	movs	r0, #0
	mov	r1, ip
	strh	r0, [r1, #50]
	strh	r0, [r1, #62]
	bl	GBASS_Reset_GBCChannel
	movs	r0, #1
	bl	GBASS_Reset_GBCChannel
	movs	r0, #2
	bl	GBASS_Reset_GBCChannel
	movs	r0, #3
	bl	GBASS_Reset_GBCChannel
	ldr	r1, .L02de4
	movs	r0, #119
	strb	r0, [r1, #0]
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L02ddc:
	.4byte	0x04000081
.L02de0:
	.4byte	gbass_ram
.L02de4:
	.4byte	0x04000080

@
@ void GBASS_Reset(void)  [API]: song and sfx master volumes 256,
@ transpose 0, speed and tempo 1.0, every mixer and channel reset, PSG silenced.
	.global	GBASS_Reset
	.thumb_func
	.type	GBASS_Reset, %function
GBASS_Reset:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #4
	ldr	r2, .L02ecc
	ldr	r0, [r2, #8]
	adds	r0, #1
	str	r0, [r2, #8]
	adds	r1, r2, #0
	adds	r1, #109
	movs	r0, #255
	strb	r0, [r1, #0]
	adds	r0, #1
	str	r0, [r2, #16]
	str	r0, [r2, #20]
	movs	r1, #0
	str	r1, [r2, #92]
	movs	r0, #128
	lsls	r0, r0, #9
	str	r0, [r2, #96]
	str	r0, [r2, #104]
	str	r1, [r2, #100]
	movs	r0, #0
	str	r0, [sp, #0]
	ldr	r1, .L02ed0
	ldr	r7, [r1, #32]
	subs	r7, #1
	subs	r0, #1
	cmp	r7, r0
	beq.n	.L02e88
	mov	sl, r1
	mov	r8, r2
	movs	r1, #0
	mov	r9, r1
.L02e30:
	ldr	r0, [sp, #0]
	lsls	r6, r0, #6
	mov	r1, sl
	ldr	r5, [r1, #36]
	adds	r5, r5, r6
	mov	r0, r8
	ldr	r1, [r0, #16]
	adds	r0, r5, #0
	bl	GBASS_MixerReset
	mov	r1, sl
	ldr	r4, [r1, #40]
	adds	r4, r4, r6
	mov	r0, r8
	ldr	r1, [r0, #20]
	adds	r0, r4, #0
	bl	GBASS_MixerReset
	adds	r5, #32
	mov	r0, r8
	ldr	r1, [r0, #16]
	adds	r0, r5, #0
	bl	GBASS_MixerReset
	adds	r4, #32
	mov	r0, r8
	ldr	r1, [r0, #20]
	adds	r0, r4, #0
	bl	GBASS_MixerReset
	mov	r1, sl
	ldr	r0, [r1, #44]
	add	r0, r9
	bl	GBASS_PlayerReset
	movs	r0, #96
	add	r9, r0
	ldr	r1, [sp, #0]
	adds	r1, #1
	str	r1, [sp, #0]
	subs	r7, #1
	subs	r0, #97
	cmp	r7, r0
	bne.n	.L02e30
.L02e88:
	movs	r7, #1
	ldr	r0, .L02ed0
	ldr	r4, [r0, #60]
	movs	r5, #1
	negs	r5, r5
.L02e92:
	adds	r0, r4, #0
	bl	GBASS_PlayerReset
	adds	r4, #96
	subs	r7, #1
	cmp	r7, r5
	bne.n	.L02e92
	bl	GBASS_Reset_GBC
	ldr	r1, .L02ecc
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L02eba
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L02eba
	bl	GBASS_Process
.L02eba:
	add	sp, #4
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L02ecc:
	.4byte	gbass_ram
.L02ed0:
	.4byte	gbass_module

@
@ void GBASS_HeadPhoneMode(int enable)  [API]: sets/clears ram+44 bit 2 (CrossMix).
@ Note: Init sets the bit, so the cross-mix is ON by default.
	.global	GBASS_HeadPhoneMode
	.thumb_func
	.type	GBASS_HeadPhoneMode, %function
GBASS_HeadPhoneMode:
	cmp	r0, #0
	beq.n	.L02ee8
	ldr	r0, .L02ee4
	ldr	r1, [r0, #68]
	movs	r2, #4
	orrs	r1, r2
	b.n	.L02ef2
	movs	r0, r0
.L02ee4:
	.4byte	gbass_ram
.L02ee8:
	ldr	r0, .L02ef8
	ldr	r1, [r0, #68]
	movs	r2, #5
	negs	r2, r2
	ands	r1, r2
.L02ef2:
	str	r1, [r0, #68]
	bx	lr
	movs	r0, r0
.L02ef8:
	.4byte	gbass_ram

@
@ void GBASS_Init(void)  [API]: sets up ram from gbass_module, clears DMA and mix
@ buffers, copies the ARM routines to IWRAM, SOUNDCNT_X = 0x80, GBASS_Reset.
@ Must be followed by GBASS_Resume before the V-Blank calls start.
	.global	GBASS_Init
	.thumb_func
	.type	GBASS_Init, %function
GBASS_Init:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	ldr	r0, .L02ffc
	mov	ip, r0
	movs	r0, #1
	mov	r1, ip
	str	r0, [r1, #8]
	movs	r2, #0
	str	r2, [r1, #12]
	str	r2, [r1, #72]
	ldr	r5, .L03000
	ldr	r0, [r5, #0]
	str	r0, [r1, #76]
	ldr	r4, [r5, #48]
	str	r4, [r1, #80]
	ldr	r0, [r5, #32]
	str	r0, [r1, #84]
	mov	r0, ip
	adds	r0, #88
	strb	r2, [r0, #0]
	str	r2, [r1, #0]
	str	r2, [r1, #4]
	adds	r0, #1
	strb	r2, [r0, #0]
	mov	r3, ip
	adds	r3, #108
	movs	r0, #255
	ldrb	r1, [r3, #0]
	orrs	r1, r0
	strb	r1, [r3, #0]
	mov	r1, ip
	adds	r1, #109
	ldrb	r3, [r1, #0]
	orrs	r0, r3
	strb	r0, [r1, #0]
	mov	r0, ip
	adds	r0, #110
	strb	r2, [r0, #0]
	adds	r0, #1
	strb	r2, [r0, #0]
	mov	r1, ip
	movs	r2, #12
	cmp	r4, #1
	bne.n	.L02f62
	ldr	r0, [r5, #56]
	ldrb	r0, [r0, #0]
	ands	r4, r0
	cmp	r4, #0
	beq.n	.L02f62
	movs	r2, #14
.L02f62:
	str	r2, [r1, #68]
	bl	DigiInit
	ldr	r0, .L03000
	ldr	r3, [r0, #64]
	ldr	r0, [r0, #0]
	lsls	r2, r0, #8
	subs	r2, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r2, r0
	beq.n	.L02f86
	movs	r1, #0
.L02f7c:
	strb	r1, [r3, #0]
	adds	r3, #1
	subs	r2, #1
	cmp	r2, r0
	bne.n	.L02f7c
.L02f86:
	ldr	r1, .L03000
	ldr	r3, [r1, #52]
	ldr	r0, [r1, #48]
	lsls	r2, r0, #6
	subs	r2, #1
	movs	r0, #1
	negs	r0, r0
	ldr	r7, .L02ffc
	mov	r8, r1
	ldr	r1, .L03004
	mov	ip, r1
	ldr	r4, .L03008
	cmp	r2, r0
	beq.n	.L02fae
	movs	r1, #0
.L02fa4:
	strb	r1, [r3, #0]
	adds	r3, #1
	subs	r2, #1
	cmp	r2, r0
	bne.n	.L02fa4
.L02fae:
	mov	r3, r8
	ldr	r5, [r3, #72]
	ldr	r1, .L02ffc
	ldr	r0, .L03004
	ldr	r0, [r0, #16]
	movs	r2, #2
	adds	r1, #40
.L02fbc:
	str	r0, [r1, #0]
	subs	r1, #4
	subs	r2, #1
	cmp	r2, #0
	bge.n	.L02fbc
	str	r4, [r7, #24]
	str	r4, [r7, #28]
	movs	r2, #0
.L02fcc:
	mov	r0, r8
	ldr	r1, [r0, #76]
	asrs	r1, r2
	movs	r0, #1
	ands	r1, r0
	adds	r3, r2, #1
	cmp	r1, #0
	beq.n	.L03056
	lsls	r0, r2, #3
	add	r0, ip
	ldr	r4, [r0, #0]
	lsls	r0, r2, #1
	adds	r0, #1
	lsls	r0, r0, #2
	add	r0, ip
	ldr	r6, [r0, #0]
	cmp	r2, #4
	bhi.n	.L03052
	lsls	r0, r2, #2
	ldr	r1, .L0300c
	adds	r0, r0, r1
	ldr	r0, [r0, #0]
	mov	pc, r0
	movs	r0, r0
.L02ffc:
	.4byte	gbass_ram
.L03000:
	.4byte	gbass_module
.L03004:
	.4byte	GBASS_Mix_Table
.L03008:
	.4byte	GBASS_Mix_BLOCKEND
.L0300c:
	.4byte	.L03010
.L03010:
	.4byte	.L03024
	.4byte	.L03028
	.4byte	.L0302c
	.4byte	.L03044
	.4byte	.L03048
.L03024:
	str	r5, [r7, #24]
	b.n	.L0304a
.L03028:
	str	r5, [r7, #28]
	b.n	.L0304a
.L0302c:
	adds	r3, r2, #1
	ldr	r0, .L03040
	movs	r2, #2
	adds	r0, #40
.L03034:
	str	r5, [r0, #0]
	subs	r0, #4
	subs	r2, #1
	cmp	r2, #0
	bge.n	.L03034
	b.n	.L03052
.L03040:
	.4byte	gbass_ram
.L03044:
	str	r5, [r7, #36]
	b.n	.L0304a
.L03048:
	str	r5, [r7, #40]
.L0304a:
	adds	r3, r2, #1
	b.n	.L03052
.L0304e:
	ldmia	r4!, {r0}
	stmia	r5!, {r0}
.L03052:
	cmp	r4, r6
	bne.n	.L0304e
.L03056:
	adds	r2, r3, #0
	cmp	r2, #4
	ble.n	.L02fcc
	ldr	r1, .L03088
	movs	r0, #128
	strb	r0, [r1, #0]
	bl	GBASS_Reset
	ldr	r1, .L0308c
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L0307c
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L0307c
	bl	GBASS_Process
.L0307c:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L03088:
	.4byte	0x04000084
.L0308c:
	.4byte	gbass_ram

@
@ void GBASS_AudioMode(int buffers)  [API]: number of mix buffers to process
@ (1..gbass_module+30); recomputes the active pair count; single-buffer mode
@ (flag b1) when one stereo buffer remains.
	.global	GBASS_AudioMode
	.thumb_func
	.type	GBASS_AudioMode, %function
GBASS_AudioMode:
	push	{r4, r5, r6, r7, lr}
	adds	r3, r0, #0
	ldr	r1, .L030cc
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	adds	r5, r1, #0
	cmp	r3, #0
	bgt.n	.L030a4
	movs	r3, #1
.L030a4:
	ldr	r1, .L030d0
	ldr	r0, [r1, #48]
	cmp	r3, r0
	ble.n	.L030ae
	adds	r3, r0, #0
.L030ae:
	movs	r2, #0
	movs	r4, #0
	cmp	r4, r3
	bge.n	.L030dc
	ldr	r6, [r1, #56]
	movs	r7, #1
.L030ba:
	adds	r1, r6, r2
	adds	r0, r7, #0
	ldrb	r1, [r1, #0]
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L030d4
	adds	r4, #2
	b.n	.L030d6
	movs	r0, r0
.L030cc:
	.4byte	gbass_ram
.L030d0:
	.4byte	gbass_module
.L030d4:
	adds	r4, #1
.L030d6:
	adds	r2, #1
	cmp	r2, r3
	blt.n	.L030ba
.L030dc:
	cmp	r3, #1
	bne.n	.L030ea
	cmp	r4, #2
	bne.n	.L030ea
	ldr	r0, [r5, #68]
	orrs	r0, r4
	b.n	.L030f2
.L030ea:
	ldr	r0, [r5, #68]
	movs	r1, #3
	negs	r1, r1
	ands	r0, r1
.L030f2:
	str	r0, [r5, #68]
	str	r4, [r5, #84]
	str	r3, [r5, #80]
	ldr	r0, [r5, #8]
	subs	r0, #1
	str	r0, [r5, #8]
	cmp	r0, #0
	bne.n	.L0310c
	ldr	r0, [r5, #12]
	cmp	r0, #0
	beq.n	.L0310c
	bl	GBASS_Process
.L0310c:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0

@ u32 GBASS_GetAudioRate(void)  [API]: ram+4C.
	.global	GBASS_GetAudioRate
	.thumb_func
	.type	GBASS_GetAudioRate, %function
GBASS_GetAudioRate:
	ldr	r0, .L0311c
	ldr	r0, [r0, #76]
	bx	lr
	movs	r0, r0
.L0311c:
	.4byte	gbass_ram

@ u32 GBASS_GetDefaultAudioRate(void)  [API]: gbass_module+0.
	.global	GBASS_GetDefaultAudioRate
	.thumb_func
	.type	GBASS_GetDefaultAudioRate, %function
GBASS_GetDefaultAudioRate:
	ldr	r0, .L03128
	ldr	r0, [r0, #0]
	bx	lr
	movs	r0, r0
.L03128:
	.4byte	gbass_module

@
@ s8 *GBASS_OutputBufferLeft(void)  [API]: the left DMA half being filled this frame.
	.global	GBASS_OutputBufferLeft
	.thumb_func
	.type	GBASS_OutputBufferLeft, %function
GBASS_OutputBufferLeft:
	ldr	r2, .L0313c
	ldr	r0, .L03140
	ldr	r1, [r0, #0]
	lsls	r1, r1, #6
	ldr	r0, [r2, #64]
	adds	r0, r0, r1
	bx	lr
	movs	r0, r0
.L0313c:
	.4byte	gbass_module
.L03140:
	.4byte	gbass_ram

@
@ s8 *GBASS_OutputBufferRight(void)  [API]: the right DMA half being filled.
	.global	GBASS_OutputBufferRight
	.thumb_func
	.type	GBASS_OutputBufferRight, %function
GBASS_OutputBufferRight:
	ldr	r2, .L03158
	ldr	r1, .L0315c
	ldr	r0, [r1, #76]
	lsls	r0, r0, #1
	ldr	r1, [r1, #0]
	adds	r1, r1, r0
	lsls	r1, r1, #6
	ldr	r0, [r2, #64]
	adds	r0, r0, r1
	bx	lr
.L03158:
	.4byte	gbass_module
.L0315c:
	.4byte	gbass_ram

@ int GBASS_GetAudioMode(void)  [API]: ram+50.
	.global	GBASS_GetAudioMode
	.thumb_func
	.type	GBASS_GetAudioMode, %function
GBASS_GetAudioMode:
	ldr	r0, .L03168
	ldr	r0, [r0, #80]
	bx	lr
	movs	r0, r0
.L03168:
	.4byte	gbass_ram

@
@ void GBASS_Song_Transpose(int halftone16)  [API]: clamps to -768..768 (+-4 octaves).
	.global	GBASS_Song_Transpose
	.thumb_func
	.type	GBASS_Song_Transpose, %function
GBASS_Song_Transpose:
	adds	r1, r0, #0
	movs	r0, #192
	lsls	r0, r0, #2
	cmp	r1, r0
	ble.n	.L03178
	adds	r1, r0, #0
.L03178:
	ldr	r0, .L03188
	cmp	r1, r0
	bge.n	.L03180
	adds	r1, r0, #0
.L03180:
	ldr	r0, .L0318c
	str	r1, [r0, #92]
	bx	lr
	movs	r0, r0
.L03188:
	.4byte	0xfffffd00
.L0318c:
	.4byte	gbass_ram

@ void GBASS_Song_Speed(u32 speed16_16)  [API]: ram+60.
	.global	GBASS_Song_Speed
	.thumb_func
	.type	GBASS_Song_Speed, %function
GBASS_Song_Speed:
	ldr	r1, .L03198
	str	r0, [r1, #96]
	bx	lr
	movs	r0, r0
.L03198:
	.4byte	gbass_ram

@
@ void GBASS_Song_MasterVolume(int vol)  [API]: clamps 31..256, writes every music
@ mixer's mvol and NR50 (vol>>5, both sides; 7 for 256).
	.global	GBASS_Song_MasterVolume
	.thumb_func
	.type	GBASS_Song_MasterVolume, %function
GBASS_Song_MasterVolume:
	push	{r4, r5, r6, r7, lr}
	adds	r2, r0, #0
	ldr	r1, .L03214
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	adds	r4, r1, #0
	cmp	r2, #255
	ble.n	.L031b2
	movs	r2, #128
	lsls	r2, r2, #1
.L031b2:
	cmp	r2, #30
	bgt.n	.L031b8
	movs	r2, #31
.L031b8:
	str	r2, [r4, #16]
	movs	r3, #0
	ldr	r1, .L03218
	ldr	r0, [r1, #32]
	lsls	r2, r0, #1
	subs	r2, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r2, r0
	beq.n	.L031e4
	adds	r7, r1, #0
	adds	r6, r4, #0
	adds	r5, r0, #0
.L031d2:
	ldr	r0, [r7, #36]
	lsls	r1, r3, #5
	adds	r1, r1, r0
	ldr	r0, [r6, #16]
	strh	r0, [r1, #26]
	adds	r3, #1
	subs	r2, #1
	cmp	r2, r5
	bne.n	.L031d2
.L031e4:
	ldr	r1, [r4, #16]
	movs	r0, #128
	lsls	r0, r0, #1
	movs	r3, #7
	cmp	r1, r0
	beq.n	.L031f2
	asrs	r3, r1, #5
.L031f2:
	lsls	r0, r3, #4
	orrs	r3, r0
	ldr	r0, .L0321c
	strb	r3, [r0, #0]
	ldr	r0, [r4, #8]
	subs	r0, #1
	str	r0, [r4, #8]
	cmp	r0, #0
	bne.n	.L0320e
	ldr	r0, [r4, #12]
	cmp	r0, #0
	beq.n	.L0320e
	bl	GBASS_Process
.L0320e:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.L03214:
	.4byte	gbass_ram
.L03218:
	.4byte	gbass_module
.L0321c:
	.4byte	0x04000080

@
@ void GBASS_SFX_MasterVolume(int vol)  [API]: clamps 0..256, writes the sfx mixers.
	.global	GBASS_SFX_MasterVolume
	.thumb_func
	.type	GBASS_SFX_MasterVolume, %function
GBASS_SFX_MasterVolume:
	push	{r4, r5, r6, r7, lr}
	adds	r2, r0, #0
	ldr	r1, .L03284
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	adds	r4, r1, #0
	cmp	r2, #255
	ble.n	.L03236
	movs	r2, #128
	lsls	r2, r2, #1
.L03236:
	cmp	r2, #0
	bge.n	.L0323c
	movs	r2, #0
.L0323c:
	str	r2, [r4, #20]
	movs	r3, #0
	ldr	r1, .L03288
	ldr	r0, [r1, #32]
	lsls	r2, r0, #1
	subs	r2, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r2, r0
	beq.n	.L03268
	adds	r7, r1, #0
	adds	r6, r4, #0
	adds	r5, r0, #0
.L03256:
	ldr	r0, [r7, #40]
	lsls	r1, r3, #5
	adds	r1, r1, r0
	ldr	r0, [r6, #20]
	strh	r0, [r1, #26]
	adds	r3, #1
	subs	r2, #1
	cmp	r2, r5
	bne.n	.L03256
.L03268:
	ldr	r0, [r4, #8]
	subs	r0, #1
	str	r0, [r4, #8]
	cmp	r0, #0
	bne.n	.L0327c
	ldr	r0, [r4, #12]
	cmp	r0, #0
	beq.n	.L0327c
	bl	GBASS_Process
.L0327c:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L03284:
	.4byte	gbass_ram
.L03288:
	.4byte	gbass_module

@
@ void GBASS_Song_Stop(void)  [API]: stops all music levels, resets the music
@ mixers, silences GB channels that no sound effect is using.
	.global	GBASS_Song_Stop
	.thumb_func
	.type	GBASS_Song_Stop, %function
GBASS_Song_Stop:
	push	{r4, r5, r6, lr}
	ldr	r1, .L0330c
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	movs	r5, #0
	ldr	r1, .L03310
	ldr	r0, [r1, #32]
	lsls	r4, r0, #1
	subs	r4, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r4, r0
	beq.n	.L032cc
	adds	r6, r1, #0
.L032aa:
	ldr	r0, [r6, #44]
	adds	r1, r5, #0
	bl	GBASS_PlayerChannelMusicStop
	lsls	r1, r5, #5
	ldr	r0, [r6, #36]
	adds	r0, r0, r1
	movs	r1, #128
	lsls	r1, r1, #1
	bl	GBASS_MixerReset
	adds	r5, #1
	subs	r4, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r4, r0
	bne.n	.L032aa
.L032cc:
	movs	r5, #0
	movs	r4, #3
	ldr	r6, .L03310
.L032d2:
	ldr	r0, [r6, #60]
	adds	r1, r5, #0
	bl	GBASS_PlayerChannelMusicStop
	cmp	r0, #0
	bne.n	.L032e4
	adds	r0, r5, #0
	bl	GBASS_Reset_GBCChannel
.L032e4:
	adds	r5, #1
	subs	r4, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r4, r0
	bne.n	.L032d2
	ldr	r1, .L0330c
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L03306
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L03306
	bl	GBASS_Process
.L03306:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
.L0330c:
	.4byte	gbass_ram
.L03310:
	.4byte	gbass_module

@ const char *GBASS_Song_Title(int song)  [API]: name or NULL.
	.global	GBASS_Song_Title
	.thumb_func
	.type	GBASS_Song_Title, %function
GBASS_Song_Title:
	adds	r2, r0, #0
	cmp	r2, #0
	blt.n	.L03322
	ldr	r1, .L03328
	ldr	r0, [r1, #4]
	cmp	r2, r0
	blt.n	.L0332c
.L03322:
	movs	r0, #0
	b.n	.L03338
	movs	r0, r0
.L03328:
	.4byte	gbass_module
.L0332c:
	ldr	r0, [r1, #8]
	lsls	r1, r2, #1
	adds	r1, r1, r2
	lsls	r1, r1, #2
	adds	r1, r1, r0
	ldr	r0, [r1, #8]
.L03338:
	bx	lr
	movs	r0, r0

@ int GBASS_Song_Time(void)  [API]: ticks since Song_Play (ram+48).
	.global	GBASS_Song_Time
	.thumb_func
	.type	GBASS_Song_Time, %function
GBASS_Song_Time:
	ldr	r0, .L03344
	ldr	r0, [r0, #72]
	bx	lr
	movs	r0, r0
.L03344:
	.4byte	gbass_ram

@
@ void GBASS_Song_Play(int song)  [API]: time 0, tempo 1.0; for each track entry
@ {u8 *track, s16 hwchan, s16 volume}: hwchan 0-3 -> GB channel, 4+ -> digital
@ channel hwchan-4 (mixer reset with the entry's volume as master volume).
	.global	GBASS_Song_Play
	.thumb_func
	.type	GBASS_Song_Play, %function
GBASS_Song_Play:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r9
	mov	r6, r8
	push	{r6, r7}
	adds	r1, r0, #0
	ldr	r2, .L033c0
	ldr	r0, [r2, #8]
	adds	r0, #1
	str	r0, [r2, #8]
	ldr	r3, .L033c4
	ldr	r0, [r3, #4]
	cmp	r1, r0
	bge.n	.L033f6
	lsls	r0, r1, #1
	adds	r0, r0, r1
	lsls	r0, r0, #2
	ldr	r1, [r3, #8]
	adds	r1, r1, r0
	mov	r8, r1
	movs	r0, #0
	str	r0, [r2, #72]
	movs	r0, #128
	lsls	r0, r0, #9
	str	r0, [r2, #104]
	movs	r0, #0
	mov	r9, r0
	ldr	r6, [r1, #0]
	subs	r6, #1
	subs	r0, #1
	cmp	r6, r0
	beq.n	.L033f6
	adds	r7, r3, #0
.L03388:
	mov	r1, r9
	lsls	r0, r1, #3
	mov	r2, r8
	ldr	r1, [r2, #4]
	adds	r4, r1, r0
	movs	r1, #4
	ldrsh	r0, [r4, r1]
	cmp	r0, #3
	bgt.n	.L033c8
	ldr	r5, [r7, #60]
	adds	r1, r0, #0
	adds	r0, r5, #0
	bl	GBASS_PlayerChannelMusicStop
	cmp	r0, #0
	bne.n	.L033b0
	movs	r1, #4
	ldrsh	r0, [r4, r1]
	bl	GBASS_Reset_GBCChannel
.L033b0:
	movs	r2, #4
	ldrsh	r3, [r4, r2]
	ldr	r2, [r4, #0]
	adds	r0, r5, #0
	adds	r1, r3, #0
	bl	GBASS_PlayerChannelOrderSet
	b.n	.L033ea
.L033c0:
	.4byte	gbass_ram
.L033c4:
	.4byte	gbass_module
.L033c8:
	ldr	r0, [r7, #44]
	movs	r1, #4
	ldrsh	r3, [r4, r1]
	subs	r1, r3, #4
	ldr	r2, [r4, #0]
	bl	GBASS_PlayerChannelOrderSet
	movs	r2, #4
	ldrsh	r1, [r4, r2]
	lsls	r1, r1, #5
	ldr	r0, [r7, #36]
	adds	r0, r0, r1
	subs	r0, #128
	movs	r2, #6
	ldrsh	r1, [r4, r2]
	bl	GBASS_MixerReset
.L033ea:
	movs	r0, #1
	add	r9, r0
	subs	r6, #1
	subs	r0, #2
	cmp	r6, r0
	bne.n	.L03388
.L033f6:
	ldr	r1, .L03418
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L0340c
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L0340c
	bl	GBASS_Process
.L0340c:
	pop	{r3, r4}
	mov	r8, r3
	mov	r9, r4
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.L03418:
	.4byte	gbass_ram

@ void GBASS_Suspend(void)  [API]: DigiStop(3) and silence the PSG.
	.global	GBASS_Suspend
	.thumb_func
	.type	GBASS_Suspend, %function
GBASS_Suspend:
	push	{lr}
	movs	r0, #3
	bl	DigiStop
	movs	r0, #0
	bl	GBASS_Reset_GBCChannel
	movs	r0, #1
	bl	GBASS_Reset_GBCChannel
	movs	r0, #2
	bl	GBASS_Reset_GBCChannel
	movs	r0, #3
	bl	GBASS_Reset_GBCChannel
	pop	{r0}
	bx	r0

@
@ void GBASS_AudioRateDivide(int divider)  [API]: rate = default/divider (1..8);
@ rescales every mixer's wave rate, sets the rate shift, clears the DMA buffers
@ and restarts output (Suspend ... Resume).
	.global	GBASS_AudioRateDivide
	.thumb_func
	.type	GBASS_AudioRateDivide, %function
GBASS_AudioRateDivide:
	push	{r4, r5, r6, r7, lr}
	ldr	r7, .L034c4
	adds	r1, r0, #0
	cmp	r1, #1
	bge.n	.L0344c
	movs	r1, #1
.L0344c:
	ldr	r5, [r7, #0]
	adds	r0, r5, #0
	bl	__divsi3
	adds	r4, r0, #0
	ldr	r6, .L034c8
	ldr	r0, [r6, #8]
	adds	r0, #1
	str	r0, [r6, #8]
	cmp	r4, #0
	bgt.n	.L03464
	movs	r4, #1
.L03464:
	cmp	r4, #8
	ble.n	.L0346a
	movs	r4, #8
.L0346a:
	cmp	r4, r5
	bgt.n	.L03558
	ldr	r0, [r6, #76]
	cmp	r0, r4
	beq.n	.L03558
	bl	GBASS_Suspend
	bl	GBASS_ReverbClear
	ldr	r1, [r6, #76]
	cmp	r1, r4
	bge.n	.L034cc
	movs	r5, #0
	adds	r0, r1, #0
	mov	ip, r6
.L03488:
	adds	r5, #1
	lsls	r0, r0, #1
	cmp	r0, r4
	blt.n	.L03488
	ldr	r0, [r7, #32]
	lsls	r2, r0, #1
	subs	r2, #1
	movs	r3, #1
	negs	r3, r3
	cmp	r2, r3
	beq.n	.L0350e
	ldr	r1, [r7, #36]
	ldr	r0, [r7, #40]
	adds	r6, r3, #0
	adds	r3, r0, #0
	adds	r3, #28
	adds	r1, #28
.L034aa:
	ldr	r0, [r1, #0]
	asrs	r0, r5
	str	r0, [r1, #0]
	ldr	r0, [r3, #0]
	asrs	r0, r5
	str	r0, [r3, #0]
	adds	r3, #32
	adds	r1, #32
	subs	r2, #1
	cmp	r2, r6
	bne.n	.L034aa
	b.n	.L0350e
	movs	r0, r0
.L034c4:
	.4byte	gbass_module
.L034c8:
	.4byte	gbass_ram
.L034cc:
	movs	r5, #0
	adds	r0, r4, #0
	mov	ip, r6
	cmp	r4, r1
	bge.n	.L034de
.L034d6:
	adds	r5, #1
	lsls	r0, r0, #1
	cmp	r0, r1
	blt.n	.L034d6
.L034de:
	ldr	r0, [r7, #32]
	lsls	r2, r0, #1
	subs	r2, #1
	movs	r3, #1
	negs	r3, r3
	cmp	r2, r3
	beq.n	.L0350e
	ldr	r1, [r7, #36]
	ldr	r0, [r7, #40]
	adds	r6, r3, #0
	adds	r3, r0, #0
	adds	r3, #28
	adds	r1, #28
.L034f8:
	ldr	r0, [r1, #0]
	lsls	r0, r5
	str	r0, [r1, #0]
	ldr	r0, [r3, #0]
	lsls	r0, r5
	str	r0, [r3, #0]
	adds	r3, #32
	adds	r1, #32
	subs	r2, #1
	cmp	r2, r6
	bne.n	.L034f8
.L0350e:
	mov	r1, ip
	adds	r1, #88
	movs	r0, #0
	strb	r0, [r1, #0]
	ldr	r0, [r7, #0]
	cmp	r0, r4
	ble.n	.L0352e
	adds	r2, r0, #0
.L0351e:
	ldrb	r0, [r1, #0]
	adds	r0, #1
	strb	r0, [r1, #0]
	adds	r0, r2, #0
	ldrb	r3, [r1, #0]
	asrs	r0, r3
	cmp	r0, r4
	bgt.n	.L0351e
.L0352e:
	mov	r0, ip
	str	r4, [r0, #76]
	movs	r0, #0
	mov	r1, ip
	str	r0, [r1, #0]
	ldr	r1, [r7, #64]
	ldr	r0, [r7, #0]
	lsls	r2, r0, #8
	subs	r2, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r2, r0
	beq.n	.L03554
	movs	r3, #0
.L0354a:
	strb	r3, [r1, #0]
	adds	r1, #1
	subs	r2, #1
	cmp	r2, r0
	bne.n	.L0354a
.L03554:
	bl	GBASS_Resume
.L03558:
	ldr	r1, .L03574
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L0356e
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L0356e
	bl	GBASS_Process
.L0356e:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.L03574:
	.4byte	gbass_ram

@
@ void GBASS_Resume(void)  [API]: DigiRate(timer0, gbass_mixingrates[rate]),
@ DMA1 -> FIFO A (left), DMA2 -> FIFO B (right), DigiPan A=left B=right, start.
	.global	GBASS_Resume
	.thumb_func
	.type	GBASS_Resume, %function
GBASS_Resume:
	push	{r4, r5, lr}
	ldr	r1, .L035e4
	ldr	r5, .L035e8
	ldr	r0, [r5, #76]
	lsls	r0, r0, #2
	adds	r0, r0, r1
	ldr	r2, [r0, #0]
	movs	r0, #3
	movs	r1, #0
	bl	DigiRate
	movs	r0, #1
	movs	r1, #0
	movs	r2, #0
	bl	DigiDMA
	movs	r0, #2
	movs	r1, #1
	movs	r2, #0
	bl	DigiDMA
	ldr	r0, .L035ec
	ldr	r1, [r5, #0]
	lsls	r1, r1, #6
	ldr	r4, [r0, #64]
	adds	r1, r4, r1
	movs	r0, #1
	bl	DigiSeek
	ldr	r1, [r5, #76]
	lsls	r1, r1, #1
	ldr	r0, [r5, #0]
	adds	r0, r0, r1
	lsls	r0, r0, #6
	adds	r4, r4, r0
	movs	r0, #2
	adds	r1, r4, #0
	bl	DigiSeek
	movs	r0, #1
	movs	r1, #2
	bl	DigiPan
	movs	r0, #2
	movs	r1, #1
	bl	DigiPan
	movs	r0, #3
	bl	DigiStart
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L035e4:
	.4byte	gbass_mixingrates
.L035e8:
	.4byte	gbass_ram
.L035ec:
	.4byte	gbass_module

@
@ u32 GBASS_Song_SaveStateBufferSize(void)  [API]: pairs*128 + 152 bytes.
	.global	GBASS_Song_SaveStateBufferSize
	.thumb_func
	.type	GBASS_Song_SaveStateBufferSize, %function
GBASS_Song_SaveStateBufferSize:
	ldr	r0, .L035fc
	ldr	r0, [r0, #84]
	lsls	r0, r0, #7
	adds	r0, #152
	bx	lr
	movs	r0, r0
.L035fc:
	.4byte	gbass_ram

@
@ void GBASS_Song_SaveState(u32 *buf)  [API]: copies music mixers, music status,
@ music levels of all channels, GB music state, time, tempo and NR10/flags.
	.global	GBASS_Song_SaveState
	.thumb_func
	.type	GBASS_Song_SaveState, %function
GBASS_Song_SaveState:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	adds	r5, r0, #0
	ldr	r1, .L0377c
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	ldr	r0, .L03780
	ldr	r2, [r0, #36]
	ldr	r0, [r1, #84]
	lsls	r3, r0, #4
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	mov	ip, r1
	movs	r1, #44
	add	r1, ip
	mov	sl, r1
	cmp	r3, r0
	beq.n	.L0363a
	adds	r1, r0, #0
.L03630:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L03630
.L0363a:
	mov	r2, ip
	ldr	r3, [r2, #84]
	subs	r3, #1
	movs	r2, #1
	negs	r2, r2
	cmp	r3, r2
	beq.n	.L0366e
	ldr	r0, .L03780
	ldr	r1, [r0, #44]
	adds	r6, r2, #0
	lsls	r0, r3, #1
	adds	r0, r0, r3
	lsls	r0, r0, #5
	adds	r4, r0, r1
.L03656:
	adds	r2, r4, #0
	adds	r2, #64
	movs	r1, #3
.L0365c:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r1, #1
	cmp	r1, r6
	bne.n	.L0365c
	subs	r4, #96
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L03656
.L0366e:
	mov	r0, ip
	ldr	r3, [r0, #84]
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	beq.n	.L036be
	ldr	r1, .L03780
	mov	r8, r1
	ldr	r2, [r1, #44]
	mov	r9, r2
	adds	r7, r0, #0
	lsls	r0, r3, #1
	adds	r0, r0, r3
	lsls	r4, r0, #5
.L0368c:
	mov	r0, r9
	adds	r2, r0, r4
	movs	r1, #5
.L03692:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r1, #1
	cmp	r1, r7
	bne.n	.L03692
	mov	r1, r8
	ldr	r0, [r1, #44]
	adds	r0, r0, r4
	adds	r2, r0, #0
	adds	r2, #32
	movs	r1, #5
	movs	r6, #1
	negs	r6, r6
.L036ac:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r1, #1
	cmp	r1, r6
	bne.n	.L036ac
	subs	r4, #96
	subs	r3, #1
	cmp	r3, r7
	bne.n	.L0368c
.L036be:
	movs	r3, #1
	ldr	r0, .L03780
	ldr	r0, [r0, #60]
	movs	r6, #1
	negs	r6, r6
	adds	r4, r0, #0
	adds	r4, #96
.L036cc:
	adds	r2, r4, #0
	adds	r2, #64
	movs	r1, #3
.L036d2:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r1, #1
	cmp	r1, r6
	bne.n	.L036d2
	subs	r4, #96
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L036cc
	movs	r3, #1
	ldr	r2, .L03780
	mov	r8, r2
	ldr	r0, [r2, #60]
	mov	r9, r0
	movs	r7, #1
	negs	r7, r7
	movs	r6, #96
.L036f4:
	mov	r1, r9
	adds	r2, r1, r6
	movs	r1, #5
.L036fa:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r1, #1
	cmp	r1, r7
	bne.n	.L036fa
	mov	r2, r8
	ldr	r0, [r2, #60]
	adds	r0, r0, r6
	adds	r2, r0, #0
	adds	r2, #32
	movs	r1, #5
	movs	r4, #1
	negs	r4, r4
.L03714:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r1, #1
	cmp	r1, r4
	bne.n	.L03714
	subs	r6, #96
	subs	r3, #1
	cmp	r3, r7
	bne.n	.L036f4
	mov	r2, sl
	movs	r3, #2
	movs	r1, #1
	negs	r1, r1
.L0372e:
	ldmia	r2!, {r0}
	stmia	r5!, {r0}
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L0372e
	mov	r1, ip
	ldr	r0, [r1, #72]
	stmia	r5!, {r0}
	ldr	r0, [r1, #104]
	stmia	r5!, {r0}
	mov	r2, ip
	adds	r2, #110
	ldr	r0, [r1, #68]
	lsls	r0, r0, #5
	movs	r1, #252
	lsls	r1, r1, #6
	ands	r0, r1
	ldrb	r2, [r2, #0]
	orrs	r0, r2
	str	r0, [r5, #0]
	mov	r2, ip
	ldr	r0, [r2, #8]
	subs	r0, #1
	str	r0, [r2, #8]
	cmp	r0, #0
	bne.n	.L0376c
	ldr	r0, [r2, #12]
	cmp	r0, #0
	beq.n	.L0376c
	bl	GBASS_Process
.L0376c:
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L0377c:
	.4byte	gbass_ram
.L03780:
	.4byte	gbass_module

@
@ void GBASS_Song_LoadState(u32 *buf)  [API]: inverse of SaveState (keeps the sfx
@ tags), silences the PSG, flags all GB channels for restore, reapplies volume.
	.global	GBASS_Song_LoadState
	.thumb_func
	.type	GBASS_Song_LoadState, %function
GBASS_Song_LoadState:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #4
	adds	r4, r0, #0
	ldr	r0, .L03988
	mov	ip, r0
	ldr	r0, [r0, #8]
	adds	r0, #1
	mov	r1, ip
	str	r0, [r1, #8]
	ldr	r0, .L0398c
	ldr	r2, [r0, #36]
	ldr	r0, [r1, #84]
	lsls	r3, r0, #4
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	mov	r8, ip
	cmp	r3, r0
	beq.n	.L037be
	adds	r1, r0, #0
.L037b4:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L037b4
.L037be:
	mov	r5, r8
	ldr	r3, [r5, #84]
	subs	r3, #1
	movs	r2, #1
	negs	r2, r2
	cmp	r3, r2
	beq.n	.L037f8
	ldr	r0, .L0398c
	ldr	r1, [r0, #44]
	adds	r5, r2, #0
	lsls	r0, r3, #1
	adds	r0, r0, r3
	lsls	r0, r0, #5
	adds	r0, r0, r1
	mov	ip, r0
.L037dc:
	mov	r2, ip
	adds	r2, #64
	movs	r1, #3
.L037e2:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L037e2
	movs	r0, #96
	negs	r0, r0
	add	ip, r0
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L037dc
.L037f8:
	mov	r1, r8
	ldr	r3, [r1, #84]
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	beq.n	.L03898
	ldr	r5, .L0398c
	mov	sl, r5
	ldr	r1, [r5, #44]
	str	r1, [sp, #0]
	adds	r7, r0, #0
	lsls	r0, r3, #1
	adds	r0, r0, r3
	lsls	r6, r0, #5
	ldr	r5, .L03990
	mov	ip, r5
	ldr	r0, .L03994
	mov	r9, r0
.L0381e:
	ldr	r1, [sp, #0]
	adds	r2, r1, r6
	movs	r1, #1
.L03824:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r7
	bne.n	.L03824
	ldmia	r4!, {r0}
	mov	r5, ip
	ands	r0, r5
	ldr	r1, [r2, #0]
	mov	r5, r9
	ands	r1, r5
	orrs	r0, r1
	stmia	r2!, {r0}
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	movs	r1, #1
	movs	r5, #1
	negs	r5, r5
.L03848:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L03848
	mov	r1, sl
	ldr	r0, [r1, #44]
	adds	r0, r0, r6
	adds	r2, r0, #0
	adds	r2, #32
	movs	r1, #1
	movs	r5, #1
	negs	r5, r5
.L03862:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L03862
	ldmia	r4!, {r0}
	mov	r5, ip
	ands	r0, r5
	ldr	r1, [r2, #0]
	mov	r5, r9
	ands	r1, r5
	orrs	r0, r1
	stmia	r2!, {r0}
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	movs	r1, #1
	movs	r5, #1
	negs	r5, r5
.L03886:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L03886
	subs	r6, #96
	subs	r3, #1
	cmp	r3, r7
	bne.n	.L0381e
.L03898:
	movs	r3, #1
	ldr	r0, .L0398c
	ldr	r0, [r0, #60]
	movs	r5, #1
	negs	r5, r5
	adds	r0, #96
	mov	ip, r0
.L038a6:
	mov	r2, ip
	adds	r2, #64
	movs	r1, #3
.L038ac:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L038ac
	movs	r0, #96
	negs	r0, r0
	add	ip, r0
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L038a6
	movs	r3, #1
	ldr	r1, .L0398c
	mov	ip, r1
	ldr	r5, [r1, #60]
	mov	r9, r5
	movs	r7, #1
	negs	r7, r7
	movs	r6, #96
.L038d2:
	mov	r0, r9
	adds	r2, r0, r6
	movs	r1, #5
.L038d8:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r7
	bne.n	.L038d8
	mov	r1, ip
	ldr	r0, [r1, #60]
	adds	r0, r0, r6
	adds	r2, r0, #0
	adds	r2, #32
	movs	r1, #5
	movs	r5, #1
	negs	r5, r5
.L038f2:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r1, #1
	cmp	r1, r5
	bne.n	.L038f2
	subs	r6, #96
	subs	r3, #1
	cmp	r3, r7
	bne.n	.L038d2
	ldr	r2, .L03998
	movs	r3, #2
	movs	r1, #1
	negs	r1, r1
.L0390c:
	ldmia	r4!, {r0}
	stmia	r2!, {r0}
	subs	r3, #1
	cmp	r3, r1
	bne.n	.L0390c
	ldmia	r4!, {r0}
	mov	r5, r8
	str	r0, [r5, #72]
	ldmia	r4!, {r0}
	str	r0, [r5, #104]
	ldr	r0, [r4, #0]
	mov	r1, r8
	adds	r1, #110
	strb	r0, [r1, #0]
	ldr	r2, [r5, #68]
	ldr	r0, .L0399c
	ands	r2, r0
	ldr	r0, [r4, #0]
	lsrs	r0, r0, #5
	movs	r1, #252
	lsls	r1, r1, #1
	ands	r0, r1
	orrs	r2, r0
	str	r2, [r5, #68]
	movs	r0, #0
	bl	GBASS_Reset_GBCChannel
	movs	r0, #1
	bl	GBASS_Reset_GBCChannel
	movs	r0, #2
	bl	GBASS_Reset_GBCChannel
	movs	r0, #3
	bl	GBASS_Reset_GBCChannel
	mov	r1, r8
	adds	r1, #111
	movs	r0, #15
	strb	r0, [r1, #0]
	ldr	r0, [r5, #16]
	bl	GBASS_Song_MasterVolume
	ldr	r0, [r5, #8]
	subs	r0, #1
	str	r0, [r5, #8]
	cmp	r0, #0
	bne.n	.L03976
	ldr	r0, [r5, #12]
	cmp	r0, #0
	beq.n	.L03976
	bl	GBASS_Process
.L03976:
	add	sp, #4
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L03988:
	.4byte	gbass_ram
.L0398c:
	.4byte	gbass_module
.L03990:
	.4byte	0x0000ffff
.L03994:
	.4byte	0xffff0000
.L03998:
	.4byte	gbass_ram+0x2c
.L0399c:
	.4byte	0xfffffe07

@ void GBASS_SFX_StopAll(void)  [API]
	.global	GBASS_SFX_StopAll
	.thumb_func
	.type	GBASS_SFX_StopAll, %function
GBASS_SFX_StopAll:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	ldr	r1, .L03a5c
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	movs	r2, #0
	mov	ip, r1
	ldr	r4, .L03a60
	ldr	r6, [r4, #60]
	movs	r5, #1
	movs	r0, #0
	mov	r8, r0
	mov	r3, ip
	adds	r3, #111
	ldr	r7, .L03a64
.L039c2:
	asrs	r0, r2, #1
	lsls	r1, r0, #1
	adds	r1, r1, r0
	lsls	r1, r1, #5
	adds	r1, r6, r1
	adds	r0, r2, #0
	ands	r0, r5
	lsls	r0, r0, #5
	adds	r1, r1, r0
	ldrh	r0, [r1, #24]
	cmp	r0, #0
	beq.n	.L039fe
	ldr	r0, [r4, #16]
	ldr	r0, [r0, #0]
	str	r0, [r1, #28]
	movs	r0, #0
	strh	r0, [r1, #24]
	mov	r0, r8
	strb	r0, [r1, #27]
	adds	r0, r5, #0
	lsls	r0, r2
	ldrb	r1, [r3, #0]
	orrs	r0, r1
	strb	r0, [r3, #0]
	cmp	r2, #0
	bne.n	.L039fe
	mov	r0, ip
	adds	r0, #110
	ldrb	r0, [r0, #0]
	strb	r0, [r7, #0]
.L039fe:
	adds	r2, #1
	cmp	r2, #3
	ble.n	.L039c2
	ldr	r0, [r4, #32]
	cmp	r0, #0
	ble.n	.L03a2e
	ldr	r6, [r4, #44]
	movs	r5, #0
	movs	r3, #0
	adds	r2, r0, #0
.L03a12:
	adds	r1, r6, r3
	ldr	r0, [r4, #16]
	ldr	r0, [r0, #0]
	str	r0, [r1, #28]
	strh	r5, [r1, #24]
	adds	r1, #32
	ldr	r0, [r4, #16]
	ldr	r0, [r0, #0]
	str	r0, [r1, #28]
	strh	r5, [r1, #24]
	adds	r3, #96
	subs	r2, #1
	cmp	r2, #0
	bne.n	.L03a12
.L03a2e:
	mov	r0, ip
	adds	r0, #109
	ldrb	r1, [r0, #0]
	subs	r0, #1
	strb	r1, [r0, #0]
	ldr	r0, .L03a68
	strb	r1, [r0, #0]
	mov	r1, ip
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L03a52
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L03a52
	bl	GBASS_Process
.L03a52:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.L03a5c:
	.4byte	gbass_ram
.L03a60:
	.4byte	gbass_module
.L03a64:
	.4byte	0x04000060
.L03a68:
	.4byte	0x04000081

@
@ int GBASS_SFX_IsActive(u32 handle)  [API]: nonzero while a channel with the
@ handle's tag (bits 8-15) still runs its level 3 script.
	.global	GBASS_SFX_IsActive
	.thumb_func
	.type	GBASS_SFX_IsActive, %function
GBASS_SFX_IsActive:
	push	{r4, r5, lr}
	lsrs	r3, r0, #8
	movs	r0, #255
	ands	r3, r0
	movs	r2, #1
	ldr	r0, .L03ab8
	ldr	r0, [r0, #60]
	adds	r1, r0, #0
	adds	r1, #24
	movs	r4, #1
	negs	r4, r4
.L03a82:
	ldrb	r5, [r0, #11]
	cmp	r5, r3
	beq.n	.L03ab4
	ldrb	r5, [r1, #19]
	cmp	r5, r3
	beq.n	.L03ac6
	adds	r1, #96
	adds	r0, #96
	subs	r2, #1
	cmp	r2, r4
	bne.n	.L03a82
	ldr	r0, .L03abc
	ldr	r2, [r0, #84]
	subs	r2, #1
	movs	r4, #1
	negs	r4, r4
	cmp	r2, r4
	beq.n	.L03ad4
	ldr	r0, .L03ab8
	ldr	r0, [r0, #44]
	adds	r1, r0, #0
	adds	r1, #24
.L03aae:
	ldrb	r5, [r0, #11]
	cmp	r5, r3
	bne.n	.L03ac0
.L03ab4:
	ldrh	r0, [r1, #0]
	b.n	.L03ad6
.L03ab8:
	.4byte	gbass_module
.L03abc:
	.4byte	gbass_ram
.L03ac0:
	ldrb	r5, [r1, #19]
	cmp	r5, r3
	bne.n	.L03aca
.L03ac6:
	ldrh	r0, [r1, #32]
	b.n	.L03ad6
.L03aca:
	adds	r1, #96
	adds	r0, #96
	subs	r2, #1
	cmp	r2, r4
	bne.n	.L03aae
.L03ad4:
	movs	r0, #0
.L03ad6:
	pop	{r4, r5}
	pop	{r1}
	bx	r1

@ void GBASS_SFX_Stop(u32 handle)  [API]
	.global	GBASS_SFX_Stop
	.thumb_func
	.type	GBASS_SFX_Stop, %function
GBASS_SFX_Stop:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #4
	lsrs	r5, r0, #8
	movs	r0, #255
	ands	r5, r0
	ldr	r1, .L03bd4
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	movs	r0, #0
	str	r0, [sp, #0]
	movs	r3, #1
	ldr	r1, .L03bd8
	mov	sl, r1
	mov	r9, sl
	mov	ip, r0
	ldr	r4, .L03bd4
	adds	r4, #111
	mov	r8, r3
	movs	r6, #1
	movs	r2, #0
.L03b0e:
	mov	r7, r9
	ldr	r0, [r7, #60]
	ldr	r7, [sp, #0]
	lsls	r1, r7, #1
	adds	r0, r2, r0
	ldrb	r7, [r0, #11]
	cmp	r7, r5
	bne.n	.L03b2c
	mov	r7, ip
	strh	r7, [r0, #24]
	mov	r0, r8
	lsls	r0, r1
	ldrb	r1, [r4, #0]
	orrs	r0, r1
	strb	r0, [r4, #0]
.L03b2c:
	mov	r7, r9
	ldr	r0, [r7, #60]
	adds	r1, r2, r0
	adds	r0, r1, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r5
	bne.n	.L03b4a
	mov	r0, ip
	strh	r0, [r1, #56]
	mov	r0, r8
	lsls	r0, r6
	ldrb	r1, [r4, #0]
	orrs	r0, r1
	strb	r0, [r4, #0]
.L03b4a:
	adds	r6, #2
	adds	r2, #96
	ldr	r7, [sp, #0]
	adds	r7, #1
	str	r7, [sp, #0]
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	bne.n	.L03b0e
	ldr	r1, .L03bd4
	ldr	r3, [r1, #84]
	subs	r3, #1
	cmp	r3, r0
	beq.n	.L03bac
	ldr	r4, .L03bd8
	movs	r6, #0
	movs	r2, #0
.L03b6e:
	ldr	r0, [r4, #44]
	adds	r0, r2, r0
	ldrb	r7, [r0, #11]
	cmp	r7, r5
	bne.n	.L03b86
	strh	r6, [r0, #24]
	mov	r1, sl
	ldr	r0, [r1, #44]
	adds	r0, r2, r0
	ldr	r1, [r1, #16]
	ldr	r1, [r1, #0]
	str	r1, [r0, #28]
.L03b86:
	ldr	r0, [r4, #44]
	adds	r1, r2, r0
	adds	r0, r1, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r5
	bne.n	.L03ba0
	strh	r6, [r1, #56]
	ldr	r0, [r4, #44]
	adds	r0, r2, r0
	ldr	r1, [r4, #16]
	ldr	r1, [r1, #0]
	str	r1, [r0, #60]
.L03ba0:
	adds	r2, #96
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	bne.n	.L03b6e
.L03bac:
	ldr	r7, .L03bd4
	ldr	r0, [r7, #8]
	subs	r0, #1
	str	r0, [r7, #8]
	cmp	r0, #0
	bne.n	.L03bc2
	ldr	r0, [r7, #12]
	cmp	r0, #0
	beq.n	.L03bc2
	bl	GBASS_Process
.L03bc2:
	add	sp, #4
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L03bd4:
	.4byte	gbass_ram
.L03bd8:
	.4byte	gbass_module

@ int GBASS_SFX_Volume(u32 handle, int vol)  [API]
	.global	GBASS_SFX_Volume
	.thumb_func
	.type	GBASS_SFX_Volume, %function
GBASS_SFX_Volume:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r9
	mov	r6, r8
	push	{r6, r7}
	adds	r6, r1, #0
	lsrs	r5, r0, #8
	movs	r0, #255
	ands	r5, r0
	movs	r0, #0
	mov	r8, r0
	ldr	r1, .L03c7c
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	ldr	r3, [r1, #84]
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	mov	r9, r1
	cmp	r3, r0
	beq.n	.L03c58
	ldr	r7, .L03c80
	mov	ip, r7
	movs	r4, #0
	movs	r1, #0
.L03c0e:
	mov	r2, ip
	ldr	r0, [r2, #44]
	adds	r0, r4, r0
	ldrb	r2, [r0, #11]
	cmp	r2, r5
	bne.n	.L03c2c
	ldrh	r0, [r0, #24]
	cmp	r0, #0
	beq.n	.L03c2c
	mov	r2, ip
	ldr	r0, [r2, #40]
	adds	r0, r1, r0
	strh	r6, [r0, #24]
	movs	r0, #1
	mov	r8, r0
.L03c2c:
	ldr	r0, [r7, #44]
	adds	r2, r4, r0
	adds	r0, r2, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r5
	bne.n	.L03c4a
	ldrh	r0, [r2, #56]
	cmp	r0, #0
	beq.n	.L03c4a
	ldr	r0, [r7, #40]
	adds	r0, r1, r0
	strh	r6, [r0, #56]
	movs	r2, #1
	mov	r8, r2
.L03c4a:
	adds	r4, #96
	adds	r1, #64
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	bne.n	.L03c0e
.L03c58:
	mov	r1, r9
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L03c6e
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L03c6e
	bl	GBASS_Process
.L03c6e:
	mov	r0, r8
	pop	{r3, r4}
	mov	r8, r3
	mov	r9, r4
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.L03c7c:
	.4byte	gbass_ram
.L03c80:
	.4byte	gbass_module

@ int GBASS_SFX_VolumeStereo(u32 handle, int volL, int volR)  [API]
	.global	GBASS_SFX_VolumeStereo
	.thumb_func
	.type	GBASS_SFX_VolumeStereo, %function
GBASS_SFX_VolumeStereo:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #4
	mov	r9, r1
	mov	r8, r2
	lsrs	r0, r0, #8
	mov	ip, r0
	movs	r0, #255
	mov	r1, ip
	ands	r1, r0
	mov	ip, r1
	movs	r3, #0
	str	r3, [sp, #0]
	ldr	r2, .L03cf4
	ldr	r6, [r2, #56]
	movs	r0, #1
	ldrb	r1, [r6, #0]
	ands	r0, r1
	adds	r4, r0, #1
	ldr	r1, .L03cf8
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	ldr	r5, [r1, #84]
	subs	r5, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r5, r0
	beq.n	.L03d64
	adds	r3, r2, #0
	mov	sl, r3
	movs	r2, #0
	movs	r7, #0
.L03ccc:
	mov	r1, sl
	ldr	r0, [r1, #44]
	adds	r0, r7, r0
	ldrb	r3, [r0, #11]
	cmp	r3, ip
	bne.n	.L03d0a
	ldrh	r0, [r0, #24]
	cmp	r0, #0
	beq.n	.L03d0a
	adds	r0, r4, #0
	movs	r1, #2
	ands	r0, r1
	cmp	r0, #0
	beq.n	.L03cfc
	mov	r3, sl
	ldr	r0, [r3, #40]
	adds	r0, r2, r0
	mov	r1, r9
	b.n	.L03d04
	movs	r0, r0
.L03cf4:
	.4byte	gbass_module
.L03cf8:
	.4byte	gbass_ram
.L03cfc:
	mov	r3, sl
	ldr	r0, [r3, #40]
	adds	r0, r2, r0
	mov	r1, r8
.L03d04:
	strh	r1, [r0, #24]
	movs	r3, #1
	str	r3, [sp, #0]
.L03d0a:
	ldr	r1, .L03d34
	ldr	r0, [r1, #44]
	adds	r3, r7, r0
	adds	r0, r3, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, ip
	bne.n	.L03d46
	ldrh	r0, [r3, #56]
	cmp	r0, #0
	beq.n	.L03d46
	adds	r0, r4, #0
	movs	r3, #2
	ands	r0, r3
	cmp	r0, #0
	beq.n	.L03d38
	ldr	r0, [r1, #40]
	adds	r0, r2, r0
	mov	r1, r9
	b.n	.L03d40
	movs	r0, r0
.L03d34:
	.4byte	gbass_module
.L03d38:
	ldr	r3, .L03d8c
	ldr	r0, [r3, #40]
	adds	r0, r2, r0
	mov	r1, r8
.L03d40:
	strh	r1, [r0, #56]
	movs	r3, #1
	str	r3, [sp, #0]
.L03d46:
	subs	r4, #1
	cmp	r4, #0
	bne.n	.L03d56
	adds	r6, #1
	movs	r0, #1
	ldrb	r1, [r6, #0]
	ands	r0, r1
	adds	r4, r0, #1
.L03d56:
	adds	r2, #64
	adds	r7, #96
	subs	r5, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r5, r0
	bne.n	.L03ccc
.L03d64:
	ldr	r3, .L03d90
	ldr	r0, [r3, #8]
	subs	r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	bne.n	.L03d7a
	ldr	r0, [r3, #12]
	cmp	r0, #0
	beq.n	.L03d7a
	bl	GBASS_Process
.L03d7a:
	ldr	r0, [sp, #0]
	add	sp, #4
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.L03d8c:
	.4byte	gbass_module
.L03d90:
	.4byte	gbass_ram

@
@ int GBASS_SFX_Release(u32 handle)  [API]: sets the level-3 release flag (+27),
@ so the effect's sustain loop (63) falls through to its release part.
	.global	GBASS_SFX_Release
	.thumb_func
	.type	GBASS_SFX_Release, %function
GBASS_SFX_Release:
	push	{r4, r5, r6, r7, lr}
	lsrs	r4, r0, #8
	movs	r0, #255
	ands	r4, r0
	movs	r5, #0
	ldr	r1, .L03e58
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	movs	r3, #1
	mov	ip, r1
	ldr	r7, .L03e5c
	movs	r6, #1
	movs	r1, #0
.L03db0:
	ldr	r0, [r7, #60]
	adds	r2, r1, r0
	ldrb	r0, [r2, #11]
	cmp	r0, r4
	bne.n	.L03dc4
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	beq.n	.L03dc4
	strb	r6, [r2, #27]
	movs	r5, #1
.L03dc4:
	ldr	r0, [r7, #60]
	adds	r2, r1, r0
	adds	r0, r2, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r4
	bne.n	.L03de0
	ldrh	r0, [r2, #56]
	cmp	r0, #0
	beq.n	.L03de0
	adds	r0, r2, #0
	adds	r0, #59
	strb	r6, [r0, #0]
	movs	r5, #1
.L03de0:
	adds	r1, #96
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	bne.n	.L03db0
	mov	r1, ip
	ldr	r3, [r1, #84]
	subs	r3, #1
	cmp	r3, r0
	beq.n	.L03e38
	ldr	r7, .L03e5c
	movs	r6, #1
	movs	r1, #0
.L03dfc:
	ldr	r0, [r7, #44]
	adds	r2, r1, r0
	ldrb	r0, [r2, #11]
	cmp	r0, r4
	bne.n	.L03e10
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	beq.n	.L03e10
	strb	r6, [r2, #27]
	movs	r5, #1
.L03e10:
	ldr	r0, [r7, #44]
	adds	r2, r1, r0
	adds	r0, r2, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r4
	bne.n	.L03e2c
	ldrh	r0, [r2, #56]
	cmp	r0, #0
	beq.n	.L03e2c
	adds	r0, r2, #0
	adds	r0, #59
	strb	r6, [r0, #0]
	movs	r5, #1
.L03e2c:
	adds	r1, #96
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	bne.n	.L03dfc
.L03e38:
	mov	r1, ip
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L03e4e
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L03e4e
	bl	GBASS_Process
.L03e4e:
	adds	r0, r5, #0
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0
.L03e58:
	.4byte	gbass_ram
.L03e5c:
	.4byte	gbass_module

@
@ int GBASS_SFX_Pitch(u32 handle, u32 pitch16_16)  [API]: sfx mixer wave rate.
	.global	GBASS_SFX_Pitch
	.thumb_func
	.type	GBASS_SFX_Pitch, %function
GBASS_SFX_Pitch:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #8
	str	r1, [sp, #0]
	lsrs	r5, r0, #8
	movs	r0, #255
	ands	r5, r0
	movs	r0, #0
	mov	sl, r0
	ldr	r1, .L03f28
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	ldr	r3, [r1, #84]
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	beq.n	.L03f00
	ldr	r1, .L03f2c
	mov	r9, r1
	mov	r8, r9
	ldr	r6, .L03f28
	adds	r6, #88
	mov	ip, r6
	movs	r4, #0
	movs	r7, #0
	str	r7, [sp, #4]
	ldr	r2, [r1, #44]
.L03ea0:
	ldrb	r0, [r2, #11]
	cmp	r0, r5
	bne.n	.L03ec0
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	beq.n	.L03ec0
	mov	r6, r9
	ldr	r1, [r6, #40]
	adds	r1, r4, r1
	ldr	r0, [sp, #0]
	mov	r7, ip
	ldrb	r7, [r7, #0]
	lsls	r0, r7
	str	r0, [r1, #28]
	movs	r0, #1
	mov	sl, r0
.L03ec0:
	mov	r1, r8
	ldr	r0, [r1, #44]
	ldr	r6, [sp, #4]
	adds	r1, r6, r0
	adds	r0, r1, #0
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r5
	bne.n	.L03eec
	ldrh	r0, [r1, #56]
	cmp	r0, #0
	beq.n	.L03eec
	mov	r7, r8
	ldr	r1, [r7, #40]
	adds	r1, r4, r1
	ldr	r0, [sp, #0]
	mov	r6, ip
	ldrb	r6, [r6, #0]
	lsls	r0, r6
	str	r0, [r1, #60]
	movs	r7, #1
	mov	sl, r7
.L03eec:
	adds	r4, #64
	ldr	r0, [sp, #4]
	adds	r0, #96
	str	r0, [sp, #4]
	adds	r2, #96
	subs	r3, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r3, r0
	bne.n	.L03ea0
.L03f00:
	ldr	r1, .L03f28
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L03f16
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L03f16
	bl	GBASS_Process
.L03f16:
	mov	r0, sl
	add	sp, #8
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
.L03f28:
	.4byte	gbass_ram
.L03f2c:
	.4byte	gbass_module

@
@ int GBASS_SFX_StartReuse(int sfx, int vol, int tag, int side, int stereoBuf)
@ Allocator. An instrument starting with 99 cc is a GB effect: it always takes
@ GB channel cc (no priority test) and returns 255. Otherwise first pass: a free
@ digital channel (level 3 idle) in a buffer of the requested kind/side; second
@ pass: a channel whose tag priority is <= the new one (LOCK only beats lower).
@ side: 2 = left pair of a stereo buffer, 0 = right pair or mono buffer.
@ Returns the channel index or -1.
	.global	GBASS_SFX_StartReuse
	.thumb_func
	.type	GBASS_SFX_StartReuse, %function
GBASS_SFX_StartReuse:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #28
	mov	sl, r0
	str	r1, [sp, #0]
	mov	r8, r2
	str	r3, [sp, #4]
	movs	r0, #63
	mov	r1, r8
	orrs	r1, r0
	str	r1, [sp, #8]
	ldr	r1, .L03f84
	ldr	r5, [r1, #56]
	movs	r6, #1
	adds	r0, r6, #0
	ldrb	r2, [r5, #0]
	ands	r0, r2
	adds	r4, r0, #1
	adds	r7, r1, #0
	ldr	r3, [sp, #8]
	cmp	r3, #255
	bne.n	.L03f66
	movs	r0, #191
	str	r0, [sp, #8]
.L03f66:
	ldr	r0, .L03f88
	ldr	r2, [r0, #8]
	adds	r1, r2, #1
	str	r1, [r0, #8]
	ldr	r1, [r7, #12]
	mov	r9, r0
	cmp	sl, r1
	blt.n	.L03f8c
	str	r2, [r0, #8]
	cmp	r2, #0
	beq.n	.L03f7e
	b.n	.L04222
.L03f7e:
	ldr	r0, [r0, #12]
	b.n	.L0421a
	movs	r0, r0
.L03f84:
	.4byte	gbass_module
.L03f88:
	.4byte	gbass_ram
.L03f8c:
	ldr	r0, [r7, #16]
	mov	r3, sl
	lsls	r1, r3, #2
	adds	r0, r1, r0
	ldr	r0, [r0, #0]
	str	r1, [sp, #12]
	ldrb	r1, [r0, #0]
	cmp	r1, #153
	bne.n	.L03ff4
	ldrb	r3, [r0, #1]
	cmp	r3, #3
	bgt.n	.L03fe6
	asrs	r0, r3, #1
	ands	r0, r6
	lsls	r1, r0, #1
	adds	r1, r1, r0
	lsls	r1, r1, #5
	ldr	r0, [r7, #60]
	adds	r0, r0, r1
	ands	r3, r6
	lsls	r1, r3, #5
	adds	r2, r0, r1
	mov	r3, r8
	strb	r3, [r2, #11]
	ldr	r0, [r7, #16]
	ldr	r4, [sp, #12]
	adds	r0, r4, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	movs	r0, #0
	strh	r6, [r2, #24]
	strb	r0, [r2, #27]
	mov	r6, r9
	ldr	r0, [r6, #8]
	subs	r0, #1
	str	r0, [r6, #8]
	cmp	r0, #0
	bne.n	.L03fe2
	ldr	r0, [r6, #12]
	cmp	r0, #0
	beq.n	.L03fe2
	bl	GBASS_Process
.L03fe2:
	movs	r0, #255
	b.n	.L04226
.L03fe6:
	mov	r0, r9
	str	r2, [r0, #8]
	cmp	r2, #0
	beq.n	.L03ff0
	b.n	.L04222
.L03ff0:
	ldr	r0, [r0, #12]
	b.n	.L0421a
.L03ff4:
	mov	r2, r9
	ldr	r1, [r2, #84]
	subs	r1, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r1, r0
	beq.n	.L040f0
	movs	r3, #1
	mov	sl, r3
	mov	r3, r9
	movs	r6, #0
	mov	ip, r6
	movs	r0, #0
	str	r0, [sp, #20]
.L04010:
	mov	r0, sl
	ldrb	r2, [r5, #0]
	ands	r0, r2
	ldr	r2, [sp, #60]
	cmp	r0, r2
	bne.n	.L040cc
	movs	r0, #2
	ands	r0, r4
	ldr	r2, [sp, #4]
	cmp	r0, r2
	bne.n	.L040cc
	ldr	r2, [r7, #44]
	add	r2, ip
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	bne.n	.L04078
	mov	r4, r8
	strb	r4, [r2, #11]
	ldr	r1, [r7, #40]
	adds	r1, r6, r1
	movs	r0, #128
	lsls	r0, r0, #1
	str	r0, [r1, #4]
	mov	r0, sp
	ldrh	r0, [r0, #0]
	strh	r0, [r1, #24]
	ldr	r0, [r7, #40]
	adds	r0, r6, r0
	ldr	r1, [r3, #20]
	strh	r1, [r0, #26]
	ldr	r0, [r7, #16]
	ldr	r1, [sp, #12]
	adds	r0, r1, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	mov	r4, sl
	strh	r4, [r2, #24]
	movs	r6, #0
	strb	r6, [r2, #27]
	ldr	r0, [r3, #8]
	subs	r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	bne.n	.L04074
	mov	r1, r9
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L04074
	bl	GBASS_Process
.L04074:
	ldr	r0, [sp, #20]
	b.n	.L04226
.L04078:
	adds	r2, #32
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	bne.n	.L040cc
	mov	r4, r8
	strb	r4, [r2, #11]
	ldr	r0, [r7, #40]
	adds	r0, r6, r0
	adds	r0, #32
	movs	r1, #128
	lsls	r1, r1, #1
	str	r1, [r0, #4]
	mov	r1, sp
	ldrh	r1, [r1, #0]
	strh	r1, [r0, #24]
	ldr	r0, [r7, #40]
	adds	r0, r6, r0
	ldr	r1, [r3, #20]
	strh	r1, [r0, #58]
	ldr	r0, [r7, #16]
	ldr	r4, [sp, #12]
	adds	r0, r4, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	mov	r6, sl
	strh	r6, [r2, #24]
	movs	r0, #0
	strb	r0, [r2, #27]
	ldr	r0, [r3, #8]
	subs	r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	bne.n	.L040c6
	mov	r1, r9
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L040c6
	bl	GBASS_Process
.L040c6:
	ldr	r0, [sp, #20]
	adds	r0, #1
	b.n	.L04226
.L040cc:
	subs	r4, #1
	cmp	r4, #0
	bne.n	.L040dc
	adds	r5, #1
	mov	r0, sl
	ldrb	r2, [r5, #0]
	ands	r0, r2
	adds	r4, r0, #1
.L040dc:
	adds	r6, #64
	movs	r0, #96
	add	ip, r0
	ldr	r2, [sp, #20]
	adds	r2, #2
	str	r2, [sp, #20]
	subs	r1, #1
	subs	r0, #97
	cmp	r1, r0
	bne.n	.L04010
.L040f0:
	ldr	r5, [r7, #56]
	movs	r0, #1
	ldrb	r3, [r5, #0]
	ands	r0, r3
	adds	r4, r0, #1
	mov	r6, r9
	ldr	r1, [r6, #84]
	subs	r1, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r1, r0
	bne.n	.L0410a
	b.n	.L0420c
.L0410a:
	mov	ip, r9
	movs	r0, #0
	str	r0, [sp, #24]
	mov	sl, r0
	movs	r2, #0
	str	r2, [sp, #16]
.L04116:
	movs	r0, #1
	ldrb	r3, [r5, #0]
	ands	r0, r3
	ldr	r6, [sp, #60]
	cmp	r0, r6
	bne.n	.L041e2
	movs	r0, #2
	ands	r0, r4
	ldr	r2, [sp, #4]
	cmp	r0, r2
	bne.n	.L041e2
	adds	r3, r7, #0
	ldr	r2, [r3, #44]
	add	r2, sl
	ldrb	r6, [r2, #11]
	ldr	r0, [sp, #8]
	cmp	r6, r0
	bgt.n	.L04186
	mov	r1, r8
	strb	r1, [r2, #11]
	ldr	r1, [r3, #40]
	ldr	r4, [sp, #24]
	adds	r1, r4, r1
	movs	r0, #128
	lsls	r0, r0, #1
	str	r0, [r1, #4]
	mov	r6, sp
	ldrh	r6, [r6, #0]
	strh	r6, [r1, #24]
	ldr	r0, [r3, #40]
	adds	r0, r4, r0
	mov	r4, ip
	ldr	r1, [r4, #20]
	strh	r1, [r0, #26]
	ldr	r0, [r3, #16]
	ldr	r6, [sp, #12]
	adds	r0, r6, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	movs	r0, #1
	strh	r0, [r2, #24]
	movs	r1, #0
	strb	r1, [r2, #27]
	ldr	r0, [r4, #8]
	subs	r0, #1
	str	r0, [r4, #8]
	cmp	r0, #0
	bne.n	.L04182
	mov	r2, r9
	ldr	r0, [r2, #12]
	cmp	r0, #0
	beq.n	.L04182
	bl	GBASS_Process
.L04182:
	ldr	r0, [sp, #16]
	b.n	.L04226
.L04186:
	adds	r2, #32
	ldrb	r3, [r2, #11]
	ldr	r6, [sp, #8]
	cmp	r3, r6
	bgt.n	.L041e2
	mov	r0, r8
	strb	r0, [r2, #11]
	ldr	r0, [r7, #40]
	ldr	r1, [sp, #24]
	adds	r0, r1, r0
	adds	r0, #32
	movs	r1, #128
	lsls	r1, r1, #1
	str	r1, [r0, #4]
	mov	r3, sp
	ldrh	r3, [r3, #0]
	strh	r3, [r0, #24]
	ldr	r0, [r7, #40]
	ldr	r4, [sp, #24]
	adds	r0, r4, r0
	mov	r6, ip
	ldr	r1, [r6, #20]
	strh	r1, [r0, #58]
	ldr	r0, [r7, #16]
	ldr	r1, [sp, #12]
	adds	r0, r1, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	movs	r3, #1
	strh	r3, [r2, #24]
	movs	r4, #0
	strb	r4, [r2, #27]
	ldr	r0, [r6, #8]
	subs	r0, #1
	str	r0, [r6, #8]
	cmp	r0, #0
	bne.n	.L041dc
	mov	r6, r9
	ldr	r0, [r6, #12]
	cmp	r0, #0
	beq.n	.L041dc
	bl	GBASS_Process
.L041dc:
	ldr	r0, [sp, #16]
	adds	r0, #1
	b.n	.L04226
.L041e2:
	subs	r4, #1
	cmp	r4, #0
	bne.n	.L041f2
	adds	r5, #1
	movs	r0, #1
	ldrb	r2, [r5, #0]
	ands	r0, r2
	adds	r4, r0, #1
.L041f2:
	ldr	r3, [sp, #24]
	adds	r3, #64
	str	r3, [sp, #24]
	movs	r6, #96
	add	sl, r6
	ldr	r0, [sp, #16]
	adds	r0, #2
	str	r0, [sp, #16]
	subs	r1, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r1, r0
	bne.n	.L04116
.L0420c:
	mov	r1, r9
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L04222
	ldr	r0, [r1, #12]
.L0421a:
	cmp	r0, #0
	beq.n	.L04222
	bl	GBASS_Process
.L04222:
	movs	r0, #1
	negs	r0, r0
.L04226:
	add	sp, #28
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ u32 GBASS_SFX_Start(int sfx, int flags, int vol)  [API]: StartStereo(vol, vol).
	.global	GBASS_SFX_Start
	.thumb_func
	.type	GBASS_SFX_Start, %function
GBASS_SFX_Start:
	push	{lr}
	adds	r3, r2, #0
	bl	GBASS_SFX_StartStereo
	pop	{r1}
	bx	r1

@
@ u32 GBASS_SFX_StartStereo(int sfx, int flags, int volL, int volR)  [API]
@ MONO: mono buffer, else one voice on each side; LEFT/RIGHT/STEREO as given.
@ Handle = flags<<16 | (prio<<6 | id)<<8 | channel (255 = GB), or -1.
	.global	GBASS_SFX_StartStereo
	.thumb_func
	.type	GBASS_SFX_StartStereo, %function
GBASS_SFX_StartStereo:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #4
	mov	r9, r0
	adds	r7, r1, #0
	mov	r8, r2
	adds	r4, r3, #0
	bl	GBASS_GetNewSFXID
	adds	r5, r0, #0
	movs	r0, #3
	ands	r0, r7
	lsls	r0, r0, #6
	orrs	r5, r0
	movs	r6, #1
	negs	r6, r6
	ldr	r1, .L042bc
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	movs	r0, #24
	ands	r0, r7
	cmp	r0, #0
	bne.n	.L042d4
	str	r0, [sp, #0]
	mov	r0, r9
	mov	r1, r8
	adds	r2, r5, #0
	movs	r3, #0
	bl	GBASS_SFX_StartReuse
	adds	r6, r0, #0
	movs	r0, #1
	negs	r0, r0
	mov	sl, r0
	cmp	r6, sl
	bne.n	.L04330
	movs	r4, #1
	str	r4, [sp, #0]
	mov	r0, r9
	mov	r1, r8
	adds	r2, r5, #0
	movs	r3, #2
	bl	GBASS_SFX_StartReuse
	adds	r6, r0, #0
	cmp	r6, sl
	bne.n	.L042c0
	str	r4, [sp, #0]
	mov	r0, r9
	mov	r1, r8
	adds	r2, r5, #0
	movs	r3, #0
	bl	GBASS_SFX_StartReuse
	adds	r6, r0, #0
	b.n	.L042ce
.L042bc:
	.4byte	gbass_ram
.L042c0:
	str	r4, [sp, #0]
	mov	r0, r9
	mov	r1, r8
	adds	r2, r5, #0
	movs	r3, #0
	bl	GBASS_SFX_StartReuse
.L042ce:
	movs	r0, #24
	orrs	r7, r0
	b.n	.L04308
.L042d4:
	movs	r0, #8
	ands	r0, r7
	cmp	r0, #0
	beq.n	.L042ee
	movs	r0, #1
	str	r0, [sp, #0]
	mov	r0, r9
	mov	r1, r8
	adds	r2, r5, #0
	movs	r3, #2
	bl	GBASS_SFX_StartReuse
	adds	r6, r0, #0
.L042ee:
	movs	r0, #16
	ands	r0, r7
	cmp	r0, #0
	beq.n	.L04308
	movs	r0, #1
	str	r0, [sp, #0]
	mov	r0, r9
	adds	r1, r4, #0
	adds	r2, r5, #0
	movs	r3, #0
	bl	GBASS_SFX_StartReuse
	adds	r6, r0, #0
.L04308:
	movs	r0, #1
	negs	r0, r0
	cmp	r6, r0
	bne.n	.L04330
	ldr	r1, .L0432c
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L04326
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L04326
	bl	GBASS_Process
.L04326:
	movs	r0, #1
	negs	r0, r0
	b.n	.L04352
.L0432c:
	.4byte	gbass_ram
.L04330:
	ldr	r1, .L04364
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L04346
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L04346
	bl	GBASS_Process
.L04346:
	lsls	r0, r5, #8
	adds	r0, r6, r0
	movs	r1, #255
	ands	r1, r7
	lsls	r1, r1, #16
	adds	r0, r0, r1
.L04352:
	add	sp, #4
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0
.L04364:
	.4byte	gbass_ram

@
@ int GBASS_SFX_StartChnlReuse(int tag, int sfx, int flags, int vol, int channel)
@ Starts an effect on an explicit digital channel (ignores priority).
	.global	GBASS_SFX_StartChnlReuse
	.thumb_func
	.type	GBASS_SFX_StartChnlReuse, %function
GBASS_SFX_StartChnlReuse:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #24
	str	r0, [sp, #0]
	mov	r8, r1
	adds	r4, r2, #0
	str	r3, [sp, #4]
	ldr	r3, [sp, #56]
	movs	r0, #63
	ldr	r1, [sp, #0]
	orrs	r1, r0
	str	r1, [sp, #8]
	ldr	r1, .L043c4
	ldr	r2, [r1, #56]
	mov	ip, r2
	movs	r5, #1
	mov	sl, r5
	mov	r0, sl
	ldrb	r7, [r2, #0]
	ands	r0, r7
	lsls	r0, r0, #1
	adds	r7, r0, #2
	adds	r6, r1, #0
	ldr	r0, [sp, #8]
	cmp	r0, #255
	bne.n	.L043a6
	movs	r1, #191
	str	r1, [sp, #8]
.L043a6:
	ldr	r0, .L043c8
	ldr	r5, [r0, #8]
	adds	r1, r5, #1
	str	r1, [r0, #8]
	ldr	r1, [r6, #12]
	mov	r9, r0
	cmp	r8, r1
	blt.n	.L043cc
	str	r5, [r0, #8]
	cmp	r5, #0
	beq.n	.L043be
	b.n	.L045e6
.L043be:
	ldr	r0, [r0, #12]
	b.n	.L045de
	movs	r0, r0
.L043c4:
	.4byte	gbass_module
.L043c8:
	.4byte	gbass_ram
.L043cc:
	ldr	r0, [r6, #16]
	mov	r2, r8
	lsls	r1, r2, #2
	adds	r0, r1, r0
	ldr	r0, [r0, #0]
	str	r1, [sp, #12]
	ldrb	r1, [r0, #0]
	cmp	r1, #153
	bne.n	.L0443a
	ldrb	r2, [r0, #1]
	cmp	r2, #3
	bgt.n	.L0442c
	asrs	r0, r2, #1
	mov	r3, sl
	ands	r0, r3
	lsls	r1, r0, #1
	adds	r1, r1, r0
	lsls	r1, r1, #5
	ldr	r0, [r6, #60]
	adds	r0, r0, r1
	ands	r2, r3
	lsls	r1, r2, #5
	adds	r2, r0, r1
	mov	r5, sp
	ldrb	r5, [r5, #0]
	strb	r5, [r2, #11]
	ldr	r0, [r6, #16]
	ldr	r7, [sp, #12]
	adds	r0, r7, r0
	ldr	r0, [r0, #0]
	adds	r0, #2
	str	r0, [r2, #28]
	movs	r0, #0
	strh	r3, [r2, #24]
	strb	r0, [r2, #27]
	mov	r1, r9
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L04428
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L04428
	bl	GBASS_Process
.L04428:
	movs	r0, #255
	b.n	.L045ea
.L0442c:
	mov	r2, r9
	str	r5, [r2, #8]
	cmp	r5, #0
	beq.n	.L04436
	b.n	.L045e6
.L04436:
	ldr	r0, [r2, #12]
	b.n	.L045de
.L0443a:
	mov	r5, r9
	ldr	r2, [r5, #84]
	subs	r2, #1
	movs	r0, #1
	negs	r0, r0
	cmp	r2, r0
	bne.n	.L0444a
	b.n	.L045d0
.L0444a:
	mov	sl, r0
	movs	r0, #0
	str	r0, [sp, #16]
	movs	r1, #0
	str	r1, [sp, #20]
	mov	r8, r9
.L04456:
	subs	r3, #1
	cmp	r3, sl
	bne.n	.L044f4
	ldr	r0, [r6, #44]
	adds	r2, r0, r1
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	beq.n	.L0446e
	ldrb	r3, [r2, #11]
	ldr	r5, [sp, #8]
	cmp	r3, r5
	bgt.n	.L044e2
.L0446e:
	mov	r0, sp
	ldrb	r0, [r0, #0]
	strb	r0, [r2, #11]
	ldr	r1, [r6, #40]
	ldr	r3, [sp, #20]
	adds	r1, r3, r1
	movs	r0, #128
	lsls	r0, r0, #1
	str	r0, [r1, #4]
	mov	r5, sp
	ldrh	r5, [r5, #4]
	strh	r5, [r1, #24]
	ldr	r0, [r6, #40]
	adds	r0, r3, r0
	mov	r3, r9
	ldr	r1, [r3, #20]
	strh	r1, [r0, #26]
	ldr	r0, [r6, #16]
	ldr	r5, [sp, #12]
	adds	r0, r5, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	movs	r0, #1
	strh	r0, [r2, #24]
	movs	r1, #0
	strb	r1, [r2, #27]
	movs	r0, #1
	mov	r2, ip
	ldrb	r2, [r2, #0]
	ands	r0, r2
	cmp	r0, #0
	beq.n	.L044be
	cmp	r7, #0
	bne.n	.L044b8
	movs	r4, #17
	negs	r4, r4
	b.n	.L044c4
.L044b8:
	movs	r4, #9
	negs	r4, r4
	b.n	.L044c4
.L044be:
	movs	r3, #25
	negs	r3, r3
	ands	r4, r3
.L044c4:
	mov	r5, r8
	ldr	r0, [r5, #8]
	subs	r0, #1
	str	r0, [r5, #8]
	cmp	r0, #0
	bne.n	.L044dc
	mov	r7, r9
	ldr	r0, [r7, #12]
	cmp	r0, #0
	beq.n	.L044dc
	bl	GBASS_Process
.L044dc:
	ldr	r1, [sp, #0]
	lsls	r0, r1, #8
	b.n	.L04586
.L044e2:
	mov	r3, r8
	ldr	r0, [r3, #8]
	subs	r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	bne.n	.L045e6
	mov	r5, r9
	ldr	r0, [r5, #12]
	b.n	.L045de
.L044f4:
	subs	r3, #1
	cmp	r3, sl
	bne.n	.L045a6
	ldr	r0, [r6, #44]
	adds	r0, r0, r1
	adds	r2, r0, #0
	adds	r2, #32
	ldrh	r0, [r2, #24]
	cmp	r0, #0
	beq.n	.L04510
	ldrb	r0, [r2, #11]
	ldr	r1, [sp, #8]
	cmp	r0, r1
	bgt.n	.L04594
.L04510:
	mov	r3, sp
	ldrb	r3, [r3, #0]
	strb	r3, [r2, #11]
	ldr	r0, [r6, #40]
	ldr	r5, [sp, #20]
	adds	r0, r5, r0
	adds	r0, #32
	movs	r1, #128
	lsls	r1, r1, #1
	str	r1, [r0, #4]
	mov	r1, sp
	ldrh	r1, [r1, #4]
	strh	r1, [r0, #24]
	ldr	r0, [r6, #40]
	adds	r0, r5, r0
	mov	r3, r9
	ldr	r1, [r3, #20]
	strh	r1, [r0, #58]
	ldr	r0, [r6, #16]
	ldr	r5, [sp, #12]
	adds	r0, r5, r0
	ldr	r0, [r0, #0]
	str	r0, [r2, #28]
	movs	r0, #1
	strh	r0, [r2, #24]
	movs	r1, #0
	strb	r1, [r2, #27]
	movs	r0, #1
	mov	r2, ip
	ldrb	r2, [r2, #0]
	ands	r0, r2
	cmp	r0, #0
	beq.n	.L04562
	cmp	r7, #0
	bne.n	.L0455c
	movs	r4, #17
	negs	r4, r4
	b.n	.L04568
.L0455c:
	movs	r4, #9
	negs	r4, r4
	b.n	.L04568
.L04562:
	movs	r3, #25
	negs	r3, r3
	ands	r4, r3
.L04568:
	mov	r5, r8
	ldr	r0, [r5, #8]
	subs	r0, #1
	str	r0, [r5, #8]
	cmp	r0, #0
	bne.n	.L04580
	mov	r7, r9
	ldr	r0, [r7, #12]
	cmp	r0, #0
	beq.n	.L04580
	bl	GBASS_Process
.L04580:
	ldr	r1, [sp, #0]
	lsls	r0, r1, #8
	adds	r0, #1
.L04586:
	ldr	r2, [sp, #16]
	adds	r0, r2, r0
	movs	r1, #255
	ands	r1, r4
	lsls	r1, r1, #16
	adds	r0, r0, r1
	b.n	.L045ea
.L04594:
	mov	r3, r8
	ldr	r0, [r3, #8]
	subs	r0, #1
	str	r0, [r3, #8]
	cmp	r0, #0
	bne.n	.L045e6
	mov	r5, r9
	ldr	r0, [r5, #12]
	b.n	.L045de
.L045a6:
	subs	r7, #1
	cmp	r7, #0
	bne.n	.L045ba
	movs	r7, #1
	add	ip, r7
	movs	r0, #1
	mov	r5, ip
	ldrb	r5, [r5, #0]
	ands	r0, r5
	adds	r7, r0, #1
.L045ba:
	ldr	r0, [sp, #16]
	adds	r0, #2
	str	r0, [sp, #16]
	ldr	r5, [sp, #20]
	adds	r5, #64
	str	r5, [sp, #20]
	adds	r1, #96
	subs	r2, #1
	cmp	r2, sl
	beq.n	.L045d0
	b.n	.L04456
.L045d0:
	mov	r7, r9
	ldr	r0, [r7, #8]
	subs	r0, #1
	str	r0, [r7, #8]
	cmp	r0, #0
	bne.n	.L045e6
	ldr	r0, [r7, #12]
.L045de:
	cmp	r0, #0
	beq.n	.L045e6
	bl	GBASS_Process
.L045e6:
	movs	r0, #1
	negs	r0, r0
.L045ea:
	add	sp, #24
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ u32 GBASS_SFX_StartChnl(int sfx, int flags, int vol, int channel)  [API]
	.global	GBASS_SFX_StartChnl
	.thumb_func
	.type	GBASS_SFX_StartChnl, %function
GBASS_SFX_StartChnl:
	push	{r4, r5, r6, lr}
	mov	r6, r8
	push	{r6}
	sub	sp, #4
	adds	r6, r0, #0
	adds	r5, r1, #0
	mov	r8, r2
	adds	r4, r3, #0
	bl	GBASS_GetNewSFXID
	adds	r1, r0, #0
	movs	r0, #3
	ands	r0, r5
	lsls	r0, r0, #6
	orrs	r0, r1
	str	r4, [sp, #0]
	adds	r1, r6, #0
	adds	r2, r5, #0
	mov	r3, r8
	bl	GBASS_SFX_StartChnlReuse
	add	sp, #4
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6}
	pop	{r1}
	bx	r1
	movs	r0, r0

@ u32 GBASS_SFX_Restart(u32 handle, int sfx, int flags, int vol)  [API]
	.global	GBASS_SFX_Restart
	.thumb_func
	.type	GBASS_SFX_Restart, %function
GBASS_SFX_Restart:
	push	{lr}
	sub	sp, #4
	str	r3, [sp, #0]
	bl	GBASS_SFX_RestartStereo
	add	sp, #4
	pop	{r1}
	bx	r1

@
@ u32 GBASS_SFX_RestartStereo(u32 handle, int sfx, int flags, int volL, int volR)  [API]
@ Reuses the channel(s) of handle if it is still allocated, else StartStereo.
	.global	GBASS_SFX_RestartStereo
	.thumb_func
	.type	GBASS_SFX_RestartStereo, %function
GBASS_SFX_RestartStereo:
	push	{r4, r5, r6, r7, lr}
	mov	r7, sl
	mov	r6, r9
	mov	r5, r8
	push	{r5, r6, r7}
	sub	sp, #20
	str	r0, [sp, #4]
	str	r1, [sp, #8]
	str	r2, [sp, #12]
	mov	r9, r3
	lsrs	r6, r0, #8
	movs	r0, #255
	ands	r6, r0
	ldr	r0, .L04684
	ldr	r7, [r0, #56]
	movs	r0, #1
	ldrb	r1, [r7, #0]
	ands	r0, r1
	lsls	r0, r0, #1
	adds	r4, r0, #2
	movs	r2, #2
	str	r2, [sp, #16]
	subs	r2, #3
	ldr	r0, [sp, #4]
	cmp	r0, r2
	bne.n	.L04688
	ldr	r0, [sp, #8]
	ldr	r1, [sp, #12]
	mov	r2, r9
	bl	GBASS_SFX_StartStereo
	b.n	.L04802
.L04684:
	.4byte	gbass_module
.L04688:
	movs	r0, #192
	lsls	r0, r0, #13
	ldr	r1, [sp, #4]
	ands	r0, r1
	cmp	r0, #24
	bne.n	.L04760
	ldr	r1, .L04758
	ldr	r0, [r1, #8]
	adds	r0, #1
	str	r0, [r1, #8]
	ldr	r5, [r1, #84]
	subs	r5, #1
	cmp	r5, r2
	beq.n	.L0472c
	movs	r2, #0
	mov	sl, r2
	mov	r8, r2
.L046aa:
	ldr	r0, .L0475c
	ldr	r0, [r0, #44]
	add	r0, sl
	mov	r1, r8
	ldrb	r0, [r0, #11]
	cmp	r0, r6
	bne.n	.L046d6
	movs	r0, #2
	ands	r0, r4
	ldr	r3, [sp, #52]
	cmp	r0, #0
	beq.n	.L046c4
	mov	r3, r9
.L046c4:
	str	r1, [sp, #0]
	adds	r0, r6, #0
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #12]
	bl	GBASS_SFX_StartChnlReuse
	ldr	r0, [sp, #16]
	subs	r0, #1
	str	r0, [sp, #16]
.L046d6:
	ldr	r0, .L0475c
	ldr	r0, [r0, #44]
	add	r0, sl
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r6
	bne.n	.L04706
	movs	r0, #2
	ands	r0, r4
	ldr	r3, [sp, #52]
	cmp	r0, #0
	beq.n	.L046f0
	mov	r3, r9
.L046f0:
	mov	r0, r8
	adds	r0, #1
	str	r0, [sp, #0]
	adds	r0, r6, #0
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #12]
	bl	GBASS_SFX_StartChnlReuse
	ldr	r1, [sp, #16]
	subs	r1, #1
	str	r1, [sp, #16]
.L04706:
	subs	r4, #1
	cmp	r4, #0
	bne.n	.L04716
	adds	r7, #1
	movs	r0, #1
	ldrb	r2, [r7, #0]
	ands	r0, r2
	adds	r4, r0, #1
.L04716:
	movs	r0, #96
	add	sl, r0
	movs	r1, #2
	add	r8, r1
	subs	r5, #1
	subs	r0, #97
	cmp	r5, r0
	beq.n	.L0472c
	ldr	r2, [sp, #16]
	cmp	r2, #0
	bne.n	.L046aa
.L0472c:
	ldr	r1, .L04758
	ldr	r0, [r1, #8]
	subs	r0, #1
	str	r0, [r1, #8]
	cmp	r0, #0
	bne.n	.L04742
	ldr	r0, [r1, #12]
	cmp	r0, #0
	beq.n	.L04742
	bl	GBASS_Process
.L04742:
	ldr	r0, [sp, #16]
	cmp	r0, #2
	bne.n	.L04800
	ldr	r0, [sp, #8]
	ldr	r1, [sp, #12]
	mov	r2, r9
	ldr	r3, [sp, #52]
	bl	GBASS_SFX_StartStereo
	b.n	.L04802
	movs	r0, r0
.L04758:
	.4byte	gbass_ram
.L0475c:
	.4byte	gbass_module
.L04760:
	movs	r1, #0
	ldr	r0, .L047f8
	ldr	r5, [r0, #84]
	subs	r5, #1
	cmp	r5, r2
	beq.n	.L047e4
	mov	sl, r1
	mov	r8, r1
.L04770:
	ldr	r0, .L047fc
	ldr	r0, [r0, #44]
	add	r0, sl
	ldrb	r0, [r0, #11]
	cmp	r0, r6
	bne.n	.L04798
	movs	r0, #2
	ands	r0, r4
	ldr	r3, [sp, #52]
	cmp	r0, #0
	beq.n	.L04788
	mov	r3, r9
.L04788:
	mov	r1, r8
	str	r1, [sp, #0]
	adds	r0, r6, #0
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #12]
	bl	GBASS_SFX_StartChnlReuse
	movs	r1, #1
.L04798:
	ldr	r0, .L047fc
	ldr	r0, [r0, #44]
	add	r0, sl
	adds	r0, #43
	ldrb	r0, [r0, #0]
	cmp	r0, r6
	bne.n	.L047c4
	movs	r0, #2
	ands	r0, r4
	ldr	r3, [sp, #52]
	cmp	r0, #0
	beq.n	.L047b2
	mov	r3, r9
.L047b2:
	mov	r0, r8
	adds	r0, #1
	str	r0, [sp, #0]
	adds	r0, r6, #0
	ldr	r1, [sp, #8]
	ldr	r2, [sp, #12]
	bl	GBASS_SFX_StartChnlReuse
	movs	r1, #1
.L047c4:
	subs	r4, #1
	cmp	r4, #0
	bne.n	.L047d4
	adds	r7, #1
	movs	r0, #1
	ldrb	r2, [r7, #0]
	ands	r0, r2
	adds	r4, r0, #1
.L047d4:
	movs	r0, #96
	add	sl, r0
	movs	r2, #2
	add	r8, r2
	subs	r5, #1
	subs	r0, #97
	cmp	r5, r0
	bne.n	.L04770
.L047e4:
	cmp	r1, #0
	bne.n	.L04800
	ldr	r0, [sp, #8]
	ldr	r1, [sp, #12]
	mov	r2, r9
	mov	r3, r9
	bl	GBASS_SFX_StartStereo
	b.n	.L04802
	movs	r0, r0
.L047f8:
	.4byte	gbass_ram
.L047fc:
	.4byte	gbass_module
.L04800:
	ldr	r0, [sp, #4]
.L04802:
	add	sp, #20
	pop	{r3, r4, r5}
	mov	r8, r3
	mov	r9, r4
	mov	sl, r5
	pop	{r4, r5, r6, r7}
	pop	{r1}
	bx	r1
	movs	r0, r0

@
@ GBASS_ReverbClear / ReverbMusicOn / ReverbMusicOff / ReverbMusicMode: only set
@ flag bits 3-8 of ram+44. Nothing in this build reads them (no reverb DSP is
@ linked); SaveState stores them. Not in gbass.h.
	.global	GBASS_ReverbClear
	.thumb_func
	.type	GBASS_ReverbClear, %function
GBASS_ReverbClear:
	ldr	r0, .L04820
	ldr	r1, [r0, #68]
	movs	r2, #8
	orrs	r1, r2
	str	r1, [r0, #68]
	bx	lr
.L04820:
	.4byte	gbass_ram
	.global	GBASS_ReverbMusicOn
	.thumb_func
	.type	GBASS_ReverbMusicOn, %function
GBASS_ReverbMusicOn:
	push	{lr}
	ldr	r3, .L0484c
	ldr	r1, [r3, #68]
	movs	r2, #16
	adds	r0, r1, #0
	ands	r0, r2
	cmp	r0, #0
	bne.n	.L04848
	adds	r0, r2, #0
	orrs	r0, r1
	str	r0, [r3, #68]
	movs	r1, #192
	lsls	r1, r1, #3
	ands	r0, r1
	cmp	r0, #0
	bne.n	.L04848
	bl	GBASS_ReverbClear
.L04848:
	pop	{r0}
	bx	r0
.L0484c:
	.4byte	gbass_ram
	.global	GBASS_ReverbMusicOff
	.thumb_func
	.type	GBASS_ReverbMusicOff, %function
GBASS_ReverbMusicOff:
	ldr	r0, .L04860
	ldr	r1, [r0, #68]
	movs	r2, #17
	negs	r2, r2
	ands	r1, r2
	str	r1, [r0, #68]
	bx	lr
	movs	r0, r0
.L04860:
	.4byte	gbass_ram
	.global	GBASS_ReverbMusicMode
	.thumb_func
	.type	GBASS_ReverbMusicMode, %function
GBASS_ReverbMusicMode:
	push	{r4, lr}
	adds	r4, r0, #0
	lsls	r4, r4, #4
	movs	r0, #16
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L04894
	ldr	r2, .L0488c
	ldr	r1, [r2, #68]
	ldr	r0, .L04890
	ands	r1, r0
	movs	r0, #240
	lsls	r0, r0, #1
	ands	r0, r4
	orrs	r1, r0
	str	r1, [r2, #68]
	bl	GBASS_ReverbMusicOn
	b.n	.L048aa
	movs	r0, r0
.L0488c:
	.4byte	gbass_ram
.L04890:
	.4byte	0xfffffe1f
.L04894:
	bl	GBASS_ReverbMusicOff
	ldr	r2, .L048b0
	ldr	r1, [r2, #68]
	ldr	r0, .L048b4
	ands	r1, r0
	movs	r0, #240
	lsls	r0, r0, #1
	ands	r0, r4
	orrs	r1, r0
	str	r1, [r2, #68]
.L048aa:
	pop	{r4}
	pop	{r0}
	bx	r0
.L048b0:
	.4byte	gbass_ram
.L048b4:
	.4byte	0xfffffe1f

@
@ void GBASS_NoMusicMode(int enable)  [API]: flag b14 -- skip SilentMix for music
@ voices hidden by sound effects.
	.global	GBASS_NoMusicMode
	.thumb_func
	.type	GBASS_NoMusicMode, %function
GBASS_NoMusicMode:
	cmp	r0, #0
	beq.n	.L048cc
	ldr	r0, .L048c8
	ldr	r1, [r0, #68]
	movs	r2, #128
	lsls	r2, r2, #7
	orrs	r1, r2
	b.n	.L048d4
.L048c8:
	.4byte	gbass_ram
.L048cc:
	ldr	r0, .L048d8
	ldr	r1, [r0, #68]
	ldr	r2, .L048dc
	ands	r1, r2
.L048d4:
	str	r1, [r0, #68]
	bx	lr
.L048d8:
	.4byte	gbass_ram
.L048dc:
	.4byte	0xffffbfff
	@ ---- start of a gcc2-compiled C unit (original object has a local .gcc2_compiled. marker here) ----

@
@ ---------------------------------------------------------------- digi.c
@ DigiInit(void): SOUNDCNT_X off, SOUNDCNT_H = 0x0E shadow, timers 0/1 and DMA1/2
@ cleared, defaults: DMA1/DMA2, timer 0, rate 0x5F1, no DMA IRQ; SOUNDCNT_X on.
@ The digi layer keeps its state in .slowram: SOUNDCNT_H shadow, dma[2], dmaintenable[2],
@ timer[2], rate[2]. Channel mask arguments: bit0 = DirectSound A, bit1 = B.
	.global	DigiInit
	.thumb_func
	.type	DigiInit, %function
DigiInit:
	push	{r4, lr}
	ldr	r4, .L04930
	movs	r2, #0
	strh	r2, [r4, #0]
	ldr	r3, .L04934
	ldr	r1, .L04938
	movs	r0, #14
	strh	r0, [r1, #0]
	strh	r0, [r3, #0]
	ldr	r0, .L0493c
	movs	r1, #0
	str	r1, [r0, #0]
	subs	r0, #4
	str	r1, [r0, #0]
	subs	r0, #48
	str	r1, [r0, #0]
	subs	r0, #12
	str	r1, [r0, #0]
	ldr	r0, .L04940
	strb	r2, [r0, #0]
	movs	r1, #1
	strb	r1, [r0, #1]
	ldr	r0, .L04944
	strb	r2, [r0, #0]
	strb	r1, [r0, #1]
	ldr	r1, .L04948
	ldr	r0, .L0494c
	str	r0, [r1, #0]
	str	r0, [r1, #4]
	ldr	r0, .L04950
	strb	r2, [r0, #0]
	strb	r2, [r0, #1]
	movs	r0, #128
	strh	r0, [r4, #0]
	movs	r0, #2
	strh	r0, [r3, #0]
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L04930:
	.4byte	0x04000084
.L04934:
	.4byte	0x04000082
.L04938:
	.4byte	SOUNDCNT_H
.L0493c:
	.4byte	0x04000104
.L04940:
	.4byte	dma
.L04944:
	.4byte	timer
.L04948:
	.4byte	rate
.L0494c:
	.4byte	0x000005f1
.L04950:
	.4byte	dmaintenable

@ DigiStop(mask): stops the FIFO DMA(s) and timer(s).
	.global	DigiStop
	.thumb_func
	.type	DigiStop, %function
DigiStop:
	push	{r4, lr}
	adds	r3, r0, #0
	movs	r2, #1
	ands	r2, r3
	cmp	r2, #0
	beq.n	.L0496a
	ldr	r1, .L04990
	movs	r4, #128
	lsls	r4, r4, #4
	adds	r0, r4, #0
	strh	r0, [r1, #0]
.L0496a:
	movs	r0, #2
	ands	r0, r3
	cmp	r0, #0
	beq.n	.L0497c
	ldr	r1, .L04990
	movs	r4, #128
	lsls	r4, r4, #8
	adds	r0, r4, #0
	strh	r0, [r1, #0]
.L0497c:
	cmp	r2, #0
	beq.n	.L049c0
	ldr	r0, .L04994
	ldrb	r1, [r0, #0]
	cmp	r1, #0
	beq.n	.L0499c
	ldr	r1, .L04998
	movs	r0, #0
	str	r0, [r1, #0]
	b.n	.L049a0
.L04990:
	.4byte	0x04000082
.L04994:
	.4byte	dma
.L04998:
	.4byte	0x040000d0
.L0499c:
	ldr	r0, .L049b0
	str	r1, [r0, #0]
.L049a0:
	ldr	r0, .L049b4
	ldrb	r1, [r0, #0]
	cmp	r1, #0
	beq.n	.L049bc
	ldr	r1, .L049b8
	movs	r0, #0
	strh	r0, [r1, #0]
	b.n	.L049c0
.L049b0:
	.4byte	0x040000c4
.L049b4:
	.4byte	timer
.L049b8:
	.4byte	0x04000106
.L049bc:
	ldr	r0, .L049d8
	strh	r1, [r0, #0]
.L049c0:
	movs	r0, #2
	ands	r0, r3
	cmp	r0, #0
	beq.n	.L04a08
	ldr	r0, .L049dc
	ldrb	r1, [r0, #1]
	cmp	r1, #0
	beq.n	.L049e4
	ldr	r1, .L049e0
	movs	r0, #0
	str	r0, [r1, #0]
	b.n	.L049e8
.L049d8:
	.4byte	0x04000102
.L049dc:
	.4byte	dma
.L049e0:
	.4byte	0x040000d0
.L049e4:
	ldr	r0, .L049f8
	str	r1, [r0, #0]
.L049e8:
	ldr	r0, .L049fc
	ldrb	r1, [r0, #1]
	cmp	r1, #0
	beq.n	.L04a04
	ldr	r1, .L04a00
	movs	r0, #0
	strh	r0, [r1, #0]
	b.n	.L04a08
.L049f8:
	.4byte	0x040000c4
.L049fc:
	.4byte	timer
.L04a00:
	.4byte	0x04000106
.L04a04:
	ldr	r0, .L04a10
	strh	r1, [r0, #0]
.L04a08:
	pop	{r4}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L04a10:
	.4byte	0x04000102

@ DigiDMA(mask, dma 0=DMA1/1=DMA2, irq): chooses DMA channel per sound.
	.global	DigiDMA
	.thumb_func
	.type	DigiDMA, %function
DigiDMA:
	push	{r4, r5, lr}
	adds	r4, r0, #0
	adds	r3, r1, #0
	adds	r5, r2, #0
	movs	r0, #1
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L04a32
	ldr	r2, .L04a4c
	movs	r1, #1
	adds	r0, r3, #0
	ands	r0, r1
	strb	r0, [r2, #0]
	ldr	r0, .L04a50
	strb	r5, [r0, #0]
.L04a32:
	movs	r0, #2
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L04a46
	ldr	r0, .L04a4c
	movs	r1, #1
	ands	r3, r1
	strb	r3, [r0, #1]
	ldr	r0, .L04a50
	strb	r5, [r0, #1]
.L04a46:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
.L04a4c:
	.4byte	dma
.L04a50:
	.4byte	dmaintenable

@
@ DigiReSeekStereo(left, right): if A and B share a timer, stops it, reprograms
@ both DMAs (control 0xB660 / 0xF660 with IRQ) to the new buffers and restarts
@ the timer, so both channels restart sample-aligned. Else DigiReSeek each.
	.global	DigiReSeekStereo
	.thumb_func
	.type	DigiReSeekStereo, %function
DigiReSeekStereo:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	adds	r7, r0, #0
	mov	r8, r1
	ldr	r0, .L04a7c
	adds	r5, r0, #0
	ldrb	r0, [r5, #0]
	ldrb	r1, [r5, #1]
	cmp	r0, r1
	beq.n	.L04a80
	movs	r0, #1
	adds	r1, r7, #0
	bl	DigiReSeek
	movs	r0, #2
	mov	r1, r8
	bl	DigiReSeek
	b.n	.L04b58
.L04a7c:
	.4byte	timer
.L04a80:
	ldr	r0, .L04a94
	ldrb	r1, [r0, #0]
	adds	r2, r0, #0
	cmp	r1, #0
	beq.n	.L04aa0
	ldr	r4, .L04a98
	ldr	r0, .L04a9c
	mov	ip, r0
	b.n	.L04aa6
	movs	r0, r0
.L04a94:
	.4byte	dma
.L04a98:
	.4byte	0x040000d0
.L04a9c:
	.4byte	0x040000c8
.L04aa0:
	ldr	r4, .L04ab4
	ldr	r1, .L04ab8
	mov	ip, r1
.L04aa6:
	ldrb	r1, [r5, #0]
	cmp	r1, #0
	beq.n	.L04ac0
	ldr	r1, .L04abc
	movs	r0, #0
	str	r0, [r1, #0]
	b.n	.L04ac4
.L04ab4:
	.4byte	0x040000c4
.L04ab8:
	.4byte	0x040000bc
.L04abc:
	.4byte	0x04000104
.L04ac0:
	ldr	r0, .L04ad0
	str	r1, [r0, #0]
.L04ac4:
	ldrb	r0, [r2, #1]
	cmp	r0, #0
	beq.n	.L04adc
	ldr	r3, .L04ad4
	ldr	r6, .L04ad8
	b.n	.L04ae0
.L04ad0:
	.4byte	0x04000100
.L04ad4:
	.4byte	0x040000d0
.L04ad8:
	.4byte	0x040000c8
.L04adc:
	ldr	r3, .L04b24
	ldr	r6, .L04b28
.L04ae0:
	ldr	r2, .L04b2c
	ldrb	r0, [r2, #0]
	ldr	r1, .L04b30
	cmp	r0, #0
	beq.n	.L04aec
	ldr	r1, .L04b34
.L04aec:
	str	r1, [r4, #0]
	ldrb	r0, [r2, #1]
	ldr	r1, .L04b30
	cmp	r0, #0
	beq.n	.L04af8
	ldr	r1, .L04b34
.L04af8:
	str	r1, [r3, #0]
	mov	r0, ip
	str	r7, [r0, #0]
	mov	r1, r8
	str	r1, [r6, #0]
	ldrb	r0, [r2, #0]
	ldr	r1, .L04b38
	cmp	r0, #0
	beq.n	.L04b0c
	ldr	r1, .L04b3c
.L04b0c:
	str	r1, [r4, #0]
	ldrb	r0, [r2, #1]
	ldr	r1, .L04b38
	cmp	r0, #0
	beq.n	.L04b18
	ldr	r1, .L04b3c
.L04b18:
	str	r1, [r3, #0]
	ldrb	r0, [r5, #0]
	cmp	r0, #0
	beq.n	.L04b44
	ldr	r2, .L04b40
	b.n	.L04b46
.L04b24:
	.4byte	0x040000c4
.L04b28:
	.4byte	0x040000bc
.L04b2c:
	.4byte	dmaintenable
.L04b30:
	.4byte	0x36600004
.L04b34:
	.4byte	0x76600004
.L04b38:
	.4byte	0xb6600004
.L04b3c:
	.4byte	0xf6600004
.L04b40:
	.4byte	0x04000104
.L04b44:
	ldr	r2, .L04b64
.L04b46:
	ldr	r0, .L04b68
	ldr	r0, [r0, #0]
	negs	r0, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	movs	r1, #128
	lsls	r1, r1, #16
	orrs	r0, r1
	str	r0, [r2, #0]
.L04b58:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L04b64:
	.4byte	0x04000100
.L04b68:
	.4byte	rate

@ DigiReSeek(mask, buf): restart one channel on a new buffer.
	.global	DigiReSeek
	.thumb_func
	.type	DigiReSeek, %function
DigiReSeek:
	push	{r4, r5, r6, r7, lr}
	adds	r5, r0, #0
	adds	r6, r1, #0
	movs	r0, #1
	ands	r0, r5
	cmp	r0, #0
	beq.n	.L04c18
	ldr	r0, .L04b8c
	ldrb	r1, [r0, #0]
	adds	r7, r0, #0
	cmp	r1, #0
	beq.n	.L04b94
	ldr	r1, .L04b90
	movs	r0, #0
	str	r0, [r1, #0]
	b.n	.L04b98
.L04b8c:
	.4byte	timer
.L04b90:
	.4byte	0x04000104
.L04b94:
	ldr	r0, .L04ba8
	str	r1, [r0, #0]
.L04b98:
	ldr	r0, .L04bac
	ldrb	r0, [r0, #0]
	cmp	r0, #0
	beq.n	.L04bb8
	ldr	r2, .L04bb0
	ldr	r3, .L04bb4
	b.n	.L04bbc
	movs	r0, r0
.L04ba8:
	.4byte	0x04000100
.L04bac:
	.4byte	dma
.L04bb0:
	.4byte	0x040000d0
.L04bb4:
	.4byte	0x040000c8
.L04bb8:
	ldr	r2, .L04be4
	ldr	r3, .L04be8
.L04bbc:
	ldr	r4, .L04bec
	ldrb	r0, [r4, #0]
	ldr	r1, .L04bf0
	cmp	r0, #0
	beq.n	.L04bc8
	ldr	r1, .L04bf4
.L04bc8:
	str	r1, [r2, #0]
	str	r6, [r3, #0]
	ldrb	r0, [r4, #0]
	ldr	r1, .L04bf8
	cmp	r0, #0
	beq.n	.L04bd6
	ldr	r1, .L04bfc
.L04bd6:
	str	r1, [r2, #0]
	ldrb	r0, [r7, #0]
	cmp	r0, #0
	beq.n	.L04c04
	ldr	r2, .L04c00
	b.n	.L04c06
	movs	r0, r0
.L04be4:
	.4byte	0x040000c4
.L04be8:
	.4byte	0x040000bc
.L04bec:
	.4byte	dmaintenable
.L04bf0:
	.4byte	0x36600004
.L04bf4:
	.4byte	0x76600004
.L04bf8:
	.4byte	0xb6600004
.L04bfc:
	.4byte	0xf6600004
.L04c00:
	.4byte	0x04000104
.L04c04:
	ldr	r2, .L04c34
.L04c06:
	ldr	r0, .L04c38
	ldr	r0, [r0, #0]
	negs	r0, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	movs	r1, #128
	lsls	r1, r1, #16
	orrs	r0, r1
	str	r0, [r2, #0]
.L04c18:
	movs	r0, #2
	ands	r0, r5
	cmp	r0, #0
	beq.n	.L04cc8
	ldr	r0, .L04c3c
	ldrb	r1, [r0, #1]
	adds	r7, r0, #0
	cmp	r1, #0
	beq.n	.L04c44
	ldr	r1, .L04c40
	movs	r0, #0
	str	r0, [r1, #0]
	b.n	.L04c48
	movs	r0, r0
.L04c34:
	.4byte	0x04000100
.L04c38:
	.4byte	rate
.L04c3c:
	.4byte	timer
.L04c40:
	.4byte	0x04000104
.L04c44:
	ldr	r0, .L04c58
	str	r1, [r0, #0]
.L04c48:
	ldr	r0, .L04c5c
	ldrb	r0, [r0, #1]
	cmp	r0, #0
	beq.n	.L04c68
	ldr	r2, .L04c60
	ldr	r3, .L04c64
	b.n	.L04c6c
	movs	r0, r0
.L04c58:
	.4byte	0x04000100
.L04c5c:
	.4byte	dma
.L04c60:
	.4byte	0x040000d0
.L04c64:
	.4byte	0x040000c8
.L04c68:
	ldr	r2, .L04c94
	ldr	r3, .L04c98
.L04c6c:
	ldr	r4, .L04c9c
	ldrb	r0, [r4, #1]
	ldr	r1, .L04ca0
	cmp	r0, #0
	beq.n	.L04c78
	ldr	r1, .L04ca4
.L04c78:
	str	r1, [r2, #0]
	str	r6, [r3, #0]
	ldrb	r0, [r4, #1]
	ldr	r1, .L04ca8
	cmp	r0, #0
	beq.n	.L04c86
	ldr	r1, .L04cac
.L04c86:
	str	r1, [r2, #0]
	ldrb	r0, [r7, #1]
	cmp	r0, #0
	beq.n	.L04cb4
	ldr	r2, .L04cb0
	b.n	.L04cb6
	movs	r0, r0
.L04c94:
	.4byte	0x040000c4
.L04c98:
	.4byte	0x040000bc
.L04c9c:
	.4byte	dmaintenable
.L04ca0:
	.4byte	0x36600004
.L04ca4:
	.4byte	0x76600004
.L04ca8:
	.4byte	0xb6600004
.L04cac:
	.4byte	0xf6600004
.L04cb0:
	.4byte	0x04000104
.L04cb4:
	ldr	r2, .L04cd0
.L04cb6:
	ldr	r0, .L04cd4
	ldr	r0, [r0, #4]
	negs	r0, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	movs	r1, #128
	lsls	r1, r1, #16
	orrs	r0, r1
	str	r0, [r2, #0]
.L04cc8:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L04cd0:
	.4byte	0x04000100
.L04cd4:
	.4byte	rate

@ DigiSeek(mask, buf): set the DMA source and FIFO destination.
	.global	DigiSeek
	.thumb_func
	.type	DigiSeek, %function
DigiSeek:
	push	{r4, r5, r6, r7, lr}
	adds	r6, r0, #0
	adds	r7, r1, #0
	movs	r0, #1
	ands	r0, r6
	cmp	r0, #0
	beq.n	.L04d2e
	ldr	r0, .L04cf8
	ldrb	r0, [r0, #0]
	cmp	r0, #0
	beq.n	.L04d08
	ldr	r3, .L04cfc
	ldr	r1, .L04d00
	ldr	r4, .L04d04
	b.n	.L04d0e
	movs	r0, r0
.L04cf8:
	.4byte	dma
.L04cfc:
	.4byte	0x040000d0
.L04d00:
	.4byte	0x040000c8
.L04d04:
	.4byte	0x040000cc
.L04d08:
	ldr	r3, .L04d48
	ldr	r1, .L04d4c
	ldr	r4, .L04d50
.L04d0e:
	ldr	r5, .L04d54
	ldrb	r0, [r5, #0]
	ldr	r2, .L04d58
	cmp	r0, #0
	beq.n	.L04d1a
	ldr	r2, .L04d5c
.L04d1a:
	str	r2, [r3, #0]
	str	r7, [r1, #0]
	ldr	r0, .L04d60
	str	r0, [r4, #0]
	ldrb	r0, [r5, #0]
	ldr	r2, .L04d64
	cmp	r0, #0
	beq.n	.L04d2c
	ldr	r2, .L04d68
.L04d2c:
	str	r2, [r3, #0]
.L04d2e:
	movs	r0, #2
	ands	r0, r6
	cmp	r0, #0
	beq.n	.L04da2
	ldr	r0, .L04d6c
	ldrb	r0, [r0, #1]
	cmp	r0, #0
	beq.n	.L04d7c
	ldr	r3, .L04d70
	ldr	r1, .L04d74
	ldr	r4, .L04d78
	b.n	.L04d82
	movs	r0, r0
.L04d48:
	.4byte	0x040000c4
.L04d4c:
	.4byte	0x040000bc
.L04d50:
	.4byte	0x040000c0
.L04d54:
	.4byte	dmaintenable
.L04d58:
	.4byte	0x36600004
.L04d5c:
	.4byte	0x76600004
.L04d60:
	.4byte	0x040000a0
.L04d64:
	.4byte	0xb6600004
.L04d68:
	.4byte	0xf6600004
.L04d6c:
	.4byte	dma
.L04d70:
	.4byte	0x040000d0
.L04d74:
	.4byte	0x040000c8
.L04d78:
	.4byte	0x040000cc
.L04d7c:
	ldr	r3, .L04da8
	ldr	r1, .L04dac
	ldr	r4, .L04db0
.L04d82:
	ldr	r5, .L04db4
	ldrb	r0, [r5, #1]
	ldr	r2, .L04db8
	cmp	r0, #0
	beq.n	.L04d8e
	ldr	r2, .L04dbc
.L04d8e:
	str	r2, [r3, #0]
	str	r7, [r1, #0]
	ldr	r0, .L04dc0
	str	r0, [r4, #0]
	ldrb	r0, [r5, #1]
	ldr	r1, .L04dc4
	cmp	r0, #0
	beq.n	.L04da0
	ldr	r1, .L04dc8
.L04da0:
	str	r1, [r3, #0]
.L04da2:
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.L04da8:
	.4byte	0x040000c4
.L04dac:
	.4byte	0x040000bc
.L04db0:
	.4byte	0x040000c0
.L04db4:
	.4byte	dmaintenable
.L04db8:
	.4byte	0x36600004
.L04dbc:
	.4byte	0x76600004
.L04dc0:
	.4byte	0x040000a4
.L04dc4:
	.4byte	0xb6600004
.L04dc8:
	.4byte	0xf6600004

@ DigiRate(mask, timer, hz): reload = 2^24/hz, selects timer in SOUNDCNT_H.
	.global	DigiRate
	.thumb_func
	.type	DigiRate, %function
DigiRate:
	push	{r4, r5, r6, r7, lr}
	mov	r7, r8
	push	{r7}
	adds	r6, r0, #0
	adds	r7, r1, #0
	mov	r8, r2
	movs	r0, #1
	ands	r0, r6
	cmp	r0, #0
	beq.n	.L04e3e
	ldr	r1, .L04e14
	movs	r0, #1
	adds	r4, r7, #0
	ands	r4, r0
	strb	r4, [r1, #0]
	ldr	r5, .L04e18
	movs	r0, #128
	lsls	r0, r0, #17
	mov	r1, r8
	bl	__divsi3
	adds	r3, r0, #0
	str	r3, [r5, #0]
	cmp	r4, #0
	beq.n	.L04e24
	ldr	r2, .L04e1c
	movs	r0, #0
	str	r0, [r2, #0]
	ldr	r1, .L04e20
	movs	r4, #128
	lsls	r4, r4, #3
	adds	r0, r4, #0
	ldrh	r4, [r1, #0]
	orrs	r0, r4
	b.n	.L04e30
	movs	r0, r0
.L04e14:
	.4byte	timer
.L04e18:
	.4byte	rate
.L04e1c:
	.4byte	0x04000104
.L04e20:
	.4byte	SOUNDCNT_H
.L04e24:
	ldr	r2, .L04e78
	str	r4, [r2, #0]
	ldr	r1, .L04e7c
	ldr	r0, .L04e80
	ldrh	r4, [r1, #0]
	ands	r0, r4
.L04e30:
	strh	r0, [r1, #0]
	ldr	r1, .L04e84
	strh	r0, [r1, #0]
	negs	r0, r3
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [r2, #0]
.L04e3e:
	movs	r0, #2
	ands	r0, r6
	cmp	r0, #0
	beq.n	.L04eae
	ldr	r1, .L04e88
	movs	r0, #1
	adds	r4, r7, #0
	ands	r4, r0
	strb	r4, [r1, #1]
	ldr	r5, .L04e8c
	movs	r0, #128
	lsls	r0, r0, #17
	mov	r1, r8
	bl	__divsi3
	adds	r3, r0, #0
	str	r3, [r5, #4]
	cmp	r4, #0
	beq.n	.L04e94
	ldr	r2, .L04e90
	movs	r0, #0
	str	r0, [r2, #0]
	ldr	r1, .L04e7c
	movs	r4, #128
	lsls	r4, r4, #7
	adds	r0, r4, #0
	ldrh	r4, [r1, #0]
	orrs	r0, r4
	b.n	.L04ea0
.L04e78:
	.4byte	0x04000100
.L04e7c:
	.4byte	SOUNDCNT_H
.L04e80:
	.4byte	0x0000fbff
.L04e84:
	.4byte	0x04000082
.L04e88:
	.4byte	timer
.L04e8c:
	.4byte	rate
.L04e90:
	.4byte	0x04000104
.L04e94:
	ldr	r2, .L04eb8
	str	r4, [r2, #0]
	ldr	r1, .L04ebc
	ldr	r0, .L04ec0
	ldrh	r4, [r1, #0]
	ands	r0, r4
.L04ea0:
	strh	r0, [r1, #0]
	ldr	r1, .L04ec4
	strh	r0, [r1, #0]
	negs	r0, r3
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [r2, #0]
.L04eae:
	pop	{r3}
	mov	r8, r3
	pop	{r4, r5, r6, r7}
	pop	{r0}
	bx	r0
.L04eb8:
	.4byte	0x04000100
.L04ebc:
	.4byte	SOUNDCNT_H
.L04ec0:
	.4byte	0x0000bfff
.L04ec4:
	.4byte	0x04000082

@ DigiRateAGB(mask, timer, reload): same with a raw reload value.
	.global	DigiRateAGB
	.thumb_func
	.type	DigiRateAGB, %function
DigiRateAGB:
	push	{r4, r5, r6, lr}
	adds	r4, r0, #0
	adds	r5, r1, #0
	adds	r3, r2, #0
	movs	r0, #1
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L04f2a
	ldr	r2, .L04f00
	movs	r1, #1
	adds	r0, r5, #0
	ands	r0, r1
	strb	r0, [r2, #0]
	ldr	r1, .L04f04
	str	r3, [r1, #0]
	cmp	r0, #0
	beq.n	.L04f10
	ldr	r2, .L04f08
	movs	r0, #0
	str	r0, [r2, #0]
	ldr	r1, .L04f0c
	movs	r6, #128
	lsls	r6, r6, #3
	adds	r0, r6, #0
	ldrh	r6, [r1, #0]
	orrs	r0, r6
	b.n	.L04f1c
	movs	r0, r0
.L04f00:
	.4byte	timer
.L04f04:
	.4byte	rate
.L04f08:
	.4byte	0x04000104
.L04f0c:
	.4byte	SOUNDCNT_H
.L04f10:
	ldr	r2, .L04f58
	str	r0, [r2, #0]
	ldr	r1, .L04f5c
	ldr	r0, .L04f60
	ldrh	r6, [r1, #0]
	ands	r0, r6
.L04f1c:
	strh	r0, [r1, #0]
	ldr	r1, .L04f64
	strh	r0, [r1, #0]
	negs	r0, r3
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [r2, #0]
.L04f2a:
	movs	r0, #2
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L04f8e
	ldr	r2, .L04f68
	movs	r0, #1
	adds	r1, r5, #0
	ands	r1, r0
	strb	r1, [r2, #1]
	ldr	r0, .L04f6c
	str	r3, [r0, #4]
	cmp	r1, #0
	beq.n	.L04f74
	ldr	r2, .L04f70
	movs	r0, #0
	str	r0, [r2, #0]
	ldr	r1, .L04f5c
	movs	r4, #128
	lsls	r4, r4, #7
	adds	r0, r4, #0
	ldrh	r6, [r1, #0]
	orrs	r0, r6
	b.n	.L04f80
.L04f58:
	.4byte	0x04000100
.L04f5c:
	.4byte	SOUNDCNT_H
.L04f60:
	.4byte	0x0000fbff
.L04f64:
	.4byte	0x04000082
.L04f68:
	.4byte	timer
.L04f6c:
	.4byte	rate
.L04f70:
	.4byte	0x04000104
.L04f74:
	ldr	r2, .L04f94
	str	r1, [r2, #0]
	ldr	r1, .L04f98
	ldr	r0, .L04f9c
	ldrh	r4, [r1, #0]
	ands	r0, r4
.L04f80:
	strh	r0, [r1, #0]
	ldr	r1, .L04fa0
	strh	r0, [r1, #0]
	negs	r0, r3
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	str	r0, [r2, #0]
.L04f8e:
	pop	{r4, r5, r6}
	pop	{r0}
	bx	r0
.L04f94:
	.4byte	0x04000100
.L04f98:
	.4byte	SOUNDCNT_H
.L04f9c:
	.4byte	0x0000bfff
.L04fa0:
	.4byte	0x04000082

@ DigiPan(mask, pan 1=right 2=left 3=both): SOUNDCNT_H enable bits, 100% volume.
	.global	DigiPan
	.thumb_func
	.type	DigiPan, %function
DigiPan:
	push	{r4, r5, lr}
	adds	r5, r0, #0
	adds	r3, r1, #0
	movs	r0, #1
	ands	r0, r5
	ldr	r4, .L04ff4
	cmp	r0, #0
	beq.n	.L04fca
	ldr	r2, .L04ff8
	ldrh	r0, [r4, #0]
	ands	r2, r0
	movs	r1, #3
	adds	r0, r3, #0
	ands	r0, r1
	lsls	r0, r0, #8
	movs	r1, #4
	orrs	r0, r1
	orrs	r2, r0
	strh	r2, [r4, #0]
.L04fca:
	movs	r0, #2
	ands	r0, r5
	cmp	r0, #0
	beq.n	.L04fe6
	ldr	r2, .L04ffc
	ldrh	r0, [r4, #0]
	ands	r2, r0
	movs	r0, #3
	ands	r3, r0
	lsls	r0, r3, #12
	movs	r1, #8
	orrs	r0, r1
	orrs	r2, r0
	strh	r2, [r4, #0]
.L04fe6:
	ldr	r1, .L05000
	ldrh	r0, [r4, #0]
	strh	r0, [r1, #0]
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L04ff4:
	.4byte	SOUNDCNT_H
.L04ff8:
	.4byte	0x0000fcff
.L04ffc:
	.4byte	0x0000cfff
.L05000:
	.4byte	0x04000082

@ DigiStart(mask): FIFO reset, start timer(s) with the stored reload.
	.global	DigiStart
	.thumb_func
	.type	DigiStart, %function
DigiStart:
	push	{r4, r5, lr}
	adds	r4, r0, #0
	movs	r3, #1
	ands	r3, r4
	cmp	r3, #0
	beq.n	.L05020
	ldr	r2, .L05048
	ldr	r1, .L0504c
	movs	r5, #128
	lsls	r5, r5, #4
	adds	r0, r5, #0
	ldrh	r1, [r1, #0]
	orrs	r0, r1
	strh	r0, [r2, #0]
.L05020:
	movs	r0, #2
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L05038
	ldr	r2, .L05048
	ldr	r1, .L0504c
	movs	r5, #128
	lsls	r5, r5, #8
	adds	r0, r5, #0
	ldrh	r1, [r1, #0]
	orrs	r0, r1
	strh	r0, [r2, #0]
.L05038:
	cmp	r3, #0
	beq.n	.L0506c
	ldr	r0, .L05050
	ldrb	r0, [r0, #0]
	cmp	r0, #0
	beq.n	.L05058
	ldr	r2, .L05054
	b.n	.L0505a
.L05048:
	.4byte	0x04000082
.L0504c:
	.4byte	SOUNDCNT_H
.L05050:
	.4byte	timer
.L05054:
	.4byte	0x04000104
.L05058:
	ldr	r2, .L05080
.L0505a:
	ldr	r0, .L05084
	ldr	r0, [r0, #0]
	negs	r0, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	movs	r1, #128
	lsls	r1, r1, #16
	orrs	r0, r1
	str	r0, [r2, #0]
.L0506c:
	movs	r0, #2
	ands	r0, r4
	cmp	r0, #0
	beq.n	.L050a4
	ldr	r0, .L05088
	ldrb	r0, [r0, #1]
	cmp	r0, #0
	beq.n	.L05090
	ldr	r2, .L0508c
	b.n	.L05092
.L05080:
	.4byte	0x04000100
.L05084:
	.4byte	rate
.L05088:
	.4byte	timer
.L0508c:
	.4byte	0x04000104
.L05090:
	ldr	r2, .L050ac
.L05092:
	ldr	r0, .L050b0
	ldr	r0, [r0, #4]
	negs	r0, r0
	lsls	r0, r0, #16
	lsrs	r0, r0, #16
	movs	r1, #128
	lsls	r1, r1, #16
	orrs	r0, r1
	str	r0, [r2, #0]
.L050a4:
	pop	{r4, r5}
	pop	{r0}
	bx	r0
	movs	r0, r0
.L050ac:
	.4byte	0x04000100
.L050b0:
	.4byte	rate

	.size	GBASS_GBTranspose, 104
	.size	DigiInit, 116
	.size	GBASS_ReverbMusicOff, 20
	.size	GBASS_OutputBufferRight, 28
	.size	GBASS_NoMusicMode, 40
	.size	GBASS_GetAudioMode, 12
	.size	DigiPan, 96
	.size	GBASS_Song_LoadState, 540
	.size	GBASS_MixerReset, 44
	.size	GBASS_SFX_VolumeStereo, 272
	.size	GBASS_SFX_Start, 12
	.size	GBASS_ReverbClear, 16
	.size	GBASS_Song_Transpose, 36
	.size	GBASS_SFX_Volume, 168
	.size	GBASS_PlayerStatusReset, 16
	.size	DigiReSeekStereo, 280
	.size	GBASS_AudioRateDivide, 312
	.size	GBASS_SFX_IsActive, 112
	.size	GBASS_SFX_Pitch, 208
	.size	DigiSeek, 244
	.size	GBASS_DMACriticalProcess, 52
	.size	GBASS_Song_Play, 212
	.size	GBASS_SFX_Restart, 16
	.size	GBASS_GetAudioRate, 12
	.size	GBASS_SFX_RestartStereo, 462
	.size	GBASS_Song_Time, 12
	.size	GBASS_Reset_GBCChannel, 132
	.size	GBASS_PlayerReset, 56
	.size	DigiReSeek, 364
	.size	GBASS_Song_Title, 38
	.size	GBASS_Reset_GBC, 136
	.size	GBASS_Process_Digital, 3522
	.size	GBASS_SFX_StartChnlReuse, 658
	.size	GBASS_ScriptPtrReset, 24
	.size	GBASS_OutputBufferLeft, 24
	.size	GBASS_SilentMix, 94
	.size	GBASS_GetNewSFXID, 156
	.size	GBASS_SFX_StartReuse, 774
	.size	GBASS_DigiTranspose, 96
	.size	DigiStop, 192
	.size	DigiStart, 176
	.size	GBASS_SFX_Release, 204
	.size	GBASS_Song_Stop, 136
	.size	GBASS_ReverbMusicMode, 84
	.size	GBASS_SFX_StopAll, 204
	.size	GBASS_Reset, 236
	.size	DigiRate, 252
	.size	GBASS_Resume, 120
	.size	DigiDMA, 64
	.size	GBASS_ReverbMusicOn, 44
	.size	GBASS_Init, 404
	.size	GBASS_PlayerChannelOrderSet, 64
	.size	GBASS_HeadPhoneMode, 40
	.size	GBASS_PlayerChannelMusicStop, 74
	.size	GBASS_SFX_Stop, 256
	.size	DigiRateAGB, 220
	.size	GBASS_AudioMode, 130
	.size	GBASS_Process_GB, 4556
	.size	GBASS_SFX_StartStereo, 292
	.size	GBASS_Song_SaveState, 388
	.size	GBASS_Song_Speed, 12
	.size	GBASS_Suspend, 36
	.size	GBASS_SFX_StartChnl, 54
	.size	GBASS_SFX_MasterVolume, 108
	.size	GBASS_GetDefaultAudioRate, 12
	.size	GBASS_Process, 1964
	.size	GBASS_Song_MasterVolume, 132
	.size	GBASS_Song_SaveStateBufferSize, 16

	.section .rodata
	.align	2
@ sample rate (Hz) per audio rate 0..12 (1,2,4,8 used = 64,128,256,512 samples/frame)
	.global	gbass_mixingrates
	.type	gbass_mixingrates, %object
gbass_mixingrates:
	.4byte	0, 3830, 7660, 11500, 15340, 19170, 23000, 26800, 30610, 34450, 38300, 38300, 45964
@ gb_notes[192]: 131072/f for octave 5, 1/16-semitone steps (GB reg = 2048 - value)
	.global	gb_notes
	.type	gb_notes, %object
gb_notes:
	.2byte	500, 499, 497, 495, 493, 492, 490, 488, 486, 484, 483, 481, 479, 478, 476, 474	@ C
	.2byte	472, 471, 469, 467, 466, 464, 462, 461, 459, 457, 456, 454, 452, 451, 449, 447	@ C#
	.2byte	446, 444, 443, 441, 439, 438, 436, 435, 433, 432, 430, 428, 427, 425, 424, 422	@ D
	.2byte	421, 419, 418, 416, 415, 413, 412, 410, 409, 407, 406, 404, 403, 401, 400, 399	@ D#
	.2byte	397, 396, 394, 393, 391, 390, 389, 387, 386, 384, 383, 382, 380, 379, 378, 376	@ E
	.2byte	375, 373, 372, 371, 369, 368, 367, 365, 364, 363, 362, 360, 359, 358, 356, 355	@ F
	.2byte	354, 352, 351, 350, 349, 347, 346, 345, 344, 342, 341, 340, 339, 338, 336, 335	@ F#
	.2byte	334, 333, 331, 330, 329, 328, 327, 326, 324, 323, 322, 321, 320, 319, 317, 316	@ G
	.2byte	315, 314, 313, 312, 311, 309, 308, 307, 306, 305, 304, 303, 302, 301, 300, 298	@ G#
	.2byte	297, 296, 295, 294, 293, 292, 291, 290, 289, 288, 287, 286, 285, 284, 283, 282	@ A
	.2byte	281, 280, 279, 278, 277, 276, 275, 274, 273, 272, 271, 270, 269, 268, 267, 266	@ A#
	.2byte	265, 264, 263, 262, 261, 260, 259, 258, 257, 256, 255, 255, 254, 253, 252, 251	@ B
@ digi_notes[192]: 65536 * 2^(n/192) -- octave 5 plays a wave at its own rate
	.global	digi_notes
	.type	digi_notes, %object
digi_notes:
	.4byte	0x10000, 0x100ed, 0x101da, 0x102c9, 0x103b9, 0x104a9, 0x1059b, 0x1068d, 0x10780, 0x10874, 0x10969, 0x10a5e, 0x10b55, 0x10c4d, 0x10d45, 0x10e3e	@ C
	.4byte	0x10f38, 0x11034, 0x11130, 0x1122d, 0x1132a, 0x11429, 0x11529, 0x11629, 0x1172b, 0x1182d, 0x11931, 0x11a35, 0x11b3b, 0x11c41, 0x11d48, 0x11e50	@ C#
	.4byte	0x11f59, 0x12063, 0x1216e, 0x1227a, 0x12387, 0x12495, 0x125a4, 0x126b4, 0x127c5, 0x128d7, 0x129e9, 0x12afd, 0x12c12, 0x12d28, 0x12e3f, 0x12f57	@ D
	.4byte	0x1306f, 0x13189, 0x132a4, 0x133c0, 0x134dd, 0x135fb, 0x1371a, 0x1383a, 0x1395b, 0x13a7d, 0x13ba0, 0x13cc5, 0x13dea, 0x13f10, 0x14038, 0x14160	@ D#
	.4byte	0x1428a, 0x143b4, 0x144e0, 0x1460d, 0x1473b, 0x1486a, 0x1499a, 0x14acb, 0x14bfd, 0x14d31, 0x14e65, 0x14f9b, 0x150d1, 0x15209, 0x15342, 0x1547c	@ E
	.4byte	0x155b8, 0x156f4, 0x15831, 0x15970, 0x15ab0, 0x15bf1, 0x15d33, 0x15e76, 0x15fbb, 0x16101, 0x16247, 0x1638f, 0x164d9, 0x16623, 0x1676f, 0x168bb	@ F
	.4byte	0x16a09, 0x16b59, 0x16ca9, 0x16dfb, 0x16f4d, 0x170a2, 0x171f7, 0x1734d, 0x174a5, 0x175fe, 0x17758, 0x178b4, 0x17a11, 0x17b6f, 0x17cce, 0x17e2f	@ F#
	.4byte	0x17f91, 0x180f4, 0x18258, 0x183be, 0x18525, 0x1868d, 0x187f7, 0x18962, 0x18ace, 0x18c3b, 0x18daa, 0x18f1a, 0x1908c, 0x191ff, 0x19373, 0x194e9	@ G
	.4byte	0x1965f, 0x197d8, 0x19951, 0x19acc, 0x19c49, 0x19dc6, 0x19f45, 0x1a0c6, 0x1a248, 0x1a3cb, 0x1a550, 0x1a6d6, 0x1a85d, 0x1a9e6, 0x1ab71, 0x1acfc	@ G#
	.4byte	0x1ae89, 0x1b018, 0x1b1a8, 0x1b33a, 0x1b4cd, 0x1b661, 0x1b7f7, 0x1b98e, 0x1bb27, 0x1bcc1, 0x1be5d, 0x1bffa, 0x1c199, 0x1c33a, 0x1c4db, 0x1c67f	@ A
	.4byte	0x1c823, 0x1c9ca, 0x1cb72, 0x1cd1b, 0x1cec6, 0x1d072, 0x1d220, 0x1d3d0, 0x1d581, 0x1d734, 0x1d8e8, 0x1da9e, 0x1dc55, 0x1de0e, 0x1dfc9, 0x1e185	@ A#
	.4byte	0x1e343, 0x1e502, 0x1e6c3, 0x1e886, 0x1ea4a, 0x1ec10, 0x1edd8, 0x1efa1, 0x1f16c, 0x1f339, 0x1f507, 0x1f6d7, 0x1f8a8, 0x1fa7c, 0x1fc51, 0x1fe27	@ B
@ vibrato_table[64]: s8 sine, 127 * sin(2 pi i / 64)
	.global	vibrato_table
	.type	vibrato_table, %object
vibrato_table:
	.byte	0, 12, 24, 36, 48, 59, 70, 80, 89, 98, 105, 112, 117, 121, 124, 126
	.byte	127, 126, 124, 121, 117, 112, 105, 98, 89, 80, 70, 59, 48, 36, 24, 12
	.byte	0, -12, -24, -36, -48, -59, -70, -80, -89, -98, -105, -112, -117, -121, -124, -126
	.byte	-127, -126, -124, -121, -117, -112, -105, -98, -89, -80, -70, -59, -48, -36, -24, -12
@ wavevibrato_table[64]: u8 raised cosine 0..255 (wave sweep, command 89)
	.global	wavevibrato_table
	.type	wavevibrato_table, %object
wavevibrato_table:
	.byte	0, 1, 3, 6, 10, 15, 22, 29, 38, 47, 57, 68, 79, 91, 103, 115
	.byte	127, 139, 151, 163, 175, 186, 197, 207, 216, 225, 232, 239, 244, 248, 251, 253
	.byte	254, 253, 251, 248, 244, 239, 232, 225, 216, 207, 197, 186, 175, 163, 151, 139
	.byte	127, 115, 103, 91, 79, 68, 57, 47, 38, 29, 22, 15, 10, 6, 3, 1
	.size	wavevibrato_table, 64
	.size	digi_notes, 768
	.size	gb_notes, 384
	.size	gbass_mixingrates, 52
	.size	vibrato_table, 64

	.data
	.align	2
	.global	"gbass_Wave$$leadstrings_high"
	.type	"gbass_Wave$$leadstrings_high", %object
"gbass_Wave$$leadstrings_high":
	.global	"gbass_Wave$$0"
	.type	"gbass_Wave$$0", %object
"gbass_Wave$$0":
	.incbin	"gbass_wavedata.bin", 0x0, 0x4deb
	.global	"gbass_Wave$$leadstrings_med"
	.type	"gbass_Wave$$leadstrings_med", %object
"gbass_Wave$$leadstrings_med":
	.global	"gbass_Wave$$1"
	.type	"gbass_Wave$$1", %object
"gbass_Wave$$1":
	.incbin	"gbass_wavedata.bin", 0x4deb, 0x47f9
	.global	"gbass_Wave$$2"
	.type	"gbass_Wave$$2", %object
"gbass_Wave$$2":
	.global	"gbass_Wave$$marcato_high"
	.type	"gbass_Wave$$marcato_high", %object
"gbass_Wave$$marcato_high":
	.incbin	"gbass_wavedata.bin", 0x95e4, 0x2938
	.global	"gbass_Wave$$3"
	.type	"gbass_Wave$$3", %object
"gbass_Wave$$3":
	.global	"gbass_Wave$$marcato_med"
	.type	"gbass_Wave$$marcato_med", %object
"gbass_Wave$$marcato_med":
	.incbin	"gbass_wavedata.bin", 0xbf1c, 0x2938
	.global	"gbass_Wave$$4"
	.type	"gbass_Wave$$4", %object
"gbass_Wave$$4":
	.global	"gbass_Wave$$marcato_low"
	.type	"gbass_Wave$$marcato_low", %object
"gbass_Wave$$marcato_low":
	.incbin	"gbass_wavedata.bin", 0xe854, 0x2fa7
	.global	"gbass_Wave$$5"
	.type	"gbass_Wave$$5", %object
"gbass_Wave$$5":
	.global	"gbass_Wave$$padstrings_med"
	.type	"gbass_Wave$$padstrings_med", %object
"gbass_Wave$$padstrings_med":
	.incbin	"gbass_wavedata.bin", 0x117fb, 0x733c
	.global	"gbass_Wave$$6"
	.type	"gbass_Wave$$6", %object
"gbass_Wave$$6":
	.global	"gbass_Wave$$padstrings_low"
	.type	"gbass_Wave$$padstrings_low", %object
"gbass_Wave$$padstrings_low":
	.incbin	"gbass_wavedata.bin", 0x18b37, 0x6629
	.global	"gbass_Wave$$7"
	.type	"gbass_Wave$$7", %object
"gbass_Wave$$7":
	.global	"gbass_Wave$$pizz_high"
	.type	"gbass_Wave$$pizz_high", %object
"gbass_Wave$$pizz_high":
	.incbin	"gbass_wavedata.bin", 0x1f160, 0x169c
	.global	"gbass_Wave$$pizz_medium"
	.type	"gbass_Wave$$pizz_medium", %object
"gbass_Wave$$pizz_medium":
	.global	"gbass_Wave$$8"
	.type	"gbass_Wave$$8", %object
"gbass_Wave$$8":
	.incbin	"gbass_wavedata.bin", 0x207fc, 0x12b8
	.global	"gbass_Wave$$9"
	.type	"gbass_Wave$$9", %object
"gbass_Wave$$9":
	.global	"gbass_Wave$$pizz_low"
	.type	"gbass_Wave$$pizz_low", %object
"gbass_Wave$$pizz_low":
	.incbin	"gbass_wavedata.bin", 0x21ab4, 0x1dea
	.global	"gbass_Wave$$trumpet_high"
	.type	"gbass_Wave$$trumpet_high", %object
"gbass_Wave$$trumpet_high":
	.global	"gbass_Wave$$A"
	.type	"gbass_Wave$$A", %object
"gbass_Wave$$A":
	.incbin	"gbass_wavedata.bin", 0x2389e, 0xffd
	.global	"gbass_Wave$$trumpet_low"
	.type	"gbass_Wave$$trumpet_low", %object
"gbass_Wave$$trumpet_low":
	.global	"gbass_Wave$$B"
	.type	"gbass_Wave$$B", %object
"gbass_Wave$$B":
	.incbin	"gbass_wavedata.bin", 0x2489b, 0x1b60
	.global	"gbass_Wave$$trombone"
	.type	"gbass_Wave$$trombone", %object
"gbass_Wave$$trombone":
	.global	"gbass_Wave$$C"
	.type	"gbass_Wave$$C", %object
"gbass_Wave$$C":
	.incbin	"gbass_wavedata.bin", 0x263fb, 0xe39
	.global	"gbass_Wave$$D"
	.type	"gbass_Wave$$D", %object
"gbass_Wave$$D":
	.global	"gbass_Wave$$tuba"
	.type	"gbass_Wave$$tuba", %object
"gbass_Wave$$tuba":
	.incbin	"gbass_wavedata.bin", 0x27234, 0x18cb
	.global	"gbass_Wave$$flute_high"
	.type	"gbass_Wave$$flute_high", %object
"gbass_Wave$$flute_high":
	.global	"gbass_Wave$$E"
	.type	"gbass_Wave$$E", %object
"gbass_Wave$$E":
	.incbin	"gbass_wavedata.bin", 0x28aff, 0x333a
	.global	"gbass_Wave$$F"
	.type	"gbass_Wave$$F", %object
"gbass_Wave$$F":
	.global	"gbass_Wave$$flute_med"
	.type	"gbass_Wave$$flute_med", %object
"gbass_Wave$$flute_med":
	.incbin	"gbass_wavedata.bin", 0x2be39, 0x4178
	.global	"gbass_Wave$$oboe"
	.type	"gbass_Wave$$oboe", %object
"gbass_Wave$$oboe":
	.global	"gbass_Wave$$10"
	.type	"gbass_Wave$$10", %object
"gbass_Wave$$10":
	.incbin	"gbass_wavedata.bin", 0x2ffb1, 0x2d0c
	.global	"gbass_Wave$$11"
	.type	"gbass_Wave$$11", %object
"gbass_Wave$$11":
	.global	"gbass_Wave$$clarinet"
	.type	"gbass_Wave$$clarinet", %object
"gbass_Wave$$clarinet":
	.incbin	"gbass_wavedata.bin", 0x32cbd, 0x224e
	.global	"gbass_Wave$$12"
	.type	"gbass_Wave$$12", %object
"gbass_Wave$$12":
	.global	"gbass_Wave$$bassoon"
	.type	"gbass_Wave$$bassoon", %object
"gbass_Wave$$bassoon":
	.incbin	"gbass_wavedata.bin", 0x34f0b, 0x15be
	.global	"gbass_Wave$$accordion"
	.type	"gbass_Wave$$accordion", %object
"gbass_Wave$$accordion":
	.global	"gbass_Wave$$13"
	.type	"gbass_Wave$$13", %object
"gbass_Wave$$13":
	.incbin	"gbass_wavedata.bin", 0x364c9, 0x17fa
	.global	"gbass_Wave$$bottleblow"
	.type	"gbass_Wave$$bottleblow", %object
"gbass_Wave$$bottleblow":
	.global	"gbass_Wave$$14"
	.type	"gbass_Wave$$14", %object
"gbass_Wave$$14":
	.incbin	"gbass_wavedata.bin", 0x37cc3, 0x15b2
	.global	"gbass_Wave$$15"
	.type	"gbass_Wave$$15", %object
"gbass_Wave$$15":
	.global	"gbass_Wave$$piano_5"
	.type	"gbass_Wave$$piano_5", %object
"gbass_Wave$$piano_5":
	.incbin	"gbass_wavedata.bin", 0x39275, 0x203d
	.global	"gbass_Wave$$16"
	.type	"gbass_Wave$$16", %object
"gbass_Wave$$16":
	.global	"gbass_Wave$$piano_3"
	.type	"gbass_Wave$$piano_3", %object
"gbass_Wave$$piano_3":
	.incbin	"gbass_wavedata.bin", 0x3b2b2, 0x3e08
	.global	"gbass_Wave$$17"
	.type	"gbass_Wave$$17", %object
"gbass_Wave$$17":
	.global	"gbass_Wave$$rhodes"
	.type	"gbass_Wave$$rhodes", %object
"gbass_Wave$$rhodes":
	.incbin	"gbass_wavedata.bin", 0x3f0ba, 0x2d79
	.global	"gbass_Wave$$18"
	.type	"gbass_Wave$$18", %object
"gbass_Wave$$18":
	.global	"gbass_Wave$$harp"
	.type	"gbass_Wave$$harp", %object
"gbass_Wave$$harp":
	.incbin	"gbass_wavedata.bin", 0x41e33, 0x1006
	.global	"gbass_Wave$$19"
	.type	"gbass_Wave$$19", %object
"gbass_Wave$$19":
	.global	"gbass_Wave$$guitar_high"
	.type	"gbass_Wave$$guitar_high", %object
"gbass_Wave$$guitar_high":
	.incbin	"gbass_wavedata.bin", 0x42e39, 0x463d
	.global	"gbass_Wave$$1A"
	.type	"gbass_Wave$$1A", %object
"gbass_Wave$$1A":
	.global	"gbass_Wave$$guitar_med"
	.type	"gbass_Wave$$guitar_med", %object
"gbass_Wave$$guitar_med":
	.incbin	"gbass_wavedata.bin", 0x47476, 0x44fb
	.global	"gbass_Wave$$guitar_nylon"
	.type	"gbass_Wave$$guitar_nylon", %object
"gbass_Wave$$guitar_nylon":
	.global	"gbass_Wave$$1B"
	.type	"gbass_Wave$$1B", %object
"gbass_Wave$$1B":
	.incbin	"gbass_wavedata.bin", 0x4b971, 0x26fc
	.global	"gbass_Wave$$1C"
	.type	"gbass_Wave$$1C", %object
"gbass_Wave$$1C":
	.global	"gbass_Wave$$bass_acoustic"
	.type	"gbass_Wave$$bass_acoustic", %object
"gbass_Wave$$bass_acoustic":
	.incbin	"gbass_wavedata.bin", 0x4e06d, 0x1c63
	.global	"gbass_Wave$$bass_finger"
	.type	"gbass_Wave$$bass_finger", %object
"gbass_Wave$$bass_finger":
	.global	"gbass_Wave$$1D"
	.type	"gbass_Wave$$1D", %object
"gbass_Wave$$1D":
	.incbin	"gbass_wavedata.bin", 0x4fcd0, 0x2191
	.global	"gbass_Wave$$vibes"
	.type	"gbass_Wave$$vibes", %object
"gbass_Wave$$vibes":
	.global	"gbass_Wave$$1E"
	.type	"gbass_Wave$$1E", %object
"gbass_Wave$$1E":
	.incbin	"gbass_wavedata.bin", 0x51e61, 0xdeb
	.global	"gbass_Wave$$1F"
	.type	"gbass_Wave$$1F", %object
"gbass_Wave$$1F":
	.global	"gbass_Wave$$celesta"
	.type	"gbass_Wave$$celesta", %object
"gbass_Wave$$celesta":
	.incbin	"gbass_wavedata.bin", 0x52c4c, 0x2482
	.global	"gbass_Wave$$glock"
	.type	"gbass_Wave$$glock", %object
"gbass_Wave$$glock":
	.global	"gbass_Wave$$20"
	.type	"gbass_Wave$$20", %object
"gbass_Wave$$20":
	.incbin	"gbass_wavedata.bin", 0x550ce, 0xc80
	.global	"gbass_Wave$$21"
	.type	"gbass_Wave$$21", %object
"gbass_Wave$$21":
	.global	"gbass_Wave$$marimba"
	.type	"gbass_Wave$$marimba", %object
"gbass_Wave$$marimba":
	.incbin	"gbass_wavedata.bin", 0x55d4e, 0x1180
	.global	"gbass_Wave$$22"
	.type	"gbass_Wave$$22", %object
"gbass_Wave$$22":
	.global	"gbass_Wave$$xylophone"
	.type	"gbass_Wave$$xylophone", %object
"gbass_Wave$$xylophone":
	.incbin	"gbass_wavedata.bin", 0x56ece, 0x2200
	.global	"gbass_Wave$$23"
	.type	"gbass_Wave$$23", %object
"gbass_Wave$$23":
	.global	"gbass_Wave$$conga_high"
	.type	"gbass_Wave$$conga_high", %object
"gbass_Wave$$conga_high":
	.incbin	"gbass_wavedata.bin", 0x590ce, 0xe16
	.global	"gbass_Wave$$24"
	.type	"gbass_Wave$$24", %object
"gbass_Wave$$24":
	.global	"gbass_Wave$$conga_low"
	.type	"gbass_Wave$$conga_low", %object
"gbass_Wave$$conga_low":
	.incbin	"gbass_wavedata.bin", 0x59ee4, 0x1aea
	.global	"gbass_Wave$$25"
	.type	"gbass_Wave$$25", %object
"gbass_Wave$$25":
	.global	"gbass_Wave$$conga_slap"
	.type	"gbass_Wave$$conga_slap", %object
"gbass_Wave$$conga_slap":
	.incbin	"gbass_wavedata.bin", 0x5b9ce, 0xc38
	.global	"gbass_Wave$$26"
	.type	"gbass_Wave$$26", %object
"gbass_Wave$$26":
	.global	"gbass_Wave$$tom"
	.type	"gbass_Wave$$tom", %object
"gbass_Wave$$tom":
	.incbin	"gbass_wavedata.bin", 0x5c606, 0x26c0
	.global	"gbass_Wave$$maracas"
	.type	"gbass_Wave$$maracas", %object
"gbass_Wave$$maracas":
	.global	"gbass_Wave$$27"
	.type	"gbass_Wave$$27", %object
"gbass_Wave$$27":
	.incbin	"gbass_wavedata.bin", 0x5ecc6, 0x991
	.global	"gbass_Wave$$28"
	.type	"gbass_Wave$$28", %object
"gbass_Wave$$28":
	.global	"gbass_Wave$$shaker"
	.type	"gbass_Wave$$shaker", %object
"gbass_Wave$$shaker":
	.incbin	"gbass_wavedata.bin", 0x5f657, 0x8e0
	.global	"gbass_Wave$$triangle_open"
	.type	"gbass_Wave$$triangle_open", %object
"gbass_Wave$$triangle_open":
	.global	"gbass_Wave$$29"
	.type	"gbass_Wave$$29", %object
"gbass_Wave$$29":
	.incbin	"gbass_wavedata.bin", 0x5ff37, 0x3591
	.global	"gbass_Wave$$2A"
	.type	"gbass_Wave$$2A", %object
"gbass_Wave$$2A":
	.global	"gbass_Wave$$triangle_closed"
	.type	"gbass_Wave$$triangle_closed", %object
"gbass_Wave$$triangle_closed":
	.incbin	"gbass_wavedata.bin", 0x634c8, 0x2c8
	.global	"gbass_Wave$$2B"
	.type	"gbass_Wave$$2B", %object
"gbass_Wave$$2B":
	.global	"gbass_Wave$$timpani"
	.type	"gbass_Wave$$timpani", %object
"gbass_Wave$$timpani":
	.incbin	"gbass_wavedata.bin", 0x63790, 0x58b3
	.global	"gbass_Wave$$click"
	.type	"gbass_Wave$$click", %object
"gbass_Wave$$click":
	.global	"gbass_Wave$$2C"
	.type	"gbass_Wave$$2C", %object
"gbass_Wave$$2C":
	.incbin	"gbass_wavedata.bin", 0x69043, 0xdc8
	.global	"gbass_Wave$$cymbal_hit"
	.type	"gbass_Wave$$cymbal_hit", %object
"gbass_Wave$$cymbal_hit":
	.global	"gbass_Wave$$2D"
	.type	"gbass_Wave$$2D", %object
"gbass_Wave$$2D":
	.incbin	"gbass_wavedata.bin", 0x69e0b, 0x5200
	.global	"gbass_Wave$$2E"
	.type	"gbass_Wave$$2E", %object
"gbass_Wave$$2E":
	.global	"gbass_Wave$$arpeggiator1"
	.type	"gbass_Wave$$arpeggiator1", %object
"gbass_Wave$$arpeggiator1":
	.incbin	"gbass_wavedata.bin", 0x6f00b, 0x3001
	.global	"gbass_Wave$$2F"
	.type	"gbass_Wave$$2F", %object
"gbass_Wave$$2F":
	.global	"gbass_Wave$$gb3_bass"
	.type	"gbass_Wave$$gb3_bass", %object
"gbass_Wave$$gb3_bass":
	.incbin	"gbass_wavedata.bin", 0x7200c, 0x20
	.global	"gbass_Wave$$harpsilow"
	.type	"gbass_Wave$$harpsilow", %object
"gbass_Wave$$harpsilow":
	.global	"gbass_Wave$$30"
	.type	"gbass_Wave$$30", %object
"gbass_Wave$$30":
	.incbin	"gbass_wavedata.bin", 0x7202c, 0x38e8
	.global	"gbass_Wave$$harpsihigh"
	.type	"gbass_Wave$$harpsihigh", %object
"gbass_Wave$$harpsihigh":
	.global	"gbass_Wave$$31"
	.type	"gbass_Wave$$31", %object
"gbass_Wave$$31":
	.incbin	"gbass_wavedata.bin", 0x75914, 0x3b44
@ Wave (24 bytes): data (bit31 = tempo-synced), rate 16.16, start 16.16,
@   loop end 16.16, loop length 16.16 (0 = one-shot), release end 16.16
	.global	gbass_WaveTable
	.type	gbass_WaveTable, %object
gbass_WaveTable:
	.4byte	"gbass_Wave$$leadstrings_high"	@ wave 0
	.4byte	0x00010000, 0x00000000, 0x4dea0000, 0x31be0000, 0x4deb0000	@ rate 1.0000 start 0 end 19946 loop 12734 release 19947
	.4byte	"gbass_Wave$$leadstrings_med"	@ wave 1
	.4byte	0x00010000, 0x00000000, 0x47f90000, 0x354e0000, 0x47f90000	@ rate 1.0000 start 0 end 18425 loop 13646 release 18425
	.4byte	"gbass_Wave$$marcato_high"	@ wave 2
	.4byte	0x00010000, 0x00000000, 0x29380000, 0x00000000, 0x29380000	@ rate 1.0000 start 0 end 10552 loop 0 release 10552
	.4byte	"gbass_Wave$$marcato_med"	@ wave 3
	.4byte	0x00010000, 0x00000000, 0x29380000, 0x00000000, 0x29380000	@ rate 1.0000 start 0 end 10552 loop 0 release 10552
	.4byte	"gbass_Wave$$marcato_low"	@ wave 4
	.4byte	0x00010000, 0x00000000, 0x2fa70000, 0x00000000, 0x2fa70000	@ rate 1.0000 start 0 end 12199 loop 0 release 12199
	.4byte	"gbass_Wave$$padstrings_med"	@ wave 5
	.4byte	0x00010000, 0x00000000, 0x733c0000, 0x5eba0000, 0x733c0000	@ rate 1.0000 start 0 end 29500 loop 24250 release 29500
	.4byte	"gbass_Wave$$padstrings_low"	@ wave 6
	.4byte	0x00010000, 0x00000000, 0x66280000, 0x52ae0000, 0x66290000	@ rate 1.0000 start 0 end 26152 loop 21166 release 26153
	.4byte	"gbass_Wave$$pizz_high"	@ wave 7
	.4byte	0x00010000, 0x00000000, 0x169c0000, 0x00000000, 0x169c0000	@ rate 1.0000 start 0 end 5788 loop 0 release 5788
	.4byte	"gbass_Wave$$pizz_medium"	@ wave 8
	.4byte	0x00010000, 0x00000000, 0x12b80000, 0x00000000, 0x12b80000	@ rate 1.0000 start 0 end 4792 loop 0 release 4792
	.4byte	"gbass_Wave$$pizz_low"	@ wave 9
	.4byte	0x00010000, 0x00000000, 0x1dea0000, 0x00000000, 0x1dea0000	@ rate 1.0000 start 0 end 7658 loop 0 release 7658
	.4byte	"gbass_Wave$$trumpet_high"	@ wave 10
	.4byte	0x00010000, 0x00000000, 0x0ffd0000, 0x04200000, 0x0ffd0000	@ rate 1.0000 start 0 end 4093 loop 1056 release 4093
	.4byte	"gbass_Wave$$trumpet_low"	@ wave 11
	.4byte	0x00010000, 0x00000000, 0x1b600000, 0x08b40000, 0x1b600000	@ rate 1.0000 start 0 end 7008 loop 2228 release 7008
	.4byte	"gbass_Wave$$trombone"	@ wave 12
	.4byte	0x00010000, 0x00000000, 0x0e390000, 0x04200000, 0x0e390000	@ rate 1.0000 start 0 end 3641 loop 1056 release 3641
	.4byte	"gbass_Wave$$tuba"	@ wave 13
	.4byte	0x00010000, 0x00000000, 0x18cb0000, 0x04a90000, 0x18cb0000	@ rate 1.0000 start 0 end 6347 loop 1193 release 6347
	.4byte	"gbass_Wave$$flute_high"	@ wave 14
	.4byte	0x00010000, 0x00000000, 0x333a0000, 0x14370000, 0x333a0000	@ rate 1.0000 start 0 end 13114 loop 5175 release 13114
	.4byte	"gbass_Wave$$flute_med"	@ wave 15
	.4byte	0x00010000, 0x00000000, 0x41780000, 0x1ff30000, 0x41780000	@ rate 1.0000 start 0 end 16760 loop 8179 release 16760
	.4byte	"gbass_Wave$$oboe"	@ wave 16
	.4byte	0x00010000, 0x00000000, 0x2d0c0000, 0x0b1c0000, 0x2d0c0000	@ rate 1.0000 start 0 end 11532 loop 2844 release 11532
	.4byte	"gbass_Wave$$clarinet"	@ wave 17
	.4byte	0x00010000, 0x00000000, 0x224e0000, 0x050a0000, 0x224e0000	@ rate 1.0000 start 0 end 8782 loop 1290 release 8782
	.4byte	"gbass_Wave$$bassoon"	@ wave 18
	.4byte	0x00010000, 0x00000000, 0x15be0000, 0x092a0000, 0x15be0000	@ rate 1.0000 start 0 end 5566 loop 2346 release 5566
	.4byte	"gbass_Wave$$accordion"	@ wave 19
	.4byte	0x00010000, 0x00000000, 0x17fa0000, 0x0d840000, 0x17fa0000	@ rate 1.0000 start 0 end 6138 loop 3460 release 6138
	.4byte	"gbass_Wave$$bottleblow"	@ wave 20
	.4byte	0x00010000, 0x00000000, 0x15b20000, 0x0b910000, 0x15b20000	@ rate 1.0000 start 0 end 5554 loop 2961 release 5554
	.4byte	"gbass_Wave$$piano_5"	@ wave 21
	.4byte	0x00010000, 0x00000000, 0x203d0000, 0x135b0000, 0x203d0000	@ rate 1.0000 start 0 end 8253 loop 4955 release 8253
	.4byte	"gbass_Wave$$piano_3"	@ wave 22
	.4byte	0x00010000, 0x00000000, 0x3e080000, 0x13790000, 0x3e080000	@ rate 1.0000 start 0 end 15880 loop 4985 release 15880
	.4byte	"gbass_Wave$$rhodes"	@ wave 23
	.4byte	0x00010000, 0x00000000, 0x2d790000, 0x09640000, 0x2d790000	@ rate 1.0000 start 0 end 11641 loop 2404 release 11641
	.4byte	"gbass_Wave$$harp"	@ wave 24
	.4byte	0x00010000, 0x00000000, 0x10060000, 0x01d70000, 0x10060000	@ rate 1.0000 start 0 end 4102 loop 471 release 4102
	.4byte	"gbass_Wave$$guitar_high"	@ wave 25
	.4byte	0x00010000, 0x00000000, 0x463d0000, 0x12520000, 0x463d0000	@ rate 1.0000 start 0 end 17981 loop 4690 release 17981
	.4byte	"gbass_Wave$$guitar_med"	@ wave 26
	.4byte	0x00010000, 0x00000000, 0x44fb0000, 0x08b30000, 0x44fb0000	@ rate 1.0000 start 0 end 17659 loop 2227 release 17659
	.4byte	"gbass_Wave$$guitar_nylon"	@ wave 27
	.4byte	0x00010000, 0x00000000, 0x26fc0000, 0x071a0000, 0x26fc0000	@ rate 1.0000 start 0 end 9980 loop 1818 release 9980
	.4byte	"gbass_Wave$$bass_acoustic"	@ wave 28
	.4byte	0x00010000, 0x00000000, 0x1c630000, 0x0bea0000, 0x1c630000	@ rate 1.0000 start 0 end 7267 loop 3050 release 7267
	.4byte	"gbass_Wave$$bass_finger"	@ wave 29
	.4byte	0x00010000, 0x00000000, 0x21910000, 0x04950000, 0x21910000	@ rate 1.0000 start 0 end 8593 loop 1173 release 8593
	.4byte	"gbass_Wave$$vibes"	@ wave 30
	.4byte	0x00010000, 0x00000000, 0x0deb0000, 0x062f0000, 0x0deb0000	@ rate 1.0000 start 0 end 3563 loop 1583 release 3563
	.4byte	"gbass_Wave$$celesta"	@ wave 31
	.4byte	0x00010000, 0x00000000, 0x24820000, 0x12900000, 0x24820000	@ rate 1.0000 start 0 end 9346 loop 4752 release 9346
	.4byte	"gbass_Wave$$glock"	@ wave 32
	.4byte	0x00010000, 0x00000000, 0x0c7f0000, 0x09970000, 0x0c800000	@ rate 1.0000 start 0 end 3199 loop 2455 release 3200
	.4byte	"gbass_Wave$$marimba"	@ wave 33
	.4byte	0x00010000, 0x00000000, 0x11800000, 0x09290000, 0x11800000	@ rate 1.0000 start 0 end 4480 loop 2345 release 4480
	.4byte	"gbass_Wave$$xylophone"	@ wave 34
	.4byte	0x00010000, 0x00000000, 0x22000000, 0x00000000, 0x22000000	@ rate 1.0000 start 0 end 8704 loop 0 release 8704
	.4byte	"gbass_Wave$$conga_high"	@ wave 35
	.4byte	0x00010000, 0x00000000, 0x0e160000, 0x00000000, 0x0e160000	@ rate 1.0000 start 0 end 3606 loop 0 release 3606
	.4byte	"gbass_Wave$$conga_low"	@ wave 36
	.4byte	0x00010000, 0x00000000, 0x1aea0000, 0x00000000, 0x1aea0000	@ rate 1.0000 start 0 end 6890 loop 0 release 6890
	.4byte	"gbass_Wave$$conga_slap"	@ wave 37
	.4byte	0x00010000, 0x00000000, 0x0c380000, 0x00000000, 0x0c380000	@ rate 1.0000 start 0 end 3128 loop 0 release 3128
	.4byte	"gbass_Wave$$tom"	@ wave 38
	.4byte	0x00010000, 0x00000000, 0x26c00000, 0x00000000, 0x26c00000	@ rate 1.0000 start 0 end 9920 loop 0 release 9920
	.4byte	"gbass_Wave$$maracas"	@ wave 39
	.4byte	0x00010000, 0x00000000, 0x09910000, 0x00000000, 0x09910000	@ rate 1.0000 start 0 end 2449 loop 0 release 2449
	.4byte	"gbass_Wave$$shaker"	@ wave 40
	.4byte	0x00010000, 0x00000000, 0x08e00000, 0x00000000, 0x08e00000	@ rate 1.0000 start 0 end 2272 loop 0 release 2272
	.4byte	"gbass_Wave$$triangle_open"	@ wave 41
	.4byte	0x00010000, 0x00000000, 0x35910000, 0x00000000, 0x35910000	@ rate 1.0000 start 0 end 13713 loop 0 release 13713
	.4byte	"gbass_Wave$$triangle_closed"	@ wave 42
	.4byte	0x00010000, 0x00000000, 0x02c80000, 0x00000000, 0x02c80000	@ rate 1.0000 start 0 end 712 loop 0 release 712
	.4byte	"gbass_Wave$$timpani"	@ wave 43
	.4byte	0x00010000, 0x00000000, 0x58b30000, 0x00000000, 0x58b30000	@ rate 1.0000 start 0 end 22707 loop 0 release 22707
	.4byte	"gbass_Wave$$click"	@ wave 44
	.4byte	0x00010000, 0x00000000, 0x0dc80000, 0x00000000, 0x0dc80000	@ rate 1.0000 start 0 end 3528 loop 0 release 3528
	.4byte	"gbass_Wave$$cymbal_hit"	@ wave 45
	.4byte	0x00010000, 0x00000000, 0x52000000, 0x00000000, 0x52000000	@ rate 1.0000 start 0 end 20992 loop 0 release 20992
	.4byte	"gbass_Wave$$arpeggiator1"	@ wave 46
	.4byte	0x00010000, 0x00000000, 0x30010000, 0x00000000, 0x30010000	@ rate 1.0000 start 0 end 12289 loop 0 release 12289
	.4byte	"gbass_Wave$$gb3_bass"	@ wave 47
	.4byte	0x00010000, 0x00000000, 0x00200000, 0x00000000, 0x00200000	@ rate 1.0000 start 0 end 32 loop 0 release 32
	.4byte	"gbass_Wave$$harpsilow"	@ wave 48
	.4byte	0x0001096a, 0x00000000, 0x38e80000, 0x03d20000, 0x38e80000	@ rate 1.0368 start 0 end 14568 loop 978 release 14568
	.4byte	"gbass_Wave$$harpsihigh"	@ wave 49
	.4byte	0x0001096a, 0x00000000, 0x3b410000, 0x089a0000, 0x3b410000	@ rate 1.0368 start 0 end 15169 loop 2202 release 15169
	.global	gbass_InstrumentTable
	.type	gbass_InstrumentTable, %object
gbass_InstrumentTable:
	.4byte	"gbass_Inst$$0"	@ instrument 0
	.4byte	"gbass_Inst$$1"	@ instrument 1
	.4byte	"gbass_Inst$$2"	@ instrument 2
	.4byte	"gbass_Inst$$3"	@ instrument 3
	.4byte	"gbass_Inst$$4"	@ instrument 4
	.4byte	"gbass_Inst$$5"	@ instrument 5
	.4byte	"gbass_Inst$$6"	@ instrument 6
	.4byte	"gbass_Inst$$7"	@ instrument 7
	.4byte	"gbass_Inst$$8"	@ instrument 8
	.4byte	"gbass_Inst$$9"	@ instrument 9
	.4byte	"gbass_Inst$$A"	@ instrument 10
	.4byte	"gbass_Inst$$B"	@ instrument 11
	.4byte	"gbass_Inst$$C"	@ instrument 12
	.4byte	"gbass_Inst$$D"	@ instrument 13
	.4byte	"gbass_Inst$$E"	@ instrument 14
	.4byte	"gbass_Inst$$11"	@ instrument 15
	.4byte	"gbass_Inst$$15"	@ instrument 16
	.4byte	"gbass_Inst$$16"	@ instrument 17
	.4byte	"gbass_Inst$$17"	@ instrument 18
	.4byte	"gbass_Inst$$19"	@ instrument 19
	.4byte	"gbass_Inst$$1B"	@ instrument 20
	.4byte	"gbass_Inst$$1D"	@ instrument 21
	.4byte	"gbass_Inst$$1E"	@ instrument 22
	.4byte	"gbass_Inst$$22"	@ instrument 23
	.4byte	"gbass_Inst$$24"	@ instrument 24
	.4byte	"gbass_Inst$$26"	@ instrument 25
	.4byte	"gbass_Inst$$27"	@ instrument 26
	.4byte	"gbass_Inst$$29"	@ instrument 27
	.4byte	"gbass_Inst$$2A"	@ instrument 28
	.4byte	"gbass_Inst$$2B"	@ instrument 29
	.4byte	"gbass_Inst$$2C"	@ instrument 30
	.4byte	"gbass_Inst$$2D"	@ instrument 31
	.4byte	"gbass_Inst$$2F"	@ instrument 32
	.4byte	"gbass_Inst$$30"	@ instrument 33
	.4byte	"gbass_Inst$$31"	@ instrument 34
	.4byte	"gbass_Inst$$32"	@ instrument 35
	.4byte	"gbass_Inst$$34"	@ instrument 36
	.4byte	"gbass_Inst$$35"	@ instrument 37
	.4byte	"gbass_Inst$$36"	@ instrument 38
	.4byte	"gbass_Inst$$37"	@ instrument 39
	.4byte	"gbass_Inst$$39"	@ instrument 40
	.4byte	"gbass_Inst$$3C"	@ instrument 41
	.4byte	"gbass_Inst$$3D"	@ instrument 42
	.4byte	"gbass_Inst$$3E"	@ instrument 43
	.4byte	"gbass_Inst$$3F"	@ instrument 44
	.4byte	"gbass_Inst$$41"	@ instrument 45
	.4byte	"gbass_Inst$$44"	@ instrument 46
	.4byte	"gbass_Inst$$46"	@ instrument 47
	.4byte	"gbass_Inst$$47"	@ instrument 48
	.4byte	"gbass_Inst$$48"	@ instrument 49
	.4byte	"gbass_Inst$$49"	@ instrument 50
	.4byte	"gbass_Inst$$4A"	@ instrument 51
	.4byte	"gbass_Inst$$4B"	@ instrument 52
	.4byte	"gbass_Inst$$4C"	@ instrument 53
	.4byte	"gbass_Inst$$4D"	@ instrument 54
	.4byte	"gbass_Inst$$4E"	@ instrument 55
	.4byte	"gbass_Inst$$4F"	@ instrument 56
	.4byte	"gbass_Inst$$50"	@ instrument 57
	.4byte	"gbass_Inst$$51"	@ instrument 58
@ instrument type: 0-3 = GB channel 1-4 (PSG), 4 = digital
	.global	gbass_InstrumentTypeTable
	.type	gbass_InstrumentTypeTable, %object
gbass_InstrumentTypeTable:
	.byte	4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4	@ 0-15
	.byte	4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4	@ 16-31
	.byte	4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4	@ 32-47
	.byte	4,1,1,1,1,1,1,3,3,3,2	@ 48-58
	.global	"gbass_Inst$$0"
	.type	"gbass_Inst$$0", %object
"gbass_Inst$$0":
	.global	"gbass_Inst$$leadstrings_med"
	.type	"gbass_Inst$$leadstrings_med", %object
"gbass_Inst$$leadstrings_med":
	.byte	0x31	@ wave 1
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$0$$$kwak"
	.type	"gbass_Inst$$0$$$kwak", %object
"gbass_Inst$$0$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$0$$$kwak
	.4byte	"gbass_Inst$$0$$$kwak"
	.byte	0x86,0xec	@ volslide -20
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$leadstrings_high"
	.type	"gbass_Inst$$leadstrings_high", %object
"gbass_Inst$$leadstrings_high":
	.global	"gbass_Inst$$1"
	.type	"gbass_Inst$$1", %object
"gbass_Inst$$1":
	.byte	0x30	@ wave 0
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$1$$$kwak"
	.type	"gbass_Inst$$1$$$kwak", %object
"gbass_Inst$$1$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$1$$$kwak
	.4byte	"gbass_Inst$$1$$$kwak"
	.byte	0x86,0xec	@ volslide -20
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$marcato_low"
	.type	"gbass_Inst$$marcato_low", %object
"gbass_Inst$$marcato_low":
	.global	"gbass_Inst$$2"
	.type	"gbass_Inst$$2", %object
"gbass_Inst$$2":
	.byte	0x34	@ wave 4
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$3"
	.type	"gbass_Inst$$3", %object
"gbass_Inst$$3":
	.global	"gbass_Inst$$marcato_med"
	.type	"gbass_Inst$$marcato_med", %object
"gbass_Inst$$marcato_med":
	.byte	0x33	@ wave 3
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$marcato_high"
	.type	"gbass_Inst$$marcato_high", %object
"gbass_Inst$$marcato_high":
	.global	"gbass_Inst$$4"
	.type	"gbass_Inst$$4", %object
"gbass_Inst$$4":
	.byte	0x32	@ wave 2
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$padstrings_low"
	.type	"gbass_Inst$$padstrings_low", %object
"gbass_Inst$$padstrings_low":
	.global	"gbass_Inst$$5"
	.type	"gbass_Inst$$5", %object
"gbass_Inst$$5":
	.byte	0x36	@ wave 6
	.byte	0x71,0x40	@ vol 64
	.byte	0x86,0x0a	@ volslide 10
	.global	"gbass_Inst$$5$$$kwak"
	.type	"gbass_Inst$$5$$$kwak", %object
"gbass_Inst$$5$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$5$$$kwak
	.4byte	"gbass_Inst$$5$$$kwak"
	.byte	0x86,0xec	@ volslide -20
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$6"
	.type	"gbass_Inst$$6", %object
"gbass_Inst$$6":
	.global	"gbass_Inst$$padstrings_med"
	.type	"gbass_Inst$$padstrings_med", %object
"gbass_Inst$$padstrings_med":
	.byte	0x35	@ wave 5
	.byte	0x71,0x40	@ vol 64
	.byte	0x86,0x08	@ volslide 8
	.global	"gbass_Inst$$6$$$kwak"
	.type	"gbass_Inst$$6$$$kwak", %object
"gbass_Inst$$6$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$6$$$kwak
	.4byte	"gbass_Inst$$6$$$kwak"
	.byte	0x86,0xec	@ volslide -20
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$pizz_low"
	.type	"gbass_Inst$$pizz_low", %object
"gbass_Inst$$pizz_low":
	.global	"gbass_Inst$$7"
	.type	"gbass_Inst$$7", %object
"gbass_Inst$$7":
	.byte	0x39	@ wave 9
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$8"
	.type	"gbass_Inst$$8", %object
"gbass_Inst$$8":
	.global	"gbass_Inst$$pizz_med"
	.type	"gbass_Inst$$pizz_med", %object
"gbass_Inst$$pizz_med":
	.byte	0x38	@ wave 8
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$pizz_high"
	.type	"gbass_Inst$$pizz_high", %object
"gbass_Inst$$pizz_high":
	.global	"gbass_Inst$$9"
	.type	"gbass_Inst$$9", %object
"gbass_Inst$$9":
	.byte	0x37	@ wave 7
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$trumpet_low"
	.type	"gbass_Inst$$trumpet_low", %object
"gbass_Inst$$trumpet_low":
	.global	"gbass_Inst$$A"
	.type	"gbass_Inst$$A", %object
"gbass_Inst$$A":
	.byte	0x3b	@ wave 11
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$A$$$kwak"
	.type	"gbass_Inst$$A$$$kwak", %object
"gbass_Inst$$A$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$A$$$kwak
	.4byte	"gbass_Inst$$A$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$B"
	.type	"gbass_Inst$$B", %object
"gbass_Inst$$B":
	.global	"gbass_Inst$$trumpet_high"
	.type	"gbass_Inst$$trumpet_high", %object
"gbass_Inst$$trumpet_high":
	.byte	0x3a	@ wave 10
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$B$$$kwak"
	.type	"gbass_Inst$$B$$$kwak", %object
"gbass_Inst$$B$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$B$$$kwak
	.4byte	"gbass_Inst$$B$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$trombone"
	.type	"gbass_Inst$$trombone", %object
"gbass_Inst$$trombone":
	.global	"gbass_Inst$$C"
	.type	"gbass_Inst$$C", %object
"gbass_Inst$$C":
	.byte	0x3c	@ wave 12
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$C$$$kwak"
	.type	"gbass_Inst$$C$$$kwak", %object
"gbass_Inst$$C$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$C$$$kwak
	.4byte	"gbass_Inst$$C$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$D"
	.type	"gbass_Inst$$D", %object
"gbass_Inst$$D":
	.global	"gbass_Inst$$harpsilow"
	.type	"gbass_Inst$$harpsilow", %object
"gbass_Inst$$harpsilow":
	.byte	0x3f,0x30	@ wave 48
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfc	@ volslide -4
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$E"
	.type	"gbass_Inst$$E", %object
"gbass_Inst$$E":
	.global	"gbass_Inst$$harpsihigh"
	.type	"gbass_Inst$$harpsihigh", %object
"gbass_Inst$$harpsihigh":
	.byte	0x3f,0x31	@ wave 49
	.byte	0x71,0x90	@ vol 144
	.byte	0x86,0xfe	@ volslide -2
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$tuba"
	.type	"gbass_Inst$$tuba", %object
"gbass_Inst$$tuba":
	.global	"gbass_Inst$$11"
	.type	"gbass_Inst$$11", %object
"gbass_Inst$$11":
	.byte	0x3d	@ wave 13
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$11$$$kwak"
	.type	"gbass_Inst$$11$$$kwak", %object
"gbass_Inst$$11$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$11$$$kwak
	.4byte	"gbass_Inst$$11$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$15"
	.type	"gbass_Inst$$15", %object
"gbass_Inst$$15":
	.global	"gbass_Inst$$flute_med"
	.type	"gbass_Inst$$flute_med", %object
"gbass_Inst$$flute_med":
	.byte	0x3f,0x0f	@ wave 15
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$15$$$kwak"
	.type	"gbass_Inst$$15$$$kwak", %object
"gbass_Inst$$15$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$15$$$kwak
	.4byte	"gbass_Inst$$15$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$16"
	.type	"gbass_Inst$$16", %object
"gbass_Inst$$16":
	.global	"gbass_Inst$$flute_high"
	.type	"gbass_Inst$$flute_high", %object
"gbass_Inst$$flute_high":
	.byte	0x3f,0x0e	@ wave 14
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$16$$$kwak"
	.type	"gbass_Inst$$16$$$kwak", %object
"gbass_Inst$$16$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$16$$$kwak
	.4byte	"gbass_Inst$$16$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$17"
	.type	"gbass_Inst$$17", %object
"gbass_Inst$$17":
	.global	"gbass_Inst$$oboe"
	.type	"gbass_Inst$$oboe", %object
"gbass_Inst$$oboe":
	.byte	0x3f,0x10	@ wave 16
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$17$$$kwak"
	.type	"gbass_Inst$$17$$$kwak", %object
"gbass_Inst$$17$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$17$$$kwak
	.4byte	"gbass_Inst$$17$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$19"
	.type	"gbass_Inst$$19", %object
"gbass_Inst$$19":
	.global	"gbass_Inst$$clarinet"
	.type	"gbass_Inst$$clarinet", %object
"gbass_Inst$$clarinet":
	.byte	0x3f,0x11	@ wave 17
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$19$$$kwak"
	.type	"gbass_Inst$$19$$$kwak", %object
"gbass_Inst$$19$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$19$$$kwak
	.4byte	"gbass_Inst$$19$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$bassoon"
	.type	"gbass_Inst$$bassoon", %object
"gbass_Inst$$bassoon":
	.global	"gbass_Inst$$1B"
	.type	"gbass_Inst$$1B", %object
"gbass_Inst$$1B":
	.byte	0x3f,0x12	@ wave 18
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$1B$$$kwak"
	.type	"gbass_Inst$$1B$$$kwak", %object
"gbass_Inst$$1B$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$1B$$$kwak
	.4byte	"gbass_Inst$$1B$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$accordion"
	.type	"gbass_Inst$$accordion", %object
"gbass_Inst$$accordion":
	.global	"gbass_Inst$$1D"
	.type	"gbass_Inst$$1D", %object
"gbass_Inst$$1D":
	.byte	0x3f,0x13	@ wave 19
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$1D$$$kwak"
	.type	"gbass_Inst$$1D$$$kwak", %object
"gbass_Inst$$1D$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$1D$$$kwak
	.4byte	"gbass_Inst$$1D$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$1E"
	.type	"gbass_Inst$$1E", %object
"gbass_Inst$$1E":
	.global	"gbass_Inst$$bottle_blow"
	.type	"gbass_Inst$$bottle_blow", %object
"gbass_Inst$$bottle_blow":
	.byte	0x3f,0x14	@ wave 20
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.global	"gbass_Inst$$1E$$$kwak"
	.type	"gbass_Inst$$1E$$$kwak", %object
"gbass_Inst$$1E$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$1E$$$kwak
	.4byte	"gbass_Inst$$1E$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$piano_mid"
	.type	"gbass_Inst$$piano_mid", %object
"gbass_Inst$$piano_mid":
	.global	"gbass_Inst$$22"
	.type	"gbass_Inst$$22", %object
"gbass_Inst$$22":
	.byte	0x3f,0x16	@ wave 22
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$22$$$kwak"
	.type	"gbass_Inst$$22$$$kwak", %object
"gbass_Inst$$22$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$22$$$kwak
	.4byte	"gbass_Inst$$22$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$piano_high"
	.type	"gbass_Inst$$piano_high", %object
"gbass_Inst$$piano_high":
	.global	"gbass_Inst$$24"
	.type	"gbass_Inst$$24", %object
"gbass_Inst$$24":
	.byte	0x3f,0x15	@ wave 21
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$24$$$kwak"
	.type	"gbass_Inst$$24$$$kwak", %object
"gbass_Inst$$24$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$24$$$kwak
	.4byte	"gbass_Inst$$24$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$26"
	.type	"gbass_Inst$$26", %object
"gbass_Inst$$26":
	.global	"gbass_Inst$$rhodes"
	.type	"gbass_Inst$$rhodes", %object
"gbass_Inst$$rhodes":
	.byte	0x3f,0x17	@ wave 23
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$26$$$kwak"
	.type	"gbass_Inst$$26$$$kwak", %object
"gbass_Inst$$26$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$26$$$kwak
	.4byte	"gbass_Inst$$26$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$harp"
	.type	"gbass_Inst$$harp", %object
"gbass_Inst$$harp":
	.global	"gbass_Inst$$27"
	.type	"gbass_Inst$$27", %object
"gbass_Inst$$27":
	.byte	0x3f,0x18	@ wave 24
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfc	@ volslide -4
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$guitar_med"
	.type	"gbass_Inst$$guitar_med", %object
"gbass_Inst$$guitar_med":
	.global	"gbass_Inst$$29"
	.type	"gbass_Inst$$29", %object
"gbass_Inst$$29":
	.byte	0x3f,0x1a	@ wave 26
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$29$$$kwak"
	.type	"gbass_Inst$$29$$$kwak", %object
"gbass_Inst$$29$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$29$$$kwak
	.4byte	"gbass_Inst$$29$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$guitar_high"
	.type	"gbass_Inst$$guitar_high", %object
"gbass_Inst$$guitar_high":
	.global	"gbass_Inst$$2A"
	.type	"gbass_Inst$$2A", %object
"gbass_Inst$$2A":
	.byte	0x3f,0x19	@ wave 25
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$2A$$$kwak"
	.type	"gbass_Inst$$2A$$$kwak", %object
"gbass_Inst$$2A$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$2A$$$kwak
	.4byte	"gbass_Inst$$2A$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$guitar_nylon"
	.type	"gbass_Inst$$guitar_nylon", %object
"gbass_Inst$$guitar_nylon":
	.global	"gbass_Inst$$2B"
	.type	"gbass_Inst$$2B", %object
"gbass_Inst$$2B":
	.byte	0x3f,0x1b	@ wave 27
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$2B$$$kwak"
	.type	"gbass_Inst$$2B$$$kwak", %object
"gbass_Inst$$2B$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$2B$$$kwak
	.4byte	"gbass_Inst$$2B$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$2C"
	.type	"gbass_Inst$$2C", %object
"gbass_Inst$$2C":
	.global	"gbass_Inst$$bass_acoustic"
	.type	"gbass_Inst$$bass_acoustic", %object
"gbass_Inst$$bass_acoustic":
	.byte	0x3f,0x1c	@ wave 28
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$2C$$$kwak"
	.type	"gbass_Inst$$2C$$$kwak", %object
"gbass_Inst$$2C$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$2C$$$kwak
	.4byte	"gbass_Inst$$2C$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$bass_finger"
	.type	"gbass_Inst$$bass_finger", %object
"gbass_Inst$$bass_finger":
	.global	"gbass_Inst$$2D"
	.type	"gbass_Inst$$2D", %object
"gbass_Inst$$2D":
	.byte	0x3f,0x1d	@ wave 29
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.global	"gbass_Inst$$2D$$$kwak"
	.type	"gbass_Inst$$2D$$$kwak", %object
"gbass_Inst$$2D$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$2D$$$kwak
	.4byte	"gbass_Inst$$2D$$$kwak"
	.byte	0x71,0x60	@ vol 96
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$2F"
	.type	"gbass_Inst$$2F", %object
"gbass_Inst$$2F":
	.global	"gbass_Inst$$vibes"
	.type	"gbass_Inst$$vibes", %object
"gbass_Inst$$vibes":
	.byte	0x3f,0x1e	@ wave 30
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfe	@ volslide -2
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$30"
	.type	"gbass_Inst$$30", %object
"gbass_Inst$$30":
	.global	"gbass_Inst$$celesta"
	.type	"gbass_Inst$$celesta", %object
"gbass_Inst$$celesta":
	.byte	0x3f,0x1f	@ wave 31
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfd	@ volslide -3
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$31"
	.type	"gbass_Inst$$31", %object
"gbass_Inst$$31":
	.global	"gbass_Inst$$glock"
	.type	"gbass_Inst$$glock", %object
"gbass_Inst$$glock":
	.byte	0x3f,0x20	@ wave 32
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfd	@ volslide -3
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$32"
	.type	"gbass_Inst$$32", %object
"gbass_Inst$$32":
	.global	"gbass_Inst$$marimba"
	.type	"gbass_Inst$$marimba", %object
"gbass_Inst$$marimba":
	.byte	0x3f,0x21	@ wave 33
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xf1	@ volslide -15
	.byte	0x0e	@ wait 14
	.byte	0x86,0xfe	@ volslide -2
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$xylophone"
	.type	"gbass_Inst$$xylophone", %object
"gbass_Inst$$xylophone":
	.global	"gbass_Inst$$34"
	.type	"gbass_Inst$$34", %object
"gbass_Inst$$34":
	.byte	0x3f,0x22	@ wave 34
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xf6	@ volslide -10
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$35"
	.type	"gbass_Inst$$35", %object
"gbass_Inst$$35":
	.global	"gbass_Inst$$conga_high"
	.type	"gbass_Inst$$conga_high", %object
"gbass_Inst$$conga_high":
	.byte	0x3f,0x23	@ wave 35
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$conga_low"
	.type	"gbass_Inst$$conga_low", %object
"gbass_Inst$$conga_low":
	.global	"gbass_Inst$$36"
	.type	"gbass_Inst$$36", %object
"gbass_Inst$$36":
	.byte	0x3f,0x24	@ wave 36
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$conga_slap"
	.type	"gbass_Inst$$conga_slap", %object
"gbass_Inst$$conga_slap":
	.global	"gbass_Inst$$37"
	.type	"gbass_Inst$$37", %object
"gbass_Inst$$37":
	.byte	0x3f,0x25	@ wave 37
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$39"
	.type	"gbass_Inst$$39", %object
"gbass_Inst$$39":
	.global	"gbass_Inst$$tom"
	.type	"gbass_Inst$$tom", %object
"gbass_Inst$$tom":
	.byte	0x3f,0x26	@ wave 38
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$3C"
	.type	"gbass_Inst$$3C", %object
"gbass_Inst$$3C":
	.global	"gbass_Inst$$maracas"
	.type	"gbass_Inst$$maracas", %object
"gbass_Inst$$maracas":
	.byte	0x3f,0x27	@ wave 39
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$shaker"
	.type	"gbass_Inst$$shaker", %object
"gbass_Inst$$shaker":
	.global	"gbass_Inst$$3D"
	.type	"gbass_Inst$$3D", %object
"gbass_Inst$$3D":
	.byte	0x3f,0x28	@ wave 40
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$3E"
	.type	"gbass_Inst$$3E", %object
"gbass_Inst$$3E":
	.global	"gbass_Inst$$triangle_open"
	.type	"gbass_Inst$$triangle_open", %object
"gbass_Inst$$triangle_open":
	.byte	0x3f,0x29	@ wave 41
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$triangle_closed"
	.type	"gbass_Inst$$triangle_closed", %object
"gbass_Inst$$triangle_closed":
	.global	"gbass_Inst$$3F"
	.type	"gbass_Inst$$3F", %object
"gbass_Inst$$3F":
	.byte	0x3f,0x2a	@ wave 42
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$timpani"
	.type	"gbass_Inst$$timpani", %object
"gbass_Inst$$timpani":
	.global	"gbass_Inst$$41"
	.type	"gbass_Inst$$41", %object
"gbass_Inst$$41":
	.byte	0x3f,0x2b	@ wave 43
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$44"
	.type	"gbass_Inst$$44", %object
"gbass_Inst$$44":
	.global	"gbass_Inst$$click"
	.type	"gbass_Inst$$click", %object
"gbass_Inst$$click":
	.byte	0x3f,0x2c	@ wave 44
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$46"
	.type	"gbass_Inst$$46", %object
"gbass_Inst$$46":
	.global	"gbass_Inst$$cymbal_hit"
	.type	"gbass_Inst$$cymbal_hit", %object
"gbass_Inst$$cymbal_hit":
	.byte	0x3f,0x2d	@ wave 45
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0x00	@ volslide 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$47"
	.type	"gbass_Inst$$47", %object
"gbass_Inst$$47":
	.global	"gbass_Inst$$arpeggiator1"
	.type	"gbass_Inst$$arpeggiator1", %object
"gbass_Inst$$arpeggiator1":
	.byte	0x3f,0x2e	@ wave 46
	.byte	0x71,0xff	@ vol 255
	.byte	0x86,0xfb	@ volslide -5
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$gb_lead1"
	.type	"gbass_Inst$$gb_lead1", %object
"gbass_Inst$$gb_lead1":
	.global	"gbass_Inst$$48"
	.type	"gbass_Inst$$48", %object
"gbass_Inst$$48":
	.byte	0x95	@ pan_center
	.byte	0x96,0x08	@ sweep 0x08
	.byte	0x30	@ wave 0
	.byte	0x71,0xc0	@ vol 192
	.byte	0x02	@ wait 2
	.byte	0x31	@ wave 1
	.byte	0x71,0x90	@ vol 144
	.global	"gbass_Inst$$48$$$kwak"
	.type	"gbass_Inst$$48$$$kwak", %object
"gbass_Inst$$48$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$48$$$kwak
	.4byte	"gbass_Inst$$48$$$kwak"
	.byte	0x71,0x31	@ vol 49
	.byte	0x02	@ wait 2
	.byte	0x71,0x43	@ vol 67
	.byte	0x0b	@ wait 11
	.byte	0x71,0x36	@ vol 54
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$49"
	.type	"gbass_Inst$$49", %object
"gbass_Inst$$49":
	.global	"gbass_Inst$$gb_lead2"
	.type	"gbass_Inst$$gb_lead2", %object
"gbass_Inst$$gb_lead2":
	.byte	0x95	@ pan_center
	.byte	0x96,0x08	@ sweep 0x08
	.byte	0x30	@ wave 0
	.byte	0x71,0xc0	@ vol 192
	.byte	0x01	@ wait 1
	.byte	0x30	@ wave 0
	.byte	0x71,0x90	@ vol 144
	.global	"gbass_Inst$$49$$$kwak"
	.type	"gbass_Inst$$49$$$kwak", %object
"gbass_Inst$$49$$$kwak":
	.byte	0x02	@ wait 2
	.byte	0x32	@ wave 2
	.byte	0x63	@ sustain gbass_Inst$$49$$$kwak
	.4byte	"gbass_Inst$$49$$$kwak"
	.byte	0x71,0x31	@ vol 49
	.byte	0x02	@ wait 2
	.byte	0x71,0x43	@ vol 67
	.byte	0x0b	@ wait 11
	.byte	0x71,0x36	@ vol 54
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$gb_arp1"
	.type	"gbass_Inst$$gb_arp1", %object
"gbass_Inst$$gb_arp1":
	.global	"gbass_Inst$$4A"
	.type	"gbass_Inst$$4A", %object
"gbass_Inst$$4A":
	.byte	0x95	@ pan_center
	.byte	0x96,0x08	@ sweep 0x08
	.byte	0x30	@ wave 0
	.byte	0x71,0x81	@ vol 129
	.byte	0x01	@ wait 1
	.byte	0x31	@ wave 1
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$4B"
	.type	"gbass_Inst$$4B", %object
"gbass_Inst$$4B":
	.global	"gbass_Inst$$gb_arp2"
	.type	"gbass_Inst$$gb_arp2", %object
"gbass_Inst$$gb_arp2":
	.byte	0x95	@ pan_center
	.byte	0x96,0x08	@ sweep 0x08
	.byte	0x30	@ wave 0
	.byte	0x71,0x81	@ vol 129
	.byte	0x02	@ wait 2
	.byte	0x32	@ wave 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$gb_arp3"
	.type	"gbass_Inst$$gb_arp3", %object
"gbass_Inst$$gb_arp3":
	.global	"gbass_Inst$$4C"
	.type	"gbass_Inst$$4C", %object
"gbass_Inst$$4C":
	.byte	0x95	@ pan_center
	.byte	0x96,0x08	@ sweep 0x08
	.byte	0x30	@ wave 0
	.byte	0x71,0x82	@ vol 130
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$gb_kick"
	.type	"gbass_Inst$$gb_kick", %object
"gbass_Inst$$gb_kick":
	.global	"gbass_Inst$$4D"
	.type	"gbass_Inst$$4D", %object
"gbass_Inst$$4D":
	.byte	0x95	@ pan_center
	.byte	0x32	@ wave 2
	.byte	0x96,0x1b	@ sweep 0x1b
	.byte	0x71,0xa1	@ vol 161
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$gb_snare"
	.type	"gbass_Inst$$gb_snare", %object
"gbass_Inst$$gb_snare":
	.global	"gbass_Inst$$4E"
	.type	"gbass_Inst$$4E", %object
"gbass_Inst$$4E":
	.byte	0x95	@ pan_center
	.byte	0x31	@ wave 1
	.byte	0x71,0xf1	@ vol 241
	.byte	0x56	@ octave 6
	.byte	0x47	@ pitch G
	.byte	0x92	@ trigger
	.byte	0x01	@ wait 1
	.byte	0x30	@ wave 0
	.byte	0x58	@ octave 8
	.byte	0x4b	@ pitch B
	.byte	0x92	@ trigger
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$gb_hihat"
	.type	"gbass_Inst$$gb_hihat", %object
"gbass_Inst$$gb_hihat":
	.global	"gbass_Inst$$4F"
	.type	"gbass_Inst$$4F", %object
"gbass_Inst$$4F":
	.byte	0x95	@ pan_center
	.byte	0x30	@ wave 0
	.byte	0x71,0x71	@ vol 113
	.byte	0x58	@ octave 8
	.byte	0x4b	@ pitch B
	.byte	0x92	@ trigger
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$50"
	.type	"gbass_Inst$$50", %object
"gbass_Inst$$50":
	.global	"gbass_Inst$$gb_hihat_open"
	.type	"gbass_Inst$$gb_hihat_open", %object
"gbass_Inst$$gb_hihat_open":
	.byte	0x95	@ pan_center
	.byte	0x30	@ wave 0
	.byte	0x71,0x57	@ vol 87
	.byte	0x58	@ octave 8
	.byte	0x4b	@ pitch B
	.byte	0x92	@ trigger
	.byte	0x00,0x00	@ end
	.global	"gbass_Inst$$51"
	.type	"gbass_Inst$$51", %object
"gbass_Inst$$51":
	.global	"gbass_Inst$$gb_bass"
	.type	"gbass_Inst$$gb_bass", %object
"gbass_Inst$$gb_bass":
	.byte	0x3f,0x2f	@ wave 47
	.byte	0x71,0xff	@ vol 255
	.global	"gbass_Inst$$51$$$kwak"
	.type	"gbass_Inst$$51$$$kwak", %object
"gbass_Inst$$51$$$kwak":
	.byte	0x01	@ wait 1
	.byte	0x63	@ sustain gbass_Inst$$51$$$kwak
	.4byte	"gbass_Inst$$51$$$kwak"
	.byte	0x71,0xff	@ vol 255
	.byte	0x03	@ wait 3
	.byte	0x71,0x80	@ vol 128
	.byte	0x03	@ wait 3
	.byte	0x71,0x20	@ vol 32
	.byte	0x03	@ wait 3
	.byte	0x71,0x00	@ vol 0
	.byte	0x00,0x00	@ end
	.byte	0x00,0x00	@ end
@ Song (12 bytes): u32 track count, Track *tracks, char *name
	.global	gbass_SongTable
	.type	gbass_SongTable, %object
gbass_SongTable:
	.4byte	12	@ song 0: tracks
	.4byte	"gbass_Song$$0$ChannelTable"
	.4byte	"gbass_Song$$0$Name"
	.global	"gbass_Song$$0$Name"
	.type	"gbass_Song$$0$Name", %object
"gbass_Song$$0$Name":
	.ascii	"Title"
	.byte	0,0,0
@ Track (8 bytes): u8 *script, s16 hardware channel (0-3 GB, 4+ digital), s16 volume
	.global	"gbass_Song$$0$ChannelTable"
	.type	"gbass_Song$$0$ChannelTable", %object
"gbass_Song$$0$ChannelTable":
	.4byte	"gbass_Song$$0$Channel$0"
	.2byte	0, 256	@ track 0: GB 1 channel, volume
	.4byte	"gbass_Song$$0$Channel$1"
	.2byte	1, 256	@ track 1: GB 2 channel, volume
	.4byte	"gbass_Song$$0$Channel$2"
	.2byte	2, 256	@ track 2: GB 3 channel, volume
	.4byte	"gbass_Song$$0$Channel$3"
	.2byte	3, 256	@ track 3: GB 4 channel, volume
	.4byte	"gbass_Song$$0$Channel$4"
	.2byte	4, 256	@ track 4: digital 0 channel, volume
	.4byte	"gbass_Song$$0$Channel$5"
	.2byte	5, 256	@ track 5: digital 1 channel, volume
	.4byte	"gbass_Song$$0$Channel$6"
	.2byte	6, 256	@ track 6: digital 2 channel, volume
	.4byte	"gbass_Song$$0$Channel$7"
	.2byte	7, 256	@ track 7: digital 3 channel, volume
	.4byte	"gbass_Song$$0$Channel$8"
	.2byte	8, 256	@ track 8: digital 4 channel, volume
	.4byte	"gbass_Song$$0$Channel$9"
	.2byte	9, 256	@ track 9: digital 5 channel, volume
	.4byte	"gbass_Song$$0$Channel$10"
	.2byte	10, 256	@ track 10: digital 6 channel, volume
	.4byte	"gbass_Song$$0$Channel$11"
	.2byte	11, 256	@ track 11: digital 7 channel, volume
	.global	"gbass_Song$$0$Channel$0"
	.type	"gbass_Song$$0$Channel$0", %object
"gbass_Song$$0$Channel$0":
	.byte	0x10	@ play gbass_Pat$$title$$10$0
	.4byte	"gbass_Pat$$title$$10$0"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$0
	.4byte	"gbass_Pat$$title$$9$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$0$LoopPoint"
	.type	"gbass_Song$$0$Channel$0$LoopPoint", %object
"gbass_Song$$0$Channel$0$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$0
	.4byte	"gbass_Pat$$title$$0$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$0
	.4byte	"gbass_Pat$$title$$1$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$0
	.4byte	"gbass_Pat$$title$$2$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$0
	.4byte	"gbass_Pat$$title$$3$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$0
	.4byte	"gbass_Pat$$title$$4$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$0
	.4byte	"gbass_Pat$$title$$5$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$0
	.4byte	"gbass_Pat$$title$$6$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$0
	.4byte	"gbass_Pat$$title$$7$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$0
	.4byte	"gbass_Pat$$title$$8$0"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$0$LoopPoint
	.4byte	"gbass_Song$$0$Channel$0$LoopPoint"
	.global	"gbass_Song$$0$Channel$1"
	.type	"gbass_Song$$0$Channel$1", %object
"gbass_Song$$0$Channel$1":
	.byte	0x10	@ play gbass_Pat$$title$$10$1
	.4byte	"gbass_Pat$$title$$10$1"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$1
	.4byte	"gbass_Pat$$title$$9$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$1$LoopPoint"
	.type	"gbass_Song$$0$Channel$1$LoopPoint", %object
"gbass_Song$$0$Channel$1$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$1
	.4byte	"gbass_Pat$$title$$0$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$1
	.4byte	"gbass_Pat$$title$$1$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$1
	.4byte	"gbass_Pat$$title$$2$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$1
	.4byte	"gbass_Pat$$title$$3$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$1
	.4byte	"gbass_Pat$$title$$4$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$1
	.4byte	"gbass_Pat$$title$$5$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$1
	.4byte	"gbass_Pat$$title$$6$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$1
	.4byte	"gbass_Pat$$title$$7$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$1
	.4byte	"gbass_Pat$$title$$8$1"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$1$LoopPoint
	.4byte	"gbass_Song$$0$Channel$1$LoopPoint"
	.global	"gbass_Song$$0$Channel$2"
	.type	"gbass_Song$$0$Channel$2", %object
"gbass_Song$$0$Channel$2":
	.byte	0x10	@ play gbass_Pat$$title$$10$2
	.4byte	"gbass_Pat$$title$$10$2"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$2
	.4byte	"gbass_Pat$$title$$9$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$2$LoopPoint"
	.type	"gbass_Song$$0$Channel$2$LoopPoint", %object
"gbass_Song$$0$Channel$2$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$2
	.4byte	"gbass_Pat$$title$$0$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$2
	.4byte	"gbass_Pat$$title$$1$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$2
	.4byte	"gbass_Pat$$title$$2$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$2
	.4byte	"gbass_Pat$$title$$3$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$2
	.4byte	"gbass_Pat$$title$$4$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$2
	.4byte	"gbass_Pat$$title$$5$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$2
	.4byte	"gbass_Pat$$title$$6$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$2
	.4byte	"gbass_Pat$$title$$7$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$2
	.4byte	"gbass_Pat$$title$$8$2"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$2$LoopPoint
	.4byte	"gbass_Song$$0$Channel$2$LoopPoint"
	.global	"gbass_Song$$0$Channel$3"
	.type	"gbass_Song$$0$Channel$3", %object
"gbass_Song$$0$Channel$3":
	.byte	0x10	@ play gbass_Pat$$title$$10$3
	.4byte	"gbass_Pat$$title$$10$3"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$3
	.4byte	"gbass_Pat$$title$$9$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$3$LoopPoint"
	.type	"gbass_Song$$0$Channel$3$LoopPoint", %object
"gbass_Song$$0$Channel$3$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$3
	.4byte	"gbass_Pat$$title$$0$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$3
	.4byte	"gbass_Pat$$title$$1$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$3
	.4byte	"gbass_Pat$$title$$2$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$3
	.4byte	"gbass_Pat$$title$$3$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$3
	.4byte	"gbass_Pat$$title$$4$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$3
	.4byte	"gbass_Pat$$title$$5$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$3
	.4byte	"gbass_Pat$$title$$6$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$3
	.4byte	"gbass_Pat$$title$$7$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$3
	.4byte	"gbass_Pat$$title$$8$3"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$3$LoopPoint
	.4byte	"gbass_Song$$0$Channel$3$LoopPoint"
	.global	"gbass_Song$$0$Channel$4"
	.type	"gbass_Song$$0$Channel$4", %object
"gbass_Song$$0$Channel$4":
	.byte	0x10	@ play gbass_Pat$$title$$10$4
	.4byte	"gbass_Pat$$title$$10$4"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$4
	.4byte	"gbass_Pat$$title$$9$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$4$LoopPoint"
	.type	"gbass_Song$$0$Channel$4$LoopPoint", %object
"gbass_Song$$0$Channel$4$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$4
	.4byte	"gbass_Pat$$title$$0$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$4
	.4byte	"gbass_Pat$$title$$1$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$4
	.4byte	"gbass_Pat$$title$$2$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$4
	.4byte	"gbass_Pat$$title$$3$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$4
	.4byte	"gbass_Pat$$title$$4$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$4
	.4byte	"gbass_Pat$$title$$5$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$4
	.4byte	"gbass_Pat$$title$$6$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$4
	.4byte	"gbass_Pat$$title$$7$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$4
	.4byte	"gbass_Pat$$title$$8$4"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$4$LoopPoint
	.4byte	"gbass_Song$$0$Channel$4$LoopPoint"
	.global	"gbass_Song$$0$Channel$5"
	.type	"gbass_Song$$0$Channel$5", %object
"gbass_Song$$0$Channel$5":
	.byte	0x10	@ play gbass_Pat$$title$$10$5
	.4byte	"gbass_Pat$$title$$10$5"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$5
	.4byte	"gbass_Pat$$title$$9$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$5$LoopPoint"
	.type	"gbass_Song$$0$Channel$5$LoopPoint", %object
"gbass_Song$$0$Channel$5$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$5
	.4byte	"gbass_Pat$$title$$0$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$5
	.4byte	"gbass_Pat$$title$$1$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$5
	.4byte	"gbass_Pat$$title$$2$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$5
	.4byte	"gbass_Pat$$title$$3$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$5
	.4byte	"gbass_Pat$$title$$4$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$5
	.4byte	"gbass_Pat$$title$$5$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$5
	.4byte	"gbass_Pat$$title$$6$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$5
	.4byte	"gbass_Pat$$title$$7$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$5
	.4byte	"gbass_Pat$$title$$8$5"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$5$LoopPoint
	.4byte	"gbass_Song$$0$Channel$5$LoopPoint"
	.global	"gbass_Song$$0$Channel$6"
	.type	"gbass_Song$$0$Channel$6", %object
"gbass_Song$$0$Channel$6":
	.byte	0x10	@ play gbass_Pat$$title$$10$6
	.4byte	"gbass_Pat$$title$$10$6"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$6
	.4byte	"gbass_Pat$$title$$9$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$6$LoopPoint"
	.type	"gbass_Song$$0$Channel$6$LoopPoint", %object
"gbass_Song$$0$Channel$6$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$6
	.4byte	"gbass_Pat$$title$$0$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$6
	.4byte	"gbass_Pat$$title$$1$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$6
	.4byte	"gbass_Pat$$title$$2$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$6
	.4byte	"gbass_Pat$$title$$3$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$6
	.4byte	"gbass_Pat$$title$$4$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$6
	.4byte	"gbass_Pat$$title$$5$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$6
	.4byte	"gbass_Pat$$title$$6$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$6
	.4byte	"gbass_Pat$$title$$7$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$6
	.4byte	"gbass_Pat$$title$$8$6"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$6$LoopPoint
	.4byte	"gbass_Song$$0$Channel$6$LoopPoint"
	.global	"gbass_Song$$0$Channel$7"
	.type	"gbass_Song$$0$Channel$7", %object
"gbass_Song$$0$Channel$7":
	.byte	0x10	@ play gbass_Pat$$title$$10$7
	.4byte	"gbass_Pat$$title$$10$7"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$7
	.4byte	"gbass_Pat$$title$$9$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$7$LoopPoint"
	.type	"gbass_Song$$0$Channel$7$LoopPoint", %object
"gbass_Song$$0$Channel$7$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$7
	.4byte	"gbass_Pat$$title$$0$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$7
	.4byte	"gbass_Pat$$title$$1$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$7
	.4byte	"gbass_Pat$$title$$2$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$7
	.4byte	"gbass_Pat$$title$$3$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$7
	.4byte	"gbass_Pat$$title$$4$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$7
	.4byte	"gbass_Pat$$title$$5$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$7
	.4byte	"gbass_Pat$$title$$6$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$7
	.4byte	"gbass_Pat$$title$$7$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$7
	.4byte	"gbass_Pat$$title$$8$7"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$7$LoopPoint
	.4byte	"gbass_Song$$0$Channel$7$LoopPoint"
	.global	"gbass_Song$$0$Channel$8"
	.type	"gbass_Song$$0$Channel$8", %object
"gbass_Song$$0$Channel$8":
	.byte	0x10	@ play gbass_Pat$$title$$10$8
	.4byte	"gbass_Pat$$title$$10$8"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$8
	.4byte	"gbass_Pat$$title$$9$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$8$LoopPoint"
	.type	"gbass_Song$$0$Channel$8$LoopPoint", %object
"gbass_Song$$0$Channel$8$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$8
	.4byte	"gbass_Pat$$title$$0$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$8
	.4byte	"gbass_Pat$$title$$1$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$8
	.4byte	"gbass_Pat$$title$$2$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$8
	.4byte	"gbass_Pat$$title$$3$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$8
	.4byte	"gbass_Pat$$title$$4$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$8
	.4byte	"gbass_Pat$$title$$5$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$8
	.4byte	"gbass_Pat$$title$$6$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$8
	.4byte	"gbass_Pat$$title$$7$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$8
	.4byte	"gbass_Pat$$title$$8$8"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$8$LoopPoint
	.4byte	"gbass_Song$$0$Channel$8$LoopPoint"
	.global	"gbass_Song$$0$Channel$9"
	.type	"gbass_Song$$0$Channel$9", %object
"gbass_Song$$0$Channel$9":
	.byte	0x10	@ play gbass_Pat$$title$$10$9
	.4byte	"gbass_Pat$$title$$10$9"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$9
	.4byte	"gbass_Pat$$title$$9$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$9$LoopPoint"
	.type	"gbass_Song$$0$Channel$9$LoopPoint", %object
"gbass_Song$$0$Channel$9$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$9
	.4byte	"gbass_Pat$$title$$0$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$9
	.4byte	"gbass_Pat$$title$$1$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$9
	.4byte	"gbass_Pat$$title$$2$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$9
	.4byte	"gbass_Pat$$title$$3$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$9
	.4byte	"gbass_Pat$$title$$4$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$9
	.4byte	"gbass_Pat$$title$$5$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$9
	.4byte	"gbass_Pat$$title$$6$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$9
	.4byte	"gbass_Pat$$title$$7$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$9
	.4byte	"gbass_Pat$$title$$8$9"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$9$LoopPoint
	.4byte	"gbass_Song$$0$Channel$9$LoopPoint"
	.global	"gbass_Song$$0$Channel$10"
	.type	"gbass_Song$$0$Channel$10", %object
"gbass_Song$$0$Channel$10":
	.byte	0x10	@ play gbass_Pat$$title$$10$10
	.4byte	"gbass_Pat$$title$$10$10"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$10
	.4byte	"gbass_Pat$$title$$9$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$10$LoopPoint"
	.type	"gbass_Song$$0$Channel$10$LoopPoint", %object
"gbass_Song$$0$Channel$10$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$10
	.4byte	"gbass_Pat$$title$$0$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$10
	.4byte	"gbass_Pat$$title$$1$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$10
	.4byte	"gbass_Pat$$title$$2$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$10
	.4byte	"gbass_Pat$$title$$3$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$10
	.4byte	"gbass_Pat$$title$$4$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$10
	.4byte	"gbass_Pat$$title$$5$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$10
	.4byte	"gbass_Pat$$title$$6$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$10
	.4byte	"gbass_Pat$$title$$7$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$10
	.4byte	"gbass_Pat$$title$$8$10"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$10$LoopPoint
	.4byte	"gbass_Song$$0$Channel$10$LoopPoint"
	.global	"gbass_Song$$0$Channel$11"
	.type	"gbass_Song$$0$Channel$11", %object
"gbass_Song$$0$Channel$11":
	.byte	0x10	@ play gbass_Pat$$title$$10$11
	.4byte	"gbass_Pat$$title$$10$11"
	.byte	0x00,0x14	@ wait 20
	.byte	0x10	@ play gbass_Pat$$title$$9$11
	.4byte	"gbass_Pat$$title$$9$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.global	"gbass_Song$$0$Channel$11$LoopPoint"
	.type	"gbass_Song$$0$Channel$11$LoopPoint", %object
"gbass_Song$$0$Channel$11$LoopPoint":
	.byte	0x10	@ play gbass_Pat$$title$$0$11
	.4byte	"gbass_Pat$$title$$0$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$1$11
	.4byte	"gbass_Pat$$title$$1$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$2$11
	.4byte	"gbass_Pat$$title$$2$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$3$11
	.4byte	"gbass_Pat$$title$$3$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xe1	@ wait 225
	.byte	0x10	@ play gbass_Pat$$title$$4$11
	.4byte	"gbass_Pat$$title$$4$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xef	@ wait 239
	.byte	0x10	@ play gbass_Pat$$title$$5$11
	.4byte	"gbass_Pat$$title$$5$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$6$11
	.4byte	"gbass_Pat$$title$$6$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x10	@ play gbass_Pat$$title$$7$11
	.4byte	"gbass_Pat$$title$$7$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x41	@ wait 65
	.byte	0x10	@ play gbass_Pat$$title$$8$11
	.4byte	"gbass_Pat$$title$$8$11"
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x82	@ wait 130
	.byte	0x60	@ jump gbass_Song$$0$Channel$11$LoopPoint
	.4byte	"gbass_Song$$0$Channel$11$LoopPoint"
	.global	"gbass_Pat$$title$$0$0"
	.type	"gbass_Pat$$title$$0$0", %object
"gbass_Pat$$title$$0$0":
	.global	"gbass_Pat$$title$$0$0$0"
	.type	"gbass_Pat$$title$$0$0$0", %object
"gbass_Pat$$title$$0$0$0":
	.byte	0x80	@ fx_off
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$1$0"
	.type	"gbass_Pat$$title$$0$1$0", %object
"gbass_Pat$$title$$0$1$0":
	.global	"gbass_Pat$$title$$0$1"
	.type	"gbass_Pat$$title$$0$1", %object
"gbass_Pat$$title$$0$1":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$2"
	.type	"gbass_Pat$$title$$0$2", %object
"gbass_Pat$$title$$0$2":
	.global	"gbass_Pat$$title$$0$2$0"
	.type	"gbass_Pat$$title$$0$2$0", %object
"gbass_Pat$$title$$0$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$3$0"
	.type	"gbass_Pat$$title$$0$3$0", %object
"gbass_Pat$$title$$0$3$0":
	.global	"gbass_Pat$$title$$0$3"
	.type	"gbass_Pat$$title$$0$3", %object
"gbass_Pat$$title$$0$3":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$4"
	.type	"gbass_Pat$$title$$0$4", %object
"gbass_Pat$$title$$0$4":
	.global	"gbass_Pat$$title$$0$4$0"
	.type	"gbass_Pat$$title$$0$4$0", %object
"gbass_Pat$$title$$0$4$0":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x0a	@ wait 10
	.byte	0x84,0x55,0x1f	@ slide_to 0x55, 31
	.byte	0x0a	@ wait 10
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x00,0x50	@ wait 80
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x2b,0x00	@ note B, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x3c	@ wait 60
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x00,0x1e	@ wait 30
	.byte	0x22,0x00	@ note D, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x22,0x00	@ note D, inst 0
	.byte	0x00,0x78	@ wait 120
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x22,0x00	@ note D, inst 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$5$0"
	.type	"gbass_Pat$$title$$0$5$0", %object
"gbass_Pat$$title$$0$5$0":
	.global	"gbass_Pat$$title$$0$5"
	.type	"gbass_Pat$$title$$0$5", %object
"gbass_Pat$$title$$0$5":
	.byte	0x54	@ octave 4
	.byte	0x20,0x2d	@ note C, inst 45
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x27,0x21	@ note G, inst 33
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0xa0	@ wait 160
	.byte	0x27,0x21	@ note G, inst 33
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x21	@ note F, inst 33
	.byte	0x00,0x28	@ wait 40
	.byte	0x24,0x21	@ note E, inst 33
	.byte	0x00,0xa0	@ wait 160
	.byte	0x22,0x21	@ note D, inst 33
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$6"
	.type	"gbass_Pat$$title$$0$6", %object
"gbass_Pat$$title$$0$6":
	.global	"gbass_Pat$$title$$0$6$0"
	.type	"gbass_Pat$$title$$0$6$0", %object
"gbass_Pat$$title$$0$6$0":
	.byte	0x54	@ octave 4
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x07	@ note G, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x07	@ note G, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x07	@ note A, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x07	@ note G, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x27,0x07	@ note G, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$7"
	.type	"gbass_Pat$$title$$0$7", %object
"gbass_Pat$$title$$0$7":
	.global	"gbass_Pat$$title$$0$7$0"
	.type	"gbass_Pat$$title$$0$7$0", %object
"gbass_Pat$$title$$0$7$0":
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x55	@ octave 5
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$8"
	.type	"gbass_Pat$$title$$0$8", %object
"gbass_Pat$$title$$0$8":
	.global	"gbass_Pat$$title$$0$8$0"
	.type	"gbass_Pat$$title$$0$8$0", %object
"gbass_Pat$$title$$0$8$0":
	.byte	0x55	@ octave 5
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$9$0"
	.type	"gbass_Pat$$title$$0$9$0", %object
"gbass_Pat$$title$$0$9$0":
	.global	"gbass_Pat$$title$$0$9"
	.type	"gbass_Pat$$title$$0$9", %object
"gbass_Pat$$title$$0$9":
	.byte	0x55	@ octave 5
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x54	@ octave 4
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$10"
	.type	"gbass_Pat$$title$$0$10", %object
"gbass_Pat$$title$$0$10":
	.global	"gbass_Pat$$title$$0$10$0"
	.type	"gbass_Pat$$title$$0$10$0", %object
"gbass_Pat$$title$$0$10$0":
	.byte	0x55	@ octave 5
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x78	@ wait 120
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$0$11"
	.type	"gbass_Pat$$title$$0$11", %object
"gbass_Pat$$title$$0$11":
	.global	"gbass_Pat$$title$$0$11$0"
	.type	"gbass_Pat$$title$$0$11$0", %object
"gbass_Pat$$title$$0$11$0":
	.byte	0x00,0x64	@ wait 100
	.byte	0x55	@ octave 5
	.byte	0x24,0x10	@ note E, inst 16
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x25,0x10	@ note F, inst 16
	.byte	0x0a	@ wait 10
	.byte	0x27,0x10	@ note G, inst 16
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x20,0x10	@ note C, inst 16
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x20,0x11	@ note C, inst 17
	.byte	0x05	@ wait 5
	.byte	0x84,0x52,0x1f	@ slide_to 0x52, 31
	.byte	0x72,0x60	@ chvol 96
	.byte	0x05	@ wait 5
	.byte	0x84,0x50,0x1f	@ slide_to 0x50, 31
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x41	@ wait 65
	.byte	0x4f	@ release
	.byte	0x00,0x19	@ wait 25
	.byte	0x54	@ octave 4
	.byte	0x2b,0x11	@ note B, inst 17
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x29,0x11	@ note A, inst 17
	.byte	0x0a	@ wait 10
	.byte	0x27,0x11	@ note G, inst 17
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x11	@ note F, inst 17
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x11	@ note G, inst 17
	.byte	0x00,0x1e	@ wait 30
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$0"
	.type	"gbass_Pat$$title$$1$0", %object
"gbass_Pat$$title$$1$0":
	.global	"gbass_Pat$$title$$1$0$0"
	.type	"gbass_Pat$$title$$1$0$0", %object
"gbass_Pat$$title$$1$0$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$1$0"
	.type	"gbass_Pat$$title$$1$1$0", %object
"gbass_Pat$$title$$1$1$0":
	.global	"gbass_Pat$$title$$1$1"
	.type	"gbass_Pat$$title$$1$1", %object
"gbass_Pat$$title$$1$1":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$2$0"
	.type	"gbass_Pat$$title$$1$2$0", %object
"gbass_Pat$$title$$1$2$0":
	.global	"gbass_Pat$$title$$1$2"
	.type	"gbass_Pat$$title$$1$2", %object
"gbass_Pat$$title$$1$2":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$3"
	.type	"gbass_Pat$$title$$1$3", %object
"gbass_Pat$$title$$1$3":
	.global	"gbass_Pat$$title$$1$3$0"
	.type	"gbass_Pat$$title$$1$3$0", %object
"gbass_Pat$$title$$1$3$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$4"
	.type	"gbass_Pat$$title$$1$4", %object
"gbass_Pat$$title$$1$4":
	.global	"gbass_Pat$$title$$1$4$0"
	.type	"gbass_Pat$$title$$1$4$0", %object
"gbass_Pat$$title$$1$4$0":
	.byte	0x55	@ octave 5
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x28	@ wait 40
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x22,0x00	@ note D, inst 0
	.byte	0x05	@ wait 5
	.byte	0x4f	@ release
	.byte	0x05	@ wait 5
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x26,0x00	@ note F#, inst 0
	.byte	0x00,0x2d	@ wait 45
	.byte	0x4f	@ release
	.byte	0x0f	@ wait 15
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x84,0x56,0x1f	@ slide_to 0x56, 31
	.byte	0x05	@ wait 5
	.byte	0x84,0x55,0x1f	@ slide_to 0x55, 31
	.byte	0x05	@ wait 5
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x3c	@ wait 60
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x3c	@ wait 60
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x20,0x17	@ note C, inst 23
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$5$0"
	.type	"gbass_Pat$$title$$1$5$0", %object
"gbass_Pat$$title$$1$5$0":
	.global	"gbass_Pat$$title$$1$5"
	.type	"gbass_Pat$$title$$1$5", %object
"gbass_Pat$$title$$1$5":
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xff	@ wait 255
	.byte	0x54	@ octave 4
	.byte	0x24,0x17	@ note E, inst 23
	.byte	0x00,0x32	@ wait 50
	.byte	0x20,0x18	@ note C, inst 24
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$6"
	.type	"gbass_Pat$$title$$1$6", %object
"gbass_Pat$$title$$1$6":
	.global	"gbass_Pat$$title$$1$6$0"
	.type	"gbass_Pat$$title$$1$6$0", %object
"gbass_Pat$$title$$1$6$0":
	.byte	0x54	@ octave 4
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x22,0x08	@ note D, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x53	@ octave 3
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x23,0x07	@ note D#, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x23,0x08	@ note D#, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x26,0x08	@ note F#, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x28	@ wait 40
	.byte	0x53	@ octave 3
	.byte	0x27,0x1b	@ note G, inst 27
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x07	@ note G, inst 7
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x27,0x1b	@ note G, inst 27
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x1b	@ note C, inst 27
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x00,0x1e	@ wait 30
	.byte	0x27,0x17	@ note G, inst 23
	.byte	0x00,0x1e	@ wait 30
	.byte	0x55	@ octave 5
	.byte	0x27,0x17	@ note G, inst 23
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$7$0"
	.type	"gbass_Pat$$title$$1$7$0", %object
"gbass_Pat$$title$$1$7$0":
	.global	"gbass_Pat$$title$$1$7"
	.type	"gbass_Pat$$title$$1$7", %object
"gbass_Pat$$title$$1$7":
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x54	@ octave 4
	.byte	0x26,0x08	@ note F#, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x54	@ octave 4
	.byte	0x27,0x09	@ note G, inst 9
	.byte	0x0a	@ wait 10
	.byte	0x29,0x09	@ note A, inst 9
	.byte	0x0a	@ wait 10
	.byte	0x27,0x09	@ note G, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x09	@ note G, inst 9
	.byte	0x0a	@ wait 10
	.byte	0x29,0x09	@ note A, inst 9
	.byte	0x0a	@ wait 10
	.byte	0x27,0x09	@ note G, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x46	@ wait 70
	.byte	0x55	@ octave 5
	.byte	0x20,0x17	@ note C, inst 23
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$8"
	.type	"gbass_Pat$$title$$1$8", %object
"gbass_Pat$$title$$1$8":
	.global	"gbass_Pat$$title$$1$8$0"
	.type	"gbass_Pat$$title$$1$8$0", %object
"gbass_Pat$$title$$1$8$0":
	.byte	0x54	@ octave 4
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x23,0x06	@ note D#, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x8c	@ wait 140
	.byte	0x55	@ octave 5
	.byte	0x24,0x17	@ note E, inst 23
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$9"
	.type	"gbass_Pat$$title$$1$9", %object
"gbass_Pat$$title$$1$9":
	.global	"gbass_Pat$$title$$1$9$0"
	.type	"gbass_Pat$$title$$1$9$0", %object
"gbass_Pat$$title$$1$9$0":
	.byte	0x55	@ octave 5
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0xf0	@ wait 240
	.byte	0x54	@ octave 4
	.byte	0x26,0x06	@ note F#, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x64	@ wait 100
	.byte	0x55	@ octave 5
	.byte	0x23,0x00	@ note D#, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x00	@ note E, inst 0
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x2b,0x00	@ note B, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$10"
	.type	"gbass_Pat$$title$$1$10", %object
"gbass_Pat$$title$$1$10":
	.global	"gbass_Pat$$title$$1$10$0"
	.type	"gbass_Pat$$title$$1$10$0", %object
"gbass_Pat$$title$$1$10$0":
	.byte	0x55	@ octave 5
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x56	@ octave 6
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x56	@ octave 6
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x29,0x03	@ note A, inst 3
	.byte	0x00,0x50	@ wait 80
	.byte	0x2b,0x03	@ note B, inst 3
	.byte	0x00,0x64	@ wait 100
	.byte	0x26,0x01	@ note F#, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x84,0x47,0x1f	@ slide_to 0x47, 31
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x23,0x01	@ note D#, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x84,0x44,0x1f	@ slide_to 0x44, 31
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$1$11"
	.type	"gbass_Pat$$title$$1$11", %object
"gbass_Pat$$title$$1$11":
	.global	"gbass_Pat$$title$$1$11$0"
	.type	"gbass_Pat$$title$$1$11$0", %object
"gbass_Pat$$title$$1$11$0":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x24,0x13	@ note E, inst 19
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x25,0x13	@ note F, inst 19
	.byte	0x0a	@ wait 10
	.byte	0x27,0x13	@ note G, inst 19
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x13	@ note C, inst 19
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x13	@ note C, inst 19
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x2b,0x13	@ note B, inst 19
	.byte	0x0a	@ wait 10
	.byte	0x29,0x13	@ note A, inst 19
	.byte	0x0a	@ wait 10
	.byte	0x27,0x13	@ note G, inst 19
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x13	@ note F, inst 19
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x13	@ note G, inst 19
	.byte	0x00,0x23	@ wait 35
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$0$0"
	.type	"gbass_Pat$$title$$2$0$0", %object
"gbass_Pat$$title$$2$0$0":
	.global	"gbass_Pat$$title$$2$0"
	.type	"gbass_Pat$$title$$2$0", %object
"gbass_Pat$$title$$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$1"
	.type	"gbass_Pat$$title$$2$1", %object
"gbass_Pat$$title$$2$1":
	.global	"gbass_Pat$$title$$2$1$0"
	.type	"gbass_Pat$$title$$2$1$0", %object
"gbass_Pat$$title$$2$1$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$2"
	.type	"gbass_Pat$$title$$2$2", %object
"gbass_Pat$$title$$2$2":
	.global	"gbass_Pat$$title$$2$2$0"
	.type	"gbass_Pat$$title$$2$2$0", %object
"gbass_Pat$$title$$2$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$3"
	.type	"gbass_Pat$$title$$2$3", %object
"gbass_Pat$$title$$2$3":
	.global	"gbass_Pat$$title$$2$3$0"
	.type	"gbass_Pat$$title$$2$3$0", %object
"gbass_Pat$$title$$2$3$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$4"
	.type	"gbass_Pat$$title$$2$4", %object
"gbass_Pat$$title$$2$4":
	.global	"gbass_Pat$$title$$2$4$0"
	.type	"gbass_Pat$$title$$2$4$0", %object
"gbass_Pat$$title$$2$4$0":
	.byte	0x55	@ octave 5
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x2b,0x01	@ note B, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x00,0x1e	@ wait 30
	.byte	0x54	@ octave 4
	.byte	0x2b,0x01	@ note B, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x64	@ wait 100
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x29,0x01	@ note A, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x26,0x01	@ note F#, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x26,0x01	@ note F#, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x29,0x01	@ note A, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x01	@ note B, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x0b	@ note G, inst 11
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$5"
	.type	"gbass_Pat$$title$$2$5", %object
"gbass_Pat$$title$$2$5":
	.global	"gbass_Pat$$title$$2$5$0"
	.type	"gbass_Pat$$title$$2$5$0", %object
"gbass_Pat$$title$$2$5$0":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x09	@ note C, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x29,0x09	@ note A, inst 9
	.byte	0x00,0x3c	@ wait 60
	.byte	0x55	@ octave 5
	.byte	0x20,0x09	@ note C, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x28,0x09	@ note G#, inst 9
	.byte	0x00,0x3c	@ wait 60
	.byte	0x55	@ octave 5
	.byte	0x20,0x09	@ note C, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x09	@ note G, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x09	@ note E, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x09	@ note C, inst 9
	.byte	0x00,0x64	@ wait 100
	.byte	0x55	@ octave 5
	.byte	0x20,0x09	@ note C, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x29,0x09	@ note A, inst 9
	.byte	0x00,0x3c	@ wait 60
	.byte	0x29,0x09	@ note A, inst 9
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x09	@ note D, inst 9
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x2b,0x21	@ note B, inst 33
	.byte	0x00,0x28	@ wait 40
	.byte	0x56	@ octave 6
	.byte	0x20,0x21	@ note C, inst 33
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x21	@ note D, inst 33
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$6$0"
	.type	"gbass_Pat$$title$$2$6$0", %object
"gbass_Pat$$title$$2$6$0":
	.global	"gbass_Pat$$title$$2$6"
	.type	"gbass_Pat$$title$$2$6", %object
"gbass_Pat$$title$$2$6":
	.byte	0x55	@ octave 5
	.byte	0x26,0x0d	@ note F#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x26,0x0d	@ note F#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x25,0x0d	@ note F, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x28,0x0d	@ note G#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x25,0x0d	@ note F, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x28,0x0d	@ note G#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x26,0x0d	@ note F#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x26,0x0d	@ note F#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x2b,0x0d	@ note B, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$7$0"
	.type	"gbass_Pat$$title$$2$7$0", %object
"gbass_Pat$$title$$2$7$0":
	.global	"gbass_Pat$$title$$2$7"
	.type	"gbass_Pat$$title$$2$7", %object
"gbass_Pat$$title$$2$7":
	.byte	0x54	@ octave 4
	.byte	0x26,0x1e	@ note F#, inst 30
	.byte	0x00,0x3c	@ wait 60
	.byte	0x26,0x1e	@ note F#, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x1e	@ note F, inst 30
	.byte	0x00,0x3c	@ wait 60
	.byte	0x25,0x1e	@ note F, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x1e	@ note E, inst 30
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x1e	@ note C, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x1e	@ note C, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x2b,0x1e	@ note B, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x2b,0x1e	@ note B, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x1e	@ note A, inst 30
	.byte	0x00,0x3c	@ wait 60
	.byte	0x27,0x1e	@ note G, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x26,0x1e	@ note F#, inst 30
	.byte	0x00,0x50	@ wait 80
	.byte	0x2b,0x0b	@ note B, inst 11
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x0b	@ note C, inst 11
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x0b	@ note D, inst 11
	.byte	0x00,0x23	@ wait 35
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$8$0"
	.type	"gbass_Pat$$title$$2$8$0", %object
"gbass_Pat$$title$$2$8$0":
	.global	"gbass_Pat$$title$$2$8"
	.type	"gbass_Pat$$title$$2$8", %object
"gbass_Pat$$title$$2$8":
	.byte	0x54	@ octave 4
	.byte	0x26,0x06	@ note F#, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x53	@ octave 3
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$9"
	.type	"gbass_Pat$$title$$2$9", %object
"gbass_Pat$$title$$2$9":
	.global	"gbass_Pat$$title$$2$9$0"
	.type	"gbass_Pat$$title$$2$9$0", %object
"gbass_Pat$$title$$2$9$0":
	.byte	0x55	@ octave 5
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x28,0x06	@ note G#, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$10$0"
	.type	"gbass_Pat$$title$$2$10$0", %object
"gbass_Pat$$title$$2$10$0":
	.global	"gbass_Pat$$title$$2$10"
	.type	"gbass_Pat$$title$$2$10", %object
"gbass_Pat$$title$$2$10":
	.byte	0x56	@ octave 6
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x26,0x06	@ note F#, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$2$11$0"
	.type	"gbass_Pat$$title$$2$11$0", %object
"gbass_Pat$$title$$2$11$0":
	.global	"gbass_Pat$$title$$2$11"
	.type	"gbass_Pat$$title$$2$11", %object
"gbass_Pat$$title$$2$11":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$0"
	.type	"gbass_Pat$$title$$3$0", %object
"gbass_Pat$$title$$3$0":
	.global	"gbass_Pat$$title$$3$0$0"
	.type	"gbass_Pat$$title$$3$0$0", %object
"gbass_Pat$$title$$3$0$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$1$0"
	.type	"gbass_Pat$$title$$3$1$0", %object
"gbass_Pat$$title$$3$1$0":
	.global	"gbass_Pat$$title$$3$1"
	.type	"gbass_Pat$$title$$3$1", %object
"gbass_Pat$$title$$3$1":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$2"
	.type	"gbass_Pat$$title$$3$2", %object
"gbass_Pat$$title$$3$2":
	.global	"gbass_Pat$$title$$3$2$0"
	.type	"gbass_Pat$$title$$3$2$0", %object
"gbass_Pat$$title$$3$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$3$0"
	.type	"gbass_Pat$$title$$3$3$0", %object
"gbass_Pat$$title$$3$3$0":
	.global	"gbass_Pat$$title$$3$3"
	.type	"gbass_Pat$$title$$3$3", %object
"gbass_Pat$$title$$3$3":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$4"
	.type	"gbass_Pat$$title$$3$4", %object
"gbass_Pat$$title$$3$4":
	.global	"gbass_Pat$$title$$3$4$0"
	.type	"gbass_Pat$$title$$3$4$0", %object
"gbass_Pat$$title$$3$4$0":
	.byte	0x55	@ octave 5
	.byte	0x24,0x0b	@ note E, inst 11
	.byte	0x00,0x14	@ wait 20
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x0b	@ note E, inst 11
	.byte	0x80	@ fx_off
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x0b	@ note D, inst 11
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0b	@ note C, inst 11
	.byte	0x80	@ fx_off
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x2b,0x0b	@ note B, inst 11
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x0b	@ note C, inst 11
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x0b	@ note G, inst 11
	.byte	0x00,0x14	@ wait 20
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x0b	@ note E, inst 11
	.byte	0x80	@ fx_off
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0b	@ note C, inst 11
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x0b	@ note D, inst 11
	.byte	0x0a	@ wait 10
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x1e	@ wait 30
	.byte	0x24,0x0b	@ note E, inst 11
	.byte	0x80	@ fx_off
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x0b	@ note F, inst 11
	.byte	0x00,0x14	@ wait 20
	.byte	0x21,0x0b	@ note C#, inst 11
	.byte	0x05	@ wait 5
	.byte	0x84,0x42,0x1f	@ slide_to 0x42, 31
	.byte	0x00,0x23	@ wait 35
	.byte	0x20,0x0b	@ note C, inst 11
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$5$0"
	.type	"gbass_Pat$$title$$3$5$0", %object
"gbass_Pat$$title$$3$5$0":
	.global	"gbass_Pat$$title$$3$5"
	.type	"gbass_Pat$$title$$3$5", %object
"gbass_Pat$$title$$3$5":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x24,0x10	@ note E, inst 16
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x25,0x10	@ note F, inst 16
	.byte	0x0a	@ wait 10
	.byte	0x27,0x10	@ note G, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x10	@ note C, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x10	@ note C, inst 16
	.byte	0x00,0x4b	@ wait 75
	.byte	0x4f	@ release
	.byte	0x00,0x19	@ wait 25
	.byte	0x55	@ octave 5
	.byte	0x24,0x12	@ note E, inst 18
	.byte	0x72,0x60	@ chvol 96
	.byte	0x0a	@ wait 10
	.byte	0x25,0x12	@ note F, inst 18
	.byte	0x0a	@ wait 10
	.byte	0x27,0x12	@ note G, inst 18
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x12	@ note C, inst 18
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x12	@ note C, inst 18
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x12	@ note D, inst 18
	.byte	0x00,0x28	@ wait 40
	.byte	0x24,0x12	@ note E, inst 18
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x12	@ note F, inst 18
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x12	@ note D, inst 18
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$6$0"
	.type	"gbass_Pat$$title$$3$6$0", %object
"gbass_Pat$$title$$3$6$0":
	.global	"gbass_Pat$$title$$3$6"
	.type	"gbass_Pat$$title$$3$6", %object
"gbass_Pat$$title$$3$6":
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x2b,0x0d	@ note B, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x25,0x0d	@ note F, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x25,0x0d	@ note F, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x25,0x0d	@ note F, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x25,0x0d	@ note F, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x27,0x0d	@ note G, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x2b,0x0d	@ note B, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x28,0x0d	@ note G#, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x29,0x0d	@ note A, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x2b,0x0d	@ note B, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x2b,0x0d	@ note B, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x20,0x0d	@ note C, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x22,0x0d	@ note D, inst 13
	.byte	0x0a	@ wait 10
	.byte	0x24,0x0d	@ note E, inst 13
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x0e	@ note G, inst 14
	.byte	0x05	@ wait 5
	.byte	0x26,0x0e	@ note F#, inst 14
	.byte	0x05	@ wait 5
	.byte	0x27,0x0e	@ note G, inst 14
	.byte	0x05	@ wait 5
	.byte	0x29,0x0e	@ note A, inst 14
	.byte	0x05	@ wait 5
	.byte	0x27,0x0e	@ note G, inst 14
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$7"
	.type	"gbass_Pat$$title$$3$7", %object
"gbass_Pat$$title$$3$7":
	.global	"gbass_Pat$$title$$3$7$0"
	.type	"gbass_Pat$$title$$3$7$0", %object
"gbass_Pat$$title$$3$7$0":
	.byte	0x54	@ octave 4
	.byte	0x20,0x1e	@ note C, inst 30
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x1e	@ note C, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x1e	@ note F, inst 30
	.byte	0x00,0x3c	@ wait 60
	.byte	0x55	@ octave 5
	.byte	0x25,0x1e	@ note F, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x1e	@ note E, inst 30
	.byte	0x00,0x3c	@ wait 60
	.byte	0x24,0x1e	@ note E, inst 30
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x29,0x1e	@ note A, inst 30
	.byte	0x00,0x28	@ wait 40
	.byte	0x26,0x1e	@ note F#, inst 30
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x1e	@ note G, inst 30
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x27,0x1e	@ note G, inst 30
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$8$0"
	.type	"gbass_Pat$$title$$3$8$0", %object
"gbass_Pat$$title$$3$8$0":
	.global	"gbass_Pat$$title$$3$8"
	.type	"gbass_Pat$$title$$3$8", %object
"gbass_Pat$$title$$3$8":
	.byte	0x54	@ octave 4
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x53	@ octave 3
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x26,0x06	@ note F#, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$9"
	.type	"gbass_Pat$$title$$3$9", %object
"gbass_Pat$$title$$3$9":
	.global	"gbass_Pat$$title$$3$9$0"
	.type	"gbass_Pat$$title$$3$9$0", %object
"gbass_Pat$$title$$3$9$0":
	.byte	0x54	@ octave 4
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x54	@ octave 4
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$10$0"
	.type	"gbass_Pat$$title$$3$10$0", %object
"gbass_Pat$$title$$3$10$0":
	.global	"gbass_Pat$$title$$3$10"
	.type	"gbass_Pat$$title$$3$10", %object
"gbass_Pat$$title$$3$10":
	.byte	0x55	@ octave 5
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$3$11"
	.type	"gbass_Pat$$title$$3$11", %object
"gbass_Pat$$title$$3$11":
	.global	"gbass_Pat$$title$$3$11$0"
	.type	"gbass_Pat$$title$$3$11$0", %object
"gbass_Pat$$title$$3$11$0":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x3c	@ wait 60
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2c	@ note C, inst 44
	.byte	0x0a	@ wait 10
	.byte	0x20,0x2b	@ note C, inst 43
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x2f	@ note C, inst 47
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$0"
	.type	"gbass_Pat$$title$$4$0", %object
"gbass_Pat$$title$$4$0":
	.global	"gbass_Pat$$title$$4$0$0"
	.type	"gbass_Pat$$title$$4$0$0", %object
"gbass_Pat$$title$$4$0$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$1$0"
	.type	"gbass_Pat$$title$$4$1$0", %object
"gbass_Pat$$title$$4$1$0":
	.global	"gbass_Pat$$title$$4$1"
	.type	"gbass_Pat$$title$$4$1", %object
"gbass_Pat$$title$$4$1":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$2$0"
	.type	"gbass_Pat$$title$$4$2$0", %object
"gbass_Pat$$title$$4$2$0":
	.global	"gbass_Pat$$title$$4$2"
	.type	"gbass_Pat$$title$$4$2", %object
"gbass_Pat$$title$$4$2":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$3"
	.type	"gbass_Pat$$title$$4$3", %object
"gbass_Pat$$title$$4$3":
	.global	"gbass_Pat$$title$$4$3$0"
	.type	"gbass_Pat$$title$$4$3$0", %object
"gbass_Pat$$title$$4$3$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$4$0"
	.type	"gbass_Pat$$title$$4$4$0", %object
"gbass_Pat$$title$$4$4$0":
	.global	"gbass_Pat$$title$$4$4"
	.type	"gbass_Pat$$title$$4$4", %object
"gbass_Pat$$title$$4$4":
	.byte	0x54	@ octave 4
	.byte	0x27,0x0b	@ note G, inst 11
	.byte	0x00,0x1e	@ wait 30
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x32	@ wait 50
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x0b	@ note F, inst 11
	.byte	0x80	@ fx_off
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x1e	@ wait 30
	.byte	0x84,0x43,0x1f	@ slide_to 0x43, 31
	.byte	0x0a	@ wait 10
	.byte	0x26,0x0b	@ note F#, inst 11
	.byte	0x05	@ wait 5
	.byte	0x84,0x47,0x1f	@ slide_to 0x47, 31
	.byte	0x00,0x28	@ wait 40
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x46	@ wait 70
	.byte	0x72,0x80	@ chvol 128
	.byte	0x80	@ fx_off
	.byte	0x05	@ wait 5
	.byte	0x2a,0x0b	@ note A#, inst 11
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x0a	@ wait 10
	.byte	0x84,0x48,0x1f	@ slide_to 0x48, 31
	.byte	0x0a	@ wait 10
	.byte	0x27,0x0b	@ note G, inst 11
	.byte	0x0a	@ wait 10
	.byte	0x84,0x45,0x1f	@ slide_to 0x45, 31
	.byte	0x0a	@ wait 10
	.byte	0x25,0x0b	@ note F, inst 11
	.byte	0x05	@ wait 5
	.byte	0x84,0x46,0x1f	@ slide_to 0x46, 31
	.byte	0x05	@ wait 5
	.byte	0x84,0x47,0x1f	@ slide_to 0x47, 31
	.byte	0x00,0x14	@ wait 20
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x73	@ wait 115
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$5"
	.type	"gbass_Pat$$title$$4$5", %object
"gbass_Pat$$title$$4$5":
	.global	"gbass_Pat$$title$$4$5$0"
	.type	"gbass_Pat$$title$$4$5$0", %object
"gbass_Pat$$title$$4$5$0":
	.byte	0x53	@ octave 3
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x29,0x1a	@ note A, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x29,0x1a	@ note A, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x0c	@ wait 12
	.byte	0x55	@ octave 5
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0d	@ wait 13
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0f	@ wait 15
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$6$0"
	.type	"gbass_Pat$$title$$4$6$0", %object
"gbass_Pat$$title$$4$6$0":
	.global	"gbass_Pat$$title$$4$6"
	.type	"gbass_Pat$$title$$4$6", %object
"gbass_Pat$$title$$4$6":
	.byte	0x05	@ wait 5
	.byte	0x53	@ octave 3
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x23,0x1a	@ note D#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x2a,0x1a	@ note A#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x28,0x1a	@ note G#, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x29,0x1a	@ note A, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x29,0x1a	@ note A, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x0b	@ wait 11
	.byte	0x54	@ octave 4
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x0c	@ wait 12
	.byte	0x55	@ octave 5
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x0e	@ wait 14
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$7$0"
	.type	"gbass_Pat$$title$$4$7$0", %object
"gbass_Pat$$title$$4$7$0":
	.global	"gbass_Pat$$title$$4$7"
	.type	"gbass_Pat$$title$$4$7", %object
"gbass_Pat$$title$$4$7":
	.byte	0x54	@ octave 4
	.byte	0x23,0x1e	@ note D#, inst 30
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0xa0	@ wait 160
	.byte	0x28,0x1e	@ note G#, inst 30
	.byte	0x00,0xa0	@ wait 160
	.byte	0x27,0x1e	@ note G, inst 30
	.byte	0x00,0x78	@ wait 120
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x0c	@ wait 12
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x0d	@ wait 13
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x0f	@ wait 15
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$8"
	.type	"gbass_Pat$$title$$4$8", %object
"gbass_Pat$$title$$4$8":
	.global	"gbass_Pat$$title$$4$8$0"
	.type	"gbass_Pat$$title$$4$8$0", %object
"gbass_Pat$$title$$4$8$0":
	.byte	0x54	@ octave 4
	.byte	0x2a,0x06	@ note A#, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0xa0	@ wait 160
	.byte	0x55	@ octave 5
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0xa0	@ wait 160
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$9$0"
	.type	"gbass_Pat$$title$$4$9$0", %object
"gbass_Pat$$title$$4$9$0":
	.global	"gbass_Pat$$title$$4$9"
	.type	"gbass_Pat$$title$$4$9", %object
"gbass_Pat$$title$$4$9":
	.byte	0x55	@ octave 5
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0xa0	@ wait 160
	.byte	0x23,0x06	@ note D#, inst 6
	.byte	0x00,0xa0	@ wait 160
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$10$0"
	.type	"gbass_Pat$$title$$4$10$0", %object
"gbass_Pat$$title$$4$10$0":
	.global	"gbass_Pat$$title$$4$10"
	.type	"gbass_Pat$$title$$4$10", %object
"gbass_Pat$$title$$4$10":
	.byte	0x55	@ octave 5
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0xa0	@ wait 160
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0xa0	@ wait 160
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x56	@ octave 6
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$4$11"
	.type	"gbass_Pat$$title$$4$11", %object
"gbass_Pat$$title$$4$11":
	.global	"gbass_Pat$$title$$4$11$0"
	.type	"gbass_Pat$$title$$4$11$0", %object
"gbass_Pat$$title$$4$11$0":
	.byte	0x55	@ octave 5
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0xa0	@ wait 160
	.byte	0x2a,0x06	@ note A#, inst 6
	.byte	0x00,0xa0	@ wait 160
	.byte	0x54	@ octave 4
	.byte	0x20,0x22	@ note C, inst 34
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x22	@ note D, inst 34
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x22	@ note F, inst 34
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x22	@ note G, inst 34
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$0$0"
	.type	"gbass_Pat$$title$$5$0$0", %object
"gbass_Pat$$title$$5$0$0":
	.global	"gbass_Pat$$title$$5$0"
	.type	"gbass_Pat$$title$$5$0", %object
"gbass_Pat$$title$$5$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$1"
	.type	"gbass_Pat$$title$$5$1", %object
"gbass_Pat$$title$$5$1":
	.global	"gbass_Pat$$title$$5$1$0"
	.type	"gbass_Pat$$title$$5$1$0", %object
"gbass_Pat$$title$$5$1$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$2$0"
	.type	"gbass_Pat$$title$$5$2$0", %object
"gbass_Pat$$title$$5$2$0":
	.global	"gbass_Pat$$title$$5$2"
	.type	"gbass_Pat$$title$$5$2", %object
"gbass_Pat$$title$$5$2":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$3$0"
	.type	"gbass_Pat$$title$$5$3$0", %object
"gbass_Pat$$title$$5$3$0":
	.global	"gbass_Pat$$title$$5$3"
	.type	"gbass_Pat$$title$$5$3", %object
"gbass_Pat$$title$$5$3":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$4$0"
	.type	"gbass_Pat$$title$$5$4$0", %object
"gbass_Pat$$title$$5$4$0":
	.global	"gbass_Pat$$title$$5$4"
	.type	"gbass_Pat$$title$$5$4", %object
"gbass_Pat$$title$$5$4":
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x50	@ wait 80
	.byte	0x4f	@ release
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x2b,0x01	@ note B, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x29,0x01	@ note A, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x4f	@ release
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x64	@ wait 100
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$5"
	.type	"gbass_Pat$$title$$5$5", %object
"gbass_Pat$$title$$5$5":
	.global	"gbass_Pat$$title$$5$5$0"
	.type	"gbass_Pat$$title$$5$5$0", %object
"gbass_Pat$$title$$5$5$0":
	.byte	0x56	@ octave 6
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$6$0"
	.type	"gbass_Pat$$title$$5$6$0", %object
"gbass_Pat$$title$$5$6$0":
	.global	"gbass_Pat$$title$$5$6"
	.type	"gbass_Pat$$title$$5$6", %object
"gbass_Pat$$title$$5$6":
	.byte	0x54	@ octave 4
	.byte	0x20,0x2d	@ note C, inst 45
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.byte	0x55	@ octave 5
	.byte	0x24,0x10	@ note E, inst 16
	.byte	0x72,0x90	@ chvol 144
	.byte	0x0a	@ wait 10
	.byte	0x25,0x10	@ note F, inst 16
	.byte	0x0a	@ wait 10
	.byte	0x27,0x10	@ note G, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x10	@ note C, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x11	@ note C, inst 17
	.byte	0x00,0x64	@ wait 100
	.byte	0x22,0x11	@ note D, inst 17
	.byte	0x0a	@ wait 10
	.byte	0x20,0x11	@ note C, inst 17
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x2b,0x11	@ note B, inst 17
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x11	@ note C, inst 17
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x11	@ note G, inst 17
	.byte	0x00,0x32	@ wait 50
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$7"
	.type	"gbass_Pat$$title$$5$7", %object
"gbass_Pat$$title$$5$7":
	.global	"gbass_Pat$$title$$5$7$0"
	.type	"gbass_Pat$$title$$5$7$0", %object
"gbass_Pat$$title$$5$7$0":
	.byte	0x54	@ octave 4
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x0a	@ note F, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x0a	@ note E, inst 10
	.byte	0x0a	@ wait 10
	.byte	0x25,0x0a	@ note F, inst 10
	.byte	0x0a	@ wait 10
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x24,0x0a	@ note E, inst 10
	.byte	0x80	@ fx_off
	.byte	0x0a	@ wait 10
	.byte	0x25,0x0a	@ note F, inst 10
	.byte	0x0a	@ wait 10
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0xc8	@ wait 200
	.byte	0x55	@ octave 5
	.byte	0x2b,0x0a	@ note B, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x2b,0x0a	@ note B, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x0a	@ note A, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x0a	@ note F, inst 10
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$8$0"
	.type	"gbass_Pat$$title$$5$8$0", %object
"gbass_Pat$$title$$5$8$0":
	.global	"gbass_Pat$$title$$5$8"
	.type	"gbass_Pat$$title$$5$8", %object
"gbass_Pat$$title$$5$8":
	.byte	0x53	@ octave 3
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x50	@ wait 80
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$9$0"
	.type	"gbass_Pat$$title$$5$9$0", %object
"gbass_Pat$$title$$5$9$0":
	.global	"gbass_Pat$$title$$5$9"
	.type	"gbass_Pat$$title$$5$9", %object
"gbass_Pat$$title$$5$9":
	.byte	0x54	@ octave 4
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$10"
	.type	"gbass_Pat$$title$$5$10", %object
"gbass_Pat$$title$$5$10":
	.global	"gbass_Pat$$title$$5$10$0"
	.type	"gbass_Pat$$title$$5$10$0", %object
"gbass_Pat$$title$$5$10$0":
	.byte	0x53	@ octave 3
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$5$11"
	.type	"gbass_Pat$$title$$5$11", %object
"gbass_Pat$$title$$5$11":
	.global	"gbass_Pat$$title$$5$11$0"
	.type	"gbass_Pat$$title$$5$11$0", %object
"gbass_Pat$$title$$5$11$0":
	.byte	0x55	@ octave 5
	.byte	0x20,0x2f	@ note C, inst 47
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0xa5	@ wait 165
	.byte	0x54	@ octave 4
	.byte	0x24,0x22	@ note E, inst 34
	.byte	0x0a	@ wait 10
	.byte	0x25,0x22	@ note F, inst 34
	.byte	0x0a	@ wait 10
	.byte	0x27,0x22	@ note G, inst 34
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x22	@ note C, inst 34
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x22	@ note C, inst 34
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$0$0"
	.type	"gbass_Pat$$title$$6$0$0", %object
"gbass_Pat$$title$$6$0$0":
	.global	"gbass_Pat$$title$$6$0"
	.type	"gbass_Pat$$title$$6$0", %object
"gbass_Pat$$title$$6$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$1"
	.type	"gbass_Pat$$title$$6$1", %object
"gbass_Pat$$title$$6$1":
	.global	"gbass_Pat$$title$$6$1$0"
	.type	"gbass_Pat$$title$$6$1$0", %object
"gbass_Pat$$title$$6$1$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$2$0"
	.type	"gbass_Pat$$title$$6$2$0", %object
"gbass_Pat$$title$$6$2$0":
	.global	"gbass_Pat$$title$$6$2"
	.type	"gbass_Pat$$title$$6$2", %object
"gbass_Pat$$title$$6$2":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$3$0"
	.type	"gbass_Pat$$title$$6$3$0", %object
"gbass_Pat$$title$$6$3$0":
	.global	"gbass_Pat$$title$$6$3"
	.type	"gbass_Pat$$title$$6$3", %object
"gbass_Pat$$title$$6$3":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$4$0"
	.type	"gbass_Pat$$title$$6$4$0", %object
"gbass_Pat$$title$$6$4$0":
	.global	"gbass_Pat$$title$$6$4"
	.type	"gbass_Pat$$title$$6$4", %object
"gbass_Pat$$title$$6$4":
	.byte	0x53	@ octave 3
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x0a	@ wait 10
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x64	@ wait 100
	.byte	0x54	@ octave 4
	.byte	0x24,0x04	@ note E, inst 4
	.byte	0x0a	@ wait 10
	.byte	0x25,0x04	@ note F, inst 4
	.byte	0x0a	@ wait 10
	.byte	0x27,0x04	@ note G, inst 4
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x04	@ note C, inst 4
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x04	@ note C, inst 4
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$5$0"
	.type	"gbass_Pat$$title$$6$5$0", %object
"gbass_Pat$$title$$6$5$0":
	.global	"gbass_Pat$$title$$6$5"
	.type	"gbass_Pat$$title$$6$5", %object
"gbass_Pat$$title$$6$5":
	.byte	0x56	@ octave 6
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$6$0"
	.type	"gbass_Pat$$title$$6$6$0", %object
"gbass_Pat$$title$$6$6$0":
	.global	"gbass_Pat$$title$$6$6"
	.type	"gbass_Pat$$title$$6$6", %object
"gbass_Pat$$title$$6$6":
	.byte	0x4f	@ release
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x55	@ wait 85
	.byte	0x55	@ octave 5
	.byte	0x24,0x10	@ note E, inst 16
	.byte	0x72,0x90	@ chvol 144
	.byte	0x0a	@ wait 10
	.byte	0x25,0x10	@ note F, inst 16
	.byte	0x0a	@ wait 10
	.byte	0x27,0x10	@ note G, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x10	@ note C, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x11	@ note C, inst 17
	.byte	0x00,0x41	@ wait 65
	.byte	0x72,0x40	@ chvol 64
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$7$0"
	.type	"gbass_Pat$$title$$6$7$0", %object
"gbass_Pat$$title$$6$7$0":
	.global	"gbass_Pat$$title$$6$7"
	.type	"gbass_Pat$$title$$6$7", %object
"gbass_Pat$$title$$6$7":
	.byte	0x55	@ octave 5
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x22,0x0a	@ note D, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x2b,0x0a	@ note B, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x0a	@ note G, inst 10
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x25,0x0a	@ note F, inst 10
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x0a	@ note E, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x0a	@ note D, inst 10
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x0a	@ note C, inst 10
	.byte	0x00,0x50	@ wait 80
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$8"
	.type	"gbass_Pat$$title$$6$8", %object
"gbass_Pat$$title$$6$8":
	.global	"gbass_Pat$$title$$6$8$0"
	.type	"gbass_Pat$$title$$6$8$0", %object
"gbass_Pat$$title$$6$8$0":
	.byte	0x54	@ octave 4
	.byte	0x27,0x15	@ note G, inst 21
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x1e	@ wait 30
	.byte	0x25,0x15	@ note F, inst 21
	.byte	0x0a	@ wait 10
	.byte	0x24,0x15	@ note E, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x15	@ note F, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x15	@ note G, inst 21
	.byte	0x00,0x64	@ wait 100
	.byte	0x24,0x15	@ note E, inst 21
	.byte	0x0a	@ wait 10
	.byte	0x25,0x15	@ note F, inst 21
	.byte	0x0a	@ wait 10
	.byte	0x27,0x15	@ note G, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x15	@ note C, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x15	@ note C, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x15	@ note G, inst 21
	.byte	0x0a	@ wait 10
	.byte	0x25,0x15	@ note F, inst 21
	.byte	0x0a	@ wait 10
	.byte	0x24,0x15	@ note E, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x15	@ note C, inst 21
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x27,0x15	@ note G, inst 21
	.byte	0x00,0x50	@ wait 80
	.byte	0x4f	@ release
	.byte	0x00,0xa0	@ wait 160
	.byte	0x54	@ octave 4
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$9$0"
	.type	"gbass_Pat$$title$$6$9$0", %object
"gbass_Pat$$title$$6$9$0":
	.global	"gbass_Pat$$title$$6$9"
	.type	"gbass_Pat$$title$$6$9", %object
"gbass_Pat$$title$$6$9":
	.byte	0x54	@ octave 4
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x02	@ note A, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x02	@ note D, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x02	@ note E, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x02	@ note B, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x02	@ note C, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$10$0"
	.type	"gbass_Pat$$title$$6$10$0", %object
"gbass_Pat$$title$$6$10$0":
	.global	"gbass_Pat$$title$$6$10"
	.type	"gbass_Pat$$title$$6$10", %object
"gbass_Pat$$title$$6$10":
	.byte	0x53	@ octave 3
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x03	@ note E, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x03	@ note F, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x53	@ octave 3
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x03	@ note G, inst 3
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x25,0x02	@ note F, inst 2
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x02	@ note G, inst 2
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$6$11"
	.type	"gbass_Pat$$title$$6$11", %object
"gbass_Pat$$title$$6$11":
	.global	"gbass_Pat$$title$$6$11$0"
	.type	"gbass_Pat$$title$$6$11$0", %object
"gbass_Pat$$title$$6$11$0":
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$0"
	.type	"gbass_Pat$$title$$7$0", %object
"gbass_Pat$$title$$7$0":
	.global	"gbass_Pat$$title$$7$0$0"
	.type	"gbass_Pat$$title$$7$0$0", %object
"gbass_Pat$$title$$7$0$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$1"
	.type	"gbass_Pat$$title$$7$1", %object
"gbass_Pat$$title$$7$1":
	.global	"gbass_Pat$$title$$7$1$0"
	.type	"gbass_Pat$$title$$7$1$0", %object
"gbass_Pat$$title$$7$1$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$2"
	.type	"gbass_Pat$$title$$7$2", %object
"gbass_Pat$$title$$7$2":
	.global	"gbass_Pat$$title$$7$2$0"
	.type	"gbass_Pat$$title$$7$2$0", %object
"gbass_Pat$$title$$7$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$3$0"
	.type	"gbass_Pat$$title$$7$3$0", %object
"gbass_Pat$$title$$7$3$0":
	.global	"gbass_Pat$$title$$7$3"
	.type	"gbass_Pat$$title$$7$3", %object
"gbass_Pat$$title$$7$3":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$4$0"
	.type	"gbass_Pat$$title$$7$4$0", %object
"gbass_Pat$$title$$7$4$0":
	.global	"gbass_Pat$$title$$7$4"
	.type	"gbass_Pat$$title$$7$4", %object
"gbass_Pat$$title$$7$4":
	.byte	0x00,0xa0	@ wait 160
	.byte	0x55	@ octave 5
	.byte	0x20,0x14	@ note C, inst 20
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x14	@ note D, inst 20
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$5"
	.type	"gbass_Pat$$title$$7$5", %object
"gbass_Pat$$title$$7$5":
	.global	"gbass_Pat$$title$$7$5$0"
	.type	"gbass_Pat$$title$$7$5$0", %object
"gbass_Pat$$title$$7$5$0":
	.byte	0x00,0xa0	@ wait 160
	.byte	0x54	@ octave 4
	.byte	0x29,0x12	@ note A, inst 18
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x12	@ note B, inst 18
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$6$0"
	.type	"gbass_Pat$$title$$7$6$0", %object
"gbass_Pat$$title$$7$6$0":
	.global	"gbass_Pat$$title$$7$6"
	.type	"gbass_Pat$$title$$7$6", %object
"gbass_Pat$$title$$7$6":
	.byte	0x54	@ octave 4
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x78	@ wait 120
	.byte	0x25,0x10	@ note F, inst 16
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x10	@ note G, inst 16
	.byte	0x00,0x14	@ wait 20
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$7$0"
	.type	"gbass_Pat$$title$$7$7$0", %object
"gbass_Pat$$title$$7$7$0":
	.global	"gbass_Pat$$title$$7$7"
	.type	"gbass_Pat$$title$$7$7", %object
"gbass_Pat$$title$$7$7":
	.byte	0x54	@ octave 4
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0xc3	@ wait 195
	.byte	0x55	@ octave 5
	.byte	0x27,0x20	@ note G, inst 32
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$8$0"
	.type	"gbass_Pat$$title$$7$8$0", %object
"gbass_Pat$$title$$7$8$0":
	.global	"gbass_Pat$$title$$7$8"
	.type	"gbass_Pat$$title$$7$8", %object
"gbass_Pat$$title$$7$8":
	.byte	0x54	@ octave 4
	.byte	0x20,0x09	@ note C, inst 9
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x09	@ note D, inst 9
	.byte	0x00,0xc8	@ wait 200
	.byte	0x56	@ octave 6
	.byte	0x27,0x21	@ note G, inst 33
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$9$0"
	.type	"gbass_Pat$$title$$7$9$0", %object
"gbass_Pat$$title$$7$9$0":
	.global	"gbass_Pat$$title$$7$9"
	.type	"gbass_Pat$$title$$7$9", %object
"gbass_Pat$$title$$7$9":
	.byte	0x00,0x50	@ wait 80
	.byte	0x54	@ octave 4
	.byte	0x25,0x0e	@ note F, inst 14
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x0e	@ note G, inst 14
	.byte	0x00,0xa0	@ wait 160
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$10$0"
	.type	"gbass_Pat$$title$$7$10$0", %object
"gbass_Pat$$title$$7$10$0":
	.global	"gbass_Pat$$title$$7$10"
	.type	"gbass_Pat$$title$$7$10", %object
"gbass_Pat$$title$$7$10":
	.byte	0x00,0x50	@ wait 80
	.byte	0x54	@ octave 4
	.byte	0x29,0x0e	@ note A, inst 14
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x0e	@ note B, inst 14
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$7$11$0"
	.type	"gbass_Pat$$title$$7$11$0", %object
"gbass_Pat$$title$$7$11$0":
	.global	"gbass_Pat$$title$$7$11"
	.type	"gbass_Pat$$title$$7$11", %object
"gbass_Pat$$title$$7$11":
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x0e	@ note C, inst 14
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x0e	@ note D, inst 14
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$0"
	.type	"gbass_Pat$$title$$8$0", %object
"gbass_Pat$$title$$8$0":
	.global	"gbass_Pat$$title$$8$0$0"
	.type	"gbass_Pat$$title$$8$0$0", %object
"gbass_Pat$$title$$8$0$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$1"
	.type	"gbass_Pat$$title$$8$1", %object
"gbass_Pat$$title$$8$1":
	.global	"gbass_Pat$$title$$8$1$0"
	.type	"gbass_Pat$$title$$8$1$0", %object
"gbass_Pat$$title$$8$1$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$2"
	.type	"gbass_Pat$$title$$8$2", %object
"gbass_Pat$$title$$8$2":
	.global	"gbass_Pat$$title$$8$2$0"
	.type	"gbass_Pat$$title$$8$2$0", %object
"gbass_Pat$$title$$8$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$3"
	.type	"gbass_Pat$$title$$8$3", %object
"gbass_Pat$$title$$8$3":
	.global	"gbass_Pat$$title$$8$3$0"
	.type	"gbass_Pat$$title$$8$3$0", %object
"gbass_Pat$$title$$8$3$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$4$0"
	.type	"gbass_Pat$$title$$8$4$0", %object
"gbass_Pat$$title$$8$4$0":
	.global	"gbass_Pat$$title$$8$4"
	.type	"gbass_Pat$$title$$8$4", %object
"gbass_Pat$$title$$8$4":
	.byte	0x55	@ octave 5
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x72,0x40	@ chvol 64
	.byte	0x00,0xc8	@ wait 200
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x78	@ wait 120
	.byte	0x24,0x01	@ note E, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x00,0x73	@ wait 115
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$5"
	.type	"gbass_Pat$$title$$8$5", %object
"gbass_Pat$$title$$8$5":
	.global	"gbass_Pat$$title$$8$5$0"
	.type	"gbass_Pat$$title$$8$5$0", %object
"gbass_Pat$$title$$8$5$0":
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x27,0x21	@ note G, inst 33
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0xa0	@ wait 160
	.byte	0x27,0x21	@ note G, inst 33
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$6"
	.type	"gbass_Pat$$title$$8$6", %object
"gbass_Pat$$title$$8$6":
	.global	"gbass_Pat$$title$$8$6$0"
	.type	"gbass_Pat$$title$$8$6$0", %object
"gbass_Pat$$title$$8$6$0":
	.byte	0x54	@ octave 4
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x08	@ note E, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x07	@ note C, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x07	@ note D, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x08	@ note F, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x07	@ note E, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x07	@ note F, inst 7
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$7$0"
	.type	"gbass_Pat$$title$$8$7$0", %object
"gbass_Pat$$title$$8$7$0":
	.global	"gbass_Pat$$title$$8$7"
	.type	"gbass_Pat$$title$$8$7", %object
"gbass_Pat$$title$$8$7":
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x55	@ octave 5
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x08	@ note G, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x08	@ note A, inst 8
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x08	@ note B, inst 8
	.byte	0x00,0x3c	@ wait 60
	.byte	0x55	@ octave 5
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x14	@ wait 20
	.byte	0x20,0x08	@ note C, inst 8
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$8$0"
	.type	"gbass_Pat$$title$$8$8$0", %object
"gbass_Pat$$title$$8$8$0":
	.global	"gbass_Pat$$title$$8$8"
	.type	"gbass_Pat$$title$$8$8", %object
"gbass_Pat$$title$$8$8":
	.byte	0x55	@ octave 5
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x55	@ octave 5
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x54	@ octave 4
	.byte	0x2b,0x06	@ note B, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x06	@ note A, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$9$0"
	.type	"gbass_Pat$$title$$8$9$0", %object
"gbass_Pat$$title$$8$9$0":
	.global	"gbass_Pat$$title$$8$9"
	.type	"gbass_Pat$$title$$8$9", %object
"gbass_Pat$$title$$8$9":
	.byte	0x55	@ octave 5
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x22,0x06	@ note D, inst 6
	.byte	0x00,0x50	@ wait 80
	.byte	0x20,0x06	@ note C, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$10$0"
	.type	"gbass_Pat$$title$$8$10$0", %object
"gbass_Pat$$title$$8$10$0":
	.global	"gbass_Pat$$title$$8$10"
	.type	"gbass_Pat$$title$$8$10", %object
"gbass_Pat$$title$$8$10":
	.byte	0x55	@ octave 5
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x78	@ wait 120
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x50	@ wait 80
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x24,0x06	@ note E, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x06	@ note G, inst 6
	.byte	0x00,0x78	@ wait 120
	.byte	0x25,0x06	@ note F, inst 6
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$8$11$0"
	.type	"gbass_Pat$$title$$8$11$0", %object
"gbass_Pat$$title$$8$11$0":
	.global	"gbass_Pat$$title$$8$11"
	.type	"gbass_Pat$$title$$8$11", %object
"gbass_Pat$$title$$8$11":
	.byte	0x54	@ octave 4
	.byte	0x20,0x2d	@ note C, inst 45
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$0$0"
	.type	"gbass_Pat$$title$$9$0$0", %object
"gbass_Pat$$title$$9$0$0":
	.global	"gbass_Pat$$title$$9$0"
	.type	"gbass_Pat$$title$$9$0", %object
"gbass_Pat$$title$$9$0":
	.byte	0x00,0xa0	@ wait 160
	.byte	0x56	@ octave 6
	.byte	0x25,0x31	@ note F, inst 49
	.byte	0x72,0x50	@ chvol 80
	.byte	0x00,0x14	@ wait 20
	.byte	0x85,0x39	@ vibrato 0x39
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x31	@ note G, inst 49
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x31	@ note A, inst 49
	.byte	0x72,0x70	@ chvol 112
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x31	@ note B, inst 49
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x33	@ wait 51
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$1$0"
	.type	"gbass_Pat$$title$$9$1$0", %object
"gbass_Pat$$title$$9$1$0":
	.global	"gbass_Pat$$title$$9$1"
	.type	"gbass_Pat$$title$$9$1", %object
"gbass_Pat$$title$$9$1":
	.byte	0x54	@ octave 4
	.byte	0x29,0x35	@ note A, inst 53
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x55	@ octave 5
	.byte	0x20,0x35	@ note C, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x25,0x35	@ note F, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x29,0x35	@ note A, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x22,0x35	@ note D, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x27,0x35	@ note G, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x2b,0x35	@ note B, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x35	@ note D, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x20,0x35	@ note C, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x25,0x35	@ note F, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x29,0x35	@ note A, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x57	@ octave 7
	.byte	0x20,0x35	@ note C, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x56	@ octave 6
	.byte	0x22,0x35	@ note D, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x27,0x35	@ note G, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x2b,0x35	@ note B, inst 53
	.byte	0x0a	@ wait 10
	.byte	0x57	@ octave 7
	.byte	0x22,0x35	@ note D, inst 53
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$2"
	.type	"gbass_Pat$$title$$9$2", %object
"gbass_Pat$$title$$9$2":
	.global	"gbass_Pat$$title$$9$2$0"
	.type	"gbass_Pat$$title$$9$2$0", %object
"gbass_Pat$$title$$9$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$3"
	.type	"gbass_Pat$$title$$9$3", %object
"gbass_Pat$$title$$9$3":
	.global	"gbass_Pat$$title$$9$3$0"
	.type	"gbass_Pat$$title$$9$3$0", %object
"gbass_Pat$$title$$9$3$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$4$0"
	.type	"gbass_Pat$$title$$9$4$0", %object
"gbass_Pat$$title$$9$4$0":
	.global	"gbass_Pat$$title$$9$4"
	.type	"gbass_Pat$$title$$9$4", %object
"gbass_Pat$$title$$9$4":
	.byte	0x54	@ octave 4
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x00,0xff	@ wait 255
	.byte	0x00,0x19	@ wait 25
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x0c	@ wait 12
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x0e	@ wait 14
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x00,0x10	@ wait 16
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$5"
	.type	"gbass_Pat$$title$$9$5", %object
"gbass_Pat$$title$$9$5":
	.global	"gbass_Pat$$title$$9$5$0"
	.type	"gbass_Pat$$title$$9$5$0", %object
"gbass_Pat$$title$$9$5$0":
	.byte	0x53	@ octave 3
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x29,0x1a	@ note A, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x29,0x0b	@ note A, inst 11
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x0b	@ note B, inst 11
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x0b	@ note C, inst 11
	.byte	0x72,0xc0	@ chvol 192
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x0b	@ note D, inst 11
	.byte	0x72,0xe0	@ chvol 224
	.byte	0x00,0x33	@ wait 51
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$6$0"
	.type	"gbass_Pat$$title$$9$6$0", %object
"gbass_Pat$$title$$9$6$0":
	.global	"gbass_Pat$$title$$9$6"
	.type	"gbass_Pat$$title$$9$6", %object
"gbass_Pat$$title$$9$6":
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x53	@ octave 3
	.byte	0x29,0x1a	@ note A, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x54	@ octave 4
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x22,0x1a	@ note D, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x25,0x1a	@ note F, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x20,0x1a	@ note C, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x55	@ octave 5
	.byte	0x2b,0x1a	@ note B, inst 26
	.byte	0x00,0x14	@ wait 20
	.byte	0x56	@ octave 6
	.byte	0x27,0x1a	@ note G, inst 26
	.byte	0x0a	@ wait 10
	.byte	0x54	@ octave 4
	.byte	0x25,0x22	@ note F, inst 34
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x22	@ note G, inst 34
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x22	@ note A, inst 34
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x22	@ note B, inst 34
	.byte	0x00,0x33	@ wait 51
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$7$0"
	.type	"gbass_Pat$$title$$9$7$0", %object
"gbass_Pat$$title$$9$7$0":
	.global	"gbass_Pat$$title$$9$7"
	.type	"gbass_Pat$$title$$9$7", %object
"gbass_Pat$$title$$9$7":
	.byte	0x54	@ octave 4
	.byte	0x27,0x05	@ note G, inst 5
	.byte	0x72,0x40	@ chvol 64
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0x50	@ chvol 80
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0x70	@ chvol 112
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0x90	@ chvol 144
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0xb0	@ chvol 176
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0xc0	@ chvol 192
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0xd0	@ chvol 208
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0xe0	@ chvol 224
	.byte	0x00,0x14	@ wait 20
	.byte	0x72,0xf0	@ chvol 240
	.byte	0x00,0x6f	@ wait 111
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$8"
	.type	"gbass_Pat$$title$$9$8", %object
"gbass_Pat$$title$$9$8":
	.global	"gbass_Pat$$title$$9$8$0"
	.type	"gbass_Pat$$title$$9$8$0", %object
"gbass_Pat$$title$$9$8$0":
	.byte	0x54	@ octave 4
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x72,0x40	@ chvol 64
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x00	@ note B, inst 0
	.byte	0x72,0x50	@ chvol 80
	.byte	0x00,0x28	@ wait 40
	.byte	0x55	@ octave 5
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x00	@ note D, inst 0
	.byte	0x72,0x70	@ chvol 112
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x72,0x90	@ chvol 144
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x00	@ note B, inst 0
	.byte	0x72,0xb0	@ chvol 176
	.byte	0x00,0x33	@ wait 51
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$9$0"
	.type	"gbass_Pat$$title$$9$9$0", %object
"gbass_Pat$$title$$9$9$0":
	.global	"gbass_Pat$$title$$9$9"
	.type	"gbass_Pat$$title$$9$9", %object
"gbass_Pat$$title$$9$9":
	.byte	0x55	@ octave 5
	.byte	0x20,0x00	@ note C, inst 0
	.byte	0x72,0x40	@ chvol 64
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x00	@ note D, inst 0
	.byte	0x72,0x50	@ chvol 80
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x72,0x70	@ chvol 112
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x00	@ note B, inst 0
	.byte	0x72,0x90	@ chvol 144
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x72,0xb0	@ chvol 176
	.byte	0x00,0x33	@ wait 51
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$10"
	.type	"gbass_Pat$$title$$9$10", %object
"gbass_Pat$$title$$9$10":
	.global	"gbass_Pat$$title$$9$10$0"
	.type	"gbass_Pat$$title$$9$10$0", %object
"gbass_Pat$$title$$9$10$0":
	.byte	0x55	@ octave 5
	.byte	0x25,0x00	@ note F, inst 0
	.byte	0x72,0x40	@ chvol 64
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x00	@ note G, inst 0
	.byte	0x72,0x50	@ chvol 80
	.byte	0x00,0x28	@ wait 40
	.byte	0x29,0x00	@ note A, inst 0
	.byte	0x72,0x60	@ chvol 96
	.byte	0x00,0x28	@ wait 40
	.byte	0x2b,0x00	@ note B, inst 0
	.byte	0x72,0x70	@ chvol 112
	.byte	0x00,0x28	@ wait 40
	.byte	0x20,0x01	@ note C, inst 1
	.byte	0x72,0x80	@ chvol 128
	.byte	0x00,0x28	@ wait 40
	.byte	0x22,0x01	@ note D, inst 1
	.byte	0x72,0x90	@ chvol 144
	.byte	0x00,0x28	@ wait 40
	.byte	0x25,0x01	@ note F, inst 1
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x28	@ wait 40
	.byte	0x27,0x01	@ note G, inst 1
	.byte	0x72,0xb0	@ chvol 176
	.byte	0x00,0x33	@ wait 51
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$9$11$0"
	.type	"gbass_Pat$$title$$9$11$0", %object
"gbass_Pat$$title$$9$11$0":
	.global	"gbass_Pat$$title$$9$11"
	.type	"gbass_Pat$$title$$9$11", %object
"gbass_Pat$$title$$9$11":
	.byte	0x55	@ octave 5
	.byte	0x20,0x2f	@ note C, inst 47
	.byte	0x00,0xa0	@ wait 160
	.byte	0x53	@ octave 3
	.byte	0x25,0x30	@ note F, inst 48
	.byte	0x72,0x80	@ chvol 128
	.byte	0x05	@ wait 5
	.byte	0x29,0x30	@ note A, inst 48
	.byte	0x05	@ wait 5
	.byte	0x54	@ octave 4
	.byte	0x20,0x30	@ note C, inst 48
	.byte	0x05	@ wait 5
	.byte	0x25,0x30	@ note F, inst 48
	.byte	0x05	@ wait 5
	.byte	0x29,0x30	@ note A, inst 48
	.byte	0x05	@ wait 5
	.byte	0x55	@ octave 5
	.byte	0x20,0x30	@ note C, inst 48
	.byte	0x05	@ wait 5
	.byte	0x25,0x30	@ note F, inst 48
	.byte	0x05	@ wait 5
	.byte	0x29,0x30	@ note A, inst 48
	.byte	0x05	@ wait 5
	.byte	0x53	@ octave 3
	.byte	0x27,0x30	@ note G, inst 48
	.byte	0x05	@ wait 5
	.byte	0x2b,0x30	@ note B, inst 48
	.byte	0x05	@ wait 5
	.byte	0x54	@ octave 4
	.byte	0x22,0x30	@ note D, inst 48
	.byte	0x05	@ wait 5
	.byte	0x27,0x30	@ note G, inst 48
	.byte	0x05	@ wait 5
	.byte	0x2b,0x30	@ note B, inst 48
	.byte	0x05	@ wait 5
	.byte	0x55	@ octave 5
	.byte	0x22,0x30	@ note D, inst 48
	.byte	0x05	@ wait 5
	.byte	0x27,0x30	@ note G, inst 48
	.byte	0x05	@ wait 5
	.byte	0x2b,0x30	@ note B, inst 48
	.byte	0x05	@ wait 5
	.byte	0x53	@ octave 3
	.byte	0x29,0x30	@ note A, inst 48
	.byte	0x05	@ wait 5
	.byte	0x54	@ octave 4
	.byte	0x20,0x30	@ note C, inst 48
	.byte	0x05	@ wait 5
	.byte	0x25,0x30	@ note F, inst 48
	.byte	0x05	@ wait 5
	.byte	0x29,0x30	@ note A, inst 48
	.byte	0x05	@ wait 5
	.byte	0x55	@ octave 5
	.byte	0x20,0x30	@ note C, inst 48
	.byte	0x05	@ wait 5
	.byte	0x25,0x30	@ note F, inst 48
	.byte	0x05	@ wait 5
	.byte	0x29,0x30	@ note A, inst 48
	.byte	0x05	@ wait 5
	.byte	0x56	@ octave 6
	.byte	0x20,0x30	@ note C, inst 48
	.byte	0x05	@ wait 5
	.byte	0x53	@ octave 3
	.byte	0x2b,0x30	@ note B, inst 48
	.byte	0x06	@ wait 6
	.byte	0x54	@ octave 4
	.byte	0x22,0x30	@ note D, inst 48
	.byte	0x06	@ wait 6
	.byte	0x27,0x30	@ note G, inst 48
	.byte	0x07	@ wait 7
	.byte	0x2b,0x30	@ note B, inst 48
	.byte	0x07	@ wait 7
	.byte	0x55	@ octave 5
	.byte	0x22,0x30	@ note D, inst 48
	.byte	0x00,0x19	@ wait 25
	.byte	0x4f	@ release
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$0$0"
	.type	"gbass_Pat$$title$$10$0$0", %object
"gbass_Pat$$title$$10$0$0":
	.global	"gbass_Pat$$title$$10$0"
	.type	"gbass_Pat$$title$$10$0", %object
"gbass_Pat$$title$$10$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$1$0"
	.type	"gbass_Pat$$title$$10$1$0", %object
"gbass_Pat$$title$$10$1$0":
	.global	"gbass_Pat$$title$$10$1"
	.type	"gbass_Pat$$title$$10$1", %object
"gbass_Pat$$title$$10$1":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$2"
	.type	"gbass_Pat$$title$$10$2", %object
"gbass_Pat$$title$$10$2":
	.global	"gbass_Pat$$title$$10$2$0"
	.type	"gbass_Pat$$title$$10$2$0", %object
"gbass_Pat$$title$$10$2$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$3$0"
	.type	"gbass_Pat$$title$$10$3$0", %object
"gbass_Pat$$title$$10$3$0":
	.global	"gbass_Pat$$title$$10$3"
	.type	"gbass_Pat$$title$$10$3", %object
"gbass_Pat$$title$$10$3":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$4"
	.type	"gbass_Pat$$title$$10$4", %object
"gbass_Pat$$title$$10$4":
	.global	"gbass_Pat$$title$$10$4$0"
	.type	"gbass_Pat$$title$$10$4$0", %object
"gbass_Pat$$title$$10$4$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$5$0"
	.type	"gbass_Pat$$title$$10$5$0", %object
"gbass_Pat$$title$$10$5$0":
	.global	"gbass_Pat$$title$$10$5"
	.type	"gbass_Pat$$title$$10$5", %object
"gbass_Pat$$title$$10$5":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$6$0"
	.type	"gbass_Pat$$title$$10$6$0", %object
"gbass_Pat$$title$$10$6$0":
	.global	"gbass_Pat$$title$$10$6"
	.type	"gbass_Pat$$title$$10$6", %object
"gbass_Pat$$title$$10$6":
	.byte	0x54	@ octave 4
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x72,0x80	@ chvol 128
	.byte	0x0a	@ wait 10
	.byte	0x27,0x2d	@ note G, inst 45
	.byte	0x72,0xa0	@ chvol 160
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$7"
	.type	"gbass_Pat$$title$$10$7", %object
"gbass_Pat$$title$$10$7":
	.global	"gbass_Pat$$title$$10$7$0"
	.type	"gbass_Pat$$title$$10$7$0", %object
"gbass_Pat$$title$$10$7$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$8"
	.type	"gbass_Pat$$title$$10$8", %object
"gbass_Pat$$title$$10$8":
	.global	"gbass_Pat$$title$$10$8$0"
	.type	"gbass_Pat$$title$$10$8$0", %object
"gbass_Pat$$title$$10$8$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$9$0"
	.type	"gbass_Pat$$title$$10$9$0", %object
"gbass_Pat$$title$$10$9$0":
	.global	"gbass_Pat$$title$$10$9"
	.type	"gbass_Pat$$title$$10$9", %object
"gbass_Pat$$title$$10$9":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$10"
	.type	"gbass_Pat$$title$$10$10", %object
"gbass_Pat$$title$$10$10":
	.global	"gbass_Pat$$title$$10$10$0"
	.type	"gbass_Pat$$title$$10$10$0", %object
"gbass_Pat$$title$$10$10$0":
	.byte	0x00,0x00	@ end
	.global	"gbass_Pat$$title$$10$11"
	.type	"gbass_Pat$$title$$10$11", %object
"gbass_Pat$$title$$10$11":
	.global	"gbass_Pat$$title$$10$11$0"
	.type	"gbass_Pat$$title$$10$11$0", %object
"gbass_Pat$$title$$10$11$0":
	.byte	0x00,0x00	@ end
	.global	gbass_DigiBufferModes
	.type	gbass_DigiBufferModes, %object
gbass_DigiBufferModes:
	.byte	1,1,0,0	@ per mix buffer: bit0 stereo (two pairs: left, right), bit3 use mixer slot +28
@ gbass_module -- see header
	.global	gbass_module
	.type	gbass_module, %object
gbass_module:
	.4byte	4	@ +00 default rate (4 = 256 samples/frame)
	.4byte	1	@ +04 songs
	.4byte	gbass_SongTable
	.4byte	59	@ +0C instruments
	.4byte	gbass_InstrumentTable
	.4byte	gbass_InstrumentTypeTable
	.4byte	50	@ +18 waves
	.4byte	gbass_WaveTable
	.4byte	4	@ +20 digital channel pairs
	.4byte	gbass_DigiMixersMusicRam
	.4byte	gbass_DigiMixersSFXRam
	.4byte	gbass_DigiPlayerPairRam
	.4byte	2	@ +30 mix buffers
	.4byte	gbass_DigiBufferRam
	.4byte	gbass_DigiBufferModes
	.4byte	gbass_GBPlayerPairRam
	.4byte	gbass_DMABufferRam
	.4byte	gbass_SilenceRam
	.4byte	gbass_MixProcRam
	.4byte	15	@ +4C Mix_Table copy mask

	.section .slowram,"aw",%progbits
	.align	2
	.type	SOUNDCNT_H, %object
SOUNDCNT_H:
	.byte	0x00,0x00
	.type	dma, %object
dma:
	.byte	0x00,0x00
	.type	dmaintenable, %object
dmaintenable:
	.byte	0x00,0x00
	.type	timer, %object
timer:
	.byte	0x00,0x00
	.type	rate, %object
rate:
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.global	gbass_ram
	.type	gbass_ram, %object
gbass_ram:
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.global	gbass_DigiPlayerPairRam
	.type	gbass_DigiPlayerPairRam, %object
gbass_DigiPlayerPairRam:
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.global	gbass_GBPlayerPairRam
	.type	gbass_GBPlayerPairRam, %object
gbass_GBPlayerPairRam:
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.byte	0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00
	.size	SOUNDCNT_H, 2
	.size	dma, 2
	.size	dmaintenable, 2
	.size	timer, 2
	.size	rate, 8

	.section .medram3,"aw",%nobits
	.align	2
	.global	gbass_DigiMixersSFXRam
	.type	gbass_DigiMixersSFXRam, %object
gbass_DigiMixersSFXRam:
	@ Mixer[8] sound-effect mixers
	.space	0x100

	.section .medram2,"aw",%nobits
	.align	2
	.global	gbass_DigiMixersMusicRam
	.type	gbass_DigiMixersMusicRam, %object
gbass_DigiMixersMusicRam:
	@ Mixer[8] music mixers
	.space	0x100

	.section .medram1,"aw",%nobits
	.align	2
	.global	gbass_DigiBufferRam
	.type	gbass_DigiBufferRam, %object
gbass_DigiBufferRam:
	@ s8[2][64] mix buffers
	.space	0x80

	.section .fastram,"aw",%nobits
	.align	2
	.global	gbass_SilenceRam
	.type	gbass_SilenceRam, %object
gbass_SilenceRam:
	@ u32 silence (idle script pointer target)
	.space	0x4
	.global	gbass_DMABufferRam
	.type	gbass_DMABufferRam, %object
gbass_DMABufferRam:
	@ s8[4][256] DMA double buffer: L0 L1 R0 R1 (rate*64 each)
	.space	0x400
	.global	gbass_MixProcRam
	.type	gbass_MixProcRam, %object
gbass_MixProcRam:
	@ IWRAM copies of the ARM routines (0x260 bytes)
	.space	0x260

	.end
