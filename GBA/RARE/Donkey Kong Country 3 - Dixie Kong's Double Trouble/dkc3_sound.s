@ ==========================================================================
@ Rare GBA sound driver (Donkey Kong Country 3, Europe, BDQP) - reconstructed source
@ ROM 0x080AECB4-0x080B1A08. Assembles byte-identical with:
@   arm-none-eabi-as -mcpu=arm7tdmi -o dkc3_sound.o dkc3_sound.s
@   arm-none-eabi-ld -Ttext=0x080AECB4 -o dkc3_sound.elf dkc3_sound.o
@   arm-none-eabi-objcopy -O binary dkc3_sound.elf dkc3_sound.bin
@ The ARM block (iwram_code_start..iwram_code_end) is copied to IWRAM 0x03002A20
@ by snd_init and runs there; (x - iwram_code_start + IWRAM_CODE_BASE) is the run-time address.
@ Labels, names and comments are reverse-engineered, not original symbols.
@ ==========================================================================
	.syntax unified
	.cpu arm7tdmi
	.text

	.equ IWRAM_CODE_BASE, 0x03002A20

@ ---- hardware registers ----
	.equ REG_VCOUNT,            0x04000006
	.equ REG_SOUNDCNT_H,        0x04000082
	.equ REG_SOUNDCNT_X,        0x04000084
	.equ REG_SOUNDBIAS_H,       0x04000089
	.equ REG_FIFO_A,            0x040000A0
	.equ REG_DMA1SAD,           0x040000BC
	.equ REG_DMA1DAD,           0x040000C0
	.equ REG_DMA1CNT_L,         0x040000C4
	.equ REG_DMA1CNT_H,         0x040000C6
	.equ REG_DMA2SAD,           0x040000C8
	.equ REG_TM0CNT_L,          0x04000100
	.equ REG_TM0CNT_H,          0x04000102
@ ---- constants ----
	.equ USEC_PER_MINUTE,       0x03938700
@ ---- game data outside the driver ----
	.equ cfg_buffer_a,          0x080E4A70   @ ptr -> 8-bit output buffer A (0x03002570)
	.equ cfg_buffer_b,          0x080E4A78   @ ptr -> 8-bit output buffer B (0x03002730)
	.equ cfg_music_pool_bytes,  0x080E4A80   @ 0xF00 = 96 voices
	.equ cfg_chan_pool_bytes,   0x080E4A84   @ 0xF0 = 6 voices per channel
	.equ cfg_sfx_pool_bytes,    0x080E4A88   @ 0xC8 = 5 voices
	.equ cfg_sfx_voices,        0x080E4A8C   @ 5
	.equ cfg_voices_per_chan,   0x080E4A94   @ 6
	.equ sfx_table,             0x0871F644   @ 
	.equ song_table,            0x0871F970   @ 
@ ---- IWRAM variables ----
	.equ seq_num_tracks,        0x03001290   @ tracks in current song
	.equ mix_samples_per_frame, 0x03001294   @ 176/224/304/352
	.equ mix_timer_reload,      0x03001298   @ Timer 0 reload
	.equ seq_prog_map_ptr,      0x0300129C   @ song+0x0C: 128-byte program -> instrument index map
	.equ seq_current_song,      0x030012A0   @ -1 = none
	.equ seq_loop_ptr,          0x030012B0   @ [16] track pointer saved by CC102
	.equ chan_mod,              0x030012F0   @ [16] {u32 mod wheel (CC1), u32 LFO phase (24-bit)}
	.equ sfx_table_ptr,         0x03001370   @ array of sample-instrument pointers, one per SFX id
	.equ chan_volume,           0x03001380   @ [16] CC7
	.equ seq_frame_time,        0x03001390   @ microseconds<<8 elapsed per frame
	.equ seq_track_ptr,         0x030013A0   @ [16] current event pointer per track
	.equ seq_division,          0x030013E0   @ ticks per quarter note
	.equ sfx_master_volume,     0x030013E4   @ 
	.equ music_paused,          0x030013E8   @ 
	.equ chan_cc100,            0x030013F0   @ [16] CC100 value - written, never read
	.equ chan_gain,             0x03001400   @ DKC3: [16] per-channel gain, written by game code; 0 = channel skipped
	.equ mix_max_voices,        0x03001410   @ 
	.equ chan_bend,             0x03001420   @ [16] u32 14-bit pitch bend
	.equ mix_pitch_scale,       0x03001460   @ 2^38 / mixing rate
	.equ seq_pending_song,      0x03001464   @ -1 = none
	.equ chan_instrument,       0x03001470   @ [16] current instrument pointer
	.equ chan_mono,             0x030014B0   @ [16] 1 = mono (CC126), 0 = poly (CC127)
	.equ music_voices,          0x030014C0   @ [96] x 0x28
	.equ seq_start_marker,      0x030023C0   @ DKC3: CC104 marker to start the next song at, -1 = none (written by game code)
	.equ music_master_volume,   0x030023C4   @ 
	.equ sfx_handle,            0x030023D0   @ [8] handle per SFX voice (5 used)
	.equ chan_adsr_override,    0x030023F0   @ DKC3: [16] x {A,D,S,R} from CC20-23, >= 0x80 = use instrument
	.equ sfx_timer,             0x03002430   @ [8] frames to auto key-off (5 used)
	.equ seq_track_time,        0x030027D0   @ [16] s64 time until next event, us<<8
	.equ mix_buffer,            0x03002850   @ s16 x 224
	.equ seq_inst_table_ptr,    0x03002A10   @ song+0x10: instrument pointer table
	.equ sfx_handle_counter,    0x03003C54   @ 
	.equ sfx_voices,            0x03003C60   @ [5] x 0x28
	.equ mix_rate_hz,           0x03003D28   @ 
	.equ seq_tempo,             0x03003D2C   @ microseconds per quarter note
	.equ dma_buffer_flag,       0x03003D30   @ toggled by snd_vblank
	.equ song_table_ptr,        0x03003D34   @ 


@ iwram_code_size: Size of the IWRAM block, read by snd_init
iwram_code_size:
	.word 0x00001234
	.balign 4
iwram_code_start:
	.arm

@ ------------------------------------------------------------------
@ voice_start   ROM 0x080AECB8 / IWRAM 0x03002A20 (ARM)
@ Start a voice. In: r5=voice, r2=sample-instrument, r1=pitch mult (16.16), r3=volume,
@ r4=MIDI key (for note-off matching), r7=loop mode, sb=pitch key. Sets state=0x11 (key on).
@ ------------------------------------------------------------------
voice_start:
	stmdb sp!, {lr}                      @ 080AECB8
	strb r3, [r5, #3]                    @ 080AECBC
	str r1, [r5, #0x24]                  @ 080AECC0
	strb r7, [r5, #1]                    @ 080AECC4
	strb r4, [r5, #2]                    @ 080AECC8
	strb sb, [r5, #5]                    @ 080AECCC
	ldr r1, [r2, #0x10]                  @ 080AECD0
	str r1, [r5, #0xc]                   @ 080AECD4
	mov r1, #0                           @ 080AECD8
	str r1, [r5, #0x10]                  @ 080AECDC
	strb r1, [r5, #4]                    @ 080AECE0
	str r1, [r5, #0x14]                  @ 080AECE4
	str r2, [r5, #0x20]                  @ 080AECE8
	mov r8, #0x11                        @ 080AECEC
	strb r8, [r5]                        @ 080AECF0
	ldm sp!, {lr}                        @ 080AECF4
	bx lr                                @ 080AECF8

@ ------------------------------------------------------------------
@ mix_frame   ROM 0x080AECFC / IWRAM 0x03002A64 (ARM)
@ Render one frame: mix up to mix_max_voices voices (SFX key-on, SFX released,
@ music key-on, music released - in that priority order) into the s16 mix buffer, then clip
@ to s8 into the DirectSound buffer that the DMA is NOT currently playing.
@ ------------------------------------------------------------------
mix_frame:
	sub sp, sp, #0x28                    @ 080AECFC
	str lr, [sp, #8]                     @ 080AED00
	ldr r5, lit_80AF5D0                  @ 080AED04  = mix_buffer
	str r5, [sp, #4]                     @ 080AED08
	ldr r1, lit_80AF5D4                  @ 080AED0C  = mix_max_voices
	ldr r1, [r1]                         @ 080AED10
	str r1, [sp, #0x10]                  @ 080AED14
	ldr r2, lit_80AF5D8                  @ 080AED18  = cfg_sfx_pool_bytes
	ldr r2, [r2]                         @ 080AED1C
	ldr r0, lit_80AF5DC                  @ 080AED20  = sfx_voices
	add r0, r0, r2                       @ 080AED24
L_80AED28:
	ldrb r5, [r0, -r2]                   @ 080AED28
	cmp r5, #0x11                        @ 080AED2C
	bleq mix_frame_voice                 @ 080AED30  SFX voices, key on
	subs r2, r2, #0x28                   @ 080AED34
	bgt L_80AED28                        @ 080AED38
	ldr r2, lit_80AF5E0                  @ 080AED3C  = cfg_sfx_pool_bytes
	ldr r2, [r2]                         @ 080AED40
L_80AED44:
	ldrb r5, [r0, -r2]                   @ 080AED44
	cmp r5, #0x12                        @ 080AED48
	bleq mix_frame_voice                 @ 080AED4C  SFX voices, released
	subs r2, r2, #0x28                   @ 080AED50
	bgt L_80AED44                        @ 080AED54
	ldr r0, lit_80AF5E4                  @ 080AED58  = music_paused
	ldr r1, [r0]                         @ 080AED5C
	cmp r1, #1                           @ 080AED60
	beq L_80AEDA8                        @ 080AED64
	ldr r2, lit_80AF5E8                  @ 080AED68  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 080AED6C
	ldr r0, lit_80AF5EC                  @ 080AED70  = music_voices
	add r0, r0, r2                       @ 080AED74
L_80AED78:
	ldrb r5, [r0, -r2]                   @ 080AED78
	cmp r5, #0x11                        @ 080AED7C
	bleq mix_frame_voice                 @ 080AED80  music voices, key on
	subs r2, r2, #0x28                   @ 080AED84
	bgt L_80AED78                        @ 080AED88
	ldr r2, lit_80AF5F0                  @ 080AED8C  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 080AED90
L_80AED94:
	ldrb r5, [r0, -r2]                   @ 080AED94
	cmp r5, #0x12                        @ 080AED98
	bleq mix_frame_voice                 @ 080AED9C  music voices, released
	subs r2, r2, #0x28                   @ 080AEDA0
	bgt L_80AED94                        @ 080AEDA4
L_80AEDA8:
	ldr r0, [sp, #0x10]                  @ 080AEDA8
	ldr r1, lit_80AF5F4                  @ 080AEDAC  = mix_max_voices
	ldr r1, [r1]                         @ 080AEDB0
	cmp r0, r1                           @ 080AEDB4
	bne L_80AEDC8                        @ 080AEDB8
	ldr r0, lit_80AF5F8                  @ 080AEDBC  = clear_mix_buffer+1 ; nothing mixed -> zero the buffer (Thumb, via bx)
	add lr, pc, #0                       @ 080AEDC0
	bx r0                                @ 080AEDC4
L_80AEDC8:
	ldr r0, lit_80AF5FC                  @ 080AEDC8  = dma_buffer_flag
	ldr r2, [r0]                         @ 080AEDCC
	ldr r1, lit_80AF600                  @ 080AEDD0  = cfg_buffer_a
	cmp r2, #0                           @ 080AEDD4
	bne L_80AEDE0                        @ 080AEDD8
	ldr r1, lit_80AF604                  @ 080AEDDC  = cfg_buffer_b
L_80AEDE0:
	ldr r1, [r1]                         @ 080AEDE0
	ldr r0, lit_80AF608                  @ 080AEDE4  = mix_buffer
	ldr r2, lit_80AF60C                  @ 080AEDE8  = mix_samples_per_frame
	ldr r2, [r2]                         @ 080AEDEC
L_80AEDF0:
	ldr r3, [r0], #4                     @ 080AEDF0
	lsl lr, r3, #0x10                    @ 080AEDF4
	asr lr, lr, #0x10                    @ 080AEDF8
	cmp lr, #0x7f                        @ 080AEDFC
	movgt lr, #0x7f                      @ 080AEE00
	cmnlt lr, #0x80                      @ 080AEE04
	mvnlt lr, #0x7f                      @ 080AEE08
	strb lr, [r1], #1                    @ 080AEE0C
	asr lr, r3, #0x10                    @ 080AEE10
	cmp lr, #0x7f                        @ 080AEE14
	movgt lr, #0x7f                      @ 080AEE18
	cmnlt lr, #0x80                      @ 080AEE1C
	mvnlt lr, #0x7f                      @ 080AEE20
	strb lr, [r1], #1                    @ 080AEE24
	subs r2, r2, #2                      @ 080AEE28
	bne L_80AEDF0                        @ 080AEE2C
	ldr lr, [sp, #8]                     @ 080AEE30
	add sp, sp, #0x28                    @ 080AEE34
	bx lr                                @ 080AEE38

@ ------------------------------------------------------------------
@ mix_frame_voice   ROM 0x080AEE3C / IWRAM 0x03002BA4 (ARM)
@ mix_frame helper: mix voice (r0-r2) and count it against the voice budget; when the
@ budget hits zero, abandon the scan and go straight to the s16->s8 conversion.
@ ------------------------------------------------------------------
mix_frame_voice:
	str lr, [sp, #0xc]                   @ 080AEE3C
	str r0, [sp, #0x14]                  @ 080AEE40
	str r2, [sp, #0x18]                  @ 080AEE44
	sub r0, r0, r2                       @ 080AEE48
	ldr r5, [sp, #4]                     @ 080AEE4C
	bl mix_voice                         @ 080AEE50
	ldr r1, [sp, #0x10]                  @ 080AEE54
	cmp r1, #0                           @ 080AEE58
	beq L_80AEDC8                        @ 080AEE5C
	ldr r0, [sp, #0x14]                  @ 080AEE60
	ldr r2, [sp, #0x18]                  @ 080AEE64
	ldr pc, [sp, #0xc]                   @ 080AEE68

@ ------------------------------------------------------------------
@ advance_sfx_voices   ROM 0x080AEE6C / IWRAM 0x03002BD4 (ARM)
@ Advance the playback position of every active SFX voice by one frame.
@ ------------------------------------------------------------------
advance_sfx_voices:
	stmdb sp!, {lr}                      @ 080AEE6C
	ldr fp, lit_80AF610                  @ 080AEE70  = cfg_sfx_pool_bytes
	ldr fp, [fp]                         @ 080AEE74
	ldr sl, lit_80AF614                  @ 080AEE78  = sfx_voices
	add sl, sl, fp                       @ 080AEE7C
	b L_80AEE98                          @ 080AEE80

@ ------------------------------------------------------------------
@ advance_music_voices   ROM 0x080AEE84 / IWRAM 0x03002BEC (ARM)
@ Advance the playback position of every active music voice by one frame.
@ ------------------------------------------------------------------
advance_music_voices:
	stmdb sp!, {lr}                      @ 080AEE84
	ldr fp, lit_80AF618                  @ 080AEE88  = cfg_music_pool_bytes
	ldr fp, [fp]                         @ 080AEE8C
	ldr sl, lit_80AF61C                  @ 080AEE90  = music_voices
	add sl, sl, fp                       @ 080AEE94
L_80AEE98:
	ldrb r2, [sl, -fp]                   @ 080AEE98
	cmp r2, #0x11                        @ 080AEE9C
	bleq voice_advance                   @ 080AEEA0
	cmp r2, #0x12                        @ 080AEEA4
	bleq voice_advance                   @ 080AEEA8
	subs fp, fp, #0x28                   @ 080AEEAC
	bgt L_80AEE98                        @ 080AEEB0
	ldm sp!, {lr}                        @ 080AEEB4
	bx lr                                @ 080AEEB8

@ ------------------------------------------------------------------
@ voice_advance   ROM 0x080AEEBC / IWRAM 0x03002C24 (ARM)
@ Advance one voice (r0=voice) by mix_samples_per_frame samples using 64-bit maths,
@ then handle end-of-sample (loop or free). The mixer never writes positions back; this pass does.
@ NOTE: loop mode 1 frees the voice through [r8] instead of [r0] (bug, fixed in DKC3).
@ ------------------------------------------------------------------
voice_advance:
	sub r0, sl, fp                       @ 080AEEBC
	ldr r7, [r0, #8]                     @ 080AEEC0
	movs r7, r7                          @ 080AEEC4
	bne L_80AEED8                        @ 080AEEC8
	push {sl, fp, lr}                    @ 080AEECC
	bl calc_pitch                        @ 080AEED0
	pop {sl, fp, lr}                     @ 080AEED4
L_80AEED8:
	ldr r1, lit_80AF620                  @ 080AEED8  = mix_samples_per_frame
	ldr r1, [r1]                         @ 080AEEDC
	ldr r2, [r0, #0x10]                  @ 080AEEE0
	ldr r3, [r0, #0xc]                   @ 080AEEE4
	mov r6, #0                           @ 080AEEE8
	str r6, [r0, #8]                     @ 080AEEEC
	ldr r6, [r0, #0x24]                  @ 080AEEF0
	umull r4, r5, r6, r7                 @ 080AEEF4  step * pitch multiplier (16.16)
	lsr r7, r4, #0x10                    @ 080AEEF8
	add r7, r7, r5, lsl #16              @ 080AEEFC
	orr r2, r2, r3, lsl #23              @ 080AEF00
	lsr r3, r3, #9                       @ 080AEF04
	umlal r2, r3, r7, r1                 @ 080AEF08
	ldr r4, lit_80AF624                  @ 080AEF0C  = 0x007FFFFF
	and r1, r2, r4                       @ 080AEF10
	lsr r2, r2, #0x17                    @ 080AEF14
	orr r2, r2, r3, lsl #9               @ 080AEF18
	ldr r3, [r0, #0x20]                  @ 080AEF1C
	ldr r3, [r3, #0x18]                  @ 080AEF20
	cmp r2, r3                           @ 080AEF24
	blt L_80AEF80                        @ 080AEF28
	ldrb r4, [r0, #1]                    @ 080AEF2C
	cmp r4, #1                           @ 080AEF30
	beq L_80AEF74                        @ 080AEF34
	cmp r4, #2                           @ 080AEF38
	beq L_80AEF50                        @ 080AEF3C
	cmp r4, #3                           @ 080AEF40
	beq L_80AEF68                        @ 080AEF44
	cmp r4, #4                           @ 080AEF48
	beq L_80AEF50                        @ 080AEF4C
L_80AEF50:
	ldr r4, [r0, #0x20]                  @ 080AEF50
	ldr r4, [r4, #0x14]                  @ 080AEF54
L_80AEF58:
	sub r2, r2, r4                       @ 080AEF58
	cmp r2, r3                           @ 080AEF5C
	bge L_80AEF58                        @ 080AEF60
	b L_80AEF80                          @ 080AEF64
L_80AEF68:
	mov r3, #0x10                        @ 080AEF68
	strb r3, [r0]                        @ 080AEF6C  fixed in DKC3: was [r8]
	b L_80AEF80                          @ 080AEF70
L_80AEF74:
	mov r3, #0x10                        @ 080AEF74
	strb r3, [r0]                        @ 080AEF78  BUG: should be [r0]
	b L_80AEF80                          @ 080AEF7C
L_80AEF80:
	str r2, [r0, #0xc]                   @ 080AEF80
	str r1, [r0, #0x10]                  @ 080AEF84
	mov pc, lr                           @ 080AEF88

@ ------------------------------------------------------------------
@ env_update_sfx   ROM 0x080AEF8C / IWRAM 0x03002CF4 (ARM)
@ Run one envelope step on every active SFX voice.
@ ------------------------------------------------------------------
env_update_sfx:
	stmdb sp!, {lr}                      @ 080AEF8C
	ldr fp, lit_80AF628                  @ 080AEF90  = cfg_sfx_pool_bytes
	ldr fp, [fp]                         @ 080AEF94
	ldr sl, lit_80AF62C                  @ 080AEF98  = sfx_voices
	add sl, sl, fp                       @ 080AEF9C
	mov sb, #1                           @ 080AEFA0
	b L_80AEFC0                          @ 080AEFA4

@ ------------------------------------------------------------------
@ env_update_music   ROM 0x080AEFA8 / IWRAM 0x03002D10 (ARM)
@ Run one envelope step on every active music voice.
@ ------------------------------------------------------------------
env_update_music:
	stmdb sp!, {lr}                      @ 080AEFA8
	ldr fp, lit_80AF630                  @ 080AEFAC  = cfg_music_pool_bytes
	ldr fp, [fp]                         @ 080AEFB0
	ldr sl, lit_80AF634                  @ 080AEFB4  = music_voices
	add sl, sl, fp                       @ 080AEFB8
	mov sb, #0                           @ 080AEFBC
L_80AEFC0:
	ldrb r2, [sl, -fp]                   @ 080AEFC0
	cmp r2, #0x11                        @ 080AEFC4
	bleq env_step                        @ 080AEFC8
	cmp r2, #0x12                        @ 080AEFCC
	bleq env_step                        @ 080AEFD0
L_80AEFD4:
	subs fp, fp, #0x28                   @ 080AEFD4
	bgt L_80AEFC0                        @ 080AEFD8
	ldm sp!, {lr}                        @ 080AEFDC
	bx lr                                @ 080AEFE0

@ ------------------------------------------------------------------
@ env_step   ROM 0x080AEFE4 / IWRAM 0x03002D4C (ARM)
@ Dispatch on voice+4 (envelope phase 0-6) through env_jump_table.
@ ------------------------------------------------------------------
env_step:
	sub ip, sl, fp                       @ 080AEFE4
	ldrb r1, [ip, #4]                    @ 080AEFE8
	add r2, pc, #4                       @ 080AEFEC  = env_jump_table
	ldr r0, [r2, r1, lsl #2]             @ 080AEFF0
	add pc, r0, r2                       @ 080AEFF4

@ env_jump_table: 7 x offset from env_jump_table
env_jump_table:
	.word L_80AF014 - env_jump_table
	.word env_attack - env_jump_table
	.word L_80AF0B4 - env_jump_table
	.word env_decay - env_jump_table
	.word env_sustain - env_jump_table
	.word env_release_init - env_jump_table
	.word env_release - env_jump_table
L_80AF014:
	movs sb, sb                          @ 080AF014
	bne env_attack_init                  @ 080AF018
	ldr r8, lit_80AF638                  @ 080AF01C  = chan_adsr_override ; DKC3: CC20 override < 0x80 is used directly as the attack time in frames
	mov r2, #4                           @ 080AF020
	ldrb r1, [ip, #6]                    @ 080AF024
	mla r8, r2, r1, r8                   @ 080AF028
	ldrb r0, [r8]                        @ 080AF02C
	cmp r0, #0x80                        @ 080AF030
	blt L_80AF050                        @ 080AF034

@ ------------------------------------------------------------------
@ env_attack_init   ROM 0x080AF038 / IWRAM 0x03002DA0 (ARM)
@ Phase 0: attack time = (99-A)*32/99 frames; 0 = instant (go to decay at full level).
@ ------------------------------------------------------------------
env_attack_init:
	ldr r3, [ip, #0x20]                  @ 080AF038
	ldr r1, [r3, #0x24]                  @ 080AF03C
	rsb r2, r1, #0x63                    @ 080AF040
	lsl r0, r2, #5                       @ 080AF044
	mov r1, #0x63                        @ 080AF048
	bl udiv_32_16                        @ 080AF04C  udiv_32_16
L_80AF050:
	movs r0, r0                          @ 080AF050
	beq L_80AF0A0                        @ 080AF054
	mov r1, r0                           @ 080AF058
	mov r0, #0x8000                      @ 080AF05C
	add r1, r1, #1                       @ 080AF060
	bl udiv_32_16                        @ 080AF064
	lsl r1, r1, #4                       @ 080AF068
	lsl r0, r0, #4                       @ 080AF06C
	str r1, [ip, #0x14]                  @ 080AF070
	str r0, [ip, #0x18]                  @ 080AF074
	mov r0, #1                           @ 080AF078
	strb r0, [ip, #4]                    @ 080AF07C

@ ------------------------------------------------------------------
@ env_attack   ROM 0x080AF080 / IWRAM 0x03002DE8 (ARM)
@ Phase 1: ramp level up by env_inc; on key-off go to release.
@ ------------------------------------------------------------------
env_attack:
	ldrb r1, [ip]                        @ 080AF080
	cmp r1, #0x12                        @ 080AF084
	beq env_release_init                 @ 080AF088
	ldr r1, [ip, #0x18]                  @ 080AF08C
	ldr r2, [ip, #0x14]                  @ 080AF090
	add r1, r1, r2                       @ 080AF094
	cmp r1, #0x80000                     @ 080AF098
	blt L_80AF0AC                        @ 080AF09C
L_80AF0A0:
	mov r1, #2                           @ 080AF0A0
	strb r1, [ip, #4]                    @ 080AF0A4
	mov r1, #0x80000                     @ 080AF0A8
L_80AF0AC:
	str r1, [ip, #0x14]                  @ 080AF0AC
	sub pc, pc, #0xe4                    @ 080AF0B0  -> L_80AEFD4
L_80AF0B4:
	movs sb, sb                          @ 080AF0B4
	bne env_decay_init                   @ 080AF0B8
	ldr r8, lit_80AF63C                  @ 080AF0BC  = chan_adsr_override ; DKC3: CC21 (decay frames) / CC22 (sustain level /128) overrides
	mov r2, #4                           @ 080AF0C0
	ldrb r1, [ip, #6]                    @ 080AF0C4
	mla r8, r2, r1, r8                   @ 080AF0C8
	ldrb r0, [r8, #2]                    @ 080AF0CC
	cmp r0, #0x80                        @ 080AF0D0
	bge env_decay_init                   @ 080AF0D4
	lsl r0, r0, #8                       @ 080AF0D8
	b L_80AF108                          @ 080AF0DC

@ ------------------------------------------------------------------
@ env_decay_init   ROM 0x080AF0E0 / IWRAM 0x03002E48 (ARM)
@ Phase 2: sustain = S*128/99 (8.8) << 4; decay frames = adsr_rate_table[D].
@ ------------------------------------------------------------------
env_decay_init:
	ldr r3, [ip, #0x20]                  @ 080AF0E0
	ldr r0, [r3, #0x2c]                  @ 080AF0E4
	lsl r0, r0, #7                       @ 080AF0E8
	mov r1, #0x63                        @ 080AF0EC
	bl udiv_32_16                        @ 080AF0F0
	lsl r4, r0, #8                       @ 080AF0F4
	lsl r0, r1, #8                       @ 080AF0F8
	mov r1, #0x63                        @ 080AF0FC
	bl udiv_32_16                        @ 080AF100
	orr r0, r4, r0                       @ 080AF104
L_80AF108:
	lsl r1, r0, #4                       @ 080AF108
	str r1, [ip, #0x1c]                  @ 080AF10C
	rsb r0, r0, #0x8000                  @ 080AF110
	movs sb, sb                          @ 080AF114
	bne L_80AF128                        @ 080AF118
	ldrb r1, [r8, #1]                    @ 080AF11C
	cmp r1, #0x80                        @ 080AF120
	blt L_80AF134                        @ 080AF124
L_80AF128:
	ldr r1, [r3, #0x28]                  @ 080AF128
	ldr r2, lit_80AF640                  @ 080AF12C  = adsr_rate_table
	ldrb r1, [r2, r1]                    @ 080AF130
L_80AF134:
	movs r1, r1                          @ 080AF134
	beq L_80AF184                        @ 080AF138
	add r1, r1, #1                       @ 080AF13C
	bl udiv_32_16                        @ 080AF140
	lsl r0, r0, #4                       @ 080AF144
	str r0, [ip, #0x18]                  @ 080AF148
	ldr r0, [ip, #0x14]                  @ 080AF14C
	sub r0, r0, r1, lsl #4               @ 080AF150
	str r0, [ip, #0x14]                  @ 080AF154
	mov r1, #3                           @ 080AF158
	strb r1, [ip, #4]                    @ 080AF15C

@ ------------------------------------------------------------------
@ env_decay   ROM 0x080AF160 / IWRAM 0x03002EC8 (ARM)
@ Phase 3: ramp down to sustain; a sustain level below 0x1000 kills the voice.
@ ------------------------------------------------------------------
env_decay:
	ldrb r1, [ip]                        @ 080AF160
	cmp r1, #0x12                        @ 080AF164
	beq env_release_init                 @ 080AF168
	ldr r1, [ip, #0x18]                  @ 080AF16C
	ldr r2, [ip, #0x14]                  @ 080AF170
	ldr r3, [ip, #0x1c]                  @ 080AF174
	sub r1, r2, r1                       @ 080AF178
	cmp r1, r3                           @ 080AF17C
	bgt L_80AF190                        @ 080AF180
L_80AF184:
	mov r1, #4                           @ 080AF184
	strb r1, [ip, #4]                    @ 080AF188
	ldr r1, [ip, #0x1c]                  @ 080AF18C
L_80AF190:
	cmp r1, #0x1000                      @ 080AF190
	blt env_kill                         @ 080AF194
	str r1, [ip, #0x14]                  @ 080AF198
	sub pc, pc, #0x1d0                   @ 080AF19C  -> L_80AEFD4

@ ------------------------------------------------------------------
@ env_sustain   ROM 0x080AF1A0 / IWRAM 0x03002F08 (ARM)
@ Phase 4: hold until key-off.
@ ------------------------------------------------------------------
env_sustain:
	ldrb r1, [ip]                        @ 080AF1A0
	cmp r1, #0x12                        @ 080AF1A4
	beq env_release_init                 @ 080AF1A8
	sub pc, pc, #0x1e0                   @ 080AF1AC  -> L_80AEFD4

@ ------------------------------------------------------------------
@ env_release_init   ROM 0x080AF1B0 / IWRAM 0x03002F18 (ARM)
@ Phase 5: release frames = adsr_rate_table[R]; 0 = cut immediately.
@ ------------------------------------------------------------------
env_release_init:
	ldr r3, [ip, #0x20]                  @ 080AF1B0
	ldr r0, [ip, #0x14]                  @ 080AF1B4
	movs sb, sb                          @ 080AF1B8
	bne L_80AF1DC                        @ 080AF1BC
	ldr r8, lit_80AF644                  @ 080AF1C0  = chan_adsr_override ; DKC3: CC23 override < 0x80 is used directly as the release time in frames
	mov r2, #4                           @ 080AF1C4
	ldrb r1, [ip, #6]                    @ 080AF1C8
	mla r8, r2, r1, r8                   @ 080AF1CC
	ldrb r1, [r8, #3]                    @ 080AF1D0
	cmp r1, #0x80                        @ 080AF1D4
	blt L_80AF1E8                        @ 080AF1D8
L_80AF1DC:
	ldr r1, [r3, #0x30]                  @ 080AF1DC
	ldr r2, lit_80AF648                  @ 080AF1E0  = adsr_rate_table
	ldrb r1, [r2, r1]                    @ 080AF1E4
L_80AF1E8:
	movs r1, r1                          @ 080AF1E8
	beq env_kill                         @ 080AF1EC
	lsr r0, r0, #4                       @ 080AF1F0
	add r1, r1, #1                       @ 080AF1F4
	bl udiv_32_16                        @ 080AF1F8
	lsls r0, r0, #4                      @ 080AF1FC
	beq env_kill                         @ 080AF200
	str r0, [ip, #0x18]                  @ 080AF204
	ldr r0, [ip, #0x14]                  @ 080AF208
	sub r0, r0, r1, lsl #4               @ 080AF20C
	str r0, [ip, #0x14]                  @ 080AF210
	mov r1, #6                           @ 080AF214
	strb r1, [ip, #4]                    @ 080AF218

@ ------------------------------------------------------------------
@ env_release   ROM 0x080AF21C / IWRAM 0x03002F84 (ARM)
@ Phase 6: ramp down to zero, then free the voice.
@ ------------------------------------------------------------------
env_release:
	ldr r1, [ip, #0x18]                  @ 080AF21C
	ldr r2, [ip, #0x14]                  @ 080AF220
	subs r1, r2, r1                      @ 080AF224
	bgt L_80AF234                        @ 080AF228

@ ------------------------------------------------------------------
@ env_kill   ROM 0x080AF22C / IWRAM 0x03002F94 (ARM)
@ Free the voice (state 0x10).
@ ------------------------------------------------------------------
env_kill:
	mov r1, #0x10                        @ 080AF22C
	strb r1, [ip]                        @ 080AF230
L_80AF234:
	str r1, [ip, #0x14]                  @ 080AF234
	sub pc, pc, #0x26c                   @ 080AF238  -> L_80AEFD4

@ ------------------------------------------------------------------
@ ev_tempo   ROM 0x080AF23C / IWRAM 0x03002FA4 (ARM)
@ cmd 0: 24-bit tempo in microseconds per quarter note (as MIDI meta FF 51).
@ ------------------------------------------------------------------
ev_tempo:
	bic r2, fp, #3                       @ 080AF23C
	ldm r2, {r1, r3}                     @ 080AF240
	and r2, fp, #3                       @ 080AF244
	lsls r2, r2, #3                      @ 080AF248
	lsrne r1, r1, r2                     @ 080AF24C
	rsbne r2, r2, #0x20                  @ 080AF250
	orrne r1, r1, r3, lsl r2             @ 080AF254
	add fp, fp, #3                       @ 080AF258
	bl set_tempo_internal                @ 080AF25C
	add pc, pc, #0x2b8                   @ 080AF260  -> L_80AF520

@ ------------------------------------------------------------------
@ set_tempo_internal   ROM 0x080AF264 / IWRAM 0x03002FCC (ARM)
@ r1 = tempo (us/qn). Also (re)computes seq_frame_time = 60,000,000/3600 us in 24.8
@ fixed point = 16666.67 us, i.e. the sequencer assumes exactly 60 frames/s.
@ ------------------------------------------------------------------
set_tempo_internal:
	stmdb sp!, {lr}                      @ 080AF264
	bic r0, r1, #0xff000000              @ 080AF268
	ldr r2, lit_80AF64C                  @ 080AF26C  = seq_tempo
	str r0, [r2]                         @ 080AF270
	ldr r0, lit_80AF650                  @ 080AF274  = USEC_PER_MINUTE
	mov r1, #0xe10                       @ 080AF278
	bl udiv_32_16                        @ 080AF27C
	lsl r4, r0, #8                       @ 080AF280
	lsl r0, r1, #0x10                    @ 080AF284
	mov r1, #0xe10                       @ 080AF288
	bl udiv_32_16                        @ 080AF28C
	orr r0, r4, r0, lsr #8               @ 080AF290
	ldr r2, lit_80AF654                  @ 080AF294  = seq_frame_time
	str r0, [r2]                         @ 080AF298
	ldm sp!, {lr}                        @ 080AF29C
	bx lr                                @ 080AF2A0

@ ------------------------------------------------------------------
@ ev_delta8   ROM 0x080AF2A4 / IWRAM 0x0300300C (ARM)
@ cmd 1: delta time, 1 byte (ticks). Converts ticks -> microseconds<<8 and adds to the track clock.
@ ------------------------------------------------------------------
ev_delta8:
	ldr r5, lit_80AF658                  @ 080AF2A4  = seq_division
	ldr r5, [r5]                         @ 080AF2A8
	ldrb r1, [fp], #1                    @ 080AF2AC
	ldr r0, lit_80AF65C                  @ 080AF2B0  = seq_tempo
	ldr r2, [r0]                         @ 080AF2B4
	mul r1, r2, r1                       @ 080AF2B8
	mov r0, #0                           @ 080AF2BC
	mov r2, r5                           @ 080AF2C0
	bl sdiv_64_32                        @ 080AF2C4
	lsl r4, r1, #8                       @ 080AF2C8
	lsl r0, r0, #0x10                    @ 080AF2CC
	mov r1, r5                           @ 080AF2D0
	bl udiv_32_16                        @ 080AF2D4
	orr r1, r4, r0, lsr #8               @ 080AF2D8
	mov r2, #0                           @ 080AF2DC
	ldr r5, [sp]                         @ 080AF2E0
	ldr r0, lit_80AF660                  @ 080AF2E4  = seq_track_time
	add r0, r0, r5, lsl #3               @ 080AF2E8
	ldm r0, {r3, r4}                     @ 080AF2EC
	adds r1, r3, r1                      @ 080AF2F0
	adcs r2, r4, r2                      @ 080AF2F4
	stm r0, {r1, r2}                     @ 080AF2F8
	add pc, pc, #0x230                   @ 080AF2FC  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_delta16   ROM 0x080AF300 / IWRAM 0x03003068 (ARM)
@ cmd 2: delta time, 2 bytes little-endian.
@ ------------------------------------------------------------------
ev_delta16:
	ldr r5, lit_80AF664                  @ 080AF300  = seq_division
	ldr r5, [r5]                         @ 080AF304
	ldrb r0, [fp], #1                    @ 080AF308
	ldrb r1, [fp], #1                    @ 080AF30C
	orr r1, r0, r1, lsl #8               @ 080AF310
	ldr r0, lit_80AF668                  @ 080AF314  = seq_tempo
	ldr r2, [r0]                         @ 080AF318
	umull r1, r0, r2, r1                 @ 080AF31C
	mov r2, r5                           @ 080AF320
	bl sdiv_64_32                        @ 080AF324
	lsr r6, r1, #0x18                    @ 080AF328
	lsl r4, r1, #8                       @ 080AF32C
	lsl r0, r0, #0x10                    @ 080AF330
	mov r1, r5                           @ 080AF334
	bl udiv_32_16                        @ 080AF338
	orr r1, r4, r0, lsr #8               @ 080AF33C
	mov r2, r6                           @ 080AF340
	ldr r5, [sp]                         @ 080AF344
	ldr r0, lit_80AF66C                  @ 080AF348  = seq_track_time
	add r0, r0, r5, lsl #3               @ 080AF34C
	ldm r0, {r3, r4}                     @ 080AF350
	adds r1, r3, r1                      @ 080AF354
	adcs r2, r4, r2                      @ 080AF358
	stm r0, {r1, r2}                     @ 080AF35C
	add pc, pc, #0x1cc                   @ 080AF360  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_delta24   ROM 0x080AF364 / IWRAM 0x030030CC (ARM)
@ cmd 3: delta time, 3 bytes little-endian.
@ ------------------------------------------------------------------
ev_delta24:
	bic r2, fp, #3                       @ 080AF364
	ldm r2, {r1, r3}                     @ 080AF368
	and r2, fp, #3                       @ 080AF36C
	lsls r2, r2, #3                      @ 080AF370
	lsrne r1, r1, r2                     @ 080AF374
	rsbne r2, r2, #0x20                  @ 080AF378
	orrne r1, r1, r3, lsl r2             @ 080AF37C
	add fp, fp, #3                       @ 080AF380
	bic r1, r1, #0xff000000              @ 080AF384
	ldr r0, lit_80AF670                  @ 080AF388  = seq_tempo
	ldr r2, [r0]                         @ 080AF38C
	umull r1, r0, r2, r1                 @ 080AF390
	ldr r5, lit_80AF674                  @ 080AF394  = seq_division
	ldr r5, [r5]                         @ 080AF398
	mov r2, r5                           @ 080AF39C
	bl sdiv_64_32                        @ 080AF3A0
	lsr r6, r1, #0x18                    @ 080AF3A4
	lsl r4, r1, #8                       @ 080AF3A8
	lsl r0, r0, #0x10                    @ 080AF3AC
	mov r1, r5                           @ 080AF3B0
	bl udiv_32_16                        @ 080AF3B4
	orr r1, r4, r0, lsr #8               @ 080AF3B8
	mov r2, r6                           @ 080AF3BC
	ldr r5, [sp]                         @ 080AF3C0
	ldr r0, lit_80AF678                  @ 080AF3C4  = seq_track_time
	add r0, r0, r5, lsl #3               @ 080AF3C8
	ldm r0, {r3, r4}                     @ 080AF3CC
	adds r1, r3, r1                      @ 080AF3D0
	adcs r2, r4, r2                      @ 080AF3D4
	stm r0, {r1, r2}                     @ 080AF3D8
	add pc, pc, #0x150                   @ 080AF3DC  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_note_on   ROM 0x080AF3E0 / IWRAM 0x03003148 (ARM)
@ cmd 4/5: note on <key> <velocity>. Allocates one of the channel's 6 voices
@ (free first, then released); mono mode always reuses slot 0. Resolves rhythm sets (0x22)
@ and key splits (0x23) through the instrument's keymap. Note is dropped if no voice is free.
@ ------------------------------------------------------------------
ev_note_on:
	ldr r4, lit_80AF67C                  @ 080AF3E0  = cfg_chan_pool_bytes
	ldr r4, [r4]                         @ 080AF3E4
	ldr r3, lit_80AF680                  @ 080AF3E8  = music_voices
	add r3, r3, r4                       @ 080AF3EC
	mla r5, r1, r4, r3                   @ 080AF3F0
	ldr r2, lit_80AF684                  @ 080AF3F4  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 080AF3F8
	ldr r0, lit_80AF688                  @ 080AF3FC  = chan_mono
	ldrb r0, [r0, r1]                    @ 080AF400
	cmp r0, #0                           @ 080AF404
	bne L_80AF448                        @ 080AF408
L_80AF40C:
	ldrb r0, [r5, -r2]                   @ 080AF40C
	cmp r0, #0x10                        @ 080AF410
	beq L_80AF448                        @ 080AF414
	subs r2, r2, #0x28                   @ 080AF418
	bgt L_80AF40C                        @ 080AF41C
	ldr r2, lit_80AF68C                  @ 080AF420  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 080AF424
L_80AF428:
	ldrb r0, [r5, -r2]                   @ 080AF428
	cmp r0, #0x12                        @ 080AF42C
	beq L_80AF448                        @ 080AF430
	subs r2, r2, #0x28                   @ 080AF434
	bgt L_80AF428                        @ 080AF438
	ldrb r4, [fp], #1                    @ 080AF43C
	ldrb r0, [fp], #1                    @ 080AF440
	b L_80AF4C8                          @ 080AF444
L_80AF448:
	sub r5, r5, r2                       @ 080AF448
	ldrb r4, [fp], #1                    @ 080AF44C
	mov sb, r4                           @ 080AF450
	mov r7, #4                           @ 080AF454
	ldr r6, lit_80AF690                  @ 080AF458  = chan_instrument
	mla r2, r1, r7, r6                   @ 080AF45C
	ldr r2, [r2]                         @ 080AF460
	ldr r7, [r2]                         @ 080AF464
	cmp r7, #0x20                        @ 080AF468  0x20 = plain instrument
	beq L_80AF4B4                        @ 080AF46C
	cmp r7, #0x21                        @ 080AF470
	beq L_80AF4B4                        @ 080AF474
	cmp r7, #0x22                        @ 080AF478  0x22 = rhythm set
	beq L_80AF488                        @ 080AF47C
	cmp r7, #0x23                        @ 080AF480  0x23 = key split
	beq L_80AF4A0                        @ 080AF484
L_80AF488:
	ldr r0, [r2, #0x1c]                  @ 080AF488
	ldrb r1, [r0, r4]                    @ 080AF48C
	ldr r0, [r2, #0x20]                  @ 080AF490
	ldr r2, [r0, r1, lsl #2]             @ 080AF494
	ldr sb, [r2, #0xc]                   @ 080AF498
	b L_80AF4B4                          @ 080AF49C
L_80AF4A0:
	ldr r0, [r2, #0x1c]                  @ 080AF4A0
	ldrb r1, [r0, r4]                    @ 080AF4A4
	ldr r0, [r2, #0x20]                  @ 080AF4A8
	ldr r2, [r0, r1, lsl #2]             @ 080AF4AC
	b L_80AF4B4                          @ 080AF4B0
L_80AF4B4:
	ldr r7, [r2, #4]                     @ 080AF4B4
	ldrb r3, [fp], #1                    @ 080AF4B8
	add r3, r3, #1                       @ 080AF4BC
	mov r1, #0x10000                     @ 080AF4C0
	bl voice_start                       @ 080AF4C4
L_80AF4C8:
	add pc, pc, #0x50                    @ 080AF4C8  -> L_80AF520

@ ------------------------------------------------------------------
@ seq_update   ROM 0x080AF4CC / IWRAM 0x03003234 (ARM)
@ Sequencer tick, once per frame: for each track subtract one frame of time from its clock;
@ while the clock is negative, execute events. Stops the song when every track sits on END.
@ ------------------------------------------------------------------
seq_update:
	stmdb sp!, {lr}                      @ 080AF4CC
	sub sp, sp, #0xc                     @ 080AF4D0
	mov r0, #0                           @ 080AF4D4
	str r0, [sp, #8]                     @ 080AF4D8
	mvn r0, #0                           @ 080AF4DC
	str r0, [sp]                         @ 080AF4E0
	b L_80AF560                          @ 080AF4E4
L_80AF4E8:
	str r0, [sp]                         @ 080AF4E8
	ldr r4, lit_80AF694                  @ 080AF4EC  = seq_track_time
	add r4, r4, r0, lsl #3               @ 080AF4F0
	ldr r1, lit_80AF698                  @ 080AF4F4  = seq_frame_time
	ldm r4, {r2, r3}                     @ 080AF4F8
	ldr r5, [r1]                         @ 080AF4FC
	subs r2, r2, r5                      @ 080AF500
	sbcs r3, r3, #0                      @ 080AF504
	stm r4, {r2, r3}                     @ 080AF508
	bpl L_80AF560                        @ 080AF50C
	ldr fp, lit_80AF69C                  @ 080AF510  = seq_track_ptr
	ldr r0, [sp]                         @ 080AF514
	ldr fp, [fp, r0, lsl #2]             @ 080AF518

@ seq_next_event: fetch and dispatch the next event of the current track
seq_next_event:
	add ip, pc, #0x78                    @ 080AF51C  = seq_cmd_table
L_80AF520:
	ldrb r0, [fp], #1                    @ 080AF520  event byte: high nibble = MIDI channel, low nibble = command
	lsr r1, r0, #4                       @ 080AF524
	bic r0, r0, #0xf0                    @ 080AF528
	ldr r0, [ip, r0, lsl #2]             @ 080AF52C
	add pc, r0, ip                       @ 080AF530  computed jump into handler

@ seq_after_delta: keep going while the track clock is still negative
seq_after_delta:
	ldr r0, [sp]                         @ 080AF534
	ldr r1, lit_80AF6A0                  @ 080AF538  = seq_track_time+0x4
	ldr r1, [r1, r0, lsl #3]             @ 080AF53C
	cmp r1, #0                           @ 080AF540
	bmi L_80AF54C                        @ 080AF544
	b L_80AF550                          @ 080AF548
L_80AF54C:
	b seq_next_event                     @ 080AF54C
L_80AF550:
	mov r0, r0                           @ 080AF550

@ seq_track_yield: save the track pointer and move to the next track
seq_track_yield:
	ldr r0, [sp]                         @ 080AF554
	ldr r2, lit_80AF6A4                  @ 080AF558  = seq_track_ptr
	str fp, [r2, r0, lsl #2]             @ 080AF55C
L_80AF560:
	ldr r1, lit_80AF6A8                  @ 080AF560  = seq_num_tracks
	ldr r1, [r1]                         @ 080AF564
	ldr r0, [sp]                         @ 080AF568
	adds r0, r0, #1                      @ 080AF56C
	cmp r0, r1                           @ 080AF570
	bne L_80AF4E8                        @ 080AF574
	ldr r0, [sp, #8]                     @ 080AF578
	cmp r0, r1                           @ 080AF57C
	bne L_80AF590                        @ 080AF580
	ldr r0, lit_80AF6AC                  @ 080AF584  = seq_current_song
	mvn r1, #0                           @ 080AF588
	str r1, [r0]                         @ 080AF58C
L_80AF590:
	add sp, sp, #0xc                     @ 080AF590
	ldm sp!, {lr}                        @ 080AF594
	bx lr                                @ 080AF598

@ seq_cmd_table: 13 x offset from seq_cmd_table, indexed by the low nibble of the event byte
seq_cmd_table:
	.word ev_tempo - seq_cmd_table
	.word ev_delta8 - seq_cmd_table
	.word ev_delta16 - seq_cmd_table
	.word ev_delta24 - seq_cmd_table
	.word ev_note_on - seq_cmd_table
	.word ev_note_on - seq_cmd_table
	.word ev_note_off - seq_cmd_table
	.word ev_controller - seq_cmd_table
	.word ev_program - seq_cmd_table
	.word ev_skip1 - seq_cmd_table
	.word ev_pitch_bend - seq_cmd_table
	.word ev_end_track - seq_cmd_table
	.word ev_nop - seq_cmd_table
lit_80AF5D0:
	.word mix_buffer
lit_80AF5D4:
	.word mix_max_voices
lit_80AF5D8:
	.word cfg_sfx_pool_bytes
lit_80AF5DC:
	.word sfx_voices
lit_80AF5E0:
	.word cfg_sfx_pool_bytes
lit_80AF5E4:
	.word music_paused
lit_80AF5E8:
	.word cfg_music_pool_bytes
lit_80AF5EC:
	.word music_voices
lit_80AF5F0:
	.word cfg_music_pool_bytes
lit_80AF5F4:
	.word mix_max_voices
lit_80AF5F8:
	.word clear_mix_buffer+1
lit_80AF5FC:
	.word dma_buffer_flag
lit_80AF600:
	.word cfg_buffer_a
lit_80AF604:
	.word cfg_buffer_b
lit_80AF608:
	.word mix_buffer
lit_80AF60C:
	.word mix_samples_per_frame
lit_80AF610:
	.word cfg_sfx_pool_bytes
lit_80AF614:
	.word sfx_voices
lit_80AF618:
	.word cfg_music_pool_bytes
lit_80AF61C:
	.word music_voices
lit_80AF620:
	.word mix_samples_per_frame
lit_80AF624:
	.word 0x007FFFFF
lit_80AF628:
	.word cfg_sfx_pool_bytes
lit_80AF62C:
	.word sfx_voices
lit_80AF630:
	.word cfg_music_pool_bytes
lit_80AF634:
	.word music_voices
lit_80AF638:
	.word chan_adsr_override
lit_80AF63C:
	.word chan_adsr_override
lit_80AF640:
	.word adsr_rate_table
lit_80AF644:
	.word chan_adsr_override
lit_80AF648:
	.word adsr_rate_table
lit_80AF64C:
	.word seq_tempo
lit_80AF650:
	.word USEC_PER_MINUTE
lit_80AF654:
	.word seq_frame_time
lit_80AF658:
	.word seq_division
lit_80AF65C:
	.word seq_tempo
lit_80AF660:
	.word seq_track_time
lit_80AF664:
	.word seq_division
lit_80AF668:
	.word seq_tempo
lit_80AF66C:
	.word seq_track_time
lit_80AF670:
	.word seq_tempo
lit_80AF674:
	.word seq_division
lit_80AF678:
	.word seq_track_time
lit_80AF67C:
	.word cfg_chan_pool_bytes
lit_80AF680:
	.word music_voices
lit_80AF684:
	.word cfg_chan_pool_bytes
lit_80AF688:
	.word chan_mono
lit_80AF68C:
	.word cfg_chan_pool_bytes
lit_80AF690:
	.word chan_instrument
lit_80AF694:
	.word seq_track_time
lit_80AF698:
	.word seq_frame_time
lit_80AF69C:
	.word seq_track_ptr
lit_80AF6A0:
	.word seq_track_time+0x4
lit_80AF6A4:
	.word seq_track_ptr
lit_80AF6A8:
	.word seq_num_tracks
lit_80AF6AC:
	.word seq_current_song

@ ------------------------------------------------------------------
@ ev_note_off   ROM 0x080AF6B0 / IWRAM 0x03003418 (ARM)
@ cmd 6: note off <key> <velocity(ignored)>. Releases the first key-on voice of the channel
@ whose stored key matches.
@ ------------------------------------------------------------------
ev_note_off:
	ldrb r6, [fp], #1                    @ 080AF6B0
	ldrb r7, [fp], #1                    @ 080AF6B4
	ldr r4, lit_80AFB00                  @ 080AF6B8  = cfg_chan_pool_bytes
	ldr r4, [r4]                         @ 080AF6BC
	ldr r3, lit_80AFB04                  @ 080AF6C0  = music_voices
	add r3, r3, r4                       @ 080AF6C4
	mla r5, r1, r4, r3                   @ 080AF6C8
	ldr r2, lit_80AFB08                  @ 080AF6CC  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 080AF6D0
L_80AF6D4:
	ldrb r0, [r5, -r2]                   @ 080AF6D4
	cmp r0, #0x11                        @ 080AF6D8
	bleq L_80AF6EC                       @ 080AF6DC
	subs r2, r2, #0x28                   @ 080AF6E0
	bgt L_80AF6D4                        @ 080AF6E4
	b L_80AF704                          @ 080AF6E8
L_80AF6EC:
	sub r0, r5, r2                       @ 080AF6EC
	ldrb r1, [r0, #2]                    @ 080AF6F0
	cmp r1, r6                           @ 080AF6F4
	bxne lr                              @ 080AF6F8
	mov r1, #0x12                        @ 080AF6FC
	strb r1, [r0]                        @ 080AF700
L_80AF704:
	sub pc, pc, #0x1ec                   @ 080AF704  -> L_80AF520

@ ------------------------------------------------------------------
@ ev_controller   ROM 0x080AF708 / IWRAM 0x03003470 (ARM)
@ cmd 7: controller <cc> <value>. Handled: 1 mod wheel, 7 volume, 100 (stored, never read),
@ 102 loop start (save track pointer), 103 loop end (jump back), 126 mono on, 127 poly on.
@ ------------------------------------------------------------------
ev_controller:
	ldrb r2, [fp], #1                    @ 080AF708
	ldrb r3, [fp], #1                    @ 080AF70C
	cmp r2, #1                           @ 080AF710
	beq L_80AF774                        @ 080AF714
	cmp r2, #7                           @ 080AF718
	beq L_80AF788                        @ 080AF71C
	cmp r2, #0x64                        @ 080AF720
	beq L_80AF794                        @ 080AF724
	cmp r2, #0x66                        @ 080AF728
	beq L_80AF7A0                        @ 080AF72C
	cmp r2, #0x67                        @ 080AF730
	beq L_80AF7B0                        @ 080AF734
	cmp r2, #0x68                        @ 080AF738
	beq L_80AF7C0                        @ 080AF73C
	cmp r2, #0x7e                        @ 080AF740
	beq L_80AF7C4                        @ 080AF744
	cmp r2, #0x7f                        @ 080AF748
	beq L_80AF7D4                        @ 080AF74C
	cmp r2, #0x14                        @ 080AF750
	beq L_80AF7E4                        @ 080AF754
	cmp r2, #0x15                        @ 080AF758
	beq L_80AF7F8                        @ 080AF75C
	cmp r2, #0x16                        @ 080AF760
	beq L_80AF80C                        @ 080AF764
	cmp r2, #0x17                        @ 080AF768
	beq L_80AF820                        @ 080AF76C
	b L_80AF834                          @ 080AF770
L_80AF774:
	ldr r5, lit_80AFB0C                  @ 080AF774  = chan_mod ; CC1  mod wheel
	mov r2, #8                           @ 080AF778
	mla r5, r1, r2, r5                   @ 080AF77C
	str r3, [r5]                         @ 080AF780
	b L_80AF834                          @ 080AF784
L_80AF788:
	ldr r5, lit_80AFB10                  @ 080AF788  = chan_volume ; CC7  volume
	strb r3, [r5, r1]                    @ 080AF78C
	b L_80AF834                          @ 080AF790
L_80AF794:
	ldr r5, lit_80AFB14                  @ 080AF794  = chan_cc100 ; CC100 (dead store)
	strb r3, [r5, r1]                    @ 080AF798
	b L_80AF834                          @ 080AF79C
L_80AF7A0:
	ldr r4, [sp]                         @ 080AF7A0  CC102 loop start
	ldr r5, lit_80AFB18                  @ 080AF7A4  = seq_loop_ptr
	str fp, [r5, r4, lsl #2]             @ 080AF7A8
	b L_80AF834                          @ 080AF7AC
L_80AF7B0:
	ldr r4, [sp]                         @ 080AF7B0  CC103 loop end
	ldr r5, lit_80AFB1C                  @ 080AF7B4  = seq_loop_ptr
	ldr fp, [r5, r4, lsl #2]             @ 080AF7B8
	b L_80AF834                          @ 080AF7BC
L_80AF7C0:
	b L_80AF834                          @ 080AF7C0  CC104 start marker: ignored while playing (see seek_start_marker)
L_80AF7C4:
	ldr r5, lit_80AFB20                  @ 080AF7C4  = chan_mono ; CC126 mono
	mov r3, #1                           @ 080AF7C8
	strb r3, [r5, r1]                    @ 080AF7CC
	b L_80AF834                          @ 080AF7D0
L_80AF7D4:
	ldr r5, lit_80AFB24                  @ 080AF7D4  = chan_mono ; CC127 poly
	mov r3, #0                           @ 080AF7D8
	strb r3, [r5, r1]                    @ 080AF7DC
	b L_80AF834                          @ 080AF7E0
L_80AF7E4:
	ldr r8, lit_80AFB28                  @ 080AF7E4  = chan_adsr_override ; CC20 attack override
	mov r2, #4                           @ 080AF7E8
	mla r8, r2, r1, r8                   @ 080AF7EC
	strb r3, [r8]                        @ 080AF7F0
	b L_80AF834                          @ 080AF7F4
L_80AF7F8:
	ldr r8, lit_80AFB2C                  @ 080AF7F8  = chan_adsr_override ; CC21 decay override
	mov r2, #4                           @ 080AF7FC
	mla r8, r2, r1, r8                   @ 080AF800
	strb r3, [r8, #1]                    @ 080AF804
	b L_80AF834                          @ 080AF808
L_80AF80C:
	ldr r8, lit_80AFB30                  @ 080AF80C  = chan_adsr_override ; CC22 sustain override
	mov r2, #4                           @ 080AF810
	mla r8, r2, r1, r8                   @ 080AF814
	strb r3, [r8, #2]                    @ 080AF818
	b L_80AF834                          @ 080AF81C
L_80AF820:
	ldr r8, lit_80AFB34                  @ 080AF820  = chan_adsr_override ; CC23 release override
	mov r2, #4                           @ 080AF824
	mla r8, r2, r1, r8                   @ 080AF828
	strb r3, [r8, #3]                    @ 080AF82C
	b L_80AF834                          @ 080AF830
L_80AF834:
	sub pc, pc, #0x31c                   @ 080AF834  -> L_80AF520

@ ------------------------------------------------------------------
@ ev_program   ROM 0x080AF838 / IWRAM 0x030035A0 (ARM)
@ cmd 8: program change <prog>: prog -> prog_map byte -> instrument table entry.
@ ------------------------------------------------------------------
ev_program:
	ldrb r3, [fp], #1                    @ 080AF838
	ldr r2, lit_80AFB38                  @ 080AF83C  = seq_prog_map_ptr
	ldr r2, [r2]                         @ 080AF840
	ldrb r2, [r2, r3]                    @ 080AF844
	ldr r3, lit_80AFB3C                  @ 080AF848  = seq_inst_table_ptr
	ldr r3, [r3]                         @ 080AF84C
	ldr r4, [r3, r2, lsl #2]             @ 080AF850
	ldr r8, lit_80AFB40                  @ 080AF854  = chan_instrument
	mov r2, #4                           @ 080AF858
	mla r8, r2, r1, r8                   @ 080AF85C
	str r4, [r8]                         @ 080AF860
	ldr r8, lit_80AFB44                  @ 080AF864  = chan_adsr_override ; program change resets the channel ADSR overrides
	mov r2, #4                           @ 080AF868
	mla r8, r2, r1, r8                   @ 080AF86C
	mvn r2, #0                           @ 080AF870
	str r2, [r8]                         @ 080AF874
	ldr pc, lit_80AFB48                  @ 080AF878  = L_80AF520 ; PERF BUG: absolute literal = ROM address of the label, not its IWRAM copy; execution continues from cartridge ROM

@ ------------------------------------------------------------------
@ ev_skip1   ROM 0x080AF87C / IWRAM 0x030035E4 (ARM)
@ cmd 9: one data byte, ignored (channel pressure slot).
@ ------------------------------------------------------------------
ev_skip1:
	add fp, fp, #1                       @ 080AF87C
	ldr pc, lit_80AFB4C                  @ 080AF880  = L_80AF520 ; PERF BUG: absolute literal = ROM address of the label, not its IWRAM copy; execution continues from cartridge ROM

@ ------------------------------------------------------------------
@ ev_pitch_bend   ROM 0x080AF884 / IWRAM 0x030035EC (ARM)
@ cmd 10: pitch bend, 14-bit value stored as a little-endian 16-bit word (0x2000 = centre).
@ ------------------------------------------------------------------
ev_pitch_bend:
	mov r3, r1                           @ 080AF884
	ldrb r0, [fp], #1                    @ 080AF888
	ldrb r1, [fp], #1                    @ 080AF88C
	orr r1, r0, r1, lsl #8               @ 080AF890
	ldr r2, lit_80AFB50                  @ 080AF894  = chan_bend
	str r1, [r2, r3, lsl #2]             @ 080AF898
	ldr pc, lit_80AFB54                  @ 080AF89C  = L_80AF520 ; PERF BUG: absolute literal = ROM address of the label, not its IWRAM copy; execution continues from cartridge ROM

@ ------------------------------------------------------------------
@ ev_end_track   ROM 0x080AF8A0 / IWRAM 0x03003608 (ARM)
@ cmd 11: end of track - re-executed every frame; counts towards 'song finished'.
@ ------------------------------------------------------------------
ev_end_track:
	sub fp, fp, #1                       @ 080AF8A0
	ldr r0, [sp, #8]                     @ 080AF8A4
	add r0, r0, #1                       @ 080AF8A8
	str r0, [sp, #8]                     @ 080AF8AC
	ldr pc, lit_80AFB58                  @ 080AF8B0  = seq_track_yield ; PERF BUG: absolute literal = ROM address of the label, not its IWRAM copy; execution continues from cartridge ROM

@ ------------------------------------------------------------------
@ ev_nop   ROM 0x080AF8B4 / IWRAM 0x0300361C (ARM)
@ cmd 12: no operation.
@ ------------------------------------------------------------------
ev_nop:
	ldr pc, lit_80AFB5C                  @ 080AF8B4  = L_80AF520 ; PERF BUG: absolute literal = ROM address of the label, not its IWRAM copy; execution continues from cartridge ROM

@ ------------------------------------------------------------------
@ udiv_32_16   ROM 0x080AF8B8 / IWRAM 0x03003620 (ARM)
@ Unsigned r0/r1 with r0 < r1<<16. Out: r0 = quotient (16 bit), r1 = remainder.
@ ------------------------------------------------------------------
udiv_32_16:
	rsb r1, r1, #0                       @ 080AF8B8
	lsls r1, r1, #0xf                    @ 080AF8BC
	adds r0, r1, r0                      @ 080AF8C0
	rsblo r0, r1, r0                     @ 080AF8C4
	adcs r0, r1, r0, lsl #1              @ 080AF8C8
	rsblo r0, r1, r0                     @ 080AF8CC
	adcs r0, r1, r0, lsl #1              @ 080AF8D0
	rsblo r0, r1, r0                     @ 080AF8D4
	adcs r0, r1, r0, lsl #1              @ 080AF8D8
	rsblo r0, r1, r0                     @ 080AF8DC
	adcs r0, r1, r0, lsl #1              @ 080AF8E0
	rsblo r0, r1, r0                     @ 080AF8E4
	adcs r0, r1, r0, lsl #1              @ 080AF8E8
	rsblo r0, r1, r0                     @ 080AF8EC
	adcs r0, r1, r0, lsl #1              @ 080AF8F0
	rsblo r0, r1, r0                     @ 080AF8F4
	adcs r0, r1, r0, lsl #1              @ 080AF8F8
	rsblo r0, r1, r0                     @ 080AF8FC
	adcs r0, r1, r0, lsl #1              @ 080AF900
	rsblo r0, r1, r0                     @ 080AF904
	adcs r0, r1, r0, lsl #1              @ 080AF908
	rsblo r0, r1, r0                     @ 080AF90C
	adcs r0, r1, r0, lsl #1              @ 080AF910
	rsblo r0, r1, r0                     @ 080AF914
	adcs r0, r1, r0, lsl #1              @ 080AF918
	rsblo r0, r1, r0                     @ 080AF91C
	adcs r0, r1, r0, lsl #1              @ 080AF920
	rsblo r0, r1, r0                     @ 080AF924
	adcs r0, r1, r0, lsl #1              @ 080AF928
	rsblo r0, r1, r0                     @ 080AF92C
	adcs r0, r1, r0, lsl #1              @ 080AF930
	rsblo r0, r1, r0                     @ 080AF934
	adcs r0, r1, r0, lsl #1              @ 080AF938
	rsblo r0, r1, r0                     @ 080AF93C
	adc r0, r0, r0                       @ 080AF940
	lsr r1, r0, #0x10                    @ 080AF944
	bic r0, r0, r1, lsl #16              @ 080AF948
	bx lr                                @ 080AF94C

@ ------------------------------------------------------------------
@ sdiv_64_32   ROM 0x080AF950 / IWRAM 0x030036B8 (ARM)
@ Signed 64/32 division: (r0:r1) / r2. Out: r1 = quotient, r0 = remainder.
@ ------------------------------------------------------------------
sdiv_64_32:
	movs r3, r2                          @ 080AF950
	rsbpl r2, r2, #0                     @ 080AF954
	lsr r3, r3, #1                       @ 080AF958
	eors r3, r3, r0, asr #1              @ 080AF95C
	bpl L_80AF96C                        @ 080AF960
	rsbs r1, r1, #0                      @ 080AF964
	rsc r0, r0, #0                       @ 080AF968
L_80AF96C:
	adds r1, r1, r1                      @ 080AF96C
	adcs r0, r2, r0, lsl #1              @ 080AF970
	rsblo r0, r2, r0                     @ 080AF974
	adcs r1, r1, r1                      @ 080AF978
	adcs r0, r2, r0, lsl #1              @ 080AF97C
	rsblo r0, r2, r0                     @ 080AF980
	adcs r1, r1, r1                      @ 080AF984
	adcs r0, r2, r0, lsl #1              @ 080AF988
	rsblo r0, r2, r0                     @ 080AF98C
	adcs r1, r1, r1                      @ 080AF990
	adcs r0, r2, r0, lsl #1              @ 080AF994
	rsblo r0, r2, r0                     @ 080AF998
	adcs r1, r1, r1                      @ 080AF99C
	adcs r0, r2, r0, lsl #1              @ 080AF9A0
	rsblo r0, r2, r0                     @ 080AF9A4
	adcs r1, r1, r1                      @ 080AF9A8
	adcs r0, r2, r0, lsl #1              @ 080AF9AC
	rsblo r0, r2, r0                     @ 080AF9B0
	adcs r1, r1, r1                      @ 080AF9B4
	adcs r0, r2, r0, lsl #1              @ 080AF9B8
	rsblo r0, r2, r0                     @ 080AF9BC
	adcs r1, r1, r1                      @ 080AF9C0
	adcs r0, r2, r0, lsl #1              @ 080AF9C4
	rsblo r0, r2, r0                     @ 080AF9C8
	adcs r1, r1, r1                      @ 080AF9CC
	adcs r0, r2, r0, lsl #1              @ 080AF9D0
	rsblo r0, r2, r0                     @ 080AF9D4
	adcs r1, r1, r1                      @ 080AF9D8
	adcs r0, r2, r0, lsl #1              @ 080AF9DC
	rsblo r0, r2, r0                     @ 080AF9E0
	adcs r1, r1, r1                      @ 080AF9E4
	adcs r0, r2, r0, lsl #1              @ 080AF9E8
	rsblo r0, r2, r0                     @ 080AF9EC
	adcs r1, r1, r1                      @ 080AF9F0
	adcs r0, r2, r0, lsl #1              @ 080AF9F4
	rsblo r0, r2, r0                     @ 080AF9F8
	adcs r1, r1, r1                      @ 080AF9FC
	adcs r0, r2, r0, lsl #1              @ 080AFA00
	rsblo r0, r2, r0                     @ 080AFA04
	adcs r1, r1, r1                      @ 080AFA08
	adcs r0, r2, r0, lsl #1              @ 080AFA0C
	rsblo r0, r2, r0                     @ 080AFA10
	adcs r1, r1, r1                      @ 080AFA14
	adcs r0, r2, r0, lsl #1              @ 080AFA18
	rsblo r0, r2, r0                     @ 080AFA1C
	adcs r1, r1, r1                      @ 080AFA20
	adcs r0, r2, r0, lsl #1              @ 080AFA24
	rsblo r0, r2, r0                     @ 080AFA28
	adcs r1, r1, r1                      @ 080AFA2C
	adcs r0, r2, r0, lsl #1              @ 080AFA30
	rsblo r0, r2, r0                     @ 080AFA34
	adcs r1, r1, r1                      @ 080AFA38
	adcs r0, r2, r0, lsl #1              @ 080AFA3C
	rsblo r0, r2, r0                     @ 080AFA40
	adcs r1, r1, r1                      @ 080AFA44
	adcs r0, r2, r0, lsl #1              @ 080AFA48
	rsblo r0, r2, r0                     @ 080AFA4C
	adcs r1, r1, r1                      @ 080AFA50
	adcs r0, r2, r0, lsl #1              @ 080AFA54
	rsblo r0, r2, r0                     @ 080AFA58
	adcs r1, r1, r1                      @ 080AFA5C
	adcs r0, r2, r0, lsl #1              @ 080AFA60
	rsblo r0, r2, r0                     @ 080AFA64
	adcs r1, r1, r1                      @ 080AFA68
	adcs r0, r2, r0, lsl #1              @ 080AFA6C
	rsblo r0, r2, r0                     @ 080AFA70
	adcs r1, r1, r1                      @ 080AFA74
	adcs r0, r2, r0, lsl #1              @ 080AFA78
	rsblo r0, r2, r0                     @ 080AFA7C
	adcs r1, r1, r1                      @ 080AFA80
	adcs r0, r2, r0, lsl #1              @ 080AFA84
	rsblo r0, r2, r0                     @ 080AFA88
	adcs r1, r1, r1                      @ 080AFA8C
	adcs r0, r2, r0, lsl #1              @ 080AFA90
	rsblo r0, r2, r0                     @ 080AFA94
	adcs r1, r1, r1                      @ 080AFA98
	adcs r0, r2, r0, lsl #1              @ 080AFA9C
	rsblo r0, r2, r0                     @ 080AFAA0
	adcs r1, r1, r1                      @ 080AFAA4
	adcs r0, r2, r0, lsl #1              @ 080AFAA8
	rsblo r0, r2, r0                     @ 080AFAAC
	adcs r1, r1, r1                      @ 080AFAB0
	adcs r0, r2, r0, lsl #1              @ 080AFAB4
	rsblo r0, r2, r0                     @ 080AFAB8
	adcs r1, r1, r1                      @ 080AFABC
	adcs r0, r2, r0, lsl #1              @ 080AFAC0
	rsblo r0, r2, r0                     @ 080AFAC4
	adcs r1, r1, r1                      @ 080AFAC8
	adcs r0, r2, r0, lsl #1              @ 080AFACC
	rsblo r0, r2, r0                     @ 080AFAD0
	adcs r1, r1, r1                      @ 080AFAD4
	adcs r0, r2, r0, lsl #1              @ 080AFAD8
	rsblo r0, r2, r0                     @ 080AFADC
	adcs r1, r1, r1                      @ 080AFAE0
	adcs r0, r2, r0, lsl #1              @ 080AFAE4
	rsblo r0, r2, r0                     @ 080AFAE8
	adcs r1, r1, r1                      @ 080AFAEC
	lsls r3, r3, #1                      @ 080AFAF0
	rsbmi r1, r1, #0                     @ 080AFAF4
	rsbhs r0, r0, #0                     @ 080AFAF8
	bx lr                                @ 080AFAFC
lit_80AFB00:
	.word cfg_chan_pool_bytes
lit_80AFB04:
	.word music_voices
lit_80AFB08:
	.word cfg_chan_pool_bytes
lit_80AFB0C:
	.word chan_mod
lit_80AFB10:
	.word chan_volume
lit_80AFB14:
	.word chan_cc100
lit_80AFB18:
	.word seq_loop_ptr
lit_80AFB1C:
	.word seq_loop_ptr
lit_80AFB20:
	.word chan_mono
lit_80AFB24:
	.word chan_mono
lit_80AFB28:
	.word chan_adsr_override
lit_80AFB2C:
	.word chan_adsr_override
lit_80AFB30:
	.word chan_adsr_override
lit_80AFB34:
	.word chan_adsr_override
lit_80AFB38:
	.word seq_prog_map_ptr
lit_80AFB3C:
	.word seq_inst_table_ptr
lit_80AFB40:
	.word chan_instrument
lit_80AFB44:
	.word chan_adsr_override
lit_80AFB48:
	.word L_80AF520
lit_80AFB4C:
	.word L_80AF520
lit_80AFB50:
	.word chan_bend
lit_80AFB54:
	.word L_80AF520
lit_80AFB58:
	.word seq_track_yield
lit_80AFB5C:
	.word L_80AF520

@ ------------------------------------------------------------------
@ mix_voice   ROM 0x080AFB60 / IWRAM 0x030038C8 (ARM)
@ Mix one voice into the s16 buffer at r5 with linear interpolation. Volume =
@ master * (chan_volume+1)/128 * vel/128 * env/2^19 (SFX: sfx_master * vol/128 * env).
@ The first voice of a frame stores, later voices add. Position is NOT written back.
@ ------------------------------------------------------------------
mix_voice:
	str lr, [sp, #0x1c]                  @ 080AFB60
	str r0, [sp, #0x20]                  @ 080AFB64
	ldrsb r6, [r0, #6]                   @ 080AFB68
	cmp r6, #0                           @ 080AFB6C
	ldr r1, lit_80AFEAC                  @ 080AFB70  = sfx_master_volume
	bmi L_80AFB7C                        @ 080AFB74
	ldr r1, lit_80AFEB0                  @ 080AFB78  = music_master_volume
L_80AFB7C:
	ldr r4, [r1]                         @ 080AFB7C
	bmi L_80AFBB0                        @ 080AFB80
	ldr r3, lit_80AFEB4                  @ 080AFB84  = chan_volume
	ldrb r3, [r3, r6]                    @ 080AFB88
	add r3, r3, #1                       @ 080AFB8C
	mul r4, r3, r4                       @ 080AFB90
	lsr r4, r4, #7                       @ 080AFB94
	ldr r3, lit_80AFEB8                  @ 080AFB98  = chan_gain ; DKC3: per-channel gain; 0 skips the voice without spending the voice budget
	ldrb r3, [r3, r6]                    @ 080AFB9C
	mul r4, r3, r4                       @ 080AFBA0
	lsr r4, r4, #7                       @ 080AFBA4
	cmp r4, #0                           @ 080AFBA8
	beq L_80AFD3C                        @ 080AFBAC
L_80AFBB0:
	str r4, [sp, #0x24]                  @ 080AFBB0
	bl calc_pitch                        @ 080AFBB4
	str r7, [r0, #8]                     @ 080AFBB8
	ldr r4, [sp, #0x24]                  @ 080AFBBC
	ldrb r3, [r0, #3]                    @ 080AFBC0
	mul r4, r3, r4                       @ 080AFBC4
	lsr r4, r4, #7                       @ 080AFBC8
	ldr sb, [r0, #0x14]                  @ 080AFBCC
	mul r4, sb, r4                       @ 080AFBD0
	lsr r4, r4, #0x13                    @ 080AFBD4
	ldr r6, [r0, #0x24]                  @ 080AFBD8
	umull sb, sl, r6, r7                 @ 080AFBDC
	lsr r7, sb, #0x10                    @ 080AFBE0
	add r7, r7, sl, lsl #16              @ 080AFBE4
	mov r6, #0                           @ 080AFBE8
	mov r3, #0                           @ 080AFBEC
	ldr sb, lit_80AFEBC                  @ 080AFBF0  = mix_samples_per_frame
	ldr sb, [sb]                         @ 080AFBF4
	add sb, r5, sb, lsl #1               @ 080AFBF8
	ldr r6, [r0, #0x10]                  @ 080AFBFC
	ldr sl, [r0, #0x20]                  @ 080AFC00
	ldr sl, [sl, #0x18]                  @ 080AFC04
	ldr r0, [r0, #0xc]                   @ 080AFC08
	ldr fp, lit_80AFEC0                  @ 080AFC0C  = 0x007FFFFF
	ldr r3, lit_80AFEC4                  @ 080AFC10  = mix_max_voices
	ldr r3, [r3]                         @ 080AFC14
	ldr r8, [sp, #0x10]                  @ 080AFC18
	cmp r3, r8                           @ 080AFC1C
	bne L_80AFC64                        @ 080AFC20
L_80AFC24:
	ldrsb r1, [r0]                       @ 080AFC24
	ldrsb r2, [r0, #1]                   @ 080AFC28
	sub r2, r2, r1                       @ 080AFC2C
	mul r3, r6, r2                       @ 080AFC30
	add r1, r1, r3, asr #23              @ 080AFC34  linear interpolation
	mul r2, r1, r4                       @ 080AFC38
	asr r2, r2, #7                       @ 080AFC3C
	strh r2, [r5], #2                    @ 080AFC40
	add r6, r6, r7                       @ 080AFC44
	add r0, r0, r6, lsr #23              @ 080AFC48
	and r6, r6, fp                       @ 080AFC4C
	cmp r0, sl                           @ 080AFC50
	blge mix_voice_sample_end            @ 080AFC54
	cmp r5, sb                           @ 080AFC58
	bne L_80AFC24                        @ 080AFC5C
	b L_80AFD30                          @ 080AFC60
L_80AFC64:
	ldrsb r1, [r0]                       @ 080AFC64
	ldrsb r2, [r0, #1]                   @ 080AFC68
	sub r2, r2, r1                       @ 080AFC6C
	mul r3, r6, r2                       @ 080AFC70
	add r1, r1, r3, asr #23              @ 080AFC74
	mul r2, r1, r4                       @ 080AFC78
	ldrsh r1, [r5]                       @ 080AFC7C
	add r1, r1, r2, asr #7               @ 080AFC80
	strh r1, [r5], #2                    @ 080AFC84
	add r6, r6, r7                       @ 080AFC88
	add r0, r0, r6, lsr #23              @ 080AFC8C
	and r6, r6, fp                       @ 080AFC90
	cmp r0, sl                           @ 080AFC94
	blge mix_voice_sample_end            @ 080AFC98
	ldrsb r1, [r0]                       @ 080AFC9C
	ldrsb r2, [r0, #1]                   @ 080AFCA0
	sub r2, r2, r1                       @ 080AFCA4
	mul r3, r6, r2                       @ 080AFCA8
	add r1, r1, r3, asr #23              @ 080AFCAC
	mul r2, r1, r4                       @ 080AFCB0
	ldrsh r1, [r5]                       @ 080AFCB4
	add r1, r1, r2, asr #7               @ 080AFCB8
	strh r1, [r5], #2                    @ 080AFCBC
	add r6, r6, r7                       @ 080AFCC0
	add r0, r0, r6, lsr #23              @ 080AFCC4
	and r6, r6, fp                       @ 080AFCC8
	cmp r0, sl                           @ 080AFCCC
	blge mix_voice_sample_end            @ 080AFCD0
	cmp r5, sb                           @ 080AFCD4
	bne L_80AFC64                        @ 080AFCD8
	b L_80AFD30                          @ 080AFCDC

@ mix_voice_sample_end: end of sample reached while mixing
mix_voice_sample_end:
	ldr r8, [sp, #0x20]                  @ 080AFCE0
	ldrb r3, [r8, #1]                    @ 080AFCE4
	cmp r3, #1                           @ 080AFCE8
	beq L_80AFD08                        @ 080AFCEC
	cmp r3, #2                           @ 080AFCF0
	beq L_80AFD20                        @ 080AFCF4
	cmp r3, #3                           @ 080AFCF8
	beq L_80AFD14                        @ 080AFCFC
	cmp r3, #4                           @ 080AFD00
	beq L_80AFD20                        @ 080AFD04
L_80AFD08:
	mov r3, #0x10                        @ 080AFD08
	strb r3, [r8]                        @ 080AFD0C
	b L_80AFD30                          @ 080AFD10
L_80AFD14:
	mov r3, #0x10                        @ 080AFD14
	strb r3, [r8]                        @ 080AFD18
	b L_80AFD30                          @ 080AFD1C
L_80AFD20:
	ldr r3, [r8, #0x20]                  @ 080AFD20
	ldr r3, [r3, #0x14]                  @ 080AFD24
	sub r0, r0, r3                       @ 080AFD28
	bx lr                                @ 080AFD2C
L_80AFD30:
	ldr r1, [sp, #0x10]                  @ 080AFD30
	subs r1, r1, #1                      @ 080AFD34
	str r1, [sp, #0x10]                  @ 080AFD38
L_80AFD3C:
	ldr lr, [sp, #0x1c]                  @ 080AFD3C
	bx lr                                @ 080AFD40

@ ------------------------------------------------------------------
@ calc_pitch   ROM 0x080AFD44 / IWRAM 0x03003AAC (ARM)
@ Return r7 = per-sample step (9.23 fixed) for voice r0: key - root + fine tune (cents)
@ + pitch bend * range + LFO * modwheel * depth, through pitch_table, scaled by the sample
@ rate and mix_pitch_scale (2^38 / mixing rate).
@ ------------------------------------------------------------------
calc_pitch:
	ldr r4, [r0, #0x20]                  @ 080AFD44
	ldr r3, [r4, #0x34]                  @ 080AFD48
	ldr r7, lit_80AFEC8                  @ 080AFD4C  = 0x028F5C29
	smull r1, r2, r7, r3                 @ 080AFD50
	push {r1, r2}                        @ 080AFD54
	ldrsb r8, [r0, #6]                   @ 080AFD58
	cmp r8, #0                           @ 080AFD5C
	bmi L_80AFD68                        @ 080AFD60
	b L_80AFD7C                          @ 080AFD64
L_80AFD68:
	mov r1, #0                           @ 080AFD68
	mov r2, #0                           @ 080AFD6C
	push {r1, r2}                        @ 080AFD70
	push {r1, r2}                        @ 080AFD74
	b L_80AFE48                          @ 080AFD78
L_80AFD7C:
	mov r7, #4                           @ 080AFD7C
	ldr r6, lit_80AFECC                  @ 080AFD80  = chan_instrument
	mla r2, r8, r7, r6                   @ 080AFD84
	ldr r2, [r2]                         @ 080AFD88
	ldr r3, [r2, #0x38]                  @ 080AFD8C
	mov r7, #0x80000                     @ 080AFD90
	mul r3, r7, r3                       @ 080AFD94
	ldrsb r7, [r0, #6]                   @ 080AFD98
	ldr r8, lit_80AFED0                  @ 080AFD9C  = chan_bend
	mov r1, #4                           @ 080AFDA0
	mla r8, r7, r1, r8                   @ 080AFDA4
	ldr r7, [r8]                         @ 080AFDA8
	sub r7, r7, #0x2000                  @ 080AFDAC
	smull r1, r2, r7, r3                 @ 080AFDB0
	push {r1, r2}                        @ 080AFDB4
	ldrsb r8, [r0, #6]                   @ 080AFDB8
	mov r7, #4                           @ 080AFDBC
	ldr r6, lit_80AFED4                  @ 080AFDC0  = chan_instrument
	mla r2, r8, r7, r6                   @ 080AFDC4
	ldr r2, [r2]                         @ 080AFDC8
	ldr r2, [r2, #0x40]                  @ 080AFDCC
	ldrsb r8, [r0, #6]                   @ 080AFDD0
	mov r7, #8                           @ 080AFDD4
	ldr sb, lit_80AFED8                  @ 080AFDD8  = chan_mod
	mla r8, r7, r8, sb                   @ 080AFDDC
	mov r1, #0                           @ 080AFDE0
	mov r2, #0                           @ 080AFDE4
	ldr sb, [r8]                         @ 080AFDE8
	cmp sb, #0                           @ 080AFDEC
	beq L_80AFE44                        @ 080AFDF0
	ldr r7, [r8, #4]                     @ 080AFDF4
	lsr r1, r7, #0x10                    @ 080AFDF8
	sub r7, r7, r1, lsl #16              @ 080AFDFC
	ldr r6, lit_80AFEDC                  @ 080AFE00  = lfo_sine_table
	add r6, r6, r1, lsl #2               @ 080AFE04
	ldm r6, {r1, r2}                     @ 080AFE08
	sub r2, r2, r1                       @ 080AFE0C
	smull r6, r7, r2, r7                 @ 080AFE10
	lsl r7, r7, #0x10                    @ 080AFE14
	add r7, r7, r6, lsr #16              @ 080AFE18
	add r1, r1, r7                       @ 080AFE1C
	add sb, sb, #1                       @ 080AFE20
	mul sb, r1, sb                       @ 080AFE24
	ldrsb r8, [r0, #6]                   @ 080AFE28
	mov r7, #4                           @ 080AFE2C
	ldr r6, lit_80AFEE0                  @ 080AFE30  = chan_instrument
	mla r2, r8, r7, r6                   @ 080AFE34
	ldr r2, [r2]                         @ 080AFE38
	ldr r2, [r2, #0x40]                  @ 080AFE3C
	smull r1, r2, sb, r2                 @ 080AFE40
L_80AFE44:
	push {r1, r2}                        @ 080AFE44
L_80AFE48:
	pop {r1, r2, r3, r7, r8, sb}         @ 080AFE48
	adds r1, r1, r3                      @ 080AFE4C
	adc r2, r2, r7                       @ 080AFE50
	adds r1, r1, r8                      @ 080AFE54
	adc r2, r2, sb                       @ 080AFE58
	ldr r3, [r4, #0xc]                   @ 080AFE5C
	ldrb sb, [r0, #5]                    @ 080AFE60
	sub r3, sb, r3                       @ 080AFE64
	add r3, r3, r2                       @ 080AFE68
	ldr r6, lit_80AFEE4                  @ 080AFE6C  = 0x080B095C
	add r2, r6, r3, lsl #2               @ 080AFE70
	ldm r2, {r3, r7}                     @ 080AFE74
	sub r2, r7, r3                       @ 080AFE78
	umull sb, sl, r1, r2                 @ 080AFE7C
	add r7, r3, sl                       @ 080AFE80
	ldr r1, lit_80AFEE8                  @ 080AFE84  = mix_pitch_scale
	ldr r1, [r1]                         @ 080AFE88
	ldr r2, [r4, #8]                     @ 080AFE8C
	umull r8, sb, r1, r2                 @ 080AFE90
	lsr r8, r8, #0xe                     @ 080AFE94
	add r8, r8, sb, lsl #18              @ 080AFE98
	umull sl, r4, r7, r8                 @ 080AFE9C
	lsr sl, sl, #0x18                    @ 080AFEA0
	orr r7, sl, r4, lsl #8               @ 080AFEA4
	bx lr                                @ 080AFEA8
lit_80AFEAC:
	.word sfx_master_volume
lit_80AFEB0:
	.word music_master_volume
lit_80AFEB4:
	.word chan_volume
lit_80AFEB8:
	.word chan_gain
lit_80AFEBC:
	.word mix_samples_per_frame
lit_80AFEC0:
	.word 0x007FFFFF
lit_80AFEC4:
	.word mix_max_voices
lit_80AFEC8:
	.word 0x028F5C29
lit_80AFECC:
	.word chan_instrument
lit_80AFED0:
	.word chan_bend
lit_80AFED4:
	.word chan_instrument
lit_80AFED8:
	.word chan_mod
lit_80AFEDC:
	.word lfo_sine_table
lit_80AFEE0:
	.word chan_instrument
lit_80AFEE4:
	.word 0x080B095C
lit_80AFEE8:
	.word mix_pitch_scale
iwram_code_end:

	.thumb

@ ------------------------------------------------------------------
@ snd_request_song   ROM 0x080AFEEC (Thumb)
@ API: r0 = song number. Latched; started at the next snd_frame.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_request_song
snd_request_song:
	push {r4, r5, r6, r7, lr}            @ 080AFEEC
	mov r3, r8                           @ 080AFEEE
	mov r4, sb                           @ 080AFEF0
	mov r5, sl                           @ 080AFEF2
	mov r6, fp                           @ 080AFEF4
	mov r7, ip                           @ 080AFEF6
	push {r3, r4, r5, r6, r7}            @ 080AFEF8
	ldr r1, lit_80B0144                  @ 080AFEFA  = seq_pending_song
	str r0, [r1]                         @ 080AFEFC
	pop {r3, r4, r5, r6, r7}             @ 080AFEFE
	mov r8, r3                           @ 080AFF00
	mov sb, r4                           @ 080AFF02
	mov sl, r5                           @ 080AFF04
	mov fp, r6                           @ 080AFF06
	mov ip, r7                           @ 080AFF08
	pop {r4, r5, r6, r7}                 @ 080AFF0A
	pop {r1}                             @ 080AFF0C
	bx r1                                @ 080AFF0E

@ ------------------------------------------------------------------
@ snd_vblank   ROM 0x080AFF10 (Thumb)
@ API (V-blank): flip the double buffer and restart DMA1 -> FIFO A on the buffer
@ that was just mixed. Leaf, no stack.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_vblank
snd_vblank:
	ldr r0, lit_80B0148                  @ 080AFF10  = dma_buffer_flag
	ldr r2, [r0]                         @ 080AFF12
	mvns r2, r2                          @ 080AFF14
	str r2, [r0]                         @ 080AFF16
	ldr r1, lit_80B014C                  @ 080AFF18  = cfg_buffer_a
	cmp r2, #0                           @ 080AFF1A
	beq L_80AFF20                        @ 080AFF1C
	ldr r1, lit_80B0150                  @ 080AFF1E  = cfg_buffer_b
L_80AFF20:
	ldr r1, [r1]                         @ 080AFF20
	ldr r2, lit_80B0154                  @ 080AFF22  = REG_FIFO_A
	ldr r0, lit_80B0158                  @ 080AFF24  = REG_DMA1DAD
	str r2, [r0]                         @ 080AFF26
	ldr r0, lit_80B015C                  @ 080AFF28  = REG_DMA1SAD
	str r1, [r0]                         @ 080AFF2A
	ldr r0, lit_80B0160                  @ 080AFF2C  = REG_DMA1CNT_L
	ldr r2, lit_80B0164                  @ 080AFF2E  = 0x84400004
	str r2, [r0]                         @ 080AFF30
	ldr r2, lit_80B0168                  @ 080AFF32  = 0x04400000
	adds r0, #2                          @ 080AFF34
	strh r2, [r0]                        @ 080AFF36
	ldr r2, lit_80B0154                  @ 080AFF38  = REG_FIFO_A
	ldr r3, lit_80B016C                  @ 080AFF3A  = 0xF6000000
	ldr r0, lit_80B015C                  @ 080AFF3C  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 080AFF3E
	ldr r0, lit_80B0170                  @ 080AFF40  = REG_SOUNDCNT_X
	movs r1, #0x80                       @ 080AFF42
	strh r1, [r0]                        @ 080AFF44
	bx lr                                @ 080AFF46

@ ------------------------------------------------------------------
@ snd_init   ROM 0x080AFF48 (Thumb)
@ API: one-time init. DirectSound A only, mono, Timer 0, 13379 Hz, 8 mixed voices.
@ Copies the ARM block into IWRAM with DMA2.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_init
snd_init:
	push {r4, r5, r6, r7, lr}            @ 080AFF48
	mov r3, r8                           @ 080AFF4A
	mov r4, sb                           @ 080AFF4C
	mov r5, sl                           @ 080AFF4E
	mov r6, fp                           @ 080AFF50
	mov r7, ip                           @ 080AFF52
	push {r3, r4, r5, r6, r7}            @ 080AFF54
	sub sp, #4                           @ 080AFF56
	ldr r0, lit_80B0170                  @ 080AFF58  = REG_SOUNDCNT_X
	movs r1, #0                          @ 080AFF5A
	strh r1, [r0]                        @ 080AFF5C
	ldr r0, lit_80B0174                  @ 080AFF5E  = REG_DMA1CNT_H
	movs r2, #0                          @ 080AFF60
	strh r2, [r0]                        @ 080AFF62
	ldr r0, lit_80B0178                  @ 080AFF64  = REG_TM0CNT_H
	movs r1, #0                          @ 080AFF66
	strh r1, [r0]                        @ 080AFF68
	movs r0, #0                          @ 080AFF6A
	str r0, [sp]                         @ 080AFF6C
	mov r1, sp                           @ 080AFF6E
	ldr r2, lit_80B017C                  @ 080AFF70  = cfg_buffer_b
	ldr r2, [r2]                         @ 080AFF72
	ldr r3, lit_80B0180                  @ 080AFF74  = 0x85000038
	ldr r0, lit_80B015C                  @ 080AFF76  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 080AFF78
	movs r0, #0                          @ 080AFF7A
	str r0, [sp]                         @ 080AFF7C
	mov r1, sp                           @ 080AFF7E
	ldr r2, lit_80B0184                  @ 080AFF80  = cfg_buffer_a
	ldr r2, [r2]                         @ 080AFF82
	ldr r3, lit_80B0180                  @ 080AFF84  = 0x85000038
	ldr r0, lit_80B015C                  @ 080AFF86  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 080AFF88
	ldr r0, lit_80B0188                  @ 080AFF8A  = dma_buffer_flag
	movs r1, #0                          @ 080AFF8C
	str r1, [r0]                         @ 080AFF8E
	movs r1, #0                          @ 080AFF90
	mvns r1, r1                          @ 080AFF92
	ldr r0, lit_80B018C                  @ 080AFF94  = seq_pending_song
	str r1, [r0]                         @ 080AFF96
	ldr r0, lit_80B0190                  @ 080AFF98  = seq_current_song
	str r1, [r0]                         @ 080AFF9A
	ldr r0, lit_80B0194                  @ 080AFF9C  = seq_start_marker
	str r1, [r0]                         @ 080AFF9E
	ldr r0, lit_80B0198                  @ 080AFFA0  = REG_SOUNDCNT_H
	movs r1, #0                          @ 080AFFA2
	strh r1, [r0]                        @ 080AFFA4
	ldrh r1, [r0]                        @ 080AFFA6
	ldr r2, lit_80B019C                  @ 080AFFA8  = 0x00008800 ; FIFO A+B reset
	orrs r1, r2                          @ 080AFFAA
	strh r1, [r0]                        @ 080AFFAC
	ldr r0, lit_80B0154                  @ 080AFFAE  = REG_FIFO_A
	movs r1, #0x80                       @ 080AFFB0
	strb r1, [r0]                        @ 080AFFB2
	movs r1, #0x80                       @ 080AFFB4
	strb r1, [r0, #4]                    @ 080AFFB6
	ldr r0, lit_80B0198                  @ 080AFFB8  = REG_SOUNDCNT_H
	ldr r1, [r0]                         @ 080AFFBA
	ldr r2, lit_80B01A0                  @ 080AFFBC  = 0x0000030C ; DSA 100%, DSB 100%, DSA L+R, Timer 0
	orrs r1, r2                          @ 080AFFBE
	strh r1, [r0]                        @ 080AFFC0
	ldr r0, lit_80B01A4                  @ 080AFFC2  = REG_SOUNDBIAS_H
	ldr r1, [r0]                         @ 080AFFC4
	movs r2, #0xc0                       @ 080AFFC6
	bics r1, r2                          @ 080AFFC8
	movs r2, #0x40                       @ 080AFFCA
	orrs r1, r2                          @ 080AFFCC
	strb r1, [r0]                        @ 080AFFCE  SOUNDBIAS: 8-bit / 65.536 kHz PWM
	bl init_music_voices                 @ 080AFFD0
	bl init_sfx_voices                   @ 080AFFD4
	movs r0, #0x80                       @ 080AFFD8
	bl snd_set_music_volume              @ 080AFFDA
	movs r0, #0x80                       @ 080AFFDE
	bl snd_set_sfx_volume                @ 080AFFE0
	bl reset_channel_volume              @ 080AFFE4
	bl reset_channel_gain                @ 080AFFE8
	bl reset_mono_flags                  @ 080AFFEC
	ldr r1, lit_80B01A8                  @ 080AFFF0  = voice_start
	ldr r2, lit_80B01AC                  @ 080AFFF2  = (voice_start - iwram_code_start + IWRAM_CODE_BASE)
	ldr r3, lit_80B01B0                  @ 080AFFF4  = iwram_code_size
	ldr r3, [r3]                         @ 080AFFF6
	ldr r4, lit_80B01B4                  @ 080AFFF8  = 0x00001234
	cmp r3, r4                           @ 080AFFFA
	beq L_80B0000                        @ 080AFFFC  dead size check: skips a 0xEFFF trap halfword (compiled-out assert)
	.hword 0xEFFF
L_80B0000:
	lsrs r3, r3, #2                      @ 080B0000
	ldr r0, lit_80B01B8                  @ 080B0002  = 0x84000000
	orrs r3, r0                          @ 080B0004
	ldr r0, lit_80B015C                  @ 080B0006  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 080B0008
	bl wait_vcount_160                   @ 080B000A
	ldr r0, lit_80B01BC                  @ 080B000E  = song_table_ptr
	ldr r1, lit_80B01C0                  @ 080B0010  = song_table
	str r1, [r0]                         @ 080B0012
	ldr r0, lit_80B01C4                  @ 080B0014  = sfx_table_ptr
	ldr r1, lit_80B01C8                  @ 080B0016  = sfx_table
	str r1, [r0]                         @ 080B0018
	ldr r0, lit_80B01CC                  @ 080B001A  = 0x00003443
	bl snd_set_mix_rate                  @ 080B001C  13379 Hz
	movs r0, #8                          @ 080B0020
	bl snd_set_max_voices                @ 080B0022  8 voices
	add sp, #4                           @ 080B0026
	pop {r3, r4, r5, r6, r7}             @ 080B0028
	mov r8, r3                           @ 080B002A
	mov sb, r4                           @ 080B002C
	mov sl, r5                           @ 080B002E
	mov fp, r6                           @ 080B0030
	mov ip, r7                           @ 080B0032
	pop {r4, r5, r6, r7}                 @ 080B0034
	pop {r1}                             @ 080B0036
	bx r1                                @ 080B0038

@ ------------------------------------------------------------------
@ snd_frame   ROM 0x080B003A (Thumb)
@ API: per-frame update (start pending song, sequencer, LFO, envelopes, mixer).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_frame
snd_frame:
	push {r4, r5, r6, r7, lr}            @ 080B003A
	mov r3, r8                           @ 080B003C
	mov r4, sb                           @ 080B003E
	mov r5, sl                           @ 080B0040
	mov r6, fp                           @ 080B0042
	mov r7, ip                           @ 080B0044
	push {r3, r4, r5, r6, r7}            @ 080B0046
	ldr r0, lit_80B01D0                  @ 080B0048  = seq_pending_song
	ldr r1, [r0]                         @ 080B004A
	cmp r1, #0                           @ 080B004C
	bmi L_80B00D2                        @ 080B004E
	movs r2, #0                          @ 080B0050
	mvns r2, r2                          @ 080B0052
	str r2, [r0]                         @ 080B0054
	ldr r0, lit_80B01D4                  @ 080B0056  = seq_current_song
	str r1, [r0]                         @ 080B0058
	ldr r0, lit_80B01D8                  @ 080B005A  = seq_track_time
	movs r2, #0x80                       @ 080B005C
	movs r3, #0                          @ 080B005E
L_80B0060:
	subs r2, #4                          @ 080B0060
	str r3, [r0, r2]                     @ 080B0062
	bne L_80B0060                        @ 080B0064
	ldr r0, lit_80B01DC                  @ 080B0066  = song_table_ptr
	ldr r0, [r0]                         @ 080B0068
	lsls r1, r1, #2                      @ 080B006A
	ldr r0, [r0, r1]                     @ 080B006C
	ldr r3, [r0]                         @ 080B006E
	ldr r2, lit_80B01E0                  @ 080B0070  = seq_num_tracks
	str r3, [r2]                         @ 080B0072
	ldr r1, [r0, #4]                     @ 080B0074
	ldr r2, lit_80B01E4                  @ 080B0076  = seq_division
	str r1, [r2]                         @ 080B0078
	ldr r1, [r0, #8]                     @ 080B007A
	ldr r2, lit_80B01E8                  @ 080B007C  = seq_track_ptr
	ldm r1!, {r3, r4, r5, r6, r7}        @ 080B007E
	stm r2!, {r3, r4, r5, r6, r7}        @ 080B0080
	ldm r1!, {r3, r4, r5, r6, r7}        @ 080B0082
	stm r2!, {r3, r4, r5, r6, r7}        @ 080B0084
	ldm r1, {r1, r3, r4, r5, r6, r7}     @ 080B0086
	stm r2!, {r1, r3, r4, r5, r6, r7}    @ 080B0088
	ldr r1, [r0, #0xc]                   @ 080B008A
	ldr r2, lit_80B01EC                  @ 080B008C  = seq_prog_map_ptr
	str r1, [r2]                         @ 080B008E
	ldr r1, [r0, #0x10]                  @ 080B0090
	ldr r2, lit_80B01F0                  @ 080B0092  = seq_inst_table_ptr
	str r1, [r2]                         @ 080B0094
	ldr r0, lit_80B01F4                  @ 080B0096  = seq_track_time
	movs r1, #0                          @ 080B0098
	adds r2, r1, #0                      @ 080B009A
	stm r0!, {r1, r2}                    @ 080B009C
	ldr r0, lit_80B01F8                  @ 080B009E  = seq_frame_time
	movs r1, #1                          @ 080B00A0
	str r1, [r0]                         @ 080B00A2
	ldr r0, lit_80B01FC                  @ 080B00A4  = seq_tempo
	movs r1, #0                          @ 080B00A6
	str r1, [r0]                         @ 080B00A8
	ldr r0, lit_80B0200                  @ 080B00AA  = seq_start_marker ; DKC3: start marker pending -> seek_start_marker
	ldr r1, [r0]                         @ 080B00AC
	cmp r1, #0                           @ 080B00AE
	bmi L_80B00BE                        @ 080B00B0
	bl seek_start_marker                 @ 080B00B2
	ldr r0, lit_80B0204                  @ 080B00B6  = seq_start_marker
	movs r1, #0                          @ 080B00B8
	mvns r1, r1                          @ 080B00BA
	str r1, [r0]                         @ 080B00BC
L_80B00BE:
	bl init_music_voices                 @ 080B00BE
	bl reset_channel_gain                @ 080B00C2
	bl reset_pitch_bend                  @ 080B00C6
	bl reset_modulation                  @ 080B00CA
	bl reset_adsr_override               @ 080B00CE
L_80B00D2:
	bl clear_mix_buffer                  @ 080B00D2
	ldr r0, lit_80B0208                  @ 080B00D6  = music_paused
	ldr r1, [r0]                         @ 080B00D8
	cmp r1, #1                           @ 080B00DA
	beq L_80B00FE                        @ 080B00DC
	ldr r0, lit_80B020C                  @ 080B00DE  = seq_current_song
	ldr r1, [r0]                         @ 080B00E0
	cmp r1, #0                           @ 080B00E2
	bmi L_80B00FE                        @ 080B00E4
	mov r0, pc                           @ 080B00E6
	adds r0, #7                          @ 080B00E8
	mov lr, r0                           @ 080B00EA
	ldr r0, lit_80B0210                  @ 080B00EC  = (seq_update - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B00EE
L_80B00F0:
	bl lfo_update                        @ 080B00F0
	mov r0, pc                           @ 080B00F4
	adds r0, #7                          @ 080B00F6
	mov lr, r0                           @ 080B00F8
	ldr r0, lit_80B0214                  @ 080B00FA  = (env_update_music - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B00FC
L_80B00FE:
	bl sfx_timer_update                  @ 080B00FE
	mov r0, pc                           @ 080B0102
	adds r0, #7                          @ 080B0104
	mov lr, r0                           @ 080B0106
	ldr r0, lit_80B0218                  @ 080B0108  = (env_update_sfx - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B010A
L_80B010C:
	mov r0, pc                           @ 080B010C
	adds r0, #7                          @ 080B010E
	mov lr, r0                           @ 080B0110
	ldr r0, lit_80B021C                  @ 080B0112  = (mix_frame - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B0114
L_80B0116:
	ldr r0, lit_80B0220                  @ 080B0116  = music_paused
	ldr r1, [r0]                         @ 080B0118
	cmp r1, #1                           @ 080B011A
	beq L_80B0128                        @ 080B011C
	mov r0, pc                           @ 080B011E
	adds r0, #7                          @ 080B0120
	mov lr, r0                           @ 080B0122
	ldr r0, lit_80B0224                  @ 080B0124  = (advance_music_voices - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B0126
L_80B0128:
	mov r0, pc                           @ 080B0128
	adds r0, #7                          @ 080B012A
	mov lr, r0                           @ 080B012C
	ldr r0, lit_80B0228                  @ 080B012E  = (advance_sfx_voices - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B0130
L_80B0132:
	pop {r3, r4, r5, r6, r7}             @ 080B0132
	mov r8, r3                           @ 080B0134
	mov sb, r4                           @ 080B0136
	mov sl, r5                           @ 080B0138
	mov fp, r6                           @ 080B013A
	mov ip, r7                           @ 080B013C
	pop {r4, r5, r6, r7}                 @ 080B013E
	pop {r1}                             @ 080B0140
	bx r1                                @ 080B0142
lit_80B0144:
	.word seq_pending_song
lit_80B0148:
	.word dma_buffer_flag
lit_80B014C:
	.word cfg_buffer_a
lit_80B0150:
	.word cfg_buffer_b
lit_80B0154:
	.word REG_FIFO_A
lit_80B0158:
	.word REG_DMA1DAD
lit_80B015C:
	.word REG_DMA1SAD
lit_80B0160:
	.word REG_DMA1CNT_L
lit_80B0164:
	.word 0x84400004
lit_80B0168:
	.word 0x04400000
lit_80B016C:
	.word 0xF6000000
lit_80B0170:
	.word REG_SOUNDCNT_X
lit_80B0174:
	.word REG_DMA1CNT_H
lit_80B0178:
	.word REG_TM0CNT_H
lit_80B017C:
	.word cfg_buffer_b
lit_80B0180:
	.word 0x85000038
lit_80B0184:
	.word cfg_buffer_a
lit_80B0188:
	.word dma_buffer_flag
lit_80B018C:
	.word seq_pending_song
lit_80B0190:
	.word seq_current_song
lit_80B0194:
	.word seq_start_marker
lit_80B0198:
	.word REG_SOUNDCNT_H
lit_80B019C:
	.word 0x00008800
lit_80B01A0:
	.word 0x0000030C
lit_80B01A4:
	.word REG_SOUNDBIAS_H
lit_80B01A8:
	.word voice_start
lit_80B01AC:
	.word (voice_start - iwram_code_start + IWRAM_CODE_BASE)
lit_80B01B0:
	.word iwram_code_size
lit_80B01B4:
	.word 0x00001234
lit_80B01B8:
	.word 0x84000000
lit_80B01BC:
	.word song_table_ptr
lit_80B01C0:
	.word song_table
lit_80B01C4:
	.word sfx_table_ptr
lit_80B01C8:
	.word sfx_table
lit_80B01CC:
	.word 0x00003443
lit_80B01D0:
	.word seq_pending_song
lit_80B01D4:
	.word seq_current_song
lit_80B01D8:
	.word seq_track_time
lit_80B01DC:
	.word song_table_ptr
lit_80B01E0:
	.word seq_num_tracks
lit_80B01E4:
	.word seq_division
lit_80B01E8:
	.word seq_track_ptr
lit_80B01EC:
	.word seq_prog_map_ptr
lit_80B01F0:
	.word seq_inst_table_ptr
lit_80B01F4:
	.word seq_track_time
lit_80B01F8:
	.word seq_frame_time
lit_80B01FC:
	.word seq_tempo
lit_80B0200:
	.word seq_start_marker
lit_80B0204:
	.word seq_start_marker
lit_80B0208:
	.word music_paused
lit_80B020C:
	.word seq_current_song
lit_80B0210:
	.word (seq_update - iwram_code_start + IWRAM_CODE_BASE)
lit_80B0214:
	.word (env_update_music - iwram_code_start + IWRAM_CODE_BASE)
lit_80B0218:
	.word (env_update_sfx - iwram_code_start + IWRAM_CODE_BASE)
lit_80B021C:
	.word (mix_frame - iwram_code_start + IWRAM_CODE_BASE)
lit_80B0220:
	.word music_paused
lit_80B0224:
	.word (advance_music_voices - iwram_code_start + IWRAM_CODE_BASE)
lit_80B0228:
	.word (advance_sfx_voices - iwram_code_start + IWRAM_CODE_BASE)

@ ------------------------------------------------------------------
@ lfo_update   ROM 0x080B022C (Thumb)
@ Advance the LFO phase of every channel whose mod wheel is non-zero.
@ ------------------------------------------------------------------
	.thumb_func
lfo_update:
	ldr r0, lit_80B04B0                  @ 080B022C  = chan_mod-8
	ldr r7, lit_80B04B4                  @ 080B022E  = chan_mod-4
	movs r1, #0x80                       @ 080B0230
	movs r6, #0                          @ 080B0232
L_80B0234:
	ldr r2, [r0, r1]                     @ 080B0234
	cmp r2, #0                           @ 080B0236
	bne L_80B0242                        @ 080B0238
	str r6, [r7, r1]                     @ 080B023A
L_80B023C:
	subs r1, #8                          @ 080B023C
	bne L_80B0234                        @ 080B023E
	bx lr                                @ 080B0240
L_80B0242:
	lsrs r3, r1, #3                      @ 080B0242
	subs r3, #1                          @ 080B0244
	ldr r4, lit_80B04B8                  @ 080B0246  = chan_instrument
	movs r5, #4                          @ 080B0248
	muls r5, r3, r5                      @ 080B024A
	ldr r3, [r4, r5]                     @ 080B024C
	ldr r3, [r3, #0x3c]                  @ 080B024E
	adds r4, r0, r1                      @ 080B0250
	ldr r5, [r4, #4]                     @ 080B0252
	adds r3, r5, r3                      @ 080B0254
	ldr r5, lit_80B04BC                  @ 080B0256  = 0x00FFFFFF
	ands r3, r5                          @ 080B0258
	str r3, [r4, #4]                     @ 080B025A
	b L_80B023C                          @ 080B025C

@ ------------------------------------------------------------------
@ sfx_timer_update   ROM 0x080B025E (Thumb)
@ Count down SFX auto-release timers; at zero the voice is keyed off.
@ ------------------------------------------------------------------
	.thumb_func
sfx_timer_update:
	ldr r5, lit_80B04C0                  @ 080B025E  = sfx_voices
	movs r3, #0                          @ 080B0260
	ldr r6, lit_80B04C4                  @ 080B0262  = cfg_sfx_pool_bytes
	ldr r6, [r6]                         @ 080B0264
	ldr r0, lit_80B04C8                  @ 080B0266  = sfx_timer
L_80B0268:
	ldrb r4, [r5, r3]                    @ 080B0268
	cmp r4, #0x11                        @ 080B026A
	beq L_80B0278                        @ 080B026C
L_80B026E:
	adds r0, #4                          @ 080B026E
	adds r3, #0x28                       @ 080B0270
	cmp r3, r6                           @ 080B0272
	blt L_80B0268                        @ 080B0274
	bx lr                                @ 080B0276
L_80B0278:
	ldr r1, [r0]                         @ 080B0278
	subs r1, #1                          @ 080B027A
	bmi L_80B0286                        @ 080B027C
	str r1, [r0]                         @ 080B027E
	bne L_80B0286                        @ 080B0280
	movs r1, #0x12                       @ 080B0282
	strb r1, [r5, r3]                    @ 080B0284
L_80B0286:
	b L_80B026E                          @ 080B0286

@ ------------------------------------------------------------------
@ sfx_start_voice   ROM 0x080B0288 (Thumb)
@ Allocate an SFX voice (free, else released). In: r0 = sfx id, r1 = volume,
@ r2 = pitch mult (16.16). Out: r0 = handle (-1 if none), r1 = voice index.
@ ------------------------------------------------------------------
	.thumb_func
sfx_start_voice:
	push {lr}                            @ 080B0288
	ldr r5, lit_80B04CC                  @ 080B028A  = sfx_voices
	movs r3, #0                          @ 080B028C
	ldr r6, lit_80B04D0                  @ 080B028E  = cfg_sfx_pool_bytes
	ldr r6, [r6]                         @ 080B0290
L_80B0292:
	ldrb r4, [r5, r3]                    @ 080B0292
	cmp r4, #0x10                        @ 080B0294
	beq L_80B02B4                        @ 080B0296
	adds r3, #0x28                       @ 080B0298
	cmp r3, r6                           @ 080B029A
	blt L_80B0292                        @ 080B029C
	movs r3, #0                          @ 080B029E
L_80B02A0:
	ldrb r4, [r5, r3]                    @ 080B02A0
	cmp r4, #0x12                        @ 080B02A2
	beq L_80B02B4                        @ 080B02A4
	adds r3, #0x28                       @ 080B02A6
	cmp r3, r6                           @ 080B02A8
	blt L_80B02A0                        @ 080B02AA
	movs r1, #0                          @ 080B02AC
	mvns r1, r1                          @ 080B02AE
	adds r0, r1, #0                      @ 080B02B0
	b L_80B0302                          @ 080B02B2
L_80B02B4:
	adds r5, r5, r3                      @ 080B02B4
	movs r4, #0                          @ 080B02B6
	mvns r4, r4                          @ 080B02B8
	adds r3, #0x28                       @ 080B02BA
L_80B02BC:
	adds r4, #1                          @ 080B02BC
	subs r3, #0x28                       @ 080B02BE
	bne L_80B02BC                        @ 080B02C0
	push {r4}                            @ 080B02C2
	ldr r3, lit_80B04D4                  @ 080B02C4  = sfx_handle_counter
	ldr r7, [r3]                         @ 080B02C6
	adds r7, #1                          @ 080B02C8
	movs r6, #1                          @ 080B02CA
	cmn r7, r6                           @ 080B02CC
	bne L_80B02D2                        @ 080B02CE
	adds r7, #1                          @ 080B02D0
L_80B02D2:
	str r7, [r3]                         @ 080B02D2
	ldr r3, lit_80B04D8                  @ 080B02D4  = sfx_handle
	lsls r4, r4, #2                      @ 080B02D6
	str r7, [r3, r4]                     @ 080B02D8
	push {r7}                            @ 080B02DA
	lsls r0, r0, #2                      @ 080B02DC
	ldr r4, lit_80B04DC                  @ 080B02DE  = sfx_table_ptr
	ldr r4, [r4]                         @ 080B02E0
	ldr r3, [r4, r0]                     @ 080B02E2
	ldr r0, [r3, #0xc]                   @ 080B02E4
	mov sb, r0                           @ 080B02E6
	adds r4, r0, #0                      @ 080B02E8
	ldr r7, [r3, #4]                     @ 080B02EA
	mov r8, r1                           @ 080B02EC
	adds r1, r2, #0                      @ 080B02EE
	adds r2, r3, #0                      @ 080B02F0
	mov r3, r8                           @ 080B02F2
	mov r0, pc                           @ 080B02F4
	adds r0, #7                          @ 080B02F6
	mov lr, r0                           @ 080B02F8
	ldr r0, lit_80B04E0                  @ 080B02FA  = (voice_start - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B02FC
L_80B02FE:
	pop {r0}                             @ 080B02FE
	pop {r1}                             @ 080B0300
L_80B0302:
	pop {r2}                             @ 080B0302
	bx r2                                @ 080B0304

@ ------------------------------------------------------------------
@ snd_sfx_is_playing   ROM 0x080B0306 (Thumb)
@ API: r0 = handle -> r0 = 1 if a voice still carries that handle.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_is_playing
snd_sfx_is_playing:
	push {r4, r5, r6, r7, lr}            @ 080B0306
	mov r3, r8                           @ 080B0308
	mov r4, sb                           @ 080B030A
	mov r5, sl                           @ 080B030C
	mov r6, fp                           @ 080B030E
	mov r7, ip                           @ 080B0310
	push {r3, r4, r5, r6, r7}            @ 080B0312
	bl sfx_find_handle                   @ 080B0314
	pop {r3, r4, r5, r6, r7}             @ 080B0318
	mov r8, r3                           @ 080B031A
	mov sb, r4                           @ 080B031C
	mov sl, r5                           @ 080B031E
	mov fp, r6                           @ 080B0320
	mov ip, r7                           @ 080B0322
	pop {r4, r5, r6, r7}                 @ 080B0324
	pop {r1}                             @ 080B0326
	bx r1                                @ 080B0328

@ ------------------------------------------------------------------
@ sfx_find_handle   ROM 0x080B032A (Thumb)
@ Out: r0 = 1 and r3 = byte offset of the voice holding handle r0, else r0 = 0.
@ ------------------------------------------------------------------
	.thumb_func
sfx_find_handle:
	movs r6, #0                          @ 080B032A
	ldr r2, lit_80B04E4                  @ 080B032C  = sfx_voices
	movs r3, #0                          @ 080B032E
	ldr r5, lit_80B04E8                  @ 080B0330  = cfg_sfx_pool_bytes
	ldr r5, [r5]                         @ 080B0332
L_80B0334:
	ldrb r4, [r2, r3]                    @ 080B0334
	cmp r4, #0x10                        @ 080B0336
	bne L_80B0346                        @ 080B0338
L_80B033A:
	adds r3, #0x28                       @ 080B033A
	adds r6, #4                          @ 080B033C
	cmp r3, r5                           @ 080B033E
	blt L_80B0334                        @ 080B0340
	movs r0, #0                          @ 080B0342
	mov pc, lr                           @ 080B0344
L_80B0346:
	ldr r4, lit_80B04EC                  @ 080B0346  = sfx_handle
	ldr r4, [r4, r6]                     @ 080B0348
	cmp r0, r4                           @ 080B034A
	bne L_80B033A                        @ 080B034C
	movs r0, #1                          @ 080B034E
	mov pc, lr                           @ 080B0350

@ ------------------------------------------------------------------
@ snd_sfx_set_pitch   ROM 0x080B0352 (Thumb)
@ API: r0 = handle, r1 = pitch multiplier (16.16).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_set_pitch
snd_sfx_set_pitch:
	push {r4, r5, r6, r7, lr}            @ 080B0352
	mov r3, r8                           @ 080B0354
	mov r4, sb                           @ 080B0356
	mov r5, sl                           @ 080B0358
	mov r6, fp                           @ 080B035A
	mov r7, ip                           @ 080B035C
	push {r3, r4, r5, r6, r7}            @ 080B035E
	bl sfx_find_handle                   @ 080B0360
	cmp r0, #0                           @ 080B0364
	beq L_80B036C                        @ 080B0366
	ldr r2, lit_80B04F0                  @ 080B0368  = sfx_voices+0x24
	str r1, [r2, r3]                     @ 080B036A
L_80B036C:
	pop {r3, r4, r5, r6, r7}             @ 080B036C
	mov r8, r3                           @ 080B036E
	mov sb, r4                           @ 080B0370
	mov sl, r5                           @ 080B0372
	mov fp, r6                           @ 080B0374
	mov ip, r7                           @ 080B0376
	pop {r4, r5, r6, r7}                 @ 080B0378
	pop {r1}                             @ 080B037A
	bx r1                                @ 080B037C

@ ------------------------------------------------------------------
@ snd_sfx_set_volume   ROM 0x080B037E (Thumb)
@ API: r0 = handle, r1 = volume (0-128).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_set_volume
snd_sfx_set_volume:
	push {r4, r5, r6, r7, lr}            @ 080B037E
	mov r3, r8                           @ 080B0380
	mov r4, sb                           @ 080B0382
	mov r5, sl                           @ 080B0384
	mov r6, fp                           @ 080B0386
	mov r7, ip                           @ 080B0388
	push {r3, r4, r5, r6, r7}            @ 080B038A
	bl sfx_find_handle                   @ 080B038C
	cmp r0, #0                           @ 080B0390
	beq L_80B0398                        @ 080B0392
	ldr r2, lit_80B04F4                  @ 080B0394  = sfx_voices+0x3
	strb r1, [r2, r3]                    @ 080B0396
L_80B0398:
	pop {r3, r4, r5, r6, r7}             @ 080B0398
	mov r8, r3                           @ 080B039A
	mov sb, r4                           @ 080B039C
	mov sl, r5                           @ 080B039E
	mov fp, r6                           @ 080B03A0
	mov ip, r7                           @ 080B03A2
	pop {r4, r5, r6, r7}                 @ 080B03A4
	pop {r1}                             @ 080B03A6
	bx r1                                @ 080B03A8

@ ------------------------------------------------------------------
@ snd_sfx_stop   ROM 0x080B03AA (Thumb)
@ API: r0 = handle. Frees the voice immediately (no release).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_stop
snd_sfx_stop:
	push {r4, r5, r6, r7, lr}            @ 080B03AA
	mov r3, r8                           @ 080B03AC
	mov r4, sb                           @ 080B03AE
	mov r5, sl                           @ 080B03B0
	mov r6, fp                           @ 080B03B2
	mov r7, ip                           @ 080B03B4
	push {r3, r4, r5, r6, r7}            @ 080B03B6
	bl sfx_find_handle                   @ 080B03B8
	cmp r0, #0                           @ 080B03BC
	beq L_80B03C6                        @ 080B03BE
	ldr r2, lit_80B04F8                  @ 080B03C0  = sfx_voices
	movs r1, #0x10                       @ 080B03C2
	strb r1, [r2, r3]                    @ 080B03C4
L_80B03C6:
	pop {r3, r4, r5, r6, r7}             @ 080B03C6
	mov r8, r3                           @ 080B03C8
	mov sb, r4                           @ 080B03CA
	mov sl, r5                           @ 080B03CC
	mov fp, r6                           @ 080B03CE
	mov ip, r7                           @ 080B03D0
	pop {r4, r5, r6, r7}                 @ 080B03D2
	pop {r1}                             @ 080B03D4
	bx r1                                @ 080B03D6

@ ------------------------------------------------------------------
@ snd_sfx_stop_all   ROM 0x080B03D8 (Thumb)
@ API: free every SFX voice.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_stop_all
snd_sfx_stop_all:
	push {r4, r5, r6, r7, lr}            @ 080B03D8
	mov r3, r8                           @ 080B03DA
	mov r4, sb                           @ 080B03DC
	mov r5, sl                           @ 080B03DE
	mov r6, fp                           @ 080B03E0
	mov r7, ip                           @ 080B03E2
	push {r3, r4, r5, r6, r7}            @ 080B03E4
	bl init_sfx_voices                   @ 080B03E6
	pop {r3, r4, r5, r6, r7}             @ 080B03EA
	mov r8, r3                           @ 080B03EC
	mov sb, r4                           @ 080B03EE
	mov sl, r5                           @ 080B03F0
	mov fp, r6                           @ 080B03F2
	mov ip, r7                           @ 080B03F4
	pop {r4, r5, r6, r7}                 @ 080B03F6
	pop {r1}                             @ 080B03F8
	bx r1                                @ 080B03FA

@ ------------------------------------------------------------------
@ snd_music_stop   ROM 0x080B03FC (Thumb)
@ API: free every music voice, no song playing.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_stop
snd_music_stop:
	push {r4, r5, r6, r7, lr}            @ 080B03FC
	mov r3, r8                           @ 080B03FE
	mov r4, sb                           @ 080B0400
	mov r5, sl                           @ 080B0402
	mov r6, fp                           @ 080B0404
	mov r7, ip                           @ 080B0406
	push {r3, r4, r5, r6, r7}            @ 080B0408
	bl init_music_voices                 @ 080B040A
	ldr r0, lit_80B04FC                  @ 080B040E  = seq_current_song
	movs r1, #0                          @ 080B0410
	mvns r1, r1                          @ 080B0412
	str r1, [r0]                         @ 080B0414
	pop {r3, r4, r5, r6, r7}             @ 080B0416
	mov r8, r3                           @ 080B0418
	mov sb, r4                           @ 080B041A
	mov sl, r5                           @ 080B041C
	mov fp, r6                           @ 080B041E
	mov ip, r7                           @ 080B0420
	pop {r4, r5, r6, r7}                 @ 080B0422
	pop {r1}                             @ 080B0424
	bx r1                                @ 080B0426

@ ------------------------------------------------------------------
@ snd_set_music_volume   ROM 0x080B0428 (Thumb)
@ API: r0 = music master volume (init 0x80).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_music_volume
snd_set_music_volume:
	ldr r1, lit_80B0500                  @ 080B0428  = music_master_volume
	str r0, [r1]                         @ 080B042A
	bx lr                                @ 080B042C

@ ------------------------------------------------------------------
@ snd_set_sfx_volume   ROM 0x080B042E (Thumb)
@ API: r0 = SFX master volume (init 0x80).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_sfx_volume
snd_set_sfx_volume:
	ldr r1, lit_80B0504                  @ 080B042E  = sfx_master_volume
	str r0, [r1]                         @ 080B0430
	bx lr                                @ 080B0432

@ ------------------------------------------------------------------
@ snd_get_tempo   ROM 0x080B0434 (Thumb)
@ API: r0 = current tempo (us per quarter note).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_get_tempo
snd_get_tempo:
	ldr r1, lit_80B0508                  @ 080B0434  = seq_tempo
	ldr r0, [r1]                         @ 080B0436
	bx lr                                @ 080B0438

@ ------------------------------------------------------------------
@ snd_set_tempo   ROM 0x080B043A (Thumb)
@ API: r0 = tempo (us per quarter note).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_tempo
snd_set_tempo:
	push {r4, r5, r6, r7, lr}            @ 080B043A
	mov r3, r8                           @ 080B043C
	mov r4, sb                           @ 080B043E
	mov r5, sl                           @ 080B0440
	mov r6, fp                           @ 080B0442
	mov r7, ip                           @ 080B0444
	push {r3, r4, r5, r6, r7}            @ 080B0446
	adds r1, r0, #0                      @ 080B0448
	mov r0, pc                           @ 080B044A
	adds r0, #7                          @ 080B044C
	mov lr, r0                           @ 080B044E
	ldr r0, lit_80B050C                  @ 080B0450  = (set_tempo_internal - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080B0452
L_80B0454:
	pop {r3, r4, r5, r6, r7}             @ 080B0454
	mov r8, r3                           @ 080B0456
	mov sb, r4                           @ 080B0458
	mov sl, r5                           @ 080B045A
	mov fp, r6                           @ 080B045C
	mov ip, r7                           @ 080B045E
	pop {r4, r5, r6, r7}                 @ 080B0460
	pop {r1}                             @ 080B0462
	bx r1                                @ 080B0464

@ ------------------------------------------------------------------
@ snd_music_pause   ROM 0x080B0466 (Thumb)
@ API: freeze the sequencer and music voices.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_pause
snd_music_pause:
	movs r1, #1                          @ 080B0466
	ldr r0, lit_80B0510                  @ 080B0468  = music_paused
	str r1, [r0]                         @ 080B046A
	bx lr                                @ 080B046C

@ ------------------------------------------------------------------
@ snd_music_resume   ROM 0x080B046E (Thumb)
@ API: undo snd_music_pause.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_resume
snd_music_resume:
	movs r1, #0                          @ 080B046E
	ldr r0, lit_80B0514                  @ 080B0470  = music_paused
	str r1, [r0]                         @ 080B0472
	bx lr                                @ 080B0474

@ ------------------------------------------------------------------
@ snd_sfx_release   ROM 0x080B0476 (Thumb)
@ API: r0 = handle. Key off (enters release).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_release
snd_sfx_release:
	push {r4, r5, r6, r7, lr}            @ 080B0476
	mov r3, r8                           @ 080B0478
	mov r4, sb                           @ 080B047A
	mov r5, sl                           @ 080B047C
	mov r6, fp                           @ 080B047E
	mov r7, ip                           @ 080B0480
	push {r3, r4, r5, r6, r7}            @ 080B0482
	bl sfx_find_handle                   @ 080B0484
	cmp r0, #0                           @ 080B0488
	beq L_80B0498                        @ 080B048A
	ldr r2, lit_80B0518                  @ 080B048C  = sfx_voices
	ldrb r1, [r2, r3]                    @ 080B048E
	cmp r1, #0x11                        @ 080B0490
	bne L_80B0498                        @ 080B0492
	movs r1, #0x12                       @ 080B0494
	strb r1, [r2, r3]                    @ 080B0496
L_80B0498:
	pop {r3, r4, r5, r6, r7}             @ 080B0498
	mov r8, r3                           @ 080B049A
	mov sb, r4                           @ 080B049C
	mov sl, r5                           @ 080B049E
	mov fp, r6                           @ 080B04A0
	mov ip, r7                           @ 080B04A2
	pop {r4, r5, r6, r7}                 @ 080B04A4
	pop {r1}                             @ 080B04A6
	bx r1                                @ 080B04A8

@ ------------------------------------------------------------------
@ snd_sfx_play   ROM 0x080B04AA (Thumb)
@ API: r0 = sfx id, r1 = volume (0 = do nothing), r2 = pitch mult (0x10000 = normal).
@ Returns handle (-1 if none).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_play
snd_sfx_play:
	movs r3, #0                          @ 080B04AA
	b sfx_play_common                    @ 080B04AC

@ ------------------------------------------------------------------
@ snd_sfx_play_timed   ROM 0x080B04AE (Thumb)
@ API: as snd_sfx_play, plus r3 = frames until automatic key-off (0 = never).
@ No callers in DKC1.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_play_timed
snd_sfx_play_timed:
	b sfx_play_common                    @ 080B04AE
lit_80B04B0:
	.word chan_mod-8
lit_80B04B4:
	.word chan_mod-4
lit_80B04B8:
	.word chan_instrument
lit_80B04BC:
	.word 0x00FFFFFF
lit_80B04C0:
	.word sfx_voices
lit_80B04C4:
	.word cfg_sfx_pool_bytes
lit_80B04C8:
	.word sfx_timer
lit_80B04CC:
	.word sfx_voices
lit_80B04D0:
	.word cfg_sfx_pool_bytes
lit_80B04D4:
	.word sfx_handle_counter
lit_80B04D8:
	.word sfx_handle
lit_80B04DC:
	.word sfx_table_ptr
lit_80B04E0:
	.word (voice_start - iwram_code_start + IWRAM_CODE_BASE)
lit_80B04E4:
	.word sfx_voices
lit_80B04E8:
	.word cfg_sfx_pool_bytes
lit_80B04EC:
	.word sfx_handle
lit_80B04F0:
	.word sfx_voices+0x24
lit_80B04F4:
	.word sfx_voices+0x3
lit_80B04F8:
	.word sfx_voices
lit_80B04FC:
	.word seq_current_song
lit_80B0500:
	.word music_master_volume
lit_80B0504:
	.word sfx_master_volume
lit_80B0508:
	.word seq_tempo
lit_80B050C:
	.word (set_tempo_internal - iwram_code_start + IWRAM_CODE_BASE)
lit_80B0510:
	.word music_paused
lit_80B0514:
	.word music_paused
lit_80B0518:
	.word sfx_voices

@ ------------------------------------------------------------------
@ sfx_play_common   ROM 0x080B051C (Thumb)
@ Shared body of snd_sfx_play / snd_sfx_play_timed: volume 0 -> return -1; else start
@ the voice and store r3 into sfx_timer[voice].
@ ------------------------------------------------------------------
	.thumb_func
sfx_play_common:
	cmp r1, #0                           @ 080B051C
	bne L_80B0528                        @ 080B051E
	movs r1, #0                          @ 080B0520
	mvns r1, r1                          @ 080B0522
	adds r0, r1, #0                      @ 080B0524
	bx lr                                @ 080B0526
L_80B0528:
	push {r4, r5, r6, r7, lr}            @ 080B0528
	mov lr, r3                           @ 080B052A
	mov r3, r8                           @ 080B052C
	mov r4, sb                           @ 080B052E
	mov r5, sl                           @ 080B0530
	mov r6, fp                           @ 080B0532
	mov r7, ip                           @ 080B0534
	push {r3, r4, r5, r6, r7}            @ 080B0536
	push {lr}                            @ 080B0538
	bl sfx_start_voice                   @ 080B053A
	pop {r3}                             @ 080B053E
	cmp r1, #0                           @ 080B0540
	bmi L_80B054A                        @ 080B0542
	ldr r5, lit_80B071C                  @ 080B0544  = sfx_timer
	lsls r6, r1, #2                      @ 080B0546
	str r3, [r5, r6]                     @ 080B0548
L_80B054A:
	pop {r3, r4, r5, r6, r7}             @ 080B054A
	mov r8, r3                           @ 080B054C
	mov sb, r4                           @ 080B054E
	mov sl, r5                           @ 080B0550
	mov fp, r6                           @ 080B0552
	mov ip, r7                           @ 080B0554
	pop {r4, r5, r6, r7}                 @ 080B0556
	pop {r1}                             @ 080B0558
	bx r1                                @ 080B055A
	.hword 0x4A70

@ ------------------------------------------------------------------
@ snd_shutdown   ROM 0x080B055E (Thumb)
@ API: stop DMA1 and switch the APU off.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_shutdown
snd_shutdown:
	ldr r0, lit_80B0724                  @ 080B055E  = REG_DMA1DAD
	str r2, [r0]                         @ 080B0560
	ldr r0, lit_80B0728                  @ 080B0562  = REG_DMA1SAD
	str r1, [r0]                         @ 080B0564
	ldr r0, lit_80B072C                  @ 080B0566  = REG_DMA1CNT_L
	ldr r2, lit_80B0730                  @ 080B0568  = 0x84400004
	str r2, [r0]                         @ 080B056A
	ldr r2, lit_80B0734                  @ 080B056C  = 0x04400000
	adds r0, #2                          @ 080B056E
	strh r2, [r0]                        @ 080B0570
	ldr r0, lit_80B0738                  @ 080B0572  = REG_SOUNDCNT_X
	movs r1, #0                          @ 080B0574
	strh r1, [r0]                        @ 080B0576
	bx lr                                @ 080B0578

@ ------------------------------------------------------------------
@ snd_set_mix_rate   ROM 0x080B057A (Thumb)
@ API: r0 = Hz. Above 13379 -> r0 = -1. 10512 / 13379 set Timer 0, samples per frame and the
@ pitch scale and return 0. BUG: any other value <= 13379 falls through to the 21024 Hz
@ settings (352 samples/frame), overrunning the 224-sample mix_buffer.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_mix_rate
snd_set_mix_rate:
	push {r4, r5, r6, r7, lr}            @ 080B057A
	mov r3, r8                           @ 080B057C
	mov r4, sb                           @ 080B057E
	mov r5, sl                           @ 080B0580
	mov r6, fp                           @ 080B0582
	mov r7, ip                           @ 080B0584
	push {r3, r4, r5, r6, r7}            @ 080B0586
	ldr r1, lit_80B073C                  @ 080B0588  = 0x00003443
	cmp r0, r1                           @ 080B058A
	ble L_80B0594                        @ 080B058C
	movs r0, #0                          @ 080B058E
	mvns r0, r0                          @ 080B0590
	b L_80B05E2                          @ 080B0592
L_80B0594:
	ldr r1, lit_80B0740                  @ 080B0594  = mix_rate_hz
	str r0, [r1]                         @ 080B0596
	ldr r1, lit_80B0744                  @ 080B0598  = 0x00002910
	ldr r2, lit_80B0748                  @ 080B059A  = 0xFFFFF9C4
	ldr r3, lit_80B074C                  @ 080B059C  = 0x018F0064
	movs r4, #0xb0                       @ 080B059E
	cmp r0, r1                           @ 080B05A0
	beq L_80B05C8                        @ 080B05A2
	ldr r1, lit_80B073C                  @ 080B05A4  = 0x00003443
	ldr r2, lit_80B0750                  @ 080B05A6  = 0xFFFFFB1A
	ldr r3, lit_80B0754                  @ 080B05A8  = 0x01397FC3
	movs r4, #0xe0                       @ 080B05AA
	cmp r0, r1                           @ 080B05AC
	beq L_80B05C8                        @ 080B05AE
	ldr r1, lit_80B0758                  @ 080B05B0  = 0x000046ED
	ldr r2, lit_80B075C                  @ 080B05B2  = 0xFFFFFC64
	ldr r3, lit_80B0760                  @ 080B05B4  = 0x00E70086
	ldr r4, lit_80B0764                  @ 080B05B6  = 0x00000130
	cmp r0, r1                           @ 080B05B8
	beq L_80B05C8                        @ 080B05BA
	ldr r1, lit_80B0768                  @ 080B05BC  = 0x00005220
	ldr r2, lit_80B076C                  @ 080B05BE  = 0xFFFFFCE2
	ldr r3, lit_80B0770                  @ 080B05C0  = 0x00C78032
	ldr r4, lit_80B0774                  @ 080B05C2  = 0x00000160
	cmp r0, r1                           @ 080B05C4
	beq L_80B05C8                        @ 080B05C6
L_80B05C8:
	ldr r7, lit_80B0778                  @ 080B05C8  = mix_timer_reload
	str r2, [r7]                         @ 080B05CA
	ldr r7, lit_80B077C                  @ 080B05CC  = mix_pitch_scale
	str r3, [r7]                         @ 080B05CE
	ldr r7, lit_80B0780                  @ 080B05D0  = mix_samples_per_frame
	str r4, [r7]                         @ 080B05D2
	ldr r0, lit_80B0784                  @ 080B05D4  = REG_TM0CNT_L
	ldr r1, lit_80B0788                  @ 080B05D6  = mix_timer_reload
	ldr r1, [r1]                         @ 080B05D8
	strh r1, [r0]                        @ 080B05DA
	movs r1, #0x80                       @ 080B05DC
	strh r1, [r0, #2]                    @ 080B05DE
	movs r0, #0                          @ 080B05E0
L_80B05E2:
	pop {r3, r4, r5, r6, r7}             @ 080B05E2
	mov r8, r3                           @ 080B05E4
	mov sb, r4                           @ 080B05E6
	mov sl, r5                           @ 080B05E8
	mov fp, r6                           @ 080B05EA
	mov ip, r7                           @ 080B05EC
	pop {r4, r5, r6, r7}                 @ 080B05EE
	pop {r1}                             @ 080B05F0
	bx r1                                @ 080B05F2

@ ------------------------------------------------------------------
@ snd_get_song   ROM 0x080B05F4 (Thumb)
@ API: r0 = current song, -1 = none / finished.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_get_song
snd_get_song:
	ldr r0, lit_80B078C                  @ 080B05F4  = seq_current_song
	ldr r0, [r0]                         @ 080B05F6
	bx lr                                @ 080B05F8

@ ------------------------------------------------------------------
@ snd_set_max_voices   ROM 0x080B05FA (Thumb)
@ API: r0 = number of voices mixed per frame (init 8).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_max_voices
snd_set_max_voices:
	ldr r1, lit_80B0790                  @ 080B05FA  = mix_max_voices
	str r0, [r1]                         @ 080B05FC
	bx lr                                @ 080B05FE

@ ------------------------------------------------------------------
@ wait_vcount_160   ROM 0x080B0600 (Thumb)
@ Busy-wait for the start of V-blank (VCOUNT 160).
@ ------------------------------------------------------------------
	.thumb_func
wait_vcount_160:
	ldr r0, lit_80B0794                  @ 080B0600  = REG_VCOUNT
L_80B0602:
	ldrb r1, [r0]                        @ 080B0602
	cmp r1, #0xa0                        @ 080B0604
	beq L_80B0602                        @ 080B0606
L_80B0608:
	ldrb r1, [r0]                        @ 080B0608
	cmp r1, #0xa0                        @ 080B060A
	bne L_80B0608                        @ 080B060C
	mov pc, lr                           @ 080B060E

@ ------------------------------------------------------------------
@ reset_pitch_bend   ROM 0x080B0610 (Thumb)
@ All 16 chan_bend = 0x2000.
@ ------------------------------------------------------------------
	.thumb_func
reset_pitch_bend:
	movs r1, #0x20                       @ 080B0610
	lsls r1, r1, #8                      @ 080B0612
	ldr r0, lit_80B0798                  @ 080B0614  = chan_bend
	movs r2, #0x40                       @ 080B0616
L_80B0618:
	subs r2, #4                          @ 080B0618
	str r1, [r0, r2]                     @ 080B061A
	bne L_80B0618                        @ 080B061C
	bx lr                                @ 080B061E

@ ------------------------------------------------------------------
@ reset_modulation   ROM 0x080B0620 (Thumb)
@ All 16 chan_mod = {0, 0}.
@ ------------------------------------------------------------------
	.thumb_func
reset_modulation:
	movs r1, #0                          @ 080B0620
	ldr r0, lit_80B079C                  @ 080B0622  = chan_mod
	movs r2, #0x80                       @ 080B0624
L_80B0626:
	subs r2, #8                          @ 080B0626
	str r1, [r0, r2]                     @ 080B0628
	bne L_80B0626                        @ 080B062A
	bx lr                                @ 080B062C

@ ------------------------------------------------------------------
@ clear_mix_buffer   ROM 0x080B062E (Thumb)
@ Zero mix_samples_per_frame s16 samples (176/224/304/352 via fall-through stm runs).
@ At 304/352 this overruns the 448-byte mix_buffer.
@ ------------------------------------------------------------------
	.thumb_func
clear_mix_buffer:
	movs r1, #0                          @ 080B062E
	movs r2, #0                          @ 080B0630
	movs r3, #0                          @ 080B0632
	movs r4, #0                          @ 080B0634
	movs r5, #0                          @ 080B0636
	movs r6, #0                          @ 080B0638
	ldr r0, lit_80B07A0                  @ 080B063A  = mix_buffer
	ldr r7, lit_80B07A4                  @ 080B063C  = mix_samples_per_frame
	ldr r7, [r7]                         @ 080B063E
	lsrs r7, r7, #1                      @ 080B0640
	cmp r7, #0x58                        @ 080B0642
	beq L_80B0652                        @ 080B0644
	cmp r7, #0x70                        @ 080B0646
	beq L_80B067C                        @ 080B0648
	cmp r7, #0x98                        @ 080B064A
	beq L_80B066E                        @ 080B064C
	cmp r7, #0xb0                        @ 080B064E
	beq L_80B0664                        @ 080B0650
L_80B0652:
	movs r7, #0                          @ 080B0652
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0654
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0656
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0658
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B065A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B065C
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B065E
	stm r0!, {r1, r2}                    @ 080B0660
	b L_80B069E                          @ 080B0662
L_80B0664:
	movs r7, #0                          @ 080B0664
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0666
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0668
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B066A
	stm r0!, {r1, r2, r3}                @ 080B066C
L_80B066E:
	movs r7, #0                          @ 080B066E
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0670
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0672
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0674
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0676
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0678
	stm r0!, {r1, r2, r3, r4, r5}        @ 080B067A
L_80B067C:
	movs r7, #0                          @ 080B067C
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B067E
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0680
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0682
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0684
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0686
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0688
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B068A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B068C
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B068E
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0690
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0692
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0694
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0696
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B0698
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B069A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080B069C
L_80B069E:
	bx lr                                @ 080B069E

@ ------------------------------------------------------------------
@ reset_adsr_override   ROM 0x080B06A0 (Thumb)
@ DKC3: all 16 chan_adsr_override = 0xFFFFFFFF (use instrument ADSR).
@ ------------------------------------------------------------------
	.thumb_func
reset_adsr_override:
	ldr r0, lit_80B07A8                  @ 080B06A0  = chan_adsr_override-4
	movs r1, #0x40                       @ 080B06A2
	movs r2, #0                          @ 080B06A4
	mvns r2, r2                          @ 080B06A6
L_80B06A8:
	str r2, [r0, r1]                     @ 080B06A8
	subs r1, #4                          @ 080B06AA
	bne L_80B06A8                        @ 080B06AC
	bx lr                                @ 080B06AE

@ ------------------------------------------------------------------
@ init_music_voices   ROM 0x080B06B0 (Thumb)
@ 96 music voices = 16 MIDI channels x 6; voice+6 = owning channel.
@ ------------------------------------------------------------------
	.thumb_func
init_music_voices:
	ldr r0, lit_80B07AC                  @ 080B06B0  = music_voices
	ldr r3, lit_80B07B0                  @ 080B06B2  = music_voices+0x6
	ldr r6, lit_80B07B4                  @ 080B06B4  = music_voices+0x8
	movs r7, #0                          @ 080B06B6
	movs r4, #1                          @ 080B06B8
	movs r5, #0x10                       @ 080B06BA
	movs r1, #0x10                       @ 080B06BC
	ldr r2, lit_80B07B8                  @ 080B06BE  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 080B06C0
L_80B06C2:
	subs r4, #1                          @ 080B06C2
	bne L_80B06CC                        @ 080B06C4
	subs r5, #1                          @ 080B06C6
	ldr r4, lit_80B07BC                  @ 080B06C8  = cfg_voices_per_chan
	ldr r4, [r4]                         @ 080B06CA
L_80B06CC:
	subs r2, #0x28                       @ 080B06CC
	strb r1, [r0, r2]                    @ 080B06CE
	strb r5, [r3, r2]                    @ 080B06D0
	str r7, [r6, r2]                     @ 080B06D2
	bne L_80B06C2                        @ 080B06D4
	bx lr                                @ 080B06D6

@ ------------------------------------------------------------------
@ init_sfx_voices   ROM 0x080B06D8 (Thumb)
@ 5 SFX voices, channel byte = -1.
@ ------------------------------------------------------------------
	.thumb_func
init_sfx_voices:
	ldr r0, lit_80B07C0                  @ 080B06D8  = sfx_voices
	movs r5, #0                          @ 080B06DA
	mvns r5, r5                          @ 080B06DC
	ldr r1, lit_80B07C4                  @ 080B06DE  = cfg_sfx_voices
	ldr r1, [r1]                         @ 080B06E0
	movs r2, #0x10                       @ 080B06E2
L_80B06E4:
	strb r2, [r0]                        @ 080B06E4
	strb r5, [r0, #6]                    @ 080B06E6
	adds r0, #0x28                       @ 080B06E8
	subs r1, #1                          @ 080B06EA
	bne L_80B06E4                        @ 080B06EC
	bx lr                                @ 080B06EE

@ ------------------------------------------------------------------
@ reset_channel_volume   ROM 0x080B06F0 (Thumb)
@ All 16 chan_volume = 127.
@ ------------------------------------------------------------------
	.thumb_func
reset_channel_volume:
	ldr r0, lit_80B07C8                  @ 080B06F0  = chan_volume
	movs r1, #0x10                       @ 080B06F2
	movs r2, #0x7f                       @ 080B06F4
L_80B06F6:
	subs r1, #1                          @ 080B06F6
	strb r2, [r0, r1]                    @ 080B06F8
	bne L_80B06F6                        @ 080B06FA
	bx lr                                @ 080B06FC

@ ------------------------------------------------------------------
@ reset_channel_gain   ROM 0x080B06FE (Thumb)
@ DKC3: all 16 chan_gain = 0x80.
@ ------------------------------------------------------------------
	.thumb_func
reset_channel_gain:
	ldr r0, lit_80B07CC                  @ 080B06FE  = chan_gain
	movs r1, #0x10                       @ 080B0700
	movs r2, #0x80                       @ 080B0702
L_80B0704:
	subs r1, #1                          @ 080B0704
	strb r2, [r0, r1]                    @ 080B0706
	bne L_80B0704                        @ 080B0708
	bx lr                                @ 080B070A

@ ------------------------------------------------------------------
@ reset_mono_flags   ROM 0x080B070C (Thumb)
@ All 16 chan_mono = 0 (poly).
@ ------------------------------------------------------------------
	.thumb_func
reset_mono_flags:
	ldr r0, lit_80B07D0                  @ 080B070C  = chan_mono
	movs r1, #0x10                       @ 080B070E
	movs r2, #0                          @ 080B0710
L_80B0712:
	subs r1, #1                          @ 080B0712
	strb r2, [r0, r1]                    @ 080B0714
	bne L_80B0712                        @ 080B0716
	bx lr                                @ 080B0718
	.hword 0x0000
lit_80B071C:
	.word sfx_timer
	.hword 0x00A0
	.hword 0x0400
lit_80B0724:
	.word REG_DMA1DAD
lit_80B0728:
	.word REG_DMA1SAD
lit_80B072C:
	.word REG_DMA1CNT_L
lit_80B0730:
	.word 0x84400004
lit_80B0734:
	.word 0x04400000
lit_80B0738:
	.word REG_SOUNDCNT_X
lit_80B073C:
	.word 0x00003443
lit_80B0740:
	.word mix_rate_hz
lit_80B0744:
	.word 0x00002910
lit_80B0748:
	.word 0xFFFFF9C4
lit_80B074C:
	.word 0x018F0064
lit_80B0750:
	.word 0xFFFFFB1A
lit_80B0754:
	.word 0x01397FC3
lit_80B0758:
	.word 0x000046ED
lit_80B075C:
	.word 0xFFFFFC64
lit_80B0760:
	.word 0x00E70086
lit_80B0764:
	.word 0x00000130
lit_80B0768:
	.word 0x00005220
lit_80B076C:
	.word 0xFFFFFCE2
lit_80B0770:
	.word 0x00C78032
lit_80B0774:
	.word 0x00000160
lit_80B0778:
	.word mix_timer_reload
lit_80B077C:
	.word mix_pitch_scale
lit_80B0780:
	.word mix_samples_per_frame
lit_80B0784:
	.word REG_TM0CNT_L
lit_80B0788:
	.word mix_timer_reload
lit_80B078C:
	.word seq_current_song
lit_80B0790:
	.word mix_max_voices
lit_80B0794:
	.word REG_VCOUNT
lit_80B0798:
	.word chan_bend
lit_80B079C:
	.word chan_mod
lit_80B07A0:
	.word mix_buffer
lit_80B07A4:
	.word mix_samples_per_frame
lit_80B07A8:
	.word chan_adsr_override-4
lit_80B07AC:
	.word music_voices
lit_80B07B0:
	.word music_voices+0x6
lit_80B07B4:
	.word music_voices+0x8
lit_80B07B8:
	.word cfg_music_pool_bytes
lit_80B07BC:
	.word cfg_voices_per_chan
lit_80B07C0:
	.word sfx_voices
lit_80B07C4:
	.word cfg_sfx_voices
lit_80B07C8:
	.word chan_volume
lit_80B07CC:
	.word chan_gain
lit_80B07D0:
	.word chan_mono

@ ------------------------------------------------------------------
@ seek_start_marker   ROM 0x080B07D4 (Thumb)
@ DKC3: if seq_start_marker >= 0, advance every track except track 0 to the event after
@ CC104 = marker, recording CC102 loop starts on the way (uses event_length_table).
@ An END before the marker returns ('could not find startpoint' assert compiled out).
@ ------------------------------------------------------------------
	.thumb_func
seek_start_marker:
	ldr r0, lit_80B0844                  @ 080B07D4  = seq_start_marker
	ldr r1, [r0]                         @ 080B07D6
	ldr r0, lit_80B0848                  @ 080B07D8  = seq_track_ptr+0x4
	ldr r2, lit_80B084C                  @ 080B07DA  = seq_num_tracks
	ldr r3, [r2]                         @ 080B07DC
	subs r2, r3, #1                      @ 080B07DE
	ldr r4, lit_80B0850                  @ 080B07E0  = event_length_table
	movs r6, #0xb                        @ 080B07E2
	mov sl, r6                           @ 080B07E4
	movs r6, #7                          @ 080B07E6
	mov fp, r6                           @ 080B07E8
	movs r6, #0x68                       @ 080B07EA
	mov sb, r6                           @ 080B07EC
	movs r6, #0x66                       @ 080B07EE
	mov ip, r6                           @ 080B07F0
	movs r7, #0xf0                       @ 080B07F2
L_80B07F4:
	ldr r3, [r0]                         @ 080B07F4
L_80B07F6:
	ldrb r5, [r3]                        @ 080B07F6
	bics r5, r7                          @ 080B07F8
	cmp sl, r5                           @ 080B07FA
	beq L_80B0808                        @ 080B07FC
	cmp fp, r5                           @ 080B07FE
	beq L_80B080A                        @ 080B0800
	ldrb r5, [r4, r5]                    @ 080B0802
	adds r3, r3, r5                      @ 080B0804
	b L_80B07F6                          @ 080B0806
L_80B0808:
	bx lr                                @ 080B0808
L_80B080A:
	adds r3, #1                          @ 080B080A
	ldrb r5, [r3]                        @ 080B080C
	adds r3, #1                          @ 080B080E
	ldrb r6, [r3]                        @ 080B0810
	adds r3, #1                          @ 080B0812
	cmp ip, r5                           @ 080B0814
	beq L_80B082A                        @ 080B0816
	cmp sb, r5                           @ 080B0818
	bne L_80B07F6                        @ 080B081A
	cmp r6, r1                           @ 080B081C
	bne L_80B07F6                        @ 080B081E
	str r3, [r0]                         @ 080B0820
	adds r0, #4                          @ 080B0822
	subs r2, #1                          @ 080B0824
	bne L_80B07F4                        @ 080B0826
	bx lr                                @ 080B0828
L_80B082A:
	ldr r6, lit_80B0854                  @ 080B082A  = seq_track_ptr
	subs r6, r0, r6                      @ 080B082C
	ldr r5, lit_80B0858                  @ 080B082E  = seq_loop_ptr
	str r3, [r5, r6]                     @ 080B0830
	b L_80B07F6                          @ 080B0832

@ event_length_table: DKC3: 13 x u8 event lengths by command nibble, +3 pad
event_length_table:
	.hword 0x0204
	.hword 0x0403
	.hword 0x0305
	.hword 0x0303
	.hword 0x0302
	.hword 0x0103
	.hword 0x0001
	.hword 0x0000
lit_80B0844:
	.word seq_start_marker
lit_80B0848:
	.word seq_track_ptr+0x4
lit_80B084C:
	.word seq_num_tracks
lit_80B0850:
	.word event_length_table
lit_80B0854:
	.word seq_track_ptr
lit_80B0858:
	.word seq_loop_ptr

@ pitch_table: 128 x u32: 2^((n-64)/12) in 9.23 fixed point; index 64 = 1.0
pitch_table:
	.word 0x00032CC0, 0x00035D14, 0x00039048, 0x0003C687
	.word 0x00040000, 0x00043CE4, 0x00047D67, 0x0004C1C0
	.word 0x00050A29, 0x000556E0, 0x0005A828, 0x0005FE44
	.word 0x00065980, 0x0006BA28, 0x00072090, 0x00078D0E
	.word 0x00080000, 0x000879C8, 0x0008FACD, 0x0009837F
	.word 0x000A1451, 0x000AADC1, 0x000B504F, 0x000BFC88
	.word 0x000CB2FF, 0x000D7450, 0x000E411F, 0x000F1A1C
	.word 0x00100000, 0x0010F390, 0x0011F59B, 0x001306FE
	.word 0x001428A3, 0x00155B81, 0x0016A09E, 0x0017F911
	.word 0x001965FF, 0x001AE8A0, 0x001C823E, 0x001E3438
	.word 0x00200000, 0x0021E71F, 0x0023EB36, 0x00260DFC
	.word 0x00285146, 0x002AB702, 0x002D413D, 0x002FF222
	.word 0x0032CBFD, 0x0035D13F, 0x0039047C, 0x003C6870
	.word 0x00400000, 0x0043CE3E, 0x0047D66B, 0x004C1BF8
	.word 0x0050A28C, 0x00556E04, 0x005A827A, 0x005FE443
	.word 0x006597FB, 0x006BA27E, 0x007208F8, 0x0078D0E0
	.word 0x00800000, 0x00879C7D, 0x008FACD6, 0x009837F0
	.word 0x00A14518, 0x00AADC08, 0x00B504F3, 0x00BFC887
	.word 0x00CB2FF5, 0x00D744FD, 0x00E411F0, 0x00F1A1BF
	.word 0x01000000, 0x010F38F9, 0x011F59AC, 0x01306FE1
	.word 0x01428A30, 0x0155B811, 0x016A09E6, 0x017F910D
	.word 0x01965FEA, 0x01AE89FA, 0x01C823E0, 0x01E3437E
	.word 0x02000000, 0x021E71F2, 0x023EB358, 0x0260DFC1
	.word 0x0285145F, 0x02AB7021, 0x02D413CD, 0x02FF221B
	.word 0x032CBFD5, 0x035D13F3, 0x039047C1, 0x03C686FD
	.word 0x04000000, 0x043CE3E5, 0x047D66B1, 0x04C1BF83
	.word 0x050A28BE, 0x0556E042, 0x05A8279A, 0x05FE4436
	.word 0x06597FA9, 0x06BA27E6, 0x07208F82, 0x078D0DFA
	.word 0x08000000, 0x0879C7C9, 0x08FACD62, 0x09837F05
	.word 0x0A14517D, 0x0AADC084, 0x0B504F33, 0x0BFC886C
	.word 0x0CB2FF53, 0x0D744FCD, 0x0E411F04, 0x0F1A1BF4
	.word 0x10000000, 0x10F38F93, 0x11F59AC4, 0x1306FE0A

@ adsr_rate_table: 100 x u8: frames for decay/release rate 0-99 (0 = slowest, 99 = instant)
adsr_rate_table:
	.byte 254, 230, 154, 154, 132, 132, 116, 102, 107,  92
	.byte  88,  85,  81,  78,  75,  72,  68,  63,  61,  60
	.byte  57,  54,  53,  52,  51,  50,  48,  46,  44,  43
	.byte  42,  40,  39,  38,  37,  36,  35,  34,  33,  32
	.byte  31,  31,  30,  29,  28,  28,  27,  26,  25,  24
	.byte  24,  23,  23,  22,  22,  21,  21,  21,  20,  20
	.byte  19,  19,  18,  18,  17,  17,  16,  16,  15,  15
	.byte  15,  14,  14,  14,  13,  13,  12,  12,  12,  11
	.byte  11,  10,  10,  10,   9,   9,   9,   8,   8,   8
	.byte   7,   7,   6,   6,   5,   4,   3,   2,   1,   0

@ lfo_sine_table: 257 x s32: sine, peak 0x51EB8 = 2^32/12800 (1 cent x 128)
lfo_sine_table:
	.word 0x00000000, 0x0000202A, 0x00004050, 0x0000606C
	.word 0x00008079, 0x0000A072, 0x0000C052, 0x0000E015
	.word 0x0000FFB5, 0x00011F2E, 0x00013E7A, 0x00015D95
	.word 0x00017C7B, 0x00019B26, 0x0001B991, 0x0001D7B8
	.word 0x0001F597, 0x00021328, 0x00023067, 0x00024D50
	.word 0x000269DE, 0x0002860D, 0x0002A1D8, 0x0002BD3B
	.word 0x0002D832, 0x0002F2B9, 0x00030CCB, 0x00032665
	.word 0x00033F83, 0x00035820, 0x00037039, 0x000387CB
	.word 0x00039ED1, 0x0003B548, 0x0003CB2D, 0x0003E07D
	.word 0x0003F533, 0x0004094D, 0x00041CC7, 0x00042F9F
	.word 0x000441D2, 0x0004535D, 0x0004643D, 0x00047470
	.word 0x000483F3, 0x000492C4, 0x0004A0E0, 0x0004AE45
	.word 0x0004BAF2, 0x0004C6E4, 0x0004D219, 0x0004DC90
	.word 0x0004E647, 0x0004EF3D, 0x0004F770, 0x0004FEDF
	.word 0x00050588, 0x00050B6C, 0x00051088, 0x000514DC
	.word 0x00051868, 0x00051B2B, 0x00051D24, 0x00051E53
	.word 0x00051EB8, 0x00051E53, 0x00051D24, 0x00051B2B
	.word 0x00051868, 0x000514DC, 0x00051088, 0x00050B6C
	.word 0x00050588, 0x0004FEDF, 0x0004F770, 0x0004EF3D
	.word 0x0004E647, 0x0004DC90, 0x0004D219, 0x0004C6E4
	.word 0x0004BAF2, 0x0004AE45, 0x0004A0E0, 0x000492C4
	.word 0x000483F3, 0x00047470, 0x0004643D, 0x0004535D
	.word 0x000441D2, 0x00042F9F, 0x00041CC7, 0x0004094D
	.word 0x0003F533, 0x0003E07D, 0x0003CB2D, 0x0003B548
	.word 0x00039ED1, 0x000387CB, 0x00037039, 0x00035820
	.word 0x00033F83, 0x00032665, 0x00030CCB, 0x0002F2B9
	.word 0x0002D832, 0x0002BD3B, 0x0002A1D8, 0x0002860D
	.word 0x000269DE, 0x00024D50, 0x00023067, 0x00021328
	.word 0x0001F597, 0x0001D7B8, 0x0001B991, 0x00019B26
	.word 0x00017C7B, 0x00015D95, 0x00013E7A, 0x00011F2E
	.word 0x0000FFB5, 0x0000E015, 0x0000C052, 0x0000A072
	.word 0x00008079, 0x0000606C, 0x00004050, 0x0000202A
	.word 0x00000000, 0xFFFFDFD6, 0xFFFFBFB0, 0xFFFF9F94
	.word 0xFFFF7F87, 0xFFFF5F8E, 0xFFFF3FAE, 0xFFFF1FEB
	.word 0xFFFF004B, 0xFFFEE0D2, 0xFFFEC186, 0xFFFEA26B
	.word 0xFFFE8385, 0xFFFE64DA, 0xFFFE466F, 0xFFFE2848
	.word 0xFFFE0A69, 0xFFFDECD8, 0xFFFDCF99, 0xFFFDB2B0
	.word 0xFFFD9622, 0xFFFD79F3, 0xFFFD5E28, 0xFFFD42C5
	.word 0xFFFD27CE, 0xFFFD0D47, 0xFFFCF335, 0xFFFCD99B
	.word 0xFFFCC07D, 0xFFFCA7E0, 0xFFFC8FC7, 0xFFFC7835
	.word 0xFFFC612F, 0xFFFC4AB8, 0xFFFC34D3, 0xFFFC1F83
	.word 0xFFFC0ACD, 0xFFFBF6B3, 0xFFFBE339, 0xFFFBD061
	.word 0xFFFBBE2E, 0xFFFBACA3, 0xFFFB9BC3, 0xFFFB8B90
	.word 0xFFFB7C0D, 0xFFFB6D3C, 0xFFFB5F20, 0xFFFB51BB
	.word 0xFFFB450E, 0xFFFB391C, 0xFFFB2DE7, 0xFFFB2370
	.word 0xFFFB19B9, 0xFFFB10C3, 0xFFFB0890, 0xFFFB0121
	.word 0xFFFAFA78, 0xFFFAF494, 0xFFFAEF78, 0xFFFAEB24
	.word 0xFFFAE798, 0xFFFAE4D5, 0xFFFAE2DC, 0xFFFAE1AD
	.word 0xFFFAE148, 0xFFFAE1AD, 0xFFFAE2DC, 0xFFFAE4D5
	.word 0xFFFAE798, 0xFFFAEB24, 0xFFFAEF78, 0xFFFAF494
	.word 0xFFFAFA78, 0xFFFB0121, 0xFFFB0890, 0xFFFB10C3
	.word 0xFFFB19B9, 0xFFFB2370, 0xFFFB2DE7, 0xFFFB391C
	.word 0xFFFB450E, 0xFFFB51BB, 0xFFFB5F20, 0xFFFB6D3C
	.word 0xFFFB7C0D, 0xFFFB8B90, 0xFFFB9BC3, 0xFFFBACA3
	.word 0xFFFBBE2E, 0xFFFBD061, 0xFFFBE339, 0xFFFBF6B3
	.word 0xFFFC0ACD, 0xFFFC1F83, 0xFFFC34D3, 0xFFFC4AB8
	.word 0xFFFC612F, 0xFFFC7835, 0xFFFC8FC7, 0xFFFCA7E0
	.word 0xFFFCC07D, 0xFFFCD99B, 0xFFFCF335, 0xFFFD0D47
	.word 0xFFFD27CE, 0xFFFD42C5, 0xFFFD5E28, 0xFFFD79F3
	.word 0xFFFD9622, 0xFFFDB2B0, 0xFFFDCF99, 0xFFFDECD8
	.word 0xFFFE0A69, 0xFFFE2848, 0xFFFE466F, 0xFFFE64DA
	.word 0xFFFE8385, 0xFFFEA26B, 0xFFFEC186, 0xFFFEE0D2
	.word 0xFFFF004B, 0xFFFF1FEB, 0xFFFF3FAE, 0xFFFF5F8E
	.word 0xFFFF7F87, 0xFFFF9F94, 0xFFFFBFB0, 0xFFFFDFD6
	.word 0x00000000

@ error_strings: Debug assert messages; unreferenced in this release build
error_strings:
	.asciz "AUDIO ERROR, freq of sample unusually high. (>3 times normal)\n"
	.asciz "AUDIO ERROR, pitch frequency too low\n"
	.asciz "AUDIO ERROR, pitch frequency too high\n"
	.asciz "AUDIO ERROR, adsr_acts table exceeded\n"
	.asciz "AUDIO ERROR, midi_command table exceeded\n"
	.asciz "AUDIO ERROR, midi delta time too big\n"
	.asciz "AUDIO ERROR, midi delta time of 4 bytes unsupported\n"
	.asciz "AUDIO ERROR, too many notes on channel 0.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 1.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 2.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 3.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 4.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 5.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 6.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 7.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 8.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 9.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 10.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 11.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 12.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 13.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 14.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, too many notes on channel 15.increase polyphony RAM\n           or modify tune (perhaps reduce envelope release times)\n"
	.asciz "AUDIO ERROR, not enough space to put audio RAM code\n"
	.asciz "AUDIO ERROR, more than 16 tracks in song\n"
	.asciz "AUDIO ERROR, tune num > max tunes available\n"
	.asciz "AUDIO ERROR, MIDI note on command before MIDI prog chng command\n"
	.asciz "AUDIO ERROR, requested playback freq exceeds max freq\n"
	.asciz "AUDIO ERROR, incorrect note mapping for rhythm_set\n"
	.asciz "AUDIO ERROR, incorrect note mapping for keysplit\n"
	.asciz "AUDIO ERROR, invalid fx number\n"
	.asciz "AUDIO ERROR, invalid tune number\n"
	.asciz "AUDIO ERROR, could not find startpoint\n"
	.byte 0
	.byte 0

