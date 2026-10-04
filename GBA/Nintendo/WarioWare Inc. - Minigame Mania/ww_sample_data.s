@ Generated from the ROM by gen_data.py; names are assigned (the ROM has no symbols apart from the
@ song name strings, which are real ROM data).
	.syntax unified

	.section .snd_pcm, "a", %progbits
@ 8-bit signed PCM of the 711 samples (plus the converter's padding bytes to the next 4-byte boundary).
@ ww_sample_pcm.bin is extracted by "ww_tool.py extract" (ROM 0x08155D74-0x08316338).

	.global smp_000_pcm
smp_000_pcm:
	.incbin "ww_sample_pcm.bin", 0x0, 2780
	.global smp_001_pcm
smp_001_pcm:
	.incbin "ww_sample_pcm.bin", 0xADC, 2472
	.global smp_002_pcm
smp_002_pcm:
	.incbin "ww_sample_pcm.bin", 0x1484, 4752
	.global smp_003_pcm
smp_003_pcm:
	.incbin "ww_sample_pcm.bin", 0x2714, 1192
	.global smp_004_pcm
smp_004_pcm:
	.incbin "ww_sample_pcm.bin", 0x2BBC, 712
	.global smp_005_pcm
smp_005_pcm:
	.incbin "ww_sample_pcm.bin", 0x2E84, 7108
	.global smp_006_pcm
smp_006_pcm:
	.incbin "ww_sample_pcm.bin", 0x4A48, 9636
	.global smp_007_pcm
smp_007_pcm:
	.incbin "ww_sample_pcm.bin", 0x6FEC, 10640
	.global smp_008_pcm
smp_008_pcm:
	.incbin "ww_sample_pcm.bin", 0x997C, 1620
	.global smp_009_pcm
smp_009_pcm:
	.incbin "ww_sample_pcm.bin", 0x9FD0, 2264
	.global smp_010_pcm
smp_010_pcm:
	.incbin "ww_sample_pcm.bin", 0xA8A8, 4352
	.global smp_011_pcm
smp_011_pcm:
	.incbin "ww_sample_pcm.bin", 0xB9A8, 5500
	.global smp_012_pcm
smp_012_pcm:
	.incbin "ww_sample_pcm.bin", 0xCF24, 660
	.global smp_013_pcm
smp_013_pcm:
	.incbin "ww_sample_pcm.bin", 0xD1B8, 3228
	.global smp_014_pcm
smp_014_pcm:
	.incbin "ww_sample_pcm.bin", 0xDE54, 9356
	.global smp_015_pcm
smp_015_pcm:
	.incbin "ww_sample_pcm.bin", 0x102E0, 132
	.global smp_016_pcm
smp_016_pcm:
	.incbin "ww_sample_pcm.bin", 0x10364, 312
	.global smp_017_pcm
smp_017_pcm:
	.incbin "ww_sample_pcm.bin", 0x1049C, 9444
	.global smp_018_pcm
smp_018_pcm:
	.incbin "ww_sample_pcm.bin", 0x12980, 1280
	.global smp_019_pcm
smp_019_pcm:
	.incbin "ww_sample_pcm.bin", 0x12E80, 9012
	.global smp_020_pcm
smp_020_pcm:
	.incbin "ww_sample_pcm.bin", 0x151B4, 3460
	.global smp_021_pcm
smp_021_pcm:
	.incbin "ww_sample_pcm.bin", 0x15F38, 6712
	.global smp_022_pcm
smp_022_pcm:
	.incbin "ww_sample_pcm.bin", 0x17970, 1348
	.global smp_023_pcm
smp_023_pcm:
	.incbin "ww_sample_pcm.bin", 0x17EB4, 492
	.global smp_024_pcm
smp_024_pcm:
	.incbin "ww_sample_pcm.bin", 0x180A0, 3920
	.global smp_025_pcm
smp_025_pcm:
	.incbin "ww_sample_pcm.bin", 0x18FF0, 1312
	.global smp_026_pcm
smp_026_pcm:
	.incbin "ww_sample_pcm.bin", 0x19510, 7000
	.global smp_027_pcm
smp_027_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B068, 4900
	.global smp_028_pcm
smp_028_pcm:
	.incbin "ww_sample_pcm.bin", 0x1C38C, 5032
	.global smp_029_pcm
smp_029_pcm:
	.incbin "ww_sample_pcm.bin", 0x1D734, 3140
	.global smp_030_pcm
smp_030_pcm:
	.incbin "ww_sample_pcm.bin", 0x1E378, 2256
	.global smp_031_pcm
smp_031_pcm:
	.incbin "ww_sample_pcm.bin", 0x1EC48, 2444
	.global smp_032_pcm
smp_032_pcm:
	.incbin "ww_sample_pcm.bin", 0x1F5D4, 24896
	.global smp_033_pcm
smp_033_pcm:
	.incbin "ww_sample_pcm.bin", 0x25714, 1000
	.global smp_034_pcm
smp_034_pcm:
	.incbin "ww_sample_pcm.bin", 0x25AFC, 776
	.global smp_035_pcm
smp_035_pcm:
	.incbin "ww_sample_pcm.bin", 0x25E04, 1052
	.global smp_036_pcm
smp_036_pcm:
	.incbin "ww_sample_pcm.bin", 0x26220, 1500
	.global smp_037_pcm
smp_037_pcm:
	.incbin "ww_sample_pcm.bin", 0x267FC, 952
	.global smp_038_pcm
smp_038_pcm:
	.incbin "ww_sample_pcm.bin", 0x26BB4, 900
	.global smp_039_pcm
smp_039_pcm:
	.incbin "ww_sample_pcm.bin", 0x26F38, 6120
	.global smp_040_pcm
smp_040_pcm:
	.incbin "ww_sample_pcm.bin", 0x28720, 7244
	.global smp_041_pcm
smp_041_pcm:
	.incbin "ww_sample_pcm.bin", 0x2A36C, 2372
	.global smp_042_pcm
smp_042_pcm:
	.incbin "ww_sample_pcm.bin", 0x2ACB0, 780
	.global smp_043_pcm
smp_043_pcm:
	.incbin "ww_sample_pcm.bin", 0x2AFBC, 1716
	.global smp_044_pcm
smp_044_pcm:
	.incbin "ww_sample_pcm.bin", 0x2B670, 1924
	.global smp_045_pcm
smp_045_pcm:
	.incbin "ww_sample_pcm.bin", 0x2BDF4, 2228
	.global smp_046_pcm
smp_046_pcm:
	.incbin "ww_sample_pcm.bin", 0x2C6A8, 4484
	.global smp_047_pcm
smp_047_pcm:
	.incbin "ww_sample_pcm.bin", 0x2D82C, 4608
	.global smp_048_pcm
smp_048_pcm:
	.incbin "ww_sample_pcm.bin", 0x2EA2C, 4792
	.global smp_049_pcm
smp_049_pcm:
	.incbin "ww_sample_pcm.bin", 0x2FCE4, 4480
	.global smp_050_pcm
smp_050_pcm:
	.incbin "ww_sample_pcm.bin", 0x30E64, 7932
	.global smp_051_pcm
smp_051_pcm:
	.incbin "ww_sample_pcm.bin", 0x32D60, 10656
	.global smp_052_pcm
smp_052_pcm:
	.incbin "ww_sample_pcm.bin", 0x35700, 5088
	.global smp_053_pcm
smp_053_pcm:
	.incbin "ww_sample_pcm.bin", 0x36AE0, 17320
	.global smp_054_pcm
smp_054_pcm:
	.incbin "ww_sample_pcm.bin", 0x3AE88, 21712
	.global smp_055_pcm
smp_055_pcm:
	.incbin "ww_sample_pcm.bin", 0x40358, 2048
	.global smp_056_pcm
smp_056_pcm:
	.incbin "ww_sample_pcm.bin", 0x40B58, 4956
	.global smp_057_pcm
smp_057_pcm:
	.incbin "ww_sample_pcm.bin", 0x41EB4, 4952
	.global smp_058_pcm
smp_058_pcm:
	.incbin "ww_sample_pcm.bin", 0x4320C, 4248
	.global smp_059_pcm
smp_059_pcm:
	.incbin "ww_sample_pcm.bin", 0x442A4, 2264
	.global smp_060_pcm
smp_060_pcm:
	.incbin "ww_sample_pcm.bin", 0x44B7C, 6156
	.global smp_061_pcm
smp_061_pcm:
	.incbin "ww_sample_pcm.bin", 0x46388, 5940
	.global smp_062_pcm
smp_062_pcm:
	.incbin "ww_sample_pcm.bin", 0x47ABC, 1580
	.global smp_063_pcm
smp_063_pcm:
	.incbin "ww_sample_pcm.bin", 0x480E8, 3984
	.global smp_064_pcm
smp_064_pcm:
	.incbin "ww_sample_pcm.bin", 0x49078, 6772
	.global smp_065_pcm
smp_065_pcm:
	.incbin "ww_sample_pcm.bin", 0x4AAEC, 7020
	.global smp_066_pcm
smp_066_pcm:
	.incbin "ww_sample_pcm.bin", 0x4C658, 2284
	.global smp_067_pcm
smp_067_pcm:
	.incbin "ww_sample_pcm.bin", 0x4CF44, 8232
	.global smp_068_pcm
smp_068_pcm:
	.incbin "ww_sample_pcm.bin", 0x4EF6C, 4196
	.global smp_069_pcm
smp_069_pcm:
	.incbin "ww_sample_pcm.bin", 0x4FFD0, 5172
	.global smp_070_pcm
smp_070_pcm:
	.incbin "ww_sample_pcm.bin", 0x51404, 12660
	.global smp_071_pcm
smp_071_pcm:
	.incbin "ww_sample_pcm.bin", 0x54578, 656
	.global smp_072_pcm
smp_072_pcm:
	.incbin "ww_sample_pcm.bin", 0x54808, 2512
	.global smp_073_pcm
smp_073_pcm:
	.incbin "ww_sample_pcm.bin", 0x551D8, 3588
	.global smp_074_pcm
smp_074_pcm:
	.incbin "ww_sample_pcm.bin", 0x55FDC, 2452
	.global smp_075_pcm
smp_075_pcm:
	.incbin "ww_sample_pcm.bin", 0x56970, 924
	.global smp_076_pcm
smp_076_pcm:
	.incbin "ww_sample_pcm.bin", 0x56D0C, 1988
	.global smp_077_pcm
smp_077_pcm:
	.incbin "ww_sample_pcm.bin", 0x574D0, 348
	.global smp_078_pcm
smp_078_pcm:
	.incbin "ww_sample_pcm.bin", 0x5762C, 4696
	.global smp_079_pcm
smp_079_pcm:
	.incbin "ww_sample_pcm.bin", 0x58884, 8924
	.global smp_080_pcm
smp_080_pcm:
	.incbin "ww_sample_pcm.bin", 0x5AB60, 1848
	.global smp_081_pcm
smp_081_pcm:
	.incbin "ww_sample_pcm.bin", 0x5B298, 5472
	.global smp_082_pcm
smp_082_pcm:
	.incbin "ww_sample_pcm.bin", 0x5C7F8, 8528
	.global smp_083_pcm
smp_083_pcm:
	.incbin "ww_sample_pcm.bin", 0x5E948, 4140
	.global smp_084_pcm
smp_084_pcm:
	.incbin "ww_sample_pcm.bin", 0x5F974, 2492
	.global smp_085_pcm
smp_085_pcm:
	.incbin "ww_sample_pcm.bin", 0x60330, 5764
	.global smp_086_pcm
smp_086_pcm:
	.incbin "ww_sample_pcm.bin", 0x619B4, 1172
	.global smp_087_pcm
smp_087_pcm:
	.incbin "ww_sample_pcm.bin", 0x61E48, 840
	.global smp_088_pcm
smp_088_pcm:
	.incbin "ww_sample_pcm.bin", 0x62190, 2540
	.global smp_089_pcm
smp_089_pcm:
	.incbin "ww_sample_pcm.bin", 0x62B7C, 1900
	.global smp_090_pcm
smp_090_pcm:
	.incbin "ww_sample_pcm.bin", 0x632E8, 1336
	.global smp_091_pcm
smp_091_pcm:
	.incbin "ww_sample_pcm.bin", 0x63820, 2300
	.global smp_092_pcm
smp_092_pcm:
	.incbin "ww_sample_pcm.bin", 0x6411C, 884
	.global smp_093_pcm
smp_093_pcm:
	.incbin "ww_sample_pcm.bin", 0x64490, 460
	.global smp_094_pcm
smp_094_pcm:
	.incbin "ww_sample_pcm.bin", 0x6465C, 956
	.global smp_095_pcm
smp_095_pcm:
	.incbin "ww_sample_pcm.bin", 0x64A18, 1580
	.global smp_096_pcm
smp_096_pcm:
	.incbin "ww_sample_pcm.bin", 0x65044, 4012
	.global smp_097_pcm
smp_097_pcm:
	.incbin "ww_sample_pcm.bin", 0x65FF0, 4432
	.global smp_098_pcm
smp_098_pcm:
	.incbin "ww_sample_pcm.bin", 0x67140, 2980
	.global smp_099_pcm
smp_099_pcm:
	.incbin "ww_sample_pcm.bin", 0x67CE4, 2144
	.global smp_100_pcm
smp_100_pcm:
	.incbin "ww_sample_pcm.bin", 0x68544, 2164
	.global smp_101_pcm
smp_101_pcm:
	.incbin "ww_sample_pcm.bin", 0x68DB8, 2428
	.global smp_102_pcm
smp_102_pcm:
	.incbin "ww_sample_pcm.bin", 0x69734, 1212
	.global smp_103_pcm
smp_103_pcm:
	.incbin "ww_sample_pcm.bin", 0x69BF0, 2524
	.global smp_104_pcm
smp_104_pcm:
	.incbin "ww_sample_pcm.bin", 0x6A5CC, 2200
	.global smp_105_pcm
smp_105_pcm:
	.incbin "ww_sample_pcm.bin", 0x6AE64, 3168
	.global smp_106_pcm
smp_106_pcm:
	.incbin "ww_sample_pcm.bin", 0x6BAC4, 2540
	.global smp_107_pcm
smp_107_pcm:
	.incbin "ww_sample_pcm.bin", 0x6C4B0, 3828
	.global smp_108_pcm
smp_108_pcm:
	.incbin "ww_sample_pcm.bin", 0x6D3A4, 1356
	.global smp_109_pcm
smp_109_pcm:
	.incbin "ww_sample_pcm.bin", 0x6D8F0, 2908
	.global smp_110_pcm
smp_110_pcm:
	.incbin "ww_sample_pcm.bin", 0x6E44C, 1820
	.global smp_111_pcm
smp_111_pcm:
	.incbin "ww_sample_pcm.bin", 0x6EB68, 2876
	.global smp_112_pcm
smp_112_pcm:
	.incbin "ww_sample_pcm.bin", 0x6F6A4, 1152
	.global smp_113_pcm
smp_113_pcm:
	.incbin "ww_sample_pcm.bin", 0x6FB24, 3060
	.global smp_114_pcm
smp_114_pcm:
	.incbin "ww_sample_pcm.bin", 0x70718, 6824
	.global smp_115_pcm
smp_115_pcm:
	.incbin "ww_sample_pcm.bin", 0x721C0, 2672
	.global smp_116_pcm
smp_116_pcm:
	.incbin "ww_sample_pcm.bin", 0x72C30, 2968
	.global smp_117_pcm
smp_117_pcm:
	.incbin "ww_sample_pcm.bin", 0x737C8, 600
	.global smp_118_pcm
smp_118_pcm:
	.incbin "ww_sample_pcm.bin", 0x73A20, 8488
	.global smp_119_pcm
smp_119_pcm:
	.incbin "ww_sample_pcm.bin", 0x75B48, 548
	.global smp_120_pcm
smp_120_pcm:
	.incbin "ww_sample_pcm.bin", 0x75D6C, 1484
	.global smp_121_pcm
smp_121_pcm:
	.incbin "ww_sample_pcm.bin", 0x76338, 1924
	.global smp_122_pcm
smp_122_pcm:
	.incbin "ww_sample_pcm.bin", 0x76ABC, 2632
	.global smp_123_pcm
smp_123_pcm:
	.incbin "ww_sample_pcm.bin", 0x77504, 3104
	.global smp_124_pcm
smp_124_pcm:
	.incbin "ww_sample_pcm.bin", 0x78124, 4092
	.global smp_125_pcm
smp_125_pcm:
	.incbin "ww_sample_pcm.bin", 0x79120, 5452
	.global smp_126_pcm
smp_126_pcm:
	.incbin "ww_sample_pcm.bin", 0x7A66C, 4348
	.global smp_127_pcm
smp_127_pcm:
	.incbin "ww_sample_pcm.bin", 0x7B768, 6680
	.global smp_128_pcm
smp_128_pcm:
	.incbin "ww_sample_pcm.bin", 0x7D180, 1968
	.global smp_129_pcm
smp_129_pcm:
	.incbin "ww_sample_pcm.bin", 0x7D930, 2200
	.global smp_130_pcm
smp_130_pcm:
	.incbin "ww_sample_pcm.bin", 0x7E1C8, 1316
	.global smp_131_pcm
smp_131_pcm:
	.incbin "ww_sample_pcm.bin", 0x7E6EC, 2016
	.global smp_132_pcm
smp_132_pcm:
	.incbin "ww_sample_pcm.bin", 0x7EECC, 1456
	.global smp_133_pcm
smp_133_pcm:
	.incbin "ww_sample_pcm.bin", 0x7F47C, 3908
	.global smp_134_pcm
smp_134_pcm:
	.incbin "ww_sample_pcm.bin", 0x803C0, 1956
	.global smp_135_pcm
smp_135_pcm:
	.incbin "ww_sample_pcm.bin", 0x80B64, 1840
	.global smp_136_pcm
smp_136_pcm:
	.incbin "ww_sample_pcm.bin", 0x81294, 5676
	.global smp_137_pcm
smp_137_pcm:
	.incbin "ww_sample_pcm.bin", 0x828C0, 3980
	.global smp_138_pcm
smp_138_pcm:
	.incbin "ww_sample_pcm.bin", 0x8384C, 448
	.global smp_139_pcm
smp_139_pcm:
	.incbin "ww_sample_pcm.bin", 0x83A0C, 928
	.global smp_140_pcm
smp_140_pcm:
	.incbin "ww_sample_pcm.bin", 0x83DAC, 3508
	.global smp_141_pcm
smp_141_pcm:
	.incbin "ww_sample_pcm.bin", 0x84B60, 3532
	.global smp_142_pcm
smp_142_pcm:
	.incbin "ww_sample_pcm.bin", 0x8592C, 1912
	.global smp_143_pcm
smp_143_pcm:
	.incbin "ww_sample_pcm.bin", 0x860A4, 912
	.global smp_144_pcm
smp_144_pcm:
	.incbin "ww_sample_pcm.bin", 0x86434, 360
	.global smp_145_pcm
smp_145_pcm:
	.incbin "ww_sample_pcm.bin", 0x8659C, 1976
	.global smp_146_pcm
smp_146_pcm:
	.incbin "ww_sample_pcm.bin", 0x86D54, 680
	.global smp_147_pcm
smp_147_pcm:
	.incbin "ww_sample_pcm.bin", 0x86FFC, 880
	.global smp_148_pcm
smp_148_pcm:
	.incbin "ww_sample_pcm.bin", 0x8736C, 2136
	.global smp_149_pcm
smp_149_pcm:
	.incbin "ww_sample_pcm.bin", 0x87BC4, 4032
	.global smp_150_pcm
smp_150_pcm:
	.incbin "ww_sample_pcm.bin", 0x88B84, 1344
	.global smp_151_pcm
smp_151_pcm:
	.incbin "ww_sample_pcm.bin", 0x890C4, 2364
	.global smp_152_pcm
smp_152_pcm:
	.incbin "ww_sample_pcm.bin", 0x89A00, 2428
	.global smp_153_pcm
smp_153_pcm:
	.incbin "ww_sample_pcm.bin", 0x8A37C, 844
	.global smp_154_pcm
smp_154_pcm:
	.incbin "ww_sample_pcm.bin", 0x8A6C8, 1340
	.global smp_155_pcm
smp_155_pcm:
	.incbin "ww_sample_pcm.bin", 0x8AC04, 2772
	.global smp_156_pcm
smp_156_pcm:
	.incbin "ww_sample_pcm.bin", 0x8B6D8, 900
	.global smp_157_pcm
smp_157_pcm:
	.incbin "ww_sample_pcm.bin", 0x8BA5C, 884
	.global smp_158_pcm
smp_158_pcm:
	.incbin "ww_sample_pcm.bin", 0x8BDD0, 1136
	.global smp_159_pcm
smp_159_pcm:
	.incbin "ww_sample_pcm.bin", 0x8C240, 2240
	.global smp_160_pcm
smp_160_pcm:
	.incbin "ww_sample_pcm.bin", 0x8CB00, 3396
	.global smp_161_pcm
smp_161_pcm:
	.incbin "ww_sample_pcm.bin", 0x8D844, 6068
	.global smp_162_pcm
smp_162_pcm:
	.incbin "ww_sample_pcm.bin", 0x8EFF8, 4804
	.global smp_163_pcm
smp_163_pcm:
	.incbin "ww_sample_pcm.bin", 0x902BC, 1828
	.global smp_164_pcm
smp_164_pcm:
	.incbin "ww_sample_pcm.bin", 0x909E0, 1180
	.global smp_165_pcm
smp_165_pcm:
	.incbin "ww_sample_pcm.bin", 0x90E7C, 1136
	.global smp_166_pcm
smp_166_pcm:
	.incbin "ww_sample_pcm.bin", 0x912EC, 1064
	.global smp_167_pcm
smp_167_pcm:
	.incbin "ww_sample_pcm.bin", 0x91714, 692
	.global smp_168_pcm
smp_168_pcm:
	.incbin "ww_sample_pcm.bin", 0x919C8, 1012
	.global smp_169_pcm
smp_169_pcm:
	.incbin "ww_sample_pcm.bin", 0x91DBC, 2064
	.global smp_170_pcm
smp_170_pcm:
	.incbin "ww_sample_pcm.bin", 0x925CC, 4636
	.global smp_171_pcm
smp_171_pcm:
	.incbin "ww_sample_pcm.bin", 0x937E8, 2800
	.global smp_172_pcm
smp_172_pcm:
	.incbin "ww_sample_pcm.bin", 0x942D8, 5060
	.global smp_173_pcm
smp_173_pcm:
	.incbin "ww_sample_pcm.bin", 0x9569C, 8056
	.global smp_174_pcm
smp_174_pcm:
	.incbin "ww_sample_pcm.bin", 0x97614, 1188
	.global smp_175_pcm
smp_175_pcm:
	.incbin "ww_sample_pcm.bin", 0x97AB8, 6676
	.global smp_176_pcm
smp_176_pcm:
	.incbin "ww_sample_pcm.bin", 0x994CC, 8032
	.global smp_177_pcm
smp_177_pcm:
	.incbin "ww_sample_pcm.bin", 0x9B42C, 9504
	.global smp_178_pcm
smp_178_pcm:
	.incbin "ww_sample_pcm.bin", 0x9D94C, 1084
	.global smp_179_pcm
smp_179_pcm:
	.incbin "ww_sample_pcm.bin", 0x9DD88, 2400
	.global smp_180_pcm
smp_180_pcm:
	.incbin "ww_sample_pcm.bin", 0x9E6E8, 2424
	.global smp_181_pcm
smp_181_pcm:
	.incbin "ww_sample_pcm.bin", 0x9F060, 5492
	.global smp_182_pcm
smp_182_pcm:
	.incbin "ww_sample_pcm.bin", 0xA05D4, 2716
	.global smp_183_pcm
smp_183_pcm:
	.incbin "ww_sample_pcm.bin", 0xA1070, 3348
	.global smp_184_pcm
smp_184_pcm:
	.incbin "ww_sample_pcm.bin", 0xA1D84, 452
	.global smp_185_pcm
smp_185_pcm:
	.incbin "ww_sample_pcm.bin", 0xA1F48, 1124
	.global smp_186_pcm
smp_186_pcm:
	.incbin "ww_sample_pcm.bin", 0xA23AC, 824
	.global smp_187_pcm
smp_187_pcm:
	.incbin "ww_sample_pcm.bin", 0xA26E4, 1372
	.global smp_188_pcm
smp_188_pcm:
	.incbin "ww_sample_pcm.bin", 0xA2C40, 1572
	.global smp_189_pcm
smp_189_pcm:
	.incbin "ww_sample_pcm.bin", 0xA3264, 852
	.global smp_190_pcm
smp_190_pcm:
	.incbin "ww_sample_pcm.bin", 0xA35B8, 1000
	.global smp_191_pcm
smp_191_pcm:
	.incbin "ww_sample_pcm.bin", 0xA39A0, 3196
	.global smp_192_pcm
smp_192_pcm:
	.incbin "ww_sample_pcm.bin", 0xA461C, 2816
	.global smp_193_pcm
smp_193_pcm:
	.incbin "ww_sample_pcm.bin", 0xA511C, 2576
	.global smp_194_pcm
smp_194_pcm:
	.incbin "ww_sample_pcm.bin", 0xA5B2C, 4224
	.global smp_195_pcm
smp_195_pcm:
	.incbin "ww_sample_pcm.bin", 0xA6BAC, 1020
	.global smp_196_pcm
smp_196_pcm:
	.incbin "ww_sample_pcm.bin", 0xA6FA8, 576
	.global smp_197_pcm
smp_197_pcm:
	.incbin "ww_sample_pcm.bin", 0xA71E8, 1364
	.global smp_198_pcm
smp_198_pcm:
	.incbin "ww_sample_pcm.bin", 0xA773C, 504
	.global smp_199_pcm
smp_199_pcm:
	.incbin "ww_sample_pcm.bin", 0xA7934, 804
	.global smp_200_pcm
smp_200_pcm:
	.incbin "ww_sample_pcm.bin", 0xA7C58, 1464
	.global smp_201_pcm
smp_201_pcm:
	.incbin "ww_sample_pcm.bin", 0xA8210, 704
	.global smp_202_pcm
smp_202_pcm:
	.incbin "ww_sample_pcm.bin", 0xA84D0, 1096
	.global smp_203_pcm
smp_203_pcm:
	.incbin "ww_sample_pcm.bin", 0xA8918, 456
	.global smp_204_pcm
smp_204_pcm:
	.incbin "ww_sample_pcm.bin", 0xA8AE0, 744
	.global smp_205_pcm
smp_205_pcm:
	.incbin "ww_sample_pcm.bin", 0xA8DC8, 2288
	.global smp_206_pcm
smp_206_pcm:
	.incbin "ww_sample_pcm.bin", 0xA96B8, 1588
	.global smp_207_pcm
smp_207_pcm:
	.incbin "ww_sample_pcm.bin", 0xA9CEC, 2156
	.global smp_208_pcm
smp_208_pcm:
	.incbin "ww_sample_pcm.bin", 0xAA558, 2300
	.global smp_209_pcm
smp_209_pcm:
	.incbin "ww_sample_pcm.bin", 0xAAE54, 1848
	.global smp_210_pcm
smp_210_pcm:
	.incbin "ww_sample_pcm.bin", 0xAB58C, 1476
	.global smp_211_pcm
smp_211_pcm:
	.incbin "ww_sample_pcm.bin", 0xABB50, 2192
	.global smp_212_pcm
smp_212_pcm:
	.incbin "ww_sample_pcm.bin", 0xAC3E0, 2028
	.global smp_213_pcm
smp_213_pcm:
	.incbin "ww_sample_pcm.bin", 0xACBCC, 4
	.global smp_214_pcm
smp_214_pcm:
	.incbin "ww_sample_pcm.bin", 0xACBD0, 4
	.global smp_215_pcm
smp_215_pcm:
	.incbin "ww_sample_pcm.bin", 0xACBD4, 4
	.global smp_216_pcm
smp_216_pcm:
	.incbin "ww_sample_pcm.bin", 0xACBD8, 2412
	.global smp_217_pcm
smp_217_pcm:
	.incbin "ww_sample_pcm.bin", 0xAD544, 4492
	.global smp_218_pcm
smp_218_pcm:
	.incbin "ww_sample_pcm.bin", 0xAE6D0, 1820
	.global smp_219_pcm
smp_219_pcm:
	.incbin "ww_sample_pcm.bin", 0xAEDEC, 3516
	.global smp_220_pcm
smp_220_pcm:
	.incbin "ww_sample_pcm.bin", 0xAFBA8, 2540
	.global smp_221_pcm
smp_221_pcm:
	.incbin "ww_sample_pcm.bin", 0xB0594, 3716
	.global smp_222_pcm
smp_222_pcm:
	.incbin "ww_sample_pcm.bin", 0xB1418, 2572
	.global smp_223_pcm
smp_223_pcm:
	.incbin "ww_sample_pcm.bin", 0xB1E24, 4680
	.global smp_224_pcm
smp_224_pcm:
	.incbin "ww_sample_pcm.bin", 0xB306C, 1780
	.global smp_225_pcm
smp_225_pcm:
	.incbin "ww_sample_pcm.bin", 0xB3760, 1964
	.global smp_226_pcm
smp_226_pcm:
	.incbin "ww_sample_pcm.bin", 0xB3F0C, 328
	.global smp_227_pcm
smp_227_pcm:
	.incbin "ww_sample_pcm.bin", 0xB4054, 1504
	.global smp_228_pcm
smp_228_pcm:
	.incbin "ww_sample_pcm.bin", 0xB4634, 300
	.global smp_229_pcm
smp_229_pcm:
	.incbin "ww_sample_pcm.bin", 0xB4760, 2636
	.global smp_230_pcm
smp_230_pcm:
	.incbin "ww_sample_pcm.bin", 0xB51AC, 464
	.global smp_231_pcm
smp_231_pcm:
	.incbin "ww_sample_pcm.bin", 0xB537C, 252
	.global smp_232_pcm
smp_232_pcm:
	.incbin "ww_sample_pcm.bin", 0xB5478, 636
	.global smp_233_pcm
smp_233_pcm:
	.incbin "ww_sample_pcm.bin", 0xB56F4, 1244
	.global smp_234_pcm
smp_234_pcm:
	.incbin "ww_sample_pcm.bin", 0xB5BD0, 5272
	.global smp_235_pcm
smp_235_pcm:
	.incbin "ww_sample_pcm.bin", 0xB7068, 5092
	.global smp_236_pcm
smp_236_pcm:
	.incbin "ww_sample_pcm.bin", 0xB844C, 2556
	.global smp_237_pcm
smp_237_pcm:
	.incbin "ww_sample_pcm.bin", 0xB8E48, 2164
	.global smp_238_pcm
smp_238_pcm:
	.incbin "ww_sample_pcm.bin", 0xB96BC, 3024
	.global smp_239_pcm
smp_239_pcm:
	.incbin "ww_sample_pcm.bin", 0xBA28C, 1476
	.global smp_240_pcm
smp_240_pcm:
	.incbin "ww_sample_pcm.bin", 0xBA850, 1944
	.global smp_241_pcm
smp_241_pcm:
	.incbin "ww_sample_pcm.bin", 0xBAFE8, 3140
	.global smp_242_pcm
smp_242_pcm:
	.incbin "ww_sample_pcm.bin", 0xBBC2C, 552
	.global smp_243_pcm
smp_243_pcm:
	.incbin "ww_sample_pcm.bin", 0xBBE54, 540
	.global smp_244_pcm
smp_244_pcm:
	.incbin "ww_sample_pcm.bin", 0xBC070, 1708
	.global smp_245_pcm
smp_245_pcm:
	.incbin "ww_sample_pcm.bin", 0xBC71C, 636
	.global smp_246_pcm
smp_246_pcm:
	.incbin "ww_sample_pcm.bin", 0xBC998, 2780
	.global smp_247_pcm
smp_247_pcm:
	.incbin "ww_sample_pcm.bin", 0xBD474, 1512
	.global smp_248_pcm
smp_248_pcm:
	.incbin "ww_sample_pcm.bin", 0xBDA5C, 1236
	.global smp_249_pcm
smp_249_pcm:
	.incbin "ww_sample_pcm.bin", 0xBDF30, 2392
	.global smp_250_pcm
smp_250_pcm:
	.incbin "ww_sample_pcm.bin", 0xBE888, 2060
	.global smp_251_pcm
smp_251_pcm:
	.incbin "ww_sample_pcm.bin", 0xBF094, 1564
	.global smp_252_pcm
smp_252_pcm:
	.incbin "ww_sample_pcm.bin", 0xBF6B0, 908
	.global smp_253_pcm
smp_253_pcm:
	.incbin "ww_sample_pcm.bin", 0xBFA3C, 1408
	.global smp_254_pcm
smp_254_pcm:
	.incbin "ww_sample_pcm.bin", 0xBFFBC, 2772
	.global smp_255_pcm
smp_255_pcm:
	.incbin "ww_sample_pcm.bin", 0xC0A90, 880
	.global smp_256_pcm
smp_256_pcm:
	.incbin "ww_sample_pcm.bin", 0xC0E00, 1912
	.global smp_257_pcm
smp_257_pcm:
	.incbin "ww_sample_pcm.bin", 0xC1578, 2124
	.global smp_258_pcm
smp_258_pcm:
	.incbin "ww_sample_pcm.bin", 0xC1DC4, 724
	.global smp_259_pcm
smp_259_pcm:
	.incbin "ww_sample_pcm.bin", 0xC2098, 2460
	.global smp_260_pcm
smp_260_pcm:
	.incbin "ww_sample_pcm.bin", 0xC2A34, 2732
	.global smp_261_pcm
smp_261_pcm:
	.incbin "ww_sample_pcm.bin", 0xC34E0, 2340
	.global smp_262_pcm
smp_262_pcm:
	.incbin "ww_sample_pcm.bin", 0xC3E04, 2004
	.global smp_263_pcm
smp_263_pcm:
	.incbin "ww_sample_pcm.bin", 0xC45D8, 2744
	.global smp_264_pcm
smp_264_pcm:
	.incbin "ww_sample_pcm.bin", 0xC5090, 2088
	.global smp_265_pcm
smp_265_pcm:
	.incbin "ww_sample_pcm.bin", 0xC58B8, 4068
	.global smp_266_pcm
smp_266_pcm:
	.incbin "ww_sample_pcm.bin", 0xC689C, 1280
	.global smp_267_pcm
smp_267_pcm:
	.incbin "ww_sample_pcm.bin", 0xC6D9C, 1944
	.global smp_268_pcm
smp_268_pcm:
	.incbin "ww_sample_pcm.bin", 0xC7534, 1264
	.global smp_269_pcm
smp_269_pcm:
	.incbin "ww_sample_pcm.bin", 0xC7A24, 1244
	.global smp_270_pcm
smp_270_pcm:
	.incbin "ww_sample_pcm.bin", 0xC7F00, 1416
	.global smp_271_pcm
smp_271_pcm:
	.incbin "ww_sample_pcm.bin", 0xC8488, 2996
	.global smp_272_pcm
smp_272_pcm:
	.incbin "ww_sample_pcm.bin", 0xC903C, 3520
	.global smp_273_pcm
smp_273_pcm:
	.incbin "ww_sample_pcm.bin", 0xC9DFC, 6828
	.global smp_274_pcm
smp_274_pcm:
	.incbin "ww_sample_pcm.bin", 0xCB8A8, 1580
	.global smp_275_pcm
smp_275_pcm:
	.incbin "ww_sample_pcm.bin", 0xCBED4, 2364
	.global smp_276_pcm
smp_276_pcm:
	.incbin "ww_sample_pcm.bin", 0xCC810, 1940
	.global smp_277_pcm
smp_277_pcm:
	.incbin "ww_sample_pcm.bin", 0xCCFA4, 4220
	.global smp_278_pcm
smp_278_pcm:
	.incbin "ww_sample_pcm.bin", 0xCE020, 2216
	.global smp_279_pcm
smp_279_pcm:
	.incbin "ww_sample_pcm.bin", 0xCE8C8, 1328
	.global smp_280_pcm
smp_280_pcm:
	.incbin "ww_sample_pcm.bin", 0xCEDF8, 3032
	.global smp_281_pcm
smp_281_pcm:
	.incbin "ww_sample_pcm.bin", 0xCF9D0, 3120
	.global smp_282_pcm
smp_282_pcm:
	.incbin "ww_sample_pcm.bin", 0xD0600, 3376
	.global smp_283_pcm
smp_283_pcm:
	.incbin "ww_sample_pcm.bin", 0xD1330, 3648
	.global smp_284_pcm
smp_284_pcm:
	.incbin "ww_sample_pcm.bin", 0xD2170, 2352
	.global smp_285_pcm
smp_285_pcm:
	.incbin "ww_sample_pcm.bin", 0xD2AA0, 3568
	.global smp_286_pcm
smp_286_pcm:
	.incbin "ww_sample_pcm.bin", 0xD3890, 2352
	.global smp_287_pcm
smp_287_pcm:
	.incbin "ww_sample_pcm.bin", 0xD41C0, 3532
	.global smp_288_pcm
smp_288_pcm:
	.incbin "ww_sample_pcm.bin", 0xD4F8C, 3604
	.global smp_289_pcm
smp_289_pcm:
	.incbin "ww_sample_pcm.bin", 0xD5DA0, 4848
	.global smp_290_pcm
smp_290_pcm:
	.incbin "ww_sample_pcm.bin", 0xD7090, 4076
	.global smp_291_pcm
smp_291_pcm:
	.incbin "ww_sample_pcm.bin", 0xD807C, 4912
	.global smp_292_pcm
smp_292_pcm:
	.incbin "ww_sample_pcm.bin", 0xD93AC, 3140
	.global smp_293_pcm
smp_293_pcm:
	.incbin "ww_sample_pcm.bin", 0xD9FF0, 4500
	.global smp_294_pcm
smp_294_pcm:
	.incbin "ww_sample_pcm.bin", 0xDB184, 4952
	.global smp_295_pcm
smp_295_pcm:
	.incbin "ww_sample_pcm.bin", 0xDC4DC, 1816
	.global smp_296_pcm
smp_296_pcm:
	.incbin "ww_sample_pcm.bin", 0xDCBF4, 3844
	.global smp_297_pcm
smp_297_pcm:
	.incbin "ww_sample_pcm.bin", 0xDDAF8, 1624
	.global smp_298_pcm
smp_298_pcm:
	.incbin "ww_sample_pcm.bin", 0xDE150, 3412
	.global smp_299_pcm
smp_299_pcm:
	.incbin "ww_sample_pcm.bin", 0xDEEA4, 2724
	.global smp_300_pcm
smp_300_pcm:
	.incbin "ww_sample_pcm.bin", 0xDF948, 6000
	.global smp_301_pcm
smp_301_pcm:
	.incbin "ww_sample_pcm.bin", 0xE10B8, 4452
	.global smp_302_pcm
smp_302_pcm:
	.incbin "ww_sample_pcm.bin", 0xE221C, 7032
	.global smp_303_pcm
smp_303_pcm:
	.incbin "ww_sample_pcm.bin", 0xE3D94, 1744
	.global smp_304_pcm
smp_304_pcm:
	.incbin "ww_sample_pcm.bin", 0xE4464, 3832
	.global smp_305_pcm
smp_305_pcm:
	.incbin "ww_sample_pcm.bin", 0xE535C, 3336
	.global smp_306_pcm
smp_306_pcm:
	.incbin "ww_sample_pcm.bin", 0xE6064, 2068
	.global smp_307_pcm
smp_307_pcm:
	.incbin "ww_sample_pcm.bin", 0xE6878, 3548
	.global smp_308_pcm
smp_308_pcm:
	.incbin "ww_sample_pcm.bin", 0xE7654, 3388
	.global smp_309_pcm
smp_309_pcm:
	.incbin "ww_sample_pcm.bin", 0xE8390, 4000
	.global smp_310_pcm
smp_310_pcm:
	.incbin "ww_sample_pcm.bin", 0xE9330, 3680
	.global smp_311_pcm
smp_311_pcm:
	.incbin "ww_sample_pcm.bin", 0xEA190, 3240
	.global smp_312_pcm
smp_312_pcm:
	.incbin "ww_sample_pcm.bin", 0xEAE38, 3416
	.global smp_313_pcm
smp_313_pcm:
	.incbin "ww_sample_pcm.bin", 0xEBB90, 3316
	.global smp_314_pcm
smp_314_pcm:
	.incbin "ww_sample_pcm.bin", 0xEC884, 4156
	.global smp_315_pcm
smp_315_pcm:
	.incbin "ww_sample_pcm.bin", 0xED8C0, 5848
	.global smp_316_pcm
smp_316_pcm:
	.incbin "ww_sample_pcm.bin", 0xEEF98, 3008
	.global smp_317_pcm
smp_317_pcm:
	.incbin "ww_sample_pcm.bin", 0xEFB58, 2336
	.global smp_318_pcm
smp_318_pcm:
	.incbin "ww_sample_pcm.bin", 0xF0478, 4596
	.global smp_319_pcm
smp_319_pcm:
	.incbin "ww_sample_pcm.bin", 0xF166C, 2528
	.global smp_320_pcm
smp_320_pcm:
	.incbin "ww_sample_pcm.bin", 0xF204C, 4060
	.global smp_321_pcm
smp_321_pcm:
	.incbin "ww_sample_pcm.bin", 0xF3028, 2448
	.global smp_322_pcm
smp_322_pcm:
	.incbin "ww_sample_pcm.bin", 0xF39B8, 2832
	.global smp_323_pcm
smp_323_pcm:
	.incbin "ww_sample_pcm.bin", 0xF44C8, 3112
	.global smp_324_pcm
smp_324_pcm:
	.incbin "ww_sample_pcm.bin", 0xF50F0, 7688
	.global smp_325_pcm
smp_325_pcm:
	.incbin "ww_sample_pcm.bin", 0xF6EF8, 1124
	.global smp_326_pcm
smp_326_pcm:
	.incbin "ww_sample_pcm.bin", 0xF735C, 3244
	.global smp_327_pcm
smp_327_pcm:
	.incbin "ww_sample_pcm.bin", 0xF8008, 6408
	.global smp_328_pcm
smp_328_pcm:
	.incbin "ww_sample_pcm.bin", 0xF9910, 4732
	.global smp_329_pcm
smp_329_pcm:
	.incbin "ww_sample_pcm.bin", 0xFAB8C, 6716
	.global smp_330_pcm
smp_330_pcm:
	.incbin "ww_sample_pcm.bin", 0xFC5C8, 5392
	.global smp_331_pcm
smp_331_pcm:
	.incbin "ww_sample_pcm.bin", 0xFDAD8, 8148
	.global smp_332_pcm
smp_332_pcm:
	.incbin "ww_sample_pcm.bin", 0xFFAAC, 2504
	.global smp_333_pcm
smp_333_pcm:
	.incbin "ww_sample_pcm.bin", 0x100474, 3388
	.global smp_334_pcm
smp_334_pcm:
	.incbin "ww_sample_pcm.bin", 0x1011B0, 2684
	.global smp_335_pcm
smp_335_pcm:
	.incbin "ww_sample_pcm.bin", 0x101C2C, 7056
	.global smp_336_pcm
smp_336_pcm:
	.incbin "ww_sample_pcm.bin", 0x1037BC, 4108
	.global smp_337_pcm
smp_337_pcm:
	.incbin "ww_sample_pcm.bin", 0x1047C8, 3244
	.global smp_338_pcm
smp_338_pcm:
	.incbin "ww_sample_pcm.bin", 0x105474, 4040
	.global smp_339_pcm
smp_339_pcm:
	.incbin "ww_sample_pcm.bin", 0x10643C, 6108
	.global smp_340_pcm
smp_340_pcm:
	.incbin "ww_sample_pcm.bin", 0x107C18, 3212
	.global smp_341_pcm
smp_341_pcm:
	.incbin "ww_sample_pcm.bin", 0x1088A4, 1792
	.global smp_342_pcm
smp_342_pcm:
	.incbin "ww_sample_pcm.bin", 0x108FA4, 2020
	.global smp_343_pcm
smp_343_pcm:
	.incbin "ww_sample_pcm.bin", 0x109788, 2336
	.global smp_344_pcm
smp_344_pcm:
	.incbin "ww_sample_pcm.bin", 0x10A0A8, 1744
	.global smp_345_pcm
smp_345_pcm:
	.incbin "ww_sample_pcm.bin", 0x10A778, 2092
	.global smp_346_pcm
smp_346_pcm:
	.incbin "ww_sample_pcm.bin", 0x10AFA4, 8848
	.global smp_347_pcm
smp_347_pcm:
	.incbin "ww_sample_pcm.bin", 0x10D234, 2248
	.global smp_348_pcm
smp_348_pcm:
	.incbin "ww_sample_pcm.bin", 0x10DAFC, 2448
	.global smp_349_pcm
smp_349_pcm:
	.incbin "ww_sample_pcm.bin", 0x10E48C, 1788
	.global smp_350_pcm
smp_350_pcm:
	.incbin "ww_sample_pcm.bin", 0x10EB88, 3020
	.global smp_351_pcm
smp_351_pcm:
	.incbin "ww_sample_pcm.bin", 0x10F754, 3320
	.global smp_352_pcm
smp_352_pcm:
	.incbin "ww_sample_pcm.bin", 0x11044C, 3784
	.global smp_353_pcm
smp_353_pcm:
	.incbin "ww_sample_pcm.bin", 0x111314, 392
	.global smp_354_pcm
smp_354_pcm:
	.incbin "ww_sample_pcm.bin", 0x11149C, 2660
	.global smp_355_pcm
smp_355_pcm:
	.incbin "ww_sample_pcm.bin", 0x111F00, 2868
	.global smp_356_pcm
smp_356_pcm:
	.incbin "ww_sample_pcm.bin", 0x112A34, 3984
	.global smp_357_pcm
smp_357_pcm:
	.incbin "ww_sample_pcm.bin", 0x1139C4, 3428
	.global smp_358_pcm
smp_358_pcm:
	.incbin "ww_sample_pcm.bin", 0x114728, 3372
	.global smp_359_pcm
smp_359_pcm:
	.incbin "ww_sample_pcm.bin", 0x115454, 3916
	.global smp_360_pcm
smp_360_pcm:
	.incbin "ww_sample_pcm.bin", 0x1163A0, 1004
	.global smp_361_pcm
smp_361_pcm:
	.incbin "ww_sample_pcm.bin", 0x11678C, 6304
	.global smp_362_pcm
smp_362_pcm:
	.incbin "ww_sample_pcm.bin", 0x11802C, 1464
	.global smp_363_pcm
smp_363_pcm:
	.incbin "ww_sample_pcm.bin", 0x1185E4, 2076
	.global smp_364_pcm
smp_364_pcm:
	.incbin "ww_sample_pcm.bin", 0x118E00, 10980
	.global smp_365_pcm
smp_365_pcm:
	.incbin "ww_sample_pcm.bin", 0x11B8E4, 2580
	.global smp_366_pcm
smp_366_pcm:
	.incbin "ww_sample_pcm.bin", 0x11C2F8, 2872
	.global smp_367_pcm
smp_367_pcm:
	.incbin "ww_sample_pcm.bin", 0x11CE30, 5464
	.global smp_368_pcm
smp_368_pcm:
	.incbin "ww_sample_pcm.bin", 0x11E388, 3640
	.global smp_369_pcm
smp_369_pcm:
	.incbin "ww_sample_pcm.bin", 0x11F1C0, 5088
	.global smp_370_pcm
smp_370_pcm:
	.incbin "ww_sample_pcm.bin", 0x1205A0, 2840
	.global smp_371_pcm
smp_371_pcm:
	.incbin "ww_sample_pcm.bin", 0x1210B8, 1864
	.global smp_372_pcm
smp_372_pcm:
	.incbin "ww_sample_pcm.bin", 0x121800, 2744
	.global smp_373_pcm
smp_373_pcm:
	.incbin "ww_sample_pcm.bin", 0x1222B8, 2132
	.global smp_374_pcm
smp_374_pcm:
	.incbin "ww_sample_pcm.bin", 0x122B0C, 3244
	.global smp_375_pcm
smp_375_pcm:
	.incbin "ww_sample_pcm.bin", 0x1237B8, 640
	.global smp_376_pcm
smp_376_pcm:
	.incbin "ww_sample_pcm.bin", 0x123A38, 896
	.global smp_377_pcm
smp_377_pcm:
	.incbin "ww_sample_pcm.bin", 0x123DB8, 3948
	.global smp_378_pcm
smp_378_pcm:
	.incbin "ww_sample_pcm.bin", 0x124D24, 3144
	.global smp_379_pcm
smp_379_pcm:
	.incbin "ww_sample_pcm.bin", 0x12596C, 3056
	.global smp_380_pcm
smp_380_pcm:
	.incbin "ww_sample_pcm.bin", 0x12655C, 1972
	.global smp_381_pcm
smp_381_pcm:
	.incbin "ww_sample_pcm.bin", 0x126D10, 1420
	.global smp_382_pcm
smp_382_pcm:
	.incbin "ww_sample_pcm.bin", 0x12729C, 1400
	.global smp_383_pcm
smp_383_pcm:
	.incbin "ww_sample_pcm.bin", 0x127814, 1200
	.global smp_384_pcm
smp_384_pcm:
	.incbin "ww_sample_pcm.bin", 0x127CC4, 2204
	.global smp_385_pcm
smp_385_pcm:
	.incbin "ww_sample_pcm.bin", 0x128560, 1268
	.global smp_386_pcm
smp_386_pcm:
	.incbin "ww_sample_pcm.bin", 0x128A54, 1592
	.global smp_387_pcm
smp_387_pcm:
	.incbin "ww_sample_pcm.bin", 0x12908C, 4252
	.global smp_388_pcm
smp_388_pcm:
	.incbin "ww_sample_pcm.bin", 0x12A128, 492
	.global smp_389_pcm
smp_389_pcm:
	.incbin "ww_sample_pcm.bin", 0x12A314, 1616
	.global smp_390_pcm
smp_390_pcm:
	.incbin "ww_sample_pcm.bin", 0x12A964, 644
	.global smp_391_pcm
smp_391_pcm:
	.incbin "ww_sample_pcm.bin", 0x12ABE8, 1668
	.global smp_392_pcm
smp_392_pcm:
	.incbin "ww_sample_pcm.bin", 0x12B26C, 732
	.global smp_393_pcm
smp_393_pcm:
	.incbin "ww_sample_pcm.bin", 0x12B548, 1464
	.global smp_394_pcm
smp_394_pcm:
	.incbin "ww_sample_pcm.bin", 0x12BB00, 2196
	.global smp_395_pcm
smp_395_pcm:
	.incbin "ww_sample_pcm.bin", 0x12C394, 1588
	.global smp_396_pcm
smp_396_pcm:
	.incbin "ww_sample_pcm.bin", 0x12C9C8, 1928
	.global smp_397_pcm
smp_397_pcm:
	.incbin "ww_sample_pcm.bin", 0x12D150, 1776
	.global smp_398_pcm
smp_398_pcm:
	.incbin "ww_sample_pcm.bin", 0x12D840, 1272
	.global smp_399_pcm
smp_399_pcm:
	.incbin "ww_sample_pcm.bin", 0x12DD38, 784
	.global smp_400_pcm
smp_400_pcm:
	.incbin "ww_sample_pcm.bin", 0x12E048, 488
	.global smp_401_pcm
smp_401_pcm:
	.incbin "ww_sample_pcm.bin", 0x12E230, 1532
	.global smp_402_pcm
smp_402_pcm:
	.incbin "ww_sample_pcm.bin", 0x12E82C, 448
	.global smp_403_pcm
smp_403_pcm:
	.incbin "ww_sample_pcm.bin", 0x12E9EC, 1352
	.global smp_404_pcm
smp_404_pcm:
	.incbin "ww_sample_pcm.bin", 0x12EF34, 1428
	.global smp_405_pcm
smp_405_pcm:
	.incbin "ww_sample_pcm.bin", 0x12F4C8, 2680
	.global smp_406_pcm
smp_406_pcm:
	.incbin "ww_sample_pcm.bin", 0x12FF40, 2512
	.global smp_407_pcm
smp_407_pcm:
	.incbin "ww_sample_pcm.bin", 0x130910, 2072
	.global smp_408_pcm
smp_408_pcm:
	.incbin "ww_sample_pcm.bin", 0x131128, 2360
	.global smp_409_pcm
smp_409_pcm:
	.incbin "ww_sample_pcm.bin", 0x131A60, 2296
	.global smp_410_pcm
smp_410_pcm:
	.incbin "ww_sample_pcm.bin", 0x132358, 1564
	.global smp_411_pcm
smp_411_pcm:
	.incbin "ww_sample_pcm.bin", 0x132974, 1752
	.global smp_412_pcm
smp_412_pcm:
	.incbin "ww_sample_pcm.bin", 0x13304C, 1468
	.global smp_413_pcm
smp_413_pcm:
	.incbin "ww_sample_pcm.bin", 0x133608, 1200
	.global smp_414_pcm
smp_414_pcm:
	.incbin "ww_sample_pcm.bin", 0x133AB8, 1236
	.global smp_415_pcm
smp_415_pcm:
	.incbin "ww_sample_pcm.bin", 0x133F8C, 1844
	.global smp_416_pcm
smp_416_pcm:
	.incbin "ww_sample_pcm.bin", 0x1346C0, 1852
	.global smp_417_pcm
smp_417_pcm:
	.incbin "ww_sample_pcm.bin", 0x134DFC, 1656
	.global smp_418_pcm
smp_418_pcm:
	.incbin "ww_sample_pcm.bin", 0x135474, 4672
	.global smp_419_pcm
smp_419_pcm:
	.incbin "ww_sample_pcm.bin", 0x1366B4, 2280
	.global smp_420_pcm
smp_420_pcm:
	.incbin "ww_sample_pcm.bin", 0x136F9C, 1676
	.global smp_421_pcm
smp_421_pcm:
	.incbin "ww_sample_pcm.bin", 0x137628, 1852
	.global smp_422_pcm
smp_422_pcm:
	.incbin "ww_sample_pcm.bin", 0x137D64, 1756
	.global smp_423_pcm
smp_423_pcm:
	.incbin "ww_sample_pcm.bin", 0x138440, 1508
	.global smp_424_pcm
smp_424_pcm:
	.incbin "ww_sample_pcm.bin", 0x138A24, 3716
	.global smp_425_pcm
smp_425_pcm:
	.incbin "ww_sample_pcm.bin", 0x1398A8, 1708
	.global smp_426_pcm
smp_426_pcm:
	.incbin "ww_sample_pcm.bin", 0x139F54, 1728
	.global smp_427_pcm
smp_427_pcm:
	.incbin "ww_sample_pcm.bin", 0x13A614, 1128
	.global smp_428_pcm
smp_428_pcm:
	.incbin "ww_sample_pcm.bin", 0x13AA7C, 2804
	.global smp_429_pcm
smp_429_pcm:
	.incbin "ww_sample_pcm.bin", 0x13B570, 2288
	.global smp_430_pcm
smp_430_pcm:
	.incbin "ww_sample_pcm.bin", 0x13BE60, 1340
	.global smp_431_pcm
smp_431_pcm:
	.incbin "ww_sample_pcm.bin", 0x13C39C, 1828
	.global smp_432_pcm
smp_432_pcm:
	.incbin "ww_sample_pcm.bin", 0x13CAC0, 1876
	.global smp_433_pcm
smp_433_pcm:
	.incbin "ww_sample_pcm.bin", 0x13D214, 1636
	.global smp_434_pcm
smp_434_pcm:
	.incbin "ww_sample_pcm.bin", 0x13D878, 2088
	.global smp_435_pcm
smp_435_pcm:
	.incbin "ww_sample_pcm.bin", 0x13E0A0, 1728
	.global smp_436_pcm
smp_436_pcm:
	.incbin "ww_sample_pcm.bin", 0x13E760, 1456
	.global smp_437_pcm
smp_437_pcm:
	.incbin "ww_sample_pcm.bin", 0x13ED10, 1640
	.global smp_438_pcm
smp_438_pcm:
	.incbin "ww_sample_pcm.bin", 0x13F378, 2324
	.global smp_439_pcm
smp_439_pcm:
	.incbin "ww_sample_pcm.bin", 0x13FC8C, 2920
	.global smp_440_pcm
smp_440_pcm:
	.incbin "ww_sample_pcm.bin", 0x1407F4, 3708
	.global smp_441_pcm
smp_441_pcm:
	.incbin "ww_sample_pcm.bin", 0x141670, 5116
	.global smp_442_pcm
smp_442_pcm:
	.incbin "ww_sample_pcm.bin", 0x142A6C, 2636
	.global smp_443_pcm
smp_443_pcm:
	.incbin "ww_sample_pcm.bin", 0x1434B8, 2332
	.global smp_444_pcm
smp_444_pcm:
	.incbin "ww_sample_pcm.bin", 0x143DD4, 3908
	.global smp_445_pcm
smp_445_pcm:
	.incbin "ww_sample_pcm.bin", 0x144D18, 3948
	.global smp_446_pcm
smp_446_pcm:
	.incbin "ww_sample_pcm.bin", 0x145C84, 10172
	.global smp_447_pcm
smp_447_pcm:
	.incbin "ww_sample_pcm.bin", 0x148440, 2348
	.global smp_448_pcm
smp_448_pcm:
	.incbin "ww_sample_pcm.bin", 0x148D6C, 3952
	.global smp_449_pcm
smp_449_pcm:
	.incbin "ww_sample_pcm.bin", 0x149CDC, 2328
	.global smp_450_pcm
smp_450_pcm:
	.incbin "ww_sample_pcm.bin", 0x14A5F4, 1944
	.global smp_451_pcm
smp_451_pcm:
	.incbin "ww_sample_pcm.bin", 0x14AD8C, 3388
	.global smp_452_pcm
smp_452_pcm:
	.incbin "ww_sample_pcm.bin", 0x14BAC8, 3508
	.global smp_453_pcm
smp_453_pcm:
	.incbin "ww_sample_pcm.bin", 0x14C87C, 876
	.global smp_454_pcm
smp_454_pcm:
	.incbin "ww_sample_pcm.bin", 0x14CBE8, 3384
	.global smp_455_pcm
smp_455_pcm:
	.incbin "ww_sample_pcm.bin", 0x14D920, 3004
	.global smp_456_pcm
smp_456_pcm:
	.incbin "ww_sample_pcm.bin", 0x14E4DC, 2612
	.global smp_457_pcm
smp_457_pcm:
	.incbin "ww_sample_pcm.bin", 0x14EF10, 2040
	.global smp_458_pcm
smp_458_pcm:
	.incbin "ww_sample_pcm.bin", 0x14F708, 2516
	.global smp_459_pcm
smp_459_pcm:
	.incbin "ww_sample_pcm.bin", 0x1500DC, 2684
	.global smp_460_pcm
smp_460_pcm:
	.incbin "ww_sample_pcm.bin", 0x150B58, 2708
	.global smp_461_pcm
smp_461_pcm:
	.incbin "ww_sample_pcm.bin", 0x1515EC, 4384
	.global smp_462_pcm
smp_462_pcm:
	.incbin "ww_sample_pcm.bin", 0x15270C, 3116
	.global smp_463_pcm
smp_463_pcm:
	.incbin "ww_sample_pcm.bin", 0x153338, 1996
	.global smp_464_pcm
smp_464_pcm:
	.incbin "ww_sample_pcm.bin", 0x153B04, 2080
	.global smp_465_pcm
smp_465_pcm:
	.incbin "ww_sample_pcm.bin", 0x154324, 1716
	.global smp_466_pcm
smp_466_pcm:
	.incbin "ww_sample_pcm.bin", 0x1549D8, 1884
	.global smp_467_pcm
smp_467_pcm:
	.incbin "ww_sample_pcm.bin", 0x155134, 1840
	.global smp_468_pcm
smp_468_pcm:
	.incbin "ww_sample_pcm.bin", 0x155864, 3636
	.global smp_469_pcm
smp_469_pcm:
	.incbin "ww_sample_pcm.bin", 0x156698, 1860
	.global smp_470_pcm
smp_470_pcm:
	.incbin "ww_sample_pcm.bin", 0x156DDC, 2036
	.global smp_471_pcm
smp_471_pcm:
	.incbin "ww_sample_pcm.bin", 0x1575D0, 1596
	.global smp_472_pcm
smp_472_pcm:
	.incbin "ww_sample_pcm.bin", 0x157C0C, 1860
	.global smp_473_pcm
smp_473_pcm:
	.incbin "ww_sample_pcm.bin", 0x158350, 2136
	.global smp_474_pcm
smp_474_pcm:
	.incbin "ww_sample_pcm.bin", 0x158BA8, 1292
	.global smp_475_pcm
smp_475_pcm:
	.incbin "ww_sample_pcm.bin", 0x1590B4, 3192
	.global smp_476_pcm
smp_476_pcm:
	.incbin "ww_sample_pcm.bin", 0x159D2C, 1760
	.global smp_477_pcm
smp_477_pcm:
	.incbin "ww_sample_pcm.bin", 0x15A40C, 2528
	.global smp_478_pcm
smp_478_pcm:
	.incbin "ww_sample_pcm.bin", 0x15ADEC, 1520
	.global smp_479_pcm
smp_479_pcm:
	.incbin "ww_sample_pcm.bin", 0x15B3DC, 1544
	.global smp_480_pcm
smp_480_pcm:
	.incbin "ww_sample_pcm.bin", 0x15B9E4, 1412
	.global smp_481_pcm
smp_481_pcm:
	.incbin "ww_sample_pcm.bin", 0x15BF68, 1476
	.global smp_482_pcm
smp_482_pcm:
	.incbin "ww_sample_pcm.bin", 0x15C52C, 1336
	.global smp_483_pcm
smp_483_pcm:
	.incbin "ww_sample_pcm.bin", 0x15CA64, 1328
	.global smp_484_pcm
smp_484_pcm:
	.incbin "ww_sample_pcm.bin", 0x15CF94, 1992
	.global smp_485_pcm
smp_485_pcm:
	.incbin "ww_sample_pcm.bin", 0x15D75C, 2012
	.global smp_486_pcm
smp_486_pcm:
	.incbin "ww_sample_pcm.bin", 0x15DF38, 360
	.global smp_487_pcm
smp_487_pcm:
	.incbin "ww_sample_pcm.bin", 0x15E0A0, 2732
	.global smp_488_pcm
smp_488_pcm:
	.incbin "ww_sample_pcm.bin", 0x15EB4C, 1692
	.global smp_489_pcm
smp_489_pcm:
	.incbin "ww_sample_pcm.bin", 0x15F1E8, 2596
	.global smp_490_pcm
smp_490_pcm:
	.incbin "ww_sample_pcm.bin", 0x15FC0C, 1008
	.global smp_491_pcm
smp_491_pcm:
	.incbin "ww_sample_pcm.bin", 0x15FFFC, 1616
	.global smp_492_pcm
smp_492_pcm:
	.incbin "ww_sample_pcm.bin", 0x16064C, 1896
	.global smp_493_pcm
smp_493_pcm:
	.incbin "ww_sample_pcm.bin", 0x160DB4, 2000
	.global smp_494_pcm
smp_494_pcm:
	.incbin "ww_sample_pcm.bin", 0x161584, 4116
	.global smp_495_pcm
smp_495_pcm:
	.incbin "ww_sample_pcm.bin", 0x162598, 3988
	.global smp_496_pcm
smp_496_pcm:
	.incbin "ww_sample_pcm.bin", 0x16352C, 1716
	.global smp_497_pcm
smp_497_pcm:
	.incbin "ww_sample_pcm.bin", 0x163BE0, 1324
	.global smp_498_pcm
smp_498_pcm:
	.incbin "ww_sample_pcm.bin", 0x16410C, 1124
	.global smp_499_pcm
smp_499_pcm:
	.incbin "ww_sample_pcm.bin", 0x164570, 1940
	.global smp_500_pcm
smp_500_pcm:
	.incbin "ww_sample_pcm.bin", 0x164D04, 3520
	.global smp_501_pcm
smp_501_pcm:
	.incbin "ww_sample_pcm.bin", 0x165AC4, 3624
	.global smp_502_pcm
smp_502_pcm:
	.incbin "ww_sample_pcm.bin", 0x1668EC, 3316
	.global smp_503_pcm
smp_503_pcm:
	.incbin "ww_sample_pcm.bin", 0x1675E0, 3876
	.global smp_504_pcm
smp_504_pcm:
	.incbin "ww_sample_pcm.bin", 0x168504, 1164
	.global smp_505_pcm
smp_505_pcm:
	.incbin "ww_sample_pcm.bin", 0x168990, 2704
	.global smp_506_pcm
smp_506_pcm:
	.incbin "ww_sample_pcm.bin", 0x169420, 1244
	.global smp_507_pcm
smp_507_pcm:
	.incbin "ww_sample_pcm.bin", 0x1698FC, 2932
	.global smp_508_pcm
smp_508_pcm:
	.incbin "ww_sample_pcm.bin", 0x16A470, 1792
	.global smp_509_pcm
smp_509_pcm:
	.incbin "ww_sample_pcm.bin", 0x16AB70, 1116
	.global smp_510_pcm
smp_510_pcm:
	.incbin "ww_sample_pcm.bin", 0x16AFCC, 2064
	.global smp_511_pcm
smp_511_pcm:
	.incbin "ww_sample_pcm.bin", 0x16B7DC, 14724
	.global smp_512_pcm
smp_512_pcm:
	.incbin "ww_sample_pcm.bin", 0x16F160, 2692
	.global smp_513_pcm
smp_513_pcm:
	.incbin "ww_sample_pcm.bin", 0x16FBE4, 1928
	.global smp_514_pcm
smp_514_pcm:
	.incbin "ww_sample_pcm.bin", 0x17036C, 1300
	.global smp_515_pcm
smp_515_pcm:
	.incbin "ww_sample_pcm.bin", 0x170880, 1532
	.global smp_516_pcm
smp_516_pcm:
	.incbin "ww_sample_pcm.bin", 0x170E7C, 1568
	.global smp_517_pcm
smp_517_pcm:
	.incbin "ww_sample_pcm.bin", 0x17149C, 2888
	.global smp_518_pcm
smp_518_pcm:
	.incbin "ww_sample_pcm.bin", 0x171FE4, 3964
	.global smp_519_pcm
smp_519_pcm:
	.incbin "ww_sample_pcm.bin", 0x172F60, 2688
	.global smp_520_pcm
smp_520_pcm:
	.incbin "ww_sample_pcm.bin", 0x1739E0, 2388
	.global smp_521_pcm
smp_521_pcm:
	.incbin "ww_sample_pcm.bin", 0x174334, 2372
	.global smp_522_pcm
smp_522_pcm:
	.incbin "ww_sample_pcm.bin", 0x174C78, 2084
	.global smp_523_pcm
smp_523_pcm:
	.incbin "ww_sample_pcm.bin", 0x17549C, 3300
	.global smp_524_pcm
smp_524_pcm:
	.incbin "ww_sample_pcm.bin", 0x176180, 2504
	.global smp_525_pcm
smp_525_pcm:
	.incbin "ww_sample_pcm.bin", 0x176B48, 1556
	.global smp_526_pcm
smp_526_pcm:
	.incbin "ww_sample_pcm.bin", 0x17715C, 1920
	.global smp_527_pcm
smp_527_pcm:
	.incbin "ww_sample_pcm.bin", 0x1778DC, 2060
	.global smp_528_pcm
smp_528_pcm:
	.incbin "ww_sample_pcm.bin", 0x1780E8, 3640
	.global smp_529_pcm
smp_529_pcm:
	.incbin "ww_sample_pcm.bin", 0x178F20, 2104
	.global smp_530_pcm
smp_530_pcm:
	.incbin "ww_sample_pcm.bin", 0x179758, 1836
	.global smp_531_pcm
smp_531_pcm:
	.incbin "ww_sample_pcm.bin", 0x179E84, 2352
	.global smp_532_pcm
smp_532_pcm:
	.incbin "ww_sample_pcm.bin", 0x17A7B4, 1548
	.global smp_533_pcm
smp_533_pcm:
	.incbin "ww_sample_pcm.bin", 0x17ADC0, 1800
	.global smp_534_pcm
smp_534_pcm:
	.incbin "ww_sample_pcm.bin", 0x17B4C8, 1980
	.global smp_535_pcm
smp_535_pcm:
	.incbin "ww_sample_pcm.bin", 0x17BC84, 4036
	.global smp_536_pcm
smp_536_pcm:
	.incbin "ww_sample_pcm.bin", 0x17CC48, 2392
	.global smp_537_pcm
smp_537_pcm:
	.incbin "ww_sample_pcm.bin", 0x17D5A0, 1892
	.global smp_538_pcm
smp_538_pcm:
	.incbin "ww_sample_pcm.bin", 0x17DD04, 2312
	.global smp_539_pcm
smp_539_pcm:
	.incbin "ww_sample_pcm.bin", 0x17E60C, 2532
	.global smp_540_pcm
smp_540_pcm:
	.incbin "ww_sample_pcm.bin", 0x17EFF0, 4224
	.global smp_541_pcm
smp_541_pcm:
	.incbin "ww_sample_pcm.bin", 0x180070, 2140
	.global smp_542_pcm
smp_542_pcm:
	.incbin "ww_sample_pcm.bin", 0x1808CC, 2016
	.global smp_543_pcm
smp_543_pcm:
	.incbin "ww_sample_pcm.bin", 0x1810AC, 1876
	.global smp_544_pcm
smp_544_pcm:
	.incbin "ww_sample_pcm.bin", 0x181800, 1908
	.global smp_545_pcm
smp_545_pcm:
	.incbin "ww_sample_pcm.bin", 0x181F74, 3240
	.global smp_546_pcm
smp_546_pcm:
	.incbin "ww_sample_pcm.bin", 0x182C1C, 2448
	.global smp_547_pcm
smp_547_pcm:
	.incbin "ww_sample_pcm.bin", 0x1835AC, 2508
	.global smp_548_pcm
smp_548_pcm:
	.incbin "ww_sample_pcm.bin", 0x183F78, 2824
	.global smp_549_pcm
smp_549_pcm:
	.incbin "ww_sample_pcm.bin", 0x184A80, 2456
	.global smp_550_pcm
smp_550_pcm:
	.incbin "ww_sample_pcm.bin", 0x185418, 3296
	.global smp_551_pcm
smp_551_pcm:
	.incbin "ww_sample_pcm.bin", 0x1860F8, 4184
	.global smp_552_pcm
smp_552_pcm:
	.incbin "ww_sample_pcm.bin", 0x187150, 2980
	.global smp_553_pcm
smp_553_pcm:
	.incbin "ww_sample_pcm.bin", 0x187CF4, 2100
	.global smp_554_pcm
smp_554_pcm:
	.incbin "ww_sample_pcm.bin", 0x188528, 2392
	.global smp_555_pcm
smp_555_pcm:
	.incbin "ww_sample_pcm.bin", 0x188E80, 2272
	.global smp_556_pcm
smp_556_pcm:
	.incbin "ww_sample_pcm.bin", 0x189760, 1552
	.global smp_557_pcm
smp_557_pcm:
	.incbin "ww_sample_pcm.bin", 0x189D70, 1476
	.global smp_558_pcm
smp_558_pcm:
	.incbin "ww_sample_pcm.bin", 0x18A334, 1640
	.global smp_559_pcm
smp_559_pcm:
	.incbin "ww_sample_pcm.bin", 0x18A99C, 2712
	.global smp_560_pcm
smp_560_pcm:
	.incbin "ww_sample_pcm.bin", 0x18B434, 2004
	.global smp_561_pcm
smp_561_pcm:
	.incbin "ww_sample_pcm.bin", 0x18BC08, 1928
	.global smp_562_pcm
smp_562_pcm:
	.incbin "ww_sample_pcm.bin", 0x18C390, 3000
	.global smp_563_pcm
smp_563_pcm:
	.incbin "ww_sample_pcm.bin", 0x18CF48, 5024
	.global smp_564_pcm
smp_564_pcm:
	.incbin "ww_sample_pcm.bin", 0x18E2E8, 2308
	.global smp_565_pcm
smp_565_pcm:
	.incbin "ww_sample_pcm.bin", 0x18EBEC, 3072
	.global smp_566_pcm
smp_566_pcm:
	.incbin "ww_sample_pcm.bin", 0x18F7EC, 3896
	.global smp_567_pcm
smp_567_pcm:
	.incbin "ww_sample_pcm.bin", 0x190724, 6244
	.global smp_568_pcm
smp_568_pcm:
	.incbin "ww_sample_pcm.bin", 0x191F88, 3788
	.global smp_569_pcm
smp_569_pcm:
	.incbin "ww_sample_pcm.bin", 0x192E54, 4296
	.global smp_570_pcm
smp_570_pcm:
	.incbin "ww_sample_pcm.bin", 0x193F1C, 3744
	.global smp_571_pcm
smp_571_pcm:
	.incbin "ww_sample_pcm.bin", 0x194DBC, 3864
	.global smp_572_pcm
smp_572_pcm:
	.incbin "ww_sample_pcm.bin", 0x195CD4, 3852
	.global smp_573_pcm
smp_573_pcm:
	.incbin "ww_sample_pcm.bin", 0x196BE0, 3052
	.global smp_574_pcm
smp_574_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977CC, 4
	.global smp_575_pcm
smp_575_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977D0, 4
	.global smp_576_pcm
smp_576_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977D4, 4
	.global smp_577_pcm
smp_577_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977D8, 4
	.global smp_578_pcm
smp_578_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977DC, 4
	.global smp_579_pcm
smp_579_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977E0, 4
	.global smp_580_pcm
smp_580_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977E4, 4
	.global smp_581_pcm
smp_581_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977E8, 4
	.global smp_582_pcm
smp_582_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977EC, 4
	.global smp_583_pcm
smp_583_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977F0, 4
	.global smp_584_pcm
smp_584_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977F4, 4
	.global smp_585_pcm
smp_585_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977F8, 4
	.global smp_586_pcm
smp_586_pcm:
	.incbin "ww_sample_pcm.bin", 0x1977FC, 4
	.global smp_587_pcm
smp_587_pcm:
	.incbin "ww_sample_pcm.bin", 0x197800, 4
	.global smp_588_pcm
smp_588_pcm:
	.incbin "ww_sample_pcm.bin", 0x197804, 4
	.global smp_589_pcm
smp_589_pcm:
	.incbin "ww_sample_pcm.bin", 0x197808, 4
	.global smp_590_pcm
smp_590_pcm:
	.incbin "ww_sample_pcm.bin", 0x19780C, 4
	.global smp_591_pcm
smp_591_pcm:
	.incbin "ww_sample_pcm.bin", 0x197810, 4
	.global smp_592_pcm
smp_592_pcm:
	.incbin "ww_sample_pcm.bin", 0x197814, 4
	.global smp_593_pcm
smp_593_pcm:
	.incbin "ww_sample_pcm.bin", 0x197818, 4
	.global smp_594_pcm
smp_594_pcm:
	.incbin "ww_sample_pcm.bin", 0x19781C, 4
	.global smp_595_pcm
smp_595_pcm:
	.incbin "ww_sample_pcm.bin", 0x197820, 4
	.global smp_596_pcm
smp_596_pcm:
	.incbin "ww_sample_pcm.bin", 0x197824, 4
	.global smp_597_pcm
smp_597_pcm:
	.incbin "ww_sample_pcm.bin", 0x197828, 4
	.global smp_598_pcm
smp_598_pcm:
	.incbin "ww_sample_pcm.bin", 0x19782C, 2328
	.global smp_599_pcm
smp_599_pcm:
	.incbin "ww_sample_pcm.bin", 0x198144, 4
	.global smp_600_pcm
smp_600_pcm:
	.incbin "ww_sample_pcm.bin", 0x198148, 4
	.global smp_601_pcm
smp_601_pcm:
	.incbin "ww_sample_pcm.bin", 0x19814C, 4
	.global smp_602_pcm
smp_602_pcm:
	.incbin "ww_sample_pcm.bin", 0x198150, 4
	.global smp_603_pcm
smp_603_pcm:
	.incbin "ww_sample_pcm.bin", 0x198154, 4
	.global smp_604_pcm
smp_604_pcm:
	.incbin "ww_sample_pcm.bin", 0x198158, 4
	.global smp_605_pcm
smp_605_pcm:
	.incbin "ww_sample_pcm.bin", 0x19815C, 4
	.global smp_606_pcm
smp_606_pcm:
	.incbin "ww_sample_pcm.bin", 0x198160, 4
	.global smp_607_pcm
smp_607_pcm:
	.incbin "ww_sample_pcm.bin", 0x198164, 4
	.global smp_608_pcm
smp_608_pcm:
	.incbin "ww_sample_pcm.bin", 0x198168, 4
	.global smp_609_pcm
smp_609_pcm:
	.incbin "ww_sample_pcm.bin", 0x19816C, 4
	.global smp_610_pcm
smp_610_pcm:
	.incbin "ww_sample_pcm.bin", 0x198170, 4
	.global smp_611_pcm
smp_611_pcm:
	.incbin "ww_sample_pcm.bin", 0x198174, 4
	.global smp_612_pcm
smp_612_pcm:
	.incbin "ww_sample_pcm.bin", 0x198178, 4
	.global smp_613_pcm
smp_613_pcm:
	.incbin "ww_sample_pcm.bin", 0x19817C, 4
	.global smp_614_pcm
smp_614_pcm:
	.incbin "ww_sample_pcm.bin", 0x198180, 4
	.global smp_615_pcm
smp_615_pcm:
	.incbin "ww_sample_pcm.bin", 0x198184, 4
	.global smp_616_pcm
smp_616_pcm:
	.incbin "ww_sample_pcm.bin", 0x198188, 4
	.global smp_617_pcm
smp_617_pcm:
	.incbin "ww_sample_pcm.bin", 0x19818C, 4
	.global smp_618_pcm
smp_618_pcm:
	.incbin "ww_sample_pcm.bin", 0x198190, 4
	.global smp_619_pcm
smp_619_pcm:
	.incbin "ww_sample_pcm.bin", 0x198194, 4
	.global smp_620_pcm
smp_620_pcm:
	.incbin "ww_sample_pcm.bin", 0x198198, 4
	.global smp_621_pcm
smp_621_pcm:
	.incbin "ww_sample_pcm.bin", 0x19819C, 4
	.global smp_622_pcm
smp_622_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981A0, 4
	.global smp_623_pcm
smp_623_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981A4, 4
	.global smp_624_pcm
smp_624_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981A8, 4
	.global smp_625_pcm
smp_625_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981AC, 4
	.global smp_626_pcm
smp_626_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981B0, 4
	.global smp_627_pcm
smp_627_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981B4, 4
	.global smp_628_pcm
smp_628_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981B8, 4
	.global smp_629_pcm
smp_629_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981BC, 4
	.global smp_630_pcm
smp_630_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981C0, 4
	.global smp_631_pcm
smp_631_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981C4, 4
	.global smp_632_pcm
smp_632_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981C8, 4
	.global smp_633_pcm
smp_633_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981CC, 4
	.global smp_634_pcm
smp_634_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981D0, 4
	.global smp_635_pcm
smp_635_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981D4, 4
	.global smp_636_pcm
smp_636_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981D8, 4
	.global smp_637_pcm
smp_637_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981DC, 4
	.global smp_638_pcm
smp_638_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981E0, 4
	.global smp_639_pcm
smp_639_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981E4, 4
	.global smp_640_pcm
smp_640_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981E8, 4
	.global smp_641_pcm
smp_641_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981EC, 4
	.global smp_642_pcm
smp_642_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981F0, 4
	.global smp_643_pcm
smp_643_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981F4, 4
	.global smp_644_pcm
smp_644_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981F8, 4
	.global smp_645_pcm
smp_645_pcm:
	.incbin "ww_sample_pcm.bin", 0x1981FC, 4
	.global smp_646_pcm
smp_646_pcm:
	.incbin "ww_sample_pcm.bin", 0x198200, 4
	.global smp_647_pcm
smp_647_pcm:
	.incbin "ww_sample_pcm.bin", 0x198204, 4
	.global smp_648_pcm
smp_648_pcm:
	.incbin "ww_sample_pcm.bin", 0x198208, 4
	.global smp_649_pcm
smp_649_pcm:
	.incbin "ww_sample_pcm.bin", 0x19820C, 2268
	.global smp_650_pcm
smp_650_pcm:
	.incbin "ww_sample_pcm.bin", 0x198AE8, 1816
	.global smp_651_pcm
smp_651_pcm:
	.incbin "ww_sample_pcm.bin", 0x199200, 1432
	.global smp_652_pcm
smp_652_pcm:
	.incbin "ww_sample_pcm.bin", 0x199798, 2992
	.global smp_653_pcm
smp_653_pcm:
	.incbin "ww_sample_pcm.bin", 0x19A348, 2076
	.global smp_654_pcm
smp_654_pcm:
	.incbin "ww_sample_pcm.bin", 0x19AB64, 2676
	.global smp_655_pcm
smp_655_pcm:
	.incbin "ww_sample_pcm.bin", 0x19B5D8, 3360
	.global smp_656_pcm
smp_656_pcm:
	.incbin "ww_sample_pcm.bin", 0x19C2F8, 2920
	.global smp_657_pcm
smp_657_pcm:
	.incbin "ww_sample_pcm.bin", 0x19CE60, 6492
	.global smp_658_pcm
smp_658_pcm:
	.incbin "ww_sample_pcm.bin", 0x19E7BC, 3384
	.global smp_659_pcm
smp_659_pcm:
	.incbin "ww_sample_pcm.bin", 0x19F4F4, 3060
	.global smp_660_pcm
smp_660_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A00E8, 2936
	.global smp_661_pcm
smp_661_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A0C60, 1520
	.global smp_662_pcm
smp_662_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A1250, 2960
	.global smp_663_pcm
smp_663_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A1DE0, 1948
	.global smp_664_pcm
smp_664_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A257C, 1224
	.global smp_665_pcm
smp_665_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A2A44, 3668
	.global smp_666_pcm
smp_666_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A3898, 2588
	.global smp_667_pcm
smp_667_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A42B4, 1772
	.global smp_668_pcm
smp_668_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A49A0, 2536
	.global smp_669_pcm
smp_669_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A5388, 628
	.global smp_670_pcm
smp_670_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A55FC, 2440
	.global smp_671_pcm
smp_671_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A5F84, 4608
	.global smp_672_pcm
smp_672_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A7184, 1252
	.global smp_673_pcm
smp_673_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A7668, 980
	.global smp_674_pcm
smp_674_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A7A3C, 1304
	.global smp_675_pcm
smp_675_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A7F54, 3756
	.global smp_676_pcm
smp_676_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A8E00, 3468
	.global smp_677_pcm
smp_677_pcm:
	.incbin "ww_sample_pcm.bin", 0x1A9B8C, 4172
	.global smp_678_pcm
smp_678_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AABD8, 2012
	.global smp_679_pcm
smp_679_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AB3B4, 3280
	.global smp_680_pcm
smp_680_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AC084, 3340
	.global smp_681_pcm
smp_681_pcm:
	.incbin "ww_sample_pcm.bin", 0x1ACD90, 2704
	.global smp_682_pcm
smp_682_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AD820, 2320
	.global smp_683_pcm
smp_683_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AE130, 960
	.global smp_684_pcm
smp_684_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AE4F0, 2444
	.global smp_685_pcm
smp_685_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AEE7C, 3800
	.global smp_686_pcm
smp_686_pcm:
	.incbin "ww_sample_pcm.bin", 0x1AFD54, 2096
	.global smp_687_pcm
smp_687_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B0584, 1816
	.global smp_688_pcm
smp_688_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B0C9C, 2560
	.global smp_689_pcm
smp_689_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B169C, 1360
	.global smp_690_pcm
smp_690_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B1BEC, 3496
	.global smp_691_pcm
smp_691_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B2994, 3176
	.global smp_692_pcm
smp_692_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B35FC, 3720
	.global smp_693_pcm
smp_693_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B4484, 1084
	.global smp_694_pcm
smp_694_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B48C0, 1076
	.global smp_695_pcm
smp_695_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B4CF4, 3352
	.global smp_696_pcm
smp_696_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B5A0C, 2320
	.global smp_697_pcm
smp_697_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B631C, 2628
	.global smp_698_pcm
smp_698_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B6D60, 1628
	.global smp_699_pcm
smp_699_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B73BC, 1956
	.global smp_700_pcm
smp_700_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B7B60, 3980
	.global smp_701_pcm
smp_701_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B8AEC, 1724
	.global smp_702_pcm
smp_702_pcm:
	.incbin "ww_sample_pcm.bin", 0x1B91A8, 4008
	.global smp_703_pcm
smp_703_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BA150, 1768
	.global smp_704_pcm
smp_704_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BA838, 3852
	.global smp_705_pcm
smp_705_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BB744, 1600
	.global smp_706_pcm
smp_706_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BBD84, 2388
	.global smp_707_pcm
smp_707_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BC6D8, 1812
	.global smp_708_pcm
smp_708_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BCDEC, 5144
	.global smp_709_pcm
smp_709_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BE204, 3688
	.global smp_710_pcm
smp_710_pcm:
	.incbin "ww_sample_pcm.bin", 0x1BF06C, 5464
