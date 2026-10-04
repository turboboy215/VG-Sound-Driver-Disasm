@ Generated from the ROM by gen_data.py; names are assigned (the ROM has no symbols apart from the
@ song name strings, which are real ROM data).
	.syntax unified

	.set WW_DATA_FILE, 1
	.include "ww_sound.inc"
	.section .snd_rodata, "a", %progbits

	.global sndKeyFreqTable
sndKeyFreqTable:        @ u16[128]: note frequency in Hz, rounded (key 69 = 440 Hz). Default Synth.freqTable.
	.hword     8,     8,     9,    10,    10,    11,    12,    12   @ keys 0-7
	.hword    13,    14,    15,    15,    16,    17,    18,    19   @ keys 8-15
	.hword    21,    22,    23,    25,    26,    28,    29,    31   @ keys 16-23
	.hword    33,    35,    37,    39,    41,    44,    46,    49   @ keys 24-31
	.hword    52,    55,    58,    62,    65,    69,    73,    78   @ keys 32-39
	.hword    82,    87,    92,    98,   104,   110,   117,   123   @ keys 40-47
	.hword   131,   139,   147,   156,   165,   175,   185,   196   @ keys 48-55
	.hword   208,   220,   233,   247,   262,   277,   294,   311   @ keys 56-63
	.hword   330,   349,   370,   392,   415,   440,   466,   494   @ keys 64-71
	.hword   523,   554,   587,   622,   659,   698,   740,   784   @ keys 72-79
	.hword   831,   880,   932,   988,  1047,  1109,  1175,  1245   @ keys 80-87
	.hword  1319,  1397,  1480,  1568,  1661,  1760,  1865,  1976   @ keys 88-95
	.hword  2093,  2218,  2349,  2489,  2637,  2794,  2960,  3136   @ keys 96-103
	.hword  3322,  3520,  3729,  3951,  4186,  4435,  4699,  4978   @ keys 104-111
	.hword  5274,  5588,  5920,  6272,  6645,  7040,  7459,  7902   @ keys 112-119
	.hword  8372,  8870,  9397,  9956, 10548, 11175, 11840, 12544   @ keys 120-127
	.global sndSemitoneTable
sndSemitoneTable:       @ u32[14]: (2^(n/12) - 1) * 65536, n = 0..13 (pitch bend and fine tune interpolation)
	.word 0, 3913, 8015, 12399, 17033, 21949, 27147, 32658, 38482, 44682, 51226, 58177, 65536, 73301
	.global sndSineTable
sndSineTable:           @ s16[256]: 256*sin(2*pi*i/256)  (LFO and filter sweep)
	.hword 0, 6, 12, 18, 25, 31, 37, 43
	.hword 50, 56, 62, 68, 74, 80, 86, 92
	.hword 98, 103, 109, 115, 120, 126, 131, 137
	.hword 142, 147, 152, 157, 162, 167, 172, 176
	.hword 181, 185, 190, 194, 198, 202, 206, 209
	.hword 213, 216, 220, 223, 226, 229, 231, 234
	.hword 236, 239, 241, 243, 245, 247, 248, 250
	.hword 251, 252, 253, 254, 255, 255, 256, 256
	.hword 256, 256, 256, 255, 255, 254, 253, 252
	.hword 251, 250, 248, 247, 245, 243, 241, 239
	.hword 236, 234, 231, 229, 226, 223, 220, 216
	.hword 213, 209, 206, 202, 198, 194, 190, 185
	.hword 181, 176, 172, 167, 162, 157, 152, 147
	.hword 142, 137, 131, 126, 120, 115, 109, 103
	.hword 98, 92, 86, 80, 74, 68, 62, 56
	.hword 50, 43, 37, 31, 25, 18, 12, 6
	.hword 0, -6, -12, -18, -25, -31, -37, -43
	.hword -50, -56, -62, -68, -74, -80, -86, -92
	.hword -98, -103, -109, -115, -120, -126, -131, -137
	.hword -142, -147, -152, -157, -162, -167, -172, -176
	.hword -181, -185, -190, -194, -198, -202, -206, -209
	.hword -213, -216, -220, -223, -226, -229, -231, -234
	.hword -236, -239, -241, -243, -245, -247, -248, -250
	.hword -251, -252, -253, -254, -255, -255, -256, -256
	.hword -256, -256, -256, -255, -255, -254, -253, -252
	.hword -251, -250, -248, -247, -245, -243, -241, -239
	.hword -236, -234, -231, -229, -226, -223, -220, -216
	.hword -213, -209, -206, -202, -198, -194, -190, -185
	.hword -181, -176, -172, -167, -162, -157, -152, -147
	.hword -142, -137, -131, -126, -120, -115, -109, -103
	.hword -98, -92, -86, -80, -74, -68, -62, -56
	.hword -50, -43, -37, -31, -25, -18, -12, -6
	.global sndCosTable
sndCosTable:            @ s16[256]: 256*cos(2*pi*i/256); not referenced by the driver
	.hword 256, 256, 256, 255, 255, 254, 253, 252
	.hword 251, 250, 248, 247, 245, 243, 241, 239
	.hword 236, 234, 231, 229, 226, 223, 220, 216
	.hword 213, 209, 206, 202, 198, 194, 190, 185
	.hword 181, 176, 172, 167, 162, 157, 152, 147
	.hword 142, 137, 131, 126, 120, 115, 109, 103
	.hword 98, 92, 86, 80, 74, 68, 62, 56
	.hword 50, 43, 37, 31, 25, 18, 12, 6
	.hword 0, -6, -12, -18, -25, -31, -37, -43
	.hword -50, -56, -62, -68, -74, -80, -86, -92
	.hword -98, -103, -109, -115, -120, -126, -131, -137
	.hword -142, -147, -152, -157, -162, -167, -172, -176
	.hword -181, -185, -190, -194, -198, -202, -206, -209
	.hword -213, -216, -220, -223, -226, -229, -231, -234
	.hword -236, -239, -241, -243, -245, -247, -248, -250
	.hword -251, -252, -253, -254, -255, -255, -256, -256
	.hword -256, -256, -256, -255, -255, -254, -253, -252
	.hword -251, -250, -248, -247, -245, -243, -241, -239
	.hword -236, -234, -231, -229, -226, -223, -220, -216
	.hword -213, -209, -206, -202, -198, -194, -190, -185
	.hword -181, -176, -172, -167, -162, -157, -152, -147
	.hword -142, -137, -131, -126, -120, -115, -109, -103
	.hword -98, -92, -86, -80, -74, -68, -62, -56
	.hword -50, -43, -37, -31, -25, -18, -12, -6
	.hword 0, 6, 12, 18, 25, 31, 37, 43
	.hword 50, 56, 62, 68, 74, 80, 86, 92
	.hword 98, 103, 109, 115, 120, 126, 131, 137
	.hword 142, 147, 152, 157, 162, 167, 172, 176
	.hword 181, 185, 190, 194, 198, 202, 206, 209
	.hword 213, 216, 220, 223, 226, 229, 231, 234
	.hword 236, 239, 241, 243, 245, 247, 248, 250
	.hword 251, 252, 253, 254, 255, 255, 256, 256
	.global psgWaveVolTable
psgWaveVolTable:        @ u16[4]: SOUND3CNT_H volume codes for PSG volume/4 = 0..3 (25%, 50%, 75%, 100%)
	.hword 0x6000, 0x4000, 0x8000, 0x2000
	.global psgRegA
psgRegA:                @ per PSG channel: register that takes length/duty/envelope
	.word REG_SOUND1CNT_H, REG_SOUND2CNT_L, REG_SOUND3CNT_H, REG_SOUND4CNT_L
	.global psgRegB
psgRegB:                @ per PSG channel: frequency / trigger register
	.word REG_SOUND1CNT_X, REG_SOUND2CNT_H, REG_SOUND3CNT_X, REG_SOUND4CNT_H
	.global psgNoiseTable
psgNoiseTable:          @ u8[60]: SOUND4CNT_H low byte for keys 21..80 (clamped)
	.byte 0xD7, 0xD6, 0xD5, 0xD4, 0xC7, 0xC6, 0xC5, 0xC4, 0xB7, 0xB6, 0xB5, 0xB4
	.byte 0xA7, 0xA6, 0xA5, 0xA4, 0x97, 0x96, 0x95, 0x94, 0x87, 0x86, 0x85, 0x84
	.byte 0x77, 0x76, 0x75, 0x74, 0x67, 0x66, 0x65, 0x64, 0x57, 0x56, 0x55, 0x54
	.byte 0x47, 0x46, 0x45, 0x44, 0x37, 0x36, 0x35, 0x34, 0x27, 0x26, 0x25, 0x24
	.byte 0x17, 0x16, 0x15, 0x14, 0x07, 0x06, 0x05, 0x04, 0x03, 0x02, 0x01, 0x00
	.global seqLoopStartMarker
seqLoopStartMarker:     @ marker meta-event text that sets the loop start
	.asciz "["
	.balign 4
	.global seqLoopEndMarker
seqLoopEndMarker:       @ marker text that jumps back to the loop start
	.asciz "]"
	.balign 4
