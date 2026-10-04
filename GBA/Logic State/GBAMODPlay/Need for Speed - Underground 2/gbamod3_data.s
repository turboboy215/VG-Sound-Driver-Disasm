@ ============================================================================
@ gbamod3_data.s -- GBAModPlay v3 sound data of Need for Speed: Underground 2 (U)
@ ROM range 0x08000210-0x080FBE74, rebuilt byte for byte by gbamod3.mk:
@   0x08000210  SFX bank   (30 effects, PCM in gbamod3_sfx.bin)
@   0x0803A2C8  9 modules  ("GBAMOD30", RLE-packed patterns written with the macros below)
@   0x080431FC  sample bank (256 header slots, 90 used; PCM in gbamod3_samples.bin)
@ The game passes the two banks to gmpInit and module addresses to gmpRequestSong.
@
@ Pattern macros.  Each channel of a pattern is a block
@     { u32 notesLen, volOfs, fxOfs, fxEnd, blockLen; notes; 0; vols; 0; fx; 0; "PAD" filler }
@ (all offsets from the start of the notes stream).  A stream is a list of runs:
@     N  rows, note, ins     notes: value note << 7 | ins; note 0x1FF (---) = no note
@     V  rows, vol           volume column (0 = none, else volume + 1)
@     X  rows, cmd, par      effect
@ Notes are XM numbers, 1 = C-0, 49 = C-4; the instrument is a sample-bank slot + 1.
@ ============================================================================
	.syntax unified
	.macro N rows, note, ins
	.byte \rows, ((\note << 7) | \ins) >> 8, ((\note << 7) | \ins) & 0xFF
	.endm
	.macro V rows, vol
	.byte \rows, \vol
	.endm
	.macro X rows, cmd, par
	.byte \rows, \cmd, \par
	.endm
	.equ	NONE, 0x1FF

	.equ	C_0, 1
	.equ	C_1, 13
	.equ	C_2, 25
	.equ	C_3, 37
	.equ	C_4, 49
	.equ	C_5, 61
	.equ	C_6, 73
	.equ	C_7, 85
	.equ	C_8, 97
	.equ	C_9, 109
	.equ	Cs0, 2
	.equ	Cs1, 14
	.equ	Cs2, 26
	.equ	Cs3, 38
	.equ	Cs4, 50
	.equ	Cs5, 62
	.equ	Cs6, 74
	.equ	Cs7, 86
	.equ	Cs8, 98
	.equ	Cs9, 110
	.equ	D_0, 3
	.equ	D_1, 15
	.equ	D_2, 27
	.equ	D_3, 39
	.equ	D_4, 51
	.equ	D_5, 63
	.equ	D_6, 75
	.equ	D_7, 87
	.equ	D_8, 99
	.equ	D_9, 111
	.equ	Ds0, 4
	.equ	Ds1, 16
	.equ	Ds2, 28
	.equ	Ds3, 40
	.equ	Ds4, 52
	.equ	Ds5, 64
	.equ	Ds6, 76
	.equ	Ds7, 88
	.equ	Ds8, 100
	.equ	Ds9, 112
	.equ	E_0, 5
	.equ	E_1, 17
	.equ	E_2, 29
	.equ	E_3, 41
	.equ	E_4, 53
	.equ	E_5, 65
	.equ	E_6, 77
	.equ	E_7, 89
	.equ	E_8, 101
	.equ	E_9, 113
	.equ	F_0, 6
	.equ	F_1, 18
	.equ	F_2, 30
	.equ	F_3, 42
	.equ	F_4, 54
	.equ	F_5, 66
	.equ	F_6, 78
	.equ	F_7, 90
	.equ	F_8, 102
	.equ	F_9, 114
	.equ	Fs0, 7
	.equ	Fs1, 19
	.equ	Fs2, 31
	.equ	Fs3, 43
	.equ	Fs4, 55
	.equ	Fs5, 67
	.equ	Fs6, 79
	.equ	Fs7, 91
	.equ	Fs8, 103
	.equ	Fs9, 115
	.equ	G_0, 8
	.equ	G_1, 20
	.equ	G_2, 32
	.equ	G_3, 44
	.equ	G_4, 56
	.equ	G_5, 68
	.equ	G_6, 80
	.equ	G_7, 92
	.equ	G_8, 104
	.equ	G_9, 116
	.equ	Gs0, 9
	.equ	Gs1, 21
	.equ	Gs2, 33
	.equ	Gs3, 45
	.equ	Gs4, 57
	.equ	Gs5, 69
	.equ	Gs6, 81
	.equ	Gs7, 93
	.equ	Gs8, 105
	.equ	Gs9, 117
	.equ	A_0, 10
	.equ	A_1, 22
	.equ	A_2, 34
	.equ	A_3, 46
	.equ	A_4, 58
	.equ	A_5, 70
	.equ	A_6, 82
	.equ	A_7, 94
	.equ	A_8, 106
	.equ	A_9, 118
	.equ	As0, 11
	.equ	As1, 23
	.equ	As2, 35
	.equ	As3, 47
	.equ	As4, 59
	.equ	As5, 71
	.equ	As6, 83
	.equ	As7, 95
	.equ	As8, 107
	.equ	As9, 119
	.equ	B_0, 12
	.equ	B_1, 24
	.equ	B_2, 36
	.equ	B_3, 48
	.equ	B_4, 60
	.equ	B_5, 72
	.equ	B_6, 84
	.equ	B_7, 96
	.equ	B_8, 108
	.equ	B_9, 120

	.section .gmp3_data, "a", %progbits

@ ==== SFX bank (gmpLoadSfxBank) =============================================
@ entry: {u32 offset, u32 length, u16 finetune, u16 volume (unused), u16 loopStart,
@         u16 loopLen, u32 rate Hz, u8 compressed, 3 pad}
	.global gmp3SfxBank
gmp3SfxBank:                                          @ 08000210
	.word	30
	.macro SFX off, len, fine, vol, ls, ll, rate, comp, p0=0, p1=0, p2=0
	.word \off, \len
	.hword \fine, \vol, \ls, \ll
	.word \rate
	.byte \comp, \p0, \p1, \p2
	.endm
	SFX	0x00000, 0x0001, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 0
	SFX	0x00001, 0x223E, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 1
	SFX	0x0223F, 0x1A2B, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 2
	SFX	0x03C6A, 0x2B70, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 3
	SFX	0x067DA, 0x29E0, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 4
	SFX	0x091BA, 0x1648, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 5
	SFX	0x0A802, 0x1990, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 6
	SFX	0x0C192, 0x15EF, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 7
	SFX	0x0D781, 0x2A40, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 8
	SFX	0x101C1, 0x1012, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 9
	SFX	0x111D3, 0x3A40, 0, 64, 0x0000, 0x3A3F, 10512, 0   @ sfx 10
	SFX	0x14C13, 0x2460, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 11
	SFX	0x17073, 0x22C0, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 12
	SFX	0x19333, 0x0568, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 13
	SFX	0x1989B, 0x0F2B, 0, 64, 0x0000, 0x0000, 15282, 0   @ sfx 14
	SFX	0x1A7C6, 0x1612, 0, 64, 0x0000, 0x0000, 15282, 0   @ sfx 15
	SFX	0x1BDD8, 0x45C6, 0, 64, 0x1207, 0x33BF, 10512, 0   @ sfx 16
	SFX	0x2039E, 0x0001, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 17
	SFX	0x2039F, 0x0001, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 18
	SFX	0x203A0, 0x0001, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 19
	SFX	0x203A1, 0x2848, 0, 64, 0x0000, 0x2848, 7000, 0   @ sfx 20
	SFX	0x22BE9, 0x2CDF, 0, 64, 0x0000, 0x2CDF, 8000, 0   @ sfx 21
	SFX	0x258C8, 0x1EB0, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 22
	SFX	0x27778, 0x1D5A, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 23
	SFX	0x294D2, 0x2560, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 24
	SFX	0x2BA32, 0x2570, 0, 64, 0x0000, 0x0000, 10512, 0   @ sfx 25
	SFX	0x2DFA2, 0x44FC, 0, 64, 0x1C7D, 0x287F, 10512, 0   @ sfx 26
	SFX	0x3249E, 0x281B, 0, 64, 0x0000, 0x281B, 7000, 0   @ sfx 27
	SFX	0x34CB9, 0x22AA, 0, 64, 0x0000, 0x22AA, 8000, 0   @ sfx 28
	SFX	0x36F63, 0x2E80, 0, 64, 0x0000, 0x2E80, 10512, 0   @ sfx 29
gmp3SfxData:
	.incbin	"gbamod3_sfx.bin"
	.byte	0x00                                                 @ 0803A2C7

@ ==== module 0 @ 0803A2C8 ==================================================
	.global gmp3Module0
gmp3Module0:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	2, 0, 0, 8   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	7, 64, 0, 125, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x05, 0x06, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m0_pat (256 words)
	.word	m0p0 - m0_pat
	.word	m0p1 - m0_pat
	.word	m0p2 - m0_pat
	.word	m0p3 - m0_pat
	.word	m0p4 - m0_pat
	.word	m0p5 - m0_pat
	.word	m0p6 - m0_pat
	.space	996
	.word	0
m0_pat:
m0p0:
m0p0c0:	.word	m0p0c0v-m0p0c0n, m0p0c0v-m0p0c0n, m0p0c0x-m0p0c0n, m0p0c0z-m0p0c0n, m0p0c0e-m0p0c0n
m0p0c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p0c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m0p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p0c0z:
m0p0c0e:
m0p0c1:	.word	m0p0c1v-m0p0c1n, m0p0c1v-m0p0c1n, m0p0c1x-m0p0c1n, m0p0c1z-m0p0c1n, m0p0c1e-m0p0c1n
m0p0c1n:
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	.byte	0
m0p0c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m0p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p0c1z:
	.ascii	"PA"
m0p0c1e:
m0p1:
m0p1c0:	.word	m0p1c0v-m0p1c0n, m0p1c0v-m0p1c0n, m0p1c0x-m0p1c0n, m0p1c0z-m0p1c0n, m0p1c0e-m0p1c0n
m0p1c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p1c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m0p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p1c0z:
m0p1c0e:
m0p1c1:	.word	m0p1c1v-m0p1c1n, m0p1c1v-m0p1c1n, m0p1c1x-m0p1c1n, m0p1c1z-m0p1c1n, m0p1c1e-m0p1c1n
m0p1c1n:
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	.byte	0
m0p1c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m0p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p1c1z:
	.ascii	"PA"
m0p1c1e:
m0p2:
m0p2c0:	.word	m0p2c0v-m0p2c0n, m0p2c0v-m0p2c0n, m0p2c0x-m0p2c0n, m0p2c0z-m0p2c0n, m0p2c0e-m0p2c0n
m0p2c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p2c0v:
	V	64, 0
	.byte	0
m0p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p2c0z:
m0p2c0e:
m0p2c1:	.word	m0p2c1v-m0p2c1n, m0p2c1v-m0p2c1n, m0p2c1x-m0p2c1n, m0p2c1z-m0p2c1n, m0p2c1e-m0p2c1n
m0p2c1n:
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	.byte	0
m0p2c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m0p2c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p2c1z:
	.ascii	"PA"
m0p2c1e:
m0p3:
m0p3c0:	.word	m0p3c0v-m0p3c0n, m0p3c0v-m0p3c0n, m0p3c0x-m0p3c0n, m0p3c0z-m0p3c0n, m0p3c0e-m0p3c0n
m0p3c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	2, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, C_4, 1
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 2
	N	1, C_4, 3
	N	1, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	2, C_4, 2
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p3c0v:
	V	64, 0
	.byte	0
m0p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p3c0z:
	.ascii	"PA"
m0p3c0e:
m0p3c1:	.word	m0p3c1v-m0p3c1n, m0p3c1v-m0p3c1n, m0p3c1x-m0p3c1n, m0p3c1z-m0p3c1n, m0p3c1e-m0p3c1n
m0p3c1n:
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	N	1, C_4, 4
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 7
	N	3, NONE, 0
	.byte	0
m0p3c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m0p3c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p3c1z:
	.ascii	"PA"
m0p3c1e:
m0p4:
m0p4c0:	.word	m0p4c0v-m0p4c0n, m0p4c0v-m0p4c0n, m0p4c0x-m0p4c0n, m0p4c0z-m0p4c0n, m0p4c0e-m0p4c0n
m0p4c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p4c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m0p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p4c0z:
m0p4c0e:
m0p4c1:	.word	m0p4c1v-m0p4c1n, m0p4c1v-m0p4c1n, m0p4c1x-m0p4c1n, m0p4c1z-m0p4c1n, m0p4c1e-m0p4c1n
m0p4c1n:
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	19, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	19, NONE, 0
	.byte	0
m0p4c1v:
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	19, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	19, 0
	.byte	0
m0p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p4c1z:
	.ascii	"PA"
m0p4c1e:
m0p5:
m0p5c0:	.word	m0p5c0v-m0p5c0n, m0p5c0v-m0p5c0n, m0p5c0x-m0p5c0n, m0p5c0z-m0p5c0n, m0p5c0e-m0p5c0n
m0p5c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p5c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m0p5c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p5c0z:
m0p5c0e:
m0p5c1:	.word	m0p5c1v-m0p5c1n, m0p5c1v-m0p5c1n, m0p5c1x-m0p5c1n, m0p5c1z-m0p5c1n, m0p5c1e-m0p5c1n
m0p5c1n:
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	.byte	0
m0p5c1v:
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	.byte	0
m0p5c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p5c1z:
	.ascii	"PA"
m0p5c1e:
m0p6:
m0p6c0:	.word	m0p6c0v-m0p6c0n, m0p6c0v-m0p6c0n, m0p6c0x-m0p6c0n, m0p6c0z-m0p6c0n, m0p6c0e-m0p6c0n
m0p6c0n:
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 1
	N	1, NONE, 0
	N	1, C_4, 3
	N	1, NONE, 0
	.byte	0
m0p6c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	1, 0
	V	1, 19
	V	1, 0
	V	1, 17
	V	1, 0
	V	1, 15
	V	1, 0
	V	1, 11
	V	1, 0
	V	1, 9
	V	3, 0
	.byte	0
m0p6c0x:
	X	64, 0x0, 0x00
	.byte	0
m0p6c0z:
m0p6c0e:
m0p6c1:	.word	m0p6c1v-m0p6c1n, m0p6c1v-m0p6c1n, m0p6c1x-m0p6c1n, m0p6c1z-m0p6c1n, m0p6c1e-m0p6c1n
m0p6c1n:
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_4, 6
	N	3, NONE, 0
	N	1, C_4, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	N	1, C_3, 6
	N	3, NONE, 0
	N	1, C_3, 5
	N	3, NONE, 0
	.byte	0
m0p6c1v:
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 12
	V	3, 0
	V	1, 6
	V	3, 0
	.byte	0
m0p6c1x:
	X	64, 0x0, 0x00
	.byte	0
m0p6c1z:
	.ascii	"PA"
m0p6c1e:

@ ==== module 1 @ 0803B524 ==================================================
	.global gmp3Module1
gmp3Module1:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	2, 0, 0, 5   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	5, 64, 0, 107, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x04, 0x00, 0x01, 0x02, 0x03, 0xFF, 0x05, 0x06, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m1_pat (256 words)
	.word	m1p0 - m1_pat
	.word	m1p1 - m1_pat
	.word	m1p2 - m1_pat
	.word	m1p3 - m1_pat
	.word	m1p4 - m1_pat
	.space	1004
	.word	0
m1_pat:
m1p0:
m1p0c0:	.word	m1p0c0v-m1p0c0n, m1p0c0v-m1p0c0n, m1p0c0x-m1p0c0n, m1p0c0z-m1p0c0n, m1p0c0e-m1p0c0n
m1p0c0n:
	N	1, C_4, 8
	N	15, NONE, 0
	N	1, C_4, 8
	N	13, NONE, 0
	N	1, C_4, 9
	N	1, NONE, 0
	N	1, C_4, 8
	N	15, NONE, 0
	N	1, C_4, 8
	N	13, NONE, 0
	N	1, C_4, 9
	N	1, NONE, 0
	.byte	0
m1p0c0v:
	V	64, 0
	.byte	0
m1p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m1p0c0z:
m1p0c0e:
m1p0c1:	.word	m1p0c1v-m1p0c1n, m1p0c1v-m1p0c1n, m1p0c1x-m1p0c1n, m1p0c1z-m1p0c1n, m1p0c1e-m1p0c1n
m1p0c1n:
	N	2, NONE, 0
	N	1, C_4, 8
	N	15, NONE, 0
	N	1, C_4, 8
	N	13, NONE, 0
	N	1, C_4, 9
	N	1, NONE, 0
	N	1, C_4, 8
	N	15, NONE, 0
	N	1, C_4, 8
	N	13, NONE, 0
	.byte	0
m1p0c1v:
	V	2, 0
	V	1, 17
	V	15, 0
	V	1, 17
	V	13, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	15, 0
	V	1, 17
	V	13, 0
	.byte	0
m1p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m1p0c1z:
	.ascii	"PAD"
m1p0c1e:
m1p1:
m1p1c0:	.word	m1p1c0v-m1p1c0n, m1p1c0v-m1p1c0n, m1p1c0x-m1p1c0n, m1p1c0z-m1p1c0n, m1p1c0e-m1p1c0n
m1p1c0n:
	N	1, C_4, 10
	N	15, NONE, 0
	N	1, C_4, 10
	N	13, NONE, 0
	N	1, C_4, 11
	N	1, NONE, 0
	N	1, C_4, 10
	N	15, NONE, 0
	N	1, C_4, 10
	N	13, NONE, 0
	N	1, C_4, 11
	N	1, NONE, 0
	.byte	0
m1p1c0v:
	V	64, 0
	.byte	0
m1p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m1p1c0z:
m1p1c0e:
m1p1c1:	.word	m1p1c1v-m1p1c1n, m1p1c1v-m1p1c1n, m1p1c1x-m1p1c1n, m1p1c1z-m1p1c1n, m1p1c1e-m1p1c1n
m1p1c1n:
	N	64, NONE, 0
	.byte	0
m1p1c1v:
	V	64, 0
	.byte	0
m1p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m1p1c1z:
	.ascii	"P"
m1p1c1e:
m1p2:
m1p2c0:	.word	m1p2c0v-m1p2c0n, m1p2c0v-m1p2c0n, m1p2c0x-m1p2c0n, m1p2c0z-m1p2c0n, m1p2c0e-m1p2c0n
m1p2c0n:
	N	1, C_4, 8
	N	7, NONE, 0
	N	1, C_4, 14
	N	7, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	.byte	0
m1p2c0v:
	V	64, 0
	.byte	0
m1p2c0x:
	X	13, 0xA, 0x01
	X	51, 0x0, 0x00
	.byte	0
m1p2c0z:
	.ascii	"PAD"
m1p2c0e:
m1p2c1:	.word	m1p2c1v-m1p2c1n, m1p2c1v-m1p2c1n, m1p2c1x-m1p2c1n, m1p2c1z-m1p2c1n, m1p2c1e-m1p2c1n
m1p2c1n:
	N	1, C_3, 12
	N	17, NONE, 0
	N	1, C_4, 13
	N	13, NONE, 0
	N	1, C_3, 12
	N	17, NONE, 0
	N	1, C_4, 13
	N	13, NONE, 0
	.byte	0
m1p2c1v:
	V	64, 0
	.byte	0
m1p2c1x:
	X	16, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	17, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	.byte	0
m1p2c1z:
m1p2c1e:
m1p3:
m1p3c0:	.word	m1p3c0v-m1p3c0n, m1p3c0v-m1p3c0n, m1p3c0x-m1p3c0n, m1p3c0z-m1p3c0n, m1p3c0e-m1p3c0n
m1p3c0n:
	N	1, C_4, 10
	N	15, NONE, 0
	N	1, C_4, 10
	N	13, NONE, 0
	N	1, C_4, 11
	N	1, NONE, 0
	N	1, C_4, 10
	N	15, NONE, 0
	N	1, C_4, 10
	N	13, NONE, 0
	N	1, C_4, 11
	N	1, NONE, 0
	.byte	0
m1p3c0v:
	V	64, 0
	.byte	0
m1p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m1p3c0z:
m1p3c0e:
m1p3c1:	.word	m1p3c1v-m1p3c1n, m1p3c1v-m1p3c1n, m1p3c1x-m1p3c1n, m1p3c1z-m1p3c1n, m1p3c1e-m1p3c1n
m1p3c1n:
	N	1, C_3, 12
	N	17, NONE, 0
	N	1, C_4, 13
	N	13, NONE, 0
	N	1, C_3, 12
	N	17, NONE, 0
	N	1, C_4, 13
	N	13, NONE, 0
	.byte	0
m1p3c1v:
	V	64, 0
	.byte	0
m1p3c1x:
	X	16, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	17, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	X	1, 0xA, 0x01
	X	1, 0x0, 0x00
	.byte	0
m1p3c1z:
m1p3c1e:
m1p4:
m1p4c0:	.word	m1p4c0v-m1p4c0n, m1p4c0v-m1p4c0n, m1p4c0x-m1p4c0n, m1p4c0z-m1p4c0n, m1p4c0e-m1p4c0n
m1p4c0n:
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	11, NONE, 0
	N	4, C_4, 14
	.byte	0
m1p4c0v:
	V	64, 0
	.byte	0
m1p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m1p4c0z:
	.ascii	"P"
m1p4c0e:
m1p4c1:	.word	m1p4c1v-m1p4c1n, m1p4c1v-m1p4c1n, m1p4c1x-m1p4c1n, m1p4c1z-m1p4c1n, m1p4c1e-m1p4c1n
m1p4c1n:
	N	2, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	15, NONE, 0
	N	1, C_4, 14
	N	11, NONE, 0
	N	2, C_4, 14
	.byte	0
m1p4c1v:
	V	2, 0
	V	1, 17
	V	15, 0
	V	1, 17
	V	15, 0
	V	1, 17
	V	15, 0
	V	1, 17
	V	11, 0
	V	2, 17
	.byte	0
m1p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m1p4c1z:
m1p4c1e:

@ ==== module 2 @ 0803BE94 ==================================================
	.global gmp3Module2
gmp3Module2:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	1, 0, 0, 10   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x0F, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	5, 64, 0, 160, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x01, 0x02, 0x02, 0x00, 0x01, 0x03, 0x04, 0x03, 0x04, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m2_pat (256 words)
	.word	m2p0 - m2_pat
	.word	m2p1 - m2_pat
	.word	m2p2 - m2_pat
	.word	m2p3 - m2_pat
	.word	m2p4 - m2_pat
	.space	1004
	.word	0
m2_pat:
m2p0:
m2p0c0:	.word	m2p0c0v-m2p0c0n, m2p0c0v-m2p0c0n, m2p0c0x-m2p0c0n, m2p0c0z-m2p0c0n, m2p0c0e-m2p0c0n
m2p0c0n:
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 16
	N	7, NONE, 0
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 17
	N	7, NONE, 0
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 16
	N	7, NONE, 0
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 17
	N	7, NONE, 0
	.byte	0
m2p0c0v:
	V	64, 0
	.byte	0
m2p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m2p0c0z:
m2p0c0e:
m2p1:
m2p1c0:	.word	m2p1c0v-m2p1c0n, m2p1c0v-m2p1c0n, m2p1c0x-m2p1c0n, m2p1c0z-m2p1c0n, m2p1c0e-m2p1c0n
m2p1c0n:
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 16
	N	7, NONE, 0
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 17
	N	7, NONE, 0
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 16
	N	7, NONE, 0
	N	1, C_4, 15
	N	7, NONE, 0
	N	1, C_4, 18
	N	7, NONE, 0
	.byte	0
m2p1c0v:
	V	64, 0
	.byte	0
m2p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m2p1c0z:
m2p1c0e:
m2p2:
m2p2c0:	.word	m2p2c0v-m2p2c0n, m2p2c0v-m2p2c0n, m2p2c0x-m2p2c0n, m2p2c0z-m2p2c0n, m2p2c0e-m2p2c0n
m2p2c0n:
	N	1, C_4, 19
	N	21, NONE, 0
	N	1, C_4, 20
	N	8, NONE, 0
	N	2, C_4, 19
	N	21, NONE, 0
	N	1, C_4, 21
	N	8, NONE, 0
	N	1, C_4, 19
	.byte	0
m2p2c0v:
	V	31, 0
	V	1, 25
	V	31, 0
	V	1, 25
	.byte	0
m2p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m2p2c0z:
	.ascii	"PAD"
m2p2c0e:
m2p3:
m2p3c0:	.word	m2p3c0v-m2p3c0n, m2p3c0v-m2p3c0n, m2p3c0x-m2p3c0n, m2p3c0z-m2p3c0n, m2p3c0e-m2p3c0n
m2p3c0n:
	N	1, C_4, 22
	N	31, NONE, 0
	N	1, C_4, 22
	N	31, NONE, 0
	.byte	0
m2p3c0v:
	V	64, 0
	.byte	0
m2p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m2p3c0z:
m2p3c0e:
m2p4:
m2p4c0:	.word	m2p4c0v-m2p4c0n, m2p4c0v-m2p4c0n, m2p4c0x-m2p4c0n, m2p4c0z-m2p4c0n, m2p4c0e-m2p4c0n
m2p4c0n:
	N	1, C_4, 22
	N	31, NONE, 0
	N	1, C_4, 22
	N	23, NONE, 0
	N	1, C_4, 23
	N	7, NONE, 0
	.byte	0
m2p4c0v:
	V	64, 0
	.byte	0
m2p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m2p4c0z:
	.ascii	"PA"
m2p4c0e:

@ ==== module 3 @ 0803C614 ==================================================
	.global gmp3Module3
gmp3Module3:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	2, 0, 0, 12   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x18, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	8, 64, 0, 125, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x01, 0x01, 0x03, 0x04, 0x04, 0x01, 0x01, 0x04, 0x06, 0x07, 0x00, 0x02, 0xFF, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m3_pat (256 words)
	.word	m3p0 - m3_pat
	.word	m3p1 - m3_pat
	.word	m3p2 - m3_pat
	.word	m3p3 - m3_pat
	.word	m3p4 - m3_pat
	.word	m3p5 - m3_pat
	.word	m3p6 - m3_pat
	.word	m3p7 - m3_pat
	.space	992
	.word	0
m3_pat:
m3p0:
m3p0c0:	.word	m3p0c0v-m3p0c0n, m3p0c0v-m3p0c0n, m3p0c0x-m3p0c0n, m3p0c0z-m3p0c0n, m3p0c0e-m3p0c0n
m3p0c0n:
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	.byte	0
m3p0c0v:
	V	64, 0
	.byte	0
m3p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p0c0z:
	.ascii	"PAD"
m3p0c0e:
m3p0c1:	.word	m3p0c1v-m3p0c1n, m3p0c1v-m3p0c1n, m3p0c1x-m3p0c1n, m3p0c1z-m3p0c1n, m3p0c1e-m3p0c1n
m3p0c1n:
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	.byte	0
m3p0c1v:
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	.byte	0
m3p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p0c1z:
	.ascii	"PA"
m3p0c1e:
m3p1:
m3p1c0:	.word	m3p1c0v-m3p1c0n, m3p1c0v-m3p1c0n, m3p1c0x-m3p1c0n, m3p1c0z-m3p1c0n, m3p1c0e-m3p1c0n
m3p1c0n:
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	1, NONE, 0
	N	3, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	1, NONE, 0
	N	3, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 25
	.byte	0
m3p1c0v:
	V	64, 0
	.byte	0
m3p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p1c0z:
	.ascii	"PAD"
m3p1c0e:
m3p1c1:	.word	m3p1c1v-m3p1c1n, m3p1c1v-m3p1c1n, m3p1c1x-m3p1c1n, m3p1c1z-m3p1c1n, m3p1c1e-m3p1c1n
m3p1c1n:
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 36
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 36
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	.byte	0
m3p1c1v:
	V	64, 0
	.byte	0
m3p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p1c1z:
m3p1c1e:
m3p2:
m3p2c0:	.word	m3p2c0v-m3p2c0n, m3p2c0v-m3p2c0n, m3p2c0x-m3p2c0n, m3p2c0z-m3p2c0n, m3p2c0e-m3p2c0n
m3p2c0n:
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 25
	N	1, C_4, 24
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	3, C_4, 25
	N	1, NONE, 0
	N	2, C_4, 25
	.byte	0
m3p2c0v:
	V	64, 0
	.byte	0
m3p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p2c0z:
	.ascii	"PAD"
m3p2c0e:
m3p2c1:	.word	m3p2c1v-m3p2c1n, m3p2c1v-m3p2c1n, m3p2c1x-m3p2c1n, m3p2c1z-m3p2c1n, m3p2c1e-m3p2c1n
m3p2c1n:
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	.byte	0
m3p2c1v:
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	.byte	0
m3p2c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p2c1z:
	.ascii	"PA"
m3p2c1e:
m3p3:
m3p3c0:	.word	m3p3c0v-m3p3c0n, m3p3c0v-m3p3c0n, m3p3c0x-m3p3c0n, m3p3c0z-m3p3c0n, m3p3c0e-m3p3c0n
m3p3c0n:
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 24
	N	3, NONE, 0
	N	1, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 26
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 25
	N	1, C_4, 24
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 24
	N	1, C_4, 26
	N	1, NONE, 0
	N	3, C_4, 25
	N	1, NONE, 0
	N	2, C_4, 25
	.byte	0
m3p3c0v:
	V	64, 0
	.byte	0
m3p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p3c0z:
	.ascii	"PAD"
m3p3c0e:
m3p3c1:	.word	m3p3c1v-m3p3c1n, m3p3c1v-m3p3c1n, m3p3c1x-m3p3c1n, m3p3c1z-m3p3c1n, m3p3c1e-m3p3c1n
m3p3c1n:
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 36
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 36
	N	3, NONE, 0
	N	1, C_4, 37
	N	3, NONE, 0
	N	1, C_4, 38
	N	3, NONE, 0
	.byte	0
m3p3c1v:
	V	64, 0
	.byte	0
m3p3c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p3c1z:
m3p3c1e:
m3p4:
m3p4c0:	.word	m3p4c0v-m3p4c0n, m3p4c0v-m3p4c0n, m3p4c0x-m3p4c0n, m3p4c0z-m3p4c0n, m3p4c0e-m3p4c0n
m3p4c0n:
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	.byte	0
m3p4c0v:
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	.byte	0
m3p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p4c0z:
	.ascii	"PA"
m3p4c0e:
m3p4c1:	.word	m3p4c1v-m3p4c1n, m3p4c1v-m3p4c1n, m3p4c1x-m3p4c1n, m3p4c1z-m3p4c1n, m3p4c1e-m3p4c1n
m3p4c1n:
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	.byte	0
m3p4c1v:
	V	64, 0
	.byte	0
m3p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p4c1z:
m3p4c1e:
m3p5:
m3p5c0:	.word	m3p5c0v-m3p5c0n, m3p5c0v-m3p5c0n, m3p5c0x-m3p5c0n, m3p5c0z-m3p5c0n, m3p5c0e-m3p5c0n
m3p5c0n:
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	.byte	0
m3p5c0v:
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	.byte	0
m3p5c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p5c0z:
	.ascii	"PA"
m3p5c0e:
m3p5c1:	.word	m3p5c1v-m3p5c1n, m3p5c1v-m3p5c1n, m3p5c1x-m3p5c1n, m3p5c1z-m3p5c1n, m3p5c1e-m3p5c1n
m3p5c1n:
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 34
	N	3, NONE, 0
	N	1, C_4, 35
	N	3, NONE, 0
	N	1, C_4, 36
	N	3, NONE, 0
	N	1, C_4, 37
	N	3, NONE, 0
	N	1, C_4, 38
	N	3, NONE, 0
	.byte	0
m3p5c1v:
	V	64, 0
	.byte	0
m3p5c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p5c1z:
m3p5c1e:
m3p6:
m3p6c0:	.word	m3p6c0v-m3p6c0n, m3p6c0v-m3p6c0n, m3p6c0x-m3p6c0n, m3p6c0z-m3p6c0n, m3p6c0e-m3p6c0n
m3p6c0n:
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	.byte	0
m3p6c0v:
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	.byte	0
m3p6c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p6c0z:
	.ascii	"PA"
m3p6c0e:
m3p6c1:	.word	m3p6c1v-m3p6c1n, m3p6c1v-m3p6c1n, m3p6c1x-m3p6c1n, m3p6c1z-m3p6c1n, m3p6c1e-m3p6c1n
m3p6c1n:
	N	1, C_4, 31
	N	3, NONE, 0
	N	1, C_4, 32
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 33
	N	3, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	13, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	13, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	13, NONE, 0
	.byte	0
m3p6c1v:
	V	10, 0
	V	1, 23
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 12
	V	2, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	13, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	13, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	12, 0
	.byte	0
m3p6c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p6c1z:
m3p6c1e:
m3p7:
m3p7c0:	.word	m3p7c0v-m3p7c0n, m3p7c0v-m3p7c0n, m3p7c0x-m3p7c0n, m3p7c0z-m3p7c0n, m3p7c0e-m3p7c0n
m3p7c0n:
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	N	1, C_4, 27
	N	3, NONE, 0
	N	1, C_4, 28
	N	3, NONE, 0
	.byte	0
m3p7c0v:
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	V	1, 45
	V	1, 0
	V	1, 23
	V	1, 0
	.byte	0
m3p7c0x:
	X	64, 0x0, 0x00
	.byte	0
m3p7c0z:
	.ascii	"PA"
m3p7c0e:
m3p7c1:	.word	m3p7c1v-m3p7c1n, m3p7c1v-m3p7c1n, m3p7c1x-m3p7c1n, m3p7c1z-m3p7c1n, m3p7c1e-m3p7c1n
m3p7c1n:
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	13, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	13, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	13, NONE, 0
	N	1, C_4, 24
	N	1, NONE, 0
	N	1, C_4, 24
	N	4, NONE, 0
	N	2, C_4, 25
	N	3, NONE, 0
	N	1, C_4, 25
	N	2, NONE, 0
	N	1, C_4, 25
	.byte	0
m3p7c1v:
	V	1, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	13, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	13, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	13, 0
	V	1, 7
	V	1, 0
	V	1, 7
	V	12, 0
	.byte	0
m3p7c1x:
	X	64, 0x0, 0x00
	.byte	0
m3p7c1z:
	.ascii	"P"
m3p7c1e:

@ ==== module 4 @ 0803D79C ==================================================
	.global gmp3Module4
gmp3Module4:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	2, 0, 0, 13   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F, 0x30, 0x31, 0x23, 0x24, 0x25, 0x26
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	11, 64, 0, 125, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x07, 0x09, 0x08, 0x08, 0x0A, 0xFF, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m4_pat (256 words)
	.word	m4p0 - m4_pat
	.word	m4p1 - m4_pat
	.word	m4p2 - m4_pat
	.word	m4p3 - m4_pat
	.word	m4p4 - m4_pat
	.word	m4p5 - m4_pat
	.word	m4p6 - m4_pat
	.word	m4p7 - m4_pat
	.word	m4p8 - m4_pat
	.word	m4p9 - m4_pat
	.word	m4p10 - m4_pat
	.space	980
	.word	0
m4_pat:
m4p0:
m4p0c0:	.word	m4p0c0v-m4p0c0n, m4p0c0v-m4p0c0n, m4p0c0x-m4p0c0n, m4p0c0z-m4p0c0n, m4p0c0e-m4p0c0n
m4p0c0n:
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	.byte	0
m4p0c0v:
	V	64, 0
	.byte	0
m4p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p0c0z:
m4p0c0e:
m4p0c1:	.word	m4p0c1v-m4p0c1n, m4p0c1v-m4p0c1n, m4p0c1x-m4p0c1n, m4p0c1z-m4p0c1n, m4p0c1e-m4p0c1n
m4p0c1n:
	N	64, NONE, 0
	.byte	0
m4p0c1v:
	V	64, 0
	.byte	0
m4p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p0c1z:
	.ascii	"P"
m4p0c1e:
m4p1:
m4p1c0:	.word	m4p1c0v-m4p1c0n, m4p1c0v-m4p1c0n, m4p1c0x-m4p1c0n, m4p1c0z-m4p1c0n, m4p1c0e-m4p1c0n
m4p1c0n:
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 45
	N	1, NONE, 0
	N	1, C_4, 46
	N	1, NONE, 0
	.byte	0
m4p1c0v:
	V	64, 0
	.byte	0
m4p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p1c0z:
m4p1c0e:
m4p1c1:	.word	m4p1c1v-m4p1c1n, m4p1c1v-m4p1c1n, m4p1c1x-m4p1c1n, m4p1c1z-m4p1c1n, m4p1c1e-m4p1c1n
m4p1c1n:
	N	64, NONE, 0
	.byte	0
m4p1c1v:
	V	64, 0
	.byte	0
m4p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p1c1z:
	.ascii	"P"
m4p1c1e:
m4p2:
m4p2c0:	.word	m4p2c0v-m4p2c0n, m4p2c0v-m4p2c0n, m4p2c0x-m4p2c0n, m4p2c0z-m4p2c0n, m4p2c0e-m4p2c0n
m4p2c0n:
	N	1, C_4, 49
	N	31, NONE, 0
	N	1, Ds4, 49
	N	25, NONE, 0
	N	1, F_4, 49
	N	1, NONE, 0
	N	1, D_4, 49
	N	1, NONE, 0
	N	1, Ds4, 49
	N	1, NONE, 0
	.byte	0
m4p2c0v:
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	.byte	0
m4p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p2c0z:
m4p2c0e:
m4p2c1:	.word	m4p2c1v-m4p2c1n, m4p2c1v-m4p2c1n, m4p2c1x-m4p2c1n, m4p2c1z-m4p2c1n, m4p2c1e-m4p2c1n
m4p2c1n:
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	.byte	0
m4p2c1v:
	V	64, 0
	.byte	0
m4p2c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p2c1z:
m4p2c1e:
m4p3:
m4p3c0:	.word	m4p3c0v-m4p3c0n, m4p3c0v-m4p3c0n, m4p3c0x-m4p3c0n, m4p3c0z-m4p3c0n, m4p3c0e-m4p3c0n
m4p3c0n:
	N	1, C_4, 49
	N	5, NONE, 0
	N	1, F_4, 49
	N	1, NONE, 0
	N	1, C_4, 49
	N	13, NONE, 0
	N	1, F_4, 49
	N	1, NONE, 0
	N	1, C_4, 49
	N	7, NONE, 0
	N	1, Ds4, 49
	N	25, NONE, 0
	N	1, F_4, 49
	N	1, NONE, 0
	N	1, D_4, 49
	N	1, NONE, 0
	N	1, Ds4, 49
	N	1, NONE, 0
	.byte	0
m4p3c0v:
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 41
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	.byte	0
m4p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p3c0z:
m4p3c0e:
m4p3c1:	.word	m4p3c1v-m4p3c1n, m4p3c1v-m4p3c1n, m4p3c1x-m4p3c1n, m4p3c1z-m4p3c1n, m4p3c1e-m4p3c1n
m4p3c1n:
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	.byte	0
m4p3c1v:
	V	64, 0
	.byte	0
m4p3c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p3c1z:
m4p3c1e:
m4p4:
m4p4c0:	.word	m4p4c0v-m4p4c0n, m4p4c0v-m4p4c0n, m4p4c0x-m4p4c0n, m4p4c0z-m4p4c0n, m4p4c0e-m4p4c0n
m4p4c0n:
	N	1, C_4, 49
	N	31, NONE, 0
	N	1, Ds4, 49
	N	25, NONE, 0
	N	1, F_4, 49
	N	1, NONE, 0
	N	1, D_4, 49
	N	1, NONE, 0
	N	1, Ds4, 49
	N	1, NONE, 0
	.byte	0
m4p4c0v:
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	.byte	0
m4p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p4c0z:
m4p4c0e:
m4p4c1:	.word	m4p4c1v-m4p4c1n, m4p4c1v-m4p4c1n, m4p4c1x-m4p4c1n, m4p4c1z-m4p4c1n, m4p4c1e-m4p4c1n
m4p4c1n:
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 43
	N	1, NONE, 0
	N	1, C_4, 44
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 39
	N	1, NONE, 0
	N	1, C_4, 40
	N	1, NONE, 0
	N	1, C_4, 41
	N	1, NONE, 0
	N	1, C_4, 42
	N	1, NONE, 0
	N	1, C_4, 45
	N	1, NONE, 0
	N	1, C_4, 45
	N	1, NONE, 0
	N	1, C_4, 45
	N	1, NONE, 0
	N	1, C_4, 45
	N	1, NONE, 0
	.byte	0
m4p4c1v:
	V	64, 0
	.byte	0
m4p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p4c1z:
m4p4c1e:
m4p5:
m4p5c0:	.word	m4p5c0v-m4p5c0n, m4p5c0v-m4p5c0n, m4p5c0x-m4p5c0n, m4p5c0z-m4p5c0n, m4p5c0e-m4p5c0n
m4p5c0n:
	N	1, C_3, 49
	N	29, NONE, 0
	N	1, As3, 49
	N	1, NONE, 0
	N	1, C_3, 49
	N	25, NONE, 0
	N	1, F_4, 49
	N	1, NONE, 0
	N	1, D_4, 49
	N	1, NONE, 0
	N	1, Ds4, 49
	N	1, NONE, 0
	.byte	0
m4p5c0v:
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 41
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	.byte	0
m4p5c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p5c0z:
	.ascii	"PA"
m4p5c0e:
m4p5c1:	.word	m4p5c1v-m4p5c1n, m4p5c1v-m4p5c1n, m4p5c1x-m4p5c1n, m4p5c1z-m4p5c1n, m4p5c1e-m4p5c1n
m4p5c1n:
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	.byte	0
m4p5c1v:
	V	64, 0
	.byte	0
m4p5c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p5c1z:
m4p5c1e:
m4p6:
m4p6c0:	.word	m4p6c0v-m4p6c0n, m4p6c0v-m4p6c0n, m4p6c0x-m4p6c0n, m4p6c0z-m4p6c0n, m4p6c0e-m4p6c0n
m4p6c0n:
	N	1, C_3, 49
	N	29, NONE, 0
	N	1, As3, 49
	N	1, NONE, 0
	N	1, C_3, 49
	N	31, NONE, 0
	.byte	0
m4p6c0v:
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 41
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	1, 41
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 41
	V	1, 9
	V	6, 0
	.byte	0
m4p6c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p6c0z:
	.ascii	"PA"
m4p6c0e:
m4p6c1:	.word	m4p6c1v-m4p6c1n, m4p6c1v-m4p6c1n, m4p6c1x-m4p6c1n, m4p6c1z-m4p6c1n, m4p6c1e-m4p6c1n
m4p6c1n:
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	.byte	0
m4p6c1v:
	V	64, 0
	.byte	0
m4p6c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p6c1z:
m4p6c1e:
m4p7:
m4p7c0:	.word	m4p7c0v-m4p7c0n, m4p7c0v-m4p7c0n, m4p7c0x-m4p7c0n, m4p7c0z-m4p7c0n, m4p7c0e-m4p7c0n
m4p7c0n:
	N	2, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	1, NONE, 0
	.byte	0
m4p7c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	1, 0
	.byte	0
m4p7c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p7c0z:
	.ascii	"P"
m4p7c0e:
m4p7c1:	.word	m4p7c1v-m4p7c1n, m4p7c1v-m4p7c1n, m4p7c1x-m4p7c1n, m4p7c1z-m4p7c1n, m4p7c1e-m4p7c1n
m4p7c1n:
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	.byte	0
m4p7c1v:
	V	64, 0
	.byte	0
m4p7c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p7c1z:
	.ascii	"P"
m4p7c1e:
m4p8:
m4p8c0:	.word	m4p8c0v-m4p8c0n, m4p8c0v-m4p8c0n, m4p8c0x-m4p8c0n, m4p8c0z-m4p8c0n, m4p8c0e-m4p8c0n
m4p8c0n:
	N	64, NONE, 0
	.byte	0
m4p8c0v:
	V	64, 0
	.byte	0
m4p8c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p8c0z:
	.ascii	"P"
m4p8c0e:
m4p8c1:	.word	m4p8c1v-m4p8c1n, m4p8c1v-m4p8c1n, m4p8c1x-m4p8c1n, m4p8c1z-m4p8c1n, m4p8c1e-m4p8c1n
m4p8c1n:
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	.byte	0
m4p8c1v:
	V	64, 0
	.byte	0
m4p8c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p8c1z:
m4p8c1e:
m4p9:
m4p9c0:	.word	m4p9c0v-m4p9c0n, m4p9c0v-m4p9c0n, m4p9c0x-m4p9c0n, m4p9c0z-m4p9c0n, m4p9c0e-m4p9c0n
m4p9c0n:
	N	2, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	1, NONE, 0
	.byte	0
m4p9c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	1, 0
	.byte	0
m4p9c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p9c0z:
	.ascii	"P"
m4p9c0e:
m4p9c1:	.word	m4p9c1v-m4p9c1n, m4p9c1v-m4p9c1n, m4p9c1x-m4p9c1n, m4p9c1z-m4p9c1n, m4p9c1e-m4p9c1n
m4p9c1n:
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	1, NONE, 0
	N	1, C_4, 48
	N	1, NONE, 0
	N	1, C_4, 48
	N	1, NONE, 0
	N	2, C_4, 48
	.byte	0
m4p9c1v:
	V	64, 0
	.byte	0
m4p9c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p9c1z:
	.ascii	"PA"
m4p9c1e:
m4p10:
m4p10c0:	.word	m4p10c0v-m4p10c0n, m4p10c0v-m4p10c0n, m4p10c0x-m4p10c0n, m4p10c0z-m4p10c0n, m4p10c0e-m4p10c0n
m4p10c0n:
	N	64, NONE, 0
	.byte	0
m4p10c0v:
	V	64, 0
	.byte	0
m4p10c0x:
	X	64, 0x0, 0x00
	.byte	0
m4p10c0z:
	.ascii	"P"
m4p10c0e:
m4p10c1:	.word	m4p10c1v-m4p10c1n, m4p10c1v-m4p10c1n, m4p10c1x-m4p10c1n, m4p10c1z-m4p10c1n, m4p10c1e-m4p10c1n
m4p10c1n:
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	3, NONE, 0
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	3, NONE, 0
	N	1, C_4, 48
	N	2, NONE, 0
	N	1, C_4, 48
	N	1, C_4, 47
	N	1, NONE, 0
	N	1, C_4, 48
	N	1, NONE, 0
	N	1, C_4, 48
	N	1, NONE, 0
	N	2, C_4, 48
	.byte	0
m4p10c1v:
	V	64, 0
	.byte	0
m4p10c1x:
	X	64, 0x0, 0x00
	.byte	0
m4p10c1z:
	.ascii	"PA"
m4p10c1e:

@ ==== module 5 @ 0803EAF0 ==================================================
	.global gmp3Module5
gmp3Module5:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	2, 0, 0, 12   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x32, 0x33, 0x34, 0x35, 0x36, 0x36, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E
	.byte	0x3F, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	10, 64, 0, 125, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x04, 0x05, 0x06, 0x07, 0x08, 0x08, 0x09, 0xFF, 0xFF, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m5_pat (256 words)
	.word	m5p0 - m5_pat
	.word	m5p1 - m5_pat
	.word	m5p2 - m5_pat
	.word	m5p3 - m5_pat
	.word	m5p4 - m5_pat
	.word	m5p5 - m5_pat
	.word	m5p6 - m5_pat
	.word	m5p7 - m5_pat
	.word	m5p8 - m5_pat
	.word	m5p9 - m5_pat
	.space	984
	.word	0
m5_pat:
m5p0:
m5p0c0:	.word	m5p0c0v-m5p0c0n, m5p0c0v-m5p0c0n, m5p0c0x-m5p0c0n, m5p0c0z-m5p0c0n, m5p0c0e-m5p0c0n
m5p0c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	.byte	0
m5p0c0v:
	V	64, 0
	.byte	0
m5p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p0c0z:
m5p0c0e:
m5p0c1:	.word	m5p0c1v-m5p0c1n, m5p0c1v-m5p0c1n, m5p0c1x-m5p0c1n, m5p0c1z-m5p0c1n, m5p0c1e-m5p0c1n
m5p0c1n:
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	.byte	0
m5p0c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m5p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p0c1z:
	.ascii	"PA"
m5p0c1e:
m5p1:
m5p1c0:	.word	m5p1c0v-m5p1c0n, m5p1c0v-m5p1c0n, m5p1c0x-m5p1c0n, m5p1c0z-m5p1c0n, m5p1c0e-m5p1c0n
m5p1c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	2, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	.byte	0
m5p1c0v:
	V	64, 0
	.byte	0
m5p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p1c0z:
	.ascii	"PAD"
m5p1c0e:
m5p1c1:	.word	m5p1c1v-m5p1c1n, m5p1c1v-m5p1c1n, m5p1c1x-m5p1c1n, m5p1c1z-m5p1c1n, m5p1c1e-m5p1c1n
m5p1c1n:
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	.byte	0
m5p1c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m5p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p1c1z:
	.ascii	"PA"
m5p1c1e:
m5p2:
m5p2c0:	.word	m5p2c0v-m5p2c0n, m5p2c0v-m5p2c0n, m5p2c0x-m5p2c0n, m5p2c0z-m5p2c0n, m5p2c0e-m5p2c0n
m5p2c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	.byte	0
m5p2c0v:
	V	64, 0
	.byte	0
m5p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p2c0z:
m5p2c0e:
m5p2c1:	.word	m5p2c1v-m5p2c1n, m5p2c1v-m5p2c1n, m5p2c1x-m5p2c1n, m5p2c1z-m5p2c1n, m5p2c1e-m5p2c1n
m5p2c1n:
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	.byte	0
m5p2c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m5p2c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p2c1z:
	.ascii	"PA"
m5p2c1e:
m5p3:
m5p3c0:	.word	m5p3c0v-m5p3c0n, m5p3c0v-m5p3c0n, m5p3c0x-m5p3c0n, m5p3c0z-m5p3c0n, m5p3c0e-m5p3c0n
m5p3c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	.byte	0
m5p3c0v:
	V	64, 0
	.byte	0
m5p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p3c0z:
m5p3c0e:
m5p3c1:	.word	m5p3c1v-m5p3c1n, m5p3c1v-m5p3c1n, m5p3c1x-m5p3c1n, m5p3c1z-m5p3c1n, m5p3c1e-m5p3c1n
m5p3c1n:
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	.byte	0
m5p3c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m5p3c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p3c1z:
	.ascii	"PA"
m5p3c1e:
m5p4:
m5p4c0:	.word	m5p4c0v-m5p4c0n, m5p4c0v-m5p4c0n, m5p4c0x-m5p4c0n, m5p4c0z-m5p4c0n, m5p4c0e-m5p4c0n
m5p4c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	.byte	0
m5p4c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m5p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p4c0z:
m5p4c0e:
m5p4c1:	.word	m5p4c1v-m5p4c1n, m5p4c1v-m5p4c1n, m5p4c1x-m5p4c1n, m5p4c1z-m5p4c1n, m5p4c1e-m5p4c1n
m5p4c1n:
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	.byte	0
m5p4c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	.byte	0
m5p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p4c1z:
	.ascii	"PA"
m5p4c1e:
m5p5:
m5p5c0:	.word	m5p5c0v-m5p5c0n, m5p5c0v-m5p5c0n, m5p5c0x-m5p5c0n, m5p5c0z-m5p5c0n, m5p5c0e-m5p5c0n
m5p5c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	.byte	0
m5p5c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m5p5c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p5c0z:
m5p5c0e:
m5p5c1:	.word	m5p5c1v-m5p5c1n, m5p5c1v-m5p5c1n, m5p5c1x-m5p5c1n, m5p5c1z-m5p5c1n, m5p5c1e-m5p5c1n
m5p5c1n:
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 64
	N	3, NONE, 0
	N	1, C_4, 63
	N	3, NONE, 0
	N	1, C_4, 62
	N	3, NONE, 0
	N	1, C_4, 61
	N	3, NONE, 0
	N	1, C_4, 60
	N	3, NONE, 0
	N	1, C_4, 59
	N	3, NONE, 0
	N	1, C_4, 58
	N	3, NONE, 0
	N	1, C_4, 57
	N	7, NONE, 0
	.byte	0
m5p5c1v:
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	3, 0
	V	1, 34
	V	7, 0
	.byte	0
m5p5c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p5c1z:
m5p5c1e:
m5p6:
m5p6c0:	.word	m5p6c0v-m5p6c0n, m5p6c0v-m5p6c0n, m5p6c0x-m5p6c0n, m5p6c0z-m5p6c0n, m5p6c0e-m5p6c0n
m5p6c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	.byte	0
m5p6c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m5p6c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p6c0z:
m5p6c0e:
m5p6c1:	.word	m5p6c1v-m5p6c1n, m5p6c1v-m5p6c1n, m5p6c1x-m5p6c1n, m5p6c1z-m5p6c1n, m5p6c1e-m5p6c1n
m5p6c1n:
	N	64, NONE, 0
	.byte	0
m5p6c1v:
	V	64, 0
	.byte	0
m5p6c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p6c1z:
	.ascii	"P"
m5p6c1e:
m5p7:
m5p7c0:	.word	m5p7c0v-m5p7c0n, m5p7c0v-m5p7c0n, m5p7c0x-m5p7c0n, m5p7c0z-m5p7c0n, m5p7c0e-m5p7c0n
m5p7c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	.byte	0
m5p7c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m5p7c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p7c0z:
m5p7c0e:
m5p7c1:	.word	m5p7c1v-m5p7c1n, m5p7c1v-m5p7c1n, m5p7c1x-m5p7c1n, m5p7c1z-m5p7c1n, m5p7c1e-m5p7c1n
m5p7c1n:
	N	4, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	11, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	11, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	11, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	.byte	0
m5p7c1v:
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 34
	V	3, 0
	V	1, 34
	V	4, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	2, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 34
	V	3, 0
	V	1, 34
	V	4, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	2, 0
	V	1, 45
	V	1, 23
	V	1, 12
	.byte	0
m5p7c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p7c1z:
	.ascii	"P"
m5p7c1e:
m5p8:
m5p8c0:	.word	m5p8c0v-m5p8c0n, m5p8c0v-m5p8c0n, m5p8c0x-m5p8c0n, m5p8c0z-m5p8c0n, m5p8c0e-m5p8c0n
m5p8c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	.byte	0
m5p8c0v:
	V	2, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	3, 0
	V	1, 23
	V	5, 0
	.byte	0
m5p8c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p8c0z:
m5p8c0e:
m5p8c1:	.word	m5p8c1v-m5p8c1n, m5p8c1v-m5p8c1n, m5p8c1x-m5p8c1n, m5p8c1z-m5p8c1n, m5p8c1e-m5p8c1n
m5p8c1n:
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	3, NONE, 0
	N	1, C_4, 57
	N	3, NONE, 0
	.byte	0
m5p8c1v:
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 34
	V	3, 0
	V	1, 34
	V	4, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	9, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 34
	V	3, 0
	V	1, 34
	V	4, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	9, 0
	V	1, 45
	V	1, 23
	V	1, 12
	.byte	0
m5p8c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p8c1z:
	.ascii	"PA"
m5p8c1e:
m5p9:
m5p9c0:	.word	m5p9c0v-m5p9c0n, m5p9c0v-m5p9c0n, m5p9c0x-m5p9c0n, m5p9c0z-m5p9c0n, m5p9c0e-m5p9c0n
m5p9c0n:
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 50
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	N	1, C_4, 52
	N	1, NONE, 0
	N	1, C_4, 51
	N	1, NONE, 0
	.byte	0
m5p9c0v:
	V	64, 0
	.byte	0
m5p9c0x:
	X	64, 0x0, 0x00
	.byte	0
m5p9c0z:
m5p9c0e:
m5p9c1:	.word	m5p9c1v-m5p9c1n, m5p9c1v-m5p9c1n, m5p9c1x-m5p9c1n, m5p9c1z-m5p9c1n, m5p9c1e-m5p9c1n
m5p9c1n:
	N	1, C_4, 57
	N	3, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	11, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	11, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	11, NONE, 0
	N	1, C_4, 55
	N	3, NONE, 0
	N	1, C_4, 56
	N	7, NONE, 0
	.byte	0
m5p9c1v:
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 34
	V	3, 0
	V	1, 34
	V	4, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	2, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 34
	V	3, 0
	V	1, 34
	V	4, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 45
	V	1, 23
	V	1, 12
	V	1, 0
	V	1, 45
	V	1, 23
	V	1, 12
	V	2, 0
	V	1, 45
	V	1, 23
	V	1, 12
	.byte	0
m5p9c1x:
	X	64, 0x0, 0x00
	.byte	0
m5p9c1z:
m5p9c1e:

@ ==== module 6 @ 080401BC ==================================================
	.global gmp3Module6
gmp3Module6:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	2, 0, 0, 7   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49, 0x39, 0x3A, 0x3B, 0x3C, 0x3D, 0x3E
	.byte	0x3F, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	7, 64, 0, 100, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0xFF, 0x07, 0x08, 0x08, 0x09, 0xFF, 0xFF, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m6_pat (256 words)
	.word	m6p0 - m6_pat
	.word	m6p1 - m6_pat
	.word	m6p2 - m6_pat
	.word	m6p3 - m6_pat
	.word	m6p4 - m6_pat
	.word	m6p5 - m6_pat
	.word	m6p6 - m6_pat
	.space	996
	.word	0
m6_pat:
m6p0:
m6p0c0:	.word	m6p0c0v-m6p0c0n, m6p0c0v-m6p0c0n, m6p0c0x-m6p0c0n, m6p0c0z-m6p0c0n, m6p0c0e-m6p0c0n
m6p0c0n:
	N	1, C_4, 65
	N	11, NONE, 0
	N	1, C_4, 66
	N	3, NONE, 0
	N	1, C_4, 65
	N	11, NONE, 0
	N	1, C_4, 67
	N	3, NONE, 0
	N	1, C_4, 65
	N	11, NONE, 0
	N	1, C_4, 66
	N	3, NONE, 0
	N	1, C_4, 65
	N	15, NONE, 0
	.byte	0
m6p0c0v:
	V	64, 0
	.byte	0
m6p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p0c0z:
	.ascii	"PA"
m6p0c0e:
m6p0c1:	.word	m6p0c1v-m6p0c1n, m6p0c1v-m6p0c1n, m6p0c1x-m6p0c1n, m6p0c1z-m6p0c1n, m6p0c1e-m6p0c1n
m6p0c1n:
	N	60, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	.byte	0
m6p0c1v:
	V	64, 0
	.byte	0
m6p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p0c1z:
	.ascii	"P"
m6p0c1e:
m6p1:
m6p1c0:	.word	m6p1c0v-m6p1c0n, m6p1c0v-m6p1c0n, m6p1c0x-m6p1c0n, m6p1c0z-m6p1c0n, m6p1c0e-m6p1c0n
m6p1c0n:
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 70
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 70
	N	3, NONE, 0
	.byte	0
m6p1c0v:
	V	64, 0
	.byte	0
m6p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p1c0z:
m6p1c0e:
m6p1c1:	.word	m6p1c1v-m6p1c1n, m6p1c1v-m6p1c1n, m6p1c1x-m6p1c1n, m6p1c1z-m6p1c1n, m6p1c1e-m6p1c1n
m6p1c1n:
	N	64, NONE, 0
	.byte	0
m6p1c1v:
	V	64, 0
	.byte	0
m6p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p1c1z:
	.ascii	"P"
m6p1c1e:
m6p2:
m6p2c0:	.word	m6p2c0v-m6p2c0n, m6p2c0v-m6p2c0n, m6p2c0x-m6p2c0n, m6p2c0z-m6p2c0n, m6p2c0e-m6p2c0n
m6p2c0n:
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 70
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	7, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	.byte	0
m6p2c0v:
	V	64, 0
	.byte	0
m6p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p2c0z:
	.ascii	"PA"
m6p2c0e:
m6p2c1:	.word	m6p2c1v-m6p2c1n, m6p2c1v-m6p2c1n, m6p2c1x-m6p2c1n, m6p2c1z-m6p2c1n, m6p2c1e-m6p2c1n
m6p2c1n:
	N	2, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 70
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	13, NONE, 0
	.byte	0
m6p2c1v:
	V	2, 0
	V	1, 33
	V	11, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	11, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	11, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	13, 0
	.byte	0
m6p2c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p2c1z:
	.ascii	"PAD"
m6p2c1e:
m6p3:
m6p3c0:	.word	m6p3c0v-m6p3c0n, m6p3c0v-m6p3c0n, m6p3c0x-m6p3c0n, m6p3c0z-m6p3c0n, m6p3c0e-m6p3c0n
m6p3c0n:
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	.byte	0
m6p3c0v:
	V	64, 0
	.byte	0
m6p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p3c0z:
m6p3c0e:
m6p3c1:	.word	m6p3c1v-m6p3c1n, m6p3c1v-m6p3c1n, m6p3c1x-m6p3c1n, m6p3c1z-m6p3c1n, m6p3c1e-m6p3c1n
m6p3c1n:
	N	2, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 73
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	.byte	0
m6p3c1v:
	V	2, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	3, 0
	V	1, 33
	V	1, 0
	.byte	0
m6p3c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p3c1z:
	.ascii	"P"
m6p3c1e:
m6p4:
m6p4c0:	.word	m6p4c0v-m6p4c0n, m6p4c0v-m6p4c0n, m6p4c0x-m6p4c0n, m6p4c0z-m6p4c0n, m6p4c0e-m6p4c0n
m6p4c0n:
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	3, NONE, 0
	N	1, C_4, 71
	N	4, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	.byte	0
m6p4c0v:
	V	57, 0
	V	1, 25
	V	1, 0
	V	1, 25
	V	1, 0
	V	1, 25
	V	1, 0
	V	1, 25
	.byte	0
m6p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p4c0z:
	.ascii	"PAD"
m6p4c0e:
m6p4c1:	.word	m6p4c1v-m6p4c1n, m6p4c1v-m6p4c1n, m6p4c1x-m6p4c1n, m6p4c1z-m6p4c1n, m6p4c1e-m6p4c1n
m6p4c1n:
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	7, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	.byte	0
m6p4c1v:
	V	64, 0
	.byte	0
m6p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p4c1z:
m6p4c1e:
m6p5:
m6p5c0:	.word	m6p5c0v-m6p5c0n, m6p5c0v-m6p5c0n, m6p5c0x-m6p5c0n, m6p5c0z-m6p5c0n, m6p5c0e-m6p5c0n
m6p5c0n:
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 70
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	15, NONE, 0
	.byte	0
m6p5c0v:
	V	64, 0
	.byte	0
m6p5c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p5c0z:
	.ascii	"PA"
m6p5c0e:
m6p5c1:	.word	m6p5c1v-m6p5c1n, m6p5c1v-m6p5c1n, m6p5c1x-m6p5c1n, m6p5c1z-m6p5c1n, m6p5c1e-m6p5c1n
m6p5c1n:
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	.byte	0
m6p5c1v:
	V	64, 0
	.byte	0
m6p5c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p5c1z:
m6p5c1e:
m6p6:
m6p6c0:	.word	m6p6c0v-m6p6c0n, m6p6c0v-m6p6c0n, m6p6c0x-m6p6c0n, m6p6c0z-m6p6c0n, m6p6c0e-m6p6c0n
m6p6c0n:
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 70
	N	3, NONE, 0
	N	1, C_4, 68
	N	11, NONE, 0
	N	1, C_4, 69
	N	3, NONE, 0
	N	1, C_4, 68
	N	7, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	.byte	0
m6p6c0v:
	V	64, 0
	.byte	0
m6p6c0x:
	X	64, 0x0, 0x00
	.byte	0
m6p6c0z:
	.ascii	"PA"
m6p6c0e:
m6p6c1:	.word	m6p6c1v-m6p6c1n, m6p6c1v-m6p6c1n, m6p6c1x-m6p6c1n, m6p6c1z-m6p6c1n, m6p6c1e-m6p6c1n
m6p6c1n:
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	15, NONE, 0
	N	1, C_4, 72
	N	8, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	N	1, NONE, 0
	N	1, C_4, 73
	.byte	0
m6p6c1v:
	V	57, 0
	V	1, 25
	V	1, 0
	V	1, 25
	V	1, 0
	V	1, 25
	V	1, 0
	V	1, 25
	.byte	0
m6p6c1x:
	X	64, 0x0, 0x00
	.byte	0
m6p6c1z:
	.ascii	"P"
m6p6c1e:

@ ==== module 7 @ 08040D18 ==================================================
	.global gmp3Module7
gmp3Module7:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	8, 0, 0, 12   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x4A, 0x4B, 0x4C, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x3E
	.byte	0x3F, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	7, 64, 0, 117, 3   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x00, 0x01, 0x02, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x05, 0x06, 0xFF, 0xFF, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m7_pat (256 words)
	.word	m7p0 - m7_pat
	.word	m7p1 - m7_pat
	.word	m7p2 - m7_pat
	.word	m7p3 - m7_pat
	.word	m7p4 - m7_pat
	.word	m7p5 - m7_pat
	.word	m7p6 - m7_pat
	.space	996
	.word	0
m7_pat:
m7p0:
m7p0c0:	.word	m7p0c0v-m7p0c0n, m7p0c0v-m7p0c0n, m7p0c0x-m7p0c0n, m7p0c0z-m7p0c0n, m7p0c0e-m7p0c0n
m7p0c0n:
	N	1, C_4, 74
	N	55, NONE, 0
	N	1, C_4, 78
	N	7, NONE, 0
	.byte	0
m7p0c0v:
	V	64, 0
	.byte	0
m7p0c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c0z:
m7p0c0e:
m7p0c1:	.word	m7p0c1v-m7p0c1n, m7p0c1v-m7p0c1n, m7p0c1x-m7p0c1n, m7p0c1z-m7p0c1n, m7p0c1e-m7p0c1n
m7p0c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	55, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p0c1v:
	V	4, 0
	V	1, 9
	V	55, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p0c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c1z:
	.ascii	"P"
m7p0c1e:
m7p0c2:	.word	m7p0c2v-m7p0c2n, m7p0c2v-m7p0c2n, m7p0c2x-m7p0c2n, m7p0c2z-m7p0c2n, m7p0c2e-m7p0c2n
m7p0c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p0c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p0c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c2z:
m7p0c2e:
m7p0c3:	.word	m7p0c3v-m7p0c3n, m7p0c3v-m7p0c3n, m7p0c3x-m7p0c3n, m7p0c3z-m7p0c3n, m7p0c3e-m7p0c3n
m7p0c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p0c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p0c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c3z:
m7p0c3e:
m7p0c4:	.word	m7p0c4v-m7p0c4n, m7p0c4v-m7p0c4n, m7p0c4x-m7p0c4n, m7p0c4z-m7p0c4n, m7p0c4e-m7p0c4n
m7p0c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p0c4v:
	V	64, 0
	.byte	0
m7p0c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c4z:
	.ascii	"PA"
m7p0c4e:
m7p0c5:	.word	m7p0c5v-m7p0c5n, m7p0c5v-m7p0c5n, m7p0c5x-m7p0c5n, m7p0c5z-m7p0c5n, m7p0c5e-m7p0c5n
m7p0c5n:
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	.byte	0
m7p0c5v:
	V	64, 0
	.byte	0
m7p0c5x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c5z:
m7p0c5e:
m7p0c6:	.word	m7p0c6v-m7p0c6n, m7p0c6v-m7p0c6n, m7p0c6x-m7p0c6n, m7p0c6z-m7p0c6n, m7p0c6e-m7p0c6n
m7p0c6n:
	N	64, NONE, 0
	.byte	0
m7p0c6v:
	V	64, 0
	.byte	0
m7p0c6x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c6z:
	.ascii	"P"
m7p0c6e:
m7p0c7:	.word	m7p0c7v-m7p0c7n, m7p0c7v-m7p0c7n, m7p0c7x-m7p0c7n, m7p0c7z-m7p0c7n, m7p0c7e-m7p0c7n
m7p0c7n:
	N	64, NONE, 0
	.byte	0
m7p0c7v:
	V	64, 0
	.byte	0
m7p0c7x:
	X	64, 0x0, 0x00
	.byte	0
m7p0c7z:
	.ascii	"P"
m7p0c7e:
m7p1:
m7p1c0:	.word	m7p1c0v-m7p1c0n, m7p1c0v-m7p1c0n, m7p1c0x-m7p1c0n, m7p1c0z-m7p1c0n, m7p1c0e-m7p1c0n
m7p1c0n:
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	7, NONE, 0
	.byte	0
m7p1c0v:
	V	64, 0
	.byte	0
m7p1c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c0z:
m7p1c0e:
m7p1c1:	.word	m7p1c1v-m7p1c1n, m7p1c1v-m7p1c1n, m7p1c1x-m7p1c1n, m7p1c1z-m7p1c1n, m7p1c1e-m7p1c1n
m7p1c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p1c1v:
	V	4, 0
	V	1, 9
	V	19, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	V	1, 9
	V	15, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p1c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c1z:
	.ascii	"P"
m7p1c1e:
m7p1c2:	.word	m7p1c2v-m7p1c2n, m7p1c2v-m7p1c2n, m7p1c2x-m7p1c2n, m7p1c2z-m7p1c2n, m7p1c2e-m7p1c2n
m7p1c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p1c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p1c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c2z:
m7p1c2e:
m7p1c3:	.word	m7p1c3v-m7p1c3n, m7p1c3v-m7p1c3n, m7p1c3x-m7p1c3n, m7p1c3z-m7p1c3n, m7p1c3e-m7p1c3n
m7p1c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p1c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p1c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c3z:
m7p1c3e:
m7p1c4:	.word	m7p1c4v-m7p1c4n, m7p1c4v-m7p1c4n, m7p1c4x-m7p1c4n, m7p1c4z-m7p1c4n, m7p1c4e-m7p1c4n
m7p1c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p1c4v:
	V	64, 0
	.byte	0
m7p1c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c4z:
	.ascii	"PA"
m7p1c4e:
m7p1c5:	.word	m7p1c5v-m7p1c5n, m7p1c5v-m7p1c5n, m7p1c5x-m7p1c5n, m7p1c5z-m7p1c5n, m7p1c5e-m7p1c5n
m7p1c5n:
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	.byte	0
m7p1c5v:
	V	64, 0
	.byte	0
m7p1c5x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c5z:
m7p1c5e:
m7p1c6:	.word	m7p1c6v-m7p1c6n, m7p1c6v-m7p1c6n, m7p1c6x-m7p1c6n, m7p1c6z-m7p1c6n, m7p1c6e-m7p1c6n
m7p1c6n:
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	11, NONE, 0
	N	1, Ds3, 79
	N	7, NONE, 0
	N	1, F_3, 79
	N	3, NONE, 0
	N	1, F_3, 79
	N	15, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As2, 79
	N	3, NONE, 0
	N	1, As2, 79
	N	3, NONE, 0
	.byte	0
m7p1c6v:
	V	8, 0
	V	1, 9
	V	43, 0
	V	1, 17
	V	7, 0
	V	1, 17
	V	3, 0
	.byte	0
m7p1c6x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c6z:
m7p1c6e:
m7p1c7:	.word	m7p1c7v-m7p1c7n, m7p1c7v-m7p1c7n, m7p1c7x-m7p1c7n, m7p1c7z-m7p1c7n, m7p1c7e-m7p1c7n
m7p1c7n:
	N	1, E_4, 87
	N	63, NONE, 0
	.byte	0
m7p1c7v:
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	.byte	0
m7p1c7x:
	X	64, 0x0, 0x00
	.byte	0
m7p1c7z:
m7p1c7e:
m7p2:
m7p2c0:	.word	m7p2c0v-m7p2c0n, m7p2c0v-m7p2c0n, m7p2c0x-m7p2c0n, m7p2c0z-m7p2c0n, m7p2c0e-m7p2c0n
m7p2c0n:
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, D_4, 78
	N	3, NONE, 0
	N	1, D_4, 78
	N	3, NONE, 0
	.byte	0
m7p2c0v:
	V	64, 0
	.byte	0
m7p2c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c0z:
	.ascii	"PA"
m7p2c0e:
m7p2c1:	.word	m7p2c1v-m7p2c1n, m7p2c1v-m7p2c1n, m7p2c1x-m7p2c1n, m7p2c1z-m7p2c1n, m7p2c1e-m7p2c1n
m7p2c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p2c1v:
	V	4, 0
	V	1, 9
	V	19, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	V	1, 9
	V	15, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p2c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c1z:
	.ascii	"P"
m7p2c1e:
m7p2c2:	.word	m7p2c2v-m7p2c2n, m7p2c2v-m7p2c2n, m7p2c2x-m7p2c2n, m7p2c2z-m7p2c2n, m7p2c2e-m7p2c2n
m7p2c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p2c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p2c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c2z:
m7p2c2e:
m7p2c3:	.word	m7p2c3v-m7p2c3n, m7p2c3v-m7p2c3n, m7p2c3x-m7p2c3n, m7p2c3z-m7p2c3n, m7p2c3e-m7p2c3n
m7p2c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p2c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p2c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c3z:
m7p2c3e:
m7p2c4:	.word	m7p2c4v-m7p2c4n, m7p2c4v-m7p2c4n, m7p2c4x-m7p2c4n, m7p2c4z-m7p2c4n, m7p2c4e-m7p2c4n
m7p2c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p2c4v:
	V	64, 0
	.byte	0
m7p2c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c4z:
	.ascii	"PA"
m7p2c4e:
m7p2c5:	.word	m7p2c5v-m7p2c5n, m7p2c5v-m7p2c5n, m7p2c5x-m7p2c5n, m7p2c5z-m7p2c5n, m7p2c5e-m7p2c5n
m7p2c5n:
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	.byte	0
m7p2c5v:
	V	64, 0
	.byte	0
m7p2c5x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c5z:
m7p2c5e:
m7p2c6:	.word	m7p2c6v-m7p2c6n, m7p2c6v-m7p2c6n, m7p2c6x-m7p2c6n, m7p2c6z-m7p2c6n, m7p2c6e-m7p2c6n
m7p2c6n:
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	11, NONE, 0
	N	1, Ds3, 79
	N	7, NONE, 0
	N	1, F_3, 79
	N	3, NONE, 0
	N	1, F_3, 79
	N	15, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	3, NONE, 0
	.byte	0
m7p2c6v:
	V	8, 0
	V	1, 9
	V	43, 0
	V	1, 17
	V	7, 0
	V	1, 17
	V	3, 0
	.byte	0
m7p2c6x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c6z:
m7p2c6e:
m7p2c7:	.word	m7p2c7v-m7p2c7n, m7p2c7v-m7p2c7n, m7p2c7x-m7p2c7n, m7p2c7z-m7p2c7n, m7p2c7e-m7p2c7n
m7p2c7n:
	N	1, G_4, 87
	N	7, NONE, 0
	N	1, E_4, 87
	N	27, NONE, 0
	N	1, A_4, 87
	N	15, NONE, 0
	N	1, D_4, 87
	N	9, NONE, 0
	N	1, E_4, 87
	N	1, NONE, 0
	.byte	0
m7p2c7v:
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	.byte	0
m7p2c7x:
	X	64, 0x0, 0x00
	.byte	0
m7p2c7z:
m7p2c7e:
m7p3:
m7p3c0:	.word	m7p3c0v-m7p3c0n, m7p3c0v-m7p3c0n, m7p3c0x-m7p3c0n, m7p3c0z-m7p3c0n, m7p3c0e-m7p3c0n
m7p3c0n:
	N	1, C_4, 74
	N	55, NONE, 0
	N	1, C_4, 78
	N	7, NONE, 0
	.byte	0
m7p3c0v:
	V	64, 0
	.byte	0
m7p3c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c0z:
m7p3c0e:
m7p3c1:	.word	m7p3c1v-m7p3c1n, m7p3c1v-m7p3c1n, m7p3c1x-m7p3c1n, m7p3c1z-m7p3c1n, m7p3c1e-m7p3c1n
m7p3c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	55, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p3c1v:
	V	4, 0
	V	1, 9
	V	55, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p3c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c1z:
	.ascii	"P"
m7p3c1e:
m7p3c2:	.word	m7p3c2v-m7p3c2n, m7p3c2v-m7p3c2n, m7p3c2x-m7p3c2n, m7p3c2z-m7p3c2n, m7p3c2e-m7p3c2n
m7p3c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p3c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p3c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c2z:
m7p3c2e:
m7p3c3:	.word	m7p3c3v-m7p3c3n, m7p3c3v-m7p3c3n, m7p3c3x-m7p3c3n, m7p3c3z-m7p3c3n, m7p3c3e-m7p3c3n
m7p3c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p3c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p3c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c3z:
m7p3c3e:
m7p3c4:	.word	m7p3c4v-m7p3c4n, m7p3c4v-m7p3c4n, m7p3c4x-m7p3c4n, m7p3c4z-m7p3c4n, m7p3c4e-m7p3c4n
m7p3c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p3c4v:
	V	64, 0
	.byte	0
m7p3c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c4z:
	.ascii	"PA"
m7p3c4e:
m7p3c5:	.word	m7p3c5v-m7p3c5n, m7p3c5v-m7p3c5n, m7p3c5x-m7p3c5n, m7p3c5z-m7p3c5n, m7p3c5e-m7p3c5n
m7p3c5n:
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	.byte	0
m7p3c5v:
	V	64, 0
	.byte	0
m7p3c5x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c5z:
m7p3c5e:
m7p3c6:	.word	m7p3c6v-m7p3c6n, m7p3c6v-m7p3c6n, m7p3c6x-m7p3c6n, m7p3c6z-m7p3c6n, m7p3c6e-m7p3c6n
m7p3c6n:
	N	2, NONE, 0
	N	1, E_4, 87
	N	61, NONE, 0
	.byte	0
m7p3c6v:
	V	1, 0
	V	2, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	.byte	0
m7p3c6x:
	X	2, 0x0, 0x00
	X	1, 0x2, 0x01
	X	61, 0x0, 0x00
	.byte	0
m7p3c6z:
	.ascii	"P"
m7p3c6e:
m7p3c7:	.word	m7p3c7v-m7p3c7n, m7p3c7v-m7p3c7n, m7p3c7x-m7p3c7n, m7p3c7z-m7p3c7n, m7p3c7e-m7p3c7n
m7p3c7n:
	N	1, E_4, 87
	N	63, NONE, 0
	.byte	0
m7p3c7v:
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	.byte	0
m7p3c7x:
	X	64, 0x0, 0x00
	.byte	0
m7p3c7z:
m7p3c7e:
m7p4:
m7p4c0:	.word	m7p4c0v-m7p4c0n, m7p4c0v-m7p4c0n, m7p4c0x-m7p4c0n, m7p4c0z-m7p4c0n, m7p4c0e-m7p4c0n
m7p4c0n:
	N	1, C_4, 74
	N	55, NONE, 0
	N	1, C_4, 78
	N	7, NONE, 0
	.byte	0
m7p4c0v:
	V	64, 0
	.byte	0
m7p4c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c0z:
m7p4c0e:
m7p4c1:	.word	m7p4c1v-m7p4c1n, m7p4c1v-m7p4c1n, m7p4c1x-m7p4c1n, m7p4c1z-m7p4c1n, m7p4c1e-m7p4c1n
m7p4c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	55, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p4c1v:
	V	4, 0
	V	1, 9
	V	55, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p4c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c1z:
	.ascii	"P"
m7p4c1e:
m7p4c2:	.word	m7p4c2v-m7p4c2n, m7p4c2v-m7p4c2n, m7p4c2x-m7p4c2n, m7p4c2z-m7p4c2n, m7p4c2e-m7p4c2n
m7p4c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p4c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p4c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c2z:
m7p4c2e:
m7p4c3:	.word	m7p4c3v-m7p4c3n, m7p4c3v-m7p4c3n, m7p4c3x-m7p4c3n, m7p4c3z-m7p4c3n, m7p4c3e-m7p4c3n
m7p4c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p4c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p4c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c3z:
m7p4c3e:
m7p4c4:	.word	m7p4c4v-m7p4c4n, m7p4c4v-m7p4c4n, m7p4c4x-m7p4c4n, m7p4c4z-m7p4c4n, m7p4c4e-m7p4c4n
m7p4c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p4c4v:
	V	64, 0
	.byte	0
m7p4c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c4z:
	.ascii	"PA"
m7p4c4e:
m7p4c5:	.word	m7p4c5v-m7p4c5n, m7p4c5v-m7p4c5n, m7p4c5x-m7p4c5n, m7p4c5z-m7p4c5n, m7p4c5e-m7p4c5n
m7p4c5n:
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	N	1, C_4, 83
	N	7, NONE, 0
	.byte	0
m7p4c5v:
	V	64, 0
	.byte	0
m7p4c5x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c5z:
m7p4c5e:
m7p4c6:	.word	m7p4c6v-m7p4c6n, m7p4c6v-m7p4c6n, m7p4c6x-m7p4c6n, m7p4c6z-m7p4c6n, m7p4c6e-m7p4c6n
m7p4c6n:
	N	2, NONE, 0
	N	1, E_4, 87
	N	61, NONE, 0
	.byte	0
m7p4c6v:
	V	1, 0
	V	2, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	.byte	0
m7p4c6x:
	X	2, 0x0, 0x00
	X	1, 0x2, 0x01
	X	61, 0x0, 0x00
	.byte	0
m7p4c6z:
	.ascii	"P"
m7p4c6e:
m7p4c7:	.word	m7p4c7v-m7p4c7n, m7p4c7v-m7p4c7n, m7p4c7x-m7p4c7n, m7p4c7z-m7p4c7n, m7p4c7e-m7p4c7n
m7p4c7n:
	N	1, E_4, 87
	N	63, NONE, 0
	.byte	0
m7p4c7v:
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	V	1, 33
	V	1, 9
	.byte	0
m7p4c7x:
	X	64, 0x0, 0x00
	.byte	0
m7p4c7z:
m7p4c7e:
m7p5:
m7p5c0:	.word	m7p5c0v-m7p5c0n, m7p5c0v-m7p5c0n, m7p5c0x-m7p5c0n, m7p5c0z-m7p5c0n, m7p5c0e-m7p5c0n
m7p5c0n:
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	7, NONE, 0
	.byte	0
m7p5c0v:
	V	64, 0
	.byte	0
m7p5c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p5c0z:
m7p5c0e:
m7p5c1:	.word	m7p5c1v-m7p5c1n, m7p5c1v-m7p5c1n, m7p5c1x-m7p5c1n, m7p5c1z-m7p5c1n, m7p5c1e-m7p5c1n
m7p5c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p5c1v:
	V	4, 0
	V	1, 9
	V	19, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	V	1, 9
	V	15, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p5c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p5c1z:
	.ascii	"P"
m7p5c1e:
m7p5c2:	.word	m7p5c2v-m7p5c2n, m7p5c2v-m7p5c2n, m7p5c2x-m7p5c2n, m7p5c2z-m7p5c2n, m7p5c2e-m7p5c2n
m7p5c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p5c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p5c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p5c2z:
m7p5c2e:
m7p5c3:	.word	m7p5c3v-m7p5c3n, m7p5c3v-m7p5c3n, m7p5c3x-m7p5c3n, m7p5c3z-m7p5c3n, m7p5c3e-m7p5c3n
m7p5c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p5c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p5c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p5c3z:
m7p5c3e:
m7p5c4:	.word	m7p5c4v-m7p5c4n, m7p5c4v-m7p5c4n, m7p5c4x-m7p5c4n, m7p5c4z-m7p5c4n, m7p5c4e-m7p5c4n
m7p5c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p5c4v:
	V	64, 0
	.byte	0
m7p5c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p5c4z:
	.ascii	"PA"
m7p5c4e:
m7p5c5:	.word	m7p5c5v-m7p5c5n, m7p5c5v-m7p5c5n, m7p5c5x-m7p5c5n, m7p5c5z-m7p5c5n, m7p5c5e-m7p5c5n
m7p5c5n:
	N	3, NONE, 0
	N	1, B_4, 87
	N	2, NONE, 0
	N	1, As4, 87
	N	1, B_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, G_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, E_4, 87
	N	3, NONE, 0
	N	1, D_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	1, NONE, 0
	N	1, D_4, 87
	.byte	0
m7p5c5v:
	V	1, 1
	V	2, 0
	V	1, 17
	V	2, 0
	V	2, 17
	V	3, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	5, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 17
	V	1, 9
	V	1, 17
	V	3, 0
	V	1, 17
	V	5, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	1, 9
	V	1, 17
	.byte	0
m7p5c5x:
	X	7, 0x0, 0x00
	X	1, 0x3, 0x30
	X	1, 0x3, 0x00
	X	1, 0xA, 0x0F
	X	19, 0x0, 0x00
	X	1, 0x4, 0x82
	X	3, 0x4, 0x00
	X	2, 0x2, 0x0F
	X	18, 0x0, 0x00
	X	2, 0xA, 0x05
	X	9, 0x0, 0x00
	.byte	0
m7p5c5z:
	.ascii	"PAD"
m7p5c5e:
m7p5c6:	.word	m7p5c6v-m7p5c6n, m7p5c6v-m7p5c6n, m7p5c6x-m7p5c6n, m7p5c6z-m7p5c6n, m7p5c6e-m7p5c6n
m7p5c6n:
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	11, NONE, 0
	N	1, Ds3, 79
	N	7, NONE, 0
	N	1, F_3, 79
	N	3, NONE, 0
	N	1, F_3, 79
	N	15, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As2, 79
	N	3, NONE, 0
	N	1, As2, 79
	N	3, NONE, 0
	.byte	0
m7p5c6v:
	V	8, 0
	V	1, 9
	V	43, 0
	V	1, 17
	V	7, 0
	V	1, 17
	V	3, 0
	.byte	0
m7p5c6x:
	X	64, 0x0, 0x00
	.byte	0
m7p5c6z:
m7p5c6e:
m7p5c7:	.word	m7p5c7v-m7p5c7n, m7p5c7v-m7p5c7n, m7p5c7x-m7p5c7n, m7p5c7z-m7p5c7n, m7p5c7e-m7p5c7n
m7p5c7n:
	N	1, B_4, 87
	N	2, NONE, 0
	N	1, As4, 87
	N	1, B_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, G_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, E_4, 87
	N	3, NONE, 0
	N	1, D_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	1, NONE, 0
	N	1, D_4, 87
	N	1, Ds4, 87
	N	1, E_4, 87
	N	1, NONE, 0
	.byte	0
m7p5c7v:
	V	22, 0
	V	1, 9
	V	15, 0
	V	1, 9
	V	2, 0
	V	1, 9
	V	17, 0
	V	1, 9
	V	3, 0
	V	1, 9
	.byte	0
m7p5c7x:
	X	4, 0x0, 0x00
	X	1, 0x3, 0x30
	X	1, 0x3, 0x00
	X	1, 0xA, 0x0F
	X	19, 0x0, 0x00
	X	1, 0x4, 0x82
	X	3, 0x4, 0x00
	X	2, 0x2, 0x0F
	X	18, 0x0, 0x00
	X	2, 0xA, 0x05
	X	9, 0x0, 0x00
	X	1, 0x1, 0x02
	X	1, 0x3, 0x30
	X	1, 0x0, 0x00
	.byte	0
m7p5c7z:
	.ascii	"PA"
m7p5c7e:
m7p6:
m7p6c0:	.word	m7p6c0v-m7p6c0n, m7p6c0v-m7p6c0n, m7p6c0x-m7p6c0n, m7p6c0z-m7p6c0n, m7p6c0e-m7p6c0n
m7p6c0n:
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	7, NONE, 0
	.byte	0
m7p6c0v:
	V	64, 0
	.byte	0
m7p6c0x:
	X	64, 0x0, 0x00
	.byte	0
m7p6c0z:
m7p6c0e:
m7p6c1:	.word	m7p6c1v-m7p6c1n, m7p6c1v-m7p6c1n, m7p6c1x-m7p6c1n, m7p6c1z-m7p6c1n, m7p6c1e-m7p6c1n
m7p6c1n:
	N	4, NONE, 0
	N	1, C_4, 74
	N	19, NONE, 0
	N	1, C_4, 75
	N	7, NONE, 0
	N	1, C_4, 76
	N	3, NONE, 0
	N	1, C_4, 76
	N	15, NONE, 0
	N	1, C_4, 77
	N	7, NONE, 0
	N	1, C_4, 78
	N	3, NONE, 0
	.byte	0
m7p6c1v:
	V	4, 0
	V	1, 9
	V	19, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	V	1, 9
	V	15, 0
	V	1, 9
	V	7, 0
	V	1, 9
	V	3, 0
	.byte	0
m7p6c1x:
	X	64, 0x0, 0x00
	.byte	0
m7p6c1z:
	.ascii	"P"
m7p6c1e:
m7p6c2:	.word	m7p6c2v-m7p6c2n, m7p6c2v-m7p6c2n, m7p6c2x-m7p6c2n, m7p6c2z-m7p6c2n, m7p6c2e-m7p6c2n
m7p6c2n:
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	5, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	1, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	N	1, C_4, 82
	N	3, NONE, 0
	.byte	0
m7p6c2v:
	V	14, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	23, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 25
	V	9, 0
	.byte	0
m7p6c2x:
	X	64, 0x0, 0x00
	.byte	0
m7p6c2z:
m7p6c2e:
m7p6c3:	.word	m7p6c3v-m7p6c3n, m7p6c3v-m7p6c3n, m7p6c3x-m7p6c3n, m7p6c3z-m7p6c3n, m7p6c3e-m7p6c3n
m7p6c3n:
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	7, NONE, 0
	N	1, C_4, 86
	N	3, NONE, 0
	N	1, C_4, 85
	N	3, NONE, 0
	.byte	0
m7p6c3v:
	V	12, 0
	V	1, 9
	V	31, 0
	V	1, 9
	V	19, 0
	.byte	0
m7p6c3x:
	X	64, 0x0, 0x00
	.byte	0
m7p6c3z:
m7p6c3e:
m7p6c4:	.word	m7p6c4v-m7p6c4n, m7p6c4v-m7p6c4n, m7p6c4x-m7p6c4n, m7p6c4z-m7p6c4n, m7p6c4e-m7p6c4n
m7p6c4n:
	N	1, F_4, 81
	N	63, NONE, 0
	.byte	0
m7p6c4v:
	V	64, 0
	.byte	0
m7p6c4x:
	X	64, 0x0, 0x00
	.byte	0
m7p6c4z:
	.ascii	"PA"
m7p6c4e:
m7p6c5:	.word	m7p6c5v-m7p6c5n, m7p6c5v-m7p6c5n, m7p6c5x-m7p6c5n, m7p6c5z-m7p6c5n, m7p6c5e-m7p6c5n
m7p6c5n:
	N	3, NONE, 0
	N	1, B_4, 87
	N	2, NONE, 0
	N	1, As4, 87
	N	1, B_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, G_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, E_4, 87
	N	3, NONE, 0
	N	1, D_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, B_4, 87
	N	1, NONE, 0
	N	1, D_5, 87
	.byte	0
m7p6c5v:
	V	1, 1
	V	2, 0
	V	1, 17
	V	2, 0
	V	2, 17
	V	3, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	5, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 9
	V	1, 0
	V	1, 17
	V	1, 9
	V	1, 17
	V	3, 0
	V	1, 17
	V	5, 0
	V	1, 17
	V	3, 0
	V	1, 17
	V	1, 0
	V	1, 17
	V	1, 9
	V	1, 17
	.byte	0
m7p6c5x:
	X	7, 0x0, 0x00
	X	1, 0x3, 0x30
	X	1, 0x3, 0x00
	X	1, 0xA, 0x0F
	X	19, 0x0, 0x00
	X	1, 0x4, 0x82
	X	3, 0x4, 0x00
	X	2, 0x2, 0x0F
	X	18, 0x0, 0x00
	X	2, 0xA, 0x05
	X	9, 0x0, 0x00
	.byte	0
m7p6c5z:
	.ascii	"PAD"
m7p6c5e:
m7p6c6:	.word	m7p6c6v-m7p6c6n, m7p6c6v-m7p6c6n, m7p6c6x-m7p6c6n, m7p6c6z-m7p6c6n, m7p6c6e-m7p6c6n
m7p6c6n:
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	3, NONE, 0
	N	1, C_3, 79
	N	11, NONE, 0
	N	1, Ds3, 79
	N	7, NONE, 0
	N	1, F_3, 79
	N	3, NONE, 0
	N	1, F_3, 79
	N	15, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As3, 79
	N	3, NONE, 0
	N	1, As2, 79
	N	3, NONE, 0
	N	1, As2, 79
	N	3, NONE, 0
	.byte	0
m7p6c6v:
	V	8, 0
	V	1, 9
	V	43, 0
	V	1, 17
	V	7, 0
	V	1, 17
	V	3, 0
	.byte	0
m7p6c6x:
	X	64, 0x0, 0x00
	.byte	0
m7p6c6z:
m7p6c6e:
m7p6c7:	.word	m7p6c7v-m7p6c7n, m7p6c7v-m7p6c7n, m7p6c7x-m7p6c7n, m7p6c7z-m7p6c7n, m7p6c7e-m7p6c7n
m7p6c7n:
	N	1, B_4, 87
	N	2, NONE, 0
	N	1, As4, 87
	N	1, B_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, G_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, E_4, 87
	N	3, NONE, 0
	N	1, D_4, 87
	N	1, NONE, 0
	N	1, E_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, G_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	5, NONE, 0
	N	1, A_4, 87
	N	3, NONE, 0
	N	1, A_4, 87
	N	1, NONE, 0
	N	1, B_4, 87
	N	1, NONE, 0
	N	1, D_5, 87
	N	1, NONE, 0
	N	1, E_5, 87
	N	1, NONE, 0
	.byte	0
m7p6c7v:
	V	22, 0
	V	1, 9
	V	15, 0
	V	1, 9
	V	2, 0
	V	1, 9
	V	17, 0
	V	1, 9
	V	3, 0
	V	1, 9
	.byte	0
m7p6c7x:
	X	4, 0x0, 0x00
	X	1, 0x3, 0x30
	X	1, 0x3, 0x00
	X	1, 0xA, 0x0F
	X	19, 0x0, 0x00
	X	1, 0x4, 0x82
	X	3, 0x4, 0x00
	X	2, 0x2, 0x0F
	X	18, 0x0, 0x00
	X	2, 0xA, 0x05
	X	10, 0x0, 0x00
	X	1, 0x3, 0x30
	X	1, 0x0, 0x00
	.byte	0
m7p6c7z:
	.ascii	"P"
m7p6c7e:

@ ==== module 8 @ 08042AE4 ==================================================
	.global gmp3Module8
gmp3Module8:
	.ascii	"GBAMOD30"
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	1, 0, 0, 5   @ channels, ?, ?, song length
@ instrument map (converter-side; not read by the player)
	.byte	0x00, 0x58, 0x59, 0x5A, 0x4D, 0x4E, 0x4F, 0x50, 0x51, 0x52, 0x53, 0x54, 0x55, 0x56, 0x57, 0x3E
	.byte	0x3F, 0x40, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.word	4, 64, 0, 120, 6   @ patterns, rows, Amiga periods, BPM, speed
@ order list (256 bytes, 0xFF-terminated; bytes after the end are converter leftovers)
	.byte	0x00, 0x01, 0x02, 0x01, 0x02, 0xFF, 0x03, 0x04, 0x05, 0x06, 0x05, 0x06, 0xFF, 0xFF, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
@ pattern offsets from m8_pat (256 words)
	.word	m8p0 - m8_pat
	.word	m8p1 - m8_pat
	.word	m8p2 - m8_pat
	.word	m8p3 - m8_pat
	.space	1008
	.word	0
m8_pat:
m8p0:
m8p0c0:	.word	m8p0c0v-m8p0c0n, m8p0c0v-m8p0c0n, m8p0c0x-m8p0c0n, m8p0c0z-m8p0c0n, m8p0c0e-m8p0c0n
m8p0c0n:
	N	1, C_4, 88
	N	23, NONE, 0
	N	1, C_4, 88
	N	17, NONE, 0
	N	1, C_4, 90
	N	21, NONE, 0
	.byte	0
m8p0c0v:
	V	64, 0
	.byte	0
m8p0c0x:
	X	47, 0x0, 0x00
	X	1, 0xD, 0x00
	X	16, 0x0, 0x00
	.byte	0
m8p0c0z:
m8p0c0e:
m8p1:
m8p1c0:	.word	m8p1c0v-m8p1c0n, m8p1c0v-m8p1c0n, m8p1c0x-m8p1c0n, m8p1c0z-m8p1c0n, m8p1c0e-m8p1c0n
m8p1c0n:
	N	1, C_4, 89
	N	23, NONE, 0
	N	1, C_4, 89
	N	39, NONE, 0
	.byte	0
m8p1c0v:
	V	64, 0
	.byte	0
m8p1c0x:
	X	47, 0x0, 0x00
	X	1, 0xD, 0x00
	X	16, 0x0, 0x00
	.byte	0
m8p1c0z:
	.ascii	"PA"
m8p1c0e:
m8p2:
m8p2c0:	.word	m8p2c0v-m8p2c0n, m8p2c0v-m8p2c0n, m8p2c0x-m8p2c0n, m8p2c0z-m8p2c0n, m8p2c0e-m8p2c0n
m8p2c0n:
	N	1, C_4, 89
	N	23, NONE, 0
	N	1, C_4, 89
	N	17, NONE, 0
	N	1, C_4, 90
	N	21, NONE, 0
	.byte	0
m8p2c0v:
	V	64, 0
	.byte	0
m8p2c0x:
	X	47, 0x0, 0x00
	X	1, 0xD, 0x00
	X	16, 0x0, 0x00
	.byte	0
m8p2c0z:
m8p2c0e:
m8p3:
m8p3c0:	.word	m8p3c0v-m8p3c0n, m8p3c0v-m8p3c0n, m8p3c0x-m8p3c0n, m8p3c0z-m8p3c0n, m8p3c0e-m8p3c0n
m8p3c0n:
	N	1, C_4, 89
	N	23, NONE, 0
	N	1, C_4, 89
	N	39, NONE, 0
	.byte	0
m8p3c0v:
	V	64, 0
	.byte	0
m8p3c0x:
	X	47, 0x0, 0x00
	X	1, 0xD, 0x00
	X	16, 0x0, 0x00
	.byte	0
m8p3c0z:
	.ascii	"PA"
m8p3c0e:

@ ==== sample bank (gmpLoadSampleBank) ======================================
@ 256 x {u16 length, finetune, volume, loopStart, loopLen, relNote}, then 8-bit PCM
	.global gmp3SampleBank
gmp3SampleBank:                                       @ 080431FC
	.macro SMP len, fine, vol, ls, ll, rel
	.hword \len, \fine, \vol, \ls, \ll, \rel
	.endm
	SMP	2518, 0, 64, 0, 0, 4   @ slot 0 (instrument 1)
	SMP	2529, 0, 64, 0, 0, 4   @ slot 1 (instrument 2)
	SMP	2515, 0, 64, 0, 0, 4   @ slot 2 (instrument 3)
	SMP	5046, 0, 64, 0, 0, 4   @ slot 3 (instrument 4)
	SMP	5046, 0, 64, 0, 0, 4   @ slot 4 (instrument 5)
	SMP	5046, 0, 64, 0, 0, 4   @ slot 5 (instrument 6)
	SMP	5046, 0, 64, 0, 0, 4   @ slot 6 (instrument 7)
	SMP	24036, 112, 64, 0, 0, 3   @ slot 7 (instrument 8)
	SMP	3412, 112, 64, 0, 0, 3   @ slot 8 (instrument 9)
	SMP	23934, 112, 64, 0, 0, 3   @ slot 9 (instrument 10)
	SMP	3006, 112, 64, 0, 0, 3   @ slot 10 (instrument 11)
	SMP	13347, 112, 64, 10290, 3057, 7   @ slot 11 (instrument 12)
	SMP	21551, 112, 64, 0, 0, 3   @ slot 12 (instrument 13)
	SMP	23960, 112, 64, 0, 0, 3   @ slot 13 (instrument 14)
	SMP	7864, 112, 64, 0, 0, 3   @ slot 14 (instrument 15)
	SMP	7847, 112, 64, 0, 0, 3   @ slot 15 (instrument 16)
	SMP	7916, 112, 64, 0, 0, 3   @ slot 16 (instrument 17)
	SMP	7870, 112, 64, 0, 0, 3   @ slot 17 (instrument 18)
	SMP	22097, 112, 64, 0, 0, 3   @ slot 18 (instrument 19)
	SMP	9403, 112, 64, 0, 0, 3   @ slot 19 (instrument 20)
	SMP	9341, 112, 64, 0, 0, 3   @ slot 20 (instrument 21)
	SMP	31567, 112, 64, 0, 0, 3   @ slot 21 (instrument 22)
	SMP	7823, 112, 64, 0, 0, 3   @ slot 22 (instrument 23)
	SMP	5046, 112, 64, 0, 0, 4   @ slot 23 (instrument 24)
	SMP	5046, 112, 64, 0, 0, 4   @ slot 24 (instrument 25)
	SMP	5046, 112, 64, 0, 0, 4   @ slot 25 (instrument 26)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 26 (instrument 27)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 27 (instrument 28)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 28 (instrument 29)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 29 (instrument 30)
	SMP	5045, 112, 48, 0, 0, 3   @ slot 30 (instrument 31)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 31 (instrument 32)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 32 (instrument 33)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 33 (instrument 34)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 34 (instrument 35)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 35 (instrument 36)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 36 (instrument 37)
	SMP	5046, 112, 48, 0, 0, 3   @ slot 37 (instrument 38)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 38 (instrument 39)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 39 (instrument 40)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 40 (instrument 41)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 41 (instrument 42)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 42 (instrument 43)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 43 (instrument 44)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 44 (instrument 45)
	SMP	2523, 0, 64, 0, 0, 4   @ slot 45 (instrument 46)
	SMP	5046, 0, 64, 0, 0, 4   @ slot 46 (instrument 47)
	SMP	5033, 0, 64, 0, 0, 4   @ slot 47 (instrument 48)
	SMP	5046, 16, 64, 519, 4526, 4   @ slot 48 (instrument 49)
	SMP	2518, 112, 64, 0, 0, 3   @ slot 49 (instrument 50)
	SMP	2529, 112, 64, 0, 0, 3   @ slot 50 (instrument 51)
	SMP	2510, 112, 64, 0, 0, 3   @ slot 51 (instrument 52)
	SMP	0, 112, 64, 0, 0, 10   @ slot 52 (instrument 53)
	SMP	0, 0, 0, 0, 0, 0   @ slot 53 (instrument 54)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 54 (instrument 55)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 55 (instrument 56)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 56 (instrument 57)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 57 (instrument 58)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 58 (instrument 59)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 59 (instrument 60)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 60 (instrument 61)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 61 (instrument 62)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 62 (instrument 63)
	SMP	5047, 112, 64, 0, 0, 3   @ slot 63 (instrument 64)
	SMP	18909, 112, 64, 0, 0, 3   @ slot 64 (instrument 65)
	SMP	6305, 112, 64, 0, 0, 3   @ slot 65 (instrument 66)
	SMP	6303, 112, 64, 0, 0, 3   @ slot 66 (instrument 67)
	SMP	18925, 112, 64, 0, 0, 3   @ slot 67 (instrument 68)
	SMP	6307, 112, 64, 0, 0, 3   @ slot 68 (instrument 69)
	SMP	6306, 112, 64, 0, 0, 3   @ slot 69 (instrument 70)
	SMP	6409, 112, 64, 0, 0, 3   @ slot 70 (instrument 71)
	SMP	25220, 112, 64, 0, 0, 3   @ slot 71 (instrument 72)
	SMP	3132, 112, 64, 0, 0, 3   @ slot 72 (instrument 73)
	SMP	19776, 112, 50, 0, 0, 15   @ slot 73 (instrument 74)
	SMP	9568, 112, 50, 0, 0, 15   @ slot 74 (instrument 75)
	SMP	10368, 112, 50, 0, 0, 15   @ slot 75 (instrument 76)
	SMP	8689, 112, 50, 0, 0, 15   @ slot 76 (instrument 77)
	SMP	8448, 112, 50, 0, 0, 15   @ slot 77 (instrument 78)
	SMP	2730, 112, 23, 0, 0, 15   @ slot 78 (instrument 79)
	SMP	7149, 112, 16, 0, 0, 15   @ slot 79 (instrument 80)
	SMP	17024, 0, 47, 0, 0, 7   @ slot 80 (instrument 81)
	SMP	7048, 112, 64, 0, 0, 15   @ slot 81 (instrument 82)
	SMP	5505, 112, 64, 0, 0, 15   @ slot 82 (instrument 83)
	SMP	9424, 112, 64, 0, 0, 15   @ slot 83 (instrument 84)
	SMP	4728, 112, 64, 0, 0, 15   @ slot 84 (instrument 85)
	SMP	6536, 112, 64, 0, 0, 15   @ slot 85 (instrument 86)
	SMP	14167, 16, 31, 4592, 9539, 0   @ slot 86 (instrument 87)
	SMP	45864, 48, 64, 0, 0, 10   @ slot 87 (instrument 88)
	SMP	45864, 48, 64, 0, 0, 10   @ slot 88 (instrument 89)
	SMP	11335, 48, 64, 0, 0, 10   @ slot 89 (instrument 90)
	.space	1992
	.incbin	"gbamod3_samples.bin"
