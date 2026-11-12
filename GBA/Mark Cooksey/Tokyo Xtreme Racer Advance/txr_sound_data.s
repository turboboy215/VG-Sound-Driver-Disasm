@ ============================================================================
@ txr_sound_data.s -- music and SFX data of Tokyo Xtreme Racer Advance (GBA)
@ Mark Cooksey sound driver, "Build B" (4 PSG + 4 software-mixed PCM channels).
@ Reconstructed from "Tokyo Xtreme Racer Advance (E) (M5).gba" (BTZP).
@   section .musicdata  083466F0-083D529C (584620 bytes)
@   section .fadetab    0803AE58-0803AE7C (36 bytes)
@ Linking with txr_sound_data.ld and objcopy reproduces each range byte for byte
@ (make -f txr_sound.mk).  PCM sample data is pulled in from txr_pcm.bin.
@ All labels were assigned during the analysis; the ROM has no symbols.
@ See claude/cooksey-gba-variants-comparison.md for the formats.
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
	.macro SEQ_PAN v		@ global panning: SOUNDCNT_L = v<<8 | 0x77
	.word 0x67, \v
	.endm
	.macro SEQ_TEMPO t		@ 8.8 ticks per frame
	.word 0x69, \t
	.endm
	.macro SEQ_CONDFLAG v	@ end-of-song flag; never read
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
@ ---- PSG instrument: 9 words (on channels 5-8 the instrument number indexes mcSmpInstTable)
	.macro INSTRUMENT b0, lo, hi, envOn, env, pitchOn, pitch, arpOn, arp
	.word \b0, \lo, \hi, \envOn, \env, \pitchOn, \pitch, \arpOn, \arp
	.endm

@ IWRAM addresses the mixers are copied to by mcSoundInit
	.equ	IWRAM_mcMixMusic, 0x03006AA0
	.equ	IWRAM_mcSfxMix, 0x030068A0

@ ----------------------------------------------------------------------------
	.section .musicdata, "a", %progbits
@ ----------------------------------------------------------------------------

@ mcMixerFuncs: called by mcUpdate via _call_via_r1 (the mixers run from IWRAM)
	.global mcMixerFuncs
mcMixerFuncs:				@ 083466F0
	.word	IWRAM_mcMixMusic	@ ARM
	.word	IWRAM_mcSfxMix+1	@ Thumb

@ E.T.-style mcSmpNoteTable {rate Hz, samples/frame, timer period}: left over from Build A,
@ not referenced by this driver
	.global mcLegacySmpNoteTable
mcLegacySmpNoteTable:				@ 083466F8
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

@ mcStepTable: 18.14 resampling step, indexed by 0x5F - note (stored high note first).
@ Note 48 = step 0x431F = 11 025 Hz at the 10 512 Hz mix rate; notes 72-95 are dummies (10).
	.global mcStepTable
mcStepTable:				@ 08346B78
	.word	0x0000A	@ [ 0] note 95
	.word	0x0000A	@ [ 1] note 94
	.word	0x0000A	@ [ 2] note 93
	.word	0x0000A	@ [ 3] note 92
	.word	0x0000A	@ [ 4] note 91
	.word	0x0000A	@ [ 5] note 90
	.word	0x0000A	@ [ 6] note 89
	.word	0x0000A	@ [ 7] note 88
	.word	0x0000A	@ [ 8] note 87
	.word	0x0000A	@ [ 9] note 86
	.word	0x0000A	@ [10] note 85
	.word	0x0000A	@ [11] note 84
	.word	0x0000A	@ [12] note 83
	.word	0x0000A	@ [13] note 82
	.word	0x0000A	@ [14] note 81
	.word	0x0000A	@ [15] note 80
	.word	0x0000A	@ [16] note 79
	.word	0x0000A	@ [17] note 78
	.word	0x0000A	@ [18] note 77
	.word	0x0000A	@ [19] note 76
	.word	0x0000A	@ [20] note 75
	.word	0x0000A	@ [21] note 74
	.word	0x0000A	@ [22] note 73
	.word	0x0000A	@ [23] note 72
	.word	0x0FD64	@ [24] note 71
	.word	0x0EF3E	@ [25] note 70
	.word	0x0E1C8	@ [26] note 69
	.word	0x0D51B	@ [27] note 68
	.word	0x0C932	@ [28] note 67
	.word	0x0BDD2	@ [29] note 66
	.word	0x0B327	@ [30] note 65
	.word	0x0A902	@ [31] note 64
	.word	0x09FA8	@ [32] note 63
	.word	0x096B3	@ [33] note 62
	.word	0x08E3A	@ [34] note 61
	.word	0x0863F	@ [35] note 60
	.word	0x07EB2	@ [36] note 59
	.word	0x0779F	@ [37] note 58
	.word	0x070E4	@ [38] note 57
	.word	0x06A8D	@ [39] note 56
	.word	0x06495	@ [40] note 55
	.word	0x05EE5	@ [41] note 54
	.word	0x05996	@ [42] note 53
	.word	0x05483	@ [43] note 52
	.word	0x04FD6	@ [44] note 51
	.word	0x04B59	@ [45] note 50
	.word	0x0471D	@ [46] note 49
	.word	0x0431F	@ [47] note 48
	.word	0x03F57	@ [48] note 47
	.word	0x03BCE	@ [49] note 46
	.word	0x03872	@ [50] note 45
	.word	0x03546	@ [51] note 44
	.word	0x0324A	@ [52] note 43
	.word	0x02F72	@ [53] note 42
	.word	0x02CCA	@ [54] note 41
	.word	0x02A41	@ [55] note 40
	.word	0x027EA	@ [56] note 39
	.word	0x025AC	@ [57] note 38
	.word	0x0238E	@ [58] note 37
	.word	0x0218F	@ [59] note 36
	.word	0x01FAB	@ [60] note 35
	.word	0x01DE7	@ [61] note 34
	.word	0x01C39	@ [62] note 33
	.word	0x01AA3	@ [63] note 32
	.word	0x01925	@ [64] note 31
	.word	0x017B9	@ [65] note 30
	.word	0x01665	@ [66] note 29
	.word	0x01520	@ [67] note 28
	.word	0x013F5	@ [68] note 27
	.word	0x012D6	@ [69] note 26
	.word	0x011C7	@ [70] note 25
	.word	0x010C7	@ [71] note 24
	.word	0x00FD5	@ [72] note 23
	.word	0x00EF3	@ [73] note 22
	.word	0x00E1C	@ [74] note 21
	.word	0x00D51	@ [75] note 20
	.word	0x00C92	@ [76] note 19
	.word	0x00BDC	@ [77] note 18
	.word	0x00B32	@ [78] note 17
	.word	0x00A90	@ [79] note 16
	.word	0x009FA	@ [80] note 15
	.word	0x0096B	@ [81] note 14
	.word	0x008E3	@ [82] note 13
	.word	0x00863	@ [83] note 12
	.word	0x15888	@ [84] note 11
	.word	0x15888	@ [85] note 10
	.word	0x15888	@ [86] note  9
	.word	0x15888	@ [87] note  8
	.word	0x15888	@ [88] note  7
	.word	0x15888	@ [89] note  6
	.word	0x15888	@ [90] note  5
	.word	0x15888	@ [91] note  4
	.word	0x15888	@ [92] note  3
	.word	0x15888	@ [93] note  2
	.word	0x15888	@ [94] note  1
	.word	0x15888	@ [95] note  0

@ PCM sample data: 8-bit signed.  Music instruments are recorded so that note 48
@ = 11 025 Hz; SFX run 1:1 through the 10.5 kHz SFX mixer.  Labels mark each start
@ address referenced by mcSmpInstTable / mcSfxTable.
	.global pcm_08346CF8
pcm_08346CF8:				@ 08346CF8, 1104 bytes
	.incbin "txr_pcm.bin", 0x0, 0x450
	.global pcm_08347148
pcm_08347148:				@ 08347148, 2188 bytes
	.incbin "txr_pcm.bin", 0x450, 0x88C
	.global pcm_083479D4
pcm_083479D4:				@ 083479D4, 8156 bytes
	.incbin "txr_pcm.bin", 0xCDC, 0x1FDC
	.global pcm_083499B0
pcm_083499B0:				@ 083499B0, 3412 bytes
	.incbin "txr_pcm.bin", 0x2CB8, 0xD54
	.global pcm_0834A704
pcm_0834A704:				@ 0834A704, 16464 bytes
	.incbin "txr_pcm.bin", 0x3A0C, 0x4050
	.global pcm_0834E754
pcm_0834E754:				@ 0834E754, 24112 bytes
	.incbin "txr_pcm.bin", 0x7A5C, 0x5E30
	.global pcm_08354584
pcm_08354584:				@ 08354584, 15200 bytes
	.incbin "txr_pcm.bin", 0xD88C, 0x3B60
	.global pcm_083580E4
pcm_083580E4:				@ 083580E4, 6704 bytes
	.incbin "txr_pcm.bin", 0x113EC, 0x1A30
	.global pcm_08359B14
pcm_08359B14:				@ 08359B14, 5344 bytes
	.incbin "txr_pcm.bin", 0x12E1C, 0x14E0
	.global pcm_0835AFF4
pcm_0835AFF4:				@ 0835AFF4, 500 bytes
	.incbin "txr_pcm.bin", 0x142FC, 0x1F4
	.global pcm_0835B1E8
pcm_0835B1E8:				@ 0835B1E8, 3500 bytes
	.incbin "txr_pcm.bin", 0x144F0, 0xDAC
	.global pcm_0835BF94
pcm_0835BF94:				@ 0835BF94, 5000 bytes
	.incbin "txr_pcm.bin", 0x1529C, 0x1388
	.global pcm_0835D31C
pcm_0835D31C:				@ 0835D31C, 4000 bytes
	.incbin "txr_pcm.bin", 0x16624, 0xFA0
	.global pcm_0835E2BC
pcm_0835E2BC:				@ 0835E2BC, 4500 bytes
	.incbin "txr_pcm.bin", 0x175C4, 0x1194
	.global pcm_0835F450
pcm_0835F450:				@ 0835F450, 2500 bytes
	.incbin "txr_pcm.bin", 0x18758, 0x9C4
	.global pcm_0835FE14
pcm_0835FE14:				@ 0835FE14, 2084 bytes
	.incbin "txr_pcm.bin", 0x1911C, 0x824
	.global pcm_08360638
pcm_08360638:				@ 08360638, 42844 bytes
	.incbin "txr_pcm.bin", 0x19940, 0xA75C
	.global pcm_0836AD94
pcm_0836AD94:				@ 0836AD94, 51656 bytes
	.incbin "txr_pcm.bin", 0x2409C, 0xC9C8
	.global pcm_0837775C
pcm_0837775C:				@ 0837775C, 51040 bytes
	.incbin "txr_pcm.bin", 0x30A64, 0xC760
	.global pcm_08383EBC
pcm_08383EBC:				@ 08383EBC, 20672 bytes
	.incbin "txr_pcm.bin", 0x3D1C4, 0x50C0
	.global pcm_08388F7C
pcm_08388F7C:				@ 08388F7C, 20672 bytes
	.incbin "txr_pcm.bin", 0x42284, 0x50C0
	.global pcm_0838E03C
pcm_0838E03C:				@ 0838E03C, 22036 bytes
	.incbin "txr_pcm.bin", 0x47344, 0x5614
	.global pcm_08393650
pcm_08393650:				@ 08393650, 3912 bytes
	.incbin "txr_pcm.bin", 0x4C958, 0xF48
	.global pcm_08394598
pcm_08394598:				@ 08394598, 1328 bytes
	.incbin "txr_pcm.bin", 0x4D8A0, 0x530
	.global pcm_08394AC8
pcm_08394AC8:				@ 08394AC8, 824 bytes
	.incbin "txr_pcm.bin", 0x4DDD0, 0x338
	.global pcm_08394E00
pcm_08394E00:				@ 08394E00, 4312 bytes
	.incbin "txr_pcm.bin", 0x4E108, 0x10D8
	.global pcm_08395ED8
pcm_08395ED8:				@ 08395ED8, 5584 bytes
	.incbin "txr_pcm.bin", 0x4F1E0, 0x15D0
	.global pcm_083974A8
pcm_083974A8:				@ 083974A8, 2152 bytes
	.incbin "txr_pcm.bin", 0x507B0, 0x868
	.global pcm_08397D10
pcm_08397D10:				@ 08397D10, 6540 bytes
	.incbin "txr_pcm.bin", 0x51018, 0x198C
	.global pcm_0839969C
pcm_0839969C:				@ 0839969C, 4512 bytes
	.incbin "txr_pcm.bin", 0x529A4, 0x11A0
	.global pcm_0839A83C
pcm_0839A83C:				@ 0839A83C, 13844 bytes
	.incbin "txr_pcm.bin", 0x53B44, 0x3614
	.global pcm_0839DE50
pcm_0839DE50:				@ 0839DE50, 5928 bytes
	.incbin "txr_pcm.bin", 0x57158, 0x1728
	.global pcm_0839F578
pcm_0839F578:				@ 0839F578, 7316 bytes
	.incbin "txr_pcm.bin", 0x58880, 0x1C94
	.global pcm_083A120C
pcm_083A120C:				@ 083A120C, 6928 bytes
	.incbin "txr_pcm.bin", 0x5A514, 0x1B10
	.global pcm_083A2D1C
pcm_083A2D1C:				@ 083A2D1C, 4084 bytes
	.incbin "txr_pcm.bin", 0x5C024, 0xFF4
	.global pcm_083A3D10
pcm_083A3D10:				@ 083A3D10, 5632 bytes
	.incbin "txr_pcm.bin", 0x5D018, 0x1600
	.global pcm_083A5310
pcm_083A5310:				@ 083A5310, 10960 bytes
	.incbin "txr_pcm.bin", 0x5E618, 0x2AD0
	.global pcm_083A7DE0
pcm_083A7DE0:				@ 083A7DE0, 1536 bytes
	.incbin "txr_pcm.bin", 0x610E8, 0x600
	.global pcm_083A83E0
pcm_083A83E0:				@ 083A83E0, 3184 bytes
	.incbin "txr_pcm.bin", 0x616E8, 0xC70
	.global pcm_083A9050
pcm_083A9050:				@ 083A9050, 6892 bytes
	.incbin "txr_pcm.bin", 0x62358, 0x1AEC
	.global pcm_083AAB3C
pcm_083AAB3C:				@ 083AAB3C, 3824 bytes
	.incbin "txr_pcm.bin", 0x63E44, 0xEF0
	.global pcm_083ABA2C
pcm_083ABA2C:				@ 083ABA2C, 4936 bytes
	.incbin "txr_pcm.bin", 0x64D34, 0x1348
	.global pcm_083ACD74
pcm_083ACD74:				@ 083ACD74, 3068 bytes
	.incbin "txr_pcm.bin", 0x6607C, 0xBFC
	.global pcm_083AD970
pcm_083AD970:				@ 083AD970, 3664 bytes
	.incbin "txr_pcm.bin", 0x66C78, 0xE50
	.global pcm_083AE7C0
pcm_083AE7C0:				@ 083AE7C0, 6068 bytes
	.incbin "txr_pcm.bin", 0x67AC8, 0x17B4
	.global pcm_083AFF74
pcm_083AFF74:				@ 083AFF74, 8548 bytes
	.incbin "txr_pcm.bin", 0x6927C, 0x2164
	.global pcm_083B20D8
pcm_083B20D8:				@ 083B20D8, 23940 bytes
	.incbin "txr_pcm.bin", 0x6B3E0, 0x5D84
	.global pcm_083B7E5C
pcm_083B7E5C:				@ 083B7E5C, 23308 bytes
	.incbin "txr_pcm.bin", 0x71164, 0x5B0C
	.global pcm_083BD968
pcm_083BD968:				@ 083BD968, 7724 bytes
	.incbin "txr_pcm.bin", 0x76C70, 0x1E2C
	.global pcm_083BF794
pcm_083BF794:				@ 083BF794, 3396 bytes
	.incbin "txr_pcm.bin", 0x78A9C, 0xD44
	.global pcm_083C04D8
pcm_083C04D8:				@ 083C04D8, 7364 bytes
	.incbin "txr_pcm.bin", 0x797E0, 0x1CC4
	.global pcm_083C219C
pcm_083C219C:				@ 083C219C, 9984 bytes
	.incbin "txr_pcm.bin", 0x7B4A4, 0x2700
	.global pcm_083C489C
pcm_083C489C:				@ 083C489C, 14444 bytes
	.incbin "txr_pcm.bin", 0x7DBA4, 0x386C
	.global pcm_083C8108
pcm_083C8108:				@ 083C8108, 15044 bytes
	.incbin "txr_pcm.bin", 0x81410, 0x3AC4

@ mcSfxTable: {pcm, frames, loop, unused, wrapLen}; wrapLen != 0 = engine loop for voice 0
	.global mcSfxTable
mcSfxTable:				@ 083CBBCC
	.word	pcm_08346CF8, 0x6, 0x0, 0x80, 0x0	@ sfx 0
	.word	pcm_083974A8, 0xB, 0x0, 0x80, 0x0	@ sfx 1
	.word	pcm_0839969C, 0x18, 0x0, 0x80, 0x0	@ sfx 2
	.word	pcm_08397D10, 0x23, 0x0, 0x80, 0x0	@ sfx 3
	.word	pcm_08394E00, 0x17, 0x0, 0x80, 0x0	@ sfx 4
	.word	pcm_08395ED8, 0x1E, 0x0, 0x80, 0x0	@ sfx 5
	.word	pcm_08394598, 0x7, 0x0, 0x80, 0x0	@ sfx 6
	.word	pcm_08394AC8, 0x4, 0x0, 0x80, 0x0	@ sfx 7
	.word	pcm_0839A83C, 0x4B, 0x0, 0x80, 0x0	@ sfx 8
	.word	pcm_0839DE50, 0x20, 0x0, 0x80, 0x0	@ sfx 9
	.word	pcm_0839F578, 0x27, 0x0, 0x80, 0x0	@ sfx 10
	.word	pcm_083A120C, 0x25, 0x0, 0x80, 0x0	@ sfx 11
	.word	pcm_083A2D1C, 0x16, 0x0, 0x80, 0x0	@ sfx 12
	.word	pcm_083A3D10, 0x1E, 0x0, 0x80, 0x0	@ sfx 13
	.word	pcm_083A5310, 0x3B, 0x0, 0x80, 0x0	@ sfx 14
	.word	pcm_083A7DE0, 0x19, 0x0, 0x80, 0x0	@ sfx 15
	.word	pcm_083A83E0, 0x11, 0x0, 0x80, 0x0	@ sfx 16
	.word	pcm_083A9050, 0x25, 0x0, 0x80, 0x0	@ sfx 17
	.word	pcm_083AAB3C, 0x14, 0x0, 0x80, 0x0	@ sfx 18
	.word	pcm_083AAB3C, 0x9, 0x0, 0x80, 0x0	@ sfx 19
	.word	pcm_083ABA2C, 0x1A, 0x0, 0x80, 0x0	@ sfx 20
	.word	pcm_083ACD74, 0x10, 0x0, 0x80, 0x0	@ sfx 21
	.word	pcm_083AD970, 0x14, 0x0, 0x80, 0x0	@ sfx 22
	.word	pcm_083AE7C0, 0x21, 0x0, 0x80, 0x0	@ sfx 23
	.word	pcm_083AFF74, 0x2E, 0x0, 0x80, 0x0	@ sfx 24
	.word	pcm_083B20D8, 0x82, 0x0, 0x80, 0x0	@ sfx 25
	.word	pcm_083B7E5C, 0x7F, 0x0, 0x80, 0x0	@ sfx 26
	.word	pcm_083BD968, 0x2A, 0x0, 0x80, 0x0	@ sfx 27
	.word	pcm_083BF794, 0x12, 0x0, 0x80, 0x0	@ sfx 28
	.word	pcm_083C04D8, 0x28, 0x0, 0x80, 0x0	@ sfx 29
	.word	pcm_083C219C, 0x36, 0x0, 0x80, 0x0	@ sfx 30
	.word	pcm_083C489C, 0x4E, 0x83C489C, 0x4E, 0x386C	@ sfx 31
	.word	pcm_083C8108, 0x52, 0x83C8108, 0x52, 0x386C	@ sfx 32
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 33
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 34
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 35
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 36
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 37
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 38
	.word	0, 0x0, 0x0, 0x0, 0x0	@ sfx 39

@ mcSmpInstTable: PCM instrument n -> {pcm, length, flag, pad}.  flag == 1: one-shot;
@ any other value: loop from offset 0.  The mix reads up to (length - 4).
	.global mcSmpInstTable
mcSmpInstTable:				@ 083CBEEC
	.word	pcm_08346CF8, 0x450, 1, 0	@ inst 0
	.word	pcm_08347148, 0x68C, 1, 0	@ inst 1
	.word	pcm_083479D4, 0x1EDC, 1, 0	@ inst 2
	.word	pcm_083499B0, 0xC54, 1, 0	@ inst 3
	.word	pcm_0834A704, 0x3F50, 1, 0	@ inst 4
	.word	pcm_0834E754, 0x5D30, 1, 0	@ inst 5
	.word	pcm_08354584, 0x3A60, 1, 0	@ inst 6
	.word	pcm_083580E4, 0x19F0, 1, 0	@ inst 7
	.word	pcm_08359B14, 0x14A0, 1, 0	@ inst 8
	.word	pcm_0835AFF4, 0x5544, 1, 0	@ inst 9
	.word	pcm_0835B1E8, 0xC00, 1, 0	@ inst 10
	.word	pcm_0835BF94, 0xC00, 1, 0	@ inst 11
	.word	pcm_0835D31C, 0xC00, 1, 0	@ inst 12
	.word	pcm_0835E2BC, 0xC00, 1, 0	@ inst 13
	.word	pcm_0835F450, 0xC00, 1, 0	@ inst 14
	.word	pcm_0835FE14, 0x500, 1, 0	@ inst 15
	.word	pcm_08360638, 0x17124, 1, 0	@ inst 16
	.word	pcm_08360638, 0x50C, 1, 0	@ inst 17
	.word	pcm_0836AD94, 0x5FF, 1, 0	@ inst 18
	.word	pcm_0835B1E8, 0x400, 1, 0	@ inst 19
	.word	pcm_0835BF94, 0x400, 1, 0	@ inst 20
	.word	pcm_0835D31C, 0x400, 1, 0	@ inst 21
	.word	pcm_0835E2BC, 0x400, 1, 0	@ inst 22
	.word	pcm_0835F450, 0x400, 1, 0	@ inst 23
	.word	pcm_0835FE14, 0x400, 1, 0	@ inst 24
	.word	pcm_0837775C, 0xC660, 1, 0	@ inst 25
	.word	pcm_08383EBC, 0x50C0, 1, 0	@ inst 26
	.word	pcm_08388F7C, 0x50C0, 1, 0	@ inst 27
	.word	pcm_0838E03C, 0x5614, 1, 0	@ inst 28
	.word	pcm_08393650, 0xE48, 1, 0	@ inst 29
	.word	pcm_0834A704, 0x880, 1, 0	@ inst 30
	.word	0, 0x0, 0, 0	@ inst 31

@ mcPsgSfxMap: PSG effect n -> 4 script numbers (0xFF = none).  mcPlayPsgSfx has no callers.
	.global mcPsgSfxMap
mcPsgSfxMap:				@ 083CC0EC
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

psgScript_09:				@ 083CC12C  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0005, 0x0080, 0x00A1, 0x0084, 0x00B6
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_10:				@ 083CC144  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00BA
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_11:				@ 083CC15C  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0014, 0x0000, 0x0020, 0x0084, 0x00B6
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_06:				@ 083CC174  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0014
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_07:				@ 083CC18C  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x0089
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_08:				@ 083CC1A4  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0030, 0x0000, 0x0080, 0x0084, 0x004F
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_04:				@ 083CC1BC  channel 3   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	3
	.hword	0x0014, 0x0000, 0x002A, 0x0080, 0x0021
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_05:				@ 083CC1D4  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0006, 0x0080, 0x00C3, 0x0087, 0x0014
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_00:				@ 083CC1EC  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_01:				@ 083CC20C  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_02:				@ 083CC22C  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_03:				@ 083CC24C  channel 3   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	3
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

	.global mcPsgSfxScripts
mcPsgSfxScripts:				@ 083CC26C
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
	.word	0
	.word	0
	.word	0
	.word	0
@ 083CC2AC-083CC3AC: 256 bytes, unreferenced table of {value, 0x88/0x89} word pairs
	.byte	0x00, 0x08, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0xFF, 0x07, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00
	.byte	0xFE, 0x07, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0xFD, 0x07, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00
	.byte	0xFC, 0x07, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0xFB, 0x07, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00
	.byte	0xFA, 0x07, 0x00, 0x00, 0x88, 0x00, 0x00, 0x00, 0xF9, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00
	.byte	0xF8, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00, 0xF7, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00
	.byte	0xF6, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00, 0xF5, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00
	.byte	0xF4, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00, 0xF3, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00
	.byte	0xF2, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00, 0xF1, 0x07, 0x00, 0x00, 0x89, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
	.byte	0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

@ note-length table (length index -> ticks); every song uses this one
durTable0:				@ 083CC3AC
	.word	  3,   4,   6,   9,  12,  18,  24,  36	@ [0..7]
	.word	 48,  72,  96, 144, 192,   8,  16,  32	@ [8..15]
	.word	 40,  64,  80,  84,  15,  54,  60,  42	@ [16..23]
	.word	 30, 108, 132, 156,   2, 120,  28,  21	@ [24..31]
	.word	 51,  33, 168, 1536, 288, 384, 624, 216	@ [32..39]
	.word	 90, 102,  66,   1, 180,  56,  20,   3	@ [40..47]
	.word	  4,   6,   9,  12,  18,  24,  36,  48	@ [48..55]
	.word	 72,  96, 144, 192,   8,  16,  32,  10	@ [56..63]
	.word	 40	@ [64..64]

@ ----------------------------------------------------------------------------
@ patterns: {note, instrument, length-index} events, 0x65 = end.  Note names assume
@ index 0 = C#2 on the PSG channels; on channels 5-8 the note selects a resampling step.
@ ----------------------------------------------------------------------------
pat_083CC4B0:				@ used by s1c1, s1c2, s1c3, s1c4, s2c3, s3c1, s3c2, s3c3, s3c4, s4c2, s4c3, s5c2, s5c3, s6c2, s6c3, s7c2, s7c3, s8c3, s9c2, s9c3
	N	60, 0, 10		@ C#7
	PAT_END

pat_083CC4B4:				@ used by s0c1, s0c2, s0c3, s0c4, s4c2, s4c3, s5c2, s5c3, s6c2, s6c3, s7c2, s7c3, s8c3, s9c2, s9c3
	N	60, 0, 0		@ C#7
	PAT_END

pat_083CC4B8:				@ used by s0c5, s0c6, s0c7, s0c8, s1c6, s1c7, s2c7, s2c8, s3c5, s4c5, s8c5, s9c5
	N	48, 0, 10		@ C#6
	PAT_END

pat_083CC4BC:				@ used by s9c1
	N	45, 19, 6		@ A#5
	N	45, 19, 5		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 5		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	PAT_END

pat_083CC4E7:				@ used by s9c1
	N	38, 21, 6		@ D#5
	N	38, 21, 5		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 2		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 2		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 2		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 2		@ D#5
	N	38, 21, 2		@ D#5
	N	38, 21, 4		@ D#5
	PAT_END

pat_083CC518:				@ used by s9c1
	N	45, 25, 6		@ A#5
	N	43, 22, 6		@ G#5
	N	41, 22, 6		@ F#5
	N	40, 25, 6		@ F5
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 2		@ D#5
	N	38, 19, 4		@ D#5
	N	40, 25, 8		@ F5
	REST	0, 2
	N	45, 25, 6		@ A#5
	N	43, 22, 6		@ G#5
	N	41, 22, 6		@ F#5
	N	40, 25, 6		@ F5
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 2		@ D#5
	N	38, 19, 4		@ D#5
	N	45, 25, 8		@ A#5
	REST	0, 2
	PAT_END

pat_083CC555:				@ used by s9c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	PAT_END

pat_083CC5B6:				@ used by s9c5
	N	57, 25, 7		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 23		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	64, 25, 23		@ F7
	N	64, 25, 2		@ F7
	N	65, 25, 2		@ F#7
	N	67, 25, 4		@ G#7
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	65, 25, 2		@ F#7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 6		@ F7
	N	62, 25, 5		@ D#7
	N	60, 25, 24		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	62, 25, 22		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	57, 25, 7		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 5		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 7		@ F7
	N	65, 25, 2		@ F#7
	N	62, 25, 5		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	57, 25, 7		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 5		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 6		@ F7
	N	57, 25, 7		@ A#6
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	57, 25, 4		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 5		@ A#6
	N	52, 25, 4		@ F6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	57, 25, 7		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 5		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 10		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	59, 25, 2		@ C7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	59, 25, 2		@ C7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	59, 25, 2		@ C7
	N	67, 25, 2		@ G#7
	N	64, 25, 4		@ F7
	N	59, 25, 4		@ C7
	N	65, 25, 7		@ F#7
	N	67, 25, 2		@ G#7
	N	69, 25, 5		@ A#7
	N	67, 25, 4		@ G#7
	N	65, 25, 4		@ F#7
	N	64, 25, 4		@ F7
	N	65, 25, 2		@ F#7
	N	67, 25, 2		@ G#7
	N	65, 25, 2		@ F#7
	N	64, 25, 2		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 5		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	62, 25, 6		@ D#7
	N	60, 25, 6		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 2		@ C#7
	N	57, 25, 5		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 7		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 5		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 6		@ F7
	N	71, 25, 7		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	59, 25, 2		@ C7
	N	64, 25, 2		@ F7
	N	59, 25, 6		@ C7
	N	55, 25, 6		@ G#6
	N	52, 25, 5		@ F6
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 12		@ A#6
	PAT_END

pat_083CC75B:				@ used by s9c5
	N	57, 25, 4		@ A#6
	N	64, 25, 4		@ F7
	N	64, 25, 4		@ F7
	N	65, 25, 2		@ F#7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	57, 25, 4		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 21		@ A#6
	N	69, 25, 4		@ A#7
	N	62, 25, 2		@ D#7
	N	62, 25, 2		@ D#7
	N	61, 25, 4		@ D7
	N	62, 25, 4		@ D#7
	N	69, 25, 4		@ A#7
	N	71, 25, 4		@ C8
	N	72, 25, 4		@ C#8
	N	74, 25, 2		@ D#8
	N	72, 25, 23		@ C#8
	N	71, 25, 2		@ C8
	N	69, 25, 5		@ A#7
	N	67, 25, 4		@ G#7
	N	69, 25, 4		@ A#7
	N	71, 25, 4		@ C8
	N	69, 25, 6		@ A#7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	60, 25, 5		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	64, 25, 2		@ F7
	N	64, 25, 2		@ F7
	N	64, 25, 4		@ F7
	N	63, 25, 2		@ E7
	N	64, 25, 21		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	64, 25, 4		@ F7
	N	76, 25, 2		@ F8
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	76, 25, 2		@ F8
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	76, 25, 2		@ F8
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	76, 25, 2		@ F8
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	76, 25, 2		@ F8
	N	71, 25, 2		@ C8
	N	67, 25, 2		@ G#7
	N	76, 25, 2		@ F8
	N	74, 25, 4		@ D#8
	N	69, 25, 2		@ A#7
	N	65, 25, 2		@ F#7
	N	74, 25, 2		@ D#8
	N	69, 25, 2		@ A#7
	N	65, 25, 2		@ F#7
	N	69, 25, 4		@ A#7
	N	65, 25, 2		@ F#7
	N	62, 25, 2		@ D#7
	N	64, 25, 2		@ F7
	N	65, 25, 4		@ F#7
	N	67, 25, 4		@ G#7
	N	69, 25, 24		@ A#7
	N	70, 25, 2		@ B7
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	65, 25, 4		@ F#7
	N	64, 25, 4		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	64, 25, 4		@ F7
	N	57, 25, 2		@ A#6
	N	57, 25, 2		@ A#6
	N	56, 25, 4		@ A6
	N	57, 25, 4		@ A#6
	N	64, 25, 4		@ F7
	N	57, 25, 2		@ A#6
	N	57, 25, 2		@ A#6
	N	56, 25, 4		@ A6
	N	57, 25, 4		@ A#6
	N	64, 25, 24		@ F7
	N	65, 25, 2		@ F#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 6		@ C#7
	N	64, 25, 7		@ F7
	N	67, 25, 2		@ G#7
	N	71, 25, 2		@ C8
	N	76, 25, 22		@ F8
	N	74, 25, 4		@ D#8
	N	72, 25, 4		@ C#8
	N	71, 25, 2		@ C8
	N	72, 25, 5		@ C#8
	N	71, 25, 4		@ C8
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	69, 25, 9		@ A#7
	N	67, 25, 4		@ G#7
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	69, 25, 10		@ A#7
	PAT_END

pat_083CC8D6:				@ used by s9c5
	N	64, 25, 6		@ F7
	N	62, 25, 6		@ D#7
	N	60, 25, 6		@ C#7
	N	59, 25, 6		@ C7
	N	57, 25, 4		@ A#6
	N	57, 25, 4		@ A#6
	N	57, 25, 2		@ A#6
	N	57, 25, 4		@ A#6
	N	59, 25, 21		@ C7
	N	64, 25, 6		@ F7
	N	62, 25, 6		@ D#7
	N	60, 25, 6		@ C#7
	N	59, 25, 6		@ C7
	N	57, 25, 4		@ A#6
	N	57, 25, 4		@ A#6
	N	57, 25, 2		@ A#6
	N	57, 25, 5		@ A#6
	N	52, 25, 8		@ F6
	PAT_END

pat_083CC90D:				@ used by s9c7
	N	57, 25, 6		@ A#6
	N	55, 25, 6		@ G#6
	N	53, 25, 6		@ F#6
	N	52, 25, 6		@ F6
	N	50, 25, 4		@ D#6
	N	50, 25, 4		@ D#6
	N	50, 25, 2		@ D#6
	N	50, 25, 4		@ D#6
	N	52, 25, 21		@ F6
	N	57, 25, 6		@ A#6
	N	55, 25, 6		@ G#6
	N	53, 25, 6		@ F#6
	N	52, 25, 6		@ F6
	N	50, 25, 4		@ D#6
	N	50, 25, 4		@ D#6
	N	50, 25, 2		@ D#6
	N	50, 25, 5		@ D#6
	N	45, 25, 8		@ A#5
	PAT_END

pat_083CC944:				@ used by s9c5
	N	45, 25, 4		@ A#5
	N	52, 25, 4		@ F6
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	52, 25, 4		@ F6
	N	45, 25, 4		@ A#5
	N	52, 25, 4		@ F6
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	56, 25, 4		@ A6
	N	55, 25, 4		@ G#6
	N	54, 25, 4		@ G6
	N	53, 25, 6		@ F#6
	N	48, 25, 4		@ C#6
	N	53, 25, 4		@ F#6
	N	56, 25, 6		@ A6
	N	53, 25, 4		@ F#6
	N	56, 25, 4		@ A6
	N	60, 25, 6		@ C#7
	N	56, 25, 4		@ A6
	N	60, 25, 4		@ C#7
	N	64, 25, 6		@ F7
	N	65, 25, 6		@ F#7
	N	64, 25, 6		@ F7
	N	60, 25, 4		@ C#7
	N	64, 25, 4		@ F7
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	56, 25, 4		@ A6
	N	55, 25, 4		@ G#6
	N	54, 25, 4		@ G6
	N	53, 25, 6		@ F#6
	N	56, 25, 6		@ A6
	N	60, 25, 6		@ C#7
	N	61, 25, 6		@ D7
	N	60, 25, 10		@ C#7
	N	62, 25, 4		@ D#7
	N	57, 25, 2		@ A#6
	N	62, 25, 2		@ D#7
	N	65, 25, 4		@ F#7
	N	62, 25, 2		@ D#7
	N	65, 25, 2		@ F#7
	N	69, 25, 7		@ A#7
	N	67, 25, 4		@ G#7
	N	65, 25, 6		@ F#7
	N	64, 25, 6		@ F7
	N	62, 25, 6		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	58, 25, 8		@ B6
	N	53, 25, 6		@ F#6
	N	61, 25, 6		@ D7
	N	58, 25, 6		@ B6
	N	65, 25, 6		@ F#7
	N	61, 25, 6		@ D7
	N	58, 25, 6		@ B6
	N	62, 25, 7		@ D#7
	N	57, 25, 2		@ A#6
	N	62, 25, 2		@ D#7
	N	65, 25, 7		@ F#7
	N	62, 25, 2		@ D#7
	N	65, 25, 2		@ F#7
	N	69, 25, 6		@ A#7
	N	67, 25, 6		@ G#7
	N	65, 25, 6		@ F#7
	N	61, 25, 6		@ D7
	N	62, 25, 9		@ D#7
	REST	0, 2
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	65, 25, 2		@ F#7
	N	62, 25, 10		@ D#7
	PAT_END

pat_083CCA3E:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	PAT_END

pat_083CCA8D:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	52, 30, 2		@ F6
	N	55, 30, 2		@ G#6
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	36, 30, 2		@ C#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	36, 30, 2		@ C#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	52, 30, 2		@ F6
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	PAT_END

pat_083CCADC:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	52, 30, 2		@ F6
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	45, 30, 2		@ A#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	52, 30, 2		@ F6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	47, 30, 4		@ C6
	N	45, 30, 4		@ A#5
	N	40, 30, 2		@ F5
	N	45, 30, 2		@ A#5
	N	47, 30, 2		@ C6
	N	48, 30, 2		@ C#6
	N	49, 30, 2		@ D6
	PAT_END

pat_083CCB2B:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	52, 30, 2		@ F6
	N	55, 30, 2		@ G#6
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	36, 30, 2		@ C#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	36, 30, 2		@ C#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	45, 30, 2		@ A#5
	N	43, 30, 2		@ G#5
	N	42, 30, 2		@ G5
	PAT_END

pat_083CCB7A:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	52, 30, 2		@ F6
	N	40, 30, 2		@ F5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	36, 30, 2		@ C#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	36, 30, 2		@ C#5
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	45, 30, 2		@ A#5
	N	48, 30, 2		@ C#6
	N	50, 30, 2		@ D#6
	N	51, 30, 2		@ E6
	PAT_END

pat_083CCBC9:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	43, 30, 2		@ G#5
	N	38, 30, 2		@ D#5
	N	42, 30, 2		@ G5
	N	43, 30, 4		@ G#5
	N	41, 30, 4		@ F#5
	N	53, 30, 2		@ F#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	40, 30, 2		@ F5
	N	50, 30, 4		@ D#6
	N	53, 30, 2		@ F#6
	N	53, 30, 2		@ F#6
	N	45, 30, 2		@ A#5
	N	45, 30, 2		@ A#5
	N	48, 30, 2		@ C#6
	N	50, 30, 4		@ D#6
	N	47, 30, 4		@ C6
	N	47, 30, 2		@ C6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	47, 30, 2		@ C6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	43, 30, 2		@ G#5
	N	38, 30, 2		@ D#5
	N	42, 30, 2		@ G5
	N	43, 30, 4		@ G#5
	N	41, 30, 4		@ F#5
	N	53, 30, 2		@ F#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	40, 30, 2		@ F5
	N	50, 30, 4		@ D#6
	N	53, 30, 2		@ F#6
	N	53, 30, 2		@ F#6
	N	45, 30, 2		@ A#5
	N	45, 30, 2		@ A#5
	N	48, 30, 2		@ C#6
	N	50, 30, 4		@ D#6
	N	45, 30, 4		@ A#5
	N	45, 30, 2		@ A#5
	N	40, 30, 2		@ F5
	N	48, 30, 2		@ C#6
	N	52, 30, 2		@ F6
	N	45, 30, 2		@ A#5
	PAT_END

pat_083CCC66:				@ used by s9c6
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	N	45, 30, 4		@ A#5
	N	48, 30, 2		@ C#6
	N	48, 30, 2		@ C#6
	N	40, 30, 2		@ F5
	N	40, 30, 2		@ F5
	N	43, 30, 2		@ G#5
	N	45, 30, 4		@ A#5
	N	48, 30, 4		@ C#6
	N	48, 30, 2		@ C#6
	N	45, 30, 2		@ A#5
	N	44, 30, 2		@ A5
	N	43, 30, 2		@ G#5
	N	42, 30, 2		@ G5
	PAT_END

pat_083CCCB5:				@ used by s9c6
	N	41, 30, 4		@ F#5
	N	44, 30, 2		@ A5
	N	44, 30, 2		@ A5
	N	36, 30, 2		@ C#5
	N	48, 30, 2		@ C#6
	N	51, 30, 2		@ E6
	N	41, 30, 4		@ F#5
	N	44, 30, 4		@ A5
	N	32, 30, 2		@ A4
	N	36, 30, 2		@ C#5
	N	36, 30, 2		@ C#5
	N	39, 30, 2		@ E5
	N	40, 30, 2		@ F5
	N	41, 30, 4		@ F#5
	N	44, 30, 2		@ A5
	N	32, 30, 2		@ A4
	N	36, 30, 2		@ C#5
	N	36, 30, 2		@ C#5
	N	39, 30, 2		@ E5
	N	41, 30, 4		@ F#5
	N	44, 30, 4		@ A5
	N	44, 30, 2		@ A5
	N	41, 30, 2		@ F#5
	N	42, 30, 2		@ G5
	N	43, 30, 2		@ G#5
	N	44, 30, 2		@ A5
	PAT_END

pat_083CCD04:				@ used by s9c7
	N	48, 1, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 1, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	PAT_END

pat_083CCD74:				@ used by s9c7
	N	48, 1, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 4		@ C#6
	N	48, 1, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 1, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	PAT_END

pat_083CCDA8:				@ used by s9c8
	N	47, 28, 10		@ C6
	N	47, 28, 10		@ C6
	PAT_END

pat_083CCDAF:				@ used by s8c1
	N	43, 25, 12		@ G#5
	N	38, 23, 12		@ D#5
	PAT_END

pat_083CCDB6:				@ used by s8c1
	N	43, 25, 8		@ G#5
	N	38, 23, 8		@ D#5
	N	38, 26, 8		@ D#5
	N	36, 23, 8		@ C#5
	N	36, 26, 8		@ C#5
	N	31, 27, 8		@ G#4
	N	45, 22, 8		@ A#5
	N	38, 24, 8		@ D#5
	PAT_END

pat_083CCDCF:				@ used by s8c1
	N	36, 27, 10		@ C#5
	N	36, 27, 10		@ C#5
	N	44, 25, 10		@ A5
	N	44, 25, 10		@ A5
	N	36, 27, 10		@ C#5
	N	36, 27, 10		@ C#5
	N	39, 26, 10		@ E5
	N	39, 26, 10		@ E5
	PAT_END

pat_083CCDE8:				@ used by s8c1
	N	43, 25, 8		@ G#5
	N	39, 26, 8		@ E5
	N	43, 25, 8		@ G#5
	N	39, 26, 8		@ E5
	N	44, 25, 8		@ A5
	N	40, 23, 8		@ F5
	N	44, 25, 8		@ A5
	N	40, 23, 8		@ F5
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	PAT_END

pat_083CCE19:				@ used by s8c1
	N	45, 25, 10		@ A#5
	N	38, 27, 10		@ D#5
	N	45, 25, 10		@ A#5
	N	38, 27, 10		@ D#5
	PAT_END

pat_083CCE26:				@ used by s8c1
	N	38, 23, 10		@ D#5
	N	43, 25, 10		@ G#5
	N	38, 23, 10		@ D#5
	N	43, 25, 8		@ G#5
	N	38, 23, 8		@ D#5
	N	43, 25, 10		@ G#5
	N	38, 23, 10		@ D#5
	N	43, 25, 10		@ G#5
	N	38, 23, 10		@ D#5
	PAT_END

pat_083CCE42:				@ used by s8c5
	N	55, 25, 19		@ G#6
	N	57, 25, 2		@ A#6
	N	58, 25, 2		@ B6
	N	63, 25, 8		@ E7
	N	62, 25, 6		@ D#7
	N	61, 25, 6		@ D7
	N	62, 25, 6		@ D#7
	N	50, 25, 4		@ D#6
	N	50, 25, 4		@ D#6
	REST	0, 8
	N	50, 25, 6		@ D#6
	N	38, 25, 4		@ D#5
	N	38, 25, 4		@ D#5
	REST	0, 8
	N	55, 25, 22		@ G#6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	58, 25, 4		@ B6
	N	63, 25, 8		@ E7
	N	62, 25, 6		@ D#7
	N	61, 25, 4		@ D7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	62, 25, 6		@ D#7
	N	50, 25, 4		@ D#6
	N	50, 25, 4		@ D#6
	REST	0, 8
	N	50, 25, 6		@ D#6
	N	38, 25, 4		@ D#5
	N	38, 25, 4		@ D#5
	REST	0, 8
	PAT_END

pat_083CCEA0:				@ used by s8c5
	N	67, 5, 6		@ G#7
	N	66, 5, 4		@ G7
	N	67, 5, 4		@ G#7
	N	63, 5, 6		@ E7
	N	62, 5, 4		@ D#7
	N	63, 5, 4		@ E7
	N	60, 5, 6		@ C#7
	N	62, 5, 4		@ D#7
	N	63, 5, 6		@ E7
	N	62, 5, 4		@ D#7
	N	60, 5, 6		@ C#7
	N	62, 5, 6		@ D#7
	N	55, 5, 4		@ G#6
	N	55, 5, 4		@ G#6
	REST	0, 8
	N	55, 5, 6		@ G#6
	N	43, 5, 4		@ G#5
	N	43, 5, 4		@ G#5
	REST	0, 8
	N	67, 5, 4		@ G#7
	N	68, 5, 2		@ A7
	N	67, 5, 2		@ G#7
	N	66, 5, 4		@ G7
	N	67, 5, 4		@ G#7
	N	63, 5, 4		@ E7
	N	65, 5, 4		@ F#7
	N	62, 5, 4		@ D#7
	N	63, 5, 4		@ E7
	N	60, 5, 4		@ C#7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	65, 5, 4		@ F#7
	N	67, 5, 2		@ G#7
	N	65, 5, 2		@ F#7
	N	63, 5, 4		@ E7
	N	62, 5, 4		@ D#7
	N	60, 5, 4		@ C#7
	N	63, 5, 4		@ E7
	N	62, 5, 6		@ D#7
	N	55, 5, 4		@ G#6
	N	55, 5, 4		@ G#6
	REST	0, 8
	N	55, 5, 6		@ G#6
	N	43, 5, 4		@ G#5
	N	43, 5, 4		@ G#5
	REST	0, 8
	PAT_END

pat_083CCF2B:				@ used by s8c5
	N	55, 25, 4		@ G#6
	N	55, 25, 4		@ G#6
	N	63, 25, 4		@ E7
	N	63, 25, 4		@ E7
	N	62, 25, 4		@ D#7
	N	62, 25, 4		@ D#7
	N	54, 25, 4		@ G6
	N	54, 25, 4		@ G6
	N	53, 25, 4		@ F#6
	N	53, 25, 4		@ F#6
	N	62, 25, 4		@ D#7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	60, 25, 4		@ C#7
	N	52, 25, 4		@ F6
	N	52, 25, 4		@ F6
	N	51, 25, 4		@ E6
	N	51, 25, 4		@ E6
	N	60, 25, 4		@ C#7
	N	60, 25, 4		@ C#7
	N	58, 25, 4		@ B6
	N	58, 25, 4		@ B6
	N	50, 25, 4		@ D#6
	N	50, 25, 4		@ D#6
	N	49, 25, 4		@ D6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	55, 25, 4		@ G#6
	N	54, 25, 8		@ G6
	N	55, 25, 4		@ G#6
	N	55, 25, 4		@ G#6
	N	63, 25, 4		@ E7
	N	63, 25, 4		@ E7
	N	62, 25, 4		@ D#7
	N	62, 25, 4		@ D#7
	N	54, 25, 4		@ G6
	N	54, 25, 4		@ G6
	N	53, 25, 4		@ F#6
	N	53, 25, 4		@ F#6
	N	62, 25, 4		@ D#7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	60, 25, 4		@ C#7
	N	52, 25, 4		@ F6
	N	52, 25, 4		@ F6
	N	51, 25, 4		@ E6
	N	51, 25, 4		@ E6
	N	60, 25, 4		@ C#7
	N	60, 25, 4		@ C#7
	N	58, 25, 4		@ B6
	N	58, 25, 4		@ B6
	N	50, 25, 4		@ D#6
	N	50, 25, 4		@ D#6
	N	49, 25, 4		@ D6
	N	52, 25, 4		@ F6
	N	57, 25, 4		@ A#6
	N	63, 25, 4		@ E7
	N	62, 25, 8		@ D#7
	PAT_END

pat_083CCFDA:				@ used by s8c5
	N	48, 25, 19		@ C#6
	N	51, 25, 2		@ E6
	N	55, 25, 2		@ G#6
	N	56, 25, 8		@ A6
	N	55, 25, 8		@ G#6
	N	54, 25, 4		@ G6
	N	56, 25, 4		@ A6
	N	54, 25, 4		@ G6
	N	53, 25, 4		@ F#6
	N	54, 25, 11		@ G6
	N	48, 25, 19		@ C#6
	N	51, 25, 2		@ E6
	N	55, 25, 2		@ G#6
	N	63, 25, 8		@ E7
	N	60, 25, 8		@ C#7
	N	58, 25, 4		@ B6
	N	59, 25, 4		@ C7
	N	58, 25, 4		@ B6
	N	56, 25, 4		@ A6
	N	58, 25, 11		@ B6
	PAT_END

pat_083CD017:				@ used by s8c5
	N	58, 25, 4		@ B6
	N	55, 25, 4		@ G#6
	N	58, 25, 4		@ B6
	N	55, 25, 4		@ G#6
	N	58, 25, 4		@ B6
	N	54, 25, 4		@ G6
	N	58, 25, 4		@ B6
	N	54, 25, 4		@ G6
	N	58, 25, 4		@ B6
	N	55, 25, 4		@ G#6
	N	58, 25, 4		@ B6
	N	55, 25, 4		@ G#6
	N	58, 25, 4		@ B6
	N	54, 25, 4		@ G6
	N	58, 25, 4		@ B6
	N	54, 25, 4		@ G6
	N	59, 25, 4		@ C7
	N	56, 25, 4		@ A6
	N	59, 25, 4		@ C7
	N	56, 25, 4		@ A6
	N	62, 25, 4		@ D#7
	N	56, 25, 4		@ A6
	N	62, 25, 4		@ D#7
	N	56, 25, 4		@ A6
	N	63, 25, 4		@ E7
	N	56, 25, 4		@ A6
	N	63, 25, 4		@ E7
	N	56, 25, 4		@ A6
	N	64, 25, 4		@ F7
	N	56, 25, 4		@ A6
	N	64, 25, 4		@ F7
	N	56, 25, 4		@ A6
	N	64, 25, 4		@ F7
	N	60, 25, 4		@ C#7
	N	64, 25, 4		@ F7
	N	60, 25, 4		@ C#7
	N	63, 25, 4		@ E7
	N	59, 25, 4		@ C7
	N	63, 25, 4		@ E7
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	56, 25, 4		@ A6
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	64, 25, 4		@ F7
	N	60, 25, 4		@ C#7
	N	64, 25, 4		@ F7
	N	60, 25, 4		@ C#7
	N	63, 25, 4		@ E7
	N	59, 25, 4		@ C7
	N	63, 25, 4		@ E7
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	60, 25, 4		@ C#7
	N	59, 25, 8		@ C7
	PAT_END

pat_083CD0CF:				@ used by s8c5
	N	52, 5, 4		@ F6
	N	55, 5, 2		@ G#6
	N	56, 5, 2		@ A6
	N	57, 5, 4		@ A#6
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	64, 5, 2		@ F7
	N	67, 5, 2		@ G#7
	N	68, 5, 2		@ A7
	N	69, 5, 4		@ A#7
	N	67, 5, 2		@ G#7
	N	69, 5, 2		@ A#7
	N	72, 5, 4		@ C#8
	N	69, 5, 4		@ A#7
	N	67, 5, 2		@ G#7
	N	64, 5, 4		@ F7
	N	67, 5, 4		@ G#7
	N	69, 5, 2		@ A#7
	N	72, 5, 2		@ C#8
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	57, 5, 5		@ A#6
	N	55, 5, 2		@ G#6
	N	57, 5, 4		@ A#6
	N	60, 5, 2		@ C#7
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	52, 5, 2		@ F6
	N	55, 5, 2		@ G#6
	N	56, 5, 2		@ A6
	N	57, 5, 2		@ A#6
	N	60, 5, 4		@ C#7
	N	64, 5, 4		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 4		@ C#7
	N	59, 5, 4		@ C7
	N	60, 5, 2		@ C#7
	N	57, 5, 24		@ A#6
	N	52, 5, 2		@ F6
	N	55, 5, 2		@ G#6
	N	56, 5, 2		@ A6
	N	57, 5, 2		@ A#6
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	64, 5, 2		@ F7
	N	67, 5, 2		@ G#7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	69, 5, 2		@ A#7
	N	72, 5, 2		@ C#8
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	64, 5, 2		@ F7
	N	67, 5, 2		@ G#7
	N	68, 5, 2		@ A7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	57, 5, 5		@ A#6
	N	55, 5, 4		@ G#6
	N	57, 5, 4		@ A#6
	N	60, 5, 2		@ C#7
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	52, 5, 2		@ F6
	N	55, 5, 2		@ G#6
	N	56, 5, 2		@ A6
	N	57, 5, 2		@ A#6
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	64, 5, 2		@ F7
	N	67, 5, 2		@ G#7
	N	68, 5, 4		@ A7
	N	69, 5, 4		@ A#7
	N	69, 5, 4		@ A#7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	64, 5, 22		@ F7
	PAT_END

pat_083CD1EA:				@ used by s8c5
	N	50, 5, 5		@ D#6
	N	52, 5, 2		@ F6
	N	54, 5, 4		@ G6
	N	57, 5, 4		@ A#6
	N	62, 5, 4		@ D#7
	N	64, 5, 4		@ F7
	N	66, 5, 4		@ G7
	N	62, 5, 4		@ D#7
	N	67, 5, 7		@ G#7
	N	69, 5, 2		@ A#7
	N	70, 5, 5		@ B7
	N	69, 5, 4		@ A#7
	N	67, 5, 4		@ G#7
	N	70, 5, 4		@ B7
	N	69, 5, 2		@ A#7
	N	70, 5, 2		@ B7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	66, 5, 4		@ G7
	N	64, 5, 4		@ F7
	N	62, 5, 4		@ D#7
	N	60, 5, 4		@ C#7
	N	58, 5, 4		@ B6
	N	57, 5, 4		@ A#6
	N	58, 5, 4		@ B6
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	60, 5, 4		@ C#7
	N	58, 5, 2		@ B6
	N	55, 5, 2		@ G#6
	N	57, 5, 4		@ A#6
	N	58, 5, 2		@ B6
	N	60, 5, 2		@ C#7
	N	58, 5, 4		@ B6
	N	57, 5, 4		@ A#6
	N	55, 5, 2		@ G#6
	N	58, 5, 2		@ B6
	N	62, 5, 2		@ D#7
	N	55, 5, 2		@ G#6
	N	58, 5, 2		@ B6
	N	62, 5, 2		@ D#7
	N	55, 5, 2		@ G#6
	N	58, 5, 2		@ B6
	N	62, 5, 2		@ D#7
	N	55, 5, 2		@ G#6
	N	58, 5, 2		@ B6
	N	62, 5, 2		@ D#7
	N	55, 5, 2		@ G#6
	N	58, 5, 2		@ B6
	N	62, 5, 2		@ D#7
	N	62, 5, 5		@ D#7
	N	57, 5, 4		@ A#6
	N	54, 5, 4		@ G6
	N	57, 5, 2		@ A#6
	N	50, 5, 21		@ D#6
	N	62, 5, 2		@ D#7
	N	58, 5, 2		@ B6
	N	55, 5, 2		@ G#6
	N	62, 5, 2		@ D#7
	N	58, 5, 2		@ B6
	N	55, 5, 2		@ G#6
	N	62, 5, 2		@ D#7
	N	58, 5, 2		@ B6
	N	55, 5, 2		@ G#6
	N	62, 5, 2		@ D#7
	N	58, 5, 2		@ B6
	N	55, 5, 2		@ G#6
	N	62, 5, 2		@ D#7
	N	58, 5, 2		@ B6
	N	55, 5, 2		@ G#6
	N	62, 5, 5		@ D#7
	N	57, 5, 4		@ A#6
	N	54, 5, 4		@ G6
	N	57, 5, 2		@ A#6
	N	50, 5, 21		@ D#6
	PAT_END

pat_083CD2CC:				@ used by s8c2, s8c6
	REST	0, 0
	PAT_END

pat_083CD2D0:				@ used by s8c2, s8c6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	79, 29, 2		@ G#8
	N	74, 29, 2		@ D#8
	N	70, 29, 2		@ B7
	N	69, 29, 2		@ A#7
	N	67, 29, 2		@ G#7
	N	62, 29, 2		@ D#7
	N	58, 29, 2		@ B6
	N	57, 29, 2		@ A#6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	79, 29, 2		@ G#8
	N	74, 29, 2		@ D#8
	N	70, 29, 2		@ B7
	N	69, 29, 2		@ A#7
	N	67, 29, 2		@ G#7
	N	62, 29, 2		@ D#7
	N	58, 29, 2		@ B6
	N	57, 29, 2		@ A#6
	N	54, 29, 2		@ G6
	N	57, 29, 2		@ A#6
	N	62, 29, 2		@ D#7
	N	64, 29, 2		@ F7
	N	66, 29, 2		@ G7
	N	69, 29, 2		@ A#7
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	78, 29, 2		@ G8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	57, 29, 2		@ A#6
	N	54, 29, 2		@ G6
	N	57, 29, 2		@ A#6
	N	62, 29, 2		@ D#7
	N	64, 29, 2		@ F7
	N	66, 29, 2		@ G7
	N	69, 29, 2		@ A#7
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	78, 29, 2		@ G8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	57, 29, 2		@ A#6
	PAT_END

pat_083CD391:				@ used by s8c2, s8c6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	78, 29, 2		@ G8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	57, 29, 2		@ A#6
	N	53, 29, 2		@ F#6
	N	57, 29, 2		@ A#6
	N	59, 29, 2		@ C7
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	71, 29, 2		@ C8
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	67, 29, 2		@ G#7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	60, 29, 2		@ C#7
	N	55, 29, 2		@ G#6
	N	51, 29, 2		@ E6
	N	55, 29, 2		@ G#6
	N	60, 29, 2		@ C#7
	N	62, 29, 2		@ D#7
	N	63, 29, 2		@ E7
	N	67, 29, 2		@ G#7
	N	72, 29, 2		@ C#8
	N	75, 29, 2		@ E8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	70, 29, 2		@ B7
	N	67, 29, 2		@ G#7
	N	62, 29, 2		@ D#7
	N	60, 29, 2		@ C#7
	N	58, 29, 2		@ B6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	61, 29, 2		@ D7
	N	64, 29, 2		@ F7
	N	69, 29, 2		@ A#7
	N	73, 29, 2		@ D8
	N	76, 29, 2		@ F8
	N	81, 29, 2		@ A#8
	N	74, 29, 2		@ D#8
	N	78, 29, 2		@ G8
	N	74, 29, 2		@ D#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	57, 29, 2		@ A#6
	PAT_END

pat_083CD452:				@ used by s8c2, s8c6
	N	60, 29, 2		@ C#7
	N	62, 29, 2		@ D#7
	N	63, 29, 2		@ E7
	N	67, 29, 2		@ G#7
	N	72, 29, 2		@ C#8
	N	74, 29, 2		@ D#8
	N	75, 29, 2		@ E8
	N	79, 29, 2		@ G#8
	N	84, 29, 2		@ C#9
	N	79, 29, 2		@ G#8
	N	75, 29, 2		@ E8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	67, 29, 2		@ G#7
	N	63, 29, 2		@ E7
	N	62, 29, 2		@ D#7
	PAT_END

pat_083CD483:				@ used by s8c2, s8c6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	75, 29, 2		@ E8
	N	70, 29, 2		@ B7
	N	66, 29, 2		@ G7
	N	65, 29, 2		@ F#7
	N	63, 29, 2		@ E7
	N	58, 29, 2		@ B6
	N	54, 29, 2		@ G6
	N	58, 29, 2		@ B6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	75, 29, 2		@ E8
	N	70, 29, 2		@ B7
	N	66, 29, 2		@ G7
	N	65, 29, 2		@ F#7
	N	63, 29, 2		@ E7
	N	58, 29, 2		@ B6
	N	54, 29, 2		@ G6
	N	58, 29, 2		@ B6
	N	56, 29, 2		@ A6
	N	58, 29, 2		@ B6
	N	59, 29, 2		@ C7
	N	63, 29, 2		@ E7
	N	68, 29, 2		@ A7
	N	70, 29, 2		@ B7
	N	71, 29, 2		@ C8
	N	75, 29, 2		@ E8
	N	76, 29, 2		@ F8
	N	71, 29, 2		@ C8
	N	68, 29, 2		@ A7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	N	59, 29, 2		@ C7
	N	56, 29, 2		@ A6
	N	59, 29, 2		@ C7
	N	56, 29, 2		@ A6
	N	58, 29, 2		@ B6
	N	59, 29, 2		@ C7
	N	63, 29, 2		@ E7
	N	68, 29, 2		@ A7
	N	70, 29, 2		@ B7
	N	71, 29, 2		@ C8
	N	75, 29, 2		@ E8
	N	76, 29, 2		@ F8
	N	71, 29, 2		@ C8
	N	68, 29, 2		@ A7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	N	59, 29, 2		@ C7
	N	56, 29, 2		@ A6
	N	59, 29, 2		@ C7
	PAT_END

pat_083CD544:				@ used by s8c2, s8c6
	N	57, 29, 2		@ A#6
	N	59, 29, 2		@ C7
	N	60, 29, 2		@ C#7
	N	64, 29, 2		@ F7
	N	69, 29, 2		@ A#7
	N	71, 29, 2		@ C8
	N	72, 29, 2		@ C#8
	N	76, 29, 2		@ F8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	71, 29, 2		@ C8
	N	68, 29, 2		@ A7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	59, 29, 2		@ C7
	N	56, 29, 2		@ A6
	PAT_END

pat_083CD575:				@ used by s8c2, s8c6
	N	62, 29, 2		@ D#7
	N	64, 29, 2		@ F7
	N	66, 29, 2		@ G7
	N	69, 29, 2		@ A#7
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	78, 29, 2		@ G8
	N	81, 29, 2		@ A#8
	N	86, 29, 2		@ D#9
	N	81, 29, 2		@ A#8
	N	78, 29, 2		@ G8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	64, 29, 2		@ F7
	PAT_END

pat_083CD5A6:				@ used by s8c2, s8c6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	79, 29, 2		@ G#8
	N	74, 29, 2		@ D#8
	N	70, 29, 2		@ B7
	N	69, 29, 2		@ A#7
	N	67, 29, 2		@ G#7
	N	62, 29, 2		@ D#7
	N	58, 29, 2		@ B6
	N	57, 29, 2		@ A#6
	PAT_END

pat_083CD5D7:				@ used by s8c2, s8c6
	N	55, 29, 2		@ G#6
	N	57, 29, 2		@ A#6
	N	58, 29, 2		@ B6
	N	62, 29, 2		@ D#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	70, 29, 2		@ B7
	N	74, 29, 2		@ D#8
	N	78, 29, 2		@ G8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	62, 29, 2		@ D#7
	N	60, 29, 2		@ C#7
	N	57, 29, 2		@ A#6
	PAT_END

pat_083CD608:				@ used by s8c2, s8c6
	N	62, 29, 2		@ D#7
	N	64, 29, 2		@ F7
	N	66, 29, 2		@ G7
	N	69, 29, 2		@ A#7
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	78, 29, 2		@ G8
	N	81, 29, 2		@ A#8
	N	86, 29, 2		@ D#9
	N	81, 29, 2		@ A#8
	N	78, 29, 2		@ G8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	69, 29, 2		@ A#7
	N	66, 29, 2		@ G7
	N	64, 29, 0		@ F7
	PAT_END

pat_083CD639:				@ used by s8c7
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 7		@ G#5
	N	38, 4, 4		@ D#5
	REST	0, 6
	REST	0, 2
	N	38, 4, 2		@ D#5
	N	38, 4, 4		@ D#5
	N	38, 4, 6		@ D#5
	N	36, 4, 4		@ C#5
	N	38, 4, 4		@ D#5
	REST	0, 6
	REST	0, 2
	N	38, 4, 2		@ D#5
	N	38, 4, 4		@ D#5
	N	38, 4, 4		@ D#5
	REST	0, 6
	PAT_END

pat_083CD68E:				@ used by s8c7
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	38, 4, 4		@ D#5
	REST	0, 6
	REST	0, 2
	N	45, 4, 2		@ A#5
	N	50, 4, 2		@ D#6
	N	45, 4, 2		@ A#5
	N	38, 4, 6		@ D#5
	N	36, 4, 4		@ C#5
	N	38, 4, 4		@ D#5
	REST	0, 6
	REST	0, 2
	N	45, 4, 2		@ A#5
	N	50, 4, 2		@ D#6
	N	45, 4, 2		@ A#5
	N	38, 4, 4		@ D#5
	N	36, 4, 4		@ C#5
	N	38, 4, 4		@ D#5
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	46, 4, 4		@ B5
	N	43, 4, 6		@ G#5
	REST	0, 4
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	38, 4, 6		@ D#5
	REST	0, 5
	N	45, 4, 2		@ A#5
	N	50, 4, 2		@ D#6
	N	45, 4, 2		@ A#5
	N	38, 4, 4		@ D#5
	REST	0, 4
	N	36, 4, 4		@ C#5
	N	38, 4, 6		@ D#5
	REST	0, 5
	N	45, 4, 2		@ A#5
	N	50, 4, 4		@ D#6
	N	51, 4, 4		@ E6
	N	48, 4, 4		@ C#6
	N	46, 4, 4		@ B5
	PAT_END

pat_083CD74F:				@ used by s8c7
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	51, 4, 4		@ E6
	N	55, 4, 4		@ G#6
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	51, 4, 4		@ E6
	N	48, 4, 4		@ C#6
	N	43, 4, 4		@ G#5
	REST	0, 24
	N	47, 4, 2		@ C6
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	47, 4, 4		@ C6
	N	50, 4, 4		@ D#6
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	55, 4, 2		@ G#6
	N	43, 4, 4		@ G#5
	N	55, 4, 2		@ G#6
	N	43, 4, 4		@ G#5
	N	55, 4, 4		@ G#6
	N	47, 4, 4		@ C6
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	51, 4, 4		@ E6
	N	55, 4, 4		@ G#6
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	36, 4, 2		@ C#5
	N	48, 4, 2		@ C#6
	N	36, 4, 2		@ C#5
	N	48, 4, 2		@ C#6
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	47, 4, 4		@ C6
	N	50, 4, 4		@ D#6
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	38, 4, 2		@ D#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	55, 4, 2		@ G#6
	N	43, 4, 2		@ G#5
	N	55, 4, 4		@ G#6
	PAT_END

pat_083CD816:				@ used by s8c7
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	50, 4, 2		@ D#6
	N	51, 4, 2		@ E6
	N	54, 4, 4		@ G6
	N	54, 4, 4		@ G6
	REST	0, 6
	N	41, 4, 4		@ F#5
	REST	0, 6
	N	48, 4, 2		@ C#6
	N	51, 4, 2		@ E6
	N	52, 4, 4		@ F6
	N	52, 4, 4		@ F6
	REST	0, 6
	N	39, 4, 4		@ E5
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 6
	N	37, 4, 5		@ D5
	N	37, 4, 2		@ D5
	N	49, 4, 6		@ D6
	N	38, 4, 5		@ D#5
	N	45, 4, 2		@ A#5
	N	50, 4, 2		@ D#6
	N	45, 4, 2		@ A#5
	N	38, 4, 4		@ D#5
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	50, 4, 2		@ D#6
	N	51, 4, 2		@ E6
	N	54, 4, 4		@ G6
	N	54, 4, 4		@ G6
	REST	0, 6
	N	41, 4, 4		@ F#5
	REST	0, 6
	N	48, 4, 2		@ C#6
	N	51, 4, 2		@ E6
	N	52, 4, 4		@ F6
	N	52, 4, 4		@ F6
	REST	0, 6
	N	39, 4, 4		@ E5
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	48, 4, 2		@ C#6
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 6
	N	37, 4, 4		@ D5
	REST	0, 6
	REST	0, 2
	N	37, 4, 2		@ D5
	N	38, 4, 2		@ D#5
	N	45, 4, 2		@ A#5
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	38, 4, 4		@ D#5
	PAT_END

pat_083CD8C8:				@ used by s8c7
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	50, 4, 4		@ D#6
	N	51, 4, 4		@ E6
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	46, 4, 4		@ B5
	N	44, 4, 4		@ A5
	REST	0, 6
	REST	0, 2
	N	39, 4, 2		@ E5
	N	44, 4, 4		@ A5
	N	44, 4, 6		@ A5
	N	39, 4, 4		@ E5
	N	44, 4, 4		@ A5
	REST	0, 6
	REST	0, 2
	N	39, 4, 2		@ E5
	N	44, 4, 4		@ A5
	N	44, 4, 4		@ A5
	N	46, 4, 4		@ B5
	N	47, 4, 4		@ C6
	N	48, 4, 4		@ C#6
	REST	0, 6
	REST	0, 2
	N	43, 4, 2		@ G#5
	N	48, 4, 4		@ C#6
	N	48, 4, 6		@ C#6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	39, 4, 4		@ E5
	REST	0, 6
	REST	0, 2
	N	46, 4, 2		@ B5
	N	51, 4, 2		@ E6
	N	46, 4, 2		@ B5
	N	39, 4, 7		@ E5
	N	39, 4, 4		@ E5
	REST	0, 6
	REST	0, 2
	N	39, 4, 2		@ E5
	N	46, 4, 4		@ B5
	N	39, 4, 4		@ E5
	N	39, 4, 4		@ E5
	REST	0, 4
	PAT_END

pat_083CD983:				@ used by s8c7
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	42, 4, 1		@ G5
	N	41, 4, 1		@ F#5
	N	40, 4, 1		@ F5
	N	39, 4, 4		@ E5
	N	39, 4, 6		@ E5
	N	42, 4, 2		@ G5
	N	46, 4, 2		@ B5
	N	43, 4, 4		@ G#5
	REST	0, 6
	N	42, 4, 1		@ G5
	N	41, 4, 1		@ F#5
	N	40, 4, 1		@ F5
	N	39, 4, 4		@ E5
	N	39, 4, 4		@ E5
	N	42, 4, 4		@ G5
	N	46, 4, 4		@ B5
	N	44, 4, 4		@ A5
	REST	0, 6
	N	43, 4, 1		@ G#5
	N	42, 4, 1		@ G5
	N	41, 4, 1		@ F#5
	N	40, 4, 4		@ F5
	N	40, 4, 4		@ F5
	REST	0, 6
	N	44, 4, 4		@ A5
	REST	0, 6
	N	43, 4, 1		@ G#5
	N	42, 4, 1		@ G5
	N	41, 4, 1		@ F#5
	N	40, 4, 4		@ F5
	N	40, 4, 4		@ F5
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	45, 4, 4		@ A#5
	REST	0, 6
	REST	0, 2
	N	45, 4, 2		@ A#5
	N	40, 4, 4		@ F5
	N	40, 4, 4		@ F5
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	45, 4, 4		@ A#5
	REST	0, 6
	REST	0, 2
	N	45, 4, 2		@ A#5
	N	52, 4, 2		@ F6
	N	47, 4, 2		@ C6
	N	40, 4, 4		@ F5
	REST	0, 6
	N	45, 4, 4		@ A#5
	REST	0, 6
	REST	0, 2
	N	45, 4, 2		@ A#5
	N	40, 4, 4		@ F5
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	44, 4, 4		@ A5
	N	45, 4, 4		@ A#5
	REST	0, 6
	REST	0, 2
	N	45, 4, 2		@ A#5
	N	40, 4, 4		@ F5
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	52, 4, 4		@ F6
	PAT_END

pat_083CDA4D:				@ used by s8c7
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	48, 4, 4		@ C#6
	N	50, 4, 4		@ D#6
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 2		@ D#6
	N	51, 4, 2		@ E6
	N	52, 4, 2		@ F6
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	52, 4, 2		@ F6
	N	48, 4, 2		@ C#6
	N	45, 4, 4		@ A#5
	N	45, 4, 6		@ A#5
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 2		@ D#6
	N	52, 4, 2		@ F6
	N	50, 4, 2		@ D#6
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 2		@ D#6
	N	51, 4, 2		@ E6
	N	52, 4, 2		@ F6
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 2		@ D#6
	N	51, 4, 2		@ E6
	N	52, 4, 5		@ F6
	N	50, 4, 4		@ D#6
	N	48, 4, 4		@ C#6
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	PAT_END

pat_083CDB2F:				@ used by s8c7
	N	50, 4, 6		@ D#6
	REST	0, 4
	N	45, 4, 2		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 5
	N	45, 4, 2		@ A#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 5
	N	46, 4, 2		@ B5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	50, 4, 4		@ D#6
	N	50, 4, 6		@ D#6
	REST	0, 4
	N	45, 4, 2		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	48, 4, 4		@ C#6
	N	45, 4, 4		@ A#5
	N	43, 4, 6		@ G#5
	REST	0, 4
	N	46, 4, 4		@ B5
	N	50, 4, 6		@ D#6
	N	38, 4, 6		@ D#5
	N	43, 4, 6		@ G#5
	REST	0, 5
	N	46, 4, 2		@ B5
	N	50, 4, 4		@ D#6
	N	50, 4, 6		@ D#6
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	50, 4, 6		@ D#6
	REST	0, 5
	N	38, 4, 2		@ D#5
	N	38, 4, 4		@ D#5
	N	38, 4, 4		@ D#5
	N	42, 4, 4		@ G5
	N	45, 4, 4		@ A#5
	N	43, 4, 6		@ G#5
	REST	0, 5
	N	46, 4, 2		@ B5
	N	50, 4, 4		@ D#6
	N	50, 4, 6		@ D#6
	N	43, 4, 2		@ G#5
	N	50, 4, 2		@ D#6
	N	50, 4, 6		@ D#6
	REST	0, 5
	N	38, 4, 2		@ D#5
	N	42, 4, 4		@ G5
	N	45, 4, 4		@ A#5
	N	50, 4, 4		@ D#6
	N	38, 4, 4		@ D#5
	PAT_END

pat_083CDBDE:				@ used by s8c8
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	N	48, 28, 10		@ C#6
	PAT_END

pat_083CDC45:				@ used by s7c1
	N	57, 22, 8		@ A#6
	N	50, 27, 8		@ D#6
	N	60, 22, 8		@ C#7
	N	53, 24, 8		@ F#6
	N	50, 24, 8		@ D#6
	N	55, 26, 8		@ G#6
	N	60, 22, 8		@ C#7
	N	53, 23, 8		@ F#6
	N	53, 23, 10		@ F#6
	PAT_END

pat_083CDC61:				@ used by s7c8
	N	50, 16, 37		@ D#6
	N	50, 16, 21		@ D#6
	PAT_END

pat_083CDC68:				@ used by s7c7
	N	45, 4, 5		@ A#5
	N	45, 4, 4		@ A#5
	N	47, 4, 2		@ C6
	N	49, 4, 4		@ D6
	N	50, 4, 4		@ D#6
	N	45, 4, 4		@ A#5
	N	38, 4, 4		@ D#5
	N	45, 4, 4		@ A#5
	N	48, 4, 5		@ C#6
	N	48, 4, 4		@ C#6
	N	50, 4, 2		@ D#6
	N	52, 4, 4		@ F6
	N	53, 4, 4		@ F#6
	N	48, 4, 4		@ C#6
	N	41, 4, 4		@ F#5
	N	48, 4, 4		@ C#6
	N	50, 4, 5		@ D#6
	N	50, 4, 4		@ D#6
	N	52, 4, 2		@ F6
	N	54, 4, 4		@ G6
	N	55, 4, 4		@ G#6
	N	50, 4, 4		@ D#6
	N	43, 4, 4		@ G#5
	N	50, 4, 4		@ D#6
	N	48, 4, 5		@ C#6
	N	48, 4, 4		@ C#6
	N	50, 4, 2		@ D#6
	N	52, 4, 4		@ F6
	N	53, 4, 4		@ F#6
	N	48, 4, 4		@ C#6
	N	41, 4, 4		@ F#5
	N	48, 4, 4		@ C#6
	N	53, 4, 4		@ F#6
	N	48, 4, 4		@ C#6
	N	41, 4, 9		@ F#5
	PAT_END

pat_083CDCD2:				@ used by s7c5
	N	64, 5, 13		@ F7
	N	61, 5, 13		@ D7
	N	57, 5, 13		@ A#6
	N	64, 5, 13		@ F7
	N	61, 5, 13		@ D7
	N	57, 5, 13		@ A#6
	N	65, 5, 13		@ F#7
	N	62, 5, 13		@ D#7
	N	57, 5, 13		@ A#6
	N	65, 5, 13		@ F#7
	N	62, 5, 13		@ D#7
	N	57, 5, 13		@ A#6
	N	67, 5, 13		@ G#7
	N	64, 5, 13		@ F7
	N	60, 5, 13		@ C#7
	N	67, 5, 13		@ G#7
	N	64, 5, 13		@ F7
	N	60, 5, 13		@ C#7
	N	69, 5, 13		@ A#7
	N	65, 5, 13		@ F#7
	N	60, 5, 13		@ C#7
	N	69, 5, 13		@ A#7
	N	65, 5, 13		@ F#7
	N	60, 5, 13		@ C#7
	N	69, 5, 13		@ A#7
	N	66, 5, 13		@ G7
	N	62, 5, 13		@ D#7
	N	69, 5, 13		@ A#7
	N	66, 5, 13		@ G7
	N	62, 5, 13		@ D#7
	N	70, 5, 13		@ B7
	N	67, 5, 13		@ G#7
	N	62, 5, 13		@ D#7
	N	74, 5, 13		@ D#8
	N	70, 5, 13		@ B7
	N	67, 5, 13		@ G#7
	N	72, 5, 13		@ C#8
	N	67, 5, 13		@ G#7
	N	64, 5, 13		@ F7
	N	76, 5, 13		@ F8
	N	72, 5, 13		@ C#8
	N	67, 5, 13		@ G#7
	N	77, 5, 13		@ F#8
	N	72, 5, 13		@ C#8
	N	69, 5, 13		@ A#7
	N	77, 5, 13		@ F#8
	N	72, 5, 13		@ C#8
	N	69, 5, 13		@ A#7
	N	77, 5, 10		@ F#8
	PAT_END

pat_083CDD66:				@ used by s7c6
	N	52, 25, 4		@ F6
	N	50, 25, 4		@ D#6
	N	49, 25, 4		@ D6
	N	45, 25, 4		@ A#5
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	53, 25, 4		@ F#6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	53, 25, 4		@ F#6
	N	55, 25, 4		@ G#6
	N	52, 25, 4		@ F6
	N	57, 25, 4		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	53, 25, 4		@ F#6
	N	54, 25, 4		@ G6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	54, 25, 4		@ G6
	N	58, 25, 4		@ B6
	N	57, 25, 4		@ A#6
	N	58, 25, 4		@ B6
	N	55, 25, 4		@ G#6
	N	52, 25, 4		@ F6
	N	53, 25, 4		@ F#6
	N	55, 25, 4		@ G#6
	N	52, 25, 4		@ F6
	N	57, 25, 4		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	60, 25, 4		@ C#7
	N	60, 25, 10		@ C#7
	PAT_END

pat_083CDDCA:				@ used by s7c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	PAT_END

pat_083CDDFB:				@ used by s7c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	PAT_END

pat_083CDE47:				@ used by s6c5
	N	50, 25, 2		@ D#6
	N	57, 25, 4		@ A#6
	N	62, 25, 42		@ D#7
	N	60, 25, 2		@ C#7
	N	58, 25, 2		@ B6
	N	60, 25, 4		@ C#7
	N	58, 25, 2		@ B6
	N	57, 25, 2		@ A#6
	N	58, 25, 4		@ B6
	N	57, 25, 2		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 4		@ A#6
	N	55, 25, 2		@ G#6
	N	53, 25, 2		@ F#6
	N	55, 25, 4		@ G#6
	N	53, 25, 2		@ F#6
	N	52, 25, 2		@ F6
	N	53, 25, 4		@ F#6
	N	52, 25, 2		@ F6
	N	50, 25, 2		@ D#6
	N	52, 25, 4		@ F6
	N	50, 25, 2		@ D#6
	N	49, 25, 2		@ D6
	N	57, 25, 19		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 10		@ A#6
	N	57, 25, 10		@ A#6
	PAT_END

pat_083CDE99:				@ used by s6c6
	N	38, 25, 2		@ D#5
	N	45, 25, 4		@ A#5
	N	50, 25, 42		@ D#6
	N	48, 25, 2		@ C#6
	N	46, 25, 2		@ B5
	N	48, 25, 4		@ C#6
	N	46, 25, 2		@ B5
	N	45, 25, 2		@ A#5
	N	46, 25, 4		@ B5
	N	45, 25, 2		@ A#5
	N	43, 25, 2		@ G#5
	N	45, 25, 4		@ A#5
	N	43, 25, 2		@ G#5
	N	41, 25, 2		@ F#5
	N	43, 25, 4		@ G#5
	N	41, 25, 2		@ F#5
	N	40, 25, 2		@ F5
	N	41, 25, 4		@ F#5
	N	40, 25, 2		@ F5
	N	38, 25, 2		@ D#5
	N	40, 25, 4		@ F5
	N	38, 25, 2		@ D#5
	N	37, 25, 2		@ D5
	N	50, 25, 19		@ D#6
	N	48, 25, 4		@ C#6
	N	50, 25, 10		@ D#6
	N	50, 25, 10		@ D#6
	PAT_END

pat_083CDEEB:				@ used by s6c7
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	50, 4, 6		@ D#6
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	REST	0, 4
	N	48, 4, 6		@ C#6
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	REST	0, 4
	N	46, 4, 6		@ B5
	REST	0, 6
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	50, 4, 6		@ D#6
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	46, 4, 2		@ B5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	50, 4, 4		@ D#6
	N	50, 4, 10		@ D#6
	PAT_END

pat_083CDF4F:				@ used by s6c8
	N	50, 16, 37		@ D#6
	N	50, 16, 10		@ D#6
	PAT_END

pat_083CDF56:				@ used by s6c1
	N	50, 21, 4		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	48, 18, 4		@ C#6
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	48, 18, 2		@ C#6
	N	60, 18, 4		@ C#7
	N	48, 18, 4		@ C#6
	N	60, 18, 4		@ C#7
	N	48, 18, 2		@ C#6
	N	60, 18, 4		@ C#7
	N	60, 18, 4		@ C#7
	N	46, 18, 4		@ B5
	N	58, 18, 2		@ B6
	N	58, 18, 2		@ B6
	N	46, 18, 2		@ B5
	N	58, 18, 4		@ B6
	N	46, 18, 4		@ B5
	N	58, 18, 4		@ B6
	N	46, 18, 2		@ B5
	N	58, 18, 4		@ B6
	N	58, 18, 4		@ B6
	N	50, 21, 4		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 21, 4		@ D#6
	N	50, 21, 2		@ D#6
	N	50, 27, 10		@ D#6
	PAT_END

pat_083CDFE4:				@ used by s6c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	PAT_END

pat_083CE0C3:				@ used by s5c1
	N	43, 19, 5		@ G#5
	N	43, 19, 2		@ G#5
	REST	0, 4
	N	43, 19, 4		@ G#5
	REST	0, 4
	N	43, 19, 4		@ G#5
	N	44, 16, 6		@ A5
	REST	0, 4
	N	43, 19, 4		@ G#5
	REST	0, 4
	N	43, 19, 4		@ G#5
	REST	0, 4
	N	43, 19, 4		@ G#5
	N	41, 19, 6		@ F#5
	PAT_END

pat_083CE0EE:				@ used by s5c1
	N	48, 19, 5		@ C#6
	N	48, 19, 2		@ C#6
	REST	0, 4
	N	48, 19, 4		@ C#6
	REST	0, 4
	N	48, 19, 4		@ C#6
	N	49, 16, 6		@ D6
	N	48, 25, 11		@ C#6
	PAT_END

pat_083CE107:				@ used by s5c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	PAT_END

pat_083CE1C5:				@ used by s5c5
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 5		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	60, 5, 6		@ C#7
	REST	0, 4
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	56, 5, 6		@ A6
	REST	0, 4
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	60, 5, 6		@ C#7
	REST	0, 4
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 4		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	58, 5, 2		@ B6
	REST	0, 2
	N	56, 5, 6		@ A6
	REST	0, 4
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	63, 5, 6		@ E7
	REST	0, 4
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	60, 5, 6		@ C#7
	REST	0, 4
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	63, 5, 6		@ E7
	REST	0, 4
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 4		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	62, 5, 2		@ D#7
	REST	0, 2
	N	60, 5, 6		@ C#7
	REST	0, 4
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 2		@ E7
	REST	0, 2
	N	63, 5, 2		@ E7
	REST	0, 2
	N	65, 5, 6		@ F#7
	REST	0, 4
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 2		@ E7
	REST	0, 2
	N	63, 5, 2		@ E7
	REST	0, 2
	N	61, 5, 6		@ D7
	REST	0, 4
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 2		@ E7
	REST	0, 2
	N	63, 5, 2		@ E7
	REST	0, 2
	N	65, 5, 6		@ F#7
	REST	0, 4
	N	63, 5, 4		@ E7
	REST	0, 2
	N	63, 5, 4		@ E7
	REST	0, 2
	N	60, 5, 11		@ C#7
	PAT_END

pat_083CE31F:				@ used by s5c6
	N	43, 19, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 23, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	43, 23, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	43, 19, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	44, 21, 2		@ A5
	N	44, 22, 2		@ A5
	N	41, 23, 2		@ F#5
	N	41, 24, 2		@ F#5
	N	43, 19, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 23, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	43, 23, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	43, 19, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	41, 21, 2		@ F#5
	N	41, 22, 2		@ F#5
	N	38, 23, 2		@ D#5
	N	38, 24, 2		@ D#5
	PAT_END

pat_083CE380:				@ used by s5c6
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 23, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 23, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	49, 21, 2		@ D6
	N	49, 22, 2		@ D6
	N	46, 23, 2		@ B5
	N	46, 24, 2		@ B5
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 23, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 23, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	46, 21, 2		@ B5
	N	46, 22, 2		@ B5
	N	43, 23, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 23, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 23, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	49, 21, 2		@ D6
	N	49, 22, 2		@ D6
	N	46, 23, 2		@ B5
	N	46, 24, 2		@ B5
	N	36, 9, 12		@ C#5
	PAT_END

pat_083CE414:				@ used by s5c7
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	44, 4, 4		@ A5
	N	41, 4, 4		@ F#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	41, 4, 4		@ F#5
	N	38, 4, 4		@ D#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	44, 4, 4		@ A5
	N	41, 4, 4		@ F#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	41, 4, 4		@ F#5
	N	38, 4, 4		@ D#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	44, 4, 4		@ A5
	N	41, 4, 4		@ F#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	41, 4, 4		@ F#5
	N	38, 4, 4		@ D#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	44, 4, 4		@ A5
	N	41, 4, 4		@ F#5
	N	43, 4, 5		@ G#5
	N	43, 4, 5		@ G#5
	N	43, 4, 4		@ G#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	48, 4, 5		@ C#6
	N	48, 4, 5		@ C#6
	N	48, 4, 4		@ C#6
	REST	0, 4
	N	48, 4, 4		@ C#6
	N	49, 4, 4		@ D6
	N	46, 4, 4		@ B5
	N	48, 4, 5		@ C#6
	N	48, 4, 5		@ C#6
	N	48, 4, 4		@ C#6
	REST	0, 4
	N	48, 4, 4		@ C#6
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	48, 4, 5		@ C#6
	N	48, 4, 5		@ C#6
	N	48, 4, 4		@ C#6
	REST	0, 4
	N	48, 4, 4		@ C#6
	N	49, 4, 4		@ D6
	N	46, 4, 4		@ B5
	N	48, 4, 8		@ C#6
	N	36, 4, 11		@ C#5
	PAT_END

pat_083CE502:				@ used by s5c8
	N	50, 16, 37		@ D#6
	PAT_END

pat_083CE506:				@ used by s4c5
	N	45, 25, 10		@ A#5
	N	47, 25, 8		@ C6
	N	48, 25, 8		@ C#6
	N	44, 25, 12		@ A5
	N	45, 25, 6		@ A#5
	N	47, 25, 6		@ C6
	N	48, 25, 6		@ C#6
	N	52, 25, 6		@ F6
	N	53, 25, 6		@ F#6
	N	47, 25, 6		@ C6
	N	48, 25, 8		@ C#6
	N	44, 25, 12		@ A5
	PAT_END

pat_083CE52B:				@ used by s4c5
	N	50, 25, 7		@ D#6
	N	53, 25, 2		@ F#6
	N	57, 25, 2		@ A#6
	N	62, 25, 9		@ D#7
	N	61, 25, 6		@ D7
	N	60, 25, 6		@ C#7
	N	59, 25, 6		@ C7
	N	58, 25, 7		@ B6
	N	53, 25, 2		@ F#6
	N	58, 25, 2		@ B6
	N	61, 25, 7		@ D7
	N	58, 25, 2		@ B6
	N	61, 25, 2		@ D7
	N	65, 25, 9		@ F#7
	N	67, 25, 6		@ G#7
	N	69, 25, 7		@ A#7
	N	65, 25, 2		@ F#7
	N	64, 25, 2		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	64, 25, 4		@ F7
	N	62, 25, 8		@ D#7
	N	61, 25, 6		@ D7
	N	62, 25, 6		@ D#7
	N	58, 25, 9		@ B6
	N	57, 25, 6		@ A#6
	N	55, 25, 8		@ G#6
	N	53, 25, 8		@ F#6
	PAT_END

pat_083CE583:				@ used by s4c5
	N	55, 25, 7		@ G#6
	N	58, 25, 2		@ B6
	N	62, 25, 2		@ D#7
	N	67, 25, 6		@ G#7
	N	69, 25, 6		@ A#7
	N	70, 25, 7		@ B7
	N	69, 25, 4		@ A#7
	N	67, 25, 6		@ G#7
	N	66, 25, 6		@ G7
	N	65, 25, 23		@ F#7
	N	66, 25, 23		@ G7
	N	63, 25, 19		@ E7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	58, 25, 7		@ B6
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	70, 25, 4		@ B7
	N	67, 25, 4		@ G#7
	N	70, 25, 4		@ B7
	N	72, 25, 4		@ C#8
	N	74, 25, 4		@ D#8
	N	72, 25, 2		@ C#8
	N	70, 25, 2		@ B7
	N	72, 25, 4		@ C#8
	N	70, 25, 2		@ B7
	N	69, 25, 2		@ A#7
	N	70, 25, 4		@ B7
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	66, 25, 4		@ G7
	N	67, 25, 4		@ G#7
	N	63, 25, 4		@ E7
	N	65, 25, 4		@ F#7
	N	62, 25, 4		@ D#7
	N	63, 25, 4		@ E7
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	58, 25, 4		@ B6
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	58, 25, 4		@ B6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	54, 25, 6		@ G6
	PAT_END

pat_083CE611:				@ used by s4c5
	N	55, 25, 6		@ G#6
	N	60, 25, 6		@ C#7
	N	62, 25, 6		@ D#7
	N	63, 25, 8		@ E7
	N	62, 25, 6		@ D#7
	N	60, 25, 6		@ C#7
	N	58, 25, 6		@ B6
	N	56, 25, 8		@ A6
	N	55, 25, 6		@ G#6
	N	56, 25, 6		@ A6
	N	53, 25, 8		@ F#6
	N	51, 25, 8		@ E6
	N	55, 25, 8		@ G#6
	N	60, 25, 6		@ C#7
	N	62, 25, 6		@ D#7
	N	63, 25, 8		@ E7
	N	62, 25, 6		@ D#7
	N	60, 25, 6		@ C#7
	N	58, 25, 8		@ B6
	N	56, 25, 11		@ A6
	PAT_END

pat_083CE64E:				@ used by s4c5
	N	48, 25, 6		@ C#6
	N	53, 25, 4		@ F#6
	N	55, 25, 4		@ G#6
	N	56, 25, 6		@ A6
	N	58, 25, 6		@ B6
	N	60, 25, 6		@ C#7
	N	58, 25, 4		@ B6
	N	56, 25, 6		@ A6
	N	55, 25, 4		@ G#6
	N	53, 25, 6		@ F#6
	N	51, 25, 8		@ E6
	N	52, 25, 8		@ F6
	N	49, 25, 10		@ D6
	N	51, 25, 6		@ E6
	N	56, 25, 4		@ A6
	N	58, 25, 4		@ B6
	N	59, 25, 6		@ C7
	N	61, 25, 6		@ D7
	N	63, 25, 6		@ E7
	N	61, 25, 4		@ D7
	N	59, 25, 6		@ C7
	N	58, 25, 4		@ B6
	N	56, 25, 6		@ A6
	N	55, 25, 8		@ G#6
	N	47, 25, 8		@ C6
	N	52, 25, 10		@ F6
	PAT_END

pat_083CE69D:				@ used by s4c5
	N	45, 25, 6		@ A#5
	N	48, 25, 4		@ C#6
	N	50, 25, 2		@ D#6
	N	51, 25, 5		@ E6
	N	52, 25, 4		@ F6
	N	55, 25, 4		@ G#6
	N	56, 25, 4		@ A6
	N	57, 25, 7		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 24		@ C#7
	N	62, 25, 6		@ D#7
	N	64, 25, 7		@ F7
	N	65, 25, 2		@ F#7
	N	64, 25, 2		@ F7
	N	62, 25, 6		@ D#7
	N	60, 25, 6		@ C#7
	N	62, 25, 7		@ D#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 6		@ C#7
	N	59, 25, 6		@ C7
	N	60, 25, 7		@ C#7
	N	57, 25, 2		@ A#6
	N	59, 25, 2		@ C7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 6		@ A#6
	N	52, 25, 6		@ F6
	N	53, 25, 6		@ F#6
	N	52, 25, 4		@ F6
	N	50, 25, 4		@ D#6
	N	52, 25, 7		@ F6
	N	50, 25, 2		@ D#6
	N	48, 25, 5		@ C#6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	48, 25, 4		@ C#6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	50, 25, 4		@ D#6
	N	48, 25, 4		@ C#6
	N	47, 25, 6		@ C6
	N	43, 25, 6		@ G#5
	N	45, 25, 4		@ A#5
	N	48, 25, 2		@ C#6
	N	50, 25, 2		@ D#6
	N	51, 25, 2		@ E6
	N	52, 25, 2		@ F6
	N	55, 25, 2		@ G#6
	N	56, 25, 2		@ A6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 4		@ A7
	N	69, 25, 7		@ A#7
	N	67, 25, 4		@ G#7
	N	69, 25, 6		@ A#7
	N	72, 25, 6		@ C#8
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	64, 25, 2		@ F7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	64, 25, 2		@ F7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	64, 25, 2		@ F7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	64, 25, 2		@ F7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	64, 25, 2		@ F7
	N	72, 25, 2		@ C#8
	N	74, 25, 2		@ D#8
	N	69, 25, 2		@ A#7
	N	65, 25, 2		@ F#7
	N	74, 25, 2		@ D#8
	N	69, 25, 2		@ A#7
	N	65, 25, 2		@ F#7
	N	74, 25, 2		@ D#8
	N	69, 25, 2		@ A#7
	N	65, 25, 2		@ F#7
	N	74, 25, 2		@ D#8
	N	69, 25, 2		@ A#7
	N	65, 25, 2		@ F#7
	N	69, 25, 4		@ A#7
	N	74, 25, 4		@ D#8
	N	76, 25, 2		@ F8
	N	77, 25, 2		@ F#8
	N	76, 25, 2		@ F8
	N	74, 25, 2		@ D#8
	N	72, 25, 4		@ C#8
	N	74, 25, 2		@ D#8
	N	72, 25, 5		@ C#8
	N	71, 25, 4		@ C8
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 4		@ A#7
	N	67, 25, 5		@ G#7
	N	64, 25, 4		@ F7
	N	62, 25, 4		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 2		@ A#7
	N	71, 25, 4		@ C8
	N	72, 25, 4		@ C#8
	N	74, 25, 7		@ D#8
	N	76, 25, 2		@ F8
	N	74, 25, 24		@ D#8
	N	72, 25, 6		@ C#8
	PAT_END

pat_083CE82A:				@ used by s4c5
	N	72, 25, 2		@ C#8
	N	64, 25, 2		@ F7
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	64, 25, 2		@ F7
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	77, 25, 2		@ F#8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	77, 25, 2		@ F#8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	77, 25, 2		@ F#8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	77, 25, 2		@ F#8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	77, 25, 2		@ F#8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	77, 25, 2		@ F#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	76, 25, 2		@ F8
	N	74, 25, 2		@ D#8
	N	67, 25, 2		@ G#7
	N	71, 25, 2		@ C8
	N	74, 25, 2		@ D#8
	N	67, 25, 2		@ G#7
	N	71, 25, 2		@ C8
	N	74, 25, 2		@ D#8
	N	67, 25, 2		@ G#7
	N	71, 25, 2		@ C8
	N	74, 25, 4		@ D#8
	N	72, 25, 2		@ C#8
	N	71, 25, 4		@ C8
	N	72, 25, 4		@ C#8
	N	69, 25, 2		@ A#7
	N	71, 25, 2		@ C8
	N	72, 25, 2		@ C#8
	N	74, 25, 2		@ D#8
	N	76, 25, 4		@ F8
	N	77, 25, 2		@ F#8
	N	79, 25, 4		@ G#8
	N	77, 25, 2		@ F#8
	N	76, 25, 2		@ F8
	N	74, 25, 2		@ D#8
	N	72, 25, 2		@ C#8
	N	74, 25, 2		@ D#8
	N	76, 25, 2		@ F8
	N	74, 25, 2		@ D#8
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 2		@ A#7
	N	67, 25, 4		@ G#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 24		@ F7
	N	60, 25, 2		@ C#7
	N	57, 25, 5		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	52, 25, 4		@ F6
	N	55, 25, 4		@ G#6
	N	56, 25, 2		@ A6
	N	57, 25, 4		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	57, 25, 4		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	60, 25, 2		@ C#7
	N	57, 25, 23		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	57, 25, 2		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 4		@ A#6
	N	60, 25, 2		@ C#7
	N	57, 25, 5		@ A#6
	N	52, 25, 4		@ F6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	48, 25, 6		@ C#6
	N	50, 25, 4		@ D#6
	N	51, 25, 2		@ E6
	N	52, 25, 5		@ F6
	N	50, 25, 4		@ D#6
	N	48, 25, 4		@ C#6
	N	43, 25, 4		@ G#5
	N	45, 25, 7		@ A#5
	N	48, 25, 2		@ C#6
	N	50, 25, 4		@ D#6
	N	51, 25, 2		@ E6
	N	52, 25, 4		@ F6
	N	55, 25, 4		@ G#6
	N	56, 25, 4		@ A6
	N	57, 25, 7		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 5		@ A#6
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 22		@ A#6
	N	55, 25, 4		@ G#6
	N	52, 25, 4		@ F6
	N	55, 25, 4		@ G#6
	N	57, 25, 19		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 10		@ A#6
	PAT_END

pat_083CE9F0:				@ used by s4c6
	N	57, 19, 2		@ A#6
	N	60, 20, 2		@ C#7
	N	64, 21, 2		@ F7
	N	65, 22, 2		@ F#7
	N	64, 23, 2		@ F7
	N	60, 24, 2		@ C#7
	N	57, 24, 2		@ A#6
	N	60, 23, 2		@ C#7
	N	64, 22, 2		@ F7
	N	65, 21, 2		@ F#7
	N	64, 20, 2		@ F7
	N	60, 19, 2		@ C#7
	N	57, 19, 2		@ A#6
	N	60, 20, 2		@ C#7
	N	64, 21, 2		@ F7
	N	65, 22, 2		@ F#7
	N	64, 23, 2		@ F7
	N	60, 24, 2		@ C#7
	N	57, 24, 2		@ A#6
	N	60, 23, 2		@ C#7
	N	64, 22, 2		@ F7
	N	65, 21, 2		@ F#7
	N	64, 20, 2		@ F7
	N	60, 19, 2		@ C#7
	N	57, 19, 2		@ A#6
	N	60, 20, 2		@ C#7
	N	64, 21, 2		@ F7
	N	65, 22, 2		@ F#7
	N	64, 23, 2		@ F7
	N	60, 24, 2		@ C#7
	N	57, 24, 2		@ A#6
	N	60, 23, 2		@ C#7
	N	53, 19, 2		@ F#6
	N	56, 20, 2		@ A6
	N	60, 21, 2		@ C#7
	N	61, 22, 2		@ D7
	N	60, 23, 2		@ C#7
	N	56, 24, 2		@ A6
	N	53, 24, 2		@ F#6
	N	56, 23, 2		@ A6
	N	60, 22, 2		@ C#7
	N	61, 21, 2		@ D7
	N	60, 20, 2		@ C#7
	N	56, 19, 2		@ A6
	N	53, 19, 2		@ F#6
	N	56, 20, 2		@ A6
	N	60, 21, 2		@ C#7
	N	61, 22, 2		@ D7
	N	60, 23, 2		@ C#7
	N	56, 24, 2		@ A6
	N	53, 24, 2		@ F#6
	N	56, 23, 2		@ A6
	N	60, 22, 2		@ C#7
	N	61, 21, 2		@ D7
	N	60, 20, 2		@ C#7
	N	56, 19, 2		@ A6
	N	53, 19, 2		@ F#6
	N	56, 20, 2		@ A6
	N	60, 21, 2		@ C#7
	N	61, 22, 2		@ D7
	N	60, 23, 2		@ C#7
	N	56, 24, 2		@ A6
	N	53, 24, 2		@ F#6
	N	56, 23, 2		@ A6
	PAT_END

pat_083CEAB1:				@ used by s4c6
	N	57, 19, 2		@ A#6
	N	59, 20, 2		@ C7
	N	60, 21, 2		@ C#7
	N	62, 22, 2		@ D#7
	N	64, 23, 2		@ F7
	N	65, 24, 2		@ F#7
	N	64, 24, 2		@ F7
	N	62, 23, 2		@ D#7
	N	60, 22, 2		@ C#7
	N	59, 21, 2		@ C7
	N	57, 20, 2		@ A#6
	N	55, 19, 2		@ G#6
	N	57, 19, 2		@ A#6
	N	59, 20, 2		@ C7
	N	60, 21, 2		@ C#7
	N	62, 22, 2		@ D#7
	N	64, 23, 2		@ F7
	N	65, 24, 2		@ F#7
	N	64, 24, 2		@ F7
	N	62, 23, 2		@ D#7
	N	60, 22, 2		@ C#7
	N	59, 21, 2		@ C7
	N	57, 20, 2		@ A#6
	N	55, 19, 2		@ G#6
	N	57, 19, 2		@ A#6
	N	59, 20, 2		@ C7
	N	60, 21, 2		@ C#7
	N	62, 22, 2		@ D#7
	N	64, 23, 2		@ F7
	N	65, 24, 2		@ F#7
	N	64, 24, 2		@ F7
	N	62, 23, 2		@ D#7
	N	60, 22, 2		@ C#7
	N	59, 21, 2		@ C7
	N	57, 20, 2		@ A#6
	N	55, 19, 2		@ G#6
	N	57, 19, 2		@ A#6
	N	59, 20, 2		@ C7
	N	60, 21, 2		@ C#7
	N	62, 22, 2		@ D#7
	N	64, 23, 2		@ F7
	N	65, 24, 2		@ F#7
	N	64, 24, 2		@ F7
	N	62, 23, 2		@ D#7
	N	60, 22, 2		@ C#7
	N	59, 21, 2		@ C7
	N	57, 20, 2		@ A#6
	N	55, 19, 2		@ G#6
	N	57, 19, 2		@ A#6
	N	59, 20, 2		@ C7
	N	60, 21, 2		@ C#7
	N	62, 22, 2		@ D#7
	N	64, 23, 2		@ F7
	N	65, 24, 2		@ F#7
	N	64, 24, 2		@ F7
	N	62, 23, 2		@ D#7
	N	60, 22, 2		@ C#7
	N	59, 21, 2		@ C7
	N	57, 20, 2		@ A#6
	N	55, 19, 2		@ G#6
	N	57, 19, 2		@ A#6
	N	60, 20, 2		@ C#7
	N	64, 21, 2		@ F7
	N	60, 22, 2		@ C#7
	PAT_END

pat_083CEB72:				@ used by s4c7
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	44, 4, 2		@ A5
	N	43, 4, 2		@ G#5
	N	42, 4, 2		@ G5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	REST	0, 4
	N	41, 4, 4		@ F#5
	REST	0, 7
	N	36, 4, 2		@ C#5
	N	38, 4, 2		@ D#5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	REST	0, 4
	N	41, 4, 4		@ F#5
	REST	0, 6
	N	41, 4, 2		@ F#5
	N	42, 4, 2		@ G5
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	PAT_END

pat_083CEBD3:				@ used by s4c7
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	44, 4, 2		@ A5
	N	43, 4, 2		@ G#5
	N	42, 4, 2		@ G5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	REST	0, 4
	N	41, 4, 4		@ F#5
	REST	0, 7
	N	36, 4, 2		@ C#5
	N	38, 4, 2		@ D#5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	REST	0, 4
	N	41, 4, 4		@ F#5
	REST	0, 6
	N	41, 4, 2		@ F#5
	N	42, 4, 2		@ G5
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 6
	N	57, 4, 2		@ A#6
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	42, 4, 2		@ G5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	REST	0, 4
	N	41, 4, 4		@ F#5
	REST	0, 7
	N	36, 4, 2		@ C#5
	N	38, 4, 2		@ D#5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	REST	0, 4
	N	41, 4, 4		@ F#5
	REST	0, 6
	N	41, 4, 2		@ F#5
	N	40, 4, 2		@ F5
	N	39, 4, 4		@ E5
	PAT_END

pat_083CEC91:				@ used by s4c7
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	38, 4, 2		@ D#5
	N	45, 4, 2		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 6		@ D#6
	N	45, 4, 2		@ A#5
	N	48, 4, 2		@ C#6
	N	50, 4, 4		@ D#6
	N	38, 4, 4		@ D#5
	REST	0, 4
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	50, 4, 4		@ D#6
	N	50, 4, 2		@ D#6
	N	49, 4, 2		@ D6
	N	48, 4, 2		@ C#6
	N	47, 4, 2		@ C6
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	REST	0, 4
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	REST	0, 4
	N	49, 4, 4		@ D6
	REST	0, 4
	N	46, 4, 4		@ B5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	46, 4, 2		@ B5
	REST	0, 2
	N	46, 4, 2		@ B5
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	41, 4, 2		@ F#5
	N	46, 4, 2		@ B5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	38, 4, 2		@ D#5
	N	45, 4, 2		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	REST	0, 4
	N	45, 4, 2		@ A#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	45, 4, 4		@ A#5
	N	50, 4, 6		@ D#6
	REST	0, 4
	N	50, 4, 4		@ D#6
	N	50, 4, 2		@ D#6
	N	49, 4, 2		@ D6
	N	48, 4, 2		@ C#6
	N	47, 4, 2		@ C6
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	REST	0, 4
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	49, 4, 6		@ D6
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	REST	0, 4
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 6		@ B5
	PAT_END

pat_083CED73:				@ used by s4c7
	N	41, 4, 6		@ F#5
	REST	0, 4
	N	44, 4, 2		@ A5
	N	48, 4, 2		@ C#6
	N	53, 4, 4		@ F#6
	N	53, 4, 4		@ F#6
	REST	0, 7
	N	41, 4, 4		@ F#5
	N	53, 4, 4		@ F#6
	N	44, 4, 2		@ A5
	N	48, 4, 4		@ C#6
	N	41, 4, 2		@ F#5
	N	48, 4, 4		@ C#6
	N	53, 4, 4		@ F#6
	N	48, 4, 4		@ C#6
	N	49, 4, 6		@ D6
	REST	0, 5
	N	44, 4, 2		@ A5
	N	49, 4, 4		@ D6
	N	49, 4, 4		@ D6
	REST	0, 4
	N	44, 4, 4		@ A5
	N	49, 4, 6		@ D6
	N	49, 4, 4		@ D6
	N	44, 4, 2		@ A5
	N	49, 4, 4		@ D6
	N	49, 4, 2		@ D6
	N	49, 4, 4		@ D6
	N	49, 4, 4		@ D6
	N	49, 4, 4		@ D6
	N	44, 4, 6		@ A5
	REST	0, 4
	N	47, 4, 2		@ C6
	N	51, 4, 2		@ E6
	N	56, 4, 4		@ A6
	N	56, 4, 4		@ A6
	REST	0, 7
	N	44, 4, 4		@ A5
	N	56, 4, 4		@ A6
	N	47, 4, 2		@ C6
	N	51, 4, 4		@ E6
	N	44, 4, 2		@ A5
	N	51, 4, 4		@ E6
	N	56, 4, 4		@ A6
	N	51, 4, 4		@ E6
	N	52, 4, 6		@ F6
	REST	0, 5
	N	47, 4, 2		@ C6
	N	52, 4, 4		@ F6
	N	52, 4, 4		@ F6
	REST	0, 4
	N	47, 4, 4		@ C6
	N	52, 4, 6		@ F6
	N	52, 4, 4		@ F6
	N	47, 4, 2		@ C6
	N	52, 4, 4		@ F6
	N	52, 4, 2		@ F6
	N	52, 4, 4		@ F6
	N	52, 4, 4		@ F6
	N	52, 4, 4		@ F6
	PAT_END

pat_083CEE28:				@ used by s4c7
	N	45, 4, 6		@ A#5
	REST	0, 5
	N	52, 4, 2		@ F6
	N	57, 4, 2		@ A#6
	N	52, 4, 2		@ F6
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	40, 4, 4		@ F5
	N	45, 4, 2		@ A#5
	REST	0, 6
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 6		@ A#5
	REST	0, 5
	N	52, 4, 2		@ F6
	N	57, 4, 2		@ A#6
	N	52, 4, 2		@ F6
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 4
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 6
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	52, 4, 2		@ F6
	N	57, 4, 4		@ A#6
	REST	0, 4
	N	45, 4, 5		@ A#5
	N	43, 4, 4		@ G#5
	N	40, 4, 2		@ F5
	REST	0, 4
	N	43, 4, 4		@ G#5
	N	45, 4, 24		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	45, 4, 6		@ A#5
	PAT_END

pat_083CEEEC:				@ used by s4c7
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 5
	N	40, 4, 2		@ F5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	52, 4, 2		@ F6
	N	57, 4, 2		@ A#6
	N	52, 4, 4		@ F6
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	40, 4, 4		@ F5
	N	43, 4, 24		@ G#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	40, 4, 2		@ F5
	N	43, 4, 4		@ G#5
	N	40, 4, 4		@ F5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	52, 4, 2		@ F6
	N	57, 4, 2		@ A#6
	N	52, 4, 2		@ F6
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 4
	N	40, 4, 2		@ F5
	N	43, 4, 4		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 6
	N	43, 4, 4		@ G#5
	N	45, 4, 2		@ A#5
	N	52, 4, 4		@ F6
	N	57, 4, 4		@ A#6
	N	45, 4, 6		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	40, 4, 4		@ F5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 4		@ G#5
	N	45, 4, 4		@ A#5
	PAT_END

pat_083CEFC5:				@ used by s4c8
	N	48, 26, 10		@ C#6
	N	48, 26, 10		@ C#6
	N	48, 26, 10		@ C#6
	N	48, 27, 10		@ C#6
	PAT_END

pat_083CEFD2:				@ used by s4c1
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	69, 19, 4		@ A#7
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	69, 19, 4		@ A#7
	N	69, 19, 4		@ A#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	65, 20, 4		@ F#7
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	53, 20, 2		@ F#6
	N	65, 20, 4		@ F#7
	N	65, 20, 4		@ F#7
	N	65, 20, 4		@ F#7
	PAT_END

pat_083CF04B:				@ used by s4c1
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 2		@ A#7
	N	57, 19, 2		@ A#6
	N	69, 19, 4		@ A#7
	N	69, 19, 4		@ A#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 2		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	62, 21, 4		@ D#7
	N	52, 21, 2		@ F6
	N	64, 21, 4		@ F7
	N	52, 21, 2		@ F6
	N	64, 21, 4		@ F7
	N	52, 21, 2		@ F6
	N	64, 21, 4		@ F7
	N	52, 21, 2		@ F6
	N	64, 21, 2		@ F7
	N	52, 21, 2		@ F6
	N	64, 21, 4		@ F7
	N	64, 21, 4		@ F7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 2		@ D#7
	N	50, 21, 2		@ D#6
	N	62, 21, 4		@ D#7
	N	62, 21, 4		@ D#7
	PAT_END

pat_083CF0D0:				@ used by s4c4, s8c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 1		@ A5
	N	42, 3, 1		@ G5
	N	42, 3, 1		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	PAT_END

pat_083CF194:				@ used by s3c5
	N	45, 9, 12		@ A#5
	PAT_END

pat_083CF198:				@ used by s3c5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 6
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	42, 4, 4		@ G5
	N	42, 4, 4		@ G5
	N	42, 4, 4		@ G5
	N	42, 4, 2		@ G5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	43, 4, 2		@ G#5
	N	43, 4, 4		@ G#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	47, 4, 4		@ C6
	N	47, 4, 4		@ C6
	N	43, 4, 2		@ G#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	PAT_END

pat_083CF271:				@ used by s3c5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 6
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	REST	0, 6
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	42, 4, 4		@ G5
	N	42, 4, 4		@ G5
	N	42, 4, 4		@ G5
	N	42, 4, 2		@ G5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	43, 4, 2		@ G#5
	N	43, 4, 4		@ G#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	REST	0, 7
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 2		@ A#5
	N	45, 4, 4		@ A#5
	N	45, 4, 4		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	47, 4, 4		@ C6
	N	47, 4, 4		@ C6
	N	43, 4, 2		@ G#5
	N	42, 4, 4		@ G5
	N	43, 4, 4		@ G#5
	PAT_END

pat_083CF34A:				@ used by s3c5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	43, 4, 2		@ G#5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	47, 4, 4		@ C6
	N	47, 4, 4		@ C6
	N	47, 4, 4		@ C6
	N	45, 4, 2		@ A#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	43, 4, 2		@ G#5
	N	47, 4, 2		@ C6
	N	50, 4, 2		@ D#6
	N	47, 4, 2		@ C6
	N	50, 4, 2		@ D#6
	N	51, 4, 4		@ E6
	N	51, 4, 4		@ E6
	N	51, 4, 2		@ E6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	51, 4, 4		@ E6
	N	51, 4, 4		@ E6
	N	51, 4, 4		@ E6
	N	51, 4, 2		@ E6
	N	51, 4, 2		@ E6
	N	48, 4, 2		@ C#6
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 2		@ B5
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	46, 4, 2		@ B5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	43, 4, 2		@ G#5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	47, 4, 4		@ C6
	N	47, 4, 4		@ C6
	N	47, 4, 4		@ C6
	N	45, 4, 2		@ A#5
	N	43, 4, 4		@ G#5
	N	43, 4, 4		@ G#5
	N	43, 4, 2		@ G#5
	N	47, 4, 2		@ C6
	N	50, 4, 2		@ D#6
	N	47, 4, 2		@ C6
	N	50, 4, 2		@ D#6
	N	51, 4, 4		@ E6
	N	51, 4, 4		@ E6
	N	51, 4, 2		@ E6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	51, 4, 4		@ E6
	N	51, 4, 4		@ E6
	N	51, 4, 4		@ E6
	N	48, 4, 2		@ C#6
	N	46, 4, 4		@ B5
	N	44, 4, 4		@ A5
	N	44, 4, 4		@ A5
	N	44, 4, 2		@ A5
	N	44, 4, 4		@ A5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 2		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	PAT_END

pat_083CF447:				@ used by s3c5
	N	45, 4, 5		@ A#5
	N	57, 4, 5		@ A#6
	N	55, 4, 6		@ G#6
	N	51, 4, 4		@ E6
	N	48, 4, 4		@ C#6
	N	51, 4, 4		@ E6
	N	45, 4, 5		@ A#5
	N	57, 4, 5		@ A#6
	N	55, 4, 6		@ G#6
	N	51, 4, 4		@ E6
	N	45, 4, 2		@ A#5
	N	48, 4, 2		@ C#6
	N	51, 4, 4		@ E6
	N	45, 4, 5		@ A#5
	N	57, 4, 5		@ A#6
	N	55, 4, 6		@ G#6
	N	51, 4, 4		@ E6
	N	48, 4, 4		@ C#6
	N	51, 4, 4		@ E6
	N	45, 4, 5		@ A#5
	N	57, 4, 5		@ A#6
	N	55, 4, 6		@ G#6
	N	51, 4, 4		@ E6
	N	45, 4, 2		@ A#5
	N	48, 4, 2		@ C#6
	N	51, 4, 4		@ E6
	N	41, 4, 5		@ F#5
	N	53, 4, 5		@ F#6
	N	51, 4, 6		@ E6
	N	47, 4, 4		@ C6
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	41, 4, 5		@ F#5
	N	53, 4, 5		@ F#6
	N	51, 4, 6		@ E6
	N	47, 4, 4		@ C6
	N	41, 4, 2		@ F#5
	N	44, 4, 2		@ A5
	N	47, 4, 4		@ C6
	N	41, 4, 5		@ F#5
	N	53, 4, 5		@ F#6
	N	51, 4, 6		@ E6
	N	47, 4, 4		@ C6
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	41, 4, 5		@ F#5
	N	53, 4, 5		@ F#6
	N	51, 4, 6		@ E6
	N	47, 4, 4		@ C6
	N	41, 4, 2		@ F#5
	N	44, 4, 2		@ A5
	N	47, 4, 4		@ C6
	N	40, 4, 5		@ F5
	N	52, 4, 5		@ F6
	N	50, 4, 6		@ D#6
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	46, 4, 4		@ B5
	N	40, 4, 5		@ F5
	N	52, 4, 5		@ F6
	N	50, 4, 6		@ D#6
	N	46, 4, 4		@ B5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	40, 4, 5		@ F5
	N	52, 4, 5		@ F6
	N	50, 4, 6		@ D#6
	N	47, 4, 4		@ C6
	N	44, 4, 4		@ A5
	N	47, 4, 4		@ C6
	N	40, 4, 5		@ F5
	N	52, 4, 5		@ F6
	N	50, 4, 6		@ D#6
	N	47, 4, 4		@ C6
	N	40, 4, 2		@ F5
	N	45, 4, 2		@ A#5
	N	47, 4, 4		@ C6
	PAT_END

pat_083CF532:				@ used by s3c6
	N	57, 25, 19		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	52, 25, 9		@ F6
	N	50, 25, 4		@ D#6
	N	48, 25, 9		@ C#6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	48, 25, 8		@ C#6
	N	47, 25, 8		@ C6
	PAT_END

pat_083CF551:				@ used by s3c6
	N	45, 25, 10		@ A#5
	N	43, 25, 10		@ G#5
	N	42, 25, 10		@ G5
	N	42, 25, 8		@ G5
	N	43, 25, 8		@ G#5
	N	45, 25, 10		@ A#5
	N	43, 25, 10		@ G#5
	N	42, 25, 10		@ G5
	N	42, 25, 8		@ G5
	N	43, 25, 6		@ G#5
	N	47, 25, 6		@ C6
	PAT_END

pat_083CF573:				@ used by s3c6
	N	57, 25, 4		@ A#6
	N	64, 25, 4		@ F7
	N	64, 25, 4		@ F7
	N	65, 25, 2		@ F#7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	57, 25, 4		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 5		@ A#6
	REST	0, 6
	N	52, 25, 2		@ F6
	N	55, 25, 2		@ G#6
	N	56, 25, 2		@ A6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	64, 25, 4		@ F7
	N	60, 25, 4		@ C#7
	N	66, 25, 7		@ G7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 4		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	57, 25, 4		@ A#6
	N	64, 25, 4		@ F7
	N	64, 25, 4		@ F7
	N	65, 25, 2		@ F#7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	57, 25, 4		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 5		@ A#6
	REST	0, 6
	N	52, 25, 2		@ F6
	N	55, 25, 2		@ G#6
	N	56, 25, 2		@ A6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 4		@ A#7
	N	72, 25, 4		@ C#8
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	66, 25, 4		@ G7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 4		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	55, 25, 6		@ G#6
	PAT_END

pat_083CF661:				@ used by s3c6
	N	67, 25, 7		@ G#7
	N	65, 25, 2		@ F#7
	N	64, 25, 5		@ F7
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 6		@ D#7
	N	55, 25, 4		@ G#6
	N	57, 25, 2		@ A#6
	N	59, 25, 5		@ C7
	N	60, 25, 4		@ C#7
	N	62, 25, 6		@ D#7
	N	70, 25, 7		@ B7
	N	69, 25, 2		@ A#7
	N	67, 25, 24		@ G#7
	N	65, 25, 4		@ F#7
	N	63, 25, 4		@ E7
	N	65, 25, 4		@ F#7
	N	67, 25, 4		@ G#7
	N	65, 25, 4		@ F#7
	N	63, 25, 2		@ E7
	N	62, 25, 24		@ D#7
	N	58, 25, 6		@ B6
	N	67, 25, 2		@ G#7
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	65, 25, 2		@ F#7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	64, 25, 5		@ F7
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 6		@ D#7
	N	59, 25, 4		@ C7
	N	60, 25, 2		@ C#7
	N	62, 25, 5		@ D#7
	N	55, 25, 4		@ G#6
	N	57, 25, 4		@ A#6
	N	59, 25, 4		@ C7
	N	67, 25, 7		@ G#7
	N	65, 25, 2		@ F#7
	N	63, 25, 5		@ E7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	58, 25, 4		@ B6
	N	56, 25, 7		@ A6
	N	58, 25, 2		@ B6
	N	60, 25, 2		@ C#7
	N	58, 25, 8		@ B6
	PAT_END

pat_083CF6F8:				@ used by s3c6
	N	45, 25, 4		@ A#5
	N	45, 25, 4		@ A#5
	N	45, 25, 2		@ A#5
	N	40, 25, 2		@ F5
	N	43, 25, 2		@ G#5
	N	45, 25, 2		@ A#5
	REST	0, 7
	N	40, 25, 2		@ F5
	N	43, 25, 2		@ G#5
	N	45, 25, 4		@ A#5
	N	45, 25, 4		@ A#5
	N	45, 25, 2		@ A#5
	N	43, 25, 2		@ G#5
	N	45, 25, 2		@ A#5
	N	48, 25, 2		@ C#6
	REST	0, 7
	N	40, 25, 2		@ F5
	N	43, 25, 2		@ G#5
	N	45, 25, 4		@ A#5
	N	45, 25, 4		@ A#5
	N	45, 25, 2		@ A#5
	N	40, 25, 2		@ F5
	N	43, 25, 2		@ G#5
	N	45, 25, 4		@ A#5
	N	45, 25, 4		@ A#5
	N	45, 25, 2		@ A#5
	N	45, 25, 4		@ A#5
	N	43, 25, 4		@ G#5
	N	42, 25, 7		@ G5
	N	43, 25, 2		@ G#5
	N	45, 25, 2		@ A#5
	N	43, 25, 7		@ G#5
	N	45, 25, 2		@ A#5
	N	47, 25, 2		@ C6
	N	45, 25, 4		@ A#5
	N	45, 25, 4		@ A#5
	N	45, 25, 2		@ A#5
	N	40, 25, 2		@ F5
	N	43, 25, 2		@ G#5
	N	45, 25, 2		@ A#5
	REST	0, 7
	N	40, 25, 2		@ F5
	N	43, 25, 2		@ G#5
	N	45, 25, 4		@ A#5
	N	45, 25, 4		@ A#5
	N	45, 25, 2		@ A#5
	N	48, 25, 2		@ C#6
	N	50, 25, 2		@ D#6
	N	51, 25, 2		@ E6
	N	52, 25, 24		@ F6
	N	55, 25, 2		@ G#6
	N	56, 25, 4		@ A6
	N	57, 25, 4		@ A#6
	N	55, 25, 4		@ G#6
	N	52, 25, 4		@ F6
	N	50, 25, 2		@ D#6
	N	51, 25, 2		@ E6
	N	52, 25, 2		@ F6
	N	50, 25, 2		@ D#6
	N	48, 25, 2		@ C#6
	N	45, 25, 5		@ A#5
	N	48, 25, 4		@ C#6
	N	50, 25, 6		@ D#6
	N	48, 25, 5		@ C#6
	N	47, 25, 5		@ C6
	N	43, 25, 4		@ G#5
	N	45, 25, 4		@ A#5
	N	47, 25, 4		@ C6
	PAT_END

pat_083CF7C5:				@ used by s3c6
	N	45, 25, 2		@ A#5
	N	48, 25, 2		@ C#6
	N	50, 25, 2		@ D#6
	N	51, 25, 2		@ E6
	N	52, 25, 2		@ F6
	N	55, 25, 2		@ G#6
	N	56, 25, 2		@ A6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 2		@ A#7
	N	72, 25, 4		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	69, 25, 2		@ A#7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 5		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	57, 25, 4		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 4		@ D#7
	N	64, 25, 6		@ F7
	N	66, 25, 2		@ G7
	N	67, 25, 2		@ G#7
	N	69, 25, 2		@ A#7
	N	62, 25, 4		@ D#7
	N	64, 25, 2		@ F7
	N	66, 25, 2		@ G7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	59, 25, 4		@ C7
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 4		@ A#7
	N	72, 25, 4		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	57, 25, 2		@ A#6
	N	60, 25, 4		@ C#7
	N	62, 25, 2		@ D#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	57, 25, 2		@ A#6
	N	55, 25, 4		@ G#6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 23		@ A#7
	N	67, 25, 4		@ G#7
	N	66, 25, 2		@ G7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 4		@ D#7
	N	60, 25, 2		@ C#7
	N	59, 25, 2		@ C7
	N	57, 25, 2		@ A#6
	N	55, 25, 4		@ G#6
	N	59, 25, 4		@ C7
	PAT_END

pat_083CF8EF:				@ used by s3c6
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	65, 25, 2		@ F#7
	N	58, 25, 2		@ B6
	N	62, 25, 2		@ D#7
	N	65, 25, 2		@ F#7
	N	58, 25, 2		@ B6
	N	62, 25, 2		@ D#7
	N	65, 25, 2		@ F#7
	N	63, 25, 2		@ E7
	N	62, 25, 2		@ D#7
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	60, 25, 2		@ C#7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	59, 25, 2		@ C7
	N	62, 25, 2		@ D#7
	N	67, 25, 2		@ G#7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	58, 25, 2		@ B6
	N	63, 25, 2		@ E7
	N	67, 25, 2		@ G#7
	N	63, 25, 2		@ E7
	N	58, 25, 4		@ B6
	N	56, 25, 7		@ A6
	N	58, 25, 2		@ B6
	N	60, 25, 2		@ C#7
	N	58, 25, 4		@ B6
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	58, 25, 4		@ B6
	PAT_END

pat_083CFA4C:				@ used by s3c6
	N	45, 25, 9		@ A#5
	N	52, 25, 6		@ F6
	N	51, 25, 8		@ E6
	N	52, 25, 8		@ F6
	N	45, 25, 9		@ A#5
	N	47, 25, 6		@ C6
	N	48, 25, 9		@ C#6
	N	47, 25, 4		@ C6
	N	45, 25, 4		@ A#5
	N	44, 25, 10		@ A5
	N	53, 25, 10		@ F#6
	N	56, 25, 9		@ A6
	N	55, 25, 4		@ G#6
	N	56, 25, 4		@ A6
	N	53, 25, 10		@ F#6
	N	52, 25, 9		@ F6
	N	50, 25, 4		@ D#6
	N	52, 25, 4		@ F6
	N	47, 25, 9		@ C6
	N	48, 25, 4		@ C#6
	N	50, 25, 4		@ D#6
	N	44, 25, 9		@ A5
	N	45, 25, 4		@ A#5
	N	47, 25, 4		@ C6
	N	50, 25, 10		@ D#6
	PAT_END

pat_083CFA98:				@ used by s3c6
	N	52, 25, 4		@ F6
	N	55, 25, 2		@ G#6
	N	56, 25, 2		@ A6
	N	57, 25, 2		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 4		@ F7
	N	69, 25, 4		@ A#7
	N	69, 25, 4		@ A#7
	N	67, 25, 2		@ G#7
	N	69, 25, 4		@ A#7
	N	72, 25, 2		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 4		@ F7
	N	62, 25, 2		@ D#7
	N	64, 25, 23		@ F7
	N	67, 25, 2		@ G#7
	N	69, 25, 2		@ A#7
	N	72, 25, 4		@ C#8
	N	69, 25, 4		@ A#7
	N	67, 25, 4		@ G#7
	N	64, 25, 2		@ F7
	N	62, 25, 4		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	54, 25, 7		@ G6
	N	55, 25, 2		@ G#6
	N	57, 25, 2		@ A#6
	N	59, 25, 4		@ C7
	N	57, 25, 4		@ A#6
	N	55, 25, 6		@ G#6
	N	57, 25, 4		@ A#6
	N	60, 25, 2		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	67, 25, 2		@ G#7
	N	68, 25, 2		@ A7
	N	69, 25, 4		@ A#7
	N	69, 25, 4		@ A#7
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	72, 25, 4		@ C#8
	N	69, 25, 2		@ A#7
	N	67, 25, 2		@ G#7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	64, 25, 2		@ F7
	N	62, 25, 2		@ D#7
	N	60, 25, 4		@ C#7
	N	57, 25, 4		@ A#6
	N	57, 25, 4		@ A#6
	N	55, 25, 2		@ G#6
	N	57, 25, 5		@ A#6
	N	60, 25, 4		@ C#7
	N	64, 25, 4		@ F7
	N	65, 25, 2		@ F#7
	N	64, 25, 5		@ F7
	N	62, 25, 4		@ D#7
	N	60, 25, 6		@ C#7
	N	62, 25, 6		@ D#7
	N	60, 25, 5		@ C#7
	N	59, 25, 5		@ C7
	N	55, 25, 4		@ G#6
	N	59, 25, 6		@ C7
	PAT_END

pat_083CFB71:				@ used by s3c6
	N	60, 25, 7		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 5		@ E7
	N	65, 25, 4		@ F#7
	N	67, 25, 6		@ G#7
	N	67, 25, 6		@ G#7
	N	62, 25, 6		@ D#7
	N	59, 25, 6		@ C7
	N	70, 25, 4		@ B7
	N	68, 25, 4		@ A7
	N	67, 25, 7		@ G#7
	N	65, 25, 2		@ F#7
	N	63, 25, 5		@ E7
	N	65, 25, 4		@ F#7
	N	67, 25, 4		@ G#7
	N	63, 25, 4		@ E7
	N	65, 25, 2		@ F#7
	N	67, 25, 2		@ G#7
	N	65, 25, 2		@ F#7
	N	63, 25, 2		@ E7
	N	62, 25, 4		@ D#7
	N	63, 25, 4		@ E7
	N	62, 25, 4		@ D#7
	N	60, 25, 4		@ C#7
	N	62, 25, 4		@ D#7
	N	58, 25, 4		@ B6
	N	60, 25, 24		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 5		@ E7
	N	65, 25, 4		@ F#7
	N	67, 25, 5		@ G#7
	N	68, 25, 4		@ A7
	N	67, 25, 7		@ G#7
	N	65, 25, 2		@ F#7
	N	63, 25, 24		@ E7
	N	62, 25, 6		@ D#7
	N	70, 25, 7		@ B7
	N	68, 25, 2		@ A7
	N	67, 25, 5		@ G#7
	N	65, 25, 4		@ F#7
	N	63, 25, 4		@ E7
	N	62, 25, 4		@ D#7
	N	60, 25, 7		@ C#7
	N	62, 25, 2		@ D#7
	N	63, 25, 2		@ E7
	N	62, 25, 8		@ D#7
	PAT_END

pat_083CFBFC:				@ used by s3c7
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	42, 19, 2		@ G5
	N	42, 20, 2		@ G5
	N	42, 21, 2		@ G5
	N	42, 22, 2		@ G5
	N	42, 24, 2		@ G5
	N	42, 22, 2		@ G5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	43, 19, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	PAT_END

pat_083CFCBD:				@ used by s3c7
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	N	50, 19, 2		@ D#6
	N	50, 20, 2		@ D#6
	N	50, 21, 2		@ D#6
	N	48, 22, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	47, 21, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 19, 2		@ C6
	N	43, 20, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 24, 2		@ G#5
	N	43, 22, 2		@ G#5
	N	43, 21, 2		@ G#5
	N	43, 20, 2		@ G#5
	PAT_END

pat_083CFD7E:				@ used by s3c7
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	47, 19, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 24, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 19, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 24, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 20, 2		@ C6
	N	51, 19, 2		@ E6
	N	51, 20, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 24, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 20, 2		@ E6
	N	51, 19, 2		@ E6
	N	51, 20, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 24, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 20, 2		@ E6
	N	46, 19, 2		@ B5
	N	46, 20, 2		@ B5
	N	46, 21, 2		@ B5
	N	46, 22, 2		@ B5
	N	46, 24, 2		@ B5
	N	46, 22, 2		@ B5
	N	46, 21, 2		@ B5
	N	46, 20, 2		@ B5
	N	46, 19, 2		@ B5
	N	46, 20, 2		@ B5
	N	46, 21, 2		@ B5
	N	46, 22, 2		@ B5
	N	46, 24, 2		@ B5
	N	46, 22, 2		@ B5
	N	46, 21, 2		@ B5
	N	46, 20, 2		@ B5
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 19, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 24, 2		@ C#6
	N	48, 22, 2		@ C#6
	N	48, 21, 2		@ C#6
	N	48, 20, 2		@ C#6
	N	47, 19, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 24, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 19, 2		@ C6
	N	47, 20, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 24, 2		@ C6
	N	47, 22, 2		@ C6
	N	47, 21, 2		@ C6
	N	47, 20, 2		@ C6
	N	51, 19, 2		@ E6
	N	51, 20, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 24, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 20, 2		@ E6
	N	51, 19, 2		@ E6
	N	51, 20, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 24, 2		@ E6
	N	51, 22, 2		@ E6
	N	51, 21, 2		@ E6
	N	51, 20, 2		@ E6
	N	44, 19, 2		@ A5
	N	44, 20, 2		@ A5
	N	44, 21, 2		@ A5
	N	44, 22, 2		@ A5
	N	44, 24, 2		@ A5
	N	44, 22, 2		@ A5
	N	44, 21, 2		@ A5
	N	46, 20, 2		@ B5
	N	46, 19, 2		@ B5
	N	46, 20, 2		@ B5
	N	46, 21, 2		@ B5
	N	46, 22, 2		@ B5
	N	46, 24, 2		@ B5
	N	46, 22, 2		@ B5
	N	46, 21, 2		@ B5
	N	46, 20, 2		@ B5
	PAT_END

pat_083CFEFF:				@ used by s3c7
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 20, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 24, 2		@ A#5
	N	45, 22, 2		@ A#5
	N	45, 21, 2		@ A#5
	N	45, 20, 2		@ A#5
	PAT_END

pat_083CFFC0:				@ used by s3c8
	N	48, 17, 8		@ C#6
	N	48, 17, 8		@ C#6
	N	48, 17, 8		@ C#6
	N	48, 17, 7		@ C#6
	N	48, 17, 4		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	PAT_END

pat_083CFFE8:				@ used by s3c8
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 4		@ C#6
	N	48, 18, 2		@ C#6
	N	48, 18, 2		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 6		@ C#6
	N	48, 17, 4		@ C#6
	N	48, 18, 2		@ C#6
	N	48, 18, 2		@ C#6
	PAT_END

pat_083D0025:				@ used by s3c8
	N	48, 16, 37		@ C#6
	PAT_END

pat_083D0029:				@ used by s3c1
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 2		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 4		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 2		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 4		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 2		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	49, 10, 6		@ D6
	N	49, 10, 6		@ D6
	N	50, 10, 6		@ D#6
	N	50, 10, 6		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 2		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 4		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 2		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 4		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	50, 10, 2		@ D#6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 10, 4		@ F6
	N	52, 10, 4		@ F6
	N	57, 10, 6		@ A#6
	N	55, 10, 5		@ G#6
	N	54, 10, 6		@ G6
	N	50, 10, 24		@ D#6
	PAT_END

pat_083D00E4:				@ used by s3c1
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 2		@ G#6
	N	55, 10, 21		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 2		@ G#6
	N	55, 10, 21		@ G#6
	N	51, 10, 4		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 2		@ E6
	N	51, 10, 21		@ E6
	N	53, 10, 4		@ F#6
	N	53, 10, 4		@ F#6
	N	53, 10, 4		@ F#6
	N	53, 10, 2		@ F#6
	N	53, 10, 21		@ F#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 2		@ G#6
	N	55, 10, 21		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 10, 2		@ G#6
	N	55, 10, 21		@ G#6
	N	51, 10, 4		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 2		@ E6
	N	51, 10, 21		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 4		@ E6
	N	51, 10, 2		@ E6
	N	53, 10, 4		@ F#6
	N	53, 10, 4		@ F#6
	N	53, 10, 2		@ F#6
	N	53, 10, 4		@ F#6
	N	53, 10, 4		@ F#6
	PAT_END

pat_083D0169:				@ used by s3c1
	REST	0, 12
	REST	0, 12
	N	60, 10, 10		@ C#7
	N	60, 10, 10		@ C#7
	N	60, 10, 10		@ C#7
	N	60, 10, 10		@ C#7
	N	59, 10, 10		@ C7
	N	59, 10, 10		@ C7
	N	59, 10, 10		@ C7
	N	59, 10, 10		@ C7
	PAT_END

pat_083D0188:				@ used by s3c2
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 2		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 4		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 2		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 4		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 2		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	42, 10, 6		@ G5
	N	42, 10, 6		@ G5
	N	43, 10, 6		@ G#5
	N	43, 10, 6		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 2		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 4		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 2		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 4		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 2		@ A#5
	N	45, 10, 4		@ A#5
	N	45, 10, 4		@ A#5
	N	50, 10, 6		@ D#6
	N	48, 10, 5		@ C#6
	N	47, 10, 6		@ C6
	N	43, 10, 24		@ G#5
	PAT_END

pat_083D0243:				@ used by s3c2
	N	48, 10, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	48, 10, 2		@ C#6
	N	48, 10, 21		@ C#6
	N	47, 10, 4		@ C6
	N	47, 10, 4		@ C6
	N	47, 10, 4		@ C6
	N	47, 10, 2		@ C6
	N	47, 10, 21		@ C6
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 2		@ B5
	N	46, 10, 21		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 2		@ B5
	N	46, 10, 21		@ B5
	N	48, 10, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	48, 10, 2		@ C#6
	N	48, 10, 21		@ C#6
	N	47, 10, 4		@ C6
	N	47, 10, 4		@ C6
	N	47, 10, 4		@ C6
	N	47, 10, 2		@ C6
	N	47, 10, 21		@ C6
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 2		@ B5
	N	46, 10, 21		@ B5
	N	44, 10, 4		@ A5
	N	44, 10, 4		@ A5
	N	44, 10, 4		@ A5
	N	44, 10, 2		@ A5
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 2		@ B5
	N	46, 10, 4		@ B5
	N	46, 10, 4		@ B5
	PAT_END

pat_083D02C8:				@ used by s3c2
	REST	0, 12
	REST	0, 12
	N	53, 10, 10		@ F#6
	N	53, 10, 10		@ F#6
	N	53, 10, 10		@ F#6
	N	53, 10, 10		@ F#6
	N	52, 10, 10		@ F6
	N	52, 10, 10		@ F6
	N	52, 10, 10		@ F6
	N	52, 10, 10		@ F6
	PAT_END

pat_083D02E7:				@ used by s3c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	PAT_END

pat_083D0468:				@ used by s2c5
	N	45, 4, 7		@ A#5
	N	40, 4, 6		@ F5
	N	40, 4, 6		@ F5
	N	43, 4, 25		@ G#5
	N	38, 4, 7		@ D#5
	N	45, 4, 6		@ A#5
	N	45, 4, 6		@ A#5
	N	46, 4, 25		@ B5
	N	45, 4, 7		@ A#5
	N	40, 4, 6		@ F5
	N	40, 4, 6		@ F5
	N	43, 4, 25		@ G#5
	N	43, 4, 7		@ G#5
	N	38, 4, 6		@ D#5
	N	38, 4, 6		@ D#5
	N	45, 4, 25		@ A#5
	PAT_END

pat_083D0499:				@ used by s2c5
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 6		@ A#5
	N	38, 4, 2		@ D#5
	N	39, 4, 2		@ E5
	N	40, 4, 4		@ F5
	N	40, 4, 6		@ F5
	N	43, 4, 7		@ G#5
	N	43, 4, 4		@ G#5
	N	41, 4, 2		@ F#5
	N	43, 4, 5		@ G#5
	N	41, 4, 4		@ F#5
	N	43, 4, 4		@ G#5
	N	41, 4, 4		@ F#5
	N	38, 4, 2		@ D#5
	N	36, 4, 2		@ C#5
	N	38, 4, 6		@ D#5
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	N	45, 4, 4		@ A#5
	N	45, 4, 6		@ A#5
	N	40, 4, 2		@ F5
	N	45, 4, 2		@ A#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	41, 4, 2		@ F#5
	N	46, 4, 4		@ B5
	N	46, 4, 4		@ B5
	N	46, 4, 2		@ B5
	N	46, 4, 4		@ B5
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 6		@ A#5
	N	38, 4, 2		@ D#5
	N	39, 4, 2		@ E5
	N	40, 4, 4		@ F5
	N	40, 4, 6		@ F5
	N	43, 4, 7		@ G#5
	N	43, 4, 4		@ G#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	41, 4, 2		@ F#5
	N	43, 4, 4		@ G#5
	N	38, 4, 4		@ D#5
	N	41, 4, 2		@ F#5
	N	42, 4, 2		@ G5
	N	43, 4, 2		@ G#5
	N	41, 4, 2		@ F#5
	N	43, 4, 6		@ G#5
	N	38, 4, 6		@ D#5
	N	38, 4, 6		@ D#5
	N	38, 4, 4		@ D#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 4		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 5		@ A#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	40, 4, 2		@ F5
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	PAT_END

pat_083D0563:				@ used by s2c5
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 6		@ A#5
	N	38, 4, 2		@ D#5
	N	39, 4, 2		@ E5
	N	40, 4, 4		@ F5
	N	40, 4, 6		@ F5
	N	43, 4, 7		@ G#5
	N	55, 4, 4		@ G#6
	N	53, 4, 2		@ F#6
	N	50, 4, 4		@ D#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	41, 4, 2		@ F#5
	N	40, 4, 2		@ F5
	N	38, 4, 2		@ D#5
	N	38, 4, 2		@ D#5
	N	36, 4, 2		@ C#5
	N	38, 4, 6		@ D#5
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	N	45, 4, 4		@ A#5
	N	45, 4, 6		@ A#5
	N	40, 4, 2		@ F5
	N	45, 4, 2		@ A#5
	N	46, 4, 4		@ B5
	N	58, 4, 4		@ B6
	N	57, 4, 4		@ A#6
	N	55, 4, 2		@ G#6
	N	50, 4, 4		@ D#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	48, 4, 2		@ C#6
	N	50, 4, 2		@ D#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	43, 4, 2		@ G#5
	N	45, 4, 2		@ A#5
	N	43, 4, 2		@ G#5
	N	45, 4, 6		@ A#5
	N	38, 4, 2		@ D#5
	N	39, 4, 2		@ E5
	N	40, 4, 4		@ F5
	N	40, 4, 6		@ F5
	N	43, 4, 7		@ G#5
	N	55, 4, 4		@ G#6
	N	53, 4, 2		@ F#6
	N	50, 4, 4		@ D#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	48, 4, 2		@ C#6
	N	50, 4, 2		@ D#6
	N	48, 4, 2		@ C#6
	N	46, 4, 2		@ B5
	N	41, 4, 2		@ F#5
	N	43, 4, 2		@ G#5
	N	41, 4, 2		@ F#5
	N	43, 4, 6		@ G#5
	N	36, 4, 2		@ C#5
	N	37, 4, 2		@ D5
	N	38, 4, 4		@ D#5
	N	38, 4, 6		@ D#5
	N	45, 4, 6		@ A#5
	N	52, 4, 4		@ F6
	N	50, 4, 4		@ D#6
	N	52, 4, 2		@ F6
	N	48, 4, 4		@ C#6
	N	52, 4, 2		@ F6
	N	48, 4, 2		@ C#6
	N	47, 4, 2		@ C6
	N	48, 4, 2		@ C#6
	N	47, 4, 2		@ C6
	N	43, 4, 2		@ G#5
	N	44, 4, 2		@ A5
	PAT_END

pat_083D0648:				@ used by s2c5
	N	57, 4, 6		@ A#6
	N	45, 4, 23		@ A#5
	N	45, 4, 2		@ A#5
	N	48, 4, 4		@ C#6
	N	45, 4, 4		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	50, 4, 2		@ D#6
	N	48, 4, 4		@ C#6
	N	50, 4, 7		@ D#6
	N	52, 4, 2		@ F6
	N	55, 4, 4		@ G#6
	N	57, 4, 6		@ A#6
	N	45, 4, 23		@ A#5
	N	45, 4, 2		@ A#5
	N	48, 4, 4		@ C#6
	N	45, 4, 4		@ A#5
	N	50, 4, 4		@ D#6
	N	50, 4, 4		@ D#6
	N	50, 4, 2		@ D#6
	N	48, 4, 4		@ C#6
	N	50, 4, 7		@ D#6
	N	50, 4, 2		@ D#6
	N	53, 4, 4		@ F#6
	N	55, 4, 6		@ G#6
	N	43, 4, 23		@ G#5
	N	43, 4, 2		@ G#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	46, 4, 4		@ B5
	N	48, 4, 7		@ C#6
	N	50, 4, 2		@ D#6
	N	53, 4, 4		@ F#6
	N	55, 4, 6		@ G#6
	N	43, 4, 8		@ G#5
	N	46, 4, 4		@ B5
	N	43, 4, 4		@ G#5
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	N	48, 4, 2		@ C#6
	N	46, 4, 4		@ B5
	N	48, 4, 21		@ C#6
	PAT_END

pat_083D06D0:				@ used by s2c5
	N	48, 4, 6		@ C#6
	N	36, 4, 23		@ C#5
	N	36, 4, 2		@ C#5
	N	38, 4, 4		@ D#5
	N	40, 4, 4		@ F5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	N	41, 4, 2		@ F#5
	N	40, 4, 4		@ F5
	N	41, 4, 23		@ F#5
	N	45, 4, 4		@ A#5
	N	48, 4, 6		@ C#6
	N	36, 4, 23		@ C#5
	N	36, 4, 2		@ C#5
	N	38, 4, 4		@ D#5
	N	40, 4, 4		@ F5
	N	41, 4, 4		@ F#5
	N	41, 4, 4		@ F#5
	N	41, 4, 2		@ F#5
	N	40, 4, 4		@ F5
	N	41, 4, 21		@ F#5
	N	47, 4, 6		@ C6
	N	35, 4, 23		@ C5
	N	35, 4, 2		@ C5
	N	37, 4, 4		@ D5
	N	39, 4, 4		@ E5
	N	40, 4, 4		@ F5
	N	40, 4, 4		@ F5
	N	40, 4, 2		@ F5
	N	38, 4, 4		@ D#5
	N	40, 4, 21		@ F5
	N	47, 4, 6		@ C6
	N	35, 4, 23		@ C5
	N	35, 4, 2		@ C5
	N	37, 4, 4		@ D5
	N	39, 4, 4		@ E5
	N	40, 4, 4		@ F5
	N	40, 4, 4		@ F5
	N	40, 4, 4		@ F5
	N	39, 4, 4		@ E5
	N	40, 4, 8		@ F5
	PAT_END

pat_083D074C:				@ used by s2c6
	N	60, 1, 6		@ C#7
	REST	0, 9
	N	60, 1, 6		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 6		@ C#7
	REST	0, 9
	N	60, 1, 6		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 6		@ C#7
	REST	0, 9
	N	60, 1, 6		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 7		@ C#7
	REST	0, 4
	N	60, 1, 7		@ C#7
	REST	0, 4
	REST	0, 6
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	PAT_END

pat_083D07B6:				@ used by s2c6
	N	60, 1, 6		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 6		@ C#7
	N	60, 1, 5		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	PAT_END

pat_083D0892:				@ used by s2c6
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 2, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	N	60, 2, 2		@ C#7
	PAT_END

pat_083D0980:				@ used by s2c7
	N	57, 10, 2		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 12, 2		@ A#6
	N	57, 13, 2		@ A#6
	N	57, 14, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	52, 12, 4		@ F6
	N	52, 11, 2		@ F6
	N	52, 10, 2		@ F6
	N	52, 11, 2		@ F6
	N	52, 12, 4		@ F6
	N	52, 13, 4		@ F6
	N	55, 14, 2		@ G#6
	N	55, 13, 2		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 12, 4		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 14, 2		@ G#6
	N	55, 13, 2		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 10, 2		@ G#6
	N	50, 11, 2		@ D#6
	N	50, 12, 4		@ D#6
	N	50, 13, 2		@ D#6
	N	50, 14, 4		@ D#6
	N	50, 13, 2		@ D#6
	N	57, 12, 4		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 10, 2		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	58, 14, 4		@ B6
	N	58, 13, 2		@ B6
	N	58, 12, 2		@ B6
	N	58, 11, 2		@ B6
	N	58, 10, 4		@ B6
	N	58, 11, 2		@ B6
	N	58, 12, 4		@ B6
	N	58, 13, 2		@ B6
	N	58, 14, 2		@ B6
	N	58, 13, 2		@ B6
	N	58, 12, 2		@ B6
	N	58, 11, 2		@ B6
	N	58, 10, 2		@ B6
	N	58, 11, 2		@ B6
	N	57, 12, 2		@ A#6
	N	57, 13, 4		@ A#6
	N	57, 14, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	57, 12, 4		@ A#6
	N	52, 11, 2		@ F6
	N	52, 10, 4		@ F6
	N	52, 11, 4		@ F6
	N	52, 12, 2		@ F6
	N	52, 13, 2		@ F6
	N	52, 14, 2		@ F6
	N	55, 13, 2		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 10, 2		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 14, 2		@ G#6
	N	55, 13, 2		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 13, 2		@ G#6
	N	55, 14, 2		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 12, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	50, 10, 4		@ D#6
	N	50, 11, 2		@ D#6
	N	50, 12, 2		@ D#6
	N	50, 13, 2		@ D#6
	N	50, 14, 2		@ D#6
	N	50, 13, 2		@ D#6
	N	57, 12, 2		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 10, 2		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	57, 14, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	57, 12, 2		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 10, 2		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 12, 2		@ A#6
	N	57, 13, 2		@ A#6
	PAT_END

pat_083D0AAD:				@ used by s2c7
	N	57, 10, 4		@ A#6
	N	57, 11, 4		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	57, 14, 4		@ A#6
	N	57, 13, 4		@ A#6
	N	57, 12, 2		@ A#6
	N	57, 11, 4		@ A#6
	N	57, 10, 4		@ A#6
	N	50, 11, 4		@ D#6
	N	50, 12, 4		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 14, 2		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 12, 4		@ D#6
	N	50, 11, 2		@ D#6
	N	50, 10, 4		@ D#6
	N	50, 11, 4		@ D#6
	N	57, 12, 4		@ A#6
	N	57, 13, 4		@ A#6
	N	57, 14, 4		@ A#6
	N	57, 13, 2		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 11, 4		@ A#6
	N	57, 10, 2		@ A#6
	N	57, 11, 4		@ A#6
	N	57, 12, 4		@ A#6
	N	50, 13, 4		@ D#6
	N	50, 14, 4		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 12, 2		@ D#6
	N	50, 11, 4		@ D#6
	N	50, 10, 4		@ D#6
	N	50, 11, 2		@ D#6
	N	50, 12, 4		@ D#6
	N	50, 13, 4		@ D#6
	N	55, 14, 4		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 12, 4		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 14, 4		@ G#6
	N	48, 13, 4		@ C#6
	N	48, 12, 4		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 10, 2		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 12, 4		@ C#6
	N	48, 13, 2		@ C#6
	N	48, 14, 4		@ C#6
	N	48, 13, 4		@ C#6
	N	55, 12, 4		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 11, 2		@ G#6
	N	55, 12, 4		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 14, 2		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 12, 4		@ G#6
	N	48, 11, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 12, 2		@ C#6
	N	48, 13, 4		@ C#6
	N	48, 14, 4		@ C#6
	N	48, 13, 2		@ C#6
	N	48, 12, 4		@ C#6
	N	48, 11, 4		@ C#6
	PAT_END

pat_083D0B86:				@ used by s2c7
	N	52, 10, 4		@ F6
	N	52, 11, 4		@ F6
	N	52, 12, 4		@ F6
	N	52, 13, 2		@ F6
	N	52, 14, 4		@ F6
	N	52, 13, 4		@ F6
	N	52, 12, 2		@ F6
	N	52, 11, 4		@ F6
	N	52, 10, 4		@ F6
	N	57, 11, 4		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 13, 4		@ A#6
	N	57, 14, 2		@ A#6
	N	57, 13, 4		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 10, 4		@ A#6
	N	57, 11, 4		@ A#6
	N	52, 12, 4		@ F6
	N	52, 13, 4		@ F6
	N	52, 14, 4		@ F6
	N	52, 13, 2		@ F6
	N	52, 12, 4		@ F6
	N	52, 11, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 11, 4		@ F6
	N	52, 12, 4		@ F6
	N	57, 13, 4		@ A#6
	N	57, 14, 4		@ A#6
	N	57, 13, 4		@ A#6
	N	57, 12, 2		@ A#6
	N	57, 11, 4		@ A#6
	N	57, 10, 4		@ A#6
	N	57, 11, 2		@ A#6
	N	57, 12, 4		@ A#6
	N	57, 13, 4		@ A#6
	N	50, 14, 4		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 12, 4		@ D#6
	N	50, 11, 2		@ D#6
	N	50, 10, 4		@ D#6
	N	50, 11, 4		@ D#6
	N	50, 12, 2		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 14, 4		@ D#6
	N	55, 13, 4		@ G#6
	N	55, 12, 4		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 10, 2		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 12, 4		@ G#6
	N	55, 13, 2		@ G#6
	N	55, 14, 4		@ G#6
	N	55, 13, 4		@ G#6
	N	50, 12, 4		@ D#6
	N	50, 11, 4		@ D#6
	N	50, 10, 4		@ D#6
	N	50, 11, 2		@ D#6
	N	50, 12, 4		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 14, 2		@ D#6
	N	50, 13, 4		@ D#6
	N	50, 12, 4		@ D#6
	N	55, 11, 4		@ G#6
	N	55, 10, 4		@ G#6
	N	55, 11, 4		@ G#6
	N	55, 12, 2		@ G#6
	N	55, 13, 4		@ G#6
	N	55, 14, 4		@ G#6
	N	55, 13, 2		@ G#6
	N	55, 12, 4		@ G#6
	N	55, 11, 4		@ G#6
	PAT_END

pat_083D0C5F:				@ used by s2c7
	N	48, 10, 4		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 12, 4		@ C#6
	N	48, 13, 2		@ C#6
	N	48, 14, 4		@ C#6
	N	48, 13, 4		@ C#6
	N	48, 12, 2		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	53, 11, 4		@ F#6
	N	53, 12, 4		@ F#6
	N	53, 13, 4		@ F#6
	N	53, 14, 2		@ F#6
	N	53, 13, 4		@ F#6
	N	53, 12, 4		@ F#6
	N	53, 11, 2		@ F#6
	N	53, 10, 4		@ F#6
	N	53, 11, 4		@ F#6
	N	48, 12, 4		@ C#6
	N	48, 13, 4		@ C#6
	N	48, 14, 4		@ C#6
	N	48, 13, 2		@ C#6
	N	48, 12, 4		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 10, 2		@ C#6
	N	48, 11, 4		@ C#6
	N	48, 12, 4		@ C#6
	N	53, 13, 4		@ F#6
	N	53, 14, 4		@ F#6
	N	53, 13, 4		@ F#6
	N	53, 12, 2		@ F#6
	N	53, 11, 4		@ F#6
	N	53, 10, 4		@ F#6
	N	53, 11, 2		@ F#6
	N	53, 12, 4		@ F#6
	N	53, 13, 4		@ F#6
	N	47, 14, 4		@ C6
	N	47, 13, 4		@ C6
	N	47, 12, 4		@ C6
	N	47, 11, 2		@ C6
	N	47, 10, 4		@ C6
	N	47, 11, 4		@ C6
	N	47, 12, 2		@ C6
	N	47, 13, 4		@ C6
	N	47, 14, 4		@ C6
	N	52, 13, 4		@ F6
	N	52, 12, 4		@ F6
	N	52, 11, 4		@ F6
	N	52, 10, 2		@ F6
	N	52, 11, 4		@ F6
	N	52, 12, 4		@ F6
	N	52, 13, 2		@ F6
	N	52, 14, 4		@ F6
	N	52, 13, 4		@ F6
	N	47, 12, 4		@ C6
	N	47, 11, 4		@ C6
	N	47, 10, 4		@ C6
	N	47, 11, 2		@ C6
	N	47, 12, 4		@ C6
	N	47, 13, 4		@ C6
	N	47, 14, 2		@ C6
	N	47, 13, 4		@ C6
	N	47, 12, 4		@ C6
	N	52, 11, 4		@ F6
	N	52, 10, 4		@ F6
	N	52, 11, 4		@ F6
	N	52, 12, 2		@ F6
	N	52, 13, 4		@ F6
	N	52, 14, 4		@ F6
	N	52, 13, 2		@ F6
	N	52, 12, 4		@ F6
	N	52, 11, 4		@ F6
	PAT_END

pat_083D0D38:				@ used by s2c8
	N	69, 5, 7		@ A#7
	N	64, 5, 2		@ F7
	N	65, 5, 2		@ F#7
	N	67, 5, 4		@ G#7
	N	65, 5, 6		@ F#7
	N	64, 5, 4		@ F7
	N	67, 5, 2		@ G#7
	N	65, 5, 2		@ F#7
	N	64, 5, 2		@ F7
	N	65, 5, 2		@ F#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	58, 5, 2		@ B6
	N	60, 5, 2		@ C#7
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	57, 5, 4		@ A#6
	N	60, 5, 4		@ C#7
	N	65, 5, 4		@ F#7
	N	67, 5, 6		@ G#7
	N	65, 5, 4		@ F#7
	N	64, 5, 6		@ F7
	N	65, 5, 2		@ F#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	58, 5, 2		@ B6
	N	60, 5, 2		@ C#7
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	72, 5, 7		@ C#8
	N	71, 5, 2		@ C8
	N	69, 5, 2		@ A#7
	N	71, 5, 4		@ C8
	N	69, 5, 4		@ A#7
	N	67, 5, 6		@ G#7
	N	70, 5, 2		@ B7
	N	69, 5, 2		@ A#7
	N	65, 5, 2		@ F#7
	N	62, 5, 2		@ D#7
	N	65, 5, 2		@ F#7
	N	69, 5, 2		@ A#7
	N	65, 5, 2		@ F#7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	65, 5, 2		@ F#7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	55, 5, 7		@ G#6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	60, 5, 4		@ C#7
	N	62, 5, 4		@ D#7
	N	64, 5, 4		@ F7
	N	67, 5, 4		@ G#7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	69, 5, 2		@ A#7
	N	67, 5, 2		@ G#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	63, 5, 2		@ E7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	56, 5, 4		@ A6
	PAT_END

pat_083D0E41:				@ used by s2c8
	N	45, 5, 2		@ A#5
	N	43, 5, 2		@ G#5
	N	45, 5, 2		@ A#5
	N	43, 5, 2		@ G#5
	N	45, 5, 2		@ A#5
	N	47, 5, 2		@ C6
	N	48, 5, 2		@ C#6
	N	47, 5, 2		@ C6
	N	48, 5, 2		@ C#6
	N	47, 5, 2		@ C6
	N	48, 5, 2		@ C#6
	N	50, 5, 2		@ D#6
	N	52, 5, 2		@ F6
	N	50, 5, 2		@ D#6
	N	52, 5, 2		@ F6
	N	53, 5, 2		@ F#6
	N	55, 5, 24		@ G#6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	52, 5, 2		@ F6
	N	50, 5, 2		@ D#6
	N	52, 5, 4		@ F6
	N	53, 5, 4		@ F#6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	52, 5, 4		@ F6
	N	53, 5, 2		@ F#6
	N	52, 5, 2		@ F6
	N	50, 5, 4		@ D#6
	N	48, 5, 4		@ C#6
	N	50, 5, 4		@ D#6
	N	52, 5, 4		@ F6
	N	50, 5, 2		@ D#6
	N	52, 5, 2		@ F6
	N	53, 5, 2		@ F#6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	55, 5, 2		@ G#6
	N	57, 5, 4		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	55, 5, 7		@ G#6
	N	53, 5, 2		@ F#6
	N	52, 5, 2		@ F6
	N	53, 5, 4		@ F#6
	N	52, 5, 4		@ F6
	N	50, 5, 4		@ D#6
	N	55, 5, 5		@ G#6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	52, 5, 2		@ F6
	N	50, 5, 2		@ D#6
	N	52, 5, 2		@ F6
	N	53, 5, 2		@ F#6
	N	52, 5, 2		@ F6
	N	50, 5, 2		@ D#6
	N	48, 5, 4		@ C#6
	N	50, 5, 4		@ D#6
	N	50, 5, 2		@ D#6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	60, 5, 5		@ C#7
	N	57, 5, 2		@ A#6
	N	58, 5, 4		@ B6
	N	57, 5, 4		@ A#6
	N	55, 5, 4		@ G#6
	N	52, 5, 4		@ F6
	N	57, 5, 24		@ A#6
	N	60, 5, 2		@ C#7
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	57, 5, 8		@ A#6
	PAT_END

pat_083D0F47:				@ used by s2c8
	N	55, 5, 19		@ G#6
	N	57, 5, 2		@ A#6
	N	59, 5, 2		@ C7
	N	60, 5, 6		@ C#7
	N	59, 5, 6		@ C7
	N	57, 5, 6		@ A#6
	N	55, 5, 6		@ G#6
	N	57, 5, 4		@ A#6
	N	59, 5, 4		@ C7
	N	55, 5, 4		@ G#6
	N	52, 5, 8		@ F6
	N	50, 5, 2		@ D#6
	N	48, 5, 2		@ C#6
	N	50, 5, 22		@ D#6
	N	52, 5, 4		@ F6
	N	53, 5, 6		@ F#6
	N	55, 5, 19		@ G#6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	60, 5, 6		@ C#7
	N	58, 5, 6		@ B6
	N	57, 5, 6		@ A#6
	N	55, 5, 6		@ G#6
	N	57, 5, 4		@ A#6
	N	58, 5, 4		@ B6
	N	55, 5, 4		@ G#6
	N	50, 5, 8		@ D#6
	N	51, 5, 2		@ E6
	N	53, 5, 2		@ F#6
	N	51, 5, 10		@ E6
	PAT_END

pat_083D0FA2:				@ used by s2c8
	N	64, 5, 7		@ F7
	N	62, 5, 2		@ D#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	59, 5, 2		@ C7
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	59, 5, 4		@ C7
	N	60, 5, 2		@ C#7
	N	59, 5, 2		@ C7
	N	60, 5, 2		@ C#7
	N	59, 5, 2		@ C7
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	52, 5, 2		@ F6
	N	54, 5, 2		@ G6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	59, 5, 2		@ C7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	64, 5, 2		@ F7
	N	66, 5, 4		@ G7
	N	67, 5, 4		@ G#7
	N	64, 5, 24		@ F7
	N	66, 5, 2		@ G7
	N	67, 5, 2		@ G#7
	N	64, 5, 2		@ F7
	N	66, 5, 2		@ G7
	N	67, 5, 2		@ G#7
	N	66, 5, 2		@ G7
	N	64, 5, 2		@ F7
	N	62, 5, 4		@ D#7
	N	64, 5, 4		@ F7
	N	60, 5, 4		@ C#7
	N	62, 5, 2		@ D#7
	N	59, 5, 4		@ C7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	59, 5, 4		@ C7
	N	57, 5, 4		@ A#6
	N	69, 5, 7		@ A#7
	N	67, 5, 2		@ G#7
	N	65, 5, 2		@ F#7
	N	67, 5, 4		@ G#7
	N	65, 5, 2		@ F#7
	N	64, 5, 2		@ F7
	N	65, 5, 4		@ F#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	64, 5, 2		@ F7
	N	65, 5, 2		@ F#7
	N	64, 5, 2		@ F7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	60, 5, 2		@ C#7
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	57, 5, 4		@ A#6
	N	58, 5, 1		@ B6
	N	57, 5, 1		@ A#6
	N	55, 5, 1		@ G#6
	N	57, 5, 7		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 5		@ F#6
	N	55, 5, 4		@ G#6
	N	57, 5, 4		@ A#6
	N	53, 5, 4		@ F#6
	N	55, 5, 2		@ G#6
	N	57, 5, 2		@ A#6
	N	55, 5, 2		@ G#6
	N	53, 5, 2		@ F#6
	N	52, 5, 4		@ F6
	N	53, 5, 2		@ F#6
	N	55, 5, 4		@ G#6
	N	57, 5, 2		@ A#6
	N	58, 5, 2		@ B6
	N	60, 5, 2		@ C#7
	N	62, 5, 2		@ D#7
	N	64, 5, 2		@ F7
	N	65, 5, 4		@ F#7
	PAT_END

pat_083D10B1:				@ used by s2c8
	N	67, 5, 19		@ G#7
	N	65, 5, 2		@ F#7
	N	64, 5, 2		@ F7
	N	65, 5, 4		@ F#7
	N	67, 5, 4		@ G#7
	N	64, 5, 22		@ F7
	N	62, 5, 4		@ D#7
	N	64, 5, 4		@ F7
	N	65, 5, 4		@ F#7
	N	64, 5, 6		@ F7
	N	60, 5, 7		@ C#7
	N	55, 5, 4		@ G#6
	N	57, 5, 10		@ A#6
	N	69, 5, 9		@ A#7
	N	68, 5, 4		@ A7
	N	66, 5, 4		@ G7
	N	68, 5, 4		@ A7
	N	69, 5, 4		@ A#7
	N	68, 5, 4		@ A7
	N	66, 5, 4		@ G7
	N	64, 5, 6		@ F7
	N	66, 5, 4		@ G7
	N	68, 5, 4		@ A7
	N	66, 5, 7		@ G7
	N	64, 5, 2		@ F7
	N	62, 5, 5		@ D#7
	N	64, 5, 4		@ F7
	N	66, 5, 4		@ G7
	N	62, 5, 4		@ D#7
	N	64, 5, 10		@ F7
	PAT_END

pat_083D110C:				@ used by s2c1
	N	36, 23, 7		@ C#5
	N	43, 23, 6		@ G#5
	N	43, 23, 6		@ G#5
	N	34, 24, 10		@ B4
	REST	0, 4
	N	41, 22, 7		@ F#5
	N	36, 24, 6		@ C#5
	N	36, 24, 6		@ C#5
	N	38, 27, 10		@ D#5
	REST	0, 4
	N	48, 22, 7		@ C#6
	N	43, 22, 6		@ G#5
	N	43, 22, 6		@ G#5
	N	46, 22, 10		@ B5
	REST	0, 4
	N	46, 22, 7		@ B5
	N	41, 22, 6		@ F#5
	N	41, 22, 6		@ F#5
	N	36, 24, 10		@ C#5
	REST	0, 4
	PAT_END

pat_083D1149:				@ used by s2c1
	N	36, 24, 10		@ C#5
	N	41, 22, 10		@ F#5
	N	36, 24, 10		@ C#5
	N	41, 22, 10		@ F#5
	N	34, 24, 10		@ B4
	N	39, 22, 10		@ E5
	N	34, 24, 10		@ B4
	N	39, 22, 10		@ E5
	PAT_END

pat_083D1162:				@ used by s2c1
	N	28, 27, 10		@ F4
	N	33, 26, 10		@ A#4
	N	28, 27, 10		@ F4
	N	33, 26, 10		@ A#4
	N	38, 22, 10		@ D#5
	N	28, 24, 10		@ F4
	N	38, 22, 10		@ D#5
	N	28, 24, 10		@ F4
	PAT_END

pat_083D117B:				@ used by s2c2
	REST	0, 10
	N	67, 28, 0		@ G#7
	N	70, 28, 0		@ B7
	N	74, 28, 0		@ D#8
	N	79, 28, 0		@ G#8
	N	67, 29, 0		@ G#7
	N	70, 29, 0		@ B7
	N	74, 29, 0		@ D#8
	N	79, 29, 20		@ G#8
	N	67, 30, 0		@ G#7
	N	70, 30, 0		@ B7
	N	74, 30, 0		@ D#8
	N	79, 30, 0		@ G#8
	N	67, 31, 0		@ G#7
	N	70, 31, 0		@ B7
	N	74, 31, 0		@ D#8
	N	79, 31, 20		@ G#8
	N	67, 32, 0		@ G#7
	N	70, 32, 0		@ B7
	N	74, 32, 0		@ D#8
	N	79, 32, 0		@ G#8
	N	67, 33, 0		@ G#7
	N	70, 33, 0		@ B7
	N	74, 33, 0		@ D#8
	N	79, 33, 0		@ G#8
	REST	0, 10
	N	69, 28, 0		@ A#7
	N	74, 28, 0		@ D#8
	N	77, 28, 0		@ F#8
	N	81, 28, 0		@ A#8
	N	69, 29, 0		@ A#7
	N	74, 29, 0		@ D#8
	N	77, 29, 0		@ F#8
	N	81, 29, 20		@ A#8
	N	69, 30, 0		@ A#7
	N	74, 30, 0		@ D#8
	N	77, 30, 0		@ F#8
	N	81, 30, 0		@ A#8
	N	69, 31, 0		@ A#7
	N	74, 31, 0		@ D#8
	N	77, 31, 0		@ F#8
	N	81, 31, 20		@ A#8
	N	69, 32, 0		@ A#7
	N	74, 32, 0		@ D#8
	N	77, 32, 0		@ F#8
	N	81, 32, 0		@ A#8
	N	69, 33, 0		@ A#7
	N	74, 33, 0		@ D#8
	N	77, 33, 0		@ F#8
	N	81, 33, 0		@ A#8
	REST	0, 10
	N	67, 28, 0		@ G#7
	N	70, 28, 0		@ B7
	N	74, 28, 0		@ D#8
	N	79, 28, 0		@ G#8
	N	67, 29, 0		@ G#7
	N	70, 29, 0		@ B7
	N	74, 29, 0		@ D#8
	N	79, 29, 20		@ G#8
	N	67, 30, 0		@ G#7
	N	70, 30, 0		@ B7
	N	74, 30, 0		@ D#8
	N	79, 30, 0		@ G#8
	N	67, 31, 0		@ G#7
	N	70, 31, 0		@ B7
	N	74, 31, 0		@ D#8
	N	79, 31, 20		@ G#8
	N	67, 32, 0		@ G#7
	N	70, 32, 0		@ B7
	N	74, 32, 0		@ D#8
	N	79, 32, 0		@ G#8
	N	67, 33, 0		@ G#7
	N	70, 33, 0		@ B7
	N	74, 33, 0		@ D#8
	N	79, 33, 0		@ G#8
	REST	0, 10
	N	69, 28, 0		@ A#7
	N	72, 28, 0		@ C#8
	N	76, 28, 0		@ F8
	N	79, 28, 0		@ G#8
	N	69, 29, 0		@ A#7
	N	72, 29, 0		@ C#8
	N	76, 29, 0		@ F8
	N	79, 29, 20		@ G#8
	N	69, 30, 0		@ A#7
	N	72, 30, 0		@ C#8
	N	76, 30, 0		@ F8
	N	79, 30, 0		@ G#8
	N	69, 31, 0		@ A#7
	N	72, 31, 0		@ C#8
	N	76, 31, 0		@ F8
	N	79, 31, 20		@ G#8
	N	69, 32, 0		@ A#7
	N	72, 32, 0		@ C#8
	N	76, 32, 0		@ F8
	N	79, 32, 0		@ G#8
	N	69, 33, 0		@ A#7
	N	72, 33, 0		@ C#8
	N	76, 33, 0		@ F8
	N	79, 33, 0		@ G#8
	PAT_END

pat_083D12A8:				@ used by s2c2
	REST	0, 10
	N	62, 28, 0		@ D#7
	N	65, 28, 0		@ F#7
	N	69, 28, 0		@ A#7
	N	74, 28, 0		@ D#8
	N	62, 29, 0		@ D#7
	N	65, 29, 0		@ F#7
	N	69, 29, 0		@ A#7
	N	74, 29, 20		@ D#8
	N	62, 30, 0		@ D#7
	N	65, 30, 0		@ F#7
	N	69, 30, 0		@ A#7
	N	74, 30, 0		@ D#8
	N	62, 31, 0		@ D#7
	N	65, 31, 0		@ F#7
	N	69, 31, 0		@ A#7
	N	74, 31, 20		@ D#8
	N	62, 32, 0		@ D#7
	N	65, 32, 0		@ F#7
	N	69, 32, 0		@ A#7
	N	74, 32, 0		@ D#8
	N	62, 33, 0		@ D#7
	N	65, 33, 0		@ F#7
	N	69, 33, 0		@ A#7
	N	74, 33, 0		@ D#8
	REST	0, 10
	N	69, 28, 0		@ A#7
	N	74, 28, 0		@ D#8
	N	77, 28, 0		@ F#8
	N	81, 28, 0		@ A#8
	N	69, 29, 0		@ A#7
	N	74, 29, 0		@ D#8
	N	77, 29, 0		@ F#8
	N	81, 29, 20		@ A#8
	N	69, 30, 0		@ A#7
	N	74, 30, 0		@ D#8
	N	77, 30, 0		@ F#8
	N	81, 30, 0		@ A#8
	N	69, 31, 0		@ A#7
	N	74, 31, 0		@ D#8
	N	77, 31, 0		@ F#8
	N	81, 31, 20		@ A#8
	N	69, 32, 0		@ A#7
	N	74, 32, 0		@ D#8
	N	77, 32, 0		@ F#8
	N	81, 32, 0		@ A#8
	N	69, 33, 0		@ A#7
	N	74, 33, 0		@ D#8
	N	77, 33, 0		@ F#8
	N	81, 33, 0		@ A#8
	REST	0, 10
	N	67, 28, 0		@ G#7
	N	70, 28, 0		@ B7
	N	74, 28, 0		@ D#8
	N	79, 28, 0		@ G#8
	N	67, 29, 0		@ G#7
	N	70, 29, 0		@ B7
	N	74, 29, 0		@ D#8
	N	79, 29, 20		@ G#8
	N	67, 30, 0		@ G#7
	N	70, 30, 0		@ B7
	N	74, 30, 0		@ D#8
	N	79, 30, 0		@ G#8
	N	67, 31, 0		@ G#7
	N	70, 31, 0		@ B7
	N	74, 31, 0		@ D#8
	N	79, 31, 20		@ G#8
	N	67, 32, 0		@ G#7
	N	70, 32, 0		@ B7
	N	74, 32, 0		@ D#8
	N	79, 32, 0		@ G#8
	N	67, 33, 0		@ G#7
	N	70, 33, 0		@ B7
	N	74, 33, 0		@ D#8
	N	79, 33, 0		@ G#8
	REST	0, 10
	N	67, 28, 0		@ G#7
	N	72, 28, 0		@ C#8
	N	75, 28, 0		@ E8
	N	79, 28, 0		@ G#8
	N	67, 29, 0		@ G#7
	N	72, 29, 0		@ C#8
	N	75, 29, 0		@ E8
	N	79, 29, 20		@ G#8
	N	67, 30, 0		@ G#7
	N	72, 30, 0		@ C#8
	N	75, 30, 0		@ E8
	N	79, 30, 0		@ G#8
	N	67, 31, 0		@ G#7
	N	72, 31, 0		@ C#8
	N	75, 31, 0		@ E8
	N	79, 31, 20		@ G#8
	N	67, 32, 0		@ G#7
	N	72, 32, 0		@ C#8
	N	75, 32, 0		@ E8
	N	79, 32, 0		@ G#8
	N	67, 33, 0		@ G#7
	N	72, 33, 0		@ C#8
	N	75, 33, 0		@ E8
	N	79, 33, 0		@ G#8
	PAT_END

pat_083D13D5:				@ used by s2c2
	REST	0, 10
	N	69, 28, 0		@ A#7
	N	72, 28, 0		@ C#8
	N	76, 28, 0		@ F8
	N	81, 28, 0		@ A#8
	N	69, 29, 0		@ A#7
	N	72, 29, 0		@ C#8
	N	76, 29, 0		@ F8
	N	81, 29, 20		@ A#8
	N	69, 30, 0		@ A#7
	N	72, 30, 0		@ C#8
	N	76, 30, 0		@ F8
	N	81, 30, 0		@ A#8
	N	69, 31, 0		@ A#7
	N	72, 31, 0		@ C#8
	N	76, 31, 0		@ F8
	N	81, 31, 20		@ A#8
	N	69, 32, 0		@ A#7
	N	72, 32, 0		@ C#8
	N	76, 32, 0		@ F8
	N	81, 32, 0		@ A#8
	N	69, 33, 0		@ A#7
	N	72, 33, 0		@ C#8
	N	76, 33, 0		@ F8
	N	81, 33, 0		@ A#8
	REST	0, 10
	N	76, 28, 0		@ F8
	N	81, 28, 0		@ A#8
	N	84, 28, 0		@ C#9
	N	88, 28, 0		@ F9
	N	76, 29, 0		@ F8
	N	81, 29, 0		@ A#8
	N	84, 29, 0		@ C#9
	N	88, 29, 20		@ F9
	N	76, 30, 0		@ F8
	N	81, 30, 0		@ A#8
	N	84, 30, 0		@ C#9
	N	88, 30, 0		@ F9
	N	76, 31, 0		@ F8
	N	81, 31, 0		@ A#8
	N	84, 31, 0		@ C#9
	N	88, 31, 20		@ F9
	N	76, 32, 0		@ F8
	N	81, 32, 0		@ A#8
	N	84, 32, 0		@ C#9
	N	88, 32, 0		@ F9
	N	76, 33, 0		@ F8
	N	81, 33, 0		@ A#8
	N	84, 33, 0		@ C#9
	N	88, 33, 0		@ F9
	REST	0, 10
	N	68, 28, 0		@ A7
	N	76, 28, 0		@ F8
	N	80, 28, 0		@ A8
	N	83, 28, 0		@ C9
	N	68, 29, 0		@ A7
	N	76, 29, 0		@ F8
	N	80, 29, 0		@ A8
	N	83, 29, 20		@ C9
	N	68, 30, 0		@ A7
	N	76, 30, 0		@ F8
	N	80, 30, 0		@ A8
	N	83, 30, 0		@ C9
	N	68, 31, 0		@ A7
	N	76, 31, 0		@ F8
	N	80, 31, 0		@ A8
	N	83, 31, 20		@ C9
	N	68, 32, 0		@ A7
	N	76, 32, 0		@ F8
	N	80, 32, 0		@ A8
	N	83, 32, 0		@ C9
	N	68, 33, 0		@ A7
	N	76, 33, 0		@ F8
	N	80, 33, 0		@ A8
	N	83, 33, 0		@ C9
	REST	0, 10
	N	68, 28, 0		@ A7
	N	76, 28, 0		@ F8
	N	80, 28, 0		@ A8
	N	83, 28, 0		@ C9
	N	68, 29, 0		@ A7
	N	76, 29, 0		@ F8
	N	80, 29, 0		@ A8
	N	83, 29, 20		@ C9
	N	68, 30, 0		@ A7
	N	76, 30, 0		@ F8
	N	80, 30, 0		@ A8
	N	83, 30, 0		@ C9
	N	68, 31, 0		@ A7
	N	76, 31, 0		@ F8
	N	80, 31, 0		@ A8
	N	83, 31, 20		@ C9
	N	68, 32, 0		@ A7
	N	76, 32, 0		@ F8
	N	80, 32, 0		@ A8
	N	83, 32, 0		@ C9
	N	68, 33, 0		@ A7
	N	76, 33, 0		@ F8
	N	80, 33, 0		@ A8
	N	83, 33, 0		@ C9
	PAT_END

pat_083D1502:				@ used by s2c4
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	46, 5, 4		@ B5
	PAT_END

pat_083D15C3:				@ used by s2c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	PAT_END

pat_083D1744:				@ used by s2c4
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 4		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 5		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 5		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	PAT_END

pat_083D1835:				@ used by s1c5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 10
	REST	0, 7
	N	46, 4, 4		@ B5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	N	41, 4, 8		@ F#5
	REST	0, 7
	N	46, 4, 4		@ B5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 10
	REST	0, 7
	N	46, 4, 4		@ B5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	N	48, 4, 8		@ C#6
	REST	0, 7
	N	46, 4, 4		@ B5
	PAT_END

pat_083D1896:				@ used by s1c5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 6		@ A#5
	N	33, 4, 7		@ A#4
	REST	0, 8
	REST	0, 7
	N	46, 4, 4		@ B5
	N	45, 4, 7		@ A#5
	N	45, 4, 6		@ A#5
	N	40, 4, 6		@ F5
	N	45, 4, 4		@ A#5
	N	41, 4, 7		@ F#5
	N	29, 4, 6		@ F#4
	REST	0, 6
	N	46, 4, 4		@ B5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	33, 4, 10		@ A#4
	REST	0, 4
	N	46, 4, 4		@ B5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 6		@ A#5
	N	45, 4, 5		@ A#5
	REST	0, 2
	N	45, 4, 4		@ A#5
	N	48, 4, 7		@ C#6
	N	36, 4, 8		@ C#5
	REST	0, 4
	PAT_END

pat_083D18F4:				@ used by s1c5
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 6		@ A#5
	N	40, 4, 6		@ F5
	N	45, 4, 4		@ A#5
	N	46, 4, 22		@ B5
	N	34, 4, 7		@ B4
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 6		@ A#5
	N	40, 4, 6		@ F5
	N	45, 4, 4		@ A#5
	N	41, 4, 7		@ F#5
	N	29, 4, 22		@ F#4
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 4		@ A#5
	REST	0, 4
	N	40, 4, 6		@ F5
	N	45, 4, 4		@ A#5
	N	46, 4, 7		@ B5
	N	34, 4, 22		@ B4
	N	45, 4, 6		@ A#5
	REST	0, 4
	N	45, 4, 6		@ A#5
	N	40, 4, 6		@ F5
	N	45, 4, 4		@ A#5
	N	48, 4, 7		@ C#6
	N	36, 4, 22		@ C#5
	PAT_END

pat_083D194C:				@ used by s1c5
	N	45, 4, 6		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	N	36, 4, 8		@ C#5
	N	48, 4, 6		@ C#6
	REST	0, 6
	N	45, 4, 6		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	N	41, 4, 8		@ F#5
	N	53, 4, 6		@ F#6
	REST	0, 6
	N	45, 4, 6		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	N	43, 4, 4		@ G#5
	N	45, 4, 6		@ A#5
	N	48, 4, 8		@ C#6
	N	36, 4, 8		@ C#5
	N	46, 4, 6		@ B5
	N	45, 4, 4		@ A#5
	N	46, 4, 6		@ B5
	N	45, 4, 4		@ A#5
	N	46, 4, 6		@ B5
	N	45, 4, 9		@ A#5
	REST	0, 6
	PAT_END

pat_083D19A7:				@ used by s1c5
	N	38, 4, 6		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 4		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 6		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 4		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 6		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 4		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 6		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 2		@ D#5
	N	50, 4, 4		@ D#6
	N	38, 4, 4		@ D#5
	N	50, 4, 4		@ D#6
	PAT_END

pat_083D1A08:				@ used by s1c6
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 7		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 6		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 6		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 6		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	PAT_END

pat_083D1A6F:				@ used by s1c6
	N	60, 1, 6		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	PAT_END

pat_083D1B3C:				@ used by s1c6
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 7		@ C#7
	N	55, 2, 4		@ G#6
	N	60, 1, 4		@ C#7
	N	60, 1, 6		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	55, 2, 6		@ G#6
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	55, 2, 4		@ G#6
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 7		@ C#7
	N	60, 1, 4		@ C#7
	REST	0, 8
	REST	0, 4
	N	60, 1, 6		@ C#7
	N	60, 1, 4		@ C#7
	N	55, 2, 4		@ G#6
	N	60, 1, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	PAT_END

pat_083D1BAF:				@ used by s1c6
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 2		@ C#7
	PAT_END

pat_083D1C4C:				@ used by s1c6
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 1, 4		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 4		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 1, 2		@ C#7
	N	60, 8, 2		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	N	60, 8, 0		@ C#7
	PAT_END

pat_083D1CF5:				@ used by s1c7
	N	40, 5, 6		@ F5
	N	39, 5, 4		@ E5
	N	40, 5, 7		@ F5
	N	33, 5, 6		@ A#4
	N	36, 5, 8		@ C#5
	N	34, 5, 8		@ B4
	N	33, 5, 6		@ A#4
	N	32, 5, 4		@ A4
	N	33, 5, 6		@ A#4
	N	28, 5, 7		@ F4
	N	31, 5, 8		@ G#4
	N	29, 5, 8		@ F#4
	N	28, 5, 6		@ F4
	N	27, 5, 4		@ E4
	N	28, 5, 6		@ F4
	N	21, 5, 7		@ A#3
	N	24, 5, 8		@ C#4
	N	22, 5, 8		@ B3
	N	21, 5, 6		@ A#3
	N	20, 5, 4		@ A3
	N	21, 5, 7		@ A#3
	N	28, 5, 6		@ F4
	N	24, 5, 4		@ C#4
	N	26, 5, 4		@ D#4
	N	27, 5, 4		@ E4
	N	31, 5, 4		@ G#4
	N	36, 5, 4		@ C#5
	N	43, 5, 4		@ G#5
	N	48, 5, 6		@ C#6
	PAT_END

pat_083D1D4D:				@ used by s1c7
	N	52, 5, 6		@ F6
	N	51, 5, 4		@ E6
	N	52, 5, 6		@ F6
	N	45, 5, 7		@ A#5
	N	55, 5, 8		@ G#6
	N	53, 5, 8		@ F#6
	N	52, 5, 6		@ F6
	N	51, 5, 4		@ E6
	N	52, 5, 6		@ F6
	N	45, 5, 7		@ A#5
	N	48, 5, 8		@ C#6
	N	46, 5, 8		@ B5
	N	45, 5, 6		@ A#5
	N	44, 5, 4		@ A5
	N	45, 5, 6		@ A#5
	N	40, 5, 7		@ F5
	N	43, 5, 8		@ G#5
	N	41, 5, 8		@ F#5
	N	40, 5, 6		@ F5
	N	39, 5, 4		@ E5
	N	40, 5, 7		@ F5
	N	33, 5, 6		@ A#4
	N	35, 5, 8		@ C5
	N	36, 5, 8		@ C#5
	PAT_END

pat_083D1D96:				@ used by s1c7
	N	45, 6, 7		@ A#5
	N	48, 6, 2		@ C#6
	N	52, 6, 2		@ F6
	N	57, 6, 6		@ A#6
	N	56, 6, 6		@ A6
	N	55, 6, 6		@ G#6
	N	53, 6, 6		@ F#6
	N	51, 6, 8		@ E6
	N	52, 6, 7		@ F6
	N	45, 6, 2		@ A#5
	N	48, 6, 2		@ C#6
	N	52, 6, 6		@ F6
	N	57, 6, 6		@ A#6
	N	58, 6, 8		@ B6
	N	56, 6, 8		@ A6
	N	57, 6, 7		@ A#6
	N	52, 6, 2		@ F6
	N	48, 6, 2		@ C#6
	N	45, 6, 6		@ A#5
	N	52, 6, 6		@ F6
	N	55, 6, 7		@ G#6
	N	56, 6, 4		@ A6
	N	55, 6, 8		@ G#6
	N	53, 6, 7		@ F#6
	N	46, 6, 2		@ B5
	N	49, 6, 2		@ D6
	N	53, 6, 6		@ F#6
	N	58, 6, 6		@ B6
	N	57, 6, 2		@ A#6
	N	58, 6, 2		@ B6
	N	57, 6, 2		@ A#6
	N	58, 6, 2		@ B6
	N	57, 6, 2		@ A#6
	N	58, 6, 2		@ B6
	N	57, 6, 2		@ A#6
	N	58, 6, 2		@ B6
	N	57, 6, 8		@ A#6
	PAT_END

pat_083D1E06:				@ used by s1c7
	N	52, 6, 8		@ F6
	N	47, 6, 6		@ C6
	N	52, 6, 6		@ F6
	N	53, 6, 8		@ F#6
	N	52, 6, 6		@ F6
	N	50, 6, 6		@ D#6
	N	52, 6, 8		@ F6
	N	47, 6, 6		@ C6
	N	52, 6, 6		@ F6
	N	50, 6, 8		@ D#6
	N	48, 6, 8		@ C#6
	N	52, 6, 8		@ F6
	N	47, 6, 6		@ C6
	N	52, 6, 6		@ F6
	N	53, 6, 8		@ F#6
	N	55, 6, 6		@ G#6
	N	53, 6, 6		@ F#6
	N	52, 6, 8		@ F6
	N	47, 6, 6		@ C6
	N	52, 6, 6		@ F6
	N	50, 6, 8		@ D#6
	N	48, 6, 6		@ C#6
	N	50, 6, 6		@ D#6
	N	52, 6, 8		@ F6
	N	56, 6, 6		@ A6
	N	57, 6, 6		@ A#6
	N	59, 6, 8		@ C7
	N	60, 6, 4		@ C#7
	N	59, 6, 4		@ C7
	N	57, 6, 6		@ A#6
	N	56, 6, 8		@ A6
	N	53, 6, 8		@ F#6
	N	52, 6, 10		@ F6
	PAT_END

pat_083D1E6A:				@ used by s1c7
	N	45, 9, 8		@ A#5
	N	45, 9, 8		@ A#5
	N	48, 9, 8		@ C#6
	N	48, 9, 8		@ C#6
	N	45, 9, 8		@ A#5
	N	45, 9, 8		@ A#5
	N	41, 9, 8		@ F#5
	N	41, 9, 8		@ F#5
	N	45, 9, 8		@ A#5
	N	45, 9, 8		@ A#5
	N	48, 9, 8		@ C#6
	N	48, 9, 8		@ C#6
	N	46, 9, 8		@ B5
	N	46, 9, 8		@ B5
	N	45, 9, 8		@ A#5
	N	45, 9, 8		@ A#5
	PAT_END

pat_083D1E9B:				@ used by s1c7
	N	50, 9, 8		@ D#6
	N	50, 9, 8		@ D#6
	N	48, 9, 8		@ C#6
	N	48, 9, 8		@ C#6
	N	46, 9, 8		@ B5
	N	46, 9, 8		@ B5
	N	45, 9, 8		@ A#5
	N	45, 9, 8		@ A#5
	N	50, 9, 8		@ D#6
	N	50, 9, 8		@ D#6
	N	53, 9, 8		@ F#6
	N	53, 9, 8		@ F#6
	N	52, 9, 8		@ F6
	N	52, 9, 8		@ F6
	N	50, 9, 8		@ D#6
	N	50, 9, 8		@ D#6
	PAT_END

pat_083D1ECC:				@ used by s1c7
	N	50, 9, 6		@ D#6
	N	48, 9, 5		@ C#6
	N	50, 9, 8		@ D#6
	REST	0, 2
	N	50, 9, 5		@ D#6
	N	48, 9, 6		@ C#6
	N	50, 9, 8		@ D#6
	REST	0, 2
	N	50, 9, 5		@ D#6
	N	48, 9, 5		@ C#6
	N	45, 9, 7		@ A#5
	N	45, 9, 6		@ A#5
	N	50, 9, 10		@ D#6
	PAT_END

pat_083D1EF4:				@ used by s1c8
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	36, 9, 10		@ C#5
	PAT_END

pat_083D1F0D:				@ used by s1c8
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	33, 9, 10		@ A#4
	N	33, 9, 10		@ A#4
	N	36, 9, 10		@ C#5
	PAT_END

pat_083D1F26:				@ used by s1c8
	N	33, 9, 10		@ A#4
	N	34, 9, 10		@ B4
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	34, 9, 10		@ B4
	N	33, 9, 10		@ A#4
	N	36, 9, 10		@ C#5
	PAT_END

pat_083D1F3F:				@ used by s1c8
	N	33, 9, 10		@ A#4
	N	36, 9, 10		@ C#5
	N	33, 9, 10		@ A#4
	N	29, 9, 10		@ F#4
	N	33, 9, 10		@ A#4
	N	36, 9, 10		@ C#5
	N	34, 9, 10		@ B4
	N	33, 9, 10		@ A#4
	PAT_END

pat_083D1F58:				@ used by s1c8
	N	38, 9, 10		@ D#5
	N	26, 9, 10		@ D#4
	N	38, 9, 10		@ D#5
	N	26, 9, 10		@ D#4
	N	38, 9, 10		@ D#5
	N	26, 9, 10		@ D#4
	N	38, 9, 10		@ D#5
	N	26, 9, 10		@ D#4
	PAT_END

pat_083D1F71:				@ used by s1c8
	N	38, 9, 10		@ D#5
	N	26, 9, 10		@ D#4
	N	38, 9, 10		@ D#5
	N	26, 9, 10		@ D#4
	PAT_END

pat_083D1F7E:				@ used by s1c8
	N	40, 9, 10		@ F5
	N	28, 9, 10		@ F4
	N	40, 9, 10		@ F5
	N	28, 9, 10		@ F4
	N	40, 9, 10		@ F5
	N	28, 9, 10		@ F4
	N	40, 9, 10		@ F5
	N	28, 9, 10		@ F4
	N	40, 9, 10		@ F5
	N	28, 9, 10		@ F4
	N	40, 9, 10		@ F5
	N	28, 9, 10		@ F4
	PAT_END

pat_083D1FA3:				@ used by s1c1, s1c2, s1c4, s1c5, s1c6, s1c7, s1c8, s2c1, s2c2, s2c4, s2c5, s2c6, s2c7, s2c8, s3c1, s3c2, s3c4, s3c5, s3c6, s3c7, s3c8, s4c1, s4c2, s4c3, s4c4, s4c5, s4c6, s4c7, s4c8, s5c1, s5c2, s5c3, s5c4, s5c5, s5c6, s5c7, s5c8, s6c1, s6c2, s6c3, s6c4, s6c5, s6c6, s6c7, s6c8, s7c1, s7c2, s7c3, s7c4, s7c5, s7c6, s7c7, s7c8, s8c1, s8c2, s8c3, s8c4, s8c5, s8c6, s8c7, s8c8, s9c1, s9c2, s9c3, s9c4, s9c5, s9c6, s9c7, s9c8
	N	48, 0, 43		@ C#6
	PAT_END

pat_083D1FA7:				@ used by s1c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	PAT_END

pat_083D2125:				@ used by s1c4
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	44, 3, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	PAT_END

pat_083D21E6:				@ used by s1c4
	N	42, 3, 2		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 0		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 0		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 0		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 0		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 0		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 0		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 0		@ A5
	N	42, 3, 0		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 3, 2		@ A5
	N	46, 5, 2		@ B5
	PAT_END

pat_083D22BC:				@ used by s1c2
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	72, 7, 2		@ C#8
	N	73, 7, 2		@ D8
	N	72, 7, 2		@ C#8
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	72, 7, 2		@ C#8
	N	73, 7, 2		@ D8
	N	72, 7, 2		@ C#8
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	72, 7, 2		@ C#8
	N	73, 7, 2		@ D8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	65, 7, 2		@ F#7
	N	67, 7, 2		@ G#7
	N	68, 7, 2		@ A7
	N	72, 7, 2		@ C#8
	N	68, 7, 2		@ A7
	N	67, 7, 2		@ G#7
	N	65, 7, 2		@ F#7
	N	67, 7, 2		@ G#7
	N	68, 7, 2		@ A7
	N	72, 7, 2		@ C#8
	N	68, 7, 2		@ A7
	N	67, 7, 2		@ G#7
	N	65, 7, 2		@ F#7
	N	67, 7, 2		@ G#7
	N	68, 7, 2		@ A7
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	72, 7, 2		@ C#8
	N	73, 7, 2		@ D8
	N	72, 7, 2		@ C#8
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	72, 7, 2		@ C#8
	N	73, 7, 2		@ D8
	N	72, 7, 2		@ C#8
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	72, 7, 2		@ C#8
	N	73, 7, 2		@ D8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	71, 7, 2		@ C8
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	71, 7, 2		@ C8
	N	72, 7, 2		@ C#8
	N	67, 7, 2		@ G#7
	N	72, 7, 2		@ C#8
	N	74, 7, 2		@ D#8
	N	75, 7, 2		@ E8
	N	74, 7, 2		@ D#8
	N	72, 7, 2		@ C#8
	N	67, 7, 2		@ G#7
	N	72, 7, 2		@ C#8
	N	74, 7, 2		@ D#8
	N	75, 7, 2		@ E8
	N	74, 7, 2		@ D#8
	N	72, 7, 2		@ C#8
	N	67, 7, 2		@ G#7
	N	72, 7, 2		@ C#8
	N	74, 7, 2		@ D#8
	N	75, 7, 2		@ E8
	PAT_END

pat_083D243D:				@ used by s1c2
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	72, 7, 2		@ C#8
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	67, 7, 2		@ G#7
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	72, 7, 2		@ C#8
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	67, 7, 2		@ G#7
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	72, 7, 2		@ C#8
	N	65, 7, 2		@ F#7
	N	68, 7, 2		@ A7
	N	65, 7, 2		@ F#7
	N	67, 7, 2		@ G#7
	N	65, 7, 2		@ F#7
	N	68, 7, 2		@ A7
	N	65, 7, 2		@ F#7
	N	72, 7, 2		@ C#8
	N	65, 7, 2		@ F#7
	N	68, 7, 2		@ A7
	N	65, 7, 2		@ F#7
	N	67, 7, 2		@ G#7
	N	65, 7, 2		@ F#7
	N	68, 7, 2		@ A7
	N	65, 7, 2		@ F#7
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	72, 7, 2		@ C#8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	72, 7, 2		@ C#8
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	67, 7, 2		@ G#7
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	72, 7, 2		@ C#8
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	67, 7, 2		@ G#7
	N	63, 7, 2		@ E7
	N	69, 7, 2		@ A#7
	N	63, 7, 2		@ E7
	N	73, 7, 2		@ D8
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	69, 7, 2		@ A#7
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	73, 7, 2		@ D8
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	69, 7, 2		@ A#7
	N	65, 7, 2		@ F#7
	N	70, 7, 2		@ B7
	N	65, 7, 2		@ F#7
	N	73, 7, 2		@ D8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	73, 7, 2		@ D8
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	N	67, 7, 2		@ G#7
	N	64, 7, 2		@ F7
	N	69, 7, 2		@ A#7
	N	64, 7, 2		@ F7
	PAT_END

pat_083D25BE:				@ used by s1c2
	N	62, 7, 2		@ D#7
	N	65, 7, 2		@ F#7
	N	69, 7, 2		@ A#7
	N	74, 7, 2		@ D#8
	N	77, 7, 2		@ F#8
	N	81, 7, 2		@ A#8
	N	86, 7, 2		@ D#9
	N	89, 7, 2		@ F#9
	N	86, 7, 2		@ D#9
	N	81, 7, 2		@ A#8
	N	77, 7, 2		@ F#8
	N	74, 7, 2		@ D#8
	N	69, 7, 2		@ A#7
	N	65, 7, 2		@ F#7
	N	62, 7, 2		@ D#7
	N	57, 7, 2		@ A#6
	N	62, 7, 2		@ D#7
	N	65, 7, 2		@ F#7
	N	69, 7, 2		@ A#7
	N	74, 7, 2		@ D#8
	N	77, 7, 2		@ F#8
	N	81, 7, 2		@ A#8
	N	86, 7, 2		@ D#9
	N	89, 7, 2		@ F#9
	N	86, 7, 2		@ D#9
	N	81, 7, 2		@ A#8
	N	77, 7, 2		@ F#8
	N	74, 7, 2		@ D#8
	N	69, 7, 2		@ A#7
	N	65, 7, 2		@ F#7
	N	62, 7, 2		@ D#7
	N	57, 7, 2		@ A#6
	PAT_END

pat_083D261F:				@ used by s1c2
	N	62, 7, 2		@ D#7
	N	66, 7, 2		@ G7
	N	69, 7, 2		@ A#7
	N	74, 7, 2		@ D#8
	N	78, 7, 2		@ G8
	N	81, 7, 2		@ A#8
	N	86, 7, 2		@ D#9
	N	90, 7, 2		@ G9
	N	86, 7, 2		@ D#9
	N	81, 7, 2		@ A#8
	N	78, 7, 2		@ G8
	N	74, 7, 2		@ D#8
	N	69, 7, 2		@ A#7
	N	66, 7, 2		@ G7
	N	62, 7, 2		@ D#7
	N	57, 7, 2		@ A#6
	N	62, 7, 2		@ D#7
	N	66, 7, 2		@ G7
	N	69, 7, 2		@ A#7
	N	74, 7, 2		@ D#8
	N	78, 7, 2		@ G8
	N	81, 7, 2		@ A#8
	N	86, 7, 2		@ D#9
	N	90, 7, 2		@ G9
	N	86, 7, 2		@ D#9
	N	81, 7, 2		@ A#8
	N	78, 7, 2		@ G8
	N	74, 7, 2		@ D#8
	N	69, 7, 2		@ A#7
	N	66, 7, 2		@ G7
	N	62, 7, 2		@ D#7
	N	57, 7, 2		@ A#6
	PAT_END

pat_083D2680:				@ used by s1c1
	N	33, 27, 10		@ A#4
	N	41, 25, 10		@ F#5
	N	33, 27, 10		@ A#4
	N	41, 25, 10		@ F#5
	N	33, 27, 10		@ A#4
	N	41, 25, 10		@ F#5
	N	33, 27, 10		@ A#4
	N	36, 26, 10		@ C#5
	PAT_END

pat_083D2699:				@ used by s1c1
	N	45, 19, 7		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	41, 26, 10		@ F#5
	N	45, 19, 7		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	41, 25, 10		@ F#5
	N	45, 19, 7		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 25, 10		@ A#5
	N	45, 19, 7		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	36, 27, 10		@ C#5
	PAT_END

pat_083D26D6:				@ used by s1c1
	N	33, 27, 10		@ A#4
	N	34, 27, 10		@ B4
	N	33, 27, 10		@ A#4
	N	41, 25, 10		@ F#5
	N	33, 27, 10		@ A#4
	N	34, 27, 10		@ B4
	N	33, 27, 10		@ A#4
	N	36, 26, 10		@ C#5
	PAT_END

pat_083D26EF:				@ used by s1c1
	N	33, 21, 6		@ A#4
	N	33, 21, 4		@ A#4
	N	33, 21, 6		@ A#4
	N	33, 21, 6		@ A#4
	N	33, 21, 4		@ A#4
	N	36, 26, 8		@ C#5
	N	36, 26, 8		@ C#5
	N	33, 21, 6		@ A#4
	N	33, 21, 4		@ A#4
	N	33, 21, 6		@ A#4
	N	33, 21, 6		@ A#4
	N	33, 21, 4		@ A#4
	N	41, 25, 8		@ F#5
	N	41, 25, 8		@ F#5
	N	33, 21, 6		@ A#4
	N	33, 21, 4		@ A#4
	N	33, 21, 6		@ A#4
	N	33, 21, 6		@ A#4
	N	33, 21, 4		@ A#4
	N	36, 26, 8		@ C#5
	N	36, 26, 8		@ C#5
	N	34, 21, 6		@ B4
	N	34, 21, 4		@ B4
	N	34, 21, 6		@ B4
	N	34, 21, 6		@ B4
	N	34, 21, 4		@ B4
	N	33, 24, 8		@ A#4
	N	33, 24, 8		@ A#4
	PAT_END

pat_083D2744:				@ used by s1c1
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 2		@ D#5
	N	38, 19, 6		@ D#5
	REST	0, 2
	REST	0, 6
	N	36, 16, 4		@ C#5
	N	36, 16, 4		@ C#5
	N	36, 16, 4		@ C#5
	N	36, 16, 2		@ C#5
	N	36, 16, 6		@ C#5
	REST	0, 2
	REST	0, 6
	N	34, 16, 4		@ B4
	N	34, 16, 4		@ B4
	N	34, 16, 4		@ B4
	N	34, 16, 2		@ B4
	N	34, 16, 6		@ B4
	REST	0, 2
	REST	0, 6
	N	26, 21, 4		@ D#4
	N	26, 21, 4		@ D#4
	N	26, 21, 4		@ D#4
	N	26, 21, 2		@ D#4
	N	26, 21, 6		@ D#4
	REST	0, 2
	REST	0, 6
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 2		@ D#5
	N	38, 19, 6		@ D#5
	REST	0, 2
	REST	0, 6
	N	34, 18, 4		@ B4
	N	34, 18, 4		@ B4
	N	34, 18, 4		@ B4
	N	34, 18, 2		@ B4
	N	34, 18, 6		@ B4
	REST	0, 2
	REST	0, 6
	N	36, 17, 4		@ C#5
	N	36, 17, 4		@ C#5
	N	36, 17, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 6		@ C#5
	REST	0, 2
	REST	0, 6
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 4		@ D#5
	N	38, 19, 2		@ D#5
	N	38, 19, 6		@ D#5
	REST	0, 2
	REST	0, 6
	N	38, 19, 6		@ D#5
	N	36, 16, 5		@ C#5
	N	38, 19, 4		@ D#5
	REST	0, 2
	REST	0, 7
	N	38, 19, 5		@ D#5
	N	36, 16, 6		@ C#5
	N	38, 19, 4		@ D#5
	REST	0, 2
	REST	0, 7
	N	38, 19, 5		@ D#5
	N	36, 16, 5		@ C#5
	N	26, 21, 7		@ D#4
	N	33, 19, 6		@ A#4
	N	26, 26, 10		@ D#4
	PAT_END

pat_083D281A:				@ used by s1c1
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 2		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 24		@ F4
	N	28, 20, 4		@ F4
	N	29, 17, 4		@ F#4
	N	29, 17, 4		@ F#4
	N	29, 17, 4		@ F#4
	N	29, 17, 2		@ F#4
	N	29, 17, 4		@ F#4
	N	29, 17, 24		@ F#4
	N	29, 17, 4		@ F#4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 2		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 24		@ F4
	N	28, 20, 4		@ F4
	N	26, 20, 4		@ D#4
	N	26, 20, 4		@ D#4
	N	26, 20, 4		@ D#4
	N	26, 20, 2		@ D#4
	N	26, 20, 4		@ D#4
	N	26, 20, 24		@ D#4
	N	26, 20, 4		@ D#4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 2		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 24		@ F4
	N	28, 20, 4		@ F4
	N	29, 17, 4		@ F#4
	N	29, 17, 4		@ F#4
	N	29, 17, 4		@ F#4
	N	29, 17, 2		@ F#4
	N	29, 17, 4		@ F#4
	N	29, 17, 24		@ F#4
	N	29, 17, 4		@ F#4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 2		@ F4
	N	28, 20, 4		@ F4
	N	28, 20, 24		@ F4
	N	28, 20, 4		@ F4
	N	26, 20, 4		@ D#4
	N	26, 20, 4		@ D#4
	N	26, 20, 4		@ D#4
	N	26, 20, 2		@ D#4
	N	26, 20, 4		@ D#4
	N	26, 20, 24		@ D#4
	N	26, 20, 4		@ D#4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 2		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 24		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 2		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 24		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 2		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 24		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 2		@ F4
	N	28, 16, 4		@ F4
	N	28, 16, 23		@ F4
	PAT_END

seq_s00_c0:				@ 083D2914
	SEQ_PAN 0xFF
	SEQ_TEMPO 255
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_CONDFLAG 1
	SEQ_END

seq_s00_c1:				@ 083D2940
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s00_c2:				@ 083D2954
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s00_c3:				@ 083D2968
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s00_c4:				@ 083D297C
	SEQ_PAT	pat_083CC4B8, 0, 1
	SEQ_END

seq_s01_c0:				@ 083D2990
	SEQ_PAN 0xFF
	SEQ_TEMPO 248
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083D2680, -12, 1
	SEQ_PAT	pat_083D2699, -12, 1
	SEQ_PAT	pat_083D26D6, -12, 3
	SEQ_PAT	pat_083D26EF, -12, 2
	SEQ_PAT	pat_083CC4B0, 0, 8
	SEQ_PAT	pat_083D2744, 0, 1
	SEQ_PAT	pat_083D281A, 0, 1
	SEQ_PAT	pat_083D26D6, -12, 3
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s01_c1:				@ 083D2A40
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 16
	SEQ_PAT	pat_083D22BC, -36, 3
	SEQ_PAT	pat_083D243D, -36, 2
	SEQ_PAT	pat_083D25BE, -36, 10
	SEQ_PAT	pat_083D25BE, -34, 4
	SEQ_PAT	pat_083D261F, -34, 2
	SEQ_PAT	pat_083D22BC, -36, 3
	SEQ_JUMP 0

seq_s01_c2:				@ 083D2AC8
	SEQ_PAT	pat_083CC4B0, 0, 128
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_END
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s01_c3:				@ 083D2B04
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083D1FA7, 0, 5
	SEQ_PAT	pat_083D2125, 0, 2
	SEQ_PAT	pat_083CC4B0, 0, 4
	SEQ_PAT	pat_083D21E6, 0, 13
	SEQ_JUMP 0

seq_s01_c4:				@ 083D2B5C
	SEQ_PAT	pat_083D1835, 1, 1
	SEQ_PAT	pat_083D1896, 1, 1
	SEQ_PAT	pat_083D18F4, 1, 3
	SEQ_PAT	pat_083D194C, 1, 2
	SEQ_PAT	pat_083D19A7, 1, 5
	SEQ_PAT	pat_083D19A7, 3, 3
	SEQ_PAT	pat_083D18F4, 1, 3
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s01_c5:				@ 083D2BE4
	SEQ_PAT	pat_083CC4B8, 0, 8
	SEQ_PAT	pat_083D1A08, 0, 1
	SEQ_PAT	pat_083D1A6F, 0, 3
	SEQ_PAT	pat_083D1B3C, 0, 1
	SEQ_PAT	pat_083D1A6F, 0, 1
	SEQ_PAT	pat_083D1BAF, 0, 1
	SEQ_PAT	pat_083D1C4C, 0, 1
	SEQ_PAT	pat_083D1BAF, 0, 1
	SEQ_PAT	pat_083D1C4C, 0, 1
	SEQ_PAT	pat_083D1BAF, 0, 2
	SEQ_PAT	pat_083D1C4C, 0, 2
	SEQ_PAT	pat_083D1BAF, 0, 1
	SEQ_PAT	pat_083D1C4C, 0, 1
	SEQ_PAT	pat_083D1BAF, 0, 1
	SEQ_PAT	pat_083D1C4C, 0, 1
	SEQ_PAT	pat_083D1A6F, 0, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s01_c6:				@ 083D2CFC
	SEQ_PAT	pat_083CC4B8, 0, 24
	SEQ_PAT	pat_083D1CF5, 13, 1
	SEQ_PAT	pat_083D1D4D, 1, 1
	SEQ_PAT	pat_083D1E6A, 13, 1
	SEQ_PAT	pat_083D1D96, 1, 1
	SEQ_PAT	pat_083CC4B8, 0, 8
	SEQ_PAT	pat_083D1E9B, 13, 1
	SEQ_PAT	pat_083D1ECC, 13, 1
	SEQ_PAT	pat_083D1E06, 1, 1
	SEQ_PAT	pat_083CC4B8, 0, 8
	SEQ_PAT	pat_083D1CF5, 13, 1
	SEQ_PAT	pat_083D1D4D, 1, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s01_c7:				@ 083D2DD4
	SEQ_PAT	pat_083D1EF4, 13, 1
	SEQ_PAT	pat_083D1F0D, 13, 1
	SEQ_PAT	pat_083D1F26, 13, 3
	SEQ_PAT	pat_083D1F3F, 13, 2
	SEQ_PAT	pat_083D1F58, 13, 2
	SEQ_PAT	pat_083D1F71, 13, 1
	SEQ_PAT	pat_083D1F7E, 13, 1
	SEQ_PAT	pat_083D1F26, 13, 3
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s02_c0:				@ 083D2E6C
	SEQ_PAN 0xFF
	SEQ_TEMPO 188
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083D110C, -23, 4
	SEQ_PAT	pat_083D1149, -11, 1
	SEQ_PAT	pat_083D1149, -16, 1
	SEQ_PAT	pat_083D1162, -11, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s02_c1:				@ 083D2EDC
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083D117B, -35, 4
	SEQ_PAT	pat_083D12A8, -35, 1
	SEQ_PAT	pat_083D12A8, -40, 1
	SEQ_PAT	pat_083D13D5, -35, 1
	SEQ_JUMP 0

seq_s02_c2:				@ 083D2F34
	SEQ_PAT	pat_083CC4B0, 0, 128
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_END
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s02_c3:				@ 083D2F70
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083D1502, 0, 1
	SEQ_PAT	pat_083D15C3, 0, 3
	SEQ_PAT	pat_083D1744, 0, 3
	SEQ_JUMP 0

seq_s02_c4:				@ 083D2FB8
	SEQ_PAT	pat_083D0468, 2, 1
	SEQ_PAT	pat_083D0499, 2, 1
	SEQ_PAT	pat_083D0563, 2, 2
	SEQ_PAT	pat_083D0648, 2, 1
	SEQ_PAT	pat_083D0648, -3, 1
	SEQ_PAT	pat_083D06D0, 2, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s02_c5:				@ 083D3030
	SEQ_PAT	pat_083D074C, 0, 1
	SEQ_PAT	pat_083D07B6, 0, 3
	SEQ_PAT	pat_083D0892, 0, 3
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s02_c6:				@ 083D3078
	SEQ_PAT	pat_083CC4B8, 0, 8
	SEQ_PAT	pat_083D0980, 14, 3
	SEQ_PAT	pat_083D0AAD, 14, 1
	SEQ_PAT	pat_083D0B86, 14, 1
	SEQ_PAT	pat_083D0C5F, 14, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s02_c7:				@ 083D30E0
	SEQ_PAT	pat_083CC4B8, 0, 16
	SEQ_PAT	pat_083D0D38, -10, 1
	SEQ_PAT	pat_083D0E41, -10, 1
	SEQ_PAT	pat_083D0F47, -10, 1
	SEQ_PAT	pat_083D0FA2, -10, 1
	SEQ_PAT	pat_083D10B1, -10, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s03_c0:				@ 083D3158
	SEQ_PAN 0xFF
	SEQ_TEMPO 192
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 4
	SEQ_PAT	pat_083D0029, -32, 2
	SEQ_PAT	pat_083D00E4, -32, 1
	SEQ_PAT	pat_083D0029, -32, 2
	SEQ_PAT	pat_083D00E4, -32, 1
	SEQ_PAT	pat_083D0169, -32, 1
	SEQ_PAT	pat_083D0029, -32, 2
	SEQ_PAT	pat_083D00E4, -32, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s03_c1:				@ 083D3208
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 4
	SEQ_PAT	pat_083D0188, -32, 2
	SEQ_PAT	pat_083D0243, -32, 1
	SEQ_PAT	pat_083D0188, -32, 2
	SEQ_PAT	pat_083D0243, -32, 1
	SEQ_PAT	pat_083D02C8, -32, 1
	SEQ_PAT	pat_083D0188, -32, 2
	SEQ_PAT	pat_083D0243, -32, 1
	SEQ_JUMP 0

seq_s03_c2:				@ 083D32A0
	SEQ_PAT	pat_083CC4B0, 0, 128
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_END
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s03_c3:				@ 083D32DC
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 4
	SEQ_PAT	pat_083D02E7, 0, 6
	SEQ_PAT	pat_083CC4B0, 0, 4
	SEQ_PAT	pat_083D02E7, 0, 4
	SEQ_JUMP 0

seq_s03_c4:				@ 083D3334
	SEQ_PAT	pat_083CF194, 0, 1
	SEQ_PAT	pat_083CC4B8, 0, 2
	SEQ_PAT	pat_083CF198, 5, 1
	SEQ_PAT	pat_083CF271, 5, 1
	SEQ_PAT	pat_083CF34A, 5, 1
	SEQ_PAT	pat_083CF198, 5, 1
	SEQ_PAT	pat_083CF271, 5, 1
	SEQ_PAT	pat_083CF34A, 5, 1
	SEQ_PAT	pat_083CF447, 5, 1
	SEQ_PAT	pat_083CF198, 5, 1
	SEQ_PAT	pat_083CF271, 5, 1
	SEQ_PAT	pat_083CF34A, 5, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s03_c5:				@ 083D340C
	SEQ_PAT	pat_083CF532, -7, 1
	SEQ_PAT	pat_083CF551, -7, 1
	SEQ_PAT	pat_083CF573, -7, 1
	SEQ_PAT	pat_083CF661, -7, 1
	SEQ_PAT	pat_083CF6F8, -7, 1
	SEQ_PAT	pat_083CF7C5, -7, 1
	SEQ_PAT	pat_083CF8EF, -7, 1
	SEQ_PAT	pat_083CFA4C, -7, 1
	SEQ_PAT	pat_083CF551, -7, 1
	SEQ_PAT	pat_083CFA98, -7, 1
	SEQ_PAT	pat_083CFB71, -7, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s03_c6:				@ 083D34D4
	SEQ_PAT	pat_083CFBFC, 5, 2
	SEQ_PAT	pat_083CFCBD, 5, 1
	SEQ_PAT	pat_083CFBFC, 5, 1
	SEQ_PAT	pat_083CFCBD, 5, 1
	SEQ_PAT	pat_083CFD7E, 5, 1
	SEQ_PAT	pat_083CFBFC, 5, 1
	SEQ_PAT	pat_083CFCBD, 5, 1
	SEQ_PAT	pat_083CFBFC, 5, 1
	SEQ_PAT	pat_083CFCBD, 5, 1
	SEQ_PAT	pat_083CFD7E, 5, 1
	SEQ_PAT	pat_083CFEFF, 5, 1
	SEQ_PAT	pat_083CFEFF, 1, 1
	SEQ_PAT	pat_083CFEFF, 0, 1
	SEQ_PAT	pat_083CFBFC, 5, 1
	SEQ_PAT	pat_083CFCBD, 5, 1
	SEQ_PAT	pat_083CFBFC, 5, 1
	SEQ_PAT	pat_083CFCBD, 5, 1
	SEQ_PAT	pat_083CFD7E, 5, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s03_c7:				@ 083D360C
	SEQ_PAT	pat_083CFFC0, 0, 1
	SEQ_PAT	pat_083D0025, 0, 12
	SEQ_PAT	pat_083CFFE8, 0, 3
	SEQ_PAT	pat_083D0025, 0, 6
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s04_c0:				@ 083D3664
	SEQ_PAN 0xFF
	SEQ_TEMPO 220
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CEFD2, -32, 3
	SEQ_PAT	pat_083CEFD2, -27, 2
	SEQ_PAT	pat_083CEFD2, -34, 2
	SEQ_PAT	pat_083CEFD2, -29, 2
	SEQ_PAT	pat_083CEFD2, -36, 1
	SEQ_PAT	pat_083CEFD2, -33, 1
	SEQ_PAT	pat_083CF04B, -32, 8
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s04_c1:				@ 083D3704
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s04_c2:				@ 083D3738
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s04_c3:				@ 083D376C
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CF0D0, 0, 19
	SEQ_JUMP 0

seq_s04_c4:				@ 083D3794
	SEQ_PAT	pat_083CC4B8, 0, 4
	SEQ_PAT	pat_083CE506, -7, 1
	SEQ_PAT	pat_083CE52B, -7, 1
	SEQ_PAT	pat_083CE583, -7, 1
	SEQ_PAT	pat_083CE611, -7, 1
	SEQ_PAT	pat_083CE64E, -7, 1
	SEQ_PAT	pat_083CE69D, -7, 1
	SEQ_PAT	pat_083CE82A, -7, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s04_c5:				@ 083D382C
	SEQ_PAT	pat_083CE9F0, 5, 3
	SEQ_PAT	pat_083CE9F0, -2, 2
	SEQ_PAT	pat_083CE9F0, 3, 2
	SEQ_PAT	pat_083CE9F0, -4, 2
	SEQ_PAT	pat_083CE9F0, 1, 1
	SEQ_PAT	pat_083CE9F0, 4, 1
	SEQ_PAT	pat_083CEAB1, 5, 8
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s04_c6:				@ 083D38B4
	SEQ_PAT	pat_083CEB72, 5, 1
	SEQ_PAT	pat_083CEBD3, 5, 1
	SEQ_PAT	pat_083CEC91, 5, 1
	SEQ_PAT	pat_083CEBD3, 3, 1
	SEQ_PAT	pat_083CEC91, 3, 1
	SEQ_PAT	pat_083CED73, 5, 1
	SEQ_PAT	pat_083CEE28, 5, 1
	SEQ_PAT	pat_083CEE28, 5, 1
	SEQ_PAT	pat_083CEE28, 5, 1
	SEQ_PAT	pat_083CEEEC, 5, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s04_c7:				@ 083D396C
	SEQ_PAT	pat_083CEFC5, 0, 19
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s05_c0:				@ 083D3994
	SEQ_PAN 0xFF
	SEQ_TEMPO 215
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CE0C3, 2, 4
	SEQ_PAT	pat_083CE0C3, 7, 1
	SEQ_PAT	pat_083CE0EE, 2, 1
	SEQ_CONDFLAG 1
	SEQ_END

seq_s05_c1:				@ 083D39F0
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s05_c2:				@ 083D3A24
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 20
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s05_c3:				@ 083D3A58
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CE107, 0, 3
	SEQ_END

seq_s05_c4:				@ 083D3A7C
	SEQ_PAT	pat_083CE1C5, -9, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s05_c5:				@ 083D3AA0
	SEQ_PAT	pat_083CE31F, 3, 4
	SEQ_PAT	pat_083CE380, 3, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s05_c6:				@ 083D3AD4
	SEQ_PAT	pat_083CE414, 3, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s05_c7:				@ 083D3AF8
	SEQ_PAT	pat_083CE502, 0, 3
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s06_c0:				@ 083D3B1C
	SEQ_PAN 0xFF
	SEQ_TEMPO 215
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CDF56, -12, 1
	SEQ_CONDFLAG 1
	SEQ_END

seq_s06_c1:				@ 083D3B58
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s06_c2:				@ 083D3B8C
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s06_c3:				@ 083D3BC0
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CDFE4, 0, 1
	SEQ_END

seq_s06_c4:				@ 083D3BE4
	SEQ_PAT	pat_083CDE47, 1, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s06_c5:				@ 083D3C08
	SEQ_PAT	pat_083CDE99, 1, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s06_c6:				@ 083D3C2C
	SEQ_PAT	pat_083CDEEB, 1, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s06_c7:				@ 083D3C50
	SEQ_PAT	pat_083CDF4F, 0, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s07_c0:				@ 083D3C74
	SEQ_PAN 0xFF
	SEQ_TEMPO 215
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CDC45, -24, 1
	SEQ_CONDFLAG 1
	SEQ_END

seq_s07_c1:				@ 083D3CB0
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s07_c2:				@ 083D3CE4
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s07_c3:				@ 083D3D18
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CDDCA, 0, 3
	SEQ_PAT	pat_083CDDFB, 0, 1
	SEQ_END

seq_s07_c4:				@ 083D3D4C
	SEQ_PAT	pat_083CDCD2, -11, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s07_c5:				@ 083D3D70
	SEQ_PAT	pat_083CDD66, 1, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s07_c6:				@ 083D3D94
	SEQ_PAT	pat_083CDC68, 1, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s07_c7:				@ 083D3DB8
	SEQ_PAT	pat_083CDC61, 0, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_END

seq_s08_c0:				@ 083D3DDC
	SEQ_PAN 0xFF
	SEQ_TEMPO 207
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CCDAF, 4, 3
	SEQ_PAT	pat_083CCDAF, 9, 2
	SEQ_PAT	pat_083CCDB6, 4, 2
	SEQ_PAT	pat_083CCDAF, 4, 2
	SEQ_PAT	pat_083CCDCF, 4, 1
	SEQ_PAT	pat_083CCDE8, 4, 1
	SEQ_PAT	pat_083CCE19, 4, 2
	SEQ_PAT	pat_083CCE26, 4, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s08_c1:				@ 083D3E8C
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CD2CC, 0, 1
	SEQ_PAT	pat_083CD2D0, -20, 3
	SEQ_PAT	pat_083CD2D0, -15, 2
	SEQ_PAT	pat_083CD391, -20, 2
	SEQ_PAT	pat_083CD2D0, -20, 2
	SEQ_PAT	pat_083CD452, -20, 2
	SEQ_PAT	pat_083CD452, -24, 2
	SEQ_PAT	pat_083CD452, -20, 2
	SEQ_PAT	pat_083CD452, -17, 2
	SEQ_PAT	pat_083CD483, -20, 1
	SEQ_PAT	pat_083CD544, -20, 4
	SEQ_PAT	pat_083CD452, -23, 8
	SEQ_PAT	pat_083CD575, -20, 1
	SEQ_PAT	pat_083CD5A6, -20, 1
	SEQ_PAT	pat_083CD575, -20, 1
	SEQ_PAT	pat_083CD5D7, -20, 1
	SEQ_PAT	pat_083CD5A6, -20, 1
	SEQ_PAT	pat_083CD575, -20, 1
	SEQ_PAT	pat_083CD5A6, -20, 1
	SEQ_PAT	pat_083CD608, -20, 1
	SEQ_JUMP 0

seq_s08_c2:				@ 083D3FE4
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s08_c3:				@ 083D4018
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CF0D0, 0, 17
	SEQ_JUMP 0

seq_s08_c4:				@ 083D4040
	SEQ_PAT	pat_083CC4B8, 0, 4
	SEQ_PAT	pat_083CCE42, 5, 1
	SEQ_PAT	pat_083CCEA0, -7, 1
	SEQ_PAT	pat_083CCF2B, 5, 1
	SEQ_PAT	pat_083CCE42, 5, 1
	SEQ_PAT	pat_083CCFDA, 5, 1
	SEQ_PAT	pat_083CD017, 5, 1
	SEQ_PAT	pat_083CD0CF, -7, 1
	SEQ_PAT	pat_083CD1EA, -7, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s08_c5:				@ 083D40E8
	SEQ_PAT	pat_083CD2D0, -31, 3
	SEQ_PAT	pat_083CD2D0, -26, 2
	SEQ_PAT	pat_083CD391, -31, 2
	SEQ_PAT	pat_083CD2D0, -31, 2
	SEQ_PAT	pat_083CD452, -31, 2
	SEQ_PAT	pat_083CD452, -35, 2
	SEQ_PAT	pat_083CD452, -31, 2
	SEQ_PAT	pat_083CD452, -28, 2
	SEQ_PAT	pat_083CD483, -31, 1
	SEQ_PAT	pat_083CD544, -31, 4
	SEQ_PAT	pat_083CD452, -34, 8
	SEQ_PAT	pat_083CD575, -31, 1
	SEQ_PAT	pat_083CD5A6, -31, 1
	SEQ_PAT	pat_083CD575, -31, 1
	SEQ_PAT	pat_083CD5D7, -31, 1
	SEQ_PAT	pat_083CD5A6, -31, 1
	SEQ_PAT	pat_083CD575, -31, 1
	SEQ_PAT	pat_083CD5A6, -31, 1
	SEQ_PAT	pat_083CD608, -31, 1
	SEQ_PAT	pat_083CD2CC, 0, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s08_c6:				@ 083D4240
	SEQ_PAT	pat_083CD639, 5, 1
	SEQ_PAT	pat_083CD68E, 5, 1
	SEQ_PAT	pat_083CD74F, 5, 1
	SEQ_PAT	pat_083CD816, 5, 1
	SEQ_PAT	pat_083CD68E, 5, 1
	SEQ_PAT	pat_083CD8C8, 5, 1
	SEQ_PAT	pat_083CD983, 5, 1
	SEQ_PAT	pat_083CDA4D, 5, 1
	SEQ_PAT	pat_083CDB2F, 5, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s08_c7:				@ 083D42E8
	SEQ_PAT	pat_083CDBDE, 0, 2
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s09_c0:				@ 083D4310
	SEQ_PAN 0xFF
	SEQ_TEMPO 194
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4BC, -10, 4
	SEQ_PAT	pat_083CC4E7, -10, 2
	SEQ_PAT	pat_083CC4BC, -10, 2
	SEQ_PAT	pat_083CC4E7, -8, 1
	SEQ_PAT	pat_083CC4E7, -10, 1
	SEQ_PAT	pat_083CC4BC, -10, 1
	SEQ_PAT	pat_083CC4E7, -8, 1
	SEQ_PAT	pat_083CC4BC, -10, 2
	SEQ_PAT	pat_083CC4E7, -10, 1
	SEQ_PAT	pat_083CC4BC, -10, 1
	SEQ_PAT	pat_083CC4E7, -8, 1
	SEQ_PAT	pat_083CC4E7, -10, 1
	SEQ_PAT	pat_083CC4BC, -10, 1
	SEQ_PAT	pat_083CC4E7, -8, 1
	SEQ_PAT	pat_083CC4BC, -10, 1
	SEQ_PAT	pat_083CC518, -10, 2
	SEQ_PAT	pat_083CC4BC, -10, 1
	SEQ_PAT	pat_083CC4E7, -7, 1
	SEQ_PAT	pat_083CC4BC, -10, 1
	SEQ_PAT	pat_083CC4E7, -7, 1
	SEQ_PAT	pat_083CC4BC, -5, 1
	SEQ_PAT	pat_083CC4E7, -14, 1
	SEQ_PAT	pat_083CC4BC, -5, 2
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s09_c1:				@ 083D44B0
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s09_c2:				@ 083D44E4
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC4B0, 0, 5
	SEQ_PAT	pat_083CC4B4, 0, 1
	SEQ_END

seq_s09_c3:				@ 083D4518
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_PAT	pat_083CC555, 0, 33
	SEQ_JUMP 0

seq_s09_c4:				@ 083D4540
	SEQ_PAT	pat_083CC4B8, 0, 4
	SEQ_PAT	pat_083CC5B6, -9, 1
	SEQ_PAT	pat_083CC75B, -9, 1
	SEQ_PAT	pat_083CC8D6, -9, 2
	SEQ_PAT	pat_083CC944, -9, 1
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s09_c5:				@ 083D45A8
	SEQ_PAT	pat_083CCA3E, 3, 2
	SEQ_PAT	pat_083CCA8D, 3, 1
	SEQ_PAT	pat_083CCADC, 3, 1
	SEQ_PAT	pat_083CCA3E, 8, 1
	SEQ_PAT	pat_083CCB2B, 8, 1
	SEQ_PAT	pat_083CCA3E, 3, 1
	SEQ_PAT	pat_083CCB7A, 3, 1
	SEQ_PAT	pat_083CCA3E, 10, 1
	SEQ_PAT	pat_083CCB2B, 8, 1
	SEQ_PAT	pat_083CCB7A, 3, 1
	SEQ_PAT	pat_083CCA3E, 10, 1
	SEQ_PAT	pat_083CCA3E, 3, 1
	SEQ_PAT	pat_083CCADC, 3, 1
	SEQ_PAT	pat_083CCA3E, 8, 1
	SEQ_PAT	pat_083CCB7A, 3, 1
	SEQ_PAT	pat_083CCA3E, 10, 1
	SEQ_PAT	pat_083CCA8D, 8, 1
	SEQ_PAT	pat_083CCB7A, 3, 1
	SEQ_PAT	pat_083CCA3E, 10, 1
	SEQ_PAT	pat_083CCA8D, 3, 1
	SEQ_PAT	pat_083CCBC9, 3, 2
	SEQ_PAT	pat_083CCC66, 3, 1
	SEQ_PAT	pat_083CCCB5, 3, 1
	SEQ_PAT	pat_083CCC66, 3, 1
	SEQ_PAT	pat_083CCCB5, 3, 1
	SEQ_PAT	pat_083CCC66, 8, 1
	SEQ_PAT	pat_083CCCB5, 8, 1
	SEQ_PAT	pat_083CCC66, 8, 2
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s09_c6:				@ 083D4780
	SEQ_PAT	pat_083CCD04, 0, 10
	SEQ_PAT	pat_083CCD74, 0, 1
	SEQ_PAT	pat_083CC90D, -9, 2
	SEQ_PAT	pat_083CCD04, 0, 4
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

seq_s09_c7:				@ 083D47D8
	SEQ_PAT	pat_083CCDA8, 0, 33
	SEQ_PAT	pat_083D1FA3, 0, 1
	SEQ_JUMP 0

	.global mcFreqLo
mcFreqLo:				@ 083D4800  PSG frequency register low byte, 97 notes
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
mcFreqHi:				@ 083D4861  PSG frequency register high byte, 97 notes
	.byte	0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04	@ 0..
	.byte	0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06	@ 12..
	.byte	0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x07	@ 24..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 36..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 48..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 60..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 72..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 84..
	.byte	0x00	@ 96..
@ 083D48C2-083D48C4: 2 bytes, padding
	.byte	0x00, 0x00

@ mcSongTable: {seq ch1..ch8, note-length table}; ch1-4 PSG, ch5-8 mixed PCM
	.global mcSongTable
mcSongTable:				@ 083D48C4
	.word	seq_s00_c0, seq_s00_c1, seq_s00_c2, seq_s00_c3, seq_s00_c4, seq_s00_c4, seq_s00_c4, seq_s00_c4, durTable0	@ song 0
	.word	seq_s01_c0, seq_s01_c1, seq_s01_c2, seq_s01_c3, seq_s01_c4, seq_s01_c5, seq_s01_c6, seq_s01_c7, durTable0	@ song 1
	.word	seq_s02_c0, seq_s02_c1, seq_s02_c2, seq_s02_c3, seq_s02_c4, seq_s02_c5, seq_s02_c6, seq_s02_c7, durTable0	@ song 2
	.word	seq_s03_c0, seq_s03_c1, seq_s03_c2, seq_s03_c3, seq_s03_c4, seq_s03_c5, seq_s03_c6, seq_s03_c7, durTable0	@ song 3
	.word	seq_s04_c0, seq_s04_c1, seq_s04_c2, seq_s04_c3, seq_s04_c4, seq_s04_c5, seq_s04_c6, seq_s04_c7, durTable0	@ song 4
	.word	seq_s05_c0, seq_s05_c1, seq_s05_c2, seq_s05_c3, seq_s05_c4, seq_s05_c5, seq_s05_c6, seq_s05_c7, durTable0	@ song 5
	.word	seq_s06_c0, seq_s06_c1, seq_s06_c2, seq_s06_c3, seq_s06_c4, seq_s06_c5, seq_s06_c6, seq_s06_c7, durTable0	@ song 6
	.word	seq_s07_c0, seq_s07_c1, seq_s07_c2, seq_s07_c3, seq_s07_c4, seq_s07_c5, seq_s07_c6, seq_s07_c7, durTable0	@ song 7
	.word	seq_s08_c0, seq_s08_c1, seq_s08_c2, seq_s08_c3, seq_s08_c4, seq_s08_c5, seq_s08_c6, seq_s08_c7, durTable0	@ song 8
	.word	seq_s09_c0, seq_s09_c1, seq_s09_c2, seq_s09_c3, seq_s09_c4, seq_s09_c5, seq_s09_c6, seq_s09_c7, durTable0	@ song 9

mod_083D4A2C:				@ env of inst 1
	.hword	240, 2, 0, 1, 112, 1, 0, 1
	.hword	255, 0

mod_083D4A40:				@ env of inst 2
	.hword	240, 1, 176, 1, 112, 2, 48, 1
	.hword	32, 5, 16, 15, 0, 1, 255, 0
	.hword	64, 1, 48, 1, 32, 1, 16, 1
	.hword	0, 1, 255, 0

mod_083D4A78:				@ env of inst 5
	.hword	16, 3, 0, 1, 255, 0, 0, 0

mod_083D4A88:				@ env of inst 6
	.hword	144, 1, 64, 1, 48, 2, 32, 3
	.hword	16, 6, 0, 1, 255, 0, 16, 1
	.hword	48, 1, 80, 1, 128, 5, 112, 10
	.hword	96, 100, 80, 100, 64, 100, 48, 100
	.hword	32, 100, 16, 100, 0, 1, 255, 0

mod_083D4AD8:				@ env of inst 8
	.hword	32, 1, 128, 2, 64, 4, 96, 9
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4AF8:				@ env of inst 11; env of inst 12; env of inst 13; env of inst 14; env of inst 15
	.hword	32, 1, 128, 1, 64, 4, 96, 12
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4B18:				@ env of inst 10
	.hword	96, 1, 80, 1, 64, 1, 48, 6
	.hword	32, 200, 16, 200, 0, 1, 255, 0

mod_083D4B38:				@ env of inst 22; env of inst 23; env of inst 24; env of inst 25; env of inst 26; env of inst 27
	.hword	32, 1, 48, 3, 32, 25, 16, 175
	.hword	16, 175, 0, 1, 255, 0, 0, 0

mod_083D4B58:				@ env of inst 28
	.hword	64, 1, 48, 1, 32, 1, 16, 5
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4B78:				@ env of inst 29
	.hword	48, 1, 32, 1, 16, 1, 16, 5
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4B98:				@ env of inst 30
	.hword	64, 1, 32, 1, 16, 1, 16, 5
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4BB8:				@ env of inst 31
	.hword	32, 1, 16, 1, 16, 1, 16, 5
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4BD8:				@ env of inst 32
	.hword	32, 1, 32, 1, 32, 1, 16, 5
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4BF8:				@ env of inst 33
	.hword	16, 1, 16, 1, 16, 1, 16, 5
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_083D4C18:				@ pitch of inst 1
	.hword	97, 200, 255, 0, 0, 0, 0, 0

mod_083D4C28:				@ pitch of inst 2
	.hword	55, 2, 100, 2, 34, 1, 55, 1
	.hword	34, 1, 55, 1, 34, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 16
	.hword	255, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0

mod_083D4CA8:				@ pitch of inst 3; pitch of inst 4
	.hword	16, 200, 255, 0, 0, 0, 0, 0

mod_083D4CB8:				@ pitch of inst 5
	.hword	34, 1, 16, 200, 255, 0, 0, 0

mod_083D4CC8:				@ pitch of inst 6
	.hword	55, 1, 70, 1, 35, 1, 70, 1
	.hword	35, 1, 70, 1, 35, 1, 70, 1
	.hword	35, 1, 70, 1, 35, 1, 70, 1
	.hword	254, 0, 0, 0, 0, 0

mod_083D4D04:				@ pitch of inst 10; pitch of inst 11; pitch of inst 12; pitch of inst 13; pitch of inst 14; pitch of inst 15; pitch of inst 7; pitch of inst 8; pitch of inst 9
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	254, 0, 0, 0

mod_083D4D1C:				@ arp of inst 16; arp of inst 22
	.hword	1, 0, 1, 4, 1, 7, 1, 0
	.hword	1, 4, 1, 7, 254, 0, 0, 0

mod_083D4D3C:				@ arp of inst 17; arp of inst 23
	.hword	1, 4, 1, 7, 1, 12, 1, 4
	.hword	1, 7, 1, 12, 254, 0, 0, 0

mod_083D4D5C:				@ arp of inst 18; arp of inst 24
	.hword	1, 7, 1, 12, 1, 16, 1, 7
	.hword	1, 12, 1, 16, 254, 0, 0, 0

mod_083D4D7C:				@ arp of inst 19; arp of inst 25
	.hword	1, 0, 1, 3, 1, 7, 1, 0
	.hword	1, 3, 1, 7, 254, 0, 0, 0

mod_083D4D9C:				@ arp of inst 20; arp of inst 26
	.hword	1, 3, 1, 7, 1, 12, 1, 3
	.hword	1, 7, 1, 12, 254, 0, 0, 0

mod_083D4DBC:				@ arp of inst 21; arp of inst 27
	.hword	1, 7, 1, 12, 1, 15, 1, 7
	.hword	1, 12, 1, 15, 254, 0, 0, 0

@ PSG instruments (9 words): b0<<8 -> CNT_X, lo/hi -> envelope/duty register, then
@ {on, table} for envelope, pitch (noise parameter on ch4) and arpeggio
inst_00:				@ 083D4DDC
	INSTRUMENT 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0

inst_01:				@ 083D4E00
	INSTRUMENT 0x40, 0xBD, 0x00, 1, mod_083D4A2C, 1, mod_083D4C18, 0, 0

inst_02:				@ 083D4E24
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4A40, 1, mod_083D4C28, 0, 0

inst_03:				@ 083D4E48
	INSTRUMENT 0x40, 0xBC, 0x21, 0, 0, 1, mod_083D4CA8, 0, 0

inst_04:				@ 083D4E6C
	INSTRUMENT 0x40, 0xBA, 0x31, 0, 0, 1, mod_083D4CA8, 0, 0

inst_05:				@ 083D4E90
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083D4A78, 1, mod_083D4CB8, 0, 0

inst_06:				@ 083D4EB4
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083D4A88, 1, mod_083D4CC8, 0, 0

inst_07:				@ 083D4ED8
	INSTRUMENT 0x00, 0x00, 0x23, 0, 0, 1, mod_083D4D04, 0, 0

inst_08:				@ 083D4EFC
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083D4AD8, 6, mod_083D4D04, 0, 0

inst_09:				@ 083D4F20
	INSTRUMENT 0x00, 0x40, 0x57, 0, 0, 1, mod_083D4D04, 0, 0

inst_10:				@ 083D4F44
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B18, 1, mod_083D4D04, 0, 0

inst_11:				@ 083D4F68
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083D4AF8, 6, mod_083D4D04, 0, 0

inst_16:				@ 083D4F8C
	INSTRUMENT 0x00, 0x40, 0x25, 0, 0, 0, 0, 1, mod_083D4D1C

inst_17:				@ 083D4FB0
	INSTRUMENT 0x00, 0x40, 0x25, 0, 0, 0, 0, 1, mod_083D4D3C

inst_18:				@ 083D4FD4
	INSTRUMENT 0x00, 0x40, 0x25, 0, 0, 0, 0, 1, mod_083D4D5C

inst_19:				@ 083D4FF8
	INSTRUMENT 0x00, 0x40, 0x25, 0, 0, 0, 0, 1, mod_083D4D7C

inst_20:				@ 083D501C
	INSTRUMENT 0x00, 0x40, 0x25, 0, 0, 0, 0, 1, mod_083D4D9C

inst_21:				@ 083D5040
	INSTRUMENT 0x00, 0x40, 0x25, 0, 0, 0, 0, 1, mod_083D4DBC

inst_22:				@ 083D5064
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B38, 0, 0, 1, mod_083D4D1C

inst_23:				@ 083D5088
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B38, 0, 0, 1, mod_083D4D3C

inst_24:				@ 083D50AC
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B38, 0, 0, 1, mod_083D4D5C

inst_25:				@ 083D50D0
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B38, 0, 0, 1, mod_083D4D7C

inst_26:				@ 083D50F4
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B38, 0, 0, 1, mod_083D4D9C

inst_27:				@ 083D5118
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_083D4B38, 0, 0, 1, mod_083D4DBC

inst_28:				@ 083D513C
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4B58, 0, 0, 0, 0

inst_29:				@ 083D5160
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4B78, 0, 0, 0, 0

inst_30:				@ 083D5184
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4B98, 0, 0, 0, 0

inst_31:				@ 083D51A8
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4BB8, 0, 0, 0, 0

inst_32:				@ 083D51CC
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4BD8, 0, 0, 0, 0

inst_33:				@ 083D51F0
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083D4BF8, 0, 0, 0, 0

	.global mcInstTable
mcInstTable:				@ 083D5214
	.word	inst_00	@ 0
	.word	inst_01	@ 1
	.word	inst_02	@ 2
	.word	inst_03	@ 3
	.word	inst_04	@ 4
	.word	inst_05	@ 5
	.word	inst_06	@ 6
	.word	inst_07	@ 7
	.word	inst_08	@ 8
	.word	inst_09	@ 9
	.word	inst_10	@ 10
	.word	inst_11	@ 11
	.word	inst_11	@ 12
	.word	inst_11	@ 13
	.word	inst_11	@ 14
	.word	inst_11	@ 15
	.word	inst_16	@ 16
	.word	inst_17	@ 17
	.word	inst_18	@ 18
	.word	inst_19	@ 19
	.word	inst_20	@ 20
	.word	inst_21	@ 21
	.word	inst_22	@ 22
	.word	inst_23	@ 23
	.word	inst_24	@ 24
	.word	inst_25	@ 25
	.word	inst_26	@ 26
	.word	inst_27	@ 27
	.word	inst_28	@ 28
	.word	inst_29	@ 29
	.word	inst_30	@ 30
	.word	inst_31	@ 31
	.word	inst_32	@ 32
	.word	inst_33	@ 33
@ ----------------------------------------------------------------------------
	.section .fadetab, "a", %progbits
@ ----------------------------------------------------------------------------

@ mcFadeTable: music-buffer gain (x/256) per fade level 0..8; used only by the (unused) fade-out
	.global mcFadeTable
mcFadeTable:				@ 0803AE58
	.word	0, 16, 32, 48, 64, 80, 96, 112, 128
