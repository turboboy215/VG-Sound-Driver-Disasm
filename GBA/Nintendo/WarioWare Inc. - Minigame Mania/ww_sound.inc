@ WarioWare, Inc. (E) sound driver: addresses and structures (all names assigned during analysis)

@ ---- IO registers ----
	.equ REG_VCOUNT, 0x04000006
	.equ REG_SOUND1CNT_L, 0x04000060
	.equ REG_SOUND1CNT_H, 0x04000062
	.equ REG_SOUND1CNT_X, 0x04000064
	.equ REG_SOUND2CNT_L, 0x04000068
	.equ REG_SOUND2CNT_H, 0x0400006C
	.equ REG_SOUND3CNT_L, 0x04000070
	.equ REG_SOUND3CNT_H, 0x04000072
	.equ REG_SOUND3CNT_X, 0x04000074
	.equ REG_SOUND4CNT_L, 0x04000078
	.equ REG_SOUND4CNT_H, 0x0400007C
	.equ REG_SOUNDCNT_L, 0x04000080
	.equ REG_SOUNDCNT_H, 0x04000082
	.equ REG_SOUNDCNT_X, 0x04000084
	.equ REG_WAVE_RAM, 0x04000090
	.equ REG_FIFO_A, 0x040000A0
	.equ REG_FIFO_B, 0x040000A4
	.equ REG_DMA1SAD, 0x040000BC
	.equ REG_DMA1DAD, 0x040000C0
	.equ REG_DMA1CNT_L, 0x040000C4
	.equ REG_DMA1CNT_H, 0x040000C6
	.equ REG_DMA2SAD, 0x040000C8
	.equ REG_DMA2DAD, 0x040000CC
	.equ REG_DMA2CNT_L, 0x040000D0
	.equ REG_DMA2CNT_H, 0x040000D2
	.equ REG_TM0CNT_H, 0x04000102

@ ---- IWRAM variables ----
	.equ gSndRandSeed, 0x03000E78
	.equ gPsgRetrig, 0x03000E80
	.equ gPsgLastVol, 0x03000E88
	.equ gPsgLastFreq, 0x03000E90
	.equ gPsgLastWave, 0x03000E98
	.equ gLivePlayer, 0x03000EA0
	.equ gLiveSynth, 0x03000EA4
	.equ gLiveBuf, 0x03000EA8
	.equ gLiveBufLen, 0x03000EAC
	.equ gLiveRunStatus, 0x03000EAE
	.equ gGameVarsDefault, 0x03000EAF
	.equ gSndRingBuf, 0x03001068
	.equ gSndMixBuf, 0x03001CA8
	.equ gSndVoiceMem, 0x030020A8
	.equ gSndNoteMem, 0x030021A8
	.equ gSndVcountStart, 0x03006550
	.equ gMixMode, 0x03006554
	.equ gReverbState, 0x03006560
	.equ gMixNumVoices, 0x03006570
	.equ gMixFilter, 0x03006580
	.equ gSeqNewTickRate, 0x0300658C
	.equ gReverbDelay, 0x03006590
	.equ gSeqLoopStartHit, 0x03006594
	.equ gReverbHpShift, 0x03006598
	.equ gSeqLoopEndHit, 0x0300659C
	.equ gMixBlockLen, 0x030065A0
	.equ gRingBufR, 0x030065A4
	.equ gSweepDepth, 0x030065A8
	.equ gSweepPlayer, 0x030065AC
	.equ gGameVarIndex, 0x030065B0
	.equ gNoteQueue, 0x030065C0
	.equ gPsgNotes, 0x03006610
	.equ gClipTable, 0x03006690
	.equ gGameVarCount, 0x03006890
	.equ gRingWords, 0x03006894
	.equ gFilterGain, 0x03006898
	.equ gSweep, 0x030068A0
	.equ gSweepMode, 0x030068AC
	.equ gRingWritePos, 0x030068B0
	.equ gReverbLpShift, 0x030068B4
	.equ gMixRamRoutines, 0x030068C0
	.equ gNoteQueueLen, 0x030068E8
	.equ gGameVars, 0x030068EC
	.equ gSndVcountEnd, 0x030068F0
	.equ gMixVcount, 0x030068F4
	.equ gMixVoices, 0x030068F8
	.equ gNumNotes, 0x030068FC
	.equ gReverbBase, 0x03006900
	.equ gMixRate, 0x03006904
	.equ gMixRamCode, 0x03006910
	.equ gRingReadPos, 0x03007210
	.equ gReverbLevel, 0x03007214
	.equ gMixSamplesPerFrame, 0x03007218
	.equ gMixVolBoost, 0x0300721C
	.equ gMixBufPtr, 0x03007220
	.equ gMixTimerReload, 0x03007224
	.equ gRingBufL, 0x03007228
	.equ gNotes, 0x0300722C
	.equ gMixFilterPrev, 0x03007230
	.equ gMixEnabled, 0x03007234

@ ---- ROM data used by the code (defined as labels in ww_sound_rodata.s / ww_music_data.s) ----
	.ifndef WW_DATA_FILE
	.equ __clz_tab, 0x083B2060
	.equ sndKeyFreqTable, 0x083FD1CC
	.equ sndSemitoneTable, 0x083FD2CC
	.equ sndSineTable, 0x083FD304
	.equ psgWaveVolTable, 0x083FD704
	.equ psgRegA, 0x083FD70C
	.equ psgRegB, 0x083FD71C
	.equ psgNoiseTable, 0x083FD72C
	.equ seqLoopStartMarker, 0x083FD768
	.equ seqLoopEndMarker, 0x083FD76C
	.equ sndBankTable, 0x08405310
	.equ sndSongTable, 0x0840BB10
	.equ sndSongPtrTable, 0x084123E8
	.equ sndSoundIdTable, 0x084140C8
	.equ sndLastPlayer, 0x08417A84
	.equ sndConfig, 0x08417A88
	.equ sndPlayers, 0x08417A90
	.equ sndPlayerConfig, 0x08417AB4
	.equ sndGroupCount, 0x08417B68
	.equ sndGroups, 0x08417B6C
	.equ sndSampleHeaders, 0x08417BD8
	.endif

@ ---- libgcc helpers outside the driver ----
	.equ __ashldi3, 0x080F4988
	.equ _call_via_r1, 0x080F49C0
	.equ _call_via_r2, 0x080F49C4
	.equ __divsi3, 0x080F49F8
	.equ __modsi3, 0x080F4B08
	.equ __muldi3, 0x080F4BD8
	.equ __udivdi3, 0x080F4C48
	.equ __udivsi3, 0x080F5020


@ ================================================================================================
@ Structures (offsets). Bit fields are given as "bits a-b of the word/halfword at +off".
@ ================================================================================================

@ ---- Voice (0x20): one mixer channel (gMixVoices, 8 of them) ----
	.equ Voice_flags,      0x00   @ u8: bit 0 active, 1 needs resampling (step != 1.0), 2 no interpolation, 3 wet (filtered)
	.equ Voice_vol,        0x01   @ u8 0..127
	.equ Voice_gainL,      0x02   @ s8 left gain (0..127)
	.equ Voice_gainR,      0x03   @ s8 right gain (negative = phase-inverted, CC75)
	.equ Voice_pcm,        0x04   @ s8 * sample data
	.equ Voice_lengthWords,0x08   @ sample length / 4 (never read)
	.equ Voice_pos,        0x0C   @ 18.14 position
	.equ Voice_loopStart,  0x10   @ 18.14 (= end when not looping)
	.equ Voice_end,        0x14   @ 18.14 loop end or sample end
	.equ Voice_step,       0x18   @ 18.14 increment per output sample (0x4000 = 1.0)
	.equ Voice_baseStep,   0x1C   @ step for 1 "Hz" of note frequency at the sample's root, see voiceSetSample
	.equ Voice_SIZE,       0x20

@ ---- MixFilter (gMixFilter, 0x0C) ----
	.equ MixFilter_cutoff, 0x00   @ s32, low byte used: 0x00-0x7F low-pass (a = 2c), 0x80-0xFF high-pass (a = 2(c-0x80))
	.equ MixFilter_stateR, 0x04
	.equ MixFilter_stateL, 0x08

@ ---- Note (0x20): a playing key (gNotes[8] -> voice i, gPsgNotes[4] -> PSG channel i) ----
	.equ Note_flags,       0x00   @ bit 0 active, bits 1-7 MIDI key (for note-off matching); word bits 15-31 = frequency
	.equ Note_velocity,    0x01   @ bits 0-6
	.equ Note_inst,        0x04   @ Instrument *
	.equ Note_synth,       0x08   @ Synth *
	.equ Note_chan,        0x0C   @ Chan *
	.equ Note_bendDown,    0x10   @ s16 freq(key) - freq(key - bendRange)
	.equ Note_bendUp,      0x12   @ s16 freq(key + bendRange) - freq(key)
	.equ Note_vibSpan,     0x14   @ s16 freq(key + vibRange) - freq(key)
	.equ Note_prio,        0x16   @ u8 channel priority at note-on
	.equ Note_isNew,       0x17   @ u8 1 until the first noteUpdate
	.equ Note_panOffset,   0x18   @ s16 from a drum-map instrument
	.equ Note_env,         0x1C   @ u32: bits 0-7 state (0 attack, 1 decay, 2 sustain, 3 release, 4 fast release),
	                              @      bits 8-31 level (7.16, 0x7F0000 = full; byte +0x1F = level >> 16)
	.equ Note_SIZE,        0x20

@ ---- Chan (0x20): synth channel = MIDI track ----
	.equ Chan_word0,       0x00   @ bit 0 mute, bit 1 no pitch update, bits 2-8 program, bits 9-22 bank select (unused),
	                              @ bits 23-29 volume (CC7)
	.equ Chan_flags3,      0x03   @ bit 6 wet (CC72), bit 7 invert right (CC75)
	.equ Chan_word4,       0x04   @ bits 0-6 pan (CC10), 7-13 expression (CC11), 14-20 mod depth (CC1), 21-27 field6,
	                              @ bits 28-29 LFO type (CC22: 0 vibrato, 1 tremolo, 2 auto-pan)
	.equ Chan_word8,       0x08   @ bits 0-13 pitch bend (0x2000 centre), 14-20 gain (computed each frame),
	                              @ bits 21-28 priority (CC33 + song priority)
	.equ Chan_vibRange,    0x0C   @ u8 semitones of full vibrato (1; no CC)
	.equ Chan_lfoValue,    0x0D   @ s8 current LFO output
	.equ Chan_bendRange,   0x0F   @ u8 semitones (CC20, default 2)
	.equ Chan_lfoSpeed,    0x10   @ u16 phase step per frame (CC21 << 8)
	.equ Chan_lfoPhase,    0x12   @ u16
	.equ Chan_lfoDelay,    0x14   @ u8 frames (CC26)
	.equ Chan_lfoDelayCount,0x15
	.equ Chan_randomPitchBase,0x16 @ u16 (CC82)
	.equ Chan_randomPitchRange,0x18
	.equ Chan_randomPitchCur,0x1A @ u16 factor/256 chosen at note-on (0x100 = none)
	.equ Chan_randomKey,   0x1C   @ u8 +-semitones (CC83)
	.equ Chan_randomKeyRate,0x1D  @ u8 frames (CC84)
	.equ Chan_randomKeyCount,0x1E
	.equ Chan_SIZE,        0x20

@ ---- Synth (0x28) ----
	.equ Synth_volume,     0x00   @ u8 = song volume * player volume * fade
	.equ Synth_transpose,  0x01   @ s8 semitones (no caller)
	.equ Synth_pan,        0x02   @ s8, added as pan/2
	.equ Synth_tune,       0x04   @ s16 semitones 8.8
	.equ Synth_field6,     0x06   @ u16 0x1400, never read
	.equ Synth_freqTable,  0x0C   @ u16 *: Hz per key (sndKeyFreqTable)
	.equ Synth_bank,       0x10   @ Instrument **
	.equ Synth_word14,     0x14   @ bits 0-4 number of channels, 5-12 priority base
	.equ Synth_chans,      0x18   @ Chan *
	.equ Synth_scale,      0x1C   @ s8[12] semitone offsets for random keys (SysEx 01)
	.equ Synth_SIZE,       0x28

@ ---- Track (0x24) ----
	.equ Track_word0,      0x00   @ bit 0 active, 1 active at loop start, 2-9 running status, 10-17 status at loop start;
	                              @ halfword +2 bits 2-9: status snapshot
	.equ Track_start,      0x04
	.equ Track_ptr,        0x08
	.equ Track_time,       0x0C   @ ticks << 8 until the next event
	.equ Track_loopPtr,    0x10
	.equ Track_loopTime,   0x14
	.equ Track_snapPtr,    0x18   @ state at the start of the current frame
	.equ Track_snapTime,   0x1C
	.equ Track_SIZE,       0x24

@ ---- Player (0x30) ----
	.equ Player_word0,     0x00   @ bits 0-4 max tracks, 5-9 tracks, 10 loop start captured, 11 paused,
	                              @ 12-20 tempo (BPM), 21 priority check, 27-29 fade mode
	.equ Player_synth,     0x04
	.equ Player_tracks,    0x08
	.equ Player_song,      0x0C   @ SongEntry * (0 = stopped)
	.equ Player_tickRate,  0x10   @ MIDI ticks per frame << 8
	.equ Player_savedTickRate,0x14 @ written at the loop start, never read
	.equ Player_loopStartText,0x18 @ "["
	.equ Player_loopEndText,0x1C  @ "]"
	.equ Player_loopStartLen,0x20
	.equ Player_loopEndLen,0x21
	.equ Player_ppqn,      0x22   @ from the MIDI header (24)
	.equ Player_tempoScale,0x24   @ 0x100 = 1.0
	.equ Player_volume,    0x26   @ 0x100 = 1.0
	.equ Player_fade,      0x28   @ 0x8000 = full
	.equ Player_fadeStep,  0x2A
	.equ Player_reverb,    0x2C   @ u8[4]: CC78-81 offsets (0x40 = none) to level, delay, lpShift, hpShift
	.equ Player_SIZE,      0x30

@ ---- Sweep (gSweep, 0x0C): tempo-synced LFO driving the master filter ----
	.equ Sweep_delay,      0x00   @ ticks before it starts
	.equ Sweep_fadeIn,     0x01   @ ticks of fade-in
	.equ Sweep_rate,       0x02   @ u16 0x10000 / period
	.equ Sweep_phase,      0x04
	.equ Sweep_maxPhase,   0x05   @ 0 = free running
	.equ Sweep_state,      0x06   @ 0 off, 1 delay, 2 fade-in, 3 running
	.equ Sweep_out,        0x07   @ s8
	.equ Sweep_acc,        0x08   @ ticks << 8

@ ---- ROM data (see ww_macros.inc) ----
@ Instrument "A"/"P" (0x20/0x24): u8 type, u8 key | noInterp << 7, s16 pan, ptr (SampleHeader * / wave), u32 envStart,
@            u32 sustain, u32 attack, u32 decay, u32 sustainRate, u32 release [, u32 psg]
@ Instrument "R" (8): u32 'R' | base << 8, Instrument **table        (key -> table[key - base])
@ Instrument "S" (12): u32 'S' | base << 8, u8 *keymap, Instrument **table   (key -> table[keymap[key - base]])
@ SampleHeader (0x18): u32 length, rate, rootKey, loopStart, loopEnd; s8 *pcm
@ SongEntry (0x14): MIDI *; u32 bits 5-14 bank, 15-21 volume, 22-31 priority; u32 0xFF; char *name; u32 id

