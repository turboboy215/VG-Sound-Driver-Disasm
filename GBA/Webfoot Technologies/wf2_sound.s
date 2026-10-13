@ ============================================================================================
@ wf2_sound.s -- Webfoot Technologies GBA sound engine, version 2
@                as shipped in Dragon Ball Z: The Legacy of Goku II (GBA, 2003), ROM ALFP (E) (M5)
@
@ Reconstructed by disassembly. Assembles with   arm-none-eabi-as -mcpu=arm7tdmi
@ and, linked with wf2.ld, rebuilds these ROM ranges byte for byte:
@     .wf2_iwram  ROM 0x087D744C-0x087D7750  ARM mixer + DMA2 IRQ; part of the crt0 RW image,
@                   runs at 0x03000520 in IWRAM
@     .wf2_sound  0x0801FE84-0x080211D4  voices + voice pool, pattern player, sound object (Thumb, compiled C++)
@ The tables are in wf2_rodata.s, the music/SFX data in wf2_data.s. All names are invented.
@
@ Version 2 is the version-1 engine rewritten as objects: one sound object holds the music player
@ (with the 15 channels and their voices embedded) and a 16-voice pool for effects; every function
@ takes the object it works on in r0. Mixing is done into a packed s32 buffer (left in the low half,
@ right in the high half) by a single ARM routine, and the output rate is fixed at 16 kHz.
@
@ ---- RAM -----------------------------------------------------------------------------------
@ snd  0x030026BC  sound object, 0x11C4 bytes
@      +000 u32 busy   +004 u32 play position (IRQ adds 16)   +008 u32 write position
@      +00C Player     +5C4 Voice pool[16]   +9C4 mix buffer, 512 x u32 (L in bits 0-15, R in 16-31)
@ Player (0x5B8 bytes)
@      +00 u8 tick(ticks left in row)  +01 u8 row  +02 u8 rows  +03 u8 speed  +04 u8 tempo  +05 u8 playing
@      +06 u16 samples per tick  +08 u16 samples left before the next tick  +0C song*  +10 s32 order
@      +14 u8* pattern read pointer  +18 Chan[15], 0x60 bytes each
@ Chan = Voice (+00..+3F) followed by the channel fields of version 1 moved up by 0x40:
@      +40 pitch  +44 porta target  +48 volume  +49 pan  +4A flags  +4B slide step  +4C D memory
@      +4D E/F/G memory  +4E Q memory  +4F vib speed  +50 vib depth  +51 vib phase  +52 counter
@      +54 tick handler  +58 mask  +59 last mask  +5A note +5B instr +5C volume +5D effect +5E param
@ Voice (0x40 bytes)
@      +00 u32 position (18.14)  +04 s32 step  +08 s8* data  +0C u16 left volume  +0E u16 right volume
@      +10 u8 flags (bit0 active, 1 step, 2 restart, 3 header, 4 volume)  +11 u8 loop state
@      +12 u8 volume 0..64  +13 s8 pan  +14 u16 rate  +18 mix routine  +1C |step|  +20 loop start
@      +24 loop end  +28 sample header*  +2C owner (the channel itself for music, 0 for sfx)
@      +30 u32 pitch factor  +34 u8 bus volume
@ Output rings: left 0x02000000-0x020003FF (DMA1 -> FIFO A), right 0x02000400-0x020007FF (DMA2 -> FIFO B, starts at +512)
@ ============================================================================================

@ symbols defined in the other source files of this set:
@   NoteFreqTab            0x087D61AC
@   FxTab                  0x087D638C
@   PortaUpTab             0x087D648C
@   PortaDownTab           0x087D670C
@   VibratoSine            0x087D690C
@   TonePortaVolTicks      0x087D694C
@   p_intrmgr              0x087D6964

	.syntax unified
	.equ mem_alloc, 0x0801F53C
	.equ mem_free, 0x0801F5C0
	.equ IntrMgr_Wait, 0x080211F0
	.equ __call_via_r1, 0x080221DA
	.equ __call_via_r3, 0x080221DE
	.equ __rt_udiv, 0x080223E0
	.equ Mix_Output_from_thumb, 0x08023BA0
	.equ DMA_FIFO_RESTART, 0xF6400004
	.equ REG_DMA3SAD, 0x040000D4
	.equ REG_FIFO_A, 0x040000A0
	.equ REG_FIFO_B, 0x040000A4
	.equ REG_IE, 0x04000200
	.equ REG_SOUNDCNT_L, 0x04000080
	.equ REG_TM0CNT_L, 0x04000100
	.equ SND_MIXBUF, 0x000009C4
	.equ SND_POOL, 0x000005C4
	.equ TEMPO_K, 0x00009C40
	.equ intrmgr, 0x03000E3C
	.equ ring_L_512, 0x02000200
	.equ ring_R, 0x02000400
	.equ ring_R_512, 0x02000600
	.equ snd, 0x030026BC
	.equ zero_word, 0x03003914
	.equ ring_L, 0x02000000


	.section .wf2_iwram, "ax"
	.p2align 2
	.arm

@ --------------------------------------------------------------------------------------------
@ void Mix_Voice(Voice *v, u32 *buf, int n)   (ARM, IWRAM)
@ buf[i] += sample * (volL | volR << 16): one multiply-accumulate mixes both channels into the packed
@ buffer. 8x unrolled; when the step is below 1.0 a second loop advances the pointer with conditional
@ pre-indexed loads (ldrsbhs ...!) instead of an add with carry.
	.global Mix_Voice
Mix_Voice:
	push {r4, r5, r6, r7, r8, sb, sl}   @ 03000520
	ldm r0, {r3, r4, r5, r6}            @ 03000524
	lsl r7, r3, #0x12                   @ 03000528
	lsl r8, r4, #0x12                   @ 0300052C
	add r3, r5, r3, asr #14             @ 03000530
	asr r4, r4, #0xe                    @ 03000534
	tst r2, #1                          @ 03000538
	beq L_03000560                      @ 0300053C
	ldrsb r0, [r3]                      @ 03000540
	adds r7, r7, r8                     @ 03000544
	adc r3, r3, r4                      @ 03000548
	ldr r5, [r1]                        @ 0300054C
	mla r5, r6, r0, r5                  @ 03000550
	str r5, [r1], #4                    @ 03000554
	subs r2, r2, #1                     @ 03000558
	beq L_03000640                      @ 0300055C
L_03000560:
	cmp r4, #0                          @ 03000560
	beq L_03000648                      @ 03000564
	tst r2, #2                          @ 03000568
	beq L_030005A0                      @ 0300056C
	ldrsb r0, [r3]                      @ 03000570
	adds r7, r7, r8                     @ 03000574
	adc r3, r3, r4                      @ 03000578
	ldrsb r5, [r3]                      @ 0300057C
	adds r7, r7, r8                     @ 03000580
	adc r3, r3, r4                      @ 03000584
	ldm r1, {sb, ip}                    @ 03000588
	mla sb, r6, r0, sb                  @ 0300058C
	mla ip, r6, r5, ip                  @ 03000590
	stm r1!, {sb, ip}                   @ 03000594
	subs r2, r2, #2                     @ 03000598
	beq L_03000640                      @ 0300059C
L_030005A0:
	tst r2, #4                          @ 030005A0
	bne L_030005F0                      @ 030005A4
L_030005A8:
	ldm r1, {r5, sb, sl, ip}            @ 030005A8
	ldrsb r0, [r3]                      @ 030005AC
	adds r7, r7, r8                     @ 030005B0
	adc r3, r3, r4                      @ 030005B4
	mla r5, r6, r0, r5                  @ 030005B8
	ldrsb r0, [r3]                      @ 030005BC
	adds r7, r7, r8                     @ 030005C0
	adc r3, r3, r4                      @ 030005C4
	mla sb, r6, r0, sb                  @ 030005C8
	ldrsb r0, [r3]                      @ 030005CC
	adds r7, r7, r8                     @ 030005D0
	adc r3, r3, r4                      @ 030005D4
	mla sl, r6, r0, sl                  @ 030005D8
	ldrsb r0, [r3]                      @ 030005DC
	adds r7, r7, r8                     @ 030005E0
	adc r3, r3, r4                      @ 030005E4
	mla ip, r6, r0, ip                  @ 030005E8
	stm r1!, {r5, sb, sl, ip}           @ 030005EC
L_030005F0:
	ldm r1, {r5, sb, sl, ip}            @ 030005F0
	ldrsb r0, [r3]                      @ 030005F4
	adds r7, r7, r8                     @ 030005F8
	adc r3, r3, r4                      @ 030005FC
	mla r5, r6, r0, r5                  @ 03000600
	ldrsb r0, [r3]                      @ 03000604
	adds r7, r7, r8                     @ 03000608
	adc r3, r3, r4                      @ 0300060C
	mla sb, r6, r0, sb                  @ 03000610
	ldrsb r0, [r3]                      @ 03000614
	adds r7, r7, r8                     @ 03000618
	adc r3, r3, r4                      @ 0300061C
	mla sl, r6, r0, sl                  @ 03000620
	ldrsb r0, [r3]                      @ 03000624
	adds r7, r7, r8                     @ 03000628
	adc r3, r3, r4                      @ 0300062C
	mla ip, r6, r0, ip                  @ 03000630
	stm r1!, {r5, sb, sl, ip}           @ 03000634
	subs r2, r2, #8                     @ 03000638
	bhi L_030005A8                      @ 0300063C
L_03000640:
	pop {r4, r5, r6, r7, r8, sb, sl}    @ 03000640
	bx lr                               @ 03000644
L_03000648:
	ldrsb r0, [r3]                      @ 03000648
	tst r2, #2                          @ 0300064C
	beq L_0300067C                      @ 03000650
	ldm r1, {sb, ip}                    @ 03000654
	mla sb, r6, r0, sb                  @ 03000658
	adds r7, r7, r8                     @ 0300065C
	ldrsbhs r0, [r3, #1]!               @ 03000660
	mla ip, r6, r0, ip                  @ 03000664
	adds r7, r7, r8                     @ 03000668
	ldrsbhs r0, [r3, #1]!               @ 0300066C
	stm r1!, {sb, ip}                   @ 03000670
	subs r2, r2, #2                     @ 03000674
	beq L_03000640                      @ 03000678
L_0300067C:
	tst r2, #4                          @ 0300067C
	bne L_030006BC                      @ 03000680
L_03000684:
	ldm r1, {r4, r5, sb, ip}            @ 03000684
	mla r4, r6, r0, r4                  @ 03000688
	adds r7, r7, r8                     @ 0300068C
	ldrsbhs r0, [r3, #1]!               @ 03000690
	mla r5, r6, r0, r5                  @ 03000694
	adds r7, r7, r8                     @ 03000698
	ldrsbhs r0, [r3, #1]!               @ 0300069C
	mla sb, r6, r0, sb                  @ 030006A0
	adds r7, r7, r8                     @ 030006A4
	ldrsbhs r0, [r3, #1]!               @ 030006A8
	mla ip, r6, r0, ip                  @ 030006AC
	adds r7, r7, r8                     @ 030006B0
	ldrsbhs r0, [r3, #1]!               @ 030006B4
	stm r1!, {r4, r5, sb, ip}           @ 030006B8
L_030006BC:
	ldm r1, {r4, r5, sb, ip}            @ 030006BC
	mla r4, r6, r0, r4                  @ 030006C0
	adds r7, r7, r8                     @ 030006C4
	ldrsbhs r0, [r3, #1]!               @ 030006C8
	mla r5, r6, r0, r5                  @ 030006CC
	adds r7, r7, r8                     @ 030006D0
	ldrsbhs r0, [r3, #1]!               @ 030006D4
	mla sb, r6, r0, sb                  @ 030006D8
	adds r7, r7, r8                     @ 030006DC
	ldrsbhs r0, [r3, #1]!               @ 030006E0
	mla ip, r6, r0, ip                  @ 030006E4
	adds r7, r7, r8                     @ 030006E8
	ldrsbhs r0, [r3, #1]!               @ 030006EC
	stm r1!, {r4, r5, sb, ip}           @ 030006F0
	subs r2, r2, #8                     @ 030006F4
	bhi L_03000684                      @ 030006F8
	pop {r4, r5, r6, r7, r8, sb, sl}    @ 030006FC
	bx lr                               @ 03000700

@ --------------------------------------------------------------------------------------------
@ void Mix_Output(s8 *outL, s8 *outR, u32 *buf, int n)   (ARM, IWRAM)
@ Unpacks the halves of each mix word, >> 6, clamps to -128..127, writes both rings and zeroes buf.
	.global Mix_Output
Mix_Output:
	push {r4, r5, r6, r7, r8}           @ 03000704
	mov r8, #0                          @ 03000708
	mov ip, #0                          @ 0300070C
L_03000710:
	ldm r2, {r4, r6}                    @ 03000710
	stm r2!, {r8, ip}                   @ 03000714
	asr r5, r4, #0x16                   @ 03000718
	asr r7, r6, #0x16                   @ 0300071C
	lsl r4, r4, #0x10                   @ 03000720
	lsl r6, r6, #0x10                   @ 03000724
	asr r4, r4, #0x16                   @ 03000728
	asr r6, r6, #0x16                   @ 0300072C
	cmp r4, #0x7f                       @ 03000730
	movgt r4, #0x7f                     @ 03000734
	cmn r4, #0x80                       @ 03000738
	mvnlt r4, #0x7f                     @ 0300073C
	cmp r5, #0x7f                       @ 03000740
	movgt r5, #0x7f                     @ 03000744
	cmn r5, #0x80                       @ 03000748
	mvnlt r5, #0x7f                     @ 0300074C
	cmp r6, #0x7f                       @ 03000750
	movgt r6, #0x7f                     @ 03000754
	cmn r6, #0x80                       @ 03000758
	mvnlt r6, #0x7f                     @ 0300075C
	cmp r7, #0x7f                       @ 03000760
	movgt r7, #0x7f                     @ 03000764
	cmn r7, #0x80                       @ 03000768
	mvnlt r7, #0x7f                     @ 0300076C
	and r4, r4, #0xff                   @ 03000770
	orr r4, r4, r6, lsl #8              @ 03000774
	and r5, r5, #0xff                   @ 03000778
	orr r5, r5, r7, lsl #8              @ 0300077C
	strh r4, [r0], #2                   @ 03000780
	strh r5, [r1], #2                   @ 03000784
	subs r3, r3, #2                     @ 03000788
	bgt L_03000710                      @ 0300078C
	pop {r4, r5, r6, r7, r8}            @ 03000790
	bx lr                               @ 03000794
	.arm

@ --------------------------------------------------------------------------------------------
@ DMA2 interrupt (every 16 samples), ARM. The dispatcher passes r3 = &REG_IE and r4 = return.
@ playpos += 16; every 512 samples re-arm DMA2 (right ring) or DMA1 (left ring, and wrap playpos);
@ if exactly 96 samples are left before the write position and the mixer is idle, re-enable IRQs
@ and tail-jump to Snd_Mix(&snd).
	.global Snd_Dma2Irq
Snd_Dma2Irq:
	ldr r0, L_03000818                  @ 03000798 =0x030026BC
	ldr r1, [r0, #4]                    @ 0300079C
	add r1, r1, #0x10                   @ 030007A0
	str r1, [r0, #4]                    @ 030007A4
	lsls ip, r1, #0x17                  @ 030007A8
	bne L_030007E4                      @ 030007AC
	lsls r2, r1, #0x16                  @ 030007B0
	mov r2, #128, #14                   @ 030007B4
	bpl L_030007CC                      @ 030007B8
	str ip, [r3, #-0x130]!              @ 030007BC
	add r2, r2, #64, #28                @ 030007C0
	sub ip, r3, #0x2c                   @ 030007C4
	b L_030007D8                        @ 030007C8
L_030007CC:
	str ip, [r0, #4]                    @ 030007CC
	str ip, [r3, #-0x13c]!              @ 030007D0
	sub ip, r3, #0x24                   @ 030007D4
L_030007D8:
	stmdb r3, {r2, ip}                  @ 030007D8
	ldr ip, L_0300081C                  @ 030007DC =0xF6400004
	str ip, [r3]                        @ 030007E0
L_030007E4:
	ldr ip, [r0, #8]                    @ 030007E4
	sub ip, ip, r1                      @ 030007E8
	lsl ip, ip, #0x16                   @ 030007EC
	cmp ip, #96, #10                    @ 030007F0
	bxne r4                             @ 030007F4
	ldrb ip, [r0]                       @ 030007F8
	cmp ip, #0                          @ 030007FC
	bxne r4                             @ 03000800
	mrs r2, cpsr                        @ 03000804
	bic r2, r2, #0x80                   @ 03000808
	msr cpsr_c, r2                      @ 0300080C
	ldr r1, L_03000820                  @ 03000810 =0x08021089
	bx r1                               @ 03000814
L_03000818:
	.word snd	@ 0x030026BC
L_0300081C:
	.word DMA_FIFO_RESTART	@ 0xF6400004
L_03000820:
	.word Snd_Mix	@ 0x08021089

	.section .wf2_sound, "ax"
	.p2align 2
	.thumb

@ --------------------------------------------------------------------------------------------
@ void Mix_Null(void) -- mix routine of a voice with both volumes 0.
	.thumb_func
	.global Mix_Null
Mix_Null:
	bx lr                               @ 0801FE84

@ --------------------------------------------------------------------------------------------
@ void Voice_Update(Voice *v): apply the dirty flags.
@   bit4: volL = bus*vol*(64-pan)>>10, volR = bus*vol*(64+pan)>>10; routine = Mix_Null if both are 0,
@         else Mix_Voice;
@   bit3: copy data/loop/rate from the sample header;  bit2: position 0, forward;
@   bit1: |step| = ((pitch * rate >> 14) * 0x1063 + 0x7FF) >> 12   (0x1063 = 2^26/16000).
	.thumb_func
	.global Voice_Update
Voice_Update:
	push {r4}                           @ 0801FE86
	ldrb r1, [r0, #0x10]                @ 0801FE88
	lsls r2, r1, #0x1f                  @ 0801FE8A
	bpl L_0801FF1E                      @ 0801FE8C
	lsls r2, r1, #0x1b                  @ 0801FE8E
	bpl L_0801FEC6                      @ 0801FE90
	movs r2, #0x34                      @ 0801FE92
	ldrb r2, [r2, r0]                   @ 0801FE94
	ldrb r3, [r0, #0x12]                @ 0801FE96
	muls r2, r3, r2                     @ 0801FE98
	movs r3, #0x13                      @ 0801FE9A
	ldrsb r4, [r0, r3]                  @ 0801FE9C
	movs r3, #0x40                      @ 0801FE9E
	subs r3, r3, r4                     @ 0801FEA0
	adds r4, #0x40                      @ 0801FEA2
	muls r3, r2, r3                     @ 0801FEA4
	asrs r3, r3, #0xa                   @ 0801FEA6
	lsls r3, r3, #0x10                  @ 0801FEA8
	muls r4, r2, r4                     @ 0801FEAA
	asrs r2, r4, #0xa                   @ 0801FEAC
	lsrs r3, r3, #0x10                  @ 0801FEAE
	lsls r2, r2, #0x10                  @ 0801FEB0
	lsrs r2, r2, #0x10                  @ 0801FEB2
	strh r3, [r0, #0xc]                 @ 0801FEB4
	strh r2, [r0, #0xe]                 @ 0801FEB6
	orrs r2, r3                         @ 0801FEB8
	bne L_0801FEC2                      @ 0801FEBA
	ldr r2, L_0802013C                  @ 0801FEBC =0x0801FE85
	str r2, [r0, #0x18]                 @ 0801FEBE
	b L_0801FEC6                        @ 0801FEC0
L_0801FEC2:
	ldr r2, L_08020140                  @ 0801FEC2 =0x03000520
	str r2, [r0, #0x18]                 @ 0801FEC4
L_0801FEC6:
	lsls r2, r1, #0x1c                  @ 0801FEC6
	bpl L_0801FEE4                      @ 0801FEC8
	ldr r2, [r0, #0x28]                 @ 0801FECA
	ldr r3, [r2]                        @ 0801FECC
	str r3, [r0, #8]                    @ 0801FECE
	ldrh r3, [r2, #6]                   @ 0801FED0
	lsls r3, r3, #0xe                   @ 0801FED2
	str r3, [r0, #0x20]                 @ 0801FED4
	ldrh r3, [r2, #8]                   @ 0801FED6
	lsls r3, r3, #0xe                   @ 0801FED8
	str r3, [r0, #0x24]                 @ 0801FEDA
	ldrh r3, [r2, #0xa]                 @ 0801FEDC
	strh r3, [r0, #0x14]                @ 0801FEDE
	ldrb r2, [r2, #4]                   @ 0801FEE0
	strb r2, [r0, #0x11]                @ 0801FEE2
L_0801FEE4:
	lsls r2, r1, #0x1d                  @ 0801FEE4
	bpl L_0801FEF4                      @ 0801FEE6
	movs r2, #0                         @ 0801FEE8
	str r2, [r0]                        @ 0801FEEA
	ldrb r2, [r0, #0x11]                @ 0801FEEC
	movs r3, #4                         @ 0801FEEE
	bics r2, r3                         @ 0801FEF0
	strb r2, [r0, #0x11]                @ 0801FEF2
L_0801FEF4:
	lsls r1, r1, #0x1e                  @ 0801FEF4
	bpl L_0801FF1A                      @ 0801FEF6
	ldrh r2, [r0, #0x14]                @ 0801FEF8
	ldr r1, [r0, #0x30]                 @ 0801FEFA
	ldr r3, L_08020144                  @ 0801FEFC =0x00001063
	muls r1, r2, r1                     @ 0801FEFE
	lsrs r1, r1, #0xe                   @ 0801FF00
	ldr r2, L_08020148                  @ 0801FF02 =0x000007FF
	muls r1, r3, r1                     @ 0801FF04
	adds r1, r1, r2                     @ 0801FF06
	lsrs r1, r1, #0xc                   @ 0801FF08
	str r1, [r0, #0x1c]                 @ 0801FF0A
	ldrb r2, [r0, #0x11]                @ 0801FF0C
	lsls r2, r2, #0x1d                  @ 0801FF0E
	bpl L_0801FF18                      @ 0801FF10
	rsbs r1, r1, #0                     @ 0801FF12
	str r1, [r0, #4]                    @ 0801FF14
	b L_0801FF1A                        @ 0801FF16
L_0801FF18:
	str r1, [r0, #4]                    @ 0801FF18
L_0801FF1A:
	movs r1, #1                         @ 0801FF1A
	strb r1, [r0, #0x10]                @ 0801FF1C
L_0801FF1E:
	pop {r4}                            @ 0801FF1E
	bx lr                               @ 0801FF20

@ --------------------------------------------------------------------------------------------
@ void Voice_Mix(Voice *v, u32 *buf, int n): as version 1 with two ping-pong fixes: the bounce
@ off the loop start now mirrors with the right sign (2*start - pos + k*step), and the bounce off the end
@ reflects to 2*end-1-p so the position can no longer land exactly on the end.
	.thumb_func
	.global Voice_Mix
Voice_Mix:
	push {r3, r4, r5, r6, r7, lr}       @ 0801FF22
	adds r4, r0, #0                     @ 0801FF24
	ldrb r0, [r0, #0x10]                @ 0801FF26
	adds r6, r1, #0                     @ 0801FF28
	adds r5, r2, #0                     @ 0801FF2A
	lsls r0, r0, #0x1f                  @ 0801FF2C
	bpl L_0801FF5C                      @ 0801FF2E
	ldrb r0, [r4, #0x11]                @ 0801FF30
	lsls r1, r0, #0x1f                  @ 0801FF32
	bpl L_08020000                      @ 0801FF34
	lsls r0, r0, #0x1e                  @ 0801FF36
	bpl L_08020002                      @ 0801FF38
L_0801FF3A:
	ldmia r4!, {r0, r1}                 @ 0801FF3A
	subs r4, #8                         @ 0801FF3C
	muls r1, r5, r1                     @ 0801FF3E
	adds r7, r0, r1                     @ 0801FF40
	ldrb r1, [r4, #0x11]                @ 0801FF42
	lsls r1, r1, #0x1d                  @ 0801FF44
	bpl L_0801FFA0                      @ 0801FF46
	ldr r1, [r4, #0x20]                 @ 0801FF48
	cmp r1, r7                          @ 0801FF4A
	bgt L_0801FF5E                      @ 0801FF4C
	adds r2, r5, #0                     @ 0801FF4E
	adds r1, r6, #0                     @ 0801FF50
	adds r0, r4, #0                     @ 0801FF52
	ldr r3, [r4, #0x18]                 @ 0801FF54
	bl __call_via_r3                    @ 0801FF56
	str r7, [r4]                        @ 0801FF5A
L_0801FF5C:
	pop {r3, r4, r5, r6, r7, pc}        @ 0801FF5C
L_0801FF5E:
	ldr r2, [r4, #0x1c]                 @ 0801FF5E
	adds r0, r0, r2                     @ 0801FF60
	subs r0, #1                         @ 0801FF62
	subs r0, r0, r1                     @ 0801FF64
	adds r1, r2, #0                     @ 0801FF66
	svc #6                              @ 0801FF68
	adds r7, r0, #0                     @ 0801FF6A
	ldr r0, [r4, #0x20]                 @ 0801FF6C
	ldr r1, [r4]                        @ 0801FF6E
	lsls r0, r0, #1                     @ 0801FF70
	subs r1, r0, r1                     @ 0801FF72
	ldr r0, [r4, #0x1c]                 @ 0801FF74
	adds r2, r7, #0                     @ 0801FF76
	muls r0, r7, r0                     @ 0801FF78
	adds r0, r1, r0                     @ 0801FF7A
	str r0, [sp]                        @ 0801FF7C
	adds r1, r6, #0                     @ 0801FF7E
	adds r0, r4, #0                     @ 0801FF80
	ldr r3, [r4, #0x18]                 @ 0801FF82
	bl __call_via_r3                    @ 0801FF84
	lsls r0, r7, #2                     @ 0801FF88
	adds r6, r0, r6                     @ 0801FF8A
	ldr r0, [sp]                        @ 0801FF8C
	subs r5, r5, r7                     @ 0801FF8E
	str r0, [r4]                        @ 0801FF90
	ldrb r0, [r4, #0x11]                @ 0801FF92
	movs r1, #4                         @ 0801FF94
	bics r0, r1                         @ 0801FF96
	strb r0, [r4, #0x11]                @ 0801FF98
	ldr r0, [r4, #0x1c]                 @ 0801FF9A
	str r0, [r4, #4]                    @ 0801FF9C
	b L_0801FFFA                        @ 0801FF9E
L_0801FFA0:
	ldr r1, [r4, #0x24]                 @ 0801FFA0
	cmp r1, r7                          @ 0801FFA2
	ble L_0801FFB6                      @ 0801FFA4
	adds r2, r5, #0                     @ 0801FFA6
	adds r1, r6, #0                     @ 0801FFA8
	adds r0, r4, #0                     @ 0801FFAA
	ldr r3, [r4, #0x18]                 @ 0801FFAC
	bl __call_via_r3                    @ 0801FFAE
	str r7, [r4]                        @ 0801FFB2
L_0801FFB4:
	b L_0801FF5C                        @ 0801FFB4
L_0801FFB6:
	adds r2, r1, #0                     @ 0801FFB6
	ldr r1, [r4, #0x1c]                 @ 0801FFB8
	adds r2, r2, r1                     @ 0801FFBA
	subs r2, #1                         @ 0801FFBC
	subs r0, r2, r0                     @ 0801FFBE
	svc #6                              @ 0801FFC0
	adds r7, r0, #0                     @ 0801FFC2
	ldr r0, [r4, #0x24]                 @ 0801FFC4
	ldr r1, [r4]                        @ 0801FFC6
	lsls r0, r0, #1                     @ 0801FFC8
	subs r1, r0, r1                     @ 0801FFCA
	ldr r0, [r4, #0x1c]                 @ 0801FFCC
	adds r2, r7, #0                     @ 0801FFCE
	muls r0, r7, r0                     @ 0801FFD0
	subs r0, r1, r0                     @ 0801FFD2
	subs r0, #1                         @ 0801FFD4
	str r0, [sp]                        @ 0801FFD6
	adds r1, r6, #0                     @ 0801FFD8
	adds r0, r4, #0                     @ 0801FFDA
	ldr r3, [r4, #0x18]                 @ 0801FFDC
	bl __call_via_r3                    @ 0801FFDE
	lsls r0, r7, #2                     @ 0801FFE2
	adds r6, r0, r6                     @ 0801FFE4
	ldr r0, [sp]                        @ 0801FFE6
	movs r1, #4                         @ 0801FFE8
	str r0, [r4]                        @ 0801FFEA
	ldrb r0, [r4, #0x11]                @ 0801FFEC
	subs r5, r5, r7                     @ 0801FFEE
	orrs r0, r1                         @ 0801FFF0
	strb r0, [r4, #0x11]                @ 0801FFF2
	ldr r0, [r4, #0x1c]                 @ 0801FFF4
	rsbs r0, r0, #0                     @ 0801FFF6
	str r0, [r4, #4]                    @ 0801FFF8
L_0801FFFA:
	cmp r5, #0                          @ 0801FFFA
	bgt L_0801FF3A                      @ 0801FFFC
	b L_0801FF5C                        @ 0801FFFE
L_08020000:
	b L_0802005C                        @ 08020000
L_08020002:
	b L_08020004                        @ 08020002
L_08020004:
	ldr r0, [r4, #4]                    @ 08020004
	ldr r2, [r4]                        @ 08020006
	muls r0, r5, r0                     @ 08020008
	adds r7, r2, r0                     @ 0802000A
	ldr r0, [r4, #0x24]                 @ 0802000C
	cmp r0, r7                          @ 0802000E
	ble L_08020022                      @ 08020010
	adds r2, r5, #0                     @ 08020012
	adds r1, r6, #0                     @ 08020014
	adds r0, r4, #0                     @ 08020016
	ldr r3, [r4, #0x18]                 @ 08020018
	bl __call_via_r3                    @ 0802001A
	str r7, [r4]                        @ 0802001E
	b L_0801FF5C                        @ 08020020
L_08020022:
	ldr r1, [r4, #0x1c]                 @ 08020022
	adds r0, r0, r1                     @ 08020024
	subs r0, #1                         @ 08020026
	subs r0, r0, r2                     @ 08020028
	svc #6                              @ 0802002A
	adds r7, r0, #0                     @ 0802002C
	ldr r0, [r4, #0x1c]                 @ 0802002E
	ldr r1, [r4]                        @ 08020030
	muls r0, r7, r0                     @ 08020032
	adds r0, r1, r0                     @ 08020034
	ldr r1, [r4, #0x24]                 @ 08020036
	ldr r2, [r4, #0x20]                 @ 08020038
	subs r1, r1, r2                     @ 0802003A
	subs r0, r0, r1                     @ 0802003C
	str r0, [sp]                        @ 0802003E
	adds r1, r6, #0                     @ 08020040
	adds r2, r7, #0                     @ 08020042
	adds r0, r4, #0                     @ 08020044
	ldr r3, [r4, #0x18]                 @ 08020046
	bl __call_via_r3                    @ 08020048
	lsls r0, r7, #2                     @ 0802004C
	adds r6, r0, r6                     @ 0802004E
	ldr r0, [sp]                        @ 08020050
	subs r5, r5, r7                     @ 08020052
	cmp r5, #0                          @ 08020054
	str r0, [r4]                        @ 08020056
	bgt L_08020004                      @ 08020058
	b L_0801FF5C                        @ 0802005A
L_0802005C:
	ldr r0, [r4, #4]                    @ 0802005C
	ldr r2, [r4]                        @ 0802005E
	muls r0, r5, r0                     @ 08020060
	adds r7, r2, r0                     @ 08020062
	ldr r0, [r4, #0x24]                 @ 08020064
	cmp r0, r7                          @ 08020066
	ble L_0802007A                      @ 08020068
	adds r2, r5, #0                     @ 0802006A
	adds r1, r6, #0                     @ 0802006C
	adds r0, r4, #0                     @ 0802006E
	ldr r3, [r4, #0x18]                 @ 08020070
	bl __call_via_r3                    @ 08020072
	str r7, [r4]                        @ 08020076
	b L_0801FF5C                        @ 08020078
L_0802007A:
	ldr r1, [r4, #0x1c]                 @ 0802007A
	adds r0, r0, r1                     @ 0802007C
	subs r0, #1                         @ 0802007E
	subs r0, r0, r2                     @ 08020080
	svc #6                              @ 08020082
	adds r2, r0, #0                     @ 08020084
	adds r1, r6, #0                     @ 08020086
	adds r0, r4, #0                     @ 08020088
	ldr r3, [r4, #0x18]                 @ 0802008A
	bl __call_via_r3                    @ 0802008C
	movs r0, #0                         @ 08020090
	strb r0, [r4, #0x10]                @ 08020092
	ldr r0, [r4, #0x2c]                 @ 08020094
	cmp r0, #0                          @ 08020096
	beq L_0801FFB4                      @ 08020098
	adds r0, #0x40                      @ 0802009A
	ldrb r1, [r0, #0xa]                 @ 0802009C
	movs r2, #4                         @ 0802009E
	bics r1, r2                         @ 080200A0
	strb r1, [r0, #0xa]                 @ 080200A2
	b L_0801FF5C                        @ 080200A4

@ --------------------------------------------------------------------------------------------
@ void Voice_Start(Voice *v, const SampleHdr *h, int vol, int pan)
	.thumb_func
	.global Voice_Start
Voice_Start:
	push {r4}                           @ 080200A6
	movs r4, #1                         @ 080200A8
	lsls r4, r4, #0xe                   @ 080200AA
	str r1, [r0, #0x28]                 @ 080200AC
	str r4, [r0, #0x30]                 @ 080200AE
	strb r2, [r0, #0x12]                @ 080200B0
	strb r3, [r0, #0x13]                @ 080200B2
	movs r1, #0x1f                      @ 080200B4
	strb r1, [r0, #0x10]                @ 080200B6
	pop {r4}                            @ 080200B8
	bx lr                               @ 080200BA

@ --------------------------------------------------------------------------------------------
@ void Pool_StopAll(Voice pool[16])
	.thumb_func
	.global Pool_StopAll
Pool_StopAll:
	movs r1, #0                         @ 080200BC
L_080200BE:
	lsls r2, r1, #6                     @ 080200BE
	adds r2, r2, r0                     @ 080200C0
	ldrb r3, [r2, #0x10]                @ 080200C2
	adds r1, #1                         @ 080200C4
	lsrs r3, r3, #1                     @ 080200C6
	lsls r3, r3, #1                     @ 080200C8
	strb r3, [r2, #0x10]                @ 080200CA
	cmp r1, #0x10                       @ 080200CC
	blt L_080200BE                      @ 080200CE
	bx lr                               @ 080200D0

@ --------------------------------------------------------------------------------------------
@ void Pool_StopSample(Voice pool[16], const SampleHdr *h): stop the first voice playing h.
	.thumb_func
	.global Pool_StopSample
Pool_StopSample:
	push {r4}                           @ 080200D2
	movs r2, #0                         @ 080200D4
L_080200D6:
	lsls r3, r2, #6                     @ 080200D6
	adds r3, r3, r0                     @ 080200D8
	ldrb r4, [r3, #0x10]                @ 080200DA
	lsls r4, r4, #0x1f                  @ 080200DC
	beq L_080200F6                      @ 080200DE
	ldr r3, [r3, #0x28]                 @ 080200E0
	cmp r3, r1                          @ 080200E2
	bne L_080200F6                      @ 080200E4
	lsls r1, r2, #6                     @ 080200E6
	adds r0, r1, r0                     @ 080200E8
	ldrb r1, [r0, #0x10]                @ 080200EA
	lsrs r1, r1, #1                     @ 080200EC
	lsls r1, r1, #1                     @ 080200EE
	strb r1, [r0, #0x10]                @ 080200F0
L_080200F2:
	pop {r4}                            @ 080200F2
	bx lr                               @ 080200F4
L_080200F6:
	adds r2, #1                         @ 080200F6
	cmp r2, #0x10                       @ 080200F8
	blt L_080200D6                      @ 080200FA
	b L_080200F2                        @ 080200FC

@ --------------------------------------------------------------------------------------------
@ void Pool_StopMatch(Voice pool[16], const SampleHdr *h, int vol, int pan):
@ stop the first voice playing h with exactly this volume and pan.
	.thumb_func
	.global Pool_StopMatch
Pool_StopMatch:
	push {r4, r5, r6}                   @ 080200FE
	adds r5, r3, #0                     @ 08020100
	movs r4, #0                         @ 08020102
L_08020104:
	lsls r3, r4, #6                     @ 08020104
	adds r3, r3, r0                     @ 08020106
	ldrb r6, [r3, #0x10]                @ 08020108
	lsls r6, r6, #0x1f                  @ 0802010A
	beq L_08020134                      @ 0802010C
	ldr r6, [r3, #0x28]                 @ 0802010E
	cmp r6, r1                          @ 08020110
	bne L_08020134                      @ 08020112
	ldrb r6, [r3, #0x12]                @ 08020114
	cmp r6, r2                          @ 08020116
	bne L_08020134                      @ 08020118
	adds r6, r3, #0                     @ 0802011A
	movs r3, #0x13                      @ 0802011C
	ldrsb r6, [r6, r3]                  @ 0802011E
	cmp r6, r5                          @ 08020120
	bne L_08020134                      @ 08020122
	lsls r1, r4, #6                     @ 08020124
	adds r0, r1, r0                     @ 08020126
	ldrb r1, [r0, #0x10]                @ 08020128
	lsrs r1, r1, #1                     @ 0802012A
	lsls r1, r1, #1                     @ 0802012C
	strb r1, [r0, #0x10]                @ 0802012E
L_08020130:
	pop {r4, r5, r6}                    @ 08020130
	bx lr                               @ 08020132
L_08020134:
	adds r4, #1                         @ 08020134
	cmp r4, #0x10                       @ 08020136
	blt L_08020104                      @ 08020138
	b L_08020130                        @ 0802013A
L_0802013C:
	.word Mix_Null	@ 0x0801FE85
L_08020140:
	.word Mix_Voice	@ 0x03000520
L_08020144:
	.word 0x00001063
L_08020148:
	.word 0x000007FF

@ --------------------------------------------------------------------------------------------
@ Voice *Pool_Play(Voice pool[16], const SampleHdr *h, int vol, int pan): first free voice or 0.
	.thumb_func
	.global Pool_Play
Pool_Play:
	push {r4, r5}                       @ 0802014C
	movs r4, #0                         @ 0802014E
L_08020150:
	lsls r5, r4, #6                     @ 08020150
	adds r5, r5, r0                     @ 08020152
	ldrb r5, [r5, #0x10]                @ 08020154
	lsls r5, r5, #0x1f                  @ 08020156
	bne L_08020172                      @ 08020158
	lsls r4, r4, #6                     @ 0802015A
	adds r0, r4, r0                     @ 0802015C
	movs r4, #1                         @ 0802015E
	lsls r4, r4, #0xe                   @ 08020160
	str r1, [r0, #0x28]                 @ 08020162
	str r4, [r0, #0x30]                 @ 08020164
	strb r2, [r0, #0x12]                @ 08020166
	strb r3, [r0, #0x13]                @ 08020168
	movs r1, #0x1f                      @ 0802016A
	strb r1, [r0, #0x10]                @ 0802016C
L_0802016E:
	pop {r4, r5}                        @ 0802016E
	bx lr                               @ 08020170
L_08020172:
	adds r4, #1                         @ 08020172
	cmp r4, #0x10                       @ 08020174
	blt L_08020150                      @ 08020176
	movs r0, #0                         @ 08020178
	b L_0802016E                        @ 0802017A

@ --------------------------------------------------------------------------------------------
@ void Pool_AddVoice(Voice pool[16], const Voice *v): copy v into the first free slot.
	.thumb_func
	.global Pool_AddVoice
Pool_AddVoice:
	movs r2, #0                         @ 0802017C
L_0802017E:
	lsls r3, r2, #6                     @ 0802017E
	adds r3, r3, r0                     @ 08020180
	ldrb r3, [r3, #0x10]                @ 08020182
	lsls r3, r3, #0x1f                  @ 08020184
	bne L_0802019E                      @ 08020186
	lsls r2, r2, #6                     @ 08020188
	adds r0, r2, r0                     @ 0802018A
	ldr r2, L_080202CC                  @ 0802018C =0x040000D4
	str r1, [r2]                        @ 0802018E
	str r0, [r2, #4]                    @ 08020190
	movs r0, #0x10                      @ 08020192
	strh r0, [r2, #8]                   @ 08020194
	movs r0, #0x21                      @ 08020196
	lsls r0, r0, #0xa                   @ 08020198
	strh r0, [r2, #0xa]                 @ 0802019A
	bx lr                               @ 0802019C
L_0802019E:
	adds r2, #1                         @ 0802019E
	cmp r2, #0x10                       @ 080201A0
	blt L_0802017E                      @ 080201A2
	bx lr                               @ 080201A4

@ --------------------------------------------------------------------------------------------
@ int Pool_CountActive(Voice pool[16])
	.thumb_func
	.global Pool_CountActive
Pool_CountActive:
	adds r3, r0, #0                     @ 080201A6
	movs r0, #0                         @ 080201A8
	movs r1, #0                         @ 080201AA
L_080201AC:
	lsls r2, r1, #6                     @ 080201AC
	adds r2, r2, r3                     @ 080201AE
	ldrb r2, [r2, #0x10]                @ 080201B0
	lsls r2, r2, #0x1f                  @ 080201B2
	beq L_080201B8                      @ 080201B4
	adds r0, #1                         @ 080201B6
L_080201B8:
	adds r1, #1                         @ 080201B8
	cmp r1, #0x10                       @ 080201BA
	blt L_080201AC                      @ 080201BC
	bx lr                               @ 080201BE

@ --------------------------------------------------------------------------------------------
@ void Pool_Clear(Voice pool[16]): flags = 0 for all.
	.thumb_func
	.global Pool_Clear
Pool_Clear:
	movs r1, #0                         @ 080201C0
	movs r2, #0                         @ 080201C2
L_080201C4:
	lsls r3, r1, #6                     @ 080201C4
	adds r3, r3, r0                     @ 080201C6
	adds r1, #1                         @ 080201C8
	cmp r1, #0x10                       @ 080201CA
	strb r2, [r3, #0x10]                @ 080201CC
	blt L_080201C4                      @ 080201CE
	bx lr                               @ 080201D0

@ --------------------------------------------------------------------------------------------
@ void Pool_UpdateAll(Voice pool[16])
	.thumb_func
	.global Pool_UpdateAll
Pool_UpdateAll:
	push {r4, r5, lr}                   @ 080201D2
	adds r5, r0, #0                     @ 080201D4
	movs r4, #0                         @ 080201D6
L_080201D8:
	lsls r0, r4, #6                     @ 080201D8
	adds r0, r0, r5                     @ 080201DA
	bl Voice_Update                     @ 080201DC
	adds r4, #1                         @ 080201E0
	cmp r4, #0x10                       @ 080201E2
	blt L_080201D8                      @ 080201E4
	pop {r4, r5, pc}                    @ 080201E6

@ --------------------------------------------------------------------------------------------
@ void Pool_MixAll(Voice pool[16], u32 *buf, int n)
	.thumb_func
	.global Pool_MixAll
Pool_MixAll:
	push {r3, r4, r5, r6, r7, lr}       @ 080201E8
	adds r6, r1, #0                     @ 080201EA
	adds r5, r0, #0                     @ 080201EC
	adds r7, r2, #0                     @ 080201EE
	movs r4, #0                         @ 080201F0
L_080201F2:
	lsls r0, r4, #6                     @ 080201F2
	adds r0, r0, r5                     @ 080201F4
	adds r2, r7, #0                     @ 080201F6
	adds r1, r6, #0                     @ 080201F8
	bl Voice_Mix                        @ 080201FA
	adds r4, #1                         @ 080201FE
	cmp r4, #0x10                       @ 08020200
	blt L_080201F2                      @ 08020202
	pop {r3, r4, r5, r6, r7, pc}        @ 08020204

@ --------------------------------------------------------------------------------------------
@ void Pool_SetVolume(Voice pool[16], int bus)
	.thumb_func
	.global Pool_SetVolume
Pool_SetVolume:
	push {r4, r5}                       @ 08020206
	movs r4, #0x10                      @ 08020208
	movs r2, #0                         @ 0802020A
	lsls r3, r1, #0x18                  @ 0802020C
	lsrs r3, r3, #0x18                  @ 0802020E
L_08020210:
	lsls r1, r2, #6                     @ 08020210
	adds r1, r1, r0                     @ 08020212
	movs r5, #0x34                      @ 08020214
	strb r3, [r5, r1]                   @ 08020216
	ldrb r5, [r1, #0x10]                @ 08020218
	adds r2, #1                         @ 0802021A
	orrs r5, r4                         @ 0802021C
	strb r5, [r1, #0x10]                @ 0802021E
	cmp r2, #0x10                       @ 08020220
	blt L_08020210                      @ 08020222
	pop {r4, r5}                        @ 08020224
	bx lr                               @ 08020226

@ --------------------------------------------------------------------------------------------
@ Voice *Pool_Suspend(Voice pool[16]): allocate room for 16 voices and move every active *looping*
@ voice (halfword +10 has both bit 0 = active and bit 8 = looped) into it; one-shot sounds keep playing.
@ Returns the copy for Pool_Restore.
	.thumb_func
	.global Pool_Suspend
Pool_Suspend:
	push {r3, r4, r5, r6, r7, lr}       @ 08020228
	adds r4, r0, #0                     @ 0802022A
	movs r0, #1                         @ 0802022C
	lsls r0, r0, #0xa                   @ 0802022E
	bl mem_alloc                        @ 08020230
	movs r1, #0                         @ 08020234
	movs r2, #0                         @ 08020236
L_08020238:
	lsls r3, r1, #6                     @ 08020238
	adds r3, r3, r0                     @ 0802023A
	adds r1, #1                         @ 0802023C
	cmp r1, #0x10                       @ 0802023E
	strb r2, [r3, #0x10]                @ 08020240
	blt L_08020238                      @ 08020242
	adds r1, r0, #0                     @ 08020244
	movs r2, #0                         @ 08020246
	movs r6, #1                         @ 08020248
L_0802024A:
	lsls r3, r2, #6                     @ 0802024A
	adds r3, r3, r4                     @ 0802024C
	ldrh r7, [r3, #0x10]                @ 0802024E
	movs r5, #0xff                      @ 08020250
	adds r5, #2                         @ 08020252
	bics r5, r7                         @ 08020254
	bne L_08020278                      @ 08020256
	ldrb r5, [r3, #0x10]                @ 08020258
	lsrs r5, r5, #1                     @ 0802025A
	lsls r5, r5, #1                     @ 0802025C
	strb r5, [r3, #0x10]                @ 0802025E
	ldr r5, L_080202CC                  @ 08020260 =0x040000D4
	str r3, [r5]                        @ 08020262
	str r1, [r5, #4]                    @ 08020264
	movs r3, #0x10                      @ 08020266
	strh r3, [r5, #8]                   @ 08020268
	movs r3, #0x21                      @ 0802026A
	lsls r3, r3, #0xa                   @ 0802026C
	strh r3, [r5, #0xa]                 @ 0802026E
	ldrb r3, [r1, #0x10]                @ 08020270
	orrs r3, r6                         @ 08020272
	strb r3, [r1, #0x10]                @ 08020274
	adds r1, #0x40                      @ 08020276
L_08020278:
	adds r2, #1                         @ 08020278
	cmp r2, #0x10                       @ 0802027A
	blt L_0802024A                      @ 0802027C
	pop {r3, r4, r5, r6, r7, pc}        @ 0802027E

@ --------------------------------------------------------------------------------------------
@ void Pool_Restore(Voice pool[16], Voice *saved): put the saved voices back into free slots,
@ then free the copy.
	.thumb_func
	.global Pool_Restore
Pool_Restore:
	push {r3, r4, r5, r6, r7, lr}       @ 08020280
	ldr r7, L_080202CC                  @ 08020282 =0x040000D4
	adds r4, r1, #0                     @ 08020284
	movs r2, #0                         @ 08020286
	movs r6, #0x10                      @ 08020288
L_0802028A:
	lsls r1, r2, #6                     @ 0802028A
	adds r5, r1, r4                     @ 0802028C
	ldrh r3, [r5, #0x10]                @ 0802028E
	movs r1, #0xff                      @ 08020290
	adds r1, #2                         @ 08020292
	bics r1, r3                         @ 08020294
	bne L_080202BC                      @ 08020296
	movs r1, #0                         @ 08020298
L_0802029A:
	lsls r3, r1, #6                     @ 0802029A
	adds r3, r3, r0                     @ 0802029C
	ldrb r3, [r3, #0x10]                @ 0802029E
	lsls r3, r3, #0x1f                  @ 080202A0
	bne L_080202B6                      @ 080202A2
	lsls r1, r1, #6                     @ 080202A4
	adds r1, r1, r0                     @ 080202A6
	str r5, [r7]                        @ 080202A8
	str r1, [r7, #4]                    @ 080202AA
	strh r6, [r7, #8]                   @ 080202AC
	movs r1, #0x21                      @ 080202AE
	lsls r1, r1, #0xa                   @ 080202B0
	strh r1, [r7, #0xa]                 @ 080202B2
	b L_080202BC                        @ 080202B4
L_080202B6:
	adds r1, #1                         @ 080202B6
	cmp r1, #0x10                       @ 080202B8
	blt L_0802029A                      @ 080202BA
L_080202BC:
	adds r2, #1                         @ 080202BC
	cmp r2, #0x10                       @ 080202BE
	blt L_0802028A                      @ 080202C0
	adds r0, r4, #0                     @ 080202C2
	bl mem_free                         @ 080202C4
	pop {r3, r4, r5, r6, r7, pc}        @ 080202C8
	movs r0, r0                         @ 080202CA
L_080202CC:
	.word REG_DMA3SAD	@ 0x040000D4

@ --------------------------------------------------------------------------------------------
@ void Fx_None(Chan *c) -- as version 1; the instrument table is now taken from the current
@ song (song->instr), reached through the constant pointer p_player.
	.thumb_func
	.global Fx_None
Fx_None:
	adds r2, r0, #0                     @ 080202D0
	adds r2, #0x50                      @ 080202D2
	push {r4, r5, r6}                   @ 080202D4
	ldrb r3, [r2, #8]                   @ 080202D6
	movs r1, #0x11                      @ 080202D8
	adds r4, r3, #0                     @ 080202DA
	ands r4, r1                         @ 080202DC
	adds r1, r0, #0                     @ 080202DE
	adds r1, #0x40                      @ 080202E0
	cmp r4, #0                          @ 080202E2
	beq L_08020348                      @ 080202E4
	ldrb r4, [r2, #0xa]                 @ 080202E6
	movs r6, #4                         @ 080202E8
	cmp r4, #0xff                       @ 080202EA
	bne L_08020300                      @ 080202EC
	ldrb r2, [r1, #0xa]                 @ 080202EE
	bics r2, r6                         @ 080202F0
	strb r2, [r1, #0xa]                 @ 080202F2
	ldrb r1, [r0, #0x10]                @ 080202F4
	lsrs r1, r1, #1                     @ 080202F6
	lsls r1, r1, #1                     @ 080202F8
	strb r1, [r0, #0x10]                @ 080202FA
L_080202FC:
	pop {r4, r5, r6}                    @ 080202FC
	bx lr                               @ 080202FE
L_08020300:
	ldrb r5, [r2, #0xc]                 @ 08020300
	lsls r4, r4, #2                     @ 08020302
	lsls r3, r3, #0x1a                  @ 08020304
	strb r5, [r1, #8]                   @ 08020306
	ldr r5, L_08020594                  @ 08020308 =0x087D61AC
	ldr r4, [r5, r4]                    @ 0802030A
	str r4, [r0, #0x40]                 @ 0802030C
	strb r6, [r1, #0xa]                 @ 0802030E
	bpl L_08020322                      @ 08020310
	ldrb r1, [r1, #8]                   @ 08020312
	str r4, [r0, #0x30]                 @ 08020314
	movs r2, #0x17                      @ 08020316
	strb r1, [r0, #0x12]                @ 08020318
	ldrb r1, [r0, #0x10]                @ 0802031A
	orrs r1, r2                         @ 0802031C
	strb r1, [r0, #0x10]                @ 0802031E
	b L_080202FC                        @ 08020320
L_08020322:
	ldr r3, L_08020594                  @ 08020322 =0x087D61AC
	ldrb r2, [r2, #0xb]                 @ 08020324
	subs r3, #4                         @ 08020326
	ldr r3, [r3]                        @ 08020328
	ldrb r1, [r1, #8]                   @ 0802032A
	ldr r3, [r3, #0xc]                  @ 0802032C
	ldr r5, [r3, #8]                    @ 0802032E
	lsls r3, r2, #1                     @ 08020330
	adds r2, r3, r2                     @ 08020332
	lsls r2, r2, #2                     @ 08020334
	adds r2, r5, r2                     @ 08020336
	str r2, [r0, #0x28]                 @ 08020338
	str r4, [r0, #0x30]                 @ 0802033A
	strb r1, [r0, #0x12]                @ 0802033C
	ldrb r1, [r0, #0x10]                @ 0802033E
	movs r2, #0x1f                      @ 08020340
	orrs r1, r2                         @ 08020342
	strb r1, [r0, #0x10]                @ 08020344
	b L_080202FC                        @ 08020346
L_08020348:
	movs r4, #0x44                      @ 08020348
	ands r3, r4                         @ 0802034A
	beq L_080202FC                      @ 0802034C
	ldrb r3, [r2, #0xc]                 @ 0802034E
	strb r3, [r1, #8]                   @ 08020350
	ldrb r1, [r2, #0xc]                 @ 08020352
	movs r2, #0x10                      @ 08020354
	strb r1, [r0, #0x12]                @ 08020356
	ldrb r1, [r0, #0x10]                @ 08020358
	orrs r1, r2                         @ 0802035A
	strb r1, [r0, #0x10]                @ 0802035C
	b L_080202FC                        @ 0802035E

@ --------------------------------------------------------------------------------------------
@ Axx: ticks per row = xx.
	.thumb_func
	.global Fx_A_SetSpeed
Fx_A_SetSpeed:
	push {r4, lr}                       @ 08020360
	adds r4, r0, #0                     @ 08020362
	bl Fx_None                          @ 08020364
	adds r4, #0x50                      @ 08020368
	ldr r1, L_08020594                  @ 0802036A =0x087D61AC
	ldrb r0, [r4, #0xe]                 @ 0802036C
	subs r1, #4                         @ 0802036E
	ldr r1, [r1]                        @ 08020370
	strb r0, [r1, #3]                   @ 08020372
	pop {r4, pc}                        @ 08020374

@ --------------------------------------------------------------------------------------------
@ Bxx: finish the current pattern now and continue at order xx.
	.thumb_func
	.global Fx_B_PositionJump
Fx_B_PositionJump:
	push {r4, lr}                       @ 08020376
	adds r4, r0, #0                     @ 08020378
	bl Fx_None                          @ 0802037A
	ldr r0, L_08020594                  @ 0802037E =0x087D61AC
	adds r4, #0x50                      @ 08020380
	subs r0, #4                         @ 08020382
	ldr r1, [r0]                        @ 08020384
	ldr r2, [r0]                        @ 08020386
	ldrb r1, [r1, #2]                   @ 08020388
	adds r1, #0xff                      @ 0802038A
	strb r1, [r2, #1]                   @ 0802038C
	ldrb r1, [r4, #0xe]                 @ 0802038E
	ldr r0, [r0]                        @ 08020390
	subs r1, #1                         @ 08020392
	str r1, [r0, #0x10]                 @ 08020394
	pop {r4, pc}                        @ 08020396

@ --------------------------------------------------------------------------------------------
@ tick handler: volume -= slide step, stop sliding at 0.
	.thumb_func
	.global Tick_VolSlideDown
Tick_VolSlideDown:
	adds r1, r0, #0                     @ 08020398
	adds r1, #0x40                      @ 0802039A
	ldrb r2, [r1, #8]                   @ 0802039C
	ldrb r3, [r1, #0xb]                 @ 0802039E
	subs r2, r2, r3                     @ 080203A0
	lsls r2, r2, #0x18                  @ 080203A2
	asrs r2, r2, #0x18                  @ 080203A4
	strb r2, [r1, #8]                   @ 080203A6
	cmp r2, #0                          @ 080203A8
	bgt L_080203B8                      @ 080203AA
	movs r2, #0                         @ 080203AC
	strb r2, [r1, #8]                   @ 080203AE
	ldrb r2, [r1, #0xa]                 @ 080203B0
	lsrs r2, r2, #2                     @ 080203B2
	lsls r2, r2, #2                     @ 080203B4
	strb r2, [r1, #0xa]                 @ 080203B6
L_080203B8:
	ldrb r1, [r1, #8]                   @ 080203B8
	movs r2, #0x10                      @ 080203BA
	strb r1, [r0, #0x12]                @ 080203BC
	ldrb r1, [r0, #0x10]                @ 080203BE
	orrs r1, r2                         @ 080203C0
	strb r1, [r0, #0x10]                @ 080203C2
	bx lr                               @ 080203C4

@ --------------------------------------------------------------------------------------------
@ tick handler: volume += slide step, stop sliding at 64.
	.thumb_func
	.global Tick_VolSlideUp
Tick_VolSlideUp:
	adds r1, r0, #0                     @ 080203C6
	adds r1, #0x40                      @ 080203C8
	ldrb r2, [r1, #8]                   @ 080203CA
	ldrb r3, [r1, #0xb]                 @ 080203CC
	adds r2, r2, r3                     @ 080203CE
	lsls r2, r2, #0x18                  @ 080203D0
	asrs r2, r2, #0x18                  @ 080203D2
	strb r2, [r1, #8]                   @ 080203D4
	cmp r2, #0x40                       @ 080203D6
	blt L_080203E6                      @ 080203D8
	movs r2, #0x40                      @ 080203DA
	strb r2, [r1, #8]                   @ 080203DC
	ldrb r2, [r1, #0xa]                 @ 080203DE
	lsrs r2, r2, #2                     @ 080203E0
	lsls r2, r2, #2                     @ 080203E2
	strb r2, [r1, #0xa]                 @ 080203E4
L_080203E6:
	ldrb r1, [r1, #8]                   @ 080203E6
	movs r2, #0x10                      @ 080203E8
	strb r1, [r0, #0x12]                @ 080203EA
	ldrb r1, [r0, #0x10]                @ 080203EC
	orrs r1, r2                         @ 080203EE
	strb r1, [r0, #0x10]                @ 080203F0
	bx lr                               @ 080203F2

@ --------------------------------------------------------------------------------------------
@ Dxy (ST3 rules): Dx0 slide up x per tick, D0y slide down y per tick (DF0/D0F also act on
@ the first tick), DxF fine slide up x once, DFy fine slide down y once. D00 reuses the last value.
	.thumb_func
	.global Fx_D_VolumeSlide
Fx_D_VolumeSlide:
	push {r4, r5, lr}                   @ 080203F4
	adds r4, r0, #0                     @ 080203F6
	bl Fx_None                          @ 080203F8
	movs r0, #0x5e                      @ 080203FC
	ldrb r1, [r0, r4]                   @ 080203FE
	adds r0, r4, #0                     @ 08020400
	adds r0, #0x40                      @ 08020402
	cmp r1, #0                          @ 08020404
	beq L_0802040A                      @ 08020406
	strb r1, [r0, #0xc]                 @ 08020408
L_0802040A:
	ldrb r1, [r0, #0xc]                 @ 0802040A
	movs r3, #1                         @ 0802040C
	lsls r2, r1, #0x1c                  @ 0802040E
	lsrs r2, r2, #0x1c                  @ 08020410
	cmp r2, #0                          @ 08020412
	bne L_08020432                      @ 08020414
	lsrs r1, r1, #4                     @ 08020416
	strb r1, [r0, #0xb]                 @ 08020418
	ldr r1, L_08020598                  @ 0802041A =0x080203C7
	str r1, [r4, #0x54]                 @ 0802041C
	ldrb r1, [r0, #0xa]                 @ 0802041E
	orrs r1, r3                         @ 08020420
	strb r1, [r0, #0xa]                 @ 08020422
	ldrb r0, [r0, #0xb]                 @ 08020424
	cmp r0, #0xf                        @ 08020426
	bne L_08020430                      @ 08020428
	adds r0, r4, #0                     @ 0802042A
	bl Tick_VolSlideUp                  @ 0802042C
L_08020430:
	pop {r4, r5, pc}                    @ 08020430
L_08020432:
	lsls r2, r1, #0x18                  @ 08020432
	lsrs r5, r2, #0x1c                  @ 08020434
	bne L_08020454                      @ 08020436
	ldrb r1, [r0, #0xc]                 @ 08020438
	strb r1, [r0, #0xb]                 @ 0802043A
	ldr r1, L_0802059C                  @ 0802043C =0x08020399
	str r1, [r4, #0x54]                 @ 0802043E
	ldrb r1, [r0, #0xa]                 @ 08020440
	orrs r1, r3                         @ 08020442
	strb r1, [r0, #0xa]                 @ 08020444
	ldrb r0, [r0, #0xb]                 @ 08020446
	cmp r0, #0xf                        @ 08020448
	bne L_08020430                      @ 0802044A
	adds r0, r4, #0                     @ 0802044C
	bl Tick_VolSlideDown                @ 0802044E
	pop {r4, r5, pc}                    @ 08020452
L_08020454:
	movs r3, #0xf                       @ 08020454
	bics r3, r1                         @ 08020456
	bne L_08020466                      @ 08020458
	lsrs r1, r1, #4                     @ 0802045A
	strb r1, [r0, #0xb]                 @ 0802045C
	adds r0, r4, #0                     @ 0802045E
	bl Tick_VolSlideUp                  @ 08020460
L_08020464:
	pop {r4, r5, pc}                    @ 08020464
L_08020466:
	lsrs r2, r2, #0x1c                  @ 08020466
	cmp r2, #0xf                        @ 08020468
	bne L_08020464                      @ 0802046A
	ands r1, r2                         @ 0802046C
	strb r1, [r0, #0xb]                 @ 0802046E
	adds r0, r4, #0                     @ 08020470
	bl Tick_VolSlideDown                @ 08020472
	pop {r4, r5, pc}                    @ 08020476

@ --------------------------------------------------------------------------------------------
@ tick handler: pitch = pitch * PortaDownTab[speed] >> 16.
	.thumb_func
	.global Tick_PortaDown
Tick_PortaDown:
	movs r1, #0x4d                      @ 08020478
	ldrb r1, [r1, r0]                   @ 0802047A
	ldr r3, L_080205A0                  @ 0802047C =0x087D670C
	ldr r2, [r0, #0x40]                 @ 0802047E
	lsls r1, r1, #1                     @ 08020480
	ldrh r1, [r3, r1]                   @ 08020482
	muls r2, r1, r2                     @ 08020484
	lsrs r1, r2, #0x10                  @ 08020486
	str r1, [r0, #0x40]                 @ 08020488
	str r1, [r0, #0x30]                 @ 0802048A
	ldrb r1, [r0, #0x10]                @ 0802048C
	movs r2, #2                         @ 0802048E
	orrs r1, r2                         @ 08020490
	strb r1, [r0, #0x10]                @ 08020492
	bx lr                               @ 08020494

@ --------------------------------------------------------------------------------------------
@ Exx portamento down: xx/16 semitone per tick; EFx fine (x/16 semitone once),
@ EEx extra fine (x/64 semitone once). E00 reuses the shared E/F/G memory.
	.thumb_func
	.global Fx_E_PortaDown
Fx_E_PortaDown:
	push {r4, r5, lr}                   @ 08020496
	adds r4, r0, #0                     @ 08020498
	bl Fx_None                          @ 0802049A
	movs r0, #0x5e                      @ 0802049E
	ldrb r1, [r0, r4]                   @ 080204A0
	adds r0, r4, #0                     @ 080204A2
	adds r0, #0x40                      @ 080204A4
	cmp r1, #0                          @ 080204A6
	beq L_080204AC                      @ 080204A8
	strb r1, [r0, #0xd]                 @ 080204AA
L_080204AC:
	ldrb r3, [r0, #0xa]                 @ 080204AC
	lsls r1, r3, #0x1d                  @ 080204AE
	lsrs r1, r1, #0x1f                  @ 080204B0
	beq L_080204D8                      @ 080204B2
	ldrb r1, [r0, #0xd]                 @ 080204B4
	movs r5, #2                         @ 080204B6
	lsls r2, r1, #0x18                  @ 080204B8
	lsrs r2, r2, #0x1c                  @ 080204BA
	cmp r2, #0xf                        @ 080204BC
	bne L_080204DA                      @ 080204BE
	lsls r0, r1, #0x1c                  @ 080204C0
	ldr r2, L_080205A0                  @ 080204C2 =0x087D670C
	lsrs r0, r0, #0x1b                  @ 080204C4
	ldrh r0, [r2, r0]                   @ 080204C6
	ldr r1, [r4, #0x40]                 @ 080204C8
	muls r1, r0, r1                     @ 080204CA
	lsrs r0, r1, #0x10                  @ 080204CC
	str r0, [r4, #0x40]                 @ 080204CE
	str r0, [r4, #0x30]                 @ 080204D0
	ldrb r0, [r4, #0x10]                @ 080204D2
	orrs r0, r5                         @ 080204D4
	strb r0, [r4, #0x10]                @ 080204D6
L_080204D8:
	pop {r4, r5, pc}                    @ 080204D8
L_080204DA:
	cmp r2, #0xe                        @ 080204DA
	bne L_080204FA                      @ 080204DC
	ldr r2, L_080205A0                  @ 080204DE =0x087D670C
	lsls r0, r1, #0x1c                  @ 080204E0
	lsrs r0, r0, #0x1b                  @ 080204E2
	subs r2, #0x80                      @ 080204E4
	ldrh r0, [r2, r0]                   @ 080204E6
	ldr r1, [r4, #0x40]                 @ 080204E8
	muls r1, r0, r1                     @ 080204EA
	lsrs r0, r1, #0x10                  @ 080204EC
	str r0, [r4, #0x40]                 @ 080204EE
	str r0, [r4, #0x30]                 @ 080204F0
	ldrb r0, [r4, #0x10]                @ 080204F2
	orrs r0, r5                         @ 080204F4
	strb r0, [r4, #0x10]                @ 080204F6
	pop {r4, r5, pc}                    @ 080204F8
L_080204FA:
	ldr r1, L_080205A4                  @ 080204FA =0x08020479
	str r1, [r4, #0x54]                 @ 080204FC
	movs r1, #1                         @ 080204FE
	orrs r1, r3                         @ 08020500
	strb r1, [r0, #0xa]                 @ 08020502
	pop {r4, r5, pc}                    @ 08020504

@ --------------------------------------------------------------------------------------------
@ tick handler: pitch = pitch * PortaUpTab[speed] >> 14.
	.thumb_func
	.global Tick_PortaUp
Tick_PortaUp:
	movs r1, #0x4d                      @ 08020506
	ldrb r1, [r1, r0]                   @ 08020508
	ldr r3, L_080205A8                  @ 0802050A =0x087D648C
	ldr r2, [r0, #0x40]                 @ 0802050C
	lsls r1, r1, #1                     @ 0802050E
	ldrh r1, [r3, r1]                   @ 08020510
	muls r2, r1, r2                     @ 08020512
	lsrs r1, r2, #0xe                   @ 08020514
	str r1, [r0, #0x40]                 @ 08020516
	str r1, [r0, #0x30]                 @ 08020518
	ldrb r1, [r0, #0x10]                @ 0802051A
	movs r2, #2                         @ 0802051C
	orrs r1, r2                         @ 0802051E
	strb r1, [r0, #0x10]                @ 08020520
	bx lr                               @ 08020522

@ --------------------------------------------------------------------------------------------
@ Fxx portamento up, same encoding as E.
	.thumb_func
	.global Fx_F_PortaUp
Fx_F_PortaUp:
	push {r4, r5, lr}                   @ 08020524
	adds r4, r0, #0                     @ 08020526
	bl Fx_None                          @ 08020528
	movs r0, #0x5e                      @ 0802052C
	ldrb r1, [r0, r4]                   @ 0802052E
	adds r0, r4, #0                     @ 08020530
	adds r0, #0x40                      @ 08020532
	cmp r1, #0                          @ 08020534
	beq L_0802053A                      @ 08020536
	strb r1, [r0, #0xd]                 @ 08020538
L_0802053A:
	ldrb r3, [r0, #0xa]                 @ 0802053A
	lsls r1, r3, #0x1d                  @ 0802053C
	lsrs r1, r1, #0x1f                  @ 0802053E
	beq L_08020566                      @ 08020540
	ldrb r1, [r0, #0xd]                 @ 08020542
	movs r5, #2                         @ 08020544
	lsls r2, r1, #0x18                  @ 08020546
	lsrs r2, r2, #0x1c                  @ 08020548
	cmp r2, #0xf                        @ 0802054A
	bne L_08020568                      @ 0802054C
	lsls r0, r1, #0x1c                  @ 0802054E
	ldr r2, L_080205A8                  @ 08020550 =0x087D648C
	lsrs r0, r0, #0x1b                  @ 08020552
	ldrh r0, [r2, r0]                   @ 08020554
	ldr r1, [r4, #0x40]                 @ 08020556
	muls r1, r0, r1                     @ 08020558
	lsrs r0, r1, #0xe                   @ 0802055A
	str r0, [r4, #0x40]                 @ 0802055C
	str r0, [r4, #0x30]                 @ 0802055E
	ldrb r0, [r4, #0x10]                @ 08020560
	orrs r0, r5                         @ 08020562
	strb r0, [r4, #0x10]                @ 08020564
L_08020566:
	pop {r4, r5, pc}                    @ 08020566
L_08020568:
	cmp r2, #0xe                        @ 08020568
	bne L_08020588                      @ 0802056A
	ldr r2, L_080205A8                  @ 0802056C =0x087D648C
	lsls r0, r1, #0x1c                  @ 0802056E
	lsrs r0, r0, #0x1b                  @ 08020570
	subs r2, #0x80                      @ 08020572
	ldrh r0, [r2, r0]                   @ 08020574
	ldr r1, [r4, #0x40]                 @ 08020576
	muls r1, r0, r1                     @ 08020578
	lsrs r0, r1, #0xf                   @ 0802057A
	str r0, [r4, #0x40]                 @ 0802057C
	str r0, [r4, #0x30]                 @ 0802057E
	ldrb r0, [r4, #0x10]                @ 08020580
	orrs r0, r5                         @ 08020582
	strb r0, [r4, #0x10]                @ 08020584
	pop {r4, r5, pc}                    @ 08020586
L_08020588:
	ldr r1, L_080205AC                  @ 08020588 =0x08020507
	str r1, [r4, #0x54]                 @ 0802058A
	movs r1, #1                         @ 0802058C
	orrs r1, r3                         @ 0802058E
	strb r1, [r0, #0xa]                 @ 08020590
	pop {r4, r5, pc}                    @ 08020592
L_08020594:
	.word NoteFreqTab	@ 0x087D61AC
L_08020598:
	.word Tick_VolSlideUp	@ 0x080203C7
L_0802059C:
	.word Tick_VolSlideDown	@ 0x08020399
L_080205A0:
	.word PortaDownTab	@ 0x087D670C
L_080205A4:
	.word Tick_PortaDown	@ 0x08020479
L_080205A8:
	.word PortaUpTab	@ 0x087D648C
L_080205AC:
	.word Tick_PortaUp	@ 0x08020507

@ --------------------------------------------------------------------------------------------
@ tick handler: slide down towards the target, clamp and stop when reached.
	.thumb_func
	.global Tick_TonePortaDown
Tick_TonePortaDown:
	adds r1, r0, #0                     @ 080205B0
	adds r1, #0x40                      @ 080205B2
	push {r4, r5}                       @ 080205B4
	ldrb r2, [r1, #0xd]                 @ 080205B6
	ldr r4, L_08020834                  @ 080205B8 =0x087D670C
	ldr r3, [r0, #0x40]                 @ 080205BA
	lsls r2, r2, #1                     @ 080205BC
	ldrh r2, [r4, r2]                   @ 080205BE
	movs r5, #2                         @ 080205C0
	muls r3, r2, r3                     @ 080205C2
	lsrs r4, r3, #0x10                  @ 080205C4
	str r4, [r0, #0x40]                 @ 080205C6
	str r4, [r0, #0x30]                 @ 080205C8
	ldrb r2, [r0, #0x10]                @ 080205CA
	orrs r2, r5                         @ 080205CC
	adds r3, r2, #0                     @ 080205CE
	strb r3, [r0, #0x10]                @ 080205D0
	ldr r2, [r0, #0x44]                 @ 080205D2
	cmp r4, r2                          @ 080205D4
	bhs L_080205EE                      @ 080205D6
	str r2, [r0, #0x40]                 @ 080205D8
	str r2, [r0, #0x30]                 @ 080205DA
	orrs r3, r5                         @ 080205DC
	adds r2, r3, #0                     @ 080205DE
	strb r2, [r0, #0x10]                @ 080205E0
	ldrb r0, [r1, #0xa]                 @ 080205E2
	movs r2, #8                         @ 080205E4
	bics r0, r2                         @ 080205E6
	lsrs r0, r0, #2                     @ 080205E8
	lsls r0, r0, #2                     @ 080205EA
	strb r0, [r1, #0xa]                 @ 080205EC
L_080205EE:
	pop {r4, r5}                        @ 080205EE
	bx lr                               @ 080205F0

@ --------------------------------------------------------------------------------------------
@ tick handler: slide up towards the target, clamp and stop when reached.
	.thumb_func
	.global Tick_TonePortaUp
Tick_TonePortaUp:
	adds r1, r0, #0                     @ 080205F2
	adds r1, #0x40                      @ 080205F4
	push {r4, r5}                       @ 080205F6
	ldrb r2, [r1, #0xd]                 @ 080205F8
	ldr r4, L_08020838                  @ 080205FA =0x087D648C
	ldr r3, [r0, #0x40]                 @ 080205FC
	lsls r2, r2, #1                     @ 080205FE
	ldrh r2, [r4, r2]                   @ 08020600
	movs r5, #2                         @ 08020602
	muls r3, r2, r3                     @ 08020604
	lsrs r4, r3, #0xe                   @ 08020606
	str r4, [r0, #0x40]                 @ 08020608
	str r4, [r0, #0x30]                 @ 0802060A
	ldrb r2, [r0, #0x10]                @ 0802060C
	orrs r2, r5                         @ 0802060E
	adds r3, r2, #0                     @ 08020610
	strb r3, [r0, #0x10]                @ 08020612
	ldr r2, [r0, #0x44]                 @ 08020614
	cmp r4, r2                          @ 08020616
	bls L_08020630                      @ 08020618
	str r2, [r0, #0x40]                 @ 0802061A
	str r2, [r0, #0x30]                 @ 0802061C
	orrs r3, r5                         @ 0802061E
	adds r2, r3, #0                     @ 08020620
	strb r2, [r0, #0x10]                @ 08020622
	ldrb r0, [r1, #0xa]                 @ 08020624
	movs r2, #8                         @ 08020626
	bics r0, r2                         @ 08020628
	lsrs r0, r0, #2                     @ 0802062A
	lsls r0, r0, #2                     @ 0802062C
	strb r0, [r1, #0xa]                 @ 0802062E
L_08020630:
	pop {r4, r5}                        @ 08020630
	bx lr                               @ 08020632

@ --------------------------------------------------------------------------------------------
@ Gxx tone portamento: a note on this row becomes the target instead of being played;
@ the direction picks Tick_TonePortaUp/Down. Does nothing (not even play the note) if the channel
@ is silent.
	.thumb_func
	.global Fx_G_TonePorta
Fx_G_TonePorta:
	adds r2, r0, #0                     @ 08020634
	adds r2, #0x50                      @ 08020636
	push {r4, r5, r6}                   @ 08020638
	ldrb r3, [r2, #0xe]                 @ 0802063A
	adds r1, r0, #0                     @ 0802063C
	adds r1, #0x40                      @ 0802063E
	cmp r3, #0                          @ 08020640
	beq L_08020646                      @ 08020642
	strb r3, [r1, #0xd]                 @ 08020644
L_08020646:
	ldrb r3, [r1, #0xa]                 @ 08020646
	lsls r4, r3, #0x1d                  @ 08020648
	lsrs r4, r4, #0x1f                  @ 0802064A
	beq L_080206A4                      @ 0802064C
	ldrb r5, [r2, #8]                   @ 0802064E
	movs r4, #0x11                      @ 08020650
	ands r4, r5                         @ 08020652
	beq L_0802066C                      @ 08020654
	ldrb r4, [r2, #0xa]                 @ 08020656
	cmp r4, #0xff                       @ 08020658
	beq L_08020690                      @ 0802065A
	ldr r6, L_0802083C                  @ 0802065C =0x087D61AC
	lsls r4, r4, #2                     @ 0802065E
	ldr r4, [r6, r4]                    @ 08020660
	str r4, [r0, #0x44]                 @ 08020662
	movs r4, #8                         @ 08020664
	orrs r3, r4                         @ 08020666
	strb r3, [r1, #0xa]                 @ 08020668
	b L_08020670                        @ 0802066A
L_0802066C:
	lsls r3, r3, #0x1c                  @ 0802066C
	bpl L_08020690                      @ 0802066E
L_08020670:
	ldr r3, [r0, #0x44]                 @ 08020670
	ldr r6, [r0, #0x40]                 @ 08020672
	movs r4, #1                         @ 08020674
	cmp r3, r6                          @ 08020676
	bls L_08020686                      @ 08020678
	ldr r3, L_08020840                  @ 0802067A =0x080205F3
	str r3, [r0, #0x54]                 @ 0802067C
	ldrb r3, [r1, #0xa]                 @ 0802067E
	orrs r3, r4                         @ 08020680
	strb r3, [r1, #0xa]                 @ 08020682
	b L_08020690                        @ 08020684
L_08020686:
	ldr r3, L_08020844                  @ 08020686 =0x080205B1
	str r3, [r0, #0x54]                 @ 08020688
	ldrb r3, [r1, #0xa]                 @ 0802068A
	orrs r3, r4                         @ 0802068C
	strb r3, [r1, #0xa]                 @ 0802068E
L_08020690:
	movs r3, #0x44                      @ 08020690
	ands r5, r3                         @ 08020692
	beq L_080206A4                      @ 08020694
	ldrb r2, [r2, #0xc]                 @ 08020696
	strb r2, [r1, #8]                   @ 08020698
	strb r2, [r0, #0x12]                @ 0802069A
	ldrb r1, [r0, #0x10]                @ 0802069C
	movs r2, #0x10                      @ 0802069E
	orrs r1, r2                         @ 080206A0
	strb r1, [r0, #0x10]                @ 080206A2
L_080206A4:
	pop {r4, r5, r6}                    @ 080206A4
	bx lr                               @ 080206A6

@ --------------------------------------------------------------------------------------------
@ tick handler: phase += speed; offset = VibratoSine[phase] * depth >> 6 (1/64 semitone units);
@ voice pitch = channel pitch scaled by PortaFineUpTab/PortaFineDownTab[|offset|]. The channel's own
@ pitch is not changed, Mus_ChannelRow restores it on the next row.
	.thumb_func
	.global Tick_Vibrato
Tick_Vibrato:
	adds r1, r0, #0                     @ 080206A8
	adds r1, #0x50                      @ 080206AA
	movs r3, #0x4f                      @ 080206AC
	ldrb r3, [r3, r0]                   @ 080206AE
	ldrb r2, [r1, #1]                   @ 080206B0
	adds r2, r2, r3                     @ 080206B2
	lsls r2, r2, #0x1a                  @ 080206B4
	lsrs r2, r2, #0x1a                  @ 080206B6
	strb r2, [r1, #1]                   @ 080206B8
	ldr r3, L_08020848                  @ 080206BA =0x087D690C
	ldrb r1, [r1]                       @ 080206BC
	ldrsb r2, [r3, r2]                  @ 080206BE
	muls r1, r2, r1                     @ 080206C0
	asrs r1, r1, #6                     @ 080206C2
	ldr r2, [r0, #0x40]                 @ 080206C4
	bpl L_080206D8                      @ 080206C6
	ldr r3, L_08020834                  @ 080206C8 =0x087D670C
	lsls r1, r1, #1                     @ 080206CA
	subs r3, #0x80                      @ 080206CC
	subs r1, r3, r1                     @ 080206CE
	ldrh r1, [r1]                       @ 080206D0
	muls r2, r1, r2                     @ 080206D2
	lsrs r1, r2, #0x10                  @ 080206D4
	b L_080206E4                        @ 080206D6
L_080206D8:
	ldr r3, L_08020838                  @ 080206D8 =0x087D648C
	lsls r1, r1, #1                     @ 080206DA
	subs r3, #0x80                      @ 080206DC
	ldrh r1, [r3, r1]                   @ 080206DE
	muls r2, r1, r2                     @ 080206E0
	lsrs r1, r2, #0xf                   @ 080206E2
L_080206E4:
	str r1, [r0, #0x30]                 @ 080206E4
	ldrb r1, [r0, #0x10]                @ 080206E6
	movs r2, #2                         @ 080206E8
	orrs r1, r2                         @ 080206EA
	strb r1, [r0, #0x10]                @ 080206EC
	bx lr                               @ 080206EE

@ --------------------------------------------------------------------------------------------
@ Hxy vibrato: speed x, depth y*4 (zero nibbles keep the old value).
	.thumb_func
	.global Fx_H_Vibrato
Fx_H_Vibrato:
	push {r4, r5, lr}                   @ 080206F0
	adds r4, r0, #0                     @ 080206F2
	bl Fx_None                          @ 080206F4
	adds r2, r4, #0                     @ 080206F8
	adds r2, #0x40                      @ 080206FA
	ldrb r3, [r2, #0xa]                 @ 080206FC
	lsls r0, r3, #0x1d                  @ 080206FE
	lsrs r0, r0, #0x1f                  @ 08020700
	beq L_0802073A                      @ 08020702
	adds r0, r4, #0                     @ 08020704
	adds r0, #0x50                      @ 08020706
	ldrb r1, [r0, #8]                   @ 08020708
	movs r5, #0x11                      @ 0802070A
	ands r1, r5                         @ 0802070C
	beq L_08020714                      @ 0802070E
	movs r1, #0                         @ 08020710
	strb r1, [r0, #1]                   @ 08020712
L_08020714:
	ldrb r1, [r0, #0xe]                 @ 08020714
	lsls r5, r1, #0x1c                  @ 08020716
	beq L_08020720                      @ 08020718
	lsls r5, r1, #0x1c                  @ 0802071A
	lsrs r5, r5, #0x1a                  @ 0802071C
	strb r5, [r0]                       @ 0802071E
L_08020720:
	lsls r0, r1, #0x18                  @ 08020720
	lsrs r0, r0, #0x1c                  @ 08020722
	beq L_0802072A                      @ 08020724
	lsrs r0, r1, #4                     @ 08020726
	strb r0, [r2, #0xf]                 @ 08020728
L_0802072A:
	ldr r0, L_0802084C                  @ 0802072A =0x080206A9
	str r0, [r4, #0x54]                 @ 0802072C
	movs r0, #1                         @ 0802072E
	orrs r0, r3                         @ 08020730
	strb r0, [r2, #0xa]                 @ 08020732
	adds r0, r4, #0                     @ 08020734
	bl Tick_Vibrato                     @ 08020736
L_0802073A:
	pop {r4, r5, pc}                    @ 0802073A

@ --------------------------------------------------------------------------------------------
@ empty functions: unreferenced (the converter maps unsupported effects to Fx_None)
	.thumb_func
	.global Fx_Empty1
Fx_Empty1:
	bx lr                               @ 0802073C
	.thumb_func
	.global Fx_Empty2
Fx_Empty2:
	bx lr                               @ 0802073E

@ --------------------------------------------------------------------------------------------
@ tick handler for K: volume slide down + vibrato.
	.thumb_func
	.global Tick_VibratoVolDown
Tick_VibratoVolDown:
	adds r1, r0, #0                     @ 08020740
	adds r1, #0x40                      @ 08020742
	ldrb r2, [r1, #8]                   @ 08020744
	ldrb r3, [r1, #0xb]                 @ 08020746
	subs r2, r2, r3                     @ 08020748
	lsls r2, r2, #0x18                  @ 0802074A
	asrs r2, r2, #0x18                  @ 0802074C
	strb r2, [r1, #8]                   @ 0802074E
	cmp r2, #0                          @ 08020750
	bgt L_0802075C                      @ 08020752
	movs r2, #0                         @ 08020754
	strb r2, [r1, #8]                   @ 08020756
	ldr r2, L_0802084C                  @ 08020758 =0x080206A9
	str r2, [r0, #0x54]                 @ 0802075A
L_0802075C:
	ldrb r1, [r1, #8]                   @ 0802075C
	movs r2, #0x10                      @ 0802075E
	strb r1, [r0, #0x12]                @ 08020760
	ldrb r1, [r0, #0x10]                @ 08020762
	orrs r1, r2                         @ 08020764
	strb r1, [r0, #0x10]                @ 08020766
	b Tick_Vibrato                      @ 08020768

@ --------------------------------------------------------------------------------------------
@ tick handler for K: volume slide up + vibrato.
	.thumb_func
	.global Tick_VibratoVolUp
Tick_VibratoVolUp:
	adds r1, r0, #0                     @ 0802076A
	adds r1, #0x40                      @ 0802076C
	ldrb r2, [r1, #8]                   @ 0802076E
	ldrb r3, [r1, #0xb]                 @ 08020770
	adds r2, r2, r3                     @ 08020772
	lsls r2, r2, #0x18                  @ 08020774
	asrs r2, r2, #0x18                  @ 08020776
	strb r2, [r1, #8]                   @ 08020778
	cmp r2, #0x40                       @ 0802077A
	blt L_08020786                      @ 0802077C
	movs r2, #0x40                      @ 0802077E
	strb r2, [r1, #8]                   @ 08020780
	ldr r2, L_0802084C                  @ 08020782 =0x080206A9
	str r2, [r0, #0x54]                 @ 08020784
L_08020786:
	ldrb r1, [r1, #8]                   @ 08020786
	movs r2, #0x10                      @ 08020788
	strb r1, [r0, #0x12]                @ 0802078A
	ldrb r1, [r0, #0x10]                @ 0802078C
	orrs r1, r2                         @ 0802078E
	strb r1, [r0, #0x10]                @ 08020790
	b Tick_Vibrato                      @ 08020792

@ --------------------------------------------------------------------------------------------
@ Kxy: continue vibrato with volume slide xy (D rules).
	.thumb_func
	.global Fx_K_VibratoVolSlide
Fx_K_VibratoVolSlide:
	push {r4, r5, r6, lr}               @ 08020794
	adds r5, r0, #0                     @ 08020796
	bl Fx_None                          @ 08020798
	adds r0, r5, #0                     @ 0802079C
	adds r0, #0x50                      @ 0802079E
	ldrb r1, [r0, #0xe]                 @ 080207A0
	adds r4, r5, #0                     @ 080207A2
	adds r4, #0x40                      @ 080207A4
	cmp r1, #0                          @ 080207A6
	beq L_080207AC                      @ 080207A8
	strb r1, [r4, #0xc]                 @ 080207AA
L_080207AC:
	ldrb r1, [r4, #0xa]                 @ 080207AC
	lsls r1, r1, #0x1d                  @ 080207AE
	lsrs r1, r1, #0x1f                  @ 080207B0
	beq L_08020830                      @ 080207B2
	ldrb r1, [r0, #8]                   @ 080207B4
	movs r2, #0x11                      @ 080207B6
	ands r1, r2                         @ 080207B8
	beq L_080207C0                      @ 080207BA
	movs r1, #0                         @ 080207BC
	strb r1, [r0, #1]                   @ 080207BE
L_080207C0:
	ldrb r0, [r4, #0xc]                 @ 080207C0
	lsls r1, r0, #0x1c                  @ 080207C2
	bne L_080207DC                      @ 080207C4
	lsrs r0, r0, #4                     @ 080207C6
	strb r0, [r4, #0xb]                 @ 080207C8
	ldr r0, L_08020850                  @ 080207CA =0x0802076B
	str r0, [r5, #0x54]                 @ 080207CC
	ldrb r0, [r4, #0xb]                 @ 080207CE
	cmp r0, #0xf                        @ 080207D0
	bne L_08020822                      @ 080207D2
	adds r0, r5, #0                     @ 080207D4
	bl Tick_VolSlideUp                  @ 080207D6
	b L_08020822                        @ 080207DA
L_080207DC:
	lsls r1, r0, #0x18                  @ 080207DC
	lsrs r2, r1, #0x1c                  @ 080207DE
	bne L_080207F8                      @ 080207E0
	ldrb r0, [r4, #0xc]                 @ 080207E2
	strb r0, [r4, #0xb]                 @ 080207E4
	ldr r0, L_08020854                  @ 080207E6 =0x08020741
	str r0, [r5, #0x54]                 @ 080207E8
	ldrb r0, [r4, #0xb]                 @ 080207EA
	cmp r0, #0xf                        @ 080207EC
	bne L_08020822                      @ 080207EE
	adds r0, r5, #0                     @ 080207F0
	bl Tick_VolSlideDown                @ 080207F2
	b L_08020822                        @ 080207F6
L_080207F8:
	movs r2, #0xf                       @ 080207F8
	bics r2, r0                         @ 080207FA
	cmp r2, #0                          @ 080207FC
	ldr r6, L_0802084C                  @ 080207FE =0x080206A9
	bne L_08020810                      @ 08020800
	lsrs r0, r0, #4                     @ 08020802
	strb r0, [r4, #0xb]                 @ 08020804
	adds r0, r5, #0                     @ 08020806
	bl Tick_VolSlideUp                  @ 08020808
	str r6, [r5, #0x54]                 @ 0802080C
	b L_08020822                        @ 0802080E
L_08020810:
	lsrs r1, r1, #0x1c                  @ 08020810
	cmp r1, #0xf                        @ 08020812
	bne L_08020822                      @ 08020814
	ands r0, r1                         @ 08020816
	strb r0, [r4, #0xb]                 @ 08020818
	adds r0, r5, #0                     @ 0802081A
	bl Tick_VolSlideDown                @ 0802081C
	str r6, [r5, #0x54]                 @ 08020820
L_08020822:
	ldrb r0, [r4, #0xa]                 @ 08020822
	movs r1, #1                         @ 08020824
	orrs r0, r1                         @ 08020826
	strb r0, [r4, #0xa]                 @ 08020828
	adds r0, r5, #0                     @ 0802082A
	bl Tick_Vibrato                     @ 0802082C
L_08020830:
	pop {r4, r5, r6, pc}                @ 08020830
	movs r0, r0                         @ 08020832
L_08020834:
	.word PortaDownTab	@ 0x087D670C
L_08020838:
	.word PortaUpTab	@ 0x087D648C
L_0802083C:
	.word NoteFreqTab	@ 0x087D61AC
L_08020840:
	.word Tick_TonePortaUp	@ 0x080205F3
L_08020844:
	.word Tick_TonePortaDown	@ 0x080205B1
L_08020848:
	.word VibratoSine	@ 0x087D690C
L_0802084C:
	.word Tick_Vibrato	@ 0x080206A9
L_08020850:
	.word Tick_VibratoVolUp	@ 0x0802076B
L_08020854:
	.word Tick_VibratoVolDown	@ 0x08020741

@ --------------------------------------------------------------------------------------------
@ Lxy: continue tone portamento with volume slide xy (D rules); the tick handler is
@ picked from TonePortaVolTicks[direction*3 + slide kind].
	.thumb_func
	.global Fx_L_TonePortaVolSlide
Fx_L_TonePortaVolSlide:
	push {r4, r5, r6, r7, lr}           @ 08020858
	adds r7, r0, #0                     @ 0802085A
	adds r7, #0x50                      @ 0802085C
	adds r5, r0, #0                     @ 0802085E
	ldrb r0, [r7, #0xe]                 @ 08020860
	adds r4, r5, #0                     @ 08020862
	adds r4, #0x40                      @ 08020864
	cmp r0, #0                          @ 08020866
	beq L_0802086C                      @ 08020868
	strb r0, [r4, #0xc]                 @ 0802086A
L_0802086C:
	ldrb r0, [r4, #0xa]                 @ 0802086C
	lsls r0, r0, #0x1d                  @ 0802086E
	lsrs r0, r0, #0x1f                  @ 08020870
	beq L_08020936                      @ 08020872
	ldrb r0, [r7, #8]                   @ 08020874
	movs r6, #0                         @ 08020876
	movs r1, #0x44                      @ 08020878
	ands r0, r1                         @ 0802087A
	beq L_0802088C                      @ 0802087C
	ldrb r0, [r7, #0xc]                 @ 0802087E
	movs r1, #0x10                      @ 08020880
	strb r0, [r4, #8]                   @ 08020882
	strb r0, [r5, #0x12]                @ 08020884
	ldrb r0, [r5, #0x10]                @ 08020886
	orrs r0, r1                         @ 08020888
	strb r0, [r5, #0x10]                @ 0802088A
L_0802088C:
	ldrb r0, [r4, #0xc]                 @ 0802088C
	lsls r1, r0, #0x1c                  @ 0802088E
	bne L_080208A6                      @ 08020890
	lsrs r0, r0, #4                     @ 08020892
	strb r0, [r4, #0xb]                 @ 08020894
	ldrb r0, [r4, #0xb]                 @ 08020896
	movs r6, #1                         @ 08020898
	cmp r0, #0xf                        @ 0802089A
	bne L_080208E2                      @ 0802089C
	adds r0, r5, #0                     @ 0802089E
	bl Tick_VolSlideUp                  @ 080208A0
	b L_080208E2                        @ 080208A4
L_080208A6:
	lsls r1, r0, #0x18                  @ 080208A6
	lsrs r2, r1, #0x1c                  @ 080208A8
	bne L_080208C0                      @ 080208AA
	ldrb r0, [r4, #0xc]                 @ 080208AC
	movs r6, #2                         @ 080208AE
	strb r0, [r4, #0xb]                 @ 080208B0
	ldrb r0, [r4, #0xb]                 @ 080208B2
	cmp r0, #0xf                        @ 080208B4
	bne L_080208E2                      @ 080208B6
	adds r0, r5, #0                     @ 080208B8
	bl Tick_VolSlideDown                @ 080208BA
	b L_080208E2                        @ 080208BE
L_080208C0:
	movs r2, #0xf                       @ 080208C0
	bics r2, r0                         @ 080208C2
	bne L_080208D2                      @ 080208C4
	lsrs r0, r0, #4                     @ 080208C6
	strb r0, [r4, #0xb]                 @ 080208C8
	adds r0, r5, #0                     @ 080208CA
	bl Tick_VolSlideUp                  @ 080208CC
	b L_080208E2                        @ 080208D0
L_080208D2:
	lsrs r1, r1, #0x1c                  @ 080208D2
	cmp r1, #0xf                        @ 080208D4
	bne L_080208E2                      @ 080208D6
	ands r0, r1                         @ 080208D8
	strb r0, [r4, #0xb]                 @ 080208DA
	adds r0, r5, #0                     @ 080208DC
	bl Tick_VolSlideDown                @ 080208DE
L_080208E2:
	ldrb r1, [r7, #8]                   @ 080208E2
	movs r0, #0x11                      @ 080208E4
	ands r1, r0                         @ 080208E6
	movs r0, #1                         @ 080208E8
	cmp r1, #0                          @ 080208EA
	beq L_08020906                      @ 080208EC
	ldrb r1, [r7, #0xa]                 @ 080208EE
	cmp r1, #0xff                       @ 080208F0
	beq L_08020936                      @ 080208F2
	ldr r2, L_08020B7C                  @ 080208F4 =0x087D61AC
	lsls r1, r1, #2                     @ 080208F6
	ldr r1, [r2, r1]                    @ 080208F8
	movs r2, #8                         @ 080208FA
	str r1, [r5, #0x44]                 @ 080208FC
	ldrb r1, [r4, #0xa]                 @ 080208FE
	orrs r1, r2                         @ 08020900
	strb r1, [r4, #0xa]                 @ 08020902
	b L_08020920                        @ 08020904
L_08020906:
	ldrb r1, [r4, #0xa]                 @ 08020906
	lsls r2, r1, #0x1c                  @ 08020908
	bmi L_08020920                      @ 0802090A
	cmp r6, #0                          @ 0802090C
	beq L_08020920                      @ 0802090E
	cmp r6, #1                          @ 08020910
	beq L_08020938                      @ 08020912
	cmp r6, #2                          @ 08020914
	bne L_08020920                      @ 08020916
	ldr r2, L_08020B80                  @ 08020918 =0x08020399
	orrs r1, r0                         @ 0802091A
	str r2, [r5, #0x54]                 @ 0802091C
	strb r1, [r4, #0xa]                 @ 0802091E
L_08020920:
	ldr r1, [r5, #0x44]                 @ 08020920
	ldr r2, [r5, #0x40]                 @ 08020922
	cmp r1, r2                          @ 08020924
	bls L_08020942                      @ 08020926
	ldr r2, L_08020B84                  @ 08020928 =0x087D694C
	lsls r1, r6, #2                     @ 0802092A
	ldr r1, [r2, r1]                    @ 0802092C
	str r1, [r5, #0x54]                 @ 0802092E
	ldrb r1, [r4, #0xa]                 @ 08020930
	orrs r0, r1                         @ 08020932
	strb r0, [r4, #0xa]                 @ 08020934
L_08020936:
	pop {r4, r5, r6, r7, pc}            @ 08020936
L_08020938:
	ldr r2, L_08020B88                  @ 08020938 =0x080203C7
	orrs r1, r0                         @ 0802093A
	str r2, [r5, #0x54]                 @ 0802093C
	strb r1, [r4, #0xa]                 @ 0802093E
	b L_08020920                        @ 08020940
L_08020942:
	ldr r2, L_08020B84                  @ 08020942 =0x087D694C
	lsls r1, r6, #2                     @ 08020944
	adds r2, #0xc                       @ 08020946
	ldr r1, [r2, r1]                    @ 08020948
	str r1, [r5, #0x54]                 @ 0802094A
	ldrb r1, [r4, #0xa]                 @ 0802094C
	orrs r0, r1                         @ 0802094E
	strb r0, [r4, #0xa]                 @ 08020950
	pop {r4, r5, r6, r7, pc}            @ 08020952
	.thumb_func
	.global Fx_Empty3
Fx_Empty3:
	bx lr                               @ 08020954
	.thumb_func
	.global Fx_Empty4
Fx_Empty4:
	bx lr                               @ 08020956

@ --------------------------------------------------------------------------------------------
@ Oxx: start the sample at offset xx*256 bytes.
	.thumb_func
	.global Fx_O_SampleOffset
Fx_O_SampleOffset:
	push {r4, lr}                       @ 08020958
	adds r4, r0, #0                     @ 0802095A
	bl Fx_None                          @ 0802095C
	adds r0, r4, #0                     @ 08020960
	adds r0, #0x50                      @ 08020962
	ldrb r1, [r0, #8]                   @ 08020964
	movs r2, #0x11                      @ 08020966
	ands r1, r2                         @ 08020968
	beq L_08020980                      @ 0802096A
	ldrb r0, [r0, #0xe]                 @ 0802096C
	movs r1, #4                         @ 0802096E
	lsls r0, r0, #0x16                  @ 08020970
	str r0, [r4]                        @ 08020972
	ldrb r0, [r4, #0x10]                @ 08020974
	bics r0, r1                         @ 08020976
	strb r0, [r4, #0x10]                @ 08020978
	ldrb r0, [r4, #0x11]                @ 0802097A
	bics r0, r1                         @ 0802097C
	strb r0, [r4, #0x11]                @ 0802097E
L_08020980:
	pop {r4, pc}                        @ 08020980
	.thumb_func
	.global Fx_Empty5
Fx_Empty5:
	bx lr                               @ 08020982

@ --------------------------------------------------------------------------------------------
@ tick handler: when the counter runs out restart the voice and reload the counter
@ (flags |= 4: unlike version 1 the tick mode survives, so the retrigger repeats).
	.thumb_func
	.global Tick_Retrig
Tick_Retrig:
	adds r1, r0, #0                     @ 08020984
	adds r1, #0x50                      @ 08020986
	ldrb r2, [r1, #2]                   @ 08020988
	adds r2, #0xff                      @ 0802098A
	lsls r2, r2, #0x18                  @ 0802098C
	lsrs r2, r2, #0x18                  @ 0802098E
	strb r2, [r1, #2]                   @ 08020990
	bne L_080209AE                      @ 08020992
	ldrb r2, [r0, #0x10]                @ 08020994
	movs r3, #5                         @ 08020996
	orrs r2, r3                         @ 08020998
	strb r2, [r0, #0x10]                @ 0802099A
	adds r0, #0x40                      @ 0802099C
	ldrb r2, [r0, #0xe]                 @ 0802099E
	lsls r2, r2, #0x1c                  @ 080209A0
	lsrs r2, r2, #0x1c                  @ 080209A2
	strb r2, [r1, #2]                   @ 080209A4
	ldrb r1, [r0, #0xa]                 @ 080209A6
	movs r2, #4                         @ 080209A8
	orrs r1, r2                         @ 080209AA
	strb r1, [r0, #0xa]                 @ 080209AC
L_080209AE:
	bx lr                               @ 080209AE

@ --------------------------------------------------------------------------------------------
@ Qxy retrigger every y ticks (tick mode 2). The volume nibble x is ignored.
	.thumb_func
	.global Fx_Q_Retrig
Fx_Q_Retrig:
	push {r4, lr}                       @ 080209B0
	adds r4, r0, #0                     @ 080209B2
	bl Fx_None                          @ 080209B4
	adds r2, r4, #0                     @ 080209B8
	adds r2, #0x50                      @ 080209BA
	ldrb r1, [r2, #0xe]                 @ 080209BC
	adds r0, r4, #0                     @ 080209BE
	adds r0, #0x40                      @ 080209C0
	cmp r1, #0                          @ 080209C2
	beq L_080209C8                      @ 080209C4
	strb r1, [r0, #0xe]                 @ 080209C6
L_080209C8:
	ldr r1, L_08020B8C                  @ 080209C8 =0x08020985
	str r1, [r4, #0x54]                 @ 080209CA
	ldrb r1, [r0, #0xe]                 @ 080209CC
	lsls r1, r1, #0x1c                  @ 080209CE
	lsrs r1, r1, #0x1c                  @ 080209D0
	strb r1, [r2, #2]                   @ 080209D2
	ldrb r1, [r0, #0xa]                 @ 080209D4
	lsrs r1, r1, #2                     @ 080209D6
	lsls r1, r1, #2                     @ 080209D8
	adds r1, #2                         @ 080209DA
	strb r1, [r0, #0xa]                 @ 080209DC
	pop {r4, pc}                        @ 080209DE
	.thumb_func
	.global Fx_Empty6
Fx_Empty6:
	bx lr                               @ 080209E0
	.thumb_func
	.global Fx_Empty7
Fx_Empty7:
	bx lr                               @ 080209E2

@ --------------------------------------------------------------------------------------------
@ tick handler: after the delay runs out, trigger the row's note (Fx_None).
	.thumb_func
	.global Tick_NoteDelay
Tick_NoteDelay:
	adds r1, r0, #0                     @ 080209E4
	adds r1, #0x50                      @ 080209E6
	push {lr}                           @ 080209E8
	ldrb r2, [r1, #2]                   @ 080209EA
	adds r2, #0xff                      @ 080209EC
	lsls r2, r2, #0x18                  @ 080209EE
	lsrs r2, r2, #0x18                  @ 080209F0
	strb r2, [r1, #2]                   @ 080209F2
	bne L_080209FA                      @ 080209F4
	bl Fx_None                          @ 080209F6
L_080209FA:
	pop {pc}                            @ 080209FA

@ --------------------------------------------------------------------------------------------
@ effect 27: note delay - play the row's note after xx ticks (the converter's SDx).
	.thumb_func
	.global Fx_NoteDelay
Fx_NoteDelay:
	adds r1, r0, #0                     @ 080209FC
	adds r1, #0x50                      @ 080209FE
	ldrb r2, [r1, #0xe]                 @ 08020A00
	strb r2, [r1, #2]                   @ 08020A02
	ldr r1, L_08020B90                  @ 08020A04 =0x080209E5
	str r1, [r0, #0x54]                 @ 08020A06
	adds r0, #0x40                      @ 08020A08
	ldrb r1, [r0, #0xa]                 @ 08020A0A
	lsrs r1, r1, #2                     @ 08020A0C
	lsls r1, r1, #2                     @ 08020A0E
	adds r1, #2                         @ 08020A10
	strb r1, [r0, #0xa]                 @ 08020A12
	bx lr                               @ 08020A14

@ --------------------------------------------------------------------------------------------
@ void Player_SetTempo(Player *p, int bpm): samples per tick = 40000 / bpm (16 kHz * 2.5).
	.thumb_func
	.global Player_SetTempo
Player_SetTempo:
	push {r4, lr}                       @ 08020A16
	adds r4, r0, #0                     @ 08020A18
	strb r1, [r4, #4]                   @ 08020A1A
	adds r0, r1, #0                     @ 08020A1C
	ldr r1, L_08020B94                  @ 08020A1E =0x00009C40
	bl __rt_udiv                        @ 08020A20
	strh r0, [r4, #6]                   @ 08020A24
	pop {r4, pc}                        @ 08020A26

@ --------------------------------------------------------------------------------------------
@ Txx: tempo xx BPM (samples per tick = 40000/xx).
	.thumb_func
	.global Fx_T_SetTempo
Fx_T_SetTempo:
	push {r3, r4, r5, lr}               @ 08020A28
	adds r5, r0, #0                     @ 08020A2A
	bl Fx_None                          @ 08020A2C
	ldr r0, L_08020B7C                  @ 08020A30 =0x087D61AC
	ldr r1, L_08020B94                  @ 08020A32 =0x00009C40
	subs r0, #4                         @ 08020A34
	ldr r4, [r0]                        @ 08020A36
	adds r5, #0x50                      @ 08020A38
	ldrb r0, [r5, #0xe]                 @ 08020A3A
	strb r0, [r4, #4]                   @ 08020A3C
	bl __rt_udiv                        @ 08020A3E
	strh r0, [r4, #6]                   @ 08020A42
	pop {r3, r4, r5, pc}                @ 08020A44

@ --------------------------------------------------------------------------------------------
@ Uxy fine vibrato: like H but depth y (4x finer).
	.thumb_func
	.global Fx_U_FineVibrato
Fx_U_FineVibrato:
	push {r4, lr}                       @ 08020A46
	adds r4, r0, #0                     @ 08020A48
	bl Fx_None                          @ 08020A4A
	adds r0, r4, #0                     @ 08020A4E
	adds r0, #0x50                      @ 08020A50
	ldrb r1, [r0, #8]                   @ 08020A52
	movs r2, #0x11                      @ 08020A54
	ands r1, r2                         @ 08020A56
	beq L_08020A5E                      @ 08020A58
	movs r1, #0                         @ 08020A5A
	strb r1, [r0, #1]                   @ 08020A5C
L_08020A5E:
	ldrb r1, [r0, #0xe]                 @ 08020A5E
	lsls r2, r1, #0x1c                  @ 08020A60
	beq L_08020A6A                      @ 08020A62
	lsls r2, r1, #0x1c                  @ 08020A64
	lsrs r2, r2, #0x1c                  @ 08020A66
	strb r2, [r0]                       @ 08020A68
L_08020A6A:
	lsls r0, r1, #0x18                  @ 08020A6A
	lsrs r2, r0, #0x1c                  @ 08020A6C
	adds r0, r4, #0                     @ 08020A6E
	adds r0, #0x40                      @ 08020A70
	cmp r2, #0                          @ 08020A72
	beq L_08020A7A                      @ 08020A74
	lsrs r1, r1, #4                     @ 08020A76
	strb r1, [r0, #0xf]                 @ 08020A78
L_08020A7A:
	ldr r1, L_08020B98                  @ 08020A7A =0x080206A9
	movs r2, #1                         @ 08020A7C
	str r1, [r4, #0x54]                 @ 08020A7E
	ldrb r1, [r0, #0xa]                 @ 08020A80
	orrs r1, r2                         @ 08020A82
	strb r1, [r0, #0xa]                 @ 08020A84
	adds r0, r4, #0                     @ 08020A86
	bl Tick_Vibrato                     @ 08020A88
	pop {r4, pc}                        @ 08020A8C
	.thumb_func
	.global Fx_Empty8
Fx_Empty8:
	bx lr                               @ 08020A8E
	.thumb_func
	.global Fx_Empty9
Fx_Empty9:
	bx lr                               @ 08020A90

@ --------------------------------------------------------------------------------------------
@ Xxx: panning, signed -64 (left) .. +64 (right).
	.thumb_func
	.global Fx_X_SetPanning
Fx_X_SetPanning:
	push {r4, lr}                       @ 08020A92
	adds r4, r0, #0                     @ 08020A94
	bl Fx_None                          @ 08020A96
	movs r0, #0x5e                      @ 08020A9A
	ldrb r0, [r0, r4]                   @ 08020A9C
	movs r1, #0x49                      @ 08020A9E
	strb r0, [r1, r4]                   @ 08020AA0
	strb r0, [r4, #0x13]                @ 08020AA2
	ldrb r0, [r4, #0x10]                @ 08020AA4
	movs r1, #0x10                      @ 08020AA6
	orrs r0, r1                         @ 08020AA8
	strb r0, [r4, #0x10]                @ 08020AAA
	pop {r4, pc}                        @ 08020AAC
	.thumb_func
	.global Fx_Empty10
Fx_Empty10:
	bx lr                               @ 08020AAE
	.thumb_func
	.global Fx_Empty11
Fx_Empty11:
	bx lr                               @ 08020AB0

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento up + volume up. NOTE: when the volume reaches 64 it switches to
@ Tick_TonePortaDown (not ...Up), which snaps the pitch straight to the target.
	.thumb_func
	.global Tick_TonePortaUpVolUp
Tick_TonePortaUpVolUp:
	adds r1, r0, #0                     @ 08020AB2
	adds r1, #0x40                      @ 08020AB4
	push {r4, r5, lr}                   @ 08020AB6
	ldrb r2, [r1, #0xd]                 @ 08020AB8
	ldr r4, L_08020B9C                  @ 08020ABA =0x087D648C
	ldr r3, [r0, #0x40]                 @ 08020ABC
	lsls r2, r2, #1                     @ 08020ABE
	ldrh r2, [r4, r2]                   @ 08020AC0
	movs r5, #2                         @ 08020AC2
	muls r3, r2, r3                     @ 08020AC4
	lsrs r4, r3, #0xe                   @ 08020AC6
	str r4, [r0, #0x40]                 @ 08020AC8
	str r4, [r0, #0x30]                 @ 08020ACA
	ldrb r2, [r0, #0x10]                @ 08020ACC
	orrs r2, r5                         @ 08020ACE
	strb r2, [r0, #0x10]                @ 08020AD0
	ldr r3, [r0, #0x44]                 @ 08020AD2
	cmp r4, r3                          @ 08020AD4
	bhs L_08020AF2                      @ 08020AD6
	str r3, [r0, #0x40]                 @ 08020AD8
	str r3, [r0, #0x30]                 @ 08020ADA
	orrs r2, r5                         @ 08020ADC
	strb r2, [r0, #0x10]                @ 08020ADE
	ldrb r2, [r1, #0xa]                 @ 08020AE0
	movs r3, #8                         @ 08020AE2
	bics r2, r3                         @ 08020AE4
	strb r2, [r1, #0xa]                 @ 08020AE6
	ldr r1, L_08020B88                  @ 08020AE8 =0x080203C7
	str r1, [r0, #0x54]                 @ 08020AEA
	bl Tick_VolSlideUp                  @ 08020AEC
	pop {r4, r5, pc}                    @ 08020AF0
L_08020AF2:
	ldrb r3, [r1, #8]                   @ 08020AF2
	ldrb r4, [r1, #0xb]                 @ 08020AF4
	adds r3, r3, r4                     @ 08020AF6
	lsls r3, r3, #0x18                  @ 08020AF8
	asrs r3, r3, #0x18                  @ 08020AFA
	strb r3, [r1, #8]                   @ 08020AFC
	cmp r3, #0x40                       @ 08020AFE
	blt L_08020B0A                      @ 08020B00
	movs r3, #0x40                      @ 08020B02
	strb r3, [r1, #8]                   @ 08020B04
	ldr r3, L_08020BA0                  @ 08020B06 =0x080205B1
	str r3, [r0, #0x54]                 @ 08020B08
L_08020B0A:
	ldrb r1, [r1, #8]                   @ 08020B0A
	strb r1, [r0, #0x12]                @ 08020B0C
	movs r1, #0x10                      @ 08020B0E
	orrs r1, r2                         @ 08020B10
	strb r1, [r0, #0x10]                @ 08020B12
	pop {r4, r5, pc}                    @ 08020B14

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento down + volume up.
	.thumb_func
	.global Tick_TonePortaDownVolUp
Tick_TonePortaDownVolUp:
	adds r1, r0, #0                     @ 08020B16
	adds r1, #0x40                      @ 08020B18
	push {r4, r5, lr}                   @ 08020B1A
	ldrb r2, [r1, #0xd]                 @ 08020B1C
	ldr r4, L_08020BA4                  @ 08020B1E =0x087D670C
	ldr r3, [r0, #0x40]                 @ 08020B20
	lsls r2, r2, #1                     @ 08020B22
	ldrh r2, [r4, r2]                   @ 08020B24
	movs r5, #2                         @ 08020B26
	muls r3, r2, r3                     @ 08020B28
	lsrs r4, r3, #0x10                  @ 08020B2A
	str r4, [r0, #0x40]                 @ 08020B2C
	str r4, [r0, #0x30]                 @ 08020B2E
	ldrb r2, [r0, #0x10]                @ 08020B30
	orrs r2, r5                         @ 08020B32
	strb r2, [r0, #0x10]                @ 08020B34
	ldr r3, [r0, #0x44]                 @ 08020B36
	cmp r4, r3                          @ 08020B38
	bhs L_08020B56                      @ 08020B3A
	str r3, [r0, #0x40]                 @ 08020B3C
	str r3, [r0, #0x30]                 @ 08020B3E
	orrs r2, r5                         @ 08020B40
	strb r2, [r0, #0x10]                @ 08020B42
	ldrb r2, [r1, #0xa]                 @ 08020B44
	movs r3, #8                         @ 08020B46
	bics r2, r3                         @ 08020B48
	strb r2, [r1, #0xa]                 @ 08020B4A
	ldr r1, L_08020B88                  @ 08020B4C =0x080203C7
	str r1, [r0, #0x54]                 @ 08020B4E
	bl Tick_VolSlideUp                  @ 08020B50
	pop {r4, r5, pc}                    @ 08020B54
L_08020B56:
	ldrb r3, [r1, #8]                   @ 08020B56
	ldrb r4, [r1, #0xb]                 @ 08020B58
	adds r3, r3, r4                     @ 08020B5A
	lsls r3, r3, #0x18                  @ 08020B5C
	asrs r3, r3, #0x18                  @ 08020B5E
	strb r3, [r1, #8]                   @ 08020B60
	cmp r3, #0x40                       @ 08020B62
	blt L_08020B6E                      @ 08020B64
	movs r3, #0x40                      @ 08020B66
	strb r3, [r1, #8]                   @ 08020B68
	ldr r3, L_08020BA0                  @ 08020B6A =0x080205B1
	str r3, [r0, #0x54]                 @ 08020B6C
L_08020B6E:
	ldrb r1, [r1, #8]                   @ 08020B6E
	strb r1, [r0, #0x12]                @ 08020B70
	movs r1, #0x10                      @ 08020B72
	orrs r1, r2                         @ 08020B74
	strb r1, [r0, #0x10]                @ 08020B76
	pop {r4, r5, pc}                    @ 08020B78
	movs r0, r0                         @ 08020B7A
L_08020B7C:
	.word NoteFreqTab	@ 0x087D61AC
L_08020B80:
	.word Tick_VolSlideDown	@ 0x08020399
L_08020B84:
	.word TonePortaVolTicks	@ 0x087D694C
L_08020B88:
	.word Tick_VolSlideUp	@ 0x080203C7
L_08020B8C:
	.word Tick_Retrig	@ 0x08020985
L_08020B90:
	.word Tick_NoteDelay	@ 0x080209E5
L_08020B94:
	.word TEMPO_K	@ 0x00009C40
L_08020B98:
	.word Tick_Vibrato	@ 0x080206A9
L_08020B9C:
	.word PortaUpTab	@ 0x087D648C
L_08020BA0:
	.word Tick_TonePortaDown	@ 0x080205B1
L_08020BA4:
	.word PortaDownTab	@ 0x087D670C

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento up + volume down. Same slip as above when the volume reaches 0.
	.thumb_func
	.global Tick_TonePortaUpVolDown
Tick_TonePortaUpVolDown:
	adds r1, r0, #0                     @ 08020BA8
	adds r1, #0x40                      @ 08020BAA
	push {r4, r5, lr}                   @ 08020BAC
	ldrb r2, [r1, #0xd]                 @ 08020BAE
	ldr r4, L_08020E30                  @ 08020BB0 =0x087D648C
	ldr r3, [r0, #0x40]                 @ 08020BB2
	lsls r2, r2, #1                     @ 08020BB4
	ldrh r2, [r4, r2]                   @ 08020BB6
	movs r5, #2                         @ 08020BB8
	muls r3, r2, r3                     @ 08020BBA
	lsrs r4, r3, #0xe                   @ 08020BBC
	str r4, [r0, #0x40]                 @ 08020BBE
	str r4, [r0, #0x30]                 @ 08020BC0
	ldrb r2, [r0, #0x10]                @ 08020BC2
	orrs r2, r5                         @ 08020BC4
	strb r2, [r0, #0x10]                @ 08020BC6
	ldr r3, [r0, #0x44]                 @ 08020BC8
	cmp r4, r3                          @ 08020BCA
	bls L_08020BE8                      @ 08020BCC
	str r3, [r0, #0x40]                 @ 08020BCE
	str r3, [r0, #0x30]                 @ 08020BD0
	orrs r2, r5                         @ 08020BD2
	strb r2, [r0, #0x10]                @ 08020BD4
	ldrb r2, [r1, #0xa]                 @ 08020BD6
	movs r3, #8                         @ 08020BD8
	bics r2, r3                         @ 08020BDA
	strb r2, [r1, #0xa]                 @ 08020BDC
	ldr r1, L_08020E34                  @ 08020BDE =0x08020399
	str r1, [r0, #0x54]                 @ 08020BE0
	bl Tick_VolSlideDown                @ 08020BE2
	pop {r4, r5, pc}                    @ 08020BE6
L_08020BE8:
	ldrb r3, [r1, #8]                   @ 08020BE8
	ldrb r4, [r1, #0xb]                 @ 08020BEA
	subs r3, r3, r4                     @ 08020BEC
	lsls r3, r3, #0x18                  @ 08020BEE
	asrs r3, r3, #0x18                  @ 08020BF0
	strb r3, [r1, #8]                   @ 08020BF2
	cmp r3, #0                          @ 08020BF4
	bgt L_08020C00                      @ 08020BF6
	movs r3, #0                         @ 08020BF8
	strb r3, [r1, #8]                   @ 08020BFA
	ldr r3, L_08020E38                  @ 08020BFC =0x080205B1
	str r3, [r0, #0x54]                 @ 08020BFE
L_08020C00:
	ldrb r1, [r1, #8]                   @ 08020C00
	strb r1, [r0, #0x12]                @ 08020C02
	movs r1, #0x10                      @ 08020C04
	orrs r1, r2                         @ 08020C06
	strb r1, [r0, #0x10]                @ 08020C08
	pop {r4, r5, pc}                    @ 08020C0A

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento down + volume down.
	.thumb_func
	.global Tick_TonePortaDownVolDown
Tick_TonePortaDownVolDown:
	adds r1, r0, #0                     @ 08020C0C
	adds r1, #0x40                      @ 08020C0E
	push {r4, r5, lr}                   @ 08020C10
	ldrb r2, [r1, #0xd]                 @ 08020C12
	ldr r4, L_08020E3C                  @ 08020C14 =0x087D670C
	ldr r3, [r0, #0x40]                 @ 08020C16
	lsls r2, r2, #1                     @ 08020C18
	ldrh r2, [r4, r2]                   @ 08020C1A
	movs r5, #2                         @ 08020C1C
	muls r3, r2, r3                     @ 08020C1E
	lsrs r4, r3, #0x10                  @ 08020C20
	str r4, [r0, #0x40]                 @ 08020C22
	str r4, [r0, #0x30]                 @ 08020C24
	ldrb r2, [r0, #0x10]                @ 08020C26
	orrs r2, r5                         @ 08020C28
	strb r2, [r0, #0x10]                @ 08020C2A
	ldr r3, [r0, #0x44]                 @ 08020C2C
	cmp r4, r3                          @ 08020C2E
	bhs L_08020C4C                      @ 08020C30
	str r3, [r0, #0x40]                 @ 08020C32
	str r3, [r0, #0x30]                 @ 08020C34
	orrs r2, r5                         @ 08020C36
	strb r2, [r0, #0x10]                @ 08020C38
	ldrb r2, [r1, #0xa]                 @ 08020C3A
	movs r3, #8                         @ 08020C3C
	bics r2, r3                         @ 08020C3E
	strb r2, [r1, #0xa]                 @ 08020C40
	ldr r1, L_08020E34                  @ 08020C42 =0x08020399
	str r1, [r0, #0x54]                 @ 08020C44
	bl Tick_VolSlideDown                @ 08020C46
	pop {r4, r5, pc}                    @ 08020C4A
L_08020C4C:
	ldrb r3, [r1, #8]                   @ 08020C4C
	ldrb r4, [r1, #0xb]                 @ 08020C4E
	subs r3, r3, r4                     @ 08020C50
	lsls r3, r3, #0x18                  @ 08020C52
	asrs r3, r3, #0x18                  @ 08020C54
	strb r3, [r1, #8]                   @ 08020C56
	cmp r3, #0                          @ 08020C58
	bgt L_08020C64                      @ 08020C5A
	movs r3, #0                         @ 08020C5C
	strb r3, [r1, #8]                   @ 08020C5E
	ldr r3, L_08020E38                  @ 08020C60 =0x080205B1
	str r3, [r0, #0x54]                 @ 08020C62
L_08020C64:
	ldrb r1, [r1, #8]                   @ 08020C64
	strb r1, [r0, #0x12]                @ 08020C66
	movs r1, #0x10                      @ 08020C68
	orrs r1, r2                         @ 08020C6A
	strb r1, [r0, #0x10]                @ 08020C6C
	pop {r4, r5, pc}                    @ 08020C6E

@ --------------------------------------------------------------------------------------------
@ per-row work of one channel: clear the tick mode, restore the voice pitch after vibrato,
@ then call FxTab[effect] (effect 0 when the row has no effect byte, nothing if the channel is absent).
	.thumb_func
	.global Player_ChannelRow
Player_ChannelRow:
	adds r1, r0, #0                     @ 08020C70
	adds r1, #0x40                      @ 08020C72
	push {r3, lr}                       @ 08020C74
	ldrb r2, [r1, #0xa]                 @ 08020C76
	lsrs r2, r2, #2                     @ 08020C78
	lsls r2, r2, #2                     @ 08020C7A
	strb r2, [r1, #0xa]                 @ 08020C7C
	lsls r1, r2, #0x1d                  @ 08020C7E
	bpl L_08020C94                      @ 08020C80
	ldr r1, [r0, #0x40]                 @ 08020C82
	ldr r2, [r0, #0x30]                 @ 08020C84
	cmp r2, r1                          @ 08020C86
	beq L_08020C94                      @ 08020C88
	str r1, [r0, #0x30]                 @ 08020C8A
	ldrb r1, [r0, #0x10]                @ 08020C8C
	movs r2, #2                         @ 08020C8E
	orrs r1, r2                         @ 08020C90
	strb r1, [r0, #0x10]                @ 08020C92
L_08020C94:
	adds r1, r0, #0                     @ 08020C94
	adds r1, #0x50                      @ 08020C96
	ldrb r2, [r1, #8]                   @ 08020C98
	cmp r2, #0                          @ 08020C9A
	beq L_08020CB2                      @ 08020C9C
	movs r3, #0x88                      @ 08020C9E
	ands r2, r3                         @ 08020CA0
	ldrb r1, [r1, #0xd]                 @ 08020CA2
	bne L_08020CA8                      @ 08020CA4
	movs r1, #0                         @ 08020CA6
L_08020CA8:
	ldr r2, L_08020E40                  @ 08020CA8 =0x087D638C
	lsls r1, r1, #2                     @ 08020CAA
	ldr r1, [r2, r1]                    @ 08020CAC
	bl __call_via_r1                    @ 08020CAE
L_08020CB2:
	pop {r3, pc}                        @ 08020CB2

@ --------------------------------------------------------------------------------------------
@ per-tick work of one channel: call its tick handler in tick mode 1 (only while the note
@ sounds) or 2 (always).
	.thumb_func
	.global Player_ChannelTick
Player_ChannelTick:
	push {r3, lr}                       @ 08020CB4
	movs r1, #0x4a                      @ 08020CB6
	ldrb r2, [r1, r0]                   @ 08020CB8
	lsls r1, r2, #0x1e                  @ 08020CBA
	lsrs r1, r1, #0x1e                  @ 08020CBC
	beq L_08020CCE                      @ 08020CBE
	cmp r1, #1                          @ 08020CC0
	bne L_08020CC8                      @ 08020CC2
	lsls r1, r2, #0x1d                  @ 08020CC4
	bpl L_08020CCE                      @ 08020CC6
L_08020CC8:
	ldr r1, [r0, #0x54]                 @ 08020CC8
	bl __call_via_r1                    @ 08020CCA
L_08020CCE:
	pop {r3, pc}                        @ 08020CCE

@ --------------------------------------------------------------------------------------------
@ Advance one row: at the end of a pattern step the order list (0xFF wraps to order 0) and
@ fetch the pattern's row count. Clear all channel masks, then decode the packed row:
@   ctrl byte (0 ends the row): low nibble = channel+1, high nibble 0 = mask byte follows,
@   1 = reuse the channel's last mask, 2..15 = song->masks[n-2];
@   mask bits 1/2/4/8 read note/instrument/volume/effect+param, bits 0x10/0x20/0x40/0x80 mark
@   the same fields as present but repeated from the channel's previous values.
	.thumb_func
	.global Player_ReadRow
Player_ReadRow:
	push {r4}                           @ 08020CD0
	ldrb r1, [r0, #1]                   @ 08020CD2
	movs r2, #0                         @ 08020CD4
	adds r1, #1                         @ 08020CD6
	lsls r1, r1, #0x18                  @ 08020CD8
	lsrs r1, r1, #0x18                  @ 08020CDA
	strb r1, [r0, #1]                   @ 08020CDC
	ldrb r3, [r0, #2]                   @ 08020CDE
	cmp r1, r3                          @ 08020CE0
	blo L_08020D0C                      @ 08020CE2
	ldr r3, [r0, #0x10]                 @ 08020CE4
	adds r3, #1                         @ 08020CE6
	str r3, [r0, #0x10]                 @ 08020CE8
	ldr r1, [r0, #0xc]                  @ 08020CEA
	ldr r4, [r1, #4]                    @ 08020CEC
	ldrb r3, [r4, r3]                   @ 08020CEE
	cmp r3, #0xff                       @ 08020CF0
	bne L_08020CF6                      @ 08020CF2
	str r2, [r0, #0x10]                 @ 08020CF4
L_08020CF6:
	ldr r3, [r1, #4]                    @ 08020CF6
	ldr r4, [r0, #0x10]                 @ 08020CF8
	ldr r1, [r1]                        @ 08020CFA
	ldrb r3, [r3, r4]                   @ 08020CFC
	lsls r3, r3, #2                     @ 08020CFE
	ldr r1, [r1, r3]                    @ 08020D00
	strb r2, [r0, #1]                   @ 08020D02
	adds r3, r1, #1                     @ 08020D04
	str r3, [r0, #0x14]                 @ 08020D06
	ldrb r1, [r1]                       @ 08020D08
	strb r1, [r0, #2]                   @ 08020D0A
L_08020D0C:
	movs r1, #0                         @ 08020D0C
L_08020D0E:
	lsls r3, r1, #1                     @ 08020D0E
	adds r3, r3, r1                     @ 08020D10
	lsls r3, r3, #5                     @ 08020D12
	adds r3, r3, r0                     @ 08020D14
	adds r3, #0x70                      @ 08020D16
	adds r1, #1                         @ 08020D18
	cmp r1, #0xf                        @ 08020D1A
	strb r2, [r3]                       @ 08020D1C
	blt L_08020D0E                      @ 08020D1E
L_08020D20:
	ldr r1, [r0, #0x14]                 @ 08020D20
	adds r2, r1, #1                     @ 08020D22
	str r2, [r0, #0x14]                 @ 08020D24
	ldrb r1, [r1]                       @ 08020D26
	cmp r1, #0                          @ 08020D28
	beq L_08020DB8                      @ 08020D2A
	lsls r3, r1, #0x1c                  @ 08020D2C
	lsrs r3, r3, #0x1c                  @ 08020D2E
	subs r4, r3, #1                     @ 08020D30
	lsls r3, r4, #1                     @ 08020D32
	adds r3, r3, r4                     @ 08020D34
	lsls r3, r3, #5                     @ 08020D36
	adds r3, r3, r0                     @ 08020D38
	adds r3, #0x18                      @ 08020D3A
	lsrs r1, r1, #4                     @ 08020D3C
	cmp r1, #0                          @ 08020D3E
	bne L_08020D52                      @ 08020D40
	adds r1, r2, #1                     @ 08020D42
	str r1, [r0, #0x14]                 @ 08020D44
	ldrb r2, [r2]                       @ 08020D46
	adds r1, r3, #0                     @ 08020D48
	adds r1, #0x50                      @ 08020D4A
	strb r2, [r1, #9]                   @ 08020D4C
	strb r2, [r1, #8]                   @ 08020D4E
	b L_08020D6E                        @ 08020D50
L_08020D52:
	cmp r1, #1                          @ 08020D52
	bne L_08020D60                      @ 08020D54
	adds r1, r3, #0                     @ 08020D56
	adds r1, #0x50                      @ 08020D58
	ldrb r2, [r1, #9]                   @ 08020D5A
	strb r2, [r1, #8]                   @ 08020D5C
	b L_08020D6E                        @ 08020D5E
L_08020D60:
	ldr r2, [r0, #0xc]                  @ 08020D60
	ldr r2, [r2, #0xc]                  @ 08020D62
	adds r1, r2, r1                     @ 08020D64
	subs r1, #0x10                      @ 08020D66
	ldrb r1, [r1, #0xe]                 @ 08020D68
	movs r2, #0x58                      @ 08020D6A
	strb r1, [r2, r3]                   @ 08020D6C
L_08020D6E:
	adds r1, r3, #0                     @ 08020D6E
	adds r1, #0x50                      @ 08020D70
	ldrb r2, [r1, #8]                   @ 08020D72
	lsls r3, r2, #0x1f                  @ 08020D74
	bpl L_08020D82                      @ 08020D76
	ldr r3, [r0, #0x14]                 @ 08020D78
	adds r4, r3, #1                     @ 08020D7A
	str r4, [r0, #0x14]                 @ 08020D7C
	ldrb r3, [r3]                       @ 08020D7E
	strb r3, [r1, #0xa]                 @ 08020D80
L_08020D82:
	lsls r3, r2, #0x1e                  @ 08020D82
	bpl L_08020D90                      @ 08020D84
	ldr r3, [r0, #0x14]                 @ 08020D86
	adds r4, r3, #1                     @ 08020D88
	str r4, [r0, #0x14]                 @ 08020D8A
	ldrb r3, [r3]                       @ 08020D8C
	strb r3, [r1, #0xb]                 @ 08020D8E
L_08020D90:
	lsls r3, r2, #0x1d                  @ 08020D90
	bpl L_08020D9E                      @ 08020D92
	ldr r3, [r0, #0x14]                 @ 08020D94
	adds r4, r3, #1                     @ 08020D96
	str r4, [r0, #0x14]                 @ 08020D98
	ldrb r3, [r3]                       @ 08020D9A
	strb r3, [r1, #0xc]                 @ 08020D9C
L_08020D9E:
	lsls r2, r2, #0x1c                  @ 08020D9E
	bpl L_08020D20                      @ 08020DA0
	ldr r2, [r0, #0x14]                 @ 08020DA2
	adds r3, r2, #1                     @ 08020DA4
	str r3, [r0, #0x14]                 @ 08020DA6
	ldrb r2, [r2]                       @ 08020DA8
	strb r2, [r1, #0xd]                 @ 08020DAA
	ldr r2, [r0, #0x14]                 @ 08020DAC
	adds r3, r2, #1                     @ 08020DAE
	str r3, [r0, #0x14]                 @ 08020DB0
	ldrb r2, [r2]                       @ 08020DB2
	strb r2, [r1, #0xe]                 @ 08020DB4
	b L_08020D20                        @ 08020DB6
L_08020DB8:
	pop {r4}                            @ 08020DB8
	bx lr                               @ 08020DBA

@ --------------------------------------------------------------------------------------------
@ One player tick: on the first tick of a row read the row and run every channel's row effect,
@ otherwise run the tick handlers; then update all 15 music voices.
	.thumb_func
	.global Player_Tick
Player_Tick:
	push {r3, r4, r5, lr}               @ 08020DBC
	adds r4, r0, #0                     @ 08020DBE
	ldrb r0, [r0]                       @ 08020DC0
	adds r0, #0xff                      @ 08020DC2
	lsls r0, r0, #0x18                  @ 08020DC4
	lsrs r0, r0, #0x18                  @ 08020DC6
	strb r0, [r4]                       @ 08020DC8
	bne L_08020DEE                      @ 08020DCA
	adds r0, r4, #0                     @ 08020DCC
	bl Player_ReadRow                   @ 08020DCE
	movs r5, #0                         @ 08020DD2
L_08020DD4:
	lsls r0, r5, #1                     @ 08020DD4
	adds r0, r0, r5                     @ 08020DD6
	lsls r0, r0, #5                     @ 08020DD8
	adds r0, r0, r4                     @ 08020DDA
	adds r0, #0x18                      @ 08020DDC
	bl Player_ChannelRow                @ 08020DDE
	adds r5, #1                         @ 08020DE2
	cmp r5, #0xf                        @ 08020DE4
	blt L_08020DD4                      @ 08020DE6
	ldrb r0, [r4, #3]                   @ 08020DE8
	strb r0, [r4]                       @ 08020DEA
	b L_08020E18                        @ 08020DEC
L_08020DEE:
	movs r5, #0                         @ 08020DEE
L_08020DF0:
	lsls r0, r5, #1                     @ 08020DF0
	adds r0, r0, r5                     @ 08020DF2
	lsls r0, r0, #5                     @ 08020DF4
	adds r0, r0, r4                     @ 08020DF6
	adds r0, #0x18                      @ 08020DF8
	movs r1, #0x4a                      @ 08020DFA
	ldrb r2, [r1, r0]                   @ 08020DFC
	lsls r1, r2, #0x1e                  @ 08020DFE
	lsrs r1, r1, #0x1e                  @ 08020E00
	beq L_08020E12                      @ 08020E02
	cmp r1, #1                          @ 08020E04
	bne L_08020E0C                      @ 08020E06
	lsls r1, r2, #0x1d                  @ 08020E08
	bpl L_08020E12                      @ 08020E0A
L_08020E0C:
	ldr r1, [r0, #0x54]                 @ 08020E0C
	bl __call_via_r1                    @ 08020E0E
L_08020E12:
	adds r5, #1                         @ 08020E12
	cmp r5, #0xf                        @ 08020E14
	blt L_08020DF0                      @ 08020E16
L_08020E18:
	movs r5, #0                         @ 08020E18
L_08020E1A:
	lsls r0, r5, #1                     @ 08020E1A
	adds r0, r0, r5                     @ 08020E1C
	lsls r0, r0, #5                     @ 08020E1E
	adds r0, r0, r4                     @ 08020E20
	adds r0, #0x18                      @ 08020E22
	bl Voice_Update                     @ 08020E24
	adds r5, #1                         @ 08020E28
	cmp r5, #0xf                        @ 08020E2A
	blt L_08020E1A                      @ 08020E2C
	pop {r3, r4, r5, pc}                @ 08020E2E
L_08020E30:
	.word PortaUpTab	@ 0x087D648C
L_08020E34:
	.word Tick_VolSlideDown	@ 0x08020399
L_08020E38:
	.word Tick_TonePortaDown	@ 0x080205B1
L_08020E3C:
	.word PortaDownTab	@ 0x087D670C
L_08020E40:
	.word FxTab	@ 0x087D638C

@ --------------------------------------------------------------------------------------------
@ void Player_MixVoices(Player *p, u32 *buf, int n): mix the 15 channel voices.
	.thumb_func
	.global Player_MixVoices
Player_MixVoices:
	push {r3, r4, r5, r6, r7, lr}       @ 08020E44
	adds r6, r1, #0                     @ 08020E46
	adds r5, r0, #0                     @ 08020E48
	adds r7, r2, #0                     @ 08020E4A
	movs r4, #0                         @ 08020E4C
L_08020E4E:
	lsls r0, r4, #1                     @ 08020E4E
	adds r0, r0, r4                     @ 08020E50
	lsls r0, r0, #5                     @ 08020E52
	adds r0, r0, r5                     @ 08020E54
	adds r0, #0x18                      @ 08020E56
	adds r2, r7, #0                     @ 08020E58
	adds r1, r6, #0                     @ 08020E5A
	bl Voice_Mix                        @ 08020E5C
	adds r4, #1                         @ 08020E60
	cmp r4, #0xf                        @ 08020E62
	blt L_08020E4E                      @ 08020E64
	pop {r3, r4, r5, r6, r7, pc}        @ 08020E66

@ --------------------------------------------------------------------------------------------
@ void Player_Render(Player *p, u32 *buf, int n): mix n samples of music, running ticks with
@ sample accuracy (see Mus_Render in version 1).
	.thumb_func
	.global Player_Render
Player_Render:
	push {r3, r4, r5, r6, r7, lr}       @ 08020E68
	adds r4, r0, #0                     @ 08020E6A
	ldrb r0, [r0, #5]                   @ 08020E6C
	adds r7, r2, #0                     @ 08020E6E
	adds r6, r1, #0                     @ 08020E70
	cmp r0, #1                          @ 08020E72
	bne L_08020E9C                      @ 08020E74
L_08020E76:
	ldrh r0, [r4, #8]                   @ 08020E76
	cmp r0, r7                          @ 08020E78
	blt L_08020E9E                      @ 08020E7A
	movs r5, #0                         @ 08020E7C
L_08020E7E:
	lsls r0, r5, #1                     @ 08020E7E
	adds r0, r0, r5                     @ 08020E80
	lsls r0, r0, #5                     @ 08020E82
	adds r0, r0, r4                     @ 08020E84
	adds r0, #0x18                      @ 08020E86
	adds r2, r7, #0                     @ 08020E88
	adds r1, r6, #0                     @ 08020E8A
	bl Voice_Mix                        @ 08020E8C
	adds r5, #1                         @ 08020E90
	cmp r5, #0xf                        @ 08020E92
	blt L_08020E7E                      @ 08020E94
	ldrh r0, [r4, #8]                   @ 08020E96
	subs r0, r0, r7                     @ 08020E98
	strh r0, [r4, #8]                   @ 08020E9A
L_08020E9C:
	pop {r3, r4, r5, r6, r7, pc}        @ 08020E9C
L_08020E9E:
	cmp r0, #0                          @ 08020E9E
	beq L_08020EC6                      @ 08020EA0
	str r0, [sp]                        @ 08020EA2
	movs r5, #0                         @ 08020EA4
L_08020EA6:
	lsls r0, r5, #1                     @ 08020EA6
	adds r0, r0, r5                     @ 08020EA8
	lsls r0, r0, #5                     @ 08020EAA
	adds r0, r0, r4                     @ 08020EAC
	adds r0, #0x18                      @ 08020EAE
	adds r1, r6, #0                     @ 08020EB0
	ldr r2, [sp]                        @ 08020EB2
	bl Voice_Mix                        @ 08020EB4
	adds r5, #1                         @ 08020EB8
	cmp r5, #0xf                        @ 08020EBA
	blt L_08020EA6                      @ 08020EBC
	ldrh r0, [r4, #8]                   @ 08020EBE
	lsls r1, r0, #2                     @ 08020EC0
	adds r6, r1, r6                     @ 08020EC2
	subs r7, r7, r0                     @ 08020EC4
L_08020EC6:
	adds r0, r4, #0                     @ 08020EC6
	bl Player_Tick                      @ 08020EC8
	ldrh r0, [r4, #6]                   @ 08020ECC
	strh r0, [r4, #8]                   @ 08020ECE
	b L_08020E76                        @ 08020ED0

@ --------------------------------------------------------------------------------------------
@ Clear the 15 channels and their voices and re-link channel <-> voice.
	.thumb_func
	.global Player_ResetChannels
Player_ResetChannels:
	movs r1, #0                         @ 08020ED2
	movs r2, #0                         @ 08020ED4
	push {r4}                           @ 08020ED6
L_08020ED8:
	lsls r3, r1, #1                     @ 08020ED8
	adds r3, r3, r1                     @ 08020EDA
	lsls r3, r3, #5                     @ 08020EDC
	adds r3, r3, r0                     @ 08020EDE
	adds r3, #0x18                      @ 08020EE0
	movs r4, #0x4a                      @ 08020EE2
	strb r2, [r4, r3]                   @ 08020EE4
	adds r4, r3, #0                     @ 08020EE6
	adds r4, #0x50                      @ 08020EE8
	strb r2, [r4, #0xf]                 @ 08020EEA
	strb r2, [r4, #8]                   @ 08020EEC
	strb r2, [r3, #0x10]                @ 08020EEE
	adds r1, #1                         @ 08020EF0
	cmp r1, #0xf                        @ 08020EF2
	str r3, [r3, #0x2c]                 @ 08020EF4
	blt L_08020ED8                      @ 08020EF6
	pop {r4}                            @ 08020EF8
	bx lr                               @ 08020EFA

@ --------------------------------------------------------------------------------------------
@ void Player_PlaySong(Player *p, const Song *s): start s at order 0 with its speed and tempo.
	.thumb_func
	.global Player_PlaySong
Player_PlaySong:
	push {r4, r5, r6, lr}               @ 08020EFC
	movs r5, #1                         @ 08020EFE
	strb r5, [r0, #2]                   @ 08020F00
	strb r5, [r0]                       @ 08020F02
	movs r2, #0                         @ 08020F04
	strb r2, [r0, #1]                   @ 08020F06
	str r1, [r0, #0xc]                  @ 08020F08
	adds r4, r0, #0                     @ 08020F0A
	ldrb r0, [r1, #0x11]                @ 08020F0C
	strb r0, [r4, #3]                   @ 08020F0E
	mvns r0, r2                         @ 08020F10
	str r0, [r4, #0x10]                 @ 08020F12
	movs r0, #0                         @ 08020F14
L_08020F16:
	lsls r3, r0, #1                     @ 08020F16
	adds r3, r3, r0                     @ 08020F18
	lsls r3, r3, #5                     @ 08020F1A
	adds r3, r3, r4                     @ 08020F1C
	adds r3, #0x18                      @ 08020F1E
	movs r6, #0x4a                      @ 08020F20
	strb r2, [r6, r3]                   @ 08020F22
	adds r6, r3, #0                     @ 08020F24
	adds r6, #0x50                      @ 08020F26
	strb r2, [r6, #0xf]                 @ 08020F28
	strb r2, [r6, #8]                   @ 08020F2A
	strb r2, [r3, #0x10]                @ 08020F2C
	adds r0, #1                         @ 08020F2E
	cmp r0, #0xf                        @ 08020F30
	str r3, [r3, #0x2c]                 @ 08020F32
	blt L_08020F16                      @ 08020F34
	ldrb r0, [r1, #0x10]                @ 08020F36
	ldr r1, L_08020FA0                  @ 08020F38 =0x00009C40
	strb r0, [r4, #4]                   @ 08020F3A
	bl __rt_udiv                        @ 08020F3C
	strh r0, [r4, #6]                   @ 08020F40
	strb r5, [r4, #5]                   @ 08020F42
	pop {r4, r5, r6, pc}                @ 08020F44

@ --------------------------------------------------------------------------------------------
@ void Player_SkipPattern(Player *p): reset the channels and end the current pattern.
	.thumb_func
	.global Player_SkipPattern
Player_SkipPattern:
	movs r1, #0                         @ 08020F46
	movs r2, #0                         @ 08020F48
	push {r4}                           @ 08020F4A
L_08020F4C:
	lsls r3, r1, #1                     @ 08020F4C
	adds r3, r3, r1                     @ 08020F4E
	lsls r3, r3, #5                     @ 08020F50
	adds r3, r3, r0                     @ 08020F52
	adds r3, #0x18                      @ 08020F54
	movs r4, #0x4a                      @ 08020F56
	strb r2, [r4, r3]                   @ 08020F58
	adds r4, r3, #0                     @ 08020F5A
	adds r4, #0x50                      @ 08020F5C
	strb r2, [r4, #0xf]                 @ 08020F5E
	strb r2, [r4, #8]                   @ 08020F60
	strb r2, [r3, #0x10]                @ 08020F62
	adds r1, #1                         @ 08020F64
	cmp r1, #0xf                        @ 08020F66
	str r3, [r3, #0x2c]                 @ 08020F68
	blt L_08020F4C                      @ 08020F6A
	ldrb r1, [r0, #2]                   @ 08020F6C
	strb r1, [r0, #1]                   @ 08020F6E
	movs r1, #1                         @ 08020F70
	strb r1, [r0]                       @ 08020F72
	pop {r4}                            @ 08020F74
	bx lr                               @ 08020F76

@ --------------------------------------------------------------------------------------------
@ void Player_SetVolume(Player *p, int bus): bus volume of the 15 music voices.
	.thumb_func
	.global Player_SetVolume
Player_SetVolume:
	push {r4, r5}                       @ 08020F78
	movs r4, #0x10                      @ 08020F7A
	movs r2, #0                         @ 08020F7C
	lsls r1, r1, #0x18                  @ 08020F7E
	lsrs r1, r1, #0x18                  @ 08020F80
L_08020F82:
	lsls r3, r2, #1                     @ 08020F82
	adds r3, r3, r2                     @ 08020F84
	lsls r3, r3, #5                     @ 08020F86
	adds r3, r3, r0                     @ 08020F88
	adds r3, #0x18                      @ 08020F8A
	movs r5, #0x34                      @ 08020F8C
	strb r1, [r5, r3]                   @ 08020F8E
	ldrb r5, [r3, #0x10]                @ 08020F90
	adds r2, #1                         @ 08020F92
	orrs r5, r4                         @ 08020F94
	strb r5, [r3, #0x10]                @ 08020F96
	cmp r2, #0xf                        @ 08020F98
	blt L_08020F82                      @ 08020F9A
	pop {r4, r5}                        @ 08020F9C
	bx lr                               @ 08020F9E
L_08020FA0:
	.word TEMPO_K	@ 0x00009C40

@ --------------------------------------------------------------------------------------------
@ void Snd_Init(Snd *s): clears the 2 KB of rings, DirectSound A = left, B = right, Timer 0 reload -1050 (15978 Hz),
@ DMA1 -> left ring, DMA2 -> right ring + 512, IRQ handler installed in the interrupt manager,
@ bus volumes music 4 / sfx 8.
	.thumb_func
	.global Snd_Init
Snd_Init:
	push {r4, r5, r6, lr}               @ 08020FA4
	adds r4, r0, #0                     @ 08020FA6
	movs r5, #0                         @ 08020FA8
	str r5, [r0, #4]                    @ 08020FAA
	str r5, [r4, #8]                    @ 08020FAC
	str r5, [r4]                        @ 08020FAE
	ldr r0, L_0802118C                  @ 08020FB0 =0x03003914
	str r5, [r0]                        @ 08020FB2
	adds r1, r0, #0                     @ 08020FB4
	ldr r0, L_08021190                  @ 08020FB6 =0x040000D4
	str r1, [r0]                        @ 08020FB8
	movs r1, #1                         @ 08020FBA
	lsls r1, r1, #0x19                  @ 08020FBC
	str r1, [r0, #4]                    @ 08020FBE
	lsrs r1, r0, #0x11                  @ 08020FC0
	strh r1, [r0, #8]                   @ 08020FC2
	movs r1, #0x85                      @ 08020FC4
	lsls r1, r1, #8                     @ 08020FC6
	strh r1, [r0, #0xa]                 @ 08020FC8
	ldr r0, L_08021194                  @ 08020FCA =0x000005C4
	adds r0, r4, r0                     @ 08020FCC
	adds r6, r0, #0                     @ 08020FCE
	bl Pool_Clear                       @ 08020FD0
	adds r4, #0xc                       @ 08020FD4
	adds r0, r4, #0                     @ 08020FD6
	bl Player_ResetChannels             @ 08020FD8
	ldr r2, L_08021198                  @ 08020FDC =0x04000080
	movs r0, #0x80                      @ 08020FDE
	ldr r1, L_0802119C                  @ 08020FE0 =0x00009A0E
	strh r0, [r2, #4]                   @ 08020FE2
	strh r1, [r2, #2]                   @ 08020FE4
	lsls r1, r0, #0x12                  @ 08020FE6
	str r1, [r2, #0x3c]                 @ 08020FE8
	ldr r3, L_080211A0                  @ 08020FEA =0x040000A0
	adds r1, r3, #0                     @ 08020FEC
	adds r1, #0x20                      @ 08020FEE
	str r3, [r1]                        @ 08020FF0
	movs r3, #4                         @ 08020FF2
	strh r3, [r1, #4]                   @ 08020FF4
	ldr r3, L_080211A4                  @ 08020FF6 =0x0000B660
	strh r3, [r1, #6]                   @ 08020FF8
	ldr r3, L_080211A8                  @ 08020FFA =0x02000600
	str r3, [r1, #8]                    @ 08020FFC
	ldr r3, L_080211AC                  @ 08020FFE =0x040000A4
	str r3, [r1, #0xc]                  @ 08021000
	movs r3, #4                         @ 08021002
	strh r3, [r1, #0x10]                @ 08021004
	ldr r3, L_080211B0                  @ 08021006 =0x0000F660
	strh r3, [r1, #0x12]                @ 08021008
	strh r5, [r2]                       @ 0802100A
	ldr r1, L_080211B4                  @ 0802100C =0x087D6964
	ldr r2, L_080211B8                  @ 0802100E =0x03000798
	ldr r1, [r1]                        @ 08021010
	str r2, [r1, #0x28]                 @ 08021012
	ldr r1, L_080211BC                  @ 08021014 =0x04000200
	lsls r2, r0, #3                     @ 08021016
	ldrh r1, [r1]                       @ 08021018
	orrs r1, r2                         @ 0802101A
	ldr r2, L_080211BC                  @ 0802101C =0x04000200
	strh r1, [r2]                       @ 0802101E
	subs r2, #0xff                      @ 08021020
	ldr r1, L_080211C0                  @ 08021022 =0xFFFFFBE6
	subs r2, #1                         @ 08021024
	strh r1, [r2]                       @ 08021026
	strh r0, [r2, #2]                   @ 08021028
	movs r1, #4                         @ 0802102A
	adds r0, r4, #0                     @ 0802102C
	bl Player_SetVolume                 @ 0802102E
	movs r1, #8                         @ 08021032
	adds r0, r6, #0                     @ 08021034
	bl Pool_SetVolume                   @ 08021036
	pop {r4, r5, r6, pc}                @ 0802103A

@ --------------------------------------------------------------------------------------------
@ void Snd_Shutdown(void): wait for the sound IRQ, stop Timer 0, both DMAs and the sound circuit.
	.thumb_func
	.global Snd_Shutdown
Snd_Shutdown:
	ldr r0, L_080211B4                  @ 0802103C =0x087D6964
	push {r3, lr}                       @ 0802103E
	movs r1, #1                         @ 08021040
	lsls r1, r1, #0xa                   @ 08021042
	ldr r0, [r0]                        @ 08021044
	bl IntrMgr_Wait                     @ 08021046
	ldr r1, L_080211C4                  @ 0802104A =0x04000100
	movs r0, #0                         @ 0802104C
	strh r0, [r1, #2]                   @ 0802104E
	subs r1, #0x40                      @ 08021050
	strh r0, [r1, #6]                   @ 08021052
	strh r0, [r1, #0x12]                @ 08021054
	ldr r1, L_08021198                  @ 08021056 =0x04000080
	strh r0, [r1, #4]                   @ 08021058
	pop {r3, pc}                        @ 0802105A

@ --------------------------------------------------------------------------------------------
@ void Snd_Kill(void): stop Timer 0 and both DMAs at once.
	.thumb_func
	.global Snd_Kill
Snd_Kill:
	ldr r1, L_080211C4                  @ 0802105C =0x04000100
	movs r0, #0                         @ 0802105E
	strh r0, [r1, #2]                   @ 08021060
	subs r1, #0x40                      @ 08021062
	strh r0, [r1, #6]                   @ 08021064
	strh r0, [r1, #0x12]                @ 08021066
	bx lr                               @ 08021068

@ --------------------------------------------------------------------------------------------
@ void Snd_Pause(void): wait for the sound IRQ, then stop Timer 0.
	.thumb_func
	.global Snd_Pause
Snd_Pause:
	ldr r0, L_080211B4                  @ 0802106A =0x087D6964
	push {r3, lr}                       @ 0802106C
	movs r1, #1                         @ 0802106E
	lsls r1, r1, #0xa                   @ 08021070
	ldr r0, [r0]                        @ 08021072
	bl IntrMgr_Wait                     @ 08021074
	ldr r1, L_080211C4                  @ 08021078 =0x04000100
	movs r0, #0                         @ 0802107A
	strh r0, [r1, #2]                   @ 0802107C
	pop {r3, pc}                        @ 0802107E

@ --------------------------------------------------------------------------------------------
@ void Snd_Resume(void): restart Timer 0.
	.thumb_func
	.global Snd_Resume
Snd_Resume:
	ldr r1, L_080211C4                  @ 08021080 =0x04000100
	movs r0, #0x80                      @ 08021082
	strh r0, [r1, #2]                   @ 08021084
	bx lr                               @ 08021086

@ --------------------------------------------------------------------------------------------
@ void Snd_Mix(Snd *s): refill the rings (main loop, and the IRQ when they run low).
@ At least 64 free samples: update the pool voices, then per chunk of at most 512 samples
@ Player_Render + Pool_MixAll + Mix_Output, split at the ring wrap and the right ring's 512 offset.
	.thumb_func
	.global Snd_Mix
Snd_Mix:
	push {r4, r5, r6, r7, lr}           @ 08021088
	adds r7, r0, #0                     @ 0802108A
	movs r0, #1                         @ 0802108C
	sub sp, #0x1c                       @ 0802108E
	str r0, [r7]                        @ 08021090
	ldr r0, [r7, #4]                    @ 08021092
	ldr r4, [r7, #8]                    @ 08021094
	subs r1, r0, r4                     @ 08021096
	lsls r5, r1, #0x16                  @ 08021098
	lsrs r5, r5, #0x16                  @ 0802109A
	str r5, [sp, #0xc]                  @ 0802109C
	cmp r5, #0x40                       @ 0802109E
	blt L_08021182                      @ 080210A0
	str r0, [r7, #8]                    @ 080210A2
	ldr r0, L_08021194                  @ 080210A4 =0x000005C4
	adds r0, r7, r0                     @ 080210A6
	str r0, [sp, #0x18]                 @ 080210A8
	bl Pool_UpdateAll                   @ 080210AA
	adds r0, r7, #0                     @ 080210AE
	adds r0, #0xc                       @ 080210B0
	str r0, [sp, #0x14]                 @ 080210B2
	ldr r0, L_080211C8                  @ 080210B4 =0x000009C4
	adds r6, r7, r0                     @ 080210B6
L_080210B8:
	movs r1, #1                         @ 080210B8
	ldr r5, [sp, #0xc]                  @ 080210BA
	lsls r1, r1, #9                     @ 080210BC
	cmp r5, r1                          @ 080210BE
	ble L_080210C4                      @ 080210C0
	adds r5, r1, #0                     @ 080210C2
L_080210C4:
	adds r2, r5, #0                     @ 080210C4
	adds r1, r6, #0                     @ 080210C6
	ldr r0, [sp, #0x14]                 @ 080210C8
	bl Player_Render                    @ 080210CA
	adds r2, r5, #0                     @ 080210CE
	adds r1, r6, #0                     @ 080210D0
	ldr r0, [sp, #0x18]                 @ 080210D2
	bl Pool_MixAll                      @ 080210D4
	adds r0, r4, r5                     @ 080210D8
	movs r1, #1                         @ 080210DA
	lsls r1, r1, #0xa                   @ 080210DC
	cmp r0, r1                          @ 080210DE
	str r0, [sp, #0x10]                 @ 080210E0
	ble L_08021114                      @ 080210E2
	subs r3, r1, r4                     @ 080210E4
	str r3, [sp, #8]                    @ 080210E6
	subs r3, r0, r1                     @ 080210E8
	ldr r0, L_080211CC                  @ 080210EA =0x02000200
	str r3, [sp, #4]                    @ 080210EC
	adds r1, r4, r0                     @ 080210EE
	lsls r0, r0, #0x10                  @ 080210F0
	adds r2, r6, #0                     @ 080210F2
	adds r0, r4, r0                     @ 080210F4
	ldr r3, [sp, #8]                    @ 080210F6
	bl Mix_Output_from_thumb            @ 080210F8
	ldr r3, [sp, #8]                    @ 080210FC
	ldr r1, L_080211C8                  @ 080210FE =0x000009C4
	lsls r0, r3, #2                     @ 08021100
	adds r0, r0, r7                     @ 08021102
	adds r2, r0, r1                     @ 08021104
	movs r0, #1                         @ 08021106
	lsls r0, r0, #0x19                  @ 08021108
	ldr r1, L_080211A8                  @ 0802110A =0x02000600
	ldr r3, [sp, #4]                    @ 0802110C
	bl Mix_Output_from_thumb            @ 0802110E
	b L_08021174                        @ 08021112
L_08021114:
	movs r1, #1                         @ 08021114
	lsls r1, r1, #9                     @ 08021116
	cmp r4, r1                          @ 08021118
	bge L_08021164                      @ 0802111A
	cmp r0, r1                          @ 0802111C
	ble L_08021150                      @ 0802111E
	subs r3, r1, r4                     @ 08021120
	str r3, [sp, #8]                    @ 08021122
	subs r3, r0, r1                     @ 08021124
	ldr r0, L_080211A8                  @ 08021126 =0x02000600
	str r3, [sp, #4]                    @ 08021128
	adds r1, r4, r0                     @ 0802112A
	movs r0, #1                         @ 0802112C
	lsls r0, r0, #0x19                  @ 0802112E
	adds r2, r6, #0                     @ 08021130
	adds r0, r4, r0                     @ 08021132
	ldr r3, [sp, #8]                    @ 08021134
	bl Mix_Output_from_thumb            @ 08021136
	ldr r3, [sp, #8]                    @ 0802113A
	ldr r1, L_080211C8                  @ 0802113C =0x000009C4
	lsls r0, r3, #2                     @ 0802113E
	adds r0, r0, r7                     @ 08021140
	adds r2, r0, r1                     @ 08021142
	ldr r1, L_080211D0                  @ 08021144 =0x02000400
	ldr r0, L_080211CC                  @ 08021146 =0x02000200
	ldr r3, [sp, #4]                    @ 08021148
	bl Mix_Output_from_thumb            @ 0802114A
	b L_08021174                        @ 0802114E
L_08021150:
	ldr r0, L_080211A8                  @ 08021150 =0x02000600
	adds r3, r5, #0                     @ 08021152
	adds r1, r4, r0                     @ 08021154
	movs r0, #1                         @ 08021156
	lsls r0, r0, #0x19                  @ 08021158
	adds r2, r6, #0                     @ 0802115A
	adds r0, r4, r0                     @ 0802115C
	bl Mix_Output_from_thumb            @ 0802115E
	b L_08021174                        @ 08021162
L_08021164:
	ldr r0, L_080211CC                  @ 08021164 =0x02000200
	adds r3, r5, #0                     @ 08021166
	adds r1, r4, r0                     @ 08021168
	lsls r0, r0, #0x10                  @ 0802116A
	adds r2, r6, #0                     @ 0802116C
	adds r0, r4, r0                     @ 0802116E
	bl Mix_Output_from_thumb            @ 08021170
L_08021174:
	ldr r0, [sp, #0x10]                 @ 08021174
	lsls r4, r0, #0x16                  @ 08021176
	ldr r0, [sp, #0xc]                  @ 08021178
	lsrs r4, r4, #0x16                  @ 0802117A
	subs r0, r0, r5                     @ 0802117C
	str r0, [sp, #0xc]                  @ 0802117E
	bne L_080210B8                      @ 08021180
L_08021182:
	movs r0, #0                         @ 08021182
	str r0, [r7]                        @ 08021184
	add sp, #0x1c                       @ 08021186
	pop {r4, r5, r6, r7, pc}            @ 08021188
	movs r0, r0                         @ 0802118A
L_0802118C:
	.word zero_word	@ 0x03003914
L_08021190:
	.word REG_DMA3SAD	@ 0x040000D4
L_08021194:
	.word SND_POOL	@ 0x000005C4
L_08021198:
	.word REG_SOUNDCNT_L	@ 0x04000080
L_0802119C:
	.word 0x00009A0E
L_080211A0:
	.word REG_FIFO_A	@ 0x040000A0
L_080211A4:
	.word 0x0000B660
L_080211A8:
	.word ring_R_512	@ 0x02000600
L_080211AC:
	.word REG_FIFO_B	@ 0x040000A4
L_080211B0:
	.word 0x0000F660
L_080211B4:
	.word p_intrmgr	@ 0x087D6964
L_080211B8:
	.word Snd_Dma2Irq	@ 0x03000798
L_080211BC:
	.word REG_IE	@ 0x04000200
L_080211C0:
	.word 0xFFFFFBE6
L_080211C4:
	.word REG_TM0CNT_L	@ 0x04000100
L_080211C8:
	.word SND_MIXBUF	@ 0x000009C4
L_080211CC:
	.word ring_L_512	@ 0x02000200
L_080211D0:
	.word ring_R	@ 0x02000400
