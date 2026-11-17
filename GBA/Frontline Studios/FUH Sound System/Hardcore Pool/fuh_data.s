@ ==================================================================================================
@ fuh_data.s -- FUH Sound System data, Hardcore Pool (E) (M4)
@
@   .rodata.fuh_music  ROM 0832A954-0839D214  music module (4 channels, 216 orders, 186 patterns,
@                                             52 instruments; PCM in fuh_music_pcm.bin)
@   .rodata.fuh_sfx    ROM 0839D868-083E05C8  SFX bank (a module with no orders: 18 samples;
@                                             PCM in fuh_sfx_pcm.bin)
@
@ Pattern rows: one `ev` per channel, separated by `;` (GAS statement separator).
@   ev n=<period>, i=<instrument>, v=<volume>, fx=<effect>, p=<parameter>   (all optional)
@   n is an XM linear period written as a note symbol from fuh_data.inc: C_4 = 4608 (8363 Hz),
@   C_4+11 = period 4619 (11/64 semitone lower). i = 0 means "previous instrument".
@   An effect-4 note without v= is a tone-portamento target (the player does not retrigger it).
@ ==================================================================================================

	.include "fuh_data.inc"

	.section .rodata.fuh_music,"a",%progbits
	.balign 4

	.global hp_module
hp_module:				@ 0832A954
	.word 4			@ +00 channels
	.word 216			@ +04 orders
	.word 59			@ +08 (never read)
	.word 6			@ +0C speed (frames per row)
	.word hp_instruments	@ +10 instrument table
	.word hp_orders		@ +14 order table
hp_orders:				@ 0832A96C
	.word hp_pat001, hp_pat002, hp_pat000, hp_pat003	@ 0
	.word hp_pat004, hp_pat007, hp_pat007, hp_pat006	@ 4
	.word hp_pat005, hp_pat005, hp_pat005, hp_pat008	@ 8
	.word hp_pat009, hp_pat010, hp_pat009, hp_pat011	@ 12
	.word hp_pat012, hp_pat013, hp_pat012, hp_pat014	@ 16
	.word hp_pat015, hp_pat016, hp_pat015, hp_pat017	@ 20
	.word hp_pat018, hp_pat019, hp_pat020, hp_pat021	@ 24
	.word hp_pat018, hp_pat022, hp_pat022, hp_pat023	@ 28
	.word hp_pat024, hp_pat025, hp_pat026, hp_pat027	@ 32
	.word hp_pat028, hp_pat029, hp_pat030, hp_pat031	@ 36
	.word hp_pat032, hp_pat029, hp_pat030, hp_pat038	@ 40
	.word hp_pat034, hp_pat035, hp_pat036, hp_pat033	@ 44
	.word hp_pat037, hp_pat040, hp_pat039, hp_pat041	@ 48
	.word hp_pat042, hp_pat018, hp_pat043, hp_pat045	@ 52
	.word hp_pat044, hp_pat046, hp_pat047, hp_pat048	@ 56
	.word hp_pat049, hp_pat050, hp_pat051, hp_pat052	@ 60
	.word hp_pat018, hp_pat053, hp_pat054, hp_pat055	@ 64
	.word hp_pat056, hp_pat057, hp_pat058, hp_pat059	@ 68
	.word hp_pat060, hp_pat055, hp_pat056, hp_pat061	@ 72
	.word hp_pat062, hp_pat063, hp_pat064, hp_pat065	@ 76
	.word hp_pat066, hp_pat067, hp_pat068, hp_pat070	@ 80
	.word hp_pat071, hp_pat018, hp_pat072, hp_pat069	@ 84
	.word hp_pat073, hp_pat074, hp_pat075, hp_pat076	@ 88
	.word hp_pat077, hp_pat078, hp_pat075, hp_pat076	@ 92
	.word hp_pat079, hp_pat080, hp_pat018, hp_pat081	@ 96
	.word hp_pat082, hp_pat083, hp_pat084, hp_pat085	@ 100
	.word hp_pat086, hp_pat087, hp_pat088, hp_pat089	@ 104
	.word hp_pat090, hp_pat091, hp_pat092, hp_pat093	@ 108
	.word hp_pat093, hp_pat095, hp_pat096, hp_pat093	@ 112
	.word hp_pat094, hp_pat097, hp_pat098, hp_pat018	@ 116
	.word hp_pat099, hp_pat100, hp_pat101, hp_pat102	@ 120
	.word hp_pat103, hp_pat104, hp_pat105, hp_pat106	@ 124
	.word hp_pat107, hp_pat108, hp_pat109, hp_pat110	@ 128
	.word hp_pat111, hp_pat112, hp_pat113, hp_pat114	@ 132
	.word hp_pat115, hp_pat116, hp_pat117, hp_pat118	@ 136
	.word hp_pat119, hp_pat120, hp_pat121, hp_pat122	@ 140
	.word hp_pat122, hp_pat122, hp_pat123, hp_pat124	@ 144
	.word hp_pat125, hp_pat126, hp_pat127, hp_pat124	@ 148
	.word hp_pat125, hp_pat126, hp_pat128, hp_pat018	@ 152
	.word hp_pat129, hp_pat130, hp_pat131, hp_pat132	@ 156
	.word hp_pat133, hp_pat134, hp_pat133, hp_pat135	@ 160
	.word hp_pat136, hp_pat137, hp_pat138, hp_pat139	@ 164
	.word hp_pat143, hp_pat144, hp_pat140, hp_pat141	@ 168
	.word hp_pat142, hp_pat145, hp_pat146, hp_pat147	@ 172
	.word hp_pat018, hp_pat148, hp_pat149, hp_pat150	@ 176
	.word hp_pat151, hp_pat152, hp_pat153, hp_pat154	@ 180
	.word hp_pat155, hp_pat156, hp_pat157, hp_pat158	@ 184
	.word hp_pat159, hp_pat160, hp_pat161, hp_pat162	@ 188
	.word hp_pat163, hp_pat164, hp_pat018, hp_pat165	@ 192
	.word hp_pat166, hp_pat167, hp_pat168, hp_pat169	@ 196
	.word hp_pat170, hp_pat171, hp_pat172, hp_pat173	@ 200
	.word hp_pat174, hp_pat175, hp_pat176, hp_pat177	@ 204
	.word hp_pat178, hp_pat179, hp_pat180, hp_pat181	@ 208
	.word hp_pat182, hp_pat183, hp_pat184, hp_pat185	@ 212
hp_instruments:				@ 0832ACCC
	.word 0	@ 0
	.word hp_ins01	@ 1
	.word hp_ins02	@ 2
	.word hp_ins03	@ 3
	.word hp_ins04	@ 4
	.word hp_ins05	@ 5
	.word hp_ins06	@ 6
	.word hp_ins07	@ 7
	.word hp_ins08	@ 8
	.word hp_ins09	@ 9
	.word hp_ins10	@ 10
	.word hp_ins11	@ 11
	.word hp_ins12	@ 12
	.word hp_ins13	@ 13
	.word hp_ins14	@ 14
	.word hp_ins15	@ 15
	.word hp_ins16	@ 16
	.word hp_ins17	@ 17
	.word hp_ins18	@ 18
	.word hp_ins19	@ 19
	.word hp_ins20	@ 20
	.word hp_ins21	@ 21
	.word hp_ins22	@ 22
	.word hp_ins23	@ 23
	.word hp_ins24	@ 24
	.word hp_ins25	@ 25
	.word hp_ins26	@ 26
	.word hp_ins27	@ 27
	.word hp_ins28	@ 28
	.word hp_ins29	@ 29
	.word hp_ins30	@ 30
	.word hp_ins31	@ 31
	.word hp_ins32	@ 32
	.word hp_ins33	@ 33
	.word hp_ins34	@ 34
	.word hp_ins35	@ 35
	.word hp_ins36	@ 36
	.word hp_ins37	@ 37
	.word hp_ins38	@ 38
	.word hp_ins39	@ 39
	.word hp_ins40	@ 40
	.word hp_ins41	@ 41
	.word hp_ins42	@ 42
	.word hp_ins43	@ 43
	.word hp_ins44	@ 44
	.word hp_ins45	@ 45
	.word hp_ins46	@ 46
	.word hp_ins47	@ 47
	.word hp_ins48	@ 48
	.word hp_ins49	@ 49
	.word hp_ins50	@ 50
	.word hp_ins51	@ 51
	.word hp_ins52	@ 52
hp_ins01:				@ 0832ADA0
	INSTR 1555, 6815, 64, hp_pcm01	@ loop 1555-6815
hp_ins02:				@ 0832ADB0
	INSTR 0, 0, 64, hp_pcm02	@ one-shot
hp_ins03:				@ 0832ADC0
	INSTR 0, 0, 64, hp_pcm03	@ one-shot
hp_ins04:				@ 0832ADD0
	INSTR 0, 200, 64, hp_pcm04	@ loop 0-200
hp_ins05:				@ 0832ADE0
	INSTR 0, 0, 64, hp_pcm05	@ one-shot
hp_ins06:				@ 0832ADF0
	INSTR 0, 28032, 32, hp_pcm06	@ loop 0-28032
hp_ins07:				@ 0832AE00
	INSTR 16059, 25289, 64, hp_pcm07	@ loop 16059-25289
hp_ins08:				@ 0832AE10
	INSTR 151, 317, 64, hp_pcm08	@ loop 151-317
hp_ins09:				@ 0832AE20
	INSTR 0, 0, 64, hp_pcm09	@ one-shot
hp_ins10:				@ 0832AE30
	INSTR 0, 0, 64, hp_pcm10	@ one-shot
hp_ins11:				@ 0832AE40
	INSTR 0, 0, 64, hp_pcm11	@ one-shot
hp_ins12:				@ 0832AE50
	INSTR 0, 0, 64, hp_pcm12	@ one-shot
hp_ins13:				@ 0832AE60
	INSTR 0, 0, 64, hp_pcm13	@ one-shot
hp_ins14:				@ 0832AE70
	INSTR 0, 0, 64, hp_pcm14	@ one-shot
hp_ins15:				@ 0832AE80
	INSTR 0, 0, 64, hp_pcm15	@ one-shot
hp_ins16:				@ 0832AE90
	INSTR 0, 0, 64, hp_pcm16	@ one-shot
hp_ins17:				@ 0832AEA0
	INSTR 0, 0, 64, hp_pcm17	@ one-shot
hp_ins18:				@ 0832AEB0
	INSTR 0, 0, 64, hp_pcm18	@ one-shot
hp_ins19:				@ 0832AEC0
	INSTR 0, 0, 64, hp_pcm19	@ one-shot
hp_ins20:				@ 0832AED0
	INSTR 0, 0, 64, hp_pcm20	@ one-shot
hp_ins21:				@ 0832AEE0
	INSTR 0, 0, 59, hp_pcm21	@ one-shot
hp_ins22:				@ 0832AEF0
	INSTR 0, 0, 60, hp_pcm22	@ one-shot
hp_ins23:				@ 0832AF00
	INSTR 56, 8894, 43, hp_pcm23	@ loop 56-8894
hp_ins24:				@ 0832AF10
	INSTR 870, 9752, 50, hp_pcm24	@ loop 870-9752
hp_ins25:				@ 0832AF20
	INSTR 0, 0, 64, hp_pcm25	@ one-shot
hp_ins26:				@ 0832AF30
	INSTR 0, 0, 64, hp_pcm26	@ one-shot
hp_ins27:				@ 0832AF40
	INSTR 0, 0, 64, hp_pcm27	@ one-shot
hp_ins28:				@ 0832AF50
	INSTR 0, 0, 64, hp_pcm28	@ one-shot
hp_ins29:				@ 0832AF60
	INSTR 0, 0, 64, hp_pcm29	@ one-shot
hp_ins30:				@ 0832AF70
	INSTR 0, 0, 64, hp_pcm30	@ one-shot
hp_ins31:				@ 0832AF80
	INSTR 0, 0, 64, hp_pcm31	@ one-shot
hp_ins32:				@ 0832AF90
	INSTR 0, 0, 64, hp_pcm32	@ one-shot
hp_ins33:				@ 0832AFA0
	INSTR 0, 0, 64, hp_pcm33	@ one-shot
hp_ins34:				@ 0832AFB0
	INSTR 16, 15048, 64, hp_pcm34	@ loop 16-15048
hp_ins35:				@ 0832AFC0
	INSTR 0, 0, 64, hp_pcm35	@ one-shot
hp_ins36:				@ 0832AFD0
	INSTR 0, 0, 64, hp_pcm36	@ one-shot
hp_ins37:				@ 0832AFE0
	INSTR 0, 0, 64, hp_pcm37	@ one-shot
hp_ins38:				@ 0832AFF0
	INSTR 0, 0, 64, hp_pcm38	@ one-shot
hp_ins39:				@ 0832B000
	INSTR 19668, 30208, 64, hp_pcm39	@ loop 19668-30208
hp_ins40:				@ 0832B010
	INSTR 0, 0, 37, hp_pcm40	@ one-shot
hp_ins41:				@ 0832B020
	INSTR 0, 0, 64, hp_pcm41	@ one-shot
hp_ins42:				@ 0832B030
	INSTR 0, 0, 40, hp_pcm42	@ one-shot
hp_ins43:				@ 0832B040
	INSTR 0, 0, 64, hp_pcm43	@ one-shot
hp_ins44:				@ 0832B050
	INSTR 32221, 45750, 41, hp_pcm44	@ loop 32221-45750
hp_ins45:				@ 0832B060
	INSTR 0, 0, 64, hp_pcm45	@ one-shot
hp_ins46:				@ 0832B070
	INSTR 0, 0, 64, hp_pcm46	@ one-shot
hp_ins47:				@ 0832B080
	INSTR 0, 0, 64, hp_pcm47	@ one-shot
hp_ins48:				@ 0832B090
	INSTR 0, 0, 64, hp_pcm48	@ one-shot
hp_ins49:				@ 0832B0A0
	INSTR 0, 0, 64, hp_pcm49	@ one-shot
hp_ins50:				@ 0832B0B0
	INSTR 0, 0, 64, hp_pcm50	@ one-shot
hp_ins51:				@ 0832B0C0
	INSTR 689, 2664, 48, hp_pcm51	@ loop 689-2664
hp_ins52:				@ 0832B0D0
	INSTR 0, 0, 64, hp_pcm52	@ one-shot
hp_pat000:				@ 0832B0E0
	.word 64, hp_pat000_rows
hp_pat001:				@ 0832B0E8
	.word 64, hp_pat001_rows
hp_pat002:				@ 0832B0F0
	.word 64, hp_pat002_rows
hp_pat003:				@ 0832B0F8
	.word 64, hp_pat003_rows
hp_pat004:				@ 0832B100
	.word 64, hp_pat004_rows
hp_pat005:				@ 0832B108
	.word 64, hp_pat005_rows
hp_pat006:				@ 0832B110
	.word 64, hp_pat006_rows
hp_pat007:				@ 0832B118
	.word 64, hp_pat007_rows
hp_pat008:				@ 0832B120
	.word 64, hp_pat008_rows
hp_pat009:				@ 0832B128
	.word 64, hp_pat009_rows
hp_pat010:				@ 0832B130
	.word 64, hp_pat010_rows
hp_pat011:				@ 0832B138
	.word 64, hp_pat011_rows
hp_pat012:				@ 0832B140
	.word 64, hp_pat012_rows
hp_pat013:				@ 0832B148
	.word 64, hp_pat013_rows
hp_pat014:				@ 0832B150
	.word 64, hp_pat014_rows
hp_pat015:				@ 0832B158
	.word 64, hp_pat015_rows
hp_pat016:				@ 0832B160
	.word 64, hp_pat016_rows
hp_pat017:				@ 0832B168
	.word 64, hp_pat017_rows
hp_pat018:				@ 0832B170
	.word 64, hp_pat018_rows
hp_pat019:				@ 0832B178
	.word 64, hp_pat019_rows
hp_pat020:				@ 0832B180
	.word 64, hp_pat020_rows
hp_pat021:				@ 0832B188
	.word 64, hp_pat021_rows
hp_pat022:				@ 0832B190
	.word 64, hp_pat022_rows
hp_pat023:				@ 0832B198
	.word 64, hp_pat023_rows
hp_pat024:				@ 0832B1A0
	.word 64, hp_pat024_rows
hp_pat025:				@ 0832B1A8
	.word 64, hp_pat025_rows
hp_pat026:				@ 0832B1B0
	.word 64, hp_pat026_rows
hp_pat027:				@ 0832B1B8
	.word 64, hp_pat027_rows
hp_pat028:				@ 0832B1C0
	.word 64, hp_pat028_rows
hp_pat029:				@ 0832B1C8
	.word 64, hp_pat029_rows
hp_pat030:				@ 0832B1D0
	.word 64, hp_pat030_rows
hp_pat031:				@ 0832B1D8
	.word 64, hp_pat031_rows
hp_pat032:				@ 0832B1E0
	.word 64, hp_pat032_rows
hp_pat033:				@ 0832B1E8
	.word 64, hp_pat033_rows
hp_pat034:				@ 0832B1F0
	.word 64, hp_pat034_rows
hp_pat035:				@ 0832B1F8
	.word 64, hp_pat035_rows
hp_pat036:				@ 0832B200
	.word 64, hp_pat036_rows
hp_pat037:				@ 0832B208
	.word 64, hp_pat037_rows
hp_pat038:				@ 0832B210
	.word 64, hp_pat038_rows
hp_pat039:				@ 0832B218
	.word 64, hp_pat039_rows
hp_pat040:				@ 0832B220
	.word 64, hp_pat040_rows
hp_pat041:				@ 0832B228
	.word 64, hp_pat041_rows
hp_pat042:				@ 0832B230
	.word 64, hp_pat042_rows
hp_pat043:				@ 0832B238
	.word 64, hp_pat043_rows
hp_pat044:				@ 0832B240
	.word 64, hp_pat044_rows
hp_pat045:				@ 0832B248
	.word 64, hp_pat045_rows
hp_pat046:				@ 0832B250
	.word 64, hp_pat046_rows
hp_pat047:				@ 0832B258
	.word 64, hp_pat047_rows
hp_pat048:				@ 0832B260
	.word 64, hp_pat048_rows
hp_pat049:				@ 0832B268
	.word 64, hp_pat049_rows
hp_pat050:				@ 0832B270
	.word 64, hp_pat050_rows
hp_pat051:				@ 0832B278
	.word 64, hp_pat051_rows
hp_pat052:				@ 0832B280
	.word 64, hp_pat052_rows
hp_pat053:				@ 0832B288
	.word 64, hp_pat053_rows
hp_pat054:				@ 0832B290
	.word 64, hp_pat054_rows
hp_pat055:				@ 0832B298
	.word 64, hp_pat055_rows
hp_pat056:				@ 0832B2A0
	.word 64, hp_pat056_rows
hp_pat057:				@ 0832B2A8
	.word 64, hp_pat057_rows
hp_pat058:				@ 0832B2B0
	.word 64, hp_pat058_rows
hp_pat059:				@ 0832B2B8
	.word 64, hp_pat059_rows
hp_pat060:				@ 0832B2C0
	.word 64, hp_pat060_rows
hp_pat061:				@ 0832B2C8
	.word 64, hp_pat061_rows
hp_pat062:				@ 0832B2D0
	.word 64, hp_pat062_rows
hp_pat063:				@ 0832B2D8
	.word 64, hp_pat063_rows
hp_pat064:				@ 0832B2E0
	.word 64, hp_pat064_rows
hp_pat065:				@ 0832B2E8
	.word 64, hp_pat065_rows
hp_pat066:				@ 0832B2F0
	.word 64, hp_pat066_rows
hp_pat067:				@ 0832B2F8
	.word 64, hp_pat067_rows
hp_pat068:				@ 0832B300
	.word 64, hp_pat068_rows
hp_pat069:				@ 0832B308
	.word 64, hp_pat069_rows
hp_pat070:				@ 0832B310
	.word 64, hp_pat070_rows
hp_pat071:				@ 0832B318
	.word 64, hp_pat071_rows
hp_pat072:				@ 0832B320
	.word 64, hp_pat072_rows
hp_pat073:				@ 0832B328
	.word 64, hp_pat073_rows
hp_pat074:				@ 0832B330
	.word 64, hp_pat074_rows
hp_pat075:				@ 0832B338
	.word 64, hp_pat075_rows
hp_pat076:				@ 0832B340
	.word 64, hp_pat076_rows
hp_pat077:				@ 0832B348
	.word 64, hp_pat077_rows
hp_pat078:				@ 0832B350
	.word 64, hp_pat078_rows
hp_pat079:				@ 0832B358
	.word 64, hp_pat079_rows
hp_pat080:				@ 0832B360
	.word 64, hp_pat080_rows
hp_pat081:				@ 0832B368
	.word 64, hp_pat081_rows
hp_pat082:				@ 0832B370
	.word 64, hp_pat082_rows
hp_pat083:				@ 0832B378
	.word 64, hp_pat083_rows
hp_pat084:				@ 0832B380
	.word 64, hp_pat084_rows
hp_pat085:				@ 0832B388
	.word 64, hp_pat085_rows
hp_pat086:				@ 0832B390
	.word 64, hp_pat086_rows
hp_pat087:				@ 0832B398
	.word 64, hp_pat087_rows
hp_pat088:				@ 0832B3A0
	.word 64, hp_pat088_rows
hp_pat089:				@ 0832B3A8
	.word 64, hp_pat089_rows
hp_pat090:				@ 0832B3B0
	.word 64, hp_pat090_rows
hp_pat091:				@ 0832B3B8
	.word 64, hp_pat091_rows
hp_pat092:				@ 0832B3C0
	.word 64, hp_pat092_rows
hp_pat093:				@ 0832B3C8
	.word 64, hp_pat093_rows
hp_pat094:				@ 0832B3D0
	.word 64, hp_pat094_rows
hp_pat095:				@ 0832B3D8
	.word 64, hp_pat095_rows
hp_pat096:				@ 0832B3E0
	.word 64, hp_pat096_rows
hp_pat097:				@ 0832B3E8
	.word 64, hp_pat097_rows
hp_pat098:				@ 0832B3F0
	.word 64, hp_pat098_rows
hp_pat099:				@ 0832B3F8
	.word 64, hp_pat099_rows
hp_pat100:				@ 0832B400
	.word 64, hp_pat100_rows
hp_pat101:				@ 0832B408
	.word 64, hp_pat101_rows
hp_pat102:				@ 0832B410
	.word 64, hp_pat102_rows
hp_pat103:				@ 0832B418
	.word 64, hp_pat103_rows
hp_pat104:				@ 0832B420
	.word 64, hp_pat104_rows
hp_pat105:				@ 0832B428
	.word 64, hp_pat105_rows
hp_pat106:				@ 0832B430
	.word 64, hp_pat106_rows
hp_pat107:				@ 0832B438
	.word 64, hp_pat107_rows
hp_pat108:				@ 0832B440
	.word 64, hp_pat108_rows
hp_pat109:				@ 0832B448
	.word 64, hp_pat109_rows
hp_pat110:				@ 0832B450
	.word 64, hp_pat110_rows
hp_pat111:				@ 0832B458
	.word 64, hp_pat111_rows
hp_pat112:				@ 0832B460
	.word 64, hp_pat112_rows
hp_pat113:				@ 0832B468
	.word 64, hp_pat113_rows
hp_pat114:				@ 0832B470
	.word 64, hp_pat114_rows
hp_pat115:				@ 0832B478
	.word 64, hp_pat115_rows
hp_pat116:				@ 0832B480
	.word 64, hp_pat116_rows
hp_pat117:				@ 0832B488
	.word 64, hp_pat117_rows
hp_pat118:				@ 0832B490
	.word 64, hp_pat118_rows
hp_pat119:				@ 0832B498
	.word 64, hp_pat119_rows
hp_pat120:				@ 0832B4A0
	.word 64, hp_pat120_rows
hp_pat121:				@ 0832B4A8
	.word 64, hp_pat121_rows
hp_pat122:				@ 0832B4B0
	.word 64, hp_pat122_rows
hp_pat123:				@ 0832B4B8
	.word 64, hp_pat123_rows
hp_pat124:				@ 0832B4C0
	.word 64, hp_pat124_rows
hp_pat125:				@ 0832B4C8
	.word 64, hp_pat125_rows
hp_pat126:				@ 0832B4D0
	.word 64, hp_pat126_rows
hp_pat127:				@ 0832B4D8
	.word 64, hp_pat127_rows
hp_pat128:				@ 0832B4E0
	.word 64, hp_pat128_rows
hp_pat129:				@ 0832B4E8
	.word 64, hp_pat129_rows
hp_pat130:				@ 0832B4F0
	.word 64, hp_pat130_rows
hp_pat131:				@ 0832B4F8
	.word 64, hp_pat131_rows
hp_pat132:				@ 0832B500
	.word 64, hp_pat132_rows
hp_pat133:				@ 0832B508
	.word 64, hp_pat133_rows
hp_pat134:				@ 0832B510
	.word 64, hp_pat134_rows
hp_pat135:				@ 0832B518
	.word 64, hp_pat135_rows
hp_pat136:				@ 0832B520
	.word 64, hp_pat136_rows
hp_pat137:				@ 0832B528
	.word 64, hp_pat137_rows
hp_pat138:				@ 0832B530
	.word 64, hp_pat138_rows
hp_pat139:				@ 0832B538
	.word 64, hp_pat139_rows
hp_pat140:				@ 0832B540
	.word 64, hp_pat140_rows
hp_pat141:				@ 0832B548
	.word 64, hp_pat141_rows
hp_pat142:				@ 0832B550
	.word 64, hp_pat142_rows
hp_pat143:				@ 0832B558
	.word 64, hp_pat143_rows
hp_pat144:				@ 0832B560
	.word 64, hp_pat144_rows
hp_pat145:				@ 0832B568
	.word 64, hp_pat145_rows
hp_pat146:				@ 0832B570
	.word 64, hp_pat146_rows
hp_pat147:				@ 0832B578
	.word 64, hp_pat147_rows
hp_pat148:				@ 0832B580
	.word 64, hp_pat148_rows
hp_pat149:				@ 0832B588
	.word 64, hp_pat149_rows
hp_pat150:				@ 0832B590
	.word 64, hp_pat150_rows
hp_pat151:				@ 0832B598
	.word 64, hp_pat151_rows
hp_pat152:				@ 0832B5A0
	.word 64, hp_pat152_rows
hp_pat153:				@ 0832B5A8
	.word 64, hp_pat153_rows
hp_pat154:				@ 0832B5B0
	.word 64, hp_pat154_rows
hp_pat155:				@ 0832B5B8
	.word 64, hp_pat155_rows
hp_pat156:				@ 0832B5C0
	.word 64, hp_pat156_rows
hp_pat157:				@ 0832B5C8
	.word 64, hp_pat157_rows
hp_pat158:				@ 0832B5D0
	.word 64, hp_pat158_rows
hp_pat159:				@ 0832B5D8
	.word 64, hp_pat159_rows
hp_pat160:				@ 0832B5E0
	.word 64, hp_pat160_rows
hp_pat161:				@ 0832B5E8
	.word 64, hp_pat161_rows
hp_pat162:				@ 0832B5F0
	.word 64, hp_pat162_rows
hp_pat163:				@ 0832B5F8
	.word 64, hp_pat163_rows
hp_pat164:				@ 0832B600
	.word 64, hp_pat164_rows
hp_pat165:				@ 0832B608
	.word 64, hp_pat165_rows
hp_pat166:				@ 0832B610
	.word 64, hp_pat166_rows
hp_pat167:				@ 0832B618
	.word 64, hp_pat167_rows
hp_pat168:				@ 0832B620
	.word 64, hp_pat168_rows
hp_pat169:				@ 0832B628
	.word 64, hp_pat169_rows
hp_pat170:				@ 0832B630
	.word 64, hp_pat170_rows
hp_pat171:				@ 0832B638
	.word 64, hp_pat171_rows
hp_pat172:				@ 0832B640
	.word 64, hp_pat172_rows
hp_pat173:				@ 0832B648
	.word 64, hp_pat173_rows
hp_pat174:				@ 0832B650
	.word 64, hp_pat174_rows
hp_pat175:				@ 0832B658
	.word 64, hp_pat175_rows
hp_pat176:				@ 0832B660
	.word 64, hp_pat176_rows
hp_pat177:				@ 0832B668
	.word 64, hp_pat177_rows
hp_pat178:				@ 0832B670
	.word 64, hp_pat178_rows
hp_pat179:				@ 0832B678
	.word 64, hp_pat179_rows
hp_pat180:				@ 0832B680
	.word 64, hp_pat180_rows
hp_pat181:				@ 0832B688
	.word 64, hp_pat181_rows
hp_pat182:				@ 0832B690
	.word 64, hp_pat182_rows
hp_pat183:				@ 0832B698
	.word 64, hp_pat183_rows
hp_pat184:				@ 0832B6A0
	.word 64, hp_pat184_rows
hp_pat185:				@ 0832B6A8
	.word 64, hp_pat185_rows
hp_pcm01:				@ 0832B6B0
	.word 6816, hp_smp01
hp_pcm02:				@ 0832B6B8
	.word 23311, hp_smp02
hp_pcm03:				@ 0832B6C0
	.word 1029, hp_smp03
hp_pcm04:				@ 0832B6C8
	.word 200, hp_smp04
hp_pcm05:				@ 0832B6D0
	.word 3756, hp_smp05
hp_pcm06:				@ 0832B6D8
	.word 28032, hp_smp06
hp_pcm07:				@ 0832B6E0
	.word 25292, hp_smp07
hp_pcm08:				@ 0832B6E8
	.word 319, hp_smp08
hp_pcm09:				@ 0832B6F0
	.word 663, hp_smp09
hp_pcm10:				@ 0832B6F8
	.word 697, hp_smp10
hp_pcm11:				@ 0832B700
	.word 965, hp_smp11
hp_pcm12:				@ 0832B708
	.word 921, hp_smp12
hp_pcm13:				@ 0832B710
	.word 867, hp_smp13
hp_pcm14:				@ 0832B718
	.word 905, hp_smp14
hp_pcm15:				@ 0832B720
	.word 531, hp_smp15
hp_pcm16:				@ 0832B728
	.word 677, hp_smp16
hp_pcm17:				@ 0832B730
	.word 573, hp_smp17
hp_pcm18:				@ 0832B738
	.word 592, hp_smp18
hp_pcm19:				@ 0832B740
	.word 576, hp_smp19
hp_pcm20:				@ 0832B748
	.word 603, hp_smp20
hp_pcm21:				@ 0832B750
	.word 2525, hp_smp21
hp_pcm22:				@ 0832B758
	.word 2016, hp_smp22
hp_pcm23:				@ 0832B760
	.word 8894, hp_smp23
hp_pcm24:				@ 0832B768
	.word 9752, hp_smp24
hp_pcm25:				@ 0832B770
	.word 357, hp_smp25
hp_pcm26:				@ 0832B778
	.word 298, hp_smp26
hp_pcm27:				@ 0832B780
	.word 288, hp_smp27
hp_pcm28:				@ 0832B788
	.word 326, hp_smp28
hp_pcm29:				@ 0832B790
	.word 325, hp_smp29
hp_pcm30:				@ 0832B798
	.word 325, hp_smp30
hp_pcm31:				@ 0832B7A0
	.word 360, hp_smp31
hp_pcm32:				@ 0832B7A8
	.word 886, hp_smp32
hp_pcm33:				@ 0832B7B0
	.word 334, hp_smp33
hp_pcm34:				@ 0832B7B8
	.word 15050, hp_smp34
hp_pcm35:				@ 0832B7C0
	.word 12943, hp_smp35
hp_pcm36:				@ 0832B7C8
	.word 9170, hp_smp36
hp_pcm37:				@ 0832B7D0
	.word 19, hp_smp37
hp_pcm38:				@ 0832B7D8
	.word 6406, hp_smp38
hp_pcm39:				@ 0832B7E0
	.word 30210, hp_smp39
hp_pcm40:				@ 0832B7E8
	.word 3091, hp_smp40
hp_pcm41:				@ 0832B7F0
	.word 16170, hp_smp41
hp_pcm42:				@ 0832B7F8
	.word 17286, hp_smp42
hp_pcm43:				@ 0832B800
	.word 14254, hp_smp43
hp_pcm44:				@ 0832B808
	.word 45943, hp_smp44
hp_pcm45:				@ 0832B810
	.word 14794, hp_smp45
hp_pcm46:				@ 0832B818
	.word 16170, hp_smp46
hp_pcm47:				@ 0832B820
	.word 7722, hp_smp47
hp_pcm48:				@ 0832B828
	.word 4052, hp_smp48
hp_pcm49:				@ 0832B830
	.word 6568, hp_smp49
hp_pcm50:				@ 0832B838
	.word 2690, hp_smp50
hp_pcm51:				@ 0832B840
	.word 2722, hp_smp51
hp_pcm52:				@ 0832B848
	.word 7288, hp_smp52
hp_pat000_rows:				@ 0832B850
	@ pattern 000: 64 rows, played at order 2
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_5, i=2	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_3, i=11 ; ev ; ev ; ev n=G_5, i=2	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev n=G_5, i=2	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 11
	ev ; ev ; ev ; ev n=G_5, i=2	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev ; ev ; ev n=G_5, i=2	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev ; ev ; ev ; ev n=G_5, i=2	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=G_6, i=2	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 25
	ev n=C_3, i=14 ; ev ; ev ; ev n=G_5, i=2	@ 26
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 27
	ev ; ev ; ev ; ev n=G_5, i=2	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_3, i=9 ; ev ; ev ; ev n=G_5, i=2	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_3, i=20 ; ev ; ev ; ev n=G_5, i=2	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 41
	ev n=C_3, i=9 ; ev ; ev ; ev n=G_5, i=2	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 43
	ev n=C_3, i=16 ; ev ; ev ; ev n=G_5, i=2	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev ; ev n=G_5, i=2	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 53
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=G_5, i=2	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 55
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=G_6, i=2	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev n=G_5, i=2	@ 58
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=G_5, i=2	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat001_rows:				@ 0832BA04
	@ pattern 001: 64 rows, played at order 0
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2, fx=FX_SPEED, p=0x03	@ 00
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 03
	ev n=C_3, i=10 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 07
	ev n=C_3, i=11 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 08
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 10
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 11
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2	@ 12
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 13
	ev n=C_3, i=12 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 14
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 15
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 18
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 19
	ev n=C_3, i=13 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 20
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 21
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 22
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 24
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 26
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 27
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 28
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_3, i=9 ; ev ; ev ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_3, i=20 ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_3, i=9 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat002_rows:				@ 0832BB90
	@ pattern 002: 64 rows, played at order 1
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev ; ev n=Gs3-8, i=1, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=2	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_3, i=11 ; ev ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev n=G_5, i=2	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_3, i=9 ; ev ; ev ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_3, i=20 ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_3, i=9 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat003_rows:				@ 0832BCFC
	@ pattern 003: 64 rows, played at order 3
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev ; ev n=B_3-8, i=1 ; ev n=G_5, i=2	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_3, i=11 ; ev ; ev ; ev n=G_5, i=2	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev n=G_5, i=2	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 11
	ev ; ev ; ev ; ev n=G_5, i=2	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev ; ev ; ev n=G_5, i=2	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev ; ev ; ev ; ev n=G_5, i=2	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=G_6, i=2	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 25
	ev n=C_3, i=14 ; ev ; ev ; ev n=G_5, i=2	@ 26
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 27
	ev ; ev ; ev ; ev n=G_5, i=2	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_3, i=9 ; ev n=D_5, i=23, fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2	@ 32
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 35
	ev n=C_3, i=15 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 39
	ev n=C_3, i=20 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 41
	ev n=C_3, i=9 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 43
	ev n=C_3, i=16 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 45
	ev n=C_3, i=17 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 47
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 53
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 55
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 57
	ev n=C_3, i=19 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 61
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00	@ 62
	ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat004_rows:				@ 0832BEBC
	@ pattern 004: 64 rows, played at order 4
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=G_7, i=35	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10 ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev	@ 10
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 11
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 25
	ev n=C_3, i=14 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 27
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=G_7, i=35	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10 ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 41
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev	@ 42
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 43
	ev n=C_3, i=16 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_4, i=3 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev ; ev n=G_5, i=2 ; ev	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev n=G_5, i=2 ; ev	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat005_rows:				@ 0832C0A0
	@ pattern 005: 64 rows, played at orders 8, 9, 10
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=G_5, i=22 ; ev ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev n=G_5, i=21 ; ev ; ev n=G_6, i=35	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev n=G_5, i=22 ; ev ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev n=G_5, i=21 ; ev ; ev n=G_6, i=35	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat006_rows:				@ 0832C28C
	@ pattern 006: 64 rows, played at order 7
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev ; ev n=C_4, i=3 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev ; ev ; ev n=G_7, i=35	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10 ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev n=G_5, i=2 ; ev	@ 10
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 11
	ev ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev ; ev n=C_4, i=3 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev ; ev n=G_5, i=2 ; ev	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev n=G_5, i=2 ; ev	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 27
	ev ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev ; ev n=C_4, i=3 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev ; ev ; ev n=G_7, i=35	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev ; ev ; ev n=G_7, i=35	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev ; ev n=G_7, i=35	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=G_7, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x00	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x20	@ 63
hp_pat007_rows:				@ 0832C440
	@ pattern 007: 64 rows, played at orders 5, 6
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev ; ev n=C_4, i=3 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev ; ev ; ev n=G_7, i=35	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10 ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev n=G_5, i=2 ; ev	@ 10
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 11
	ev ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev ; ev n=C_4, i=3 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev ; ev n=G_5, i=2 ; ev	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev n=G_5, i=2 ; ev	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 27
	ev ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev ; ev n=C_4, i=3 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev ; ev ; ev n=G_7, i=35	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x10 ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 41
	ev ; ev ; ev n=G_5, i=2 ; ev	@ 42
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 43
	ev n=C_3, i=16 ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev ; ev n=C_4, i=3 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev ; ev n=G_5, i=2 ; ev	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev ; ev n=C_4, i=3 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev n=G_5, i=2 ; ev	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_5, i=2 ; ev n=G_7, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat008_rows:				@ 0832C610
	@ pattern 008: 64 rows, played at order 11
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=G_5, i=22 ; ev ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev n=G_5, i=21 ; ev ; ev n=G_6, i=35	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=14, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=22 ; ev ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=14, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=14, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=32, fx=FX_VOLUME, p=0x10 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x03 ; ev ; ev n=C_3, i=31, fx=FX_VOLUME, p=0x10 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=14, fx=FX_VOLUME, p=0x05 ; ev ; ev n=C_3, i=30, fx=FX_VOLUME, p=0x1A ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=C_3, i=29, fx=FX_VOLUME, p=0x20 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_3, i=28, fx=FX_VOLUME, p=0x2A ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_3, i=14, fx=FX_VOLUME, p=0x03 ; ev ; ev n=C_3, i=27, fx=FX_VOLUME, p=0x30 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=C_3, i=26, fx=FX_VOLUME, p=0x3A ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=25, fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=C_3, i=14, fx=FX_VOLUME, p=0x01 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=30, fx=FX_VOLUME, p=0x40 ; ev	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat009_rows:				@ 0832C7E8
	@ pattern 009: 64 rows, played at orders 12, 14
	ev n=As4, i=7, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 07
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_4, i=3, fx=FX_VOLUME, p=0x20	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_4, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 30
	ev ; ev ; ev fx=FX_VIBRATO, p=0x93 ; ev	@ 31
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x94 ; ev	@ 36
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 37
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 38
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 39
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 41
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 42
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 43
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_4, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_4, i=3, fx=FX_VOLUME, p=0x20	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_4, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_7, i=34 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat010_rows:				@ 0832C9FC
	@ pattern 010: 64 rows, played at order 13
	ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 07
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_4, i=3, fx=FX_VOLUME, p=0x20	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 30
	ev ; ev ; ev fx=FX_VIBRATO, p=0x93 ; ev	@ 31
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x94 ; ev	@ 36
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 37
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 38
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 39
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 41
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 42
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 43
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=As6, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_4, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_4, i=3, fx=FX_VOLUME, p=0x20	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_4, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=34, fx=FX_VOLUME, p=0x0A ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=34, fx=FX_VOLUME, p=0x10 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=As5, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat011_rows:				@ 0832CC10
	@ pattern 011: 64 rows, played at order 15
	ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 07
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_4, i=3, fx=FX_VOLUME, p=0x20	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x10 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev ; ev	@ 38
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x01 ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x05 ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x20 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev n=D_6, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=C_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=As5, i=34, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat012_rows:				@ 0832CE0C
	@ pattern 012: 64 rows, played at orders 16, 18
	ev n=Ds3, i=9, fx=FX_VOLUME, p=0x10 ; ev ; ev n=As4, i=7, fx=FX_VOLUME, p=0x1A ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=Ds3, i=9, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=Ds3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=Ds3, i=10, fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat013_rows:				@ 0832CF58
	@ pattern 013: 64 rows, played at order 17
	ev n=F_3, i=9, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x1A ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 01
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 03
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 05
	ev n=F_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 07
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 09
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 11
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 12
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 13
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 15
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 17
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 19
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 29
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 31
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 32
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 33
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 34
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 35
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 37
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 39
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 41
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 43
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 44
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 45
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 47
	ev ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat014_rows:				@ 0832D0D8
	@ pattern 014: 64 rows, played at order 19
	ev n=F_3, i=9, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x1A ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 01
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 03
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 05
	ev n=F_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 07
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 09
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 11
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 12
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 13
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 15
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 17
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 19
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 29
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 31
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 32
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 33
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 34
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 35
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 37
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 39
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 41
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 43
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 44
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 45
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 47
	ev ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x0A	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=F_3, i=11, fx=FX_VOLUME, p=0x03 ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_3, i=10, fx=FX_VOLUME, p=0x01 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev fx=FX_VOLUME, p=0x04 ; ev ; ev	@ 61
	ev ; ev n=C_7, i=2, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev fx=FX_VOLUME, p=0x04 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat015_rows:				@ 0832D280
	@ pattern 015: 64 rows, played at orders 20, 22
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=G_5, i=22, fx=FX_SPEED, p=0x03 ; ev n=D_5, i=23, fx=FX_VOLUME, p=0x02 ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev n=G_5, i=22 ; ev ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat016_rows:				@ 0832D48C
	@ pattern 016: 64 rows, played at order 21
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=G_5, i=22 ; ev n=D_5, i=23, fx=FX_VOLUME, p=0x02 ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev n=G_5, i=22 ; ev n=D_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=C_4, i=3	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev n=G_6, i=35	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat017_rows:				@ 0832D6A0
	@ pattern 017: 64 rows, played at order 23
	ev n=C_3, i=9, fx=FX_STORE, p=0x95 ; ev n=G_5, i=22 ; ev n=D_5, i=23, fx=FX_VOLUME, p=0x02 ; ev n=C_4, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=C_3, i=10 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 05
	ev n=C_3, i=9, fx=FX_VOLUME, p=0x20 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=C_3, i=11 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_3, i=12 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 15
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_3, i=13 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_3, i=14 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev n=Cs5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=G_6, i=35	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x02 ; ev	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_3, i=9 ; ev n=G_5, i=22 ; ev n=D_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=C_4, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_3, i=15 ; ev n=G_5, i=21 ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=11, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_3, i=20 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_3, i=16 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_3, i=17 ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 47
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_4, i=3	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x1A ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_3, i=18 ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_3, i=19 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=G_5, i=22, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 62
	ev fx=FX_JUMP, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat018_rows:				@ 0832D894
	@ pattern 018: 64 rows, played at orders 24, 28, 53, 64, 85, 98, 119, 155, 176, 194
	ev ; ev ; ev ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev ; ev ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat019_rows:				@ 0832D994
	@ pattern 019: 64 rows, played at order 25
	ev fx=FX_STORE, p=0x95 ; ev fx=FX_SPEED, p=0x07 ; ev n=C_4, i=23, fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 01
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 03
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 05
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 07
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 08
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 09
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 10
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 11
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 12
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 13
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 14
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 15
	ev n=Ds4, i=23, fx=FX_VOLUME, p=0x00 ; ev n=Ds5, i=23, fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 17
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 19
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 21
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 22
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 23
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 25
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 26
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 27
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 29
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 30
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 31
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=As3, i=23, fx=FX_VOLUME, p=0x00 ; ev n=As4, i=23, fx=FX_VOLUME, p=0x00	@ 32
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 33
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 34
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 35
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 36
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 37
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 38
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 39
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 40
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 41
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 42
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 43
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 44
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 45
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 46
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x10	@ 47
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 62
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat020_rows:				@ 0832DB58
	@ pattern 020: 64 rows, played at order 26
	ev n=G_4, i=24, fx=FX_SPEED, p=0x07 ; ev n=F_2, i=9 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev n=F_2, i=9, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 03
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=F_3, i=10 ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 05
	ev n=G_4, i=23 ; ev ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 06
	ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 07
	ev ; ev n=F_3, i=11 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=F_3, i=12 ; ev n=F_3, i=29 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 10
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=F_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 11
	ev ; ev ; ev n=F_3, i=31 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev n=F_3, i=12, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 13
	ev ; ev n=F_3, i=15 ; ev n=F_3, i=32 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=G_4, i=24 ; ev n=F_3, i=9 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=F_2, i=10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev n=F_3, i=9, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 19
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=F_3, i=11 ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=F_2, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 21
	ev n=G_4, i=23 ; ev ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 22
	ev ; ev n=F_3, i=11 ; ev ; ev	@ 23
	ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=F_3, i=12 ; ev n=F_3, i=32 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 26
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 27
	ev ; ev n=F_3, i=12, fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=31 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev n=F_3, i=13 ; ev ; ev	@ 29
	ev ; ev ; ev n=F_3, i=30 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20	@ 30
	ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 31
	ev n=C_4, i=24 ; ev n=As1, i=9 ; ev n=F_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev n=As1, i=9, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 35
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=As2, i=10 ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 37
	ev n=C_4, i=23 ; ev ; ev n=F_5, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 38
	ev ; ev n=As2, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 39
	ev ; ev n=As2, i=11 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=As2, i=12 ; ev n=As3, i=29 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 42
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=As2, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 43
	ev ; ev ; ev n=As3, i=31 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev n=As2, i=12, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 45
	ev ; ev n=As2, i=15 ; ev n=As3, i=32 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_4, i=24 ; ev n=As2, i=9 ; ev n=F_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=As1, i=10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev n=As2, i=9, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 51
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=As2, i=11 ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=As1, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 53
	ev n=C_4, i=23 ; ev ; ev n=F_5, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 54
	ev ; ev n=As2, i=11 ; ev ; ev	@ 55
	ev ; ev n=As2, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=As2, i=12 ; ev n=As3, i=32 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 58
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 59
	ev ; ev n=As2, i=12, fx=FX_VOLUME, p=0x0A ; ev n=As3, i=31 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev n=As2, i=13 ; ev ; ev	@ 61
	ev ; ev ; ev n=As3, i=30 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev n=As2, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat021_rows:				@ 0832DDEC
	@ pattern 021: 64 rows, played at order 27
	ev n=D_4, i=24 ; ev n=C_2, i=9 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev n=C_2, i=9, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 03
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_3, i=10 ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 05
	ev n=D_4, i=23 ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 06
	ev ; ev n=C_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 07
	ev ; ev n=C_3, i=11 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_3, i=12 ; ev n=C_3, i=29 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 10
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 11
	ev ; ev ; ev n=C_3, i=31 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev n=C_3, i=12, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 13
	ev ; ev n=C_3, i=15 ; ev n=C_3, i=32 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_4, i=24 ; ev n=C_3, i=9 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_2, i=10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 19
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_3, i=11 ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_2, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 21
	ev n=D_4, i=23 ; ev ; ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 22
	ev ; ev n=C_3, i=11 ; ev ; ev	@ 23
	ev ; ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_3, i=12 ; ev n=C_3, i=32 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 26
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 27
	ev ; ev n=C_3, i=12, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=31 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev n=C_3, i=13 ; ev ; ev	@ 29
	ev ; ev ; ev n=C_3, i=30 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20	@ 30
	ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 31
	ev n=E_4, i=24 ; ev n=D_2, i=9 ; ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev n=D_2, i=9, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 35
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=D_3, i=10 ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 37
	ev n=E_4, i=23 ; ev ; ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 38
	ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 39
	ev ; ev n=D_3, i=11 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=D_3, i=12 ; ev n=D_3, i=29 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 42
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 43
	ev ; ev ; ev n=D_3, i=31 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 45
	ev ; ev n=D_3, i=15 ; ev n=D_3, i=32 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=G_4, i=23 ; ev n=F_3, i=9 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=F_2, i=10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev n=F_3, i=9, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev n=C_3, i=3	@ 51
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_3, i=11 ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_2, i=10, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 53
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=C_6, i=2, fx=FX_VOLUME, p=0x20 ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_3, i=11 ; ev ; ev	@ 55
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_6, i=5, fx=FX_VOLUME, p=0x20	@ 56
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_3, i=12 ; ev n=F_3, i=32 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 58
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A	@ 59
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_3, i=12, fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=31 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev n=F_3, i=13 ; ev ; ev	@ 61
	ev ; ev ; ev n=F_3, i=30 ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20	@ 62
	ev fx=FX_JUMP, p=0x1A ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat022_rows:				@ 0832E084
	@ pattern 022: 64 rows, played at orders 29, 30
	ev fx=FX_STORE, p=0x95 ; ev fx=FX_SPEED, p=0x07 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 03
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 05
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 07
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 08
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 09
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 10
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 11
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 17
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 19
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 21
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 23
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 25
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 26
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 27
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 35
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 37
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 39
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 41
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 43
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev n=As4, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 49
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 51
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 53
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 55
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 59
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat023_rows:				@ 0832E1CC
	@ pattern 023: 64 rows, played at order 31
	ev n=E_6, i=22 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 01
	ev n=E_6, i=22 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 02
	ev ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 03
	ev n=E_6, i=21 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 05
	ev n=E_6, i=22 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 07
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 08
	ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 09
	ev n=E_6, i=22 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 11
	ev n=E_6, i=21 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 15
	ev n=E_6, i=22 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 17
	ev n=E_6, i=22 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 19
	ev n=E_6, i=21 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 21
	ev n=E_6, i=22 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 23
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 25
	ev n=E_6, i=22 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 27
	ev n=E_6, i=21 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=E_6, i=22 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 33
	ev n=E_6, i=22 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 35
	ev n=E_6, i=21 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 37
	ev n=E_6, i=22 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 39
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 41
	ev n=E_6, i=22 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 43
	ev n=E_6, i=21 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 47
	ev n=E_6, i=22 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 49
	ev n=E_6, i=22 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 51
	ev n=E_6, i=21 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 53
	ev n=E_6, i=22 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 55
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 59
	ev n=E_6, i=21 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 62
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat024_rows:				@ 0832E488
	@ pattern 024: 64 rows, played at order 32
	ev n=E_6, i=22 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 01
	ev n=E_6, i=22 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 02
	ev ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 03
	ev n=E_6, i=21 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 05
	ev n=E_6, i=22 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 07
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 08
	ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 09
	ev n=E_6, i=22 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01 ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 11
	ev n=E_6, i=21 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 15
	ev n=E_6, i=22 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 17
	ev n=E_6, i=22 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 19
	ev n=E_6, i=21 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 21
	ev n=E_6, i=22 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 23
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 25
	ev n=E_6, i=22 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 27
	ev n=E_6, i=21 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3	@ 30
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=E_6, i=22 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 33
	ev n=E_6, i=22 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 35
	ev n=E_6, i=21 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 37
	ev n=E_6, i=22 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 39
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 41
	ev n=E_6, i=22 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 43
	ev n=E_6, i=21 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 47
	ev n=E_6, i=22 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 49
	ev n=E_6, i=22 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01	@ 50
	ev ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 51
	ev n=E_6, i=21 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 53
	ev n=E_6, i=22 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 55
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 59
	ev n=E_6, i=21 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3, fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=C_2, i=3	@ 62
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev n=C_2, i=3	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat025_rows:				@ 0832E768
	@ pattern 025: 64 rows, played at order 33
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 21
	ev n=C_3, i=3 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 37
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 47
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 53
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 62
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 63
hp_pat026_rows:				@ 0832EA54
	@ pattern 026: 64 rows, played at order 34
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 21
	ev n=C_3, i=3 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 32
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 47
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 53
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat027_rows:				@ 0832ED34
	@ pattern 027: 64 rows, played at order 35
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 32
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 36
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 38
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 42
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 58
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat028_rows:				@ 0832F03C
	@ pattern 028: 64 rows, played at order 36
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 32
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 36
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 38
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 42
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev n=E_6+14, i=36 ; ev	@ 56
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 58
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev n=E_6+14, i=36 ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=E_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=E_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat029_rows:				@ 0832F348
	@ pattern 029: 64 rows, played at orders 37, 41
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 36
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 42
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 52
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 58
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat030_rows:				@ 0832F670
	@ pattern 030: 64 rows, played at orders 38, 42
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 04
	ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 10
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 20
	ev ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 26
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 36
	ev ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev	@ 42
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev	@ 50
	ev ; ev ; ev n=D_6+14, i=36 ; ev	@ 51
	ev ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev ; ev	@ 56
	ev ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev n=F_5, i=38 ; ev ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat031_rows:				@ 0832F944
	@ pattern 031: 64 rows, played at order 39
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=Cs6-16, i=39, fx=FX_PORTA_UP, p=0x01 ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x30 ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=C_6-16, i=39 ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x93 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 10
	ev ; ev n=Ds6-16, i=39 ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=Cs6-16, i=39 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=Fs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 20
	ev ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 26
	ev ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=Ds6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=Cs6-16, i=39 ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_6-16, i=39 ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs5-16, i=39 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 42
	ev ; ev n=Gs5-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_6-16, i=39 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=Gs5-16, i=39 ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev ; ev n=A_5+14, i=36 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs6-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Fs6-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs7-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=Fs7-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Gs7-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat032_rows:				@ 0832FBF4
	@ pattern 032: 64 rows, played at order 40
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=Cs6-16, i=39, fx=FX_PORTA_UP, p=0x01 ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x30 ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=C_6-16, i=39 ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x93 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 10
	ev ; ev n=Ds6-16, i=39 ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=Cs6-16, i=39 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=Fs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 20
	ev ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 26
	ev ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=Ds6-16, i=39 ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Fs6-16, i=39 ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Cs6-16, i=39 ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 36
	ev ; ev n=Gs6-16, i=39 ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_6-16, i=39 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39 ; ev ; ev	@ 42
	ev ; ev fx=FX_PORTA_DN, p=0x0A ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Gs6-16, i=39 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=Fs6-16, i=39, fx=FX_PORTA_UP, p=0x02 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_PORTA_UP, p=0x02 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=Gs6-16, i=39, fx=FX_TONEPORTA, p=0x10 ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 52
	ev ; ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev	@ 53
	ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 56
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat033_rows:				@ 0832FE98
	@ pattern 033: 64 rows, played at order 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=A_5, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 04
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=E_8, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 10
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 20
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 26
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 36
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 42
	ev ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 52
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=A_5+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat034_rows:				@ 083301C0
	@ pattern 034: 64 rows, played at order 44
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=E_6, i=21 ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 08
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=E_6, i=21 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=E_6, i=22 ; ev ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=E_6, i=22 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev ; ev ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=E_6, i=21 ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=E_6, i=22 ; ev ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=E_6, i=21 ; ev ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 30
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=E_6, i=22 ; ev ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=E_6, i=21 ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=E_6, i=22 ; ev ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 40
	ev ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=E_6, i=21 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 50
	ev ; ev ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=E_6, i=21 ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 56
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=E_6, i=21 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01	@ 63
hp_pat035_rows:				@ 083303B4
	@ pattern 035: 64 rows, played at order 45
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x20 ; ev n=A_5+14, i=36 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20 ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 04
	ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20 ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 10
	ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 12
	ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36 ; ev	@ 16
	ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev ; ev n=C_6+14, i=36 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=36 ; ev	@ 32
	ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=36 ; ev	@ 38
	ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 42
	ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev ; ev n=A_5+14, i=36 ; ev	@ 48
	ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev ; ev n=A_5+14, i=36 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat036_rows:				@ 08330628
	@ pattern 036: 64 rows, played at order 46
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=A_5, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 04
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 05
	ev n=C_3, i=3 ; ev n=E_8, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 06
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 10
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 13
	ev n=E_6, i=22 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=C_6+14, i=36 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 20
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_6+14, i=36 ; ev	@ 22
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 26
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 32
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 38
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 48
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x05	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x05	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 52
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=A_5+14, i=36 ; ev	@ 54
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat037_rows:				@ 0833099C
	@ pattern 037: 64 rows, played at order 48
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=A_5, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 04
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 05
	ev n=C_3, i=3 ; ev n=E_8, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 10
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 20
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 26
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 36
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 42
	ev ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 52
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=A_5+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat038_rows:				@ 08330CC4
	@ pattern 038: 64 rows, played at order 43
	ev n=E_6, i=22 ; ev n=A_5, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 01
	ev n=E_6, i=22 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 02
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 03
	ev n=E_6, i=21 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 04
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 05
	ev n=E_6, i=22 ; ev n=E_8, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 06
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 07
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 08
	ev ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 09
	ev n=E_6, i=22 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 10
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 11
	ev n=E_6, i=21 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=E_4, i=24, fx=FX_VOLUME, p=0x10	@ 12
	ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 13
	ev n=E_6, i=22 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=E_6, i=22 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=C_6+14, i=36 ; ev n=G_4, i=24, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 17
	ev n=E_6, i=22 ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=E_6, i=21 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 20
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 21
	ev n=E_6, i=22 ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=C_6+14, i=36 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 24
	ev ; ev n=G_6, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22 ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 26
	ev ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=E_6, i=21 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 31
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 33
	ev n=E_6, i=22 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 34
	ev ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=D_6+14, i=36 ; ev	@ 35
	ev n=E_6, i=21 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 36
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 37
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10	@ 38
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 39
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 40
	ev ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 41
	ev n=E_6, i=22 ; ev n=D_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 42
	ev ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 43
	ev n=E_6, i=21 ; ev n=Fs7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev ; ev n=D_8, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 47
	ev n=E_6, i=22 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 49
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 50
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=E_6, i=21 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 52
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 53
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x10 ; ev n=A_5+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 55
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 56
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 59
	ev n=E_6, i=21 ; ev n=G_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=E_7, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01	@ 63
hp_pat039_rows:				@ 08330FB8
	@ pattern 039: 64 rows, played at order 50
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev ; ev n=A_5+14, i=36 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev n=Cs6-16, i=39, fx=FX_PORTA_UP, p=0x01 ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x30 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+14, i=36 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 05
	ev n=C_3, i=3 ; ev n=C_6-16, i=39 ; ev n=A_5+14, i=36 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 06
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x93 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 10
	ev ; ev n=Ds6-16, i=39 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 13
	ev n=E_6, i=22 ; ev n=Cs6-16, i=39 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=Fs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 20
	ev ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev	@ 22
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 26
	ev ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 32
	ev ; ev n=Ds6-16, i=39 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Fs6-16, i=39 ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Cs6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev n=Gs6-16, i=39 ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev ; ev n=D_6+14, i=36 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 38
	ev ; ev ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_6-16, i=39 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev fx=FX_PORTA_DN, p=0x0A ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Gs6-16, i=39 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=Fs6-16, i=39, fx=FX_PORTA_UP, p=0x02 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_PORTA_UP, p=0x02 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=Gs6-16, i=39, fx=FX_TONEPORTA, p=0x10 ; ev n=A_5+14, i=36 ; ev	@ 48
	ev ; ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x05	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x05	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 52
	ev ; ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev	@ 53
	ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 56
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat040_rows:				@ 083312A8
	@ pattern 040: 64 rows, played at order 49
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev ; ev n=A_5+14, i=36 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev n=Cs6-16, i=39, fx=FX_PORTA_UP, p=0x01 ; ev ; ev	@ 01
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x30 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 02
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+14, i=36 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 03
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 05
	ev n=C_3, i=3 ; ev n=C_6-16, i=39 ; ev n=A_5+14, i=36 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 06
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 07
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 08
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x93 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 09
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 10
	ev ; ev n=Ds6-16, i=39 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 11
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 13
	ev n=E_6, i=22 ; ev n=Cs6-16, i=39 ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 15
	ev n=C_3, i=3 ; ev n=Fs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 17
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 18
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39 ; ev n=C_6+14, i=36 ; ev	@ 19
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 20
	ev ; ev fx=FX_PORTA_DN, p=0x01 ; ev ; ev	@ 21
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36 ; ev	@ 22
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 23
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 24
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Ds6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 25
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 26
	ev ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 27
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39 ; ev n=C_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 28
	ev ; ev fx=FX_VIBRATO, p=0x93 ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev fx=FX_VIBRATO, p=0x00 ; ev ; ev	@ 30
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=C_3, i=3 ; ev n=Ds6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 32
	ev ; ev n=Cs6-16, i=39 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 33
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 34
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 35
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_3, i=3 ; ev n=Cs6-16, i=39 ; ev n=D_6+14, i=36 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 38
	ev ; ev ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 39
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs5-16, i=39 ; ev ; ev	@ 40
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 41
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev n=Gs5-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 43
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_6-16, i=39 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev n=Cs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 47
	ev n=C_3, i=3, fx=FX_SPEED, p=0x07 ; ev n=Gs5-16, i=39 ; ev n=A_5+14, i=36 ; ev	@ 48
	ev ; ev ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x05	@ 49
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x05	@ 50
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=A_5+14, i=36 ; ev	@ 51
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_3, i=3 ; ev ; ev n=A_5+14, i=36 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs6-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 56
	ev n=C_6, i=22, fx=FX_VOLUME, p=0x0A ; ev n=Fs6-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 57
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs7-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=Fs7-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 59
	ev n=F_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Gs7-16, i=39, fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x0A ; ev	@ 60
	ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x20 ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat041_rows:				@ 083315A8
	@ pattern 041: 64 rows, played at order 51
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 01
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 03
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 05
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 07
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 09
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 11
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 13
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 15
	ev n=E_6, i=22 ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 17
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 18
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 19
	ev n=E_6, i=21 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 20
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 21
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 22
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 23
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 24
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 25
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 26
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 27
	ev n=E_6, i=21 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 30
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 31
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 32
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 33
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x20	@ 35
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 37
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x20	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 39
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 41
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x20	@ 43
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=E_6, i=22 ; ev ; ev ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x10	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x10	@ 47
	ev n=E_6, i=22 ; ev n=As4, i=7, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 48
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x05	@ 49
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x05	@ 50
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 51
	ev n=E_6, i=21 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 52
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 53
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 54
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 55
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 56
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 57
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 58
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 59
	ev n=E_6, i=21 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=E_6, i=22 ; ev ; ev ; ev	@ 62
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat042_rows:				@ 083317D0
	@ pattern 042: 64 rows, played at order 52
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 00
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F	@ 01
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F	@ 03
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F	@ 05
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F	@ 07
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F	@ 09
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F	@ 11
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 12
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F	@ 13
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F	@ 14
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F	@ 15
	ev n=E_6, i=22 ; ev n=Ds5, i=7, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 16
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F	@ 17
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=27, fx=FX_VOLSLIDE, p=0x0F	@ 18
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=28, fx=FX_VOLUME, p=0x0F	@ 19
	ev n=E_6, i=21 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=29, fx=FX_VOLSLIDE, p=0x0F	@ 20
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=30, fx=FX_VOLUME, p=0x0F	@ 21
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=31, fx=FX_VOLSLIDE, p=0x0F	@ 22
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=32, fx=FX_VOLUME, p=0x0F	@ 23
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=33, fx=FX_VOLSLIDE, p=0x0F	@ 24
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F	@ 25
	ev n=E_6, i=22 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=28, fx=FX_VOLSLIDE, p=0x0F	@ 26
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F	@ 27
	ev n=E_6, i=21 ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 28
	ev ; ev ; ev ; ev n=A_3, i=26, fx=FX_VOLUME, p=0x0F	@ 29
	ev n=E_6, i=22 ; ev ; ev ; ev n=A_3, i=32, fx=FX_VOLSLIDE, p=0x0F	@ 30
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=A_3, i=29, fx=FX_VOLUME, p=0x0F	@ 31
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 32
	ev ; ev ; ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F	@ 33
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=27, fx=FX_VOLSLIDE, p=0x0F	@ 34
	ev ; ev ; ev ; ev n=D_3, i=28, fx=FX_VOLUME, p=0x0F	@ 35
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=29, fx=FX_VOLSLIDE, p=0x0F	@ 36
	ev ; ev ; ev ; ev n=D_3, i=30, fx=FX_VOLUME, p=0x0F	@ 37
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=31, fx=FX_VOLSLIDE, p=0x0F	@ 38
	ev ; ev ; ev ; ev n=D_3, i=32, fx=FX_VOLUME, p=0x0F	@ 39
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=33, fx=FX_VOLSLIDE, p=0x0F	@ 40
	ev ; ev ; ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F	@ 41
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=28, fx=FX_VOLSLIDE, p=0x0F	@ 42
	ev ; ev ; ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F	@ 43
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 44
	ev ; ev ; ev ; ev n=D_3, i=26, fx=FX_VOLUME, p=0x0F	@ 45
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_3, i=32, fx=FX_VOLSLIDE, p=0x0F	@ 46
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_3, i=29, fx=FX_VOLUME, p=0x0F	@ 47
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 48
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F	@ 49
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=27, fx=FX_VOLSLIDE, p=0x0F	@ 50
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=28, fx=FX_VOLUME, p=0x0F	@ 51
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=29, fx=FX_VOLSLIDE, p=0x0F	@ 52
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=30, fx=FX_VOLUME, p=0x0F	@ 53
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=31, fx=FX_VOLSLIDE, p=0x0F	@ 54
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=32, fx=FX_VOLUME, p=0x0F	@ 55
	ev n=E_6, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=33, fx=FX_VOLSLIDE, p=0x0F	@ 56
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F	@ 57
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=28, fx=FX_VOLSLIDE, p=0x0F	@ 58
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F	@ 59
	ev n=E_6, i=21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_3, i=25, fx=FX_VOLSLIDE, p=0x0F	@ 60
	ev ; ev ; ev ; ev n=G_3, i=26, fx=FX_VOLUME, p=0x0F	@ 61
	ev n=E_6, i=22 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=G_3, i=32, fx=FX_VOLSLIDE, p=0x0F	@ 62
	ev n=E_6, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_JUMP, p=0x1D ; ev ; ev n=G_3, i=29, fx=FX_VOLUME, p=0x0F	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat043_rows:				@ 08331A8C
	@ pattern 043: 64 rows, played at order 54
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev fx=FX_SPEED, p=0x04 ; ev fx=FX_STORE, p=0x95 ; ev n=C_4, i=40, fx=FX_VOLUME, p=0x10	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 54
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 56
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 58
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 59
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev	@ 60
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat044_rows:				@ 08331C18
	@ pattern 044: 64 rows, played at order 56
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_5, i=40	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_7-15, i=42 ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=Ds7-15, i=42 ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_5, i=40	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 54
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 56
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 58
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 59
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
hp_pat045_rows:				@ 08331E24
	@ pattern 045: 64 rows, played at order 55
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_STORE, p=0x95 ; ev	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev n=C_6, i=41	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev n=C_6, i=41	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev n=C_6, i=41	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev n=C_5, i=40	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_5, i=40	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat046_rows:				@ 08331FA0
	@ pattern 046: 64 rows, played at order 57
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_5, i=40	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_7-15, i=42 ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=Ds7-15, i=42 ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_5, i=40	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 54
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 56
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=40	@ 58
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 59
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat047_rows:				@ 083321B0
	@ pattern 047: 64 rows, played at order 58
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_7-15, i=42 ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=Ds7-15, i=42 ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 54
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 56
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 58
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 59
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat048_rows:				@ 083323D0
	@ pattern 048: 64 rows, played at order 59
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_7-15, i=42 ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_7-15, i=42 ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev n=Ds7-15, i=42 ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 50
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=40	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat049_rows:				@ 083325E8
	@ pattern 049: 64 rows, played at order 60
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=A_6, i=35 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLSLIDE, p=0x03 ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLSLIDE, p=0x03 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLSLIDE, p=0x03 ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev ; ev n=A_6, i=35 ; ev n=G_4, i=6 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 12
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 18
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=C_7-15, i=42 ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=D_7-15, i=42 ; ev ; ev	@ 30
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev ; ev n=Ds7-15, i=42 ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev n=Fs6, i=35 ; ev n=F_4, i=6 ; ev	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 44
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 50
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=F_4, i=6 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat050_rows:				@ 083327C8
	@ pattern 050: 64 rows, played at order 61
	ev fx=FX_VOLUME, p=0x00 ; ev n=A_6, i=35 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6, i=41	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev ; ev n=A_6, i=35 ; ev n=G_4, i=6 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 12
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=C_7-15, i=42 ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=A_6, i=35 ; ev ; ev n=C_6, i=41	@ 18
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=C_7-15, i=42 ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=D_7-15, i=42 ; ev ; ev	@ 30
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev ; ev n=Ds7-15, i=42 ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev n=Fs6, i=35 ; ev n=F_4, i=6 ; ev	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=40	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 44
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=As6-15, i=42 ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=Fs6, i=35 ; ev ; ev n=C_6, i=41	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat051_rows:				@ 08332988
	@ pattern 051: 64 rows, played at order 62
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 52
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 54
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 56
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 58
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 59
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat052_rows:				@ 08332B60
	@ pattern 052: 64 rows, played at order 63
	ev n=G_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_STORE, p=0x95 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_4, i=6 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=F_5, i=6, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41, fx=FX_SPEED, p=0x04	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_6, i=41	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_4, i=6 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x05	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x0A	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=C_5, i=40, fx=FX_NOP10, p=0x14	@ 52
	ev n=B_9-64, i=0 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 53
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 54
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 56
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 57
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 58
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 59
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x30 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 60
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x3A ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 62
	ev fx=FX_JUMP, p=0x36 ; ev ; ev ; ev	@ 63
hp_pat053_rows:				@ 08332D34
	@ pattern 053: 64 rows, played at order 65
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev fx=FX_VOLUME, p=0x00 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_7+14, i=43 ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=Fs6-16, i=39 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Cs6-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_7+14, i=43 ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat054_rows:				@ 08332F34
	@ pattern 054: 64 rows, played at order 66
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev ; ev n=F_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=F_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev n=F_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev n=F_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev n=G_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev ; ev n=G_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_7+14, i=43 ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=B_6-16, i=39 ; ev ; ev n=G_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Ds7-16, i=39 ; ev ; ev n=G_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_7+14, i=43 ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat055_rows:				@ 08333134
	@ pattern 055: 64 rows, played at orders 67, 73
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev fx=FX_STORE, p=0x95 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40 ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=Fs6-16, i=39 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Cs6-16, i=39 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_7+14, i=43 ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat056_rows:				@ 0833334C
	@ pattern 056: 64 rows, played at orders 68, 74
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev fx=FX_STORE, p=0x95 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40 ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev ; ev n=F_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=F_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev n=F_6, i=40 ; ev n=F_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev n=F_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev n=G_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=43 ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=B_6-16, i=39 ; ev n=F_6, i=40 ; ev n=G_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Ds7-16, i=39 ; ev n=F_6, i=40 ; ev n=G_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_7+14, i=43 ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat057_rows:				@ 08333568
	@ pattern 057: 64 rows, played at order 69
	ev n=E_7, i=34 ; ev fx=FX_STORE, p=0x95 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=C_7, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=A_6, i=34 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=E_7, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_7, i=34 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=E_7, i=34 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=A_7, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=E_7, i=34 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=D_7, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=B_6, i=34 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=B_6, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_7, i=34 ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=D_7, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=B_6, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_7, i=34 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=D_7, i=34 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_7, i=34 ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=B_6, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=G_6, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_7+14, i=43 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat058_rows:				@ 0833375C
	@ pattern 058: 64 rows, played at order 70
	ev n=B_6, i=34 ; ev fx=FX_STORE, p=0x95 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=A_6, i=34 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=G_6, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=B_6, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_7, i=34 ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=G_7, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7, i=34 ; ev ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=G_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_7, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=B_6, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=G_6, i=34 ; ev ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=A_6, i=34 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=G_6, i=34 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=A_6, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=B_6, i=34 ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_7, i=34 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=B_6, i=34 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=A_6, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=G_6, i=34 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=A_6, i=34 ; ev ; ev n=G_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=43 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x04 ; ev n=F_6, i=40 ; ev n=A_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=G_6, i=34, fx=FX_VOLUME, p=0x04 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x04 ; ev n=F_6, i=40 ; ev n=A_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=A_7+14, i=43 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat059_rows:				@ 08333950
	@ pattern 059: 64 rows, played at order 71
	ev n=E_7, i=34 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=D_7, i=34 ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=C_7, i=34 ; ev n=E_4, i=23 ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 07
	ev n=A_6, i=34 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=E_7, i=34 ; ev n=E_4, i=24, fx=FX_STORE, p=0x95 ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev n=E_7, i=34 ; ev n=E_4, i=23, fx=FX_STORE, p=0x95 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=A_7, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=E_7, i=34 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=D_7, i=34 ; ev n=E_4, i=24 ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=E_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_6, i=40 ; ev	@ 30
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 31
	ev n=B_6, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=B_6, i=34 ; ev n=D_4, i=23 ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 39
	ev n=D_7, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=B_6, i=34 ; ev n=D_4, i=24 ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev n=D_7, i=34 ; ev n=D_4, i=23 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=C_7, i=34 ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=B_6, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=G_6, i=34 ; ev n=D_4, i=23 ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=C_7+14, i=43 ; ev	@ 62
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat060_rows:				@ 08333B74
	@ pattern 060: 64 rows, played at order 72
	ev n=B_6, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=A_6, i=34 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=G_6, i=34 ; ev n=D_4, i=23 ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 07
	ev n=B_6, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=C_7, i=34 ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=G_7, i=34 ; ev n=D_4, i=24 ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev n=D_7, i=34 ; ev n=D_4, i=23 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=G_7, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_7, i=34 ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=B_6, i=34 ; ev n=F_6, i=40 ; ev n=C_6+14, i=43 ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=C_7, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=G_6, i=34 ; ev n=D_4, i=23 ; ev n=C_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev n=B_6, i=34, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=A_6, i=34 ; ev ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=G_6, i=34 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=A_6, i=34 ; ev n=D_4, i=23 ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=B_6, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 39
	ev n=C_7, i=34 ; ev n=F_6, i=40 ; ev n=D_6+14, i=43 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=B_6, i=34 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=A_6, i=34 ; ev ; ev n=D_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=G_6, i=34 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=A_6, i=34 ; ev n=A_4, i=23 ; ev n=G_6+14, i=43 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=G_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=40, fx=FX_VOLUME, p=0x0A ; ev n=G_7+14, i=43 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x04 ; ev n=F_6, i=40 ; ev n=A_6+14, i=43 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=G_6, i=34, fx=FX_VOLUME, p=0x04 ; ev n=F_6, i=40 ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=A_6, i=34, fx=FX_VOLUME, p=0x04 ; ev n=F_6, i=40 ; ev n=A_7+14, i=43 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev n=F_6, i=40 ; ev ; ev	@ 61
	ev ; ev n=F_6, i=40 ; ev n=A_7+14, i=43 ; ev	@ 62
	ev ; ev n=F_6, i=40 ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat061_rows:				@ 08333D94
	@ pattern 061: 64 rows, played at order 75
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=D_3, i=9 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev n=D_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev n=D_3, i=11 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=12 ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev n=D_3, i=13 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=14 ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A ; ev n=C_3, i=9 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=C_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev n=C_3, i=11 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=12 ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev n=C_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev ; ev n=C_3, i=13 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=Fs6-16, i=39 ; ev ; ev ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=14 ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Cs6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
hp_pat062_rows:				@ 08333FA0
	@ pattern 062: 64 rows, played at order 76
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=D_3, i=9 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev n=D_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev n=D_3, i=11 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=12 ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev n=D_3, i=13 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_3, i=14 ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x1A ; ev n=F_3, i=9 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=F_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev n=F_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev n=F_3, i=11 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_3, i=12 ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x15 ; ev n=C_3, i=32 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=33 ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev ; ev n=C_3, i=31 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=30 ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=B_6-16, i=39 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=C_3, i=29 ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=32 ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Ds7-16, i=39 ; ev ; ev n=C_3, i=31 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_3, i=32 ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat063_rows:				@ 083341C4
	@ pattern 063: 64 rows, played at order 77
	ev n=A_5, i=2 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=D_3, i=9 ; ev n=F_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=A_5, i=2 ; ev ; ev n=D_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=A_4+20, i=8 ; ev ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=F_6, i=40 ; ev ; ev n=D_3, i=11 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=A_4+20, i=8 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=A_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=D_3, i=12 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=A_4+20, i=8, fx=FX_VOLUME, p=0x20 ; ev ; ev n=D_3, i=13 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=A_5, i=2, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=F_6, i=40 ; ev ; ev ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=A_4+20, i=8 ; ev ; ev n=D_3, i=14 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=A_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=G_5, i=2 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A ; ev n=F_3, i=9 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=G_5, i=2 ; ev ; ev n=F_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=G_4+20, i=8 ; ev ; ev n=F_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=F_6, i=40 ; ev ; ev n=F_3, i=11 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=G_4+20, i=8 ; ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=G_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=F_3, i=12 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=32 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_3, i=33 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=31 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=G_4+20, i=8 ; ev ; ev n=C_3, i=30 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_6, i=40 ; ev ; ev n=C_3, i=29 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=C_3, i=32 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=G_4+20, i=8 ; ev ; ev n=C_3, i=31 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=C_3, i=32 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat064_rows:				@ 0833439C
	@ pattern 064: 64 rows, played at order 78
	ev n=A_5, i=2 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=D_3, i=9 ; ev n=F_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=A_5, i=2 ; ev ; ev n=D_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=A_4+20, i=8 ; ev ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=F_6, i=40 ; ev ; ev n=D_3, i=11 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=A_4+20, i=8 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=A_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=D_3, i=12 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=A_4+20, i=8, fx=FX_VOLUME, p=0x20 ; ev ; ev n=D_3, i=13 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=A_5, i=2 ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=F_6, i=40 ; ev ; ev ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=A_4+20, i=8 ; ev ; ev n=D_3, i=14 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=A_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=B_5, i=2 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x1A ; ev n=F_3, i=9 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=B_5, i=2 ; ev ; ev n=F_3, i=10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_5+20, i=8 ; ev ; ev n=F_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=F_6, i=40 ; ev ; ev n=F_3, i=11 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_5+20, i=8 ; ev ; ev n=F_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=B_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=F_3, i=12 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x00 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x15 ; ev n=C_3, i=32 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=D_6, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_3, i=33 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_4+20, i=8, fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=31 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=D_6, i=2, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_3, i=30 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_6, i=40 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=C_3, i=29 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_5+20, i=8 ; ev ; ev n=C_3, i=32 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=D_6, i=2 ; ev ; ev n=C_3, i=31 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=D_4+20, i=8 ; ev ; ev n=C_3, i=32 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat065_rows:				@ 08334584
	@ pattern 065: 64 rows, played at order 79
	ev n=A_5, i=2 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=A_5, i=2 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=A_4+20, i=8 ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=F_6, i=40 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=A_4+20, i=8 ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=A_5, i=2 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=A_4+20, i=8, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=A_5, i=2, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=F_6, i=40 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=A_4+20, i=8 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=A_5, i=2 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=G_5, i=2 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=G_5, i=2 ; ev ; ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=G_4+20, i=8 ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=F_6, i=40 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=G_4+20, i=8 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=G_5, i=2 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=As5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=G_5, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=A_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=G_5, i=2, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=G_4+20, i=8 ; ev ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=F_6, i=40 ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=G_4+20, i=8 ; ev ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=F_5+13, i=4 ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat066_rows:				@ 08334750
	@ pattern 066: 64 rows, played at order 80
	ev n=A_5, i=2 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=A_5, i=2 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=A_4+20, i=8 ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=F_6, i=40 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=A_4+20, i=8 ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=A_5, i=2 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=A_5, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=A_4+20, i=8, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=A_5, i=2 ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=F_6, i=40 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=A_4+20, i=8 ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=A_5, i=2 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=B_5, i=2 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x1A ; ev n=F_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=B_5, i=2 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=C_5+20, i=8 ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=F_6, i=40 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_5+20, i=8 ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=B_5, i=2 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x00 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x15 ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=D_6, i=2, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_4+20, i=8, fx=FX_VOLUME, p=0x00 ; ev ; ev n=As5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=D_6, i=2, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=F_6, i=40 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=A_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_5+20, i=8 ; ev ; ev n=As5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=D_6, i=2 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=D_4+20, i=8 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat067_rows:				@ 08334930
	@ pattern 067: 64 rows, played at order 81
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev n=As5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev ; ev n=A_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=Fs6-16, i=39 ; ev ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Cs6-16, i=39 ; ev ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
hp_pat068_rows:				@ 08334B38
	@ pattern 068: 64 rows, played at order 82
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev n=G_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x1A ; ev n=F_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x15 ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=As5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=21	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=C_6, i=40	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=B_6-16, i=39 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=40	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=As5+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=40	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=C_6, i=40	@ 59
	ev n=Ds7-16, i=39 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=40	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=C_6, i=40	@ 61
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_6+15, i=44, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=40	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=C_6, i=40	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat069_rows:				@ 08334D6C
	@ pattern 069: 64 rows, played at order 87
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45, fx=FX_SPEED, p=0x05	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev n=G_5, i=45	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev n=Ds6-15, i=42 ; ev fx=FX_PORTA_UP, p=0x02	@ 26
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=F_6-15, i=42 ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=C_6, i=45, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=45	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=45	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev n=D_6, i=45, fx=FX_OFFSET, p=0x0A	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=45	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev n=D_6, i=45	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev n=D_7+14, i=43 ; ev n=Ds6-15, i=42 ; ev n=C_6, i=45	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=F_6-15, i=42 ; ev n=B_5, i=45	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat070_rows:				@ 08334FA0
	@ pattern 070: 64 rows, played at order 83
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev ; ev	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev ; ev	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev ; ev	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev ; ev	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev ; ev	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=Fs6-16, i=39 ; ev ; ev ; ev	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 59
	ev n=Cs6-16, i=39 ; ev ; ev ; ev	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 61
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat071_rows:				@ 0833513C
	@ pattern 071: 64 rows, played at order 84
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x15 ; ev ; ev	@ 00
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 01
	ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=Gs6-16, i=39 ; ev ; ev ; ev	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 09
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 11
	ev n=Cs7-16, i=39 ; ev ; ev ; ev	@ 12
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 15
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 16
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 17
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=Gs6-16, i=39 ; ev ; ev ; ev	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 25
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 27
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 28
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 31
	ev n=B_6-16, i=39, fx=FX_SPEED, p=0x03 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 32
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 33
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=B_6-16, i=39 ; ev ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=As6-16, i=39 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=Fs6-16, i=39 ; ev ; ev ; ev	@ 40
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 41
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 43
	ev n=Cs7-16, i=39 ; ev ; ev ; ev	@ 44
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 45
	ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 47
	ev n=B_6-16, i=39 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x15 ; ev ; ev n=F_6, i=41	@ 48
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev n=F_6, i=41	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=As6-16, i=39 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=B_6-16, i=39 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=F_6, i=41	@ 56
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 57
	ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=F_6, i=41	@ 58
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 59
	ev n=Ds7-16, i=39 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=F_6, i=41	@ 60
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev	@ 61
	ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=F_6, i=41	@ 62
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev fx=FX_JUMP, p=0x41	@ 63
hp_pat072_rows:				@ 083352F4
	@ pattern 072: 64 rows, played at order 86
	ev n=D_6+14, i=43 ; ev ; ev ; ev n=G_5, i=45, fx=FX_SPEED, p=0x05	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=D_6+14, i=43 ; ev ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_6-15, i=42 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev ; ev ; ev n=A_5, i=45	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev ; ev n=C_6-15, i=42 ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev ; ev ; ev n=A_5, i=45	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev ; ev n=A_5, i=45	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev ; ev ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=C_6-15, i=42 ; ev n=G_5, i=45	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev n=Ds6-15, i=42 ; ev fx=FX_PORTA_UP, p=0x02	@ 26
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 27
	ev ; ev ; ev n=F_6-15, i=42 ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=D_6+14, i=43 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x00 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev n=G_5, i=45	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev n=D_7+14, i=43 ; ev n=Ds6-15, i=42 ; ev fx=FX_PORTA_UP, p=0x02	@ 58
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 59
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=F_6-15, i=42 ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat073_rows:				@ 083354CC
	@ pattern 073: 64 rows, played at order 88
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45, fx=FX_SPEED, p=0x05	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev n=G_5, i=45	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev n=A_7, i=35 ; ev n=D_7+14, i=43 ; ev n=Ds6-15, i=42 ; ev fx=FX_PORTA_UP, p=0x02	@ 26
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 27
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=F_6-15, i=42 ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_5, i=40 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev ; ev n=C_6, i=45, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=45	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=45	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev n=D_6, i=45, fx=FX_OFFSET, p=0x0A	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=45	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev n=C_5, i=40 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev n=D_6, i=45	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev n=A_7, i=35 ; ev n=D_7+14, i=43 ; ev n=Ds6-15, i=42 ; ev n=C_6, i=45	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=F_6-15, i=42 ; ev n=B_5, i=45	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat074_rows:				@ 08335738
	@ pattern 074: 64 rows, played at order 89
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45, fx=FX_SPEED, p=0x05	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 08
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev n=G_5, i=45	@ 24
	ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev n=A_7, i=35 ; ev n=D_7+14, i=43 ; ev n=Ds6-15, i=42 ; ev fx=FX_PORTA_UP, p=0x02	@ 26
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 27
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=F_6-15, i=42 ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev ; ev n=G_5, i=45	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=A_7, i=35 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev n=A_7, i=35 ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_5, i=40 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev n=C_6-15, i=42 ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev ; ev n=C_6, i=45, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=45	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev n=A_7, i=35 ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev ; ev ; ev n=C_6, i=45	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev ; ev ; ev n=D_6, i=45, fx=FX_OFFSET, p=0x0A	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev n=E_6, i=45	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6-15, i=42 ; ev n=D_6, i=45	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Ds6-15, i=42 ; ev n=C_6, i=45	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev n=F_6-15, i=42 ; ev n=B_5, i=45	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=G_5, i=45	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat075_rows:				@ 08335988
	@ pattern 075: 64 rows, played at orders 90, 94
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=G_5+14, i=43, fx=FX_STORE, p=0x95 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x10 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=G_5+14, i=43 ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=G_5+14, i=43 ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_5, i=41 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev n=G_5+14, i=43 ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev n=G_6+14, i=43 ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=G_5+14, i=43 ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat076_rows:				@ 08335B4C
	@ pattern 076: 64 rows, played at orders 91, 95
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=G_5+14, i=43, fx=FX_STORE, p=0x95 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x10 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=G_5+14, i=43 ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=G_5+14, i=43 ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_5, i=41 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev n=G_5+14, i=43 ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev n=G_6+14, i=43 ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=G_5+14, i=43 ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat077_rows:				@ 08335D10
	@ pattern 077: 64 rows, played at order 92
	ev ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A	@ 06
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 07
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x20	@ 08
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 10
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=B_5, i=47, fx=FX_VOLUME, p=0x0A	@ 12
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 13
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 14
	ev n=B_5, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A	@ 16
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 18
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 20
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A	@ 22
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x20	@ 24
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 26
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x10	@ 28
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x10	@ 30
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 31
	ev ; ev n=G_5+14, i=43, fx=FX_STORE, p=0x95 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 32
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 33
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6, i=47, fx=FX_VOLUME, p=0x0A	@ 34
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 36
	ev n=A_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=G_5+14, i=43 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A	@ 38
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 39
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x20	@ 40
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=G_5, i=47, fx=FX_VOLUME, p=0x20	@ 42
	ev n=A_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=G_5+14, i=43 ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x0A	@ 44
	ev n=G_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 45
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 46
	ev n=A_5, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A	@ 48
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 50
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev ; ev n=G_5+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 52
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 53
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_6, i=47, fx=FX_VOLUME, p=0x0A	@ 54
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 56
	ev n=A_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev n=G_6+14, i=43 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x20	@ 58
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 59
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x10	@ 60
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev ; ev n=G_5+14, i=43 ; ev ; ev n=G_5, i=47, fx=FX_VOLUME, p=0x10	@ 62
	ev n=A_5, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat078_rows:				@ 08335F98
	@ pattern 078: 64 rows, played at order 93
	ev ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 02
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A	@ 06
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 07
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x20	@ 08
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 10
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=B_5, i=47, fx=FX_VOLUME, p=0x0A	@ 12
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 13
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 14
	ev n=B_5, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A	@ 16
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 18
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 20
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A	@ 22
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x20	@ 24
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 26
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x10	@ 28
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x10	@ 30
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 31
	ev ; ev n=G_5+14, i=43, fx=FX_STORE, p=0x95 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 32
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev n=A_6, i=47, fx=FX_VOLUME, p=0x0A	@ 34
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 35
	ev ; ev ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 36
	ev n=A_6, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 37
	ev ; ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A	@ 38
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 39
	ev ; ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x20	@ 40
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev n=G_5, i=47, fx=FX_VOLUME, p=0x20	@ 42
	ev n=A_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x0A	@ 44
	ev n=G_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 46
	ev n=A_5, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 47
	ev ; ev ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A	@ 48
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20	@ 50
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 52
	ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev n=A_6, i=47, fx=FX_VOLUME, p=0x0A	@ 54
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 55
	ev ; ev ; ev ; ev n=E_6, i=47, fx=FX_VOLUME, p=0x20	@ 56
	ev n=A_6, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev n=D_6, i=47, fx=FX_VOLUME, p=0x20	@ 58
	ev n=E_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x10	@ 60
	ev n=D_6, i=47, fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev n=G_5, i=47, fx=FX_VOLUME, p=0x10	@ 62
	ev n=A_5, i=47, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat079_rows:				@ 083361E0
	@ pattern 079: 64 rows, played at order 96
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=45, fx=FX_SPEED, p=0x05	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=G_5, i=45	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 26
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=G_5+14, i=43, fx=FX_STORE, p=0x95 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=45, fx=FX_SPEED, p=0x05	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=45, fx=FX_OFFSET, p=0x0A	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=G_5+14, i=43 ; ev ; ev n=D_6, i=45, fx=FX_VOLUME, p=0x0A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=45	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=G_5+14, i=43 ; ev ; ev n=D_6, i=45, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_5, i=41 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=45	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=45	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev n=G_5+14, i=43 ; ev ; ev n=C_6, i=45, fx=FX_OFFSET, p=0x0A	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=45, fx=FX_VOLUME, p=0x0A	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=45	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev n=G_6+14, i=43 ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 58
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 59
	ev ; ev n=D_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_6, i=45, fx=FX_OFFSET, p=0x0A	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=G_5+14, i=43 ; ev ; ev n=C_6, i=45, fx=FX_VOLUME, p=0x0A	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat080_rows:				@ 083363FC
	@ pattern 080: 64 rows, played at order 97
	ev n=C_5, i=41 ; ev n=D_6+14, i=43, fx=FX_STORE, p=0x95 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev n=G_5, i=45, fx=FX_SPEED, p=0x05	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 03
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 09
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev ; ev n=A_5, i=45	@ 14
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 15
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 16
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 17
	ev n=C_5, i=41 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_5, i=45	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 19
	ev n=C_5, i=41 ; ev n=D_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=45, fx=FX_OFFSET, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_5, i=45, fx=FX_VOLUME, p=0x0A	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=45	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 25
	ev ; ev n=D_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_PORTA_UP, p=0x02	@ 26
	ev ; ev ; ev ; ev fx=FX_PORTA_UP, p=0x02	@ 27
	ev ; ev n=A_7+14, i=36, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_5, i=45, fx=FX_OFFSET, p=0x0A	@ 28
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 29
	ev ; ev n=D_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=G_5, i=45, fx=FX_VOLUME, p=0x0A	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=41 ; ev n=G_5+14, i=43, fx=FX_STORE, p=0x95 ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=45	@ 32
	ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x20 ; ev	@ 33
	ev ; ev ; ev n=C_5, i=47, fx=FX_VOLUME, p=0x20 ; ev n=D_6, i=45, fx=FX_OFFSET, p=0x0A	@ 34
	ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x0A ; ev	@ 35
	ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x0A ; ev	@ 36
	ev ; ev ; ev n=C_5, i=47, fx=FX_VOLUME, p=0x0A ; ev	@ 37
	ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x05 ; ev n=D_6, i=45, fx=FX_VOLUME, p=0x0A	@ 38
	ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev ; ev n=C_5, i=47, fx=FX_VOLUME, p=0x05 ; ev n=D_6, i=45	@ 40
	ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x02 ; ev	@ 41
	ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x02 ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=47, fx=FX_VOLUME, p=0x02 ; ev	@ 43
	ev ; ev ; ev n=A_5, i=47, fx=FX_VOLUME, p=0x01 ; ev n=F_6, i=45, fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev n=E_5, i=47, fx=FX_VOLUME, p=0x01 ; ev	@ 45
	ev n=C_5, i=41 ; ev ; ev n=C_5, i=47, fx=FX_VOLUME, p=0x01 ; ev n=F_6, i=45	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_5, i=41 ; ev ; ev ; ev n=F_6, i=45	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=41 ; ev ; ev ; ev n=G_6, i=45, fx=FX_OFFSET, p=0x0A	@ 52
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 53
	ev n=C_5, i=40 ; ev ; ev ; ev n=A_6, i=45	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x2A ; ev ; ev ; ev n=G_6, i=45	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=F_6, i=45	@ 58
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev	@ 59
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=E_6, i=45	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev n=C_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev ; ev n=C_6, i=45	@ 62
	ev ; ev ; ev fx=FX_JUMP, p=0x56 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat081_rows:				@ 08336628
	@ pattern 081: 64 rows, played at order 99
	ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 03
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 05
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 07
	ev n=C_5, i=23 ; ev ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs3, i=23 ; ev ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 19
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 21
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 23
	ev n=As4, i=23 ; ev n=As3, i=23 ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 35
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 37
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 39
	ev n=C_5, i=23 ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs3, i=23 ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_5, i=24 ; ev ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 51
	ev n=Ds5, i=24 ; ev ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 53
	ev n=Ds5, i=23 ; ev ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 55
	ev n=C_5, i=24 ; ev n=As3, i=23 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=As4, i=23 ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat082_rows:				@ 08336798
	@ pattern 082: 64 rows, played at order 100
	ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x20 ; ev	@ 00
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x11 ; ev	@ 01
	ev n=C_5, i=24 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x0A	@ 03
	ev n=C_5, i=24 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x10	@ 04
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 05
	ev n=C_5, i=24 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 06
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 07
	ev n=C_5, i=23 ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 08
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 09
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 10
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 11
	ev n=C_5, i=24 ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 12
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 13
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 14
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 15
	ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs3, i=23 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 16
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 17
	ev n=C_5, i=24 ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 18
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 19
	ev n=C_5, i=24 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 20
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 21
	ev n=C_5, i=24 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 22
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 23
	ev n=As4, i=23 ; ev n=As3, i=23 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 24
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 25
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 26
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 27
	ev n=C_5, i=24 ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 28
	ev ; ev ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 29
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 30
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 31
	ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00	@ 32
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 33
	ev n=C_5, i=24 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 34
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 35
	ev n=C_5, i=24 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 36
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 37
	ev n=C_5, i=24 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 38
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 39
	ev n=C_5, i=23 ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 40
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 41
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 42
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 43
	ev n=C_5, i=24 ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 44
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 45
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 46
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 47
	ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Ds4, i=23 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 48
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 49
	ev n=C_5, i=24 ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 50
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 51
	ev n=Ds5, i=24 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 52
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 53
	ev n=Ds5, i=23 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 54
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 55
	ev n=C_5, i=24 ; ev n=F_4, i=23 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 56
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 57
	ev ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 58
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 59
	ev n=As4, i=23 ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 60
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 61
	ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=G_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 62
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat083_rows:				@ 08336AFC
	@ pattern 083: 64 rows, played at order 101
	ev n=C_5, i=23 ; ev n=C_4, i=23 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x20 ; ev	@ 00
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x10 ; ev	@ 01
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 02
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x0A	@ 03
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x30	@ 04
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 05
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 06
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 07
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 08
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 09
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 10
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 11
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 12
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 13
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 14
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 15
	ev n=Gs4, i=23 ; ev n=Gs3, i=23 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 16
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 17
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 18
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 19
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 20
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 21
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 22
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 23
	ev n=As4, i=23 ; ev n=As3, i=23 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 24
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 25
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 26
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 27
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 28
	ev ; ev ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 29
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 30
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 31
	ev n=C_5, i=23 ; ev n=C_4, i=23 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00	@ 32
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 33
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 34
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 35
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 36
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 37
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 38
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 39
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 40
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00	@ 41
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 42
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 43
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 44
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 45
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 46
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 47
	ev n=Ds5, i=23 ; ev n=Ds4, i=23 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 48
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 49
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00	@ 50
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 51
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 52
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 53
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 54
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 55
	ev n=C_6, i=38, fx=FX_VOLUME, p=0x10 ; ev n=F_4, i=23 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 56
	ev n=C_6, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 57
	ev n=C_6, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 58
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00	@ 59
	ev n=C_6, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 60
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 61
	ev n=C_6, i=38, fx=FX_VOLUME, p=0x30 ; ev ; ev n=G_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 62
	ev n=C_6, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat084_rows:				@ 08336E2C
	@ pattern 084: 64 rows, played at order 102
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x10 ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 03
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 04
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 05
	ev n=F_6+14, i=36 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 06
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 07
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 08
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A	@ 11
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 17
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 19
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 20
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 22
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 25
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 30
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 35
	ev ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 36
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 37
	ev n=F_6+14, i=36 ; ev ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 38
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 39
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 40
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x0A	@ 43
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 49
	ev ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 51
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 52
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 54
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 55
	ev ; ev n=As4, i=23 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 57
	ev ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 58
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 59
	ev ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 61
	ev ; ev ; ev n=G_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x30	@ 62
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat085_rows:				@ 0833710C
	@ pattern 085: 64 rows, played at order 103
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=B_4-16, i=39 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 03
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_TONEPORTA, p=0x03 ; ev	@ 08
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 11
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 17
	ev ; ev ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev ; ev n=E_5-16, i=39 ; ev n=C_5, i=46	@ 22
	ev ; ev ; ev n=Fs5-16, i=39, fx=FX_TONEPORTA, p=0x20 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=G_5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Fs5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 25
	ev ; ev ; ev n=G_5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Fs5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_5-16, i=39 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_PORTA_UP, p=0x02 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev ; ev n=B_5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=Ds6-16, i=39, fx=FX_PORTA_UP, p=0x02 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev ; ev fx=FX_VIBRATO, p=0x93 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 37
	ev n=F_6+14, i=36 ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46	@ 38
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 39
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 40
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev n=Fs6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=G_6-16, i=39, fx=FX_TONEPORTA, p=0x20 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev n=Fs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 49
	ev ; ev ; ev n=D_6-16, i=39 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev ; ev fx=FX_VIBRATO, p=0x93 ; ev n=C_5, i=46	@ 51
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_5, i=46	@ 54
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 55
	ev ; ev n=As4, i=23 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 56
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev n=C_6, i=46	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 62
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat086_rows:				@ 08337350
	@ pattern 086: 64 rows, played at order 104
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=B_4-16, i=39 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 03
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev ; ev n=E_5-16, i=39, fx=FX_TONEPORTA, p=0x03 ; ev	@ 08
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 11
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 17
	ev ; ev ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev ; ev n=E_5-16, i=39 ; ev n=C_5, i=46	@ 22
	ev ; ev ; ev n=Fs5-16, i=39, fx=FX_TONEPORTA, p=0x20 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=G_5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Fs5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 25
	ev ; ev ; ev n=G_5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Fs5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_5-16, i=39 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_PORTA_UP, p=0x02 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev ; ev n=B_5-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=Ds6-16, i=39, fx=FX_PORTA_UP, p=0x02 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev ; ev fx=FX_VIBRATO, p=0x93 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 37
	ev n=F_6+14, i=36 ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46	@ 38
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 39
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 40
	ev ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev n=Fs6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Ds4, i=23 ; ev n=G_6-16, i=39, fx=FX_TONEPORTA, p=0x20 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev n=Fs6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 49
	ev ; ev ; ev n=G_6-16, i=39 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev ; ev n=Fs6-16, i=39, fx=FX_VIBRATO, p=0x93 ; ev n=C_5, i=46	@ 51
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_TONEPORTA, p=0x20 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev n=G_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev ; ev n=A_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=C_5, i=46	@ 54
	ev ; ev ; ev n=G_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev	@ 55
	ev ; ev n=F_4, i=23 ; ev n=B_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev n=A_6-16, i=39, fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev n=B_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=C_6, i=46	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev n=A_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=G_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev ; ev n=B_6-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev n=G_7-16, i=39, fx=FX_VOLSLIDE, p=0x05 ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat087_rows:				@ 083375C8
	@ pattern 087: 64 rows, played at order 105
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46	@ 03
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev ; ev n=C_6, i=46	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 07
	ev ; ev n=C_5, i=23 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 11
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs3, i=23 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=24 ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev n=C_5, i=24 ; ev ; ev n=C_5, i=46	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=As3, i=23 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 25
	ev ; ev ; ev ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev ; ev	@ 34
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev ; ev n=C_6, i=46	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 39
	ev ; ev n=C_5, i=23 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 43
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs3, i=23 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=24 ; ev ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_5, i=46	@ 51
	ev ; ev n=Ds5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev n=Ds5, i=23 ; ev ; ev n=C_5, i=46	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_5, i=24 ; ev n=As3, i=23 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat088_rows:				@ 08337808
	@ pattern 088: 64 rows, played at order 106
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46	@ 03
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 05
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev ; ev n=C_6, i=46	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 07
	ev ; ev n=C_5, i=23 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 11
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs3, i=23 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=24 ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev n=C_5, i=24 ; ev ; ev n=C_5, i=46	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=As3, i=23 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 25
	ev ; ev ; ev ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=C_4, i=23 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev ; ev	@ 34
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev ; ev n=C_6, i=46	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 39
	ev ; ev n=C_5, i=23 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 43
	ev ; ev n=C_5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=Gs4, i=23 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=24 ; ev ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=C_5, i=46	@ 51
	ev ; ev n=Ds5, i=24 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev n=Ds5, i=23 ; ev ; ev n=C_5, i=46	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_5, i=24 ; ev n=As4, i=23 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat089_rows:				@ 08337A54
	@ pattern 089: 64 rows, played at order 107
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x11 ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 02
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 03
	ev ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 05
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 07
	ev ; ev n=C_5, i=23 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 08
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 11
	ev ; ev n=C_5, i=24 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 17
	ev ; ev n=C_5, i=24 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 19
	ev ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 25
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 30
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 35
	ev ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 37
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 39
	ev ; ev n=C_5, i=23 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 40
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 43
	ev ; ev n=C_5, i=24 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 49
	ev ; ev n=C_5, i=24 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 51
	ev ; ev n=Ds5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev n=Ds5, i=23 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 55
	ev ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 56
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=G_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 62
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat090_rows:				@ 08337D84
	@ pattern 090: 64 rows, played at order 108
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=A_4-16, i=39, fx=FX_VOLUME, p=0x20 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x11 ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 02
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 03
	ev ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 05
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 07
	ev ; ev n=C_5, i=23 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 08
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 11
	ev ; ev n=C_5, i=24 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 16
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 17
	ev ; ev n=C_5, i=24 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 19
	ev ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_5, i=46	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 25
	ev ; ev ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_8-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 30
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06 ; ev n=B_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 35
	ev ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 37
	ev n=F_6+14, i=36 ; ev n=C_5, i=24 ; ev n=E_7-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 39
	ev ; ev n=C_5, i=23 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 40
	ev ; ev ; ev n=B_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 43
	ev ; ev n=C_5, i=24 ; ev n=A_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev n=E_6-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev n=C_6, i=46	@ 48
	ev ; ev ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 49
	ev ; ev n=C_5, i=24 ; ev n=B_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 51
	ev ; ev n=Ds5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev n=Ds5, i=23 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 55
	ev ; ev n=C_5, i=24 ; ev n=E_5-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 56
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 57
	ev ; ev ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 58
	ev ; ev ; ev n=B_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 59
	ev ; ev n=As4, i=23 ; ev n=A_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 60
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 61
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=G_4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 62
	ev ; ev ; ev n=Fs4-16, i=39, fx=FX_OFFSET, p=0x00 ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat091_rows:				@ 08338094
	@ pattern 091: 64 rows, played at order 109
	ev n=F_6+14, i=36 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 03
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=F_6+14, i=36 ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46	@ 06
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 07
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 08
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 11
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=25 ; ev ; ev n=C_6, i=46	@ 16
	ev ; ev n=Fs3, i=26 ; ev ; ev	@ 17
	ev ; ev n=Fs3, i=27 ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=28 ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev n=Fs3, i=29 ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev n=Fs3, i=30 ; ev ; ev n=C_5, i=46	@ 22
	ev ; ev n=Fs3, i=31 ; ev ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=32 ; ev ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 25
	ev ; ev n=Gs3, i=31 ; ev ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=30 ; ev ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=29 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=28 ; ev ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev n=Gs3, i=27 ; ev ; ev	@ 30
	ev ; ev n=Gs3, i=26 ; ev ; ev	@ 31
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=F_6+14, i=36 ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46	@ 38
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 39
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 40
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x10 ; ev ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 43
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=25 ; ev ; ev n=C_6, i=46	@ 48
	ev ; ev n=Fs3, i=26 ; ev ; ev	@ 49
	ev ; ev n=Fs3, i=27 ; ev ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=28 ; ev ; ev n=C_5, i=46	@ 51
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev n=Fs3, i=29 ; ev ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev n=Fs3, i=30 ; ev ; ev n=C_5, i=46	@ 54
	ev ; ev n=Fs3, i=31 ; ev ; ev	@ 55
	ev ; ev n=Gs3, i=32 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev n=Gs3, i=31 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev n=Gs3, i=30 ; ev ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=29 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=28 ; ev ; ev n=F_5, i=38	@ 61
	ev n=Ds6+14, i=36 ; ev n=Gs3, i=27 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev n=Gs3, i=26 ; ev ; ev n=F_5, i=38	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat092_rows:				@ 083382F8
	@ pattern 092: 64 rows, played at order 110
	ev n=F_6+14, i=36 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 03
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=F_6+14, i=36 ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46	@ 06
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 07
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=F_4+20, i=8 ; ev	@ 08
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev n=F_4+20, i=8 ; ev	@ 11
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_4+20, i=8 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 16
	ev ; ev n=Fs3, i=26 ; ev ; ev	@ 17
	ev ; ev n=Fs3, i=27 ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=28 ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev n=Fs3, i=29 ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev n=Fs3, i=30 ; ev ; ev n=C_5, i=46	@ 22
	ev ; ev n=Fs3, i=31 ; ev ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=32 ; ev n=Ds4+20, i=8 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 25
	ev ; ev n=Gs3, i=31 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=30 ; ev n=Ds4+20, i=8 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=29 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=28 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev n=Gs3, i=27 ; ev n=Ds4+20, i=8 ; ev	@ 30
	ev ; ev n=Gs3, i=26 ; ev ; ev	@ 31
	ev n=F_6+14, i=36 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev n=F_6+14, i=36 ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46	@ 38
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 39
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x20 ; ev n=F_4+20, i=8 ; ev	@ 40
	ev ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=B_5, i=40, fx=FX_VOLUME, p=0x0A ; ev n=F_4+20, i=8 ; ev	@ 43
	ev ; ev ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_4+20, i=8 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=46	@ 48
	ev ; ev n=Fs3, i=26 ; ev ; ev	@ 49
	ev ; ev n=Fs3, i=27 ; ev ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev n=Fs3, i=28 ; ev ; ev n=C_5, i=46	@ 51
	ev ; ev ; ev n=E_5, i=40, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev n=Fs3, i=29 ; ev n=E_5, i=40, fx=FX_VOLUME, p=0x20 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev n=Fs3, i=30 ; ev n=E_5, i=40, fx=FX_VOLUME, p=0x30 ; ev n=C_5, i=46	@ 54
	ev ; ev n=Fs3, i=31 ; ev n=E_5, i=40, fx=FX_VOLUME, p=0x20 ; ev	@ 55
	ev ; ev n=Gs3, i=32 ; ev n=Ds4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=40, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev ; ev n=Ds4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=40, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=Ds6+14, i=36 ; ev n=Gs3, i=31 ; ev n=F_4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev n=Gs3, i=30 ; ev n=F_4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=29 ; ev n=Ds4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=Gs3, i=28 ; ev n=Ds4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=38	@ 61
	ev n=Ds6+14, i=36 ; ev n=Gs3, i=27 ; ev n=F_4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev n=Gs3, i=26 ; ev n=F_4+20, i=8, fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=38	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat093_rows:				@ 083385B8
	@ pattern 093: 64 rows, played at orders 111, 112, 115
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=F_6, i=34 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 03
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 04
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 05
	ev n=F_6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 06
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 07
	ev ; ev ; ev n=F_6, i=34 ; ev	@ 08
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 11
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34 ; ev	@ 14
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 15
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=Gs6, i=34 ; ev	@ 16
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 17
	ev ; ev ; ev n=As6, i=34 ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 19
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 20
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 22
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=Gs7, i=34 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 25
	ev ; ev ; ev n=F_7, i=34 ; ev	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Gs7, i=34 ; ev	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev ; ev n=As7, i=34 ; ev	@ 30
	ev ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=F_6, i=34 ; ev	@ 32
	ev ; ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=As7, i=34 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 35
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 36
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 37
	ev n=F_6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 38
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 39
	ev ; ev ; ev n=F_6, i=34 ; ev	@ 40
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 43
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34 ; ev	@ 46
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=Gs6, i=34 ; ev	@ 48
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 49
	ev ; ev ; ev n=As6, i=34 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 51
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 52
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 54
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 55
	ev ; ev n=As4, i=23 ; ev n=Gs7, i=34 ; ev	@ 56
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=As7, i=34 ; ev	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev ; ev n=Gs7, i=34 ; ev	@ 62
	ev ; ev ; ev n=As7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 63
hp_pat094_rows:				@ 08338818
	@ pattern 094: 64 rows, played at order 116
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=F_6, i=34 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 02
	ev n=F_6+14, i=36 ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 03
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 04
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 05
	ev n=F_6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 06
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 07
	ev ; ev ; ev n=F_6, i=34 ; ev	@ 08
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 11
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34 ; ev	@ 14
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 15
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=Gs6, i=34 ; ev	@ 16
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 17
	ev ; ev ; ev n=As6, i=34 ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 19
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 20
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 22
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=Gs7, i=34 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 25
	ev ; ev ; ev n=F_7, i=34 ; ev	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Gs7, i=34 ; ev	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev ; ev n=As7, i=34 ; ev	@ 30
	ev ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23 ; ev n=F_6, i=34 ; ev	@ 32
	ev ; ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=As7, i=34 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 35
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 36
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 37
	ev n=F_6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 38
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 39
	ev ; ev ; ev n=F_6, i=34 ; ev	@ 40
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 43
	ev ; ev ; ev n=C_7, i=34 ; ev	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34 ; ev	@ 46
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23 ; ev n=Gs6, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 48
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 49
	ev ; ev ; ev n=As6, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 50
	ev n=Cs6+14, i=36 ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 51
	ev ; ev ; ev n=C_7, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x2A	@ 52
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x00	@ 53
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 54
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 55
	ev ; ev n=As4, i=24 ; ev n=Gs7, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23 ; ev n=As7, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 61
	ev n=Ds6+14, i=36 ; ev ; ev n=Gs7, i=34 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev n=As7, i=34, fx=FX_VOLUME, p=0x1A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat095_rows:				@ 08338AB0
	@ pattern 095: 64 rows, played at order 113
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=Gs5+15, i=44, fx=FX_PORTA_UP, p=0x02 ; ev n=C_6, i=46	@ 00
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=As5+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x94 ; ev n=C_6, i=46	@ 03
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 05
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds5+15, i=44 ; ev n=C_6, i=46	@ 06
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 08
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Ds5+15, i=44, fx=FX_VOLUME, p=0x1A ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 11
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds5+15, i=44, fx=FX_VOLUME, p=0x0A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Fs5+15, i=44 ; ev n=C_6, i=46	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 17
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Gs5+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev n=C_5, i=46	@ 22
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23, fx=FX_VOLUME, p=0x40 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 25
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x93 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 30
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=As5+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev n=C_6, i=46	@ 32
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 37
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds6+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev n=C_6, i=46	@ 38
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 39
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 40
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x94 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23, fx=FX_VOLUME, p=0x40 ; ev n=Fs6+15, i=44, fx=FX_VOLSLIDE, p=0x01 ; ev n=C_6, i=46	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_6+15, i=44, fx=FX_VOLSLIDE, p=0x02 ; ev	@ 49
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=Cs6+15, i=44, fx=FX_VOLSLIDE, p=0x03 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev n=Gs5+15, i=44, fx=FX_VOLSLIDE, p=0x04 ; ev n=C_5, i=46	@ 51
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=Fs5+15, i=44, fx=FX_VOLSLIDE, p=0x05 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_5+15, i=44, fx=FX_VOLSLIDE, p=0x06 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds5+15, i=44, fx=FX_VOLSLIDE, p=0x07 ; ev n=C_5, i=46	@ 54
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Cs5+15, i=44, fx=FX_VOLSLIDE, p=0x08 ; ev	@ 55
	ev ; ev n=As4, i=23, fx=FX_VOLUME, p=0x40 ; ev n=As4+15, i=44, fx=FX_VOLSLIDE, p=0x09 ; ev	@ 56
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Gs4+15, i=44, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Fs4+15, i=44, fx=FX_VOLSLIDE, p=0x0B ; ev n=C_6, i=46	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4+15, i=44, fx=FX_VOLSLIDE, p=0x0C ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 62
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat096_rows:				@ 08338D3C
	@ pattern 096: 64 rows, played at order 114
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=Gs5+15, i=44, fx=FX_PORTA_UP, p=0x02 ; ev n=C_6, i=46	@ 00
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=As5+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 02
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x94 ; ev n=C_6, i=46	@ 03
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 05
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds5+15, i=44 ; ev n=C_6, i=46	@ 06
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 08
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Ds5+15, i=44, fx=FX_VOLUME, p=0x1A ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=46	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 11
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds5+15, i=44, fx=FX_VOLUME, p=0x0A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 14
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 15
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Fs5+15, i=44 ; ev n=C_6, i=46	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 17
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev	@ 18
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=46	@ 19
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 21
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Gs5+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev n=C_5, i=46	@ 22
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As4, i=23, fx=FX_VOLUME, p=0x40 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 25
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x93 ; ev n=C_6, i=46	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 30
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x40 ; ev n=As5+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev n=C_6, i=46	@ 32
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 34
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_6, i=46	@ 35
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 37
	ev n=F_6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev n=Ds6+15, i=44, fx=FX_TONEPORTA, p=0x10 ; ev n=C_6, i=46	@ 38
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 39
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 40
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x94 ; ev n=C_6, i=46	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x10	@ 46
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_6, i=46, fx=FX_VOLUME, p=0x20	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs4, i=23, fx=FX_VOLUME, p=0x40 ; ev n=Ds6+15, i=44, fx=FX_VOLSLIDE, p=0x01 ; ev n=C_6, i=46	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_6+15, i=44, fx=FX_VOLSLIDE, p=0x02 ; ev	@ 49
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=Fs6+15, i=44, fx=FX_VOLSLIDE, p=0x03 ; ev	@ 50
	ev n=Cs6+14, i=36 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_6+15, i=44, fx=FX_VOLSLIDE, p=0x04 ; ev n=C_5, i=46	@ 51
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=Cs6+15, i=44, fx=FX_VIBRATO, p=0x94 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 53
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=C_5, i=46	@ 54
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 55
	ev ; ev n=As4, i=23, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 56
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VIBRATO, p=0x00 ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev fx=FX_VOLUME, p=0x40 ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=F_5, i=38, fx=FX_VOLUME, p=0x20	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat097_rows:				@ 08338FC0
	@ pattern 097: 64 rows, played at order 117
	ev n=F_6+14, i=36 ; ev n=C_4, i=23 ; ev n=F_6, i=34 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev n=C_5, i=24	@ 02
	ev n=F_6+14, i=36 ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 03
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 04
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 05
	ev n=F_6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev n=C_5, i=24	@ 06
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 07
	ev ; ev ; ev n=F_6, i=34 ; ev n=C_5, i=23	@ 08
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 09
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 10
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 11
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 12
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 13
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 14
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 15
	ev n=Cs6+14, i=36 ; ev n=Gs3, i=23 ; ev n=Gs6, i=34 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06	@ 16
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 17
	ev ; ev ; ev n=As6, i=34 ; ev n=C_5, i=24	@ 18
	ev n=Cs6+14, i=36 ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 19
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 20
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 21
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev n=C_5, i=24	@ 22
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 23
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev n=As3, i=23 ; ev n=Gs7, i=34 ; ev n=As4, i=23	@ 24
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 25
	ev ; ev ; ev n=F_7, i=34 ; ev	@ 26
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 27
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=Gs7, i=34 ; ev n=C_5, i=24	@ 28
	ev n=Ds6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 29
	ev n=Ds7+14, i=36 ; ev ; ev n=As7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 30
	ev ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 31
	ev n=F_6+14, i=36 ; ev n=C_4, i=23 ; ev n=F_6, i=34 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06	@ 32
	ev ; ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 33
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=As7, i=34 ; ev n=C_5, i=24	@ 34
	ev n=F_6+14, i=36 ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 35
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 36
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 37
	ev n=F_6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev n=C_5, i=24	@ 38
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 39
	ev ; ev ; ev n=F_6, i=34 ; ev n=C_5, i=23	@ 40
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 41
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34 ; ev	@ 42
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 43
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 44
	ev n=F_7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 45
	ev n=F_6+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 46
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 47
	ev n=Cs6+14, i=36 ; ev n=Gs3, i=23 ; ev n=Gs6, i=34 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06	@ 48
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 49
	ev ; ev ; ev n=As6, i=34 ; ev n=C_5, i=24	@ 50
	ev n=Cs6+14, i=36 ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 51
	ev ; ev ; ev n=C_7, i=34 ; ev n=Ds5, i=24	@ 52
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 53
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev n=Ds5, i=23	@ 54
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 55
	ev ; ev n=As3, i=23 ; ev n=Gs7, i=34 ; ev n=C_5, i=24	@ 56
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 57
	ev n=Ds6+14, i=36 ; ev ; ev n=F_7, i=34 ; ev	@ 58
	ev fx=FX_PORTA_UP, p=0x02 ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 59
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=As7, i=34 ; ev n=As4, i=23	@ 60
	ev n=Ds7+14, i=36, fx=FX_VOLSLIDE, p=0x0F ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 61
	ev n=Ds6+14, i=36 ; ev ; ev n=Gs7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 62
	ev ; ev ; ev n=As7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 63
hp_pat098_rows:				@ 0833927C
	@ pattern 098: 64 rows, played at order 118
	ev ; ev n=C_4, i=23 ; ev n=F_6, i=34 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev n=A_6, i=34 ; ev n=C_5, i=24	@ 02
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 03
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 04
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 05
	ev ; ev ; ev n=F_7, i=34 ; ev n=C_5, i=24	@ 06
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 07
	ev ; ev ; ev n=F_6, i=34 ; ev n=C_5, i=23	@ 08
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 09
	ev ; ev ; ev n=A_6, i=34 ; ev	@ 10
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 11
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 12
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 13
	ev ; ev ; ev n=F_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 14
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 15
	ev ; ev n=Gs3, i=23 ; ev n=Gs6, i=34 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06	@ 16
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 17
	ev ; ev ; ev n=As6, i=34 ; ev n=C_5, i=24	@ 18
	ev ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 19
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 20
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 21
	ev ; ev ; ev n=F_7, i=34 ; ev n=C_5, i=24	@ 22
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 23
	ev ; ev n=As3, i=23 ; ev n=Gs7, i=34 ; ev n=As4, i=23	@ 24
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 25
	ev ; ev ; ev n=F_7, i=34 ; ev	@ 26
	ev ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 27
	ev ; ev ; ev n=Gs7, i=34 ; ev n=C_5, i=24	@ 28
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 29
	ev ; ev ; ev n=As7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 30
	ev ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 31
	ev ; ev n=C_4, i=23 ; ev n=F_6, i=34 ; ev n=C_5, i=23, fx=FX_SPEED, p=0x06	@ 32
	ev ; ev ; ev n=A_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 33
	ev ; ev ; ev n=As7, i=34 ; ev n=C_5, i=24	@ 34
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 35
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 36
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 37
	ev ; ev ; ev n=F_7, i=34 ; ev n=C_5, i=24	@ 38
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 39
	ev ; ev ; ev n=F_6, i=34 ; ev n=C_5, i=23	@ 40
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 41
	ev ; ev ; ev n=A_6, i=34 ; ev	@ 42
	ev ; ev ; ev n=F_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 43
	ev ; ev ; ev n=C_7, i=34 ; ev n=C_5, i=24	@ 44
	ev ; ev ; ev n=A_6, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 45
	ev ; ev ; ev n=F_7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 46
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 47
	ev ; ev n=Ds4, i=23 ; ev n=Gs6, i=34 ; ev n=As4, i=23, fx=FX_SPEED, p=0x06	@ 48
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 49
	ev ; ev ; ev n=As6, i=34 ; ev n=C_5, i=24	@ 50
	ev ; ev ; ev n=Gs6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 51
	ev ; ev ; ev n=C_7, i=34 ; ev n=Ds5, i=24	@ 52
	ev ; ev ; ev n=As6, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 53
	ev ; ev ; ev n=F_7, i=34 ; ev n=Ds5, i=23	@ 54
	ev ; ev ; ev n=C_7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x0A	@ 55
	ev ; ev n=F_4, i=23 ; ev n=Gs7, i=34 ; ev n=C_5, i=24	@ 56
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 57
	ev ; ev ; ev n=F_7, i=34 ; ev	@ 58
	ev ; ev ; ev n=Gs7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 59
	ev ; ev ; ev n=As7, i=34 ; ev n=As4, i=23	@ 60
	ev ; ev ; ev n=F_7, i=34, fx=FX_VOLUME, p=0x1A ; ev	@ 61
	ev ; ev ; ev n=Gs7, i=34 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 62
	ev ; ev ; ev n=As7, i=34, fx=FX_VOLUME, p=0x1A ; ev fx=FX_JUMP, p=0x63	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat099_rows:				@ 083394C8
	@ pattern 099: 64 rows, played at order 120
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=D_6+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=E_6, i=41 ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=D_6+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=E_6, i=41 ; ev n=Gs3-8, i=1 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat100_rows:				@ 08339670
	@ pattern 100: 64 rows, played at order 121
	ev n=F_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=F_5+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=F_5+14, i=43 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=F_5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=E_6, i=41 ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=F_5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_5+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=F_5+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=F_5+14, i=43 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev n=D_3-8, i=1, fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=As5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=As6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=E_6, i=41 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=As5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=As6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat101_rows:				@ 08339818
	@ pattern 101: 64 rows, played at order 122
	ev n=G_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=B_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=D_3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=G_5+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=G_5+14, i=43 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=G_5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=E_6, i=41 ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=G_5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=G_5+14, i=43 ; ev n=E_6, i=41 ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=G_5+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=G_5+14, i=43 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev n=Gs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=G_5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=E_6, i=41 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=G_5+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat102_rows:				@ 083399C4
	@ pattern 102: 64 rows, played at order 123
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=D_6+14, i=43 ; ev n=E_6, i=41 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=E_6, i=41 ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev n=E_6, i=41, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev ; ev n=E_6, i=41, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 31
	ev n=C_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev n=B_2-8, i=1, fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_6+14, i=43 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_6+14, i=43 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_7+14, i=43 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20 ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=C_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_6+14, i=43 ; ev n=C_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=C_7+14, i=43 ; ev n=C_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_6, i=41 ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat103_rows:				@ 08339B84
	@ pattern 103: 64 rows, played at order 124
	ev n=D_6+14, i=43 ; ev n=C_6, i=41 ; ev ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev n=D_6+14, i=43, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=G_5, i=21 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev ; ev ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=D_6+14, i=43, fx=FX_VOLUME, p=0x05 ; ev ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev ; ev n=C_6, i=41 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev n=C_6, i=41 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=G_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=41 ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev n=C_6, i=41 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev n=C_6, i=41 ; ev	@ 28
	ev ; ev ; ev n=C_6, i=41 ; ev	@ 29
	ev ; ev ; ev n=C_6, i=41 ; ev	@ 30
	ev ; ev fx=FX_NOP16, p=0x00 ; ev n=C_6, i=41 ; ev	@ 31
	ev ; ev ; ev ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat104_rows:				@ 08339CB8
	@ pattern 104: 64 rows, played at order 125
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=Gs3-8, i=1 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat105_rows:				@ 08339EAC
	@ pattern 105: 64 rows, played at order 126
	ev n=F_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=F_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=F_5+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_5+14, i=43 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=F_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=F_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev n=D_3-8, i=1, fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=As5+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=As6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=As5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=As6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat106_rows:				@ 0833A09C
	@ pattern 106: 64 rows, played at order 127
	ev n=G_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=B_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=D_3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=G_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=G_5+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=G_5+14, i=43 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=G_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev n=Gs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=G_5+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=G_6+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat107_rows:				@ 0833A290
	@ pattern 107: 64 rows, played at order 128
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev fx=FX_VOLUME, p=0x40 ; ev n=B_2-8, i=1, fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 39
	ev n=C_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_7+14, i=43 ; ev n=E_6, i=41 ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 53
	ev n=C_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 59
	ev n=C_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 60
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat108_rows:				@ 0833A484
	@ pattern 108: 64 rows, played at order 129
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 05
	ev ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 21
	ev n=D_7+14, i=43 ; ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 28
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 35
	ev n=D_7+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 37
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 39
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x15 ; ev ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 41
	ev n=D_7+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 44
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x25 ; ev ; ev	@ 46
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 47
	ev n=D_7+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev	@ 48
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 49
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x30 ; ev ; ev	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x33 ; ev ; ev	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 53
	ev n=D_7+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x37 ; ev ; ev	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x3A ; ev ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x3C ; ev ; ev	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 59
	ev n=D_7+14, i=43 ; ev n=C_5, i=5 ; ev ; ev	@ 60
	ev ; ev n=C_5, i=5 ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5 ; ev ; ev	@ 62
	ev ; ev n=C_5, i=5 ; ev ; ev	@ 63
hp_pat109_rows:				@ 0833A670
	@ pattern 109: 64 rows, played at order 130
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=51, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x30	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 39
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 53
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat110_rows:				@ 0833A8A8
	@ pattern 110: 64 rows, played at order 131
	ev n=F_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=51, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 05
	ev ; ev ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 07
	ev n=F_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=F_6+14, i=43 ; ev ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev n=As5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=F_5+14, i=43 ; ev n=G_5, i=21 ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev n=F_6+14, i=43 ; ev ; ev n=As5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=C_5, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_5+14, i=43 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x30	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 37
	ev ; ev ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 39
	ev n=F_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=F_6+14, i=43 ; ev ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev n=As5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=As5+14, i=43 ; ev n=G_5, i=21 ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 53
	ev n=As6+14, i=43 ; ev ; ev n=As5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=As5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=As6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=C_5, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat111_rows:				@ 0833AADC
	@ pattern 111: 64 rows, played at order 132
	ev n=G_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=51, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 05
	ev ; ev ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 07
	ev n=G_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev n=C_6, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=G_5+14, i=43 ; ev n=G_5, i=21 ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev n=G_6+14, i=43 ; ev ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=D_5, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=G_5+14, i=43 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x30	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 37
	ev ; ev ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 39
	ev n=G_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=G_6+14, i=43 ; ev ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev n=C_6, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=G_5+14, i=43 ; ev n=G_5, i=21 ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 53
	ev n=G_6+14, i=43 ; ev ; ev n=C_6, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=D_5, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat112_rows:				@ 0833AD10
	@ pattern 112: 64 rows, played at order 133
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=51, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x30	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 39
	ev n=C_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 53
	ev n=C_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=C_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat113_rows:				@ 0833AF48
	@ pattern 113: 64 rows, played at order 134
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=51, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x30	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev n=A_5, i=50 ; ev fx=FX_VOLUME, p=0x40	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 38
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 39
	ev ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x40	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev n=G_5, i=50 ; ev fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 52
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 53
	ev ; ev ; ev n=G_5, i=48 ; ev fx=FX_VOLUME, p=0x40	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x40	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=A_5, i=48 ; ev fx=FX_VOLUME, p=0x0A	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat114_rows:				@ 0833B134
	@ pattern 114: 64 rows, played at order 135
	ev n=E_4, i=23, fx=FX_VOLUME, p=0x00 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x00	@ 00
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 01
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 03
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 07
	ev ; ev ; ev ; ev	@ 08
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 09
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 11
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 12
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 15
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 16
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 17
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 19
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 23
	ev ; ev ; ev ; ev	@ 24
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 25
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 27
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 28
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 36
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 38
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 52
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 54
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 55
	ev ; ev n=Gs3-8, i=1 ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 58
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 60
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat115_rows:				@ 0833B298
	@ pattern 115: 64 rows, played at order 136
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 01
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 02
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 03
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 04
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 05
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 06
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 07
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 09
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 11
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 12
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 13
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 15
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 17
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 18
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 19
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 20
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 21
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 22
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 23
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 25
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 26
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 27
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 28
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 29
	ev ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 36
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 38
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=D_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 52
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 54
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 55
	ev ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 58
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 60
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat116_rows:				@ 0833B40C
	@ pattern 116: 64 rows, played at order 137
	ev n=A_4, i=23, fx=FX_VOLUME, p=0x00 ; ev n=B_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=D_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 00
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 01
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01	@ 02
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 03
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 04
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 05
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 06
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 07
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 08
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 09
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 10
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 11
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01	@ 12
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 14
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 15
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 17
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 19
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 22
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 23
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 25
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 26
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 27
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 29
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev n=A_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x00	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 36
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 38
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 39
	ev ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=Gs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 52
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 54
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 55
	ev ; ev ; ev ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 58
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 60
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat117_rows:				@ 0833B584
	@ pattern 117: 64 rows, played at order 138
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=Cs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=Fs3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 01
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 02
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 03
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 04
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 05
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 06
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 07
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 09
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 11
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 12
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 13
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 15
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 17
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 18
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 19
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 20
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 21
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 22
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 23
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 25
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 26
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x10	@ 27
	ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 28
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 29
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_4, i=23, fx=FX_VOLUME, p=0x00 ; ev n=B_2-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 32
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 33
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01	@ 34
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 35
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 36
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 38
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 39
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 40
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 41
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 42
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01	@ 44
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 46
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 47
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 49
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 51
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 55
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev fx=FX_VOLSLIDE, p=0x10 ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev fx=FX_VOLSLIDE, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x00	@ 60
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 61
	ev ; ev ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat118_rows:				@ 0833B71C
	@ pattern 118: 64 rows, played at order 139
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 01
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 03
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 05
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 07
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 09
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 11
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=A_5, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 13
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 15
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 17
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=A_5, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 19
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 21
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 23
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 25
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x10	@ 27
	ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev fx=FX_VOLUME, p=0x00 ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat119_rows:				@ 0833B8F0
	@ pattern 119: 64 rows, played at order 140
	ev ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat120_rows:				@ 0833BAA0
	@ pattern 120: 64 rows, played at order 141
	ev n=A_4, i=51, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev fx=FX_VOLSLIDE, p=0x01	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 05
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 07
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev fx=FX_VOLSLIDE, p=0x01	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 13
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev fx=FX_VOLSLIDE, p=0x01	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev fx=FX_VOLSLIDE, p=0x01	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 19
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 21
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev fx=FX_VOLSLIDE, p=0x01	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 23
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev fx=FX_VOLSLIDE, p=0x01	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=50 ; ev fx=FX_VOLSLIDE, p=0x01	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 31
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x00	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 37
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 39
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 45
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev	@ 50
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 51
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 53
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev	@ 54
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 55
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 57
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 59
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev	@ 60
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 61
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=50 ; ev	@ 62
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 63
hp_pat121_rows:				@ 0833BCA4
	@ pattern 121: 64 rows, played at order 142
	ev n=A_4, i=51, fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 00
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 01
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 03
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 04
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 05
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 07
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 09
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 11
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev	@ 12
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 13
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 15
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 16
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 17
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev	@ 18
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 19
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 21
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=48 ; ev	@ 22
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 23
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 25
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 27
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=48 ; ev	@ 28
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 29
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 31
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 32
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 33
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 35
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_5, i=50 ; ev	@ 36
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 37
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 39
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 41
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 43
	ev fx=FX_VOLUME, p=0x20 ; ev ; ev n=A_5, i=48 ; ev	@ 44
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 45
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_6+14, i=43 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 47
	ev fx=FX_VOLUME, p=0x20 ; ev n=D_7+14, i=43 ; ev n=G_5, i=50 ; ev	@ 48
	ev fx=FX_VOLUME, p=0x01 ; ev ; ev ; ev	@ 49
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev n=E_6, i=41	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev n=G_5, i=48 ; ev n=E_6, i=41	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev n=E_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev n=E_6, i=41	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=A_5, i=48 ; ev n=E_6, i=41	@ 60
	ev ; ev ; ev ; ev n=E_6, i=41	@ 61
	ev ; ev ; ev n=A_4, i=50 ; ev n=E_6, i=41	@ 62
	ev ; ev ; ev ; ev n=E_6, i=41	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat122_rows:				@ 0833BE98
	@ pattern 122: 64 rows, played at orders 143, 144, 145
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x30	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x30	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x30	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x1A	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=16, fx=FX_VOLUME, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x30	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x1A	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x30	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev n=D_3, i=16, fx=FX_VOLUME, p=0x30	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x30	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x30	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x1A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x30	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x30	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev n=D_3, i=16, fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x30	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=17, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev n=D_3, i=18, fx=FX_VOLUME, p=0x30	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=19, fx=FX_VOLUME, p=0x30	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=50 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x30	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat123_rows:				@ 0833C12C
	@ pattern 123: 64 rows, played at order 146
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x30	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x30	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x30	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x0A	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x30	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x0A	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x1A	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev n=D_3, i=14, fx=FX_VOLUME, p=0x30	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=16, fx=FX_VOLUME, p=0x0A	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x30	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x1A	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x30	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev n=D_3, i=16, fx=FX_VOLUME, p=0x30	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=E_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x20	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=11, fx=FX_VOLUME, p=0x30	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev n=A_5, i=50 ; ev n=D_3, i=12, fx=FX_VOLUME, p=0x30	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x1A	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x30	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev n=A_5, i=48 ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x30	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev n=G_5, i=50 ; ev n=D_3, i=16, fx=FX_VOLUME, p=0x30	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x30	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev ; ev n=D_3, i=17, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev n=D_3, i=18, fx=FX_VOLUME, p=0x30	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev ; ev n=D_3, i=15, fx=FX_VOLUME, p=0x1A	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=D_3, i=19, fx=FX_VOLUME, p=0x30	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev ; ev n=C_5, i=21 ; ev ; ev n=D_3, i=13, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev ; ev n=D_3, i=10, fx=FX_VOLUME, p=0x30	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat124_rows:				@ 0833C370
	@ pattern 124: 64 rows, played at orders 147, 151
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat125_rows:				@ 0833C588
	@ pattern 125: 64 rows, played at orders 148, 152
	ev n=F_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=F_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=F_6+14, i=43 ; ev ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev n=As5, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=F_5+14, i=43 ; ev n=G_5, i=21 ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=F_6+14, i=43 ; ev ; ev n=As5, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=C_5, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=F_5+14, i=43 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=F_6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=50 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=C_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=F_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=F_6+14, i=43 ; ev ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=F_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=F_6+14, i=43 ; ev n=E_6, i=41 ; ev n=As5, i=50 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=As5+14, i=43 ; ev n=G_5, i=21 ; ev n=C_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=As6+14, i=43 ; ev ; ev n=As5, i=48 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=C_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=As5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_6, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=As6+14, i=43 ; ev n=G_5, i=21 ; ev n=C_6, i=48 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=C_5, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat126_rows:				@ 0833C7A0
	@ pattern 126: 64 rows, played at orders 149, 153
	ev n=G_5+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=G_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev n=C_6, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=G_5+14, i=43 ; ev n=G_5, i=21 ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=G_6+14, i=43 ; ev ; ev n=C_6, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=D_5, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=G_5+14, i=43 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=50 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=D_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=G_5+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=G_6+14, i=43 ; ev ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_5, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=G_6+14, i=43 ; ev n=E_6, i=41 ; ev n=C_6, i=50 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=G_5+14, i=43 ; ev n=G_5, i=21 ; ev n=D_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=G_6+14, i=43 ; ev ; ev n=C_6, i=48 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=D_6, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=G_5+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_6, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=G_6+14, i=43 ; ev n=G_5, i=21 ; ev n=D_6, i=48 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=D_5, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat127_rows:				@ 0833C9B8
	@ pattern 127: 64 rows, played at order 150
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=D_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_6, i=41, fx=FX_STORE, p=0x95 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=50 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev n=C_6+14, i=43 ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x1A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_7+14, i=43 ; ev n=E_6, i=41 ; ev n=G_5, i=50 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=48 ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_6+14, i=43 ; ev n=G_5, i=21 ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev n=C_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x2A ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 59
	ev n=C_7+14, i=43 ; ev n=G_5, i=21 ; ev n=A_5, i=48 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5, i=5, fx=FX_VOLUME, p=0x1A ; ev n=A_4, i=50 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat128_rows:				@ 0833CBD8
	@ pattern 128: 64 rows, played at order 154
	ev n=D_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev n=D_7+14, i=43 ; ev ; ev n=A_5, i=50 ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev n=A_4, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev n=D_6+14, i=43 ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x1A ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev n=D_7+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x1A ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev n=D_6+14, i=43 ; ev ; ev n=A_4, i=49, fx=FX_VOLUME, p=0x10 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=50 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev n=A_5, i=48 ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=D_6+14, i=43 ; ev ; ev n=A_4, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev n=D_7+14, i=43 ; ev ; ev n=G_5, i=48 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=A_5, i=48, fx=FX_VOLUME, p=0x1A ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev n=D_6+14, i=43 ; ev ; ev n=A_5, i=50, fx=FX_VOLUME, p=0x10 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=D_7+14, i=43 ; ev ; ev n=A_5, i=48 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=A_4, i=50 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_6+14, i=43, fx=FX_SPEED, p=0x03 ; ev n=E_3-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=B_2-8, i=1, fx=FX_VOLUME, p=0x40 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x1A	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev n=C_7+14, i=43 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 36
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 38
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 39
	ev n=C_6+14, i=43 ; ev ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x1A	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev n=C_6+14, i=43 ; ev ; ev ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_7+14, i=43 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x02	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x02	@ 49
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x02	@ 50
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x02	@ 51
	ev n=C_6+14, i=43 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLSLIDE, p=0x02	@ 52
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev n=C_7+14, i=43 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev	@ 54
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 55
	ev ; ev ; ev ; ev n=E_6, i=41	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev n=C_6+14, i=43 ; ev fx=FX_VOLUME, p=0x40 ; ev fx=FX_VOLUME, p=0x40 ; ev n=E_6, i=41	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_7+14, i=43 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev n=E_6, i=41	@ 60
	ev ; ev ; ev ; ev n=E_6, i=41	@ 61
	ev ; ev ; ev ; ev n=E_6, i=41	@ 62
	ev ; ev ; ev ; ev n=E_6, i=41, fx=FX_JUMP, p=0x78	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat129_rows:				@ 0833CD9C
	@ pattern 129: 64 rows, played at order 156
	ev fx=FX_STORE, p=0x95 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3, fx=FX_SPEED, p=0x04	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev ; ev n=C_5+20, i=8 ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=C_5+20, i=8 ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev n=C_5+20, i=8 ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_4, i=40, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev ; ev n=C_5+20, i=8 ; ev fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat130_rows:				@ 0833CF14
	@ pattern 130: 64 rows, played at order 157
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev	@ 04
	ev ; ev ; ev ; ev	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev ; ev n=C_5+20, i=8 ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=C_5+20, i=8 ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev ; ev n=C_5+20, i=8 ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_4, i=40, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 55
	ev ; ev ; ev n=C_5+20, i=8 ; ev fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat131_rows:				@ 0833D08C
	@ pattern 131: 64 rows, played at order 158
	ev ; ev n=F_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=F_3, i=26 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=F_3, i=29 ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev n=F_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev n=F_3, i=31 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=F_3, i=32 ; ev ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=F_3, i=31 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=F_3, i=30 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=F_3, i=28 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=F_3, i=27 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev n=F_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=F_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev ; ev n=F_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=F_3, i=26 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=F_3, i=29 ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev n=F_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev n=F_3, i=31 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev n=F_3, i=32 ; ev ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=F_3, i=31 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=F_3, i=30 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=F_3, i=28 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=F_3, i=27 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=F_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=F_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat132_rows:				@ 0833D26C
	@ pattern 132: 64 rows, played at order 159
	ev ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=E_3, i=29 ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev n=E_3, i=31 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=E_3, i=32 ; ev ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=E_3, i=31 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev n=E_3, i=30 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=E_3, i=28 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev n=E_3, i=27 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=E_3, i=26 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=E_3, i=29 ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev n=E_3, i=31 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev n=E_3, i=32 ; ev ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=E_3, i=31 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev n=E_3, i=30 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev ; ev ; ev n=D_4, i=46, fx=FX_VOLUME, p=0x10	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=E_3, i=28 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev n=E_3, i=27 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=C_5+20, i=8 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat133_rows:				@ 0833D464
	@ pattern 133: 64 rows, played at orders 160, 162
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=E_3, i=29 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev n=E_3, i=31 ; ev ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=E_3, i=32 ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 13
	ev ; ev n=E_3, i=31 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev n=E_3, i=30 ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=28 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=27 ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=25 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Gs3, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=25 ; ev ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=E_3, i=29 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev n=E_3, i=31 ; ev ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev n=E_3, i=32 ; ev n=Cs4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 45
	ev ; ev n=E_3, i=31 ; ev n=Cs5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 47
	ev n=As3, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=30 ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev ; ev n=Ds4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev ; ev n=E_3, i=28 ; ev n=Ds5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev n=E_3, i=27 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=Ds4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=E_3, i=25 ; ev n=Ds5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev n=Ds4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat134_rows:				@ 0833D674
	@ pattern 134: 64 rows, played at order 161
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=E_3, i=29 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev n=E_3, i=31 ; ev ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=E_3, i=32 ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 13
	ev ; ev n=E_3, i=31 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev n=E_3, i=30 ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=28 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=27 ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=25 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Ds4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=25 ; ev ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=E_3, i=29 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev n=E_3, i=31 ; ev ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev n=E_3, i=32 ; ev n=G_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 45
	ev ; ev n=E_3, i=31 ; ev n=G_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 47
	ev n=F_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=30 ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev ; ev n=As4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev ; ev n=E_3, i=28 ; ev n=As5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev n=E_3, i=27 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=As4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=E_3, i=25 ; ev n=As5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev n=As4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat135_rows:				@ 0833D884
	@ pattern 135: 64 rows, played at order 163
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 02
	ev ; ev ; ev ; ev	@ 03
	ev ; ev ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev ; ev	@ 07
	ev ; ev n=E_3, i=29 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev n=E_3, i=30 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev n=E_3, i=31 ; ev ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=E_3, i=32 ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 13
	ev ; ev n=E_3, i=31 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev n=E_3, i=30 ; ev ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=28 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=27 ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=25 ; ev n=F_5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev n=E_3, i=32 ; ev ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Ds4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=E_3, i=25 ; ev ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=E_3, i=26 ; ev ; ev	@ 34
	ev ; ev ; ev ; ev	@ 35
	ev ; ev ; ev ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev ; ev	@ 38
	ev ; ev ; ev ; ev	@ 39
	ev ; ev n=E_3, i=29 ; ev ; ev	@ 40
	ev ; ev n=E_3, i=30 ; ev ; ev	@ 41
	ev ; ev n=E_3, i=31 ; ev ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev n=E_3, i=32 ; ev n=Gs4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 44
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 45
	ev ; ev n=E_3, i=31 ; ev n=Gs5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 46
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 47
	ev n=F_4, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev n=As4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 50
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 51
	ev ; ev ; ev n=As5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 52
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=As4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 56
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 57
	ev ; ev ; ev n=As5+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 58
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 59
	ev ; ev ; ev ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=As4+20, i=8, fx=FX_OFFSET, p=0x01 ; ev	@ 62
	ev ; ev ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat136_rows:				@ 0833DA58
	@ pattern 136: 64 rows, played at order 164
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev ; ev ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Gs3, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=Cs4, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev ; ev ; ev n=Cs5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev n=Cs4, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev ; ev n=Cs4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=Cs5, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=As3, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Ds3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=Ds4, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=Ds5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=Ds4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat137_rows:				@ 0833DC20
	@ pattern 137: 64 rows, played at order 165
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev ; ev ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Gs3, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=Gs3, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev ; ev ; ev n=Gs4, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev n=Gs3, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev ; ev n=Gs3, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev n=Gs4, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=As3, i=23, fx=FX_VOLUME, p=0x10 ; ev ; ev n=As2, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=As3, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=As4, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=As3, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat138_rows:				@ 0833DDE8
	@ pattern 138: 64 rows, played at order 166
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_4, i=23 ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev n=Cs4, i=23 ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev n=C_4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_4, i=23 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev n=Ds4, i=23 ; ev ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev n=C_4, i=23 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev n=B_3, i=23 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev n=C_4, i=23 ; ev ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev n=Cs4, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Gs3, i=23, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=23 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=Gs3, i=23 ; ev n=Cs4, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Cs5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev n=A_3, i=23 ; ev n=Cs4, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev ; ev n=Gs3, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Cs4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev n=G_3, i=23 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=Gs3, i=23 ; ev n=Cs5, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=As3, i=23, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=Ds3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev n=B_3, i=23 ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=As3, i=23 ; ev n=Ds4, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=A_3, i=23 ; ev n=Ds5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=As3, i=23 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Ds4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=B_3, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat139_rows:				@ 0833DFFC
	@ pattern 139: 64 rows, played at order 167
	ev n=C_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev n=C_4, i=23 ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev n=Cs4, i=23 ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev n=C_4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_4, i=23 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev fx=FX_VIBRATO, p=0x93 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev fx=FX_VIBRATO, p=0x00 ; ev n=Ds4, i=23 ; ev ; ev n=D_4, i=46	@ 18
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 19
	ev fx=FX_VIBRATO, p=0x00 ; ev n=C_4, i=23 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 21
	ev fx=FX_VIBRATO, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 22
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 23
	ev fx=FX_VIBRATO, p=0x00 ; ev n=B_3, i=23 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev fx=FX_VIBRATO, p=0x00 ; ev n=C_4, i=23 ; ev ; ev n=C_3, i=3	@ 26
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev	@ 27
	ev fx=FX_VIBRATO, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev fx=FX_VIBRATO, p=0x00 ; ev n=Cs4, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev fx=FX_VIBRATO, p=0x00 ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=Ds4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=23 ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev n=Ds4, i=23 ; ev n=Gs3, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Gs4, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev n=E_4, i=23 ; ev n=Gs3, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev ; ev n=Ds4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Gs3, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev ; ev n=D_4, i=23 ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=Ds4, i=23 ; ev n=Gs4, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=F_4, i=23, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=As2, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev ; ev n=Fs4, i=23 ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=F_4, i=23 ; ev n=As3, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=E_4, i=23 ; ev n=As4, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=F_4, i=23 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=As3, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=Fs4, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat140_rows:				@ 0833E210
	@ pattern 140: 64 rows, played at order 170
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5, i=23, fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev n=C_4, i=0, fx=FX_TONEPORTA, p=0x01 ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 13
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 21
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 22
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=C_3, i=3	@ 26
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs4, i=48 ; ev	@ 34
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs4, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 45
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Cs5, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Ds3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Ds4, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 53
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 54
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Ds5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=Ds4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat141_rows:				@ 0833E454
	@ pattern 141: 64 rows, played at order 171
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23, fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev ; ev ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Gs3, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Gs4, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev ; ev n=Gs3, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev ; ev n=Gs3, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 45
	ev ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev n=Gs4, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev n=As2, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev n=As3, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 53
	ev ; ev ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev n=As4, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev n=As3, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=Fs4, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat142_rows:				@ 0833E684
	@ pattern 142: 64 rows, played at order 172
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Cs4, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Cs5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs4, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=Cs5, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Ds3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Ds4, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev n=Ds5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Ds4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat143_rows:				@ 0833E8B4
	@ pattern 143: 64 rows, played at order 168
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23 ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev n=Cs4, i=23 ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_4, i=23 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds4, i=23 ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev n=C_4, i=23 ; ev ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev n=Cs4, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=23 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs3, i=23 ; ev n=Cs4, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=Cs5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev n=A_3, i=23 ; ev n=Cs4, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Gs3, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Cs4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=23 ; ev n=Cs3, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=Gs3, i=23 ; ev n=Cs5, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=Ds3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=As3, i=23 ; ev n=Ds4, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=A_3, i=23 ; ev n=Ds5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=As3, i=23 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=Ds4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=B_3, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
hp_pat144_rows:				@ 0833EAFC
	@ pattern 144: 64 rows, played at order 169
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23 ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev n=Cs4, i=23 ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_4, i=23 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds4, i=23 ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_4, i=23 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=B_3, i=23 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev n=C_4, i=23 ; ev ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev n=Cs4, i=23 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=23 ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds4, i=23 ; ev n=Gs3, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=Gs4, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev n=E_4, i=23 ; ev n=Gs3, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Ds4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=Gs3, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=D_4, i=23 ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=Ds4, i=23 ; ev n=Gs4, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=As2, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=Fs4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=F_4, i=23 ; ev n=As3, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=E_4, i=23 ; ev n=As4, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev n=F_4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=As3, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=Fs4, i=23 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat145_rows:				@ 0833ED50
	@ pattern 145: 64 rows, played at order 173
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_5, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 05
	ev ; ev ; ev n=F_4, i=50 ; ev n=C_3, i=3	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 08
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 09
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_4, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 10
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_3, i=48 ; ev n=C_3, i=3	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=50 ; ev n=D_4, i=46	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_4, i=46	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=F_4, i=49 ; ev n=C_3, i=3	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev n=F_5, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 24
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 25
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=3	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 28
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 29
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 30
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Gs3, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Gs4, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x03	@ 37
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Gs3, i=50 ; ev n=C_3, i=3	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 40
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 41
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Gs3, i=50 ; ev fx=FX_VOLUME, p=0x20	@ 42
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Gs2, i=48 ; ev n=C_3, i=3	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=Gs4, i=50 ; ev n=D_4, i=46	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=As2, i=49 ; ev n=Ds4, i=21, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x05	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=D_4, i=46	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=As3, i=49 ; ev n=C_3, i=3	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev n=As4, i=49 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 57
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev n=C_3, i=3	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=As3, i=49 ; ev n=D_4, i=40, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 61
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VOLUME, p=0x00	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat146_rows:				@ 0833EF80
	@ pattern 146: 64 rows, played at order 174
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=48 ; ev n=C_3, i=38, fx=FX_VOLUME, p=0x20	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_5, i=49 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 05
	ev ; ev ; ev n=F_4, i=50 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_4, i=50 ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_3, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=50 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=49 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=F_4, i=49 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev n=F_5, i=49 ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=F_4, i=49 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs3, i=48 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Cs4, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Cs5, i=49 ; ev	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs4, i=50 ; ev	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs4, i=50 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Cs3, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=Cs5, i=50 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Ds3, i=49 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Ds4, i=49 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev n=C_5, i=22, fx=FX_VOLUME, p=0x10 ; ev n=C_5+20, i=8 ; ev n=Ds5, i=49 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev n=C_5, i=21, fx=FX_VOLUME, p=0x10 ; ev ; ev n=Ds4, i=49 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat147_rows:				@ 0833F150
	@ pattern 147: 64 rows, played at order 175
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=48 ; ev	@ 00
	ev ; ev ; ev ; ev	@ 01
	ev ; ev ; ev n=F_4, i=48 ; ev	@ 02
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 03
	ev ; ev ; ev n=F_5, i=49 ; ev	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 05
	ev ; ev ; ev n=F_4, i=50 ; ev	@ 06
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 07
	ev ; ev n=C_5+20, i=8 ; ev ; ev	@ 08
	ev ; ev ; ev ; ev	@ 09
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_4, i=50 ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev n=F_3, i=48 ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=F_5, i=50 ; ev	@ 14
	ev ; ev ; ev ; ev	@ 15
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=F_3, i=49 ; ev	@ 16
	ev ; ev ; ev ; ev	@ 17
	ev ; ev ; ev ; ev	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=F_4, i=49 ; ev	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev n=C_5+20, i=8 ; ev n=F_5, i=49 ; ev	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev n=F_4, i=49 ; ev	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Gs2, i=48 ; ev	@ 32
	ev ; ev ; ev ; ev	@ 33
	ev ; ev ; ev n=Gs3, i=48 ; ev	@ 34
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 35
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=Gs4, i=49 ; ev	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 37
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Gs3, i=50 ; ev	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 39
	ev ; ev n=C_5+20, i=8 ; ev ; ev	@ 40
	ev ; ev ; ev ; ev	@ 41
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=Gs3, i=50 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev n=Gs2, i=48 ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev n=Gs4, i=50 ; ev	@ 46
	ev ; ev ; ev ; ev	@ 47
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev n=As2, i=49 ; ev	@ 48
	ev ; ev ; ev ; ev	@ 49
	ev ; ev ; ev ; ev	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x05 ; ev n=As3, i=49 ; ev	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev n=C_5+20, i=8 ; ev n=As4, i=49 ; ev	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev fx=FX_VOLUME, p=0x00 ; ev ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev n=As3, i=49 ; ev	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev n=C_5+20, i=8, fx=FX_VOLUME, p=0x10 ; ev ; ev	@ 62
	ev ; ev ; ev ; ev fx=FX_JUMP, p=0x9D	@ 63
hp_pat148_rows:				@ 0833F2CC
	@ pattern 148: 64 rows, played at order 177
	ev fx=FX_SPEED, p=0x07 ; ev ; ev fx=FX_STORE, p=0x95 ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12	@ 00
	ev ; ev ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10	@ 01
	ev ; ev ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x07 ; ev fx=FX_TONEPORTA, p=0x00	@ 02
	ev ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00	@ 03
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 04
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 05
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=G_5+15, i=0	@ 06
	ev ; ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 07
	ev ; ev ; ev n=G_5+15, i=0 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 08
	ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 09
	ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 10
	ev ; ev ; ev ; ev	@ 11
	ev ; ev ; ev ; ev	@ 12
	ev ; ev ; ev ; ev	@ 13
	ev ; ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 14
	ev ; ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 15
	ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 16
	ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 17
	ev ; ev ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 18
	ev ; ev ; ev ; ev	@ 19
	ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 20
	ev ; ev ; ev ; ev	@ 21
	ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 22
	ev ; ev ; ev ; ev	@ 23
	ev ; ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 24
	ev ; ev ; ev ; ev	@ 25
	ev ; ev ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 26
	ev ; ev ; ev ; ev	@ 27
	ev ; ev ; ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 28
	ev ; ev ; ev ; ev	@ 29
	ev ; ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 30
	ev ; ev ; ev ; ev	@ 31
	ev ; ev ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 32
	ev ; ev ; ev ; ev fx=FX_TONEPORTA, p=0x00	@ 33
	ev ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 34
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 35
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 36
	ev ; ev ; ev ; ev	@ 37
	ev ; ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 38
	ev ; ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 39
	ev ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 40
	ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 41
	ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 42
	ev ; ev ; ev ; ev	@ 43
	ev ; ev ; ev ; ev	@ 44
	ev ; ev ; ev ; ev	@ 45
	ev ; ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 46
	ev ; ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 47
	ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 48
	ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 49
	ev ; ev ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 50
	ev ; ev ; ev ; ev	@ 51
	ev ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 52
	ev ; ev ; ev ; ev	@ 53
	ev ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 54
	ev ; ev ; ev ; ev	@ 55
	ev ; ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 56
	ev ; ev ; ev ; ev	@ 57
	ev ; ev ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 58
	ev ; ev ; ev ; ev	@ 59
	ev ; ev ; ev ; ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 60
	ev ; ev ; ev ; ev	@ 61
	ev ; ev ; ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 62
	ev ; ev ; ev ; ev	@ 63
hp_pat149_rows:				@ 0833F4A0
	@ pattern 149: 64 rows, played at order 178
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev fx=FX_SPEED, p=0x07 ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12	@ 00
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10	@ 01
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x07 ; ev fx=FX_TONEPORTA, p=0x00	@ 02
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00	@ 03
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0C ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 04
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 05
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0D ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=G_5+15, i=0	@ 06
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 07
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0E ; ev n=G_5+15, i=0 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 08
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 09
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 10
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x00 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x00 ; ev ; ev	@ 12
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x11 ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 14
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 15
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 16
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 17
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x13 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 18
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 19
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 20
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 21
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 22
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 23
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x16 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 24
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 26
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x18 ; ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 28
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 29
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 30
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 31
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 32
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_TONEPORTA, p=0x00	@ 33
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1B ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 34
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 35
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1C ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 36
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 37
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1D ; ev fx=FX_TONEPORTA, p=0x00 ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 38
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 39
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1E ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 40
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 41
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 42
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 44
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x21 ; ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 46
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 47
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 48
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 49
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x23 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 50
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 51
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 52
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 53
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 54
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 55
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 56
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 57
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 58
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 59
	ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x28 ; ev ; ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00	@ 60
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev	@ 62
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat150_rows:				@ 0833F7B4
	@ pattern 150: 64 rows, played at order 179
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev fx=FX_SPEED, p=0x07 ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12	@ 00
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10	@ 01
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x07 ; ev fx=FX_TONEPORTA, p=0x00	@ 02
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_TONEPORTA, p=0x00	@ 03
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_TONEPORTA, p=0x00	@ 04
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 05
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0D ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev fx=FX_TONEPORTA, p=0x00 ; ev	@ 06
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 07
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0E ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev ; ev	@ 08
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 09
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev ; ev	@ 10
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev ; ev	@ 12
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev ; ev	@ 14
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev ; ev	@ 16
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x13 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev ; ev	@ 18
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 19
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev ; ev	@ 20
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 21
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev ; ev	@ 22
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 23
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x16 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev ; ev	@ 24
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev ; ev	@ 26
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev n=As3+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev ; ev	@ 28
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 29
	ev n=As3+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev ; ev	@ 30
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 31
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 32
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1B ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 34
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 35
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 36
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 37
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1D ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 38
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 39
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1E ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 40
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 41
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 42
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 44
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 46
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 47
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev fx=FX_SPEED, p=0x08 ; ev fx=FX_VOLSLIDE, p=0x01	@ 48
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x23 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 50
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 51
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev fx=FX_SPEED, p=0x09 ; ev fx=FX_VOLSLIDE, p=0x01	@ 52
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 53
	ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 54
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 55
	ev n=As3+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev fx=FX_SPEED, p=0x10 ; ev fx=FX_VOLSLIDE, p=0x01	@ 56
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 57
	ev n=As3+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 59
	ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev fx=FX_SPEED, p=0x11 ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev fx=FX_SPEED, p=0x12 ; ev	@ 62
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_SPEED, p=0x13 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat151_rows:				@ 0833FA2C
	@ pattern 151: 64 rows, played at order 180
	ev n=B_5+12, i=52 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 15
	ev n=B_5+12, i=52 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=D_6+12, i=52 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x0A ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev n=D_6+12, i=52 ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev fx=FX_VOLUME, p=0x0A ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=E_6+12, i=52 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=E_6+12, i=52 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev n=E_6+12, i=52 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36 ; ev	@ 59
	ev n=Fs6+12, i=52 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev n=Fs6+12, i=52 ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
hp_pat152_rows:				@ 0833FD2C
	@ pattern 152: 64 rows, played at order 181
	ev n=B_5+12, i=52 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 01
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 15
	ev n=B_5+12, i=52 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 17
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=B_5+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=D_6+12, i=52 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x0A ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev n=D_6+12, i=52 ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev fx=FX_VOLUME, p=0x0A ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=E_6+12, i=52 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 33
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=E_6+12, i=52 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 49
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=E_6+12, i=52 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev n=E_6+12, i=52 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36 ; ev	@ 59
	ev n=Fs6+12, i=52 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev n=Fs6+12, i=52 ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev fx=FX_VOLUME, p=0x0A ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
hp_pat153_rows:				@ 0834002C
	@ pattern 153: 64 rows, played at order 182
	ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 01
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=G_5+15, i=0 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 15
	ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 17
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 33
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 49
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36 ; ev	@ 59
	ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
hp_pat154_rows:				@ 0834034C
	@ pattern 154: 64 rows, played at order 183
	ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 01
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=G_5+15, i=0 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 15
	ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 17
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 33
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 49
	ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 51
	ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 55
	ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 59
	ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36 ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x30	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat155_rows:				@ 08340680
	@ pattern 155: 64 rows, played at order 184
	ev n=E_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 01
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 05
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 15
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 17
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 21
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=G_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=A_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 33
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 37
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=D_4, i=24, fx=FX_VOLUME, p=0x20 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 49
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 53
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=D_4, i=23, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36 ; ev	@ 59
	ev n=G_4, i=23 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat156_rows:				@ 08340950
	@ pattern 156: 64 rows, played at order 185
	ev n=E_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 01
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 05
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 11
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 15
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36 ; ev	@ 17
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev	@ 21
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=G_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=A_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 33
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 37
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 43
	ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=D_4, i=24, fx=FX_VOLUME, p=0x20 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36 ; ev	@ 49
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36 ; ev	@ 53
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=D_4, i=23, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 57
	ev ; ev ; ev ; ev	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev ; ev	@ 59
	ev n=G_4, i=23 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev ; ev	@ 60
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev ; ev	@ 61
	ev ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev ; ev	@ 62
	ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat157_rows:				@ 08340BF4
	@ pattern 157: 64 rows, played at order 186
	ev n=E_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36	@ 00
	ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36	@ 01
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 03
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36	@ 05
	ev ; ev n=G_5+15, i=0 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 06
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36	@ 07
	ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 08
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36	@ 09
	ev ; ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 10
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 11
	ev ; ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 12
	ev ; ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 13
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36	@ 14
	ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev	@ 15
	ev ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36	@ 16
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36	@ 17
	ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 19
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 20
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36	@ 21
	ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 22
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36	@ 23
	ev ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 24
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36	@ 25
	ev ; ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00	@ 26
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36	@ 27
	ev n=G_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev	@ 28
	ev ; ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 29
	ev ; ev ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 30
	ev ; ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36	@ 31
	ev n=A_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36	@ 32
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36	@ 33
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 35
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36	@ 37
	ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 38
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36	@ 39
	ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 40
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36	@ 41
	ev ; ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 42
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 43
	ev ; ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 44
	ev ; ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 45
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36	@ 46
	ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 47
	ev n=D_4, i=24, fx=FX_VOLUME, p=0x20 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36	@ 48
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36	@ 49
	ev ; ev n=As5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 51
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 52
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36	@ 53
	ev ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 54
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36	@ 55
	ev n=D_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=D_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 56
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36	@ 57
	ev ; ev ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00	@ 58
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36	@ 59
	ev n=G_4, i=23 ; ev n=C_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev	@ 60
	ev ; ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 61
	ev ; ev ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 62
	ev ; ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat158_rows:				@ 08340E98
	@ pattern 158: 64 rows, played at order 187
	ev n=E_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=F_5+15, i=44, fx=FX_VOLUME, p=0x12 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36	@ 00
	ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x10 ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36	@ 01
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 02
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 03
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 04
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36	@ 05
	ev ; ev n=G_5+15, i=0 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 06
	ev ; ev n=A_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36	@ 07
	ev ; ev n=D_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 08
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36	@ 09
	ev ; ev ; ev ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 10
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 11
	ev ; ev ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 12
	ev ; ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 13
	ev ; ev n=D_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_7+14, i=36	@ 14
	ev ; ev n=F_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x20 ; ev	@ 15
	ev ; ev n=G_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36	@ 16
	ev ; ev ; ev fx=FX_VOLUME, p=0x0A ; ev n=A_6+14, i=36	@ 17
	ev ; ev n=D_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 18
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 19
	ev ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 20
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36	@ 21
	ev ; ev n=B_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 22
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_6+14, i=36	@ 23
	ev ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 24
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_5+14, i=36	@ 25
	ev ; ev ; ev ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00	@ 26
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=A_7+14, i=36	@ 27
	ev n=G_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=F_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev	@ 28
	ev ; ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 29
	ev ; ev ; ev n=As4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 30
	ev ; ev ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_6+14, i=36	@ 31
	ev n=A_4, i=23, fx=FX_VOLUME, p=0x20 ; ev n=G_5+15, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36	@ 32
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36	@ 33
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 34
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 35
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 36
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36	@ 37
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 38
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36	@ 39
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 40
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36	@ 41
	ev ; ev ; ev ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 42
	ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 43
	ev ; ev ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 44
	ev ; ev fx=FX_PORTA_UP, p=0x01 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 45
	ev ; ev fx=FX_PORTA_UP, p=0x01 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_7+14, i=36	@ 46
	ev ; ev fx=FX_PORTA_UP, p=0x01 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x0A	@ 47
	ev n=D_4, i=24, fx=FX_VOLUME, p=0x20 ; ev n=C_6+15, i=0, fx=FX_TONEPORTA, p=0x05 ; ev n=C_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=D_5+14, i=36	@ 48
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x0A ; ev n=D_6+14, i=36	@ 49
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 50
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 51
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 52
	ev ; ev fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36	@ 53
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x00	@ 54
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_6+14, i=36	@ 55
	ev n=D_4, i=23, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev fx=FX_VOLUME, p=0x0A	@ 56
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_5+14, i=36	@ 57
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00	@ 58
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev n=D_7+14, i=36	@ 59
	ev n=G_4, i=23 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev	@ 60
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x10 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 61
	ev ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=D_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A	@ 62
	ev ; ev ; ev n=D_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=E_5+14, i=36	@ 63
hp_pat159_rows:				@ 08341124
	@ pattern 159: 64 rows, played at order 188
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 01
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 17
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x13 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x15 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x16 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x18 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 33
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 49
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x23 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x26 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_7+14, i=36 ; ev	@ 59
	ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x28 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat160_rows:				@ 083414A4
	@ pattern 160: 64 rows, played at order 189
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 01
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 17
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x13 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x15 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x16 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_7+14, i=36 ; ev	@ 27
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x18 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 33
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 49
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x23 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x26 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_7+14, i=36 ; ev	@ 59
	ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x28 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat161_rows:				@ 08341824
	@ pattern 161: 64 rows, played at order 190
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 01
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 17
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_7+14, i=36 ; ev	@ 27
	ev ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 33
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev n=Cs7-16, i=0 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 48
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 49
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 50
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 52
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 53
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 54
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 55
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 57
	ev n=Cs7-16, i=0 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=D_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 58
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_7+14, i=36 ; ev	@ 59
	ev ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 60
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 61
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=E_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 62
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_5+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat162_rows:				@ 08341BCC
	@ pattern 162: 64 rows, played at order 191
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=A_5+14, i=36 ; ev n=C_6, i=41, fx=FX_SPEED, p=0x07	@ 00
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 01
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 02
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x10	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 04
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 05
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 06
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 07
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 08
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 09
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 10
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 12
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 13
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=A_7+14, i=36 ; ev n=C_5, i=21	@ 14
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 16
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev	@ 17
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 18
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=A_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 20
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev	@ 21
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 22
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_6+14, i=36 ; ev n=C_6, i=41	@ 23
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_5+14, i=36 ; ev n=C_6, i=41	@ 25
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=A_6+14, i=36, fx=FX_VOLUME, p=0x00 ; ev n=C_6, i=41	@ 26
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=A_7+14, i=36 ; ev	@ 27
	ev ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x10	@ 29
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=C_7+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x20	@ 30
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=C_6+14, i=36 ; ev n=C_6, i=41, fx=FX_VOLUME, p=0x30	@ 31
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=D_5+14, i=36 ; ev n=C_6, i=41	@ 32
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev	@ 33
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 34
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=22	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 36
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_5+14, i=36 ; ev	@ 37
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=22	@ 38
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 39
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 40
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36 ; ev n=C_6, i=41	@ 41
	ev n=Cs7-16, i=0 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=D_5+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_6, i=41	@ 42
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev n=C_5, i=40, fx=FX_VOLUME, p=0x20	@ 44
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev n=D_6+14, i=36, fx=FX_VOLSLIDE, p=0x0A ; ev	@ 45
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=D_7+14, i=36 ; ev n=C_5, i=21	@ 46
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x0A ; ev	@ 47
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev ; ev	@ 48
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 49
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 50
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev ; ev ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev ; ev ; ev	@ 52
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 53
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev ; ev ; ev	@ 54
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev ; ev ; ev	@ 55
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x23 ; ev ; ev	@ 56
	ev fx=FX_VIBRATO, p=0x94 ; ev ; ev ; ev	@ 57
	ev n=Cs7-16, i=0 ; ev ; ev ; ev	@ 58
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev ; ev ; ev	@ 59
	ev ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x24 ; ev ; ev	@ 60
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev ; ev ; ev	@ 61
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev ; ev ; ev	@ 62
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat163_rows:				@ 08341F04
	@ pattern 163: 64 rows, played at order 192
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x20	@ 00
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 01
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0B ; ev	@ 02
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0C ; ev	@ 04
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 05
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0D ; ev	@ 06
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 07
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0E ; ev	@ 08
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 09
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev	@ 10
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 11
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x0F ; ev	@ 12
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 13
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x11 ; ev	@ 14
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 15
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x12 ; ev	@ 16
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x13 ; ev	@ 18
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x14 ; ev	@ 20
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 21
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x15 ; ev	@ 22
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 23
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x16 ; ev	@ 24
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 25
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev n=G_3+15, i=44, fx=FX_OFFSET, p=0x17 ; ev	@ 26
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 27
	ev ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 29
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x19 ; ev	@ 30
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 31
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x20	@ 32
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1B ; ev	@ 34
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1C ; ev	@ 36
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 37
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1D ; ev	@ 38
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 39
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1E ; ev	@ 40
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 41
	ev n=Cs7-16, i=0 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x1F ; ev	@ 42
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 43
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x20 ; ev	@ 44
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 45
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x21 ; ev	@ 46
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 47
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev n=Cs7-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x23 ; ev	@ 50
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x24 ; ev	@ 52
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 53
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=C_4+15, i=44, fx=FX_OFFSET, p=0x25 ; ev	@ 54
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 55
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x20	@ 56
	ev fx=FX_VIBRATO, p=0x94 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 57
	ev n=Cs7-16, i=0 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=As3+15, i=44, fx=FX_OFFSET, p=0x27 ; ev	@ 58
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 59
	ev ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=G_4, i=23	@ 60
	ev n=Gs6-16, i=0, fx=FX_VOLUME, p=0x1A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 61
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev n=A_3+15, i=44, fx=FX_OFFSET, p=0x29 ; ev	@ 62
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x05 ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat164_rows:				@ 08342224
	@ pattern 164: 64 rows, played at order 193
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0A ; ev n=B_5+12, i=52 ; ev n=E_4, i=23, fx=FX_VOLUME, p=0x20	@ 00
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0B ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 02
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=B_5+12, i=52 ; ev	@ 03
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0C ; ev ; ev	@ 04
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 05
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0D ; ev n=B_5+12, i=52 ; ev	@ 06
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 07
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0E ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 08
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 09
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev ; ev	@ 10
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x0F ; ev ; ev	@ 12
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x11 ; ev ; ev	@ 14
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev n=Gs6-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x12 ; ev n=B_5+12, i=52 ; ev	@ 16
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x13 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 18
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=B_5+12, i=52 ; ev	@ 19
	ev fx=FX_VOLUME, p=0x0A ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x14 ; ev ; ev	@ 20
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x15 ; ev n=B_5+12, i=52 ; ev	@ 22
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 23
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x16 ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 24
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=Cs7-16, i=0 ; ev n=G_2+15, i=44, fx=FX_OFFSET, p=0x17 ; ev ; ev	@ 26
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x18 ; ev n=Fs5+12, i=52 ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x20	@ 28
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 29
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x19 ; ev n=Fs5+12, i=52 ; ev	@ 30
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 31
	ev n=Gs6-16, i=0 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1A ; ev n=E_5+12, i=52 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x20	@ 32
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1B ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 34
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_5+12, i=52 ; ev	@ 35
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1C ; ev ; ev	@ 36
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 37
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1D ; ev n=E_5+12, i=52 ; ev	@ 38
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 39
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1E ; ev fx=FX_VOLUME, p=0x00 ; ev	@ 40
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 41
	ev n=Cs7-16, i=0 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x1F ; ev ; ev	@ 42
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x20 ; ev ; ev	@ 44
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x21 ; ev ; ev	@ 46
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 47
	ev n=Gs6-16, i=0 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x22 ; ev n=E_5+12, i=52 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x20	@ 48
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x30 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x23 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 50
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev n=E_5+12, i=52 ; ev	@ 51
	ev fx=FX_VOLUME, p=0x0A ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x24 ; ev ; ev	@ 52
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=C_3+15, i=44, fx=FX_OFFSET, p=0x25 ; ev n=E_5+12, i=52 ; ev	@ 54
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 55
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x26 ; ev n=E_5+12, i=52 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x20	@ 56
	ev fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 57
	ev n=Cs7-16, i=0 ; ev n=As2+15, i=44, fx=FX_OFFSET, p=0x27 ; ev n=E_5+12, i=52 ; ev	@ 58
	ev n=Ds7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLUME, p=0x0A ; ev	@ 59
	ev ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x28 ; ev n=Fs5+12, i=52 ; ev n=G_4, i=23	@ 60
	ev n=Gs6-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_PORTA_DN, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x02	@ 61
	ev n=Cs7-16, i=0, fx=FX_TONEPORTA, p=0x00 ; ev n=A_2+15, i=44, fx=FX_OFFSET, p=0x29 ; ev fx=FX_PORTA_DN, p=0x0F ; ev fx=FX_VOLSLIDE, p=0x02	@ 62
	ev n=Ds7-16, i=0, fx=FX_VOLUME, p=0x00 ; ev fx=FX_VOLUME, p=0x05 ; ev fx=FX_JUMP, p=0xB2 ; ev fx=FX_VOLSLIDE, p=0x02	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat165_rows:				@ 083424EC
	@ pattern 165: 64 rows, played at order 195
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev fx=FX_SPEED, p=0x07	@ 00
	ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev ; ev	@ 01
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 03
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 05
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 07
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 08
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 09
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 11
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 12
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 15
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 16
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 17
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 19
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 21
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 23
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 24
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 25
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 27
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 28
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 31
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=G_5, i=7, fx=FX_VOLUME, p=0x20 ; ev	@ 32
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 33
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 35
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 37
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 39
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 40
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 41
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 43
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 44
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 45
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 47
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 48
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 49
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 51
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 53
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 55
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x20 ; ev	@ 56
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 57
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 59
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 60
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 61
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 63
hp_pat166_rows:				@ 08342734
	@ pattern 166: 64 rows, played at order 196
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev	@ 00
	ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev ; ev	@ 01
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev	@ 02
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 03
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 04
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 05
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 06
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 07
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 08
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 09
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 10
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 11
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 12
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 14
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 15
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 16
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 17
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 18
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 19
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 20
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 21
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 22
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 23
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 24
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 25
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 26
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 27
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 28
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 30
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 31
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=G_5, i=7, fx=FX_VOLUME, p=0x20 ; ev	@ 32
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 33
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 34
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 35
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 36
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 37
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 38
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 39
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 40
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 41
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 42
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 43
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 44
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 45
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 46
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 47
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 48
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 49
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 50
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 51
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 52
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 53
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 54
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 55
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x20 ; ev	@ 56
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 57
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 58
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 59
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 60
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 61
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev	@ 62
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat167_rows:				@ 0834297C
	@ pattern 167: 64 rows, played at order 197
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 00
	ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 01
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 02
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 03
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 04
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 05
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 06
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 07
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 08
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 10
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 11
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 12
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 14
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 15
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 16
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 17
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 18
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 19
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 20
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 21
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 22
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 23
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 24
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 26
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 27
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 28
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 30
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 31
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=G_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 32
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 33
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 34
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 35
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 36
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 37
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 38
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 39
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 40
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 42
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 43
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 44
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 45
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 46
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 47
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 48
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 49
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 50
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 51
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 52
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 53
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 54
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 55
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=F_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 56
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 58
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 59
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 60
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 61
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 62
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat168_rows:				@ 08342CC4
	@ pattern 168: 64 rows, played at order 198
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x00 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 00
	ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 01
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 02
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 03
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 04
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 05
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 06
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 07
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 08
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 10
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 11
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 12
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 13
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 14
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 15
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 16
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 17
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 18
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 19
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 20
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 21
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 22
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 23
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 24
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 26
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 27
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 28
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 29
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 30
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 31
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev n=G_5, i=7, fx=FX_VOLUME, p=0x20 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 32
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 33
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 34
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 35
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 36
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 37
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 38
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 39
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 40
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 42
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 43
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 44
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 45
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 46
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 47
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 48
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 49
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 50
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 51
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 52
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 53
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 54
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 55
	ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 56
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 58
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 59
	ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 60
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x09 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 61
	ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VOLUME, p=0x01 ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 62
	ev fx=FX_VOLSLIDE, p=0x04 ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x09 ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat169_rows:				@ 08343010
	@ pattern 169: 64 rows, played at order 199
	ev ; ev n=C_3, i=3 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x10 ; ev	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 20
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 22
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 28
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 30
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 31
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 36
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 38
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 39
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 41
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 44
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 46
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 47
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01 ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 56
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat170_rows:				@ 08343254
	@ pattern 170: 64 rows, played at order 200
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 47
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x10 ; ev	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 52
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 54
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 57
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 60
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 62
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
hp_pat171_rows:				@ 083434A0
	@ pattern 171: 64 rows, played at order 201
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 47
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x10 ; ev	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 52
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev	@ 54
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 56
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 57
	ev n=C_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 60
	ev n=C_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 62
	ev n=C_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
hp_pat172_rows:				@ 083436EC
	@ pattern 172: 64 rows, played at order 202
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs8-16, i=39, fx=FX_VOLUME, p=0x10	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 47
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 49
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 52
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 54
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 60
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs8-16, i=39, fx=FX_VOLUME, p=0x10	@ 62
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 63
hp_pat173_rows:				@ 08343A20
	@ pattern 173: 64 rows, played at order 203
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs8-16, i=39, fx=FX_VOLUME, p=0x10	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 47
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 49
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 52
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 54
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=C_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x05	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 60
	ev n=C_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev n=B_6-16, i=39, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 62
	ev n=C_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat174_rows:				@ 08343D58
	@ pattern 174: 64 rows, played at order 204
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x1A	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 47
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat175_rows:				@ 08343FEC
	@ pattern 175: 64 rows, played at order 205
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev fx=FX_VIBRATO, p=0x00	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x1A	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 47
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x1A	@ 48
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev ; ev	@ 49
	ev n=G_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 50
	ev n=G_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 52
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x14 ; ev ; ev fx=FX_PORTA_DN, p=0x01	@ 53
	ev n=G_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 54
	ev n=G_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 55
	ev n=G_6+14, i=43 ; ev n=C_3, i=3 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 56
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 57
	ev n=G_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x1A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 58
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 60
	ev n=G_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 61
	ev n=G_7+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x1A ; ev ; ev	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
hp_pat176_rows:				@ 08344298
	@ pattern 176: 64 rows, played at order 206
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs8-16, i=39, fx=FX_VOLUME, p=0x10	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 47
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 49
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 52
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 54
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 60
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs8-16, i=39, fx=FX_VOLUME, p=0x10	@ 62
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 63
hp_pat177_rows:				@ 083445CC
	@ pattern 177: 64 rows, played at order 207
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 07
	ev ; ev n=C_3, i=3 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 15
	ev ; ev n=C_3, i=3 ; ev n=B_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=B_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Ds7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=G_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x10	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 31
	ev ; ev n=C_3, i=3 ; ev n=D_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x10	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=As7-16, i=39, fx=FX_VOLUME, p=0x05	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev n=B_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev n=Cs8-16, i=39, fx=FX_VOLUME, p=0x10	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 47
	ev ; ev n=C_3, i=3 ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 48
	ev ; ev ; ev ; ev fx=FX_VOLSLIDE, p=0x0A	@ 49
	ev ; ev ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 50
	ev ; ev ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 51
	ev ; ev ; ev n=A_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 52
	ev ; ev ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 53
	ev ; ev ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 54
	ev ; ev ; ev ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev ; ev n=G_4, i=23, fx=FX_VOLUME, p=0x10 ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x10	@ 56
	ev ; ev ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x0A	@ 57
	ev ; ev ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 58
	ev ; ev ; ev ; ev n=F_7-16, i=39, fx=FX_VOLUME, p=0x05	@ 59
	ev ; ev ; ev n=A_4, i=24, fx=FX_VOLUME, p=0x10 ; ev n=Fs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 60
	ev ; ev ; ev ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x10	@ 61
	ev ; ev ; ev ; ev n=Gs7-16, i=39, fx=FX_VOLUME, p=0x10	@ 62
	ev ; ev ; ev ; ev fx=FX_VIBRATO, p=0x94	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat178_rows:				@ 083448C0
	@ pattern 178: 64 rows, played at order 208
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VIBRATO, p=0x00	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 03
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLSLIDE, p=0x02	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLSLIDE, p=0x02	@ 07
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 11
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev	@ 15
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev	@ 19
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 20
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev	@ 22
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 23
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev	@ 25
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 27
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9 ; ev	@ 28
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 30
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 31
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 35
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 38
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 39
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 41
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 43
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 46
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev	@ 47
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev	@ 51
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 59
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9 ; ev	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 63
hp_pat179_rows:				@ 08344BD4
	@ pattern 179: 64 rows, played at order 209
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLUME, p=0x00 ; ev fx=FX_VIBRATO, p=0x00	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 03
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VOLSLIDE, p=0x02	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VOLSLIDE, p=0x02	@ 07
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x02	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 11
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev	@ 15
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev	@ 19
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 20
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev	@ 22
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 23
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev	@ 25
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 27
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9 ; ev	@ 28
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 30
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 31
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 35
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 38
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 39
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 41
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 43
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 44
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 46
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev	@ 47
	ev ; ev ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 48
	ev ; ev ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev ; ev ; ev n=C_3, i=9 ; ev	@ 50
	ev ; ev ; ev n=D_3, i=9 ; ev	@ 51
	ev ; ev ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 52
	ev ; ev ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev ; ev n=D_3, i=9 ; ev	@ 54
	ev ; ev ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 55
	ev ; ev ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev ; ev n=D_3, i=9 ; ev	@ 57
	ev ; ev ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev	@ 58
	ev ; ev ; ev n=C_3, i=9 ; ev	@ 59
	ev ; ev ; ev n=D_3, i=9 ; ev	@ 60
	ev ; ev ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev	@ 61
	ev ; ev ; ev n=C_3, i=9 ; ev	@ 62
	ev ; ev ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 63
	.byte 0x00	@ zero padding to a word boundary
hp_pat180_rows:				@ 08344E9C
	@ pattern 180: 64 rows, played at order 210
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLUME, p=0x00 ; ev n=G_3, i=32	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=G_3, i=33	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=31	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_3, i=30	@ 07
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev n=G_3, i=28	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=G_3, i=31	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=25	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev n=G_3, i=26	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=27	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28	@ 15
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=32	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev n=A_3, i=33	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=A_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=E_3, i=9 ; ev n=A_3, i=31	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=30	@ 23
	ev ; ev n=C_3, i=3 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev n=A_3, i=29	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev n=A_3, i=31	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_3, i=9 ; ev n=A_3, i=25	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=26	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev n=A_3, i=27	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28	@ 31
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=32	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=Cs3, i=33	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=31	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=30	@ 39
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=29	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev n=Cs3, i=28	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=Cs3, i=31	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=25	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev n=Cs3, i=26	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=27	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=28	@ 47
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=32	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev n=G_3, i=33	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev n=G_3, i=31	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=30	@ 55
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev n=G_3, i=29	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev n=G_3, i=31	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9 ; ev n=G_3, i=25	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=26	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev n=G_3, i=27	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat181_rows:				@ 0834522C
	@ pattern 181: 64 rows, played at order 211
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLUME, p=0x00 ; ev n=G_3, i=32	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=G_3, i=33	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=31	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev n=G_3, i=30	@ 07
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=29	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev n=G_3, i=28	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=G_3, i=31	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=25	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev n=G_3, i=26	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=27	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28	@ 15
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=32	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev n=A_3, i=33	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=A_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=E_3, i=9 ; ev n=A_3, i=31	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=30	@ 23
	ev ; ev n=C_3, i=3 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev n=A_3, i=29	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev n=A_3, i=31	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_3, i=9 ; ev n=A_3, i=25	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=26	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev n=A_3, i=27	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=28	@ 31
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=32	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=Cs3, i=33	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x05 ; ev	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=31	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=30	@ 39
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=29	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev n=Cs3, i=28	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev n=Cs3, i=31	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=25	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev n=Cs3, i=26	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=27	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=Cs3, i=28	@ 47
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=32	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev n=G_3, i=33	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev n=G_3, i=31	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=30	@ 55
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 56
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev n=D_3, i=9 ; ev n=G_3, i=29	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x1A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev n=G_3, i=31	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x10 ; ev n=D_3, i=9 ; ev n=G_3, i=25	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=26	@ 61
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x1A ; ev n=C_3, i=9 ; ev n=G_3, i=27	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x15 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=28	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary
hp_pat182_rows:				@ 083455BC
	@ pattern 182: 64 rows, played at order 212
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 07
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 15
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x93	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=14, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=A_3, i=15, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 23
	ev ; ev n=C_3, i=3 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 31
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x93	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VIBRATO, p=0x00	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 39
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x1A	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev fx=FX_PORTA_DN, p=0x01	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x01	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x01	@ 47
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=Gs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev fx=FX_PORTA_DN, p=0x01	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x01	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x01	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x93	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev	@ 63
hp_pat183_rows:				@ 0834590C
	@ pattern 183: 64 rows, played at order 213
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLUME, p=0x00 ; ev n=Cs6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev	@ 03
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev ; ev fx=FX_VIBRATO, p=0x93	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev fx=FX_VIBRATO, p=0x00	@ 07
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 11
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 15
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=Ds6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 17
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x93	@ 19
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=A_3, i=14, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 20
	ev n=A_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=A_3, i=15, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 22
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 23
	ev ; ev n=C_3, i=3 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 25
	ev n=A_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=A_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 27
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=E_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 28
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 30
	ev n=A_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=A_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 31
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev n=As6-16, i=39, fx=FX_VOLUME, p=0x1A	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev	@ 33
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x93	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 35
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VIBRATO, p=0x00	@ 36
	ev n=C_7+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 38
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 39
	ev ; ev n=C_3, i=3 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 41
	ev n=C_7+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 43
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x1A	@ 44
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev fx=FX_PORTA_DN, p=0x01	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x01	@ 46
	ev n=C_7+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=13, fx=FX_VOLUME, p=0x0A ; ev fx=FX_PORTA_DN, p=0x01	@ 47
	ev ; ev n=C_3, i=3 ; ev n=C_3, i=9, fx=FX_VOLUME, p=0x05 ; ev n=Cs7-16, i=39, fx=FX_VOLUME, p=0x1A	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x05 ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VIBRATO, p=0x93	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 51
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=G_3, i=14, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev n=G_3, i=15, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev n=D_3, i=9 ; ev fx=FX_VIBRATO, p=0x00	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=9, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x00	@ 55
	ev ; ev n=C_3, i=3 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VIBRATO, p=0x93	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=D_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x01	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=G_3, i=11, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x01	@ 59
	ev ; ev n=C_5, i=38, fx=FX_VOLUME, p=0x20 ; ev n=D_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x01	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=10, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev n=C_3, i=9 ; ev fx=FX_VOLSLIDE, p=0x01	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev n=G_3, i=16, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x01	@ 63
	.byte 0x00, 0x00, 0x00	@ zero padding to a word boundary
hp_pat184_rows:				@ 08345C60
	@ pattern 184: 64 rows, played at order 214
	ev fx=FX_SPEED, p=0x07 ; ev n=C_3, i=3 ; ev fx=FX_VIBRATO, p=0x00 ; ev fx=FX_VOLUME, p=0x00	@ 00
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VIBRATO, p=0x00 ; ev	@ 01
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 02
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 03
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 04
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 05
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 06
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 07
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 08
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 09
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x02 ; ev	@ 10
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 11
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 12
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 13
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 14
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 15
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 16
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 17
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 18
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 19
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 20
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 21
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev ; ev	@ 22
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 23
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 24
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 25
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 26
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 27
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 28
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 29
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 30
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 31
	ev ; ev n=C_3, i=3 ; ev n=C_5, i=7, fx=FX_VOLUME, p=0x00 ; ev	@ 32
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 33
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 34
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 35
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 36
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 37
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 38
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 39
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 40
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 41
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 42
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 43
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 44
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 45
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 46
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 47
	ev ; ev n=C_3, i=3 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 48
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 49
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 50
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 51
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev ; ev	@ 52
	ev n=G_6+14, i=43 ; ev fx=FX_VOLSLIDE, p=0x04 ; ev ; ev	@ 53
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x06 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 54
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 55
	ev ; ev n=C_3, i=3 ; ev ; ev	@ 56
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 57
	ev n=G_6+14, i=43 ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev ; ev	@ 58
	ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 59
	ev ; ev n=C_3, i=3, fx=FX_VOLUME, p=0x20 ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 60
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 61
	ev ; ev n=C_5, i=21, fx=FX_VOLUME, p=0x0A ; ev fx=FX_VOLSLIDE, p=0x10 ; ev	@ 62
	ev n=G_6+14, i=43 ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x05 ; ev ; ev	@ 63
hp_pat185_rows:				@ 08345EAC
	@ pattern 185: 64 rows, played at order 215
	ev fx=FX_SPEED, p=0x07 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 00
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 01
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 02
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 03
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 04
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 05
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 06
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 07
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 08
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 09
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 10
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 11
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 12
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 13
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 14
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 15
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 16
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 17
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 18
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 19
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 20
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 21
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 22
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 23
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 24
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 25
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 26
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 27
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 28
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 29
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 30
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 31
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 32
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 33
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 34
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 35
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 36
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 37
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 38
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 39
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 40
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 41
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 42
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 43
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 44
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 45
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 46
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 47
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 48
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 49
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 50
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 51
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 52
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 53
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 54
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 55
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 56
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 57
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 58
	ev ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 59
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x2A	@ 60
	ev n=G_6+14, i=43 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 61
	ev ; ev ; ev ; ev n=F_5, i=21, fx=FX_VOLUME, p=0x0A	@ 62
	ev n=G_6+14, i=43, fx=FX_JUMP, p=0xC5 ; ev ; ev ; ev n=C_5, i=22, fx=FX_VOLUME, p=0x0A	@ 63
	.byte 0x00, 0x00	@ zero padding to a word boundary

@ 083460F8
hp_pcm_data:
	.incbin "fuh_music_pcm.bin"	@ 356636 bytes of 8-bit signed PCM
	.set hp_smp01, hp_pcm_data + 0x0
	.set hp_smp02, hp_pcm_data + 0x1AA0
	.set hp_smp03, hp_pcm_data + 0x75B0
	.set hp_smp04, hp_pcm_data + 0x79B8
	.set hp_smp05, hp_pcm_data + 0x7A80
	.set hp_smp06, hp_pcm_data + 0x892C
	.set hp_smp07, hp_pcm_data + 0xF6AC
	.set hp_smp08, hp_pcm_data + 0x15978
	.set hp_smp09, hp_pcm_data + 0x15AB8
	.set hp_smp10, hp_pcm_data + 0x15D50
	.set hp_smp11, hp_pcm_data + 0x1600C
	.set hp_smp12, hp_pcm_data + 0x163D4
	.set hp_smp13, hp_pcm_data + 0x16770
	.set hp_smp14, hp_pcm_data + 0x16AD4
	.set hp_smp15, hp_pcm_data + 0x16E60
	.set hp_smp16, hp_pcm_data + 0x17074
	.set hp_smp17, hp_pcm_data + 0x1731C
	.set hp_smp18, hp_pcm_data + 0x1755C
	.set hp_smp19, hp_pcm_data + 0x177AC
	.set hp_smp20, hp_pcm_data + 0x179EC
	.set hp_smp21, hp_pcm_data + 0x17C48
	.set hp_smp22, hp_pcm_data + 0x18628
	.set hp_smp23, hp_pcm_data + 0x18E08
	.set hp_smp24, hp_pcm_data + 0x1B0C8
	.set hp_smp25, hp_pcm_data + 0x1D6E0
	.set hp_smp26, hp_pcm_data + 0x1D848
	.set hp_smp27, hp_pcm_data + 0x1D974
	.set hp_smp28, hp_pcm_data + 0x1DA94
	.set hp_smp29, hp_pcm_data + 0x1DBDC
	.set hp_smp30, hp_pcm_data + 0x1DD24
	.set hp_smp31, hp_pcm_data + 0x1DE6C
	.set hp_smp32, hp_pcm_data + 0x1DFD4
	.set hp_smp33, hp_pcm_data + 0x1E34C
	.set hp_smp34, hp_pcm_data + 0x1E49C
	.set hp_smp35, hp_pcm_data + 0x21F68
	.set hp_smp36, hp_pcm_data + 0x251F8
	.set hp_smp37, hp_pcm_data + 0x275CC
	.set hp_smp38, hp_pcm_data + 0x275E0
	.set hp_smp39, hp_pcm_data + 0x28EE8
	.set hp_smp40, hp_pcm_data + 0x304EC
	.set hp_smp41, hp_pcm_data + 0x31100
	.set hp_smp42, hp_pcm_data + 0x3502C
	.set hp_smp43, hp_pcm_data + 0x393B4
	.set hp_smp44, hp_pcm_data + 0x3CB64
	.set hp_smp45, hp_pcm_data + 0x47EDC
	.set hp_smp46, hp_pcm_data + 0x4B8A8
	.set hp_smp47, hp_pcm_data + 0x4F7D4
	.set hp_smp48, hp_pcm_data + 0x51600
	.set hp_smp49, hp_pcm_data + 0x525D4
	.set hp_smp50, hp_pcm_data + 0x53F7C
	.set hp_smp51, hp_pcm_data + 0x54A00
	.set hp_smp52, hp_pcm_data + 0x554A4

	.section .rodata.fuh_sfx,"a",%progbits
	.balign 4

	.global hpsfx_module
hpsfx_module:				@ 0839D868
	.word 16			@ +00 channels
	.word 0			@ +04 orders
	.word 50			@ +08 (never read)
	.word 6			@ +0C speed (frames per row)
	.word hpsfx_instruments	@ +10 instrument table
	.word hpsfx_orders		@ +14 order table
hpsfx_orders:				@ 0839D880
				@ (empty order table)
	.byte 0x00, 0x00, 0x00, 0x00	@ zero padding to a word boundary
hpsfx_instruments:				@ 0839D884
	.word hpsfx_ins00	@ 0
	.word hpsfx_ins01	@ 1
	.word hpsfx_ins02	@ 2
	.word hpsfx_ins03	@ 3
	.word hpsfx_ins04	@ 4
	.word hpsfx_ins05	@ 5
	.word hpsfx_ins06	@ 6
	.word hpsfx_ins07	@ 7
	.word hpsfx_ins08	@ 8
	.word hpsfx_ins09	@ 9
	.word hpsfx_ins10	@ 10
	.word hpsfx_ins11	@ 11
	.word hpsfx_ins12	@ 12
	.word hpsfx_ins13	@ 13
	.word hpsfx_ins14	@ 14
	.word hpsfx_ins15	@ 15
	.word hpsfx_ins16	@ 16
	.word hpsfx_ins17	@ 17
hpsfx_ins00:				@ 0839D8CC
	INSTR 0, 0, 64, hpsfx_pcm00	@ one-shot
hpsfx_ins01:				@ 0839D8DC
	INSTR 0, 0, 64, hpsfx_pcm01	@ one-shot
hpsfx_ins02:				@ 0839D8EC
	INSTR 0, 0, 64, hpsfx_pcm02	@ one-shot
hpsfx_ins03:				@ 0839D8FC
	INSTR 0, 0, 64, hpsfx_pcm03	@ one-shot
hpsfx_ins04:				@ 0839D90C
	INSTR 0, 0, 64, hpsfx_pcm04	@ one-shot
hpsfx_ins05:				@ 0839D91C
	INSTR 0, 0, 64, hpsfx_pcm05	@ one-shot
hpsfx_ins06:				@ 0839D92C
	INSTR 0, 0, 64, hpsfx_pcm06	@ one-shot
hpsfx_ins07:				@ 0839D93C
	INSTR 0, 0, 64, hpsfx_pcm07	@ one-shot
hpsfx_ins08:				@ 0839D94C
	INSTR 0, 0, 64, hpsfx_pcm08	@ one-shot
hpsfx_ins09:				@ 0839D95C
	INSTR 0, 0, 64, hpsfx_pcm09	@ one-shot
hpsfx_ins10:				@ 0839D96C
	INSTR 0, 0, 64, hpsfx_pcm10	@ one-shot
hpsfx_ins11:				@ 0839D97C
	INSTR 0, 0, 64, hpsfx_pcm11	@ one-shot
hpsfx_ins12:				@ 0839D98C
	INSTR 0, 232404, 64, hpsfx_pcm12	@ loop 0-232404
hpsfx_ins13:				@ 0839D99C
	INSTR 0, 1116410, 64, hpsfx_pcm13	@ loop 0-1116410
hpsfx_ins14:				@ 0839D9AC
	INSTR 0, 0, 64, hpsfx_pcm14	@ one-shot
hpsfx_ins15:				@ 0839D9BC
	INSTR 0, 0, 64, hpsfx_pcm15	@ one-shot
hpsfx_ins16:				@ 0839D9CC
	INSTR 0, 0, 64, hpsfx_pcm16	@ one-shot
hpsfx_ins17:				@ 0839D9DC
	INSTR 0, 0, 64, hpsfx_pcm17	@ one-shot
hpsfx_pcm00:				@ 0839D9EC
	.word 6349, hpsfx_smp00
hpsfx_pcm01:				@ 0839D9F4
	.word 4807, hpsfx_smp01
hpsfx_pcm02:				@ 0839D9FC
	.word 10958, hpsfx_smp02
hpsfx_pcm03:				@ 0839DA04
	.word 16000, hpsfx_smp03
hpsfx_pcm04:				@ 0839DA0C
	.word 17728, hpsfx_smp04
hpsfx_pcm05:				@ 0839DA14
	.word 2781, hpsfx_smp05
hpsfx_pcm06:				@ 0839DA1C
	.word 3312, hpsfx_smp06
hpsfx_pcm07:				@ 0839DA24
	.word 12816, hpsfx_smp07
hpsfx_pcm08:				@ 0839DA2C
	.word 29504, hpsfx_smp08
hpsfx_pcm09:				@ 0839DA34
	.word 2464, hpsfx_smp09
hpsfx_pcm10:				@ 0839DA3C
	.word 516, hpsfx_smp10
hpsfx_pcm11:				@ 0839DA44
	.word 3168, hpsfx_smp11
hpsfx_pcm12:				@ 0839DA4C
	.word 232404, 0
hpsfx_pcm13:				@ 0839DA54
	.word 1116410, 0
hpsfx_pcm14:				@ 0839DA5C
	.word 11974, hpsfx_smp14
hpsfx_pcm15:				@ 0839DA64
	.word 4842, hpsfx_smp15
hpsfx_pcm16:				@ 0839DA6C
	.word 6468, hpsfx_smp16
hpsfx_pcm17:				@ 0839DA74
	.word 131800, hpsfx_smp17

@ 0839DA7C
hpsfx_pcm_data:
	.incbin "fuh_sfx_pcm.bin"	@ 273228 bytes of 8-bit signed PCM
	.set hpsfx_smp00, hpsfx_pcm_data + 0x0
	.set hpsfx_smp01, hpsfx_pcm_data + 0x18CD
	.set hpsfx_smp02, hpsfx_pcm_data + 0x2B94
	.set hpsfx_smp03, hpsfx_pcm_data + 0x5662
	.set hpsfx_smp04, hpsfx_pcm_data + 0x94E2
	.set hpsfx_smp05, hpsfx_pcm_data + 0xDA22
	.set hpsfx_smp06, hpsfx_pcm_data + 0xE4FF
	.set hpsfx_smp07, hpsfx_pcm_data + 0xF1EF
	.set hpsfx_smp08, hpsfx_pcm_data + 0x123FF
	.set hpsfx_smp09, hpsfx_pcm_data + 0x1973F
	.set hpsfx_smp10, hpsfx_pcm_data + 0x1A0DF
	.set hpsfx_smp11, hpsfx_pcm_data + 0x1A2E3
	.set hpsfx_smp14, hpsfx_pcm_data + 0x1CD80
	.set hpsfx_smp15, hpsfx_pcm_data + 0x1FC46
	.set hpsfx_smp16, hpsfx_pcm_data + 0x20F30
	.set hpsfx_smp17, hpsfx_pcm_data + 0x22874
