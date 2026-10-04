@ ===========================================================================
@  mvdk_sfx_data.s  -  SFX table 0x08B92E20-0x08B949EC, SFX PCM 0x08B949EC-0x08DDD85C,
@                      SFX names 0x0807A2D0-0x0807ACFC. PCM comes from mvdk_sfx_pcm.bin.
@ ===========================================================================
	.include "mvdk_sound.inc"

@ SfxEntry (28 bytes): length, data, rate (Hz), name, volume (x/128), priority (0..15), flag
@ (not read by the driver), loop start, loop end. length 1 = "stop looping SFX of this priority".
	.macro SFX len, data, rate, name, vol, prio, flag, ls, le
	.word \len, \data, \rate, \name
	.hword \vol
	.byte \prio, \flag
	.word \ls, \le
	.endm

	.section .snd_sfx, "a", %progbits
	.global sfxCount, sfxTable
sfxCount: .word 254 @ 0x08B92E20 (not read by the driver)
sfxTable: @ 0x08B92E24
	SFX  3202, sfx_000,  8000, sfxName_000, 128,  0, 1,     0,  3202 @ 0x00 CLIMB
	SFX  1857, sfx_001,  8000, sfxName_001, 128,  0, 0,     0,  1857 @ 0x01 SKID
	SFX 13439, sfx_002,  8000, sfxName_002,  90,  0, 0,     0, 13439 @ 0x02 POUND
	SFX  3048, sfx_003,  8000, sfxName_003, 128,  3, 0,     0,  3048 @ 0x03 TUMBLE1
	SFX 11679, sfx_004,  8000, sfxName_004, 128,  3, 0,     0, 11679 @ 0x04 STUN
	SFX  6403, sfx_005,  8000, sfxName_005, 128,  3, 0,     0,  6403 @ 0x05 BURN1
	SFX  3765, sfx_006,  8000, sfxName_006, 140,  2, 0,     0,  3765 @ 0x06 JUMP_1
	SFX  1658, sfx_007,  8000, sfxName_007,  80,  2, 0,     0,  1658 @ 0x07 GRUNT2
	SFX  8571, sfx_008,  8000, sfxName_008, 100,  2, 0,     0,  8571 @ 0x08 JUMP_4
	SFX  6320, sfx_009,  8000, sfxName_009, 100,  2, 0,     0,  6320 @ 0x09 JUMP_3
	SFX  3004, sfx_010,  8000, sfxName_010, 128,  2, 0,     0,  3004 @ 0x0A PICKUP
	SFX  8007, sfx_011,  8000, sfxName_011, 100,  2, 0,     0,  8007 @ 0x0B JUMP_5
	SFX   385, sfx_012,  8000, sfxName_012, 128,  0, 0,     0,   385 @ 0x0C COUNTER
	SFX  5766, sfx_013,  8000, sfxName_013, 128,  5, 0,     0,  5766 @ 0x0D ITEM1
	SFX  3200, sfx_014,  8000, sfxName_014, 128,  0, 0,     0,  3200 @ 0x0E STEPS2
	SFX  3808, sfx_015, 11025, sfxName_015,  60,  8, 0,     0,  3808 @ 0x0F KEY1
	SFX  5116, sfx_016,  8000, sfxName_016, 128,  2, 0,     0,  5116 @ 0x10 CRASH
	SFX  4364, sfx_017,  8000, sfxName_017, 128,  3, 0,     0,  4364 @ 0x11 THROW
	SFX  4419, sfx_018, 11025, sfxName_018, 128,  0, 0,     0,  4419 @ 0x12 WALK
	SFX  9478, sfx_019,  8000, sfxName_019, 128, 15, 0,     0,  9478 @ 0x13 PICKUP_CRYSTAL
	SFX 26811, sfx_020,  8000, sfxName_020, 128,  2, 1,     0, 26811 @ 0x14 HERE_WEGO
	SFX 13868, sfx_021,  8000, sfxName_021,  90,  2, 0,     0, 13868 @ 0x15 LETS_GO
	SFX  5117, sfx_022,  8000, sfxName_022, 100,  0, 0,     0,  5117 @ 0x16 BACK
	SFX  1386, sfx_023,  8000, sfxName_023, 200,  0, 0,     0,  1386 @ 0x17 CURSOR_E
	SFX  3093, sfx_024,  8000, sfxName_024,  50,  0, 0,     0,  3093 @ 0x18 CURSOR_M
	SFX  2066, sfx_025,  8000, sfxName_025, 128,  0, 0,     0,  2066 @ 0x19 CURSOR_S
	SFX  2519, sfx_026,  8000, sfxName_026,  60,  0, 0,     0,  2519 @ 0x1A ERASE
	SFX  1735, sfx_027,  8000, sfxName_027,  70,  0, 0,     0,  1735 @ 0x1B ERROR
	SFX     1, sfx_028,  8000, sfxName_028,  50,  0, 1,     0,     1 @ 0x1C EXIT_ED
	SFX     1, sfx_029,  8000, sfxName_029, 128,  0, 1,     0,     1 @ 0x1D FIELD
	SFX     1, sfx_030,  8000, sfxName_030, 128,  0, 1,     0,     1 @ 0x1E GRID
	SFX     1, sfx_031,  8000, sfxName_031, 128,  0, 1,     0,     1 @ 0x1F ITEM
	SFX     1, sfx_032,  8000, sfxName_032, 128,  0, 1,     0,     1 @ 0x20 SELECT_M
	SFX     1, sfx_033,  8000, sfxName_033, 128,  0, 1,     0,     1 @ 0x21 SELECT_S
	SFX     1, sfx_034,  8000, sfxName_034, 128,  0, 1,     0,     1 @ 0x22 STAMP
	SFX  5549, sfx_035,  8000, sfxName_035,  90, 15, 0,     0,  5549 @ 0x23 START
	SFX     1, sfx_036,  8000, sfxName_036, 128,  5, 1,     0,     1 @ 0x24 BEAM
	SFX  2239, sfx_037,  8000, sfxName_037, 128,  0, 0,     0,  2239 @ 0x25 BURN2
	SFX  3540, sfx_038,  8000, sfxName_038,  50,  1, 0,     0,  3540 @ 0x26 BLOCK
	SFX     1, sfx_039,  8000, sfxName_039, 128,  0, 1,     0,     1 @ 0x27 EXIT
	SFX  3887, sfx_040,  8000, sfxName_040, 128,  4, 0,     0,  3887 @ 0x28 HURT
	SFX  9607, sfx_041,  8000, sfxName_041,  50,  5, 0,     0,  9607 @ 0x29 ITEMLAST
	SFX  2132, sfx_042,  8000, sfxName_042, 128,  2, 0,     0,  2132 @ 0x2A POUND2
	SFX  1800, sfx_043,  8000, sfxName_043, 128,  0, 0,     0,  1800 @ 0x2B SCUFF
	SFX 13460, sfx_044,  8000, sfxName_044, 128, 14, 0,     0, 13460 @ 0x2C SHOCK
	SFX 18735, sfx_045,  8000, sfxName_045, 200, 15, 1,     0, 18735 @ 0x2D KEY_DOOR
	SFX  1349, sfx_046,  8000, sfxName_046, 128,  0, 0,     0,  1349 @ 0x2E SPIN
	SFX  5125, sfx_047,  8000, sfxName_047, 128,  0, 0,     0,  5125 @ 0x2F SPLAT
	SFX  3312, sfx_048,  8000, sfxName_048,  80,  4, 0,     0,  3312 @ 0x30 SQUEAK
	SFX     1, sfx_049,  8000, sfxName_049, 128, 14, 1,     0,     1 @ 0x31 UNLOCK
	SFX  5378, sfx_050,  8000, sfxName_050,  85,  2, 0,     0,  5378 @ 0x32 WIREJUMP
	SFX  1349, sfx_051,  8000, sfxName_051, 128,  0, 0,     0,  1349 @ 0x33 SPIN_1
	SFX 11968, sfx_052, 11025, sfxName_052, 130,  5, 0,     0, 11968 @ 0x34 ONE_UP
	SFX     1, sfx_053,  8000, sfxName_053, 128,  0, 1,     0,     1 @ 0x35 HELP
	SFX     1, sfx_054,  8000, sfxName_054, 128,  0, 1,     0,     1 @ 0x36 SILENCE
	SFX   298, sfx_055,  8000, sfxName_055, 128,  0, 0,     0,   298 @ 0x37 SKIDSHORT
	SFX 15039, sfx_056, 11025, sfxName_056, 110,  6, 0,     0, 15039 @ 0x38 SWITCH1
	SFX 13263, sfx_057, 11025, sfxName_057, 110,  6, 0,     0, 13263 @ 0x39 SWITCH2
	SFX 12191, sfx_058, 11025, sfxName_058, 110,  6, 0,     0, 12191 @ 0x3A SWITCH3
	SFX  4249, sfx_059,  8000, sfxName_059, 128,  0, 0,     0,  4249 @ 0x3B BOING
	SFX  7196, sfx_060,  8000, sfxName_060, 100,  3, 0,     0,  7196 @ 0x3C JUMP_6
	SFX  2405, sfx_061,  8000, sfxName_061, 100,  0, 0,     0,  2405 @ 0x3D ROPE_UP
	SFX  2905, sfx_062,  8000, sfxName_062, 128,  0, 0,     0,  2905 @ 0x3E ROPE_DOWN
	SFX     1, sfx_063,  8000, sfxName_063, 150,  3, 1,     0,     1 @ 0x3F DOOR
	SFX  1156, sfx_064,  8000, sfxName_064, 100,  0, 0,     0,  1155 @ 0x40 SCROLL
	SFX 12570, sfx_065,  8000, sfxName_065, 100,  0, 0,     0, 12570 @ 0x41 RETURN
	SFX     1, sfx_066,  8000, sfxName_066, 128,  0, 1,     0,     1 @ 0x42 BLANK
	SFX  3350, sfx_067,  8000, sfxName_067,  65,  0, 0,     0,  3350 @ 0x43 LOOK_UP
	SFX  5632, sfx_068,  8000, sfxName_068, 100,  4, 0,     0,  5632 @ 0x44 MM_DIE
	SFX  1346, sfx_069,  8000, sfxName_069, 128,  2, 0,     0,  1346 @ 0x45 MM_BOING
	SFX 14745, sfx_070,  8000, sfxName_070, 128,  3, 0,     0, 14745 @ 0x46 MM_PROTECT
	SFX  5773, sfx_071,  8000, sfxName_071, 128,  3, 0,     0,  5773 @ 0x47 CHEST_OPEN
	SFX  3686, sfx_072,  8000, sfxName_072, 128,  3, 0,     0,  3686 @ 0x48 CHEST_CLOSE
	SFX  8722, sfx_073,  8000, sfxName_073, 128,  2, 0,     0,  8722 @ 0x49 OOF
	SFX  7853, sfx_074,  8000, sfxName_074, 170, 15, 0,     0,  7853 @ 0x4A DK_HURT
	SFX 12190, sfx_075,  8000, sfxName_075, 110, 15, 0,     0, 12190 @ 0x4B DK_BELLOW
	SFX     1, sfx_076,  8000, sfxName_076, 200, 15, 1,     0,     1 @ 0x4C SLAM2
	SFX 10909, sfx_077,  8000, sfxName_077,  75,  7, 0,     0, 10909 @ 0x4D FRUIT_FALL
	SFX   552, sfx_078,  8000, sfxName_078, 128,  0, 0,     0,   552 @ 0x4E POINTER
	SFX  5590, sfx_079,  8000, sfxName_079, 160, 15, 0,     0,  5590 @ 0x4F CHOOSE
	SFX  3662, sfx_080,  8000, sfxName_080, 128,  0, 0,     0,  3662 @ 0x50 EMPTY
	SFX  5223, sfx_081,  8000, sfxName_081, 128,  5, 0,     0,  5223 @ 0x51 TOY1
	SFX  6279, sfx_082,  8000, sfxName_082, 128,  5, 0,     0,  6279 @ 0x52 TOYLAST
	SFX     1, sfx_083,  8000, sfxName_083, 128,  0, 1,     0,     1 @ 0x53 WARP_OUT
	SFX 21047, sfx_084,  8000, sfxName_084, 128,  0, 0,     0, 21047 @ 0x54 WARP_IN
	SFX  9985, sfx_085,  8000, sfxName_085, 128,  0, 0,     0,  9985 @ 0x55 SQUEEZE
	SFX 28365, sfx_086, 11025, sfxName_086, 175,  0, 0,     0, 28365 @ 0x56 GLASS
	SFX  2497, sfx_087,  8000, sfxName_087, 128,  0, 0,     0,  2497 @ 0x57 LIFT
	SFX  8719, sfx_088,  8000, sfxName_088,  40, 10, 0,     0,  8719 @ 0x58 MM_OH_NO
	SFX 13768, sfx_089,  8000, sfxName_089, 100,  0, 0,     0, 13768 @ 0x59 JUMP_7
	SFX 10820, sfx_090,  8000, sfxName_090,  90, 15, 0,     0, 10820 @ 0x5A LEVEL_START
	SFX  7988, sfx_091,  8000, sfxName_091, 128,  8, 0,     0,  7988 @ 0x5B ELEV_GO
	SFX  3054, sfx_092,  8000, sfxName_092, 160,  8, 0,     0,  3054 @ 0x5C ELEV_STOP
	SFX  9971, sfx_093,  8000, sfxName_093, 128,  8, 0,     0,  9971 @ 0x5D EGG_FALL
	SFX  4497, sfx_094,  8000, sfxName_094, 128,  0, 0,     0,  4497 @ 0x5E DK_EXIT1
	SFX 15776, sfx_095,  8000, sfxName_095, 160,  0, 1,     0, 15776 @ 0x5F DK_BLUBBER
	SFX  3269, sfx_096,  8000, sfxName_096, 100,  0, 1,     0,  3269 @ 0x60 MOVIE_02
	SFX 18080, sfx_097,  8000, sfxName_097,  60,  0, 1,     0, 18080 @ 0x61 MOVIE_03
	SFX 24696, sfx_098,  8000, sfxName_098,  60,  0, 1,     0, 24696 @ 0x62 MOVIE_04
	SFX 12075, sfx_099,  8000, sfxName_099,  60,  0, 1,     0, 12075 @ 0x63 MOVIE_05
	SFX 17401, sfx_100,  8000, sfxName_100,  60,  0, 1,     0, 17401 @ 0x64 MOVIE_06
	SFX  2340, sfx_101,  8000, sfxName_101,  65,  0, 0,     0,  2340 @ 0x65 KEY2
	SFX   362, sfx_102, 11025, sfxName_102,  50,  0, 0,     0,   362 @ 0x66 KEY3
	SFX   820, sfx_103,  8000, sfxName_103, 170,  1, 0,     0,   820 @ 0x67 GRAB_WIRE
	SFX   675, sfx_104,  8000, sfxName_104, 170,  1, 0,     0,   675 @ 0x68 GRAB_ROPE
	SFX  1806, sfx_105,  8000, sfxName_105, 170,  1, 0,     0,  1806 @ 0x69 GRAB_LADDER
	SFX  3352, sfx_106,  8000, sfxName_106, 128,  3, 0,     0,  3352 @ 0x6A CRUSH
	SFX 18139, sfx_107,  8000, sfxName_107,  25,  3, 1,     0, 18139 @ 0x6B SPITFIRE
	SFX  1817, sfx_108,  8000, sfxName_108,  30,  5, 0,     0,  1817 @ 0x6C NINJI
	SFX 11071, sfx_109,  8000, sfxName_109,  35,  0, 0,     0, 11071 @ 0x6D CRUMBLE
	SFX 24798, sfx_110,  8000, sfxName_110,  85,  4, 0,     0, 24798 @ 0x6E LAVA
	SFX  2658, sfx_111,  8000, sfxName_111,  85,  1, 0,     0,  2658 @ 0x6F BUBBLE
	SFX 19728, sfx_112,  8000, sfxName_112,  20,  6, 0,     0, 19728 @ 0x70 FOUNTAIN
	SFX     1, sfx_113,  8000, sfxName_113, 128,  2, 1,     0,     1 @ 0x71 OUCH
	SFX  5614, sfx_114,  8000, sfxName_114, 128,  1, 0,     0,  5614 @ 0x72 RESTART
	SFX  7431, sfx_115,  8000, sfxName_115,  35,  3, 0,     0,  7431 @ 0x73 METALROLL
	SFX  3959, sfx_116,  8000, sfxName_116,  85,  4, 0,     0,  3959 @ 0x74 SHWING
	SFX   858, sfx_117, 11025, sfxName_117, 100,  5, 0,     0,   858 @ 0x75 KICK
	SFX  9474, sfx_118,  8000, sfxName_118,  70,  4, 0,     0,  9474 @ 0x76 BRICKMAN
	SFX  8383, sfx_119,  8000, sfxName_119,  80,  4, 0,     0,  8383 @ 0x77 SPIT
	SFX  7424, sfx_120, 11025, sfxName_120, 110,  8, 0,     0,  7424 @ 0x78 POP
	SFX  5172, sfx_121,  8000, sfxName_121,  30,  5, 0,     0,  5172 @ 0x79 GROWL
	SFX  8037, sfx_122,  8000, sfxName_122,  60,  5, 0,     0,  8037 @ 0x7A GROWL2
	SFX  3013, sfx_123,  8000, sfxName_123,  25,  5, 0,     0,  3013 @ 0x7B GHOST
	SFX  2954, sfx_124,  8000, sfxName_124,  50,  5, 0,     0,  2954 @ 0x7C SHY_WAKE
	SFX  2445, sfx_125,  8000, sfxName_125,  50,  4, 0,     0,  2445 @ 0x7D SHY_RUN
	SFX  2207, sfx_126,  8000, sfxName_126,  45,  5, 0,     0,  2207 @ 0x7E BOMB_PEEP
	SFX  6363, sfx_127,  8000, sfxName_127,  45,  5, 0,     0,  6363 @ 0x7F BOMB_JUMP
	SFX  1032, sfx_128, 16000, sfxName_128,  50,  5, 0,     0,  1032 @ 0x80 BOMB_FLASH
	SFX  8125, sfx_129,  8000, sfxName_129, 128,  5, 0,     0,  8125 @ 0x81 BOMB_BLOW
	SFX  6361, sfx_130,  8000, sfxName_130, 110,  5, 0,     0,  6361 @ 0x82 VAPORIZE
	SFX  5815, sfx_131,  8000, sfxName_131, 127,  5, 0,     0,  5815 @ 0x83 BAT
	SFX  9349, sfx_132,  8000, sfxName_132, 127,  5, 0,     0,  9349 @ 0x84 CANNON
	SFX     1, sfx_133,  8000, sfxName_133, 127,  3, 1,     0,     1 @ 0x85 CROUCH
	SFX 18436, sfx_134,  8000, sfxName_134, 127,  0, 0,     0, 18436 @ 0x86 SCATTER
	SFX  2520, sfx_135,  8000, sfxName_135, 127,  2, 0,     0,  2520 @ 0x87 REACH
	SFX  8511, sfx_136,  8000, sfxName_136, 127,  0, 0,     0,  8511 @ 0x88 DK_HEAD
	SFX  9153, sfx_137,  8000, sfxName_137, 127,  0, 0,     0,  9153 @ 0x89 GOTCHA
	SFX  3201, sfx_138,  8000, sfxName_138, 100, 13, 0,     0,  3201 @ 0x8A TOAD_WALK
	SFX 14320, sfx_139,  8000, sfxName_139, 127, 13, 0,     0, 14320 @ 0x8B TOAD_TOSS
	SFX 25665, sfx_140, 11025, sfxName_140, 127,  0, 0,     0, 25665 @ 0x8C BOX_FALL
	SFX  5871, sfx_141, 11025, sfxName_141,  60,  4, 0,     0,  5871 @ 0x8D SPARKY_LOOP
	SFX  5253, sfx_142,  8000, sfxName_142, 127,  4, 0,     0,  5253 @ 0x8E DK_BLUB
	SFX  6802, sfx_143,  8000, sfxName_143, 150,  6, 0,     0,  6802 @ 0x8F YANK
	SFX  7034, sfx_144,  8000, sfxName_144,  50,  6, 0,     0,  7034 @ 0x90 SPIKE
	SFX 17807, sfx_145,  8000, sfxName_145, 127,  5, 0,     0, 17807 @ 0x91 BONE
	SFX  1357, sfx_146,  8000, sfxName_146, 127,  0, 0,     0,  1357 @ 0x92 MM_BOINGUP
	SFX  7792, sfx_147,  8000, sfxName_147,  16, 13, 0,     0,  7792 @ 0x93 LASER
	SFX  7499, sfx_148,  8000, sfxName_148, 127,  8, 0,     0,  7499 @ 0x94 DK_JUMP
	SFX  2554, sfx_149,  8000, sfxName_149, 120,  2, 0,     0,  2554 @ 0x95 JUMP_8
	SFX  5037, sfx_150,  8000, sfxName_150, 100,  5, 0,     0,  5037 @ 0x96 TRASHCAN
	SFX  9197, sfx_151,  8000, sfxName_151, 127,  8, 1,     0,  9197 @ 0x97 KEY_TOAD
	SFX 13034, sfx_152, 11025, sfxName_152, 140,  8, 0,     0, 13034 @ 0x98 SHATTER
	SFX  4272, sfx_153,  8000, sfxName_153, 127, 13, 0,     0,  4272 @ 0x99 TOAD_CARRY
	SFX  6430, sfx_154,  8000, sfxName_154, 127, 13, 0,     0,  6430 @ 0x9A TOAD_SET
	SFX  1211, sfx_155,  8000, sfxName_155,  80,  2, 0,     0,  1211 @ 0x9B JUMP_A
	SFX  1056, sfx_156,  8000, sfxName_156,  80,  2, 0,     0,  1056 @ 0x9C JUMP_B
	SFX  1174, sfx_157,  8000, sfxName_157,  80,  2, 0,     0,  1174 @ 0x9D JUMP_C
	SFX  1331, sfx_158,  8000, sfxName_158,  80,  2, 0,     0,  1331 @ 0x9E JUMP_D
	SFX  2080, sfx_159,  8000, sfxName_159, 127,  2, 0,     0,  2080 @ 0x9F SHUFFLE
	SFX 102115, sfx_160,  8000, sfxName_160,  60,  0, 1,     0, 102115 @ 0xA0 MOVIE_07
	SFX 32128, sfx_161,  8000, sfxName_161,  60,  0, 1,     0, 32128 @ 0xA1 MOVIE_01
	SFX 38457, sfx_162,  8000, sfxName_162, 127, 15, 0,     0, 38457 @ 0xA2 MINI_KEY
	SFX 10163, sfx_163,  8000, sfxName_163,  80,  0, 1,     0, 10163 @ 0xA3 MOVIE2_1
	SFX 20736, sfx_164,  8000, sfxName_164, 127,  0, 1,     0, 20736 @ 0xA4 MOVIE2_2
	SFX 14224, sfx_165,  8000, sfxName_165,  80,  0, 1,     0, 14224 @ 0xA5 MOVIE2_3
	SFX 19516, sfx_166,  8000, sfxName_166, 127,  0, 1,     0, 19516 @ 0xA6 MOVIE2_4
	SFX 13672, sfx_167,  8000, sfxName_167, 127,  0, 1,     0, 13672 @ 0xA7 MOVIE2_5
	SFX 19800, sfx_168,  8000, sfxName_168,  80,  0, 1,     0, 19800 @ 0xA8 MOVIE2_6
	SFX 11040, sfx_169,  8000, sfxName_169, 100,  0, 1,     0, 11040 @ 0xA9 MOVIE2_7
	SFX 21913, sfx_170,  8000, sfxName_170, 100,  0, 1,     0, 21913 @ 0xAA MOVIE2_8
	SFX  8889, sfx_171,  8000, sfxName_171, 127,  0, 0,     0,  8889 @ 0xAB BOSS_ARM
	SFX  6541, sfx_172,  8000, sfxName_172, 127,  0, 0,     0,  6541 @ 0xAC BOSS_ARM2
	SFX  8559, sfx_173,  8000, sfxName_173, 127,  0, 0,     0,  8559 @ 0xAD BOSS_ARM3
	SFX  5590, sfx_174,  8000, sfxName_174, 127,  0, 0,     0,  5590 @ 0xAE BOSS_ARM4
	SFX 12057, sfx_175,  8000, sfxName_175, 127,  0, 0,     0, 12057 @ 0xAF BOSS_ARM5
	SFX  7958, sfx_176, 11025, sfxName_176, 110,  0, 0,     0,  7958 @ 0xB0 BOSS_SWITCH
	SFX  4222, sfx_177,  8000, sfxName_177, 128,  0, 0,     0,  4222 @ 0xB1 CURSOR_WORLD
	SFX  1858, sfx_178,  8000, sfxName_178,  80,  0, 0,     0,  1858 @ 0xB2 CURSOR_UP_DN
	SFX  8000, sfx_179,  8000, sfxName_179, 127,  0, 0,     0,  8000 @ 0xB3 BOSS_DIE1
	SFX 25120, sfx_180,  8000, sfxName_180, 127,  0, 0, 12288, 24960 @ 0xB4 BOSS_DIE2
	SFX 16439, sfx_181,  8000, sfxName_181, 100,  2, 0,     0, 16439 @ 0xB5 BOSS_INTRO1
	SFX 31512, sfx_182,  8000, sfxName_182, 100,  2, 0,     0, 31512 @ 0xB6 BOSS_INTRO3
	SFX  6118, sfx_183,  8000, sfxName_183, 127,  0, 0,     0,  6118 @ 0xB7 PLUS_MAIN
	SFX  4134, sfx_184,  8000, sfxName_184,  90,  0, 0,     0,  4134 @ 0xB8 BARREL
	SFX  5752, sfx_185,  8000, sfxName_185, 160,  5, 0,     0,  5752 @ 0xB9 SPIKE_HIT
	SFX  6560, sfx_186,  8000, sfxName_186, 192,  0, 0,     0,  6560 @ 0xBA BIGBARREL_HIT
	SFX     1, sfx_187,  8000, sfxName_187,   0,  0, 1,     0,     1 @ 0xBB BIGBARREL_FALL
	SFX 36018, sfx_188,  8000, sfxName_188, 160,  0, 0,     0, 36018 @ 0xBC TOADS_JUMP
	SFX  7803, sfx_189,  8000, sfxName_189, 127, 10, 0,     0,  7803 @ 0xBD TOADS_GRAB
	SFX     1, sfx_190,  8000, sfxName_190,   0,  0, 1,     0,     1 @ 0xBE MOVIE3_01
	SFX 10563, sfx_191,  8000, sfxName_191, 127,  0, 1,     0, 10563 @ 0xBF MOVIE3_02
	SFX  6600, sfx_192,  8000, sfxName_192, 127,  0, 1,     0,  6600 @ 0xC0 MOVIE3_03
	SFX 16316, sfx_193,  8000, sfxName_193, 127,  0, 1,     0, 16316 @ 0xC1 MOVIE3_04
	SFX 16448, sfx_194,  8000, sfxName_194, 127,  0, 1,     0, 16448 @ 0xC2 MOVIE3_05
	SFX 14656, sfx_195,  8000, sfxName_195, 127,  0, 1,     0, 14656 @ 0xC3 MOVIE3_06
	SFX 20704, sfx_196,  8000, sfxName_196, 127,  0, 1,     0, 20704 @ 0xC4 MOVIE3_07
	SFX 19232, sfx_197,  8000, sfxName_197, 127,  0, 1,     0, 19232 @ 0xC5 MOVIE3_08
	SFX 18080, sfx_198,  8000, sfxName_198, 127,  0, 1,     0, 18080 @ 0xC6 MOVIE3_09
	SFX 16480, sfx_199,  8000, sfxName_199, 127,  0, 1,     0, 16480 @ 0xC7 MOVIE3_10
	SFX 18048, sfx_200,  8000, sfxName_200, 127,  0, 1,     0, 18048 @ 0xC8 MOVIE3_11
	SFX     1, sfx_201,  8000, sfxName_201, 127,  0, 1,     0,     1 @ 0xC9 MOVIE3_12
	SFX     1, sfx_202,  8000, sfxName_202, 127,  0, 1,     0,     1 @ 0xCA MOVIE3_13
	SFX 23184, sfx_203,  8000, sfxName_203, 160,  0, 1,     0, 23184 @ 0xCB MOVIE3_14
	SFX 19968, sfx_204,  8000, sfxName_204, 127,  0, 1,     0, 19968 @ 0xCC MOVIE4_01
	SFX 32300, sfx_205,  8000, sfxName_205, 127,  0, 1,     0, 32300 @ 0xCD MOVIE4_02
	SFX 17504, sfx_206,  8000, sfxName_206, 127,  0, 1,     0, 17504 @ 0xCE MOVIE4_03
	SFX 62059, sfx_207,  8000, sfxName_207, 127,  0, 1,     0, 62059 @ 0xCF MOVIE4_04
	SFX     1, sfx_208,  8000, sfxName_208, 127,  0, 1,     0,     1 @ 0xD0 MOVIE4_06
	SFX 19727, sfx_209,  8000, sfxName_209, 127,  0, 1,     0, 19727 @ 0xD1 MOVIE4_07
	SFX 20436, sfx_210,  8000, sfxName_210, 127,  0, 1,     0, 20436 @ 0xD2 MOVIE4_08
	SFX 17287, sfx_211,  8000, sfxName_211, 127,  0, 1,     0, 17287 @ 0xD3 MOVIE4_09
	SFX 20128, sfx_212,  8000, sfxName_212, 127,  0, 1,     0, 20128 @ 0xD4 MOVIE4_10
	SFX 16624, sfx_213,  8000, sfxName_213, 127,  0, 1,     0, 16624 @ 0xD5 MOVIE5_01
	SFX  3525, sfx_214,  8000, sfxName_214, 127,  0, 1,     0,  3525 @ 0xD6 MOVIE5_05
	SFX 19349, sfx_215,  8000, sfxName_215, 127,  0, 1,     0, 19349 @ 0xD7 MOVIE5_07
	SFX 21423, sfx_216,  8000, sfxName_216, 127,  0, 1,     0, 21423 @ 0xD8 MOVIE6_01
	SFX  5199, sfx_217,  8000, sfxName_217, 127,  0, 1,     0,  5199 @ 0xD9 MOVIE6_02
	SFX 24047, sfx_218,  8000, sfxName_218, 127,  0, 1,     0, 24047 @ 0xDA MOVIE6_03
	SFX 21242, sfx_219,  8000, sfxName_219, 127,  0, 1,     0, 21242 @ 0xDB MOVIE6_04
	SFX 22976, sfx_220,  8000, sfxName_220, 127,  0, 1,     0, 22976 @ 0xDC MOVIE6_05
	SFX 15013, sfx_221,  8000, sfxName_221, 127,  0, 1,     0, 15013 @ 0xDD MOVIE6_06
	SFX 22437, sfx_222,  8000, sfxName_222, 127,  0, 1,     0, 22437 @ 0xDE MOVIE6_07
	SFX 21818, sfx_223,  8000, sfxName_223, 127,  0, 1,     0, 21818 @ 0xDF MOVIE6_08
	SFX 22883, sfx_224,  8000, sfxName_224, 127,  0, 1,     0, 22883 @ 0xE0 MOVIE6_09
	SFX 25125, sfx_225,  8000, sfxName_225, 127,  0, 1,     0, 25125 @ 0xE1 MOVIE6_10
	SFX 17227, sfx_226,  8000, sfxName_226, 100,  0, 1,     0, 17227 @ 0xE2 MOVIE2_9
	SFX     1, sfx_227,  8000, sfxName_227,   0,  0, 1,     0,     1 @ 0xE3 MOVIE2_10
	SFX  3741, sfx_228,  8000, sfxName_228, 110,  0, 1,     0,  3741 @ 0xE4 MOVIE_08
	SFX 17891, sfx_229,  8000, sfxName_229, 128, 15, 0,     0, 17891 @ 0xE5 TITLE
	SFX  9295, sfx_230,  8000, sfxName_230, 115, 15, 0,     0,  9295 @ 0xE6 YOU_WON1
	SFX  8678, sfx_231,  8000, sfxName_231, 115, 15, 0,     0,  8678 @ 0xE7 YOU_WON2
	SFX 14249, sfx_232,  8000, sfxName_232, 115, 15, 0,     0, 14249 @ 0xE8 YOU_WON3
	SFX  4900, sfx_233,  8000, sfxName_233, 150,  0, 0,     0,  4900 @ 0xE9 STAR
	SFX  3204, sfx_234,  8000, sfxName_234,  40,  0, 0,     0,  3204 @ 0xEA DK_WALK
	SFX  3400, sfx_235,  8000, sfxName_235, 128,  0, 1,     0,  3400 @ 0xEB SCUFF2
	SFX 10927, sfx_236,  8000, sfxName_236, 128,  0, 0,     0, 10927 @ 0xEC WORLD_START
	SFX 11534, sfx_237,  8000, sfxName_237, 128,  2, 0,     0, 11534 @ 0xED MM_WAKEUP
	SFX 11381, sfx_238,  8000, sfxName_238, 140,  2, 0,     0, 11381 @ 0xEE MM_FREE
	SFX 12632, sfx_239,  8000, sfxName_239, 100,  2, 0,     0, 12632 @ 0xEF MM_MAMAMIAS
	SFX  3791, sfx_240,  8000, sfxName_240, 128,  2, 0,     0,  3791 @ 0xF0 SPIKE_VANISH
	SFX  6116, sfx_241,  8000, sfxName_241, 128,  2, 0,     0,  6116 @ 0xF1 SPIKE_APPEAR
	SFX 34015, sfx_242,  8000, sfxName_242, 200,  2, 0,     0, 34015 @ 0xF2 BOSS_DIE3
	SFX  1076, sfx_243,  8000, sfxName_243, 128,  2, 0,     0,  1076 @ 0xF3 BARREL_BOUNCE
	SFX   450, sfx_244,  8000, sfxName_244, 128,  2, 0,     0,   450 @ 0xF4 ROCK_BOUNCE
	SFX  2804, sfx_245, 11025, sfxName_245, 128,  2, 0,     0,  2804 @ 0xF5 MM_WALK
	SFX  4018, sfx_246,  8000, sfxName_246, 140,  2, 0,     0,  4018 @ 0xF6 DK_GRUNT
	SFX  3651, sfx_247,  8000, sfxName_247, 128,  2, 0,     0,  3651 @ 0xF7 RIBBON
	SFX 13290, sfx_248,  8000, sfxName_248,  40,  2, 0,     0, 13290 @ 0xF8 WON_TEXT
	SFX  6357, sfx_249,  8000, sfxName_249, 128,  2, 0,     0,  6357 @ 0xF9 DK_FALL
	SFX  7353, sfx_250, 11025, sfxName_250, 100,  5, 0,     0,  7353 @ 0xFA POINTS_OUT
	SFX  4773, sfx_251, 11025, sfxName_251, 100,  5, 0,     0,  4773 @ 0xFB POINTS_IN
	SFX 11424, sfx_252, 11025, sfxName_252,  50,  5, 0,     0, 11424 @ 0xFC POINTS_MERGE
	SFX 16797, sfx_253,  8000, sfxName_253, 128,  0, 0,     0, 16797 @ 0xFD SQUEEZE2

@ 8-bit signed PCM, in ROM order
sfx_000: .incbin "mvdk_sfx_pcm.bin", 0x000000, 3202 @ CLIMB
sfx_001: .incbin "mvdk_sfx_pcm.bin", 0x000C82, 1857 @ SKID
sfx_002: .incbin "mvdk_sfx_pcm.bin", 0x0013C3, 13439 @ POUND
sfx_003: .incbin "mvdk_sfx_pcm.bin", 0x004842, 3048 @ TUMBLE1
sfx_004: .incbin "mvdk_sfx_pcm.bin", 0x00542A, 11679 @ STUN
sfx_005: .incbin "mvdk_sfx_pcm.bin", 0x0081C9, 6403 @ BURN1
sfx_006: .incbin "mvdk_sfx_pcm.bin", 0x009ACC, 3765 @ JUMP_1
sfx_007: .incbin "mvdk_sfx_pcm.bin", 0x00A981, 1658 @ GRUNT2
sfx_008: .incbin "mvdk_sfx_pcm.bin", 0x00AFFB, 8571 @ JUMP_4
sfx_009: .incbin "mvdk_sfx_pcm.bin", 0x00D176, 6320 @ JUMP_3
sfx_010: .incbin "mvdk_sfx_pcm.bin", 0x00EA26, 3004 @ PICKUP
sfx_011: .incbin "mvdk_sfx_pcm.bin", 0x00F5E2, 8007 @ JUMP_5
sfx_012: .incbin "mvdk_sfx_pcm.bin", 0x011529, 385 @ COUNTER
sfx_013: .incbin "mvdk_sfx_pcm.bin", 0x0116AA, 5766 @ ITEM1
sfx_014: .incbin "mvdk_sfx_pcm.bin", 0x012D30, 3200 @ STEPS2
sfx_015: .incbin "mvdk_sfx_pcm.bin", 0x0139B0, 3808 @ KEY1
sfx_016: .incbin "mvdk_sfx_pcm.bin", 0x014890, 5116 @ CRASH
sfx_017: .incbin "mvdk_sfx_pcm.bin", 0x015C8C, 4364 @ THROW
sfx_018: .incbin "mvdk_sfx_pcm.bin", 0x016D98, 4419 @ WALK
sfx_019: .incbin "mvdk_sfx_pcm.bin", 0x017EDB, 9478 @ PICKUP_CRYSTAL
sfx_020: .incbin "mvdk_sfx_pcm.bin", 0x01A3E1, 26811 @ HERE_WEGO
sfx_021: .incbin "mvdk_sfx_pcm.bin", 0x020C9C, 13868 @ LETS_GO
sfx_022: .incbin "mvdk_sfx_pcm.bin", 0x0242C8, 5117 @ BACK
sfx_023: .incbin "mvdk_sfx_pcm.bin", 0x0256C5, 1386 @ CURSOR_E
sfx_024: .incbin "mvdk_sfx_pcm.bin", 0x025C2F, 3093 @ CURSOR_M
sfx_025: .incbin "mvdk_sfx_pcm.bin", 0x026844, 2066 @ CURSOR_S
sfx_026: .incbin "mvdk_sfx_pcm.bin", 0x027056, 2519 @ ERASE
sfx_027: .incbin "mvdk_sfx_pcm.bin", 0x027A2D, 1735 @ ERROR
sfx_028: .incbin "mvdk_sfx_pcm.bin", 0x0280F4, 1 @ EXIT_ED
sfx_029: .incbin "mvdk_sfx_pcm.bin", 0x0280F5, 1 @ FIELD
sfx_030: .incbin "mvdk_sfx_pcm.bin", 0x0280F6, 1 @ GRID
sfx_031: .incbin "mvdk_sfx_pcm.bin", 0x0280F7, 1 @ ITEM
sfx_032: .incbin "mvdk_sfx_pcm.bin", 0x0280F8, 1 @ SELECT_M
sfx_033: .incbin "mvdk_sfx_pcm.bin", 0x0280F9, 1 @ SELECT_S
sfx_034: .incbin "mvdk_sfx_pcm.bin", 0x0280FA, 1 @ STAMP
sfx_035: .incbin "mvdk_sfx_pcm.bin", 0x0280FB, 5549 @ START
sfx_036: .incbin "mvdk_sfx_pcm.bin", 0x0296A8, 1 @ BEAM
sfx_037: .incbin "mvdk_sfx_pcm.bin", 0x0296A9, 2239 @ BURN2
sfx_038: .incbin "mvdk_sfx_pcm.bin", 0x029F68, 3540 @ BLOCK
sfx_039: .incbin "mvdk_sfx_pcm.bin", 0x02AD3C, 1 @ EXIT
sfx_040: .incbin "mvdk_sfx_pcm.bin", 0x02AD3D, 3887 @ HURT
sfx_041: .incbin "mvdk_sfx_pcm.bin", 0x02BC6C, 9607 @ ITEMLAST
sfx_042: .incbin "mvdk_sfx_pcm.bin", 0x02E1F3, 2132 @ POUND2
sfx_043: .incbin "mvdk_sfx_pcm.bin", 0x02EA47, 1800 @ SCUFF
sfx_044: .incbin "mvdk_sfx_pcm.bin", 0x02F14F, 13460 @ SHOCK
sfx_045: .incbin "mvdk_sfx_pcm.bin", 0x0325E3, 18735 @ KEY_DOOR
sfx_046: .incbin "mvdk_sfx_pcm.bin", 0x036F12, 1349 @ SPIN
sfx_047: .incbin "mvdk_sfx_pcm.bin", 0x037457, 5125 @ SPLAT
sfx_048: .incbin "mvdk_sfx_pcm.bin", 0x03885C, 3312 @ SQUEAK
sfx_049: .incbin "mvdk_sfx_pcm.bin", 0x03954C, 1 @ UNLOCK
sfx_050: .incbin "mvdk_sfx_pcm.bin", 0x03954D, 5378 @ WIREJUMP
sfx_051: .incbin "mvdk_sfx_pcm.bin", 0x03AA4F, 1349 @ SPIN_1
sfx_052: .incbin "mvdk_sfx_pcm.bin", 0x03AF94, 11968 @ ONE_UP
sfx_053: .incbin "mvdk_sfx_pcm.bin", 0x03DE54, 1 @ HELP
sfx_054: .incbin "mvdk_sfx_pcm.bin", 0x03DE55, 1 @ SILENCE
sfx_055: .incbin "mvdk_sfx_pcm.bin", 0x03DE56, 298 @ SKIDSHORT
sfx_056: .incbin "mvdk_sfx_pcm.bin", 0x03DF80, 15039 @ SWITCH1
sfx_057: .incbin "mvdk_sfx_pcm.bin", 0x041A3F, 13263 @ SWITCH2
sfx_058: .incbin "mvdk_sfx_pcm.bin", 0x044E0E, 12191 @ SWITCH3
sfx_059: .incbin "mvdk_sfx_pcm.bin", 0x047DAD, 4249 @ BOING
sfx_060: .incbin "mvdk_sfx_pcm.bin", 0x048E46, 7196 @ JUMP_6
sfx_061: .incbin "mvdk_sfx_pcm.bin", 0x04AA62, 2405 @ ROPE_UP
sfx_062: .incbin "mvdk_sfx_pcm.bin", 0x04B3C7, 2905 @ ROPE_DOWN
sfx_063: .incbin "mvdk_sfx_pcm.bin", 0x04BF20, 1 @ DOOR
sfx_064: .incbin "mvdk_sfx_pcm.bin", 0x04BF21, 1156 @ SCROLL
sfx_065: .incbin "mvdk_sfx_pcm.bin", 0x04C3A5, 12570 @ RETURN
sfx_066: .incbin "mvdk_sfx_pcm.bin", 0x04F4BF, 1 @ BLANK
sfx_067: .incbin "mvdk_sfx_pcm.bin", 0x04F4C0, 3350 @ LOOK_UP
sfx_068: .incbin "mvdk_sfx_pcm.bin", 0x0501D6, 5632 @ MM_DIE
sfx_069: .incbin "mvdk_sfx_pcm.bin", 0x0517D6, 1346 @ MM_BOING
sfx_070: .incbin "mvdk_sfx_pcm.bin", 0x051D18, 14745 @ MM_PROTECT
sfx_071: .incbin "mvdk_sfx_pcm.bin", 0x0556B1, 5773 @ CHEST_OPEN
sfx_072: .incbin "mvdk_sfx_pcm.bin", 0x056D3E, 3686 @ CHEST_CLOSE
sfx_073: .incbin "mvdk_sfx_pcm.bin", 0x057BA4, 8722 @ OOF
sfx_074: .incbin "mvdk_sfx_pcm.bin", 0x059DB6, 7853 @ DK_HURT
sfx_075: .incbin "mvdk_sfx_pcm.bin", 0x05BC63, 12190 @ DK_BELLOW
sfx_076: .incbin "mvdk_sfx_pcm.bin", 0x05EC01, 1 @ SLAM2
sfx_077: .incbin "mvdk_sfx_pcm.bin", 0x05EC02, 10909 @ FRUIT_FALL
sfx_078: .incbin "mvdk_sfx_pcm.bin", 0x06169F, 552 @ POINTER
sfx_079: .incbin "mvdk_sfx_pcm.bin", 0x0618C7, 5590 @ CHOOSE
sfx_080: .incbin "mvdk_sfx_pcm.bin", 0x062E9D, 3662 @ EMPTY
sfx_081: .incbin "mvdk_sfx_pcm.bin", 0x063CEB, 5223 @ TOY1
sfx_082: .incbin "mvdk_sfx_pcm.bin", 0x065152, 6279 @ TOYLAST
sfx_083: .incbin "mvdk_sfx_pcm.bin", 0x0669D9, 1 @ WARP_OUT
sfx_084: .incbin "mvdk_sfx_pcm.bin", 0x0669DA, 21047 @ WARP_IN
sfx_085: .incbin "mvdk_sfx_pcm.bin", 0x06BC11, 9985 @ SQUEEZE
sfx_086: .incbin "mvdk_sfx_pcm.bin", 0x06E312, 28365 @ GLASS
sfx_087: .incbin "mvdk_sfx_pcm.bin", 0x0751DF, 2497 @ LIFT
sfx_088: .incbin "mvdk_sfx_pcm.bin", 0x075BA0, 8719 @ MM_OH_NO
sfx_089: .incbin "mvdk_sfx_pcm.bin", 0x077DAF, 13768 @ JUMP_7
sfx_090: .incbin "mvdk_sfx_pcm.bin", 0x07B377, 10820 @ LEVEL_START
sfx_091: .incbin "mvdk_sfx_pcm.bin", 0x07DDBB, 7988 @ ELEV_GO
sfx_092: .incbin "mvdk_sfx_pcm.bin", 0x07FCEF, 3054 @ ELEV_STOP
sfx_093: .incbin "mvdk_sfx_pcm.bin", 0x0808DD, 9971 @ EGG_FALL
sfx_094: .incbin "mvdk_sfx_pcm.bin", 0x082FD0, 4497 @ DK_EXIT1
sfx_095: .incbin "mvdk_sfx_pcm.bin", 0x084161, 15776 @ DK_BLUBBER
sfx_096: .incbin "mvdk_sfx_pcm.bin", 0x087F01, 3269 @ MOVIE_02
sfx_097: .incbin "mvdk_sfx_pcm.bin", 0x088BC6, 18080 @ MOVIE_03
sfx_098: .incbin "mvdk_sfx_pcm.bin", 0x08D266, 24696 @ MOVIE_04
sfx_099: .incbin "mvdk_sfx_pcm.bin", 0x0932DE, 12075 @ MOVIE_05
sfx_100: .incbin "mvdk_sfx_pcm.bin", 0x096209, 17401 @ MOVIE_06
sfx_101: .incbin "mvdk_sfx_pcm.bin", 0x09A602, 2340 @ KEY2
sfx_102: .incbin "mvdk_sfx_pcm.bin", 0x09AF26, 362 @ KEY3
sfx_103: .incbin "mvdk_sfx_pcm.bin", 0x09B090, 820 @ GRAB_WIRE
sfx_104: .incbin "mvdk_sfx_pcm.bin", 0x09B3C4, 675 @ GRAB_ROPE
sfx_105: .incbin "mvdk_sfx_pcm.bin", 0x09B667, 1806 @ GRAB_LADDER
sfx_106: .incbin "mvdk_sfx_pcm.bin", 0x09BD75, 3352 @ CRUSH
sfx_107: .incbin "mvdk_sfx_pcm.bin", 0x09CA8D, 18139 @ SPITFIRE
sfx_108: .incbin "mvdk_sfx_pcm.bin", 0x0A1168, 1817 @ NINJI
sfx_109: .incbin "mvdk_sfx_pcm.bin", 0x0A1881, 11071 @ CRUMBLE
sfx_110: .incbin "mvdk_sfx_pcm.bin", 0x0A43C0, 24798 @ LAVA
sfx_111: .incbin "mvdk_sfx_pcm.bin", 0x0AA49E, 2658 @ BUBBLE
sfx_112: .incbin "mvdk_sfx_pcm.bin", 0x0AAF00, 19728 @ FOUNTAIN
sfx_113: .incbin "mvdk_sfx_pcm.bin", 0x0AFC10, 1 @ OUCH
sfx_114: .incbin "mvdk_sfx_pcm.bin", 0x0AFC11, 5614 @ RESTART
sfx_115: .incbin "mvdk_sfx_pcm.bin", 0x0B11FF, 7431 @ METALROLL
sfx_116: .incbin "mvdk_sfx_pcm.bin", 0x0B2F06, 3959 @ SHWING
sfx_117: .incbin "mvdk_sfx_pcm.bin", 0x0B3E7D, 858 @ KICK
sfx_118: .incbin "mvdk_sfx_pcm.bin", 0x0B41D7, 9474 @ BRICKMAN
sfx_119: .incbin "mvdk_sfx_pcm.bin", 0x0B66D9, 8383 @ SPIT
sfx_120: .incbin "mvdk_sfx_pcm.bin", 0x0B8798, 7424 @ POP
sfx_121: .incbin "mvdk_sfx_pcm.bin", 0x0BA498, 5172 @ GROWL
sfx_122: .incbin "mvdk_sfx_pcm.bin", 0x0BB8CC, 8037 @ GROWL2
sfx_123: .incbin "mvdk_sfx_pcm.bin", 0x0BD831, 3013 @ GHOST
sfx_124: .incbin "mvdk_sfx_pcm.bin", 0x0BE3F6, 2954 @ SHY_WAKE
sfx_125: .incbin "mvdk_sfx_pcm.bin", 0x0BEF80, 2445 @ SHY_RUN
sfx_126: .incbin "mvdk_sfx_pcm.bin", 0x0BF90D, 2207 @ BOMB_PEEP
sfx_127: .incbin "mvdk_sfx_pcm.bin", 0x0C01AC, 6363 @ BOMB_JUMP
sfx_128: .incbin "mvdk_sfx_pcm.bin", 0x0C1A87, 1032 @ BOMB_FLASH
sfx_129: .incbin "mvdk_sfx_pcm.bin", 0x0C1E8F, 8125 @ BOMB_BLOW
sfx_130: .incbin "mvdk_sfx_pcm.bin", 0x0C3E4C, 6361 @ VAPORIZE
sfx_131: .incbin "mvdk_sfx_pcm.bin", 0x0C5725, 5815 @ BAT
sfx_132: .incbin "mvdk_sfx_pcm.bin", 0x0C6DDC, 9349 @ CANNON
sfx_133: .incbin "mvdk_sfx_pcm.bin", 0x0C9261, 1 @ CROUCH
sfx_134: .incbin "mvdk_sfx_pcm.bin", 0x0C9262, 18436 @ SCATTER
sfx_135: .incbin "mvdk_sfx_pcm.bin", 0x0CDA66, 2520 @ REACH
sfx_136: .incbin "mvdk_sfx_pcm.bin", 0x0CE43E, 8511 @ DK_HEAD
sfx_137: .incbin "mvdk_sfx_pcm.bin", 0x0D057D, 9153 @ GOTCHA
sfx_138: .incbin "mvdk_sfx_pcm.bin", 0x0D293E, 3201 @ TOAD_WALK
sfx_139: .incbin "mvdk_sfx_pcm.bin", 0x0D35BF, 14320 @ TOAD_TOSS
sfx_140: .incbin "mvdk_sfx_pcm.bin", 0x0D6DAF, 25665 @ BOX_FALL
sfx_141: .incbin "mvdk_sfx_pcm.bin", 0x0DD1F0, 5871 @ SPARKY_LOOP
sfx_142: .incbin "mvdk_sfx_pcm.bin", 0x0DE8DF, 5253 @ DK_BLUB
sfx_143: .incbin "mvdk_sfx_pcm.bin", 0x0DFD64, 6802 @ YANK
sfx_144: .incbin "mvdk_sfx_pcm.bin", 0x0E17F6, 7034 @ SPIKE
sfx_145: .incbin "mvdk_sfx_pcm.bin", 0x0E3370, 17807 @ BONE
sfx_146: .incbin "mvdk_sfx_pcm.bin", 0x0E78FF, 1357 @ MM_BOINGUP
sfx_147: .incbin "mvdk_sfx_pcm.bin", 0x0E7E4C, 7792 @ LASER
sfx_148: .incbin "mvdk_sfx_pcm.bin", 0x0E9CBC, 7499 @ DK_JUMP
sfx_149: .incbin "mvdk_sfx_pcm.bin", 0x0EBA07, 2554 @ JUMP_8
sfx_150: .incbin "mvdk_sfx_pcm.bin", 0x0EC401, 5037 @ TRASHCAN
sfx_151: .incbin "mvdk_sfx_pcm.bin", 0x0ED7AE, 9197 @ KEY_TOAD
sfx_152: .incbin "mvdk_sfx_pcm.bin", 0x0EFB9B, 13034 @ SHATTER
sfx_153: .incbin "mvdk_sfx_pcm.bin", 0x0F2E85, 4272 @ TOAD_CARRY
sfx_154: .incbin "mvdk_sfx_pcm.bin", 0x0F3F35, 6430 @ TOAD_SET
sfx_155: .incbin "mvdk_sfx_pcm.bin", 0x0F5853, 1211 @ JUMP_A
sfx_156: .incbin "mvdk_sfx_pcm.bin", 0x0F5D0E, 1056 @ JUMP_B
sfx_157: .incbin "mvdk_sfx_pcm.bin", 0x0F612E, 1174 @ JUMP_C
sfx_158: .incbin "mvdk_sfx_pcm.bin", 0x0F65C4, 1331 @ JUMP_D
sfx_159: .incbin "mvdk_sfx_pcm.bin", 0x0F6AF7, 2080 @ SHUFFLE
sfx_160: .incbin "mvdk_sfx_pcm.bin", 0x0F7317, 102115 @ MOVIE_07
sfx_161: .incbin "mvdk_sfx_pcm.bin", 0x1101FA, 32128 @ MOVIE_01
sfx_162: .incbin "mvdk_sfx_pcm.bin", 0x117F7A, 38457 @ MINI_KEY
sfx_163: .incbin "mvdk_sfx_pcm.bin", 0x1215B3, 10163 @ MOVIE2_1
sfx_164: .incbin "mvdk_sfx_pcm.bin", 0x123D66, 20736 @ MOVIE2_2
sfx_165: .incbin "mvdk_sfx_pcm.bin", 0x128E66, 14224 @ MOVIE2_3
sfx_166: .incbin "mvdk_sfx_pcm.bin", 0x12C5F6, 19516 @ MOVIE2_4
sfx_167: .incbin "mvdk_sfx_pcm.bin", 0x131232, 13672 @ MOVIE2_5
sfx_168: .incbin "mvdk_sfx_pcm.bin", 0x13479A, 19800 @ MOVIE2_6
sfx_169: .incbin "mvdk_sfx_pcm.bin", 0x1394F2, 11040 @ MOVIE2_7
sfx_170: .incbin "mvdk_sfx_pcm.bin", 0x13C012, 21913 @ MOVIE2_8
sfx_171: .incbin "mvdk_sfx_pcm.bin", 0x1415AB, 8889 @ BOSS_ARM
sfx_172: .incbin "mvdk_sfx_pcm.bin", 0x143864, 6541 @ BOSS_ARM2
sfx_173: .incbin "mvdk_sfx_pcm.bin", 0x1451F1, 8559 @ BOSS_ARM3
sfx_174: .incbin "mvdk_sfx_pcm.bin", 0x147360, 5590 @ BOSS_ARM4
sfx_175: .incbin "mvdk_sfx_pcm.bin", 0x148936, 12057 @ BOSS_ARM5
sfx_176: .incbin "mvdk_sfx_pcm.bin", 0x14B84F, 7958 @ BOSS_SWITCH
sfx_177: .incbin "mvdk_sfx_pcm.bin", 0x14D765, 4222 @ CURSOR_WORLD
sfx_178: .incbin "mvdk_sfx_pcm.bin", 0x14E7E3, 1858 @ CURSOR_UP_DN
sfx_179: .incbin "mvdk_sfx_pcm.bin", 0x14EF25, 8000 @ BOSS_DIE1
sfx_180: .incbin "mvdk_sfx_pcm.bin", 0x150E65, 25120 @ BOSS_DIE2
sfx_181: .incbin "mvdk_sfx_pcm.bin", 0x157085, 16439 @ BOSS_INTRO1
sfx_182: .incbin "mvdk_sfx_pcm.bin", 0x15B0BC, 31512 @ BOSS_INTRO3
sfx_183: .incbin "mvdk_sfx_pcm.bin", 0x162BD4, 6118 @ PLUS_MAIN
sfx_184: .incbin "mvdk_sfx_pcm.bin", 0x1643BA, 4134 @ BARREL
sfx_185: .incbin "mvdk_sfx_pcm.bin", 0x1653E0, 5752 @ SPIKE_HIT
sfx_186: .incbin "mvdk_sfx_pcm.bin", 0x166A58, 6560 @ BIGBARREL_HIT
sfx_187: .incbin "mvdk_sfx_pcm.bin", 0x1683F8, 1 @ BIGBARREL_FALL
sfx_188: .incbin "mvdk_sfx_pcm.bin", 0x1683F9, 36018 @ TOADS_JUMP
sfx_189: .incbin "mvdk_sfx_pcm.bin", 0x1710AB, 7803 @ TOADS_GRAB
sfx_190: .incbin "mvdk_sfx_pcm.bin", 0x172F26, 1 @ MOVIE3_01
sfx_191: .incbin "mvdk_sfx_pcm.bin", 0x172F27, 10563 @ MOVIE3_02
sfx_192: .incbin "mvdk_sfx_pcm.bin", 0x17586A, 6600 @ MOVIE3_03
sfx_193: .incbin "mvdk_sfx_pcm.bin", 0x177232, 16316 @ MOVIE3_04
sfx_194: .incbin "mvdk_sfx_pcm.bin", 0x17B1EE, 16448 @ MOVIE3_05
sfx_195: .incbin "mvdk_sfx_pcm.bin", 0x17F22E, 14656 @ MOVIE3_06
sfx_196: .incbin "mvdk_sfx_pcm.bin", 0x182B6E, 20704 @ MOVIE3_07
sfx_197: .incbin "mvdk_sfx_pcm.bin", 0x187C4E, 19232 @ MOVIE3_08
sfx_198: .incbin "mvdk_sfx_pcm.bin", 0x18C76E, 18080 @ MOVIE3_09
sfx_199: .incbin "mvdk_sfx_pcm.bin", 0x190E0E, 16480 @ MOVIE3_10
sfx_200: .incbin "mvdk_sfx_pcm.bin", 0x194E6E, 18048 @ MOVIE3_11
sfx_201: .incbin "mvdk_sfx_pcm.bin", 0x1994EE, 1 @ MOVIE3_12
sfx_202: .incbin "mvdk_sfx_pcm.bin", 0x1994EF, 1 @ MOVIE3_13
sfx_203: .incbin "mvdk_sfx_pcm.bin", 0x1994F0, 23184 @ MOVIE3_14
sfx_204: .incbin "mvdk_sfx_pcm.bin", 0x19EF80, 19968 @ MOVIE4_01
sfx_205: .incbin "mvdk_sfx_pcm.bin", 0x1A3D80, 32300 @ MOVIE4_02
sfx_206: .incbin "mvdk_sfx_pcm.bin", 0x1ABBAC, 17504 @ MOVIE4_03
sfx_207: .incbin "mvdk_sfx_pcm.bin", 0x1B000C, 62059 @ MOVIE4_04
sfx_208: .incbin "mvdk_sfx_pcm.bin", 0x1BF277, 1 @ MOVIE4_06
sfx_209: .incbin "mvdk_sfx_pcm.bin", 0x1BF278, 19727 @ MOVIE4_07
sfx_210: .incbin "mvdk_sfx_pcm.bin", 0x1C3F87, 20436 @ MOVIE4_08
sfx_211: .incbin "mvdk_sfx_pcm.bin", 0x1C8F5B, 17287 @ MOVIE4_09
sfx_212: .incbin "mvdk_sfx_pcm.bin", 0x1CD2E2, 20128 @ MOVIE4_10
sfx_213: .incbin "mvdk_sfx_pcm.bin", 0x1D2182, 16624 @ MOVIE5_01
sfx_214: .incbin "mvdk_sfx_pcm.bin", 0x1D6272, 3525 @ MOVIE5_05
sfx_215: .incbin "mvdk_sfx_pcm.bin", 0x1D7037, 19349 @ MOVIE5_07
sfx_216: .incbin "mvdk_sfx_pcm.bin", 0x1DBBCC, 21423 @ MOVIE6_01
sfx_217: .incbin "mvdk_sfx_pcm.bin", 0x1E0F7B, 5199 @ MOVIE6_02
sfx_218: .incbin "mvdk_sfx_pcm.bin", 0x1E23CA, 24047 @ MOVIE6_03
sfx_219: .incbin "mvdk_sfx_pcm.bin", 0x1E81B9, 21242 @ MOVIE6_04
sfx_220: .incbin "mvdk_sfx_pcm.bin", 0x1ED4B3, 22976 @ MOVIE6_05
sfx_221: .incbin "mvdk_sfx_pcm.bin", 0x1F2E73, 15013 @ MOVIE6_06
sfx_222: .incbin "mvdk_sfx_pcm.bin", 0x1F6918, 22437 @ MOVIE6_07
sfx_223: .incbin "mvdk_sfx_pcm.bin", 0x1FC0BD, 21818 @ MOVIE6_08
sfx_224: .incbin "mvdk_sfx_pcm.bin", 0x2015F7, 22883 @ MOVIE6_09
sfx_225: .incbin "mvdk_sfx_pcm.bin", 0x206F5A, 25125 @ MOVIE6_10
sfx_226: .incbin "mvdk_sfx_pcm.bin", 0x20D17F, 17227 @ MOVIE2_9
sfx_227: .incbin "mvdk_sfx_pcm.bin", 0x2114CA, 1 @ MOVIE2_10
sfx_228: .incbin "mvdk_sfx_pcm.bin", 0x2114CB, 3741 @ MOVIE_08
sfx_229: .incbin "mvdk_sfx_pcm.bin", 0x212368, 17891 @ TITLE
sfx_230: .incbin "mvdk_sfx_pcm.bin", 0x21694B, 9295 @ YOU_WON1
sfx_231: .incbin "mvdk_sfx_pcm.bin", 0x218D9A, 8678 @ YOU_WON2
sfx_232: .incbin "mvdk_sfx_pcm.bin", 0x21AF80, 14249 @ YOU_WON3
sfx_233: .incbin "mvdk_sfx_pcm.bin", 0x21E729, 4900 @ STAR
sfx_234: .incbin "mvdk_sfx_pcm.bin", 0x21FA4D, 3204 @ DK_WALK
sfx_235: .incbin "mvdk_sfx_pcm.bin", 0x2206D1, 3400 @ SCUFF2
sfx_236: .incbin "mvdk_sfx_pcm.bin", 0x221419, 10927 @ WORLD_START
sfx_237: .incbin "mvdk_sfx_pcm.bin", 0x223EC8, 11534 @ MM_WAKEUP
sfx_238: .incbin "mvdk_sfx_pcm.bin", 0x226BD6, 11381 @ MM_FREE
sfx_239: .incbin "mvdk_sfx_pcm.bin", 0x22984B, 12632 @ MM_MAMAMIAS
sfx_240: .incbin "mvdk_sfx_pcm.bin", 0x22C9A3, 3791 @ SPIKE_VANISH
sfx_241: .incbin "mvdk_sfx_pcm.bin", 0x22D872, 6116 @ SPIKE_APPEAR
sfx_242: .incbin "mvdk_sfx_pcm.bin", 0x22F056, 34015 @ BOSS_DIE3
sfx_243: .incbin "mvdk_sfx_pcm.bin", 0x237535, 1076 @ BARREL_BOUNCE
sfx_244: .incbin "mvdk_sfx_pcm.bin", 0x237969, 450 @ ROCK_BOUNCE
sfx_245: .incbin "mvdk_sfx_pcm.bin", 0x237B2B, 2804 @ MM_WALK
sfx_246: .incbin "mvdk_sfx_pcm.bin", 0x23861F, 4018 @ DK_GRUNT
sfx_247: .incbin "mvdk_sfx_pcm.bin", 0x2395D1, 3651 @ RIBBON
sfx_248: .incbin "mvdk_sfx_pcm.bin", 0x23A414, 13290 @ WON_TEXT
sfx_249: .incbin "mvdk_sfx_pcm.bin", 0x23D7FE, 6357 @ DK_FALL
sfx_250: .incbin "mvdk_sfx_pcm.bin", 0x23F0D3, 7353 @ POINTS_OUT
sfx_251: .incbin "mvdk_sfx_pcm.bin", 0x240D8C, 4773 @ POINTS_IN
sfx_252: .incbin "mvdk_sfx_pcm.bin", 0x242031, 11424 @ POINTS_MERGE
sfx_253: .incbin "mvdk_sfx_pcm.bin", 0x244CD1, 16797 @ SQUEEZE2
	.hword 0 @ padding

@ SFX names (in the game's rodata, referenced only by sfxTable)
	.section .snd_sfxnames, "a", %progbits
sfxName_253: .asciz "SQUEEZE2"
	.align 2, 0
sfxName_252: .asciz "POINTS_MERGE"
	.align 2, 0
sfxName_251: .asciz "POINTS_IN"
	.align 2, 0
sfxName_250: .asciz "POINTS_OUT"
	.align 2, 0
sfxName_249: .asciz "DK_FALL"
	.align 2, 0
sfxName_248: .asciz "WON_TEXT"
	.align 2, 0
sfxName_247: .asciz "RIBBON"
	.align 2, 0
sfxName_246: .asciz "DK_GRUNT"
	.align 2, 0
sfxName_245: .asciz "MM_WALK"
	.align 2, 0
sfxName_244: .asciz "ROCK_BOUNCE"
	.align 2, 0
sfxName_243: .asciz "BARREL_BOUNCE"
	.align 2, 0
sfxName_242: .asciz "BOSS_DIE3"
	.align 2, 0
sfxName_241: .asciz "SPIKE_APPEAR"
	.align 2, 0
sfxName_240: .asciz "SPIKE_VANISH"
	.align 2, 0
sfxName_239: .asciz "MM_MAMAMIAS"
	.align 2, 0
sfxName_238: .asciz "MM_FREE"
	.align 2, 0
sfxName_237: .asciz "MM_WAKEUP"
	.align 2, 0
sfxName_236: .asciz "WORLD_START"
	.align 2, 0
sfxName_235: .asciz "SCUFF2"
	.align 2, 0
sfxName_234: .asciz "DK_WALK"
	.align 2, 0
sfxName_233: .asciz "STAR"
	.align 2, 0
sfxName_232: .asciz "YOU_WON3"
	.align 2, 0
sfxName_231: .asciz "YOU_WON2"
	.align 2, 0
sfxName_230: .asciz "YOU_WON1"
	.align 2, 0
sfxName_229: .asciz "TITLE"
	.align 2, 0
sfxName_228: .asciz "MOVIE_08"
	.align 2, 0
sfxName_227: .asciz "MOVIE2_10"
	.align 2, 0
sfxName_226: .asciz "MOVIE2_9"
	.align 2, 0
sfxName_225: .asciz "MOVIE6_10"
	.align 2, 0
sfxName_224: .asciz "MOVIE6_09"
	.align 2, 0
sfxName_223: .asciz "MOVIE6_08"
	.align 2, 0
sfxName_222: .asciz "MOVIE6_07"
	.align 2, 0
sfxName_221: .asciz "MOVIE6_06"
	.align 2, 0
sfxName_220: .asciz "MOVIE6_05"
	.align 2, 0
sfxName_219: .asciz "MOVIE6_04"
	.align 2, 0
sfxName_218: .asciz "MOVIE6_03"
	.align 2, 0
sfxName_217: .asciz "MOVIE6_02"
	.align 2, 0
sfxName_216: .asciz "MOVIE6_01"
	.align 2, 0
sfxName_215: .asciz "MOVIE5_07"
	.align 2, 0
sfxName_214: .asciz "MOVIE5_05"
	.align 2, 0
sfxName_213: .asciz "MOVIE5_01"
	.align 2, 0
sfxName_212: .asciz "MOVIE4_10"
	.align 2, 0
sfxName_211: .asciz "MOVIE4_09"
	.align 2, 0
sfxName_210: .asciz "MOVIE4_08"
	.align 2, 0
sfxName_209: .asciz "MOVIE4_07"
	.align 2, 0
sfxName_208: .asciz "MOVIE4_06"
	.align 2, 0
sfxName_207: .asciz "MOVIE4_04"
	.align 2, 0
sfxName_206: .asciz "MOVIE4_03"
	.align 2, 0
sfxName_205: .asciz "MOVIE4_02"
	.align 2, 0
sfxName_204: .asciz "MOVIE4_01"
	.align 2, 0
sfxName_203: .asciz "MOVIE3_14"
	.align 2, 0
sfxName_202: .asciz "MOVIE3_13"
	.align 2, 0
sfxName_201: .asciz "MOVIE3_12"
	.align 2, 0
sfxName_200: .asciz "MOVIE3_11"
	.align 2, 0
sfxName_199: .asciz "MOVIE3_10"
	.align 2, 0
sfxName_198: .asciz "MOVIE3_09"
	.align 2, 0
sfxName_197: .asciz "MOVIE3_08"
	.align 2, 0
sfxName_196: .asciz "MOVIE3_07"
	.align 2, 0
sfxName_195: .asciz "MOVIE3_06"
	.align 2, 0
sfxName_194: .asciz "MOVIE3_05"
	.align 2, 0
sfxName_193: .asciz "MOVIE3_04"
	.align 2, 0
sfxName_192: .asciz "MOVIE3_03"
	.align 2, 0
sfxName_191: .asciz "MOVIE3_02"
	.align 2, 0
sfxName_190: .asciz "MOVIE3_01"
	.align 2, 0
sfxName_189: .asciz "TOADS_GRAB"
	.align 2, 0
sfxName_188: .asciz "TOADS_JUMP"
	.align 2, 0
sfxName_187: .asciz "BIGBARREL_FALL"
	.align 2, 0
sfxName_186: .asciz "BIGBARREL_HIT"
	.align 2, 0
sfxName_185: .asciz "SPIKE_HIT"
	.align 2, 0
sfxName_184: .asciz "BARREL"
	.align 2, 0
sfxName_183: .asciz "PLUS_MAIN"
	.align 2, 0
sfxName_182: .asciz "BOSS_INTRO3"
	.align 2, 0
sfxName_181: .asciz "BOSS_INTRO1"
	.align 2, 0
sfxName_180: .asciz "BOSS_DIE2"
	.align 2, 0
sfxName_179: .asciz "BOSS_DIE1"
	.align 2, 0
sfxName_178: .asciz "CURSOR_UP_DN"
	.align 2, 0
sfxName_177: .asciz "CURSOR_WORLD"
	.align 2, 0
sfxName_176: .asciz "BOSS_SWITCH"
	.align 2, 0
sfxName_175: .asciz "BOSS_ARM5"
	.align 2, 0
sfxName_174: .asciz "BOSS_ARM4"
	.align 2, 0
sfxName_173: .asciz "BOSS_ARM3"
	.align 2, 0
sfxName_172: .asciz "BOSS_ARM2"
	.align 2, 0
sfxName_171: .asciz "BOSS_ARM"
	.align 2, 0
sfxName_170: .asciz "MOVIE2_8"
	.align 2, 0
sfxName_169: .asciz "MOVIE2_7"
	.align 2, 0
sfxName_168: .asciz "MOVIE2_6"
	.align 2, 0
sfxName_167: .asciz "MOVIE2_5"
	.align 2, 0
sfxName_166: .asciz "MOVIE2_4"
	.align 2, 0
sfxName_165: .asciz "MOVIE2_3"
	.align 2, 0
sfxName_164: .asciz "MOVIE2_2"
	.align 2, 0
sfxName_163: .asciz "MOVIE2_1"
	.align 2, 0
sfxName_162: .asciz "MINI_KEY"
	.align 2, 0
sfxName_161: .asciz "MOVIE_01"
	.align 2, 0
sfxName_160: .asciz "MOVIE_07"
	.align 2, 0
sfxName_159: .asciz "SHUFFLE"
	.align 2, 0
sfxName_158: .asciz "JUMP_D"
	.align 2, 0
sfxName_157: .asciz "JUMP_C"
	.align 2, 0
sfxName_156: .asciz "JUMP_B"
	.align 2, 0
sfxName_155: .asciz "JUMP_A"
	.align 2, 0
sfxName_154: .asciz "TOAD_SET"
	.align 2, 0
sfxName_153: .asciz "TOAD_CARRY"
	.align 2, 0
sfxName_152: .asciz "SHATTER"
	.align 2, 0
sfxName_151: .asciz "KEY_TOAD"
	.align 2, 0
sfxName_150: .asciz "TRASHCAN"
	.align 2, 0
sfxName_149: .asciz "JUMP_8"
	.align 2, 0
sfxName_148: .asciz "DK_JUMP"
	.align 2, 0
sfxName_147: .asciz "LASER"
	.align 2, 0
sfxName_146: .asciz "MM_BOINGUP"
	.align 2, 0
sfxName_145: .asciz "BONE"
	.align 2, 0
sfxName_144: .asciz "SPIKE"
	.align 2, 0
sfxName_143: .asciz "YANK"
	.align 2, 0
sfxName_142: .asciz "DK_BLUB"
	.align 2, 0
sfxName_141: .asciz "SPARKY_LOOP"
	.align 2, 0
sfxName_140: .asciz "BOX_FALL"
	.align 2, 0
sfxName_139: .asciz "TOAD_TOSS"
	.align 2, 0
sfxName_138: .asciz "TOAD_WALK"
	.align 2, 0
sfxName_137: .asciz "GOTCHA"
	.align 2, 0
sfxName_136: .asciz "DK_HEAD"
	.align 2, 0
sfxName_135: .asciz "REACH"
	.align 2, 0
sfxName_134: .asciz "SCATTER"
	.align 2, 0
sfxName_133: .asciz "CROUCH"
	.align 2, 0
sfxName_132: .asciz "CANNON"
	.align 2, 0
sfxName_131: .asciz "BAT"
	.align 2, 0
sfxName_130: .asciz "VAPORIZE"
	.align 2, 0
sfxName_129: .asciz "BOMB_BLOW"
	.align 2, 0
sfxName_128: .asciz "BOMB_FLASH"
	.align 2, 0
sfxName_127: .asciz "BOMB_JUMP"
	.align 2, 0
sfxName_126: .asciz "BOMB_PEEP"
	.align 2, 0
sfxName_125: .asciz "SHY_RUN"
	.align 2, 0
sfxName_124: .asciz "SHY_WAKE"
	.align 2, 0
sfxName_123: .asciz "GHOST"
	.align 2, 0
sfxName_122: .asciz "GROWL2"
	.align 2, 0
sfxName_121: .asciz "GROWL"
	.align 2, 0
sfxName_120: .asciz "POP"
	.align 2, 0
sfxName_119: .asciz "SPIT"
	.align 2, 0
sfxName_118: .asciz "BRICKMAN"
	.align 2, 0
sfxName_117: .asciz "KICK"
	.align 2, 0
sfxName_116: .asciz "SHWING"
	.align 2, 0
sfxName_115: .asciz "METALROLL"
	.align 2, 0
sfxName_114: .asciz "RESTART"
	.align 2, 0
sfxName_113: .asciz "OUCH"
	.align 2, 0
sfxName_112: .asciz "FOUNTAIN"
	.align 2, 0
sfxName_111: .asciz "BUBBLE"
	.align 2, 0
sfxName_110: .asciz "LAVA"
	.align 2, 0
sfxName_109: .asciz "CRUMBLE"
	.align 2, 0
sfxName_108: .asciz "NINJI"
	.align 2, 0
sfxName_107: .asciz "SPITFIRE"
	.align 2, 0
sfxName_106: .asciz "CRUSH"
	.align 2, 0
sfxName_105: .asciz "GRAB_LADDER"
	.align 2, 0
sfxName_104: .asciz "GRAB_ROPE"
	.align 2, 0
sfxName_103: .asciz "GRAB_WIRE"
	.align 2, 0
sfxName_102: .asciz "KEY3"
	.align 2, 0
sfxName_101: .asciz "KEY2"
	.align 2, 0
sfxName_100: .asciz "MOVIE_06"
	.align 2, 0
sfxName_099: .asciz "MOVIE_05"
	.align 2, 0
sfxName_098: .asciz "MOVIE_04"
	.align 2, 0
sfxName_097: .asciz "MOVIE_03"
	.align 2, 0
sfxName_096: .asciz "MOVIE_02"
	.align 2, 0
sfxName_095: .asciz "DK_BLUBBER"
	.align 2, 0
sfxName_094: .asciz "DK_EXIT1"
	.align 2, 0
sfxName_093: .asciz "EGG_FALL"
	.align 2, 0
sfxName_092: .asciz "ELEV_STOP"
	.align 2, 0
sfxName_091: .asciz "ELEV_GO"
	.align 2, 0
sfxName_090: .asciz "LEVEL_START"
	.align 2, 0
sfxName_089: .asciz "JUMP_7"
	.align 2, 0
sfxName_088: .asciz "MM_OH_NO"
	.align 2, 0
sfxName_087: .asciz "LIFT"
	.align 2, 0
sfxName_086: .asciz "GLASS"
	.align 2, 0
sfxName_085: .asciz "SQUEEZE"
	.align 2, 0
sfxName_084: .asciz "WARP_IN"
	.align 2, 0
sfxName_083: .asciz "WARP_OUT"
	.align 2, 0
sfxName_082: .asciz "TOYLAST"
	.align 2, 0
sfxName_081: .asciz "TOY1"
	.align 2, 0
sfxName_080: .asciz "EMPTY"
	.align 2, 0
sfxName_079: .asciz "CHOOSE"
	.align 2, 0
sfxName_078: .asciz "POINTER"
	.align 2, 0
sfxName_077: .asciz "FRUIT_FALL"
	.align 2, 0
sfxName_076: .asciz "SLAM2"
	.align 2, 0
sfxName_075: .asciz "DK_BELLOW"
	.align 2, 0
sfxName_074: .asciz "DK_HURT"
	.align 2, 0
sfxName_073: .asciz "OOF"
	.align 2, 0
sfxName_072: .asciz "CHEST_CLOSE"
	.align 2, 0
sfxName_071: .asciz "CHEST_OPEN"
	.align 2, 0
sfxName_070: .asciz "MM_PROTECT"
	.align 2, 0
sfxName_069: .asciz "MM_BOING"
	.align 2, 0
sfxName_068: .asciz "MM_DIE"
	.align 2, 0
sfxName_067: .asciz "LOOK_UP"
	.align 2, 0
sfxName_066: .asciz "BLANK"
	.align 2, 0
sfxName_065: .asciz "RETURN"
	.align 2, 0
sfxName_064: .asciz "SCROLL"
	.align 2, 0
sfxName_063: .asciz "DOOR"
	.align 2, 0
sfxName_062: .asciz "ROPE_DOWN"
	.align 2, 0
sfxName_061: .asciz "ROPE_UP"
	.align 2, 0
sfxName_060: .asciz "JUMP_6"
	.align 2, 0
sfxName_059: .asciz "BOING"
	.align 2, 0
sfxName_058: .asciz "SWITCH3"
	.align 2, 0
sfxName_057: .asciz "SWITCH2"
	.align 2, 0
sfxName_056: .asciz "SWITCH1"
	.align 2, 0
sfxName_055: .asciz "SKIDSHORT"
	.align 2, 0
sfxName_054: .asciz "SILENCE"
	.align 2, 0
sfxName_053: .asciz "HELP"
	.align 2, 0
sfxName_052: .asciz "ONE_UP"
	.align 2, 0
sfxName_051: .asciz "SPIN_1"
	.align 2, 0
sfxName_050: .asciz "WIREJUMP"
	.align 2, 0
sfxName_049: .asciz "UNLOCK"
	.align 2, 0
sfxName_048: .asciz "SQUEAK"
	.align 2, 0
sfxName_047: .asciz "SPLAT"
	.align 2, 0
sfxName_046: .asciz "SPIN"
	.align 2, 0
sfxName_045: .asciz "KEY_DOOR"
	.align 2, 0
sfxName_044: .asciz "SHOCK"
	.align 2, 0
sfxName_043: .asciz "SCUFF"
	.align 2, 0
sfxName_042: .asciz "POUND2"
	.align 2, 0
sfxName_041: .asciz "ITEMLAST"
	.align 2, 0
sfxName_040: .asciz "HURT"
	.align 2, 0
sfxName_039: .asciz "EXIT"
	.align 2, 0
sfxName_038: .asciz "BLOCK"
	.align 2, 0
sfxName_037: .asciz "BURN2"
	.align 2, 0
sfxName_036: .asciz "BEAM"
	.align 2, 0
sfxName_035: .asciz "START"
	.align 2, 0
sfxName_034: .asciz "STAMP"
	.align 2, 0
sfxName_033: .asciz "SELECT_S"
	.align 2, 0
sfxName_032: .asciz "SELECT_M"
	.align 2, 0
sfxName_031: .asciz "ITEM"
	.align 2, 0
sfxName_030: .asciz "GRID"
	.align 2, 0
sfxName_029: .asciz "FIELD"
	.align 2, 0
sfxName_028: .asciz "EXIT_ED"
	.align 2, 0
sfxName_027: .asciz "ERROR"
	.align 2, 0
sfxName_026: .asciz "ERASE"
	.align 2, 0
sfxName_025: .asciz "CURSOR_S"
	.align 2, 0
sfxName_024: .asciz "CURSOR_M"
	.align 2, 0
sfxName_023: .asciz "CURSOR_E"
	.align 2, 0
sfxName_022: .asciz "BACK"
	.align 2, 0
sfxName_021: .asciz "LETS_GO"
	.align 2, 0
sfxName_020: .asciz "HERE_WEGO"
	.align 2, 0
sfxName_019: .asciz "PICKUP_CRYSTAL"
	.align 2, 0
sfxName_018: .asciz "WALK"
	.align 2, 0
sfxName_017: .asciz "THROW"
	.align 2, 0
sfxName_016: .asciz "CRASH"
	.align 2, 0
sfxName_015: .asciz "KEY1"
	.align 2, 0
sfxName_014: .asciz "STEPS2"
	.align 2, 0
sfxName_013: .asciz "ITEM1"
	.align 2, 0
sfxName_012: .asciz "COUNTER"
	.align 2, 0
sfxName_011: .asciz "JUMP_5"
	.align 2, 0
sfxName_010: .asciz "PICKUP"
	.align 2, 0
sfxName_009: .asciz "JUMP_3"
	.align 2, 0
sfxName_008: .asciz "JUMP_4"
	.align 2, 0
sfxName_007: .asciz "GRUNT2"
	.align 2, 0
sfxName_006: .asciz "JUMP_1"
	.align 2, 0
sfxName_005: .asciz "BURN1"
	.align 2, 0
sfxName_004: .asciz "STUN"
	.align 2, 0
sfxName_003: .asciz "TUMBLE1"
	.align 2, 0
sfxName_002: .asciz "POUND"
	.align 2, 0
sfxName_001: .asciz "SKID"
	.align 2, 0
sfxName_000: .asciz "CLIMB"
	.align 2, 0
