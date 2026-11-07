@ bb_sound.inc -- symbols for the Brownie Brown sound driver (Magical Vacation, AMVJ)

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
	.equ REG_TM0CNT_H,    0x04000102
	.equ REG_TM1CNT_H,    0x04000106
	.equ REG_IE,          0x04000200
	.equ REG_IF,          0x04000202
@ offsets from REG_SOUND1CNT_L (r8 in the parser, r3 in sndInit)
	.equ IO_SOUND1CNT_L, 0x00
	.equ IO_SOUND1CNT_H, 0x02
	.equ IO_SOUND1CNT_X, 0x04
	.equ IO_SOUND2CNT_L, 0x08
	.equ IO_SOUND2CNT_H, 0x0C
	.equ IO_SOUND3CNT_L, 0x10
	.equ IO_SOUND3CNT_H, 0x12
	.equ IO_SOUND3CNT_X, 0x14
	.equ IO_SOUND4CNT_L, 0x18
	.equ IO_UNUSED_7A,   0x1A   @ driver writes 0x8000 here (SOUND4CNT_H is +0x1C)
	.equ IO_SOUNDCNT_L,  0x20
	.equ IO_SOUNDCNT_H,  0x22
	.equ IO_SOUNDCNT_X,  0x24
	.equ IO_WAVE_RAM,    0x30
	.equ IO_FIFO_A,      0x40
	.equ IO_FIFO_B,      0x44
	.equ IO_DMA1CNT_H,   0x66
	.equ IO_DMA2CNT_H,   0x72
	.equ IO_TM0CNT_L,    0xA0
	.equ IO_TM0CNT_H,    0xA2
	.equ IO_TM1CNT_L,    0xA4
	.equ IO_TM1CNT_H,    0xA6

@ ---- EWRAM state
	.equ sndTracks,     0x02000EF0   @ Track[12], 0x38 bytes each
	.equ sndQueueRead,  0x02001190   @ u8 byte offset into sndQueue
	.equ sndQueueWrite, 0x02001191
	.equ sndQueue,      0x02001192   @ u16[4] sound ids
	.equ sndStreamA,    0x0200119C   @ Stream (FIFO A)
	.equ sndStreamB,    0x020011AC   @ Stream (FIFO B)
	.equ sndSoundCntL,  0x020011BC   @ u16 shadow of SOUNDCNT_L (NR50/NR51)
	.equ sndMaster,     0x020011D0   @ Master

@ ---- ROM data outside the driver block
	.equ seqSongTable, 0x0805D2DC    @ u8 *[278] song headers
	.equ smpTable,     0x0806C988    @ Sample *[16]
	.equ waveTable,    0x08097174    @ u8 *[16] 16-byte wave patterns

@ ---- struct Track (0x38)
	.equ TRK_FLAGS,    0x00   @ bit0 active, bit1 muted by an SE track
	.equ TRK_WAIT,     0x01   @ frames until next event
	.equ TRK_ENVWAIT,  0x02   @ frames until next envelope step (0 = hold)
	.equ TRK_LOOPCNT,  0x03
	.equ TRK_PTR,      0x04
	.equ TRK_LOOPPTR,  0x08
	.equ TRK_RETPTR,   0x0C
	.equ TRK_PATTERNS, 0x10   @ u8 ** (song header word 3)
	.equ TRK_SMPSTART, 0x14   @ PCM: sample data start
	.equ TRK_SMPEND,   0x18   @ PCM: sample end
	.equ TRK_SMPLOOP,  0x1C   @ PCM: loop point / PSG wave: wave pattern pointer
	.equ TRK_FREQ,     0x20   @ u16 PSG freq value / PCM timer reload
	.equ TRK_ENVREG,   0x22   @ u16 value for CNT_H (duty | env << 8)
	.equ TRK_DUTY,     0x24   @ PSG: duty/length byte; PCM: slide countdown
	.equ TRK_SWEEP,    0x25   @ PSG ch1: sweep; PCM: effective volume
	.equ TRK_VOLUME,   0x26   @ F2
	.equ TRK_DETUNE,   0x27   @ F9
	.equ TRK_LEVEL,    0x28   @ envelope level
	.equ TRK_LENGTH,   0x29   @ current length (frames)
	.equ TRK_PANBITS,  0x2A
	.equ TRK_PANMASK,  0x2B
	.equ TRK_TRANSP,   0x2C   @ F3 (s8)
	.equ TRK_SLIDE,    0x2D   @ PCM slide: bit3 down, bits0-2 amount
	.equ TRK_SLIDEPER, 0x2E   @ PCM slide period
	.equ TRK_ENV,      0x30   @ envelope script start (F0)
	.equ TRK_ENVPOS,   0x34   @ envelope script position

@ ---- struct Stream (0x10)
	.equ STR_CUR, 0x0
	.equ STR_END, 0x4
	.equ STR_LOOP, 0x8   @ == END: one-shot
	.equ STR_VOL, 0xC

@ ---- struct Master (sndMaster)
	.equ MST_VOLUME, 0x0
	.equ MST_STEP,   0x1
	.equ MST_FRAMES, 0x2  @ u16 fade frames left (0 = no fade)
	.equ MST_ACC,    0x4  @ u16 8.8
	.equ MST_PERIOD, 0x8  @ u16 8.8

@ ---- struct Sample (ROM, smpTable)
	.equ SMP_START, 0x0   @ u8 * (data follows the 12-byte header)
	.equ SMP_END,   0x4
	.equ SMP_LOOP,  0x8   @ == END: one-shot
