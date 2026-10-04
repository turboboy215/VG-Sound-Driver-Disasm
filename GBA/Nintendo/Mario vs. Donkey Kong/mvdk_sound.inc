@ ===========================================================================
@  mvdk_sound.inc - shared definitions for the Mario vs. Donkey Kong (E)
@  sound driver disassembly. All names were assigned during this analysis;
@  the ROM contains no symbols.
@ ===========================================================================

	.macro thumb_func_start name
	.thumb_func
	.global \name
	.type \name, %function
	.endm

	.macro arm_func_start name
	.arm
	.global \name
	.type \name, %function
	.endm

@ ---- IWRAM globals (.bss of the driver) ----------------------------------
	.equ gMusTickPos,      0x030007E8 @ u32  samples already mixed in the current tick (0 = tick start)
	.equ gMusTick,         0x030007EC @ u32  current tick inside the row (0 = row tick)
	.equ gPsgSeq,          0x03000808 @ PsgSeq  (0x40 bytes) PSG register sequencer, see psgTimerIrq
	.equ gSndClearFn,      0x03001F50 @ ->RAM copy of sndArmA_Clear32
	.equ gSndMixSpanFn,    0x03001F54 @ ->RAM copy of sndArmB_MixSpan
	.equ gSndDmaIrqFn,     0x03001F58 @ ->RAM copy of sndArmA_DmaIrq
	.equ gSndDownmixFn,    0x03001F68 @ ->RAM copy of sndArmA_Downmix
	.equ gSndMixChannelFn, 0x03001F6C @ ->RAM copy of sndArmB_MixChannel
	.equ gSndCpuTimer,     0x03001F70 @ u32  profiling counter - never written by anything
	.equ gSndCpuLast,      0x03001F74 @ u32  (gSndCpuTimer delta of the last sndFrame, always 0)
	.equ gSndCpuTotal,     0x03001F78 @ u32  (running sum, always 0)
	.equ gSnd,             0x03001F80 @ SndState*  the whole driver state (heap block)
	.equ gSndHeapSize,     0x03001F84 @ u32  bump allocator: size
	.equ gSndHeapBase,     0x03001F88 @ u8*  bump allocator: base
	.equ gSndHeapUsed,     0x03001F8C @ u32  bump allocator: bytes used
	.equ gMusVolume,       0x03001F94 @ s32  song volume 0..128 used by sndArmB_MixChannel
	.equ gMusCurChannel,   0x03001F98 @ MusChannel* channel being mixed (written, never read)

@ ---- IO registers -------------------------------------------------------
	.equ REG_SOUND3CNT_L,  0x04000070
	.equ REG_SOUNDCNT_L,   0x04000080
	.equ REG_SOUNDCNT_H,   0x04000082
	.equ REG_SOUNDCNT_X,   0x04000084
	.equ REG_WAVE_RAM,     0x04000090
	.equ REG_FIFO_A,       0x040000A0
	.equ REG_DMA1SAD,      0x040000BC
	.equ REG_DMA1CNT,      0x040000C4
	.equ REG_DMA3SAD,      0x040000D4
	.equ REG_TM0CNT,       0x04000100
	.equ REG_TM1CNT,       0x04000104
	.equ REG_IE,           0x04000200

@ ---- SndState (heap block, pointer in gSnd) ------------------------------
@ size = SND_STATE_SIZE + (nSfxVoices-1)*VC_SIZE
	.equ ST_nVoices,     0x000  @ u8  number of SFX voices (sndInit arg 3)
	.equ ST_flags,       0x001  @ u8  1=no buffer swap since last VBlank, 2=DMA swapped a buffer,
	                            @     4=DMA stopped, 8=sndFrame busy, 0x10=stereo
	.equ ST_irqCount,    0x002  @ u8  DMA1 IRQs left until the buffer ends (18 x 16 samples)
	.equ ST_unused3,     0x003  @ u8  sndInit arg 4, never read
	.equ ST_unused4,     0x004  @ u8  sndInit arg 5 (copy), never read
	.equ ST_mixBuf,      0x005  @ u8  buffer that sndFrame fills next (0..2)
	.equ ST_playBuf,     0x006  @ u8  buffer the DMA is playing
	.equ ST_nextBuf,     0x007  @ u8  buffer the DMA restarts with
	.equ ST_lastMixed,   0x008  @ u8  buffer sndFrame filled last
	.equ ST_handleSeq,   0x00C  @ u32 SFX handle counter
	.equ ST_buffers,     0x010  @ u8  [3][2][288] 8-bit output, L then R (0x240 each)
	.equ ST_mix16,       0x6D0  @ s16 [288][2] interleaved 16-bit mix buffer
	.equ SND_ARMA,       0xB50  @ RAM copy of ARM module A (0xE8 bytes)
	.equ SND_ARMB,       0xC38  @ RAM copy of ARM module B (0x390 bytes)
	.equ SND_PLAYER,     0xFC8  @ MusPlayer (0x514 bytes)
	.equ SND_VOICES,     0x14DC @ SfxVoice [nVoices]
	.equ SND_STATE_SIZE, 0x14F0 @ size with one SFX voice
	.equ SND_BUF_LEN,    288    @ samples per buffer (16384 Hz, ~1.05 frames)

@ ---- SfxVoice (0x14 bytes) ------------------------------------------------
	.equ VC_flags,   0x00 @ u8  bits0-1 active, bit2 loop, bits4-7 priority
	.equ VC_pan,     0x01 @ u8  0..127, 64 = centre
	.equ VC_wide,    0x02 @ u8  0..127 stereo-widening amount (second, phase-inverted tap)
	.equ VC_vol,     0x03 @ u8  0..255
	.equ VC_handle,  0x04 @ u32 handle returned by sfxPlay
	.equ VC_pos,     0x08 @ u32 position, 18.14 fixed point
	.equ VC_step,    0x0C @ u32 step = playback rate in Hz (output is 16384 Hz)
	.equ VC_sfx,     0x10 @ SfxEntry*
	.equ VC_SIZE,    0x14

@ ---- MusPlayer (0x514 bytes at SndState+SND_PLAYER) -------------------------
	.equ PL_module,      0x000 @ Module*
	.equ PL_chan,        0x004 @ MusChannel[16]
	.equ PL_voiceOwner,  0x4C4 @ MusChannel* [8]: owner of each mixing voice (1 = reserved by SFX)
	.equ PL_patPtr,      0x4E4 @ u8* packed pattern read pointer
	.equ PL_volume,      0x4E8 @ s16 song volume (0..128)
	.equ PL_tickHz,      0x4EA @ s16 BPM*2/5
	.equ PL_speed,       0x4EC @ s16 ticks per row
	.equ PL_loop,        0x4EE @ u16 bit0: loop at the end of the order list
	.equ PL_lastOrder,   0x4F0 @ s16
	.equ PL_order,       0x4F2 @ s16 current order; -1 = paused, -2 = stopped
	.equ PL_lastRow,     0x4F4 @ s16
	.equ PL_row,         0x4F6 @ s16 next row to read
	.equ PL_savedOrder,  0x4F8 @ s16 order saved by musStop/musPause
	.equ PL_nChannels,   0x4FA @ u8  module channels (max 16)
	.equ PL_maxVoices,   0x4FB @ u8  mixing voices for music (max 8)
	.equ PL_rowMask,     0x4FC @ u32 bit n = channel n had a cell in the current row
	.equ PL_tick,        0x500 @ u32 tick inside the row
	.equ PL_tickPos,     0x504 @ u32 samples into the tick
	.equ PL_rowLen,      0x508 @ u32 samples per row (computed, never read)
	.equ PL_tickLen,     0x50C @ u32 samples per tick = 16384*5/(2*BPM)
	.equ PL_voiceMap,    0x510 @ u8[3] mixing voice used by SFX voice 0..2 (1-based, 0 = default 8-n)

@ ---- MusChannel (0x4C bytes) ---------------------------------------------
	.equ CH_volEnv,   0x00 @ EnvState {u16 value 8.8; u8 cur|next<<4; u8 -; u16 tick; u16 -}
	.equ CH_panEnv,   0x08 @ EnvState
	.equ CH_note,     0x10 @ u8  (+1 = last value)
	.equ CH_ins,      0x12 @ u8
	.equ CH_volcol,   0x14 @ u8
	.equ CH_pancol,   0x16 @ u8  0x80 = none
	.equ CH_cmd,      0x18 @ u8
	.equ CH_param,    0x1A @ u8
	.equ CH_finetune, 0x1C @ s8
	.equ CH_voice,    0x1D @ u8  bit0 = owns a mixing voice, bits1-7 = last mixed volume
	.equ CH_dir,      0x1E @ s16 mixer direction (written, never read)
	.equ CH_pos,      0x20 @ u32 sample position, 18.14
	.equ CH_baseVol,  0x24 @ s8
	.equ CH_mask,     0x25 @ u8  last pattern mask
	.equ CH_period,   0x26 @ s16 period used by the mixer (linear, 40..7680)
	.equ CH_basePer,  0x28 @ s16 period without vibrato/arpeggio
	.equ CH_portaTgt, 0x2A @ s16 tone portamento target
	.equ CH_vol,      0x2C @ s8  0..64
	.equ CH_pan,      0x2D @ s8  0..64 (negative = surround)
	.equ CH_chanVol,  0x2E @ s8  module channel volume
	.equ CH_mixVol,   0x2F @ s8  chanVol*insVol/64*sampleAmp/64
	.equ CH_fade,     0x30 @ u16 fadeout volume
	.equ CH_fadeSpd,  0x32 @ u16 fadeout*2 | 1 = key released
	.equ CH_fxMem,    0x34 @ u8[8] effect parameter memory
	.equ CH_insPtr,   0x3C @ Instrument*
	.equ CH_smpPtr,   0x40 @ Sample*
	.equ CH_vibWave,  0x44 @ u8
	.equ CH_tremWave, 0x45 @ u8
	.equ CH_autoVib,  0x46 @ s16 auto-vibrato position (-1 = off)
	.equ CH_vibPos,   0x48 @ s16
	.equ CH_tremPos,  0x4A @ s16
	.equ CH_SIZE,     0x4C

@ ---- ROM data layouts (see mvdk_music_data.s) ------------------------------
	.equ MOD_songLen, 0x34
	.equ MOD_restart, 0x36
	.equ MOD_nChan,   0x38
	.equ MOD_nPat,    0x3A
	.equ MOD_nIns,    0x3C
	.equ MOD_speed,   0x3E
	.equ MOD_bpm,     0x40
	.equ MOD_orders,  0x44
	.equ MOD_insMap,  0x144
	.equ MOD_chanSet, 0x244
	.equ MOD_patTab,  0x284
	.equ INS_SIZE,    0x13C
	.equ INS_volEnv,  0x94
	.equ INS_panEnv,  0xE4
	.equ ENV_type,    0x35
