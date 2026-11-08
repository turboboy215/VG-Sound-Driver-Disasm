@ MusyX GBA driver read-only data, Earthworm Jim 2 (E)
@ reassembles byte-identically: see build notes in musyx_ewj2.s
.syntax unified

.section .rodata.psgfreq,"a"
@ 0x08725BCE: DMG square/wave frequency register values, indexed by (MIDI note mod 84).
@ index 36..83 = MIDI 36..83 (C2..B5), index 0..35 = MIDI 84..119 (C6..B8). value -> 131072/(2048-x) Hz
.global psg_FreqTable
psg_FreqTable:
	.hword 1922	@ idx  0
	.hword 1929	@ idx  1
	.hword 1936	@ idx  2
	.hword 1942	@ idx  3
	.hword 1948	@ idx  4
	.hword 1954	@ idx  5
	.hword 1959	@ idx  6
	.hword 1964	@ idx  7
	.hword 1969	@ idx  8
	.hword 1973	@ idx  9
	.hword 1977	@ idx 10
	.hword 1981	@ idx 11
	.hword 1985	@ idx 12
	.hword 1988	@ idx 13
	.hword 1992	@ idx 14
	.hword 1995	@ idx 15
	.hword 1998	@ idx 16
	.hword 2001	@ idx 17
	.hword 2003	@ idx 18
	.hword 2006	@ idx 19
	.hword 2008	@ idx 20
	.hword 2010	@ idx 21
	.hword 2012	@ idx 22
	.hword 2014	@ idx 23
	.hword 2016	@ idx 24
	.hword 2018	@ idx 25
	.hword 2020	@ idx 26
	.hword 2021	@ idx 27
	.hword 2023	@ idx 28
	.hword 2024	@ idx 29
	.hword 2025	@ idx 30
	.hword 2027	@ idx 31
	.hword 2028	@ idx 32
	.hword 2029	@ idx 33
	.hword 2030	@ idx 34
	.hword 2031	@ idx 35
	.hword   44	@ idx 36
	.hword  156	@ idx 37
	.hword  262	@ idx 38
	.hword  362	@ idx 39
	.hword  457	@ idx 40
	.hword  546	@ idx 41
	.hword  630	@ idx 42
	.hword  710	@ idx 43
	.hword  785	@ idx 44
	.hword  856	@ idx 45
	.hword  923	@ idx 46
	.hword  986	@ idx 47
	.hword 1046	@ idx 48
	.hword 1102	@ idx 49
	.hword 1155	@ idx 50
	.hword 1205	@ idx 51
	.hword 1252	@ idx 52
	.hword 1297	@ idx 53
	.hword 1339	@ idx 54
	.hword 1379	@ idx 55
	.hword 1416	@ idx 56
	.hword 1452	@ idx 57
	.hword 1485	@ idx 58
	.hword 1517	@ idx 59
	.hword 1547	@ idx 60
	.hword 1575	@ idx 61
	.hword 1601	@ idx 62
	.hword 1626	@ idx 63
	.hword 1650	@ idx 64
	.hword 1672	@ idx 65
	.hword 1693	@ idx 66
	.hword 1713	@ idx 67
	.hword 1732	@ idx 68
	.hword 1750	@ idx 69
	.hword 1766	@ idx 70
	.hword 1782	@ idx 71
	.hword 1797	@ idx 72
	.hword 1811	@ idx 73
	.hword 1824	@ idx 74
	.hword 1837	@ idx 75
	.hword 1849	@ idx 76
	.hword 1860	@ idx 77
	.hword 1870	@ idx 78
	.hword 1880	@ idx 79
	.hword 1890	@ idx 80
	.hword 1899	@ idx 81
	.hword 1907	@ idx 82
	.hword 1915	@ idx 83

.section .rodata.musyx,"a"
@ 0x087FFC68
.global psg_FreqRegs
psg_FreqRegs:	@ SOUND1CNT_X, SOUND2CNT_H, SOUND3CNT_X, SOUND4CNT_H
	.word 0x04000064
	.word 0x0400006C
	.word 0x04000074
	.word 0x0400007C
.global psg_EnvRegs
psg_EnvRegs:	@ SOUND1CNT_H, SOUND2CNT_L, SOUND3CNT_H, SOUND4CNT_L
	.word 0x04000062
	.word 0x04000068
	.word 0x04000072
	.word 0x04000078
.global psg_WaveVolTable
psg_WaveVolTable:	@ (volume>>3) -> SOUND3CNT_H bits 13-15 (0=mute,0x20=100%,0x40=50%,0x60=25%,0x80=75%)
	.byte 0x00, 0x60, 0x60, 0x60, 0x40, 0x40, 0x40, 0x40, 0x80, 0x80, 0x80, 0x80, 0x20, 0x20, 0x20, 0x20
.global pulse_SampleHeader
pulse_SampleHeader:	@ pseudo sample header used by PULSESWEEP/PULSEVEL (len 0x80, no loop, 8376 Hz, root 48)
	.word 0x00000080
	.word 0xFFFFFFFF
	.word 0x003020B8
	.word 0x00000000
.global pulse_SquareData
pulse_SquareData:	@ 64 x +127 then 64 x -128; a 64-byte window into this gives the duty cycle
	.byte 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F
	.byte 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F
	.byte 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F
	.byte 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F, 0x7F
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
	.byte 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80, 0x80
.global pitch_UpTable
pitch_UpTable:	@ 2^(n/12) in 4.12 fixed point, n=0..127
	.hword  4096,  4339,  4597,  4870,  5160,  5467,  5792,  6137	@ 0
	.hword  6501,  6888,  7298,  7732,  8192,  8679,  9195,  9741	@ 8
	.hword 10321, 10935, 11585, 12274, 13003, 13777, 14596, 15464	@ 16
	.hword 16384, 17358, 18390, 19483, 20642, 21870, 23170, 24548	@ 24
	.hword 26007, 27554, 29192, 30928, 32768, 34716, 36780, 38967	@ 32
	.hword 41285, 43740, 46340, 49096, 52015, 55109, 58385, 61857	@ 40
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 48
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 56
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 64
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 72
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 80
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 88
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 96
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 104
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 112
	.hword 65535, 65535, 65535, 65535, 65535, 65535, 65535, 65535	@ 120
.global pitch_DownTable
pitch_DownTable:	@ 2^(-n/12) in 4.12 fixed point, n=0..127
	.hword  4096,  3866,  3649,  3444,  3250,  3068,  2896,  2733	@ 0
	.hword  2580,  2435,  2298,  2169,  2048,  1933,  1824,  1722	@ 8
	.hword  1625,  1534,  1448,  1366,  1290,  1217,  1149,  1084	@ 16
	.hword  1024,   966,   912,   861,   812,   767,   724,   683	@ 24
	.hword   645,   608,   574,   542,   512,   483,   456,   430	@ 32
	.hword   406,   383,   362,   341,   322,   304,   287,   271	@ 40
	.hword   256,   241,   228,   215,   203,   191,   181,   170	@ 48
	.hword   161,   152,   143,   135,   128,   120,   114,   107	@ 56
	.hword   101,    95,    90,    85,    80,    76,    71,    67	@ 64
	.hword    64,    60,    57,    53,    50,    47,    45,    42	@ 72
	.hword    40,    38,    35,    33,    32,    30,    28,    26	@ 80
	.hword    25,    23,    22,    21,    20,    19,    17,    16	@ 88
	.hword    16,    15,    14,    13,    12,    11,    11,    10	@ 96
	.hword    10,     9,     8,     8,     8,     7,     7,     6	@ 104
	.hword     6,     5,     5,     5,     5,     4,     4,     4	@ 112
	.hword     4,     3,     3,     3,     3,     2,     2,     2	@ 120
.global macro_OpTable
macro_OpTable:	@ 54 handlers, Thumb (bit 0 set)
	.word 0x080655B1	@ 0x00 END
	.word 0x080655B1	@ 0x01 STOP
	.word 0x08065631	@ 0x02 VOLUME
	.word 0x0806697D	@ 0x03 KEYON
	.word 0x08065799	@ 0x04 WAIT
	.word 0x08065701	@ 0x05 SILENCE
	.word 0x080658E9	@ 0x06 LOOP
	.word 0x080669CD	@ 0x07 PANNING
	.word 0x08065A41	@ 0x08 SETPITCH
	.word 0x08065AB1	@ 0x09 ADDPITCH
	.word 0x08066A21	@ 0x0A VIBRATO
	.word 0x08066A41	@ 0x0B PITCHSWEEP
	.word 0x08066A65	@ 0x0C PORTAMENTO
	.word 0x08066A8D	@ 0x0D GOTO
	.word 0x08066AA1	@ 0x0E SETADSR
	.word 0x08065C45	@ 0x0F STARTSAMPLE
	.word 0x08066ADD	@ 0x10 TRAPKEYOFF
	.word 0x08066AF5	@ 0x11 UNTRAPKEYOFF
	.word 0x08065CE9	@ 0x12 SAMPLEREGION
	.word 0x08065DD9	@ 0x13 PULSESWEEP
	.word 0x08065EF1	@ 0x14 PULSEVEL
	.word 0x08066B05	@ 0x15 FADE
	.word 0x08066031	@ 0x16 RNDPITCH
	.word 0x08066B25	@ 0x17 SPLITKEY
	.word 0x08066B69	@ 0x18 SPLITVEL
	.word 0x08066BAD	@ 0x19 SPLITRND
	.word 0x080660F5	@ 0x1A MODOFF
	.word 0x08066205	@ 0x1B MODRESET
	.word 0x080662A5	@ 0x1C LASTNOTE
	.word 0x08066341	@ 0x1D KEYMAP
	.word 0x08066461	@ 0x1E PLAYMACRO
	.word 0x08066BE1	@ 0x1F NOP
	.word 0x08066BED	@ 0x20 PSGDUTY
	.word 0x08066C35	@ 0x21 NOISEPARAM
	.word 0x08066C55	@ 0x22 SENDKEYOFF
	.word 0x08066C91	@ 0x23 KEYOFFMACRO
	.word 0x08066CDD	@ 0x24 PSGENV
	.word 0x08066D05	@ 0x25 PSGENVOFF
	.word 0x08066D41	@ 0x26 SETPRIO
	.word 0x08066D8D	@ 0x27 ADDPRIO
	.word 0x08066DF9	@ 0x28 SETAGE
	.word 0x08066E31	@ 0x29 ADDAGE
	.word 0x08066E85	@ 0x2A SETFLAG
	.word 0x08066EC9	@ 0x2B IFFLAG
	.word 0x08066EFD	@ 0x2C REVERB
	.word 0x080666D5	@ 0x2D PANSWEEP
	.word 0x08066F49	@ 0x2E KEYOFF
	.word 0x08066741	@ 0x2F SCALEVOL
	.word 0x080667F1	@ 0x30 LOOPSCAN
	.word 0x08066885	@ 0x31 SETWAVE
	.word 0x08066FA9	@ 0x32 PORTAFROMLAST
	.word 0x08066FC9	@ 0x33 ADDLOOPLEN
	.word 0x08067041	@ 0x34 AGESPEED
	.word 0x08067071	@ 0x35 SETLOOPLEN
