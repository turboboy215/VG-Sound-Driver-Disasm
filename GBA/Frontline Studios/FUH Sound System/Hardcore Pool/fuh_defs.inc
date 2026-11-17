@ ==================================================================================================
@ fuh_defs.inc -- shared definitions for the FUH Sound System sources (Hardcore Pool (E) (M4))
@ ==================================================================================================

@ ---- RAM -----------------------------------------------------------------------------------------
	.equ mus_state,  0x03000000	@ MusState (player state, 0x2C bytes)
	.equ mixer,      0x030031D8	@ Mixer
	.equ mix_outbuf, 0x030031FC	@ u8  [2][512]  FIFO A double buffer (304 bytes used per half)
	.equ mix_acc,    0x030035FC	@ u16 [304]     biased accumulator (0x400 = silence)
	.equ mix_lut,    0x03003860	@ s8  [2048]    output table built by Mixer_BuildOutputTable
	.equ g_game,     0x03002DF4	@ the game's global object (heap at +0x3E0, loop counter at +0x58)
	.equ REG_IFBIOS, 0x03007FF8	@ BIOS IntrCheck flags

@ ---- ROM (outside the sound code) ---------------------------------------------------------------
	@ StepTable (u32[7680], ROM 083E1E00) is defined in fuh_rodata.s
	.equ memset,     0x080332C4	@ libc memset (Thumb)
	.equ __divsi3,   0x0803999C	@ libgcc (Thumb)
	.equ Heap_Alloc, 0x08039430	@ game heap: Heap_Alloc(heap, size, align, file, line) (Thumb)
	.equ str_DirectSoundSystemMixer_cpp, 0x083EC600	@ "DirectSoundSystemMixer.cpp"

@ ---- I/O ----------------------------------------------------------------------------------------
	.equ REG_DMA1SAD,    0x040000BC
	.equ REG_FIFO_A,     0x040000A0
	.equ REG_TM0CNT_L,   0x04000100
	.equ REG_TM0CNT_H,   0x04000102
	.equ REG_SOUNDCNT_X, 0x04000084

@ ---- MusState (mus_state, 03000000) ------------------------------------------------------------
	.equ MS_state,    0x00	@ 0 = stopped, otherwise running (Mus_Play writes 2)
	.equ MS_tick,     0x04	@ frames since the last row
	.equ MS_speed,    0x08	@ frames per row
	.equ MS_unused0C, 0x0C	@ copy of Module.unused08, never read
	.equ MS_module,   0x10	@ Module *
	.equ MS_pattern,  0x14	@ PatternHeader * of the current order
	.equ MS_data,     0x18	@ pattern data pointer (next row)
	.equ MS_order,    0x1C
	.equ MS_row,      0x20
	.equ MS_paused,   0x24	@ Mus_TogglePause
	.equ MS_savedVol, 0x28	@ written by Mus_TogglePause, never read

@ ---- Mixer (mixer, 030031D8) --------------------------------------------------------------------
	.equ MX_voices,    0x00	@ Voice * (heap, 0x200 bytes)
	.equ MX_samples,   0x04	@ samples per frame (304)
	.equ MX_master,    0x08	@ master volume (80)
	.equ MX_nVoices,   0x0C	@ 8
	.equ MX_bufOfs,    0x10	@ 0 or 0x200: half of mix_outbuf mixed last
	.equ MX_rate,      0x14	@ 18157, never read
	.equ MX_musicVol,  0x1C	@ 0..256
	.equ MX_fadeDelta, 0x20	@ added to musicVol once per row

@ ---- Voice (64 bytes; music channel n = voice n) ------------------------------------------------
	.equ V_state,    0x00	@ 0 = off
	.equ V_step,     0x04	@ 16.16 source bytes per output sample
	.equ V_frac,     0x08	@ position fraction (low 16 bits)
	.equ V_ptr,      0x0C	@ current sample pointer
	.equ V_end,      0x10	@ data + length
	.equ V_loopStart,0x14	@ absolute
	.equ V_loopEnd,  0x18	@ absolute, 0 = one-shot
	.equ V_vol,      0x1C	@ mix volume (music: chanVol * musicVol >> 8)
	.equ V_handler,  0x20	@ tick handler (ARM) or 0
	.equ V_mem24,    0x24	@ effect parameter memory shared by effects 1-4, 6-8, 12
	.equ V_phase,    0x28	@ vibrato phase 0..63
	.equ V_period,   0x2C	@ step-table index (XM linear period)
	.equ V_mem30,    0x30	@ vibrato parameter used by effect 12
	.equ V_tpTarget, 0x34	@ tone-porta target period
	.equ V_mem38,    0x38	@ last instrument AND sample-offset memory (same field)
	.equ V_chanVol,  0x3C	@ 0..64

@ ---- Module data (see fuh_data.s) ---------------------------------------------------------------
	.equ MOD_nch, 0x00
	.equ MOD_norders, 0x04
	.equ MOD_unused08, 0x08
	.equ MOD_speed, 0x0C
	.equ MOD_instruments, 0x10
	.equ MOD_orders, 0x14
