@ ==========================================================================
@ Rare GBA sound driver (Donkey Kong Country, Europe, A5NP) - reconstructed source
@ ROM 0x08031BC4-0x08034630. Assembles byte-identical with:
@   arm-none-eabi-as -mcpu=arm7tdmi -o dkc1_sound.o dkc1_sound.s
@   arm-none-eabi-ld -Ttext=0x08031BC4 -o dkc1_sound.elf dkc1_sound.o
@   arm-none-eabi-objcopy -O binary dkc1_sound.elf dkc1_sound.bin
@ The ARM block (iwram_code_start..iwram_code_end) is copied to IWRAM 0x03002B40
@ by snd_init and runs there; (x - iwram_code_start + IWRAM_CODE_BASE) is the run-time address.
@ Labels, names and comments are reverse-engineered, not original symbols.
@ ==========================================================================
	.syntax unified
	.cpu arm7tdmi
	.text

	.equ IWRAM_CODE_BASE, 0x03002B40

@ ---- hardware registers ----
	.equ REG_VCOUNT,            0x04000006
	.equ REG_SOUNDCNT_H,        0x04000082
	.equ REG_SOUNDCNT_X,        0x04000084
	.equ REG_SOUNDBIAS_H,       0x04000089
	.equ REG_FIFO_A,            0x040000A0
	.equ REG_DMA1SAD,           0x040000BC
	.equ REG_DMA1CNT_H,         0x040000C6
	.equ REG_DMA2SAD,           0x040000C8
	.equ REG_TM0CNT_L,          0x04000100
	.equ REG_TM0CNT_H,          0x04000102
@ ---- constants ----
	.equ USEC_PER_MINUTE,       0x03938700
@ ---- game data outside the driver ----
	.equ cfg_buffer_a,          0x0809BD5C   @ ptr -> 8-bit output buffer A (0x03002570)
	.equ cfg_buffer_a2,         0x0809BD60   @ unused
	.equ cfg_buffer_b,          0x0809BD64   @ ptr -> 8-bit output buffer B (0x03002730)
	.equ cfg_buffer_b2,         0x0809BD68   @ unused
	.equ cfg_music_pool_bytes,  0x0809BD6C   @ 0xF00 = 96 voices
	.equ cfg_chan_pool_bytes,   0x0809BD70   @ 0xF0 = 6 voices per channel
	.equ cfg_sfx_pool_bytes,    0x0809BD74   @ 0xC8 = 5 voices
	.equ cfg_sfx_voices,        0x0809BD78   @ 5
	.equ cfg_voices_per_chan,   0x0809BD80   @ 6
	.equ sfx_table,             0x08562294   @ 245 sample-instrument pointers
	.equ song_table,            0x08562668   @ 39 song header pointers
@ ---- IWRAM variables ----
	.equ seq_num_tracks,        0x03001410   @ tracks in current song
	.equ mix_samples_per_frame, 0x03001414   @ 176/224/304/352
	.equ mix_timer_reload,      0x03001418   @ Timer 0 reload
	.equ seq_prog_map_ptr,      0x0300141C   @ song+0x0C: 128-byte program -> instrument index map
	.equ seq_current_song,      0x03001420   @ -1 = none
	.equ seq_loop_ptr,          0x03001430   @ [16] track pointer saved by CC102
	.equ chan_mod,              0x03001470   @ [16] {u32 mod wheel (CC1), u32 LFO phase (24-bit)}
	.equ sfx_table_ptr,         0x030014F0   @ array of sample-instrument pointers, one per SFX id
	.equ seq_frame_time,        0x030014F4   @ microseconds<<8 elapsed per frame
	.equ seq_track_ptr,         0x03001500   @ [16] current event pointer per track
	.equ seq_division,          0x03001540   @ ticks per quarter note
	.equ sfx_master_volume,     0x03001544   @ 
	.equ music_paused,          0x03001548   @ 
	.equ chan_cc100,            0x03001550   @ [16] CC100 value - written, never read
	.equ chan_volume,           0x03001560   @ [16] CC7
	.equ mix_max_voices,        0x03001570   @ 
	.equ chan_bend,             0x03001580   @ [16] u32 14-bit pitch bend
	.equ mix_pitch_scale,       0x030015C0   @ 2^38 / mixing rate
	.equ seq_pending_song,      0x030015C4   @ -1 = none
	.equ chan_instrument,       0x030015D0   @ [16] current instrument pointer
	.equ chan_mono,             0x03001610   @ [16] 1 = mono (CC126), 0 = poly (CC127)
	.equ music_voices,          0x03001620   @ [96] x 0x28
	.equ music_master_volume,   0x03002520   @ 
	.equ sfx_handle,            0x03002530   @ [8] handle per SFX voice (5 used)
	.equ sfx_timer,             0x03002550   @ [8] frames to auto key-off (5 used)
	.equ seq_track_time,        0x030028F0   @ [16] s64 time until next event, us<<8
	.equ mix_buffer,            0x03002970   @ s16 x 224
	.equ seq_inst_table_ptr,    0x03002B30   @ song+0x10: instrument pointer table
	.equ sfx_handle_counter,    0x03003F2C   @ 
	.equ sfx_voices,            0x03003F30   @ [5] x 0x28
	.equ mix_rate_hz,           0x03003FF8   @ 
	.equ seq_tempo,             0x03003FFC   @ microseconds per quarter note
	.equ dma_buffer_flag,       0x03004000   @ toggled by snd_vblank
	.equ song_table_ptr,        0x03004004   @ 


@ iwram_code_size: Size of the IWRAM block, read by snd_init
iwram_code_size:
	.word 0x00001098
	.balign 4
iwram_code_start:
	.arm

@ ------------------------------------------------------------------
@ voice_start   ROM 0x08031BC8 / IWRAM 0x03002B40 (ARM)
@ Start a voice. In: r5=voice, r2=sample-instrument, r1=pitch mult (16.16), r3=volume,
@ r4=MIDI key (for note-off matching), r7=loop mode, sb=pitch key. Sets state=0x11 (key on).
@ ------------------------------------------------------------------
voice_start:
	stmdb sp!, {lr}                      @ 08031BC8
	strb r3, [r5, #3]                    @ 08031BCC
	str r1, [r5, #0x24]                  @ 08031BD0
	strb r7, [r5, #1]                    @ 08031BD4
	strb r4, [r5, #2]                    @ 08031BD8
	strb sb, [r5, #5]                    @ 08031BDC
	ldr r1, [r2, #0x10]                  @ 08031BE0
	str r1, [r5, #0xc]                   @ 08031BE4
	mov r1, #0                           @ 08031BE8
	str r1, [r5, #0x10]                  @ 08031BEC
	strb r1, [r5, #4]                    @ 08031BF0
	str r1, [r5, #0x14]                  @ 08031BF4
	str r2, [r5, #0x20]                  @ 08031BF8
	mov r8, #0x11                        @ 08031BFC
	strb r8, [r5]                        @ 08031C00
	ldm sp!, {lr}                        @ 08031C04
	bx lr                                @ 08031C08

@ ------------------------------------------------------------------
@ mix_frame   ROM 0x08031C0C / IWRAM 0x03002B84 (ARM)
@ Render one frame: mix up to mix_max_voices voices (SFX key-on, SFX released,
@ music key-on, music released - in that priority order) into the s16 mix buffer, then clip
@ to s8 into the DirectSound buffer that the DMA is NOT currently playing.
@ ------------------------------------------------------------------
mix_frame:
	sub sp, sp, #0x24                    @ 08031C0C
	str lr, [sp, #8]                     @ 08031C10
	ldr r5, lit_8032438                  @ 08031C14  = mix_buffer
	str r5, [sp, #4]                     @ 08031C18
	ldr r1, lit_803243C                  @ 08031C1C  = mix_max_voices
	ldr r1, [r1]                         @ 08031C20
	str r1, [sp, #0x10]                  @ 08031C24
	ldr r2, lit_8032440                  @ 08031C28  = cfg_sfx_pool_bytes
	ldr r2, [r2]                         @ 08031C2C
	ldr r0, lit_8032444                  @ 08031C30  = sfx_voices
	add r0, r0, r2                       @ 08031C34
L_8031C38:
	ldrb r5, [r0, -r2]                   @ 08031C38
	cmp r5, #0x11                        @ 08031C3C
	bleq mix_frame_voice                 @ 08031C40  SFX voices, key on
	subs r2, r2, #0x28                   @ 08031C44
	bgt L_8031C38                        @ 08031C48
	ldr r2, lit_8032448                  @ 08031C4C  = cfg_sfx_pool_bytes
	ldr r2, [r2]                         @ 08031C50
L_8031C54:
	ldrb r5, [r0, -r2]                   @ 08031C54
	cmp r5, #0x12                        @ 08031C58
	bleq mix_frame_voice                 @ 08031C5C  SFX voices, released
	subs r2, r2, #0x28                   @ 08031C60
	bgt L_8031C54                        @ 08031C64
	ldr r0, lit_803244C                  @ 08031C68  = music_paused
	ldr r1, [r0]                         @ 08031C6C
	cmp r1, #1                           @ 08031C70
	beq L_8031CB8                        @ 08031C74
	ldr r2, lit_8032450                  @ 08031C78  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 08031C7C
	ldr r0, lit_8032454                  @ 08031C80  = music_voices
	add r0, r0, r2                       @ 08031C84
L_8031C88:
	ldrb r5, [r0, -r2]                   @ 08031C88
	cmp r5, #0x11                        @ 08031C8C
	bleq mix_frame_voice                 @ 08031C90  music voices, key on
	subs r2, r2, #0x28                   @ 08031C94
	bgt L_8031C88                        @ 08031C98
	ldr r2, lit_8032458                  @ 08031C9C  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 08031CA0
L_8031CA4:
	ldrb r5, [r0, -r2]                   @ 08031CA4
	cmp r5, #0x12                        @ 08031CA8
	bleq mix_frame_voice                 @ 08031CAC  music voices, released
	subs r2, r2, #0x28                   @ 08031CB0
	bgt L_8031CA4                        @ 08031CB4
L_8031CB8:
	ldr r0, [sp, #0x10]                  @ 08031CB8
	ldr r1, lit_803245C                  @ 08031CBC  = mix_max_voices
	ldr r1, [r1]                         @ 08031CC0
	cmp r0, r1                           @ 08031CC4
	bne L_8031CD8                        @ 08031CC8
	ldr r0, lit_8032460                  @ 08031CCC  = clear_mix_buffer+1 ; nothing mixed -> zero the buffer (Thumb, via bx)
	add lr, pc, #0                       @ 08031CD0
	bx r0                                @ 08031CD4
L_8031CD8:
	ldr r0, lit_8032464                  @ 08031CD8  = dma_buffer_flag
	ldr r2, [r0]                         @ 08031CDC
	ldr r1, lit_8032468                  @ 08031CE0  = cfg_buffer_a
	cmp r2, #0                           @ 08031CE4
	bne L_8031CF0                        @ 08031CE8
	ldr r1, lit_803246C                  @ 08031CEC  = cfg_buffer_b
L_8031CF0:
	ldr r1, [r1]                         @ 08031CF0
	ldr r0, lit_8032470                  @ 08031CF4  = mix_buffer
	ldr r2, lit_8032474                  @ 08031CF8  = mix_samples_per_frame
	ldr r2, [r2]                         @ 08031CFC
L_8031D00:
	ldrsh r3, [r0], #2                   @ 08031D00  clip s16 -> s8
	cmp r3, #0x7f                        @ 08031D04
	movgt r3, #0x7f                      @ 08031D08
	bgt L_8031D18                        @ 08031D0C
	cmn r3, #0x80                        @ 08031D10
	mvnlt r3, #0x7f                      @ 08031D14
L_8031D18:
	strb r3, [r1], #1                    @ 08031D18
	subs r2, r2, #1                      @ 08031D1C
	bne L_8031D00                        @ 08031D20
	ldr lr, [sp, #8]                     @ 08031D24
	add sp, sp, #0x24                    @ 08031D28
	bx lr                                @ 08031D2C

@ ------------------------------------------------------------------
@ mix_frame_voice   ROM 0x08031D30 / IWRAM 0x03002CA8 (ARM)
@ mix_frame helper: mix voice (r0-r2) and count it against the voice budget; when the
@ budget hits zero, abandon the scan and go straight to the s16->s8 conversion.
@ ------------------------------------------------------------------
mix_frame_voice:
	str lr, [sp, #0xc]                   @ 08031D30
	str r0, [sp, #0x14]                  @ 08031D34
	str r2, [sp, #0x18]                  @ 08031D38
	sub r0, r0, r2                       @ 08031D3C
	ldr r5, [sp, #4]                     @ 08031D40
	bl mix_voice                         @ 08031D44
	ldr r1, [sp, #0x10]                  @ 08031D48
	subs r1, r1, #1                      @ 08031D4C
	str r1, [sp, #0x10]                  @ 08031D50
	beq L_8031CD8                        @ 08031D54
	ldr r0, [sp, #0x14]                  @ 08031D58
	ldr r2, [sp, #0x18]                  @ 08031D5C
	ldr pc, [sp, #0xc]                   @ 08031D60

@ ------------------------------------------------------------------
@ advance_sfx_voices   ROM 0x08031D64 / IWRAM 0x03002CDC (ARM)
@ Advance the playback position of every active SFX voice by one frame.
@ ------------------------------------------------------------------
advance_sfx_voices:
	stmdb sp!, {lr}                      @ 08031D64
	ldr fp, lit_8032478                  @ 08031D68  = cfg_sfx_pool_bytes
	ldr fp, [fp]                         @ 08031D6C
	ldr sl, lit_803247C                  @ 08031D70  = sfx_voices
	add sl, sl, fp                       @ 08031D74
	b L_8031D90                          @ 08031D78

@ ------------------------------------------------------------------
@ advance_music_voices   ROM 0x08031D7C / IWRAM 0x03002CF4 (ARM)
@ Advance the playback position of every active music voice by one frame.
@ ------------------------------------------------------------------
advance_music_voices:
	stmdb sp!, {lr}                      @ 08031D7C
	ldr fp, lit_8032480                  @ 08031D80  = cfg_music_pool_bytes
	ldr fp, [fp]                         @ 08031D84
	ldr sl, lit_8032484                  @ 08031D88  = music_voices
	add sl, sl, fp                       @ 08031D8C
L_8031D90:
	ldrb r2, [sl, -fp]                   @ 08031D90
	cmp r2, #0x11                        @ 08031D94
	bleq voice_advance                   @ 08031D98
	cmp r2, #0x12                        @ 08031D9C
	bleq voice_advance                   @ 08031DA0
	subs fp, fp, #0x28                   @ 08031DA4
	bgt L_8031D90                        @ 08031DA8
	ldm sp!, {lr}                        @ 08031DAC
	bx lr                                @ 08031DB0

@ ------------------------------------------------------------------
@ voice_advance   ROM 0x08031DB4 / IWRAM 0x03002D2C (ARM)
@ Advance one voice (r0=voice) by mix_samples_per_frame samples using 64-bit maths,
@ then handle end-of-sample (loop or free). The mixer never writes positions back; this pass does.
@ NOTE: loop mode 1 frees the voice through [r8] instead of [r0] (bug, fixed in DKC3).
@ ------------------------------------------------------------------
voice_advance:
	sub r0, sl, fp                       @ 08031DB4
	ldr r7, [r0, #8]                     @ 08031DB8
	movs r7, r7                          @ 08031DBC
	bne L_8031DD0                        @ 08031DC0
	push {sl, fp, lr}                    @ 08031DC4
	bl calc_pitch                        @ 08031DC8
	pop {sl, fp, lr}                     @ 08031DCC
L_8031DD0:
	ldr r1, lit_8032488                  @ 08031DD0  = mix_samples_per_frame
	ldr r1, [r1]                         @ 08031DD4
	ldr r2, [r0, #0x10]                  @ 08031DD8
	ldr r3, [r0, #0xc]                   @ 08031DDC
	mov r6, #0                           @ 08031DE0
	str r6, [r0, #8]                     @ 08031DE4
	ldr r6, [r0, #0x24]                  @ 08031DE8
	umull r4, r5, r6, r7                 @ 08031DEC  step * pitch multiplier (16.16)
	lsr r7, r4, #0x10                    @ 08031DF0
	add r7, r7, r5, lsl #16              @ 08031DF4
	orr r2, r2, r3, lsl #23              @ 08031DF8
	lsr r3, r3, #9                       @ 08031DFC
	umlal r2, r3, r7, r1                 @ 08031E00
	ldr r4, lit_803248C                  @ 08031E04  = 0x007FFFFF
	and r1, r2, r4                       @ 08031E08
	lsr r2, r2, #0x17                    @ 08031E0C
	orr r2, r2, r3, lsl #9               @ 08031E10
	ldr r3, [r0, #0x20]                  @ 08031E14
	ldr r3, [r3, #0x18]                  @ 08031E18
	cmp r2, r3                           @ 08031E1C
	blt L_8031E78                        @ 08031E20
	ldrb r4, [r0, #1]                    @ 08031E24
	cmp r4, #1                           @ 08031E28
	beq L_8031E6C                        @ 08031E2C
	cmp r4, #2                           @ 08031E30
	beq L_8031E48                        @ 08031E34
	cmp r4, #3                           @ 08031E38
	beq L_8031E60                        @ 08031E3C
	cmp r4, #4                           @ 08031E40
	beq L_8031E48                        @ 08031E44
L_8031E48:
	ldr r4, [r0, #0x20]                  @ 08031E48
	ldr r4, [r4, #0x14]                  @ 08031E4C
L_8031E50:
	sub r2, r2, r4                       @ 08031E50
	cmp r2, r3                           @ 08031E54
	bge L_8031E50                        @ 08031E58
	b L_8031E78                          @ 08031E5C
L_8031E60:
	mov r3, #0x10                        @ 08031E60
	strb r3, [r0]                        @ 08031E64
	b L_8031E78                          @ 08031E68
L_8031E6C:
	mov r3, #0x10                        @ 08031E6C
	strb r3, [r8]                        @ 08031E70  BUG: should be [r0]
	b L_8031E78                          @ 08031E74
L_8031E78:
	str r2, [r0, #0xc]                   @ 08031E78
	str r1, [r0, #0x10]                  @ 08031E7C
	mov pc, lr                           @ 08031E80

@ ------------------------------------------------------------------
@ env_update_sfx   ROM 0x08031E84 / IWRAM 0x03002DFC (ARM)
@ Run one envelope step on every active SFX voice.
@ ------------------------------------------------------------------
env_update_sfx:
	stmdb sp!, {lr}                      @ 08031E84
	ldr fp, lit_8032490                  @ 08031E88  = cfg_sfx_pool_bytes
	ldr fp, [fp]                         @ 08031E8C
	ldr sl, lit_8032494                  @ 08031E90  = sfx_voices
	add sl, sl, fp                       @ 08031E94
	b L_8031EB0                          @ 08031E98

@ ------------------------------------------------------------------
@ env_update_music   ROM 0x08031E9C / IWRAM 0x03002E14 (ARM)
@ Run one envelope step on every active music voice.
@ ------------------------------------------------------------------
env_update_music:
	stmdb sp!, {lr}                      @ 08031E9C
	ldr fp, lit_8032498                  @ 08031EA0  = cfg_music_pool_bytes
	ldr fp, [fp]                         @ 08031EA4
	ldr sl, lit_803249C                  @ 08031EA8  = music_voices
	add sl, sl, fp                       @ 08031EAC
L_8031EB0:
	ldrb r2, [sl, -fp]                   @ 08031EB0
	cmp r2, #0x11                        @ 08031EB4
	bleq env_step                        @ 08031EB8
	cmp r2, #0x12                        @ 08031EBC
	bleq env_step                        @ 08031EC0
L_8031EC4:
	subs fp, fp, #0x28                   @ 08031EC4
	bgt L_8031EB0                        @ 08031EC8
	ldm sp!, {lr}                        @ 08031ECC
	bx lr                                @ 08031ED0

@ ------------------------------------------------------------------
@ env_step   ROM 0x08031ED4 / IWRAM 0x03002E4C (ARM)
@ Dispatch on voice+4 (envelope phase 0-6) through env_jump_table.
@ ------------------------------------------------------------------
env_step:
	sub ip, sl, fp                       @ 08031ED4
	ldrb r1, [ip, #4]                    @ 08031ED8
	add r2, pc, #4                       @ 08031EDC  = env_jump_table
	ldr r0, [r2, r1, lsl #2]             @ 08031EE0
	add pc, r0, r2                       @ 08031EE4

@ env_jump_table: 7 x offset from env_jump_table
env_jump_table:
	.word env_attack_init - env_jump_table
	.word env_attack - env_jump_table
	.word env_decay_init - env_jump_table
	.word env_decay - env_jump_table
	.word env_sustain - env_jump_table
	.word env_release_init - env_jump_table
	.word env_release - env_jump_table

@ ------------------------------------------------------------------
@ env_attack_init   ROM 0x08031F04 / IWRAM 0x03002E7C (ARM)
@ Phase 0: attack time = (99-A)*32/99 frames; 0 = instant (go to decay at full level).
@ ------------------------------------------------------------------
env_attack_init:
	ldr r3, [ip, #0x20]                  @ 08031F04
	ldr r1, [r3, #0x24]                  @ 08031F08
	rsb r2, r1, #0x63                    @ 08031F0C
	lsl r0, r2, #5                       @ 08031F10
	mov r1, #0x63                        @ 08031F14
	bl udiv_32_16                        @ 08031F18  udiv_32_16
	movs r0, r0                          @ 08031F1C
	beq L_8031F6C                        @ 08031F20
	mov r1, r0                           @ 08031F24
	mov r0, #0x8000                      @ 08031F28
	add r1, r1, #1                       @ 08031F2C
	bl udiv_32_16                        @ 08031F30
	lsl r1, r1, #4                       @ 08031F34
	lsl r0, r0, #4                       @ 08031F38
	str r1, [ip, #0x14]                  @ 08031F3C
	str r0, [ip, #0x18]                  @ 08031F40
	mov r0, #1                           @ 08031F44
	strb r0, [ip, #4]                    @ 08031F48

@ ------------------------------------------------------------------
@ env_attack   ROM 0x08031F4C / IWRAM 0x03002EC4 (ARM)
@ Phase 1: ramp level up by env_inc; on key-off go to release.
@ ------------------------------------------------------------------
env_attack:
	ldrb r1, [ip]                        @ 08031F4C
	cmp r1, #0x12                        @ 08031F50
	beq env_release_init                 @ 08031F54
	ldr r1, [ip, #0x18]                  @ 08031F58
	ldr r2, [ip, #0x14]                  @ 08031F5C
	add r1, r1, r2                       @ 08031F60
	cmp r1, #0x80000                     @ 08031F64
	blt L_8031F78                        @ 08031F68
L_8031F6C:
	mov r1, #2                           @ 08031F6C
	strb r1, [ip, #4]                    @ 08031F70
	mov r1, #0x80000                     @ 08031F74
L_8031F78:
	str r1, [ip, #0x14]                  @ 08031F78
	sub pc, pc, #0xc0                    @ 08031F7C  -> L_8031EC4

@ ------------------------------------------------------------------
@ env_decay_init   ROM 0x08031F80 / IWRAM 0x03002EF8 (ARM)
@ Phase 2: sustain = S*128/99 (8.8) << 4; decay frames = adsr_rate_table[D].
@ ------------------------------------------------------------------
env_decay_init:
	ldr r3, [ip, #0x20]                  @ 08031F80
	ldr r0, [r3, #0x2c]                  @ 08031F84
	lsl r0, r0, #7                       @ 08031F88
	mov r1, #0x63                        @ 08031F8C
	bl udiv_32_16                        @ 08031F90
	lsl r4, r0, #8                       @ 08031F94
	lsl r0, r1, #8                       @ 08031F98
	mov r1, #0x63                        @ 08031F9C
	bl udiv_32_16                        @ 08031FA0
	orr r0, r4, r0                       @ 08031FA4
	lsl r1, r0, #4                       @ 08031FA8
	str r1, [ip, #0x1c]                  @ 08031FAC
	rsb r0, r0, #0x8000                  @ 08031FB0
	ldr r1, [r3, #0x28]                  @ 08031FB4
	ldr r2, lit_80324A0                  @ 08031FB8  = adsr_rate_table
	ldrb r1, [r2, r1]                    @ 08031FBC
	movs r1, r1                          @ 08031FC0
	beq L_8032010                        @ 08031FC4
	add r1, r1, #1                       @ 08031FC8
	bl udiv_32_16                        @ 08031FCC
	lsl r0, r0, #4                       @ 08031FD0
	str r0, [ip, #0x18]                  @ 08031FD4
	ldr r0, [ip, #0x14]                  @ 08031FD8
	sub r0, r0, r1, lsl #4               @ 08031FDC
	str r0, [ip, #0x14]                  @ 08031FE0
	mov r1, #3                           @ 08031FE4
	strb r1, [ip, #4]                    @ 08031FE8

@ ------------------------------------------------------------------
@ env_decay   ROM 0x08031FEC / IWRAM 0x03002F64 (ARM)
@ Phase 3: ramp down to sustain; a sustain level below 0x1000 kills the voice.
@ ------------------------------------------------------------------
env_decay:
	ldrb r1, [ip]                        @ 08031FEC
	cmp r1, #0x12                        @ 08031FF0
	beq env_release_init                 @ 08031FF4
	ldr r1, [ip, #0x18]                  @ 08031FF8
	ldr r2, [ip, #0x14]                  @ 08031FFC
	ldr r3, [ip, #0x1c]                  @ 08032000
	sub r1, r2, r1                       @ 08032004
	cmp r1, r3                           @ 08032008
	bgt L_803201C                        @ 0803200C
L_8032010:
	mov r1, #4                           @ 08032010
	strb r1, [ip, #4]                    @ 08032014
	ldr r1, [ip, #0x1c]                  @ 08032018
L_803201C:
	cmp r1, #0x1000                      @ 0803201C
	blt env_kill                         @ 08032020
	str r1, [ip, #0x14]                  @ 08032024
	sub pc, pc, #0x16c                   @ 08032028  -> L_8031EC4

@ ------------------------------------------------------------------
@ env_sustain   ROM 0x0803202C / IWRAM 0x03002FA4 (ARM)
@ Phase 4: hold until key-off.
@ ------------------------------------------------------------------
env_sustain:
	ldrb r1, [ip]                        @ 0803202C
	cmp r1, #0x12                        @ 08032030
	beq env_release_init                 @ 08032034
	sub pc, pc, #0x17c                   @ 08032038  -> L_8031EC4

@ ------------------------------------------------------------------
@ env_release_init   ROM 0x0803203C / IWRAM 0x03002FB4 (ARM)
@ Phase 5: release frames = adsr_rate_table[R]; 0 = cut immediately.
@ ------------------------------------------------------------------
env_release_init:
	ldr r3, [ip, #0x20]                  @ 0803203C
	ldr r0, [ip, #0x14]                  @ 08032040
	ldr r1, [r3, #0x30]                  @ 08032044
	ldr r2, lit_80324A4                  @ 08032048  = adsr_rate_table
	ldrb r1, [r2, r1]                    @ 0803204C
	movs r1, r1                          @ 08032050
	beq env_kill                         @ 08032054
	lsr r0, r0, #4                       @ 08032058
	add r1, r1, #1                       @ 0803205C
	bl udiv_32_16                        @ 08032060
	lsls r0, r0, #4                      @ 08032064
	beq env_kill                         @ 08032068
	str r0, [ip, #0x18]                  @ 0803206C
	ldr r0, [ip, #0x14]                  @ 08032070
	sub r0, r0, r1, lsl #4               @ 08032074
	str r0, [ip, #0x14]                  @ 08032078
	mov r1, #6                           @ 0803207C
	strb r1, [ip, #4]                    @ 08032080

@ ------------------------------------------------------------------
@ env_release   ROM 0x08032084 / IWRAM 0x03002FFC (ARM)
@ Phase 6: ramp down to zero, then free the voice.
@ ------------------------------------------------------------------
env_release:
	ldr r1, [ip, #0x18]                  @ 08032084
	ldr r2, [ip, #0x14]                  @ 08032088
	subs r1, r2, r1                      @ 0803208C
	bgt L_803209C                        @ 08032090

@ ------------------------------------------------------------------
@ env_kill   ROM 0x08032094 / IWRAM 0x0300300C (ARM)
@ Free the voice (state 0x10).
@ ------------------------------------------------------------------
env_kill:
	mov r1, #0x10                        @ 08032094
	strb r1, [ip]                        @ 08032098
L_803209C:
	str r1, [ip, #0x14]                  @ 0803209C
	sub pc, pc, #0x1e4                   @ 080320A0  -> L_8031EC4

@ ------------------------------------------------------------------
@ ev_tempo   ROM 0x080320A4 / IWRAM 0x0300301C (ARM)
@ cmd 0: 24-bit tempo in microseconds per quarter note (as MIDI meta FF 51).
@ ------------------------------------------------------------------
ev_tempo:
	bic r2, fp, #3                       @ 080320A4
	ldm r2, {r1, r3}                     @ 080320A8
	and r2, fp, #3                       @ 080320AC
	lsls r2, r2, #3                      @ 080320B0
	lsrne r1, r1, r2                     @ 080320B4
	rsbne r2, r2, #0x20                  @ 080320B8
	orrne r1, r1, r3, lsl r2             @ 080320BC
	add fp, fp, #3                       @ 080320C0
	bl set_tempo_internal                @ 080320C4
	add pc, pc, #0x2b8                   @ 080320C8  -> L_8032388

@ ------------------------------------------------------------------
@ set_tempo_internal   ROM 0x080320CC / IWRAM 0x03003044 (ARM)
@ r1 = tempo (us/qn). Also (re)computes seq_frame_time = 60,000,000/3600 us in 24.8
@ fixed point = 16666.67 us, i.e. the sequencer assumes exactly 60 frames/s.
@ ------------------------------------------------------------------
set_tempo_internal:
	stmdb sp!, {lr}                      @ 080320CC
	bic r0, r1, #0xff000000              @ 080320D0
	ldr r2, lit_80324A8                  @ 080320D4  = seq_tempo
	str r0, [r2]                         @ 080320D8
	ldr r0, lit_80324AC                  @ 080320DC  = USEC_PER_MINUTE
	mov r1, #0xe10                       @ 080320E0
	bl udiv_32_16                        @ 080320E4
	lsl r4, r0, #8                       @ 080320E8
	lsl r0, r1, #0x10                    @ 080320EC
	mov r1, #0xe10                       @ 080320F0
	bl udiv_32_16                        @ 080320F4
	orr r0, r4, r0, lsr #8               @ 080320F8
	ldr r2, lit_80324B0                  @ 080320FC  = seq_frame_time
	str r0, [r2]                         @ 08032100
	ldm sp!, {lr}                        @ 08032104
	bx lr                                @ 08032108

@ ------------------------------------------------------------------
@ ev_delta8   ROM 0x0803210C / IWRAM 0x03003084 (ARM)
@ cmd 1: delta time, 1 byte (ticks). Converts ticks -> microseconds<<8 and adds to the track clock.
@ ------------------------------------------------------------------
ev_delta8:
	ldr r5, lit_80324B4                  @ 0803210C  = seq_division
	ldr r5, [r5]                         @ 08032110
	ldrb r1, [fp], #1                    @ 08032114
	ldr r0, lit_80324B8                  @ 08032118  = seq_tempo
	ldr r2, [r0]                         @ 0803211C
	mul r1, r2, r1                       @ 08032120
	mov r0, #0                           @ 08032124
	mov r2, r5                           @ 08032128
	bl sdiv_64_32                        @ 0803212C
	lsl r4, r1, #8                       @ 08032130
	lsl r0, r0, #0x10                    @ 08032134
	mov r1, r5                           @ 08032138
	bl udiv_32_16                        @ 0803213C
	orr r1, r4, r0, lsr #8               @ 08032140
	mov r2, #0                           @ 08032144
	ldr r5, [sp]                         @ 08032148
	ldr r0, lit_80324BC                  @ 0803214C  = seq_track_time
	add r0, r0, r5, lsl #3               @ 08032150
	ldm r0, {r3, r4}                     @ 08032154
	adds r1, r3, r1                      @ 08032158
	adcs r2, r4, r2                      @ 0803215C
	stm r0, {r1, r2}                     @ 08032160
	add pc, pc, #0x230                   @ 08032164  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_delta16   ROM 0x08032168 / IWRAM 0x030030E0 (ARM)
@ cmd 2: delta time, 2 bytes little-endian.
@ ------------------------------------------------------------------
ev_delta16:
	ldr r5, lit_80324C0                  @ 08032168  = seq_division
	ldr r5, [r5]                         @ 0803216C
	ldrb r0, [fp], #1                    @ 08032170
	ldrb r1, [fp], #1                    @ 08032174
	orr r1, r0, r1, lsl #8               @ 08032178
	ldr r0, lit_80324C4                  @ 0803217C  = seq_tempo
	ldr r2, [r0]                         @ 08032180
	umull r1, r0, r2, r1                 @ 08032184
	mov r2, r5                           @ 08032188
	bl sdiv_64_32                        @ 0803218C
	lsr r6, r1, #0x18                    @ 08032190
	lsl r4, r1, #8                       @ 08032194
	lsl r0, r0, #0x10                    @ 08032198
	mov r1, r5                           @ 0803219C
	bl udiv_32_16                        @ 080321A0
	orr r1, r4, r0, lsr #8               @ 080321A4
	mov r2, r6                           @ 080321A8
	ldr r5, [sp]                         @ 080321AC
	ldr r0, lit_80324C8                  @ 080321B0  = seq_track_time
	add r0, r0, r5, lsl #3               @ 080321B4
	ldm r0, {r3, r4}                     @ 080321B8
	adds r1, r3, r1                      @ 080321BC
	adcs r2, r4, r2                      @ 080321C0
	stm r0, {r1, r2}                     @ 080321C4
	add pc, pc, #0x1cc                   @ 080321C8  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_delta24   ROM 0x080321CC / IWRAM 0x03003144 (ARM)
@ cmd 3: delta time, 3 bytes little-endian.
@ ------------------------------------------------------------------
ev_delta24:
	bic r2, fp, #3                       @ 080321CC
	ldm r2, {r1, r3}                     @ 080321D0
	and r2, fp, #3                       @ 080321D4
	lsls r2, r2, #3                      @ 080321D8
	lsrne r1, r1, r2                     @ 080321DC
	rsbne r2, r2, #0x20                  @ 080321E0
	orrne r1, r1, r3, lsl r2             @ 080321E4
	add fp, fp, #3                       @ 080321E8
	bic r1, r1, #0xff000000              @ 080321EC
	ldr r0, lit_80324CC                  @ 080321F0  = seq_tempo
	ldr r2, [r0]                         @ 080321F4
	umull r1, r0, r2, r1                 @ 080321F8
	ldr r5, lit_80324D0                  @ 080321FC  = seq_division
	ldr r5, [r5]                         @ 08032200
	mov r2, r5                           @ 08032204
	bl sdiv_64_32                        @ 08032208
	lsr r6, r1, #0x18                    @ 0803220C
	lsl r4, r1, #8                       @ 08032210
	lsl r0, r0, #0x10                    @ 08032214
	mov r1, r5                           @ 08032218
	bl udiv_32_16                        @ 0803221C
	orr r1, r4, r0, lsr #8               @ 08032220
	mov r2, r6                           @ 08032224
	ldr r5, [sp]                         @ 08032228
	ldr r0, lit_80324D4                  @ 0803222C  = seq_track_time
	add r0, r0, r5, lsl #3               @ 08032230
	ldm r0, {r3, r4}                     @ 08032234
	adds r1, r3, r1                      @ 08032238
	adcs r2, r4, r2                      @ 0803223C
	stm r0, {r1, r2}                     @ 08032240
	add pc, pc, #0x150                   @ 08032244  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_note_on   ROM 0x08032248 / IWRAM 0x030031C0 (ARM)
@ cmd 4/5: note on <key> <velocity>. Allocates one of the channel's 6 voices
@ (free first, then released); mono mode always reuses slot 0. Resolves rhythm sets (0x22)
@ and key splits (0x23) through the instrument's keymap. Note is dropped if no voice is free.
@ ------------------------------------------------------------------
ev_note_on:
	ldr r4, lit_80324D8                  @ 08032248  = cfg_chan_pool_bytes
	ldr r4, [r4]                         @ 0803224C
	ldr r3, lit_80324DC                  @ 08032250  = music_voices
	add r3, r3, r4                       @ 08032254
	mla r5, r1, r4, r3                   @ 08032258
	ldr r2, lit_80324E0                  @ 0803225C  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 08032260
	ldr r0, lit_80324E4                  @ 08032264  = chan_mono
	ldrb r0, [r0, r1]                    @ 08032268
	cmp r0, #0                           @ 0803226C
	bne L_80322B0                        @ 08032270
L_8032274:
	ldrb r0, [r5, -r2]                   @ 08032274
	cmp r0, #0x10                        @ 08032278
	beq L_80322B0                        @ 0803227C
	subs r2, r2, #0x28                   @ 08032280
	bgt L_8032274                        @ 08032284
	ldr r2, lit_80324E8                  @ 08032288  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 0803228C
L_8032290:
	ldrb r0, [r5, -r2]                   @ 08032290
	cmp r0, #0x12                        @ 08032294
	beq L_80322B0                        @ 08032298
	subs r2, r2, #0x28                   @ 0803229C
	bgt L_8032290                        @ 080322A0
	ldrb r4, [fp], #1                    @ 080322A4
	ldrb r0, [fp], #1                    @ 080322A8
	b L_8032330                          @ 080322AC
L_80322B0:
	sub r5, r5, r2                       @ 080322B0
	ldrb r4, [fp], #1                    @ 080322B4
	mov sb, r4                           @ 080322B8
	mov r7, #4                           @ 080322BC
	ldr r6, lit_80324EC                  @ 080322C0  = chan_instrument
	mla r2, r1, r7, r6                   @ 080322C4
	ldr r2, [r2]                         @ 080322C8
	ldr r7, [r2]                         @ 080322CC
	cmp r7, #0x20                        @ 080322D0  0x20 = plain instrument
	beq L_803231C                        @ 080322D4
	cmp r7, #0x21                        @ 080322D8
	beq L_803231C                        @ 080322DC
	cmp r7, #0x22                        @ 080322E0  0x22 = rhythm set
	beq L_80322F0                        @ 080322E4
	cmp r7, #0x23                        @ 080322E8  0x23 = key split
	beq L_8032308                        @ 080322EC
L_80322F0:
	ldr r0, [r2, #0x1c]                  @ 080322F0
	ldrb r1, [r0, r4]                    @ 080322F4
	ldr r0, [r2, #0x20]                  @ 080322F8
	ldr r2, [r0, r1, lsl #2]             @ 080322FC
	ldr sb, [r2, #0xc]                   @ 08032300
	b L_803231C                          @ 08032304
L_8032308:
	ldr r0, [r2, #0x1c]                  @ 08032308
	ldrb r1, [r0, r4]                    @ 0803230C
	ldr r0, [r2, #0x20]                  @ 08032310
	ldr r2, [r0, r1, lsl #2]             @ 08032314
	b L_803231C                          @ 08032318
L_803231C:
	ldr r7, [r2, #4]                     @ 0803231C
	ldrb r3, [fp], #1                    @ 08032320
	add r3, r3, #1                       @ 08032324
	mov r1, #0x10000                     @ 08032328
	bl voice_start                       @ 0803232C
L_8032330:
	add pc, pc, #0x50                    @ 08032330  -> L_8032388

@ ------------------------------------------------------------------
@ seq_update   ROM 0x08032334 / IWRAM 0x030032AC (ARM)
@ Sequencer tick, once per frame: for each track subtract one frame of time from its clock;
@ while the clock is negative, execute events. Stops the song when every track sits on END.
@ ------------------------------------------------------------------
seq_update:
	stmdb sp!, {lr}                      @ 08032334
	sub sp, sp, #0xc                     @ 08032338
	mov r0, #0                           @ 0803233C
	str r0, [sp, #8]                     @ 08032340
	mvn r0, #0                           @ 08032344
	str r0, [sp]                         @ 08032348
	b L_80323C8                          @ 0803234C
L_8032350:
	str r0, [sp]                         @ 08032350
	ldr r4, lit_80324F0                  @ 08032354  = seq_track_time
	add r4, r4, r0, lsl #3               @ 08032358
	ldr r1, lit_80324F4                  @ 0803235C  = seq_frame_time
	ldm r4, {r2, r3}                     @ 08032360
	ldr r5, [r1]                         @ 08032364
	subs r2, r2, r5                      @ 08032368
	sbcs r3, r3, #0                      @ 0803236C
	stm r4, {r2, r3}                     @ 08032370
	bpl L_80323C8                        @ 08032374
	ldr fp, lit_80324F8                  @ 08032378  = seq_track_ptr
	ldr r0, [sp]                         @ 0803237C
	ldr fp, [fp, r0, lsl #2]             @ 08032380

@ seq_next_event: fetch and dispatch the next event of the current track
seq_next_event:
	add ip, pc, #0x78                    @ 08032384  = seq_cmd_table
L_8032388:
	ldrb r0, [fp], #1                    @ 08032388  event byte: high nibble = MIDI channel, low nibble = command
	lsr r1, r0, #4                       @ 0803238C
	bic r0, r0, #0xf0                    @ 08032390
	ldr r0, [ip, r0, lsl #2]             @ 08032394
	add pc, r0, ip                       @ 08032398  computed jump into handler

@ seq_after_delta: keep going while the track clock is still negative
seq_after_delta:
	ldr r0, [sp]                         @ 0803239C
	ldr r1, lit_80324FC                  @ 080323A0  = seq_track_time+0x4
	ldr r1, [r1, r0, lsl #3]             @ 080323A4
	cmp r1, #0                           @ 080323A8
	bmi L_80323B4                        @ 080323AC
	b L_80323B8                          @ 080323B0
L_80323B4:
	b seq_next_event                     @ 080323B4
L_80323B8:
	mov r0, r0                           @ 080323B8

@ seq_track_yield: save the track pointer and move to the next track
seq_track_yield:
	ldr r0, [sp]                         @ 080323BC
	ldr r2, lit_8032500                  @ 080323C0  = seq_track_ptr
	str fp, [r2, r0, lsl #2]             @ 080323C4
L_80323C8:
	ldr r1, lit_8032504                  @ 080323C8  = seq_num_tracks
	ldr r1, [r1]                         @ 080323CC
	ldr r0, [sp]                         @ 080323D0
	adds r0, r0, #1                      @ 080323D4
	cmp r0, r1                           @ 080323D8
	bne L_8032350                        @ 080323DC
	ldr r0, [sp, #8]                     @ 080323E0
	cmp r0, r1                           @ 080323E4
	bne L_80323F8                        @ 080323E8
	ldr r0, lit_8032508                  @ 080323EC  = seq_current_song
	mvn r1, #0                           @ 080323F0
	str r1, [r0]                         @ 080323F4
L_80323F8:
	add sp, sp, #0xc                     @ 080323F8
	ldm sp!, {lr}                        @ 080323FC
	bx lr                                @ 08032400

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
lit_8032438:
	.word mix_buffer
lit_803243C:
	.word mix_max_voices
lit_8032440:
	.word cfg_sfx_pool_bytes
lit_8032444:
	.word sfx_voices
lit_8032448:
	.word cfg_sfx_pool_bytes
lit_803244C:
	.word music_paused
lit_8032450:
	.word cfg_music_pool_bytes
lit_8032454:
	.word music_voices
lit_8032458:
	.word cfg_music_pool_bytes
lit_803245C:
	.word mix_max_voices
lit_8032460:
	.word clear_mix_buffer+1
lit_8032464:
	.word dma_buffer_flag
lit_8032468:
	.word cfg_buffer_a
lit_803246C:
	.word cfg_buffer_b
lit_8032470:
	.word mix_buffer
lit_8032474:
	.word mix_samples_per_frame
lit_8032478:
	.word cfg_sfx_pool_bytes
lit_803247C:
	.word sfx_voices
lit_8032480:
	.word cfg_music_pool_bytes
lit_8032484:
	.word music_voices
lit_8032488:
	.word mix_samples_per_frame
lit_803248C:
	.word 0x007FFFFF
lit_8032490:
	.word cfg_sfx_pool_bytes
lit_8032494:
	.word sfx_voices
lit_8032498:
	.word cfg_music_pool_bytes
lit_803249C:
	.word music_voices
lit_80324A0:
	.word adsr_rate_table
lit_80324A4:
	.word adsr_rate_table
lit_80324A8:
	.word seq_tempo
lit_80324AC:
	.word USEC_PER_MINUTE
lit_80324B0:
	.word seq_frame_time
lit_80324B4:
	.word seq_division
lit_80324B8:
	.word seq_tempo
lit_80324BC:
	.word seq_track_time
lit_80324C0:
	.word seq_division
lit_80324C4:
	.word seq_tempo
lit_80324C8:
	.word seq_track_time
lit_80324CC:
	.word seq_tempo
lit_80324D0:
	.word seq_division
lit_80324D4:
	.word seq_track_time
lit_80324D8:
	.word cfg_chan_pool_bytes
lit_80324DC:
	.word music_voices
lit_80324E0:
	.word cfg_chan_pool_bytes
lit_80324E4:
	.word chan_mono
lit_80324E8:
	.word cfg_chan_pool_bytes
lit_80324EC:
	.word chan_instrument
lit_80324F0:
	.word seq_track_time
lit_80324F4:
	.word seq_frame_time
lit_80324F8:
	.word seq_track_ptr
lit_80324FC:
	.word seq_track_time+0x4
lit_8032500:
	.word seq_track_ptr
lit_8032504:
	.word seq_num_tracks
lit_8032508:
	.word seq_current_song

@ ------------------------------------------------------------------
@ ev_note_off   ROM 0x0803250C / IWRAM 0x03003484 (ARM)
@ cmd 6: note off <key> <velocity(ignored)>. Releases the first key-on voice of the channel
@ whose stored key matches.
@ ------------------------------------------------------------------
ev_note_off:
	ldrb r6, [fp], #1                    @ 0803250C
	ldrb r7, [fp], #1                    @ 08032510
	ldr r4, lit_80328CC                  @ 08032514  = cfg_chan_pool_bytes
	ldr r4, [r4]                         @ 08032518
	ldr r3, lit_80328D0                  @ 0803251C  = music_voices
	add r3, r3, r4                       @ 08032520
	mla r5, r1, r4, r3                   @ 08032524
	ldr r2, lit_80328D4                  @ 08032528  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 0803252C
L_8032530:
	ldrb r0, [r5, -r2]                   @ 08032530
	cmp r0, #0x11                        @ 08032534
	bleq L_8032548                       @ 08032538
	subs r2, r2, #0x28                   @ 0803253C
	bgt L_8032530                        @ 08032540
	b L_8032560                          @ 08032544
L_8032548:
	sub r0, r5, r2                       @ 08032548
	ldrb r1, [r0, #2]                    @ 0803254C
	cmp r1, r6                           @ 08032550
	bxne lr                              @ 08032554
	mov r1, #0x12                        @ 08032558
	strb r1, [r0]                        @ 0803255C
L_8032560:
	sub pc, pc, #0x1e0                   @ 08032560  -> L_8032388

@ ------------------------------------------------------------------
@ ev_controller   ROM 0x08032564 / IWRAM 0x030034DC (ARM)
@ cmd 7: controller <cc> <value>. Handled: 1 mod wheel, 7 volume, 100 (stored, never read),
@ 102 loop start (save track pointer), 103 loop end (jump back), 126 mono on, 127 poly on.
@ ------------------------------------------------------------------
ev_controller:
	ldrb r2, [fp], #1                    @ 08032564
	ldrb r3, [fp], #1                    @ 08032568
	cmp r2, #1                           @ 0803256C
	beq L_80325A8                        @ 08032570
	cmp r2, #7                           @ 08032574
	beq L_80325BC                        @ 08032578
	cmp r2, #0x64                        @ 0803257C
	beq L_80325C8                        @ 08032580
	cmp r2, #0x66                        @ 08032584
	beq L_80325D4                        @ 08032588
	cmp r2, #0x67                        @ 0803258C
	beq L_80325E4                        @ 08032590
	cmp r2, #0x7e                        @ 08032594
	beq L_80325F4                        @ 08032598
	cmp r2, #0x7f                        @ 0803259C
	beq L_8032604                        @ 080325A0
	b L_8032614                          @ 080325A4
L_80325A8:
	ldr r5, lit_80328D8                  @ 080325A8  = chan_mod ; CC1  mod wheel
	mov r2, #8                           @ 080325AC
	mla r5, r1, r2, r5                   @ 080325B0
	str r3, [r5]                         @ 080325B4
	b L_8032614                          @ 080325B8
L_80325BC:
	ldr r5, lit_80328DC                  @ 080325BC  = chan_volume ; CC7  volume
	strb r3, [r5, r1]                    @ 080325C0
	b L_8032614                          @ 080325C4
L_80325C8:
	ldr r5, lit_80328E0                  @ 080325C8  = chan_cc100 ; CC100 (dead store)
	strb r3, [r5, r1]                    @ 080325CC
	b L_8032614                          @ 080325D0
L_80325D4:
	ldr r4, [sp]                         @ 080325D4  CC102 loop start
	ldr r5, lit_80328E4                  @ 080325D8  = seq_loop_ptr
	str fp, [r5, r4, lsl #2]             @ 080325DC
	b L_8032614                          @ 080325E0
L_80325E4:
	ldr r4, [sp]                         @ 080325E4  CC103 loop end
	ldr r5, lit_80328E8                  @ 080325E8  = seq_loop_ptr
	ldr fp, [r5, r4, lsl #2]             @ 080325EC
	b L_8032614                          @ 080325F0
L_80325F4:
	ldr r5, lit_80328EC                  @ 080325F4  = chan_mono ; CC126 mono
	mov r3, #1                           @ 080325F8
	strb r3, [r5, r1]                    @ 080325FC
	b L_8032614                          @ 08032600
L_8032604:
	ldr r5, lit_80328F0                  @ 08032604  = chan_mono ; CC127 poly
	mov r3, #0                           @ 08032608
	strb r3, [r5, r1]                    @ 0803260C
	b L_8032614                          @ 08032610
L_8032614:
	sub pc, pc, #0x294                   @ 08032614  -> L_8032388

@ ------------------------------------------------------------------
@ ev_program   ROM 0x08032618 / IWRAM 0x03003590 (ARM)
@ cmd 8: program change <prog>: prog -> prog_map byte -> instrument table entry.
@ ------------------------------------------------------------------
ev_program:
	ldrb r3, [fp], #1                    @ 08032618
	ldr r2, lit_80328F4                  @ 0803261C  = seq_prog_map_ptr
	ldr r2, [r2]                         @ 08032620
	ldrb r2, [r2, r3]                    @ 08032624
	ldr r3, lit_80328F8                  @ 08032628  = seq_inst_table_ptr
	ldr r3, [r3]                         @ 0803262C
	ldr r4, [r3, r2, lsl #2]             @ 08032630
	ldr r8, lit_80328FC                  @ 08032634  = chan_instrument
	mov r2, #4                           @ 08032638
	mla r8, r2, r1, r8                   @ 0803263C
	str r4, [r8]                         @ 08032640
	sub pc, pc, #0x2c4                   @ 08032644  -> L_8032388

@ ------------------------------------------------------------------
@ ev_skip1   ROM 0x08032648 / IWRAM 0x030035C0 (ARM)
@ cmd 9: one data byte, ignored (channel pressure slot).
@ ------------------------------------------------------------------
ev_skip1:
	add fp, fp, #1                       @ 08032648
	sub pc, pc, #0x2cc                   @ 0803264C  -> L_8032388

@ ------------------------------------------------------------------
@ ev_pitch_bend   ROM 0x08032650 / IWRAM 0x030035C8 (ARM)
@ cmd 10: pitch bend, 14-bit value stored as a little-endian 16-bit word (0x2000 = centre).
@ ------------------------------------------------------------------
ev_pitch_bend:
	mov r3, r1                           @ 08032650
	ldrb r0, [fp], #1                    @ 08032654
	ldrb r1, [fp], #1                    @ 08032658
	orr r1, r0, r1, lsl #8               @ 0803265C
	ldr r2, lit_8032900                  @ 08032660  = chan_bend
	str r1, [r2, r3, lsl #2]             @ 08032664
	sub pc, pc, #0x2e8                   @ 08032668  -> L_8032388

@ ------------------------------------------------------------------
@ ev_end_track   ROM 0x0803266C / IWRAM 0x030035E4 (ARM)
@ cmd 11: end of track - re-executed every frame; counts towards 'song finished'.
@ ------------------------------------------------------------------
ev_end_track:
	sub fp, fp, #1                       @ 0803266C
	ldr r0, [sp, #8]                     @ 08032670
	add r0, r0, #1                       @ 08032674
	str r0, [sp, #8]                     @ 08032678
	sub pc, pc, #0x2c8                   @ 0803267C  -> seq_track_yield

@ ------------------------------------------------------------------
@ ev_nop   ROM 0x08032680 / IWRAM 0x030035F8 (ARM)
@ cmd 12: no operation.
@ ------------------------------------------------------------------
ev_nop:
	sub pc, pc, #0x300                   @ 08032680  -> L_8032388

@ ------------------------------------------------------------------
@ udiv_32_16   ROM 0x08032684 / IWRAM 0x030035FC (ARM)
@ Unsigned r0/r1 with r0 < r1<<16. Out: r0 = quotient (16 bit), r1 = remainder.
@ ------------------------------------------------------------------
udiv_32_16:
	rsb r1, r1, #0                       @ 08032684
	lsls r1, r1, #0xf                    @ 08032688
	adds r0, r1, r0                      @ 0803268C
	rsblo r0, r1, r0                     @ 08032690
	adcs r0, r1, r0, lsl #1              @ 08032694
	rsblo r0, r1, r0                     @ 08032698
	adcs r0, r1, r0, lsl #1              @ 0803269C
	rsblo r0, r1, r0                     @ 080326A0
	adcs r0, r1, r0, lsl #1              @ 080326A4
	rsblo r0, r1, r0                     @ 080326A8
	adcs r0, r1, r0, lsl #1              @ 080326AC
	rsblo r0, r1, r0                     @ 080326B0
	adcs r0, r1, r0, lsl #1              @ 080326B4
	rsblo r0, r1, r0                     @ 080326B8
	adcs r0, r1, r0, lsl #1              @ 080326BC
	rsblo r0, r1, r0                     @ 080326C0
	adcs r0, r1, r0, lsl #1              @ 080326C4
	rsblo r0, r1, r0                     @ 080326C8
	adcs r0, r1, r0, lsl #1              @ 080326CC
	rsblo r0, r1, r0                     @ 080326D0
	adcs r0, r1, r0, lsl #1              @ 080326D4
	rsblo r0, r1, r0                     @ 080326D8
	adcs r0, r1, r0, lsl #1              @ 080326DC
	rsblo r0, r1, r0                     @ 080326E0
	adcs r0, r1, r0, lsl #1              @ 080326E4
	rsblo r0, r1, r0                     @ 080326E8
	adcs r0, r1, r0, lsl #1              @ 080326EC
	rsblo r0, r1, r0                     @ 080326F0
	adcs r0, r1, r0, lsl #1              @ 080326F4
	rsblo r0, r1, r0                     @ 080326F8
	adcs r0, r1, r0, lsl #1              @ 080326FC
	rsblo r0, r1, r0                     @ 08032700
	adcs r0, r1, r0, lsl #1              @ 08032704
	rsblo r0, r1, r0                     @ 08032708
	adc r0, r0, r0                       @ 0803270C
	lsr r1, r0, #0x10                    @ 08032710
	bic r0, r0, r1, lsl #16              @ 08032714
	bx lr                                @ 08032718

@ ------------------------------------------------------------------
@ sdiv_64_32   ROM 0x0803271C / IWRAM 0x03003694 (ARM)
@ Signed 64/32 division: (r0:r1) / r2. Out: r1 = quotient, r0 = remainder.
@ ------------------------------------------------------------------
sdiv_64_32:
	movs r3, r2                          @ 0803271C
	rsbpl r2, r2, #0                     @ 08032720
	lsr r3, r3, #1                       @ 08032724
	eors r3, r3, r0, asr #1              @ 08032728
	bpl L_8032738                        @ 0803272C
	rsbs r1, r1, #0                      @ 08032730
	rsc r0, r0, #0                       @ 08032734
L_8032738:
	adds r1, r1, r1                      @ 08032738
	adcs r0, r2, r0, lsl #1              @ 0803273C
	rsblo r0, r2, r0                     @ 08032740
	adcs r1, r1, r1                      @ 08032744
	adcs r0, r2, r0, lsl #1              @ 08032748
	rsblo r0, r2, r0                     @ 0803274C
	adcs r1, r1, r1                      @ 08032750
	adcs r0, r2, r0, lsl #1              @ 08032754
	rsblo r0, r2, r0                     @ 08032758
	adcs r1, r1, r1                      @ 0803275C
	adcs r0, r2, r0, lsl #1              @ 08032760
	rsblo r0, r2, r0                     @ 08032764
	adcs r1, r1, r1                      @ 08032768
	adcs r0, r2, r0, lsl #1              @ 0803276C
	rsblo r0, r2, r0                     @ 08032770
	adcs r1, r1, r1                      @ 08032774
	adcs r0, r2, r0, lsl #1              @ 08032778
	rsblo r0, r2, r0                     @ 0803277C
	adcs r1, r1, r1                      @ 08032780
	adcs r0, r2, r0, lsl #1              @ 08032784
	rsblo r0, r2, r0                     @ 08032788
	adcs r1, r1, r1                      @ 0803278C
	adcs r0, r2, r0, lsl #1              @ 08032790
	rsblo r0, r2, r0                     @ 08032794
	adcs r1, r1, r1                      @ 08032798
	adcs r0, r2, r0, lsl #1              @ 0803279C
	rsblo r0, r2, r0                     @ 080327A0
	adcs r1, r1, r1                      @ 080327A4
	adcs r0, r2, r0, lsl #1              @ 080327A8
	rsblo r0, r2, r0                     @ 080327AC
	adcs r1, r1, r1                      @ 080327B0
	adcs r0, r2, r0, lsl #1              @ 080327B4
	rsblo r0, r2, r0                     @ 080327B8
	adcs r1, r1, r1                      @ 080327BC
	adcs r0, r2, r0, lsl #1              @ 080327C0
	rsblo r0, r2, r0                     @ 080327C4
	adcs r1, r1, r1                      @ 080327C8
	adcs r0, r2, r0, lsl #1              @ 080327CC
	rsblo r0, r2, r0                     @ 080327D0
	adcs r1, r1, r1                      @ 080327D4
	adcs r0, r2, r0, lsl #1              @ 080327D8
	rsblo r0, r2, r0                     @ 080327DC
	adcs r1, r1, r1                      @ 080327E0
	adcs r0, r2, r0, lsl #1              @ 080327E4
	rsblo r0, r2, r0                     @ 080327E8
	adcs r1, r1, r1                      @ 080327EC
	adcs r0, r2, r0, lsl #1              @ 080327F0
	rsblo r0, r2, r0                     @ 080327F4
	adcs r1, r1, r1                      @ 080327F8
	adcs r0, r2, r0, lsl #1              @ 080327FC
	rsblo r0, r2, r0                     @ 08032800
	adcs r1, r1, r1                      @ 08032804
	adcs r0, r2, r0, lsl #1              @ 08032808
	rsblo r0, r2, r0                     @ 0803280C
	adcs r1, r1, r1                      @ 08032810
	adcs r0, r2, r0, lsl #1              @ 08032814
	rsblo r0, r2, r0                     @ 08032818
	adcs r1, r1, r1                      @ 0803281C
	adcs r0, r2, r0, lsl #1              @ 08032820
	rsblo r0, r2, r0                     @ 08032824
	adcs r1, r1, r1                      @ 08032828
	adcs r0, r2, r0, lsl #1              @ 0803282C
	rsblo r0, r2, r0                     @ 08032830
	adcs r1, r1, r1                      @ 08032834
	adcs r0, r2, r0, lsl #1              @ 08032838
	rsblo r0, r2, r0                     @ 0803283C
	adcs r1, r1, r1                      @ 08032840
	adcs r0, r2, r0, lsl #1              @ 08032844
	rsblo r0, r2, r0                     @ 08032848
	adcs r1, r1, r1                      @ 0803284C
	adcs r0, r2, r0, lsl #1              @ 08032850
	rsblo r0, r2, r0                     @ 08032854
	adcs r1, r1, r1                      @ 08032858
	adcs r0, r2, r0, lsl #1              @ 0803285C
	rsblo r0, r2, r0                     @ 08032860
	adcs r1, r1, r1                      @ 08032864
	adcs r0, r2, r0, lsl #1              @ 08032868
	rsblo r0, r2, r0                     @ 0803286C
	adcs r1, r1, r1                      @ 08032870
	adcs r0, r2, r0, lsl #1              @ 08032874
	rsblo r0, r2, r0                     @ 08032878
	adcs r1, r1, r1                      @ 0803287C
	adcs r0, r2, r0, lsl #1              @ 08032880
	rsblo r0, r2, r0                     @ 08032884
	adcs r1, r1, r1                      @ 08032888
	adcs r0, r2, r0, lsl #1              @ 0803288C
	rsblo r0, r2, r0                     @ 08032890
	adcs r1, r1, r1                      @ 08032894
	adcs r0, r2, r0, lsl #1              @ 08032898
	rsblo r0, r2, r0                     @ 0803289C
	adcs r1, r1, r1                      @ 080328A0
	adcs r0, r2, r0, lsl #1              @ 080328A4
	rsblo r0, r2, r0                     @ 080328A8
	adcs r1, r1, r1                      @ 080328AC
	adcs r0, r2, r0, lsl #1              @ 080328B0
	rsblo r0, r2, r0                     @ 080328B4
	adcs r1, r1, r1                      @ 080328B8
	lsls r3, r3, #1                      @ 080328BC
	rsbmi r1, r1, #0                     @ 080328C0
	rsbhs r0, r0, #0                     @ 080328C4
	bx lr                                @ 080328C8
lit_80328CC:
	.word cfg_chan_pool_bytes
lit_80328D0:
	.word music_voices
lit_80328D4:
	.word cfg_chan_pool_bytes
lit_80328D8:
	.word chan_mod
lit_80328DC:
	.word chan_volume
lit_80328E0:
	.word chan_cc100
lit_80328E4:
	.word seq_loop_ptr
lit_80328E8:
	.word seq_loop_ptr
lit_80328EC:
	.word chan_mono
lit_80328F0:
	.word chan_mono
lit_80328F4:
	.word seq_prog_map_ptr
lit_80328F8:
	.word seq_inst_table_ptr
lit_80328FC:
	.word chan_instrument
lit_8032900:
	.word chan_bend

@ ------------------------------------------------------------------
@ mix_voice   ROM 0x08032904 / IWRAM 0x0300387C (ARM)
@ Mix one voice into the s16 buffer at r5 with linear interpolation. Volume =
@ master * (chan_volume+1)/128 * vel/128 * env/2^19 (SFX: sfx_master * vol/128 * env).
@ The first voice of a frame stores, later voices add. Position is NOT written back.
@ ------------------------------------------------------------------
mix_voice:
	str lr, [sp, #0x1c]                  @ 08032904
	str r0, [sp, #0x20]                  @ 08032908
	bl calc_pitch                        @ 0803290C
	str r7, [r0, #8]                     @ 08032910
	ldrsb r6, [r0, #6]                   @ 08032914
	cmp r6, #0                           @ 08032918
	ldr r1, lit_8032C24                  @ 0803291C  = sfx_master_volume
	bmi L_8032928                        @ 08032920
	ldr r1, lit_8032C28                  @ 08032924  = music_master_volume
L_8032928:
	ldr r4, [r1]                         @ 08032928
	bmi L_8032944                        @ 0803292C
	ldr r3, lit_8032C2C                  @ 08032930  = chan_volume
	ldrb r3, [r3, r6]                    @ 08032934
	add r3, r3, #1                       @ 08032938
	mul r4, r3, r4                       @ 0803293C
	lsr r4, r4, #7                       @ 08032940
L_8032944:
	ldrb r3, [r0, #3]                    @ 08032944
	mul r4, r3, r4                       @ 08032948
	lsr r4, r4, #7                       @ 0803294C
	ldr sb, [r0, #0x14]                  @ 08032950
	mul r4, sb, r4                       @ 08032954
	lsr r4, r4, #0x13                    @ 08032958
	ldr r6, [r0, #0x24]                  @ 0803295C
	umull sb, sl, r6, r7                 @ 08032960
	lsr r7, sb, #0x10                    @ 08032964
	add r7, r7, sl, lsl #16              @ 08032968
	mov r6, #0                           @ 0803296C
	mov r3, #0                           @ 08032970
	ldr sb, lit_8032C30                  @ 08032974  = mix_samples_per_frame
	ldr sb, [sb]                         @ 08032978
	add sb, r5, sb, lsl #1               @ 0803297C
	ldr r6, [r0, #0x10]                  @ 08032980
	ldr sl, [r0, #0x20]                  @ 08032984
	ldr sl, [sl, #0x18]                  @ 08032988
	ldr r0, [r0, #0xc]                   @ 0803298C
	ldr fp, lit_8032C34                  @ 08032990  = 0x007FFFFF
	ldr r3, lit_8032C38                  @ 08032994  = mix_max_voices
	ldr r3, [r3]                         @ 08032998
	ldr r8, [sp, #0x10]                  @ 0803299C
	cmp r3, r8                           @ 080329A0
	bne L_80329E8                        @ 080329A4
L_80329A8:
	ldrsb r1, [r0]                       @ 080329A8
	ldrsb r2, [r0, #1]                   @ 080329AC
	sub r2, r2, r1                       @ 080329B0
	mul r3, r6, r2                       @ 080329B4
	add r1, r1, r3, asr #23              @ 080329B8  linear interpolation
	mul r2, r1, r4                       @ 080329BC
	asr r2, r2, #7                       @ 080329C0
	strh r2, [r5], #2                    @ 080329C4
	add r6, r6, r7                       @ 080329C8
	add r0, r0, r6, lsr #23              @ 080329CC
	and r6, r6, fp                       @ 080329D0
	cmp r0, sl                           @ 080329D4
	blge mix_voice_sample_end            @ 080329D8
	cmp r5, sb                           @ 080329DC
	bne L_80329A8                        @ 080329E0
	b L_8032AB4                          @ 080329E4
L_80329E8:
	ldrsb r1, [r0]                       @ 080329E8
	ldrsb r2, [r0, #1]                   @ 080329EC
	sub r2, r2, r1                       @ 080329F0
	mul r3, r6, r2                       @ 080329F4
	add r1, r1, r3, asr #23              @ 080329F8
	mul r2, r1, r4                       @ 080329FC
	ldrsh r1, [r5]                       @ 08032A00
	add r1, r1, r2, asr #7               @ 08032A04
	strh r1, [r5], #2                    @ 08032A08
	add r6, r6, r7                       @ 08032A0C
	add r0, r0, r6, lsr #23              @ 08032A10
	and r6, r6, fp                       @ 08032A14
	cmp r0, sl                           @ 08032A18
	blge mix_voice_sample_end            @ 08032A1C
	ldrsb r1, [r0]                       @ 08032A20
	ldrsb r2, [r0, #1]                   @ 08032A24
	sub r2, r2, r1                       @ 08032A28
	mul r3, r6, r2                       @ 08032A2C
	add r1, r1, r3, asr #23              @ 08032A30
	mul r2, r1, r4                       @ 08032A34
	ldrsh r1, [r5]                       @ 08032A38
	add r1, r1, r2, asr #7               @ 08032A3C
	strh r1, [r5], #2                    @ 08032A40
	add r6, r6, r7                       @ 08032A44
	add r0, r0, r6, lsr #23              @ 08032A48
	and r6, r6, fp                       @ 08032A4C
	cmp r0, sl                           @ 08032A50
	blge mix_voice_sample_end            @ 08032A54
	cmp r5, sb                           @ 08032A58
	bne L_80329E8                        @ 08032A5C
	b L_8032AB4                          @ 08032A60

@ mix_voice_sample_end: end of sample reached while mixing
mix_voice_sample_end:
	ldr r8, [sp, #0x20]                  @ 08032A64
	ldrb r3, [r8, #1]                    @ 08032A68
	cmp r3, #1                           @ 08032A6C
	beq L_8032A8C                        @ 08032A70
	cmp r3, #2                           @ 08032A74
	beq L_8032AA4                        @ 08032A78
	cmp r3, #3                           @ 08032A7C
	beq L_8032A98                        @ 08032A80
	cmp r3, #4                           @ 08032A84
	beq L_8032AA4                        @ 08032A88
L_8032A8C:
	mov r3, #0x10                        @ 08032A8C
	strb r3, [r8]                        @ 08032A90
	b L_8032AB4                          @ 08032A94
L_8032A98:
	mov r3, #0x10                        @ 08032A98
	strb r3, [r8]                        @ 08032A9C
	b L_8032AB4                          @ 08032AA0
L_8032AA4:
	ldr r3, [r8, #0x20]                  @ 08032AA4
	ldr r3, [r3, #0x14]                  @ 08032AA8
	sub r0, r0, r3                       @ 08032AAC
	bx lr                                @ 08032AB0
L_8032AB4:
	ldr lr, [sp, #0x1c]                  @ 08032AB4
	bx lr                                @ 08032AB8

@ ------------------------------------------------------------------
@ calc_pitch   ROM 0x08032ABC / IWRAM 0x03003A34 (ARM)
@ Return r7 = per-sample step (9.23 fixed) for voice r0: key - root + fine tune (cents)
@ + pitch bend * range + LFO * modwheel * depth, through pitch_table, scaled by the sample
@ rate and mix_pitch_scale (2^38 / mixing rate).
@ ------------------------------------------------------------------
calc_pitch:
	ldr r4, [r0, #0x20]                  @ 08032ABC
	ldr r3, [r4, #0x34]                  @ 08032AC0
	ldr r7, lit_8032C3C                  @ 08032AC4  = 0x028F5C29
	smull r1, r2, r7, r3                 @ 08032AC8
	push {r1, r2}                        @ 08032ACC
	ldrsb r8, [r0, #6]                   @ 08032AD0
	cmp r8, #0                           @ 08032AD4
	bmi L_8032AE0                        @ 08032AD8
	b L_8032AF4                          @ 08032ADC
L_8032AE0:
	mov r1, #0                           @ 08032AE0
	mov r2, #0                           @ 08032AE4
	push {r1, r2}                        @ 08032AE8
	push {r1, r2}                        @ 08032AEC
	b L_8032BC0                          @ 08032AF0
L_8032AF4:
	mov r7, #4                           @ 08032AF4
	ldr r6, lit_8032C40                  @ 08032AF8  = chan_instrument
	mla r2, r8, r7, r6                   @ 08032AFC
	ldr r2, [r2]                         @ 08032B00
	ldr r3, [r2, #0x38]                  @ 08032B04
	mov r7, #0x80000                     @ 08032B08
	mul r3, r7, r3                       @ 08032B0C
	ldrsb r7, [r0, #6]                   @ 08032B10
	ldr r8, lit_8032C44                  @ 08032B14  = chan_bend
	mov r1, #4                           @ 08032B18
	mla r8, r7, r1, r8                   @ 08032B1C
	ldr r7, [r8]                         @ 08032B20
	sub r7, r7, #0x2000                  @ 08032B24
	smull r1, r2, r7, r3                 @ 08032B28
	push {r1, r2}                        @ 08032B2C
	ldrsb r8, [r0, #6]                   @ 08032B30
	mov r7, #4                           @ 08032B34
	ldr r6, lit_8032C48                  @ 08032B38  = chan_instrument
	mla r2, r8, r7, r6                   @ 08032B3C
	ldr r2, [r2]                         @ 08032B40
	ldr r2, [r2, #0x40]                  @ 08032B44
	ldrsb r8, [r0, #6]                   @ 08032B48
	mov r7, #8                           @ 08032B4C
	ldr sb, lit_8032C4C                  @ 08032B50  = chan_mod
	mla r8, r7, r8, sb                   @ 08032B54
	mov r1, #0                           @ 08032B58
	mov r2, #0                           @ 08032B5C
	ldr sb, [r8]                         @ 08032B60
	cmp sb, #0                           @ 08032B64
	beq L_8032BBC                        @ 08032B68
	ldr r7, [r8, #4]                     @ 08032B6C
	lsr r1, r7, #0x10                    @ 08032B70
	sub r7, r7, r1, lsl #16              @ 08032B74
	ldr r6, lit_8032C50                  @ 08032B78  = lfo_sine_table
	add r6, r6, r1, lsl #2               @ 08032B7C
	ldm r6, {r1, r2}                     @ 08032B80
	sub r2, r2, r1                       @ 08032B84
	smull r6, r7, r2, r7                 @ 08032B88
	lsl r7, r7, #0x10                    @ 08032B8C
	add r7, r7, r6, lsr #16              @ 08032B90
	add r1, r1, r7                       @ 08032B94
	add sb, sb, #1                       @ 08032B98
	mul sb, r1, sb                       @ 08032B9C
	ldrsb r8, [r0, #6]                   @ 08032BA0
	mov r7, #4                           @ 08032BA4
	ldr r6, lit_8032C54                  @ 08032BA8  = chan_instrument
	mla r2, r8, r7, r6                   @ 08032BAC
	ldr r2, [r2]                         @ 08032BB0
	ldr r2, [r2, #0x40]                  @ 08032BB4
	smull r1, r2, sb, r2                 @ 08032BB8
L_8032BBC:
	push {r1, r2}                        @ 08032BBC
L_8032BC0:
	pop {r1, r2, r3, r7, r8, sb}         @ 08032BC0
	adds r1, r1, r3                      @ 08032BC4
	adc r2, r2, r7                       @ 08032BC8
	adds r1, r1, r8                      @ 08032BCC
	adc r2, r2, sb                       @ 08032BD0
	ldr r3, [r4, #0xc]                   @ 08032BD4
	ldrb sb, [r0, #5]                    @ 08032BD8
	sub r3, sb, r3                       @ 08032BDC
	add r3, r3, r2                       @ 08032BE0
	ldr r6, lit_8032C58                  @ 08032BE4  = 0x080335AC
	add r2, r6, r3, lsl #2               @ 08032BE8
	ldm r2, {r3, r7}                     @ 08032BEC
	sub r2, r7, r3                       @ 08032BF0
	umull sb, sl, r1, r2                 @ 08032BF4
	add r7, r3, sl                       @ 08032BF8
	ldr r1, lit_8032C5C                  @ 08032BFC  = mix_pitch_scale
	ldr r1, [r1]                         @ 08032C00
	ldr r2, [r4, #8]                     @ 08032C04
	umull r8, sb, r1, r2                 @ 08032C08
	lsr r8, r8, #0xe                     @ 08032C0C
	add r8, r8, sb, lsl #18              @ 08032C10
	umull sl, r4, r7, r8                 @ 08032C14
	lsr sl, sl, #0x18                    @ 08032C18
	orr r7, sl, r4, lsl #8               @ 08032C1C
	bx lr                                @ 08032C20
lit_8032C24:
	.word sfx_master_volume
lit_8032C28:
	.word music_master_volume
lit_8032C2C:
	.word chan_volume
lit_8032C30:
	.word mix_samples_per_frame
lit_8032C34:
	.word 0x007FFFFF
lit_8032C38:
	.word mix_max_voices
lit_8032C3C:
	.word 0x028F5C29
lit_8032C40:
	.word chan_instrument
lit_8032C44:
	.word chan_bend
lit_8032C48:
	.word chan_instrument
lit_8032C4C:
	.word chan_mod
lit_8032C50:
	.word lfo_sine_table
lit_8032C54:
	.word chan_instrument
lit_8032C58:
	.word 0x080335AC
lit_8032C5C:
	.word mix_pitch_scale
iwram_code_end:

	.thumb

@ ------------------------------------------------------------------
@ snd_request_song   ROM 0x08032C60 (Thumb)
@ API: r0 = song number. Latched; started at the next snd_frame.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_request_song
snd_request_song:
	push {r4, r5, r6, r7, lr}            @ 08032C60
	mov r3, r8                           @ 08032C62
	mov r4, sb                           @ 08032C64
	mov r5, sl                           @ 08032C66
	mov r6, fp                           @ 08032C68
	mov r7, ip                           @ 08032C6A
	push {r3, r4, r5, r6, r7}            @ 08032C6C
	ldr r1, lit_8032E80                  @ 08032C6E  = seq_pending_song
	str r0, [r1]                         @ 08032C70
	pop {r3, r4, r5, r6, r7}             @ 08032C72
	mov r8, r3                           @ 08032C74
	mov sb, r4                           @ 08032C76
	mov sl, r5                           @ 08032C78
	mov fp, r6                           @ 08032C7A
	mov ip, r7                           @ 08032C7C
	pop {r4, r5, r6, r7}                 @ 08032C7E
	pop {r1}                             @ 08032C80
	bx r1                                @ 08032C82

@ ------------------------------------------------------------------
@ snd_vblank   ROM 0x08032C84 (Thumb)
@ API (V-blank): flip the double buffer and restart DMA1 -> FIFO A on the buffer
@ that was just mixed. Leaf, no stack.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_vblank
snd_vblank:
	ldr r0, lit_8032E84                  @ 08032C84  = dma_buffer_flag
	ldr r2, [r0]                         @ 08032C86
	mvns r2, r2                          @ 08032C88
	str r2, [r0]                         @ 08032C8A
	ldr r1, lit_8032E88                  @ 08032C8C  = cfg_buffer_a
	cmp r2, #0                           @ 08032C8E
	beq L_8032C94                        @ 08032C90
	ldr r1, lit_8032E8C                  @ 08032C92  = cfg_buffer_b
L_8032C94:
	ldr r1, [r1]                         @ 08032C94
	ldr r0, lit_8032E90                  @ 08032C96  = REG_DMA1CNT_H
	movs r2, #0                          @ 08032C98
	strh r2, [r0]                        @ 08032C9A
	ldr r2, lit_8032E94                  @ 08032C9C  = REG_FIFO_A
	ldr r3, lit_8032E98                  @ 08032C9E  = 0xF6000000
	ldr r0, lit_8032E9C                  @ 08032CA0  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 08032CA2
	ldr r0, lit_8032EA0                  @ 08032CA4  = REG_SOUNDCNT_X
	movs r1, #0x80                       @ 08032CA6
	strh r1, [r0]                        @ 08032CA8
	bx lr                                @ 08032CAA

@ ------------------------------------------------------------------
@ snd_init   ROM 0x08032CAC (Thumb)
@ API: one-time init. DirectSound A only, mono, Timer 0, 13379 Hz, 8 mixed voices.
@ Copies the ARM block into IWRAM with DMA2.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_init
snd_init:
	push {r4, r5, r6, r7, lr}            @ 08032CAC
	mov r3, r8                           @ 08032CAE
	mov r4, sb                           @ 08032CB0
	mov r5, sl                           @ 08032CB2
	mov r6, fp                           @ 08032CB4
	mov r7, ip                           @ 08032CB6
	push {r3, r4, r5, r6, r7}            @ 08032CB8
	sub sp, #4                           @ 08032CBA
	ldr r0, lit_8032EA0                  @ 08032CBC  = REG_SOUNDCNT_X
	movs r1, #0                          @ 08032CBE
	strh r1, [r0]                        @ 08032CC0
	ldr r0, lit_8032E90                  @ 08032CC2  = REG_DMA1CNT_H
	movs r2, #0                          @ 08032CC4
	strh r2, [r0]                        @ 08032CC6
	ldr r0, lit_8032EA4                  @ 08032CC8  = REG_TM0CNT_H
	movs r1, #0                          @ 08032CCA
	strh r1, [r0]                        @ 08032CCC
	movs r0, #0                          @ 08032CCE
	str r0, [sp]                         @ 08032CD0
	mov r1, sp                           @ 08032CD2
	ldr r2, lit_8032EA8                  @ 08032CD4  = cfg_buffer_b
	ldr r2, [r2]                         @ 08032CD6
	ldr r3, lit_8032EAC                  @ 08032CD8  = 0x85000038
	ldr r0, lit_8032EB0                  @ 08032CDA  = REG_DMA2SAD
	stm r0!, {r1, r2, r3}                @ 08032CDC
	movs r0, #0                          @ 08032CDE
	str r0, [sp]                         @ 08032CE0
	mov r1, sp                           @ 08032CE2
	ldr r2, lit_8032EB4                  @ 08032CE4  = cfg_buffer_a
	ldr r2, [r2]                         @ 08032CE6
	ldr r3, lit_8032EAC                  @ 08032CE8  = 0x85000038
	ldr r0, lit_8032EB0                  @ 08032CEA  = REG_DMA2SAD
	stm r0!, {r1, r2, r3}                @ 08032CEC
	ldr r0, lit_8032EB8                  @ 08032CEE  = dma_buffer_flag
	movs r1, #0                          @ 08032CF0
	str r1, [r0]                         @ 08032CF2
	movs r1, #0                          @ 08032CF4
	mvns r1, r1                          @ 08032CF6
	ldr r0, lit_8032EBC                  @ 08032CF8  = seq_pending_song
	str r1, [r0]                         @ 08032CFA
	ldr r0, lit_8032EC0                  @ 08032CFC  = seq_current_song
	str r1, [r0]                         @ 08032CFE
	ldr r0, lit_8032EC4                  @ 08032D00  = REG_SOUNDCNT_H
	movs r1, #0                          @ 08032D02
	strh r1, [r0]                        @ 08032D04
	ldrh r1, [r0]                        @ 08032D06
	ldr r2, lit_8032EC8                  @ 08032D08  = 0x00008800 ; FIFO A+B reset
	orrs r1, r2                          @ 08032D0A
	strh r1, [r0]                        @ 08032D0C
	ldr r0, lit_8032E94                  @ 08032D0E  = REG_FIFO_A
	movs r1, #0x80                       @ 08032D10
	strb r1, [r0]                        @ 08032D12
	movs r1, #0x80                       @ 08032D14
	strb r1, [r0, #4]                    @ 08032D16
	ldr r0, lit_8032EC4                  @ 08032D18  = REG_SOUNDCNT_H
	ldr r1, [r0]                         @ 08032D1A
	ldr r2, lit_8032ECC                  @ 08032D1C  = 0x0000030C ; DSA 100%, DSB 100%, DSA L+R, Timer 0
	orrs r1, r2                          @ 08032D1E
	strh r1, [r0]                        @ 08032D20
	ldr r0, lit_8032ED0                  @ 08032D22  = REG_SOUNDBIAS_H
	ldr r1, [r0]                         @ 08032D24
	movs r2, #0xc0                       @ 08032D26
	bics r1, r2                          @ 08032D28
	movs r2, #0x40                       @ 08032D2A
	orrs r1, r2                          @ 08032D2C
	strb r1, [r0]                        @ 08032D2E  SOUNDBIAS: 8-bit / 65.536 kHz PWM
	bl init_music_voices                 @ 08032D30
	bl init_sfx_voices                   @ 08032D34
	movs r0, #0x80                       @ 08032D38
	bl snd_set_music_volume              @ 08032D3A
	movs r0, #0x80                       @ 08032D3E
	bl snd_set_sfx_volume                @ 08032D40
	bl reset_channel_volume              @ 08032D44
	bl reset_mono_flags                  @ 08032D48
	ldr r1, lit_8032ED4                  @ 08032D4C  = voice_start
	ldr r2, lit_8032ED8                  @ 08032D4E  = (voice_start - iwram_code_start + IWRAM_CODE_BASE)
	ldr r3, lit_8032EDC                  @ 08032D50  = iwram_code_size
	ldr r3, [r3]                         @ 08032D52
	ldr r4, lit_8032EE0                  @ 08032D54  = 0x000013EC
	cmp r3, r4                           @ 08032D56
	ble L_8032D5A                        @ 08032D58  dead check (assert stripped): not enough space for audio RAM code
L_8032D5A:
	lsrs r3, r3, #2                      @ 08032D5A
	ldr r0, lit_8032EE4                  @ 08032D5C  = 0x84000000
	orrs r3, r0                          @ 08032D5E
	ldr r0, lit_8032EB0                  @ 08032D60  = REG_DMA2SAD
	stm r0!, {r1, r2, r3}                @ 08032D62
	bl wait_vcount_160                   @ 08032D64
	ldr r0, lit_8032EE8                  @ 08032D68  = song_table_ptr
	ldr r1, lit_8032EEC                  @ 08032D6A  = song_table
	str r1, [r0]                         @ 08032D6C
	ldr r0, lit_8032EF0                  @ 08032D6E  = sfx_table_ptr
	ldr r1, lit_8032EF4                  @ 08032D70  = sfx_table
	str r1, [r0]                         @ 08032D72
	ldr r0, lit_8032EF8                  @ 08032D74  = 0x00003443
	bl snd_set_mix_rate                  @ 08032D76  13379 Hz
	movs r0, #8                          @ 08032D7A
	bl snd_set_max_voices                @ 08032D7C  8 voices
	add sp, #4                           @ 08032D80
	pop {r3, r4, r5, r6, r7}             @ 08032D82
	mov r8, r3                           @ 08032D84
	mov sb, r4                           @ 08032D86
	mov sl, r5                           @ 08032D88
	mov fp, r6                           @ 08032D8A
	mov ip, r7                           @ 08032D8C
	pop {r4, r5, r6, r7}                 @ 08032D8E
	pop {r1}                             @ 08032D90
	bx r1                                @ 08032D92

@ ------------------------------------------------------------------
@ snd_frame   ROM 0x08032D94 (Thumb)
@ API: per-frame update (start pending song, sequencer, LFO, envelopes, mixer).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_frame
snd_frame:
	push {r4, r5, r6, r7, lr}            @ 08032D94
	mov r3, r8                           @ 08032D96
	mov r4, sb                           @ 08032D98
	mov r5, sl                           @ 08032D9A
	mov r6, fp                           @ 08032D9C
	mov r7, ip                           @ 08032D9E
	push {r3, r4, r5, r6, r7}            @ 08032DA0
	ldr r0, lit_8032EFC                  @ 08032DA2  = seq_pending_song
	ldr r1, [r0]                         @ 08032DA4
	cmp r1, #0                           @ 08032DA6
	bmi L_8032E0C                        @ 08032DA8
	movs r2, #0                          @ 08032DAA
	mvns r2, r2                          @ 08032DAC
	str r2, [r0]                         @ 08032DAE
	ldr r0, lit_8032F00                  @ 08032DB0  = seq_current_song
	str r1, [r0]                         @ 08032DB2
	ldr r0, lit_8032F04                  @ 08032DB4  = seq_track_time
	movs r2, #0x80                       @ 08032DB6
	movs r3, #0                          @ 08032DB8
L_8032DBA:
	subs r2, #4                          @ 08032DBA
	str r3, [r0, r2]                     @ 08032DBC
	bne L_8032DBA                        @ 08032DBE
	ldr r0, lit_8032F08                  @ 08032DC0  = song_table_ptr
	ldr r0, [r0]                         @ 08032DC2
	lsls r1, r1, #2                      @ 08032DC4
	ldr r0, [r0, r1]                     @ 08032DC6
	ldr r3, [r0]                         @ 08032DC8
	ldr r2, lit_8032F0C                  @ 08032DCA  = seq_num_tracks
	str r3, [r2]                         @ 08032DCC
	ldr r1, [r0, #4]                     @ 08032DCE
	ldr r2, lit_8032F10                  @ 08032DD0  = seq_division
	str r1, [r2]                         @ 08032DD2
	ldr r1, [r0, #8]                     @ 08032DD4
	ldr r2, lit_8032F14                  @ 08032DD6  = seq_track_ptr
	ldr r4, lit_8032EE4                  @ 08032DD8  = 0x84000000
	orrs r3, r4                          @ 08032DDA
	ldr r4, lit_8032EB0                  @ 08032DDC  = REG_DMA2SAD
	stm r4!, {r1, r2, r3}                @ 08032DDE
	ldr r1, [r0, #0xc]                   @ 08032DE0
	ldr r2, lit_8032F18                  @ 08032DE2  = seq_prog_map_ptr
	str r1, [r2]                         @ 08032DE4
	ldr r1, [r0, #0x10]                  @ 08032DE6
	ldr r2, lit_8032F1C                  @ 08032DE8  = seq_inst_table_ptr
	str r1, [r2]                         @ 08032DEA
	ldr r0, lit_8032F20                  @ 08032DEC  = seq_track_time
	movs r1, #0                          @ 08032DEE
	adds r2, r1, #0                      @ 08032DF0
	stm r0!, {r1, r2}                    @ 08032DF2
	ldr r0, lit_8032F24                  @ 08032DF4  = seq_frame_time
	movs r1, #1                          @ 08032DF6
	str r1, [r0]                         @ 08032DF8
	ldr r0, lit_8032F28                  @ 08032DFA  = seq_tempo
	movs r1, #0                          @ 08032DFC
	str r1, [r0]                         @ 08032DFE
	bl init_music_voices                 @ 08032E00
	bl reset_pitch_bend                  @ 08032E04
	bl reset_modulation                  @ 08032E08
L_8032E0C:
	bl clear_mix_buffer                  @ 08032E0C
	ldr r0, lit_8032F2C                  @ 08032E10  = music_paused
	ldr r1, [r0]                         @ 08032E12
	cmp r1, #1                           @ 08032E14
	beq L_8032E38                        @ 08032E16
	ldr r0, lit_8032F30                  @ 08032E18  = seq_current_song
	ldr r1, [r0]                         @ 08032E1A
	cmp r1, #0                           @ 08032E1C
	bmi L_8032E38                        @ 08032E1E
	mov r0, pc                           @ 08032E20
	adds r0, #7                          @ 08032E22
	mov lr, r0                           @ 08032E24
	ldr r0, lit_8032F34                  @ 08032E26  = (seq_update - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08032E28
L_8032E2A:
	bl lfo_update                        @ 08032E2A
	mov r0, pc                           @ 08032E2E
	adds r0, #7                          @ 08032E30
	mov lr, r0                           @ 08032E32
	ldr r0, lit_8032F38                  @ 08032E34  = (env_update_music - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08032E36
L_8032E38:
	bl sfx_timer_update                  @ 08032E38
	mov r0, pc                           @ 08032E3C
	adds r0, #7                          @ 08032E3E
	mov lr, r0                           @ 08032E40
	ldr r0, lit_8032F3C                  @ 08032E42  = (env_update_sfx - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08032E44
L_8032E46:
	mov r0, pc                           @ 08032E46
	adds r0, #7                          @ 08032E48
	mov lr, r0                           @ 08032E4A
	ldr r0, lit_8032F40                  @ 08032E4C  = (mix_frame - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08032E4E
L_8032E50:
	ldr r0, lit_8032F44                  @ 08032E50  = music_paused
	ldr r1, [r0]                         @ 08032E52
	cmp r1, #1                           @ 08032E54
	beq L_8032E62                        @ 08032E56
	mov r0, pc                           @ 08032E58
	adds r0, #7                          @ 08032E5A
	mov lr, r0                           @ 08032E5C
	ldr r0, lit_8032F48                  @ 08032E5E  = (advance_music_voices - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08032E60
L_8032E62:
	mov r0, pc                           @ 08032E62
	adds r0, #7                          @ 08032E64
	mov lr, r0                           @ 08032E66
	ldr r0, lit_8032F4C                  @ 08032E68  = (advance_sfx_voices - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08032E6A
L_8032E6C:
	pop {r3, r4, r5, r6, r7}             @ 08032E6C
	mov r8, r3                           @ 08032E6E
	mov sb, r4                           @ 08032E70
	mov sl, r5                           @ 08032E72
	mov fp, r6                           @ 08032E74
	mov ip, r7                           @ 08032E76
	pop {r4, r5, r6, r7}                 @ 08032E78
	pop {r1}                             @ 08032E7A
	bx r1                                @ 08032E7C
	.hword 0x0000
lit_8032E80:
	.word seq_pending_song
lit_8032E84:
	.word dma_buffer_flag
lit_8032E88:
	.word cfg_buffer_a
lit_8032E8C:
	.word cfg_buffer_b
lit_8032E90:
	.word REG_DMA1CNT_H
lit_8032E94:
	.word REG_FIFO_A
lit_8032E98:
	.word 0xF6000000
lit_8032E9C:
	.word REG_DMA1SAD
lit_8032EA0:
	.word REG_SOUNDCNT_X
lit_8032EA4:
	.word REG_TM0CNT_H
lit_8032EA8:
	.word cfg_buffer_b
lit_8032EAC:
	.word 0x85000038
lit_8032EB0:
	.word REG_DMA2SAD
lit_8032EB4:
	.word cfg_buffer_a
lit_8032EB8:
	.word dma_buffer_flag
lit_8032EBC:
	.word seq_pending_song
lit_8032EC0:
	.word seq_current_song
lit_8032EC4:
	.word REG_SOUNDCNT_H
lit_8032EC8:
	.word 0x00008800
lit_8032ECC:
	.word 0x0000030C
lit_8032ED0:
	.word REG_SOUNDBIAS_H
lit_8032ED4:
	.word voice_start
lit_8032ED8:
	.word (voice_start - iwram_code_start + IWRAM_CODE_BASE)
lit_8032EDC:
	.word iwram_code_size
lit_8032EE0:
	.word 0x000013EC
lit_8032EE4:
	.word 0x84000000
lit_8032EE8:
	.word song_table_ptr
lit_8032EEC:
	.word song_table
lit_8032EF0:
	.word sfx_table_ptr
lit_8032EF4:
	.word sfx_table
lit_8032EF8:
	.word 0x00003443
lit_8032EFC:
	.word seq_pending_song
lit_8032F00:
	.word seq_current_song
lit_8032F04:
	.word seq_track_time
lit_8032F08:
	.word song_table_ptr
lit_8032F0C:
	.word seq_num_tracks
lit_8032F10:
	.word seq_division
lit_8032F14:
	.word seq_track_ptr
lit_8032F18:
	.word seq_prog_map_ptr
lit_8032F1C:
	.word seq_inst_table_ptr
lit_8032F20:
	.word seq_track_time
lit_8032F24:
	.word seq_frame_time
lit_8032F28:
	.word seq_tempo
lit_8032F2C:
	.word music_paused
lit_8032F30:
	.word seq_current_song
lit_8032F34:
	.word (seq_update - iwram_code_start + IWRAM_CODE_BASE)
lit_8032F38:
	.word (env_update_music - iwram_code_start + IWRAM_CODE_BASE)
lit_8032F3C:
	.word (env_update_sfx - iwram_code_start + IWRAM_CODE_BASE)
lit_8032F40:
	.word (mix_frame - iwram_code_start + IWRAM_CODE_BASE)
lit_8032F44:
	.word music_paused
lit_8032F48:
	.word (advance_music_voices - iwram_code_start + IWRAM_CODE_BASE)
lit_8032F4C:
	.word (advance_sfx_voices - iwram_code_start + IWRAM_CODE_BASE)

@ ------------------------------------------------------------------
@ lfo_update   ROM 0x08032F50 (Thumb)
@ Advance the LFO phase of every channel whose mod wheel is non-zero.
@ ------------------------------------------------------------------
	.thumb_func
lfo_update:
	ldr r0, lit_80331D4                  @ 08032F50  = chan_mod-8
	ldr r7, lit_80331D8                  @ 08032F52  = chan_mod-4
	movs r1, #0x80                       @ 08032F54
	movs r6, #0                          @ 08032F56
L_8032F58:
	ldr r2, [r0, r1]                     @ 08032F58
	cmp r2, #0                           @ 08032F5A
	bne L_8032F66                        @ 08032F5C
	str r6, [r7, r1]                     @ 08032F5E
L_8032F60:
	subs r1, #8                          @ 08032F60
	bne L_8032F58                        @ 08032F62
	bx lr                                @ 08032F64
L_8032F66:
	lsrs r3, r1, #3                      @ 08032F66
	subs r3, #1                          @ 08032F68
	ldr r4, lit_80331DC                  @ 08032F6A  = chan_instrument
	movs r5, #4                          @ 08032F6C
	muls r5, r3, r5                      @ 08032F6E
	ldr r3, [r4, r5]                     @ 08032F70
	ldr r3, [r3, #0x3c]                  @ 08032F72
	adds r4, r0, r1                      @ 08032F74
	ldr r5, [r4, #4]                     @ 08032F76
	adds r3, r5, r3                      @ 08032F78
	ldr r5, lit_80331E0                  @ 08032F7A  = 0x00FFFFFF
	ands r3, r5                          @ 08032F7C
	str r3, [r4, #4]                     @ 08032F7E
	b L_8032F60                          @ 08032F80

@ ------------------------------------------------------------------
@ sfx_timer_update   ROM 0x08032F82 (Thumb)
@ Count down SFX auto-release timers; at zero the voice is keyed off.
@ ------------------------------------------------------------------
	.thumb_func
sfx_timer_update:
	ldr r5, lit_80331E4                  @ 08032F82  = sfx_voices
	movs r3, #0                          @ 08032F84
	ldr r6, lit_80331E8                  @ 08032F86  = cfg_sfx_pool_bytes
	ldr r6, [r6]                         @ 08032F88
	ldr r0, lit_80331EC                  @ 08032F8A  = sfx_timer
L_8032F8C:
	ldrb r4, [r5, r3]                    @ 08032F8C
	cmp r4, #0x11                        @ 08032F8E
	beq L_8032F9C                        @ 08032F90
L_8032F92:
	adds r0, #4                          @ 08032F92
	adds r3, #0x28                       @ 08032F94
	cmp r3, r6                           @ 08032F96
	blt L_8032F8C                        @ 08032F98
	bx lr                                @ 08032F9A
L_8032F9C:
	ldr r1, [r0]                         @ 08032F9C
	subs r1, #1                          @ 08032F9E
	bmi L_8032FAA                        @ 08032FA0
	str r1, [r0]                         @ 08032FA2
	bne L_8032FAA                        @ 08032FA4
	movs r1, #0x12                       @ 08032FA6
	strb r1, [r5, r3]                    @ 08032FA8
L_8032FAA:
	b L_8032F92                          @ 08032FAA

@ ------------------------------------------------------------------
@ sfx_start_voice   ROM 0x08032FAC (Thumb)
@ Allocate an SFX voice (free, else released). In: r0 = sfx id, r1 = volume,
@ r2 = pitch mult (16.16). Out: r0 = handle (-1 if none), r1 = voice index.
@ ------------------------------------------------------------------
	.thumb_func
sfx_start_voice:
	push {lr}                            @ 08032FAC
	ldr r5, lit_80331F0                  @ 08032FAE  = sfx_voices
	movs r3, #0                          @ 08032FB0
	ldr r6, lit_80331F4                  @ 08032FB2  = cfg_sfx_pool_bytes
	ldr r6, [r6]                         @ 08032FB4
L_8032FB6:
	ldrb r4, [r5, r3]                    @ 08032FB6
	cmp r4, #0x10                        @ 08032FB8
	beq L_8032FD8                        @ 08032FBA
	adds r3, #0x28                       @ 08032FBC
	cmp r3, r6                           @ 08032FBE
	blt L_8032FB6                        @ 08032FC0
	movs r3, #0                          @ 08032FC2
L_8032FC4:
	ldrb r4, [r5, r3]                    @ 08032FC4
	cmp r4, #0x12                        @ 08032FC6
	beq L_8032FD8                        @ 08032FC8
	adds r3, #0x28                       @ 08032FCA
	cmp r3, r6                           @ 08032FCC
	blt L_8032FC4                        @ 08032FCE
	movs r1, #0                          @ 08032FD0
	mvns r1, r1                          @ 08032FD2
	adds r0, r1, #0                      @ 08032FD4
	b L_8033026                          @ 08032FD6
L_8032FD8:
	adds r5, r5, r3                      @ 08032FD8
	movs r4, #0                          @ 08032FDA
	mvns r4, r4                          @ 08032FDC
	adds r3, #0x28                       @ 08032FDE
L_8032FE0:
	adds r4, #1                          @ 08032FE0
	subs r3, #0x28                       @ 08032FE2
	bne L_8032FE0                        @ 08032FE4
	push {r4}                            @ 08032FE6
	ldr r3, lit_80331F8                  @ 08032FE8  = sfx_handle_counter
	ldr r7, [r3]                         @ 08032FEA
	adds r7, #1                          @ 08032FEC
	movs r6, #1                          @ 08032FEE
	cmn r7, r6                           @ 08032FF0
	bne L_8032FF6                        @ 08032FF2
	adds r7, #1                          @ 08032FF4
L_8032FF6:
	str r7, [r3]                         @ 08032FF6
	ldr r3, lit_80331FC                  @ 08032FF8  = sfx_handle
	lsls r4, r4, #2                      @ 08032FFA
	str r7, [r3, r4]                     @ 08032FFC
	push {r7}                            @ 08032FFE
	lsls r0, r0, #2                      @ 08033000
	ldr r4, lit_8033200                  @ 08033002  = sfx_table_ptr
	ldr r4, [r4]                         @ 08033004
	ldr r3, [r4, r0]                     @ 08033006
	ldr r0, [r3, #0xc]                   @ 08033008
	mov sb, r0                           @ 0803300A
	adds r4, r0, #0                      @ 0803300C
	ldr r7, [r3, #4]                     @ 0803300E
	mov r8, r1                           @ 08033010
	adds r1, r2, #0                      @ 08033012
	adds r2, r3, #0                      @ 08033014
	mov r3, r8                           @ 08033016
	mov r0, pc                           @ 08033018
	adds r0, #7                          @ 0803301A
	mov lr, r0                           @ 0803301C
	ldr r0, lit_8033204                  @ 0803301E  = (voice_start - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08033020
L_8033022:
	pop {r0}                             @ 08033022
	pop {r1}                             @ 08033024
L_8033026:
	pop {r2}                             @ 08033026
	bx r2                                @ 08033028

@ ------------------------------------------------------------------
@ snd_sfx_is_playing   ROM 0x0803302A (Thumb)
@ API: r0 = handle -> r0 = 1 if a voice still carries that handle.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_is_playing
snd_sfx_is_playing:
	push {r4, r5, r6, r7, lr}            @ 0803302A
	mov r3, r8                           @ 0803302C
	mov r4, sb                           @ 0803302E
	mov r5, sl                           @ 08033030
	mov r6, fp                           @ 08033032
	mov r7, ip                           @ 08033034
	push {r3, r4, r5, r6, r7}            @ 08033036
	bl sfx_find_handle                   @ 08033038
	pop {r3, r4, r5, r6, r7}             @ 0803303C
	mov r8, r3                           @ 0803303E
	mov sb, r4                           @ 08033040
	mov sl, r5                           @ 08033042
	mov fp, r6                           @ 08033044
	mov ip, r7                           @ 08033046
	pop {r4, r5, r6, r7}                 @ 08033048
	pop {r1}                             @ 0803304A
	bx r1                                @ 0803304C

@ ------------------------------------------------------------------
@ sfx_find_handle   ROM 0x0803304E (Thumb)
@ Out: r0 = 1 and r3 = byte offset of the voice holding handle r0, else r0 = 0.
@ ------------------------------------------------------------------
	.thumb_func
sfx_find_handle:
	movs r6, #0                          @ 0803304E
	ldr r2, lit_8033208                  @ 08033050  = sfx_voices
	movs r3, #0                          @ 08033052
	ldr r5, lit_803320C                  @ 08033054  = cfg_sfx_pool_bytes
	ldr r5, [r5]                         @ 08033056
L_8033058:
	ldrb r4, [r2, r3]                    @ 08033058
	cmp r4, #0x10                        @ 0803305A
	bne L_803306A                        @ 0803305C
L_803305E:
	adds r3, #0x28                       @ 0803305E
	adds r6, #4                          @ 08033060
	cmp r3, r5                           @ 08033062
	blt L_8033058                        @ 08033064
	movs r0, #0                          @ 08033066
	mov pc, lr                           @ 08033068
L_803306A:
	ldr r4, lit_8033210                  @ 0803306A  = sfx_handle
	ldr r4, [r4, r6]                     @ 0803306C
	cmp r0, r4                           @ 0803306E
	bne L_803305E                        @ 08033070
	movs r0, #1                          @ 08033072
	mov pc, lr                           @ 08033074

@ ------------------------------------------------------------------
@ snd_sfx_set_pitch   ROM 0x08033076 (Thumb)
@ API: r0 = handle, r1 = pitch multiplier (16.16).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_set_pitch
snd_sfx_set_pitch:
	push {r4, r5, r6, r7, lr}            @ 08033076
	mov r3, r8                           @ 08033078
	mov r4, sb                           @ 0803307A
	mov r5, sl                           @ 0803307C
	mov r6, fp                           @ 0803307E
	mov r7, ip                           @ 08033080
	push {r3, r4, r5, r6, r7}            @ 08033082
	bl sfx_find_handle                   @ 08033084
	cmp r0, #0                           @ 08033088
	beq L_8033090                        @ 0803308A
	ldr r2, lit_8033214                  @ 0803308C  = sfx_voices+0x24
	str r1, [r2, r3]                     @ 0803308E
L_8033090:
	pop {r3, r4, r5, r6, r7}             @ 08033090
	mov r8, r3                           @ 08033092
	mov sb, r4                           @ 08033094
	mov sl, r5                           @ 08033096
	mov fp, r6                           @ 08033098
	mov ip, r7                           @ 0803309A
	pop {r4, r5, r6, r7}                 @ 0803309C
	pop {r1}                             @ 0803309E
	bx r1                                @ 080330A0

@ ------------------------------------------------------------------
@ snd_sfx_set_volume   ROM 0x080330A2 (Thumb)
@ API: r0 = handle, r1 = volume (0-128).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_set_volume
snd_sfx_set_volume:
	push {r4, r5, r6, r7, lr}            @ 080330A2
	mov r3, r8                           @ 080330A4
	mov r4, sb                           @ 080330A6
	mov r5, sl                           @ 080330A8
	mov r6, fp                           @ 080330AA
	mov r7, ip                           @ 080330AC
	push {r3, r4, r5, r6, r7}            @ 080330AE
	bl sfx_find_handle                   @ 080330B0
	cmp r0, #0                           @ 080330B4
	beq L_80330BC                        @ 080330B6
	ldr r2, lit_8033218                  @ 080330B8  = sfx_voices+0x3
	strb r1, [r2, r3]                    @ 080330BA
L_80330BC:
	pop {r3, r4, r5, r6, r7}             @ 080330BC
	mov r8, r3                           @ 080330BE
	mov sb, r4                           @ 080330C0
	mov sl, r5                           @ 080330C2
	mov fp, r6                           @ 080330C4
	mov ip, r7                           @ 080330C6
	pop {r4, r5, r6, r7}                 @ 080330C8
	pop {r1}                             @ 080330CA
	bx r1                                @ 080330CC

@ ------------------------------------------------------------------
@ snd_sfx_stop   ROM 0x080330CE (Thumb)
@ API: r0 = handle. Frees the voice immediately (no release).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_stop
snd_sfx_stop:
	push {r4, r5, r6, r7, lr}            @ 080330CE
	mov r3, r8                           @ 080330D0
	mov r4, sb                           @ 080330D2
	mov r5, sl                           @ 080330D4
	mov r6, fp                           @ 080330D6
	mov r7, ip                           @ 080330D8
	push {r3, r4, r5, r6, r7}            @ 080330DA
	bl sfx_find_handle                   @ 080330DC
	cmp r0, #0                           @ 080330E0
	beq L_80330EA                        @ 080330E2
	ldr r2, lit_803321C                  @ 080330E4  = sfx_voices
	movs r1, #0x10                       @ 080330E6
	strb r1, [r2, r3]                    @ 080330E8
L_80330EA:
	pop {r3, r4, r5, r6, r7}             @ 080330EA
	mov r8, r3                           @ 080330EC
	mov sb, r4                           @ 080330EE
	mov sl, r5                           @ 080330F0
	mov fp, r6                           @ 080330F2
	mov ip, r7                           @ 080330F4
	pop {r4, r5, r6, r7}                 @ 080330F6
	pop {r1}                             @ 080330F8
	bx r1                                @ 080330FA

@ ------------------------------------------------------------------
@ snd_sfx_stop_all   ROM 0x080330FC (Thumb)
@ API: free every SFX voice.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_stop_all
snd_sfx_stop_all:
	push {r4, r5, r6, r7, lr}            @ 080330FC
	mov r3, r8                           @ 080330FE
	mov r4, sb                           @ 08033100
	mov r5, sl                           @ 08033102
	mov r6, fp                           @ 08033104
	mov r7, ip                           @ 08033106
	push {r3, r4, r5, r6, r7}            @ 08033108
	bl init_sfx_voices                   @ 0803310A
	pop {r3, r4, r5, r6, r7}             @ 0803310E
	mov r8, r3                           @ 08033110
	mov sb, r4                           @ 08033112
	mov sl, r5                           @ 08033114
	mov fp, r6                           @ 08033116
	mov ip, r7                           @ 08033118
	pop {r4, r5, r6, r7}                 @ 0803311A
	pop {r1}                             @ 0803311C
	bx r1                                @ 0803311E

@ ------------------------------------------------------------------
@ snd_music_stop   ROM 0x08033120 (Thumb)
@ API: free every music voice, no song playing.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_stop
snd_music_stop:
	push {r4, r5, r6, r7, lr}            @ 08033120
	mov r3, r8                           @ 08033122
	mov r4, sb                           @ 08033124
	mov r5, sl                           @ 08033126
	mov r6, fp                           @ 08033128
	mov r7, ip                           @ 0803312A
	push {r3, r4, r5, r6, r7}            @ 0803312C
	bl init_music_voices                 @ 0803312E
	ldr r0, lit_8033220                  @ 08033132  = seq_current_song
	movs r1, #0                          @ 08033134
	mvns r1, r1                          @ 08033136
	str r1, [r0]                         @ 08033138
	pop {r3, r4, r5, r6, r7}             @ 0803313A
	mov r8, r3                           @ 0803313C
	mov sb, r4                           @ 0803313E
	mov sl, r5                           @ 08033140
	mov fp, r6                           @ 08033142
	mov ip, r7                           @ 08033144
	pop {r4, r5, r6, r7}                 @ 08033146
	pop {r1}                             @ 08033148
	bx r1                                @ 0803314A

@ ------------------------------------------------------------------
@ snd_set_music_volume   ROM 0x0803314C (Thumb)
@ API: r0 = music master volume (init 0x80).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_music_volume
snd_set_music_volume:
	ldr r1, lit_8033224                  @ 0803314C  = music_master_volume
	str r0, [r1]                         @ 0803314E
	bx lr                                @ 08033150

@ ------------------------------------------------------------------
@ snd_set_sfx_volume   ROM 0x08033152 (Thumb)
@ API: r0 = SFX master volume (init 0x80).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_sfx_volume
snd_set_sfx_volume:
	ldr r1, lit_8033228                  @ 08033152  = sfx_master_volume
	str r0, [r1]                         @ 08033154
	bx lr                                @ 08033156

@ ------------------------------------------------------------------
@ snd_get_tempo   ROM 0x08033158 (Thumb)
@ API: r0 = current tempo (us per quarter note).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_get_tempo
snd_get_tempo:
	ldr r1, lit_803322C                  @ 08033158  = seq_tempo
	ldr r0, [r1]                         @ 0803315A
	bx lr                                @ 0803315C

@ ------------------------------------------------------------------
@ snd_set_tempo   ROM 0x0803315E (Thumb)
@ API: r0 = tempo (us per quarter note).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_tempo
snd_set_tempo:
	push {r4, r5, r6, r7, lr}            @ 0803315E
	mov r3, r8                           @ 08033160
	mov r4, sb                           @ 08033162
	mov r5, sl                           @ 08033164
	mov r6, fp                           @ 08033166
	mov r7, ip                           @ 08033168
	push {r3, r4, r5, r6, r7}            @ 0803316A
	adds r1, r0, #0                      @ 0803316C
	mov r0, pc                           @ 0803316E
	adds r0, #7                          @ 08033170
	mov lr, r0                           @ 08033172
	ldr r0, lit_8033230                  @ 08033174  = (set_tempo_internal - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08033176
L_8033178:
	pop {r3, r4, r5, r6, r7}             @ 08033178
	mov r8, r3                           @ 0803317A
	mov sb, r4                           @ 0803317C
	mov sl, r5                           @ 0803317E
	mov fp, r6                           @ 08033180
	mov ip, r7                           @ 08033182
	pop {r4, r5, r6, r7}                 @ 08033184
	pop {r1}                             @ 08033186
	bx r1                                @ 08033188

@ ------------------------------------------------------------------
@ snd_music_pause   ROM 0x0803318A (Thumb)
@ API: freeze the sequencer and music voices.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_pause
snd_music_pause:
	movs r1, #1                          @ 0803318A
	ldr r0, lit_8033234                  @ 0803318C  = music_paused
	str r1, [r0]                         @ 0803318E
	bx lr                                @ 08033190

@ ------------------------------------------------------------------
@ snd_music_resume   ROM 0x08033192 (Thumb)
@ API: undo snd_music_pause.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_resume
snd_music_resume:
	movs r1, #0                          @ 08033192
	ldr r0, lit_8033238                  @ 08033194  = music_paused
	str r1, [r0]                         @ 08033196
	bx lr                                @ 08033198

@ ------------------------------------------------------------------
@ snd_sfx_release   ROM 0x0803319A (Thumb)
@ API: r0 = handle. Key off (enters release).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_release
snd_sfx_release:
	push {r4, r5, r6, r7, lr}            @ 0803319A
	mov r3, r8                           @ 0803319C
	mov r4, sb                           @ 0803319E
	mov r5, sl                           @ 080331A0
	mov r6, fp                           @ 080331A2
	mov r7, ip                           @ 080331A4
	push {r3, r4, r5, r6, r7}            @ 080331A6
	bl sfx_find_handle                   @ 080331A8
	cmp r0, #0                           @ 080331AC
	beq L_80331BC                        @ 080331AE
	ldr r2, lit_803323C                  @ 080331B0  = sfx_voices
	ldrb r1, [r2, r3]                    @ 080331B2
	cmp r1, #0x11                        @ 080331B4
	bne L_80331BC                        @ 080331B6
	movs r1, #0x12                       @ 080331B8
	strb r1, [r2, r3]                    @ 080331BA
L_80331BC:
	pop {r3, r4, r5, r6, r7}             @ 080331BC
	mov r8, r3                           @ 080331BE
	mov sb, r4                           @ 080331C0
	mov sl, r5                           @ 080331C2
	mov fp, r6                           @ 080331C4
	mov ip, r7                           @ 080331C6
	pop {r4, r5, r6, r7}                 @ 080331C8
	pop {r1}                             @ 080331CA
	bx r1                                @ 080331CC

@ ------------------------------------------------------------------
@ snd_sfx_play   ROM 0x080331CE (Thumb)
@ API: r0 = sfx id, r1 = volume (0 = do nothing), r2 = pitch mult (0x10000 = normal).
@ Returns handle (-1 if none).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_play
snd_sfx_play:
	movs r3, #0                          @ 080331CE
	b sfx_play_common                    @ 080331D0

@ ------------------------------------------------------------------
@ snd_sfx_play_timed   ROM 0x080331D2 (Thumb)
@ API: as snd_sfx_play, plus r3 = frames until automatic key-off (0 = never).
@ No callers in DKC1.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_play_timed
snd_sfx_play_timed:
	b sfx_play_common                    @ 080331D2
lit_80331D4:
	.word chan_mod-8
lit_80331D8:
	.word chan_mod-4
lit_80331DC:
	.word chan_instrument
lit_80331E0:
	.word 0x00FFFFFF
lit_80331E4:
	.word sfx_voices
lit_80331E8:
	.word cfg_sfx_pool_bytes
lit_80331EC:
	.word sfx_timer
lit_80331F0:
	.word sfx_voices
lit_80331F4:
	.word cfg_sfx_pool_bytes
lit_80331F8:
	.word sfx_handle_counter
lit_80331FC:
	.word sfx_handle
lit_8033200:
	.word sfx_table_ptr
lit_8033204:
	.word (voice_start - iwram_code_start + IWRAM_CODE_BASE)
lit_8033208:
	.word sfx_voices
lit_803320C:
	.word cfg_sfx_pool_bytes
lit_8033210:
	.word sfx_handle
lit_8033214:
	.word sfx_voices+0x24
lit_8033218:
	.word sfx_voices+0x3
lit_803321C:
	.word sfx_voices
lit_8033220:
	.word seq_current_song
lit_8033224:
	.word music_master_volume
lit_8033228:
	.word sfx_master_volume
lit_803322C:
	.word seq_tempo
lit_8033230:
	.word (set_tempo_internal - iwram_code_start + IWRAM_CODE_BASE)
lit_8033234:
	.word music_paused
lit_8033238:
	.word music_paused
lit_803323C:
	.word sfx_voices

@ ------------------------------------------------------------------
@ sfx_play_common   ROM 0x08033240 (Thumb)
@ Shared body of snd_sfx_play / snd_sfx_play_timed: volume 0 -> return -1; else start
@ the voice and store r3 into sfx_timer[voice].
@ ------------------------------------------------------------------
	.thumb_func
sfx_play_common:
	cmp r1, #0                           @ 08033240
	bne L_803324C                        @ 08033242
	movs r1, #0                          @ 08033244
	mvns r1, r1                          @ 08033246
	adds r0, r1, #0                      @ 08033248
	bx lr                                @ 0803324A
L_803324C:
	push {r4, r5, r6, r7, lr}            @ 0803324C
	mov lr, r3                           @ 0803324E
	mov r3, r8                           @ 08033250
	mov r4, sb                           @ 08033252
	mov r5, sl                           @ 08033254
	mov r6, fp                           @ 08033256
	mov r7, ip                           @ 08033258
	push {r3, r4, r5, r6, r7}            @ 0803325A
	push {lr}                            @ 0803325C
	bl sfx_start_voice                   @ 0803325E
	pop {r3}                             @ 08033262
	cmp r1, #0                           @ 08033264
	bmi L_803326E                        @ 08033266
	ldr r5, lit_8033410                  @ 08033268  = sfx_timer
	lsls r6, r1, #2                      @ 0803326A
	str r3, [r5, r6]                     @ 0803326C
L_803326E:
	pop {r3, r4, r5, r6, r7}             @ 0803326E
	mov r8, r3                           @ 08033270
	mov sb, r4                           @ 08033272
	mov sl, r5                           @ 08033274
	mov fp, r6                           @ 08033276
	mov ip, r7                           @ 08033278
	pop {r4, r5, r6, r7}                 @ 0803327A
	pop {r1}                             @ 0803327C
	bx r1                                @ 0803327E

@ ------------------------------------------------------------------
@ snd_shutdown   ROM 0x08033280 (Thumb)
@ API: stop DMA1 and switch the APU off.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_shutdown
snd_shutdown:
	ldr r0, lit_8033414                  @ 08033280  = REG_DMA1CNT_H
	movs r2, #0                          @ 08033282
	strh r2, [r0]                        @ 08033284
	ldr r0, lit_8033418                  @ 08033286  = REG_SOUNDCNT_X
	movs r1, #0                          @ 08033288
	strh r1, [r0]                        @ 0803328A
	bx lr                                @ 0803328C

@ ------------------------------------------------------------------
@ snd_set_mix_rate   ROM 0x0803328E (Thumb)
@ API: r0 = Hz. Above 13379 -> r0 = -1. 10512 / 13379 set Timer 0, samples per frame and the
@ pitch scale and return 0. BUG: any other value <= 13379 falls through to the 21024 Hz
@ settings (352 samples/frame), overrunning the 224-sample mix_buffer.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_mix_rate
snd_set_mix_rate:
	push {r4, r5, r6, r7, lr}            @ 0803328E
	mov r3, r8                           @ 08033290
	mov r4, sb                           @ 08033292
	mov r5, sl                           @ 08033294
	mov r6, fp                           @ 08033296
	mov r7, ip                           @ 08033298
	push {r3, r4, r5, r6, r7}            @ 0803329A
	ldr r1, lit_803341C                  @ 0803329C  = 0x00003443
	cmp r0, r1                           @ 0803329E
	ble L_80332A8                        @ 080332A0
	movs r0, #0                          @ 080332A2
	mvns r0, r0                          @ 080332A4
	b L_80332F6                          @ 080332A6
L_80332A8:
	ldr r1, lit_8033420                  @ 080332A8  = mix_rate_hz
	str r0, [r1]                         @ 080332AA
	ldr r1, lit_8033424                  @ 080332AC  = 0x00002910
	ldr r2, lit_8033428                  @ 080332AE  = 0xFFFFF9C4
	ldr r3, lit_803342C                  @ 080332B0  = 0x018F0064
	movs r4, #0xb0                       @ 080332B2
	cmp r0, r1                           @ 080332B4
	beq L_80332DC                        @ 080332B6
	ldr r1, lit_803341C                  @ 080332B8  = 0x00003443
	ldr r2, lit_8033430                  @ 080332BA  = 0xFFFFFB1A
	ldr r3, lit_8033434                  @ 080332BC  = 0x01397FC3
	movs r4, #0xe0                       @ 080332BE
	cmp r0, r1                           @ 080332C0
	beq L_80332DC                        @ 080332C2
	ldr r1, lit_8033438                  @ 080332C4  = 0x000046ED
	ldr r2, lit_803343C                  @ 080332C6  = 0xFFFFFC64
	ldr r3, lit_8033440                  @ 080332C8  = 0x00E70086
	ldr r4, lit_8033444                  @ 080332CA  = 0x00000130
	cmp r0, r1                           @ 080332CC
	beq L_80332DC                        @ 080332CE
	ldr r1, lit_8033448                  @ 080332D0  = 0x00005220
	ldr r2, lit_803344C                  @ 080332D2  = 0xFFFFFCE2
	ldr r3, lit_8033450                  @ 080332D4  = 0x00C78032
	ldr r4, lit_8033454                  @ 080332D6  = 0x00000160
	cmp r0, r1                           @ 080332D8
	beq L_80332DC                        @ 080332DA
L_80332DC:
	ldr r7, lit_8033458                  @ 080332DC  = mix_timer_reload
	str r2, [r7]                         @ 080332DE
	ldr r7, lit_803345C                  @ 080332E0  = mix_pitch_scale
	str r3, [r7]                         @ 080332E2
	ldr r7, lit_8033460                  @ 080332E4  = mix_samples_per_frame
	str r4, [r7]                         @ 080332E6
	ldr r0, lit_8033464                  @ 080332E8  = REG_TM0CNT_L
	ldr r1, lit_8033468                  @ 080332EA  = mix_timer_reload
	ldr r1, [r1]                         @ 080332EC
	strh r1, [r0]                        @ 080332EE
	movs r1, #0x80                       @ 080332F0
	strh r1, [r0, #2]                    @ 080332F2
	movs r0, #0                          @ 080332F4
L_80332F6:
	pop {r3, r4, r5, r6, r7}             @ 080332F6
	mov r8, r3                           @ 080332F8
	mov sb, r4                           @ 080332FA
	mov sl, r5                           @ 080332FC
	mov fp, r6                           @ 080332FE
	mov ip, r7                           @ 08033300
	pop {r4, r5, r6, r7}                 @ 08033302
	pop {r1}                             @ 08033304
	bx r1                                @ 08033306

@ ------------------------------------------------------------------
@ snd_get_song   ROM 0x08033308 (Thumb)
@ API: r0 = current song, -1 = none / finished.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_get_song
snd_get_song:
	ldr r0, lit_803346C                  @ 08033308  = seq_current_song
	ldr r0, [r0]                         @ 0803330A
	bx lr                                @ 0803330C

@ ------------------------------------------------------------------
@ snd_set_max_voices   ROM 0x0803330E (Thumb)
@ API: r0 = number of voices mixed per frame (init 8).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_max_voices
snd_set_max_voices:
	ldr r1, lit_8033470                  @ 0803330E  = mix_max_voices
	str r0, [r1]                         @ 08033310
	bx lr                                @ 08033312

@ ------------------------------------------------------------------
@ wait_vcount_160   ROM 0x08033314 (Thumb)
@ Busy-wait for the start of V-blank (VCOUNT 160).
@ ------------------------------------------------------------------
	.thumb_func
wait_vcount_160:
	ldr r0, lit_8033474                  @ 08033314  = REG_VCOUNT
L_8033316:
	ldrb r1, [r0]                        @ 08033316
	cmp r1, #0xa0                        @ 08033318
	beq L_8033316                        @ 0803331A
L_803331C:
	ldrb r1, [r0]                        @ 0803331C
	cmp r1, #0xa0                        @ 0803331E
	bne L_803331C                        @ 08033320
	mov pc, lr                           @ 08033322

@ ------------------------------------------------------------------
@ reset_pitch_bend   ROM 0x08033324 (Thumb)
@ All 16 chan_bend = 0x2000.
@ ------------------------------------------------------------------
	.thumb_func
reset_pitch_bend:
	movs r1, #0x20                       @ 08033324
	lsls r1, r1, #8                      @ 08033326
	ldr r0, lit_8033478                  @ 08033328  = chan_bend
	movs r2, #0x40                       @ 0803332A
L_803332C:
	subs r2, #4                          @ 0803332C
	str r1, [r0, r2]                     @ 0803332E
	bne L_803332C                        @ 08033330
	bx lr                                @ 08033332

@ ------------------------------------------------------------------
@ reset_modulation   ROM 0x08033334 (Thumb)
@ All 16 chan_mod = {0, 0}.
@ ------------------------------------------------------------------
	.thumb_func
reset_modulation:
	movs r1, #0                          @ 08033334
	ldr r0, lit_803347C                  @ 08033336  = chan_mod
	movs r2, #0x80                       @ 08033338
L_803333A:
	subs r2, #8                          @ 0803333A
	str r1, [r0, r2]                     @ 0803333C
	bne L_803333A                        @ 0803333E
	bx lr                                @ 08033340

@ ------------------------------------------------------------------
@ clear_mix_buffer   ROM 0x08033342 (Thumb)
@ Zero mix_samples_per_frame s16 samples (176/224/304/352 via fall-through stm runs).
@ At 304/352 this overruns the 448-byte mix_buffer.
@ ------------------------------------------------------------------
	.thumb_func
clear_mix_buffer:
	movs r1, #0                          @ 08033342
	movs r2, #0                          @ 08033344
	movs r3, #0                          @ 08033346
	movs r4, #0                          @ 08033348
	movs r5, #0                          @ 0803334A
	movs r6, #0                          @ 0803334C
	ldr r0, lit_8033480                  @ 0803334E  = mix_buffer
	ldr r7, lit_8033484                  @ 08033350  = mix_samples_per_frame
	ldr r7, [r7]                         @ 08033352
	lsrs r7, r7, #1                      @ 08033354
	cmp r7, #0x58                        @ 08033356
	beq L_8033366                        @ 08033358
	cmp r7, #0x70                        @ 0803335A
	beq L_8033390                        @ 0803335C
	cmp r7, #0x98                        @ 0803335E
	beq L_8033382                        @ 08033360
	cmp r7, #0xb0                        @ 08033362
	beq L_8033378                        @ 08033364
L_8033366:
	movs r7, #0                          @ 08033366
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033368
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803336A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803336C
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803336E
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033370
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033372
	stm r0!, {r1, r2}                    @ 08033374
	b L_80333B2                          @ 08033376
L_8033378:
	movs r7, #0                          @ 08033378
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803337A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803337C
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803337E
	stm r0!, {r1, r2, r3}                @ 08033380
L_8033382:
	movs r7, #0                          @ 08033382
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033384
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033386
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033388
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803338A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803338C
	stm r0!, {r1, r2, r3, r4, r5}        @ 0803338E
L_8033390:
	movs r7, #0                          @ 08033390
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033392
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033394
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033396
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033398
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803339A
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803339C
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 0803339E
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333A0
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333A2
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333A4
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333A6
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333A8
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333AA
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333AC
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333AE
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080333B0
L_80333B2:
	bx lr                                @ 080333B2

@ ------------------------------------------------------------------
@ init_music_voices   ROM 0x080333B4 (Thumb)
@ 96 music voices = 16 MIDI channels x 6; voice+6 = owning channel.
@ ------------------------------------------------------------------
	.thumb_func
init_music_voices:
	ldr r0, lit_8033488                  @ 080333B4  = music_voices
	ldr r3, lit_803348C                  @ 080333B6  = music_voices+0x6
	ldr r6, lit_8033490                  @ 080333B8  = music_voices+0x8
	movs r7, #0                          @ 080333BA
	movs r4, #1                          @ 080333BC
	movs r5, #0x10                       @ 080333BE
	movs r1, #0x10                       @ 080333C0
	ldr r2, lit_8033494                  @ 080333C2  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 080333C4
L_80333C6:
	subs r4, #1                          @ 080333C6
	bne L_80333D0                        @ 080333C8
	subs r5, #1                          @ 080333CA
	ldr r4, lit_8033498                  @ 080333CC  = cfg_voices_per_chan
	ldr r4, [r4]                         @ 080333CE
L_80333D0:
	subs r2, #0x28                       @ 080333D0
	strb r1, [r0, r2]                    @ 080333D2
	strb r5, [r3, r2]                    @ 080333D4
	str r7, [r6, r2]                     @ 080333D6
	bne L_80333C6                        @ 080333D8
	bx lr                                @ 080333DA

@ ------------------------------------------------------------------
@ init_sfx_voices   ROM 0x080333DC (Thumb)
@ 5 SFX voices, channel byte = -1.
@ ------------------------------------------------------------------
	.thumb_func
init_sfx_voices:
	ldr r0, lit_803349C                  @ 080333DC  = sfx_voices
	movs r5, #0                          @ 080333DE
	mvns r5, r5                          @ 080333E0
	ldr r1, lit_80334A0                  @ 080333E2  = cfg_sfx_voices
	ldr r1, [r1]                         @ 080333E4
	movs r2, #0x10                       @ 080333E6
L_80333E8:
	strb r2, [r0]                        @ 080333E8
	strb r5, [r0, #6]                    @ 080333EA
	adds r0, #0x28                       @ 080333EC
	subs r1, #1                          @ 080333EE
	bne L_80333E8                        @ 080333F0
	bx lr                                @ 080333F2

@ ------------------------------------------------------------------
@ reset_channel_volume   ROM 0x080333F4 (Thumb)
@ All 16 chan_volume = 127.
@ ------------------------------------------------------------------
	.thumb_func
reset_channel_volume:
	ldr r0, lit_80334A4                  @ 080333F4  = chan_volume
	movs r1, #0x10                       @ 080333F6
	movs r2, #0x7f                       @ 080333F8
L_80333FA:
	subs r1, #1                          @ 080333FA
	strb r2, [r0, r1]                    @ 080333FC
	bne L_80333FA                        @ 080333FE
	bx lr                                @ 08033400

@ ------------------------------------------------------------------
@ reset_mono_flags   ROM 0x08033402 (Thumb)
@ All 16 chan_mono = 0 (poly).
@ ------------------------------------------------------------------
	.thumb_func
reset_mono_flags:
	ldr r0, lit_80334A8                  @ 08033402  = chan_mono
	movs r1, #0x10                       @ 08033404
	movs r2, #0                          @ 08033406
L_8033408:
	subs r1, #1                          @ 08033408
	strb r2, [r0, r1]                    @ 0803340A
	bne L_8033408                        @ 0803340C
	bx lr                                @ 0803340E
lit_8033410:
	.word sfx_timer
lit_8033414:
	.word REG_DMA1CNT_H
lit_8033418:
	.word REG_SOUNDCNT_X
lit_803341C:
	.word 0x00003443
lit_8033420:
	.word mix_rate_hz
lit_8033424:
	.word 0x00002910
lit_8033428:
	.word 0xFFFFF9C4
lit_803342C:
	.word 0x018F0064
lit_8033430:
	.word 0xFFFFFB1A
lit_8033434:
	.word 0x01397FC3
lit_8033438:
	.word 0x000046ED
lit_803343C:
	.word 0xFFFFFC64
lit_8033440:
	.word 0x00E70086
lit_8033444:
	.word 0x00000130
lit_8033448:
	.word 0x00005220
lit_803344C:
	.word 0xFFFFFCE2
lit_8033450:
	.word 0x00C78032
lit_8033454:
	.word 0x00000160
lit_8033458:
	.word mix_timer_reload
lit_803345C:
	.word mix_pitch_scale
lit_8033460:
	.word mix_samples_per_frame
lit_8033464:
	.word REG_TM0CNT_L
lit_8033468:
	.word mix_timer_reload
lit_803346C:
	.word seq_current_song
lit_8033470:
	.word mix_max_voices
lit_8033474:
	.word REG_VCOUNT
lit_8033478:
	.word chan_bend
lit_803347C:
	.word chan_mod
lit_8033480:
	.word mix_buffer
lit_8033484:
	.word mix_samples_per_frame
lit_8033488:
	.word music_voices
lit_803348C:
	.word music_voices+0x6
lit_8033490:
	.word music_voices+0x8
lit_8033494:
	.word cfg_music_pool_bytes
lit_8033498:
	.word cfg_voices_per_chan
lit_803349C:
	.word sfx_voices
lit_80334A0:
	.word cfg_sfx_voices
lit_80334A4:
	.word chan_volume
lit_80334A8:
	.word chan_mono

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
	.byte 0
	.byte 0

