@ som_sound.inc -- symbols for the Brownie Brown sound driver rev. 2 (Sword of Mana, AVSP)

@ ---- I/O
	.equ REG_SOUND1CNT_L, 0x04000060
	.equ REG_SOUND1CNT_H, 0x04000062
	.equ REG_SOUND1CNT_X, 0x04000064
	.equ REG_SOUND2CNT_L, 0x04000068
	.equ REG_SOUND2CNT_H, 0x0400006C
	.equ REG_SOUND3CNT_H, 0x04000072
	.equ REG_SOUND3CNT_X, 0x04000074
	.equ REG_SOUND4CNT_L, 0x04000078
	.equ REG_SOUND4CNT_H, 0x0400007C
	.equ REG_FIFO_A,      0x040000A0
	.equ REG_FIFO_B,      0x040000A4
	.equ REG_IE,          0x04000200
	.equ REG_IF,          0x04000202
@ offsets from REG_SOUND1CNT_L (I/O base in r6 / r3 / r8)
	.equ IO_SOUND1CNT_L, 0x00
	.equ IO_SOUND3CNT_L, 0x10
	.equ IO_SOUNDCNT_L,  0x20
	.equ IO_SOUNDCNT_H,  0x22
	.equ IO_SOUNDCNT_X,  0x24
	.equ IO_SOUNDBIAS,   0x28
	.equ IO_WAVE_RAM,    0x30
	.equ IO_DMA1SAD,     0x5C
	.equ IO_DMA1DAD,     0x60
	.equ IO_DMA1CNT_H,   0x66
	.equ IO_DMA2SAD,     0x68
	.equ IO_DMA2DAD,     0x6C
	.equ IO_DMA2CNT_H,   0x72
	.equ IO_TM0CNT_L,    0xA0
	.equ IO_TM0CNT_H,    0xA2

@ ---- IWRAM state
	.equ sndTracks,     0x03002ACC   @ Track[14] (13 updated), 0x38 bytes each
	.equ sndQueueRead,  0x03002DDC   @ u8 byte offset into sndQueue
	.equ sndQueueWrite, 0x03002DDD
	.equ sndQueue,      0x03002DDE   @ u16[8]; 0 = empty slot
	.equ sndMixMode,    0x03002DEE   @ u8 0 = 2-voice ROM path, else 5-voice IWRAM mixer (E2)
	.equ sndMaster,     0x03002DF0   @ Master
	.equ sndSoundCntL,  0x03002DFC   @ u16 shadow of SOUNDCNT_L
	.equ sndVoices,     0x03002E0C   @ Voice[6] (0-4 mixed)
	.equ sndMixA,       0x03002E6C   @ 16 output bytes -> FIFO A (right)
	.equ sndMixB,       0x03002E7C   @ 16 output bytes -> FIFO B (left)
	.equ sndStage,      0x03002E8C   @ 5 x 16 resampled voice bytes
	.equ IW_sndMixIrq,  0x03003150   @ IWRAM copy of sndMixIrq
	.equ IW_sndMixFull, 0x03003750   @ IWRAM copy of sndMixFull

@ ---- ROM data outside the driver block
	.equ seqSongTable, 0x080A2998    @ u8 *[745]
	.equ instTable,    0x080C2884    @ Sample **[24] (20 used): 12-13 headers per instrument
	.equ waveTable,    0x0836723C    @ u8 *[24] wave patterns

@ ---- struct Track (0x38)
	.equ TRK_FLAGS,    0x00   @ bit0 active, bit1 muted by SE, bit7 paused (fade-out)
	.equ TRK_WAIT,     0x01
	.equ TRK_ENVWAIT,  0x02
	.equ TRK_LOOPCNT,  0x03
	.equ TRK_PTR,      0x04
	.equ TRK_LOOPPTR,  0x08
	.equ TRK_RETPTR,   0x0C
	.equ TRK_PATTERNS, 0x10
	.equ TRK_INST,     0x14   @ PCM: Sample *[12..13] (E1)
	.equ TRK_WAVE,     0x1C   @ PSG wave pattern (FC)
	.equ TRK_FREQ,     0x20
	.equ TRK_ENVREG,   0x22
	.equ TRK_DUTY,     0x24   @ PSG duty byte / PCM slide countdown
	.equ TRK_SWEEP,    0x25   @ PSG ch1 sweep / PCM effective volume
	.equ TRK_VOLUME,   0x26
	.equ TRK_DETUNE,   0x27
	.equ TRK_LEVEL,    0x28
	.equ TRK_LENGTH,   0x29
	.equ TRK_PANBITS,  0x2A   @ PSG NR51 bits / PCM volA (EA)
	.equ TRK_PANMASK,  0x2B   @ PSG NR51 mask / PCM volB (EA)
	.equ TRK_TRANSP,   0x2C
	.equ TRK_SLIDE,    0x2D   @ PCM: bit7 down, bits0-6 amount
	.equ TRK_SLIDEPER, 0x2E   @ always 1
	.equ TRK_TEMPOROW, 0x2F   @ EE
	.equ TRK_ENV,      0x30
	.equ TRK_ENVPOS,   0x34

@ ---- struct Voice (0x10)
	.equ VOI_MODE,  0x0   @ 0 x1, bit0 x2, bit1 x4, bit2 x8
	.equ VOI_MODE2, 0x1
	.equ VOI_VOLA,  0x2   @ FIFO A (right)
	.equ VOI_VOLB,  0x3   @ FIFO B (left)
	.equ VOI_CUR,   0x4
	.equ VOI_END,   0x8
	.equ VOI_LOOP,  0xC

@ ---- struct Master (sndMaster)
	.equ MST_VOLUME,    0x00
	.equ MST_STEP,      0x01
	.equ MST_OUTFRAMES, 0x02  @ u16 fade-out frames left
	.equ MST_OUTACC,    0x04
	.equ MST_OUTPERIOD, 0x06
	.equ MST_INACC,     0x08
	.equ MST_INPERIOD,  0x0A
	.equ MST_INFRAMES,  0x18  @ fade-in frames left (read as u8)
