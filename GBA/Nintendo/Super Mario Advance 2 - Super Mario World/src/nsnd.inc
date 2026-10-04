@ nsnd.inc - hardware registers and driver structures of the Nintendo GBA sound driver
@ used by Super Mario Advance 2/3/4 and A Link to the Past (GBA).
@ Offsets are those of SMA3, SMA4 and ALttP; define GEN_A for the SMA2 / Mario Bros. builds.

@ ---- I/O ------------------------------------------------------------------------
	.equ REG_NR10,        0x04000060	@ SOUND1CNT_L
	.equ REG_NR11,        0x04000062	@ SOUND1CNT_H low: length / duty
	.equ REG_NR12,        0x04000063	@ SOUND1CNT_H high: envelope
	.equ REG_SOUND1CNT_X, 0x04000064
	.equ REG_NR21,        0x04000068
	.equ REG_NR22,        0x04000069
	.equ REG_SOUND2CNT_H, 0x0400006C
	.equ REG_NR30,        0x04000070	@ SOUND3CNT_L
	.equ REG_NR31,        0x04000072
	.equ REG_NR32,        0x04000073	@ wave volume
	.equ REG_SOUND3CNT_X, 0x04000074
	.equ REG_NR41,        0x04000078
	.equ REG_NR42,        0x04000079
	.equ REG_NR43,        0x0400007C
	.equ REG_NR44,        0x0400007D
	.equ REG_SOUNDCNT_L,  0x04000080
	.equ REG_NR51,        0x04000081	@ PSG channel -> left/right enables
	.equ REG_SOUNDCNT_H,  0x04000082
	.equ REG_SOUNDCNT_X,  0x04000084
	.equ REG_SOUNDBIAS,   0x04000088
	.equ REG_WAVE_RAM,    0x04000090
	.equ REG_FIFO_A,      0x040000A0	@ -> left
	.equ REG_FIFO_B,      0x040000A4	@ -> right
	.equ REG_DMA1SAD,     0x040000BC
	.equ REG_DMA2SAD,     0x040000C8
	.equ REG_TM0CNT,      0x04000100

@ ---- constants ------------------------------------------------------------------
	.equ MIX_RATE,     10512	@ Hz: timer 0 reload 0xF9C4 (16777216 / 1596)
	.equ MIX_FRAME,    176		@ samples per frame and channel
	.equ NUM_DS_VOICES, 7
	.equ NUM_TRACKS,   24
	.equ NUM_PLAYERS,  20
	.equ CMD_QUEUE_LEN, 46

@ ---- SndConfig (argument of sndInit) ----------------------------------------------
	.equ cfg_sampleBanks,      0x00	@ u32 offset table -> sample banks
	.equ cfg_instBanks,        0x04	@ u32 offset table -> instrument banks
	.equ cfg_songs,            0x08	@ u32 offset table -> songs
	.equ cfg_sfxSets,          0x0C	@ u32 offset table -> sound-effect sets
	.equ cfg_instToSampleBank, 0x10	@ u16 per instrument bank
	.equ cfg_songBankMaps,     0x14	@ u32 offset table -> u16 bank maps
	.equ cfg_sfxBankMaps,      0x18

@ ---- SampleHdr ----------------------------------------------------------------------
	.equ smp_length, 0x00		@ samples (one-shot end)
	.equ smp_rate,   0x04		@ Hz at the root key
	.equ smp_loopStart, 0x08
	.equ smp_loopEnd, 0x0C		@ 0 = no loop
	.equ smp_pcm,    0x10		@ s8[]

@ ---- InstRec (8 bytes; 12 for square 1, 4 for sample kits and key splits) ---------------
	.equ ins_type,    0x00		@ 0 sample, 1 sq1, 2 sq2, 3 wave, 4 noise, 0x10 kit, 0x11 sample kit, 0x12 split
	.equ ins_flags,   0x01		@ bit 0: 'data' is a duty sequence; bit 4: length ignores the tempo offset
	.equ ins_data,    0x02		@ sample number / fixed duty / offset of wave, duty sequence or table
	.equ ins_env,     0x04		@ offset of the envelope (kits: low byte = first key)
	.equ ins_release, 0x06
	.equ ins_root,    0x07
	.equ ins_sweep,   0x08		@ square 1 only

@ ---- Voice (0x78 bytes) ------------------------------------------------------------
	.equ v_type,      0x00		@ 0 sampled, 1-4 PSG channel
	.equ v_state,     0x01		@ 0 free, 1 on, 2 released
	.equ v_track,     0x04
	.equ v_priority,  0x08
	.ifdef GEN_A
	.equ v_velocity,  0x09
	.else
	.equ v_key,       0x09
	.equ v_velocity,  0x0A
	.endif
	.equ v_freq,      0x0C		@ base pitch (kDsPitch units / GB frequency register)
	.equ v_outFreq,   0x10		@ after portamento, bend and vibrato
	.equ v_volume,    0x14
	.equ v_length,    0x18		@ s16 frames until the automatic note-off
	.equ v_echo,      0x1A
	.equ v_fixedPan,  0x1B
	.equ v_pan,       0x1C
	.equ v_lfoPhase,  0x20
	.equ v_lfoDelay,  0x24
	.equ v_lfoParams, 0x28		@ -> Track.lfoDelay
	.equ v_portaDelay, 0x2C
	.equ v_portaCount, 0x30
	.equ v_portaOfs,  0x34
	.equ v_portaTotal, 0x38
	.equ v_portaStep, 0x3C
	.equ v_envLevel,  0x40
	.equ v_envTarget, 0x44
	.equ v_envCount,  0x48		@ s16
	.equ v_envStep,   0x4A		@ s16
	.equ v_envTable,  0x4C
	.equ v_envIndex,  0x50		@ s8
	.equ v_inst,      0x54
	.equ v_release,   0x58
	.equ v_sample,    0x5C
	.equ v_pos,       0x60		@ 24.8 sample position / PSG: frames since key-on
	.equ v_psgData,   0x64		@ wave, duty sequence or fixed duty byte
	.equ v_prev,      0x68
	.equ v_next,      0x6C
	.equ v_tprev,     0x70
	.equ v_tnext,     0x74
	.equ VOICE_SIZE,  0x78

@ ---- Track (0x54 bytes) --------------------------------------------------------------
	.equ t_ptr,       0x00
	.equ t_sampleBank, 0x04
	.equ t_player,    0x08
	.equ t_voices,    0x0C
	.equ t_lfoDelay,  0x10		@ u16
	.equ t_lfoSpeed,  0x14
	.equ t_lfoDepth,  0x18
	.equ t_portaOn,   0x1C
	.equ t_portaMode, 0x1D
	.equ t_portaKey,  0x1E
	.equ t_portaDelay, 0x20		@ u16
	.equ t_portaLen,  0x22		@ u16
	.equ t_stack,     0x24		@ 3 return addresses
	.equ t_sp,        0x30
	.equ t_wait,      0x34		@ ticks * 150
	.equ t_bank,      0x40		@ u16
	.equ t_program,   0x42		@ u16
	.equ t_noteLen,   0x44		@ u16
	.equ t_restLen,   0x46		@ u16
	.equ t_velocity,  0x48
	.equ t_hold,      0x49
	.equ t_mute,      0x4A
	.equ t_pan,       0x4B
	.equ t_echo,      0x4C
	.equ t_volume,    0x4D
	.equ t_expression, 0x4E
	.equ t_bend,      0x4F
	.equ t_bendRange, 0x50
	.equ t_transpose, 0x51
	.equ t_priority,  0x52
	.equ t_noteAdvances, 0x53
	.equ TRACK_SIZE,  0x54

@ ---- Player (0x48 bytes; 0x44 in GEN_A) -----------------------------------------------
	.equ p_bankMap,   0x00
	.equ p_base,      0x04
	.equ p_tracks,    0x08		@ 10 pointers
	.equ p_tempo,     0x30		@ u16, 150 = 1 tick per frame (= BPM at 24 ticks/quarter)
	.equ p_tempoOfs,  0x32		@ s16
	.equ p_volume,    0x34		@ u16, 0x8000 = 1.0
	.equ p_fadeStep,  0x36
	.equ p_fadeTarget, 0x38
	.equ p_fadeCount, 0x3A
	.equ p_flags,     0x3C		@ bit 0: paused
	.ifdef GEN_A
	.equ p_volume2,   0x40
	.equ p_state,     0x41
	.equ p_isSfx,     0x42
	.equ p_hookFlags, 0x43
	.equ PLAYER_SIZE, 0x44
	.else
	.equ p_songVolume, 0x40		@ command EA
	.equ p_volume2,   0x41		@ command 5
	.equ p_state,     0x42		@ 0 idle, 1 playing, 2 fading out
	.equ p_isSfx,     0x43
	.equ p_hookFlags, 0x44
	.equ PLAYER_SIZE, 0x48
	.endif

@ ---- SndCmd (12 bytes, command queue) --------------------------------------------------
	.equ cmd_op, 0x00
	.equ cmd_a,  0x04
	.equ cmd_b,  0x08
