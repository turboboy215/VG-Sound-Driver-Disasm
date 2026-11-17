@ ==================================================================================================
@ fuh_sound.s -- FUH Sound System (Frontline Studios), Hardcore Pool (E) (M4)
@
@ All sound code of the game, disassembled to source that rebuilds byte-identically:
@   VBlank_Sound            ROM 08000190-080001FC   Thumb   game-side V-blank handler
@   Mixer_*                 ROM 08035A00-08035CCC   Thumb   DirectSoundSystemMixer.cpp
@   Mus_*                   ROM 08039260-080393AC   Thumb   music control
@   Mix_Frame               IWRAM 03000408-030005A0 ARM     (ROM 083ECB2C, crt0 IWRAM image)
@   Player_Tick + effects   IWRAM 03002838-03002DF4 ARM     (ROM 083EEF5C, crt0 IWRAM image)
@
@ Names are invented; the ROM has no symbols. See fuh-technical-reference.md for the full
@ description, and fuh_defs.inc for the structure layouts and external symbols.
@ Build: make -f fuh.mk check ROM="Hardcore Pool (E) (M4).gba"
@ ==================================================================================================

	.include "fuh_defs.inc"

@==================================================================================================
@ vblank  (Thumb, .text.fuh_vblank)  VMA 08000190-080001FC
@==================================================================================================
	.section .text.fuh_vblank,"ax",%progbits
	.balign 4
	.thumb
	.syntax unified

@ --------------------------------------------------------------------------------------------------
@ void VBlank_Sound(void)                                         (game file GameEntry.cpp)
@
@ V-blank interrupt handler, installed by GameEntry with SetIrqHandler(VBlank_Sound, IRQ_VBLANK).
@ Restarts the FIFO A DMA on the half of the output buffer that Mix_Frame filled during the
@ previous frame, runs one player tick, then mixes the next 304 samples into the other half.
@
@     DMA1CNT_H = 0;  DMA1SAD = mix_outbuf + mixer.bufOfs;  DMA1DAD = REG_FIFO_A;
@     DMA1CNT_L = 1;  DMA1CNT_H = 0xB640;      // enable, FIFO timing, 32-bit, repeat, dst fixed
@     Player_Tick();  Mix_Frame(&mixer);
@     *(u16 *)0x03007FF8 = 1;                  // BIOS IntrCheck = V-blank (VBlankIntrWait)
@ --------------------------------------------------------------------------------------------------
	.global VBlank_Sound
	.thumb_func
	.type VBlank_Sound, %function
VBlank_Sound:
	push {r4, r5, lr}
	ldr r5, .Llit_80001D8	@ r5 = &mixer
	ldr r3, .Llit_80001DC	@ r3 = mix_outbuf (2 x 512 bytes)
	ldr r2, [r5, #0x10]	@ r2 = mixer.bufOfs (half mixed last frame)
	ldr r1, .Llit_80001E0	@ r1 = &REG_DMA1SAD
	adds r2, r2, r3
	ldr r3, .Llit_80001CC
	strh r3, [r1, #0xa]	@ DMA1CNT_H = 0: stop the DMA
	ldr r3, .Llit_80001E4
	str r2, [r1]	@ DMA1SAD = buffer half
	ldr r4, .Llit_80001D0
	str r3, [r1, #4]	@ DMA1DAD = FIFO A
	ldr r3, .Llit_80001D4
	strh r4, [r1, #8]	@ DMA1CNT_L = 1 (ignored in FIFO mode)
	ldr r0, .Llit_80001E8	@ r0 = Player_Tick (ARM, IWRAM)
	strh r3, [r1, #0xa]	@ DMA1CNT_H = 0xB640: restart
	bl .Lvblank_80001B6	@ long call through bx r0
	b .Lvblank_80001B8
.Lvblank_80001B6:
	bx r0
.Lvblank_80001B8:
	ldr r3, .Llit_80001EC	@ r3 = Mix_Frame (ARM, IWRAM)
	adds r0, r5, #0	@ r0 = &mixer
	bl .Lvblank_80001C2
	b .Lvblank_80001C4
.Lvblank_80001C2:
	bx r3
.Lvblank_80001C4:
	ldr r3, .Llit_80001F0	@ r3 = &BIOS IntrCheck
	strh r4, [r3]	@ = 1 (V-blank)
	b .Lvblank_80001F4
	.hword 0x0000	@ pad
.Llit_80001CC:
	.word 0x00000000
.Llit_80001D0:
	.word 0x00000001
.Llit_80001D4:
	.word 0xFFFFB640
.Llit_80001D8:
	.word mixer	@ 030031D8
.Llit_80001DC:
	.word mix_outbuf	@ 030031FC
.Llit_80001E0:
	.word REG_DMA1SAD	@ 040000BC
.Llit_80001E4:
	.word REG_FIFO_A	@ 040000A0
.Llit_80001E8:
	.word Player_Tick	@ 03002838
.Llit_80001EC:
	.word Mix_Frame	@ 03000408
.Llit_80001F0:
	.word REG_IFBIOS	@ 03007FF8
.Lvblank_80001F4:
	pop {r4, r5}
	pop {r0}
	bx r0
	movs r0, r0

@==================================================================================================
@ mixapi  (Thumb, .text.fuh_mixer)  VMA 08035A00-08035CCC
@==================================================================================================
	.section .text.fuh_mixer,"ax",%progbits
	.balign 4
	.thumb
	.syntax unified

@ --------------------------------------------------------------------------------------------------
@ void Mixer_BuildOutputTable(int gain)                           (DirectSoundSystemMixer.cpp)
@
@ Builds the 2048-byte output table mix_lut[] that Mix_Frame uses to turn the biased 16-bit sum
@ (centre 0x400) into a signed 8-bit FIFO sample. Called once by Mixer_Init with gain = 64.
@
@     g = gain & 0x7F;  if (g <= 15) g = 16;
@     span = 0x8000 / g;                 // 512 for gain 64
@     lo = (0x800 - span) / 2;           // 768
@     hi = lo + span;                    // 1280
@     for (i = 0; i <= 0x7FF; i++)
@         mix_lut[i] = i <  lo ? -128
@                    : i >= hi ? 127
@                    : ((i - lo) * 256 / span) ^ 0x80;
@
@ GCC unrolled the loop four times; the four .Lbot_rampN blocks are the in-range case of each copy.
@ --------------------------------------------------------------------------------------------------
	.global Mixer_BuildOutputTable
	.thumb_func
	.type Mixer_BuildOutputTable, %function
Mixer_BuildOutputTable:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	movs r3, #0xfe	@ r3 = 0x7F0000
	lsls r0, r0, #0x10
	lsls r3, r3, #0xf
	ands r3, r0	@ r1 = gain & 0x7F
	asrs r1, r3, #0x10
	cmp r1, #0xf	@ if (g <= 15) g = 16
	bgt .Lmixapi_8035A1A
	movs r1, #0x10
.Lmixapi_8035A1A:
	ldr r3, .Llit_8035B28	@ sb = __divsi3 (kept for the loop)
	movs r0, #0x80	@ r0 = 0x8000
	lsls r0, r0, #8
	mov sb, r3
	bl .Lmixapi_8035A28	@ span = __divsi3(0x8000, g)
	b .Lmixapi_8035A2A
.Lmixapi_8035A28:
	bx r3
.Lmixapi_8035A2A:
	movs r3, #0x80
	lsls r0, r0, #0x10
	asrs r0, r0, #0x10	@ r0 = (s16)span
	lsls r3, r3, #4
	subs r3, r3, r0	@ r3 = 0x800 - span
	lsrs r2, r3, #0x1f
	adds r3, r3, r2
	lsls r3, r3, #0xf
	asrs r6, r3, #0x10	@ r6 = lo = (0x800 - span) / 2
	adds r0, r6, r0
	lsls r0, r0, #0x10
	asrs r5, r0, #0x10	@ r5 = hi = lo + span
	subs r3, r5, r6
	mov r8, r3	@ r8 = span (divisor)
	ldr r3, .Llit_8035B2C
	ldr r7, .Llit_8035B30	@ r7 = mix_lut
	movs r4, #0	@ i = 0
	mov sl, r3	@ sl = 0x7FF (last index)
.Lbot_loop:
	movs r0, #0	@ value = 0
	cmp r6, r4	@ i < lo ?
	bgt .Lmixapi_8035B22
	cmp r4, r5	@ i < hi ?
	blt .Lbot_ramp3
.Lmixapi_8035A58:
	movs r0, #0xff	@ i >= hi: value = 0xFF
.Lmixapi_8035A5A:
	movs r3, #0x80
	rsbs r3, r3, #0
	eors r0, r3	@ value ^= 0x80  (-> 0x7F, or 0x80 for i < lo)
	adds r3, r4, #1
	lsls r3, r3, #0x10
	strb r0, [r4, r7]	@ mix_lut[i] = value
	asrs r4, r3, #0x10
	movs r0, #0
	cmp r6, r4
	bgt .Lmixapi_8035B0A
	cmp r4, r5
	blt .Lbot_ramp2
.Lmixapi_8035A72:
	movs r0, #0xff
.Lmixapi_8035A74:
	movs r3, #0x80
	rsbs r3, r3, #0
	eors r0, r3
	adds r3, r4, #1
	lsls r3, r3, #0x10
	strb r0, [r4, r7]
	asrs r4, r3, #0x10
	movs r0, #0
	cmp r6, r4
	bgt .Lmixapi_8035AF2
	cmp r4, r5
	blt .Lbot_ramp1
.Lmixapi_8035A8C:
	movs r0, #0xff
.Lmixapi_8035A8E:
	movs r3, #0x80
	rsbs r3, r3, #0
	eors r0, r3
	adds r3, r4, #1
	lsls r3, r3, #0x10
	strb r0, [r4, r7]
	asrs r4, r3, #0x10
	movs r0, #0
	cmp r6, r4
	bgt .Lmixapi_8035ADA
	cmp r4, r5
	blt .Lbot_ramp0
.Lmixapi_8035AA6:
	movs r0, #0xff
.Lmixapi_8035AA8:
	movs r3, #0x80
	rsbs r3, r3, #0
	eors r0, r3
	adds r3, r4, #1
	lsls r3, r3, #0x10
	strb r0, [r4, r7]
	asrs r4, r3, #0x10
	cmp r4, sl	@ loop while i <= 0x7FF
	ble .Lbot_loop
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
.Lbot_ramp0:
	subs r0, r4, r6	@ in range: (i - lo) << 8
	lsls r0, r0, #8
	mov r1, r8
	bl .Lmixapi_8035AD4	@ / span
	b .Lmixapi_8035AD6
.Lmixapi_8035AD4:
	bx sb
.Lmixapi_8035AD6:
	lsls r0, r0, #0x18	@ (u8)
	lsrs r0, r0, #0x18
.Lmixapi_8035ADA:
	cmp r4, r5
	blt .Lmixapi_8035AA8
	b .Lmixapi_8035AA6
.Lbot_ramp1:
	subs r0, r4, r6
	lsls r0, r0, #8
	mov r1, r8
	bl .Lmixapi_8035AEC
	b .Lmixapi_8035AEE
.Lmixapi_8035AEC:
	bx sb
.Lmixapi_8035AEE:
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
.Lmixapi_8035AF2:
	cmp r4, r5
	blt .Lmixapi_8035A8E
	b .Lmixapi_8035A8C
.Lbot_ramp2:
	subs r0, r4, r6
	lsls r0, r0, #8
	mov r1, r8
	bl .Lmixapi_8035B04
	b .Lmixapi_8035B06
.Lmixapi_8035B04:
	bx sb
.Lmixapi_8035B06:
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
.Lmixapi_8035B0A:
	cmp r4, r5
	blt .Lmixapi_8035A74
	b .Lmixapi_8035A72
.Lbot_ramp3:
	subs r0, r4, r6
	lsls r0, r0, #8
	mov r1, r8
	bl .Lmixapi_8035B1C
	b .Lmixapi_8035B1E
.Lmixapi_8035B1C:
	bx sb
.Lmixapi_8035B1E:
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
.Lmixapi_8035B22:
	cmp r4, r5
	blt .Lmixapi_8035A5A
	b .Lmixapi_8035A58
.Llit_8035B28:
	.word __divsi3+1	@ 0803999D
.Llit_8035B2C:
	.word 0x000007FF
.Llit_8035B30:
	.word mix_lut	@ 03003860

@ --------------------------------------------------------------------------------------------------
@ void Mixer_ClearVoices(void)                                    (DirectSoundSystemMixer.cpp)
@
@     memset(mix_outbuf, 0, mixer.samplesPerFrame * 2);
@     for (g_game.i = 0; g_game.i < mixer.nVoices; g_game.i++)   // loop counter lives in the
@         mixer.voices[g_game.i].state = 0;                       // game object at 03002DF4+0x58
@ --------------------------------------------------------------------------------------------------
	.global Mixer_ClearVoices
	.thumb_func
	.type Mixer_ClearVoices, %function
Mixer_ClearVoices:
	push {r4, lr}
	ldr r4, .Llit_8035B78
	ldr r2, [r4, #4]	@ samplesPerFrame
	movs r1, #0
	lsls r2, r2, #1	@ * 2 bytes
	ldr r3, .Llit_8035B7C
	ldr r0, .Llit_8035B80
	bl .Lmixapi_8035B48	@ memset(mix_outbuf, 0, n)
	b .Lmixapi_8035B4A
.Lmixapi_8035B48:
	bx r3
.Lmixapi_8035B4A:
	ldr r1, .Llit_8035B84	@ r1 = &g_game
	ldr r3, [r4, #0xc]	@ nVoices
	movs r2, #0
	str r2, [r1, #0x58]	@ g_game.i = 0
	cmp r2, r3
	bhs .Lclr_done
	adds r0, r4, #0
	movs r4, #0
.Lclr_loop:
	ldr r3, [r1, #0x58]
	ldr r2, [r0]
	lsls r3, r3, #6	@ i * 64
	adds r3, r3, r2
	str r4, [r3]	@ voices[i].state = 0
	ldr r3, [r1, #0x58]
	ldr r2, [r0, #0xc]
	adds r3, #1	@ i++
	str r3, [r1, #0x58]
	cmp r3, r2
	blo .Lclr_loop
.Lclr_done:
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000	@ pad
.Llit_8035B78:
	.word mixer	@ 030031D8
.Llit_8035B7C:
	.word memset+1	@ 080332C5
.Llit_8035B80:
	.word mix_outbuf	@ 030031FC
.Llit_8035B84:
	.word g_game	@ 03002DF4

@ --------------------------------------------------------------------------------------------------
@ void Mixer_Init(int nVoices, int rate, int samplesPerFrame, int master)
@                                                                 (DirectSoundSystemMixer.cpp)
@ Hardcore Pool calls Mixer_Init(8, 18157, 304, 80) from GameEntry.
@
@     mixer.master          = (u8)master;      // +08
@     mixer.samplesPerFrame = (u16)samples;    // +04
@     mixer.bufOfs          = 0;               // +10
@     mixer.rate            = (u16)rate;       // +14  never read: hardware is fixed at 18157 Hz
@     mixer.nVoices         = nVoices;         // +0C
@     mixer.voices = Heap_Alloc(g_game.heap, 0x200, 2, "DirectSoundSystemMixer.cpp", 56);
@                                              // always 0x200 bytes = 8 voices
@     memset(mixer.voices, 0, nVoices * 64);
@     Mixer_BuildOutputTable(64);
@     Mixer_ClearVoices();
@ --------------------------------------------------------------------------------------------------
	.global Mixer_Init
	.thumb_func
	.type Mixer_Init, %function
Mixer_Init:
	push {r4, r5, r6, lr}
	ldr r5, .Llit_8035BEC
	lsls r3, r3, #0x18
	lsls r2, r2, #0x10
	lsrs r3, r3, #0x18
	lsrs r2, r2, #0x10
	str r3, [r5, #8]	@ mixer.master = (u8)master
	str r2, [r5, #4]	@ mixer.samplesPerFrame = (u16)samples
	ldr r3, .Llit_8035BF0
	movs r2, #0xf8	@ r2 = 0x3E0: g_game.heap
	lsls r2, r2, #2
	lsls r1, r1, #0x10
	adds r6, r0, #0
	adds r3, r3, r2
	movs r0, #0
	lsrs r1, r1, #0x10
	sub sp, #4
	str r0, [r5, #0x10]	@ mixer.bufOfs = 0
	str r1, [r5, #0x14]	@ mixer.rate = (u16)rate (unused)
	ldr r0, [r3]	@ r0 = g_game.heap
	movs r1, #0x80	@ r1 = 0x200 (fixed size!)
	movs r3, #0x38
	str r6, [r5, #0xc]	@ mixer.nVoices = nVoices
	lsls r1, r1, #2
	str r3, [sp]	@ arg5 = line 56
	movs r2, #2	@ r2 = 2
	ldr r3, .Llit_8035BF4	@ r3 = __FILE__
	ldr r4, .Llit_8035BF8
	bl .Lmixapi_8035BC6	@ Heap_Alloc(...)
	b .Lmixapi_8035BC8
.Lmixapi_8035BC6:
	bx r4
.Lmixapi_8035BC8:
	lsls r6, r6, #6	@ nVoices * 64
	movs r1, #0
	adds r2, r6, #0
	ldr r3, .Llit_8035BFC
	str r0, [r5]	@ mixer.voices = result
	bl .Lmixapi_8035BD8	@ memset(voices, 0, nVoices * 64)
	b .Lmixapi_8035BDA
.Lmixapi_8035BD8:
	bx r3
.Lmixapi_8035BDA:
	movs r0, #0x40	@ gain 64
	bl Mixer_BuildOutputTable
	bl Mixer_ClearVoices
	add sp, #4
	pop {r4, r5, r6}
	pop {r0}
	bx r0
.Llit_8035BEC:
	.word mixer	@ 030031D8
.Llit_8035BF0:
	.word g_game	@ 03002DF4
.Llit_8035BF4:
	.word str_DirectSoundSystemMixer_cpp	@ 083EC600
.Llit_8035BF8:
	.word Heap_Alloc+1	@ 08039431
.Llit_8035BFC:
	.word memset+1	@ 080332C5

@ --------------------------------------------------------------------------------------------------
@ void Mixer_Start(void)                                          (DirectSoundSystemMixer.cpp)
@
@     TM0CNT_H    = 0;
@     SOUNDCNT_X  = 0x0080;      // master enable
@     SOUNDCNT_L  = 0xFF77;      // PSG volume 7/7 and all PSG enables (the engine never uses PSG)
@     SOUNDCNT_H  = 0x0B0E;      // PSG 100%, DS-A 100% (DS-B bit too), A -> L+R, A on timer 0,
@                                // FIFO A reset
@     TM0CNT_L    = 0xFC64;      // -924: 16777216 / 924 = 18157 Hz = 304 samples per frame
@     TM0CNT_H    = 0x0080;      // start
@ The DMA is not set up here; VBlank_Sound starts it at the next V-blank.
@ --------------------------------------------------------------------------------------------------
	.global Mixer_Start
	.thumb_func
	.type Mixer_Start, %function
Mixer_Start:
	ldr r1, .Llit_8035C34
	ldr r3, .Llit_8035C20
	ldr r0, .Llit_8035C24
	strh r3, [r1, #2]	@ TM0CNT_H = 0
	ldr r3, .Llit_8035C38
	ldr r2, .Llit_8035C28
	strh r0, [r3]	@ SOUNDCNT_X = 0x80
	subs r3, #4
	strh r2, [r3]	@ SOUNDCNT_L = 0xFF77
	ldr r2, .Llit_8035C2C
	adds r3, #2
	strh r2, [r3]	@ SOUNDCNT_H = 0x0B0E
	ldr r3, .Llit_8035C30
	strh r3, [r1]	@ TM0CNT_L = 0xFC64
	strh r0, [r1, #2]	@ TM0CNT_H = 0x80
	b .Lstart_ret
.Llit_8035C20:
	.word 0x00000000
.Llit_8035C24:
	.word 0x00000080
.Llit_8035C28:
	.word 0xFFFFFF77
.Llit_8035C2C:
	.word 0x00000B0E
.Llit_8035C30:
	.word 0xFFFFFC64
.Llit_8035C34:
	.word REG_TM0CNT_L	@ 04000100
.Llit_8035C38:
	.word REG_SOUNDCNT_X	@ 04000084
.Lstart_ret:
	bx lr
	movs r0, r0

@ --------------------------------------------------------------------------------------------------
@ void Mixer_Stop(void)                                           (DirectSoundSystemMixer.cpp)
@
@     TM0CNT_L = TM0CNT_H = 0;
@     DMA1SAD = DMA1DAD = 0; DMA1CNT_H = 0;  DMA2SAD = DMA2DAD = 0; DMA2CNT_H = 0;
@     SOUNDCNT_X = 0;  SOUNDCNT_L = 0;  SOUNDCNT_H = 0;  TM0CNT_L = TM0CNT_H = 0;
@ --------------------------------------------------------------------------------------------------
	.global Mixer_Stop
	.thumb_func
	.type Mixer_Stop, %function
Mixer_Stop:
	ldr r1, .Llit_8035C7C
	ldr r2, .Llit_8035C78
	ldr r3, .Llit_8035C80
	strh r2, [r1]
	strh r2, [r3]
	movs r2, #0
	subs r3, #0x46	@ r3 = DMA1SAD
	str r2, [r3]	@ DMA1SAD = 0
	adds r3, #4
	str r2, [r3]	@ DMA1DAD = 0
	adds r3, #6
	strh r2, [r3]	@ DMA1CNT_H = 0
	adds r3, #2
	str r2, [r3]	@ DMA2SAD = 0
	adds r3, #4
	str r2, [r3]	@ DMA2DAD = 0
	adds r3, #6
	strh r2, [r3]	@ DMA2CNT_H = 0
	subs r3, #0x4e	@ r3 = SOUNDCNT_X
	strh r2, [r1, #2]
	strh r2, [r3]	@ SOUNDCNT_X = 0
	subs r3, #4
	strh r2, [r3]	@ SOUNDCNT_L = 0
	adds r3, #2
	strh r2, [r3]	@ SOUNDCNT_H = 0
	strh r2, [r1]
	strh r2, [r1, #2]
	b .Lstop_ret
.Llit_8035C78:
	.word 0x00000000
.Llit_8035C7C:
	.word REG_TM0CNT_L	@ 04000100
.Llit_8035C80:
	.word REG_TM0CNT_H	@ 04000102
.Lstop_ret:
	bx lr
	movs r0, r0

@ --------------------------------------------------------------------------------------------------
@ int Mixer_FindFreeVoice(void)                                   (DirectSoundSystemMixer.cpp)
@
@     i = (mus_state.paused && mus_state.module) ? mus_state.module->nch : 0;
@     while (i != 8 && mixer.voices[i].state != 0) i++;
@     return i;                           // 8 = none free
@
@ The search skips the music channels only while the music is paused; during playback it can
@ return a music voice whose sample has ended (the test looks inverted). One caller (0803B0E4).
@ --------------------------------------------------------------------------------------------------
	.global Mixer_FindFreeVoice
	.thumb_func
	.type Mixer_FindFreeVoice, %function
Mixer_FindFreeVoice:
	push {lr}
	ldr r2, .Llit_8035CC4
	ldr r3, [r2, #0x24]	@ paused?
	movs r0, #0
	cmp r3, #0
	beq .Lffv_search
	ldr r3, [r2, #0x10]	@ module?
	cmp r3, #0
	beq .Lffv_search
	ldrb r0, [r3]	@ start = module->nch
.Lffv_search:
	cmp r0, #8	@ i == 8: none free
	beq .Lffv_done
	ldr r1, .Llit_8035CC8
	ldr r3, [r1]
	lsls r2, r0, #6
	ldr r3, [r2, r3]	@ voices[i].state
	cmp r3, #0
	beq .Lffv_done
.Lffv_next:
	adds r3, r0, #1	@ i++
	lsls r3, r3, #0x18
	lsrs r0, r3, #0x18
	cmp r0, #8
	beq .Lffv_done
	ldr r3, [r1]
	lsls r2, r0, #6
	ldr r3, [r2, r3]
	cmp r3, #0
	bne .Lffv_next
.Lffv_done:
	pop {r1}
	bx r1
.Llit_8035CC4:
	.word mus_state	@ 03000000
.Llit_8035CC8:
	.word mixer	@ 030031D8

@==================================================================================================
@ musapi  (Thumb, .text.fuh_music)  VMA 08039260-080393AC
@==================================================================================================
	.section .text.fuh_music,"ax",%progbits
	.balign 4
	.thumb
	.syntax unified

@ --------------------------------------------------------------------------------------------------
@ int Mus_Play(const Module *m, int order, int fadeIn)
@
@     mus_state.state = 0;  mus_state.module = 0;           // stop the player first
@     if (m->norders == 0) return 0;
@     mus_state.pattern = m->orders[order];
@     if (*(u8 *)mus_state.pattern == 0) return 0;         // row count read as a BYTE
@     mus_state.order = order;  mus_state.data = pattern->data;  mus_state.row = 0;
@     mus_state.speed = mus_state.tick = m->speed;          // row 0 is read on the next tick
@     mus_state.unused0C = m->unused08;
@     mus_state.state = 2;  mus_state.module = m;
@     if (!mus_state.paused && mixer.musicVol == 0) mixer.fadeDelta = fadeIn;
@     return 1;
@ Voices still sounding from the previous tune are not stopped.
@ --------------------------------------------------------------------------------------------------
	.global Mus_Play
	.thumb_func
	.type Mus_Play, %function
Mus_Play:
	push {r4, r5, r6, lr}
	adds r5, r1, #0
	ldr r1, .Llit_80392B8
	movs r4, #0
	str r4, [r1]	@ state = 0
	str r4, [r1, #0x10]	@ module = 0
	ldr r3, [r0, #4]	@ m->norders
	adds r6, r2, #0
	cmp r3, #0
	beq .Lplay_fail
	ldr r3, [r0, #0x14]	@ m->orders
	lsls r2, r5, #2
	ldr r2, [r2, r3]	@ orders[order]
	str r2, [r1, #0x14]	@ mus_state.pattern
	ldrb r3, [r2]	@ rows (byte)
	cmp r3, #0
	bne .Lplay_ok
.Lplay_fail:
	movs r0, #0
.Lplay_ret:
	pop {r4, r5, r6}
	pop {r1}
	bx r1
.Lplay_ok:
	ldr r3, [r2, #4]	@ pattern->data
	str r5, [r1, #0x1c]	@ mus_state.order
	str r3, [r1, #0x18]	@ mus_state.data
	str r4, [r1, #0x20]	@ mus_state.row = 0
	ldr r3, [r0, #0xc]
	str r3, [r1, #8]	@ speed = m->speed
	ldr r3, [r0, #0xc]
	str r3, [r1, #4]	@ tick = m->speed
	ldr r3, [r0, #8]
	str r3, [r1, #0xc]	@ unused0C = m->unused08
	movs r3, #2
	str r3, [r1]	@ state = 2
	ldr r3, [r1, #0x24]	@ paused?
	str r0, [r1, #0x10]	@ module = m
	cmp r3, #0
	bne .Lplay_ok_ret
	ldr r2, .Llit_80392BC
	ldr r3, [r2, #0x1c]	@ mixer.musicVol
	cmp r3, #0
	bne .Lplay_ok_ret
	str r6, [r2, #0x20]	@ mixer.fadeDelta = fadeIn
.Lplay_ok_ret:
	movs r0, #1
	b .Lplay_ret
.Llit_80392B8:
	.word mus_state	@ 03000000
.Llit_80392BC:
	.word mixer	@ 030031D8

@ --------------------------------------------------------------------------------------------------
@ void Mus_Stop(void)                                             UNREFERENCED, BROKEN
@
@     mus_state.state = 1;  mus_state.module = 0;
@ Player_Tick only tests state != 0, so the next tick would read the NULL module (BIOS area) and
@ use garbage as the channel count. Nothing calls this function.
@ --------------------------------------------------------------------------------------------------
	.global Mus_Stop
	.thumb_func
	.type Mus_Stop, %function
Mus_Stop:
	ldr r3, .Llit_80392CC
	movs r2, #1
	str r2, [r3]
	movs r2, #0
	str r2, [r3, #0x10]
	bx lr
.Llit_80392CC:
	.word mus_state	@ 03000000

@ --------------------------------------------------------------------------------------------------
@ void Mus_TogglePause(int fadeStep)
@
@     mus_state.paused = !mus_state.paused;
@     if (mus_state.paused) { mus_state.savedVol = mixer.musicVol;  mixer.fadeDelta = ~fadeStep; }
@     else                    mixer.fadeDelta = fadeStep;
@ The player keeps running while paused (silently, after the fade). savedVol is never read.
@ --------------------------------------------------------------------------------------------------
	.global Mus_TogglePause
	.thumb_func
	.type Mus_TogglePause, %function
Mus_TogglePause:
	push {lr}
	ldr r1, .Llit_80392F8
	ldr r3, [r1, #0x24]
	movs r2, #0
	cmp r3, #0
	bne .Lmusapi_80392DE
	movs r2, #1
.Lmusapi_80392DE:
	str r2, [r1, #0x24]	@ paused = !paused
	cmp r2, #0
	beq .Lpause_resume
	ldr r3, .Llit_80392FC
	ldr r2, [r3, #0x1c]
	str r2, [r1, #0x28]	@ savedVol = musicVol
	mvns r2, r0	@ ~fadeStep = -(fadeStep+1)
	str r2, [r3, #0x20]	@ fade out
.Lpause_ret:
	pop {r0}
	bx r0
.Lpause_resume:
	ldr r3, .Llit_80392FC
	str r0, [r3, #0x20]	@ fade in
	b .Lpause_ret
.Llit_80392F8:
	.word mus_state	@ 03000000
.Llit_80392FC:
	.word mixer	@ 030031D8

@ --------------------------------------------------------------------------------------------------
@ void Mus_SetFade(int delta)
@
@     if (mus_state.module && !mus_state.paused) mixer.fadeDelta = delta;
@ Player_Tick adds fadeDelta to musicVol once per ROW and clears it at 0 or 256.
@ --------------------------------------------------------------------------------------------------
	.global Mus_SetFade
	.thumb_func
	.type Mus_SetFade, %function
Mus_SetFade:
	push {lr}
	ldr r2, .Llit_8039318
	ldr r3, [r2, #0x10]
	cmp r3, #0
	beq .Lfade_ret
	ldr r3, [r2, #0x24]
	cmp r3, #0
	bne .Lfade_ret
	ldr r3, .Llit_803931C
	str r0, [r3, #0x20]
.Lfade_ret:
	pop {r0}
	bx r0
.Llit_8039318:
	.word mus_state	@ 03000000
.Llit_803931C:
	.word mixer	@ 030031D8

@ --------------------------------------------------------------------------------------------------
@ void Mus_WaitFade(void)
@
@     if (mus_state.module && !mus_state.paused) while (mixer.fadeDelta) ;   // busy-wait
@ --------------------------------------------------------------------------------------------------
	.global Mus_WaitFade
	.thumb_func
	.type Mus_WaitFade, %function
Mus_WaitFade:
	push {lr}
	ldr r2, .Llit_803933C
	ldr r3, [r2, #0x10]
	cmp r3, #0
	beq .Lwait_ret
	ldr r3, [r2, #0x24]
	cmp r3, #0
	bne .Lwait_ret
	ldr r2, .Llit_8039340
.Lwait_loop:
	ldr r3, [r2, #0x20]
	cmp r3, #0
	bne .Lwait_loop
.Lwait_ret:
	pop {r0}
	bx r0
.Llit_803933C:
	.word mus_state	@ 03000000
.Llit_8039340:
	.word mixer	@ 030031D8

@ --------------------------------------------------------------------------------------------------
@ void Mus_SetState4(void)                                        UNREFERENCED
@
@     if (mus_state.module) mus_state.state = 4;      // the player treats any non-zero state alike
@ --------------------------------------------------------------------------------------------------
	.global Mus_SetState4
	.thumb_func
	.type Mus_SetState4, %function
Mus_SetState4:
	push {lr}
	ldr r2, .Llit_8039358
	ldr r3, [r2, #0x10]
	cmp r3, #0
	beq .Lst4_ret
	movs r3, #4
	str r3, [r2]
.Lst4_ret:
	pop {r0}
	bx r0
	.hword 0x0000	@ pad
.Llit_8039358:
	.word mus_state	@ 03000000

@ --------------------------------------------------------------------------------------------------
@ void Mus_JumpToOrder(int order)
@
@     if (!mus_state.module) return;
@     Mus_SetFade(256);                                // full volume again at the next row
@     voices[0..3].state = 0;                          // hard-coded 4 voices
@     mus_state.pattern = module->orders[order];  mus_state.order = order;
@     mus_state.data = pattern->data;  mus_state.row = 0;     // tick is not reset
@ The game switches tunes with: Mus_SetFade(-30); Mus_WaitFade(); Mus_JumpToOrder(n);
@ --------------------------------------------------------------------------------------------------
	.global Mus_JumpToOrder
	.thumb_func
	.type Mus_JumpToOrder, %function
Mus_JumpToOrder:
	push {r4, r5, lr}
	ldr r4, .Llit_80393A4
	ldr r3, [r4, #0x10]
	adds r5, r0, #0
	cmp r3, #0
	bne .Ljump_go
.Ljump_ret:
	pop {r4, r5}
	pop {r0}
	bx r0
.Ljump_go:
	movs r0, #0x80
	lsls r0, r0, #1
	bl Mus_SetFade	@ Mus_SetFade(256)
	ldr r2, .Llit_80393A8
	ldr r3, [r2]
	movs r1, #0
	str r1, [r3]	@ voices[0].state = 0
	ldr r3, [r2]
	str r1, [r3, #0x40]	@ voices[1].state = 0
	ldr r3, [r2]
	adds r3, #0x80
	str r1, [r3]	@ voices[2].state = 0
	ldr r3, [r2]
	adds r3, #0xc0
	str r1, [r3]	@ voices[3].state = 0
	ldr r3, [r4, #0x10]
	ldr r2, [r3, #0x14]	@ module->orders
	lsls r3, r5, #2
	ldr r3, [r3, r2]
	str r3, [r4, #0x14]	@ mus_state.pattern
	ldr r3, [r3, #4]
	str r5, [r4, #0x1c]	@ mus_state.order
	str r3, [r4, #0x18]	@ mus_state.data
	str r1, [r4, #0x20]	@ mus_state.row = 0
	b .Ljump_ret
	.hword 0x0000	@ pad
.Llit_80393A4:
	.word mus_state	@ 03000000
.Llit_80393A8:
	.word mixer	@ 030031D8

@==================================================================================================
@ mix  (ARM, .iwram.fuh_mix)  VMA 03000408-030005A0, ROM 083ECB2C
@==================================================================================================
	.section .iwram.fuh_mix,"ax",%progbits
	.balign 4
	.arm
	.syntax unified

@ ==================================================================================================
@ void Mix_Frame(Mixer *mx)                         ARM, runs from IWRAM; called by VBlank_Sound
@
@ Mixes mx->samplesPerFrame (304) samples of every active voice into the other half of mix_outbuf.
@
@     fill mix_acc[0..samples) with 0x0400 (16-bit, two per word; 0x400 = centre of mix_lut)
@     mix_masterVol = mx->master;                 // patched into this routine's literal pool
@     mx->bufOfs ^= 0x200;
@     for (v = mx->voices, n = mx->nVoices; n; n--, v++) {
@         if (!v->state) continue;
@         end = v->loopEnd ? v->loopEnd : v->end;
@         g   = (mix_masterVol * v->vol) >> 6;
@         for (each PAIR of output samples) {
@             p = v->ptr + (frac >> 16);
@             if (p > end) {                       // tested once per pair
@                 if (v->loopEnd) { frac = 0; v->ptr = v->loopStart; p = v->ptr; }
@                 else            { v->state = 0; v->ptr = 0; break; }
@             }
@             s0 = *p;               frac += step;  p = v->ptr + (frac >> 16);
@             s1 = *p;               frac += step;
@             acc32[i] += ((s0 * g >> 6) & 0xFFFF) | ((s1 * g >> 6) << 16);
@         }
@         v->ptr += frac >> 16;  v->frac = (u16)frac;
@     }
@     for (i = 0; i < samples; i++) out[i] = mix_lut[acc[i]];    // 4 samples per pass
@
@ Notes: no interpolation; at a loop wrap the overshoot and fraction are dropped; a negative even
@ sample carries +1 into the odd half of its pair; mix_lut is indexed without a range check.
@ Register use in the voice loop: r0 step, r1 frac (16.16, accumulating), r2 ptr, r3 end,
@ r4 gain, r5 acc pointer, r6 acc end, r7 voice+4, r8 sample pointer, sl 0xFFFF mask.
@ ==================================================================================================
	.global Mix_Frame
	.type Mix_Frame, %function
Mix_Frame:
	push {r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}
	ldr ip, [r0, #4]	@ ip = samplesPerFrame
	ldr sl, mix_pAcc	@ sl = mix_acc
	ldr fp, mix_pBiasFill	@ fp = &mix_biasFill
	ldm fp, {r2, r3, r4, r5, r6, r7, r8, sb}	@ 8 words of 0x04000400
.Lmix_clear:
	stm sl!, {r2, r3, r4, r5, r6, r7, r8, sb}	@ 16 samples per store
	subs ip, ip, #0x10
	bne .Lmix_clear
	str r2, [sl]	@ one extra word (harmless overrun)
	ldm r0, {r7, r8, sb, sl, fp, ip}	@ r7 voices, r8 samples, r9 master, sl nVoices, fp bufOfs, ip rate
	ldr r2, mix_pMasterVol
	str sb, [r2]	@ self-modify: mix_masterVol = master
	eor fp, fp, #0x200	@ flip buffer halves
	str fp, [r0, #0x10]	@ mx->bufOfs
.Lmix_voice:
	ldr r0, [r7], #4	@ r0 = v->state, r7 = &v->step
	cmp r0, #0
	beq .Lmix_voice_next
	ldm r7, {r0, r1, r2, r3, r4, r5, r6}	@ r0 step, r1 frac, r2 ptr, r3 end, r4 loopStart, r5 loopEnd, r6 vol
	cmp r5, #0
	movne r3, r5	@ looping: test against loopEnd instead
	ldr sb, mix_masterVol	@ master (patched literal)
	mul r4, sb, r6	@ gain = master * vol
	lsr r4, r4, #6	@ >> 6
	ldr r5, mix_pAcc
	add r6, r5, r8, lsl #1	@ r6 = acc end = acc + 2*samples
	push {r8, sl}	@ save samples, voice counter
	mov sl, #0xff
	orr sl, sl, #0xff00	@ sl = 0xFFFF
	mov r8, #0
.Lmix_pair:
	add r8, r2, r1, lsr #16	@ p = ptr + (frac >> 16)
	cmp r8, r3	@ past the end?
	ble .Lmix_pair_body
	ldr ip, [r7, #0x14]	@ v->loopEnd
	cmp ip, #0
	beq .Lmix_oneshot_end
	mov r1, #0	@ loop: frac = 0
	ldr r2, [r7, #0x10]	@ ptr = v->loopStart (overshoot dropped)
	mov r8, r2
	b .Lmix_pair_body
.Lmix_oneshot_end:
	mov r2, #0	@ one-shot finished:
	str r2, [r7, #-4]	@ v->state = 0
	b .Lmix_voice_save
.Lmix_pair_body:
	ldrsb ip, [r8]	@ s0
	mul ip, r4, ip	@ * gain
	and ip, sl, ip, asr #6	@ >> 6, 16 bits
	add r1, r1, r0	@ frac += step
	add r8, r2, r1, lsr #16
	ldrsb sb, [r8]	@ s1 (no end test)
	mul sb, r4, sb
	and sb, sl, sb, asr #6
	add r1, r1, r0
	orr ip, ip, sb, lsl #16	@ pack the pair
	ldr sb, [r5]
	add sb, ip, sb	@ acc pair += packed (low-half borrow carries into high)
	str sb, [r5], #4	@ store, next pair
	cmp r5, r6
	bne .Lmix_pair
	add r2, r2, r1, lsr #16	@ ptr += frac >> 16
.Lmix_voice_save:
	pop {r8, sl}
	str r2, [r7, #8]	@ v->ptr
	strh r1, [r7, #4]	@ v->frac (low 16 bits)
.Lmix_voice_next:
	add r7, r7, #0x3c	@ next voice (r7 was +4 already)
	subs sl, sl, #1
	bne .Lmix_voice
	ldr ip, mix_pOutBuf	@ ip = mix_outbuf + bufOfs
	add ip, ip, fp
	ldr r6, mix_pLut	@ r6 = mix_lut
	ldr r0, mix_pAcc	@ r0 = mix_acc
.Lmix_out:
	ldr r1, [r0], #4
	ldrb r2, [r6, r1, lsr #16]	@ lut[sample 1 (high half)]
	lsl r1, r1, #0x10
	ldrb r3, [r6, r1, lsr #16]	@ lut[sample 0 (low half)]
	orr r2, r3, r2, lsl #8	@ two bytes, in order
	ldr r1, [r0], #4
	ldrb r3, [r6, r1, lsr #16]
	lsl r1, r1, #0x10
	ldrb r7, [r6, r1, lsr #16]
	orr r3, r7, r3, lsl #8
	orr r2, r2, r3, lsl #16
	str r2, [ip], #4	@ 4 output bytes
	subs r8, r8, #4	@ r8 = samples, 4 per pass
	bne .Lmix_out
	pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}
	bx lr
.Lmix_dead:
	mov r0, #0	@ unreachable leftover code
	str r0, [r7, #-4]
	bge .Lmix_voice_save
	bx lr
	.global mix_pLut
	.type mix_pLut, %object
mix_pLut:
	.word mix_lut	@ output table (2048 bytes)
	.global mix_pOutBuf
	.type mix_pOutBuf, %object
mix_pOutBuf:
	.word mix_outbuf	@ output double buffer
	.global mix_masterVol
	.type mix_masterVol, %object
mix_masterVol:
	.word 0x00000000	@ SELF-MODIFIED: master volume, written every frame
	.global mix_pMasterVol
	.type mix_pMasterVol, %object
mix_pMasterVol:
	.word mix_masterVol	@ &mix_masterVol
	.global mix_pAcc
	.type mix_pAcc, %object
mix_pAcc:
	.word mix_acc	@ accumulator
	.global mix_biasFill
	.type mix_biasFill, %object
mix_biasFill:
	.word 0x04000400	@ bias pattern (0x400 per sample)
	.word 0x04000400
	.word 0x04000400
	.word 0x04000400
	.word 0x04000400
	.word 0x04000400
	.word 0x04000400
	.word 0x04000400
	.global mix_pBiasFill
	.type mix_pBiasFill, %object
mix_pBiasFill:
	.word mix_biasFill	@ &mix_biasFill

@==================================================================================================
@ player  (ARM, .iwram.fuh_player)  VMA 03002838-03002DF4, ROM 083EEF5C
@==================================================================================================
	.section .iwram.fuh_player,"ax",%progbits
	.balign 4
	.arm
	.syntax unified

@ ==================================================================================================
@ void Player_Tick(void)                            ARM, runs from IWRAM; called by VBlank_Sound
@
@ One call per frame. Register conventions used by every effect handler:
@     r0 = &mus_state.tick (mus_state + 4)    sl = module       r7 = current voice (= channel)
@     r3 = row-effect parameter               r4 = tick parameter (voice.mem24)
@     r5 = tick handler to install (row handlers return it; 0 = none)
@     r6 = 1 after a position jump            r9 = pattern data pointer   r2 = 1 if a note was read
@
@     if (!mus_state.state) return;
@     if (++tick < speed) {                                   // effect tick
@         for (each of module->nch voices) if (v->handler) v->handler(r4 = v->mem24);
@         return;
@     }
@     tick = 0;                                                // row tick: no tick handlers
@     for (each channel) {
@         flags = *data++;  handler = 0;
@         if (flags & 0x01) Player_Note();
@         if (flags & 0x80) v->chanVol = *data++;
@         if (flags & 0x7E) { p = *data++;  r5 = FxRowTable[(flags & 0x7E) / 4](p); }
@         v->handler = r5;
@     }
@     if (jumped) return;                                      // also skips the volume update
@     mus_state.data = data;
@     if (++row >= pattern->rows) { row = 0; if (++order >= module->norders) order = 0;
@                                   pattern = module->orders[order]; data = pattern->data; }
@     mixer.musicVol = clamp(mixer.musicVol + mixer.fadeDelta, 0, 256)   // delta = 0 at a limit
@     for (each channel) v->vol = v->chanVol * mixer.musicVol >> 8;    // volume only on rows
@ ==================================================================================================
	.global Player_Tick
	.type Player_Tick, %function
Player_Tick:
	push {r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}
	ldr r0, .Llit_3002DA4	@ r0 = &mus_state
	ldr r1, [r0], #4	@ state; r0 -> &tick
	cmp r1, #0
	beq .Lplayer_exit	@ stopped
	ldr sl, [r0, #0xc]	@ sl = module
	ldr r1, [r0]	@ tick
	ldr r2, [r0, #4]	@ speed
	add r1, r1, #1
	cmp r1, r2	@ tick + 1 >= speed: row
	bge .Lrow
	str r1, [r0]	@ tick++
	ldr r7, .Llit_3002DA8
	ldr r7, [r7]	@ r7 = voices
	ldr ip, [sl]	@ ip = module->nch
.Ltick_loop:
	ldr r5, [r7, #0x20]	@ v->handler
	cmp r5, #0
	beq .Ltick_next
	ldr r4, [r7, #0x24]	@ r4 = v->mem24
	mov lr, pc	@ call handler
	bx r5
.Ltick_next:
	add r7, r7, #0x40	@ next voice
	subs ip, ip, #1
	bne .Ltick_loop
	pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}
	bx lr
.Lrow:
	mov r1, #0
	str r1, [r0]	@ tick = 0
	ldr r8, [r0, #0x10]	@ r8 = pattern
	ldr sb, [r0, #0x14]	@ r9 = data
	mov r6, #0	@ r6 = jumped = 0
	ldr r2, [r0, #0x18]
	ldr r3, [r0, #0x1c]
	ldr r7, .Llit_3002DA8
	ldr r7, [r7]
	ldr ip, [sl]
.Lrow_chan:
	ldrb r1, [sb], #1	@ flags
	mov r5, #0	@ r5 = no handler
	cmp r1, #0
	beq .Lrow_next	@ empty event
	and r2, r1, #1
	cmp r2, #1
	bleq Player_Note	@ note + instrument
	mov r5, #0	@ r5 = no handler
	and r3, r1, #0x80
	cmp r3, #0
	beq .Lrow_fx
	ldrb r3, [sb], #1	@ volume byte
	str r3, [r7, #0x3c]	@ v->chanVol
.Lrow_fx:
	and r4, r1, #0x7e	@ effect bits (offset into table)
	cmp r4, #0
	beq .Lrow_next
	ldrb r3, [sb], #1	@ r3 = parameter
	ldr fp, .Llit_3002DA0	@ FxRowTable
	ldr fp, [fp, r4]	@ handler = table[(flags & 0x7E) / 4]
	mov lr, pc	@ call (returns r5)
	bx fp
.Lrow_next:
	str r5, [r7, #0x20]	@ v->handler = r5
	add r7, r7, #0x40
	subs ip, ip, #1
	bne .Lrow_chan
	cmp r6, #1	@ position jump?
	beq .Lplayer_exit
	str sb, [r0, #0x14]	@ mus_state.data
	ldr r3, [r0, #0x1c]	@ row
	ldr r5, [r8]	@ pattern->rows
	add r3, r3, #1
	cmp r3, r5	@ row + 1 < rows?
	blt .Lrow_storerow
	mov r3, #0
	ldr r2, [r0, #0x18]	@ order
	add r2, r2, #1
	ldr r5, [sl, #4]	@ module->norders
	cmp r2, r5
	blt .Lrow_setpat
	mov r2, #0	@ wrap to order 0
.Lrow_setpat:
	ldr r4, [sl, #0x14]	@ module->orders
	ldr r4, [r4, r2, lsl #2]
	str r4, [r0, #0x10]	@ mus_state.pattern
	ldr r4, [r4, #4]
	str r4, [r0, #0x14]	@ mus_state.data
	str r2, [r0, #0x18]	@ mus_state.order
.Lrow_storerow:
	str r3, [r0, #0x1c]	@ mus_state.row
	ldr r8, .Llit_3002DA8	@ r8 = &mixer
	ldr r7, [r8]
	ldr ip, [sl]
	ldr r6, [r8, #0x1c]	@ musicVol
	ldr r5, [r8, #0x20]	@ fadeDelta
	cmp r5, #0
	addne r6, r5, r6
	mov r2, #0
	cmp r6, #0
	movlt r6, #0	@ clamp at 0
	strlt r2, [r8, #0x20]	@ and stop fading
	cmp r6, #0x100
	movgt r6, #0x100	@ clamp at 256
	strgt r2, [r8, #0x20]
	str r6, [r8, #0x1c]	@ mixer.musicVol
.Lrow_vol:
	ldr r3, [r7, #0x3c]	@ v->chanVol
	mul r3, r6, r3	@ * musicVol
	lsr r3, r3, #8	@ >> 8
	str r3, [r7, #0x1c]	@ v->vol
	add r7, r7, #0x40
	subs ip, ip, #1
	bne .Lrow_vol
.Lplayer_exit:
	pop {r0, r1, r2, r3, r4, r5, r6, r7, r8, sb, sl, fp, ip, lr}
	bx lr

@ --------------------------------------------------------------------------------------------------
@ Player_Note      (ARM, internal; entered with BL from Player_Tick)
@
@     period = *(u16 *)data;  data += 2;  v->tpTarget = period;
@     if ((flags & 0xFE) == 0x10) { data++; return 1; }   // tone porta (effect 4, no volume byte)
@     v->period = period;  v->step = StepTable[period];
@     i = *data++;  if (i == 0) i = v->mem38; else v->mem38 = i;   // mem38 shared with effect 15
@     ins = module->instruments[i];
@     if (instrument byte != 0) v->chanVol = ins->volume;
@     v->ptr = pcm->data;  v->end = pcm->data + pcm->length;
@     v->loopStart = pcm->data + ins->loopStart;
@     v->loopEnd = ins->loopEnd ? pcm->data + ins->loopEnd : 0;
@     v->frac = 0;  v->state = 2;  return 1 (in r2);
@ --------------------------------------------------------------------------------------------------
	.global Player_Note
	.type Player_Note, %function
Player_Note:
	ldrb r4, [sb], #1
	ldrb r5, [sb], #1
	orr r4, r4, r5, lsl #8	@ period (u16 LE)
	str r4, [r7, #0x34]	@ v->tpTarget
	and fp, r1, #0xfe	@ flags & 0xFE
	cmp fp, #0x10	@ == effect 4 without volume?
	addeq sb, sb, #1	@ skip instrument byte
	beq .Lnote_ret
	str r4, [r7, #0x2c]	@ v->period
	ldr fp, .Llit_3002DAC	@ StepTable
	ldr fp, [fp, r4, lsl #2]	@ [period]
	str fp, [r7, #4]	@ v->step
	ldrb r4, [sb], #1	@ instrument byte
	mov r2, r4
	cmp r4, #0
	ldreq r4, [r7, #0x38]	@ 0: previous (v->mem38)
	strne r4, [r7, #0x38]	@ else remember
	ldr fp, [sl, #0x10]	@ module->instruments
	ldr r4, [fp, r4, lsl #2]	@ ins
	cmp r2, #0
	ldrne r5, [r4, #8]	@ byte != 0: ins->volume
	strne r5, [r7, #0x3c]	@ v->chanVol
	ldr fp, [r4, #0xc]	@ ins->pcm
	ldr r5, [fp]	@ pcm->length
	ldr fp, [fp, #4]	@ pcm->data
	add r5, fp, r5
	str fp, [r7, #0xc]	@ v->ptr
	str r5, [r7, #0x10]	@ v->end
	ldr r5, [r4]	@ ins->loopStart
	add r5, r5, fp
	str r5, [r7, #0x14]	@ v->loopStart
	ldr r4, [r4, #4]	@ ins->loopEnd
	cmp r4, #0
	addne r4, r4, fp
	str r4, [r7, #0x18]	@ v->loopEnd (0 = one-shot)
	mov fp, #0
	str fp, [r7, #8]	@ v->frac = 0
	mov r5, #2
	str r5, [r7]	@ v->state = 2
.Lnote_ret:
	mov r2, #1	@ r2 = 1: note read
	bx lr

@ --------------------------------------------------------------------------------------------------
@ Row-effect handlers: called with r3 = parameter; return the tick handler in r5 (or leave
@ r5 = 0). Tick handlers: called with r4 = v->mem24, r7 = voice. All end with bx lr.
@
@ Effect 1: store the parameter only (data always uses 0x95).
@ --------------------------------------------------------------------------------------------------
	.global Fx01_StoreParam
	.type Fx01_StoreParam, %function
Fx01_StoreParam:
	str r3, [r7, #0x24]	@ v->mem24 = p (no tick handler)
	bx lr

@ Effect 2: portamento up.  Tick: period -= mem24 * 4 (only signed overflow is caught).
	.global Fx02_PortaUp
	.type Fx02_PortaUp, %function
Fx02_PortaUp:
	ldr r5, .Llit_3002AC0	@ r5 = Tick_PortaUp
	cmp r3, #0
	strne r3, [r7, #0x24]	@ if (p) v->mem24 = p
	bx lr
	.global Tick_PortaUp
	.type Tick_PortaUp, %function
Tick_PortaUp:
	ldr fp, [r7, #0x2c]
	subs fp, fp, r4, lsl #2	@ period -= mem24*4
	movvs fp, #0	@ (V flag only)
	str fp, [r7, #0x2c]
	ldr r6, .Llit_3002DAC
	ldr r6, [r6, fp, lsl #2]	@ StepTable[period]
	str r6, [r7, #4]	@ v->step
	bx lr
.Llit_3002AC0:
	.word Tick_PortaUp	@ 03002AA0

@ Effect 3: portamento down.  Tick: period += mem24 * 4 (no clamp).
	.global Fx03_PortaDown
	.type Fx03_PortaDown, %function
Fx03_PortaDown:
	ldr r5, .Llit_3002AF0	@ r5 = Tick_PortaDown
	cmp r3, #0
	strne r3, [r7, #0x24]	@ if (p) v->mem24 = p
	bx lr
	.global Tick_PortaDown
	.type Tick_PortaDown, %function
Tick_PortaDown:
	ldr fp, [r7, #0x2c]
	add fp, fp, r4, lsl #2	@ period += mem24*4
	str fp, [r7, #0x2c]
	ldr r6, .Llit_3002DAC
	ldr r6, [r6, fp, lsl #2]	@ StepTable[period]
	str r6, [r7, #4]	@ v->step
	bx lr
.Llit_3002AF0:
	.word Tick_PortaDown	@ 03002AD4

@ Effect 4: tone portamento toward v->tpTarget by mem24 * 4 per tick.
	.global Fx04_TonePorta
	.type Fx04_TonePorta, %function
Fx04_TonePorta:
	cmp r3, #0
	strne r3, [r7, #0x24]	@ if (p) v->mem24 = p
	ldr r5, .Llit_3002B50	@ r5 = Tick_TonePorta
	bx lr
	.global Tick_TonePorta
	.type Tick_TonePorta, %function
Tick_TonePorta:
	ldr r5, [r7, #0x34]	@ target
	ldr r6, [r7, #0x2c]	@ period
	cmp r6, r5
	beq .Ltp_ret	@ reached
	bgt .Ltp_down
	add r6, r6, r4, lsl #2	@ below: += speed
	cmp r6, r5
	blt .Ltp_store
	b .Ltp_clamp
.Ltp_down:
	sub r6, r6, r4, lsl #2	@ above: -= speed
	cmp r5, r6
	movgt r6, r5	@ clamp at target
	bgt .Ltp_store
.Ltp_clamp:
	mov r6, r5	@ clamp at target
.Ltp_store:
	ldr fp, .Llit_3002DAC
	str r6, [r7, #0x2c]	@ v->period
	ldr fp, [fp, r6, lsl #2]
	str fp, [r7, #4]	@ v->step
.Ltp_ret:
	bx lr
.Llit_3002B50:
	.word Tick_TonePorta	@ 03002B04

@ Effect 5: set channel volume (no clamp).
	.global Fx05_SetVolume
	.type Fx05_SetVolume, %function
Fx05_SetVolume:
	str r3, [r7, #0x3c]	@ v->chanVol = p
	bx lr

@ Effects 7 and 8: vibrato xy (speed x, depth y).
@ Row: phase = 0 on a new note; if (p) mem24 = mem30 = p.
@ Tick: phase = (phase + x) & 63;  step = StepTable[period + (VibratoSine[phase]*y >> 7)*4].
	.global Fx07_Vibrato
	.type Fx07_Vibrato, %function
Fx07_Vibrato:
	cmp r2, #0
	movne r5, #0	@ new note: phase = 0
	strne r5, [r7, #0x28]
	cmp r3, #0
	strne r3, [r7, #0x24]	@ if (p) v->mem24 = p
	strne r3, [r7, #0x30]	@ and v->mem30 (for effect 12)
	ldr r5, .Llit_3002BC4	@ r5 = Tick_Vibrato
	bx lr
	.global Tick_Vibrato
	.type Tick_Vibrato, %function
Tick_Vibrato:
	lsr r6, r4, #4	@ x = speed
	ldr fp, [r7, #0x28]
	add fp, fp, r6
	cmp fp, #0x40
	subhs fp, fp, #0x40
	str fp, [r7, #0x28]	@ v->phase
	ldr r5, .Llit_3002DB0
	ldrsb fp, [r5, fp]	@ sine (index 16 holds 0x80 = -128)
	and r4, r4, #0xf	@ y = depth
	mul fp, r4, fp
	asr fp, fp, #7	@ >> 7
	ldr r5, [r7, #0x2c]
	adds r5, r5, fp, lsl #2	@ period + delta*4 (period itself unchanged)
	movvs r5, #0
	ldr r6, .Llit_3002DAC
	ldr r6, [r6, r5, lsl #2]
	str r6, [r7, #4]	@ v->step
	bx lr
.Llit_3002BC4:
	.word Tick_Vibrato	@ 03002B7C
	.global Fx11_None
	.type Fx11_None, %function
Fx11_None:
	bx lr

@ Effect 12: vibrato (from mem30) + volume slide xy (mem24 = p, even when 0).
	.global Fx12_VibVolSlide
	.type Fx12_VibVolSlide, %function
Fx12_VibVolSlide:
	ldr r5, .Llit_3002C50	@ r5 = Tick_VibVolSlide
	str r3, [r7, #0x24]	@ v->mem24 = p
	bx lr
	.global Tick_VibVolSlide
	.type Tick_VibVolSlide, %function
Tick_VibVolSlide:
	ldr fp, [r7, #0x3c]	@ chanVol
	and r6, r4, #0xf
	subs fp, fp, r6	@ -= y
	movmi fp, #0	@ clamp 0
	lsr r4, r4, #4
	add fp, fp, r4	@ += x
	cmp fp, #0x40
	movhi fp, #0x40	@ clamp 64
	str fp, [r7, #0x3c]
	ldr r4, [r7, #0x30]	@ vibrato parameter (mem30)
	cmp r4, #0
	beq .Lvvs_ret	@ none set
	lsr r6, r4, #4
	ldr fp, [r7, #0x28]
	add fp, fp, r6
	cmp fp, #0x40
	subhs fp, fp, #0x40
	str fp, [r7, #0x28]
	ldr r5, .Llit_3002DB0
	ldrsb fp, [r5, fp]
	and r4, r4, #0xf
	mul fp, r4, fp
	asr fp, fp, #7
	ldr r5, [r7, #0x2c]
	adds r5, r5, fp, lsl #2
	movvs r5, #0
	ldr r6, .Llit_3002DAC
	ldr r6, [r6, r5, lsl #2]
	str r6, [r7, #4]
.Lvvs_ret:
	bx lr
.Llit_3002C50:
	.word Tick_VibVolSlide	@ 03002BD8
	.global Fx13_None
	.type Fx13_None, %function
Fx13_None:
	bx lr

@ Effect 14: position jump to order p, row 0 (sets r6 = 1: rest of the row tick is skipped).
	.global Fx14_PositionJump
	.type Fx14_PositionJump, %function
Fx14_PositionJump:
	ldr fp, [sl, #0x14]
	ldr r4, [fp, r3, lsl #2]	@ module->orders[p]
	str r4, [r0, #0x10]	@ mus_state.pattern
	ldr r4, [r4, #4]
	str r4, [r0, #0x14]	@ mus_state.data
	mov fp, #0
	str r3, [r0, #0x18]	@ mus_state.order
	str fp, [r0, #0x1c]	@ mus_state.row = 0
	mov r6, #1	@ jumped = 1
	bx lr

@ Effect 15: sample offset p*256. Memory is v->mem38, the SAME field as the last instrument.
	.global Fx15_SampleOffset
	.type Fx15_SampleOffset, %function
Fx15_SampleOffset:
	ldr fp, [r7, #0xc]	@ v->ptr
	cmp r3, #0
	strne r3, [r7, #0x38]	@ if (p) mem38 = p
	ldreq r3, [r7, #0x38]	@ else p = mem38 (may be an instrument no.)
	add fp, fp, r3, lsl #8	@ ptr += p << 8 (end not checked)
	str fp, [r7, #0xc]
	bx lr

@ Effect 6: volume slide xy (mem24 = p, even when 0). Tick: chanVol = clamp(chanVol - y + x, 0, 64).
@ The change reaches the voice at the next ROW (Player_Tick only writes v->vol on rows).
	.global Fx06_VolSlide
	.type Fx06_VolSlide, %function
Fx06_VolSlide:
	ldr r5, .Llit_3002CD0	@ r5 = Tick_VolSlide
	str r3, [r7, #0x24]	@ v->mem24 = p
	bx lr
	.global Tick_VolSlide
	.type Tick_VolSlide, %function
Tick_VolSlide:
	ldr fp, [r7, #0x3c]
	and r6, r4, #0xf
	subs fp, fp, r6
	movmi fp, #0
	lsr r4, r4, #4
	add fp, fp, r4
	cmp fp, #0x40
	movhi fp, #0x40
	str fp, [r7, #0x3c]
	bx lr
.Llit_3002CD0:
	.word Tick_VolSlide	@ 03002CA8

@ Effect 9: set speed (frames per row).  Effects 0, 10, 11, 13, 16-30: no operation.
	.global Fx09_SetSpeed
	.type Fx09_SetSpeed, %function
Fx09_SetSpeed:
	str r3, [r0, #4]	@ mus_state.speed = p
	bx lr
	.global Fx10_None
	.type Fx10_None, %function
Fx10_None:
	bx lr
	.global Fx16_None
	.type Fx16_None, %function
Fx16_None:
	bx lr
	.global Fx17_None
	.type Fx17_None, %function
Fx17_None:
	bx lr
	.global Fx18_None
	.type Fx18_None, %function
Fx18_None:
	bx lr
	.global Fx19_None
	.type Fx19_None, %function
Fx19_None:
	bx lr
	.global Fx20_None
	.type Fx20_None, %function
Fx20_None:
	bx lr
	.global Fx21_None
	.type Fx21_None, %function
Fx21_None:
	bx lr
	.global Fx22_None
	.type Fx22_None, %function
Fx22_None:
	bx lr
	.global Fx23_None
	.type Fx23_None, %function
Fx23_None:
	bx lr
	.global Fx24_None
	.type Fx24_None, %function
Fx24_None:
	bx lr
	.global Fx25_None
	.type Fx25_None, %function
Fx25_None:
	bx lr
	.global Fx26_None
	.type Fx26_None, %function
Fx26_None:
	bx lr
	.global Fx27_None
	.type Fx27_None, %function
Fx27_None:
	bx lr
	.global Fx28_None
	.type Fx28_None, %function
Fx28_None:
	bx lr
	.global Fx29_None
	.type Fx29_None, %function
Fx29_None:
	bx lr
	.global Fx30_None
	.type Fx30_None, %function
Fx30_None:
	bx lr
	.global Fx00_None
	.type Fx00_None, %function
Fx00_None:
	bx lr

@ Row-effect handler table, indexed by (flags & 0x7E) / 4. Entry 31 is the 0 terminator:
@ effect 31 would branch to address 0.
	.global FxRowTable
	.type FxRowTable, %object
FxRowTable:
	.word Fx00_None	@ 03002D1C
	.word Fx01_StoreParam	@ 03002A88
	.word Fx02_PortaUp	@ 03002A90
	.word Fx03_PortaDown	@ 03002AC4
	.word Fx04_TonePorta	@ 03002AF4
	.word Fx05_SetVolume	@ 03002B54
	.word Fx06_VolSlide	@ 03002C9C
	.word Fx07_Vibrato	@ 03002B5C
	.word Fx07_Vibrato	@ 03002B5C
	.word Fx09_SetSpeed	@ 03002CD4
	.word Fx10_None	@ 03002CDC
	.word Fx11_None	@ 03002BC8
	.word Fx12_VibVolSlide	@ 03002BCC
	.word Fx13_None	@ 03002C54
	.word Fx14_PositionJump	@ 03002C58
	.word Fx15_SampleOffset	@ 03002C80
	.word Fx16_None	@ 03002CE0
	.word Fx17_None	@ 03002CE4
	.word Fx18_None	@ 03002CE8
	.word Fx19_None	@ 03002CEC
	.word Fx20_None	@ 03002CF0
	.word Fx21_None	@ 03002CF4
	.word Fx22_None	@ 03002CF8
	.word Fx23_None	@ 03002CFC
	.word Fx24_None	@ 03002D00
	.word Fx25_None	@ 03002D04
	.word Fx26_None	@ 03002D08
	.word Fx27_None	@ 03002D0C
	.word Fx28_None	@ 03002D10
	.word Fx29_None	@ 03002D14
	.word Fx30_None	@ 03002D18
	.word 0x00000000
.Llit_3002DA0:
	.word FxRowTable	@ 03002D20
.Llit_3002DA4:
	.word mus_state	@ 03000000
.Llit_3002DA8:
	.word mixer	@ 030031D8
.Llit_3002DAC:
	.word StepTable	@ 083E1E00
.Llit_3002DB0:
	.word VibratoSine	@ 03002DB4

@ Vibrato sine, 64 x s8. Index 16 should be +128 but holds 0x80, read as -128 (bug).
	.global VibratoSine
	.type VibratoSine, %object
VibratoSine:
	.byte 0x00, 0x0C, 0x18, 0x25, 0x30, 0x3C, 0x47, 0x51, 0x5A, 0x62, 0x6A, 0x70, 0x76, 0x7A, 0x7D, 0x7F
	.byte 0x80, 0x7F, 0x7D, 0x7A, 0x76, 0x70, 0x6A, 0x62, 0x5A, 0x51, 0x47, 0x3C, 0x30, 0x25, 0x18, 0x0C
	.byte 0x00, 0xF4, 0xE8, 0xDB, 0xD0, 0xC4, 0xB9, 0xAF, 0xA6, 0x9E, 0x96, 0x90, 0x8A, 0x86, 0x83, 0x81
	.byte 0x80, 0x81, 0x83, 0x86, 0x8A, 0x90, 0x96, 0x9E, 0xA6, 0xAF, 0xB9, 0xC4, 0xD0, 0xDB, 0xE8, 0xF4

