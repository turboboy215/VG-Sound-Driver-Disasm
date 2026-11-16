@ ============================================================================
@ snood_sound_data.s -- music and SFX data of Snood (GBA)
@ Mark Cooksey sound driver, "Build A" (E.T. driver without the DirectSound music channels).
@ Reconstructed from "Snood (E) (M5).gba" (ASQP).
@   section .musicdata  0834FEEC-083FF880 (719252 bytes)
@ Linking with snood_sound_data.ld and objcopy reproduces the range byte for byte
@ (make -f snood_sound.mk).  SFX PCM is pulled in from snood_pcm.bin.
@ All labels were assigned during the analysis; the ROM has no symbols.
@ Formats: claude/cooksey-et-technical-reference.md and claude/cooksey-gba-variants-comparison.md.
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
@ ---- PSG instrument: 9 words (channels 1-4 only)
	.macro INSTRUMENT b0, lo, hi, envOn, env, pitchOn, pitch, arpOn, arp
	.word \b0, \lo, \hi, \envOn, \env, \pitchOn, \pitch, \arpOn, \arp
	.endm

@ ----------------------------------------------------------------------------
	.section .musicdata, "a", %progbits
@ ----------------------------------------------------------------------------

@ SFX PCM: 8-bit signed, played by mcDsSfxStart through DMA at 11 268 Hz (Timer reload 0xFA2F).
	.global pcm_0834FEEC
pcm_0834FEEC:				@ 0834FEEC, 4908 bytes
	.incbin "snood_pcm.bin", 0x0, 0x132C
	.global pcm_08351218
pcm_08351218:				@ 08351218, 1984 bytes
	.incbin "snood_pcm.bin", 0x132C, 0x7C0
	.global pcm_083519D8
pcm_083519D8:				@ 083519D8, 2596 bytes
	.incbin "snood_pcm.bin", 0x1AEC, 0xA24
	.global pcm_083523FC
pcm_083523FC:				@ 083523FC, 4552 bytes
	.incbin "snood_pcm.bin", 0x2510, 0x11C8
	.global pcm_083535C4
pcm_083535C4:				@ 083535C4, 6616 bytes
	.incbin "snood_pcm.bin", 0x36D8, 0x19D8
	.global pcm_08354F9C
pcm_08354F9C:				@ 08354F9C, 3308 bytes
	.incbin "snood_pcm.bin", 0x50B0, 0xCEC
	.global pcm_08355C88
pcm_08355C88:				@ 08355C88, 5464 bytes
	.incbin "snood_pcm.bin", 0x5D9C, 0x1558
	.global pcm_083571E0
pcm_083571E0:				@ 083571E0, 12800 bytes
	.incbin "snood_pcm.bin", 0x72F4, 0x3200
	.global pcm_0835A3E0
pcm_0835A3E0:				@ 0835A3E0, 10688 bytes
	.incbin "snood_pcm.bin", 0xA4F4, 0x29C0
	.global pcm_0835CDA0
pcm_0835CDA0:				@ 0835CDA0, 5032 bytes
	.incbin "snood_pcm.bin", 0xCEB4, 0x13A8
	.global pcm_0835E148
pcm_0835E148:				@ 0835E148, 1264 bytes
	.incbin "snood_pcm.bin", 0xE25C, 0x4F0
	.global pcm_0835E638
pcm_0835E638:				@ 0835E638, 14592 bytes
	.incbin "snood_pcm.bin", 0xE74C, 0x3900
	.global pcm_08361F38
pcm_08361F38:				@ 08361F38, 8320 bytes
	.incbin "snood_pcm.bin", 0x1204C, 0x2080
	.global pcm_08363FB8
pcm_08363FB8:				@ 08363FB8, 4912 bytes
	.incbin "snood_pcm.bin", 0x140CC, 0x1330
	.global pcm_083652E8
pcm_083652E8:				@ 083652E8, 3680 bytes
	.incbin "snood_pcm.bin", 0x153FC, 0xE60
	.global pcm_08366148
pcm_08366148:				@ 08366148, 4968 bytes
	.incbin "snood_pcm.bin", 0x1625C, 0x1368
	.global pcm_083674B0
pcm_083674B0:				@ 083674B0, 4912 bytes
	.incbin "snood_pcm.bin", 0x175C4, 0x1330
	.global pcm_083687E0
pcm_083687E0:				@ 083687E0, 12928 bytes
	.incbin "snood_pcm.bin", 0x188F4, 0x3280
	.global pcm_0836BA60
pcm_0836BA60:				@ 0836BA60, 6552 bytes
	.incbin "snood_pcm.bin", 0x1BB74, 0x1998
	.global pcm_0836D3F8
pcm_0836D3F8:				@ 0836D3F8, 8084 bytes
	.incbin "snood_pcm.bin", 0x1D50C, 0x1F94
	.global pcm_0836F38C
pcm_0836F38C:				@ 0836F38C, 2820 bytes
	.incbin "snood_pcm.bin", 0x1F4A0, 0xB04
	.global pcm_0836FE90
pcm_0836FE90:				@ 0836FE90, 12480 bytes
	.incbin "snood_pcm.bin", 0x1FFA4, 0x30C0
	.global pcm_08372F50
pcm_08372F50:				@ 08372F50, 7712 bytes
	.incbin "snood_pcm.bin", 0x23064, 0x1E20
	.global pcm_08374D70
pcm_08374D70:				@ 08374D70, 3604 bytes
	.incbin "snood_pcm.bin", 0x24E84, 0xE14
	.global pcm_08375B84
pcm_08375B84:				@ 08375B84, 44096 bytes
	.incbin "snood_pcm.bin", 0x25C98, 0xAC40
	.global pcm_083807C4
pcm_083807C4:				@ 083807C4, 22044 bytes
	.incbin "snood_pcm.bin", 0x308D8, 0x561C
	.global pcm_08385DE0
pcm_08385DE0:				@ 08385DE0, 11164 bytes
	.incbin "snood_pcm.bin", 0x35EF4, 0x2B9C
	.global pcm_0838897C
pcm_0838897C:				@ 0838897C, 4312 bytes
	.incbin "snood_pcm.bin", 0x38A90, 0x10D8
	.global pcm_08389A54
pcm_08389A54:				@ 08389A54, 3900 bytes
	.incbin "snood_pcm.bin", 0x39B68, 0xF3C
	.global pcm_0838A990
pcm_0838A990:				@ 0838A990, 11264 bytes
	.incbin "snood_pcm.bin", 0x3AAA4, 0x2C00
	.global pcm_0838D590
pcm_0838D590:				@ 0838D590, 9152 bytes
	.incbin "snood_pcm.bin", 0x3D6A4, 0x23C0
	.global pcm_0838F950
pcm_0838F950:				@ 0838F950, 12624 bytes
	.incbin "snood_pcm.bin", 0x3FA64, 0x3150
	.global pcm_08392AA0
pcm_08392AA0:				@ 08392AA0, 4392 bytes
	.incbin "snood_pcm.bin", 0x42BB4, 0x1128
	.global pcm_08393BC8
pcm_08393BC8:				@ 08393BC8, 9396 bytes
	.incbin "snood_pcm.bin", 0x43CDC, 0x24B4
	.global pcm_0839607C
pcm_0839607C:				@ 0839607C, 14208 bytes
	.incbin "snood_pcm.bin", 0x46190, 0x3780
	.global pcm_083997FC
pcm_083997FC:				@ 083997FC, 10020 bytes
	.incbin "snood_pcm.bin", 0x49910, 0x2724
	.global pcm_0839BF20
pcm_0839BF20:				@ 0839BF20, 11744 bytes
	.incbin "snood_pcm.bin", 0x4C034, 0x2DE0
	.global pcm_0839ED00
pcm_0839ED00:				@ 0839ED00, 9240 bytes
	.incbin "snood_pcm.bin", 0x4EE14, 0x2418
	.global pcm_083A1118
pcm_083A1118:				@ 083A1118, 9664 bytes
	.incbin "snood_pcm.bin", 0x5122C, 0x25C0
	.global pcm_083A36D8
pcm_083A36D8:				@ 083A36D8, 11176 bytes
	.incbin "snood_pcm.bin", 0x537EC, 0x2BA8
	.global pcm_083A6280
pcm_083A6280:				@ 083A6280, 11904 bytes
	.incbin "snood_pcm.bin", 0x56394, 0x2E80
	.global pcm_083A9100
pcm_083A9100:				@ 083A9100, 14336 bytes
	.incbin "snood_pcm.bin", 0x59214, 0x3800
	.global pcm_083AC900
pcm_083AC900:				@ 083AC900, 12448 bytes
	.incbin "snood_pcm.bin", 0x5CA14, 0x30A0
	.global pcm_083AF9A0
pcm_083AF9A0:				@ 083AF9A0, 11680 bytes
	.incbin "snood_pcm.bin", 0x5FAB4, 0x2DA0
	.global pcm_083B2740
pcm_083B2740:				@ 083B2740, 16568 bytes
	.incbin "snood_pcm.bin", 0x62854, 0x40B8
	.global pcm_083B67F8
pcm_083B67F8:				@ 083B67F8, 19252 bytes
	.incbin "snood_pcm.bin", 0x6690C, 0x4B34
	.global pcm_083BB32C
pcm_083BB32C:				@ 083BB32C, 8816 bytes
	.incbin "snood_pcm.bin", 0x6B440, 0x2270
	.global pcm_083BD59C
pcm_083BD59C:				@ 083BD59C, 12384 bytes
	.incbin "snood_pcm.bin", 0x6D6B0, 0x3060
	.global pcm_083C05FC
pcm_083C05FC:				@ 083C05FC, 11216 bytes
	.incbin "snood_pcm.bin", 0x70710, 0x2BD0
	.global pcm_083C31CC
pcm_083C31CC:				@ 083C31CC, 4244 bytes
	.incbin "snood_pcm.bin", 0x732E0, 0x1094
	.global pcm_083C4260
pcm_083C4260:				@ 083C4260, 5128 bytes
	.incbin "snood_pcm.bin", 0x74374, 0x1408
	.global pcm_083C5668
pcm_083C5668:				@ 083C5668, 5212 bytes
	.incbin "snood_pcm.bin", 0x7577C, 0x145C
	.global pcm_083C6AC4
pcm_083C6AC4:				@ 083C6AC4, 1396 bytes
	.incbin "snood_pcm.bin", 0x76BD8, 0x574
	.global pcm_083C7038
pcm_083C7038:				@ 083C7038, 11780 bytes
	.incbin "snood_pcm.bin", 0x7714C, 0x2E04
	.global pcm_083C9E3C
pcm_083C9E3C:				@ 083C9E3C, 13040 bytes
	.incbin "snood_pcm.bin", 0x79F50, 0x32F0
	.global pcm_083CD12C
pcm_083CD12C:				@ 083CD12C, 21964 bytes
	.incbin "snood_pcm.bin", 0x7D240, 0x55CC
	.global pcm_083D26F8
pcm_083D26F8:				@ 083D26F8, 1512 bytes
	.incbin "snood_pcm.bin", 0x8280C, 0x5E8
	.global pcm_083D2CE0
pcm_083D2CE0:				@ 083D2CE0, 1324 bytes
	.incbin "snood_pcm.bin", 0x82DF4, 0x52C
	.global pcm_083D320C
pcm_083D320C:				@ 083D320C, 12688 bytes
	.incbin "snood_pcm.bin", 0x83320, 0x3190
	.global pcm_083D639C
pcm_083D639C:				@ 083D639C, 10744 bytes
	.incbin "snood_pcm.bin", 0x864B0, 0x29F8
	.global pcm_083D8D94
pcm_083D8D94:				@ 083D8D94, 9152 bytes
	.incbin "snood_pcm.bin", 0x88EA8, 0x23C0
	.global pcm_083DB154
pcm_083DB154:				@ 083DB154, 4588 bytes
	.incbin "snood_pcm.bin", 0x8B268, 0x11EC
	.global pcm_083DC340
pcm_083DC340:				@ 083DC340, 15524 bytes
	.incbin "snood_pcm.bin", 0x8C454, 0x3CA4
	.global pcm_083DFFE4
pcm_083DFFE4:				@ 083DFFE4, 20768 bytes
	.incbin "snood_pcm.bin", 0x900F8, 0x5120
	.global pcm_083E5104
pcm_083E5104:				@ 083E5104, 11840 bytes
	.incbin "snood_pcm.bin", 0x95218, 0x2E40
	.global pcm_083E7F44
pcm_083E7F44:				@ 083E7F44, 12544 bytes
	.incbin "snood_pcm.bin", 0x98058, 0x3100
	.global pcm_083EB044
pcm_083EB044:				@ 083EB044, 15804 bytes
	.incbin "snood_pcm.bin", 0x9B158, 0x3DBC
	.global pcm_083EEE00
pcm_083EEE00:				@ 083EEE00, 19872 bytes
	.incbin "snood_pcm.bin", 0x9EF14, 0x4DA0
	.global pcm_083F3BA0
pcm_083F3BA0:				@ 083F3BA0, 2816 bytes
	.incbin "snood_pcm.bin", 0xA3CB4, 0xB00
	.global pcm_083F46A0
pcm_083F46A0:				@ 083F46A0, 11708 bytes
	.incbin "snood_pcm.bin", 0xA47B4, 0x2DBC
	.global pcm_083F745C
pcm_083F745C:				@ 083F745C, 8140 bytes
	.incbin "snood_pcm.bin", 0xA7570, 0x1FCC
	.global pcm_083F9428
pcm_083F9428:				@ 083F9428, 10912 bytes
	.incbin "snood_pcm.bin", 0xA953C, 0x2AA0

@ mcDsSfxTable: {pcm, frames, loopFrames (0 = one-shot)}; 74 of 100 entries used
	.global mcDsSfxTable
mcDsSfxTable:				@ 083FBEC8
	.word	pcm_0836D3F8, 43, 0	@ sfx 0
	.word	pcm_08351218, 10, 0	@ sfx 1
	.word	pcm_083519D8, 13, 0	@ sfx 2
	.word	pcm_083523FC, 24, 0	@ sfx 3
	.word	pcm_083535C4, 35, 0	@ sfx 4
	.word	pcm_08354F9C, 17, 0	@ sfx 5
	.word	pcm_08355C88, 29, 0	@ sfx 6
	.word	pcm_083571E0, 68, 0	@ sfx 7
	.word	pcm_0835A3E0, 57, 57	@ sfx 8
	.word	pcm_0835CDA0, 26, 0	@ sfx 9
	.word	pcm_0835E148, 6, 0	@ sfx 10
	.word	pcm_0835E638, 78, 0	@ sfx 11
	.word	pcm_08361F38, 44, 0	@ sfx 12
	.word	pcm_08363FB8, 26, 0	@ sfx 13
	.word	pcm_083652E8, 19, 0	@ sfx 14
	.word	pcm_08366148, 26, 0	@ sfx 15
	.word	pcm_083674B0, 26, 0	@ sfx 16
	.word	pcm_083687E0, 69, 0	@ sfx 17
	.word	pcm_0836BA60, 35, 0	@ sfx 18
	.word	pcm_0834FEEC, 26, 26	@ sfx 19
	.word	pcm_0836F38C, 15, 0	@ sfx 20
	.word	pcm_0836FE90, 66, 0	@ sfx 21
	.word	pcm_08372F50, 41, 0	@ sfx 22
	.word	pcm_08375B84, 235, 0	@ sfx 23
	.word	pcm_083807C4, 117, 0	@ sfx 24
	.word	pcm_08385DE0, 59, 0	@ sfx 25
	.word	pcm_0838897C, 23, 0	@ sfx 26
	.word	pcm_08389A54, 20, 20	@ sfx 27
	.word	pcm_083571E0, 68, 0	@ sfx 28
	.word	pcm_0838A990, 60, 0	@ sfx 29
	.word	pcm_0838D590, 48, 0	@ sfx 30
	.word	pcm_0838F950, 67, 0	@ sfx 31
	.word	pcm_08392AA0, 23, 0	@ sfx 32
	.word	pcm_08393BC8, 50, 0	@ sfx 33
	.word	pcm_0839607C, 75, 0	@ sfx 34
	.word	pcm_083997FC, 53, 0	@ sfx 35
	.word	pcm_0839BF20, 62, 0	@ sfx 36
	.word	pcm_0839ED00, 49, 0	@ sfx 37
	.word	pcm_083A1118, 51, 0	@ sfx 38
	.word	pcm_083A36D8, 59, 59	@ sfx 39
	.word	pcm_083A6280, 63, 0	@ sfx 40
	.word	pcm_083A9100, 76, 0	@ sfx 41
	.word	pcm_083AC900, 66, 0	@ sfx 42
	.word	pcm_083AF9A0, 62, 0	@ sfx 43
	.word	pcm_083B2740, 88, 0	@ sfx 44
	.word	pcm_083B67F8, 102, 0	@ sfx 45
	.word	pcm_083BB32C, 47, 0	@ sfx 46
	.word	pcm_083BD59C, 66, 0	@ sfx 47
	.word	pcm_083C05FC, 59, 0	@ sfx 48
	.word	pcm_083C31CC, 22, 0	@ sfx 49
	.word	pcm_083C4260, 27, 0	@ sfx 50
	.word	pcm_083C5668, 27, 0	@ sfx 51
	.word	pcm_083C6AC4, 7, 0	@ sfx 52
	.word	pcm_083C7038, 62, 0	@ sfx 53
	.word	pcm_083C9E3C, 69, 0	@ sfx 54
	.word	pcm_083CD12C, 117, 0	@ sfx 55
	.word	pcm_08374D70, 19, 0	@ sfx 56
	.word	pcm_0836F38C, 15, 0	@ sfx 57
	.word	pcm_083D26F8, 8, 0	@ sfx 58
	.word	pcm_083D2CE0, 7, 0	@ sfx 59
	.word	pcm_083D320C, 67, 0	@ sfx 60
	.word	pcm_083D639C, 57, 0	@ sfx 61
	.word	pcm_083D8D94, 48, 0	@ sfx 62
	.word	pcm_083DB154, 24, 0	@ sfx 63
	.word	pcm_083DC340, 83, 0	@ sfx 64
	.word	pcm_083DFFE4, 111, 0	@ sfx 65
	.word	pcm_083E5104, 63, 0	@ sfx 66
	.word	pcm_083E7F44, 67, 0	@ sfx 67
	.word	pcm_083EB044, 84, 0	@ sfx 68
	.word	pcm_083EEE00, 106, 0	@ sfx 69
	.word	pcm_083F3BA0, 15, 0	@ sfx 70
	.word	pcm_083F46A0, 62, 0	@ sfx 71
	.word	pcm_083F745C, 43, 0	@ sfx 72
	.word	pcm_083F9428, 58, 0	@ sfx 73
	.word	0, 0, 0	@ sfx 74
	.word	0, 0, 0	@ sfx 75
	.word	0, 0, 0	@ sfx 76
	.word	0, 0, 0	@ sfx 77
	.word	0, 0, 0	@ sfx 78
	.word	0, 0, 0	@ sfx 79
	.word	0, 0, 0	@ sfx 80
	.word	0, 0, 0	@ sfx 81
	.word	0, 0, 0	@ sfx 82
	.word	0, 0, 0	@ sfx 83
	.word	0, 0, 0	@ sfx 84
	.word	0, 0, 0	@ sfx 85
	.word	0, 0, 0	@ sfx 86
	.word	0, 0, 0	@ sfx 87
	.word	0, 0, 0	@ sfx 88
	.word	0, 0, 0	@ sfx 89
	.word	0, 0, 0	@ sfx 90
	.word	0, 0, 0	@ sfx 91
	.word	0, 0, 0	@ sfx 92
	.word	0, 0, 0	@ sfx 93
	.word	0, 0, 0	@ sfx 94
	.word	0, 0, 0	@ sfx 95
	.word	0, 0, 0	@ sfx 96
	.word	0, 0, 0	@ sfx 97
	.word	0, 0, 0	@ sfx 98
	.word	0, 0, 0	@ sfx 99

@ mcPsgSfxMap: PSG effect n -> 4 script numbers (0xFF = none).  mcPlayPsgSfx has no callers.
	.global mcPsgSfxMap
mcPsgSfxMap:				@ 083FC378
	.byte	0x00, 0x01, 0x02, 0x03	@ psg sfx 0
	.byte	0x04, 0xFF, 0xFF, 0xFF	@ psg sfx 1
	.byte	0x05, 0xFF, 0xFF, 0xFF	@ psg sfx 2
	.byte	0x06, 0x07, 0xFF, 0xFF	@ psg sfx 3
	.byte	0x08, 0x09, 0xFF, 0xFF	@ psg sfx 4
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

psgScript_08:				@ 083FC3B8  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0091
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0091
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0091
	.hword	0x000C, 0x0080, 0x00C1, 0x0087, 0x0091
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0091
	.hword	0x0028, 0x0080, 0x00C3, 0x0087, 0x0083
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000

psgScript_09:				@ 083FC438  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0074
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0045
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0074
	.hword	0x000C, 0x0080, 0x00C1, 0x0087, 0x0045
	.hword	0x0006, 0x0080, 0x00C1, 0x0087, 0x0074
	.hword	0x0028, 0x0080, 0x00C3, 0x0087, 0x006C
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000

psgScript_06:				@ 083FC4B8  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0004, 0x0080, 0x00C1, 0x0087, 0x0014
	.hword	0x0028, 0x0080, 0x00F5, 0x0086, 0x0028
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_07:				@ 083FC4F8  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0004, 0x0080, 0x00C1, 0x0087, 0x0021
	.hword	0x0028, 0x0080, 0x00F5, 0x0086, 0x0042
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000

psgScript_04:				@ 083FC538  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0003, 0x0080, 0x00F0, 0x0087, 0x00B1
	.hword	0x0003, 0x0080, 0x00F0, 0x0087, 0x00D9
	.hword	0x0003, 0x0080, 0x00F0, 0x0087, 0x00CC
	.hword	0x0003, 0x0080, 0x00F0, 0x0087, 0x00C5
	.hword	0x0003, 0x0080, 0x00F0, 0x0087, 0x00B1
	.hword	0x000A, 0x0080, 0x00F2, 0x0087, 0x008A
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000

psgScript_05:				@ 083FC5B8  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0002, 0x0080, 0x0040, 0x0087, 0x0014
	.hword	0x0002, 0x0080, 0x0080, 0x0087, 0x0063
	.hword	0x0002, 0x0080, 0x00C0, 0x0087, 0x002E
	.hword	0x0002, 0x0080, 0x00F0, 0x0087, 0x0074
	.hword	0x0002, 0x0080, 0x00F0, 0x0087, 0x0045
	.hword	0x0002, 0x0080, 0x00F0, 0x0087, 0x0083
	.hword	0x0002, 0x0080, 0x00C0, 0x0087, 0x002E
	.hword	0x0002, 0x0080, 0x00C0, 0x0087, 0x0074
	.hword	0x0002, 0x0080, 0x0080, 0x0087, 0x0014
	.hword	0x0002, 0x0080, 0x0040, 0x0087, 0x0063
	.hword	0x00FE, 0x00FD, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_00:				@ 083FC678  channel 0   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	0
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_01:				@ 083FC698  channel 1   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	1
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_02:				@ 083FC6B8  channel 2   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	2
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

psgScript_03:				@ 083FC6D8  channel 3   {frames, v1lo, v1hi, v2hi, v2lo}
	.hword	3
	.hword	0x0001, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x00FF, 0x0000, 0x0000, 0x0000, 0x0000
	.hword	0x0000, 0x0000, 0x0000, 0x0000, 0x0000

	.global mcPsgSfxScripts
mcPsgSfxScripts:				@ 083FC6F8
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
	.word	0
	.word	0
	.word	0
	.word	0
	.word	0
	.word	0

@ note-length table (length index -> ticks); fixed: the driver indexes it directly for every song
	.global mcDurTable
mcDurTable:				@ 083FC738
	.word	  3,   4,   6,   9,  12,  18,  24,  36	@ [0..7]
	.word	 48,  72,  96, 144, 192,   8,  16,  32	@ [8..15]

@ ----------------------------------------------------------------------------
@ patterns: {note, instrument, length-index} events, 0x65 = end.  Note names assume
@ index 0 = C#2 on the PSG channels; on channels 5-8 the note selects a resampling step.
@ ----------------------------------------------------------------------------
pat_083FC778:				@ used by s1c1, s1c2, s1c4, s2c1, s2c2, s2c4, s3c1, s3c2, s4c2, s4c4, s5c1, s5c2
	N	60, 0, 10		@ C#7
	PAT_END

pat_083FC77C:				@ used by s0c1, s0c2, s0c3, s0c4
	N	60, 0, 0		@ C#7
	PAT_END

pat_083FC780:				@ used by s1c1
	N	60, 13, 6		@ C#7
	N	62, 13, 5		@ D#7
	N	64, 13, 8		@ F7
	REST	0, 2
	N	65, 13, 4		@ F#7
	N	67, 13, 4		@ G#7
	N	64, 13, 4		@ F7
	N	65, 13, 2		@ F#7
	N	62, 13, 8		@ D#7
	REST	0, 2
	N	60, 13, 6		@ C#7
	N	62, 13, 5		@ D#7
	N	64, 13, 8		@ F7
	REST	0, 2
	N	65, 13, 6		@ F#7
	N	62, 13, 5		@ D#7
	N	64, 13, 8		@ F7
	REST	0, 2
	PAT_END

pat_083FC7B7:				@ used by s1c1
	REST	0, 4
	N	67, 13, 4		@ G#7
	N	67, 13, 2		@ G#7
	N	55, 13, 6		@ G#6
	REST	0, 2
	N	67, 13, 4		@ G#7
	N	67, 13, 2		@ G#7
	N	55, 13, 6		@ G#6
	REST	0, 2
	N	67, 13, 4		@ G#7
	N	67, 13, 4		@ G#7
	N	67, 13, 4		@ G#7
	N	67, 13, 4		@ G#7
	N	67, 13, 4		@ G#7
	N	67, 13, 2		@ G#7
	N	55, 13, 5		@ G#6
	PAT_END

pat_083FC7E8:				@ used by s1c1
	N	60, 13, 4		@ C#7
	N	60, 13, 4		@ C#7
	N	58, 13, 2		@ B6
	N	62, 13, 4		@ D#7
	N	60, 13, 8		@ C#7
	REST	0, 2
	N	64, 13, 4		@ F7
	N	65, 13, 4		@ F#7
	N	67, 13, 4		@ G#7
	N	62, 13, 2		@ D#7
	N	64, 13, 8		@ F7
	REST	0, 2
	N	60, 13, 4		@ C#7
	N	60, 13, 4		@ C#7
	N	58, 13, 2		@ B6
	N	62, 13, 4		@ D#7
	N	60, 13, 8		@ C#7
	REST	0, 2
	N	64, 13, 2		@ F7
	N	60, 13, 5		@ C#7
	N	62, 13, 2		@ D#7
	N	58, 13, 5		@ B6
	N	60, 13, 8		@ C#7
	PAT_END

pat_083FC82E:				@ used by s1c1
	N	71, 13, 4		@ C8
	N	62, 13, 4		@ D#7
	N	71, 13, 4		@ C8
	N	71, 13, 2		@ C8
	N	62, 13, 4		@ D#7
	N	71, 13, 2		@ C8
	N	62, 13, 4		@ D#7
	N	71, 13, 4		@ C8
	N	62, 13, 4		@ D#7
	N	72, 13, 4		@ C#8
	N	62, 13, 4		@ D#7
	N	72, 13, 4		@ C#8
	N	72, 13, 2		@ C#8
	N	62, 13, 4		@ D#7
	N	72, 13, 2		@ C#8
	N	62, 13, 4		@ D#7
	N	72, 13, 4		@ C#8
	N	62, 13, 4		@ D#7
	N	74, 13, 4		@ D#8
	N	62, 13, 4		@ D#7
	N	74, 13, 2		@ D#8
	N	62, 13, 4		@ D#7
	N	74, 13, 4		@ D#8
	N	62, 13, 2		@ D#7
	N	74, 13, 4		@ D#8
	N	62, 13, 4		@ D#7
	N	74, 13, 4		@ D#8
	N	77, 13, 4		@ F#8
	N	62, 13, 4		@ D#7
	N	77, 13, 4		@ F#8
	N	62, 13, 2		@ D#7
	N	77, 13, 4		@ F#8
	N	77, 13, 2		@ F#8
	N	62, 13, 4		@ D#7
	N	77, 13, 6		@ F#8
	PAT_END

pat_083FC898:				@ used by s1c2
	N	76, 13, 4		@ F8
	N	72, 13, 4		@ C#8
	N	77, 13, 4		@ F#8
	N	72, 13, 2		@ C#8
	N	79, 13, 4		@ G#8
	N	79, 13, 2		@ G#8
	N	72, 13, 4		@ C#8
	N	81, 13, 4		@ A#8
	N	72, 13, 4		@ C#8
	N	82, 13, 4		@ B8
	N	72, 13, 4		@ C#8
	N	81, 13, 4		@ A#8
	N	72, 13, 2		@ C#8
	N	79, 13, 8		@ G#8
	REST	0, 2
	N	76, 13, 4		@ F8
	N	72, 13, 4		@ C#8
	N	77, 13, 4		@ F#8
	N	72, 13, 2		@ C#8
	N	79, 13, 4		@ G#8
	N	79, 13, 2		@ G#8
	N	72, 13, 4		@ C#8
	N	76, 13, 4		@ F8
	N	72, 13, 4		@ C#8
	N	74, 13, 4		@ D#8
	N	72, 13, 4		@ C#8
	N	70, 13, 4		@ B7
	N	74, 13, 2		@ D#8
	N	72, 13, 8		@ C#8
	REST	0, 2
	PAT_END

pat_083FC8F3:				@ used by s1c2
	REST	0, 4
	N	71, 13, 4		@ C8
	N	71, 13, 2		@ C8
	N	59, 13, 6		@ C7
	REST	0, 2
	N	71, 13, 4		@ C8
	N	71, 13, 2		@ C8
	N	59, 13, 6		@ C7
@ DATA BUG (083FC90B): this rest is missing its instrument byte.  It should read
@ "REST 0, 2" followed by N 71,13,4 / 72,13,4 / 72,13,4 / 73,13,4 / 73,13,4 / 74,13,2 / 59,13,5 and
@ PAT_END.  As stored, the grid is shifted by one byte from here on: the driver reads
@ {0x60, inst 2, len 71} -> 67 976 706 ticks, so channel 2 of song 1 goes silent for good, and the
@ intended PAT_END (0x65) is read as the last length byte below.  Kept as-is for a byte-exact build.
	REST	2, 71
	N	13, 4, 72		@ D3
	N	13, 4, 72		@ D3
	N	13, 4, 73		@ D3
	N	13, 4, 73		@ D3
	N	13, 4, 74		@ D3
	N	13, 2, 59		@ D3
	N	13, 5, 101		@ D3

pat_083FC923:				@ used by s1c2
	N	76, 13, 4		@ F8
	N	77, 13, 4		@ F#8
	N	74, 13, 4		@ D#8
	N	77, 13, 2		@ F#8
	N	76, 13, 4		@ F8
	N	76, 13, 2		@ F8
	N	77, 13, 4		@ F#8
	N	79, 13, 4		@ G#8
	N	81, 13, 4		@ A#8
	N	82, 13, 4		@ B8
	N	81, 13, 4		@ A#8
	N	79, 13, 4		@ G#8
	N	77, 13, 2		@ F#8
	N	79, 13, 8		@ G#8
	REST	0, 2
	N	76, 13, 4		@ F8
	N	79, 13, 4		@ G#8
	N	77, 13, 4		@ F#8
	N	79, 13, 2		@ G#8
	N	76, 13, 4		@ F8
	N	76, 13, 2		@ F8
	N	74, 13, 4		@ D#8
	N	76, 13, 4		@ F8
	N	77, 13, 4		@ F#8
	N	72, 13, 2		@ C#8
	N	67, 13, 5		@ G#7
	N	70, 13, 2		@ B7
	N	65, 13, 5		@ F#7
	N	67, 13, 8		@ G#7
	PAT_END

pat_083FC97B:				@ used by s1c2
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	59, 13, 2		@ C7
	N	55, 13, 2		@ G#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	60, 13, 2		@ C#7
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	62, 13, 2		@ D#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	N	59, 13, 2		@ C7
	N	65, 13, 2		@ F#7
	PAT_END

pat_083FCA3C:				@ used by s1c3
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	67, 18, 2		@ G#7
	N	70, 18, 2		@ B7
	N	60, 18, 4		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	65, 18, 2		@ F#7
	N	72, 18, 2		@ C#8
	N	60, 18, 2		@ C#7
	N	60, 18, 4		@ C#7
	N	60, 18, 4		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	67, 18, 2		@ G#7
	N	70, 18, 2		@ B7
	N	60, 18, 4		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	65, 18, 2		@ F#7
	N	74, 18, 4		@ D#8
	N	77, 18, 4		@ F#8
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	67, 18, 2		@ G#7
	N	70, 18, 2		@ B7
	N	60, 18, 4		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	65, 18, 2		@ F#7
	N	72, 18, 2		@ C#8
	N	60, 18, 2		@ C#7
	N	60, 18, 4		@ C#7
	N	60, 18, 4		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	67, 18, 2		@ G#7
	N	70, 18, 2		@ B7
	N	60, 18, 4		@ C#7
	N	60, 18, 2		@ C#7
	N	60, 18, 2		@ C#7
	N	65, 18, 2		@ F#7
	N	70, 18, 4		@ B7
	N	74, 18, 4		@ D#8
	PAT_END

pat_083FCAD9:				@ used by s1c3
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	55, 18, 2		@ G#6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	43, 18, 2		@ G#5
	N	47, 18, 2		@ C6
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	55, 18, 2		@ G#6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	43, 18, 2		@ G#5
	N	47, 18, 2		@ C6
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	55, 18, 2		@ G#6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	43, 18, 2		@ G#5
	N	47, 18, 2		@ C6
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	55, 18, 2		@ G#6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	43, 18, 2		@ G#5
	N	47, 18, 2		@ C6
	N	50, 18, 2		@ D#6
	PAT_END

pat_083FCB3A:				@ used by s1c3
	N	55, 18, 2		@ G#6
	N	43, 18, 2		@ G#5
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	47, 18, 2		@ C6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	43, 18, 2		@ G#5
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	47, 18, 2		@ C6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	43, 18, 2		@ G#5
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	47, 18, 2		@ C6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	43, 18, 2		@ G#5
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	47, 18, 2		@ C6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	50, 18, 2		@ D#6
	PAT_END

pat_083FCB9B:				@ used by s1c3
	N	55, 18, 2		@ G#6
	N	43, 18, 2		@ G#5
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	47, 18, 2		@ C6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	50, 18, 2		@ D#6
	N	55, 18, 2		@ G#6
	N	43, 18, 2		@ G#5
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	47, 18, 2		@ C6
	N	46, 18, 2		@ B5
	N	65, 18, 2		@ F#7
	N	50, 18, 2		@ D#6
	N	60, 18, 2		@ C#7
	N	48, 18, 2		@ C#6
	N	60, 18, 2		@ C#7
	N	67, 18, 2		@ G#7
	N	52, 18, 2		@ F6
	N	51, 18, 2		@ E6
	N	70, 18, 2		@ B7
	N	55, 18, 2		@ G#6
	N	62, 18, 2		@ D#7
	N	50, 18, 2		@ D#6
	N	62, 18, 2		@ D#7
	N	69, 18, 2		@ A#7
	N	54, 18, 2		@ G6
	N	53, 18, 2		@ F#6
	N	72, 18, 2		@ C#8
	N	57, 18, 2		@ A#6
	PAT_END

pat_083FCBFC:				@ used by s1c4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	34, 5, 2		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	34, 5, 2		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	34, 5, 2		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	34, 5, 2		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	PAT_END

pat_083FCC8D:				@ used by s2c1
	N	55, 13, 2		@ G#6
	N	56, 13, 4		@ A6
	N	58, 13, 9		@ B6
	REST	0, 2
	N	53, 13, 2		@ F#6
	N	55, 13, 4		@ G#6
	N	56, 13, 9		@ A6
	REST	0, 2
	N	55, 13, 2		@ G#6
	N	56, 13, 4		@ A6
	N	58, 13, 6		@ B6
	N	0, 13, 2		@ C#2
	N	53, 13, 2		@ F#6
	N	55, 13, 4		@ G#6
	N	56, 13, 6		@ A6
	REST	0, 2
	N	56, 13, 2		@ A6
	N	55, 13, 5		@ G#6
	N	55, 13, 2		@ G#6
	REST	0, 5
	REST	0, 8
	PAT_END

pat_083FCCCD:				@ used by s2c1
	N	61, 13, 2		@ D7
	N	60, 13, 4		@ C#7
	N	58, 13, 5		@ B6
	N	60, 13, 8		@ C#7
	REST	0, 4
	N	55, 13, 2		@ G#6
	N	56, 13, 4		@ A6
	N	58, 13, 5		@ B6
	N	56, 13, 8		@ A6
	REST	0, 4
	N	63, 13, 2		@ E7
	N	61, 13, 5		@ D7
	N	61, 13, 2		@ D7
	N	60, 13, 5		@ C#7
	N	60, 13, 2		@ C#7
	N	58, 13, 5		@ B6
	N	58, 13, 2		@ B6
	N	56, 13, 5		@ A6
	N	56, 13, 2		@ A6
	N	55, 13, 5		@ G#6
	N	55, 13, 9		@ G#6
	PAT_END

pat_083FCD0D:				@ used by s2c1
	N	58, 14, 5		@ B6
	N	56, 13, 5		@ A6
	N	56, 13, 6		@ A6
	N	56, 13, 5		@ A6
	N	56, 13, 5		@ A6
	N	56, 14, 5		@ A6
	N	55, 13, 5		@ G#6
	N	55, 13, 6		@ G#6
	N	55, 13, 5		@ G#6
	N	55, 13, 5		@ G#6
	N	55, 14, 5		@ G#6
	N	54, 13, 6		@ G6
	REST	0, 2
	N	54, 14, 5		@ G6
	N	56, 13, 6		@ A6
	REST	0, 2
	N	56, 14, 5		@ A6
	N	58, 13, 5		@ B6
	N	58, 13, 8		@ B6
	REST	0, 4
	PAT_END

pat_083FCD4A:				@ used by s2c1
	N	58, 14, 5		@ B6
	N	61, 13, 5		@ D7
	N	63, 13, 6		@ E7
	N	58, 14, 4		@ B6
	N	61, 13, 4		@ D7
	N	63, 13, 4		@ E7
	N	58, 14, 5		@ B6
	N	61, 13, 5		@ D7
	N	63, 13, 6		@ E7
	N	58, 14, 4		@ B6
	N	61, 13, 4		@ D7
	N	63, 13, 4		@ E7
	N	58, 14, 6		@ B6
	N	65, 14, 6		@ F#7
	N	64, 14, 6		@ F7
	N	58, 14, 6		@ B6
	N	63, 14, 6		@ E7
	N	61, 14, 6		@ D7
	N	58, 14, 6		@ B6
	N	61, 14, 6		@ D7
	PAT_END

pat_083FCD87:				@ used by s2c1
	N	58, 13, 4		@ B6
	N	58, 13, 2		@ B6
	N	56, 13, 4		@ A6
	N	56, 13, 2		@ A6
	N	58, 13, 4		@ B6
	N	61, 13, 4		@ D7
	N	58, 13, 4		@ B6
	N	56, 14, 4		@ A6
	N	58, 13, 4		@ B6
	N	58, 14, 5		@ B6
	N	56, 13, 5		@ A6
	N	56, 13, 4		@ A6
	N	56, 14, 5		@ A6
	N	55, 13, 5		@ G#6
	N	55, 13, 4		@ G#6
	N	58, 13, 4		@ B6
	N	58, 13, 2		@ B6
	N	56, 13, 4		@ A6
	N	56, 13, 2		@ A6
	N	58, 13, 4		@ B6
	N	61, 13, 4		@ D7
	N	58, 13, 4		@ B6
	N	56, 13, 4		@ A6
	N	58, 13, 4		@ B6
	N	61, 13, 4		@ D7
	N	63, 14, 5		@ E7
	N	64, 13, 5		@ F7
	N	65, 13, 4		@ F#7
	N	68, 14, 5		@ A7
	N	70, 13, 5		@ B7
	PAT_END

pat_083FCDE2:				@ used by s2c1
	N	58, 14, 5		@ B6
	N	61, 14, 5		@ D7
	N	63, 14, 6		@ E7
	N	58, 14, 4		@ B6
	N	61, 14, 4		@ D7
	N	63, 14, 4		@ E7
	N	58, 14, 5		@ B6
	N	61, 14, 5		@ D7
	N	63, 14, 6		@ E7
	N	58, 14, 4		@ B6
	N	61, 14, 4		@ D7
	N	63, 14, 4		@ E7
	N	58, 14, 6		@ B6
	N	65, 14, 6		@ F#7
	N	64, 14, 6		@ F7
	N	58, 14, 6		@ B6
	N	63, 14, 6		@ E7
	N	61, 14, 6		@ D7
	N	58, 14, 6		@ B6
	N	61, 14, 6		@ D7
	PAT_END

pat_083FCE1F:				@ used by s2c2
	REST	0, 7
	N	70, 15, 6		@ B7
	N	67, 13, 4		@ G#7
	N	65, 13, 8		@ F#7
	REST	0, 4
	N	65, 15, 6		@ F#7
	N	67, 13, 4		@ G#7
	N	68, 13, 8		@ A7
	REST	0, 4
	N	75, 13, 8		@ E8
	N	73, 13, 4		@ D8
	N	73, 13, 2		@ D8
	N	72, 13, 5		@ C#8
	N	72, 13, 9		@ C#8
	PAT_END

pat_083FCE4A:				@ used by s2c2
	N	60, 15, 10		@ C#7
	N	61, 15, 10		@ D7
	N	63, 15, 8		@ E7
	N	61, 15, 8		@ D7
	N	60, 15, 10		@ C#7
	PAT_END

pat_083FCE5A:				@ used by s2c2
	N	60, 15, 10		@ C#7
	N	61, 15, 10		@ D7
	REST	0, 2
	N	65, 13, 5		@ F#7
	N	65, 13, 2		@ F#7
	N	63, 13, 5		@ E7
	N	63, 13, 2		@ E7
	N	61, 13, 5		@ D7
	N	61, 13, 2		@ D7
	N	63, 13, 5		@ E7
	N	61, 13, 2		@ D7
	N	60, 13, 5		@ C#7
	N	60, 13, 9		@ C#7
	PAT_END

pat_083FCE82:				@ used by s2c2
	N	58, 15, 10		@ B6
	N	61, 15, 10		@ D7
	N	65, 15, 6		@ F#7
	N	68, 15, 6		@ A7
	N	67, 15, 6		@ G#7
	N	61, 15, 6		@ D7
	N	66, 15, 6		@ G7
	N	65, 15, 6		@ F#7
	N	61, 15, 6		@ D7
	N	65, 15, 6		@ F#7
	PAT_END

pat_083FCEA1:				@ used by s2c2
	N	60, 13, 4		@ C#7
	N	60, 13, 2		@ C#7
	N	58, 13, 5		@ B6
	N	60, 13, 6		@ C#7
	N	60, 13, 5		@ C#7
	N	60, 13, 5		@ C#7
	N	61, 13, 4		@ D7
	N	61, 13, 2		@ D7
	N	60, 13, 5		@ C#7
	N	61, 13, 6		@ D7
	N	61, 13, 5		@ D7
	N	61, 13, 5		@ D7
	N	63, 13, 4		@ E7
	N	63, 13, 2		@ E7
	N	61, 13, 5		@ D7
	N	63, 13, 4		@ E7
	N	61, 13, 4		@ D7
	N	61, 13, 2		@ D7
	N	60, 13, 5		@ C#7
	N	61, 13, 4		@ D7
	N	61, 13, 4		@ D7
	N	60, 13, 2		@ C#7
	N	58, 13, 5		@ B6
	N	60, 13, 6		@ C#7
	N	60, 13, 5		@ C#7
	N	60, 13, 5		@ C#7
	PAT_END

pat_083FCEF0:				@ used by s2c2
	N	60, 15, 10		@ C#7
	N	61, 15, 10		@ D7
	N	63, 15, 8		@ E7
	N	61, 15, 8		@ D7
	N	60, 15, 10		@ C#7
	PAT_END

pat_083FCF00:				@ used by s2c3
	N	48, 16, 4		@ C#6
	N	63, 17, 2		@ E7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	61, 17, 2		@ D7
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	67, 17, 2		@ G#7
	N	60, 17, 2		@ C#7
	N	58, 17, 2		@ B6
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	61, 17, 2		@ D7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	61, 17, 2		@ D7
	N	48, 17, 2		@ C#6
	N	58, 17, 2		@ B6
	N	48, 17, 2		@ C#6
	N	65, 17, 2		@ F#7
	N	60, 17, 2		@ C#7
	N	61, 17, 2		@ D7
	N	67, 17, 2		@ G#7
	N	48, 16, 4		@ C#6
	N	63, 17, 2		@ E7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	61, 17, 2		@ D7
	N	48, 17, 2		@ C#6
	N	61, 17, 2		@ D7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	67, 17, 2		@ G#7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	61, 17, 2		@ D7
	N	48, 17, 2		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	67, 17, 2		@ G#7
	N	60, 17, 2		@ C#7
	N	56, 17, 2		@ A6
	N	60, 17, 2		@ C#7
	PAT_END

pat_083FCFB8:				@ used by s2c3
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	46, 17, 2		@ B5
	N	46, 17, 2		@ B5
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	46, 17, 2		@ B5
	N	46, 17, 2		@ B5
	N	61, 17, 2		@ D7
	N	58, 17, 2		@ B6
	N	46, 17, 2		@ B5
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	61, 17, 2		@ D7
	N	58, 17, 2		@ B6
	N	46, 17, 2		@ B5
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	46, 17, 2		@ B5
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	61, 17, 2		@ D7
	N	46, 17, 2		@ B5
	N	58, 17, 2		@ B6
	N	63, 17, 2		@ E7
	N	46, 17, 2		@ B5
	PAT_END

pat_083FD079:				@ used by s2c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 4		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	34, 5, 2		@ B4
	PAT_END

pat_083FD098:				@ used by s2c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 2		@ D#4
	N	34, 5, 2		@ B4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FD0BD:				@ used by s3c1
	N	60, 14, 4		@ C#7
	N	63, 13, 4		@ E7
	N	65, 13, 6		@ F#7
	N	60, 14, 4		@ C#7
	N	63, 13, 2		@ E7
	N	62, 13, 4		@ D#7
	N	62, 13, 2		@ D#7
	N	58, 13, 4		@ B6
	N	60, 14, 4		@ C#7
	N	63, 14, 4		@ E7
	N	65, 13, 4		@ F#7
	N	70, 14, 4		@ B7
	N	67, 13, 4		@ G#7
	N	63, 13, 2		@ E7
	N	65, 13, 6		@ F#7
	REST	0, 2
	N	60, 14, 4		@ C#7
	N	63, 13, 4		@ E7
	N	65, 13, 6		@ F#7
	N	63, 14, 4		@ E7
	N	65, 13, 2		@ F#7
	N	67, 13, 4		@ G#7
	N	67, 13, 2		@ G#7
	N	67, 13, 4		@ G#7
	N	70, 14, 4		@ B7
	N	69, 13, 4		@ A#7
	N	69, 14, 4		@ A#7
	N	67, 13, 4		@ G#7
	N	67, 14, 4		@ G#7
	N	65, 13, 4		@ F#7
	N	65, 14, 4		@ F#7
	N	63, 13, 4		@ E7
	PAT_END

pat_083FD11E:				@ used by s3c1
	N	62, 14, 4		@ D#7
	N	65, 13, 4		@ F#7
	N	67, 13, 6		@ G#7
	N	62, 14, 4		@ D#7
	N	65, 13, 2		@ F#7
	N	64, 13, 4		@ F7
	N	64, 13, 2		@ F7
	N	60, 13, 4		@ C#7
	N	62, 14, 4		@ D#7
	N	65, 14, 4		@ F#7
	N	67, 13, 4		@ G#7
	N	72, 14, 4		@ C#8
	N	69, 13, 4		@ A#7
	N	65, 13, 2		@ F#7
	N	67, 13, 6		@ G#7
	REST	0, 2
	N	62, 14, 4		@ D#7
	N	65, 13, 4		@ F#7
	N	67, 13, 6		@ G#7
	N	65, 14, 4		@ F#7
	N	67, 13, 2		@ G#7
	N	69, 13, 4		@ A#7
	N	69, 13, 2		@ A#7
	N	69, 13, 4		@ A#7
	N	72, 14, 4		@ C#8
	N	71, 13, 4		@ C8
	N	71, 14, 4		@ C8
	N	69, 13, 4		@ A#7
	N	69, 14, 4		@ A#7
	N	67, 13, 4		@ G#7
	N	67, 14, 4		@ G#7
	N	65, 13, 4		@ F#7
	PAT_END

pat_083FD17F:				@ used by s3c1
	N	67, 13, 2		@ G#7
	N	67, 13, 2		@ G#7
	N	70, 13, 4		@ B7
	N	67, 13, 2		@ G#7
	N	67, 13, 2		@ G#7
	N	70, 13, 4		@ B7
	N	67, 13, 2		@ G#7
	N	67, 13, 2		@ G#7
	N	70, 13, 2		@ B7
	N	69, 13, 4		@ A#7
	N	69, 13, 4		@ A#7
	N	69, 13, 2		@ A#7
	N	67, 13, 2		@ G#7
	N	67, 13, 2		@ G#7
	N	70, 13, 4		@ B7
	N	67, 13, 2		@ G#7
	N	67, 13, 2		@ G#7
	N	70, 13, 4		@ B7
	N	67, 13, 2		@ G#7
	N	67, 13, 2		@ G#7
	N	70, 13, 2		@ B7
	N	69, 13, 6		@ A#7
	REST	0, 2
	N	70, 13, 2		@ B7
	N	70, 13, 2		@ B7
	N	67, 13, 4		@ G#7
	N	70, 13, 2		@ B7
	N	70, 13, 2		@ B7
	N	67, 13, 4		@ G#7
	N	70, 13, 2		@ B7
	N	70, 13, 2		@ B7
	N	67, 13, 2		@ G#7
	N	72, 13, 4		@ C#8
	N	72, 13, 5		@ C#8
	N	75, 13, 2		@ E8
	N	74, 13, 2		@ D#8
	N	70, 13, 2		@ B7
	N	72, 13, 4		@ C#8
	N	72, 13, 4		@ C#8
	N	72, 13, 2		@ C#8
	N	72, 13, 2		@ C#8
	N	70, 13, 2		@ B7
	N	67, 13, 2		@ G#7
	N	69, 13, 6		@ A#7
	REST	0, 2
	PAT_END

pat_083FD207:				@ used by s3c1
	N	69, 13, 2		@ A#7
	N	69, 13, 2		@ A#7
	N	72, 13, 4		@ C#8
	N	69, 13, 2		@ A#7
	N	69, 13, 2		@ A#7
	N	72, 13, 4		@ C#8
	N	69, 13, 2		@ A#7
	N	69, 13, 2		@ A#7
	N	72, 13, 2		@ C#8
	N	71, 13, 4		@ C8
	N	71, 13, 4		@ C8
	N	71, 13, 2		@ C8
	N	69, 13, 2		@ A#7
	N	69, 13, 2		@ A#7
	N	72, 13, 4		@ C#8
	N	69, 13, 2		@ A#7
	N	69, 13, 2		@ A#7
	N	72, 13, 4		@ C#8
	N	69, 13, 2		@ A#7
	N	69, 13, 2		@ A#7
	N	72, 13, 2		@ C#8
	N	71, 13, 6		@ C8
	REST	0, 2
	N	72, 13, 2		@ C#8
	N	72, 13, 2		@ C#8
	N	69, 13, 4		@ A#7
	N	72, 13, 2		@ C#8
	N	72, 13, 2		@ C#8
	N	69, 13, 4		@ A#7
	N	72, 13, 2		@ C#8
	N	72, 13, 2		@ C#8
	N	69, 13, 2		@ A#7
	N	74, 13, 4		@ D#8
	N	74, 13, 5		@ D#8
	N	77, 13, 2		@ F#8
	N	76, 13, 2		@ F8
	N	72, 13, 2		@ C#8
	N	74, 13, 4		@ D#8
	N	74, 13, 4		@ D#8
	N	74, 13, 2		@ D#8
	N	74, 13, 2		@ D#8
	N	72, 13, 2		@ C#8
	N	69, 13, 2		@ A#7
	N	71, 13, 6		@ C8
	REST	0, 2
	PAT_END

pat_083FD28F:				@ used by s3c2
	N	63, 15, 10		@ E7
	N	65, 15, 10		@ F#7
	N	67, 15, 10		@ G#7
	N	70, 15, 6		@ B7
	N	69, 15, 6		@ A#7
	N	69, 15, 6		@ A#7
	N	67, 15, 6		@ G#7
	PAT_END

pat_083FD2A5:				@ used by s3c2
	N	65, 15, 10		@ F#7
	N	67, 15, 10		@ G#7
	N	69, 15, 10		@ A#7
	N	72, 15, 6		@ C#8
	N	71, 15, 6		@ C8
	N	71, 15, 6		@ C8
	N	69, 15, 6		@ A#7
	PAT_END

pat_083FD2BB:				@ used by s3c2
	N	63, 15, 6		@ E7
	N	62, 15, 6		@ D#7
	N	63, 15, 4		@ E7
	N	67, 13, 2		@ G#7
	N	65, 13, 4		@ F#7
	N	65, 13, 5		@ F#7
	N	63, 15, 6		@ E7
	N	62, 15, 6		@ D#7
	N	63, 15, 4		@ E7
	N	67, 13, 2		@ G#7
	N	65, 13, 6		@ F#7
	REST	0, 2
	N	63, 15, 6		@ E7
	N	62, 15, 6		@ D#7
	N	63, 15, 4		@ E7
	N	67, 13, 2		@ G#7
	N	65, 13, 4		@ F#7
	N	65, 13, 5		@ F#7
	N	67, 13, 2		@ G#7
	N	65, 13, 2		@ F#7
	N	62, 13, 2		@ D#7
	N	63, 13, 4		@ E7
	N	63, 13, 5		@ E7
	N	63, 13, 2		@ E7
	N	62, 13, 2		@ D#7
	N	58, 13, 2		@ B6
	N	60, 13, 6		@ C#7
	REST	0, 2
	PAT_END

pat_083FD310:				@ used by s3c2
	N	65, 15, 6		@ F#7
	N	64, 15, 6		@ F7
	N	65, 15, 4		@ F#7
	N	69, 13, 2		@ A#7
	N	67, 13, 4		@ G#7
	N	67, 13, 5		@ G#7
	N	65, 15, 6		@ F#7
	N	64, 15, 6		@ F7
	N	65, 15, 4		@ F#7
	N	69, 13, 2		@ A#7
	N	67, 13, 6		@ G#7
	REST	0, 2
	N	65, 15, 6		@ F#7
	N	64, 15, 6		@ F7
	N	65, 15, 4		@ F#7
	N	69, 13, 2		@ A#7
	N	67, 13, 4		@ G#7
	N	67, 13, 5		@ G#7
	N	69, 13, 2		@ A#7
	N	67, 13, 2		@ G#7
	N	64, 13, 2		@ F7
	N	65, 13, 4		@ F#7
	N	65, 13, 5		@ F#7
	N	65, 13, 2		@ F#7
	N	64, 13, 2		@ F7
	N	60, 13, 2		@ C#7
	N	62, 13, 6		@ D#7
	REST	0, 2
	PAT_END

pat_083FD365:				@ used by s3c3
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 7		@ E5
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 16, 6		@ F#5
	REST	0, 2
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 7		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	PAT_END

pat_083FD3F0:				@ used by s3c3
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 2		@ F#5
	N	39, 17, 2		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 16, 4		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	PAT_END

pat_083FD493:				@ used by s3c3
	N	38, 16, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 16, 2		@ G#5
	N	45, 17, 2		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 17, 2		@ A#5
	N	38, 16, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 16, 2		@ G#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	38, 16, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 17, 2		@ G#5
	PAT_END

pat_083FD536:				@ used by s3c3
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 7		@ E5
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 16, 6		@ F#5
	REST	0, 2
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 7		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	PAT_END

pat_083FD5C1:				@ used by s3c3
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 17, 2		@ G#5
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 2		@ F#5
	N	39, 17, 2		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	36, 16, 4		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	36, 17, 2		@ C#5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 16, 4		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	39, 16, 4		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	39, 17, 2		@ E5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	PAT_END

pat_083FD664:				@ used by s3c3
	N	38, 16, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 16, 2		@ G#5
	N	45, 17, 2		@ A#5
	N	45, 16, 4		@ A#5
	N	45, 17, 2		@ A#5
	N	38, 16, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 16, 2		@ G#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	38, 16, 4		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	38, 17, 2		@ D#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 16, 4		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	41, 17, 2		@ F#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 17, 2		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 16, 4		@ G#5
	N	43, 17, 2		@ G#5
	PAT_END

pat_083FD707:				@ used by s3c4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FD741:				@ used by s3c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	34, 5, 4		@ B4
	N	26, 2, 4		@ D#4
	N	26, 2, 4		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FD7A8:				@ used by s3c4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 4		@ C#4
	N	26, 2, 4		@ D#4
	N	26, 2, 4		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FD7E2:				@ used by s4c1
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	61, 13, 2		@ D7
	N	59, 13, 5		@ C7
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	61, 13, 2		@ D7
	N	59, 13, 7		@ C7
	REST	0, 2
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	61, 13, 2		@ D7
	N	62, 13, 5		@ D#7
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	66, 13, 7		@ G7
	REST	0, 2
	PAT_END

pat_083FD819:				@ used by s4c1
	N	62, 13, 2		@ D#7
	N	61, 13, 2		@ D7
	N	59, 13, 2		@ C7
	N	57, 13, 5		@ A#6
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	61, 13, 2		@ D7
	N	59, 13, 7		@ C7
	REST	0, 2
	N	62, 13, 2		@ D#7
	N	61, 13, 2		@ D7
	N	59, 13, 2		@ C7
	N	57, 13, 5		@ A#6
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	66, 13, 7		@ G7
	REST	0, 2
	PAT_END

pat_083FD850:				@ used by s4c1
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	61, 13, 2		@ D7
	N	59, 13, 4		@ C7
	N	62, 13, 4		@ D#7
	N	61, 13, 4		@ D7
	N	64, 13, 4		@ F7
	N	66, 13, 6		@ G7
	REST	0, 2
	N	61, 13, 2		@ D7
	N	59, 13, 2		@ C7
	N	57, 13, 2		@ A#6
	N	55, 13, 4		@ G#6
	N	59, 13, 4		@ C7
	N	57, 13, 8		@ A#6
	REST	0, 2
	PAT_END

pat_083FD881:				@ used by s4c1
	N	57, 13, 2		@ A#6
	N	59, 13, 2		@ C7
	N	61, 13, 2		@ D7
	N	59, 13, 4		@ C7
	N	62, 13, 4		@ D#7
	N	61, 13, 4		@ D7
	N	64, 13, 4		@ F7
	N	66, 13, 6		@ G7
	REST	0, 2
	N	61, 13, 2		@ D7
	N	59, 13, 2		@ C7
	N	57, 13, 2		@ A#6
	N	55, 13, 4		@ G#6
	N	59, 13, 4		@ C7
	N	57, 13, 8		@ A#6
	REST	0, 2
	PAT_END

pat_083FD8B2:				@ used by s4c1
	N	69, 14, 6		@ A#7
	N	67, 14, 5		@ G#7
	N	66, 13, 4		@ G7
	N	62, 13, 7		@ D#7
	REST	0, 2
	N	62, 13, 4		@ D#7
	N	64, 13, 4		@ F7
	N	66, 13, 2		@ G7
	N	67, 13, 4		@ G#7
	N	69, 14, 8		@ A#7
	REST	0, 2
	PAT_END

pat_083FD8D4:				@ used by s4c1
	N	66, 14, 5		@ G7
	N	64, 13, 4		@ F7
	N	66, 13, 2		@ G7
	N	67, 13, 4		@ G#7
	N	66, 13, 4		@ G7
	N	62, 13, 7		@ D#7
	N	62, 13, 2		@ D#7
	N	66, 13, 4		@ G7
	N	64, 13, 4		@ F7
	N	67, 13, 4		@ G#7
	N	66, 13, 4		@ G7
	N	69, 13, 4		@ A#7
	N	67, 13, 4		@ G#7
	N	71, 13, 5		@ C8
	PAT_END

pat_083FD8FF:				@ used by s4c1
	N	69, 13, 4		@ A#7
	N	66, 13, 4		@ G7
	N	67, 13, 2		@ G#7
	N	64, 13, 4		@ F7
	N	66, 13, 4		@ G7
	N	62, 13, 7		@ D#7
	REST	0, 2
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	66, 13, 2		@ G7
	N	67, 13, 4		@ G#7
	N	69, 13, 2		@ A#7
	N	71, 13, 4		@ C8
	N	69, 13, 4		@ A#7
	N	66, 13, 7		@ G7
	PAT_END

pat_083FD92D:				@ used by s4c1
	N	66, 14, 5		@ G7
	N	64, 13, 4		@ F7
	N	66, 13, 2		@ G7
	N	67, 13, 4		@ G#7
	N	69, 13, 4		@ A#7
	N	66, 13, 7		@ G7
	N	62, 13, 2		@ D#7
	N	66, 13, 4		@ G7
	N	64, 13, 4		@ F7
	N	67, 13, 4		@ G#7
	N	66, 13, 4		@ G7
	N	69, 13, 4		@ A#7
	N	67, 13, 4		@ G#7
	N	71, 13, 5		@ C8
	PAT_END

pat_083FD958:				@ used by s4c2
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	62, 13, 4		@ D#7
	N	66, 13, 4		@ G7
	N	64, 13, 4		@ F7
	N	68, 13, 4		@ A7
	N	69, 13, 6		@ A#7
	REST	0, 2
	N	64, 13, 2		@ F7
	N	62, 13, 2		@ D#7
	N	61, 13, 2		@ D7
	N	59, 13, 4		@ C7
	N	62, 13, 4		@ D#7
	N	61, 13, 8		@ D7
	REST	0, 2
	PAT_END

pat_083FD989:				@ used by s4c2
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	62, 13, 4		@ D#7
	N	66, 13, 4		@ G7
	N	64, 13, 4		@ F7
	N	68, 13, 4		@ A7
	N	69, 13, 6		@ A#7
	REST	0, 2
	N	64, 13, 2		@ F7
	N	62, 13, 2		@ D#7
	N	61, 13, 2		@ D7
	N	59, 13, 4		@ C7
	N	62, 13, 4		@ D#7
	N	61, 13, 8		@ D7
	REST	0, 2
	PAT_END

pat_083FD9BA:				@ used by s4c2
	N	66, 15, 6		@ G7
	N	64, 15, 5		@ F7
	N	62, 13, 4		@ D#7
	N	57, 13, 7		@ A#6
	REST	0, 2
	N	57, 13, 4		@ A#6
	N	62, 13, 4		@ D#7
	N	60, 13, 2		@ C#7
	N	64, 13, 4		@ F7
	N	62, 15, 8		@ D#7
	REST	0, 2
	PAT_END

pat_083FD9DC:				@ used by s4c2
	N	62, 15, 5		@ D#7
	N	60, 13, 4		@ C#7
	N	62, 13, 2		@ D#7
	N	64, 13, 4		@ F7
	N	62, 13, 4		@ D#7
	N	57, 13, 7		@ A#6
	N	66, 15, 6		@ G7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	71, 15, 6		@ C8
	PAT_END

pat_083FD9FB:				@ used by s4c2
	N	66, 13, 4		@ G7
	N	62, 13, 4		@ D#7
	N	64, 13, 2		@ F7
	N	60, 13, 4		@ C#7
	N	62, 13, 4		@ D#7
	N	57, 13, 7		@ A#6
	REST	0, 2
	N	66, 13, 2		@ G7
	N	67, 13, 2		@ G#7
	N	69, 13, 2		@ A#7
	N	71, 13, 4		@ C8
	N	72, 13, 2		@ C#8
	N	76, 13, 4		@ F8
	N	74, 13, 4		@ D#8
	N	71, 13, 7		@ C8
	PAT_END

pat_083FDA29:				@ used by s4c2
	N	62, 15, 5		@ D#7
	N	60, 13, 4		@ C#7
	N	62, 13, 2		@ D#7
	N	64, 13, 4		@ F7
	N	66, 13, 4		@ G7
	N	62, 13, 7		@ D#7
	N	66, 15, 6		@ G7
	N	67, 15, 6		@ G#7
	N	69, 15, 6		@ A#7
	N	71, 15, 6		@ C8
	PAT_END

pat_083FDA48:				@ used by s4c2
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	62, 13, 5		@ D#7
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	62, 13, 7		@ D#7
	REST	0, 2
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	66, 13, 5		@ G7
	N	64, 13, 2		@ F7
	N	66, 13, 2		@ G7
	N	68, 13, 2		@ A7
	N	69, 13, 7		@ A#7
	REST	0, 2
	PAT_END

pat_083FDA7F:				@ used by s4c2
	N	66, 13, 2		@ G7
	N	64, 13, 2		@ F7
	N	62, 13, 2		@ D#7
	N	61, 13, 5		@ D7
	N	61, 13, 2		@ D7
	N	62, 13, 2		@ D#7
	N	64, 13, 2		@ F7
	N	62, 13, 7		@ D#7
	REST	0, 2
	N	66, 13, 2		@ G7
	N	64, 13, 2		@ F7
	N	62, 13, 2		@ D#7
	N	61, 13, 5		@ D7
	N	64, 13, 2		@ F7
	N	66, 13, 2		@ G7
	N	68, 13, 2		@ A7
	N	69, 13, 7		@ A#7
	REST	0, 2
	PAT_END

pat_083FDAB6:				@ used by s4c3
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	43, 17, 5		@ G#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	43, 17, 2		@ G#5
	N	48, 17, 4		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	43, 17, 5		@ G#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	43, 17, 2		@ G#5
	N	50, 17, 4		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	PAT_END

pat_083FDB05:				@ used by s4c3
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	55, 17, 2		@ G#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	55, 17, 2		@ G#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	PAT_END

pat_083FDB66:				@ used by s4c3
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	55, 17, 2		@ G#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	55, 17, 2		@ G#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	57, 17, 2		@ A#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	PAT_END

pat_083FDBC7:				@ used by s4c3
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	42, 17, 5		@ G5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	42, 17, 2		@ G5
	N	48, 17, 4		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	42, 17, 5		@ G5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	45, 17, 2		@ A#5
	N	42, 17, 2		@ G5
	N	50, 17, 4		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	PAT_END

pat_083FDC16:				@ used by s4c3
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	PAT_END

pat_083FDC65:				@ used by s4c3
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	53, 17, 2		@ F#6
	N	53, 17, 2		@ F#6
	N	53, 17, 2		@ F#6
	N	53, 17, 2		@ F#6
	N	53, 17, 2		@ F#6
	N	53, 17, 2		@ F#6
	N	53, 17, 2		@ F#6
	PAT_END

pat_083FDCB4:				@ used by s4c3
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	N	55, 17, 2		@ G#6
	PAT_END

pat_083FDD03:				@ used by s4c3
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	48, 17, 2		@ C#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 4		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	N	50, 17, 2		@ D#6
	PAT_END

pat_083FDD49:				@ used by s4c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	26, 2, 2		@ D#4
	N	26, 2, 4		@ D#4
	N	26, 2, 4		@ D#4
	PAT_END

pat_083FDD83:				@ used by s4c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FDDBD:				@ used by s4c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	26, 2, 2		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FDE06:				@ used by s4c4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	26, 2, 4		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FDE52:				@ used by s4c4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 4		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	30, 3, 2		@ G4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FDE95:				@ used by s4c4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 4		@ G4
	N	26, 2, 4		@ D#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	26, 2, 4		@ D#4
	N	24, 1, 4		@ C#4
	N	26, 2, 4		@ D#4
	N	24, 1, 2		@ C#4
	N	26, 2, 4		@ D#4
	N	26, 2, 4		@ D#4
	N	26, 2, 4		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	N	26, 2, 2		@ D#4
	PAT_END

pat_083FDED2:				@ used by s5c1
	N	70, 14, 9		@ B7
	N	69, 14, 6		@ A#7
	N	65, 14, 8		@ F#7
	N	67, 14, 8		@ G#7
	PAT_END

pat_083FDEDF:				@ used by s5c1
	N	72, 14, 5		@ C#8
	N	70, 13, 5		@ B7
	N	69, 13, 4		@ A#7
	N	70, 14, 5		@ B7
	N	72, 13, 5		@ C#8
	N	67, 13, 4		@ G#7
	N	70, 14, 5		@ B7
	N	69, 13, 5		@ A#7
	N	69, 13, 8		@ A#7
	REST	0, 4
	N	70, 14, 5		@ B7
	N	69, 13, 5		@ A#7
	N	65, 13, 4		@ F#7
	N	69, 14, 5		@ A#7
	N	67, 13, 5		@ G#7
	N	65, 13, 4		@ F#7
	N	65, 14, 5		@ F#7
	N	67, 13, 9		@ G#7
	REST	0, 2
	PAT_END

pat_083FDF19:				@ used by s5c1
	N	65, 14, 5		@ F#7
	N	63, 13, 5		@ E7
	N	62, 13, 4		@ D#7
	N	63, 14, 5		@ E7
	N	65, 13, 6		@ F#7
	REST	0, 2
	N	63, 14, 5		@ E7
	N	62, 13, 5		@ D#7
	N	60, 13, 4		@ C#7
	N	62, 14, 5		@ D#7
	N	63, 13, 6		@ E7
	REST	0, 2
	N	62, 14, 5		@ D#7
	N	60, 13, 5		@ C#7
	N	62, 13, 4		@ D#7
	N	63, 14, 5		@ E7
	N	62, 13, 5		@ D#7
	N	63, 13, 4		@ E7
	N	65, 14, 5		@ F#7
	N	63, 13, 5		@ E7
	N	65, 13, 4		@ F#7
	N	67, 14, 6		@ G#7
	N	69, 14, 6		@ A#7
	PAT_END

pat_083FDF5F:				@ used by s5c1
	N	63, 13, 4		@ E7
	N	64, 13, 2		@ F7
	N	65, 13, 5		@ F#7
	N	65, 13, 4		@ F#7
	N	68, 14, 4		@ A7
	N	65, 13, 4		@ F#7
	N	63, 13, 4		@ E7
	N	65, 13, 4		@ F#7
	N	63, 13, 4		@ E7
	N	64, 13, 2		@ F7
	N	65, 13, 5		@ F#7
	N	65, 13, 8		@ F#7
	REST	0, 4
	N	63, 13, 4		@ E7
	N	64, 13, 2		@ F7
	N	65, 13, 5		@ F#7
	N	65, 13, 4		@ F#7
	N	68, 14, 4		@ A7
	N	67, 13, 4		@ G#7
	N	70, 14, 4		@ B7
	N	67, 13, 4		@ G#7
	N	65, 13, 4		@ F#7
	N	63, 13, 2		@ E7
	N	60, 13, 5		@ C#7
	N	60, 13, 8		@ C#7
	REST	0, 4
	PAT_END

pat_083FDFAE:				@ used by s5c1
	N	65, 13, 7		@ F#7
	N	65, 13, 6		@ F#7
	N	65, 13, 5		@ F#7
	N	65, 13, 5		@ F#7
	N	63, 13, 7		@ E7
	N	63, 13, 6		@ E7
	N	63, 13, 5		@ E7
	N	63, 13, 5		@ E7
	N	61, 13, 7		@ D7
	N	61, 13, 6		@ D7
	N	61, 13, 5		@ D7
	N	61, 13, 5		@ D7
	N	60, 13, 7		@ C#7
	N	60, 13, 6		@ C#7
	N	60, 13, 5		@ C#7
	N	60, 13, 5		@ C#7
	PAT_END

pat_083FDFDF:				@ used by s5c2
	N	55, 15, 10		@ G#6
	N	57, 15, 10		@ A#6
	N	59, 15, 10		@ C7
	N	60, 15, 10		@ C#7
	PAT_END

pat_083FDFEC:				@ used by s5c2
	N	88, 15, 5		@ F9
	N	86, 13, 5		@ D#9
	N	84, 13, 4		@ C#9
	N	86, 15, 5		@ D#9
	N	88, 13, 5		@ F9
	N	84, 13, 4		@ C#9
	N	86, 15, 5		@ D#9
	N	84, 13, 5		@ C#9
	N	84, 13, 8		@ C#9
	REST	0, 4
	N	86, 15, 5		@ D#9
	N	84, 13, 5		@ C#9
	N	82, 13, 4		@ B8
	N	84, 15, 5		@ C#9
	N	82, 13, 5		@ B8
	N	81, 13, 4		@ A#8
	N	81, 15, 5		@ A#8
	N	82, 13, 9		@ B8
	REST	0, 2
	PAT_END

pat_083FE026:				@ used by s5c2
	N	77, 13, 4		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 2		@ F#7
	N	77, 13, 4		@ F#8
	N	77, 13, 2		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 2		@ F#7
	N	77, 13, 4		@ F#8
	N	77, 13, 2		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 6		@ F#8
	N	77, 13, 4		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 2		@ F#7
	N	77, 13, 4		@ F#8
	N	77, 13, 2		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 2		@ F#7
	N	77, 13, 4		@ F#8
	N	77, 13, 2		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 4		@ F#8
	N	65, 13, 4		@ F#7
	N	77, 13, 6		@ F#8
	PAT_END

pat_083FE08D:				@ used by s5c2
	N	69, 13, 7		@ A#7
	N	69, 13, 6		@ A#7
	N	69, 13, 5		@ A#7
	N	69, 13, 5		@ A#7
	N	70, 13, 7		@ B7
	N	70, 13, 6		@ B7
	N	70, 13, 5		@ B7
	N	70, 13, 5		@ B7
	N	73, 13, 7		@ D8
	N	73, 13, 6		@ D8
	N	73, 13, 5		@ D8
	N	73, 13, 5		@ D8
	N	76, 13, 7		@ F8
	N	76, 13, 6		@ F8
	N	76, 13, 5		@ F8
	N	76, 13, 5		@ F8
	PAT_END

pat_083FE0BE:				@ used by s5c3
	N	55, 17, 5		@ G#6
	N	53, 17, 5		@ F#6
	N	55, 17, 6		@ G#6
	N	50, 17, 5		@ D#6
	N	53, 17, 5		@ F#6
	N	55, 17, 5		@ G#6
	N	53, 17, 5		@ F#6
	N	55, 17, 4		@ G#6
	N	50, 16, 8		@ D#6
	N	55, 17, 5		@ G#6
	N	53, 17, 5		@ F#6
	N	55, 17, 6		@ G#6
	N	50, 17, 5		@ D#6
	N	53, 17, 5		@ F#6
	N	55, 17, 5		@ G#6
	N	53, 17, 5		@ F#6
	N	55, 17, 4		@ G#6
	N	50, 16, 8		@ D#6
	PAT_END

pat_083FE0F5:				@ used by s5c3
	N	55, 16, 4		@ G#6
	N	58, 17, 2		@ B6
	N	46, 17, 2		@ B5
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	43, 17, 2		@ G#5
	N	47, 17, 2		@ C6
	N	55, 17, 2		@ G#6
	N	52, 17, 2		@ F6
	N	55, 17, 2		@ G#6
	N	52, 17, 2		@ F6
	N	60, 17, 2		@ C#7
	N	47, 17, 2		@ C6
	N	67, 17, 2		@ G#7
	N	43, 17, 2		@ G#5
	N	57, 16, 4		@ A#6
	N	60, 17, 2		@ C#7
	N	48, 17, 2		@ C#6
	N	62, 17, 2		@ D#7
	N	50, 17, 2		@ D#6
	N	45, 17, 2		@ A#5
	N	49, 17, 2		@ D6
	N	57, 17, 2		@ A#6
	N	54, 17, 2		@ G6
	N	57, 17, 2		@ A#6
	N	54, 17, 2		@ G6
	N	62, 17, 2		@ D#7
	N	49, 17, 2		@ D6
	N	69, 17, 2		@ A#7
	N	45, 17, 2		@ A#5
	N	59, 16, 4		@ C7
	N	62, 17, 2		@ D#7
	N	50, 17, 2		@ D#6
	N	64, 17, 2		@ F7
	N	52, 17, 2		@ F6
	N	47, 17, 2		@ C6
	N	51, 17, 2		@ E6
	N	59, 17, 2		@ C7
	N	56, 17, 2		@ A6
	N	59, 17, 2		@ C7
	N	56, 17, 2		@ A6
	N	64, 17, 2		@ F7
	N	51, 17, 2		@ E6
	N	71, 17, 2		@ C8
	N	47, 17, 2		@ C6
	N	60, 16, 4		@ C#7
	N	63, 17, 2		@ E7
	N	51, 17, 2		@ E6
	N	65, 17, 2		@ F#7
	N	53, 17, 2		@ F#6
	N	48, 17, 2		@ C#6
	N	52, 17, 2		@ F6
	N	60, 17, 2		@ C#7
	N	57, 17, 2		@ A#6
	N	60, 17, 2		@ C#7
	N	57, 17, 2		@ A#6
	N	65, 17, 2		@ F#7
	N	52, 17, 2		@ F6
	N	72, 17, 2		@ C#8
	N	48, 17, 2		@ C#6
	PAT_END

pat_083FE1AA:				@ used by s5c3
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 5		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 5		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	PAT_END

pat_083FE211:				@ used by s5c3
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 5		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 5		@ C#6
	N	60, 17, 2		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	PAT_END

pat_083FE278:				@ used by s5c3
	N	51, 16, 5		@ E6
	N	52, 17, 5		@ F6
	N	53, 17, 6		@ F#6
	N	53, 17, 5		@ F#6
	N	53, 17, 5		@ F#6
	N	51, 16, 5		@ E6
	N	52, 17, 5		@ F6
	N	53, 17, 4		@ F#6
	N	56, 16, 6		@ A6
	N	58, 16, 6		@ B6
	N	51, 16, 5		@ E6
	N	52, 17, 5		@ F6
	N	53, 17, 6		@ F#6
	N	53, 17, 5		@ F#6
	N	53, 17, 5		@ F#6
	N	56, 16, 5		@ A6
	N	55, 17, 4		@ G#6
	N	51, 17, 2		@ E6
	N	48, 16, 8		@ C#6
	REST	0, 4
	PAT_END

pat_083FE2B5:				@ used by s5c3
	N	53, 16, 4		@ F#6
	N	65, 17, 4		@ F#7
	N	53, 16, 4		@ F#6
	N	65, 17, 4		@ F#7
	N	53, 16, 4		@ F#6
	N	65, 17, 4		@ F#7
	N	53, 16, 5		@ F#6
	N	65, 17, 2		@ F#7
	N	51, 16, 4		@ E6
	N	63, 17, 4		@ E7
	N	51, 16, 4		@ E6
	N	63, 17, 4		@ E7
	N	51, 16, 4		@ E6
	N	63, 17, 4		@ E7
	N	51, 16, 4		@ E6
	N	63, 17, 2		@ E7
	N	63, 17, 2		@ E7
	N	49, 16, 4		@ D6
	N	61, 17, 4		@ D7
	N	49, 16, 4		@ D6
	N	61, 17, 4		@ D7
	N	49, 16, 4		@ D6
	N	61, 17, 4		@ D7
	N	49, 16, 5		@ D6
	N	61, 17, 2		@ D7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 4		@ C#7
	N	48, 16, 4		@ C#6
	N	60, 17, 2		@ C#7
	N	60, 17, 2		@ C#7
	PAT_END

pat_083FE31C:				@ used by s5c4
	N	24, 1, 6		@ C#4
	N	34, 5, 6		@ B4
	N	24, 1, 8		@ C#4
	N	24, 1, 6		@ C#4
	N	34, 5, 6		@ B4
	N	24, 1, 8		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 2, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 2, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 2, 6		@ C#4
	N	24, 1, 6		@ C#4
	N	24, 2, 6		@ C#4
	PAT_END

pat_083FE347:				@ used by s5c4
	N	24, 1, 6		@ C#4
	N	24, 2, 2		@ C#4
	N	34, 5, 5		@ B4
	N	24, 1, 6		@ C#4
	N	24, 2, 2		@ C#4
	N	34, 5, 5		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 2, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 2, 4		@ C#4
	N	34, 5, 4		@ B4
	N	24, 1, 4		@ C#4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 4		@ C#4
	N	24, 1, 4		@ C#4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 4		@ C#4
	N	24, 1, 4		@ C#4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 4		@ C#4
	N	24, 1, 4		@ C#4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	PAT_END

pat_083FE3BD:				@ used by s5c4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	PAT_END

pat_083FE466:				@ used by s5c4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	PAT_END

pat_083FE50F:				@ used by s5c4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	PAT_END

pat_083FE5B8:				@ used by s5c4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	PAT_END

pat_083FE661:				@ used by s5c4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 2		@ C#4
	N	34, 5, 2		@ B4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 2, 4		@ C#4
	N	30, 3, 2		@ G4
	N	30, 3, 2		@ G4
	N	24, 1, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	N	24, 2, 2		@ C#4
	PAT_END
@ 083FE70A-083FE70C: 2 bytes, after the pattern end
	.byte	0x00, 0x00

seq_s00_c0:				@ 083FE70C
	SEQ_PAN 0xFF
	SEQ_TEMPO 255
	SEQ_PAT	pat_083FC77C, 0, 1
	SEQ_CONDFLAG 1
	SEQ_END

seq_s00_c1:				@ 083FE738
	SEQ_PAT	pat_083FC77C, 0, 1
	SEQ_END

seq_s00_c2:				@ 083FE74C
	SEQ_PAT	pat_083FC77C, 0, 1
	SEQ_END

seq_s00_c3:				@ 083FE760
	SEQ_PAT	pat_083FC77C, 0, 1
	SEQ_END

seq_s01_c0:				@ 083FE774
	SEQ_PAN 0xFF
	SEQ_TEMPO 223
	SEQ_PAT	pat_083FC778, 0, 8
	SEQ_PAT	pat_083FC780, -20, 2
	SEQ_PAT	pat_083FC780, -20, 2
	SEQ_PAT	pat_083FC7B7, -20, 2
	SEQ_PAT	pat_083FC7E8, -20, 2
	SEQ_PAT	pat_083FC82E, -20, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 12

seq_s01_c1:				@ 083FE7F4
	SEQ_PAT	pat_083FC778, 0, 16
	SEQ_PAT	pat_083FC898, -32, 2
	SEQ_PAT	pat_083FC778, 0, 2
	SEQ_PAT	pat_083FC8F3, -32, 1
	SEQ_PAT	pat_083FC923, -32, 2
	SEQ_PAT	pat_083FC97B, -32, 1
	SEQ_JUMP 4

seq_s01_c2:				@ 083FE85C
	SEQ_PAT	pat_083FCA3C, -44, 4
	SEQ_PAT	pat_083FCA3C, -44, 2
	SEQ_PAT	pat_083FCAD9, -44, 2
	SEQ_PAT	pat_083FCA3C, -44, 2
	SEQ_PAT	pat_083FCB3A, -44, 1
	SEQ_PAT	pat_083FCB9B, -44, 1
	SEQ_JUMP 4

seq_s01_c3:				@ 083FE8C4
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FCBFC, 0, 3
	SEQ_PAT	pat_083FCBFC, 0, 6
	SEQ_JUMP 8

seq_s02_c0:				@ 083FE8FC
	SEQ_PAN 0xFF
	SEQ_TEMPO 206
	SEQ_PAT	pat_083FC778, 0, 8
	SEQ_PAT	pat_083FCC8D, -14, 2
	SEQ_PAT	pat_083FCCCD, -14, 2
	SEQ_PAT	pat_083FCD0D, -14, 1
	SEQ_PAT	pat_083FCD4A, -14, 1
	SEQ_PAT	pat_083FCC8D, -14, 2
	SEQ_PAT	pat_083FCCCD, -14, 2
	SEQ_PAT	pat_083FCD87, -14, 1
	SEQ_PAT	pat_083FCDE2, -14, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 8

seq_s02_c1:				@ 083FE9AC
	SEQ_PAT	pat_083FC778, 0, 8
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FCE1F, -26, 1
	SEQ_PAT	pat_083FCE4A, -26, 1
	SEQ_PAT	pat_083FCE5A, -26, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FCE82, -26, 1
	SEQ_PAT	pat_083FCEA1, -26, 2
	SEQ_PAT	pat_083FCEF0, -26, 1
	SEQ_PAT	pat_083FCE5A, -26, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FCE82, -26, 1
	SEQ_JUMP 4

seq_s02_c2:				@ 083FEA74
	SEQ_PAT	pat_083FCF00, -38, 2
	SEQ_PAT	pat_083FCF00, -38, 4
	SEQ_PAT	pat_083FCFB8, -38, 2
	SEQ_PAT	pat_083FCF00, -38, 4
	SEQ_PAT	pat_083FCFB8, -38, 2
	SEQ_JUMP 4

seq_s02_c3:				@ 083FEACC
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FD079, 0, 3
	SEQ_PAT	pat_083FD098, 0, 1
	SEQ_JUMP 4

seq_s03_c0:				@ 083FEB04
	SEQ_PAN 0xFF
	SEQ_TEMPO 223
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FD0BD, -19, 2
	SEQ_PAT	pat_083FD11E, -19, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FD17F, -19, 2
	SEQ_PAT	pat_083FD207, -19, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 4

seq_s03_c1:				@ 083FEB84
	SEQ_PAT	pat_083FC778, 0, 8
	SEQ_PAT	pat_083FD28F, -31, 1
	SEQ_PAT	pat_083FD2A5, -31, 1
	SEQ_PAT	pat_083FC778, 0, 8
	SEQ_PAT	pat_083FD2BB, -31, 1
	SEQ_PAT	pat_083FD310, -31, 1
	SEQ_JUMP 0

seq_s03_c2:				@ 083FEBEC
	SEQ_PAT	pat_083FD365, -19, 1
	SEQ_PAT	pat_083FD3F0, -19, 2
	SEQ_PAT	pat_083FD493, -19, 1
	SEQ_PAT	pat_083FD536, -19, 1
	SEQ_PAT	pat_083FD5C1, -19, 2
	SEQ_PAT	pat_083FD664, -19, 1
	SEQ_JUMP 0

seq_s03_c3:				@ 083FEC54
	SEQ_PAT	pat_083FD707, 0, 1
	SEQ_PAT	pat_083FD741, 0, 3
	SEQ_PAT	pat_083FD7A8, 0, 1
	SEQ_PAT	pat_083FD741, 0, 3
	SEQ_JUMP 0

seq_s04_c0:				@ 083FEC9C
	SEQ_PAN 0xFF
	SEQ_TEMPO 206
	SEQ_PAT	pat_083FD7E2, -18, 1
	SEQ_PAT	pat_083FD819, -18, 1
	SEQ_PAT	pat_083FD850, -18, 2
	SEQ_PAT	pat_083FD881, -13, 1
	SEQ_PAT	pat_083FD850, -18, 1
	SEQ_PAT	pat_083FD7E2, -18, 1
	SEQ_PAT	pat_083FD819, -18, 1
	SEQ_PAT	pat_083FD850, -18, 2
	SEQ_PAT	pat_083FD881, -13, 1
	SEQ_PAT	pat_083FD850, -18, 1
	SEQ_PAT	pat_083FD8B2, -18, 1
	SEQ_PAT	pat_083FD8D4, -18, 1
	SEQ_PAT	pat_083FD8FF, -18, 1
	SEQ_PAT	pat_083FD92D, -18, 1
	SEQ_PAT	pat_083FD7E2, -18, 1
	SEQ_PAT	pat_083FD819, -18, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 12

seq_s04_c1:				@ 083FEDBC
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FC778, 0, 12
	SEQ_PAT	pat_083FD958, -18, 2
	SEQ_PAT	pat_083FD989, -13, 1
	SEQ_PAT	pat_083FD958, -18, 1
	SEQ_PAT	pat_083FD9BA, -30, 1
	SEQ_PAT	pat_083FD9DC, -30, 1
	SEQ_PAT	pat_083FD9FB, -30, 1
	SEQ_PAT	pat_083FDA29, -30, 1
	SEQ_PAT	pat_083FDA48, -18, 1
	SEQ_PAT	pat_083FDA7F, -18, 1
	SEQ_JUMP 4

seq_s04_c2:				@ 083FEE74
	SEQ_PAT	pat_083FDAB6, -30, 2
	SEQ_PAT	pat_083FDB05, -30, 2
	SEQ_PAT	pat_083FDB66, -25, 1
	SEQ_PAT	pat_083FDB05, -30, 1
	SEQ_PAT	pat_083FDBC7, -30, 2
	SEQ_PAT	pat_083FDB05, -30, 2
	SEQ_PAT	pat_083FDB66, -25, 1
	SEQ_PAT	pat_083FDB05, -30, 1
	SEQ_PAT	pat_083FDC16, -30, 1
	SEQ_PAT	pat_083FDC65, -30, 1
	SEQ_PAT	pat_083FDCB4, -30, 1
	SEQ_PAT	pat_083FDD03, -30, 1
	SEQ_PAT	pat_083FDAB6, -30, 2
	SEQ_JUMP 4

seq_s04_c3:				@ 083FEF4C
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FDD49, 0, 1
	SEQ_PAT	pat_083FDD83, 0, 1
	SEQ_PAT	pat_083FDD49, 0, 1
	SEQ_PAT	pat_083FDDBD, 0, 1
	SEQ_PAT	pat_083FDE06, 0, 1
	SEQ_PAT	pat_083FDD49, 0, 1
	SEQ_PAT	pat_083FDD83, 0, 1
	SEQ_PAT	pat_083FDD49, 0, 1
	SEQ_PAT	pat_083FDDBD, 0, 1
	SEQ_PAT	pat_083FDE52, 0, 3
	SEQ_PAT	pat_083FDE95, 0, 1
	SEQ_PAT	pat_083FDE06, 0, 1
	SEQ_JUMP 4

seq_s05_c0:				@ 083FF024
	SEQ_PAN 0xFF
	SEQ_TEMPO 223
	SEQ_PAT	pat_083FC778, 0, 2
	SEQ_PAT	pat_083FDED2, -18, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FDEDF, -18, 2
	SEQ_PAT	pat_083FDF19, -18, 1
	SEQ_PAT	pat_083FDEDF, -18, 1
	SEQ_PAT	pat_083FDF5F, -18, 2
	SEQ_PAT	pat_083FDFAE, -18, 1
	SEQ_CONDFLAG 1
	SEQ_JUMP 12

seq_s05_c1:				@ 083FF0C4
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FDFDF, -18, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FDFEC, -42, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FDFEC, -42, 1
	SEQ_PAT	pat_083FC778, 0, 4
	SEQ_PAT	pat_083FE026, -30, 1
	SEQ_PAT	pat_083FE08D, -30, 1
	SEQ_JUMP 4

seq_s05_c2:				@ 083FF15C
	SEQ_PAT	pat_083FE0BE, -30, 1
	SEQ_PAT	pat_083FE0F5, -30, 1
	SEQ_PAT	pat_083FE1AA, -30, 2
	SEQ_PAT	pat_083FE211, -25, 1
	SEQ_PAT	pat_083FE1AA, -30, 1
	SEQ_PAT	pat_083FE278, -30, 2
	SEQ_PAT	pat_083FE2B5, -30, 1
	SEQ_JUMP 4

seq_s05_c3:				@ 083FF1D4
	SEQ_PAT	pat_083FE31C, 0, 1
	SEQ_PAT	pat_083FE347, 0, 1
	SEQ_PAT	pat_083FE3BD, 0, 2
	SEQ_PAT	pat_083FE466, 0, 1
	SEQ_PAT	pat_083FE50F, 0, 1
	SEQ_PAT	pat_083FE5B8, 0, 2
	SEQ_PAT	pat_083FE661, 0, 1
	SEQ_JUMP 4

	.global mcFreqLo
mcFreqLo:				@ 083FF24C  PSG frequency register low byte, 97 notes
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
mcFreqHi:				@ 083FF2AD  PSG frequency register high byte, 97 notes
	.byte	0x00, 0x01, 0x01, 0x01, 0x02, 0x02, 0x02, 0x03, 0x03, 0x03, 0x03, 0x04	@ 0..
	.byte	0x04, 0x04, 0x04, 0x04, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x05, 0x06	@ 12..
	.byte	0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x06, 0x07	@ 24..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 36..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 48..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 60..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 72..
	.byte	0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07, 0x07	@ 84..
	.byte	0x00	@ 96..
@ 083FF30E-083FF310: 2 bytes, padding
	.byte	0x00, 0x00

@ mcSongTable: {seq ch1..ch4, 0, 0, note-length table}.  Only words 0-3 are read; the driver
@ always uses mcDurTable (word 6 holds the same address for every song).
	.global mcSongTable
mcSongTable:				@ 083FF310
	.word	seq_s00_c0, seq_s00_c1, seq_s00_c2, seq_s00_c3, 0, 0, mcDurTable	@ song 0
	.word	seq_s01_c0, seq_s01_c1, seq_s01_c2, seq_s01_c3, 0, 0, mcDurTable	@ song 1
	.word	seq_s02_c0, seq_s02_c1, seq_s02_c2, seq_s02_c3, 0, 0, mcDurTable	@ song 2
	.word	seq_s03_c0, seq_s03_c1, seq_s03_c2, seq_s03_c3, 0, 0, mcDurTable	@ song 3
	.word	seq_s04_c0, seq_s04_c1, seq_s04_c2, seq_s04_c3, 0, 0, mcDurTable	@ song 4
	.word	seq_s05_c0, seq_s05_c1, seq_s05_c2, seq_s05_c3, 0, 0, mcDurTable	@ song 5

mod_083FF3B8:				@ env of inst 1
	.hword	240, 1, 0, 1, 112, 1, 0, 1
	.hword	255, 0

mod_083FF3CC:				@ env of inst 2
	.hword	240, 1, 112, 2, 48, 1, 32, 5
	.hword	16, 15, 0, 1, 255, 0, 0, 0

mod_083FF3EC:				@ env of inst 5
	.hword	80, 2, 48, 4, 32, 8, 16, 2
	.hword	16, 2, 0, 1, 255, 0, 0, 0

mod_083FF40C:				@ env of inst 15
	.hword	32, 1, 64, 1, 112, 1, 96, 2
	.hword	80, 5, 64, 20, 48, 20, 32, 80
	.hword	16, 20, 0, 1, 255, 0, 0, 0

mod_083FF43C:				@ env of inst 16
	.hword	128, 2, 64, 200, 64, 200, 96, 200
	.hword	96, 200, 0, 1, 255, 0, 0, 0

mod_083FF45C:				@ env of inst 17
	.hword	128, 2, 64, 6, 96, 6, 0, 1
	.hword	255, 0, 0, 0, 0, 0, 0, 0

mod_083FF47C:				@ env of inst 18
	.hword	128, 2, 64, 10, 96, 30, 0, 1
	.hword	255, 0, 0, 0, 0, 0, 0, 0

mod_083FF49C:				@ pitch of inst 1
	.hword	97, 200, 255, 0, 0, 0, 0, 0

mod_083FF4AC:				@ pitch of inst 2
	.hword	55, 2, 100, 2, 34, 1, 55, 1
	.hword	34, 1, 55, 1, 34, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 1
	.hword	55, 1, 34, 1, 55, 1, 34, 16
	.hword	255, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0

mod_083FF52C:				@ pitch of inst 3
	.hword	18, 200, 255, 0, 0, 0, 0, 0

mod_083FF53C:				@ pitch of inst 5
	.hword	34, 1, 16, 200, 255, 0, 0, 0

mod_083FF54C:				@ pitch of inst 13; pitch of inst 14
	.hword	2, 3, -2, 3, -2, 3, 2, 3
	.hword	254, 0, 0, 0

mod_083FF564:				@ pitch of inst 15
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	1, 3, -1, 3, -1, 3, 1, 3
	.hword	2, 3, -2, 3, -2, 3, 2, 3
	.hword	254, 32, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0

mod_083FF5E4:				@ pitch of inst 16; pitch of inst 17; pitch of inst 18
	.hword	6, 2, -6, 2, -6, 2, 6, 2
	.hword	254, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0
	.hword	3, 0, 3, 12, 3, 0, 3, 12
	.hword	3, 0, 3, 12, 254, 0, 0, 0
	.hword	0, 0, 0, 0, 0, 0, 0, 0

mod_083FF654:				@ arp of inst 13; arp of inst 14
	.hword	1, 0, 1, 0, 1, -12, 1, 0
	.hword	1, -12, 1, 0, 1, -12, 254, 2
	.hword	0, 0, 0, 0, 0, 0, 0, 0

@ PSG instruments (9 words): b0<<8 -> CNT_X, lo/hi -> envelope/duty register, then
@ {on, table} for envelope, pitch (noise parameter on ch4) and arpeggio
inst_00:				@ 083FF684
	INSTRUMENT 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0

inst_01:				@ 083FF6A8
	INSTRUMENT 0x40, 0xBD, 0x00, 1, mod_083FF3B8, 1, mod_083FF49C, 0, 0

inst_02:				@ 083FF6CC
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083FF3CC, 1, mod_083FF4AC, 0, 0

inst_03:				@ 083FF6F0
	INSTRUMENT 0x40, 0xBB, 0x91, 0, 0, 1, mod_083FF52C, 0, 0

inst_04:				@ 083FF714
	INSTRUMENT 0x00, 0x00, 0x00, 0, 0, 0, 0, 0, 0

inst_05:				@ 083FF738
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083FF3EC, 1, mod_083FF53C, 0, 0

inst_13:				@ 083FF75C
	INSTRUMENT 0x00, 0x80, 0x72, 0, 0, 1, mod_083FF54C, 1, mod_083FF654

inst_14:				@ 083FF780
	INSTRUMENT 0x00, 0x80, 0x77, 0, 0, 1, mod_083FF54C, 1, mod_083FF654

inst_15:				@ 083FF7A4
	INSTRUMENT 0x00, 0x80, 0x00, 1, mod_083FF40C, 1, mod_083FF564, 0, 0

inst_16:				@ 083FF7C8
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083FF43C, 24, mod_083FF5E4, 0, 0

inst_17:				@ 083FF7EC
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083FF45C, 6, mod_083FF5E4, 0, 0

inst_18:				@ 083FF810
	INSTRUMENT 0x00, 0x00, 0x00, 1, mod_083FF47C, 6, mod_083FF5E4, 0, 0

	.global mcInstTable
mcInstTable:				@ 083FF834
	.word	inst_00	@ 0
	.word	inst_01	@ 1
	.word	inst_02	@ 2
	.word	inst_03	@ 3
	.word	inst_04	@ 4
	.word	inst_05	@ 5
	.word	inst_04	@ 6
	.word	inst_04	@ 7
	.word	inst_04	@ 8
	.word	inst_04	@ 9
	.word	inst_04	@ 10
	.word	inst_04	@ 11
	.word	inst_04	@ 12
	.word	inst_13	@ 13
	.word	inst_14	@ 14
	.word	inst_15	@ 15
	.word	inst_16	@ 16
	.word	inst_17	@ 17
	.word	inst_18	@ 18
