@ ============================================================================================
@ wf3_sound.s -- Webfoot Technologies GBA sound engine, version 2.1
@                as shipped in Hello Kitty: Happy Party Pals (GBA), ROM B86P (E)
@
@ Reconstructed by disassembly. Assembles with   arm-none-eabi-as -mcpu=arm7tdmi
@ and, linked with wf3.ld, rebuilds these ROM ranges byte for byte:
@     .wf3_iwram  ROM 0x0837E6B0-0x0837E9B4  ARM mixer + Timer 1 IRQ; part of the crt0 RW image,
@                   runs at 0x03000828 in IWRAM
@     .wf3_sound  0x08027F04-0x080292B8  voices + voice pool, pattern player, sound object (Thumb, compiled C++)
@ The tables are in wf3_rodata.s, the music/SFX data in wf3_data.s. All names are invented.
@
@ Version 2 is the version-1 engine rewritten as objects: one sound object holds the music player
@ (with the 15 channels and their voices embedded) and a 16-voice pool for effects; every function
@ takes the object it works on in r0. Mixing is done into a packed s32 buffer (left in the low half,
@ right in the high half) by a single ARM routine, and the output rate is fixed at 16 kHz.
@
@ ---- RAM -----------------------------------------------------------------------------------
@ snd  0x03003258  sound object, 0x11C4 bytes
@      +000 u32 busy   +004 u32 play position (IRQ adds 64)   +008 u32 write position
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
@ Output rings: left 0x02000000-0x0200043F, right 0x02000440-0x0200087F (1024 bytes + 64-byte guard each;
@      DMA2 starts the right ring at +512)
@ ============================================================================================

@ symbols defined in the other source files of this set:
@   NoteFreqTab            0x0837CD44
@   FxTab                  0x0837CF24
@   PortaUpTab             0x0837D024
@   PortaDownTab           0x0837D2A4
@   VibratoSine            0x0837D4A4
@   TonePortaVolTicks      0x0837D4E4
@   p_intrmgr              0x0837D4FC

	.syntax unified
	.equ mem_alloc, 0x08027418
	.equ mem_free, 0x0802749C
	.equ IntrMgr_Wait, 0x080292D4
	.equ __call_via_r1, 0x0802A35E
	.equ __call_via_r3, 0x0802A362
	.equ __rt_udiv, 0x0802A6A4
	.equ memcpy_from_thumb, 0x0802BDC0
	.equ memset_from_thumb, 0x0802BDCC
	.equ Mix_Output_from_thumb, 0x0802BE58
	.equ DMA_FIFO_RESTART, 0xB6400004
	.equ REG_FIFO_A, 0x040000A0
	.equ REG_FIFO_B, 0x040000A4
	.equ REG_SOUNDCNT_L, 0x04000080
	.equ REG_TM0CNT_L, 0x04000100
	.equ SND_MIXBUF, 0x000009C4
	.equ SND_POOL, 0x000005C4
	.equ TEMPO_K, 0x00009C40
	.equ intrmgr, 0x030010AC
	.equ ring_L_512, 0x02000200
	.equ ring_L_guard, 0x02000400
	.equ ring_R, 0x02000440
	.equ ring_R_512, 0x02000640
	.equ ring_R_guard, 0x02000840
	.equ ring_R_m512, 0x02000240
	.equ snd, 0x03003258
	.equ ring_L, 0x02000000


	.section .wf3_iwram, "ax"
	.p2align 2
	.arm

@ --------------------------------------------------------------------------------------------
@ void Mix_Voice(Voice *v, u32 *buf, int n)   (ARM, IWRAM)
@ buf[i] += sample * (volL | volR << 16): one multiply-accumulate mixes both channels into the packed
@ buffer. 8x unrolled; when the step is below 1.0 a second loop advances the pointer with conditional
@ pre-indexed loads (ldrsbhs ...!) instead of an add with carry.
	.global Mix_Voice
Mix_Voice:
	push {r4, r5, r6, r7, r8, sb, sl}   @ 03000828
	ldm r0, {r3, r4, r5, r6}            @ 0300082C
	lsl r7, r3, #0x12                   @ 03000830
	lsl r8, r4, #0x12                   @ 03000834
	add r3, r5, r3, asr #14             @ 03000838
	asr r4, r4, #0xe                    @ 0300083C
	tst r2, #1                          @ 03000840
	beq L_03000868                      @ 03000844
	ldrsb r0, [r3]                      @ 03000848
	adds r7, r7, r8                     @ 0300084C
	adc r3, r3, r4                      @ 03000850
	ldr r5, [r1]                        @ 03000854
	mla r5, r6, r0, r5                  @ 03000858
	str r5, [r1], #4                    @ 0300085C
	subs r2, r2, #1                     @ 03000860
	beq L_03000948                      @ 03000864
L_03000868:
	cmp r4, #0                          @ 03000868
	beq L_03000950                      @ 0300086C
	tst r2, #2                          @ 03000870
	beq L_030008A8                      @ 03000874
	ldrsb r0, [r3]                      @ 03000878
	adds r7, r7, r8                     @ 0300087C
	adc r3, r3, r4                      @ 03000880
	ldrsb r5, [r3]                      @ 03000884
	adds r7, r7, r8                     @ 03000888
	adc r3, r3, r4                      @ 0300088C
	ldm r1, {sb, ip}                    @ 03000890
	mla sb, r6, r0, sb                  @ 03000894
	mla ip, r6, r5, ip                  @ 03000898
	stm r1!, {sb, ip}                   @ 0300089C
	subs r2, r2, #2                     @ 030008A0
	beq L_03000948                      @ 030008A4
L_030008A8:
	tst r2, #4                          @ 030008A8
	bne L_030008F8                      @ 030008AC
L_030008B0:
	ldm r1, {r5, sb, sl, ip}            @ 030008B0
	ldrsb r0, [r3]                      @ 030008B4
	adds r7, r7, r8                     @ 030008B8
	adc r3, r3, r4                      @ 030008BC
	mla r5, r6, r0, r5                  @ 030008C0
	ldrsb r0, [r3]                      @ 030008C4
	adds r7, r7, r8                     @ 030008C8
	adc r3, r3, r4                      @ 030008CC
	mla sb, r6, r0, sb                  @ 030008D0
	ldrsb r0, [r3]                      @ 030008D4
	adds r7, r7, r8                     @ 030008D8
	adc r3, r3, r4                      @ 030008DC
	mla sl, r6, r0, sl                  @ 030008E0
	ldrsb r0, [r3]                      @ 030008E4
	adds r7, r7, r8                     @ 030008E8
	adc r3, r3, r4                      @ 030008EC
	mla ip, r6, r0, ip                  @ 030008F0
	stm r1!, {r5, sb, sl, ip}           @ 030008F4
L_030008F8:
	ldm r1, {r5, sb, sl, ip}            @ 030008F8
	ldrsb r0, [r3]                      @ 030008FC
	adds r7, r7, r8                     @ 03000900
	adc r3, r3, r4                      @ 03000904
	mla r5, r6, r0, r5                  @ 03000908
	ldrsb r0, [r3]                      @ 0300090C
	adds r7, r7, r8                     @ 03000910
	adc r3, r3, r4                      @ 03000914
	mla sb, r6, r0, sb                  @ 03000918
	ldrsb r0, [r3]                      @ 0300091C
	adds r7, r7, r8                     @ 03000920
	adc r3, r3, r4                      @ 03000924
	mla sl, r6, r0, sl                  @ 03000928
	ldrsb r0, [r3]                      @ 0300092C
	adds r7, r7, r8                     @ 03000930
	adc r3, r3, r4                      @ 03000934
	mla ip, r6, r0, ip                  @ 03000938
	stm r1!, {r5, sb, sl, ip}           @ 0300093C
	subs r2, r2, #8                     @ 03000940
	bhi L_030008B0                      @ 03000944
L_03000948:
	pop {r4, r5, r6, r7, r8, sb, sl}    @ 03000948
	bx lr                               @ 0300094C
L_03000950:
	ldrsb r0, [r3]                      @ 03000950
	tst r2, #2                          @ 03000954
	beq L_03000984                      @ 03000958
	ldm r1, {sb, ip}                    @ 0300095C
	mla sb, r6, r0, sb                  @ 03000960
	adds r7, r7, r8                     @ 03000964
	ldrsbhs r0, [r3, #1]!               @ 03000968
	mla ip, r6, r0, ip                  @ 0300096C
	adds r7, r7, r8                     @ 03000970
	ldrsbhs r0, [r3, #1]!               @ 03000974
	stm r1!, {sb, ip}                   @ 03000978
	subs r2, r2, #2                     @ 0300097C
	beq L_03000948                      @ 03000980
L_03000984:
	tst r2, #4                          @ 03000984
	bne L_030009C4                      @ 03000988
L_0300098C:
	ldm r1, {r4, r5, sb, ip}            @ 0300098C
	mla r4, r6, r0, r4                  @ 03000990
	adds r7, r7, r8                     @ 03000994
	ldrsbhs r0, [r3, #1]!               @ 03000998
	mla r5, r6, r0, r5                  @ 0300099C
	adds r7, r7, r8                     @ 030009A0
	ldrsbhs r0, [r3, #1]!               @ 030009A4
	mla sb, r6, r0, sb                  @ 030009A8
	adds r7, r7, r8                     @ 030009AC
	ldrsbhs r0, [r3, #1]!               @ 030009B0
	mla ip, r6, r0, ip                  @ 030009B4
	adds r7, r7, r8                     @ 030009B8
	ldrsbhs r0, [r3, #1]!               @ 030009BC
	stm r1!, {r4, r5, sb, ip}           @ 030009C0
L_030009C4:
	ldm r1, {r4, r5, sb, ip}            @ 030009C4
	mla r4, r6, r0, r4                  @ 030009C8
	adds r7, r7, r8                     @ 030009CC
	ldrsbhs r0, [r3, #1]!               @ 030009D0
	mla r5, r6, r0, r5                  @ 030009D4
	adds r7, r7, r8                     @ 030009D8
	ldrsbhs r0, [r3, #1]!               @ 030009DC
	mla sb, r6, r0, sb                  @ 030009E0
	adds r7, r7, r8                     @ 030009E4
	ldrsbhs r0, [r3, #1]!               @ 030009E8
	mla ip, r6, r0, ip                  @ 030009EC
	adds r7, r7, r8                     @ 030009F0
	ldrsbhs r0, [r3, #1]!               @ 030009F4
	stm r1!, {r4, r5, sb, ip}           @ 030009F8
	subs r2, r2, #8                     @ 030009FC
	bhi L_0300098C                      @ 03000A00
	pop {r4, r5, r6, r7, r8, sb, sl}    @ 03000A04
	bx lr                               @ 03000A08

@ --------------------------------------------------------------------------------------------
@ void Mix_Output(s8 *outL, s8 *outR, u32 *buf, int n)   (ARM, IWRAM)
@ Unpacks the halves of each mix word, >> 6, clamps to -128..127, writes both rings and zeroes buf.
	.global Mix_Output
Mix_Output:
	push {r4, r5, r6, r7, r8}           @ 03000A0C
	mov r8, #0                          @ 03000A10
	mov ip, #0                          @ 03000A14
L_03000A18:
	ldm r2, {r4, r6}                    @ 03000A18
	stm r2!, {r8, ip}                   @ 03000A1C
	asr r5, r4, #0x16                   @ 03000A20
	asr r7, r6, #0x16                   @ 03000A24
	lsl r4, r4, #0x10                   @ 03000A28
	lsl r6, r6, #0x10                   @ 03000A2C
	asr r4, r4, #0x16                   @ 03000A30
	asr r6, r6, #0x16                   @ 03000A34
	cmp r4, #0x7f                       @ 03000A38
	movgt r4, #0x7f                     @ 03000A3C
	cmn r4, #0x80                       @ 03000A40
	mvnlt r4, #0x7f                     @ 03000A44
	cmp r5, #0x7f                       @ 03000A48
	movgt r5, #0x7f                     @ 03000A4C
	cmn r5, #0x80                       @ 03000A50
	mvnlt r5, #0x7f                     @ 03000A54
	cmp r6, #0x7f                       @ 03000A58
	movgt r6, #0x7f                     @ 03000A5C
	cmn r6, #0x80                       @ 03000A60
	mvnlt r6, #0x7f                     @ 03000A64
	cmp r7, #0x7f                       @ 03000A68
	movgt r7, #0x7f                     @ 03000A6C
	cmn r7, #0x80                       @ 03000A70
	mvnlt r7, #0x7f                     @ 03000A74
	and r4, r4, #0xff                   @ 03000A78
	orr r4, r4, r6, lsl #8              @ 03000A7C
	and r5, r5, #0xff                   @ 03000A80
	orr r5, r5, r7, lsl #8              @ 03000A84
	strh r4, [r0], #2                   @ 03000A88
	strh r5, [r1], #2                   @ 03000A8C
	subs r3, r3, #2                     @ 03000A90
	bgt L_03000A18                      @ 03000A94
	pop {r4, r5, r6, r7, r8}            @ 03000A98
	bx lr                               @ 03000A9C

@ --------------------------------------------------------------------------------------------
@ Timer 1 interrupt (Timer 1 counts Timer 0 overflows, reload -64: every 64 samples), ARM.
@ playpos += 64 and IRQs are re-enabled at once; every 512 samples re-arm DMA2 / DMA1 (the rings have a
@ 68-byte guard copy at their end, see Snd_Mix, so the late restart is harmless); if exactly 128 samples
@ are left before the write position and the mixer is idle, tail-jump to Snd_Mix(&snd).
	.global Snd_Timer1Irq
Snd_Timer1Irq:
	ldr r0, L_03000B20                  @ 03000AA0 =0x03003258
	ldr r1, [r0, #4]                    @ 03000AA4
	add r1, r1, #0x40                   @ 03000AA8
	str r1, [r0, #4]                    @ 03000AAC
	mrs ip, cpsr                        @ 03000AB0
	bic ip, ip, #0x80                   @ 03000AB4
	msr cpsr_c, ip                      @ 03000AB8
	lsls ip, r1, #0x17                  @ 03000ABC
	bne L_03000AF8                      @ 03000AC0
	lsls r2, r1, #0x16                  @ 03000AC4
	mov r2, #128, #14                   @ 03000AC8
	bpl L_03000AE0                      @ 03000ACC
	str ip, [r3, #-0x130]!              @ 03000AD0
	add r2, r2, #68, #28                @ 03000AD4
	sub ip, r3, #0x2c                   @ 03000AD8
	b L_03000AEC                        @ 03000ADC
L_03000AE0:
	str ip, [r0, #4]                    @ 03000AE0
	str ip, [r3, #-0x13c]!              @ 03000AE4
	sub ip, r3, #0x24                   @ 03000AE8
L_03000AEC:
	stmdb r3, {r2, ip}                  @ 03000AEC
	ldr ip, L_03000B24                  @ 03000AF0 =0xB6400004
	str ip, [r3]                        @ 03000AF4
L_03000AF8:
	ldr ip, [r0, #8]                    @ 03000AF8
	sub ip, ip, r1                      @ 03000AFC
	lsl ip, ip, #0x16                   @ 03000B00
	cmp ip, #128, #10                   @ 03000B04
	bxne r4                             @ 03000B08
	ldrb ip, [r0]                       @ 03000B0C
	cmp ip, #0                          @ 03000B10
	bxne r4                             @ 03000B14
	ldr r1, L_03000B28                  @ 03000B18 =0x080290E1
	bx r1                               @ 03000B1C
L_03000B20:
	.word snd	@ 0x03003258
L_03000B24:
	.word DMA_FIFO_RESTART	@ 0xB6400004
L_03000B28:
	.word Snd_Mix	@ 0x080290E1

	.section .wf3_sound, "ax"
	.p2align 2
	.thumb

@ --------------------------------------------------------------------------------------------
@ void Mix_Null(void) -- mix routine of a voice with both volumes 0.
	.thumb_func
	.global Mix_Null
Mix_Null:
	bx lr                               @ 08027F04

@ --------------------------------------------------------------------------------------------
@ void Voice_Update(Voice *v): apply the dirty flags.
@   bit4: volL = bus*vol*(64-pan)>>10, volR = bus*vol*(64+pan)>>10; routine = Mix_Null if both are 0,
@         else Mix_Voice;
@   bit3: copy data/loop/rate from the sample header;  bit2: position 0, forward;
@   bit1: |step| = ((pitch * rate >> 14) * 0x1063 + 0x7FF) >> 12   (0x1063 = 2^26/16000).
	.thumb_func
	.global Voice_Update
Voice_Update:
	push {r4}                           @ 08027F06
	ldrb r1, [r0, #0x10]                @ 08027F08
	lsls r2, r1, #0x1f                  @ 08027F0A
	bpl L_08027F9E                      @ 08027F0C
	lsls r2, r1, #0x1b                  @ 08027F0E
	bpl L_08027F46                      @ 08027F10
	movs r2, #0x34                      @ 08027F12
	ldrb r2, [r2, r0]                   @ 08027F14
	ldrb r3, [r0, #0x12]                @ 08027F16
	muls r2, r3, r2                     @ 08027F18
	movs r3, #0x13                      @ 08027F1A
	ldrsb r4, [r0, r3]                  @ 08027F1C
	movs r3, #0x40                      @ 08027F1E
	subs r3, r3, r4                     @ 08027F20
	adds r4, #0x40                      @ 08027F22
	muls r3, r2, r3                     @ 08027F24
	asrs r3, r3, #0xa                   @ 08027F26
	lsls r3, r3, #0x10                  @ 08027F28
	muls r4, r2, r4                     @ 08027F2A
	asrs r2, r4, #0xa                   @ 08027F2C
	lsrs r3, r3, #0x10                  @ 08027F2E
	lsls r2, r2, #0x10                  @ 08027F30
	lsrs r2, r2, #0x10                  @ 08027F32
	strh r3, [r0, #0xc]                 @ 08027F34
	strh r2, [r0, #0xe]                 @ 08027F36
	orrs r2, r3                         @ 08027F38
	bne L_08027F42                      @ 08027F3A
	ldr r2, L_080281B8                  @ 08027F3C =0x08027F05
	str r2, [r0, #0x18]                 @ 08027F3E
	b L_08027F46                        @ 08027F40
L_08027F42:
	ldr r2, L_080281BC                  @ 08027F42 =0x03000828
	str r2, [r0, #0x18]                 @ 08027F44
L_08027F46:
	lsls r2, r1, #0x1c                  @ 08027F46
	bpl L_08027F64                      @ 08027F48
	ldr r2, [r0, #0x28]                 @ 08027F4A
	ldr r3, [r2]                        @ 08027F4C
	str r3, [r0, #8]                    @ 08027F4E
	ldrh r3, [r2, #6]                   @ 08027F50
	lsls r3, r3, #0xe                   @ 08027F52
	str r3, [r0, #0x20]                 @ 08027F54
	ldrh r3, [r2, #8]                   @ 08027F56
	lsls r3, r3, #0xe                   @ 08027F58
	str r3, [r0, #0x24]                 @ 08027F5A
	ldrh r3, [r2, #0xa]                 @ 08027F5C
	strh r3, [r0, #0x14]                @ 08027F5E
	ldrb r2, [r2, #4]                   @ 08027F60
	strb r2, [r0, #0x11]                @ 08027F62
L_08027F64:
	lsls r2, r1, #0x1d                  @ 08027F64
	bpl L_08027F74                      @ 08027F66
	movs r2, #0                         @ 08027F68
	str r2, [r0]                        @ 08027F6A
	ldrb r2, [r0, #0x11]                @ 08027F6C
	movs r3, #4                         @ 08027F6E
	bics r2, r3                         @ 08027F70
	strb r2, [r0, #0x11]                @ 08027F72
L_08027F74:
	lsls r1, r1, #0x1e                  @ 08027F74
	bpl L_08027F9A                      @ 08027F76
	ldrh r2, [r0, #0x14]                @ 08027F78
	ldr r1, [r0, #0x30]                 @ 08027F7A
	ldr r3, L_080281C0                  @ 08027F7C =0x00001063
	muls r1, r2, r1                     @ 08027F7E
	lsrs r1, r1, #0xe                   @ 08027F80
	ldr r2, L_080281C4                  @ 08027F82 =0x000007FF
	muls r1, r3, r1                     @ 08027F84
	adds r1, r1, r2                     @ 08027F86
	lsrs r1, r1, #0xc                   @ 08027F88
	str r1, [r0, #0x1c]                 @ 08027F8A
	ldrb r2, [r0, #0x11]                @ 08027F8C
	lsls r2, r2, #0x1d                  @ 08027F8E
	bpl L_08027F98                      @ 08027F90
	rsbs r1, r1, #0                     @ 08027F92
	str r1, [r0, #4]                    @ 08027F94
	b L_08027F9A                        @ 08027F96
L_08027F98:
	str r1, [r0, #4]                    @ 08027F98
L_08027F9A:
	movs r1, #1                         @ 08027F9A
	strb r1, [r0, #0x10]                @ 08027F9C
L_08027F9E:
	pop {r4}                            @ 08027F9E
	bx lr                               @ 08027FA0

@ --------------------------------------------------------------------------------------------
@ void Voice_Mix(Voice *v, u32 *buf, int n): as version 1 with two ping-pong fixes: the bounce
@ off the loop start now mirrors with the right sign (2*start - pos + k*step), and the bounce off the end
@ reflects to 2*end-1-p so the position can no longer land exactly on the end.
	.thumb_func
	.global Voice_Mix
Voice_Mix:
	push {r3, r4, r5, r6, r7, lr}       @ 08027FA2
	adds r4, r0, #0                     @ 08027FA4
	ldrb r0, [r0, #0x10]                @ 08027FA6
	adds r6, r1, #0                     @ 08027FA8
	adds r5, r2, #0                     @ 08027FAA
	lsls r0, r0, #0x1f                  @ 08027FAC
	bpl L_08027FDC                      @ 08027FAE
	ldrb r0, [r4, #0x11]                @ 08027FB0
	lsls r1, r0, #0x1f                  @ 08027FB2
	bpl L_08028080                      @ 08027FB4
	lsls r0, r0, #0x1e                  @ 08027FB6
	bpl L_08028082                      @ 08027FB8
L_08027FBA:
	ldmia r4!, {r0, r1}                 @ 08027FBA
	subs r4, #8                         @ 08027FBC
	muls r1, r5, r1                     @ 08027FBE
	adds r7, r0, r1                     @ 08027FC0
	ldrb r1, [r4, #0x11]                @ 08027FC2
	lsls r1, r1, #0x1d                  @ 08027FC4
	bpl L_08028020                      @ 08027FC6
	ldr r1, [r4, #0x20]                 @ 08027FC8
	cmp r1, r7                          @ 08027FCA
	bgt L_08027FDE                      @ 08027FCC
	adds r2, r5, #0                     @ 08027FCE
	adds r1, r6, #0                     @ 08027FD0
	adds r0, r4, #0                     @ 08027FD2
	ldr r3, [r4, #0x18]                 @ 08027FD4
	bl __call_via_r3                    @ 08027FD6
	str r7, [r4]                        @ 08027FDA
L_08027FDC:
	pop {r3, r4, r5, r6, r7, pc}        @ 08027FDC
L_08027FDE:
	ldr r2, [r4, #0x1c]                 @ 08027FDE
	adds r0, r0, r2                     @ 08027FE0
	subs r0, #1                         @ 08027FE2
	subs r0, r0, r1                     @ 08027FE4
	adds r1, r2, #0                     @ 08027FE6
	svc #6                              @ 08027FE8
	adds r7, r0, #0                     @ 08027FEA
	ldr r0, [r4, #0x20]                 @ 08027FEC
	ldr r1, [r4]                        @ 08027FEE
	lsls r0, r0, #1                     @ 08027FF0
	subs r1, r0, r1                     @ 08027FF2
	ldr r0, [r4, #0x1c]                 @ 08027FF4
	adds r2, r7, #0                     @ 08027FF6
	muls r0, r7, r0                     @ 08027FF8
	adds r0, r1, r0                     @ 08027FFA
	str r0, [sp]                        @ 08027FFC
	adds r1, r6, #0                     @ 08027FFE
	adds r0, r4, #0                     @ 08028000
	ldr r3, [r4, #0x18]                 @ 08028002
	bl __call_via_r3                    @ 08028004
	lsls r0, r7, #2                     @ 08028008
	adds r6, r0, r6                     @ 0802800A
	ldr r0, [sp]                        @ 0802800C
	subs r5, r5, r7                     @ 0802800E
	str r0, [r4]                        @ 08028010
	ldrb r0, [r4, #0x11]                @ 08028012
	movs r1, #4                         @ 08028014
	bics r0, r1                         @ 08028016
	strb r0, [r4, #0x11]                @ 08028018
	ldr r0, [r4, #0x1c]                 @ 0802801A
	str r0, [r4, #4]                    @ 0802801C
	b L_0802807A                        @ 0802801E
L_08028020:
	ldr r1, [r4, #0x24]                 @ 08028020
	cmp r1, r7                          @ 08028022
	ble L_08028036                      @ 08028024
	adds r2, r5, #0                     @ 08028026
	adds r1, r6, #0                     @ 08028028
	adds r0, r4, #0                     @ 0802802A
	ldr r3, [r4, #0x18]                 @ 0802802C
	bl __call_via_r3                    @ 0802802E
	str r7, [r4]                        @ 08028032
L_08028034:
	b L_08027FDC                        @ 08028034
L_08028036:
	adds r2, r1, #0                     @ 08028036
	ldr r1, [r4, #0x1c]                 @ 08028038
	adds r2, r2, r1                     @ 0802803A
	subs r2, #1                         @ 0802803C
	subs r0, r2, r0                     @ 0802803E
	svc #6                              @ 08028040
	adds r7, r0, #0                     @ 08028042
	ldr r0, [r4, #0x24]                 @ 08028044
	ldr r1, [r4]                        @ 08028046
	lsls r0, r0, #1                     @ 08028048
	subs r1, r0, r1                     @ 0802804A
	ldr r0, [r4, #0x1c]                 @ 0802804C
	adds r2, r7, #0                     @ 0802804E
	muls r0, r7, r0                     @ 08028050
	subs r0, r1, r0                     @ 08028052
	subs r0, #1                         @ 08028054
	str r0, [sp]                        @ 08028056
	adds r1, r6, #0                     @ 08028058
	adds r0, r4, #0                     @ 0802805A
	ldr r3, [r4, #0x18]                 @ 0802805C
	bl __call_via_r3                    @ 0802805E
	lsls r0, r7, #2                     @ 08028062
	adds r6, r0, r6                     @ 08028064
	ldr r0, [sp]                        @ 08028066
	movs r1, #4                         @ 08028068
	str r0, [r4]                        @ 0802806A
	ldrb r0, [r4, #0x11]                @ 0802806C
	subs r5, r5, r7                     @ 0802806E
	orrs r0, r1                         @ 08028070
	strb r0, [r4, #0x11]                @ 08028072
	ldr r0, [r4, #0x1c]                 @ 08028074
	rsbs r0, r0, #0                     @ 08028076
	str r0, [r4, #4]                    @ 08028078
L_0802807A:
	cmp r5, #0                          @ 0802807A
	bgt L_08027FBA                      @ 0802807C
	b L_08027FDC                        @ 0802807E
L_08028080:
	b L_080280DC                        @ 08028080
L_08028082:
	b L_08028084                        @ 08028082
L_08028084:
	ldr r0, [r4, #4]                    @ 08028084
	ldr r2, [r4]                        @ 08028086
	muls r0, r5, r0                     @ 08028088
	adds r7, r2, r0                     @ 0802808A
	ldr r0, [r4, #0x24]                 @ 0802808C
	cmp r0, r7                          @ 0802808E
	ble L_080280A2                      @ 08028090
	adds r2, r5, #0                     @ 08028092
	adds r1, r6, #0                     @ 08028094
	adds r0, r4, #0                     @ 08028096
	ldr r3, [r4, #0x18]                 @ 08028098
	bl __call_via_r3                    @ 0802809A
	str r7, [r4]                        @ 0802809E
	b L_08027FDC                        @ 080280A0
L_080280A2:
	ldr r1, [r4, #0x1c]                 @ 080280A2
	adds r0, r0, r1                     @ 080280A4
	subs r0, #1                         @ 080280A6
	subs r0, r0, r2                     @ 080280A8
	svc #6                              @ 080280AA
	adds r7, r0, #0                     @ 080280AC
	ldr r0, [r4, #0x1c]                 @ 080280AE
	ldr r1, [r4]                        @ 080280B0
	muls r0, r7, r0                     @ 080280B2
	adds r0, r1, r0                     @ 080280B4
	ldr r1, [r4, #0x24]                 @ 080280B6
	ldr r2, [r4, #0x20]                 @ 080280B8
	subs r1, r1, r2                     @ 080280BA
	subs r0, r0, r1                     @ 080280BC
	str r0, [sp]                        @ 080280BE
	adds r1, r6, #0                     @ 080280C0
	adds r2, r7, #0                     @ 080280C2
	adds r0, r4, #0                     @ 080280C4
	ldr r3, [r4, #0x18]                 @ 080280C6
	bl __call_via_r3                    @ 080280C8
	lsls r0, r7, #2                     @ 080280CC
	adds r6, r0, r6                     @ 080280CE
	ldr r0, [sp]                        @ 080280D0
	subs r5, r5, r7                     @ 080280D2
	cmp r5, #0                          @ 080280D4
	str r0, [r4]                        @ 080280D6
	bgt L_08028084                      @ 080280D8
	b L_08027FDC                        @ 080280DA
L_080280DC:
	ldr r0, [r4, #4]                    @ 080280DC
	ldr r2, [r4]                        @ 080280DE
	muls r0, r5, r0                     @ 080280E0
	adds r7, r2, r0                     @ 080280E2
	ldr r0, [r4, #0x24]                 @ 080280E4
	cmp r0, r7                          @ 080280E6
	ble L_080280FA                      @ 080280E8
	adds r2, r5, #0                     @ 080280EA
	adds r1, r6, #0                     @ 080280EC
	adds r0, r4, #0                     @ 080280EE
	ldr r3, [r4, #0x18]                 @ 080280F0
	bl __call_via_r3                    @ 080280F2
	str r7, [r4]                        @ 080280F6
	b L_08027FDC                        @ 080280F8
L_080280FA:
	ldr r1, [r4, #0x1c]                 @ 080280FA
	adds r0, r0, r1                     @ 080280FC
	subs r0, #1                         @ 080280FE
	subs r0, r0, r2                     @ 08028100
	svc #6                              @ 08028102
	adds r2, r0, #0                     @ 08028104
	adds r1, r6, #0                     @ 08028106
	adds r0, r4, #0                     @ 08028108
	ldr r3, [r4, #0x18]                 @ 0802810A
	bl __call_via_r3                    @ 0802810C
	movs r0, #0                         @ 08028110
	strb r0, [r4, #0x10]                @ 08028112
	ldr r0, [r4, #0x2c]                 @ 08028114
	cmp r0, #0                          @ 08028116
	beq L_08028034                      @ 08028118
	adds r0, #0x40                      @ 0802811A
	ldrb r1, [r0, #0xa]                 @ 0802811C
	movs r2, #4                         @ 0802811E
	bics r1, r2                         @ 08028120
	strb r1, [r0, #0xa]                 @ 08028122
	b L_08027FDC                        @ 08028124

@ --------------------------------------------------------------------------------------------
@ void Voice_Start(Voice *v, const SampleHdr *h, int vol, int pan)
	.thumb_func
	.global Voice_Start
Voice_Start:
	push {r4}                           @ 08028126
	movs r4, #1                         @ 08028128
	lsls r4, r4, #0xe                   @ 0802812A
	str r1, [r0, #0x28]                 @ 0802812C
	str r4, [r0, #0x30]                 @ 0802812E
	strb r2, [r0, #0x12]                @ 08028130
	strb r3, [r0, #0x13]                @ 08028132
	movs r1, #0x1f                      @ 08028134
	strb r1, [r0, #0x10]                @ 08028136
	pop {r4}                            @ 08028138
	bx lr                               @ 0802813A

@ --------------------------------------------------------------------------------------------
@ void Pool_StopAll(Voice pool[16])
	.thumb_func
	.global Pool_StopAll
Pool_StopAll:
	movs r1, #0                         @ 0802813C
L_0802813E:
	lsls r2, r1, #6                     @ 0802813E
	adds r2, r2, r0                     @ 08028140
	ldrb r3, [r2, #0x10]                @ 08028142
	adds r1, #1                         @ 08028144
	lsrs r3, r3, #1                     @ 08028146
	lsls r3, r3, #1                     @ 08028148
	strb r3, [r2, #0x10]                @ 0802814A
	cmp r1, #0x10                       @ 0802814C
	blt L_0802813E                      @ 0802814E
	bx lr                               @ 08028150

@ --------------------------------------------------------------------------------------------
@ void Pool_StopSample(Voice pool[16], const SampleHdr *h): stop the first voice playing h.
	.thumb_func
	.global Pool_StopSample
Pool_StopSample:
	push {r4}                           @ 08028152
	movs r2, #0xf                       @ 08028154
L_08028156:
	lsls r3, r2, #6                     @ 08028156
	adds r3, r3, r0                     @ 08028158
	ldrb r4, [r3, #0x10]                @ 0802815A
	lsls r4, r4, #0x1f                  @ 0802815C
	beq L_08028176                      @ 0802815E
	ldr r3, [r3, #0x28]                 @ 08028160
	cmp r3, r1                          @ 08028162
	bne L_08028176                      @ 08028164
	lsls r1, r2, #6                     @ 08028166
	adds r0, r1, r0                     @ 08028168
	ldrb r1, [r0, #0x10]                @ 0802816A
	lsrs r1, r1, #1                     @ 0802816C
	lsls r1, r1, #1                     @ 0802816E
	strb r1, [r0, #0x10]                @ 08028170
L_08028172:
	pop {r4}                            @ 08028172
	bx lr                               @ 08028174
L_08028176:
	subs r2, #1                         @ 08028176
	bpl L_08028156                      @ 08028178
	b L_08028172                        @ 0802817A

@ --------------------------------------------------------------------------------------------
@ void Pool_StopMatch(Voice pool[16], const SampleHdr *h, int vol, int pan):
@ stop the first voice playing h with exactly this volume and pan.
	.thumb_func
	.global Pool_StopMatch
Pool_StopMatch:
	push {r4, r5, r6}                   @ 0802817C
	adds r5, r3, #0                     @ 0802817E
	movs r4, #0xf                       @ 08028180
L_08028182:
	lsls r3, r4, #6                     @ 08028182
	adds r3, r3, r0                     @ 08028184
	ldrb r6, [r3, #0x10]                @ 08028186
	lsls r6, r6, #0x1f                  @ 08028188
	beq L_080281B2                      @ 0802818A
	ldr r6, [r3, #0x28]                 @ 0802818C
	cmp r6, r1                          @ 0802818E
	bne L_080281B2                      @ 08028190
	ldrb r6, [r3, #0x12]                @ 08028192
	cmp r6, r2                          @ 08028194
	bne L_080281B2                      @ 08028196
	adds r6, r3, #0                     @ 08028198
	movs r3, #0x13                      @ 0802819A
	ldrsb r6, [r6, r3]                  @ 0802819C
	cmp r6, r5                          @ 0802819E
	bne L_080281B2                      @ 080281A0
	lsls r1, r4, #6                     @ 080281A2
	adds r0, r1, r0                     @ 080281A4
	ldrb r1, [r0, #0x10]                @ 080281A6
	lsrs r1, r1, #1                     @ 080281A8
	lsls r1, r1, #1                     @ 080281AA
	strb r1, [r0, #0x10]                @ 080281AC
L_080281AE:
	pop {r4, r5, r6}                    @ 080281AE
	bx lr                               @ 080281B0
L_080281B2:
	subs r4, #1                         @ 080281B2
	bpl L_08028182                      @ 080281B4
	b L_080281AE                        @ 080281B6
L_080281B8:
	.word Mix_Null	@ 0x08027F05
L_080281BC:
	.word Mix_Voice	@ 0x03000828
L_080281C0:
	.word 0x00001063
L_080281C4:
	.word 0x000007FF

@ --------------------------------------------------------------------------------------------
@ Voice *Pool_Play(Voice pool[16], const SampleHdr *h, int vol, int pan): first free voice or 0.
	.thumb_func
	.global Pool_Play
Pool_Play:
	push {r4, r5}                       @ 080281C8
	movs r4, #0                         @ 080281CA
L_080281CC:
	lsls r5, r4, #6                     @ 080281CC
	adds r5, r5, r0                     @ 080281CE
	ldrb r5, [r5, #0x10]                @ 080281D0
	lsls r5, r5, #0x1f                  @ 080281D2
	bne L_080281EE                      @ 080281D4
	lsls r4, r4, #6                     @ 080281D6
	adds r0, r4, r0                     @ 080281D8
	movs r4, #1                         @ 080281DA
	lsls r4, r4, #0xe                   @ 080281DC
	str r1, [r0, #0x28]                 @ 080281DE
	str r4, [r0, #0x30]                 @ 080281E0
	strb r2, [r0, #0x12]                @ 080281E2
	strb r3, [r0, #0x13]                @ 080281E4
	movs r1, #0x1f                      @ 080281E6
	strb r1, [r0, #0x10]                @ 080281E8
L_080281EA:
	pop {r4, r5}                        @ 080281EA
	bx lr                               @ 080281EC
L_080281EE:
	adds r4, #1                         @ 080281EE
	cmp r4, #0x10                       @ 080281F0
	blt L_080281CC                      @ 080281F2
	movs r0, #0                         @ 080281F4
	b L_080281EA                        @ 080281F6

@ --------------------------------------------------------------------------------------------
@ void Pool_AddVoice(Voice pool[16], const Voice *v): copy v into the first free slot (memcpy; v2 used DMA3).
	.thumb_func
	.global Pool_AddVoice
Pool_AddVoice:
	push {r3, lr}                       @ 080281F8
	movs r2, #0                         @ 080281FA
L_080281FC:
	lsls r3, r2, #6                     @ 080281FC
	adds r3, r3, r0                     @ 080281FE
	ldrb r3, [r3, #0x10]                @ 08028200
	lsls r3, r3, #0x1f                  @ 08028202
	bne L_08028212                      @ 08028204
	lsls r2, r2, #6                     @ 08028206
	adds r0, r2, r0                     @ 08028208
	movs r2, #0x40                      @ 0802820A
	bl memcpy_from_thumb                @ 0802820C
L_08028210:
	pop {r3, pc}                        @ 08028210
L_08028212:
	adds r2, #1                         @ 08028212
	cmp r2, #0x10                       @ 08028214
	blt L_080281FC                      @ 08028216
	b L_08028210                        @ 08028218

@ --------------------------------------------------------------------------------------------
@ int Pool_CountActive(Voice pool[16])
	.thumb_func
	.global Pool_CountActive
Pool_CountActive:
	adds r3, r0, #0                     @ 0802821A
	movs r0, #0                         @ 0802821C
	movs r1, #0                         @ 0802821E
L_08028220:
	lsls r2, r1, #6                     @ 08028220
	adds r2, r2, r3                     @ 08028222
	ldrb r2, [r2, #0x10]                @ 08028224
	lsls r2, r2, #0x1f                  @ 08028226
	beq L_0802822C                      @ 08028228
	adds r0, #1                         @ 0802822A
L_0802822C:
	adds r1, #1                         @ 0802822C
	cmp r1, #0x10                       @ 0802822E
	blt L_08028220                      @ 08028230
	bx lr                               @ 08028232

@ --------------------------------------------------------------------------------------------
@ void Pool_Clear(Voice pool[16]): flags = 0 for all.
	.thumb_func
	.global Pool_Clear
Pool_Clear:
	movs r1, #0                         @ 08028234
	movs r2, #0                         @ 08028236
L_08028238:
	lsls r3, r1, #6                     @ 08028238
	adds r3, r3, r0                     @ 0802823A
	adds r1, #1                         @ 0802823C
	cmp r1, #0x10                       @ 0802823E
	strb r2, [r3, #0x10]                @ 08028240
	blt L_08028238                      @ 08028242
	bx lr                               @ 08028244

@ --------------------------------------------------------------------------------------------
@ void Pool_UpdateAll(Voice pool[16])
	.thumb_func
	.global Pool_UpdateAll
Pool_UpdateAll:
	push {r4, r5, lr}                   @ 08028246
	adds r5, r0, #0                     @ 08028248
	movs r4, #0                         @ 0802824A
L_0802824C:
	lsls r0, r4, #6                     @ 0802824C
	adds r0, r0, r5                     @ 0802824E
	bl Voice_Update                     @ 08028250
	adds r4, #1                         @ 08028254
	cmp r4, #0x10                       @ 08028256
	blt L_0802824C                      @ 08028258
	pop {r4, r5, pc}                    @ 0802825A

@ --------------------------------------------------------------------------------------------
@ void Pool_MixAll(Voice pool[16], u32 *buf, int n)
	.thumb_func
	.global Pool_MixAll
Pool_MixAll:
	push {r3, r4, r5, r6, r7, lr}       @ 0802825C
	adds r6, r1, #0                     @ 0802825E
	adds r5, r0, #0                     @ 08028260
	adds r7, r2, #0                     @ 08028262
	movs r4, #0                         @ 08028264
L_08028266:
	lsls r0, r4, #6                     @ 08028266
	adds r0, r0, r5                     @ 08028268
	adds r2, r7, #0                     @ 0802826A
	adds r1, r6, #0                     @ 0802826C
	bl Voice_Mix                        @ 0802826E
	adds r4, #1                         @ 08028272
	cmp r4, #0x10                       @ 08028274
	blt L_08028266                      @ 08028276
	pop {r3, r4, r5, r6, r7, pc}        @ 08028278

@ --------------------------------------------------------------------------------------------
@ void Pool_SetVolume(Voice pool[16], int bus)
	.thumb_func
	.global Pool_SetVolume
Pool_SetVolume:
	push {r4, r5}                       @ 0802827A
	movs r4, #0x10                      @ 0802827C
	movs r2, #0                         @ 0802827E
	lsls r3, r1, #0x18                  @ 08028280
	lsrs r3, r3, #0x18                  @ 08028282
L_08028284:
	lsls r1, r2, #6                     @ 08028284
	adds r1, r1, r0                     @ 08028286
	movs r5, #0x34                      @ 08028288
	strb r3, [r5, r1]                   @ 0802828A
	ldrb r5, [r1, #0x10]                @ 0802828C
	adds r2, #1                         @ 0802828E
	orrs r5, r4                         @ 08028290
	strb r5, [r1, #0x10]                @ 08028292
	cmp r2, #0x10                       @ 08028294
	blt L_08028284                      @ 08028296
	pop {r4, r5}                        @ 08028298
	bx lr                               @ 0802829A

@ --------------------------------------------------------------------------------------------
@ Voice *Pool_Suspend(Voice pool[16]): allocate room for 16 voices and move every active *looping*
@ voice (halfword +10 has both bit 0 = active and bit 8 = looped) into it; one-shot sounds keep playing.
@ Returns the copy for Pool_Restore. Copies with memcpy (v2: DMA3).
	.thumb_func
	.global Pool_Suspend
Pool_Suspend:
	push {r0, r4, r5, r6, r7, lr}       @ 0802829C
	movs r0, #1                         @ 0802829E
	lsls r0, r0, #0xa                   @ 080282A0
	bl mem_alloc                        @ 080282A2
	adds r6, r0, #0                     @ 080282A6
	movs r0, #0                         @ 080282A8
	movs r1, #0                         @ 080282AA
L_080282AC:
	lsls r2, r0, #6                     @ 080282AC
	adds r2, r2, r6                     @ 080282AE
	adds r0, #1                         @ 080282B0
	cmp r0, #0x10                       @ 080282B2
	strb r1, [r2, #0x10]                @ 080282B4
	blt L_080282AC                      @ 080282B6
	adds r4, r6, #0                     @ 080282B8
	movs r5, #0                         @ 080282BA
	movs r7, #1                         @ 080282BC
L_080282BE:
	ldr r1, [sp]                        @ 080282BE
	lsls r0, r5, #6                     @ 080282C0
	adds r1, r0, r1                     @ 080282C2
	ldrh r2, [r1, #0x10]                @ 080282C4
	movs r0, #0xff                      @ 080282C6
	adds r0, #2                         @ 080282C8
	bics r0, r2                         @ 080282CA
	bne L_080282E6                      @ 080282CC
	ldrb r0, [r1, #0x10]                @ 080282CE
	movs r2, #0x40                      @ 080282D0
	lsrs r0, r0, #1                     @ 080282D2
	lsls r0, r0, #1                     @ 080282D4
	strb r0, [r1, #0x10]                @ 080282D6
	adds r0, r4, #0                     @ 080282D8
	bl memcpy_from_thumb                @ 080282DA
	ldrb r0, [r4, #0x10]                @ 080282DE
	orrs r0, r7                         @ 080282E0
	strb r0, [r4, #0x10]                @ 080282E2
	adds r4, #0x40                      @ 080282E4
L_080282E6:
	adds r5, #1                         @ 080282E6
	cmp r5, #0x10                       @ 080282E8
	blt L_080282BE                      @ 080282EA
	adds r0, r6, #0                     @ 080282EC
	pop {r3, r4, r5, r6, r7, pc}        @ 080282EE

@ --------------------------------------------------------------------------------------------
@ void Pool_Restore(Voice pool[16], Voice *saved): put the saved voices back into free slots,
@ then free the copy. Copies with memcpy (v2: DMA3).
	.thumb_func
	.global Pool_Restore
Pool_Restore:
	push {r3, r4, r5, r6, r7, lr}       @ 080282F0
	movs r7, #0xff                      @ 080282F2
	adds r6, r1, #0                     @ 080282F4
	adds r5, r0, #0                     @ 080282F6
	movs r4, #0                         @ 080282F8
	adds r7, #2                         @ 080282FA
L_080282FC:
	lsls r0, r4, #6                     @ 080282FC
	adds r1, r0, r6                     @ 080282FE
	ldrh r2, [r1, #0x10]                @ 08028300
	adds r0, r7, #0                     @ 08028302
	bics r0, r2                         @ 08028304
	bne L_08028326                      @ 08028306
	movs r0, #0                         @ 08028308
L_0802830A:
	lsls r2, r0, #6                     @ 0802830A
	adds r2, r2, r5                     @ 0802830C
	ldrb r2, [r2, #0x10]                @ 0802830E
	lsls r2, r2, #0x1f                  @ 08028310
	bne L_08028320                      @ 08028312
	lsls r0, r0, #6                     @ 08028314
	adds r0, r0, r5                     @ 08028316
	movs r2, #0x40                      @ 08028318
	bl memcpy_from_thumb                @ 0802831A
	b L_08028326                        @ 0802831E
L_08028320:
	adds r0, #1                         @ 08028320
	cmp r0, #0x10                       @ 08028322
	blt L_0802830A                      @ 08028324
L_08028326:
	adds r4, #1                         @ 08028326
	cmp r4, #0x10                       @ 08028328
	blt L_080282FC                      @ 0802832A
	adds r0, r6, #0                     @ 0802832C
	bl mem_free                         @ 0802832E
	pop {r3, r4, r5, r6, r7, pc}        @ 08028332

@ --------------------------------------------------------------------------------------------
@ void Fx_None(Chan *c) -- as version 1; the instrument table is now taken from the current
@ song (song->instr), reached through the constant pointer p_player.
	.thumb_func
	.global Fx_None
Fx_None:
	adds r2, r0, #0                     @ 08028334
	adds r2, #0x50                      @ 08028336
	push {r4, r5, r6}                   @ 08028338
	ldrb r3, [r2, #8]                   @ 0802833A
	movs r1, #0x11                      @ 0802833C
	adds r4, r3, #0                     @ 0802833E
	ands r4, r1                         @ 08028340
	adds r1, r0, #0                     @ 08028342
	adds r1, #0x40                      @ 08028344
	cmp r4, #0                          @ 08028346
	beq L_080283AC                      @ 08028348
	ldrb r4, [r2, #0xa]                 @ 0802834A
	movs r6, #4                         @ 0802834C
	cmp r4, #0xff                       @ 0802834E
	bne L_08028364                      @ 08028350
	ldrb r2, [r1, #0xa]                 @ 08028352
	bics r2, r6                         @ 08028354
	strb r2, [r1, #0xa]                 @ 08028356
	ldrb r1, [r0, #0x10]                @ 08028358
	lsrs r1, r1, #1                     @ 0802835A
	lsls r1, r1, #1                     @ 0802835C
	strb r1, [r0, #0x10]                @ 0802835E
L_08028360:
	pop {r4, r5, r6}                    @ 08028360
	bx lr                               @ 08028362
L_08028364:
	ldrb r5, [r2, #0xc]                 @ 08028364
	lsls r4, r4, #2                     @ 08028366
	lsls r3, r3, #0x1a                  @ 08028368
	strb r5, [r1, #8]                   @ 0802836A
	ldr r5, L_080285F8                  @ 0802836C =0x0837CD44
	ldr r4, [r5, r4]                    @ 0802836E
	str r4, [r0, #0x40]                 @ 08028370
	strb r6, [r1, #0xa]                 @ 08028372
	bpl L_08028386                      @ 08028374
	ldrb r1, [r1, #8]                   @ 08028376
	str r4, [r0, #0x30]                 @ 08028378
	movs r2, #0x17                      @ 0802837A
	strb r1, [r0, #0x12]                @ 0802837C
	ldrb r1, [r0, #0x10]                @ 0802837E
	orrs r1, r2                         @ 08028380
	strb r1, [r0, #0x10]                @ 08028382
	b L_08028360                        @ 08028384
L_08028386:
	ldr r3, L_080285F8                  @ 08028386 =0x0837CD44
	ldrb r2, [r2, #0xb]                 @ 08028388
	subs r3, #4                         @ 0802838A
	ldr r3, [r3]                        @ 0802838C
	ldrb r1, [r1, #8]                   @ 0802838E
	ldr r3, [r3, #0xc]                  @ 08028390
	ldr r5, [r3, #8]                    @ 08028392
	lsls r3, r2, #1                     @ 08028394
	adds r2, r3, r2                     @ 08028396
	lsls r2, r2, #2                     @ 08028398
	adds r2, r5, r2                     @ 0802839A
	str r2, [r0, #0x28]                 @ 0802839C
	str r4, [r0, #0x30]                 @ 0802839E
	strb r1, [r0, #0x12]                @ 080283A0
	ldrb r1, [r0, #0x10]                @ 080283A2
	movs r2, #0x1f                      @ 080283A4
	orrs r1, r2                         @ 080283A6
	strb r1, [r0, #0x10]                @ 080283A8
	b L_08028360                        @ 080283AA
L_080283AC:
	movs r4, #0x44                      @ 080283AC
	ands r3, r4                         @ 080283AE
	beq L_08028360                      @ 080283B0
	ldrb r3, [r2, #0xc]                 @ 080283B2
	strb r3, [r1, #8]                   @ 080283B4
	ldrb r1, [r2, #0xc]                 @ 080283B6
	movs r2, #0x10                      @ 080283B8
	strb r1, [r0, #0x12]                @ 080283BA
	ldrb r1, [r0, #0x10]                @ 080283BC
	orrs r1, r2                         @ 080283BE
	strb r1, [r0, #0x10]                @ 080283C0
	b L_08028360                        @ 080283C2

@ --------------------------------------------------------------------------------------------
@ Axx: ticks per row = xx.
	.thumb_func
	.global Fx_A_SetSpeed
Fx_A_SetSpeed:
	push {r4, lr}                       @ 080283C4
	adds r4, r0, #0                     @ 080283C6
	bl Fx_None                          @ 080283C8
	adds r4, #0x50                      @ 080283CC
	ldr r1, L_080285F8                  @ 080283CE =0x0837CD44
	ldrb r0, [r4, #0xe]                 @ 080283D0
	subs r1, #4                         @ 080283D2
	ldr r1, [r1]                        @ 080283D4
	strb r0, [r1, #3]                   @ 080283D6
	pop {r4, pc}                        @ 080283D8

@ --------------------------------------------------------------------------------------------
@ Bxx: finish the current pattern now and continue at order xx.
	.thumb_func
	.global Fx_B_PositionJump
Fx_B_PositionJump:
	push {r4, lr}                       @ 080283DA
	adds r4, r0, #0                     @ 080283DC
	bl Fx_None                          @ 080283DE
	ldr r0, L_080285F8                  @ 080283E2 =0x0837CD44
	adds r4, #0x50                      @ 080283E4
	subs r0, #4                         @ 080283E6
	ldr r1, [r0]                        @ 080283E8
	ldr r2, [r0]                        @ 080283EA
	ldrb r1, [r1, #2]                   @ 080283EC
	adds r1, #0xff                      @ 080283EE
	strb r1, [r2, #1]                   @ 080283F0
	ldrb r1, [r4, #0xe]                 @ 080283F2
	ldr r0, [r0]                        @ 080283F4
	subs r1, #1                         @ 080283F6
	str r1, [r0, #0x10]                 @ 080283F8
	pop {r4, pc}                        @ 080283FA

@ --------------------------------------------------------------------------------------------
@ tick handler: volume -= slide step, stop sliding at 0.
	.thumb_func
	.global Tick_VolSlideDown
Tick_VolSlideDown:
	adds r1, r0, #0                     @ 080283FC
	adds r1, #0x40                      @ 080283FE
	ldrb r2, [r1, #8]                   @ 08028400
	ldrb r3, [r1, #0xb]                 @ 08028402
	subs r2, r2, r3                     @ 08028404
	lsls r2, r2, #0x18                  @ 08028406
	asrs r2, r2, #0x18                  @ 08028408
	strb r2, [r1, #8]                   @ 0802840A
	cmp r2, #0                          @ 0802840C
	bgt L_0802841C                      @ 0802840E
	movs r2, #0                         @ 08028410
	strb r2, [r1, #8]                   @ 08028412
	ldrb r2, [r1, #0xa]                 @ 08028414
	lsrs r2, r2, #2                     @ 08028416
	lsls r2, r2, #2                     @ 08028418
	strb r2, [r1, #0xa]                 @ 0802841A
L_0802841C:
	ldrb r1, [r1, #8]                   @ 0802841C
	movs r2, #0x10                      @ 0802841E
	strb r1, [r0, #0x12]                @ 08028420
	ldrb r1, [r0, #0x10]                @ 08028422
	orrs r1, r2                         @ 08028424
	strb r1, [r0, #0x10]                @ 08028426
	bx lr                               @ 08028428

@ --------------------------------------------------------------------------------------------
@ tick handler: volume += slide step, stop sliding at 64.
	.thumb_func
	.global Tick_VolSlideUp
Tick_VolSlideUp:
	adds r1, r0, #0                     @ 0802842A
	adds r1, #0x40                      @ 0802842C
	ldrb r2, [r1, #8]                   @ 0802842E
	ldrb r3, [r1, #0xb]                 @ 08028430
	adds r2, r2, r3                     @ 08028432
	lsls r2, r2, #0x18                  @ 08028434
	asrs r2, r2, #0x18                  @ 08028436
	strb r2, [r1, #8]                   @ 08028438
	cmp r2, #0x40                       @ 0802843A
	blt L_0802844A                      @ 0802843C
	movs r2, #0x40                      @ 0802843E
	strb r2, [r1, #8]                   @ 08028440
	ldrb r2, [r1, #0xa]                 @ 08028442
	lsrs r2, r2, #2                     @ 08028444
	lsls r2, r2, #2                     @ 08028446
	strb r2, [r1, #0xa]                 @ 08028448
L_0802844A:
	ldrb r1, [r1, #8]                   @ 0802844A
	movs r2, #0x10                      @ 0802844C
	strb r1, [r0, #0x12]                @ 0802844E
	ldrb r1, [r0, #0x10]                @ 08028450
	orrs r1, r2                         @ 08028452
	strb r1, [r0, #0x10]                @ 08028454
	bx lr                               @ 08028456

@ --------------------------------------------------------------------------------------------
@ Dxy (ST3 rules): Dx0 slide up x per tick, D0y slide down y per tick (DF0/D0F also act on
@ the first tick), DxF fine slide up x once, DFy fine slide down y once. D00 reuses the last value.
	.thumb_func
	.global Fx_D_VolumeSlide
Fx_D_VolumeSlide:
	push {r4, r5, lr}                   @ 08028458
	adds r4, r0, #0                     @ 0802845A
	bl Fx_None                          @ 0802845C
	movs r0, #0x5e                      @ 08028460
	ldrb r1, [r0, r4]                   @ 08028462
	adds r0, r4, #0                     @ 08028464
	adds r0, #0x40                      @ 08028466
	cmp r1, #0                          @ 08028468
	beq L_0802846E                      @ 0802846A
	strb r1, [r0, #0xc]                 @ 0802846C
L_0802846E:
	ldrb r1, [r0, #0xc]                 @ 0802846E
	movs r3, #1                         @ 08028470
	lsls r2, r1, #0x1c                  @ 08028472
	lsrs r2, r2, #0x1c                  @ 08028474
	cmp r2, #0                          @ 08028476
	bne L_08028496                      @ 08028478
	lsrs r1, r1, #4                     @ 0802847A
	strb r1, [r0, #0xb]                 @ 0802847C
	ldr r1, L_080285FC                  @ 0802847E =0x0802842B
	str r1, [r4, #0x54]                 @ 08028480
	ldrb r1, [r0, #0xa]                 @ 08028482
	orrs r1, r3                         @ 08028484
	strb r1, [r0, #0xa]                 @ 08028486
	ldrb r0, [r0, #0xb]                 @ 08028488
	cmp r0, #0xf                        @ 0802848A
	bne L_08028494                      @ 0802848C
	adds r0, r4, #0                     @ 0802848E
	bl Tick_VolSlideUp                  @ 08028490
L_08028494:
	pop {r4, r5, pc}                    @ 08028494
L_08028496:
	lsls r2, r1, #0x18                  @ 08028496
	lsrs r5, r2, #0x1c                  @ 08028498
	bne L_080284B8                      @ 0802849A
	ldrb r1, [r0, #0xc]                 @ 0802849C
	strb r1, [r0, #0xb]                 @ 0802849E
	ldr r1, L_08028600                  @ 080284A0 =0x080283FD
	str r1, [r4, #0x54]                 @ 080284A2
	ldrb r1, [r0, #0xa]                 @ 080284A4
	orrs r1, r3                         @ 080284A6
	strb r1, [r0, #0xa]                 @ 080284A8
	ldrb r0, [r0, #0xb]                 @ 080284AA
	cmp r0, #0xf                        @ 080284AC
	bne L_08028494                      @ 080284AE
	adds r0, r4, #0                     @ 080284B0
	bl Tick_VolSlideDown                @ 080284B2
	pop {r4, r5, pc}                    @ 080284B6
L_080284B8:
	movs r3, #0xf                       @ 080284B8
	bics r3, r1                         @ 080284BA
	bne L_080284CA                      @ 080284BC
	lsrs r1, r1, #4                     @ 080284BE
	strb r1, [r0, #0xb]                 @ 080284C0
	adds r0, r4, #0                     @ 080284C2
	bl Tick_VolSlideUp                  @ 080284C4
L_080284C8:
	pop {r4, r5, pc}                    @ 080284C8
L_080284CA:
	lsrs r2, r2, #0x1c                  @ 080284CA
	cmp r2, #0xf                        @ 080284CC
	bne L_080284C8                      @ 080284CE
	ands r1, r2                         @ 080284D0
	strb r1, [r0, #0xb]                 @ 080284D2
	adds r0, r4, #0                     @ 080284D4
	bl Tick_VolSlideDown                @ 080284D6
	pop {r4, r5, pc}                    @ 080284DA

@ --------------------------------------------------------------------------------------------
@ tick handler: pitch = pitch * PortaDownTab[speed] >> 16.
	.thumb_func
	.global Tick_PortaDown
Tick_PortaDown:
	movs r1, #0x4d                      @ 080284DC
	ldrb r1, [r1, r0]                   @ 080284DE
	ldr r3, L_08028604                  @ 080284E0 =0x0837D2A4
	ldr r2, [r0, #0x40]                 @ 080284E2
	lsls r1, r1, #1                     @ 080284E4
	ldrh r1, [r3, r1]                   @ 080284E6
	muls r2, r1, r2                     @ 080284E8
	lsrs r1, r2, #0x10                  @ 080284EA
	str r1, [r0, #0x40]                 @ 080284EC
	str r1, [r0, #0x30]                 @ 080284EE
	ldrb r1, [r0, #0x10]                @ 080284F0
	movs r2, #2                         @ 080284F2
	orrs r1, r2                         @ 080284F4
	strb r1, [r0, #0x10]                @ 080284F6
	bx lr                               @ 080284F8

@ --------------------------------------------------------------------------------------------
@ Exx portamento down: xx/16 semitone per tick; EFx fine (x/16 semitone once),
@ EEx extra fine (x/64 semitone once). E00 reuses the shared E/F/G memory.
	.thumb_func
	.global Fx_E_PortaDown
Fx_E_PortaDown:
	push {r4, r5, lr}                   @ 080284FA
	adds r4, r0, #0                     @ 080284FC
	bl Fx_None                          @ 080284FE
	movs r0, #0x5e                      @ 08028502
	ldrb r1, [r0, r4]                   @ 08028504
	adds r0, r4, #0                     @ 08028506
	adds r0, #0x40                      @ 08028508
	cmp r1, #0                          @ 0802850A
	beq L_08028510                      @ 0802850C
	strb r1, [r0, #0xd]                 @ 0802850E
L_08028510:
	ldrb r3, [r0, #0xa]                 @ 08028510
	lsls r1, r3, #0x1d                  @ 08028512
	lsrs r1, r1, #0x1f                  @ 08028514
	beq L_0802853C                      @ 08028516
	ldrb r1, [r0, #0xd]                 @ 08028518
	movs r5, #2                         @ 0802851A
	lsls r2, r1, #0x18                  @ 0802851C
	lsrs r2, r2, #0x1c                  @ 0802851E
	cmp r2, #0xf                        @ 08028520
	bne L_0802853E                      @ 08028522
	lsls r0, r1, #0x1c                  @ 08028524
	ldr r2, L_08028604                  @ 08028526 =0x0837D2A4
	lsrs r0, r0, #0x1b                  @ 08028528
	ldrh r0, [r2, r0]                   @ 0802852A
	ldr r1, [r4, #0x40]                 @ 0802852C
	muls r1, r0, r1                     @ 0802852E
	lsrs r0, r1, #0x10                  @ 08028530
	str r0, [r4, #0x40]                 @ 08028532
	str r0, [r4, #0x30]                 @ 08028534
	ldrb r0, [r4, #0x10]                @ 08028536
	orrs r0, r5                         @ 08028538
	strb r0, [r4, #0x10]                @ 0802853A
L_0802853C:
	pop {r4, r5, pc}                    @ 0802853C
L_0802853E:
	cmp r2, #0xe                        @ 0802853E
	bne L_0802855E                      @ 08028540
	ldr r2, L_08028604                  @ 08028542 =0x0837D2A4
	lsls r0, r1, #0x1c                  @ 08028544
	lsrs r0, r0, #0x1b                  @ 08028546
	subs r2, #0x80                      @ 08028548
	ldrh r0, [r2, r0]                   @ 0802854A
	ldr r1, [r4, #0x40]                 @ 0802854C
	muls r1, r0, r1                     @ 0802854E
L_08028550:
	lsrs r0, r1, #0x10                  @ 08028550
	str r0, [r4, #0x40]                 @ 08028552
	str r0, [r4, #0x30]                 @ 08028554
	ldrb r0, [r4, #0x10]                @ 08028556
	orrs r0, r5                         @ 08028558
	strb r0, [r4, #0x10]                @ 0802855A
	pop {r4, r5, pc}                    @ 0802855C
L_0802855E:
	ldr r1, L_08028608                  @ 0802855E =0x080284DD
	str r1, [r4, #0x54]                 @ 08028560
	movs r1, #1                         @ 08028562
	orrs r1, r3                         @ 08028564
	strb r1, [r0, #0xa]                 @ 08028566
	pop {r4, r5, pc}                    @ 08028568

@ --------------------------------------------------------------------------------------------
@ tick handler: pitch = pitch * PortaUpTab[speed] >> 14.
	.thumb_func
	.global Tick_PortaUp
Tick_PortaUp:
	movs r1, #0x4d                      @ 0802856A
	ldrb r1, [r1, r0]                   @ 0802856C
	ldr r3, L_0802860C                  @ 0802856E =0x0837D024
	ldr r2, [r0, #0x40]                 @ 08028570
	lsls r1, r1, #1                     @ 08028572
	ldrh r1, [r3, r1]                   @ 08028574
	muls r2, r1, r2                     @ 08028576
	lsrs r1, r2, #0xe                   @ 08028578
	str r1, [r0, #0x40]                 @ 0802857A
	str r1, [r0, #0x30]                 @ 0802857C
	ldrb r1, [r0, #0x10]                @ 0802857E
	movs r2, #2                         @ 08028580
	orrs r1, r2                         @ 08028582
	strb r1, [r0, #0x10]                @ 08028584
	bx lr                               @ 08028586

@ --------------------------------------------------------------------------------------------
@ Fxx portamento up, same encoding as E.
	.thumb_func
	.global Fx_F_PortaUp
Fx_F_PortaUp:
	push {r4, r5, lr}                   @ 08028588
	adds r4, r0, #0                     @ 0802858A
	bl Fx_None                          @ 0802858C
	movs r0, #0x5e                      @ 08028590
	ldrb r1, [r0, r4]                   @ 08028592
	adds r0, r4, #0                     @ 08028594
	adds r0, #0x40                      @ 08028596
	cmp r1, #0                          @ 08028598
	beq L_0802859E                      @ 0802859A
	strb r1, [r0, #0xd]                 @ 0802859C
L_0802859E:
	ldrb r3, [r0, #0xa]                 @ 0802859E
	lsls r1, r3, #0x1d                  @ 080285A0
	lsrs r1, r1, #0x1f                  @ 080285A2
	beq L_080285CA                      @ 080285A4
	ldrb r1, [r0, #0xd]                 @ 080285A6
	movs r5, #2                         @ 080285A8
	lsls r2, r1, #0x18                  @ 080285AA
	lsrs r2, r2, #0x1c                  @ 080285AC
	cmp r2, #0xf                        @ 080285AE
	bne L_080285CC                      @ 080285B0
	lsls r0, r1, #0x1c                  @ 080285B2
	ldr r2, L_0802860C                  @ 080285B4 =0x0837D024
	lsrs r0, r0, #0x1b                  @ 080285B6
	ldrh r0, [r2, r0]                   @ 080285B8
	ldr r1, [r4, #0x40]                 @ 080285BA
	muls r1, r0, r1                     @ 080285BC
	lsrs r0, r1, #0xe                   @ 080285BE
	str r0, [r4, #0x40]                 @ 080285C0
	str r0, [r4, #0x30]                 @ 080285C2
	ldrb r0, [r4, #0x10]                @ 080285C4
	orrs r0, r5                         @ 080285C6
	strb r0, [r4, #0x10]                @ 080285C8
L_080285CA:
	pop {r4, r5, pc}                    @ 080285CA
L_080285CC:
	cmp r2, #0xe                        @ 080285CC
	bne L_080285EC                      @ 080285CE
	ldr r2, L_0802860C                  @ 080285D0 =0x0837D024
	lsls r0, r1, #0x1c                  @ 080285D2
	lsrs r0, r0, #0x1b                  @ 080285D4
	subs r2, #0x80                      @ 080285D6
	ldrh r0, [r2, r0]                   @ 080285D8
	ldr r1, [r4, #0x40]                 @ 080285DA
	muls r1, r0, r1                     @ 080285DC
	lsrs r0, r1, #0xf                   @ 080285DE
	str r0, [r4, #0x40]                 @ 080285E0
	str r0, [r4, #0x30]                 @ 080285E2
	ldrb r0, [r4, #0x10]                @ 080285E4
	orrs r0, r5                         @ 080285E6
	strb r0, [r4, #0x10]                @ 080285E8
	pop {r4, r5, pc}                    @ 080285EA
L_080285EC:
	ldr r1, L_08028610                  @ 080285EC =0x0802856B
	str r1, [r4, #0x54]                 @ 080285EE
	movs r1, #1                         @ 080285F0
	orrs r1, r3                         @ 080285F2
	strb r1, [r0, #0xa]                 @ 080285F4
	pop {r4, r5, pc}                    @ 080285F6
L_080285F8:
	.word NoteFreqTab	@ 0x0837CD44
L_080285FC:
	.word Tick_VolSlideUp	@ 0x0802842B
L_08028600:
	.word Tick_VolSlideDown	@ 0x080283FD
L_08028604:
	.word PortaDownTab	@ 0x0837D2A4
L_08028608:
	.word Tick_PortaDown	@ 0x080284DD
L_0802860C:
	.word PortaUpTab	@ 0x0837D024
L_08028610:
	.word Tick_PortaUp	@ 0x0802856B

@ --------------------------------------------------------------------------------------------
@ tick handler: slide down towards the target, clamp and stop when reached.
	.thumb_func
	.global Tick_TonePortaDown
Tick_TonePortaDown:
	adds r1, r0, #0                     @ 08028614
	adds r1, #0x40                      @ 08028616
	push {r4, r5}                       @ 08028618
	ldrb r2, [r1, #0xd]                 @ 0802861A
	ldr r4, L_08028898                  @ 0802861C =0x0837D2A4
	ldr r3, [r0, #0x40]                 @ 0802861E
	lsls r2, r2, #1                     @ 08028620
	ldrh r2, [r4, r2]                   @ 08028622
	movs r5, #2                         @ 08028624
	muls r3, r2, r3                     @ 08028626
	lsrs r4, r3, #0x10                  @ 08028628
	str r4, [r0, #0x40]                 @ 0802862A
	str r4, [r0, #0x30]                 @ 0802862C
	ldrb r2, [r0, #0x10]                @ 0802862E
	orrs r2, r5                         @ 08028630
	adds r3, r2, #0                     @ 08028632
	strb r3, [r0, #0x10]                @ 08028634
	ldr r2, [r0, #0x44]                 @ 08028636
	cmp r4, r2                          @ 08028638
	bhs L_08028652                      @ 0802863A
	str r2, [r0, #0x40]                 @ 0802863C
	str r2, [r0, #0x30]                 @ 0802863E
	orrs r3, r5                         @ 08028640
	adds r2, r3, #0                     @ 08028642
	strb r2, [r0, #0x10]                @ 08028644
	ldrb r0, [r1, #0xa]                 @ 08028646
	movs r2, #8                         @ 08028648
	bics r0, r2                         @ 0802864A
	lsrs r0, r0, #2                     @ 0802864C
	lsls r0, r0, #2                     @ 0802864E
	strb r0, [r1, #0xa]                 @ 08028650
L_08028652:
	pop {r4, r5}                        @ 08028652
	bx lr                               @ 08028654

@ --------------------------------------------------------------------------------------------
@ tick handler: slide up towards the target, clamp and stop when reached.
	.thumb_func
	.global Tick_TonePortaUp
Tick_TonePortaUp:
	adds r1, r0, #0                     @ 08028656
L_08028658:
	adds r1, #0x40                      @ 08028658
	push {r4, r5}                       @ 0802865A
	ldrb r2, [r1, #0xd]                 @ 0802865C
	ldr r4, L_0802889C                  @ 0802865E =0x0837D024
	ldr r3, [r0, #0x40]                 @ 08028660
	lsls r2, r2, #1                     @ 08028662
	ldrh r2, [r4, r2]                   @ 08028664
	movs r5, #2                         @ 08028666
	muls r3, r2, r3                     @ 08028668
	lsrs r4, r3, #0xe                   @ 0802866A
	str r4, [r0, #0x40]                 @ 0802866C
	str r4, [r0, #0x30]                 @ 0802866E
	ldrb r2, [r0, #0x10]                @ 08028670
	orrs r2, r5                         @ 08028672
	adds r3, r2, #0                     @ 08028674
	strb r3, [r0, #0x10]                @ 08028676
	ldr r2, [r0, #0x44]                 @ 08028678
	cmp r4, r2                          @ 0802867A
	bls L_08028694                      @ 0802867C
	str r2, [r0, #0x40]                 @ 0802867E
	str r2, [r0, #0x30]                 @ 08028680
	orrs r3, r5                         @ 08028682
	adds r2, r3, #0                     @ 08028684
	strb r2, [r0, #0x10]                @ 08028686
	ldrb r0, [r1, #0xa]                 @ 08028688
	movs r2, #8                         @ 0802868A
	bics r0, r2                         @ 0802868C
	lsrs r0, r0, #2                     @ 0802868E
	lsls r0, r0, #2                     @ 08028690
	strb r0, [r1, #0xa]                 @ 08028692
L_08028694:
	pop {r4, r5}                        @ 08028694
	bx lr                               @ 08028696

@ --------------------------------------------------------------------------------------------
@ Gxx tone portamento: a note on this row becomes the target instead of being played;
@ the direction picks Tick_TonePortaUp/Down. Does nothing (not even play the note) if the channel
@ is silent.
	.thumb_func
	.global Fx_G_TonePorta
Fx_G_TonePorta:
	adds r2, r0, #0                     @ 08028698
	adds r2, #0x50                      @ 0802869A
	push {r4, r5, r6}                   @ 0802869C
	ldrb r3, [r2, #0xe]                 @ 0802869E
	adds r1, r0, #0                     @ 080286A0
	adds r1, #0x40                      @ 080286A2
	cmp r3, #0                          @ 080286A4
	beq L_080286AA                      @ 080286A6
	strb r3, [r1, #0xd]                 @ 080286A8
L_080286AA:
	ldrb r3, [r1, #0xa]                 @ 080286AA
	lsls r4, r3, #0x1d                  @ 080286AC
	lsrs r4, r4, #0x1f                  @ 080286AE
	beq L_08028708                      @ 080286B0
	ldrb r5, [r2, #8]                   @ 080286B2
	movs r4, #0x11                      @ 080286B4
	ands r4, r5                         @ 080286B6
	beq L_080286D0                      @ 080286B8
	ldrb r4, [r2, #0xa]                 @ 080286BA
	cmp r4, #0xff                       @ 080286BC
	beq L_080286F4                      @ 080286BE
	ldr r6, L_080288A0                  @ 080286C0 =0x0837CD44
	lsls r4, r4, #2                     @ 080286C2
	ldr r4, [r6, r4]                    @ 080286C4
	str r4, [r0, #0x44]                 @ 080286C6
	movs r4, #8                         @ 080286C8
	orrs r3, r4                         @ 080286CA
	strb r3, [r1, #0xa]                 @ 080286CC
	b L_080286D4                        @ 080286CE
L_080286D0:
	lsls r3, r3, #0x1c                  @ 080286D0
	bpl L_080286F4                      @ 080286D2
L_080286D4:
	ldr r3, [r0, #0x44]                 @ 080286D4
	ldr r6, [r0, #0x40]                 @ 080286D6
	movs r4, #1                         @ 080286D8
	cmp r3, r6                          @ 080286DA
	bls L_080286EA                      @ 080286DC
	ldr r3, L_080288A4                  @ 080286DE =0x08028657
	str r3, [r0, #0x54]                 @ 080286E0
	ldrb r3, [r1, #0xa]                 @ 080286E2
	orrs r3, r4                         @ 080286E4
	strb r3, [r1, #0xa]                 @ 080286E6
	b L_080286F4                        @ 080286E8
L_080286EA:
	ldr r3, L_080288A8                  @ 080286EA =0x08028615
	str r3, [r0, #0x54]                 @ 080286EC
	ldrb r3, [r1, #0xa]                 @ 080286EE
	orrs r3, r4                         @ 080286F0
	strb r3, [r1, #0xa]                 @ 080286F2
L_080286F4:
	movs r3, #0x44                      @ 080286F4
	ands r5, r3                         @ 080286F6
	beq L_08028708                      @ 080286F8
	ldrb r2, [r2, #0xc]                 @ 080286FA
	strb r2, [r1, #8]                   @ 080286FC
	strb r2, [r0, #0x12]                @ 080286FE
	ldrb r1, [r0, #0x10]                @ 08028700
	movs r2, #0x10                      @ 08028702
	orrs r1, r2                         @ 08028704
	strb r1, [r0, #0x10]                @ 08028706
L_08028708:
	pop {r4, r5, r6}                    @ 08028708
	bx lr                               @ 0802870A

@ --------------------------------------------------------------------------------------------
@ tick handler: phase += speed; offset = VibratoSine[phase] * depth >> 6 (1/64 semitone units);
@ voice pitch = channel pitch scaled by PortaFineUpTab/PortaFineDownTab[|offset|]. The channel's own
@ pitch is not changed, Mus_ChannelRow restores it on the next row.
	.thumb_func
	.global Tick_Vibrato
Tick_Vibrato:
	adds r1, r0, #0                     @ 0802870C
	adds r1, #0x50                      @ 0802870E
	movs r3, #0x4f                      @ 08028710
	ldrb r3, [r3, r0]                   @ 08028712
	ldrb r2, [r1, #1]                   @ 08028714
	adds r2, r2, r3                     @ 08028716
	lsls r2, r2, #0x1a                  @ 08028718
	lsrs r2, r2, #0x1a                  @ 0802871A
	strb r2, [r1, #1]                   @ 0802871C
	ldr r3, L_080288AC                  @ 0802871E =0x0837D4A4
	ldrb r1, [r1]                       @ 08028720
	ldrsb r2, [r3, r2]                  @ 08028722
	muls r1, r2, r1                     @ 08028724
	asrs r1, r1, #6                     @ 08028726
	ldr r2, [r0, #0x40]                 @ 08028728
	bpl L_0802873C                      @ 0802872A
	ldr r3, L_08028898                  @ 0802872C =0x0837D2A4
	lsls r1, r1, #1                     @ 0802872E
	subs r3, #0x80                      @ 08028730
	subs r1, r3, r1                     @ 08028732
	ldrh r1, [r1]                       @ 08028734
	muls r2, r1, r2                     @ 08028736
	lsrs r1, r2, #0x10                  @ 08028738
	b L_08028748                        @ 0802873A
L_0802873C:
	ldr r3, L_0802889C                  @ 0802873C =0x0837D024
	lsls r1, r1, #1                     @ 0802873E
	subs r3, #0x80                      @ 08028740
	ldrh r1, [r3, r1]                   @ 08028742
	muls r2, r1, r2                     @ 08028744
	lsrs r1, r2, #0xf                   @ 08028746
L_08028748:
	str r1, [r0, #0x30]                 @ 08028748
	ldrb r1, [r0, #0x10]                @ 0802874A
	movs r2, #2                         @ 0802874C
	orrs r1, r2                         @ 0802874E
	strb r1, [r0, #0x10]                @ 08028750
	bx lr                               @ 08028752

@ --------------------------------------------------------------------------------------------
@ Hxy vibrato: speed x, depth y*4 (zero nibbles keep the old value).
	.thumb_func
	.global Fx_H_Vibrato
Fx_H_Vibrato:
	push {r4, r5, lr}                   @ 08028754
	adds r4, r0, #0                     @ 08028756
	bl Fx_None                          @ 08028758
	adds r2, r4, #0                     @ 0802875C
	adds r2, #0x40                      @ 0802875E
	ldrb r3, [r2, #0xa]                 @ 08028760
	lsls r0, r3, #0x1d                  @ 08028762
	lsrs r0, r0, #0x1f                  @ 08028764
	beq L_0802879E                      @ 08028766
	adds r0, r4, #0                     @ 08028768
	adds r0, #0x50                      @ 0802876A
	ldrb r1, [r0, #8]                   @ 0802876C
	movs r5, #0x11                      @ 0802876E
	ands r1, r5                         @ 08028770
	beq L_08028778                      @ 08028772
	movs r1, #0                         @ 08028774
	strb r1, [r0, #1]                   @ 08028776
L_08028778:
	ldrb r1, [r0, #0xe]                 @ 08028778
	lsls r5, r1, #0x1c                  @ 0802877A
	beq L_08028784                      @ 0802877C
	lsls r5, r1, #0x1c                  @ 0802877E
	lsrs r5, r5, #0x1a                  @ 08028780
	strb r5, [r0]                       @ 08028782
L_08028784:
	lsls r0, r1, #0x18                  @ 08028784
	lsrs r0, r0, #0x1c                  @ 08028786
	beq L_0802878E                      @ 08028788
	lsrs r0, r1, #4                     @ 0802878A
	strb r0, [r2, #0xf]                 @ 0802878C
L_0802878E:
	ldr r0, L_080288B0                  @ 0802878E =0x0802870D
	str r0, [r4, #0x54]                 @ 08028790
	movs r0, #1                         @ 08028792
	orrs r0, r3                         @ 08028794
	strb r0, [r2, #0xa]                 @ 08028796
	adds r0, r4, #0                     @ 08028798
	bl Tick_Vibrato                     @ 0802879A
L_0802879E:
	pop {r4, r5, pc}                    @ 0802879E

@ --------------------------------------------------------------------------------------------
@ empty functions: unreferenced (the converter maps unsupported effects to Fx_None)
	.thumb_func
	.global Fx_Empty1
Fx_Empty1:
	bx lr                               @ 080287A0
	.thumb_func
	.global Fx_Empty2
Fx_Empty2:
	bx lr                               @ 080287A2

@ --------------------------------------------------------------------------------------------
@ tick handler for K: volume slide down + vibrato.
	.thumb_func
	.global Tick_VibratoVolDown
Tick_VibratoVolDown:
	adds r1, r0, #0                     @ 080287A4
	adds r1, #0x40                      @ 080287A6
	ldrb r2, [r1, #8]                   @ 080287A8
	ldrb r3, [r1, #0xb]                 @ 080287AA
	subs r2, r2, r3                     @ 080287AC
	lsls r2, r2, #0x18                  @ 080287AE
	asrs r2, r2, #0x18                  @ 080287B0
	strb r2, [r1, #8]                   @ 080287B2
	cmp r2, #0                          @ 080287B4
	bgt L_080287C0                      @ 080287B6
	movs r2, #0                         @ 080287B8
	strb r2, [r1, #8]                   @ 080287BA
	ldr r2, L_080288B0                  @ 080287BC =0x0802870D
	str r2, [r0, #0x54]                 @ 080287BE
L_080287C0:
	ldrb r1, [r1, #8]                   @ 080287C0
	movs r2, #0x10                      @ 080287C2
	strb r1, [r0, #0x12]                @ 080287C4
	ldrb r1, [r0, #0x10]                @ 080287C6
	orrs r1, r2                         @ 080287C8
	strb r1, [r0, #0x10]                @ 080287CA
	b Tick_Vibrato                      @ 080287CC

@ --------------------------------------------------------------------------------------------
@ tick handler for K: volume slide up + vibrato.
	.thumb_func
	.global Tick_VibratoVolUp
Tick_VibratoVolUp:
	adds r1, r0, #0                     @ 080287CE
	adds r1, #0x40                      @ 080287D0
	ldrb r2, [r1, #8]                   @ 080287D2
	ldrb r3, [r1, #0xb]                 @ 080287D4
	adds r2, r2, r3                     @ 080287D6
	lsls r2, r2, #0x18                  @ 080287D8
	asrs r2, r2, #0x18                  @ 080287DA
	strb r2, [r1, #8]                   @ 080287DC
	cmp r2, #0x40                       @ 080287DE
	blt L_080287EA                      @ 080287E0
	movs r2, #0x40                      @ 080287E2
L_080287E4:
	strb r2, [r1, #8]                   @ 080287E4
	ldr r2, L_080288B0                  @ 080287E6 =0x0802870D
	str r2, [r0, #0x54]                 @ 080287E8
L_080287EA:
	ldrb r1, [r1, #8]                   @ 080287EA
	movs r2, #0x10                      @ 080287EC
	strb r1, [r0, #0x12]                @ 080287EE
	ldrb r1, [r0, #0x10]                @ 080287F0
	orrs r1, r2                         @ 080287F2
	strb r1, [r0, #0x10]                @ 080287F4
	b Tick_Vibrato                      @ 080287F6

@ --------------------------------------------------------------------------------------------
@ Kxy: continue vibrato with volume slide xy (D rules).
	.thumb_func
	.global Fx_K_VibratoVolSlide
Fx_K_VibratoVolSlide:
	push {r4, r5, r6, lr}               @ 080287F8
	adds r5, r0, #0                     @ 080287FA
	bl Fx_None                          @ 080287FC
	adds r0, r5, #0                     @ 08028800
	adds r0, #0x50                      @ 08028802
	ldrb r1, [r0, #0xe]                 @ 08028804
	adds r4, r5, #0                     @ 08028806
	adds r4, #0x40                      @ 08028808
	cmp r1, #0                          @ 0802880A
	beq L_08028810                      @ 0802880C
	strb r1, [r4, #0xc]                 @ 0802880E
L_08028810:
	ldrb r1, [r4, #0xa]                 @ 08028810
	lsls r1, r1, #0x1d                  @ 08028812
	lsrs r1, r1, #0x1f                  @ 08028814
	beq L_08028894                      @ 08028816
	ldrb r1, [r0, #8]                   @ 08028818
	movs r2, #0x11                      @ 0802881A
	ands r1, r2                         @ 0802881C
	beq L_08028824                      @ 0802881E
	movs r1, #0                         @ 08028820
	strb r1, [r0, #1]                   @ 08028822
L_08028824:
	ldrb r0, [r4, #0xc]                 @ 08028824
	lsls r1, r0, #0x1c                  @ 08028826
	bne L_08028840                      @ 08028828
	lsrs r0, r0, #4                     @ 0802882A
	strb r0, [r4, #0xb]                 @ 0802882C
	ldr r0, L_080288B4                  @ 0802882E =0x080287CF
	str r0, [r5, #0x54]                 @ 08028830
	ldrb r0, [r4, #0xb]                 @ 08028832
	cmp r0, #0xf                        @ 08028834
	bne L_08028886                      @ 08028836
	adds r0, r5, #0                     @ 08028838
	bl Tick_VolSlideUp                  @ 0802883A
	b L_08028886                        @ 0802883E
L_08028840:
	lsls r1, r0, #0x18                  @ 08028840
	lsrs r2, r1, #0x1c                  @ 08028842
	bne L_0802885C                      @ 08028844
	ldrb r0, [r4, #0xc]                 @ 08028846
	strb r0, [r4, #0xb]                 @ 08028848
	ldr r0, L_080288B8                  @ 0802884A =0x080287A5
	str r0, [r5, #0x54]                 @ 0802884C
	ldrb r0, [r4, #0xb]                 @ 0802884E
	cmp r0, #0xf                        @ 08028850
	bne L_08028886                      @ 08028852
	adds r0, r5, #0                     @ 08028854
	bl Tick_VolSlideDown                @ 08028856
	b L_08028886                        @ 0802885A
L_0802885C:
	movs r2, #0xf                       @ 0802885C
	bics r2, r0                         @ 0802885E
	cmp r2, #0                          @ 08028860
	ldr r6, L_080288B0                  @ 08028862 =0x0802870D
	bne L_08028874                      @ 08028864
	lsrs r0, r0, #4                     @ 08028866
	strb r0, [r4, #0xb]                 @ 08028868
	adds r0, r5, #0                     @ 0802886A
	bl Tick_VolSlideUp                  @ 0802886C
	str r6, [r5, #0x54]                 @ 08028870
	b L_08028886                        @ 08028872
L_08028874:
	lsrs r1, r1, #0x1c                  @ 08028874
	cmp r1, #0xf                        @ 08028876
	bne L_08028886                      @ 08028878
	ands r0, r1                         @ 0802887A
	strb r0, [r4, #0xb]                 @ 0802887C
	adds r0, r5, #0                     @ 0802887E
	bl Tick_VolSlideDown                @ 08028880
	str r6, [r5, #0x54]                 @ 08028884
L_08028886:
	ldrb r0, [r4, #0xa]                 @ 08028886
	movs r1, #1                         @ 08028888
	orrs r0, r1                         @ 0802888A
	strb r0, [r4, #0xa]                 @ 0802888C
	adds r0, r5, #0                     @ 0802888E
	bl Tick_Vibrato                     @ 08028890
L_08028894:
	pop {r4, r5, r6, pc}                @ 08028894
	movs r0, r0                         @ 08028896
L_08028898:
	.word PortaDownTab	@ 0x0837D2A4
L_0802889C:
	.word PortaUpTab	@ 0x0837D024
L_080288A0:
	.word NoteFreqTab	@ 0x0837CD44
L_080288A4:
	.word Tick_TonePortaUp	@ 0x08028657
L_080288A8:
	.word Tick_TonePortaDown	@ 0x08028615
L_080288AC:
	.word VibratoSine	@ 0x0837D4A4
L_080288B0:
	.word Tick_Vibrato	@ 0x0802870D
L_080288B4:
	.word Tick_VibratoVolUp	@ 0x080287CF
L_080288B8:
	.word Tick_VibratoVolDown	@ 0x080287A5

@ --------------------------------------------------------------------------------------------
@ Lxy: continue tone portamento with volume slide xy (D rules); the tick handler is
@ picked from TonePortaVolTicks[direction*3 + slide kind].
	.thumb_func
	.global Fx_L_TonePortaVolSlide
Fx_L_TonePortaVolSlide:
	push {r4, r5, r6, r7, lr}           @ 080288BC
	adds r7, r0, #0                     @ 080288BE
	adds r7, #0x50                      @ 080288C0
	adds r5, r0, #0                     @ 080288C2
	ldrb r0, [r7, #0xe]                 @ 080288C4
	adds r4, r5, #0                     @ 080288C6
	adds r4, #0x40                      @ 080288C8
	cmp r0, #0                          @ 080288CA
	beq L_080288D0                      @ 080288CC
	strb r0, [r4, #0xc]                 @ 080288CE
L_080288D0:
	ldrb r0, [r4, #0xa]                 @ 080288D0
	lsls r0, r0, #0x1d                  @ 080288D2
	lsrs r0, r0, #0x1f                  @ 080288D4
	beq L_0802899A                      @ 080288D6
	ldrb r0, [r7, #8]                   @ 080288D8
	movs r6, #0                         @ 080288DA
	movs r1, #0x44                      @ 080288DC
	ands r0, r1                         @ 080288DE
	beq L_080288F0                      @ 080288E0
	ldrb r0, [r7, #0xc]                 @ 080288E2
	movs r1, #0x10                      @ 080288E4
	strb r0, [r4, #8]                   @ 080288E6
L_080288E8:
	strb r0, [r5, #0x12]                @ 080288E8
	ldrb r0, [r5, #0x10]                @ 080288EA
	orrs r0, r1                         @ 080288EC
	strb r0, [r5, #0x10]                @ 080288EE
L_080288F0:
	ldrb r0, [r4, #0xc]                 @ 080288F0
	lsls r1, r0, #0x1c                  @ 080288F2
	bne L_0802890A                      @ 080288F4
	lsrs r0, r0, #4                     @ 080288F6
	strb r0, [r4, #0xb]                 @ 080288F8
	ldrb r0, [r4, #0xb]                 @ 080288FA
	movs r6, #1                         @ 080288FC
	cmp r0, #0xf                        @ 080288FE
	bne L_08028946                      @ 08028900
	adds r0, r5, #0                     @ 08028902
	bl Tick_VolSlideUp                  @ 08028904
	b L_08028946                        @ 08028908
L_0802890A:
	lsls r1, r0, #0x18                  @ 0802890A
	lsrs r2, r1, #0x1c                  @ 0802890C
	bne L_08028924                      @ 0802890E
	ldrb r0, [r4, #0xc]                 @ 08028910
	movs r6, #2                         @ 08028912
	strb r0, [r4, #0xb]                 @ 08028914
	ldrb r0, [r4, #0xb]                 @ 08028916
	cmp r0, #0xf                        @ 08028918
	bne L_08028946                      @ 0802891A
	adds r0, r5, #0                     @ 0802891C
	bl Tick_VolSlideDown                @ 0802891E
	b L_08028946                        @ 08028922
L_08028924:
	movs r2, #0xf                       @ 08028924
	bics r2, r0                         @ 08028926
	bne L_08028936                      @ 08028928
	lsrs r0, r0, #4                     @ 0802892A
	strb r0, [r4, #0xb]                 @ 0802892C
	adds r0, r5, #0                     @ 0802892E
	bl Tick_VolSlideUp                  @ 08028930
	b L_08028946                        @ 08028934
L_08028936:
	lsrs r1, r1, #0x1c                  @ 08028936
	cmp r1, #0xf                        @ 08028938
	bne L_08028946                      @ 0802893A
	ands r0, r1                         @ 0802893C
	strb r0, [r4, #0xb]                 @ 0802893E
	adds r0, r5, #0                     @ 08028940
	bl Tick_VolSlideDown                @ 08028942
L_08028946:
	ldrb r1, [r7, #8]                   @ 08028946
	movs r0, #0x11                      @ 08028948
	ands r1, r0                         @ 0802894A
	movs r0, #1                         @ 0802894C
	cmp r1, #0                          @ 0802894E
	beq L_0802896A                      @ 08028950
	ldrb r1, [r7, #0xa]                 @ 08028952
	cmp r1, #0xff                       @ 08028954
	beq L_0802899A                      @ 08028956
	ldr r2, L_08028BE0                  @ 08028958 =0x0837CD44
	lsls r1, r1, #2                     @ 0802895A
	ldr r1, [r2, r1]                    @ 0802895C
	movs r2, #8                         @ 0802895E
	str r1, [r5, #0x44]                 @ 08028960
	ldrb r1, [r4, #0xa]                 @ 08028962
	orrs r1, r2                         @ 08028964
	strb r1, [r4, #0xa]                 @ 08028966
	b L_08028984                        @ 08028968
L_0802896A:
	ldrb r1, [r4, #0xa]                 @ 0802896A
	lsls r2, r1, #0x1c                  @ 0802896C
	bmi L_08028984                      @ 0802896E
	cmp r6, #0                          @ 08028970
	beq L_08028984                      @ 08028972
	cmp r6, #1                          @ 08028974
	beq L_0802899C                      @ 08028976
	cmp r6, #2                          @ 08028978
	bne L_08028984                      @ 0802897A
	ldr r2, L_08028BE4                  @ 0802897C =0x080283FD
	orrs r1, r0                         @ 0802897E
	str r2, [r5, #0x54]                 @ 08028980
	strb r1, [r4, #0xa]                 @ 08028982
L_08028984:
	ldr r1, [r5, #0x44]                 @ 08028984
	ldr r2, [r5, #0x40]                 @ 08028986
	cmp r1, r2                          @ 08028988
	bls L_080289A6                      @ 0802898A
	ldr r2, L_08028BE8                  @ 0802898C =0x0837D4E4
	lsls r1, r6, #2                     @ 0802898E
	ldr r1, [r2, r1]                    @ 08028990
	str r1, [r5, #0x54]                 @ 08028992
	ldrb r1, [r4, #0xa]                 @ 08028994
	orrs r0, r1                         @ 08028996
	strb r0, [r4, #0xa]                 @ 08028998
L_0802899A:
	pop {r4, r5, r6, r7, pc}            @ 0802899A
L_0802899C:
	ldr r2, L_08028BEC                  @ 0802899C =0x0802842B
	orrs r1, r0                         @ 0802899E
	str r2, [r5, #0x54]                 @ 080289A0
	strb r1, [r4, #0xa]                 @ 080289A2
	b L_08028984                        @ 080289A4
L_080289A6:
	ldr r2, L_08028BE8                  @ 080289A6 =0x0837D4E4
	lsls r1, r6, #2                     @ 080289A8
	adds r2, #0xc                       @ 080289AA
	ldr r1, [r2, r1]                    @ 080289AC
	str r1, [r5, #0x54]                 @ 080289AE
	ldrb r1, [r4, #0xa]                 @ 080289B0
	orrs r0, r1                         @ 080289B2
	strb r0, [r4, #0xa]                 @ 080289B4
	pop {r4, r5, r6, r7, pc}            @ 080289B6
	.thumb_func
	.global Fx_Empty3
Fx_Empty3:
	bx lr                               @ 080289B8
	.thumb_func
	.global Fx_Empty4
Fx_Empty4:
	bx lr                               @ 080289BA

@ --------------------------------------------------------------------------------------------
@ Oxx: start the sample at offset xx*256 bytes.
	.thumb_func
	.global Fx_O_SampleOffset
Fx_O_SampleOffset:
	push {r4, lr}                       @ 080289BC
	adds r4, r0, #0                     @ 080289BE
	bl Fx_None                          @ 080289C0
	adds r0, r4, #0                     @ 080289C4
	adds r0, #0x50                      @ 080289C6
	ldrb r1, [r0, #8]                   @ 080289C8
	movs r2, #0x11                      @ 080289CA
	ands r1, r2                         @ 080289CC
	beq L_080289E4                      @ 080289CE
	ldrb r0, [r0, #0xe]                 @ 080289D0
	movs r1, #4                         @ 080289D2
	lsls r0, r0, #0x16                  @ 080289D4
	str r0, [r4]                        @ 080289D6
	ldrb r0, [r4, #0x10]                @ 080289D8
	bics r0, r1                         @ 080289DA
	strb r0, [r4, #0x10]                @ 080289DC
	ldrb r0, [r4, #0x11]                @ 080289DE
	bics r0, r1                         @ 080289E0
	strb r0, [r4, #0x11]                @ 080289E2
L_080289E4:
	pop {r4, pc}                        @ 080289E4
	.thumb_func
	.global Fx_Empty5
Fx_Empty5:
	bx lr                               @ 080289E6

@ --------------------------------------------------------------------------------------------
@ tick handler: when the counter runs out restart the voice and reload the counter
@ (flags |= 4: unlike version 1 the tick mode survives, so the retrigger repeats).
	.thumb_func
	.global Tick_Retrig
Tick_Retrig:
	adds r1, r0, #0                     @ 080289E8
	adds r1, #0x50                      @ 080289EA
	ldrb r2, [r1, #2]                   @ 080289EC
	adds r2, #0xff                      @ 080289EE
	lsls r2, r2, #0x18                  @ 080289F0
	lsrs r2, r2, #0x18                  @ 080289F2
	strb r2, [r1, #2]                   @ 080289F4
	bne L_08028A12                      @ 080289F6
	ldrb r2, [r0, #0x10]                @ 080289F8
	movs r3, #5                         @ 080289FA
	orrs r2, r3                         @ 080289FC
	strb r2, [r0, #0x10]                @ 080289FE
	adds r0, #0x40                      @ 08028A00
	ldrb r2, [r0, #0xe]                 @ 08028A02
	lsls r2, r2, #0x1c                  @ 08028A04
	lsrs r2, r2, #0x1c                  @ 08028A06
	strb r2, [r1, #2]                   @ 08028A08
	ldrb r1, [r0, #0xa]                 @ 08028A0A
	movs r2, #4                         @ 08028A0C
	orrs r1, r2                         @ 08028A0E
	strb r1, [r0, #0xa]                 @ 08028A10
L_08028A12:
	bx lr                               @ 08028A12

@ --------------------------------------------------------------------------------------------
@ Qxy retrigger every y ticks (tick mode 2). The volume nibble x is ignored.
	.thumb_func
	.global Fx_Q_Retrig
Fx_Q_Retrig:
	push {r4, lr}                       @ 08028A14
	adds r4, r0, #0                     @ 08028A16
	bl Fx_None                          @ 08028A18
	adds r2, r4, #0                     @ 08028A1C
	adds r2, #0x50                      @ 08028A1E
	ldrb r1, [r2, #0xe]                 @ 08028A20
	adds r0, r4, #0                     @ 08028A22
	adds r0, #0x40                      @ 08028A24
	cmp r1, #0                          @ 08028A26
	beq L_08028A2C                      @ 08028A28
	strb r1, [r0, #0xe]                 @ 08028A2A
L_08028A2C:
	ldr r1, L_08028BF0                  @ 08028A2C =0x080289E9
	str r1, [r4, #0x54]                 @ 08028A2E
	ldrb r1, [r0, #0xe]                 @ 08028A30
	lsls r1, r1, #0x1c                  @ 08028A32
	lsrs r1, r1, #0x1c                  @ 08028A34
	strb r1, [r2, #2]                   @ 08028A36
	ldrb r1, [r0, #0xa]                 @ 08028A38
	lsrs r1, r1, #2                     @ 08028A3A
	lsls r1, r1, #2                     @ 08028A3C
	adds r1, #2                         @ 08028A3E
	strb r1, [r0, #0xa]                 @ 08028A40
	pop {r4, pc}                        @ 08028A42
	.thumb_func
	.global Fx_Empty6
Fx_Empty6:
	bx lr                               @ 08028A44
	.thumb_func
	.global Fx_Empty7
Fx_Empty7:
	bx lr                               @ 08028A46

@ --------------------------------------------------------------------------------------------
@ tick handler: after the delay runs out, trigger the row's note (Fx_None).
	.thumb_func
	.global Tick_NoteDelay
Tick_NoteDelay:
	adds r1, r0, #0                     @ 08028A48
	adds r1, #0x50                      @ 08028A4A
	push {lr}                           @ 08028A4C
	ldrb r2, [r1, #2]                   @ 08028A4E
	adds r2, #0xff                      @ 08028A50
	lsls r2, r2, #0x18                  @ 08028A52
	lsrs r2, r2, #0x18                  @ 08028A54
	strb r2, [r1, #2]                   @ 08028A56
	bne L_08028A5E                      @ 08028A58
	bl Fx_None                          @ 08028A5A
L_08028A5E:
	pop {pc}                            @ 08028A5E

@ --------------------------------------------------------------------------------------------
@ effect 27: note delay - play the row's note after xx ticks (the converter's SDx).
	.thumb_func
	.global Fx_NoteDelay
Fx_NoteDelay:
	adds r1, r0, #0                     @ 08028A60
	adds r1, #0x50                      @ 08028A62
	ldrb r2, [r1, #0xe]                 @ 08028A64
	strb r2, [r1, #2]                   @ 08028A66
	ldr r1, L_08028BF4                  @ 08028A68 =0x08028A49
	str r1, [r0, #0x54]                 @ 08028A6A
	adds r0, #0x40                      @ 08028A6C
	ldrb r1, [r0, #0xa]                 @ 08028A6E
	lsrs r1, r1, #2                     @ 08028A70
	lsls r1, r1, #2                     @ 08028A72
	adds r1, #2                         @ 08028A74
	strb r1, [r0, #0xa]                 @ 08028A76
	bx lr                               @ 08028A78

@ --------------------------------------------------------------------------------------------
@ void Player_SetTempo(Player *p, int bpm): samples per tick = 40000 / bpm (16 kHz * 2.5).
	.thumb_func
	.global Player_SetTempo
Player_SetTempo:
	push {r4, lr}                       @ 08028A7A
	adds r4, r0, #0                     @ 08028A7C
	strb r1, [r4, #4]                   @ 08028A7E
	adds r0, r1, #0                     @ 08028A80
	ldr r1, L_08028BF8                  @ 08028A82 =0x00009C40
	bl __rt_udiv                        @ 08028A84
	strh r0, [r4, #6]                   @ 08028A88
	pop {r4, pc}                        @ 08028A8A

@ --------------------------------------------------------------------------------------------
@ Txx: tempo xx BPM (samples per tick = 40000/xx).
	.thumb_func
	.global Fx_T_SetTempo
Fx_T_SetTempo:
	push {r3, r4, r5, lr}               @ 08028A8C
	adds r5, r0, #0                     @ 08028A8E
	bl Fx_None                          @ 08028A90
	ldr r0, L_08028BE0                  @ 08028A94 =0x0837CD44
	ldr r1, L_08028BF8                  @ 08028A96 =0x00009C40
	subs r0, #4                         @ 08028A98
	ldr r4, [r0]                        @ 08028A9A
	adds r5, #0x50                      @ 08028A9C
	ldrb r0, [r5, #0xe]                 @ 08028A9E
	strb r0, [r4, #4]                   @ 08028AA0
	bl __rt_udiv                        @ 08028AA2
	strh r0, [r4, #6]                   @ 08028AA6
	pop {r3, r4, r5, pc}                @ 08028AA8

@ --------------------------------------------------------------------------------------------
@ Uxy fine vibrato: like H but depth y (4x finer).
	.thumb_func
	.global Fx_U_FineVibrato
Fx_U_FineVibrato:
	push {r4, lr}                       @ 08028AAA
	adds r4, r0, #0                     @ 08028AAC
	bl Fx_None                          @ 08028AAE
	adds r0, r4, #0                     @ 08028AB2
	adds r0, #0x50                      @ 08028AB4
	ldrb r1, [r0, #8]                   @ 08028AB6
	movs r2, #0x11                      @ 08028AB8
	ands r1, r2                         @ 08028ABA
	beq L_08028AC2                      @ 08028ABC
	movs r1, #0                         @ 08028ABE
	strb r1, [r0, #1]                   @ 08028AC0
L_08028AC2:
	ldrb r1, [r0, #0xe]                 @ 08028AC2
	lsls r2, r1, #0x1c                  @ 08028AC4
	beq L_08028ACE                      @ 08028AC6
	lsls r2, r1, #0x1c                  @ 08028AC8
	lsrs r2, r2, #0x1c                  @ 08028ACA
	strb r2, [r0]                       @ 08028ACC
L_08028ACE:
	lsls r0, r1, #0x18                  @ 08028ACE
	lsrs r2, r0, #0x1c                  @ 08028AD0
	adds r0, r4, #0                     @ 08028AD2
	adds r0, #0x40                      @ 08028AD4
	cmp r2, #0                          @ 08028AD6
	beq L_08028ADE                      @ 08028AD8
	lsrs r1, r1, #4                     @ 08028ADA
	strb r1, [r0, #0xf]                 @ 08028ADC
L_08028ADE:
	ldr r1, L_08028BFC                  @ 08028ADE =0x0802870D
	movs r2, #1                         @ 08028AE0
	str r1, [r4, #0x54]                 @ 08028AE2
	ldrb r1, [r0, #0xa]                 @ 08028AE4
	orrs r1, r2                         @ 08028AE6
	strb r1, [r0, #0xa]                 @ 08028AE8
	adds r0, r4, #0                     @ 08028AEA
	bl Tick_Vibrato                     @ 08028AEC
	pop {r4, pc}                        @ 08028AF0
	.thumb_func
	.global Fx_Empty8
Fx_Empty8:
	bx lr                               @ 08028AF2
	.thumb_func
	.global Fx_Empty9
Fx_Empty9:
	bx lr                               @ 08028AF4

@ --------------------------------------------------------------------------------------------
@ Xxx: panning, signed -64 (left) .. +64 (right).
	.thumb_func
	.global Fx_X_SetPanning
Fx_X_SetPanning:
	push {r4, lr}                       @ 08028AF6
	adds r4, r0, #0                     @ 08028AF8
	bl Fx_None                          @ 08028AFA
	movs r0, #0x5e                      @ 08028AFE
	ldrb r0, [r0, r4]                   @ 08028B00
	movs r1, #0x49                      @ 08028B02
	strb r0, [r1, r4]                   @ 08028B04
	strb r0, [r4, #0x13]                @ 08028B06
	ldrb r0, [r4, #0x10]                @ 08028B08
	movs r1, #0x10                      @ 08028B0A
	orrs r0, r1                         @ 08028B0C
	strb r0, [r4, #0x10]                @ 08028B0E
	pop {r4, pc}                        @ 08028B10
	.thumb_func
	.global Fx_Empty10
Fx_Empty10:
	bx lr                               @ 08028B12
	.thumb_func
	.global Fx_Empty11
Fx_Empty11:
	bx lr                               @ 08028B14

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento up + volume up. NOTE: when the volume reaches 64 it switches to
@ Tick_TonePortaDown (not ...Up), which snaps the pitch straight to the target.
	.thumb_func
	.global Tick_TonePortaUpVolUp
Tick_TonePortaUpVolUp:
	adds r1, r0, #0                     @ 08028B16
	adds r1, #0x40                      @ 08028B18
	push {r4, r5, lr}                   @ 08028B1A
	ldrb r2, [r1, #0xd]                 @ 08028B1C
	ldr r4, L_08028C00                  @ 08028B1E =0x0837D024
	ldr r3, [r0, #0x40]                 @ 08028B20
	lsls r2, r2, #1                     @ 08028B22
	ldrh r2, [r4, r2]                   @ 08028B24
	movs r5, #2                         @ 08028B26
	muls r3, r2, r3                     @ 08028B28
	lsrs r4, r3, #0xe                   @ 08028B2A
	str r4, [r0, #0x40]                 @ 08028B2C
	str r4, [r0, #0x30]                 @ 08028B2E
	ldrb r2, [r0, #0x10]                @ 08028B30
	orrs r2, r5                         @ 08028B32
	strb r2, [r0, #0x10]                @ 08028B34
	ldr r3, [r0, #0x44]                 @ 08028B36
	cmp r4, r3                          @ 08028B38
	bhs L_08028B56                      @ 08028B3A
	str r3, [r0, #0x40]                 @ 08028B3C
	str r3, [r0, #0x30]                 @ 08028B3E
	orrs r2, r5                         @ 08028B40
	strb r2, [r0, #0x10]                @ 08028B42
	ldrb r2, [r1, #0xa]                 @ 08028B44
	movs r3, #8                         @ 08028B46
	bics r2, r3                         @ 08028B48
	strb r2, [r1, #0xa]                 @ 08028B4A
	ldr r1, L_08028BEC                  @ 08028B4C =0x0802842B
	str r1, [r0, #0x54]                 @ 08028B4E
	bl Tick_VolSlideUp                  @ 08028B50
L_08028B54:
	pop {r4, r5, pc}                    @ 08028B54
L_08028B56:
	ldrb r3, [r1, #8]                   @ 08028B56
	ldrb r4, [r1, #0xb]                 @ 08028B58
	adds r3, r3, r4                     @ 08028B5A
	lsls r3, r3, #0x18                  @ 08028B5C
	asrs r3, r3, #0x18                  @ 08028B5E
	strb r3, [r1, #8]                   @ 08028B60
	cmp r3, #0x40                       @ 08028B62
	blt L_08028B6E                      @ 08028B64
	movs r3, #0x40                      @ 08028B66
	strb r3, [r1, #8]                   @ 08028B68
	ldr r3, L_08028C04                  @ 08028B6A =0x08028615
	str r3, [r0, #0x54]                 @ 08028B6C
L_08028B6E:
	ldrb r1, [r1, #8]                   @ 08028B6E
	strb r1, [r0, #0x12]                @ 08028B70
	movs r1, #0x10                      @ 08028B72
	orrs r1, r2                         @ 08028B74
	strb r1, [r0, #0x10]                @ 08028B76
	pop {r4, r5, pc}                    @ 08028B78

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento down + volume up.
	.thumb_func
	.global Tick_TonePortaDownVolUp
Tick_TonePortaDownVolUp:
	adds r1, r0, #0                     @ 08028B7A
	adds r1, #0x40                      @ 08028B7C
	push {r4, r5, lr}                   @ 08028B7E
	ldrb r2, [r1, #0xd]                 @ 08028B80
	ldr r4, L_08028C08                  @ 08028B82 =0x0837D2A4
	ldr r3, [r0, #0x40]                 @ 08028B84
	lsls r2, r2, #1                     @ 08028B86
	ldrh r2, [r4, r2]                   @ 08028B88
	movs r5, #2                         @ 08028B8A
	muls r3, r2, r3                     @ 08028B8C
	lsrs r4, r3, #0x10                  @ 08028B8E
	str r4, [r0, #0x40]                 @ 08028B90
	str r4, [r0, #0x30]                 @ 08028B92
	ldrb r2, [r0, #0x10]                @ 08028B94
	orrs r2, r5                         @ 08028B96
	strb r2, [r0, #0x10]                @ 08028B98
	ldr r3, [r0, #0x44]                 @ 08028B9A
	cmp r4, r3                          @ 08028B9C
	bhs L_08028BBA                      @ 08028B9E
	str r3, [r0, #0x40]                 @ 08028BA0
	str r3, [r0, #0x30]                 @ 08028BA2
	orrs r2, r5                         @ 08028BA4
	strb r2, [r0, #0x10]                @ 08028BA6
	ldrb r2, [r1, #0xa]                 @ 08028BA8
	movs r3, #8                         @ 08028BAA
	bics r2, r3                         @ 08028BAC
	strb r2, [r1, #0xa]                 @ 08028BAE
	ldr r1, L_08028BEC                  @ 08028BB0 =0x0802842B
	str r1, [r0, #0x54]                 @ 08028BB2
L_08028BB4:
	bl Tick_VolSlideUp                  @ 08028BB4
	pop {r4, r5, pc}                    @ 08028BB8
L_08028BBA:
	ldrb r3, [r1, #8]                   @ 08028BBA
	ldrb r4, [r1, #0xb]                 @ 08028BBC
	adds r3, r3, r4                     @ 08028BBE
	lsls r3, r3, #0x18                  @ 08028BC0
	asrs r3, r3, #0x18                  @ 08028BC2
	strb r3, [r1, #8]                   @ 08028BC4
	cmp r3, #0x40                       @ 08028BC6
	blt L_08028BD2                      @ 08028BC8
	movs r3, #0x40                      @ 08028BCA
	strb r3, [r1, #8]                   @ 08028BCC
	ldr r3, L_08028C04                  @ 08028BCE =0x08028615
	str r3, [r0, #0x54]                 @ 08028BD0
L_08028BD2:
	ldrb r1, [r1, #8]                   @ 08028BD2
	strb r1, [r0, #0x12]                @ 08028BD4
	movs r1, #0x10                      @ 08028BD6
	orrs r1, r2                         @ 08028BD8
	strb r1, [r0, #0x10]                @ 08028BDA
	pop {r4, r5, pc}                    @ 08028BDC
	movs r0, r0                         @ 08028BDE
L_08028BE0:
	.word NoteFreqTab	@ 0x0837CD44
L_08028BE4:
	.word Tick_VolSlideDown	@ 0x080283FD
L_08028BE8:
	.word TonePortaVolTicks	@ 0x0837D4E4
L_08028BEC:
	.word Tick_VolSlideUp	@ 0x0802842B
L_08028BF0:
	.word Tick_Retrig	@ 0x080289E9
L_08028BF4:
	.word Tick_NoteDelay	@ 0x08028A49
L_08028BF8:
	.word TEMPO_K	@ 0x00009C40
L_08028BFC:
	.word Tick_Vibrato	@ 0x0802870D
L_08028C00:
	.word PortaUpTab	@ 0x0837D024
L_08028C04:
	.word Tick_TonePortaDown	@ 0x08028615
L_08028C08:
	.word PortaDownTab	@ 0x0837D2A4

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento up + volume down. Same slip as above when the volume reaches 0.
	.thumb_func
	.global Tick_TonePortaUpVolDown
Tick_TonePortaUpVolDown:
	adds r1, r0, #0                     @ 08028C0C
	adds r1, #0x40                      @ 08028C0E
	push {r4, r5, lr}                   @ 08028C10
	ldrb r2, [r1, #0xd]                 @ 08028C12
	ldr r4, L_08028E94                  @ 08028C14 =0x0837D024
	ldr r3, [r0, #0x40]                 @ 08028C16
	lsls r2, r2, #1                     @ 08028C18
	ldrh r2, [r4, r2]                   @ 08028C1A
	movs r5, #2                         @ 08028C1C
	muls r3, r2, r3                     @ 08028C1E
	lsrs r4, r3, #0xe                   @ 08028C20
	str r4, [r0, #0x40]                 @ 08028C22
	str r4, [r0, #0x30]                 @ 08028C24
	ldrb r2, [r0, #0x10]                @ 08028C26
	orrs r2, r5                         @ 08028C28
	strb r2, [r0, #0x10]                @ 08028C2A
	ldr r3, [r0, #0x44]                 @ 08028C2C
	cmp r4, r3                          @ 08028C2E
	bls L_08028C4C                      @ 08028C30
	str r3, [r0, #0x40]                 @ 08028C32
	str r3, [r0, #0x30]                 @ 08028C34
	orrs r2, r5                         @ 08028C36
	strb r2, [r0, #0x10]                @ 08028C38
	ldrb r2, [r1, #0xa]                 @ 08028C3A
	movs r3, #8                         @ 08028C3C
	bics r2, r3                         @ 08028C3E
	strb r2, [r1, #0xa]                 @ 08028C40
	ldr r1, L_08028E98                  @ 08028C42 =0x080283FD
	str r1, [r0, #0x54]                 @ 08028C44
	bl Tick_VolSlideDown                @ 08028C46
	pop {r4, r5, pc}                    @ 08028C4A
L_08028C4C:
	ldrb r3, [r1, #8]                   @ 08028C4C
	ldrb r4, [r1, #0xb]                 @ 08028C4E
	subs r3, r3, r4                     @ 08028C50
	lsls r3, r3, #0x18                  @ 08028C52
	asrs r3, r3, #0x18                  @ 08028C54
	strb r3, [r1, #8]                   @ 08028C56
	cmp r3, #0                          @ 08028C58
	bgt L_08028C64                      @ 08028C5A
	movs r3, #0                         @ 08028C5C
	strb r3, [r1, #8]                   @ 08028C5E
	ldr r3, L_08028E9C                  @ 08028C60 =0x08028615
	str r3, [r0, #0x54]                 @ 08028C62
L_08028C64:
	ldrb r1, [r1, #8]                   @ 08028C64
	strb r1, [r0, #0x12]                @ 08028C66
	movs r1, #0x10                      @ 08028C68
	orrs r1, r2                         @ 08028C6A
	strb r1, [r0, #0x10]                @ 08028C6C
	pop {r4, r5, pc}                    @ 08028C6E

@ --------------------------------------------------------------------------------------------
@ L tick: tone portamento down + volume down.
	.thumb_func
	.global Tick_TonePortaDownVolDown
Tick_TonePortaDownVolDown:
	adds r1, r0, #0                     @ 08028C70
	adds r1, #0x40                      @ 08028C72
	push {r4, r5, lr}                   @ 08028C74
	ldrb r2, [r1, #0xd]                 @ 08028C76
	ldr r4, L_08028EA0                  @ 08028C78 =0x0837D2A4
	ldr r3, [r0, #0x40]                 @ 08028C7A
	lsls r2, r2, #1                     @ 08028C7C
	ldrh r2, [r4, r2]                   @ 08028C7E
	movs r5, #2                         @ 08028C80
	muls r3, r2, r3                     @ 08028C82
	lsrs r4, r3, #0x10                  @ 08028C84
	str r4, [r0, #0x40]                 @ 08028C86
	str r4, [r0, #0x30]                 @ 08028C88
	ldrb r2, [r0, #0x10]                @ 08028C8A
	orrs r2, r5                         @ 08028C8C
	strb r2, [r0, #0x10]                @ 08028C8E
	ldr r3, [r0, #0x44]                 @ 08028C90
	cmp r4, r3                          @ 08028C92
	bhs L_08028CB0                      @ 08028C94
	str r3, [r0, #0x40]                 @ 08028C96
	str r3, [r0, #0x30]                 @ 08028C98
	orrs r2, r5                         @ 08028C9A
	strb r2, [r0, #0x10]                @ 08028C9C
	ldrb r2, [r1, #0xa]                 @ 08028C9E
	movs r3, #8                         @ 08028CA0
	bics r2, r3                         @ 08028CA2
	strb r2, [r1, #0xa]                 @ 08028CA4
	ldr r1, L_08028E98                  @ 08028CA6 =0x080283FD
	str r1, [r0, #0x54]                 @ 08028CA8
	bl Tick_VolSlideDown                @ 08028CAA
	pop {r4, r5, pc}                    @ 08028CAE
L_08028CB0:
	ldrb r3, [r1, #8]                   @ 08028CB0
	ldrb r4, [r1, #0xb]                 @ 08028CB2
	subs r3, r3, r4                     @ 08028CB4
	lsls r3, r3, #0x18                  @ 08028CB6
	asrs r3, r3, #0x18                  @ 08028CB8
	strb r3, [r1, #8]                   @ 08028CBA
	cmp r3, #0                          @ 08028CBC
	bgt L_08028CC8                      @ 08028CBE
	movs r3, #0                         @ 08028CC0
	strb r3, [r1, #8]                   @ 08028CC2
	ldr r3, L_08028E9C                  @ 08028CC4 =0x08028615
	str r3, [r0, #0x54]                 @ 08028CC6
L_08028CC8:
	ldrb r1, [r1, #8]                   @ 08028CC8
	strb r1, [r0, #0x12]                @ 08028CCA
	movs r1, #0x10                      @ 08028CCC
	orrs r1, r2                         @ 08028CCE
	strb r1, [r0, #0x10]                @ 08028CD0
	pop {r4, r5, pc}                    @ 08028CD2

@ --------------------------------------------------------------------------------------------
@ per-row work of one channel: clear the tick mode, restore the voice pitch after vibrato,
@ then call FxTab[effect] (effect 0 when the row has no effect byte, nothing if the channel is absent).
	.thumb_func
	.global Player_ChannelRow
Player_ChannelRow:
	adds r1, r0, #0                     @ 08028CD4
	adds r1, #0x40                      @ 08028CD6
	push {r3, lr}                       @ 08028CD8
	ldrb r2, [r1, #0xa]                 @ 08028CDA
	lsrs r2, r2, #2                     @ 08028CDC
	lsls r2, r2, #2                     @ 08028CDE
	strb r2, [r1, #0xa]                 @ 08028CE0
	lsls r1, r2, #0x1d                  @ 08028CE2
	bpl L_08028CF8                      @ 08028CE4
	ldr r1, [r0, #0x40]                 @ 08028CE6
	ldr r2, [r0, #0x30]                 @ 08028CE8
	cmp r2, r1                          @ 08028CEA
	beq L_08028CF8                      @ 08028CEC
	str r1, [r0, #0x30]                 @ 08028CEE
	ldrb r1, [r0, #0x10]                @ 08028CF0
	movs r2, #2                         @ 08028CF2
	orrs r1, r2                         @ 08028CF4
	strb r1, [r0, #0x10]                @ 08028CF6
L_08028CF8:
	adds r1, r0, #0                     @ 08028CF8
	adds r1, #0x50                      @ 08028CFA
	ldrb r2, [r1, #8]                   @ 08028CFC
	cmp r2, #0                          @ 08028CFE
	beq L_08028D16                      @ 08028D00
	movs r3, #0x88                      @ 08028D02
	ands r2, r3                         @ 08028D04
	ldrb r1, [r1, #0xd]                 @ 08028D06
	bne L_08028D0C                      @ 08028D08
	movs r1, #0                         @ 08028D0A
L_08028D0C:
	ldr r2, L_08028EA4                  @ 08028D0C =0x0837CF24
	lsls r1, r1, #2                     @ 08028D0E
	ldr r1, [r2, r1]                    @ 08028D10
	bl __call_via_r1                    @ 08028D12
L_08028D16:
	pop {r3, pc}                        @ 08028D16

@ --------------------------------------------------------------------------------------------
@ per-tick work of one channel: call its tick handler in tick mode 1 (only while the note
@ sounds) or 2 (always).
	.thumb_func
	.global Player_ChannelTick
Player_ChannelTick:
	push {r3, lr}                       @ 08028D18
	movs r1, #0x4a                      @ 08028D1A
	ldrb r2, [r1, r0]                   @ 08028D1C
	lsls r1, r2, #0x1e                  @ 08028D1E
	lsrs r1, r1, #0x1e                  @ 08028D20
	beq L_08028D32                      @ 08028D22
	cmp r1, #1                          @ 08028D24
	bne L_08028D2C                      @ 08028D26
	lsls r1, r2, #0x1d                  @ 08028D28
	bpl L_08028D32                      @ 08028D2A
L_08028D2C:
	ldr r1, [r0, #0x54]                 @ 08028D2C
	bl __call_via_r1                    @ 08028D2E
L_08028D32:
	pop {r3, pc}                        @ 08028D32

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
	push {r4}                           @ 08028D34
	ldrb r1, [r0, #1]                   @ 08028D36
	movs r2, #0                         @ 08028D38
	adds r1, #1                         @ 08028D3A
	lsls r1, r1, #0x18                  @ 08028D3C
	lsrs r1, r1, #0x18                  @ 08028D3E
	strb r1, [r0, #1]                   @ 08028D40
	ldrb r3, [r0, #2]                   @ 08028D42
	cmp r1, r3                          @ 08028D44
	blo L_08028D70                      @ 08028D46
	ldr r3, [r0, #0x10]                 @ 08028D48
	adds r3, #1                         @ 08028D4A
	str r3, [r0, #0x10]                 @ 08028D4C
	ldr r1, [r0, #0xc]                  @ 08028D4E
	ldr r4, [r1, #4]                    @ 08028D50
	ldrb r3, [r4, r3]                   @ 08028D52
	cmp r3, #0xff                       @ 08028D54
	bne L_08028D5A                      @ 08028D56
	str r2, [r0, #0x10]                 @ 08028D58
L_08028D5A:
	ldr r3, [r1, #4]                    @ 08028D5A
	ldr r4, [r0, #0x10]                 @ 08028D5C
	ldr r1, [r1]                        @ 08028D5E
	ldrb r3, [r3, r4]                   @ 08028D60
	lsls r3, r3, #2                     @ 08028D62
	ldr r1, [r1, r3]                    @ 08028D64
	strb r2, [r0, #1]                   @ 08028D66
	adds r3, r1, #1                     @ 08028D68
	str r3, [r0, #0x14]                 @ 08028D6A
	ldrb r1, [r1]                       @ 08028D6C
	strb r1, [r0, #2]                   @ 08028D6E
L_08028D70:
	movs r1, #0                         @ 08028D70
L_08028D72:
	lsls r3, r1, #1                     @ 08028D72
	adds r3, r3, r1                     @ 08028D74
	lsls r3, r3, #5                     @ 08028D76
	adds r3, r3, r0                     @ 08028D78
	adds r3, #0x70                      @ 08028D7A
	adds r1, #1                         @ 08028D7C
	cmp r1, #0xf                        @ 08028D7E
	strb r2, [r3]                       @ 08028D80
	blt L_08028D72                      @ 08028D82
L_08028D84:
	ldr r1, [r0, #0x14]                 @ 08028D84
	adds r2, r1, #1                     @ 08028D86
	str r2, [r0, #0x14]                 @ 08028D88
	ldrb r1, [r1]                       @ 08028D8A
	cmp r1, #0                          @ 08028D8C
	beq L_08028E1C                      @ 08028D8E
	lsls r3, r1, #0x1c                  @ 08028D90
	lsrs r3, r3, #0x1c                  @ 08028D92
	subs r4, r3, #1                     @ 08028D94
	lsls r3, r4, #1                     @ 08028D96
	adds r3, r3, r4                     @ 08028D98
	lsls r3, r3, #5                     @ 08028D9A
	adds r3, r3, r0                     @ 08028D9C
	adds r3, #0x18                      @ 08028D9E
	lsrs r1, r1, #4                     @ 08028DA0
	cmp r1, #0                          @ 08028DA2
	bne L_08028DB6                      @ 08028DA4
	adds r1, r2, #1                     @ 08028DA6
	str r1, [r0, #0x14]                 @ 08028DA8
	ldrb r2, [r2]                       @ 08028DAA
	adds r1, r3, #0                     @ 08028DAC
	adds r1, #0x50                      @ 08028DAE
	strb r2, [r1, #9]                   @ 08028DB0
	strb r2, [r1, #8]                   @ 08028DB2
	b L_08028DD2                        @ 08028DB4
L_08028DB6:
	cmp r1, #1                          @ 08028DB6
	bne L_08028DC4                      @ 08028DB8
	adds r1, r3, #0                     @ 08028DBA
	adds r1, #0x50                      @ 08028DBC
	ldrb r2, [r1, #9]                   @ 08028DBE
	strb r2, [r1, #8]                   @ 08028DC0
	b L_08028DD2                        @ 08028DC2
L_08028DC4:
	ldr r2, [r0, #0xc]                  @ 08028DC4
	ldr r2, [r2, #0xc]                  @ 08028DC6
	adds r1, r2, r1                     @ 08028DC8
	subs r1, #0x10                      @ 08028DCA
	ldrb r1, [r1, #0xe]                 @ 08028DCC
	movs r2, #0x58                      @ 08028DCE
	strb r1, [r2, r3]                   @ 08028DD0
L_08028DD2:
	adds r1, r3, #0                     @ 08028DD2
	adds r1, #0x50                      @ 08028DD4
	ldrb r2, [r1, #8]                   @ 08028DD6
	lsls r3, r2, #0x1f                  @ 08028DD8
	bpl L_08028DE6                      @ 08028DDA
	ldr r3, [r0, #0x14]                 @ 08028DDC
	adds r4, r3, #1                     @ 08028DDE
	str r4, [r0, #0x14]                 @ 08028DE0
	ldrb r3, [r3]                       @ 08028DE2
	strb r3, [r1, #0xa]                 @ 08028DE4
L_08028DE6:
	lsls r3, r2, #0x1e                  @ 08028DE6
	bpl L_08028DF4                      @ 08028DE8
	ldr r3, [r0, #0x14]                 @ 08028DEA
L_08028DEC:
	adds r4, r3, #1                     @ 08028DEC
	str r4, [r0, #0x14]                 @ 08028DEE
	ldrb r3, [r3]                       @ 08028DF0
	strb r3, [r1, #0xb]                 @ 08028DF2
L_08028DF4:
	lsls r3, r2, #0x1d                  @ 08028DF4
	bpl L_08028E02                      @ 08028DF6
	ldr r3, [r0, #0x14]                 @ 08028DF8
	adds r4, r3, #1                     @ 08028DFA
	str r4, [r0, #0x14]                 @ 08028DFC
	ldrb r3, [r3]                       @ 08028DFE
	strb r3, [r1, #0xc]                 @ 08028E00
L_08028E02:
	lsls r2, r2, #0x1c                  @ 08028E02
	bpl L_08028D84                      @ 08028E04
	ldr r2, [r0, #0x14]                 @ 08028E06
	adds r3, r2, #1                     @ 08028E08
	str r3, [r0, #0x14]                 @ 08028E0A
	ldrb r2, [r2]                       @ 08028E0C
	strb r2, [r1, #0xd]                 @ 08028E0E
	ldr r2, [r0, #0x14]                 @ 08028E10
	adds r3, r2, #1                     @ 08028E12
	str r3, [r0, #0x14]                 @ 08028E14
	ldrb r2, [r2]                       @ 08028E16
	strb r2, [r1, #0xe]                 @ 08028E18
	b L_08028D84                        @ 08028E1A
L_08028E1C:
	pop {r4}                            @ 08028E1C
	bx lr                               @ 08028E1E

@ --------------------------------------------------------------------------------------------
@ One player tick: on the first tick of a row read the row and run every channel's row effect,
@ otherwise run the tick handlers; then update all 15 music voices.
	.thumb_func
	.global Player_Tick
Player_Tick:
	push {r3, r4, r5, lr}               @ 08028E20
	adds r4, r0, #0                     @ 08028E22
	ldrb r0, [r0]                       @ 08028E24
	adds r0, #0xff                      @ 08028E26
	lsls r0, r0, #0x18                  @ 08028E28
	lsrs r0, r0, #0x18                  @ 08028E2A
	strb r0, [r4]                       @ 08028E2C
	bne L_08028E52                      @ 08028E2E
	adds r0, r4, #0                     @ 08028E30
	bl Player_ReadRow                   @ 08028E32
	movs r5, #0                         @ 08028E36
L_08028E38:
	lsls r0, r5, #1                     @ 08028E38
	adds r0, r0, r5                     @ 08028E3A
	lsls r0, r0, #5                     @ 08028E3C
	adds r0, r0, r4                     @ 08028E3E
	adds r0, #0x18                      @ 08028E40
	bl Player_ChannelRow                @ 08028E42
	adds r5, #1                         @ 08028E46
	cmp r5, #0xf                        @ 08028E48
	blt L_08028E38                      @ 08028E4A
	ldrb r0, [r4, #3]                   @ 08028E4C
	strb r0, [r4]                       @ 08028E4E
	b L_08028E7C                        @ 08028E50
L_08028E52:
	movs r5, #0                         @ 08028E52
L_08028E54:
	lsls r0, r5, #1                     @ 08028E54
	adds r0, r0, r5                     @ 08028E56
	lsls r0, r0, #5                     @ 08028E58
	adds r0, r0, r4                     @ 08028E5A
	adds r0, #0x18                      @ 08028E5C
	movs r1, #0x4a                      @ 08028E5E
	ldrb r2, [r1, r0]                   @ 08028E60
	lsls r1, r2, #0x1e                  @ 08028E62
	lsrs r1, r1, #0x1e                  @ 08028E64
	beq L_08028E76                      @ 08028E66
	cmp r1, #1                          @ 08028E68
	bne L_08028E70                      @ 08028E6A
	lsls r1, r2, #0x1d                  @ 08028E6C
	bpl L_08028E76                      @ 08028E6E
L_08028E70:
	ldr r1, [r0, #0x54]                 @ 08028E70
	bl __call_via_r1                    @ 08028E72
L_08028E76:
	adds r5, #1                         @ 08028E76
	cmp r5, #0xf                        @ 08028E78
	blt L_08028E54                      @ 08028E7A
L_08028E7C:
	movs r5, #0                         @ 08028E7C
L_08028E7E:
	lsls r0, r5, #1                     @ 08028E7E
	adds r0, r0, r5                     @ 08028E80
	lsls r0, r0, #5                     @ 08028E82
	adds r0, r0, r4                     @ 08028E84
	adds r0, #0x18                      @ 08028E86
	bl Voice_Update                     @ 08028E88
	adds r5, #1                         @ 08028E8C
	cmp r5, #0xf                        @ 08028E8E
	blt L_08028E7E                      @ 08028E90
	pop {r3, r4, r5, pc}                @ 08028E92
L_08028E94:
	.word PortaUpTab	@ 0x0837D024
L_08028E98:
	.word Tick_VolSlideDown	@ 0x080283FD
L_08028E9C:
	.word Tick_TonePortaDown	@ 0x08028615
L_08028EA0:
	.word PortaDownTab	@ 0x0837D2A4
L_08028EA4:
	.word FxTab	@ 0x0837CF24

@ --------------------------------------------------------------------------------------------
@ void Player_MixVoices(Player *p, u32 *buf, int n): mix the 15 channel voices.
	.thumb_func
	.global Player_MixVoices
Player_MixVoices:
	push {r3, r4, r5, r6, r7, lr}       @ 08028EA8
	adds r6, r1, #0                     @ 08028EAA
	adds r5, r0, #0                     @ 08028EAC
	adds r7, r2, #0                     @ 08028EAE
	movs r4, #0                         @ 08028EB0
L_08028EB2:
	lsls r0, r4, #1                     @ 08028EB2
	adds r0, r0, r4                     @ 08028EB4
	lsls r0, r0, #5                     @ 08028EB6
	adds r0, r0, r5                     @ 08028EB8
	adds r0, #0x18                      @ 08028EBA
	adds r2, r7, #0                     @ 08028EBC
	adds r1, r6, #0                     @ 08028EBE
	bl Voice_Mix                        @ 08028EC0
	adds r4, #1                         @ 08028EC4
	cmp r4, #0xf                        @ 08028EC6
	blt L_08028EB2                      @ 08028EC8
	pop {r3, r4, r5, r6, r7, pc}        @ 08028ECA

@ --------------------------------------------------------------------------------------------
@ void Player_Render(Player *p, u32 *buf, int n): mix n samples of music, running ticks with
@ sample accuracy (see Mus_Render in version 1).
	.thumb_func
	.global Player_Render
Player_Render:
	push {r3, r4, r5, r6, r7, lr}       @ 08028ECC
	adds r4, r0, #0                     @ 08028ECE
	ldrb r0, [r0, #5]                   @ 08028ED0
	adds r7, r2, #0                     @ 08028ED2
	adds r6, r1, #0                     @ 08028ED4
	cmp r0, #1                          @ 08028ED6
	bne L_08028F00                      @ 08028ED8
L_08028EDA:
	ldrh r0, [r4, #8]                   @ 08028EDA
	cmp r0, r7                          @ 08028EDC
	blt L_08028F02                      @ 08028EDE
L_08028EE0:
	movs r5, #0                         @ 08028EE0
L_08028EE2:
	lsls r0, r5, #1                     @ 08028EE2
	adds r0, r0, r5                     @ 08028EE4
	lsls r0, r0, #5                     @ 08028EE6
	adds r0, r0, r4                     @ 08028EE8
	adds r0, #0x18                      @ 08028EEA
	adds r2, r7, #0                     @ 08028EEC
	adds r1, r6, #0                     @ 08028EEE
	bl Voice_Mix                        @ 08028EF0
	adds r5, #1                         @ 08028EF4
	cmp r5, #0xf                        @ 08028EF6
	blt L_08028EE2                      @ 08028EF8
	ldrh r0, [r4, #8]                   @ 08028EFA
	subs r0, r0, r7                     @ 08028EFC
	strh r0, [r4, #8]                   @ 08028EFE
L_08028F00:
	pop {r3, r4, r5, r6, r7, pc}        @ 08028F00
L_08028F02:
	cmp r0, #0                          @ 08028F02
	beq L_08028F2A                      @ 08028F04
	str r0, [sp]                        @ 08028F06
	movs r5, #0                         @ 08028F08
L_08028F0A:
	lsls r0, r5, #1                     @ 08028F0A
	adds r0, r0, r5                     @ 08028F0C
	lsls r0, r0, #5                     @ 08028F0E
	adds r0, r0, r4                     @ 08028F10
	adds r0, #0x18                      @ 08028F12
	adds r1, r6, #0                     @ 08028F14
	ldr r2, [sp]                        @ 08028F16
	bl Voice_Mix                        @ 08028F18
	adds r5, #1                         @ 08028F1C
	cmp r5, #0xf                        @ 08028F1E
	blt L_08028F0A                      @ 08028F20
	ldrh r0, [r4, #8]                   @ 08028F22
	lsls r1, r0, #2                     @ 08028F24
	adds r6, r1, r6                     @ 08028F26
	subs r7, r7, r0                     @ 08028F28
L_08028F2A:
	adds r0, r4, #0                     @ 08028F2A
	bl Player_Tick                      @ 08028F2C
	ldrh r0, [r4, #6]                   @ 08028F30
	strh r0, [r4, #8]                   @ 08028F32
	b L_08028EDA                        @ 08028F34

@ --------------------------------------------------------------------------------------------
@ Clear the 15 channels and their voices and re-link channel <-> voice.
	.thumb_func
	.global Player_ResetChannels
Player_ResetChannels:
	movs r1, #0                         @ 08028F36
	movs r2, #0                         @ 08028F38
	push {r4}                           @ 08028F3A
L_08028F3C:
	lsls r3, r1, #1                     @ 08028F3C
	adds r3, r3, r1                     @ 08028F3E
	lsls r3, r3, #5                     @ 08028F40
	adds r3, r3, r0                     @ 08028F42
	adds r3, #0x18                      @ 08028F44
	movs r4, #0x4a                      @ 08028F46
	strb r2, [r4, r3]                   @ 08028F48
	adds r4, r3, #0                     @ 08028F4A
	adds r4, #0x50                      @ 08028F4C
	strb r2, [r4, #0xf]                 @ 08028F4E
	strb r2, [r4, #8]                   @ 08028F50
	strb r2, [r3, #0x10]                @ 08028F52
	adds r1, #1                         @ 08028F54
	cmp r1, #0xf                        @ 08028F56
	str r3, [r3, #0x2c]                 @ 08028F58
	blt L_08028F3C                      @ 08028F5A
	pop {r4}                            @ 08028F5C
	bx lr                               @ 08028F5E

@ --------------------------------------------------------------------------------------------
@ void Player_PlaySong(Player *p, const Song *s): start s at order 0 with its speed and tempo.
	.thumb_func
	.global Player_PlaySong
Player_PlaySong:
	push {r4, r5, r6, lr}               @ 08028F60
	movs r5, #1                         @ 08028F62
	strb r5, [r0, #2]                   @ 08028F64
	strb r5, [r0]                       @ 08028F66
	movs r2, #0                         @ 08028F68
	strb r2, [r0, #1]                   @ 08028F6A
	str r1, [r0, #0xc]                  @ 08028F6C
	adds r4, r0, #0                     @ 08028F6E
	ldrb r0, [r1, #0x11]                @ 08028F70
	strb r0, [r4, #3]                   @ 08028F72
	mvns r0, r2                         @ 08028F74
	str r0, [r4, #0x10]                 @ 08028F76
	movs r0, #0                         @ 08028F78
L_08028F7A:
	lsls r3, r0, #1                     @ 08028F7A
	adds r3, r3, r0                     @ 08028F7C
	lsls r3, r3, #5                     @ 08028F7E
	adds r3, r3, r4                     @ 08028F80
	adds r3, #0x18                      @ 08028F82
	movs r6, #0x4a                      @ 08028F84
	strb r2, [r6, r3]                   @ 08028F86
	adds r6, r3, #0                     @ 08028F88
	adds r6, #0x50                      @ 08028F8A
	strb r2, [r6, #0xf]                 @ 08028F8C
	strb r2, [r6, #8]                   @ 08028F8E
	strb r2, [r3, #0x10]                @ 08028F90
	adds r0, #1                         @ 08028F92
	cmp r0, #0xf                        @ 08028F94
	str r3, [r3, #0x2c]                 @ 08028F96
	blt L_08028F7A                      @ 08028F98
	ldrb r0, [r1, #0x10]                @ 08028F9A
	ldr r1, L_08029004                  @ 08028F9C =0x00009C40
	strb r0, [r4, #4]                   @ 08028F9E
	bl __rt_udiv                        @ 08028FA0
	strh r0, [r4, #6]                   @ 08028FA4
	strb r5, [r4, #5]                   @ 08028FA6
	pop {r4, r5, r6, pc}                @ 08028FA8

@ --------------------------------------------------------------------------------------------
@ void Player_SkipPattern(Player *p): reset the channels and end the current pattern.
	.thumb_func
	.global Player_SkipPattern
Player_SkipPattern:
	movs r1, #0                         @ 08028FAA
	movs r2, #0                         @ 08028FAC
	push {r4}                           @ 08028FAE
L_08028FB0:
	lsls r3, r1, #1                     @ 08028FB0
	adds r3, r3, r1                     @ 08028FB2
	lsls r3, r3, #5                     @ 08028FB4
	adds r3, r3, r0                     @ 08028FB6
	adds r3, #0x18                      @ 08028FB8
	movs r4, #0x4a                      @ 08028FBA
	strb r2, [r4, r3]                   @ 08028FBC
	adds r4, r3, #0                     @ 08028FBE
	adds r4, #0x50                      @ 08028FC0
	strb r2, [r4, #0xf]                 @ 08028FC2
	strb r2, [r4, #8]                   @ 08028FC4
	strb r2, [r3, #0x10]                @ 08028FC6
	adds r1, #1                         @ 08028FC8
	cmp r1, #0xf                        @ 08028FCA
	str r3, [r3, #0x2c]                 @ 08028FCC
	blt L_08028FB0                      @ 08028FCE
	ldrb r1, [r0, #2]                   @ 08028FD0
	strb r1, [r0, #1]                   @ 08028FD2
	movs r1, #1                         @ 08028FD4
	strb r1, [r0]                       @ 08028FD6
	pop {r4}                            @ 08028FD8
	bx lr                               @ 08028FDA

@ --------------------------------------------------------------------------------------------
@ void Player_SetVolume(Player *p, int bus): bus volume of the 15 music voices.
	.thumb_func
	.global Player_SetVolume
Player_SetVolume:
	push {r4, r5}                       @ 08028FDC
	movs r4, #0x10                      @ 08028FDE
	movs r2, #0                         @ 08028FE0
	lsls r1, r1, #0x18                  @ 08028FE2
	lsrs r1, r1, #0x18                  @ 08028FE4
L_08028FE6:
	lsls r3, r2, #1                     @ 08028FE6
	adds r3, r3, r2                     @ 08028FE8
	lsls r3, r3, #5                     @ 08028FEA
	adds r3, r3, r0                     @ 08028FEC
	adds r3, #0x18                      @ 08028FEE
	movs r5, #0x34                      @ 08028FF0
	strb r1, [r5, r3]                   @ 08028FF2
	ldrb r5, [r3, #0x10]                @ 08028FF4
	adds r2, #1                         @ 08028FF6
	orrs r5, r4                         @ 08028FF8
	strb r5, [r3, #0x10]                @ 08028FFA
	cmp r2, #0xf                        @ 08028FFC
	blt L_08028FE6                      @ 08028FFE
	pop {r4, r5}                        @ 08029000
	bx lr                               @ 08029002
L_08029004:
	.word TEMPO_K	@ 0x00009C40

@ --------------------------------------------------------------------------------------------
@ void Snd_Init(Snd *s): clears 2 KB of rings, DirectSound A = left, B = right, Timer 0 reload -1050
@ (15978 Hz); DMA1/DMA2 without IRQ; Timer 1 cascaded on Timer 0 with reload -64 and IRQ,
@ handler Snd_Timer1Irq; bus volumes music 4 / sfx 8.
	.thumb_func
	.global Snd_Init
Snd_Init:
	push {r3, r4, r5, lr}               @ 08029008
	adds r4, r0, #0                     @ 0802900A
	movs r0, #0                         @ 0802900C
	str r0, [r4, #4]                    @ 0802900E
	str r0, [r4, #8]                    @ 08029010
	str r0, [r4]                        @ 08029012
	movs r2, #1                         @ 08029014
	lsls r2, r2, #0xb                   @ 08029016
	movs r1, #0                         @ 08029018
	lsls r0, r2, #0xe                   @ 0802901A
	bl memset_from_thumb                @ 0802901C
	ldr r0, L_08029274                  @ 08029020 =0x000005C4
	adds r0, r4, r0                     @ 08029022
	adds r5, r0, #0                     @ 08029024
	bl Pool_Clear                       @ 08029026
	adds r4, #0xc                       @ 0802902A
	adds r0, r4, #0                     @ 0802902C
	bl Player_ResetChannels             @ 0802902E
	ldr r1, L_08029278                  @ 08029032 =0x04000080
	movs r0, #0x80                      @ 08029034
	strh r0, [r1, #4]                   @ 08029036
	ldr r0, L_0802927C                  @ 08029038 =0x00009A0E
	strh r0, [r1, #2]                   @ 0802903A
	lsls r0, r1, #0x12                  @ 0802903C
	str r0, [r1, #0x3c]                 @ 0802903E
	ldr r1, L_08029280                  @ 08029040 =0x040000A0
	adds r0, r1, #0                     @ 08029042
	adds r0, #0x20                      @ 08029044
	str r1, [r0]                        @ 08029046
	movs r1, #4                         @ 08029048
	strh r1, [r0, #4]                   @ 0802904A
	ldr r2, L_08029284                  @ 0802904C =0x0000B660
	strh r2, [r0, #6]                   @ 0802904E
	ldr r2, L_08029288                  @ 08029050 =0x02000640
	str r2, [r0, #8]                    @ 08029052
	ldr r2, L_0802928C                  @ 08029054 =0x040000A4
	str r2, [r0, #0xc]                  @ 08029056
	strh r1, [r0, #0x10]                @ 08029058
	ldr r1, L_08029284                  @ 0802905A =0x0000B660
	strh r1, [r0, #0x12]                @ 0802905C
	ldr r1, L_08029278                  @ 0802905E =0x04000080
	movs r0, #0                         @ 08029060
	strh r0, [r1]                       @ 08029062
	ldr r1, L_08029290                  @ 08029064 =0xFFFFFBE6
	ldr r0, L_08029294                  @ 08029066 =0x04000100
	ldr r2, L_0802929C                  @ 08029068 =0x03000AA0
	strh r1, [r0]                       @ 0802906A
	movs r1, #0x80                      @ 0802906C
	strh r1, [r0, #2]                   @ 0802906E
	ldr r1, L_08029298                  @ 08029070 =0x0837D4FC
	movs r3, #0x10                      @ 08029072
	ldr r1, [r1]                        @ 08029074
	str r2, [r1, #0x10]                 @ 08029076
	adds r2, r0, #0                     @ 08029078
	adds r2, #0xff                      @ 0802907A
	adds r2, #1                         @ 0802907C
	ldrh r1, [r2]                       @ 0802907E
	orrs r1, r3                         @ 08029080
	strh r1, [r2]                       @ 08029082
	movs r1, #0x3f                      @ 08029084
	mvns r1, r1                         @ 08029086
	strh r1, [r0, #4]                   @ 08029088
	movs r1, #0xc4                      @ 0802908A
	strh r1, [r0, #6]                   @ 0802908C
	movs r1, #4                         @ 0802908E
	adds r0, r4, #0                     @ 08029090
	bl Player_SetVolume                 @ 08029092
	movs r1, #8                         @ 08029096
	adds r0, r5, #0                     @ 08029098
	bl Pool_SetVolume                   @ 0802909A
	pop {r3, r4, r5, pc}                @ 0802909E

@ --------------------------------------------------------------------------------------------
@ void Snd_Shutdown(void): stop both timers, both DMAs and the sound circuit (no wait).
	.thumb_func
	.global Snd_Shutdown
Snd_Shutdown:
	ldr r2, L_08029294                  @ 080290A0 =0x04000100
	movs r0, #0                         @ 080290A2
	adds r1, r2, #0                     @ 080290A4
	subs r1, #0x40                      @ 080290A6
	strh r0, [r2, #2]                   @ 080290A8
	strh r0, [r1, #6]                   @ 080290AA
	strh r0, [r1, #0x12]                @ 080290AC
	ldr r1, L_08029278                  @ 080290AE =0x04000080
	strh r0, [r2, #6]                   @ 080290B0
	strh r0, [r1, #4]                   @ 080290B2
	bx lr                               @ 080290B4

@ --------------------------------------------------------------------------------------------
@ void Snd_Kill(void): stop Timer 0 and both DMAs at once.
	.thumb_func
	.global Snd_Kill
Snd_Kill:
	ldr r1, L_08029294                  @ 080290B6 =0x04000100
	movs r0, #0                         @ 080290B8
	strh r0, [r1, #2]                   @ 080290BA
	subs r1, #0x40                      @ 080290BC
	strh r0, [r1, #6]                   @ 080290BE
	strh r0, [r1, #0x12]                @ 080290C0
	bx lr                               @ 080290C2

@ --------------------------------------------------------------------------------------------
@ void Snd_Pause(void): wait for the Timer 1 IRQ, then stop Timer 0.
	.thumb_func
	.global Snd_Pause
Snd_Pause:
	ldr r0, L_08029298                  @ 080290C4 =0x0837D4FC
	push {r3, lr}                       @ 080290C6
	ldr r0, [r0]                        @ 080290C8
	movs r1, #0x10                      @ 080290CA
	bl IntrMgr_Wait                     @ 080290CC
	ldr r1, L_08029294                  @ 080290D0 =0x04000100
	movs r0, #0                         @ 080290D2
	strh r0, [r1, #2]                   @ 080290D4
	pop {r3, pc}                        @ 080290D6

@ --------------------------------------------------------------------------------------------
@ void Snd_Resume(void): restart Timer 0.
	.thumb_func
	.global Snd_Resume
Snd_Resume:
	ldr r1, L_08029294                  @ 080290D8 =0x04000100
	movs r0, #0x80                      @ 080290DA
	strh r0, [r1, #2]                   @ 080290DC
	bx lr                               @ 080290DE

@ --------------------------------------------------------------------------------------------
@ void Snd_Mix(Snd *s): refill the rings (main loop, and the IRQ when they run low).
@ At least 64 free samples: update the pool voices, then per chunk of at most 512 samples
@ Player_Render + Pool_MixAll + Mix_Output, split at the ring wrap and the right ring's 512 offset.
@ Afterwards the first 68 bytes of each ring are copied behind its end (rings are 1024 + 64 bytes),
@ so DMA can run past the wrap point until the 64-sample timer IRQ re-arms it.
	.thumb_func
	.global Snd_Mix
Snd_Mix:
	push {r4, r5, r6, r7, lr}           @ 080290E0
	adds r7, r0, #0                     @ 080290E2
	movs r0, #1                         @ 080290E4
	sub sp, #0x1c                       @ 080290E6
	str r0, [r7]                        @ 080290E8
	ldr r0, [r7, #4]                    @ 080290EA
	ldr r4, [r7, #8]                    @ 080290EC
	subs r1, r0, r4                     @ 080290EE
	lsls r5, r1, #0x16                  @ 080290F0
	lsrs r5, r5, #0x16                  @ 080290F2
	str r5, [sp, #0xc]                  @ 080290F4
	cmp r5, #0x40                       @ 080290F6
	blt L_080291DE                      @ 080290F8
	str r0, [r7, #8]                    @ 080290FA
	ldr r0, L_08029274                  @ 080290FC =0x000005C4
	adds r0, r7, r0                     @ 080290FE
	str r0, [sp, #0x18]                 @ 08029100
	bl Pool_UpdateAll                   @ 08029102
	adds r0, r7, #0                     @ 08029106
	adds r0, #0xc                       @ 08029108
	str r0, [sp, #0x14]                 @ 0802910A
	ldr r0, L_080292A0                  @ 0802910C =0x000009C4
	adds r6, r7, r0                     @ 0802910E
L_08029110:
	movs r1, #1                         @ 08029110
	ldr r5, [sp, #0xc]                  @ 08029112
	lsls r1, r1, #9                     @ 08029114
	cmp r5, r1                          @ 08029116
	ble L_0802911C                      @ 08029118
	adds r5, r1, #0                     @ 0802911A
L_0802911C:
	adds r2, r5, #0                     @ 0802911C
	adds r1, r6, #0                     @ 0802911E
	ldr r0, [sp, #0x14]                 @ 08029120
	bl Player_Render                    @ 08029122
	adds r2, r5, #0                     @ 08029126
	adds r1, r6, #0                     @ 08029128
	ldr r0, [sp, #0x18]                 @ 0802912A
	bl Pool_MixAll                      @ 0802912C
	adds r0, r4, r5                     @ 08029130
	movs r1, #1                         @ 08029132
	lsls r1, r1, #0xa                   @ 08029134
	cmp r0, r1                          @ 08029136
	str r0, [sp, #0x10]                 @ 08029138
	ble L_0802916E                      @ 0802913A
	subs r3, r1, r4                     @ 0802913C
	str r3, [sp, #8]                    @ 0802913E
	subs r3, r0, r1                     @ 08029140
	ldr r0, L_080292A4                  @ 08029142 =0x02000240
	str r3, [sp, #4]                    @ 08029144
	adds r1, r4, r0                     @ 08029146
	movs r0, #1                         @ 08029148
	lsls r0, r0, #0x19                  @ 0802914A
	adds r2, r6, #0                     @ 0802914C
	adds r0, r4, r0                     @ 0802914E
	ldr r3, [sp, #8]                    @ 08029150
	bl Mix_Output_from_thumb            @ 08029152
	ldr r3, [sp, #8]                    @ 08029156
	ldr r1, L_080292A0                  @ 08029158 =0x000009C4
	lsls r0, r3, #2                     @ 0802915A
	adds r0, r0, r7                     @ 0802915C
	adds r2, r0, r1                     @ 0802915E
	movs r0, #1                         @ 08029160
	lsls r0, r0, #0x19                  @ 08029162
	ldr r1, L_08029288                  @ 08029164 =0x02000640
	ldr r3, [sp, #4]                    @ 08029166
	bl Mix_Output_from_thumb            @ 08029168
	b L_080291D0                        @ 0802916C
L_0802916E:
	movs r1, #1                         @ 0802916E
	lsls r1, r1, #9                     @ 08029170
	cmp r4, r1                          @ 08029172
	bge L_080291BE                      @ 08029174
	cmp r0, r1                          @ 08029176
	ble L_080291AA                      @ 08029178
	subs r3, r1, r4                     @ 0802917A
	str r3, [sp, #8]                    @ 0802917C
	subs r3, r0, r1                     @ 0802917E
	ldr r0, L_08029288                  @ 08029180 =0x02000640
	str r3, [sp, #4]                    @ 08029182
	adds r1, r4, r0                     @ 08029184
	movs r0, #1                         @ 08029186
	lsls r0, r0, #0x19                  @ 08029188
	adds r2, r6, #0                     @ 0802918A
	adds r0, r4, r0                     @ 0802918C
	ldr r3, [sp, #8]                    @ 0802918E
	bl Mix_Output_from_thumb            @ 08029190
	ldr r3, [sp, #8]                    @ 08029194
	ldr r1, L_080292A0                  @ 08029196 =0x000009C4
	lsls r0, r3, #2                     @ 08029198
	adds r0, r0, r7                     @ 0802919A
	adds r2, r0, r1                     @ 0802919C
	ldr r1, L_080292A8                  @ 0802919E =0x02000440
	ldr r0, L_080292AC                  @ 080291A0 =0x02000200
	ldr r3, [sp, #4]                    @ 080291A2
	bl Mix_Output_from_thumb            @ 080291A4
	b L_080291D0                        @ 080291A8
L_080291AA:
	ldr r0, L_08029288                  @ 080291AA =0x02000640
	adds r3, r5, #0                     @ 080291AC
	adds r1, r4, r0                     @ 080291AE
	movs r0, #1                         @ 080291B0
	lsls r0, r0, #0x19                  @ 080291B2
	adds r2, r6, #0                     @ 080291B4
	adds r0, r4, r0                     @ 080291B6
	bl Mix_Output_from_thumb            @ 080291B8
	b L_080291D0                        @ 080291BC
L_080291BE:
	ldr r0, L_080292A4                  @ 080291BE =0x02000240
	adds r3, r5, #0                     @ 080291C0
	adds r1, r4, r0                     @ 080291C2
	movs r0, #1                         @ 080291C4
	lsls r0, r0, #0x19                  @ 080291C6
	adds r2, r6, #0                     @ 080291C8
	adds r0, r4, r0                     @ 080291CA
	bl Mix_Output_from_thumb            @ 080291CC
L_080291D0:
	ldr r0, [sp, #0x10]                 @ 080291D0
	lsls r4, r0, #0x16                  @ 080291D2
	ldr r0, [sp, #0xc]                  @ 080291D4
	lsrs r4, r4, #0x16                  @ 080291D6
	subs r0, r0, r5                     @ 080291D8
	str r0, [sp, #0xc]                  @ 080291DA
	b L_080291E0                        @ 080291DC
L_080291DE:
	b L_080291E2                        @ 080291DE
L_080291E0:
	bne L_08029110                      @ 080291E0
L_080291E2:
	ldr r1, L_080292A8                  @ 080291E2 =0x02000440
	ldr r0, L_080292B0                  @ 080291E4 =0x02000840
	ldmia r1!, {r2}                     @ 080291E6
	stmia r0!, {r2}                     @ 080291E8
	ldmia r1!, {r2}                     @ 080291EA
	stmia r0!, {r2}                     @ 080291EC
	ldmia r1!, {r2}                     @ 080291EE
	stmia r0!, {r2}                     @ 080291F0
	ldmia r1!, {r2}                     @ 080291F2
	stmia r0!, {r2}                     @ 080291F4
	ldmia r1!, {r2}                     @ 080291F6
	stmia r0!, {r2}                     @ 080291F8
	ldmia r1!, {r2}                     @ 080291FA
	stmia r0!, {r2}                     @ 080291FC
	ldmia r1!, {r2}                     @ 080291FE
	stmia r0!, {r2}                     @ 08029200
	ldmia r1!, {r2}                     @ 08029202
	stmia r0!, {r2}                     @ 08029204
	ldmia r1!, {r2}                     @ 08029206
	stmia r0!, {r2}                     @ 08029208
	ldmia r1!, {r2}                     @ 0802920A
	stmia r0!, {r2}                     @ 0802920C
	ldmia r1!, {r2}                     @ 0802920E
	stmia r0!, {r2}                     @ 08029210
	ldmia r1!, {r2}                     @ 08029212
	stmia r0!, {r2}                     @ 08029214
	ldmia r1!, {r2}                     @ 08029216
	stmia r0!, {r2}                     @ 08029218
	ldmia r1!, {r2}                     @ 0802921A
	stmia r0!, {r2}                     @ 0802921C
	ldmia r1!, {r2}                     @ 0802921E
	stmia r0!, {r2}                     @ 08029220
	ldr r1, [r1]                        @ 08029222
	str r1, [r0]                        @ 08029224
	ldr r0, L_080292B4                  @ 08029226 =0x02000400
	lsls r1, r0, #0xf                   @ 08029228
	ldmia r1!, {r2}                     @ 0802922A
	stmia r0!, {r2}                     @ 0802922C
	ldmia r1!, {r2}                     @ 0802922E
	stmia r0!, {r2}                     @ 08029230
	ldmia r1!, {r2}                     @ 08029232
	stmia r0!, {r2}                     @ 08029234
	ldmia r1!, {r2}                     @ 08029236
	stmia r0!, {r2}                     @ 08029238
	ldmia r1!, {r2}                     @ 0802923A
	stmia r0!, {r2}                     @ 0802923C
	ldmia r1!, {r2}                     @ 0802923E
	stmia r0!, {r2}                     @ 08029240
	ldmia r1!, {r2}                     @ 08029242
	stmia r0!, {r2}                     @ 08029244
	ldmia r1!, {r2}                     @ 08029246
	stmia r0!, {r2}                     @ 08029248
	ldmia r1!, {r2}                     @ 0802924A
	stmia r0!, {r2}                     @ 0802924C
	ldmia r1!, {r2}                     @ 0802924E
	stmia r0!, {r2}                     @ 08029250
	ldmia r1!, {r2}                     @ 08029252
	stmia r0!, {r2}                     @ 08029254
	ldmia r1!, {r2}                     @ 08029256
	stmia r0!, {r2}                     @ 08029258
	ldmia r1!, {r2}                     @ 0802925A
	stmia r0!, {r2}                     @ 0802925C
	ldmia r1!, {r2}                     @ 0802925E
	stmia r0!, {r2}                     @ 08029260
	ldmia r1!, {r2}                     @ 08029262
	stmia r0!, {r2}                     @ 08029264
	ldr r1, [r1]                        @ 08029266
	str r1, [r0]                        @ 08029268
	movs r0, #0                         @ 0802926A
	str r0, [r7]                        @ 0802926C
	add sp, #0x1c                       @ 0802926E
	pop {r4, r5, r6, r7, pc}            @ 08029270
	movs r0, r0                         @ 08029272
L_08029274:
	.word SND_POOL	@ 0x000005C4
L_08029278:
	.word REG_SOUNDCNT_L	@ 0x04000080
L_0802927C:
	.word 0x00009A0E
L_08029280:
	.word REG_FIFO_A	@ 0x040000A0
L_08029284:
	.word 0x0000B660
L_08029288:
	.word ring_R_512	@ 0x02000640
L_0802928C:
	.word REG_FIFO_B	@ 0x040000A4
L_08029290:
	.word 0xFFFFFBE6
L_08029294:
	.word REG_TM0CNT_L	@ 0x04000100
L_08029298:
	.word p_intrmgr	@ 0x0837D4FC
L_0802929C:
	.word Snd_Timer1Irq	@ 0x03000AA0
L_080292A0:
	.word SND_MIXBUF	@ 0x000009C4
L_080292A4:
	.word ring_R_m512	@ 0x02000240
L_080292A8:
	.word ring_R	@ 0x02000440
L_080292AC:
	.word ring_L_512	@ 0x02000200
L_080292B0:
	.word ring_R_guard	@ 0x02000840
L_080292B4:
	.word ring_L_guard	@ 0x02000400
