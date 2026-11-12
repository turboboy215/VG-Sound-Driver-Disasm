@ ============================================================================
@ snood2_sound_data.s -- music and SFX data of Snood 2: Snoods on Vacation (GBA)
@ Mark Cooksey sound driver, "Build B" (4 PSG + 4 software-mixed PCM channels).
@ Reconstructed from "Snood 2 - Snoods on Vacation (E) (M5).gba" (B2VP).
@   section .steptab    0800FB60-08010184 (1572 bytes)
@   section .musicdata  080128B4-08092014 (522080 bytes)
@ Linking with snood2_sound_data.ld and objcopy reproduces each range byte for byte
@ (make -f snood2_sound.mk).  PCM sample data is pulled in from snood2_pcm.bin.
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
	.equ	IWRAM_mcMixMusic, 0x030048F0
	.equ	IWRAM_mcSfxMix, 0x030046F0

@ ----------------------------------------------------------------------------
	.section .steptab, "a", %progbits
@ ----------------------------------------------------------------------------

@ E.T.-style mcSmpNoteTable {rate Hz, samples/frame, timer period}: left over from Build A,
@ not referenced by this driver
	.global mcLegacySmpNoteTable
mcLegacySmpNoteTable:				@ 0800FB60
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
mcStepTable:				@ 0800FFE0
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

@ mcFadeTable: music-buffer gain (x/256) per fade level 0..8; used only by the (unused) fade-out
	.global mcFadeTable
mcFadeTable:				@ 08010160
	.word	0, 16, 32, 48, 64, 80, 96, 112, 128
@ ----------------------------------------------------------------------------
	.section .musicdata, "a", %progbits
@ ----------------------------------------------------------------------------

@ mcMixerFuncs: called by mcUpdate via _call_via_r1 (the mixers run from IWRAM)
	.global mcMixerFuncs
mcMixerFuncs:				@ 080128B4
	.word	IWRAM_mcMixMusic	@ ARM
	.word	IWRAM_mcSfxMix+1	@ Thumb

@ PCM sample data: 8-bit signed.  Music instruments are recorded so that note 48
@ = 11 025 Hz; SFX run 1:1 through the 10.5 kHz SFX mixer.  Labels mark each start
@ address referenced by mcSmpInstTable / mcSfxTable.
	.global pcm_080128BC
pcm_080128BC:				@ 080128BC, 1104 bytes
	.incbin "snood2_pcm.bin", 0x0, 0x450
	.global pcm_08012D0C
pcm_08012D0C:				@ 08012D0C, 3316 bytes
	.incbin "snood2_pcm.bin", 0x450, 0xCF4
	.global pcm_08013A00
pcm_08013A00:				@ 08013A00, 2280 bytes
	.incbin "snood2_pcm.bin", 0x1144, 0x8E8
	.global pcm_080142E8
pcm_080142E8:				@ 080142E8, 3320 bytes
	.incbin "snood2_pcm.bin", 0x1A2C, 0xCF8
	.global pcm_08014FE0
pcm_08014FE0:				@ 08014FE0, 3748 bytes
	.incbin "snood2_pcm.bin", 0x2724, 0xEA4
	.global pcm_08015E84
pcm_08015E84:				@ 08015E84, 3288 bytes
	.incbin "snood2_pcm.bin", 0x35C8, 0xCD8
	.global pcm_08016B5C
pcm_08016B5C:				@ 08016B5C, 3520 bytes
	.incbin "snood2_pcm.bin", 0x42A0, 0xDC0
	.global pcm_0801791C
pcm_0801791C:				@ 0801791C, 4440 bytes
	.incbin "snood2_pcm.bin", 0x5060, 0x1158
	.global pcm_08018A74
pcm_08018A74:				@ 08018A74, 5936 bytes
	.incbin "snood2_pcm.bin", 0x61B8, 0x1730
	.global pcm_0801A1A4
pcm_0801A1A4:				@ 0801A1A4, 6548 bytes
	.incbin "snood2_pcm.bin", 0x78E8, 0x1994
	.global pcm_0801BB38
pcm_0801BB38:				@ 0801BB38, 22784 bytes
	.incbin "snood2_pcm.bin", 0x927C, 0x5900
	.global pcm_08021438
pcm_08021438:				@ 08021438, 15224 bytes
	.incbin "snood2_pcm.bin", 0xEB7C, 0x3B78
	.global pcm_08024FB0
pcm_08024FB0:				@ 08024FB0, 4912 bytes
	.incbin "snood2_pcm.bin", 0x126F4, 0x1330
	.global pcm_080262E0
pcm_080262E0:				@ 080262E0, 22068 bytes
	.incbin "snood2_pcm.bin", 0x13A24, 0x5634
	.global pcm_0802B914
pcm_0802B914:				@ 0802B914, 28160 bytes
	.incbin "snood2_pcm.bin", 0x19058, 0x6E00
	.global pcm_08032714
pcm_08032714:				@ 08032714, 22688 bytes
	.incbin "snood2_pcm.bin", 0x1FE58, 0x58A0
	.global pcm_08037FB4
pcm_08037FB4:				@ 08037FB4, 12512 bytes
	.incbin "snood2_pcm.bin", 0x256F8, 0x30E0
	.global pcm_0803B094
pcm_0803B094:				@ 0803B094, 10880 bytes
	.incbin "snood2_pcm.bin", 0x287D8, 0x2A80
	.global pcm_0803DB14
pcm_0803DB14:				@ 0803DB14, 5936 bytes
	.incbin "snood2_pcm.bin", 0x2B258, 0x1730
	.global pcm_0803F244
pcm_0803F244:				@ 0803F244, 33600 bytes
	.incbin "snood2_pcm.bin", 0x2C988, 0x8340
	.global pcm_08047584
pcm_08047584:				@ 08047584, 29376 bytes
	.incbin "snood2_pcm.bin", 0x34CC8, 0x72C0
	.global pcm_0804E844
pcm_0804E844:				@ 0804E844, 9872 bytes
	.incbin "snood2_pcm.bin", 0x3BF88, 0x2690
	.global pcm_08050ED4
pcm_08050ED4:				@ 08050ED4, 20380 bytes
	.incbin "snood2_pcm.bin", 0x3E618, 0x4F9C
	.global pcm_08055E70
pcm_08055E70:				@ 08055E70, 8512 bytes
	.incbin "snood2_pcm.bin", 0x435B4, 0x2140
	.global pcm_08057FB0
pcm_08057FB0:				@ 08057FB0, 8512 bytes
	.incbin "snood2_pcm.bin", 0x456F4, 0x2140
	.global pcm_0805A0F0
pcm_0805A0F0:				@ 0805A0F0, 1024 bytes
	.incbin "snood2_pcm.bin", 0x47834, 0x400
	.global pcm_0805A4F0
pcm_0805A4F0:				@ 0805A4F0, 6192 bytes
	.incbin "snood2_pcm.bin", 0x47C34, 0x1830
	.global pcm_0805BD20
pcm_0805BD20:				@ 0805BD20, 4880 bytes
	.incbin "snood2_pcm.bin", 0x49464, 0x1310
	.global pcm_0805D030
pcm_0805D030:				@ 0805D030, 12008 bytes
	.incbin "snood2_pcm.bin", 0x4A774, 0x2EE8
	.global pcm_0805FF18
pcm_0805FF18:				@ 0805FF18, 3624 bytes
	.incbin "snood2_pcm.bin", 0x4D65C, 0xE28
	.global pcm_08060D40
pcm_08060D40:				@ 08060D40, 1680 bytes
	.incbin "snood2_pcm.bin", 0x4E484, 0x690
	.global pcm_080613D0
pcm_080613D0:				@ 080613D0, 8864 bytes
	.incbin "snood2_pcm.bin", 0x4EB14, 0x22A0
	.global pcm_08063670
pcm_08063670:				@ 08063670, 1276 bytes
	.incbin "snood2_pcm.bin", 0x50DB4, 0x4FC
	.global pcm_08063B6C
pcm_08063B6C:				@ 08063B6C, 4560 bytes
	.incbin "snood2_pcm.bin", 0x512B0, 0x11D0
	.global pcm_08064D3C
pcm_08064D3C:				@ 08064D3C, 1004 bytes
	.incbin "snood2_pcm.bin", 0x52480, 0x3EC
	.global pcm_08065128
pcm_08065128:				@ 08065128, 4336 bytes
	.incbin "snood2_pcm.bin", 0x5286C, 0x10F0
	.global pcm_08066218
pcm_08066218:				@ 08066218, 5712 bytes
	.incbin "snood2_pcm.bin", 0x5395C, 0x1650
	.global pcm_08067868
pcm_08067868:				@ 08067868, 10132 bytes
	.incbin "snood2_pcm.bin", 0x54FAC, 0x2794
	.global pcm_08069FFC
pcm_08069FFC:				@ 08069FFC, 10216 bytes
	.incbin "snood2_pcm.bin", 0x57740, 0x27E8
	.global pcm_0806C7E4
pcm_0806C7E4:				@ 0806C7E4, 50008 bytes
	.incbin "snood2_pcm.bin", 0x59F28, 0xC358
	.global pcm_08078B3C
pcm_08078B3C:				@ 08078B3C, 38656 bytes
	.incbin "snood2_pcm.bin", 0x66280, 0x9700

@ mcSfxTable: {pcm, frames (176-byte chunks), loop (0 = one-shot), unused}
	.global mcSfxTable
mcSfxTable:				@ 0808223C
	.word	pcm_080128BC, 0x6, 0x0, 0x80	@ sfx 0
	.word	pcm_08060D40, 0x9, 0x0, 0x80	@ sfx 1
	.word	pcm_080613D0, 0x30, 0x0, 0x80	@ sfx 2
	.word	pcm_08063670, 0x6, 0x0, 0x80	@ sfx 3
	.word	pcm_08063B6C, 0x18, 0x0, 0x80	@ sfx 4
	.word	pcm_08064D3C, 0x5, 0x0, 0x80	@ sfx 5
	.word	pcm_08065128, 0x17, 0x0, 0x80	@ sfx 6
	.word	pcm_08066218, 0x1F, 0x0, 0x80	@ sfx 7
	.word	pcm_08067868, 0x37, 0x0, 0x80	@ sfx 8
	.word	pcm_08069FFC, 0x37, 0x0, 0x80	@ sfx 9
	.word	pcm_0806C7E4, 0x111, 0x0, 0x80	@ sfx 10
	.word	pcm_08078B3C, 0xD3, 0x0, 0x80	@ sfx 11
	.word	0, 0x0, 0x0, 0x0	@ sfx 12
	.word	0, 0x0, 0x0, 0x0	@ sfx 13
	.word	0, 0x0, 0x0, 0x0	@ sfx 14
	.word	0, 0x0, 0x0, 0x0	@ sfx 15

@ mcSmpInstTable: PCM instrument n -> {pcm, length, flag, pad}.  flag == 1: one-shot;
@ any other value: loop from offset 0.  The mix reads up to (length - 4).
	.global mcSmpInstTable
mcSmpInstTable:				@ 0808233C
	.word	pcm_080128BC, 0x450, 1, 0	@ inst 0
	.word	pcm_0801BB38, 0x5880, 1, 0	@ inst 1
	.word	pcm_08012D0C, 0xCD4, 1, 0	@ inst 2
	.word	pcm_08013A00, 0x868, 1, 0	@ inst 3
	.word	pcm_080142E8, 0xCD8, 1, 0	@ inst 4
	.word	pcm_08015E84, 0xCB8, 1, 0	@ inst 5
	.word	pcm_08014FE0, 0xE84, 1, 0	@ inst 6
	.word	pcm_08016B5C, 0xDA0, 1, 0	@ inst 7
	.word	pcm_0801791C, 0x1138, 1, 0	@ inst 8
	.word	pcm_08018A74, 0x1710, 1, 0	@ inst 9
	.word	pcm_0801A1A4, 0x1974, 1, 0	@ inst 10
	.word	pcm_08021438, 0x3B78, 1, 0	@ inst 11
	.word	pcm_08024FB0, 0x1330, 1, 0	@ inst 12
	.word	pcm_080262E0, 0x5634, 1, 0	@ inst 13
	.word	pcm_08032714, 0x58A0, 1, 0	@ inst 14
	.word	pcm_0802B914, 0x6E00, 1, 0	@ inst 15
	.word	pcm_08037FB4, 0x30E0, 1, 0	@ inst 16
	.word	pcm_0803B094, 0x2A80, 1, 0	@ inst 17
	.word	pcm_0803F244, 0x8340, 1, 0	@ inst 18
	.word	pcm_08047584, 0x72C0, 1, 0	@ inst 19
	.word	pcm_0804E844, 0x2690, 1, 0	@ inst 20
	.word	pcm_08050ED4, 0x4F9C, 1, 0	@ inst 21
	.word	pcm_0803DB14, 0x1730, 1, 0	@ inst 22
	.word	pcm_08055E70, 0x2140, 1, 0	@ inst 23
	.word	pcm_08057FB0, 0x2140, 1, 0	@ inst 24
	.word	pcm_0805A0F0, 0x1C30, 1, 0	@ inst 25
	.word	pcm_0805A4F0, 0x800, pcm_0805A0F0, 0x1770	@ inst 26
	.word	pcm_0805BD20, 0x1310, pcm_0805BD20, 0x1310	@ inst 27
	.word	pcm_0805D030, 0x2EE8, pcm_0805D030, 0x2EE8	@ inst 28
	.word	pcm_0805FF18, 0xE28, 1, 0	@ inst 29
	.word	0, 0x0, 0, 0	@ inst 30
	.word	0, 0x0, 0, 0	@ inst 31

@ mcPsgSfxMap: PSG effect n -> 4 script numbers (0xFF = none).  mcPlayPsgSfx has no callers.
	.global mcPsgSfxMap
mcPsgSfxMap:				@ 0808253C
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

psgScript_09:				@ 0808257C  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0005, 0x0080, 0x00A1, 0x0084, 0x00B6
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_10:				@ 08082594  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0005, 0x0080, 0x00A1, 0x0087, 0x00BA
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_11:				@ 080825AC  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0014, 0x0000, 0x0020, 0x0084, 0x00B6
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_06:				@ 080825C4  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0008, 0x0080, 0x00A2, 0x0087, 0x0014
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_07:				@ 080825DC  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0008, 0x0080, 0x00A2, 0x0086, 0x0089
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_08:				@ 080825F4  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0030, 0x0000, 0x0080, 0x0084, 0x004F
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_04:				@ 0808260C  channel 3   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	3
	.hword	0x0014, 0x0000, 0x002A, 0x0080, 0x0021
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_05:				@ 08082624  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0006, 0x0080, 0x00C3, 0x0087, 0x0014
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_00:				@ 0808263C  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_01:				@ 0808265C  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_02:				@ 0808267C  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_03:				@ 0808269C  channel 3   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	3
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

	.global mcPsgSfxScripts
mcPsgSfxScripts:				@ 080826BC
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
@ 080826FC-080827FC: 256 bytes, unreferenced table of {value, 0x88/0x89} word pairs
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
durTable0:				@ 080827FC
	.word	  3,   4,   6,   9,  12,  18,  24,  36	@ [0..7]
	.word	 48,  72,  96, 144, 192,   8,  16,  32	@ [8..15]
	.word	 40,  64,  80,  84,  15,  54,  60,  42	@ [16..23]
	.word	 30, 108, 132, 156,   2, 120,  28,  21	@ [24..31]
	.word	 51,  33, 168, 1536, 288, 384, 624, 216	@ [32..39]
	.word	 90, 102,  66,   1, 180,  56,  20,  78	@ [40..47]
	.word	  3,   4,   6,   9,  12,  18,  24,  36	@ [48..55]
	.word	 48,  72,  96, 144, 192,   8,  16,  32	@ [56..63]
	.word	 10,  40	@ [64..65]

@ ----------------------------------------------------------------------------
@ patterns: {note, instrument, length-index} events, 0x65 = end.  Note names assume
@ index 0 = C#2 on the PSG channels; on channels 5-8 the note selects a resampling step.
@ ----------------------------------------------------------------------------
pat_08082904:				@ used by s10c1, s12c1, s12c2, s1c2, s1c3, s2c2, s2c3, s3c2, s3c3, s4c2, s4c3, s5c1, s5c3, s6c1, s7c1, s7c2, s9c1
	N	60, 0, 10		@ C#7
	PAT_END

pat_08082908:				@ used by s0c1, s0c2, s0c3, s0c4
	N	60, 0, 0		@ C#7
	PAT_END

pat_0808290C:				@ used by s0c5, s0c6, s0c7, s0c8, s11c5, s11c6, s13c1, s13c5, s1c6, s1c7, s2c5, s3c6, s5c5, s7c5, s8c5, s8c6, s9c5
	N	48, 0, 10		@ C#6
	PAT_END

pat_08082910:				@ used by s2c5
	N	48, 0, 8		@ C#6
	PAT_END

pat_08082914:				@ used by s10c1, s10c2, s10c3, s10c4, s10c5, s10c6, s10c7, s10c8, s11c1, s11c2, s11c3, s11c4, s11c5, s11c6, s11c7, s11c8, s12c1, s12c2, s12c3, s12c4, s12c5, s12c6, s12c7, s12c8, s13c1, s13c2, s13c3, s13c4, s13c5, s13c6, s13c7, s13c8, s1c1, s1c2, s1c3, s1c4, s1c5, s1c6, s1c7, s1c8, s2c1, s2c2, s2c3, s2c4, s2c5, s2c6, s2c7, s2c8, s3c1, s3c2, s3c3, s3c4, s3c5, s3c6, s3c7, s3c8, s4c1, s4c2, s4c3, s4c4, s4c5, s4c6, s4c7, s4c8, s5c1, s5c2, s5c3, s5c4, s5c5, s5c6, s5c7, s5c8, s6c1, s6c2, s6c3, s6c4, s6c5, s6c6, s6c7, s6c8, s7c1, s7c2, s7c3, s7c4, s7c5, s7c6, s7c7, s7c8, s8c1, s8c2, s8c3, s8c4, s8c5, s8c6, s8c7, s8c8, s9c1, s9c2, s9c3, s9c4, s9c5, s9c6, s9c7, s9c8
	N	48, 0, 43		@ C#6
	PAT_END

pat_08082918:				@ used by s1c5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	36, 1, 5		@ C#5
	N	40, 1, 4		@ F5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	PAT_END

pat_08082979:				@ used by s1c5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	36, 1, 5		@ C#5
	N	40, 1, 4		@ F5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	PAT_END

pat_08082A3A:				@ used by s1c5
	N	36, 1, 5		@ C#5
	N	36, 1, 4		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 2		@ F5
	N	31, 1, 5		@ G#4
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	43, 1, 2		@ G#5
	N	33, 1, 5		@ A#4
	N	33, 1, 4		@ A#4
	N	36, 1, 2		@ C#5
	N	40, 1, 2		@ F5
	N	36, 1, 2		@ C#5
	N	29, 1, 5		@ F#4
	N	36, 1, 4		@ C#5
	N	41, 1, 2		@ F#5
	N	36, 1, 2		@ C#5
	N	33, 1, 2		@ A#4
	N	31, 1, 5		@ G#4
	N	36, 1, 4		@ C#5
	N	40, 1, 2		@ F5
	N	36, 1, 2		@ C#5
	N	35, 1, 2		@ C5
	N	31, 1, 5		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 2		@ D#5
	N	43, 1, 2		@ G#5
	N	38, 1, 2		@ D#5
	N	41, 1, 5		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 2		@ A#4
	N	29, 1, 2		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 5		@ C#5
	N	40, 1, 4		@ F5
	N	36, 1, 2		@ C#5
	N	43, 1, 2		@ G#5
	N	31, 1, 2		@ G#4
	PAT_END

pat_08082AB3:				@ used by s1c5
	N	31, 1, 5		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 2		@ D#5
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	35, 1, 5		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 2		@ G5
	N	47, 1, 2		@ C6
	N	42, 1, 2		@ G5
	N	40, 1, 5		@ F5
	N	43, 1, 4		@ G#5
	N	47, 1, 2		@ C6
	N	43, 1, 2		@ G#5
	N	40, 1, 2		@ F5
	N	36, 1, 5		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 5		@ D#5
	N	43, 1, 4		@ G#5
	N	47, 1, 2		@ C6
	N	43, 1, 4		@ G#5
	N	38, 1, 5		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 2		@ A#5
	N	42, 1, 4		@ G5
	N	43, 1, 5		@ G#5
	N	38, 1, 4		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 2		@ G#4
	N	35, 1, 2		@ C5
	N	36, 1, 5		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 5		@ D#5
	N	43, 1, 4		@ G#5
	N	47, 1, 2		@ C6
	N	43, 1, 4		@ G#5
	N	38, 1, 5		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 2		@ A#5
	N	42, 1, 4		@ G5
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	PAT_END

pat_08082B7D:				@ used by s1c5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 5		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	PAT_END

pat_08082BDE:				@ used by s1c5
	N	36, 1, 5		@ C#5
	N	36, 1, 4		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 4		@ G#5
	N	41, 1, 5		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 2		@ A#4
	N	29, 1, 4		@ F#4
	N	31, 1, 5		@ G#4
	N	36, 1, 4		@ C#5
	N	40, 1, 2		@ F5
	N	36, 1, 4		@ C#5
	N	31, 1, 5		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 2		@ D#5
	N	43, 1, 2		@ G#5
	N	38, 1, 2		@ D#5
	N	36, 1, 5		@ C#5
	N	36, 1, 4		@ C#5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 5		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 2		@ A#4
	N	29, 1, 2		@ F#4
	N	33, 1, 2		@ A#4
	N	31, 1, 5		@ G#4
	N	36, 1, 4		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 4		@ G#5
	N	31, 1, 5		@ G#4
	N	32, 1, 4		@ A4
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	N	33, 1, 5		@ A#4
	N	36, 1, 4		@ C#5
	N	40, 1, 2		@ F5
	N	45, 1, 4		@ A#5
	N	38, 1, 5		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 2		@ A#5
	N	42, 1, 4		@ G5
	N	43, 1, 5		@ G#5
	N	38, 1, 4		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	36, 1, 5		@ C#5
	N	36, 1, 4		@ C#5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 5		@ F#5
	N	29, 1, 5		@ F#4
	N	33, 1, 4		@ A#4
	N	36, 1, 5		@ C#5
	N	41, 1, 4		@ F#5
	N	29, 1, 2		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	31, 1, 5		@ G#4
	N	35, 1, 5		@ C5
	N	38, 1, 4		@ D#5
	N	43, 1, 4		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 5		@ C5
	N	31, 1, 4		@ G#4
	PAT_END

pat_08082CA2:				@ used by s1c6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	57, 11, 4		@ A#6
	N	55, 11, 8		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 4		@ C#7
	N	60, 11, 8		@ C#7
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	57, 11, 4		@ A#6
	N	55, 11, 8		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	59, 11, 4		@ C7
	N	57, 11, 2		@ A#6
	N	59, 11, 4		@ C7
	N	60, 11, 8		@ C#7
	PAT_END

pat_08082D3F:				@ used by s1c6
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	55, 11, 4		@ G#6
	N	59, 11, 4		@ C7
	N	62, 11, 6		@ D#7
	N	57, 11, 2		@ A#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	57, 11, 2		@ A#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	57, 11, 2		@ A#6
	N	60, 11, 2		@ C#7
	N	57, 11, 4		@ A#6
	N	60, 11, 4		@ C#7
	N	65, 11, 6		@ F#7
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	55, 11, 4		@ G#6
	N	59, 11, 4		@ C7
	N	62, 11, 6		@ D#7
	N	53, 11, 2		@ F#6
	N	57, 11, 2		@ A#6
	N	60, 11, 2		@ C#7
	N	53, 11, 2		@ F#6
	N	57, 11, 2		@ A#6
	N	60, 11, 2		@ C#7
	N	53, 11, 2		@ F#6
	N	57, 11, 2		@ A#6
	N	55, 11, 4		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 6		@ F7
	PAT_END

pat_08082DC4:				@ used by s1c6
	N	59, 11, 2		@ C7
	N	62, 11, 2		@ D#7
	N	67, 11, 2		@ G#7
	N	71, 11, 4		@ C8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 6		@ C#7
	N	59, 11, 2		@ C7
	N	63, 11, 2		@ E7
	N	66, 11, 2		@ G7
	N	71, 11, 4		@ C8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	66, 11, 2		@ G7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	66, 11, 2		@ G7
	N	64, 11, 6		@ F7
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	67, 11, 2		@ G#7
	N	72, 11, 4		@ C#8
	N	71, 11, 2		@ C8
	N	69, 11, 4		@ A#7
	N	71, 11, 4		@ C8
	N	67, 11, 2		@ G#7
	N	67, 11, 4		@ G#7
	N	69, 11, 2		@ A#7
	N	71, 11, 4		@ C8
	N	69, 11, 4		@ A#7
	N	66, 11, 2		@ G7
	N	66, 11, 4		@ G7
	N	67, 11, 2		@ G#7
	N	69, 11, 4		@ A#7
	N	67, 11, 4		@ G#7
	N	69, 11, 2		@ A#7
	N	71, 11, 4		@ C8
	N	72, 11, 2		@ C#8
	N	74, 11, 4		@ D#8
	N	72, 11, 4		@ C#8
	N	69, 11, 2		@ A#7
	N	69, 11, 4		@ A#7
	N	71, 11, 2		@ C8
	N	72, 11, 4		@ C#8
	N	71, 11, 4		@ C8
	N	67, 11, 2		@ G#7
	N	67, 11, 4		@ G#7
	N	69, 11, 2		@ A#7
	N	71, 11, 4		@ C8
	N	69, 11, 4		@ A#7
	N	66, 11, 2		@ G7
	N	66, 11, 4		@ G7
	N	67, 11, 2		@ G#7
	N	69, 11, 4		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 4		@ C#7
	N	60, 11, 8		@ C#7
	PAT_END

pat_08082EB8:				@ used by s1c6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	57, 11, 4		@ A#6
	N	55, 11, 8		@ G#6
	N	60, 11, 5		@ C#7
	N	64, 11, 4		@ F7
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	65, 11, 5		@ F#7
	N	62, 11, 4		@ D#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	60, 11, 5		@ C#7
	N	59, 11, 4		@ C7
	N	57, 11, 2		@ A#6
	N	59, 11, 4		@ C7
	N	60, 11, 8		@ C#7
	PAT_END

pat_08082F07:				@ used by s1c6
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	68, 12, 0		@ A7
	N	64, 12, 0		@ F7
	N	68, 12, 0		@ A7
	N	64, 12, 0		@ F7
	N	68, 12, 0		@ A7
	N	64, 12, 0		@ F7
	N	68, 12, 0		@ A7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	60, 12, 0		@ C#7
	N	64, 12, 0		@ F7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	66, 12, 0		@ G7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	62, 12, 0		@ D#7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	67, 12, 0		@ G#7
	N	64, 12, 0		@ F7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	69, 12, 0		@ A#7
	N	65, 12, 0		@ F#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	N	71, 12, 0		@ C8
	N	67, 12, 0		@ G#7
	PAT_END

pat_08083208:				@ used by s1c7
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	55, 11, 2		@ G#6
	N	53, 11, 4		@ F#6
	N	50, 11, 8		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	52, 11, 8		@ F6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	55, 11, 2		@ G#6
	N	53, 11, 4		@ F#6
	N	50, 11, 8		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	55, 11, 4		@ G#6
	N	53, 11, 2		@ F#6
	N	55, 11, 4		@ G#6
	N	55, 11, 8		@ G#6
	PAT_END

pat_080832A5:				@ used by s1c7
	N	76, 13, 5		@ F8
	N	72, 13, 5		@ C#8
	N	76, 13, 4		@ F8
	N	74, 13, 5		@ D#8
	N	71, 13, 5		@ C8
	N	74, 13, 4		@ D#8
	N	72, 13, 5		@ C#8
	N	69, 13, 5		@ A#7
	N	72, 13, 4		@ C#8
	N	71, 13, 5		@ C8
	N	69, 13, 5		@ A#7
	N	67, 13, 4		@ G#7
	N	67, 13, 5		@ G#7
	N	72, 13, 5		@ C#8
	N	76, 13, 4		@ F8
	N	74, 13, 5		@ D#8
	N	72, 13, 5		@ C#8
	N	71, 13, 4		@ C8
	N	69, 13, 5		@ A#7
	N	67, 13, 5		@ G#7
	N	65, 13, 4		@ F#7
	N	64, 13, 4		@ F7
	N	67, 13, 4		@ G#7
	N	72, 13, 6		@ C#8
	N	79, 13, 24		@ G#8
	N	77, 13, 2		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 4		@ C8
	N	67, 13, 4		@ G#7
	N	76, 13, 7		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	69, 13, 4		@ A#7
	N	65, 13, 4		@ F#7
	N	67, 13, 4		@ G#7
	N	72, 13, 2		@ C#8
	N	76, 13, 2		@ F8
	N	79, 13, 7		@ G#8
	N	77, 13, 2		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 2		@ D#8
	N	72, 13, 4		@ C#8
	N	71, 13, 5		@ C8
	N	69, 13, 4		@ A#7
	N	67, 13, 2		@ G#7
	N	65, 13, 4		@ F#7
	N	64, 13, 8		@ F7
	PAT_END

pat_08083348:				@ used by s1c7
	N	55, 11, 2		@ G#6
	N	59, 11, 2		@ C7
	N	62, 11, 2		@ D#7
	N	67, 11, 4		@ G#7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 2		@ C#7
	N	62, 11, 2		@ D#7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	N	55, 11, 6		@ G#6
	N	54, 11, 2		@ G6
	N	59, 11, 2		@ C7
	N	63, 11, 2		@ E7
	N	66, 11, 4		@ G7
	N	66, 11, 2		@ G7
	N	64, 11, 2		@ F7
	N	63, 11, 2		@ E7
	N	64, 11, 2		@ F7
	N	66, 11, 2		@ G7
	N	64, 11, 2		@ F7
	N	63, 11, 2		@ E7
	N	59, 11, 6		@ C7
	N	55, 11, 2		@ G#6
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	67, 11, 4		@ G#7
	N	67, 11, 2		@ G#7
	N	66, 11, 4		@ G7
	N	67, 11, 4		@ G#7
	N	62, 11, 2		@ D#7
	N	62, 11, 4		@ D#7
	N	66, 11, 2		@ G7
	N	67, 11, 4		@ G#7
	N	66, 11, 4		@ G7
	N	62, 11, 2		@ D#7
	N	62, 11, 4		@ D#7
	N	64, 11, 2		@ F7
	N	66, 11, 4		@ G7
	N	62, 11, 4		@ D#7
	N	66, 11, 2		@ G7
	N	67, 11, 4		@ G#7
	N	69, 11, 2		@ A#7
	N	71, 11, 4		@ C8
	N	67, 11, 4		@ G#7
	N	64, 11, 2		@ F7
	N	64, 11, 4		@ F7
	N	67, 11, 2		@ G#7
	N	69, 11, 4		@ A#7
	N	67, 11, 4		@ G#7
	N	62, 11, 2		@ D#7
	N	62, 11, 4		@ D#7
	N	66, 11, 2		@ G7
	N	67, 11, 4		@ G#7
	N	66, 11, 4		@ G7
	N	62, 11, 2		@ D#7
	N	62, 11, 4		@ D#7
	N	64, 11, 2		@ F7
	N	66, 11, 4		@ G7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	N	57, 11, 2		@ A#6
	N	60, 11, 2		@ C#7
	N	62, 11, 2		@ D#7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	59, 11, 2		@ C7
	N	55, 11, 4		@ G#6
	N	52, 11, 8		@ F6
	PAT_END

pat_0808343C:				@ used by s1c7
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	55, 11, 2		@ G#6
	N	53, 11, 4		@ F#6
	N	50, 11, 8		@ D#6
	N	55, 11, 5		@ G#6
	N	60, 11, 4		@ C#7
	N	64, 11, 4		@ F7
	N	60, 11, 2		@ C#7
	N	62, 11, 5		@ D#7
	N	59, 11, 4		@ C7
	N	55, 11, 2		@ G#6
	N	50, 11, 4		@ D#6
	N	55, 11, 5		@ G#6
	N	55, 11, 4		@ G#6
	N	53, 11, 2		@ F#6
	N	55, 11, 4		@ G#6
	N	55, 11, 8		@ G#6
	PAT_END

pat_0808348B:				@ used by s1c7
	N	60, 13, 4		@ C#7
	N	64, 13, 2		@ F7
	N	67, 13, 4		@ G#7
	N	72, 13, 5		@ C#8
	N	69, 13, 4		@ A#7
	N	67, 13, 2		@ G#7
	N	65, 13, 4		@ F#7
	N	67, 13, 2		@ G#7
	N	69, 13, 4		@ A#7
	N	67, 13, 4		@ G#7
	N	64, 13, 2		@ F7
	N	64, 13, 4		@ F7
	N	65, 13, 2		@ F#7
	N	67, 13, 4		@ G#7
	N	65, 13, 2		@ F#7
	N	67, 13, 2		@ G#7
	N	65, 13, 2		@ F#7
	N	64, 13, 2		@ F7
	N	62, 13, 4		@ D#7
	N	64, 13, 2		@ F7
	N	65, 13, 2		@ F#7
	N	60, 13, 4		@ C#7
	N	64, 13, 2		@ F7
	N	67, 13, 4		@ G#7
	N	72, 13, 4		@ C#8
	N	74, 13, 2		@ D#8
	N	76, 13, 4		@ F8
	N	74, 13, 2		@ D#8
	N	72, 13, 5		@ C#8
	N	69, 13, 4		@ A#7
	N	67, 13, 24		@ G#7
	N	72, 13, 2		@ C#8
	N	76, 13, 4		@ F8
	N	74, 13, 6		@ D#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	69, 13, 6		@ A#7
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	71, 13, 2		@ C8
	N	72, 13, 2		@ C#8
	N	69, 13, 2		@ A#7
	N	71, 13, 4		@ C8
	N	67, 13, 2		@ G#7
	N	67, 13, 5		@ G#7
	N	69, 13, 4		@ A#7
	N	71, 13, 2		@ C8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	67, 13, 4		@ G#7
	N	69, 13, 2		@ A#7
	N	71, 13, 2		@ C8
	N	69, 13, 4		@ A#7
	N	65, 13, 2		@ F#7
	N	65, 13, 5		@ F#7
	N	67, 13, 4		@ G#7
	N	69, 13, 5		@ A#7
	N	67, 13, 5		@ G#7
	N	65, 13, 4		@ F#7
	N	62, 13, 24		@ D#7
	N	64, 13, 2		@ F7
	N	65, 13, 2		@ F#7
	N	67, 13, 2		@ G#7
	N	69, 13, 4		@ A#7
	N	71, 13, 4		@ C8
	N	72, 13, 4		@ C#8
	N	74, 13, 4		@ D#8
	PAT_END

pat_0808356D:				@ used by s1c8
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 4, 2		@ C#6
	N	48, 10, 2		@ C#6
	PAT_END

pat_0808362E:				@ used by s1c1
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 16, 5		@ F#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 16, 4		@ C#5
	N	36, 16, 2		@ C#5
	N	36, 16, 4		@ C#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	PAT_END

pat_0808368F:				@ used by s1c1
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 16, 5		@ F#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 16, 5		@ F#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	PAT_END

pat_08083750:				@ used by s1c1
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	45, 19, 5		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 19, 4		@ A#5
	N	41, 17, 5		@ F#5
	N	41, 17, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 4		@ F#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	41, 16, 5		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	PAT_END

pat_080837B1:				@ used by s1c1
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	47, 16, 5		@ C6
	N	47, 16, 4		@ C6
	N	47, 16, 2		@ C6
	N	47, 16, 4		@ C6
	N	40, 21, 5		@ F5
	N	40, 21, 4		@ F5
	N	40, 21, 2		@ F5
	N	40, 21, 4		@ F5
	N	48, 16, 5		@ C#6
	N	48, 16, 4		@ C#6
	N	48, 16, 2		@ C#6
	N	48, 16, 4		@ C#6
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 2		@ D#5
	N	38, 18, 4		@ D#5
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	48, 16, 5		@ C#6
	N	48, 16, 4		@ C#6
	N	48, 16, 2		@ C#6
	N	48, 16, 4		@ C#6
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 2		@ D#5
	N	38, 18, 4		@ D#5
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	PAT_END

pat_08083872:				@ used by s1c1
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 16, 5		@ F#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 5		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	PAT_END

pat_080838D3:				@ used by s1c1
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 4		@ F#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	41, 17, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 4		@ F#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 4		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	40, 17, 4		@ F5
	N	40, 17, 2		@ F5
	N	40, 17, 4		@ F5
	N	33, 21, 4		@ A#4
	N	33, 21, 2		@ A#4
	N	33, 21, 4		@ A#4
	N	33, 21, 2		@ A#4
	N	33, 21, 4		@ A#4
	N	38, 17, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 4		@ D#5
	N	31, 18, 4		@ G#4
	N	31, 18, 2		@ G#4
	N	31, 18, 4		@ G#4
	N	31, 18, 2		@ G#4
	N	31, 18, 4		@ G#4
	N	36, 17, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 4		@ C#5
	N	41, 16, 4		@ F#5
	N	41, 16, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 4		@ G#5
	PAT_END

pat_080839C4:				@ used by s1c4
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
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	PAT_END

pat_08083A85:				@ used by s2c5
	N	55, 15, 4		@ G#6
	N	57, 15, 4		@ A#6
	N	59, 15, 6		@ C7
	N	62, 15, 6		@ D#7
	N	64, 15, 6		@ F7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	71, 15, 4		@ C8
	N	69, 15, 4		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	62, 15, 6		@ D#7
	N	59, 15, 6		@ C7
	N	55, 15, 6		@ G#6
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	63, 15, 6		@ E7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	63, 15, 6		@ E7
	N	62, 15, 11		@ D#7
	N	55, 15, 4		@ G#6
	N	57, 15, 4		@ A#6
	N	59, 15, 6		@ C7
	N	62, 15, 6		@ D#7
	N	64, 15, 6		@ F7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	71, 15, 4		@ C8
	N	69, 15, 4		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	62, 15, 6		@ D#7
	N	59, 15, 6		@ C7
	N	55, 15, 6		@ G#6
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	63, 15, 6		@ E7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	71, 15, 11		@ C8
	PAT_END

pat_08083B0A:				@ used by s2c5
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	63, 15, 6		@ E7
	N	67, 15, 6		@ G#7
	N	70, 15, 6		@ B7
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	70, 15, 4		@ B7
	N	69, 15, 4		@ A#7
	N	67, 15, 6		@ G#7
	N	63, 15, 6		@ E7
	N	62, 15, 6		@ D#7
	N	58, 15, 6		@ B6
	N	55, 15, 6		@ G#6
	N	62, 15, 4		@ D#7
	N	66, 15, 4		@ G7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 6		@ C#8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	66, 15, 6		@ G7
	N	67, 15, 6		@ G#7
	N	65, 15, 6		@ F#7
	N	62, 15, 4		@ D#7
	N	58, 15, 4		@ B6
	N	57, 15, 6		@ A#6
	N	55, 15, 8		@ G#6
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	63, 15, 6		@ E7
	N	67, 15, 6		@ G#7
	N	70, 15, 6		@ B7
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	70, 15, 6		@ B7
	N	75, 15, 6		@ E8
	N	74, 15, 6		@ D#8
	N	70, 15, 6		@ B7
	N	67, 15, 6		@ G#7
	N	69, 15, 4		@ A#7
	N	69, 15, 4		@ A#7
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	64, 15, 6		@ F7
	N	70, 15, 6		@ B7
	N	70, 15, 6		@ B7
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	66, 15, 4		@ G7
	N	63, 15, 4		@ E7
	N	62, 15, 8		@ D#7
	PAT_END

pat_08083BB3:				@ used by s2c5
	N	71, 15, 4		@ C8
	N	69, 15, 4		@ A#7
	N	71, 15, 6		@ C8
	N	66, 15, 6		@ G7
	N	63, 15, 6		@ E7
	N	59, 15, 6		@ C7
	N	69, 15, 6		@ A#7
	N	67, 15, 4		@ G#7
	N	66, 15, 4		@ G7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	59, 15, 6		@ C7
	N	55, 15, 6		@ G#6
	N	67, 15, 6		@ G#7
	N	71, 15, 4		@ C8
	N	69, 15, 4		@ A#7
	N	71, 15, 6		@ C8
	N	66, 15, 6		@ G7
	N	63, 15, 6		@ E7
	N	59, 15, 6		@ C7
	N	69, 15, 4		@ A#7
	N	68, 15, 4		@ A7
	N	68, 15, 4		@ A7
	N	66, 15, 4		@ G7
	N	68, 15, 6		@ A7
	N	64, 15, 6		@ F7
	N	59, 15, 6		@ C7
	N	56, 15, 6		@ A6
	N	64, 15, 6		@ F7
	N	57, 15, 4		@ A#6
	N	59, 15, 4		@ C7
	N	61, 15, 6		@ D7
	N	64, 15, 6		@ F7
	N	66, 15, 6		@ G7
	N	69, 15, 6		@ A#7
	N	71, 15, 6		@ C8
	N	73, 15, 4		@ D8
	N	71, 15, 4		@ C8
	N	69, 15, 6		@ A#7
	N	66, 15, 6		@ G7
	N	64, 15, 6		@ F7
	N	61, 15, 6		@ D7
	N	57, 15, 6		@ A#6
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	65, 15, 6		@ F#7
	N	69, 15, 6		@ A#7
	N	71, 15, 6		@ C8
	N	74, 15, 6		@ D#8
	N	71, 15, 6		@ C8
	N	73, 15, 11		@ D8
	PAT_END

pat_08083C4D:				@ used by s2c5
	N	77, 15, 4		@ F#8
	N	76, 15, 4		@ F8
	N	77, 15, 6		@ F#8
	N	74, 15, 6		@ D#8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	74, 15, 6		@ D#8
	N	72, 15, 4		@ C#8
	N	71, 15, 4		@ C8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	69, 15, 6		@ A#7
	N	77, 15, 4		@ F#8
	N	76, 15, 4		@ F8
	N	77, 15, 6		@ F#8
	N	74, 15, 6		@ D#8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	74, 15, 6		@ D#8
	N	72, 15, 11		@ C#8
	N	72, 15, 4		@ C#8
	N	71, 15, 4		@ C8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	65, 15, 6		@ F#7
	N	69, 15, 6		@ A#7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	62, 15, 6		@ D#7
	N	60, 15, 6		@ C#7
	N	64, 15, 6		@ F7
	N	62, 15, 4		@ D#7
	N	65, 15, 4		@ F#7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	74, 15, 6		@ D#8
	N	72, 15, 6		@ C#8
	N	76, 15, 11		@ F8
	PAT_END

pat_08083CD2:				@ used by s2c5
	N	72, 15, 4		@ C#8
	N	71, 15, 4		@ C8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	69, 15, 6		@ A#7
	N	67, 15, 4		@ G#7
	N	66, 15, 4		@ G7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	62, 15, 6		@ D#7
	N	59, 15, 6		@ C7
	N	71, 15, 6		@ C8
	N	72, 15, 4		@ C#8
	N	71, 15, 4		@ C8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	69, 15, 6		@ A#7
	N	67, 15, 11		@ G#7
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	64, 15, 6		@ F7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	71, 15, 4		@ C8
	N	69, 15, 4		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	62, 15, 6		@ D#7
	N	64, 15, 6		@ F7
	N	67, 15, 6		@ G#7
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	65, 15, 6		@ F#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	74, 15, 6		@ D#8
	N	72, 15, 6		@ C#8
	N	71, 15, 11		@ C8
	PAT_END

pat_08083D57:				@ used by s2c5
	N	73, 15, 4		@ D8
	N	71, 15, 4		@ C8
	N	73, 15, 6		@ D8
	N	70, 15, 6		@ B7
	N	66, 15, 6		@ G7
	N	70, 15, 6		@ B7
	N	73, 15, 6		@ D8
	N	74, 15, 4		@ D#8
	N	73, 15, 4		@ D8
	N	74, 15, 6		@ D#8
	N	71, 15, 6		@ C8
	N	66, 15, 6		@ G7
	N	71, 15, 6		@ C8
	N	74, 15, 6		@ D#8
	N	76, 15, 4		@ F8
	N	74, 15, 4		@ D#8
	N	76, 15, 6		@ F8
	N	73, 15, 6		@ D8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	65, 15, 6		@ F#7
	N	69, 15, 6		@ A#7
	N	74, 15, 6		@ D#8
	N	73, 15, 4		@ D8
	N	71, 15, 4		@ C8
	N	73, 15, 6		@ D8
	N	74, 15, 11		@ D#8
	PAT_END

pat_08083DB2:				@ used by s2c6
	N	48, 2, 8		@ C#6
	N	48, 4, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	53, 10, 6		@ F#6
	N	48, 4, 6		@ C#6
	N	48, 2, 8		@ C#6
	N	48, 4, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	53, 10, 6		@ F#6
	N	48, 4, 6		@ C#6
	N	48, 2, 8		@ C#6
	N	48, 4, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	53, 10, 6		@ F#6
	N	48, 4, 6		@ C#6
	N	48, 2, 8		@ C#6
	N	48, 4, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	53, 10, 6		@ F#6
	N	48, 4, 4		@ C#6
	N	48, 4, 4		@ C#6
	PAT_END

pat_08083DF2:				@ used by s2c7
	N	31, 1, 4		@ G#4
	N	26, 1, 4		@ D#4
	N	31, 1, 6		@ G#4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	31, 1, 4		@ G#4
	N	26, 1, 4		@ D#4
	N	31, 1, 6		@ G#4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 6		@ A#4
	N	36, 1, 6		@ C#5
	N	39, 1, 6		@ E5
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	26, 1, 4		@ D#4
	N	31, 1, 6		@ G#4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	PAT_END

pat_08083E47:				@ used by s2c7
	N	36, 1, 6		@ C#5
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	39, 1, 6		@ E5
	N	38, 1, 6		@ D#5
	N	39, 1, 6		@ E5
	N	34, 1, 6		@ B4
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	38, 1, 6		@ D#5
	N	34, 1, 6		@ B4
	N	31, 1, 6		@ G#4
	N	38, 1, 6		@ D#5
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	45, 1, 6		@ A#5
	N	42, 1, 6		@ G5
	N	39, 1, 6		@ E5
	N	38, 1, 6		@ D#5
	N	31, 1, 6		@ G#4
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	38, 1, 6		@ D#5
	N	34, 1, 6		@ B4
	N	31, 1, 6		@ G#4
	N	36, 1, 6		@ C#5
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	39, 1, 6		@ E5
	N	38, 1, 6		@ D#5
	N	36, 1, 6		@ C#5
	N	34, 1, 6		@ B4
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	38, 1, 6		@ D#5
	N	34, 1, 6		@ B4
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	37, 1, 6		@ D5
	N	33, 1, 6		@ A#4
	N	38, 1, 6		@ D#5
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	45, 1, 6		@ A#5
	N	42, 1, 6		@ G5
	N	39, 1, 6		@ E5
	N	38, 1, 6		@ D#5
	PAT_END

pat_08083EF0:				@ used by s2c7
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	39, 1, 6		@ E5
	N	42, 1, 6		@ G5
	N	39, 1, 6		@ E5
	N	45, 1, 6		@ A#5
	N	42, 1, 6		@ G5
	N	40, 1, 4		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	39, 1, 6		@ E5
	N	42, 1, 6		@ G5
	N	45, 1, 6		@ A#5
	N	42, 1, 6		@ G5
	N	39, 1, 6		@ E5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 6		@ F5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	37, 1, 6		@ D5
	N	33, 1, 6		@ A#4
	N	38, 1, 4		@ D#5
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	33, 1, 6		@ A#4
	PAT_END

pat_08083F9C:				@ used by s2c7
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	33, 1, 4		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	33, 1, 6		@ A#4
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	40, 1, 6		@ F5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	41, 1, 4		@ F#5
	N	40, 1, 4		@ F5
	N	41, 1, 6		@ F#5
	N	36, 1, 6		@ C#5
	N	33, 1, 6		@ A#4
	N	29, 1, 6		@ F#4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	35, 1, 4		@ C5
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	38, 1, 7		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 6		@ A#4
	N	36, 1, 6		@ C#5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	N	32, 1, 6		@ A4
	N	35, 1, 6		@ C5
	N	40, 1, 6		@ F5
	PAT_END

pat_08084042:				@ used by s2c7
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 6		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	33, 1, 6		@ A#4
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 6		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	33, 1, 6		@ A#4
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	40, 1, 6		@ F5
	N	38, 1, 6		@ D#5
	N	35, 1, 6		@ C5
	N	36, 1, 4		@ C#5
	N	35, 1, 4		@ C5
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 6		@ G#4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	43, 1, 6		@ G#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	N	32, 1, 6		@ A4
	N	35, 1, 6		@ C5
	N	40, 1, 6		@ F5
	PAT_END

pat_080840EB:				@ used by s2c7
	N	42, 1, 4		@ G5
	N	41, 1, 4		@ F#5
	N	42, 1, 6		@ G5
	N	37, 1, 6		@ D5
	N	34, 1, 6		@ B4
	N	30, 1, 6		@ G4
	N	34, 1, 6		@ B4
	N	35, 1, 4		@ C5
	N	34, 1, 4		@ B4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	42, 1, 6		@ G5
	N	38, 1, 6		@ D#5
	N	35, 1, 6		@ C5
	N	33, 1, 4		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 6		@ A#4
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	37, 1, 6		@ D5
	N	33, 1, 6		@ A#4
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 6		@ A#4
	N	37, 1, 6		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	42, 1, 6		@ G5
	N	45, 1, 6		@ A#5
	N	42, 1, 6		@ G5
	N	38, 1, 6		@ D#5
	PAT_END

pat_08084158:				@ used by s2c7
	N	31, 1, 4		@ G#4
	N	26, 1, 4		@ D#4
	N	31, 1, 6		@ G#4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 6		@ A#4
	N	36, 1, 6		@ C#5
	N	39, 1, 6		@ E5
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	26, 1, 4		@ D#4
	N	31, 1, 6		@ G#4
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	PAT_END

pat_08084198:				@ used by s2c8
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	52, 10, 4		@ F6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	52, 10, 4		@ F6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	52, 10, 4		@ F6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	52, 10, 4		@ F6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	PAT_END

pat_08084229:				@ used by s2c1
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	36, 21, 4		@ C#5
	N	36, 21, 4		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	PAT_END

pat_0808427E:				@ used by s2c1
	N	48, 19, 4		@ C#6
	N	48, 19, 4		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	43, 20, 4		@ G#5
	N	43, 20, 4		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	43, 20, 4		@ G#5
	N	43, 20, 4		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	48, 19, 4		@ C#6
	N	48, 19, 4		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	48, 19, 6		@ C#6
	N	43, 20, 4		@ G#5
	N	43, 20, 4		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	43, 20, 6		@ G#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	PAT_END

pat_08084327:				@ used by s2c1
	N	47, 16, 4		@ C6
	N	47, 16, 4		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	40, 21, 4		@ F5
	N	40, 21, 4		@ F5
	N	40, 21, 6		@ F5
	N	40, 21, 6		@ F5
	N	40, 21, 6		@ F5
	N	40, 21, 6		@ F5
	N	40, 21, 6		@ F5
	N	47, 16, 4		@ C6
	N	47, 16, 4		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	47, 16, 6		@ C6
	N	40, 18, 4		@ F5
	N	40, 18, 4		@ F5
	N	40, 18, 6		@ F5
	N	40, 18, 6		@ F5
	N	40, 18, 6		@ F5
	N	40, 18, 6		@ F5
	N	40, 18, 6		@ F5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	38, 21, 4		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	PAT_END

pat_080843D0:				@ used by s2c1
	N	38, 21, 4		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	41, 17, 4		@ F#5
	N	41, 17, 4		@ F#5
	N	41, 17, 6		@ F#5
	N	41, 17, 6		@ F#5
	N	41, 17, 6		@ F#5
	N	41, 17, 6		@ F#5
	N	41, 17, 6		@ F#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	38, 21, 4		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084479:				@ used by s2c1
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	40, 20, 4		@ F5
	N	40, 20, 4		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	40, 20, 4		@ F5
	N	40, 20, 4		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	40, 20, 6		@ F5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 6		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	38, 20, 6		@ D#5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084522:				@ used by s2c1
	N	42, 16, 4		@ G5
	N	42, 16, 4		@ G5
	N	42, 16, 6		@ G5
	N	42, 16, 6		@ G5
	N	42, 16, 6		@ G5
	N	42, 16, 6		@ G5
	N	42, 16, 6		@ G5
	N	35, 21, 4		@ C5
	N	35, 21, 4		@ C5
	N	35, 21, 6		@ C5
	N	35, 21, 6		@ C5
	N	35, 21, 6		@ C5
	N	35, 21, 6		@ C5
	N	35, 21, 6		@ C5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	38, 21, 4		@ D#5
	N	38, 21, 4		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	38, 21, 6		@ D#5
	N	45, 16, 6		@ A#5
	N	45, 16, 6		@ A#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 6		@ D#5
	PAT_END

pat_0808458C:				@ used by s2c1
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	36, 21, 4		@ C#5
	N	36, 21, 4		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 21, 6		@ C#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 6		@ G#5
	PAT_END

pat_080845CC:				@ used by s2c4
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	PAT_END

pat_08084669:				@ used by s3c5
	REST	0, 6
	N	60, 15, 6		@ C#7
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 8		@ G#7
	N	63, 15, 8		@ E7
	REST	0, 6
	N	60, 15, 6		@ C#7
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	63, 15, 8		@ E7
	N	62, 15, 8		@ D#7
	PAT_END

pat_0808468E:				@ used by s3c5
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	63, 15, 4		@ E7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	63, 15, 4		@ E7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	76, 15, 4		@ F8
	N	74, 15, 4		@ D#8
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	64, 15, 4		@ F7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	76, 15, 4		@ F8
	N	74, 15, 4		@ D#8
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	64, 15, 4		@ F7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	76, 15, 4		@ F8
	N	74, 15, 4		@ D#8
	N	72, 15, 4		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	64, 15, 4		@ F7
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	60, 15, 6		@ C#7
	N	57, 15, 6		@ A#6
	N	55, 15, 8		@ G#6
	PAT_END

pat_08084740:				@ used by s3c5
	N	72, 15, 4		@ C#8
	N	71, 15, 4		@ C8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 4		@ F7
	N	62, 15, 4		@ D#7
	N	64, 15, 6		@ F7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 4		@ C#8
	N	71, 15, 4		@ C8
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 10		@ F7
	N	62, 15, 4		@ D#7
	N	60, 15, 4		@ C#7
	N	62, 15, 6		@ D#7
	N	64, 15, 6		@ F7
	N	67, 15, 6		@ G#7
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	64, 15, 6		@ F7
	N	60, 15, 6		@ C#7
	N	62, 15, 10		@ D#7
	PAT_END

pat_080847A1:				@ used by s3c5
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	76, 15, 6		@ F8
	N	74, 15, 4		@ D#8
	N	71, 15, 4		@ C8
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	N	64, 15, 6		@ F7
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	69, 15, 6		@ A#7
	N	72, 15, 6		@ C#8
	N	71, 15, 2		@ C8
	N	69, 15, 2		@ A#7
	N	67, 15, 4		@ G#7
	N	64, 15, 10		@ F7
	N	62, 15, 4		@ D#7
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	64, 15, 4		@ F7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 4		@ C#8
	N	74, 15, 4		@ D#8
	N	72, 15, 2		@ C#8
	N	71, 15, 2		@ C8
	N	69, 15, 4		@ A#7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	64, 15, 8		@ F7
	N	57, 15, 4		@ A#6
	N	60, 15, 4		@ C#7
	N	62, 15, 4		@ D#7
	N	65, 15, 4		@ F#7
	N	67, 15, 4		@ G#7
	N	69, 15, 4		@ A#7
	N	72, 15, 2		@ C#8
	N	69, 15, 2		@ A#7
	N	67, 15, 2		@ G#7
	N	64, 15, 2		@ F7
	N	62, 15, 10		@ D#7
	PAT_END

pat_08084823:				@ used by s3c6
	N	60, 14, 8		@ C#7
	N	62, 14, 8		@ D#7
	N	63, 14, 8		@ E7
	N	67, 14, 8		@ G#7
	N	69, 14, 8		@ A#7
	N	67, 14, 8		@ G#7
	N	63, 14, 10		@ E7
	N	69, 14, 8		@ A#7
	N	72, 14, 6		@ C#8
	N	69, 14, 6		@ A#7
	N	67, 14, 8		@ G#7
	N	64, 14, 8		@ F7
	N	67, 14, 8		@ G#7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	64, 14, 8		@ F7
	N	67, 14, 8		@ G#7
	PAT_END

pat_08084857:				@ used by s3c6
	N	64, 14, 4		@ F7
	N	62, 14, 4		@ D#7
	N	64, 14, 6		@ F7
	N	60, 14, 6		@ C#7
	N	57, 14, 6		@ A#6
	N	62, 14, 4		@ D#7
	N	60, 14, 4		@ C#7
	N	62, 14, 6		@ D#7
	N	59, 14, 6		@ C7
	N	55, 14, 6		@ G#6
	N	64, 14, 4		@ F7
	N	62, 14, 4		@ D#7
	N	64, 14, 6		@ F7
	N	60, 14, 6		@ C#7
	N	57, 14, 6		@ A#6
	N	59, 14, 10		@ C7
	N	57, 14, 4		@ A#6
	N	55, 14, 4		@ G#6
	N	57, 14, 6		@ A#6
	N	60, 14, 6		@ C#7
	N	62, 14, 6		@ D#7
	N	60, 14, 4		@ C#7
	N	59, 14, 4		@ C7
	N	60, 14, 6		@ C#7
	N	57, 14, 6		@ A#6
	N	60, 14, 6		@ C#7
	N	69, 14, 6		@ A#7
	N	67, 14, 4		@ G#7
	N	64, 14, 4		@ F7
	N	62, 14, 6		@ D#7
	N	64, 14, 6		@ F7
	N	59, 14, 10		@ C7
	PAT_END

pat_080848B8:				@ used by s3c6
	N	52, 14, 8		@ F6
	N	57, 14, 8		@ A#6
	N	55, 14, 8		@ G#6
	N	59, 14, 8		@ C7
	N	60, 14, 8		@ C#7
	N	57, 14, 8		@ A#6
	N	59, 14, 8		@ C7
	N	55, 14, 8		@ G#6
	N	53, 14, 6		@ F#6
	N	55, 14, 4		@ G#6
	N	57, 14, 4		@ A#6
	N	62, 14, 6		@ D#7
	N	59, 14, 6		@ C7
	N	60, 14, 8		@ C#7
	N	57, 14, 8		@ A#6
	N	62, 14, 8		@ D#7
	N	60, 14, 6		@ C#7
	N	57, 14, 6		@ A#6
	N	55, 14, 10		@ G#6
	PAT_END

pat_080848F2:				@ used by s3c7
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	PAT_END

pat_0808493B:				@ used by s3c7
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	45, 1, 4		@ A#5
	REST	0, 6
	N	43, 1, 6		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	41, 1, 4		@ F#5
	REST	0, 6
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	29, 1, 4		@ F#4
	N	43, 1, 4		@ G#5
	REST	0, 6
	N	38, 1, 6		@ D#5
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	REST	0, 6
	N	33, 1, 6		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	PAT_END

pat_080849CC:				@ used by s3c7
	N	33, 1, 4		@ A#4
	REST	0, 6
	N	43, 1, 6		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	40, 1, 4		@ F5
	REST	0, 6
	N	38, 1, 6		@ D#5
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	REST	0, 6
	N	43, 1, 6		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	40, 1, 4		@ F5
	REST	0, 6
	N	38, 1, 6		@ D#5
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	REST	0, 6
	N	36, 1, 6		@ C#5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 6
	N	43, 1, 6		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 4		@ F#5
	REST	0, 6
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	31, 1, 4		@ G#4
	REST	0, 6
	N	38, 1, 6		@ D#5
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	PAT_END

pat_08084A5D:				@ used by s3c8
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	53, 10, 4		@ F#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	53, 10, 4		@ F#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	53, 10, 4		@ F#6
	N	48, 6, 4		@ C#6
	PAT_END

pat_08084ABE:				@ used by s3c8
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	53, 10, 4		@ F#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	53, 10, 4		@ F#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	53, 10, 4		@ F#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	53, 10, 4		@ F#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	53, 10, 4		@ F#6
	N	48, 5, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	53, 10, 4		@ F#6
	N	48, 9, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	53, 10, 4		@ F#6
	N	48, 6, 4		@ C#6
	PAT_END

pat_08084B7F:				@ used by s3c1
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 21, 4		@ C#5
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 21, 4		@ C#5
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	N	36, 21, 6		@ C#5
	PAT_END

pat_08084BD4:				@ used by s3c1
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 21, 4		@ C#5
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	N	36, 21, 6		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 21, 4		@ C#5
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	REST	0, 4
	N	36, 21, 4		@ C#5
	N	36, 21, 6		@ C#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	41, 17, 4		@ F#5
	N	41, 17, 4		@ F#5
	REST	0, 4
	N	41, 17, 4		@ F#5
	REST	0, 4
	N	41, 17, 4		@ F#5
	N	41, 17, 6		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	REST	0, 4
	N	43, 17, 4		@ G#5
	REST	0, 4
	N	43, 17, 4		@ G#5
	N	43, 17, 6		@ G#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	REST	0, 4
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	PAT_END

pat_08084C7D:				@ used by s3c1
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	40, 20, 4		@ F5
	N	40, 20, 4		@ F5
	REST	0, 4
	N	40, 20, 4		@ F5
	REST	0, 4
	N	40, 20, 4		@ F5
	N	40, 20, 6		@ F5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	40, 20, 4		@ F5
	N	40, 20, 4		@ F5
	REST	0, 4
	N	40, 20, 4		@ F5
	REST	0, 4
	N	40, 20, 4		@ F5
	N	40, 20, 6		@ F5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	REST	0, 4
	N	38, 20, 4		@ D#5
	REST	0, 4
	N	38, 20, 4		@ D#5
	N	38, 20, 6		@ D#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	REST	0, 4
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	41, 17, 4		@ F#5
	N	41, 17, 4		@ F#5
	REST	0, 4
	N	41, 17, 4		@ F#5
	REST	0, 4
	N	41, 17, 4		@ F#5
	N	41, 17, 6		@ F#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	REST	0, 4
	N	43, 17, 4		@ G#5
	REST	0, 4
	N	43, 17, 4		@ G#5
	N	43, 17, 6		@ G#5
	PAT_END

pat_08084D26:				@ used by s3c4
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	PAT_END

pat_08084D93:				@ used by s4c1
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	PAT_END

pat_08084E24:				@ used by s4c1
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084E37:				@ used by s4c1
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	PAT_END

pat_08084E4A:				@ used by s4c1
	N	41, 19, 6		@ F#5
	N	41, 19, 4		@ F#5
	N	41, 19, 4		@ F#5
	N	41, 19, 4		@ F#5
	N	41, 19, 4		@ F#5
	N	41, 19, 6		@ F#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	PAT_END

pat_08084E6F:				@ used by s4c1
	N	38, 20, 6		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 6		@ D#5
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084E94:				@ used by s4c1
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	45, 16, 6		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	PAT_END

pat_08084EB9:				@ used by s4c1
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 6		@ A#5
	PAT_END

pat_08084EDE:				@ used by s4c1
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	41, 16, 4		@ F#5
	N	41, 16, 4		@ F#5
	N	40, 16, 6		@ F5
	N	38, 20, 6		@ D#5
	N	38, 20, 4		@ D#5
	N	38, 20, 4		@ D#5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084F03:				@ used by s4c1
	N	41, 17, 6		@ F#5
	N	41, 17, 4		@ F#5
	N	41, 17, 4		@ F#5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084F16:				@ used by s4c1
	N	40, 17, 6		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 6		@ F5
	PAT_END

pat_08084F29:				@ used by s4c4
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
	N	42, 3, 4		@ G5
	PAT_END

pat_08084F5A:				@ used by s4c5
	N	76, 16, 8		@ F8
	N	75, 16, 6		@ E8
	N	72, 16, 6		@ C#8
	N	69, 16, 9		@ A#7
	N	71, 16, 6		@ C8
	N	72, 16, 6		@ C#8
	N	75, 16, 6		@ E8
	N	76, 16, 6		@ F8
	N	69, 16, 6		@ A#7
	N	71, 16, 10		@ C8
	N	64, 16, 8		@ F7
	N	65, 16, 6		@ F#7
	N	68, 16, 6		@ A7
	N	71, 16, 9		@ C8
	N	72, 16, 6		@ C#8
	N	74, 16, 8		@ D#8
	N	72, 16, 6		@ C#8
	N	68, 16, 6		@ A7
	N	69, 16, 10		@ A#7
	PAT_END

pat_08084F94:				@ used by s4c5
	N	64, 16, 5		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 6		@ D#8
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	79, 16, 2		@ G#8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 8		@ F8
	N	64, 16, 5		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 6		@ D#8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	68, 16, 8		@ A7
	N	64, 16, 5		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 6		@ D#8
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	79, 16, 2		@ G#8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	76, 16, 6		@ F8
	N	64, 16, 5		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 6		@ D#8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	72, 16, 4		@ C#8
	N	68, 16, 4		@ A7
	N	69, 16, 8		@ A#7
	PAT_END

pat_08085049:				@ used by s4c5
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	72, 16, 2		@ C#8
	N	75, 16, 6		@ E8
	N	74, 16, 6		@ D#8
	N	72, 16, 6		@ C#8
	N	69, 16, 2		@ A#7
	N	71, 16, 2		@ C8
	N	69, 16, 2		@ A#7
	N	67, 16, 2		@ G#7
	N	69, 16, 8		@ A#7
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	72, 16, 2		@ C#8
	N	75, 16, 6		@ E8
	N	74, 16, 6		@ D#8
	N	72, 16, 6		@ C#8
	N	69, 16, 6		@ A#7
	N	71, 16, 2		@ C8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	69, 16, 2		@ A#7
	N	68, 16, 4		@ A7
	N	65, 16, 4		@ F#7
	N	64, 16, 8		@ F7
	N	64, 16, 5		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 4		@ D#8
	N	76, 16, 4		@ F8
	N	77, 16, 7		@ F#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	76, 16, 8		@ F8
	N	80, 16, 5		@ A8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 4		@ F8
	N	77, 16, 4		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	69, 16, 9		@ A#7
	PAT_END
pat_080850E6:				@ not referenced by any sequence
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	72, 16, 2		@ C#8
	N	75, 16, 6		@ E8
	N	74, 16, 6		@ D#8
	N	72, 16, 6		@ C#8
	N	69, 16, 2		@ A#7
	N	71, 16, 2		@ C8
	N	69, 16, 2		@ A#7
	N	67, 16, 2		@ G#7
	N	69, 16, 8		@ A#7
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	72, 16, 2		@ C#8
	N	75, 16, 6		@ E8
	N	74, 16, 6		@ D#8
	N	72, 16, 6		@ C#8
	N	69, 16, 6		@ A#7
	N	64, 16, 2		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 2		@ A7
	N	69, 16, 2		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 8		@ D#8
	N	74, 16, 5		@ D#8
	N	76, 16, 2		@ F8
	N	77, 16, 4		@ F#8
	N	80, 16, 4		@ A8
	N	77, 16, 6		@ F#8
	N	76, 16, 6		@ F8
	N	80, 16, 5		@ A8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	76, 16, 6		@ F8
	N	76, 16, 5		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	72, 16, 4		@ C#8
	N	68, 16, 4		@ A7
	N	69, 16, 10		@ A#7
	PAT_END

pat_08085180:				@ used by s4c5
	N	65, 13, 5		@ F#7
	N	67, 13, 2		@ G#7
	N	68, 13, 4		@ A7
	N	71, 13, 4		@ C8
	N	72, 13, 6		@ C#8
	N	74, 13, 6		@ D#8
	N	76, 13, 2		@ F8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 9		@ F8
	N	80, 13, 5		@ A8
	N	79, 13, 2		@ G#8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	N	77, 13, 6		@ F#8
	N	72, 13, 6		@ C#8
	N	76, 13, 10		@ F8
	N	65, 13, 5		@ F#7
	N	67, 13, 2		@ G#7
	N	68, 13, 4		@ A7
	N	71, 13, 4		@ C8
	N	72, 13, 6		@ C#8
	N	74, 13, 6		@ D#8
	N	76, 13, 2		@ F8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 9		@ F8
	N	77, 13, 5		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	71, 13, 4		@ C8
	N	69, 13, 4		@ A#7
	N	71, 13, 2		@ C8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	68, 13, 4		@ A7
	N	65, 13, 4		@ F#7
	N	64, 13, 8		@ F7
	PAT_END

pat_08085205:				@ used by s4c5
	N	74, 16, 9		@ D#8
	N	74, 16, 2		@ D#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	71, 16, 2		@ C8
	N	73, 16, 9		@ D8
	N	73, 16, 2		@ D8
	N	74, 16, 2		@ D#8
	N	73, 16, 2		@ D8
	N	69, 16, 2		@ A#7
	N	71, 16, 9		@ C8
	N	71, 16, 2		@ C8
	N	73, 16, 2		@ D8
	N	71, 16, 2		@ C8
	N	68, 16, 2		@ A7
	N	69, 16, 9		@ A#7
	N	76, 16, 2		@ F8
	N	78, 16, 2		@ G8
	N	76, 16, 2		@ F8
	N	73, 16, 2		@ D8
	N	74, 16, 9		@ D#8
	N	74, 16, 2		@ D#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	71, 16, 2		@ C8
	N	72, 16, 9		@ C#8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	69, 16, 2		@ A#7
	N	71, 16, 8		@ C8
	N	69, 16, 6		@ A#7
	N	67, 16, 6		@ G#7
	N	65, 16, 7		@ F#7
	N	67, 16, 2		@ G#7
	N	65, 16, 2		@ F#7
	N	64, 16, 8		@ F7
	PAT_END

pat_08085275:				@ used by s4c5
	N	65, 16, 7		@ F#7
	N	67, 16, 2		@ G#7
	N	65, 16, 2		@ F#7
	N	64, 16, 8		@ F7
	N	65, 16, 7		@ F#7
	N	67, 16, 2		@ G#7
	N	65, 16, 2		@ F#7
	N	64, 16, 8		@ F7
	N	64, 16, 5		@ F7
	N	65, 16, 2		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 4		@ C8
	N	72, 16, 4		@ C#8
	N	74, 16, 6		@ D#8
	N	77, 16, 2		@ F#8
	N	79, 16, 2		@ G#8
	N	80, 16, 2		@ A8
	N	79, 16, 2		@ G#8
	N	77, 16, 4		@ F#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	76, 16, 8		@ F8
	PAT_END

pat_080852BB:				@ used by s4c6
	N	72, 16, 8		@ C#8
	N	71, 16, 6		@ C8
	N	69, 16, 6		@ A#7
	N	64, 16, 9		@ F7
	N	68, 16, 6		@ A7
	N	69, 16, 6		@ A#7
	N	71, 16, 6		@ C8
	N	72, 16, 6		@ C#8
	N	64, 16, 6		@ F7
	N	68, 16, 10		@ A7
	N	59, 16, 8		@ C7
	N	62, 16, 6		@ D#7
	N	64, 16, 6		@ F7
	N	68, 16, 9		@ A7
	N	69, 16, 6		@ A#7
	N	71, 16, 8		@ C8
	N	68, 16, 6		@ A7
	N	64, 16, 6		@ F7
	N	60, 16, 10		@ C#7
	PAT_END

pat_080852F5:				@ used by s4c6
	N	72, 16, 8		@ C#8
	N	71, 16, 6		@ C8
	N	69, 16, 6		@ A#7
	N	64, 16, 4		@ F7
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	72, 16, 4		@ C#8
	N	75, 16, 6		@ E8
	N	74, 16, 6		@ D#8
	N	69, 16, 6		@ A#7
	N	71, 16, 6		@ C8
	N	72, 16, 6		@ C#8
	N	64, 16, 6		@ F7
	N	68, 16, 4		@ A7
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 8		@ F8
	N	59, 16, 4		@ C7
	N	80, 16, 2		@ A8
	N	81, 16, 2		@ A#8
	N	80, 16, 4		@ A8
	N	77, 16, 4		@ F#8
	N	76, 16, 6		@ F8
	N	64, 16, 6		@ F7
	N	68, 16, 4		@ A7
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 4		@ F8
	N	74, 16, 4		@ D#8
	N	76, 16, 6		@ F8
	N	69, 16, 6		@ A#7
	N	71, 16, 4		@ C8
	N	80, 16, 2		@ A8
	N	81, 16, 2		@ A#8
	N	80, 16, 4		@ A8
	N	77, 16, 4		@ F#8
	N	76, 16, 6		@ F8
	N	64, 16, 6		@ F7
	N	60, 16, 6		@ C#7
	N	76, 16, 2		@ F8
	N	77, 16, 2		@ F#8
	N	76, 16, 2		@ F8
	N	75, 16, 2		@ E8
	N	72, 16, 8		@ C#8
	PAT_END

pat_08085383:				@ used by s4c6
	N	59, 16, 5		@ C7
	N	62, 16, 2		@ D#7
	N	64, 16, 4		@ F7
	N	64, 16, 4		@ F7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 6		@ C8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	72, 16, 4		@ C#8
	N	71, 16, 4		@ C8
	N	68, 16, 8		@ A7
	N	59, 16, 5		@ C7
	N	62, 16, 2		@ D#7
	N	64, 16, 4		@ F7
	N	65, 16, 4		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 6		@ C8
	N	69, 16, 2		@ A#7
	N	71, 16, 2		@ C8
	N	69, 16, 2		@ A#7
	N	68, 16, 2		@ A7
	N	65, 16, 4		@ F#7
	N	68, 16, 4		@ A7
	N	64, 16, 8		@ F7
	N	59, 16, 5		@ C7
	N	62, 16, 2		@ D#7
	N	64, 16, 4		@ F7
	N	65, 16, 4		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 6		@ C8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	76, 16, 2		@ F8
	N	74, 16, 2		@ D#8
	N	72, 16, 4		@ C#8
	N	71, 16, 4		@ C8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	68, 16, 6		@ A7
	N	59, 16, 5		@ C7
	N	62, 16, 2		@ D#7
	N	64, 16, 4		@ F7
	N	65, 16, 4		@ F#7
	N	68, 16, 4		@ A7
	N	69, 16, 4		@ A#7
	N	71, 16, 6		@ C8
	N	69, 16, 2		@ A#7
	N	71, 16, 2		@ C8
	N	69, 16, 2		@ A#7
	N	68, 16, 2		@ A7
	N	69, 16, 4		@ A#7
	N	64, 16, 4		@ F7
	N	60, 16, 8		@ C#7
	PAT_END

pat_08085438:				@ used by s4c6
	N	81, 13, 6		@ A#8
	N	69, 13, 6		@ A#7
	N	71, 13, 6		@ C8
	N	76, 13, 6		@ F8
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	72, 13, 7		@ C#8
	N	71, 13, 4		@ C8
	N	69, 13, 4		@ A#7
	N	67, 13, 4		@ G#7
	N	69, 13, 2		@ A#7
	N	72, 13, 2		@ C#8
	N	69, 13, 2		@ A#7
	N	67, 13, 2		@ G#7
	N	64, 13, 4		@ F7
	N	67, 13, 4		@ G#7
	N	69, 13, 4		@ A#7
	N	72, 13, 4		@ C#8
	N	76, 13, 6		@ F8
	N	77, 13, 7		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	71, 13, 4		@ C8
	N	71, 13, 7		@ C8
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	77, 13, 7		@ F#8
	N	79, 13, 4		@ G#8
	N	80, 13, 6		@ A8
	N	83, 13, 4		@ C9
	N	80, 13, 2		@ A8
	N	77, 13, 2		@ F#8
	N	76, 13, 7		@ F8
	N	77, 13, 4		@ F#8
	N	76, 13, 2		@ F8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 7		@ F8
	N	77, 13, 4		@ F#8
	N	80, 13, 4		@ A8
	N	77, 13, 4		@ F#8
	N	76, 13, 2		@ F8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 9		@ F8
	N	81, 13, 5		@ A#8
	N	79, 13, 2		@ G#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	74, 13, 4		@ D#8
	N	75, 13, 4		@ E8
	N	76, 13, 4		@ F8
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	69, 13, 8		@ A#7
	N	69, 13, 4		@ A#7
	N	71, 13, 4		@ C8
	N	72, 13, 5		@ C#8
	N	74, 13, 2		@ D#8
	N	76, 13, 4		@ F8
	N	79, 13, 4		@ G#8
	N	81, 13, 6		@ A#8
	N	79, 13, 4		@ G#8
	N	76, 13, 4		@ F8
	N	77, 13, 2		@ F#8
	N	79, 13, 2		@ G#8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	77, 13, 8		@ F#8
	N	76, 13, 6		@ F8
	N	80, 13, 5		@ A8
	N	77, 13, 2		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	76, 13, 4		@ F8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 2		@ C#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	71, 13, 2		@ C8
	N	72, 13, 4		@ C#8
	N	71, 13, 4		@ C8
	N	69, 13, 4		@ A#7
	N	68, 13, 4		@ A7
	N	65, 13, 4		@ F#7
	N	68, 13, 4		@ A7
	N	64, 13, 7		@ F7
	N	65, 13, 2		@ F#7
	N	68, 13, 2		@ A7
	N	69, 13, 4		@ A#7
	N	71, 13, 4		@ C8
	N	72, 13, 4		@ C#8
	N	71, 13, 4		@ C8
	N	64, 13, 10		@ F7
	PAT_END

pat_08085577:				@ used by s4c6
	N	60, 16, 5		@ C#7
	N	64, 16, 2		@ F7
	N	65, 16, 4		@ F#7
	N	67, 16, 4		@ G#7
	N	68, 16, 6		@ A7
	N	71, 16, 6		@ C8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	72, 16, 9		@ C#8
	N	77, 16, 5		@ F#8
	N	76, 16, 2		@ F8
	N	74, 16, 4		@ D#8
	N	72, 16, 4		@ C#8
	N	74, 16, 6		@ D#8
	N	68, 16, 6		@ A7
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	72, 16, 6		@ C#8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	72, 16, 6		@ C#8
	N	60, 16, 5		@ C#7
	N	64, 16, 2		@ F7
	N	65, 16, 4		@ F#7
	N	67, 16, 4		@ G#7
	N	68, 16, 6		@ A7
	N	71, 16, 6		@ C8
	N	72, 16, 2		@ C#8
	N	74, 16, 2		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 2		@ C8
	N	72, 16, 9		@ C#8
	N	74, 16, 5		@ D#8
	N	72, 16, 2		@ C#8
	N	71, 16, 4		@ C8
	N	69, 16, 4		@ A#7
	N	67, 16, 6		@ G#7
	N	65, 16, 6		@ F#7
	N	64, 16, 2		@ F7
	N	65, 16, 2		@ F#7
	N	64, 16, 2		@ F7
	N	62, 16, 2		@ D#7
	N	64, 16, 6		@ F7
	N	64, 16, 2		@ F7
	N	65, 16, 2		@ F#7
	N	64, 16, 2		@ F7
	N	62, 16, 2		@ D#7
	N	76, 16, 2		@ F8
	N	78, 16, 2		@ G8
	N	76, 16, 2		@ F8
	N	73, 16, 2		@ D8
	PAT_END

pat_08085623:				@ used by s4c6
	N	64, 13, 6		@ F7
	N	71, 13, 2		@ C8
	N	73, 13, 2		@ D8
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	71, 13, 6		@ C8
	N	68, 13, 6		@ A7
	N	64, 13, 6		@ F7
	N	69, 13, 2		@ A#7
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	68, 13, 2		@ A7
	N	69, 13, 6		@ A#7
	N	64, 13, 6		@ F7
	N	64, 13, 6		@ F7
	N	68, 13, 2		@ A7
	N	69, 13, 2		@ A#7
	N	68, 13, 2		@ A7
	N	66, 13, 2		@ G7
	N	68, 13, 6		@ A7
	N	64, 13, 6		@ F7
	N	64, 13, 4		@ F7
	N	69, 13, 2		@ A#7
	N	71, 13, 2		@ C8
	N	73, 13, 4		@ D8
	N	74, 13, 4		@ D#8
	N	76, 13, 2		@ F8
	N	78, 13, 2		@ G8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 6		@ F8
	N	64, 13, 6		@ F7
	N	71, 13, 2		@ C8
	N	73, 13, 2		@ D8
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	71, 13, 6		@ C8
	N	64, 13, 6		@ F7
	N	69, 13, 6		@ A#7
	N	76, 13, 2		@ F8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	76, 13, 8		@ F8
	N	74, 13, 8		@ D#8
	N	72, 13, 6		@ C#8
	N	71, 13, 6		@ C8
	N	69, 13, 7		@ A#7
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	68, 13, 8		@ A7
	PAT_END

pat_080856BD:				@ used by s4c6
	N	69, 13, 7		@ A#7
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	68, 13, 8		@ A7
	N	69, 13, 7		@ A#7
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	68, 13, 8		@ A7
	N	68, 13, 5		@ A7
	N	69, 13, 2		@ A#7
	N	71, 13, 4		@ C8
	N	72, 13, 4		@ C#8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	71, 13, 4		@ C8
	N	69, 13, 4		@ A#7
	N	65, 13, 6		@ F#7
	N	68, 13, 2		@ A7
	N	69, 13, 2		@ A#7
	N	68, 13, 2		@ A7
	N	65, 13, 2		@ F#7
	N	64, 13, 8		@ F7
	PAT_END

pat_08085700:				@ used by s4c7
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	39, 1, 4		@ E5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	44, 1, 4		@ A5
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	44, 1, 4		@ A5
	N	35, 1, 6		@ C5
	N	38, 1, 6		@ D#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	PAT_END

pat_0808578B:				@ used by s4c7
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 2		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 2		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	44, 1, 4		@ A5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 2		@ F#5
	N	44, 1, 2		@ A5
	N	41, 1, 4		@ F#5
	N	40, 1, 4		@ F5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 2		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 2		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	44, 1, 4		@ A5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	32, 1, 4		@ A4
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 4		@ C#5
	N	35, 1, 4		@ C5
	PAT_END

pat_08085837:				@ used by s4c7
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	39, 1, 4		@ E5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 6		@ F5
	N	44, 1, 4		@ A5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 6		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 6		@ F5
	N	44, 1, 4		@ A5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	PAT_END

pat_080858BC:				@ used by s4c7
	N	29, 1, 6		@ F#4
	N	41, 1, 4		@ F#5
	N	39, 1, 4		@ E5
	N	36, 1, 4		@ C#5
	N	34, 1, 4		@ B4
	N	32, 1, 6		@ A4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	39, 1, 4		@ E5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	29, 1, 6		@ F#4
	N	41, 1, 4		@ F#5
	N	39, 1, 4		@ E5
	N	36, 1, 4		@ C#5
	N	34, 1, 4		@ B4
	N	32, 1, 6		@ A4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	39, 1, 4		@ E5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	29, 1, 6		@ F#4
	N	41, 1, 4		@ F#5
	N	39, 1, 4		@ E5
	N	36, 1, 4		@ C#5
	N	34, 1, 4		@ B4
	N	32, 1, 6		@ A4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	39, 1, 4		@ E5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	44, 1, 4		@ A5
	N	40, 1, 6		@ F5
	PAT_END

pat_0808594A:				@ used by s4c7
	N	40, 1, 6		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	44, 1, 6		@ A5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 6		@ F5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	39, 1, 4		@ E5
	N	36, 1, 6		@ C#5
	N	43, 1, 6		@ G#5
	N	43, 1, 4		@ G#5
	N	43, 1, 4		@ G#5
	N	41, 1, 6		@ F#5
	N	40, 1, 6		@ F5
	N	38, 1, 6		@ D#5
	N	41, 1, 4		@ F#5
	N	45, 1, 4		@ A#5
	N	40, 1, 6		@ F5
	N	35, 1, 6		@ C5
	PAT_END

pat_080859CC:				@ used by s4c7
	N	41, 1, 7		@ F#5
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	41, 1, 7		@ F#5
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	40, 1, 6		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	40, 1, 7		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	N	44, 1, 7		@ A5
	N	35, 1, 4		@ C5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	PAT_END

pat_08085A09:				@ used by s4c8
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	52, 10, 4		@ F6
	N	48, 6, 4		@ C#6
	PAT_END

pat_08085A85:				@ used by s5c1
	REST	0, 4
	N	69, 29, 4		@ A#7
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	74, 29, 7		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 4		@ F#8
	N	81, 29, 4		@ A#8
	N	80, 29, 8		@ A8
	N	77, 29, 6		@ F#8
	N	74, 29, 6		@ D#8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	69, 29, 7		@ A#7
	N	72, 29, 4		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	70, 29, 7		@ B7
	N	72, 29, 4		@ C#8
	N	74, 29, 6		@ D#8
	N	72, 29, 4		@ C#8
	N	70, 29, 4		@ B7
	N	69, 29, 4		@ A#7
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	81, 29, 7		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	80, 29, 9		@ A8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 6		@ G#8
	N	76, 29, 6		@ F8
	N	73, 29, 6		@ D8
	N	69, 29, 4		@ A#7
	N	71, 29, 2		@ C8
	N	73, 29, 2		@ D8
	N	74, 29, 10		@ D#8
	PAT_END

pat_08085B04:				@ used by s5c1
	N	69, 29, 24		@ A#7
	N	74, 29, 2		@ D#8
	N	77, 29, 2		@ F#8
	N	74, 29, 2		@ D#8
	N	81, 29, 24		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	77, 29, 2		@ F#8
	N	80, 29, 9		@ A8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 6		@ A#8
	N	74, 29, 7		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 4		@ F#8
	N	74, 29, 4		@ D#8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 7		@ F8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	69, 29, 4		@ A#7
	N	74, 29, 2		@ D#8
	N	77, 29, 2		@ F#8
	N	81, 29, 21		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	77, 29, 2		@ F#8
	N	80, 29, 19		@ A8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 24		@ F8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	73, 29, 4		@ D8
	N	69, 29, 4		@ A#7
	N	74, 29, 10		@ D#8
	PAT_END

pat_08085B8C:				@ used by s5c1
	N	70, 29, 4		@ B7
	N	73, 29, 2		@ D8
	N	77, 29, 2		@ F#8
	N	79, 29, 7		@ G#8
	N	77, 29, 4		@ F#8
	N	82, 29, 4		@ B8
	N	79, 29, 4		@ G#8
	N	81, 29, 21		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 6		@ A#8
	N	70, 29, 4		@ B7
	N	73, 29, 2		@ D8
	N	77, 29, 2		@ F#8
	N	79, 29, 7		@ G#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	84, 29, 4		@ C#9
	N	81, 29, 10		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	76, 29, 4		@ F8
	N	76, 29, 5		@ F8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	76, 29, 4		@ F8
	N	76, 29, 4		@ F8
	N	81, 29, 4		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	74, 29, 4		@ D#8
	N	74, 29, 5		@ D#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	74, 29, 4		@ D#8
	N	74, 29, 4		@ D#8
	N	79, 29, 4		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	73, 29, 4		@ D8
	N	73, 29, 5		@ D8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	73, 29, 4		@ D8
	N	73, 29, 4		@ D8
	N	74, 29, 24		@ D#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	74, 29, 8		@ D#8
	PAT_END

pat_08085C32:				@ used by s5c1
	N	86, 29, 2		@ D#9
	N	84, 29, 2		@ C#9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	84, 29, 4		@ C#9
	N	86, 29, 6		@ D#9
	N	84, 29, 4		@ C#9
	N	81, 29, 4		@ A#8
	N	84, 29, 2		@ C#9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	76, 29, 2		@ F8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	81, 29, 4		@ A#8
	N	84, 29, 4		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 2		@ C#9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	84, 29, 4		@ C#9
	N	86, 29, 6		@ D#9
	N	84, 29, 4		@ C#9
	N	81, 29, 4		@ A#8
	N	77, 29, 24		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 8		@ A#8
	N	86, 29, 2		@ D#9
	N	84, 29, 2		@ C#9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	84, 29, 4		@ C#9
	N	86, 29, 6		@ D#9
	N	84, 29, 4		@ C#9
	N	81, 29, 4		@ A#8
	N	84, 29, 2		@ C#9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 7		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 7		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	79, 29, 24		@ G#8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	79, 29, 2		@ G#8
	N	81, 29, 24		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 8		@ A#8
	PAT_END

pat_08085CF0:				@ used by s5c1
	N	74, 29, 4		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	81, 29, 7		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	77, 29, 4		@ F#8
	N	72, 29, 4		@ C#8
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	79, 29, 7		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	77, 29, 2		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 7		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	77, 29, 4		@ F#8
	N	84, 29, 24		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 2		@ C#9
	N	82, 29, 2		@ B8
	N	84, 29, 8		@ C#9
	N	74, 29, 4		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	81, 29, 7		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	72, 29, 7		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 2		@ F#8
	N	82, 29, 2		@ B8
	N	86, 29, 7		@ D#9
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	79, 29, 4		@ G#8
	N	81, 29, 10		@ A#8
	PAT_END

pat_08085D81:				@ used by s5c1
	N	69, 29, 4		@ A#7
	N	74, 29, 2		@ D#8
	N	77, 29, 2		@ F#8
	N	81, 29, 7		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	77, 29, 4		@ F#8
	N	80, 29, 9		@ A8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 6		@ A#8
	N	74, 29, 7		@ D#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	73, 29, 10		@ D8
	N	69, 29, 4		@ A#7
	N	74, 29, 2		@ D#8
	N	77, 29, 2		@ F#8
	N	81, 29, 7		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	77, 29, 4		@ F#8
	N	80, 29, 9		@ A8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 6		@ G#8
	N	76, 29, 8		@ F8
	N	73, 29, 6		@ D8
	N	74, 29, 10		@ D#8
	PAT_END

pat_08085DDC:				@ used by s5c1
	N	74, 29, 4		@ D#8
	N	69, 29, 2		@ A#7
	N	72, 29, 2		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	74, 29, 6		@ D#8
	N	74, 29, 4		@ D#8
	N	69, 29, 2		@ A#7
	N	72, 29, 2		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	81, 29, 6		@ A#8
	N	81, 29, 5		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 4		@ F#8
	N	81, 29, 4		@ A#8
	N	79, 29, 6		@ G#8
	N	72, 29, 6		@ C#8
	N	77, 29, 5		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	76, 29, 6		@ F8
	N	69, 29, 6		@ A#7
	N	74, 29, 4		@ D#8
	N	69, 29, 2		@ A#7
	N	72, 29, 2		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	74, 29, 6		@ D#8
	N	74, 29, 4		@ D#8
	N	69, 29, 2		@ A#7
	N	72, 29, 2		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	81, 29, 6		@ A#8
	N	81, 29, 5		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 4		@ F#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	76, 29, 4		@ F8
	N	72, 29, 6		@ C#8
	N	77, 29, 4		@ F#8
	N	70, 29, 4		@ B7
	N	69, 29, 4		@ A#7
	N	81, 29, 4		@ A#8
	N	77, 29, 6		@ F#8
	N	74, 29, 4		@ D#8
	PAT_END

pat_08085E88:				@ used by s5c2
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	58, 28, 2		@ B6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	58, 28, 4		@ B6
	N	50, 28, 4		@ D#6
	N	58, 28, 2		@ B6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	58, 28, 4		@ B6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	PAT_END

pat_08085F79:				@ used by s5c2
	N	49, 28, 4		@ D6
	N	58, 28, 2		@ B6
	N	49, 28, 2		@ D6
	N	49, 28, 4		@ D6
	N	58, 28, 4		@ B6
	N	49, 28, 4		@ D6
	N	58, 28, 2		@ B6
	N	49, 28, 2		@ D6
	N	49, 28, 4		@ D6
	N	58, 28, 4		@ B6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	49, 28, 4		@ D6
	N	58, 28, 2		@ B6
	N	49, 28, 2		@ D6
	N	49, 28, 4		@ D6
	N	58, 28, 4		@ B6
	N	49, 28, 4		@ D6
	N	58, 28, 2		@ B6
	N	49, 28, 2		@ D6
	N	49, 28, 4		@ D6
	N	58, 28, 4		@ B6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	52, 28, 4		@ F6
	N	57, 28, 2		@ A#6
	N	52, 28, 2		@ F6
	N	52, 28, 4		@ F6
	N	57, 28, 4		@ A#6
	N	52, 28, 4		@ F6
	N	57, 28, 2		@ A#6
	N	52, 28, 2		@ F6
	N	52, 28, 4		@ F6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	52, 28, 4		@ F6
	N	57, 28, 2		@ A#6
	N	52, 28, 2		@ F6
	N	52, 28, 4		@ F6
	N	57, 28, 4		@ A#6
	N	52, 28, 4		@ F6
	N	57, 28, 2		@ A#6
	N	52, 28, 2		@ F6
	N	52, 28, 4		@ F6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	PAT_END

pat_0808606A:				@ used by s5c2
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	48, 28, 4		@ C#6
	N	55, 28, 4		@ G#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	48, 28, 4		@ C#6
	N	55, 28, 4		@ G#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	53, 28, 4		@ F#6
	N	60, 28, 2		@ C#7
	N	53, 28, 2		@ F#6
	N	53, 28, 4		@ F#6
	N	60, 28, 4		@ C#7
	N	53, 28, 4		@ F#6
	N	60, 28, 2		@ C#7
	N	53, 28, 2		@ F#6
	N	53, 28, 4		@ F#6
	N	60, 28, 4		@ C#7
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	48, 28, 4		@ C#6
	N	55, 28, 4		@ G#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	48, 28, 4		@ C#6
	N	55, 28, 4		@ G#6
	N	46, 28, 4		@ B5
	N	53, 28, 2		@ F#6
	N	46, 28, 2		@ B5
	N	46, 28, 4		@ B5
	N	53, 28, 4		@ F#6
	N	45, 28, 4		@ A#5
	N	52, 28, 2		@ F6
	N	45, 28, 2		@ A#5
	N	45, 28, 4		@ A#5
	N	52, 28, 4		@ F6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	PAT_END

pat_0808615B:				@ used by s5c2
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	49, 28, 4		@ D6
	N	57, 28, 2		@ A#6
	N	49, 28, 2		@ D6
	N	49, 28, 4		@ D6
	N	57, 28, 4		@ A#6
	N	49, 28, 4		@ D6
	N	57, 28, 2		@ A#6
	N	49, 28, 2		@ D6
	N	49, 28, 4		@ D6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	56, 28, 2		@ A6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	56, 28, 4		@ A6
	N	50, 28, 4		@ D#6
	N	55, 28, 2		@ G#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	55, 28, 4		@ G#6
	N	50, 28, 4		@ D#6
	N	55, 28, 2		@ G#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	55, 28, 4		@ G#6
	N	50, 28, 4		@ D#6
	N	53, 28, 2		@ F#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	53, 28, 4		@ F#6
	N	50, 28, 4		@ D#6
	N	53, 28, 2		@ F#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	53, 28, 4		@ F#6
	PAT_END

pat_0808624C:				@ used by s5c2
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	57, 28, 2		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	53, 28, 4		@ F#6
	N	57, 28, 4		@ A#6
	N	53, 28, 4		@ F#6
	N	57, 28, 2		@ A#6
	N	53, 28, 2		@ F#6
	N	53, 28, 4		@ F#6
	N	57, 28, 4		@ A#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	48, 28, 4		@ C#6
	N	55, 28, 4		@ G#6
	N	46, 28, 4		@ B5
	N	53, 28, 2		@ F#6
	N	46, 28, 2		@ B5
	N	46, 28, 4		@ B5
	N	53, 28, 4		@ F#6
	N	45, 28, 4		@ A#5
	N	52, 28, 2		@ F6
	N	45, 28, 2		@ A#5
	N	45, 28, 4		@ A#5
	N	52, 28, 4		@ F6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	53, 28, 4		@ F#6
	N	57, 28, 4		@ A#6
	N	53, 28, 4		@ F#6
	N	57, 28, 2		@ A#6
	N	53, 28, 2		@ F#6
	N	53, 28, 4		@ F#6
	N	57, 28, 4		@ A#6
	N	48, 28, 4		@ C#6
	N	55, 28, 2		@ G#6
	N	48, 28, 2		@ C#6
	N	48, 28, 4		@ C#6
	N	55, 28, 4		@ G#6
	N	46, 28, 4		@ B5
	N	53, 28, 2		@ F#6
	N	53, 28, 2		@ F#6
	N	45, 28, 4		@ A#5
	N	52, 28, 2		@ F6
	N	52, 28, 2		@ F6
	N	50, 28, 4		@ D#6
	N	57, 28, 2		@ A#6
	N	50, 28, 2		@ D#6
	N	50, 28, 4		@ D#6
	N	57, 28, 4		@ A#6
	PAT_END

pat_08086340:				@ used by s5c4
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	46, 5, 4		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	46, 5, 4		@ B5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	42, 3, 5		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 5		@ B5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 4		@ B5
	PAT_END

pat_080863CE:				@ used by s5c5
	N	69, 18, 4		@ A#7
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	74, 18, 7		@ D#8
	N	76, 18, 4		@ F8
	N	77, 18, 4		@ F#8
	N	81, 18, 4		@ A#8
	N	80, 18, 8		@ A8
	N	77, 18, 6		@ F#8
	N	74, 18, 6		@ D#8
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	69, 18, 7		@ A#7
	N	72, 18, 4		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	70, 18, 7		@ B7
	N	72, 18, 4		@ C#8
	N	74, 18, 6		@ D#8
	N	72, 18, 4		@ C#8
	N	70, 18, 4		@ B7
	N	69, 18, 4		@ A#7
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	81, 18, 7		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	80, 18, 9		@ A8
	N	79, 18, 4		@ G#8
	N	77, 18, 4		@ F#8
	N	79, 18, 6		@ G#8
	N	76, 18, 6		@ F8
	N	73, 18, 6		@ D8
	N	69, 18, 4		@ A#7
	N	71, 18, 2		@ C8
	N	73, 18, 2		@ D8
	N	74, 18, 10		@ D#8
	PAT_END

pat_0808644A:				@ used by s5c5
	N	69, 18, 24		@ A#7
	N	74, 18, 2		@ D#8
	N	77, 18, 2		@ F#8
	N	74, 18, 2		@ D#8
	N	81, 18, 24		@ A#8
	N	82, 18, 2		@ B8
	N	81, 18, 2		@ A#8
	N	77, 18, 2		@ F#8
	N	80, 18, 9		@ A8
	N	81, 18, 4		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 6		@ A#8
	N	74, 18, 7		@ D#8
	N	76, 18, 4		@ F8
	N	77, 18, 4		@ F#8
	N	74, 18, 4		@ D#8
	N	79, 18, 2		@ G#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 7		@ F8
	N	77, 18, 4		@ F#8
	N	79, 18, 4		@ G#8
	N	77, 18, 4		@ F#8
	N	69, 18, 4		@ A#7
	N	74, 18, 2		@ D#8
	N	77, 18, 2		@ F#8
	N	81, 18, 21		@ A#8
	N	82, 18, 2		@ B8
	N	81, 18, 2		@ A#8
	N	77, 18, 2		@ F#8
	N	80, 18, 19		@ A8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	79, 18, 2		@ G#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 24		@ F8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	73, 18, 4		@ D8
	N	69, 18, 4		@ A#7
	N	74, 18, 10		@ D#8
	PAT_END

pat_080864D2:				@ used by s5c5
	N	70, 18, 4		@ B7
	N	73, 18, 2		@ D8
	N	77, 18, 2		@ F#8
	N	79, 18, 7		@ G#8
	N	77, 18, 4		@ F#8
	N	82, 18, 4		@ B8
	N	79, 18, 4		@ G#8
	N	81, 18, 21		@ A#8
	N	82, 18, 2		@ B8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 6		@ A#8
	N	70, 18, 4		@ B7
	N	73, 18, 2		@ D8
	N	77, 18, 2		@ F#8
	N	79, 18, 7		@ G#8
	N	81, 18, 4		@ A#8
	N	82, 18, 4		@ B8
	N	84, 18, 4		@ C#9
	N	81, 18, 10		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	76, 18, 4		@ F8
	N	76, 18, 5		@ F8
	N	82, 18, 2		@ B8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	76, 18, 4		@ F8
	N	76, 18, 4		@ F8
	N	81, 18, 4		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	74, 18, 4		@ D#8
	N	74, 18, 5		@ D#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	74, 18, 4		@ D#8
	N	74, 18, 4		@ D#8
	N	79, 18, 4		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	73, 18, 4		@ D8
	N	73, 18, 5		@ D8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	73, 18, 4		@ D8
	N	73, 18, 4		@ D8
	N	74, 18, 24		@ D#8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	74, 18, 8		@ D#8
	PAT_END

pat_08086578:				@ used by s5c5
	N	86, 18, 2		@ D#9
	N	84, 18, 2		@ C#9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	84, 18, 4		@ C#9
	N	86, 18, 6		@ D#9
	N	84, 18, 4		@ C#9
	N	81, 18, 4		@ A#8
	N	84, 18, 2		@ C#9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	76, 18, 2		@ F8
	N	79, 18, 4		@ G#8
	N	81, 18, 4		@ A#8
	N	79, 18, 4		@ G#8
	N	77, 18, 4		@ F#8
	N	81, 18, 4		@ A#8
	N	84, 18, 4		@ C#9
	N	86, 18, 2		@ D#9
	N	84, 18, 2		@ C#9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	84, 18, 4		@ C#9
	N	86, 18, 6		@ D#9
	N	84, 18, 4		@ C#9
	N	81, 18, 4		@ A#8
	N	77, 18, 24		@ F#8
	N	79, 18, 2		@ G#8
	N	81, 18, 2		@ A#8
	N	82, 18, 2		@ B8
	N	81, 18, 8		@ A#8
	N	86, 18, 2		@ D#9
	N	84, 18, 2		@ C#9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	84, 18, 4		@ C#9
	N	86, 18, 6		@ D#9
	N	84, 18, 4		@ C#9
	N	81, 18, 4		@ A#8
	N	84, 18, 2		@ C#9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	79, 18, 4		@ G#8
	N	81, 18, 4		@ A#8
	N	79, 18, 7		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	74, 18, 7		@ D#8
	N	76, 18, 2		@ F8
	N	77, 18, 2		@ F#8
	N	79, 18, 24		@ G#8
	N	81, 18, 2		@ A#8
	N	82, 18, 2		@ B8
	N	79, 18, 2		@ G#8
	N	81, 18, 24		@ A#8
	N	82, 18, 2		@ B8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 8		@ A#8
	PAT_END

pat_08086636:				@ used by s5c5
	N	74, 18, 4		@ D#8
	N	76, 18, 2		@ F8
	N	77, 18, 2		@ F#8
	N	81, 18, 7		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 4		@ A#8
	N	77, 18, 4		@ F#8
	N	72, 18, 4		@ C#8
	N	74, 18, 2		@ D#8
	N	76, 18, 2		@ F8
	N	79, 18, 7		@ G#8
	N	81, 18, 4		@ A#8
	N	79, 18, 4		@ G#8
	N	76, 18, 4		@ F8
	N	74, 18, 4		@ D#8
	N	77, 18, 2		@ F#8
	N	79, 18, 2		@ G#8
	N	81, 18, 7		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 4		@ A#8
	N	77, 18, 4		@ F#8
	N	84, 18, 24		@ C#9
	N	86, 18, 2		@ D#9
	N	84, 18, 2		@ C#9
	N	82, 18, 2		@ B8
	N	84, 18, 8		@ C#9
	N	74, 18, 4		@ D#8
	N	76, 18, 2		@ F8
	N	77, 18, 2		@ F#8
	N	81, 18, 7		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 4		@ A#8
	N	77, 18, 4		@ F#8
	N	79, 18, 4		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	72, 18, 7		@ C#8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	72, 18, 4		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 2		@ F#8
	N	82, 18, 2		@ B8
	N	86, 18, 7		@ D#9
	N	84, 18, 4		@ C#9
	N	82, 18, 4		@ B8
	N	79, 18, 4		@ G#8
	N	81, 18, 10		@ A#8
	PAT_END

pat_080866C7:				@ used by s5c5
	N	69, 18, 4		@ A#7
	N	74, 18, 2		@ D#8
	N	77, 18, 2		@ F#8
	N	81, 18, 7		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 4		@ A#8
	N	77, 18, 4		@ F#8
	N	80, 18, 9		@ A8
	N	81, 18, 4		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 6		@ A#8
	N	74, 18, 7		@ D#8
	N	77, 18, 4		@ F#8
	N	76, 18, 4		@ F8
	N	74, 18, 4		@ D#8
	N	73, 18, 10		@ D8
	N	69, 18, 4		@ A#7
	N	74, 18, 2		@ D#8
	N	77, 18, 2		@ F#8
	N	81, 18, 7		@ A#8
	N	82, 18, 4		@ B8
	N	81, 18, 4		@ A#8
	N	77, 18, 4		@ F#8
	N	80, 18, 9		@ A8
	N	79, 18, 4		@ G#8
	N	77, 18, 4		@ F#8
	N	79, 18, 6		@ G#8
	N	76, 18, 8		@ F8
	N	73, 18, 6		@ D8
	N	74, 18, 10		@ D#8
	PAT_END

pat_08086722:				@ used by s5c5
	N	74, 18, 4		@ D#8
	N	69, 18, 2		@ A#7
	N	72, 18, 2		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	76, 18, 4		@ F8
	N	72, 18, 4		@ C#8
	N	74, 18, 6		@ D#8
	N	74, 18, 4		@ D#8
	N	69, 18, 2		@ A#7
	N	72, 18, 2		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	76, 18, 4		@ F8
	N	72, 18, 4		@ C#8
	N	81, 18, 6		@ A#8
	N	81, 18, 5		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 4		@ F#8
	N	81, 18, 4		@ A#8
	N	79, 18, 6		@ G#8
	N	72, 18, 6		@ C#8
	N	77, 18, 5		@ F#8
	N	76, 18, 2		@ F8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	76, 18, 6		@ F8
	N	69, 18, 6		@ A#7
	N	74, 18, 4		@ D#8
	N	69, 18, 2		@ A#7
	N	72, 18, 2		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	76, 18, 4		@ F8
	N	72, 18, 4		@ C#8
	N	74, 18, 6		@ D#8
	N	74, 18, 4		@ D#8
	N	69, 18, 2		@ A#7
	N	72, 18, 2		@ C#8
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	76, 18, 4		@ F8
	N	72, 18, 4		@ C#8
	N	81, 18, 6		@ A#8
	N	81, 18, 5		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 4		@ F#8
	N	81, 18, 4		@ A#8
	N	79, 18, 4		@ G#8
	N	76, 18, 4		@ F8
	N	72, 18, 6		@ C#8
	N	77, 18, 4		@ F#8
	N	70, 18, 4		@ B7
	N	69, 18, 4		@ A#7
	N	81, 18, 4		@ A#8
	N	77, 18, 6		@ F#8
	N	74, 18, 6		@ D#8
	PAT_END

pat_080867CE:				@ used by s5c6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	70, 17, 4		@ B7
	N	62, 17, 2		@ D#7
	N	70, 17, 2		@ B7
	N	70, 17, 4		@ B7
	N	62, 17, 4		@ D#7
	N	70, 17, 4		@ B7
	N	62, 17, 2		@ D#7
	N	70, 17, 2		@ B7
	N	70, 17, 4		@ B7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	61, 17, 4		@ D7
	N	67, 17, 4		@ G#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	61, 17, 4		@ D7
	N	65, 17, 4		@ F#7
	N	62, 17, 2		@ D#7
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	62, 17, 4		@ D#7
	N	65, 17, 4		@ F#7
	N	62, 17, 2		@ D#7
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	62, 17, 4		@ D#7
	PAT_END

pat_080868BF:				@ used by s5c6
	N	70, 17, 4		@ B7
	N	61, 17, 2		@ D7
	N	70, 17, 2		@ B7
	N	70, 17, 4		@ B7
	N	61, 17, 4		@ D7
	N	70, 17, 4		@ B7
	N	61, 17, 2		@ D7
	N	70, 17, 2		@ B7
	N	70, 17, 4		@ B7
	N	61, 17, 4		@ D7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	70, 17, 4		@ B7
	N	61, 17, 2		@ D7
	N	70, 17, 2		@ B7
	N	70, 17, 4		@ B7
	N	61, 17, 4		@ D7
	N	70, 17, 4		@ B7
	N	61, 17, 2		@ D7
	N	70, 17, 2		@ B7
	N	70, 17, 4		@ B7
	N	61, 17, 4		@ D7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	61, 17, 4		@ D7
	N	67, 17, 4		@ G#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	61, 17, 4		@ D7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	61, 17, 4		@ D7
	N	67, 17, 4		@ G#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	61, 17, 4		@ D7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	PAT_END

pat_080869B0:				@ used by s5c6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	60, 17, 4		@ C#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	60, 17, 4		@ C#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	72, 17, 4		@ C#8
	N	65, 17, 2		@ F#7
	N	72, 17, 2		@ C#8
	N	72, 17, 4		@ C#8
	N	65, 17, 4		@ F#7
	N	72, 17, 4		@ C#8
	N	65, 17, 2		@ F#7
	N	72, 17, 2		@ C#8
	N	72, 17, 4		@ C#8
	N	65, 17, 4		@ F#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	60, 17, 4		@ C#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	60, 17, 4		@ C#7
	N	65, 17, 4		@ F#7
	N	58, 17, 2		@ B6
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	58, 17, 4		@ B6
	N	64, 17, 4		@ F7
	N	57, 17, 2		@ A#6
	N	64, 17, 2		@ F7
	N	64, 17, 4		@ F7
	N	57, 17, 4		@ A#6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	PAT_END

pat_08086AA1:				@ used by s5c6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	61, 17, 2		@ D7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	61, 17, 4		@ D7
	N	69, 17, 4		@ A#7
	N	61, 17, 2		@ D7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	61, 17, 4		@ D7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	68, 17, 4		@ A7
	N	62, 17, 2		@ D#7
	N	68, 17, 2		@ A7
	N	68, 17, 4		@ A7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	62, 17, 2		@ D#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	62, 17, 2		@ D#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	62, 17, 4		@ D#7
	N	65, 17, 4		@ F#7
	N	62, 17, 2		@ D#7
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	62, 17, 4		@ D#7
	N	65, 17, 4		@ F#7
	N	62, 17, 2		@ D#7
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	62, 17, 4		@ D#7
	PAT_END

pat_08086B92:				@ used by s5c6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	62, 17, 2		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	N	65, 17, 4		@ F#7
	N	60, 17, 4		@ C#7
	N	65, 17, 4		@ F#7
	N	60, 17, 2		@ C#7
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	60, 17, 4		@ C#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	60, 17, 4		@ C#7
	N	65, 17, 4		@ F#7
	N	58, 17, 2		@ B6
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	58, 17, 4		@ B6
	N	64, 17, 4		@ F7
	N	57, 17, 2		@ A#6
	N	64, 17, 2		@ F7
	N	64, 17, 4		@ F7
	N	57, 17, 4		@ A#6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	N	65, 17, 4		@ F#7
	N	60, 17, 4		@ C#7
	N	65, 17, 4		@ F#7
	N	60, 17, 2		@ C#7
	N	65, 17, 2		@ F#7
	N	65, 17, 4		@ F#7
	N	60, 17, 4		@ C#7
	N	67, 17, 4		@ G#7
	N	60, 17, 2		@ C#7
	N	67, 17, 2		@ G#7
	N	67, 17, 4		@ G#7
	N	60, 17, 4		@ C#7
	N	65, 17, 4		@ F#7
	N	58, 17, 2		@ B6
	N	58, 17, 2		@ B6
	N	64, 17, 4		@ F7
	N	57, 17, 2		@ A#6
	N	57, 17, 2		@ A#6
	N	69, 17, 4		@ A#7
	N	62, 17, 2		@ D#7
	N	69, 17, 2		@ A#7
	N	69, 17, 4		@ A#7
	N	62, 17, 4		@ D#7
	PAT_END

pat_08086C86:				@ used by s5c7
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	44, 1, 4		@ A5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	38, 1, 5		@ D#5
	N	43, 1, 2		@ G#5
	N	45, 1, 4		@ A#5
	N	46, 1, 4		@ B5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	44, 1, 4		@ A5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	PAT_END

pat_08086D47:				@ used by s5c7
	N	34, 1, 5		@ B4
	N	37, 1, 2		@ D5
	N	39, 1, 4		@ E5
	N	41, 1, 4		@ F#5
	REST	0, 4
	N	34, 1, 4		@ B4
	N	37, 1, 4		@ D5
	N	41, 1, 4		@ F#5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	34, 1, 5		@ B4
	N	37, 1, 2		@ D5
	N	39, 1, 4		@ E5
	N	41, 1, 4		@ F#5
	REST	0, 4
	N	34, 1, 4		@ B4
	N	37, 1, 4		@ D5
	N	41, 1, 4		@ F#5
	N	38, 1, 5		@ D#5
	N	43, 1, 2		@ G#5
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	33, 1, 5		@ A#4
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	PAT_END

pat_08086E08:				@ used by s5c7
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	36, 1, 5		@ C#5
	N	40, 1, 2		@ F5
	N	41, 1, 4		@ F#5
	N	43, 1, 4		@ G#5
	REST	0, 4
	N	31, 1, 4		@ G#4
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 5		@ F#5
	N	45, 1, 2		@ A#5
	N	48, 1, 4		@ C#6
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	36, 1, 5		@ C#5
	N	40, 1, 2		@ F5
	N	41, 1, 4		@ F#5
	N	43, 1, 4		@ G#5
	REST	0, 4
	N	31, 1, 4		@ G#4
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	34, 1, 5		@ B4
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 4		@ F#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	PAT_END

pat_08086EC9:				@ used by s5c7
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	44, 1, 4		@ A5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	44, 1, 4		@ A5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	PAT_END

pat_08086F8A:				@ used by s5c7
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	44, 1, 4		@ A5
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	29, 1, 4		@ F#4
	N	41, 1, 5		@ F#5
	N	45, 1, 2		@ A#5
	N	46, 1, 4		@ B5
	N	48, 1, 4		@ C#6
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	34, 1, 5		@ B4
	N	38, 1, 2		@ D#5
	N	41, 1, 4		@ F#5
	N	46, 1, 4		@ B5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	37, 1, 4		@ D5
	N	38, 1, 5		@ D#5
	N	41, 1, 2		@ F#5
	N	43, 1, 4		@ G#5
	N	44, 1, 4		@ A5
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	29, 1, 4		@ F#4
	N	41, 1, 5		@ F#5
	N	45, 1, 2		@ A#5
	N	46, 1, 4		@ B5
	N	48, 1, 4		@ C#6
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	34, 1, 5		@ B4
	N	41, 1, 2		@ F#5
	N	45, 1, 4		@ A#5
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	PAT_END

pat_0808704B:				@ used by s5c8
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 9, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 6, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 8, 2		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 7, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 5, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 9, 2		@ C#6
	PAT_END

pat_08087199:				@ used by s6c5
	N	50, 14, 6		@ D#6
	N	53, 14, 6		@ F#6
	N	58, 14, 6		@ B6
	N	57, 14, 6		@ A#6
	N	50, 14, 10		@ D#6
	PAT_END

pat_080871A9:				@ used by s6c6
	N	45, 14, 6		@ A#5
	N	50, 14, 6		@ D#6
	N	53, 14, 6		@ F#6
	N	52, 14, 6		@ F6
	N	45, 14, 10		@ A#5
	PAT_END

pat_080871B9:				@ used by s6c7
	N	41, 14, 6		@ F#5
	N	45, 14, 6		@ A#5
	N	50, 14, 6		@ D#6
	N	49, 14, 6		@ D6
	N	41, 14, 10		@ F#5
	PAT_END

pat_080871C9:				@ used by s6c8
	N	38, 14, 6		@ D#5
	N	41, 14, 6		@ F#5
	N	46, 14, 6		@ B5
	N	45, 14, 6		@ A#5
	N	38, 14, 10		@ D#5
	PAT_END

pat_080871D9:				@ used by s7c1
	REST	0, 4
	REST	0, 4
	N	81, 29, 2		@ A#8
	N	80, 29, 2		@ A8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	73, 29, 6		@ D8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 7		@ F#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	73, 29, 4		@ D8
	N	70, 29, 4		@ B7
	N	69, 29, 4		@ A#7
	N	81, 29, 2		@ A#8
	N	80, 29, 2		@ A8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	73, 29, 6		@ D8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 7		@ F#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 8		@ F8
	REST	0, 4
	N	81, 29, 2		@ A#8
	N	80, 29, 2		@ A8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	73, 29, 6		@ D8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 7		@ F#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	73, 29, 4		@ D8
	N	70, 29, 4		@ B7
	N	69, 29, 4		@ A#7
	N	81, 29, 2		@ A#8
	N	80, 29, 2		@ A8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	73, 29, 6		@ D8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 7		@ F#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 8		@ F8
	PAT_END

pat_0808727F:				@ used by s7c1
	N	69, 29, 10		@ A#7
	REST	0, 4
	N	71, 29, 4		@ C8
	N	72, 29, 4		@ C#8
	N	75, 29, 4		@ E8
	N	76, 29, 4		@ F8
	N	75, 29, 4		@ E8
	N	72, 29, 4		@ C#8
	N	71, 29, 4		@ C8
	N	69, 29, 10		@ A#7
	REST	0, 4
	N	71, 29, 4		@ C8
	N	72, 29, 4		@ C#8
	N	75, 29, 4		@ E8
	N	76, 29, 4		@ F8
	N	78, 29, 4		@ G8
	N	76, 29, 4		@ F8
	N	75, 29, 4		@ E8
	N	79, 29, 9		@ G#8
	N	78, 29, 4		@ G8
	N	76, 29, 4		@ F8
	N	74, 29, 9		@ D#8
	N	76, 29, 4		@ F8
	N	78, 29, 2		@ G8
	N	74, 29, 2		@ D#8
	N	76, 29, 24		@ F8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	76, 29, 47		@ F8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	76, 29, 8		@ F8
	PAT_END

pat_080872E6:				@ used by s7c1
	N	69, 29, 4		@ A#7
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	71, 29, 24		@ C8
	N	73, 29, 2		@ D8
	N	75, 29, 2		@ E8
	N	76, 29, 2		@ F8
	N	78, 29, 4		@ G8
	N	79, 29, 4		@ G#8
	N	78, 29, 4		@ G8
	N	75, 29, 4		@ E8
	N	76, 29, 24		@ F8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	72, 29, 4		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	78, 29, 24		@ G8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	78, 29, 4		@ G8
	N	76, 29, 4		@ F8
	N	75, 29, 4		@ E8
	N	72, 29, 4		@ C#8
	N	76, 29, 21		@ F8
	N	78, 29, 2		@ G8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 4		@ G#8
	N	78, 29, 2		@ G8
	N	76, 29, 2		@ F8
	N	74, 29, 7		@ D#8
	N	71, 29, 0		@ C8
	N	74, 29, 0		@ D#8
	N	79, 29, 0		@ G#8
	N	83, 29, 0		@ C9
	N	86, 29, 4		@ D#9
	N	84, 29, 4		@ C#9
	N	83, 29, 4		@ C9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 24		@ A#8
	N	83, 29, 2		@ C9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 2		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	74, 29, 2		@ D#8
	N	76, 29, 7		@ F8
	N	71, 29, 0		@ C8
	N	76, 29, 0		@ F8
	N	80, 29, 2		@ A8
	N	83, 29, 8		@ C9
	PAT_END

pat_080873A7:				@ used by s7c1
	N	0, 0, 4		@ C#2
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	74, 29, 7		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	76, 29, 8		@ F8
	N	0, 0, 4		@ C#2
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	72, 29, 6		@ C#8
	N	84, 29, 4		@ C#9
	N	83, 29, 2		@ C9
	N	81, 29, 2		@ A#8
	N	83, 29, 7		@ C9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 8		@ A#8
	N	0, 0, 4		@ C#2
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	74, 29, 7		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	79, 29, 2		@ G#8
	N	0, 0, 2		@ C#2
	N	77, 29, 2		@ F#8
	N	0, 0, 2		@ C#2
	N	76, 29, 2		@ F8
	N	0, 0, 2		@ C#2
	N	74, 29, 2		@ D#8
	N	0, 0, 2		@ C#2
	N	72, 29, 4		@ C#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	76, 29, 4		@ F8
	N	84, 29, 7		@ C#9
	N	83, 29, 2		@ C9
	N	81, 29, 2		@ A#8
	N	83, 29, 7		@ C9
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	81, 29, 8		@ A#8
	PAT_END

pat_08087450:				@ used by s7c1
	REST	0, 2
	N	81, 29, 2		@ A#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	76, 29, 8		@ F8
	REST	0, 2
	N	81, 29, 2		@ A#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	76, 29, 8		@ F8
	REST	0, 2
	N	77, 29, 2		@ F#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	70, 29, 5		@ B7
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 0		@ F8
	N	77, 29, 3		@ F#8
	N	79, 29, 0		@ G#8
	N	77, 29, 0		@ F#8
	N	76, 29, 0		@ F8
	N	74, 29, 0		@ D#8
	N	76, 29, 10		@ F8
	REST	0, 2
	N	81, 29, 2		@ A#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	76, 29, 8		@ F8
	REST	0, 2
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 0		@ F8
	N	77, 29, 0		@ F#8
	N	76, 29, 0		@ F8
	N	74, 29, 0		@ D#8
	N	76, 29, 8		@ F8
	REST	0, 2
	N	77, 29, 2		@ F#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	70, 29, 5		@ B7
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 0		@ F8
	N	77, 29, 0		@ F#8
	N	79, 29, 0		@ G#8
	N	81, 29, 0		@ A#8
	N	79, 29, 0		@ G#8
	N	77, 29, 0		@ F#8
	N	76, 29, 0		@ F8
	N	74, 29, 0		@ D#8
	N	76, 29, 10		@ F8
	PAT_END

pat_08087535:				@ used by s7c1
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	79, 29, 2		@ G#8
	REST	0, 4
	N	76, 29, 2		@ F8
	N	79, 29, 2		@ G#8
	N	81, 29, 24		@ A#8
	REST	0, 6
	REST	0, 10
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	79, 29, 2		@ G#8
	REST	0, 4
	N	76, 29, 2		@ F8
	N	79, 29, 2		@ G#8
	N	81, 29, 24		@ A#8
	REST	0, 6
	REST	0, 10
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	69, 29, 0		@ A#7
	N	71, 29, 0		@ C8
	N	72, 29, 0		@ C#8
	N	74, 29, 0		@ D#8
	N	76, 29, 2		@ F8
	REST	0, 5
	N	79, 29, 2		@ G#8
	REST	0, 4
	N	76, 29, 2		@ F8
	N	79, 29, 2		@ G#8
	N	81, 29, 24		@ A#8
	REST	0, 4
	PAT_END

pat_08087614:				@ used by s7c2
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	79, 28, 2		@ G#8
	REST	0, 4
	N	76, 28, 2		@ F8
	N	79, 28, 2		@ G#8
	N	81, 28, 24		@ A#8
	REST	0, 6
	REST	0, 10
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	79, 28, 2		@ G#8
	REST	0, 4
	N	76, 28, 2		@ F8
	N	79, 28, 2		@ G#8
	N	81, 28, 24		@ A#8
	REST	0, 6
	REST	0, 10
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	69, 28, 0		@ A#7
	N	71, 28, 0		@ C8
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 2		@ F8
	REST	0, 5
	N	79, 28, 2		@ G#8
	REST	0, 4
	N	76, 28, 2		@ F8
	N	79, 28, 2		@ G#8
	N	81, 28, 24		@ A#8
	REST	0, 6
	PAT_END

pat_080876F3:				@ used by s7c2
	REST	0, 2
	N	81, 28, 2		@ A#8
	N	81, 28, 2		@ A#8
	N	79, 28, 2		@ G#8
	N	79, 28, 2		@ G#8
	N	77, 28, 2		@ F#8
	N	77, 28, 2		@ F#8
	N	76, 28, 2		@ F8
	N	76, 28, 8		@ F8
	REST	0, 2
	N	81, 28, 2		@ A#8
	N	81, 28, 2		@ A#8
	N	79, 28, 2		@ G#8
	N	79, 28, 2		@ G#8
	N	77, 28, 2		@ F#8
	N	77, 28, 2		@ F#8
	N	76, 28, 2		@ F8
	N	76, 28, 8		@ F8
	REST	0, 2
	N	77, 28, 2		@ F#8
	N	77, 28, 2		@ F#8
	N	76, 28, 2		@ F8
	N	76, 28, 2		@ F8
	N	74, 28, 2		@ D#8
	N	74, 28, 2		@ D#8
	N	72, 28, 2		@ C#8
	N	70, 28, 5		@ B7
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 0		@ F8
	N	77, 28, 3		@ F#8
	N	79, 28, 0		@ G#8
	N	77, 28, 0		@ F#8
	N	76, 28, 0		@ F8
	N	74, 28, 0		@ D#8
	N	76, 28, 10		@ F8
	REST	0, 2
	N	81, 28, 2		@ A#8
	N	81, 28, 2		@ A#8
	N	79, 28, 2		@ G#8
	N	79, 28, 2		@ G#8
	N	77, 28, 2		@ F#8
	N	77, 28, 2		@ F#8
	N	76, 28, 2		@ F8
	N	76, 28, 8		@ F8
	REST	0, 2
	N	81, 28, 2		@ A#8
	N	82, 28, 2		@ B8
	N	81, 28, 2		@ A#8
	N	79, 28, 2		@ G#8
	N	77, 28, 2		@ F#8
	N	76, 28, 0		@ F8
	N	77, 28, 0		@ F#8
	N	76, 28, 0		@ F8
	N	74, 28, 0		@ D#8
	N	76, 28, 8		@ F8
	REST	0, 2
	N	77, 28, 2		@ F#8
	N	77, 28, 2		@ F#8
	N	76, 28, 2		@ F8
	N	76, 28, 2		@ F8
	N	74, 28, 2		@ D#8
	N	74, 28, 2		@ D#8
	N	72, 28, 2		@ C#8
	N	70, 28, 5		@ B7
	N	72, 28, 0		@ C#8
	N	74, 28, 0		@ D#8
	N	76, 28, 0		@ F8
	N	77, 28, 0		@ F#8
	N	79, 28, 0		@ G#8
	N	81, 28, 0		@ A#8
	N	79, 28, 0		@ G#8
	N	77, 28, 0		@ F#8
	N	76, 28, 0		@ F8
	N	74, 28, 0		@ D#8
	N	76, 28, 10		@ F8
	PAT_END

pat_080877D8:				@ used by s7c5
	N	48, 21, 10		@ C#6
	PAT_END

pat_080877DC:				@ used by s7c5
	REST	0, 4
	N	81, 18, 2		@ A#8
	N	80, 18, 2		@ A8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	73, 18, 6		@ D8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	77, 18, 7		@ F#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 4		@ F8
	N	74, 18, 4		@ D#8
	N	73, 18, 4		@ D8
	N	70, 18, 4		@ B7
	N	69, 18, 4		@ A#7
	N	81, 18, 2		@ A#8
	N	80, 18, 2		@ A8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	73, 18, 6		@ D8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	77, 18, 7		@ F#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 8		@ F8
	REST	0, 4
	N	81, 18, 2		@ A#8
	N	80, 18, 2		@ A8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	73, 18, 6		@ D8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	77, 18, 7		@ F#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 4		@ F8
	N	74, 18, 4		@ D#8
	N	73, 18, 4		@ D8
	N	70, 18, 4		@ B7
	N	69, 18, 4		@ A#7
	N	81, 18, 2		@ A#8
	N	80, 18, 2		@ A8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	73, 18, 6		@ D8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	77, 18, 7		@ F#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 8		@ F8
	PAT_END

pat_0808787F:				@ used by s7c5
	N	69, 18, 10		@ A#7
	REST	0, 4
	N	71, 18, 4		@ C8
	N	72, 18, 4		@ C#8
	N	75, 18, 4		@ E8
	N	76, 18, 4		@ F8
	N	75, 18, 4		@ E8
	N	72, 18, 4		@ C#8
	N	71, 18, 4		@ C8
	N	69, 18, 10		@ A#7
	REST	0, 4
	N	71, 18, 4		@ C8
	N	72, 18, 4		@ C#8
	N	75, 18, 4		@ E8
	N	76, 18, 4		@ F8
	N	78, 18, 4		@ G8
	N	76, 18, 4		@ F8
	N	75, 18, 4		@ E8
	N	79, 18, 9		@ G#8
	N	78, 18, 4		@ G8
	N	76, 18, 4		@ F8
	N	74, 18, 9		@ D#8
	N	76, 18, 4		@ F8
	N	78, 18, 2		@ G8
	N	74, 18, 2		@ D#8
	N	76, 18, 24		@ F8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	76, 18, 47		@ F8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	76, 18, 8		@ F8
	PAT_END

pat_080878E6:				@ used by s7c5
	N	69, 18, 4		@ A#7
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	72, 18, 6		@ C#8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	71, 18, 24		@ C8
	N	73, 18, 2		@ D8
	N	75, 18, 2		@ E8
	N	76, 18, 2		@ F8
	N	78, 18, 4		@ G8
	N	79, 18, 4		@ G#8
	N	78, 18, 4		@ G8
	N	75, 18, 4		@ E8
	N	76, 18, 24		@ F8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	72, 18, 4		@ C#8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	72, 18, 4		@ C#8
	N	78, 18, 24		@ G8
	N	79, 18, 2		@ G#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	78, 18, 4		@ G8
	N	76, 18, 4		@ F8
	N	75, 18, 4		@ E8
	N	72, 18, 4		@ C#8
	N	76, 18, 21		@ F8
	N	78, 18, 2		@ G8
	N	79, 18, 2		@ G#8
	N	81, 18, 2		@ A#8
	N	79, 18, 4		@ G#8
	N	78, 18, 2		@ G8
	N	76, 18, 2		@ F8
	N	74, 18, 7		@ D#8
	N	71, 18, 0		@ C8
	N	74, 18, 0		@ D#8
	N	79, 18, 0		@ G#8
	N	83, 18, 0		@ C9
	N	86, 18, 4		@ D#9
	N	84, 18, 4		@ C#9
	N	83, 18, 4		@ C9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 24		@ A#8
	N	83, 18, 2		@ C9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 4		@ F#8
	N	76, 18, 4		@ F8
	N	74, 18, 2		@ D#8
	N	76, 18, 2		@ F8
	N	77, 18, 2		@ F#8
	N	74, 18, 2		@ D#8
	N	76, 18, 7		@ F8
	N	71, 18, 0		@ C8
	N	76, 18, 0		@ F8
	N	80, 18, 2		@ A8
	N	83, 18, 8		@ C9
	PAT_END

pat_080879A7:				@ used by s7c5
	N	0, 0, 4		@ C#2
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	72, 18, 6		@ C#8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	74, 18, 7		@ D#8
	N	76, 18, 2		@ F8
	N	77, 18, 2		@ F#8
	N	76, 18, 8		@ F8
	N	0, 0, 4		@ C#2
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	72, 18, 6		@ C#8
	N	84, 18, 4		@ C#9
	N	83, 18, 2		@ C9
	N	81, 18, 2		@ A#8
	N	83, 18, 7		@ C9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 8		@ A#8
	N	0, 0, 4		@ C#2
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	72, 18, 6		@ C#8
	N	74, 18, 4		@ D#8
	N	76, 18, 4		@ F8
	N	74, 18, 7		@ D#8
	N	76, 18, 2		@ F8
	N	77, 18, 2		@ F#8
	N	79, 18, 2		@ G#8
	N	0, 0, 2		@ C#2
	N	77, 18, 2		@ F#8
	N	0, 0, 2		@ C#2
	N	76, 18, 2		@ F8
	N	0, 0, 2		@ C#2
	N	74, 18, 2		@ D#8
	N	0, 0, 2		@ C#2
	N	72, 18, 4		@ C#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 4		@ A#8
	N	76, 18, 4		@ F8
	N	84, 18, 7		@ C#9
	N	83, 18, 2		@ C9
	N	81, 18, 2		@ A#8
	N	83, 18, 7		@ C9
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	81, 18, 8		@ A#8
	PAT_END

pat_08087A50:				@ used by s7c5
	REST	0, 2
	N	81, 18, 2		@ A#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	76, 18, 8		@ F8
	REST	0, 2
	N	81, 18, 2		@ A#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	76, 18, 8		@ F8
	REST	0, 2
	N	77, 18, 2		@ F#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	70, 18, 5		@ B7
	N	72, 18, 0		@ C#8
	N	74, 18, 0		@ D#8
	N	76, 18, 0		@ F8
	N	77, 18, 3		@ F#8
	N	79, 18, 0		@ G#8
	N	77, 18, 0		@ F#8
	N	76, 18, 0		@ F8
	N	74, 18, 0		@ D#8
	N	76, 18, 10		@ F8
	REST	0, 2
	N	81, 18, 2		@ A#8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	76, 18, 8		@ F8
	REST	0, 2
	N	81, 18, 2		@ A#8
	N	82, 18, 2		@ B8
	N	81, 18, 2		@ A#8
	N	79, 18, 2		@ G#8
	N	77, 18, 2		@ F#8
	N	76, 18, 0		@ F8
	N	77, 18, 0		@ F#8
	N	76, 18, 0		@ F8
	N	74, 18, 0		@ D#8
	N	76, 18, 8		@ F8
	REST	0, 2
	N	77, 18, 2		@ F#8
	N	77, 18, 2		@ F#8
	N	76, 18, 2		@ F8
	N	76, 18, 2		@ F8
	N	74, 18, 2		@ D#8
	N	74, 18, 2		@ D#8
	N	72, 18, 2		@ C#8
	N	70, 18, 5		@ B7
	N	72, 18, 0		@ C#8
	N	74, 18, 0		@ D#8
	N	76, 18, 0		@ F8
	N	77, 18, 0		@ F#8
	N	79, 18, 0		@ G#8
	N	81, 18, 0		@ A#8
	N	79, 18, 0		@ G#8
	N	77, 18, 0		@ F#8
	N	76, 18, 0		@ F8
	N	74, 18, 0		@ D#8
	N	76, 18, 10		@ F8
	PAT_END

pat_08087B35:				@ used by s7c5
	N	69, 18, 0		@ A#7
	N	71, 18, 0		@ C8
	N	72, 18, 0		@ C#8
	N	74, 18, 0		@ D#8
	N	76, 18, 2		@ F8
	REST	0, 5
	N	69, 18, 0		@ A#7
	N	71, 18, 0		@ C8
	N	72, 18, 0		@ C#8
	N	74, 18, 0		@ D#8
	N	76, 18, 2		@ F8
	REST	0, 5
	N	69, 18, 0		@ A#7
	N	71, 18, 0		@ C8
	N	72, 18, 0		@ C#8
	N	74, 18, 0		@ D#8
	N	76, 18, 2		@ F8
	REST	0, 5
	N	79, 18, 2		@ G#8
	REST	0, 4
	N	76, 18, 2		@ F8
	N	79, 18, 2		@ G#8
	N	81, 18, 24		@ A#8
	REST	0, 6
	PAT_END

pat_08087B7E:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	PAT_END

pat_08087C03:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	50, 20, 2		@ D#6
	N	50, 20, 4		@ D#6
	N	50, 20, 2		@ D#6
	N	50, 20, 4		@ D#6
	N	50, 20, 4		@ D#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	50, 20, 2		@ D#6
	N	50, 20, 4		@ D#6
	N	50, 20, 2		@ D#6
	N	50, 20, 4		@ D#6
	N	50, 20, 4		@ D#6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	PAT_END

pat_08087C7C:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 4		@ G#6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	PAT_END

pat_08087D70:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 2		@ G6
	N	54, 20, 4		@ G6
	N	54, 20, 4		@ G6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 2		@ G#6
	N	55, 20, 4		@ G#6
	N	55, 20, 4		@ G#6
	N	53, 20, 2		@ F#6
	N	53, 20, 4		@ F#6
	N	53, 20, 2		@ F#6
	N	53, 20, 4		@ F#6
	N	53, 20, 4		@ F#6
	N	53, 20, 2		@ F#6
	N	53, 20, 4		@ F#6
	N	53, 20, 2		@ F#6
	N	53, 20, 4		@ F#6
	N	53, 20, 4		@ F#6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 4		@ F6
	PAT_END

pat_08087E64:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	52, 20, 4		@ F6
	N	52, 20, 2		@ F6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	PAT_END

pat_08087F79:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 4		@ B6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 2		@ B6
	N	58, 20, 4		@ B6
	N	58, 20, 4		@ B6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 4		@ A#6
	PAT_END

pat_08088085:				@ used by s7c6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	58, 20, 4		@ B6
	N	60, 20, 4		@ C#7
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	55, 20, 4		@ G#6
	N	52, 20, 4		@ F6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	58, 20, 4		@ B6
	N	60, 20, 4		@ C#7
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	57, 20, 2		@ A#6
	N	57, 20, 4		@ A#6
	N	55, 20, 4		@ G#6
	N	52, 20, 4		@ F6
	PAT_END

pat_080880FE:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	45, 1, 4		@ A#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	PAT_END

pat_0808815F:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 5		@ D#5
	N	38, 1, 2		@ D#5
	N	33, 1, 4		@ A#4
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 5		@ D#5
	N	38, 1, 2		@ D#5
	N	33, 1, 4		@ A#4
	N	38, 1, 4		@ D#5
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 5		@ D#5
	N	38, 1, 2		@ D#5
	N	37, 1, 4		@ D5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	32, 1, 4		@ A4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 5		@ D#5
	N	38, 1, 2		@ D#5
	N	33, 1, 4		@ A#4
	N	38, 1, 4		@ D#5
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	PAT_END

pat_08088220:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	35, 1, 5		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	REST	0, 4
	N	35, 1, 4		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	35, 1, 5		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	REST	0, 4
	N	35, 1, 4		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	36, 1, 5		@ C#5
	N	36, 1, 2		@ C#5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	38, 1, 5		@ D#5
	N	38, 1, 2		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	40, 1, 5		@ F5
	N	41, 1, 2		@ F#5
	N	44, 1, 4		@ A5
	N	41, 1, 4		@ F#5
	REST	0, 4
	N	40, 1, 4		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	44, 1, 4		@ A5
	N	41, 1, 4		@ F#5
	REST	0, 4
	N	40, 1, 4		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	PAT_END

pat_080882E1:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	35, 1, 5		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	REST	0, 4
	N	35, 1, 4		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	35, 1, 5		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	REST	0, 4
	N	35, 1, 4		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	36, 1, 5		@ C#5
	N	36, 1, 2		@ C#5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	REST	0, 4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	N	31, 1, 5		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	REST	0, 4
	N	31, 1, 4		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	41, 1, 5		@ F#5
	N	40, 1, 2		@ F5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	REST	0, 4
	N	41, 1, 4		@ F#5
	N	33, 1, 4		@ A#4
	N	41, 1, 4		@ F#5
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	44, 1, 4		@ A5
	N	41, 1, 4		@ F#5
	REST	0, 4
	N	40, 1, 4		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	PAT_END

pat_080883A2:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 5		@ C5
	N	35, 1, 2		@ C5
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	40, 1, 5		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	PAT_END

pat_08088460:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	28, 1, 4		@ F4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	34, 1, 5		@ B4
	N	34, 1, 2		@ B4
	N	29, 1, 4		@ F#4
	N	31, 1, 4		@ G#4
	REST	0, 4
	N	34, 1, 4		@ B4
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	28, 1, 4		@ F4
	REST	0, 4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	34, 1, 5		@ B4
	N	34, 1, 2		@ B4
	N	29, 1, 4		@ F#4
	N	34, 1, 4		@ B4
	REST	0, 4
	N	34, 1, 4		@ B4
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	PAT_END

pat_08088521:				@ used by s7c7
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 4		@ C#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	34, 1, 4		@ B4
	N	36, 1, 4		@ C#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	REST	0, 4
	N	28, 1, 4		@ F4
	N	31, 1, 4		@ G#4
	N	28, 1, 4		@ F4
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	36, 1, 4		@ C#5
	REST	0, 4
	N	33, 1, 4		@ A#4
	N	34, 1, 4		@ B4
	N	36, 1, 4		@ C#5
	N	33, 1, 5		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	N	31, 1, 4		@ G#4
	REST	0, 4
	N	28, 1, 4		@ F4
	N	31, 1, 4		@ G#4
	N	28, 1, 4		@ F4
	PAT_END

pat_08088582:				@ used by s7c8
	N	48, 19, 10		@ C#6
	N	48, 19, 10		@ C#6
	N	48, 19, 10		@ C#6
	N	48, 19, 10		@ C#6
	PAT_END

pat_0808858F:				@ used by s8c1
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	PAT_END

pat_08088620:				@ used by s8c1
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	69, 9, 13		@ A#7
	N	72, 9, 13		@ C#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	72, 9, 13		@ C#8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	69, 9, 13		@ A#7
	N	72, 9, 13		@ C#8
	N	77, 9, 13		@ F#8
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	PAT_END

pat_08088741:				@ used by s8c1
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	67, 9, 13		@ G#7
	N	74, 9, 13		@ D#8
	N	79, 9, 13		@ G#8
	N	82, 9, 13		@ B8
	N	79, 9, 13		@ G#8
	N	74, 9, 13		@ D#8
	N	72, 9, 13		@ C#8
	N	76, 9, 13		@ F8
	N	79, 9, 13		@ G#8
	N	84, 9, 13		@ C#9
	N	79, 9, 13		@ G#8
	N	76, 9, 13		@ F8
	N	69, 9, 13		@ A#7
	N	72, 9, 13		@ C#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	72, 9, 13		@ C#8
	N	70, 9, 13		@ B7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	82, 9, 13		@ B8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	67, 9, 13		@ G#7
	N	70, 9, 13		@ B7
	N	74, 9, 13		@ D#8
	N	79, 9, 13		@ G#8
	N	74, 9, 13		@ D#8
	N	70, 9, 13		@ B7
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	73, 9, 13		@ D8
	N	76, 9, 13		@ F8
	N	81, 9, 13		@ A#8
	N	76, 9, 13		@ F8
	N	73, 9, 13		@ D8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	74, 9, 13		@ D#8
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	83, 9, 13		@ C9
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	83, 9, 13		@ C9
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	72, 9, 13		@ C#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	84, 9, 13		@ C#9
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	72, 9, 13		@ C#8
	N	77, 9, 13		@ F#8
	N	81, 9, 13		@ A#8
	N	84, 9, 13		@ C#9
	N	81, 9, 13		@ A#8
	N	77, 9, 13		@ F#8
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	83, 9, 13		@ C9
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	N	71, 9, 13		@ C8
	N	76, 9, 13		@ F8
	N	80, 9, 13		@ A8
	N	83, 9, 13		@ C9
	N	80, 9, 13		@ A8
	N	76, 9, 13		@ F8
	PAT_END

pat_080888F2:				@ used by s8c1
	N	69, 9, 13		@ A#7
	N	72, 9, 13		@ C#8
	N	64, 9, 13		@ F7
	N	64, 9, 13		@ F7
	N	71, 9, 13		@ C8
	N	68, 9, 13		@ A7
	N	64, 9, 13		@ F7
	N	69, 9, 13		@ A#7
	N	72, 9, 13		@ C#8
	N	65, 9, 13		@ F#7
	N	69, 9, 13		@ A#7
	N	74, 9, 13		@ D#8
	N	67, 9, 13		@ G#7
	N	71, 9, 13		@ C8
	N	62, 9, 13		@ D#7
	N	67, 9, 13		@ G#7
	N	71, 9, 13		@ C8
	N	62, 9, 13		@ D#7
	N	67, 9, 13		@ G#7
	N	71, 9, 13		@ C8
	N	62, 9, 13		@ D#7
	N	64, 9, 13		@ F7
	N	72, 9, 13		@ C#8
	N	64, 9, 13		@ F7
	N	64, 9, 13		@ F7
	N	69, 9, 13		@ A#7
	N	60, 9, 13		@ C#7
	N	64, 9, 13		@ F7
	N	68, 9, 13		@ A7
	N	71, 9, 13		@ C8
	N	64, 9, 13		@ F7
	N	69, 9, 13		@ A#7
	N	60, 9, 13		@ C#7
	N	65, 9, 13		@ F#7
	N	71, 9, 13		@ C8
	N	62, 9, 13		@ D#7
	N	64, 9, 13		@ F7
	N	69, 9, 13		@ A#7
	N	60, 9, 13		@ C#7
	N	64, 9, 13		@ F7
	N	69, 9, 13		@ A#7
	N	60, 9, 13		@ C#7
	N	64, 9, 13		@ F7
	N	68, 9, 13		@ A7
	N	59, 9, 13		@ C7
	N	64, 9, 13		@ F7
	N	68, 9, 13		@ A7
	N	59, 9, 13		@ C7
	PAT_END
pat_08088983:				@ not referenced by any sequence
	N	48, 30, 37		@ C#6
	N	48, 30, 37		@ C#6
	N	48, 30, 37		@ C#6
	N	48, 30, 37		@ C#6
	PAT_END

pat_08088990:				@ used by s8c4
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	46, 5, 13		@ B5
	PAT_END

pat_080889B5:				@ used by s8c5
	REST	0, 9
	REST	0, 4
	N	69, 22, 0		@ A#7
	N	71, 22, 0		@ C8
	N	73, 22, 0		@ D8
	N	74, 22, 0		@ D#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	76, 22, 13		@ F8
	N	77, 22, 14		@ F#8
	N	77, 22, 13		@ F#8
	N	79, 22, 14		@ G#8
	N	77, 22, 13		@ F#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 14		@ D#8
	N	74, 22, 13		@ D#8
	N	76, 22, 14		@ F8
	N	74, 22, 13		@ D#8
	N	73, 22, 14		@ D8
	N	73, 22, 13		@ D8
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	73, 22, 13		@ D8
	N	71, 22, 14		@ C8
	N	71, 22, 13		@ C8
	N	69, 22, 14		@ A#7
	N	68, 22, 13		@ A7
	N	69, 22, 14		@ A#7
	N	71, 22, 13		@ C8
	N	72, 22, 13		@ C#8
	N	71, 22, 13		@ C8
	N	69, 22, 13		@ A#7
	N	71, 22, 14		@ C8
	N	69, 22, 13		@ A#7
	N	68, 22, 4		@ A7
	N	69, 22, 0		@ A#7
	N	71, 22, 0		@ C8
	N	73, 22, 0		@ D8
	N	74, 22, 0		@ D#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	76, 22, 13		@ F8
	N	77, 22, 14		@ F#8
	N	77, 22, 13		@ F#8
	N	79, 22, 14		@ G#8
	N	77, 22, 13		@ F#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 14		@ D#8
	N	74, 22, 13		@ D#8
	N	76, 22, 14		@ F8
	N	74, 22, 13		@ D#8
	N	73, 22, 14		@ D8
	N	73, 22, 13		@ D8
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	73, 22, 13		@ D8
	N	71, 22, 14		@ C8
	N	71, 22, 13		@ C8
	N	69, 22, 14		@ A#7
	N	68, 22, 13		@ A7
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	69, 22, 13		@ A#7
	N	68, 22, 14		@ A7
	N	64, 22, 13		@ F7
	N	69, 22, 14		@ A#7
	N	69, 22, 13		@ A#7
	N	69, 22, 4		@ A#7
	N	69, 22, 0		@ A#7
	N	71, 22, 0		@ C8
	N	73, 22, 0		@ D8
	N	74, 22, 0		@ D#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	76, 22, 13		@ F8
	N	77, 22, 14		@ F#8
	N	77, 22, 13		@ F#8
	N	79, 22, 14		@ G#8
	N	77, 22, 13		@ F#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 14		@ D#8
	N	74, 22, 13		@ D#8
	N	76, 22, 14		@ F8
	N	74, 22, 13		@ D#8
	N	73, 22, 14		@ D8
	N	73, 22, 13		@ D8
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	73, 22, 13		@ D8
	N	71, 22, 14		@ C8
	N	71, 22, 13		@ C8
	N	69, 22, 14		@ A#7
	N	68, 22, 13		@ A7
	N	69, 22, 14		@ A#7
	N	71, 22, 13		@ C8
	N	72, 22, 13		@ C#8
	N	71, 22, 13		@ C8
	N	69, 22, 13		@ A#7
	N	71, 22, 14		@ C8
	N	69, 22, 13		@ A#7
	N	68, 22, 4		@ A7
	N	69, 22, 0		@ A#7
	N	71, 22, 0		@ C8
	N	73, 22, 0		@ D8
	N	74, 22, 0		@ D#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	76, 22, 13		@ F8
	N	77, 22, 14		@ F#8
	N	77, 22, 13		@ F#8
	N	79, 22, 14		@ G#8
	N	77, 22, 13		@ F#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 14		@ D#8
	N	74, 22, 13		@ D#8
	N	76, 22, 14		@ F8
	N	74, 22, 13		@ D#8
	N	73, 22, 14		@ D8
	N	73, 22, 13		@ D8
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	73, 22, 13		@ D8
	N	71, 22, 14		@ C8
	N	71, 22, 13		@ C8
	N	69, 22, 14		@ A#7
	N	68, 22, 13		@ A7
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	69, 22, 13		@ A#7
	N	68, 22, 14		@ A7
	N	64, 22, 13		@ F7
	N	69, 22, 14		@ A#7
	N	69, 22, 13		@ A#7
	N	69, 22, 6		@ A#7
	PAT_END

pat_08088B90:				@ used by s8c5
	N	69, 22, 13		@ A#7
	N	74, 22, 13		@ D#8
	N	73, 22, 13		@ D8
	N	74, 22, 14		@ D#8
	N	69, 22, 13		@ A#7
	N	67, 22, 14		@ G#7
	N	69, 22, 13		@ A#7
	N	65, 22, 14		@ F#7
	N	64, 22, 13		@ F7
	N	62, 22, 13		@ D#7
	N	61, 22, 13		@ D7
	N	62, 22, 13		@ D#7
	N	64, 22, 14		@ F7
	N	65, 22, 13		@ F#7
	N	64, 22, 14		@ F7
	N	69, 22, 13		@ A#7
	N	73, 22, 14		@ D8
	N	69, 22, 13		@ A#7
	N	74, 22, 13		@ D#8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	69, 22, 14		@ A#7
	N	67, 22, 13		@ G#7
	N	65, 22, 14		@ F#7
	N	64, 22, 13		@ F7
	N	65, 22, 14		@ F#7
	N	62, 22, 13		@ D#7
	N	61, 22, 13		@ D7
	N	62, 22, 13		@ D#7
	N	64, 22, 13		@ F7
	N	65, 22, 14		@ F#7
	N	64, 22, 13		@ F7
	N	62, 22, 14		@ D#7
	N	69, 22, 13		@ A#7
	N	74, 22, 6		@ D#8
	N	74, 22, 14		@ D#8
	N	76, 22, 13		@ F8
	N	77, 22, 13		@ F#8
	N	76, 22, 13		@ F8
	N	74, 22, 13		@ D#8
	N	70, 22, 14		@ B7
	N	72, 22, 13		@ C#8
	N	74, 22, 14		@ D#8
	N	70, 22, 13		@ B7
	N	72, 22, 14		@ C#8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 13		@ D#8
	N	72, 22, 13		@ C#8
	N	69, 22, 14		@ A#7
	N	70, 22, 13		@ B7
	N	72, 22, 14		@ C#8
	N	69, 22, 13		@ A#7
	N	70, 22, 14		@ B7
	N	72, 22, 13		@ C#8
	N	74, 22, 13		@ D#8
	N	72, 22, 13		@ C#8
	N	70, 22, 13		@ B7
	N	67, 22, 14		@ G#7
	N	69, 22, 13		@ A#7
	N	70, 22, 14		@ B7
	N	67, 22, 13		@ G#7
	N	69, 22, 13		@ A#7
	N	70, 22, 13		@ B7
	N	69, 22, 13		@ A#7
	N	67, 22, 13		@ G#7
	N	69, 22, 13		@ A#7
	N	67, 22, 13		@ G#7
	N	65, 22, 13		@ F#7
	N	67, 22, 13		@ G#7
	N	65, 22, 13		@ F#7
	N	64, 22, 13		@ F7
	N	65, 22, 13		@ F#7
	N	64, 22, 13		@ F7
	N	62, 22, 13		@ D#7
	N	65, 22, 13		@ F#7
	N	69, 22, 13		@ A#7
	N	74, 22, 14		@ D#8
	N	69, 22, 13		@ A#7
	N	62, 22, 13		@ D#7
	N	65, 22, 13		@ F#7
	N	69, 22, 13		@ A#7
	N	74, 22, 14		@ D#8
	N	69, 22, 13		@ A#7
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	71, 22, 13		@ C8
	N	76, 22, 14		@ F8
	N	71, 22, 13		@ C8
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	71, 22, 13		@ C8
	N	76, 22, 14		@ F8
	N	71, 22, 13		@ C8
	N	65, 22, 13		@ F#7
	N	69, 22, 13		@ A#7
	N	72, 22, 13		@ C#8
	N	77, 22, 14		@ F#8
	N	72, 22, 13		@ C#8
	N	65, 22, 13		@ F#7
	N	69, 22, 13		@ A#7
	N	72, 22, 13		@ C#8
	N	77, 22, 14		@ F#8
	N	72, 22, 13		@ C#8
	N	76, 22, 13		@ F8
	N	77, 22, 13		@ F#8
	N	76, 22, 13		@ F8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 13		@ D#8
	N	72, 22, 13		@ C#8
	N	74, 22, 13		@ D#8
	N	72, 22, 13		@ C#8
	N	71, 22, 13		@ C8
	N	72, 22, 13		@ C#8
	N	71, 22, 13		@ C8
	PAT_END

pat_08088CED:				@ used by s8c5
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	76, 22, 13		@ F8
	N	77, 22, 14		@ F#8
	N	77, 22, 13		@ F#8
	N	79, 22, 14		@ G#8
	N	77, 22, 13		@ F#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 14		@ D#8
	N	74, 22, 13		@ D#8
	N	76, 22, 14		@ F8
	N	74, 22, 13		@ D#8
	N	73, 22, 14		@ D8
	N	73, 22, 13		@ D8
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	73, 22, 13		@ D8
	N	71, 22, 14		@ C8
	N	71, 22, 13		@ C8
	N	69, 22, 14		@ A#7
	N	68, 22, 13		@ A7
	N	69, 22, 14		@ A#7
	N	71, 22, 13		@ C8
	N	72, 22, 13		@ C#8
	N	71, 22, 13		@ C8
	N	69, 22, 13		@ A#7
	N	71, 22, 14		@ C8
	N	69, 22, 13		@ A#7
	N	68, 22, 4		@ A7
	N	69, 22, 0		@ A#7
	N	71, 22, 0		@ C8
	N	73, 22, 0		@ D8
	N	74, 22, 0		@ D#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	76, 22, 13		@ F8
	N	77, 22, 14		@ F#8
	N	77, 22, 13		@ F#8
	N	79, 22, 14		@ G#8
	N	77, 22, 13		@ F#8
	N	76, 22, 14		@ F8
	N	76, 22, 13		@ F8
	N	73, 22, 13		@ D8
	N	74, 22, 13		@ D#8
	N	76, 22, 13		@ F8
	N	74, 22, 14		@ D#8
	N	74, 22, 13		@ D#8
	N	76, 22, 14		@ F8
	N	74, 22, 13		@ D#8
	N	73, 22, 14		@ D8
	N	73, 22, 13		@ D8
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	73, 22, 13		@ D8
	N	71, 22, 14		@ C8
	N	71, 22, 13		@ C8
	N	69, 22, 14		@ A#7
	N	68, 22, 13		@ A7
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	69, 22, 13		@ A#7
	N	68, 22, 14		@ A7
	N	64, 22, 13		@ F7
	N	69, 22, 14		@ A#7
	N	69, 22, 13		@ A#7
	N	69, 22, 6		@ A#7
	PAT_END

pat_08088DCC:				@ used by s8c5
	N	72, 22, 13		@ C#8
	N	64, 22, 13		@ F7
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	72, 22, 13		@ C#8
	N	64, 22, 13		@ F7
	N	69, 22, 13		@ A#7
	N	74, 22, 13		@ D#8
	N	65, 22, 13		@ F#7
	N	69, 22, 13		@ A#7
	N	71, 22, 13		@ C8
	N	62, 22, 13		@ D#7
	N	67, 22, 13		@ G#7
	N	71, 22, 13		@ C8
	N	62, 22, 13		@ D#7
	N	67, 22, 13		@ G#7
	N	71, 22, 13		@ C8
	N	62, 22, 13		@ D#7
	N	67, 22, 13		@ G#7
	N	72, 22, 13		@ C#8
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	69, 22, 13		@ A#7
	N	60, 22, 13		@ C#7
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	59, 22, 13		@ C7
	N	64, 22, 13		@ F7
	N	69, 22, 13		@ A#7
	N	60, 22, 13		@ C#7
	N	64, 22, 13		@ F7
	N	71, 22, 13		@ C8
	N	62, 22, 13		@ D#7
	N	65, 22, 13		@ F#7
	N	69, 22, 13		@ A#7
	N	60, 22, 13		@ C#7
	N	64, 22, 13		@ F7
	N	69, 22, 13		@ A#7
	N	60, 22, 13		@ C#7
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	59, 22, 13		@ C7
	N	64, 22, 13		@ F7
	N	68, 22, 13		@ A7
	N	59, 22, 13		@ C7
	N	64, 22, 13		@ F7
	PAT_END

pat_08088E5D:				@ used by s8c6
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	64, 13, 13		@ F7
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	71, 13, 13		@ C8
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	71, 13, 13		@ C8
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	PAT_END

pat_08088EEE:				@ used by s8c6
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	62, 13, 13		@ D#7
	N	65, 13, 13		@ F#7
	N	69, 13, 13		@ A#7
	N	65, 13, 13		@ F#7
	N	62, 13, 13		@ D#7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	62, 13, 13		@ D#7
	N	65, 13, 13		@ F#7
	N	69, 13, 13		@ A#7
	N	65, 13, 13		@ F#7
	N	62, 13, 13		@ D#7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	71, 13, 13		@ C8
	N	68, 13, 13		@ A7
	N	64, 13, 13		@ F7
	N	53, 13, 13		@ F#6
	N	60, 13, 13		@ C#7
	N	65, 13, 13		@ F#7
	N	69, 13, 13		@ A#7
	N	65, 13, 13		@ F#7
	N	60, 13, 13		@ C#7
	N	56, 13, 13		@ A6
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	64, 13, 13		@ F7
	N	59, 13, 13		@ C7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	62, 13, 13		@ D#7
	N	65, 13, 13		@ F#7
	N	69, 13, 13		@ A#7
	N	65, 13, 13		@ F#7
	N	62, 13, 13		@ D#7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	57, 13, 13		@ A#6
	N	62, 13, 13		@ D#7
	N	65, 13, 13		@ F#7
	N	69, 13, 13		@ A#7
	N	65, 13, 13		@ F#7
	N	62, 13, 13		@ D#7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	68, 13, 13		@ A7
	N	71, 13, 13		@ C8
	N	68, 13, 13		@ A7
	N	64, 13, 13		@ F7
	N	53, 13, 13		@ F#6
	N	60, 13, 13		@ C#7
	N	65, 13, 13		@ F#7
	N	56, 13, 13		@ A6
	N	59, 13, 13		@ C7
	N	64, 13, 13		@ F7
	N	57, 13, 13		@ A#6
	N	61, 13, 13		@ D7
	N	64, 13, 13		@ F7
	N	69, 13, 13		@ A#7
	N	64, 13, 13		@ F7
	N	61, 13, 13		@ D7
	PAT_END

pat_0808900F:				@ used by s8c6
	N	77, 13, 6		@ F#8
	N	74, 13, 6		@ D#8
	N	76, 13, 6		@ F8
	N	73, 13, 6		@ D8
	N	74, 13, 6		@ D#8
	N	69, 13, 6		@ A#7
	N	73, 13, 6		@ D8
	N	76, 13, 6		@ F8
	N	77, 13, 6		@ F#8
	N	74, 13, 6		@ D#8
	N	77, 13, 6		@ F#8
	N	74, 13, 6		@ D#8
	N	76, 13, 6		@ F8
	N	73, 13, 6		@ D8
	N	74, 13, 8		@ D#8
	N	77, 13, 6		@ F#8
	N	74, 13, 6		@ D#8
	N	77, 13, 6		@ F#8
	N	74, 13, 6		@ D#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	74, 13, 6		@ D#8
	N	70, 13, 6		@ B7
	N	74, 13, 6		@ D#8
	N	70, 13, 6		@ B7
	N	69, 13, 8		@ A#7
	N	73, 13, 6		@ D8
	N	76, 13, 6		@ F8
	N	77, 13, 8		@ F#8
	N	76, 13, 6		@ F8
	N	74, 13, 6		@ D#8
	N	76, 13, 8		@ F8
	N	74, 13, 6		@ D#8
	N	72, 13, 6		@ C#8
	N	74, 13, 8		@ D#8
	N	72, 13, 6		@ C#8
	N	71, 13, 6		@ C8
	N	72, 13, 8		@ C#8
	N	71, 13, 8		@ C8
	PAT_END

pat_0808908B:				@ used by s8c6
	N	64, 13, 6		@ F7
	N	69, 13, 14		@ A#7
	N	68, 13, 13		@ A7
	N	69, 13, 6		@ A#7
	N	71, 13, 6		@ C8
	N	72, 13, 15		@ C#8
	N	74, 13, 13		@ D#8
	N	76, 13, 13		@ F8
	N	74, 13, 6		@ D#8
	N	72, 13, 14		@ C#8
	N	71, 13, 13		@ C8
	N	72, 13, 15		@ C#8
	N	74, 13, 13		@ D#8
	N	72, 13, 13		@ C#8
	N	71, 13, 6		@ C8
	N	69, 13, 6		@ A#7
	N	72, 13, 15		@ C#8
	N	74, 13, 13		@ D#8
	N	72, 13, 13		@ C#8
	N	71, 13, 8		@ C8
	N	76, 13, 13		@ F8
	N	72, 13, 13		@ C#8
	N	69, 13, 13		@ A#7
	N	76, 13, 13		@ F8
	N	72, 13, 13		@ C#8
	N	69, 13, 13		@ A#7
	N	77, 13, 14		@ F#8
	N	76, 13, 14		@ F8
	N	74, 13, 13		@ D#8
	N	72, 13, 13		@ C#8
	N	74, 13, 15		@ D#8
	N	72, 13, 13		@ C#8
	N	71, 13, 13		@ C8
	N	76, 13, 6		@ F8
	N	74, 13, 6		@ D#8
	N	72, 13, 15		@ C#8
	N	71, 13, 13		@ C8
	N	69, 13, 13		@ A#7
	N	74, 13, 6		@ D#8
	N	72, 13, 6		@ C#8
	N	72, 13, 15		@ C#8
	N	74, 13, 13		@ D#8
	N	72, 13, 13		@ C#8
	N	71, 13, 8		@ C8
	PAT_END

pat_08089110:				@ used by s8c7
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	35, 1, 14		@ C5
	N	37, 1, 13		@ D5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	38, 1, 14		@ D#5
	N	35, 1, 13		@ C5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	40, 1, 14		@ F5
	N	37, 1, 13		@ D5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	37, 1, 14		@ D5
	N	37, 1, 13		@ D5
	N	35, 1, 14		@ C5
	N	35, 1, 13		@ C5
	PAT_END

pat_0808917A:				@ used by s8c7
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	41, 1, 14		@ F#5
	N	38, 1, 13		@ D#5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	37, 1, 14		@ D5
	N	38, 1, 13		@ D#5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	37, 1, 13		@ D5
	N	40, 1, 13		@ F5
	N	45, 1, 13		@ A#5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	35, 1, 13		@ C5
	N	32, 1, 13		@ A4
	N	35, 1, 13		@ C5
	N	41, 1, 14		@ F#5
	N	41, 1, 13		@ F#5
	N	36, 1, 13		@ C#5
	N	41, 1, 13		@ F#5
	N	36, 1, 13		@ C#5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	35, 1, 14		@ C5
	N	32, 1, 13		@ A4
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	41, 1, 14		@ F#5
	N	38, 1, 13		@ D#5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	41, 1, 14		@ F#5
	N	38, 1, 13		@ D#5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	33, 1, 6		@ A#4
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	44, 1, 14		@ A5
	N	40, 1, 13		@ F5
	N	41, 1, 14		@ F#5
	N	29, 1, 13		@ F#4
	N	40, 1, 14		@ F5
	N	28, 1, 13		@ F4
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	45, 1, 13		@ A#5
	N	40, 1, 13		@ F5
	N	37, 1, 13		@ D5
	PAT_END

pat_08089250:				@ used by s8c7
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	37, 1, 14		@ D5
	N	33, 1, 13		@ A#4
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	37, 1, 14		@ D5
	N	33, 1, 13		@ A#4
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	31, 1, 14		@ G#4
	N	31, 1, 13		@ G#4
	N	34, 1, 14		@ B4
	N	31, 1, 13		@ G#4
	N	36, 1, 14		@ C#5
	N	36, 1, 13		@ C#5
	N	48, 1, 13		@ C#6
	N	43, 1, 13		@ G#5
	N	40, 1, 13		@ F5
	N	29, 1, 14		@ F#4
	N	29, 1, 13		@ F#4
	N	33, 1, 14		@ A#4
	N	29, 1, 13		@ F#4
	N	34, 1, 14		@ B4
	N	34, 1, 13		@ B4
	N	38, 1, 13		@ D#5
	N	34, 1, 13		@ B4
	N	38, 1, 13		@ D#5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	34, 1, 14		@ B4
	N	38, 1, 13		@ D#5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	37, 1, 14		@ D5
	N	40, 1, 13		@ F5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	37, 1, 14		@ D5
	N	40, 1, 13		@ F5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	38, 1, 14		@ D#5
	N	38, 1, 13		@ D#5
	N	50, 1, 13		@ D#6
	N	45, 1, 13		@ A#5
	N	41, 1, 13		@ F#5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	47, 1, 14		@ C6
	N	44, 1, 13		@ A5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	47, 1, 14		@ C6
	N	44, 1, 13		@ A5
	N	41, 1, 14		@ F#5
	N	41, 1, 13		@ F#5
	N	48, 1, 14		@ C#6
	N	45, 1, 13		@ A#5
	N	41, 1, 14		@ F#5
	N	41, 1, 13		@ F#5
	N	48, 1, 14		@ C#6
	N	45, 1, 13		@ A#5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	47, 1, 14		@ C6
	N	44, 1, 13		@ A5
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	47, 1, 6		@ C6
	PAT_END

pat_0808938F:				@ used by s8c7
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	40, 1, 13		@ F5
	N	35, 1, 13		@ C5
	N	32, 1, 13		@ A4
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	38, 1, 14		@ D#5
	N	41, 1, 13		@ F#5
	N	31, 1, 14		@ G#4
	N	31, 1, 13		@ G#4
	N	43, 1, 13		@ G#5
	N	38, 1, 13		@ D#5
	N	34, 1, 13		@ B4
	N	31, 1, 14		@ G#4
	N	31, 1, 13		@ G#4
	N	40, 1, 14		@ F5
	N	35, 1, 13		@ C5
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	40, 1, 13		@ F5
	N	35, 1, 13		@ C5
	N	32, 1, 13		@ A4
	N	33, 1, 14		@ A#4
	N	33, 1, 13		@ A#4
	N	38, 1, 13		@ D#5
	N	33, 1, 13		@ A#4
	N	29, 1, 13		@ F#4
	N	45, 1, 14		@ A#5
	N	40, 1, 13		@ F5
	N	33, 1, 13		@ A#4
	N	40, 1, 13		@ F5
	N	33, 1, 13		@ A#4
	N	40, 1, 14		@ F5
	N	40, 1, 13		@ F5
	N	35, 1, 14		@ C5
	N	32, 1, 13		@ A4
	PAT_END

pat_080893FF:				@ used by s8c8
	N	48, 2, 14		@ C#6
	N	48, 9, 13		@ C#6
	N	48, 8, 13		@ C#6
	N	48, 7, 13		@ C#6
	N	48, 6, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 9, 13		@ C#6
	N	48, 8, 14		@ C#6
	N	48, 5, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 5, 13		@ C#6
	N	48, 6, 13		@ C#6
	N	48, 7, 13		@ C#6
	N	48, 8, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 9, 13		@ C#6
	N	48, 8, 13		@ C#6
	N	48, 7, 13		@ C#6
	N	48, 6, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 9, 13		@ C#6
	N	48, 8, 13		@ C#6
	N	48, 5, 13		@ C#6
	N	48, 6, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 9, 13		@ C#6
	N	48, 8, 14		@ C#6
	N	48, 7, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 5, 13		@ C#6
	N	48, 6, 13		@ C#6
	N	48, 7, 13		@ C#6
	N	48, 8, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 9, 13		@ C#6
	N	48, 10, 14		@ C#6
	N	48, 5, 13		@ C#6
	PAT_END

pat_0808946F:				@ used by s9c1
	REST	0, 4
	N	69, 29, 7		@ A#7
	N	74, 29, 2		@ D#8
	N	77, 29, 2		@ F#8
	N	81, 29, 22		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 7		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	72, 29, 4		@ C#8
	N	74, 29, 7		@ D#8
	N	77, 29, 2		@ F#8
	N	81, 29, 2		@ A#8
	N	86, 29, 7		@ D#9
	N	88, 29, 4		@ F9
	N	89, 29, 4		@ F#9
	N	88, 29, 4		@ F9
	N	86, 29, 4		@ D#9
	N	84, 29, 4		@ C#9
	N	86, 29, 4		@ D#9
	N	84, 29, 4		@ C#9
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	84, 29, 7		@ C#9
	N	86, 29, 4		@ D#9
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	84, 29, 2		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	PAT_END

pat_0808951B:				@ used by s9c1
	N	81, 29, 4		@ A#8
	N	74, 29, 2		@ D#8
	N	74, 29, 2		@ D#8
	N	74, 29, 4		@ D#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	74, 29, 2		@ D#8
	N	74, 29, 2		@ D#8
	N	74, 29, 4		@ D#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	74, 29, 2		@ D#8
	N	74, 29, 2		@ D#8
	N	74, 29, 4		@ D#8
	N	86, 29, 4		@ D#9
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	84, 29, 2		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 2		@ C#9
	N	82, 29, 2		@ B8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 4		@ F#8
	N	81, 29, 4		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 2		@ D#8
	N	72, 29, 4		@ C#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	81, 29, 2		@ A#8
	N	81, 29, 2		@ A#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	81, 29, 2		@ A#8
	N	81, 29, 2		@ A#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	84, 29, 2		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 2		@ C#9
	N	82, 29, 2		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 2		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 4		@ F8
	N	73, 29, 4		@ D8
	PAT_END

pat_08089618:				@ used by s9c1
	N	74, 29, 6		@ D#8
	N	86, 29, 4		@ D#9
	N	84, 29, 7		@ C#9
	N	82, 29, 4		@ B8
	N	84, 29, 2		@ C#9
	N	82, 29, 2		@ B8
	N	81, 29, 10		@ A#8
	N	72, 29, 6		@ C#8
	N	84, 29, 4		@ C#9
	N	82, 29, 7		@ B8
	N	81, 29, 4		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 10		@ G#8
	N	74, 29, 6		@ D#8
	N	82, 29, 4		@ B8
	N	81, 29, 6		@ A#8
	N	79, 29, 6		@ G#8
	N	77, 29, 2		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 6		@ F#8
	N	79, 29, 6		@ G#8
	N	81, 29, 7		@ A#8
	N	82, 29, 2		@ B8
	N	84, 29, 2		@ C#9
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	76, 29, 6		@ F8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 6		@ F8
	PAT_END

pat_0808968B:				@ used by s9c1
	N	74, 29, 6		@ D#8
	N	86, 29, 4		@ D#9
	N	74, 29, 4		@ D#8
	N	84, 29, 4		@ C#9
	N	74, 29, 4		@ D#8
	N	82, 29, 4		@ B8
	N	84, 29, 2		@ C#9
	N	82, 29, 2		@ B8
	N	81, 29, 22		@ A#8
	N	82, 29, 2		@ B8
	N	84, 29, 2		@ C#9
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	72, 29, 6		@ C#8
	N	84, 29, 4		@ C#9
	N	72, 29, 4		@ C#8
	N	82, 29, 4		@ B8
	N	72, 29, 4		@ C#8
	N	81, 29, 4		@ A#8
	N	82, 29, 2		@ B8
	N	81, 29, 2		@ A#8
	N	79, 29, 7		@ G#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 6		@ G#8
	N	74, 29, 6		@ D#8
	N	82, 29, 4		@ B8
	N	74, 29, 4		@ D#8
	N	81, 29, 6		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 6		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 6		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	77, 29, 7		@ F#8
	N	79, 29, 2		@ G#8
	N	77, 29, 2		@ F#8
	N	76, 29, 6		@ F8
	N	74, 29, 4		@ D#8
	N	76, 29, 6		@ F8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	72, 29, 6		@ C#8
	PAT_END

pat_0808971F:				@ used by s9c1
	N	74, 29, 9		@ D#8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 6		@ A#8
	N	83, 29, 4		@ C9
	N	84, 29, 6		@ C#9
	N	83, 29, 4		@ C9
	N	81, 29, 6		@ A#8
	N	79, 29, 4		@ G#8
	N	76, 29, 6		@ F8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 2		@ F#8
	N	76, 29, 2		@ F8
	N	74, 29, 9		@ D#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 6		@ A#8
	N	83, 29, 4		@ C9
	N	84, 29, 6		@ C#9
	N	83, 29, 4		@ C9
	N	81, 29, 6		@ A#8
	N	86, 29, 6		@ D#9
	N	84, 29, 4		@ C#9
	N	83, 29, 6		@ C9
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	83, 29, 4		@ C9
	N	81, 29, 22		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 6		@ A#8
	N	79, 29, 6		@ G#8
	N	77, 29, 6		@ F#8
	N	76, 29, 6		@ F8
	N	81, 29, 9		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 2		@ G#8
	N	77, 29, 6		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 6		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 6		@ F#8
	N	79, 29, 4		@ G#8
	N	76, 29, 6		@ F8
	N	72, 29, 7		@ C#8
	N	74, 29, 6		@ D#8
	N	76, 29, 22		@ F8
	N	77, 29, 4		@ F#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	74, 29, 19		@ D#8
	N	76, 29, 2		@ F8
	N	77, 29, 2		@ F#8
	N	79, 29, 6		@ G#8
	N	76, 29, 6		@ F8
	N	72, 29, 6		@ C#8
	N	76, 29, 6		@ F8
	N	74, 29, 22		@ D#8
	N	72, 29, 4		@ C#8
	N	74, 29, 4		@ D#8
	N	77, 29, 4		@ F#8
	N	74, 29, 10		@ D#8
	PAT_END

pat_080897E6:				@ used by s9c1
	N	86, 29, 22		@ D#9
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	84, 29, 2		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 4		@ C#9
	N	81, 29, 6		@ A#8
	N	77, 29, 7		@ F#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 22		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 4		@ G#8
	N	76, 29, 4		@ F8
	N	72, 29, 9		@ C#8
	N	74, 29, 6		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 6		@ F#8
	N	76, 29, 4		@ F8
	N	74, 29, 6		@ D#8
	N	76, 29, 6		@ F8
	N	72, 29, 6		@ C#8
	N	84, 29, 6		@ C#9
	N	82, 29, 6		@ B8
	N	81, 29, 22		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 4		@ A#8
	N	82, 29, 4		@ B8
	N	81, 29, 4		@ A#8
	N	79, 29, 4		@ G#8
	N	81, 29, 8		@ A#8
	N	86, 29, 22		@ D#9
	N	84, 29, 4		@ C#9
	N	82, 29, 4		@ B8
	N	84, 29, 2		@ C#9
	N	86, 29, 2		@ D#9
	N	84, 29, 4		@ C#9
	N	81, 29, 6		@ A#8
	N	77, 29, 7		@ F#8
	N	77, 29, 4		@ F#8
	N	79, 29, 4		@ G#8
	N	81, 29, 22		@ A#8
	N	79, 29, 4		@ G#8
	N	77, 29, 4		@ F#8
	N	79, 29, 2		@ G#8
	N	81, 29, 2		@ A#8
	N	79, 29, 4		@ G#8
	N	76, 29, 6		@ F8
	N	72, 29, 7		@ C#8
	N	72, 29, 6		@ C#8
	N	74, 29, 6		@ D#8
	N	76, 29, 4		@ F8
	N	77, 29, 6		@ F#8
	N	79, 29, 4		@ G#8
	N	77, 29, 6		@ F#8
	N	76, 29, 6		@ F8
	N	74, 29, 4		@ D#8
	N	72, 29, 6		@ C#8
	N	74, 29, 4		@ D#8
	N	76, 29, 4		@ F8
	N	72, 29, 4		@ C#8
	N	74, 29, 22		@ D#8
	N	76, 29, 4		@ F8
	N	74, 29, 4		@ D#8
	N	72, 29, 4		@ C#8
	N	74, 29, 9		@ D#8
	REST	0, 4
	PAT_END

pat_080898BF:				@ used by s9c4
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	PAT_END

pat_08089920:				@ used by s9c5
	N	69, 13, 7		@ A#7
	N	74, 13, 2		@ D#8
	N	77, 13, 2		@ F#8
	N	81, 13, 22		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 2		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 2		@ A#8
	N	79, 13, 2		@ G#8
	N	77, 13, 7		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	74, 13, 7		@ D#8
	N	77, 13, 2		@ F#8
	N	81, 13, 2		@ A#8
	N	86, 13, 7		@ D#9
	N	88, 13, 4		@ F9
	N	89, 13, 4		@ F#9
	N	88, 13, 4		@ F9
	N	86, 13, 4		@ D#9
	N	84, 13, 4		@ C#9
	N	86, 13, 4		@ D#9
	N	84, 13, 4		@ C#9
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	84, 13, 7		@ C#9
	N	86, 13, 4		@ D#9
	N	84, 13, 4		@ C#9
	N	82, 13, 4		@ B8
	N	81, 13, 2		@ A#8
	N	82, 13, 2		@ B8
	N	84, 13, 2		@ C#9
	N	86, 13, 2		@ D#9
	N	84, 13, 4		@ C#9
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	PAT_END

pat_080899C9:				@ used by s9c5
	N	81, 13, 4		@ A#8
	N	74, 13, 2		@ D#8
	N	74, 13, 2		@ D#8
	N	74, 13, 4		@ D#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	74, 13, 2		@ D#8
	N	74, 13, 2		@ D#8
	N	74, 13, 4		@ D#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	74, 13, 2		@ D#8
	N	74, 13, 2		@ D#8
	N	74, 13, 4		@ D#8
	N	86, 13, 4		@ D#9
	N	84, 13, 4		@ C#9
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	84, 13, 2		@ C#9
	N	86, 13, 2		@ D#9
	N	84, 13, 2		@ C#9
	N	82, 13, 2		@ B8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	84, 13, 4		@ C#9
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 2		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 2		@ A#8
	N	79, 13, 2		@ G#8
	N	77, 13, 4		@ F#8
	N	81, 13, 4		@ A#8
	N	79, 13, 2		@ G#8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 2		@ D#8
	N	72, 13, 4		@ C#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	81, 13, 2		@ A#8
	N	81, 13, 2		@ A#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	81, 13, 2		@ A#8
	N	81, 13, 2		@ A#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	84, 13, 2		@ C#9
	N	86, 13, 2		@ D#9
	N	84, 13, 2		@ C#9
	N	82, 13, 2		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 2		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 2		@ A#8
	N	79, 13, 2		@ G#8
	N	77, 13, 2		@ F#8
	N	79, 13, 2		@ G#8
	N	81, 13, 2		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 2		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 2		@ F#8
	N	79, 13, 2		@ G#8
	N	81, 13, 4		@ A#8
	N	79, 13, 2		@ G#8
	N	77, 13, 2		@ F#8
	N	76, 13, 4		@ F8
	N	73, 13, 4		@ D8
	PAT_END

pat_08089AC6:				@ used by s9c5
	N	74, 13, 6		@ D#8
	N	86, 13, 4		@ D#9
	N	84, 13, 7		@ C#9
	N	82, 13, 4		@ B8
	N	84, 13, 2		@ C#9
	N	82, 13, 2		@ B8
	N	81, 13, 10		@ A#8
	N	72, 13, 6		@ C#8
	N	84, 13, 4		@ C#9
	N	82, 13, 7		@ B8
	N	81, 13, 4		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 2		@ A#8
	N	79, 13, 10		@ G#8
	N	74, 13, 6		@ D#8
	N	82, 13, 4		@ B8
	N	81, 13, 6		@ A#8
	N	79, 13, 6		@ G#8
	N	77, 13, 2		@ F#8
	N	79, 13, 2		@ G#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 6		@ F#8
	N	79, 13, 6		@ G#8
	N	81, 13, 7		@ A#8
	N	82, 13, 2		@ B8
	N	84, 13, 2		@ C#9
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	74, 13, 4		@ D#8
	N	76, 13, 6		@ F8
	PAT_END

pat_08089B39:				@ used by s9c5
	N	74, 13, 6		@ D#8
	N	86, 13, 4		@ D#9
	N	74, 13, 4		@ D#8
	N	84, 13, 4		@ C#9
	N	74, 13, 4		@ D#8
	N	82, 13, 4		@ B8
	N	84, 13, 2		@ C#9
	N	82, 13, 2		@ B8
	N	81, 13, 22		@ A#8
	N	82, 13, 2		@ B8
	N	84, 13, 2		@ C#9
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	72, 13, 6		@ C#8
	N	84, 13, 4		@ C#9
	N	72, 13, 4		@ C#8
	N	82, 13, 4		@ B8
	N	72, 13, 4		@ C#8
	N	81, 13, 4		@ A#8
	N	82, 13, 2		@ B8
	N	81, 13, 2		@ A#8
	N	79, 13, 7		@ G#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 6		@ G#8
	N	74, 13, 6		@ D#8
	N	82, 13, 4		@ B8
	N	74, 13, 4		@ D#8
	N	81, 13, 6		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 6		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 6		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	77, 13, 7		@ F#8
	N	79, 13, 2		@ G#8
	N	77, 13, 2		@ F#8
	N	76, 13, 6		@ F8
	N	74, 13, 4		@ D#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	74, 13, 4		@ D#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 6		@ C#8
	PAT_END

pat_08089BCD:				@ used by s9c5
	N	74, 13, 9		@ D#8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 6		@ A#8
	N	83, 13, 4		@ C9
	N	84, 13, 6		@ C#9
	N	83, 13, 4		@ C9
	N	81, 13, 6		@ A#8
	N	79, 13, 4		@ G#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	74, 13, 4		@ D#8
	N	76, 13, 4		@ F8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	74, 13, 9		@ D#8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 6		@ A#8
	N	83, 13, 4		@ C9
	N	84, 13, 6		@ C#9
	N	83, 13, 4		@ C9
	N	81, 13, 6		@ A#8
	N	86, 13, 6		@ D#9
	N	84, 13, 4		@ C#9
	N	83, 13, 6		@ C9
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	83, 13, 4		@ C9
	N	81, 13, 22		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 6		@ A#8
	N	79, 13, 6		@ G#8
	N	77, 13, 6		@ F#8
	N	76, 13, 6		@ F8
	N	81, 13, 9		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 2		@ A#8
	N	79, 13, 2		@ G#8
	N	77, 13, 6		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 6		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 6		@ F#8
	N	79, 13, 4		@ G#8
	N	76, 13, 6		@ F8
	N	72, 13, 7		@ C#8
	N	74, 13, 6		@ D#8
	N	76, 13, 22		@ F8
	N	77, 13, 4		@ F#8
	N	76, 13, 4		@ F8
	N	72, 13, 4		@ C#8
	N	74, 13, 19		@ D#8
	N	76, 13, 2		@ F8
	N	77, 13, 2		@ F#8
	N	79, 13, 6		@ G#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	76, 13, 6		@ F8
	N	74, 13, 22		@ D#8
	N	72, 13, 4		@ C#8
	N	74, 13, 4		@ D#8
	N	77, 13, 4		@ F#8
	N	74, 13, 10		@ D#8
	PAT_END

pat_08089C94:				@ used by s9c5
	N	86, 13, 22		@ D#9
	N	84, 13, 4		@ C#9
	N	82, 13, 4		@ B8
	N	84, 13, 2		@ C#9
	N	86, 13, 2		@ D#9
	N	84, 13, 4		@ C#9
	N	81, 13, 6		@ A#8
	N	77, 13, 7		@ F#8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 22		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	79, 13, 2		@ G#8
	N	81, 13, 2		@ A#8
	N	79, 13, 4		@ G#8
	N	76, 13, 4		@ F8
	N	72, 13, 9		@ C#8
	N	74, 13, 6		@ D#8
	N	76, 13, 4		@ F8
	N	77, 13, 6		@ F#8
	N	76, 13, 4		@ F8
	N	74, 13, 6		@ D#8
	N	76, 13, 6		@ F8
	N	72, 13, 6		@ C#8
	N	84, 13, 6		@ C#9
	N	82, 13, 6		@ B8
	N	81, 13, 22		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	81, 13, 8		@ A#8
	N	86, 13, 22		@ D#9
	N	84, 13, 4		@ C#9
	N	82, 13, 4		@ B8
	N	84, 13, 2		@ C#9
	N	86, 13, 2		@ D#9
	N	84, 13, 4		@ C#9
	N	81, 13, 6		@ A#8
	N	77, 13, 7		@ F#8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 22		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	79, 13, 2		@ G#8
	N	81, 13, 2		@ A#8
	N	79, 13, 4		@ G#8
	N	76, 13, 6		@ F8
	N	72, 13, 7		@ C#8
	N	72, 13, 6		@ C#8
	N	74, 13, 6		@ D#8
	N	76, 13, 4		@ F8
	N	77, 13, 6		@ F#8
	N	79, 13, 4		@ G#8
	N	77, 13, 6		@ F#8
	N	76, 13, 6		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 6		@ C#8
	N	74, 13, 4		@ D#8
	N	76, 13, 4		@ F8
	N	72, 13, 4		@ C#8
	N	74, 13, 22		@ D#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	74, 13, 10		@ D#8
	PAT_END

pat_08089D6A:				@ used by s9c6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	60, 23, 6		@ C#7
	N	60, 23, 6		@ C#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	60, 23, 6		@ C#7
	N	60, 23, 6		@ C#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	60, 23, 6		@ C#7
	N	60, 23, 6		@ C#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	57, 23, 6		@ A#6
	N	57, 23, 6		@ A#6
	PAT_END

pat_08089DE3:				@ used by s9c6
	N	62, 24, 7		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 6		@ C#7
	N	60, 23, 6		@ C#7
	N	65, 23, 4		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 2		@ C#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	65, 23, 7		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	57, 23, 4		@ A#6
	N	57, 23, 2		@ A#6
	N	57, 23, 2		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 4		@ A#6
	PAT_END

pat_08089E86:				@ used by s9c6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 2		@ G#7
	N	67, 24, 2		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	65, 23, 7		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	PAT_END

pat_08089F26:				@ used by s9c6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	PAT_END

pat_08089FB7:				@ used by s9c6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	55, 23, 6		@ G#6
	N	55, 23, 4		@ G#6
	N	55, 23, 6		@ G#6
	N	55, 23, 4		@ G#6
	N	55, 23, 4		@ G#6
	N	55, 23, 4		@ G#6
	N	57, 23, 7		@ A#6
	N	57, 23, 6		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 6		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 6		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 4		@ A#6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	57, 24, 6		@ A#6
	N	57, 24, 4		@ A#6
	N	57, 24, 6		@ A#6
	N	57, 24, 4		@ A#6
	N	57, 24, 4		@ A#6
	N	57, 24, 4		@ A#6
	N	58, 23, 6		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 6		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 4		@ B6
	N	60, 23, 6		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	57, 24, 4		@ A#6
	N	57, 24, 4		@ A#6
	N	57, 24, 4		@ A#6
	N	57, 24, 4		@ A#6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	PAT_END

pat_0808A0D5:				@ used by s9c6
	N	58, 23, 6		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 6		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 4		@ B6
	N	65, 23, 7		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 7		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	58, 23, 6		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 6		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 4		@ B6
	N	60, 23, 7		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 2		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	57, 23, 7		@ A#6
	N	57, 23, 6		@ A#6
	N	57, 23, 2		@ A#6
	N	57, 23, 2		@ A#6
	N	57, 23, 4		@ A#6
	N	57, 23, 4		@ A#6
	N	58, 23, 6		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 6		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 4		@ B6
	N	65, 23, 7		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	62, 24, 7		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	60, 23, 7		@ C#7
	N	60, 23, 6		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 2		@ C#7
	N	60, 23, 4		@ C#7
	N	60, 23, 4		@ C#7
	N	58, 23, 7		@ B6
	N	58, 23, 6		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 2		@ B6
	N	58, 23, 4		@ B6
	N	58, 23, 4		@ B6
	N	60, 23, 6		@ C#7
	N	60, 23, 6		@ C#7
	N	57, 24, 4		@ A#6
	N	57, 24, 6		@ A#6
	N	57, 24, 4		@ A#6
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 2		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 6		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	N	62, 24, 4		@ D#7
	PAT_END

pat_0808A202:				@ used by s9c7
	N	38, 1, 7		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	38, 1, 8		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	36, 1, 6		@ C#5
	N	36, 1, 6		@ C#5
	N	29, 1, 7		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	41, 1, 8		@ F#5
	N	29, 1, 4		@ F#4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	36, 1, 6		@ C#5
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	36, 1, 6		@ C#5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	29, 1, 7		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	41, 1, 7		@ F#5
	N	29, 1, 4		@ F#4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	PAT_END

pat_0808A284:				@ used by s9c7
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 6		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 6		@ C#5
	N	36, 1, 6		@ C#5
	N	29, 1, 7		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 6		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	29, 1, 4		@ F#4
	N	36, 1, 6		@ C#5
	N	36, 1, 6		@ C#5
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	36, 1, 4		@ C#5
	N	31, 1, 4		@ G#4
	N	29, 1, 7		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	29, 1, 6		@ F#4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 4		@ A#5
	PAT_END

pat_0808A321:				@ used by s9c7
	N	38, 1, 7		@ D#5
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 6		@ C#5
	N	36, 1, 6		@ C#5
	N	29, 1, 7		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	41, 1, 6		@ F#5
	N	29, 1, 4		@ F#4
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	36, 1, 4		@ C#5
	N	31, 1, 4		@ G#4
	N	29, 1, 7		@ F#4
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	41, 1, 4		@ F#5
	N	40, 1, 4		@ F5
	N	41, 1, 6		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	29, 1, 4		@ F#4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	PAT_END

pat_0808A3C1:				@ used by s9c7
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	38, 1, 4		@ D#5
	N	36, 1, 7		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 6		@ C#5
	N	31, 1, 6		@ G#4
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 6		@ C#5
	N	43, 1, 7		@ G#5
	N	31, 1, 2		@ G#4
	N	34, 1, 2		@ B4
	N	38, 1, 4		@ D#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	31, 1, 6		@ G#4
	N	43, 1, 6		@ G#5
	N	31, 1, 6		@ G#4
	N	34, 1, 4		@ B4
	N	31, 1, 4		@ G#4
	N	34, 1, 4		@ B4
	N	41, 1, 7		@ F#5
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	41, 1, 7		@ F#5
	N	36, 1, 7		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	PAT_END

pat_0808A44C:				@ used by s9c7
	N	38, 1, 7		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 7		@ C#5
	N	31, 1, 2		@ G#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	36, 1, 4		@ C#5
	N	31, 1, 4		@ G#4
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	43, 1, 7		@ G#5
	N	38, 1, 2		@ D#5
	N	34, 1, 2		@ B4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	34, 1, 4		@ B4
	N	38, 1, 6		@ D#5
	N	43, 1, 4		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 6		@ B4
	N	31, 1, 4		@ G#4
	N	34, 1, 4		@ B4
	N	38, 1, 4		@ D#5
	N	38, 1, 7		@ D#5
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 6		@ D#5
	N	36, 1, 6		@ C#5
	N	31, 1, 4		@ G#4
	N	36, 1, 4		@ C#5
	N	40, 1, 6		@ F5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	PAT_END

pat_0808A4E3:				@ used by s9c7
	N	38, 1, 7		@ D#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 7		@ F#5
	N	36, 1, 6		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 7		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	38, 1, 7		@ D#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 7		@ F#5
	N	36, 1, 6		@ C#5
	N	41, 1, 6		@ F#5
	N	36, 1, 4		@ C#5
	N	43, 1, 6		@ G#5
	N	38, 1, 4		@ D#5
	N	35, 1, 6		@ C5
	N	31, 1, 4		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	33, 1, 7		@ A#4
	N	37, 1, 6		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 4		@ A#5
	N	40, 1, 4		@ F5
	N	33, 1, 6		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 4		@ A#5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 7		@ D#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	41, 1, 7		@ F#5
	N	36, 1, 6		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 7		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	33, 1, 7		@ A#4
	N	45, 1, 6		@ A#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	34, 1, 7		@ B4
	N	38, 1, 6		@ D#5
	N	41, 1, 4		@ F#5
	N	46, 1, 4		@ B5
	N	41, 1, 4		@ F#5
	N	36, 1, 7		@ C#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	38, 1, 7		@ D#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 7		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	PAT_END

pat_0808A5DA:				@ used by s9c7
	N	34, 1, 7		@ B4
	N	46, 1, 6		@ B5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	29, 1, 7		@ F#4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 7		@ D#5
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	36, 1, 7		@ C#5
	N	31, 1, 6		@ G#4
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	34, 1, 7		@ B4
	N	46, 1, 6		@ B5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	36, 1, 7		@ C#5
	N	43, 1, 6		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	29, 1, 7		@ F#4
	N	45, 1, 6		@ A#5
	N	41, 1, 4		@ F#5
	N	36, 1, 4		@ C#5
	N	29, 1, 4		@ F#4
	N	33, 1, 7		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 4		@ A#5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	N	34, 1, 7		@ B4
	N	46, 1, 6		@ B5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	41, 1, 4		@ F#5
	N	29, 1, 7		@ F#4
	N	41, 1, 6		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 7		@ D#5
	N	38, 1, 6		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	36, 1, 7		@ C#5
	N	31, 1, 6		@ G#4
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	34, 1, 7		@ B4
	N	41, 1, 6		@ F#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	38, 1, 4		@ D#5
	N	36, 1, 7		@ C#5
	N	33, 1, 6		@ A#4
	N	45, 1, 4		@ A#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	38, 1, 7		@ D#5
	N	38, 1, 6		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	38, 1, 6		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	38, 1, 6		@ D#5
	PAT_END

pat_0808A6CE:				@ used by s9c8
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 10, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 6, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 7, 4		@ C#6
	N	48, 5, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 9, 4		@ C#6
	N	48, 8, 4		@ C#6
	N	48, 10, 4		@ C#6
	PAT_END

pat_0808A72F:				@ used by s10c1
	N	69, 31, 8		@ A#7
	N	74, 31, 4		@ D#8
	N	76, 31, 4		@ F8
	N	77, 31, 8		@ F#8
	N	76, 31, 4		@ F8
	N	74, 31, 4		@ D#8
	N	76, 31, 7		@ F8
	N	74, 31, 4		@ D#8
	N	73, 31, 4		@ D8
	N	70, 31, 4		@ B7
	N	69, 31, 9		@ A#7
	N	69, 31, 8		@ A#7
	N	76, 31, 4		@ F8
	N	77, 31, 4		@ F#8
	N	79, 31, 8		@ G#8
	N	77, 31, 4		@ F#8
	N	76, 31, 4		@ F8
	N	77, 31, 7		@ F#8
	N	76, 31, 4		@ F8
	N	74, 31, 4		@ D#8
	N	73, 31, 4		@ D8
	N	74, 31, 9		@ D#8
	N	69, 31, 8		@ A#7
	N	74, 31, 4		@ D#8
	N	76, 31, 4		@ F8
	N	77, 31, 8		@ F#8
	N	76, 31, 4		@ F8
	N	74, 31, 4		@ D#8
	N	76, 31, 7		@ F8
	N	74, 31, 4		@ D#8
	N	73, 31, 4		@ D8
	N	70, 31, 4		@ B7
	N	69, 31, 9		@ A#7
	N	69, 31, 8		@ A#7
	N	76, 31, 4		@ F8
	N	77, 31, 4		@ F#8
	N	79, 31, 8		@ G#8
	N	81, 31, 4		@ A#8
	N	79, 31, 4		@ G#8
	N	77, 31, 7		@ F#8
	N	76, 31, 4		@ F8
	N	74, 31, 4		@ D#8
	N	73, 31, 4		@ D8
	N	74, 31, 9		@ D#8
	PAT_END

pat_0808A7B4:				@ used by s10c1
	N	69, 31, 8		@ A#7
	N	74, 31, 4		@ D#8
	N	73, 31, 4		@ D8
	N	74, 31, 6		@ D#8
	N	76, 31, 6		@ F8
	N	78, 31, 6		@ G8
	N	79, 31, 7		@ G#8
	N	74, 31, 4		@ D#8
	N	70, 31, 4		@ B7
	N	69, 31, 4		@ A#7
	N	67, 31, 6		@ G#7
	N	69, 31, 6		@ A#7
	N	70, 31, 6		@ B7
	N	72, 31, 8		@ C#8
	N	79, 31, 4		@ G#8
	N	78, 31, 4		@ G8
	N	79, 31, 6		@ G#8
	N	76, 31, 6		@ F8
	N	72, 31, 6		@ C#8
	N	77, 31, 7		@ F#8
	N	72, 31, 4		@ C#8
	N	69, 31, 4		@ A#7
	N	65, 31, 4		@ F#7
	N	69, 31, 6		@ A#7
	N	71, 31, 6		@ C8
	N	73, 31, 6		@ D8
	N	69, 31, 8		@ A#7
	N	74, 31, 4		@ D#8
	N	73, 31, 4		@ D8
	N	74, 31, 6		@ D#8
	N	76, 31, 6		@ F8
	N	78, 31, 6		@ G8
	N	79, 31, 7		@ G#8
	N	74, 31, 4		@ D#8
	N	70, 31, 4		@ B7
	N	69, 31, 4		@ A#7
	N	67, 31, 6		@ G#7
	N	69, 31, 6		@ A#7
	N	70, 31, 6		@ B7
	N	72, 31, 8		@ C#8
	N	79, 31, 4		@ G#8
	N	78, 31, 4		@ G8
	N	79, 31, 6		@ G#8
	N	76, 31, 6		@ F8
	N	72, 31, 6		@ C#8
	N	77, 31, 7		@ F#8
	N	72, 31, 4		@ C#8
	N	69, 31, 4		@ A#7
	N	65, 31, 4		@ F#7
	N	69, 31, 6		@ A#7
	N	71, 31, 6		@ C8
	N	73, 31, 6		@ D8
	N	74, 31, 8		@ D#8
	N	81, 31, 4		@ A#8
	N	80, 31, 4		@ A8
	N	79, 31, 6		@ G#8
	N	76, 31, 6		@ F8
	N	72, 31, 6		@ C#8
	PAT_END

pat_0808A863:				@ used by s10c1
	N	65, 29, 6		@ F#7
	N	67, 29, 6		@ G#7
	N	69, 29, 6		@ A#7
	N	70, 29, 6		@ B7
	N	72, 29, 6		@ C#8
	N	74, 29, 6		@ D#8
	N	72, 29, 2		@ C#8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	72, 29, 2		@ C#8
	N	67, 29, 29		@ G#7
	N	64, 29, 6		@ F7
	N	65, 29, 6		@ F#7
	N	67, 29, 6		@ G#7
	N	69, 29, 6		@ A#7
	N	70, 29, 6		@ B7
	N	72, 29, 6		@ C#8
	N	70, 29, 2		@ B7
	N	72, 29, 2		@ C#8
	N	70, 29, 2		@ B7
	N	69, 29, 2		@ A#7
	N	65, 29, 29		@ F#7
	N	62, 29, 6		@ D#7
	N	64, 29, 6		@ F7
	N	66, 29, 6		@ G7
	N	69, 29, 6		@ A#7
	N	69, 29, 6		@ A#7
	N	66, 29, 6		@ G7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	67, 29, 2		@ G#7
	N	66, 29, 2		@ G7
	N	62, 29, 10		@ D#7
	N	62, 29, 4		@ D#7
	N	64, 29, 2		@ F7
	N	62, 29, 2		@ D#7
	N	60, 29, 6		@ C#7
	N	62, 29, 6		@ D#7
	N	64, 29, 6		@ F7
	N	67, 29, 6		@ G#7
	N	67, 29, 6		@ G#7
	N	64, 29, 6		@ F7
	N	65, 29, 2		@ F#7
	N	67, 29, 2		@ G#7
	N	65, 29, 2		@ F#7
	N	64, 29, 2		@ F7
	N	60, 29, 29		@ C#7
	PAT_END

pat_0808A8F1:				@ used by s10c1
	N	65, 29, 6		@ F#7
	N	67, 29, 6		@ G#7
	N	69, 29, 6		@ A#7
	N	70, 29, 6		@ B7
	N	72, 29, 6		@ C#8
	N	74, 29, 6		@ D#8
	N	72, 29, 2		@ C#8
	N	74, 29, 2		@ D#8
	N	72, 29, 2		@ C#8
	N	70, 29, 2		@ B7
	N	67, 29, 29		@ G#7
	N	64, 29, 6		@ F7
	N	65, 29, 6		@ F#7
	N	67, 29, 6		@ G#7
	N	69, 29, 6		@ A#7
	N	70, 29, 6		@ B7
	N	72, 29, 6		@ C#8
	N	70, 29, 2		@ B7
	N	72, 29, 2		@ C#8
	N	70, 29, 2		@ B7
	N	69, 29, 2		@ A#7
	N	65, 29, 29		@ F#7
	N	72, 29, 6		@ C#8
	N	70, 29, 6		@ B7
	N	69, 29, 6		@ A#7
	N	66, 29, 6		@ G7
	N	67, 29, 6		@ G#7
	N	69, 29, 6		@ A#7
	N	67, 29, 2		@ G#7
	N	69, 29, 2		@ A#7
	N	67, 29, 2		@ G#7
	N	66, 29, 2		@ G7
	N	62, 29, 7		@ D#7
	N	67, 29, 4		@ G#7
	N	67, 29, 4		@ G#7
	N	65, 29, 4		@ F#7
	N	64, 29, 4		@ F7
	N	62, 29, 4		@ D#7
	N	60, 29, 4		@ C#7
	N	58, 29, 4		@ B6
	N	55, 29, 4		@ G#6
	N	58, 29, 4		@ B6
	N	60, 29, 4		@ C#7
	N	62, 29, 4		@ D#7
	N	64, 29, 4		@ F7
	N	67, 29, 4		@ G#7
	N	64, 29, 6		@ F7
	N	64, 29, 6		@ F7
	N	60, 29, 6		@ C#7
	N	60, 29, 4		@ C#7
	N	64, 29, 4		@ F7
	N	65, 29, 6		@ F#7
	N	67, 29, 6		@ G#7
	N	64, 29, 9		@ F7
	PAT_END

pat_0808A994:				@ used by s10c1
	N	69, 31, 9		@ A#7
	N	74, 31, 8		@ D#8
	N	76, 31, 6		@ F8
	N	77, 31, 8		@ F#8
	N	76, 31, 6		@ F8
	N	74, 31, 8		@ D#8
	N	76, 31, 6		@ F8
	N	77, 31, 8		@ F#8
	N	74, 31, 6		@ D#8
	N	73, 31, 8		@ D8
	N	74, 31, 6		@ D#8
	N	69, 31, 11		@ A#7
	N	67, 31, 8		@ G#7
	N	69, 31, 6		@ A#7
	N	70, 31, 8		@ B7
	N	74, 31, 6		@ D#8
	N	74, 31, 8		@ D#8
	N	76, 31, 6		@ F8
	N	77, 31, 8		@ F#8
	N	74, 31, 6		@ D#8
	N	76, 31, 9		@ F8
	N	71, 31, 8		@ C8
	N	76, 31, 6		@ F8
	N	73, 31, 11		@ D8
	PAT_END

pat_0808A9DD:				@ used by s10c1
	N	69, 31, 9		@ A#7
	N	74, 31, 8		@ D#8
	N	76, 31, 6		@ F8
	N	77, 31, 8		@ F#8
	N	76, 31, 6		@ F8
	N	74, 31, 8		@ D#8
	N	76, 31, 6		@ F8
	N	77, 31, 8		@ F#8
	N	74, 31, 6		@ D#8
	N	73, 31, 8		@ D8
	N	74, 31, 6		@ D#8
	N	69, 31, 9		@ A#7
	N	77, 31, 6		@ F#8
	N	76, 31, 6		@ F8
	N	74, 31, 6		@ D#8
	N	67, 31, 8		@ G#7
	N	69, 31, 6		@ A#7
	N	70, 31, 8		@ B7
	N	72, 31, 6		@ C#8
	N	74, 31, 9		@ D#8
	N	69, 31, 9		@ A#7
	N	67, 31, 6		@ G#7
	N	69, 31, 6		@ A#7
	N	70, 31, 6		@ B7
	N	69, 31, 8		@ A#7
	N	73, 31, 6		@ D8
	N	74, 31, 9		@ D#8
	N	76, 31, 9		@ F8
	PAT_END

pat_0808AA32:				@ used by s10c4
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	PAT_END

pat_0808AA87:				@ used by s10c4
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	42, 3, 4		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 4		@ G5
	PAT_END

pat_0808AAB2:				@ used by s10c5
	N	69, 25, 4		@ A#7
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	69, 25, 4		@ A#7
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	70, 25, 4		@ B7
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	62, 25, 4		@ D#7
	N	69, 25, 4		@ A#7
	N	62, 25, 4		@ D#7
	N	69, 25, 4		@ A#7
	N	61, 25, 4		@ D7
	N	67, 25, 4		@ G#7
	N	61, 25, 4		@ D7
	N	64, 25, 4		@ F7
	N	66, 25, 4		@ G7
	N	67, 25, 4		@ G#7
	N	61, 25, 4		@ D7
	N	64, 25, 4		@ F7
	N	67, 25, 4		@ G#7
	N	61, 25, 4		@ D7
	N	64, 25, 4		@ F7
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	61, 25, 4		@ D7
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	61, 25, 4		@ D7
	N	69, 25, 4		@ A#7
	N	57, 25, 4		@ A#6
	N	61, 25, 4		@ D7
	N	57, 25, 4		@ A#6
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	65, 25, 4		@ F#7
	N	57, 25, 4		@ A#6
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	57, 25, 4		@ A#6
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	57, 25, 4		@ A#6
	N	62, 25, 4		@ D#7
	N	69, 25, 4		@ A#7
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	69, 25, 4		@ A#7
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	70, 25, 4		@ B7
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	62, 25, 4		@ D#7
	N	69, 25, 4		@ A#7
	N	62, 25, 4		@ D#7
	N	69, 25, 4		@ A#7
	N	61, 25, 4		@ D7
	N	67, 25, 4		@ G#7
	N	61, 25, 4		@ D7
	N	64, 25, 4		@ F7
	N	66, 25, 4		@ G7
	N	67, 25, 4		@ G#7
	N	61, 25, 4		@ D7
	N	64, 25, 4		@ F7
	N	67, 25, 4		@ G#7
	N	61, 25, 4		@ D7
	N	64, 25, 4		@ F7
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	61, 25, 4		@ D7
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	61, 25, 4		@ D7
	N	69, 25, 4		@ A#7
	N	57, 25, 4		@ A#6
	N	61, 25, 4		@ D7
	N	57, 25, 4		@ A#6
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	67, 25, 4		@ G#7
	N	57, 25, 4		@ A#6
	N	65, 25, 4		@ F#7
	N	57, 25, 4		@ A#6
	N	62, 25, 4		@ D#7
	N	64, 25, 4		@ F7
	N	65, 25, 4		@ F#7
	N	57, 25, 4		@ A#6
	N	62, 25, 4		@ D#7
	N	65, 25, 4		@ F#7
	N	57, 25, 4		@ A#6
	N	62, 25, 4		@ D#7
	PAT_END

pat_0808ABD3:				@ used by s10c5
	N	62, 26, 6		@ D#7
	N	66, 26, 6		@ G7
	N	69, 26, 6		@ A#7
	N	74, 26, 6		@ D#8
	N	72, 26, 6		@ C#8
	N	69, 26, 6		@ A#7
	N	70, 26, 4		@ B7
	N	72, 26, 4		@ C#8
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	66, 26, 4		@ G7
	N	67, 26, 9		@ G#7
	N	60, 26, 6		@ C#7
	N	64, 26, 6		@ F7
	N	67, 26, 6		@ G#7
	N	72, 26, 6		@ C#8
	N	70, 26, 6		@ B7
	N	67, 26, 6		@ G#7
	N	69, 26, 4		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 6		@ F#7
	N	67, 26, 4		@ G#7
	N	68, 26, 4		@ A7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	64, 26, 4		@ F7
	N	62, 26, 6		@ D#7
	N	66, 26, 6		@ G7
	N	69, 26, 3		@ A#7
	N	62, 26, 2		@ D#7
	N	66, 26, 0		@ G7
	N	69, 26, 2		@ A#7
	N	74, 26, 6		@ D#8
	N	72, 26, 6		@ C#8
	N	69, 26, 6		@ A#7
	N	70, 26, 4		@ B7
	N	72, 26, 4		@ C#8
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	66, 26, 4		@ G7
	N	67, 26, 6		@ G#7
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	60, 26, 6		@ C#7
	N	64, 26, 6		@ F7
	N	67, 26, 6		@ G#7
	N	72, 26, 6		@ C#8
	N	70, 26, 6		@ B7
	N	67, 26, 6		@ G#7
	N	69, 26, 4		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 6		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	64, 26, 4		@ F7
	N	65, 26, 4		@ F#7
	N	64, 26, 4		@ F7
	N	62, 26, 4		@ D#7
	N	61, 26, 6		@ D7
	N	62, 26, 6		@ D#7
	N	64, 26, 6		@ F7
	N	65, 26, 6		@ F#7
	N	67, 26, 6		@ G#7
	N	65, 26, 6		@ F#7
	N	64, 26, 6		@ F7
	PAT_END

pat_0808ACA6:				@ used by s10c5
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	72, 26, 6		@ C#8
	N	74, 26, 6		@ D#8
	N	76, 26, 6		@ F8
	N	77, 26, 6		@ F#8
	N	76, 26, 2		@ F8
	N	77, 26, 2		@ F#8
	N	76, 26, 2		@ F8
	N	72, 26, 2		@ C#8
	N	70, 26, 29		@ B7
	N	67, 26, 6		@ G#7
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	72, 26, 6		@ C#8
	N	74, 26, 6		@ D#8
	N	76, 26, 6		@ F8
	N	74, 26, 2		@ D#8
	N	76, 26, 2		@ F8
	N	74, 26, 2		@ D#8
	N	72, 26, 2		@ C#8
	N	69, 26, 29		@ A#7
	N	66, 26, 6		@ G7
	N	67, 26, 6		@ G#7
	N	69, 26, 6		@ A#7
	N	74, 26, 6		@ D#8
	N	72, 26, 6		@ C#8
	N	69, 26, 6		@ A#7
	N	70, 26, 2		@ B7
	N	72, 26, 2		@ C#8
	N	70, 26, 2		@ B7
	N	69, 26, 2		@ A#7
	N	67, 26, 10		@ G#7
	N	65, 26, 4		@ F#7
	N	67, 26, 2		@ G#7
	N	65, 26, 2		@ F#7
	N	64, 26, 6		@ F7
	N	65, 26, 6		@ F#7
	N	67, 26, 6		@ G#7
	N	72, 26, 6		@ C#8
	N	70, 26, 6		@ B7
	N	67, 26, 6		@ G#7
	N	69, 26, 2		@ A#7
	N	70, 26, 2		@ B7
	N	69, 26, 2		@ A#7
	N	67, 26, 2		@ G#7
	N	65, 26, 29		@ F#7
	PAT_END

pat_0808AD34:				@ used by s10c5
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	72, 26, 6		@ C#8
	N	74, 26, 6		@ D#8
	N	76, 26, 6		@ F8
	N	77, 26, 6		@ F#8
	N	76, 26, 2		@ F8
	N	77, 26, 2		@ F#8
	N	76, 26, 2		@ F8
	N	74, 26, 2		@ D#8
	N	70, 26, 29		@ B7
	N	67, 26, 6		@ G#7
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	72, 26, 6		@ C#8
	N	74, 26, 6		@ D#8
	N	76, 26, 6		@ F8
	N	74, 26, 2		@ D#8
	N	76, 26, 2		@ F8
	N	74, 26, 2		@ D#8
	N	72, 26, 2		@ C#8
	N	69, 26, 29		@ A#7
	N	75, 26, 6		@ E8
	N	74, 26, 6		@ D#8
	N	72, 26, 6		@ C#8
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	72, 26, 6		@ C#8
	N	70, 26, 2		@ B7
	N	72, 26, 2		@ C#8
	N	70, 26, 2		@ B7
	N	69, 26, 2		@ A#7
	N	67, 26, 7		@ G#7
	N	69, 26, 4		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	64, 26, 4		@ F7
	N	62, 26, 4		@ D#7
	N	60, 26, 4		@ C#7
	N	62, 26, 4		@ D#7
	N	64, 26, 4		@ F7
	N	65, 26, 4		@ F#7
	N	67, 26, 4		@ G#7
	N	70, 26, 4		@ B7
	N	69, 26, 6		@ A#7
	N	67, 26, 6		@ G#7
	N	64, 26, 6		@ F7
	N	65, 26, 4		@ F#7
	N	67, 26, 4		@ G#7
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	69, 26, 9		@ A#7
	PAT_END

pat_0808ADD7:				@ used by s10c5
	N	62, 26, 6		@ D#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	64, 26, 4		@ F7
	N	62, 26, 6		@ D#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	70, 26, 6		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	64, 26, 4		@ F7
	N	62, 26, 6		@ D#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	74, 26, 6		@ D#8
	N	73, 26, 6		@ D8
	N	74, 26, 6		@ D#8
	N	69, 26, 7		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	69, 26, 9		@ A#7
	N	77, 26, 7		@ F#8
	N	76, 26, 4		@ F8
	N	74, 26, 4		@ D#8
	N	73, 26, 4		@ D8
	N	74, 26, 8		@ D#8
	N	76, 26, 6		@ F8
	N	69, 26, 7		@ A#7
	N	68, 26, 4		@ A7
	N	69, 26, 4		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 9		@ A#7
	N	64, 26, 7		@ F7
	N	66, 26, 4		@ G7
	N	68, 26, 4		@ A7
	N	69, 26, 4		@ A#7
	N	71, 26, 6		@ C8
	N	73, 26, 6		@ D8
	N	74, 26, 6		@ D#8
	N	73, 26, 4		@ D8
	N	74, 26, 4		@ D#8
	N	73, 26, 6		@ D8
	N	70, 26, 6		@ B7
	N	69, 26, 9		@ A#7
	PAT_END

pat_0808AE6E:				@ used by s10c5
	N	62, 26, 6		@ D#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	70, 26, 4		@ B7
	N	72, 26, 4		@ C#8
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	62, 26, 6		@ D#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	70, 26, 4		@ B7
	N	72, 26, 4		@ C#8
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	65, 26, 4		@ F#7
	N	62, 26, 6		@ D#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	74, 26, 6		@ D#8
	N	73, 26, 7		@ D8
	N	70, 26, 4		@ B7
	N	69, 26, 7		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	68, 26, 4		@ A7
	N	69, 26, 9		@ A#7
	N	77, 26, 6		@ F#8
	N	76, 26, 6		@ F8
	N	74, 26, 6		@ D#8
	N	73, 26, 6		@ D8
	N	74, 26, 6		@ D#8
	N	70, 26, 6		@ B7
	N	69, 26, 7		@ A#7
	N	70, 26, 4		@ B7
	N	69, 26, 4		@ A#7
	N	67, 26, 4		@ G#7
	N	69, 26, 6		@ A#7
	N	67, 26, 6		@ G#7
	N	65, 26, 6		@ F#7
	N	69, 26, 6		@ A#7
	N	67, 26, 6		@ G#7
	N	65, 26, 6		@ F#7
	N	64, 26, 6		@ F7
	N	65, 26, 7		@ F#7
	N	64, 26, 4		@ F7
	N	62, 26, 7		@ D#7
	N	64, 26, 4		@ F7
	N	65, 26, 6		@ F#7
	N	64, 26, 6		@ F7
	N	65, 26, 6		@ F#7
	N	67, 26, 6		@ G#7
	PAT_END

pat_0808AF11:				@ used by s10c6
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	69, 23, 6		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	69, 23, 6		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	PAT_END

pat_0808AFCC:				@ used by s10c6
	N	74, 23, 6		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	74, 23, 6		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	PAT_END

pat_0808B0A8:				@ used by s10c6
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	74, 23, 6		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	PAT_END

pat_0808B169:				@ used by s10c6
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	65, 23, 6		@ F#7
	N	74, 23, 6		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 4		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	74, 23, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 4		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	65, 23, 6		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 4		@ F#7
	N	65, 23, 6		@ F#7
	N	69, 23, 6		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	PAT_END

pat_0808B22D:				@ used by s10c6
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	76, 23, 6		@ F8
	N	76, 23, 4		@ F8
	N	76, 23, 4		@ F8
	N	76, 23, 4		@ F8
	N	76, 23, 4		@ F8
	N	76, 23, 6		@ F8
	N	76, 23, 6		@ F8
	N	76, 23, 6		@ F8
	N	69, 23, 6		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 4		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	PAT_END

pat_0808B2F4:				@ used by s10c6
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	67, 24, 4		@ G#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	69, 23, 6		@ A#7
	N	74, 24, 6		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	74, 24, 4		@ D#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	PAT_END

pat_0808B3BB:				@ used by s10c7
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	33, 1, 8		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	37, 1, 6		@ D5
	N	33, 1, 8		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	37, 1, 6		@ D5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	45, 1, 8		@ A#5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	N	33, 1, 6		@ A#4
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	33, 1, 8		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 6		@ A#5
	N	40, 1, 6		@ F5
	N	37, 1, 6		@ D5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	PAT_END

pat_0808B44C:				@ used by s10c7
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	42, 1, 6		@ G5
	N	45, 1, 6		@ A#5
	N	43, 1, 8		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	34, 1, 6		@ B4
	N	36, 1, 8		@ C#5
	N	40, 1, 4		@ F5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	41, 1, 7		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	29, 1, 4		@ F#4
	N	33, 1, 6		@ A#4
	N	35, 1, 6		@ C5
	N	37, 1, 6		@ D5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	42, 1, 6		@ G5
	N	45, 1, 6		@ A#5
	N	43, 1, 8		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	34, 1, 6		@ B4
	N	36, 1, 8		@ C#5
	N	40, 1, 4		@ F5
	N	41, 1, 4		@ F#5
	N	43, 1, 6		@ G#5
	N	40, 1, 6		@ F5
	N	36, 1, 6		@ C#5
	N	41, 1, 7		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	29, 1, 4		@ F#4
	N	33, 1, 6		@ A#4
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	38, 1, 7		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 4		@ D#5
	N	36, 1, 6		@ C#5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	PAT_END

pat_0808B4F8:				@ used by s10c7
	N	41, 1, 8		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	36, 1, 6		@ C#5
	N	29, 1, 6		@ F#4
	N	36, 1, 8		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	36, 1, 8		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	41, 1, 8		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	36, 1, 6		@ C#5
	N	29, 1, 6		@ F#4
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	42, 1, 6		@ G5
	N	45, 1, 6		@ A#5
	N	43, 1, 8		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	34, 1, 6		@ B4
	N	36, 1, 8		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	41, 1, 8		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	36, 1, 6		@ C#5
	N	29, 1, 6		@ F#4
	PAT_END

pat_0808B589:				@ used by s10c7
	N	41, 1, 8		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	36, 1, 6		@ C#5
	N	29, 1, 6		@ F#4
	N	36, 1, 8		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	36, 1, 8		@ C#5
	N	31, 1, 4		@ G#4
	N	33, 1, 4		@ A#4
	N	36, 1, 6		@ C#5
	N	40, 1, 6		@ F5
	N	43, 1, 6		@ G#5
	N	41, 1, 8		@ F#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	36, 1, 6		@ C#5
	N	29, 1, 6		@ F#4
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	42, 1, 6		@ G5
	N	45, 1, 6		@ A#5
	N	43, 1, 8		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	34, 1, 6		@ B4
	N	36, 1, 8		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	36, 1, 6		@ C#5
	N	43, 1, 6		@ G#5
	N	40, 1, 6		@ F5
	N	41, 1, 7		@ F#5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	29, 1, 4		@ F#4
	N	33, 1, 6		@ A#4
	N	35, 1, 6		@ C5
	N	37, 1, 6		@ D5
	PAT_END

pat_0808B61D:				@ used by s10c7
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 8		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	34, 1, 6		@ B4
	N	38, 1, 6		@ D#5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	43, 1, 7		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	34, 1, 6		@ B4
	N	38, 1, 7		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	41, 1, 6		@ F#5
	N	40, 1, 8		@ F5
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	44, 1, 6		@ A5
	N	40, 1, 6		@ F5
	N	45, 1, 7		@ A#5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	33, 1, 6		@ A#4
	N	35, 1, 6		@ C5
	N	37, 1, 6		@ D5
	PAT_END

pat_0808B6B7:				@ used by s10c7
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 8		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 8		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	33, 1, 6		@ A#4
	N	34, 1, 6		@ B4
	N	38, 1, 7		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 6		@ D#5
	N	43, 1, 8		@ G#5
	N	38, 1, 4		@ D#5
	N	34, 1, 4		@ B4
	N	31, 1, 8		@ G#4
	N	34, 1, 6		@ B4
	N	38, 1, 7		@ D#5
	N	33, 1, 4		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	41, 1, 6		@ F#5
	N	45, 1, 6		@ A#5
	N	38, 1, 6		@ D#5
	N	31, 1, 8		@ G#4
	N	34, 1, 4		@ B4
	N	38, 1, 4		@ D#5
	N	33, 1, 6		@ A#4
	N	37, 1, 6		@ D5
	N	40, 1, 6		@ F5
	N	38, 1, 7		@ D#5
	N	41, 1, 4		@ F#5
	N	45, 1, 6		@ A#5
	N	36, 1, 6		@ C#5
	N	38, 1, 6		@ D#5
	N	40, 1, 6		@ F5
	PAT_END

pat_0808B74B:				@ used by s10c8
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 3, 2		@ C#6
	PAT_END

pat_0808B77F:				@ used by s10c8
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 3, 2		@ C#6
	PAT_END

pat_0808B79B:				@ used by s11c1
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	72, 11, 2		@ C#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	72, 11, 2		@ C#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	72, 11, 2		@ C#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	72, 11, 2		@ C#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	72, 11, 2		@ C#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	72, 11, 2		@ C#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	72, 11, 2		@ C#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	72, 11, 2		@ C#8
	N	68, 11, 2		@ A7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	71, 11, 2		@ C8
	N	68, 11, 2		@ A7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	71, 11, 2		@ C8
	N	68, 11, 2		@ A7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	71, 11, 2		@ C8
	N	68, 11, 2		@ A7
	N	76, 11, 2		@ F8
	N	74, 11, 2		@ D#8
	N	76, 11, 2		@ F8
	N	71, 11, 2		@ C8
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	71, 11, 2		@ C8
	PAT_END

pat_0808B85C:				@ used by s11c1
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	65, 11, 2		@ F#7
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	65, 11, 2		@ F#7
	N	62, 11, 2		@ D#7
	N	70, 11, 2		@ B7
	N	69, 11, 2		@ A#7
	N	70, 11, 2		@ B7
	N	67, 11, 2		@ G#7
	N	70, 11, 2		@ B7
	N	65, 11, 2		@ F#7
	N	67, 11, 2		@ G#7
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	69, 11, 2		@ A#7
	N	61, 11, 2		@ D7
	N	69, 11, 2		@ A#7
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	69, 11, 2		@ A#7
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	61, 11, 2		@ D7
	N	69, 11, 2		@ A#7
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	65, 11, 2		@ F#7
	N	69, 11, 2		@ A#7
	N	64, 11, 2		@ F7
	N	69, 11, 2		@ A#7
	N	61, 11, 2		@ D7
	N	69, 11, 2		@ A#7
	PAT_END

pat_0808B91D:				@ used by s11c1
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	77, 11, 2		@ F#8
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	77, 11, 2		@ F#8
	N	74, 11, 2		@ D#8
	N	70, 11, 2		@ B7
	N	69, 11, 2		@ A#7
	N	70, 11, 2		@ B7
	N	79, 11, 2		@ G#8
	N	70, 11, 2		@ B7
	N	77, 11, 2		@ F#8
	N	79, 11, 2		@ G#8
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	73, 11, 2		@ D8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	73, 11, 2		@ D8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	73, 11, 2		@ D8
	N	69, 11, 2		@ A#7
	PAT_END

pat_0808B9DE:				@ used by s11c1
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	77, 11, 2		@ F#8
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	77, 11, 2		@ F#8
	N	74, 11, 2		@ D#8
	N	70, 11, 2		@ B7
	N	69, 11, 2		@ A#7
	N	70, 11, 2		@ B7
	N	79, 11, 2		@ G#8
	N	70, 11, 2		@ B7
	N	77, 11, 2		@ F#8
	N	79, 11, 2		@ G#8
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	73, 11, 2		@ D8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	69, 11, 2		@ A#7
	N	77, 11, 2		@ F#8
	N	69, 11, 2		@ A#7
	N	76, 11, 2		@ F8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	66, 11, 2		@ G7
	N	74, 11, 2		@ D#8
	N	67, 11, 2		@ G#7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	70, 11, 2		@ B7
	N	74, 11, 2		@ D#8
	N	72, 11, 2		@ C#8
	N	74, 11, 2		@ D#8
	N	70, 11, 2		@ B7
	N	74, 11, 2		@ D#8
	N	69, 11, 2		@ A#7
	N	74, 11, 2		@ D#8
	N	66, 11, 2		@ G7
	N	74, 11, 2		@ D#8
	PAT_END

pat_0808BA9F:				@ used by s11c1
	N	57, 11, 2		@ A#6
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	64, 11, 2		@ F7
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	56, 11, 2		@ A6
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	64, 11, 2		@ F7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 2		@ C#7
	N	57, 11, 2		@ A#6
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	64, 11, 2		@ F7
	N	60, 11, 2		@ C#7
	N	64, 11, 2		@ F7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	57, 11, 2		@ A#6
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	65, 11, 2		@ F#7
	N	62, 11, 2		@ D#7
	N	69, 11, 2		@ A#7
	N	67, 11, 2		@ G#7
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	64, 11, 2		@ F7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	57, 11, 2		@ A#6
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	56, 11, 2		@ A6
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	57, 11, 2		@ A#6
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	64, 11, 2		@ F7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	N	60, 11, 2		@ C#7
	N	56, 11, 2		@ A6
	N	65, 11, 2		@ F#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	64, 11, 2		@ F7
	N	62, 11, 2		@ D#7
	N	60, 11, 2		@ C#7
	N	59, 11, 2		@ C7
	PAT_END

pat_0808BB60:				@ used by s11c2
	N	45, 25, 12		@ A#5
	N	40, 23, 12		@ F5
	PAT_END

pat_0808BB67:				@ used by s11c2
	N	50, 25, 10		@ D#6
	N	43, 27, 8		@ G#5
	N	50, 25, 8		@ D#6
	N	45, 23, 10		@ A#5
	N	45, 22, 10		@ A#5
	PAT_END

pat_0808BB77:				@ used by s11c2
	N	50, 26, 10		@ D#6
	N	55, 25, 8		@ G#6
	N	50, 26, 8		@ D#6
	N	45, 24, 10		@ A#5
	N	45, 23, 10		@ A#5
	PAT_END

pat_0808BB87:				@ used by s11c2
	N	50, 26, 10		@ D#6
	N	55, 25, 8		@ G#6
	N	50, 26, 8		@ D#6
	N	45, 24, 10		@ A#5
	N	50, 23, 10		@ D#6
	PAT_END

pat_0808BB97:				@ used by s11c2
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	N	45, 25, 8		@ A#5
	N	38, 27, 8		@ D#5
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	N	45, 25, 8		@ A#5
	N	40, 23, 8		@ F5
	PAT_END

pat_0808BBB0:				@ used by s11c4
	N	49, 30, 7		@ D6
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 4		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 4		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	N	42, 3, 2		@ G5
	N	44, 4, 2		@ A5
	PAT_END

pat_0808BCEC:				@ used by s11c5
	N	57, 27, 8		@ A#6
	N	60, 27, 6		@ C#7
	N	64, 27, 6		@ F7
	N	65, 27, 8		@ F#7
	N	64, 27, 8		@ F7
	N	56, 27, 8		@ A6
	N	59, 27, 6		@ C7
	N	64, 27, 6		@ F7
	N	65, 27, 8		@ F#7
	N	64, 27, 8		@ F7
	N	57, 27, 8		@ A#6
	N	60, 27, 6		@ C#7
	N	64, 27, 6		@ F7
	N	65, 27, 8		@ F#7
	N	64, 27, 8		@ F7
	N	56, 27, 8		@ A6
	N	59, 27, 6		@ C7
	N	64, 27, 6		@ F7
	N	65, 27, 8		@ F#7
	N	64, 27, 8		@ F7
	N	53, 27, 8		@ F#6
	N	56, 27, 6		@ A6
	N	60, 27, 6		@ C#7
	N	61, 27, 8		@ D7
	N	60, 27, 6		@ C#7
	N	56, 27, 6		@ A6
	N	52, 27, 8		@ F6
	N	55, 27, 6		@ G#6
	N	60, 27, 6		@ C#7
	N	61, 27, 8		@ D7
	N	60, 27, 6		@ C#7
	N	56, 27, 6		@ A6
	N	53, 27, 8		@ F#6
	N	56, 27, 6		@ A6
	N	60, 27, 6		@ C#7
	N	61, 27, 8		@ D7
	N	60, 27, 6		@ C#7
	N	56, 27, 6		@ A6
	N	52, 27, 8		@ F6
	N	55, 27, 6		@ G#6
	N	60, 27, 6		@ C#7
	N	61, 27, 8		@ D7
	N	60, 27, 6		@ C#7
	N	56, 27, 6		@ A6
	PAT_END

pat_0808BD71:				@ used by s11c5
	N	58, 27, 7		@ B6
	N	61, 27, 2		@ D7
	N	65, 27, 2		@ F#7
	N	70, 27, 6		@ B7
	N	72, 27, 6		@ C#8
	N	73, 27, 8		@ D8
	N	72, 27, 6		@ C#8
	N	70, 27, 6		@ B7
	N	72, 27, 7		@ C#8
	N	70, 27, 2		@ B7
	N	69, 27, 2		@ A#7
	N	70, 27, 7		@ B7
	N	69, 27, 2		@ A#7
	N	67, 27, 2		@ G#7
	N	69, 27, 4		@ A#7
	N	67, 27, 4		@ G#7
	N	65, 27, 4		@ F#7
	N	63, 27, 4		@ E7
	N	65, 27, 4		@ F#7
	N	63, 27, 4		@ E7
	N	61, 27, 4		@ D7
	N	60, 27, 4		@ C#7
	N	63, 27, 6		@ E7
	N	71, 27, 4		@ C8
	N	70, 27, 4		@ B7
	N	71, 27, 6		@ C8
	N	68, 27, 6		@ A7
	N	67, 27, 6		@ G#7
	N	68, 27, 6		@ A7
	N	63, 27, 6		@ E7
	N	68, 27, 6		@ A7
	N	70, 27, 7		@ B7
	N	71, 27, 4		@ C8
	N	70, 27, 4		@ B7
	N	68, 27, 4		@ A7
	N	67, 27, 4		@ G#7
	N	65, 27, 4		@ F#7
	N	67, 27, 4		@ G#7
	N	68, 27, 4		@ A7
	N	70, 27, 4		@ B7
	N	68, 27, 4		@ A7
	N	67, 27, 4		@ G#7
	N	65, 27, 4		@ F#7
	N	63, 27, 6		@ E7
	N	66, 27, 4		@ G7
	N	73, 27, 4		@ D8
	N	71, 27, 4		@ C8
	N	73, 27, 4		@ D8
	N	69, 27, 4		@ A#7
	N	73, 27, 4		@ D8
	N	68, 27, 4		@ A7
	N	73, 27, 4		@ D8
	N	66, 27, 4		@ G7
	N	73, 27, 4		@ D8
	N	71, 27, 4		@ C8
	N	73, 27, 4		@ D8
	N	69, 27, 4		@ A#7
	N	73, 27, 4		@ D8
	N	71, 27, 4		@ C8
	N	73, 27, 4		@ D8
	N	61, 27, 4		@ D7
	N	65, 27, 4		@ F#7
	N	68, 27, 4		@ A7
	N	69, 27, 4		@ A#7
	N	71, 27, 4		@ C8
	N	69, 27, 4		@ A#7
	N	68, 27, 4		@ A7
	N	66, 27, 4		@ G7
	N	65, 27, 6		@ F#7
	N	63, 27, 6		@ E7
	N	65, 27, 6		@ F#7
	N	61, 27, 6		@ D7
	N	64, 27, 4		@ F7
	N	71, 27, 2		@ C8
	N	69, 27, 2		@ A#7
	N	71, 27, 4		@ C8
	N	67, 27, 4		@ G#7
	N	66, 27, 4		@ G7
	N	67, 27, 4		@ G#7
	N	64, 27, 4		@ F7
	N	63, 27, 4		@ E7
	N	64, 27, 4		@ F7
	N	59, 27, 4		@ C7
	N	63, 27, 4		@ E7
	N	64, 27, 4		@ F7
	N	66, 27, 4		@ G7
	N	67, 27, 4		@ G#7
	N	69, 27, 4		@ A#7
	N	67, 27, 4		@ G#7
	N	66, 27, 4		@ G7
	N	67, 27, 2		@ G#7
	N	66, 27, 2		@ G7
	N	64, 27, 4		@ F7
	N	63, 27, 4		@ E7
	N	64, 27, 4		@ F7
	N	66, 27, 4		@ G7
	N	64, 27, 4		@ F7
	N	63, 27, 4		@ E7
	N	64, 27, 10		@ F7
	PAT_END

pat_0808BE9B:				@ used by s11c5
	N	57, 27, 7		@ A#6
	N	59, 27, 2		@ C7
	N	60, 27, 2		@ C#7
	N	59, 27, 4		@ C7
	N	60, 27, 4		@ C#7
	N	62, 27, 4		@ D#7
	N	65, 27, 4		@ F#7
	N	64, 27, 6		@ F7
	N	69, 27, 6		@ A#7
	N	67, 27, 6		@ G#7
	N	65, 27, 6		@ F#7
	N	64, 27, 7		@ F7
	N	65, 27, 2		@ F#7
	N	64, 27, 2		@ F7
	N	62, 27, 4		@ D#7
	N	60, 27, 4		@ C#7
	N	59, 27, 4		@ C7
	N	62, 27, 4		@ D#7
	N	60, 27, 7		@ C#7
	N	59, 27, 2		@ C7
	N	57, 27, 2		@ A#6
	N	59, 27, 8		@ C7
	N	69, 27, 8		@ A#7
	N	67, 27, 24		@ G#7
	N	62, 27, 2		@ D#7
	N	64, 27, 2		@ F7
	N	65, 27, 2		@ F#7
	N	64, 27, 6		@ F7
	N	62, 27, 4		@ D#7
	N	60, 27, 4		@ C#7
	N	62, 27, 4		@ D#7
	N	64, 27, 4		@ F7
	N	65, 27, 4		@ F#7
	N	62, 27, 4		@ D#7
	N	64, 27, 2		@ F7
	N	65, 27, 2		@ F#7
	N	64, 27, 2		@ F7
	N	62, 27, 2		@ D#7
	N	60, 27, 4		@ C#7
	N	64, 27, 4		@ F7
	N	62, 27, 4		@ D#7
	N	60, 27, 4		@ C#7
	N	59, 27, 4		@ C7
	N	62, 27, 4		@ D#7
	N	60, 27, 5		@ C#7
	N	59, 27, 2		@ C7
	N	57, 27, 4		@ A#6
	N	60, 27, 4		@ C#7
	N	65, 27, 6		@ F#7
	N	64, 27, 6		@ F7
	N	69, 27, 8		@ A#7
	N	67, 27, 5		@ G#7
	N	65, 27, 2		@ F#7
	N	64, 27, 4		@ F7
	N	62, 27, 4		@ D#7
	N	64, 27, 2		@ F7
	N	65, 27, 2		@ F#7
	N	64, 27, 2		@ F7
	N	62, 27, 2		@ D#7
	N	60, 27, 4		@ C#7
	N	64, 27, 4		@ F7
	N	62, 27, 5		@ D#7
	N	64, 27, 2		@ F7
	N	65, 27, 4		@ F#7
	N	62, 27, 4		@ D#7
	N	64, 27, 2		@ F7
	N	65, 27, 2		@ F#7
	N	64, 27, 2		@ F7
	N	62, 27, 2		@ D#7
	N	60, 27, 4		@ C#7
	N	62, 27, 2		@ D#7
	N	64, 27, 2		@ F7
	N	62, 27, 4		@ D#7
	N	60, 27, 4		@ C#7
	N	59, 27, 4		@ C7
	N	64, 27, 4		@ F7
	N	60, 27, 7		@ C#7
	N	59, 27, 2		@ C7
	N	57, 27, 2		@ A#6
	N	59, 27, 8		@ C7
	N	57, 27, 4		@ A#6
	N	64, 27, 2		@ F7
	N	63, 27, 2		@ E7
	N	64, 27, 4		@ F7
	N	69, 27, 4		@ A#7
	N	67, 27, 5		@ G#7
	N	65, 27, 2		@ F#7
	N	64, 27, 4		@ F7
	N	62, 27, 4		@ D#7
	N	64, 27, 2		@ F7
	N	65, 27, 2		@ F#7
	N	67, 27, 2		@ G#7
	N	65, 27, 2		@ F#7
	N	64, 27, 4		@ F7
	N	62, 27, 2		@ D#7
	N	60, 27, 2		@ C#7
	N	62, 27, 6		@ D#7
	N	65, 27, 6		@ F#7
	N	64, 27, 7		@ F7
	N	62, 27, 2		@ D#7
	N	60, 27, 2		@ C#7
	N	62, 27, 6		@ D#7
	N	59, 27, 6		@ C7
	N	57, 27, 8		@ A#6
	N	64, 27, 8		@ F7
	PAT_END

pat_0808BFD7:				@ used by s11c6
	N	69, 14, 7		@ A#7
	N	64, 14, 2		@ F7
	N	67, 14, 2		@ G#7
	N	69, 14, 6		@ A#7
	N	72, 14, 6		@ C#8
	N	77, 14, 6		@ F#8
	N	76, 14, 6		@ F8
	N	74, 14, 6		@ D#8
	N	72, 14, 6		@ C#8
	N	74, 14, 24		@ D#8
	N	76, 14, 2		@ F8
	N	74, 14, 2		@ D#8
	N	72, 14, 2		@ C#8
	N	71, 14, 6		@ C8
	N	69, 14, 6		@ A#7
	N	68, 14, 6		@ A7
	N	69, 14, 6		@ A#7
	N	71, 14, 6		@ C8
	N	74, 14, 6		@ D#8
	N	69, 14, 7		@ A#7
	N	67, 14, 2		@ G#7
	N	69, 14, 2		@ A#7
	N	72, 14, 6		@ C#8
	N	76, 14, 6		@ F8
	N	77, 14, 6		@ F#8
	N	76, 14, 6		@ F8
	N	74, 14, 6		@ D#8
	N	72, 14, 6		@ C#8
	N	71, 14, 7		@ C8
	N	72, 14, 2		@ C#8
	N	74, 14, 2		@ D#8
	N	68, 14, 7		@ A7
	N	69, 14, 2		@ A#7
	N	71, 14, 2		@ C8
	N	64, 14, 6		@ F7
	N	68, 14, 6		@ A7
	N	71, 14, 6		@ C8
	N	74, 14, 6		@ D#8
	N	65, 14, 7		@ F#7
	N	68, 14, 2		@ A7
	N	72, 14, 2		@ C#8
	N	77, 14, 6		@ F#8
	N	75, 14, 6		@ E8
	N	73, 14, 8		@ D8
	N	72, 14, 8		@ C#8
	N	64, 14, 7		@ F7
	N	67, 14, 2		@ G#7
	N	72, 14, 2		@ C#8
	N	76, 14, 6		@ F8
	N	73, 14, 6		@ D8
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	65, 14, 7		@ F#7
	N	68, 14, 2		@ A7
	N	72, 14, 2		@ C#8
	N	73, 14, 6		@ D8
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	68, 14, 6		@ A7
	N	67, 14, 6		@ G#7
	N	65, 14, 6		@ F#7
	N	64, 14, 7		@ F7
	N	67, 14, 2		@ G#7
	N	72, 14, 2		@ C#8
	N	73, 14, 6		@ D8
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	68, 14, 6		@ A7
	N	67, 14, 6		@ G#7
	N	64, 14, 6		@ F7
	PAT_END

pat_0808C0B0:				@ used by s11c6
	N	62, 14, 6		@ D#7
	N	65, 14, 6		@ F#7
	N	69, 14, 6		@ A#7
	N	70, 14, 6		@ B7
	N	69, 14, 6		@ A#7
	N	65, 14, 6		@ F#7
	N	64, 14, 6		@ F7
	N	62, 14, 6		@ D#7
	N	61, 14, 6		@ D7
	N	64, 14, 6		@ F7
	N	67, 14, 6		@ G#7
	N	68, 14, 6		@ A7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	64, 14, 6		@ F7
	N	61, 14, 6		@ D7
	PAT_END

pat_0808C0E1:				@ used by s11c6
	N	65, 14, 6		@ F#7
	N	69, 14, 6		@ A#7
	N	74, 14, 6		@ D#8
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	65, 14, 6		@ F#7
	N	64, 14, 6		@ F7
	N	67, 14, 6		@ G#7
	N	69, 14, 6		@ A#7
	N	73, 14, 6		@ D8
	N	70, 14, 6		@ B7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	64, 14, 6		@ F7
	PAT_END

pat_0808C112:				@ used by s11c6
	N	65, 14, 6		@ F#7
	N	69, 14, 6		@ A#7
	N	74, 14, 6		@ D#8
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	65, 14, 6		@ F#7
	N	64, 14, 6		@ F7
	N	67, 14, 6		@ G#7
	N	69, 14, 6		@ A#7
	N	73, 14, 6		@ D8
	N	74, 14, 6		@ D#8
	N	72, 14, 6		@ C#8
	N	70, 14, 6		@ B7
	N	69, 14, 6		@ A#7
	PAT_END

pat_0808C143:				@ used by s11c6
	N	57, 14, 6		@ A#6
	N	60, 14, 6		@ C#7
	N	59, 14, 6		@ C7
	N	62, 14, 6		@ D#7
	N	60, 14, 6		@ C#7
	N	64, 14, 6		@ F7
	N	62, 14, 6		@ D#7
	N	65, 14, 6		@ F#7
	N	64, 14, 6		@ F7
	N	60, 14, 6		@ C#7
	N	62, 14, 6		@ D#7
	N	59, 14, 6		@ C7
	N	60, 14, 6		@ C#7
	N	57, 14, 6		@ A#6
	N	59, 14, 6		@ C7
	N	56, 14, 6		@ A6
	PAT_END

pat_0808C174:				@ used by s11c7
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 5
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 2		@ A#4
	REST	0, 7
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 5
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 5		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 4
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	REST	0, 24
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	REST	0, 2
	REST	0, 6
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	REST	0, 5
	N	32, 1, 4		@ A4
	N	32, 1, 6		@ A4
	N	32, 1, 6		@ A4
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 5
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 23		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 5
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	REST	0, 5
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	REST	0, 5
	N	32, 1, 4		@ A4
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	REST	0, 2
	REST	0, 6
	N	32, 1, 2		@ A4
	N	32, 1, 4		@ A4
	REST	0, 5
	N	32, 1, 4		@ A4
	N	32, 1, 6		@ A4
	N	32, 1, 4		@ A4
	REST	0, 4
	PAT_END

pat_0808C220:				@ used by s11c7
	N	33, 1, 7		@ A#4
	N	28, 1, 2		@ F4
	N	31, 1, 2		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	36, 1, 2		@ C#5
	N	40, 1, 2		@ F5
	N	45, 1, 4		@ A#5
	N	45, 1, 6		@ A#5
	N	43, 1, 2		@ G#5
	N	45, 1, 2		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	32, 1, 7		@ A4
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	40, 1, 6		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 2		@ F5
	N	44, 1, 4		@ A5
	N	44, 1, 6		@ A5
	N	40, 1, 2		@ F5
	N	44, 1, 2		@ A5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	32, 1, 4		@ A4
	N	33, 1, 7		@ A#4
	N	28, 1, 2		@ F4
	N	31, 1, 2		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	36, 1, 2		@ C#5
	N	40, 1, 2		@ F5
	N	45, 1, 4		@ A#5
	N	45, 1, 6		@ A#5
	N	43, 1, 2		@ G#5
	N	45, 1, 2		@ A#5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	33, 1, 4		@ A#4
	N	32, 1, 7		@ A4
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	40, 1, 6		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 2		@ F5
	N	44, 1, 4		@ A5
	N	44, 1, 6		@ A5
	N	40, 1, 2		@ F5
	N	44, 1, 2		@ A5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	32, 1, 4		@ A4
	N	29, 1, 7		@ F#4
	N	32, 1, 2		@ A4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	41, 1, 6		@ F#5
	N	40, 1, 2		@ F5
	N	41, 1, 2		@ F#5
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	32, 1, 4		@ A4
	N	29, 1, 4		@ F#4
	N	29, 1, 4		@ F#4
	N	32, 1, 4		@ A4
	N	29, 1, 4		@ F#4
	N	40, 1, 7		@ F5
	N	36, 1, 2		@ C#5
	N	31, 1, 2		@ G#4
	N	43, 1, 4		@ G#5
	N	43, 1, 6		@ G#5
	N	40, 1, 2		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 6		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	31, 1, 4		@ G#4
	N	40, 1, 4		@ F5
	N	29, 1, 7		@ F#4
	N	32, 1, 2		@ A4
	N	36, 1, 2		@ C#5
	N	41, 1, 4		@ F#5
	N	41, 1, 6		@ F#5
	N	40, 1, 2		@ F5
	N	41, 1, 2		@ F#5
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	32, 1, 4		@ A4
	N	29, 1, 4		@ F#4
	N	29, 1, 4		@ F#4
	N	32, 1, 4		@ A4
	N	29, 1, 4		@ F#4
	N	40, 1, 7		@ F5
	N	36, 1, 2		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 6		@ F5
	N	36, 1, 2		@ C#5
	N	40, 1, 2		@ F5
	N	31, 1, 7		@ G#4
	N	36, 1, 2		@ C#5
	N	40, 1, 2		@ F5
	N	43, 1, 4		@ G#5
	N	40, 1, 4		@ F5
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	PAT_END

pat_0808C380:				@ used by s11c7
	N	38, 1, 7		@ D#5
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	41, 1, 4		@ F#5
	N	41, 1, 6		@ F#5
	N	38, 1, 2		@ D#5
	N	41, 1, 2		@ F#5
	N	45, 1, 4		@ A#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	41, 1, 4		@ F#5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	38, 1, 4		@ D#5
	N	33, 1, 7		@ A#4
	N	37, 1, 2		@ D5
	N	40, 1, 2		@ F5
	N	45, 1, 4		@ A#5
	N	45, 1, 6		@ A#5
	N	43, 1, 2		@ G#5
	N	45, 1, 2		@ A#5
	N	40, 1, 4		@ F5
	N	40, 1, 6		@ F5
	N	37, 1, 2		@ D5
	N	40, 1, 2		@ F5
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	36, 1, 7		@ C#5
	N	31, 1, 2		@ G#4
	N	36, 1, 2		@ C#5
	N	39, 1, 4		@ E5
	N	39, 1, 6		@ E5
	N	36, 1, 2		@ C#5
	N	39, 1, 2		@ E5
	N	43, 1, 4		@ G#5
	N	41, 1, 4		@ F#5
	N	39, 1, 4		@ E5
	N	38, 1, 4		@ D#5
	N	39, 1, 6		@ E5
	N	36, 1, 6		@ C#5
	N	43, 1, 7		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	31, 1, 6		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	43, 1, 4		@ G#5
	N	43, 1, 6		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	31, 1, 7		@ G#4
	N	34, 1, 7		@ B4
	N	37, 1, 2		@ D5
	N	41, 1, 2		@ F#5
	N	46, 1, 4		@ B5
	N	46, 1, 6		@ B5
	N	45, 1, 2		@ A#5
	N	46, 1, 2		@ B5
	N	41, 1, 4		@ F#5
	N	41, 1, 6		@ F#5
	N	39, 1, 2		@ E5
	N	41, 1, 2		@ F#5
	N	37, 1, 4		@ D5
	N	34, 1, 4		@ B4
	N	37, 1, 4		@ D5
	N	34, 1, 4		@ B4
	N	41, 1, 7		@ F#5
	N	36, 1, 2		@ C#5
	N	41, 1, 2		@ F#5
	N	45, 1, 4		@ A#5
	N	45, 1, 6		@ A#5
	N	41, 1, 2		@ F#5
	N	45, 1, 2		@ A#5
	N	48, 1, 4		@ C#6
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	45, 1, 4		@ A#5
	N	41, 1, 4		@ F#5
	N	39, 1, 4		@ E5
	N	37, 1, 4		@ D5
	N	36, 1, 4		@ C#5
	N	32, 1, 7		@ A4
	N	39, 1, 2		@ E5
	N	44, 1, 2		@ A5
	N	46, 1, 4		@ B5
	N	44, 1, 6		@ A5
	N	39, 1, 2		@ E5
	N	35, 1, 2		@ C5
	N	32, 1, 4		@ A4
	N	32, 1, 6		@ A4
	N	39, 1, 2		@ E5
	N	44, 1, 2		@ A5
	N	46, 1, 4		@ B5
	N	44, 1, 4		@ A5
	N	39, 1, 4		@ E5
	N	44, 1, 4		@ A5
	N	39, 1, 7		@ E5
	N	34, 1, 2		@ B4
	N	39, 1, 2		@ E5
	N	43, 1, 4		@ G#5
	N	46, 1, 6		@ B5
	N	43, 1, 2		@ G#5
	N	46, 1, 2		@ B5
	N	43, 1, 4		@ G#5
	N	41, 1, 6		@ F#5
	N	43, 1, 4		@ G#5
	N	39, 1, 6		@ E5
	N	34, 1, 6		@ B4
	N	30, 1, 7		@ G4
	N	33, 1, 2		@ A#4
	N	37, 1, 2		@ D5
	N	42, 1, 4		@ G5
	N	42, 1, 6		@ G5
	N	44, 1, 4		@ A5
	N	45, 1, 7		@ A#5
	N	44, 1, 4		@ A5
	N	42, 1, 6		@ G5
	N	42, 1, 6		@ G5
	N	37, 1, 7		@ D5
	N	41, 1, 2		@ F#5
	N	44, 1, 2		@ A5
	N	49, 1, 4		@ D6
	N	49, 1, 6		@ D6
	N	47, 1, 4		@ C6
	N	45, 1, 6		@ A#5
	N	44, 1, 6		@ A5
	N	42, 1, 6		@ G5
	N	41, 1, 6		@ F#5
	N	40, 1, 7		@ F5
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	42, 1, 2		@ G5
	N	43, 1, 2		@ G#5
	N	40, 1, 4		@ F5
	N	40, 1, 6		@ F5
	N	38, 1, 2		@ D#5
	N	40, 1, 2		@ F5
	N	38, 1, 6		@ D#5
	N	35, 1, 6		@ C5
	N	35, 1, 7		@ C5
	N	39, 1, 2		@ E5
	N	42, 1, 2		@ G5
	N	47, 1, 4		@ C6
	N	45, 1, 4		@ A#5
	N	43, 1, 4		@ G#5
	N	42, 1, 4		@ G5
	N	40, 1, 7		@ F5
	N	35, 1, 2		@ C5
	N	40, 1, 2		@ F5
	N	44, 1, 4		@ A5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	PAT_END

pat_0808C564:				@ used by s11c7
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	35, 1, 6		@ C5
	N	32, 1, 6		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	38, 1, 6		@ D#5
	N	35, 1, 6		@ C5
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	33, 1, 4		@ A#4
	N	35, 1, 6		@ C5
	N	32, 1, 6		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	35, 1, 6		@ C5
	N	32, 1, 6		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	36, 1, 4		@ C#5
	N	38, 1, 6		@ D#5
	N	35, 1, 6		@ C5
	N	36, 1, 4		@ C#5
	N	36, 1, 6		@ C#5
	N	33, 1, 4		@ A#4
	N	35, 1, 6		@ C5
	N	32, 1, 6		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 6		@ A#4
	N	40, 1, 2		@ F5
	N	41, 1, 2		@ F#5
	N	40, 1, 4		@ F5
	N	38, 1, 4		@ D#5
	N	36, 1, 4		@ C#5
	N	35, 1, 4		@ C5
	PAT_END

pat_0808C5EC:				@ used by s11c8
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	PAT_END

pat_0808C61D:				@ used by s11c8
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	50, 10, 2		@ D#6
	N	50, 10, 4		@ D#6
	N	50, 10, 2		@ D#6
	N	48, 10, 4		@ C#6
	N	47, 10, 2		@ C6
	N	45, 10, 4		@ A#5
	N	43, 10, 2		@ G#5
	N	43, 10, 4		@ G#5
	N	41, 10, 4		@ F#5
	N	41, 10, 4		@ F#5
	PAT_END

pat_0808C660:				@ used by s11c8
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 8		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 8		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 8		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 8		@ C#6
	N	48, 2, 7		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	50, 10, 4		@ D#6
	N	47, 10, 2		@ C6
	N	43, 10, 2		@ G#5
	N	43, 10, 4		@ G#5
	PAT_END

pat_0808C6DF:				@ used by s12c1, s12c2
	N	69, 31, 6		@ A#7
	N	69, 31, 14		@ A#7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	67, 31, 6		@ G#7
	N	65, 31, 14		@ F#7
	N	67, 31, 13		@ G#7
	N	69, 31, 4		@ A#7
	N	65, 31, 4		@ F#7
	N	62, 31, 14		@ D#7
	N	64, 31, 13		@ F7
	N	65, 31, 6		@ F#7
	N	60, 31, 6		@ C#7
	N	65, 31, 14		@ F#7
	N	69, 31, 13		@ A#7
	N	72, 31, 6		@ C#8
	N	72, 31, 14		@ C#8
	N	72, 31, 13		@ C#8
	N	72, 31, 6		@ C#8
	N	72, 31, 14		@ C#8
	N	72, 31, 13		@ C#8
	N	72, 31, 6		@ C#8
	N	65, 31, 14		@ F#7
	N	67, 31, 13		@ G#7
	N	69, 31, 6		@ A#7
	N	69, 31, 14		@ A#7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	67, 31, 14		@ G#7
	N	67, 31, 13		@ G#7
	N	65, 31, 14		@ F#7
	N	67, 31, 13		@ G#7
	N	69, 31, 14		@ A#7
	N	65, 31, 13		@ F#7
	N	62, 31, 14		@ D#7
	N	64, 31, 13		@ F7
	N	65, 31, 6		@ F#7
	N	60, 31, 6		@ C#7
	N	65, 31, 14		@ F#7
	N	69, 31, 13		@ A#7
	N	72, 31, 6		@ C#8
	N	70, 31, 4		@ B7
	N	69, 31, 4		@ A#7
	N	67, 31, 6		@ G#7
	N	67, 31, 6		@ G#7
	N	65, 31, 8		@ F#7
	PAT_END

pat_0808C76A:				@ used by s12c1, s12c2
	N	72, 31, 6		@ C#8
	N	72, 31, 14		@ C#8
	N	72, 31, 13		@ C#8
	N	72, 31, 6		@ C#8
	N	69, 31, 6		@ A#7
	N	77, 31, 6		@ F#8
	N	77, 31, 14		@ F#8
	N	77, 31, 13		@ F#8
	N	76, 31, 6		@ F8
	N	74, 31, 6		@ D#8
	N	72, 31, 6		@ C#8
	N	72, 31, 14		@ C#8
	N	72, 31, 13		@ C#8
	N	74, 31, 6		@ D#8
	N	72, 31, 6		@ C#8
	N	72, 31, 6		@ C#8
	N	70, 31, 14		@ B7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	65, 31, 14		@ F#7
	N	67, 31, 13		@ G#7
	N	69, 31, 6		@ A#7
	N	69, 31, 14		@ A#7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	67, 31, 14		@ G#7
	N	67, 31, 13		@ G#7
	N	65, 31, 4		@ F#7
	N	67, 31, 4		@ G#7
	N	69, 31, 14		@ A#7
	N	65, 31, 13		@ F#7
	N	62, 31, 14		@ D#7
	N	64, 31, 13		@ F7
	N	65, 31, 6		@ F#7
	N	60, 31, 6		@ C#7
	N	65, 31, 14		@ F#7
	N	69, 31, 13		@ A#7
	N	72, 31, 6		@ C#8
	N	70, 31, 14		@ B7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	67, 31, 6		@ G#7
	N	65, 31, 8		@ F#7
	PAT_END

pat_0808C7EC:				@ used by s12c1, s12c2
	N	67, 31, 14		@ G#7
	N	65, 31, 13		@ F#7
	N	64, 31, 14		@ F7
	N	67, 31, 13		@ G#7
	N	72, 31, 6		@ C#8
	N	71, 31, 6		@ C8
	N	72, 31, 14		@ C#8
	N	74, 31, 13		@ D#8
	N	76, 31, 14		@ F8
	N	72, 31, 13		@ C#8
	N	74, 31, 14		@ D#8
	N	72, 31, 13		@ C#8
	N	71, 31, 14		@ C8
	N	74, 31, 13		@ D#8
	N	72, 31, 6		@ C#8
	N	67, 31, 6		@ G#7
	N	69, 31, 14		@ A#7
	N	67, 31, 13		@ G#7
	N	65, 31, 14		@ F#7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	64, 31, 6		@ F7
	N	64, 31, 8		@ F7
	N	67, 31, 14		@ G#7
	N	65, 31, 13		@ F#7
	N	64, 31, 14		@ F7
	N	67, 31, 13		@ G#7
	N	72, 31, 6		@ C#8
	N	74, 31, 6		@ D#8
	N	76, 31, 14		@ F8
	N	74, 31, 13		@ D#8
	N	72, 31, 14		@ C#8
	N	76, 31, 13		@ F8
	N	74, 31, 6		@ D#8
	N	71, 31, 6		@ C8
	N	72, 31, 6		@ C#8
	N	67, 31, 14		@ G#7
	N	72, 31, 13		@ C#8
	N	71, 31, 14		@ C8
	N	69, 31, 13		@ A#7
	N	67, 31, 14		@ G#7
	N	65, 31, 13		@ F#7
	N	67, 31, 6		@ G#7
	N	64, 31, 6		@ F7
	N	64, 31, 8		@ F7
	PAT_END

pat_0808C874:				@ used by s12c1, s12c2
	N	69, 31, 14		@ A#7
	N	67, 31, 13		@ G#7
	N	65, 31, 14		@ F#7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	74, 31, 6		@ D#8
	N	76, 31, 14		@ F8
	N	74, 31, 13		@ D#8
	N	72, 31, 14		@ C#8
	N	76, 31, 13		@ F8
	N	74, 31, 6		@ D#8
	N	70, 31, 6		@ B7
	N	72, 31, 15		@ C#8
	N	74, 31, 13		@ D#8
	N	76, 31, 13		@ F8
	N	77, 31, 15		@ F#8
	N	76, 31, 13		@ F8
	N	74, 31, 13		@ D#8
	N	72, 31, 6		@ C#8
	N	70, 31, 6		@ B7
	N	69, 31, 6		@ A#7
	N	67, 31, 6		@ G#7
	N	69, 31, 14		@ A#7
	N	67, 31, 13		@ G#7
	N	65, 31, 14		@ F#7
	N	69, 31, 13		@ A#7
	N	67, 31, 6		@ G#7
	N	74, 31, 6		@ D#8
	N	76, 31, 15		@ F8
	N	74, 31, 13		@ D#8
	N	72, 31, 13		@ C#8
	N	70, 31, 6		@ B7
	N	67, 31, 6		@ G#7
	N	69, 31, 16		@ A#7
	N	67, 31, 13		@ G#7
	N	65, 31, 14		@ F#7
	N	67, 31, 13		@ G#7
	N	69, 31, 14		@ A#7
	N	72, 31, 13		@ C#8
	N	74, 31, 6		@ D#8
	N	76, 31, 6		@ F8
	N	77, 31, 8		@ F#8
	PAT_END

pat_0808C8F3:				@ used by s12c4
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 13		@ B5
	PAT_END

pat_0808C96C:				@ used by s12c4
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 14		@ B5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	PAT_END

pat_0808C9E2:				@ used by s12c4
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 14		@ G5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 14		@ A5
	N	46, 5, 13		@ B5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	42, 3, 13		@ G5
	N	44, 4, 13		@ A5
	N	42, 3, 13		@ G5
	N	46, 5, 13		@ B5
	PAT_END

pat_0808CA5E:				@ used by s12c5
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	N	48, 28, 8		@ C#6
	PAT_END

pat_0808CA77:				@ used by s12c5
	N	69, 25, 14		@ A#7
	N	72, 25, 13		@ C#8
	N	70, 25, 14		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 14		@ G#7
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	67, 25, 13		@ G#7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 13		@ F#7
	N	62, 25, 14		@ D#7
	N	64, 25, 13		@ F7
	N	65, 25, 13		@ F#7
	N	64, 25, 13		@ F7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	65, 25, 13		@ F#7
	N	69, 25, 14		@ A#7
	N	70, 25, 13		@ B7
	N	72, 25, 14		@ C#8
	N	74, 25, 13		@ D#8
	N	72, 25, 13		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 14		@ G#7
	N	69, 25, 13		@ A#7
	N	67, 25, 14		@ G#7
	N	65, 25, 13		@ F#7
	N	64, 25, 14		@ F7
	N	62, 25, 13		@ D#7
	N	60, 25, 6		@ C#7
	N	69, 25, 14		@ A#7
	N	72, 25, 13		@ C#8
	N	70, 25, 14		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 14		@ G#7
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	67, 25, 13		@ G#7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 13		@ F#7
	N	62, 25, 14		@ D#7
	N	64, 25, 13		@ F7
	N	65, 25, 13		@ F#7
	N	64, 25, 13		@ F7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	65, 25, 13		@ F#7
	N	69, 25, 14		@ A#7
	N	70, 25, 13		@ B7
	N	72, 25, 14		@ C#8
	N	74, 25, 13		@ D#8
	N	72, 25, 13		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	64, 25, 13		@ F7
	N	65, 25, 8		@ F#7
	PAT_END

pat_0808CB41:				@ used by s12c5
	N	72, 25, 14		@ C#8
	N	74, 25, 13		@ D#8
	N	72, 25, 14		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 6		@ F#7
	N	74, 25, 14		@ D#8
	N	76, 25, 13		@ F8
	N	74, 25, 14		@ D#8
	N	72, 25, 13		@ C#8
	N	70, 25, 14		@ B7
	N	72, 25, 13		@ C#8
	N	74, 25, 6		@ D#8
	N	72, 25, 14		@ C#8
	N	74, 25, 13		@ D#8
	N	72, 25, 14		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	70, 25, 13		@ B7
	N	72, 25, 13		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 14		@ G#7
	N	69, 25, 13		@ A#7
	N	70, 25, 13		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	67, 25, 13		@ G#7
	N	64, 25, 13		@ F7
	N	65, 25, 13		@ F#7
	N	67, 25, 13		@ G#7
	N	69, 25, 14		@ A#7
	N	72, 25, 13		@ C#8
	N	70, 25, 14		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 14		@ G#7
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	67, 25, 13		@ G#7
	N	69, 25, 14		@ A#7
	N	65, 25, 13		@ F#7
	N	62, 25, 14		@ D#7
	N	64, 25, 13		@ F7
	N	65, 25, 13		@ F#7
	N	64, 25, 13		@ F7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	65, 25, 13		@ F#7
	N	69, 25, 14		@ A#7
	N	70, 25, 13		@ B7
	N	72, 25, 14		@ C#8
	N	74, 25, 13		@ D#8
	N	72, 25, 13		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	69, 25, 13		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	64, 25, 13		@ F7
	N	65, 25, 8		@ F#7
	PAT_END

pat_0808CC05:				@ used by s12c5
	N	65, 25, 6		@ F#7
	N	65, 25, 14		@ F#7
	N	62, 25, 13		@ D#7
	N	63, 25, 14		@ E7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	63, 25, 13		@ E7
	N	62, 25, 6		@ D#7
	N	58, 25, 14		@ B6
	N	58, 25, 13		@ B6
	N	60, 25, 14		@ C#7
	N	62, 25, 13		@ D#7
	N	63, 25, 14		@ E7
	N	67, 25, 13		@ G#7
	N	65, 25, 6		@ F#7
	N	62, 25, 14		@ D#7
	N	65, 25, 13		@ F#7
	N	63, 25, 14		@ E7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	63, 25, 13		@ E7
	N	62, 25, 6		@ D#7
	N	58, 25, 6		@ B6
	N	58, 25, 8		@ B6
	N	65, 25, 14		@ F#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	62, 25, 13		@ D#7
	N	63, 25, 14		@ E7
	N	65, 25, 13		@ F#7
	N	63, 25, 14		@ E7
	N	60, 25, 13		@ C#7
	N	62, 25, 13		@ D#7
	N	63, 25, 13		@ E7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	58, 25, 13		@ B6
	N	60, 25, 14		@ C#7
	N	62, 25, 13		@ D#7
	N	63, 25, 14		@ E7
	N	67, 25, 13		@ G#7
	N	65, 25, 6		@ F#7
	N	62, 25, 14		@ D#7
	N	65, 25, 13		@ F#7
	N	63, 25, 14		@ E7
	N	62, 25, 13		@ D#7
	N	60, 25, 14		@ C#7
	N	63, 25, 13		@ E7
	N	62, 25, 6		@ D#7
	N	58, 25, 6		@ B6
	N	58, 25, 8		@ B6
	PAT_END

pat_0808CC9F:				@ used by s12c5
	N	72, 25, 14		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	72, 25, 13		@ C#8
	N	70, 25, 6		@ B7
	N	67, 25, 6		@ G#7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	64, 25, 13		@ F7
	N	62, 25, 6		@ D#7
	N	70, 25, 6		@ B7
	N	72, 25, 14		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	64, 25, 13		@ F7
	N	62, 25, 14		@ D#7
	N	60, 25, 13		@ C#7
	N	58, 25, 14		@ B6
	N	60, 25, 13		@ C#7
	N	62, 25, 14		@ D#7
	N	65, 25, 13		@ F#7
	N	64, 25, 14		@ F7
	N	62, 25, 13		@ D#7
	N	60, 25, 6		@ C#7
	N	72, 25, 14		@ C#8
	N	70, 25, 13		@ B7
	N	69, 25, 14		@ A#7
	N	72, 25, 13		@ C#8
	N	70, 25, 6		@ B7
	N	67, 25, 6		@ G#7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	64, 25, 13		@ F7
	N	62, 25, 6		@ D#7
	N	70, 25, 6		@ B7
	N	69, 25, 6		@ A#7
	N	69, 25, 14		@ A#7
	N	67, 25, 13		@ G#7
	N	65, 25, 14		@ F#7
	N	67, 25, 13		@ G#7
	N	69, 25, 14		@ A#7
	N	65, 25, 13		@ F#7
	N	67, 25, 14		@ G#7
	N	65, 25, 13		@ F#7
	N	64, 25, 14		@ F7
	N	67, 25, 13		@ G#7
	N	65, 25, 6		@ F#7
	N	65, 25, 6		@ F#7
	PAT_END

pat_0808CD3C:				@ used by s12c6
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	PAT_END

pat_0808CD85:				@ used by s12c6
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	74, 24, 6		@ D#8
	N	74, 24, 14		@ D#8
	N	74, 24, 13		@ D#8
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 14		@ G#7
	N	67, 24, 13		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	74, 24, 6		@ D#8
	N	74, 24, 14		@ D#8
	N	74, 24, 13		@ D#8
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	72, 23, 14		@ C#8
	N	72, 23, 13		@ C#8
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	PAT_END

pat_0808CDFE:				@ used by s12c6
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 14		@ G#7
	N	67, 24, 13		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	74, 24, 6		@ D#8
	N	74, 24, 14		@ D#8
	N	74, 24, 13		@ D#8
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	72, 23, 14		@ C#8
	N	72, 23, 13		@ C#8
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	PAT_END

pat_0808CE77:				@ used by s12c6
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	N	70, 23, 6		@ B7
	N	70, 23, 14		@ B7
	N	70, 23, 13		@ B7
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	PAT_END

pat_0808CEF0:				@ used by s12c6
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	69, 24, 6		@ A#7
	N	69, 24, 14		@ A#7
	N	69, 24, 13		@ A#7
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	67, 24, 14		@ G#7
	N	67, 24, 13		@ G#7
	N	72, 23, 6		@ C#8
	N	72, 23, 6		@ C#8
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	67, 24, 6		@ G#7
	N	67, 24, 6		@ G#7
	N	69, 24, 6		@ A#7
	N	69, 24, 14		@ A#7
	N	69, 24, 13		@ A#7
	N	70, 23, 6		@ B7
	N	70, 23, 6		@ B7
	N	77, 23, 6		@ F#8
	N	77, 23, 14		@ F#8
	N	77, 23, 13		@ F#8
	N	74, 24, 6		@ D#8
	N	74, 24, 6		@ D#8
	N	67, 24, 6		@ G#7
	N	72, 23, 6		@ C#8
	N	77, 23, 6		@ F#8
	N	77, 23, 6		@ F#8
	PAT_END

pat_0808CF66:				@ used by s12c7
	N	41, 1, 16		@ F#5
	N	36, 1, 13		@ C#5
	N	33, 1, 6		@ A#4
	N	29, 1, 6		@ F#4
	N	29, 1, 16		@ F#4
	N	33, 1, 13		@ A#4
	N	34, 1, 6		@ B4
	N	36, 1, 6		@ C#5
	N	41, 1, 16		@ F#5
	N	36, 1, 13		@ C#5
	N	33, 1, 6		@ A#4
	N	29, 1, 6		@ F#4
	N	29, 1, 16		@ F#4
	N	33, 1, 13		@ A#4
	N	34, 1, 6		@ B4
	N	36, 1, 6		@ C#5
	PAT_END

pat_0808CF97:				@ used by s12c7
	N	41, 1, 16		@ F#5
	N	41, 1, 13		@ F#5
	N	36, 1, 6		@ C#5
	N	36, 1, 14		@ C#5
	N	37, 1, 13		@ D5
	N	38, 1, 16		@ D#5
	N	36, 1, 13		@ C#5
	N	34, 1, 6		@ B4
	N	38, 1, 6		@ D#5
	N	41, 1, 16		@ F#5
	N	40, 1, 13		@ F5
	N	38, 1, 16		@ D#5
	N	36, 1, 13		@ C#5
	N	31, 1, 6		@ G#4
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 13		@ B4
	N	36, 1, 6		@ C#5
	N	36, 1, 13		@ C#5
	N	38, 1, 13		@ D#5
	N	40, 1, 13		@ F5
	N	41, 1, 16		@ F#5
	N	41, 1, 13		@ F#5
	N	36, 1, 6		@ C#5
	N	36, 1, 14		@ C#5
	N	37, 1, 13		@ D5
	N	38, 1, 16		@ D#5
	N	38, 1, 13		@ D#5
	N	34, 1, 6		@ B4
	N	38, 1, 6		@ D#5
	N	41, 1, 6		@ F#5
	N	41, 1, 14		@ F#5
	N	40, 1, 13		@ F5
	N	38, 1, 6		@ D#5
	N	38, 1, 6		@ D#5
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 13		@ B4
	N	36, 1, 13		@ C#5
	N	38, 1, 13		@ D#5
	N	40, 1, 13		@ F5
	N	41, 1, 6		@ F#5
	N	41, 1, 6		@ F#5
	PAT_END

pat_0808D019:				@ used by s12c7
	N	41, 1, 16		@ F#5
	N	36, 1, 13		@ C#5
	N	29, 1, 14		@ F#4
	N	29, 1, 13		@ F#4
	N	31, 1, 14		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	N	41, 1, 16		@ F#5
	N	40, 1, 13		@ F5
	N	38, 1, 16		@ D#5
	N	36, 1, 13		@ C#5
	N	31, 1, 6		@ G#4
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 13		@ B4
	N	36, 1, 6		@ C#5
	N	36, 1, 13		@ C#5
	N	38, 1, 13		@ D#5
	N	40, 1, 13		@ F5
	N	41, 1, 16		@ F#5
	N	41, 1, 13		@ F#5
	N	36, 1, 16		@ C#5
	N	37, 1, 13		@ D5
	N	38, 1, 16		@ D#5
	N	36, 1, 13		@ C#5
	N	34, 1, 6		@ B4
	N	38, 1, 6		@ D#5
	N	41, 1, 16		@ F#5
	N	40, 1, 13		@ F5
	N	38, 1, 16		@ D#5
	N	36, 1, 13		@ C#5
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 13		@ B4
	N	36, 1, 13		@ C#5
	N	38, 1, 13		@ D#5
	N	40, 1, 13		@ F5
	N	41, 1, 6		@ F#5
	N	41, 1, 6		@ F#5
	PAT_END

pat_0808D098:				@ used by s12c7
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	29, 1, 13		@ F#4
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	29, 1, 14		@ F#4
	N	31, 1, 13		@ G#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	29, 1, 13		@ F#4
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	29, 1, 6		@ F#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	29, 1, 13		@ F#4
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	29, 1, 13		@ F#4
	N	31, 1, 13		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 14		@ F#5
	N	29, 1, 13		@ F#4
	N	31, 1, 14		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 16		@ B4
	N	38, 1, 13		@ D#5
	N	41, 1, 6		@ F#5
	N	38, 1, 6		@ D#5
	PAT_END

pat_0808D11A:				@ used by s12c7
	N	41, 1, 16		@ F#5
	N	29, 1, 13		@ F#4
	N	31, 1, 6		@ G#4
	N	34, 1, 6		@ B4
	N	33, 1, 16		@ A#4
	N	36, 1, 13		@ C#5
	N	34, 1, 6		@ B4
	N	41, 1, 6		@ F#5
	N	41, 1, 16		@ F#5
	N	40, 1, 13		@ F5
	N	38, 1, 16		@ D#5
	N	36, 1, 13		@ C#5
	N	31, 1, 15		@ G#4
	N	33, 1, 13		@ A#4
	N	34, 1, 13		@ B4
	N	36, 1, 14		@ C#5
	N	38, 1, 13		@ D#5
	N	40, 1, 14		@ F5
	N	36, 1, 13		@ C#5
	N	41, 1, 15		@ F#5
	N	36, 1, 13		@ C#5
	N	33, 1, 13		@ A#4
	N	31, 1, 6		@ G#4
	N	34, 1, 6		@ B4
	N	33, 1, 15		@ A#4
	N	36, 1, 13		@ C#5
	N	40, 1, 13		@ F5
	N	34, 1, 6		@ B4
	N	38, 1, 6		@ D#5
	N	41, 1, 16		@ F#5
	N	40, 1, 13		@ F5
	N	38, 1, 8		@ D#5
	N	31, 1, 14		@ G#4
	N	33, 1, 13		@ A#4
	N	36, 1, 14		@ C#5
	N	40, 1, 13		@ F5
	N	41, 1, 6		@ F#5
	N	29, 1, 6		@ F#4
	PAT_END

pat_0808D18D:				@ used by s12c8
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 13		@ C#6
	PAT_END

pat_0808D1DC:				@ used by s12c8
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 6		@ C#6
	PAT_END

pat_0808D270:				@ used by s12c8
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 6		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 2, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 14		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 2, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	N	48, 3, 13		@ C#6
	PAT_END

pat_0808D32E:				@ used by s13c2
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	42, 20, 5		@ G5
	N	42, 20, 5		@ G5
	N	42, 20, 6		@ G5
	N	42, 20, 4		@ G5
	N	42, 20, 4		@ G5
	N	42, 20, 4		@ G5
	N	43, 17, 5		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 6		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	43, 17, 5		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 6		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	PAT_END

pat_0808D3BF:				@ used by s13c2
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	40, 18, 4		@ F5
	N	40, 18, 4		@ F5
	N	45, 17, 6		@ A#5
	N	45, 17, 5		@ A#5
	N	45, 17, 5		@ A#5
	N	45, 17, 4		@ A#5
	N	45, 17, 4		@ A#5
	N	45, 17, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	45, 17, 6		@ A#5
	N	45, 17, 5		@ A#5
	N	45, 17, 5		@ A#5
	N	45, 17, 4		@ A#5
	N	45, 17, 4		@ A#5
	N	45, 17, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	PAT_END

pat_0808D450:				@ used by s13c2
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	47, 19, 6		@ C6
	N	47, 19, 5		@ C6
	N	47, 19, 5		@ C6
	N	47, 19, 4		@ C6
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	43, 17, 6		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 6		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	PAT_END

pat_0808D571:				@ used by s13c2
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	36, 18, 6		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 6		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 2		@ C#5
	N	36, 18, 5		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	N	36, 18, 4		@ C#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 6		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 2		@ G#5
	N	43, 16, 5		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	45, 19, 6		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 2		@ A#5
	N	45, 19, 5		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	45, 19, 4		@ A#5
	N	38, 18, 6		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 2		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	43, 17, 6		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 5		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 4		@ G#5
	PAT_END

pat_0808D6AD:				@ used by s13c2
	N	38, 18, 6		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 2		@ D#5
	N	38, 18, 5		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	N	38, 18, 4		@ D#5
	PAT_END

pat_0808D6C3:				@ used by s13c2
	N	43, 17, 6		@ G#5
	N	43, 17, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 4		@ G#5
	N	42, 18, 2		@ G5
	N	42, 18, 4		@ G5
	N	42, 18, 4		@ G5
	N	42, 18, 4		@ G5
	PAT_END

pat_0808D6DC:				@ used by s13c2
	N	35, 18, 6		@ C5
	N	35, 18, 5		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 2		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	40, 17, 6		@ F5
	N	40, 17, 5		@ F5
	N	40, 17, 4		@ F5
	N	40, 18, 4		@ F5
	N	40, 17, 2		@ F5
	N	40, 17, 4		@ F5
	N	40, 17, 4		@ F5
	N	35, 18, 6		@ C5
	N	35, 18, 5		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 2		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	42, 17, 5		@ G5
	N	42, 17, 4		@ G5
	N	42, 17, 2		@ G5
	N	42, 18, 4		@ G5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	35, 18, 4		@ C5
	N	47, 16, 6		@ C6
	N	47, 16, 5		@ C6
	N	47, 16, 4		@ C6
	N	47, 16, 4		@ C6
	N	47, 16, 2		@ C6
	N	47, 16, 4		@ C6
	N	47, 16, 4		@ C6
	N	40, 16, 6		@ F5
	N	40, 16, 5		@ F5
	N	40, 16, 4		@ F5
	N	40, 16, 4		@ F5
	N	40, 16, 2		@ F5
	N	40, 16, 4		@ F5
	N	40, 16, 4		@ F5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 2		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 6		@ A#5
	N	45, 16, 5		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 2		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 16, 4		@ A#5
	PAT_END

pat_0808D788:				@ used by s13c1
	N	62, 31, 8		@ D#7
	N	64, 31, 6		@ F7
	N	66, 31, 6		@ G7
	N	66, 31, 9		@ G7
	N	64, 31, 4		@ F7
	N	62, 31, 4		@ D#7
	N	61, 31, 8		@ D7
	N	62, 31, 6		@ D#7
	N	64, 31, 6		@ F7
	N	64, 31, 9		@ F7
	N	64, 31, 6		@ F7
	N	62, 31, 22		@ D#7
	N	61, 31, 4		@ D7
	N	57, 31, 6		@ A#6
	N	57, 31, 22		@ A#6
	N	55, 31, 4		@ G#6
	N	57, 31, 6		@ A#6
	N	57, 31, 8		@ A#6
	N	50, 31, 6		@ D#6
	N	52, 31, 6		@ F6
	N	52, 31, 9		@ F6
	N	52, 31, 6		@ F6
	N	57, 31, 6		@ A#6
	N	54, 31, 6		@ G6
	N	57, 31, 6		@ A#6
	N	57, 31, 6		@ A#6
	N	55, 31, 6		@ G#6
	N	50, 31, 8		@ D#6
	N	55, 31, 6		@ G#6
	N	59, 31, 6		@ C7
	N	64, 31, 7		@ F7
	N	62, 31, 4		@ D#7
	N	59, 31, 4		@ C7
	N	59, 31, 4		@ C7
	N	57, 31, 6		@ A#6
	N	57, 31, 8		@ A#6
	N	52, 31, 6		@ F6
	N	57, 31, 22		@ A#6
	N	61, 31, 4		@ D7
	N	62, 31, 4		@ D#7
	N	64, 31, 4		@ F7
	N	66, 31, 22		@ G7
	N	62, 31, 4		@ D#7
	N	57, 31, 4		@ A#6
	N	61, 31, 4		@ D7
	N	62, 31, 22		@ D#7
	N	64, 31, 4		@ F7
	N	61, 31, 6		@ D7
	N	57, 31, 10		@ A#6
	PAT_END

pat_0808D81C:				@ used by s13c1
	N	59, 31, 6		@ C7
	N	59, 31, 4		@ C7
	N	60, 31, 4		@ C#7
	N	59, 31, 6		@ C7
	N	57, 31, 4		@ A#6
	N	59, 31, 2		@ C7
	N	57, 31, 2		@ A#6
	N	55, 31, 6		@ G#6
	N	59, 31, 4		@ C7
	N	55, 31, 2		@ G#6
	N	59, 31, 2		@ C7
	N	62, 31, 5		@ D#7
	N	59, 31, 2		@ C7
	N	62, 31, 4		@ D#7
	N	66, 31, 4		@ G7
	N	67, 31, 7		@ G#7
	N	67, 31, 6		@ G#7
	N	67, 31, 6		@ G#7
	N	66, 31, 4		@ G7
	N	62, 31, 7		@ D#7
	N	62, 31, 6		@ D#7
	N	62, 31, 4		@ D#7
	N	62, 31, 4		@ D#7
	N	62, 31, 4		@ D#7
	N	60, 31, 6		@ C#7
	N	60, 31, 7		@ C#7
	N	62, 31, 6		@ D#7
	N	60, 31, 2		@ C#7
	N	62, 31, 2		@ D#7
	N	64, 31, 6		@ F7
	N	66, 31, 6		@ G7
	N	64, 31, 6		@ F7
	N	60, 31, 6		@ C#7
	N	59, 31, 7		@ C7
	N	60, 31, 4		@ C#7
	N	59, 31, 6		@ C7
	N	55, 31, 4		@ G#6
	N	59, 31, 8		@ C7
	N	62, 31, 2		@ D#7
	N	66, 31, 2		@ G7
	N	67, 31, 4		@ G#7
	N	66, 31, 4		@ G7
	N	62, 31, 6		@ D#7
	N	59, 31, 6		@ C7
	N	59, 31, 6		@ C7
	N	59, 31, 6		@ C7
	N	57, 31, 4		@ A#6
	N	59, 31, 2		@ C7
	N	57, 31, 2		@ A#6
	N	55, 31, 6		@ G#6
	N	59, 31, 4		@ C7
	N	55, 31, 2		@ G#6
	N	59, 31, 2		@ C7
	N	62, 31, 4		@ D#7
	N	59, 31, 4		@ C7
	N	62, 31, 4		@ D#7
	N	66, 31, 4		@ G7
	N	67, 31, 6		@ G#7
	N	67, 31, 5		@ G#7
	N	69, 31, 2		@ A#7
	N	67, 31, 6		@ G#7
	N	66, 31, 4		@ G7
	N	67, 31, 2		@ G#7
	N	66, 31, 2		@ G7
	N	62, 31, 9		@ D#7
	N	62, 31, 6		@ D#7
	N	60, 31, 6		@ C#7
	N	60, 31, 4		@ C#7
	N	60, 31, 6		@ C#7
	N	60, 31, 4		@ C#7
	N	60, 31, 6		@ C#7
	N	59, 31, 6		@ C7
	N	59, 31, 6		@ C7
	N	57, 31, 6		@ A#6
	N	55, 31, 4		@ G#6
	N	62, 31, 4		@ D#7
	N	59, 31, 7		@ C7
	N	59, 31, 4		@ C7
	N	59, 31, 6		@ C7
	N	57, 31, 6		@ A#6
	N	55, 31, 6		@ G#6
	N	54, 31, 4		@ G6
	N	50, 31, 4		@ D#6
	N	49, 31, 4		@ D6
	N	54, 31, 4		@ G6
	N	58, 31, 4		@ B6
	N	61, 31, 2		@ D7
	N	58, 31, 2		@ B6
	PAT_END

pat_0808D925:				@ used by s13c4
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
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 0		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	42, 3, 2		@ G5
	N	46, 5, 2		@ B5
	PAT_END

pat_0808D9FB:				@ used by s13c5
	REST	0, 9
	N	69, 14, 4		@ A#7
	N	66, 14, 4		@ G7
	N	62, 14, 8		@ D#7
	N	66, 14, 6		@ G7
	N	69, 14, 6		@ A#7
	N	74, 14, 9		@ D#8
	N	78, 14, 4		@ G8
	N	76, 14, 4		@ F8
	N	74, 14, 8		@ D#8
	N	66, 14, 6		@ G7
	N	68, 14, 6		@ A7
	N	69, 14, 9		@ A#7
	N	69, 14, 4		@ A#7
	N	69, 14, 4		@ A#7
	N	78, 14, 22		@ G8
	N	76, 14, 4		@ F8
	N	74, 14, 6		@ D#8
	N	73, 14, 9		@ D8
	N	71, 14, 4		@ C8
	N	73, 14, 4		@ D8
	N	74, 14, 6		@ D#8
	N	74, 14, 6		@ D#8
	N	69, 14, 6		@ A#7
	N	66, 14, 6		@ G7
	N	62, 14, 9		@ D#7
	N	69, 14, 4		@ A#7
	N	66, 14, 4		@ G7
	N	62, 14, 8		@ D#7
	N	66, 14, 6		@ G7
	N	69, 14, 6		@ A#7
	N	74, 14, 9		@ D#8
	N	78, 14, 4		@ G8
	N	76, 14, 4		@ F8
	N	74, 14, 8		@ D#8
	N	66, 14, 6		@ G7
	N	68, 14, 6		@ A7
	N	69, 14, 9		@ A#7
	N	69, 14, 4		@ A#7
	N	69, 14, 4		@ A#7
	N	78, 14, 22		@ G8
	N	76, 14, 4		@ F8
	N	74, 14, 6		@ D#8
	N	73, 14, 9		@ D8
	N	71, 14, 4		@ C8
	N	73, 14, 4		@ D8
	N	74, 14, 6		@ D#8
	N	74, 14, 6		@ D#8
	N	69, 14, 6		@ A#7
	N	66, 14, 6		@ G7
	N	62, 14, 10		@ D#7
	PAT_END

pat_0808DA95:				@ used by s13c5
	N	66, 14, 8		@ G7
	N	67, 14, 6		@ G#7
	N	69, 14, 6		@ A#7
	N	69, 14, 9		@ A#7
	N	67, 14, 4		@ G#7
	N	66, 14, 4		@ G7
	N	64, 14, 8		@ F7
	N	66, 14, 6		@ G7
	N	67, 14, 6		@ G#7
	N	67, 14, 9		@ G#7
	N	67, 14, 6		@ G#7
	N	66, 14, 22		@ G7
	N	64, 14, 4		@ F7
	N	62, 14, 6		@ D#7
	N	61, 14, 22		@ D7
	N	59, 14, 4		@ C7
	N	61, 14, 6		@ D7
	N	62, 14, 8		@ D#7
	N	54, 14, 6		@ G6
	N	56, 14, 6		@ A6
	N	57, 14, 9		@ A#6
	N	57, 14, 6		@ A#6
	N	62, 14, 6		@ D#7
	N	62, 14, 6		@ D#7
	N	62, 14, 6		@ D#7
	N	61, 14, 6		@ D7
	N	59, 14, 6		@ C7
	N	55, 14, 8		@ G#6
	N	59, 14, 6		@ C7
	N	64, 14, 6		@ F7
	N	67, 14, 7		@ G#7
	N	66, 14, 4		@ G7
	N	64, 14, 4		@ F7
	N	62, 14, 4		@ D#7
	N	62, 14, 6		@ D#7
	N	61, 14, 8		@ D7
	N	57, 14, 6		@ A#6
	N	62, 14, 22		@ D#7
	N	64, 14, 4		@ F7
	N	66, 14, 4		@ G7
	N	67, 14, 4		@ G#7
	N	69, 14, 22		@ A#7
	N	66, 14, 4		@ G7
	N	62, 14, 4		@ D#7
	N	64, 14, 4		@ F7
	N	66, 14, 22		@ G7
	N	67, 14, 4		@ G#7
	N	64, 14, 6		@ F7
	N	62, 14, 10		@ D#7
	PAT_END

pat_0808DB29:				@ used by s13c5
	N	62, 14, 7		@ D#7
	N	62, 14, 7		@ D#7
	N	60, 14, 4		@ C#7
	N	62, 14, 2		@ D#7
	N	60, 14, 2		@ C#7
	N	59, 14, 6		@ C7
	N	62, 14, 4		@ D#7
	N	59, 14, 2		@ C7
	N	62, 14, 2		@ D#7
	N	67, 14, 6		@ G#7
	N	67, 14, 4		@ G#7
	N	62, 14, 1		@ D#7
	N	67, 14, 1		@ G#7
	N	69, 14, 1		@ A#7
	N	71, 14, 5		@ C8
	N	71, 14, 5		@ C8
	N	71, 14, 6		@ C8
	N	72, 14, 4		@ C#8
	N	71, 14, 4		@ C8
	N	69, 14, 4		@ A#7
	N	67, 14, 7		@ G#7
	N	67, 14, 2		@ G#7
	N	69, 14, 2		@ A#7
	N	71, 14, 4		@ C8
	N	69, 14, 4		@ A#7
	N	67, 14, 4		@ G#7
	N	66, 14, 4		@ G7
	N	64, 14, 7		@ F7
	N	64, 14, 7		@ F7
	N	66, 14, 4		@ G7
	N	64, 14, 2		@ F7
	N	66, 14, 2		@ G7
	N	67, 14, 7		@ G#7
	N	69, 14, 4		@ A#7
	N	67, 14, 4		@ G#7
	N	69, 14, 4		@ A#7
	N	67, 14, 4		@ G#7
	N	64, 14, 4		@ F7
	N	62, 14, 7		@ D#7
	N	64, 14, 4		@ F7
	N	62, 14, 6		@ D#7
	N	59, 14, 6		@ C7
	N	62, 14, 7		@ D#7
	N	67, 14, 2		@ G#7
	N	69, 14, 2		@ A#7
	N	71, 14, 4		@ C8
	N	69, 14, 4		@ A#7
	N	67, 14, 6		@ G#7
	N	62, 14, 7		@ D#7
	N	62, 14, 7		@ D#7
	N	60, 14, 4		@ C#7
	N	62, 14, 2		@ D#7
	N	60, 14, 2		@ C#7
	N	59, 14, 6		@ C7
	N	62, 14, 4		@ D#7
	N	59, 14, 2		@ C7
	N	62, 14, 2		@ D#7
	N	67, 14, 4		@ G#7
	N	62, 14, 2		@ D#7
	N	67, 14, 5		@ G#7
	N	69, 14, 4		@ A#7
	N	71, 14, 4		@ C8
	N	71, 14, 4		@ C8
	N	71, 14, 4		@ C8
	N	72, 14, 4		@ C#8
	N	71, 14, 6		@ C8
	N	69, 14, 4		@ A#7
	N	71, 14, 2		@ C8
	N	69, 14, 2		@ A#7
	N	67, 14, 9		@ G#7
	N	67, 14, 6		@ G#7
	N	69, 14, 7		@ A#7
	N	69, 14, 6		@ A#7
	N	69, 14, 4		@ A#7
	N	69, 14, 4		@ A#7
	N	69, 14, 4		@ A#7
	N	67, 14, 7		@ G#7
	N	69, 14, 2		@ A#7
	N	67, 14, 2		@ G#7
	N	66, 14, 7		@ G7
	N	64, 14, 2		@ F7
	N	66, 14, 2		@ G7
	N	67, 14, 7		@ G#7
	N	67, 14, 2		@ G#7
	N	69, 14, 2		@ A#7
	N	71, 14, 4		@ C8
	N	69, 14, 4		@ A#7
	N	67, 14, 4		@ G#7
	N	66, 14, 4		@ G7
	N	64, 14, 4		@ F7
	N	66, 14, 4		@ G7
	N	64, 14, 4		@ F7
	N	66, 14, 4		@ G7
	N	62, 14, 8		@ D#7
	PAT_END

pat_0808DC44:				@ used by s13c5
	N	62, 14, 6		@ D#7
	N	62, 14, 4		@ D#7
	N	64, 14, 4		@ F7
	N	62, 14, 6		@ D#7
	N	60, 14, 4		@ C#7
	N	62, 14, 2		@ D#7
	N	60, 14, 2		@ C#7
	N	59, 14, 6		@ C7
	N	62, 14, 4		@ D#7
	N	59, 14, 2		@ C7
	N	62, 14, 2		@ D#7
	N	67, 14, 5		@ G#7
	N	62, 14, 2		@ D#7
	N	67, 14, 4		@ G#7
	N	69, 14, 4		@ A#7
	N	71, 14, 7		@ C8
	N	71, 14, 6		@ C8
	N	71, 14, 6		@ C8
	N	69, 14, 4		@ A#7
	N	67, 14, 7		@ G#7
	N	67, 14, 6		@ G#7
	N	67, 14, 4		@ G#7
	N	67, 14, 4		@ G#7
	N	66, 14, 4		@ G7
	N	64, 14, 6		@ F7
	N	64, 14, 7		@ F7
	N	66, 14, 6		@ G7
	N	64, 14, 2		@ F7
	N	66, 14, 2		@ G7
	N	67, 14, 6		@ G#7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	64, 14, 6		@ F7
	N	62, 14, 7		@ D#7
	N	64, 14, 4		@ F7
	N	62, 14, 6		@ D#7
	N	59, 14, 4		@ C7
	N	62, 14, 8		@ D#7
	N	67, 14, 2		@ G#7
	N	69, 14, 2		@ A#7
	N	71, 14, 4		@ C8
	N	69, 14, 4		@ A#7
	N	67, 14, 6		@ G#7
	N	62, 14, 6		@ D#7
	N	62, 14, 6		@ D#7
	N	62, 14, 6		@ D#7
	N	60, 14, 4		@ C#7
	N	62, 14, 2		@ D#7
	N	60, 14, 2		@ C#7
	N	59, 14, 6		@ C7
	N	62, 14, 4		@ D#7
	N	59, 14, 2		@ C7
	N	62, 14, 2		@ D#7
	N	67, 14, 4		@ G#7
	N	62, 14, 4		@ D#7
	N	67, 14, 4		@ G#7
	N	69, 14, 4		@ A#7
	N	71, 14, 6		@ C8
	N	71, 14, 5		@ C8
	N	72, 14, 2		@ C#8
	N	71, 14, 6		@ C8
	N	69, 14, 4		@ A#7
	N	71, 14, 2		@ C8
	N	69, 14, 2		@ A#7
	N	67, 14, 9		@ G#7
	N	67, 14, 6		@ G#7
	N	69, 14, 6		@ A#7
	N	69, 14, 4		@ A#7
	N	69, 14, 6		@ A#7
	N	69, 14, 4		@ A#7
	N	69, 14, 6		@ A#7
	N	67, 14, 6		@ G#7
	N	67, 14, 6		@ G#7
	N	66, 14, 6		@ G7
	N	64, 14, 4		@ F7
	N	66, 14, 4		@ G7
	N	67, 14, 7		@ G#7
	N	67, 14, 4		@ G#7
	N	62, 14, 6		@ D#7
	N	60, 14, 6		@ C#7
	N	59, 14, 6		@ C7
	N	57, 14, 4		@ A#6
	N	55, 14, 4		@ G#6
	N	54, 14, 4		@ G6
	N	58, 14, 4		@ B6
	N	61, 14, 4		@ D7
	N	66, 14, 2		@ G7
	N	63, 14, 2		@ E7
	PAT_END

pat_0808DD4D:				@ used by s13c5
	N	59, 14, 4		@ C7
	N	59, 14, 4		@ C7
	N	59, 14, 2		@ C7
	N	61, 14, 2		@ D7
	N	63, 14, 2		@ E7
	N	64, 14, 2		@ F7
	N	66, 14, 4		@ G7
	N	66, 14, 4		@ G7
	N	66, 14, 4		@ G7
	N	63, 14, 4		@ E7
	N	68, 14, 5		@ A7
	N	66, 14, 2		@ G7
	N	68, 14, 5		@ A7
	N	66, 14, 2		@ G7
	N	68, 14, 5		@ A7
	N	66, 14, 2		@ G7
	N	68, 14, 2		@ A7
	N	70, 14, 2		@ B7
	N	71, 14, 2		@ C8
	N	73, 14, 2		@ D8
	N	75, 14, 7		@ E8
	N	71, 14, 2		@ C8
	N	66, 14, 2		@ G7
	N	71, 14, 7		@ C8
	N	66, 14, 2		@ G7
	N	63, 14, 2		@ E7
	N	66, 14, 7		@ G7
	N	61, 14, 2		@ D7
	N	63, 14, 2		@ E7
	N	59, 14, 6		@ C7
	N	66, 14, 6		@ G7
	N	71, 14, 6		@ C8
	N	75, 14, 6		@ E8
	N	73, 14, 6		@ D8
	N	71, 14, 6		@ C8
	N	68, 14, 6		@ A7
	N	71, 14, 8		@ C8
	N	68, 14, 6		@ A7
	N	73, 14, 9		@ D8
	N	69, 14, 6		@ A#7
	N	73, 14, 10		@ D8
	PAT_END

pat_0808DDC9:				@ used by s13c6
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	61, 29, 2		@ D7
	N	61, 29, 2		@ D7
	N	61, 29, 2		@ D7
	N	61, 29, 2		@ D7
	N	61, 29, 4		@ D7
	N	59, 29, 2		@ C7
	N	61, 29, 4		@ D7
	N	61, 29, 4		@ D7
	N	61, 29, 2		@ D7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	62, 29, 4		@ D#7
	N	67, 29, 4		@ G#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	62, 29, 4		@ D#7
	N	66, 29, 4		@ G7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	62, 29, 4		@ D#7
	N	67, 29, 4		@ G#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	55, 29, 2		@ G#6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	PAT_END

pat_0808DED2:				@ used by s13c6
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	64, 29, 4		@ F7
	N	64, 29, 4		@ F7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	PAT_END

pat_0808DFDB:				@ used by s13c6
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	56, 29, 4		@ A6
	N	64, 29, 4		@ F7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	62, 29, 4		@ D#7
	N	67, 29, 4		@ G#7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	57, 29, 2		@ A#6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	64, 29, 4		@ F7
	N	67, 29, 4		@ G#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	PAT_END

pat_0808E1EC:				@ used by s13c6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	60, 29, 2		@ C#7
	N	60, 29, 2		@ C#7
	N	60, 29, 2		@ C#7
	N	60, 29, 2		@ C#7
	N	60, 29, 4		@ C#7
	N	59, 29, 2		@ C7
	N	60, 29, 4		@ C#7
	N	60, 29, 4		@ C#7
	N	60, 29, 2		@ C#7
	N	64, 29, 4		@ F7
	N	67, 29, 4		@ G#7
	N	60, 29, 2		@ C#7
	N	60, 29, 2		@ C#7
	N	60, 29, 2		@ C#7
	N	60, 29, 2		@ C#7
	N	60, 29, 4		@ C#7
	N	59, 29, 2		@ C7
	N	60, 29, 4		@ C#7
	N	60, 29, 4		@ C#7
	N	60, 29, 2		@ C#7
	N	64, 29, 4		@ F7
	N	67, 29, 4		@ G#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	60, 29, 4		@ C#7
	N	64, 29, 4		@ F7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	60, 29, 2		@ C#7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	55, 29, 4		@ G#6
	N	55, 29, 2		@ G#6
	N	59, 29, 4		@ C7
	N	62, 29, 4		@ D#7
	PAT_END

pat_0808E3DC:				@ used by s13c6
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 2		@ D#7
	N	62, 29, 4		@ D#7
	N	61, 29, 2		@ D7
	N	62, 29, 4		@ D#7
	N	62, 29, 4		@ D#7
	N	62, 29, 2		@ D#7
	N	66, 29, 4		@ G7
	N	69, 29, 4		@ A#7
	PAT_END

pat_0808E3FE:				@ used by s13c6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 2		@ G#6
	N	55, 29, 4		@ G#6
	N	54, 29, 2		@ G6
	N	55, 29, 4		@ G#6
	N	54, 29, 4		@ G6
	N	54, 29, 2		@ G6
	N	58, 29, 4		@ B6
	N	61, 29, 4		@ D7
	PAT_END

pat_0808E420:				@ used by s13c6
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	58, 29, 2		@ B6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	63, 29, 4		@ E7
	N	66, 29, 4		@ G7
	N	56, 29, 2		@ A6
	N	56, 29, 2		@ A6
	N	56, 29, 2		@ A6
	N	56, 29, 2		@ A6
	N	56, 29, 4		@ A6
	N	54, 29, 2		@ G6
	N	56, 29, 4		@ A6
	N	56, 29, 4		@ A6
	N	56, 29, 2		@ A6
	N	59, 29, 4		@ C7
	N	64, 29, 4		@ F7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	58, 29, 2		@ B6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	63, 29, 4		@ E7
	N	66, 29, 4		@ G7
	N	58, 29, 2		@ B6
	N	58, 29, 2		@ B6
	N	58, 29, 2		@ B6
	N	58, 29, 2		@ B6
	N	58, 29, 4		@ B6
	N	56, 29, 2		@ A6
	N	58, 29, 4		@ B6
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	63, 29, 4		@ E7
	N	66, 29, 4		@ G7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 2		@ C7
	N	59, 29, 4		@ C7
	N	58, 29, 2		@ B6
	N	59, 29, 4		@ C7
	N	59, 29, 4		@ C7
	N	59, 29, 2		@ C7
	N	63, 29, 4		@ E7
	N	66, 29, 4		@ G7
	N	56, 29, 2		@ A6
	N	56, 29, 2		@ A6
	N	56, 29, 2		@ A6
	N	56, 29, 2		@ A6
	N	56, 29, 4		@ A6
	N	54, 29, 2		@ G6
	N	56, 29, 4		@ A6
	N	56, 29, 4		@ A6
	N	56, 29, 2		@ A6
	N	59, 29, 4		@ C7
	N	64, 29, 4		@ F7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	56, 29, 2		@ A6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 2		@ A#6
	N	57, 29, 4		@ A#6
	N	55, 29, 2		@ G#6
	N	57, 29, 4		@ A#6
	N	57, 29, 4		@ A#6
	N	57, 29, 2		@ A#6
	N	61, 29, 4		@ D7
	N	64, 29, 4		@ F7
	PAT_END

pat_0808E529:				@ used by s13c7
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	38, 1, 4		@ D#5
	N	38, 1, 2		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 4		@ D5
	N	42, 1, 6		@ G5
	N	42, 1, 4		@ G5
	N	40, 1, 2		@ F5
	N	42, 1, 4		@ G5
	N	42, 1, 4		@ G5
	N	42, 1, 2		@ G5
	N	42, 1, 4		@ G5
	N	40, 1, 4		@ F5
	N	43, 1, 6		@ G#5
	N	43, 1, 2		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	33, 1, 4		@ A#4
	N	35, 1, 4		@ C5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	37, 1, 2		@ D5
	N	40, 1, 4		@ F5
	N	40, 1, 4		@ F5
	N	40, 1, 2		@ F5
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	38, 1, 4		@ D#5
	N	38, 1, 2		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 4		@ D5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	33, 1, 2		@ A#4
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	35, 1, 4		@ C5
	N	33, 1, 4		@ A#4
	N	31, 1, 6		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	43, 1, 4		@ G#5
	N	43, 1, 4		@ G#5
	N	43, 1, 2		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	33, 1, 6		@ A#4
	N	33, 1, 2		@ A#4
	N	37, 1, 2		@ D5
	N	40, 1, 2		@ F5
	N	45, 1, 4		@ A#5
	N	45, 1, 4		@ A#5
	N	45, 1, 2		@ A#5
	N	40, 1, 2		@ F5
	N	37, 1, 2		@ D5
	N	33, 1, 4		@ A#4
	PAT_END

pat_0808E5F9:				@ used by s13c7
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	40, 1, 4		@ F5
	N	40, 1, 4		@ F5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	PAT_END

pat_0808E6BA:				@ used by s13c7
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	32, 1, 4		@ A4
	N	32, 1, 4		@ A4
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	32, 1, 2		@ A4
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	43, 1, 6		@ G#5
	N	43, 1, 4		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 4		@ C5
	N	31, 1, 2		@ G#4
	N	31, 1, 4		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	40, 1, 6		@ F5
	N	40, 1, 4		@ F5
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	40, 1, 2		@ F5
	N	40, 1, 4		@ F5
	N	40, 1, 2		@ F5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	37, 1, 2		@ D5
	N	40, 1, 4		@ F5
	N	45, 1, 2		@ A#5
	N	40, 1, 4		@ F5
	N	37, 1, 4		@ D5
	N	33, 1, 4		@ A#4
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	33, 1, 4		@ A#4
	N	37, 1, 4		@ D5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	37, 1, 2		@ D5
	N	38, 1, 4		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	PAT_END

pat_0808E83E:				@ used by s13c7
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	43, 1, 6		@ G#5
	N	43, 1, 4		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	36, 1, 6		@ C#5
	N	36, 1, 4		@ C#5
	N	35, 1, 2		@ C5
	N	36, 1, 4		@ C#5
	N	36, 1, 4		@ C#5
	N	36, 1, 2		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	36, 1, 6		@ C#5
	N	36, 1, 4		@ C#5
	N	35, 1, 2		@ C5
	N	36, 1, 4		@ C#5
	N	36, 1, 4		@ C#5
	N	36, 1, 2		@ C#5
	N	40, 1, 4		@ F5
	N	43, 1, 4		@ G#5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	43, 1, 6		@ G#5
	N	43, 1, 4		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	38, 1, 4		@ D#5
	N	35, 1, 4		@ C5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	30, 1, 2		@ G4
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	31, 1, 2		@ G#4
	N	43, 1, 4		@ G#5
	N	38, 1, 4		@ D#5
	N	35, 1, 2		@ C5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	31, 1, 2		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	36, 1, 4		@ C#5
	N	40, 1, 4		@ F5
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	36, 1, 2		@ C#5
	N	38, 1, 4		@ D#5
	N	38, 1, 4		@ D#5
	N	38, 1, 2		@ D#5
	N	42, 1, 4		@ G5
	N	45, 1, 4		@ A#5
	N	43, 1, 6		@ G#5
	N	43, 1, 4		@ G#5
	N	38, 1, 2		@ D#5
	N	35, 1, 2		@ C5
	N	31, 1, 4		@ G#4
	N	31, 1, 4		@ G#4
	N	35, 1, 4		@ C5
	N	38, 1, 4		@ D#5
	PAT_END

pat_0808E9AA:				@ used by s13c7
	N	38, 1, 6		@ D#5
	N	38, 1, 4		@ D#5
	N	33, 1, 2		@ A#4
	N	36, 1, 2		@ C#5
	N	38, 1, 2		@ D#5
	N	38, 1, 4		@ D#5
	N	38, 1, 2		@ D#5
	N	42, 1, 4		@ G5
	N	38, 1, 4		@ D#5
	PAT_END

pat_0808E9C6:				@ used by s13c7
	N	31, 1, 6		@ G#4
	N	31, 1, 4		@ G#4
	N	38, 1, 2		@ D#5
	N	33, 1, 2		@ A#4
	N	30, 1, 2		@ G4
	N	30, 1, 4		@ G4
	N	30, 1, 2		@ G4
	N	34, 1, 4		@ B4
	N	30, 1, 4		@ G4
	PAT_END

pat_0808E9E2:				@ used by s13c7
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 5		@ C5
	N	34, 1, 2		@ B4
	N	35, 1, 2		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	40, 1, 4		@ F5
	N	40, 1, 4		@ F5
	N	40, 1, 2		@ F5
	N	35, 1, 2		@ C5
	N	32, 1, 2		@ A4
	N	28, 1, 4		@ F4
	N	28, 1, 4		@ F4
	N	28, 1, 2		@ F4
	N	32, 1, 4		@ A4
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	34, 1, 2		@ B4
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	42, 1, 4		@ G5
	N	42, 1, 4		@ G5
	N	37, 1, 2		@ D5
	N	34, 1, 2		@ B4
	N	30, 1, 2		@ G4
	N	34, 1, 2		@ B4
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	34, 1, 2		@ B4
	N	35, 1, 4		@ C5
	N	35, 1, 6		@ C5
	N	35, 1, 4		@ C5
	N	34, 1, 2		@ B4
	N	35, 1, 4		@ C5
	N	35, 1, 4		@ C5
	N	35, 1, 2		@ C5
	N	39, 1, 4		@ E5
	N	42, 1, 4		@ G5
	N	28, 1, 6		@ F4
	N	28, 1, 5		@ F4
	N	28, 1, 4		@ F4
	N	32, 1, 2		@ A4
	N	35, 1, 4		@ C5
	N	40, 1, 4		@ F5
	N	35, 1, 4		@ C5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	28, 1, 2		@ F4
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	N	33, 1, 6		@ A#4
	N	33, 1, 4		@ A#4
	N	31, 1, 2		@ G#4
	N	33, 1, 4		@ A#4
	N	33, 1, 4		@ A#4
	N	33, 1, 2		@ A#4
	N	37, 1, 4		@ D5
	N	40, 1, 4		@ F5
	PAT_END

pat_0808EAB5:				@ used by s13c8
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 3, 2		@ C#6
	PAT_END

pat_0808EB85:				@ used by s13c8
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 3, 2		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 6		@ C#6
	N	48, 3, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	48, 2, 2		@ C#6
	N	48, 2, 4		@ C#6
	N	50, 10, 2		@ D#6
	N	48, 10, 2		@ C#6
	N	45, 10, 2		@ A#5
	N	41, 10, 2		@ F#5
	PAT_END
@ 0808EC55-0808EC58: 3 bytes, after the pattern end
	.byte	0x00, 0x00, 0x00

seq_s00_c0:				@ 0808EC58
	SEQ_PAN 0xFF
	SEQ_TEMPO 255
	SEQ_PAT	pat_08082908, 0, 1
	SEQ_CONDFLAG 1
	SEQ_END

seq_s00_c1:				@ 0808EC84
	SEQ_PAT	pat_08082908, 0, 1
	SEQ_END

seq_s00_c2:				@ 0808EC98
	SEQ_PAT	pat_08082908, 0, 1
	SEQ_END

seq_s00_c3:				@ 0808ECAC
	SEQ_PAT	pat_08082908, 0, 1
	SEQ_END

seq_s00_c4:				@ 0808ECC0
	SEQ_PAT	pat_0808290C, 0, 1
	SEQ_END

seq_s01_c0:				@ 0808ECD4
	SEQ_PAN 0xFF
	SEQ_TEMPO 164
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808362E, -11, 1
	SEQ_PAT	pat_0808368F, -11, 1
	SEQ_PAT	pat_08083750, -11, 2
	SEQ_PAT	pat_080837B1, -11, 1
	SEQ_PAT	pat_08083872, -11, 1
	SEQ_PAT	pat_080838D3, -11, 1
	SEQ_PAT	pat_0808368F, -11, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 16

seq_s01_c1:				@ 0808ED84
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 32
	SEQ_END
	SEQ_JUMP 4

seq_s01_c2:				@ 0808EDB0
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 16
	SEQ_END
	SEQ_JUMP 0

seq_s01_c3:				@ 0808EDDC
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_080839C4, 0, 3
	SEQ_PAT	pat_080839C4, 0, 9
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 8

seq_s01_c4:				@ 0808EE24
	SEQ_PAT	pat_08082918, 14, 1
	SEQ_PAT	pat_08082979, 14, 1
	SEQ_PAT	pat_08082A3A, 14, 2
	SEQ_PAT	pat_08082AB3, 14, 1
	SEQ_PAT	pat_08082B7D, 14, 1
	SEQ_PAT	pat_08082BDE, 14, 1
	SEQ_PAT	pat_08082979, 14, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 8

seq_s01_c5:				@ 0808EEAC
	SEQ_PAT	pat_0808290C, 0, 4
	SEQ_PAT	pat_08082CA2, -10, 1
	SEQ_PAT	pat_08082D3F, -10, 2
	SEQ_PAT	pat_08082DC4, -10, 1
	SEQ_PAT	pat_08082EB8, -10, 1
	SEQ_PAT	pat_08082F07, -10, 1
	SEQ_PAT	pat_08082CA2, -10, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 8

seq_s01_c6:				@ 0808EF34
	SEQ_PAT	pat_0808290C, 0, 12
	SEQ_PAT	pat_080832A5, -22, 1
	SEQ_PAT	pat_08083348, -10, 1
	SEQ_PAT	pat_0808343C, -10, 1
	SEQ_PAT	pat_0808348B, -10, 1
	SEQ_PAT	pat_08083208, -10, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 4

seq_s01_c7:				@ 0808EFAC
	SEQ_PAT	pat_0808356D, 1, 3
	SEQ_PAT	pat_0808356D, 1, 9
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 4

seq_s02_c0:				@ 0808EFE4
	SEQ_PAN 0xFF
	SEQ_TEMPO 239
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08084229, -9, 3
	SEQ_PAT	pat_0808427E, -9, 1
	SEQ_PAT	pat_08084229, -9, 2
	SEQ_PAT	pat_08084327, -9, 1
	SEQ_PAT	pat_080843D0, -9, 1
	SEQ_PAT	pat_08084229, -7, 2
	SEQ_PAT	pat_0808427E, -7, 1
	SEQ_PAT	pat_08084479, -9, 1
	SEQ_PAT	pat_08084522, -9, 1
	SEQ_PAT	pat_0808458C, -9, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s02_c1:				@ 0808F0B4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s02_c2:				@ 0808F0D8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s02_c3:				@ 0808F0FC
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_080845CC, 0, 19
	SEQ_JUMP 0

seq_s02_c4:				@ 0808F124
	SEQ_PAT	pat_0808290C, 0, 6
	SEQ_PAT	pat_08083A85, -8, 1
	SEQ_PAT	pat_08083B0A, -8, 1
	SEQ_PAT	pat_08083A85, -8, 1
	SEQ_PAT	pat_08083BB3, -8, 1
	SEQ_PAT	pat_08083C4D, -8, 1
	SEQ_PAT	pat_08083A85, -6, 1
	SEQ_PAT	pat_08083B0A, -6, 1
	SEQ_PAT	pat_08083CD2, -8, 1
	SEQ_PAT	pat_08083D57, -8, 1
	SEQ_PAT	pat_0808290C, 0, 4
	SEQ_PAT	pat_08082910, 0, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s02_c5:				@ 0808F1FC
	SEQ_PAT	pat_08083DB2, 0, 19
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s02_c6:				@ 0808F224
	SEQ_PAT	pat_08083DF2, 16, 3
	SEQ_PAT	pat_08083E47, 16, 1
	SEQ_PAT	pat_08083DF2, 16, 2
	SEQ_PAT	pat_08083EF0, 16, 1
	SEQ_PAT	pat_08083F9C, 16, 1
	SEQ_PAT	pat_08083DF2, 18, 2
	SEQ_PAT	pat_08083E47, 18, 1
	SEQ_PAT	pat_08084042, 16, 1
	SEQ_PAT	pat_080840EB, 16, 1
	SEQ_PAT	pat_08084158, 16, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s02_c7:				@ 0808F2DC
	SEQ_PAT	pat_08084198, 1, 19
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s03_c0:				@ 0808F304
	SEQ_PAN 0xFF
	SEQ_TEMPO 188
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08084B7F, -13, 1
	SEQ_PAT	pat_08084BD4, -13, 2
	SEQ_PAT	pat_08084C7D, -13, 2
	SEQ_PAT	pat_08084BD4, -13, 2
	SEQ_PAT	pat_08084C7D, -13, 2
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s03_c1:				@ 0808F384
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s03_c2:				@ 0808F3A8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s03_c3:				@ 0808F3CC
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08084D26, 0, 17
	SEQ_JUMP 0

seq_s03_c4:				@ 0808F3F4
	SEQ_PAT	pat_08084669, -12, 1
	SEQ_PAT	pat_0808468E, -12, 2
	SEQ_PAT	pat_08084740, -12, 1
	SEQ_PAT	pat_080847A1, -12, 1
	SEQ_PAT	pat_0808468E, -12, 2
	SEQ_PAT	pat_08084740, -12, 1
	SEQ_PAT	pat_080847A1, -12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s03_c5:				@ 0808F47C
	SEQ_PAT	pat_0808290C, 0, 12
	SEQ_PAT	pat_08084823, -12, 1
	SEQ_PAT	pat_0808290C, 0, 24
	SEQ_PAT	pat_08084823, -12, 1
	SEQ_PAT	pat_08084857, -12, 1
	SEQ_PAT	pat_080848B8, -12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s03_c6:				@ 0808F4F4
	SEQ_PAT	pat_080848F2, 12, 1
	SEQ_PAT	pat_0808493B, 12, 2
	SEQ_PAT	pat_080849CC, 12, 2
	SEQ_PAT	pat_0808493B, 12, 2
	SEQ_PAT	pat_080849CC, 12, 2
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s03_c7:				@ 0808F55C
	SEQ_PAT	pat_08084A5D, 1, 1
	SEQ_PAT	pat_08084ABE, 1, 8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s04_c0:				@ 0808F594
	SEQ_PAN 0xFF
	SEQ_TEMPO 171
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08084D93, -13, 2
	SEQ_PAT	pat_08084E24, -13, 7
	SEQ_PAT	pat_08084E37, -13, 1
	SEQ_PAT	pat_08084E37, -13, 3
	SEQ_PAT	pat_08084E24, -13, 4
	SEQ_PAT	pat_08084E37, -13, 1
	SEQ_PAT	pat_08084E37, -13, 3
	SEQ_PAT	pat_08084E24, -13, 4
	SEQ_PAT	pat_08084E37, -13, 1
	SEQ_PAT	pat_08084E24, -13, 7
	SEQ_PAT	pat_08084E37, -13, 1
	SEQ_PAT	pat_08084D93, -13, 1
	SEQ_PAT	pat_08084E4A, -13, 3
	SEQ_PAT	pat_08084E6F, -13, 1
	SEQ_PAT	pat_08084E94, -13, 2
	SEQ_PAT	pat_08084EB9, -13, 1
	SEQ_PAT	pat_08084EDE, -13, 1
	SEQ_PAT	pat_08084F03, -13, 2
	SEQ_PAT	pat_08084F16, -13, 2
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s04_c1:				@ 0808F6F4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s04_c2:				@ 0808F718
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s04_c3:				@ 0808F73C
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08084F29, 0, 38
	SEQ_JUMP 0

seq_s04_c4:				@ 0808F764
	SEQ_PAT	pat_08084F5A, -24, 2
	SEQ_PAT	pat_08084F94, -24, 1
	SEQ_PAT	pat_08085049, -24, 1
	SEQ_PAT	pat_08085049, -24, 1
	SEQ_PAT	pat_08084F94, -24, 1
	SEQ_PAT	pat_08084F5A, -24, 1
	SEQ_PAT	pat_08085180, -24, 1
	SEQ_PAT	pat_08085205, -24, 1
	SEQ_PAT	pat_08085275, -24, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s04_c5:				@ 0808F80C
	SEQ_PAT	pat_080852BB, -24, 1
	SEQ_PAT	pat_080852F5, -24, 1
	SEQ_PAT	pat_08085383, -24, 1
	SEQ_PAT	pat_08085438, -24, 1
	SEQ_PAT	pat_08085383, -24, 1
	SEQ_PAT	pat_080852F5, -24, 1
	SEQ_PAT	pat_08085577, -24, 1
	SEQ_PAT	pat_08085623, -24, 1
	SEQ_PAT	pat_080856BD, -24, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s04_c6:				@ 0808F8B4
	SEQ_PAT	pat_08085700, 12, 2
	SEQ_PAT	pat_0808578B, 12, 1
	SEQ_PAT	pat_08085837, 12, 2
	SEQ_PAT	pat_0808578B, 12, 1
	SEQ_PAT	pat_08085700, 12, 1
	SEQ_PAT	pat_080858BC, 12, 1
	SEQ_PAT	pat_0808594A, 12, 1
	SEQ_PAT	pat_080859CC, 12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s04_c7:				@ 0808F94C
	SEQ_PAT	pat_08085A09, 1, 19
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s05_c0:				@ 0808F974
	SEQ_PAN 0xFF
	SEQ_TEMPO 154
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 8
	SEQ_PAT	pat_08085A85, -37, 1
	SEQ_PAT	pat_08085B04, -37, 1
	SEQ_PAT	pat_08085B8C, -37, 1
	SEQ_PAT	pat_08085C32, -37, 1
	SEQ_PAT	pat_08085CF0, -37, 1
	SEQ_PAT	pat_08085D81, -37, 1
	SEQ_PAT	pat_08085DDC, -37, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s05_c1:				@ 0808FA24
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08085E88, -37, 3
	SEQ_PAT	pat_08085F79, -37, 1
	SEQ_PAT	pat_0808606A, -37, 2
	SEQ_PAT	pat_0808615B, -37, 1
	SEQ_PAT	pat_0808624C, -37, 1
	SEQ_JUMP 0

seq_s05_c2:				@ 0808FA8C
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 7
	SEQ_END

seq_s05_c3:				@ 0808FAB0
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08086340, 0, 16
	SEQ_JUMP 0

seq_s05_c4:				@ 0808FAD8
	SEQ_PAT	pat_0808290C, 0, 8
	SEQ_PAT	pat_080863CE, -24, 1
	SEQ_PAT	pat_0808644A, -24, 1
	SEQ_PAT	pat_080864D2, -24, 1
	SEQ_PAT	pat_08086578, -24, 1
	SEQ_PAT	pat_08086636, -24, 1
	SEQ_PAT	pat_080866C7, -24, 1
	SEQ_PAT	pat_08086722, -24, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s05_c5:				@ 0808FB70
	SEQ_PAT	pat_080867CE, -12, 3
	SEQ_PAT	pat_080868BF, -12, 1
	SEQ_PAT	pat_080869B0, -12, 2
	SEQ_PAT	pat_08086AA1, -12, 1
	SEQ_PAT	pat_08086B92, -12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s05_c6:				@ 0808FBD8
	SEQ_PAT	pat_08086C86, 12, 3
	SEQ_PAT	pat_08086D47, 12, 1
	SEQ_PAT	pat_08086E08, 12, 2
	SEQ_PAT	pat_08086EC9, 12, 1
	SEQ_PAT	pat_08086F8A, 12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s05_c7:				@ 0808FC40
	SEQ_PAT	pat_0808704B, 1, 8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s06_c0:				@ 0808FC68
	SEQ_PAN 0xFF
	SEQ_TEMPO 205
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 2
	SEQ_END
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s06_c1:				@ 0808FCAC
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s06_c2:				@ 0808FCC0
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s06_c3:				@ 0808FCD4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s06_c4:				@ 0808FCE8
	SEQ_PAT	pat_08087199, 4, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s06_c5:				@ 0808FD0C
	SEQ_PAT	pat_080871A9, 4, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s06_c6:				@ 0808FD30
	SEQ_PAT	pat_080871B9, 4, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s06_c7:				@ 0808FD54
	SEQ_PAT	pat_080871C9, 4, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s07_c0:				@ 0808FD78
	SEQ_PAN 0xFF
	SEQ_TEMPO 154
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 4
	SEQ_PAT	pat_080871D9, -37, 1
	SEQ_PAT	pat_0808727F, -37, 1
	SEQ_PAT	pat_080872E6, -37, 1
	SEQ_PAT	pat_080873A7, -37, 1
	SEQ_PAT	pat_08087450, -37, 1
	SEQ_PAT	pat_080872E6, -37, 1
	SEQ_PAT	pat_08082904, 0, 4
	SEQ_PAT	pat_08087535, -37, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s07_c1:				@ 0808FE38
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 36
	SEQ_PAT	pat_080876F3, -37, 1
	SEQ_PAT	pat_08082904, 0, 8
	SEQ_PAT	pat_08082904, 0, 4
	SEQ_PAT	pat_08087614, -37, 1
	SEQ_JUMP 0

seq_s07_c2:				@ 0808FEA0
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s07_c3:				@ 0808FEB4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s07_c4:				@ 0808FEC8
	SEQ_PAT	pat_080877D8, 0, 1
	SEQ_PAT	pat_0808290C, 0, 1
	SEQ_PAT	pat_080877D8, 0, 1
	SEQ_PAT	pat_0808290C, 0, 1
	SEQ_PAT	pat_080877DC, -24, 1
	SEQ_PAT	pat_0808787F, -24, 1
	SEQ_PAT	pat_080878E6, -24, 1
	SEQ_PAT	pat_080879A7, -24, 1
	SEQ_PAT	pat_08087A50, -24, 1
	SEQ_PAT	pat_080878E6, -24, 1
	SEQ_PAT	pat_0808290C, 0, 4
	SEQ_PAT	pat_08087B35, -24, 1
	SEQ_PAT	pat_080877D8, 0, 1
	SEQ_PAT	pat_08087B35, -24, 1
	SEQ_PAT	pat_080877D8, 0, 1
	SEQ_PAT	pat_08087B35, -24, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s07_c5:				@ 0808FFE0
	SEQ_PAT	pat_08087B7E, -12, 1
	SEQ_PAT	pat_08087C03, -12, 2
	SEQ_PAT	pat_08087C7C, -12, 1
	SEQ_PAT	pat_08087D70, -12, 1
	SEQ_PAT	pat_08087E64, -12, 1
	SEQ_PAT	pat_08087F79, -12, 1
	SEQ_PAT	pat_08087D70, -12, 1
	SEQ_PAT	pat_08088085, -12, 3
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s07_c6:				@ 08090078
	SEQ_PAT	pat_080880FE, 12, 1
	SEQ_PAT	pat_0808815F, 12, 1
	SEQ_PAT	pat_08088220, 12, 1
	SEQ_PAT	pat_080882E1, 12, 1
	SEQ_PAT	pat_080883A2, 12, 1
	SEQ_PAT	pat_08088460, 12, 1
	SEQ_PAT	pat_080882E1, 12, 1
	SEQ_PAT	pat_08088521, 12, 3
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s07_c7:				@ 08090110
	SEQ_PAT	pat_08088582, 0, 16
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s08_c0:				@ 08090138
	SEQ_PAN 0xFF
	SEQ_TEMPO 178
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808858F, 3, 1
	SEQ_PAT	pat_08088620, 3, 2
	SEQ_PAT	pat_08088741, 3, 1
	SEQ_PAT	pat_08088620, 3, 1
	SEQ_PAT	pat_080888F2, 3, 4
	SEQ_PAT	pat_08088620, 3, 1
	SEQ_PAT	pat_08088741, 3, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s08_c1:				@ 080901D8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s08_c2:				@ 080901EC
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s08_c3:				@ 08090200
	SEQ_PAT	pat_08088990, 0, 76
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s08_c4:				@ 08090228
	SEQ_PAT	pat_0808290C, 0, 3
	SEQ_PAT	pat_080889B5, -20, 1
	SEQ_PAT	pat_08088B90, -20, 1
	SEQ_PAT	pat_08088CED, -20, 1
	SEQ_PAT	pat_08088DCC, -20, 4
	SEQ_PAT	pat_08088CED, -20, 1
	SEQ_PAT	pat_08088B90, -20, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s08_c5:				@ 080902B0
	SEQ_PAT	pat_08088E5D, -20, 1
	SEQ_PAT	pat_08088EEE, -20, 2
	SEQ_PAT	pat_0808900F, -20, 1
	SEQ_PAT	pat_08088EEE, -20, 1
	SEQ_PAT	pat_0808290C, 0, 8
	SEQ_PAT	pat_0808908B, -20, 1
	SEQ_PAT	pat_08088EEE, -20, 1
	SEQ_PAT	pat_0808900F, -20, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s08_c6:				@ 08090348
	SEQ_PAT	pat_08089110, 16, 1
	SEQ_PAT	pat_0808917A, 16, 2
	SEQ_PAT	pat_08089250, 16, 1
	SEQ_PAT	pat_0808917A, 16, 1
	SEQ_PAT	pat_0808938F, 16, 4
	SEQ_PAT	pat_0808917A, 16, 1
	SEQ_PAT	pat_08089250, 16, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s08_c7:				@ 080903D0
	SEQ_PAT	pat_080893FF, 1, 19
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s09_c0:				@ 080903F8
	SEQ_PAN 0xFF
	SEQ_TEMPO 193
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 8
	SEQ_PAT	pat_0808946F, -39, 1
	SEQ_PAT	pat_0808951B, -39, 1
	SEQ_PAT	pat_08089618, -39, 1
	SEQ_PAT	pat_0808968B, -39, 1
	SEQ_PAT	pat_0808971F, -39, 1
	SEQ_PAT	pat_080897E6, -39, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s09_c1:				@ 08090498
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s09_c2:				@ 080904AC
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s09_c3:				@ 080904C0
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_080898BF, 0, 18
	SEQ_JUMP 0

seq_s09_c4:				@ 080904E8
	SEQ_PAT	pat_0808290C, 0, 8
	SEQ_PAT	pat_08089920, -26, 1
	SEQ_PAT	pat_080899C9, -26, 1
	SEQ_PAT	pat_08089AC6, -26, 1
	SEQ_PAT	pat_08089B39, -26, 1
	SEQ_PAT	pat_08089BCD, -26, 1
	SEQ_PAT	pat_08089C94, -26, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s09_c5:				@ 08090570
	SEQ_PAT	pat_08089D6A, -14, 1
	SEQ_PAT	pat_08089DE3, -14, 1
	SEQ_PAT	pat_08089DE3, -14, 1
	SEQ_PAT	pat_08089E86, -14, 1
	SEQ_PAT	pat_08089F26, -14, 1
	SEQ_PAT	pat_08089FB7, -14, 1
	SEQ_PAT	pat_0808A0D5, -14, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s09_c6:				@ 080905F8
	SEQ_PAT	pat_0808A202, 10, 1
	SEQ_PAT	pat_0808A284, 10, 1
	SEQ_PAT	pat_0808A321, 10, 1
	SEQ_PAT	pat_0808A3C1, 10, 1
	SEQ_PAT	pat_0808A44C, 10, 1
	SEQ_PAT	pat_0808A4E3, 10, 1
	SEQ_PAT	pat_0808A5DA, 10, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s09_c7:				@ 08090680
	SEQ_PAT	pat_0808A6CE, 1, 18
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s10_c0:				@ 080906A8
	SEQ_PAN 0xFF
	SEQ_TEMPO 240
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 12
	SEQ_PAT	pat_0808A72F, -37, 1
	SEQ_PAT	pat_0808A7B4, -37, 1
	SEQ_PAT	pat_0808A863, -25, 1
	SEQ_PAT	pat_0808A8F1, -25, 1
	SEQ_PAT	pat_0808A994, -37, 1
	SEQ_PAT	pat_0808A9DD, -37, 1
	SEQ_PAT	pat_0808A863, -25, 1
	SEQ_PAT	pat_0808A8F1, -25, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s10_c1:				@ 08090768
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s10_c2:				@ 0809077C
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s10_c3:				@ 08090790
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808AA32, 0, 12
	SEQ_PAT	pat_0808AA87, 0, 1
	SEQ_PAT	pat_0808AA32, 0, 24
	SEQ_JUMP 0

seq_s10_c4:				@ 080907D8
	SEQ_PAT	pat_0808AAB2, -12, 2
	SEQ_PAT	pat_0808ABD3, -12, 1
	SEQ_PAT	pat_0808ACA6, -12, 1
	SEQ_PAT	pat_0808AD34, -12, 1
	SEQ_PAT	pat_0808ADD7, -12, 1
	SEQ_PAT	pat_0808AE6E, -12, 1
	SEQ_PAT	pat_0808ACA6, -12, 1
	SEQ_PAT	pat_0808AD34, -12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s10_c5:				@ 08090870
	SEQ_PAT	pat_0808AF11, -24, 2
	SEQ_PAT	pat_0808AFCC, -24, 1
	SEQ_PAT	pat_0808B0A8, -24, 1
	SEQ_PAT	pat_0808B169, -24, 1
	SEQ_PAT	pat_0808B22D, -24, 1
	SEQ_PAT	pat_0808B2F4, -24, 1
	SEQ_PAT	pat_0808B0A8, -24, 1
	SEQ_PAT	pat_0808B169, -24, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s10_c6:				@ 08090908
	SEQ_PAT	pat_0808B3BB, 12, 2
	SEQ_PAT	pat_0808B44C, 12, 1
	SEQ_PAT	pat_0808B4F8, 12, 1
	SEQ_PAT	pat_0808B589, 12, 1
	SEQ_PAT	pat_0808B61D, 12, 1
	SEQ_PAT	pat_0808B6B7, 12, 1
	SEQ_PAT	pat_0808B4F8, 12, 1
	SEQ_PAT	pat_0808B589, 12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s10_c7:				@ 080909A0
	SEQ_PAT	pat_0808B74B, 1, 12
	SEQ_PAT	pat_0808B77F, 1, 1
	SEQ_PAT	pat_0808B74B, 1, 24
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s11_c0:				@ 080909E8
	SEQ_PAN 0xFF
	SEQ_TEMPO 154
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808B79B, -35, 2
	SEQ_PAT	pat_0808B79B, -39, 2
	SEQ_PAT	pat_0808B79B, -35, 2
	SEQ_PAT	pat_0808B79B, -39, 2
	SEQ_PAT	pat_0808B85C, -35, 1
	SEQ_PAT	pat_0808B85C, -37, 1
	SEQ_PAT	pat_0808B85C, -39, 1
	SEQ_PAT	pat_0808B91D, -41, 1
	SEQ_PAT	pat_0808B91D, -43, 1
	SEQ_PAT	pat_0808B9DE, -45, 1
	SEQ_PAT	pat_0808BA9F, -35, 4
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s11_c1:				@ 08090AC8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808BB60, -11, 2
	SEQ_PAT	pat_0808BB60, -15, 2
	SEQ_PAT	pat_0808BB60, -11, 2
	SEQ_PAT	pat_0808BB60, -15, 2
	SEQ_PAT	pat_0808BB67, -11, 1
	SEQ_PAT	pat_0808BB67, -13, 1
	SEQ_PAT	pat_0808BB67, -15, 1
	SEQ_PAT	pat_0808BB77, -17, 1
	SEQ_PAT	pat_0808BB77, -19, 1
	SEQ_PAT	pat_0808BB87, -21, 1
	SEQ_PAT	pat_0808BB97, -11, 4
	SEQ_JUMP 0

seq_s11_c2:				@ 08090B90
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s11_c3:				@ 08090BA4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808BBB0, 0, 9
	SEQ_JUMP 0

seq_s11_c4:				@ 08090BCC
	SEQ_PAT	pat_0808BCEC, -10, 2
	SEQ_PAT	pat_0808290C, 0, 8
	SEQ_PAT	pat_0808BD71, -10, 1
	SEQ_PAT	pat_0808BE9B, -10, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s11_c5:				@ 08090C24
	SEQ_PAT	pat_0808290C, 0, 16
	SEQ_PAT	pat_0808BFD7, -10, 1
	SEQ_PAT	pat_0808C0B0, -10, 1
	SEQ_PAT	pat_0808C0B0, -12, 1
	SEQ_PAT	pat_0808C0B0, -14, 1
	SEQ_PAT	pat_0808C0E1, -16, 1
	SEQ_PAT	pat_0808C0E1, -18, 1
	SEQ_PAT	pat_0808C112, -20, 1
	SEQ_PAT	pat_0808C143, -10, 4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s11_c6:				@ 08090CCC
	SEQ_PAT	pat_0808C174, 14, 1
	SEQ_PAT	pat_0808C174, 10, 1
	SEQ_PAT	pat_0808C220, 14, 1
	SEQ_PAT	pat_0808C380, 14, 1
	SEQ_PAT	pat_0808C564, 14, 2
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s11_c7:				@ 08090D34
	SEQ_PAT	pat_0808C5EC, 1, 3
	SEQ_PAT	pat_0808C61D, 1, 1
	SEQ_PAT	pat_0808C660, 1, 7
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s12_c0:				@ 08090D7C
	SEQ_PAN 0xFF
	SEQ_TEMPO 185
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 12
	SEQ_PAT	pat_0808C6DF, -37, 1
	SEQ_PAT	pat_0808C76A, -37, 2
	SEQ_PAT	pat_08082904, 0, 12
	SEQ_PAT	pat_0808C7EC, -37, 1
	SEQ_PAT	pat_08082904, 0, 8
	SEQ_PAT	pat_0808C874, -37, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s12_c1:				@ 08090E1C
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_08082904, 0, 12
	SEQ_PAT	pat_0808C6DF, -49, 1
	SEQ_PAT	pat_0808C76A, -49, 2
	SEQ_PAT	pat_08082904, 0, 12
	SEQ_PAT	pat_0808C7EC, -25, 1
	SEQ_PAT	pat_08082904, 0, 8
	SEQ_PAT	pat_0808C874, -25, 1
	SEQ_JUMP 0

seq_s12_c2:				@ 08090EA4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s12_c3:				@ 08090EB8
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808C8F3, 0, 1
	SEQ_PAT	pat_0808C96C, 0, 4
	SEQ_PAT	pat_0808C9E2, 0, 4
	SEQ_PAT	pat_0808C8F3, 0, 1
	SEQ_PAT	pat_0808C9E2, 0, 8
	SEQ_JUMP 0

seq_s12_c4:				@ 08090F20
	SEQ_PAT	pat_0808CA5E, 0, 1
	SEQ_PAT	pat_0808CA77, -24, 2
	SEQ_PAT	pat_0808CB41, -24, 2
	SEQ_PAT	pat_0808CA5E, 0, 1
	SEQ_PAT	pat_0808CC05, -24, 1
	SEQ_PAT	pat_0808CC05, -22, 1
	SEQ_PAT	pat_0808CC9F, -24, 2
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s12_c5:				@ 08090FA8
	SEQ_PAT	pat_0808CD3C, -24, 1
	SEQ_PAT	pat_0808CD85, -24, 2
	SEQ_PAT	pat_0808CDFE, -24, 2
	SEQ_PAT	pat_0808CD3C, -24, 1
	SEQ_PAT	pat_0808CE77, -24, 1
	SEQ_PAT	pat_0808CE77, -22, 1
	SEQ_PAT	pat_0808CEF0, -24, 2
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s12_c6:				@ 08091030
	SEQ_PAT	pat_0808CF66, 12, 1
	SEQ_PAT	pat_0808CF97, 12, 2
	SEQ_PAT	pat_0808D019, 12, 2
	SEQ_PAT	pat_0808CF66, 12, 1
	SEQ_PAT	pat_0808D098, 12, 1
	SEQ_PAT	pat_0808D098, 14, 1
	SEQ_PAT	pat_0808D11A, 12, 2
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s12_c7:				@ 080910B8
	SEQ_PAT	pat_0808D18D, 1, 1
	SEQ_PAT	pat_0808D1DC, 1, 2
	SEQ_PAT	pat_0808D270, 1, 2
	SEQ_PAT	pat_0808D18D, 1, 1
	SEQ_PAT	pat_0808D270, 1, 4
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s13_c0:				@ 08091120
	SEQ_PAN 0xFF
	SEQ_TEMPO 188
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808290C, 0, 24
	SEQ_PAT	pat_0808D788, -25, 1
	SEQ_PAT	pat_0808290C, 0, 16
	SEQ_PAT	pat_0808D81C, -25, 1
	SEQ_PAT	pat_0808290C, 0, 8
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s13_c1:				@ 080911A0
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808D32E, -13, 1
	SEQ_PAT	pat_0808D3BF, -13, 2
	SEQ_PAT	pat_0808D450, -13, 1
	SEQ_PAT	pat_0808D571, -13, 1
	SEQ_PAT	pat_0808D6AD, -13, 1
	SEQ_PAT	pat_0808D571, -13, 1
	SEQ_PAT	pat_0808D6C3, -13, 1
	SEQ_PAT	pat_0808D6DC, -13, 1
	SEQ_JUMP 0

seq_s13_c2:				@ 08091238
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_END

seq_s13_c3:				@ 0809124C
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_PAT	pat_0808D925, 0, 20
	SEQ_JUMP 0

seq_s13_c4:				@ 08091274
	SEQ_PAT	pat_0808290C, 0, 7
	SEQ_PAT	pat_0808D9FB, -12, 1
	SEQ_PAT	pat_0808DA95, -12, 1
	SEQ_PAT	pat_0808DB29, -12, 1
	SEQ_PAT	pat_0808DC44, -12, 1
	SEQ_PAT	pat_0808DD4D, -12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s13_c5:				@ 080912EC
	SEQ_PAT	pat_0808DDC9, -12, 1
	SEQ_PAT	pat_0808DED2, -12, 2
	SEQ_PAT	pat_0808DFDB, -12, 1
	SEQ_PAT	pat_0808E1EC, -12, 1
	SEQ_PAT	pat_0808E3DC, -12, 1
	SEQ_PAT	pat_0808E1EC, -12, 1
	SEQ_PAT	pat_0808E3FE, -12, 1
	SEQ_PAT	pat_0808E420, -12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s13_c6:				@ 08091384
	SEQ_PAT	pat_0808E529, 12, 1
	SEQ_PAT	pat_0808E5F9, 12, 2
	SEQ_PAT	pat_0808E6BA, 12, 1
	SEQ_PAT	pat_0808E83E, 12, 1
	SEQ_PAT	pat_0808E9AA, 12, 1
	SEQ_PAT	pat_0808E83E, 12, 1
	SEQ_PAT	pat_0808E9C6, 12, 1
	SEQ_PAT	pat_0808E9E2, 12, 1
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

seq_s13_c7:				@ 0809141C
	SEQ_PAT	pat_0808EAB5, 1, 2
	SEQ_PAT	pat_0808EB85, 1, 1
	SEQ_PAT	pat_0808EAB5, 1, 1
	SEQ_PAT	pat_0808EB85, 1, 1
	SEQ_PAT	pat_0808EAB5, 1, 1
	SEQ_PAT	pat_0808EB85, 1, 1
	SEQ_PAT	pat_0808EAB5, 1, 1
	SEQ_PAT	pat_0808EB85, 1, 2
	SEQ_PAT	pat_08082914, 0, 1
	SEQ_JUMP 0

	.global mcFreqLo
mcFreqLo:				@ 080914B4  PSG frequency register low byte, 97 notes
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
mcFreqHi:				@ 08091515  PSG frequency register high byte, 97 notes
	.byte	0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04	@ 0..
	.byte	0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06	@ 12..
	.byte	0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x07	@ 24..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 36..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 48..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 60..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 72..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 84..
	.byte	0x00	@ 96..
@ 08091576-08091578: 2 bytes, padding
	.byte	0x00, 0x00

@ mcSongTable: {seq ch1..ch8, note-length table}; ch1-4 PSG, ch5-8 mixed PCM
	.global mcSongTable
mcSongTable:				@ 08091578
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
	.word	seq_s10_c0, seq_s10_c1, seq_s10_c2, seq_s10_c3, seq_s10_c4, seq_s10_c5, seq_s10_c6, seq_s10_c7, durTable0	@ song 10
	.word	seq_s11_c0, seq_s11_c1, seq_s11_c2, seq_s11_c3, seq_s11_c4, seq_s11_c5, seq_s11_c6, seq_s11_c7, durTable0	@ song 11
	.word	seq_s12_c0, seq_s12_c1, seq_s12_c2, seq_s12_c3, seq_s12_c4, seq_s12_c5, seq_s12_c6, seq_s12_c7, durTable0	@ song 12
	.word	seq_s13_c0, seq_s13_c1, seq_s13_c2, seq_s13_c3, seq_s13_c4, seq_s13_c5, seq_s13_c6, seq_s13_c7, durTable0	@ song 13

mod_08091770:				@ env of inst 1
	.hword	240, 2, 0, 1, 112, 1, 0, 1
	.hword	255, 0

mod_08091784:				@ env of inst 2
	.hword	240, 1, 176, 1, 112, 2, 48, 1
	.hword	32, 5, 16, 15, 0, 1, 255, 0
	.hword	64, 1, 48, 1, 32, 1, 16, 1
	.hword	0, 1, 255, 0

mod_080917BC:				@ env of inst 5
	.hword	64, 1, 48, 1, 32, 2, 16, 2
	.hword	16, 8, 16, 2, 16, 2, 0, 1
	.hword	255, 0

mod_080917E0:				@ env of inst 6
	.hword	144, 1, 64, 1, 48, 2, 32, 3
	.hword	16, 6, 0, 1, 255, 0, 16, 1
	.hword	48, 1, 80, 1, 128, 5, 112, 10
	.hword	96, 100, 80, 100, 64, 100, 48, 100
	.hword	32, 100, 16, 100, 0, 1, 255, 0

mod_08091830:				@ env of inst 8
	.hword	32, 1, 128, 2, 64, 4, 96, 9
	.hword	0, 1, 255, 0, 0, 0, 0, 0
	.hword	32, 1, 128, 1, 64, 4, 96, 12
	.hword	0, 1, 255, 0, 0, 0, 0, 0

mod_08091870:				@ env of inst 10
	.hword	48, 4, 16, 1, 0, 1, 255, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0

mod_080918A4:				@ env of inst 12; env of inst 13; env of inst 14; env of inst 15
	.hword	48, 1, 16, 1, 48, 1, 64, 2
	.hword	48, 2, 16, 5, 0, 1, 255, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0

mod_080918D8:				@ env of inst 22; env of inst 23; env of inst 24; env of inst 25; env of inst 26; env of inst 27
	.hword	32, 1, 48, 2, 32, 25, 32, 25
	.hword	16, 175, 16, 175, 16, 175, 0, 1
	.hword	255, 0, 0, 0

mod_08091900:				@ env of inst 29
	.hword	16, 1, 32, 1, 16, 1, 48, 1
	.hword	64, 1, 32, 1, 16, 1, 0, 6
	.hword	254, 0, 0, 0, 0, 0, 0, 0
	.hword	16, 100, 16, 100, 16, 100, 16, 100
	.hword	16, 100, 254, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0

mod_08091968:				@ env of inst 31
	.hword	16, 1, 32, 1, 48, 2, 32, 12
	.hword	32, 4, 0, 4, 32, 4, 0, 4
	.hword	254, 8, 0, 0, 0, 0, 0, 0

mod_08091998:				@ pitch of inst 1
	.hword	97, 200, 255, 0, 0, 0, 0, 0

mod_080919A8:				@ pitch of inst 2
	.hword	55, 2, 100, 2, 34, 1, 55, 1
	.hword	34, 1, 55, 1, 34, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 16
	.hword	255, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0

mod_08091A28:				@ pitch of inst 3
	.hword	16, 200, 255, 0, 0, 0, 0, 0

mod_08091A38:				@ pitch of inst 4; pitch of inst 5
	.hword	34, 1, 16, 200, 255, 0, 0, 0

mod_08091A48:				@ pitch of inst 6
	.hword	55, 1, 70, 1, 35, 1, 70, 1
	.hword	35, 1, 70, 1, 35, 1, 70, 1
	.hword	35, 1, 70, 1, 35, 1, 70, 1
	.hword	254, 0, 0, 0, 0, 0

mod_08091A84:				@ pitch of inst 12; pitch of inst 13; pitch of inst 14; pitch of inst 15; pitch of inst 31; pitch of inst 7; pitch of inst 8
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	254, 0, 0, 0

mod_08091A9C:				@ pitch of inst 30
	.hword	36, 200, 36, 200, 36, 200, 255, 0
	.hword	0, 0

mod_08091AB0:				@ arp of inst 16; arp of inst 22
	.hword	1, 0, 1, 4, 1, 7, 1, 0
	.hword	1, 4, 1, 7, 254, 0, 0, 0

mod_08091AD0:				@ arp of inst 17; arp of inst 23
	.hword	1, 4, 1, 7, 1, 12, 1, 4
	.hword	1, 7, 1, 12, 254, 0, 0, 0

mod_08091AF0:				@ arp of inst 18; arp of inst 24
	.hword	1, 7, 1, 12, 1, 16, 1, 7
	.hword	1, 12, 1, 16, 254, 0, 0, 0

mod_08091B10:				@ arp of inst 19; arp of inst 25
	.hword	1, 0, 1, 3, 1, 7, 1, 0
	.hword	1, 3, 1, 7, 254, 0, 0, 0

mod_08091B30:				@ arp of inst 20; arp of inst 26
	.hword	1, 3, 1, 7, 1, 12, 1, 3
	.hword	1, 7, 1, 12, 254, 0, 0, 0

mod_08091B50:				@ arp of inst 21; arp of inst 27
	.hword	1, 7, 1, 12, 1, 15, 1, 7
	.hword	1, 12, 1, 15, 254, 0, 0, 0
	.hword	1, 12, 200, 0, 200, 0, 254, 0

@ PSG instruments (9 words): b0<<8 -> CNT_X, lo/hi -> envelope/duty register, then
@ {on, table} for envelope, pitch (noise parameter on ch4) and arpeggio
inst_00:				@ 08091B80
	INSTRUMENT 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0

inst_01:				@ 08091BA4
	INSTRUMENT 0x40, 0xBD, 0x00, 1, mod_08091770, 1, mod_08091998, 0, 0

inst_02:				@ 08091BC8
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08091784, 1, mod_080919A8, 0, 0

inst_03:				@ 08091BEC
	INSTRUMENT 0x40, 0xBC, 0x41, 0, 0, 1, mod_08091A28, 0, 0

inst_04:				@ 08091C10
	INSTRUMENT 0x40, 0xB8, 0x51, 0, 0, 1, mod_08091A38, 0, 0

inst_05:				@ 08091C34
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080917BC, 1, mod_08091A38, 0, 0

inst_06:				@ 08091C58
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080917E0, 1, mod_08091A48, 0, 0

inst_07:				@ 08091C7C
	INSTRUMENT 0x00, 0x40, 0x43, 0, 0, 1, mod_08091A84, 0, 0

inst_08:				@ 08091CA0
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_08091830, 6, mod_08091A84, 0, 0

inst_09:				@ 08091CC4
	INSTRUMENT 0x00, 0x40, 0x27, 0, 0, 0, 0, 0, 0

inst_10:				@ 08091CE8
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_08091870, 0, 0, 0, 0

inst_11:				@ 08091D0C
	INSTRUMENT 0x00, 0x00, 0x34, 0, 0, 0, 0, 0, 0

inst_12:				@ 08091D30
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_080918A4, 6, mod_08091A84, 0, 0

inst_16:				@ 08091D54
	INSTRUMENT 0x00, 0x40, 0x35, 0, 0, 0, 0, 1, mod_08091AB0

inst_17:				@ 08091D78
	INSTRUMENT 0x00, 0x40, 0x35, 0, 0, 0, 0, 1, mod_08091AD0

inst_18:				@ 08091D9C
	INSTRUMENT 0x00, 0x40, 0x35, 0, 0, 0, 0, 1, mod_08091AF0

inst_19:				@ 08091DC0
	INSTRUMENT 0x00, 0x40, 0x35, 0, 0, 0, 0, 1, mod_08091B10

inst_20:				@ 08091DE4
	INSTRUMENT 0x00, 0x40, 0x35, 0, 0, 0, 0, 1, mod_08091B30

inst_21:				@ 08091E08
	INSTRUMENT 0x00, 0x40, 0x35, 0, 0, 0, 0, 1, mod_08091B50

inst_22:				@ 08091E2C
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080918D8, 0, 0, 1, mod_08091AB0

inst_23:				@ 08091E50
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080918D8, 0, 0, 1, mod_08091AD0

inst_24:				@ 08091E74
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080918D8, 0, 0, 1, mod_08091AF0

inst_25:				@ 08091E98
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080918D8, 0, 0, 1, mod_08091B10

inst_26:				@ 08091EBC
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080918D8, 0, 0, 1, mod_08091B30

inst_27:				@ 08091EE0
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_080918D8, 0, 0, 1, mod_08091B50

inst_28:				@ 08091F04
	INSTRUMENT 0x00, 0x80, 0x52, 0, 0, 0, 0, 0, 0

inst_29:				@ 08091F28
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_08091900, 0, 0, 0, 0

inst_30:				@ 08091F4C
	INSTRUMENT 0x00, 0x80, 0x54, 0, 0, 1, mod_08091A9C, 0, 0

inst_31:				@ 08091F70
	INSTRUMENT 0x00, 0x40, 0x00, 1, mod_08091968, 1, mod_08091A84, 0, 0

	.global mcInstTable
mcInstTable:				@ 08091F94
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
	.word	inst_12	@ 12
	.word	inst_12	@ 13
	.word	inst_12	@ 14
	.word	inst_12	@ 15
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
