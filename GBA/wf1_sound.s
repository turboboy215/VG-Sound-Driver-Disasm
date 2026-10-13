@ ============================================================================================
@ wf1_sound.s -- Webfoot Technologies GBA sound engine, version 1
@                as shipped in Dragon Ball Z: The Legacy of Goku (GBA, 2002), ROM ALGP (E) (M5)
@
@ Reconstructed by disassembly. Assembles with   arm-none-eabi-as -mcpu=arm7tdmi
@ and, linked with wf1.ld, rebuilds the three code ranges of the ROM byte for byte:
@     .wf1_mix     0x080089EC-0x08008D4C   ARM mixing loops (copied to IWRAM at run time) + DMA2 IRQ
@     .wf1_player  0x08009CCC-0x0800A910   S3M-style pattern player (Thumb, compiled C)
@     .wf1_sound   0x0800A9F4-0x0800B0BC   voices, software mixer front end, SFX API (Thumb, compiled C)
@ The tables the code reads are in wf1_rodata.s, the music/SFX data in wf1_data.s.
@ All names are invented; the ROM carries no symbols.
@
@ ---- RAM -----------------------------------------------------------------------------------
@ mus  0x03003CF8  (20 bytes)  pattern-player state
@      +00 u8 playing   +01 u8 row      +02 u8 rows(in pattern)   +03 u8 tick(ticks left in row)
@      +04 u8 speed     +05 u8 tempo    +06 s16 order position
@      +08 u16 samples per tick         +0A u16 samples left before the next tick
@      +0C song*        +10 u8* pattern read pointer
@ snd  0x03003D28  (28 bytes)  mixer state
@      +00 u8 music bus volume (default 4)   +01 u8 sfx bus volume (default 8)   +02 u16 mix rate
@      +04 s16 samples in the current chunk  +08 u32 play position (IRQ adds 16)  +0C u32 write position
@      +10 u32 pitch constant ceil(2^26/rate) +14 u32 busy flag  +18 output routine (IWRAM Mix_Output)
@ 0x03003D44-0x03004018  IWRAM copies of Mix_Side/Mix_Centre/Mix_Stereo/Mix_Output
@ 0x03004018  mix buffer, 256 stereo frames of s32 (L,R interleaved)
@ 0x0203EE24  music channels, 15 x 36 bytes
@      +00 u32 pitch factor (NoteFreqTab units)   +04 u32 tone-portamento target
@      +08 s8 volume 0..64   +09 s8 panning -64..+64
@      +0A u8 flags: bits0-1 tick mode (0 none, 1 while note sounds, 2 always), bit2 note sounding,
@                    bit3 portamento target valid
@      +0B u8 current slide step   +0C u8 D memory   +0D u8 E/F/G memory   +0E u8 Q memory
@      +0F u8 vibrato speed  +10 u8 vibrato depth  +11 u8 vibrato phase (6 bits)  +12 u8 retrig/delay counter
@      +14 tick handler (Thumb)
@      +18 u8 mask of this row  +19 u8 channel's last explicit mask
@      +1A note  +1B instrument  +1C volume  +1D effect  +1E parameter   (last values read for this channel)
@      +1F u8 cleared on reset, never read     +20 voice*
@ 0x0203F040  music voices, 15 x 64 bytes      0x0203F400  sfx voices, 16 x 64 bytes
@      +00 u32 position (18.14 fixed point, bytes)   +04 s32 step (negative while a ping-pong loop runs back)
@      +08 s8* sample data
@      +0C u8 flags: bit0 active, bit1 recompute step, bit2 restart at 0, bit3 reload sample header,
@                    bit4 recompute volume/pan  (0x1F = start everything)
@      +0D u8 loop state: bit0 looped, bit1 ping-pong, bit2 currently running backwards
@      +0E u8 volume A  +0F u8 volume B / side   (meaning depends on the chosen mix routine, see Voice_Update)
@      +10 u8 volume 0..64   +11 s8 panning -64..+64   +12 u16 sample rate (Hz)
@      +14 mix routine       +18 u32 |step|   +1C loop start (18.14)   +20 loop end = length (18.14)
@      +24 sample header*    +28 owning music channel* (0 for sfx)   +2C u32 pitch factor (16384 = native)
@      +30 u8 bus volume
@ 0x0203F800 / 0x0203FC00  1024-byte s8 rings for DirectSound A (left) and B (right)
@ ============================================================================================

@ symbols defined in the other source files of this set:
@   NoteFreqTab            0x080113A8
@   PortaUpTab             0x08011608
@   PortaDownTab           0x08011888
@   VibratoSine            0x08011A88
@   TonePortaVolTicks      0x08011AC8
@   RowMaskTab             0x08142518
@   FxTab                  0x0818CDF8
@   wf1_MusInstrTab        0x085B8258
@   wf1_SfxTab             0x085E6F18

	.syntax unified
	.equ IntrWait, 0x08009C62
	.equ __call_via_r0, 0x0800E8D8
	.equ __call_via_r1, 0x0800E8DA
	.equ __call_via_r3, 0x0800E8DE
	.equ __call_via_r7, 0x0800E8E6
	.equ __rt_udiv, 0x0800EA78
	.equ DMA_FIFO_RESTART, 0xF6400004
	.equ IntrTable_DMA2_quirk, 0x03003BAF
	.equ REG_DMA1SAD, 0x040000BC
	.equ REG_DMA2SAD, 0x040000C8
	.equ REG_DMA3SAD, 0x040000D4
	.equ REG_FIFO_A, 0x040000A0
	.equ REG_FIFO_B, 0x040000A4
	.equ REG_IE, 0x04000200
	.equ REG_SOUNDCNT_L, 0x04000080
	.equ REG_TM0CNT_L, 0x04000100
	.equ iw_Mix_Side, 0x03003D44
	.equ iw_Mix_Stereo, 0x03003EC0
	.equ mus, 0x03003CF8
	.equ mus_chan, 0x0203EE24
	.equ mus_chan_0C, 0x0203EE30
	.equ mus_chan_1C, 0x0203EE40
	.equ mus_order, 0x03003CFE
	.equ mus_row, 0x03003CF9
	.equ mus_rows, 0x03003CFA
	.equ mus_speed, 0x03003CFC
	.equ mus_voice, 0x0203F040
	.equ ring_L, 0x0203F800
	.equ ring_L_512, 0x0203FA00
	.equ ring_R, 0x0203FC00
	.equ ring_R_512, 0x0203FE00
	.equ sfx_voice, 0x0203F400
	.equ snd, 0x03003D28
	.equ snd_busy, 0x03003D3C
	.equ snd_chunk, 0x03003D2C
	.equ snd_mixbuf, 0x03004018
	.equ snd_playpos, 0x03003D30
	.equ snd_rate, 0x03003D2A
	.equ snd_writepos, 0x03003D34
	.equ zero_word, 0x03004CB8


	.section .wf1_mix, "ax"
	.p2align 2
	.arm

@ --------------------------------------------------------------------------------------------
@ void Mix_Side(Voice *v, s32 *buf, int n)            [runs from IWRAM 0x03003D44]
@ Adds n samples of voice v into one side of the interleaved s32 stereo buffer:
@ buf[2*i + side] += sample * vol, side = v->volB (0 left, 1 right), vol = v->volA.
@ Resampling is nearest-sample: pos is 18.14 fixed point, the integer part indexes the sample.
@ Entry is a computed jump into a 4x unrolled loop so any n works.
	.global Mix_Side
Mix_Side:
	push {r4, r5, r6, r7}               @ 080089EC
	ldrb r3, [r0, #0xf]                 @ 080089F0
	add r1, r1, r3, lsl #2              @ 080089F4
	ldrb r3, [r0, #0xe]                 @ 080089F8
	ldm r0, {r4, r5, r7}                @ 080089FC
	lsl r6, r4, #0x12                   @ 08008A00
	add r4, r7, r4, asr #14             @ 08008A04
	lsl r7, r5, #0x12                   @ 08008A08
	asr r5, r5, #0xe                    @ 08008A0C
	rsb r0, r2, #0                      @ 08008A10
	and r0, r0, #3                      @ 08008A14
	add r0, r0, r0, lsl #1              @ 08008A18
	add pc, pc, r0, lsl #3              @ 08008A1C
	mov r0, r0                          @ 08008A20
L_08008A24:
	ldrsb ip, [r4]                      @ 08008A24
	ldr r0, [r1]                        @ 08008A28
	mla r0, ip, r3, r0                  @ 08008A2C
	adds r6, r6, r7                     @ 08008A30
	adc r4, r4, r5                      @ 08008A34
	str r0, [r1], #8                    @ 08008A38
	ldrsb ip, [r4]                      @ 08008A3C
	ldr r0, [r1]                        @ 08008A40
	mla r0, ip, r3, r0                  @ 08008A44
	adds r6, r6, r7                     @ 08008A48
	adc r4, r4, r5                      @ 08008A4C
	str r0, [r1], #8                    @ 08008A50
	ldrsb ip, [r4]                      @ 08008A54
	ldr r0, [r1]                        @ 08008A58
	mla r0, ip, r3, r0                  @ 08008A5C
	adds r6, r6, r7                     @ 08008A60
	adc r4, r4, r5                      @ 08008A64
	str r0, [r1], #8                    @ 08008A68
	ldrsb ip, [r4]                      @ 08008A6C
	ldr r0, [r1]                        @ 08008A70
	mla r0, ip, r3, r0                  @ 08008A74
	adds r6, r6, r7                     @ 08008A78
	adc r4, r4, r5                      @ 08008A7C
	str r0, [r1], #8                    @ 08008A80
	subs r2, r2, #4                     @ 08008A84
	bhi L_08008A24                      @ 08008A88
	pop {r4, r5, r6, r7}                @ 08008A8C
	bx lr                               @ 08008A90

@ --------------------------------------------------------------------------------------------
@ void Mix_Centre(Voice *v, s32 *buf, int n)          [IWRAM 0x03003DEC]
@ Same as Mix_Side but adds sample * v->volA to both sides (left volume == right volume).
	.global Mix_Centre
Mix_Centre:
	push {r4, r5, r6, r7, r8, sb, sl, fp}@ 08008A94
	ldrb r7, [r0, #0xe]                 @ 08008A98
	ldm r0, {r3, r4, r8}                @ 08008A9C
	lsl r5, r3, #0x12                   @ 08008AA0
	lsl r6, r4, #0x12                   @ 08008AA4
	add r3, r8, r3, asr #14             @ 08008AA8
	asr r4, r4, #0xe                    @ 08008AAC
	tst r2, #1                          @ 08008AB0
	beq L_08008AE0                      @ 08008AB4
	ldrsb r8, [r3]                      @ 08008AB8
	ldm r1, {r0, ip}                    @ 08008ABC
	mul sb, r8, r7                      @ 08008AC0
	add r0, r0, sb                      @ 08008AC4
	add ip, ip, sb                      @ 08008AC8
	stm r1!, {r0, ip}                   @ 08008ACC
	adds r5, r5, r6                     @ 08008AD0
	adc r3, r3, r4                      @ 08008AD4
	subs r2, r2, #1                     @ 08008AD8
	beq L_08008B60                      @ 08008ADC
L_08008AE0:
	tst r2, #2                          @ 08008AE0
	bne L_08008B20                      @ 08008AE4
L_08008AE8:
	ldm r1, {r0, sl, fp, ip}            @ 08008AE8
	ldrsb r8, [r3]                      @ 08008AEC
	mul sb, r8, r7                      @ 08008AF0
	add r0, r0, sb                      @ 08008AF4
	add sl, sl, sb                      @ 08008AF8
	adds r5, r5, r6                     @ 08008AFC
	adc r3, r3, r4                      @ 08008B00
	ldrsb r8, [r3]                      @ 08008B04
	mul sb, r8, r7                      @ 08008B08
	add fp, fp, sb                      @ 08008B0C
	add ip, ip, sb                      @ 08008B10
	adds r5, r5, r6                     @ 08008B14
	adc r3, r3, r4                      @ 08008B18
	stm r1!, {r0, sl, fp, ip}           @ 08008B1C
L_08008B20:
	ldm r1, {r0, sl, fp, ip}            @ 08008B20
	ldrsb r8, [r3]                      @ 08008B24
	mul sb, r8, r7                      @ 08008B28
	add r0, r0, sb                      @ 08008B2C
	add sl, sl, sb                      @ 08008B30
	adds r5, r5, r6                     @ 08008B34
	adc r3, r3, r4                      @ 08008B38
	ldrsb r8, [r3]                      @ 08008B3C
	mul sb, r8, r7                      @ 08008B40
	add fp, fp, sb                      @ 08008B44
	add ip, ip, sb                      @ 08008B48
	adds r5, r5, r6                     @ 08008B4C
	adc r3, r3, r4                      @ 08008B50
	stm r1!, {r0, sl, fp, ip}           @ 08008B54
	subs r2, r2, #4                     @ 08008B58
	bhi L_08008AE8                      @ 08008B5C
L_08008B60:
	pop {r4, r5, r6, r7, r8, sb, sl, fp}@ 08008B60
	bx lr                               @ 08008B64

@ --------------------------------------------------------------------------------------------
@ void Mix_Stereo(Voice *v, s32 *buf, int n)          [IWRAM 0x03003EC0]
@ General case: left += sample * v->volA, right += sample * v->volB.
	.global Mix_Stereo
Mix_Stereo:
	push {r4, r5, r6, r7, r8, sb, sl, fp}@ 08008B68
	ldrb r7, [r0, #0xe]                 @ 08008B6C
	ldrb r8, [r0, #0xf]                 @ 08008B70
	ldm r0, {r3, r4, sb}                @ 08008B74
	lsl r5, r3, #0x12                   @ 08008B78
	lsl r6, r4, #0x12                   @ 08008B7C
	add r3, sb, r3, asr #14             @ 08008B80
	asr r4, r4, #0xe                    @ 08008B84
	tst r2, #1                          @ 08008B88
	beq L_08008BB4                      @ 08008B8C
	ldrsb sb, [r3]                      @ 08008B90
	ldm r1, {r0, ip}                    @ 08008B94
	mla r0, sb, r7, r0                  @ 08008B98
	mla ip, sb, r8, ip                  @ 08008B9C
	adds r5, r5, r6                     @ 08008BA0
	adc r3, r3, r4                      @ 08008BA4
	stm r1!, {r0, ip}                   @ 08008BA8
	subs r2, r2, #1                     @ 08008BAC
	beq L_08008C24                      @ 08008BB0
L_08008BB4:
	tst r2, #2                          @ 08008BB4
	bne L_08008BEC                      @ 08008BB8
L_08008BBC:
	ldm r1, {r0, sl, fp, ip}            @ 08008BBC
	ldrsb sb, [r3]                      @ 08008BC0
	mla r0, sb, r7, r0                  @ 08008BC4
	mla sl, sb, r8, sl                  @ 08008BC8
	adds r5, r5, r6                     @ 08008BCC
	adc r3, r3, r4                      @ 08008BD0
	ldrsb sb, [r3]                      @ 08008BD4
	mla fp, sb, r7, fp                  @ 08008BD8
	mla ip, sb, r8, ip                  @ 08008BDC
	adds r5, r5, r6                     @ 08008BE0
	adc r3, r3, r4                      @ 08008BE4
	stm r1!, {r0, sl, fp, ip}           @ 08008BE8
L_08008BEC:
	ldm r1, {r0, sl, fp, ip}            @ 08008BEC
	ldrsb sb, [r3]                      @ 08008BF0
	mla r0, sb, r7, r0                  @ 08008BF4
	mla sl, sb, r8, sl                  @ 08008BF8
	adds r5, r5, r6                     @ 08008BFC
	adc r3, r3, r4                      @ 08008C00
	ldrsb sb, [r3]                      @ 08008C04
	mla fp, sb, r7, fp                  @ 08008C08
	mla ip, sb, r8, ip                  @ 08008C0C
	adds r5, r5, r6                     @ 08008C10
	adc r3, r3, r4                      @ 08008C14
	stm r1!, {r0, sl, fp, ip}           @ 08008C18
	subs r2, r2, #4                     @ 08008C1C
	bhi L_08008BBC                      @ 08008C20
L_08008C24:
	pop {r4, r5, r6, r7, r8, sb, sl, fp}@ 08008C24
	bx lr                               @ 08008C28

@ --------------------------------------------------------------------------------------------
@ void Mix_Output(s8 *outL, s8 *outR, s32 *buf, int n)  [IWRAM 0x03003F84]
@ Converts n frames of the mix buffer to 8-bit DirectSound data: (x >> 6) clamped to -128..127,
@ written two bytes at a time to each ring. Clears the mix buffer as it goes.
	.global Mix_Output
Mix_Output:
	push {r4, r5, r6, r7, r8, sb, sl, fp}@ 08008C2C
	mov r8, #0                          @ 08008C30
	mov sb, #0                          @ 08008C34
	mov sl, #0                          @ 08008C38
	mov fp, #0                          @ 08008C3C
L_08008C40:
	ldm r2, {r4, r5, r6, r7}            @ 08008C40
	stm r2!, {r8, sb, sl, fp}           @ 08008C44
	asr r4, r4, #6                      @ 08008C48
	asr r5, r5, #6                      @ 08008C4C
	asr r6, r6, #6                      @ 08008C50
	asr r7, r7, #6                      @ 08008C54
	cmp r4, #0x7f                       @ 08008C58
	movgt r4, #0x7f                     @ 08008C5C
	cmn r4, #0x80                       @ 08008C60
	mvnlt r4, #0x7f                     @ 08008C64
	cmp r5, #0x7f                       @ 08008C68
	movgt r5, #0x7f                     @ 08008C6C
	cmn r5, #0x80                       @ 08008C70
	mvnlt r5, #0x7f                     @ 08008C74
	cmp r6, #0x7f                       @ 08008C78
	movgt r6, #0x7f                     @ 08008C7C
	cmn r6, #0x80                       @ 08008C80
	mvnlt r6, #0x7f                     @ 08008C84
	cmp r7, #0x7f                       @ 08008C88
	movgt r7, #0x7f                     @ 08008C8C
	cmn r7, #0x80                       @ 08008C90
	mvnlt r7, #0x7f                     @ 08008C94
	and r4, r4, #0xff                   @ 08008C98
	orr r4, r4, r6, lsl #8              @ 08008C9C
	and r5, r5, #0xff                   @ 08008CA0
	orr r5, r5, r7, lsl #8              @ 08008CA4
	strh r4, [r0], #2                   @ 08008CA8
	strh r5, [r1], #2                   @ 08008CAC
	subs r3, r3, #2                     @ 08008CB0
	bgt L_08008C40                      @ 08008CB4
	pop {r4, r5, r6, r7, r8, sb, sl, fp}@ 08008CB8
	bx lr                               @ 08008CBC
	.thumb

@ --------------------------------------------------------------------------------------------
@ void Mix_Null(void) -- installed as the mix routine of a voice whose two volumes are both 0.
	.thumb_func
	.global Mix_Null
Mix_Null:
	bx lr                               @ 08008CC0

@ --------------------------------------------------------------------------------------------
@ DMA2 interrupt (FIFO B refill, every 16 bytes = 16 samples). Called by the game's ARM IRQ
@ dispatcher with r6 = ARM return address, so it returns with bx r6.
@   playpos += 16;
@   every 512 samples one of the two DMAs is re-armed at the start of its ring (DMA2 at playpos 512,
@   DMA1 at playpos 1024, which also wraps playpos to 0) - the right ring is half a turn out of phase.
@   When only 128 samples remain between playpos and the write position and the mixer is not already
@   running, it enters Snd_Mix with IRQs re-enabled (through Snd_IrqCallMix).
	.thumb_func
	.global Snd_Dma2Irq
Snd_Dma2Irq:
	ldr r3, L_08008D1C                  @ 08008CC2 =0x03003D30
	ldr r0, [r3]                        @ 08008CC4
	adds r0, #0x10                      @ 08008CC6
	str r0, [r3]                        @ 08008CC8
	lsls r1, r0, #0x17                  @ 08008CCA
	bne L_08008CEC                      @ 08008CCC
	lsls r2, r0, #0x16                  @ 08008CCE
	bpl L_08008CDC                      @ 08008CD0
	ldr r2, L_08008D20                  @ 08008CD2 =0x040000C8
	str r1, [r2, #8]                    @ 08008CD4
	ldr r1, L_08008D24                  @ 08008CD6 =0x0203FC00
	ldr r3, L_08008D28                  @ 08008CD8 =0x040000A4
	b L_08008CE6                        @ 08008CDA
L_08008CDC:
	str r1, [r3]                        @ 08008CDC
	ldr r2, L_08008D2C                  @ 08008CDE =0x040000BC
	str r1, [r2, #8]                    @ 08008CE0
	ldr r1, L_08008D30                  @ 08008CE2 =0x0203F800
	ldr r3, L_08008D34                  @ 08008CE4 =0x040000A0
L_08008CE6:
	stmia r2!, {r1, r3}                 @ 08008CE6
	ldr r3, L_08008D38                  @ 08008CE8 =0xF6400004
	str r3, [r2]                        @ 08008CEA
L_08008CEC:
	ldr r1, L_08008D3C                  @ 08008CEC =0x03003D34
	ldr r1, [r1]                        @ 08008CEE
	subs r1, r1, r0                     @ 08008CF0
	lsls r1, r1, #0x16                  @ 08008CF2
	lsrs r1, r1, #0x16                  @ 08008CF4
	cmp r1, #0x80                       @ 08008CF6
	beq L_08008CFC                      @ 08008CF8
L_08008CFA:
	bx r6                               @ 08008CFA
L_08008CFC:
	ldr r0, L_08008D40                  @ 08008CFC =0x03003D3C
	ldrb r0, [r0]                       @ 08008CFE
	cmp r0, #0                          @ 08008D00
	bne L_08008CFA                      @ 08008D02
	ldr r0, L_08008D44                  @ 08008D04 =0x08008D0C
	ldr r1, L_08008D48                  @ 08008D06 =0x0800AE0D
	bx r0                               @ 08008D08
	movs r0, r0                         @ 08008D0A
	.arm

@ --------------------------------------------------------------------------------------------
@ ARM stub: clear the I bit (allow nested IRQs) and jump to Snd_Mix (r1 = Snd_Mix|1).
	.global Snd_IrqCallMix
Snd_IrqCallMix:
	mrs r0, cpsr                        @ 08008D0C
	bic r0, r0, #0x80                   @ 08008D10
	msr cpsr_c, r0                      @ 08008D14
	bx r1                               @ 08008D18
	.thumb
L_08008D1C:
	.word snd_playpos	@ 0x03003D30
L_08008D20:
	.word REG_DMA2SAD	@ 0x040000C8
L_08008D24:
	.word ring_R	@ 0x0203FC00
L_08008D28:
	.word REG_FIFO_B	@ 0x040000A4
L_08008D2C:
	.word REG_DMA1SAD	@ 0x040000BC
L_08008D30:
	.word ring_L	@ 0x0203F800
L_08008D34:
	.word REG_FIFO_A	@ 0x040000A0
L_08008D38:
	.word DMA_FIFO_RESTART	@ 0xF6400004
L_08008D3C:
	.word snd_writepos	@ 0x03003D34
L_08008D40:
	.word snd_busy	@ 0x03003D3C
L_08008D44:
	.word Snd_IrqCallMix	@ 0x08008D0C
L_08008D48:
	.word Snd_Mix	@ 0x0800AE0D

	.section .wf1_player, "ax"
	.p2align 2
	.thumb

@ --------------------------------------------------------------------------------------------
@ void Fx_None(Chan *c)  -- effect 0, and the first step of almost every other effect handler.
@ If the row holds a note (mask 0x01 or 0x11): note 0xFF = note off (stop the voice);
@ otherwise pitch = NoteFreqTab[note], volume = the channel's row volume, flags = note sounding,
@ and the voice is started: with instrument reload (MusInstrTab[ins], voice flags 0x1F) unless
@ mask bit 0x20 (instrument repeated) is set, in which case only pitch/volume/restart (0x17).
@ Without a note, a volume byte (mask 0x04/0x44) just sets the volume.
	.thumb_func
	.global Fx_None
Fx_None:
	push {r4}                           @ 08009CCC
	ldrb r1, [r0, #0x18]                @ 08009CCE
	movs r2, #0x11                      @ 08009CD0
	ands r2, r1                         @ 08009CD2
	beq L_08009D34                      @ 08009CD4
	ldrb r2, [r0, #0x1a]                @ 08009CD6
	movs r4, #4                         @ 08009CD8
	cmp r2, #0xff                       @ 08009CDA
	bne L_08009CF2                      @ 08009CDC
	ldr r1, [r0, #0x20]                 @ 08009CDE
	ldrb r2, [r1, #0xc]                 @ 08009CE0
	lsrs r2, r2, #1                     @ 08009CE2
	lsls r2, r2, #1                     @ 08009CE4
	strb r2, [r1, #0xc]                 @ 08009CE6
	ldrb r1, [r0, #0xa]                 @ 08009CE8
	bics r1, r4                         @ 08009CEA
	strb r1, [r0, #0xa]                 @ 08009CEC
L_08009CEE:
	pop {r4}                            @ 08009CEE
	bx lr                               @ 08009CF0
L_08009CF2:
	ldrb r3, [r0, #0x1c]                @ 08009CF2
	lsls r2, r2, #2                     @ 08009CF4
	lsls r1, r1, #0x1a                  @ 08009CF6
	strb r3, [r0, #8]                   @ 08009CF8
	ldr r3, L_0800A0D8                  @ 08009CFA =0x080113A8
	ldr r2, [r3, r2]                    @ 08009CFC
	str r2, [r0]                        @ 08009CFE
	strb r4, [r0, #0xa]                 @ 08009D00
	ldr r1, [r0, #0x20]                 @ 08009D02
	bpl L_08009D16                      @ 08009D04
	ldrb r0, [r0, #8]                   @ 08009D06
	str r2, [r1, #0x2c]                 @ 08009D08
	movs r2, #0x17                      @ 08009D0A
	strb r0, [r1, #0x10]                @ 08009D0C
	ldrb r0, [r1, #0xc]                 @ 08009D0E
	orrs r0, r2                         @ 08009D10
	strb r0, [r1, #0xc]                 @ 08009D12
	b L_08009CEE                        @ 08009D14
L_08009D16:
	ldrb r4, [r0, #0x1b]                @ 08009D16
	ldrb r0, [r0, #8]                   @ 08009D18
	str r2, [r1, #0x2c]                 @ 08009D1A
	lsls r3, r4, #1                     @ 08009D1C
	adds r3, r3, r4                     @ 08009D1E
	ldr r4, L_0800A0DC                  @ 08009D20 =0x085B8258
	lsls r3, r3, #2                     @ 08009D22
	adds r3, r3, r4                     @ 08009D24
	str r3, [r1, #0x24]                 @ 08009D26
	strb r0, [r1, #0x10]                @ 08009D28
	ldrb r0, [r1, #0xc]                 @ 08009D2A
	movs r2, #0x1f                      @ 08009D2C
	orrs r0, r2                         @ 08009D2E
	strb r0, [r1, #0xc]                 @ 08009D30
	b L_08009CEE                        @ 08009D32
L_08009D34:
	movs r2, #0x44                      @ 08009D34
	ands r1, r2                         @ 08009D36
	beq L_08009CEE                      @ 08009D38
	ldrb r1, [r0, #0x1c]                @ 08009D3A
	movs r2, #0x10                      @ 08009D3C
	strb r1, [r0, #8]                   @ 08009D3E
	ldr r1, [r0, #0x20]                 @ 08009D40
	ldrb r0, [r0, #0x1c]                @ 08009D42
	strb r0, [r1, #0x10]                @ 08009D44
	ldrb r0, [r1, #0xc]                 @ 08009D46
	orrs r0, r2                         @ 08009D48
	strb r0, [r1, #0xc]                 @ 08009D4A
	b L_08009CEE                        @ 08009D4C

@ --------------------------------------------------------------------------------------------
@ Axx: ticks per row = xx.
	.thumb_func
	.global Fx_A_SetSpeed
Fx_A_SetSpeed:
	push {r4, lr}                       @ 08009D4E
	adds r4, r0, #0                     @ 08009D50
	bl Fx_None                          @ 08009D52
	adds r4, #0x10                      @ 08009D56
	ldrb r0, [r4, #0xe]                 @ 08009D58
	ldr r1, L_0800A0E0                  @ 08009D5A =0x03003CFC
	strb r0, [r1]                       @ 08009D5C
	pop {r4, pc}                        @ 08009D5E

@ --------------------------------------------------------------------------------------------
@ Bxx: finish the current pattern now and continue at order xx.
	.thumb_func
	.global Fx_B_PositionJump
Fx_B_PositionJump:
	push {r4, lr}                       @ 08009D60
	adds r4, r0, #0                     @ 08009D62
	bl Fx_None                          @ 08009D64
	ldr r0, L_0800A0E4                  @ 08009D68 =0x03003CFA
	ldr r1, L_0800A0E8                  @ 08009D6A =0x03003CF9
	ldrb r0, [r0]                       @ 08009D6C
	adds r4, #0x10                      @ 08009D6E
	subs r0, #1                         @ 08009D70
	strb r0, [r1]                       @ 08009D72
	ldrb r0, [r4, #0xe]                 @ 08009D74
	ldr r1, L_0800A0EC                  @ 08009D76 =0x03003CFE
	subs r0, #1                         @ 08009D78
	strh r0, [r1]                       @ 08009D7A
	pop {r4, pc}                        @ 08009D7C

@ --------------------------------------------------------------------------------------------
@ tick handler: volume -= slide step, stop sliding at 0.
	.thumb_func
	.global Tick_VolSlideDown
Tick_VolSlideDown:
	ldrb r1, [r0, #8]                   @ 08009D7E
	ldrb r2, [r0, #0xb]                 @ 08009D80
	subs r1, r1, r2                     @ 08009D82
	lsls r1, r1, #0x18                  @ 08009D84
	asrs r1, r1, #0x18                  @ 08009D86
	strb r1, [r0, #8]                   @ 08009D88
	cmp r1, #0                          @ 08009D8A
	bgt L_08009D9A                      @ 08009D8C
	movs r1, #0                         @ 08009D8E
	strb r1, [r0, #8]                   @ 08009D90
	ldrb r1, [r0, #0xa]                 @ 08009D92
	lsrs r1, r1, #2                     @ 08009D94
	lsls r1, r1, #2                     @ 08009D96
	strb r1, [r0, #0xa]                 @ 08009D98
L_08009D9A:
	ldr r1, [r0, #0x20]                 @ 08009D9A
	ldrb r0, [r0, #8]                   @ 08009D9C
	movs r2, #0x10                      @ 08009D9E
	strb r0, [r1, #0x10]                @ 08009DA0
	ldrb r0, [r1, #0xc]                 @ 08009DA2
	orrs r0, r2                         @ 08009DA4
	strb r0, [r1, #0xc]                 @ 08009DA6
	bx lr                               @ 08009DA8

@ --------------------------------------------------------------------------------------------
@ tick handler: volume += slide step, stop sliding at 64.
	.thumb_func
	.global Tick_VolSlideUp
Tick_VolSlideUp:
	ldrb r1, [r0, #8]                   @ 08009DAA
	ldrb r2, [r0, #0xb]                 @ 08009DAC
	adds r1, r1, r2                     @ 08009DAE
	lsls r1, r1, #0x18                  @ 08009DB0
	asrs r1, r1, #0x18                  @ 08009DB2
	strb r1, [r0, #8]                   @ 08009DB4
	cmp r1, #0x40                       @ 08009DB6
	blt L_08009DC6                      @ 08009DB8
	movs r1, #0x40                      @ 08009DBA
	strb r1, [r0, #8]                   @ 08009DBC
	ldrb r1, [r0, #0xa]                 @ 08009DBE
	lsrs r1, r1, #2                     @ 08009DC0
	lsls r1, r1, #2                     @ 08009DC2
	strb r1, [r0, #0xa]                 @ 08009DC4
L_08009DC6:
	ldr r1, [r0, #0x20]                 @ 08009DC6
	ldrb r0, [r0, #8]                   @ 08009DC8
	movs r2, #0x10                      @ 08009DCA
	strb r0, [r1, #0x10]                @ 08009DCC
	ldrb r0, [r1, #0xc]                 @ 08009DCE
	orrs r0, r2                         @ 08009DD0
	strb r0, [r1, #0xc]                 @ 08009DD2
	bx lr                               @ 08009DD4

@ --------------------------------------------------------------------------------------------
@ Dxy (ST3 rules): Dx0 slide up x per tick, D0y slide down y per tick (DF0/D0F also act on
@ the first tick), DxF fine slide up x once, DFy fine slide down y once. D00 reuses the last value.
	.thumb_func
	.global Fx_D_VolumeSlide
Fx_D_VolumeSlide:
	push {r4, lr}                       @ 08009DD6
	adds r4, r0, #0                     @ 08009DD8
	bl Fx_None                          @ 08009DDA
	movs r0, #0x1e                      @ 08009DDE
	ldrb r0, [r0, r4]                   @ 08009DE0
	cmp r0, #0                          @ 08009DE2
	beq L_08009DE8                      @ 08009DE4
	strb r0, [r4, #0xc]                 @ 08009DE6
L_08009DE8:
	ldrb r0, [r4, #0xc]                 @ 08009DE8
	movs r3, #1                         @ 08009DEA
	lsls r2, r0, #0x1c                  @ 08009DEC
	lsrs r2, r2, #0x1c                  @ 08009DEE
	cmp r2, #0                          @ 08009DF0
	bne L_08009E10                      @ 08009DF2
	lsrs r0, r0, #4                     @ 08009DF4
	strb r0, [r4, #0xb]                 @ 08009DF6
	ldr r0, L_0800A0F0                  @ 08009DF8 =0x08009DAB
	str r0, [r4, #0x14]                 @ 08009DFA
	ldrb r0, [r4, #0xa]                 @ 08009DFC
	orrs r0, r3                         @ 08009DFE
	strb r0, [r4, #0xa]                 @ 08009E00
	ldrb r0, [r4, #0xb]                 @ 08009E02
	cmp r0, #0xf                        @ 08009E04
	bne L_08009E0E                      @ 08009E06
	adds r0, r4, #0                     @ 08009E08
	bl Tick_VolSlideUp                  @ 08009E0A
L_08009E0E:
	pop {r4, pc}                        @ 08009E0E
L_08009E10:
	lsls r1, r0, #0x18                  @ 08009E10
	lsrs r1, r1, #0x1c                  @ 08009E12
	bne L_08009E32                      @ 08009E14
	ldrb r0, [r4, #0xc]                 @ 08009E16
	strb r0, [r4, #0xb]                 @ 08009E18
	ldr r0, L_0800A0F4                  @ 08009E1A =0x08009D7F
	str r0, [r4, #0x14]                 @ 08009E1C
	ldrb r0, [r4, #0xa]                 @ 08009E1E
	orrs r0, r3                         @ 08009E20
	strb r0, [r4, #0xa]                 @ 08009E22
	ldrb r0, [r4, #0xb]                 @ 08009E24
	cmp r0, #0xf                        @ 08009E26
	bne L_08009E0E                      @ 08009E28
	adds r0, r4, #0                     @ 08009E2A
	bl Tick_VolSlideDown                @ 08009E2C
	pop {r4, pc}                        @ 08009E30
L_08009E32:
	movs r3, #0xf                       @ 08009E32
	bics r3, r0                         @ 08009E34
	bne L_08009E44                      @ 08009E36
	lsrs r0, r0, #4                     @ 08009E38
	strb r0, [r4, #0xb]                 @ 08009E3A
	adds r0, r4, #0                     @ 08009E3C
	bl Tick_VolSlideUp                  @ 08009E3E
L_08009E42:
	pop {r4, pc}                        @ 08009E42
L_08009E44:
	cmp r1, #0xf                        @ 08009E44
	bne L_08009E42                      @ 08009E46
	strb r2, [r4, #0xb]                 @ 08009E48
	adds r0, r4, #0                     @ 08009E4A
	bl Tick_VolSlideDown                @ 08009E4C
	pop {r4, pc}                        @ 08009E50

@ --------------------------------------------------------------------------------------------
@ tick handler: pitch = pitch * PortaDownTab[speed] >> 16.
	.thumb_func
	.global Tick_PortaDown
Tick_PortaDown:
	ldrb r1, [r0, #0xd]                 @ 08009E52
	ldr r3, L_0800A0F8                  @ 08009E54 =0x08011888
	ldr r2, [r0]                        @ 08009E56
	lsls r1, r1, #1                     @ 08009E58
	ldrh r1, [r3, r1]                   @ 08009E5A
	muls r2, r1, r2                     @ 08009E5C
	lsrs r1, r2, #0x10                  @ 08009E5E
	str r1, [r0]                        @ 08009E60
	ldr r0, [r0, #0x20]                 @ 08009E62
	movs r2, #2                         @ 08009E64
	str r1, [r0, #0x2c]                 @ 08009E66
	ldrb r1, [r0, #0xc]                 @ 08009E68
	orrs r1, r2                         @ 08009E6A
	strb r1, [r0, #0xc]                 @ 08009E6C
	bx lr                               @ 08009E6E

@ --------------------------------------------------------------------------------------------
@ Exx portamento down: xx/16 semitone per tick; EFx fine (x/16 semitone once),
@ EEx extra fine (x/64 semitone once). E00 reuses the shared E/F/G memory.
	.thumb_func
	.global Fx_E_PortaDown
Fx_E_PortaDown:
	push {r4, lr}                       @ 08009E70
	adds r4, r0, #0                     @ 08009E72
	bl Fx_None                          @ 08009E74
	movs r0, #0x1e                      @ 08009E78
	ldrb r0, [r0, r4]                   @ 08009E7A
	cmp r0, #0                          @ 08009E7C
	beq L_08009E82                      @ 08009E7E
	strb r0, [r4, #0xd]                 @ 08009E80
L_08009E82:
	ldrb r2, [r4, #0xa]                 @ 08009E82
	lsls r0, r2, #0x1d                  @ 08009E84
	lsrs r0, r0, #0x1f                  @ 08009E86
	beq L_08009EB0                      @ 08009E88
	ldrb r0, [r4, #0xd]                 @ 08009E8A
	movs r3, #2                         @ 08009E8C
	lsls r1, r0, #0x18                  @ 08009E8E
	lsrs r1, r1, #0x1c                  @ 08009E90
	cmp r1, #0xf                        @ 08009E92
	bne L_08009EB2                      @ 08009E94
	lsls r0, r0, #0x1c                  @ 08009E96
	ldr r2, L_0800A0F8                  @ 08009E98 =0x08011888
	lsrs r0, r0, #0x1b                  @ 08009E9A
	ldrh r0, [r2, r0]                   @ 08009E9C
	ldr r1, [r4]                        @ 08009E9E
	muls r1, r0, r1                     @ 08009EA0
	lsrs r0, r1, #0x10                  @ 08009EA2
	str r0, [r4]                        @ 08009EA4
	ldr r1, [r4, #0x20]                 @ 08009EA6
	str r0, [r1, #0x2c]                 @ 08009EA8
	ldrb r0, [r1, #0xc]                 @ 08009EAA
	orrs r0, r3                         @ 08009EAC
	strb r0, [r1, #0xc]                 @ 08009EAE
L_08009EB0:
	pop {r4, pc}                        @ 08009EB0
L_08009EB2:
	cmp r1, #0xe                        @ 08009EB2
	bne L_08009ED4                      @ 08009EB4
	ldr r2, L_0800A0F8                  @ 08009EB6 =0x08011888
	lsls r0, r0, #0x1c                  @ 08009EB8
	lsrs r0, r0, #0x1b                  @ 08009EBA
	subs r2, #0x80                      @ 08009EBC
	ldrh r0, [r2, r0]                   @ 08009EBE
	ldr r1, [r4]                        @ 08009EC0
	muls r1, r0, r1                     @ 08009EC2
	lsrs r0, r1, #0x10                  @ 08009EC4
	str r0, [r4]                        @ 08009EC6
	ldr r1, [r4, #0x20]                 @ 08009EC8
	str r0, [r1, #0x2c]                 @ 08009ECA
	ldrb r0, [r1, #0xc]                 @ 08009ECC
	orrs r0, r3                         @ 08009ECE
	strb r0, [r1, #0xc]                 @ 08009ED0
	pop {r4, pc}                        @ 08009ED2
L_08009ED4:
	ldr r0, L_0800A0FC                  @ 08009ED4 =0x08009E53
	str r0, [r4, #0x14]                 @ 08009ED6
	movs r0, #1                         @ 08009ED8
	orrs r0, r2                         @ 08009EDA
	strb r0, [r4, #0xa]                 @ 08009EDC
	pop {r4, pc}                        @ 08009EDE

@ --------------------------------------------------------------------------------------------
@ tick handler: pitch = pitch * PortaUpTab[speed] >> 14.
	.thumb_func
	.global Tick_PortaUp
Tick_PortaUp:
	ldrb r1, [r0, #0xd]                 @ 08009EE0
	ldr r3, L_0800A100                  @ 08009EE2 =0x08011608
	ldr r2, [r0]                        @ 08009EE4
	lsls r1, r1, #1                     @ 08009EE6
	ldrh r1, [r3, r1]                   @ 08009EE8
	muls r2, r1, r2                     @ 08009EEA
	lsrs r1, r2, #0xe                   @ 08009EEC
	str r1, [r0]                        @ 08009EEE
	ldr r0, [r0, #0x20]                 @ 08009EF0
	movs r2, #2                         @ 08009EF2
	str r1, [r0, #0x2c]                 @ 08009EF4
	ldrb r1, [r0, #0xc]                 @ 08009EF6
	orrs r1, r2                         @ 08009EF8
	strb r1, [r0, #0xc]                 @ 08009EFA
	bx lr                               @ 08009EFC

@ --------------------------------------------------------------------------------------------
@ Fxx portamento up, same encoding as E.
	.thumb_func
	.global Fx_F_PortaUp
Fx_F_PortaUp:
	push {r4, lr}                       @ 08009EFE
	adds r4, r0, #0                     @ 08009F00
	bl Fx_None                          @ 08009F02
	movs r0, #0x1e                      @ 08009F06
	ldrb r0, [r0, r4]                   @ 08009F08
	cmp r0, #0                          @ 08009F0A
	beq L_08009F10                      @ 08009F0C
	strb r0, [r4, #0xd]                 @ 08009F0E
L_08009F10:
	ldrb r2, [r4, #0xa]                 @ 08009F10
	lsls r0, r2, #0x1d                  @ 08009F12
	lsrs r0, r0, #0x1f                  @ 08009F14
	beq L_08009F3E                      @ 08009F16
	ldrb r0, [r4, #0xd]                 @ 08009F18
	movs r3, #2                         @ 08009F1A
	lsls r1, r0, #0x18                  @ 08009F1C
	lsrs r1, r1, #0x1c                  @ 08009F1E
	cmp r1, #0xf                        @ 08009F20
	bne L_08009F40                      @ 08009F22
	lsls r0, r0, #0x1c                  @ 08009F24
	ldr r2, L_0800A100                  @ 08009F26 =0x08011608
	lsrs r0, r0, #0x1b                  @ 08009F28
	ldrh r0, [r2, r0]                   @ 08009F2A
	ldr r1, [r4]                        @ 08009F2C
	muls r1, r0, r1                     @ 08009F2E
	lsrs r0, r1, #0xe                   @ 08009F30
	str r0, [r4]                        @ 08009F32
	ldr r1, [r4, #0x20]                 @ 08009F34
	str r0, [r1, #0x2c]                 @ 08009F36
	ldrb r0, [r1, #0xc]                 @ 08009F38
	orrs r0, r3                         @ 08009F3A
	strb r0, [r1, #0xc]                 @ 08009F3C
L_08009F3E:
	pop {r4, pc}                        @ 08009F3E
L_08009F40:
	cmp r1, #0xe                        @ 08009F40
	bne L_08009F62                      @ 08009F42
	ldr r2, L_0800A100                  @ 08009F44 =0x08011608
	lsls r0, r0, #0x1c                  @ 08009F46
	lsrs r0, r0, #0x1b                  @ 08009F48
	subs r2, #0x80                      @ 08009F4A
	ldrh r0, [r2, r0]                   @ 08009F4C
	ldr r1, [r4]                        @ 08009F4E
	muls r1, r0, r1                     @ 08009F50
	lsrs r0, r1, #0xf                   @ 08009F52
	str r0, [r4]                        @ 08009F54
	ldr r1, [r4, #0x20]                 @ 08009F56
	str r0, [r1, #0x2c]                 @ 08009F58
	ldrb r0, [r1, #0xc]                 @ 08009F5A
	orrs r0, r3                         @ 08009F5C
	strb r0, [r1, #0xc]                 @ 08009F5E
	pop {r4, pc}                        @ 08009F60
L_08009F62:
	ldr r0, L_0800A104                  @ 08009F62 =0x08009EE1
	str r0, [r4, #0x14]                 @ 08009F64
	movs r0, #1                         @ 08009F66
	orrs r0, r2                         @ 08009F68
	strb r0, [r4, #0xa]                 @ 08009F6A
	pop {r4, pc}                        @ 08009F6C

@ --------------------------------------------------------------------------------------------
@ tick handler: slide down towards the target, clamp and stop when reached.
	.thumb_func
	.global Tick_TonePortaDown
Tick_TonePortaDown:
	ldrb r1, [r0, #0xd]                 @ 08009F6E
	ldr r3, L_0800A0F8                  @ 08009F70 =0x08011888
	ldr r2, [r0]                        @ 08009F72
	lsls r1, r1, #1                     @ 08009F74
	ldrh r1, [r3, r1]                   @ 08009F76
	movs r3, #2                         @ 08009F78
	muls r2, r1, r2                     @ 08009F7A
	lsrs r2, r2, #0x10                  @ 08009F7C
	str r2, [r0]                        @ 08009F7E
	ldr r1, [r0, #0x20]                 @ 08009F80
	str r2, [r1, #0x2c]                 @ 08009F82
	ldrb r2, [r1, #0xc]                 @ 08009F84
	orrs r2, r3                         @ 08009F86
	strb r2, [r1, #0xc]                 @ 08009F88
	ldmia r0!, {r1, r2}                 @ 08009F8A
	subs r0, #8                         @ 08009F8C
	cmp r1, r2                          @ 08009F8E
	bhs L_08009FAA                      @ 08009F90
	str r2, [r0]                        @ 08009F92
	ldr r1, [r0, #0x20]                 @ 08009F94
	str r2, [r1, #0x2c]                 @ 08009F96
	ldrb r2, [r1, #0xc]                 @ 08009F98
	orrs r2, r3                         @ 08009F9A
	strb r2, [r1, #0xc]                 @ 08009F9C
	ldrb r1, [r0, #0xa]                 @ 08009F9E
	movs r2, #8                         @ 08009FA0
	bics r1, r2                         @ 08009FA2
	lsrs r1, r1, #2                     @ 08009FA4
	lsls r1, r1, #2                     @ 08009FA6
	strb r1, [r0, #0xa]                 @ 08009FA8
L_08009FAA:
	bx lr                               @ 08009FAA

@ --------------------------------------------------------------------------------------------
@ tick handler: slide up towards the target, clamp and stop when reached.
	.thumb_func
	.global Tick_TonePortaUp
Tick_TonePortaUp:
	ldrb r1, [r0, #0xd]                 @ 08009FAC
	ldr r2, [r0]                        @ 08009FAE
	ldr r3, L_0800A100                  @ 08009FB0 =0x08011608
	lsls r1, r1, #1                     @ 08009FB2
	ldrh r1, [r3, r1]                   @ 08009FB4
	movs r3, #2                         @ 08009FB6
	muls r2, r1, r2                     @ 08009FB8
	lsrs r2, r2, #0xe                   @ 08009FBA
	str r2, [r0]                        @ 08009FBC
	ldr r1, [r0, #0x20]                 @ 08009FBE
	str r2, [r1, #0x2c]                 @ 08009FC0
	ldrb r2, [r1, #0xc]                 @ 08009FC2
	orrs r2, r3                         @ 08009FC4
	strb r2, [r1, #0xc]                 @ 08009FC6
	ldmia r0!, {r1, r2}                 @ 08009FC8
	subs r0, #8                         @ 08009FCA
	cmp r1, r2                          @ 08009FCC
	bls L_08009FE8                      @ 08009FCE
	str r2, [r0]                        @ 08009FD0
	ldr r1, [r0, #0x20]                 @ 08009FD2
	str r2, [r1, #0x2c]                 @ 08009FD4
	ldrb r2, [r1, #0xc]                 @ 08009FD6
	orrs r2, r3                         @ 08009FD8
	strb r2, [r1, #0xc]                 @ 08009FDA
	ldrb r1, [r0, #0xa]                 @ 08009FDC
	movs r2, #8                         @ 08009FDE
	bics r1, r2                         @ 08009FE0
	lsrs r1, r1, #2                     @ 08009FE2
	lsls r1, r1, #2                     @ 08009FE4
	strb r1, [r0, #0xa]                 @ 08009FE6
L_08009FE8:
	bx lr                               @ 08009FE8

@ --------------------------------------------------------------------------------------------
@ Gxx tone portamento: a note on this row becomes the target instead of being played;
@ the direction picks Tick_TonePortaUp/Down. Does nothing (not even play the note) if the channel
@ is silent.
	.thumb_func
	.global Fx_G_TonePorta
Fx_G_TonePorta:
	push {r4}                           @ 08009FEA
	movs r1, #0x1e                      @ 08009FEC
	ldrb r1, [r1, r0]                   @ 08009FEE
	cmp r1, #0                          @ 08009FF0
	beq L_08009FF6                      @ 08009FF2
	strb r1, [r0, #0xd]                 @ 08009FF4
L_08009FF6:
	ldrb r1, [r0, #0xa]                 @ 08009FF6
	lsls r2, r1, #0x1d                  @ 08009FF8
	lsrs r2, r2, #0x1f                  @ 08009FFA
	beq L_0800A058                      @ 08009FFC
	ldrb r3, [r0, #0x18]                @ 08009FFE
	movs r2, #0x11                      @ 0800A000
	ands r2, r3                         @ 0800A002
	beq L_0800A01C                      @ 0800A004
	ldrb r2, [r0, #0x1a]                @ 0800A006
	cmp r2, #0xff                       @ 0800A008
	beq L_0800A040                      @ 0800A00A
	ldr r4, L_0800A0D8                  @ 0800A00C =0x080113A8
	lsls r2, r2, #2                     @ 0800A00E
	ldr r2, [r4, r2]                    @ 0800A010
	str r2, [r0, #4]                    @ 0800A012
	movs r2, #8                         @ 0800A014
	orrs r1, r2                         @ 0800A016
	strb r1, [r0, #0xa]                 @ 0800A018
	b L_0800A020                        @ 0800A01A
L_0800A01C:
	lsls r1, r1, #0x1c                  @ 0800A01C
	bpl L_0800A040                      @ 0800A01E
L_0800A020:
	ldr r1, [r0, #4]                    @ 0800A020
	ldr r4, [r0]                        @ 0800A022
	movs r2, #1                         @ 0800A024
	cmp r1, r4                          @ 0800A026
	bls L_0800A036                      @ 0800A028
	ldr r1, L_0800A108                  @ 0800A02A =0x08009FAD
	str r1, [r0, #0x14]                 @ 0800A02C
	ldrb r1, [r0, #0xa]                 @ 0800A02E
	orrs r1, r2                         @ 0800A030
	strb r1, [r0, #0xa]                 @ 0800A032
	b L_0800A040                        @ 0800A034
L_0800A036:
	ldr r1, L_0800A10C                  @ 0800A036 =0x08009F6F
	str r1, [r0, #0x14]                 @ 0800A038
	ldrb r1, [r0, #0xa]                 @ 0800A03A
	orrs r1, r2                         @ 0800A03C
	strb r1, [r0, #0xa]                 @ 0800A03E
L_0800A040:
	movs r1, #0x44                      @ 0800A040
	ands r3, r1                         @ 0800A042
	beq L_0800A058                      @ 0800A044
	ldrb r1, [r0, #0x1c]                @ 0800A046
	movs r2, #0x10                      @ 0800A048
	strb r1, [r0, #8]                   @ 0800A04A
	ldr r1, [r0, #0x20]                 @ 0800A04C
	ldrb r0, [r0, #8]                   @ 0800A04E
	strb r0, [r1, #0x10]                @ 0800A050
	ldrb r0, [r1, #0xc]                 @ 0800A052
	orrs r0, r2                         @ 0800A054
	strb r0, [r1, #0xc]                 @ 0800A056
L_0800A058:
	pop {r4}                            @ 0800A058
	bx lr                               @ 0800A05A

@ --------------------------------------------------------------------------------------------
@ tick handler: phase += speed; offset = VibratoSine[phase] * depth >> 6 (1/64 semitone units);
@ voice pitch = channel pitch scaled by PortaFineUpTab/PortaFineDownTab[|offset|]. The channel's own
@ pitch is not changed, Mus_ChannelRow restores it on the next row.
	.thumb_func
	.global Tick_Vibrato
Tick_Vibrato:
	ldrb r1, [r0, #0x11]                @ 0800A05C
	ldrb r2, [r0, #0xf]                 @ 0800A05E
	ldr r3, L_0800A110                  @ 0800A060 =0x08011A88
	adds r1, r1, r2                     @ 0800A062
	lsls r1, r1, #0x1a                  @ 0800A064
	lsrs r1, r1, #0x1a                  @ 0800A066
	strb r1, [r0, #0x11]                @ 0800A068
	ldrb r2, [r0, #0x10]                @ 0800A06A
	ldrsb r1, [r3, r1]                  @ 0800A06C
	muls r2, r1, r2                     @ 0800A06E
	asrs r1, r2, #6                     @ 0800A070
	ldr r2, [r0]                        @ 0800A072
	bpl L_0800A086                      @ 0800A074
	ldr r3, L_0800A0F8                  @ 0800A076 =0x08011888
	lsls r1, r1, #1                     @ 0800A078
	subs r3, #0x80                      @ 0800A07A
	subs r1, r3, r1                     @ 0800A07C
	ldrh r1, [r1]                       @ 0800A07E
	muls r2, r1, r2                     @ 0800A080
	lsrs r1, r2, #0x10                  @ 0800A082
	b L_0800A092                        @ 0800A084
L_0800A086:
	ldr r3, L_0800A100                  @ 0800A086 =0x08011608
	lsls r1, r1, #1                     @ 0800A088
	subs r3, #0x80                      @ 0800A08A
	ldrh r1, [r3, r1]                   @ 0800A08C
	muls r2, r1, r2                     @ 0800A08E
	lsrs r1, r2, #0xf                   @ 0800A090
L_0800A092:
	ldr r0, [r0, #0x20]                 @ 0800A092
	movs r2, #2                         @ 0800A094
	str r1, [r0, #0x2c]                 @ 0800A096
	ldrb r1, [r0, #0xc]                 @ 0800A098
	orrs r1, r2                         @ 0800A09A
	strb r1, [r0, #0xc]                 @ 0800A09C
	bx lr                               @ 0800A09E

@ --------------------------------------------------------------------------------------------
@ Hxy vibrato: speed x, depth y*4 (zero nibbles keep the old value).
	.thumb_func
	.global Fx_H_Vibrato
Fx_H_Vibrato:
	push {r4, lr}                       @ 0800A0A0
	adds r4, r0, #0                     @ 0800A0A2
	bl Fx_None                          @ 0800A0A4
	ldrb r2, [r4, #0xa]                 @ 0800A0A8
	lsls r0, r2, #0x1d                  @ 0800A0AA
	lsrs r0, r0, #0x1f                  @ 0800A0AC
	beq L_0800A124                      @ 0800A0AE
	ldrb r0, [r4, #0x18]                @ 0800A0B0
	movs r1, #0x11                      @ 0800A0B2
	ands r0, r1                         @ 0800A0B4
	beq L_0800A0BC                      @ 0800A0B6
	movs r0, #0                         @ 0800A0B8
	strb r0, [r4, #0x11]                @ 0800A0BA
L_0800A0BC:
	movs r0, #0x1e                      @ 0800A0BC
	ldrb r0, [r0, r4]                   @ 0800A0BE
	lsls r1, r0, #0x1c                  @ 0800A0C0
	lsrs r1, r1, #0x1c                  @ 0800A0C2
	beq L_0800A0CA                      @ 0800A0C4
	lsls r1, r1, #2                     @ 0800A0C6
	strb r1, [r4, #0x10]                @ 0800A0C8
L_0800A0CA:
	lsls r1, r0, #0x18                  @ 0800A0CA
	lsrs r1, r1, #0x1c                  @ 0800A0CC
	beq L_0800A114                      @ 0800A0CE
	lsrs r0, r0, #4                     @ 0800A0D0
	strb r0, [r4, #0xf]                 @ 0800A0D2
	b L_0800A114                        @ 0800A0D4
	movs r0, r0                         @ 0800A0D6
L_0800A0D8:
	.word NoteFreqTab	@ 0x080113A8
L_0800A0DC:
	.word wf1_MusInstrTab	@ 0x085B8258
L_0800A0E0:
	.word mus_speed	@ 0x03003CFC
L_0800A0E4:
	.word mus_rows	@ 0x03003CFA
L_0800A0E8:
	.word mus_row	@ 0x03003CF9
L_0800A0EC:
	.word mus_order	@ 0x03003CFE
L_0800A0F0:
	.word Tick_VolSlideUp	@ 0x08009DAB
L_0800A0F4:
	.word Tick_VolSlideDown	@ 0x08009D7F
L_0800A0F8:
	.word PortaDownTab	@ 0x08011888
L_0800A0FC:
	.word Tick_PortaDown	@ 0x08009E53
L_0800A100:
	.word PortaUpTab	@ 0x08011608
L_0800A104:
	.word Tick_PortaUp	@ 0x08009EE1
L_0800A108:
	.word Tick_TonePortaUp	@ 0x08009FAD
L_0800A10C:
	.word Tick_TonePortaDown	@ 0x08009F6F
L_0800A110:
	.word VibratoSine	@ 0x08011A88
L_0800A114:
	ldr r0, L_0800A4E0                  @ 0800A114 =0x0800A05D
	str r0, [r4, #0x14]                 @ 0800A116
	movs r0, #1                         @ 0800A118
	orrs r0, r2                         @ 0800A11A
	strb r0, [r4, #0xa]                 @ 0800A11C
	adds r0, r4, #0                     @ 0800A11E
	bl Tick_Vibrato                     @ 0800A120
L_0800A124:
	pop {r4, pc}                        @ 0800A124

@ --------------------------------------------------------------------------------------------
@ empty functions: unreferenced (the converter maps unsupported effects to Fx_None)
	.thumb_func
	.global Fx_Empty1
Fx_Empty1:
	bx lr                               @ 0800A126
	.thumb_func
	.global Fx_Empty2
Fx_Empty2:
	bx lr                               @ 0800A128

@ --------------------------------------------------------------------------------------------
@ tick handler for K: volume slide down + vibrato.
	.thumb_func
	.global Tick_VibratoVolDown
Tick_VibratoVolDown:
	push {lr}                           @ 0800A12A
	ldrb r1, [r0, #8]                   @ 0800A12C
	ldrb r2, [r0, #0xb]                 @ 0800A12E
	subs r1, r1, r2                     @ 0800A130
	lsls r1, r1, #0x18                  @ 0800A132
	asrs r1, r1, #0x18                  @ 0800A134
	strb r1, [r0, #8]                   @ 0800A136
	cmp r1, #0                          @ 0800A138
	bgt L_0800A144                      @ 0800A13A
	movs r1, #0                         @ 0800A13C
	strb r1, [r0, #8]                   @ 0800A13E
	ldr r1, L_0800A4E0                  @ 0800A140 =0x0800A05D
	str r1, [r0, #0x14]                 @ 0800A142
L_0800A144:
	ldrb r2, [r0, #8]                   @ 0800A144
	ldr r1, [r0, #0x20]                 @ 0800A146
	movs r3, #0x10                      @ 0800A148
	strb r2, [r1, #0x10]                @ 0800A14A
	ldrb r2, [r1, #0xc]                 @ 0800A14C
	orrs r2, r3                         @ 0800A14E
	strb r2, [r1, #0xc]                 @ 0800A150
	bl Tick_Vibrato                     @ 0800A152
	pop {pc}                            @ 0800A156

@ --------------------------------------------------------------------------------------------
@ tick handler for K: volume slide up + vibrato.
	.thumb_func
	.global Tick_VibratoVolUp
Tick_VibratoVolUp:
	push {lr}                           @ 0800A158
	ldrb r1, [r0, #8]                   @ 0800A15A
	ldrb r2, [r0, #0xb]                 @ 0800A15C
	adds r1, r1, r2                     @ 0800A15E
	lsls r1, r1, #0x18                  @ 0800A160
	asrs r1, r1, #0x18                  @ 0800A162
	strb r1, [r0, #8]                   @ 0800A164
	cmp r1, #0x40                       @ 0800A166
	blt L_0800A172                      @ 0800A168
	movs r1, #0x40                      @ 0800A16A
	strb r1, [r0, #8]                   @ 0800A16C
	ldr r1, L_0800A4E0                  @ 0800A16E =0x0800A05D
	str r1, [r0, #0x14]                 @ 0800A170
L_0800A172:
	ldrb r2, [r0, #8]                   @ 0800A172
	ldr r1, [r0, #0x20]                 @ 0800A174
	movs r3, #0x10                      @ 0800A176
	strb r2, [r1, #0x10]                @ 0800A178
	ldrb r2, [r1, #0xc]                 @ 0800A17A
	orrs r2, r3                         @ 0800A17C
	strb r2, [r1, #0xc]                 @ 0800A17E
	bl Tick_Vibrato                     @ 0800A180
	pop {pc}                            @ 0800A184

@ --------------------------------------------------------------------------------------------
@ Kxy: continue vibrato with volume slide xy (D rules).
	.thumb_func
	.global Fx_K_VibratoVolSlide
Fx_K_VibratoVolSlide:
	push {r4, r5, lr}                   @ 0800A186
	adds r4, r0, #0                     @ 0800A188
	bl Fx_None                          @ 0800A18A
	movs r0, #0x1e                      @ 0800A18E
	ldrb r0, [r0, r4]                   @ 0800A190
	cmp r0, #0                          @ 0800A192
	beq L_0800A198                      @ 0800A194
	strb r0, [r4, #0xc]                 @ 0800A196
L_0800A198:
	ldrb r0, [r4, #0xa]                 @ 0800A198
	lsls r0, r0, #0x1d                  @ 0800A19A
	lsrs r0, r0, #0x1f                  @ 0800A19C
	beq L_0800A21A                      @ 0800A19E
	ldrb r0, [r4, #0x18]                @ 0800A1A0
	movs r1, #0x11                      @ 0800A1A2
	ands r0, r1                         @ 0800A1A4
	beq L_0800A1AC                      @ 0800A1A6
	movs r0, #0                         @ 0800A1A8
	strb r0, [r4, #0x11]                @ 0800A1AA
L_0800A1AC:
	ldrb r0, [r4, #0xc]                 @ 0800A1AC
	lsls r1, r0, #0x1c                  @ 0800A1AE
	lsrs r1, r1, #0x1c                  @ 0800A1B0
	bne L_0800A1CA                      @ 0800A1B2
	lsrs r0, r0, #4                     @ 0800A1B4
	strb r0, [r4, #0xb]                 @ 0800A1B6
	ldr r0, L_0800A4E4                  @ 0800A1B8 =0x0800A159
	str r0, [r4, #0x14]                 @ 0800A1BA
	ldrb r0, [r4, #0xb]                 @ 0800A1BC
	cmp r0, #0xf                        @ 0800A1BE
	bne L_0800A20C                      @ 0800A1C0
	adds r0, r4, #0                     @ 0800A1C2
	bl Tick_VolSlideUp                  @ 0800A1C4
	b L_0800A20C                        @ 0800A1C8
L_0800A1CA:
	lsls r2, r0, #0x18                  @ 0800A1CA
	lsrs r2, r2, #0x1c                  @ 0800A1CC
	bne L_0800A1E6                      @ 0800A1CE
	ldrb r0, [r4, #0xc]                 @ 0800A1D0
	strb r0, [r4, #0xb]                 @ 0800A1D2
	ldr r0, L_0800A4E8                  @ 0800A1D4 =0x0800A12B
	str r0, [r4, #0x14]                 @ 0800A1D6
	ldrb r0, [r4, #0xb]                 @ 0800A1D8
	cmp r0, #0xf                        @ 0800A1DA
	bne L_0800A20C                      @ 0800A1DC
	adds r0, r4, #0                     @ 0800A1DE
	bl Tick_VolSlideDown                @ 0800A1E0
	b L_0800A20C                        @ 0800A1E4
L_0800A1E6:
	movs r3, #0xf                       @ 0800A1E6
	bics r3, r0                         @ 0800A1E8
	cmp r3, #0                          @ 0800A1EA
	ldr r5, L_0800A4E0                  @ 0800A1EC =0x0800A05D
	bne L_0800A1FE                      @ 0800A1EE
	lsrs r0, r0, #4                     @ 0800A1F0
	strb r0, [r4, #0xb]                 @ 0800A1F2
	adds r0, r4, #0                     @ 0800A1F4
	bl Tick_VolSlideUp                  @ 0800A1F6
	str r5, [r4, #0x14]                 @ 0800A1FA
	b L_0800A20C                        @ 0800A1FC
L_0800A1FE:
	cmp r2, #0xf                        @ 0800A1FE
	bne L_0800A20C                      @ 0800A200
	strb r1, [r4, #0xb]                 @ 0800A202
	adds r0, r4, #0                     @ 0800A204
	bl Tick_VolSlideDown                @ 0800A206
	str r5, [r4, #0x14]                 @ 0800A20A
L_0800A20C:
	ldrb r0, [r4, #0xa]                 @ 0800A20C
	movs r1, #1                         @ 0800A20E
	orrs r0, r1                         @ 0800A210
	strb r0, [r4, #0xa]                 @ 0800A212
	adds r0, r4, #0                     @ 0800A214
	bl Tick_Vibrato                     @ 0800A216
L_0800A21A:
	pop {r4, r5, pc}                    @ 0800A21A

@ --------------------------------------------------------------------------------------------
@ Lxy: continue tone portamento with volume slide xy (D rules); the tick handler is
@ picked from TonePortaVolTicks[direction*3 + slide kind].
	.thumb_func
	.global Fx_L_TonePortaVolSlide
Fx_L_TonePortaVolSlide:
	push {r4, r5, lr}                   @ 0800A21C
	adds r4, r0, #0                     @ 0800A21E
	adds r0, #0x10                      @ 0800A220
	ldrb r0, [r0, #0xe]                 @ 0800A222
	cmp r0, #0                          @ 0800A224
	beq L_0800A22A                      @ 0800A226
	strb r0, [r4, #0xc]                 @ 0800A228
L_0800A22A:
	ldrb r0, [r4, #0xa]                 @ 0800A22A
	lsls r0, r0, #0x1d                  @ 0800A22C
	lsrs r0, r0, #0x1f                  @ 0800A22E
	beq L_0800A2F6                      @ 0800A230
	ldrb r0, [r4, #0x18]                @ 0800A232
	movs r5, #0                         @ 0800A234
	movs r1, #0x44                      @ 0800A236
	ands r0, r1                         @ 0800A238
	beq L_0800A24E                      @ 0800A23A
	ldrb r0, [r4, #0x1c]                @ 0800A23C
	movs r2, #0x10                      @ 0800A23E
	strb r0, [r4, #8]                   @ 0800A240
	ldrb r1, [r4, #8]                   @ 0800A242
	ldr r0, [r4, #0x20]                 @ 0800A244
	strb r1, [r0, #0x10]                @ 0800A246
	ldrb r1, [r0, #0xc]                 @ 0800A248
	orrs r1, r2                         @ 0800A24A
	strb r1, [r0, #0xc]                 @ 0800A24C
L_0800A24E:
	ldrb r0, [r4, #0xc]                 @ 0800A24E
	lsls r1, r0, #0x1c                  @ 0800A250
	lsrs r1, r1, #0x1c                  @ 0800A252
	bne L_0800A26A                      @ 0800A254
	lsrs r0, r0, #4                     @ 0800A256
	strb r0, [r4, #0xb]                 @ 0800A258
	ldrb r0, [r4, #0xb]                 @ 0800A25A
	movs r5, #1                         @ 0800A25C
	cmp r0, #0xf                        @ 0800A25E
	bne L_0800A2A2                      @ 0800A260
	adds r0, r4, #0                     @ 0800A262
	bl Tick_VolSlideUp                  @ 0800A264
	b L_0800A2A2                        @ 0800A268
L_0800A26A:
	lsls r2, r0, #0x18                  @ 0800A26A
	lsrs r2, r2, #0x1c                  @ 0800A26C
	bne L_0800A284                      @ 0800A26E
	ldrb r0, [r4, #0xc]                 @ 0800A270
	movs r5, #2                         @ 0800A272
	strb r0, [r4, #0xb]                 @ 0800A274
	ldrb r0, [r4, #0xb]                 @ 0800A276
	cmp r0, #0xf                        @ 0800A278
	bne L_0800A2A2                      @ 0800A27A
	adds r0, r4, #0                     @ 0800A27C
	bl Tick_VolSlideDown                @ 0800A27E
	b L_0800A2A2                        @ 0800A282
L_0800A284:
	movs r3, #0xf                       @ 0800A284
	bics r3, r0                         @ 0800A286
	bne L_0800A296                      @ 0800A288
	lsrs r0, r0, #4                     @ 0800A28A
	strb r0, [r4, #0xb]                 @ 0800A28C
	adds r0, r4, #0                     @ 0800A28E
	bl Tick_VolSlideUp                  @ 0800A290
	b L_0800A2A2                        @ 0800A294
L_0800A296:
	cmp r2, #0xf                        @ 0800A296
	bne L_0800A2A2                      @ 0800A298
	strb r1, [r4, #0xb]                 @ 0800A29A
	adds r0, r4, #0                     @ 0800A29C
	bl Tick_VolSlideDown                @ 0800A29E
L_0800A2A2:
	ldrb r0, [r4, #0x18]                @ 0800A2A2
	movs r1, #0x11                      @ 0800A2A4
	ands r0, r1                         @ 0800A2A6
	movs r1, #1                         @ 0800A2A8
	cmp r0, #0                          @ 0800A2AA
	beq L_0800A2C6                      @ 0800A2AC
	ldrb r0, [r4, #0x1a]                @ 0800A2AE
	cmp r0, #0xff                       @ 0800A2B0
	beq L_0800A2F6                      @ 0800A2B2
	ldr r2, L_0800A4EC                  @ 0800A2B4 =0x080113A8
	lsls r0, r0, #2                     @ 0800A2B6
	ldr r0, [r2, r0]                    @ 0800A2B8
	movs r2, #8                         @ 0800A2BA
	str r0, [r4, #4]                    @ 0800A2BC
	ldrb r0, [r4, #0xa]                 @ 0800A2BE
	orrs r0, r2                         @ 0800A2C0
	strb r0, [r4, #0xa]                 @ 0800A2C2
	b L_0800A2E0                        @ 0800A2C4
L_0800A2C6:
	ldrb r0, [r4, #0xa]                 @ 0800A2C6
	lsls r2, r0, #0x1c                  @ 0800A2C8
	bmi L_0800A2E0                      @ 0800A2CA
	cmp r5, #0                          @ 0800A2CC
	beq L_0800A2E0                      @ 0800A2CE
	cmp r5, #1                          @ 0800A2D0
	beq L_0800A2F8                      @ 0800A2D2
	cmp r5, #2                          @ 0800A2D4
	bne L_0800A2E0                      @ 0800A2D6
	ldr r2, L_0800A4F0                  @ 0800A2D8 =0x08009D7F
	orrs r0, r1                         @ 0800A2DA
	str r2, [r4, #0x14]                 @ 0800A2DC
	strb r0, [r4, #0xa]                 @ 0800A2DE
L_0800A2E0:
	ldr r0, [r4, #4]                    @ 0800A2E0
	ldr r2, [r4]                        @ 0800A2E2
	cmp r0, r2                          @ 0800A2E4
	bls L_0800A302                      @ 0800A2E6
	ldr r2, L_0800A4F4                  @ 0800A2E8 =0x08011AC8
	lsls r0, r5, #2                     @ 0800A2EA
	ldr r0, [r2, r0]                    @ 0800A2EC
	str r0, [r4, #0x14]                 @ 0800A2EE
	ldrb r0, [r4, #0xa]                 @ 0800A2F0
	orrs r0, r1                         @ 0800A2F2
	strb r0, [r4, #0xa]                 @ 0800A2F4
L_0800A2F6:
	pop {r4, r5, pc}                    @ 0800A2F6
L_0800A2F8:
	ldr r2, L_0800A4F8                  @ 0800A2F8 =0x08009DAB
	orrs r0, r1                         @ 0800A2FA
	str r2, [r4, #0x14]                 @ 0800A2FC
	strb r0, [r4, #0xa]                 @ 0800A2FE
	b L_0800A2E0                        @ 0800A300
L_0800A302:
	ldr r2, L_0800A4F4                  @ 0800A302 =0x08011AC8
	lsls r0, r5, #2                     @ 0800A304
	adds r2, #0xc                       @ 0800A306
	ldr r0, [r2, r0]                    @ 0800A308
	str r0, [r4, #0x14]                 @ 0800A30A
	ldrb r0, [r4, #0xa]                 @ 0800A30C
	orrs r0, r1                         @ 0800A30E
	strb r0, [r4, #0xa]                 @ 0800A310
	pop {r4, r5, pc}                    @ 0800A312
	.thumb_func
	.global Fx_Empty3
Fx_Empty3:
	bx lr                               @ 0800A314
	.thumb_func
	.global Fx_Empty4
Fx_Empty4:
	bx lr                               @ 0800A316

@ --------------------------------------------------------------------------------------------
@ Oxx: start the sample at offset xx*256 bytes.
	.thumb_func
	.global Fx_O_SampleOffset
Fx_O_SampleOffset:
	push {r4, lr}                       @ 0800A318
	adds r4, r0, #0                     @ 0800A31A
	bl Fx_None                          @ 0800A31C
	ldrb r0, [r4, #0x18]                @ 0800A320
	movs r1, #0x11                      @ 0800A322
	ands r0, r1                         @ 0800A324
	beq L_0800A33A                      @ 0800A326
	ldr r0, [r4, #0x20]                 @ 0800A328
	adds r4, #0x10                      @ 0800A32A
	ldrb r1, [r4, #0xe]                 @ 0800A32C
	movs r2, #4                         @ 0800A32E
	lsls r1, r1, #0x16                  @ 0800A330
	str r1, [r0]                        @ 0800A332
	ldrb r1, [r0, #0xc]                 @ 0800A334
	bics r1, r2                         @ 0800A336
	strb r1, [r0, #0xc]                 @ 0800A338
L_0800A33A:
	pop {r4, pc}                        @ 0800A33A
	.thumb_func
	.global Fx_Empty5
Fx_Empty5:
	bx lr                               @ 0800A33C

@ --------------------------------------------------------------------------------------------
@ tick handler: when the counter runs out restart the voice from 0; flags = 4 (see Fx_Q_Retrig).
	.thumb_func
	.global Tick_Retrig
Tick_Retrig:
	ldrb r1, [r0, #0x12]                @ 0800A33E
	subs r1, #1                         @ 0800A340
	lsls r1, r1, #0x18                  @ 0800A342
	lsrs r1, r1, #0x18                  @ 0800A344
	strb r1, [r0, #0x12]                @ 0800A346
	bne L_0800A360                      @ 0800A348
	ldr r1, [r0, #0x20]                 @ 0800A34A
	movs r3, #5                         @ 0800A34C
	ldrb r2, [r1, #0xc]                 @ 0800A34E
	orrs r2, r3                         @ 0800A350
	strb r2, [r1, #0xc]                 @ 0800A352
	ldrb r1, [r0, #0xe]                 @ 0800A354
	lsls r1, r1, #0x1c                  @ 0800A356
	lsrs r1, r1, #0x1c                  @ 0800A358
	strb r1, [r0, #0x12]                @ 0800A35A
	movs r1, #4                         @ 0800A35C
	strb r1, [r0, #0xa]                 @ 0800A35E
L_0800A360:
	bx lr                               @ 0800A360

@ --------------------------------------------------------------------------------------------
@ Qxy retrigger after y ticks (tick mode 2: runs even after the note stopped).
@ The volume-change nibble x is ignored. In this version the retrigger fires only once per row,
@ because Tick_Retrig stores 4 into the channel flags and so also clears the tick mode (v2 ORs it).
	.thumb_func
	.global Fx_Q_Retrig
Fx_Q_Retrig:
	push {r4, lr}                       @ 0800A362
	adds r4, r0, #0                     @ 0800A364
	bl Fx_None                          @ 0800A366
	movs r0, #0x1e                      @ 0800A36A
	ldrb r0, [r0, r4]                   @ 0800A36C
	cmp r0, #0                          @ 0800A36E
	beq L_0800A374                      @ 0800A370
	strb r0, [r4, #0xe]                 @ 0800A372
L_0800A374:
	ldr r0, L_0800A4FC                  @ 0800A374 =0x0800A33F
	str r0, [r4, #0x14]                 @ 0800A376
	ldrb r0, [r4, #0xe]                 @ 0800A378
	lsls r0, r0, #0x1c                  @ 0800A37A
	lsrs r0, r0, #0x1c                  @ 0800A37C
	strb r0, [r4, #0x12]                @ 0800A37E
	ldrb r0, [r4, #0xa]                 @ 0800A380
	lsrs r0, r0, #2                     @ 0800A382
	lsls r0, r0, #2                     @ 0800A384
	adds r0, #2                         @ 0800A386
	strb r0, [r4, #0xa]                 @ 0800A388
	pop {r4, pc}                        @ 0800A38A
	.thumb_func
	.global Fx_Empty6
Fx_Empty6:
	bx lr                               @ 0800A38C
	.thumb_func
	.global Fx_Empty7
Fx_Empty7:
	bx lr                               @ 0800A38E

@ --------------------------------------------------------------------------------------------
@ tick handler: after the delay runs out, trigger the row's note (Fx_None).
	.thumb_func
	.global Tick_NoteDelay
Tick_NoteDelay:
	push {lr}                           @ 0800A390
	ldrb r1, [r0, #0x12]                @ 0800A392
	subs r1, #1                         @ 0800A394
	lsls r1, r1, #0x18                  @ 0800A396
	lsrs r1, r1, #0x18                  @ 0800A398
	strb r1, [r0, #0x12]                @ 0800A39A
	bne L_0800A3A2                      @ 0800A39C
	bl Fx_None                          @ 0800A39E
L_0800A3A2:
	pop {pc}                            @ 0800A3A2

@ --------------------------------------------------------------------------------------------
@ effect 27: note delay - play the row's note after xx ticks (the converter's SDx).
	.thumb_func
	.global Fx_NoteDelay
Fx_NoteDelay:
	movs r1, #0x1e                      @ 0800A3A4
	ldrb r1, [r1, r0]                   @ 0800A3A6
	strb r1, [r0, #0x12]                @ 0800A3A8
	ldr r1, L_0800A500                  @ 0800A3AA =0x0800A391
	str r1, [r0, #0x14]                 @ 0800A3AC
	ldrb r1, [r0, #0xa]                 @ 0800A3AE
	lsrs r1, r1, #2                     @ 0800A3B0
	lsls r1, r1, #2                     @ 0800A3B2
	adds r1, #2                         @ 0800A3B4
	strb r1, [r0, #0xa]                 @ 0800A3B6
	bx lr                               @ 0800A3B8

@ --------------------------------------------------------------------------------------------
@ Txx: tempo xx BPM (samples per tick = rate*2.5/xx).
	.thumb_func
	.global Fx_T_SetTempo
Fx_T_SetTempo:
	push {r4, lr}                       @ 0800A3BA
	adds r4, r0, #0                     @ 0800A3BC
	bl Fx_None                          @ 0800A3BE
	adds r4, #0x10                      @ 0800A3C2
	ldrb r0, [r4, #0xe]                 @ 0800A3C4
	bl Mus_SetTempo                     @ 0800A3C6
	pop {r4, pc}                        @ 0800A3CA

@ --------------------------------------------------------------------------------------------
@ Uxy fine vibrato: like H but depth y (4x finer).
	.thumb_func
	.global Fx_U_FineVibrato
Fx_U_FineVibrato:
	push {r4, lr}                       @ 0800A3CC
	adds r4, r0, #0                     @ 0800A3CE
	bl Fx_None                          @ 0800A3D0
	ldrb r0, [r4, #0x18]                @ 0800A3D4
	movs r1, #0x11                      @ 0800A3D6
	ands r0, r1                         @ 0800A3D8
	beq L_0800A3E0                      @ 0800A3DA
	movs r0, #0                         @ 0800A3DC
	strb r0, [r4, #0x11]                @ 0800A3DE
L_0800A3E0:
	movs r0, #0x1e                      @ 0800A3E0
	ldrb r0, [r0, r4]                   @ 0800A3E2
	lsls r1, r0, #0x1c                  @ 0800A3E4
	lsrs r1, r1, #0x1c                  @ 0800A3E6
	beq L_0800A3EC                      @ 0800A3E8
	strb r1, [r4, #0x10]                @ 0800A3EA
L_0800A3EC:
	lsls r1, r0, #0x18                  @ 0800A3EC
	lsrs r1, r1, #0x1c                  @ 0800A3EE
	beq L_0800A3F6                      @ 0800A3F0
	lsrs r0, r0, #4                     @ 0800A3F2
	strb r0, [r4, #0xf]                 @ 0800A3F4
L_0800A3F6:
	ldr r0, L_0800A4E0                  @ 0800A3F6 =0x0800A05D
	movs r1, #1                         @ 0800A3F8
	str r0, [r4, #0x14]                 @ 0800A3FA
	ldrb r0, [r4, #0xa]                 @ 0800A3FC
	orrs r0, r1                         @ 0800A3FE
	strb r0, [r4, #0xa]                 @ 0800A400
	adds r0, r4, #0                     @ 0800A402
	bl Tick_Vibrato                     @ 0800A404
	pop {r4, pc}                        @ 0800A408
	.thumb_func
	.global Fx_Empty8
Fx_Empty8:
	bx lr                               @ 0800A40A
	.thumb_func
	.global Fx_Empty9
Fx_Empty9:
	bx lr                               @ 0800A40C

@ --------------------------------------------------------------------------------------------
@ Xxx: panning, signed -64 (left) .. +64 (right).
	.thumb_func
	.global Fx_X_SetPanning
Fx_X_SetPanning:
	push {r4, lr}                       @ 0800A40E
	adds r4, r0, #0                     @ 0800A410
	bl Fx_None                          @ 0800A412
	movs r0, #0x1e                      @ 0800A416
	ldrb r0, [r0, r4]                   @ 0800A418
	movs r2, #0x10                      @ 0800A41A
	strb r0, [r4, #9]                   @ 0800A41C
	ldr r1, [r4, #0x20]                 @ 0800A41E
	strb r0, [r1, #0x11]                @ 0800A420
	ldrb r0, [r1, #0xc]                 @ 0800A422
	orrs r0, r2                         @ 0800A424
	strb r0, [r1, #0xc]                 @ 0800A426
	pop {r4, pc}                        @ 0800A428
	.thumb_func
	.global Fx_Empty10
Fx_Empty10:
	bx lr                               @ 0800A42A
	.thumb_func
	.global Fx_Empty11
Fx_Empty11:
	bx lr                               @ 0800A42C

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento up + volume up. NOTE: when the volume reaches 64 it switches to
@ Tick_TonePortaDown (not ...Up), which snaps the pitch straight to the target.
	.thumb_func
	.global Tick_TonePortaUpVolUp
Tick_TonePortaUpVolUp:
	push {lr}                           @ 0800A42E
	ldrb r1, [r0, #0xd]                 @ 0800A430
	ldr r3, L_0800A504                  @ 0800A432 =0x08011608
	ldr r2, [r0]                        @ 0800A434
	lsls r1, r1, #1                     @ 0800A436
	ldrh r1, [r3, r1]                   @ 0800A438
	movs r3, #2                         @ 0800A43A
	muls r2, r1, r2                     @ 0800A43C
	lsrs r2, r2, #0xe                   @ 0800A43E
	str r2, [r0]                        @ 0800A440
	ldr r1, [r0, #0x20]                 @ 0800A442
	str r2, [r1, #0x2c]                 @ 0800A444
	ldrb r2, [r1, #0xc]                 @ 0800A446
	orrs r2, r3                         @ 0800A448
	strb r2, [r1, #0xc]                 @ 0800A44A
	ldmia r0!, {r1, r2}                 @ 0800A44C
	subs r0, #8                         @ 0800A44E
	cmp r1, r2                          @ 0800A450
	bhs L_0800A472                      @ 0800A452
	str r2, [r0]                        @ 0800A454
	ldr r1, [r0, #0x20]                 @ 0800A456
	str r2, [r1, #0x2c]                 @ 0800A458
	ldrb r2, [r1, #0xc]                 @ 0800A45A
	orrs r2, r3                         @ 0800A45C
	strb r2, [r1, #0xc]                 @ 0800A45E
	ldrb r1, [r0, #0xa]                 @ 0800A460
	movs r2, #8                         @ 0800A462
	bics r1, r2                         @ 0800A464
	strb r1, [r0, #0xa]                 @ 0800A466
	ldr r1, L_0800A4F8                  @ 0800A468 =0x08009DAB
	str r1, [r0, #0x14]                 @ 0800A46A
	bl Tick_VolSlideUp                  @ 0800A46C
	pop {pc}                            @ 0800A470
L_0800A472:
	ldrb r1, [r0, #8]                   @ 0800A472
	ldrb r2, [r0, #0xb]                 @ 0800A474
	adds r1, r1, r2                     @ 0800A476
	lsls r1, r1, #0x18                  @ 0800A478
	asrs r1, r1, #0x18                  @ 0800A47A
	strb r1, [r0, #8]                   @ 0800A47C
	cmp r1, #0x40                       @ 0800A47E
	blt L_0800A48A                      @ 0800A480
	movs r1, #0x40                      @ 0800A482
	strb r1, [r0, #8]                   @ 0800A484
	ldr r1, L_0800A508                  @ 0800A486 =0x08009F6F
	str r1, [r0, #0x14]                 @ 0800A488
L_0800A48A:
	ldr r1, [r0, #0x20]                 @ 0800A48A
	ldrb r0, [r0, #8]                   @ 0800A48C
	movs r2, #0x10                      @ 0800A48E
	strb r0, [r1, #0x10]                @ 0800A490
	ldrb r0, [r1, #0xc]                 @ 0800A492
	orrs r0, r2                         @ 0800A494
	strb r0, [r1, #0xc]                 @ 0800A496
	pop {pc}                            @ 0800A498

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento down + volume up.
	.thumb_func
	.global Tick_TonePortaDownVolUp
Tick_TonePortaDownVolUp:
	push {lr}                           @ 0800A49A
	ldrb r1, [r0, #0xd]                 @ 0800A49C
	ldr r3, L_0800A50C                  @ 0800A49E =0x08011888
	ldr r2, [r0]                        @ 0800A4A0
	lsls r1, r1, #1                     @ 0800A4A2
	ldrh r1, [r3, r1]                   @ 0800A4A4
	movs r3, #2                         @ 0800A4A6
	muls r2, r1, r2                     @ 0800A4A8
	lsrs r2, r2, #0x10                  @ 0800A4AA
	str r2, [r0]                        @ 0800A4AC
	ldr r1, [r0, #0x20]                 @ 0800A4AE
	str r2, [r1, #0x2c]                 @ 0800A4B0
	ldrb r2, [r1, #0xc]                 @ 0800A4B2
	orrs r2, r3                         @ 0800A4B4
	strb r2, [r1, #0xc]                 @ 0800A4B6
	ldmia r0!, {r1, r2}                 @ 0800A4B8
	subs r0, #8                         @ 0800A4BA
	cmp r1, r2                          @ 0800A4BC
	bhs L_0800A510                      @ 0800A4BE
	str r2, [r0]                        @ 0800A4C0
	ldr r1, [r0, #0x20]                 @ 0800A4C2
	str r2, [r1, #0x2c]                 @ 0800A4C4
	ldrb r2, [r1, #0xc]                 @ 0800A4C6
	orrs r2, r3                         @ 0800A4C8
	strb r2, [r1, #0xc]                 @ 0800A4CA
	ldrb r1, [r0, #0xa]                 @ 0800A4CC
	movs r2, #8                         @ 0800A4CE
	bics r1, r2                         @ 0800A4D0
	strb r1, [r0, #0xa]                 @ 0800A4D2
	ldr r1, L_0800A4F8                  @ 0800A4D4 =0x08009DAB
	str r1, [r0, #0x14]                 @ 0800A4D6
	bl Tick_VolSlideUp                  @ 0800A4D8
	pop {pc}                            @ 0800A4DC
	movs r0, r0                         @ 0800A4DE
L_0800A4E0:
	.word Tick_Vibrato	@ 0x0800A05D
L_0800A4E4:
	.word Tick_VibratoVolUp	@ 0x0800A159
L_0800A4E8:
	.word Tick_VibratoVolDown	@ 0x0800A12B
L_0800A4EC:
	.word NoteFreqTab	@ 0x080113A8
L_0800A4F0:
	.word Tick_VolSlideDown	@ 0x08009D7F
L_0800A4F4:
	.word TonePortaVolTicks	@ 0x08011AC8
L_0800A4F8:
	.word Tick_VolSlideUp	@ 0x08009DAB
L_0800A4FC:
	.word Tick_Retrig	@ 0x0800A33F
L_0800A500:
	.word Tick_NoteDelay	@ 0x0800A391
L_0800A504:
	.word PortaUpTab	@ 0x08011608
L_0800A508:
	.word Tick_TonePortaDown	@ 0x08009F6F
L_0800A50C:
	.word PortaDownTab	@ 0x08011888
L_0800A510:
	ldrb r1, [r0, #8]                   @ 0800A510
	ldrb r2, [r0, #0xb]                 @ 0800A512
	adds r1, r1, r2                     @ 0800A514
	lsls r1, r1, #0x18                  @ 0800A516
	asrs r1, r1, #0x18                  @ 0800A518
	strb r1, [r0, #8]                   @ 0800A51A
	cmp r1, #0x40                       @ 0800A51C
	blt L_0800A528                      @ 0800A51E
	movs r1, #0x40                      @ 0800A520
	strb r1, [r0, #8]                   @ 0800A522
	ldr r1, L_0800A610                  @ 0800A524 =0x08009F6F
	str r1, [r0, #0x14]                 @ 0800A526
L_0800A528:
	ldr r1, [r0, #0x20]                 @ 0800A528
	ldrb r0, [r0, #8]                   @ 0800A52A
	movs r2, #0x10                      @ 0800A52C
	strb r0, [r1, #0x10]                @ 0800A52E
	ldrb r0, [r1, #0xc]                 @ 0800A530
	orrs r0, r2                         @ 0800A532
	strb r0, [r1, #0xc]                 @ 0800A534
	pop {pc}                            @ 0800A536

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento up + volume down. Same slip as above when the volume reaches 0.
	.thumb_func
	.global Tick_TonePortaUpVolDown
Tick_TonePortaUpVolDown:
	push {lr}                           @ 0800A538
	ldrb r1, [r0, #0xd]                 @ 0800A53A
	ldr r3, L_0800A614                  @ 0800A53C =0x08011608
	ldr r2, [r0]                        @ 0800A53E
	lsls r1, r1, #1                     @ 0800A540
	ldrh r1, [r3, r1]                   @ 0800A542
	movs r3, #2                         @ 0800A544
	muls r2, r1, r2                     @ 0800A546
	lsrs r2, r2, #0xe                   @ 0800A548
	str r2, [r0]                        @ 0800A54A
	ldr r1, [r0, #0x20]                 @ 0800A54C
	str r2, [r1, #0x2c]                 @ 0800A54E
	ldrb r2, [r1, #0xc]                 @ 0800A550
	orrs r2, r3                         @ 0800A552
	strb r2, [r1, #0xc]                 @ 0800A554
	ldmia r0!, {r1, r2}                 @ 0800A556
	subs r0, #8                         @ 0800A558
	cmp r1, r2                          @ 0800A55A
	bls L_0800A57C                      @ 0800A55C
	str r2, [r0]                        @ 0800A55E
	ldr r1, [r0, #0x20]                 @ 0800A560
	str r2, [r1, #0x2c]                 @ 0800A562
	ldrb r2, [r1, #0xc]                 @ 0800A564
	orrs r2, r3                         @ 0800A566
	strb r2, [r1, #0xc]                 @ 0800A568
	ldrb r1, [r0, #0xa]                 @ 0800A56A
	movs r2, #8                         @ 0800A56C
	bics r1, r2                         @ 0800A56E
	strb r1, [r0, #0xa]                 @ 0800A570
	ldr r1, L_0800A618                  @ 0800A572 =0x08009D7F
	str r1, [r0, #0x14]                 @ 0800A574
	bl Tick_VolSlideDown                @ 0800A576
	pop {pc}                            @ 0800A57A
L_0800A57C:
	ldrb r1, [r0, #8]                   @ 0800A57C
	ldrb r2, [r0, #0xb]                 @ 0800A57E
	subs r1, r1, r2                     @ 0800A580
	lsls r1, r1, #0x18                  @ 0800A582
	asrs r1, r1, #0x18                  @ 0800A584
	strb r1, [r0, #8]                   @ 0800A586
	cmp r1, #0                          @ 0800A588
	bgt L_0800A594                      @ 0800A58A
	movs r1, #0                         @ 0800A58C
	strb r1, [r0, #8]                   @ 0800A58E
	ldr r1, L_0800A610                  @ 0800A590 =0x08009F6F
	str r1, [r0, #0x14]                 @ 0800A592
L_0800A594:
	ldr r1, [r0, #0x20]                 @ 0800A594
	ldrb r0, [r0, #8]                   @ 0800A596
L_0800A598:
	movs r2, #0x10                      @ 0800A598
	strb r0, [r1, #0x10]                @ 0800A59A
	ldrb r0, [r1, #0xc]                 @ 0800A59C
	orrs r0, r2                         @ 0800A59E
	strb r0, [r1, #0xc]                 @ 0800A5A0
	pop {pc}                            @ 0800A5A2

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento down + volume down.
	.thumb_func
	.global Tick_TonePortaDownVolDown
Tick_TonePortaDownVolDown:
	push {lr}                           @ 0800A5A4
	ldrb r1, [r0, #0xd]                 @ 0800A5A6
	ldr r3, L_0800A61C                  @ 0800A5A8 =0x08011888
	ldr r2, [r0]                        @ 0800A5AA
	lsls r1, r1, #1                     @ 0800A5AC
	ldrh r1, [r3, r1]                   @ 0800A5AE
	movs r3, #2                         @ 0800A5B0
	muls r2, r1, r2                     @ 0800A5B2
	lsrs r2, r2, #0x10                  @ 0800A5B4
	str r2, [r0]                        @ 0800A5B6
	ldr r1, [r0, #0x20]                 @ 0800A5B8
	str r2, [r1, #0x2c]                 @ 0800A5BA
	ldrb r2, [r1, #0xc]                 @ 0800A5BC
	orrs r2, r3                         @ 0800A5BE
	strb r2, [r1, #0xc]                 @ 0800A5C0
	ldmia r0!, {r1, r2}                 @ 0800A5C2
	subs r0, #8                         @ 0800A5C4
	cmp r1, r2                          @ 0800A5C6
	bhs L_0800A5E8                      @ 0800A5C8
	str r2, [r0]                        @ 0800A5CA
	ldr r1, [r0, #0x20]                 @ 0800A5CC
	str r2, [r1, #0x2c]                 @ 0800A5CE
	ldrb r2, [r1, #0xc]                 @ 0800A5D0
	orrs r2, r3                         @ 0800A5D2
	strb r2, [r1, #0xc]                 @ 0800A5D4
	ldrb r1, [r0, #0xa]                 @ 0800A5D6
	movs r2, #8                         @ 0800A5D8
	bics r1, r2                         @ 0800A5DA
	strb r1, [r0, #0xa]                 @ 0800A5DC
	ldr r1, L_0800A618                  @ 0800A5DE =0x08009D7F
	str r1, [r0, #0x14]                 @ 0800A5E0
	bl Tick_VolSlideDown                @ 0800A5E2
	pop {pc}                            @ 0800A5E6
L_0800A5E8:
	ldrb r1, [r0, #8]                   @ 0800A5E8
	ldrb r2, [r0, #0xb]                 @ 0800A5EA
	subs r1, r1, r2                     @ 0800A5EC
	lsls r1, r1, #0x18                  @ 0800A5EE
	asrs r1, r1, #0x18                  @ 0800A5F0
	strb r1, [r0, #8]                   @ 0800A5F2
	cmp r1, #0                          @ 0800A5F4
	bgt L_0800A600                      @ 0800A5F6
	movs r1, #0                         @ 0800A5F8
	strb r1, [r0, #8]                   @ 0800A5FA
L_0800A5FC:
	ldr r1, L_0800A610                  @ 0800A5FC =0x08009F6F
	str r1, [r0, #0x14]                 @ 0800A5FE
L_0800A600:
	ldr r1, [r0, #0x20]                 @ 0800A600
	ldrb r0, [r0, #8]                   @ 0800A602
	movs r2, #0x10                      @ 0800A604
	strb r0, [r1, #0x10]                @ 0800A606
	ldrb r0, [r1, #0xc]                 @ 0800A608
	orrs r0, r2                         @ 0800A60A
	strb r0, [r1, #0xc]                 @ 0800A60C
	pop {pc}                            @ 0800A60E
L_0800A610:
	.word Tick_TonePortaDown	@ 0x08009F6F
L_0800A614:
	.word PortaUpTab	@ 0x08011608
L_0800A618:
	.word Tick_VolSlideDown	@ 0x08009D7F
L_0800A61C:
	.word PortaDownTab	@ 0x08011888

@ --------------------------------------------------------------------------------------------
@ void Mus_SetTempo(int bpm): samples per tick = (rate*2 + rate/2) / bpm.
	.thumb_func
	.global Mus_SetTempo
Mus_SetTempo:
	push {r4, lr}                       @ 0800A620
	ldr r4, L_0800A8E8                  @ 0800A622 =0x03003CF8
	ldr r1, L_0800A8EC                  @ 0800A624 =0x03003D2A
	strb r0, [r4, #5]                   @ 0800A626
	ldrh r1, [r1]                       @ 0800A628
	lsls r2, r1, #1                     @ 0800A62A
	lsrs r1, r1, #1                     @ 0800A62C
	adds r1, r2, r1                     @ 0800A62E
	bl __rt_udiv                        @ 0800A630
	strh r0, [r4, #8]                   @ 0800A634
	pop {r4, pc}                        @ 0800A636

@ --------------------------------------------------------------------------------------------
@ per-tick work of one channel: call its tick handler in tick mode 1 (only while the note
@ sounds) or 2 (always).
	.thumb_func
	.global Mus_ChannelTick
Mus_ChannelTick:
	push {r3, lr}                       @ 0800A638
	ldrb r2, [r0, #0xa]                 @ 0800A63A
	lsls r1, r2, #0x1e                  @ 0800A63C
	lsrs r1, r1, #0x1e                  @ 0800A63E
	beq L_0800A650                      @ 0800A640
	cmp r1, #1                          @ 0800A642
	bne L_0800A64A                      @ 0800A644
	lsls r1, r2, #0x1d                  @ 0800A646
	bpl L_0800A650                      @ 0800A648
L_0800A64A:
	ldr r1, [r0, #0x14]                 @ 0800A64A
L_0800A64C:
	bl __call_via_r1                    @ 0800A64C
L_0800A650:
	pop {r3, pc}                        @ 0800A650

@ --------------------------------------------------------------------------------------------
@ per-row work of one channel: clear the tick mode, restore the voice pitch after vibrato,
@ then call FxTab[effect] (effect 0 when the row has no effect byte, nothing if the channel is absent).
	.thumb_func
	.global Mus_ChannelRow
Mus_ChannelRow:
	push {r3, lr}                       @ 0800A652
	ldrb r1, [r0, #0xa]                 @ 0800A654
	lsrs r1, r1, #2                     @ 0800A656
L_0800A658:
	lsls r1, r1, #2                     @ 0800A658
	strb r1, [r0, #0xa]                 @ 0800A65A
	lsls r1, r1, #0x1d                  @ 0800A65C
	bpl L_0800A674                      @ 0800A65E
	ldr r2, [r0, #0x20]                 @ 0800A660
	ldr r3, [r2, #0x2c]                 @ 0800A662
	ldr r1, [r0]                        @ 0800A664
	cmp r3, r1                          @ 0800A666
	beq L_0800A674                      @ 0800A668
	str r1, [r2, #0x2c]                 @ 0800A66A
	ldrb r1, [r2, #0xc]                 @ 0800A66C
	movs r3, #2                         @ 0800A66E
	orrs r1, r3                         @ 0800A670
	strb r1, [r2, #0xc]                 @ 0800A672
L_0800A674:
	ldrb r2, [r0, #0x18]                @ 0800A674
	cmp r2, #0                          @ 0800A676
	beq L_0800A690                      @ 0800A678
	movs r1, #0x1d                      @ 0800A67A
	movs r3, #0x88                      @ 0800A67C
	ands r2, r3                         @ 0800A67E
	ldrb r1, [r1, r0]                   @ 0800A680
	bne L_0800A686                      @ 0800A682
	movs r1, #0                         @ 0800A684
L_0800A686:
	ldr r2, L_0800A8F0                  @ 0800A686 =0x0818CDF8
	lsls r1, r1, #2                     @ 0800A688
	ldr r1, [r2, r1]                    @ 0800A68A
	bl __call_via_r1                    @ 0800A68C
L_0800A690:
	pop {r3, pc}                        @ 0800A690

@ --------------------------------------------------------------------------------------------
@ Advance one row: at the end of a pattern step the order list (0xFF wraps to order 0) and
@ fetch the pattern's row count. Clear all channel masks, then decode the packed row:
@   ctrl byte (0 ends the row): low nibble = channel+1, high nibble 0 = mask byte follows,
@   1 = reuse the channel's last mask, 2..15 = RowMaskTab[n-2];
@   mask bits 1/2/4/8 read note/instrument/volume/effect+param, bits 0x10/0x20/0x40/0x80 mark
@   the same fields as present but repeated from the channel's previous values.
	.thumb_func
	.global Mus_ReadRow
Mus_ReadRow:
	push {r4, r5, r6}                   @ 0800A692
	ldr r1, L_0800A8E8                  @ 0800A694 =0x03003CF8
	ldrb r0, [r1, #1]                   @ 0800A696
	adds r0, #1                         @ 0800A698
	lsls r2, r0, #0x18                  @ 0800A69A
	lsrs r2, r2, #0x18                  @ 0800A69C
	strb r2, [r1, #1]                   @ 0800A69E
	ldrb r3, [r1, #2]                   @ 0800A6A0
	movs r0, #0                         @ 0800A6A2
	cmp r2, r3                          @ 0800A6A4
	blo L_0800A6D4                      @ 0800A6A6
	ldrh r2, [r1, #6]                   @ 0800A6A8
	adds r2, #1                         @ 0800A6AA
	lsls r3, r2, #0x10                  @ 0800A6AC
	asrs r3, r3, #0x10                  @ 0800A6AE
	strh r3, [r1, #6]                   @ 0800A6B0
	ldr r4, [r1, #0xc]                  @ 0800A6B2
	ldr r2, [r4, #4]                    @ 0800A6B4
	ldrb r3, [r2, r3]                   @ 0800A6B6
	cmp r3, #0xff                       @ 0800A6B8
	bne L_0800A6BE                      @ 0800A6BA
	strh r0, [r1, #6]                   @ 0800A6BC
L_0800A6BE:
	movs r3, #6                         @ 0800A6BE
	ldrsh r5, [r1, r3]                  @ 0800A6C0
	ldr r4, [r4]                        @ 0800A6C2
	ldrb r2, [r2, r5]                   @ 0800A6C4
	lsls r2, r2, #2                     @ 0800A6C6
	ldr r2, [r4, r2]                    @ 0800A6C8
	strb r0, [r1, #1]                   @ 0800A6CA
	ldrb r3, [r2]                       @ 0800A6CC
	adds r2, #1                         @ 0800A6CE
	str r2, [r1, #0x10]                 @ 0800A6D0
	strb r3, [r1, #2]                   @ 0800A6D2
L_0800A6D4:
	ldr r4, L_0800A8F4                  @ 0800A6D4 =0x0203EE30
	movs r2, #0                         @ 0800A6D6
L_0800A6D8:
	lsls r3, r2, #3                     @ 0800A6D8
	adds r3, r3, r2                     @ 0800A6DA
	lsls r3, r3, #2                     @ 0800A6DC
	adds r3, r3, r4                     @ 0800A6DE
	adds r2, #1                         @ 0800A6E0
	cmp r2, #0xf                        @ 0800A6E2
	strb r0, [r3, #0xc]                 @ 0800A6E4
	blt L_0800A6D8                      @ 0800A6E6
	ldr r4, L_0800A8F8                  @ 0800A6E8 =0x0203EE24
	ldr r5, L_0800A8FC                  @ 0800A6EA =0x08142518
L_0800A6EC:
	ldr r2, [r1, #0x10]                 @ 0800A6EC
	ldrb r0, [r2]                       @ 0800A6EE
	adds r2, #1                         @ 0800A6F0
	str r2, [r1, #0x10]                 @ 0800A6F2
	cmp r0, #0                          @ 0800A6F4
	beq L_0800A76E                      @ 0800A6F6
	lsls r3, r0, #0x1c                  @ 0800A6F8
	lsrs r3, r3, #0x1c                  @ 0800A6FA
	subs r6, r3, #1                     @ 0800A6FC
	lsls r3, r6, #3                     @ 0800A6FE
	adds r3, r3, r6                     @ 0800A700
	lsls r3, r3, #2                     @ 0800A702
	adds r3, r3, r4                     @ 0800A704
	lsrs r0, r0, #4                     @ 0800A706
	cmp r0, #0                          @ 0800A708
	bne L_0800A718                      @ 0800A70A
	ldrb r0, [r2]                       @ 0800A70C
	adds r2, #1                         @ 0800A70E
	str r2, [r1, #0x10]                 @ 0800A710
	strb r0, [r3, #0x19]                @ 0800A712
	strb r0, [r3, #0x18]                @ 0800A714
	b L_0800A72A                        @ 0800A716
L_0800A718:
	cmp r0, #1                          @ 0800A718
	bne L_0800A722                      @ 0800A71A
	ldrb r0, [r3, #0x19]                @ 0800A71C
	strb r0, [r3, #0x18]                @ 0800A71E
	b L_0800A72A                        @ 0800A720
L_0800A722:
	adds r0, r5, r0                     @ 0800A722
	subs r0, #0x10                      @ 0800A724
	ldrb r0, [r0, #0xe]                 @ 0800A726
	strb r0, [r3, #0x18]                @ 0800A728
L_0800A72A:
	ldrb r0, [r3, #0x18]                @ 0800A72A
	lsls r2, r0, #0x1f                  @ 0800A72C
	bpl L_0800A73A                      @ 0800A72E
	ldr r2, [r1, #0x10]                 @ 0800A730
	ldrb r6, [r2]                       @ 0800A732
	adds r2, #1                         @ 0800A734
	str r2, [r1, #0x10]                 @ 0800A736
	strb r6, [r3, #0x1a]                @ 0800A738
L_0800A73A:
	lsls r2, r0, #0x1e                  @ 0800A73A
	bpl L_0800A748                      @ 0800A73C
	ldr r2, [r1, #0x10]                 @ 0800A73E
	ldrb r6, [r2]                       @ 0800A740
	adds r2, #1                         @ 0800A742
	str r2, [r1, #0x10]                 @ 0800A744
	strb r6, [r3, #0x1b]                @ 0800A746
L_0800A748:
	lsls r2, r0, #0x1d                  @ 0800A748
	bpl L_0800A756                      @ 0800A74A
	ldr r2, [r1, #0x10]                 @ 0800A74C
	ldrb r6, [r2]                       @ 0800A74E
	adds r2, #1                         @ 0800A750
	str r2, [r1, #0x10]                 @ 0800A752
	strb r6, [r3, #0x1c]                @ 0800A754
L_0800A756:
	lsls r0, r0, #0x1c                  @ 0800A756
	bpl L_0800A6EC                      @ 0800A758
	ldr r0, [r1, #0x10]                 @ 0800A75A
	adds r3, #0x10                      @ 0800A75C
	ldrb r2, [r0]                       @ 0800A75E
	adds r0, #1                         @ 0800A760
	strb r2, [r3, #0xd]                 @ 0800A762
	ldrb r2, [r0]                       @ 0800A764
	adds r0, #1                         @ 0800A766
	str r0, [r1, #0x10]                 @ 0800A768
	strb r2, [r3, #0xe]                 @ 0800A76A
	b L_0800A6EC                        @ 0800A76C
L_0800A76E:
	pop {r4, r5, r6}                    @ 0800A76E
	bx lr                               @ 0800A770

@ --------------------------------------------------------------------------------------------
@ One player tick: on the first tick of a row read the row and run every channel's row effect,
@ otherwise run the tick handlers; then update all 15 music voices.
	.thumb_func
	.global Mus_Tick
Mus_Tick:
	push {r4, r5, r6, lr}               @ 0800A772
	ldr r5, L_0800A8E8                  @ 0800A774 =0x03003CF8
	ldr r6, L_0800A8F8                  @ 0800A776 =0x0203EE24
	ldrb r0, [r5, #3]                   @ 0800A778
	subs r0, #1                         @ 0800A77A
	lsls r0, r0, #0x18                  @ 0800A77C
	lsrs r0, r0, #0x18                  @ 0800A77E
	strb r0, [r5, #3]                   @ 0800A780
	bne L_0800A7A2                      @ 0800A782
	bl Mus_ReadRow                      @ 0800A784
	movs r4, #0                         @ 0800A788
L_0800A78A:
	lsls r0, r4, #3                     @ 0800A78A
	adds r0, r0, r4                     @ 0800A78C
	lsls r0, r0, #2                     @ 0800A78E
	adds r0, r0, r6                     @ 0800A790
	bl Mus_ChannelRow                   @ 0800A792
	adds r4, #1                         @ 0800A796
	cmp r4, #0xf                        @ 0800A798
	blt L_0800A78A                      @ 0800A79A
	ldrb r0, [r5, #4]                   @ 0800A79C
	strb r0, [r5, #3]                   @ 0800A79E
	b L_0800A7C8                        @ 0800A7A0
L_0800A7A2:
	movs r4, #0                         @ 0800A7A2
L_0800A7A4:
	lsls r0, r4, #3                     @ 0800A7A4
	adds r0, r0, r4                     @ 0800A7A6
	lsls r0, r0, #2                     @ 0800A7A8
	adds r0, r0, r6                     @ 0800A7AA
	ldrb r2, [r0, #0xa]                 @ 0800A7AC
	lsls r1, r2, #0x1e                  @ 0800A7AE
	lsrs r1, r1, #0x1e                  @ 0800A7B0
	beq L_0800A7C2                      @ 0800A7B2
	cmp r1, #1                          @ 0800A7B4
	bne L_0800A7BC                      @ 0800A7B6
	lsls r1, r2, #0x1d                  @ 0800A7B8
	bpl L_0800A7C2                      @ 0800A7BA
L_0800A7BC:
	ldr r1, [r0, #0x14]                 @ 0800A7BC
	bl __call_via_r1                    @ 0800A7BE
L_0800A7C2:
	adds r4, #1                         @ 0800A7C2
	cmp r4, #0xf                        @ 0800A7C4
	blt L_0800A7A4                      @ 0800A7C6
L_0800A7C8:
	ldr r5, L_0800A900                  @ 0800A7C8 =0x0203F040
	movs r4, #0                         @ 0800A7CA
L_0800A7CC:
	lsls r0, r4, #6                     @ 0800A7CC
	adds r0, r0, r5                     @ 0800A7CE
	bl Voice_Update                     @ 0800A7D0
	adds r4, #1                         @ 0800A7D4
	cmp r4, #0xf                        @ 0800A7D6
	blt L_0800A7CC                      @ 0800A7D8
	pop {r4, r5, r6, pc}                @ 0800A7DA

@ --------------------------------------------------------------------------------------------
@ void Mus_MixVoices(s32 *buf, int n): mix the 15 music voices. Never called.
	.thumb_func
	.global Mus_MixVoices
Mus_MixVoices:
	push {r3, r4, r5, r6, r7, lr}       @ 0800A7DC
	adds r5, r0, #0                     @ 0800A7DE
	adds r6, r1, #0                     @ 0800A7E0
	ldr r7, L_0800A900                  @ 0800A7E2 =0x0203F040
	movs r4, #0                         @ 0800A7E4
L_0800A7E6:
	lsls r0, r4, #6                     @ 0800A7E6
	adds r0, r0, r7                     @ 0800A7E8
	adds r2, r6, #0                     @ 0800A7EA
	adds r1, r5, #0                     @ 0800A7EC
	bl Voice_Mix                        @ 0800A7EE
	adds r4, #1                         @ 0800A7F2
	cmp r4, #0xf                        @ 0800A7F4
	blt L_0800A7E6                      @ 0800A7F6
	pop {r3, r4, r5, r6, r7, pc}        @ 0800A7F8

@ --------------------------------------------------------------------------------------------
@ Mix snd.chunk samples of music into the mix buffer, splitting the chunk wherever a tick falls
@ so effects are applied with sample accuracy.
	.thumb_func
	.global Mus_Render
Mus_Render:
	push {r3, r4, r5, r6, r7, lr}       @ 0800A7FA
	ldr r0, L_0800A8E8                  @ 0800A7FC =0x03003CF8
	ldrb r1, [r0]                       @ 0800A7FE
	cmp r1, #1                          @ 0800A800
	bne L_0800A832                      @ 0800A802
	ldr r1, L_0800A904                  @ 0800A804 =0x03003D2C
	movs r3, #0                         @ 0800A806
	ldrsh r6, [r1, r3]                  @ 0800A808
	ldr r5, L_0800A908                  @ 0800A80A =0x03004018
L_0800A80C:
	ldr r0, L_0800A8E8                  @ 0800A80C =0x03003CF8
	ldrh r7, [r0, #0xa]                 @ 0800A80E
	cmp r7, r6                          @ 0800A810
	blt L_0800A834                      @ 0800A812
	ldr r7, L_0800A900                  @ 0800A814 =0x0203F040
	movs r4, #0                         @ 0800A816
L_0800A818:
	lsls r0, r4, #6                     @ 0800A818
	adds r0, r0, r7                     @ 0800A81A
	adds r2, r6, #0                     @ 0800A81C
	adds r1, r5, #0                     @ 0800A81E
	bl Voice_Mix                        @ 0800A820
	adds r4, #1                         @ 0800A824
	cmp r4, #0xf                        @ 0800A826
	blt L_0800A818                      @ 0800A828
	ldr r1, L_0800A8E8                  @ 0800A82A =0x03003CF8
	ldrh r0, [r1, #0xa]                 @ 0800A82C
	subs r0, r0, r6                     @ 0800A82E
	strh r0, [r1, #0xa]                 @ 0800A830
L_0800A832:
	pop {r3, r4, r5, r6, r7, pc}        @ 0800A832
L_0800A834:
	cmp r7, #0                          @ 0800A834
	beq L_0800A858                      @ 0800A836
	movs r4, #0                         @ 0800A838
L_0800A83A:
	ldr r1, L_0800A900                  @ 0800A83A =0x0203F040
	lsls r0, r4, #6                     @ 0800A83C
	adds r0, r0, r1                     @ 0800A83E
	adds r2, r7, #0                     @ 0800A840
	adds r1, r5, #0                     @ 0800A842
	bl Voice_Mix                        @ 0800A844
	adds r4, #1                         @ 0800A848
	cmp r4, #0xf                        @ 0800A84A
	blt L_0800A83A                      @ 0800A84C
	ldr r0, L_0800A8E8                  @ 0800A84E =0x03003CF8
	ldrh r0, [r0, #0xa]                 @ 0800A850
	lsls r1, r0, #3                     @ 0800A852
	adds r5, r1, r5                     @ 0800A854
	subs r6, r6, r0                     @ 0800A856
L_0800A858:
	bl Mus_Tick                         @ 0800A858
	ldr r1, L_0800A8E8                  @ 0800A85C =0x03003CF8
	ldrh r0, [r1, #8]                   @ 0800A85E
	strh r0, [r1, #0xa]                 @ 0800A860
	b L_0800A80C                        @ 0800A862

@ --------------------------------------------------------------------------------------------
@ void Mus_Stop(void): mus.playing = 0 (voices keep their state but are no longer mixed).
	.thumb_func
	.global Mus_Stop
Mus_Stop:
	ldr r1, L_0800A8E8                  @ 0800A864 =0x03003CF8
	movs r0, #0                         @ 0800A866
	strb r0, [r1]                       @ 0800A868
	bx lr                               @ 0800A86A

@ --------------------------------------------------------------------------------------------
@ Clear the 15 channels and their voices and re-link channel <-> voice.
	.thumb_func
	.global Mus_ResetChannels
Mus_ResetChannels:
	push {r4, r5, r6, r7}               @ 0800A86C
	ldr r1, L_0800A90C                  @ 0800A86E =0x0203EE40
	movs r0, #0                         @ 0800A870
	adds r4, r1, #0                     @ 0800A872
	subs r4, #0x1c                      @ 0800A874
	ldr r2, L_0800A900                  @ 0800A876 =0x0203F040
	movs r5, #0                         @ 0800A878
L_0800A87A:
	lsls r7, r0, #3                     @ 0800A87A
	adds r7, r7, r0                     @ 0800A87C
	lsls r7, r7, #2                     @ 0800A87E
	adds r3, r7, r4                     @ 0800A880
	adds r6, r3, #0                     @ 0800A882
	strb r5, [r3, #0xa]                 @ 0800A884
	adds r3, #0x10                      @ 0800A886
	strb r5, [r3, #0xf]                 @ 0800A888
	lsls r3, r0, #6                     @ 0800A88A
	adds r3, r3, r2                     @ 0800A88C
	adds r7, r7, r1                     @ 0800A88E
	strb r5, [r6, #0x18]                @ 0800A890
	str r3, [r7, #4]                    @ 0800A892
	strb r5, [r3, #0xc]                 @ 0800A894
	adds r0, #1                         @ 0800A896
	cmp r0, #0xf                        @ 0800A898
	str r6, [r3, #0x28]                 @ 0800A89A
	blt L_0800A87A                      @ 0800A89C
	pop {r4, r5, r6, r7}                @ 0800A89E
	bx lr                               @ 0800A8A0

@ --------------------------------------------------------------------------------------------
@ void Mus_PlaySong(const Song *s): start s from order 0 with its speed and tempo.
	.thumb_func
	.global Mus_PlaySong
Mus_PlaySong:
	push {r4, r5, r6, lr}               @ 0800A8A2
	ldr r4, L_0800A8E8                  @ 0800A8A4 =0x03003CF8
	movs r6, #1                         @ 0800A8A6
	strb r6, [r4, #2]                   @ 0800A8A8
	adds r5, r0, #0                     @ 0800A8AA
	movs r0, #0                         @ 0800A8AC
	strb r6, [r4, #3]                   @ 0800A8AE
	strb r0, [r4, #1]                   @ 0800A8B0
	str r5, [r4, #0xc]                  @ 0800A8B2
	ldrb r0, [r5, #9]                   @ 0800A8B4
	strb r0, [r4, #4]                   @ 0800A8B6
	rsbs r0, r6, #0                     @ 0800A8B8
	strh r0, [r4, #6]                   @ 0800A8BA
	bl Mus_ResetChannels                @ 0800A8BC
	ldrb r0, [r5, #8]                   @ 0800A8C0
	ldr r1, L_0800A8EC                  @ 0800A8C2 =0x03003D2A
	strb r0, [r4, #5]                   @ 0800A8C4
	ldrh r1, [r1]                       @ 0800A8C6
	lsls r2, r1, #1                     @ 0800A8C8
	lsrs r1, r1, #1                     @ 0800A8CA
	adds r1, r2, r1                     @ 0800A8CC
	bl __rt_udiv                        @ 0800A8CE
	strh r0, [r4, #8]                   @ 0800A8D2
	strb r6, [r4]                       @ 0800A8D4
	pop {r4, r5, r6, pc}                @ 0800A8D6

@ --------------------------------------------------------------------------------------------
@ void Mus_PlaySongIfNew(const Song *s): Mus_PlaySong unless s is already the current song.
	.thumb_func
	.global Mus_PlaySongIfNew
Mus_PlaySongIfNew:
	push {r3, lr}                       @ 0800A8D8
	ldr r1, L_0800A8E8                  @ 0800A8DA =0x03003CF8
	ldr r1, [r1, #0xc]                  @ 0800A8DC
	cmp r1, r0                          @ 0800A8DE
	beq L_0800A8E6                      @ 0800A8E0
	bl Mus_PlaySong                     @ 0800A8E2
L_0800A8E6:
	pop {r3, pc}                        @ 0800A8E6
L_0800A8E8:
	.word mus	@ 0x03003CF8
L_0800A8EC:
	.word snd_rate	@ 0x03003D2A
L_0800A8F0:
	.word FxTab	@ 0x0818CDF8
L_0800A8F4:
	.word mus_chan_0C	@ 0x0203EE30
L_0800A8F8:
	.word mus_chan	@ 0x0203EE24
L_0800A8FC:
	.word RowMaskTab	@ 0x08142518
L_0800A900:
	.word mus_voice	@ 0x0203F040
L_0800A904:
	.word snd_chunk	@ 0x03003D2C
L_0800A908:
	.word snd_mixbuf	@ 0x03004018
L_0800A90C:
	.word mus_chan_1C	@ 0x0203EE40

	.section .wf1_sound, "ax"
	.p2align 2
	.thumb

@ --------------------------------------------------------------------------------------------
@ Apply a voice's dirty flags (call before mixing):
@   bit4: volA/volB = bus*vol*(64-pan)>>10 and bus*vol*(64+pan)>>10, and pick the mix routine:
@         both 0 -> Mix_Null, one side 0 -> Mix_Side, equal -> Mix_Centre, else Mix_Stereo;
@   bit3: copy data/loop start/loop end/rate/loop type from the sample header;
@   bit2: position 0, direction forward;
@   bit1: |step| = ((pitch * rate >> 14) * snd.pitchK + 0x7FF) >> 12  (=pitch*rate/mixrate in 18.14).
	.thumb_func
	.global Voice_Update
Voice_Update:
	push {r4, r5, r6}                   @ 0800A9F4
	ldrb r1, [r0, #0xc]                 @ 0800A9F6
	lsls r2, r1, #0x1f                  @ 0800A9F8
	bpl L_0800AAB6                      @ 0800A9FA
	lsls r2, r1, #0x1b                  @ 0800A9FC
	movs r4, #1                         @ 0800A9FE
	movs r5, #0                         @ 0800AA00
	cmp r2, #0                          @ 0800AA02
	bge L_0800AA5E                      @ 0800AA04
	movs r2, #0x30                      @ 0800AA06
	ldrb r2, [r2, r0]                   @ 0800AA08
	ldrb r3, [r0, #0x10]                @ 0800AA0A
	muls r2, r3, r2                     @ 0800AA0C
	movs r3, #0x11                      @ 0800AA0E
	ldrsb r6, [r0, r3]                  @ 0800AA10
	movs r3, #0x40                      @ 0800AA12
	subs r3, r3, r6                     @ 0800AA14
	adds r6, #0x40                      @ 0800AA16
	muls r3, r2, r3                     @ 0800AA18
	asrs r3, r3, #0xa                   @ 0800AA1A
	muls r6, r2, r6                     @ 0800AA1C
	asrs r2, r6, #0xa                   @ 0800AA1E
	lsls r3, r3, #0x18                  @ 0800AA20
	lsrs r3, r3, #0x18                  @ 0800AA22
	lsls r2, r2, #0x18                  @ 0800AA24
	lsrs r2, r2, #0x18                  @ 0800AA26
	adds r6, r3, #0                     @ 0800AA28
	strb r3, [r0, #0xe]                 @ 0800AA2A
	strb r2, [r0, #0xf]                 @ 0800AA2C
	orrs r6, r2                         @ 0800AA2E
	bne L_0800AA38                      @ 0800AA30
	ldr r2, L_0800AE14                  @ 0800AA32 =0x08008CC1
	str r2, [r0, #0x14]                 @ 0800AA34
	b L_0800AA5E                        @ 0800AA36
L_0800AA38:
	ldr r6, L_0800AE18                  @ 0800AA38 =0x03003D44
	cmp r3, #0                          @ 0800AA3A
	bne L_0800AA46                      @ 0800AA3C
	strb r2, [r0, #0xe]                 @ 0800AA3E
	strb r4, [r0, #0xf]                 @ 0800AA40
	str r6, [r0, #0x14]                 @ 0800AA42
	b L_0800AA5E                        @ 0800AA44
L_0800AA46:
	cmp r2, #0                          @ 0800AA46
	bne L_0800AA4E                      @ 0800AA48
	str r6, [r0, #0x14]                 @ 0800AA4A
	b L_0800AA5E                        @ 0800AA4C
L_0800AA4E:
	cmp r3, r2                          @ 0800AA4E
	bne L_0800AA5A                      @ 0800AA50
	ldr r2, L_0800AE18                  @ 0800AA52 =0x03003D44
	adds r2, #0xa8                      @ 0800AA54
	str r2, [r0, #0x14]                 @ 0800AA56
	b L_0800AA5E                        @ 0800AA58
L_0800AA5A:
	ldr r2, L_0800AE1C                  @ 0800AA5A =0x03003EC0
	str r2, [r0, #0x14]                 @ 0800AA5C
L_0800AA5E:
	lsls r2, r1, #0x1c                  @ 0800AA5E
	bpl L_0800AA7C                      @ 0800AA60
	ldr r2, [r0, #0x24]                 @ 0800AA62
	ldr r3, [r2]                        @ 0800AA64
	str r3, [r0, #8]                    @ 0800AA66
	ldrh r3, [r2, #6]                   @ 0800AA68
	lsls r3, r3, #0xe                   @ 0800AA6A
	str r3, [r0, #0x1c]                 @ 0800AA6C
	ldrh r3, [r2, #8]                   @ 0800AA6E
	lsls r3, r3, #0xe                   @ 0800AA70
	str r3, [r0, #0x20]                 @ 0800AA72
	ldrh r3, [r2, #0xa]                 @ 0800AA74
	strh r3, [r0, #0x12]                @ 0800AA76
	ldrb r2, [r2, #4]                   @ 0800AA78
	strb r2, [r0, #0xd]                 @ 0800AA7A
L_0800AA7C:
	lsls r2, r1, #0x1d                  @ 0800AA7C
	bpl L_0800AA8A                      @ 0800AA7E
	str r5, [r0]                        @ 0800AA80
	ldrb r2, [r0, #0xd]                 @ 0800AA82
	movs r3, #4                         @ 0800AA84
	bics r2, r3                         @ 0800AA86
	strb r2, [r0, #0xd]                 @ 0800AA88
L_0800AA8A:
	lsls r1, r1, #0x1e                  @ 0800AA8A
	bpl L_0800AAB4                      @ 0800AA8C
	ldrh r2, [r0, #0x12]                @ 0800AA8E
	ldr r1, [r0, #0x2c]                 @ 0800AA90
	muls r1, r2, r1                     @ 0800AA92
	ldr r2, L_0800AE18                  @ 0800AA94 =0x03003D44
	lsrs r1, r1, #0xe                   @ 0800AA96
	subs r2, #0x1c                      @ 0800AA98
	ldr r2, [r2, #0x10]                 @ 0800AA9A
	muls r1, r2, r1                     @ 0800AA9C
	ldr r2, L_0800AE20                  @ 0800AA9E =0x000007FF
	adds r1, r1, r2                     @ 0800AAA0
	lsrs r1, r1, #0xc                   @ 0800AAA2
	str r1, [r0, #0x18]                 @ 0800AAA4
	ldrb r2, [r0, #0xd]                 @ 0800AAA6
	lsls r2, r2, #0x1d                  @ 0800AAA8
	bpl L_0800AAB2                      @ 0800AAAA
	rsbs r1, r1, #0                     @ 0800AAAC
	str r1, [r0, #4]                    @ 0800AAAE
	b L_0800AAB4                        @ 0800AAB0
L_0800AAB2:
	str r1, [r0, #4]                    @ 0800AAB2
L_0800AAB4:
	strb r4, [r0, #0xc]                 @ 0800AAB4
L_0800AAB6:
	pop {r4, r5, r6}                    @ 0800AAB6
	bx lr                               @ 0800AAB8

@ --------------------------------------------------------------------------------------------
@ void Voice_Mix(Voice *v, s32 *buf, int n): mix n samples, handling one-shot end (voice
@ stops and clears its channel's note flag), forward loops and ping-pong loops. Segment lengths up to
@ a loop point are found with SWI 6 (Div).
@ BUG: the bounce off a ping-pong loop's *start* (0800AB04-0800AB12) computes 2*start - pos - k*step
@ instead of 2*start - pos + k*step, so the voice resumes well before the loop start (fixed in v2).
	.thumb_func
	.global Voice_Mix
Voice_Mix:
	push {r3, r4, r5, r6, r7, lr}       @ 0800AABA
	adds r4, r0, #0                     @ 0800AABC
	ldrb r0, [r0, #0xc]                 @ 0800AABE
	adds r6, r1, #0                     @ 0800AAC0
	adds r5, r2, #0                     @ 0800AAC2
	lsls r0, r0, #0x1f                  @ 0800AAC4
	bpl L_0800AAF4                      @ 0800AAC6
	ldrb r0, [r4, #0xd]                 @ 0800AAC8
	lsls r1, r0, #0x1f                  @ 0800AACA
	bpl L_0800AB96                      @ 0800AACC
	lsls r0, r0, #0x1e                  @ 0800AACE
	bpl L_0800AB98                      @ 0800AAD0
L_0800AAD2:
	ldmia r4!, {r0, r1}                 @ 0800AAD2
	subs r4, #8                         @ 0800AAD4
	muls r1, r5, r1                     @ 0800AAD6
	adds r7, r0, r1                     @ 0800AAD8
	ldrb r1, [r4, #0xd]                 @ 0800AADA
	lsls r1, r1, #0x1d                  @ 0800AADC
	bpl L_0800AB38                      @ 0800AADE
	ldr r1, [r4, #0x1c]                 @ 0800AAE0
	cmp r1, r7                          @ 0800AAE2
	bgt L_0800AAF6                      @ 0800AAE4
	adds r2, r5, #0                     @ 0800AAE6
	adds r1, r6, #0                     @ 0800AAE8
	adds r0, r4, #0                     @ 0800AAEA
	ldr r3, [r4, #0x14]                 @ 0800AAEC
	bl __call_via_r3                    @ 0800AAEE
	str r7, [r4]                        @ 0800AAF2
L_0800AAF4:
	pop {r3, r4, r5, r6, r7, pc}        @ 0800AAF4
L_0800AAF6:
	ldr r2, [r4, #0x18]                 @ 0800AAF6
	adds r0, r0, r2                     @ 0800AAF8
	subs r0, #1                         @ 0800AAFA
	subs r0, r0, r1                     @ 0800AAFC
	adds r1, r2, #0                     @ 0800AAFE
	svc #6                              @ 0800AB00
	adds r7, r0, #0                     @ 0800AB02
	ldr r0, [r4, #0x1c]                 @ 0800AB04
	ldr r1, [r4]                        @ 0800AB06
	lsls r0, r0, #1                     @ 0800AB08
	subs r1, r0, r1                     @ 0800AB0A
	ldr r0, [r4, #0x18]                 @ 0800AB0C
	adds r2, r7, #0                     @ 0800AB0E
	muls r0, r7, r0                     @ 0800AB10
	subs r0, r1, r0                     @ 0800AB12
	str r0, [sp]                        @ 0800AB14
	adds r1, r6, #0                     @ 0800AB16
	adds r0, r4, #0                     @ 0800AB18
	ldr r3, [r4, #0x14]                 @ 0800AB1A
	bl __call_via_r3                    @ 0800AB1C
	lsls r0, r7, #3                     @ 0800AB20
	adds r6, r0, r6                     @ 0800AB22
	ldr r0, [sp]                        @ 0800AB24
	subs r5, r5, r7                     @ 0800AB26
	str r0, [r4]                        @ 0800AB28
	ldrb r0, [r4, #0xd]                 @ 0800AB2A
	movs r1, #4                         @ 0800AB2C
	bics r0, r1                         @ 0800AB2E
	strb r0, [r4, #0xd]                 @ 0800AB30
	ldr r0, [r4, #0x18]                 @ 0800AB32
	str r0, [r4, #4]                    @ 0800AB34
	b L_0800AB90                        @ 0800AB36
L_0800AB38:
	ldr r1, [r4, #0x20]                 @ 0800AB38
	cmp r1, r7                          @ 0800AB3A
	ble L_0800AB4E                      @ 0800AB3C
	adds r2, r5, #0                     @ 0800AB3E
	adds r1, r6, #0                     @ 0800AB40
	adds r0, r4, #0                     @ 0800AB42
	ldr r3, [r4, #0x14]                 @ 0800AB44
	bl __call_via_r3                    @ 0800AB46
	str r7, [r4]                        @ 0800AB4A
L_0800AB4C:
	b L_0800AAF4                        @ 0800AB4C
L_0800AB4E:
	adds r2, r1, #0                     @ 0800AB4E
	ldr r1, [r4, #0x18]                 @ 0800AB50
	adds r2, r2, r1                     @ 0800AB52
	subs r2, #1                         @ 0800AB54
	subs r0, r2, r0                     @ 0800AB56
	svc #6                              @ 0800AB58
	adds r7, r0, #0                     @ 0800AB5A
	ldr r0, [r4, #0x20]                 @ 0800AB5C
	ldr r1, [r4]                        @ 0800AB5E
	lsls r0, r0, #1                     @ 0800AB60
	subs r1, r0, r1                     @ 0800AB62
	ldr r0, [r4, #0x18]                 @ 0800AB64
	adds r2, r7, #0                     @ 0800AB66
	muls r0, r7, r0                     @ 0800AB68
	subs r0, r1, r0                     @ 0800AB6A
	str r0, [sp]                        @ 0800AB6C
	adds r1, r6, #0                     @ 0800AB6E
	adds r0, r4, #0                     @ 0800AB70
	ldr r3, [r4, #0x14]                 @ 0800AB72
	bl __call_via_r3                    @ 0800AB74
	lsls r0, r7, #3                     @ 0800AB78
	adds r6, r0, r6                     @ 0800AB7A
	ldr r0, [sp]                        @ 0800AB7C
	movs r1, #4                         @ 0800AB7E
	str r0, [r4]                        @ 0800AB80
	ldrb r0, [r4, #0xd]                 @ 0800AB82
	subs r5, r5, r7                     @ 0800AB84
	orrs r0, r1                         @ 0800AB86
	strb r0, [r4, #0xd]                 @ 0800AB88
	ldr r0, [r4, #0x18]                 @ 0800AB8A
	rsbs r0, r0, #0                     @ 0800AB8C
	str r0, [r4, #4]                    @ 0800AB8E
L_0800AB90:
	cmp r5, #0                          @ 0800AB90
	bgt L_0800AAD2                      @ 0800AB92
	b L_0800AAF4                        @ 0800AB94
L_0800AB96:
	b L_0800ABF0                        @ 0800AB96
L_0800AB98:
	ldr r0, [r4, #4]                    @ 0800AB98
	ldr r2, [r4]                        @ 0800AB9A
	muls r0, r5, r0                     @ 0800AB9C
	adds r7, r2, r0                     @ 0800AB9E
	ldr r0, [r4, #0x20]                 @ 0800ABA0
	cmp r0, r7                          @ 0800ABA2
	ble L_0800ABB6                      @ 0800ABA4
	adds r2, r5, #0                     @ 0800ABA6
	adds r1, r6, #0                     @ 0800ABA8
	adds r0, r4, #0                     @ 0800ABAA
	ldr r3, [r4, #0x14]                 @ 0800ABAC
	bl __call_via_r3                    @ 0800ABAE
	str r7, [r4]                        @ 0800ABB2
	b L_0800AAF4                        @ 0800ABB4
L_0800ABB6:
	ldr r1, [r4, #0x18]                 @ 0800ABB6
	adds r0, r0, r1                     @ 0800ABB8
	subs r0, #1                         @ 0800ABBA
	subs r0, r0, r2                     @ 0800ABBC
	svc #6                              @ 0800ABBE
	adds r7, r0, #0                     @ 0800ABC0
	ldr r0, [r4, #0x18]                 @ 0800ABC2
	ldr r1, [r4]                        @ 0800ABC4
	muls r0, r7, r0                     @ 0800ABC6
	adds r0, r1, r0                     @ 0800ABC8
	ldr r1, [r4, #0x20]                 @ 0800ABCA
	ldr r2, [r4, #0x1c]                 @ 0800ABCC
	subs r1, r1, r2                     @ 0800ABCE
	subs r0, r0, r1                     @ 0800ABD0
	str r0, [sp]                        @ 0800ABD2
	adds r1, r6, #0                     @ 0800ABD4
	adds r2, r7, #0                     @ 0800ABD6
	adds r0, r4, #0                     @ 0800ABD8
	ldr r3, [r4, #0x14]                 @ 0800ABDA
	bl __call_via_r3                    @ 0800ABDC
	lsls r0, r7, #3                     @ 0800ABE0
	adds r6, r0, r6                     @ 0800ABE2
	ldr r0, [sp]                        @ 0800ABE4
	subs r5, r5, r7                     @ 0800ABE6
	cmp r5, #0                          @ 0800ABE8
	str r0, [r4]                        @ 0800ABEA
	bgt L_0800AB98                      @ 0800ABEC
	b L_0800AAF4                        @ 0800ABEE
L_0800ABF0:
	ldr r0, [r4, #4]                    @ 0800ABF0
	ldr r2, [r4]                        @ 0800ABF2
	muls r0, r5, r0                     @ 0800ABF4
	adds r7, r2, r0                     @ 0800ABF6
	ldr r0, [r4, #0x20]                 @ 0800ABF8
	cmp r0, r7                          @ 0800ABFA
	ble L_0800AC0E                      @ 0800ABFC
	adds r2, r5, #0                     @ 0800ABFE
	adds r1, r6, #0                     @ 0800AC00
	adds r0, r4, #0                     @ 0800AC02
	ldr r3, [r4, #0x14]                 @ 0800AC04
	bl __call_via_r3                    @ 0800AC06
	str r7, [r4]                        @ 0800AC0A
	b L_0800AAF4                        @ 0800AC0C
L_0800AC0E:
	ldr r1, [r4, #0x18]                 @ 0800AC0E
	adds r0, r0, r1                     @ 0800AC10
	subs r0, #1                         @ 0800AC12
	subs r0, r0, r2                     @ 0800AC14
	svc #6                              @ 0800AC16
	adds r2, r0, #0                     @ 0800AC18
	adds r1, r6, #0                     @ 0800AC1A
	adds r0, r4, #0                     @ 0800AC1C
	ldr r3, [r4, #0x14]                 @ 0800AC1E
	bl __call_via_r3                    @ 0800AC20
	movs r0, #0                         @ 0800AC24
	strb r0, [r4, #0xc]                 @ 0800AC26
	ldr r0, [r4, #0x28]                 @ 0800AC28
	cmp r0, #0                          @ 0800AC2A
	beq L_0800AB4C                      @ 0800AC2C
	ldrb r1, [r0, #0xa]                 @ 0800AC2E
	movs r2, #4                         @ 0800AC30
	bics r1, r2                         @ 0800AC32
	strb r1, [r0, #0xa]                 @ 0800AC34
	b L_0800AAF4                        @ 0800AC36

@ --------------------------------------------------------------------------------------------
@ void Voice_Start(Voice *v, const SampleHdr *h, int vol, int pan): pitch = native, flags = 0x1F.
	.thumb_func
	.global Voice_Start
Voice_Start:
	push {r4}                           @ 0800AC38
	movs r4, #1                         @ 0800AC3A
	lsls r4, r4, #0xe                   @ 0800AC3C
	str r1, [r0, #0x24]                 @ 0800AC3E
	str r4, [r0, #0x2c]                 @ 0800AC40
	strb r2, [r0, #0x10]                @ 0800AC42
	strb r3, [r0, #0x11]                @ 0800AC44
	movs r1, #0x1f                      @ 0800AC46
	strb r1, [r0, #0xc]                 @ 0800AC48
	pop {r4}                            @ 0800AC4A
	bx lr                               @ 0800AC4C

@ --------------------------------------------------------------------------------------------
@ void Snd_SetSfxVolume(int v): bus volume of the 16 sfx voices (0..8 sensible).
	.thumb_func
	.global Snd_SetSfxVolume
Snd_SetSfxVolume:
	lsls r2, r0, #0x18                  @ 0800AC4E
	lsrs r2, r2, #0x18                  @ 0800AC50
	push {r4, r5}                       @ 0800AC52
	ldr r0, L_0800AE18                  @ 0800AC54 =0x03003D44
	ldr r4, L_0800AE24                  @ 0800AC56 =0x0203F400
	subs r0, #0x1c                      @ 0800AC58
	strb r2, [r0, #1]                   @ 0800AC5A
	movs r0, #0                         @ 0800AC5C
	movs r3, #0x10                      @ 0800AC5E
L_0800AC60:
	lsls r1, r0, #6                     @ 0800AC60
	adds r1, r1, r4                     @ 0800AC62
	movs r5, #0x30                      @ 0800AC64
	strb r2, [r5, r1]                   @ 0800AC66
	ldrb r5, [r1, #0xc]                 @ 0800AC68
	adds r0, #1                         @ 0800AC6A
	orrs r5, r3                         @ 0800AC6C
	strb r5, [r1, #0xc]                 @ 0800AC6E
	cmp r0, #0x10                       @ 0800AC70
	blt L_0800AC60                      @ 0800AC72
	pop {r4, r5}                        @ 0800AC74
	bx lr                               @ 0800AC76

@ --------------------------------------------------------------------------------------------
@ void Snd_SetMusicVolume(int v): bus volume of the 15 music voices.
	.thumb_func
	.global Snd_SetMusicVolume
Snd_SetMusicVolume:
	lsls r2, r0, #0x18                  @ 0800AC78
	lsrs r2, r2, #0x18                  @ 0800AC7A
	push {r4, r5}                       @ 0800AC7C
	ldr r0, L_0800AE18                  @ 0800AC7E =0x03003D44
	ldr r4, L_0800AE28                  @ 0800AC80 =0x0203F040
	subs r0, #0x1c                      @ 0800AC82
	strb r2, [r0]                       @ 0800AC84
	movs r0, #0                         @ 0800AC86
	movs r3, #0x10                      @ 0800AC88
L_0800AC8A:
	lsls r1, r0, #6                     @ 0800AC8A
	adds r1, r1, r4                     @ 0800AC8C
	movs r5, #0x30                      @ 0800AC8E
	strb r2, [r5, r1]                   @ 0800AC90
	ldrb r5, [r1, #0xc]                 @ 0800AC92
	adds r0, #1                         @ 0800AC94
	orrs r5, r3                         @ 0800AC96
	strb r5, [r1, #0xc]                 @ 0800AC98
	cmp r0, #0xf                        @ 0800AC9A
	blt L_0800AC8A                      @ 0800AC9C
	pop {r4, r5}                        @ 0800AC9E
	bx lr                               @ 0800ACA0

@ --------------------------------------------------------------------------------------------
@ void Snd_Init(int rate)  -- the game passes 14000.
@ Clears the sound RAM, sets DirectSound A = left / B = right on Timer 0 at full volume, points DMA1
@ at the left ring and DMA2 at the right ring (+512), copies the ARM mixers to IWRAM, installs
@ Snd_Dma2Irq in the IRQ table, enables the DMA2 IRQ and starts Timer 0 at 2^24/rate cycles.
@ Bus volumes: music 4, sfx 8.
	.thumb_func
	.global Snd_Init
Snd_Init:
	push {r3, r4, r5, r6, r7, lr}       @ 0800ACA2
	ldr r4, L_0800AE18                  @ 0800ACA4 =0x03003D44
	movs r3, #0                         @ 0800ACA6
	subs r4, #0x1c                      @ 0800ACA8
	str r3, [r4, #8]                    @ 0800ACAA
	lsls r0, r0, #0x10                  @ 0800ACAC
	lsrs r0, r0, #0x10                  @ 0800ACAE
	str r3, [r4, #0xc]                  @ 0800ACB0
	strh r0, [r4, #2]                   @ 0800ACB2
	str r3, [r4, #0x14]                 @ 0800ACB4
	ldr r1, L_0800AE2C                  @ 0800ACB6 =0x03FFFFFF
	adds r1, r0, r1                     @ 0800ACB8
	bl __rt_udiv                        @ 0800ACBA
	ldr r2, L_0800AE30                  @ 0800ACBE =0x0203EE24
	ldr r5, L_0800AE28                  @ 0800ACC0 =0x0203F040
	movs r1, #0                         @ 0800ACC2
	str r0, [r4, #0x10]                 @ 0800ACC4
L_0800ACC6:
	lsls r3, r1, #3                     @ 0800ACC6
	adds r3, r3, r1                     @ 0800ACC8
	lsls r6, r1, #6                     @ 0800ACCA
	lsls r3, r3, #2                     @ 0800ACCC
	adds r3, r3, r2                     @ 0800ACCE
	adds r6, r6, r5                     @ 0800ACD0
	adds r1, #1                         @ 0800ACD2
	cmp r1, #0xf                        @ 0800ACD4
	str r3, [r6, #0x28]                 @ 0800ACD6
	blt L_0800ACC6                      @ 0800ACD8
	ldr r6, L_0800AE34                  @ 0800ACDA =0x04000080
	movs r1, #0x80                      @ 0800ACDC
	strh r1, [r6, #4]                   @ 0800ACDE
	ldr r1, L_0800AE38                  @ 0800ACE0 =0x00009A0E
	strh r1, [r6, #2]                   @ 0800ACE2
	ldr r1, L_0800AE3C                  @ 0800ACE4 =0x0203F800
	str r1, [r6, #0x3c]                 @ 0800ACE6
	ldr r1, L_0800AE40                  @ 0800ACE8 =0x040000A0
	adds r3, r1, #0                     @ 0800ACEA
	adds r3, #0x20                      @ 0800ACEC
	str r1, [r3]                        @ 0800ACEE
	movs r1, #4                         @ 0800ACF0
	strh r1, [r3, #4]                   @ 0800ACF2
	ldr r7, L_0800AE44                  @ 0800ACF4 =0x0000B660
	strh r7, [r3, #6]                   @ 0800ACF6
	ldr r7, L_0800AE48                  @ 0800ACF8 =0x0203FE00
	str r7, [r3, #8]                    @ 0800ACFA
	ldr r7, L_0800AE4C                  @ 0800ACFC =0x040000A4
	str r7, [r3, #0xc]                  @ 0800ACFE
	strh r1, [r3, #0x10]                @ 0800AD00
	ldr r7, L_0800AE50                  @ 0800AD02 =0x0000F660
	strh r7, [r3, #0x12]                @ 0800AD04
	movs r3, #0                         @ 0800AD06
	strh r3, [r6]                       @ 0800AD08
	ldr r6, L_0800AE54                  @ 0800AD0A =0x080089EC
	ldr r3, L_0800AE58                  @ 0800AD0C =0x040000D4
	str r6, [r3]                        @ 0800AD0E
	ldr r6, L_0800AE18                  @ 0800AD10 =0x03003D44
	str r6, [r3, #4]                    @ 0800AD12
	movs r6, #0x2a                      @ 0800AD14
	strh r6, [r3, #8]                   @ 0800AD16
	movs r6, #0x21                      @ 0800AD18
	lsls r6, r6, #0xa                   @ 0800AD1A
	strh r6, [r3, #0xa]                 @ 0800AD1C
	ldr r6, L_0800AE5C                  @ 0800AD1E =0x08008A94
	str r6, [r3]                        @ 0800AD20
	ldr r6, L_0800AE18                  @ 0800AD22 =0x03003D44
	adds r6, #0xa8                      @ 0800AD24
	str r6, [r3, #4]                    @ 0800AD26
	movs r6, #0x35                      @ 0800AD28
	strh r6, [r3, #8]                   @ 0800AD2A
	movs r6, #0x21                      @ 0800AD2C
	lsls r6, r6, #0xa                   @ 0800AD2E
	strh r6, [r3, #0xa]                 @ 0800AD30
	ldr r6, L_0800AE60                  @ 0800AD32 =0x08008B68
	str r6, [r3]                        @ 0800AD34
	ldr r6, L_0800AE1C                  @ 0800AD36 =0x03003EC0
	str r6, [r3, #4]                    @ 0800AD38
	movs r6, #0x31                      @ 0800AD3A
	strh r6, [r3, #8]                   @ 0800AD3C
	movs r6, #0x21                      @ 0800AD3E
	lsls r6, r6, #0xa                   @ 0800AD40
	strh r6, [r3, #0xa]                 @ 0800AD42
	ldr r6, L_0800AE64                  @ 0800AD44 =0x08008C2C
	str r6, [r3]                        @ 0800AD46
	ldr r6, L_0800AE1C                  @ 0800AD48 =0x03003EC0
	adds r6, #0xc4                      @ 0800AD4A
	str r6, [r3, #4]                    @ 0800AD4C
	movs r6, #0x25                      @ 0800AD4E
	strh r6, [r3, #8]                   @ 0800AD50
	movs r6, #0x21                      @ 0800AD52
	lsls r6, r6, #0xa                   @ 0800AD54
	strh r6, [r3, #0xa]                 @ 0800AD56
	ldr r6, L_0800AE1C                  @ 0800AD58 =0x03003EC0
	ldr r7, L_0800AE68                  @ 0800AD5A =0x03004CB8
	adds r6, #0xc4                      @ 0800AD5C
	str r6, [r4, #0x18]                 @ 0800AD5E
	movs r6, #0                         @ 0800AD60
	str r6, [r7]                        @ 0800AD62
	adds r6, r7, #0                     @ 0800AD64
	str r6, [r3]                        @ 0800AD66
	str r2, [r3, #4]                    @ 0800AD68
	ldr r2, L_0800AE6C                  @ 0800AD6A =0x00000477
	strh r2, [r3, #8]                   @ 0800AD6C
	movs r2, #0x85                      @ 0800AD6E
	lsls r2, r2, #8                     @ 0800AD70
	strh r2, [r3, #0xa]                 @ 0800AD72
	ldr r2, L_0800AE70                  @ 0800AD74 =0x08008CC3
	ldr r3, L_0800AE74                  @ 0800AD76 =0x03003BAF
	ldr r6, L_0800AE78                  @ 0800AD78 =0x04000200
	str r2, [r3]                        @ 0800AD7A
	ldrh r2, [r6]                       @ 0800AD7C
	lsls r3, r1, #8                     @ 0800AD7E
	adds r0, #3                         @ 0800AD80
	orrs r2, r3                         @ 0800AD82
	strh r2, [r6]                       @ 0800AD84
	adds r2, r6, #0                     @ 0800AD86
	rsbs r0, r0, #0                     @ 0800AD88
	lsrs r0, r0, #2                     @ 0800AD8A
	subs r2, #0xff                      @ 0800AD8C
	subs r2, #1                         @ 0800AD8E
	strh r0, [r2]                       @ 0800AD90
	movs r0, #0x80                      @ 0800AD92
	strh r0, [r2, #2]                   @ 0800AD94
	movs r0, #0                         @ 0800AD96
	movs r6, #0x10                      @ 0800AD98
	strb r1, [r4]                       @ 0800AD9A
L_0800AD9C:
	lsls r2, r0, #6                     @ 0800AD9C
	adds r2, r2, r5                     @ 0800AD9E
	movs r3, #0x30                      @ 0800ADA0
	strb r1, [r3, r2]                   @ 0800ADA2
	ldrb r3, [r2, #0xc]                 @ 0800ADA4
	adds r0, #1                         @ 0800ADA6
	orrs r3, r6                         @ 0800ADA8
	strb r3, [r2, #0xc]                 @ 0800ADAA
	cmp r0, #0xf                        @ 0800ADAC
	blt L_0800AD9C                      @ 0800ADAE
	movs r1, #8                         @ 0800ADB0
	ldr r2, L_0800AE24                  @ 0800ADB2 =0x0203F400
	strb r1, [r4, #1]                   @ 0800ADB4
	movs r0, #0                         @ 0800ADB6
L_0800ADB8:
	lsls r3, r0, #6                     @ 0800ADB8
	adds r3, r3, r2                     @ 0800ADBA
	movs r4, #0x30                      @ 0800ADBC
	strb r1, [r4, r3]                   @ 0800ADBE
	ldrb r4, [r3, #0xc]                 @ 0800ADC0
	adds r0, #1                         @ 0800ADC2
	orrs r4, r6                         @ 0800ADC4
	strb r4, [r3, #0xc]                 @ 0800ADC6
	cmp r0, #0x10                       @ 0800ADC8
	blt L_0800ADB8                      @ 0800ADCA
	pop {r3, r4, r5, r6, r7, pc}        @ 0800ADCC

@ --------------------------------------------------------------------------------------------
@ void Snd_Pause(void): wait for a DMA2 IRQ, then stop Timer 0.
	.thumb_func
	.global Snd_Pause
Snd_Pause:
	push {r3, lr}                       @ 0800ADCE
	movs r0, #1                         @ 0800ADD0
	lsls r0, r0, #0xa                   @ 0800ADD2
	bl IntrWait                         @ 0800ADD4
	ldr r1, L_0800AE7C                  @ 0800ADD8 =0x04000100
	movs r0, #0                         @ 0800ADDA
	strh r0, [r1, #2]                   @ 0800ADDC
	pop {r3, pc}                        @ 0800ADDE

@ --------------------------------------------------------------------------------------------
@ void Snd_Resume(void): restart Timer 0.
	.thumb_func
	.global Snd_Resume
Snd_Resume:
	movs r0, #0x80                      @ 0800ADE0
	ldr r1, L_0800AE7C                  @ 0800ADE2 =0x04000100
	strh r0, [r1, #2]                   @ 0800ADE4
	bx lr                               @ 0800ADE6

@ --------------------------------------------------------------------------------------------
@ void Snd_Shutdown(void): wait for a DMA2 IRQ, stop Timer 0, both DMAs and the sound circuit.
	.thumb_func
	.global Snd_Shutdown
Snd_Shutdown:
	push {r3, lr}                       @ 0800ADE8
	ldr r0, L_0800AE78                  @ 0800ADEA =0x04000200
	ldr r2, L_0800AE78                  @ 0800ADEC =0x04000200
	ldrh r1, [r0]                       @ 0800ADEE
	lsrs r0, r0, #0x10                  @ 0800ADF0
	orrs r1, r0                         @ 0800ADF2
	strh r1, [r2]                       @ 0800ADF4
	bl IntrWait                         @ 0800ADF6
	ldr r1, L_0800AE7C                  @ 0800ADFA =0x04000100
	movs r0, #0                         @ 0800ADFC
	strh r0, [r1, #2]                   @ 0800ADFE
	subs r1, #0x40                      @ 0800AE00
	strh r0, [r1, #6]                   @ 0800AE02
	strh r0, [r1, #0x12]                @ 0800AE04
	ldr r1, L_0800AE34                  @ 0800AE06 =0x04000080
	strh r0, [r1, #4]                   @ 0800AE08
	pop {r3, pc}                        @ 0800AE0A

@ --------------------------------------------------------------------------------------------
@ void Snd_Mix(void) -- refill the output rings. Called from the main loop and, when the rings run
@ low, from Snd_Dma2Irq. If more than 64 samples are free: update the sfx voices, then in chunks of at
@ most 256 samples render music (Mus_Render), mix the sfx voices and convert to the rings with
@ Mix_Output, splitting at the 1024-byte wrap and at the 512-sample phase offset of the right ring.
	.thumb_func
	.global Snd_Mix
Snd_Mix:
	push {r4, r5, r6, r7, lr}           @ 0800AE0C
	sub sp, #0xc                        @ 0800AE0E
	b L_0800AE80                        @ 0800AE10
	movs r0, r0                         @ 0800AE12
L_0800AE14:
	.word Mix_Null	@ 0x08008CC1
L_0800AE18:
	.word iw_Mix_Side	@ 0x03003D44
L_0800AE1C:
	.word iw_Mix_Stereo	@ 0x03003EC0
L_0800AE20:
	.word 0x000007FF
L_0800AE24:
	.word sfx_voice	@ 0x0203F400
L_0800AE28:
	.word mus_voice	@ 0x0203F040
L_0800AE2C:
	.word 0x03FFFFFF
L_0800AE30:
	.word mus_chan	@ 0x0203EE24
L_0800AE34:
	.word REG_SOUNDCNT_L	@ 0x04000080
L_0800AE38:
	.word 0x00009A0E
L_0800AE3C:
	.word ring_L	@ 0x0203F800
L_0800AE40:
	.word REG_FIFO_A	@ 0x040000A0
L_0800AE44:
	.word 0x0000B660
L_0800AE48:
	.word ring_R_512	@ 0x0203FE00
L_0800AE4C:
	.word REG_FIFO_B	@ 0x040000A4
L_0800AE50:
	.word 0x0000F660
L_0800AE54:
	.word Mix_Side	@ 0x080089EC
L_0800AE58:
	.word REG_DMA3SAD	@ 0x040000D4
L_0800AE5C:
	.word Mix_Centre	@ 0x08008A94
L_0800AE60:
	.word Mix_Stereo	@ 0x08008B68
L_0800AE64:
	.word Mix_Output	@ 0x08008C2C
L_0800AE68:
	.word zero_word	@ 0x03004CB8
L_0800AE6C:
	.word 0x00000477
L_0800AE70:
	.word Snd_Dma2Irq	@ 0x08008CC3
L_0800AE74:
	.word IntrTable_DMA2_quirk	@ 0x03003BAF
L_0800AE78:
	.word REG_IE	@ 0x04000200
L_0800AE7C:
	.word REG_TM0CNT_L	@ 0x04000100
L_0800AE80:
	ldr r1, L_0800B098                  @ 0800AE80 =0x03003D28
	movs r0, #1                         @ 0800AE82
	str r0, [r1, #0x14]                 @ 0800AE84
	ldr r0, [r1, #8]                    @ 0800AE86
	ldr r4, [r1, #0xc]                  @ 0800AE88
	subs r1, r0, r4                     @ 0800AE8A
	lsls r5, r1, #0x16                  @ 0800AE8C
	lsrs r5, r5, #0x16                  @ 0800AE8E
	cmp r5, #0x40                       @ 0800AE90
	ble L_0800AF5E                      @ 0800AE92
	ldr r1, L_0800B098                  @ 0800AE94 =0x03003D28
	ldr r7, L_0800B09C                  @ 0800AE96 =0x0203F400
	movs r6, #0                         @ 0800AE98
	str r0, [r1, #0xc]                  @ 0800AE9A
L_0800AE9C:
	ldr r7, L_0800B09C                  @ 0800AE9C =0x0203F400
	lsls r0, r6, #6                     @ 0800AE9E
	adds r0, r0, r7                     @ 0800AEA0
	bl Voice_Update                     @ 0800AEA2
	adds r6, #1                         @ 0800AEA6
	cmp r6, #0x10                       @ 0800AEA8
	blt L_0800AE9C                      @ 0800AEAA
L_0800AEAC:
	lsls r0, r5, #0x10                  @ 0800AEAC
	ldr r1, L_0800B098                  @ 0800AEAE =0x03003D28
	asrs r0, r0, #0x10                  @ 0800AEB0
	strh r0, [r1, #4]                   @ 0800AEB2
	movs r1, #0xff                      @ 0800AEB4
	adds r1, #1                         @ 0800AEB6
	cmp r0, r1                          @ 0800AEB8
	ble L_0800AEC0                      @ 0800AEBA
	ldr r0, L_0800B098                  @ 0800AEBC =0x03003D28
	strh r1, [r0, #4]                   @ 0800AEBE
L_0800AEC0:
	bl Mus_Render                       @ 0800AEC0
	ldr r7, L_0800B0A0                  @ 0800AEC4 =0x03004018
	movs r6, #0                         @ 0800AEC6
L_0800AEC8:
	ldr r1, L_0800B09C                  @ 0800AEC8 =0x0203F400
	lsls r0, r6, #6                     @ 0800AECA
	adds r0, r0, r1                     @ 0800AECC
	ldr r1, L_0800B098                  @ 0800AECE =0x03003D28
	movs r3, #4                         @ 0800AED0
	ldrsh r2, [r1, r3]                  @ 0800AED2
	adds r1, r7, #0                     @ 0800AED4
	bl Voice_Mix                        @ 0800AED6
	adds r6, #1                         @ 0800AEDA
	cmp r6, #0x10                       @ 0800AEDC
	blt L_0800AEC8                      @ 0800AEDE
	ldr r6, L_0800B098                  @ 0800AEE0 =0x03003D28
	movs r3, #4                         @ 0800AEE2
	ldrsh r0, [r6, r3]                  @ 0800AEE4
	movs r1, #1                         @ 0800AEE6
	lsls r1, r1, #0xa                   @ 0800AEE8
	adds r3, r0, #0                     @ 0800AEEA
	adds r0, r4, r0                     @ 0800AEEC
	cmp r0, r1                          @ 0800AEEE
	ble L_0800AF22                      @ 0800AEF0
	subs r0, r0, r1                     @ 0800AEF2
	str r0, [sp, #4]                    @ 0800AEF4
	subs r3, r1, r4                     @ 0800AEF6
	ldr r0, L_0800B0A4                  @ 0800AEF8 =0x0203FA00
	str r3, [sp, #8]                    @ 0800AEFA
	adds r1, r4, r0                     @ 0800AEFC
	ldr r0, L_0800B0A8                  @ 0800AEFE =0x0203F800
	ldr r3, [sp, #8]                    @ 0800AF00
	ldr r7, [r6, #0x18]                 @ 0800AF02
	ldr r2, L_0800B0A0                  @ 0800AF04 =0x03004018
	adds r0, r4, r0                     @ 0800AF06
	bl __call_via_r7                    @ 0800AF08
	ldr r3, [sp, #8]                    @ 0800AF0C
	ldr r2, L_0800B0A0                  @ 0800AF0E =0x03004018
	lsls r0, r3, #3                     @ 0800AF10
	adds r2, r0, r2                     @ 0800AF12
	ldr r3, [sp, #4]                    @ 0800AF14
	ldr r7, [r6, #0x18]                 @ 0800AF16
	ldr r0, L_0800B0A8                  @ 0800AF18 =0x0203F800
	ldr r1, L_0800B0AC                  @ 0800AF1A =0x0203FE00
	bl __call_via_r7                    @ 0800AF1C
	b L_0800AF82                        @ 0800AF20
L_0800AF22:
	movs r1, #1                         @ 0800AF22
	lsls r1, r1, #9                     @ 0800AF24
	cmp r4, r1                          @ 0800AF26
	bge L_0800AF72                      @ 0800AF28
	cmp r0, r1                          @ 0800AF2A
	ble L_0800AF60                      @ 0800AF2C
	subs r0, r0, r1                     @ 0800AF2E
	str r0, [sp, #4]                    @ 0800AF30
	subs r3, r1, r4                     @ 0800AF32
	ldr r0, L_0800B0AC                  @ 0800AF34 =0x0203FE00
	str r3, [sp, #8]                    @ 0800AF36
	adds r1, r4, r0                     @ 0800AF38
	ldr r0, L_0800B0A8                  @ 0800AF3A =0x0203F800
	ldr r3, [sp, #8]                    @ 0800AF3C
	ldr r7, [r6, #0x18]                 @ 0800AF3E
	ldr r2, L_0800B0A0                  @ 0800AF40 =0x03004018
	adds r0, r4, r0                     @ 0800AF42
	bl __call_via_r7                    @ 0800AF44
	ldr r3, [sp, #8]                    @ 0800AF48
	ldr r2, L_0800B0A0                  @ 0800AF4A =0x03004018
	lsls r0, r3, #3                     @ 0800AF4C
	adds r2, r0, r2                     @ 0800AF4E
	ldr r3, [sp, #4]                    @ 0800AF50
	ldr r7, [r6, #0x18]                 @ 0800AF52
	ldr r0, L_0800B0A4                  @ 0800AF54 =0x0203FA00
	ldr r1, L_0800B0B0                  @ 0800AF56 =0x0203FC00
	bl __call_via_r7                    @ 0800AF58
	b L_0800AF82                        @ 0800AF5C
L_0800AF5E:
	b L_0800AF90                        @ 0800AF5E
L_0800AF60:
	ldr r0, L_0800B0AC                  @ 0800AF60 =0x0203FE00
	adds r2, r7, #0                     @ 0800AF62
	adds r1, r4, r0                     @ 0800AF64
	ldr r0, L_0800B0A8                  @ 0800AF66 =0x0203F800
	ldr r7, [r6, #0x18]                 @ 0800AF68
	adds r0, r4, r0                     @ 0800AF6A
	bl __call_via_r7                    @ 0800AF6C
	b L_0800AF82                        @ 0800AF70
L_0800AF72:
	ldr r0, L_0800B0A4                  @ 0800AF72 =0x0203FA00
	adds r2, r7, #0                     @ 0800AF74
	adds r1, r4, r0                     @ 0800AF76
	ldr r0, L_0800B0A8                  @ 0800AF78 =0x0203F800
	ldr r7, [r6, #0x18]                 @ 0800AF7A
	adds r0, r4, r0                     @ 0800AF7C
	bl __call_via_r7                    @ 0800AF7E
L_0800AF82:
	movs r3, #4                         @ 0800AF82
	ldrsh r0, [r6, r3]                  @ 0800AF84
	adds r1, r4, r0                     @ 0800AF86
	lsls r4, r1, #0x16                  @ 0800AF88
	lsrs r4, r4, #0x16                  @ 0800AF8A
	subs r5, r5, r0                     @ 0800AF8C
	bne L_0800AEAC                      @ 0800AF8E
L_0800AF90:
	ldr r1, L_0800B098                  @ 0800AF90 =0x03003D28
	movs r0, #0                         @ 0800AF92
	str r0, [r1, #0x14]                 @ 0800AF94
	add sp, #0xc                        @ 0800AF96
	pop {r4, r5, r6, r7, pc}            @ 0800AF98

@ --------------------------------------------------------------------------------------------
@ void Sfx_StopAll(void)
	.thumb_func
	.global Sfx_StopAll
Sfx_StopAll:
	movs r0, #0                         @ 0800AF9A
	ldr r3, L_0800B09C                  @ 0800AF9C =0x0203F400
L_0800AF9E:
	lsls r1, r0, #6                     @ 0800AF9E
	adds r1, r1, r3                     @ 0800AFA0
	ldrb r2, [r1, #0xc]                 @ 0800AFA2
	adds r0, #1                         @ 0800AFA4
	lsrs r2, r2, #1                     @ 0800AFA6
	lsls r2, r2, #1                     @ 0800AFA8
	strb r2, [r1, #0xc]                 @ 0800AFAA
	cmp r0, #0x10                       @ 0800AFAC
	blt L_0800AF9E                      @ 0800AFAE
	bx lr                               @ 0800AFB0

@ --------------------------------------------------------------------------------------------
@ Voice *Sfx_PlaySample(const SampleHdr *h, int vol, int pan): first free sfx voice, or 0.
	.thumb_func
	.global Sfx_PlaySample
Sfx_PlaySample:
	push {r4, r5}                       @ 0800AFB2
	adds r3, r0, #0                     @ 0800AFB4
	ldr r4, L_0800B09C                  @ 0800AFB6 =0x0203F400
	movs r0, #0                         @ 0800AFB8
L_0800AFBA:
	lsls r5, r0, #6                     @ 0800AFBA
	adds r5, r5, r4                     @ 0800AFBC
	ldrb r5, [r5, #0xc]                 @ 0800AFBE
	lsls r5, r5, #0x1f                  @ 0800AFC0
	bne L_0800AFDC                      @ 0800AFC2
	lsls r0, r0, #6                     @ 0800AFC4
	adds r0, r0, r4                     @ 0800AFC6
	movs r4, #1                         @ 0800AFC8
	lsls r4, r4, #0xe                   @ 0800AFCA
	str r3, [r0, #0x24]                 @ 0800AFCC
	str r4, [r0, #0x2c]                 @ 0800AFCE
	strb r1, [r0, #0x10]                @ 0800AFD0
	strb r2, [r0, #0x11]                @ 0800AFD2
	movs r1, #0x1f                      @ 0800AFD4
	strb r1, [r0, #0xc]                 @ 0800AFD6
L_0800AFD8:
	pop {r4, r5}                        @ 0800AFD8
	bx lr                               @ 0800AFDA
L_0800AFDC:
	adds r0, #1                         @ 0800AFDC
	cmp r0, #0x10                       @ 0800AFDE
	blt L_0800AFBA                      @ 0800AFE0
	movs r0, #0                         @ 0800AFE2
	b L_0800AFD8                        @ 0800AFE4

@ --------------------------------------------------------------------------------------------
@ Voice *Sfx_Play(int n): Sfx_PlaySample(&SfxTab[n], 64, 0).
	.thumb_func
	.global Sfx_Play
Sfx_Play:
	lsls r3, r0, #1                     @ 0800AFE6
	adds r0, r3, r0                     @ 0800AFE8
	ldr r1, L_0800B0B4                  @ 0800AFEA =0x085E6F18
	lsls r0, r0, #2                     @ 0800AFEC
	adds r2, r0, r1                     @ 0800AFEE
	ldr r1, L_0800B09C                  @ 0800AFF0 =0x0203F400
	movs r0, #0                         @ 0800AFF2
L_0800AFF4:
	lsls r3, r0, #6                     @ 0800AFF4
	adds r3, r3, r1                     @ 0800AFF6
	ldrb r3, [r3, #0xc]                 @ 0800AFF8
	lsls r3, r3, #0x1f                  @ 0800AFFA
	bne L_0800B018                      @ 0800AFFC
	lsls r0, r0, #6                     @ 0800AFFE
	adds r0, r0, r1                     @ 0800B000
	movs r1, #1                         @ 0800B002
	lsls r1, r1, #0xe                   @ 0800B004
	str r1, [r0, #0x2c]                 @ 0800B006
	str r2, [r0, #0x24]                 @ 0800B008
	movs r1, #0x40                      @ 0800B00A
	strb r1, [r0, #0x10]                @ 0800B00C
	movs r1, #0                         @ 0800B00E
	strb r1, [r0, #0x11]                @ 0800B010
	movs r1, #0x1f                      @ 0800B012
	strb r1, [r0, #0xc]                 @ 0800B014
	bx lr                               @ 0800B016
L_0800B018:
	adds r0, #1                         @ 0800B018
	cmp r0, #0x10                       @ 0800B01A
	blt L_0800AFF4                      @ 0800B01C
	movs r0, #0                         @ 0800B01E
	bx lr                               @ 0800B020

@ --------------------------------------------------------------------------------------------
@ int Sfx_CountActive(void)
	.thumb_func
	.global Sfx_CountActive
Sfx_CountActive:
	movs r0, #0                         @ 0800B022
	movs r1, #0                         @ 0800B024
	ldr r2, L_0800B09C                  @ 0800B026 =0x0203F400
L_0800B028:
	lsls r3, r1, #6                     @ 0800B028
	adds r3, r3, r2                     @ 0800B02A
	ldrb r3, [r3, #0xc]                 @ 0800B02C
	lsls r3, r3, #0x1f                  @ 0800B02E
	beq L_0800B034                      @ 0800B030
	adds r0, #1                         @ 0800B032
L_0800B034:
	adds r1, #1                         @ 0800B034
	cmp r1, #0x10                       @ 0800B036
	blt L_0800B028                      @ 0800B038
	bx lr                               @ 0800B03A

@ --------------------------------------------------------------------------------------------
@ void Sfx_Suspend(Voice save[16]): copy the sfx voices away (DMA3) and stop them all.
	.thumb_func
	.global Sfx_Suspend
Sfx_Suspend:
	ldr r1, L_0800B0B8                  @ 0800B03C =0x040000D4
	ldr r3, L_0800B09C                  @ 0800B03E =0x0203F400
	str r3, [r1]                        @ 0800B040
	str r0, [r1, #4]                    @ 0800B042
	lsrs r0, r1, #0x12                  @ 0800B044
	strh r0, [r1, #8]                   @ 0800B046
	movs r0, #0x21                      @ 0800B048
	lsls r0, r0, #0xa                   @ 0800B04A
	strh r0, [r1, #0xa]                 @ 0800B04C
	movs r0, #0                         @ 0800B04E
L_0800B050:
	lsls r1, r0, #6                     @ 0800B050
	adds r1, r1, r3                     @ 0800B052
	ldrb r2, [r1, #0xc]                 @ 0800B054
	adds r0, #1                         @ 0800B056
	lsrs r2, r2, #1                     @ 0800B058
	lsls r2, r2, #1                     @ 0800B05A
	strb r2, [r1, #0xc]                 @ 0800B05C
	cmp r0, #0x10                       @ 0800B05E
	blt L_0800B050                      @ 0800B060
	bx lr                               @ 0800B062

@ --------------------------------------------------------------------------------------------
@ void Sfx_Restore(const Voice save[16]): copy them back with the current bus volume.
	.thumb_func
	.global Sfx_Restore
Sfx_Restore:
	push {r4, r5}                       @ 0800B064
	movs r1, #0                         @ 0800B066
	ldr r2, L_0800B098                  @ 0800B068 =0x03003D28
	movs r4, #0x10                      @ 0800B06A
	ldrb r3, [r2, #1]                   @ 0800B06C
L_0800B06E:
	lsls r2, r1, #6                     @ 0800B06E
	adds r2, r2, r0                     @ 0800B070
	movs r5, #0x30                      @ 0800B072
	strb r3, [r5, r2]                   @ 0800B074
	ldrb r5, [r2, #0xc]                 @ 0800B076
	adds r1, #1                         @ 0800B078
	orrs r5, r4                         @ 0800B07A
	strb r5, [r2, #0xc]                 @ 0800B07C
	cmp r1, #0x10                       @ 0800B07E
	blt L_0800B06E                      @ 0800B080
	ldr r1, L_0800B0B8                  @ 0800B082 =0x040000D4
	str r0, [r1]                        @ 0800B084
	ldr r0, L_0800B09C                  @ 0800B086 =0x0203F400
	str r0, [r1, #4]                    @ 0800B088
	lsrs r0, r1, #0x12                  @ 0800B08A
	strh r0, [r1, #8]                   @ 0800B08C
	movs r0, #0x21                      @ 0800B08E
	lsls r0, r0, #0xa                   @ 0800B090
	strh r0, [r1, #0xa]                 @ 0800B092
	pop {r4, r5}                        @ 0800B094
	bx lr                               @ 0800B096
L_0800B098:
	.word snd	@ 0x03003D28
L_0800B09C:
	.word sfx_voice	@ 0x0203F400
L_0800B0A0:
	.word snd_mixbuf	@ 0x03004018
L_0800B0A4:
	.word ring_L_512	@ 0x0203FA00
L_0800B0A8:
	.word ring_L	@ 0x0203F800
L_0800B0AC:
	.word ring_R_512	@ 0x0203FE00
L_0800B0B0:
	.word ring_R	@ 0x0203FC00
L_0800B0B4:
	.word wf1_SfxTab	@ 0x085E6F18
L_0800B0B8:
	.word REG_DMA3SAD	@ 0x040000D4
