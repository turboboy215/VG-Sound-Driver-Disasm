@ ============================================================================
@ et_sound_data.s -- music data of E.T.: The Extra-Terrestrial (GBA, 2001)
@ Sound driver and music by Mark Cooksey.  Reconstructed from the ROM
@ "E.T. - The Extra-Terrestrial (E) (M6).gba"; links at 0x08016790 and
@ reassembles byte-for-byte to ROM 0x08016790-0x08027AF0 (70 496 bytes).
@ The two music samples are pulled in from et_music_samples.bin.
@ The WAV sound-effect table (0x080284FC) is in section .sfxtable at the end.
@ See ET_Sound_Engine_Technical_Reference.md for the formats.
@ ============================================================================

	.syntax unified

@ ---- sequence (order list) commands: 32-bit words
	.macro SEQ_PAT pat, transpose=0, repeat=1
	.word 0x64, \pat, \transpose, \repeat
	.endm
	.macro SEQ_JUMP index
	.word 0x62, \index
	.endm
	.macro SEQ_END
	.word 0x61
	.endm
	.macro SEQ_PAN v		@ global panning: v = PSG L/R enables (SOUNDCNT_L bits 8-15, = GB NR51)
	.word 0x67, \v
	.endm
	.macro SEQ_TEMPO t
	.word 0x69, \t
	.endm
	.macro SEQ_CONDFLAG v	@ conditional (end-of-song) flag for the game; not read by the driver
	.word 0x66, \v
	.endm
@ ---- pattern events: 3 bytes {note, instrument, length index}; 0x65 ends
	.macro N note, inst, len
	.byte \note, \inst, \len
	.endm
	.macro REST inst, len
	.byte 0x60, \inst, \len
	.endm
	.macro PAT_END
	.byte 0x65
	.endm
@ ---- instrument: 9 words
	.macro INSTRUMENT b0, lo, hi, envOn, env, pitchOn, pitch, arpOn, arp
	.word \b0, \lo, \hi, \envOn, \env, \pitchOn, \pitch, \arpOn, \arp
	.endm

	.text
	.balign 4

@ mcSmpNoteTable: 96 x {sampleRate Hz, samplesPerFrame, timerPeriod (cycles)}
@ used only by the DirectSound music channels 5/6; entries 0-23 are dummies, 84-95 clamp
	.global mcSmpNoteTable
mcSmpNoteTable:
	.word	    10,    10,    10	@ note  0
	.word	    10,    10,    10	@ note  1
	.word	    10,    10,    10	@ note  2
	.word	    10,    10,    10	@ note  3
	.word	    10,    10,    10	@ note  4
	.word	    10,    10,    10	@ note  5
	.word	    10,    10,    10	@ note  6
	.word	    10,    10,    10	@ note  7
	.word	    10,    10,    10	@ note  8
	.word	    10,    10,    10	@ note  9
	.word	    10,    10,    10	@ note 10
	.word	    10,    10,    10	@ note 11
	.word	    10,    10,    10	@ note 12
	.word	    10,    10,    10	@ note 13
	.word	    10,    10,    10	@ note 14
	.word	    10,    10,    10	@ note 15
	.word	    10,    10,    10	@ note 16
	.word	    10,    10,    10	@ note 17
	.word	    10,    10,    10	@ note 18
	.word	    10,    10,    10	@ note 19
	.word	    10,    10,    10	@ note 20
	.word	    10,    10,    10	@ note 21
	.word	    10,    10,    10	@ note 22
	.word	    10,    10,    10	@ note 23
	.word	  2756,    45,  6087	@ note 24
	.word	  2919,    48,  5747	@ note 25
	.word	  3093,    51,  5424	@ note 26
	.word	  3277,    54,  5119	@ note 27
	.word	  3471,    57,  4833	@ note 28
	.word	  3679,    61,  4560	@ note 29
	.word	  3898,    64,  4304	@ note 30
	.word	  4132,    68,  4060	@ note 31
	.word	  4374,    72,  3835	@ note 32
	.word	  4634,    77,  3620	@ note 33
	.word	  4910,    81,  3416	@ note 34
	.word	  5202,    86,  3225	@ note 35
	.word	  5512,    91,  3043	@ note 36
	.word	  5838,    97,  2873	@ note 37
	.word	  6186,   103,  2712	@ note 38
	.word	  6554,   109,  2559	@ note 39
	.word	  6943,   115,  2416	@ note 40
	.word	  7359,   122,  2279	@ note 41
	.word	  7795,   129,  2152	@ note 42
	.word	  8263,   137,  2030	@ note 43
	.word	  8747,   145,  1918	@ note 44
	.word	  9268,   154,  1810	@ note 45
	.word	  9820,   163,  1708	@ note 46
	.word	 10404,   173,  1612	@ note 47
	.word	 11025,   183,  1521	@ note 48
	.word	 11677,   194,  1436	@ note 49
	.word	 12372,   206,  1356	@ note 50
	.word	 13108,   218,  1279	@ note 51
	.word	 13886,   231,  1208	@ note 52
	.word	 14718,   245,  1139	@ note 53
	.word	 15591,   259,  1076	@ note 54
	.word	 16527,   275,  1015	@ note 55
	.word	 17495,   291,   958	@ note 56
	.word	 18536,   308,   905	@ note 57
	.word	 19641,   327,   854	@ note 58
	.word	 20809,   346,   806	@ note 59
	.word	 22050,   367,   760	@ note 60
	.word	 23354,   389,   718	@ note 61
	.word	 24744,   412,   678	@ note 62
	.word	 26216,   436,   639	@ note 63
	.word	 27772,   462,   604	@ note 64
	.word	 29436,   490,   569	@ note 65
	.word	 31182,   519,   538	@ note 66
	.word	 33054,   550,   507	@ note 67
	.word	 34990,   583,   479	@ note 68
	.word	 37072,   617,   452	@ note 69
	.word	 39282,   654,   427	@ note 70
	.word	 41618,   693,   403	@ note 71
	.word	 44100,   735,   380	@ note 72
	.word	 46708,   778,   359	@ note 73
	.word	 49488,   824,   339	@ note 74
	.word	 52432,   873,   319	@ note 75
	.word	 55544,   925,   302	@ note 76
	.word	 58872,   981,   284	@ note 77
	.word	 62364,  1039,   269	@ note 78
	.word	 66108,  1101,   253	@ note 79
	.word	 69980,  1166,   239	@ note 80
	.word	 74144,  1235,   226	@ note 81
	.word	 78564,  1309,   213	@ note 82
	.word	 83236,  1387,   201	@ note 83
	.word	 88200,  1470,   190	@ note 84
	.word	 88200,  1470,   190	@ note 85
	.word	 88200,  1470,   190	@ note 86
	.word	 88200,  1470,   190	@ note 87
	.word	 88200,  1470,   190	@ note 88
	.word	 88200,  1470,   190	@ note 89
	.word	 88200,  1470,   190	@ note 90
	.word	 88200,  1470,   190	@ note 91
	.word	 88200,  1470,   190	@ note 92
	.word	 88200,  1470,   190	@ note 93
	.word	 88200,  1470,   190	@ note 94
	.word	 88200,  1470,   190	@ note 95

@ the two music samples: 8-bit signed PCM, native rate 11025 Hz (note 48)
	.global smp0_pcm
smp0_pcm:				@ 08016C10, 5688 bytes
	.incbin "et_music_samples.bin", 0, 5688
	.global smp1_pcm
smp1_pcm:				@ 08018248, 9088 bytes
	.incbin "et_music_samples.bin", 5688, 9088

@ mcDsSfxTable: 90 x 16 bytes {addr, frames, loopFrames, length} -- all zero in E.T.
@ (read only by the unused mcDsSfxStart / stream-player code)
	.global mcDsSfxTable
mcDsSfxTable:
	.space	0x5A0

@ mcSmpInstTable: instrument number on channels 5/6 -> {PCM address, length in bytes}
	.global mcSmpInstTable
mcSmpInstTable:
	.word	smp0_pcm, 0x1638
	.word	smp1_pcm, 0x2380

@ mcPsgSfxMap: PSG sound effect n -> 4 script numbers (one per PSG channel, 0xFF = none)
@ PSG sound effects are never triggered in E.T. (mcPlayPsgSfx has no callers)
	.global mcPsgSfxMap
mcPsgSfxMap:
	.byte	0x00, 0x01, 0x02, 0x03	@ psg sfx 0
	.byte	0x04, 0xFF, 0xFF, 0xFF	@ psg sfx 1
	.byte	0x05, 0xFF, 0xFF, 0xFF	@ psg sfx 2
	.byte	0x06, 0x07, 0x08, 0xFF	@ psg sfx 3
	.byte	0x09, 0x0A, 0x0B, 0xFF	@ psg sfx 4
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 5
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 6
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 7
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 8
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 9
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 10
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 11
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 12
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 13
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 14
	.byte	0x00, 0x00, 0x00, 0x00	@ psg sfx 15

@ PSG SFX scripts: u16 channel, then 5-halfword records {frames, v1lo, v1hi, v2hi, v2lo}
@ v1 -> SOUNDnCNT_L/H (envelope/duty), v2 -> SOUNDnCNT_X/H (frequency + restart)
@ frames 0xFF = end; 0xFE,0xFD = end; 0xFE,n = jump to halfword n of the script
psgScript_09:				@ 0801ABB8  channel 0
	.hword	0
	.hword	0x0005, 0x0080, 0x00A1, 0x0084, 0x00B6
	.hword	0x0005, 0x0080, 0x00A1, 0x0085, 0x0012
	.hword	0x0005, 0x0080, 0x00A1, 0x0085, 0x0064
	.hword	0x0005, 0x0080, 0x00A1, 0x0085, 0x00CE
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x005B
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x0089
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x00B2
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x00E7
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x002E
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0045
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0059
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0074
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0097
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00A3
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00AD
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00BA
	.hword	0x000A, 0x0080, 0x00A3, 0x0087, 0x00BA
	.hword	0x000A, 0x0080, 0x00A3, 0x0086, 0x00E7
	.hword	0x003C, 0x0080, 0x00A7, 0x0087, 0x0074
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_10:				@ 0801ACA8  channel 1
	.hword	1
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00BA
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00AD
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00A3
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0097
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0074
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0059
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x0045
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x002E
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x00E7
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x00B2
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x0089
	.hword	0x0005, 0x0080, 0x00A1, 0x0086, 0x005B
	.hword	0x0005, 0x0080, 0x00A1, 0x0085, 0x00CE
	.hword	0x0005, 0x0080, 0x00A1, 0x0085, 0x0064
	.hword	0x0005, 0x0080, 0x00A1, 0x0085, 0x0012
	.hword	0x0005, 0x0080, 0x00A1, 0x0084, 0x00B6
	.hword	0x000A, 0x0080, 0x00A3, 0x0087, 0x00AD
	.hword	0x000A, 0x0080, 0x00A3, 0x0086, 0x00B2
	.hword	0x003C, 0x0080, 0x00A7, 0x0087, 0x0059
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_11:				@ 0801AD98  channel 2
	.hword	2
	.hword	0x0014, 0x0000, 0x0020, 0x0084, 0x00B6
	.hword	0x0014, 0x0000, 0x0020, 0x0085, 0x0012
	.hword	0x0014, 0x0000, 0x0020, 0x0085, 0x0064
	.hword	0x0014, 0x0000, 0x0020, 0x0085, 0x00CE
	.hword	0x000A, 0x0000, 0x0020, 0x0086, 0x005B
	.hword	0x000A, 0x0000, 0x0020, 0x0086, 0x00E7
	.hword	0x0014, 0x0000, 0x0020, 0x0087, 0x002E
	.hword	0x0014, 0x0000, 0x0080, 0x0087, 0x002E
	.hword	0x000A, 0x0000, 0x0040, 0x0087, 0x002E
	.hword	0x000A, 0x0000, 0x0060, 0x0087, 0x002E
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_06:				@ 0801AE10  channel 0
	.hword	0
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0014
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x002E
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0045
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0063
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x008A
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0097
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x00A3
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0097
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x008A
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0063
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0045
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0014
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x002E
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0045
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0059
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0074
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0097
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x00A3
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x00AD
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x00A3
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0097
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0074
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0059
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x002E
	.hword	0x003C, 0x0080, 0x00A7, 0x0087, 0x0045
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_07:				@ 0801AF3C  channel 1
	.hword	1
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x0089
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x009E
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00C5
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0014
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0045
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x004F
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0063
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x004F
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0045
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0014
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00C5
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x0089
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00B2
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00C5
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00E7
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x002E
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0059
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0063
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0097
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x008A
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0059
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x002E
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00E7
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x00B2
	.hword	0x003C, 0x0080, 0x00A7, 0x0087, 0x006C
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_08:				@ 0801B068  channel 2
	.hword	2
	.hword	0x0030, 0x0000, 0x0080, 0x0084, 0x004F
	.hword	0x0030, 0x0000, 0x0080, 0x0086, 0x0028
	.hword	0x0030, 0x0000, 0x0080, 0x0084, 0x00B6
	.hword	0x0030, 0x0000, 0x0080, 0x0086, 0x005B
	.hword	0x0014, 0x0000, 0x0020, 0x0086, 0x0089
	.hword	0x0014, 0x0000, 0x0080, 0x0086, 0x0089
	.hword	0x000A, 0x0000, 0x0040, 0x0086, 0x0089
	.hword	0x000A, 0x0000, 0x0060, 0x0086, 0x0089
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_04:				@ 0801B0CC  channel 3
	.hword	3
	.hword	0x0014, 0x0000, 0x002A, 0x0080, 0x0021
	.hword	0x003C, 0x0000, 0x00C4, 0x0080, 0x0021
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000
psgScript_05:				@ 0801B0F4  channel 1
	.hword	1
	.hword	0x0006, 0x0080, 0x00C3, 0x0087, 0x0014
	.hword	0x0005, 0x0080, 0x00C3, 0x0087, 0x0045
	.hword	0x0004, 0x0080, 0x00C3, 0x0087, 0x0063
	.hword	0x0004, 0x0080, 0x00C3, 0x0087, 0x008A
	.hword	0x0003, 0x0080, 0x00C3, 0x0087, 0x00A3
	.hword	0x0003, 0x0080, 0x00C3, 0x0087, 0x00B1
	.hword	0x003C, 0x0080, 0x00C4, 0x0087, 0x00C5
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000
psgScript_00:				@ 0801B144  channel 0
	.hword	0
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
psgScript_01:				@ 0801B164  channel 1
	.hword	1
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
psgScript_02:				@ 0801B184  channel 2
	.hword	2
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
psgScript_03:				@ 0801B1A4  channel 3
	.hword	3
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

	.global mcPsgSfxScripts
mcPsgSfxScripts:
	.word	psgScript_00
	.word	psgScript_01
	.word	psgScript_02
	.word	psgScript_03
	.word	psgScript_04
	.word	psgScript_05
	.word	psgScript_06
	.word	psgScript_07
	.word	psgScript_08
	.word	psgScript_09
	.word	psgScript_10
	.word	psgScript_11
	.word	0x0
	.word	0x0
	.word	0x0
	.word	0x0

@ note-length tables (length index -> ticks); songtab word 6 selects one
durTable0:
	.word	  3,   4,   6,   9,  12,  18,  24,  36	@ [0..7]
	.word	 48,  72,  96, 144, 192,   8,  16,  32	@ [8..15]
	.word	 40,  64,  80,  84,  15,  54,  60,  42	@ [16..23]
	.word	 30, 108, 132, 156	@ [24..27]
durTable1:
	.word	  3,   4,   6,   9,  12,  18,  24,  36	@ [0..7]
	.word	 48,  72,  96, 144, 192,   8,  16,  32	@ [8..15]
	.word	 10,  40	@ [16..17]

@ ----------------------------------------------------------------------------
@ patterns: {note, instrument, length-index} events, 0x65 = end
@ note names assume table index 0 = C#2 (69.3 Hz) on the PSG channels;
@ on channels 5/6 the note selects a sample rate from mcSmpNoteTable instead
@ ----------------------------------------------------------------------------
pat_0801B2BC:				@ used by s8c1, s15c1
	N	60, 0, 10            @ C#7
	PAT_END
pat_0801B2C0:				@ used by s0c1, s0c2, s0c3, s0c4
	N	60, 0, 0             @ C#7
	PAT_END
pat_0801B2C4:				@ used by s15c5
	N	60, 0, 7             @ C#7
	N	67, 0, 19            @ G#7
	N	67, 0, 4             @ G#7
	N	69, 0, 4             @ A#7
	N	67, 0, 6             @ G#7
	N	64, 0, 6             @ F7
	N	66, 0, 7             @ G7
	N	57, 0, 27            @ A#6
	N	60, 0, 7             @ C#7
	N	72, 0, 19            @ C#8
	N	71, 0, 4             @ C8
	N	72, 0, 4             @ C#8
	N	71, 0, 6             @ C8
	N	67, 0, 6             @ G#7
	N	69, 0, 7             @ A#7
	N	62, 0, 27            @ D#7
	PAT_END
pat_0801B2F5:				@ used by s15c5
	N	65, 0, 7             @ F#7
	N	72, 0, 19            @ C#8
	N	74, 0, 6             @ D#8
	N	72, 0, 4             @ C#8
	N	71, 0, 4             @ C8
	N	69, 0, 6             @ A#7
	N	71, 0, 7             @ C8
	N	67, 0, 25            @ G#7
	N	67, 0, 4             @ G#7
	N	69, 0, 4             @ A#7
	N	71, 0, 6             @ C8
	N	69, 0, 7             @ A#7
	N	65, 0, 26            @ F#7
	N	60, 0, 6             @ C#7
	N	65, 0, 7             @ F#7
	N	72, 0, 19            @ C#8
	N	74, 0, 6             @ D#8
	N	72, 0, 4             @ C#8
	N	71, 0, 4             @ C8
	N	69, 0, 6             @ A#7
	N	71, 0, 7             @ C8
	N	67, 0, 25            @ G#7
	N	67, 0, 4             @ G#7
	N	69, 0, 4             @ A#7
	N	71, 0, 6             @ C8
	N	69, 0, 6             @ A#7
	N	64, 0, 4             @ F7
	N	69, 0, 4             @ A#7
	N	73, 0, 6             @ D8
	N	69, 0, 4             @ A#7
	N	73, 0, 4             @ D8
	N	76, 0, 6             @ F8
	N	73, 0, 4             @ D8
	N	76, 0, 4             @ F8
	N	81, 0, 8             @ A#8
	PAT_END
pat_0801B35F:				@ used by s15c5
	N	72, 0, 6             @ C#8
	N	72, 0, 4             @ C#8
	N	74, 0, 4             @ D#8
	N	72, 0, 4             @ C#8
	N	71, 0, 4             @ C8
	N	69, 0, 4             @ A#7
	N	72, 0, 4             @ C#8
	N	71, 0, 6             @ C8
	N	71, 0, 4             @ C8
	N	69, 0, 4             @ A#7
	N	67, 0, 4             @ G#7
	N	69, 0, 4             @ A#7
	N	71, 0, 4             @ C8
	N	67, 0, 4             @ G#7
	N	69, 0, 6             @ A#7
	N	65, 0, 6             @ F#7
	N	60, 0, 6             @ C#7
	N	65, 0, 6             @ F#7
	N	57, 0, 4             @ A#6
	N	58, 0, 4             @ B6
	N	60, 0, 6             @ C#7
	N	57, 0, 4             @ A#6
	N	58, 0, 4             @ B6
	N	60, 0, 6             @ C#7
	N	72, 0, 6             @ C#8
	N	72, 0, 4             @ C#8
	N	74, 0, 4             @ D#8
	N	72, 0, 4             @ C#8
	N	71, 0, 4             @ C8
	N	69, 0, 4             @ A#7
	N	72, 0, 4             @ C#8
	N	71, 0, 6             @ C8
	N	71, 0, 4             @ C8
	N	69, 0, 4             @ A#7
	N	67, 0, 6             @ G#7
	N	71, 0, 6             @ C8
	N	69, 0, 6             @ A#7
	N	65, 0, 6             @ F#7
	N	60, 0, 6             @ C#7
	N	65, 0, 6             @ F#7
	N	57, 0, 4             @ A#6
	N	58, 0, 4             @ B6
	N	60, 0, 4             @ C#7
	N	58, 0, 4             @ B6
	N	57, 0, 8             @ A#6
	N	71, 0, 6             @ C8
	N	71, 0, 4             @ C8
	N	72, 0, 4             @ C#8
	N	71, 0, 4             @ C8
	N	69, 0, 4             @ A#7
	N	67, 0, 4             @ G#7
	N	71, 0, 4             @ C8
	N	69, 0, 6             @ A#7
	N	69, 0, 4             @ A#7
	N	67, 0, 4             @ G#7
	N	65, 0, 6             @ F#7
	N	69, 0, 6             @ A#7
	N	67, 0, 6             @ G#7
	N	62, 0, 6             @ D#7
	N	59, 0, 4             @ C7
	N	60, 0, 4             @ C#7
	N	62, 0, 6             @ D#7
	N	59, 0, 4             @ C7
	N	60, 0, 4             @ C#7
	N	62, 0, 4             @ D#7
	N	64, 0, 4             @ F7
	N	62, 0, 4             @ D#7
	N	60, 0, 4             @ C#7
	N	59, 0, 6             @ C7
	N	71, 0, 6             @ C8
	N	71, 0, 4             @ C8
	N	72, 0, 4             @ C#8
	N	74, 0, 6             @ D#8
	N	72, 0, 4             @ C#8
	N	71, 0, 4             @ C8
	N	72, 0, 6             @ C#8
	N	69, 0, 6             @ A#7
	N	65, 0, 6             @ F#7
	N	69, 0, 6             @ A#7
	N	67, 0, 6             @ G#7
	N	62, 0, 4             @ D#7
	N	67, 0, 4             @ G#7
	N	71, 0, 6             @ C8
	N	67, 0, 4             @ G#7
	N	71, 0, 4             @ C8
	N	74, 0, 6             @ D#8
	N	71, 0, 4             @ C8
	N	74, 0, 4             @ D#8
	N	79, 0, 8             @ G#8
	PAT_END
pat_0801B46B:				@ used by s15c5
	N	60, 0, 8             @ C#7
	N	67, 0, 9             @ G#7
	N	66, 0, 4             @ G7
	N	67, 0, 4             @ G#7
	N	66, 0, 4             @ G7
	N	67, 0, 4             @ G#7
	N	62, 0, 6             @ D#7
	N	64, 0, 8             @ F7
	N	57, 0, 11            @ A#6
	N	60, 0, 8             @ C#7
	N	67, 0, 9             @ G#7
	N	66, 0, 4             @ G7
	N	67, 0, 4             @ G#7
	N	66, 0, 6             @ G7
	N	62, 0, 6             @ D#7
	N	64, 0, 8             @ F7
	N	57, 0, 10            @ A#6
	N	59, 0, 6             @ C7
	N	60, 0, 6             @ C#7
	N	62, 0, 8             @ D#7
	N	67, 0, 6             @ G#7
	N	69, 0, 6             @ A#7
	N	70, 0, 6             @ B7
	N	69, 0, 6             @ A#7
	N	67, 0, 6             @ G#7
	N	75, 0, 6             @ E8
	N	74, 0, 8             @ D#8
	N	72, 0, 6             @ C#8
	N	71, 0, 6             @ C8
	N	69, 0, 6             @ A#7
	N	71, 0, 6             @ C8
	N	67, 0, 8             @ G#7
	N	72, 0, 8             @ C#8
	N	70, 0, 6             @ B7
	N	68, 0, 6             @ A7
	N	70, 0, 8             @ B7
	N	68, 0, 6             @ A7
	N	67, 0, 6             @ G#7
	N	66, 0, 12            @ G7
	PAT_END
pat_0801B4E1:				@ used by s15c5
	N	79, 0, 7             @ G#8
	N	81, 0, 7             @ A#8
	N	83, 0, 6             @ C9
	N	74, 0, 9             @ D#8
	N	76, 0, 4             @ F8
	N	77, 0, 4             @ F#8
	N	77, 0, 6             @ F#8
	N	76, 0, 6             @ F8
	N	74, 0, 6             @ D#8
	N	72, 0, 6             @ C#8
	N	74, 0, 6             @ D#8
	N	72, 0, 6             @ C#8
	N	71, 0, 6             @ C8
	N	69, 0, 6             @ A#7
	N	71, 0, 6             @ C8
	N	67, 0, 6             @ G#7
	N	71, 0, 6             @ C8
	N	74, 0, 6             @ D#8
	N	79, 0, 6             @ G#8
	N	81, 0, 6             @ A#8
	N	83, 0, 6             @ C9
	N	81, 0, 4             @ A#8
	N	79, 0, 4             @ G#8
	N	74, 0, 8             @ D#8
	N	71, 0, 6             @ C8
	N	69, 0, 6             @ A#7
	N	67, 0, 10            @ G#7
	PAT_END
pat_0801B533:				@ used by s15c6
	N	55, 1, 7             @ G#6
	N	64, 1, 19            @ F7
	N	64, 1, 4             @ F7
	N	66, 1, 4             @ G7
	N	64, 1, 6             @ F7
	N	60, 1, 6             @ C#7
	N	62, 1, 7             @ D#7
	N	54, 1, 27            @ G6
	N	57, 1, 7             @ A#6
	N	69, 1, 19            @ A#7
	N	67, 1, 4             @ G#7
	N	69, 1, 4             @ A#7
	N	67, 1, 6             @ G#7
	N	60, 1, 6             @ C#7
	N	62, 1, 7             @ D#7
	N	59, 1, 27            @ C7
	PAT_END
pat_0801B564:				@ used by s15c6
	N	60, 1, 7             @ C#7
	N	69, 1, 19            @ A#7
	N	71, 1, 6             @ C8
	N	69, 1, 4             @ A#7
	N	67, 1, 4             @ G#7
	N	65, 1, 6             @ F#7
	N	67, 1, 7             @ G#7
	N	62, 1, 25            @ D#7
	N	62, 1, 4             @ D#7
	N	64, 1, 4             @ F7
	N	65, 1, 6             @ F#7
	N	65, 1, 7             @ F#7
	N	60, 1, 26            @ C#7
	N	57, 1, 6             @ A#6
	N	60, 1, 7             @ C#7
	N	69, 1, 19            @ A#7
	N	69, 1, 6             @ A#7
	N	67, 1, 4             @ G#7
	N	65, 1, 4             @ F#7
	N	60, 1, 6             @ C#7
	N	67, 1, 7             @ G#7
	N	62, 1, 25            @ D#7
	N	62, 1, 4             @ D#7
	N	65, 1, 4             @ F#7
	N	67, 1, 6             @ G#7
	N	64, 1, 6             @ F7
	N	61, 1, 4             @ D7
	N	64, 1, 4             @ F7
	N	69, 1, 6             @ A#7
	N	64, 1, 4             @ F7
	N	69, 1, 4             @ A#7
	N	73, 1, 6             @ D8
	N	69, 1, 4             @ A#7
	N	73, 1, 4             @ D8
	N	73, 1, 8             @ D8
	PAT_END
pat_0801B5CE:				@ used by s15c6
	N	65, 1, 6             @ F#7
	N	65, 1, 6             @ F#7
	N	65, 1, 8             @ F#7
	N	62, 1, 6             @ D#7
	N	62, 1, 6             @ D#7
	N	62, 1, 4             @ D#7
	N	62, 1, 4             @ D#7
	N	62, 1, 6             @ D#7
	N	60, 1, 6             @ C#7
	N	60, 1, 6             @ C#7
	N	57, 1, 6             @ A#6
	N	60, 1, 6             @ C#7
	N	53, 1, 4             @ F#6
	N	55, 1, 4             @ G#6
	N	57, 1, 6             @ A#6
	N	53, 1, 4             @ F#6
	N	55, 1, 4             @ G#6
	N	57, 1, 6             @ A#6
	N	65, 1, 6             @ F#7
	N	65, 1, 9             @ F#7
	N	62, 1, 6             @ D#7
	N	62, 1, 6             @ D#7
	N	62, 1, 8             @ D#7
	N	60, 1, 6             @ C#7
	N	60, 1, 6             @ C#7
	N	57, 1, 6             @ A#6
	N	60, 1, 6             @ C#7
	N	53, 1, 4             @ F#6
	N	55, 1, 4             @ G#6
	N	57, 1, 4             @ A#6
	N	55, 1, 4             @ G#6
	N	53, 1, 8             @ F#6
	N	62, 1, 6             @ D#7
	N	62, 1, 6             @ D#7
	N	62, 1, 6             @ D#7
	N	62, 1, 4             @ D#7
	N	62, 1, 4             @ D#7
	N	60, 1, 6             @ C#7
	N	60, 1, 6             @ C#7
	N	60, 1, 6             @ C#7
	N	60, 1, 6             @ C#7
	N	62, 1, 6             @ D#7
	N	59, 1, 6             @ C7
	N	55, 1, 4             @ G#6
	N	57, 1, 4             @ A#6
	N	59, 1, 6             @ C7
	N	55, 1, 4             @ G#6
	N	57, 1, 4             @ A#6
	N	59, 1, 4             @ C7
	N	60, 1, 4             @ C#7
	N	59, 1, 4             @ C7
	N	57, 1, 4             @ A#6
	N	55, 1, 6             @ G#6
	N	62, 1, 6             @ D#7
	N	62, 1, 4             @ D#7
	N	62, 1, 4             @ D#7
	N	62, 1, 6             @ D#7
	N	62, 1, 6             @ D#7
	N	69, 1, 6             @ A#7
	N	65, 1, 6             @ F#7
	N	60, 1, 6             @ C#7
	N	65, 1, 6             @ F#7
	N	62, 1, 6             @ D#7
	N	59, 1, 4             @ C7
	N	62, 1, 4             @ D#7
	N	67, 1, 6             @ G#7
	N	62, 1, 4             @ D#7
	N	67, 1, 4             @ G#7
	N	71, 1, 6             @ C8
	N	67, 1, 4             @ G#7
	N	67, 1, 4             @ G#7
	N	71, 1, 8             @ C8
	PAT_END
pat_0801B6A7:				@ used by s15c6
	N	48, 1, 8             @ C#6
	N	55, 1, 9             @ G#6
	N	54, 1, 4             @ G6
	N	55, 1, 4             @ G#6
	N	54, 1, 4             @ G6
	N	55, 1, 4             @ G#6
	N	50, 1, 6             @ D#6
	N	52, 1, 8             @ F6
	N	45, 1, 11            @ A#5
	N	48, 1, 8             @ C#6
	N	55, 1, 9             @ G#6
	N	54, 1, 4             @ G6
	N	55, 1, 4             @ G#6
	N	54, 1, 6             @ G6
	N	50, 1, 6             @ D#6
	N	52, 1, 8             @ F6
	N	45, 1, 10            @ A#5
	N	47, 1, 6             @ C6
	N	48, 1, 6             @ C#6
	N	50, 1, 8             @ D#6
	N	55, 1, 6             @ G#6
	N	57, 1, 6             @ A#6
	N	58, 1, 6             @ B6
	N	57, 1, 6             @ A#6
	N	55, 1, 6             @ G#6
	N	63, 1, 6             @ E7
	N	62, 1, 8             @ D#7
	N	60, 1, 6             @ C#7
	N	59, 1, 6             @ C7
	N	57, 1, 6             @ A#6
	N	59, 1, 6             @ C7
	N	55, 1, 8             @ G#6
	N	60, 1, 8             @ C#7
	N	58, 1, 6             @ B6
	N	56, 1, 6             @ A6
	N	58, 1, 8             @ B6
	N	56, 1, 6             @ A6
	N	55, 1, 6             @ G#6
	N	54, 1, 12            @ G6
	PAT_END
pat_0801B71D:				@ used by s15c6
	N	67, 1, 7             @ G#7
	N	69, 1, 7             @ A#7
	N	71, 1, 6             @ C8
	N	62, 1, 9             @ D#7
	N	64, 1, 4             @ F7
	N	65, 1, 4             @ F#7
	N	65, 1, 6             @ F#7
	N	64, 1, 6             @ F7
	N	62, 1, 6             @ D#7
	N	60, 1, 6             @ C#7
	N	62, 1, 6             @ D#7
	N	60, 1, 6             @ C#7
	N	59, 1, 6             @ C7
	N	57, 1, 6             @ A#6
	N	59, 1, 6             @ C7
	N	55, 1, 6             @ G#6
	N	59, 1, 6             @ C7
	N	62, 1, 6             @ D#7
	N	67, 1, 6             @ G#7
	N	69, 1, 6             @ A#7
	N	71, 1, 6             @ C8
	N	69, 1, 4             @ A#7
	N	67, 1, 4             @ G#7
	N	62, 1, 8             @ D#7
	N	59, 1, 6             @ C7
	N	57, 1, 6             @ A#6
	N	55, 1, 10            @ G#6
	PAT_END
pat_0801B76F:				@ used by s15c2
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	52, 15, 2            @ F6
	N	48, 15, 2            @ C#6
	N	52, 15, 2            @ F6
	N	48, 15, 2            @ C#6
	N	50, 15, 2            @ D#6
	N	52, 15, 2            @ F6
	N	53, 15, 2            @ F#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	55, 15, 2            @ G#6
	N	52, 15, 2            @ F6
	N	48, 15, 2            @ C#6
	N	52, 15, 2            @ F6
	N	48, 15, 2            @ C#6
	N	50, 15, 2            @ D#6
	N	52, 15, 2            @ F6
	N	53, 15, 2            @ F#6
	N	57, 15, 2            @ A#6
	N	59, 15, 2            @ C7
	N	57, 15, 2            @ A#6
	N	59, 15, 2            @ C7
	N	57, 15, 2            @ A#6
	N	59, 15, 2            @ C7
	N	57, 15, 2            @ A#6
	N	59, 15, 2            @ C7
	N	57, 15, 2            @ A#6
	N	54, 15, 2            @ G6
	N	50, 15, 2            @ D#6
	N	54, 15, 2            @ G6
	N	50, 15, 2            @ D#6
	N	52, 15, 2            @ F6
	N	54, 15, 2            @ G6
	N	55, 15, 2            @ G#6
	N	62, 15, 2            @ D#7
	N	64, 15, 2            @ F7
	N	66, 15, 2            @ G7
	N	67, 15, 2            @ G#7
	N	69, 15, 2            @ A#7
	N	71, 15, 2            @ C8
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	74, 15, 4            @ D#8
	REST	0, 7
	PAT_END
pat_0801B81E:				@ used by s15c2
	N	65, 15, 2            @ F#7
	N	67, 15, 2            @ G#7
	N	65, 15, 2            @ F#7
	N	60, 15, 2            @ C#7
	N	57, 15, 2            @ A#6
	N	60, 15, 2            @ C#7
	N	65, 15, 2            @ F#7
	N	69, 15, 2            @ A#7
	N	65, 15, 2            @ F#7
	N	67, 15, 2            @ G#7
	N	65, 15, 2            @ F#7
	N	60, 15, 2            @ C#7
	N	57, 15, 2            @ A#6
	N	53, 15, 2            @ F#6
	N	57, 15, 2            @ A#6
	N	60, 15, 2            @ C#7
	N	65, 15, 2            @ F#7
	N	67, 15, 2            @ G#7
	N	65, 15, 2            @ F#7
	N	60, 15, 2            @ C#7
	N	57, 15, 2            @ A#6
	N	60, 15, 2            @ C#7
	N	65, 15, 2            @ F#7
	N	69, 15, 2            @ A#7
	N	65, 15, 2            @ F#7
	N	67, 15, 2            @ G#7
	N	65, 15, 2            @ F#7
	N	60, 15, 2            @ C#7
	N	57, 15, 2            @ A#6
	N	53, 15, 2            @ F#6
	N	57, 15, 2            @ A#6
	N	60, 15, 2            @ C#7
	N	67, 15, 2            @ G#7
	N	69, 15, 2            @ A#7
	N	67, 15, 2            @ G#7
	N	62, 15, 2            @ D#7
	N	59, 15, 2            @ C7
	N	62, 15, 2            @ D#7
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	69, 15, 2            @ A#7
	N	67, 15, 2            @ G#7
	N	62, 15, 2            @ D#7
	N	59, 15, 2            @ C7
	N	55, 15, 2            @ G#6
	N	59, 15, 2            @ C7
	N	62, 15, 2            @ D#7
	N	67, 15, 2            @ G#7
	N	69, 15, 2            @ A#7
	N	71, 15, 2            @ C8
	N	72, 15, 2            @ C#8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	78, 15, 2            @ G8
	N	79, 15, 4            @ G#8
	N	91, 15, 7            @ G#9
	PAT_END
pat_0801B8CD:				@ used by s15c2
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	75, 15, 4            @ E8
	N	72, 15, 4            @ C#8
	N	75, 15, 4            @ E8
	N	72, 15, 4            @ C#8
	N	75, 15, 4            @ E8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	75, 15, 4            @ E8
	N	72, 15, 4            @ C#8
	N	75, 15, 4            @ E8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	74, 15, 4            @ D#8
	N	70, 15, 4            @ B7
	N	74, 15, 4            @ D#8
	N	77, 15, 4            @ F#8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	74, 15, 4            @ D#8
	N	70, 15, 4            @ B7
	N	65, 15, 4            @ F#7
	N	70, 15, 4            @ B7
	N	74, 15, 4            @ D#8
	N	77, 15, 4            @ F#8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	75, 15, 4            @ E8
	N	72, 15, 4            @ C#8
	N	75, 15, 4            @ E8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	75, 15, 4            @ E8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	75, 15, 4            @ E8
	N	72, 15, 4            @ C#8
	N	75, 15, 4            @ E8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	82, 15, 4            @ B8
	N	80, 15, 4            @ A8
	N	75, 15, 4            @ E8
	N	72, 15, 4            @ C#8
	N	75, 15, 4            @ E8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	74, 15, 4            @ D#8
	N	70, 15, 4            @ B7
	N	74, 15, 4            @ D#8
	N	77, 15, 4            @ F#8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	70, 15, 4            @ B7
	N	74, 15, 4            @ D#8
	N	77, 15, 4            @ F#8
	N	82, 15, 4            @ B8
	N	77, 15, 4            @ F#8
	N	82, 15, 4            @ B8
	N	84, 15, 4            @ C#9
	N	79, 15, 4            @ G#8
	N	76, 15, 4            @ F8
	N	79, 15, 4            @ G#8
	N	76, 15, 4            @ F8
	N	79, 15, 4            @ G#8
	N	76, 15, 4            @ F8
	N	79, 15, 4            @ G#8
	N	72, 15, 4            @ C#8
	N	74, 15, 4            @ D#8
	N	76, 15, 4            @ F8
	N	77, 15, 4            @ F#8
	N	72, 15, 0            @ C#8
	N	74, 15, 0            @ D#8
	N	76, 15, 0            @ F8
	N	77, 15, 0            @ F#8
	N	79, 15, 0            @ G#8
	N	81, 15, 0            @ A#8
	N	83, 15, 2            @ C9
	N	84, 15, 6            @ C#9
	PAT_END
pat_0801B9FA:				@ used by s15c2
	REST	0, 22
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 4            @ G#8
	N	76, 15, 4            @ F8
	N	74, 15, 4            @ D#8
	N	76, 15, 4            @ F8
	N	72, 15, 6            @ C#8
	REST	0, 22
	N	81, 15, 2            @ A#8
	N	83, 15, 2            @ C9
	N	81, 15, 4            @ A#8
	N	83, 15, 4            @ C9
	N	81, 15, 4            @ A#8
	N	79, 15, 4            @ G#8
	N	78, 15, 4            @ G8
	N	76, 15, 4            @ F8
	N	78, 15, 4            @ G8
	N	76, 15, 4            @ F8
	N	74, 15, 4            @ D#8
	N	73, 15, 4            @ D8
	N	74, 15, 6            @ D#8
	REST	0, 7
	N	72, 15, 4            @ C#8
	N	79, 15, 4            @ G#8
	N	76, 15, 4            @ F8
	N	79, 15, 6            @ G#8
	N	84, 15, 6            @ C#9
	REST	0, 4
	N	84, 15, 2            @ C#9
	N	79, 15, 2            @ G#8
	N	76, 15, 4            @ F8
	N	79, 15, 4            @ G#8
	N	76, 15, 4            @ F8
	N	72, 15, 4            @ C#8
	REST	0, 7
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	74, 15, 4            @ D#8
	N	78, 15, 4            @ G8
	N	81, 15, 4            @ A#8
	N	78, 15, 4            @ G8
	N	74, 15, 4            @ D#8
	N	69, 15, 4            @ A#7
	N	66, 15, 4            @ G7
	N	69, 15, 4            @ A#7
	N	66, 15, 4            @ G7
	N	69, 15, 4            @ A#7
	N	62, 15, 6            @ D#7
	REST	0, 7
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 4            @ D#8
	N	71, 15, 4            @ C8
	N	67, 15, 6            @ G#7
	REST	0, 7
	N	79, 15, 2            @ G#8
	N	75, 15, 2            @ E8
	N	70, 15, 4            @ B7
	N	67, 15, 4            @ G#7
	N	70, 15, 6            @ B7
	N	75, 15, 6            @ E8
	REST	0, 4
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 4            @ G#7
	N	71, 15, 4            @ C8
	N	74, 15, 4            @ D#8
	N	71, 15, 4            @ C8
	N	67, 15, 6            @ G#7
	REST	0, 4
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	REST	0, 4
	N	67, 15, 4            @ G#7
	N	62, 15, 4            @ D#7
	N	67, 15, 4            @ G#7
	N	71, 15, 6            @ C8
	REST	0, 4
	N	72, 15, 2            @ C#8
	N	68, 15, 2            @ A7
	N	63, 15, 4            @ E7
	N	60, 15, 4            @ C#7
	N	63, 15, 4            @ E7
	N	68, 15, 4            @ A7
	N	63, 15, 4            @ E7
	N	72, 15, 4            @ C#8
	REST	0, 4
	N	72, 15, 2            @ C#8
	N	68, 15, 2            @ A7
	N	63, 15, 4            @ E7
	N	60, 15, 4            @ C#7
	N	56, 15, 4            @ A6
	N	51, 15, 4            @ E6
	N	48, 15, 6            @ C#6
	REST	0, 4
	N	50, 15, 2            @ D#6
	N	52, 15, 2            @ F6
	N	54, 15, 2            @ G6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	59, 15, 2            @ C7
	N	61, 15, 2            @ D7
	N	62, 15, 2            @ D#7
	N	64, 15, 2            @ F7
	N	66, 15, 2            @ G7
	N	67, 15, 2            @ G#7
	N	69, 15, 2            @ A#7
	N	71, 15, 2            @ C8
	N	73, 15, 2            @ D8
	N	74, 15, 8            @ D#8
	REST	0, 8
	PAT_END
pat_0801BB4B:				@ used by s15c2
	REST	0, 6
	N	74, 15, 4            @ D#8
	N	76, 15, 4            @ F8
	N	74, 15, 4            @ D#8
	N	71, 15, 4            @ C8
	REST	0, 4
	N	69, 15, 6            @ A#7
	N	71, 15, 6            @ C8
	N	67, 15, 4            @ G#7
	REST	0, 4
	N	69, 15, 4            @ A#7
	N	71, 15, 6            @ C8
	N	69, 15, 6            @ A#7
	N	67, 15, 6            @ G#7
	N	65, 15, 6            @ F#7
	N	64, 15, 6            @ F7
	N	62, 15, 6            @ D#7
	N	60, 15, 6            @ C#7
	N	59, 15, 6            @ C7
	N	57, 15, 6            @ A#6
	N	55, 15, 2            @ G#6
	N	57, 15, 2            @ A#6
	N	59, 15, 2            @ C7
	N	60, 15, 2            @ C#7
	N	62, 15, 2            @ D#7
	N	64, 15, 2            @ F7
	N	66, 15, 2            @ G7
	N	67, 15, 2            @ G#7
	N	69, 15, 2            @ A#7
	N	71, 15, 2            @ C8
	N	72, 15, 2            @ C#8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	86, 15, 2            @ D#9
	N	88, 15, 2            @ F9
	N	90, 15, 4            @ G9
	N	91, 15, 4            @ G#9
	N	86, 15, 4            @ D#9
	N	83, 15, 4            @ C9
	N	79, 15, 4            @ G#8
	N	74, 15, 4            @ D#8
	N	71, 15, 4            @ C8
	N	74, 15, 4            @ D#8
	N	67, 15, 6            @ G#7
	N	71, 15, 6            @ C8
	N	74, 15, 6            @ D#8
	N	79, 15, 10           @ G#8
	PAT_END
pat_0801BBE8:				@ used by s15c2
	N	72, 30, 6            @ C#8
	N	72, 30, 4            @ C#8
	N	74, 30, 4            @ D#8
	N	72, 30, 4            @ C#8
	N	71, 30, 4            @ C8
	N	69, 30, 4            @ A#7
	N	72, 30, 4            @ C#8
	N	71, 30, 6            @ C8
	N	71, 30, 4            @ C8
	N	69, 30, 4            @ A#7
	N	67, 30, 4            @ G#7
	N	69, 30, 4            @ A#7
	N	71, 30, 4            @ C8
	N	67, 30, 4            @ G#7
	N	69, 30, 6            @ A#7
	N	65, 30, 6            @ F#7
	N	60, 30, 6            @ C#7
	N	65, 30, 6            @ F#7
	N	57, 30, 4            @ A#6
	N	58, 30, 4            @ B6
	N	60, 30, 6            @ C#7
	N	57, 30, 4            @ A#6
	N	58, 30, 4            @ B6
	N	60, 30, 6            @ C#7
	N	72, 30, 6            @ C#8
	N	72, 30, 4            @ C#8
	N	74, 30, 4            @ D#8
	N	72, 30, 4            @ C#8
	N	71, 30, 4            @ C8
	N	69, 30, 4            @ A#7
	N	72, 30, 4            @ C#8
	N	71, 30, 6            @ C8
	N	71, 30, 4            @ C8
	N	69, 30, 4            @ A#7
	N	67, 30, 6            @ G#7
	N	71, 30, 6            @ C8
	N	69, 30, 6            @ A#7
	N	65, 30, 6            @ F#7
	N	60, 30, 6            @ C#7
	N	65, 30, 6            @ F#7
	N	57, 30, 4            @ A#6
	N	58, 30, 4            @ B6
	N	60, 30, 4            @ C#7
	N	58, 30, 4            @ B6
	N	57, 30, 8            @ A#6
	N	71, 30, 6            @ C8
	N	71, 30, 4            @ C8
	N	72, 30, 4            @ C#8
	N	71, 30, 4            @ C8
	N	69, 30, 4            @ A#7
	N	67, 30, 4            @ G#7
	N	71, 30, 4            @ C8
	N	69, 30, 6            @ A#7
	N	69, 30, 4            @ A#7
	N	67, 30, 4            @ G#7
	N	65, 30, 6            @ F#7
	N	69, 30, 6            @ A#7
	N	67, 30, 6            @ G#7
	N	62, 30, 6            @ D#7
	N	59, 30, 4            @ C7
	N	60, 30, 4            @ C#7
	N	62, 30, 6            @ D#7
	N	59, 30, 4            @ C7
	N	60, 30, 4            @ C#7
	N	62, 30, 4            @ D#7
	N	64, 30, 4            @ F7
	N	62, 30, 4            @ D#7
	N	60, 30, 4            @ C#7
	N	59, 30, 6            @ C7
	N	71, 30, 6            @ C8
	N	71, 30, 4            @ C8
	N	72, 30, 4            @ C#8
	N	74, 30, 6            @ D#8
	N	72, 30, 4            @ C#8
	N	71, 30, 4            @ C8
	N	72, 30, 6            @ C#8
	N	69, 30, 6            @ A#7
	N	65, 30, 6            @ F#7
	N	69, 30, 6            @ A#7
	N	67, 30, 6            @ G#7
	N	62, 30, 4            @ D#7
	N	67, 30, 4            @ G#7
	N	71, 30, 6            @ C8
	N	67, 30, 4            @ G#7
	N	71, 30, 4            @ C8
	N	74, 30, 6            @ D#8
	N	71, 30, 4            @ C8
	N	74, 30, 4            @ D#8
	N	79, 30, 8            @ G#8
	PAT_END
pat_0801BCF4:				@ used by s15c1
	N	31, 21, 7            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 4            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 7            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 4            @ G#4
	N	31, 21, 6            @ G#4
	N	38, 22, 7            @ D#5
	N	38, 22, 6            @ D#5
	N	38, 22, 4            @ D#5
	N	38, 22, 6            @ D#5
	N	38, 22, 7            @ D#5
	N	38, 22, 6            @ D#5
	N	38, 22, 4            @ D#5
	N	38, 22, 6            @ D#5
	N	31, 21, 7            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 4            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 7            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 4            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 7            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 4            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 6            @ G#4
	N	31, 21, 6            @ G#4
	PAT_END
pat_0801BD55:				@ used by s15c1
	N	36, 21, 7            @ C#5
	N	36, 21, 6            @ C#5
	N	36, 21, 4            @ C#5
	N	36, 21, 7            @ C#5
	N	36, 21, 6            @ C#5
	N	36, 21, 4            @ C#5
	N	36, 21, 6            @ C#5
	N	36, 21, 6            @ C#5
	N	38, 20, 7            @ D#5
	N	38, 20, 6            @ D#5
	N	38, 20, 4            @ D#5
	N	38, 20, 7            @ D#5
	N	38, 20, 6            @ D#5
	N	38, 20, 4            @ D#5
	N	38, 20, 6            @ D#5
	N	38, 20, 6            @ D#5
	N	41, 19, 7            @ F#5
	N	41, 19, 6            @ F#5
	N	41, 19, 4            @ F#5
	N	41, 19, 7            @ F#5
	N	41, 19, 6            @ F#5
	N	41, 19, 4            @ F#5
	N	41, 19, 6            @ F#5
	N	41, 19, 6            @ F#5
	N	43, 19, 7            @ G#5
	N	43, 19, 6            @ G#5
	N	43, 19, 4            @ G#5
	N	43, 19, 7            @ G#5
	N	43, 19, 6            @ G#5
	N	43, 19, 4            @ G#5
	N	43, 19, 6            @ G#5
	N	43, 19, 6            @ G#5
	PAT_END
pat_0801BDB6:				@ used by s15c1
	N	44, 19, 7            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 4            @ A5
	N	44, 19, 7            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 4            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 6            @ A5
	N	34, 21, 7            @ B4
	N	34, 21, 6            @ B4
	N	34, 21, 4            @ B4
	N	34, 21, 7            @ B4
	N	34, 21, 6            @ B4
	N	34, 21, 4            @ B4
	N	34, 21, 6            @ B4
	N	34, 21, 6            @ B4
	N	44, 19, 7            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 4            @ A5
	N	44, 19, 7            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 4            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 7            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 4            @ A5
	N	44, 19, 7            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 4            @ A5
	N	44, 19, 6            @ A5
	N	44, 19, 6            @ A5
	N	34, 21, 7            @ B4
	N	34, 21, 6            @ B4
	N	34, 21, 4            @ B4
	N	34, 21, 7            @ B4
	N	34, 21, 6            @ B4
	N	34, 21, 4            @ B4
	N	34, 21, 6            @ B4
	N	34, 21, 6            @ B4
	N	36, 21, 7            @ C#5
	N	36, 21, 6            @ C#5
	N	36, 21, 4            @ C#5
	N	36, 21, 7            @ C#5
	N	36, 21, 6            @ C#5
	N	36, 21, 4            @ C#5
	N	36, 21, 6            @ C#5
	N	36, 21, 6            @ C#5
	PAT_END
pat_0801BE47:				@ used by s15c3
	N	36, 11, 7            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 7            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 6            @ D#5
	N	40, 11, 6            @ F5
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 6            @ F#5
	N	43, 11, 7            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 7            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	PAT_END
pat_0801BEAB:				@ used by s15c3
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	41, 11, 6            @ F#5
	N	43, 11, 7            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 7            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	43, 11, 6            @ G#5
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	41, 11, 7            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 7            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 4            @ F#5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	41, 11, 6            @ F#5
	N	43, 11, 7            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 7            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 4            @ G#5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	43, 11, 6            @ G#5
	N	45, 11, 7            @ A#5
	N	45, 11, 6            @ A#5
	N	45, 11, 4            @ A#5
	N	45, 11, 7            @ A#5
	N	45, 11, 6            @ A#5
	N	45, 11, 4            @ A#5
	N	45, 11, 6            @ A#5
	N	45, 11, 6            @ A#5
	PAT_END
pat_0801BF4E:				@ used by s15c3
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	41, 11, 6            @ F#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	PAT_END
pat_0801C00F:				@ used by s15c3
	N	36, 11, 8            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	42, 11, 6            @ G5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	39, 11, 6            @ E5
	N	39, 11, 6            @ E5
	N	39, 11, 6            @ E5
	N	39, 11, 6            @ E5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	43, 11, 6            @ G#5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	44, 11, 6            @ A5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	PAT_END
pat_0801C0CD:				@ used by s15c3
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 6            @ G#4
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 6            @ D#5
	N	43, 11, 6            @ G#5
	N	41, 11, 6            @ F#5
	N	40, 11, 6            @ F5
	N	38, 11, 6            @ D#5
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 10           @ G#4
	PAT_END
pat_0801C125:				@ used by s15c4
	N	30, 3, 4             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	PAT_END
pat_0801C195:				@ used by s14c1
	N	57, 29, 6            @ A#6
	N	64, 29, 6            @ F7
	N	59, 29, 2            @ C7
	N	62, 29, 2            @ D#7
	N	60, 29, 2            @ C#7
	N	59, 29, 2            @ C7
	N	60, 29, 6            @ C#7
	N	57, 29, 6            @ A#6
	N	52, 29, 6            @ F6
	N	53, 29, 6            @ F#6
	N	60, 29, 6            @ C#7
	N	55, 29, 2            @ G#6
	N	58, 29, 2            @ B6
	N	56, 29, 2            @ A6
	N	55, 29, 2            @ G#6
	N	56, 29, 6            @ A6
	N	53, 29, 6            @ F#6
	N	48, 29, 6            @ C#6
	N	51, 29, 8            @ E6
	N	50, 29, 6            @ D#6
	N	48, 29, 10           @ C#6
	PAT_END
pat_0801C1D5:				@ used by s14c2
	N	48, 29, 6            @ C#6
	N	60, 29, 6            @ C#7
	N	56, 29, 2            @ A6
	N	59, 29, 2            @ C7
	N	57, 29, 2            @ A#6
	N	56, 29, 2            @ A6
	N	57, 29, 6            @ A#6
	N	52, 29, 6            @ F6
	N	48, 29, 6            @ C#6
	N	48, 29, 6            @ C#6
	N	53, 29, 6            @ F#6
	N	51, 29, 2            @ E6
	N	55, 29, 2            @ G#6
	N	53, 29, 2            @ F#6
	N	51, 29, 2            @ E6
	N	53, 29, 6            @ F#6
	N	48, 29, 6            @ C#6
	N	44, 29, 6            @ A5
	N	43, 29, 8            @ G#5
	N	47, 29, 6            @ C6
	N	39, 29, 10           @ E5
	PAT_END
pat_0801C215:				@ used by s14c3
	N	33, 14, 7            @ A#4
	N	40, 14, 4            @ F5
	N	45, 14, 4            @ A#5
	N	40, 14, 4            @ F5
	N	33, 14, 6            @ A#4
	N	45, 14, 4            @ A#5
	N	40, 14, 4            @ F5
	N	36, 14, 4            @ C#5
	N	33, 14, 4            @ A#4
	N	29, 14, 6            @ F#4
	N	41, 14, 7            @ F#5
	N	36, 14, 4            @ C#5
	N	32, 14, 4            @ A4
	N	36, 14, 4            @ C#5
	N	29, 14, 6            @ F#4
	N	41, 14, 6            @ F#5
	N	36, 14, 7            @ C#5
	N	39, 14, 4            @ E5
	N	43, 14, 4            @ G#5
	N	31, 14, 4            @ G#4
	N	36, 14, 6            @ C#5
	N	31, 14, 6            @ G#4
	N	31, 14, 6            @ G#4
	N	36, 14, 8            @ C#5
	PAT_END
pat_0801C25E:				@ used by s14c4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 8             @ F4
	PAT_END
pat_0801C2EC:				@ used by s13c1
	N	59, 29, 4            @ C7
	N	57, 29, 4            @ A#6
	N	59, 29, 8            @ C7
	N	62, 29, 6            @ D#7
	N	55, 29, 10           @ G#6
	N	61, 29, 4            @ D7
	N	59, 29, 4            @ C7
	N	61, 29, 8            @ D7
	N	64, 29, 6            @ F7
	N	69, 29, 10           @ A#7
	N	67, 29, 6            @ G#7
	N	65, 29, 6            @ F#7
	N	63, 29, 6            @ E7
	N	60, 29, 6            @ C#7
	N	62, 29, 4            @ D#7
	N	64, 29, 4            @ F7
	N	62, 29, 4            @ D#7
	N	60, 29, 4            @ C#7
	N	59, 29, 4            @ C7
	N	57, 29, 4            @ A#6
	N	59, 29, 4            @ C7
	N	60, 29, 4            @ C#7
	N	59, 29, 4            @ C7
	N	60, 29, 4            @ C#7
	N	62, 29, 4            @ D#7
	N	62, 29, 7            @ D#7
	N	60, 29, 4            @ C#7
	N	59, 29, 4            @ C7
	N	57, 29, 4            @ A#6
	N	55, 29, 4            @ G#6
	N	54, 29, 4            @ G6
	N	55, 29, 4            @ G#6
	N	57, 29, 4            @ A#6
	N	59, 29, 4            @ C7
	N	60, 29, 4            @ C#7
	N	57, 29, 4            @ A#6
	PAT_END
pat_0801C359:				@ used by s13c1
	N	59, 29, 4            @ C7
	N	57, 29, 4            @ A#6
	N	59, 29, 8            @ C7
	N	62, 29, 6            @ D#7
	N	55, 29, 7            @ G#6
	N	67, 29, 2            @ G#7
	N	69, 29, 2            @ A#7
	N	71, 29, 4            @ C8
	N	69, 29, 4            @ A#7
	N	67, 29, 4            @ G#7
	N	62, 29, 4            @ D#7
	N	61, 29, 4            @ D7
	N	59, 29, 4            @ C7
	N	61, 29, 8            @ D7
	N	64, 29, 6            @ F7
	N	69, 29, 7            @ A#7
	N	61, 29, 2            @ D7
	N	62, 29, 2            @ D#7
	N	64, 29, 4            @ F7
	N	62, 29, 4            @ D#7
	N	61, 29, 4            @ D7
	N	57, 29, 4            @ A#6
	N	63, 29, 6            @ E7
	N	62, 29, 6            @ D#7
	N	60, 29, 6            @ C#7
	N	55, 29, 6            @ G#6
	N	62, 29, 6            @ D#7
	N	64, 29, 4            @ F7
	N	66, 29, 6            @ G7
	N	64, 29, 4            @ F7
	N	62, 29, 6            @ D#7
	N	67, 29, 6            @ G#7
	N	67, 29, 4            @ G#7
	N	67, 29, 6            @ G#7
	N	67, 29, 4            @ G#7
	N	67, 29, 6            @ G#7
	N	67, 29, 10           @ G#7
	PAT_END
pat_0801C3C9:				@ used by s13c2
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	72, 15, 2            @ C#8
	N	67, 15, 2            @ G#7
	N	72, 15, 2            @ C#8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	72, 15, 2            @ C#8
	N	67, 15, 2            @ G#7
	N	72, 15, 2            @ C#8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	66, 15, 2            @ G7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	66, 15, 2            @ G7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	66, 15, 2            @ G7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	66, 15, 2            @ G7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	78, 15, 2            @ G8
	N	76, 15, 2            @ F8
	N	73, 15, 2            @ D8
	N	69, 15, 2            @ A#7
	N	73, 15, 2            @ D8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	72, 15, 2            @ C#8
	N	67, 15, 2            @ G#7
	N	72, 15, 2            @ C#8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	77, 15, 2            @ F#8
	N	75, 15, 2            @ E8
	N	72, 15, 2            @ C#8
	N	67, 15, 2            @ G#7
	N	72, 15, 2            @ C#8
	N	74, 15, 2            @ D#8
	N	75, 15, 2            @ E8
	N	74, 15, 2            @ D#8
	N	75, 15, 2            @ E8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	66, 15, 2            @ G7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	66, 15, 2            @ G7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	67, 15, 2            @ G#7
	N	71, 15, 2            @ C8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	71, 15, 2            @ C8
	N	69, 15, 2            @ A#7
	N	71, 15, 2            @ C8
	N	67, 15, 8            @ G#7
	PAT_END
pat_0801C6B5:				@ used by s13c3
	N	31, 14, 7            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 7            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 6            @ G#4
	N	33, 14, 7            @ A#4
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	33, 14, 6            @ A#4
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	33, 14, 6            @ A#4
	N	36, 14, 7            @ C#5
	N	36, 14, 6            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 6            @ C#5
	N	38, 14, 7            @ D#5
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	35, 14, 4            @ C5
	N	31, 14, 7            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 6            @ G#4
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 6            @ D#5
	N	36, 14, 4            @ C#5
	N	35, 14, 4            @ C5
	N	33, 14, 4            @ A#4
	N	31, 14, 7            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 4            @ G#4
	N	30, 14, 4            @ G4
	N	31, 14, 7            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 4            @ G#4
	N	33, 14, 7            @ A#4
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	33, 14, 4            @ A#4
	N	32, 14, 4            @ A4
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	33, 14, 6            @ A#4
	N	36, 14, 7            @ C#5
	N	36, 14, 6            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 6            @ C#5
	N	38, 14, 7            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 6            @ D#5
	N	31, 14, 7            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 6            @ G#4
	N	31, 14, 8            @ G#4
	PAT_END
pat_0801C78E:				@ used by s13c4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	PAT_END
pat_0801C80D:				@ used by s12c1
	N	57, 16, 4            @ A#6
	N	56, 16, 4            @ A6
	N	57, 16, 4            @ A#6
	N	60, 16, 4            @ C#7
	N	57, 16, 6            @ A#6
	N	52, 16, 7            @ F6
	N	57, 16, 4            @ A#6
	N	56, 16, 4            @ A6
	N	57, 16, 4            @ A#6
	N	60, 16, 6            @ C#7
	N	64, 16, 7            @ F7
	N	59, 16, 4            @ C7
	N	58, 16, 4            @ B6
	N	59, 16, 4            @ C7
	N	62, 16, 6            @ D#7
	N	56, 16, 7            @ A6
	N	52, 16, 4            @ F6
	N	51, 16, 4            @ E6
	N	52, 16, 4            @ F6
	N	56, 16, 6            @ A6
	N	59, 16, 7            @ C7
	N	57, 16, 4            @ A#6
	N	56, 16, 4            @ A6
	N	57, 16, 4            @ A#6
	N	60, 16, 6            @ C#7
	N	52, 16, 7            @ F6
	N	57, 16, 4            @ A#6
	N	56, 16, 4            @ A6
	N	57, 16, 4            @ A#6
	N	60, 16, 6            @ C#7
	N	64, 16, 7            @ F7
	N	64, 16, 4            @ F7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	62, 16, 6            @ D#7
	N	59, 16, 7            @ C7
	N	57, 16, 4            @ A#6
	N	56, 16, 4            @ A6
	N	57, 16, 4            @ A#6
	N	60, 16, 6            @ C#7
	N	64, 16, 6            @ F7
	PAT_END
pat_0801C889:				@ used by s12c1
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	76, 16, 4            @ F8
	N	75, 16, 4            @ E8
	N	76, 16, 4            @ F8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	68, 16, 4            @ A7
	N	64, 16, 4            @ F7
	N	68, 16, 4            @ A7
	N	71, 16, 4            @ C8
	N	74, 16, 4            @ D#8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	75, 16, 4            @ E8
	N	76, 16, 4            @ F8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	71, 16, 4            @ C8
	N	68, 16, 4            @ A7
	N	64, 16, 4            @ F7
	N	68, 16, 4            @ A7
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	69, 16, 4            @ A#7
	N	72, 16, 4            @ C#8
	N	76, 16, 4            @ F8
	N	72, 16, 4            @ C#8
	N	76, 16, 4            @ F8
	N	81, 16, 4            @ A#8
	PAT_END
pat_0801C94A:				@ used by s12c1
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	64, 16, 4            @ F7
	N	59, 16, 4            @ C7
	N	64, 16, 4            @ F7
	N	57, 16, 4            @ A#6
	N	59, 16, 4            @ C7
	N	60, 16, 4            @ C#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	64, 16, 4            @ F7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	59, 16, 4            @ C7
	N	64, 16, 4            @ F7
	N	64, 16, 4            @ F7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	60, 16, 4            @ C#7
	N	59, 16, 4            @ C7
	N	57, 16, 4            @ A#6
	N	59, 16, 4            @ C7
	N	60, 16, 4            @ C#7
	N	62, 16, 4            @ D#7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	64, 16, 4            @ F7
	N	57, 16, 6            @ A#6
	PAT_END
pat_0801CA08:				@ used by s12c1
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	70, 16, 4            @ B7
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	77, 16, 4            @ F#8
	N	72, 16, 4            @ C#8
	N	70, 16, 4            @ B7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	72, 16, 4            @ C#8
	N	67, 16, 4            @ G#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	62, 16, 4            @ D#7
	N	61, 16, 4            @ D7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	76, 16, 4            @ F8
	N	75, 16, 4            @ E8
	N	76, 16, 4            @ F8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	70, 16, 4            @ B7
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	77, 16, 4            @ F#8
	N	72, 16, 4            @ C#8
	N	70, 16, 4            @ B7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	60, 16, 4            @ C#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	55, 16, 4            @ G#6
	N	60, 16, 4            @ C#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	62, 16, 4            @ D#7
	N	61, 16, 4            @ D7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	76, 16, 4            @ F8
	N	75, 16, 4            @ E8
	N	76, 16, 4            @ F8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	PAT_END
pat_0801CB89:				@ used by s12c1
	N	62, 16, 4            @ D#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	74, 16, 4            @ D#8
	N	73, 16, 4            @ D8
	N	74, 16, 4            @ D#8
	N	69, 16, 4            @ A#7
	N	70, 16, 4            @ B7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	61, 16, 4            @ D7
	N	57, 16, 4            @ A#6
	N	61, 16, 2            @ D7
	N	64, 16, 2            @ F7
	N	67, 16, 4            @ G#7
	N	70, 16, 4            @ B7
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 2            @ A#7
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	62, 16, 4            @ D#7
	N	61, 16, 4            @ D7
	N	62, 16, 4            @ D#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	74, 16, 4            @ D#8
	N	73, 16, 4            @ D8
	N	74, 16, 4            @ D#8
	N	69, 16, 4            @ A#7
	N	70, 16, 4            @ B7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	61, 16, 4            @ D7
	N	57, 16, 4            @ A#6
	N	61, 16, 2            @ D7
	N	64, 16, 2            @ F7
	N	67, 16, 4            @ G#7
	N	70, 16, 4            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	61, 16, 4            @ D7
	N	62, 16, 4            @ D#7
	N	57, 16, 4            @ A#6
	N	53, 16, 4            @ F#6
	N	57, 16, 4            @ A#6
	N	50, 16, 6            @ D#6
	PAT_END
pat_0801CC65:				@ used by s12c1
	N	69, 16, 4            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	66, 16, 4            @ G7
	N	66, 16, 4            @ G7
	N	69, 16, 4            @ A#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	67, 16, 2            @ G#7
	N	67, 16, 2            @ G#7
	N	67, 16, 4            @ G#7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	64, 16, 4            @ F7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	65, 16, 2            @ F#7
	N	65, 16, 2            @ F#7
	N	65, 16, 4            @ F#7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	62, 16, 4            @ D#7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	57, 16, 2            @ A#6
	N	58, 16, 2            @ B6
	N	59, 16, 2            @ C7
	N	60, 16, 2            @ C#7
	N	61, 16, 2            @ D7
	N	62, 16, 2            @ D#7
	N	63, 16, 2            @ E7
	N	64, 16, 2            @ F7
	N	65, 16, 2            @ F#7
	N	66, 16, 2            @ G7
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	66, 16, 4            @ G7
	N	66, 16, 4            @ G7
	N	69, 16, 4            @ A#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	67, 16, 2            @ G#7
	N	67, 16, 2            @ G#7
	N	67, 16, 4            @ G#7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	64, 16, 4            @ F7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	65, 16, 4            @ F#7
	N	65, 16, 2            @ F#7
	N	65, 16, 2            @ F#7
	N	65, 16, 4            @ F#7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	62, 16, 4            @ D#7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	64, 16, 2            @ F7
	N	63, 16, 2            @ E7
	N	62, 16, 2            @ D#7
	N	61, 16, 2            @ D7
	N	60, 16, 2            @ C#7
	N	61, 16, 2            @ D7
	N	62, 16, 2            @ D#7
	N	63, 16, 2            @ E7
	N	64, 16, 2            @ F7
	N	65, 16, 2            @ F#7
	N	66, 16, 2            @ G7
	N	67, 16, 2            @ G#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 4            @ D#8
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	74, 16, 4            @ D#8
	N	69, 16, 4            @ A#7
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 4            @ C8
	N	67, 16, 4            @ G#7
	N	67, 16, 4            @ G#7
	N	71, 16, 4            @ C8
	N	67, 16, 4            @ G#7
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 4            @ C#8
	N	67, 16, 4            @ G#7
	N	67, 16, 4            @ G#7
	N	72, 16, 4            @ C#8
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	65, 16, 4            @ F#7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	64, 16, 4            @ F7
	N	64, 16, 2            @ F7
	N	64, 16, 2            @ F7
	N	64, 16, 4            @ F7
	N	64, 16, 4            @ F7
	N	68, 16, 4            @ A7
	N	68, 16, 4            @ A7
	N	71, 16, 4            @ C8
	N	71, 16, 4            @ C8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	76, 16, 4            @ F8
	N	77, 16, 4            @ F#8
	N	77, 16, 4            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 4            @ D#8
	N	76, 16, 6            @ F8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	74, 16, 6            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 2            @ A#7
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	71, 16, 8            @ C8
	PAT_END
pat_0801CE22:				@ used by s12c2
	N	50, 20, 7            @ D#6
	N	50, 20, 4            @ D#6
	N	50, 20, 8            @ D#6
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	50, 20, 7            @ D#6
	N	50, 20, 4            @ D#6
	N	50, 20, 8            @ D#6
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	55, 19, 7            @ G#6
	N	55, 19, 4            @ G#6
	N	55, 19, 8            @ G#6
	N	48, 21, 7            @ C#6
	N	48, 21, 4            @ C#6
	N	48, 21, 8            @ C#6
	N	53, 19, 7            @ F#6
	N	53, 19, 4            @ F#6
	N	53, 19, 8            @ F#6
	N	52, 19, 7            @ F6
	N	52, 19, 4            @ F6
	N	52, 19, 8            @ F6
	N	52, 19, 7            @ F6
	N	52, 19, 4            @ F6
	N	52, 19, 8            @ F6
	N	45, 24, 8            @ A#5
	N	52, 19, 8            @ F6
	N	45, 24, 8            @ A#5
	N	52, 19, 8            @ F6
	PAT_END
pat_0801CEAD:				@ used by s12c2
	N	50, 22, 7            @ D#6
	N	50, 22, 4            @ D#6
	N	50, 22, 8            @ D#6
	N	50, 22, 7            @ D#6
	N	50, 22, 4            @ D#6
	N	50, 22, 8            @ D#6
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	45, 21, 7            @ A#5
	N	45, 21, 4            @ A#5
	N	45, 21, 8            @ A#5
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	PAT_END
pat_0801CEF6:				@ used by s12c2
	N	53, 19, 7            @ F#6
	N	53, 19, 4            @ F#6
	N	53, 19, 8            @ F#6
	N	53, 19, 7            @ F#6
	N	53, 19, 4            @ F#6
	N	53, 19, 8            @ F#6
	N	48, 20, 7            @ C#6
	N	48, 20, 4            @ C#6
	N	48, 20, 8            @ C#6
	N	48, 20, 7            @ C#6
	N	48, 20, 4            @ C#6
	N	48, 20, 8            @ C#6
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	N	53, 19, 7            @ F#6
	N	53, 19, 4            @ F#6
	N	53, 19, 8            @ F#6
	N	53, 19, 7            @ F#6
	N	53, 19, 4            @ F#6
	N	53, 19, 8            @ F#6
	N	48, 21, 7            @ C#6
	N	48, 21, 4            @ C#6
	N	48, 21, 8            @ C#6
	N	48, 21, 7            @ C#6
	N	48, 21, 4            @ C#6
	N	48, 21, 8            @ C#6
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	50, 23, 7            @ D#6
	N	50, 23, 4            @ D#6
	N	50, 23, 8            @ D#6
	N	48, 20, 7            @ C#6
	N	48, 20, 4            @ C#6
	N	48, 20, 8            @ C#6
	N	55, 19, 7            @ G#6
	N	55, 19, 4            @ G#6
	N	55, 19, 8            @ G#6
	PAT_END
pat_0801CF87:				@ used by s12c2
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	N	52, 19, 7            @ F6
	N	52, 19, 4            @ F6
	N	52, 19, 8            @ F6
	N	52, 19, 7            @ F6
	N	52, 19, 4            @ F6
	N	52, 19, 8            @ F6
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	N	52, 19, 7            @ F6
	N	52, 19, 4            @ F6
	N	52, 19, 8            @ F6
	N	45, 24, 7            @ A#5
	N	45, 24, 4            @ A#5
	N	45, 24, 8            @ A#5
	PAT_END
pat_0801CFD0:				@ used by s12c3
	N	33, 14, 4            @ A#4
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	28, 14, 4            @ F4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	28, 14, 4            @ F4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	33, 14, 4            @ A#4
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	28, 14, 4            @ F4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	33, 14, 4            @ A#4
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	PAT_END
pat_0801D091:				@ used by s12c3
	N	29, 14, 4            @ F#4
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	38, 11, 4            @ D#5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	41, 11, 4            @ F#5
	N	29, 14, 4            @ F#4
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	41, 11, 4            @ F#5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	29, 11, 4            @ F#4
	N	36, 11, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	36, 14, 4            @ C#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	29, 14, 4            @ F#4
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	41, 11, 4            @ F#5
	N	33, 11, 4            @ A#4
	N	41, 11, 4            @ F#5
	N	29, 14, 4            @ F#4
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	41, 11, 4            @ F#5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	36, 14, 4            @ C#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	38, 14, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	31, 14, 4            @ G#4
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	35, 11, 4            @ C5
	N	43, 11, 4            @ G#5
	PAT_END
pat_0801D212:				@ used by s12c3
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	36, 14, 2            @ C#5
	N	35, 11, 2            @ C5
	N	33, 11, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	35, 14, 4            @ C5
	N	37, 11, 4            @ D5
	N	33, 11, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 14, 2            @ A#4
	N	35, 11, 2            @ C5
	N	37, 11, 4            @ D5
	N	38, 11, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	41, 11, 4            @ F#5
	N	38, 11, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	36, 11, 2            @ C#5
	N	35, 11, 2            @ C5
	N	33, 11, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	37, 11, 4            @ D5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	PAT_END
pat_0801D2E2:				@ used by s12c3
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	42, 11, 4            @ G5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	42, 11, 4            @ G5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	38, 14, 4            @ D#5
	N	45, 11, 4            @ A#5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	41, 11, 4            @ F#5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	31, 14, 4            @ G#4
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	29, 14, 4            @ F#4
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	29, 11, 4            @ F#4
	N	36, 11, 4            @ C#5
	N	28, 14, 4            @ F4
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	28, 11, 4            @ F4
	N	35, 11, 4            @ C5
	N	28, 14, 4            @ F4
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	28, 11, 4            @ F4
	N	35, 11, 4            @ C5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	28, 11, 4            @ F4
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	33, 14, 4            @ A#4
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	PAT_END
pat_0801D463:				@ used by s12c4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 4             @ C#4
	N	26, 2, 2             @ D#4
	N	26, 2, 2             @ D#4
	N	24, 1, 2             @ C#4
	N	26, 2, 2             @ D#4
	N	26, 2, 4             @ D#4
	PAT_END
pat_0801D5D8:				@ used by s11c1
	N	69, 16, 12           @ A#7
	N	69, 16, 8            @ A#7
	N	67, 16, 8            @ G#7
	N	64, 16, 10           @ F7
	PAT_END
pat_0801D5E5:				@ used by s11c1
	N	57, 16, 6            @ A#6
	N	64, 16, 8            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	59, 16, 2            @ C7
	N	60, 16, 2            @ C#7
	N	57, 16, 6            @ A#6
	N	52, 16, 9            @ F6
	N	57, 16, 2            @ A#6
	N	60, 16, 2            @ C#7
	N	62, 16, 2            @ D#7
	N	63, 16, 2            @ E7
	N	64, 16, 2            @ F7
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 4            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	62, 16, 2            @ D#7
	N	64, 16, 2            @ F7
	N	62, 16, 4            @ D#7
	N	60, 16, 2            @ C#7
	N	59, 16, 4            @ C7
	N	60, 16, 2            @ C#7
	N	59, 16, 2            @ C7
	N	60, 16, 2            @ C#7
	N	57, 16, 4            @ A#6
	N	55, 16, 4            @ G#6
	N	57, 16, 6            @ A#6
	N	64, 16, 8            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	62, 16, 2            @ D#7
	N	59, 16, 2            @ C7
	N	57, 16, 6            @ A#6
	N	52, 16, 9            @ F6
	N	57, 16, 2            @ A#6
	N	60, 16, 2            @ C#7
	N	62, 16, 2            @ D#7
	N	63, 16, 2            @ E7
	N	64, 16, 2            @ F7
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 2            @ A#7
	N	72, 16, 2            @ C#8
	N	74, 16, 2            @ D#8
	N	75, 16, 2            @ E8
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 10           @ A#7
	PAT_END
pat_0801D691:				@ used by s11c1
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	65, 16, 7            @ F#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 6            @ F7
	N	60, 16, 6            @ C#7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	74, 16, 4            @ D#8
	N	76, 16, 2            @ F8
	N	77, 16, 2            @ F#8
	N	76, 16, 4            @ F8
	N	74, 16, 2            @ D#8
	N	76, 16, 21           @ F8
	N	81, 16, 2            @ A#8
	N	76, 16, 2            @ F8
	N	72, 16, 2            @ C#8
	N	76, 16, 2            @ F8
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	64, 16, 2            @ F7
	N	69, 16, 2            @ A#7
	N	71, 16, 2            @ C8
	N	72, 16, 2            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 2            @ A#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 4            @ G#7
	N	65, 16, 4            @ F#7
	N	64, 16, 7            @ F7
	N	62, 16, 4            @ D#7
	N	57, 16, 2            @ A#6
	N	60, 16, 2            @ C#7
	N	62, 16, 2            @ D#7
	N	63, 16, 2            @ E7
	N	64, 16, 2            @ F7
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 2            @ A#7
	N	72, 16, 2            @ C#8
	N	74, 16, 2            @ D#8
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 4            @ C#8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 10           @ A#7
	PAT_END
pat_0801D785:				@ used by s11c1
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	62, 16, 2            @ D#7
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	62, 16, 2            @ D#7
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	62, 16, 2            @ D#7
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	62, 16, 2            @ D#7
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	62, 16, 4            @ D#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	74, 16, 2            @ D#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	77, 16, 2            @ F#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	77, 16, 2            @ F#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	77, 16, 2            @ F#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	77, 16, 2            @ F#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	77, 16, 2            @ F#8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	76, 16, 2            @ F8
	N	76, 16, 7            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 7            @ C8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 4            @ A#7
	N	72, 16, 4            @ C#8
	N	74, 16, 2            @ D#8
	N	75, 16, 2            @ E8
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	69, 16, 4            @ A#7
	N	76, 16, 2            @ F8
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	76, 16, 2            @ F8
	N	72, 16, 2            @ C#8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	69, 16, 2            @ A#7
	N	72, 16, 2            @ C#8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	72, 16, 2            @ C#8
	N	69, 16, 24           @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	67, 16, 2            @ G#7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 6            @ A#7
	PAT_END
pat_0801D987:				@ used by s11c1
	N	79, 16, 2            @ G#8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	79, 16, 2            @ G#8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	79, 16, 2            @ G#8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	79, 16, 2            @ G#8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	79, 16, 2            @ G#8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	79, 16, 2            @ G#8
	N	78, 16, 2            @ G8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	78, 16, 2            @ G8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	78, 16, 2            @ G8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	78, 16, 2            @ G8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	78, 16, 2            @ G8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	78, 16, 2            @ G8
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	71, 16, 2            @ C8
	N	75, 16, 2            @ E8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	75, 16, 2            @ E8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	75, 16, 2            @ E8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	75, 16, 2            @ E8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	76, 16, 2            @ F8
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	76, 16, 2            @ F8
	N	77, 16, 7            @ F#8
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	76, 16, 7            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	74, 16, 2            @ D#8
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 2            @ C#8
	N	69, 16, 5            @ A#7
	N	67, 16, 4            @ G#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	69, 16, 2            @ A#7
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	62, 16, 2            @ D#7
	N	71, 16, 2            @ C8
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	62, 16, 2            @ D#7
	N	72, 16, 2            @ C#8
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	72, 16, 2            @ C#8
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	71, 16, 2            @ C8
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	69, 16, 2            @ A#7
	N	65, 16, 2            @ F#7
	N	62, 16, 4            @ D#7
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 2            @ A#6
	N	57, 16, 2            @ A#6
	N	52, 16, 2            @ F6
	N	55, 16, 2            @ G#6
	N	56, 16, 2            @ A6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 7            @ A#6
	N	57, 16, 2            @ A#6
	N	60, 16, 2            @ C#7
	N	62, 16, 2            @ D#7
	N	64, 16, 4            @ F7
	N	64, 16, 4            @ F7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 4            @ C#7
	N	57, 16, 4            @ A#6
	N	55, 16, 4            @ G#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 7            @ A#6
	N	52, 16, 2            @ F6
	N	55, 16, 2            @ G#6
	N	56, 16, 2            @ A6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 2            @ A#6
	N	55, 16, 4            @ G#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 2            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 4            @ A#6
	N	52, 16, 2            @ F6
	N	55, 16, 2            @ G#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 7            @ A#6
	N	57, 16, 2            @ A#6
	N	60, 16, 2            @ C#7
	N	62, 16, 2            @ D#7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 4            @ C#7
	N	57, 16, 4            @ A#6
	N	57, 16, 2            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	52, 16, 2            @ F6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	59, 16, 4            @ C7
	N	55, 16, 2            @ G#6
	N	57, 16, 21           @ A#6
	PAT_END
pat_0801DBAA:				@ used by s11c1
	N	64, 16, 6            @ F7
	N	69, 16, 4            @ A#7
	N	64, 16, 4            @ F7
	N	60, 16, 6            @ C#7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	57, 16, 6            @ A#6
	N	60, 16, 4            @ C#7
	N	57, 16, 2            @ A#6
	N	52, 16, 21           @ F6
	N	52, 16, 4            @ F6
	N	57, 16, 4            @ A#6
	N	60, 16, 4            @ C#7
	N	57, 16, 4            @ A#6
	N	59, 16, 4            @ C7
	N	57, 16, 4            @ A#6
	N	55, 16, 6            @ G#6
	N	55, 16, 4            @ G#6
	N	59, 16, 4            @ C7
	N	62, 16, 4            @ D#7
	N	59, 16, 4            @ C7
	N	60, 16, 6            @ C#7
	N	57, 16, 6            @ A#6
	N	56, 16, 6            @ A6
	N	55, 16, 4            @ G#6
	N	56, 16, 2            @ A6
	N	53, 16, 5            @ F#6
	N	55, 16, 4            @ G#6
	N	56, 16, 4            @ A6
	N	60, 16, 4            @ C#7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	68, 16, 4            @ A7
	N	67, 16, 2            @ G#7
	N	65, 16, 23           @ F#7
	N	70, 16, 4            @ B7
	N	71, 16, 6            @ C8
	N	72, 16, 6            @ C#8
	N	68, 16, 6            @ A7
	N	67, 16, 6            @ G#7
	N	68, 16, 6            @ A7
	N	65, 16, 9            @ F#7
	N	64, 16, 6            @ F7
	N	62, 16, 4            @ D#7
	N	64, 16, 2            @ F7
	N	60, 16, 5            @ C#7
	N	64, 16, 4            @ F7
	N	59, 16, 4            @ C7
	N	64, 16, 4            @ F7
	N	57, 16, 4            @ A#6
	N	59, 16, 4            @ C7
	N	60, 16, 4            @ C#7
	N	62, 16, 2            @ D#7
	N	64, 16, 21           @ F7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	60, 16, 4            @ C#7
	N	64, 16, 4            @ F7
	N	59, 16, 4            @ C7
	N	64, 16, 4            @ F7
	N	57, 16, 6            @ A#6
	N	60, 16, 6            @ C#7
	N	62, 16, 4            @ D#7
	N	64, 16, 8            @ F7
	N	63, 16, 4            @ E7
	N	60, 16, 2            @ C#7
	N	63, 16, 2            @ E7
	N	67, 16, 4            @ G#7
	N	63, 16, 4            @ E7
	N	72, 16, 7            @ C#8
	N	74, 16, 4            @ D#8
	N	75, 16, 6            @ E8
	N	74, 16, 4            @ D#8
	N	72, 16, 2            @ C#8
	N	75, 16, 23           @ E8
	N	72, 16, 2            @ C#8
	N	74, 16, 2            @ D#8
	N	75, 16, 4            @ E8
	N	72, 16, 4            @ C#8
	N	74, 16, 4            @ D#8
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	67, 16, 4            @ G#7
	N	68, 16, 4            @ A7
	N	65, 16, 4            @ F#7
	N	67, 16, 4            @ G#7
	N	63, 16, 4            @ E7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	63, 16, 8            @ E7
	N	64, 16, 6            @ F7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 4            @ C#7
	N	59, 16, 4            @ C7
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	55, 16, 2            @ G#6
	N	57, 16, 21           @ A#6
	N	64, 16, 2            @ F7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 4            @ F7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	72, 16, 4            @ C#8
	N	69, 16, 4            @ A#7
	N	67, 16, 2            @ G#7
	N	64, 16, 4            @ F7
	N	69, 16, 21           @ A#7
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 4            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 4            @ A#7
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 23           @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	59, 16, 6            @ C7
	N	57, 16, 4            @ A#6
	N	60, 16, 4            @ C#7
	N	57, 16, 6            @ A#6
	N	55, 16, 4            @ G#6
	N	52, 16, 4            @ F6
	N	57, 16, 10           @ A#6
	PAT_END
pat_0801DD58:				@ used by s11c2
	N	64, 7, 4             @ F7
	N	57, 7, 4             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	65, 7, 4             @ F#7
	N	64, 7, 4             @ F7
	N	64, 7, 4             @ F7
	N	57, 7, 4             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	62, 7, 4             @ D#7
	N	60, 7, 4             @ C#7
	N	64, 7, 4             @ F7
	N	57, 7, 4             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	65, 7, 4             @ F#7
	N	64, 7, 4             @ F7
	N	64, 7, 4             @ F7
	N	57, 7, 4             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	57, 7, 2             @ A#6
	N	64, 7, 4             @ F7
	N	62, 7, 2             @ D#7
	N	60, 7, 2             @ C#7
	N	59, 7, 4             @ C7
	PAT_END
pat_0801DDC8:				@ used by s11c3
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	31, 11, 2            @ G#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	36, 11, 2            @ C#5
	N	38, 11, 2            @ D#5
	N	39, 11, 2            @ E5
	N	40, 11, 2            @ F5
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	31, 11, 2            @ G#4
	N	28, 11, 2            @ F4
	N	31, 11, 2            @ G#4
	N	32, 11, 2            @ A4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	36, 11, 2            @ C#5
	N	38, 11, 2            @ D#5
	N	39, 11, 2            @ E5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	28, 11, 2            @ F4
	N	31, 11, 2            @ G#4
	N	32, 11, 2            @ A4
	PAT_END
pat_0801DE5C:				@ used by s11c4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	26, 2, 2             @ D#4
	N	26, 2, 2             @ D#4
	PAT_END
pat_0801DF1A:				@ used by s10c1
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 4            @ C#7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 4            @ C7
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 4            @ B6
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 2            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 4            @ C#7
	N	60, 16, 4            @ C#7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 2            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 4            @ C7
	N	59, 16, 4            @ C7
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 2            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 4            @ B6
	N	58, 16, 4            @ B6
	N	57, 16, 2            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 2            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 2            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 2            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	N	57, 16, 4            @ A#6
	PAT_END
pat_0801E00B:				@ used by s10c1
	N	60, 16, 6            @ C#7
	N	67, 16, 8            @ G#7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	62, 16, 6            @ D#7
	N	55, 16, 9            @ G#6
	N	63, 16, 6            @ E7
	N	70, 16, 8            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	63, 16, 2            @ E7
	N	65, 16, 6            @ F#7
	N	58, 16, 9            @ B6
	N	60, 16, 6            @ C#7
	N	67, 16, 8            @ G#7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	62, 16, 6            @ D#7
	N	55, 16, 22           @ G#6
	N	55, 16, 2            @ G#6
	N	57, 16, 2            @ A#6
	N	58, 16, 4            @ B6
	N	53, 16, 4            @ F#6
	N	58, 16, 4            @ B6
	N	62, 16, 4            @ D#7
	N	65, 16, 4            @ F#7
	N	62, 16, 4            @ D#7
	N	65, 16, 4            @ F#7
	N	70, 16, 4            @ B7
	N	69, 16, 7            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	69, 16, 8            @ A#7
	PAT_END
pat_0801E07E:				@ used by s10c1
	N	72, 16, 4            @ C#8
	N	72, 16, 4            @ C#8
	N	67, 16, 4            @ G#7
	N	67, 16, 2            @ G#7
	N	64, 16, 4            @ F7
	N	64, 16, 4            @ F7
	N	64, 16, 2            @ F7
	N	67, 16, 4            @ G#7
	N	60, 16, 4            @ C#7
	N	62, 16, 2            @ D#7
	N	64, 16, 2            @ F7
	N	65, 16, 22           @ F#7
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	63, 16, 4            @ E7
	N	58, 16, 4            @ B6
	N	63, 16, 4            @ E7
	N	67, 16, 2            @ G#7
	N	70, 16, 2            @ B7
	N	75, 16, 7            @ E8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	74, 16, 10           @ D#8
	N	76, 16, 2            @ F8
	N	72, 16, 2            @ C#8
	N	67, 16, 2            @ G#7
	N	72, 16, 2            @ C#8
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	67, 16, 2            @ G#7
	N	64, 16, 2            @ F7
	N	60, 16, 7            @ C#7
	N	62, 16, 2            @ D#7
	N	64, 16, 2            @ F7
	N	62, 16, 4            @ D#7
	N	59, 16, 4            @ C7
	N	55, 16, 22           @ G#6
	N	55, 16, 2            @ G#6
	N	57, 16, 2            @ A#6
	N	58, 16, 4            @ B6
	N	62, 16, 4            @ D#7
	N	65, 16, 4            @ F#7
	N	70, 16, 4            @ B7
	N	74, 16, 7            @ D#8
	N	72, 16, 2            @ C#8
	N	70, 16, 2            @ B7
	N	69, 16, 10           @ A#7
	PAT_END
pat_0801E10C:				@ used by s10c1
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	69, 16, 4            @ A#7
	N	67, 16, 4            @ G#7
	N	69, 16, 2            @ A#7
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 4            @ F#7
	N	64, 16, 2            @ F7
	N	62, 16, 21           @ D#7
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	74, 16, 2            @ D#8
	N	74, 16, 4            @ D#8
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	72, 16, 2            @ C#8
	N	72, 16, 4            @ C#8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	71, 16, 2            @ C8
	N	71, 16, 4            @ C8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 10           @ A#7
	PAT_END
pat_0801E1EB:				@ used by s10c1
	N	63, 16, 6            @ E7
	N	70, 16, 8            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	63, 16, 2            @ E7
	N	62, 16, 6            @ D#7
	N	69, 16, 22           @ A#7
	N	62, 16, 4            @ D#7
	N	63, 16, 6            @ E7
	N	70, 16, 8            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	63, 16, 2            @ E7
	N	62, 16, 6            @ D#7
	N	57, 16, 9            @ A#6
	N	63, 16, 6            @ E7
	N	70, 16, 8            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	63, 16, 2            @ E7
	N	62, 16, 6            @ D#7
	N	65, 16, 6            @ F#7
	N	69, 16, 8            @ A#7
	N	63, 16, 6            @ E7
	N	70, 16, 8            @ B7
	N	72, 16, 2            @ C#8
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 10           @ F#7
	PAT_END
pat_0801E24F:				@ used by s10c1
	N	65, 16, 6            @ F#7
	N	72, 16, 8            @ C#8
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 2            @ A#7
	N	70, 16, 6            @ B7
	N	77, 16, 9            @ F#8
	N	77, 16, 6            @ F#8
	N	71, 16, 8            @ C8
	N	74, 16, 2            @ D#8
	N	75, 16, 2            @ E8
	N	77, 16, 2            @ F#8
	N	74, 16, 2            @ D#8
	N	75, 16, 6            @ E8
	N	72, 16, 9            @ C#8
	N	65, 16, 6            @ F#7
	N	72, 16, 8            @ C#8
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 2            @ A#7
	N	70, 16, 6            @ B7
	N	74, 16, 6            @ D#8
	N	77, 16, 8            @ F#8
	N	79, 16, 7            @ G#8
	N	77, 16, 4            @ F#8
	N	75, 16, 4            @ E8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	72, 16, 10           @ C#8
	PAT_END
pat_0801E2B0:				@ used by s10c1
	N	72, 16, 2            @ C#8
	N	67, 16, 4            @ G#7
	N	74, 16, 2            @ D#8
	N	67, 16, 4            @ G#7
	N	75, 16, 2            @ E8
	N	67, 16, 4            @ G#7
	N	74, 16, 2            @ D#8
	N	67, 16, 4            @ G#7
	N	72, 16, 4            @ C#8
	N	75, 16, 4            @ E8
	N	74, 16, 6            @ D#8
	N	71, 16, 6            @ C8
	N	67, 16, 8            @ G#7
	N	75, 16, 2            @ E8
	N	70, 16, 4            @ B7
	N	77, 16, 2            @ F#8
	N	70, 16, 4            @ B7
	N	79, 16, 2            @ G#8
	N	70, 16, 4            @ B7
	N	77, 16, 2            @ F#8
	N	70, 16, 4            @ B7
	N	75, 16, 4            @ E8
	N	79, 16, 4            @ G#8
	N	77, 16, 6            @ F#8
	N	74, 16, 6            @ D#8
	N	70, 16, 8            @ B7
	N	71, 16, 2            @ C8
	N	67, 16, 4            @ G#7
	N	72, 16, 2            @ C#8
	N	67, 16, 4            @ G#7
	N	74, 16, 2            @ D#8
	N	67, 16, 4            @ G#7
	N	77, 16, 2            @ F#8
	N	67, 16, 4            @ G#7
	N	75, 16, 4            @ E8
	N	74, 16, 4            @ D#8
	N	75, 16, 6            @ E8
	N	72, 16, 6            @ C#8
	N	67, 16, 8            @ G#7
	N	74, 16, 2            @ D#8
	N	69, 16, 4            @ A#7
	N	76, 16, 2            @ F8
	N	69, 16, 4            @ A#7
	N	78, 16, 2            @ G8
	N	69, 16, 4            @ A#7
	N	69, 16, 2            @ A#7
	N	81, 16, 4            @ A#8
	N	79, 16, 4            @ G#8
	N	78, 16, 4            @ G8
	N	79, 16, 10           @ G#8
	PAT_END
pat_0801E347:				@ used by s10c1
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	73, 16, 2            @ D8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	68, 16, 2            @ A7
	N	67, 16, 2            @ G#7
	N	66, 16, 2            @ G7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	63, 16, 2            @ E7
	N	62, 16, 2            @ D#7
	N	61, 16, 2            @ D7
	N	60, 16, 2            @ C#7
	N	59, 16, 4            @ C7
	N	55, 16, 4            @ G#6
	N	62, 16, 4            @ D#7
	N	59, 16, 4            @ C7
	N	67, 16, 8            @ G#7
	N	74, 16, 2            @ D#8
	N	73, 16, 2            @ D8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	68, 16, 2            @ A7
	N	67, 16, 2            @ G#7
	N	66, 16, 2            @ G7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	63, 16, 2            @ E7
	N	62, 16, 2            @ D#7
	N	61, 16, 2            @ D7
	N	60, 16, 2            @ C#7
	N	59, 16, 2            @ C7
	N	57, 16, 4            @ A#6
	N	53, 16, 4            @ F#6
	N	60, 16, 4            @ C#7
	N	57, 16, 4            @ A#6
	N	65, 16, 4            @ F#7
	N	60, 16, 4            @ C#7
	N	69, 16, 4            @ A#7
	N	65, 16, 4            @ F#7
	N	76, 16, 2            @ F8
	N	74, 16, 2            @ D#8
	N	73, 16, 2            @ D8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	68, 16, 2            @ A7
	N	67, 16, 2            @ G#7
	N	66, 16, 2            @ G7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	63, 16, 2            @ E7
	N	62, 16, 2            @ D#7
	N	61, 16, 2            @ D7
	N	60, 16, 2            @ C#7
	N	59, 16, 2            @ C7
	N	55, 16, 2            @ G#6
	N	62, 16, 2            @ D#7
	N	59, 16, 2            @ C7
	N	67, 16, 2            @ G#7
	N	62, 16, 2            @ D#7
	N	71, 16, 2            @ C8
	N	67, 16, 2            @ G#7
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 6            @ C8
	N	62, 16, 2            @ D#7
	N	63, 16, 2            @ E7
	N	64, 16, 2            @ F7
	N	65, 16, 2            @ F#7
	N	66, 16, 2            @ G7
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 2            @ A#7
	N	70, 16, 2            @ B7
	N	71, 16, 2            @ C8
	N	72, 16, 2            @ C#8
	N	73, 16, 2            @ D8
	N	74, 16, 6            @ D#8
	N	67, 16, 2            @ G#7
	N	68, 16, 2            @ A7
	N	69, 16, 2            @ A#7
	N	70, 16, 2            @ B7
	N	71, 16, 2            @ C8
	N	72, 16, 2            @ C#8
	N	73, 16, 2            @ D8
	N	74, 16, 2            @ D#8
	N	75, 16, 2            @ E8
	N	76, 16, 2            @ F8
	N	77, 16, 2            @ F#8
	N	78, 16, 2            @ G8
	N	79, 16, 6            @ G#8
	PAT_END
pat_0801E46E:				@ used by s10c2
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	63, 28, 2            @ E7
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	63, 28, 2            @ E7
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	63, 28, 2            @ E7
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	63, 28, 2            @ E7
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	58, 28, 2            @ B6
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	58, 28, 2            @ B6
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	58, 28, 2            @ B6
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	67, 28, 2            @ G#7
	N	69, 28, 2            @ A#7
	N	67, 28, 2            @ G#7
	N	64, 28, 2            @ F7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	65, 28, 2            @ F#7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	60, 28, 2            @ C#7
	N	65, 28, 2            @ F#7
	N	69, 28, 2            @ A#7
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	65, 28, 2            @ F#7
	N	69, 28, 2            @ A#7
	N	57, 28, 2            @ A#6
	N	60, 28, 2            @ C#7
	N	65, 28, 2            @ F#7
	N	69, 28, 2            @ A#7
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	65, 28, 2            @ F#7
	N	69, 28, 2            @ A#7
	PAT_END
pat_0801E5EF:				@ used by s10c2
	N	67, 28, 2            @ G#7
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	67, 28, 2            @ G#7
	N	62, 28, 2            @ D#7
	N	59, 28, 2            @ C7
	N	67, 28, 2            @ G#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	67, 28, 2            @ G#7
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	67, 28, 2            @ G#7
	N	62, 28, 2            @ D#7
	N	59, 28, 2            @ C7
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	65, 28, 2            @ F#7
	PAT_END
pat_0801E650:				@ used by s10c2
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	62, 28, 2            @ D#7
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	57, 28, 2            @ A#6
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	65, 28, 2            @ F#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	65, 28, 2            @ F#7
	PAT_END
pat_0801E6B1:				@ used by s10c2
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	62, 28, 2            @ D#7
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	57, 28, 2            @ A#6
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	67, 28, 2            @ G#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	57, 28, 2            @ A#6
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	60, 28, 2            @ C#7
	N	57, 28, 2            @ A#6
	N	65, 28, 2            @ F#7
	PAT_END
pat_0801E712:				@ used by s10c2
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	63, 28, 2            @ E7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	63, 28, 2            @ E7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	58, 28, 2            @ B6
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	63, 28, 2            @ E7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	63, 28, 2            @ E7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	PAT_END
pat_0801E893:				@ used by s10c2
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	65, 28, 2            @ F#7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	58, 28, 2            @ B6
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	58, 28, 2            @ B6
	N	65, 28, 2            @ F#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	67, 28, 2            @ G#7
	N	58, 28, 2            @ B6
	N	62, 28, 2            @ D#7
	N	58, 28, 2            @ B6
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	65, 28, 2            @ F#7
	N	58, 28, 2            @ B6
	N	63, 28, 2            @ E7
	N	62, 28, 2            @ D#7
	N	58, 28, 2            @ B6
	N	65, 28, 2            @ F#7
	N	58, 28, 2            @ B6
	N	62, 28, 2            @ D#7
	N	63, 28, 2            @ E7
	N	58, 28, 2            @ B6
	N	65, 28, 2            @ F#7
	N	58, 28, 2            @ B6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	59, 28, 2            @ C7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	59, 28, 2            @ C7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	63, 28, 2            @ E7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	62, 28, 2            @ D#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	64, 28, 2            @ F7
	N	57, 28, 2            @ A#6
	N	66, 28, 2            @ G7
	N	57, 28, 2            @ A#6
	N	64, 28, 2            @ F7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	66, 28, 2            @ G7
	N	57, 28, 2            @ A#6
	N	64, 28, 2            @ F7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	66, 28, 2            @ G7
	N	57, 28, 2            @ A#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	PAT_END
pat_0801EA14:				@ used by s10c2
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	64, 28, 2            @ F7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	64, 28, 2            @ F7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	64, 28, 2            @ F7
	N	55, 28, 2            @ G#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	58, 28, 2            @ B6
	N	57, 28, 2            @ A#6
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	53, 28, 2            @ F#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	64, 28, 2            @ F7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	64, 28, 2            @ F7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	64, 28, 2            @ F7
	N	55, 28, 2            @ G#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	64, 28, 2            @ F7
	N	57, 28, 2            @ A#6
	N	66, 28, 2            @ G7
	N	57, 28, 2            @ A#6
	N	64, 28, 2            @ F7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	66, 28, 2            @ G7
	N	57, 28, 2            @ A#6
	N	64, 28, 2            @ F7
	N	62, 28, 2            @ D#7
	N	57, 28, 2            @ A#6
	N	66, 28, 2            @ G7
	N	57, 28, 2            @ A#6
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	N	60, 28, 2            @ C#7
	N	59, 28, 2            @ C7
	N	55, 28, 2            @ G#6
	N	62, 28, 2            @ D#7
	N	55, 28, 2            @ G#6
	PAT_END
pat_0801EB95:				@ used by s10c3
	N	36, 14, 23           @ C#5
	N	31, 14, 2            @ G#4
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	40, 14, 2            @ F5
	N	43, 14, 2            @ G#5
	N	40, 14, 2            @ F5
	N	31, 14, 23           @ G#4
	N	35, 14, 2            @ C5
	N	38, 14, 4            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 2            @ D#5
	N	35, 14, 2            @ C5
	N	31, 14, 4            @ G#4
	N	39, 14, 23           @ E5
	N	34, 14, 2            @ B4
	N	39, 14, 4            @ E5
	N	39, 14, 4            @ E5
	N	39, 14, 2            @ E5
	N	43, 14, 2            @ G#5
	N	39, 14, 4            @ E5
	N	34, 14, 6            @ B4
	N	34, 14, 4            @ B4
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	41, 14, 2            @ F#5
	N	38, 14, 2            @ D#5
	N	34, 14, 4            @ B4
	N	36, 14, 23           @ C#5
	N	31, 14, 2            @ G#4
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	40, 14, 2            @ F5
	N	43, 14, 2            @ G#5
	N	40, 14, 2            @ F5
	N	31, 14, 23           @ G#4
	N	29, 14, 2            @ F#4
	N	31, 14, 4            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 2            @ G#4
	N	35, 14, 2            @ C5
	N	38, 14, 4            @ D#5
	N	34, 14, 7            @ B4
	N	34, 14, 6            @ B4
	N	34, 14, 4            @ B4
	N	34, 14, 2            @ B4
	N	38, 14, 2            @ D#5
	N	41, 14, 4            @ F#5
	N	29, 14, 5            @ F#4
	N	29, 14, 5            @ F#4
	N	29, 14, 6            @ F#4
	N	29, 14, 4            @ F#4
	N	41, 14, 2            @ F#5
	N	36, 14, 2            @ C#5
	N	33, 14, 4            @ A#4
	PAT_END
pat_0801EC41:				@ used by s10c3
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	41, 14, 4            @ F#5
	N	40, 14, 4            @ F5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	35, 14, 4            @ C5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	41, 14, 4            @ F#5
	N	40, 14, 4            @ F5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	38, 14, 2            @ D#5
	N	36, 14, 2            @ C#5
	N	38, 14, 6            @ D#5
	PAT_END
pat_0801ECBA:				@ used by s10c3
	N	27, 14, 2            @ E4
	N	39, 14, 4            @ E5
	N	27, 14, 2            @ E4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	36, 14, 4            @ C#5
	N	27, 14, 2            @ E4
	N	34, 14, 4            @ B4
	N	39, 14, 4            @ E5
	N	27, 14, 4            @ E4
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	36, 14, 4            @ C#5
	N	26, 14, 2            @ D#4
	N	34, 14, 4            @ B4
	N	26, 14, 2            @ D#4
	N	33, 14, 4            @ A#4
	N	26, 14, 4            @ D#4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	39, 14, 4            @ E5
	N	27, 14, 2            @ E4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	36, 14, 4            @ C#5
	N	27, 14, 2            @ E4
	N	34, 14, 2            @ B4
	N	27, 14, 2            @ E4
	N	39, 14, 4            @ E5
	N	27, 14, 4            @ E4
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	36, 14, 4            @ C#5
	N	26, 14, 2            @ D#4
	N	34, 14, 4            @ B4
	N	26, 14, 2            @ D#4
	N	33, 14, 4            @ A#4
	N	26, 14, 4            @ D#4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	39, 14, 4            @ E5
	N	27, 14, 2            @ E4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	36, 14, 4            @ C#5
	N	27, 14, 2            @ E4
	N	39, 14, 4            @ E5
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	36, 14, 2            @ C#5
	N	26, 14, 2            @ D#4
	N	38, 14, 4            @ D#5
	N	26, 14, 2            @ D#4
	N	36, 14, 4            @ C#5
	N	26, 14, 2            @ D#4
	N	34, 14, 4            @ B4
	N	26, 14, 2            @ D#4
	N	33, 14, 4            @ A#4
	N	26, 14, 4            @ D#4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	39, 14, 4            @ E5
	N	27, 14, 2            @ E4
	N	38, 14, 4            @ D#5
	N	27, 14, 2            @ E4
	N	36, 14, 4            @ C#5
	N	27, 14, 2            @ E4
	N	34, 14, 4            @ B4
	N	39, 14, 4            @ E5
	N	27, 14, 4            @ E4
	N	29, 14, 2            @ F#4
	N	41, 14, 4            @ F#5
	N	29, 14, 2            @ F#4
	N	39, 14, 4            @ E5
	N	29, 14, 2            @ F#4
	N	38, 14, 4            @ D#5
	N	29, 14, 2            @ F#4
	N	36, 14, 4            @ C#5
	N	34, 14, 4            @ B4
	N	33, 14, 4            @ A#4
	PAT_END
pat_0801EDB1:				@ used by s10c3
	N	29, 14, 2            @ F#4
	N	41, 14, 4            @ F#5
	N	29, 14, 2            @ F#4
	N	41, 14, 4            @ F#5
	N	29, 14, 2            @ F#4
	N	41, 14, 4            @ F#5
	N	29, 14, 2            @ F#4
	N	41, 14, 4            @ F#5
	N	39, 14, 4            @ E5
	N	38, 14, 4            @ D#5
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	29, 14, 2            @ F#4
	N	34, 14, 4            @ B4
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	34, 14, 4            @ B4
	N	33, 14, 2            @ A#4
	N	32, 14, 2            @ A4
	N	31, 14, 2            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	41, 14, 4            @ F#5
	N	31, 14, 2            @ G#4
	N	39, 14, 4            @ E5
	N	38, 14, 4            @ D#5
	N	39, 14, 4            @ E5
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	34, 14, 2            @ B4
	N	33, 14, 2            @ A#4
	N	31, 14, 2            @ G#4
	N	29, 14, 2            @ F#4
	N	41, 14, 4            @ F#5
	N	29, 14, 2            @ F#4
	N	39, 14, 4            @ E5
	N	29, 14, 2            @ F#4
	N	38, 14, 4            @ D#5
	N	29, 14, 2            @ F#4
	N	36, 14, 4            @ C#5
	N	34, 14, 4            @ B4
	N	33, 14, 4            @ A#4
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	29, 14, 2            @ F#4
	N	34, 14, 4            @ B4
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	34, 14, 4            @ B4
	N	33, 14, 2            @ A#4
	N	32, 14, 2            @ A4
	N	31, 14, 2            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	41, 14, 4            @ F#5
	N	31, 14, 2            @ G#4
	N	39, 14, 4            @ E5
	N	38, 14, 4            @ D#5
	N	39, 14, 4            @ E5
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	31, 14, 4            @ G#4
	N	34, 14, 4            @ B4
	PAT_END
pat_0801EEAE:				@ used by s10c3
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	34, 14, 4            @ B4
	N	36, 14, 4            @ C#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	41, 14, 4            @ F#5
	N	31, 14, 2            @ G#4
	N	39, 14, 4            @ E5
	N	31, 14, 2            @ G#4
	N	38, 14, 4            @ D#5
	N	31, 14, 4            @ G#4
	N	38, 14, 4            @ D#5
	N	39, 14, 2            @ E5
	N	39, 14, 4            @ E5
	N	34, 14, 2            @ B4
	N	39, 14, 4            @ E5
	N	39, 14, 2            @ E5
	N	38, 14, 2            @ D#5
	N	39, 14, 4            @ E5
	N	39, 14, 4            @ E5
	N	39, 14, 2            @ E5
	N	34, 14, 2            @ B4
	N	39, 14, 4            @ E5
	N	34, 14, 5            @ B4
	N	34, 14, 2            @ B4
	N	46, 14, 4            @ B5
	N	34, 14, 2            @ B4
	N	41, 14, 4            @ F#5
	N	34, 14, 2            @ B4
	N	38, 14, 4            @ D#5
	N	34, 14, 4            @ B4
	N	38, 14, 4            @ D#5
	N	31, 14, 2            @ G#4
	N	31, 14, 4            @ G#4
	N	38, 14, 2            @ D#5
	N	31, 14, 4            @ G#4
	N	35, 14, 2            @ C5
	N	31, 14, 4            @ G#4
	N	31, 14, 2            @ G#4
	N	29, 14, 4            @ F#4
	N	31, 14, 4            @ G#4
	N	31, 14, 4            @ G#4
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	34, 14, 2            @ B4
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	34, 14, 4            @ B4
	N	36, 14, 4            @ C#5
	N	38, 14, 2            @ D#5
	N	38, 14, 4            @ D#5
	N	36, 14, 2            @ C#5
	N	33, 14, 4            @ A#4
	N	38, 14, 2            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 2            @ D#5
	N	36, 14, 4            @ C#5
	N	33, 14, 4            @ A#4
	N	38, 14, 4            @ D#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	41, 14, 4            @ F#5
	N	31, 14, 2            @ G#4
	N	39, 14, 4            @ E5
	N	31, 14, 2            @ G#4
	N	38, 14, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	35, 14, 4            @ C5
	PAT_END
pat_0801EF9F:				@ used by s10c3
	N	36, 14, 2            @ C#5
	N	36, 14, 4            @ C#5
	N	35, 14, 2            @ C5
	N	36, 14, 4            @ C#5
	N	31, 14, 5            @ G#4
	N	35, 14, 4            @ C5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	35, 14, 2            @ C5
	N	36, 14, 2            @ C#5
	N	31, 14, 2            @ G#4
	N	31, 14, 4            @ G#4
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	41, 14, 4            @ F#5
	N	31, 14, 2            @ G#4
	N	38, 14, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	35, 14, 4            @ C5
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	29, 14, 2            @ F#4
	N	34, 14, 4            @ B4
	N	36, 14, 2            @ C#5
	N	38, 14, 4            @ D#5
	N	34, 14, 4            @ B4
	N	34, 14, 2            @ B4
	N	34, 14, 4            @ B4
	N	33, 14, 2            @ A#4
	N	31, 14, 2            @ G#4
	N	33, 14, 2            @ A#4
	N	29, 14, 4            @ F#4
	N	36, 14, 4            @ C#5
	N	29, 14, 2            @ F#4
	N	41, 14, 5            @ F#5
	N	29, 14, 2            @ F#4
	N	33, 14, 2            @ A#4
	N	29, 14, 2            @ F#4
	N	36, 14, 4            @ C#5
	N	29, 14, 4            @ F#4
	N	36, 14, 5            @ C#5
	N	31, 14, 4            @ G#4
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	36, 14, 2            @ C#5
	N	40, 14, 2            @ F5
	N	36, 14, 2            @ C#5
	N	31, 14, 5            @ G#4
	N	31, 14, 2            @ G#4
	N	38, 14, 4            @ D#5
	N	31, 14, 2            @ G#4
	N	43, 14, 4            @ G#5
	N	31, 14, 2            @ G#4
	N	38, 14, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	31, 14, 4            @ G#4
	N	38, 14, 5            @ D#5
	N	36, 14, 2            @ C#5
	N	38, 14, 4            @ D#5
	N	33, 14, 2            @ A#4
	N	38, 14, 4            @ D#5
	N	38, 14, 4            @ D#5
	N	38, 14, 2            @ D#5
	N	33, 14, 2            @ A#4
	N	38, 14, 2            @ D#5
	N	36, 14, 2            @ C#5
	N	38, 14, 2            @ D#5
	N	31, 14, 5            @ G#4
	N	31, 14, 2            @ G#4
	N	38, 14, 4            @ D#5
	N	31, 14, 2            @ G#4
	N	36, 14, 4            @ C#5
	N	31, 14, 2            @ G#4
	N	35, 14, 4            @ C5
	N	33, 14, 4            @ A#4
	N	31, 14, 4            @ G#4
	PAT_END
pat_0801F08D:				@ used by s10c4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 2             @ D#4
	N	24, 1, 2             @ C#4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	26, 2, 2             @ D#4
	N	26, 2, 4             @ D#4
	PAT_END
pat_0801F1D8:				@ used by s9c1
	N	64, 27, 2            @ F7
	N	60, 27, 2            @ C#7
	N	67, 27, 2            @ G#7
	N	60, 27, 2            @ C#7
	N	66, 27, 7            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	66, 27, 4            @ G7
	N	64, 27, 5            @ F7
	N	60, 27, 5            @ C#7
	N	55, 27, 8            @ G#6
	REST	0, 4
	N	64, 27, 2            @ F7
	N	60, 27, 2            @ C#7
	N	67, 27, 2            @ G#7
	N	60, 27, 2            @ C#7
	N	66, 27, 7            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	66, 27, 4            @ G7
	N	64, 27, 10           @ F7
	N	69, 27, 2            @ A#7
	N	64, 27, 2            @ F7
	N	71, 27, 2            @ C8
	N	64, 27, 2            @ F7
	N	73, 27, 7            @ D8
	N	76, 27, 4            @ F8
	N	74, 27, 4            @ D#8
	N	73, 27, 4            @ D8
	N	71, 27, 5            @ C8
	N	67, 27, 5            @ G#7
	N	64, 27, 8            @ F7
	REST	0, 4
	N	69, 27, 2            @ A#7
	N	65, 27, 2            @ F#7
	N	71, 27, 2            @ C8
	N	65, 27, 2            @ F#7
	N	72, 27, 7            @ C#8
	N	71, 27, 4            @ C8
	N	69, 27, 4            @ A#7
	N	72, 27, 4            @ C#8
	N	74, 27, 5            @ D#8
	N	71, 27, 5            @ C8
	N	67, 27, 8            @ G#7
	REST	0, 4
	PAT_END
pat_0801F260:				@ used by s9c1
	N	60, 10, 4            @ C#7
	N	67, 10, 4            @ G#7
	N	66, 10, 2            @ G7
	N	64, 10, 2            @ F7
	N	62, 10, 2            @ D#7
	N	64, 10, 4            @ F7
	N	60, 10, 4            @ C#7
	N	55, 10, 4            @ G#6
	N	55, 10, 2            @ G#6
	N	57, 10, 2            @ A#6
	N	59, 10, 2            @ C7
	N	60, 10, 4            @ C#7
	N	67, 10, 4            @ G#7
	N	66, 10, 2            @ G7
	N	64, 10, 2            @ F7
	N	62, 10, 2            @ D#7
	N	64, 10, 8            @ F7
	REST	0, 2
	N	60, 10, 4            @ C#7
	N	67, 10, 4            @ G#7
	N	66, 10, 2            @ G7
	N	64, 10, 2            @ F7
	N	62, 10, 2            @ D#7
	N	64, 10, 4            @ F7
	N	60, 10, 4            @ C#7
	N	55, 10, 4            @ G#6
	N	55, 10, 2            @ G#6
	N	57, 10, 2            @ A#6
	N	59, 10, 2            @ C7
	N	60, 10, 4            @ C#7
	N	67, 10, 4            @ G#7
	N	66, 10, 2            @ G7
	N	64, 10, 2            @ F7
	N	62, 10, 2            @ D#7
	N	64, 10, 8            @ F7
	REST	0, 2
	N	69, 10, 4            @ A#7
	N	76, 10, 4            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 4            @ D8
	N	69, 10, 4            @ A#7
	N	64, 10, 4            @ F7
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 2            @ A7
	N	69, 10, 4            @ A#7
	N	76, 10, 4            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 7            @ D8
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 2            @ A7
	N	69, 10, 4            @ A#7
	N	76, 10, 4            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 4            @ D8
	N	69, 10, 4            @ A#7
	N	64, 10, 4            @ F7
	N	64, 10, 2            @ F7
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	67, 10, 4            @ G#7
	N	67, 10, 4            @ G#7
	N	66, 10, 2            @ G7
	N	64, 10, 2            @ F7
	N	62, 10, 2            @ D#7
	N	64, 10, 8            @ F7
	REST	0, 2
	N	69, 10, 4            @ A#7
	N	76, 10, 4            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 4            @ D8
	N	69, 10, 4            @ A#7
	N	64, 10, 4            @ F7
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 2            @ A7
	N	69, 10, 4            @ A#7
	N	76, 10, 4            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 7            @ D8
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 2            @ A7
	N	69, 10, 4            @ A#7
	N	76, 10, 4            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 4            @ D8
	N	69, 10, 4            @ A#7
	N	64, 10, 4            @ F7
	N	64, 10, 2            @ F7
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	67, 10, 4            @ G#7
	N	67, 10, 4            @ G#7
	N	66, 10, 2            @ G7
	N	64, 10, 2            @ F7
	N	62, 10, 2            @ D#7
	N	64, 10, 8            @ F7
	REST	0, 2
	PAT_END
pat_0801F3B1:				@ used by s9c1
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	75, 10, 2            @ E8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	77, 10, 2            @ F#8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	74, 10, 2            @ D#8
	N	69, 10, 2            @ A#7
	N	72, 10, 2            @ C#8
	N	69, 10, 2            @ A#7
	N	71, 10, 4            @ C8
	N	69, 10, 4            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 2            @ C#8
	N	71, 10, 4            @ C8
	N	69, 10, 4            @ A#7
	N	71, 10, 4            @ C8
	N	68, 10, 4            @ A7
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 4            @ A7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	75, 10, 2            @ E8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	77, 10, 2            @ F#8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	74, 10, 2            @ D#8
	N	69, 10, 2            @ A#7
	N	72, 10, 2            @ C#8
	N	69, 10, 2            @ A#7
	N	71, 10, 4            @ C8
	N	69, 10, 4            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 2            @ C#8
	N	76, 10, 4            @ F8
	N	64, 10, 4            @ F7
	N	69, 10, 6            @ A#7
	REST	0, 2
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 2            @ C#8
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	75, 10, 2            @ E8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	77, 10, 2            @ F#8
	N	69, 10, 2            @ A#7
	N	79, 10, 2            @ G#8
	N	69, 10, 2            @ A#7
	N	81, 10, 2            @ A#8
	N	69, 10, 2            @ A#7
	N	79, 10, 2            @ G#8
	N	69, 10, 2            @ A#7
	N	77, 10, 2            @ F#8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	74, 10, 2            @ D#8
	N	69, 10, 2            @ A#7
	N	72, 10, 4            @ C#8
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	71, 10, 4            @ C8
	N	68, 10, 4            @ A7
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 4            @ A7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	75, 10, 2            @ E8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	77, 10, 2            @ F#8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	69, 10, 2            @ A#7
	N	74, 10, 2            @ D#8
	N	69, 10, 2            @ A#7
	N	72, 10, 2            @ C#8
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	72, 10, 2            @ C#8
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	76, 10, 2            @ F8
	N	64, 10, 2            @ F7
	N	66, 10, 2            @ G7
	N	68, 10, 2            @ A7
	N	69, 10, 8            @ A#7
	PAT_END
pat_0801F4E7:				@ used by s9c1
	N	57, 27, 6            @ A#6
	N	64, 27, 8            @ F7
	N	67, 27, 4            @ G#7
	N	66, 27, 2            @ G7
	N	64, 27, 2            @ F7
	N	66, 27, 4            @ G7
	N	62, 27, 4            @ D#7
	N	57, 27, 7            @ A#6
	N	66, 27, 4            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	64, 27, 4            @ F7
	N	60, 27, 4            @ C#7
	N	57, 27, 7            @ A#6
	N	57, 27, 2            @ A#6
	N	59, 27, 2            @ C7
	N	60, 27, 4            @ C#7
	N	59, 27, 2            @ C7
	N	57, 27, 2            @ A#6
	N	59, 27, 6            @ C7
	N	55, 27, 6            @ G#6
	N	52, 27, 7            @ F6
	N	55, 27, 2            @ G#6
	N	59, 27, 2            @ C7
	N	57, 27, 4            @ A#6
	N	64, 27, 4            @ F7
	N	64, 27, 7            @ F7
	N	67, 27, 4            @ G#7
	N	66, 27, 4            @ G7
	N	64, 27, 4            @ F7
	N	66, 27, 4            @ G7
	N	62, 27, 4            @ D#7
	N	57, 27, 7            @ A#6
	N	66, 27, 4            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	64, 27, 4            @ F7
	N	62, 27, 2            @ D#7
	N	60, 27, 2            @ C#7
	N	62, 27, 4            @ D#7
	N	60, 27, 2            @ C#7
	N	59, 27, 2            @ C7
	N	60, 27, 4            @ C#7
	N	59, 27, 2            @ C7
	N	57, 27, 2            @ A#6
	N	59, 27, 4            @ C7
	N	56, 27, 4            @ A6
	N	57, 27, 8            @ A#6
	N	64, 27, 6            @ F7
	N	69, 27, 6            @ A#7
	N	71, 27, 2            @ C8
	N	69, 27, 2            @ A#7
	N	67, 27, 2            @ G#7
	N	69, 27, 2            @ A#7
	N	71, 27, 4            @ C8
	N	72, 27, 4            @ C#8
	N	74, 27, 4            @ D#8
	N	67, 27, 4            @ G#7
	N	77, 27, 4            @ F#8
	N	76, 27, 2            @ F8
	N	74, 27, 2            @ D#8
	N	76, 27, 4            @ F8
	N	72, 27, 4            @ C#8
	N	67, 27, 4            @ G#7
	N	72, 27, 4            @ C#8
	N	64, 27, 2            @ F7
	N	65, 27, 2            @ F#7
	N	67, 27, 4            @ G#7
	N	64, 27, 2            @ F7
	N	65, 27, 2            @ F#7
	N	67, 27, 4            @ G#7
	N	62, 27, 6            @ D#7
	REST	0, 2
	N	64, 27, 2            @ F7
	N	65, 27, 2            @ F#7
	N	64, 27, 2            @ F7
	N	62, 27, 4            @ D#7
	N	60, 27, 4            @ C#7
	N	59, 27, 4            @ C7
	N	57, 27, 4            @ A#6
	N	64, 27, 6            @ F7
	N	52, 27, 5            @ F6
	N	54, 27, 2            @ G6
	N	56, 27, 4            @ A6
	N	57, 27, 4            @ A#6
	N	59, 27, 4            @ C7
	N	60, 27, 4            @ C#7
	N	57, 27, 6            @ A#6
	N	64, 27, 8            @ F7
	N	67, 27, 4            @ G#7
	N	66, 27, 2            @ G7
	N	64, 27, 2            @ F7
	N	66, 27, 4            @ G7
	N	62, 27, 4            @ D#7
	N	57, 27, 7            @ A#6
	N	66, 27, 4            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	64, 27, 4            @ F7
	N	60, 27, 4            @ C#7
	N	57, 27, 7            @ A#6
	N	57, 27, 2            @ A#6
	N	59, 27, 2            @ C7
	N	60, 27, 4            @ C#7
	N	59, 27, 2            @ C7
	N	57, 27, 2            @ A#6
	N	59, 27, 6            @ C7
	N	55, 27, 6            @ G#6
	N	52, 27, 7            @ F6
	N	55, 27, 2            @ G#6
	N	59, 27, 2            @ C7
	N	57, 27, 4            @ A#6
	N	64, 27, 4            @ F7
	N	64, 27, 7            @ F7
	N	67, 27, 4            @ G#7
	N	66, 27, 4            @ G7
	N	64, 27, 4            @ F7
	N	66, 27, 4            @ G7
	N	62, 27, 4            @ D#7
	N	57, 27, 7            @ A#6
	N	66, 27, 4            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	64, 27, 4            @ F7
	N	62, 27, 2            @ D#7
	N	60, 27, 2            @ C#7
	N	62, 27, 4            @ D#7
	N	60, 27, 2            @ C#7
	N	59, 27, 2            @ C7
	N	60, 27, 4            @ C#7
	N	59, 27, 2            @ C7
	N	57, 27, 2            @ A#6
	N	59, 27, 4            @ C7
	N	56, 27, 4            @ A6
	N	57, 27, 8            @ A#6
	N	54, 27, 8            @ G6
	PAT_END
pat_0801F680:				@ used by s9c1
	N	48, 27, 5            @ C#6
	N	55, 27, 5            @ G#6
	N	54, 27, 6            @ G6
	N	52, 27, 4            @ F6
	N	50, 27, 4            @ D#6
	N	54, 27, 4            @ G6
	N	52, 27, 5            @ F6
	N	55, 27, 5            @ G#6
	N	60, 27, 7            @ C#7
	N	60, 27, 4            @ C#7
	N	62, 27, 4            @ D#7
	N	64, 27, 6            @ F7
	N	62, 27, 4            @ D#7
	N	60, 27, 4            @ C#7
	N	62, 27, 5            @ D#7
	N	59, 27, 5            @ C7
	N	55, 27, 4            @ G#6
	N	60, 27, 9            @ C#7
	N	60, 27, 4            @ C#7
	N	62, 27, 4            @ D#7
	N	64, 27, 5            @ F7
	N	67, 27, 5            @ G#7
	N	66, 27, 6            @ G7
	N	64, 27, 4            @ F7
	N	62, 27, 4            @ D#7
	N	66, 27, 4            @ G7
	N	64, 27, 5            @ F7
	N	60, 27, 5            @ C#7
	N	55, 27, 7            @ G#6
	N	55, 27, 4            @ G#6
	N	57, 27, 4            @ A#6
	N	59, 27, 5            @ C7
	N	60, 27, 5            @ C#7
	N	62, 27, 4            @ D#7
	N	65, 27, 5            @ F#7
	N	64, 27, 5            @ F7
	N	62, 27, 4            @ D#7
	N	60, 27, 10           @ C#7
	PAT_END
pat_0801F6F3:				@ used by s9c2
	N	60, 17, 4            @ C#7
	N	55, 17, 2            @ G#6
	N	64, 17, 5            @ F7
	N	62, 17, 6            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 5            @ C#7
	N	55, 17, 5            @ G#6
	N	52, 17, 8            @ F6
	REST	0, 4
	N	60, 17, 4            @ C#7
	N	55, 17, 4            @ G#6
	N	64, 17, 4            @ F7
	N	62, 17, 6            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 4            @ A#6
	N	56, 17, 10           @ A6
	N	57, 17, 2            @ A#6
	N	52, 17, 2            @ F6
	N	57, 17, 2            @ A#6
	N	61, 17, 2            @ D7
	N	64, 17, 7            @ F7
	N	57, 17, 2            @ A#6
	N	61, 17, 2            @ D7
	N	64, 17, 4            @ F7
	N	69, 17, 4            @ A#7
	N	67, 17, 2            @ G#7
	N	64, 17, 2            @ F7
	N	59, 17, 2            @ C7
	N	64, 17, 2            @ F7
	N	59, 17, 2            @ C7
	N	55, 17, 2            @ G#6
	N	59, 17, 2            @ C7
	N	55, 17, 2            @ G#6
	N	52, 17, 8            @ F6
	N	57, 17, 2            @ A#6
	N	53, 17, 2            @ F#6
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	65, 17, 6            @ F#7
	N	60, 17, 2            @ C#7
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	65, 17, 2            @ F#7
	N	69, 17, 6            @ A#7
	N	67, 17, 5            @ G#7
	N	62, 17, 5            @ D#7
	N	59, 17, 6            @ C7
	N	57, 17, 4            @ A#6
	N	55, 17, 6            @ G#6
	N	60, 17, 2            @ C#7
	N	55, 17, 4            @ G#6
	N	64, 17, 5            @ F7
	N	62, 17, 6            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 5            @ C#7
	N	55, 17, 5            @ G#6
	N	52, 17, 8            @ F6
	REST	0, 4
	N	60, 17, 4            @ C#7
	N	55, 17, 2            @ G#6
	N	64, 17, 5            @ F7
	N	62, 17, 6            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 4            @ A#6
	N	56, 17, 4            @ A6
	N	57, 17, 4            @ A#6
	N	59, 17, 4            @ C7
	N	60, 17, 4            @ C#7
	N	62, 17, 4            @ D#7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	57, 17, 4            @ A#6
	N	52, 17, 2            @ F6
	N	57, 17, 2            @ A#6
	N	61, 17, 4            @ D7
	N	57, 17, 2            @ A#6
	N	61, 17, 2            @ D7
	N	64, 17, 2            @ F7
	N	69, 17, 7            @ A#7
	REST	0, 2
	N	67, 17, 5            @ G#7
	N	64, 17, 5            @ F7
	N	59, 17, 6            @ C7
	N	55, 17, 4            @ G#6
	N	52, 17, 4            @ F6
	N	55, 17, 4            @ G#6
	N	57, 17, 2            @ A#6
	N	53, 17, 2            @ F#6
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	65, 17, 6            @ F#7
	N	65, 17, 2            @ F#7
	N	60, 17, 2            @ C#7
	N	65, 17, 2            @ F#7
	N	69, 17, 2            @ A#7
	N	67, 17, 4            @ G#7
	N	65, 17, 4            @ F#7
	N	64, 17, 5            @ F7
	N	65, 17, 5            @ F#7
	N	62, 17, 8            @ D#7
	REST	0, 4
	PAT_END
pat_0801F838:				@ used by s9c2
	N	72, 10, 4            @ C#8
	N	72, 10, 4            @ C#8
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 4            @ C#8
	N	67, 10, 4            @ G#7
	N	67, 10, 4            @ G#7
	N	67, 10, 2            @ G#7
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 4            @ C#8
	N	72, 10, 4            @ C#8
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 7            @ C#8
	N	67, 10, 2            @ G#7
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 4            @ C#8
	N	72, 10, 4            @ C#8
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 4            @ C#8
	N	67, 10, 4            @ G#7
	N	67, 10, 4            @ G#7
	N	67, 10, 2            @ G#7
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 4            @ C#8
	N	72, 10, 4            @ C#8
	N	74, 10, 2            @ D#8
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	76, 10, 7            @ F8
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 4            @ A#8
	N	81, 10, 2            @ A#8
	N	80, 10, 2            @ A8
	N	78, 10, 2            @ G8
	N	76, 10, 2            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 4            @ D8
	N	71, 10, 4            @ C8
	N	69, 10, 4            @ A#7
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 4            @ A#8
	N	81, 10, 2            @ A#8
	N	80, 10, 2            @ A8
	N	78, 10, 2            @ G8
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 6            @ A#8
	REST	0, 2
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 4            @ A#8
	N	81, 10, 4            @ A#8
	N	81, 10, 2            @ A#8
	N	80, 10, 2            @ A8
	N	78, 10, 2            @ G8
	N	76, 10, 2            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	69, 10, 4            @ A#7
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	73, 10, 2            @ D8
	N	74, 10, 2            @ D#8
	N	76, 10, 2            @ F8
	N	78, 10, 4            @ G8
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 7            @ A#8
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 4            @ A#8
	N	81, 10, 4            @ A#8
	N	81, 10, 2            @ A#8
	N	80, 10, 2            @ A8
	N	78, 10, 2            @ G8
	N	76, 10, 2            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	69, 10, 4            @ A#7
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 4            @ A#8
	N	81, 10, 4            @ A#8
	N	81, 10, 2            @ A#8
	N	80, 10, 2            @ A8
	N	78, 10, 2            @ G8
	N	76, 10, 2            @ F8
	N	81, 10, 6            @ A#8
	REST	0, 2
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 2            @ A#8
	N	80, 10, 2            @ A8
	N	78, 10, 2            @ G8
	N	76, 10, 2            @ F8
	N	74, 10, 2            @ D#8
	N	73, 10, 2            @ D8
	N	71, 10, 2            @ C8
	N	73, 10, 2            @ D8
	N	69, 10, 2            @ A#7
	N	71, 10, 4            @ C8
	N	73, 10, 4            @ D8
	N	69, 10, 2            @ A#7
	N	71, 10, 2            @ C8
	N	73, 10, 2            @ D8
	N	74, 10, 2            @ D#8
	N	76, 10, 2            @ F8
	N	78, 10, 4            @ G8
	N	76, 10, 2            @ F8
	N	78, 10, 2            @ G8
	N	80, 10, 2            @ A8
	N	81, 10, 8            @ A#8
	REST	0, 2
	PAT_END
pat_0801F9C8:				@ used by s9c2
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	72, 10, 2            @ C#8
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	72, 10, 4            @ C#8
	N	74, 10, 2            @ D#8
	N	76, 10, 2            @ F8
	N	74, 10, 4            @ D#8
	N	72, 10, 4            @ C#8
	N	71, 10, 2            @ C8
	N	72, 10, 2            @ C#8
	N	74, 10, 2            @ D#8
	N	72, 10, 2            @ C#8
	N	71, 10, 2            @ C8
	N	69, 10, 2            @ A#7
	N	68, 10, 4            @ A7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	72, 10, 2            @ C#8
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	72, 10, 4            @ C#8
	N	74, 10, 2            @ D#8
	N	76, 10, 2            @ F8
	N	74, 10, 4            @ D#8
	N	72, 10, 2            @ C#8
	N	71, 10, 2            @ C8
	N	72, 10, 4            @ C#8
	N	71, 10, 4            @ C8
	N	69, 10, 6            @ A#7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	72, 10, 2            @ C#8
	N	64, 10, 2            @ F7
	N	74, 10, 2            @ D#8
	N	64, 10, 2            @ F7
	N	72, 10, 2            @ C#8
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	69, 10, 4            @ A#7
	N	71, 10, 2            @ C8
	N	72, 10, 2            @ C#8
	N	74, 10, 4            @ D#8
	N	72, 10, 2            @ C#8
	N	71, 10, 2            @ C8
	N	76, 10, 2            @ F8
	N	74, 10, 2            @ D#8
	N	72, 10, 2            @ C#8
	N	71, 10, 2            @ C8
	N	74, 10, 2            @ D#8
	N	72, 10, 2            @ C#8
	N	71, 10, 4            @ C8
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	72, 10, 2            @ C#8
	N	64, 10, 2            @ F7
	N	71, 10, 2            @ C8
	N	64, 10, 2            @ F7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	68, 10, 2            @ A7
	N	64, 10, 2            @ F7
	N	72, 10, 4            @ C#8
	N	74, 10, 2            @ D#8
	N	76, 10, 2            @ F8
	N	74, 10, 2            @ D#8
	N	72, 10, 2            @ C#8
	N	71, 10, 2            @ C8
	N	72, 10, 2            @ C#8
	N	69, 10, 2            @ A#7
	N	68, 10, 2            @ A7
	N	69, 10, 2            @ A#7
	N	64, 10, 2            @ F7
	N	60, 10, 2            @ C#7
	N	64, 10, 2            @ F7
	N	57, 10, 4            @ A#6
	PAT_END
pat_0801FB19:				@ used by s9c2
	N	57, 17, 6            @ A#6
	N	60, 17, 8            @ C#7
	N	60, 17, 4            @ C#7
	N	59, 17, 2            @ C7
	N	57, 17, 2            @ A#6
	N	57, 17, 4            @ A#6
	N	54, 17, 4            @ G6
	N	50, 17, 7            @ D#6
	N	57, 17, 4            @ A#6
	N	55, 17, 4            @ G#6
	N	54, 17, 4            @ G6
	N	57, 17, 4            @ A#6
	N	52, 17, 4            @ F6
	N	60, 17, 7            @ C#7
	N	60, 17, 2            @ C#7
	N	59, 17, 2            @ C7
	N	57, 17, 4            @ A#6
	N	59, 17, 2            @ C7
	N	60, 17, 2            @ C#7
	N	62, 17, 4            @ D#7
	N	59, 17, 4            @ C7
	N	55, 17, 4            @ G#6
	N	59, 17, 4            @ C7
	N	52, 17, 8            @ F6
	N	57, 17, 6            @ A#6
	N	60, 17, 7            @ C#7
	N	60, 17, 4            @ C#7
	N	60, 17, 4            @ C#7
	N	59, 17, 2            @ C7
	N	57, 17, 2            @ A#6
	N	57, 17, 4            @ A#6
	N	54, 17, 4            @ G6
	N	50, 17, 7            @ D#6
	N	54, 17, 2            @ G6
	N	55, 17, 2            @ G#6
	N	57, 17, 4            @ A#6
	N	55, 17, 2            @ G#6
	N	54, 17, 2            @ G6
	N	60, 17, 6            @ C#7
	N	59, 17, 6            @ C7
	N	57, 17, 6            @ A#6
	N	55, 17, 4            @ G#6
	N	52, 17, 4            @ F6
	N	57, 17, 6            @ A#6
	REST	0, 2
	N	52, 17, 2            @ F6
	N	57, 17, 2            @ A#6
	N	59, 17, 2            @ C7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 6            @ A#6
	N	55, 17, 4            @ G#6
	N	59, 17, 2            @ C7
	N	62, 17, 2            @ D#7
	N	67, 17, 4            @ G#7
	N	62, 17, 2            @ D#7
	N	59, 17, 2            @ C7
	N	55, 17, 2            @ G#6
	N	59, 17, 2            @ C7
	N	62, 17, 2            @ D#7
	N	67, 17, 2            @ G#7
	N	62, 17, 4            @ D#7
	N	59, 17, 4            @ C7
	N	48, 17, 2            @ C#6
	N	52, 17, 2            @ F6
	N	55, 17, 2            @ G#6
	N	60, 17, 2            @ C#7
	N	64, 17, 4            @ F7
	N	60, 17, 4            @ C#7
	N	52, 17, 2            @ F6
	N	55, 17, 2            @ G#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	67, 17, 4            @ G#7
	N	64, 17, 4            @ F7
	N	52, 17, 4            @ F6
	N	56, 17, 2            @ A6
	N	59, 17, 2            @ C7
	N	64, 17, 4            @ F7
	N	59, 17, 2            @ C7
	N	64, 17, 2            @ F7
	N	56, 17, 2            @ A6
	N	59, 17, 2            @ C7
	N	64, 17, 2            @ F7
	N	68, 17, 2            @ A7
	N	64, 17, 4            @ F7
	N	59, 17, 4            @ C7
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 2            @ A#7
	N	64, 17, 4            @ F7
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 4            @ A#7
	N	64, 17, 2            @ F7
	N	60, 17, 2            @ C#7
	N	64, 17, 4            @ F7
	N	69, 17, 4            @ A#7
	N	57, 17, 4            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 4            @ A#7
	N	64, 17, 2            @ F7
	N	60, 17, 2            @ C#7
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 2            @ A#7
	N	52, 17, 4            @ F6
	N	64, 17, 2            @ F7
	N	60, 17, 2            @ C#7
	N	54, 17, 2            @ G6
	N	57, 17, 2            @ A#6
	N	62, 17, 2            @ D#7
	N	66, 17, 2            @ G7
	N	50, 17, 2            @ D#6
	N	57, 17, 2            @ A#6
	N	62, 17, 2            @ D#7
	N	66, 17, 2            @ G7
	N	54, 17, 4            @ G6
	N	66, 17, 2            @ G7
	N	62, 17, 2            @ D#7
	N	57, 17, 4            @ A#6
	N	66, 17, 4            @ G7
	N	57, 17, 2            @ A#6
	N	64, 17, 2            @ F7
	N	69, 17, 2            @ A#7
	N	64, 17, 2            @ F7
	N	57, 17, 4            @ A#6
	N	60, 17, 4            @ C#7
	N	52, 17, 4            @ F6
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 4            @ F7
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	55, 17, 4            @ G#6
	N	59, 17, 2            @ C7
	N	64, 17, 2            @ F7
	N	52, 17, 4            @ F6
	N	59, 17, 2            @ C7
	N	64, 17, 2            @ F7
	N	55, 17, 2            @ G#6
	N	67, 17, 2            @ G#7
	N	64, 17, 2            @ F7
	N	59, 17, 2            @ C7
	N	52, 17, 2            @ F6
	N	59, 17, 2            @ C7
	N	55, 17, 2            @ G#6
	N	64, 17, 2            @ F7
	N	57, 17, 4            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 4            @ A#7
	N	64, 17, 5            @ F7
	N	57, 17, 2            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 2            @ A#7
	N	64, 17, 2            @ F7
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	54, 17, 4            @ G6
	N	57, 17, 2            @ A#6
	N	62, 17, 2            @ D#7
	N	66, 17, 4            @ G7
	N	62, 17, 4            @ D#7
	N	50, 17, 2            @ D#6
	N	57, 17, 2            @ A#6
	N	62, 17, 2            @ D#7
	N	66, 17, 2            @ G7
	N	54, 17, 2            @ G6
	N	62, 17, 2            @ D#7
	N	57, 17, 2            @ A#6
	N	62, 17, 2            @ D#7
	N	57, 17, 4            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 4            @ A#7
	N	64, 17, 4            @ F7
	N	57, 17, 4            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	52, 17, 4            @ F6
	N	59, 17, 4            @ C7
	N	57, 17, 4            @ A#6
	N	60, 17, 2            @ C#7
	N	64, 17, 2            @ F7
	N	69, 17, 4            @ A#7
	N	64, 17, 4            @ F7
	N	54, 17, 4            @ G6
	N	58, 17, 2            @ B6
	N	61, 17, 2            @ D7
	N	66, 17, 6            @ G7
	PAT_END
pat_0801FD63:				@ used by s9c2
	N	55, 17, 4            @ G#6
	N	52, 17, 2            @ F6
	N	60, 17, 4            @ C#7
	N	55, 17, 2            @ G#6
	N	64, 17, 6            @ F7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	64, 17, 4            @ F7
	N	64, 17, 5            @ F7
	N	62, 17, 2            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 2            @ C7
	N	60, 17, 4            @ C#7
	N	55, 17, 4            @ G#6
	N	53, 17, 4            @ F#6
	N	55, 17, 2            @ G#6
	N	53, 17, 4            @ F#6
	N	52, 17, 2            @ F6
	N	55, 17, 2            @ G#6
	N	60, 17, 4            @ C#7
	N	64, 17, 7            @ F7
	N	62, 17, 2            @ D#7
	N	60, 17, 2            @ C#7
	N	62, 17, 4            @ D#7
	N	60, 17, 2            @ C#7
	N	59, 17, 2            @ C7
	N	60, 17, 5            @ C#7
	N	55, 17, 5            @ G#6
	N	52, 17, 6            @ F6
	N	48, 17, 4            @ C#6
	N	50, 17, 4            @ D#6
	N	52, 17, 4            @ F6
	N	52, 17, 2            @ F6
	N	55, 17, 2            @ G#6
	N	60, 17, 2            @ C#7
	N	64, 17, 5            @ F7
	N	62, 17, 2            @ D#7
	N	60, 17, 2            @ C#7
	N	62, 17, 4            @ D#7
	N	60, 17, 2            @ C#7
	N	59, 17, 2            @ C7
	N	60, 17, 4            @ C#7
	N	59, 17, 2            @ C7
	N	57, 17, 2            @ A#6
	N	60, 17, 4            @ C#7
	N	55, 17, 4            @ G#6
	N	52, 17, 4            @ F6
	N	55, 17, 4            @ G#6
	N	48, 17, 8            @ C#6
	N	59, 17, 4            @ C7
	N	60, 17, 2            @ C#7
	N	62, 17, 2            @ D#7
	N	59, 17, 4            @ C7
	N	57, 17, 4            @ A#6
	N	55, 17, 4            @ G#6
	N	57, 17, 4            @ A#6
	N	59, 17, 4            @ C7
	N	55, 17, 4            @ G#6
	N	60, 17, 4            @ C#7
	N	55, 17, 2            @ G#6
	N	52, 17, 2            @ F6
	N	55, 17, 4            @ G#6
	N	50, 17, 4            @ D#6
	N	48, 17, 8            @ C#6
	PAT_END
pat_0801FE24:				@ used by s9c3
	N	36, 11, 5            @ C#5
	N	36, 11, 2            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	36, 11, 5            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 2            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 2            @ C#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	N	36, 11, 5            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 2            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	40, 11, 5            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 5            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	33, 11, 5            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 5            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	40, 11, 5            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 5            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 5            @ F5
	N	41, 11, 5            @ F#5
	N	41, 11, 2            @ F#5
	N	41, 11, 4            @ F#5
	N	36, 11, 2            @ C#5
	N	41, 11, 4            @ F#5
	N	41, 11, 2            @ F#5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	31, 11, 5            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 2            @ G#4
	N	31, 11, 5            @ G#4
	N	31, 11, 2            @ G#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	PAT_END
pat_0801FEDF:				@ used by s9c3
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	31, 11, 4            @ G#4
	N	39, 11, 2            @ E5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	31, 11, 4            @ G#4
	N	42, 11, 2            @ G5
	N	43, 11, 4            @ G#5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	31, 11, 4            @ G#4
	N	39, 11, 2            @ E5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	31, 11, 4            @ G#4
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	35, 11, 2            @ C5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	31, 11, 4            @ G#4
	N	39, 11, 2            @ E5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	31, 11, 4            @ G#4
	N	42, 11, 2            @ G5
	N	43, 11, 4            @ G#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	39, 11, 2            @ E5
	N	37, 11, 2            @ D5
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	39, 11, 2            @ E5
	N	37, 11, 2            @ D5
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	28, 11, 4            @ F4
	N	28, 11, 2            @ F4
	N	30, 11, 2            @ G4
	N	32, 11, 2            @ A4
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	39, 11, 2            @ E5
	N	37, 11, 2            @ D5
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	39, 11, 2            @ E5
	N	37, 11, 2            @ D5
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	37, 11, 2            @ D5
	N	39, 11, 2            @ E5
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	28, 11, 4            @ F4
	N	28, 11, 2            @ F4
	N	30, 11, 2            @ G4
	N	32, 11, 2            @ A4
	PAT_END
pat_08020039:				@ used by s9c3
	N	33, 11, 4            @ A#4
	N	40, 11, 2            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	40, 11, 2            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	32, 11, 4            @ A4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	40, 11, 2            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	40, 11, 2            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	33, 11, 4            @ A#4
	N	28, 11, 2            @ F4
	N	30, 11, 2            @ G4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	40, 11, 7            @ F5
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	40, 11, 2            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 2            @ D#5
	N	36, 11, 2            @ C#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	40, 11, 2            @ F5
	N	40, 11, 2            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	28, 11, 2            @ F4
	N	30, 11, 2            @ G4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	PAT_END
pat_08020109:				@ used by s9c3
	N	45, 11, 7            @ A#5
	N	43, 11, 2            @ G#5
	N	41, 11, 2            @ F#5
	N	43, 11, 7            @ G#5
	N	41, 11, 2            @ F#5
	N	40, 11, 2            @ F5
	N	41, 11, 7            @ F#5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	40, 11, 6            @ F5
	REST	0, 2
	N	40, 11, 2            @ F5
	N	42, 11, 2            @ G5
	N	44, 11, 2            @ A5
	N	45, 11, 7            @ A#5
	N	43, 11, 2            @ G#5
	N	41, 11, 2            @ F#5
	N	43, 11, 7            @ G#5
	N	41, 11, 2            @ F#5
	N	40, 11, 2            @ F5
	N	41, 11, 4            @ F#5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	40, 11, 4            @ F5
	N	35, 11, 2            @ C5
	N	32, 11, 2            @ A4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	36, 11, 2            @ C#5
	N	38, 11, 2            @ D#5
	N	40, 11, 4            @ F5
	N	45, 11, 7            @ A#5
	N	43, 11, 2            @ G#5
	N	41, 11, 2            @ F#5
	N	43, 11, 2            @ G#5
	N	45, 11, 2            @ A#5
	N	43, 11, 6            @ G#5
	N	41, 11, 2            @ F#5
	N	40, 11, 2            @ F5
	N	41, 11, 2            @ F#5
	N	43, 11, 2            @ G#5
	N	41, 11, 6            @ F#5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	40, 11, 7            @ F5
	N	35, 11, 4            @ C5
	N	45, 11, 7            @ A#5
	N	43, 11, 2            @ G#5
	N	41, 11, 2            @ F#5
	N	43, 11, 2            @ G#5
	N	45, 11, 2            @ A#5
	N	43, 11, 6            @ G#5
	N	41, 11, 2            @ F#5
	N	40, 11, 2            @ F5
	N	41, 11, 4            @ F#5
	N	40, 11, 2            @ F5
	N	38, 11, 2            @ D#5
	N	40, 11, 4            @ F5
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	PAT_END
pat_080201C4:				@ used by s9c3
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 5            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	35, 11, 2            @ C5
	N	35, 11, 2            @ C5
	N	35, 11, 4            @ C5
	N	35, 11, 4            @ C5
	N	28, 11, 4            @ F4
	N	28, 11, 2            @ F4
	N	28, 11, 2            @ F4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 5            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	31, 11, 2            @ G#4
	N	31, 11, 2            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	N	36, 11, 4            @ C#5
	N	36, 11, 2            @ C#5
	N	36, 11, 2            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	32, 11, 4            @ A4
	N	32, 11, 2            @ A4
	N	32, 11, 2            @ A4
	N	32, 11, 4            @ A4
	N	32, 11, 6            @ A4
	N	32, 11, 2            @ A4
	N	32, 11, 2            @ A4
	N	32, 11, 4            @ A4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	28, 11, 2            @ F4
	N	28, 11, 2            @ F4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	42, 11, 6            @ G5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	28, 11, 4            @ F4
	N	28, 11, 2            @ F4
	N	28, 11, 2            @ F4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	35, 11, 4            @ C5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	35, 11, 2            @ C5
	N	36, 11, 2            @ C#5
	N	38, 11, 4            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 2            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	33, 11, 4            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 2            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	30, 11, 4            @ G4
	N	30, 11, 2            @ G4
	N	30, 11, 2            @ G4
	N	30, 11, 4            @ G4
	N	30, 11, 4            @ G4
	PAT_END
pat_080203F0:				@ used by s9c3
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	35, 11, 4            @ C5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	31, 11, 2            @ G#4
	N	33, 11, 2            @ A#4
	N	35, 11, 4            @ C5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 4            @ C#5
	N	31, 11, 5            @ G#4
	N	31, 11, 5            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 5            @ G#4
	N	33, 11, 5            @ A#4
	N	35, 11, 4            @ C5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 5            @ C#5
	N	36, 11, 4            @ C#5
	PAT_END
pat_08020487:				@ used by s9c4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	PAT_END
pat_08020548:				@ used by s8c1
	N	60, 17, 9            @ C#7
	N	67, 17, 11           @ G#7
	N	62, 17, 7            @ D#7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	65, 17, 9            @ F#7
	N	58, 17, 11           @ B6
	N	58, 17, 6            @ B6
	N	60, 17, 6            @ C#7
	N	62, 17, 6            @ D#7
	N	60, 17, 9            @ C#7
	N	67, 17, 11           @ G#7
	N	62, 17, 7            @ D#7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	63, 17, 9            @ E7
	N	70, 17, 9            @ B7
	N	75, 17, 9            @ E8
	N	70, 17, 9            @ B7
	PAT_END
pat_08020588:				@ used by s8c1
	N	60, 17, 9            @ C#7
	N	67, 17, 11           @ G#7
	N	62, 17, 7            @ D#7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	65, 17, 9            @ F#7
	N	58, 17, 12           @ B6
	REST	0, 6
	N	56, 17, 7            @ A6
	N	60, 17, 4            @ C#7
	N	63, 17, 6            @ E7
	N	68, 17, 7            @ A7
	N	70, 17, 4            @ B7
	N	72, 17, 6            @ C#8
	N	74, 17, 7            @ D#8
	N	72, 17, 4            @ C#8
	N	71, 17, 6            @ C8
	N	67, 17, 7            @ G#7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	60, 17, 9            @ C#7
	N	58, 17, 8            @ B6
	N	55, 17, 6            @ G#6
	N	60, 17, 11           @ C#7
	PAT_END
pat_080205D7:				@ used by s8c1
	N	55, 17, 8            @ G#6
	N	60, 17, 4            @ C#7
	N	62, 17, 4            @ D#7
	N	63, 17, 8            @ E7
	N	65, 17, 6            @ F#7
	N	66, 17, 9            @ G7
	N	67, 17, 9            @ G#7
	N	68, 17, 6            @ A7
	N	71, 17, 6            @ C8
	N	68, 17, 6            @ A7
	N	63, 17, 6            @ E7
	N	68, 17, 6            @ A7
	N	63, 17, 6            @ E7
	N	59, 17, 6            @ C7
	N	63, 17, 6            @ E7
	N	59, 17, 6            @ C7
	N	56, 17, 9            @ A6
	N	55, 17, 8            @ G#6
	N	60, 17, 4            @ C#7
	N	62, 17, 4            @ D#7
	N	63, 17, 8            @ E7
	N	65, 17, 6            @ F#7
	N	66, 17, 9            @ G7
	N	67, 17, 9            @ G#7
	N	70, 17, 4            @ B7
	N	69, 17, 4            @ A#7
	N	68, 17, 4            @ A7
	N	67, 17, 4            @ G#7
	N	66, 17, 4            @ G7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	63, 17, 8            @ E7
	REST	0, 4
	N	70, 17, 4            @ B7
	N	69, 17, 4            @ A#7
	N	68, 17, 4            @ A7
	N	67, 17, 4            @ G#7
	N	66, 17, 4            @ G7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	63, 17, 8            @ E7
	REST	0, 4
	N	60, 17, 8            @ C#7
	N	55, 17, 4            @ G#6
	N	60, 17, 4            @ C#7
	N	63, 17, 8            @ E7
	N	60, 17, 4            @ C#7
	N	63, 17, 4            @ E7
	N	66, 17, 6            @ G7
	N	67, 17, 6            @ G#7
	N	68, 17, 6            @ A7
	N	67, 17, 10           @ G#7
	N	68, 17, 6            @ A7
	N	63, 17, 6            @ E7
	N	59, 17, 8            @ C7
	N	63, 17, 6            @ E7
	N	56, 17, 8            @ A6
	N	58, 17, 6            @ B6
	N	59, 17, 9            @ C7
	N	62, 17, 4            @ D#7
	N	57, 17, 4            @ A#6
	N	62, 17, 4            @ D#7
	N	57, 17, 4            @ A#6
	N	62, 17, 4            @ D#7
	N	66, 17, 4            @ G7
	N	69, 17, 9            @ A#7
	N	66, 17, 4            @ G7
	N	62, 17, 4            @ D#7
	N	66, 17, 4            @ G7
	N	62, 17, 4            @ D#7
	N	66, 17, 4            @ G7
	N	69, 17, 4            @ A#7
	N	74, 17, 8            @ D#8
	N	72, 17, 6            @ C#8
	N	71, 17, 9            @ C8
	N	69, 17, 8            @ A#7
	N	71, 17, 6            @ C8
	N	67, 17, 8            @ G#7
	N	65, 17, 6            @ F#7
	N	63, 17, 4            @ E7
	N	62, 17, 4            @ D#7
	N	60, 17, 6            @ C#7
	N	59, 17, 6            @ C7
	PAT_END
pat_080206D1:				@ used by s8c1
	N	55, 17, 8            @ G#6
	N	60, 17, 4            @ C#7
	N	62, 17, 4            @ D#7
	N	63, 17, 8            @ E7
	N	66, 17, 6            @ G7
	N	67, 17, 8            @ G#7
	N	72, 17, 4            @ C#8
	N	74, 17, 4            @ D#8
	N	75, 17, 6            @ E8
	N	74, 17, 6            @ D#8
	N	72, 17, 6            @ C#8
	N	73, 17, 6            @ D8
	N	70, 17, 6            @ B7
	N	73, 17, 6            @ D8
	N	65, 17, 6            @ F#7
	N	70, 17, 6            @ B7
	N	65, 17, 6            @ F#7
	N	61, 17, 6            @ D7
	N	65, 17, 6            @ F#7
	N	61, 17, 6            @ D7
	N	58, 17, 9            @ B6
	N	56, 17, 8            @ A6
	N	58, 17, 4            @ B6
	N	59, 17, 4            @ C7
	N	61, 17, 8            @ D7
	N	63, 17, 6            @ E7
	N	64, 17, 6            @ F7
	N	63, 17, 6            @ E7
	N	61, 17, 6            @ D7
	N	63, 17, 6            @ E7
	N	61, 17, 6            @ D7
	N	59, 17, 6            @ C7
	N	57, 17, 8            @ A#6
	N	54, 17, 4            @ G6
	N	57, 17, 4            @ A#6
	N	61, 17, 6            @ D7
	N	57, 17, 4            @ A#6
	N	61, 17, 4            @ D7
	N	66, 17, 4            @ G7
	N	61, 17, 4            @ D7
	N	69, 17, 4            @ A#7
	N	66, 17, 4            @ G7
	N	69, 17, 4            @ A#7
	N	66, 17, 4            @ G7
	N	69, 17, 4            @ A#7
	N	66, 17, 4            @ G7
	N	73, 17, 6            @ D8
	N	69, 17, 6            @ A#7
	N	66, 17, 6            @ G7
	N	74, 17, 7            @ D#8
	N	72, 17, 4            @ C#8
	N	71, 17, 4            @ C8
	N	72, 17, 4            @ C#8
	N	74, 17, 4            @ D#8
	N	72, 17, 4            @ C#8
	N	71, 17, 4            @ C8
	N	69, 17, 4            @ A#7
	N	67, 17, 4            @ G#7
	N	69, 17, 4            @ A#7
	N	67, 17, 4            @ G#7
	N	65, 17, 4            @ F#7
	N	63, 17, 4            @ E7
	N	62, 17, 4            @ D#7
	N	63, 17, 4            @ E7
	N	65, 17, 4            @ F#7
	N	63, 17, 4            @ E7
	N	62, 17, 4            @ D#7
	N	60, 17, 6            @ C#7
	N	59, 17, 6            @ C7
	N	60, 17, 6            @ C#7
	N	55, 17, 4            @ G#6
	N	60, 17, 4            @ C#7
	N	63, 17, 4            @ E7
	N	60, 17, 4            @ C#7
	N	67, 17, 6            @ G#7
	N	63, 17, 4            @ E7
	N	68, 17, 4            @ A7
	N	67, 17, 6            @ G#7
	N	72, 17, 4            @ C#8
	N	74, 17, 4            @ D#8
	N	75, 17, 7            @ E8
	N	74, 17, 4            @ D#8
	N	72, 17, 6            @ C#8
	N	74, 17, 6            @ D#8
	N	75, 17, 6            @ E8
	N	73, 17, 8            @ D8
	N	70, 17, 4            @ B7
	N	73, 17, 4            @ D8
	N	65, 17, 8            @ F#7
	N	70, 17, 4            @ B7
	N	65, 17, 4            @ F#7
	N	61, 17, 8            @ D7
	N	65, 17, 4            @ F#7
	N	61, 17, 4            @ D7
	N	58, 17, 9            @ B6
	N	67, 17, 8            @ G#7
	REST	0, 4
	N	69, 17, 4            @ A#7
	N	71, 17, 8            @ C8
	REST	0, 4
	N	72, 17, 4            @ C#8
	N	74, 17, 11           @ D#8
	PAT_END
pat_08020804:				@ used by s8c2
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	PAT_END
pat_0802084D:				@ used by s8c2
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	68, 26, 6            @ A7
	N	67, 26, 6            @ G#7
	N	63, 26, 6            @ E7
	N	68, 26, 6            @ A7
	N	67, 26, 6            @ G#7
	N	63, 26, 6            @ E7
	N	68, 26, 6            @ A7
	N	67, 26, 6            @ G#7
	N	63, 26, 6            @ E7
	N	68, 26, 6            @ A7
	N	67, 26, 6            @ G#7
	N	63, 26, 6            @ E7
	PAT_END
pat_080208DE:				@ used by s8c2
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	64, 26, 6            @ F7
	N	62, 26, 6            @ D#7
	N	58, 26, 6            @ B6
	N	60, 26, 6            @ C#7
	N	58, 26, 6            @ B6
	N	56, 26, 6            @ A6
	N	60, 26, 6            @ C#7
	N	58, 26, 6            @ B6
	N	56, 26, 6            @ A6
	N	55, 26, 6            @ G#6
	N	59, 26, 6            @ C7
	N	62, 26, 6            @ D#7
	N	55, 26, 6            @ G#6
	N	59, 26, 6            @ C7
	N	62, 26, 6            @ D#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	64, 26, 6            @ F7
	N	60, 26, 6            @ C#7
	PAT_END
pat_0802096F:				@ used by s8c2
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	55, 26, 6            @ G#6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	55, 26, 6            @ G#6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	59, 26, 6            @ C7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	56, 26, 6            @ A6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	59, 26, 6            @ C7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	56, 26, 6            @ A6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	55, 26, 6            @ G#6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	55, 26, 6            @ G#6
	N	66, 26, 6            @ G7
	N	63, 26, 6            @ E7
	N	58, 26, 6            @ B6
	N	66, 26, 6            @ G7
	N	63, 26, 6            @ E7
	N	54, 26, 6            @ G6
	N	66, 26, 6            @ G7
	N	63, 26, 6            @ E7
	N	58, 26, 6            @ B6
	N	66, 26, 6            @ G7
	N	63, 26, 6            @ E7
	N	54, 26, 6            @ G6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	55, 26, 6            @ G#6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	60, 26, 6            @ C#7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	55, 26, 6            @ G#6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	59, 26, 6            @ C7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	56, 26, 6            @ A6
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	59, 26, 6            @ C7
	N	65, 26, 6            @ F#7
	N	63, 26, 6            @ E7
	N	56, 26, 6            @ A6
	N	66, 26, 6            @ G7
	N	62, 26, 6            @ D#7
	N	60, 26, 6            @ C#7
	N	66, 26, 6            @ G7
	N	62, 26, 6            @ D#7
	N	57, 26, 6            @ A#6
	N	66, 26, 6            @ G7
	N	62, 26, 6            @ D#7
	N	60, 26, 6            @ C#7
	N	66, 26, 6            @ G7
	N	62, 26, 6            @ D#7
	N	57, 26, 6            @ A#6
	N	67, 26, 6            @ G#7
	N	62, 26, 6            @ D#7
	N	60, 26, 6            @ C#7
	N	67, 26, 6            @ G#7
	N	62, 26, 6            @ D#7
	N	59, 26, 6            @ C7
	N	67, 26, 6            @ G#7
	N	62, 26, 6            @ D#7
	N	57, 26, 6            @ A#6
	N	67, 26, 6            @ G#7
	N	62, 26, 6            @ D#7
	N	55, 26, 6            @ G#6
	PAT_END
pat_08020A90:				@ used by s8c2
	N	60, 26, 4            @ C#7
	N	63, 26, 4            @ E7
	N	67, 26, 4            @ G#7
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	67, 26, 4            @ G#7
	N	63, 26, 4            @ E7
	N	60, 26, 4            @ C#7
	N	55, 26, 4            @ G#6
	N	60, 26, 4            @ C#7
	N	63, 26, 4            @ E7
	N	67, 26, 4            @ G#7
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	67, 26, 4            @ G#7
	N	63, 26, 4            @ E7
	N	60, 26, 4            @ C#7
	N	63, 26, 4            @ E7
	N	61, 26, 4            @ D7
	N	58, 26, 4            @ B6
	N	53, 26, 4            @ F#6
	N	58, 26, 4            @ B6
	N	61, 26, 4            @ D7
	N	65, 26, 4            @ F#7
	N	70, 26, 4            @ B7
	N	65, 26, 4            @ F#7
	N	70, 26, 4            @ B7
	N	73, 26, 4            @ D8
	N	70, 26, 4            @ B7
	N	65, 26, 4            @ F#7
	N	61, 26, 4            @ D7
	N	58, 26, 4            @ B6
	N	53, 26, 4            @ F#6
	N	58, 26, 4            @ B6
	N	61, 26, 4            @ D7
	N	65, 26, 4            @ F#7
	N	70, 26, 4            @ B7
	N	73, 26, 4            @ D8
	N	70, 26, 4            @ B7
	N	65, 26, 4            @ F#7
	N	61, 26, 4            @ D7
	N	58, 26, 4            @ B6
	N	56, 26, 4            @ A6
	N	59, 26, 4            @ C7
	N	63, 26, 4            @ E7
	N	68, 26, 4            @ A7
	N	71, 26, 4            @ C8
	N	68, 26, 4            @ A7
	N	75, 26, 4            @ E8
	N	71, 26, 4            @ C8
	N	68, 26, 4            @ A7
	N	63, 26, 4            @ E7
	N	59, 26, 4            @ C7
	N	56, 26, 4            @ A6
	N	56, 26, 4            @ A6
	N	59, 26, 4            @ C7
	N	63, 26, 4            @ E7
	N	68, 26, 4            @ A7
	N	71, 26, 4            @ C8
	N	75, 26, 4            @ E8
	N	71, 26, 4            @ C8
	N	68, 26, 4            @ A7
	N	63, 26, 4            @ E7
	N	68, 26, 4            @ A7
	N	59, 26, 4            @ C7
	N	63, 26, 4            @ E7
	N	54, 26, 4            @ G6
	N	57, 26, 4            @ A#6
	N	61, 26, 4            @ D7
	N	66, 26, 4            @ G7
	N	69, 26, 4            @ A#7
	N	66, 26, 4            @ G7
	N	73, 26, 4            @ D8
	N	69, 26, 4            @ A#7
	N	66, 26, 4            @ G7
	N	61, 26, 4            @ D7
	N	57, 26, 4            @ A#6
	N	61, 26, 4            @ D7
	N	54, 26, 4            @ G6
	N	57, 26, 4            @ A#6
	N	61, 26, 4            @ D7
	N	66, 26, 4            @ G7
	N	69, 26, 4            @ A#7
	N	73, 26, 4            @ D8
	N	69, 26, 4            @ A#7
	N	66, 26, 4            @ G7
	N	61, 26, 4            @ D7
	N	57, 26, 4            @ A#6
	N	54, 26, 4            @ G6
	N	57, 26, 4            @ A#6
	N	55, 26, 4            @ G#6
	N	59, 26, 4            @ C7
	N	62, 26, 4            @ D#7
	N	67, 26, 4            @ G#7
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	74, 26, 4            @ D#8
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	62, 26, 4            @ D#7
	N	67, 26, 4            @ G#7
	N	71, 26, 4            @ C8
	N	55, 26, 4            @ G#6
	N	59, 26, 4            @ C7
	N	62, 26, 4            @ D#7
	N	67, 26, 4            @ G#7
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	74, 26, 4            @ D#8
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	62, 26, 4            @ D#7
	N	59, 26, 4            @ C7
	N	55, 26, 4            @ G#6
	N	60, 26, 4            @ C#7
	N	63, 26, 4            @ E7
	N	67, 26, 4            @ G#7
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	67, 26, 4            @ G#7
	N	63, 26, 4            @ E7
	N	60, 26, 4            @ C#7
	N	55, 26, 4            @ G#6
	N	60, 26, 4            @ C#7
	N	63, 26, 4            @ E7
	N	67, 26, 4            @ G#7
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	75, 26, 4            @ E8
	N	72, 26, 4            @ C#8
	N	67, 26, 4            @ G#7
	N	63, 26, 4            @ E7
	N	60, 26, 4            @ C#7
	N	55, 26, 4            @ G#6
	N	58, 26, 4            @ B6
	N	61, 26, 4            @ D7
	N	65, 26, 4            @ F#7
	N	70, 26, 4            @ B7
	N	73, 26, 4            @ D8
	N	70, 26, 4            @ B7
	N	73, 26, 4            @ D8
	N	70, 26, 4            @ B7
	N	65, 26, 4            @ F#7
	N	61, 26, 4            @ D7
	N	58, 26, 4            @ B6
	N	53, 26, 4            @ F#6
	N	58, 26, 4            @ B6
	N	61, 26, 4            @ D7
	N	65, 26, 4            @ F#7
	N	70, 26, 4            @ B7
	N	73, 26, 4            @ D8
	N	70, 26, 4            @ B7
	N	73, 26, 4            @ D8
	N	70, 26, 4            @ B7
	N	65, 26, 4            @ F#7
	N	61, 26, 4            @ D7
	N	58, 26, 4            @ B6
	N	53, 26, 4            @ F#6
	N	55, 26, 4            @ G#6
	N	59, 26, 4            @ C7
	N	62, 26, 4            @ D#7
	N	67, 26, 4            @ G#7
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	74, 26, 4            @ D#8
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	62, 26, 4            @ D#7
	N	59, 26, 4            @ C7
	N	62, 26, 4            @ D#7
	N	55, 26, 4            @ G#6
	N	59, 26, 4            @ C7
	N	62, 26, 4            @ D#7
	N	67, 26, 4            @ G#7
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	74, 26, 4            @ D#8
	N	71, 26, 4            @ C8
	N	67, 26, 4            @ G#7
	N	62, 26, 4            @ D#7
	N	67, 26, 4            @ G#7
	N	62, 26, 4            @ D#7
	PAT_END
pat_08020CD1:				@ used by s8c3
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	34, 11, 6            @ B4
	N	29, 11, 6            @ F#4
	REST	0, 6
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	41, 11, 6            @ F#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	34, 11, 6            @ B4
	N	29, 11, 6            @ F#4
	REST	0, 6
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	41, 11, 6            @ F#5
	PAT_END
pat_08020D32:				@ used by s8c3
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	34, 11, 6            @ B4
	N	29, 11, 6            @ F#4
	REST	0, 6
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	41, 11, 6            @ F#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	34, 11, 6            @ B4
	N	29, 11, 6            @ F#4
	REST	0, 6
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	41, 11, 6            @ F#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	39, 11, 4            @ E5
	N	38, 11, 4            @ D#5
	N	39, 11, 6            @ E5
	N	34, 11, 6            @ B4
	REST	0, 6
	N	39, 11, 4            @ E5
	N	43, 11, 4            @ G#5
	N	46, 11, 6            @ B5
	N	39, 11, 4            @ E5
	N	38, 11, 4            @ D#5
	N	39, 11, 6            @ E5
	N	34, 11, 6            @ B4
	REST	0, 6
	N	39, 11, 4            @ E5
	N	43, 11, 4            @ G#5
	N	46, 11, 6            @ B5
	PAT_END
pat_08020DF3:				@ used by s8c3
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	34, 11, 6            @ B4
	N	29, 11, 6            @ F#4
	REST	0, 6
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	41, 11, 6            @ F#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	34, 11, 6            @ B4
	N	29, 11, 6            @ F#4
	REST	0, 6
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	41, 11, 6            @ F#5
	N	32, 11, 4            @ A4
	N	31, 11, 4            @ G#4
	N	32, 11, 6            @ A4
	N	27, 11, 6            @ E4
	REST	0, 6
	N	32, 11, 4            @ A4
	N	36, 11, 4            @ C#5
	N	39, 11, 6            @ E5
	N	31, 11, 4            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 6            @ G#4
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	35, 11, 6            @ C5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	PAT_END
pat_08020EC0:				@ used by s8c3
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	32, 11, 4            @ A4
	N	31, 11, 4            @ G#4
	N	32, 11, 6            @ A4
	N	27, 11, 6            @ E4
	REST	0, 6
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	39, 11, 6            @ E5
	N	32, 11, 4            @ A4
	N	31, 11, 4            @ G#4
	N	32, 11, 6            @ A4
	N	27, 11, 6            @ E4
	REST	0, 6
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	39, 11, 6            @ E5
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	39, 11, 4            @ E5
	N	38, 11, 4            @ D#5
	N	39, 11, 6            @ E5
	N	34, 11, 6            @ B4
	REST	0, 6
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	46, 11, 6            @ B5
	N	39, 11, 4            @ E5
	N	38, 11, 4            @ D#5
	N	39, 11, 6            @ E5
	N	34, 11, 6            @ B4
	REST	0, 6
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	46, 11, 6            @ B5
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	REST	0, 6
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	32, 11, 4            @ A4
	N	31, 11, 4            @ G#4
	N	32, 11, 6            @ A4
	N	27, 11, 6            @ E4
	REST	0, 6
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	39, 11, 6            @ E5
	N	32, 11, 4            @ A4
	N	31, 11, 4            @ G#4
	N	32, 11, 6            @ A4
	N	27, 11, 6            @ E4
	REST	0, 6
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	39, 11, 6            @ E5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	33, 11, 6            @ A#4
	REST	0, 6
	N	38, 11, 4            @ D#5
	N	42, 11, 4            @ G5
	N	45, 11, 6            @ A#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	33, 11, 6            @ A#4
	REST	0, 6
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	43, 11, 6            @ G#5
	N	38, 11, 6            @ D#5
	N	35, 11, 6            @ C5
	N	31, 11, 6            @ G#4
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	35, 11, 6            @ C5
	N	31, 11, 6            @ G#4
	PAT_END
pat_0802103B:				@ used by s8c3
	N	36, 11, 7            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	39, 11, 6            @ E5
	N	43, 11, 6            @ G#5
	N	36, 11, 7            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	39, 11, 6            @ E5
	N	43, 11, 6            @ G#5
	N	34, 11, 7            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 4            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 6            @ B4
	N	37, 11, 6            @ D5
	N	41, 11, 6            @ F#5
	N	34, 11, 7            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 4            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 6            @ B4
	N	37, 11, 6            @ D5
	N	41, 11, 6            @ F#5
	N	32, 11, 7            @ A4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	N	30, 11, 4            @ G4
	N	32, 11, 6            @ A4
	N	35, 11, 6            @ C5
	N	39, 11, 6            @ E5
	N	32, 11, 7            @ A4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	N	30, 11, 4            @ G4
	N	32, 11, 6            @ A4
	N	35, 11, 6            @ C5
	N	39, 11, 6            @ E5
	N	30, 11, 7            @ G4
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	28, 11, 4            @ F4
	N	30, 11, 6            @ G4
	N	33, 11, 6            @ A#4
	N	37, 11, 6            @ D5
	N	30, 11, 7            @ G4
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	28, 11, 4            @ F4
	N	30, 11, 6            @ G4
	N	33, 11, 6            @ A#4
	N	37, 11, 6            @ D5
	N	31, 11, 7            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 4            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 6            @ G#4
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	N	31, 11, 7            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 4            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 6            @ G#4
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	N	36, 11, 7            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	39, 11, 6            @ E5
	N	43, 11, 6            @ G#5
	N	36, 11, 7            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 4            @ C#5
	N	34, 11, 4            @ B4
	N	36, 11, 6            @ C#5
	N	39, 11, 6            @ E5
	N	43, 11, 6            @ G#5
	N	34, 11, 7            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 4            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 6            @ B4
	N	37, 11, 6            @ D5
	N	41, 11, 6            @ F#5
	N	34, 11, 7            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 4            @ B4
	N	32, 11, 4            @ A4
	N	34, 11, 6            @ B4
	N	37, 11, 6            @ D5
	N	41, 11, 6            @ F#5
	N	31, 11, 7            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 4            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 6            @ G#4
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	N	31, 11, 7            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 4            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 6            @ G#4
	N	35, 11, 6            @ C5
	N	38, 11, 6            @ D#5
	PAT_END
pat_0802118C:				@ used by s8c4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 2             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	32, 5, 4             @ A4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	PAT_END
pat_08021235:				@ used by s8c4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	32, 5, 4             @ A4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	32, 5, 4             @ A4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	32, 5, 4             @ A4
	N	26, 2, 2             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	PAT_END
pat_080212DE:				@ used by s8c4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	32, 5, 4             @ A4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	32, 5, 4             @ A4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	PAT_END
pat_08021384:				@ used by s8c4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	26, 2, 4             @ D#4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 4, 4             @ B4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	32, 5, 4             @ A4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	26, 2, 4             @ D#4
	N	34, 4, 2             @ B4
	N	26, 2, 4             @ D#4
	N	26, 2, 2             @ D#4
	N	26, 2, 4             @ D#4
	PAT_END
pat_08021430:				@ used by s7c1
	N	45, 17, 12           @ A#5
	N	47, 17, 12           @ C6
	N	48, 17, 12           @ C#6
	N	47, 17, 11           @ C6
	N	52, 17, 8            @ F6
	PAT_END
pat_08021440:				@ used by s7c1
	N	57, 17, 8            @ A#6
	N	64, 17, 10           @ F7
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 8            @ A#6
	N	52, 17, 11           @ F6
	N	57, 17, 7            @ A#6
	N	64, 17, 4            @ F7
	N	69, 17, 9            @ A#7
	N	71, 17, 6            @ C8
	N	72, 17, 6            @ C#8
	N	67, 17, 6            @ G#7
	N	64, 17, 12           @ F7
	N	69, 17, 8            @ A#7
	N	64, 17, 10           @ F7
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	60, 17, 8            @ C#7
	N	57, 17, 10           @ A#6
	REST	0, 6
	N	57, 17, 4            @ A#6
	N	59, 17, 4            @ C7
	N	60, 17, 8            @ C#7
	N	64, 17, 10           @ F7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	60, 17, 4            @ C#7
	N	57, 17, 12           @ A#6
	PAT_END
pat_080214A4:				@ used by s7c1
	N	68, 17, 10           @ A7
	N	67, 17, 8            @ G#7
	N	68, 17, 8            @ A7
	N	65, 17, 4            @ F#7
	N	67, 17, 4            @ G#7
	N	68, 17, 4            @ A7
	N	70, 17, 4            @ B7
	N	72, 17, 6            @ C#8
	N	73, 17, 4            @ D8
	N	72, 17, 8            @ C#8
	REST	0, 4
	N	75, 17, 6            @ E8
	N	73, 17, 6            @ D8
	N	72, 17, 4            @ C#8
	N	73, 17, 4            @ D8
	N	72, 17, 4            @ C#8
	N	70, 17, 4            @ B7
	N	68, 17, 6            @ A7
	N	67, 17, 4            @ G#7
	N	68, 17, 6            @ A7
	N	67, 17, 4            @ G#7
	N	65, 17, 6            @ F#7
	N	64, 17, 6            @ F7
	N	65, 17, 4            @ F#7
	N	67, 17, 4            @ G#7
	N	65, 17, 11           @ F#7
	REST	0, 6
	N	67, 17, 4            @ G#7
	N	68, 17, 4            @ A7
	N	69, 17, 8            @ A#7
	N	64, 17, 10           @ F7
	N	71, 17, 4            @ C8
	N	74, 17, 4            @ D#8
	N	72, 17, 4            @ C#8
	N	71, 17, 4            @ C8
	N	69, 17, 8            @ A#7
	N	64, 17, 10           @ F7
	N	62, 17, 4            @ D#7
	N	65, 17, 4            @ F#7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	64, 17, 8            @ F7
	N	57, 17, 10           @ A#6
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 8            @ A#6
	N	64, 17, 8            @ F7
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 8            @ A#6
	PAT_END
pat_08021547:				@ used by s7c1
	N	62, 17, 8            @ D#7
	N	69, 17, 10           @ A#7
	N	67, 17, 4            @ G#7
	N	71, 17, 4            @ C8
	N	69, 17, 4            @ A#7
	N	67, 17, 4            @ G#7
	N	66, 17, 8            @ G7
	N	62, 17, 10           @ D#7
	REST	0, 6
	N	64, 17, 4            @ F7
	N	66, 17, 4            @ G7
	N	64, 17, 8            @ F7
	N	60, 17, 10           @ C#7
	N	59, 17, 4            @ C7
	N	62, 17, 4            @ D#7
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	60, 17, 8            @ C#7
	N	55, 17, 11           @ G#6
	N	67, 17, 8            @ G#7
	N	71, 17, 10           @ C8
	N	64, 17, 4            @ F7
	N	67, 17, 4            @ G#7
	N	66, 17, 4            @ G7
	N	64, 17, 4            @ F7
	N	62, 17, 8            @ D#7
	N	59, 17, 8            @ C7
	N	55, 17, 9            @ G#6
	N	57, 17, 4            @ A#6
	N	59, 17, 4            @ C7
	N	57, 17, 4            @ A#6
	N	52, 17, 4            @ F6
	N	57, 17, 4            @ A#6
	N	61, 17, 6            @ D7
	N	57, 17, 4            @ A#6
	N	61, 17, 4            @ D7
	N	64, 17, 6            @ F7
	N	61, 17, 4            @ D7
	N	64, 17, 4            @ F7
	N	69, 17, 7            @ A#7
	N	68, 17, 6            @ A7
	N	69, 17, 6            @ A#7
	N	64, 17, 6            @ F7
	N	62, 17, 4            @ D#7
	N	66, 17, 4            @ G7
	N	64, 17, 4            @ F7
	N	62, 17, 4            @ D#7
	N	61, 17, 8            @ D7
	N	57, 17, 8            @ A#6
	N	62, 17, 8            @ D#7
	N	69, 17, 10           @ A#7
	N	71, 17, 4            @ C8
	N	69, 17, 4            @ A#7
	N	67, 17, 4            @ G#7
	N	71, 17, 4            @ C8
	N	69, 17, 8            @ A#7
	N	66, 17, 8            @ G7
	N	62, 17, 9            @ D#7
	N	64, 17, 4            @ F7
	N	66, 17, 4            @ G7
	N	64, 17, 6            @ F7
	N	60, 17, 6            @ C#7
	N	72, 17, 10           @ C#8
	N	71, 17, 4            @ C8
	N	74, 17, 4            @ D#8
	N	72, 17, 4            @ C#8
	N	71, 17, 4            @ C8
	N	72, 17, 8            @ C#8
	N	67, 17, 8            @ G#7
	N	64, 17, 8            @ F7
	N	60, 17, 8            @ C#7
	N	59, 17, 8            @ C7
	N	62, 17, 10           @ D#7
	N	57, 17, 4            @ A#6
	N	60, 17, 4            @ C#7
	N	59, 17, 4            @ C7
	N	57, 17, 4            @ A#6
	N	59, 17, 8            @ C7
	N	62, 17, 8            @ D#7
	N	67, 17, 9            @ G#7
	N	69, 17, 4            @ A#7
	N	71, 17, 4            @ C8
	N	71, 17, 8            @ C8
	N	68, 17, 8            @ A7
	N	64, 17, 8            @ F7
	N	74, 17, 6            @ D#8
	N	72, 17, 6            @ C#8
	N	71, 17, 6            @ C8
	N	68, 17, 6            @ A7
	N	64, 17, 6            @ F7
	N	62, 17, 6            @ D#7
	N	60, 17, 6            @ C#7
	N	59, 17, 6            @ C7
	N	57, 17, 6            @ A#6
	N	56, 17, 6            @ A6
	PAT_END
pat_08021665:				@ used by s7c1
	N	60, 17, 8            @ C#7
	N	67, 17, 10           @ G#7
	N	62, 17, 4            @ D#7
	N	65, 17, 4            @ F#7
	N	63, 17, 4            @ E7
	N	60, 17, 4            @ C#7
	N	62, 17, 8            @ D#7
	N	69, 17, 10           @ A#7
	N	64, 17, 4            @ F7
	N	67, 17, 4            @ G#7
	N	66, 17, 4            @ G7
	N	62, 17, 4            @ D#7
	N	64, 17, 8            @ F7
	N	68, 17, 8            @ A7
	N	71, 17, 9            @ C8
	N	72, 17, 6            @ C#8
	N	74, 17, 6            @ D#8
	N	72, 17, 6            @ C#8
	N	71, 17, 6            @ C8
	N	69, 17, 6            @ A#7
	N	68, 17, 6            @ A7
	N	64, 17, 6            @ F7
	N	59, 17, 6            @ C7
	N	56, 17, 6            @ A6
	PAT_END
pat_080216AE:				@ used by s7c2
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	47, 25, 4            @ C6
	N	45, 25, 4            @ A#5
	N	48, 25, 4            @ C#6
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	43, 25, 4            @ G#5
	N	44, 25, 4            @ A5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	43, 25, 4            @ G#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	48, 25, 4            @ C#6
	N	45, 25, 4            @ A#5
	N	47, 25, 4            @ C6
	N	48, 25, 4            @ C#6
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	43, 25, 4            @ G#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	45, 25, 4            @ A#5
	N	43, 25, 4            @ G#5
	N	44, 25, 4            @ A5
	PAT_END
pat_0802176F:				@ used by s7c2
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	49, 25, 4            @ D6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	54, 25, 4            @ G6
	N	54, 25, 4            @ G6
	N	55, 25, 4            @ G#6
	N	57, 25, 4            @ A#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	49, 25, 4            @ D6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	49, 25, 4            @ D6
	N	45, 25, 4            @ A#5
	PAT_END
pat_080217D0:				@ used by s7c2
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	47, 25, 4            @ C6
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	47, 25, 4            @ C6
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	48, 25, 4            @ C#6
	N	51, 25, 4            @ E6
	N	51, 25, 4            @ E6
	N	55, 25, 4            @ G#6
	N	51, 25, 4            @ E6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	48, 25, 4            @ C#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	48, 25, 4            @ C#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	50, 25, 4            @ D#6
	N	54, 25, 4            @ G6
	N	54, 25, 4            @ G6
	N	54, 25, 4            @ G6
	N	57, 25, 4            @ A#6
	N	54, 25, 4            @ G6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	50, 25, 4            @ D#6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	50, 25, 4            @ D#6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	56, 25, 4            @ A6
	N	56, 25, 4            @ A6
	N	56, 25, 4            @ A6
	N	59, 25, 4            @ C7
	N	56, 25, 4            @ A6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	50, 25, 4            @ D#6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	50, 25, 4            @ D#6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	52, 25, 4            @ F6
	N	50, 25, 4            @ D#6
	N	48, 25, 4            @ C#6
	N	47, 25, 4            @ C6
	PAT_END
pat_08021891:				@ used by s7c3
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	36, 11, 6            @ C#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	28, 11, 6            @ F4
	N	31, 11, 4            @ G#4
	N	32, 11, 4            @ A4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	36, 11, 6            @ C#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	31, 11, 4            @ G#4
	N	31, 11, 4            @ G#4
	PAT_END
pat_08021910:				@ used by s7c3
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 6            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	28, 11, 4            @ F4
	N	28, 11, 4            @ F4
	N	31, 11, 4            @ G#4
	N	32, 11, 4            @ A4
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 6            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	28, 11, 4            @ F4
	N	31, 11, 4            @ G#4
	PAT_END
pat_080219A4:				@ used by s7c3
	N	38, 11, 6            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	42, 11, 4            @ G5
	N	45, 11, 4            @ A#5
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	33, 11, 7            @ A#4
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	42, 11, 6            @ G5
	N	38, 11, 4            @ D#5
	N	42, 11, 4            @ G5
	N	36, 11, 7            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	N	36, 11, 6            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	40, 11, 6            @ F5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	31, 11, 7            @ G#4
	N	29, 11, 4            @ F#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 6            @ G#4
	N	43, 11, 6            @ G#5
	N	38, 11, 4            @ D#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	35, 11, 4            @ C5
	N	38, 11, 7            @ D#5
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	35, 11, 4            @ C5
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	32, 11, 4            @ A4
	N	33, 11, 7            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 4            @ A#4
	N	37, 11, 4            @ D5
	N	40, 11, 6            @ F5
	N	33, 11, 6            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	31, 11, 4            @ G#4
	N	33, 11, 7            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 4            @ A#4
	N	40, 11, 7            @ F5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	33, 11, 6            @ A#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	37, 11, 4            @ D5
	N	38, 11, 6            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 7            @ D#5
	N	33, 11, 6            @ A#4
	N	33, 11, 4            @ A#4
	N	38, 11, 6            @ D#5
	N	42, 11, 4            @ G5
	N	45, 11, 4            @ A#5
	N	38, 11, 6            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	33, 11, 6            @ A#4
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	36, 11, 7            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 6            @ G#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	31, 11, 6            @ G#4
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	31, 11, 7            @ G#4
	N	43, 11, 6            @ G#5
	N	43, 11, 4            @ G#5
	N	38, 11, 7            @ D#5
	N	35, 11, 6            @ C5
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 6            @ C5
	N	31, 11, 7            @ G#4
	N	31, 11, 6            @ G#4
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	35, 11, 6            @ C5
	N	31, 11, 6            @ G#4
	N	31, 11, 6            @ G#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	40, 11, 7            @ F5
	N	40, 11, 6            @ F5
	N	35, 11, 4            @ C5
	N	32, 11, 4            @ A4
	N	28, 11, 6            @ F4
	N	28, 11, 6            @ F4
	N	28, 11, 6            @ F4
	N	28, 11, 4            @ F4
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	40, 11, 7            @ F5
	N	38, 11, 2            @ D#5
	N	36, 11, 2            @ C#5
	N	38, 11, 7            @ D#5
	N	35, 11, 6            @ C5
	N	32, 11, 6            @ A4
	N	28, 11, 6            @ F4
	N	28, 11, 4            @ F4
	N	30, 11, 4            @ G4
	N	32, 11, 4            @ A4
	PAT_END
pat_08021B7F:				@ used by s7c3
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	35, 11, 4            @ C5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	43, 11, 6            @ G#5
	N	39, 11, 4            @ E5
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	33, 11, 6            @ A#4
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	33, 11, 6            @ A#4
	N	38, 11, 6            @ D#5
	N	33, 11, 4            @ A#4
	N	40, 11, 7            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	35, 11, 6            @ C5
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 6            @ F5
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 6            @ C#5
	N	35, 11, 6            @ C5
	PAT_END
pat_08021C0A:				@ used by s7c4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 2             @ C#4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	26, 2, 4             @ D#4
	N	26, 2, 4             @ D#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	32, 5, 4             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 2             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	32, 5, 4             @ A4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	32, 5, 4             @ A4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	34, 4, 2             @ B4
	N	30, 3, 2             @ G4
	N	34, 4, 4             @ B4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	26, 2, 4             @ D#4
	N	26, 2, 4             @ D#4
	PAT_END
pat_08021CE0:				@ used by s6c1
	N	46, 17, 14           @ B5
	N	46, 17, 15           @ B5
	N	46, 17, 15           @ B5
	N	46, 17, 14           @ B5
	N	46, 17, 14           @ B5
	N	46, 17, 15           @ B5
	N	46, 17, 15           @ B5
	N	46, 17, 14           @ B5
	N	45, 17, 14           @ A#5
	N	45, 17, 13           @ A#5
	N	45, 17, 6            @ A#5
	N	45, 17, 6            @ A#5
	N	45, 17, 16           @ A#5
	N	45, 17, 14           @ A#5
	N	45, 17, 14           @ A#5
	N	45, 17, 15           @ A#5
	N	45, 17, 14           @ A#5
	PAT_END
pat_08021D14:				@ used by s6c1
	N	70, 17, 8            @ B7
	N	69, 17, 10           @ A#7
	N	68, 17, 6            @ A7
	N	66, 17, 6            @ G7
	N	69, 17, 12           @ A#7
	N	70, 17, 8            @ B7
	N	69, 17, 10           @ A#7
	N	68, 17, 6            @ A7
	N	67, 17, 6            @ G#7
	N	66, 17, 12           @ G7
	PAT_END
pat_08021D33:				@ used by s6c1
	N	70, 17, 8            @ B7
	N	69, 17, 10           @ A#7
	N	70, 17, 6            @ B7
	N	71, 17, 4            @ C8
	N	72, 17, 4            @ C#8
	N	73, 17, 12           @ D8
	N	70, 17, 8            @ B7
	N	69, 17, 19           @ A#7
	N	70, 17, 4            @ B7
	N	69, 17, 7            @ A#7
	N	68, 17, 4            @ A7
	N	67, 17, 12           @ G#7
	PAT_END
pat_08021D58:				@ used by s6c1
	N	55, 17, 14           @ G#6
	N	57, 17, 14           @ A#6
	N	58, 17, 14           @ B6
	N	63, 17, 10           @ E7
	N	62, 17, 8            @ D#7
	N	57, 17, 17           @ A#6
	N	58, 17, 14           @ B6
	N	60, 17, 14           @ C#7
	N	54, 17, 14           @ G6
	N	55, 17, 14           @ G#6
	N	57, 17, 14           @ A#6
	N	50, 17, 8            @ D#6
	N	53, 17, 14           @ F#6
	N	55, 17, 14           @ G#6
	N	56, 17, 14           @ A6
	N	61, 17, 10           @ D7
	N	60, 17, 15           @ C#7
	N	56, 17, 14           @ A6
	N	55, 17, 10           @ G#6
	N	52, 17, 10           @ F6
	PAT_END
pat_08021D95:				@ used by s6c1
	N	50, 17, 14           @ D#6
	N	52, 17, 14           @ F6
	N	53, 17, 14           @ F#6
	N	57, 17, 17           @ A#6
	N	62, 17, 14           @ D#7
	N	64, 17, 14           @ F7
	N	65, 17, 15           @ F#7
	N	62, 17, 14           @ D#7
	N	60, 17, 8            @ C#7
	N	56, 17, 15           @ A6
	N	55, 17, 14           @ G#6
	N	53, 17, 14           @ F#6
	N	55, 17, 14           @ G#6
	N	56, 17, 14           @ A6
	N	48, 17, 8            @ C#6
	N	50, 17, 14           @ D#6
	N	53, 17, 14           @ F#6
	N	57, 17, 14           @ A#6
	N	62, 17, 18           @ D#7
	N	64, 17, 14           @ F7
	N	65, 17, 14           @ F#7
	N	64, 17, 14           @ F7
	N	62, 17, 14           @ D#7
	N	64, 17, 8            @ F7
	N	59, 17, 8            @ C7
	N	56, 17, 8            @ A6
	N	52, 17, 8            @ F6
	PAT_END
pat_08021DE7:				@ used by s6c1
	N	52, 17, 8            @ F6
	N	57, 17, 15           @ A#6
	N	55, 17, 14           @ G#6
	N	57, 17, 15           @ A#6
	N	59, 17, 14           @ C7
	N	60, 17, 15           @ C#7
	N	62, 17, 14           @ D#7
	N	63, 17, 14           @ E7
	N	62, 17, 14           @ D#7
	N	60, 17, 14           @ C#7
	N	66, 17, 8            @ G7
	N	67, 17, 10           @ G#7
	N	69, 17, 8            @ A#7
	N	64, 17, 15           @ F7
	N	62, 17, 14           @ D#7
	N	60, 17, 15           @ C#7
	N	59, 17, 14           @ C7
	N	57, 17, 15           @ A#6
	N	60, 17, 14           @ C#7
	N	56, 17, 8            @ A6
	N	55, 17, 15           @ G#6
	N	56, 17, 14           @ A6
	N	53, 17, 10           @ F#6
	N	57, 17, 14           @ A#6
	N	52, 17, 14           @ F6
	N	57, 17, 14           @ A#6
	N	59, 17, 15           @ C7
	N	57, 17, 13           @ A#6
	N	59, 17, 13           @ C7
	N	60, 17, 15           @ C#7
	N	62, 17, 14           @ D#7
	N	64, 17, 15           @ F7
	N	67, 17, 14           @ G#7
	N	66, 17, 8            @ G7
	N	67, 17, 8            @ G#7
	N	63, 17, 10           @ E7
	N	64, 17, 14           @ F7
	N	62, 17, 14           @ D#7
	N	60, 17, 14           @ C#7
	N	57, 17, 15           @ A#6
	N	55, 17, 14           @ G#6
	N	57, 17, 15           @ A#6
	N	59, 17, 14           @ C7
	N	60, 17, 15           @ C#7
	N	59, 17, 14           @ C7
	N	60, 17, 8            @ C#7
	N	59, 17, 8            @ C7
	N	57, 17, 10           @ A#6
	PAT_END
pat_08021E78:				@ used by s6c1
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 14           @ B6
	N	61, 17, 14           @ D7
	N	58, 17, 14           @ B6
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	59, 17, 13           @ C7
	N	59, 17, 14           @ C7
	N	58, 17, 13           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	62, 17, 14           @ D#7
	N	61, 17, 14           @ D7
	N	58, 17, 14           @ B6
	PAT_END
pat_08021ED6:				@ used by s6c1
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	57, 17, 13           @ A#6
	N	57, 17, 14           @ A#6
	N	57, 17, 13           @ A#6
	N	57, 17, 14           @ A#6
	N	60, 17, 14           @ C#7
	N	58, 17, 14           @ B6
	N	57, 17, 14           @ A#6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	57, 17, 13           @ A#6
	N	57, 17, 14           @ A#6
	N	57, 17, 13           @ A#6
	N	57, 17, 14           @ A#6
	N	65, 17, 13           @ F#7
	N	63, 17, 13           @ E7
	N	61, 17, 14           @ D7
	N	60, 17, 14           @ C#7
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	58, 17, 13           @ B6
	N	58, 17, 14           @ B6
	N	53, 17, 14           @ F#6
	N	53, 17, 14           @ F#6
	N	53, 17, 14           @ F#6
	N	53, 17, 14           @ F#6
	N	55, 17, 14           @ G#6
	N	57, 17, 14           @ A#6
	N	60, 17, 8            @ C#7
	N	58, 17, 15           @ B6
	N	60, 17, 14           @ C#7
	N	57, 17, 8            @ A#6
	N	53, 17, 8            @ F#6
	PAT_END
pat_08021F6D:				@ used by s6c2
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	PAT_END
pat_08021FB6:				@ used by s6c2
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	54, 18, 14           @ G6
	N	57, 18, 14           @ A#6
	N	61, 18, 14           @ D7
	N	54, 18, 14           @ G6
	N	57, 18, 14           @ A#6
	N	61, 18, 14           @ D7
	N	54, 18, 14           @ G6
	N	57, 18, 14           @ A#6
	N	61, 18, 14           @ D7
	N	54, 18, 14           @ G6
	N	57, 18, 14           @ A#6
	N	61, 18, 14           @ D7
	PAT_END
pat_08022047:				@ used by s6c2
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	61, 18, 14           @ D7
	N	64, 18, 14           @ F7
	N	68, 18, 14           @ A7
	N	61, 18, 14           @ D7
	N	64, 18, 14           @ F7
	N	68, 18, 14           @ A7
	N	61, 18, 14           @ D7
	N	64, 18, 14           @ F7
	N	68, 18, 14           @ A7
	N	61, 18, 14           @ D7
	N	64, 18, 14           @ F7
	N	68, 18, 14           @ A7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	65, 18, 14           @ F#7
	N	55, 18, 14           @ G#6
	N	58, 18, 14           @ B6
	N	62, 18, 14           @ D#7
	N	55, 18, 14           @ G#6
	N	58, 18, 14           @ B6
	N	62, 18, 14           @ D#7
	N	55, 18, 14           @ G#6
	N	58, 18, 14           @ B6
	N	62, 18, 14           @ D#7
	N	55, 18, 14           @ G#6
	N	58, 18, 14           @ B6
	N	62, 18, 14           @ D#7
	PAT_END
pat_080220D8:				@ used by s6c2
	N	55, 18, 14           @ G#6
	N	58, 18, 14           @ B6
	N	62, 18, 14           @ D#7
	N	67, 18, 14           @ G#7
	N	62, 18, 14           @ D#7
	N	58, 18, 14           @ B6
	N	55, 18, 14           @ G#6
	N	58, 18, 14           @ B6
	N	62, 18, 14           @ D#7
	N	67, 18, 14           @ G#7
	N	62, 18, 14           @ D#7
	N	58, 18, 14           @ B6
	N	54, 18, 14           @ G6
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	66, 18, 14           @ G7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	54, 18, 14           @ G6
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	66, 18, 14           @ G7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	60, 18, 14           @ C#7
	N	56, 18, 14           @ A6
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	60, 18, 14           @ C#7
	N	56, 18, 14           @ A6
	N	52, 18, 14           @ F6
	N	55, 18, 14           @ G#6
	N	59, 18, 14           @ C7
	N	64, 18, 14           @ F7
	N	59, 18, 14           @ C7
	N	55, 18, 14           @ G#6
	N	52, 18, 14           @ F6
	N	55, 18, 14           @ G#6
	N	59, 18, 14           @ C7
	N	64, 18, 14           @ F7
	N	59, 18, 14           @ C7
	N	55, 18, 14           @ G#6
	PAT_END
pat_08022169:				@ used by s6c2
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	65, 18, 14           @ F#7
	N	62, 18, 14           @ D#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	65, 18, 14           @ F#7
	N	62, 18, 14           @ D#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	60, 18, 14           @ C#7
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	65, 18, 14           @ F#7
	N	62, 18, 14           @ D#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	65, 18, 14           @ F#7
	N	62, 18, 14           @ D#7
	N	57, 18, 14           @ A#6
	N	62, 18, 14           @ D#7
	N	64, 18, 14           @ F7
	N	59, 18, 14           @ C7
	N	56, 18, 14           @ A6
	N	59, 18, 14           @ C7
	N	52, 18, 14           @ F6
	N	56, 18, 14           @ A6
	N	59, 18, 14           @ C7
	N	56, 18, 14           @ A6
	N	59, 18, 14           @ C7
	N	64, 18, 14           @ F7
	N	59, 18, 14           @ C7
	N	56, 18, 14           @ A6
	PAT_END
pat_080221FA:				@ used by s6c2
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	67, 18, 14           @ G#7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	68, 18, 14           @ A7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	67, 18, 14           @ G#7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	66, 18, 14           @ G7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	61, 18, 14           @ D7
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	53, 18, 14           @ F#6
	N	56, 18, 14           @ A6
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	67, 18, 14           @ G#7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	68, 18, 14           @ A7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	67, 18, 14           @ G#7
	N	60, 18, 14           @ C#7
	N	63, 18, 14           @ E7
	N	67, 18, 14           @ G#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	65, 18, 14           @ F#7
	N	64, 18, 14           @ F7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	N	57, 18, 14           @ A#6
	N	60, 18, 14           @ C#7
	N	64, 18, 14           @ F7
	PAT_END
pat_0802231B:				@ used by s6c2
	N	59, 18, 14           @ C7
	N	62, 18, 14           @ D#7
	N	66, 18, 14           @ G7
	N	59, 18, 14           @ C7
	N	62, 18, 14           @ D#7
	N	66, 18, 14           @ G7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	66, 18, 14           @ G7
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	66, 18, 14           @ G7
	N	59, 18, 14           @ C7
	N	62, 18, 14           @ D#7
	N	66, 18, 14           @ G7
	N	59, 18, 14           @ C7
	N	62, 18, 14           @ D#7
	N	66, 18, 14           @ G7
	N	54, 18, 14           @ G6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	54, 18, 14           @ G6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	PAT_END
pat_08022364:				@ used by s6c2
	N	53, 18, 14           @ F#6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	53, 18, 14           @ F#6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	53, 18, 14           @ F#6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	53, 18, 14           @ F#6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	53, 18, 14           @ F#6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	53, 18, 14           @ F#6
	N	58, 18, 14           @ B6
	N	61, 18, 14           @ D7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	65, 18, 14           @ F#7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	69, 18, 14           @ A#7
	N	65, 18, 14           @ F#7
	N	60, 18, 14           @ C#7
	N	65, 18, 14           @ F#7
	N	60, 18, 14           @ C#7
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	N	57, 18, 14           @ A#6
	N	53, 18, 14           @ F#6
	PAT_END
pat_080223F5:				@ used by s6c3
	N	34, 11, 17           @ B4
	N	33, 11, 14           @ A#4
	N	34, 11, 14           @ B4
	N	36, 11, 8            @ C#5
	N	34, 11, 8            @ B4
	N	33, 11, 8            @ A#4
	N	40, 11, 14           @ F5
	N	38, 11, 14           @ D#5
	N	40, 11, 14           @ F5
	N	36, 11, 8            @ C#5
	N	33, 11, 8            @ A#4
	PAT_END
pat_08022417:				@ used by s6c3
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	29, 11, 14           @ F#4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	28, 11, 14           @ F4
	N	28, 11, 14           @ F4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	40, 11, 14           @ F5
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 14           @ G4
	N	37, 11, 14           @ D5
	N	37, 11, 14           @ D5
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 14           @ G4
	N	31, 11, 14           @ G#4
	N	32, 11, 14           @ A4
	PAT_END
pat_080224C6:				@ used by s6c3
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	37, 11, 13           @ D5
	N	37, 11, 14           @ D5
	N	37, 11, 13           @ D5
	N	37, 11, 14           @ D5
	N	37, 11, 14           @ D5
	N	32, 11, 14           @ A4
	N	32, 11, 14           @ A4
	N	37, 11, 13           @ D5
	N	37, 11, 14           @ D5
	N	37, 11, 13           @ D5
	N	37, 11, 14           @ D5
	N	37, 11, 14           @ D5
	N	37, 11, 14           @ D5
	N	37, 11, 14           @ D5
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	29, 11, 14           @ F#4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	33, 11, 14           @ A#4
	N	32, 11, 14           @ A4
	N	31, 11, 13           @ G#4
	N	31, 11, 14           @ G#4
	N	31, 11, 13           @ G#4
	N	31, 11, 14           @ G#4
	N	31, 11, 15           @ G#4
	N	33, 11, 14           @ A#4
	N	34, 11, 15           @ B4
	N	33, 11, 14           @ A#4
	N	31, 11, 8            @ G#4
	PAT_END
pat_08022560:				@ used by s6c3
	N	31, 11, 13           @ G#4
	N	31, 11, 14           @ G#4
	N	31, 11, 13           @ G#4
	N	31, 11, 14           @ G#4
	N	31, 11, 14           @ G#4
	N	34, 11, 14           @ B4
	N	38, 11, 14           @ D#5
	N	31, 11, 13           @ G#4
	N	31, 11, 14           @ G#4
	N	31, 11, 13           @ G#4
	N	31, 11, 14           @ G#4
	N	31, 11, 14           @ G#4
	N	34, 11, 14           @ B4
	N	31, 11, 14           @ G#4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 14           @ G4
	N	33, 11, 14           @ A#4
	N	38, 11, 14           @ D#5
	N	26, 11, 13           @ D#4
	N	26, 11, 14           @ D#4
	N	26, 11, 13           @ D#4
	N	26, 11, 14           @ D#4
	N	26, 11, 14           @ D#4
	N	30, 11, 14           @ G4
	N	33, 11, 14           @ A#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	32, 11, 14           @ A4
	N	36, 11, 14           @ C#5
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	32, 11, 14           @ A4
	N	36, 11, 14           @ C#5
	N	40, 11, 15           @ F5
	N	35, 11, 14           @ C5
	N	31, 11, 15           @ G#4
	N	35, 11, 14           @ C5
	N	28, 11, 13           @ F4
	N	28, 11, 14           @ F4
	N	28, 11, 13           @ F4
	N	28, 11, 14           @ F4
	N	28, 11, 15           @ F4
	N	28, 11, 14           @ F4
	PAT_END
pat_080225FD:				@ used by s6c3
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	33, 11, 14           @ A#4
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	33, 11, 14           @ A#4
	N	38, 11, 14           @ D#5
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	32, 11, 14           @ A4
	N	36, 11, 14           @ C#5
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	32, 11, 14           @ A4
	N	29, 11, 14           @ F#4
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	33, 11, 14           @ A#4
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 13           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	38, 11, 14           @ D#5
	N	39, 11, 14           @ E5
	N	40, 11, 13           @ F5
	N	40, 11, 14           @ F5
	N	40, 11, 13           @ F5
	N	40, 11, 14           @ F5
	N	40, 11, 14           @ F5
	N	35, 11, 14           @ C5
	N	32, 11, 14           @ A4
	N	35, 11, 14           @ C5
	N	32, 11, 14           @ A4
	N	35, 11, 14           @ C5
	N	28, 11, 8            @ F4
	PAT_END
pat_0802269D:				@ used by s6c3
	N	33, 11, 13           @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	36, 11, 14           @ C#5
	N	40, 11, 14           @ F5
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	28, 11, 14           @ F4
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	39, 11, 14           @ E5
	N	43, 11, 14           @ G#5
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	28, 11, 14           @ F4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	32, 11, 14           @ A4
	N	36, 11, 14           @ C#5
	N	41, 11, 13           @ F#5
	N	41, 11, 14           @ F#5
	N	41, 11, 13           @ F#5
	N	41, 11, 14           @ F#5
	N	41, 11, 14           @ F#5
	N	36, 11, 14           @ C#5
	N	32, 11, 14           @ A4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	36, 11, 14           @ C#5
	N	40, 11, 14           @ F5
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	33, 11, 14           @ A#4
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	39, 11, 14           @ E5
	N	43, 11, 14           @ G#5
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 13           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	36, 11, 14           @ C#5
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	36, 11, 14           @ C#5
	N	40, 11, 14           @ F5
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	28, 11, 14           @ F4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 13           @ A#4
	N	33, 11, 14           @ A#4
	N	33, 11, 14           @ A#4
	N	36, 11, 14           @ C#5
	N	40, 11, 14           @ F5
	N	38, 11, 14           @ D#5
	N	36, 11, 14           @ C#5
	N	35, 11, 14           @ C5
	N	33, 11, 8            @ A#4
	PAT_END
pat_080227E2:				@ used by s6c3
	N	35, 11, 6            @ C5
	N	35, 11, 13           @ C5
	N	35, 11, 14           @ C5
	N	35, 11, 14           @ C5
	N	38, 11, 14           @ D#5
	N	35, 11, 14           @ C5
	N	34, 11, 6            @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	37, 11, 14           @ D5
	N	34, 11, 14           @ B4
	N	35, 11, 6            @ C5
	N	35, 11, 13           @ C5
	N	35, 11, 14           @ C5
	N	35, 11, 14           @ C5
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	30, 11, 6            @ G4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 14           @ G4
	N	32, 11, 14           @ A4
	N	34, 11, 14           @ B4
	N	35, 11, 6            @ C5
	N	35, 11, 13           @ C5
	N	35, 11, 14           @ C5
	N	35, 11, 13           @ C5
	N	37, 11, 13           @ D5
	N	38, 11, 13           @ D#5
	N	40, 11, 13           @ F5
	N	41, 11, 13           @ F#5
	N	42, 11, 13           @ G5
	N	34, 11, 6            @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	35, 11, 13           @ C5
	N	37, 11, 13           @ D5
	N	38, 11, 13           @ D#5
	N	40, 11, 13           @ F5
	N	41, 11, 13           @ F#5
	N	42, 11, 13           @ G5
	N	35, 11, 6            @ C5
	N	35, 11, 13           @ C5
	N	35, 11, 14           @ C5
	N	35, 11, 14           @ C5
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	30, 11, 6            @ G4
	N	30, 11, 13           @ G4
	N	30, 11, 14           @ G4
	N	30, 11, 14           @ G4
	N	34, 11, 14           @ B4
	N	37, 11, 14           @ D5
	PAT_END
pat_08022885:				@ used by s6c3
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	37, 11, 14           @ D5
	N	41, 11, 14           @ F#5
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 13           @ F#4
	N	29, 11, 14           @ F#4
	N	29, 11, 14           @ F#4
	N	31, 11, 14           @ G#4
	N	33, 11, 14           @ A#4
	N	34, 11, 6            @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 13           @ B4
	N	37, 11, 13           @ D5
	N	41, 11, 13           @ F#5
	N	37, 11, 13           @ D5
	N	34, 11, 14           @ B4
	N	36, 11, 15           @ C#5
	N	34, 11, 14           @ B4
	N	33, 11, 14           @ A#4
	N	31, 11, 14           @ G#4
	N	29, 11, 14           @ F#4
	N	34, 11, 6            @ B4
	N	34, 11, 13           @ B4
	N	34, 11, 14           @ B4
	N	34, 11, 14           @ B4
	N	37, 11, 14           @ D5
	N	41, 11, 14           @ F#5
	N	36, 11, 8            @ C#5
	N	33, 11, 15           @ A#4
	N	31, 11, 14           @ G#4
	N	29, 11, 8            @ F#4
	N	36, 11, 15           @ C#5
	N	33, 11, 14           @ A#4
	N	29, 11, 8            @ F#4
	N	41, 11, 14           @ F#5
	N	36, 11, 14           @ C#5
	N	33, 11, 14           @ A#4
	PAT_END
pat_08022907:				@ used by s6c4
	N	24, 1, 3             @ C#4
	N	24, 1, 20            @ C#4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	N	30, 3, 13            @ G4
	N	24, 1, 3             @ C#4
	N	24, 1, 20            @ C#4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	N	30, 3, 13            @ G4
	N	24, 1, 3             @ C#4
	N	24, 1, 20            @ C#4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	N	30, 3, 13            @ G4
	N	24, 1, 3             @ C#4
	N	24, 1, 20            @ C#4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	N	30, 3, 13            @ G4
	PAT_END
pat_08022944:				@ used by s5c1
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	66, 16, 8            @ G7
	N	62, 16, 6            @ D#7
	N	64, 16, 6            @ F7
	N	55, 16, 9            @ G#6
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	66, 16, 8            @ G7
	N	62, 16, 6            @ D#7
	N	62, 16, 6            @ D#7
	N	71, 16, 9            @ C8
	N	62, 16, 6            @ D#7
	N	70, 16, 8            @ B7
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	64, 16, 6            @ F7
	N	60, 16, 8            @ C#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	62, 16, 8            @ D#7
	N	66, 16, 6            @ G7
	N	69, 16, 6            @ A#7
	N	67, 16, 10           @ G#7
	PAT_END
pat_08022993:				@ used by s5c1
	N	60, 16, 6            @ C#7
	N	67, 16, 8            @ G#7
	N	62, 16, 2            @ D#7
	N	65, 16, 2            @ F#7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	63, 16, 6            @ E7
	N	69, 16, 9            @ A#7
	N	59, 16, 6            @ C7
	N	71, 16, 8            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	66, 16, 2            @ G7
	N	64, 16, 2            @ F7
	N	62, 16, 6            @ D#7
	N	74, 16, 9            @ D#8
	N	76, 16, 4            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	74, 16, 4            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	72, 16, 4            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	68, 16, 4            @ A7
	N	69, 16, 4            @ A#7
	N	69, 16, 8            @ A#7
	N	71, 16, 6            @ C8
	N	72, 16, 6            @ C#8
	N	74, 16, 4            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	72, 16, 4            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	71, 16, 4            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	66, 16, 8            @ G7
	N	64, 16, 8            @ F7
	N	72, 16, 7            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 6            @ G#7
	N	66, 16, 6            @ G7
	N	64, 16, 6            @ F7
	N	62, 16, 6            @ D#7
	N	69, 16, 6            @ A#7
	N	72, 16, 6            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	69, 16, 4            @ A#7
	N	67, 16, 2            @ G#7
	N	66, 16, 2            @ G7
	N	67, 16, 4            @ G#7
	N	66, 16, 2            @ G7
	N	64, 16, 2            @ F7
	N	66, 16, 4            @ G7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	64, 16, 4            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	62, 16, 4            @ D#7
	N	60, 16, 2            @ C#7
	N	59, 16, 2            @ C7
	N	57, 16, 2            @ A#6
	N	59, 16, 2            @ C7
	N	57, 16, 2            @ A#6
	N	59, 16, 2            @ C7
	N	55, 16, 6            @ G#6
	PAT_END
pat_08022A75:				@ used by s5c1
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	66, 16, 8            @ G7
	N	62, 16, 6            @ D#7
	N	64, 16, 6            @ F7
	N	55, 16, 9            @ G#6
	N	66, 16, 4            @ G7
	N	67, 16, 4            @ G#7
	N	66, 16, 8            @ G7
	N	62, 16, 6            @ D#7
	N	62, 16, 6            @ D#7
	N	71, 16, 9            @ C8
	N	62, 16, 6            @ D#7
	N	70, 16, 8            @ B7
	N	70, 16, 2            @ B7
	N	69, 16, 2            @ A#7
	N	67, 16, 2            @ G#7
	N	65, 16, 2            @ F#7
	N	64, 16, 6            @ F7
	N	60, 16, 8            @ C#7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	62, 16, 8            @ D#7
	N	66, 16, 6            @ G7
	N	69, 16, 6            @ A#7
	N	71, 16, 10           @ C8
	PAT_END
pat_08022AC4:				@ used by s5c1
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	63, 16, 8            @ E7
	N	59, 16, 6            @ C7
	N	61, 16, 6            @ D7
	N	52, 16, 9            @ F6
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	63, 16, 8            @ E7
	N	59, 16, 6            @ C7
	N	59, 16, 6            @ C7
	N	66, 16, 9            @ G7
	N	60, 16, 6            @ C#7
	N	67, 16, 8            @ G#7
	N	66, 16, 2            @ G7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	60, 16, 2            @ C#7
	N	59, 16, 6            @ C7
	N	57, 16, 8            @ A#6
	N	59, 16, 4            @ C7
	N	60, 16, 4            @ C#7
	N	59, 16, 4            @ C7
	N	56, 16, 2            @ A6
	N	59, 16, 2            @ C7
	N	64, 16, 4            @ F7
	N	68, 16, 2            @ A7
	N	64, 16, 2            @ F7
	N	59, 16, 11           @ C7
	PAT_END
pat_08022B1C:				@ used by s5c1
	N	57, 16, 4            @ A#6
	N	61, 16, 2            @ D7
	N	64, 16, 2            @ F7
	N	69, 16, 8            @ A#7
	N	68, 16, 2            @ A7
	N	66, 16, 2            @ G7
	N	64, 16, 2            @ F7
	N	62, 16, 2            @ D#7
	N	61, 16, 4            @ D7
	N	62, 16, 4            @ D#7
	N	64, 16, 4            @ F7
	N	61, 16, 4            @ D7
	N	57, 16, 8            @ A#6
	N	59, 16, 4            @ C7
	N	63, 16, 2            @ E7
	N	66, 16, 2            @ G7
	N	71, 16, 8            @ C8
	N	69, 16, 2            @ A#7
	N	68, 16, 2            @ A7
	N	66, 16, 2            @ G7
	N	64, 16, 2            @ F7
	N	63, 16, 4            @ E7
	N	64, 16, 4            @ F7
	N	66, 16, 4            @ G7
	N	63, 16, 4            @ E7
	N	59, 16, 8            @ C7
	N	64, 16, 4            @ F7
	N	67, 16, 2            @ G#7
	N	72, 16, 2            @ C#8
	N	76, 16, 8            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	72, 16, 2            @ C#8
	N	74, 16, 4            @ D#8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	69, 16, 2            @ A#7
	N	71, 16, 2            @ C8
	N	67, 16, 8            @ G#7
	N	65, 16, 4            @ F#7
	N	67, 16, 2            @ G#7
	N	69, 16, 2            @ A#7
	N	72, 16, 7            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	71, 16, 4            @ C8
	N	72, 16, 4            @ C#8
	N	71, 16, 4            @ C8
	N	68, 16, 4            @ A7
	N	64, 16, 4            @ F7
	N	68, 16, 4            @ A7
	N	76, 16, 4            @ F8
	N	74, 16, 2            @ D#8
	N	72, 16, 2            @ C#8
	N	71, 16, 2            @ C8
	N	69, 16, 2            @ A#7
	N	68, 16, 4            @ A7
	PAT_END
pat_08022BCB:				@ used by s5c1
	N	64, 16, 2            @ F7
	N	60, 16, 2            @ C#7
	N	57, 16, 2            @ A#6
	N	64, 16, 4            @ F7
	N	60, 16, 2            @ C#7
	N	57, 16, 4            @ A#6
	N	63, 16, 4            @ E7
	N	60, 16, 4            @ C#7
	N	57, 16, 4            @ A#6
	N	52, 16, 4            @ F6
	N	64, 16, 2            @ F7
	N	60, 16, 2            @ C#7
	N	57, 16, 2            @ A#6
	N	64, 16, 4            @ F7
	N	60, 16, 2            @ C#7
	N	57, 16, 4            @ A#6
	N	63, 16, 4            @ E7
	N	60, 16, 4            @ C#7
	N	57, 16, 6            @ A#6
	N	62, 16, 2            @ D#7
	N	59, 16, 2            @ C7
	N	55, 16, 2            @ G#6
	N	62, 16, 4            @ D#7
	N	59, 16, 2            @ C7
	N	55, 16, 4            @ G#6
	N	61, 16, 4            @ D7
	N	58, 16, 4            @ B6
	N	55, 16, 4            @ G#6
	N	50, 16, 4            @ D#6
	N	62, 16, 2            @ D#7
	N	59, 16, 2            @ C7
	N	55, 16, 2            @ G#6
	N	62, 16, 4            @ D#7
	N	59, 16, 2            @ C7
	N	55, 16, 4            @ G#6
	N	64, 16, 4            @ F7
	N	62, 16, 4            @ D#7
	N	60, 16, 4            @ C#7
	N	59, 16, 4            @ C7
	N	60, 16, 2            @ C#7
	N	57, 16, 2            @ A#6
	N	52, 16, 2            @ F6
	N	60, 16, 4            @ C#7
	N	57, 16, 2            @ A#6
	N	52, 16, 4            @ F6
	N	59, 16, 4            @ C7
	N	56, 16, 4            @ A6
	N	52, 16, 4            @ F6
	N	64, 16, 4            @ F7
	N	60, 16, 2            @ C#7
	N	57, 16, 2            @ A#6
	N	52, 16, 2            @ F6
	N	60, 16, 4            @ C#7
	N	57, 16, 2            @ A#6
	N	52, 16, 4            @ F6
	N	62, 16, 4            @ D#7
	N	60, 16, 4            @ C#7
	N	59, 16, 4            @ C7
	N	57, 16, 4            @ A#6
	N	59, 16, 6            @ C7
	N	60, 16, 6            @ C#7
	N	62, 16, 6            @ D#7
	N	64, 16, 6            @ F7
	N	65, 16, 6            @ F#7
	N	67, 16, 6            @ G#7
	N	69, 16, 6            @ A#7
	N	71, 16, 6            @ C8
	PAT_END
pat_08022C95:				@ used by s5c2
	N	60, 13, 4            @ C#7
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 4            @ G#7
	N	60, 13, 6            @ C#7
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 4            @ G#7
	N	64, 13, 4            @ F7
	N	60, 13, 4            @ C#7
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 4            @ G#7
	N	60, 13, 6            @ C#7
	N	76, 13, 4            @ F8
	N	72, 13, 4            @ C#8
	N	67, 13, 4            @ G#7
	N	60, 13, 4            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 4            @ C#8
	N	76, 13, 6            @ F8
	N	60, 13, 2            @ C#7
	N	72, 13, 2            @ C#8
	N	67, 13, 4            @ G#7
	N	72, 13, 4            @ C#8
	N	59, 13, 4            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 4            @ C8
	N	74, 13, 5            @ D#8
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 4            @ C8
	N	74, 13, 4            @ D#8
	N	58, 13, 4            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 4            @ B7
	N	74, 13, 5            @ D#8
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	74, 13, 2            @ D#8
	N	70, 13, 4            @ B7
	N	72, 13, 4            @ C#8
	N	69, 13, 2            @ A#7
	N	64, 13, 2            @ F7
	N	60, 13, 4            @ C#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 4            @ F7
	N	69, 13, 4            @ A#7
	N	72, 13, 4            @ C#8
	N	69, 13, 4            @ A#7
	N	62, 13, 4            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	74, 13, 4            @ D#8
	N	69, 13, 4            @ A#7
	N	66, 13, 4            @ G7
	N	62, 13, 4            @ D#7
	N	66, 13, 4            @ G7
	N	62, 13, 4            @ D#7
	N	55, 13, 4            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	67, 13, 0            @ G#7
	N	69, 13, 0            @ A#7
	N	71, 13, 0            @ C8
	N	72, 13, 0            @ C#8
	N	74, 13, 0            @ D#8
	N	76, 13, 0            @ F8
	N	77, 13, 0            @ F#8
	N	79, 13, 0            @ G#8
	N	81, 13, 0            @ A#8
	N	79, 13, 0            @ G#8
	N	77, 13, 0            @ F#8
	N	76, 13, 0            @ F8
	N	74, 13, 0            @ D#8
	N	72, 13, 0            @ C#8
	N	71, 13, 0            @ C8
	N	69, 13, 0            @ A#7
	PAT_END
pat_08022D9B:				@ used by s5c2
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	PAT_END
pat_08022FDC:				@ used by s5c2
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	66, 13, 2            @ G7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	66, 13, 2            @ G7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	66, 13, 2            @ G7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	66, 13, 2            @ G7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	66, 13, 2            @ G7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	66, 13, 2            @ G7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	74, 13, 2            @ D#8
	N	70, 13, 2            @ B7
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	70, 13, 2            @ B7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	72, 13, 2            @ C#8
	N	69, 13, 2            @ A#7
	N	64, 13, 2            @ F7
	N	60, 13, 2            @ C#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	74, 13, 2            @ D#8
	N	69, 13, 2            @ A#7
	N	66, 13, 2            @ G7
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	74, 13, 2            @ D#8
	N	69, 13, 2            @ A#7
	N	66, 13, 2            @ G7
	N	62, 13, 2            @ D#7
	N	69, 13, 2            @ A#7
	N	74, 13, 2            @ D#8
	N	66, 13, 2            @ G7
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	76, 13, 2            @ F8
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	PAT_END
pat_0802315D:				@ used by s5c2
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	69, 13, 2            @ A#7
	N	64, 13, 2            @ F7
	N	61, 13, 2            @ D7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	69, 13, 2            @ A#7
	N	64, 13, 2            @ F7
	N	76, 13, 2            @ F8
	N	73, 13, 2            @ D8
	N	69, 13, 2            @ A#7
	N	64, 13, 2            @ F7
	N	61, 13, 2            @ D7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	76, 13, 2            @ F8
	N	73, 13, 2            @ D8
	N	69, 13, 2            @ A#7
	N	64, 13, 2            @ F7
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	75, 13, 2            @ E8
	N	71, 13, 2            @ C8
	N	75, 13, 2            @ E8
	N	71, 13, 2            @ C8
	N	78, 13, 2            @ G8
	N	75, 13, 2            @ E8
	N	71, 13, 2            @ C8
	N	66, 13, 2            @ G7
	N	75, 13, 2            @ E8
	N	71, 13, 2            @ C8
	N	63, 13, 2            @ E7
	N	75, 13, 2            @ E8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 2            @ G#7
	N	64, 13, 2            @ F7
	N	79, 13, 2            @ G#8
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 2            @ G#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	69, 13, 2            @ A#7
	N	74, 13, 2            @ D#8
	N	78, 13, 2            @ G8
	N	74, 13, 2            @ D#8
	N	69, 13, 2            @ A#7
	N	66, 13, 2            @ G7
	N	62, 13, 2            @ D#7
	N	78, 13, 2            @ G8
	N	74, 13, 2            @ D#8
	N	69, 13, 2            @ A#7
	N	66, 13, 2            @ G7
	N	62, 13, 2            @ D#7
	N	69, 13, 2            @ A#7
	N	74, 13, 2            @ D#8
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	76, 13, 2            @ F8
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	76, 13, 2            @ F8
	N	80, 13, 2            @ A8
	N	76, 13, 2            @ F8
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	76, 13, 2            @ F8
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	56, 13, 2            @ A6
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	64, 13, 2            @ F7
	N	59, 13, 2            @ C7
	PAT_END
pat_080232DE:				@ used by s5c2
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	76, 13, 2            @ F8
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	73, 13, 2            @ D8
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	61, 13, 2            @ D7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	75, 13, 2            @ E8
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	75, 13, 2            @ E8
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	59, 13, 2            @ C7
	N	63, 13, 2            @ E7
	N	66, 13, 2            @ G7
	N	71, 13, 2            @ C8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	76, 13, 2            @ F8
	N	72, 13, 2            @ C#8
	N	67, 13, 2            @ G#7
	N	64, 13, 2            @ F7
	N	55, 13, 2            @ G#6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	53, 13, 2            @ F#6
	N	60, 13, 2            @ C#7
	N	65, 13, 2            @ F#7
	N	69, 13, 2            @ A#7
	N	72, 13, 2            @ C#8
	N	69, 13, 2            @ A#7
	N	65, 13, 2            @ F#7
	N	60, 13, 2            @ C#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	65, 13, 2            @ F#7
	N	69, 13, 2            @ A#7
	N	72, 13, 2            @ C#8
	N	69, 13, 2            @ A#7
	N	65, 13, 2            @ F#7
	N	60, 13, 2            @ C#7
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	76, 13, 2            @ F8
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	64, 13, 2            @ F7
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	71, 13, 2            @ C8
	N	76, 13, 2            @ F8
	N	71, 13, 2            @ C8
	N	68, 13, 2            @ A7
	N	64, 13, 2            @ F7
	PAT_END
pat_0802345F:				@ used by s5c2
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	61, 13, 2            @ D7
	N	62, 13, 2            @ D#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	61, 13, 2            @ D7
	N	62, 13, 2            @ D#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	61, 13, 2            @ D7
	N	62, 13, 2            @ D#7
	N	56, 13, 2            @ A6
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	56, 13, 2            @ A6
	N	59, 13, 2            @ C7
	N	64, 13, 2            @ F7
	N	68, 13, 2            @ A7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	64, 13, 2            @ F7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	57, 13, 2            @ A#6
	N	60, 13, 2            @ C#7
	N	64, 13, 2            @ F7
	N	69, 13, 2            @ A#7
	N	54, 13, 2            @ G6
	N	57, 13, 2            @ A#6
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	54, 13, 2            @ G6
	N	57, 13, 2            @ A#6
	N	62, 13, 2            @ D#7
	N	66, 13, 2            @ G7
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	79, 13, 2            @ G#8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	71, 13, 2            @ C8
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	59, 13, 2            @ C7
	N	55, 13, 2            @ G#6
	N	62, 13, 2            @ D#7
	PAT_END
pat_080235E0:				@ used by s5c3
	N	36, 11, 7            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 7            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 7            @ C#5
	N	36, 11, 6            @ C#5
	N	36, 11, 4            @ C#5
	N	36, 11, 6            @ C#5
	N	35, 11, 7            @ C5
	N	35, 11, 6            @ C5
	N	35, 11, 4            @ C5
	N	35, 11, 6            @ C5
	N	34, 11, 7            @ B4
	N	34, 11, 6            @ B4
	N	34, 11, 4            @ B4
	N	34, 11, 6            @ B4
	N	33, 11, 7            @ A#4
	N	33, 11, 6            @ A#4
	N	33, 11, 4            @ A#4
	N	33, 11, 6            @ A#4
	N	38, 11, 7            @ D#5
	N	38, 11, 6            @ D#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	PAT_END
pat_08023650:				@ used by s5c3
	N	36, 11, 4            @ C#5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	48, 11, 4            @ C#6
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	45, 11, 4            @ A#5
	N	48, 11, 4            @ C#6
	N	45, 11, 4            @ A#5
	N	42, 11, 4            @ G5
	N	39, 11, 4            @ E5
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	47, 11, 4            @ C6
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	46, 11, 4            @ B5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	45, 11, 4            @ A#5
	N	42, 11, 4            @ G5
	N	39, 11, 4            @ E5
	N	36, 11, 4            @ C#5
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	N	34, 11, 4            @ B4
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	42, 11, 4            @ G5
	N	43, 11, 4            @ G#5
	N	45, 11, 4            @ A#5
	N	42, 11, 4            @ G5
	N	38, 11, 4            @ D#5
	N	33, 11, 4            @ A#4
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	PAT_END
pat_08023771:				@ used by s5c3
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	42, 11, 4            @ G5
	N	43, 11, 6            @ G#5
	N	48, 11, 4            @ C#6
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	48, 11, 6            @ C#6
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	42, 11, 4            @ G5
	N	43, 11, 6            @ G#5
	N	48, 11, 4            @ C#6
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	47, 11, 6            @ C6
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	34, 11, 4            @ B4
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	46, 11, 6            @ B5
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	34, 11, 4            @ B4
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	38, 11, 6            @ D#5
	N	42, 11, 4            @ G5
	N	45, 11, 6            @ A#5
	N	50, 11, 4            @ D#6
	N	45, 11, 4            @ A#5
	N	42, 11, 4            @ G5
	N	40, 11, 4            @ F5
	N	42, 11, 4            @ G5
	N	44, 11, 4            @ A5
	N	45, 11, 4            @ A#5
	N	47, 11, 4            @ C6
	N	44, 11, 4            @ A5
	N	42, 11, 4            @ G5
	N	40, 11, 4            @ F5
	PAT_END
pat_0802381D:				@ used by s5c3
	N	33, 11, 7            @ A#4
	N	37, 11, 6            @ D5
	N	40, 11, 4            @ F5
	N	37, 11, 2            @ D5
	N	40, 11, 2            @ F5
	N	37, 11, 4            @ D5
	N	33, 11, 7            @ A#4
	N	37, 11, 2            @ D5
	N	40, 11, 2            @ F5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	33, 11, 7            @ A#4
	N	37, 11, 6            @ D5
	N	40, 11, 2            @ F5
	N	37, 11, 2            @ D5
	N	33, 11, 4            @ A#4
	N	40, 11, 4            @ F5
	N	35, 11, 7            @ C5
	N	39, 11, 2            @ E5
	N	42, 11, 2            @ G5
	N	47, 11, 4            @ C6
	N	42, 11, 4            @ G5
	N	39, 11, 4            @ E5
	N	35, 11, 4            @ C5
	N	36, 11, 7            @ C#5
	N	40, 11, 2            @ F5
	N	43, 11, 2            @ G#5
	N	40, 11, 4            @ F5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	38, 11, 7            @ D#5
	N	33, 11, 6            @ A#4
	N	38, 11, 4            @ D#5
	N	42, 11, 4            @ G5
	N	38, 11, 4            @ D#5
	N	40, 11, 7            @ F5
	N	40, 11, 6            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	44, 11, 4            @ A5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	PAT_END
pat_080238B7:				@ used by s5c3
	N	33, 11, 4            @ A#4
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	45, 11, 5            @ A#5
	N	33, 11, 2            @ A#4
	N	37, 11, 2            @ D5
	N	40, 11, 2            @ F5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	37, 11, 4            @ D5
	N	40, 11, 4            @ F5
	N	45, 11, 5            @ A#5
	N	33, 11, 2            @ A#4
	N	37, 11, 2            @ D5
	N	40, 11, 2            @ F5
	N	45, 11, 4            @ A#5
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	47, 11, 5            @ C6
	N	42, 11, 2            @ G5
	N	39, 11, 2            @ E5
	N	42, 11, 2            @ G5
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	35, 11, 4            @ C5
	N	39, 11, 4            @ E5
	N	42, 11, 4            @ G5
	N	47, 11, 4            @ C6
	N	42, 11, 4            @ G5
	N	39, 11, 4            @ E5
	N	35, 11, 4            @ C5
	N	42, 11, 4            @ G5
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	43, 11, 4            @ G#5
	N	48, 11, 5            @ C#6
	N	36, 11, 2            @ C#5
	N	40, 11, 2            @ F5
	N	43, 11, 2            @ G#5
	N	48, 11, 4            @ C#6
	N	43, 11, 4            @ G#5
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	47, 11, 4            @ C6
	N	43, 11, 4            @ G#5
	N	38, 11, 4            @ D#5
	N	31, 11, 4            @ G#4
	N	29, 11, 4            @ F#4
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	41, 11, 4            @ F#5
	N	36, 11, 4            @ C#5
	N	33, 11, 4            @ A#4
	N	29, 11, 4            @ F#4
	N	33, 11, 4            @ A#4
	N	40, 11, 4            @ F5
	N	35, 11, 4            @ C5
	N	32, 11, 4            @ A4
	N	35, 11, 4            @ C5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	PAT_END
pat_08023984:				@ used by s5c3
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 5            @ A#5
	N	33, 11, 2            @ A#4
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 5            @ A#5
	N	33, 11, 2            @ A#4
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	40, 11, 4            @ F5
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 5            @ G#5
	N	31, 11, 2            @ G#4
	N	35, 11, 4            @ C5
	N	37, 11, 4            @ D5
	N	38, 11, 4            @ D#5
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	40, 11, 4            @ F5
	N	44, 11, 4            @ A5
	N	47, 11, 4            @ C6
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 5            @ A#5
	N	33, 11, 2            @ A#4
	N	36, 11, 4            @ C#5
	N	39, 11, 4            @ E5
	N	40, 11, 4            @ F5
	N	33, 11, 4            @ A#4
	N	36, 11, 4            @ C#5
	N	40, 11, 4            @ F5
	N	45, 11, 4            @ A#5
	N	38, 11, 4            @ D#5
	N	40, 11, 4            @ F5
	N	42, 11, 4            @ G5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	36, 11, 4            @ C#5
	N	35, 11, 4            @ C5
	N	33, 11, 4            @ A#4
	N	35, 11, 4            @ C5
	N	31, 11, 4            @ G#4
	N	35, 11, 4            @ C5
	N	38, 11, 4            @ D#5
	N	43, 11, 4            @ G#5
	N	41, 11, 4            @ F#5
	N	40, 11, 4            @ F5
	N	38, 11, 4            @ D#5
	N	35, 11, 4            @ C5
	PAT_END
pat_08023A45:				@ used by s5c4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	24, 1, 2             @ C#4
	N	24, 1, 2             @ C#4
	N	30, 3, 2             @ G4
	N	30, 4, 2             @ G4
	N	30, 3, 2             @ G4
	PAT_END
pat_08023B06:				@ used by s1c1
	N	60, 8, 14            @ C#7
	N	59, 8, 13            @ C7
	N	60, 8, 6             @ C#7
	N	64, 8, 6             @ F7
	N	55, 8, 9             @ G#6
	N	56, 8, 14            @ A6
	N	55, 8, 13            @ G#6
	N	53, 8, 6             @ F#6
	N	60, 8, 6             @ C#7
	N	65, 8, 9             @ F#7
	N	64, 8, 14            @ F7
	N	62, 8, 13            @ D#7
	N	64, 8, 6             @ F7
	N	67, 8, 6             @ G#7
	N	60, 8, 8             @ C#7
	N	62, 8, 6             @ D#7
	N	63, 8, 14            @ E7
	N	62, 8, 13            @ D#7
	N	60, 8, 14            @ C#7
	N	62, 8, 13            @ D#7
	N	63, 8, 14            @ E7
	N	60, 8, 13            @ C#7
	N	62, 8, 6             @ D#7
	N	59, 8, 6             @ C7
	N	55, 8, 6             @ G#6
	N	60, 8, 14            @ C#7
	N	59, 8, 13            @ C7
	N	60, 8, 6             @ C#7
	N	64, 8, 6             @ F7
	N	55, 8, 9             @ G#6
	N	56, 8, 14            @ A6
	N	55, 8, 13            @ G#6
	N	53, 8, 14            @ F#6
	N	55, 8, 13            @ G#6
	N	56, 8, 14            @ A6
	N	60, 8, 13            @ C#7
	N	65, 8, 8             @ F#7
	N	64, 8, 14            @ F7
	N	62, 8, 13            @ D#7
	N	64, 8, 8             @ F7
	N	62, 8, 14            @ D#7
	N	60, 8, 13            @ C#7
	N	62, 8, 14            @ D#7
	N	60, 8, 13            @ C#7
	N	58, 8, 6             @ B6
	N	62, 8, 6             @ D#7
	N	60, 8, 11            @ C#7
	PAT_END
pat_08023B94:				@ used by s1c1
	N	77, 8, 8             @ F#8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	70, 8, 8             @ B7
	N	70, 8, 2             @ B7
	N	74, 8, 2             @ D#8
	N	77, 8, 4             @ F#8
	N	76, 8, 8             @ F8
	N	74, 8, 2             @ D#8
	N	76, 8, 16            @ F8
	N	74, 8, 13            @ D#8
	N	72, 8, 6             @ C#8
	N	67, 8, 6             @ G#7
	N	72, 8, 4             @ C#8
	N	76, 8, 4             @ F8
	N	77, 8, 8             @ F#8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	70, 8, 8             @ B7
	N	70, 8, 2             @ B7
	N	74, 8, 2             @ D#8
	N	77, 8, 4             @ F#8
	N	76, 8, 6             @ F8
	N	74, 8, 6             @ D#8
	N	72, 8, 6             @ C#8
	N	67, 8, 6             @ G#7
	N	64, 8, 6             @ F7
	N	67, 8, 4             @ G#7
	N	72, 8, 4             @ C#8
	N	75, 8, 8             @ E8
	N	75, 8, 2             @ E8
	N	74, 8, 2             @ D#8
	N	72, 8, 4             @ C#8
	N	68, 8, 8             @ A7
	N	68, 8, 2             @ A7
	N	72, 8, 2             @ C#8
	N	75, 8, 4             @ E8
	N	74, 8, 8             @ D#8
	N	72, 8, 2             @ C#8
	N	74, 8, 2             @ D#8
	N	72, 8, 4             @ C#8
	N	70, 8, 6             @ B7
	N	67, 8, 6             @ G#7
	N	70, 8, 4             @ B7
	N	74, 8, 4             @ D#8
	N	75, 8, 8             @ E8
	N	75, 8, 2             @ E8
	N	74, 8, 2             @ D#8
	N	72, 8, 4             @ C#8
	N	68, 8, 6             @ A7
	N	63, 8, 4             @ E7
	N	68, 8, 4             @ A7
	N	72, 8, 4             @ C#8
	N	75, 8, 4             @ E8
	N	74, 8, 8             @ D#8
	N	72, 8, 2             @ C#8
	N	74, 8, 2             @ D#8
	N	72, 8, 4             @ C#8
	N	71, 8, 6             @ C8
	N	69, 8, 6             @ A#7
	N	67, 8, 6             @ G#7
	PAT_END
pat_08023C52:				@ used by s1c2
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	68, 13, 4            @ A7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	72, 13, 4            @ C#8
	N	65, 13, 4            @ F#7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	72, 13, 4            @ C#8
	N	65, 13, 4            @ F#7
	N	67, 13, 4            @ G#7
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	68, 13, 4            @ A7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	72, 13, 4            @ C#8
	N	75, 13, 4            @ E8
	N	68, 13, 4            @ A7
	N	67, 13, 4            @ G#7
	N	66, 13, 4            @ G7
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	74, 13, 4            @ D#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	68, 13, 4            @ A7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	72, 13, 4            @ C#8
	N	65, 13, 4            @ F#7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	67, 13, 4            @ G#7
	N	68, 13, 4            @ A7
	N	72, 13, 4            @ C#8
	N	65, 13, 4            @ F#7
	N	67, 13, 4            @ G#7
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	74, 13, 4            @ D#8
	N	72, 13, 4            @ C#8
	N	70, 13, 4            @ B7
	N	67, 13, 4            @ G#7
	N	74, 13, 4            @ D#8
	N	77, 13, 4            @ F#8
	N	76, 13, 4            @ F8
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	67, 13, 4            @ G#7
	N	65, 13, 4            @ F#7
	N	67, 13, 4            @ G#7
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	71, 13, 4            @ C8
	N	72, 13, 4            @ C#8
	N	76, 13, 4            @ F8
	PAT_END
pat_08023D73:				@ used by s1c2
	N	74, 8, 8             @ D#8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	70, 8, 13            @ B7
	N	65, 8, 8             @ F#7
	N	65, 8, 2             @ F#7
	N	70, 8, 2             @ B7
	N	74, 8, 4             @ D#8
	N	72, 8, 8             @ C#8
	N	70, 8, 2             @ B7
	N	72, 8, 16            @ C#8
	N	70, 8, 13            @ B7
	N	67, 8, 6             @ G#7
	N	64, 8, 6             @ F7
	N	67, 8, 4             @ G#7
	N	72, 8, 4             @ C#8
	N	74, 8, 8             @ D#8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	70, 8, 13            @ B7
	N	65, 8, 8             @ F#7
	N	65, 8, 2             @ F#7
	N	70, 8, 2             @ B7
	N	74, 8, 4             @ D#8
	N	72, 8, 6             @ C#8
	N	65, 8, 6             @ F#7
	N	64, 8, 6             @ F7
	N	64, 8, 6             @ F7
	N	60, 8, 6             @ C#7
	N	64, 8, 4             @ F7
	N	67, 8, 4             @ G#7
	N	72, 8, 8             @ C#8
	N	72, 8, 2             @ C#8
	N	70, 8, 2             @ B7
	N	68, 8, 4             @ A7
	N	63, 8, 8             @ E7
	N	63, 8, 2             @ E7
	N	68, 8, 2             @ A7
	N	72, 8, 4             @ C#8
	N	70, 8, 8             @ B7
	N	69, 8, 2             @ A#7
	N	70, 8, 2             @ B7
	N	69, 8, 4             @ A#7
	N	67, 8, 6             @ G#7
	N	62, 8, 6             @ D#7
	N	67, 8, 4             @ G#7
	N	70, 8, 4             @ B7
	N	72, 8, 8             @ C#8
	N	72, 8, 2             @ C#8
	N	70, 8, 2             @ B7
	N	68, 8, 4             @ A7
	N	63, 8, 6             @ E7
	N	60, 8, 4             @ C#7
	N	63, 8, 4             @ E7
	N	68, 8, 4             @ A7
	N	72, 8, 4             @ C#8
	N	71, 8, 8             @ C8
	N	69, 8, 2             @ A#7
	N	71, 8, 2             @ C8
	N	69, 8, 4             @ A#7
	N	62, 8, 6             @ D#7
	N	60, 8, 6             @ C#7
	N	59, 8, 6             @ C7
	PAT_END
pat_08023E31:				@ used by s1c2
	N	55, 13, 2            @ G#6
	N	57, 13, 2            @ A#6
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	69, 13, 2            @ A#7
	N	70, 13, 2            @ B7
	N	74, 13, 2            @ D#8
	N	79, 13, 2            @ G#8
	N	81, 13, 2            @ A#8
	N	82, 13, 2            @ B8
	N	81, 13, 2            @ A#8
	N	79, 13, 2            @ G#8
	N	74, 13, 2            @ D#8
	N	70, 13, 2            @ B7
	N	69, 13, 2            @ A#7
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	58, 13, 2            @ B6
	N	57, 13, 2            @ A#6
	N	55, 13, 2            @ G#6
	N	50, 13, 2            @ D#6
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	55, 13, 2            @ G#6
	N	60, 13, 2            @ C#7
	N	62, 13, 2            @ D#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	74, 13, 2            @ D#8
	N	76, 13, 2            @ F8
	N	79, 13, 2            @ G#8
	N	76, 13, 2            @ F8
	N	74, 13, 2            @ D#8
	N	72, 13, 2            @ C#8
	N	67, 13, 2            @ G#7
	N	64, 13, 2            @ F7
	N	62, 13, 2            @ D#7
	N	60, 13, 2            @ C#7
	N	55, 13, 2            @ G#6
	N	52, 13, 2            @ F6
	N	50, 13, 2            @ D#6
	N	48, 13, 2            @ C#6
	N	50, 13, 2            @ D#6
	N	52, 13, 2            @ F6
	N	55, 13, 2            @ G#6
	N	57, 13, 2            @ A#6
	N	55, 13, 2            @ G#6
	N	57, 13, 2            @ A#6
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	69, 13, 2            @ A#7
	N	70, 13, 2            @ B7
	N	74, 13, 2            @ D#8
	N	79, 13, 2            @ G#8
	N	81, 13, 2            @ A#8
	N	82, 13, 2            @ B8
	N	81, 13, 2            @ A#8
	N	79, 13, 2            @ G#8
	N	74, 13, 2            @ D#8
	N	70, 13, 2            @ B7
	N	69, 13, 2            @ A#7
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	58, 13, 2            @ B6
	N	57, 13, 2            @ A#6
	N	55, 13, 2            @ G#6
	N	50, 13, 2            @ D#6
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	55, 13, 2            @ G#6
	N	60, 13, 2            @ C#7
	N	62, 13, 2            @ D#7
	N	64, 13, 2            @ F7
	N	67, 13, 2            @ G#7
	N	72, 13, 2            @ C#8
	N	74, 13, 2            @ D#8
	N	76, 13, 2            @ F8
	N	79, 13, 2            @ G#8
	N	76, 13, 2            @ F8
	N	74, 13, 2            @ D#8
	N	72, 13, 2            @ C#8
	N	67, 13, 2            @ G#7
	N	64, 13, 2            @ F7
	N	62, 13, 2            @ D#7
	N	60, 13, 2            @ C#7
	N	55, 13, 2            @ G#6
	N	52, 13, 2            @ F6
	N	50, 13, 2            @ D#6
	N	48, 13, 2            @ C#6
	N	50, 13, 2            @ D#6
	N	52, 13, 2            @ F6
	N	55, 13, 2            @ G#6
	N	57, 13, 2            @ A#6
	N	56, 13, 2            @ A6
	N	58, 13, 2            @ B6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	68, 13, 2            @ A7
	N	70, 13, 2            @ B7
	N	72, 13, 2            @ C#8
	N	75, 13, 2            @ E8
	N	80, 13, 2            @ A8
	N	82, 13, 2            @ B8
	N	80, 13, 2            @ A8
	N	79, 13, 2            @ G#8
	N	75, 13, 2            @ E8
	N	72, 13, 2            @ C#8
	N	70, 13, 2            @ B7
	N	68, 13, 2            @ A7
	N	63, 13, 2            @ E7
	N	60, 13, 2            @ C#7
	N	58, 13, 2            @ B6
	N	56, 13, 2            @ A6
	N	51, 13, 2            @ E6
	N	56, 13, 2            @ A6
	N	58, 13, 2            @ B6
	N	60, 13, 2            @ C#7
	N	50, 13, 2            @ D#6
	N	55, 13, 2            @ G#6
	N	57, 13, 2            @ A#6
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	69, 13, 2            @ A#7
	N	70, 13, 2            @ B7
	N	74, 13, 2            @ D#8
	N	75, 13, 2            @ E8
	N	74, 13, 2            @ D#8
	N	75, 13, 2            @ E8
	N	74, 13, 2            @ D#8
	N	70, 13, 2            @ B7
	N	69, 13, 2            @ A#7
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	58, 13, 2            @ B6
	N	57, 13, 2            @ A#6
	N	55, 13, 2            @ G#6
	N	50, 13, 2            @ D#6
	N	55, 13, 2            @ G#6
	N	58, 13, 2            @ B6
	N	62, 13, 2            @ D#7
	N	56, 13, 2            @ A6
	N	58, 13, 2            @ B6
	N	60, 13, 2            @ C#7
	N	63, 13, 2            @ E7
	N	68, 13, 2            @ A7
	N	70, 13, 2            @ B7
	N	72, 13, 2            @ C#8
	N	75, 13, 2            @ E8
	N	80, 13, 2            @ A8
	N	82, 13, 2            @ B8
	N	80, 13, 2            @ A8
	N	79, 13, 2            @ G#8
	N	75, 13, 2            @ E8
	N	72, 13, 2            @ C#8
	N	70, 13, 2            @ B7
	N	68, 13, 2            @ A7
	N	63, 13, 2            @ E7
	N	60, 13, 2            @ C#7
	N	58, 13, 2            @ B6
	N	56, 13, 2            @ A6
	N	51, 13, 2            @ E6
	N	56, 13, 2            @ A6
	N	58, 13, 2            @ B6
	N	60, 13, 2            @ C#7
	N	50, 13, 2            @ D#6
	N	55, 13, 2            @ G#6
	N	57, 13, 2            @ A#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	N	67, 13, 2            @ G#7
	N	69, 13, 2            @ A#7
	N	71, 13, 2            @ C8
	N	74, 13, 2            @ D#8
	N	75, 13, 2            @ E8
	N	74, 13, 2            @ D#8
	N	75, 13, 2            @ E8
	N	74, 13, 2            @ D#8
	N	71, 13, 2            @ C8
	N	69, 13, 2            @ A#7
	N	67, 13, 2            @ G#7
	N	62, 13, 2            @ D#7
	N	59, 13, 2            @ C7
	N	57, 13, 2            @ A#6
	N	55, 13, 2            @ G#6
	N	50, 13, 2            @ D#6
	N	55, 13, 2            @ G#6
	N	59, 13, 2            @ C7
	N	62, 13, 2            @ D#7
	PAT_END
pat_08024072:				@ used by s1c3
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 6            @ C#5
	N	40, 12, 14           @ F5
	N	43, 12, 13           @ G#5
	N	36, 12, 6            @ C#5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 6            @ C#5
	N	29, 12, 17           @ F#4
	N	31, 12, 13           @ G#4
	N	32, 12, 14           @ A4
	N	36, 12, 13           @ C#5
	N	41, 12, 6            @ F#5
	N	36, 12, 6            @ C#5
	N	32, 12, 14           @ A4
	N	29, 12, 13           @ F#4
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 8            @ C#5
	N	36, 12, 6            @ C#5
	N	32, 12, 14           @ A4
	N	34, 12, 13           @ B4
	N	36, 12, 14           @ C#5
	N	34, 12, 13           @ B4
	N	32, 12, 6            @ A4
	N	31, 12, 6            @ G#4
	N	38, 12, 6            @ D#5
	N	43, 12, 6            @ G#5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 6            @ C#5
	N	31, 12, 6            @ G#4
	N	36, 12, 6            @ C#5
	N	29, 12, 17           @ F#4
	N	32, 12, 13           @ A4
	N	29, 12, 14           @ F#4
	N	32, 12, 13           @ A4
	N	36, 12, 6            @ C#5
	N	32, 12, 6            @ A4
	N	29, 12, 6            @ F#4
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	N	31, 12, 6            @ G#4
	N	34, 12, 14           @ B4
	N	38, 12, 13           @ D#5
	N	43, 12, 14           @ G#5
	N	38, 12, 13           @ D#5
	N	36, 12, 17           @ C#5
	N	34, 12, 13           @ B4
	N	36, 12, 14           @ C#5
	N	34, 12, 13           @ B4
	N	36, 12, 6            @ C#5
	N	36, 12, 6            @ C#5
	N	36, 12, 6            @ C#5
	PAT_END
pat_0802413C:				@ used by s1c3
	N	31, 12, 8            @ G#4
	N	33, 12, 6            @ A#4
	N	34, 12, 6            @ B4
	N	38, 12, 6            @ D#5
	N	34, 12, 6            @ B4
	N	36, 12, 8            @ C#5
	N	38, 12, 6            @ D#5
	N	40, 12, 6            @ F5
	N	38, 12, 6            @ D#5
	N	36, 12, 6            @ C#5
	N	34, 12, 8            @ B4
	N	31, 12, 14           @ G#4
	N	34, 12, 13           @ B4
	N	38, 12, 6            @ D#5
	N	36, 12, 6            @ C#5
	N	34, 12, 6            @ B4
	N	36, 12, 6            @ C#5
	N	40, 12, 6            @ F5
	N	43, 12, 6            @ G#5
	N	36, 12, 8            @ C#5
	N	34, 12, 6            @ B4
	N	32, 12, 6            @ A4
	N	36, 12, 6            @ C#5
	N	39, 12, 6            @ E5
	N	44, 12, 8            @ A5
	N	39, 12, 14           @ E5
	N	44, 12, 13           @ A5
	N	43, 12, 6            @ G#5
	N	38, 12, 6            @ D#5
	N	34, 12, 6            @ B4
	N	31, 12, 6            @ G#4
	N	34, 12, 6            @ B4
	N	38, 12, 14           @ D#5
	N	43, 12, 13           @ G#5
	N	44, 12, 8            @ A5
	N	39, 12, 6            @ E5
	N	36, 12, 6            @ C#5
	N	32, 12, 6            @ A4
	N	36, 12, 6            @ C#5
	N	43, 12, 6            @ G#5
	N	38, 12, 6            @ D#5
	N	35, 12, 6            @ C5
	N	31, 12, 6            @ G#4
	N	33, 12, 6            @ A#4
	N	31, 12, 6            @ G#4
	PAT_END
pat_080241C4:				@ used by s1c3
	N	31, 12, 6            @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 14           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 14           @ G#4
	N	31, 12, 13           @ G#4
	N	34, 12, 6            @ B4
	N	31, 12, 6            @ G#4
	N	36, 12, 6            @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 14           @ C#5
	N	36, 12, 13           @ C#5
	N	40, 12, 6            @ F5
	N	36, 12, 6            @ C#5
	N	43, 12, 6            @ G#5
	N	31, 12, 6            @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	34, 12, 6            @ B4
	N	31, 12, 6            @ G#4
	N	34, 12, 6            @ B4
	N	36, 12, 6            @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 14           @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 6            @ C#5
	N	36, 12, 6            @ C#5
	N	34, 12, 6            @ B4
	N	32, 12, 6            @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 14           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 6            @ A4
	N	36, 12, 6            @ C#5
	N	39, 12, 14           @ E5
	N	36, 12, 13           @ C#5
	N	31, 12, 6            @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 6            @ G#4
	N	34, 12, 6            @ B4
	N	38, 12, 6            @ D#5
	N	32, 12, 6            @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 13           @ A4
	N	32, 12, 6            @ A4
	N	36, 12, 6            @ C#5
	N	39, 12, 6            @ E5
	N	31, 12, 6            @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 14           @ G#4
	N	31, 12, 13           @ G#4
	N	35, 12, 6            @ C5
	N	31, 12, 6            @ G#4
	N	35, 12, 6            @ C5
	PAT_END
pat_080242AC:				@ used by s1c4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	24, 1, 4             @ C#4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 4             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 2             @ F4
	N	28, 6, 4             @ F4
	PAT_END
pat_0802435E:				@ used by s2c1
	N	65, 8, 8             @ F#7
	N	72, 8, 10            @ C#8
	N	70, 8, 4             @ B7
	N	69, 8, 4             @ A#7
	N	67, 8, 4             @ G#7
	N	65, 8, 4             @ F#7
	N	67, 8, 8             @ G#7
	N	74, 8, 11            @ D#8
	N	67, 8, 8             @ G#7
	N	76, 8, 10            @ F8
	N	76, 8, 4             @ F8
	N	74, 8, 4             @ D#8
	N	72, 8, 4             @ C#8
	N	70, 8, 4             @ B7
	N	69, 8, 6             @ A#7
	N	67, 8, 6             @ G#7
	N	69, 8, 6             @ A#7
	N	70, 8, 6             @ B7
	N	72, 8, 8             @ C#8
	N	0, 8, 4              @ C#2
	N	70, 8, 4             @ B7
	N	69, 8, 4             @ A#7
	N	67, 8, 4             @ G#7
	N	65, 8, 6             @ F#7
	N	69, 8, 4             @ A#7
	N	65, 8, 4             @ F#7
	N	72, 8, 10            @ C#8
	N	70, 8, 4             @ B7
	N	69, 8, 4             @ A#7
	N	67, 8, 4             @ G#7
	N	65, 8, 4             @ F#7
	N	67, 8, 8             @ G#7
	N	74, 8, 11            @ D#8
	N	67, 8, 8             @ G#7
	N	76, 8, 9             @ F8
	N	77, 8, 6             @ F#8
	N	79, 8, 4             @ G#8
	N	77, 8, 4             @ F#8
	N	76, 8, 6             @ F8
	N	77, 8, 12            @ F#8
	PAT_END
pat_080243D7:				@ used by s2c1
	N	77, 8, 4             @ F#8
	N	76, 8, 4             @ F8
	N	77, 8, 10            @ F#8
	N	74, 8, 6             @ D#8
	N	77, 8, 6             @ F#8
	N	81, 8, 6             @ A#8
	N	82, 8, 7             @ B8
	N	81, 8, 4             @ A#8
	N	79, 8, 6             @ G#8
	N	77, 8, 6             @ F#8
	N	79, 8, 7             @ G#8
	N	77, 8, 4             @ F#8
	N	76, 8, 4             @ F8
	N	74, 8, 4             @ D#8
	N	76, 8, 4             @ F8
	N	77, 8, 4             @ F#8
	N	76, 8, 4             @ F8
	N	74, 8, 4             @ D#8
	N	76, 8, 10            @ F8
	N	72, 8, 6             @ C#8
	N	76, 8, 6             @ F8
	N	82, 8, 6             @ B8
	N	81, 8, 7             @ A#8
	N	79, 8, 4             @ G#8
	N	81, 8, 4             @ A#8
	N	79, 8, 4             @ G#8
	N	77, 8, 4             @ F#8
	N	76, 8, 4             @ F8
	N	77, 8, 8             @ F#8
	N	72, 8, 6             @ C#8
	N	70, 8, 6             @ B7
	N	69, 8, 4             @ A#7
	N	74, 8, 4             @ D#8
	N	77, 8, 6             @ F#8
	N	81, 8, 9             @ A#8
	N	84, 8, 6             @ C#9
	N	82, 8, 6             @ B8
	N	81, 8, 6             @ A#8
	N	81, 8, 4             @ A#8
	N	82, 8, 4             @ B8
	N	79, 8, 4             @ G#8
	N	77, 8, 4             @ F#8
	N	79, 8, 9             @ G#8
	N	77, 8, 6             @ F#8
	N	76, 8, 6             @ F8
	N	74, 8, 6             @ D#8
	N	76, 8, 4             @ F8
	N	77, 8, 4             @ F#8
	N	79, 8, 6             @ G#8
	N	72, 8, 9             @ C#8
	N	76, 8, 4             @ F8
	N	77, 8, 4             @ F#8
	N	79, 8, 6             @ G#8
	N	77, 8, 4             @ F#8
	N	76, 8, 4             @ F8
	N	77, 8, 12            @ F#8
	PAT_END
pat_08024480:				@ used by s2c2
	N	60, 13, 4            @ C#7
	N	59, 13, 4            @ C7
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	59, 13, 4            @ C7
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	59, 13, 4            @ C7
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	59, 13, 4            @ C7
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	64, 13, 4            @ F7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	64, 13, 4            @ F7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	64, 13, 4            @ F7
	N	58, 13, 4            @ B6
	N	57, 13, 4            @ A#6
	N	58, 13, 4            @ B6
	N	64, 13, 4            @ F7
	N	57, 13, 4            @ A#6
	N	55, 13, 4            @ G#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	55, 13, 4            @ G#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	55, 13, 4            @ G#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	55, 13, 4            @ G#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	PAT_END
pat_08024541:				@ used by s2c2
	N	50, 13, 4            @ D#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	62, 13, 4            @ D#7
	N	65, 13, 4            @ F#7
	N	62, 13, 4            @ D#7
	N	57, 13, 4            @ A#6
	N	62, 13, 4            @ D#7
	N	50, 13, 4            @ D#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	62, 13, 4            @ D#7
	N	65, 13, 4            @ F#7
	N	62, 13, 4            @ D#7
	N	57, 13, 4            @ A#6
	N	53, 13, 4            @ F#6
	N	55, 13, 4            @ G#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	67, 13, 4            @ G#7
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	55, 13, 4            @ G#6
	N	58, 13, 4            @ B6
	N	50, 13, 4            @ D#6
	N	55, 13, 4            @ G#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	67, 13, 4            @ G#7
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	55, 13, 4            @ G#6
	N	48, 13, 4            @ C#6
	N	52, 13, 4            @ F6
	N	55, 13, 4            @ G#6
	N	60, 13, 4            @ C#7
	N	64, 13, 4            @ F7
	N	55, 13, 4            @ G#6
	N	60, 13, 4            @ C#7
	N	64, 13, 4            @ F7
	N	67, 13, 4            @ G#7
	N	64, 13, 4            @ F7
	N	60, 13, 4            @ C#7
	N	55, 13, 4            @ G#6
	N	52, 13, 4            @ F6
	N	55, 13, 4            @ G#6
	N	60, 13, 4            @ C#7
	N	55, 13, 4            @ G#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	69, 13, 4            @ A#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	64, 13, 4            @ F7
	N	60, 13, 4            @ C#7
	N	50, 13, 4            @ D#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	62, 13, 4            @ D#7
	N	65, 13, 4            @ F#7
	N	62, 13, 4            @ D#7
	N	57, 13, 4            @ A#6
	N	62, 13, 4            @ D#7
	N	50, 13, 4            @ D#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	62, 13, 4            @ D#7
	N	65, 13, 4            @ F#7
	N	62, 13, 4            @ D#7
	N	57, 13, 4            @ A#6
	N	53, 13, 4            @ F#6
	N	55, 13, 4            @ G#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	67, 13, 4            @ G#7
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	55, 13, 4            @ G#6
	N	58, 13, 4            @ B6
	N	50, 13, 4            @ D#6
	N	55, 13, 4            @ G#6
	N	58, 13, 4            @ B6
	N	62, 13, 4            @ D#7
	N	67, 13, 4            @ G#7
	N	62, 13, 4            @ D#7
	N	58, 13, 4            @ B6
	N	55, 13, 4            @ G#6
	N	48, 13, 4            @ C#6
	N	52, 13, 4            @ F6
	N	55, 13, 4            @ G#6
	N	60, 13, 4            @ C#7
	N	64, 13, 4            @ F7
	N	60, 13, 4            @ C#7
	N	55, 13, 4            @ G#6
	N	60, 13, 4            @ C#7
	N	52, 13, 4            @ F6
	N	55, 13, 4            @ G#6
	N	60, 13, 4            @ C#7
	N	64, 13, 4            @ F7
	N	67, 13, 4            @ G#7
	N	64, 13, 4            @ F7
	N	60, 13, 4            @ C#7
	N	55, 13, 4            @ G#6
	N	53, 13, 4            @ F#6
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	65, 13, 4            @ F#7
	N	53, 13, 4            @ F#6
	N	69, 13, 4            @ A#7
	N	65, 13, 4            @ F#7
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	60, 13, 4            @ C#7
	N	57, 13, 4            @ A#6
	N	53, 13, 4            @ F#6
	PAT_END
pat_080246C2:				@ used by s2c3
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 8            @ F#5
	PAT_END
pat_08024720:				@ used by s2c3
	N	38, 12, 7            @ D#5
	N	38, 12, 4            @ D#5
	N	38, 12, 6            @ D#5
	N	33, 12, 6            @ A#4
	N	38, 12, 4            @ D#5
	N	38, 12, 6            @ D#5
	N	38, 12, 4            @ D#5
	N	41, 12, 4            @ F#5
	N	38, 12, 4            @ D#5
	N	33, 12, 6            @ A#4
	N	31, 12, 7            @ G#4
	N	31, 12, 4            @ G#4
	N	38, 12, 6            @ D#5
	N	38, 12, 6            @ D#5
	N	43, 12, 6            @ G#5
	N	41, 12, 6            @ F#5
	N	40, 12, 6            @ F5
	N	38, 12, 6            @ D#5
	N	36, 12, 7            @ C#5
	N	36, 12, 4            @ C#5
	N	36, 12, 6            @ C#5
	N	31, 12, 6            @ G#4
	N	36, 12, 4            @ C#5
	N	36, 12, 6            @ C#5
	N	40, 12, 4            @ F5
	N	43, 12, 6            @ G#5
	N	40, 12, 6            @ F5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	41, 12, 6            @ F#5
	N	36, 12, 6            @ C#5
	N	29, 12, 4            @ F#4
	N	29, 12, 6            @ F#4
	N	36, 12, 4            @ C#5
	N	41, 12, 6            @ F#5
	N	36, 12, 6            @ C#5
	N	38, 12, 7            @ D#5
	N	38, 12, 4            @ D#5
	N	38, 12, 6            @ D#5
	N	33, 12, 6            @ A#4
	N	38, 12, 4            @ D#5
	N	38, 12, 6            @ D#5
	N	38, 12, 4            @ D#5
	N	41, 12, 4            @ F#5
	N	38, 12, 4            @ D#5
	N	33, 12, 6            @ A#4
	N	31, 12, 7            @ G#4
	N	31, 12, 4            @ G#4
	N	31, 12, 6            @ G#4
	N	34, 12, 4            @ B4
	N	38, 12, 4            @ D#5
	N	31, 12, 7            @ G#4
	N	31, 12, 4            @ G#4
	N	38, 12, 6            @ D#5
	N	43, 12, 6            @ G#5
	N	36, 12, 4            @ C#5
	N	36, 12, 6            @ C#5
	N	31, 12, 4            @ G#4
	N	36, 12, 6            @ C#5
	N	40, 12, 6            @ F5
	N	36, 12, 4            @ C#5
	N	36, 12, 6            @ C#5
	N	36, 12, 4            @ C#5
	N	40, 12, 6            @ F5
	N	43, 12, 6            @ G#5
	N	41, 12, 7            @ F#5
	N	41, 12, 4            @ F#5
	N	36, 12, 6            @ C#5
	N	33, 12, 6            @ A#4
	N	29, 12, 4            @ F#4
	N	29, 12, 6            @ F#4
	N	29, 12, 4            @ F#4
	N	33, 12, 6            @ A#4
	N	36, 12, 6            @ C#5
	PAT_END
pat_080247FF:				@ used by s2c4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	34, 5, 4             @ B4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	34, 5, 4             @ B4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	34, 5, 4             @ B4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	26, 2, 4             @ D#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	30, 3, 4             @ G4
	N	24, 1, 4             @ C#4
	N	24, 1, 4             @ C#4
	N	26, 2, 4             @ D#4
	PAT_END
pat_080248C0:				@ used by s3c1
	N	64, 8, 6             @ F7
	N	72, 8, 14            @ C#8
	N	71, 8, 13            @ C8
	N	72, 8, 6             @ C#8
	N	74, 8, 6             @ D#8
	N	76, 8, 13            @ F8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 14            @ D#8
	N	76, 8, 13            @ F8
	N	72, 8, 6             @ C#8
	N	71, 8, 6             @ C8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	69, 8, 13            @ A#7
	N	71, 8, 13            @ C8
	N	69, 8, 13            @ A#7
	N	67, 8, 13            @ G#7
	N	69, 8, 13            @ A#7
	N	67, 8, 13            @ G#7
	N	65, 8, 13            @ F#7
	N	67, 8, 13            @ G#7
	N	65, 8, 13            @ F#7
	N	64, 8, 13            @ F7
	N	65, 8, 13            @ F#7
	N	64, 8, 13            @ F7
	N	62, 8, 13            @ D#7
	N	62, 8, 15            @ D#7
	N	64, 8, 13            @ F7
	N	65, 8, 13            @ F#7
	N	69, 8, 15            @ A#7
	N	74, 8, 13            @ D#8
	N	76, 8, 13            @ F8
	N	77, 8, 15            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	79, 8, 6             @ G#8
	N	74, 8, 13            @ D#8
	N	79, 8, 13            @ G#8
	N	74, 8, 13            @ D#8
	N	71, 8, 13            @ C8
	N	74, 8, 13            @ D#8
	N	71, 8, 13            @ C8
	N	67, 8, 6             @ G#7
	N	68, 8, 6             @ A7
	N	64, 8, 13            @ F7
	N	68, 8, 13            @ A7
	N	71, 8, 13            @ C8
	N	76, 8, 15            @ F8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	69, 8, 7             @ A#7
	REST	0, 1
	N	76, 8, 14            @ F8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	69, 8, 13            @ A#7
	N	71, 8, 13            @ C8
	N	72, 8, 13            @ C#8
	N	76, 8, 14            @ F8
	N	81, 8, 14            @ A#8
	N	83, 8, 13            @ C9
	N	84, 8, 13            @ C#9
	N	84, 8, 13            @ C#9
	N	83, 8, 13            @ C9
	N	81, 8, 13            @ A#8
	N	83, 8, 13            @ C9
	N	81, 8, 13            @ A#8
	N	79, 8, 13            @ G#8
	N	81, 8, 13            @ A#8
	N	79, 8, 13            @ G#8
	N	77, 8, 13            @ F#8
	N	79, 8, 13            @ G#8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	77, 8, 13            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	74, 8, 13            @ D#8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	72, 8, 13            @ C#8
	N	71, 8, 13            @ C8
	N	69, 8, 13            @ A#7
	N	69, 8, 15            @ A#7
	N	67, 8, 13            @ G#7
	N	69, 8, 13            @ A#7
	N	65, 8, 15            @ F#7
	N	64, 8, 13            @ F7
	N	65, 8, 13            @ F#7
	N	62, 8, 13            @ D#7
	N	64, 8, 13            @ F7
	N	65, 8, 13            @ F#7
	N	69, 8, 13            @ A#7
	N	74, 8, 13            @ D#8
	N	76, 8, 13            @ F8
	N	77, 8, 15            @ F#8
	N	76, 8, 13            @ F8
	N	74, 8, 13            @ D#8
	N	79, 8, 13            @ G#8
	N	74, 8, 13            @ D#8
	N	71, 8, 13            @ C8
	N	74, 8, 13            @ D#8
	N	71, 8, 13            @ C8
	N	67, 8, 13            @ G#7
	N	71, 8, 13            @ C8
	N	67, 8, 13            @ G#7
	N	62, 8, 13            @ D#7
	N	67, 8, 13            @ G#7
	N	71, 8, 13            @ C8
	N	67, 8, 13            @ G#7
	N	64, 8, 15            @ F7
	N	68, 8, 13            @ A7
	N	71, 8, 13            @ C8
	N	76, 8, 8             @ F8
	PAT_END
pat_08024A62:				@ used by s3c2
	N	64, 13, 13           @ F7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	63, 13, 13           @ E7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	64, 13, 13           @ F7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	69, 13, 13           @ A#7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	64, 13, 13           @ F7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	63, 13, 13           @ E7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	64, 13, 13           @ F7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	69, 13, 13           @ A#7
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	60, 13, 13           @ C#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	59, 13, 13           @ C7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	65, 13, 13           @ F#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	59, 13, 13           @ C7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	60, 13, 13           @ C#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	65, 13, 13           @ F#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	62, 13, 13           @ D#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	61, 13, 13           @ D7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	62, 13, 13           @ D#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	65, 13, 13           @ F#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	62, 13, 13           @ D#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	61, 13, 13           @ D7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	62, 13, 13           @ D#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	65, 13, 13           @ F#7
	N	53, 13, 13           @ F#6
	N	57, 13, 13           @ A#6
	N	62, 13, 13           @ D#7
	N	55, 13, 13           @ G#6
	N	59, 13, 13           @ C7
	N	61, 13, 13           @ D7
	N	55, 13, 13           @ G#6
	N	59, 13, 13           @ C7
	N	62, 13, 13           @ D#7
	N	55, 13, 13           @ G#6
	N	59, 13, 13           @ C7
	N	67, 13, 13           @ G#7
	N	55, 13, 13           @ G#6
	N	59, 13, 13           @ C7
	N	59, 13, 13           @ C7
	N	52, 13, 13           @ F6
	N	56, 13, 13           @ A6
	N	58, 13, 13           @ B6
	N	52, 13, 13           @ F6
	N	56, 13, 13           @ A6
	N	59, 13, 13           @ C7
	N	52, 13, 13           @ F6
	N	56, 13, 13           @ A6
	N	64, 13, 13           @ F7
	N	52, 13, 13           @ F6
	N	56, 13, 13           @ A6
	PAT_END
pat_08024B83:				@ used by s3c3
	N	33, 12, 14           @ A#4
	N	33, 12, 13           @ A#4
	N	33, 12, 13           @ A#4
	N	31, 12, 13           @ G#4
	N	33, 12, 13           @ A#4
	N	36, 12, 14           @ C#5
	N	36, 12, 6            @ C#5
	N	36, 12, 13           @ C#5
	N	33, 12, 14           @ A#4
	N	33, 12, 13           @ A#4
	N	33, 12, 13           @ A#4
	N	31, 12, 13           @ G#4
	N	28, 12, 13           @ F4
	N	33, 12, 14           @ A#4
	N	33, 12, 13           @ A#4
	N	36, 12, 14           @ C#5
	N	33, 12, 13           @ A#4
	N	41, 12, 14           @ F#5
	N	41, 12, 13           @ F#5
	N	41, 12, 13           @ F#5
	N	40, 12, 13           @ F5
	N	41, 12, 13           @ F#5
	N	36, 12, 14           @ C#5
	N	36, 12, 13           @ C#5
	N	33, 12, 14           @ A#4
	N	33, 12, 13           @ A#4
	N	29, 12, 14           @ F#4
	N	29, 12, 13           @ F#4
	N	29, 12, 13           @ F#4
	N	31, 12, 13           @ G#4
	N	33, 12, 13           @ A#4
	N	36, 12, 14           @ C#5
	N	36, 12, 13           @ C#5
	N	36, 12, 14           @ C#5
	N	33, 12, 13           @ A#4
	N	38, 12, 14           @ D#5
	N	38, 12, 13           @ D#5
	N	38, 12, 13           @ D#5
	N	36, 12, 13           @ C#5
	N	33, 12, 13           @ A#4
	N	38, 12, 14           @ D#5
	N	38, 12, 14           @ D#5
	N	33, 12, 13           @ A#4
	N	36, 12, 13           @ C#5
	N	38, 12, 14           @ D#5
	N	38, 12, 13           @ D#5
	N	41, 12, 14           @ F#5
	N	41, 12, 13           @ F#5
	N	38, 12, 14           @ D#5
	N	38, 12, 13           @ D#5
	N	41, 12, 14           @ F#5
	N	41, 12, 13           @ F#5
	N	43, 12, 14           @ G#5
	N	43, 12, 13           @ G#5
	N	38, 12, 13           @ D#5
	N	35, 12, 13           @ C5
	N	38, 12, 13           @ D#5
	N	31, 12, 14           @ G#4
	N	31, 12, 13           @ G#4
	N	31, 12, 13           @ G#4
	N	33, 12, 13           @ A#4
	N	35, 12, 13           @ C5
	N	40, 12, 14           @ F5
	N	40, 12, 13           @ F5
	N	40, 12, 13           @ F5
	N	38, 12, 13           @ D#5
	N	40, 12, 13           @ F5
	N	40, 12, 14           @ F5
	N	38, 12, 13           @ D#5
	N	36, 12, 14           @ C#5
	N	35, 12, 13           @ C5
	PAT_END
pat_08024C59:				@ used by s3c4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	N	30, 3, 13            @ G4
	N	34, 5, 13            @ B4
	PAT_END
pat_08024CEA:				@ used by s4c1
	N	41, 22, 4            @ F#5
	N	41, 22, 4            @ F#5
	N	41, 22, 4            @ F#5
	N	41, 22, 6            @ F#5
	N	41, 22, 6            @ F#5
	N	41, 22, 4            @ F#5
	N	38, 22, 4            @ D#5
	N	38, 22, 4            @ D#5
	N	38, 22, 4            @ D#5
	N	38, 22, 6            @ D#5
	N	38, 22, 6            @ D#5
	N	38, 22, 4            @ D#5
	N	41, 22, 4            @ F#5
	N	41, 22, 4            @ F#5
	N	41, 22, 4            @ F#5
	N	41, 22, 6            @ F#5
	N	41, 22, 6            @ F#5
	N	41, 22, 4            @ F#5
	N	45, 22, 4            @ A#5
	N	45, 22, 4            @ A#5
	N	45, 22, 4            @ A#5
	N	45, 22, 6            @ A#5
	N	45, 22, 6            @ A#5
	N	45, 22, 4            @ A#5
	PAT_END
pat_08024D33:				@ used by s4c1
	N	45, 9, 6             @ A#5
	N	46, 9, 6             @ B5
	N	45, 9, 6             @ A#5
	N	46, 9, 6             @ B5
	N	45, 9, 6             @ A#5
	N	46, 9, 6             @ B5
	N	45, 9, 6             @ A#5
	N	46, 9, 6             @ B5
	N	46, 9, 6             @ B5
	N	48, 9, 6             @ C#6
	N	46, 9, 6             @ B5
	N	48, 9, 6             @ C#6
	N	46, 9, 6             @ B5
	N	48, 9, 6             @ C#6
	N	46, 9, 6             @ B5
	N	48, 9, 6             @ C#6
	N	50, 9, 6             @ D#6
	N	52, 9, 6             @ F6
	N	50, 9, 6             @ D#6
	N	52, 9, 6             @ F6
	N	50, 9, 6             @ D#6
	N	52, 9, 6             @ F6
	N	50, 9, 6             @ D#6
	N	52, 9, 6             @ F6
	N	52, 9, 6             @ F6
	N	53, 9, 6             @ F#6
	N	52, 9, 6             @ F6
	N	53, 9, 6             @ F#6
	N	52, 9, 6             @ F6
	N	53, 9, 6             @ F#6
	N	53, 9, 6             @ F#6
	N	52, 9, 6             @ F6
	PAT_END
pat_08024D94:				@ used by s4c1
	N	57, 9, 8             @ A#6
	N	59, 9, 6             @ C7
	N	60, 9, 6             @ C#7
	N	65, 9, 8             @ F#7
	N	64, 9, 8             @ F7
	N	62, 9, 6             @ D#7
	N	61, 9, 6             @ D7
	N	62, 9, 6             @ D#7
	N	58, 9, 6             @ B6
	N	53, 9, 8             @ F#6
	N	65, 9, 8             @ F#7
	N	64, 9, 8             @ F7
	N	69, 9, 6             @ A#7
	N	71, 9, 6             @ C8
	N	72, 9, 6             @ C#8
	N	75, 9, 6             @ E8
	N	76, 9, 8             @ F8
	N	77, 9, 8             @ F#8
	N	73, 9, 6             @ D8
	N	70, 9, 6             @ B7
	N	65, 9, 6             @ F#7
	N	61, 9, 6             @ D7
	N	58, 9, 8             @ B6
	PAT_END
pat_08024DDA:				@ used by s4c1
	N	48, 9, 7             @ C#6
	N	51, 9, 2             @ E6
	N	55, 9, 2             @ G#6
	N	60, 9, 6             @ C#7
	N	59, 9, 4             @ C7
	N	58, 9, 4             @ B6
	N	57, 9, 10            @ A#6
	N	55, 9, 7             @ G#6
	N	60, 9, 2             @ C#7
	N	63, 9, 2             @ E7
	N	67, 9, 6             @ G#7
	N	66, 9, 4             @ G7
	N	65, 9, 4             @ F#7
	N	64, 9, 10            @ F7
	N	63, 9, 6             @ E7
	N	60, 9, 6             @ C#7
	N	55, 9, 6             @ G#6
	N	51, 9, 6             @ E6
	N	52, 9, 7             @ F6
	N	57, 9, 2             @ A#6
	N	60, 9, 2             @ C#7
	N	64, 9, 8             @ F7
	N	63, 9, 6             @ E7
	N	60, 9, 6             @ C#7
	N	55, 9, 6             @ G#6
	N	51, 9, 6             @ E6
	N	64, 9, 4             @ F7
	N	59, 9, 4             @ C7
	N	55, 9, 4             @ G#6
	N	59, 9, 4             @ C7
	N	52, 9, 8             @ F6
	PAT_END
pat_08024E38:				@ used by s4c1
	N	60, 9, 9             @ C#7
	REST	0, 2
	N	65, 9, 2             @ F#7
	N	68, 9, 2             @ A7
	N	72, 9, 2             @ C#8
	N	77, 9, 8             @ F#8
	N	72, 9, 8             @ C#8
	N	71, 9, 12            @ C8
	N	58, 9, 9             @ B6
	REST	0, 4
	N	64, 9, 2             @ F7
	N	67, 9, 2             @ G#7
	N	72, 9, 8             @ C#8
	N	70, 9, 8             @ B7
	N	69, 9, 12            @ A#7
	PAT_END
pat_08024E66:				@ used by s4c1
	N	70, 9, 7             @ B7
	N	69, 9, 7             @ A#7
	N	67, 9, 6             @ G#7
	N	64, 9, 7             @ F7
	N	65, 9, 7             @ F#7
	N	67, 9, 6             @ G#7
	N	69, 9, 12            @ A#7
	N	72, 9, 7             @ C#8
	N	71, 9, 7             @ C8
	N	69, 9, 6             @ A#7
	N	69, 9, 7             @ A#7
	N	68, 9, 7             @ A7
	N	69, 9, 6             @ A#7
	N	71, 9, 4             @ C8
	N	68, 9, 4             @ A7
	N	64, 9, 11            @ F7
	REST	0, 6
	PAT_END
pat_08024E9A:				@ used by s4c2
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	70, 15, 2            @ B7
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	70, 15, 2            @ B7
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	70, 15, 2            @ B7
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	70, 15, 2            @ B7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	73, 15, 2            @ D8
	N	70, 15, 2            @ B7
	N	73, 15, 2            @ D8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	73, 15, 2            @ D8
	N	70, 15, 2            @ B7
	N	73, 15, 2            @ D8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	73, 15, 2            @ D8
	N	70, 15, 2            @ B7
	N	73, 15, 2            @ D8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	79, 15, 2            @ G#8
	N	77, 15, 2            @ F#8
	N	73, 15, 2            @ D8
	N	70, 15, 2            @ B7
	N	73, 15, 2            @ D8
	PAT_END
pat_0802501B:				@ used by s4c2
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	68, 15, 2            @ A7
	N	65, 15, 2            @ F#7
	N	68, 15, 2            @ A7
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	68, 15, 2            @ A7
	N	65, 15, 2            @ F#7
	N	68, 15, 2            @ A7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	65, 15, 2            @ F#7
	N	69, 15, 2            @ A#7
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	76, 15, 2            @ F8
	N	74, 15, 2            @ D#8
	N	69, 15, 2            @ A#7
	N	65, 15, 2            @ F#7
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	68, 15, 2            @ A7
	N	65, 15, 2            @ F#7
	N	68, 15, 2            @ A7
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	73, 15, 2            @ D8
	N	72, 15, 2            @ C#8
	N	68, 15, 2            @ A7
	N	65, 15, 2            @ F#7
	N	68, 15, 2            @ A7
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	77, 15, 2            @ F#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	69, 15, 2            @ A#7
	N	72, 15, 2            @ C#8
	PAT_END
pat_080250DC:				@ used by s4c2
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	82, 15, 2            @ B8
	N	80, 15, 2            @ A8
	N	77, 15, 2            @ F#8
	N	72, 15, 2            @ C#8
	N	77, 15, 2            @ F#8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	PAT_END
pat_0802525D:				@ used by s4c2
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	84, 15, 2            @ C#9
	N	82, 15, 2            @ B8
	N	79, 15, 2            @ G#8
	N	74, 15, 2            @ D#8
	N	79, 15, 2            @ G#8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	81, 15, 2            @ A#8
	N	79, 15, 2            @ G#8
	N	76, 15, 2            @ F8
	N	72, 15, 2            @ C#8
	N	76, 15, 2            @ F8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	82, 15, 2            @ B8
	N	81, 15, 2            @ A#8
	N	78, 15, 2            @ G8
	N	74, 15, 2            @ D#8
	N	78, 15, 2            @ G8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	78, 15, 2            @ G8
	N	75, 15, 2            @ E8
	N	78, 15, 2            @ G8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	78, 15, 2            @ G8
	N	75, 15, 2            @ E8
	N	78, 15, 2            @ G8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	78, 15, 2            @ G8
	N	75, 15, 2            @ E8
	N	78, 15, 2            @ G8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	78, 15, 2            @ G8
	N	75, 15, 2            @ E8
	N	78, 15, 2            @ G8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	80, 15, 2            @ A8
	N	76, 15, 2            @ F8
	N	80, 15, 2            @ A8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	80, 15, 2            @ A8
	N	76, 15, 2            @ F8
	N	80, 15, 2            @ A8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	80, 15, 2            @ A8
	N	76, 15, 2            @ F8
	N	80, 15, 2            @ A8
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	84, 15, 2            @ C#9
	N	83, 15, 2            @ C9
	N	80, 15, 2            @ A8
	N	76, 15, 2            @ F8
	N	80, 15, 2            @ A8
	PAT_END
pat_080253DE:				@ used by s4c3
	N	33, 14, 6            @ A#4
	N	40, 14, 6            @ F5
	N	45, 14, 6            @ A#5
	N	40, 14, 4            @ F5
	N	33, 14, 6            @ A#4
	N	33, 14, 4            @ A#4
	N	40, 14, 4            @ F5
	N	45, 14, 6            @ A#5
	N	40, 14, 4            @ F5
	N	33, 14, 4            @ A#4
	N	40, 14, 4            @ F5
	N	34, 14, 6            @ B4
	N	41, 14, 6            @ F#5
	N	46, 14, 6            @ B5
	N	41, 14, 4            @ F#5
	N	34, 14, 6            @ B4
	N	34, 14, 4            @ B4
	N	41, 14, 4            @ F#5
	N	46, 14, 6            @ B5
	N	41, 14, 4            @ F#5
	N	46, 14, 4            @ B5
	N	41, 14, 4            @ F#5
	N	33, 14, 6            @ A#4
	N	40, 14, 4            @ F5
	N	45, 14, 6            @ A#5
	N	40, 14, 4            @ F5
	N	45, 14, 4            @ A#5
	N	40, 14, 4            @ F5
	N	33, 14, 6            @ A#4
	N	40, 14, 6            @ F5
	N	45, 14, 4            @ A#5
	N	33, 14, 4            @ A#4
	N	40, 14, 4            @ F5
	N	45, 14, 4            @ A#5
	N	34, 14, 6            @ B4
	N	41, 14, 6            @ F#5
	N	46, 14, 6            @ B5
	N	41, 14, 4            @ F#5
	N	34, 14, 6            @ B4
	N	46, 14, 4            @ B5
	N	41, 14, 4            @ F#5
	N	34, 14, 6            @ B4
	N	46, 14, 4            @ B5
	N	41, 14, 4            @ F#5
	N	34, 14, 4            @ B4
	PAT_END
pat_08025466:				@ used by s4c3
	N	29, 14, 6            @ F#4
	N	36, 14, 6            @ C#5
	N	41, 14, 6            @ F#5
	N	36, 14, 7            @ C#5
	N	38, 14, 6            @ D#5
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	33, 14, 4            @ A#4
	N	38, 14, 4            @ D#5
	N	29, 14, 6            @ F#4
	N	36, 14, 6            @ C#5
	N	41, 14, 6            @ F#5
	N	36, 14, 7            @ C#5
	N	33, 14, 4            @ A#4
	N	36, 14, 4            @ C#5
	N	40, 14, 6            @ F5
	N	33, 14, 4            @ A#4
	N	36, 14, 4            @ C#5
	N	40, 14, 4            @ F5
	PAT_END
pat_080254A0:				@ used by s4c3
	N	41, 14, 6            @ F#5
	N	36, 14, 6            @ C#5
	N	41, 14, 6            @ F#5
	N	36, 14, 7            @ C#5
	N	38, 14, 6            @ D#5
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	33, 14, 4            @ A#4
	N	38, 14, 4            @ D#5
	N	41, 14, 6            @ F#5
	N	36, 14, 6            @ C#5
	N	41, 14, 6            @ F#5
	N	36, 14, 7            @ C#5
	N	33, 14, 4            @ A#4
	N	36, 14, 4            @ C#5
	N	40, 14, 6            @ F5
	N	33, 14, 4            @ A#4
	N	36, 14, 4            @ C#5
	N	40, 14, 4            @ F5
	PAT_END
pat_080254DA:				@ used by s4c3
	N	29, 14, 6            @ F#4
	N	36, 14, 6            @ C#5
	N	41, 14, 4            @ F#5
	N	36, 14, 6            @ C#5
	N	29, 14, 6            @ F#4
	N	29, 14, 4            @ F#4
	N	36, 14, 4            @ C#5
	N	41, 14, 6            @ F#5
	N	29, 14, 4            @ F#4
	N	36, 14, 4            @ C#5
	N	41, 14, 4            @ F#5
	N	43, 14, 6            @ G#5
	N	38, 14, 6            @ D#5
	N	35, 14, 4            @ C5
	N	38, 14, 6            @ D#5
	N	31, 14, 6            @ G#4
	N	31, 14, 4            @ G#4
	N	38, 14, 4            @ D#5
	N	43, 14, 6            @ G#5
	N	38, 14, 4            @ D#5
	N	43, 14, 4            @ G#5
	N	38, 14, 4            @ D#5
	N	31, 14, 6            @ G#4
	N	31, 14, 6            @ G#4
	N	34, 14, 4            @ B4
	N	31, 14, 4            @ G#4
	N	34, 14, 4            @ B4
	N	36, 14, 6            @ C#5
	N	36, 14, 6            @ C#5
	N	40, 14, 6            @ F5
	N	43, 14, 4            @ G#5
	N	40, 14, 4            @ F5
	N	36, 14, 4            @ C#5
	N	38, 14, 6            @ D#5
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	33, 14, 6            @ A#4
	N	38, 14, 6            @ D#5
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	42, 14, 4            @ G5
	N	45, 14, 4            @ A#5
	N	42, 14, 4            @ G5
	N	38, 14, 4            @ D#5
	PAT_END
pat_0802555F:				@ used by s4c3
	N	31, 14, 6            @ G#4
	N	38, 14, 6            @ D#5
	N	43, 14, 4            @ G#5
	N	38, 14, 6            @ D#5
	N	36, 14, 6            @ C#5
	N	36, 14, 6            @ C#5
	N	40, 14, 6            @ F5
	N	43, 14, 4            @ G#5
	N	40, 14, 4            @ F5
	N	36, 14, 4            @ C#5
	N	38, 14, 6            @ D#5
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	33, 14, 6            @ A#4
	N	38, 14, 6            @ D#5
	N	38, 14, 4            @ D#5
	N	42, 14, 4            @ G5
	N	45, 14, 6            @ A#5
	N	38, 14, 4            @ D#5
	N	42, 14, 4            @ G5
	N	45, 14, 4            @ A#5
	N	39, 14, 6            @ E5
	N	39, 14, 6            @ E5
	N	39, 14, 4            @ E5
	N	39, 14, 6            @ E5
	N	39, 14, 4            @ E5
	N	35, 14, 4            @ C5
	N	35, 14, 6            @ C5
	N	35, 14, 4            @ C5
	N	39, 14, 4            @ E5
	N	42, 14, 4            @ G5
	N	47, 14, 4            @ C6
	N	42, 14, 4            @ G5
	N	40, 14, 6            @ F5
	N	40, 14, 6            @ F5
	N	40, 14, 4            @ F5
	N	35, 14, 6            @ C5
	N	40, 14, 6            @ F5
	N	40, 14, 4            @ F5
	N	38, 14, 4            @ D#5
	N	38, 14, 4            @ D#5
	N	36, 14, 4            @ C#5
	N	36, 14, 4            @ C#5
	N	35, 14, 4            @ C5
	N	35, 14, 4            @ C5
	PAT_END
pat_080255E7:				@ used by s4c4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 6             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 6             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 6             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 6             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 2             @ C#4
	N	24, 6, 4             @ C#4
	N	24, 6, 4             @ C#4
	PAT_END
	.byte	0x00, 0x00	@ padding

@ ----------------------------------------------------------------------------
@ sequences (order lists), one per song channel
@ ----------------------------------------------------------------------------
seq_s00_c0:				@ 080256E0 song 0 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 255			@ 255/256 ticks per frame
	SEQ_PAT	pat_0801B2C0, 0, 1
	SEQ_CONDFLAG 1
	SEQ_END
seq_s00_c1:				@ 0802570C song 0 channel 2
	SEQ_PAT	pat_0801B2C0, 0, 1
	SEQ_END
seq_s00_c2:				@ 08025720 song 0 channel 3
	SEQ_PAT	pat_0801B2C0, 0, 1
	SEQ_END
seq_s00_c3:				@ 08025734 song 0 channel 4
	SEQ_PAT	pat_0801B2C0, 0, 1
	SEQ_END
seq_s01_c0:				@ 08025748 song 1 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 205			@ 205/256 ticks per frame
	SEQ_PAT	pat_08023B06, -30, 1
	SEQ_PAT	pat_08023B94, -42, 1
	SEQ_PAT	pat_08023B06, -30, 1
	SEQ_PAT	pat_08023B94, -42, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s01_c1:				@ 080257A8 song 1 channel 2
	SEQ_PAT	pat_08023C52, -30, 1
	SEQ_PAT	pat_08023D73, -42, 1
	SEQ_PAT	pat_08023C52, -30, 1
	SEQ_PAT	pat_08023E31, -30, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s01_c2:				@ 080257F0 song 1 channel 3
	SEQ_PAT	pat_08024072, -18, 1
	SEQ_PAT	pat_0802413C, -18, 1
	SEQ_PAT	pat_08024072, -18, 1
	SEQ_PAT	pat_080241C4, -18, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s01_c3:				@ 08025838 song 1 channel 4
	SEQ_PAT	pat_080242AC, 0, 8
	SEQ_END
	SEQ_JUMP 0			@ (unreachable: follows SEQ_END)
seq_s02_c0:				@ 08025854 song 2 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 205			@ 205/256 ticks per frame
	SEQ_PAT	pat_0802435E, -41, 1
	SEQ_PAT	pat_080243D7, -41, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s02_c1:				@ 08025894 song 2 channel 2
	SEQ_PAT	pat_08024480, -17, 2
	SEQ_PAT	pat_08024541, -17, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s02_c2:				@ 080258BC song 2 channel 3
	SEQ_PAT	pat_080246C2, -17, 2
	SEQ_PAT	pat_08024720, -17, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s02_c3:				@ 080258E4 song 2 channel 4
	SEQ_PAT	pat_080247FF, 0, 4
	SEQ_JUMP 0			@ -> word index 0
seq_s03_c0:				@ 080258FC song 3 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 180			@ 180/256 ticks per frame
	SEQ_PAT	pat_080248C0, -40, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s03_c1:				@ 0802592C song 3 channel 2
	SEQ_PAT	pat_08024A62, -16, 2
	SEQ_JUMP 0			@ -> word index 0
seq_s03_c2:				@ 08025944 song 3 channel 3
	SEQ_PAT	pat_08024B83, -16, 2
	SEQ_JUMP 0			@ -> word index 0
seq_s03_c3:				@ 0802595C song 3 channel 4
	SEQ_PAT	pat_08024C59, 0, 4
	SEQ_JUMP 0			@ -> word index 0
seq_s04_c0:				@ 08025974 song 4 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 195			@ 195/256 ticks per frame
	SEQ_PAT	pat_08024D33, -20, 1
	SEQ_PAT	pat_08024D94, -32, 2
	SEQ_PAT	pat_08024CEA, -8, 2
	SEQ_PAT	pat_08024DDA, -32, 1
	SEQ_PAT	pat_08024DDA, -20, 1
	SEQ_PAT	pat_08024D94, -32, 2
	SEQ_PAT	pat_08024E38, -32, 1
	SEQ_PAT	pat_08024E66, -32, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s04_c1:				@ 08025A14 song 4 channel 2
	SEQ_PAT	pat_08024E9A, -20, 3
	SEQ_PAT	pat_0802501B, -20, 2
	SEQ_PAT	pat_0802501B, -25, 4
	SEQ_PAT	pat_08024E9A, -20, 2
	SEQ_PAT	pat_080250DC, -32, 1
	SEQ_PAT	pat_0802525D, -32, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s04_c2:				@ 08025A7C song 4 channel 3
	SEQ_PAT	pat_080253DE, -20, 3
	SEQ_PAT	pat_08025466, -20, 2
	SEQ_PAT	pat_080254A0, -25, 4
	SEQ_PAT	pat_080253DE, -20, 2
	SEQ_PAT	pat_080254DA, -20, 1
	SEQ_PAT	pat_0802555F, -20, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s04_c3:				@ 08025AE4 song 4 channel 4
	SEQ_PAT	pat_080255E7, 0, 10
	SEQ_JUMP 0			@ -> word index 0
seq_s05_c0:				@ 08025AFC song 5 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 164			@ 164/256 ticks per frame
	SEQ_PAT	pat_08022944, -30, 1
	SEQ_PAT	pat_08022993, -30, 1
	SEQ_PAT	pat_08022A75, -30, 1
	SEQ_PAT	pat_08022AC4, -30, 1
	SEQ_PAT	pat_08022993, -33, 1
	SEQ_PAT	pat_08022B1C, -30, 1
	SEQ_PAT	pat_08022BCB, -30, 1
	SEQ_PAT	pat_08022AC4, -27, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s05_c1:				@ 08025B9C song 5 channel 2
	SEQ_PAT	pat_08022C95, -30, 1
	SEQ_PAT	pat_08022D9B, -30, 1
	SEQ_PAT	pat_08022FDC, -30, 1
	SEQ_PAT	pat_0802315D, -30, 1
	SEQ_PAT	pat_08022D9B, -33, 1
	SEQ_PAT	pat_080232DE, -30, 1
	SEQ_PAT	pat_0802345F, -30, 1
	SEQ_PAT	pat_0802315D, -27, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s05_c2:				@ 08025C24 song 5 channel 3
	SEQ_PAT	pat_080235E0, -18, 1
	SEQ_PAT	pat_08023650, -18, 1
	SEQ_PAT	pat_08023771, -18, 1
	SEQ_PAT	pat_0802381D, -18, 1
	SEQ_PAT	pat_08023650, -21, 1
	SEQ_PAT	pat_080238B7, -18, 1
	SEQ_PAT	pat_08023984, -18, 1
	SEQ_PAT	pat_0802381D, -15, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s05_c3:				@ 08025CAC song 5 channel 4
	SEQ_PAT	pat_08023A45, 0, 18
	SEQ_JUMP 0			@ -> word index 0
seq_s06_c0:				@ 08025CC4 song 6 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 188			@ 188/256 ticks per frame
	SEQ_PAT	pat_08021CE0, -28, 2
	SEQ_PAT	pat_08021D14, -28, 1
	SEQ_PAT	pat_08021D33, -28, 1
	SEQ_PAT	pat_08021D58, -28, 1
	SEQ_PAT	pat_08021D95, -28, 1
	SEQ_PAT	pat_08021DE7, -28, 1
	SEQ_PAT	pat_08021D58, -26, 1
	SEQ_PAT	pat_08021D95, -26, 1
	SEQ_PAT	pat_08021E78, -28, 2
	SEQ_PAT	pat_08021ED6, -28, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s06_c1:				@ 08025D84 song 6 channel 2
	SEQ_PAT	pat_08021F6D, -28, 2
	SEQ_PAT	pat_08021FB6, -28, 1
	SEQ_PAT	pat_08022047, -28, 1
	SEQ_PAT	pat_080220D8, -28, 1
	SEQ_PAT	pat_08022169, -28, 1
	SEQ_PAT	pat_080221FA, -28, 1
	SEQ_PAT	pat_080220D8, -26, 1
	SEQ_PAT	pat_08022169, -26, 1
	SEQ_PAT	pat_0802231B, -28, 2
	SEQ_PAT	pat_08022364, -28, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s06_c2:				@ 08025E2C song 6 channel 3
	SEQ_PAT	pat_080223F5, -16, 2
	SEQ_PAT	pat_08022417, -16, 1
	SEQ_PAT	pat_080224C6, -16, 1
	SEQ_PAT	pat_08022560, -16, 1
	SEQ_PAT	pat_080225FD, -16, 1
	SEQ_PAT	pat_0802269D, -16, 1
	SEQ_PAT	pat_08022560, -14, 1
	SEQ_PAT	pat_080225FD, -14, 1
	SEQ_PAT	pat_080227E2, -16, 1
	SEQ_PAT	pat_08022885, -16, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s06_c3:				@ 08025ED4 song 6 channel 4
	SEQ_PAT	pat_08022907, 0, 44
	SEQ_JUMP 0			@ -> word index 0
seq_s07_c0:				@ 08025EEC song 7 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 214			@ 214/256 ticks per frame
	SEQ_PAT	pat_08021430, -18, 1
	SEQ_PAT	pat_08021440, -30, 1
	SEQ_PAT	pat_080214A4, -30, 1
	SEQ_PAT	pat_08021547, -30, 1
	SEQ_PAT	pat_08021440, -30, 1
	SEQ_PAT	pat_08021665, -30, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s07_c1:				@ 08025F6C song 7 channel 2
	SEQ_PAT	pat_080216AE, -30, 3
	SEQ_PAT	pat_080216AE, -34, 1
	SEQ_PAT	pat_080216AE, -30, 1
	SEQ_PAT	pat_0802176F, -30, 1
	SEQ_PAT	pat_0802176F, -32, 1
	SEQ_PAT	pat_0802176F, -37, 1
	SEQ_PAT	pat_0802176F, -35, 1
	SEQ_PAT	pat_0802176F, -30, 1
	SEQ_PAT	pat_0802176F, -32, 1
	SEQ_PAT	pat_0802176F, -37, 1
	SEQ_PAT	pat_0802176F, -28, 1
	SEQ_PAT	pat_080216AE, -30, 2
	SEQ_PAT	pat_080217D0, -30, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s07_c2:				@ 08026044 song 7 channel 3
	SEQ_PAT	pat_08021891, -18, 1
	SEQ_PAT	pat_08021910, -18, 2
	SEQ_PAT	pat_08021891, -22, 1
	SEQ_PAT	pat_08021891, -18, 1
	SEQ_PAT	pat_080219A4, -18, 1
	SEQ_PAT	pat_08021910, -18, 2
	SEQ_PAT	pat_08021B7F, -18, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s07_c3:				@ 080260BC song 7 channel 4
	SEQ_PAT	pat_08021C0A, 0, 12
	SEQ_JUMP 0			@ -> word index 0
seq_s08_c0:				@ 080260D4 song 8 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 248			@ 248/256 ticks per frame
	SEQ_PAT	pat_0801B2BC, 0, 6
	SEQ_PAT	pat_08020548, -28, 1
	SEQ_PAT	pat_08020588, -28, 1
	SEQ_PAT	pat_080205D7, -28, 1
	SEQ_PAT	pat_08020588, -28, 1
	SEQ_PAT	pat_080206D1, -28, 1
	SEQ_PAT	pat_080205D7, -28, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s08_c1:				@ 08026164 song 8 channel 2
	SEQ_PAT	pat_08020804, -28, 1
	SEQ_PAT	pat_0802084D, -28, 1
	SEQ_PAT	pat_080208DE, -28, 1
	SEQ_PAT	pat_0802096F, -28, 1
	SEQ_PAT	pat_080208DE, -28, 1
	SEQ_PAT	pat_08020A90, -28, 1
	SEQ_PAT	pat_0802096F, -28, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s08_c2:				@ 080261DC song 8 channel 3
	SEQ_PAT	pat_08020CD1, -16, 1
	SEQ_PAT	pat_08020D32, -16, 1
	SEQ_PAT	pat_08020DF3, -16, 1
	SEQ_PAT	pat_08020EC0, -16, 1
	SEQ_PAT	pat_08020DF3, -16, 1
	SEQ_PAT	pat_0802103B, -16, 1
	SEQ_PAT	pat_08020EC0, -16, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s08_c3:				@ 08026254 song 8 channel 4
	SEQ_PAT	pat_08021384, 0, 1
	SEQ_PAT	pat_0802118C, 0, 1
	SEQ_PAT	pat_08021235, 0, 1
	SEQ_PAT	pat_080212DE, 0, 1
	SEQ_PAT	pat_08021384, 0, 1
	SEQ_PAT	pat_0802118C, 0, 1
	SEQ_PAT	pat_08021235, 0, 1
	SEQ_PAT	pat_080212DE, 0, 1
	SEQ_PAT	pat_08021384, 0, 1
	SEQ_PAT	pat_080212DE, 0, 1
	SEQ_PAT	pat_08021384, 0, 1
	SEQ_PAT	pat_0802118C, 0, 1
	SEQ_PAT	pat_08021235, 0, 1
	SEQ_PAT	pat_080212DE, 0, 1
	SEQ_PAT	pat_08021384, 0, 1
	SEQ_PAT	pat_0802118C, 0, 1
	SEQ_PAT	pat_08021235, 0, 1
	SEQ_PAT	pat_080212DE, 0, 1
	SEQ_PAT	pat_08021384, 0, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s09_c0:				@ 0802638C song 9 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 165			@ 165/256 ticks per frame
	SEQ_PAT	pat_0801F1D8, -30, 2
	SEQ_PAT	pat_0801F260, -30, 1
	SEQ_PAT	pat_0801F3B1, -30, 1
	SEQ_PAT	pat_0801F3B1, -29, 1
	SEQ_PAT	pat_0801F4E7, -29, 1
	SEQ_PAT	pat_0801F680, -30, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s09_c1:				@ 0802640C song 9 channel 2
	SEQ_PAT	pat_0801F6F3, -30, 1
	SEQ_PAT	pat_0801F838, -30, 1
	SEQ_PAT	pat_0801F9C8, -30, 1
	SEQ_PAT	pat_0801F9C8, -29, 1
	SEQ_PAT	pat_0801FB19, -29, 1
	SEQ_PAT	pat_0801FD63, -30, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s09_c2:				@ 08026474 song 9 channel 3
	SEQ_PAT	pat_0801FE24, -18, 2
	SEQ_PAT	pat_0801FEDF, -18, 1
	SEQ_PAT	pat_08020039, -18, 1
	SEQ_PAT	pat_08020109, -17, 1
	SEQ_PAT	pat_080201C4, -17, 1
	SEQ_PAT	pat_080203F0, -18, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s09_c3:				@ 080264DC song 9 channel 4
	SEQ_PAT	pat_08020487, 0, 18
	SEQ_JUMP 0			@ -> word index 0
seq_s10_c0:				@ 080264F4 song 10 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 180			@ 180/256 ticks per frame
	SEQ_PAT	pat_0801DF1A, -31, 1
	SEQ_PAT	pat_0801E00B, -31, 1
	SEQ_PAT	pat_0801E07E, -31, 1
	SEQ_PAT	pat_0801E10C, -31, 1
	SEQ_PAT	pat_0801E1EB, -31, 1
	SEQ_PAT	pat_0801E00B, -33, 1
	SEQ_PAT	pat_0801E07E, -21, 1
	SEQ_PAT	pat_0801E24F, -31, 1
	SEQ_PAT	pat_0801E2B0, -31, 1
	SEQ_PAT	pat_0801E347, -31, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s10_c1:				@ 080265B4 song 10 channel 2
	SEQ_PAT	pat_0801E46E, -31, 3
	SEQ_PAT	pat_0801E5EF, -31, 4
	SEQ_PAT	pat_0801E650, -31, 3
	SEQ_PAT	pat_0801E6B1, -31, 1
	SEQ_PAT	pat_0801E46E, -33, 2
	SEQ_PAT	pat_0801E712, -31, 1
	SEQ_PAT	pat_0801E893, -31, 1
	SEQ_PAT	pat_0801EA14, -31, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s10_c2:				@ 0802663C song 10 channel 3
	SEQ_PAT	pat_0801EB95, -19, 3
	SEQ_PAT	pat_0801EC41, -19, 2
	SEQ_PAT	pat_0801ECBA, -19, 1
	SEQ_PAT	pat_0801EB95, -21, 2
	SEQ_PAT	pat_0801EDB1, -19, 1
	SEQ_PAT	pat_0801EEAE, -19, 1
	SEQ_PAT	pat_0801EF9F, -19, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s10_c3:				@ 080266B4 song 10 channel 4
	SEQ_PAT	pat_0801F08D, 0, 10
	SEQ_JUMP 0			@ -> word index 0
seq_s11_c0:				@ 080266CC song 11 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 189			@ 189/256 ticks per frame
	SEQ_PAT	pat_0801D5D8, -31, 1
	SEQ_PAT	pat_0801D5E5, -31, 1
	SEQ_PAT	pat_0801D691, -31, 1
	SEQ_PAT	pat_0801D785, -31, 1
	SEQ_PAT	pat_0801D987, -31, 1
	SEQ_PAT	pat_0801DBAA, -31, 1
	SEQ_PAT	pat_0801D785, -31, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s11_c1:				@ 0802675C song 11 channel 2
	SEQ_PAT	pat_0801DD58, -31, 5
	SEQ_PAT	pat_0801DD58, -26, 2
	SEQ_PAT	pat_0801DD58, -31, 1
	SEQ_PAT	pat_0801DD58, -24, 1
	SEQ_PAT	pat_0801DD58, -26, 1
	SEQ_PAT	pat_0801DD58, -31, 3
	SEQ_PAT	pat_0801DD58, -35, 1
	SEQ_PAT	pat_0801DD58, -31, 1
	SEQ_PAT	pat_0801DD58, -28, 1
	SEQ_PAT	pat_0801DD58, -31, 2
	SEQ_PAT	pat_0801DD58, -26, 2
	SEQ_PAT	pat_0801DD58, -31, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s11_c2:				@ 08026824 song 11 channel 3
	SEQ_PAT	pat_0801DDC8, -19, 5
	SEQ_PAT	pat_0801DDC8, -14, 2
	SEQ_PAT	pat_0801DDC8, -19, 1
	SEQ_PAT	pat_0801DDC8, -12, 1
	SEQ_PAT	pat_0801DDC8, -14, 1
	SEQ_PAT	pat_0801DDC8, -19, 3
	SEQ_PAT	pat_0801DDC8, -11, 1
	SEQ_PAT	pat_0801DDC8, -19, 1
	SEQ_PAT	pat_0801DDC8, -16, 1
	SEQ_PAT	pat_0801DDC8, -19, 2
	SEQ_PAT	pat_0801DDC8, -14, 2
	SEQ_PAT	pat_0801DDC8, -19, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s11_c3:				@ 080268EC song 11 channel 4
	SEQ_PAT	pat_0801DE5C, 0, 21
	SEQ_JUMP 0			@ -> word index 0
seq_s12_c0:				@ 08026904 song 12 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 214			@ 214/256 ticks per frame
	SEQ_PAT	pat_0801C80D, -32, 1
	SEQ_PAT	pat_0801C889, -32, 1
	SEQ_PAT	pat_0801C94A, -32, 1
	SEQ_PAT	pat_0801C889, -31, 1
	SEQ_PAT	pat_0801C94A, -31, 1
	SEQ_PAT	pat_0801CA08, -31, 1
	SEQ_PAT	pat_0801C889, -28, 1
	SEQ_PAT	pat_0801C94A, -28, 1
	SEQ_PAT	pat_0801CB89, -32, 1
	SEQ_PAT	pat_0801CC65, -32, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s12_c1:				@ 080269C4 song 12 channel 2
	SEQ_PAT	pat_0801CF87, -20, 3
	SEQ_PAT	pat_0801CF87, -19, 2
	SEQ_PAT	pat_0801CEF6, -19, 1
	SEQ_PAT	pat_0801CF87, -16, 2
	SEQ_PAT	pat_0801CEAD, -20, 1
	SEQ_PAT	pat_0801CE22, -20, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s12_c2:				@ 08026A2C song 12 channel 3
	SEQ_PAT	pat_0801CFD0, -20, 3
	SEQ_PAT	pat_0801CFD0, -19, 2
	SEQ_PAT	pat_0801D091, -19, 1
	SEQ_PAT	pat_0801CFD0, -16, 2
	SEQ_PAT	pat_0801D212, -20, 1
	SEQ_PAT	pat_0801D2E2, -20, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s12_c3:				@ 08026A94 song 12 channel 4
	SEQ_PAT	pat_0801D463, 0, 12
	SEQ_JUMP 0			@ -> word index 0
seq_s13_c0:				@ 08026AAC song 13 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 214			@ 214/256 ticks per frame
	SEQ_PAT	pat_0801C2EC, -26, 1
	SEQ_PAT	pat_0801C359, -26, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s13_c1:				@ 08026AEC song 13 channel 2
	SEQ_PAT	pat_0801C3C9, -26, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s13_c2:				@ 08026B04 song 13 channel 3
	SEQ_PAT	pat_0801C6B5, -14, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s13_c3:				@ 08026B1C song 13 channel 4
	SEQ_PAT	pat_0801C78E, 0, 4
	SEQ_JUMP 0			@ -> word index 0
seq_s14_c0:				@ 08026B34 song 14 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 154			@ 154/256 ticks per frame
	SEQ_PAT	pat_0801C195, -27, 1
	SEQ_CONDFLAG 1
	SEQ_END
seq_s14_c1:				@ 08026B60 song 14 channel 2
	SEQ_PAT	pat_0801C1D5, -27, 1
	SEQ_END
seq_s14_c2:				@ 08026B74 song 14 channel 3
	SEQ_PAT	pat_0801C215, -15, 1
	SEQ_END
seq_s14_c3:				@ 08026B88 song 14 channel 4
	SEQ_PAT	pat_0801C25E, 0, 1
	SEQ_END
seq_s15_c0:				@ 08026B9C song 15 channel 1
	SEQ_PAN 0xFF
	SEQ_TEMPO 240			@ 240/256 ticks per frame
	SEQ_PAT	pat_0801BD55, -19, 2
	SEQ_PAT	pat_0801BDB6, -19, 1
	SEQ_PAT	pat_0801B2BC, 0, 16
	SEQ_PAT	pat_0801BD55, -19, 2
	SEQ_PAT	pat_0801B2BC, 0, 16
	SEQ_PAT	pat_0801BCF4, -19, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4			@ -> word index 4
seq_s15_c1:				@ 08026C1C song 15 channel 2
	SEQ_PAT	pat_0801B76F, -19, 1
	SEQ_PAT	pat_0801B81E, -31, 1
	SEQ_PAT	pat_0801B76F, -19, 1
	SEQ_PAT	pat_0801B81E, -31, 1
	SEQ_PAT	pat_0801B8CD, -31, 1
	SEQ_PAT	pat_0801BBE8, -7, 1
	SEQ_PAT	pat_0801B76F, -19, 1
	SEQ_PAT	pat_0801B81E, -31, 1
	SEQ_PAT	pat_0801B76F, -19, 1
	SEQ_PAT	pat_0801B81E, -31, 1
	SEQ_PAT	pat_0801B9FA, -31, 1
	SEQ_PAT	pat_0801BB4B, -31, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s15_c2:				@ 08026CE4 song 15 channel 3
	SEQ_PAT	pat_0801BE47, -19, 2
	SEQ_PAT	pat_0801BEAB, -16, 1
	SEQ_PAT	pat_0801BF4E, -19, 1
	SEQ_PAT	pat_0801BE47, -19, 2
	SEQ_PAT	pat_0801C00F, -19, 1
	SEQ_PAT	pat_0801C0CD, -19, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s15_c3:				@ 08026D4C song 15 channel 4
	SEQ_PAT	pat_0801C125, 0, 21
	SEQ_JUMP 0			@ -> word index 0
seq_s15_c4:				@ 08026D64 song 15 channel 5
	SEQ_PAT	pat_0801B2C4, -18, 2
	SEQ_PAT	pat_0801B2F5, -15, 1
	SEQ_PAT	pat_0801B35F, -18, 1
	SEQ_PAT	pat_0801B2C4, -18, 2
	SEQ_PAT	pat_0801B46B, -6, 1
	SEQ_PAT	pat_0801B4E1, -18, 1
	SEQ_JUMP 0			@ -> word index 0
seq_s15_c5:				@ 08026DCC song 15 channel 6
	SEQ_PAT	pat_0801B533, -18, 2
	SEQ_PAT	pat_0801B564, -15, 1
	SEQ_PAT	pat_0801B5CE, -18, 1
	SEQ_PAT	pat_0801B533, -18, 2
	SEQ_PAT	pat_0801B6A7, -6, 1
	SEQ_PAT	pat_0801B71D, -18, 1
	SEQ_JUMP 0			@ -> word index 0

@ PSG frequency register values, split into low and high bytes (97 notes)
	.global mcFreqLo
mcFreqLo:
	.byte	0x9D, 0x07, 0x6B, 0xCA, 0x23, 0x78, 0xC7, 0x12, 0x59, 0x9C, 0xDB, 0x17	@ 0..
	.byte	0x4F, 0x84, 0xB6, 0xE5, 0x12, 0x3C, 0x64, 0x89, 0xAD, 0xCE, 0xEE, 0x0C	@ 12..
	.byte	0x28, 0x42, 0x5B, 0x73, 0x89, 0x9E, 0xB2, 0xC5, 0xD7, 0xE7, 0xF7, 0x06	@ 24..
	.byte	0x14, 0x21, 0x2E, 0x3A, 0x45, 0x4F, 0x59, 0x63, 0x6C, 0x74, 0x7C, 0x83	@ 36..
	.byte	0x8A, 0x91, 0x97, 0x9D, 0xA3, 0xA8, 0xAD, 0xB1, 0xB6, 0xBA, 0xBE, 0xC2	@ 48..
	.byte	0xC5, 0xC9, 0xCC, 0xCF, 0xD2, 0xD4, 0xD7, 0xD9, 0xDB, 0xDD, 0xDF, 0xE1	@ 60..
	.byte	0xE3, 0xE5, 0xE6, 0xE8, 0xE9, 0xEA, 0xEC, 0xED, 0xEE, 0xEF, 0xF0, 0xF1	@ 72..
	.byte	0xF2, 0xF3, 0xF3, 0xF4, 0xF5, 0xF5, 0xF7, 0xF7, 0xF8, 0xF8, 0xFA, 0xFA	@ 84..
	.byte	0x00	@ 96..
	.global mcFreqHi
mcFreqHi:
	.byte	0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04	@ 0..
	.byte	0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06	@ 12..
	.byte	0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x07	@ 24..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 36..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 48..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 60..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 72..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 84..
	.byte	0x00	@ 96..
	.byte	0x00, 0x00	@ padding

@ mcSongTable: 16 songs x {seq ch1..ch6, note-length table}
	.global mcSongTable
mcSongTable:
	.word	seq_s00_c0, seq_s00_c1, seq_s00_c2, seq_s00_c3, 0, 0, durTable0	@ song 0
	.word	seq_s01_c0, seq_s01_c1, seq_s01_c2, seq_s01_c3, 0, 0, durTable1	@ song 1
	.word	seq_s02_c0, seq_s02_c1, seq_s02_c2, seq_s02_c3, 0, 0, durTable0	@ song 2
	.word	seq_s03_c0, seq_s03_c1, seq_s03_c2, seq_s03_c3, 0, 0, durTable0	@ song 3
	.word	seq_s04_c0, seq_s04_c1, seq_s04_c2, seq_s04_c3, 0, 0, durTable0	@ song 4
	.word	seq_s05_c0, seq_s05_c1, seq_s05_c2, seq_s05_c3, 0, 0, durTable0	@ song 5
	.word	seq_s06_c0, seq_s06_c1, seq_s06_c2, seq_s06_c3, 0, 0, durTable0	@ song 6
	.word	seq_s07_c0, seq_s07_c1, seq_s07_c2, seq_s07_c3, 0, 0, durTable0	@ song 7
	.word	seq_s08_c0, seq_s08_c1, seq_s08_c2, seq_s08_c3, 0, 0, durTable0	@ song 8
	.word	seq_s09_c0, seq_s09_c1, seq_s09_c2, seq_s09_c3, 0, 0, durTable0	@ song 9
	.word	seq_s10_c0, seq_s10_c1, seq_s10_c2, seq_s10_c3, 0, 0, durTable0	@ song 10
	.word	seq_s11_c0, seq_s11_c1, seq_s11_c2, seq_s11_c3, 0, 0, durTable0	@ song 11
	.word	seq_s12_c0, seq_s12_c1, seq_s12_c2, seq_s12_c3, 0, 0, durTable0	@ song 12
	.word	seq_s13_c0, seq_s13_c1, seq_s13_c2, seq_s13_c3, 0, 0, durTable0	@ song 13
	.word	seq_s14_c0, seq_s14_c1, seq_s14_c2, seq_s14_c3, 0, 0, durTable0	@ song 14
	.word	seq_s15_c0, seq_s15_c1, seq_s15_c2, seq_s15_c3, seq_s15_c4, seq_s15_c5, durTable0	@ song 15

@ modulation tables: s16 pairs.  env {value, frames}; pitch {delta, frames};
@ arp {frames, semitones}.  0xFE,n = loop to halfword n; 0xFF = hold (end)
mod_080270B8:				@ env of inst 1
	.hword	240, 1, 0, 1, 112, 1, 0, 1
	.hword	255, 0
mod_080270CC:				@ env of inst 2
	.hword	240, 1, 112, 2, 48, 1, 32, 5
	.hword	16, 15, 0, 1, 255, 0, 0, 0
mod_080270EC:				@ env of inst 4
	.hword	64, 1, 48, 1, 32, 1, 16, 1
	.hword	0, 1, 255, 0, 0, 0, 0, 0
mod_0802710C:				@ env of inst 5
	.hword	64, 1, 48, 2, 32, 8, 16, 2
	.hword	16, 2, 0, 1, 255, 0, 0, 0
mod_0802712C:				@ env of inst 6
	.hword	144, 1, 64, 1, 48, 2, 32, 3
	.hword	16, 6, 0, 1, 255, 0, 0, 0
	.hword	0, 0, 0, 0
mod_08027154:				@ env of inst 9
	.hword	16, 1, 48, 1, 80, 1, 128, 5
	.hword	112, 10, 96, 100, 80, 100, 64, 100
	.hword	48, 100, 32, 100, 16, 100, 0, 1
	.hword	255, 0
mod_08027188:				@ env of inst 10
	.hword	80, 1, 64, 20, 48, 30, 32, 40
	.hword	16, 50, 0, 1, 255, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
mod_080271B8:				@ env of inst 11
	.hword	32, 1, 128, 4, 64, 14, 96, 14
	.hword	0, 1, 255, 0, 0, 0, 0, 0
mod_080271D8:				@ env of inst 12
	.hword	32, 2, 128, 20, 64, 60, 96, 120
	.hword	0, 1, 255, 0, 0, 0, 0, 0
mod_080271F8:				@ env of inst 14
	.hword	32, 4, 128, 6, 64, 10, 96, 20
	.hword	0, 1, 255, 0, 0, 0, 0, 0
mod_08027218:				@ env of inst 15
	.hword	16, 1, 32, 1, 64, 6, 32, 50
	.hword	16, 50, 0, 1, 255, 0, 0, 0
mod_08027238:				@ env of inst 16
	.hword	48, 1, 96, 1, 112, 1, 96, 3
	.hword	80, 3, 64, 12, 48, 16, 32, 24
	.hword	16, 24, 0, 1, 255, 0, 0, 0
mod_08027268:				@ env of inst 17
	.hword	48, 1, 96, 1, 112, 3, 128, 5
	.hword	112, 5, 96, 3, 80, 10, 64, 52
	.hword	48, 56, 32, 24, 16, 24, 0, 1
	.hword	255, 0, 0, 0, 0, 0
mod_080272A4:				@ env of inst 18
	.hword	16, 1, 32, 1, 64, 2, 80, 2
	.hword	64, 2, 48, 60, 32, 60, 16, 50
	.hword	0, 1, 255, 0
mod_080272CC:				@ env of inst 26
	.hword	96, 1, 80, 1, 64, 10, 48, 50
	.hword	32, 100, 16, 100, 0, 1, 255, 0
	.hword	0, 0, 0, 0
mod_080272F4:				@ env of inst 27
	.hword	48, 1, 64, 1, 80, 5, 64, 5
	.hword	48, 70, 32, 50, 16, 50, 0, 1
	.hword	255, 0, 0, 0, 0, 0
mod_08027320:				@ env of inst 29
	.hword	64, 2, 128, 1, 112, 2, 96, 5
	.hword	80, 5, 64, 12, 48, 26, 32, 94
	.hword	16, 64, 0, 1, 255, 0, 0, 0
mod_08027350:				@ pitch of inst 1
	.hword	97, 200, 255, 0, 0, 0, 0, 0
mod_08027360:				@ pitch of inst 2
	.hword	55, 2, 100, 2, 34, 1, 55, 1
	.hword	34, 1, 55, 1, 34, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 16
	.hword	255, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
mod_080273E0:				@ pitch of inst 3
	.hword	18, 200, 255, 0, 0, 0, 0, 0
mod_080273F0:				@ pitch of inst 4, pitch of inst 5
	.hword	34, 1, 16, 200, 255, 0, 0, 0
mod_08027400:				@ pitch of inst 6
	.hword	55, 1, 70, 1, 35, 1, 70, 1
	.hword	35, 1, 70, 1, 35, 1, 70, 1
	.hword	35, 1, 70, 1, 35, 1, 70, 1
	.hword	254, 0, 0, 0, 0, 0
mod_0802743C:				@ pitch of inst 7, pitch of inst 8, pitch of inst 9, pitch of inst 10, pitch of inst 13, pitch of inst 28
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	254, 0, 0, 0
mod_08027454:				@ pitch of inst 11, pitch of inst 12
	.hword	4, 2, -4, 2, -4, 2, 4, 2
	.hword	254, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
mod_08027494:				@ arp of inst 16, arp of inst 29
	.hword	1, 24, 23, 0, 4, 0, 4, -12
	.hword	4, 0, 4, -12, 254, 4, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0
mod_080274F8:				@ arp of inst 17
	.hword	1, 0, 6, 0, 4, -12, 6, 0
	.hword	4, -12, 6, 0, 4, -12, 254, 2
	.hword	0, 0, 0, 0, 0, 0, 0, 0
mod_08027528:				@ arp of inst 26
	.hword	8, 0, 8, -12, 8, 0, 8, -12
	.hword	8, 0, 8, -12, 254, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
mod_08027558:				@ arp of inst 19
	.hword	1, 0, 1, 4, 1, 7, 1, 0
	.hword	1, 4, 1, 7, 254, 0, 0, 0
mod_08027578:				@ arp of inst 20
	.hword	1, 4, 1, 7, 1, 12, 1, 4
	.hword	1, 7, 1, 12, 254, 0, 0, 0
mod_08027598:				@ arp of inst 21
	.hword	1, 7, 1, 12, 1, 16, 1, 7
	.hword	1, 12, 1, 16, 254, 0, 0, 0
mod_080275B8:				@ arp of inst 22
	.hword	1, 0, 1, 3, 1, 7, 1, 0
	.hword	1, 3, 1, 7, 254, 0, 0, 0
mod_080275D8:				@ arp of inst 23
	.hword	1, 3, 1, 7, 1, 12, 1, 3
	.hword	1, 7, 1, 12, 254, 0, 0, 0
mod_080275F8:				@ arp of inst 24
	.hword	1, 7, 1, 12, 1, 15, 1, 7
	.hword	1, 12, 1, 15, 254, 0, 0, 0

@ instruments (36 bytes): {b0, lo, hi, envOn, env, pitchOn, pitch, arpOn, arp}
@   PSG tone : b0<<8 -> CNT_X (0x40 = length enable), lo = duty/length, hi = envelope
@   wave     : lo = length, hi = SOUND3CNT_H volume byte
@   noise    : lo = length, hi = envelope; "pitch" table = SOUND4CNT_H values
inst_00:
	INSTRUMENT 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0
inst_01:
	INSTRUMENT 0x40, 0xBD, 0x00, 1, mod_080270B8, 1, mod_08027350, 0, 0
inst_02:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_080270CC, 1, mod_08027360, 0, 0
inst_03:
	INSTRUMENT 0x40, 0xBC, 0x41, 0, 0, 1, mod_080273E0, 0, 0
inst_04:
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080270EC, 1, mod_080273F0, 0, 0
inst_05:
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_0802710C, 1, mod_080273F0, 0, 0
inst_06:
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_0802712C, 1, mod_08027400, 0, 0
inst_07:
	INSTRUMENT 0x00, 0x40, 0x72, 0, 0, 1, mod_0802743C, 0, 0
inst_08:
	INSTRUMENT 0x00, 0x40, 0x87, 0, 0, 1, mod_0802743C, 0, 0
inst_09:
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_08027154, 1, mod_0802743C, 0, 0
inst_10:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08027188, 1, mod_0802743C, 0, 0
inst_11:
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080271B8, 6, mod_08027454, 0, 0
inst_12:
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080271D8, 6, mod_08027454, 0, 0
inst_13:
	INSTRUMENT 0x00, 0x80, 0x37, 0, 0, 1, mod_0802743C, 0, 0
inst_14:
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080271F8, 0, 0, 0, 0
inst_15:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08027218, 0, 0, 0, 0
inst_16:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08027238, 0, 0, 1, mod_08027494
inst_17:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08027268, 0, 0, 1, mod_080274F8
inst_18:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_080272A4, 0, 0, 0, 0
inst_19:
	INSTRUMENT 0x00, 0x80, 0x57, 0, 0, 0, 0, 1, mod_08027558
inst_20:
	INSTRUMENT 0x00, 0x80, 0x57, 0, 0, 0, 0, 1, mod_08027578
inst_21:
	INSTRUMENT 0x00, 0x80, 0x57, 0, 0, 0, 0, 1, mod_08027598
inst_22:
	INSTRUMENT 0x00, 0x80, 0x57, 0, 0, 0, 0, 1, mod_080275B8
inst_23:
	INSTRUMENT 0x00, 0x80, 0x57, 0, 0, 0, 0, 1, mod_080275D8
inst_24:
	INSTRUMENT 0x00, 0x80, 0x57, 0, 0, 0, 0, 1, mod_080275F8
inst_25:
	INSTRUMENT 0x00, 0x40, 0x93, 0, 0, 0, 0, 0, 0
inst_26:
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080272CC, 0, 0, 1, mod_08027528
inst_27:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_080272F4, 0, 0, 0, 0
inst_28:
	INSTRUMENT 0x00, 0x40, 0x45, 0, 0, 1, mod_0802743C, 0, 0
inst_29:
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08027320, 0, 0, 1, mod_08027494
inst_30:
	INSTRUMENT 0x00, 0x80, 0x47, 0, 0, 0, 0, 0, 0

	.global mcInstTable
mcInstTable:
	.word	inst_00
	.word	inst_01
	.word	inst_02
	.word	inst_03
	.word	inst_04
	.word	inst_05
	.word	inst_06
	.word	inst_07
	.word	inst_08
	.word	inst_09
	.word	inst_10
	.word	inst_11
	.word	inst_12
	.word	inst_13
	.word	inst_14
	.word	inst_15
	.word	inst_16
	.word	inst_17
	.word	inst_18
	.word	inst_19
	.word	inst_20
	.word	inst_21
	.word	inst_22
	.word	inst_23
	.word	inst_24
	.word	inst_25
	.word	inst_26
	.word	inst_27
	.word	inst_28
	.word	inst_29
	.word	inst_30

@ ============================================================================
@ SfxTable (0x080284FC): 94 x {u8 priority, u8 pan, u16 pitch (256 = 1.0), ptr RIFF/WAV}
@ pan: 0 = both, 1 = left, 2 = right (all 0 in E.T.).  The WAV files stay in ROM;
@ their addresses are given as absolute symbols.
@ ============================================================================
	.equ	wav_0833EB9C, 0x0833EB9C      @ 11025 Hz, 3259 bytes
	.equ	wav_0833F884, 0x0833F884      @ 11025 Hz, 2398 bytes
	.equ	wav_08340210, 0x08340210      @ 11025 Hz, 2996 bytes
	.equ	wav_08340DF0, 0x08340DF0      @ 11025 Hz, 2204 bytes
	.equ	wav_083416B8, 0x083416B8      @ 11025 Hz, 2204 bytes
	.equ	wav_08341F80, 0x08341F80      @ 11025 Hz, 3897 bytes
	.equ	wav_08342EE8, 0x08342EE8      @ 11025 Hz, 10383 bytes
	.equ	wav_083457A4, 0x083457A4      @ 11025 Hz, 7114 bytes
	.equ	wav_0834739C, 0x0834739C      @ 11025 Hz, 16536 bytes
	.equ	wav_0834B460, 0x0834B460      @ 11025 Hz, 15283 bytes
	.equ	wav_0834F040, 0x0834F040      @ 11025 Hz, 22014 bytes
	.equ	wav_0835466C, 0x0835466C      @ 11025 Hz, 12962 bytes
	.equ	wav_0835793C, 0x0835793C      @ 11025 Hz, 14111 bytes
	.equ	wav_0835B088, 0x0835B088      @ 11025 Hz, 18755 bytes
	.equ	wav_0835F9F8, 0x0835F9F8      @ 11025 Hz, 21001 bytes
	.equ	wav_08364C30, 0x08364C30      @ 11025 Hz, 8217 bytes
	.equ	wav_08366C78, 0x08366C78      @ 11025 Hz, 6823 bytes
	.equ	wav_0836874C, 0x0836874C      @ 11025 Hz, 8417 bytes
	.equ	wav_0836A85C, 0x0836A85C      @ 11025 Hz, 9689 bytes
	.equ	wav_0836CE64, 0x0836CE64      @ 11025 Hz, 4655 bytes
	.equ	wav_0836E0C0, 0x0836E0C0      @ 11025 Hz, 3695 bytes
	.equ	wav_0836EF5C, 0x0836EF5C      @ 11025 Hz, 9281 bytes
	.equ	wav_083713CC, 0x083713CC      @ 11025 Hz, 9263 bytes
	.equ	wav_08373828, 0x08373828      @ 11025 Hz, 7119 bytes
	.equ	wav_08375424, 0x08375424      @ 11025 Hz, 7647 bytes
	.equ	wav_08377230, 0x08377230      @ 11025 Hz, 4745 bytes
	.equ	wav_083784E8, 0x083784E8      @ 11025 Hz, 5671 bytes
	.equ	wav_08379B3C, 0x08379B3C      @ 11025 Hz, 4013 bytes
	.equ	wav_0837AB18, 0x0837AB18      @ 11025 Hz, 9947 bytes
	.equ	wav_0837D220, 0x0837D220      @ 11025 Hz, 1121 bytes
	.equ	wav_0837D6B0, 0x0837D6B0      @ 11025 Hz, 11999 bytes
	.equ	wav_083805BC, 0x083805BC      @ 11025 Hz, 8268 bytes
	.equ	wav_08382634, 0x08382634      @ 11025 Hz, 7183 bytes
	.equ	wav_08384270, 0x08384270      @ 11025 Hz, 7824 bytes
	.equ	wav_0838612C, 0x0838612C      @ 11025 Hz, 9575 bytes
	.equ	wav_083886C0, 0x083886C0      @ 11025 Hz, 12977 bytes
	.equ	wav_0838B9A0, 0x0838B9A0      @ 11025 Hz, 2659 bytes
	.equ	wav_0838C430, 0x0838C430      @ 11025 Hz, 595 bytes
	.equ	wav_0838C6B0, 0x0838C6B0      @ 11025 Hz, 31743 bytes
	.equ	wav_083942DC, 0x083942DC      @ 11025 Hz, 4463 bytes
	.equ	wav_08395478, 0x08395478      @ 11025 Hz, 21503 bytes
	.equ	wav_0839A8A4, 0x0839A8A4      @ 11025 Hz, 22975 bytes
	.equ	wav_083A0290, 0x083A0290      @ 11025 Hz, 8479 bytes
	.equ	wav_083A23DC, 0x083A23DC      @ 11025 Hz, 14591 bytes
	.equ	wav_083A5D08, 0x083A5D08      @ 11025 Hz, 14591 bytes
	.equ	wav_083A9634, 0x083A9634      @ 11025 Hz, 11327 bytes
	.equ	wav_083AC2A0, 0x083AC2A0      @ 11025 Hz, 32254 bytes
	.equ	wav_083B40CC, 0x083B40CC      @ 11025 Hz, 2434 bytes
	.equ	wav_083B4A7C, 0x083B4A7C      @ 11025 Hz, 6397 bytes
	.equ	wav_083B63A8, 0x083B63A8      @ 11025 Hz, 13119 bytes
	.equ	wav_083B9714, 0x083B9714      @ 11025 Hz, 8124 bytes
	.equ	wav_083BB6FC, 0x083BB6FC      @ 11025 Hz, 10530 bytes
	.equ	wav_083BE04C, 0x083BE04C      @ 11025 Hz, 4472 bytes
	.equ	wav_083BF1F0, 0x083BF1F0      @ 11025 Hz, 18431 bytes
	.equ	wav_083C3A1C, 0x083C3A1C      @ 11025 Hz, 34986 bytes
	.equ	wav_083CC2F4, 0x083CC2F4      @ 11025 Hz, 17072 bytes
	.equ	wav_083D05D0, 0x083D05D0      @ 11025 Hz, 10751 bytes
	.equ	wav_083D2FFC, 0x083D2FFC      @ 11025 Hz, 18110 bytes
	.equ	wav_083D76E8, 0x083D76E8      @ 11025 Hz, 5759 bytes
	.equ	wav_083D8D94, 0x083D8D94      @ 11025 Hz, 10207 bytes
	.equ	wav_083DB5A0, 0x083DB5A0      @ 11025 Hz, 3731 bytes
	.equ	wav_083DC460, 0x083DC460      @ 11025 Hz, 3731 bytes
	.equ	wav_083DD320, 0x083DD320      @ 11025 Hz, 14271 bytes
	.equ	wav_083E0B0C, 0x083E0B0C      @ 11025 Hz, 23808 bytes
	.equ	wav_083E6838, 0x083E6838      @ 11025 Hz, 12733 bytes
	.equ	wav_083E9A24, 0x083E9A24      @ 11025 Hz, 27051 bytes
	.section .sfxtable, "a", %progbits
	.global SfxTable
SfxTable:
	.byte	100, 0
	.hword	256
	.word	wav_0833EB9C		@ sfx 0
	.byte	100, 0
	.hword	256
	.word	wav_0833F884		@ sfx 1
	.byte	100, 0
	.hword	256
	.word	wav_08340210		@ sfx 2
	.byte	100, 0
	.hword	256
	.word	wav_08340DF0		@ sfx 3
	.byte	100, 0
	.hword	256
	.word	wav_083416B8		@ sfx 4
	.byte	100, 0
	.hword	256
	.word	wav_08341F80		@ sfx 5
	.byte	100, 0
	.hword	768
	.word	wav_08341F80		@ sfx 6
	.byte	100, 0
	.hword	256
	.word	wav_08342EE8		@ sfx 7
	.byte	100, 0
	.hword	256
	.word	wav_083457A4		@ sfx 8
	.byte	240, 0
	.hword	256
	.word	wav_0834739C		@ sfx 9
	.byte	240, 0
	.hword	256
	.word	wav_0834B460		@ sfx 10
	.byte	100, 0
	.hword	256
	.word	wav_0834F040		@ sfx 11
	.byte	100, 0
	.hword	256
	.word	wav_0835466C		@ sfx 12
	.byte	100, 0
	.hword	384
	.word	wav_0835466C		@ sfx 13
	.byte	210, 0
	.hword	384
	.word	wav_0834B460		@ sfx 14
	.byte	200, 0
	.hword	256
	.word	wav_0835793C		@ sfx 15
	.byte	100, 0
	.hword	256
	.word	wav_0835B088		@ sfx 16
	.byte	100, 0
	.hword	256
	.word	wav_0835F9F8		@ sfx 17
	.byte	100, 0
	.hword	256
	.word	wav_0835B088		@ sfx 18
	.byte	100, 0
	.hword	256
	.word	wav_0835F9F8		@ sfx 19
	.byte	100, 0
	.hword	256
	.word	wav_08364C30		@ sfx 20
	.byte	100, 0
	.hword	256
	.word	wav_08366C78		@ sfx 21
	.byte	100, 0
	.hword	256
	.word	wav_0836874C		@ sfx 22
	.byte	100, 0
	.hword	256
	.word	wav_0836A85C		@ sfx 23
	.byte	100, 0
	.hword	256
	.word	wav_0836CE64		@ sfx 24
	.byte	100, 0
	.hword	256
	.word	wav_0836E0C0		@ sfx 25
	.byte	100, 0
	.hword	256
	.word	wav_0836EF5C		@ sfx 26
	.byte	100, 0
	.hword	256
	.word	wav_083713CC		@ sfx 27
	.byte	100, 0
	.hword	256
	.word	wav_08373828		@ sfx 28
	.byte	100, 0
	.hword	256
	.word	wav_08375424		@ sfx 29
	.byte	100, 0
	.hword	256
	.word	wav_08377230		@ sfx 30
	.byte	100, 0
	.hword	256
	.word	wav_083784E8		@ sfx 31
	.byte	100, 0
	.hword	256
	.word	wav_08379B3C		@ sfx 32
	.byte	100, 0
	.hword	256
	.word	wav_0837AB18		@ sfx 33
	.byte	  4, 0
	.hword	512
	.word	wav_0837D220		@ sfx 34
	.byte	  4, 0
	.hword	512
	.word	wav_0837D6B0		@ sfx 35
	.byte	 40, 0
	.hword	256
	.word	wav_083805BC		@ sfx 36
	.byte	  4, 0
	.hword	256
	.word	wav_0837D6B0		@ sfx 37
	.byte	  4, 0
	.hword	256
	.word	wav_08382634		@ sfx 38
	.byte	200, 0
	.hword	256
	.word	wav_0834B460		@ sfx 39
	.byte	200, 0
	.hword	256
	.word	wav_08384270		@ sfx 40
	.byte	200, 0
	.hword	256
	.word	wav_0838612C		@ sfx 41
	.byte	200, 0
	.hword	256
	.word	wav_083886C0		@ sfx 42
	.byte	200, 0
	.hword	256
	.word	wav_0833EB9C		@ sfx 43
	.byte	200, 0
	.hword	256
	.word	wav_0833EB9C		@ sfx 44
	.byte	200, 0
	.hword	256
	.word	wav_0838B9A0		@ sfx 45
	.byte	  9, 0
	.hword	256
	.word	wav_0838C430		@ sfx 46
	.byte	  3, 0
	.hword	256
	.word	wav_0838C6B0		@ sfx 47
	.byte	  3, 0
	.hword	256
	.word	wav_083942DC		@ sfx 48
	.byte	  3, 0
	.hword	256
	.word	wav_08395478		@ sfx 49
	.byte	  3, 0
	.hword	256
	.word	wav_0839A8A4		@ sfx 50
	.byte	  3, 0
	.hword	256
	.word	wav_083A0290		@ sfx 51
	.byte	 30, 0
	.hword	256
	.word	wav_083A23DC		@ sfx 52
	.byte	 30, 0
	.hword	256
	.word	wav_083A5D08		@ sfx 53
	.byte	  2, 0
	.hword	512
	.word	wav_08379B3C		@ sfx 54
	.byte	 30, 0
	.hword	256
	.word	wav_083A9634		@ sfx 55
	.byte	  1, 0
	.hword	256
	.word	wav_0837D220		@ sfx 56
	.byte	100, 0
	.hword	256
	.word	wav_0837AB18		@ sfx 57
	.byte	100, 0
	.hword	512
	.word	wav_083AC2A0		@ sfx 58
	.byte	 12, 0
	.hword	256
	.word	wav_083B40CC		@ sfx 59
	.byte	 10, 0
	.hword	256
	.word	wav_083457A4		@ sfx 60
	.byte	 11, 0
	.hword	256
	.word	wav_0835793C		@ sfx 61
	.byte	 11, 0
	.hword	256
	.word	wav_083B4A7C		@ sfx 62
	.byte	 50, 0
	.hword	256
	.word	wav_083B63A8		@ sfx 63
	.byte	 50, 0
	.hword	256
	.word	wav_083AC2A0		@ sfx 64
	.byte	 40, 0
	.hword	256
	.word	wav_083B9714		@ sfx 65
	.byte	  1, 0
	.hword	768
	.word	wav_083BB6FC		@ sfx 66
	.byte	 50, 0
	.hword	256
	.word	wav_083BE04C		@ sfx 67
	.byte	  5, 0
	.hword	256
	.word	wav_083BF1F0		@ sfx 68
	.byte	  7, 0
	.hword	256
	.word	wav_083C3A1C		@ sfx 69
	.byte	 50, 0
	.hword	512
	.word	wav_083BB6FC		@ sfx 70
	.byte	 50, 0
	.hword	128
	.word	wav_08379B3C		@ sfx 71
	.byte	 50, 0
	.hword	256
	.word	wav_083A5D08		@ sfx 72
	.byte	  2, 0
	.hword	256
	.word	wav_08379B3C		@ sfx 73
	.byte	100, 0
	.hword	256
	.word	wav_083CC2F4		@ sfx 74
	.byte	100, 0
	.hword	256
	.word	wav_083D05D0		@ sfx 75
	.byte	100, 0
	.hword	256
	.word	wav_0833EB9C		@ sfx 76
	.byte	100, 0
	.hword	256
	.word	wav_083D05D0		@ sfx 77
	.byte	100, 0
	.hword	256
	.word	wav_083D2FFC		@ sfx 78
	.byte	100, 0
	.hword	256
	.word	wav_083D76E8		@ sfx 79
	.byte	100, 0
	.hword	256
	.word	wav_083D8D94		@ sfx 80
	.byte	100, 0
	.hword	256
	.word	wav_083DB5A0		@ sfx 81
	.byte	100, 0
	.hword	256
	.word	wav_083DC460		@ sfx 82
	.byte	100, 0
	.hword	256
	.word	wav_0834B460		@ sfx 83
	.byte	100, 0
	.hword	256
	.word	wav_0834B460		@ sfx 84
	.byte	 10, 0
	.hword	256
	.word	wav_083DD320		@ sfx 85
	.byte	 10, 0
	.hword	256
	.word	wav_083E0B0C		@ sfx 86
	.byte	 10, 0
	.hword	256
	.word	wav_083E6838		@ sfx 87
	.byte	 11, 0
	.hword	512
	.word	wav_0833EB9C		@ sfx 88
	.byte	 11, 0
	.hword	512
	.word	wav_0833F884		@ sfx 89
	.byte	210, 0
	.hword	256
	.word	wav_083E9A24		@ sfx 90
	.byte	 10, 0
	.hword	512
	.word	wav_0834B460		@ sfx 91
	.byte	 10, 0
	.hword	128
	.word	wav_08340DF0		@ sfx 92
	.byte	 10, 0
	.hword	128
	.word	wav_08340210		@ sfx 93
