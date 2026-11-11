@ ==========================================================================
@ Rare GBA sound driver (Donkey Kong Country 2, Europe, B2DP) - reconstructed source
@ ROM 0x080321F4-0x08034C84. Assembles byte-identical with:
@   arm-none-eabi-as -mcpu=arm7tdmi -o dkc2_sound.o dkc2_sound.s
@   arm-none-eabi-ld -Ttext=0x080321F4 -o dkc2_sound.elf dkc2_sound.o
@   arm-none-eabi-objcopy -O binary dkc2_sound.elf dkc2_sound.bin
@ The ARM block (iwram_code_start..iwram_code_end) is copied to IWRAM 0x03002190
@ by snd_init and runs there; (x - iwram_code_start + IWRAM_CODE_BASE) is the run-time address.
@ Labels, names and comments are reverse-engineered, not original symbols.
@ ==========================================================================
	.syntax unified
	.cpu arm7tdmi
	.text

	.equ IWRAM_CODE_BASE, 0x03002190

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
	.equ cfg_buffer_a,          0x080D3BD8   @ ptr -> 8-bit output buffer A (0x03002570)
	.equ cfg_buffer_b,          0x080D3BE0   @ ptr -> 8-bit output buffer B (0x03002730)
	.equ cfg_music_pool_bytes,  0x080D3BE8   @ 0xF00 = 96 voices
	.equ cfg_chan_pool_bytes,   0x080D3BEC   @ 0xF0 = 6 voices per channel
	.equ cfg_sfx_pool_bytes,    0x080D3BF0   @ 0xC8 = 5 voices
	.equ cfg_sfx_voices,        0x080D3BF4   @ 5
	.equ cfg_voices_per_chan,   0x080D3BFC   @ 6
	.equ sfx_table,             0x0854B0B0   @ 
	.equ song_table,            0x0854B5B0   @ 
@ ---- IWRAM variables ----
	.equ seq_num_tracks,        0x03000C10   @ tracks in current song
	.equ mix_samples_per_frame, 0x03000C14   @ 176/224/304/352
	.equ mix_timer_reload,      0x03000C18   @ Timer 0 reload
	.equ seq_prog_map_ptr,      0x03000C1C   @ song+0x0C: 128-byte program -> instrument index map
	.equ seq_current_song,      0x03000C20   @ -1 = none
	.equ seq_loop_ptr,          0x03000C30   @ [16] track pointer saved by CC102
	.equ chan_mod,              0x03000C70   @ [16] {u32 mod wheel (CC1), u32 LFO phase (24-bit)}
	.equ sfx_table_ptr,         0x03000CF0   @ array of sample-instrument pointers, one per SFX id
	.equ seq_frame_time,        0x03000CF4   @ microseconds<<8 elapsed per frame
	.equ seq_track_ptr,         0x03000D00   @ [16] current event pointer per track
	.equ seq_division,          0x03000D40   @ ticks per quarter note
	.equ sfx_master_volume,     0x03000D44   @ 
	.equ music_paused,          0x03000D48   @ 
	.equ chan_cc100,            0x03000D50   @ [16] CC100 value - written, never read
	.equ chan_volume,           0x03000D60   @ [16] CC7
	.equ mix_max_voices,        0x03000D70   @ 
	.equ chan_bend,             0x03000D80   @ [16] u32 14-bit pitch bend
	.equ mix_pitch_scale,       0x03000DC0   @ 2^38 / mixing rate
	.equ seq_pending_song,      0x03000DC4   @ -1 = none
	.equ chan_instrument,       0x03000DD0   @ [16] current instrument pointer
	.equ chan_mono,             0x03000E10   @ [16] 1 = mono (CC126), 0 = poly (CC127)
	.equ music_voices,          0x03000E20   @ [96] x 0x28
	.equ music_master_volume,   0x03001D20   @ 
	.equ sfx_handle,            0x03001D30   @ [8] handle per SFX voice (5 used)
	.equ sfx_timer,             0x03001D50   @ [8] frames to auto key-off (5 used)
	.equ seq_track_time,        0x03001F40   @ [16] s64 time until next event, us<<8
	.equ mix_buffer,            0x03001FC0   @ s16 x 224
	.equ seq_inst_table_ptr,    0x03002180   @ song+0x10: instrument pointer table
	.equ sfx_handle_counter,    0x0300357C   @ 
	.equ sfx_voices,            0x03003580   @ [5] x 0x28
	.equ mix_rate_hz,           0x03003648   @ 
	.equ seq_tempo,             0x0300364C   @ microseconds per quarter note
	.equ dma_buffer_flag,       0x03003650   @ toggled by snd_vblank
	.equ song_table_ptr,        0x03003654   @ 


@ iwram_code_size: Size of the IWRAM block, read by snd_init
iwram_code_size:
	.word 0x000010BC
	.balign 4
iwram_code_start:
	.arm

@ ------------------------------------------------------------------
@ voice_start   ROM 0x080321F8 / IWRAM 0x03002190 (ARM)
@ Start a voice. In: r5=voice, r2=sample-instrument, r1=pitch mult (16.16), r3=volume,
@ r4=MIDI key (for note-off matching), r7=loop mode, sb=pitch key. Sets state=0x11 (key on).
@ ------------------------------------------------------------------
voice_start:
	stmdb sp!, {lr}                      @ 080321F8
	strb r3, [r5, #3]                    @ 080321FC
	str r1, [r5, #0x24]                  @ 08032200
	strb r7, [r5, #1]                    @ 08032204
	strb r4, [r5, #2]                    @ 08032208
	strb sb, [r5, #5]                    @ 0803220C
	ldr r1, [r2, #0x10]                  @ 08032210
	str r1, [r5, #0xc]                   @ 08032214
	mov r1, #0                           @ 08032218
	str r1, [r5, #0x10]                  @ 0803221C
	strb r1, [r5, #4]                    @ 08032220
	str r1, [r5, #0x14]                  @ 08032224
	str r2, [r5, #0x20]                  @ 08032228
	mov r8, #0x11                        @ 0803222C
	strb r8, [r5]                        @ 08032230
	ldm sp!, {lr}                        @ 08032234
	bx lr                                @ 08032238

@ ------------------------------------------------------------------
@ mix_frame   ROM 0x0803223C / IWRAM 0x030021D4 (ARM)
@ Render one frame: mix up to mix_max_voices voices (SFX key-on, SFX released,
@ music key-on, music released - in that priority order) into the s16 mix buffer, then clip
@ to s8 into the DirectSound buffer that the DMA is NOT currently playing.
@ ------------------------------------------------------------------
mix_frame:
	sub sp, sp, #0x24                    @ 0803223C
	str lr, [sp, #8]                     @ 08032240
	ldr r5, lit_8032A8C                  @ 08032244  = mix_buffer
	str r5, [sp, #4]                     @ 08032248
	ldr r1, lit_8032A90                  @ 0803224C  = mix_max_voices
	ldr r1, [r1]                         @ 08032250
	str r1, [sp, #0x10]                  @ 08032254
	ldr r2, lit_8032A94                  @ 08032258  = cfg_sfx_pool_bytes
	ldr r2, [r2]                         @ 0803225C
	ldr r0, lit_8032A98                  @ 08032260  = sfx_voices
	add r0, r0, r2                       @ 08032264
L_8032268:
	ldrb r5, [r0, -r2]                   @ 08032268
	cmp r5, #0x11                        @ 0803226C
	bleq mix_frame_voice                 @ 08032270  SFX voices, key on
	subs r2, r2, #0x28                   @ 08032274
	bgt L_8032268                        @ 08032278
	ldr r2, lit_8032A9C                  @ 0803227C  = cfg_sfx_pool_bytes
	ldr r2, [r2]                         @ 08032280
L_8032284:
	ldrb r5, [r0, -r2]                   @ 08032284
	cmp r5, #0x12                        @ 08032288
	bleq mix_frame_voice                 @ 0803228C  SFX voices, released
	subs r2, r2, #0x28                   @ 08032290
	bgt L_8032284                        @ 08032294
	ldr r0, lit_8032AA0                  @ 08032298  = music_paused
	ldr r1, [r0]                         @ 0803229C
	cmp r1, #1                           @ 080322A0
	beq L_80322E8                        @ 080322A4
	ldr r2, lit_8032AA4                  @ 080322A8  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 080322AC
	ldr r0, lit_8032AA8                  @ 080322B0  = music_voices
	add r0, r0, r2                       @ 080322B4
L_80322B8:
	ldrb r5, [r0, -r2]                   @ 080322B8
	cmp r5, #0x11                        @ 080322BC
	bleq mix_frame_voice                 @ 080322C0  music voices, key on
	subs r2, r2, #0x28                   @ 080322C4
	bgt L_80322B8                        @ 080322C8
	ldr r2, lit_8032AAC                  @ 080322CC  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 080322D0
L_80322D4:
	ldrb r5, [r0, -r2]                   @ 080322D4
	cmp r5, #0x12                        @ 080322D8
	bleq mix_frame_voice                 @ 080322DC  music voices, released
	subs r2, r2, #0x28                   @ 080322E0
	bgt L_80322D4                        @ 080322E4
L_80322E8:
	ldr r0, [sp, #0x10]                  @ 080322E8
	ldr r1, lit_8032AB0                  @ 080322EC  = mix_max_voices
	ldr r1, [r1]                         @ 080322F0
	cmp r0, r1                           @ 080322F4
	bne L_8032308                        @ 080322F8
	ldr r0, lit_8032AB4                  @ 080322FC  = clear_mix_buffer+1 ; nothing mixed -> zero the buffer (Thumb, via bx)
	add lr, pc, #0                       @ 08032300
	bx r0                                @ 08032304
L_8032308:
	ldr r0, lit_8032AB8                  @ 08032308  = dma_buffer_flag
	ldr r2, [r0]                         @ 0803230C
	ldr r1, lit_8032ABC                  @ 08032310  = cfg_buffer_a
	cmp r2, #0                           @ 08032314
	bne L_8032320                        @ 08032318
	ldr r1, lit_8032AC0                  @ 0803231C  = cfg_buffer_b
L_8032320:
	ldr r1, [r1]                         @ 08032320
	ldr r0, lit_8032AC4                  @ 08032324  = mix_buffer
	ldr r2, lit_8032AC8                  @ 08032328  = mix_samples_per_frame
	ldr r2, [r2]                         @ 0803232C
	stmdb sp!, {r4}                      @ 08032330
	mov r4, #0x800000                    @ 08032334
L_8032338:
	ldr r3, [r0], #4                     @ 08032338  clip s16 -> s8, two samples per iteration
	ror lr, r3, #0x10                    @ 0803233C
	cmp r4, r3, lsl #16                  @ 08032340
	movle r3, #0x7f                      @ 08032344
	cmn r4, r3, lsl #16                  @ 08032348
	movlt r3, #0x80                      @ 0803234C
	cmp r4, lr, lsl #16                  @ 08032350
	movle lr, #0x7f                      @ 08032354
	cmn r4, lr, lsl #16                  @ 08032358
	movlt lr, #0x80                      @ 0803235C
	and r3, r3, #0xff                    @ 08032360
	orr r3, r3, lr, lsl #8               @ 08032364
	strh r3, [r1], #2                    @ 08032368
	subs r2, r2, #2                      @ 0803236C
	bne L_8032338                        @ 08032370
	ldm sp!, {r4}                        @ 08032374
	ldr lr, [sp, #8]                     @ 08032378
	add sp, sp, #0x24                    @ 0803237C
	bx lr                                @ 08032380

@ ------------------------------------------------------------------
@ mix_frame_voice   ROM 0x08032384 / IWRAM 0x0300231C (ARM)
@ mix_frame helper: mix voice (r0-r2) and count it against the voice budget; when the
@ budget hits zero, abandon the scan and go straight to the s16->s8 conversion.
@ ------------------------------------------------------------------
mix_frame_voice:
	str lr, [sp, #0xc]                   @ 08032384
	str r0, [sp, #0x14]                  @ 08032388
	str r2, [sp, #0x18]                  @ 0803238C
	sub r0, r0, r2                       @ 08032390
	ldr r5, [sp, #4]                     @ 08032394
	bl mix_voice                         @ 08032398
	ldr r1, [sp, #0x10]                  @ 0803239C
	subs r1, r1, #1                      @ 080323A0
	str r1, [sp, #0x10]                  @ 080323A4
	beq L_8032308                        @ 080323A8
	ldr r0, [sp, #0x14]                  @ 080323AC
	ldr r2, [sp, #0x18]                  @ 080323B0
	ldr pc, [sp, #0xc]                   @ 080323B4

@ ------------------------------------------------------------------
@ advance_sfx_voices   ROM 0x080323B8 / IWRAM 0x03002350 (ARM)
@ Advance the playback position of every active SFX voice by one frame.
@ ------------------------------------------------------------------
advance_sfx_voices:
	stmdb sp!, {lr}                      @ 080323B8
	ldr fp, lit_8032ACC                  @ 080323BC  = cfg_sfx_pool_bytes
	ldr fp, [fp]                         @ 080323C0
	ldr sl, lit_8032AD0                  @ 080323C4  = sfx_voices
	add sl, sl, fp                       @ 080323C8
	b L_80323E4                          @ 080323CC

@ ------------------------------------------------------------------
@ advance_music_voices   ROM 0x080323D0 / IWRAM 0x03002368 (ARM)
@ Advance the playback position of every active music voice by one frame.
@ ------------------------------------------------------------------
advance_music_voices:
	stmdb sp!, {lr}                      @ 080323D0
	ldr fp, lit_8032AD4                  @ 080323D4  = cfg_music_pool_bytes
	ldr fp, [fp]                         @ 080323D8
	ldr sl, lit_8032AD8                  @ 080323DC  = music_voices
	add sl, sl, fp                       @ 080323E0
L_80323E4:
	ldrb r2, [sl, -fp]                   @ 080323E4
	cmp r2, #0x11                        @ 080323E8
	bleq voice_advance                   @ 080323EC
	cmp r2, #0x12                        @ 080323F0
	bleq voice_advance                   @ 080323F4
	subs fp, fp, #0x28                   @ 080323F8
	bgt L_80323E4                        @ 080323FC
	ldm sp!, {lr}                        @ 08032400
	bx lr                                @ 08032404

@ ------------------------------------------------------------------
@ voice_advance   ROM 0x08032408 / IWRAM 0x030023A0 (ARM)
@ Advance one voice (r0=voice) by mix_samples_per_frame samples using 64-bit maths,
@ then handle end-of-sample (loop or free). The mixer never writes positions back; this pass does.
@ NOTE: loop mode 1 frees the voice through [r8] instead of [r0] (bug, fixed in DKC3).
@ ------------------------------------------------------------------
voice_advance:
	sub r0, sl, fp                       @ 08032408
	ldr r7, [r0, #8]                     @ 0803240C
	movs r7, r7                          @ 08032410
	bne L_8032424                        @ 08032414
	push {sl, fp, lr}                    @ 08032418
	bl calc_pitch                        @ 0803241C
	pop {sl, fp, lr}                     @ 08032420
L_8032424:
	ldr r1, lit_8032ADC                  @ 08032424  = mix_samples_per_frame
	ldr r1, [r1]                         @ 08032428
	ldr r2, [r0, #0x10]                  @ 0803242C
	ldr r3, [r0, #0xc]                   @ 08032430
	mov r6, #0                           @ 08032434
	str r6, [r0, #8]                     @ 08032438
	ldr r6, [r0, #0x24]                  @ 0803243C
	umull r4, r5, r6, r7                 @ 08032440  step * pitch multiplier (16.16)
	lsr r7, r4, #0x10                    @ 08032444
	add r7, r7, r5, lsl #16              @ 08032448
	orr r2, r2, r3, lsl #23              @ 0803244C
	lsr r3, r3, #9                       @ 08032450
	umlal r2, r3, r7, r1                 @ 08032454
	ldr r4, lit_8032AE0                  @ 08032458  = 0x007FFFFF
	and r1, r2, r4                       @ 0803245C
	lsr r2, r2, #0x17                    @ 08032460
	orr r2, r2, r3, lsl #9               @ 08032464
	ldr r3, [r0, #0x20]                  @ 08032468
	ldr r3, [r3, #0x18]                  @ 0803246C
	cmp r2, r3                           @ 08032470
	blt L_80324CC                        @ 08032474
	ldrb r4, [r0, #1]                    @ 08032478
	cmp r4, #1                           @ 0803247C
	beq L_80324C0                        @ 08032480
	cmp r4, #2                           @ 08032484
	beq L_803249C                        @ 08032488
	cmp r4, #3                           @ 0803248C
	beq L_80324B4                        @ 08032490
	cmp r4, #4                           @ 08032494
	beq L_803249C                        @ 08032498
L_803249C:
	ldr r4, [r0, #0x20]                  @ 0803249C
	ldr r4, [r4, #0x14]                  @ 080324A0
L_80324A4:
	sub r2, r2, r4                       @ 080324A4
	cmp r2, r3                           @ 080324A8
	bge L_80324A4                        @ 080324AC
	b L_80324CC                          @ 080324B0
L_80324B4:
	mov r3, #0x10                        @ 080324B4
	strb r3, [r0]                        @ 080324B8
	b L_80324CC                          @ 080324BC
L_80324C0:
	mov r3, #0x10                        @ 080324C0
	strb r3, [r8]                        @ 080324C4  BUG: should be [r0]
	b L_80324CC                          @ 080324C8
L_80324CC:
	str r2, [r0, #0xc]                   @ 080324CC
	str r1, [r0, #0x10]                  @ 080324D0
	mov pc, lr                           @ 080324D4

@ ------------------------------------------------------------------
@ env_update_sfx   ROM 0x080324D8 / IWRAM 0x03002470 (ARM)
@ Run one envelope step on every active SFX voice.
@ ------------------------------------------------------------------
env_update_sfx:
	stmdb sp!, {lr}                      @ 080324D8
	ldr fp, lit_8032AE4                  @ 080324DC  = cfg_sfx_pool_bytes
	ldr fp, [fp]                         @ 080324E0
	ldr sl, lit_8032AE8                  @ 080324E4  = sfx_voices
	add sl, sl, fp                       @ 080324E8
	b L_8032504                          @ 080324EC

@ ------------------------------------------------------------------
@ env_update_music   ROM 0x080324F0 / IWRAM 0x03002488 (ARM)
@ Run one envelope step on every active music voice.
@ ------------------------------------------------------------------
env_update_music:
	stmdb sp!, {lr}                      @ 080324F0
	ldr fp, lit_8032AEC                  @ 080324F4  = cfg_music_pool_bytes
	ldr fp, [fp]                         @ 080324F8
	ldr sl, lit_8032AF0                  @ 080324FC  = music_voices
	add sl, sl, fp                       @ 08032500
L_8032504:
	ldrb r2, [sl, -fp]                   @ 08032504
	cmp r2, #0x11                        @ 08032508
	bleq env_step                        @ 0803250C
	cmp r2, #0x12                        @ 08032510
	bleq env_step                        @ 08032514
L_8032518:
	subs fp, fp, #0x28                   @ 08032518
	bgt L_8032504                        @ 0803251C
	ldm sp!, {lr}                        @ 08032520
	bx lr                                @ 08032524

@ ------------------------------------------------------------------
@ env_step   ROM 0x08032528 / IWRAM 0x030024C0 (ARM)
@ Dispatch on voice+4 (envelope phase 0-6) through env_jump_table.
@ ------------------------------------------------------------------
env_step:
	sub ip, sl, fp                       @ 08032528
	ldrb r1, [ip, #4]                    @ 0803252C
	add r2, pc, #4                       @ 08032530  = env_jump_table
	ldr r0, [r2, r1, lsl #2]             @ 08032534
	add pc, r0, r2                       @ 08032538

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
@ env_attack_init   ROM 0x08032558 / IWRAM 0x030024F0 (ARM)
@ Phase 0: attack time = (99-A)*32/99 frames; 0 = instant (go to decay at full level).
@ ------------------------------------------------------------------
env_attack_init:
	ldr r3, [ip, #0x20]                  @ 08032558
	ldr r1, [r3, #0x24]                  @ 0803255C
	rsb r2, r1, #0x63                    @ 08032560
	lsl r0, r2, #5                       @ 08032564
	mov r1, #0x63                        @ 08032568
	bl udiv_32_16                        @ 0803256C  udiv_32_16
	movs r0, r0                          @ 08032570
	beq L_80325C0                        @ 08032574
	mov r1, r0                           @ 08032578
	mov r0, #0x8000                      @ 0803257C
	add r1, r1, #1                       @ 08032580
	bl udiv_32_16                        @ 08032584
	lsl r1, r1, #4                       @ 08032588
	lsl r0, r0, #4                       @ 0803258C
	str r1, [ip, #0x14]                  @ 08032590
	str r0, [ip, #0x18]                  @ 08032594
	mov r0, #1                           @ 08032598
	strb r0, [ip, #4]                    @ 0803259C

@ ------------------------------------------------------------------
@ env_attack   ROM 0x080325A0 / IWRAM 0x03002538 (ARM)
@ Phase 1: ramp level up by env_inc; on key-off go to release.
@ ------------------------------------------------------------------
env_attack:
	ldrb r1, [ip]                        @ 080325A0
	cmp r1, #0x12                        @ 080325A4
	beq env_release_init                 @ 080325A8
	ldr r1, [ip, #0x18]                  @ 080325AC
	ldr r2, [ip, #0x14]                  @ 080325B0
	add r1, r1, r2                       @ 080325B4
	cmp r1, #0x80000                     @ 080325B8
	blt L_80325CC                        @ 080325BC
L_80325C0:
	mov r1, #2                           @ 080325C0
	strb r1, [ip, #4]                    @ 080325C4
	mov r1, #0x80000                     @ 080325C8
L_80325CC:
	str r1, [ip, #0x14]                  @ 080325CC
	sub pc, pc, #0xc0                    @ 080325D0  -> L_8032518

@ ------------------------------------------------------------------
@ env_decay_init   ROM 0x080325D4 / IWRAM 0x0300256C (ARM)
@ Phase 2: sustain = S*128/99 (8.8) << 4; decay frames = adsr_rate_table[D].
@ ------------------------------------------------------------------
env_decay_init:
	ldr r3, [ip, #0x20]                  @ 080325D4
	ldr r0, [r3, #0x2c]                  @ 080325D8
	lsl r0, r0, #7                       @ 080325DC
	mov r1, #0x63                        @ 080325E0
	bl udiv_32_16                        @ 080325E4
	lsl r4, r0, #8                       @ 080325E8
	lsl r0, r1, #8                       @ 080325EC
	mov r1, #0x63                        @ 080325F0
	bl udiv_32_16                        @ 080325F4
	orr r0, r4, r0                       @ 080325F8
	lsl r1, r0, #4                       @ 080325FC
	str r1, [ip, #0x1c]                  @ 08032600
	rsb r0, r0, #0x8000                  @ 08032604
	ldr r1, [r3, #0x28]                  @ 08032608
	ldr r2, lit_8032AF4                  @ 0803260C  = adsr_rate_table
	ldrb r1, [r2, r1]                    @ 08032610
	movs r1, r1                          @ 08032614
	beq L_8032664                        @ 08032618
	add r1, r1, #1                       @ 0803261C
	bl udiv_32_16                        @ 08032620
	lsl r0, r0, #4                       @ 08032624
	str r0, [ip, #0x18]                  @ 08032628
	ldr r0, [ip, #0x14]                  @ 0803262C
	sub r0, r0, r1, lsl #4               @ 08032630
	str r0, [ip, #0x14]                  @ 08032634
	mov r1, #3                           @ 08032638
	strb r1, [ip, #4]                    @ 0803263C

@ ------------------------------------------------------------------
@ env_decay   ROM 0x08032640 / IWRAM 0x030025D8 (ARM)
@ Phase 3: ramp down to sustain; a sustain level below 0x1000 kills the voice.
@ ------------------------------------------------------------------
env_decay:
	ldrb r1, [ip]                        @ 08032640
	cmp r1, #0x12                        @ 08032644
	beq env_release_init                 @ 08032648
	ldr r1, [ip, #0x18]                  @ 0803264C
	ldr r2, [ip, #0x14]                  @ 08032650
	ldr r3, [ip, #0x1c]                  @ 08032654
	sub r1, r2, r1                       @ 08032658
	cmp r1, r3                           @ 0803265C
	bgt L_8032670                        @ 08032660
L_8032664:
	mov r1, #4                           @ 08032664
	strb r1, [ip, #4]                    @ 08032668
	ldr r1, [ip, #0x1c]                  @ 0803266C
L_8032670:
	cmp r1, #0x1000                      @ 08032670
	blt env_kill                         @ 08032674
	str r1, [ip, #0x14]                  @ 08032678
	sub pc, pc, #0x16c                   @ 0803267C  -> L_8032518

@ ------------------------------------------------------------------
@ env_sustain   ROM 0x08032680 / IWRAM 0x03002618 (ARM)
@ Phase 4: hold until key-off.
@ ------------------------------------------------------------------
env_sustain:
	ldrb r1, [ip]                        @ 08032680
	cmp r1, #0x12                        @ 08032684
	beq env_release_init                 @ 08032688
	sub pc, pc, #0x17c                   @ 0803268C  -> L_8032518

@ ------------------------------------------------------------------
@ env_release_init   ROM 0x08032690 / IWRAM 0x03002628 (ARM)
@ Phase 5: release frames = adsr_rate_table[R]; 0 = cut immediately.
@ ------------------------------------------------------------------
env_release_init:
	ldr r3, [ip, #0x20]                  @ 08032690
	ldr r0, [ip, #0x14]                  @ 08032694
	ldr r1, [r3, #0x30]                  @ 08032698
	ldr r2, lit_8032AF8                  @ 0803269C  = adsr_rate_table
	ldrb r1, [r2, r1]                    @ 080326A0
	movs r1, r1                          @ 080326A4
	beq env_kill                         @ 080326A8
	lsr r0, r0, #4                       @ 080326AC
	add r1, r1, #1                       @ 080326B0
	bl udiv_32_16                        @ 080326B4
	lsls r0, r0, #4                      @ 080326B8
	beq env_kill                         @ 080326BC
	str r0, [ip, #0x18]                  @ 080326C0
	ldr r0, [ip, #0x14]                  @ 080326C4
	sub r0, r0, r1, lsl #4               @ 080326C8
	str r0, [ip, #0x14]                  @ 080326CC
	mov r1, #6                           @ 080326D0
	strb r1, [ip, #4]                    @ 080326D4

@ ------------------------------------------------------------------
@ env_release   ROM 0x080326D8 / IWRAM 0x03002670 (ARM)
@ Phase 6: ramp down to zero, then free the voice.
@ ------------------------------------------------------------------
env_release:
	ldr r1, [ip, #0x18]                  @ 080326D8
	ldr r2, [ip, #0x14]                  @ 080326DC
	subs r1, r2, r1                      @ 080326E0
	bgt L_80326F0                        @ 080326E4

@ ------------------------------------------------------------------
@ env_kill   ROM 0x080326E8 / IWRAM 0x03002680 (ARM)
@ Free the voice (state 0x10).
@ ------------------------------------------------------------------
env_kill:
	mov r1, #0x10                        @ 080326E8
	strb r1, [ip]                        @ 080326EC
L_80326F0:
	str r1, [ip, #0x14]                  @ 080326F0
	sub pc, pc, #0x1e4                   @ 080326F4  -> L_8032518

@ ------------------------------------------------------------------
@ ev_tempo   ROM 0x080326F8 / IWRAM 0x03002690 (ARM)
@ cmd 0: 24-bit tempo in microseconds per quarter note (as MIDI meta FF 51).
@ ------------------------------------------------------------------
ev_tempo:
	bic r2, fp, #3                       @ 080326F8
	ldm r2, {r1, r3}                     @ 080326FC
	and r2, fp, #3                       @ 08032700
	lsls r2, r2, #3                      @ 08032704
	lsrne r1, r1, r2                     @ 08032708
	rsbne r2, r2, #0x20                  @ 0803270C
	orrne r1, r1, r3, lsl r2             @ 08032710
	add fp, fp, #3                       @ 08032714
	bl set_tempo_internal                @ 08032718
	add pc, pc, #0x2b8                   @ 0803271C  -> L_80329DC

@ ------------------------------------------------------------------
@ set_tempo_internal   ROM 0x08032720 / IWRAM 0x030026B8 (ARM)
@ r1 = tempo (us/qn). Also (re)computes seq_frame_time = 60,000,000/3600 us in 24.8
@ fixed point = 16666.67 us, i.e. the sequencer assumes exactly 60 frames/s.
@ ------------------------------------------------------------------
set_tempo_internal:
	stmdb sp!, {lr}                      @ 08032720
	bic r0, r1, #0xff000000              @ 08032724
	ldr r2, lit_8032AFC                  @ 08032728  = seq_tempo
	str r0, [r2]                         @ 0803272C
	ldr r0, lit_8032B00                  @ 08032730  = USEC_PER_MINUTE
	mov r1, #0xe10                       @ 08032734
	bl udiv_32_16                        @ 08032738
	lsl r4, r0, #8                       @ 0803273C
	lsl r0, r1, #0x10                    @ 08032740
	mov r1, #0xe10                       @ 08032744
	bl udiv_32_16                        @ 08032748
	orr r0, r4, r0, lsr #8               @ 0803274C
	ldr r2, lit_8032B04                  @ 08032750  = seq_frame_time
	str r0, [r2]                         @ 08032754
	ldm sp!, {lr}                        @ 08032758
	bx lr                                @ 0803275C

@ ------------------------------------------------------------------
@ ev_delta8   ROM 0x08032760 / IWRAM 0x030026F8 (ARM)
@ cmd 1: delta time, 1 byte (ticks). Converts ticks -> microseconds<<8 and adds to the track clock.
@ ------------------------------------------------------------------
ev_delta8:
	ldr r5, lit_8032B08                  @ 08032760  = seq_division
	ldr r5, [r5]                         @ 08032764
	ldrb r1, [fp], #1                    @ 08032768
	ldr r0, lit_8032B0C                  @ 0803276C  = seq_tempo
	ldr r2, [r0]                         @ 08032770
	mul r1, r2, r1                       @ 08032774
	mov r0, #0                           @ 08032778
	mov r2, r5                           @ 0803277C
	bl sdiv_64_32                        @ 08032780
	lsl r4, r1, #8                       @ 08032784
	lsl r0, r0, #0x10                    @ 08032788
	mov r1, r5                           @ 0803278C
	bl udiv_32_16                        @ 08032790
	orr r1, r4, r0, lsr #8               @ 08032794
	mov r2, #0                           @ 08032798
	ldr r5, [sp]                         @ 0803279C
	ldr r0, lit_8032B10                  @ 080327A0  = seq_track_time
	add r0, r0, r5, lsl #3               @ 080327A4
	ldm r0, {r3, r4}                     @ 080327A8
	adds r1, r3, r1                      @ 080327AC
	adcs r2, r4, r2                      @ 080327B0
	stm r0, {r1, r2}                     @ 080327B4
	add pc, pc, #0x230                   @ 080327B8  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_delta16   ROM 0x080327BC / IWRAM 0x03002754 (ARM)
@ cmd 2: delta time, 2 bytes little-endian.
@ ------------------------------------------------------------------
ev_delta16:
	ldr r5, lit_8032B14                  @ 080327BC  = seq_division
	ldr r5, [r5]                         @ 080327C0
	ldrb r0, [fp], #1                    @ 080327C4
	ldrb r1, [fp], #1                    @ 080327C8
	orr r1, r0, r1, lsl #8               @ 080327CC
	ldr r0, lit_8032B18                  @ 080327D0  = seq_tempo
	ldr r2, [r0]                         @ 080327D4
	umull r1, r0, r2, r1                 @ 080327D8
	mov r2, r5                           @ 080327DC
	bl sdiv_64_32                        @ 080327E0
	lsr r6, r1, #0x18                    @ 080327E4
	lsl r4, r1, #8                       @ 080327E8
	lsl r0, r0, #0x10                    @ 080327EC
	mov r1, r5                           @ 080327F0
	bl udiv_32_16                        @ 080327F4
	orr r1, r4, r0, lsr #8               @ 080327F8
	mov r2, r6                           @ 080327FC
	ldr r5, [sp]                         @ 08032800
	ldr r0, lit_8032B1C                  @ 08032804  = seq_track_time
	add r0, r0, r5, lsl #3               @ 08032808
	ldm r0, {r3, r4}                     @ 0803280C
	adds r1, r3, r1                      @ 08032810
	adcs r2, r4, r2                      @ 08032814
	stm r0, {r1, r2}                     @ 08032818
	add pc, pc, #0x1cc                   @ 0803281C  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_delta24   ROM 0x08032820 / IWRAM 0x030027B8 (ARM)
@ cmd 3: delta time, 3 bytes little-endian.
@ ------------------------------------------------------------------
ev_delta24:
	bic r2, fp, #3                       @ 08032820
	ldm r2, {r1, r3}                     @ 08032824
	and r2, fp, #3                       @ 08032828
	lsls r2, r2, #3                      @ 0803282C
	lsrne r1, r1, r2                     @ 08032830
	rsbne r2, r2, #0x20                  @ 08032834
	orrne r1, r1, r3, lsl r2             @ 08032838
	add fp, fp, #3                       @ 0803283C
	bic r1, r1, #0xff000000              @ 08032840
	ldr r0, lit_8032B20                  @ 08032844  = seq_tempo
	ldr r2, [r0]                         @ 08032848
	umull r1, r0, r2, r1                 @ 0803284C
	ldr r5, lit_8032B24                  @ 08032850  = seq_division
	ldr r5, [r5]                         @ 08032854
	mov r2, r5                           @ 08032858
	bl sdiv_64_32                        @ 0803285C
	lsr r6, r1, #0x18                    @ 08032860
	lsl r4, r1, #8                       @ 08032864
	lsl r0, r0, #0x10                    @ 08032868
	mov r1, r5                           @ 0803286C
	bl udiv_32_16                        @ 08032870
	orr r1, r4, r0, lsr #8               @ 08032874
	mov r2, r6                           @ 08032878
	ldr r5, [sp]                         @ 0803287C
	ldr r0, lit_8032B28                  @ 08032880  = seq_track_time
	add r0, r0, r5, lsl #3               @ 08032884
	ldm r0, {r3, r4}                     @ 08032888
	adds r1, r3, r1                      @ 0803288C
	adcs r2, r4, r2                      @ 08032890
	stm r0, {r1, r2}                     @ 08032894
	add pc, pc, #0x150                   @ 08032898  -> seq_after_delta

@ ------------------------------------------------------------------
@ ev_note_on   ROM 0x0803289C / IWRAM 0x03002834 (ARM)
@ cmd 4/5: note on <key> <velocity>. Allocates one of the channel's 6 voices
@ (free first, then released); mono mode always reuses slot 0. Resolves rhythm sets (0x22)
@ and key splits (0x23) through the instrument's keymap. Note is dropped if no voice is free.
@ ------------------------------------------------------------------
ev_note_on:
	ldr r4, lit_8032B2C                  @ 0803289C  = cfg_chan_pool_bytes
	ldr r4, [r4]                         @ 080328A0
	ldr r3, lit_8032B30                  @ 080328A4  = music_voices
	add r3, r3, r4                       @ 080328A8
	mla r5, r1, r4, r3                   @ 080328AC
	ldr r2, lit_8032B34                  @ 080328B0  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 080328B4
	ldr r0, lit_8032B38                  @ 080328B8  = chan_mono
	ldrb r0, [r0, r1]                    @ 080328BC
	cmp r0, #0                           @ 080328C0
	bne L_8032904                        @ 080328C4
L_80328C8:
	ldrb r0, [r5, -r2]                   @ 080328C8
	cmp r0, #0x10                        @ 080328CC
	beq L_8032904                        @ 080328D0
	subs r2, r2, #0x28                   @ 080328D4
	bgt L_80328C8                        @ 080328D8
	ldr r2, lit_8032B3C                  @ 080328DC  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 080328E0
L_80328E4:
	ldrb r0, [r5, -r2]                   @ 080328E4
	cmp r0, #0x12                        @ 080328E8
	beq L_8032904                        @ 080328EC
	subs r2, r2, #0x28                   @ 080328F0
	bgt L_80328E4                        @ 080328F4
	ldrb r4, [fp], #1                    @ 080328F8
	ldrb r0, [fp], #1                    @ 080328FC
	b L_8032984                          @ 08032900
L_8032904:
	sub r5, r5, r2                       @ 08032904
	ldrb r4, [fp], #1                    @ 08032908
	mov sb, r4                           @ 0803290C
	mov r7, #4                           @ 08032910
	ldr r6, lit_8032B40                  @ 08032914  = chan_instrument
	mla r2, r1, r7, r6                   @ 08032918
	ldr r2, [r2]                         @ 0803291C
	ldr r7, [r2]                         @ 08032920
	cmp r7, #0x20                        @ 08032924  0x20 = plain instrument
	beq L_8032970                        @ 08032928
	cmp r7, #0x21                        @ 0803292C
	beq L_8032970                        @ 08032930
	cmp r7, #0x22                        @ 08032934  0x22 = rhythm set
	beq L_8032944                        @ 08032938
	cmp r7, #0x23                        @ 0803293C  0x23 = key split
	beq L_803295C                        @ 08032940
L_8032944:
	ldr r0, [r2, #0x1c]                  @ 08032944
	ldrb r1, [r0, r4]                    @ 08032948
	ldr r0, [r2, #0x20]                  @ 0803294C
	ldr r2, [r0, r1, lsl #2]             @ 08032950
	ldr sb, [r2, #0xc]                   @ 08032954
	b L_8032970                          @ 08032958
L_803295C:
	ldr r0, [r2, #0x1c]                  @ 0803295C
	ldrb r1, [r0, r4]                    @ 08032960
	ldr r0, [r2, #0x20]                  @ 08032964
	ldr r2, [r0, r1, lsl #2]             @ 08032968
	b L_8032970                          @ 0803296C
L_8032970:
	ldr r7, [r2, #4]                     @ 08032970
	ldrb r3, [fp], #1                    @ 08032974
	add r3, r3, #1                       @ 08032978
	mov r1, #0x10000                     @ 0803297C
	bl voice_start                       @ 08032980
L_8032984:
	add pc, pc, #0x50                    @ 08032984  -> L_80329DC

@ ------------------------------------------------------------------
@ seq_update   ROM 0x08032988 / IWRAM 0x03002920 (ARM)
@ Sequencer tick, once per frame: for each track subtract one frame of time from its clock;
@ while the clock is negative, execute events. Stops the song when every track sits on END.
@ ------------------------------------------------------------------
seq_update:
	stmdb sp!, {lr}                      @ 08032988
	sub sp, sp, #0xc                     @ 0803298C
	mov r0, #0                           @ 08032990
	str r0, [sp, #8]                     @ 08032994
	mvn r0, #0                           @ 08032998
	str r0, [sp]                         @ 0803299C
	b L_8032A1C                          @ 080329A0
L_80329A4:
	str r0, [sp]                         @ 080329A4
	ldr r4, lit_8032B44                  @ 080329A8  = seq_track_time
	add r4, r4, r0, lsl #3               @ 080329AC
	ldr r1, lit_8032B48                  @ 080329B0  = seq_frame_time
	ldm r4, {r2, r3}                     @ 080329B4
	ldr r5, [r1]                         @ 080329B8
	subs r2, r2, r5                      @ 080329BC
	sbcs r3, r3, #0                      @ 080329C0
	stm r4, {r2, r3}                     @ 080329C4
	bpl L_8032A1C                        @ 080329C8
	ldr fp, lit_8032B4C                  @ 080329CC  = seq_track_ptr
	ldr r0, [sp]                         @ 080329D0
	ldr fp, [fp, r0, lsl #2]             @ 080329D4

@ seq_next_event: fetch and dispatch the next event of the current track
seq_next_event:
	add ip, pc, #0x78                    @ 080329D8  = seq_cmd_table
L_80329DC:
	ldrb r0, [fp], #1                    @ 080329DC  event byte: high nibble = MIDI channel, low nibble = command
	lsr r1, r0, #4                       @ 080329E0
	bic r0, r0, #0xf0                    @ 080329E4
	ldr r0, [ip, r0, lsl #2]             @ 080329E8
	add pc, r0, ip                       @ 080329EC  computed jump into handler

@ seq_after_delta: keep going while the track clock is still negative
seq_after_delta:
	ldr r0, [sp]                         @ 080329F0
	ldr r1, lit_8032B50                  @ 080329F4  = seq_track_time+0x4
	ldr r1, [r1, r0, lsl #3]             @ 080329F8
	cmp r1, #0                           @ 080329FC
	bmi L_8032A08                        @ 08032A00
	b L_8032A0C                          @ 08032A04
L_8032A08:
	b seq_next_event                     @ 08032A08
L_8032A0C:
	mov r0, r0                           @ 08032A0C

@ seq_track_yield: save the track pointer and move to the next track
seq_track_yield:
	ldr r0, [sp]                         @ 08032A10
	ldr r2, lit_8032B54                  @ 08032A14  = seq_track_ptr
	str fp, [r2, r0, lsl #2]             @ 08032A18
L_8032A1C:
	ldr r1, lit_8032B58                  @ 08032A1C  = seq_num_tracks
	ldr r1, [r1]                         @ 08032A20
	ldr r0, [sp]                         @ 08032A24
	adds r0, r0, #1                      @ 08032A28
	cmp r0, r1                           @ 08032A2C
	bne L_80329A4                        @ 08032A30
	ldr r0, [sp, #8]                     @ 08032A34
	cmp r0, r1                           @ 08032A38
	bne L_8032A4C                        @ 08032A3C
	ldr r0, lit_8032B5C                  @ 08032A40  = seq_current_song
	mvn r1, #0                           @ 08032A44
	str r1, [r0]                         @ 08032A48
L_8032A4C:
	add sp, sp, #0xc                     @ 08032A4C
	ldm sp!, {lr}                        @ 08032A50
	bx lr                                @ 08032A54

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
lit_8032A8C:
	.word mix_buffer
lit_8032A90:
	.word mix_max_voices
lit_8032A94:
	.word cfg_sfx_pool_bytes
lit_8032A98:
	.word sfx_voices
lit_8032A9C:
	.word cfg_sfx_pool_bytes
lit_8032AA0:
	.word music_paused
lit_8032AA4:
	.word cfg_music_pool_bytes
lit_8032AA8:
	.word music_voices
lit_8032AAC:
	.word cfg_music_pool_bytes
lit_8032AB0:
	.word mix_max_voices
lit_8032AB4:
	.word clear_mix_buffer+1
lit_8032AB8:
	.word dma_buffer_flag
lit_8032ABC:
	.word cfg_buffer_a
lit_8032AC0:
	.word cfg_buffer_b
lit_8032AC4:
	.word mix_buffer
lit_8032AC8:
	.word mix_samples_per_frame
lit_8032ACC:
	.word cfg_sfx_pool_bytes
lit_8032AD0:
	.word sfx_voices
lit_8032AD4:
	.word cfg_music_pool_bytes
lit_8032AD8:
	.word music_voices
lit_8032ADC:
	.word mix_samples_per_frame
lit_8032AE0:
	.word 0x007FFFFF
lit_8032AE4:
	.word cfg_sfx_pool_bytes
lit_8032AE8:
	.word sfx_voices
lit_8032AEC:
	.word cfg_music_pool_bytes
lit_8032AF0:
	.word music_voices
lit_8032AF4:
	.word adsr_rate_table
lit_8032AF8:
	.word adsr_rate_table
lit_8032AFC:
	.word seq_tempo
lit_8032B00:
	.word USEC_PER_MINUTE
lit_8032B04:
	.word seq_frame_time
lit_8032B08:
	.word seq_division
lit_8032B0C:
	.word seq_tempo
lit_8032B10:
	.word seq_track_time
lit_8032B14:
	.word seq_division
lit_8032B18:
	.word seq_tempo
lit_8032B1C:
	.word seq_track_time
lit_8032B20:
	.word seq_tempo
lit_8032B24:
	.word seq_division
lit_8032B28:
	.word seq_track_time
lit_8032B2C:
	.word cfg_chan_pool_bytes
lit_8032B30:
	.word music_voices
lit_8032B34:
	.word cfg_chan_pool_bytes
lit_8032B38:
	.word chan_mono
lit_8032B3C:
	.word cfg_chan_pool_bytes
lit_8032B40:
	.word chan_instrument
lit_8032B44:
	.word seq_track_time
lit_8032B48:
	.word seq_frame_time
lit_8032B4C:
	.word seq_track_ptr
lit_8032B50:
	.word seq_track_time+0x4
lit_8032B54:
	.word seq_track_ptr
lit_8032B58:
	.word seq_num_tracks
lit_8032B5C:
	.word seq_current_song

@ ------------------------------------------------------------------
@ ev_note_off   ROM 0x08032B60 / IWRAM 0x03002AF8 (ARM)
@ cmd 6: note off <key> <velocity(ignored)>. Releases the first key-on voice of the channel
@ whose stored key matches.
@ ------------------------------------------------------------------
ev_note_off:
	ldrb r6, [fp], #1                    @ 08032B60
	ldrb r7, [fp], #1                    @ 08032B64
	ldr r4, lit_8032F20                  @ 08032B68  = cfg_chan_pool_bytes
	ldr r4, [r4]                         @ 08032B6C
	ldr r3, lit_8032F24                  @ 08032B70  = music_voices
	add r3, r3, r4                       @ 08032B74
	mla r5, r1, r4, r3                   @ 08032B78
	ldr r2, lit_8032F28                  @ 08032B7C  = cfg_chan_pool_bytes
	ldr r2, [r2]                         @ 08032B80
L_8032B84:
	ldrb r0, [r5, -r2]                   @ 08032B84
	cmp r0, #0x11                        @ 08032B88
	bleq L_8032B9C                       @ 08032B8C
	subs r2, r2, #0x28                   @ 08032B90
	bgt L_8032B84                        @ 08032B94
	b L_8032BB4                          @ 08032B98
L_8032B9C:
	sub r0, r5, r2                       @ 08032B9C
	ldrb r1, [r0, #2]                    @ 08032BA0
	cmp r1, r6                           @ 08032BA4
	bxne lr                              @ 08032BA8
	mov r1, #0x12                        @ 08032BAC
	strb r1, [r0]                        @ 08032BB0
L_8032BB4:
	sub pc, pc, #0x1e0                   @ 08032BB4  -> L_80329DC

@ ------------------------------------------------------------------
@ ev_controller   ROM 0x08032BB8 / IWRAM 0x03002B50 (ARM)
@ cmd 7: controller <cc> <value>. Handled: 1 mod wheel, 7 volume, 100 (stored, never read),
@ 102 loop start (save track pointer), 103 loop end (jump back), 126 mono on, 127 poly on.
@ ------------------------------------------------------------------
ev_controller:
	ldrb r2, [fp], #1                    @ 08032BB8
	ldrb r3, [fp], #1                    @ 08032BBC
	cmp r2, #1                           @ 08032BC0
	beq L_8032BFC                        @ 08032BC4
	cmp r2, #7                           @ 08032BC8
	beq L_8032C10                        @ 08032BCC
	cmp r2, #0x64                        @ 08032BD0
	beq L_8032C1C                        @ 08032BD4
	cmp r2, #0x66                        @ 08032BD8
	beq L_8032C28                        @ 08032BDC
	cmp r2, #0x67                        @ 08032BE0
	beq L_8032C38                        @ 08032BE4
	cmp r2, #0x7e                        @ 08032BE8
	beq L_8032C48                        @ 08032BEC
	cmp r2, #0x7f                        @ 08032BF0
	beq L_8032C58                        @ 08032BF4
	b L_8032C68                          @ 08032BF8
L_8032BFC:
	ldr r5, lit_8032F2C                  @ 08032BFC  = chan_mod ; CC1  mod wheel
	mov r2, #8                           @ 08032C00
	mla r5, r1, r2, r5                   @ 08032C04
	str r3, [r5]                         @ 08032C08
	b L_8032C68                          @ 08032C0C
L_8032C10:
	ldr r5, lit_8032F30                  @ 08032C10  = chan_volume ; CC7  volume
	strb r3, [r5, r1]                    @ 08032C14
	b L_8032C68                          @ 08032C18
L_8032C1C:
	ldr r5, lit_8032F34                  @ 08032C1C  = chan_cc100 ; CC100 (dead store)
	strb r3, [r5, r1]                    @ 08032C20
	b L_8032C68                          @ 08032C24
L_8032C28:
	ldr r4, [sp]                         @ 08032C28  CC102 loop start
	ldr r5, lit_8032F38                  @ 08032C2C  = seq_loop_ptr
	str fp, [r5, r4, lsl #2]             @ 08032C30
	b L_8032C68                          @ 08032C34
L_8032C38:
	ldr r4, [sp]                         @ 08032C38  CC103 loop end
	ldr r5, lit_8032F3C                  @ 08032C3C  = seq_loop_ptr
	ldr fp, [r5, r4, lsl #2]             @ 08032C40
	b L_8032C68                          @ 08032C44
L_8032C48:
	ldr r5, lit_8032F40                  @ 08032C48  = chan_mono ; CC126 mono
	mov r3, #1                           @ 08032C4C
	strb r3, [r5, r1]                    @ 08032C50
	b L_8032C68                          @ 08032C54
L_8032C58:
	ldr r5, lit_8032F44                  @ 08032C58  = chan_mono ; CC127 poly
	mov r3, #0                           @ 08032C5C
	strb r3, [r5, r1]                    @ 08032C60
	b L_8032C68                          @ 08032C64
L_8032C68:
	sub pc, pc, #0x294                   @ 08032C68  -> L_80329DC

@ ------------------------------------------------------------------
@ ev_program   ROM 0x08032C6C / IWRAM 0x03002C04 (ARM)
@ cmd 8: program change <prog>: prog -> prog_map byte -> instrument table entry.
@ ------------------------------------------------------------------
ev_program:
	ldrb r3, [fp], #1                    @ 08032C6C
	ldr r2, lit_8032F48                  @ 08032C70  = seq_prog_map_ptr
	ldr r2, [r2]                         @ 08032C74
	ldrb r2, [r2, r3]                    @ 08032C78
	ldr r3, lit_8032F4C                  @ 08032C7C  = seq_inst_table_ptr
	ldr r3, [r3]                         @ 08032C80
	ldr r4, [r3, r2, lsl #2]             @ 08032C84
	ldr r8, lit_8032F50                  @ 08032C88  = chan_instrument
	mov r2, #4                           @ 08032C8C
	mla r8, r2, r1, r8                   @ 08032C90
	str r4, [r8]                         @ 08032C94
	sub pc, pc, #0x2c4                   @ 08032C98  -> L_80329DC

@ ------------------------------------------------------------------
@ ev_skip1   ROM 0x08032C9C / IWRAM 0x03002C34 (ARM)
@ cmd 9: one data byte, ignored (channel pressure slot).
@ ------------------------------------------------------------------
ev_skip1:
	add fp, fp, #1                       @ 08032C9C
	sub pc, pc, #0x2cc                   @ 08032CA0  -> L_80329DC

@ ------------------------------------------------------------------
@ ev_pitch_bend   ROM 0x08032CA4 / IWRAM 0x03002C3C (ARM)
@ cmd 10: pitch bend, 14-bit value stored as a little-endian 16-bit word (0x2000 = centre).
@ ------------------------------------------------------------------
ev_pitch_bend:
	mov r3, r1                           @ 08032CA4
	ldrb r0, [fp], #1                    @ 08032CA8
	ldrb r1, [fp], #1                    @ 08032CAC
	orr r1, r0, r1, lsl #8               @ 08032CB0
	ldr r2, lit_8032F54                  @ 08032CB4  = chan_bend
	str r1, [r2, r3, lsl #2]             @ 08032CB8
	sub pc, pc, #0x2e8                   @ 08032CBC  -> L_80329DC

@ ------------------------------------------------------------------
@ ev_end_track   ROM 0x08032CC0 / IWRAM 0x03002C58 (ARM)
@ cmd 11: end of track - re-executed every frame; counts towards 'song finished'.
@ ------------------------------------------------------------------
ev_end_track:
	sub fp, fp, #1                       @ 08032CC0
	ldr r0, [sp, #8]                     @ 08032CC4
	add r0, r0, #1                       @ 08032CC8
	str r0, [sp, #8]                     @ 08032CCC
	sub pc, pc, #0x2c8                   @ 08032CD0  -> seq_track_yield

@ ------------------------------------------------------------------
@ ev_nop   ROM 0x08032CD4 / IWRAM 0x03002C6C (ARM)
@ cmd 12: no operation.
@ ------------------------------------------------------------------
ev_nop:
	sub pc, pc, #0x300                   @ 08032CD4  -> L_80329DC

@ ------------------------------------------------------------------
@ udiv_32_16   ROM 0x08032CD8 / IWRAM 0x03002C70 (ARM)
@ Unsigned r0/r1 with r0 < r1<<16. Out: r0 = quotient (16 bit), r1 = remainder.
@ ------------------------------------------------------------------
udiv_32_16:
	rsb r1, r1, #0                       @ 08032CD8
	lsls r1, r1, #0xf                    @ 08032CDC
	adds r0, r1, r0                      @ 08032CE0
	rsblo r0, r1, r0                     @ 08032CE4
	adcs r0, r1, r0, lsl #1              @ 08032CE8
	rsblo r0, r1, r0                     @ 08032CEC
	adcs r0, r1, r0, lsl #1              @ 08032CF0
	rsblo r0, r1, r0                     @ 08032CF4
	adcs r0, r1, r0, lsl #1              @ 08032CF8
	rsblo r0, r1, r0                     @ 08032CFC
	adcs r0, r1, r0, lsl #1              @ 08032D00
	rsblo r0, r1, r0                     @ 08032D04
	adcs r0, r1, r0, lsl #1              @ 08032D08
	rsblo r0, r1, r0                     @ 08032D0C
	adcs r0, r1, r0, lsl #1              @ 08032D10
	rsblo r0, r1, r0                     @ 08032D14
	adcs r0, r1, r0, lsl #1              @ 08032D18
	rsblo r0, r1, r0                     @ 08032D1C
	adcs r0, r1, r0, lsl #1              @ 08032D20
	rsblo r0, r1, r0                     @ 08032D24
	adcs r0, r1, r0, lsl #1              @ 08032D28
	rsblo r0, r1, r0                     @ 08032D2C
	adcs r0, r1, r0, lsl #1              @ 08032D30
	rsblo r0, r1, r0                     @ 08032D34
	adcs r0, r1, r0, lsl #1              @ 08032D38
	rsblo r0, r1, r0                     @ 08032D3C
	adcs r0, r1, r0, lsl #1              @ 08032D40
	rsblo r0, r1, r0                     @ 08032D44
	adcs r0, r1, r0, lsl #1              @ 08032D48
	rsblo r0, r1, r0                     @ 08032D4C
	adcs r0, r1, r0, lsl #1              @ 08032D50
	rsblo r0, r1, r0                     @ 08032D54
	adcs r0, r1, r0, lsl #1              @ 08032D58
	rsblo r0, r1, r0                     @ 08032D5C
	adc r0, r0, r0                       @ 08032D60
	lsr r1, r0, #0x10                    @ 08032D64
	bic r0, r0, r1, lsl #16              @ 08032D68
	bx lr                                @ 08032D6C

@ ------------------------------------------------------------------
@ sdiv_64_32   ROM 0x08032D70 / IWRAM 0x03002D08 (ARM)
@ Signed 64/32 division: (r0:r1) / r2. Out: r1 = quotient, r0 = remainder.
@ ------------------------------------------------------------------
sdiv_64_32:
	movs r3, r2                          @ 08032D70
	rsbpl r2, r2, #0                     @ 08032D74
	lsr r3, r3, #1                       @ 08032D78
	eors r3, r3, r0, asr #1              @ 08032D7C
	bpl L_8032D8C                        @ 08032D80
	rsbs r1, r1, #0                      @ 08032D84
	rsc r0, r0, #0                       @ 08032D88
L_8032D8C:
	adds r1, r1, r1                      @ 08032D8C
	adcs r0, r2, r0, lsl #1              @ 08032D90
	rsblo r0, r2, r0                     @ 08032D94
	adcs r1, r1, r1                      @ 08032D98
	adcs r0, r2, r0, lsl #1              @ 08032D9C
	rsblo r0, r2, r0                     @ 08032DA0
	adcs r1, r1, r1                      @ 08032DA4
	adcs r0, r2, r0, lsl #1              @ 08032DA8
	rsblo r0, r2, r0                     @ 08032DAC
	adcs r1, r1, r1                      @ 08032DB0
	adcs r0, r2, r0, lsl #1              @ 08032DB4
	rsblo r0, r2, r0                     @ 08032DB8
	adcs r1, r1, r1                      @ 08032DBC
	adcs r0, r2, r0, lsl #1              @ 08032DC0
	rsblo r0, r2, r0                     @ 08032DC4
	adcs r1, r1, r1                      @ 08032DC8
	adcs r0, r2, r0, lsl #1              @ 08032DCC
	rsblo r0, r2, r0                     @ 08032DD0
	adcs r1, r1, r1                      @ 08032DD4
	adcs r0, r2, r0, lsl #1              @ 08032DD8
	rsblo r0, r2, r0                     @ 08032DDC
	adcs r1, r1, r1                      @ 08032DE0
	adcs r0, r2, r0, lsl #1              @ 08032DE4
	rsblo r0, r2, r0                     @ 08032DE8
	adcs r1, r1, r1                      @ 08032DEC
	adcs r0, r2, r0, lsl #1              @ 08032DF0
	rsblo r0, r2, r0                     @ 08032DF4
	adcs r1, r1, r1                      @ 08032DF8
	adcs r0, r2, r0, lsl #1              @ 08032DFC
	rsblo r0, r2, r0                     @ 08032E00
	adcs r1, r1, r1                      @ 08032E04
	adcs r0, r2, r0, lsl #1              @ 08032E08
	rsblo r0, r2, r0                     @ 08032E0C
	adcs r1, r1, r1                      @ 08032E10
	adcs r0, r2, r0, lsl #1              @ 08032E14
	rsblo r0, r2, r0                     @ 08032E18
	adcs r1, r1, r1                      @ 08032E1C
	adcs r0, r2, r0, lsl #1              @ 08032E20
	rsblo r0, r2, r0                     @ 08032E24
	adcs r1, r1, r1                      @ 08032E28
	adcs r0, r2, r0, lsl #1              @ 08032E2C
	rsblo r0, r2, r0                     @ 08032E30
	adcs r1, r1, r1                      @ 08032E34
	adcs r0, r2, r0, lsl #1              @ 08032E38
	rsblo r0, r2, r0                     @ 08032E3C
	adcs r1, r1, r1                      @ 08032E40
	adcs r0, r2, r0, lsl #1              @ 08032E44
	rsblo r0, r2, r0                     @ 08032E48
	adcs r1, r1, r1                      @ 08032E4C
	adcs r0, r2, r0, lsl #1              @ 08032E50
	rsblo r0, r2, r0                     @ 08032E54
	adcs r1, r1, r1                      @ 08032E58
	adcs r0, r2, r0, lsl #1              @ 08032E5C
	rsblo r0, r2, r0                     @ 08032E60
	adcs r1, r1, r1                      @ 08032E64
	adcs r0, r2, r0, lsl #1              @ 08032E68
	rsblo r0, r2, r0                     @ 08032E6C
	adcs r1, r1, r1                      @ 08032E70
	adcs r0, r2, r0, lsl #1              @ 08032E74
	rsblo r0, r2, r0                     @ 08032E78
	adcs r1, r1, r1                      @ 08032E7C
	adcs r0, r2, r0, lsl #1              @ 08032E80
	rsblo r0, r2, r0                     @ 08032E84
	adcs r1, r1, r1                      @ 08032E88
	adcs r0, r2, r0, lsl #1              @ 08032E8C
	rsblo r0, r2, r0                     @ 08032E90
	adcs r1, r1, r1                      @ 08032E94
	adcs r0, r2, r0, lsl #1              @ 08032E98
	rsblo r0, r2, r0                     @ 08032E9C
	adcs r1, r1, r1                      @ 08032EA0
	adcs r0, r2, r0, lsl #1              @ 08032EA4
	rsblo r0, r2, r0                     @ 08032EA8
	adcs r1, r1, r1                      @ 08032EAC
	adcs r0, r2, r0, lsl #1              @ 08032EB0
	rsblo r0, r2, r0                     @ 08032EB4
	adcs r1, r1, r1                      @ 08032EB8
	adcs r0, r2, r0, lsl #1              @ 08032EBC
	rsblo r0, r2, r0                     @ 08032EC0
	adcs r1, r1, r1                      @ 08032EC4
	adcs r0, r2, r0, lsl #1              @ 08032EC8
	rsblo r0, r2, r0                     @ 08032ECC
	adcs r1, r1, r1                      @ 08032ED0
	adcs r0, r2, r0, lsl #1              @ 08032ED4
	rsblo r0, r2, r0                     @ 08032ED8
	adcs r1, r1, r1                      @ 08032EDC
	adcs r0, r2, r0, lsl #1              @ 08032EE0
	rsblo r0, r2, r0                     @ 08032EE4
	adcs r1, r1, r1                      @ 08032EE8
	adcs r0, r2, r0, lsl #1              @ 08032EEC
	rsblo r0, r2, r0                     @ 08032EF0
	adcs r1, r1, r1                      @ 08032EF4
	adcs r0, r2, r0, lsl #1              @ 08032EF8
	rsblo r0, r2, r0                     @ 08032EFC
	adcs r1, r1, r1                      @ 08032F00
	adcs r0, r2, r0, lsl #1              @ 08032F04
	rsblo r0, r2, r0                     @ 08032F08
	adcs r1, r1, r1                      @ 08032F0C
	lsls r3, r3, #1                      @ 08032F10
	rsbmi r1, r1, #0                     @ 08032F14
	rsbhs r0, r0, #0                     @ 08032F18
	bx lr                                @ 08032F1C
lit_8032F20:
	.word cfg_chan_pool_bytes
lit_8032F24:
	.word music_voices
lit_8032F28:
	.word cfg_chan_pool_bytes
lit_8032F2C:
	.word chan_mod
lit_8032F30:
	.word chan_volume
lit_8032F34:
	.word chan_cc100
lit_8032F38:
	.word seq_loop_ptr
lit_8032F3C:
	.word seq_loop_ptr
lit_8032F40:
	.word chan_mono
lit_8032F44:
	.word chan_mono
lit_8032F48:
	.word seq_prog_map_ptr
lit_8032F4C:
	.word seq_inst_table_ptr
lit_8032F50:
	.word chan_instrument
lit_8032F54:
	.word chan_bend

@ ------------------------------------------------------------------
@ mix_voice   ROM 0x08032F58 / IWRAM 0x03002EF0 (ARM)
@ Mix one voice into the s16 buffer at r5 with linear interpolation. Volume =
@ master * (chan_volume+1)/128 * vel/128 * env/2^19 (SFX: sfx_master * vol/128 * env).
@ The first voice of a frame stores, later voices add. Position is NOT written back.
@ ------------------------------------------------------------------
mix_voice:
	str lr, [sp, #0x1c]                  @ 08032F58
	str r0, [sp, #0x20]                  @ 08032F5C
	bl calc_pitch                        @ 08032F60
	str r7, [r0, #8]                     @ 08032F64
	ldrsb r6, [r0, #6]                   @ 08032F68
	cmp r6, #0                           @ 08032F6C
	ldr r1, lit_8033278                  @ 08032F70  = sfx_master_volume
	bmi L_8032F7C                        @ 08032F74
	ldr r1, lit_803327C                  @ 08032F78  = music_master_volume
L_8032F7C:
	ldr r4, [r1]                         @ 08032F7C
	bmi L_8032F98                        @ 08032F80
	ldr r3, lit_8033280                  @ 08032F84  = chan_volume
	ldrb r3, [r3, r6]                    @ 08032F88
	add r3, r3, #1                       @ 08032F8C
	mul r4, r3, r4                       @ 08032F90
	lsr r4, r4, #7                       @ 08032F94
L_8032F98:
	ldrb r3, [r0, #3]                    @ 08032F98
	mul r4, r3, r4                       @ 08032F9C
	lsr r4, r4, #7                       @ 08032FA0
	ldr sb, [r0, #0x14]                  @ 08032FA4
	mul r4, sb, r4                       @ 08032FA8
	lsr r4, r4, #0x13                    @ 08032FAC
	ldr r6, [r0, #0x24]                  @ 08032FB0
	umull sb, sl, r6, r7                 @ 08032FB4
	lsr r7, sb, #0x10                    @ 08032FB8
	add r7, r7, sl, lsl #16              @ 08032FBC
	mov r6, #0                           @ 08032FC0
	mov r3, #0                           @ 08032FC4
	ldr sb, lit_8033284                  @ 08032FC8  = mix_samples_per_frame
	ldr sb, [sb]                         @ 08032FCC
	add sb, r5, sb, lsl #1               @ 08032FD0
	ldr r6, [r0, #0x10]                  @ 08032FD4
	ldr sl, [r0, #0x20]                  @ 08032FD8
	ldr sl, [sl, #0x18]                  @ 08032FDC
	ldr r0, [r0, #0xc]                   @ 08032FE0
	ldr fp, lit_8033288                  @ 08032FE4  = 0x007FFFFF
	ldr r3, lit_803328C                  @ 08032FE8  = mix_max_voices
	ldr r3, [r3]                         @ 08032FEC
	ldr r8, [sp, #0x10]                  @ 08032FF0
	cmp r3, r8                           @ 08032FF4
	bne L_803303C                        @ 08032FF8
L_8032FFC:
	ldrsb r1, [r0]                       @ 08032FFC
	ldrsb r2, [r0, #1]                   @ 08033000
	sub r2, r2, r1                       @ 08033004
	mul r3, r6, r2                       @ 08033008
	add r1, r1, r3, asr #23              @ 0803300C  linear interpolation
	mul r2, r1, r4                       @ 08033010
	asr r2, r2, #7                       @ 08033014
	strh r2, [r5], #2                    @ 08033018
	add r6, r6, r7                       @ 0803301C
	add r0, r0, r6, lsr #23              @ 08033020
	and r6, r6, fp                       @ 08033024
	cmp r0, sl                           @ 08033028
	blge mix_voice_sample_end            @ 0803302C
	cmp r5, sb                           @ 08033030
	bne L_8032FFC                        @ 08033034
	b L_8033108                          @ 08033038
L_803303C:
	ldrsb r1, [r0]                       @ 0803303C
	ldrsb r2, [r0, #1]                   @ 08033040
	sub r2, r2, r1                       @ 08033044
	mul r3, r6, r2                       @ 08033048
	add r1, r1, r3, asr #23              @ 0803304C
	mul r2, r1, r4                       @ 08033050
	ldrsh r1, [r5]                       @ 08033054
	add r1, r1, r2, asr #7               @ 08033058
	strh r1, [r5], #2                    @ 0803305C
	add r6, r6, r7                       @ 08033060
	add r0, r0, r6, lsr #23              @ 08033064
	and r6, r6, fp                       @ 08033068
	cmp r0, sl                           @ 0803306C
	blge mix_voice_sample_end            @ 08033070
	ldrsb r1, [r0]                       @ 08033074
	ldrsb r2, [r0, #1]                   @ 08033078
	sub r2, r2, r1                       @ 0803307C
	mul r3, r6, r2                       @ 08033080
	add r1, r1, r3, asr #23              @ 08033084
	mul r2, r1, r4                       @ 08033088
	ldrsh r1, [r5]                       @ 0803308C
	add r1, r1, r2, asr #7               @ 08033090
	strh r1, [r5], #2                    @ 08033094
	add r6, r6, r7                       @ 08033098
	add r0, r0, r6, lsr #23              @ 0803309C
	and r6, r6, fp                       @ 080330A0
	cmp r0, sl                           @ 080330A4
	blge mix_voice_sample_end            @ 080330A8
	cmp r5, sb                           @ 080330AC
	bne L_803303C                        @ 080330B0
	b L_8033108                          @ 080330B4

@ mix_voice_sample_end: end of sample reached while mixing
mix_voice_sample_end:
	ldr r8, [sp, #0x20]                  @ 080330B8
	ldrb r3, [r8, #1]                    @ 080330BC
	cmp r3, #1                           @ 080330C0
	beq L_80330E0                        @ 080330C4
	cmp r3, #2                           @ 080330C8
	beq L_80330F8                        @ 080330CC
	cmp r3, #3                           @ 080330D0
	beq L_80330EC                        @ 080330D4
	cmp r3, #4                           @ 080330D8
	beq L_80330F8                        @ 080330DC
L_80330E0:
	mov r3, #0x10                        @ 080330E0
	strb r3, [r8]                        @ 080330E4
	b L_8033108                          @ 080330E8
L_80330EC:
	mov r3, #0x10                        @ 080330EC
	strb r3, [r8]                        @ 080330F0
	b L_8033108                          @ 080330F4
L_80330F8:
	ldr r3, [r8, #0x20]                  @ 080330F8
	ldr r3, [r3, #0x14]                  @ 080330FC
	sub r0, r0, r3                       @ 08033100
	bx lr                                @ 08033104
L_8033108:
	ldr lr, [sp, #0x1c]                  @ 08033108
	bx lr                                @ 0803310C

@ ------------------------------------------------------------------
@ calc_pitch   ROM 0x08033110 / IWRAM 0x030030A8 (ARM)
@ Return r7 = per-sample step (9.23 fixed) for voice r0: key - root + fine tune (cents)
@ + pitch bend * range + LFO * modwheel * depth, through pitch_table, scaled by the sample
@ rate and mix_pitch_scale (2^38 / mixing rate).
@ ------------------------------------------------------------------
calc_pitch:
	ldr r4, [r0, #0x20]                  @ 08033110
	ldr r3, [r4, #0x34]                  @ 08033114
	ldr r7, lit_8033290                  @ 08033118  = 0x028F5C29
	smull r1, r2, r7, r3                 @ 0803311C
	push {r1, r2}                        @ 08033120
	ldrsb r8, [r0, #6]                   @ 08033124
	cmp r8, #0                           @ 08033128
	bmi L_8033134                        @ 0803312C
	b L_8033148                          @ 08033130
L_8033134:
	mov r1, #0                           @ 08033134
	mov r2, #0                           @ 08033138
	push {r1, r2}                        @ 0803313C
	push {r1, r2}                        @ 08033140
	b L_8033214                          @ 08033144
L_8033148:
	mov r7, #4                           @ 08033148
	ldr r6, lit_8033294                  @ 0803314C  = chan_instrument
	mla r2, r8, r7, r6                   @ 08033150
	ldr r2, [r2]                         @ 08033154
	ldr r3, [r2, #0x38]                  @ 08033158
	mov r7, #0x80000                     @ 0803315C
	mul r3, r7, r3                       @ 08033160
	ldrsb r7, [r0, #6]                   @ 08033164
	ldr r8, lit_8033298                  @ 08033168  = chan_bend
	mov r1, #4                           @ 0803316C
	mla r8, r7, r1, r8                   @ 08033170
	ldr r7, [r8]                         @ 08033174
	sub r7, r7, #0x2000                  @ 08033178
	smull r1, r2, r7, r3                 @ 0803317C
	push {r1, r2}                        @ 08033180
	ldrsb r8, [r0, #6]                   @ 08033184
	mov r7, #4                           @ 08033188
	ldr r6, lit_803329C                  @ 0803318C  = chan_instrument
	mla r2, r8, r7, r6                   @ 08033190
	ldr r2, [r2]                         @ 08033194
	ldr r2, [r2, #0x40]                  @ 08033198
	ldrsb r8, [r0, #6]                   @ 0803319C
	mov r7, #8                           @ 080331A0
	ldr sb, lit_80332A0                  @ 080331A4  = chan_mod
	mla r8, r7, r8, sb                   @ 080331A8
	mov r1, #0                           @ 080331AC
	mov r2, #0                           @ 080331B0
	ldr sb, [r8]                         @ 080331B4
	cmp sb, #0                           @ 080331B8
	beq L_8033210                        @ 080331BC
	ldr r7, [r8, #4]                     @ 080331C0
	lsr r1, r7, #0x10                    @ 080331C4
	sub r7, r7, r1, lsl #16              @ 080331C8
	ldr r6, lit_80332A4                  @ 080331CC  = lfo_sine_table
	add r6, r6, r1, lsl #2               @ 080331D0
	ldm r6, {r1, r2}                     @ 080331D4
	sub r2, r2, r1                       @ 080331D8
	smull r6, r7, r2, r7                 @ 080331DC
	lsl r7, r7, #0x10                    @ 080331E0
	add r7, r7, r6, lsr #16              @ 080331E4
	add r1, r1, r7                       @ 080331E8
	add sb, sb, #1                       @ 080331EC
	mul sb, r1, sb                       @ 080331F0
	ldrsb r8, [r0, #6]                   @ 080331F4
	mov r7, #4                           @ 080331F8
	ldr r6, lit_80332A8                  @ 080331FC  = chan_instrument
	mla r2, r8, r7, r6                   @ 08033200
	ldr r2, [r2]                         @ 08033204
	ldr r2, [r2, #0x40]                  @ 08033208
	smull r1, r2, sb, r2                 @ 0803320C
L_8033210:
	push {r1, r2}                        @ 08033210
L_8033214:
	pop {r1, r2, r3, r7, r8, sb}         @ 08033214
	adds r1, r1, r3                      @ 08033218
	adc r2, r2, r7                       @ 0803321C
	adds r1, r1, r8                      @ 08033220
	adc r2, r2, sb                       @ 08033224
	ldr r3, [r4, #0xc]                   @ 08033228
	ldrb sb, [r0, #5]                    @ 0803322C
	sub r3, sb, r3                       @ 08033230
	add r3, r3, r2                       @ 08033234
	ldr r6, lit_80332AC                  @ 08033238  = 0x08033C00
	add r2, r6, r3, lsl #2               @ 0803323C
	ldm r2, {r3, r7}                     @ 08033240
	sub r2, r7, r3                       @ 08033244
	umull sb, sl, r1, r2                 @ 08033248
	add r7, r3, sl                       @ 0803324C
	ldr r1, lit_80332B0                  @ 08033250  = mix_pitch_scale
	ldr r1, [r1]                         @ 08033254
	ldr r2, [r4, #8]                     @ 08033258
	umull r8, sb, r1, r2                 @ 0803325C
	lsr r8, r8, #0xe                     @ 08033260
	add r8, r8, sb, lsl #18              @ 08033264
	umull sl, r4, r7, r8                 @ 08033268
	lsr sl, sl, #0x18                    @ 0803326C
	orr r7, sl, r4, lsl #8               @ 08033270
	bx lr                                @ 08033274
lit_8033278:
	.word sfx_master_volume
lit_803327C:
	.word music_master_volume
lit_8033280:
	.word chan_volume
lit_8033284:
	.word mix_samples_per_frame
lit_8033288:
	.word 0x007FFFFF
lit_803328C:
	.word mix_max_voices
lit_8033290:
	.word 0x028F5C29
lit_8033294:
	.word chan_instrument
lit_8033298:
	.word chan_bend
lit_803329C:
	.word chan_instrument
lit_80332A0:
	.word chan_mod
lit_80332A4:
	.word lfo_sine_table
lit_80332A8:
	.word chan_instrument
lit_80332AC:
	.word 0x08033C00
lit_80332B0:
	.word mix_pitch_scale
iwram_code_end:

	.thumb

@ ------------------------------------------------------------------
@ snd_request_song   ROM 0x080332B4 (Thumb)
@ API: r0 = song number. Latched; started at the next snd_frame.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_request_song
snd_request_song:
	push {r4, r5, r6, r7, lr}            @ 080332B4
	mov r3, r8                           @ 080332B6
	mov r4, sb                           @ 080332B8
	mov r5, sl                           @ 080332BA
	mov r6, fp                           @ 080332BC
	mov r7, ip                           @ 080332BE
	push {r3, r4, r5, r6, r7}            @ 080332C0
	ldr r1, lit_80334D8                  @ 080332C2  = seq_pending_song
	str r0, [r1]                         @ 080332C4
	pop {r3, r4, r5, r6, r7}             @ 080332C6
	mov r8, r3                           @ 080332C8
	mov sb, r4                           @ 080332CA
	mov sl, r5                           @ 080332CC
	mov fp, r6                           @ 080332CE
	mov ip, r7                           @ 080332D0
	pop {r4, r5, r6, r7}                 @ 080332D2
	pop {r1}                             @ 080332D4
	bx r1                                @ 080332D6

@ ------------------------------------------------------------------
@ snd_vblank   ROM 0x080332D8 (Thumb)
@ API (V-blank): flip the double buffer and restart DMA1 -> FIFO A on the buffer
@ that was just mixed. Leaf, no stack.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_vblank
snd_vblank:
	ldr r0, lit_80334DC                  @ 080332D8  = dma_buffer_flag
	ldr r2, [r0]                         @ 080332DA
	mvns r2, r2                          @ 080332DC
	str r2, [r0]                         @ 080332DE
	ldr r1, lit_80334E0                  @ 080332E0  = cfg_buffer_a
	cmp r2, #0                           @ 080332E2
	beq L_80332E8                        @ 080332E4
	ldr r1, lit_80334E4                  @ 080332E6  = cfg_buffer_b
L_80332E8:
	ldr r1, [r1]                         @ 080332E8
	ldr r0, lit_80334E8                  @ 080332EA  = REG_DMA1CNT_H
	movs r2, #0                          @ 080332EC
	strh r2, [r0]                        @ 080332EE
	ldr r2, lit_80334EC                  @ 080332F0  = REG_FIFO_A
	ldr r3, lit_80334F0                  @ 080332F2  = 0xF6000000
	ldr r0, lit_80334F4                  @ 080332F4  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 080332F6
	ldr r0, lit_80334F8                  @ 080332F8  = REG_SOUNDCNT_X
	movs r1, #0x80                       @ 080332FA
	strh r1, [r0]                        @ 080332FC
	bx lr                                @ 080332FE

@ ------------------------------------------------------------------
@ snd_init   ROM 0x08033300 (Thumb)
@ API: one-time init. DirectSound A only, mono, Timer 0, 13379 Hz, 8 mixed voices.
@ Copies the ARM block into IWRAM with DMA2.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_init
snd_init:
	push {r4, r5, r6, r7, lr}            @ 08033300
	mov r3, r8                           @ 08033302
	mov r4, sb                           @ 08033304
	mov r5, sl                           @ 08033306
	mov r6, fp                           @ 08033308
	mov r7, ip                           @ 0803330A
	push {r3, r4, r5, r6, r7}            @ 0803330C
	sub sp, #4                           @ 0803330E
	ldr r0, lit_80334F8                  @ 08033310  = REG_SOUNDCNT_X
	movs r1, #0                          @ 08033312
	strh r1, [r0]                        @ 08033314
	ldr r0, lit_80334E8                  @ 08033316  = REG_DMA1CNT_H
	movs r2, #0                          @ 08033318
	strh r2, [r0]                        @ 0803331A
	ldr r0, lit_80334FC                  @ 0803331C  = REG_TM0CNT_H
	movs r1, #0                          @ 0803331E
	strh r1, [r0]                        @ 08033320
	movs r0, #0                          @ 08033322
	str r0, [sp]                         @ 08033324
	mov r1, sp                           @ 08033326
	ldr r2, lit_8033500                  @ 08033328  = cfg_buffer_b
	ldr r2, [r2]                         @ 0803332A
	ldr r3, lit_8033504                  @ 0803332C  = 0x85000038
	ldr r0, lit_80334F4                  @ 0803332E  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 08033330
	movs r0, #0                          @ 08033332
	str r0, [sp]                         @ 08033334
	mov r1, sp                           @ 08033336
	ldr r2, lit_8033508                  @ 08033338  = cfg_buffer_a
	ldr r2, [r2]                         @ 0803333A
	ldr r3, lit_8033504                  @ 0803333C  = 0x85000038
	ldr r0, lit_80334F4                  @ 0803333E  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 08033340
	ldr r0, lit_803350C                  @ 08033342  = dma_buffer_flag
	movs r1, #0                          @ 08033344
	str r1, [r0]                         @ 08033346
	movs r1, #0                          @ 08033348
	mvns r1, r1                          @ 0803334A
	ldr r0, lit_8033510                  @ 0803334C  = seq_pending_song
	str r1, [r0]                         @ 0803334E
	ldr r0, lit_8033514                  @ 08033350  = seq_current_song
	str r1, [r0]                         @ 08033352
	ldr r0, lit_8033518                  @ 08033354  = REG_SOUNDCNT_H
	movs r1, #0                          @ 08033356
	strh r1, [r0]                        @ 08033358
	ldrh r1, [r0]                        @ 0803335A
	ldr r2, lit_803351C                  @ 0803335C  = 0x00008800 ; FIFO A+B reset
	orrs r1, r2                          @ 0803335E
	strh r1, [r0]                        @ 08033360
	ldr r0, lit_80334EC                  @ 08033362  = REG_FIFO_A
	movs r1, #0x80                       @ 08033364
	strb r1, [r0]                        @ 08033366
	movs r1, #0x80                       @ 08033368
	strb r1, [r0, #4]                    @ 0803336A
	ldr r0, lit_8033518                  @ 0803336C  = REG_SOUNDCNT_H
	ldr r1, [r0]                         @ 0803336E
	ldr r2, lit_8033520                  @ 08033370  = 0x0000030C ; DSA 100%, DSB 100%, DSA L+R, Timer 0
	orrs r1, r2                          @ 08033372
	strh r1, [r0]                        @ 08033374
	ldr r0, lit_8033524                  @ 08033376  = REG_SOUNDBIAS_H
	ldr r1, [r0]                         @ 08033378
	movs r2, #0xc0                       @ 0803337A
	bics r1, r2                          @ 0803337C
	movs r2, #0x40                       @ 0803337E
	orrs r1, r2                          @ 08033380
	strb r1, [r0]                        @ 08033382  SOUNDBIAS: 8-bit / 65.536 kHz PWM
	bl init_music_voices                 @ 08033384
	bl init_sfx_voices                   @ 08033388
	movs r0, #0x80                       @ 0803338C
	bl snd_set_music_volume              @ 0803338E
	movs r0, #0x80                       @ 08033392
	bl snd_set_sfx_volume                @ 08033394
	bl reset_channel_volume              @ 08033398
	bl reset_mono_flags                  @ 0803339C
	ldr r1, lit_8033528                  @ 080333A0  = voice_start
	ldr r2, lit_803352C                  @ 080333A2  = (voice_start - iwram_code_start + IWRAM_CODE_BASE)
	ldr r3, lit_8033530                  @ 080333A4  = iwram_code_size
	ldr r3, [r3]                         @ 080333A6
	ldr r4, lit_8033534                  @ 080333A8  = 0x000013EC
	cmp r3, r4                           @ 080333AA
	ble L_80333AE                        @ 080333AC  dead check (assert stripped): not enough space for audio RAM code
L_80333AE:
	lsrs r3, r3, #2                      @ 080333AE
	ldr r0, lit_8033538                  @ 080333B0  = 0x84000000
	orrs r3, r0                          @ 080333B2
	ldr r0, lit_80334F4                  @ 080333B4  = REG_DMA1SAD
	stm r0!, {r1, r2, r3}                @ 080333B6
	bl wait_vcount_160                   @ 080333B8
	ldr r0, lit_803353C                  @ 080333BC  = song_table_ptr
	ldr r1, lit_8033540                  @ 080333BE  = song_table
	str r1, [r0]                         @ 080333C0
	ldr r0, lit_8033544                  @ 080333C2  = sfx_table_ptr
	ldr r1, lit_8033548                  @ 080333C4  = sfx_table
	str r1, [r0]                         @ 080333C6
	ldr r0, lit_803354C                  @ 080333C8  = 0x00003443
	bl snd_set_mix_rate                  @ 080333CA  13379 Hz
	movs r0, #8                          @ 080333CE
	bl snd_set_max_voices                @ 080333D0  8 voices
	add sp, #4                           @ 080333D4
	pop {r3, r4, r5, r6, r7}             @ 080333D6
	mov r8, r3                           @ 080333D8
	mov sb, r4                           @ 080333DA
	mov sl, r5                           @ 080333DC
	mov fp, r6                           @ 080333DE
	mov ip, r7                           @ 080333E0
	pop {r4, r5, r6, r7}                 @ 080333E2
	pop {r1}                             @ 080333E4
	bx r1                                @ 080333E6

@ ------------------------------------------------------------------
@ snd_frame   ROM 0x080333E8 (Thumb)
@ API: per-frame update (start pending song, sequencer, LFO, envelopes, mixer).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_frame
snd_frame:
	push {r4, r5, r6, r7, lr}            @ 080333E8
	mov r3, r8                           @ 080333EA
	mov r4, sb                           @ 080333EC
	mov r5, sl                           @ 080333EE
	mov r6, fp                           @ 080333F0
	mov r7, ip                           @ 080333F2
	push {r3, r4, r5, r6, r7}            @ 080333F4
	ldr r0, lit_8033550                  @ 080333F6  = seq_pending_song
	ldr r1, [r0]                         @ 080333F8
	cmp r1, #0                           @ 080333FA
	bmi L_8033464                        @ 080333FC
	movs r2, #0                          @ 080333FE
	mvns r2, r2                          @ 08033400
	str r2, [r0]                         @ 08033402
	ldr r0, lit_8033554                  @ 08033404  = seq_current_song
	str r1, [r0]                         @ 08033406
	ldr r0, lit_8033558                  @ 08033408  = seq_track_time
	movs r2, #0x80                       @ 0803340A
	movs r3, #0                          @ 0803340C
L_803340E:
	subs r2, #4                          @ 0803340E
	str r3, [r0, r2]                     @ 08033410
	bne L_803340E                        @ 08033412
	ldr r0, lit_803355C                  @ 08033414  = song_table_ptr
	ldr r0, [r0]                         @ 08033416
	lsls r1, r1, #2                      @ 08033418
	ldr r0, [r0, r1]                     @ 0803341A
	ldr r3, [r0]                         @ 0803341C
	ldr r2, lit_8033560                  @ 0803341E  = seq_num_tracks
	str r3, [r2]                         @ 08033420
	ldr r1, [r0, #4]                     @ 08033422
	ldr r2, lit_8033564                  @ 08033424  = seq_division
	str r1, [r2]                         @ 08033426
	ldr r1, [r0, #8]                     @ 08033428
	ldr r2, lit_8033568                  @ 0803342A  = seq_track_ptr
	ldm r1!, {r3, r4, r5, r6, r7}        @ 0803342C
	stm r2!, {r3, r4, r5, r6, r7}        @ 0803342E
	ldm r1!, {r3, r4, r5, r6, r7}        @ 08033430
	stm r2!, {r3, r4, r5, r6, r7}        @ 08033432
	ldm r1, {r1, r3, r4, r5, r6, r7}     @ 08033434
	stm r2!, {r1, r3, r4, r5, r6, r7}    @ 08033436
	ldr r1, [r0, #0xc]                   @ 08033438
	ldr r2, lit_803356C                  @ 0803343A  = seq_prog_map_ptr
	str r1, [r2]                         @ 0803343C
	ldr r1, [r0, #0x10]                  @ 0803343E
	ldr r2, lit_8033570                  @ 08033440  = seq_inst_table_ptr
	str r1, [r2]                         @ 08033442
	ldr r0, lit_8033574                  @ 08033444  = seq_track_time
	movs r1, #0                          @ 08033446
	adds r2, r1, #0                      @ 08033448
	stm r0!, {r1, r2}                    @ 0803344A
	ldr r0, lit_8033578                  @ 0803344C  = seq_frame_time
	movs r1, #1                          @ 0803344E
	str r1, [r0]                         @ 08033450
	ldr r0, lit_803357C                  @ 08033452  = seq_tempo
	movs r1, #0                          @ 08033454
	str r1, [r0]                         @ 08033456
	bl init_music_voices                 @ 08033458
	bl reset_pitch_bend                  @ 0803345C
	bl reset_modulation                  @ 08033460
L_8033464:
	bl clear_mix_buffer                  @ 08033464
	ldr r0, lit_8033580                  @ 08033468  = music_paused
	ldr r1, [r0]                         @ 0803346A
	cmp r1, #1                           @ 0803346C
	beq L_8033490                        @ 0803346E
	ldr r0, lit_8033584                  @ 08033470  = seq_current_song
	ldr r1, [r0]                         @ 08033472
	cmp r1, #0                           @ 08033474
	bmi L_8033490                        @ 08033476
	mov r0, pc                           @ 08033478
	adds r0, #7                          @ 0803347A
	mov lr, r0                           @ 0803347C
	ldr r0, lit_8033588                  @ 0803347E  = (seq_update - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08033480
L_8033482:
	bl lfo_update                        @ 08033482
	mov r0, pc                           @ 08033486
	adds r0, #7                          @ 08033488
	mov lr, r0                           @ 0803348A
	ldr r0, lit_803358C                  @ 0803348C  = (env_update_music - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 0803348E
L_8033490:
	bl sfx_timer_update                  @ 08033490
	mov r0, pc                           @ 08033494
	adds r0, #7                          @ 08033496
	mov lr, r0                           @ 08033498
	ldr r0, lit_8033590                  @ 0803349A  = (env_update_sfx - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 0803349C
L_803349E:
	mov r0, pc                           @ 0803349E
	adds r0, #7                          @ 080334A0
	mov lr, r0                           @ 080334A2
	ldr r0, lit_8033594                  @ 080334A4  = (mix_frame - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080334A6
L_80334A8:
	ldr r0, lit_8033598                  @ 080334A8  = music_paused
	ldr r1, [r0]                         @ 080334AA
	cmp r1, #1                           @ 080334AC
	beq L_80334BA                        @ 080334AE
	mov r0, pc                           @ 080334B0
	adds r0, #7                          @ 080334B2
	mov lr, r0                           @ 080334B4
	ldr r0, lit_803359C                  @ 080334B6  = (advance_music_voices - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080334B8
L_80334BA:
	mov r0, pc                           @ 080334BA
	adds r0, #7                          @ 080334BC
	mov lr, r0                           @ 080334BE
	ldr r0, lit_80335A0                  @ 080334C0  = (advance_sfx_voices - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080334C2
L_80334C4:
	pop {r3, r4, r5, r6, r7}             @ 080334C4
	mov r8, r3                           @ 080334C6
	mov sb, r4                           @ 080334C8
	mov sl, r5                           @ 080334CA
	mov fp, r6                           @ 080334CC
	mov ip, r7                           @ 080334CE
	pop {r4, r5, r6, r7}                 @ 080334D0
	pop {r1}                             @ 080334D2
	bx r1                                @ 080334D4
	.hword 0x0000
lit_80334D8:
	.word seq_pending_song
lit_80334DC:
	.word dma_buffer_flag
lit_80334E0:
	.word cfg_buffer_a
lit_80334E4:
	.word cfg_buffer_b
lit_80334E8:
	.word REG_DMA1CNT_H
lit_80334EC:
	.word REG_FIFO_A
lit_80334F0:
	.word 0xF6000000
lit_80334F4:
	.word REG_DMA1SAD
lit_80334F8:
	.word REG_SOUNDCNT_X
lit_80334FC:
	.word REG_TM0CNT_H
lit_8033500:
	.word cfg_buffer_b
lit_8033504:
	.word 0x85000038
lit_8033508:
	.word cfg_buffer_a
lit_803350C:
	.word dma_buffer_flag
lit_8033510:
	.word seq_pending_song
lit_8033514:
	.word seq_current_song
lit_8033518:
	.word REG_SOUNDCNT_H
lit_803351C:
	.word 0x00008800
lit_8033520:
	.word 0x0000030C
lit_8033524:
	.word REG_SOUNDBIAS_H
lit_8033528:
	.word voice_start
lit_803352C:
	.word (voice_start - iwram_code_start + IWRAM_CODE_BASE)
lit_8033530:
	.word iwram_code_size
lit_8033534:
	.word 0x000013EC
lit_8033538:
	.word 0x84000000
lit_803353C:
	.word song_table_ptr
lit_8033540:
	.word song_table
lit_8033544:
	.word sfx_table_ptr
lit_8033548:
	.word sfx_table
lit_803354C:
	.word 0x00003443
lit_8033550:
	.word seq_pending_song
lit_8033554:
	.word seq_current_song
lit_8033558:
	.word seq_track_time
lit_803355C:
	.word song_table_ptr
lit_8033560:
	.word seq_num_tracks
lit_8033564:
	.word seq_division
lit_8033568:
	.word seq_track_ptr
lit_803356C:
	.word seq_prog_map_ptr
lit_8033570:
	.word seq_inst_table_ptr
lit_8033574:
	.word seq_track_time
lit_8033578:
	.word seq_frame_time
lit_803357C:
	.word seq_tempo
lit_8033580:
	.word music_paused
lit_8033584:
	.word seq_current_song
lit_8033588:
	.word (seq_update - iwram_code_start + IWRAM_CODE_BASE)
lit_803358C:
	.word (env_update_music - iwram_code_start + IWRAM_CODE_BASE)
lit_8033590:
	.word (env_update_sfx - iwram_code_start + IWRAM_CODE_BASE)
lit_8033594:
	.word (mix_frame - iwram_code_start + IWRAM_CODE_BASE)
lit_8033598:
	.word music_paused
lit_803359C:
	.word (advance_music_voices - iwram_code_start + IWRAM_CODE_BASE)
lit_80335A0:
	.word (advance_sfx_voices - iwram_code_start + IWRAM_CODE_BASE)

@ ------------------------------------------------------------------
@ lfo_update   ROM 0x080335A4 (Thumb)
@ Advance the LFO phase of every channel whose mod wheel is non-zero.
@ ------------------------------------------------------------------
	.thumb_func
lfo_update:
	ldr r0, lit_8033828                  @ 080335A4  = chan_mod-8
	ldr r7, lit_803382C                  @ 080335A6  = chan_mod-4
	movs r1, #0x80                       @ 080335A8
	movs r6, #0                          @ 080335AA
L_80335AC:
	ldr r2, [r0, r1]                     @ 080335AC
	cmp r2, #0                           @ 080335AE
	bne L_80335BA                        @ 080335B0
	str r6, [r7, r1]                     @ 080335B2
L_80335B4:
	subs r1, #8                          @ 080335B4
	bne L_80335AC                        @ 080335B6
	bx lr                                @ 080335B8
L_80335BA:
	lsrs r3, r1, #3                      @ 080335BA
	subs r3, #1                          @ 080335BC
	ldr r4, lit_8033830                  @ 080335BE  = chan_instrument
	movs r5, #4                          @ 080335C0
	muls r5, r3, r5                      @ 080335C2
	ldr r3, [r4, r5]                     @ 080335C4
	ldr r3, [r3, #0x3c]                  @ 080335C6
	adds r4, r0, r1                      @ 080335C8
	ldr r5, [r4, #4]                     @ 080335CA
	adds r3, r5, r3                      @ 080335CC
	ldr r5, lit_8033834                  @ 080335CE  = 0x00FFFFFF
	ands r3, r5                          @ 080335D0
	str r3, [r4, #4]                     @ 080335D2
	b L_80335B4                          @ 080335D4

@ ------------------------------------------------------------------
@ sfx_timer_update   ROM 0x080335D6 (Thumb)
@ Count down SFX auto-release timers; at zero the voice is keyed off.
@ ------------------------------------------------------------------
	.thumb_func
sfx_timer_update:
	ldr r5, lit_8033838                  @ 080335D6  = sfx_voices
	movs r3, #0                          @ 080335D8
	ldr r6, lit_803383C                  @ 080335DA  = cfg_sfx_pool_bytes
	ldr r6, [r6]                         @ 080335DC
	ldr r0, lit_8033840                  @ 080335DE  = sfx_timer
L_80335E0:
	ldrb r4, [r5, r3]                    @ 080335E0
	cmp r4, #0x11                        @ 080335E2
	beq L_80335F0                        @ 080335E4
L_80335E6:
	adds r0, #4                          @ 080335E6
	adds r3, #0x28                       @ 080335E8
	cmp r3, r6                           @ 080335EA
	blt L_80335E0                        @ 080335EC
	bx lr                                @ 080335EE
L_80335F0:
	ldr r1, [r0]                         @ 080335F0
	subs r1, #1                          @ 080335F2
	bmi L_80335FE                        @ 080335F4
	str r1, [r0]                         @ 080335F6
	bne L_80335FE                        @ 080335F8
	movs r1, #0x12                       @ 080335FA
	strb r1, [r5, r3]                    @ 080335FC
L_80335FE:
	b L_80335E6                          @ 080335FE

@ ------------------------------------------------------------------
@ sfx_start_voice   ROM 0x08033600 (Thumb)
@ Allocate an SFX voice (free, else released). In: r0 = sfx id, r1 = volume,
@ r2 = pitch mult (16.16). Out: r0 = handle (-1 if none), r1 = voice index.
@ ------------------------------------------------------------------
	.thumb_func
sfx_start_voice:
	push {lr}                            @ 08033600
	ldr r5, lit_8033844                  @ 08033602  = sfx_voices
	movs r3, #0                          @ 08033604
	ldr r6, lit_8033848                  @ 08033606  = cfg_sfx_pool_bytes
	ldr r6, [r6]                         @ 08033608
L_803360A:
	ldrb r4, [r5, r3]                    @ 0803360A
	cmp r4, #0x10                        @ 0803360C
	beq L_803362C                        @ 0803360E
	adds r3, #0x28                       @ 08033610
	cmp r3, r6                           @ 08033612
	blt L_803360A                        @ 08033614
	movs r3, #0                          @ 08033616
L_8033618:
	ldrb r4, [r5, r3]                    @ 08033618
	cmp r4, #0x12                        @ 0803361A
	beq L_803362C                        @ 0803361C
	adds r3, #0x28                       @ 0803361E
	cmp r3, r6                           @ 08033620
	blt L_8033618                        @ 08033622
	movs r1, #0                          @ 08033624
	mvns r1, r1                          @ 08033626
	adds r0, r1, #0                      @ 08033628
	b L_803367A                          @ 0803362A
L_803362C:
	adds r5, r5, r3                      @ 0803362C
	movs r4, #0                          @ 0803362E
	mvns r4, r4                          @ 08033630
	adds r3, #0x28                       @ 08033632
L_8033634:
	adds r4, #1                          @ 08033634
	subs r3, #0x28                       @ 08033636
	bne L_8033634                        @ 08033638
	push {r4}                            @ 0803363A
	ldr r3, lit_803384C                  @ 0803363C  = sfx_handle_counter
	ldr r7, [r3]                         @ 0803363E
	adds r7, #1                          @ 08033640
	movs r6, #1                          @ 08033642
	cmn r7, r6                           @ 08033644
	bne L_803364A                        @ 08033646
	adds r7, #1                          @ 08033648
L_803364A:
	str r7, [r3]                         @ 0803364A
	ldr r3, lit_8033850                  @ 0803364C  = sfx_handle
	lsls r4, r4, #2                      @ 0803364E
	str r7, [r3, r4]                     @ 08033650
	push {r7}                            @ 08033652
	lsls r0, r0, #2                      @ 08033654
	ldr r4, lit_8033854                  @ 08033656  = sfx_table_ptr
	ldr r4, [r4]                         @ 08033658
	ldr r3, [r4, r0]                     @ 0803365A
	ldr r0, [r3, #0xc]                   @ 0803365C
	mov sb, r0                           @ 0803365E
	adds r4, r0, #0                      @ 08033660
	ldr r7, [r3, #4]                     @ 08033662
	mov r8, r1                           @ 08033664
	adds r1, r2, #0                      @ 08033666
	adds r2, r3, #0                      @ 08033668
	mov r3, r8                           @ 0803366A
	mov r0, pc                           @ 0803366C
	adds r0, #7                          @ 0803366E
	mov lr, r0                           @ 08033670
	ldr r0, lit_8033858                  @ 08033672  = (voice_start - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 08033674
L_8033676:
	pop {r0}                             @ 08033676
	pop {r1}                             @ 08033678
L_803367A:
	pop {r2}                             @ 0803367A
	bx r2                                @ 0803367C

@ ------------------------------------------------------------------
@ snd_sfx_is_playing   ROM 0x0803367E (Thumb)
@ API: r0 = handle -> r0 = 1 if a voice still carries that handle.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_is_playing
snd_sfx_is_playing:
	push {r4, r5, r6, r7, lr}            @ 0803367E
	mov r3, r8                           @ 08033680
	mov r4, sb                           @ 08033682
	mov r5, sl                           @ 08033684
	mov r6, fp                           @ 08033686
	mov r7, ip                           @ 08033688
	push {r3, r4, r5, r6, r7}            @ 0803368A
	bl sfx_find_handle                   @ 0803368C
	pop {r3, r4, r5, r6, r7}             @ 08033690
	mov r8, r3                           @ 08033692
	mov sb, r4                           @ 08033694
	mov sl, r5                           @ 08033696
	mov fp, r6                           @ 08033698
	mov ip, r7                           @ 0803369A
	pop {r4, r5, r6, r7}                 @ 0803369C
	pop {r1}                             @ 0803369E
	bx r1                                @ 080336A0

@ ------------------------------------------------------------------
@ sfx_find_handle   ROM 0x080336A2 (Thumb)
@ Out: r0 = 1 and r3 = byte offset of the voice holding handle r0, else r0 = 0.
@ ------------------------------------------------------------------
	.thumb_func
sfx_find_handle:
	movs r6, #0                          @ 080336A2
	ldr r2, lit_803385C                  @ 080336A4  = sfx_voices
	movs r3, #0                          @ 080336A6
	ldr r5, lit_8033860                  @ 080336A8  = cfg_sfx_pool_bytes
	ldr r5, [r5]                         @ 080336AA
L_80336AC:
	ldrb r4, [r2, r3]                    @ 080336AC
	cmp r4, #0x10                        @ 080336AE
	bne L_80336BE                        @ 080336B0
L_80336B2:
	adds r3, #0x28                       @ 080336B2
	adds r6, #4                          @ 080336B4
	cmp r3, r5                           @ 080336B6
	blt L_80336AC                        @ 080336B8
	movs r0, #0                          @ 080336BA
	mov pc, lr                           @ 080336BC
L_80336BE:
	ldr r4, lit_8033864                  @ 080336BE  = sfx_handle
	ldr r4, [r4, r6]                     @ 080336C0
	cmp r0, r4                           @ 080336C2
	bne L_80336B2                        @ 080336C4
	movs r0, #1                          @ 080336C6
	mov pc, lr                           @ 080336C8

@ ------------------------------------------------------------------
@ snd_sfx_set_pitch   ROM 0x080336CA (Thumb)
@ API: r0 = handle, r1 = pitch multiplier (16.16).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_set_pitch
snd_sfx_set_pitch:
	push {r4, r5, r6, r7, lr}            @ 080336CA
	mov r3, r8                           @ 080336CC
	mov r4, sb                           @ 080336CE
	mov r5, sl                           @ 080336D0
	mov r6, fp                           @ 080336D2
	mov r7, ip                           @ 080336D4
	push {r3, r4, r5, r6, r7}            @ 080336D6
	bl sfx_find_handle                   @ 080336D8
	cmp r0, #0                           @ 080336DC
	beq L_80336E4                        @ 080336DE
	ldr r2, lit_8033868                  @ 080336E0  = sfx_voices+0x24
	str r1, [r2, r3]                     @ 080336E2
L_80336E4:
	pop {r3, r4, r5, r6, r7}             @ 080336E4
	mov r8, r3                           @ 080336E6
	mov sb, r4                           @ 080336E8
	mov sl, r5                           @ 080336EA
	mov fp, r6                           @ 080336EC
	mov ip, r7                           @ 080336EE
	pop {r4, r5, r6, r7}                 @ 080336F0
	pop {r1}                             @ 080336F2
	bx r1                                @ 080336F4

@ ------------------------------------------------------------------
@ snd_sfx_set_volume   ROM 0x080336F6 (Thumb)
@ API: r0 = handle, r1 = volume (0-128).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_set_volume
snd_sfx_set_volume:
	push {r4, r5, r6, r7, lr}            @ 080336F6
	mov r3, r8                           @ 080336F8
	mov r4, sb                           @ 080336FA
	mov r5, sl                           @ 080336FC
	mov r6, fp                           @ 080336FE
	mov r7, ip                           @ 08033700
	push {r3, r4, r5, r6, r7}            @ 08033702
	bl sfx_find_handle                   @ 08033704
	cmp r0, #0                           @ 08033708
	beq L_8033710                        @ 0803370A
	ldr r2, lit_803386C                  @ 0803370C  = sfx_voices+0x3
	strb r1, [r2, r3]                    @ 0803370E
L_8033710:
	pop {r3, r4, r5, r6, r7}             @ 08033710
	mov r8, r3                           @ 08033712
	mov sb, r4                           @ 08033714
	mov sl, r5                           @ 08033716
	mov fp, r6                           @ 08033718
	mov ip, r7                           @ 0803371A
	pop {r4, r5, r6, r7}                 @ 0803371C
	pop {r1}                             @ 0803371E
	bx r1                                @ 08033720

@ ------------------------------------------------------------------
@ snd_sfx_stop   ROM 0x08033722 (Thumb)
@ API: r0 = handle. Frees the voice immediately (no release).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_stop
snd_sfx_stop:
	push {r4, r5, r6, r7, lr}            @ 08033722
	mov r3, r8                           @ 08033724
	mov r4, sb                           @ 08033726
	mov r5, sl                           @ 08033728
	mov r6, fp                           @ 0803372A
	mov r7, ip                           @ 0803372C
	push {r3, r4, r5, r6, r7}            @ 0803372E
	bl sfx_find_handle                   @ 08033730
	cmp r0, #0                           @ 08033734
	beq L_803373E                        @ 08033736
	ldr r2, lit_8033870                  @ 08033738  = sfx_voices
	movs r1, #0x10                       @ 0803373A
	strb r1, [r2, r3]                    @ 0803373C
L_803373E:
	pop {r3, r4, r5, r6, r7}             @ 0803373E
	mov r8, r3                           @ 08033740
	mov sb, r4                           @ 08033742
	mov sl, r5                           @ 08033744
	mov fp, r6                           @ 08033746
	mov ip, r7                           @ 08033748
	pop {r4, r5, r6, r7}                 @ 0803374A
	pop {r1}                             @ 0803374C
	bx r1                                @ 0803374E

@ ------------------------------------------------------------------
@ snd_sfx_stop_all   ROM 0x08033750 (Thumb)
@ API: free every SFX voice.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_stop_all
snd_sfx_stop_all:
	push {r4, r5, r6, r7, lr}            @ 08033750
	mov r3, r8                           @ 08033752
	mov r4, sb                           @ 08033754
	mov r5, sl                           @ 08033756
	mov r6, fp                           @ 08033758
	mov r7, ip                           @ 0803375A
	push {r3, r4, r5, r6, r7}            @ 0803375C
	bl init_sfx_voices                   @ 0803375E
	pop {r3, r4, r5, r6, r7}             @ 08033762
	mov r8, r3                           @ 08033764
	mov sb, r4                           @ 08033766
	mov sl, r5                           @ 08033768
	mov fp, r6                           @ 0803376A
	mov ip, r7                           @ 0803376C
	pop {r4, r5, r6, r7}                 @ 0803376E
	pop {r1}                             @ 08033770
	bx r1                                @ 08033772

@ ------------------------------------------------------------------
@ snd_music_stop   ROM 0x08033774 (Thumb)
@ API: free every music voice, no song playing.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_stop
snd_music_stop:
	push {r4, r5, r6, r7, lr}            @ 08033774
	mov r3, r8                           @ 08033776
	mov r4, sb                           @ 08033778
	mov r5, sl                           @ 0803377A
	mov r6, fp                           @ 0803377C
	mov r7, ip                           @ 0803377E
	push {r3, r4, r5, r6, r7}            @ 08033780
	bl init_music_voices                 @ 08033782
	ldr r0, lit_8033874                  @ 08033786  = seq_current_song
	movs r1, #0                          @ 08033788
	mvns r1, r1                          @ 0803378A
	str r1, [r0]                         @ 0803378C
	pop {r3, r4, r5, r6, r7}             @ 0803378E
	mov r8, r3                           @ 08033790
	mov sb, r4                           @ 08033792
	mov sl, r5                           @ 08033794
	mov fp, r6                           @ 08033796
	mov ip, r7                           @ 08033798
	pop {r4, r5, r6, r7}                 @ 0803379A
	pop {r1}                             @ 0803379C
	bx r1                                @ 0803379E

@ ------------------------------------------------------------------
@ snd_set_music_volume   ROM 0x080337A0 (Thumb)
@ API: r0 = music master volume (init 0x80).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_music_volume
snd_set_music_volume:
	ldr r1, lit_8033878                  @ 080337A0  = music_master_volume
	str r0, [r1]                         @ 080337A2
	bx lr                                @ 080337A4

@ ------------------------------------------------------------------
@ snd_set_sfx_volume   ROM 0x080337A6 (Thumb)
@ API: r0 = SFX master volume (init 0x80).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_sfx_volume
snd_set_sfx_volume:
	ldr r1, lit_803387C                  @ 080337A6  = sfx_master_volume
	str r0, [r1]                         @ 080337A8
	bx lr                                @ 080337AA

@ ------------------------------------------------------------------
@ snd_get_tempo   ROM 0x080337AC (Thumb)
@ API: r0 = current tempo (us per quarter note).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_get_tempo
snd_get_tempo:
	ldr r1, lit_8033880                  @ 080337AC  = seq_tempo
	ldr r0, [r1]                         @ 080337AE
	bx lr                                @ 080337B0

@ ------------------------------------------------------------------
@ snd_set_tempo   ROM 0x080337B2 (Thumb)
@ API: r0 = tempo (us per quarter note).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_tempo
snd_set_tempo:
	push {r4, r5, r6, r7, lr}            @ 080337B2
	mov r3, r8                           @ 080337B4
	mov r4, sb                           @ 080337B6
	mov r5, sl                           @ 080337B8
	mov r6, fp                           @ 080337BA
	mov r7, ip                           @ 080337BC
	push {r3, r4, r5, r6, r7}            @ 080337BE
	adds r1, r0, #0                      @ 080337C0
	mov r0, pc                           @ 080337C2
	adds r0, #7                          @ 080337C4
	mov lr, r0                           @ 080337C6
	ldr r0, lit_8033884                  @ 080337C8  = (set_tempo_internal - iwram_code_start + IWRAM_CODE_BASE)
	bx r0                                @ 080337CA
L_80337CC:
	pop {r3, r4, r5, r6, r7}             @ 080337CC
	mov r8, r3                           @ 080337CE
	mov sb, r4                           @ 080337D0
	mov sl, r5                           @ 080337D2
	mov fp, r6                           @ 080337D4
	mov ip, r7                           @ 080337D6
	pop {r4, r5, r6, r7}                 @ 080337D8
	pop {r1}                             @ 080337DA
	bx r1                                @ 080337DC

@ ------------------------------------------------------------------
@ snd_music_pause   ROM 0x080337DE (Thumb)
@ API: freeze the sequencer and music voices.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_pause
snd_music_pause:
	movs r1, #1                          @ 080337DE
	ldr r0, lit_8033888                  @ 080337E0  = music_paused
	str r1, [r0]                         @ 080337E2
	bx lr                                @ 080337E4

@ ------------------------------------------------------------------
@ snd_music_resume   ROM 0x080337E6 (Thumb)
@ API: undo snd_music_pause.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_music_resume
snd_music_resume:
	movs r1, #0                          @ 080337E6
	ldr r0, lit_803388C                  @ 080337E8  = music_paused
	str r1, [r0]                         @ 080337EA
	bx lr                                @ 080337EC

@ ------------------------------------------------------------------
@ snd_sfx_release   ROM 0x080337EE (Thumb)
@ API: r0 = handle. Key off (enters release).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_release
snd_sfx_release:
	push {r4, r5, r6, r7, lr}            @ 080337EE
	mov r3, r8                           @ 080337F0
	mov r4, sb                           @ 080337F2
	mov r5, sl                           @ 080337F4
	mov r6, fp                           @ 080337F6
	mov r7, ip                           @ 080337F8
	push {r3, r4, r5, r6, r7}            @ 080337FA
	bl sfx_find_handle                   @ 080337FC
	cmp r0, #0                           @ 08033800
	beq L_8033810                        @ 08033802
	ldr r2, lit_8033890                  @ 08033804  = sfx_voices
	ldrb r1, [r2, r3]                    @ 08033806
	cmp r1, #0x11                        @ 08033808
	bne L_8033810                        @ 0803380A
	movs r1, #0x12                       @ 0803380C
	strb r1, [r2, r3]                    @ 0803380E
L_8033810:
	pop {r3, r4, r5, r6, r7}             @ 08033810
	mov r8, r3                           @ 08033812
	mov sb, r4                           @ 08033814
	mov sl, r5                           @ 08033816
	mov fp, r6                           @ 08033818
	mov ip, r7                           @ 0803381A
	pop {r4, r5, r6, r7}                 @ 0803381C
	pop {r1}                             @ 0803381E
	bx r1                                @ 08033820

@ ------------------------------------------------------------------
@ snd_sfx_play   ROM 0x08033822 (Thumb)
@ API: r0 = sfx id, r1 = volume (0 = do nothing), r2 = pitch mult (0x10000 = normal).
@ Returns handle (-1 if none).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_play
snd_sfx_play:
	movs r3, #0                          @ 08033822
	b sfx_play_common                    @ 08033824

@ ------------------------------------------------------------------
@ snd_sfx_play_timed   ROM 0x08033826 (Thumb)
@ API: as snd_sfx_play, plus r3 = frames until automatic key-off (0 = never).
@ No callers in DKC1.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_sfx_play_timed
snd_sfx_play_timed:
	b sfx_play_common                    @ 08033826
lit_8033828:
	.word chan_mod-8
lit_803382C:
	.word chan_mod-4
lit_8033830:
	.word chan_instrument
lit_8033834:
	.word 0x00FFFFFF
lit_8033838:
	.word sfx_voices
lit_803383C:
	.word cfg_sfx_pool_bytes
lit_8033840:
	.word sfx_timer
lit_8033844:
	.word sfx_voices
lit_8033848:
	.word cfg_sfx_pool_bytes
lit_803384C:
	.word sfx_handle_counter
lit_8033850:
	.word sfx_handle
lit_8033854:
	.word sfx_table_ptr
lit_8033858:
	.word (voice_start - iwram_code_start + IWRAM_CODE_BASE)
lit_803385C:
	.word sfx_voices
lit_8033860:
	.word cfg_sfx_pool_bytes
lit_8033864:
	.word sfx_handle
lit_8033868:
	.word sfx_voices+0x24
lit_803386C:
	.word sfx_voices+0x3
lit_8033870:
	.word sfx_voices
lit_8033874:
	.word seq_current_song
lit_8033878:
	.word music_master_volume
lit_803387C:
	.word sfx_master_volume
lit_8033880:
	.word seq_tempo
lit_8033884:
	.word (set_tempo_internal - iwram_code_start + IWRAM_CODE_BASE)
lit_8033888:
	.word music_paused
lit_803388C:
	.word music_paused
lit_8033890:
	.word sfx_voices

@ ------------------------------------------------------------------
@ sfx_play_common   ROM 0x08033894 (Thumb)
@ Shared body of snd_sfx_play / snd_sfx_play_timed: volume 0 -> return -1; else start
@ the voice and store r3 into sfx_timer[voice].
@ ------------------------------------------------------------------
	.thumb_func
sfx_play_common:
	cmp r1, #0                           @ 08033894
	bne L_80338A0                        @ 08033896
	movs r1, #0                          @ 08033898
	mvns r1, r1                          @ 0803389A
	adds r0, r1, #0                      @ 0803389C
	bx lr                                @ 0803389E
L_80338A0:
	push {r4, r5, r6, r7, lr}            @ 080338A0
	mov lr, r3                           @ 080338A2
	mov r3, r8                           @ 080338A4
	mov r4, sb                           @ 080338A6
	mov r5, sl                           @ 080338A8
	mov r6, fp                           @ 080338AA
	mov r7, ip                           @ 080338AC
	push {r3, r4, r5, r6, r7}            @ 080338AE
	push {lr}                            @ 080338B0
	bl sfx_start_voice                   @ 080338B2
	pop {r3}                             @ 080338B6
	cmp r1, #0                           @ 080338B8
	bmi L_80338C2                        @ 080338BA
	ldr r5, lit_8033A64                  @ 080338BC  = sfx_timer
	lsls r6, r1, #2                      @ 080338BE
	str r3, [r5, r6]                     @ 080338C0
L_80338C2:
	pop {r3, r4, r5, r6, r7}             @ 080338C2
	mov r8, r3                           @ 080338C4
	mov sb, r4                           @ 080338C6
	mov sl, r5                           @ 080338C8
	mov fp, r6                           @ 080338CA
	mov ip, r7                           @ 080338CC
	pop {r4, r5, r6, r7}                 @ 080338CE
	pop {r1}                             @ 080338D0
	bx r1                                @ 080338D2

@ ------------------------------------------------------------------
@ snd_shutdown   ROM 0x080338D4 (Thumb)
@ API: stop DMA1 and switch the APU off.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_shutdown
snd_shutdown:
	ldr r0, lit_8033A68                  @ 080338D4  = REG_DMA1CNT_H
	movs r2, #0                          @ 080338D6
	strh r2, [r0]                        @ 080338D8
	ldr r0, lit_8033A6C                  @ 080338DA  = REG_SOUNDCNT_X
	movs r1, #0                          @ 080338DC
	strh r1, [r0]                        @ 080338DE
	bx lr                                @ 080338E0

@ ------------------------------------------------------------------
@ snd_set_mix_rate   ROM 0x080338E2 (Thumb)
@ API: r0 = Hz. Above 13379 -> r0 = -1. 10512 / 13379 set Timer 0, samples per frame and the
@ pitch scale and return 0. BUG: any other value <= 13379 falls through to the 21024 Hz
@ settings (352 samples/frame), overrunning the 224-sample mix_buffer.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_mix_rate
snd_set_mix_rate:
	push {r4, r5, r6, r7, lr}            @ 080338E2
	mov r3, r8                           @ 080338E4
	mov r4, sb                           @ 080338E6
	mov r5, sl                           @ 080338E8
	mov r6, fp                           @ 080338EA
	mov r7, ip                           @ 080338EC
	push {r3, r4, r5, r6, r7}            @ 080338EE
	ldr r1, lit_8033A70                  @ 080338F0  = 0x00003443
	cmp r0, r1                           @ 080338F2
	ble L_80338FC                        @ 080338F4
	movs r0, #0                          @ 080338F6
	mvns r0, r0                          @ 080338F8
	b L_803394A                          @ 080338FA
L_80338FC:
	ldr r1, lit_8033A74                  @ 080338FC  = mix_rate_hz
	str r0, [r1]                         @ 080338FE
	ldr r1, lit_8033A78                  @ 08033900  = 0x00002910
	ldr r2, lit_8033A7C                  @ 08033902  = 0xFFFFF9C4
	ldr r3, lit_8033A80                  @ 08033904  = 0x018F0064
	movs r4, #0xb0                       @ 08033906
	cmp r0, r1                           @ 08033908
	beq L_8033930                        @ 0803390A
	ldr r1, lit_8033A70                  @ 0803390C  = 0x00003443
	ldr r2, lit_8033A84                  @ 0803390E  = 0xFFFFFB1A
	ldr r3, lit_8033A88                  @ 08033910  = 0x01397FC3
	movs r4, #0xe0                       @ 08033912
	cmp r0, r1                           @ 08033914
	beq L_8033930                        @ 08033916
	ldr r1, lit_8033A8C                  @ 08033918  = 0x000046ED
	ldr r2, lit_8033A90                  @ 0803391A  = 0xFFFFFC64
	ldr r3, lit_8033A94                  @ 0803391C  = 0x00E70086
	ldr r4, lit_8033A98                  @ 0803391E  = 0x00000130
	cmp r0, r1                           @ 08033920
	beq L_8033930                        @ 08033922
	ldr r1, lit_8033A9C                  @ 08033924  = 0x00005220
	ldr r2, lit_8033AA0                  @ 08033926  = 0xFFFFFCE2
	ldr r3, lit_8033AA4                  @ 08033928  = 0x00C78032
	ldr r4, lit_8033AA8                  @ 0803392A  = 0x00000160
	cmp r0, r1                           @ 0803392C
	beq L_8033930                        @ 0803392E
L_8033930:
	ldr r7, lit_8033AAC                  @ 08033930  = mix_timer_reload
	str r2, [r7]                         @ 08033932
	ldr r7, lit_8033AB0                  @ 08033934  = mix_pitch_scale
	str r3, [r7]                         @ 08033936
	ldr r7, lit_8033AB4                  @ 08033938  = mix_samples_per_frame
	str r4, [r7]                         @ 0803393A
	ldr r0, lit_8033AB8                  @ 0803393C  = REG_TM0CNT_L
	ldr r1, lit_8033ABC                  @ 0803393E  = mix_timer_reload
	ldr r1, [r1]                         @ 08033940
	strh r1, [r0]                        @ 08033942
	movs r1, #0x80                       @ 08033944
	strh r1, [r0, #2]                    @ 08033946
	movs r0, #0                          @ 08033948
L_803394A:
	pop {r3, r4, r5, r6, r7}             @ 0803394A
	mov r8, r3                           @ 0803394C
	mov sb, r4                           @ 0803394E
	mov sl, r5                           @ 08033950
	mov fp, r6                           @ 08033952
	mov ip, r7                           @ 08033954
	pop {r4, r5, r6, r7}                 @ 08033956
	pop {r1}                             @ 08033958
	bx r1                                @ 0803395A

@ ------------------------------------------------------------------
@ snd_get_song   ROM 0x0803395C (Thumb)
@ API: r0 = current song, -1 = none / finished.
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_get_song
snd_get_song:
	ldr r0, lit_8033AC0                  @ 0803395C  = seq_current_song
	ldr r0, [r0]                         @ 0803395E
	bx lr                                @ 08033960

@ ------------------------------------------------------------------
@ snd_set_max_voices   ROM 0x08033962 (Thumb)
@ API: r0 = number of voices mixed per frame (init 8).
@ ------------------------------------------------------------------
	.thumb_func
	.global snd_set_max_voices
snd_set_max_voices:
	ldr r1, lit_8033AC4                  @ 08033962  = mix_max_voices
	str r0, [r1]                         @ 08033964
	bx lr                                @ 08033966

@ ------------------------------------------------------------------
@ wait_vcount_160   ROM 0x08033968 (Thumb)
@ Busy-wait for the start of V-blank (VCOUNT 160).
@ ------------------------------------------------------------------
	.thumb_func
wait_vcount_160:
	ldr r0, lit_8033AC8                  @ 08033968  = REG_VCOUNT
L_803396A:
	ldrb r1, [r0]                        @ 0803396A
	cmp r1, #0xa0                        @ 0803396C
	beq L_803396A                        @ 0803396E
L_8033970:
	ldrb r1, [r0]                        @ 08033970
	cmp r1, #0xa0                        @ 08033972
	bne L_8033970                        @ 08033974
	mov pc, lr                           @ 08033976

@ ------------------------------------------------------------------
@ reset_pitch_bend   ROM 0x08033978 (Thumb)
@ All 16 chan_bend = 0x2000.
@ ------------------------------------------------------------------
	.thumb_func
reset_pitch_bend:
	movs r1, #0x20                       @ 08033978
	lsls r1, r1, #8                      @ 0803397A
	ldr r0, lit_8033ACC                  @ 0803397C  = chan_bend
	movs r2, #0x40                       @ 0803397E
L_8033980:
	subs r2, #4                          @ 08033980
	str r1, [r0, r2]                     @ 08033982
	bne L_8033980                        @ 08033984
	bx lr                                @ 08033986

@ ------------------------------------------------------------------
@ reset_modulation   ROM 0x08033988 (Thumb)
@ All 16 chan_mod = {0, 0}.
@ ------------------------------------------------------------------
	.thumb_func
reset_modulation:
	movs r1, #0                          @ 08033988
	ldr r0, lit_8033AD0                  @ 0803398A  = chan_mod
	movs r2, #0x80                       @ 0803398C
L_803398E:
	subs r2, #8                          @ 0803398E
	str r1, [r0, r2]                     @ 08033990
	bne L_803398E                        @ 08033992
	bx lr                                @ 08033994

@ ------------------------------------------------------------------
@ clear_mix_buffer   ROM 0x08033996 (Thumb)
@ Zero mix_samples_per_frame s16 samples (176/224/304/352 via fall-through stm runs).
@ At 304/352 this overruns the 448-byte mix_buffer.
@ ------------------------------------------------------------------
	.thumb_func
clear_mix_buffer:
	movs r1, #0                          @ 08033996
	movs r2, #0                          @ 08033998
	movs r3, #0                          @ 0803399A
	movs r4, #0                          @ 0803399C
	movs r5, #0                          @ 0803399E
	movs r6, #0                          @ 080339A0
	ldr r0, lit_8033AD4                  @ 080339A2  = mix_buffer
	ldr r7, lit_8033AD8                  @ 080339A4  = mix_samples_per_frame
	ldr r7, [r7]                         @ 080339A6
	lsrs r7, r7, #1                      @ 080339A8
	cmp r7, #0x58                        @ 080339AA
	beq L_80339BA                        @ 080339AC
	cmp r7, #0x70                        @ 080339AE
	beq L_80339E4                        @ 080339B0
	cmp r7, #0x98                        @ 080339B2
	beq L_80339D6                        @ 080339B4
	cmp r7, #0xb0                        @ 080339B6
	beq L_80339CC                        @ 080339B8
L_80339BA:
	movs r7, #0                          @ 080339BA
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339BC
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339BE
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339C0
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339C2
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339C4
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339C6
	stm r0!, {r1, r2}                    @ 080339C8
	b L_8033A06                          @ 080339CA
L_80339CC:
	movs r7, #0                          @ 080339CC
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339CE
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339D0
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339D2
	stm r0!, {r1, r2, r3}                @ 080339D4
L_80339D6:
	movs r7, #0                          @ 080339D6
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339D8
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339DA
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339DC
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339DE
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339E0
	stm r0!, {r1, r2, r3, r4, r5}        @ 080339E2
L_80339E4:
	movs r7, #0                          @ 080339E4
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339E6
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339E8
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339EA
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339EC
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339EE
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339F0
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339F2
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339F4
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339F6
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339F8
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339FA
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339FC
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 080339FE
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033A00
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033A02
	stm r0!, {r1, r2, r3, r4, r5, r6, r7} @ 08033A04
L_8033A06:
	bx lr                                @ 08033A06

@ ------------------------------------------------------------------
@ init_music_voices   ROM 0x08033A08 (Thumb)
@ 96 music voices = 16 MIDI channels x 6; voice+6 = owning channel.
@ ------------------------------------------------------------------
	.thumb_func
init_music_voices:
	ldr r0, lit_8033ADC                  @ 08033A08  = music_voices
	ldr r3, lit_8033AE0                  @ 08033A0A  = music_voices+0x6
	ldr r6, lit_8033AE4                  @ 08033A0C  = music_voices+0x8
	movs r7, #0                          @ 08033A0E
	movs r4, #1                          @ 08033A10
	movs r5, #0x10                       @ 08033A12
	movs r1, #0x10                       @ 08033A14
	ldr r2, lit_8033AE8                  @ 08033A16  = cfg_music_pool_bytes
	ldr r2, [r2]                         @ 08033A18
L_8033A1A:
	subs r4, #1                          @ 08033A1A
	bne L_8033A24                        @ 08033A1C
	subs r5, #1                          @ 08033A1E
	ldr r4, lit_8033AEC                  @ 08033A20  = cfg_voices_per_chan
	ldr r4, [r4]                         @ 08033A22
L_8033A24:
	subs r2, #0x28                       @ 08033A24
	strb r1, [r0, r2]                    @ 08033A26
	strb r5, [r3, r2]                    @ 08033A28
	str r7, [r6, r2]                     @ 08033A2A
	bne L_8033A1A                        @ 08033A2C
	bx lr                                @ 08033A2E

@ ------------------------------------------------------------------
@ init_sfx_voices   ROM 0x08033A30 (Thumb)
@ 5 SFX voices, channel byte = -1.
@ ------------------------------------------------------------------
	.thumb_func
init_sfx_voices:
	ldr r0, lit_8033AF0                  @ 08033A30  = sfx_voices
	movs r5, #0                          @ 08033A32
	mvns r5, r5                          @ 08033A34
	ldr r1, lit_8033AF4                  @ 08033A36  = cfg_sfx_voices
	ldr r1, [r1]                         @ 08033A38
	movs r2, #0x10                       @ 08033A3A
L_8033A3C:
	strb r2, [r0]                        @ 08033A3C
	strb r5, [r0, #6]                    @ 08033A3E
	adds r0, #0x28                       @ 08033A40
	subs r1, #1                          @ 08033A42
	bne L_8033A3C                        @ 08033A44
	bx lr                                @ 08033A46

@ ------------------------------------------------------------------
@ reset_channel_volume   ROM 0x08033A48 (Thumb)
@ All 16 chan_volume = 127.
@ ------------------------------------------------------------------
	.thumb_func
reset_channel_volume:
	ldr r0, lit_8033AF8                  @ 08033A48  = chan_volume
	movs r1, #0x10                       @ 08033A4A
	movs r2, #0x7f                       @ 08033A4C
L_8033A4E:
	subs r1, #1                          @ 08033A4E
	strb r2, [r0, r1]                    @ 08033A50
	bne L_8033A4E                        @ 08033A52
	bx lr                                @ 08033A54

@ ------------------------------------------------------------------
@ reset_mono_flags   ROM 0x08033A56 (Thumb)
@ All 16 chan_mono = 0 (poly).
@ ------------------------------------------------------------------
	.thumb_func
reset_mono_flags:
	ldr r0, lit_8033AFC                  @ 08033A56  = chan_mono
	movs r1, #0x10                       @ 08033A58
	movs r2, #0                          @ 08033A5A
L_8033A5C:
	subs r1, #1                          @ 08033A5C
	strb r2, [r0, r1]                    @ 08033A5E
	bne L_8033A5C                        @ 08033A60
	bx lr                                @ 08033A62
lit_8033A64:
	.word sfx_timer
lit_8033A68:
	.word REG_DMA1CNT_H
lit_8033A6C:
	.word REG_SOUNDCNT_X
lit_8033A70:
	.word 0x00003443
lit_8033A74:
	.word mix_rate_hz
lit_8033A78:
	.word 0x00002910
lit_8033A7C:
	.word 0xFFFFF9C4
lit_8033A80:
	.word 0x018F0064
lit_8033A84:
	.word 0xFFFFFB1A
lit_8033A88:
	.word 0x01397FC3
lit_8033A8C:
	.word 0x000046ED
lit_8033A90:
	.word 0xFFFFFC64
lit_8033A94:
	.word 0x00E70086
lit_8033A98:
	.word 0x00000130
lit_8033A9C:
	.word 0x00005220
lit_8033AA0:
	.word 0xFFFFFCE2
lit_8033AA4:
	.word 0x00C78032
lit_8033AA8:
	.word 0x00000160
lit_8033AAC:
	.word mix_timer_reload
lit_8033AB0:
	.word mix_pitch_scale
lit_8033AB4:
	.word mix_samples_per_frame
lit_8033AB8:
	.word REG_TM0CNT_L
lit_8033ABC:
	.word mix_timer_reload
lit_8033AC0:
	.word seq_current_song
lit_8033AC4:
	.word mix_max_voices
lit_8033AC8:
	.word REG_VCOUNT
lit_8033ACC:
	.word chan_bend
lit_8033AD0:
	.word chan_mod
lit_8033AD4:
	.word mix_buffer
lit_8033AD8:
	.word mix_samples_per_frame
lit_8033ADC:
	.word music_voices
lit_8033AE0:
	.word music_voices+0x6
lit_8033AE4:
	.word music_voices+0x8
lit_8033AE8:
	.word cfg_music_pool_bytes
lit_8033AEC:
	.word cfg_voices_per_chan
lit_8033AF0:
	.word sfx_voices
lit_8033AF4:
	.word cfg_sfx_voices
lit_8033AF8:
	.word chan_volume
lit_8033AFC:
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

