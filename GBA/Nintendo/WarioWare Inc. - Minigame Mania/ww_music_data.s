@ Generated from the ROM by gen_data.py; names are assigned (the ROM has no symbols apart from the
@ song name strings, which are real ROM data).
	.syntax unified

	.set WW_DATA_FILE, 1
	.include "ww_sound.inc"
	.include "ww_macros.inc"
	.section .snd_data, "a", %progbits

@ ---- key maps of the "S" (key split) instruments: u8[72] for keys 36..107 -> index into bank_00 ----
keymap_0:
	.byte  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   @ keys 36-47
	.byte  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0,  0   @ keys 48-59
	.byte  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   @ keys 60-71
	.byte  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   @ keys 72-83
	.byte  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   @ keys 84-95
	.byte  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1,  1   @ keys 96-107
keymap_1:
	.byte 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16   @ keys 36-47
	.byte 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16   @ keys 48-59
	.byte 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17, 17   @ keys 60-71
	.byte 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16   @ keys 72-83
	.byte 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16   @ keys 84-95
	.byte 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16, 16   @ keys 96-107
keymap_2:
	.byte  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2,  2   @ keys 36-47
	.byte  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3,  3   @ keys 48-59
	.byte  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4   @ keys 60-71
	.byte  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4,  4   @ keys 72-83
	.byte  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5,  5   @ keys 84-95
	.byte  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6,  6   @ keys 96-107
keymap_3:
	.byte 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10, 10   @ keys 36-47
	.byte 11, 11, 11, 11, 12, 12, 12, 12, 13, 13, 13, 13   @ keys 48-59
	.byte 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14   @ keys 60-71
	.byte 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14, 14   @ keys 72-83
	.byte 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15, 15   @ keys 84-95
	.byte 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11, 11   @ keys 96-107

@ ---- PSG wave-channel waveforms (16 bytes = 32 4-bit samples) ----
psgwave_0:                             @ not referenced
	.byte 0x00, 0x11, 0x23, 0x56, 0x89, 0xAC, 0xDE, 0xEF, 0xFF, 0xEE, 0xDC, 0xA9, 0x86, 0x53, 0x21, 0x10
psgwave_1:                             @ not referenced
	.byte 0x01, 0x23, 0x45, 0x67, 0x89, 0xAB, 0xCD, 0xEF, 0xFE, 0xDC, 0xBA, 0x98, 0x76, 0x54, 0x32, 0x10
psgwave_2:                             @ not referenced
	.byte 0xFF, 0xEE, 0xDD, 0xCC, 0xBB, 0xAA, 0x99, 0x88, 0x77, 0x66, 0x55, 0x44, 0x33, 0x22, 0x11, 0x00
psgwave_3:
	.byte 0xFE, 0xDC, 0xBA, 0x99, 0x88, 0x88, 0x88, 0x88, 0x77, 0x77, 0x77, 0x77, 0x66, 0x54, 0x32, 0x10
psgwave_4:                             @ not referenced
	.byte 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
psgwave_5:                             @ not referenced
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
psgwave_6:
	.byte 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00

@ ---- instruments (type byte first: A = sampled, P = PSG, R = drum map, S = key split) ----
ins_b00_000:   @ bank 0 entry 0; start 0, attack 2 fr, decay to 38.5 in 14 fr, sustain rate 0, release 3 fr; sample rate 10512 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_000, env_start=0x0, sustain=0x267C1F, attack=0x5E0F83, decay=0x690CE, sustain_rate=0x0, release=0xF6A90
ins_b00_001:   @ bank 0 entry 1; start 0, attack 2 fr, decay to 38.5 in 14 fr, sustain rate 0, release 3 fr; sample rate 10512 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_001, env_start=0x0, sustain=0x267C1F, attack=0x5E0F83, decay=0x690CE, sustain_rate=0x0, release=0xF6A90
ins_b00_002:   @ bank 0 entry 2; start 127, attack 0 fr, decay to 25.7 in 16 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_002, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x55552
ins_b00_003:   @ bank 0 entry 3; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_003, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b00_004:   @ bank 0 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 83
	ins_sample key=60, nointerp=0, pan=127, sample=smp_004, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b00_005:   @ bank 0 entry 5; start 127, attack 0 fr, decay to 64.1 in 4 fr, sustain rate 0, release 6 fr; sample rate 13379 root 91
	ins_sample key=60, nointerp=0, pan=127, sample=smp_005, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xB8000
ins_b00_006:   @ bank 0 entry 6; start 127, attack 0 fr, decay to 64.1 in 4 fr, sustain rate 0, release 6 fr; sample rate 13379 root 115
	ins_sample key=60, nointerp=0, pan=127, sample=smp_006, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xB8000
ins_b00_010:   @ bank 0 entry 10; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 170 fr; sample rate 13379 root 70
	ins_sample key=60, nointerp=0, pan=127, sample=smp_007, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xC000
ins_b00_011:   @ bank 0 entry 11; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 52
	ins_sample key=60, nointerp=0, pan=127, sample=smp_008, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b00_012:   @ bank 0 entry 12; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 70
	ins_sample key=60, nointerp=0, pan=127, sample=smp_009, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b00_013:   @ bank 0 entry 13; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 80
	ins_sample key=60, nointerp=0, pan=127, sample=smp_010, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b00_014:   @ bank 0 entry 14; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_011, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b00_015:   @ bank 0 entry 15; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_012, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b00_016:   @ bank 0 entry 16; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 52
	ins_sample key=60, nointerp=0, pan=127, sample=smp_013, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b00_017:   @ bank 0 entry 17; start 0, attack 3 fr, decay to 127.0 in 0 fr, sustain rate 0, release 375 fr; sample rate 10512 root 84
	ins_sample key=60, nointerp=0, pan=127, sample=smp_014, env_start=0x0, sustain=0x7F0000, attack=0x307C1F, decay=0x208000, sustain_rate=0x0, release=0x56C1
ins_b00_020:   @ bank 0 entry 20; start 0, attack 2 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 10512 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_000, env_start=0x0, sustain=0x7F0000, attack=0x43E0F8, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b00_021:   @ bank 0 entry 21; start 0, attack 2 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 10512 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_001, env_start=0x0, sustain=0x7F0000, attack=0x43E0F8, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b01_000:   @ bank 1 entry 0; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00047000
ins_b01_001:   @ bank 1 entry 1; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000003
ins_b01_002:   @ bank 1 entry 2; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 11 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0xB8BA2, psg=0x00045800
ins_b01_003:   @ bank 1 entry 3; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 27 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x4B425, psg=0x00000003
ins_b01_004:   @ bank 1 entry 4; PSG noise; start 127, attack 0 fr, decay to 51.0 in 5 fr, sustain rate 0, release 3 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x330000, attack=0x7F0000, decay=0x122492, sustain_rate=0x0, release=0x122492, psg=0x00080003
ins_b01_005:   @ bank 1 entry 5; PSG square 2; start 127, attack 0 fr, decay to 51.0 in 5 fr, sustain rate 0, release 3 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x330000, attack=0x7F0000, decay=0x122492, sustain_rate=0x0, release=0x122492, psg=0x00040001
ins_b01_006:   @ bank 1 entry 6; PSG noise; start 127, attack 0 fr, decay to 89.0 in 6 fr, sustain rate 0, release 17 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x590000, attack=0x7F0000, decay=0x77878, sustain_rate=0x0, release=0x54AAA, psg=0x00000003
ins_b01_007:   @ bank 1 entry 7; PSG noise; start 127, attack 0 fr, decay to 89.0 in 6 fr, sustain rate 0, release 17 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x590000, attack=0x7F0000, decay=0x77878, sustain_rate=0x0, release=0x54AAA, psg=0x00080003
ins_b01_008:   @ bank 1 entry 8; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00020000
ins_b01_009:   @ bank 1 entry 9; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00040000
ins_b01_010:   @ bank 1 entry 10; PSG wave; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=psgwave_6, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00000002
ins_b01_011:   @ bank 1 entry 11; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 7 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x122492, psg=0x00000003
ins_b01_012:   @ bank 1 entry 12; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 7 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x122492, psg=0x00080003
ins_b01_013:   @ bank 1 entry 13; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00040001
ins_b01_014:   @ bank 1 entry 14; PSG wave; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=psgwave_3, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00000002
ins_b01_015:   @ bank 1 entry 15; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 11 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0xB8BA2, psg=0x00040001
ins_b01_016:   @ bank 1 entry 16; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x0004CC00
ins_b01_017:   @ bank 1 entry 17; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00049000
ins_b01_018:   @ bank 1 entry 18; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00054C00
ins_b01_019:   @ bank 1 entry 19; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 7 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x122492, psg=0x00045400
ins_b01_020:   @ bank 1 entry 20; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00080003
ins_b01_021:   @ bank 1 entry 21; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 17 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x77878, psg=0x00080003
ins_b01_022:   @ bank 1 entry 22; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000003
ins_b01_023:   @ bank 1 entry 23; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 17 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x77878, psg=0x00000003
ins_b01_030:   @ bank 1 entry 30; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000000
ins_b01_031:   @ bank 1 entry 31; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00020000
ins_b01_032:   @ bank 1 entry 32; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00040000
ins_b01_033:   @ bank 1 entry 33; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 14 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x91249, psg=0x00000000
ins_b01_034:   @ bank 1 entry 34; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 14 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x91249, psg=0x00020000
ins_b01_035:   @ bank 1 entry 35; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 14 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x91249, psg=0x00040000
ins_b01_036:   @ bank 1 entry 36; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000001
ins_b01_037:   @ bank 1 entry 37; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00020001
ins_b01_038:   @ bank 1 entry 38; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00040001
ins_b01_039:   @ bank 1 entry 39; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 14 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x91249, psg=0x00000001
ins_b01_040:   @ bank 1 entry 40; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 14 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x91249, psg=0x00020001
ins_b01_041:   @ bank 1 entry 41; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 14 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x91249, psg=0x00040001
ins_b01_042:   @ bank 1 entry 42; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 22050 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_015, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x218000
ins_b01_043:   @ bank 1 entry 43; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 22050 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_015, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b01_044:   @ bank 1 entry 44; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_016, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b01_045:   @ bank 1 entry 45; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_016, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b01_050:   @ bank 1 entry 50; PSG square 1; start 115, attack 1 fr, decay to 64.0 in 14 fr, sustain rate 0, release 17 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x73745D, sustain=0x400000, attack=0x1FC000, decay=0x4B425, sustain_rate=0x0, release=0x3F800, psg=0x00040000
ins_b01_051:   @ bank 1 entry 51; PSG square 2; start 115, attack 1 fr, decay to 64.0 in 14 fr, sustain rate 0, release 17 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x73745D, sustain=0x400000, attack=0x1FC000, decay=0x4B425, sustain_rate=0x0, release=0x3F800, psg=0x00040001
ins_b01_063:   @ bank 1 entry 63; start 127, attack 0 fr, decay to 51.3 in 5 fr, sustain rate 0, release 4 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_017, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xF6A90
ins_b01_098:   @ bank 1 entry 98; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 22050 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_015, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b01_102:   @ bank 1 entry 102; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 10512 root 57
	ins_sample key=60, nointerp=0, pan=127, sample=smp_018, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b01_103:   @ bank 1 entry 103; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_019, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b01_104:   @ bank 1 entry 104; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 57
	ins_sample key=60, nointerp=0, pan=127, sample=smp_020, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b01_107:   @ bank 1 entry 107; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_021, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b01_108:   @ bank 1 entry 108; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_022, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b01_109:   @ bank 1 entry 109; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_023, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b01_110:   @ bank 1 entry 110; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_024, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b01_111:   @ bank 1 entry 111; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_025, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b01_112:   @ bank 1 entry 112; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_026, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b01_113:   @ bank 1 entry 113; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_024, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b01_114:   @ bank 1 entry 114; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_027, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b01_115:   @ bank 1 entry 115; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_028, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b01_116:   @ bank 1 entry 116; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_029, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b01_117:   @ bank 1 entry 117; drum map: key k -> bank_04[k - 36]
	ins_drummap base=36, table=bank_04
ins_b01_120:   @ bank 1 entry 120; key split: key k -> bank_00[keymap_2[k - 36]]
	ins_split base=36, keymap=keymap_2, table=bank_00
ins_b01_121:   @ bank 1 entry 121; key split: key k -> bank_00[keymap_3[k - 36]]
	ins_split base=36, keymap=keymap_3, table=bank_00
ins_b01_122:   @ bank 1 entry 122; key split: key k -> bank_00[keymap_1[k - 36]]
	ins_split base=36, keymap=keymap_1, table=bank_00
ins_b01_123:   @ bank 1 entry 123; drum map: key k -> bank_09[k - 36]
	ins_drummap base=36, table=bank_09
ins_b01_124:   @ bank 1 entry 124; drum map: key k -> bank_08[k - 36]
	ins_drummap base=36, table=bank_08
ins_b01_125:   @ bank 1 entry 125; drum map: key k -> bank_07[k - 36]
	ins_drummap base=36, table=bank_07
ins_b01_126:   @ bank 1 entry 126; drum map: key k -> bank_06[k - 36]
	ins_drummap base=36, table=bank_06
ins_b01_127:   @ bank 1 entry 127; drum map: key k -> bank_05[k - 36]
	ins_drummap base=36, table=bank_05
ins_b02_050:   @ bank 2 entry 50; start 0, attack 2 fr, decay to 25.7 in 7 fr, sustain rate 0, release 2 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_030, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b02_051:   @ bank 2 entry 51; start 0, attack 2 fr, decay to 25.7 in 16 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_002, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x690CE, sustain_rate=0x0, release=0x55552
ins_b02_052:   @ bank 2 entry 52; start 0, attack 2 fr, decay to 25.7 in 16 fr, sustain rate 0, release 3 fr; sample rate 10512 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_031, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x690CE, sustain_rate=0x0, release=0xB8000
ins_b02_053:   @ bank 2 entry 53; start 0, attack 2 fr, decay to 25.7 in 16 fr, sustain rate 0, release 5 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_032, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x690CE, sustain_rate=0x0, release=0x55552
ins_b02_054:   @ bank 2 entry 54; key split: key k -> bank_00[keymap_0[k - 36]]
	ins_split base=36, keymap=keymap_0, table=bank_00
ins_b02_055:   @ bank 2 entry 55; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 5 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_033, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b02_056:   @ bank 2 entry 56; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 5 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_034, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b02_057:   @ bank 2 entry 57; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 10 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_035, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b02_058:   @ bank 2 entry 58; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 10 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_036, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b02_059:   @ bank 2 entry 59; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 5 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_037, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b02_060:   @ bank 2 entry 60; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 5 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_038, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b02_126:   @ bank 2 entry 126; drum map: key k -> bank_06[k - 36]
	ins_drummap base=36, table=bank_06
ins_b03_000:   @ bank 3 entry 0; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00047000
ins_b03_001:   @ bank 3 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_039, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_002:   @ bank 3 entry 2; start 127, attack 0 fr, decay to 102.6 in 75 fr, sustain rate 0, release 13 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_040, env_start=0x7F0000, sustain=0x66A052, attack=0x600000, decay=0x540A, sustain_rate=0x0, release=0x82378
ins_b03_004:   @ bank 3 entry 4; start 127, attack 0 fr, decay to 12.8 in 70 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_041, env_start=0x7F0000, sustain=0xCD40A, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b03_005:   @ bank 3 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_042, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_007:   @ bank 3 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_043, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b03_008:   @ bank 3 entry 8; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_044, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b03_009:   @ bank 3 entry 9; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 11 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0xB8BA2, psg=0x00040000
ins_b03_010:   @ bank 3 entry 10; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 11 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0xB8BA2, psg=0x00040001
ins_b03_011:   @ bank 3 entry 11; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00040000
ins_b03_012:   @ bank 3 entry 12; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00040001
ins_b03_013:   @ bank 3 entry 13; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000003
ins_b03_014:   @ bank 3 entry 14; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00080003
ins_b03_015:   @ bank 3 entry 15; start 127, attack 0 fr, decay to 12.8 in 348 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_045, env_start=0x7F0000, sustain=0xCD40A, attack=0x600000, decay=0x540A, sustain_rate=0x0, release=0x31548
ins_b03_016:   @ bank 3 entry 16; start 127, attack 0 fr, decay to 102.6 in 3 fr, sustain rate 0, release 7 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_046, env_start=0x7F0000, sustain=0x66A052, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0xF6A90
ins_b03_017:   @ bank 3 entry 17; start 127, attack 0 fr, decay to 102.6 in 3 fr, sustain rate 0, release 13 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_046, env_start=0x7F0000, sustain=0x66A052, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0x82378
ins_b03_018:   @ bank 3 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_047, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b03_019:   @ bank 3 entry 19; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_048, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b03_020:   @ bank 3 entry 20; PSG square 1; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000000
ins_b03_021:   @ bank 3 entry 21; PSG square 2; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 4 fr
	ins_psg key=60, nointerp=0, pan=127, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x1FC000, psg=0x00000001
ins_b03_023:   @ bank 3 entry 23; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 4 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_049, env_start=0x0, sustain=0x267C1F, attack=0x526C9B, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b03_024:   @ bank 3 entry 24; key split: key k -> bank_00[keymap_0[k - 36]]
	ins_split base=36, keymap=keymap_0, table=bank_00
ins_b03_026:   @ bank 3 entry 26; start 127, attack 0 fr, decay to 25.7 in 62 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_050, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b03_027:   @ bank 3 entry 27; start 127, attack 0 fr, decay to 51.3 in 47 fr, sustain rate 0, release 10 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_051, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b03_028:   @ bank 3 entry 28; start 127, attack 0 fr, decay to 51.3 in 5 fr, sustain rate 0, release 3 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_052, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b03_029:   @ bank 3 entry 29; start 127, attack 0 fr, decay to 51.3 in 47 fr, sustain rate 0, release 10 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_053, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b03_031:   @ bank 3 entry 31; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_054, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b03_032:   @ bank 3 entry 32; start 127, attack 0 fr, decay to 38.5 in 9 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_055, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0xB8000
ins_b03_035:   @ bank 3 entry 35; start 127, attack 0 fr, decay to 25.7 in 309 fr, sustain rate 0, release 2 fr; sample rate 13379 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_056, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x540A, sustain_rate=0x0, release=0x13E350
ins_b03_036:   @ bank 3 entry 36; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 4 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_057, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b03_037:   @ bank 3 entry 37; start 127, attack 0 fr, decay to 38.5 in 6 fr, sustain rate 0, release 3 fr; sample rate 7884 root 55
	ins_sample key=60, nointerp=0, pan=127, sample=smp_058, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xF6A90
ins_b03_047:   @ bank 3 entry 47; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_059, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b03_048:   @ bank 3 entry 48; start 0, attack 2 fr, decay to 38.5 in 54 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_060, env_start=0x0, sustain=0x267C1F, attack=0x5E0F83, decay=0x1A433, sustain_rate=0x0, release=0x82378
ins_b03_049:   @ bank 3 entry 49; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_061, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b03_055:   @ bank 3 entry 55; start 0, attack 2 fr, decay to 51.3 in 47 fr, sustain rate 0, release 4 fr; sample rate 5734 root 52
	ins_sample key=60, nointerp=0, pan=127, sample=smp_062, env_start=0x0, sustain=0x335029, attack=0x5745D1, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b03_060:   @ bank 3 entry 60; start 127, attack 0 fr, decay to 51.3 in 5 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_063, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xF6A90
ins_b03_061:   @ bank 3 entry 61; start 0, attack 2 fr, decay to 51.3 in 5 fr, sustain rate 0, release 4 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_064, env_start=0x0, sustain=0x335029, attack=0x5745D1, decay=0x106A05, sustain_rate=0x0, release=0xF6A90
ins_b03_062:   @ bank 3 entry 62; start 127, attack 0 fr, decay to 51.3 in 5 fr, sustain rate 0, release 4 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_064, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xF6A90
ins_b03_063:   @ bank 3 entry 63; start 127, attack 0 fr, decay to 51.3 in 5 fr, sustain rate 0, release 4 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_017, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0xF6A90
ins_b03_071:   @ bank 3 entry 71; start 127, attack 0 fr, decay to 77.0 in 8 fr, sustain rate 0, release 5 fr; sample rate 5734 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_065, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0xF6A90
ins_b03_072:   @ bank 3 entry 72; start 127, attack 0 fr, decay to 77.0 in 8 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_066, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0xF6A90
ins_b03_074:   @ bank 3 entry 74; start 127, attack 0 fr, decay to 77.0 in 8 fr, sustain rate 0, release 5 fr; sample rate 13379 root 77
	ins_sample key=60, nointerp=0, pan=127, sample=smp_067, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0xF6A90
ins_b03_079:   @ bank 3 entry 79; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_068, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b03_080:   @ bank 3 entry 80; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_069, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_081:   @ bank 3 entry 81; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_068, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b03_082:   @ bank 3 entry 82; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 48
	ins_sample key=60, nointerp=0, pan=127, sample=smp_070, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_083:   @ bank 3 entry 83; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 44100 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_071, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_084:   @ bank 3 entry 84; start 0, attack 2 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 22050 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_015, env_start=0x0, sustain=0x7F0000, attack=0x5745D1, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b03_085:   @ bank 3 entry 85; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 44100 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_071, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b03_086:   @ bank 3 entry 86; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 13379 root 69
	ins_sample key=60, nointerp=0, pan=127, sample=smp_072, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b03_087:   @ bank 3 entry 87; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_073, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b03_090:   @ bank 3 entry 90; start 127, attack 0 fr, decay to 89.8 in 12 fr, sustain rate 0, release 4 fr; sample rate 10512 root 79
	ins_sample key=60, nointerp=0, pan=127, sample=smp_074, env_start=0x7F0000, sustain=0x59CC48, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x18EA90
ins_b03_093:   @ bank 3 entry 93; start 127, attack 0 fr, decay to 25.7 in 7 fr, sustain rate 0, release 1 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_075, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x1FC000
ins_b03_095:   @ bank 3 entry 95; start 127, attack 0 fr, decay to 89.8 in 3 fr, sustain rate 0, release 3 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_076, env_start=0x7F0000, sustain=0x59CC48, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x1E7FBA
ins_b03_098:   @ bank 3 entry 98; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 22050 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_015, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b03_099:   @ bank 3 entry 99; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 28 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_016, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x1638C
ins_b03_101:   @ bank 3 entry 101; start 127, attack 0 fr, decay to 38.5 in 6 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_077, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x82378
ins_b03_103:   @ bank 3 entry 103; drum map: key k -> bank_15[k - 36]
	ins_drummap base=36, table=bank_15
ins_b03_104:   @ bank 3 entry 104; drum map: key k -> bank_10[k - 36]
	ins_drummap base=36, table=bank_10
ins_b03_105:   @ bank 3 entry 105; drum map: key k -> bank_12[k - 24]
	ins_drummap base=24, table=bank_12
ins_b03_106:   @ bank 3 entry 106; drum map: key k -> bank_13[k - 24]
	ins_drummap base=24, table=bank_13
ins_b03_107:   @ bank 3 entry 107; drum map: key k -> bank_14[k - 24]
	ins_drummap base=24, table=bank_14
ins_b03_109:   @ bank 3 entry 109; drum map: key k -> bank_11[k - 36]
	ins_drummap base=36, table=bank_11
ins_b03_110:   @ bank 3 entry 110; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_078, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_111:   @ bank 3 entry 111; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 3 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_079, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x18EA90
ins_b03_112:   @ bank 3 entry 112; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 4 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_080, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b03_113:   @ bank 3 entry 113; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_027, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_114:   @ bank 3 entry 114; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_081, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_115:   @ bank 3 entry 115; start 127, attack 0 fr, decay to 25.7 in 16 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_082, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x82378
ins_b03_116:   @ bank 3 entry 116; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_028, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b03_117:   @ bank 3 entry 117; drum map: key k -> bank_04[k - 36]
	ins_drummap base=36, table=bank_04
ins_b03_118:   @ bank 3 entry 118; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_083, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b03_119:   @ bank 3 entry 119; start 127, attack 0 fr, decay to 38.5 in 9 fr, sustain rate 0, release 5 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_084, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0x82378
ins_b03_120:   @ bank 3 entry 120; key split: key k -> bank_00[keymap_2[k - 36]]
	ins_split base=36, keymap=keymap_2, table=bank_00
ins_b03_121:   @ bank 3 entry 121; key split: key k -> bank_00[keymap_3[k - 36]]
	ins_split base=36, keymap=keymap_3, table=bank_00
ins_b03_122:   @ bank 3 entry 122; key split: key k -> bank_00[keymap_1[k - 36]]
	ins_split base=36, keymap=keymap_1, table=bank_00
ins_b03_123:   @ bank 3 entry 123; drum map: key k -> bank_09[k - 36]
	ins_drummap base=36, table=bank_09
ins_b03_124:   @ bank 3 entry 124; drum map: key k -> bank_08[k - 36]
	ins_drummap base=36, table=bank_08
ins_b03_125:   @ bank 3 entry 125; drum map: key k -> bank_07[k - 36]
	ins_drummap base=36, table=bank_07
ins_b03_126:   @ bank 3 entry 126; drum map: key k -> bank_06[k - 36]
	ins_drummap base=36, table=bank_06
ins_b03_127:   @ bank 3 entry 127; drum map: key k -> bank_05[k - 36]
	ins_drummap base=36, table=bank_05
ins_b04_000:   @ bank 4 entry 0; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_085, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x13E350
ins_b04_001:   @ bank 4 entry 1; start 127, attack 0 fr, decay to 115.5 in 4 fr, sustain rate 0, release 22 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_086, env_start=0x7F0000, sustain=0x73745D, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b04_002:   @ bank 4 entry 2; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_087, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b04_003:   @ bank 4 entry 3; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_088, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b04_004:   @ bank 4 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_089, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_005:   @ bank 4 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_090, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_006:   @ bank 4 entry 6; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_091, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_007:   @ bank 4 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_092, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_008:   @ bank 4 entry 8; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_093, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_009:   @ bank 4 entry 9; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_094, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_011:   @ bank 4 entry 11; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 2 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_095, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x18EA90
ins_b04_012:   @ bank 4 entry 12; start 127, attack 0 fr, decay to 25.7 in 16 fr, sustain rate 0, release 2 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_096, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x18EA90
ins_b04_013:   @ bank 4 entry 13; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_097, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_014:   @ bank 4 entry 14; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_098, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_015:   @ bank 4 entry 15; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_099, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_016:   @ bank 4 entry 16; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_100, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_017:   @ bank 4 entry 17; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_101, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_018:   @ bank 4 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_102, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_019:   @ bank 4 entry 19; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_103, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_020:   @ bank 4 entry 20; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_104, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b04_021:   @ bank 4 entry 21; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_105, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x218000
ins_b05_000:   @ bank 5 entry 0; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_106, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b05_001:   @ bank 5 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_107, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b05_002:   @ bank 5 entry 2; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_108, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b05_003:   @ bank 5 entry 3; start 127, attack 0 fr, decay to 25.7 in 7 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_109, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x13E350
ins_b05_004:   @ bank 5 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_110, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b05_005:   @ bank 5 entry 5; start 127, attack 0 fr, decay to 38.5 in 6 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_111, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x13E350
ins_b05_007:   @ bank 5 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_112, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b05_009:   @ bank 5 entry 9; start 127, attack 0 fr, decay to 25.7 in 45 fr, sustain rate 0, release 4 fr; sample rate 13379 root 67
	ins_sample key=48, nointerp=0, pan=127, sample=smp_113, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x24C48, sustain_rate=0x0, release=0x82378
ins_b05_011:   @ bank 5 entry 11; start 127, attack 0 fr, decay to 25.7 in 45 fr, sustain rate 0, release 4 fr; sample rate 13379 root 67
	ins_sample key=54, nointerp=0, pan=127, sample=smp_113, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x24C48, sustain_rate=0x0, release=0x82378
ins_b05_012:   @ bank 5 entry 12; start 127, attack 0 fr, decay to 25.7 in 45 fr, sustain rate 0, release 4 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_113, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x24C48, sustain_rate=0x0, release=0x82378
ins_b05_013:   @ bank 5 entry 13; start 127, attack 0 fr, decay to 1.3 in 39 fr, sustain rate 0, release 1 fr; sample rate 13379 root 62
	ins_sample key=60, nointerp=0, pan=127, sample=smp_114, env_start=0x7F0000, sustain=0x14867, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b05_014:   @ bank 5 entry 14; start 127, attack 0 fr, decay to 25.7 in 6 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_115, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x13B26C, sustain_rate=0x0, release=0xF6A90
ins_b05_018:   @ bank 5 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_116, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b05_020:   @ bank 5 entry 20; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_117, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b05_022:   @ bank 5 entry 22; start 127, attack 0 fr, decay to 77.0 in 8 fr, sustain rate 0, release 36 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_118, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x22AA4
ins_b05_024:   @ bank 5 entry 24; start 0, attack 2 fr, decay to 25.7 in 7 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_119, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b05_025:   @ bank 5 entry 25; start 0, attack 2 fr, decay to 25.7 in 7 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_120, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b05_027:   @ bank 5 entry 27; start 0, attack 2 fr, decay to 25.7 in 7 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_121, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b05_028:   @ bank 5 entry 28; start 0, attack 2 fr, decay to 25.7 in 7 fr, sustain rate 0, release 2 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_030, env_start=0x0, sustain=0x19A814, attack=0x5D1745, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b05_032:   @ bank 5 entry 32; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_122, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b05_033:   @ bank 5 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_123, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b05_034:   @ bank 5 entry 34; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_124, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b05_035:   @ bank 5 entry 35; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_125, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b05_036:   @ bank 5 entry 36; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_126, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b05_038:   @ bank 5 entry 38; start 127, attack 0 fr, decay to 38.5 in 14 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_127, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x82378
ins_b05_053:   @ bank 5 entry 53; start 127, attack 0 fr, decay to 102.6 in 3 fr, sustain rate 0, release 7 fr; sample rate 5000 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_128, env_start=0x7F0000, sustain=0x66A052, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0xF6A90
ins_b05_054:   @ bank 5 entry 54; start 127, attack 0 fr, decay to 25.7 in 21 fr, sustain rate 0, release 4 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_129, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x4EC9B, sustain_rate=0x0, release=0x82378
ins_b05_055:   @ bank 5 entry 55; start 127, attack 0 fr, decay to 25.7 in 21 fr, sustain rate 0, release 4 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_130, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x4EC9B, sustain_rate=0x0, release=0x82378
ins_b05_056:   @ bank 5 entry 56; start 127, attack 0 fr, decay to 19.2 in 17 fr, sustain rate 0, release 3 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_131, env_start=0x7F0000, sustain=0x133E0F, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x82378
ins_b05_057:   @ bank 5 entry 57; start 127, attack 0 fr, decay to 25.7 in 21 fr, sustain rate 0, release 4 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_132, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x4EC9B, sustain_rate=0x0, release=0x82378
ins_b05_059:   @ bank 5 entry 59; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=51, nointerp=0, pan=0, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00080003
ins_b05_060:   @ bank 5 entry 60; PSG noise; start 127, attack 0 fr, decay to 126.0 in 1 fr, sustain rate 0, release 1 fr
	ins_psg key=62, nointerp=0, pan=0, wave=0, env_start=0x7F0000, sustain=0x7E0000, attack=0x7F0000, decay=0x7F0000, sustain_rate=0x0, release=0x7F0000, psg=0x00080003
ins_b06_000:   @ bank 6 entry 0; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 64
	ins_sample key=48, nointerp=0, pan=127, sample=smp_133, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b06_001:   @ bank 6 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_134, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b06_002:   @ bank 6 entry 2; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_135, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b06_004:   @ bank 6 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 60
	ins_sample key=40, nointerp=0, pan=127, sample=smp_028, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_005:   @ bank 6 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_136, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b06_006:   @ bank 6 entry 6; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 60
	ins_sample key=55, nointerp=0, pan=127, sample=smp_137, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b06_007:   @ bank 6 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_137, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b06_008:   @ bank 6 entry 8; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=86, nointerp=0, pan=127, sample=smp_012, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_009:   @ bank 6 entry 9; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_138, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_010:   @ bank 6 entry 10; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_139, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_011:   @ bank 6 entry 11; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 92 fr; sample rate 13379 root 65
	ins_sample key=65, nointerp=0, pan=127, sample=smp_140, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1638C
ins_b06_012:   @ bank 6 entry 12; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_141, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x218000
ins_b06_013:   @ bank 6 entry 13; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_142, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_014:   @ bank 6 entry 14; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_029, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_015:   @ bank 6 entry 15; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 13379 root 67
	ins_sample key=55, nointerp=0, pan=127, sample=smp_143, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b06_016:   @ bank 6 entry 16; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 4 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_143, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1FC000
ins_b06_017:   @ bank 6 entry 17; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 4 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_028, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b06_018:   @ bank 6 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_019, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b06_019:   @ bank 6 entry 19; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 57
	ins_sample key=60, nointerp=0, pan=127, sample=smp_020, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b06_020:   @ bank 6 entry 20; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_144, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_021:   @ bank 6 entry 21; start 0, attack 5 fr, decay to 102.6 in 15 fr, sustain rate 0, release 137 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_145, env_start=0x0, sustain=0x66A052, attack=0x1D1745, decay=0x1A433, sustain_rate=0x0, release=0xC000
ins_b06_022:   @ bank 6 entry 22; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_146, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_024:   @ bank 6 entry 24; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_147, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_025:   @ bank 6 entry 25; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_148, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_026:   @ bank 6 entry 26; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 62
	ins_sample key=60, nointerp=0, pan=127, sample=smp_149, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_027:   @ bank 6 entry 27; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_150, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_028:   @ bank 6 entry 28; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_151, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b06_029:   @ bank 6 entry 29; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_152, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b06_030:   @ bank 6 entry 30; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_023, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b06_031:   @ bank 6 entry 31; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 70
	ins_sample key=48, nointerp=0, pan=127, sample=smp_007, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b06_032:   @ bank 6 entry 32; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_153, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b06_033:   @ bank 6 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_021, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b06_034:   @ bank 6 entry 34; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_022, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b06_035:   @ bank 6 entry 35; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_154, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b06_036:   @ bank 6 entry 36; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 14 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_155, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x9BFDD
ins_b06_037:   @ bank 6 entry 37; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_156, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_038:   @ bank 6 entry 38; start 127, attack 0 fr, decay to 25.7 in 4 fr, sustain rate 0, release 1 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_157, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433B, sustain_rate=0x0, release=0x1E7FBA
ins_b06_039:   @ bank 6 entry 39; start 127, attack 0 fr, decay to 25.7 in 4 fr, sustain rate 0, release 1 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_158, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433B, sustain_rate=0x0, release=0x1E7FBA
ins_b06_040:   @ bank 6 entry 40; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 66
	ins_sample key=60, nointerp=0, pan=127, sample=smp_159, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_041:   @ bank 6 entry 41; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 66
	ins_sample key=60, nointerp=0, pan=127, sample=smp_160, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b06_043:   @ bank 6 entry 43; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 10512 root 57
	ins_sample key=60, nointerp=0, pan=127, sample=smp_018, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b06_044:   @ bank 6 entry 44; start 127, attack 0 fr, decay to 77.0 in 4 fr, sustain rate 0, release 15 fr; sample rate 10512 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_161, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x55552
ins_b06_045:   @ bank 6 entry 45; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=48, nointerp=0, pan=127, sample=smp_162, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b06_046:   @ bank 6 entry 46; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_163, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_047:   @ bank 6 entry 47; start 0, attack 2 fr, decay to 51.3 in 47 fr, sustain rate 0, release 5 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_164, env_start=0x0, sustain=0x335029, attack=0x4D9364, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b06_048:   @ bank 6 entry 48; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_165, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b06_049:   @ bank 6 entry 49; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_166, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_050:   @ bank 6 entry 50; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_167, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_051:   @ bank 6 entry 51; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_168, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_052:   @ bank 6 entry 52; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_169, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b06_053:   @ bank 6 entry 53; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_170, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b06_054:   @ bank 6 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_171, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b06_055:   @ bank 6 entry 55; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_172, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b06_056:   @ bank 6 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_173, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b06_057:   @ bank 6 entry 57; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_174, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b06_058:   @ bank 6 entry 58; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 31 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_175, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x42378
ins_b06_059:   @ bank 6 entry 59; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 59 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_176, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x22AA4
ins_b06_060:   @ bank 6 entry 60; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 170 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_177, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xC000
ins_b07_022:   @ bank 7 entry 22; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_178, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b07_023:   @ bank 7 entry 23; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_179, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b07_024:   @ bank 7 entry 24; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_180, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b07_025:   @ bank 7 entry 25; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_181, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b07_026:   @ bank 7 entry 26; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_182, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b07_027:   @ bank 7 entry 27; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_183, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b07_028:   @ bank 7 entry 28; start 0, attack 3 fr, decay to 25.7 in 31 fr, sustain rate 0, release 2 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_184, env_start=0x0, sustain=0x19A814, attack=0x3A2E8B, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b07_029:   @ bank 7 entry 29; start 0, attack 3 fr, decay to 64.1 in 20 fr, sustain rate 0, release 5 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_185, env_start=0x0, sustain=0x402433, attack=0x3A2E8B, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b07_030:   @ bank 7 entry 30; start 0, attack 3 fr, decay to 51.3 in 24 fr, sustain rate 0, release 7 fr; sample rate 10512 root 60
	ins_sample key=61, nointerp=0, pan=127, sample=smp_186, env_start=0x0, sustain=0x335029, attack=0x3A2E8B, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b07_031:   @ bank 7 entry 31; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 13 fr; sample rate 10512 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_187, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b07_032:   @ bank 7 entry 32; start 0, attack 2 fr, decay to 25.7 in 16 fr, sustain rate 0, release 4 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_188, env_start=0x0, sustain=0x19A814, attack=0x4D9364, decay=0x690CE, sustain_rate=0x0, release=0x82378
ins_b07_033:   @ bank 7 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 10512 root 66
	ins_sample key=60, nointerp=0, pan=127, sample=smp_189, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b07_034:   @ bank 7 entry 34; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 10512 root 66
	ins_sample key=60, nointerp=0, pan=127, sample=smp_190, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b07_035:   @ bank 7 entry 35; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 21 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_191, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x31548
ins_b07_036:   @ bank 7 entry 36; start 0, attack 2 fr, decay to 51.3 in 231 fr, sustain rate 0, release 10 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_192, env_start=0x0, sustain=0x335029, attack=0x4D9364, decay=0x540A, sustain_rate=0x0, release=0x55552
ins_b07_037:   @ bank 7 entry 37; start 127, attack 0 fr, decay to 51.3 in 231 fr, sustain rate 0, release 10 fr; sample rate 10512 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_193, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0x540A, sustain_rate=0x0, release=0x55552
ins_b07_038:   @ bank 7 entry 38; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_194, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_041:   @ bank 7 entry 41; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_195, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_042:   @ bank 7 entry 42; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_196, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_043:   @ bank 7 entry 43; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_197, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_044:   @ bank 7 entry 44; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_198, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_045:   @ bank 7 entry 45; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_199, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_046:   @ bank 7 entry 46; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_200, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_047:   @ bank 7 entry 47; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_201, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_048:   @ bank 7 entry 48; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_202, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_049:   @ bank 7 entry 49; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_203, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_050:   @ bank 7 entry 50; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_204, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_051:   @ bank 7 entry 51; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_205, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_052:   @ bank 7 entry 52; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_206, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_053:   @ bank 7 entry 53; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_207, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_054:   @ bank 7 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_208, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_055:   @ bank 7 entry 55; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_209, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_056:   @ bank 7 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_210, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_057:   @ bank 7 entry 57; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_211, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_058:   @ bank 7 entry 58; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_212, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b07_059:   @ bank 7 entry 59; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 1000 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_213, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b07_060:   @ bank 7 entry 60; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_214, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b07_061:   @ bank 7 entry 61; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_215, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_000:   @ bank 8 entry 0; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_134, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b08_001:   @ bank 8 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 66
	ins_sample key=60, nointerp=0, pan=127, sample=smp_216, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b08_002:   @ bank 8 entry 2; start 127, attack 0 fr, decay to 6.4 in 74 fr, sustain rate 0, release 2 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_217, env_start=0x7F0000, sustain=0x66A05, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b08_003:   @ bank 8 entry 3; start 0, attack 3 fr, decay to 127.0 in 0 fr, sustain rate 0, release 16 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_218, env_start=0x0, sustain=0x7F0000, attack=0x307C1F, decay=0x208000, sustain_rate=0x0, release=0x82378
ins_b08_004:   @ bank 8 entry 4; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 2 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_219, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x18EA90
ins_b08_005:   @ bank 8 entry 5; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 6 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_220, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b08_006:   @ bank 8 entry 6; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_221, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b08_007:   @ bank 8 entry 7; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 2 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_222, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x18EA90
ins_b08_008:   @ bank 8 entry 8; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 2 fr; sample rate 10512 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_223, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x13E350
ins_b08_010:   @ bank 8 entry 10; start 0, attack 7 fr, decay to 127.0 in 0 fr, sustain rate 0, release 92 fr; sample rate 10512 root 72
	ins_sample key=50, nointerp=0, pan=127, sample=smp_224, env_start=0x0, sustain=0x7F0000, attack=0x1364D9, decay=0x208000, sustain_rate=0x0, release=0x1638C
ins_b08_011:   @ bank 8 entry 11; start 0, attack 7 fr, decay to 89.8 in 23 fr, sustain rate 0, release 65 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_225, env_start=0x0, sustain=0x59CC48, attack=0x1364D9, decay=0x1A433, sustain_rate=0x0, release=0x1638C
ins_b08_012:   @ bank 8 entry 12; start 0, attack 2 fr, decay to 89.8 in 23 fr, sustain rate 0, release 8 fr; sample rate 10512 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_226, env_start=0x0, sustain=0x59CC48, attack=0x4D9364, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b08_013:   @ bank 8 entry 13; start 127, attack 0 fr, decay to 38.5 in 9 fr, sustain rate 0, release 2 fr; sample rate 13379 root 52
	ins_sample key=53, nointerp=0, pan=127, sample=smp_008, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0x18EA90
ins_b08_014:   @ bank 8 entry 14; start 127, attack 0 fr, decay to 38.5 in 9 fr, sustain rate 0, release 2 fr; sample rate 13379 root 52
	ins_sample key=55, nointerp=0, pan=127, sample=smp_008, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0x18EA90
ins_b08_015:   @ bank 8 entry 15; start 127, attack 0 fr, decay to 64.1 in 4 fr, sustain rate 0, release 3 fr; sample rate 10512 root 64
	ins_sample key=53, nointerp=0, pan=127, sample=smp_227, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b08_016:   @ bank 8 entry 16; start 127, attack 0 fr, decay to 64.1 in 4 fr, sustain rate 0, release 3 fr; sample rate 10512 root 64
	ins_sample key=55, nointerp=0, pan=127, sample=smp_227, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x106A05, sustain_rate=0x0, release=0x18EA90
ins_b08_017:   @ bank 8 entry 17; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 64
	ins_sample key=57, nointerp=0, pan=127, sample=smp_228, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_018:   @ bank 8 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 64
	ins_sample key=60, nointerp=0, pan=127, sample=smp_228, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_020:   @ bank 8 entry 20; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_025, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b08_021:   @ bank 8 entry 21; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_026, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b08_022:   @ bank 8 entry 22; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 24 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_024, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x55552
ins_b08_023:   @ bank 8 entry 23; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_029, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b08_024:   @ bank 8 entry 24; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 13379 root 72
	ins_sample key=55, nointerp=0, pan=127, sample=smp_229, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b08_025:   @ bank 8 entry 25; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_229, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b08_026:   @ bank 8 entry 26; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 72
	ins_sample key=58, nointerp=0, pan=127, sample=smp_230, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b08_027:   @ bank 8 entry 27; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_230, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b08_030:   @ bank 8 entry 30; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_231, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_031:   @ bank 8 entry 31; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=65, nointerp=0, pan=127, sample=smp_231, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_032:   @ bank 8 entry 32; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=68, nointerp=0, pan=127, sample=smp_231, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_033:   @ bank 8 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_232, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_034:   @ bank 8 entry 34; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=65, nointerp=0, pan=127, sample=smp_232, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_035:   @ bank 8 entry 35; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=70, nointerp=0, pan=127, sample=smp_232, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_036:   @ bank 8 entry 36; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_233, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_040:   @ bank 8 entry 40; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_042, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b08_042:   @ bank 8 entry 42; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_043, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_043:   @ bank 8 entry 43; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 10512 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_044, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b08_045:   @ bank 8 entry 45; start 127, attack 0 fr, decay to 38.5 in 18 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_234, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x4EC9B, sustain_rate=0x0, release=0x82378
ins_b08_046:   @ bank 8 entry 46; start 127, attack 0 fr, decay to 25.7 in 45 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_235, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x24C48, sustain_rate=0x0, release=0x82378
ins_b08_047:   @ bank 8 entry 47; start 127, attack 0 fr, decay to 25.7 in 45 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_236, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x24C48, sustain_rate=0x0, release=0x82378
ins_b08_048:   @ bank 8 entry 48; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_237, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_049:   @ bank 8 entry 49; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_238, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x13E350
ins_b08_050:   @ bank 8 entry 50; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_239, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_051:   @ bank 8 entry 51; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_240, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_052:   @ bank 8 entry 52; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_241, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_054:   @ bank 8 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_242, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_055:   @ bank 8 entry 55; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_243, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_056:   @ bank 8 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_244, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_057:   @ bank 8 entry 57; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_245, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_058:   @ bank 8 entry 58; start 127, attack 0 fr, decay to 12.8 in 24 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_246, env_start=0x7F0000, sustain=0xCD40A, attack=0x600000, decay=0x4EC9B, sustain_rate=0x0, release=0x55552
ins_b08_059:   @ bank 8 entry 59; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_247, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_060:   @ bank 8 entry 60; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_248, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_061:   @ bank 8 entry 61; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_249, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_062:   @ bank 8 entry 62; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_250, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_063:   @ bank 8 entry 63; start 127, attack 0 fr, decay to 12.8 in 18 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_251, env_start=0x7F0000, sustain=0xCD40A, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0x82378
ins_b08_064:   @ bank 8 entry 64; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_252, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_065:   @ bank 8 entry 65; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_253, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_066:   @ bank 8 entry 66; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 70
	ins_sample key=60, nointerp=0, pan=127, sample=smp_254, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b08_067:   @ bank 8 entry 67; start 127, attack 0 fr, decay to 25.7 in 21 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_255, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x4EC9B, sustain_rate=0x0, release=0x13E350
ins_b08_068:   @ bank 8 entry 68; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_256, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_000:   @ bank 9 entry 0; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_257, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_001:   @ bank 9 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_258, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_002:   @ bank 9 entry 2; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_259, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_004:   @ bank 9 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_260, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_005:   @ bank 9 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_261, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_006:   @ bank 9 entry 6; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_262, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_007:   @ bank 9 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_263, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_010:   @ bank 9 entry 10; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_264, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_011:   @ bank 9 entry 11; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_265, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_012:   @ bank 9 entry 12; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_266, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_018:   @ bank 9 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_267, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_019:   @ bank 9 entry 19; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_268, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_020:   @ bank 9 entry 20; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_269, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_021:   @ bank 9 entry 21; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_270, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_022:   @ bank 9 entry 22; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_271, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_023:   @ bank 9 entry 23; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_272, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_024:   @ bank 9 entry 24; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_273, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_025:   @ bank 9 entry 25; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_274, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_026:   @ bank 9 entry 26; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_275, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_027:   @ bank 9 entry 27; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_276, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_028:   @ bank 9 entry 28; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_277, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_031:   @ bank 9 entry 31; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_278, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_032:   @ bank 9 entry 32; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_279, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_033:   @ bank 9 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_280, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_034:   @ bank 9 entry 34; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_281, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_035:   @ bank 9 entry 35; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_282, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_036:   @ bank 9 entry 36; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_283, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b09_037:   @ bank 9 entry 37; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_284, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_038:   @ bank 9 entry 38; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_285, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_039:   @ bank 9 entry 39; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_286, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_040:   @ bank 9 entry 40; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_287, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b09_041:   @ bank 9 entry 41; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_288, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_042:   @ bank 9 entry 42; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_289, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_043:   @ bank 9 entry 43; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_290, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_044:   @ bank 9 entry 44; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_291, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_045:   @ bank 9 entry 45; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_292, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_046:   @ bank 9 entry 46; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_293, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_047:   @ bank 9 entry 47; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_294, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_048:   @ bank 9 entry 48; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_295, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_049:   @ bank 9 entry 49; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_296, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_050:   @ bank 9 entry 50; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_297, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_051:   @ bank 9 entry 51; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_298, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_052:   @ bank 9 entry 52; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_299, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b09_053:   @ bank 9 entry 53; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_300, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b09_054:   @ bank 9 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_301, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_055:   @ bank 9 entry 55; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_302, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b09_056:   @ bank 9 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_303, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_057:   @ bank 9 entry 57; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_304, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_058:   @ bank 9 entry 58; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_305, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_059:   @ bank 9 entry 59; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_306, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b09_060:   @ bank 9 entry 60; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_307, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_061:   @ bank 9 entry 61; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_308, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b09_062:   @ bank 9 entry 62; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_309, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_000:   @ bank 10 entry 0; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_310, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_001:   @ bank 10 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_311, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_002:   @ bank 10 entry 2; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_312, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_003:   @ bank 10 entry 3; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_313, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_004:   @ bank 10 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_314, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_005:   @ bank 10 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_315, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_007:   @ bank 10 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_316, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_008:   @ bank 10 entry 8; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_317, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_009:   @ bank 10 entry 9; start 127, attack 0 fr, decay to 38.5 in 34 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_318, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x2A052, sustain_rate=0x0, release=0xB8000
ins_b10_010:   @ bank 10 entry 10; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_319, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_011:   @ bank 10 entry 11; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_320, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_012:   @ bank 10 entry 12; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_321, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_013:   @ bank 10 entry 13; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_322, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_014:   @ bank 10 entry 14; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_323, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_015:   @ bank 10 entry 15; start 127, attack 0 fr, decay to 25.7 in 62 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_324, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x82378
ins_b10_016:   @ bank 10 entry 16; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_325, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_017:   @ bank 10 entry 17; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_326, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b10_019:   @ bank 10 entry 19; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_327, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b10_020:   @ bank 10 entry 20; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_328, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b10_022:   @ bank 10 entry 22; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_329, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x18EA90
ins_b10_023:   @ bank 10 entry 23; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_330, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x13E350
ins_b10_025:   @ bank 10 entry 25; start 127, attack 0 fr, decay to 25.7 in 103 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_331, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0xFC1F, sustain_rate=0x0, release=0x13E350
ins_b10_026:   @ bank 10 entry 26; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_332, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_028:   @ bank 10 entry 28; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_333, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_029:   @ bank 10 entry 29; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_334, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b10_030:   @ bank 10 entry 30; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_335, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b10_031:   @ bank 10 entry 31; start 127, attack 0 fr, decay to 25.7 in 62 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_336, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x82378
ins_b10_032:   @ bank 10 entry 32; start 127, attack 0 fr, decay to 77.0 in 31 fr, sustain rate 0, release 10 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_337, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x82378
ins_b10_033:   @ bank 10 entry 33; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 6 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_338, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b10_034:   @ bank 10 entry 34; start 127, attack 0 fr, decay to 25.7 in 62 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_339, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b10_037:   @ bank 10 entry 37; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_340, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b10_038:   @ bank 10 entry 38; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_341, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_039:   @ bank 10 entry 39; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_342, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_040:   @ bank 10 entry 40; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_343, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_041:   @ bank 10 entry 41; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_344, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_042:   @ bank 10 entry 42; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_345, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_043:   @ bank 10 entry 43; start 127, attack 0 fr, decay to 25.7 in 62 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_346, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b10_044:   @ bank 10 entry 44; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_347, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_045:   @ bank 10 entry 45; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_348, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_046:   @ bank 10 entry 46; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_349, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_047:   @ bank 10 entry 47; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_350, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_048:   @ bank 10 entry 48; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_351, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_049:   @ bank 10 entry 49; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_352, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xB8000
ins_b10_050:   @ bank 10 entry 50; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_353, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_051:   @ bank 10 entry 51; start 127, attack 0 fr, decay to 12.8 in 18 fr, sustain rate 0, release 1 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_354, env_start=0x7F0000, sustain=0xCD40A, attack=0x600000, decay=0x690CE, sustain_rate=0x0, release=0xF6A90
ins_b10_052:   @ bank 10 entry 52; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_355, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b10_053:   @ bank 10 entry 53; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_356, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_054:   @ bank 10 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_357, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_055:   @ bank 10 entry 55; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_358, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b10_056:   @ bank 10 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_359, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_001:   @ bank 11 entry 1; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_360, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b11_003:   @ bank 11 entry 3; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 69
	ins_sample key=60, nointerp=0, pan=127, sample=smp_361, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b11_004:   @ bank 11 entry 4; start 127, attack 0 fr, decay to 25.7 in 62 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=57, nointerp=0, pan=127, sample=smp_324, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x82378
ins_b11_005:   @ bank 11 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 42 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_362, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x31548
ins_b11_006:   @ bank 11 entry 6; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 66
	ins_sample key=60, nointerp=0, pan=127, sample=smp_363, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_007:   @ bank 11 entry 7; start 0, attack 2 fr, decay to 102.6 in 8 fr, sustain rate 0, release 34 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_364, env_start=0x0, sustain=0x66A052, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b11_008:   @ bank 11 entry 8; start 127, attack 0 fr, decay to 64.1 in 7 fr, sustain rate 0, release 3 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_365, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x9D936, sustain_rate=0x0, release=0x18EA90
ins_b11_010:   @ bank 11 entry 10; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_366, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_011:   @ bank 11 entry 11; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_367, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_012:   @ bank 11 entry 12; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_368, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_013:   @ bank 11 entry 13; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_369, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_014:   @ bank 11 entry 14; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_370, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_016:   @ bank 11 entry 16; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_371, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_017:   @ bank 11 entry 17; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_372, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_018:   @ bank 11 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_373, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b11_021:   @ bank 11 entry 21; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_374, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b11_022:   @ bank 11 entry 22; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_375, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b11_023:   @ bank 11 entry 23; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 12 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_376, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xB8000
ins_b11_024:   @ bank 11 entry 24; start 127, attack 0 fr, decay to 89.8 in 2 fr, sustain rate 0, release 12 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_377, env_start=0x7F0000, sustain=0x59CC48, attack=0x600000, decay=0x1A433B, sustain_rate=0x0, release=0x82378
ins_b11_025:   @ bank 11 entry 25; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_378, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b11_032:   @ bank 11 entry 32; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=59, nointerp=0, pan=127, sample=smp_284, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b11_033:   @ bank 11 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=59, nointerp=0, pan=127, sample=smp_285, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b11_036:   @ bank 11 entry 36; start 127, attack 0 fr, decay to 77.0 in 16 fr, sustain rate 0, release 7 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_379, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b11_051:   @ bank 11 entry 51; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_380, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_053:   @ bank 11 entry 53; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 65
	ins_sample key=60, nointerp=0, pan=127, sample=smp_381, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_054:   @ bank 11 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_382, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_055:   @ bank 11 entry 55; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_383, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_056:   @ bank 11 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_384, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_057:   @ bank 11 entry 57; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_385, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_058:   @ bank 11 entry 58; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 5 fr; sample rate 13379 root 67
	ins_sample key=60, nointerp=0, pan=127, sample=smp_386, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x1E7FBA
ins_b11_059:   @ bank 11 entry 59; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_387, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b11_060:   @ bank 11 entry 60; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_388, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b11_061:   @ bank 11 entry 61; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_389, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b11_062:   @ bank 11 entry 62; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 2628 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_390, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b11_063:   @ bank 11 entry 63; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_391, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b11_064:   @ bank 11 entry 64; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 6 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_392, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x18EA90
ins_b12_001:   @ bank 12 entry 1; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_393, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_002:   @ bank 12 entry 2; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_394, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_003:   @ bank 12 entry 3; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_395, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_004:   @ bank 12 entry 4; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_396, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_005:   @ bank 12 entry 5; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_397, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_006:   @ bank 12 entry 6; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_398, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_007:   @ bank 12 entry 7; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_399, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_008:   @ bank 12 entry 8; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_400, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_009:   @ bank 12 entry 9; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_401, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_010:   @ bank 12 entry 10; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_402, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_011:   @ bank 12 entry 11; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_403, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_012:   @ bank 12 entry 12; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_404, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_013:   @ bank 12 entry 13; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_405, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_014:   @ bank 12 entry 14; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_406, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_015:   @ bank 12 entry 15; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_407, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_016:   @ bank 12 entry 16; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_408, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_017:   @ bank 12 entry 17; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_409, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_018:   @ bank 12 entry 18; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_410, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_019:   @ bank 12 entry 19; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_411, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_020:   @ bank 12 entry 20; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_412, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_021:   @ bank 12 entry 21; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_413, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_022:   @ bank 12 entry 22; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_414, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_023:   @ bank 12 entry 23; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_415, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_024:   @ bank 12 entry 24; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_416, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_025:   @ bank 12 entry 25; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_417, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_026:   @ bank 12 entry 26; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_418, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_027:   @ bank 12 entry 27; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_419, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_028:   @ bank 12 entry 28; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_420, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_029:   @ bank 12 entry 29; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_421, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_030:   @ bank 12 entry 30; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_422, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_031:   @ bank 12 entry 31; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_423, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_032:   @ bank 12 entry 32; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_424, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_033:   @ bank 12 entry 33; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_425, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_034:   @ bank 12 entry 34; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_426, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_035:   @ bank 12 entry 35; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_427, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_036:   @ bank 12 entry 36; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_428, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_037:   @ bank 12 entry 37; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_429, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_038:   @ bank 12 entry 38; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_430, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_039:   @ bank 12 entry 39; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_431, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_040:   @ bank 12 entry 40; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_432, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_041:   @ bank 12 entry 41; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_433, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_042:   @ bank 12 entry 42; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_434, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_043:   @ bank 12 entry 43; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_435, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_044:   @ bank 12 entry 44; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_436, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_045:   @ bank 12 entry 45; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_437, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_046:   @ bank 12 entry 46; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_438, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_047:   @ bank 12 entry 47; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_439, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_048:   @ bank 12 entry 48; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_440, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_049:   @ bank 12 entry 49; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_441, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_050:   @ bank 12 entry 50; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_442, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_051:   @ bank 12 entry 51; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_443, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_052:   @ bank 12 entry 52; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_444, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_053:   @ bank 12 entry 53; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_445, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_054:   @ bank 12 entry 54; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_446, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_055:   @ bank 12 entry 55; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_447, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_056:   @ bank 12 entry 56; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_448, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_057:   @ bank 12 entry 57; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_449, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_058:   @ bank 12 entry 58; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_450, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_059:   @ bank 12 entry 59; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_451, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_060:   @ bank 12 entry 60; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_452, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_061:   @ bank 12 entry 61; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_453, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_062:   @ bank 12 entry 62; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_454, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_063:   @ bank 12 entry 63; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_455, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_064:   @ bank 12 entry 64; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_456, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_065:   @ bank 12 entry 65; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_457, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_066:   @ bank 12 entry 66; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_458, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_067:   @ bank 12 entry 67; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_459, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_068:   @ bank 12 entry 68; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_460, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_069:   @ bank 12 entry 69; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_461, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_070:   @ bank 12 entry 70; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_462, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_071:   @ bank 12 entry 71; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_463, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_072:   @ bank 12 entry 72; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_464, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_073:   @ bank 12 entry 73; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_465, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_074:   @ bank 12 entry 74; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_466, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_075:   @ bank 12 entry 75; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_467, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_076:   @ bank 12 entry 76; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_468, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_077:   @ bank 12 entry 77; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_469, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_078:   @ bank 12 entry 78; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_470, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_079:   @ bank 12 entry 79; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_471, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_080:   @ bank 12 entry 80; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_472, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_081:   @ bank 12 entry 81; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_473, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_082:   @ bank 12 entry 82; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_474, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_083:   @ bank 12 entry 83; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_475, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_084:   @ bank 12 entry 84; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_476, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_085:   @ bank 12 entry 85; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_477, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_086:   @ bank 12 entry 86; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_478, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_087:   @ bank 12 entry 87; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_479, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_088:   @ bank 12 entry 88; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_480, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_089:   @ bank 12 entry 89; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_481, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_090:   @ bank 12 entry 90; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_482, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_091:   @ bank 12 entry 91; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_483, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_092:   @ bank 12 entry 92; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_484, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_093:   @ bank 12 entry 93; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_485, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_094:   @ bank 12 entry 94; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_486, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_095:   @ bank 12 entry 95; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_487, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_096:   @ bank 12 entry 96; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_488, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_097:   @ bank 12 entry 97; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_489, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b12_098:   @ bank 12 entry 98; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_490, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_001:   @ bank 13 entry 1; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_491, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_002:   @ bank 13 entry 2; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_492, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_003:   @ bank 13 entry 3; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_493, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_004:   @ bank 13 entry 4; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 8 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_494, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_005:   @ bank 13 entry 5; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_495, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_006:   @ bank 13 entry 6; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_496, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_007:   @ bank 13 entry 7; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_497, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_008:   @ bank 13 entry 8; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_498, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_009:   @ bank 13 entry 9; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_499, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_010:   @ bank 13 entry 10; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_500, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b13_011:   @ bank 13 entry 11; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_501, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_012:   @ bank 13 entry 12; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_502, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b13_013:   @ bank 13 entry 13; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_503, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_014:   @ bank 13 entry 14; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_504, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_015:   @ bank 13 entry 15; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_505, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_016:   @ bank 13 entry 16; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_506, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_017:   @ bank 13 entry 17; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_507, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_018:   @ bank 13 entry 18; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_508, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_019:   @ bank 13 entry 19; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_509, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_020:   @ bank 13 entry 20; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_510, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_021:   @ bank 13 entry 21; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 44100 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_511, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_022:   @ bank 13 entry 22; start 0, attack 2 fr, decay to 64.1 in 39 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_512, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b13_023:   @ bank 13 entry 23; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 21 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_513, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b13_024:   @ bank 13 entry 24; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_514, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_025:   @ bank 13 entry 25; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_515, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_026:   @ bank 13 entry 26; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_516, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_027:   @ bank 13 entry 27; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_517, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_028:   @ bank 13 entry 28; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_518, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_029:   @ bank 13 entry 29; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_519, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_030:   @ bank 13 entry 30; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_520, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_031:   @ bank 13 entry 31; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_521, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_032:   @ bank 13 entry 32; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_522, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_033:   @ bank 13 entry 33; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_523, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_034:   @ bank 13 entry 34; start 127, attack 0 fr, decay to 89.8 in 12 fr, sustain rate 0, release 17 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_524, env_start=0x7F0000, sustain=0x59CC48, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_035:   @ bank 13 entry 35; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_525, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_036:   @ bank 13 entry 36; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_526, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_037:   @ bank 13 entry 37; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_527, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_038:   @ bank 13 entry 38; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_528, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_039:   @ bank 13 entry 39; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 21 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_529, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b13_040:   @ bank 13 entry 40; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_530, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_041:   @ bank 13 entry 41; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_531, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_042:   @ bank 13 entry 42; start 0, attack 2 fr, decay to 38.5 in 39 fr, sustain rate 0, release 5 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_532, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x24C48, sustain_rate=0x0, release=0x82378
ins_b13_043:   @ bank 13 entry 43; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 21 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_533, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b13_044:   @ bank 13 entry 44; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_534, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_045:   @ bank 13 entry 45; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_535, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b13_046:   @ bank 13 entry 46; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_536, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_047:   @ bank 13 entry 47; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_537, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_048:   @ bank 13 entry 48; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_538, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_049:   @ bank 13 entry 49; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 4 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_539, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_050:   @ bank 13 entry 50; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_540, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b13_051:   @ bank 13 entry 51; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 13 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_541, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b13_052:   @ bank 13 entry 52; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_542, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_053:   @ bank 13 entry 53; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_543, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_054:   @ bank 13 entry 54; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_544, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_055:   @ bank 13 entry 55; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_545, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_056:   @ bank 13 entry 56; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_546, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_057:   @ bank 13 entry 57; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_547, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_058:   @ bank 13 entry 58; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_548, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_059:   @ bank 13 entry 59; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_549, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_060:   @ bank 13 entry 60; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_550, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_061:   @ bank 13 entry 61; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 8 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_551, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_062:   @ bank 13 entry 62; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_552, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_063:   @ bank 13 entry 63; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_553, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_064:   @ bank 13 entry 64; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_554, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_065:   @ bank 13 entry 65; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_555, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_066:   @ bank 13 entry 66; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_556, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_067:   @ bank 13 entry 67; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_557, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_068:   @ bank 13 entry 68; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_558, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_069:   @ bank 13 entry 69; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_559, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_070:   @ bank 13 entry 70; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_560, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_071:   @ bank 13 entry 71; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_561, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_072:   @ bank 13 entry 72; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_562, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_073:   @ bank 13 entry 73; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_563, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b13_074:   @ bank 13 entry 74; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_564, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_075:   @ bank 13 entry 75; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_565, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b13_076:   @ bank 13 entry 76; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_566, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_077:   @ bank 13 entry 77; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_567, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b13_078:   @ bank 13 entry 78; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_568, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_079:   @ bank 13 entry 79; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_569, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_080:   @ bank 13 entry 80; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_570, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_081:   @ bank 13 entry 81; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_571, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b13_082:   @ bank 13 entry 82; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_572, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b13_083:   @ bank 13 entry 83; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 7884 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_573, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_001:   @ bank 14 entry 1; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_574, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_002:   @ bank 14 entry 2; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_575, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_003:   @ bank 14 entry 3; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_576, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_004:   @ bank 14 entry 4; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 5 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_577, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_005:   @ bank 14 entry 5; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_578, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_006:   @ bank 14 entry 6; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_579, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_007:   @ bank 14 entry 7; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_580, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_008:   @ bank 14 entry 8; start 0, attack 2 fr, decay to 25.7 in 31 fr, sustain rate 0, release 4 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_581, env_start=0x0, sustain=0x19A814, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_009:   @ bank 14 entry 9; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_582, env_start=0x0, sustain=0x267C1F, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_010:   @ bank 14 entry 10; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 5 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_583, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_011:   @ bank 14 entry 11; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_584, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_012:   @ bank 14 entry 12; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_585, env_start=0x0, sustain=0x402433, attack=0x4D9364, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_013:   @ bank 14 entry 13; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_586, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_014:   @ bank 14 entry 14; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_587, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_015:   @ bank 14 entry 15; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_588, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_016:   @ bank 14 entry 16; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_589, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_017:   @ bank 14 entry 17; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 5 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_590, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_018:   @ bank 14 entry 18; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_591, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_019:   @ bank 14 entry 19; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_592, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_020:   @ bank 14 entry 20; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 5 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_593, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_021:   @ bank 14 entry 21; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_594, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_022:   @ bank 14 entry 22; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_595, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_023:   @ bank 14 entry 23; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_596, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_024:   @ bank 14 entry 24; start 0, attack 2 fr, decay to 51.3 in 231 fr, sustain rate 0, release 10 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_597, env_start=0x0, sustain=0x335029, attack=0x5745D1, decay=0x540A, sustain_rate=0x0, release=0x55552
ins_b14_025:   @ bank 14 entry 25; start 0, attack 2 fr, decay to 51.3 in 231 fr, sustain rate 0, release 10 fr; sample rate 10512 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_598, env_start=0x0, sustain=0x335029, attack=0x4D9364, decay=0x540A, sustain_rate=0x0, release=0x55552
ins_b14_026:   @ bank 14 entry 26; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_599, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_027:   @ bank 14 entry 27; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_600, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_028:   @ bank 14 entry 28; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_601, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_029:   @ bank 14 entry 29; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_602, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_030:   @ bank 14 entry 30; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_603, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_031:   @ bank 14 entry 31; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_604, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_032:   @ bank 14 entry 32; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_605, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_033:   @ bank 14 entry 33; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_606, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_034:   @ bank 14 entry 34; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_607, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_035:   @ bank 14 entry 35; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_608, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_036:   @ bank 14 entry 36; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_609, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_037:   @ bank 14 entry 37; start 0, attack 2 fr, decay to 38.5 in 54 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_610, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b14_038:   @ bank 14 entry 38; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_611, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_039:   @ bank 14 entry 39; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_612, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_040:   @ bank 14 entry 40; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_613, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_041:   @ bank 14 entry 41; start 0, attack 2 fr, decay to 38.5 in 27 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_614, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_042:   @ bank 14 entry 42; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_615, env_start=0x0, sustain=0x402433, attack=0x5C1F07, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_043:   @ bank 14 entry 43; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 8 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_616, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_044:   @ bank 14 entry 44; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_617, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_045:   @ bank 14 entry 45; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_618, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_046:   @ bank 14 entry 46; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_619, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_047:   @ bank 14 entry 47; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_620, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_048:   @ bank 14 entry 48; start 0, attack 2 fr, decay to 38.5 in 54 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_621, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x1A433, sustain_rate=0x0, release=0x31548
ins_b14_049:   @ bank 14 entry 49; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_622, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_050:   @ bank 14 entry 50; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_623, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_051:   @ bank 14 entry 51; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_624, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_052:   @ bank 14 entry 52; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_625, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_053:   @ bank 14 entry 53; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_626, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_054:   @ bank 14 entry 54; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_627, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_055:   @ bank 14 entry 55; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 4 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_628, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_056:   @ bank 14 entry 56; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_629, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_057:   @ bank 14 entry 57; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_630, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_058:   @ bank 14 entry 58; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 5 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_631, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x82378
ins_b14_059:   @ bank 14 entry 59; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_632, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_060:   @ bank 14 entry 60; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_633, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_061:   @ bank 14 entry 61; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_634, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_062:   @ bank 14 entry 62; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_635, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_063:   @ bank 14 entry 63; start 0, attack 2 fr, decay to 64.1 in 20 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_636, env_start=0x0, sustain=0x402433, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_064:   @ bank 14 entry 64; start 0, attack 2 fr, decay to 38.5 in 68 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_637, env_start=0x0, sustain=0x267C1F, attack=0x5745D1, decay=0x15029, sustain_rate=0x0, release=0x31548
ins_b14_065:   @ bank 14 entry 65; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_638, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_066:   @ bank 14 entry 66; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_639, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_067:   @ bank 14 entry 67; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_640, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_068:   @ bank 14 entry 68; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_641, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_069:   @ bank 14 entry 69; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_642, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_070:   @ bank 14 entry 70; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_643, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_071:   @ bank 14 entry 71; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 13 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_644, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x31548
ins_b14_072:   @ bank 14 entry 72; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_645, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_073:   @ bank 14 entry 73; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_646, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_074:   @ bank 14 entry 74; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_647, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_075:   @ bank 14 entry 75; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 6 fr; sample rate 3200 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_648, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xB8000
ins_b14_076:   @ bank 14 entry 76; start 0, attack 2 fr, decay to 25.7 in 21 fr, sustain rate 0, release 4 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_649, env_start=0x0, sustain=0x19A814, attack=0x4D9364, decay=0x4EC9B, sustain_rate=0x0, release=0x82378
ins_b14_077:   @ bank 14 entry 77; start 0, attack 2 fr, decay to 102.6 in 8 fr, sustain rate 0, release 20 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_650, env_start=0x0, sustain=0x66A052, attack=0x5745D1, decay=0x34867, sustain_rate=0x0, release=0x55552
ins_b14_078:   @ bank 14 entry 78; start 0, attack 2 fr, decay to 12.8 in 70 fr, sustain rate 0, release 3 fr; sample rate 5734 root 60
	ins_sample key=60, nointerp=0, pan=127, sample=smp_651, env_start=0x0, sustain=0xCD40A, attack=0x5745D1, decay=0x1A433, sustain_rate=0x0, release=0x55552
ins_b15_001:   @ bank 15 entry 1; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_652, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_002:   @ bank 15 entry 2; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_653, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_003:   @ bank 15 entry 3; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_654, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_004:   @ bank 15 entry 4; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_655, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_005:   @ bank 15 entry 5; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_656, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_006:   @ bank 15 entry 6; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_657, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b15_007:   @ bank 15 entry 7; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 79
	ins_sample key=60, nointerp=0, pan=127, sample=smp_658, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_008:   @ bank 15 entry 8; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_659, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_009:   @ bank 15 entry 9; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 5 fr; sample rate 13379 root 79
	ins_sample key=60, nointerp=0, pan=127, sample=smp_660, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b15_010:   @ bank 15 entry 10; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_661, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_011:   @ bank 15 entry 11; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_662, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_012:   @ bank 15 entry 12; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_663, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_013:   @ bank 15 entry 13; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_664, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_014:   @ bank 15 entry 14; start 127, attack 0 fr, decay to 38.5 in 54 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_665, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0xF6A90
ins_b15_015:   @ bank 15 entry 15; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_666, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_016:   @ bank 15 entry 16; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_667, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_017:   @ bank 15 entry 17; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_668, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_018:   @ bank 15 entry 18; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_669, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_019:   @ bank 15 entry 19; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_670, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_020:   @ bank 15 entry 20; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_671, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_021:   @ bank 15 entry 21; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_672, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_022:   @ bank 15 entry 22; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_673, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_024:   @ bank 15 entry 24; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_674, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_025:   @ bank 15 entry 25; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_675, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_026:   @ bank 15 entry 26; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_676, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_027:   @ bank 15 entry 27; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_677, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_028:   @ bank 15 entry 28; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_678, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_029:   @ bank 15 entry 29; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_679, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_030:   @ bank 15 entry 30; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 5 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_680, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_031:   @ bank 15 entry 31; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_681, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_032:   @ bank 15 entry 32; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_682, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_033:   @ bank 15 entry 33; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_683, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_034:   @ bank 15 entry 34; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_684, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_036:   @ bank 15 entry 36; start 127, attack 0 fr, decay to 25.7 in 31 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_685, env_start=0x7F0000, sustain=0x19A814, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_037:   @ bank 15 entry 37; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_686, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_038:   @ bank 15 entry 38; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_687, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_039:   @ bank 15 entry 39; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_688, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_040:   @ bank 15 entry 40; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_689, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_041:   @ bank 15 entry 41; start 127, attack 0 fr, decay to 38.5 in 27 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_690, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0xF6A90
ins_b15_042:   @ bank 15 entry 42; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 9 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_691, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0xF6A90
ins_b15_043:   @ bank 15 entry 43; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_692, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_044:   @ bank 15 entry 44; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_693, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_045:   @ bank 15 entry 45; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_694, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_046:   @ bank 15 entry 46; start 127, attack 0 fr, decay to 64.1 in 22 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_695, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x2F45D, sustain_rate=0x0, release=0x13E350
ins_b15_047:   @ bank 15 entry 47; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_696, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_048:   @ bank 15 entry 48; start 127, attack 0 fr, decay to 77.0 in 31 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_697, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b15_049:   @ bank 15 entry 49; start 127, attack 0 fr, decay to 77.0 in 31 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_698, env_start=0x7F0000, sustain=0x4CF83E, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b15_050:   @ bank 15 entry 50; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_699, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b15_051:   @ bank 15 entry 51; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_700, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b15_052:   @ bank 15 entry 52; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_701, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_053:   @ bank 15 entry 53; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_702, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350
ins_b15_054:   @ bank 15 entry 54; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_703, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_055:   @ bank 15 entry 55; start 127, attack 0 fr, decay to 51.3 in 77 fr, sustain rate 0, release 3 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_704, env_start=0x7F0000, sustain=0x335029, attack=0x600000, decay=0xFC1F, sustain_rate=0x0, release=0x13E350
ins_b15_056:   @ bank 15 entry 56; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_705, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_057:   @ bank 15 entry 57; start 127, attack 0 fr, decay to 64.1 in 20 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_706, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x34867, sustain_rate=0x0, release=0x13E350
ins_b15_058:   @ bank 15 entry 58; start 127, attack 0 fr, decay to 127.0 in 0 fr, sustain rate 0, release 7 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_707, env_start=0x7F0000, sustain=0x7F0000, attack=0x600000, decay=0x208000, sustain_rate=0x0, release=0x13E350
ins_b15_059:   @ bank 15 entry 59; start 127, attack 0 fr, decay to 38.5 in 90 fr, sustain rate 0, release 2 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_708, env_start=0x7F0000, sustain=0x267C1F, attack=0x600000, decay=0xFC1F, sustain_rate=0x0, release=0x13E350
ins_b15_060:   @ bank 15 entry 60; start 127, attack 0 fr, decay to 64.1 in 28 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_709, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x24C48, sustain_rate=0x0, release=0x13E350
ins_b15_061:   @ bank 15 entry 61; start 127, attack 0 fr, decay to 64.1 in 39 fr, sustain rate 0, release 4 fr; sample rate 13379 root 72
	ins_sample key=60, nointerp=0, pan=127, sample=smp_710, env_start=0x7F0000, sustain=0x402433, attack=0x600000, decay=0x1A433, sustain_rate=0x0, release=0x13E350

@ ---- banks: Instrument *[n]; bank_01..03 are program banks, the others are drum maps / split tables ----
bank_00:   @ 22 entries; split table (S instruments)
	.word ins_b00_000              @ 0
	.word ins_b00_001              @ 1
	.word ins_b00_002              @ 2
	.word ins_b00_003              @ 3
	.word ins_b00_004              @ 4
	.word ins_b00_005              @ 5
	.word ins_b00_006              @ 6
	.word 0                        @ 7
	.word 0                        @ 8
	.word 0                        @ 9
	.word ins_b00_010              @ 10
	.word ins_b00_011              @ 11
	.word ins_b00_012              @ 12
	.word ins_b00_013              @ 13
	.word ins_b00_014              @ 14
	.word ins_b00_015              @ 15
	.word ins_b00_016              @ 16
	.word ins_b00_017              @ 17
	.word 0                        @ 18
	.word 0                        @ 19
	.word ins_b00_020              @ 20
	.word ins_b00_021              @ 21
bank_01:   @ 128 entries; program bank (221 songs)
	.word ins_b01_000              @ 0
	.word ins_b01_001              @ 1
	.word ins_b01_002              @ 2
	.word ins_b01_003              @ 3
	.word ins_b01_004              @ 4
	.word ins_b01_005              @ 5
	.word ins_b01_006              @ 6
	.word ins_b01_007              @ 7
	.word ins_b01_008              @ 8
	.word ins_b01_009              @ 9
	.word ins_b01_010              @ 10
	.word ins_b01_011              @ 11
	.word ins_b01_012              @ 12
	.word ins_b01_013              @ 13
	.word ins_b01_014              @ 14
	.word ins_b01_015              @ 15
	.word ins_b01_016              @ 16
	.word ins_b01_017              @ 17
	.word ins_b01_018              @ 18
	.word ins_b01_019              @ 19
	.word ins_b01_020              @ 20
	.word ins_b01_021              @ 21
	.word ins_b01_022              @ 22
	.word ins_b01_023              @ 23
	.word 0                        @ 24
	.word 0                        @ 25
	.word 0                        @ 26
	.word 0                        @ 27
	.word 0                        @ 28
	.word 0                        @ 29
	.word ins_b01_030              @ 30
	.word ins_b01_031              @ 31
	.word ins_b01_032              @ 32
	.word ins_b01_033              @ 33
	.word ins_b01_034              @ 34
	.word ins_b01_035              @ 35
	.word ins_b01_036              @ 36
	.word ins_b01_037              @ 37
	.word ins_b01_038              @ 38
	.word ins_b01_039              @ 39
	.word ins_b01_040              @ 40
	.word ins_b01_041              @ 41
	.word ins_b01_042              @ 42
	.word ins_b01_043              @ 43
	.word ins_b01_044              @ 44
	.word ins_b01_045              @ 45
	.word 0                        @ 46
	.word 0                        @ 47
	.word 0                        @ 48
	.word 0                        @ 49
	.word ins_b01_050              @ 50
	.word ins_b01_051              @ 51
	.word 0                        @ 52
	.word 0                        @ 53
	.word 0                        @ 54
	.word 0                        @ 55
	.word 0                        @ 56
	.word 0                        @ 57
	.word 0                        @ 58
	.word 0                        @ 59
	.word 0                        @ 60
	.word 0                        @ 61
	.word 0                        @ 62
	.word ins_b01_063              @ 63
	.word 0                        @ 64
	.word 0                        @ 65
	.word 0                        @ 66
	.word 0                        @ 67
	.word 0                        @ 68
	.word 0                        @ 69
	.word 0                        @ 70
	.word 0                        @ 71
	.word 0                        @ 72
	.word 0                        @ 73
	.word 0                        @ 74
	.word 0                        @ 75
	.word 0                        @ 76
	.word 0                        @ 77
	.word 0                        @ 78
	.word 0                        @ 79
	.word 0                        @ 80
	.word 0                        @ 81
	.word 0                        @ 82
	.word 0                        @ 83
	.word 0                        @ 84
	.word 0                        @ 85
	.word 0                        @ 86
	.word 0                        @ 87
	.word 0                        @ 88
	.word 0                        @ 89
	.word 0                        @ 90
	.word 0                        @ 91
	.word 0                        @ 92
	.word 0                        @ 93
	.word 0                        @ 94
	.word 0                        @ 95
	.word 0                        @ 96
	.word 0                        @ 97
	.word ins_b01_098              @ 98
	.word 0                        @ 99
	.word 0                        @ 100
	.word 0                        @ 101
	.word ins_b01_102              @ 102
	.word ins_b01_103              @ 103
	.word ins_b01_104              @ 104
	.word 0                        @ 105
	.word 0                        @ 106
	.word ins_b01_107              @ 107
	.word ins_b01_108              @ 108
	.word ins_b01_109              @ 109
	.word ins_b01_110              @ 110
	.word ins_b01_111              @ 111
	.word ins_b01_112              @ 112
	.word ins_b01_113              @ 113
	.word ins_b01_114              @ 114
	.word ins_b01_115              @ 115
	.word ins_b01_116              @ 116
	.word ins_b01_117              @ 117
	.word 0                        @ 118
	.word 0                        @ 119
	.word ins_b01_120              @ 120
	.word ins_b01_121              @ 121
	.word ins_b01_122              @ 122
	.word ins_b01_123              @ 123
	.word ins_b01_124              @ 124
	.word ins_b01_125              @ 125
	.word ins_b01_126              @ 126
	.word ins_b01_127              @ 127
bank_02:   @ 127 entries; program bank (1 song)
	.word 0                        @ 0
	.word 0                        @ 1
	.word 0                        @ 2
	.word 0                        @ 3
	.word 0                        @ 4
	.word 0                        @ 5
	.word 0                        @ 6
	.word 0                        @ 7
	.word 0                        @ 8
	.word 0                        @ 9
	.word 0                        @ 10
	.word 0                        @ 11
	.word 0                        @ 12
	.word 0                        @ 13
	.word 0                        @ 14
	.word 0                        @ 15
	.word 0                        @ 16
	.word 0                        @ 17
	.word 0                        @ 18
	.word 0                        @ 19
	.word 0                        @ 20
	.word 0                        @ 21
	.word 0                        @ 22
	.word 0                        @ 23
	.word 0                        @ 24
	.word 0                        @ 25
	.word 0                        @ 26
	.word 0                        @ 27
	.word 0                        @ 28
	.word 0                        @ 29
	.word 0                        @ 30
	.word 0                        @ 31
	.word 0                        @ 32
	.word 0                        @ 33
	.word 0                        @ 34
	.word 0                        @ 35
	.word 0                        @ 36
	.word 0                        @ 37
	.word 0                        @ 38
	.word 0                        @ 39
	.word 0                        @ 40
	.word 0                        @ 41
	.word 0                        @ 42
	.word 0                        @ 43
	.word 0                        @ 44
	.word 0                        @ 45
	.word 0                        @ 46
	.word 0                        @ 47
	.word 0                        @ 48
	.word 0                        @ 49
	.word ins_b02_050              @ 50
	.word ins_b02_051              @ 51
	.word ins_b02_052              @ 52
	.word ins_b02_053              @ 53
	.word ins_b02_054              @ 54
	.word ins_b02_055              @ 55
	.word ins_b02_056              @ 56
	.word ins_b02_057              @ 57
	.word ins_b02_058              @ 58
	.word ins_b02_059              @ 59
	.word ins_b02_060              @ 60
	.word 0                        @ 61
	.word 0                        @ 62
	.word 0                        @ 63
	.word 0                        @ 64
	.word 0                        @ 65
	.word 0                        @ 66
	.word 0                        @ 67
	.word 0                        @ 68
	.word 0                        @ 69
	.word 0                        @ 70
	.word 0                        @ 71
	.word 0                        @ 72
	.word 0                        @ 73
	.word 0                        @ 74
	.word 0                        @ 75
	.word 0                        @ 76
	.word 0                        @ 77
	.word 0                        @ 78
	.word 0                        @ 79
	.word 0                        @ 80
	.word 0                        @ 81
	.word 0                        @ 82
	.word 0                        @ 83
	.word 0                        @ 84
	.word 0                        @ 85
	.word 0                        @ 86
	.word 0                        @ 87
	.word 0                        @ 88
	.word 0                        @ 89
	.word 0                        @ 90
	.word 0                        @ 91
	.word 0                        @ 92
	.word 0                        @ 93
	.word 0                        @ 94
	.word 0                        @ 95
	.word 0                        @ 96
	.word 0                        @ 97
	.word 0                        @ 98
	.word 0                        @ 99
	.word 0                        @ 100
	.word 0                        @ 101
	.word 0                        @ 102
	.word 0                        @ 103
	.word 0                        @ 104
	.word 0                        @ 105
	.word 0                        @ 106
	.word 0                        @ 107
	.word 0                        @ 108
	.word 0                        @ 109
	.word 0                        @ 110
	.word 0                        @ 111
	.word 0                        @ 112
	.word 0                        @ 113
	.word 0                        @ 114
	.word 0                        @ 115
	.word 0                        @ 116
	.word 0                        @ 117
	.word 0                        @ 118
	.word 0                        @ 119
	.word 0                        @ 120
	.word 0                        @ 121
	.word 0                        @ 122
	.word 0                        @ 123
	.word 0                        @ 124
	.word 0                        @ 125
	.word ins_b02_126              @ 126
bank_03:   @ 128 entries; program bank (1120 songs and SFX)
	.word ins_b03_000              @ 0
	.word ins_b03_001              @ 1
	.word ins_b03_002              @ 2
	.word 0                        @ 3
	.word ins_b03_004              @ 4
	.word ins_b03_005              @ 5
	.word 0                        @ 6
	.word ins_b03_007              @ 7
	.word ins_b03_008              @ 8
	.word ins_b03_009              @ 9
	.word ins_b03_010              @ 10
	.word ins_b03_011              @ 11
	.word ins_b03_012              @ 12
	.word ins_b03_013              @ 13
	.word ins_b03_014              @ 14
	.word ins_b03_015              @ 15
	.word ins_b03_016              @ 16
	.word ins_b03_017              @ 17
	.word ins_b03_018              @ 18
	.word ins_b03_019              @ 19
	.word ins_b03_020              @ 20
	.word ins_b03_021              @ 21
	.word 0                        @ 22
	.word ins_b03_023              @ 23
	.word ins_b03_024              @ 24
	.word 0                        @ 25
	.word ins_b03_026              @ 26
	.word ins_b03_027              @ 27
	.word ins_b03_028              @ 28
	.word ins_b03_029              @ 29
	.word 0                        @ 30
	.word ins_b03_031              @ 31
	.word ins_b03_032              @ 32
	.word 0                        @ 33
	.word 0                        @ 34
	.word ins_b03_035              @ 35
	.word ins_b03_036              @ 36
	.word ins_b03_037              @ 37
	.word 0                        @ 38
	.word 0                        @ 39
	.word 0                        @ 40
	.word 0                        @ 41
	.word 0                        @ 42
	.word 0                        @ 43
	.word 0                        @ 44
	.word 0                        @ 45
	.word 0                        @ 46
	.word ins_b03_047              @ 47
	.word ins_b03_048              @ 48
	.word ins_b03_049              @ 49
	.word 0                        @ 50
	.word 0                        @ 51
	.word 0                        @ 52
	.word 0                        @ 53
	.word 0                        @ 54
	.word ins_b03_055              @ 55
	.word 0                        @ 56
	.word 0                        @ 57
	.word 0                        @ 58
	.word 0                        @ 59
	.word ins_b03_060              @ 60
	.word ins_b03_061              @ 61
	.word ins_b03_062              @ 62
	.word ins_b03_063              @ 63
	.word 0                        @ 64
	.word 0                        @ 65
	.word 0                        @ 66
	.word 0                        @ 67
	.word 0                        @ 68
	.word 0                        @ 69
	.word 0                        @ 70
	.word ins_b03_071              @ 71
	.word ins_b03_072              @ 72
	.word 0                        @ 73
	.word ins_b03_074              @ 74
	.word 0                        @ 75
	.word 0                        @ 76
	.word 0                        @ 77
	.word 0                        @ 78
	.word ins_b03_079              @ 79
	.word ins_b03_080              @ 80
	.word ins_b03_081              @ 81
	.word ins_b03_082              @ 82
	.word ins_b03_083              @ 83
	.word ins_b03_084              @ 84
	.word ins_b03_085              @ 85
	.word ins_b03_086              @ 86
	.word ins_b03_087              @ 87
	.word 0                        @ 88
	.word 0                        @ 89
	.word ins_b03_090              @ 90
	.word 0                        @ 91
	.word 0                        @ 92
	.word ins_b03_093              @ 93
	.word 0                        @ 94
	.word ins_b03_095              @ 95
	.word 0                        @ 96
	.word 0                        @ 97
	.word ins_b03_098              @ 98
	.word ins_b03_099              @ 99
	.word 0                        @ 100
	.word ins_b03_101              @ 101
	.word 0                        @ 102
	.word ins_b03_103              @ 103
	.word ins_b03_104              @ 104
	.word ins_b03_105              @ 105
	.word ins_b03_106              @ 106
	.word ins_b03_107              @ 107
	.word 0                        @ 108
	.word ins_b03_109              @ 109
	.word ins_b03_110              @ 110
	.word ins_b03_111              @ 111
	.word ins_b03_112              @ 112
	.word ins_b03_113              @ 113
	.word ins_b03_114              @ 114
	.word ins_b03_115              @ 115
	.word ins_b03_116              @ 116
	.word ins_b03_117              @ 117
	.word ins_b03_118              @ 118
	.word ins_b03_119              @ 119
	.word ins_b03_120              @ 120
	.word ins_b03_121              @ 121
	.word ins_b03_122              @ 122
	.word ins_b03_123              @ 123
	.word ins_b03_124              @ 124
	.word ins_b03_125              @ 125
	.word ins_b03_126              @ 126
	.word ins_b03_127              @ 127
bank_04:   @ 22 entries; drum map (R instruments)
	.word ins_b04_000              @ 0
	.word ins_b04_001              @ 1
	.word ins_b04_002              @ 2
	.word ins_b04_003              @ 3
	.word ins_b04_004              @ 4
	.word ins_b04_005              @ 5
	.word ins_b04_006              @ 6
	.word ins_b04_007              @ 7
	.word ins_b04_008              @ 8
	.word ins_b04_009              @ 9
	.word 0                        @ 10
	.word ins_b04_011              @ 11
	.word ins_b04_012              @ 12
	.word ins_b04_013              @ 13
	.word ins_b04_014              @ 14
	.word ins_b04_015              @ 15
	.word ins_b04_016              @ 16
	.word ins_b04_017              @ 17
	.word ins_b04_018              @ 18
	.word ins_b04_019              @ 19
	.word ins_b04_020              @ 20
	.word ins_b04_021              @ 21
bank_05:   @ 61 entries; drum map (R instruments)
	.word ins_b05_000              @ 0
	.word ins_b05_001              @ 1
	.word ins_b05_002              @ 2
	.word ins_b05_003              @ 3
	.word ins_b05_004              @ 4
	.word ins_b05_005              @ 5
	.word 0                        @ 6
	.word ins_b05_007              @ 7
	.word 0                        @ 8
	.word ins_b05_009              @ 9
	.word 0                        @ 10
	.word ins_b05_011              @ 11
	.word ins_b05_012              @ 12
	.word ins_b05_013              @ 13
	.word ins_b05_014              @ 14
	.word 0                        @ 15
	.word 0                        @ 16
	.word 0                        @ 17
	.word ins_b05_018              @ 18
	.word 0                        @ 19
	.word ins_b05_020              @ 20
	.word 0                        @ 21
	.word ins_b05_022              @ 22
	.word 0                        @ 23
	.word ins_b05_024              @ 24
	.word ins_b05_025              @ 25
	.word 0                        @ 26
	.word ins_b05_027              @ 27
	.word ins_b05_028              @ 28
	.word 0                        @ 29
	.word 0                        @ 30
	.word 0                        @ 31
	.word ins_b05_032              @ 32
	.word ins_b05_033              @ 33
	.word ins_b05_034              @ 34
	.word ins_b05_035              @ 35
	.word ins_b05_036              @ 36
	.word 0                        @ 37
	.word ins_b05_038              @ 38
	.word 0                        @ 39
	.word 0                        @ 40
	.word 0                        @ 41
	.word 0                        @ 42
	.word 0                        @ 43
	.word 0                        @ 44
	.word 0                        @ 45
	.word 0                        @ 46
	.word 0                        @ 47
	.word 0                        @ 48
	.word 0                        @ 49
	.word 0                        @ 50
	.word 0                        @ 51
	.word 0                        @ 52
	.word ins_b05_053              @ 53
	.word ins_b05_054              @ 54
	.word ins_b05_055              @ 55
	.word ins_b05_056              @ 56
	.word ins_b05_057              @ 57
	.word 0                        @ 58
	.word ins_b05_059              @ 59
	.word ins_b05_060              @ 60
bank_06:   @ 61 entries; drum map (R instruments)
	.word ins_b06_000              @ 0
	.word ins_b06_001              @ 1
	.word ins_b06_002              @ 2
	.word 0                        @ 3
	.word ins_b06_004              @ 4
	.word ins_b06_005              @ 5
	.word ins_b06_006              @ 6
	.word ins_b06_007              @ 7
	.word ins_b06_008              @ 8
	.word ins_b06_009              @ 9
	.word ins_b06_010              @ 10
	.word ins_b06_011              @ 11
	.word ins_b06_012              @ 12
	.word ins_b06_013              @ 13
	.word ins_b06_014              @ 14
	.word ins_b06_015              @ 15
	.word ins_b06_016              @ 16
	.word ins_b06_017              @ 17
	.word ins_b06_018              @ 18
	.word ins_b06_019              @ 19
	.word ins_b06_020              @ 20
	.word ins_b06_021              @ 21
	.word ins_b06_022              @ 22
	.word 0                        @ 23
	.word ins_b06_024              @ 24
	.word ins_b06_025              @ 25
	.word ins_b06_026              @ 26
	.word ins_b06_027              @ 27
	.word ins_b06_028              @ 28
	.word ins_b06_029              @ 29
	.word ins_b06_030              @ 30
	.word ins_b06_031              @ 31
	.word ins_b06_032              @ 32
	.word ins_b06_033              @ 33
	.word ins_b06_034              @ 34
	.word ins_b06_035              @ 35
	.word ins_b06_036              @ 36
	.word ins_b06_037              @ 37
	.word ins_b06_038              @ 38
	.word ins_b06_039              @ 39
	.word ins_b06_040              @ 40
	.word ins_b06_041              @ 41
	.word 0                        @ 42
	.word ins_b06_043              @ 43
	.word ins_b06_044              @ 44
	.word ins_b06_045              @ 45
	.word ins_b06_046              @ 46
	.word ins_b06_047              @ 47
	.word ins_b06_048              @ 48
	.word ins_b06_049              @ 49
	.word ins_b06_050              @ 50
	.word ins_b06_051              @ 51
	.word ins_b06_052              @ 52
	.word ins_b06_053              @ 53
	.word ins_b06_054              @ 54
	.word ins_b06_055              @ 55
	.word ins_b06_056              @ 56
	.word ins_b06_057              @ 57
	.word ins_b06_058              @ 58
	.word ins_b06_059              @ 59
	.word ins_b06_060              @ 60
bank_07:   @ 62 entries; drum map (R instruments)
	.word 0                        @ 0
	.word 0                        @ 1
	.word 0                        @ 2
	.word 0                        @ 3
	.word 0                        @ 4
	.word 0                        @ 5
	.word 0                        @ 6
	.word 0                        @ 7
	.word 0                        @ 8
	.word 0                        @ 9
	.word 0                        @ 10
	.word 0                        @ 11
	.word 0                        @ 12
	.word 0                        @ 13
	.word 0                        @ 14
	.word 0                        @ 15
	.word 0                        @ 16
	.word 0                        @ 17
	.word 0                        @ 18
	.word 0                        @ 19
	.word 0                        @ 20
	.word 0                        @ 21
	.word ins_b07_022              @ 22
	.word ins_b07_023              @ 23
	.word ins_b07_024              @ 24
	.word ins_b07_025              @ 25
	.word ins_b07_026              @ 26
	.word ins_b07_027              @ 27
	.word ins_b07_028              @ 28
	.word ins_b07_029              @ 29
	.word ins_b07_030              @ 30
	.word ins_b07_031              @ 31
	.word ins_b07_032              @ 32
	.word ins_b07_033              @ 33
	.word ins_b07_034              @ 34
	.word ins_b07_035              @ 35
	.word ins_b07_036              @ 36
	.word ins_b07_037              @ 37
	.word ins_b07_038              @ 38
	.word 0                        @ 39
	.word 0                        @ 40
	.word ins_b07_041              @ 41
	.word ins_b07_042              @ 42
	.word ins_b07_043              @ 43
	.word ins_b07_044              @ 44
	.word ins_b07_045              @ 45
	.word ins_b07_046              @ 46
	.word ins_b07_047              @ 47
	.word ins_b07_048              @ 48
	.word ins_b07_049              @ 49
	.word ins_b07_050              @ 50
	.word ins_b07_051              @ 51
	.word ins_b07_052              @ 52
	.word ins_b07_053              @ 53
	.word ins_b07_054              @ 54
	.word ins_b07_055              @ 55
	.word ins_b07_056              @ 56
	.word ins_b07_057              @ 57
	.word ins_b07_058              @ 58
	.word ins_b07_059              @ 59
	.word ins_b07_060              @ 60
	.word ins_b07_061              @ 61
bank_08:   @ 69 entries; drum map (R instruments)
	.word ins_b08_000              @ 0
	.word ins_b08_001              @ 1
	.word ins_b08_002              @ 2
	.word ins_b08_003              @ 3
	.word ins_b08_004              @ 4
	.word ins_b08_005              @ 5
	.word ins_b08_006              @ 6
	.word ins_b08_007              @ 7
	.word ins_b08_008              @ 8
	.word 0                        @ 9
	.word ins_b08_010              @ 10
	.word ins_b08_011              @ 11
	.word ins_b08_012              @ 12
	.word ins_b08_013              @ 13
	.word ins_b08_014              @ 14
	.word ins_b08_015              @ 15
	.word ins_b08_016              @ 16
	.word ins_b08_017              @ 17
	.word ins_b08_018              @ 18
	.word 0                        @ 19
	.word ins_b08_020              @ 20
	.word ins_b08_021              @ 21
	.word ins_b08_022              @ 22
	.word ins_b08_023              @ 23
	.word ins_b08_024              @ 24
	.word ins_b08_025              @ 25
	.word ins_b08_026              @ 26
	.word ins_b08_027              @ 27
	.word 0                        @ 28
	.word 0                        @ 29
	.word ins_b08_030              @ 30
	.word ins_b08_031              @ 31
	.word ins_b08_032              @ 32
	.word ins_b08_033              @ 33
	.word ins_b08_034              @ 34
	.word ins_b08_035              @ 35
	.word ins_b08_036              @ 36
	.word 0                        @ 37
	.word 0                        @ 38
	.word 0                        @ 39
	.word ins_b08_040              @ 40
	.word 0                        @ 41
	.word ins_b08_042              @ 42
	.word ins_b08_043              @ 43
	.word 0                        @ 44
	.word ins_b08_045              @ 45
	.word ins_b08_046              @ 46
	.word ins_b08_047              @ 47
	.word ins_b08_048              @ 48
	.word ins_b08_049              @ 49
	.word ins_b08_050              @ 50
	.word ins_b08_051              @ 51
	.word ins_b08_052              @ 52
	.word 0                        @ 53
	.word ins_b08_054              @ 54
	.word ins_b08_055              @ 55
	.word ins_b08_056              @ 56
	.word ins_b08_057              @ 57
	.word ins_b08_058              @ 58
	.word ins_b08_059              @ 59
	.word ins_b08_060              @ 60
	.word ins_b08_061              @ 61
	.word ins_b08_062              @ 62
	.word ins_b08_063              @ 63
	.word ins_b08_064              @ 64
	.word ins_b08_065              @ 65
	.word ins_b08_066              @ 66
	.word ins_b08_067              @ 67
	.word ins_b08_068              @ 68
bank_09:   @ 63 entries; drum map (R instruments)
	.word ins_b09_000              @ 0
	.word ins_b09_001              @ 1
	.word ins_b09_002              @ 2
	.word 0                        @ 3
	.word ins_b09_004              @ 4
	.word ins_b09_005              @ 5
	.word ins_b09_006              @ 6
	.word ins_b09_007              @ 7
	.word 0                        @ 8
	.word 0                        @ 9
	.word ins_b09_010              @ 10
	.word ins_b09_011              @ 11
	.word ins_b09_012              @ 12
	.word 0                        @ 13
	.word 0                        @ 14
	.word 0                        @ 15
	.word 0                        @ 16
	.word 0                        @ 17
	.word ins_b09_018              @ 18
	.word ins_b09_019              @ 19
	.word ins_b09_020              @ 20
	.word ins_b09_021              @ 21
	.word ins_b09_022              @ 22
	.word ins_b09_023              @ 23
	.word ins_b09_024              @ 24
	.word ins_b09_025              @ 25
	.word ins_b09_026              @ 26
	.word ins_b09_027              @ 27
	.word ins_b09_028              @ 28
	.word 0                        @ 29
	.word 0                        @ 30
	.word ins_b09_031              @ 31
	.word ins_b09_032              @ 32
	.word ins_b09_033              @ 33
	.word ins_b09_034              @ 34
	.word ins_b09_035              @ 35
	.word ins_b09_036              @ 36
	.word ins_b09_037              @ 37
	.word ins_b09_038              @ 38
	.word ins_b09_039              @ 39
	.word ins_b09_040              @ 40
	.word ins_b09_041              @ 41
	.word ins_b09_042              @ 42
	.word ins_b09_043              @ 43
	.word ins_b09_044              @ 44
	.word ins_b09_045              @ 45
	.word ins_b09_046              @ 46
	.word ins_b09_047              @ 47
	.word ins_b09_048              @ 48
	.word ins_b09_049              @ 49
	.word ins_b09_050              @ 50
	.word ins_b09_051              @ 51
	.word ins_b09_052              @ 52
	.word ins_b09_053              @ 53
	.word ins_b09_054              @ 54
	.word ins_b09_055              @ 55
	.word ins_b09_056              @ 56
	.word ins_b09_057              @ 57
	.word ins_b09_058              @ 58
	.word ins_b09_059              @ 59
	.word ins_b09_060              @ 60
	.word ins_b09_061              @ 61
	.word ins_b09_062              @ 62
bank_10:   @ 57 entries; drum map (R instruments)
	.word ins_b10_000              @ 0
	.word ins_b10_001              @ 1
	.word ins_b10_002              @ 2
	.word ins_b10_003              @ 3
	.word ins_b10_004              @ 4
	.word ins_b10_005              @ 5
	.word 0                        @ 6
	.word ins_b10_007              @ 7
	.word ins_b10_008              @ 8
	.word ins_b10_009              @ 9
	.word ins_b10_010              @ 10
	.word ins_b10_011              @ 11
	.word ins_b10_012              @ 12
	.word ins_b10_013              @ 13
	.word ins_b10_014              @ 14
	.word ins_b10_015              @ 15
	.word ins_b10_016              @ 16
	.word ins_b10_017              @ 17
	.word 0                        @ 18
	.word ins_b10_019              @ 19
	.word ins_b10_020              @ 20
	.word 0                        @ 21
	.word ins_b10_022              @ 22
	.word ins_b10_023              @ 23
	.word 0                        @ 24
	.word ins_b10_025              @ 25
	.word ins_b10_026              @ 26
	.word 0                        @ 27
	.word ins_b10_028              @ 28
	.word ins_b10_029              @ 29
	.word ins_b10_030              @ 30
	.word ins_b10_031              @ 31
	.word ins_b10_032              @ 32
	.word ins_b10_033              @ 33
	.word ins_b10_034              @ 34
	.word 0                        @ 35
	.word 0                        @ 36
	.word ins_b10_037              @ 37
	.word ins_b10_038              @ 38
	.word ins_b10_039              @ 39
	.word ins_b10_040              @ 40
	.word ins_b10_041              @ 41
	.word ins_b10_042              @ 42
	.word ins_b10_043              @ 43
	.word ins_b10_044              @ 44
	.word ins_b10_045              @ 45
	.word ins_b10_046              @ 46
	.word ins_b10_047              @ 47
	.word ins_b10_048              @ 48
	.word ins_b10_049              @ 49
	.word ins_b10_050              @ 50
	.word ins_b10_051              @ 51
	.word ins_b10_052              @ 52
	.word ins_b10_053              @ 53
	.word ins_b10_054              @ 54
	.word ins_b10_055              @ 55
	.word ins_b10_056              @ 56
bank_11:   @ 65 entries; drum map (R instruments)
	.word 0                        @ 0
	.word ins_b11_001              @ 1
	.word 0                        @ 2
	.word ins_b11_003              @ 3
	.word ins_b11_004              @ 4
	.word ins_b11_005              @ 5
	.word ins_b11_006              @ 6
	.word ins_b11_007              @ 7
	.word ins_b11_008              @ 8
	.word 0                        @ 9
	.word ins_b11_010              @ 10
	.word ins_b11_011              @ 11
	.word ins_b11_012              @ 12
	.word ins_b11_013              @ 13
	.word ins_b11_014              @ 14
	.word 0                        @ 15
	.word ins_b11_016              @ 16
	.word ins_b11_017              @ 17
	.word ins_b11_018              @ 18
	.word 0                        @ 19
	.word 0                        @ 20
	.word ins_b11_021              @ 21
	.word ins_b11_022              @ 22
	.word ins_b11_023              @ 23
	.word ins_b11_024              @ 24
	.word ins_b11_025              @ 25
	.word 0                        @ 26
	.word 0                        @ 27
	.word 0                        @ 28
	.word 0                        @ 29
	.word 0                        @ 30
	.word 0                        @ 31
	.word ins_b11_032              @ 32
	.word ins_b11_033              @ 33
	.word 0                        @ 34
	.word 0                        @ 35
	.word ins_b11_036              @ 36
	.word 0                        @ 37
	.word 0                        @ 38
	.word 0                        @ 39
	.word 0                        @ 40
	.word 0                        @ 41
	.word 0                        @ 42
	.word 0                        @ 43
	.word 0                        @ 44
	.word 0                        @ 45
	.word 0                        @ 46
	.word 0                        @ 47
	.word 0                        @ 48
	.word 0                        @ 49
	.word 0                        @ 50
	.word ins_b11_051              @ 51
	.word 0                        @ 52
	.word ins_b11_053              @ 53
	.word ins_b11_054              @ 54
	.word ins_b11_055              @ 55
	.word ins_b11_056              @ 56
	.word ins_b11_057              @ 57
	.word ins_b11_058              @ 58
	.word ins_b11_059              @ 59
	.word ins_b11_060              @ 60
	.word ins_b11_061              @ 61
	.word ins_b11_062              @ 62
	.word ins_b11_063              @ 63
	.word ins_b11_064              @ 64
bank_12:   @ 99 entries; drum map (R instruments)
	.word 0                        @ 0
	.word ins_b12_001              @ 1
	.word ins_b12_002              @ 2
	.word ins_b12_003              @ 3
	.word ins_b12_004              @ 4
	.word ins_b12_005              @ 5
	.word ins_b12_006              @ 6
	.word ins_b12_007              @ 7
	.word ins_b12_008              @ 8
	.word ins_b12_009              @ 9
	.word ins_b12_010              @ 10
	.word ins_b12_011              @ 11
	.word ins_b12_012              @ 12
	.word ins_b12_013              @ 13
	.word ins_b12_014              @ 14
	.word ins_b12_015              @ 15
	.word ins_b12_016              @ 16
	.word ins_b12_017              @ 17
	.word ins_b12_018              @ 18
	.word ins_b12_019              @ 19
	.word ins_b12_020              @ 20
	.word ins_b12_021              @ 21
	.word ins_b12_022              @ 22
	.word ins_b12_023              @ 23
	.word ins_b12_024              @ 24
	.word ins_b12_025              @ 25
	.word ins_b12_026              @ 26
	.word ins_b12_027              @ 27
	.word ins_b12_028              @ 28
	.word ins_b12_029              @ 29
	.word ins_b12_030              @ 30
	.word ins_b12_031              @ 31
	.word ins_b12_032              @ 32
	.word ins_b12_033              @ 33
	.word ins_b12_034              @ 34
	.word ins_b12_035              @ 35
	.word ins_b12_036              @ 36
	.word ins_b12_037              @ 37
	.word ins_b12_038              @ 38
	.word ins_b12_039              @ 39
	.word ins_b12_040              @ 40
	.word ins_b12_041              @ 41
	.word ins_b12_042              @ 42
	.word ins_b12_043              @ 43
	.word ins_b12_044              @ 44
	.word ins_b12_045              @ 45
	.word ins_b12_046              @ 46
	.word ins_b12_047              @ 47
	.word ins_b12_048              @ 48
	.word ins_b12_049              @ 49
	.word ins_b12_050              @ 50
	.word ins_b12_051              @ 51
	.word ins_b12_052              @ 52
	.word ins_b12_053              @ 53
	.word ins_b12_054              @ 54
	.word ins_b12_055              @ 55
	.word ins_b12_056              @ 56
	.word ins_b12_057              @ 57
	.word ins_b12_058              @ 58
	.word ins_b12_059              @ 59
	.word ins_b12_060              @ 60
	.word ins_b12_061              @ 61
	.word ins_b12_062              @ 62
	.word ins_b12_063              @ 63
	.word ins_b12_064              @ 64
	.word ins_b12_065              @ 65
	.word ins_b12_066              @ 66
	.word ins_b12_067              @ 67
	.word ins_b12_068              @ 68
	.word ins_b12_069              @ 69
	.word ins_b12_070              @ 70
	.word ins_b12_071              @ 71
	.word ins_b12_072              @ 72
	.word ins_b12_073              @ 73
	.word ins_b12_074              @ 74
	.word ins_b12_075              @ 75
	.word ins_b12_076              @ 76
	.word ins_b12_077              @ 77
	.word ins_b12_078              @ 78
	.word ins_b12_079              @ 79
	.word ins_b12_080              @ 80
	.word ins_b12_081              @ 81
	.word ins_b12_082              @ 82
	.word ins_b12_083              @ 83
	.word ins_b12_084              @ 84
	.word ins_b12_085              @ 85
	.word ins_b12_086              @ 86
	.word ins_b12_087              @ 87
	.word ins_b12_088              @ 88
	.word ins_b12_089              @ 89
	.word ins_b12_090              @ 90
	.word ins_b12_091              @ 91
	.word ins_b12_092              @ 92
	.word ins_b12_093              @ 93
	.word ins_b12_094              @ 94
	.word ins_b12_095              @ 95
	.word ins_b12_096              @ 96
	.word ins_b12_097              @ 97
	.word ins_b12_098              @ 98
bank_13:   @ 84 entries; drum map (R instruments)
	.word 0                        @ 0
	.word ins_b13_001              @ 1
	.word ins_b13_002              @ 2
	.word ins_b13_003              @ 3
	.word ins_b13_004              @ 4
	.word ins_b13_005              @ 5
	.word ins_b13_006              @ 6
	.word ins_b13_007              @ 7
	.word ins_b13_008              @ 8
	.word ins_b13_009              @ 9
	.word ins_b13_010              @ 10
	.word ins_b13_011              @ 11
	.word ins_b13_012              @ 12
	.word ins_b13_013              @ 13
	.word ins_b13_014              @ 14
	.word ins_b13_015              @ 15
	.word ins_b13_016              @ 16
	.word ins_b13_017              @ 17
	.word ins_b13_018              @ 18
	.word ins_b13_019              @ 19
	.word ins_b13_020              @ 20
	.word ins_b13_021              @ 21
	.word ins_b13_022              @ 22
	.word ins_b13_023              @ 23
	.word ins_b13_024              @ 24
	.word ins_b13_025              @ 25
	.word ins_b13_026              @ 26
	.word ins_b13_027              @ 27
	.word ins_b13_028              @ 28
	.word ins_b13_029              @ 29
	.word ins_b13_030              @ 30
	.word ins_b13_031              @ 31
	.word ins_b13_032              @ 32
	.word ins_b13_033              @ 33
	.word ins_b13_034              @ 34
	.word ins_b13_035              @ 35
	.word ins_b13_036              @ 36
	.word ins_b13_037              @ 37
	.word ins_b13_038              @ 38
	.word ins_b13_039              @ 39
	.word ins_b13_040              @ 40
	.word ins_b13_041              @ 41
	.word ins_b13_042              @ 42
	.word ins_b13_043              @ 43
	.word ins_b13_044              @ 44
	.word ins_b13_045              @ 45
	.word ins_b13_046              @ 46
	.word ins_b13_047              @ 47
	.word ins_b13_048              @ 48
	.word ins_b13_049              @ 49
	.word ins_b13_050              @ 50
	.word ins_b13_051              @ 51
	.word ins_b13_052              @ 52
	.word ins_b13_053              @ 53
	.word ins_b13_054              @ 54
	.word ins_b13_055              @ 55
	.word ins_b13_056              @ 56
	.word ins_b13_057              @ 57
	.word ins_b13_058              @ 58
	.word ins_b13_059              @ 59
	.word ins_b13_060              @ 60
	.word ins_b13_061              @ 61
	.word ins_b13_062              @ 62
	.word ins_b13_063              @ 63
	.word ins_b13_064              @ 64
	.word ins_b13_065              @ 65
	.word ins_b13_066              @ 66
	.word ins_b13_067              @ 67
	.word ins_b13_068              @ 68
	.word ins_b13_069              @ 69
	.word ins_b13_070              @ 70
	.word ins_b13_071              @ 71
	.word ins_b13_072              @ 72
	.word ins_b13_073              @ 73
	.word ins_b13_074              @ 74
	.word ins_b13_075              @ 75
	.word ins_b13_076              @ 76
	.word ins_b13_077              @ 77
	.word ins_b13_078              @ 78
	.word ins_b13_079              @ 79
	.word ins_b13_080              @ 80
	.word ins_b13_081              @ 81
	.word ins_b13_082              @ 82
	.word ins_b13_083              @ 83
bank_14:   @ 79 entries; drum map (R instruments)
	.word 0                        @ 0
	.word ins_b14_001              @ 1
	.word ins_b14_002              @ 2
	.word ins_b14_003              @ 3
	.word ins_b14_004              @ 4
	.word ins_b14_005              @ 5
	.word ins_b14_006              @ 6
	.word ins_b14_007              @ 7
	.word ins_b14_008              @ 8
	.word ins_b14_009              @ 9
	.word ins_b14_010              @ 10
	.word ins_b14_011              @ 11
	.word ins_b14_012              @ 12
	.word ins_b14_013              @ 13
	.word ins_b14_014              @ 14
	.word ins_b14_015              @ 15
	.word ins_b14_016              @ 16
	.word ins_b14_017              @ 17
	.word ins_b14_018              @ 18
	.word ins_b14_019              @ 19
	.word ins_b14_020              @ 20
	.word ins_b14_021              @ 21
	.word ins_b14_022              @ 22
	.word ins_b14_023              @ 23
	.word ins_b14_024              @ 24
	.word ins_b14_025              @ 25
	.word ins_b14_026              @ 26
	.word ins_b14_027              @ 27
	.word ins_b14_028              @ 28
	.word ins_b14_029              @ 29
	.word ins_b14_030              @ 30
	.word ins_b14_031              @ 31
	.word ins_b14_032              @ 32
	.word ins_b14_033              @ 33
	.word ins_b14_034              @ 34
	.word ins_b14_035              @ 35
	.word ins_b14_036              @ 36
	.word ins_b14_037              @ 37
	.word ins_b14_038              @ 38
	.word ins_b14_039              @ 39
	.word ins_b14_040              @ 40
	.word ins_b14_041              @ 41
	.word ins_b14_042              @ 42
	.word ins_b14_043              @ 43
	.word ins_b14_044              @ 44
	.word ins_b14_045              @ 45
	.word ins_b14_046              @ 46
	.word ins_b14_047              @ 47
	.word ins_b14_048              @ 48
	.word ins_b14_049              @ 49
	.word ins_b14_050              @ 50
	.word ins_b14_051              @ 51
	.word ins_b14_052              @ 52
	.word ins_b14_053              @ 53
	.word ins_b14_054              @ 54
	.word ins_b14_055              @ 55
	.word ins_b14_056              @ 56
	.word ins_b14_057              @ 57
	.word ins_b14_058              @ 58
	.word ins_b14_059              @ 59
	.word ins_b14_060              @ 60
	.word ins_b14_061              @ 61
	.word ins_b14_062              @ 62
	.word ins_b14_063              @ 63
	.word ins_b14_064              @ 64
	.word ins_b14_065              @ 65
	.word ins_b14_066              @ 66
	.word ins_b14_067              @ 67
	.word ins_b14_068              @ 68
	.word ins_b14_069              @ 69
	.word ins_b14_070              @ 70
	.word ins_b14_071              @ 71
	.word ins_b14_072              @ 72
	.word ins_b14_073              @ 73
	.word ins_b14_074              @ 74
	.word ins_b14_075              @ 75
	.word ins_b14_076              @ 76
	.word ins_b14_077              @ 77
	.word ins_b14_078              @ 78
bank_15:   @ 62 entries; drum map (R instruments)
	.word 0                        @ 0
	.word ins_b15_001              @ 1
	.word ins_b15_002              @ 2
	.word ins_b15_003              @ 3
	.word ins_b15_004              @ 4
	.word ins_b15_005              @ 5
	.word ins_b15_006              @ 6
	.word ins_b15_007              @ 7
	.word ins_b15_008              @ 8
	.word ins_b15_009              @ 9
	.word ins_b15_010              @ 10
	.word ins_b15_011              @ 11
	.word ins_b15_012              @ 12
	.word ins_b15_013              @ 13
	.word ins_b15_014              @ 14
	.word ins_b15_015              @ 15
	.word ins_b15_016              @ 16
	.word ins_b15_017              @ 17
	.word ins_b15_018              @ 18
	.word ins_b15_019              @ 19
	.word ins_b15_020              @ 20
	.word ins_b15_021              @ 21
	.word ins_b15_022              @ 22
	.word 0                        @ 23
	.word ins_b15_024              @ 24
	.word ins_b15_025              @ 25
	.word ins_b15_026              @ 26
	.word ins_b15_027              @ 27
	.word ins_b15_028              @ 28
	.word ins_b15_029              @ 29
	.word ins_b15_030              @ 30
	.word ins_b15_031              @ 31
	.word ins_b15_032              @ 32
	.word ins_b15_033              @ 33
	.word ins_b15_034              @ 34
	.word 0                        @ 35
	.word ins_b15_036              @ 36
	.word ins_b15_037              @ 37
	.word ins_b15_038              @ 38
	.word ins_b15_039              @ 39
	.word ins_b15_040              @ 40
	.word ins_b15_041              @ 41
	.word ins_b15_042              @ 42
	.word ins_b15_043              @ 43
	.word ins_b15_044              @ 44
	.word ins_b15_045              @ 45
	.word ins_b15_046              @ 46
	.word ins_b15_047              @ 47
	.word ins_b15_048              @ 48
	.word ins_b15_049              @ 49
	.word ins_b15_050              @ 50
	.word ins_b15_051              @ 51
	.word ins_b15_052              @ 52
	.word ins_b15_053              @ 53
	.word ins_b15_054              @ 54
	.word ins_b15_055              @ 55
	.word ins_b15_056              @ 56
	.word ins_b15_057              @ 57
	.word ins_b15_058              @ 58
	.word ins_b15_059              @ 59
	.word ins_b15_060              @ 60
	.word ins_b15_061              @ 61

	.global sndBankTable
sndBankTable:   @ Instrument **[16]; the song table selects one by index
	.word bank_00
	.word bank_01
	.word bank_02
	.word bank_03
	.word bank_04
	.word bank_05
	.word bank_06
	.word bank_07
	.word bank_08
	.word bank_09
	.word bank_10
	.word bank_11
	.word bank_12
	.word bank_13
	.word bank_14
	.word bank_15

@ ---- song names (ROM strings) ----
sname_0000: .asciz "x_TEST"
	.balign 4
sname_0001: .asciz "m_x_BGM_BOMB_2bar"
	.balign 4
sname_0002: .asciz "m_x_BGM_BOMB_4bar"
	.balign 4
sname_0003: .asciz "m_x_BGM_BOMB_8bar"
	.balign 4
sname_0004: .asciz "m_BGM_01"
	.balign 4
sname_0005: .asciz "m_BGM_Title_Demo_10"
sname_0006: .asciz "m_BGM_Title_Demo_NEWS"
	.balign 4
sname_0007: .asciz "m_BGM_Title_Demo_15"
sname_0008: .asciz "m_BGM_Title_Demo_20"
sname_0009: .asciz "m_BGM_Title_Demo_30"
sname_0010: .asciz "m_BGM_Title_01"
	.balign 4
sname_0011: .asciz "m_BGM_Select_01"
sname_0012: .asciz "m_BGM_Select_02"
sname_0013: .asciz "s_Demo_MAP_1"
	.balign 4
sname_0014: .asciz "m_BGM_Demo_EP_MAP_1"
sname_0015: .asciz "m_BGM_Ending_01"
sname_0016: .asciz "m_BGM_Ending_02"
sname_0017: .asciz "m_BGM_DrMario_Title"
sname_0018: .asciz "m_BGM_DrMario_Select"
	.balign 4
sname_0019: .asciz "m_BGM_DrMario_Game_Hot"
	.balign 4
sname_0020: .asciz "m_BGM_DrMario_Clear"
sname_0021: .asciz "m_BGM_DrMario_OVER"
	.balign 4
sname_0022: .asciz "m_BGM_DrMario_Demo"
	.balign 4
sname_0023: .asciz "s_Demo_DrMario_UFO_1"
	.balign 4
sname_0024: .asciz "s_Demo_DrMario_UFO_2"
	.balign 4
sname_0025: .asciz "m_BGM_DrMario_Ending"
	.balign 4
sname_0026: .asciz "m_BGM_PAINT_Title"
	.balign 4
sname_0027: .asciz "m_BGM_PAINT_BGM_1"
	.balign 4
sname_0028: .asciz "m_BGM_PAINT_BGM_2"
	.balign 4
sname_0029: .asciz "m_BGM_PAINT_BGM_3"
	.balign 4
sname_0030: .asciz "m_BGM_PAINT_BOSS"
	.balign 4
sname_0031: .asciz "m_BGM_PAINT_GameOver"
	.balign 4
sname_0032: .asciz "m_BGM_PAINT_Fanfare"
sname_0033: .asciz "m_BGM_Sheriff_Title"
sname_0034: .asciz "m_BGM_Sheriff_START_1"
	.balign 4
sname_0035: .asciz "m_BGM_Sheriff_Game_1"
	.balign 4
sname_0036: .asciz "m_BGM_Sheriff_BIRD_1"
	.balign 4
sname_0037: .asciz "m_BGM_Sheriff_TEKI_IN_1"
sname_0038: .asciz "m_BGM_Sheriff_CLEAR_1"
	.balign 4
sname_0039: .asciz "m_BGM_Sheriff_CLEAR_HART"
	.balign 4
sname_0040: .asciz "m_BGM_Sheriff_GameOver"
	.balign 4
sname_0041: .asciz "m_BGM_GYORO_Title_01"
	.balign 4
sname_0042: .asciz "m_BGM_GYORO_Game_Type_1"
sname_0043: .asciz "m_BGM_GYORO_Game_Type_2"
sname_0044: .asciz "m_BGM_GYORO_Game_Type_3"
sname_0045: .asciz "m_BGM_GYORO_Game_Type_4"
sname_0046: .asciz "m_BGM_GYORO_Game_50000"
	.balign 4
sname_0047: .asciz "m_BGM_GYORO_Game_50000_2"
	.balign 4
sname_0048: .asciz "m_BGM_GYORO_Game_50000_3"
	.balign 4
sname_0049: .asciz "m_BGM_GYORO_GameOver_01"
sname_0050: .asciz "m_BGM_Wario_Demo_1"
	.balign 4
sname_0051: .asciz "m_BGM_Wario_Turn_NEXT_01"
	.balign 4
sname_0052: .asciz "m_BGM_Wario_Turn_NEXT_02"
	.balign 4
sname_0053: .asciz "m_BGM_Wario_Turn_OK_01"
	.balign 4
sname_0054: .asciz "m_BGM_Wario_Turn_OK_02"
	.balign 4
sname_0055: .asciz "m_BGM_Wario_Turn_NG_01"
	.balign 4
sname_0056: .asciz "m_BGM_Wario_Turn_NG_02"
	.balign 4
sname_0057: .asciz "m_BGM_Wario_END_01"
	.balign 4
sname_0058: .asciz "m_BGM_Wario_END_Loop_01"
sname_0059: .asciz "m_BGM_Wario_EP_10"
	.balign 4
sname_0060: .asciz "m_BGM_Wario_EP_STAFF_01"
sname_0061: .asciz "m_BGM_Wario_BOSS_10"
sname_0062: .asciz "m_BGM_Wario_BOSS_90"
sname_0063: .asciz "m_BGM_Tutorial_Demo_1"
	.balign 4
sname_0064: .asciz "m_BGM_Tutorial_READY_01"
sname_0065: .asciz "m_BGM_Tutorial_Turn_OK_01"
	.balign 4
sname_0066: .asciz "m_BGM_Tutorial_Turn_OK_02"
	.balign 4
sname_0067: .asciz "m_BGM_Tutorial_Turn_NG_01"
	.balign 4
sname_0068: .asciz "m_BGM_Tutorial_Turn_NG_02"
	.balign 4
sname_0069: .asciz "m_BGM_Tutorial_Turn_NEXT_0"
	.balign 4
sname_0070: .asciz "m_BGM_Tutorial_Turn_NEXT_1"
	.balign 4
sname_0071: .asciz "m_BGM_Tutorial_END_01"
	.balign 4
sname_0072: .asciz "m_BGM_Tutorial_BOSS_FF_ST"
	.balign 4
sname_0073: .asciz "m_BGM_Tutorial_BOSS_10"
	.balign 4
sname_0074: .asciz "m_BGM_BOMB_Demo_AFRO_0"
	.balign 4
sname_0075: .asciz "m_BGM_BOMB_Demo_AFRO_1"
	.balign 4
sname_0076: .asciz "m_BGM_BOMB_Demo_AFRO_2"
	.balign 4
sname_0077: .asciz "m_BGM_BOMB_Demo_AFRO_3"
	.balign 4
sname_0078: .asciz "m_BGM_BOMB_Demo_AFRO_Loop"
	.balign 4
sname_0079: .asciz "m_BGM_BOMB_Demo_AFRO_Loop_B"
sname_0080: .asciz "m_BGM_BOMB_Demo_AFRO_Loop_C"
sname_0081: .asciz "m_BGM_BOMB_Demo_AFRO_Loop2"
	.balign 4
sname_0082: .asciz "m_BGM_BOMB_Demo_AFRO_Loop22"
sname_0083: .asciz "m_BGM_BOMB_Demo_AFRO_Loop23"
sname_0084: .asciz "m_BGM_BOMB_Demo_AFRO_NEXT1A"
sname_0085: .asciz "m_BGM_BOMB_Demo_AFRO_NEXT2A"
sname_0086: .asciz "m_BGM_BOMB_Demo_AFRO_NEXT1B"
sname_0087: .asciz "m_BGM_BOMB_Demo_AFRO_NEXT2B"
sname_0088: .asciz "m_BGM_BOMB_Demo_AFRO_NEXT1C"
sname_0089: .asciz "m_BGM_BOMB_Demo_AFRO_NEXT2C"
sname_0090: .asciz "m_BGM_AFRO_Turn_NEXT_00"
sname_0091: .asciz "m_BGM_AFRO_Turn_OK_01"
	.balign 4
sname_0092: .asciz "m_BGM_AFRO_Turn_OK_02"
	.balign 4
sname_0093: .asciz "m_BGM_AFRO_Turn_NG_01"
	.balign 4
sname_0094: .asciz "m_BGM_AFRO_Turn_NG_02"
	.balign 4
sname_0095: .asciz "m_BGM_AFRO_Turn_NEXT_01"
sname_0096: .asciz "m_BGM_AFRO_Turn_NEXT_02"
sname_0097: .asciz "m_BGM_BOMB_Demo_AFRO_EP_A1"
	.balign 4
sname_0098: .asciz "m_BGM_BOMB_Demo_AFRO_EP_A2"
	.balign 4
sname_0099: .asciz "m_BGM_AFRO_BOSS_10"
	.balign 4
sname_0100: .asciz "m_BGM_AFRO_BOSS_11"
	.balign 4
sname_0101: .asciz "m_BGM_AFRO_BOSS_21"
	.balign 4
sname_0102: .asciz "m_BGM_AFRO_BOSS_31"
	.balign 4
sname_0103: .asciz "m_BGM_AFRO_BOSS_41"
	.balign 4
sname_0104: .asciz "m_BGM_AFRO_BOSS_51"
	.balign 4
sname_0105: .asciz "m_BGM_DraBuru_INTRO_0"
	.balign 4
sname_0106: .asciz "m_BGM_DraBuru_INTRO_1"
	.balign 4
sname_0107: .asciz "m_BGM_DraBuru_INTRO_2"
	.balign 4
sname_0108: .asciz "m_BGM_DraBuru_INTRO_3"
	.balign 4
sname_0109: .asciz "m_BGM_DraBuru_01_IN"
sname_0110: .asciz "m_BGM_DraBuru_02_IN"
sname_0111: .asciz "m_BGM_DraBuru_03_IN"
sname_0112: .asciz "m_BGM_DraBuru_04_IN"
sname_0113: .asciz "m_BGM_DraBuru_01_Intro"
	.balign 4
sname_0114: .asciz "m_BGM_DraBuru_01_01"
sname_0115: .asciz "m_BGM_DraBuru_01_02"
sname_0116: .asciz "m_BGM_DraBuru_01_03"
sname_0117: .asciz "m_BGM_DraBuru_01_04"
sname_0118: .asciz "m_BGM_DraBuru_01_05"
sname_0119: .asciz "m_BGM_DraBuru_01_06"
sname_0120: .asciz "m_BGM_DraBuru_01_07"
sname_0121: .asciz "m_BGM_DraBuru_01_08"
sname_0122: .asciz "m_BGM_DraBuru_01_END"
	.balign 4
sname_0123: .asciz "m_BGM_DraBuru_01_BOSS_IN"
	.balign 4
sname_0124: .asciz "m_BGM_DraBuru_01_SpeedUp"
	.balign 4
sname_0125: .asciz "m_BGM_DraBuru_02_Intro"
	.balign 4
sname_0126: .asciz "m_BGM_DraBuru_02_01"
sname_0127: .asciz "m_BGM_DraBuru_02_02"
sname_0128: .asciz "m_BGM_DraBuru_02_03"
sname_0129: .asciz "m_BGM_DraBuru_02_04"
sname_0130: .asciz "m_BGM_DraBuru_02_05"
sname_0131: .asciz "m_BGM_DraBuru_02_06"
sname_0132: .asciz "m_BGM_DraBuru_02_07"
sname_0133: .asciz "m_BGM_DraBuru_02_08"
sname_0134: .asciz "m_BGM_DraBuru_02_END"
	.balign 4
sname_0135: .asciz "m_BGM_DraBuru_02_BOSS_IN"
	.balign 4
sname_0136: .asciz "m_BGM_DraBuru_02_SpeedUp"
	.balign 4
sname_0137: .asciz "m_BGM_DraBuru_03_Intro"
	.balign 4
sname_0138: .asciz "m_BGM_DraBuru_03_01"
sname_0139: .asciz "m_BGM_DraBuru_03_02"
sname_0140: .asciz "m_BGM_DraBuru_03_03"
sname_0141: .asciz "m_BGM_DraBuru_03_04"
sname_0142: .asciz "m_BGM_DraBuru_03_05"
sname_0143: .asciz "m_BGM_DraBuru_03_06"
sname_0144: .asciz "m_BGM_DraBuru_03_07"
sname_0145: .asciz "m_BGM_DraBuru_03_08"
sname_0146: .asciz "m_BGM_DraBuru_03_END"
	.balign 4
sname_0147: .asciz "m_BGM_DraBuru_03_BOSS_IN"
	.balign 4
sname_0148: .asciz "m_BGM_DraBuru_03_SpeedUp"
	.balign 4
sname_0149: .asciz "m_BGM_DraBuru_04_Intro"
	.balign 4
sname_0150: .asciz "m_BGM_DraBuru_04_01"
sname_0151: .asciz "m_BGM_DraBuru_04_02"
sname_0152: .asciz "m_BGM_DraBuru_04_03"
sname_0153: .asciz "m_BGM_DraBuru_04_04"
sname_0154: .asciz "m_BGM_DraBuru_04_05"
sname_0155: .asciz "m_BGM_DraBuru_04_06"
sname_0156: .asciz "m_BGM_DraBuru_04_07"
sname_0157: .asciz "m_BGM_DraBuru_04_08"
sname_0158: .asciz "m_BGM_DraBuru_04_END"
	.balign 4
sname_0159: .asciz "m_BGM_DraBuru_04_BOSS_IN"
	.balign 4
sname_0160: .asciz "m_BGM_DraBuru_04_SpeedUp"
	.balign 4
sname_0161: .asciz "m_BGM_DraBuru_NEXTSTAGE"
sname_0162: .asciz "m_BGM_DraBuru_Turn_OK_01"
	.balign 4
sname_0163: .asciz "m_BGM_DraBuru_Turn_OK_02"
	.balign 4
sname_0164: .asciz "m_BGM_DraBuru_Turn_NG_01"
	.balign 4
sname_0165: .asciz "m_BGM_DraBuru_Turn_NG_02"
	.balign 4
sname_0166: .asciz "m_BGM_DraBuru_Turn_NEXT_1"
	.balign 4
sname_0167: .asciz "m_BGM_DraBuru_Turn_NEXT_2"
	.balign 4
sname_0168: .asciz "m_BGM_DraBuru_Boss_START_1"
	.balign 4
sname_0169: .asciz "m_BGM_DraBuru_Boss_START_FF"
sname_0170: .asciz "m_BGM_DraBuru_Boss_01"
	.balign 4
sname_0171: .asciz "m_BGM_DraBuru_BOSS_BOSS"
sname_0172: .asciz "m_BGM_DraBuru_BOSS_NG"
	.balign 4
sname_0173: .asciz "m_BGM_DraBuru_BOSS_Clear"
	.balign 4
sname_0174: .asciz "m_BGM_DraBuru_REST_LvUp"
sname_0175: .asciz "m_BGM_DraBuru_EP_1"
	.balign 4
sname_0176: .asciz "m_BGM_Monna_INTRO_0_City"
	.balign 4
sname_0177: .asciz "m_BGM_Monna_INTRO_0_Shop"
	.balign 4
sname_0178: .asciz "m_BGM_Monna_INTRO_1"
sname_0179: .asciz "m_BGM_Monna_INTRO_2"
sname_0180: .asciz "m_BGM_Monna_01"
	.balign 4
sname_0181: .asciz "m_BGM_Monna_02"
	.balign 4
sname_0182: .asciz "m_BGM_Monna_03"
	.balign 4
sname_0183: .asciz "m_BGM_Monna_04"
	.balign 4
sname_0184: .asciz "m_BGM_Monna_05"
	.balign 4
sname_0185: .asciz "m_BGM_Monna_06"
	.balign 4
sname_0186: .asciz "m_BGM_Monna_07"
	.balign 4
sname_0187: .asciz "m_BGM_Monna_08"
	.balign 4
sname_0188: .asciz "m_BGM_Monna_09"
	.balign 4
sname_0189: .asciz "m_BGM_Monna_10"
	.balign 4
sname_0190: .asciz "m_BGM_Monna_END"
sname_0191: .asciz "m_BGM_Monna_Loop"
	.balign 4
sname_0192: .asciz "m_BGM_Monna_Result_OK_10"
	.balign 4
sname_0193: .asciz "m_BGM_Monna_Result_OK_11"
	.balign 4
sname_0194: .asciz "m_BGM_Monna_Result_NG_10"
	.balign 4
sname_0195: .asciz "m_BGM_Monna_Result_NG_11"
	.balign 4
sname_0196: .asciz "m_BGM_Monna_NEXT_10"
sname_0197: .asciz "m_BGM_Monna_NEXT_11"
sname_0198: .asciz "m_BGM_Monna_BOSS_10"
sname_0199: .asciz "m_BGM_Monna_EP_1"
	.balign 4
sname_0200: .asciz "m_BGM_Monna_EP_Shop"
sname_0201: .asciz "m_BGM_Monna_FF_Safe_01"
	.balign 4
sname_0202: .asciz "m_BGM_Voya_Demo_IN_05"
	.balign 4
sname_0203: .asciz "m_BGM_Voya_Demo_IN_10"
	.balign 4
sname_0204: .asciz "m_BGM_Voya_Demo_IN_50"
	.balign 4
sname_0205: .asciz "m_BGM_Voya_Demo_IN_51"
	.balign 4
sname_0206: .asciz "m_BGM_Voya_Turn_OK_1"
	.balign 4
sname_0207: .asciz "m_BGM_Voya_Turn_OK_2"
	.balign 4
sname_0208: .asciz "m_BGM_Voya_Turn_NG_1"
	.balign 4
sname_0209: .asciz "m_BGM_Voya_Turn_NG_2"
	.balign 4
sname_0210: .asciz "m_BGM_Voya_Turn_NEXT_1"
	.balign 4
sname_0211: .asciz "m_BGM_Voya_Turn_NEXT_2"
	.balign 4
sname_0212: .asciz "m_BGM_Voya_Game_END_1"
	.balign 4
sname_0213: .asciz "m_BGM_Voya_BOSS_Fanfare_1"
	.balign 4
sname_0214: .asciz "m_BGM_Voya_BOSS_10"
	.balign 4
sname_0215: .asciz "m_BGM_KAEDE_Demo_01"
sname_0216: .asciz "m_BGM_KAEDE_Demo_02"
sname_0217: .asciz "m_BGM_KAEDE_Demo_03"
sname_0218: .asciz "m_BGM_KAEDE_Demo_04"
sname_0219: .asciz "m_BGM_KAEDE_Demo_05"
sname_0220: .asciz "m_BGM_KAEDE_Demo_06"
sname_0221: .asciz "m_BGM_KAEDE_Demo_10"
sname_0222: .asciz "m_BGM_KAEDE_Demo_11"
sname_0223: .asciz "m_BGM_KAEDE_Game_Intro"
	.balign 4
sname_0224: .asciz "m_BGM_KAEDE_Game_1_1"
	.balign 4
sname_0225: .asciz "m_BGM_KAEDE_Game_1_2"
	.balign 4
sname_0226: .asciz "m_BGM_KAEDE_Game_1_3"
	.balign 4
sname_0227: .asciz "m_BGM_KAEDE_Game_1_4"
	.balign 4
sname_0228: .asciz "m_BGM_KAEDE_Game_1_5"
	.balign 4
sname_0229: .asciz "m_BGM_KAEDE_Game_1_6"
	.balign 4
sname_0230: .asciz "m_BGM_KAEDE_Game_1_7"
	.balign 4
sname_0231: .asciz "m_BGM_KAEDE_Game_1_8"
	.balign 4
sname_0232: .asciz "m_BGM_KAEDE_Game_1_NEXT"
sname_0233: .asciz "m_BGM_KAEDE_Game_1_END"
	.balign 4
sname_0234: .asciz "m_BGM_KAEDE_Game_2_1"
	.balign 4
sname_0235: .asciz "m_BGM_KAEDE_Game_2_2"
	.balign 4
sname_0236: .asciz "m_BGM_KAEDE_Game_2_3"
	.balign 4
sname_0237: .asciz "m_BGM_KAEDE_Game_2_4"
	.balign 4
sname_0238: .asciz "m_BGM_KAEDE_Game_2_5"
	.balign 4
sname_0239: .asciz "m_BGM_KAEDE_Game_2_6"
	.balign 4
sname_0240: .asciz "m_BGM_KAEDE_Game_2_7"
	.balign 4
sname_0241: .asciz "m_BGM_KAEDE_Game_2_8"
	.balign 4
sname_0242: .asciz "m_BGM_KAEDE_Game_2_NEXT"
sname_0243: .asciz "m_BGM_KAEDE_Game_2_END"
	.balign 4
sname_0244: .asciz "m_BGM_KAEDE_Game_3_1"
	.balign 4
sname_0245: .asciz "m_BGM_KAEDE_Game_3_2"
	.balign 4
sname_0246: .asciz "m_BGM_KAEDE_Game_3_3"
	.balign 4
sname_0247: .asciz "m_BGM_KAEDE_Game_3_4"
	.balign 4
sname_0248: .asciz "m_BGM_KAEDE_Game_3_5"
	.balign 4
sname_0249: .asciz "m_BGM_KAEDE_Game_3_6"
	.balign 4
sname_0250: .asciz "m_BGM_KAEDE_Game_3_7"
	.balign 4
sname_0251: .asciz "m_BGM_KAEDE_Game_3_8"
	.balign 4
sname_0252: .asciz "m_BGM_KAEDE_Game_3_NEXT"
sname_0253: .asciz "m_BGM_KAEDE_Game_3_END"
	.balign 4
sname_0254: .asciz "m_BGM_KAEDE_Game_BOSS_Next"
	.balign 4
sname_0255: .asciz "m_BGM_KAEDE_BOSS_10"
sname_0256: .asciz "m_BGM_KAEDE_Demo_EP_10"
	.balign 4
sname_0257: .asciz "m_BGM_KAEDE_Demo_EP_11"
	.balign 4
sname_0258: .asciz "m_BGM_KAEDE_Demo_EP_12"
	.balign 4
sname_0259: .asciz "m_BGM_Loo_Demo_MAP_1"
	.balign 4
sname_0260: .asciz "m_BGM_Loo_Demo_10"
	.balign 4
sname_0261: .asciz "m_BGM_Loo_Demo_11"
	.balign 4
sname_0262: .asciz "m_BGM_Loo_Demo_112"
	.balign 4
sname_0263: .asciz "m_BGM_Loo_Demo_12"
	.balign 4
sname_0264: .asciz "m_BGM_Loo_Demo_13"
	.balign 4
sname_0265: .asciz "m_BGM_Loo_Game_1_Intro"
	.balign 4
sname_0266: .asciz "m_BGM_Loo_Game_1_1"
	.balign 4
sname_0267: .asciz "m_BGM_Loo_Game_1_2"
	.balign 4
sname_0268: .asciz "m_BGM_Loo_Game_1_3"
	.balign 4
sname_0269: .asciz "m_BGM_Loo_Game_1_4"
	.balign 4
sname_0270: .asciz "m_BGM_Loo_Game_1_5"
	.balign 4
sname_0271: .asciz "m_BGM_Loo_Game_1_6"
	.balign 4
sname_0272: .asciz "m_BGM_Loo_Game_1_7"
	.balign 4
sname_0273: .asciz "m_BGM_Loo_Game_1_8"
	.balign 4
sname_0274: .asciz "m_BGM_Loo_Game_1_NEXT"
	.balign 4
sname_0275: .asciz "m_BGM_Loo_Game_1_END"
	.balign 4
sname_0276: .asciz "m_BGM_Loo_BOSS_FF_Start"
sname_0277: .asciz "m_BGM_Loo_BOSS_10"
	.balign 4
sname_0278: .asciz "m_BGM_Loo_EP_05"
sname_0279: .asciz "m_BGM_Loo_EP_10"
sname_0280: .asciz "m_BGM_Loo_EP_11"
sname_0281: .asciz "m_BGM_Bio_Demo_0"
	.balign 4
sname_0282: .asciz "m_BGM_Bio_Turn_OK_1"
sname_0283: .asciz "m_BGM_Bio_Turn_OK_2"
sname_0284: .asciz "m_BGM_Bio_Turn_OK_3"
sname_0285: .asciz "m_BGM_Bio_Turn_NG_1"
sname_0286: .asciz "m_BGM_Bio_Turn_NG_2"
sname_0287: .asciz "m_BGM_Bio_Turn_NG_3"
sname_0288: .asciz "m_BGM_Bio_Turn_NEXT_1"
	.balign 4
sname_0289: .asciz "m_BGM_Bio_Turn_NEXT_2"
	.balign 4
sname_0290: .asciz "m_BGM_Bio_Turn_NEXT_3"
	.balign 4
sname_0291: .asciz "m_BGM_Bio_BOSS_FF_Start"
sname_0292: .asciz "m_BGM_Bio_BOSS_10"
	.balign 4
sname_0293: .asciz "m_BGM_Bio_END"
	.balign 4
sname_0294: .asciz "m_BGM_Bio_END_01"
	.balign 4
sname_0295: .asciz "m_BGM_Bio_Demo_EP_1"
sname_0296: .asciz "s_BASIC_PAUSE_ON"
	.balign 4
sname_0297: .asciz "s_BASIC_PAUSE_OFF"
	.balign 4
sname_0298: .asciz "s_BASIC_CURSOR_01"
	.balign 4
sname_0299: .asciz "s_BASIC_CURSOR_02"
	.balign 4
sname_0300: .asciz "s_BASIC_BUTTON_A"
	.balign 4
sname_0301: .asciz "s_BASIC_BUTTON_A1"
	.balign 4
sname_0302: .asciz "s_BASIC_BUTTON_A2"
	.balign 4
sname_0303: .asciz "s_BASIC_BUTTON_As1"
	.balign 4
sname_0304: .asciz "s_BASIC_BUTTON_As2"
	.balign 4
sname_0305: .asciz "s_BASIC_BUTTON_A_Delete"
sname_0306: .asciz "s_BASIC_BUTTON_B"
	.balign 4
sname_0307: .asciz "s_BASIC_BUTTON_Bs"
	.balign 4
sname_0308: .asciz "s_BASIC_DAME_1"
	.balign 4
sname_0309: .asciz "s_BOMB_Window_Change"
	.balign 4
sname_0310: .asciz "s_BOMB_Window_Change_2"
	.balign 4
sname_0311: .asciz "s_Demo_Title_BUMP"
	.balign 4
sname_0312: .asciz "s_BOMB_Door_Open"
	.balign 4
sname_0313: .asciz "s_BOMB_Door_Close"
	.balign 4
sname_0314: .asciz "s_BOMB_END_OFF_1"
	.balign 4
sname_0315: .asciz "s_Demo_1UP_01"
	.balign 4
sname_0316: .asciz "s_BOMB_BOSS_BOXING_Wind_1"
	.balign 4
sname_0317: .asciz "s_BOMB_BOSS_BOXING_Wind_2"
	.balign 4
sname_0318: .asciz "s_BOMB_BOSS_BOXING_Wind_3"
	.balign 4
sname_0319: .asciz "s_BOMB_BOSS_BOXING_Punch_1"
	.balign 4
sname_0320: .asciz "s_BOMB_BOSS_BOXING_Punch_2"
	.balign 4
sname_0321: .asciz "s_BOMB_BOSS_BOXING_Punch_3"
	.balign 4
sname_0322: .asciz "s_BOMB_BOSS_BOXING_OK_01"
	.balign 4
sname_0323: .asciz "s_BOMB_BOSS_BOXING_OK_02"
	.balign 4
sname_0324: .asciz "s_BOMB_BOSS_BOXING_OK_03"
	.balign 4
sname_0325: .asciz "s_BOMB_BOSS_BOXING_NG_01"
	.balign 4
sname_0326: .asciz "s_BOMB_BOSS_BOXING_NG_02"
	.balign 4
sname_0327: .asciz "s_BOMB_BOSS_BOXING_NG_03"
	.balign 4
sname_0328: .asciz "s_BOMB_BOSS_BOXING_Power_1"
	.balign 4
sname_0329: .asciz "s_BOMB_BOSS_BOXING_Power_2"
	.balign 4
sname_0330: .asciz "s_BOMB_BOSS_BOXING_WIN"
	.balign 4
sname_0331: .asciz "s_BOMB_BOSS_BOXING_LOSE"
sname_0332: .asciz "s_BOMB_BOSS_BOXING_GONG"
sname_0333: .asciz "s_BOMB_BOSS_BOXING_Hit_01"
	.balign 4
sname_0334: .asciz "s_BOMB_BOSS_BOXING_Hit_02"
	.balign 4
sname_0335: .asciz "s_BOMB_BOSS_BOXING_Hit_03"
	.balign 4
sname_0336: .asciz "s_BOMB_BOSS_BOXING_Hit_04"
	.balign 4
sname_0337: .asciz "s_BOMB_BOSS_BOXING_Hit_05"
	.balign 4
sname_0338: .asciz "s_BOMB_BOSS_BOXING_Hit_06"
	.balign 4
sname_0339: .asciz "s_BOMB_BOSS_BOXING_Hit_07"
	.balign 4
sname_0340: .asciz "s_BOMB_BOSS_BOXING_Hit_08"
	.balign 4
sname_0341: .asciz "s_BOMB_BOSS_Nail_FALL_0"
sname_0342: .asciz "s_BOMB_BOSS_Nail_FALL_1"
sname_0343: .asciz "s_BOMB_BOSS_Nail_ON_1"
	.balign 4
sname_0344: .asciz "s_BOMB_BOSS_Nail_Hit_OK_1"
	.balign 4
sname_0345: .asciz "s_BOMB_BOSS_Nail_Hit_L_1"
	.balign 4
sname_0346: .asciz "s_BOMB_BOSS_Nail_Hit_R_1"
	.balign 4
sname_0347: .asciz "s_BOMB_BOSS_Nail_NG_1"
	.balign 4
sname_0348: .asciz "s_BOMB_BOSS_Nail_Finish_1"
	.balign 4
sname_0349: .asciz "s_BOMB_BOSS_BaseB_Cheer_1"
	.balign 4
sname_0350: .asciz "s_BOMB_BOSS_BaseB_Cheer_2"
	.balign 4
sname_0351: .asciz "s_BOMB_BOSS_BaseB_Boo_1"
sname_0352: .asciz "s_BOMB_BOSS_BaseB_Boo_2"
sname_0353: .asciz "s_BOMB_BOSS_BaseB_Miss_1"
	.balign 4
sname_0354: .asciz "s_BOMB_BOSS_BaseB_Miss_2"
	.balign 4
sname_0355: .asciz "s_BOMB_BOSS_BaseB_ReSet"
sname_0356: .asciz "s_BOMB_BOSS_Galala_Shot_01"
	.balign 4
sname_0357: .asciz "s_BOMB_BOSS_Galala_Hit_01"
	.balign 4
sname_0358: .asciz "s_BOMB_BOSS_Galala_Hit_02"
	.balign 4
sname_0359: .asciz "s_BOMB_BOSS_Galala_Hit_03"
	.balign 4
sname_0360: .asciz "s_BOMB_BOSS_Galala_Hit_04"
	.balign 4
sname_0361: .asciz "s_BOMB_BOSS_Galala_CORE_02"
	.balign 4
sname_0362: .asciz "s_BOMB_BOSS_Galala_CORE_03"
	.balign 4
sname_0363: .asciz "s_BOMB_BOSS_Galala_Hole_01"
	.balign 4
sname_0364: .asciz "s_BOMB_BOSS_Galala_Bonus"
	.balign 4
sname_0365: .asciz "s_BOMB_BOSS_Galala_ITEM_01"
	.balign 4
sname_0366: .asciz "s_BOMB_BOSS_Galala_OK_01"
	.balign 4
sname_0367: .asciz "s_BOMB_BOSS_Galala_Fail_01"
	.balign 4
sname_0368: .asciz "s_BOMB_BOSS_Galala_Barrier"
	.balign 4
sname_0369: .asciz "s_BOMB_BOSS_Goma_FALL_0"
sname_0370: .asciz "s_BOMB_BOSS_Goma_FALL_9"
sname_0371: .asciz "s_BOMB_BOSS_Goma_JUMP_1"
sname_0372: .asciz "s_BOMB_BOSS_Goma_Walk_1"
sname_0373: .asciz "s_BOMB_BOSS_Goma_Walk_2"
sname_0374: .asciz "s_BOMB_BOSS_Goma_Walk_3"
sname_0375: .asciz "s_BOMB_BOSS_Goma_ITEM_1"
sname_0376: .asciz "s_BOMB_BOSS_Draran_Hit_1"
	.balign 4
sname_0377: .asciz "s_BOMB_BOSS_Draran_Hit_2"
	.balign 4
sname_0378: .asciz "s_BOMB_BOSS_Draran_Hit_3"
	.balign 4
sname_0379: .asciz "s_BOMB_BOSS_Draran_Damage_1"
sname_0380: .asciz "s_BOMB_BOSS_Earthquake"
	.balign 4
sname_0381: .asciz "s_Demo_DraBuru_Wiper_1_1"
	.balign 4
sname_0382: .asciz "s_Demo_DraBuru_Wiper_1_2"
	.balign 4
sname_0383: .asciz "s_Demo_DraBuru_Wiper_2_1"
	.balign 4
sname_0384: .asciz "s_Demo_DraBuru_Wiper_2_2"
	.balign 4
sname_0385: .asciz "s_Demo_Dra_CountDown_3"
	.balign 4
sname_0386: .asciz "s_Demo_Dra_CountDown_2"
	.balign 4
sname_0387: .asciz "s_Demo_Dra_CountDown_1"
	.balign 4
sname_0388: .asciz "s_Demo_DraBuru_EP_Car"
	.balign 4
sname_0389: .asciz "s_Demo_DraBuru_EP_Change"
	.balign 4
sname_0390: .asciz "s_Demo_Monna_Bird_01"
	.balign 4
sname_0391: .asciz "s_Demo_Monna_Bird_02"
	.balign 4
sname_0392: .asciz "s_Demo_Monna_Walk_01"
	.balign 4
sname_0393: .asciz "s_Demo_Monna_Walk_02"
	.balign 4
sname_0394: .asciz "s_Demo_Monna_Shutter_01"
sname_0395: .asciz "s_Demo_Monna_Slide_01"
	.balign 4
sname_0396: .asciz "s_Demo_Monna_KACHA_01"
	.balign 4
sname_0397: .asciz "s_Demo_Monna_Goggles_01"
sname_0398: .asciz "s_Demo_Mon_CountDown_3"
	.balign 4
sname_0399: .asciz "s_Demo_Mon_CountDown_2"
	.balign 4
sname_0400: .asciz "s_Demo_Mon_CountDown_1"
	.balign 4
sname_0401: .asciz "s_Demo_Mon_GameOver"
sname_0402: .asciz "s_Demo_Monna_EP_Bike"
	.balign 4
sname_0403: .asciz "s_Demo_Monna_EP_Clock"
	.balign 4
sname_0404: .asciz "s_Demo_AFRO_Tel_Catch"
	.balign 4
sname_0405: .asciz "s_Demo_AFRO_CountDown_1"
sname_0406: .asciz "s_Demo_AFRO_CountDown_2"
sname_0407: .asciz "s_Demo_AFRO_CountDown_3"
sname_0408: .asciz "s_Demo_Bio_Crash_1"
	.balign 4
sname_0409: .asciz "s_Demo_Bio_CountDown_3"
	.balign 4
sname_0410: .asciz "s_Demo_Bio_CountDown_2"
	.balign 4
sname_0411: .asciz "s_Demo_Bio_CountDown_1"
	.balign 4
sname_0412: .asciz "s_Demo_KAEDE_Open_1"
sname_0413: .asciz "s_Demo_KAEDE_Go_1"
	.balign 4
sname_0414: .asciz "s_Demo_KAEDE_KATANA_1"
	.balign 4
sname_0415: .asciz "s_Demo_KAEDE_TEKI_UP"
	.balign 4
sname_0416: .asciz "s_Demo_KAEDE_CountDown_3"
	.balign 4
sname_0417: .asciz "s_Demo_KAEDE_CountDown_2"
	.balign 4
sname_0418: .asciz "s_Demo_KAEDE_CountDown_1"
	.balign 4
sname_0419: .asciz "s_Demo_KAEDE_EP_STEP"
	.balign 4
sname_0420: .asciz "s_Demo_KAEDE_EP_Voice"
	.balign 4
sname_0421: .asciz "s_Demo_KAEDE_KATANA_2"
	.balign 4
sname_0422: .asciz "s_Demo_KAEDE_TEKI_Laugh_1"
	.balign 4
sname_0423: .asciz "s_Demo_KAEDE_EP_Jump"
	.balign 4
sname_0424: .asciz "s_Demo_Loo_Paper_1"
	.balign 4
sname_0425: .asciz "s_Demo_Loo_Water_OUT_1"
	.balign 4
sname_0426: .asciz "s_Demo_Loo_Water_IN_1"
	.balign 4
sname_0427: .asciz "s_Demo_Loo_Flap"
sname_0428: .asciz "s_Demo_Loo_CountDown_3"
	.balign 4
sname_0429: .asciz "s_Demo_Loo_CountDown_2"
	.balign 4
sname_0430: .asciz "s_Demo_Loo_CountDown_1"
	.balign 4
sname_0431: .asciz "s_Demo_Loo_EP_Water_JET_1"
	.balign 4
sname_0432: .asciz "s_Demo_Loo_EP_Water_JET_2"
	.balign 4
sname_0433: .asciz "s_Demo_Loo_EP_Rocket"
	.balign 4
sname_0434: .asciz "s_Demo_Loo_EP_FALL_01"
	.balign 4
sname_0435: .asciz "s_Demo_Loo_EP_Bird_01"
	.balign 4
sname_0436: .asciz "s_Demo_Loo_EP_Swim_01"
	.balign 4
sname_0437: .asciz "s_Demo_Voya_CountDown_3"
sname_0438: .asciz "s_Demo_Voya_CountDown_2"
sname_0439: .asciz "s_Demo_Voya_CountDown_1"
sname_0440: .asciz "s_Demo_Voya_EP_BOARD_1"
	.balign 4
sname_0441: .asciz "s_Demo_Wario_CountDown_3"
	.balign 4
sname_0442: .asciz "s_Demo_Wario_CountDown_2"
	.balign 4
sname_0443: .asciz "s_Demo_Wario_CountDown_1"
	.balign 4
sname_0444: .asciz "s_Demo_Wario_EP_Earthquake"
	.balign 4
sname_0445: .asciz "s_Demo_Wario_EP_UP_Loo"
	.balign 4
sname_0446: .asciz "s_Demo_Wario_EP_UP_Wario"
	.balign 4
sname_0447: .asciz "s_BOMB_Success_01"
	.balign 4
sname_0448: .asciz "s_BOMB_OK_01"
	.balign 4
sname_0449: .asciz "s_BOMB_OK_02_Bamboo"
sname_0450: .asciz "s_BOMB_OK_03"
	.balign 4
sname_0451: .asciz "s_BOMB_OK_04"
	.balign 4
sname_0452: .asciz "s_BOMB_OK_05"
	.balign 4
sname_0453: .asciz "s_BOMB_OK_06"
	.balign 4
sname_0454: .asciz "s_BOMB_OK_07"
	.balign 4
sname_0455: .asciz "s_BOMB_OK_08"
	.balign 4
sname_0456: .asciz "s_BOMB_OK_09"
	.balign 4
sname_0457: .asciz "s_BOMB_OK_10_Suck_Apple"
sname_0458: .asciz "s_BOMB_OK_11_SPY"
	.balign 4
sname_0459: .asciz "s_BOMB_OK_12"
	.balign 4
sname_0460: .asciz "s_BOMB_OK_13"
	.balign 4
sname_0461: .asciz "s_BOMB_OK_14"
	.balign 4
sname_0462: .asciz "s_BOMB_OK_15"
	.balign 4
sname_0463: .asciz "s_BOMB_OK_17"
	.balign 4
sname_0464: .asciz "s_BOMB_OK_19"
	.balign 4
sname_0465: .asciz "s_BOMB_OK_20"
	.balign 4
sname_0466: .asciz "s_BOMB_OK_21"
	.balign 4
sname_0467: .asciz "s_BOMB_OK_22"
	.balign 4
sname_0468: .asciz "s_BOMB_OK_23"
	.balign 4
sname_0469: .asciz "s_BOMB_OK_24"
	.balign 4
sname_0470: .asciz "s_BOMB_OK_25"
	.balign 4
sname_0471: .asciz "s_BOMB_OK_26"
	.balign 4
sname_0472: .asciz "s_BOMB_OK_27"
	.balign 4
sname_0473: .asciz "s_BOMB_OK_28"
	.balign 4
sname_0474: .asciz "s_BOMB_OK_29"
	.balign 4
sname_0475: .asciz "s_BOMB_OK_30"
	.balign 4
sname_0476: .asciz "s_BOMB_OK_31"
	.balign 4
sname_0477: .asciz "s_BOMB_OK_32"
	.balign 4
sname_0478: .asciz "s_BOMB_OK_33"
	.balign 4
sname_0479: .asciz "s_BOMB_OK_34"
	.balign 4
sname_0480: .asciz "s_BOMB_OK_35"
	.balign 4
sname_0481: .asciz "s_BOMB_OK_36"
	.balign 4
sname_0482: .asciz "s_BOMB_OK_37"
	.balign 4
sname_0483: .asciz "s_BOMB_OK_38"
	.balign 4
sname_0484: .asciz "s_BOMB_OK_39"
	.balign 4
sname_0485: .asciz "s_BOMB_OK_40"
	.balign 4
sname_0486: .asciz "s_BOMB_OK_41"
	.balign 4
sname_0487: .asciz "s_BOMB_OK_42"
	.balign 4
sname_0488: .asciz "s_BOMB_OK_43"
	.balign 4
sname_0489: .asciz "s_BOMB_OK_44"
	.balign 4
sname_0490: .asciz "s_BOMB_OK_45"
	.balign 4
sname_0491: .asciz "s_BOMB_OK_46"
	.balign 4
sname_0492: .asciz "s_BOMB_Fail_01"
	.balign 4
sname_0493: .asciz "s_BOMB_Fail_02"
	.balign 4
sname_0494: .asciz "s_BOMB_Fail_03"
	.balign 4
sname_0495: .asciz "s_BOMB_Fail_04"
	.balign 4
sname_0496: .asciz "s_BOMB_Fail_05"
	.balign 4
sname_0497: .asciz "s_BOMB_Fail_06"
	.balign 4
sname_0498: .asciz "s_BOMB_Fail_07"
	.balign 4
sname_0499: .asciz "s_BOMB_Fail_08"
	.balign 4
sname_0500: .asciz "s_BOMB_Fail_09"
	.balign 4
sname_0501: .asciz "s_BOMB_Fail_10"
	.balign 4
sname_0502: .asciz "s_BOMB_Fail_11"
	.balign 4
sname_0503: .asciz "s_BOMB_Fail_12"
	.balign 4
sname_0504: .asciz "s_BOMB_Fail_13"
	.balign 4
sname_0505: .asciz "s_BOMB_Fail_14"
	.balign 4
sname_0506: .asciz "s_BOMB_Fail_15"
	.balign 4
sname_0507: .asciz "s_BOMB_Fail_16"
	.balign 4
sname_0508: .asciz "s_BOMB_Fail_17"
	.balign 4
sname_0509: .asciz "s_BOMB_Fail_18"
	.balign 4
sname_0510: .asciz "s_BOMB_Fail_19_AIR"
	.balign 4
sname_0511: .asciz "s_BOMB_Fail_20"
	.balign 4
sname_0512: .asciz "s_BOMB_Fail_21"
	.balign 4
sname_0513: .asciz "s_BOMB_Fail_22"
	.balign 4
sname_0514: .asciz "s_BOMB_Fail_23"
	.balign 4
sname_0515: .asciz "s_BOMB_Fail_24"
	.balign 4
sname_0516: .asciz "s_BOMB_Fail_25"
	.balign 4
sname_0517: .asciz "s_BOMB_Fail_26"
	.balign 4
sname_0518: .asciz "s_BOMB_Fail_27"
	.balign 4
sname_0519: .asciz "s_BOMB_Fail_28"
	.balign 4
sname_0520: .asciz "s_BOMB_Fail_29"
	.balign 4
sname_0521: .asciz "s_BOMB_Fail_30"
	.balign 4
sname_0522: .asciz "s_BOMB_Fail_31"
	.balign 4
sname_0523: .asciz "s_BOMB_Fail_32"
	.balign 4
sname_0524: .asciz "s_BOMB_Fail_34"
	.balign 4
sname_0525: .asciz "s_BOMB_Fail_35"
	.balign 4
sname_0526: .asciz "s_BOMB_Fail_36"
	.balign 4
sname_0527: .asciz "s_BOMB_Fail_37"
	.balign 4
sname_0528: .asciz "s_BOMB_Fail_38"
	.balign 4
sname_0529: .asciz "s_BOMB_Fail_39"
	.balign 4
sname_0530: .asciz "s_BOMB_Fail_40"
	.balign 4
sname_0531: .asciz "s_BOMB_Fail_41"
	.balign 4
sname_0532: .asciz "s_BOMB_Fail_42"
	.balign 4
sname_0533: .asciz "s_BOMB_Fail_43"
	.balign 4
sname_0534: .asciz "s_BOMB_Fail_44"
	.balign 4
sname_0535: .asciz "s_BOMB_Fail_45"
	.balign 4
sname_0536: .asciz "s_BOMB_Fail_46"
	.balign 4
sname_0537: .asciz "s_BOMB_Fail_47"
	.balign 4
sname_0538: .asciz "s_BOMB_Fail_48"
	.balign 4
sname_0539: .asciz "s_BOMB_Shot_01"
	.balign 4
sname_0540: .asciz "s_BOMB_Shot_02"
	.balign 4
sname_0541: .asciz "s_BOMB_Shot_03"
	.balign 4
sname_0542: .asciz "s_BOMB_Shot_04"
	.balign 4
sname_0543: .asciz "s_BOMB_Shot_05"
	.balign 4
sname_0544: .asciz "s_BOMB_Shot_06"
	.balign 4
sname_0545: .asciz "s_BOMB_Shot_07"
	.balign 4
sname_0546: .asciz "s_BOMB_Shot_08"
	.balign 4
sname_0547: .asciz "s_BOMB_Shot_09"
	.balign 4
sname_0548: .asciz "s_BOMB_Shot_10"
	.balign 4
sname_0549: .asciz "s_BOMB_Shot_11"
	.balign 4
sname_0550: .asciz "s_BOMB_Shot_12"
	.balign 4
sname_0551: .asciz "s_BOMB_Shot_13"
	.balign 4
sname_0552: .asciz "s_BOMB_Shot_14"
	.balign 4
sname_0553: .asciz "s_BOMB_Shot_15"
	.balign 4
sname_0554: .asciz "s_BOMB_Shot_16"
	.balign 4
sname_0555: .asciz "s_BOMB_Bomb_01"
	.balign 4
sname_0556: .asciz "s_BOMB_Bomb_02"
	.balign 4
sname_0557: .asciz "s_BOMB_Bomb_03"
	.balign 4
sname_0558: .asciz "s_BOMB_Bomb_04"
	.balign 4
sname_0559: .asciz "s_BOMB_Bomb_05"
	.balign 4
sname_0560: .asciz "s_BOMB_Bomb_06"
	.balign 4
sname_0561: .asciz "s_BOMB_Bomb_07"
	.balign 4
sname_0562: .asciz "s_BOMB_Bomb_08"
	.balign 4
sname_0563: .asciz "s_BOMB_Bomb_09"
	.balign 4
sname_0564: .asciz "s_BOMB_Bomb_10"
	.balign 4
sname_0565: .asciz "s_BOMB_Bomb_11"
	.balign 4
sname_0566: .asciz "s_BOMB_Bomb_12"
	.balign 4
sname_0567: .asciz "s_BOMB_Bomb_13"
	.balign 4
sname_0568: .asciz "s_BOMB_Bomb_14"
	.balign 4
sname_0569: .asciz "s_BOMB_Bomb_15"
	.balign 4
sname_0570: .asciz "s_BOMB_FIRE_01"
	.balign 4
sname_0571: .asciz "s_BOMB_FIRE_02"
	.balign 4
sname_0572: .asciz "s_BOMB_JUMP_01"
	.balign 4
sname_0573: .asciz "s_BOMB_JUMP_02"
	.balign 4
sname_0574: .asciz "s_BOMB_JUMP_03_1"
	.balign 4
sname_0575: .asciz "s_BOMB_JUMP_03_2"
	.balign 4
sname_0576: .asciz "s_BOMB_JUMP_03_3"
	.balign 4
sname_0577: .asciz "s_BOMB_JUMP_04"
	.balign 4
sname_0578: .asciz "s_BOMB_JUMP_05"
	.balign 4
sname_0579: .asciz "s_BOMB_JUMP_06"
	.balign 4
sname_0580: .asciz "s_BOMB_JUMP_07"
	.balign 4
sname_0581: .asciz "s_BOMB_JUMP_08"
	.balign 4
sname_0582: .asciz "s_BOMB_JUMP_09"
	.balign 4
sname_0583: .asciz "s_BOMB_JUMP_10"
	.balign 4
sname_0584: .asciz "s_BOMB_JUMP_11"
	.balign 4
sname_0585: .asciz "s_BOMB_JUMP_12"
	.balign 4
sname_0586: .asciz "s_BOMB_JUMP_13"
	.balign 4
sname_0587: .asciz "s_BOMB_FALL_01"
	.balign 4
sname_0588: .asciz "s_BOMB_FALL_02"
	.balign 4
sname_0589: .asciz "s_BOMB_FALL_03"
	.balign 4
sname_0590: .asciz "s_BOMB_FALL_04"
	.balign 4
sname_0591: .asciz "s_BOMB_FALL_05"
	.balign 4
sname_0592: .asciz "s_BOMB_FALL_06"
	.balign 4
sname_0593: .asciz "s_BOMB_FALL_07"
	.balign 4
sname_0594: .asciz "s_BOMB_FALL_08"
	.balign 4
sname_0595: .asciz "s_BOMB_FALL_09"
	.balign 4
sname_0596: .asciz "s_BOMB_Catch_OK_01"
	.balign 4
sname_0597: .asciz "s_BOMB_Catch_OK_02"
	.balign 4
sname_0598: .asciz "s_BOMB_Catch_OK_03"
	.balign 4
sname_0599: .asciz "s_BOMB_Catch_OK_04"
	.balign 4
sname_0600: .asciz "s_BOMB_Catch_OK_041"
sname_0601: .asciz "s_BOMB_Catch_OK_05"
	.balign 4
sname_0602: .asciz "s_BOMB_Catch_OK_06"
	.balign 4
sname_0603: .asciz "s_BOMB_Catch_BAD_01"
sname_0604: .asciz "s_BOMB_Catch_BAD_02"
sname_0605: .asciz "s_BOMB_PI_01"
	.balign 4
sname_0606: .asciz "s_BOMB_PI_02"
	.balign 4
sname_0607: .asciz "s_BOMB_PI_03"
	.balign 4
sname_0608: .asciz "s_BOMB_PI_04_E2"
sname_0609: .asciz "s_BOMB_PI_05_G2"
sname_0610: .asciz "s_BOMB_PI_06_A2"
sname_0611: .asciz "s_BOMB_PI_07_C3"
sname_0612: .asciz "s_BOMB_PI_08_E3"
sname_0613: .asciz "s_BOMB_PI_09"
	.balign 4
sname_0614: .asciz "s_BOMB_PI_10_1"
	.balign 4
sname_0615: .asciz "s_BOMB_PI_10_2"
	.balign 4
sname_0616: .asciz "s_BOMB_PI_10_3"
	.balign 4
sname_0617: .asciz "s_BOMB_PI_10_4"
	.balign 4
sname_0618: .asciz "s_BOMB_PI_11"
	.balign 4
sname_0619: .asciz "s_BOMB_PI_12"
	.balign 4
sname_0620: .asciz "s_BOMB_PI_13"
	.balign 4
sname_0621: .asciz "s_BOMB_PI_14"
	.balign 4
sname_0622: .asciz "s_BOMB_PI_15"
	.balign 4
sname_0623: .asciz "s_BOMB_PI_16"
	.balign 4
sname_0624: .asciz "s_BOMB_PI_17"
	.balign 4
sname_0625: .asciz "s_BOMB_PI_18"
	.balign 4
sname_0626: .asciz "s_BOMB_PI_19"
	.balign 4
sname_0627: .asciz "s_BOMB_PI_20"
	.balign 4
sname_0628: .asciz "s_BOMB_PI_21"
	.balign 4
sname_0629: .asciz "s_BOMB_Landing_01"
	.balign 4
sname_0630: .asciz "s_BOMB_Landing_02_OK"
	.balign 4
sname_0631: .asciz "s_BOMB_Landing_02_NG"
	.balign 4
sname_0632: .asciz "s_BOMB_Landing_03"
	.balign 4
sname_0633: .asciz "s_BOMB_Landing_03_OK"
	.balign 4
sname_0634: .asciz "s_BOMB_Landing_04"
	.balign 4
sname_0635: .asciz "s_BOMB_Curve_01"
sname_0636: .asciz "s_BOMB_Sweep_01"
sname_0637: .asciz "s_BOMB_Sweep_02"
sname_0638: .asciz "s_BOMB_Sweep_03"
sname_0639: .asciz "s_BOMB_Sweep_04"
sname_0640: .asciz "s_BOMB_PO_01"
	.balign 4
sname_0641: .asciz "s_BOMB_KALI_01"
	.balign 4
sname_0642: .asciz "s_BOMB_KALI_02"
	.balign 4
sname_0643: .asciz "s_BOMB_KALI_03"
	.balign 4
sname_0644: .asciz "s_BOMB_KALI_04"
	.balign 4
sname_0645: .asciz "s_BOMB_KALI_05"
	.balign 4
sname_0646: .asciz "s_BOMB_KALI_06"
	.balign 4
sname_0647: .asciz "s_BOMB_KALI_07"
	.balign 4
sname_0648: .asciz "s_BOMB_Bound_01"
sname_0649: .asciz "s_BOMB_Bound_02"
sname_0650: .asciz "s_BOMB_Bound_03"
sname_0651: .asciz "s_BOMB_Bound_04"
sname_0652: .asciz "s_BOMB_Bound_05"
sname_0653: .asciz "s_BOMB_Bound_06"
sname_0654: .asciz "s_BOMB_Bound_07"
sname_0655: .asciz "s_BOMB_Bound_08"
sname_0656: .asciz "s_BOMB_Push_01"
	.balign 4
sname_0657: .asciz "s_BOMB_Push_02"
	.balign 4
sname_0658: .asciz "s_BOMB_SMASH_02"
sname_0659: .asciz "s_BOMB_SMASH_03"
sname_0660: .asciz "s_BOMB_SMASH_04"
sname_0661: .asciz "s_BOMB_Throw_01"
sname_0662: .asciz "s_BOMB_Throw_02"
sname_0663: .asciz "s_BOMB_Throw_03"
sname_0664: .asciz "s_BOMB_Throw_04"
sname_0665: .asciz "s_BOMB_Throw_05"
sname_0666: .asciz "s_BOMB_v_Haa_01"
sname_0667: .asciz "s_BOMB_OUT_01"
	.balign 4
sname_0668: .asciz "s_BOMB_v_Ahh_01"
sname_0669: .asciz "s_BOMB_BUTTON_01"
	.balign 4
sname_0670: .asciz "s_BOMB_BUTTON_02"
	.balign 4
sname_0671: .asciz "s_BOMB_Combine_01"
	.balign 4
sname_0672: .asciz "s_BOMB_Combine_02"
	.balign 4
sname_0673: .asciz "s_BOMB_Bowling_Throw_01"
sname_0674: .asciz "s_BOMB_Bowling_Gater"
	.balign 4
sname_0675: .asciz "s_BOMB_Bowling_HIT_01"
	.balign 4
sname_0676: .asciz "s_BOMB_Bowling_HIT_ALL"
	.balign 4
sname_0677: .asciz "s_BOMB_WAVE_01"
	.balign 4
sname_0678: .asciz "s_BOMB_WAVE_02"
	.balign 4
sname_0679: .asciz "s_BOMB_SAW_01"
	.balign 4
sname_0680: .asciz "s_BOMB_SAW_02"
	.balign 4
sname_0681: .asciz "s_BOMB_Water_01"
sname_0682: .asciz "s_BOMB_Water_02"
sname_0683: .asciz "s_BOMB_Water_03"
sname_0684: .asciz "s_BOMB_Count_01"
sname_0685: .asciz "s_BOMB_PAD_01"
	.balign 4
sname_0686: .asciz "s_BOMB_Archery_Shot_01"
	.balign 4
sname_0687: .asciz "s_BOMB_Uproot_01"
	.balign 4
sname_0688: .asciz "s_BOMB_Revolve_01"
	.balign 4
sname_0689: .asciz "s_BOMB_Brush_01"
sname_0690: .asciz "s_BOMB_Flower_Water_01"
	.balign 4
sname_0691: .asciz "s_BOMB_Please_01"
	.balign 4
sname_0692: .asciz "s_BOMB_CAMERA_Shutter_01"
	.balign 4
sname_0693: .asciz "s_BOMB_CAMERA_PRINT_01"
	.balign 4
sname_0694: .asciz "s_BOMB_CAMERA_PRINT_02"
	.balign 4
sname_0695: .asciz "s_BOMB_Jet_01"
	.balign 4
sname_0696: .asciz "s_BOMB_Pour_01"
	.balign 4
sname_0697: .asciz "s_BOMB_Turn_01"
	.balign 4
sname_0698: .asciz "s_BOMB_START_01"
sname_0699: .asciz "s_BOMB_Suck_Body"
	.balign 4
sname_0700: .asciz "s_BOMB_Page_Turn"
	.balign 4
sname_0701: .asciz "s_BOMB_Page_MARK"
	.balign 4
sname_0702: .asciz "s_BOMB_Trampoline_JUMP_2"
	.balign 4
sname_0703: .asciz "s_BOMB_Trampoline_JUMP_3"
	.balign 4
sname_0704: .asciz "s_BOMB_CURSOR_01"
	.balign 4
sname_0705: .asciz "s_BOMB_Fly_01"
	.balign 4
sname_0706: .asciz "s_BOMB_BIG_01"
	.balign 4
sname_0707: .asciz "s_BOMB_Rotate_01"
	.balign 4
sname_0708: .asciz "s_BOMB_AIR_ON"
	.balign 4
sname_0709: .asciz "s_BOMB_AIR_OFF"
	.balign 4
sname_0710: .asciz "s_BOMB_CAR_01"
	.balign 4
sname_0711: .asciz "s_BOMB_CAR_02"
	.balign 4
sname_0712: .asciz "s_BOMB_CAR_03"
	.balign 4
sname_0713: .asciz "s_BOMB_CAR_04"
	.balign 4
sname_0714: .asciz "s_BOMB_CAR_05"
	.balign 4
sname_0715: .asciz "s_BOMB_CAR_06"
	.balign 4
sname_0716: .asciz "s_BOMB_CAR_07"
	.balign 4
sname_0717: .asciz "s_BOMB_CAR_08"
	.balign 4
sname_0718: .asciz "s_BOMB_CAR_Back_01"
	.balign 4
sname_0719: .asciz "s_BOMB_CAR_Bend"
sname_0720: .asciz "s_BOMB_CAR_Back_NG_01"
	.balign 4
sname_0721: .asciz "s_BOMB_CAR_Crash_01"
sname_0722: .asciz "s_BOMB_WARP_01"
	.balign 4
sname_0723: .asciz "s_BOMB_v_CHYOKI"
sname_0724: .asciz "s_BOMB_Change_01"
	.balign 4
sname_0725: .asciz "s_BOMB_GOLF_CupIn_01"
	.balign 4
sname_0726: .asciz "s_wario_JUMP_1"
	.balign 4
sname_0727: .asciz "s_wario_DIE"
sname_0728: .asciz "s_BOMB_Nose_01"
	.balign 4
sname_0729: .asciz "s_BOMB_Nose_02"
	.balign 4
sname_0730: .asciz "s_BOMB_Nose_03"
	.balign 4
sname_0731: .asciz "s_BOMB_Robot_UP"
sname_0732: .asciz "s_BOMB_Robot_DOWN"
	.balign 4
sname_0733: .asciz "s_BOMB_Robot_NIP"
	.balign 4
sname_0734: .asciz "s_BOMB_Robot_OK"
sname_0735: .asciz "s_BOMB_Robot_NG"
sname_0736: .asciz "s_BOMB_NIP_01"
	.balign 4
sname_0737: .asciz "s_BOMB_Whistle_01"
	.balign 4
sname_0738: .asciz "s_BOMB_Dog_Bow_01"
	.balign 4
sname_0739: .asciz "s_BOMB_Get_01"
	.balign 4
sname_0740: .asciz "s_BOMB_Get_02"
	.balign 4
sname_0741: .asciz "s_BOMB_FootStep_01"
	.balign 4
sname_0742: .asciz "s_BOMB_FootStep_02"
	.balign 4
sname_0743: .asciz "s_BOMB_FootStep_03"
	.balign 4
sname_0744: .asciz "s_BOMB_FootStep_04"
	.balign 4
sname_0745: .asciz "s_BOMB_Damage_01"
	.balign 4
sname_0746: .asciz "s_BOMB_BUMP_01"
	.balign 4
sname_0747: .asciz "s_BOMB_BUMP_02"
	.balign 4
sname_0748: .asciz "s_BOMB_BUMP_03"
	.balign 4
sname_0749: .asciz "s_BOMB_Filter_01"
	.balign 4
sname_0750: .asciz "s_BOMB_wario_B_Attack"
	.balign 4
sname_0751: .asciz "s_BOMB_wario_BLOCK_Break_1"
	.balign 4
sname_0752: .asciz "s_BOMB_wario_Hip_Attack_S"
	.balign 4
sname_0753: .asciz "s_BOMB_Lizard_Tongue"
	.balign 4
sname_0754: .asciz "s_BOMB_STOP_01"
	.balign 4
sname_0755: .asciz "s_BOMB_STOP_02_CAR"
	.balign 4
sname_0756: .asciz "s_BOMB_Frog_HIT"
sname_0757: .asciz "s_BOMB_Frog_SWIM"
	.balign 4
sname_0758: .asciz "s_BOMB_Mario_Step_ON_1"
	.balign 4
sname_0759: .asciz "s_BOMB_Mario_Step_ON_2"
	.balign 4
sname_0760: .asciz "s_BOMB_Mario_Step_ON_3"
	.balign 4
sname_0761: .asciz "s_BOMB_Mario2_Step_ON_1"
sname_0762: .asciz "s_BOMB_Mario2_Step_ON_2"
sname_0763: .asciz "s_BOMB_Mario2_Step_ON_3"
sname_0764: .asciz "s_BOMB_Mario_Step_ON_END"
	.balign 4
sname_0765: .asciz "s_BOMB_Mario_Step_ON_END2"
	.balign 4
sname_0766: .asciz "s_BOMB_Tennis_Hit_0"
sname_0767: .asciz "s_BOMB_Tennis_Hit_1"
sname_0768: .asciz "s_BOMB_Tennis_Hit_2"
sname_0769: .asciz "s_BOMB_Move_01"
	.balign 4
sname_0770: .asciz "s_BOMB_AIR_01"
	.balign 4
sname_0771: .asciz "s_BOMB_AIR_02"
	.balign 4
sname_0772: .asciz "s_BOMB_Ele_01"
	.balign 4
sname_0773: .asciz "s_BOMB_Ele_02"
	.balign 4
sname_0774: .asciz "s_BOMB_Ele_03"
	.balign 4
sname_0775: .asciz "s_BOMB_Ele_04"
	.balign 4
sname_0776: .asciz "s_BOMB_Ele_05"
	.balign 4
sname_0777: .asciz "s_BOMB_Ele_06"
	.balign 4
sname_0778: .asciz "s_BOMB_v_1"
	.balign 4
sname_0779: .asciz "s_BOMB_v_2"
	.balign 4
sname_0780: .asciz "s_BOMB_v_3"
	.balign 4
sname_0781: .asciz "s_BOMB_Beat_Tel_03"
	.balign 4
sname_0782: .asciz "s_BOMB_Beat_Tel_04"
	.balign 4
sname_0783: .asciz "s_BOMB_Beat_Tel_05"
	.balign 4
sname_0784: .asciz "s_BOMB_Beat_Tel_06"
	.balign 4
sname_0785: .asciz "s_BOMB_Beat_Tel_07"
	.balign 4
sname_0786: .asciz "s_BOMB_GYORO_Walk_01"
	.balign 4
sname_0787: .asciz "s_BOMB_GYORO_Shot_TANE"
	.balign 4
sname_0788: .asciz "s_BOMB_GYORO_SHITA_Dasu"
sname_0789: .asciz "s_BOMB_GYORO_SHITA_Modosu"
	.balign 4
sname_0790: .asciz "s_BOMB_GYORO_ESA_Get"
	.balign 4
sname_0791: .asciz "s_BOMB_GYORO_Die_01"
sname_0792: .asciz "s_BOMB_GYORO_Die_Bean"
	.balign 4
sname_0793: .asciz "s_BOMB_GYORO_Die_Bean_2"
sname_0794: .asciz "s_BOMB_GYORO_Die_Bean_3"
sname_0795: .asciz "s_BOMB_GYORO_Die_Bean_4"
sname_0796: .asciz "s_BOMB_GYORO_BOMB_01"
	.balign 4
sname_0797: .asciz "s_BOMB_GYORO_Repair_Engel"
	.balign 4
sname_0798: .asciz "s_BOMB_GYORO_Repair_01"
	.balign 4
sname_0799: .asciz "s_BOMB_GYORO_Repair_02"
	.balign 4
sname_0800: .asciz "s_BOMB_GYORO_Repair_03"
	.balign 4
sname_0801: .asciz "s_BOMB_GYORO_Repair_04"
	.balign 4
sname_0802: .asciz "s_BOMB_GYORO_Repair_05"
	.balign 4
sname_0803: .asciz "s_BOMB_GYORO_STAR"
	.balign 4
sname_0804: .asciz "s_BOMB_Wind_01"
	.balign 4
sname_0805: .asciz "s_BOMB_Wind_02"
	.balign 4
sname_0806: .asciz "s_BOMB_Voice_MALE_03"
	.balign 4
sname_0807: .asciz "s_BOMB_Voice_MALE_04"
	.balign 4
sname_0808: .asciz "s_BOMB_Voice_MALE_05"
	.balign 4
sname_0809: .asciz "s_BOMB_Voice_MALE_06"
	.balign 4
sname_0810: .asciz "s_BOMB_Voice_MALE_07"
	.balign 4
sname_0811: .asciz "s_BOMB_Voice_MALE_08"
	.balign 4
sname_0812: .asciz "s_BOMB_Voice_MALE_09"
	.balign 4
sname_0813: .asciz "s_BOMB_Voice_MALE_10"
	.balign 4
sname_0814: .asciz "s_BOMB_Voice_MALE_11"
	.balign 4
sname_0815: .asciz "s_BOMB_Voice_MALE_12"
	.balign 4
sname_0816: .asciz "s_BOMB_Voice_MALE_13"
	.balign 4
sname_0817: .asciz "s_BOMB_Voice_FEMALE_01"
	.balign 4
sname_0818: .asciz "s_BOMB_Voice_FEMALE_02"
	.balign 4
sname_0819: .asciz "s_BOMB_Voice_FEMALE_03"
	.balign 4
sname_0820: .asciz "s_BOMB_Voice_Child_01"
	.balign 4
sname_0821: .asciz "s_BOMB_Voice_Child_02"
	.balign 4
sname_0822: .asciz "s_BOMB_Voice_Child_03"
	.balign 4
sname_0823: .asciz "s_BOMB_Voice_Sneeze_01"
	.balign 4
sname_0824: .asciz "s_BOMB_Voice_Sneeze_02"
	.balign 4
sname_0825: .asciz "s_BOMB_Voice_PON_01"
sname_0826: .asciz "s_BOMB_Voice_PON_02"
sname_0827: .asciz "s_BOMB_Voice_PON_03"
sname_0828: .asciz "s_BOMB_Voice_Frog_01"
	.balign 4
sname_0829: .asciz "s_BOMB_Voice_Cat_01"
sname_0830: .asciz "s_BOMB_Voice_TakoIka"
	.balign 4
sname_0831: .asciz "s_BOMB_Voice_Funkoro"
	.balign 4
sname_0832: .asciz "s_BOMB_Swing_02"
sname_0833: .asciz "s_BOMB_Swing_03"
sname_0834: .asciz "s_wario_TURN"
	.balign 4
sname_0835: .asciz "s_AFRO_BOMB_Burst"
	.balign 4
sname_0836: .asciz "s_BOMB_Fit_01"
	.balign 4
sname_0837: .asciz "s_BOMB_Hit_01"
	.balign 4
sname_0838: .asciz "s_BOMB_Hit_02"
	.balign 4
sname_0839: .asciz "s_BOMB_Hit_03"
	.balign 4
sname_0840: .asciz "s_BOMB_Hit_04"
	.balign 4
sname_0841: .asciz "s_BOMB_Hit_05"
	.balign 4
sname_0842: .asciz "s_BOMB_Hit_06"
	.balign 4
sname_0843: .asciz "s_BOMB_Hit_07"
	.balign 4
sname_0844: .asciz "s_BOMB_Hit_08"
	.balign 4
sname_0845: .asciz "s_BOMB_Hit_09"
	.balign 4
sname_0846: .asciz "s_BOMB_Hit_10"
	.balign 4
sname_0847: .asciz "s_BOMB_Hit_11"
	.balign 4
sname_0848: .asciz "s_BOMB_Hit_12"
	.balign 4
sname_0849: .asciz "s_BOMB_Hit_13"
	.balign 4
sname_0850: .asciz "s_BOMB_Hit_14"
	.balign 4
sname_0851: .asciz "s_BOMB_Music_CowBell"
	.balign 4
sname_0852: .asciz "s_BOMB_Music_Drum"
	.balign 4
sname_0853: .asciz "s_BOMB_Music_Guitar"
sname_0854: .asciz "s_BOMB_Music_Whistle"
	.balign 4
sname_0855: .asciz "s_BOMB_Music_ALL"
	.balign 4
sname_0856: .asciz "s_Drum_BD_1"
sname_0857: .asciz "s_Drum_SD_1"
sname_0858: .asciz "s_Drum_SD_Rim_Close"
sname_0859: .asciz "s_Drum_SD_Rim_Open"
	.balign 4
sname_0860: .asciz "s_Drum_SD_Roll"
	.balign 4
sname_0861: .asciz "s_Drum_Tom_1"
	.balign 4
sname_0862: .asciz "s_Drum_Sym_Crash"
	.balign 4
sname_0863: .asciz "s_Drum_Sym_Sprash"
	.balign 4
sname_0864: .asciz "s_x_NoSound"
sname_0865: .asciz "m_BGM_BOMB_01"
	.balign 4
sname_0866: .asciz "m_BGM_BOMB_02"
	.balign 4
sname_0867: .asciz "m_BGM_BOMB_03"
	.balign 4
sname_0868: .asciz "m_BGM_BOMB_04"
	.balign 4
sname_0869: .asciz "m_BGM_BOMB_05"
	.balign 4
sname_0870: .asciz "m_BGM_BOMB_06"
	.balign 4
sname_0871: .asciz "m_BGM_BOMB_07"
	.balign 4
sname_0872: .asciz "m_BGM_BOMB_08"
	.balign 4
sname_0873: .asciz "m_BGM_BOMB_09"
	.balign 4
sname_0874: .asciz "m_BGM_BOMB_10"
	.balign 4
sname_0875: .asciz "m_BGM_BOMB_11"
	.balign 4
sname_0876: .asciz "m_BGM_BOMB_12"
	.balign 4
sname_0877: .asciz "m_BGM_BOMB_13"
	.balign 4
sname_0878: .asciz "m_BGM_BOMB_14"
	.balign 4
sname_0879: .asciz "m_BGM_BOMB_15"
	.balign 4
sname_0880: .asciz "m_BGM_BOMB_16"
	.balign 4
sname_0881: .asciz "m_BGM_BOMB_17"
	.balign 4
sname_0882: .asciz "m_BGM_BOMB_18"
	.balign 4
sname_0883: .asciz "m_BGM_BOMB_19"
	.balign 4
sname_0884: .asciz "m_BGM_BOMB_20"
	.balign 4
sname_0885: .asciz "m_BGM_BOMB_21"
	.balign 4
sname_0886: .asciz "m_BGM_BOMB_22"
	.balign 4
sname_0887: .asciz "m_BGM_BOMB_23"
	.balign 4
sname_0888: .asciz "m_BGM_BOMB_24"
	.balign 4
sname_0889: .asciz "m_BGM_BOMB_25"
	.balign 4
sname_0890: .asciz "m_BGM_BOMB_26"
	.balign 4
sname_0891: .asciz "m_BGM_BOMB_27_Zelda1"
	.balign 4
sname_0892: .asciz "m_BGM_BOMB_28_DrMario"
	.balign 4
sname_0893: .asciz "m_BGM_BOMB_29_Donkey"
	.balign 4
sname_0894: .asciz "m_BGM_BOMB_30_MPaint"
	.balign 4
sname_0895: .asciz "m_BGM_BOMB_31_Mario"
sname_0896: .asciz "m_BGM_BOMB_32_Wario_01"
	.balign 4
sname_0897: .asciz "m_BGM_BOMB_33_Wario_02"
	.balign 4
sname_0898: .asciz "m_BGM_BOMB_34_Wario_03"
	.balign 4
sname_0899: .asciz "m_BGM_BOMB_35_0_1"
	.balign 4
sname_0900: .asciz "m_BGM_BOMB_35_0_2"
	.balign 4
sname_0901: .asciz "m_BGM_BOMB_35_1"
sname_0902: .asciz "m_BGM_BOMB_35_2"
sname_0903: .asciz "m_BGM_BOMB_36"
	.balign 4
sname_0904: .asciz "m_BGM_BOMB_37"
	.balign 4
sname_0905: .asciz "m_BGM_BOMB_38"
	.balign 4
sname_0906: .asciz "m_BGM_BOMB_39"
	.balign 4
sname_0907: .asciz "m_BGM_BOMB_40"
	.balign 4
sname_0908: .asciz "m_BGM_BOMB_41"
	.balign 4
sname_0909: .asciz "m_BGM_BOMB_42"
	.balign 4
sname_0910: .asciz "m_BGM_BOMB_43"
	.balign 4
sname_0911: .asciz "m_BGM_BOMB_44"
	.balign 4
sname_0912: .asciz "m_BGM_BOMB_45"
	.balign 4
sname_0913: .asciz "m_BGM_BOMB_46"
	.balign 4
sname_0914: .asciz "m_BGM_BOMB_47"
	.balign 4
sname_0915: .asciz "m_BGM_BOMB_48"
	.balign 4
sname_0916: .asciz "m_BGM_BOMB_50"
	.balign 4
sname_0917: .asciz "m_BGM_BOMB_51"
	.balign 4
sname_0918: .asciz "m_BGM_BOMB_52"
	.balign 4
sname_0919: .asciz "m_BGM_BOMB_53"
	.balign 4
sname_0920: .asciz "m_BGM_BOMB_54"
	.balign 4
sname_0921: .asciz "m_BGM_BOMB_55"
	.balign 4
sname_0922: .asciz "m_BGM_BOMB_56"
	.balign 4
sname_0923: .asciz "m_BGM_BOMB_57"
	.balign 4
sname_0924: .asciz "m_BGM_BOMB_58"
	.balign 4
sname_0925: .asciz "m_BGM_BOMB_59"
	.balign 4
sname_0926: .asciz "m_BGM_BOMB_60"
	.balign 4
sname_0927: .asciz "m_BGM_BOMB_61"
	.balign 4
sname_0928: .asciz "m_BGM_BOMB_62"
	.balign 4
sname_0929: .asciz "m_BGM_BOMB_63"
	.balign 4
sname_0930: .asciz "m_BGM_BOMB_64"
	.balign 4
sname_0931: .asciz "m_BGM_BOMB_65"
	.balign 4
sname_0932: .asciz "m_BGM_BOMB_66"
	.balign 4
sname_0933: .asciz "m_BGM_BOMB_67"
	.balign 4
sname_0934: .asciz "m_BGM_BOMB_68"
	.balign 4
sname_0935: .asciz "m_BGM_BOMB_69"
	.balign 4
sname_0936: .asciz "m_BGM_BOMB_70"
	.balign 4
sname_0937: .asciz "m_BGM_BOMB_71"
	.balign 4
sname_0938: .asciz "m_BGM_BOMB_72"
	.balign 4
sname_0939: .asciz "m_BGM_BOMB_73"
	.balign 4
sname_0940: .asciz "m_BGM_BOMB_74"
	.balign 4
sname_0941: .asciz "m_BGM_BOMB_75"
	.balign 4
sname_0942: .asciz "m_BGM_BOMB_76"
	.balign 4
sname_0943: .asciz "m_BGM_BOMB_77"
	.balign 4
sname_0944: .asciz "m_BGM_BOMB_78"
	.balign 4
sname_0945: .asciz "m_BGM_BOMB_79"
	.balign 4
sname_0946: .asciz "m_BGM_BOMB_80"
	.balign 4
sname_0947: .asciz "m_BGM_BOMB_81"
	.balign 4
sname_0948: .asciz "m_BGM_BOMB_82"
	.balign 4
sname_0949: .asciz "m_BGM_BOMB_83"
	.balign 4
sname_0950: .asciz "m_BGM_BOMB_84"
	.balign 4
sname_0951: .asciz "m_BGM_BOMB_85"
	.balign 4
sname_0952: .asciz "m_BGM_BOMB_86"
	.balign 4
sname_0953: .asciz "m_BGM_BOMB_87"
	.balign 4
sname_0954: .asciz "m_BGM_BOMB_88"
	.balign 4
sname_0955: .asciz "m_BGM_BOMB_89"
	.balign 4
sname_0956: .asciz "m_BGM_BOMB_90"
	.balign 4
sname_0957: .asciz "m_BGM_BOMB_91"
	.balign 4
sname_0958: .asciz "m_BGM_BOMB_92"
	.balign 4
sname_0959: .asciz "m_BGM_BOMB_93"
	.balign 4
sname_0960: .asciz "m_BGM_BOMB_94"
	.balign 4
sname_0961: .asciz "m_BGM_BOMB_95"
	.balign 4
sname_0962: .asciz "m_BGM_BOMB_96"
	.balign 4
sname_0963: .asciz "m_BGM_BOMB_97"
	.balign 4
sname_0964: .asciz "m_BGM_BOMB_98"
	.balign 4
sname_0965: .asciz "m_BGM_BOMB_99"
	.balign 4
sname_0966: .asciz "m_BGM_BOMB_100"
	.balign 4
sname_0967: .asciz "m_BGM_BOMB_101"
	.balign 4
sname_0968: .asciz "m_BGM_BOMB_102"
	.balign 4
sname_0969: .asciz "m_BGM_BOMB_103"
	.balign 4
sname_0970: .asciz "m_BGM_BOMB_Finish_1"
sname_0971: .asciz "m_BGM_BOMB_Finish_2"
sname_0972: .asciz "m_BGM_BOMB_REST_1"
	.balign 4
sname_0973: .asciz "m_BGM_BOMB_Demo_11"
	.balign 4
sname_0974: .asciz "m_BGM_BOMB_Demo_2"
	.balign 4
sname_0975: .asciz "m_BGM_BOSS_FF_Clear_1"
	.balign 4
sname_0976: .asciz "m_BGM_BOSS_FF_Lose_1"
	.balign 4
sname_0977: .asciz "m_BGM_PIG_END_01"
	.balign 4
sname_0978: .asciz "m_BGM_BOMB_READY_Turn_1"
sname_0979: .asciz "m_BGM_BOMB_GOOD_0"
	.balign 4
sname_0980: .asciz "m_BGM_BOMB_BAD_0"
	.balign 4
sname_0981: .asciz "m_BGM_ROPE_Select"
	.balign 4
sname_0982: .asciz "m_BGM_ROPE_BGM_A00"
	.balign 4
sname_0983: .asciz "m_BGM_ROPE_BGM_A01"
	.balign 4
sname_0984: .asciz "m_BGM_ROPE_BGM_A02"
	.balign 4
sname_0985: .asciz "m_BGM_ROPE_BGM_00"
	.balign 4
sname_0986: .asciz "m_BGM_ROPE_BGM_01"
	.balign 4
sname_0987: .asciz "m_BGM_ROPE_BGM_02"
	.balign 4
sname_0988: .asciz "m_BGM_ROPE_BGM_03"
	.balign 4
sname_0989: .asciz "m_BGM_ROPE_BGM_04"
	.balign 4
sname_0990: .asciz "m_BGM_ROPE_BGM_KAEDE_IN"
sname_0991: .asciz "m_BGM_ROPE_BGM_KAEDE_1A"
sname_0992: .asciz "m_BGM_ROPE_BGM_KAEDE_1B"
sname_0993: .asciz "m_BGM_ROPE_BGM_KAEDE_2A"
sname_0994: .asciz "m_BGM_ROPE_BGM_KAEDE_2B"
sname_0995: .asciz "m_BGM_DraBuru_ALL"
	.balign 4
sname_0996: .asciz "m_BGM_KAEDE_ALL"
sname_0997: .asciz "m_BGM_Loo_ALL"
	.balign 4
sname_0998: .asciz "m_BGM_Plane_BGM_01"
	.balign 4
sname_0999: .asciz "m_BGM_SkateBoard_BGM_01"
sname_1000: .asciz "m_BGM_SkateBoard_FF_NG"
	.balign 4
sname_1001: .asciz "m_BGM_VS_Title_10"
	.balign 4
sname_1002: .asciz "m_BGM_VS_Chiritori2_10"
	.balign 4
sname_1003: .asciz "m_BGM_VS_ChoroQ_10"
	.balign 4
sname_1004: .asciz "m_BGM_VS_ChoroQ_12"
	.balign 4
sname_1005: .asciz "m_BGM_VS_Hurdle_10"
	.balign 4
sname_1006: .asciz "m_BGM_VS_PON2_10"
	.balign 4
sname_1007: .asciz "m_BGM_VS_RoboControl_10"
sname_1008: .asciz "m_BGM_FF_Victory"
	.balign 4
sname_1009: .asciz "s_REST_SFX_01"
	.balign 4
sname_1010: .asciz "s_REST_SFX_02"
	.balign 4
sname_1011: .asciz "s_REST_SFX_03"
	.balign 4
sname_1012: .asciz "s_Demo_AFRO_melo_B1"
sname_1013: .asciz "s_Demo_AFRO_melo_C1"
sname_1014: .asciz "s_Demo_AFRO_melo_D1"
sname_1015: .asciz "s_BOMB_Ele_07"
	.balign 4
sname_1016: .asciz "s_BOMB_Ele_08"
	.balign 4
sname_1017: .asciz "s_BOMB_Ele_09"
	.balign 4
sname_1018: .asciz "s_BOMB_Ele_10"
	.balign 4
sname_1019: .asciz "s_VS_Hurdle_Hit_1"
	.balign 4
sname_1020: .asciz "s_VS_Hurdle_Hit_2"
	.balign 4
sname_1021: .asciz "s_VS_Hurdle_Jump_1"
	.balign 4
sname_1022: .asciz "s_VS_Hurdle_Jump_2"
	.balign 4
sname_1023: .asciz "s_VS_Chiritori_CRASH_A"
	.balign 4
sname_1024: .asciz "s_VS_Chiritori_CRASH_B"
	.balign 4
sname_1025: .asciz "s_VS_PON_Count_1"
	.balign 4
sname_1026: .asciz "s_VS_PON_Count_2"
	.balign 4
sname_1027: .asciz "s_VS_PON_Wall_1"
sname_1028: .asciz "s_VS_PON_STAR_1"
sname_1029: .asciz "s_VS_PON_STAR_2"
sname_1030: .asciz "s_VS_PON_Hit_1"
	.balign 4
sname_1031: .asciz "s_VS_PON_Hit_2"
	.balign 4
sname_1032: .asciz "s_VS_PON_Move_1"
sname_1033: .asciz "s_VS_PON_Move_2"
sname_1034: .asciz "s_VS_PON_Power_1"
	.balign 4
sname_1035: .asciz "s_VS_PON_Power_2"
	.balign 4
sname_1036: .asciz "s_VS_PON_Snap_1"
sname_1037: .asciz "s_VS_PON_Snap_2"
sname_1038: .asciz "s_VS_ChoroQ_Scroll_1"
	.balign 4
sname_1039: .asciz "s_VS_ChoroQ_Scroll_2"
	.balign 4
sname_1040: .asciz "s_VS_ChoroQ_Pull_1"
	.balign 4
sname_1041: .asciz "s_VS_ChoroQ_Pull_2"
	.balign 4
sname_1042: .asciz "s_VS_ChoroQ_Keep_1"
	.balign 4
sname_1043: .asciz "s_VS_ChoroQ_Keep_2"
	.balign 4
sname_1044: .asciz "s_VS_ChoroQ_GO_1"
	.balign 4
sname_1045: .asciz "s_VS_ChoroQ_Lean_1"
	.balign 4
sname_1046: .asciz "s_BOMB_Draw_01"
	.balign 4
sname_1047: .asciz "s_VS_Push_UP_01"
sname_1048: .asciz "s_VS_Push_DOWN_01"
	.balign 4
sname_1049: .asciz "s_VS_Push_BUTTON_01"
sname_1050: .asciz "s_VS_Push_BUTTON_02"
sname_1051: .asciz "s_VS_Push_HIT_01"
	.balign 4
sname_1052: .asciz "s_VS_PUSH_NG_01"
sname_1053: .asciz "s_VS_PUSH_FALL_01"
	.balign 4
sname_1054: .asciz "s_VS_PUSH_Bomb_01"
	.balign 4
sname_1055: .asciz "s_Demo_Title_PINPON_1"
	.balign 4
sname_1056: .asciz "s_Demo_Title_PINPON_2"
	.balign 4
sname_1057: .asciz "s_Demo_Title_PINPON_3"
	.balign 4
sname_1058: .asciz "s_Demo_Title_Rotate_1"
	.balign 4
sname_1059: .asciz "s_Demo_Title_v_Snore_1"
	.balign 4
sname_1060: .asciz "s_Demo_Wario_v_1_Ho"
sname_1061: .asciz "s_Demo_Wario_v_2_Yeah"
	.balign 4
sname_1062: .asciz "s_Demo_Bio_v_1_HELP"
sname_1063: .asciz "s_Demo_Bio_v_2_KOBUN"
	.balign 4
sname_1064: .asciz "s_Demo_Bio_v_3_YADA"
sname_1065: .asciz "s_Demo_Bio_Siren_1"
	.balign 4
sname_1066: .asciz "s_Demo_Bio_Switch_1"
sname_1067: .asciz "s_Demo_Bio_Down_1"
	.balign 4
sname_1068: .asciz "s_Demo_Bio_Fall_1"
	.balign 4
sname_1069: .asciz "s_Demo_Bio_DON_1"
	.balign 4
sname_1070: .asciz "s_Demo_Bio_DON_2"
	.balign 4
sname_1071: .asciz "s_Demo_App_v_1_Morning"
	.balign 4
sname_1072: .asciz "s_Demo_App_v_1_Hello"
	.balign 4
sname_1073: .asciz "s_Demo_App_v_1_Night"
	.balign 4
sname_1074: .asciz "s_Demo_App_v_2_Baby"
sname_1075: .asciz "s_Demo_App_v_2_Party"
	.balign 4
sname_1076: .asciz "s_Demo_App_v_3_Laugh"
	.balign 4
sname_1077: .asciz "s_Demo_App_v_3_Wow"
	.balign 4
sname_1078: .asciz "s_Demo_App_v_4_OK"
	.balign 4
sname_1079: .asciz "s_Demo_App_v_4_DJ"
	.balign 4
sname_1080: .asciz "s_Demo_Dra_v_1_Ahh"
	.balign 4
sname_1081: .asciz "s_Demo_Dra_v_1_Uhn"
	.balign 4
sname_1082: .asciz "s_Demo_Dra_v_2_Where"
	.balign 4
sname_1083: .asciz "s_Demo_Dra_v_3_Ahh"
	.balign 4
sname_1084: .asciz "s_Demo_Dra_v_3_Hey"
	.balign 4
sname_1085: .asciz "s_Demo_Mon_v_1_Haa"
	.balign 4
sname_1086: .asciz "s_Demo_Mon_v_1_Oh"
	.balign 4
sname_1087: .asciz "s_Demo_Mon_v_2_Ahh"
	.balign 4
sname_1088: .asciz "s_Demo_Mon_v_2_Go"
	.balign 4
sname_1089: .asciz "s_Demo_Mon_v_3_Hurry"
	.balign 4
sname_1090: .asciz "s_Demo_Mon_v_3_Go"
	.balign 4
sname_1091: .asciz "s_Demo_Mon_v_4_Ahn"
	.balign 4
sname_1092: .asciz "s_Demo_Mon_v_4_Go"
	.balign 4
sname_1093: .asciz "s_Demo_Mon_Switch_1"
sname_1094: .asciz "s_Demo_Mon_Switch_2"
sname_1095: .asciz "s_Demo_Mon_Switch_3"
sname_1096: .asciz "s_Demo_Mon_Shot_1"
	.balign 4
sname_1097: .asciz "s_Demo_Mon_Shot_2"
	.balign 4
sname_1098: .asciz "s_Demo_Mon_Shot_3"
	.balign 4
sname_1099: .asciz "s_Demo_Mon_PATO_Crash"
	.balign 4
sname_1100: .asciz "s_Demo_Mon_PATO_Jump"
	.balign 4
sname_1101: .asciz "s_Demo_Mon_PATO_1"
	.balign 4
sname_1102: .asciz "s_Demo_Mon_PATO_2"
	.balign 4
sname_1103: .asciz "s_Demo_Voya_v_1_Fuu"
sname_1104: .asciz "s_Demo_Voya_v_1_Haa"
sname_1105: .asciz "s_Demo_Voya_v_2_9V"
	.balign 4
sname_1106: .asciz "s_Demo_Voya_v_2_Ready"
	.balign 4
sname_1107: .asciz "s_Demo_Loo_v_1_Laugh"
	.balign 4
sname_1108: .asciz "s_Demo_Loo_v_1_OK"
	.balign 4
sname_1109: .asciz "s_Demo_Loo_v_2_HaHa"
sname_1110: .asciz "s_Demo_Loo_v_3_GOKU"
sname_1111: .asciz "s_Demo_Loo_v_4_Ah"
	.balign 4
sname_1112: .asciz "s_Demo_Loo_v_4_Oh"
	.balign 4
sname_1113: .asciz "s_Demo_Loo_v_5_Bee"
	.balign 4
sname_1114: .asciz "s_Demo_Loo_v_5_Naa"
	.balign 4
sname_1115: .asciz "s_v_WARIO_YAHOO_1"
	.balign 4
sname_1116: .asciz "s_v_WARIO_YAHOO_2"
	.balign 4
sname_1117: .asciz "s_v_WARIO_YAHOO_3"
	.balign 4
sname_1118: .asciz "s_v_WARIO_YAHOO_4"
	.balign 4
sname_1119: .asciz "s_v_WARIO_YAHOO_5"
	.balign 4
sname_1120: .asciz "s_v_WARIO_EXCELLENT_1"
	.balign 4
sname_1121: .asciz "s_v_WARIO_EXCELLENT_2"
	.balign 4
sname_1122: .asciz "s_v_WARIO_EXCELLENT_3"
	.balign 4
sname_1123: .asciz "s_v_WARIO_OH_RIGHT_1"
	.balign 4
sname_1124: .asciz "s_v_WARIO_OH_RIGHT_2"
	.balign 4
sname_1125: .asciz "s_v_WARIO_LAUGH_HA1_1"
	.balign 4
sname_1126: .asciz "s_v_WARIO_LAUGH_HA1_2"
	.balign 4
sname_1127: .asciz "s_v_WARIO_LAUGH_HA2_1"
	.balign 4
sname_1128: .asciz "s_v_WARIO_LAUGH_HI_1"
	.balign 4
sname_1129: .asciz "s_v_WARIO_OK_1"
	.balign 4
sname_1130: .asciz "s_v_WARIO_OK_2"
	.balign 4
sname_1131: .asciz "s_v_WARIO_OK_3"
	.balign 4
sname_1132: .asciz "s_v_WARIO_OH_BOY_1"
	.balign 4
sname_1133: .asciz "s_v_WARIO_OH_BOY_2"
	.balign 4
sname_1134: .asciz "s_v_WARIO_HEY_1"
sname_1135: .asciz "s_v_WARIO_HEYHEY_1"
	.balign 4
sname_1136: .asciz "s_v_WARIO_YEAH_1"
	.balign 4
sname_1137: .asciz "s_v_WARIO_NO_1"
	.balign 4
sname_1138: .asciz "s_v_WARIO_NO_2"
	.balign 4
sname_1139: .asciz "s_v_WARIO_NO_3"
	.balign 4
sname_1140: .asciz "s_v_WARIO_AHH_1"
sname_1141: .asciz "s_v_WARIO_AHH_2"
sname_1142: .asciz "s_v_WARIO_AHH_3"
sname_1143: .asciz "s_v_WARIO_AHH_EYEAH_1"
	.balign 4
sname_1144: .asciz "s_v_WARIO_AHH_EYEAH_2"
	.balign 4
sname_1145: .asciz "s_v_WARIO_HA_1"
	.balign 4
sname_1146: .asciz "s_v_WARIO_WAA_1"
sname_1147: .asciz "s_v_WARIO_WAA_2"
sname_1148: .asciz "s_v_WARIO_WAO_1"
sname_1149: .asciz "s_v_WARIO_WAO_2"
sname_1150: .asciz "s_v_WARIO_WIN_YOKI"
	.balign 4
sname_1151: .asciz "s_v_Monna_OK_01"
sname_1152: .asciz "s_v_Monna_OK_02"
sname_1153: .asciz "s_v_Monna_OK_03"
sname_1154: .asciz "s_v_Monna_OK_04"
sname_1155: .asciz "s_v_Monna_OK_05"
sname_1156: .asciz "s_v_Monna_OK_06"
sname_1157: .asciz "s_v_Monna_OK_07"
sname_1158: .asciz "s_v_Monna_OK_08"
sname_1159: .asciz "s_v_Monna_OK_09"
sname_1160: .asciz "s_v_Monna_OK_10"
sname_1161: .asciz "s_v_Monna_OK_11"
sname_1162: .asciz "s_v_Monna_OK_12"
sname_1163: .asciz "s_v_Monna_OK_13"
sname_1164: .asciz "s_v_Monna_NG_01"
sname_1165: .asciz "s_v_Monna_NG_02"
sname_1166: .asciz "s_v_Monna_NG_03"
sname_1167: .asciz "s_v_Monna_NG_04"
sname_1168: .asciz "s_v_Monna_NG_05"
sname_1169: .asciz "s_v_Monna_NG_06"
sname_1170: .asciz "s_v_Monna_NG_07"
sname_1171: .asciz "s_v_Monna_NG_08"
sname_1172: .asciz "s_v_Monna_NG_09"
sname_1173: .asciz "s_v_Monna_NG_10"
sname_1174: .asciz "s_v_App_OK_01"
	.balign 4
sname_1175: .asciz "s_v_App_OK_02"
	.balign 4
sname_1176: .asciz "s_v_App_OK_03"
	.balign 4
sname_1177: .asciz "s_v_App_OK_04"
	.balign 4
sname_1178: .asciz "s_v_App_OK_05"
	.balign 4
sname_1179: .asciz "s_v_App_OK_06"
	.balign 4
sname_1180: .asciz "s_v_App_OK_07"
	.balign 4
sname_1181: .asciz "s_v_App_OK_08"
	.balign 4
sname_1182: .asciz "s_v_App_OK_09"
	.balign 4
sname_1183: .asciz "s_v_App_OK_10"
	.balign 4
sname_1184: .asciz "s_v_App_OK_11"
	.balign 4
sname_1185: .asciz "s_v_App_OK_12"
	.balign 4
sname_1186: .asciz "s_v_App_OK_13"
	.balign 4
sname_1187: .asciz "s_v_App_OK_14"
	.balign 4
sname_1188: .asciz "s_v_App_OK_15"
	.balign 4
sname_1189: .asciz "s_v_App_OK_16"
	.balign 4
sname_1190: .asciz "s_v_App_NG_01"
	.balign 4
sname_1191: .asciz "s_v_App_NG_02"
	.balign 4
sname_1192: .asciz "s_v_App_NG_03"
	.balign 4
sname_1193: .asciz "s_v_App_NG_04"
	.balign 4
sname_1194: .asciz "s_v_App_NG_05"
	.balign 4
sname_1195: .asciz "s_v_App_NG_06"
	.balign 4
sname_1196: .asciz "s_v_App_NG_07"
	.balign 4
sname_1197: .asciz "s_v_App_NG_08"
	.balign 4
sname_1198: .asciz "s_v_App_NG_09"
	.balign 4
sname_1199: .asciz "s_v_App_NG_10"
	.balign 4
sname_1200: .asciz "s_v_App_NG_11"
	.balign 4
sname_1201: .asciz "s_v_App_Morning_1"
	.balign 4
sname_1202: .asciz "s_v_App_Hello_1"
sname_1203: .asciz "s_v_App_Night_1"
sname_1204: .asciz "s_v_Dra_OK_01"
	.balign 4
sname_1205: .asciz "s_v_Dra_OK_02"
	.balign 4
sname_1206: .asciz "s_v_Dra_OK_03"
	.balign 4
sname_1207: .asciz "s_v_Dra_OK_04"
	.balign 4
sname_1208: .asciz "s_v_Dra_OK_05"
	.balign 4
sname_1209: .asciz "s_v_Dra_OK_06"
	.balign 4
sname_1210: .asciz "s_v_Dra_OK_07"
	.balign 4
sname_1211: .asciz "s_v_Dra_OK_08"
	.balign 4
sname_1212: .asciz "s_v_Dra_OK_09"
	.balign 4
sname_1213: .asciz "s_v_Dra_OK_10"
	.balign 4
sname_1214: .asciz "s_v_Dra_OK_11"
	.balign 4
sname_1215: .asciz "s_v_Dra_OK_12"
	.balign 4
sname_1216: .asciz "s_v_Dra_OK_13"
	.balign 4
sname_1217: .asciz "s_v_Dra_NG_01"
	.balign 4
sname_1218: .asciz "s_v_Dra_NG_02"
	.balign 4
sname_1219: .asciz "s_v_Dra_NG_03"
	.balign 4
sname_1220: .asciz "s_v_Dra_NG_04"
	.balign 4
sname_1221: .asciz "s_v_Dra_NG_05"
	.balign 4
sname_1222: .asciz "s_v_Dra_NG_06"
	.balign 4
sname_1223: .asciz "s_v_Dra_NG_07"
	.balign 4
sname_1224: .asciz "s_v_Dra_NG_08"
	.balign 4
sname_1225: .asciz "s_v_Dra_NG_09"
	.balign 4
sname_1226: .asciz "s_v_Dra_NG_10"
	.balign 4
sname_1227: .asciz "s_v_Dra_NG_11"
	.balign 4
sname_1228: .asciz "s_v_Loo_OK_01"
	.balign 4
sname_1229: .asciz "s_v_Loo_OK_02"
	.balign 4
sname_1230: .asciz "s_v_Loo_OK_03"
	.balign 4
sname_1231: .asciz "s_v_Loo_OK_04"
	.balign 4
sname_1232: .asciz "s_v_Loo_OK_05"
	.balign 4
sname_1233: .asciz "s_v_Loo_OK_06"
	.balign 4
sname_1234: .asciz "s_v_Loo_OK_07"
	.balign 4
sname_1235: .asciz "s_v_Loo_OK_08"
	.balign 4
sname_1236: .asciz "s_v_Loo_OK_09"
	.balign 4
sname_1237: .asciz "s_v_Loo_OK_10"
	.balign 4
sname_1238: .asciz "s_v_Loo_OK_11"
	.balign 4
sname_1239: .asciz "s_v_Loo_OK_12"
	.balign 4
sname_1240: .asciz "s_v_Loo_OK_13"
	.balign 4
sname_1241: .asciz "s_v_Loo_OK_14"
	.balign 4
sname_1242: .asciz "s_v_Loo_NG_01"
	.balign 4
sname_1243: .asciz "s_v_Loo_NG_02"
	.balign 4
sname_1244: .asciz "s_v_Loo_NG_03"
	.balign 4
sname_1245: .asciz "s_v_Loo_NG_04"
	.balign 4
sname_1246: .asciz "s_v_Loo_NG_05"
	.balign 4
sname_1247: .asciz "s_v_Loo_NG_06"
	.balign 4
sname_1248: .asciz "s_v_Loo_NG_07"
	.balign 4
sname_1249: .asciz "s_v_Loo_NG_08"
	.balign 4
sname_1250: .asciz "s_v_Loo_NG_09"
	.balign 4
sname_1251: .asciz "s_v_Loo_NG_10"
	.balign 4
sname_1252: .asciz "s_v_Voya_OK_01"
	.balign 4
sname_1253: .asciz "s_v_Voya_OK_02"
	.balign 4
sname_1254: .asciz "s_v_Voya_OK_03"
	.balign 4
sname_1255: .asciz "s_v_Voya_OK_04"
	.balign 4
sname_1256: .asciz "s_v_Voya_OK_05"
	.balign 4
sname_1257: .asciz "s_v_Voya_OK_06"
	.balign 4
sname_1258: .asciz "s_v_Voya_OK_07"
	.balign 4
sname_1259: .asciz "s_v_Voya_OK_08"
	.balign 4
sname_1260: .asciz "s_v_Voya_OK_09"
	.balign 4
sname_1261: .asciz "s_v_Voya_OK_10"
	.balign 4
sname_1262: .asciz "s_v_Voya_NG_01"
	.balign 4
sname_1263: .asciz "s_v_Voya_NG_02"
	.balign 4
sname_1264: .asciz "s_v_Voya_NG_03"
	.balign 4
sname_1265: .asciz "s_v_Voya_NG_04"
	.balign 4
sname_1266: .asciz "s_v_Voya_NG_05"
	.balign 4
sname_1267: .asciz "s_v_Voya_NG_06"
	.balign 4
sname_1268: .asciz "s_v_Bio_OK_01"
	.balign 4
sname_1269: .asciz "s_v_Bio_OK_02"
	.balign 4
sname_1270: .asciz "s_v_Bio_OK_03"
	.balign 4
sname_1271: .asciz "s_v_Bio_OK_04"
	.balign 4
sname_1272: .asciz "s_v_Bio_OK_05"
	.balign 4
sname_1273: .asciz "s_v_Bio_OK_06"
	.balign 4
sname_1274: .asciz "s_v_Bio_OK_07"
	.balign 4
sname_1275: .asciz "s_v_Bio_OK_08"
	.balign 4
sname_1276: .asciz "s_v_Bio_OK_09"
	.balign 4
sname_1277: .asciz "s_v_Bio_OK_10"
	.balign 4
sname_1278: .asciz "s_v_Bio_NG_01"
	.balign 4
sname_1279: .asciz "s_v_Bio_NG_02"
	.balign 4
sname_1280: .asciz "s_v_Bio_NG_03"
	.balign 4
sname_1281: .asciz "s_v_Bio_NG_04"
	.balign 4
sname_1282: .asciz "s_v_Bio_NG_05"
	.balign 4
sname_1283: .asciz "s_v_Bio_NG_06"
	.balign 4
sname_1284: .asciz "s_v_Bio_NG_07"
	.balign 4
sname_1285: .asciz "s_v_Bio_NG_08"
	.balign 4
sname_1286: .asciz "s_v_Bio_NG_09"
	.balign 4
sname_1287: .asciz "s_v_Bio_NG_10"
	.balign 4
sname_1288: .asciz "s_v_Kaede_OK_01"
sname_1289: .asciz "s_v_Kaede_OK_02"
sname_1290: .asciz "s_v_Kaede_OK_03"
sname_1291: .asciz "s_v_Kaede_OK_04"
sname_1292: .asciz "s_v_Kaede_OK_05"
sname_1293: .asciz "s_v_Kaede_OK_06"
sname_1294: .asciz "s_v_Kaede_OK_07"
sname_1295: .asciz "s_v_Kaede_OK_08"
sname_1296: .asciz "s_v_Kaede_OK_09"
sname_1297: .asciz "s_v_Kaede_OK_10"
sname_1298: .asciz "s_v_Kaede_NG_01"
sname_1299: .asciz "s_v_Kaede_NG_02"
sname_1300: .asciz "s_v_Kaede_NG_03"
sname_1301: .asciz "s_v_Kaede_NG_04"
sname_1302: .asciz "s_v_Kaede_NG_05"
sname_1303: .asciz "s_v_Kaede_NG_06"
sname_1304: .asciz "s_v_Kaede_NG_07"
sname_1305: .asciz "s_v_App_Select_A1"
	.balign 4
sname_1306: .asciz "s_v_App_Select_A2"
	.balign 4
sname_1307: .asciz "s_v_App_Select_A3"
	.balign 4
sname_1308: .asciz "s_v_App_Select_B1"
	.balign 4
sname_1309: .asciz "s_v_App_Select_B2"
	.balign 4
sname_1310: .asciz "s_v_App_Select_B3"
	.balign 4
sname_1311: .asciz "s_v_App_Select_C1"
	.balign 4
sname_1312: .asciz "s_v_App_Select_C2"
	.balign 4
sname_1313: .asciz "s_v_App_Select_C3"
	.balign 4
sname_1314: .asciz "s_v_Dra_Select_1"
	.balign 4
sname_1315: .asciz "s_v_Dra_Select_2"
	.balign 4
sname_1316: .asciz "s_v_Dra_Select_3"
	.balign 4
sname_1317: .asciz "s_v_Monna_Select_1"
	.balign 4
sname_1318: .asciz "s_v_Monna_Select_2"
	.balign 4
sname_1319: .asciz "s_v_Monna_Select_3"
	.balign 4
sname_1320: .asciz "s_v_Voya_Select_1"
	.balign 4
sname_1321: .asciz "s_v_Voya_Select_2"
	.balign 4
sname_1322: .asciz "s_v_Voya_Select_3"
	.balign 4
sname_1323: .asciz "s_v_Bio_Select_1"
	.balign 4
sname_1324: .asciz "s_v_Bio_Select_2"
	.balign 4
sname_1325: .asciz "s_v_Bio_Select_3"
	.balign 4
sname_1326: .asciz "s_v_Loo_Select_1"
	.balign 4
sname_1327: .asciz "s_v_Loo_Select_2"
	.balign 4
sname_1328: .asciz "s_v_Loo_Select_3"
	.balign 4
sname_1329: .asciz "s_v_wario_Select_1"
	.balign 4
sname_1330: .asciz "s_v_wario_Select_2"
	.balign 4
sname_1331: .asciz "s_v_wario_Select_3"
	.balign 4
sname_1332: .asciz "s_v_Kaede_Select_1"
	.balign 4
sname_1333: .asciz "s_v_Kaede_Select_2"
	.balign 4
sname_1334: .asciz "s_v_Kaede_Select_3"
	.balign 4
sname_1335: .asciz "s_v_App_MAP_01"
	.balign 4
sname_1336: .asciz "s_v_Dra_MAP_01"
	.balign 4
sname_1337: .asciz "s_v_Monna_MAP_01"
	.balign 4
sname_1338: .asciz "s_v_Voya_MAP_01"
sname_1339: .asciz "s_v_Bio_MAP_01"
	.balign 4
sname_1340: .asciz "s_v_Loo_MAP_01"
	.balign 4
sname_1341: .asciz "s_v_KAEDE_MAP_01"
	.balign 4

	.global sndSongTable
sndSongTable:   @ 1342 x {MIDI *midi; u32 bits (0-4 player, not read by the driver; 5-14 bank, 15-21 volume, 22-31 priority); u32 0xFF (not read); char *name; u32 id}
song_0000:
	song_entry mid_0000_x_TEST, bank=3, volume=120, priority=90, player=7, w8=0xFF, name=sname_0000, id=0
song_0001:
	song_entry mid_0001_m_x_BGM_BOMB_2bar, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0001, id=1
song_0002:
	song_entry mid_0002_m_x_BGM_BOMB_4bar, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0002, id=2
song_0003:
	song_entry mid_0003_m_x_BGM_BOMB_8bar, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0003, id=3
song_0004:
	song_entry mid_0004_m_BGM_01, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0004, id=4
song_0005:
	song_entry mid_0005_m_BGM_Title_Demo_10, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0005, id=5
song_0006:
	song_entry mid_0006_m_BGM_Title_Demo_NEWS, bank=3, volume=70, priority=0, player=3, w8=0xFF, name=sname_0006, id=6
song_0007:
	song_entry mid_0007_m_BGM_Title_Demo_15, bank=3, volume=80, priority=0, player=2, w8=0xFF, name=sname_0007, id=7
song_0008:
	song_entry mid_0008_m_BGM_Title_Demo_20, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0008, id=8
song_0009:
	song_entry mid_0009_m_BGM_Title_Demo_30, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0009, id=9
song_0010:
	song_entry mid_0010_m_BGM_Title_01, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0010, id=10
song_0011:
	song_entry mid_0011_m_BGM_Select_01, bank=3, volume=55, priority=0, player=1, w8=0xFF, name=sname_0011, id=11
song_0012:
	song_entry mid_0012_m_BGM_Select_02, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0012, id=12
song_0013:
	song_entry mid_0013_s_Demo_MAP_1, bank=3, volume=50, priority=0, player=3, w8=0xFF, name=sname_0013, id=13
song_0014:
	song_entry mid_0014_m_BGM_Demo_EP_MAP_1, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0014, id=14
song_0015:
	song_entry mid_0015_m_BGM_Ending_01, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0015, id=15
song_0016:
	song_entry mid_0016_m_BGM_Ending_02, bank=3, volume=95, priority=0, player=1, w8=0xFF, name=sname_0016, id=16
song_0017:
	song_entry mid_0017_m_BGM_DrMario_Title, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0017, id=17
song_0018:
	song_entry mid_0018_m_BGM_DrMario_Select, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0018, id=18
song_0019:
	song_entry mid_0019_m_BGM_DrMario_Game_Hot, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0019, id=19
song_0020:
	song_entry mid_0020_m_BGM_DrMario_Clear, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0020, id=20
song_0021:
	song_entry mid_0021_m_BGM_DrMario_OVER, bank=3, volume=55, priority=0, player=0, w8=0xFF, name=sname_0021, id=21
song_0022:
	song_entry mid_0022_m_BGM_DrMario_Demo, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0022, id=22
song_0023:
	song_entry mid_0023_s_Demo_DrMario_UFO_1, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0023, id=23
song_0024:
	song_entry mid_0024_s_Demo_DrMario_UFO_2, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0024, id=24
song_0025:
	song_entry mid_0025_m_BGM_DrMario_Ending, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0025, id=25
song_0026:
	song_entry mid_0026_m_BGM_PAINT_Title, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0026, id=26
song_0027:
	song_entry mid_0027_m_BGM_PAINT_BGM_1, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0027, id=27
song_0028:
	song_entry mid_0028_m_BGM_PAINT_BGM_2, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0028, id=28
song_0029:
	song_entry mid_0029_m_BGM_PAINT_BGM_3, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0029, id=29
song_0030:
	song_entry mid_0030_m_BGM_PAINT_BOSS, bank=3, volume=75, priority=0, player=0, w8=0xFF, name=sname_0030, id=30
song_0031:
	song_entry mid_0031_m_BGM_PAINT_GameOver, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0031, id=31
song_0032:
	song_entry mid_0032_m_BGM_PAINT_Fanfare, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0032, id=32
song_0033:
	song_entry mid_0033_m_BGM_Sheriff_Title, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0033, id=33
song_0034:
	song_entry mid_0034_m_BGM_Sheriff_START_1, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0034, id=34
song_0035:
	song_entry mid_0035_m_BGM_Sheriff_Game_1, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0035, id=35
song_0036:
	song_entry mid_0036_m_BGM_Sheriff_BIRD_1, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0036, id=36
song_0037:
	song_entry mid_0037_m_BGM_Sheriff_TEKI_IN_1, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0037, id=37
song_0038:
	song_entry mid_0038_m_BGM_Sheriff_CLEAR_1, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0038, id=38
song_0039:
	song_entry mid_0039_m_BGM_Sheriff_CLEAR_HART, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0039, id=39
song_0040:
	song_entry mid_0040_m_BGM_Sheriff_GameOver, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0040, id=40
song_0041:
	song_entry mid_0041_m_BGM_GYORO_Title_01, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0041, id=41
song_0042:
	song_entry mid_0042_m_BGM_GYORO_Game_Type_1, bank=3, volume=55, priority=30, player=0, w8=0xFF, name=sname_0042, id=42
song_0043:
	song_entry mid_0043_m_BGM_GYORO_Game_Type_2, bank=3, volume=55, priority=30, player=1, w8=0xFF, name=sname_0043, id=43
song_0044:
	song_entry mid_0044_m_BGM_GYORO_Game_Type_3, bank=3, volume=35, priority=30, player=2, w8=0xFF, name=sname_0044, id=44
song_0045:
	song_entry mid_0045_m_BGM_GYORO_Game_Type_4, bank=3, volume=40, priority=30, player=0, w8=0xFF, name=sname_0045, id=45
song_0046:
	song_entry mid_0046_m_BGM_GYORO_Game_50000, bank=3, volume=60, priority=30, player=0, w8=0xFF, name=sname_0046, id=46
song_0047:
	song_entry mid_0047_m_BGM_GYORO_Game_50000_2, bank=3, volume=50, priority=30, player=1, w8=0xFF, name=sname_0047, id=47
song_0048:
	song_entry mid_0048_m_BGM_GYORO_Game_50000_3, bank=3, volume=70, priority=30, player=2, w8=0xFF, name=sname_0048, id=48
song_0049:
	song_entry mid_0049_m_BGM_GYORO_GameOver_01, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0049, id=49
song_0050:
	song_entry mid_0050_m_BGM_Wario_Demo_1, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0050, id=53
song_0051:
	song_entry mid_0051_m_BGM_Wario_Turn_NEXT_01, bank=3, volume=75, priority=0, player=1, w8=0xFF, name=sname_0051, id=54
song_0052:
	song_entry mid_0052_m_BGM_Wario_Turn_NEXT_02, bank=3, volume=75, priority=0, player=1, w8=0xFF, name=sname_0052, id=55
song_0053:
	song_entry mid_0053_m_BGM_Wario_Turn_OK_01, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0053, id=56
song_0054:
	song_entry mid_0054_m_BGM_Wario_Turn_OK_02, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0054, id=57
song_0055:
	song_entry mid_0055_m_BGM_Wario_Turn_NG_01, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0055, id=58
song_0056:
	song_entry mid_0056_m_BGM_Wario_Turn_NG_02, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0056, id=59
song_0057:
	song_entry mid_0057_m_BGM_Wario_END_01, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0057, id=60
song_0058:
	song_entry mid_0058_m_BGM_Wario_END_Loop_01, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0058, id=61
song_0059:
	song_entry mid_0059_m_BGM_Wario_EP_10, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0059, id=62
song_0060:
	song_entry mid_0060_m_BGM_Wario_EP_STAFF_01, bank=3, volume=110, priority=0, player=0, w8=0xFF, name=sname_0060, id=63
song_0061:
	song_entry mid_0061_m_BGM_Wario_BOSS_10, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0061, id=64
song_0062:
	song_entry mid_0062_m_BGM_Wario_BOSS_90, bank=3, volume=110, priority=0, player=0, w8=0xFF, name=sname_0062, id=65
song_0063:
	song_entry mid_0063_m_BGM_Tutorial_Demo_1, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0063, id=66
song_0064:
	song_entry mid_0064_m_BGM_Tutorial_READY_01, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0064, id=67
song_0065:
	song_entry mid_0065_m_BGM_Tutorial_Turn_OK_01, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0065, id=68
song_0066:
	song_entry mid_0066_m_BGM_Tutorial_Turn_OK_02, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0066, id=69
song_0067:
	song_entry mid_0067_m_BGM_Tutorial_Turn_NG_01, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0067, id=70
song_0068:
	song_entry mid_0068_m_BGM_Tutorial_Turn_NG_02, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0068, id=71
song_0069:
	song_entry mid_0069_m_BGM_Tutorial_Turn_NEXT_0, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0069, id=72
song_0070:
	song_entry mid_0070_m_BGM_Tutorial_Turn_NEXT_1, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0070, id=73
song_0071:
	song_entry mid_0071_m_BGM_Tutorial_END_01, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0071, id=74
song_0072:
	song_entry mid_0072_m_BGM_Tutorial_BOSS_FF_ST, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0072, id=75
song_0073:
	song_entry mid_0073_m_BGM_Tutorial_BOSS_10, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0073, id=76
song_0074:
	song_entry mid_0074_m_BGM_BOMB_Demo_AFRO_0, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_0074, id=77
song_0075:
	song_entry mid_0075_m_BGM_BOMB_Demo_AFRO_1, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0075, id=78
song_0076:
	song_entry mid_0076_m_BGM_BOMB_Demo_AFRO_2, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0076, id=79
song_0077:
	song_entry mid_0077_m_BGM_BOMB_Demo_AFRO_3, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0077, id=80
song_0078:
	song_entry mid_0078_m_BGM_BOMB_Demo_AFRO_Loop, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0078, id=81
song_0079:
	song_entry mid_0079_m_BGM_BOMB_Demo_AFRO_Loop_B, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0079, id=82
song_0080:
	song_entry mid_0080_m_BGM_BOMB_Demo_AFRO_Loop_C, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0080, id=83
song_0081:
	song_entry mid_0081_m_BGM_BOMB_Demo_AFRO_Loop2, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0081, id=84
song_0082:
	song_entry mid_0082_m_BGM_BOMB_Demo_AFRO_Loop22, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0082, id=85
song_0083:
	song_entry mid_0083_m_BGM_BOMB_Demo_AFRO_Loop23, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0083, id=86
song_0084:
	song_entry mid_0084_m_BGM_BOMB_Demo_AFRO_NEXT1A, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0084, id=87
song_0085:
	song_entry mid_0085_m_BGM_BOMB_Demo_AFRO_NEXT2A, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0085, id=88
song_0086:
	song_entry mid_0086_m_BGM_BOMB_Demo_AFRO_NEXT1B, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0086, id=89
song_0087:
	song_entry mid_0087_m_BGM_BOMB_Demo_AFRO_NEXT2B, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0087, id=90
song_0088:
	song_entry mid_0088_m_BGM_BOMB_Demo_AFRO_NEXT1C, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0088, id=91
song_0089:
	song_entry mid_0089_m_BGM_BOMB_Demo_AFRO_NEXT2C, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0089, id=92
song_0090:
	song_entry mid_0090_m_BGM_AFRO_Turn_NEXT_00, bank=3, volume=110, priority=0, player=1, w8=0xFF, name=sname_0090, id=93
song_0091:
	song_entry mid_0091_m_BGM_AFRO_Turn_OK_01, bank=3, volume=90, priority=0, player=2, w8=0xFF, name=sname_0091, id=94
song_0092:
	song_entry mid_0092_m_BGM_AFRO_Turn_OK_02, bank=3, volume=90, priority=0, player=2, w8=0xFF, name=sname_0092, id=95
song_0093:
	song_entry mid_0093_m_BGM_AFRO_Turn_NG_01, bank=3, volume=90, priority=0, player=2, w8=0xFF, name=sname_0093, id=96
song_0094:
	song_entry mid_0094_m_BGM_AFRO_Turn_NG_02, bank=3, volume=90, priority=0, player=2, w8=0xFF, name=sname_0094, id=97
song_0095:
	song_entry mid_0095_m_BGM_AFRO_Turn_NEXT_01, bank=3, volume=100, priority=0, player=1, w8=0xFF, name=sname_0095, id=98
song_0096:
	song_entry mid_0096_m_BGM_AFRO_Turn_NEXT_02, bank=3, volume=100, priority=0, player=1, w8=0xFF, name=sname_0096, id=99
song_0097:
	song_entry mid_0097_m_BGM_BOMB_Demo_AFRO_EP_A1, bank=3, volume=60, priority=0, player=1, w8=0xFF, name=sname_0097, id=100
song_0098:
	song_entry mid_0098_m_BGM_BOMB_Demo_AFRO_EP_A2, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0098, id=101
song_0099:
	song_entry mid_0099_m_BGM_AFRO_BOSS_10, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0099, id=102
song_0100:
	song_entry mid_0100_m_BGM_AFRO_BOSS_11, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0100, id=103
song_0101:
	song_entry mid_0101_m_BGM_AFRO_BOSS_21, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0101, id=104
song_0102:
	song_entry mid_0102_m_BGM_AFRO_BOSS_31, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0102, id=105
song_0103:
	song_entry mid_0103_m_BGM_AFRO_BOSS_41, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0103, id=106
song_0104:
	song_entry mid_0104_m_BGM_AFRO_BOSS_51, bank=3, volume=110, priority=0, player=0, w8=0xFF, name=sname_0104, id=107
song_0105:
	song_entry mid_0105_m_BGM_DraBuru_INTRO_0, bank=3, volume=40, priority=0, player=2, w8=0xFF, name=sname_0105, id=108
song_0106:
	song_entry mid_0106_m_BGM_DraBuru_INTRO_1, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0106, id=109
song_0107:
	song_entry mid_0107_m_BGM_DraBuru_INTRO_2, bank=3, volume=100, priority=0, player=1, w8=0xFF, name=sname_0107, id=110
song_0108:
	song_entry mid_0108_m_BGM_DraBuru_INTRO_3, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0108, id=111
song_0109:
	song_entry mid_0109_m_BGM_DraBuru_01_IN, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0109, id=112
song_0110:
	song_entry mid_0110_m_BGM_DraBuru_02_IN, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0110, id=113
song_0111:
	song_entry mid_0111_m_BGM_DraBuru_03_IN, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0111, id=114
song_0112:
	song_entry mid_0112_m_BGM_DraBuru_04_IN, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0112, id=115
song_0113:
	song_entry mid_0113_m_BGM_DraBuru_01_Intro, bank=3, volume=110, priority=25, player=1, w8=0xFF, name=sname_0113, id=116
song_0114:
	song_entry mid_0114_m_BGM_DraBuru_01_01, bank=3, volume=85, priority=25, player=2, w8=0xFF, name=sname_0114, id=117
song_0115:
	song_entry mid_0115_m_BGM_DraBuru_01_02, bank=3, volume=85, priority=25, player=1, w8=0xFF, name=sname_0115, id=118
song_0116:
	song_entry mid_0116_m_BGM_DraBuru_01_03, bank=3, volume=85, priority=25, player=2, w8=0xFF, name=sname_0116, id=119
song_0117:
	song_entry mid_0117_m_BGM_DraBuru_01_04, bank=3, volume=85, priority=25, player=1, w8=0xFF, name=sname_0117, id=120
song_0118:
	song_entry mid_0118_m_BGM_DraBuru_01_05, bank=3, volume=85, priority=25, player=2, w8=0xFF, name=sname_0118, id=121
song_0119:
	song_entry mid_0119_m_BGM_DraBuru_01_06, bank=3, volume=85, priority=25, player=1, w8=0xFF, name=sname_0119, id=122
song_0120:
	song_entry mid_0120_m_BGM_DraBuru_01_07, bank=3, volume=85, priority=25, player=2, w8=0xFF, name=sname_0120, id=123
song_0121:
	song_entry mid_0121_m_BGM_DraBuru_01_08, bank=3, volume=85, priority=25, player=1, w8=0xFF, name=sname_0121, id=124
song_0122:
	song_entry mid_0122_m_BGM_DraBuru_01_END, bank=3, volume=80, priority=25, player=0, w8=0xFF, name=sname_0122, id=125
song_0123:
	song_entry mid_0123_m_BGM_DraBuru_01_BOSS_IN, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0123, id=126
song_0124:
	song_entry mid_0124_m_BGM_DraBuru_01_SpeedUp, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0124, id=127
song_0125:
	song_entry mid_0125_m_BGM_DraBuru_02_Intro, bank=3, volume=100, priority=25, player=1, w8=0xFF, name=sname_0125, id=128
song_0126:
	song_entry mid_0126_m_BGM_DraBuru_02_01, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0126, id=129
song_0127:
	song_entry mid_0127_m_BGM_DraBuru_02_02, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0127, id=130
song_0128:
	song_entry mid_0128_m_BGM_DraBuru_02_03, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0128, id=131
song_0129:
	song_entry mid_0129_m_BGM_DraBuru_02_04, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0129, id=132
song_0130:
	song_entry mid_0130_m_BGM_DraBuru_02_05, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0130, id=133
song_0131:
	song_entry mid_0131_m_BGM_DraBuru_02_06, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0131, id=134
song_0132:
	song_entry mid_0132_m_BGM_DraBuru_02_07, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0132, id=135
song_0133:
	song_entry mid_0133_m_BGM_DraBuru_02_08, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0133, id=136
song_0134:
	song_entry mid_0134_m_BGM_DraBuru_02_END, bank=3, volume=80, priority=25, player=0, w8=0xFF, name=sname_0134, id=137
song_0135:
	song_entry mid_0135_m_BGM_DraBuru_02_BOSS_IN, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0135, id=138
song_0136:
	song_entry mid_0136_m_BGM_DraBuru_02_SpeedUp, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0136, id=139
song_0137:
	song_entry mid_0137_m_BGM_DraBuru_03_Intro, bank=3, volume=100, priority=25, player=1, w8=0xFF, name=sname_0137, id=140
song_0138:
	song_entry mid_0138_m_BGM_DraBuru_03_01, bank=3, volume=70, priority=25, player=2, w8=0xFF, name=sname_0138, id=141
song_0139:
	song_entry mid_0139_m_BGM_DraBuru_03_02, bank=3, volume=70, priority=25, player=1, w8=0xFF, name=sname_0139, id=142
song_0140:
	song_entry mid_0140_m_BGM_DraBuru_03_03, bank=3, volume=70, priority=25, player=2, w8=0xFF, name=sname_0140, id=143
song_0141:
	song_entry mid_0141_m_BGM_DraBuru_03_04, bank=3, volume=70, priority=25, player=1, w8=0xFF, name=sname_0141, id=144
song_0142:
	song_entry mid_0142_m_BGM_DraBuru_03_05, bank=3, volume=70, priority=25, player=2, w8=0xFF, name=sname_0142, id=145
song_0143:
	song_entry mid_0143_m_BGM_DraBuru_03_06, bank=3, volume=70, priority=25, player=1, w8=0xFF, name=sname_0143, id=146
song_0144:
	song_entry mid_0144_m_BGM_DraBuru_03_07, bank=3, volume=70, priority=25, player=2, w8=0xFF, name=sname_0144, id=147
song_0145:
	song_entry mid_0145_m_BGM_DraBuru_03_08, bank=3, volume=70, priority=25, player=1, w8=0xFF, name=sname_0145, id=148
song_0146:
	song_entry mid_0146_m_BGM_DraBuru_03_END, bank=3, volume=70, priority=25, player=0, w8=0xFF, name=sname_0146, id=149
song_0147:
	song_entry mid_0147_m_BGM_DraBuru_03_BOSS_IN, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0147, id=150
song_0148:
	song_entry mid_0148_m_BGM_DraBuru_03_SpeedUp, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0148, id=151
song_0149:
	song_entry mid_0149_m_BGM_DraBuru_04_Intro, bank=3, volume=85, priority=25, player=1, w8=0xFF, name=sname_0149, id=152
song_0150:
	song_entry mid_0150_m_BGM_DraBuru_04_01, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0150, id=153
song_0151:
	song_entry mid_0151_m_BGM_DraBuru_04_02, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0151, id=154
song_0152:
	song_entry mid_0152_m_BGM_DraBuru_04_03, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0152, id=155
song_0153:
	song_entry mid_0153_m_BGM_DraBuru_04_04, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0153, id=156
song_0154:
	song_entry mid_0154_m_BGM_DraBuru_04_05, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0154, id=157
song_0155:
	song_entry mid_0155_m_BGM_DraBuru_04_06, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0155, id=158
song_0156:
	song_entry mid_0156_m_BGM_DraBuru_04_07, bank=3, volume=80, priority=25, player=2, w8=0xFF, name=sname_0156, id=159
song_0157:
	song_entry mid_0157_m_BGM_DraBuru_04_08, bank=3, volume=80, priority=25, player=1, w8=0xFF, name=sname_0157, id=160
song_0158:
	song_entry mid_0158_m_BGM_DraBuru_04_END, bank=3, volume=70, priority=25, player=0, w8=0xFF, name=sname_0158, id=161
song_0159:
	song_entry mid_0159_m_BGM_DraBuru_04_BOSS_IN, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0159, id=162
song_0160:
	song_entry mid_0160_m_BGM_DraBuru_04_SpeedUp, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0160, id=163
song_0161:
	song_entry mid_0161_m_BGM_DraBuru_NEXTSTAGE, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0161, id=164
song_0162:
	song_entry mid_0162_m_BGM_DraBuru_Turn_OK_01, bank=3, volume=90, priority=100, player=6, w8=0xFF, name=sname_0162, id=165
song_0163:
	song_entry mid_0163_m_BGM_DraBuru_Turn_OK_02, bank=3, volume=90, priority=100, player=6, w8=0xFF, name=sname_0163, id=166
song_0164:
	song_entry mid_0164_m_BGM_DraBuru_Turn_NG_01, bank=3, volume=30, priority=100, player=6, w8=0xFF, name=sname_0164, id=167
song_0165:
	song_entry mid_0165_m_BGM_DraBuru_Turn_NG_02, bank=3, volume=30, priority=100, player=6, w8=0xFF, name=sname_0165, id=168
song_0166:
	song_entry mid_0166_m_BGM_DraBuru_Turn_NEXT_1, bank=3, volume=80, priority=100, player=6, w8=0xFF, name=sname_0166, id=169
song_0167:
	song_entry mid_0167_m_BGM_DraBuru_Turn_NEXT_2, bank=3, volume=80, priority=100, player=6, w8=0xFF, name=sname_0167, id=170
song_0168:
	song_entry mid_0168_m_BGM_DraBuru_Boss_START_1, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0168, id=171
song_0169:
	song_entry mid_0169_m_BGM_DraBuru_Boss_START_FF, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0169, id=172
song_0170:
	song_entry mid_0170_m_BGM_DraBuru_Boss_01, bank=3, volume=75, priority=0, player=0, w8=0xFF, name=sname_0170, id=173
song_0171:
	song_entry mid_0171_m_BGM_DraBuru_BOSS_BOSS, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_0171, id=174
song_0172:
	song_entry mid_0172_m_BGM_DraBuru_BOSS_NG, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0172, id=175
song_0173:
	song_entry mid_0173_m_BGM_DraBuru_BOSS_Clear, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0173, id=176
song_0174:
	song_entry mid_0174_m_BGM_DraBuru_REST_LvUp, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0174, id=177
song_0175:
	song_entry mid_0175_m_BGM_DraBuru_EP_1, bank=3, volume=95, priority=0, player=0, w8=0xFF, name=sname_0175, id=178
song_0176:
	song_entry mid_0176_m_BGM_Monna_INTRO_0_City, bank=3, volume=25, priority=0, player=2, w8=0xFF, name=sname_0176, id=180
song_0177:
	song_entry mid_0177_m_BGM_Monna_INTRO_0_Shop, bank=3, volume=30, priority=0, player=2, w8=0xFF, name=sname_0177, id=181
song_0178:
	song_entry mid_0178_m_BGM_Monna_INTRO_1, bank=3, volume=85, priority=0, player=2, w8=0xFF, name=sname_0178, id=182
song_0179:
	song_entry mid_0179_m_BGM_Monna_INTRO_2, bank=3, volume=100, priority=0, player=2, w8=0xFF, name=sname_0179, id=183
song_0180:
	song_entry mid_0180_m_BGM_Monna_01, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0180, id=184
song_0181:
	song_entry mid_0181_m_BGM_Monna_02, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0181, id=185
song_0182:
	song_entry mid_0182_m_BGM_Monna_03, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0182, id=186
song_0183:
	song_entry mid_0183_m_BGM_Monna_04, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0183, id=187
song_0184:
	song_entry mid_0184_m_BGM_Monna_05, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0184, id=188
song_0185:
	song_entry mid_0185_m_BGM_Monna_06, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0185, id=189
song_0186:
	song_entry mid_0186_m_BGM_Monna_07, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0186, id=190
song_0187:
	song_entry mid_0187_m_BGM_Monna_08, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0187, id=191
song_0188:
	song_entry mid_0188_m_BGM_Monna_09, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0188, id=192
song_0189:
	song_entry mid_0189_m_BGM_Monna_10, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0189, id=193
song_0190:
	song_entry mid_0190_m_BGM_Monna_END, bank=3, volume=80, priority=0, player=2, w8=0xFF, name=sname_0190, id=194
song_0191:
	song_entry mid_0191_m_BGM_Monna_Loop, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0191, id=195
song_0192:
	song_entry mid_0192_m_BGM_Monna_Result_OK_10, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0192, id=196
song_0193:
	song_entry mid_0193_m_BGM_Monna_Result_OK_11, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0193, id=197
song_0194:
	song_entry mid_0194_m_BGM_Monna_Result_NG_10, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0194, id=198
song_0195:
	song_entry mid_0195_m_BGM_Monna_Result_NG_11, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0195, id=199
song_0196:
	song_entry mid_0196_m_BGM_Monna_NEXT_10, bank=3, volume=100, priority=0, player=1, w8=0xFF, name=sname_0196, id=200
song_0197:
	song_entry mid_0197_m_BGM_Monna_NEXT_11, bank=3, volume=100, priority=0, player=1, w8=0xFF, name=sname_0197, id=201
song_0198:
	song_entry mid_0198_m_BGM_Monna_BOSS_10, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0198, id=202
song_0199:
	song_entry mid_0199_m_BGM_Monna_EP_1, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0199, id=203
song_0200:
	song_entry mid_0200_m_BGM_Monna_EP_Shop, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0200, id=204
song_0201:
	song_entry mid_0201_m_BGM_Monna_FF_Safe_01, bank=3, volume=60, priority=1, player=1, w8=0xFF, name=sname_0201, id=205
song_0202:
	song_entry mid_0202_m_BGM_Voya_Demo_IN_05, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0202, id=206
song_0203:
	song_entry mid_0203_m_BGM_Voya_Demo_IN_10, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0203, id=207
song_0204:
	song_entry mid_0204_m_BGM_Voya_Demo_IN_50, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0204, id=208
song_0205:
	song_entry mid_0205_m_BGM_Voya_Demo_IN_51, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0205, id=209
song_0206:
	song_entry mid_0206_m_BGM_Voya_Turn_OK_1, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0206, id=210
song_0207:
	song_entry mid_0207_m_BGM_Voya_Turn_OK_2, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0207, id=211
song_0208:
	song_entry mid_0208_m_BGM_Voya_Turn_NG_1, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0208, id=212
song_0209:
	song_entry mid_0209_m_BGM_Voya_Turn_NG_2, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0209, id=213
song_0210:
	song_entry mid_0210_m_BGM_Voya_Turn_NEXT_1, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_0210, id=214
song_0211:
	song_entry mid_0211_m_BGM_Voya_Turn_NEXT_2, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_0211, id=215
song_0212:
	song_entry mid_0212_m_BGM_Voya_Game_END_1, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0212, id=216
song_0213:
	song_entry mid_0213_m_BGM_Voya_BOSS_Fanfare_1, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0213, id=217
song_0214:
	song_entry mid_0214_m_BGM_Voya_BOSS_10, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0214, id=218
song_0215:
	song_entry mid_0215_m_BGM_KAEDE_Demo_01, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0215, id=219
song_0216:
	song_entry mid_0216_m_BGM_KAEDE_Demo_02, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0216, id=220
song_0217:
	song_entry mid_0217_m_BGM_KAEDE_Demo_03, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0217, id=221
song_0218:
	song_entry mid_0218_m_BGM_KAEDE_Demo_04, bank=3, volume=100, priority=0, player=1, w8=0xFF, name=sname_0218, id=222
song_0219:
	song_entry mid_0219_m_BGM_KAEDE_Demo_05, bank=3, volume=110, priority=0, player=0, w8=0xFF, name=sname_0219, id=223
song_0220:
	song_entry mid_0220_m_BGM_KAEDE_Demo_06, bank=3, volume=60, priority=0, player=1, w8=0xFF, name=sname_0220, id=224
song_0221:
	song_entry mid_0221_m_BGM_KAEDE_Demo_10, bank=3, volume=110, priority=0, player=1, w8=0xFF, name=sname_0221, id=225
song_0222:
	song_entry mid_0222_m_BGM_KAEDE_Demo_11, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0222, id=226
song_0223:
	song_entry mid_0223_m_BGM_KAEDE_Game_Intro, bank=3, volume=110, priority=0, player=1, w8=0xFF, name=sname_0223, id=227
song_0224:
	song_entry mid_0224_m_BGM_KAEDE_Game_1_1, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0224, id=228
song_0225:
	song_entry mid_0225_m_BGM_KAEDE_Game_1_2, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0225, id=229
song_0226:
	song_entry mid_0226_m_BGM_KAEDE_Game_1_3, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0226, id=230
song_0227:
	song_entry mid_0227_m_BGM_KAEDE_Game_1_4, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0227, id=231
song_0228:
	song_entry mid_0228_m_BGM_KAEDE_Game_1_5, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0228, id=232
song_0229:
	song_entry mid_0229_m_BGM_KAEDE_Game_1_6, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0229, id=233
song_0230:
	song_entry mid_0230_m_BGM_KAEDE_Game_1_7, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0230, id=234
song_0231:
	song_entry mid_0231_m_BGM_KAEDE_Game_1_8, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0231, id=235
song_0232:
	song_entry mid_0232_m_BGM_KAEDE_Game_1_NEXT, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0232, id=236
song_0233:
	song_entry mid_0233_m_BGM_KAEDE_Game_1_END, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0233, id=237
song_0234:
	song_entry mid_0234_m_BGM_KAEDE_Game_2_1, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0234, id=238
song_0235:
	song_entry mid_0235_m_BGM_KAEDE_Game_2_2, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0235, id=239
song_0236:
	song_entry mid_0236_m_BGM_KAEDE_Game_2_3, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0236, id=240
song_0237:
	song_entry mid_0237_m_BGM_KAEDE_Game_2_4, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0237, id=241
song_0238:
	song_entry mid_0238_m_BGM_KAEDE_Game_2_5, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0238, id=242
song_0239:
	song_entry mid_0239_m_BGM_KAEDE_Game_2_6, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0239, id=243
song_0240:
	song_entry mid_0240_m_BGM_KAEDE_Game_2_7, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0240, id=244
song_0241:
	song_entry mid_0241_m_BGM_KAEDE_Game_2_8, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0241, id=245
song_0242:
	song_entry mid_0242_m_BGM_KAEDE_Game_2_NEXT, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0242, id=246
song_0243:
	song_entry mid_0243_m_BGM_KAEDE_Game_2_END, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0243, id=247
song_0244:
	song_entry mid_0244_m_BGM_KAEDE_Game_3_1, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0244, id=248
song_0245:
	song_entry mid_0245_m_BGM_KAEDE_Game_3_2, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0245, id=249
song_0246:
	song_entry mid_0246_m_BGM_KAEDE_Game_3_3, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0246, id=250
song_0247:
	song_entry mid_0247_m_BGM_KAEDE_Game_3_4, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0247, id=251
song_0248:
	song_entry mid_0248_m_BGM_KAEDE_Game_3_5, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0248, id=252
song_0249:
	song_entry mid_0249_m_BGM_KAEDE_Game_3_6, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0249, id=253
song_0250:
	song_entry mid_0250_m_BGM_KAEDE_Game_3_7, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0250, id=254
song_0251:
	song_entry mid_0251_m_BGM_KAEDE_Game_3_8, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_0251, id=255
song_0252:
	song_entry mid_0252_m_BGM_KAEDE_Game_3_NEXT, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0252, id=256
song_0253:
	song_entry mid_0253_m_BGM_KAEDE_Game_3_END, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0253, id=257
song_0254:
	song_entry mid_0254_m_BGM_KAEDE_Game_BOSS_Next, bank=3, volume=60, priority=0, player=1, w8=0xFF, name=sname_0254, id=258
song_0255:
	song_entry mid_0255_m_BGM_KAEDE_BOSS_10, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0255, id=259
song_0256:
	song_entry mid_0256_m_BGM_KAEDE_Demo_EP_10, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0256, id=260
song_0257:
	song_entry mid_0257_m_BGM_KAEDE_Demo_EP_11, bank=3, volume=85, priority=0, player=1, w8=0xFF, name=sname_0257, id=261
song_0258:
	song_entry mid_0258_m_BGM_KAEDE_Demo_EP_12, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0258, id=262
song_0259:
	song_entry mid_0259_m_BGM_Loo_Demo_MAP_1, bank=3, volume=50, priority=0, player=2, w8=0xFF, name=sname_0259, id=263
song_0260:
	song_entry mid_0260_m_BGM_Loo_Demo_10, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0260, id=264
song_0261:
	song_entry mid_0261_m_BGM_Loo_Demo_11, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0261, id=265
song_0262:
	song_entry mid_0262_m_BGM_Loo_Demo_112, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0262, id=266
song_0263:
	song_entry mid_0263_m_BGM_Loo_Demo_12, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0263, id=267
song_0264:
	song_entry mid_0264_m_BGM_Loo_Demo_13, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0264, id=268
song_0265:
	song_entry mid_0265_m_BGM_Loo_Game_1_Intro, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0265, id=269
song_0266:
	song_entry mid_0266_m_BGM_Loo_Game_1_1, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0266, id=270
song_0267:
	song_entry mid_0267_m_BGM_Loo_Game_1_2, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0267, id=271
song_0268:
	song_entry mid_0268_m_BGM_Loo_Game_1_3, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0268, id=272
song_0269:
	song_entry mid_0269_m_BGM_Loo_Game_1_4, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0269, id=273
song_0270:
	song_entry mid_0270_m_BGM_Loo_Game_1_5, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0270, id=274
song_0271:
	song_entry mid_0271_m_BGM_Loo_Game_1_6, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0271, id=275
song_0272:
	song_entry mid_0272_m_BGM_Loo_Game_1_7, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0272, id=276
song_0273:
	song_entry mid_0273_m_BGM_Loo_Game_1_8, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0273, id=277
song_0274:
	song_entry mid_0274_m_BGM_Loo_Game_1_NEXT, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0274, id=278
song_0275:
	song_entry mid_0275_m_BGM_Loo_Game_1_END, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0275, id=279
song_0276:
	song_entry mid_0276_m_BGM_Loo_BOSS_FF_Start, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0276, id=280
song_0277:
	song_entry mid_0277_m_BGM_Loo_BOSS_10, bank=3, volume=75, priority=0, player=0, w8=0xFF, name=sname_0277, id=281
song_0278:
	song_entry mid_0278_m_BGM_Loo_EP_05, bank=3, volume=55, priority=0, player=4, w8=0xFF, name=sname_0278, id=282
song_0279:
	song_entry mid_0279_m_BGM_Loo_EP_10, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0279, id=283
song_0280:
	song_entry mid_0280_m_BGM_Loo_EP_11, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0280, id=284
song_0281:
	song_entry mid_0281_m_BGM_Bio_Demo_0, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0281, id=285
song_0282:
	song_entry mid_0282_m_BGM_Bio_Turn_OK_1, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0282, id=286
song_0283:
	song_entry mid_0283_m_BGM_Bio_Turn_OK_2, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0283, id=287
song_0284:
	song_entry mid_0284_m_BGM_Bio_Turn_OK_3, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0284, id=288
song_0285:
	song_entry mid_0285_m_BGM_Bio_Turn_NG_1, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0285, id=289
song_0286:
	song_entry mid_0286_m_BGM_Bio_Turn_NG_2, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0286, id=290
song_0287:
	song_entry mid_0287_m_BGM_Bio_Turn_NG_3, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0287, id=291
song_0288:
	song_entry mid_0288_m_BGM_Bio_Turn_NEXT_1, bank=3, volume=75, priority=0, player=0, w8=0xFF, name=sname_0288, id=292
song_0289:
	song_entry mid_0289_m_BGM_Bio_Turn_NEXT_2, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0289, id=293
song_0290:
	song_entry mid_0290_m_BGM_Bio_Turn_NEXT_3, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0290, id=294
song_0291:
	song_entry mid_0291_m_BGM_Bio_BOSS_FF_Start, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_0291, id=295
song_0292:
	song_entry mid_0292_m_BGM_Bio_BOSS_10, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0292, id=296
song_0293:
	song_entry mid_0293_m_BGM_Bio_END, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0293, id=297
song_0294:
	song_entry mid_0294_m_BGM_Bio_END_01, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0294, id=298
song_0295:
	song_entry mid_0295_m_BGM_Bio_Demo_EP_1, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0295, id=299
song_0296:
	song_entry mid_0296_s_BASIC_PAUSE_ON, bank=1, volume=50, priority=121, player=7, w8=0xFF, name=sname_0296, id=300
song_0297:
	song_entry mid_0297_s_BASIC_PAUSE_OFF, bank=1, volume=80, priority=121, player=7, w8=0xFF, name=sname_0297, id=301
song_0298:
	song_entry mid_0298_s_BASIC_CURSOR_01, bank=1, volume=30, priority=100, player=4, w8=0xFF, name=sname_0298, id=302
song_0299:
	song_entry mid_0299_s_BASIC_CURSOR_02, bank=3, volume=30, priority=100, player=4, w8=0xFF, name=sname_0299, id=303
song_0300:
	song_entry mid_0300_s_BASIC_BUTTON_A, bank=3, volume=50, priority=110, player=5, w8=0xFF, name=sname_0300, id=304
song_0301:
	song_entry mid_0301_s_BASIC_BUTTON_A1, bank=3, volume=60, priority=110, player=5, w8=0xFF, name=sname_0301, id=305
song_0302:
	song_entry mid_0302_s_BASIC_BUTTON_A2, bank=1, volume=70, priority=110, player=5, w8=0xFF, name=sname_0302, id=306
song_0303:
	song_entry mid_0303_s_BASIC_BUTTON_As1, bank=3, volume=30, priority=110, player=5, w8=0xFF, name=sname_0303, id=307
song_0304:
	song_entry mid_0304_s_BASIC_BUTTON_As2, bank=3, volume=30, priority=110, player=5, w8=0xFF, name=sname_0304, id=308
song_0305:
	song_entry mid_0305_s_BASIC_BUTTON_A_Delete, bank=3, volume=60, priority=111, player=5, w8=0xFF, name=sname_0305, id=309
song_0306:
	song_entry mid_0306_s_BASIC_BUTTON_B, bank=1, volume=45, priority=110, player=6, w8=0xFF, name=sname_0306, id=310
song_0307:
	song_entry mid_0307_s_BASIC_BUTTON_Bs, bank=1, volume=50, priority=110, player=6, w8=0xFF, name=sname_0307, id=311
song_0308:
	song_entry mid_0308_s_BASIC_DAME_1, bank=3, volume=120, priority=110, player=5, w8=0xFF, name=sname_0308, id=312
song_0309:
	song_entry mid_0309_s_BOMB_Window_Change, bank=1, volume=75, priority=110, player=7, w8=0xFF, name=sname_0309, id=313
song_0310:
	song_entry mid_0310_s_BOMB_Window_Change_2, bank=1, volume=60, priority=110, player=7, w8=0xFF, name=sname_0310, id=314
song_0311:
	song_entry mid_0311_s_Demo_Title_BUMP, bank=1, volume=100, priority=120, player=5, w8=0xFF, name=sname_0311, id=315
song_0312:
	song_entry mid_0312_s_BOMB_Door_Open, bank=1, volume=100, priority=100, player=4, w8=0xFF, name=sname_0312, id=316
song_0313:
	song_entry mid_0313_s_BOMB_Door_Close, bank=1, volume=100, priority=100, player=4, w8=0xFF, name=sname_0313, id=317
song_0314:
	song_entry mid_0314_s_BOMB_END_OFF_1, bank=3, volume=30, priority=100, player=4, w8=0xFF, name=sname_0314, id=318
song_0315:
	song_entry mid_0315_s_Demo_1UP_01, bank=1, volume=75, priority=119, player=7, w8=0xFF, name=sname_0315, id=319
song_0316:
	song_entry mid_0316_s_BOMB_BOSS_BOXING_Wind_1, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0316, id=320
song_0317:
	song_entry mid_0317_s_BOMB_BOSS_BOXING_Wind_2, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0317, id=321
song_0318:
	song_entry mid_0318_s_BOMB_BOSS_BOXING_Wind_3, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0318, id=322
song_0319:
	song_entry mid_0319_s_BOMB_BOSS_BOXING_Punch_1, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0319, id=323
song_0320:
	song_entry mid_0320_s_BOMB_BOSS_BOXING_Punch_2, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0320, id=324
song_0321:
	song_entry mid_0321_s_BOMB_BOSS_BOXING_Punch_3, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0321, id=325
song_0322:
	song_entry mid_0322_s_BOMB_BOSS_BOXING_OK_01, bank=3, volume=95, priority=100, player=4, w8=0xFF, name=sname_0322, id=326
song_0323:
	song_entry mid_0323_s_BOMB_BOSS_BOXING_OK_02, bank=3, volume=95, priority=100, player=4, w8=0xFF, name=sname_0323, id=327
song_0324:
	song_entry mid_0324_s_BOMB_BOSS_BOXING_OK_03, bank=3, volume=95, priority=100, player=4, w8=0xFF, name=sname_0324, id=328
song_0325:
	song_entry mid_0325_s_BOMB_BOSS_BOXING_NG_01, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0325, id=329
song_0326:
	song_entry mid_0326_s_BOMB_BOSS_BOXING_NG_02, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0326, id=330
song_0327:
	song_entry mid_0327_s_BOMB_BOSS_BOXING_NG_03, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0327, id=331
song_0328:
	song_entry mid_0328_s_BOMB_BOSS_BOXING_Power_1, bank=3, volume=40, priority=100, player=4, w8=0xFF, name=sname_0328, id=332
song_0329:
	song_entry mid_0329_s_BOMB_BOSS_BOXING_Power_2, bank=3, volume=40, priority=100, player=4, w8=0xFF, name=sname_0329, id=333
song_0330:
	song_entry mid_0330_s_BOMB_BOSS_BOXING_WIN, bank=3, volume=90, priority=101, player=5, w8=0xFF, name=sname_0330, id=334
song_0331:
	song_entry mid_0331_s_BOMB_BOSS_BOXING_LOSE, bank=3, volume=90, priority=101, player=0, w8=0xFF, name=sname_0331, id=335
song_0332:
	song_entry mid_0332_s_BOMB_BOSS_BOXING_GONG, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0332, id=336
song_0333:
	song_entry mid_0333_s_BOMB_BOSS_BOXING_Hit_01, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0333, id=337
song_0334:
	song_entry mid_0334_s_BOMB_BOSS_BOXING_Hit_02, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0334, id=338
song_0335:
	song_entry mid_0335_s_BOMB_BOSS_BOXING_Hit_03, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0335, id=339
song_0336:
	song_entry mid_0336_s_BOMB_BOSS_BOXING_Hit_04, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0336, id=340
song_0337:
	song_entry mid_0337_s_BOMB_BOSS_BOXING_Hit_05, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0337, id=341
song_0338:
	song_entry mid_0338_s_BOMB_BOSS_BOXING_Hit_06, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0338, id=342
song_0339:
	song_entry mid_0339_s_BOMB_BOSS_BOXING_Hit_07, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0339, id=343
song_0340:
	song_entry mid_0340_s_BOMB_BOSS_BOXING_Hit_08, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0340, id=344
song_0341:
	song_entry mid_0341_s_BOMB_BOSS_Nail_FALL_0, bank=3, volume=80, priority=90, player=1, w8=0xFF, name=sname_0341, id=345
song_0342:
	song_entry mid_0342_s_BOMB_BOSS_Nail_FALL_1, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0342, id=346
song_0343:
	song_entry mid_0343_s_BOMB_BOSS_Nail_ON_1, bank=1, volume=100, priority=100, player=5, w8=0xFF, name=sname_0343, id=347
song_0344:
	song_entry mid_0344_s_BOMB_BOSS_Nail_Hit_OK_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0344, id=348
song_0345:
	song_entry mid_0345_s_BOMB_BOSS_Nail_Hit_L_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0345, id=349
song_0346:
	song_entry mid_0346_s_BOMB_BOSS_Nail_Hit_R_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0346, id=350
song_0347:
	song_entry mid_0347_s_BOMB_BOSS_Nail_NG_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0347, id=351
song_0348:
	song_entry mid_0348_s_BOMB_BOSS_Nail_Finish_1, bank=1, volume=100, priority=100, player=4, w8=0xFF, name=sname_0348, id=352
song_0349:
	song_entry mid_0349_s_BOMB_BOSS_BaseB_Cheer_1, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0349, id=353
song_0350:
	song_entry mid_0350_s_BOMB_BOSS_BaseB_Cheer_2, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0350, id=354
song_0351:
	song_entry mid_0351_s_BOMB_BOSS_BaseB_Boo_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0351, id=355
song_0352:
	song_entry mid_0352_s_BOMB_BOSS_BaseB_Boo_2, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0352, id=356
song_0353:
	song_entry mid_0353_s_BOMB_BOSS_BaseB_Miss_1, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_0353, id=357
song_0354:
	song_entry mid_0354_s_BOMB_BOSS_BaseB_Miss_2, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_0354, id=358
song_0355:
	song_entry mid_0355_s_BOMB_BOSS_BaseB_ReSet, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0355, id=359
song_0356:
	song_entry mid_0356_s_BOMB_BOSS_Galala_Shot_01, bank=3, volume=40, priority=90, player=6, w8=0xFF, name=sname_0356, id=360
song_0357:
	song_entry mid_0357_s_BOMB_BOSS_Galala_Hit_01, bank=1, volume=40, priority=90, player=5, w8=0xFF, name=sname_0357, id=361
song_0358:
	song_entry mid_0358_s_BOMB_BOSS_Galala_Hit_02, bank=1, volume=40, priority=85, player=5, w8=0xFF, name=sname_0358, id=362
song_0359:
	song_entry mid_0359_s_BOMB_BOSS_Galala_Hit_03, bank=3, volume=20, priority=93, player=5, w8=0xFF, name=sname_0359, id=363
song_0360:
	song_entry mid_0360_s_BOMB_BOSS_Galala_Hit_04, bank=3, volume=80, priority=95, player=5, w8=0xFF, name=sname_0360, id=364
song_0361:
	song_entry mid_0361_s_BOMB_BOSS_Galala_CORE_02, bank=3, volume=60, priority=90, player=4, w8=0xFF, name=sname_0361, id=365
song_0362:
	song_entry mid_0362_s_BOMB_BOSS_Galala_CORE_03, bank=3, volume=20, priority=80, player=4, w8=0xFF, name=sname_0362, id=366
song_0363:
	song_entry mid_0363_s_BOMB_BOSS_Galala_Hole_01, bank=3, volume=110, priority=90, player=4, w8=0xFF, name=sname_0363, id=367
song_0364:
	song_entry mid_0364_s_BOMB_BOSS_Galala_Bonus, bank=3, volume=70, priority=95, player=6, w8=0xFF, name=sname_0364, id=368
song_0365:
	song_entry mid_0365_s_BOMB_BOSS_Galala_ITEM_01, bank=3, volume=100, priority=95, player=4, w8=0xFF, name=sname_0365, id=369
song_0366:
	song_entry mid_0366_s_BOMB_BOSS_Galala_OK_01, bank=1, volume=80, priority=100, player=6, w8=0xFF, name=sname_0366, id=370
song_0367:
	song_entry mid_0367_s_BOMB_BOSS_Galala_Fail_01, bank=3, volume=120, priority=100, player=6, w8=0xFF, name=sname_0367, id=371
song_0368:
	song_entry mid_0368_s_BOMB_BOSS_Galala_Barrier, bank=3, volume=80, priority=90, player=7, w8=0xFF, name=sname_0368, id=372
song_0369:
	song_entry mid_0369_s_BOMB_BOSS_Goma_FALL_0, bank=3, volume=90, priority=90, player=1, w8=0xFF, name=sname_0369, id=380
song_0370:
	song_entry mid_0370_s_BOMB_BOSS_Goma_FALL_9, bank=3, volume=90, priority=90, player=0, w8=0xFF, name=sname_0370, id=381
song_0371:
	song_entry mid_0371_s_BOMB_BOSS_Goma_JUMP_1, bank=3, volume=40, priority=90, player=4, w8=0xFF, name=sname_0371, id=382
song_0372:
	song_entry mid_0372_s_BOMB_BOSS_Goma_Walk_1, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0372, id=383
song_0373:
	song_entry mid_0373_s_BOMB_BOSS_Goma_Walk_2, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0373, id=384
song_0374:
	song_entry mid_0374_s_BOMB_BOSS_Goma_Walk_3, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0374, id=385
song_0375:
	song_entry mid_0375_s_BOMB_BOSS_Goma_ITEM_1, bank=1, volume=100, priority=100, player=6, w8=0xFF, name=sname_0375, id=386
song_0376:
	song_entry mid_0376_s_BOMB_BOSS_Draran_Hit_1, bank=3, volume=120, priority=90, player=3, w8=0xFF, name=sname_0376, id=387
song_0377:
	song_entry mid_0377_s_BOMB_BOSS_Draran_Hit_2, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0377, id=388
song_0378:
	song_entry mid_0378_s_BOMB_BOSS_Draran_Hit_3, bank=3, volume=75, priority=90, player=5, w8=0xFF, name=sname_0378, id=389
song_0379:
	song_entry mid_0379_s_BOMB_BOSS_Draran_Damage_1, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_0379, id=390
song_0380:
	song_entry mid_0380_s_BOMB_BOSS_Earthquake, bank=3, volume=110, priority=90, player=3, w8=0xFF, name=sname_0380, id=391
song_0381:
	song_entry mid_0381_s_Demo_DraBuru_Wiper_1_1, bank=3, volume=55, priority=100, player=3, w8=0xFF, name=sname_0381, id=400
song_0382:
	song_entry mid_0382_s_Demo_DraBuru_Wiper_1_2, bank=3, volume=55, priority=100, player=3, w8=0xFF, name=sname_0382, id=401
song_0383:
	song_entry mid_0383_s_Demo_DraBuru_Wiper_2_1, bank=3, volume=55, priority=100, player=3, w8=0xFF, name=sname_0383, id=402
song_0384:
	song_entry mid_0384_s_Demo_DraBuru_Wiper_2_2, bank=3, volume=55, priority=100, player=3, w8=0xFF, name=sname_0384, id=403
song_0385:
	song_entry mid_0385_s_Demo_Dra_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0385, id=404
song_0386:
	song_entry mid_0386_s_Demo_Dra_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0386, id=405
song_0387:
	song_entry mid_0387_s_Demo_Dra_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0387, id=406
song_0388:
	song_entry mid_0388_s_Demo_DraBuru_EP_Car, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0388, id=407
song_0389:
	song_entry mid_0389_s_Demo_DraBuru_EP_Change, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0389, id=408
song_0390:
	song_entry mid_0390_s_Demo_Monna_Bird_01, bank=3, volume=15, priority=100, player=4, w8=0xFF, name=sname_0390, id=409
song_0391:
	song_entry mid_0391_s_Demo_Monna_Bird_02, bank=3, volume=40, priority=100, player=5, w8=0xFF, name=sname_0391, id=410
song_0392:
	song_entry mid_0392_s_Demo_Monna_Walk_01, bank=3, volume=30, priority=100, player=6, w8=0xFF, name=sname_0392, id=411
song_0393:
	song_entry mid_0393_s_Demo_Monna_Walk_02, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0393, id=412
song_0394:
	song_entry mid_0394_s_Demo_Monna_Shutter_01, bank=3, volume=50, priority=100, player=4, w8=0xFF, name=sname_0394, id=413
song_0395:
	song_entry mid_0395_s_Demo_Monna_Slide_01, bank=3, volume=30, priority=100, player=5, w8=0xFF, name=sname_0395, id=414
song_0396:
	song_entry mid_0396_s_Demo_Monna_KACHA_01, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0396, id=415
song_0397:
	song_entry mid_0397_s_Demo_Monna_Goggles_01, bank=3, volume=110, priority=100, player=4, w8=0xFF, name=sname_0397, id=416
song_0398:
	song_entry mid_0398_s_Demo_Mon_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0398, id=417
song_0399:
	song_entry mid_0399_s_Demo_Mon_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0399, id=418
song_0400:
	song_entry mid_0400_s_Demo_Mon_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0400, id=419
song_0401:
	song_entry mid_0401_s_Demo_Mon_GameOver, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0401, id=420
song_0402:
	song_entry mid_0402_s_Demo_Monna_EP_Bike, bank=1, volume=50, priority=80, player=6, w8=0xFF, name=sname_0402, id=421
song_0403:
	song_entry mid_0403_s_Demo_Monna_EP_Clock, bank=1, volume=60, priority=80, player=6, w8=0xFF, name=sname_0403, id=422
song_0404:
	song_entry mid_0404_s_Demo_AFRO_Tel_Catch, bank=1, volume=60, priority=80, player=7, w8=0xFF, name=sname_0404, id=423
song_0405:
	song_entry mid_0405_s_Demo_AFRO_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0405, id=424
song_0406:
	song_entry mid_0406_s_Demo_AFRO_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0406, id=425
song_0407:
	song_entry mid_0407_s_Demo_AFRO_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0407, id=426
song_0408:
	song_entry mid_0408_s_Demo_Bio_Crash_1, bank=3, volume=100, priority=100, player=2, w8=0xFF, name=sname_0408, id=427
song_0409:
	song_entry mid_0409_s_Demo_Bio_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0409, id=428
song_0410:
	song_entry mid_0410_s_Demo_Bio_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0410, id=429
song_0411:
	song_entry mid_0411_s_Demo_Bio_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0411, id=430
song_0412:
	song_entry mid_0412_s_Demo_KAEDE_Open_1, bank=1, volume=70, priority=100, player=2, w8=0xFF, name=sname_0412, id=431
song_0413:
	song_entry mid_0413_s_Demo_KAEDE_Go_1, bank=3, volume=60, priority=100, player=3, w8=0xFF, name=sname_0413, id=432
song_0414:
	song_entry mid_0414_s_Demo_KAEDE_KATANA_1, bank=1, volume=90, priority=100, player=3, w8=0xFF, name=sname_0414, id=433
song_0415:
	song_entry mid_0415_s_Demo_KAEDE_TEKI_UP, bank=1, volume=90, priority=100, player=3, w8=0xFF, name=sname_0415, id=434
song_0416:
	song_entry mid_0416_s_Demo_KAEDE_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0416, id=435
song_0417:
	song_entry mid_0417_s_Demo_KAEDE_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0417, id=436
song_0418:
	song_entry mid_0418_s_Demo_KAEDE_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0418, id=437
song_0419:
	song_entry mid_0419_s_Demo_KAEDE_EP_STEP, bank=3, volume=40, priority=80, player=4, w8=0xFF, name=sname_0419, id=438
song_0420:
	song_entry mid_0420_s_Demo_KAEDE_EP_Voice, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0420, id=439
song_0421:
	song_entry mid_0421_s_Demo_KAEDE_KATANA_2, bank=1, volume=20, priority=80, player=3, w8=0xFF, name=sname_0421, id=440
song_0422:
	song_entry mid_0422_s_Demo_KAEDE_TEKI_Laugh_1, bank=1, volume=90, priority=80, player=3, w8=0xFF, name=sname_0422, id=441
song_0423:
	song_entry mid_0423_s_Demo_KAEDE_EP_Jump, bank=1, volume=40, priority=50, player=4, w8=0xFF, name=sname_0423, id=442
song_0424:
	song_entry mid_0424_s_Demo_Loo_Paper_1, bank=3, volume=90, priority=100, player=3, w8=0xFF, name=sname_0424, id=443
song_0425:
	song_entry mid_0425_s_Demo_Loo_Water_OUT_1, bank=3, volume=90, priority=100, player=3, w8=0xFF, name=sname_0425, id=444
song_0426:
	song_entry mid_0426_s_Demo_Loo_Water_IN_1, bank=3, volume=90, priority=100, player=3, w8=0xFF, name=sname_0426, id=445
song_0427:
	song_entry mid_0427_s_Demo_Loo_Flap, bank=3, volume=90, priority=100, player=3, w8=0xFF, name=sname_0427, id=446
song_0428:
	song_entry mid_0428_s_Demo_Loo_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0428, id=447
song_0429:
	song_entry mid_0429_s_Demo_Loo_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0429, id=448
song_0430:
	song_entry mid_0430_s_Demo_Loo_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0430, id=449
song_0431:
	song_entry mid_0431_s_Demo_Loo_EP_Water_JET_1, bank=3, volume=100, priority=80, player=4, w8=0xFF, name=sname_0431, id=450
song_0432:
	song_entry mid_0432_s_Demo_Loo_EP_Water_JET_2, bank=3, volume=60, priority=80, player=5, w8=0xFF, name=sname_0432, id=451
song_0433:
	song_entry mid_0433_s_Demo_Loo_EP_Rocket, bank=3, volume=65, priority=80, player=4, w8=0xFF, name=sname_0433, id=452
song_0434:
	song_entry mid_0434_s_Demo_Loo_EP_FALL_01, bank=3, volume=35, priority=80, player=5, w8=0xFF, name=sname_0434, id=453
song_0435:
	song_entry mid_0435_s_Demo_Loo_EP_Bird_01, bank=3, volume=45, priority=80, player=4, w8=0xFF, name=sname_0435, id=454
song_0436:
	song_entry mid_0436_s_Demo_Loo_EP_Swim_01, bank=3, volume=20, priority=80, player=6, w8=0xFF, name=sname_0436, id=455
song_0437:
	song_entry mid_0437_s_Demo_Voya_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0437, id=456
song_0438:
	song_entry mid_0438_s_Demo_Voya_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0438, id=457
song_0439:
	song_entry mid_0439_s_Demo_Voya_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0439, id=458
song_0440:
	song_entry mid_0440_s_Demo_Voya_EP_BOARD_1, bank=3, volume=70, priority=80, player=4, w8=0xFF, name=sname_0440, id=459
song_0441:
	song_entry mid_0441_s_Demo_Wario_CountDown_3, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0441, id=460
song_0442:
	song_entry mid_0442_s_Demo_Wario_CountDown_2, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0442, id=461
song_0443:
	song_entry mid_0443_s_Demo_Wario_CountDown_1, bank=1, volume=40, priority=80, player=7, w8=0xFF, name=sname_0443, id=462
song_0444:
	song_entry mid_0444_s_Demo_Wario_EP_Earthquake, bank=3, volume=120, priority=80, player=4, w8=0xFF, name=sname_0444, id=463
song_0445:
	song_entry mid_0445_s_Demo_Wario_EP_UP_Loo, bank=3, volume=90, priority=80, player=4, w8=0xFF, name=sname_0445, id=464
song_0446:
	song_entry mid_0446_s_Demo_Wario_EP_UP_Wario, bank=3, volume=120, priority=80, player=5, w8=0xFF, name=sname_0446, id=465
song_0447:
	song_entry mid_0447_s_BOMB_Success_01, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0447, id=481
song_0448:
	song_entry mid_0448_s_BOMB_OK_01, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0448, id=482
song_0449:
	song_entry mid_0449_s_BOMB_OK_02_Bamboo, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0449, id=483
song_0450:
	song_entry mid_0450_s_BOMB_OK_03, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0450, id=484
song_0451:
	song_entry mid_0451_s_BOMB_OK_04, bank=1, volume=50, priority=100, player=4, w8=0xFF, name=sname_0451, id=485
song_0452:
	song_entry mid_0452_s_BOMB_OK_05, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0452, id=486
song_0453:
	song_entry mid_0453_s_BOMB_OK_06, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0453, id=487
song_0454:
	song_entry mid_0454_s_BOMB_OK_07, bank=3, volume=110, priority=100, player=4, w8=0xFF, name=sname_0454, id=488
song_0455:
	song_entry mid_0455_s_BOMB_OK_08, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0455, id=489
song_0456:
	song_entry mid_0456_s_BOMB_OK_09, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0456, id=490
song_0457:
	song_entry mid_0457_s_BOMB_OK_10_Suck_Apple, bank=1, volume=85, priority=101, player=4, w8=0xFF, name=sname_0457, id=491
song_0458:
	song_entry mid_0458_s_BOMB_OK_11_SPY, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0458, id=492
song_0459:
	song_entry mid_0459_s_BOMB_OK_12, bank=1, volume=70, priority=100, player=4, w8=0xFF, name=sname_0459, id=493
song_0460:
	song_entry mid_0460_s_BOMB_OK_13, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0460, id=494
song_0461:
	song_entry mid_0461_s_BOMB_OK_14, bank=3, volume=60, priority=101, player=5, w8=0xFF, name=sname_0461, id=495
song_0462:
	song_entry mid_0462_s_BOMB_OK_15, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0462, id=496
song_0463:
	song_entry mid_0463_s_BOMB_OK_17, bank=3, volume=70, priority=102, player=4, w8=0xFF, name=sname_0463, id=498
song_0464:
	song_entry mid_0464_s_BOMB_OK_19, bank=3, volume=110, priority=101, player=4, w8=0xFF, name=sname_0464, id=500
song_0465:
	song_entry mid_0465_s_BOMB_OK_20, bank=3, volume=85, priority=101, player=4, w8=0xFF, name=sname_0465, id=501
song_0466:
	song_entry mid_0466_s_BOMB_OK_21, bank=3, volume=70, priority=101, player=4, w8=0xFF, name=sname_0466, id=502
song_0467:
	song_entry mid_0467_s_BOMB_OK_22, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0467, id=503
song_0468:
	song_entry mid_0468_s_BOMB_OK_23, bank=1, volume=50, priority=100, player=0, w8=0xFF, name=sname_0468, id=504
song_0469:
	song_entry mid_0469_s_BOMB_OK_24, bank=3, volume=110, priority=100, player=4, w8=0xFF, name=sname_0469, id=505
song_0470:
	song_entry mid_0470_s_BOMB_OK_25, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0470, id=506
song_0471:
	song_entry mid_0471_s_BOMB_OK_26, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0471, id=507
song_0472:
	song_entry mid_0472_s_BOMB_OK_27, bank=3, volume=85, priority=100, player=4, w8=0xFF, name=sname_0472, id=508
song_0473:
	song_entry mid_0473_s_BOMB_OK_28, bank=3, volume=110, priority=100, player=4, w8=0xFF, name=sname_0473, id=509
song_0474:
	song_entry mid_0474_s_BOMB_OK_29, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0474, id=510
song_0475:
	song_entry mid_0475_s_BOMB_OK_30, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0475, id=511
song_0476:
	song_entry mid_0476_s_BOMB_OK_31, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0476, id=512
song_0477:
	song_entry mid_0477_s_BOMB_OK_32, bank=3, volume=110, priority=101, player=4, w8=0xFF, name=sname_0477, id=513
song_0478:
	song_entry mid_0478_s_BOMB_OK_33, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0478, id=514
song_0479:
	song_entry mid_0479_s_BOMB_OK_34, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0479, id=515
song_0480:
	song_entry mid_0480_s_BOMB_OK_35, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0480, id=516
song_0481:
	song_entry mid_0481_s_BOMB_OK_36, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0481, id=517
song_0482:
	song_entry mid_0482_s_BOMB_OK_37, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0482, id=518
song_0483:
	song_entry mid_0483_s_BOMB_OK_38, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0483, id=519
song_0484:
	song_entry mid_0484_s_BOMB_OK_39, bank=3, volume=100, priority=101, player=5, w8=0xFF, name=sname_0484, id=520
song_0485:
	song_entry mid_0485_s_BOMB_OK_40, bank=3, volume=100, priority=101, player=4, w8=0xFF, name=sname_0485, id=521
song_0486:
	song_entry mid_0486_s_BOMB_OK_41, bank=3, volume=100, priority=101, player=4, w8=0xFF, name=sname_0486, id=522
song_0487:
	song_entry mid_0487_s_BOMB_OK_42, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0487, id=523
song_0488:
	song_entry mid_0488_s_BOMB_OK_43, bank=1, volume=110, priority=100, player=4, w8=0xFF, name=sname_0488, id=524
song_0489:
	song_entry mid_0489_s_BOMB_OK_44, bank=3, volume=110, priority=100, player=4, w8=0xFF, name=sname_0489, id=525
song_0490:
	song_entry mid_0490_s_BOMB_OK_45, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0490, id=526
song_0491:
	song_entry mid_0491_s_BOMB_OK_46, bank=3, volume=120, priority=100, player=4, w8=0xFF, name=sname_0491, id=527
song_0492:
	song_entry mid_0492_s_BOMB_Fail_01, bank=3, volume=100, priority=101, player=4, w8=0xFF, name=sname_0492, id=531
song_0493:
	song_entry mid_0493_s_BOMB_Fail_02, bank=1, volume=70, priority=100, player=4, w8=0xFF, name=sname_0493, id=532
song_0494:
	song_entry mid_0494_s_BOMB_Fail_03, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0494, id=533
song_0495:
	song_entry mid_0495_s_BOMB_Fail_04, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0495, id=534
song_0496:
	song_entry mid_0496_s_BOMB_Fail_05, bank=3, volume=60, priority=100, player=5, w8=0xFF, name=sname_0496, id=535
song_0497:
	song_entry mid_0497_s_BOMB_Fail_06, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0497, id=536
song_0498:
	song_entry mid_0498_s_BOMB_Fail_07, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0498, id=537
song_0499:
	song_entry mid_0499_s_BOMB_Fail_08, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0499, id=538
song_0500:
	song_entry mid_0500_s_BOMB_Fail_09, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0500, id=539
song_0501:
	song_entry mid_0501_s_BOMB_Fail_10, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0501, id=540
song_0502:
	song_entry mid_0502_s_BOMB_Fail_11, bank=1, volume=75, priority=100, player=4, w8=0xFF, name=sname_0502, id=541
song_0503:
	song_entry mid_0503_s_BOMB_Fail_12, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0503, id=542
song_0504:
	song_entry mid_0504_s_BOMB_Fail_13, bank=3, volume=100, priority=102, player=4, w8=0xFF, name=sname_0504, id=543
song_0505:
	song_entry mid_0505_s_BOMB_Fail_14, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0505, id=544
song_0506:
	song_entry mid_0506_s_BOMB_Fail_15, bank=3, volume=120, priority=100, player=4, w8=0xFF, name=sname_0506, id=545
song_0507:
	song_entry mid_0507_s_BOMB_Fail_16, bank=3, volume=65, priority=100, player=4, w8=0xFF, name=sname_0507, id=546
song_0508:
	song_entry mid_0508_s_BOMB_Fail_17, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0508, id=547
song_0509:
	song_entry mid_0509_s_BOMB_Fail_18, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0509, id=548
song_0510:
	song_entry mid_0510_s_BOMB_Fail_19_AIR, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0510, id=549
song_0511:
	song_entry mid_0511_s_BOMB_Fail_20, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0511, id=550
song_0512:
	song_entry mid_0512_s_BOMB_Fail_21, bank=3, volume=60, priority=100, player=0, w8=0xFF, name=sname_0512, id=551
song_0513:
	song_entry mid_0513_s_BOMB_Fail_22, bank=3, volume=70, priority=100, player=4, w8=0xFF, name=sname_0513, id=552
song_0514:
	song_entry mid_0514_s_BOMB_Fail_23, bank=3, volume=90, priority=100, player=4, w8=0xFF, name=sname_0514, id=553
song_0515:
	song_entry mid_0515_s_BOMB_Fail_24, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0515, id=554
song_0516:
	song_entry mid_0516_s_BOMB_Fail_25, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0516, id=555
song_0517:
	song_entry mid_0517_s_BOMB_Fail_26, bank=3, volume=110, priority=100, player=4, w8=0xFF, name=sname_0517, id=556
song_0518:
	song_entry mid_0518_s_BOMB_Fail_27, bank=1, volume=110, priority=100, player=4, w8=0xFF, name=sname_0518, id=557
song_0519:
	song_entry mid_0519_s_BOMB_Fail_28, bank=1, volume=70, priority=100, player=6, w8=0xFF, name=sname_0519, id=558
song_0520:
	song_entry mid_0520_s_BOMB_Fail_29, bank=1, volume=80, priority=101, player=5, w8=0xFF, name=sname_0520, id=559
song_0521:
	song_entry mid_0521_s_BOMB_Fail_30, bank=3, volume=40, priority=101, player=0, w8=0xFF, name=sname_0521, id=560
song_0522:
	song_entry mid_0522_s_BOMB_Fail_31, bank=3, volume=110, priority=101, player=0, w8=0xFF, name=sname_0522, id=561
song_0523:
	song_entry mid_0523_s_BOMB_Fail_32, bank=3, volume=40, priority=101, player=0, w8=0xFF, name=sname_0523, id=562
song_0524:
	song_entry mid_0524_s_BOMB_Fail_34, bank=3, volume=80, priority=101, player=0, w8=0xFF, name=sname_0524, id=564
song_0525:
	song_entry mid_0525_s_BOMB_Fail_35, bank=1, volume=100, priority=101, player=0, w8=0xFF, name=sname_0525, id=565
song_0526:
	song_entry mid_0526_s_BOMB_Fail_36, bank=3, volume=50, priority=101, player=0, w8=0xFF, name=sname_0526, id=566
song_0527:
	song_entry mid_0527_s_BOMB_Fail_37, bank=3, volume=85, priority=101, player=0, w8=0xFF, name=sname_0527, id=567
song_0528:
	song_entry mid_0528_s_BOMB_Fail_38, bank=3, volume=60, priority=101, player=4, w8=0xFF, name=sname_0528, id=568
song_0529:
	song_entry mid_0529_s_BOMB_Fail_39, bank=3, volume=70, priority=101, player=0, w8=0xFF, name=sname_0529, id=569
song_0530:
	song_entry mid_0530_s_BOMB_Fail_40, bank=3, volume=60, priority=101, player=4, w8=0xFF, name=sname_0530, id=570
song_0531:
	song_entry mid_0531_s_BOMB_Fail_41, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0531, id=571
song_0532:
	song_entry mid_0532_s_BOMB_Fail_42, bank=3, volume=70, priority=101, player=5, w8=0xFF, name=sname_0532, id=572
song_0533:
	song_entry mid_0533_s_BOMB_Fail_43, bank=3, volume=70, priority=101, player=4, w8=0xFF, name=sname_0533, id=573
song_0534:
	song_entry mid_0534_s_BOMB_Fail_44, bank=3, volume=60, priority=101, player=4, w8=0xFF, name=sname_0534, id=574
song_0535:
	song_entry mid_0535_s_BOMB_Fail_45, bank=3, volume=70, priority=101, player=0, w8=0xFF, name=sname_0535, id=575
song_0536:
	song_entry mid_0536_s_BOMB_Fail_46, bank=3, volume=80, priority=100, player=0, w8=0xFF, name=sname_0536, id=576
song_0537:
	song_entry mid_0537_s_BOMB_Fail_47, bank=3, volume=90, priority=100, player=0, w8=0xFF, name=sname_0537, id=577
song_0538:
	song_entry mid_0538_s_BOMB_Fail_48, bank=3, volume=80, priority=100, player=2, w8=0xFF, name=sname_0538, id=578
song_0539:
	song_entry mid_0539_s_BOMB_Shot_01, bank=1, volume=90, priority=100, player=5, w8=0xFF, name=sname_0539, id=586
song_0540:
	song_entry mid_0540_s_BOMB_Shot_02, bank=3, volume=40, priority=100, player=5, w8=0xFF, name=sname_0540, id=587
song_0541:
	song_entry mid_0541_s_BOMB_Shot_03, bank=1, volume=100, priority=100, player=5, w8=0xFF, name=sname_0541, id=588
song_0542:
	song_entry mid_0542_s_BOMB_Shot_04, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_0542, id=589
song_0543:
	song_entry mid_0543_s_BOMB_Shot_05, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_0543, id=590
song_0544:
	song_entry mid_0544_s_BOMB_Shot_06, bank=1, volume=40, priority=90, player=5, w8=0xFF, name=sname_0544, id=591
song_0545:
	song_entry mid_0545_s_BOMB_Shot_07, bank=3, volume=100, priority=101, player=5, w8=0xFF, name=sname_0545, id=592
song_0546:
	song_entry mid_0546_s_BOMB_Shot_08, bank=1, volume=90, priority=101, player=5, w8=0xFF, name=sname_0546, id=593
song_0547:
	song_entry mid_0547_s_BOMB_Shot_09, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_0547, id=594
song_0548:
	song_entry mid_0548_s_BOMB_Shot_10, bank=1, volume=70, priority=90, player=6, w8=0xFF, name=sname_0548, id=595
song_0549:
	song_entry mid_0549_s_BOMB_Shot_11, bank=3, volume=110, priority=90, player=6, w8=0xFF, name=sname_0549, id=596
song_0550:
	song_entry mid_0550_s_BOMB_Shot_12, bank=1, volume=70, priority=95, player=6, w8=0xFF, name=sname_0550, id=597
song_0551:
	song_entry mid_0551_s_BOMB_Shot_13, bank=1, volume=20, priority=90, player=5, w8=0xFF, name=sname_0551, id=598
song_0552:
	song_entry mid_0552_s_BOMB_Shot_14, bank=3, volume=80, priority=101, player=0, w8=0xFF, name=sname_0552, id=599
song_0553:
	song_entry mid_0553_s_BOMB_Shot_15, bank=1, volume=110, priority=80, player=6, w8=0xFF, name=sname_0553, id=600
song_0554:
	song_entry mid_0554_s_BOMB_Shot_16, bank=1, volume=20, priority=90, player=5, w8=0xFF, name=sname_0554, id=601
song_0555:
	song_entry mid_0555_s_BOMB_Bomb_01, bank=3, volume=50, priority=100, player=4, w8=0xFF, name=sname_0555, id=611
song_0556:
	song_entry mid_0556_s_BOMB_Bomb_02, bank=1, volume=60, priority=101, player=4, w8=0xFF, name=sname_0556, id=612
song_0557:
	song_entry mid_0557_s_BOMB_Bomb_03, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0557, id=613
song_0558:
	song_entry mid_0558_s_BOMB_Bomb_04, bank=1, volume=100, priority=90, player=6, w8=0xFF, name=sname_0558, id=614
song_0559:
	song_entry mid_0559_s_BOMB_Bomb_05, bank=1, volume=110, priority=100, player=3, w8=0xFF, name=sname_0559, id=615
song_0560:
	song_entry mid_0560_s_BOMB_Bomb_06, bank=1, volume=50, priority=90, player=4, w8=0xFF, name=sname_0560, id=616
song_0561:
	song_entry mid_0561_s_BOMB_Bomb_07, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0561, id=617
song_0562:
	song_entry mid_0562_s_BOMB_Bomb_08, bank=3, volume=80, priority=101, player=6, w8=0xFF, name=sname_0562, id=618
song_0563:
	song_entry mid_0563_s_BOMB_Bomb_09, bank=3, volume=70, priority=100, player=5, w8=0xFF, name=sname_0563, id=619
song_0564:
	song_entry mid_0564_s_BOMB_Bomb_10, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0564, id=620
song_0565:
	song_entry mid_0565_s_BOMB_Bomb_11, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_0565, id=621
song_0566:
	song_entry mid_0566_s_BOMB_Bomb_12, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0566, id=622
song_0567:
	song_entry mid_0567_s_BOMB_Bomb_13, bank=3, volume=30, priority=90, player=5, w8=0xFF, name=sname_0567, id=623
song_0568:
	song_entry mid_0568_s_BOMB_Bomb_14, bank=3, volume=110, priority=80, player=4, w8=0xFF, name=sname_0568, id=624
song_0569:
	song_entry mid_0569_s_BOMB_Bomb_15, bank=3, volume=120, priority=100, player=4, w8=0xFF, name=sname_0569, id=625
song_0570:
	song_entry mid_0570_s_BOMB_FIRE_01, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0570, id=630
song_0571:
	song_entry mid_0571_s_BOMB_FIRE_02, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0571, id=631
song_0572:
	song_entry mid_0572_s_BOMB_JUMP_01, bank=1, volume=50, priority=100, player=5, w8=0xFF, name=sname_0572, id=635
song_0573:
	song_entry mid_0573_s_BOMB_JUMP_02, bank=1, volume=60, priority=100, player=5, w8=0xFF, name=sname_0573, id=636
song_0574:
	song_entry mid_0574_s_BOMB_JUMP_03_1, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0574, id=637
song_0575:
	song_entry mid_0575_s_BOMB_JUMP_03_2, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0575, id=638
song_0576:
	song_entry mid_0576_s_BOMB_JUMP_03_3, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0576, id=639
song_0577:
	song_entry mid_0577_s_BOMB_JUMP_04, bank=1, volume=90, priority=90, player=5, w8=0xFF, name=sname_0577, id=640
song_0578:
	song_entry mid_0578_s_BOMB_JUMP_05, bank=3, volume=85, priority=90, player=4, w8=0xFF, name=sname_0578, id=641
song_0579:
	song_entry mid_0579_s_BOMB_JUMP_06, bank=1, volume=100, priority=90, player=4, w8=0xFF, name=sname_0579, id=642
song_0580:
	song_entry mid_0580_s_BOMB_JUMP_07, bank=3, volume=40, priority=90, player=4, w8=0xFF, name=sname_0580, id=643
song_0581:
	song_entry mid_0581_s_BOMB_JUMP_08, bank=3, volume=30, priority=90, player=4, w8=0xFF, name=sname_0581, id=644
song_0582:
	song_entry mid_0582_s_BOMB_JUMP_09, bank=3, volume=75, priority=80, player=4, w8=0xFF, name=sname_0582, id=645
song_0583:
	song_entry mid_0583_s_BOMB_JUMP_10, bank=3, volume=70, priority=100, player=4, w8=0xFF, name=sname_0583, id=646
song_0584:
	song_entry mid_0584_s_BOMB_JUMP_11, bank=3, volume=70, priority=100, player=4, w8=0xFF, name=sname_0584, id=647
song_0585:
	song_entry mid_0585_s_BOMB_JUMP_12, bank=3, volume=40, priority=80, player=4, w8=0xFF, name=sname_0585, id=648
song_0586:
	song_entry mid_0586_s_BOMB_JUMP_13, bank=3, volume=25, priority=90, player=5, w8=0xFF, name=sname_0586, id=649
song_0587:
	song_entry mid_0587_s_BOMB_FALL_01, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0587, id=651
song_0588:
	song_entry mid_0588_s_BOMB_FALL_02, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0588, id=652
song_0589:
	song_entry mid_0589_s_BOMB_FALL_03, bank=3, volume=90, priority=50, player=4, w8=0xFF, name=sname_0589, id=653
song_0590:
	song_entry mid_0590_s_BOMB_FALL_04, bank=3, volume=60, priority=50, player=5, w8=0xFF, name=sname_0590, id=654
song_0591:
	song_entry mid_0591_s_BOMB_FALL_05, bank=3, volume=30, priority=50, player=4, w8=0xFF, name=sname_0591, id=655
song_0592:
	song_entry mid_0592_s_BOMB_FALL_06, bank=3, volume=60, priority=80, player=4, w8=0xFF, name=sname_0592, id=656
song_0593:
	song_entry mid_0593_s_BOMB_FALL_07, bank=3, volume=20, priority=80, player=4, w8=0xFF, name=sname_0593, id=657
song_0594:
	song_entry mid_0594_s_BOMB_FALL_08, bank=3, volume=40, priority=80, player=6, w8=0xFF, name=sname_0594, id=658
song_0595:
	song_entry mid_0595_s_BOMB_FALL_09, bank=3, volume=40, priority=80, player=6, w8=0xFF, name=sname_0595, id=659
song_0596:
	song_entry mid_0596_s_BOMB_Catch_OK_01, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0596, id=660
song_0597:
	song_entry mid_0597_s_BOMB_Catch_OK_02, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0597, id=661
song_0598:
	song_entry mid_0598_s_BOMB_Catch_OK_03, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0598, id=662
song_0599:
	song_entry mid_0599_s_BOMB_Catch_OK_04, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0599, id=663
song_0600:
	song_entry mid_0600_s_BOMB_Catch_OK_041, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_0600, id=664
song_0601:
	song_entry mid_0601_s_BOMB_Catch_OK_05, bank=1, volume=110, priority=100, player=4, w8=0xFF, name=sname_0601, id=665
song_0602:
	song_entry mid_0602_s_BOMB_Catch_OK_06, bank=1, volume=110, priority=100, player=0, w8=0xFF, name=sname_0602, id=666
song_0603:
	song_entry mid_0603_s_BOMB_Catch_BAD_01, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0603, id=670
song_0604:
	song_entry mid_0604_s_BOMB_Catch_BAD_02, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0604, id=671
song_0605:
	song_entry mid_0605_s_BOMB_PI_01, bank=3, volume=30, priority=100, player=6, w8=0xFF, name=sname_0605, id=675
song_0606:
	song_entry mid_0606_s_BOMB_PI_02, bank=3, volume=50, priority=100, player=4, w8=0xFF, name=sname_0606, id=676
song_0607:
	song_entry mid_0607_s_BOMB_PI_03, bank=3, volume=40, priority=100, player=4, w8=0xFF, name=sname_0607, id=677
song_0608:
	song_entry mid_0608_s_BOMB_PI_04_E2, bank=1, volume=60, priority=90, player=5, w8=0xFF, name=sname_0608, id=678
song_0609:
	song_entry mid_0609_s_BOMB_PI_05_G2, bank=1, volume=50, priority=90, player=4, w8=0xFF, name=sname_0609, id=679
song_0610:
	song_entry mid_0610_s_BOMB_PI_06_A2, bank=1, volume=50, priority=90, player=6, w8=0xFF, name=sname_0610, id=680
song_0611:
	song_entry mid_0611_s_BOMB_PI_07_C3, bank=1, volume=50, priority=90, player=5, w8=0xFF, name=sname_0611, id=681
song_0612:
	song_entry mid_0612_s_BOMB_PI_08_E3, bank=1, volume=40, priority=90, player=6, w8=0xFF, name=sname_0612, id=682
song_0613:
	song_entry mid_0613_s_BOMB_PI_09, bank=1, volume=70, priority=95, player=4, w8=0xFF, name=sname_0613, id=683
song_0614:
	song_entry mid_0614_s_BOMB_PI_10_1, bank=1, volume=50, priority=90, player=5, w8=0xFF, name=sname_0614, id=684
song_0615:
	song_entry mid_0615_s_BOMB_PI_10_2, bank=1, volume=60, priority=90, player=5, w8=0xFF, name=sname_0615, id=685
song_0616:
	song_entry mid_0616_s_BOMB_PI_10_3, bank=1, volume=80, priority=90, player=5, w8=0xFF, name=sname_0616, id=686
song_0617:
	song_entry mid_0617_s_BOMB_PI_10_4, bank=1, volume=100, priority=90, player=5, w8=0xFF, name=sname_0617, id=687
song_0618:
	song_entry mid_0618_s_BOMB_PI_11, bank=1, volume=50, priority=90, player=5, w8=0xFF, name=sname_0618, id=688
song_0619:
	song_entry mid_0619_s_BOMB_PI_12, bank=1, volume=50, priority=90, player=5, w8=0xFF, name=sname_0619, id=689
song_0620:
	song_entry mid_0620_s_BOMB_PI_13, bank=1, volume=20, priority=80, player=5, w8=0xFF, name=sname_0620, id=690
song_0621:
	song_entry mid_0621_s_BOMB_PI_14, bank=1, volume=40, priority=90, player=6, w8=0xFF, name=sname_0621, id=691
song_0622:
	song_entry mid_0622_s_BOMB_PI_15, bank=3, volume=30, priority=100, player=6, w8=0xFF, name=sname_0622, id=692
song_0623:
	song_entry mid_0623_s_BOMB_PI_16, bank=3, volume=50, priority=80, player=6, w8=0xFF, name=sname_0623, id=693
song_0624:
	song_entry mid_0624_s_BOMB_PI_17, bank=3, volume=90, priority=80, player=5, w8=0xFF, name=sname_0624, id=694
song_0625:
	song_entry mid_0625_s_BOMB_PI_18, bank=3, volume=70, priority=80, player=4, w8=0xFF, name=sname_0625, id=695
song_0626:
	song_entry mid_0626_s_BOMB_PI_19, bank=3, volume=90, priority=80, player=4, w8=0xFF, name=sname_0626, id=696
song_0627:
	song_entry mid_0627_s_BOMB_PI_20, bank=3, volume=90, priority=95, player=5, w8=0xFF, name=sname_0627, id=697
song_0628:
	song_entry mid_0628_s_BOMB_PI_21, bank=1, volume=20, priority=80, player=3, w8=0xFF, name=sname_0628, id=698
song_0629:
	song_entry mid_0629_s_BOMB_Landing_01, bank=3, volume=50, priority=100, player=6, w8=0xFF, name=sname_0629, id=700
song_0630:
	song_entry mid_0630_s_BOMB_Landing_02_OK, bank=3, volume=90, priority=100, player=5, w8=0xFF, name=sname_0630, id=701
song_0631:
	song_entry mid_0631_s_BOMB_Landing_02_NG, bank=1, volume=100, priority=100, player=5, w8=0xFF, name=sname_0631, id=702
song_0632:
	song_entry mid_0632_s_BOMB_Landing_03, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_0632, id=703
song_0633:
	song_entry mid_0633_s_BOMB_Landing_03_OK, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0633, id=704
song_0634:
	song_entry mid_0634_s_BOMB_Landing_04, bank=3, volume=55, priority=80, player=5, w8=0xFF, name=sname_0634, id=705
song_0635:
	song_entry mid_0635_s_BOMB_Curve_01, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0635, id=710
song_0636:
	song_entry mid_0636_s_BOMB_Sweep_01, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_0636, id=715
song_0637:
	song_entry mid_0637_s_BOMB_Sweep_02, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0637, id=716
song_0638:
	song_entry mid_0638_s_BOMB_Sweep_03, bank=3, volume=40, priority=80, player=5, w8=0xFF, name=sname_0638, id=717
song_0639:
	song_entry mid_0639_s_BOMB_Sweep_04, bank=3, volume=30, priority=90, player=6, w8=0xFF, name=sname_0639, id=718
song_0640:
	song_entry mid_0640_s_BOMB_PO_01, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_0640, id=720
song_0641:
	song_entry mid_0641_s_BOMB_KALI_01, bank=3, volume=40, priority=100, player=6, w8=0xFF, name=sname_0641, id=721
song_0642:
	song_entry mid_0642_s_BOMB_KALI_02, bank=3, volume=110, priority=101, player=6, w8=0xFF, name=sname_0642, id=722
song_0643:
	song_entry mid_0643_s_BOMB_KALI_03, bank=3, volume=80, priority=90, player=3, w8=0xFF, name=sname_0643, id=723
song_0644:
	song_entry mid_0644_s_BOMB_KALI_04, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0644, id=724
song_0645:
	song_entry mid_0645_s_BOMB_KALI_05, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0645, id=725
song_0646:
	song_entry mid_0646_s_BOMB_KALI_06, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0646, id=726
song_0647:
	song_entry mid_0647_s_BOMB_KALI_07, bank=3, volume=90, priority=90, player=5, w8=0xFF, name=sname_0647, id=727
song_0648:
	song_entry mid_0648_s_BOMB_Bound_01, bank=1, volume=50, priority=90, player=5, w8=0xFF, name=sname_0648, id=730
song_0649:
	song_entry mid_0649_s_BOMB_Bound_02, bank=1, volume=30, priority=90, player=5, w8=0xFF, name=sname_0649, id=731
song_0650:
	song_entry mid_0650_s_BOMB_Bound_03, bank=1, volume=80, priority=90, player=6, w8=0xFF, name=sname_0650, id=732
song_0651:
	song_entry mid_0651_s_BOMB_Bound_04, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0651, id=733
song_0652:
	song_entry mid_0652_s_BOMB_Bound_05, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0652, id=734
song_0653:
	song_entry mid_0653_s_BOMB_Bound_06, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0653, id=735
song_0654:
	song_entry mid_0654_s_BOMB_Bound_07, bank=1, volume=80, priority=90, player=0, w8=0xFF, name=sname_0654, id=736
song_0655:
	song_entry mid_0655_s_BOMB_Bound_08, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0655, id=737
song_0656:
	song_entry mid_0656_s_BOMB_Push_01, bank=3, volume=40, priority=90, player=5, w8=0xFF, name=sname_0656, id=738
song_0657:
	song_entry mid_0657_s_BOMB_Push_02, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0657, id=739
song_0658:
	song_entry mid_0658_s_BOMB_SMASH_02, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0658, id=741
song_0659:
	song_entry mid_0659_s_BOMB_SMASH_03, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_0659, id=742
song_0660:
	song_entry mid_0660_s_BOMB_SMASH_04, bank=3, volume=100, priority=102, player=4, w8=0xFF, name=sname_0660, id=743
song_0661:
	song_entry mid_0661_s_BOMB_Throw_01, bank=1, volume=70, priority=101, player=5, w8=0xFF, name=sname_0661, id=746
song_0662:
	song_entry mid_0662_s_BOMB_Throw_02, bank=3, volume=40, priority=100, player=5, w8=0xFF, name=sname_0662, id=747
song_0663:
	song_entry mid_0663_s_BOMB_Throw_03, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0663, id=748
song_0664:
	song_entry mid_0664_s_BOMB_Throw_04, bank=3, volume=80, priority=95, player=4, w8=0xFF, name=sname_0664, id=749
song_0665:
	song_entry mid_0665_s_BOMB_Throw_05, bank=3, volume=80, priority=95, player=6, w8=0xFF, name=sname_0665, id=750
song_0666:
	song_entry mid_0666_s_BOMB_v_Haa_01, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0666, id=751
song_0667:
	song_entry mid_0667_s_BOMB_OUT_01, bank=3, volume=80, priority=101, player=6, w8=0xFF, name=sname_0667, id=752
song_0668:
	song_entry mid_0668_s_BOMB_v_Ahh_01, bank=3, volume=70, priority=100, player=5, w8=0xFF, name=sname_0668, id=753
song_0669:
	song_entry mid_0669_s_BOMB_BUTTON_01, bank=1, volume=60, priority=80, player=6, w8=0xFF, name=sname_0669, id=754
song_0670:
	song_entry mid_0670_s_BOMB_BUTTON_02, bank=1, volume=80, priority=50, player=5, w8=0xFF, name=sname_0670, id=755
song_0671:
	song_entry mid_0671_s_BOMB_Combine_01, bank=1, volume=90, priority=100, player=3, w8=0xFF, name=sname_0671, id=756
song_0672:
	song_entry mid_0672_s_BOMB_Combine_02, bank=1, volume=90, priority=100, player=5, w8=0xFF, name=sname_0672, id=757
song_0673:
	song_entry mid_0673_s_BOMB_Bowling_Throw_01, bank=3, volume=70, priority=100, player=5, w8=0xFF, name=sname_0673, id=758
song_0674:
	song_entry mid_0674_s_BOMB_Bowling_Gater, bank=1, volume=80, priority=100, player=6, w8=0xFF, name=sname_0674, id=759
song_0675:
	song_entry mid_0675_s_BOMB_Bowling_HIT_01, bank=1, volume=90, priority=100, player=5, w8=0xFF, name=sname_0675, id=760
song_0676:
	song_entry mid_0676_s_BOMB_Bowling_HIT_ALL, bank=1, volume=100, priority=101, player=5, w8=0xFF, name=sname_0676, id=761
song_0677:
	song_entry mid_0677_s_BOMB_WAVE_01, bank=1, volume=60, priority=100, player=5, w8=0xFF, name=sname_0677, id=762
song_0678:
	song_entry mid_0678_s_BOMB_WAVE_02, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_0678, id=763
song_0679:
	song_entry mid_0679_s_BOMB_SAW_01, bank=1, volume=70, priority=100, player=5, w8=0xFF, name=sname_0679, id=764
song_0680:
	song_entry mid_0680_s_BOMB_SAW_02, bank=1, volume=90, priority=100, player=5, w8=0xFF, name=sname_0680, id=765
song_0681:
	song_entry mid_0681_s_BOMB_Water_01, bank=3, volume=80, priority=100, player=6, w8=0xFF, name=sname_0681, id=766
song_0682:
	song_entry mid_0682_s_BOMB_Water_02, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0682, id=767
song_0683:
	song_entry mid_0683_s_BOMB_Water_03, bank=3, volume=80, priority=90, player=6, w8=0xFF, name=sname_0683, id=768
song_0684:
	song_entry mid_0684_s_BOMB_Count_01, bank=3, volume=20, priority=90, player=4, w8=0xFF, name=sname_0684, id=769
song_0685:
	song_entry mid_0685_s_BOMB_PAD_01, bank=3, volume=60, priority=90, player=4, w8=0xFF, name=sname_0685, id=770
song_0686:
	song_entry mid_0686_s_BOMB_Archery_Shot_01, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0686, id=771
song_0687:
	song_entry mid_0687_s_BOMB_Uproot_01, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_0687, id=772
song_0688:
	song_entry mid_0688_s_BOMB_Revolve_01, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_0688, id=773
song_0689:
	song_entry mid_0689_s_BOMB_Brush_01, bank=1, volume=40, priority=90, player=6, w8=0xFF, name=sname_0689, id=774
song_0690:
	song_entry mid_0690_s_BOMB_Flower_Water_01, bank=3, volume=60, priority=100, player=5, w8=0xFF, name=sname_0690, id=775
song_0691:
	song_entry mid_0691_s_BOMB_Please_01, bank=1, volume=90, priority=100, player=5, w8=0xFF, name=sname_0691, id=776
song_0692:
	song_entry mid_0692_s_BOMB_CAMERA_Shutter_01, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0692, id=777
song_0693:
	song_entry mid_0693_s_BOMB_CAMERA_PRINT_01, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0693, id=778
song_0694:
	song_entry mid_0694_s_BOMB_CAMERA_PRINT_02, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0694, id=779
song_0695:
	song_entry mid_0695_s_BOMB_Jet_01, bank=1, volume=45, priority=90, player=4, w8=0xFF, name=sname_0695, id=780
song_0696:
	song_entry mid_0696_s_BOMB_Pour_01, bank=3, volume=80, priority=100, player=5, w8=0xFF, name=sname_0696, id=781
song_0697:
	song_entry mid_0697_s_BOMB_Turn_01, bank=1, volume=40, priority=100, player=5, w8=0xFF, name=sname_0697, id=782
song_0698:
	song_entry mid_0698_s_BOMB_START_01, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0698, id=783
song_0699:
	song_entry mid_0699_s_BOMB_Suck_Body, bank=1, volume=50, priority=100, player=6, w8=0xFF, name=sname_0699, id=784
song_0700:
	song_entry mid_0700_s_BOMB_Page_Turn, bank=1, volume=20, priority=90, player=5, w8=0xFF, name=sname_0700, id=785
song_0701:
	song_entry mid_0701_s_BOMB_Page_MARK, bank=1, volume=70, priority=100, player=6, w8=0xFF, name=sname_0701, id=786
song_0702:
	song_entry mid_0702_s_BOMB_Trampoline_JUMP_2, bank=1, volume=70, priority=110, player=5, w8=0xFF, name=sname_0702, id=787
song_0703:
	song_entry mid_0703_s_BOMB_Trampoline_JUMP_3, bank=3, volume=70, priority=100, player=5, w8=0xFF, name=sname_0703, id=788
song_0704:
	song_entry mid_0704_s_BOMB_CURSOR_01, bank=1, volume=40, priority=80, player=6, w8=0xFF, name=sname_0704, id=789
song_0705:
	song_entry mid_0705_s_BOMB_Fly_01, bank=1, volume=80, priority=80, player=5, w8=0xFF, name=sname_0705, id=790
song_0706:
	song_entry mid_0706_s_BOMB_BIG_01, bank=1, volume=90, priority=90, player=5, w8=0xFF, name=sname_0706, id=791
song_0707:
	song_entry mid_0707_s_BOMB_Rotate_01, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_0707, id=792
song_0708:
	song_entry mid_0708_s_BOMB_AIR_ON, bank=1, volume=120, priority=100, player=5, w8=0xFF, name=sname_0708, id=794
song_0709:
	song_entry mid_0709_s_BOMB_AIR_OFF, bank=1, volume=90, priority=101, player=5, w8=0xFF, name=sname_0709, id=795
song_0710:
	song_entry mid_0710_s_BOMB_CAR_01, bank=1, volume=70, priority=100, player=5, w8=0xFF, name=sname_0710, id=796
song_0711:
	song_entry mid_0711_s_BOMB_CAR_02, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0711, id=797
song_0712:
	song_entry mid_0712_s_BOMB_CAR_03, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_0712, id=798
song_0713:
	song_entry mid_0713_s_BOMB_CAR_04, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_0713, id=799
song_0714:
	song_entry mid_0714_s_BOMB_CAR_05, bank=3, volume=110, priority=90, player=5, w8=0xFF, name=sname_0714, id=800
song_0715:
	song_entry mid_0715_s_BOMB_CAR_06, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0715, id=801
song_0716:
	song_entry mid_0716_s_BOMB_CAR_07, bank=3, volume=100, priority=90, player=6, w8=0xFF, name=sname_0716, id=802
song_0717:
	song_entry mid_0717_s_BOMB_CAR_08, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0717, id=803
song_0718:
	song_entry mid_0718_s_BOMB_CAR_Back_01, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0718, id=804
song_0719:
	song_entry mid_0719_s_BOMB_CAR_Bend, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0719, id=805
song_0720:
	song_entry mid_0720_s_BOMB_CAR_Back_NG_01, bank=3, volume=90, priority=110, player=4, w8=0xFF, name=sname_0720, id=806
song_0721:
	song_entry mid_0721_s_BOMB_CAR_Crash_01, bank=3, volume=100, priority=110, player=5, w8=0xFF, name=sname_0721, id=807
song_0722:
	song_entry mid_0722_s_BOMB_WARP_01, bank=1, volume=80, priority=100, player=4, w8=0xFF, name=sname_0722, id=808
song_0723:
	song_entry mid_0723_s_BOMB_v_CHYOKI, bank=3, volume=55, priority=100, player=5, w8=0xFF, name=sname_0723, id=809
song_0724:
	song_entry mid_0724_s_BOMB_Change_01, bank=1, volume=50, priority=100, player=5, w8=0xFF, name=sname_0724, id=810
song_0725:
	song_entry mid_0725_s_BOMB_GOLF_CupIn_01, bank=1, volume=90, priority=100, player=4, w8=0xFF, name=sname_0725, id=811
song_0726:
	song_entry mid_0726_s_wario_JUMP_1, bank=1, volume=60, priority=21, player=5, w8=0xFF, name=sname_0726, id=812
song_0727:
	song_entry mid_0727_s_wario_DIE, bank=1, volume=90, priority=110, player=4, w8=0xFF, name=sname_0727, id=813
song_0728:
	song_entry mid_0728_s_BOMB_Nose_01, bank=3, volume=50, priority=100, player=0, w8=0xFF, name=sname_0728, id=814
song_0729:
	song_entry mid_0729_s_BOMB_Nose_02, bank=3, volume=60, priority=100, player=0, w8=0xFF, name=sname_0729, id=815
song_0730:
	song_entry mid_0730_s_BOMB_Nose_03, bank=3, volume=50, priority=100, player=0, w8=0xFF, name=sname_0730, id=816
song_0731:
	song_entry mid_0731_s_BOMB_Robot_UP, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0731, id=817
song_0732:
	song_entry mid_0732_s_BOMB_Robot_DOWN, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_0732, id=818
song_0733:
	song_entry mid_0733_s_BOMB_Robot_NIP, bank=3, volume=70, priority=100, player=4, w8=0xFF, name=sname_0733, id=819
song_0734:
	song_entry mid_0734_s_BOMB_Robot_OK, bank=3, volume=70, priority=101, player=4, w8=0xFF, name=sname_0734, id=820
song_0735:
	song_entry mid_0735_s_BOMB_Robot_NG, bank=3, volume=70, priority=101, player=4, w8=0xFF, name=sname_0735, id=821
song_0736:
	song_entry mid_0736_s_BOMB_NIP_01, bank=1, volume=90, priority=90, player=5, w8=0xFF, name=sname_0736, id=822
song_0737:
	song_entry mid_0737_s_BOMB_Whistle_01, bank=1, volume=60, priority=90, player=5, w8=0xFF, name=sname_0737, id=823
song_0738:
	song_entry mid_0738_s_BOMB_Dog_Bow_01, bank=1, volume=70, priority=90, player=5, w8=0xFF, name=sname_0738, id=824
song_0739:
	song_entry mid_0739_s_BOMB_Get_01, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0739, id=825
song_0740:
	song_entry mid_0740_s_BOMB_Get_02, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0740, id=826
song_0741:
	song_entry mid_0741_s_BOMB_FootStep_01, bank=3, volume=120, priority=90, player=4, w8=0xFF, name=sname_0741, id=827
song_0742:
	song_entry mid_0742_s_BOMB_FootStep_02, bank=3, volume=120, priority=100, player=4, w8=0xFF, name=sname_0742, id=828
song_0743:
	song_entry mid_0743_s_BOMB_FootStep_03, bank=3, volume=40, priority=90, player=4, w8=0xFF, name=sname_0743, id=829
song_0744:
	song_entry mid_0744_s_BOMB_FootStep_04, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_0744, id=830
song_0745:
	song_entry mid_0745_s_BOMB_Damage_01, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_0745, id=831
song_0746:
	song_entry mid_0746_s_BOMB_BUMP_01, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_0746, id=832
song_0747:
	song_entry mid_0747_s_BOMB_BUMP_02, bank=3, volume=90, priority=90, player=4, w8=0xFF, name=sname_0747, id=833
song_0748:
	song_entry mid_0748_s_BOMB_BUMP_03, bank=3, volume=70, priority=91, player=4, w8=0xFF, name=sname_0748, id=834
song_0749:
	song_entry mid_0749_s_BOMB_Filter_01, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_0749, id=835
song_0750:
	song_entry mid_0750_s_BOMB_wario_B_Attack, bank=1, volume=90, priority=90, player=4, w8=0xFF, name=sname_0750, id=837
song_0751:
	song_entry mid_0751_s_BOMB_wario_BLOCK_Break_1, bank=1, volume=100, priority=91, player=4, w8=0xFF, name=sname_0751, id=838
song_0752:
	song_entry mid_0752_s_BOMB_wario_Hip_Attack_S, bank=1, volume=80, priority=90, player=4, w8=0xFF, name=sname_0752, id=839
song_0753:
	song_entry mid_0753_s_BOMB_Lizard_Tongue, bank=1, volume=40, priority=100, player=5, w8=0xFF, name=sname_0753, id=840
song_0754:
	song_entry mid_0754_s_BOMB_STOP_01, bank=1, volume=60, priority=90, player=4, w8=0xFF, name=sname_0754, id=841
song_0755:
	song_entry mid_0755_s_BOMB_STOP_02_CAR, bank=1, volume=50, priority=101, player=6, w8=0xFF, name=sname_0755, id=842
song_0756:
	song_entry mid_0756_s_BOMB_Frog_HIT, bank=3, volume=80, priority=102, player=6, w8=0xFF, name=sname_0756, id=843
song_0757:
	song_entry mid_0757_s_BOMB_Frog_SWIM, bank=1, volume=60, priority=101, player=6, w8=0xFF, name=sname_0757, id=844
song_0758:
	song_entry mid_0758_s_BOMB_Mario_Step_ON_1, bank=3, volume=70, priority=101, player=6, w8=0xFF, name=sname_0758, id=845
song_0759:
	song_entry mid_0759_s_BOMB_Mario_Step_ON_2, bank=3, volume=50, priority=101, player=6, w8=0xFF, name=sname_0759, id=846
song_0760:
	song_entry mid_0760_s_BOMB_Mario_Step_ON_3, bank=3, volume=70, priority=101, player=6, w8=0xFF, name=sname_0760, id=847
song_0761:
	song_entry mid_0761_s_BOMB_Mario2_Step_ON_1, bank=3, volume=70, priority=101, player=6, w8=0xFF, name=sname_0761, id=848
song_0762:
	song_entry mid_0762_s_BOMB_Mario2_Step_ON_2, bank=3, volume=70, priority=101, player=6, w8=0xFF, name=sname_0762, id=849
song_0763:
	song_entry mid_0763_s_BOMB_Mario2_Step_ON_3, bank=3, volume=70, priority=101, player=6, w8=0xFF, name=sname_0763, id=850
song_0764:
	song_entry mid_0764_s_BOMB_Mario_Step_ON_END, bank=3, volume=100, priority=101, player=4, w8=0xFF, name=sname_0764, id=851
song_0765:
	song_entry mid_0765_s_BOMB_Mario_Step_ON_END2, bank=3, volume=90, priority=101, player=4, w8=0xFF, name=sname_0765, id=852
song_0766:
	song_entry mid_0766_s_BOMB_Tennis_Hit_0, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0766, id=853
song_0767:
	song_entry mid_0767_s_BOMB_Tennis_Hit_1, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0767, id=854
song_0768:
	song_entry mid_0768_s_BOMB_Tennis_Hit_2, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0768, id=855
song_0769:
	song_entry mid_0769_s_BOMB_Move_01, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0769, id=856
song_0770:
	song_entry mid_0770_s_BOMB_AIR_01, bank=1, volume=50, priority=100, player=6, w8=0xFF, name=sname_0770, id=857
song_0771:
	song_entry mid_0771_s_BOMB_AIR_02, bank=1, volume=60, priority=100, player=6, w8=0xFF, name=sname_0771, id=858
song_0772:
	song_entry mid_0772_s_BOMB_Ele_01, bank=1, volume=40, priority=100, player=3, w8=0xFF, name=sname_0772, id=859
song_0773:
	song_entry mid_0773_s_BOMB_Ele_02, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0773, id=860
song_0774:
	song_entry mid_0774_s_BOMB_Ele_03, bank=3, volume=100, priority=100, player=6, w8=0xFF, name=sname_0774, id=861
song_0775:
	song_entry mid_0775_s_BOMB_Ele_04, bank=3, volume=60, priority=100, player=6, w8=0xFF, name=sname_0775, id=862
song_0776:
	song_entry mid_0776_s_BOMB_Ele_05, bank=3, volume=70, priority=100, player=6, w8=0xFF, name=sname_0776, id=863
song_0777:
	song_entry mid_0777_s_BOMB_Ele_06, bank=3, volume=70, priority=100, player=6, w8=0xFF, name=sname_0777, id=864
song_0778:
	song_entry mid_0778_s_BOMB_v_1, bank=3, volume=120, priority=90, player=5, w8=0xFF, name=sname_0778, id=865
song_0779:
	song_entry mid_0779_s_BOMB_v_2, bank=3, volume=120, priority=90, player=5, w8=0xFF, name=sname_0779, id=866
song_0780:
	song_entry mid_0780_s_BOMB_v_3, bank=3, volume=120, priority=90, player=5, w8=0xFF, name=sname_0780, id=867
song_0781:
	song_entry mid_0781_s_BOMB_Beat_Tel_03, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0781, id=868
song_0782:
	song_entry mid_0782_s_BOMB_Beat_Tel_04, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0782, id=869
song_0783:
	song_entry mid_0783_s_BOMB_Beat_Tel_05, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0783, id=870
song_0784:
	song_entry mid_0784_s_BOMB_Beat_Tel_06, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0784, id=871
song_0785:
	song_entry mid_0785_s_BOMB_Beat_Tel_07, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0785, id=872
song_0786:
	song_entry mid_0786_s_BOMB_GYORO_Walk_01, bank=1, volume=25, priority=30, player=4, w8=0xFF, name=sname_0786, id=884
song_0787:
	song_entry mid_0787_s_BOMB_GYORO_Shot_TANE, bank=3, volume=55, priority=92, player=4, w8=0xFF, name=sname_0787, id=885
song_0788:
	song_entry mid_0788_s_BOMB_GYORO_SHITA_Dasu, bank=3, volume=40, priority=92, player=4, w8=0xFF, name=sname_0788, id=886
song_0789:
	song_entry mid_0789_s_BOMB_GYORO_SHITA_Modosu, bank=3, volume=70, priority=93, player=4, w8=0xFF, name=sname_0789, id=887
song_0790:
	song_entry mid_0790_s_BOMB_GYORO_ESA_Get, bank=3, volume=65, priority=95, player=5, w8=0xFF, name=sname_0790, id=888
song_0791:
	song_entry mid_0791_s_BOMB_GYORO_Die_01, bank=3, volume=80, priority=101, player=6, w8=0xFF, name=sname_0791, id=889
song_0792:
	song_entry mid_0792_s_BOMB_GYORO_Die_Bean, bank=1, volume=70, priority=90, player=5, w8=0xFF, name=sname_0792, id=890
song_0793:
	song_entry mid_0793_s_BOMB_GYORO_Die_Bean_2, bank=1, volume=70, priority=100, player=5, w8=0xFF, name=sname_0793, id=891
song_0794:
	song_entry mid_0794_s_BOMB_GYORO_Die_Bean_3, bank=1, volume=70, priority=100, player=5, w8=0xFF, name=sname_0794, id=892
song_0795:
	song_entry mid_0795_s_BOMB_GYORO_Die_Bean_4, bank=1, volume=70, priority=100, player=5, w8=0xFF, name=sname_0795, id=893
song_0796:
	song_entry mid_0796_s_BOMB_GYORO_BOMB_01, bank=1, volume=55, priority=90, player=6, w8=0xFF, name=sname_0796, id=894
song_0797:
	song_entry mid_0797_s_BOMB_GYORO_Repair_Engel, bank=3, volume=45, priority=90, player=3, w8=0xFF, name=sname_0797, id=895
song_0798:
	song_entry mid_0798_s_BOMB_GYORO_Repair_01, bank=3, volume=70, priority=100, player=7, w8=0xFF, name=sname_0798, id=896
song_0799:
	song_entry mid_0799_s_BOMB_GYORO_Repair_02, bank=3, volume=70, priority=100, player=7, w8=0xFF, name=sname_0799, id=897
song_0800:
	song_entry mid_0800_s_BOMB_GYORO_Repair_03, bank=3, volume=70, priority=100, player=7, w8=0xFF, name=sname_0800, id=898
song_0801:
	song_entry mid_0801_s_BOMB_GYORO_Repair_04, bank=3, volume=70, priority=100, player=7, w8=0xFF, name=sname_0801, id=899
song_0802:
	song_entry mid_0802_s_BOMB_GYORO_Repair_05, bank=3, volume=70, priority=100, player=7, w8=0xFF, name=sname_0802, id=900
song_0803:
	song_entry mid_0803_s_BOMB_GYORO_STAR, bank=3, volume=50, priority=100, player=3, w8=0xFF, name=sname_0803, id=901
song_0804:
	song_entry mid_0804_s_BOMB_Wind_01, bank=3, volume=40, priority=90, player=4, w8=0xFF, name=sname_0804, id=902
song_0805:
	song_entry mid_0805_s_BOMB_Wind_02, bank=3, volume=50, priority=90, player=7, w8=0xFF, name=sname_0805, id=903
song_0806:
	song_entry mid_0806_s_BOMB_Voice_MALE_03, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0806, id=911
song_0807:
	song_entry mid_0807_s_BOMB_Voice_MALE_04, bank=3, volume=80, priority=90, player=6, w8=0xFF, name=sname_0807, id=912
song_0808:
	song_entry mid_0808_s_BOMB_Voice_MALE_05, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_0808, id=913
song_0809:
	song_entry mid_0809_s_BOMB_Voice_MALE_06, bank=3, volume=70, priority=100, player=4, w8=0xFF, name=sname_0809, id=914
song_0810:
	song_entry mid_0810_s_BOMB_Voice_MALE_07, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0810, id=915
song_0811:
	song_entry mid_0811_s_BOMB_Voice_MALE_08, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0811, id=916
song_0812:
	song_entry mid_0812_s_BOMB_Voice_MALE_09, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0812, id=917
song_0813:
	song_entry mid_0813_s_BOMB_Voice_MALE_10, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0813, id=918
song_0814:
	song_entry mid_0814_s_BOMB_Voice_MALE_11, bank=3, volume=40, priority=90, player=6, w8=0xFF, name=sname_0814, id=919
song_0815:
	song_entry mid_0815_s_BOMB_Voice_MALE_12, bank=3, volume=45, priority=90, player=6, w8=0xFF, name=sname_0815, id=920
song_0816:
	song_entry mid_0816_s_BOMB_Voice_MALE_13, bank=3, volume=70, priority=90, player=3, w8=0xFF, name=sname_0816, id=921
song_0817:
	song_entry mid_0817_s_BOMB_Voice_FEMALE_01, bank=3, volume=50, priority=90, player=5, w8=0xFF, name=sname_0817, id=930
song_0818:
	song_entry mid_0818_s_BOMB_Voice_FEMALE_02, bank=3, volume=50, priority=90, player=6, w8=0xFF, name=sname_0818, id=931
song_0819:
	song_entry mid_0819_s_BOMB_Voice_FEMALE_03, bank=3, volume=50, priority=90, player=3, w8=0xFF, name=sname_0819, id=932
song_0820:
	song_entry mid_0820_s_BOMB_Voice_Child_01, bank=3, volume=65, priority=90, player=4, w8=0xFF, name=sname_0820, id=940
song_0821:
	song_entry mid_0821_s_BOMB_Voice_Child_02, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_0821, id=941
song_0822:
	song_entry mid_0822_s_BOMB_Voice_Child_03, bank=3, volume=40, priority=90, player=4, w8=0xFF, name=sname_0822, id=942
song_0823:
	song_entry mid_0823_s_BOMB_Voice_Sneeze_01, bank=3, volume=110, priority=90, player=4, w8=0xFF, name=sname_0823, id=950
song_0824:
	song_entry mid_0824_s_BOMB_Voice_Sneeze_02, bank=3, volume=90, priority=90, player=5, w8=0xFF, name=sname_0824, id=951
song_0825:
	song_entry mid_0825_s_BOMB_Voice_PON_01, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0825, id=952
song_0826:
	song_entry mid_0826_s_BOMB_Voice_PON_02, bank=3, volume=110, priority=100, player=5, w8=0xFF, name=sname_0826, id=953
song_0827:
	song_entry mid_0827_s_BOMB_Voice_PON_03, bank=3, volume=60, priority=90, player=5, w8=0xFF, name=sname_0827, id=954
song_0828:
	song_entry mid_0828_s_BOMB_Voice_Frog_01, bank=3, volume=100, priority=90, player=5, w8=0xFF, name=sname_0828, id=955
song_0829:
	song_entry mid_0829_s_BOMB_Voice_Cat_01, bank=3, volume=70, priority=90, player=5, w8=0xFF, name=sname_0829, id=956
song_0830:
	song_entry mid_0830_s_BOMB_Voice_TakoIka, bank=3, volume=80, priority=80, player=4, w8=0xFF, name=sname_0830, id=957
song_0831:
	song_entry mid_0831_s_BOMB_Voice_Funkoro, bank=3, volume=70, priority=80, player=4, w8=0xFF, name=sname_0831, id=958
song_0832:
	song_entry mid_0832_s_BOMB_Swing_02, bank=1, volume=100, priority=101, player=6, w8=0xFF, name=sname_0832, id=960
song_0833:
	song_entry mid_0833_s_BOMB_Swing_03, bank=1, volume=60, priority=100, player=6, w8=0xFF, name=sname_0833, id=961
song_0834:
	song_entry mid_0834_s_wario_TURN, bank=1, volume=40, priority=12, player=5, w8=0xFF, name=sname_0834, id=962
song_0835:
	song_entry mid_0835_s_AFRO_BOMB_Burst, bank=1, volume=110, priority=100, player=5, w8=0xFF, name=sname_0835, id=963
song_0836:
	song_entry mid_0836_s_BOMB_Fit_01, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_0836, id=964
song_0837:
	song_entry mid_0837_s_BOMB_Hit_01, bank=3, volume=80, priority=102, player=5, w8=0xFF, name=sname_0837, id=970
song_0838:
	song_entry mid_0838_s_BOMB_Hit_02, bank=3, volume=110, priority=102, player=5, w8=0xFF, name=sname_0838, id=971
song_0839:
	song_entry mid_0839_s_BOMB_Hit_03, bank=3, volume=90, priority=90, player=5, w8=0xFF, name=sname_0839, id=972
song_0840:
	song_entry mid_0840_s_BOMB_Hit_04, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0840, id=973
song_0841:
	song_entry mid_0841_s_BOMB_Hit_05, bank=3, volume=80, priority=90, player=5, w8=0xFF, name=sname_0841, id=974
song_0842:
	song_entry mid_0842_s_BOMB_Hit_06, bank=3, volume=25, priority=95, player=5, w8=0xFF, name=sname_0842, id=975
song_0843:
	song_entry mid_0843_s_BOMB_Hit_07, bank=3, volume=60, priority=95, player=5, w8=0xFF, name=sname_0843, id=976
song_0844:
	song_entry mid_0844_s_BOMB_Hit_08, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_0844, id=977
song_0845:
	song_entry mid_0845_s_BOMB_Hit_09, bank=3, volume=70, priority=90, player=6, w8=0xFF, name=sname_0845, id=978
song_0846:
	song_entry mid_0846_s_BOMB_Hit_10, bank=3, volume=70, priority=90, player=6, w8=0xFF, name=sname_0846, id=979
song_0847:
	song_entry mid_0847_s_BOMB_Hit_11, bank=3, volume=60, priority=90, player=6, w8=0xFF, name=sname_0847, id=980
song_0848:
	song_entry mid_0848_s_BOMB_Hit_12, bank=3, volume=60, priority=100, player=6, w8=0xFF, name=sname_0848, id=981
song_0849:
	song_entry mid_0849_s_BOMB_Hit_13, bank=3, volume=90, priority=100, player=6, w8=0xFF, name=sname_0849, id=982
song_0850:
	song_entry mid_0850_s_BOMB_Hit_14, bank=3, volume=100, priority=100, player=6, w8=0xFF, name=sname_0850, id=983
song_0851:
	song_entry mid_0851_s_BOMB_Music_CowBell, bank=3, volume=100, priority=100, player=3, w8=0xFF, name=sname_0851, id=984
song_0852:
	song_entry mid_0852_s_BOMB_Music_Drum, bank=3, volume=80, priority=100, player=3, w8=0xFF, name=sname_0852, id=985
song_0853:
	song_entry mid_0853_s_BOMB_Music_Guitar, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0853, id=986
song_0854:
	song_entry mid_0854_s_BOMB_Music_Whistle, bank=3, volume=90, priority=100, player=6, w8=0xFF, name=sname_0854, id=987
song_0855:
	song_entry mid_0855_s_BOMB_Music_ALL, bank=3, volume=80, priority=100, player=3, w8=0xFF, name=sname_0855, id=988
song_0856:
	song_entry mid_0856_s_Drum_BD_1, bank=3, volume=100, priority=100, player=2, w8=0xFF, name=sname_0856, id=990
song_0857:
	song_entry mid_0857_s_Drum_SD_1, bank=3, volume=100, priority=100, player=3, w8=0xFF, name=sname_0857, id=991
song_0858:
	song_entry mid_0858_s_Drum_SD_Rim_Close, bank=3, volume=100, priority=100, player=3, w8=0xFF, name=sname_0858, id=992
song_0859:
	song_entry mid_0859_s_Drum_SD_Rim_Open, bank=3, volume=100, priority=100, player=3, w8=0xFF, name=sname_0859, id=993
song_0860:
	song_entry mid_0860_s_Drum_SD_Roll, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_0860, id=994
song_0861:
	song_entry mid_0861_s_Drum_Tom_1, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_0861, id=995
song_0862:
	song_entry mid_0862_s_Drum_Sym_Crash, bank=3, volume=100, priority=100, player=6, w8=0xFF, name=sname_0862, id=996
song_0863:
	song_entry mid_0863_s_Drum_Sym_Sprash, bank=3, volume=100, priority=100, player=7, w8=0xFF, name=sname_0863, id=997
song_0864:
	song_entry mid_0864_s_x_NoSound, bank=3, volume=0, priority=0, player=0, w8=0xFF, name=sname_0864, id=999
song_0865:
	song_entry mid_0865_m_BGM_BOMB_01, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0865, id=1001
song_0866:
	song_entry mid_0866_m_BGM_BOMB_02, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0866, id=1002
song_0867:
	song_entry mid_0867_m_BGM_BOMB_03, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0867, id=1003
song_0868:
	song_entry mid_0868_m_BGM_BOMB_04, bank=3, volume=55, priority=0, player=0, w8=0xFF, name=sname_0868, id=1004
song_0869:
	song_entry mid_0869_m_BGM_BOMB_05, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0869, id=1005
song_0870:
	song_entry mid_0870_m_BGM_BOMB_06, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0870, id=1006
song_0871:
	song_entry mid_0871_m_BGM_BOMB_07, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0871, id=1007
song_0872:
	song_entry mid_0872_m_BGM_BOMB_08, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0872, id=1008
song_0873:
	song_entry mid_0873_m_BGM_BOMB_09, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0873, id=1009
song_0874:
	song_entry mid_0874_m_BGM_BOMB_10, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0874, id=1010
song_0875:
	song_entry mid_0875_m_BGM_BOMB_11, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0875, id=1011
song_0876:
	song_entry mid_0876_m_BGM_BOMB_12, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0876, id=1012
song_0877:
	song_entry mid_0877_m_BGM_BOMB_13, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0877, id=1013
song_0878:
	song_entry mid_0878_m_BGM_BOMB_14, bank=2, volume=50, priority=0, player=0, w8=0xFF, name=sname_0878, id=1014
song_0879:
	song_entry mid_0879_m_BGM_BOMB_15, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0879, id=1015
song_0880:
	song_entry mid_0880_m_BGM_BOMB_16, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0880, id=1016
song_0881:
	song_entry mid_0881_m_BGM_BOMB_17, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0881, id=1017
song_0882:
	song_entry mid_0882_m_BGM_BOMB_18, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0882, id=1018
song_0883:
	song_entry mid_0883_m_BGM_BOMB_19, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0883, id=1019
song_0884:
	song_entry mid_0884_m_BGM_BOMB_20, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0884, id=1020
song_0885:
	song_entry mid_0885_m_BGM_BOMB_21, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0885, id=1021
song_0886:
	song_entry mid_0886_m_BGM_BOMB_22, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0886, id=1022
song_0887:
	song_entry mid_0887_m_BGM_BOMB_23, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0887, id=1023
song_0888:
	song_entry mid_0888_m_BGM_BOMB_24, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0888, id=1024
song_0889:
	song_entry mid_0889_m_BGM_BOMB_25, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0889, id=1025
song_0890:
	song_entry mid_0890_m_BGM_BOMB_26, bank=1, volume=60, priority=0, player=0, w8=0xFF, name=sname_0890, id=1026
song_0891:
	song_entry mid_0891_m_BGM_BOMB_27_Zelda1, bank=1, volume=55, priority=0, player=0, w8=0xFF, name=sname_0891, id=1027
song_0892:
	song_entry mid_0892_m_BGM_BOMB_28_DrMario, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0892, id=1028
song_0893:
	song_entry mid_0893_m_BGM_BOMB_29_Donkey, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0893, id=1029
song_0894:
	song_entry mid_0894_m_BGM_BOMB_30_MPaint, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0894, id=1030
song_0895:
	song_entry mid_0895_m_BGM_BOMB_31_Mario, bank=1, volume=50, priority=0, player=0, w8=0xFF, name=sname_0895, id=1031
song_0896:
	song_entry mid_0896_m_BGM_BOMB_32_Wario_01, bank=1, volume=30, priority=0, player=0, w8=0xFF, name=sname_0896, id=1032
song_0897:
	song_entry mid_0897_m_BGM_BOMB_33_Wario_02, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0897, id=1033
song_0898:
	song_entry mid_0898_m_BGM_BOMB_34_Wario_03, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0898, id=1034
song_0899:
	song_entry mid_0899_m_BGM_BOMB_35_0_1, bank=3, volume=70, priority=101, player=3, w8=0xFF, name=sname_0899, id=1035
song_0900:
	song_entry mid_0900_m_BGM_BOMB_35_0_2, bank=3, volume=70, priority=101, player=3, w8=0xFF, name=sname_0900, id=1036
song_0901:
	song_entry mid_0901_m_BGM_BOMB_35_1, bank=3, volume=60, priority=101, player=3, w8=0xFF, name=sname_0901, id=1037
song_0902:
	song_entry mid_0902_m_BGM_BOMB_35_2, bank=3, volume=70, priority=101, player=3, w8=0xFF, name=sname_0902, id=1038
song_0903:
	song_entry mid_0903_m_BGM_BOMB_36, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0903, id=1039
song_0904:
	song_entry mid_0904_m_BGM_BOMB_37, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0904, id=1040
song_0905:
	song_entry mid_0905_m_BGM_BOMB_38, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0905, id=1041
song_0906:
	song_entry mid_0906_m_BGM_BOMB_39, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0906, id=1042
song_0907:
	song_entry mid_0907_m_BGM_BOMB_40, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0907, id=1043
song_0908:
	song_entry mid_0908_m_BGM_BOMB_41, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0908, id=1044
song_0909:
	song_entry mid_0909_m_BGM_BOMB_42, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0909, id=1045
song_0910:
	song_entry mid_0910_m_BGM_BOMB_43, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0910, id=1046
song_0911:
	song_entry mid_0911_m_BGM_BOMB_44, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0911, id=1047
song_0912:
	song_entry mid_0912_m_BGM_BOMB_45, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0912, id=1048
song_0913:
	song_entry mid_0913_m_BGM_BOMB_46, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0913, id=1049
song_0914:
	song_entry mid_0914_m_BGM_BOMB_47, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0914, id=1050
song_0915:
	song_entry mid_0915_m_BGM_BOMB_48, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0915, id=1051
song_0916:
	song_entry mid_0916_m_BGM_BOMB_50, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0916, id=1053
song_0917:
	song_entry mid_0917_m_BGM_BOMB_51, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0917, id=1054
song_0918:
	song_entry mid_0918_m_BGM_BOMB_52, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0918, id=1055
song_0919:
	song_entry mid_0919_m_BGM_BOMB_53, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0919, id=1056
song_0920:
	song_entry mid_0920_m_BGM_BOMB_54, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0920, id=1057
song_0921:
	song_entry mid_0921_m_BGM_BOMB_55, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0921, id=1058
song_0922:
	song_entry mid_0922_m_BGM_BOMB_56, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0922, id=1059
song_0923:
	song_entry mid_0923_m_BGM_BOMB_57, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0923, id=1060
song_0924:
	song_entry mid_0924_m_BGM_BOMB_58, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0924, id=1061
song_0925:
	song_entry mid_0925_m_BGM_BOMB_59, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0925, id=1062
song_0926:
	song_entry mid_0926_m_BGM_BOMB_60, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0926, id=1063
song_0927:
	song_entry mid_0927_m_BGM_BOMB_61, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0927, id=1064
song_0928:
	song_entry mid_0928_m_BGM_BOMB_62, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0928, id=1065
song_0929:
	song_entry mid_0929_m_BGM_BOMB_63, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0929, id=1066
song_0930:
	song_entry mid_0930_m_BGM_BOMB_64, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0930, id=1067
song_0931:
	song_entry mid_0931_m_BGM_BOMB_65, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0931, id=1068
song_0932:
	song_entry mid_0932_m_BGM_BOMB_66, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0932, id=1069
song_0933:
	song_entry mid_0933_m_BGM_BOMB_67, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0933, id=1070
song_0934:
	song_entry mid_0934_m_BGM_BOMB_68, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0934, id=1071
song_0935:
	song_entry mid_0935_m_BGM_BOMB_69, bank=3, volume=55, priority=0, player=0, w8=0xFF, name=sname_0935, id=1072
song_0936:
	song_entry mid_0936_m_BGM_BOMB_70, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0936, id=1073
song_0937:
	song_entry mid_0937_m_BGM_BOMB_71, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0937, id=1074
song_0938:
	song_entry mid_0938_m_BGM_BOMB_72, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0938, id=1075
song_0939:
	song_entry mid_0939_m_BGM_BOMB_73, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0939, id=1076
song_0940:
	song_entry mid_0940_m_BGM_BOMB_74, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0940, id=1077
song_0941:
	song_entry mid_0941_m_BGM_BOMB_75, bank=3, volume=55, priority=0, player=0, w8=0xFF, name=sname_0941, id=1078
song_0942:
	song_entry mid_0942_m_BGM_BOMB_76, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0942, id=1079
song_0943:
	song_entry mid_0943_m_BGM_BOMB_77, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0943, id=1080
song_0944:
	song_entry mid_0944_m_BGM_BOMB_78, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0944, id=1081
song_0945:
	song_entry mid_0945_m_BGM_BOMB_79, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0945, id=1082
song_0946:
	song_entry mid_0946_m_BGM_BOMB_80, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0946, id=1083
song_0947:
	song_entry mid_0947_m_BGM_BOMB_81, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0947, id=1084
song_0948:
	song_entry mid_0948_m_BGM_BOMB_82, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0948, id=1085
song_0949:
	song_entry mid_0949_m_BGM_BOMB_83, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0949, id=1086
song_0950:
	song_entry mid_0950_m_BGM_BOMB_84, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0950, id=1087
song_0951:
	song_entry mid_0951_m_BGM_BOMB_85, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0951, id=1088
song_0952:
	song_entry mid_0952_m_BGM_BOMB_86, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0952, id=1089
song_0953:
	song_entry mid_0953_m_BGM_BOMB_87, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0953, id=1090
song_0954:
	song_entry mid_0954_m_BGM_BOMB_88, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0954, id=1091
song_0955:
	song_entry mid_0955_m_BGM_BOMB_89, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0955, id=1092
song_0956:
	song_entry mid_0956_m_BGM_BOMB_90, bank=3, volume=40, priority=0, player=0, w8=0xFF, name=sname_0956, id=1093
song_0957:
	song_entry mid_0957_m_BGM_BOMB_91, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0957, id=1094
song_0958:
	song_entry mid_0958_m_BGM_BOMB_92, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0958, id=1095
song_0959:
	song_entry mid_0959_m_BGM_BOMB_93, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_0959, id=1096
song_0960:
	song_entry mid_0960_m_BGM_BOMB_94, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0960, id=1097
song_0961:
	song_entry mid_0961_m_BGM_BOMB_95, bank=3, volume=55, priority=0, player=0, w8=0xFF, name=sname_0961, id=1098
song_0962:
	song_entry mid_0962_m_BGM_BOMB_96, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0962, id=1099
song_0963:
	song_entry mid_0963_m_BGM_BOMB_97, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0963, id=1100
song_0964:
	song_entry mid_0964_m_BGM_BOMB_98, bank=3, volume=45, priority=0, player=0, w8=0xFF, name=sname_0964, id=1101
song_0965:
	song_entry mid_0965_m_BGM_BOMB_99, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0965, id=1102
song_0966:
	song_entry mid_0966_m_BGM_BOMB_100, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0966, id=1103
song_0967:
	song_entry mid_0967_m_BGM_BOMB_101, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0967, id=1104
song_0968:
	song_entry mid_0968_m_BGM_BOMB_102, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0968, id=1105
song_0969:
	song_entry mid_0969_m_BGM_BOMB_103, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0969, id=1106
song_0970:
	song_entry mid_0970_m_BGM_BOMB_Finish_1, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0970, id=1117
song_0971:
	song_entry mid_0971_m_BGM_BOMB_Finish_2, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0971, id=1118
song_0972:
	song_entry mid_0972_m_BGM_BOMB_REST_1, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0972, id=1119
song_0973:
	song_entry mid_0973_m_BGM_BOMB_Demo_11, bank=3, volume=85, priority=0, player=0, w8=0xFF, name=sname_0973, id=1120
song_0974:
	song_entry mid_0974_m_BGM_BOMB_Demo_2, bank=3, volume=70, priority=0, player=1, w8=0xFF, name=sname_0974, id=1121
song_0975:
	song_entry mid_0975_m_BGM_BOSS_FF_Clear_1, bank=3, volume=90, priority=110, player=2, w8=0xFF, name=sname_0975, id=1122
song_0976:
	song_entry mid_0976_m_BGM_BOSS_FF_Lose_1, bank=3, volume=90, priority=110, player=2, w8=0xFF, name=sname_0976, id=1123
song_0977:
	song_entry mid_0977_m_BGM_PIG_END_01, bank=3, volume=50, priority=0, player=0, w8=0xFF, name=sname_0977, id=1124
song_0978:
	song_entry mid_0978_m_BGM_BOMB_READY_Turn_1, bank=3, volume=105, priority=0, player=0, w8=0xFF, name=sname_0978, id=1125
song_0979:
	song_entry mid_0979_m_BGM_BOMB_GOOD_0, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0979, id=1126
song_0980:
	song_entry mid_0980_m_BGM_BOMB_BAD_0, bank=3, volume=80, priority=0, player=0, w8=0xFF, name=sname_0980, id=1127
song_0981:
	song_entry mid_0981_m_BGM_ROPE_Select, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0981, id=1128
song_0982:
	song_entry mid_0982_m_BGM_ROPE_BGM_A00, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0982, id=1129
song_0983:
	song_entry mid_0983_m_BGM_ROPE_BGM_A01, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0983, id=1130
song_0984:
	song_entry mid_0984_m_BGM_ROPE_BGM_A02, bank=3, volume=70, priority=0, player=0, w8=0xFF, name=sname_0984, id=1131
song_0985:
	song_entry mid_0985_m_BGM_ROPE_BGM_00, bank=3, volume=100, priority=0, player=0, w8=0xFF, name=sname_0985, id=1132
song_0986:
	song_entry mid_0986_m_BGM_ROPE_BGM_01, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0986, id=1133
song_0987:
	song_entry mid_0987_m_BGM_ROPE_BGM_02, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0987, id=1134
song_0988:
	song_entry mid_0988_m_BGM_ROPE_BGM_03, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0988, id=1135
song_0989:
	song_entry mid_0989_m_BGM_ROPE_BGM_04, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0989, id=1136
song_0990:
	song_entry mid_0990_m_BGM_ROPE_BGM_KAEDE_IN, bank=3, volume=90, priority=0, player=0, w8=0xFF, name=sname_0990, id=1137
song_0991:
	song_entry mid_0991_m_BGM_ROPE_BGM_KAEDE_1A, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0991, id=1138
song_0992:
	song_entry mid_0992_m_BGM_ROPE_BGM_KAEDE_1B, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0992, id=1139
song_0993:
	song_entry mid_0993_m_BGM_ROPE_BGM_KAEDE_2A, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0993, id=1140
song_0994:
	song_entry mid_0994_m_BGM_ROPE_BGM_KAEDE_2B, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0994, id=1141
song_0995:
	song_entry mid_0995_m_BGM_DraBuru_ALL, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0995, id=1142
song_0996:
	song_entry mid_0996_m_BGM_KAEDE_ALL, bank=3, volume=90, priority=0, player=1, w8=0xFF, name=sname_0996, id=1143
song_0997:
	song_entry mid_0997_m_BGM_Loo_ALL, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_0997, id=1144
song_0998:
	song_entry mid_0998_m_BGM_Plane_BGM_01, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0998, id=1146
song_0999:
	song_entry mid_0999_m_BGM_SkateBoard_BGM_01, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_0999, id=1147
song_1000:
	song_entry mid_1000_m_BGM_SkateBoard_FF_NG, bank=3, volume=60, priority=0, player=0, w8=0xFF, name=sname_1000, id=1148
song_1001:
	song_entry mid_1001_m_BGM_VS_Title_10, bank=3, volume=65, priority=0, player=0, w8=0xFF, name=sname_1001, id=1249
song_1002:
	song_entry mid_1002_m_BGM_VS_Chiritori2_10, bank=3, volume=55, priority=0, player=1, w8=0xFF, name=sname_1002, id=1250
song_1003:
	song_entry mid_1003_m_BGM_VS_ChoroQ_10, bank=3, volume=65, priority=0, player=1, w8=0xFF, name=sname_1003, id=1251
song_1004:
	song_entry mid_1004_m_BGM_VS_ChoroQ_12, bank=3, volume=80, priority=0, player=1, w8=0xFF, name=sname_1004, id=1252
song_1005:
	song_entry mid_1005_m_BGM_VS_Hurdle_10, bank=3, volume=50, priority=0, player=1, w8=0xFF, name=sname_1005, id=1253
song_1006:
	song_entry mid_1006_m_BGM_VS_PON2_10, bank=3, volume=55, priority=0, player=1, w8=0xFF, name=sname_1006, id=1254
song_1007:
	song_entry mid_1007_m_BGM_VS_RoboControl_10, bank=3, volume=50, priority=0, player=1, w8=0xFF, name=sname_1007, id=1255
song_1008:
	song_entry mid_1008_m_BGM_FF_Victory, bank=3, volume=75, priority=0, player=1, w8=0xFF, name=sname_1008, id=1256
song_1009:
	song_entry mid_1009_s_REST_SFX_01, bank=3, volume=25, priority=100, player=3, w8=0xFF, name=sname_1009, id=1257
song_1010:
	song_entry mid_1010_s_REST_SFX_02, bank=3, volume=60, priority=100, player=3, w8=0xFF, name=sname_1010, id=1258
song_1011:
	song_entry mid_1011_s_REST_SFX_03, bank=3, volume=50, priority=100, player=4, w8=0xFF, name=sname_1011, id=1259
song_1012:
	song_entry mid_1012_s_Demo_AFRO_melo_B1, bank=3, volume=110, priority=100, player=3, w8=0xFF, name=sname_1012, id=1260
song_1013:
	song_entry mid_1013_s_Demo_AFRO_melo_C1, bank=3, volume=110, priority=100, player=3, w8=0xFF, name=sname_1013, id=1261
song_1014:
	song_entry mid_1014_s_Demo_AFRO_melo_D1, bank=3, volume=110, priority=100, player=3, w8=0xFF, name=sname_1014, id=1262
song_1015:
	song_entry mid_1015_s_BOMB_Ele_07, bank=3, volume=70, priority=100, player=6, w8=0xFF, name=sname_1015, id=1296
song_1016:
	song_entry mid_1016_s_BOMB_Ele_08, bank=3, volume=70, priority=100, player=6, w8=0xFF, name=sname_1016, id=1297
song_1017:
	song_entry mid_1017_s_BOMB_Ele_09, bank=3, volume=60, priority=100, player=5, w8=0xFF, name=sname_1017, id=1298
song_1018:
	song_entry mid_1018_s_BOMB_Ele_10, bank=3, volume=60, priority=90, player=4, w8=0xFF, name=sname_1018, id=1299
song_1019:
	song_entry mid_1019_s_VS_Hurdle_Hit_1, bank=3, volume=60, priority=100, player=6, w8=0xFF, name=sname_1019, id=1300
song_1020:
	song_entry mid_1020_s_VS_Hurdle_Hit_2, bank=3, volume=60, priority=100, player=5, w8=0xFF, name=sname_1020, id=1301
song_1021:
	song_entry mid_1021_s_VS_Hurdle_Jump_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_1021, id=1302
song_1022:
	song_entry mid_1022_s_VS_Hurdle_Jump_2, bank=3, volume=110, priority=100, player=3, w8=0xFF, name=sname_1022, id=1303
song_1023:
	song_entry mid_1023_s_VS_Chiritori_CRASH_A, bank=3, volume=80, priority=101, player=4, w8=0xFF, name=sname_1023, id=1304
song_1024:
	song_entry mid_1024_s_VS_Chiritori_CRASH_B, bank=3, volume=80, priority=101, player=6, w8=0xFF, name=sname_1024, id=1305
song_1025:
	song_entry mid_1025_s_VS_PON_Count_1, bank=3, volume=30, priority=100, player=3, w8=0xFF, name=sname_1025, id=1306
song_1026:
	song_entry mid_1026_s_VS_PON_Count_2, bank=3, volume=30, priority=100, player=3, w8=0xFF, name=sname_1026, id=1307
song_1027:
	song_entry mid_1027_s_VS_PON_Wall_1, bank=3, volume=50, priority=100, player=3, w8=0xFF, name=sname_1027, id=1308
song_1028:
	song_entry mid_1028_s_VS_PON_STAR_1, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_1028, id=1309
song_1029:
	song_entry mid_1029_s_VS_PON_STAR_2, bank=3, volume=85, priority=100, player=4, w8=0xFF, name=sname_1029, id=1310
song_1030:
	song_entry mid_1030_s_VS_PON_Hit_1, bank=3, volume=100, priority=100, player=4, w8=0xFF, name=sname_1030, id=1311
song_1031:
	song_entry mid_1031_s_VS_PON_Hit_2, bank=3, volume=100, priority=100, player=5, w8=0xFF, name=sname_1031, id=1312
song_1032:
	song_entry mid_1032_s_VS_PON_Move_1, bank=1, volume=70, priority=100, player=6, w8=0xFF, name=sname_1032, id=1313
song_1033:
	song_entry mid_1033_s_VS_PON_Move_2, bank=1, volume=70, priority=100, player=7, w8=0xFF, name=sname_1033, id=1314
song_1034:
	song_entry mid_1034_s_VS_PON_Power_1, bank=3, volume=40, priority=100, player=6, w8=0xFF, name=sname_1034, id=1315
song_1035:
	song_entry mid_1035_s_VS_PON_Power_2, bank=3, volume=40, priority=100, player=7, w8=0xFF, name=sname_1035, id=1316
song_1036:
	song_entry mid_1036_s_VS_PON_Snap_1, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_1036, id=1317
song_1037:
	song_entry mid_1037_s_VS_PON_Snap_2, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_1037, id=1318
song_1038:
	song_entry mid_1038_s_VS_ChoroQ_Scroll_1, bank=3, volume=50, priority=100, player=3, w8=0xFF, name=sname_1038, id=1319
song_1039:
	song_entry mid_1039_s_VS_ChoroQ_Scroll_2, bank=3, volume=50, priority=100, player=3, w8=0xFF, name=sname_1039, id=1320
song_1040:
	song_entry mid_1040_s_VS_ChoroQ_Pull_1, bank=3, volume=60, priority=100, player=4, w8=0xFF, name=sname_1040, id=1321
song_1041:
	song_entry mid_1041_s_VS_ChoroQ_Pull_2, bank=3, volume=60, priority=100, player=5, w8=0xFF, name=sname_1041, id=1322
song_1042:
	song_entry mid_1042_s_VS_ChoroQ_Keep_1, bank=3, volume=50, priority=100, player=4, w8=0xFF, name=sname_1042, id=1323
song_1043:
	song_entry mid_1043_s_VS_ChoroQ_Keep_2, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_1043, id=1324
song_1044:
	song_entry mid_1044_s_VS_ChoroQ_GO_1, bank=1, volume=80, priority=100, player=5, w8=0xFF, name=sname_1044, id=1325
song_1045:
	song_entry mid_1045_s_VS_ChoroQ_Lean_1, bank=3, volume=45, priority=100, player=6, w8=0xFF, name=sname_1045, id=1326
song_1046:
	song_entry mid_1046_s_BOMB_Draw_01, bank=3, volume=90, priority=100, player=7, w8=0xFF, name=sname_1046, id=1327
song_1047:
	song_entry mid_1047_s_VS_Push_UP_01, bank=3, volume=20, priority=80, player=4, w8=0xFF, name=sname_1047, id=1328
song_1048:
	song_entry mid_1048_s_VS_Push_DOWN_01, bank=3, volume=20, priority=80, player=4, w8=0xFF, name=sname_1048, id=1329
song_1049:
	song_entry mid_1049_s_VS_Push_BUTTON_01, bank=1, volume=70, priority=80, player=4, w8=0xFF, name=sname_1049, id=1330
song_1050:
	song_entry mid_1050_s_VS_Push_BUTTON_02, bank=1, volume=70, priority=80, player=5, w8=0xFF, name=sname_1050, id=1331
song_1051:
	song_entry mid_1051_s_VS_Push_HIT_01, bank=1, volume=80, priority=80, player=4, w8=0xFF, name=sname_1051, id=1332
song_1052:
	song_entry mid_1052_s_VS_PUSH_NG_01, bank=3, volume=60, priority=80, player=6, w8=0xFF, name=sname_1052, id=1333
song_1053:
	song_entry mid_1053_s_VS_PUSH_FALL_01, bank=1, volume=110, priority=80, player=6, w8=0xFF, name=sname_1053, id=1334
song_1054:
	song_entry mid_1054_s_VS_PUSH_Bomb_01, bank=1, volume=80, priority=100, player=6, w8=0xFF, name=sname_1054, id=1335
song_1055:
	song_entry mid_1055_s_Demo_Title_PINPON_1, bank=3, volume=30, priority=90, player=4, w8=0xFF, name=sname_1055, id=1338
song_1056:
	song_entry mid_1056_s_Demo_Title_PINPON_2, bank=3, volume=15, priority=90, player=6, w8=0xFF, name=sname_1056, id=1339
song_1057:
	song_entry mid_1057_s_Demo_Title_PINPON_3, bank=3, volume=40, priority=90, player=6, w8=0xFF, name=sname_1057, id=1340
song_1058:
	song_entry mid_1058_s_Demo_Title_Rotate_1, bank=3, volume=30, priority=90, player=5, w8=0xFF, name=sname_1058, id=1341
song_1059:
	song_entry mid_1059_s_Demo_Title_v_Snore_1, bank=3, volume=35, priority=90, player=6, w8=0xFF, name=sname_1059, id=1342
song_1060:
	song_entry mid_1060_s_Demo_Wario_v_1_Ho, bank=3, volume=70, priority=100, player=3, w8=0xFF, name=sname_1060, id=1343
song_1061:
	song_entry mid_1061_s_Demo_Wario_v_2_Yeah, bank=3, volume=80, priority=100, player=3, w8=0xFF, name=sname_1061, id=1344
song_1062:
	song_entry mid_1062_s_Demo_Bio_v_1_HELP, bank=3, volume=50, priority=100, player=5, w8=0xFF, name=sname_1062, id=1345
song_1063:
	song_entry mid_1063_s_Demo_Bio_v_2_KOBUN, bank=3, volume=50, priority=100, player=3, w8=0xFF, name=sname_1063, id=1346
song_1064:
	song_entry mid_1064_s_Demo_Bio_v_3_YADA, bank=3, volume=80, priority=100, player=4, w8=0xFF, name=sname_1064, id=1347
song_1065:
	song_entry mid_1065_s_Demo_Bio_Siren_1, bank=3, volume=80, priority=100, player=3, w8=0xFF, name=sname_1065, id=1348
song_1066:
	song_entry mid_1066_s_Demo_Bio_Switch_1, bank=3, volume=70, priority=100, player=3, w8=0xFF, name=sname_1066, id=1349
song_1067:
	song_entry mid_1067_s_Demo_Bio_Down_1, bank=3, volume=30, priority=100, player=3, w8=0xFF, name=sname_1067, id=1350
song_1068:
	song_entry mid_1068_s_Demo_Bio_Fall_1, bank=3, volume=40, priority=100, player=3, w8=0xFF, name=sname_1068, id=1351
song_1069:
	song_entry mid_1069_s_Demo_Bio_DON_1, bank=3, volume=70, priority=100, player=4, w8=0xFF, name=sname_1069, id=1352
song_1070:
	song_entry mid_1070_s_Demo_Bio_DON_2, bank=3, volume=70, priority=100, player=3, w8=0xFF, name=sname_1070, id=1353
song_1071:
	song_entry mid_1071_s_Demo_App_v_1_Morning, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1071, id=1354
song_1072:
	song_entry mid_1072_s_Demo_App_v_1_Hello, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1072, id=1355
song_1073:
	song_entry mid_1073_s_Demo_App_v_1_Night, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1073, id=1356
song_1074:
	song_entry mid_1074_s_Demo_App_v_2_Baby, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1074, id=1357
song_1075:
	song_entry mid_1075_s_Demo_App_v_2_Party, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1075, id=1358
song_1076:
	song_entry mid_1076_s_Demo_App_v_3_Laugh, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1076, id=1359
song_1077:
	song_entry mid_1077_s_Demo_App_v_3_Wow, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1077, id=1360
song_1078:
	song_entry mid_1078_s_Demo_App_v_4_OK, bank=3, volume=65, priority=90, player=4, w8=0xFF, name=sname_1078, id=1361
song_1079:
	song_entry mid_1079_s_Demo_App_v_4_DJ, bank=3, volume=65, priority=90, player=4, w8=0xFF, name=sname_1079, id=1362
song_1080:
	song_entry mid_1080_s_Demo_Dra_v_1_Ahh, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1080, id=1363
song_1081:
	song_entry mid_1081_s_Demo_Dra_v_1_Uhn, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_1081, id=1364
song_1082:
	song_entry mid_1082_s_Demo_Dra_v_2_Where, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1082, id=1365
song_1083:
	song_entry mid_1083_s_Demo_Dra_v_3_Ahh, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1083, id=1366
song_1084:
	song_entry mid_1084_s_Demo_Dra_v_3_Hey, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1084, id=1367
song_1085:
	song_entry mid_1085_s_Demo_Mon_v_1_Haa, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1085, id=1370
song_1086:
	song_entry mid_1086_s_Demo_Mon_v_1_Oh, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1086, id=1371
song_1087:
	song_entry mid_1087_s_Demo_Mon_v_2_Ahh, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1087, id=1372
song_1088:
	song_entry mid_1088_s_Demo_Mon_v_2_Go, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_1088, id=1373
song_1089:
	song_entry mid_1089_s_Demo_Mon_v_3_Hurry, bank=3, volume=90, priority=90, player=4, w8=0xFF, name=sname_1089, id=1374
song_1090:
	song_entry mid_1090_s_Demo_Mon_v_3_Go, bank=3, volume=90, priority=90, player=4, w8=0xFF, name=sname_1090, id=1375
song_1091:
	song_entry mid_1091_s_Demo_Mon_v_4_Ahn, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_1091, id=1376
song_1092:
	song_entry mid_1092_s_Demo_Mon_v_4_Go, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_1092, id=1377
song_1093:
	song_entry mid_1093_s_Demo_Mon_Switch_1, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1093, id=1378
song_1094:
	song_entry mid_1094_s_Demo_Mon_Switch_2, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1094, id=1379
song_1095:
	song_entry mid_1095_s_Demo_Mon_Switch_3, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1095, id=1380
song_1096:
	song_entry mid_1096_s_Demo_Mon_Shot_1, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_1096, id=1381
song_1097:
	song_entry mid_1097_s_Demo_Mon_Shot_2, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1097, id=1382
song_1098:
	song_entry mid_1098_s_Demo_Mon_Shot_3, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_1098, id=1383
song_1099:
	song_entry mid_1099_s_Demo_Mon_PATO_Crash, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_1099, id=1384
song_1100:
	song_entry mid_1100_s_Demo_Mon_PATO_Jump, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1100, id=1385
song_1101:
	song_entry mid_1101_s_Demo_Mon_PATO_1, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_1101, id=1386
song_1102:
	song_entry mid_1102_s_Demo_Mon_PATO_2, bank=3, volume=100, priority=90, player=4, w8=0xFF, name=sname_1102, id=1387
song_1103:
	song_entry mid_1103_s_Demo_Voya_v_1_Fuu, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1103, id=1388
song_1104:
	song_entry mid_1104_s_Demo_Voya_v_1_Haa, bank=3, volume=50, priority=90, player=4, w8=0xFF, name=sname_1104, id=1389
song_1105:
	song_entry mid_1105_s_Demo_Voya_v_2_9V, bank=3, volume=45, priority=90, player=4, w8=0xFF, name=sname_1105, id=1390
song_1106:
	song_entry mid_1106_s_Demo_Voya_v_2_Ready, bank=3, volume=45, priority=90, player=4, w8=0xFF, name=sname_1106, id=1391
song_1107:
	song_entry mid_1107_s_Demo_Loo_v_1_Laugh, bank=3, volume=55, priority=90, player=4, w8=0xFF, name=sname_1107, id=1392
song_1108:
	song_entry mid_1108_s_Demo_Loo_v_1_OK, bank=3, volume=55, priority=90, player=4, w8=0xFF, name=sname_1108, id=1393
song_1109:
	song_entry mid_1109_s_Demo_Loo_v_2_HaHa, bank=3, volume=60, priority=90, player=4, w8=0xFF, name=sname_1109, id=1394
song_1110:
	song_entry mid_1110_s_Demo_Loo_v_3_GOKU, bank=3, volume=70, priority=90, player=4, w8=0xFF, name=sname_1110, id=1395
song_1111:
	song_entry mid_1111_s_Demo_Loo_v_4_Ah, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1111, id=1396
song_1112:
	song_entry mid_1112_s_Demo_Loo_v_4_Oh, bank=3, volume=90, priority=90, player=4, w8=0xFF, name=sname_1112, id=1397
song_1113:
	song_entry mid_1113_s_Demo_Loo_v_5_Bee, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1113, id=1398
song_1114:
	song_entry mid_1114_s_Demo_Loo_v_5_Naa, bank=3, volume=80, priority=90, player=4, w8=0xFF, name=sname_1114, id=1399
song_1115:
	song_entry mid_1115_s_v_WARIO_YAHOO_1, bank=1, volume=90, priority=120, player=7, w8=0xFF, name=sname_1115, id=1400
song_1116:
	song_entry mid_1116_s_v_WARIO_YAHOO_2, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1116, id=1401
song_1117:
	song_entry mid_1117_s_v_WARIO_YAHOO_3, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1117, id=1402
song_1118:
	song_entry mid_1118_s_v_WARIO_YAHOO_4, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1118, id=1403
song_1119:
	song_entry mid_1119_s_v_WARIO_YAHOO_5, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1119, id=1404
song_1120:
	song_entry mid_1120_s_v_WARIO_EXCELLENT_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1120, id=1405
song_1121:
	song_entry mid_1121_s_v_WARIO_EXCELLENT_2, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1121, id=1406
song_1122:
	song_entry mid_1122_s_v_WARIO_EXCELLENT_3, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1122, id=1407
song_1123:
	song_entry mid_1123_s_v_WARIO_OH_RIGHT_1, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1123, id=1408
song_1124:
	song_entry mid_1124_s_v_WARIO_OH_RIGHT_2, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1124, id=1409
song_1125:
	song_entry mid_1125_s_v_WARIO_LAUGH_HA1_1, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1125, id=1410
song_1126:
	song_entry mid_1126_s_v_WARIO_LAUGH_HA1_2, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1126, id=1411
song_1127:
	song_entry mid_1127_s_v_WARIO_LAUGH_HA2_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1127, id=1412
song_1128:
	song_entry mid_1128_s_v_WARIO_LAUGH_HI_1, bank=1, volume=90, priority=120, player=7, w8=0xFF, name=sname_1128, id=1413
song_1129:
	song_entry mid_1129_s_v_WARIO_OK_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1129, id=1414
song_1130:
	song_entry mid_1130_s_v_WARIO_OK_2, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1130, id=1415
song_1131:
	song_entry mid_1131_s_v_WARIO_OK_3, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1131, id=1416
song_1132:
	song_entry mid_1132_s_v_WARIO_OH_BOY_1, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1132, id=1417
song_1133:
	song_entry mid_1133_s_v_WARIO_OH_BOY_2, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1133, id=1418
song_1134:
	song_entry mid_1134_s_v_WARIO_HEY_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1134, id=1419
song_1135:
	song_entry mid_1135_s_v_WARIO_HEYHEY_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1135, id=1420
song_1136:
	song_entry mid_1136_s_v_WARIO_YEAH_1, bank=1, volume=80, priority=120, player=7, w8=0xFF, name=sname_1136, id=1421
song_1137:
	song_entry mid_1137_s_v_WARIO_NO_1, bank=1, volume=90, priority=120, player=7, w8=0xFF, name=sname_1137, id=1422
song_1138:
	song_entry mid_1138_s_v_WARIO_NO_2, bank=1, volume=90, priority=120, player=7, w8=0xFF, name=sname_1138, id=1423
song_1139:
	song_entry mid_1139_s_v_WARIO_NO_3, bank=1, volume=80, priority=120, player=7, w8=0xFF, name=sname_1139, id=1424
song_1140:
	song_entry mid_1140_s_v_WARIO_AHH_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1140, id=1425
song_1141:
	song_entry mid_1141_s_v_WARIO_AHH_2, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1141, id=1426
song_1142:
	song_entry mid_1142_s_v_WARIO_AHH_3, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1142, id=1427
song_1143:
	song_entry mid_1143_s_v_WARIO_AHH_EYEAH_1, bank=1, volume=90, priority=120, player=7, w8=0xFF, name=sname_1143, id=1428
song_1144:
	song_entry mid_1144_s_v_WARIO_AHH_EYEAH_2, bank=1, volume=90, priority=120, player=7, w8=0xFF, name=sname_1144, id=1429
song_1145:
	song_entry mid_1145_s_v_WARIO_HA_1, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1145, id=1430
song_1146:
	song_entry mid_1146_s_v_WARIO_WAA_1, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1146, id=1431
song_1147:
	song_entry mid_1147_s_v_WARIO_WAA_2, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1147, id=1432
song_1148:
	song_entry mid_1148_s_v_WARIO_WAO_1, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1148, id=1433
song_1149:
	song_entry mid_1149_s_v_WARIO_WAO_2, bank=1, volume=100, priority=120, player=7, w8=0xFF, name=sname_1149, id=1434
song_1150:
	song_entry mid_1150_s_v_WARIO_WIN_YOKI, bank=1, volume=110, priority=120, player=7, w8=0xFF, name=sname_1150, id=1455
song_1151:
	song_entry mid_1151_s_v_Monna_OK_01, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1151, id=1500
song_1152:
	song_entry mid_1152_s_v_Monna_OK_02, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1152, id=1501
song_1153:
	song_entry mid_1153_s_v_Monna_OK_03, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1153, id=1502
song_1154:
	song_entry mid_1154_s_v_Monna_OK_04, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1154, id=1503
song_1155:
	song_entry mid_1155_s_v_Monna_OK_05, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1155, id=1504
song_1156:
	song_entry mid_1156_s_v_Monna_OK_06, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1156, id=1505
song_1157:
	song_entry mid_1157_s_v_Monna_OK_07, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1157, id=1506
song_1158:
	song_entry mid_1158_s_v_Monna_OK_08, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1158, id=1507
song_1159:
	song_entry mid_1159_s_v_Monna_OK_09, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1159, id=1508
song_1160:
	song_entry mid_1160_s_v_Monna_OK_10, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1160, id=1509
song_1161:
	song_entry mid_1161_s_v_Monna_OK_11, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1161, id=1510
song_1162:
	song_entry mid_1162_s_v_Monna_OK_12, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1162, id=1511
song_1163:
	song_entry mid_1163_s_v_Monna_OK_13, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1163, id=1512
song_1164:
	song_entry mid_1164_s_v_Monna_NG_01, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1164, id=1520
song_1165:
	song_entry mid_1165_s_v_Monna_NG_02, bank=3, volume=70, priority=120, player=7, w8=0xFF, name=sname_1165, id=1521
song_1166:
	song_entry mid_1166_s_v_Monna_NG_03, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1166, id=1522
song_1167:
	song_entry mid_1167_s_v_Monna_NG_04, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1167, id=1523
song_1168:
	song_entry mid_1168_s_v_Monna_NG_05, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1168, id=1524
song_1169:
	song_entry mid_1169_s_v_Monna_NG_06, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1169, id=1525
song_1170:
	song_entry mid_1170_s_v_Monna_NG_07, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1170, id=1526
song_1171:
	song_entry mid_1171_s_v_Monna_NG_08, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1171, id=1527
song_1172:
	song_entry mid_1172_s_v_Monna_NG_09, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1172, id=1528
song_1173:
	song_entry mid_1173_s_v_Monna_NG_10, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1173, id=1529
song_1174:
	song_entry mid_1174_s_v_App_OK_01, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1174, id=1540
song_1175:
	song_entry mid_1175_s_v_App_OK_02, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1175, id=1541
song_1176:
	song_entry mid_1176_s_v_App_OK_03, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1176, id=1542
song_1177:
	song_entry mid_1177_s_v_App_OK_04, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1177, id=1543
song_1178:
	song_entry mid_1178_s_v_App_OK_05, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1178, id=1544
song_1179:
	song_entry mid_1179_s_v_App_OK_06, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1179, id=1545
song_1180:
	song_entry mid_1180_s_v_App_OK_07, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1180, id=1546
song_1181:
	song_entry mid_1181_s_v_App_OK_08, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1181, id=1547
song_1182:
	song_entry mid_1182_s_v_App_OK_09, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1182, id=1548
song_1183:
	song_entry mid_1183_s_v_App_OK_10, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1183, id=1549
song_1184:
	song_entry mid_1184_s_v_App_OK_11, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1184, id=1550
song_1185:
	song_entry mid_1185_s_v_App_OK_12, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1185, id=1551
song_1186:
	song_entry mid_1186_s_v_App_OK_13, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1186, id=1552
song_1187:
	song_entry mid_1187_s_v_App_OK_14, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1187, id=1553
song_1188:
	song_entry mid_1188_s_v_App_OK_15, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1188, id=1554
song_1189:
	song_entry mid_1189_s_v_App_OK_16, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1189, id=1555
song_1190:
	song_entry mid_1190_s_v_App_NG_01, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1190, id=1560
song_1191:
	song_entry mid_1191_s_v_App_NG_02, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1191, id=1561
song_1192:
	song_entry mid_1192_s_v_App_NG_03, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1192, id=1562
song_1193:
	song_entry mid_1193_s_v_App_NG_04, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1193, id=1563
song_1194:
	song_entry mid_1194_s_v_App_NG_05, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1194, id=1564
song_1195:
	song_entry mid_1195_s_v_App_NG_06, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1195, id=1565
song_1196:
	song_entry mid_1196_s_v_App_NG_07, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1196, id=1566
song_1197:
	song_entry mid_1197_s_v_App_NG_08, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1197, id=1567
song_1198:
	song_entry mid_1198_s_v_App_NG_09, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1198, id=1568
song_1199:
	song_entry mid_1199_s_v_App_NG_10, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1199, id=1569
song_1200:
	song_entry mid_1200_s_v_App_NG_11, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1200, id=1570
song_1201:
	song_entry mid_1201_s_v_App_Morning_1, bank=3, volume=120, priority=120, player=7, w8=0xFF, name=sname_1201, id=1580
song_1202:
	song_entry mid_1202_s_v_App_Hello_1, bank=3, volume=120, priority=120, player=7, w8=0xFF, name=sname_1202, id=1581
song_1203:
	song_entry mid_1203_s_v_App_Night_1, bank=3, volume=120, priority=120, player=7, w8=0xFF, name=sname_1203, id=1582
song_1204:
	song_entry mid_1204_s_v_Dra_OK_01, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1204, id=1590
song_1205:
	song_entry mid_1205_s_v_Dra_OK_02, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1205, id=1591
song_1206:
	song_entry mid_1206_s_v_Dra_OK_03, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1206, id=1592
song_1207:
	song_entry mid_1207_s_v_Dra_OK_04, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1207, id=1593
song_1208:
	song_entry mid_1208_s_v_Dra_OK_05, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1208, id=1594
song_1209:
	song_entry mid_1209_s_v_Dra_OK_06, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1209, id=1595
song_1210:
	song_entry mid_1210_s_v_Dra_OK_07, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1210, id=1596
song_1211:
	song_entry mid_1211_s_v_Dra_OK_08, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1211, id=1597
song_1212:
	song_entry mid_1212_s_v_Dra_OK_09, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1212, id=1598
song_1213:
	song_entry mid_1213_s_v_Dra_OK_10, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1213, id=1599
song_1214:
	song_entry mid_1214_s_v_Dra_OK_11, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1214, id=1600
song_1215:
	song_entry mid_1215_s_v_Dra_OK_12, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1215, id=1601
song_1216:
	song_entry mid_1216_s_v_Dra_OK_13, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1216, id=1602
song_1217:
	song_entry mid_1217_s_v_Dra_NG_01, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1217, id=1603
song_1218:
	song_entry mid_1218_s_v_Dra_NG_02, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1218, id=1604
song_1219:
	song_entry mid_1219_s_v_Dra_NG_03, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1219, id=1605
song_1220:
	song_entry mid_1220_s_v_Dra_NG_04, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1220, id=1606
song_1221:
	song_entry mid_1221_s_v_Dra_NG_05, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1221, id=1607
song_1222:
	song_entry mid_1222_s_v_Dra_NG_06, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1222, id=1608
song_1223:
	song_entry mid_1223_s_v_Dra_NG_07, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1223, id=1609
song_1224:
	song_entry mid_1224_s_v_Dra_NG_08, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1224, id=1610
song_1225:
	song_entry mid_1225_s_v_Dra_NG_09, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1225, id=1611
song_1226:
	song_entry mid_1226_s_v_Dra_NG_10, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1226, id=1612
song_1227:
	song_entry mid_1227_s_v_Dra_NG_11, bank=3, volume=80, priority=120, player=8, w8=0xFF, name=sname_1227, id=1613
song_1228:
	song_entry mid_1228_s_v_Loo_OK_01, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1228, id=1620
song_1229:
	song_entry mid_1229_s_v_Loo_OK_02, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1229, id=1621
song_1230:
	song_entry mid_1230_s_v_Loo_OK_03, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1230, id=1622
song_1231:
	song_entry mid_1231_s_v_Loo_OK_04, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1231, id=1623
song_1232:
	song_entry mid_1232_s_v_Loo_OK_05, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1232, id=1624
song_1233:
	song_entry mid_1233_s_v_Loo_OK_06, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1233, id=1625
song_1234:
	song_entry mid_1234_s_v_Loo_OK_07, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1234, id=1626
song_1235:
	song_entry mid_1235_s_v_Loo_OK_08, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1235, id=1627
song_1236:
	song_entry mid_1236_s_v_Loo_OK_09, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1236, id=1628
song_1237:
	song_entry mid_1237_s_v_Loo_OK_10, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1237, id=1629
song_1238:
	song_entry mid_1238_s_v_Loo_OK_11, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1238, id=1630
song_1239:
	song_entry mid_1239_s_v_Loo_OK_12, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1239, id=1631
song_1240:
	song_entry mid_1240_s_v_Loo_OK_13, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1240, id=1632
song_1241:
	song_entry mid_1241_s_v_Loo_OK_14, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1241, id=1633
song_1242:
	song_entry mid_1242_s_v_Loo_NG_01, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1242, id=1640
song_1243:
	song_entry mid_1243_s_v_Loo_NG_02, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1243, id=1641
song_1244:
	song_entry mid_1244_s_v_Loo_NG_03, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1244, id=1642
song_1245:
	song_entry mid_1245_s_v_Loo_NG_04, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1245, id=1643
song_1246:
	song_entry mid_1246_s_v_Loo_NG_05, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1246, id=1644
song_1247:
	song_entry mid_1247_s_v_Loo_NG_06, bank=3, volume=75, priority=120, player=7, w8=0xFF, name=sname_1247, id=1645
song_1248:
	song_entry mid_1248_s_v_Loo_NG_07, bank=3, volume=75, priority=120, player=7, w8=0xFF, name=sname_1248, id=1646
song_1249:
	song_entry mid_1249_s_v_Loo_NG_08, bank=3, volume=75, priority=120, player=7, w8=0xFF, name=sname_1249, id=1647
song_1250:
	song_entry mid_1250_s_v_Loo_NG_09, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1250, id=1648
song_1251:
	song_entry mid_1251_s_v_Loo_NG_10, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1251, id=1649
song_1252:
	song_entry mid_1252_s_v_Voya_OK_01, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1252, id=1651
song_1253:
	song_entry mid_1253_s_v_Voya_OK_02, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1253, id=1652
song_1254:
	song_entry mid_1254_s_v_Voya_OK_03, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1254, id=1653
song_1255:
	song_entry mid_1255_s_v_Voya_OK_04, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1255, id=1654
song_1256:
	song_entry mid_1256_s_v_Voya_OK_05, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1256, id=1655
song_1257:
	song_entry mid_1257_s_v_Voya_OK_06, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1257, id=1656
song_1258:
	song_entry mid_1258_s_v_Voya_OK_07, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1258, id=1657
song_1259:
	song_entry mid_1259_s_v_Voya_OK_08, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1259, id=1658
song_1260:
	song_entry mid_1260_s_v_Voya_OK_09, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1260, id=1659
song_1261:
	song_entry mid_1261_s_v_Voya_OK_10, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1261, id=1660
song_1262:
	song_entry mid_1262_s_v_Voya_NG_01, bank=3, volume=100, priority=120, player=7, w8=0xFF, name=sname_1262, id=1662
song_1263:
	song_entry mid_1263_s_v_Voya_NG_02, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1263, id=1663
song_1264:
	song_entry mid_1264_s_v_Voya_NG_03, bank=3, volume=100, priority=120, player=7, w8=0xFF, name=sname_1264, id=1664
song_1265:
	song_entry mid_1265_s_v_Voya_NG_04, bank=3, volume=100, priority=120, player=7, w8=0xFF, name=sname_1265, id=1665
song_1266:
	song_entry mid_1266_s_v_Voya_NG_05, bank=3, volume=100, priority=120, player=7, w8=0xFF, name=sname_1266, id=1666
song_1267:
	song_entry mid_1267_s_v_Voya_NG_06, bank=3, volume=100, priority=120, player=7, w8=0xFF, name=sname_1267, id=1667
song_1268:
	song_entry mid_1268_s_v_Bio_OK_01, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1268, id=1670
song_1269:
	song_entry mid_1269_s_v_Bio_OK_02, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1269, id=1671
song_1270:
	song_entry mid_1270_s_v_Bio_OK_03, bank=3, volume=55, priority=120, player=8, w8=0xFF, name=sname_1270, id=1672
song_1271:
	song_entry mid_1271_s_v_Bio_OK_04, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1271, id=1673
song_1272:
	song_entry mid_1272_s_v_Bio_OK_05, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1272, id=1674
song_1273:
	song_entry mid_1273_s_v_Bio_OK_06, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1273, id=1675
song_1274:
	song_entry mid_1274_s_v_Bio_OK_07, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1274, id=1676
song_1275:
	song_entry mid_1275_s_v_Bio_OK_08, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1275, id=1677
song_1276:
	song_entry mid_1276_s_v_Bio_OK_09, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1276, id=1678
song_1277:
	song_entry mid_1277_s_v_Bio_OK_10, bank=3, volume=55, priority=120, player=8, w8=0xFF, name=sname_1277, id=1679
song_1278:
	song_entry mid_1278_s_v_Bio_NG_01, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1278, id=1680
song_1279:
	song_entry mid_1279_s_v_Bio_NG_02, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1279, id=1681
song_1280:
	song_entry mid_1280_s_v_Bio_NG_03, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1280, id=1682
song_1281:
	song_entry mid_1281_s_v_Bio_NG_04, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1281, id=1683
song_1282:
	song_entry mid_1282_s_v_Bio_NG_05, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1282, id=1684
song_1283:
	song_entry mid_1283_s_v_Bio_NG_06, bank=3, volume=55, priority=120, player=8, w8=0xFF, name=sname_1283, id=1685
song_1284:
	song_entry mid_1284_s_v_Bio_NG_07, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1284, id=1686
song_1285:
	song_entry mid_1285_s_v_Bio_NG_08, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1285, id=1687
song_1286:
	song_entry mid_1286_s_v_Bio_NG_09, bank=3, volume=45, priority=120, player=8, w8=0xFF, name=sname_1286, id=1688
song_1287:
	song_entry mid_1287_s_v_Bio_NG_10, bank=3, volume=65, priority=120, player=8, w8=0xFF, name=sname_1287, id=1689
song_1288:
	song_entry mid_1288_s_v_Kaede_OK_01, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1288, id=1690
song_1289:
	song_entry mid_1289_s_v_Kaede_OK_02, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1289, id=1691
song_1290:
	song_entry mid_1290_s_v_Kaede_OK_03, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1290, id=1692
song_1291:
	song_entry mid_1291_s_v_Kaede_OK_04, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1291, id=1693
song_1292:
	song_entry mid_1292_s_v_Kaede_OK_05, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1292, id=1694
song_1293:
	song_entry mid_1293_s_v_Kaede_OK_06, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1293, id=1695
song_1294:
	song_entry mid_1294_s_v_Kaede_OK_07, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1294, id=1696
song_1295:
	song_entry mid_1295_s_v_Kaede_OK_08, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1295, id=1697
song_1296:
	song_entry mid_1296_s_v_Kaede_OK_09, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1296, id=1698
song_1297:
	song_entry mid_1297_s_v_Kaede_OK_10, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1297, id=1699
song_1298:
	song_entry mid_1298_s_v_Kaede_NG_01, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1298, id=1700
song_1299:
	song_entry mid_1299_s_v_Kaede_NG_02, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1299, id=1701
song_1300:
	song_entry mid_1300_s_v_Kaede_NG_03, bank=3, volume=80, priority=120, player=7, w8=0xFF, name=sname_1300, id=1702
song_1301:
	song_entry mid_1301_s_v_Kaede_NG_04, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1301, id=1703
song_1302:
	song_entry mid_1302_s_v_Kaede_NG_05, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1302, id=1704
song_1303:
	song_entry mid_1303_s_v_Kaede_NG_06, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1303, id=1705
song_1304:
	song_entry mid_1304_s_v_Kaede_NG_07, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1304, id=1706
song_1305:
	song_entry mid_1305_s_v_App_Select_A1, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1305, id=1810
song_1306:
	song_entry mid_1306_s_v_App_Select_A2, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1306, id=1811
song_1307:
	song_entry mid_1307_s_v_App_Select_A3, bank=3, volume=60, priority=120, player=3, w8=0xFF, name=sname_1307, id=1812
song_1308:
	song_entry mid_1308_s_v_App_Select_B1, bank=3, volume=80, priority=120, player=3, w8=0xFF, name=sname_1308, id=1813
song_1309:
	song_entry mid_1309_s_v_App_Select_B2, bank=3, volume=80, priority=120, player=3, w8=0xFF, name=sname_1309, id=1814
song_1310:
	song_entry mid_1310_s_v_App_Select_B3, bank=3, volume=80, priority=120, player=3, w8=0xFF, name=sname_1310, id=1815
song_1311:
	song_entry mid_1311_s_v_App_Select_C1, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1311, id=1816
song_1312:
	song_entry mid_1312_s_v_App_Select_C2, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1312, id=1817
song_1313:
	song_entry mid_1313_s_v_App_Select_C3, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1313, id=1818
song_1314:
	song_entry mid_1314_s_v_Dra_Select_1, bank=3, volume=65, priority=120, player=3, w8=0xFF, name=sname_1314, id=1819
song_1315:
	song_entry mid_1315_s_v_Dra_Select_2, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1315, id=1820
song_1316:
	song_entry mid_1316_s_v_Dra_Select_3, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1316, id=1821
song_1317:
	song_entry mid_1317_s_v_Monna_Select_1, bank=3, volume=50, priority=120, player=7, w8=0xFF, name=sname_1317, id=1822
song_1318:
	song_entry mid_1318_s_v_Monna_Select_2, bank=3, volume=60, priority=120, player=7, w8=0xFF, name=sname_1318, id=1823
song_1319:
	song_entry mid_1319_s_v_Monna_Select_3, bank=3, volume=60, priority=120, player=7, w8=0xFF, name=sname_1319, id=1824
song_1320:
	song_entry mid_1320_s_v_Voya_Select_1, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1320, id=1825
song_1321:
	song_entry mid_1321_s_v_Voya_Select_2, bank=3, volume=60, priority=120, player=3, w8=0xFF, name=sname_1321, id=1826
song_1322:
	song_entry mid_1322_s_v_Voya_Select_3, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1322, id=1827
song_1323:
	song_entry mid_1323_s_v_Bio_Select_1, bank=3, volume=60, priority=120, player=3, w8=0xFF, name=sname_1323, id=1828
song_1324:
	song_entry mid_1324_s_v_Bio_Select_2, bank=3, volume=60, priority=120, player=3, w8=0xFF, name=sname_1324, id=1829
song_1325:
	song_entry mid_1325_s_v_Bio_Select_3, bank=3, volume=70, priority=120, player=3, w8=0xFF, name=sname_1325, id=1830
song_1326:
	song_entry mid_1326_s_v_Loo_Select_1, bank=3, volume=90, priority=120, player=7, w8=0xFF, name=sname_1326, id=1831
song_1327:
	song_entry mid_1327_s_v_Loo_Select_2, bank=3, volume=70, priority=120, player=7, w8=0xFF, name=sname_1327, id=1832
song_1328:
	song_entry mid_1328_s_v_Loo_Select_3, bank=3, volume=70, priority=120, player=7, w8=0xFF, name=sname_1328, id=1833
song_1329:
	song_entry mid_1329_s_v_wario_Select_1, bank=3, volume=70, priority=120, player=7, w8=0xFF, name=sname_1329, id=1834
song_1330:
	song_entry mid_1330_s_v_wario_Select_2, bank=3, volume=70, priority=120, player=7, w8=0xFF, name=sname_1330, id=1835
song_1331:
	song_entry mid_1331_s_v_wario_Select_3, bank=3, volume=70, priority=120, player=7, w8=0xFF, name=sname_1331, id=1836
song_1332:
	song_entry mid_1332_s_v_Kaede_Select_1, bank=3, volume=90, priority=120, player=3, w8=0xFF, name=sname_1332, id=1837
song_1333:
	song_entry mid_1333_s_v_Kaede_Select_2, bank=3, volume=80, priority=120, player=3, w8=0xFF, name=sname_1333, id=1838
song_1334:
	song_entry mid_1334_s_v_Kaede_Select_3, bank=3, volume=60, priority=120, player=3, w8=0xFF, name=sname_1334, id=1839
song_1335:
	song_entry mid_1335_s_v_App_MAP_01, bank=3, volume=50, priority=100, player=1, w8=0xFF, name=sname_1335, id=1840
song_1336:
	song_entry mid_1336_s_v_Dra_MAP_01, bank=3, volume=60, priority=100, player=2, w8=0xFF, name=sname_1336, id=1841
song_1337:
	song_entry mid_1337_s_v_Monna_MAP_01, bank=3, volume=60, priority=100, player=3, w8=0xFF, name=sname_1337, id=1842
song_1338:
	song_entry mid_1338_s_v_Voya_MAP_01, bank=3, volume=40, priority=100, player=4, w8=0xFF, name=sname_1338, id=1843
song_1339:
	song_entry mid_1339_s_v_Bio_MAP_01, bank=3, volume=60, priority=100, player=5, w8=0xFF, name=sname_1339, id=1844
song_1340:
	song_entry mid_1340_s_v_Loo_MAP_01, bank=3, volume=60, priority=100, player=6, w8=0xFF, name=sname_1340, id=1845
song_1341:
	song_entry mid_1341_s_v_KAEDE_MAP_01, bank=3, volume=35, priority=100, player=7, w8=0xFF, name=sname_1341, id=1846

	.global sndSongPtrTable
sndSongPtrTable:   @ u32 maxId; SongEntry *[maxId + 1] (id -> entry); not read by the driver or the game code
	.word 1846
	.word song_0000                @ id 0
	.word song_0001                @ id 1
	.word song_0002                @ id 2
	.word song_0003                @ id 3
	.word song_0004                @ id 4
	.word song_0005                @ id 5
	.word song_0006                @ id 6
	.word song_0007                @ id 7
	.word song_0008                @ id 8
	.word song_0009                @ id 9
	.word song_0010                @ id 10
	.word song_0011                @ id 11
	.word song_0012                @ id 12
	.word song_0013                @ id 13
	.word song_0014                @ id 14
	.word song_0015                @ id 15
	.word song_0016                @ id 16
	.word song_0017                @ id 17
	.word song_0018                @ id 18
	.word song_0019                @ id 19
	.word song_0020                @ id 20
	.word song_0021                @ id 21
	.word song_0022                @ id 22
	.word song_0023                @ id 23
	.word song_0024                @ id 24
	.word song_0025                @ id 25
	.word song_0026                @ id 26
	.word song_0027                @ id 27
	.word song_0028                @ id 28
	.word song_0029                @ id 29
	.word song_0030                @ id 30
	.word song_0031                @ id 31
	.word song_0032                @ id 32
	.word song_0033                @ id 33
	.word song_0034                @ id 34
	.word song_0035                @ id 35
	.word song_0036                @ id 36
	.word song_0037                @ id 37
	.word song_0038                @ id 38
	.word song_0039                @ id 39
	.word song_0040                @ id 40
	.word song_0041                @ id 41
	.word song_0042                @ id 42
	.word song_0043                @ id 43
	.word song_0044                @ id 44
	.word song_0045                @ id 45
	.word song_0046                @ id 46
	.word song_0047                @ id 47
	.word song_0048                @ id 48
	.word song_0049                @ id 49
	.word 0                        @ id 50
	.word 0                        @ id 51
	.word 0                        @ id 52
	.word song_0050                @ id 53
	.word song_0051                @ id 54
	.word song_0052                @ id 55
	.word song_0053                @ id 56
	.word song_0054                @ id 57
	.word song_0055                @ id 58
	.word song_0056                @ id 59
	.word song_0057                @ id 60
	.word song_0058                @ id 61
	.word song_0059                @ id 62
	.word song_0060                @ id 63
	.word song_0061                @ id 64
	.word song_0062                @ id 65
	.word song_0063                @ id 66
	.word song_0064                @ id 67
	.word song_0065                @ id 68
	.word song_0066                @ id 69
	.word song_0067                @ id 70
	.word song_0068                @ id 71
	.word song_0069                @ id 72
	.word song_0070                @ id 73
	.word song_0071                @ id 74
	.word song_0072                @ id 75
	.word song_0073                @ id 76
	.word song_0074                @ id 77
	.word song_0075                @ id 78
	.word song_0076                @ id 79
	.word song_0077                @ id 80
	.word song_0078                @ id 81
	.word song_0079                @ id 82
	.word song_0080                @ id 83
	.word song_0081                @ id 84
	.word song_0082                @ id 85
	.word song_0083                @ id 86
	.word song_0084                @ id 87
	.word song_0085                @ id 88
	.word song_0086                @ id 89
	.word song_0087                @ id 90
	.word song_0088                @ id 91
	.word song_0089                @ id 92
	.word song_0090                @ id 93
	.word song_0091                @ id 94
	.word song_0092                @ id 95
	.word song_0093                @ id 96
	.word song_0094                @ id 97
	.word song_0095                @ id 98
	.word song_0096                @ id 99
	.word song_0097                @ id 100
	.word song_0098                @ id 101
	.word song_0099                @ id 102
	.word song_0100                @ id 103
	.word song_0101                @ id 104
	.word song_0102                @ id 105
	.word song_0103                @ id 106
	.word song_0104                @ id 107
	.word song_0105                @ id 108
	.word song_0106                @ id 109
	.word song_0107                @ id 110
	.word song_0108                @ id 111
	.word song_0109                @ id 112
	.word song_0110                @ id 113
	.word song_0111                @ id 114
	.word song_0112                @ id 115
	.word song_0113                @ id 116
	.word song_0114                @ id 117
	.word song_0115                @ id 118
	.word song_0116                @ id 119
	.word song_0117                @ id 120
	.word song_0118                @ id 121
	.word song_0119                @ id 122
	.word song_0120                @ id 123
	.word song_0121                @ id 124
	.word song_0122                @ id 125
	.word song_0123                @ id 126
	.word song_0124                @ id 127
	.word song_0125                @ id 128
	.word song_0126                @ id 129
	.word song_0127                @ id 130
	.word song_0128                @ id 131
	.word song_0129                @ id 132
	.word song_0130                @ id 133
	.word song_0131                @ id 134
	.word song_0132                @ id 135
	.word song_0133                @ id 136
	.word song_0134                @ id 137
	.word song_0135                @ id 138
	.word song_0136                @ id 139
	.word song_0137                @ id 140
	.word song_0138                @ id 141
	.word song_0139                @ id 142
	.word song_0140                @ id 143
	.word song_0141                @ id 144
	.word song_0142                @ id 145
	.word song_0143                @ id 146
	.word song_0144                @ id 147
	.word song_0145                @ id 148
	.word song_0146                @ id 149
	.word song_0147                @ id 150
	.word song_0148                @ id 151
	.word song_0149                @ id 152
	.word song_0150                @ id 153
	.word song_0151                @ id 154
	.word song_0152                @ id 155
	.word song_0153                @ id 156
	.word song_0154                @ id 157
	.word song_0155                @ id 158
	.word song_0156                @ id 159
	.word song_0157                @ id 160
	.word song_0158                @ id 161
	.word song_0159                @ id 162
	.word song_0160                @ id 163
	.word song_0161                @ id 164
	.word song_0162                @ id 165
	.word song_0163                @ id 166
	.word song_0164                @ id 167
	.word song_0165                @ id 168
	.word song_0166                @ id 169
	.word song_0167                @ id 170
	.word song_0168                @ id 171
	.word song_0169                @ id 172
	.word song_0170                @ id 173
	.word song_0171                @ id 174
	.word song_0172                @ id 175
	.word song_0173                @ id 176
	.word song_0174                @ id 177
	.word song_0175                @ id 178
	.word 0                        @ id 179
	.word song_0176                @ id 180
	.word song_0177                @ id 181
	.word song_0178                @ id 182
	.word song_0179                @ id 183
	.word song_0180                @ id 184
	.word song_0181                @ id 185
	.word song_0182                @ id 186
	.word song_0183                @ id 187
	.word song_0184                @ id 188
	.word song_0185                @ id 189
	.word song_0186                @ id 190
	.word song_0187                @ id 191
	.word song_0188                @ id 192
	.word song_0189                @ id 193
	.word song_0190                @ id 194
	.word song_0191                @ id 195
	.word song_0192                @ id 196
	.word song_0193                @ id 197
	.word song_0194                @ id 198
	.word song_0195                @ id 199
	.word song_0196                @ id 200
	.word song_0197                @ id 201
	.word song_0198                @ id 202
	.word song_0199                @ id 203
	.word song_0200                @ id 204
	.word song_0201                @ id 205
	.word song_0202                @ id 206
	.word song_0203                @ id 207
	.word song_0204                @ id 208
	.word song_0205                @ id 209
	.word song_0206                @ id 210
	.word song_0207                @ id 211
	.word song_0208                @ id 212
	.word song_0209                @ id 213
	.word song_0210                @ id 214
	.word song_0211                @ id 215
	.word song_0212                @ id 216
	.word song_0213                @ id 217
	.word song_0214                @ id 218
	.word song_0215                @ id 219
	.word song_0216                @ id 220
	.word song_0217                @ id 221
	.word song_0218                @ id 222
	.word song_0219                @ id 223
	.word song_0220                @ id 224
	.word song_0221                @ id 225
	.word song_0222                @ id 226
	.word song_0223                @ id 227
	.word song_0224                @ id 228
	.word song_0225                @ id 229
	.word song_0226                @ id 230
	.word song_0227                @ id 231
	.word song_0228                @ id 232
	.word song_0229                @ id 233
	.word song_0230                @ id 234
	.word song_0231                @ id 235
	.word song_0232                @ id 236
	.word song_0233                @ id 237
	.word song_0234                @ id 238
	.word song_0235                @ id 239
	.word song_0236                @ id 240
	.word song_0237                @ id 241
	.word song_0238                @ id 242
	.word song_0239                @ id 243
	.word song_0240                @ id 244
	.word song_0241                @ id 245
	.word song_0242                @ id 246
	.word song_0243                @ id 247
	.word song_0244                @ id 248
	.word song_0245                @ id 249
	.word song_0246                @ id 250
	.word song_0247                @ id 251
	.word song_0248                @ id 252
	.word song_0249                @ id 253
	.word song_0250                @ id 254
	.word song_0251                @ id 255
	.word song_0252                @ id 256
	.word song_0253                @ id 257
	.word song_0254                @ id 258
	.word song_0255                @ id 259
	.word song_0256                @ id 260
	.word song_0257                @ id 261
	.word song_0258                @ id 262
	.word song_0259                @ id 263
	.word song_0260                @ id 264
	.word song_0261                @ id 265
	.word song_0262                @ id 266
	.word song_0263                @ id 267
	.word song_0264                @ id 268
	.word song_0265                @ id 269
	.word song_0266                @ id 270
	.word song_0267                @ id 271
	.word song_0268                @ id 272
	.word song_0269                @ id 273
	.word song_0270                @ id 274
	.word song_0271                @ id 275
	.word song_0272                @ id 276
	.word song_0273                @ id 277
	.word song_0274                @ id 278
	.word song_0275                @ id 279
	.word song_0276                @ id 280
	.word song_0277                @ id 281
	.word song_0278                @ id 282
	.word song_0279                @ id 283
	.word song_0280                @ id 284
	.word song_0281                @ id 285
	.word song_0282                @ id 286
	.word song_0283                @ id 287
	.word song_0284                @ id 288
	.word song_0285                @ id 289
	.word song_0286                @ id 290
	.word song_0287                @ id 291
	.word song_0288                @ id 292
	.word song_0289                @ id 293
	.word song_0290                @ id 294
	.word song_0291                @ id 295
	.word song_0292                @ id 296
	.word song_0293                @ id 297
	.word song_0294                @ id 298
	.word song_0295                @ id 299
	.word song_0296                @ id 300
	.word song_0297                @ id 301
	.word song_0298                @ id 302
	.word song_0299                @ id 303
	.word song_0300                @ id 304
	.word song_0301                @ id 305
	.word song_0302                @ id 306
	.word song_0303                @ id 307
	.word song_0304                @ id 308
	.word song_0305                @ id 309
	.word song_0306                @ id 310
	.word song_0307                @ id 311
	.word song_0308                @ id 312
	.word song_0309                @ id 313
	.word song_0310                @ id 314
	.word song_0311                @ id 315
	.word song_0312                @ id 316
	.word song_0313                @ id 317
	.word song_0314                @ id 318
	.word song_0315                @ id 319
	.word song_0316                @ id 320
	.word song_0317                @ id 321
	.word song_0318                @ id 322
	.word song_0319                @ id 323
	.word song_0320                @ id 324
	.word song_0321                @ id 325
	.word song_0322                @ id 326
	.word song_0323                @ id 327
	.word song_0324                @ id 328
	.word song_0325                @ id 329
	.word song_0326                @ id 330
	.word song_0327                @ id 331
	.word song_0328                @ id 332
	.word song_0329                @ id 333
	.word song_0330                @ id 334
	.word song_0331                @ id 335
	.word song_0332                @ id 336
	.word song_0333                @ id 337
	.word song_0334                @ id 338
	.word song_0335                @ id 339
	.word song_0336                @ id 340
	.word song_0337                @ id 341
	.word song_0338                @ id 342
	.word song_0339                @ id 343
	.word song_0340                @ id 344
	.word song_0341                @ id 345
	.word song_0342                @ id 346
	.word song_0343                @ id 347
	.word song_0344                @ id 348
	.word song_0345                @ id 349
	.word song_0346                @ id 350
	.word song_0347                @ id 351
	.word song_0348                @ id 352
	.word song_0349                @ id 353
	.word song_0350                @ id 354
	.word song_0351                @ id 355
	.word song_0352                @ id 356
	.word song_0353                @ id 357
	.word song_0354                @ id 358
	.word song_0355                @ id 359
	.word song_0356                @ id 360
	.word song_0357                @ id 361
	.word song_0358                @ id 362
	.word song_0359                @ id 363
	.word song_0360                @ id 364
	.word song_0361                @ id 365
	.word song_0362                @ id 366
	.word song_0363                @ id 367
	.word song_0364                @ id 368
	.word song_0365                @ id 369
	.word song_0366                @ id 370
	.word song_0367                @ id 371
	.word song_0368                @ id 372
	.word 0                        @ id 373
	.word 0                        @ id 374
	.word 0                        @ id 375
	.word 0                        @ id 376
	.word 0                        @ id 377
	.word 0                        @ id 378
	.word 0                        @ id 379
	.word song_0369                @ id 380
	.word song_0370                @ id 381
	.word song_0371                @ id 382
	.word song_0372                @ id 383
	.word song_0373                @ id 384
	.word song_0374                @ id 385
	.word song_0375                @ id 386
	.word song_0376                @ id 387
	.word song_0377                @ id 388
	.word song_0378                @ id 389
	.word song_0379                @ id 390
	.word song_0380                @ id 391
	.word 0                        @ id 392
	.word 0                        @ id 393
	.word 0                        @ id 394
	.word 0                        @ id 395
	.word 0                        @ id 396
	.word 0                        @ id 397
	.word 0                        @ id 398
	.word 0                        @ id 399
	.word song_0381                @ id 400
	.word song_0382                @ id 401
	.word song_0383                @ id 402
	.word song_0384                @ id 403
	.word song_0385                @ id 404
	.word song_0386                @ id 405
	.word song_0387                @ id 406
	.word song_0388                @ id 407
	.word song_0389                @ id 408
	.word song_0390                @ id 409
	.word song_0391                @ id 410
	.word song_0392                @ id 411
	.word song_0393                @ id 412
	.word song_0394                @ id 413
	.word song_0395                @ id 414
	.word song_0396                @ id 415
	.word song_0397                @ id 416
	.word song_0398                @ id 417
	.word song_0399                @ id 418
	.word song_0400                @ id 419
	.word song_0401                @ id 420
	.word song_0402                @ id 421
	.word song_0403                @ id 422
	.word song_0404                @ id 423
	.word song_0405                @ id 424
	.word song_0406                @ id 425
	.word song_0407                @ id 426
	.word song_0408                @ id 427
	.word song_0409                @ id 428
	.word song_0410                @ id 429
	.word song_0411                @ id 430
	.word song_0412                @ id 431
	.word song_0413                @ id 432
	.word song_0414                @ id 433
	.word song_0415                @ id 434
	.word song_0416                @ id 435
	.word song_0417                @ id 436
	.word song_0418                @ id 437
	.word song_0419                @ id 438
	.word song_0420                @ id 439
	.word song_0421                @ id 440
	.word song_0422                @ id 441
	.word song_0423                @ id 442
	.word song_0424                @ id 443
	.word song_0425                @ id 444
	.word song_0426                @ id 445
	.word song_0427                @ id 446
	.word song_0428                @ id 447
	.word song_0429                @ id 448
	.word song_0430                @ id 449
	.word song_0431                @ id 450
	.word song_0432                @ id 451
	.word song_0433                @ id 452
	.word song_0434                @ id 453
	.word song_0435                @ id 454
	.word song_0436                @ id 455
	.word song_0437                @ id 456
	.word song_0438                @ id 457
	.word song_0439                @ id 458
	.word song_0440                @ id 459
	.word song_0441                @ id 460
	.word song_0442                @ id 461
	.word song_0443                @ id 462
	.word song_0444                @ id 463
	.word song_0445                @ id 464
	.word song_0446                @ id 465
	.word 0                        @ id 466
	.word 0                        @ id 467
	.word 0                        @ id 468
	.word 0                        @ id 469
	.word 0                        @ id 470
	.word 0                        @ id 471
	.word 0                        @ id 472
	.word 0                        @ id 473
	.word 0                        @ id 474
	.word 0                        @ id 475
	.word 0                        @ id 476
	.word 0                        @ id 477
	.word 0                        @ id 478
	.word 0                        @ id 479
	.word 0                        @ id 480
	.word song_0447                @ id 481
	.word song_0448                @ id 482
	.word song_0449                @ id 483
	.word song_0450                @ id 484
	.word song_0451                @ id 485
	.word song_0452                @ id 486
	.word song_0453                @ id 487
	.word song_0454                @ id 488
	.word song_0455                @ id 489
	.word song_0456                @ id 490
	.word song_0457                @ id 491
	.word song_0458                @ id 492
	.word song_0459                @ id 493
	.word song_0460                @ id 494
	.word song_0461                @ id 495
	.word song_0462                @ id 496
	.word 0                        @ id 497
	.word song_0463                @ id 498
	.word 0                        @ id 499
	.word song_0464                @ id 500
	.word song_0465                @ id 501
	.word song_0466                @ id 502
	.word song_0467                @ id 503
	.word song_0468                @ id 504
	.word song_0469                @ id 505
	.word song_0470                @ id 506
	.word song_0471                @ id 507
	.word song_0472                @ id 508
	.word song_0473                @ id 509
	.word song_0474                @ id 510
	.word song_0475                @ id 511
	.word song_0476                @ id 512
	.word song_0477                @ id 513
	.word song_0478                @ id 514
	.word song_0479                @ id 515
	.word song_0480                @ id 516
	.word song_0481                @ id 517
	.word song_0482                @ id 518
	.word song_0483                @ id 519
	.word song_0484                @ id 520
	.word song_0485                @ id 521
	.word song_0486                @ id 522
	.word song_0487                @ id 523
	.word song_0488                @ id 524
	.word song_0489                @ id 525
	.word song_0490                @ id 526
	.word song_0491                @ id 527
	.word 0                        @ id 528
	.word 0                        @ id 529
	.word 0                        @ id 530
	.word song_0492                @ id 531
	.word song_0493                @ id 532
	.word song_0494                @ id 533
	.word song_0495                @ id 534
	.word song_0496                @ id 535
	.word song_0497                @ id 536
	.word song_0498                @ id 537
	.word song_0499                @ id 538
	.word song_0500                @ id 539
	.word song_0501                @ id 540
	.word song_0502                @ id 541
	.word song_0503                @ id 542
	.word song_0504                @ id 543
	.word song_0505                @ id 544
	.word song_0506                @ id 545
	.word song_0507                @ id 546
	.word song_0508                @ id 547
	.word song_0509                @ id 548
	.word song_0510                @ id 549
	.word song_0511                @ id 550
	.word song_0512                @ id 551
	.word song_0513                @ id 552
	.word song_0514                @ id 553
	.word song_0515                @ id 554
	.word song_0516                @ id 555
	.word song_0517                @ id 556
	.word song_0518                @ id 557
	.word song_0519                @ id 558
	.word song_0520                @ id 559
	.word song_0521                @ id 560
	.word song_0522                @ id 561
	.word song_0523                @ id 562
	.word 0                        @ id 563
	.word song_0524                @ id 564
	.word song_0525                @ id 565
	.word song_0526                @ id 566
	.word song_0527                @ id 567
	.word song_0528                @ id 568
	.word song_0529                @ id 569
	.word song_0530                @ id 570
	.word song_0531                @ id 571
	.word song_0532                @ id 572
	.word song_0533                @ id 573
	.word song_0534                @ id 574
	.word song_0535                @ id 575
	.word song_0536                @ id 576
	.word song_0537                @ id 577
	.word song_0538                @ id 578
	.word 0                        @ id 579
	.word 0                        @ id 580
	.word 0                        @ id 581
	.word 0                        @ id 582
	.word 0                        @ id 583
	.word 0                        @ id 584
	.word 0                        @ id 585
	.word song_0539                @ id 586
	.word song_0540                @ id 587
	.word song_0541                @ id 588
	.word song_0542                @ id 589
	.word song_0543                @ id 590
	.word song_0544                @ id 591
	.word song_0545                @ id 592
	.word song_0546                @ id 593
	.word song_0547                @ id 594
	.word song_0548                @ id 595
	.word song_0549                @ id 596
	.word song_0550                @ id 597
	.word song_0551                @ id 598
	.word song_0552                @ id 599
	.word song_0553                @ id 600
	.word song_0554                @ id 601
	.word 0                        @ id 602
	.word 0                        @ id 603
	.word 0                        @ id 604
	.word 0                        @ id 605
	.word 0                        @ id 606
	.word 0                        @ id 607
	.word 0                        @ id 608
	.word 0                        @ id 609
	.word 0                        @ id 610
	.word song_0555                @ id 611
	.word song_0556                @ id 612
	.word song_0557                @ id 613
	.word song_0558                @ id 614
	.word song_0559                @ id 615
	.word song_0560                @ id 616
	.word song_0561                @ id 617
	.word song_0562                @ id 618
	.word song_0563                @ id 619
	.word song_0564                @ id 620
	.word song_0565                @ id 621
	.word song_0566                @ id 622
	.word song_0567                @ id 623
	.word song_0568                @ id 624
	.word song_0569                @ id 625
	.word 0                        @ id 626
	.word 0                        @ id 627
	.word 0                        @ id 628
	.word 0                        @ id 629
	.word song_0570                @ id 630
	.word song_0571                @ id 631
	.word 0                        @ id 632
	.word 0                        @ id 633
	.word 0                        @ id 634
	.word song_0572                @ id 635
	.word song_0573                @ id 636
	.word song_0574                @ id 637
	.word song_0575                @ id 638
	.word song_0576                @ id 639
	.word song_0577                @ id 640
	.word song_0578                @ id 641
	.word song_0579                @ id 642
	.word song_0580                @ id 643
	.word song_0581                @ id 644
	.word song_0582                @ id 645
	.word song_0583                @ id 646
	.word song_0584                @ id 647
	.word song_0585                @ id 648
	.word song_0586                @ id 649
	.word 0                        @ id 650
	.word song_0587                @ id 651
	.word song_0588                @ id 652
	.word song_0589                @ id 653
	.word song_0590                @ id 654
	.word song_0591                @ id 655
	.word song_0592                @ id 656
	.word song_0593                @ id 657
	.word song_0594                @ id 658
	.word song_0595                @ id 659
	.word song_0596                @ id 660
	.word song_0597                @ id 661
	.word song_0598                @ id 662
	.word song_0599                @ id 663
	.word song_0600                @ id 664
	.word song_0601                @ id 665
	.word song_0602                @ id 666
	.word 0                        @ id 667
	.word 0                        @ id 668
	.word 0                        @ id 669
	.word song_0603                @ id 670
	.word song_0604                @ id 671
	.word 0                        @ id 672
	.word 0                        @ id 673
	.word 0                        @ id 674
	.word song_0605                @ id 675
	.word song_0606                @ id 676
	.word song_0607                @ id 677
	.word song_0608                @ id 678
	.word song_0609                @ id 679
	.word song_0610                @ id 680
	.word song_0611                @ id 681
	.word song_0612                @ id 682
	.word song_0613                @ id 683
	.word song_0614                @ id 684
	.word song_0615                @ id 685
	.word song_0616                @ id 686
	.word song_0617                @ id 687
	.word song_0618                @ id 688
	.word song_0619                @ id 689
	.word song_0620                @ id 690
	.word song_0621                @ id 691
	.word song_0622                @ id 692
	.word song_0623                @ id 693
	.word song_0624                @ id 694
	.word song_0625                @ id 695
	.word song_0626                @ id 696
	.word song_0627                @ id 697
	.word song_0628                @ id 698
	.word 0                        @ id 699
	.word song_0629                @ id 700
	.word song_0630                @ id 701
	.word song_0631                @ id 702
	.word song_0632                @ id 703
	.word song_0633                @ id 704
	.word song_0634                @ id 705
	.word 0                        @ id 706
	.word 0                        @ id 707
	.word 0                        @ id 708
	.word 0                        @ id 709
	.word song_0635                @ id 710
	.word 0                        @ id 711
	.word 0                        @ id 712
	.word 0                        @ id 713
	.word 0                        @ id 714
	.word song_0636                @ id 715
	.word song_0637                @ id 716
	.word song_0638                @ id 717
	.word song_0639                @ id 718
	.word 0                        @ id 719
	.word song_0640                @ id 720
	.word song_0641                @ id 721
	.word song_0642                @ id 722
	.word song_0643                @ id 723
	.word song_0644                @ id 724
	.word song_0645                @ id 725
	.word song_0646                @ id 726
	.word song_0647                @ id 727
	.word 0                        @ id 728
	.word 0                        @ id 729
	.word song_0648                @ id 730
	.word song_0649                @ id 731
	.word song_0650                @ id 732
	.word song_0651                @ id 733
	.word song_0652                @ id 734
	.word song_0653                @ id 735
	.word song_0654                @ id 736
	.word song_0655                @ id 737
	.word song_0656                @ id 738
	.word song_0657                @ id 739
	.word 0                        @ id 740
	.word song_0658                @ id 741
	.word song_0659                @ id 742
	.word song_0660                @ id 743
	.word 0                        @ id 744
	.word 0                        @ id 745
	.word song_0661                @ id 746
	.word song_0662                @ id 747
	.word song_0663                @ id 748
	.word song_0664                @ id 749
	.word song_0665                @ id 750
	.word song_0666                @ id 751
	.word song_0667                @ id 752
	.word song_0668                @ id 753
	.word song_0669                @ id 754
	.word song_0670                @ id 755
	.word song_0671                @ id 756
	.word song_0672                @ id 757
	.word song_0673                @ id 758
	.word song_0674                @ id 759
	.word song_0675                @ id 760
	.word song_0676                @ id 761
	.word song_0677                @ id 762
	.word song_0678                @ id 763
	.word song_0679                @ id 764
	.word song_0680                @ id 765
	.word song_0681                @ id 766
	.word song_0682                @ id 767
	.word song_0683                @ id 768
	.word song_0684                @ id 769
	.word song_0685                @ id 770
	.word song_0686                @ id 771
	.word song_0687                @ id 772
	.word song_0688                @ id 773
	.word song_0689                @ id 774
	.word song_0690                @ id 775
	.word song_0691                @ id 776
	.word song_0692                @ id 777
	.word song_0693                @ id 778
	.word song_0694                @ id 779
	.word song_0695                @ id 780
	.word song_0696                @ id 781
	.word song_0697                @ id 782
	.word song_0698                @ id 783
	.word song_0699                @ id 784
	.word song_0700                @ id 785
	.word song_0701                @ id 786
	.word song_0702                @ id 787
	.word song_0703                @ id 788
	.word song_0704                @ id 789
	.word song_0705                @ id 790
	.word song_0706                @ id 791
	.word song_0707                @ id 792
	.word 0                        @ id 793
	.word song_0708                @ id 794
	.word song_0709                @ id 795
	.word song_0710                @ id 796
	.word song_0711                @ id 797
	.word song_0712                @ id 798
	.word song_0713                @ id 799
	.word song_0714                @ id 800
	.word song_0715                @ id 801
	.word song_0716                @ id 802
	.word song_0717                @ id 803
	.word song_0718                @ id 804
	.word song_0719                @ id 805
	.word song_0720                @ id 806
	.word song_0721                @ id 807
	.word song_0722                @ id 808
	.word song_0723                @ id 809
	.word song_0724                @ id 810
	.word song_0725                @ id 811
	.word song_0726                @ id 812
	.word song_0727                @ id 813
	.word song_0728                @ id 814
	.word song_0729                @ id 815
	.word song_0730                @ id 816
	.word song_0731                @ id 817
	.word song_0732                @ id 818
	.word song_0733                @ id 819
	.word song_0734                @ id 820
	.word song_0735                @ id 821
	.word song_0736                @ id 822
	.word song_0737                @ id 823
	.word song_0738                @ id 824
	.word song_0739                @ id 825
	.word song_0740                @ id 826
	.word song_0741                @ id 827
	.word song_0742                @ id 828
	.word song_0743                @ id 829
	.word song_0744                @ id 830
	.word song_0745                @ id 831
	.word song_0746                @ id 832
	.word song_0747                @ id 833
	.word song_0748                @ id 834
	.word song_0749                @ id 835
	.word 0                        @ id 836
	.word song_0750                @ id 837
	.word song_0751                @ id 838
	.word song_0752                @ id 839
	.word song_0753                @ id 840
	.word song_0754                @ id 841
	.word song_0755                @ id 842
	.word song_0756                @ id 843
	.word song_0757                @ id 844
	.word song_0758                @ id 845
	.word song_0759                @ id 846
	.word song_0760                @ id 847
	.word song_0761                @ id 848
	.word song_0762                @ id 849
	.word song_0763                @ id 850
	.word song_0764                @ id 851
	.word song_0765                @ id 852
	.word song_0766                @ id 853
	.word song_0767                @ id 854
	.word song_0768                @ id 855
	.word song_0769                @ id 856
	.word song_0770                @ id 857
	.word song_0771                @ id 858
	.word song_0772                @ id 859
	.word song_0773                @ id 860
	.word song_0774                @ id 861
	.word song_0775                @ id 862
	.word song_0776                @ id 863
	.word song_0777                @ id 864
	.word song_0778                @ id 865
	.word song_0779                @ id 866
	.word song_0780                @ id 867
	.word song_0781                @ id 868
	.word song_0782                @ id 869
	.word song_0783                @ id 870
	.word song_0784                @ id 871
	.word song_0785                @ id 872
	.word 0                        @ id 873
	.word 0                        @ id 874
	.word 0                        @ id 875
	.word 0                        @ id 876
	.word 0                        @ id 877
	.word 0                        @ id 878
	.word 0                        @ id 879
	.word 0                        @ id 880
	.word 0                        @ id 881
	.word 0                        @ id 882
	.word 0                        @ id 883
	.word song_0786                @ id 884
	.word song_0787                @ id 885
	.word song_0788                @ id 886
	.word song_0789                @ id 887
	.word song_0790                @ id 888
	.word song_0791                @ id 889
	.word song_0792                @ id 890
	.word song_0793                @ id 891
	.word song_0794                @ id 892
	.word song_0795                @ id 893
	.word song_0796                @ id 894
	.word song_0797                @ id 895
	.word song_0798                @ id 896
	.word song_0799                @ id 897
	.word song_0800                @ id 898
	.word song_0801                @ id 899
	.word song_0802                @ id 900
	.word song_0803                @ id 901
	.word song_0804                @ id 902
	.word song_0805                @ id 903
	.word 0                        @ id 904
	.word 0                        @ id 905
	.word 0                        @ id 906
	.word 0                        @ id 907
	.word 0                        @ id 908
	.word 0                        @ id 909
	.word 0                        @ id 910
	.word song_0806                @ id 911
	.word song_0807                @ id 912
	.word song_0808                @ id 913
	.word song_0809                @ id 914
	.word song_0810                @ id 915
	.word song_0811                @ id 916
	.word song_0812                @ id 917
	.word song_0813                @ id 918
	.word song_0814                @ id 919
	.word song_0815                @ id 920
	.word song_0816                @ id 921
	.word 0                        @ id 922
	.word 0                        @ id 923
	.word 0                        @ id 924
	.word 0                        @ id 925
	.word 0                        @ id 926
	.word 0                        @ id 927
	.word 0                        @ id 928
	.word 0                        @ id 929
	.word song_0817                @ id 930
	.word song_0818                @ id 931
	.word song_0819                @ id 932
	.word 0                        @ id 933
	.word 0                        @ id 934
	.word 0                        @ id 935
	.word 0                        @ id 936
	.word 0                        @ id 937
	.word 0                        @ id 938
	.word 0                        @ id 939
	.word song_0820                @ id 940
	.word song_0821                @ id 941
	.word song_0822                @ id 942
	.word 0                        @ id 943
	.word 0                        @ id 944
	.word 0                        @ id 945
	.word 0                        @ id 946
	.word 0                        @ id 947
	.word 0                        @ id 948
	.word 0                        @ id 949
	.word song_0823                @ id 950
	.word song_0824                @ id 951
	.word song_0825                @ id 952
	.word song_0826                @ id 953
	.word song_0827                @ id 954
	.word song_0828                @ id 955
	.word song_0829                @ id 956
	.word song_0830                @ id 957
	.word song_0831                @ id 958
	.word 0                        @ id 959
	.word song_0832                @ id 960
	.word song_0833                @ id 961
	.word song_0834                @ id 962
	.word song_0835                @ id 963
	.word song_0836                @ id 964
	.word 0                        @ id 965
	.word 0                        @ id 966
	.word 0                        @ id 967
	.word 0                        @ id 968
	.word 0                        @ id 969
	.word song_0837                @ id 970
	.word song_0838                @ id 971
	.word song_0839                @ id 972
	.word song_0840                @ id 973
	.word song_0841                @ id 974
	.word song_0842                @ id 975
	.word song_0843                @ id 976
	.word song_0844                @ id 977
	.word song_0845                @ id 978
	.word song_0846                @ id 979
	.word song_0847                @ id 980
	.word song_0848                @ id 981
	.word song_0849                @ id 982
	.word song_0850                @ id 983
	.word song_0851                @ id 984
	.word song_0852                @ id 985
	.word song_0853                @ id 986
	.word song_0854                @ id 987
	.word song_0855                @ id 988
	.word 0                        @ id 989
	.word song_0856                @ id 990
	.word song_0857                @ id 991
	.word song_0858                @ id 992
	.word song_0859                @ id 993
	.word song_0860                @ id 994
	.word song_0861                @ id 995
	.word song_0862                @ id 996
	.word song_0863                @ id 997
	.word 0                        @ id 998
	.word song_0864                @ id 999
	.word 0                        @ id 1000
	.word song_0865                @ id 1001
	.word song_0866                @ id 1002
	.word song_0867                @ id 1003
	.word song_0868                @ id 1004
	.word song_0869                @ id 1005
	.word song_0870                @ id 1006
	.word song_0871                @ id 1007
	.word song_0872                @ id 1008
	.word song_0873                @ id 1009
	.word song_0874                @ id 1010
	.word song_0875                @ id 1011
	.word song_0876                @ id 1012
	.word song_0877                @ id 1013
	.word song_0878                @ id 1014
	.word song_0879                @ id 1015
	.word song_0880                @ id 1016
	.word song_0881                @ id 1017
	.word song_0882                @ id 1018
	.word song_0883                @ id 1019
	.word song_0884                @ id 1020
	.word song_0885                @ id 1021
	.word song_0886                @ id 1022
	.word song_0887                @ id 1023
	.word song_0888                @ id 1024
	.word song_0889                @ id 1025
	.word song_0890                @ id 1026
	.word song_0891                @ id 1027
	.word song_0892                @ id 1028
	.word song_0893                @ id 1029
	.word song_0894                @ id 1030
	.word song_0895                @ id 1031
	.word song_0896                @ id 1032
	.word song_0897                @ id 1033
	.word song_0898                @ id 1034
	.word song_0899                @ id 1035
	.word song_0900                @ id 1036
	.word song_0901                @ id 1037
	.word song_0902                @ id 1038
	.word song_0903                @ id 1039
	.word song_0904                @ id 1040
	.word song_0905                @ id 1041
	.word song_0906                @ id 1042
	.word song_0907                @ id 1043
	.word song_0908                @ id 1044
	.word song_0909                @ id 1045
	.word song_0910                @ id 1046
	.word song_0911                @ id 1047
	.word song_0912                @ id 1048
	.word song_0913                @ id 1049
	.word song_0914                @ id 1050
	.word song_0915                @ id 1051
	.word 0                        @ id 1052
	.word song_0916                @ id 1053
	.word song_0917                @ id 1054
	.word song_0918                @ id 1055
	.word song_0919                @ id 1056
	.word song_0920                @ id 1057
	.word song_0921                @ id 1058
	.word song_0922                @ id 1059
	.word song_0923                @ id 1060
	.word song_0924                @ id 1061
	.word song_0925                @ id 1062
	.word song_0926                @ id 1063
	.word song_0927                @ id 1064
	.word song_0928                @ id 1065
	.word song_0929                @ id 1066
	.word song_0930                @ id 1067
	.word song_0931                @ id 1068
	.word song_0932                @ id 1069
	.word song_0933                @ id 1070
	.word song_0934                @ id 1071
	.word song_0935                @ id 1072
	.word song_0936                @ id 1073
	.word song_0937                @ id 1074
	.word song_0938                @ id 1075
	.word song_0939                @ id 1076
	.word song_0940                @ id 1077
	.word song_0941                @ id 1078
	.word song_0942                @ id 1079
	.word song_0943                @ id 1080
	.word song_0944                @ id 1081
	.word song_0945                @ id 1082
	.word song_0946                @ id 1083
	.word song_0947                @ id 1084
	.word song_0948                @ id 1085
	.word song_0949                @ id 1086
	.word song_0950                @ id 1087
	.word song_0951                @ id 1088
	.word song_0952                @ id 1089
	.word song_0953                @ id 1090
	.word song_0954                @ id 1091
	.word song_0955                @ id 1092
	.word song_0956                @ id 1093
	.word song_0957                @ id 1094
	.word song_0958                @ id 1095
	.word song_0959                @ id 1096
	.word song_0960                @ id 1097
	.word song_0961                @ id 1098
	.word song_0962                @ id 1099
	.word song_0963                @ id 1100
	.word song_0964                @ id 1101
	.word song_0965                @ id 1102
	.word song_0966                @ id 1103
	.word song_0967                @ id 1104
	.word song_0968                @ id 1105
	.word song_0969                @ id 1106
	.word 0                        @ id 1107
	.word 0                        @ id 1108
	.word 0                        @ id 1109
	.word 0                        @ id 1110
	.word 0                        @ id 1111
	.word 0                        @ id 1112
	.word 0                        @ id 1113
	.word 0                        @ id 1114
	.word 0                        @ id 1115
	.word 0                        @ id 1116
	.word song_0970                @ id 1117
	.word song_0971                @ id 1118
	.word song_0972                @ id 1119
	.word song_0973                @ id 1120
	.word song_0974                @ id 1121
	.word song_0975                @ id 1122
	.word song_0976                @ id 1123
	.word song_0977                @ id 1124
	.word song_0978                @ id 1125
	.word song_0979                @ id 1126
	.word song_0980                @ id 1127
	.word song_0981                @ id 1128
	.word song_0982                @ id 1129
	.word song_0983                @ id 1130
	.word song_0984                @ id 1131
	.word song_0985                @ id 1132
	.word song_0986                @ id 1133
	.word song_0987                @ id 1134
	.word song_0988                @ id 1135
	.word song_0989                @ id 1136
	.word song_0990                @ id 1137
	.word song_0991                @ id 1138
	.word song_0992                @ id 1139
	.word song_0993                @ id 1140
	.word song_0994                @ id 1141
	.word song_0995                @ id 1142
	.word song_0996                @ id 1143
	.word song_0997                @ id 1144
	.word 0                        @ id 1145
	.word song_0998                @ id 1146
	.word song_0999                @ id 1147
	.word song_1000                @ id 1148
	.word 0                        @ id 1149
	.word 0                        @ id 1150
	.word 0                        @ id 1151
	.word 0                        @ id 1152
	.word 0                        @ id 1153
	.word 0                        @ id 1154
	.word 0                        @ id 1155
	.word 0                        @ id 1156
	.word 0                        @ id 1157
	.word 0                        @ id 1158
	.word 0                        @ id 1159
	.word 0                        @ id 1160
	.word 0                        @ id 1161
	.word 0                        @ id 1162
	.word 0                        @ id 1163
	.word 0                        @ id 1164
	.word 0                        @ id 1165
	.word 0                        @ id 1166
	.word 0                        @ id 1167
	.word 0                        @ id 1168
	.word 0                        @ id 1169
	.word 0                        @ id 1170
	.word 0                        @ id 1171
	.word 0                        @ id 1172
	.word 0                        @ id 1173
	.word 0                        @ id 1174
	.word 0                        @ id 1175
	.word 0                        @ id 1176
	.word 0                        @ id 1177
	.word 0                        @ id 1178
	.word 0                        @ id 1179
	.word 0                        @ id 1180
	.word 0                        @ id 1181
	.word 0                        @ id 1182
	.word 0                        @ id 1183
	.word 0                        @ id 1184
	.word 0                        @ id 1185
	.word 0                        @ id 1186
	.word 0                        @ id 1187
	.word 0                        @ id 1188
	.word 0                        @ id 1189
	.word 0                        @ id 1190
	.word 0                        @ id 1191
	.word 0                        @ id 1192
	.word 0                        @ id 1193
	.word 0                        @ id 1194
	.word 0                        @ id 1195
	.word 0                        @ id 1196
	.word 0                        @ id 1197
	.word 0                        @ id 1198
	.word 0                        @ id 1199
	.word 0                        @ id 1200
	.word 0                        @ id 1201
	.word 0                        @ id 1202
	.word 0                        @ id 1203
	.word 0                        @ id 1204
	.word 0                        @ id 1205
	.word 0                        @ id 1206
	.word 0                        @ id 1207
	.word 0                        @ id 1208
	.word 0                        @ id 1209
	.word 0                        @ id 1210
	.word 0                        @ id 1211
	.word 0                        @ id 1212
	.word 0                        @ id 1213
	.word 0                        @ id 1214
	.word 0                        @ id 1215
	.word 0                        @ id 1216
	.word 0                        @ id 1217
	.word 0                        @ id 1218
	.word 0                        @ id 1219
	.word 0                        @ id 1220
	.word 0                        @ id 1221
	.word 0                        @ id 1222
	.word 0                        @ id 1223
	.word 0                        @ id 1224
	.word 0                        @ id 1225
	.word 0                        @ id 1226
	.word 0                        @ id 1227
	.word 0                        @ id 1228
	.word 0                        @ id 1229
	.word 0                        @ id 1230
	.word 0                        @ id 1231
	.word 0                        @ id 1232
	.word 0                        @ id 1233
	.word 0                        @ id 1234
	.word 0                        @ id 1235
	.word 0                        @ id 1236
	.word 0                        @ id 1237
	.word 0                        @ id 1238
	.word 0                        @ id 1239
	.word 0                        @ id 1240
	.word 0                        @ id 1241
	.word 0                        @ id 1242
	.word 0                        @ id 1243
	.word 0                        @ id 1244
	.word 0                        @ id 1245
	.word 0                        @ id 1246
	.word 0                        @ id 1247
	.word 0                        @ id 1248
	.word song_1001                @ id 1249
	.word song_1002                @ id 1250
	.word song_1003                @ id 1251
	.word song_1004                @ id 1252
	.word song_1005                @ id 1253
	.word song_1006                @ id 1254
	.word song_1007                @ id 1255
	.word song_1008                @ id 1256
	.word song_1009                @ id 1257
	.word song_1010                @ id 1258
	.word song_1011                @ id 1259
	.word song_1012                @ id 1260
	.word song_1013                @ id 1261
	.word song_1014                @ id 1262
	.word 0                        @ id 1263
	.word 0                        @ id 1264
	.word 0                        @ id 1265
	.word 0                        @ id 1266
	.word 0                        @ id 1267
	.word 0                        @ id 1268
	.word 0                        @ id 1269
	.word 0                        @ id 1270
	.word 0                        @ id 1271
	.word 0                        @ id 1272
	.word 0                        @ id 1273
	.word 0                        @ id 1274
	.word 0                        @ id 1275
	.word 0                        @ id 1276
	.word 0                        @ id 1277
	.word 0                        @ id 1278
	.word 0                        @ id 1279
	.word 0                        @ id 1280
	.word 0                        @ id 1281
	.word 0                        @ id 1282
	.word 0                        @ id 1283
	.word 0                        @ id 1284
	.word 0                        @ id 1285
	.word 0                        @ id 1286
	.word 0                        @ id 1287
	.word 0                        @ id 1288
	.word 0                        @ id 1289
	.word 0                        @ id 1290
	.word 0                        @ id 1291
	.word 0                        @ id 1292
	.word 0                        @ id 1293
	.word 0                        @ id 1294
	.word 0                        @ id 1295
	.word song_1015                @ id 1296
	.word song_1016                @ id 1297
	.word song_1017                @ id 1298
	.word song_1018                @ id 1299
	.word song_1019                @ id 1300
	.word song_1020                @ id 1301
	.word song_1021                @ id 1302
	.word song_1022                @ id 1303
	.word song_1023                @ id 1304
	.word song_1024                @ id 1305
	.word song_1025                @ id 1306
	.word song_1026                @ id 1307
	.word song_1027                @ id 1308
	.word song_1028                @ id 1309
	.word song_1029                @ id 1310
	.word song_1030                @ id 1311
	.word song_1031                @ id 1312
	.word song_1032                @ id 1313
	.word song_1033                @ id 1314
	.word song_1034                @ id 1315
	.word song_1035                @ id 1316
	.word song_1036                @ id 1317
	.word song_1037                @ id 1318
	.word song_1038                @ id 1319
	.word song_1039                @ id 1320
	.word song_1040                @ id 1321
	.word song_1041                @ id 1322
	.word song_1042                @ id 1323
	.word song_1043                @ id 1324
	.word song_1044                @ id 1325
	.word song_1045                @ id 1326
	.word song_1046                @ id 1327
	.word song_1047                @ id 1328
	.word song_1048                @ id 1329
	.word song_1049                @ id 1330
	.word song_1050                @ id 1331
	.word song_1051                @ id 1332
	.word song_1052                @ id 1333
	.word song_1053                @ id 1334
	.word song_1054                @ id 1335
	.word 0                        @ id 1336
	.word 0                        @ id 1337
	.word song_1055                @ id 1338
	.word song_1056                @ id 1339
	.word song_1057                @ id 1340
	.word song_1058                @ id 1341
	.word song_1059                @ id 1342
	.word song_1060                @ id 1343
	.word song_1061                @ id 1344
	.word song_1062                @ id 1345
	.word song_1063                @ id 1346
	.word song_1064                @ id 1347
	.word song_1065                @ id 1348
	.word song_1066                @ id 1349
	.word song_1067                @ id 1350
	.word song_1068                @ id 1351
	.word song_1069                @ id 1352
	.word song_1070                @ id 1353
	.word song_1071                @ id 1354
	.word song_1072                @ id 1355
	.word song_1073                @ id 1356
	.word song_1074                @ id 1357
	.word song_1075                @ id 1358
	.word song_1076                @ id 1359
	.word song_1077                @ id 1360
	.word song_1078                @ id 1361
	.word song_1079                @ id 1362
	.word song_1080                @ id 1363
	.word song_1081                @ id 1364
	.word song_1082                @ id 1365
	.word song_1083                @ id 1366
	.word song_1084                @ id 1367
	.word 0                        @ id 1368
	.word 0                        @ id 1369
	.word song_1085                @ id 1370
	.word song_1086                @ id 1371
	.word song_1087                @ id 1372
	.word song_1088                @ id 1373
	.word song_1089                @ id 1374
	.word song_1090                @ id 1375
	.word song_1091                @ id 1376
	.word song_1092                @ id 1377
	.word song_1093                @ id 1378
	.word song_1094                @ id 1379
	.word song_1095                @ id 1380
	.word song_1096                @ id 1381
	.word song_1097                @ id 1382
	.word song_1098                @ id 1383
	.word song_1099                @ id 1384
	.word song_1100                @ id 1385
	.word song_1101                @ id 1386
	.word song_1102                @ id 1387
	.word song_1103                @ id 1388
	.word song_1104                @ id 1389
	.word song_1105                @ id 1390
	.word song_1106                @ id 1391
	.word song_1107                @ id 1392
	.word song_1108                @ id 1393
	.word song_1109                @ id 1394
	.word song_1110                @ id 1395
	.word song_1111                @ id 1396
	.word song_1112                @ id 1397
	.word song_1113                @ id 1398
	.word song_1114                @ id 1399
	.word song_1115                @ id 1400
	.word song_1116                @ id 1401
	.word song_1117                @ id 1402
	.word song_1118                @ id 1403
	.word song_1119                @ id 1404
	.word song_1120                @ id 1405
	.word song_1121                @ id 1406
	.word song_1122                @ id 1407
	.word song_1123                @ id 1408
	.word song_1124                @ id 1409
	.word song_1125                @ id 1410
	.word song_1126                @ id 1411
	.word song_1127                @ id 1412
	.word song_1128                @ id 1413
	.word song_1129                @ id 1414
	.word song_1130                @ id 1415
	.word song_1131                @ id 1416
	.word song_1132                @ id 1417
	.word song_1133                @ id 1418
	.word song_1134                @ id 1419
	.word song_1135                @ id 1420
	.word song_1136                @ id 1421
	.word song_1137                @ id 1422
	.word song_1138                @ id 1423
	.word song_1139                @ id 1424
	.word song_1140                @ id 1425
	.word song_1141                @ id 1426
	.word song_1142                @ id 1427
	.word song_1143                @ id 1428
	.word song_1144                @ id 1429
	.word song_1145                @ id 1430
	.word song_1146                @ id 1431
	.word song_1147                @ id 1432
	.word song_1148                @ id 1433
	.word song_1149                @ id 1434
	.word 0                        @ id 1435
	.word 0                        @ id 1436
	.word 0                        @ id 1437
	.word 0                        @ id 1438
	.word 0                        @ id 1439
	.word 0                        @ id 1440
	.word 0                        @ id 1441
	.word 0                        @ id 1442
	.word 0                        @ id 1443
	.word 0                        @ id 1444
	.word 0                        @ id 1445
	.word 0                        @ id 1446
	.word 0                        @ id 1447
	.word 0                        @ id 1448
	.word 0                        @ id 1449
	.word 0                        @ id 1450
	.word 0                        @ id 1451
	.word 0                        @ id 1452
	.word 0                        @ id 1453
	.word 0                        @ id 1454
	.word song_1150                @ id 1455
	.word 0                        @ id 1456
	.word 0                        @ id 1457
	.word 0                        @ id 1458
	.word 0                        @ id 1459
	.word 0                        @ id 1460
	.word 0                        @ id 1461
	.word 0                        @ id 1462
	.word 0                        @ id 1463
	.word 0                        @ id 1464
	.word 0                        @ id 1465
	.word 0                        @ id 1466
	.word 0                        @ id 1467
	.word 0                        @ id 1468
	.word 0                        @ id 1469
	.word 0                        @ id 1470
	.word 0                        @ id 1471
	.word 0                        @ id 1472
	.word 0                        @ id 1473
	.word 0                        @ id 1474
	.word 0                        @ id 1475
	.word 0                        @ id 1476
	.word 0                        @ id 1477
	.word 0                        @ id 1478
	.word 0                        @ id 1479
	.word 0                        @ id 1480
	.word 0                        @ id 1481
	.word 0                        @ id 1482
	.word 0                        @ id 1483
	.word 0                        @ id 1484
	.word 0                        @ id 1485
	.word 0                        @ id 1486
	.word 0                        @ id 1487
	.word 0                        @ id 1488
	.word 0                        @ id 1489
	.word 0                        @ id 1490
	.word 0                        @ id 1491
	.word 0                        @ id 1492
	.word 0                        @ id 1493
	.word 0                        @ id 1494
	.word 0                        @ id 1495
	.word 0                        @ id 1496
	.word 0                        @ id 1497
	.word 0                        @ id 1498
	.word 0                        @ id 1499
	.word song_1151                @ id 1500
	.word song_1152                @ id 1501
	.word song_1153                @ id 1502
	.word song_1154                @ id 1503
	.word song_1155                @ id 1504
	.word song_1156                @ id 1505
	.word song_1157                @ id 1506
	.word song_1158                @ id 1507
	.word song_1159                @ id 1508
	.word song_1160                @ id 1509
	.word song_1161                @ id 1510
	.word song_1162                @ id 1511
	.word song_1163                @ id 1512
	.word 0                        @ id 1513
	.word 0                        @ id 1514
	.word 0                        @ id 1515
	.word 0                        @ id 1516
	.word 0                        @ id 1517
	.word 0                        @ id 1518
	.word 0                        @ id 1519
	.word song_1164                @ id 1520
	.word song_1165                @ id 1521
	.word song_1166                @ id 1522
	.word song_1167                @ id 1523
	.word song_1168                @ id 1524
	.word song_1169                @ id 1525
	.word song_1170                @ id 1526
	.word song_1171                @ id 1527
	.word song_1172                @ id 1528
	.word song_1173                @ id 1529
	.word 0                        @ id 1530
	.word 0                        @ id 1531
	.word 0                        @ id 1532
	.word 0                        @ id 1533
	.word 0                        @ id 1534
	.word 0                        @ id 1535
	.word 0                        @ id 1536
	.word 0                        @ id 1537
	.word 0                        @ id 1538
	.word 0                        @ id 1539
	.word song_1174                @ id 1540
	.word song_1175                @ id 1541
	.word song_1176                @ id 1542
	.word song_1177                @ id 1543
	.word song_1178                @ id 1544
	.word song_1179                @ id 1545
	.word song_1180                @ id 1546
	.word song_1181                @ id 1547
	.word song_1182                @ id 1548
	.word song_1183                @ id 1549
	.word song_1184                @ id 1550
	.word song_1185                @ id 1551
	.word song_1186                @ id 1552
	.word song_1187                @ id 1553
	.word song_1188                @ id 1554
	.word song_1189                @ id 1555
	.word 0                        @ id 1556
	.word 0                        @ id 1557
	.word 0                        @ id 1558
	.word 0                        @ id 1559
	.word song_1190                @ id 1560
	.word song_1191                @ id 1561
	.word song_1192                @ id 1562
	.word song_1193                @ id 1563
	.word song_1194                @ id 1564
	.word song_1195                @ id 1565
	.word song_1196                @ id 1566
	.word song_1197                @ id 1567
	.word song_1198                @ id 1568
	.word song_1199                @ id 1569
	.word song_1200                @ id 1570
	.word 0                        @ id 1571
	.word 0                        @ id 1572
	.word 0                        @ id 1573
	.word 0                        @ id 1574
	.word 0                        @ id 1575
	.word 0                        @ id 1576
	.word 0                        @ id 1577
	.word 0                        @ id 1578
	.word 0                        @ id 1579
	.word song_1201                @ id 1580
	.word song_1202                @ id 1581
	.word song_1203                @ id 1582
	.word 0                        @ id 1583
	.word 0                        @ id 1584
	.word 0                        @ id 1585
	.word 0                        @ id 1586
	.word 0                        @ id 1587
	.word 0                        @ id 1588
	.word 0                        @ id 1589
	.word song_1204                @ id 1590
	.word song_1205                @ id 1591
	.word song_1206                @ id 1592
	.word song_1207                @ id 1593
	.word song_1208                @ id 1594
	.word song_1209                @ id 1595
	.word song_1210                @ id 1596
	.word song_1211                @ id 1597
	.word song_1212                @ id 1598
	.word song_1213                @ id 1599
	.word song_1214                @ id 1600
	.word song_1215                @ id 1601
	.word song_1216                @ id 1602
	.word song_1217                @ id 1603
	.word song_1218                @ id 1604
	.word song_1219                @ id 1605
	.word song_1220                @ id 1606
	.word song_1221                @ id 1607
	.word song_1222                @ id 1608
	.word song_1223                @ id 1609
	.word song_1224                @ id 1610
	.word song_1225                @ id 1611
	.word song_1226                @ id 1612
	.word song_1227                @ id 1613
	.word 0                        @ id 1614
	.word 0                        @ id 1615
	.word 0                        @ id 1616
	.word 0                        @ id 1617
	.word 0                        @ id 1618
	.word 0                        @ id 1619
	.word song_1228                @ id 1620
	.word song_1229                @ id 1621
	.word song_1230                @ id 1622
	.word song_1231                @ id 1623
	.word song_1232                @ id 1624
	.word song_1233                @ id 1625
	.word song_1234                @ id 1626
	.word song_1235                @ id 1627
	.word song_1236                @ id 1628
	.word song_1237                @ id 1629
	.word song_1238                @ id 1630
	.word song_1239                @ id 1631
	.word song_1240                @ id 1632
	.word song_1241                @ id 1633
	.word 0                        @ id 1634
	.word 0                        @ id 1635
	.word 0                        @ id 1636
	.word 0                        @ id 1637
	.word 0                        @ id 1638
	.word 0                        @ id 1639
	.word song_1242                @ id 1640
	.word song_1243                @ id 1641
	.word song_1244                @ id 1642
	.word song_1245                @ id 1643
	.word song_1246                @ id 1644
	.word song_1247                @ id 1645
	.word song_1248                @ id 1646
	.word song_1249                @ id 1647
	.word song_1250                @ id 1648
	.word song_1251                @ id 1649
	.word 0                        @ id 1650
	.word song_1252                @ id 1651
	.word song_1253                @ id 1652
	.word song_1254                @ id 1653
	.word song_1255                @ id 1654
	.word song_1256                @ id 1655
	.word song_1257                @ id 1656
	.word song_1258                @ id 1657
	.word song_1259                @ id 1658
	.word song_1260                @ id 1659
	.word song_1261                @ id 1660
	.word 0                        @ id 1661
	.word song_1262                @ id 1662
	.word song_1263                @ id 1663
	.word song_1264                @ id 1664
	.word song_1265                @ id 1665
	.word song_1266                @ id 1666
	.word song_1267                @ id 1667
	.word 0                        @ id 1668
	.word 0                        @ id 1669
	.word song_1268                @ id 1670
	.word song_1269                @ id 1671
	.word song_1270                @ id 1672
	.word song_1271                @ id 1673
	.word song_1272                @ id 1674
	.word song_1273                @ id 1675
	.word song_1274                @ id 1676
	.word song_1275                @ id 1677
	.word song_1276                @ id 1678
	.word song_1277                @ id 1679
	.word song_1278                @ id 1680
	.word song_1279                @ id 1681
	.word song_1280                @ id 1682
	.word song_1281                @ id 1683
	.word song_1282                @ id 1684
	.word song_1283                @ id 1685
	.word song_1284                @ id 1686
	.word song_1285                @ id 1687
	.word song_1286                @ id 1688
	.word song_1287                @ id 1689
	.word song_1288                @ id 1690
	.word song_1289                @ id 1691
	.word song_1290                @ id 1692
	.word song_1291                @ id 1693
	.word song_1292                @ id 1694
	.word song_1293                @ id 1695
	.word song_1294                @ id 1696
	.word song_1295                @ id 1697
	.word song_1296                @ id 1698
	.word song_1297                @ id 1699
	.word song_1298                @ id 1700
	.word song_1299                @ id 1701
	.word song_1300                @ id 1702
	.word song_1301                @ id 1703
	.word song_1302                @ id 1704
	.word song_1303                @ id 1705
	.word song_1304                @ id 1706
	.word 0                        @ id 1707
	.word 0                        @ id 1708
	.word 0                        @ id 1709
	.word 0                        @ id 1710
	.word 0                        @ id 1711
	.word 0                        @ id 1712
	.word 0                        @ id 1713
	.word 0                        @ id 1714
	.word 0                        @ id 1715
	.word 0                        @ id 1716
	.word 0                        @ id 1717
	.word 0                        @ id 1718
	.word 0                        @ id 1719
	.word 0                        @ id 1720
	.word 0                        @ id 1721
	.word 0                        @ id 1722
	.word 0                        @ id 1723
	.word 0                        @ id 1724
	.word 0                        @ id 1725
	.word 0                        @ id 1726
	.word 0                        @ id 1727
	.word 0                        @ id 1728
	.word 0                        @ id 1729
	.word 0                        @ id 1730
	.word 0                        @ id 1731
	.word 0                        @ id 1732
	.word 0                        @ id 1733
	.word 0                        @ id 1734
	.word 0                        @ id 1735
	.word 0                        @ id 1736
	.word 0                        @ id 1737
	.word 0                        @ id 1738
	.word 0                        @ id 1739
	.word 0                        @ id 1740
	.word 0                        @ id 1741
	.word 0                        @ id 1742
	.word 0                        @ id 1743
	.word 0                        @ id 1744
	.word 0                        @ id 1745
	.word 0                        @ id 1746
	.word 0                        @ id 1747
	.word 0                        @ id 1748
	.word 0                        @ id 1749
	.word 0                        @ id 1750
	.word 0                        @ id 1751
	.word 0                        @ id 1752
	.word 0                        @ id 1753
	.word 0                        @ id 1754
	.word 0                        @ id 1755
	.word 0                        @ id 1756
	.word 0                        @ id 1757
	.word 0                        @ id 1758
	.word 0                        @ id 1759
	.word 0                        @ id 1760
	.word 0                        @ id 1761
	.word 0                        @ id 1762
	.word 0                        @ id 1763
	.word 0                        @ id 1764
	.word 0                        @ id 1765
	.word 0                        @ id 1766
	.word 0                        @ id 1767
	.word 0                        @ id 1768
	.word 0                        @ id 1769
	.word 0                        @ id 1770
	.word 0                        @ id 1771
	.word 0                        @ id 1772
	.word 0                        @ id 1773
	.word 0                        @ id 1774
	.word 0                        @ id 1775
	.word 0                        @ id 1776
	.word 0                        @ id 1777
	.word 0                        @ id 1778
	.word 0                        @ id 1779
	.word 0                        @ id 1780
	.word 0                        @ id 1781
	.word 0                        @ id 1782
	.word 0                        @ id 1783
	.word 0                        @ id 1784
	.word 0                        @ id 1785
	.word 0                        @ id 1786
	.word 0                        @ id 1787
	.word 0                        @ id 1788
	.word 0                        @ id 1789
	.word 0                        @ id 1790
	.word 0                        @ id 1791
	.word 0                        @ id 1792
	.word 0                        @ id 1793
	.word 0                        @ id 1794
	.word 0                        @ id 1795
	.word 0                        @ id 1796
	.word 0                        @ id 1797
	.word 0                        @ id 1798
	.word 0                        @ id 1799
	.word 0                        @ id 1800
	.word 0                        @ id 1801
	.word 0                        @ id 1802
	.word 0                        @ id 1803
	.word 0                        @ id 1804
	.word 0                        @ id 1805
	.word 0                        @ id 1806
	.word 0                        @ id 1807
	.word 0                        @ id 1808
	.word 0                        @ id 1809
	.word song_1305                @ id 1810
	.word song_1306                @ id 1811
	.word song_1307                @ id 1812
	.word song_1308                @ id 1813
	.word song_1309                @ id 1814
	.word song_1310                @ id 1815
	.word song_1311                @ id 1816
	.word song_1312                @ id 1817
	.word song_1313                @ id 1818
	.word song_1314                @ id 1819
	.word song_1315                @ id 1820
	.word song_1316                @ id 1821
	.word song_1317                @ id 1822
	.word song_1318                @ id 1823
	.word song_1319                @ id 1824
	.word song_1320                @ id 1825
	.word song_1321                @ id 1826
	.word song_1322                @ id 1827
	.word song_1323                @ id 1828
	.word song_1324                @ id 1829
	.word song_1325                @ id 1830
	.word song_1326                @ id 1831
	.word song_1327                @ id 1832
	.word song_1328                @ id 1833
	.word song_1329                @ id 1834
	.word song_1330                @ id 1835
	.word song_1331                @ id 1836
	.word song_1332                @ id 1837
	.word song_1333                @ id 1838
	.word song_1334                @ id 1839
	.word song_1335                @ id 1840
	.word song_1336                @ id 1841
	.word song_1337                @ id 1842
	.word song_1338                @ id 1843
	.word song_1339                @ id 1844
	.word song_1340                @ id 1845
	.word song_1341                @ id 1846

	.global sndSoundIdTable
sndSoundIdTable:   @ u32 count; {SongEntry *song; u32 group}[count]; sndPlay(id) uses it
	.word 1847
	.word song_0000, 7                     @ id 0
	.word song_0001, 0                     @ id 1
	.word song_0002, 0                     @ id 2
	.word song_0003, 0                     @ id 3
	.word song_0004, 0                     @ id 4
	.word song_0005, 0                     @ id 5
	.word song_0006, 3                     @ id 6
	.word song_0007, 2                     @ id 7
	.word song_0008, 1                     @ id 8
	.word song_0009, 0                     @ id 9
	.word song_0010, 0                     @ id 10
	.word song_0011, 1                     @ id 11
	.word song_0012, 1                     @ id 12
	.word song_0013, 3                     @ id 13
	.word song_0014, 0                     @ id 14
	.word song_0015, 0                     @ id 15
	.word song_0016, 1                     @ id 16
	.word song_0017, 0                     @ id 17
	.word song_0018, 0                     @ id 18
	.word song_0019, 0                     @ id 19
	.word song_0020, 0                     @ id 20
	.word song_0021, 0                     @ id 21
	.word song_0022, 0                     @ id 22
	.word song_0023, 0                     @ id 23
	.word song_0024, 0                     @ id 24
	.word song_0025, 0                     @ id 25
	.word song_0026, 0                     @ id 26
	.word song_0027, 0                     @ id 27
	.word song_0028, 0                     @ id 28
	.word song_0029, 0                     @ id 29
	.word song_0030, 0                     @ id 30
	.word song_0031, 0                     @ id 31
	.word song_0032, 0                     @ id 32
	.word song_0033, 0                     @ id 33
	.word song_0034, 0                     @ id 34
	.word song_0035, 0                     @ id 35
	.word song_0036, 0                     @ id 36
	.word song_0037, 0                     @ id 37
	.word song_0038, 0                     @ id 38
	.word song_0039, 0                     @ id 39
	.word song_0040, 0                     @ id 40
	.word song_0041, 0                     @ id 41
	.word song_0042, 0                     @ id 42
	.word song_0043, 1                     @ id 43
	.word song_0044, 2                     @ id 44
	.word song_0045, 0                     @ id 45
	.word song_0046, 0                     @ id 46
	.word song_0047, 1                     @ id 47
	.word song_0048, 2                     @ id 48
	.word song_0049, 0                     @ id 49
	.word 0, 0                             @ id 50
	.word 0, 0                             @ id 51
	.word 0, 0                             @ id 52
	.word song_0050, 1                     @ id 53
	.word song_0051, 1                     @ id 54
	.word song_0052, 1                     @ id 55
	.word song_0053, 0                     @ id 56
	.word song_0054, 0                     @ id 57
	.word song_0055, 0                     @ id 58
	.word song_0056, 0                     @ id 59
	.word song_0057, 1                     @ id 60
	.word song_0058, 1                     @ id 61
	.word song_0059, 0                     @ id 62
	.word song_0060, 0                     @ id 63
	.word song_0061, 0                     @ id 64
	.word song_0062, 0                     @ id 65
	.word song_0063, 0                     @ id 66
	.word song_0064, 0                     @ id 67
	.word song_0065, 0                     @ id 68
	.word song_0066, 0                     @ id 69
	.word song_0067, 0                     @ id 70
	.word song_0068, 0                     @ id 71
	.word song_0069, 0                     @ id 72
	.word song_0070, 0                     @ id 73
	.word song_0071, 0                     @ id 74
	.word song_0072, 0                     @ id 75
	.word song_0073, 1                     @ id 76
	.word song_0074, 1                     @ id 77
	.word song_0075, 0                     @ id 78
	.word song_0076, 0                     @ id 79
	.word song_0077, 0                     @ id 80
	.word song_0078, 1                     @ id 81
	.word song_0079, 1                     @ id 82
	.word song_0080, 1                     @ id 83
	.word song_0081, 0                     @ id 84
	.word song_0082, 0                     @ id 85
	.word song_0083, 0                     @ id 86
	.word song_0084, 0                     @ id 87
	.word song_0085, 0                     @ id 88
	.word song_0086, 0                     @ id 89
	.word song_0087, 0                     @ id 90
	.word song_0088, 0                     @ id 91
	.word song_0089, 0                     @ id 92
	.word song_0090, 1                     @ id 93
	.word song_0091, 2                     @ id 94
	.word song_0092, 2                     @ id 95
	.word song_0093, 2                     @ id 96
	.word song_0094, 2                     @ id 97
	.word song_0095, 1                     @ id 98
	.word song_0096, 1                     @ id 99
	.word song_0097, 1                     @ id 100
	.word song_0098, 1                     @ id 101
	.word song_0099, 0                     @ id 102
	.word song_0100, 0                     @ id 103
	.word song_0101, 0                     @ id 104
	.word song_0102, 0                     @ id 105
	.word song_0103, 0                     @ id 106
	.word song_0104, 0                     @ id 107
	.word song_0105, 2                     @ id 108
	.word song_0106, 0                     @ id 109
	.word song_0107, 1                     @ id 110
	.word song_0108, 0                     @ id 111
	.word song_0109, 1                     @ id 112
	.word song_0110, 1                     @ id 113
	.word song_0111, 1                     @ id 114
	.word song_0112, 1                     @ id 115
	.word song_0113, 1                     @ id 116
	.word song_0114, 2                     @ id 117
	.word song_0115, 1                     @ id 118
	.word song_0116, 2                     @ id 119
	.word song_0117, 1                     @ id 120
	.word song_0118, 2                     @ id 121
	.word song_0119, 1                     @ id 122
	.word song_0120, 2                     @ id 123
	.word song_0121, 1                     @ id 124
	.word song_0122, 0                     @ id 125
	.word song_0123, 0                     @ id 126
	.word song_0124, 0                     @ id 127
	.word song_0125, 1                     @ id 128
	.word song_0126, 2                     @ id 129
	.word song_0127, 1                     @ id 130
	.word song_0128, 2                     @ id 131
	.word song_0129, 1                     @ id 132
	.word song_0130, 2                     @ id 133
	.word song_0131, 1                     @ id 134
	.word song_0132, 2                     @ id 135
	.word song_0133, 1                     @ id 136
	.word song_0134, 0                     @ id 137
	.word song_0135, 0                     @ id 138
	.word song_0136, 0                     @ id 139
	.word song_0137, 1                     @ id 140
	.word song_0138, 2                     @ id 141
	.word song_0139, 1                     @ id 142
	.word song_0140, 2                     @ id 143
	.word song_0141, 1                     @ id 144
	.word song_0142, 2                     @ id 145
	.word song_0143, 1                     @ id 146
	.word song_0144, 2                     @ id 147
	.word song_0145, 1                     @ id 148
	.word song_0146, 0                     @ id 149
	.word song_0147, 0                     @ id 150
	.word song_0148, 0                     @ id 151
	.word song_0149, 1                     @ id 152
	.word song_0150, 2                     @ id 153
	.word song_0151, 1                     @ id 154
	.word song_0152, 2                     @ id 155
	.word song_0153, 1                     @ id 156
	.word song_0154, 2                     @ id 157
	.word song_0155, 1                     @ id 158
	.word song_0156, 2                     @ id 159
	.word song_0157, 1                     @ id 160
	.word song_0158, 0                     @ id 161
	.word song_0159, 0                     @ id 162
	.word song_0160, 0                     @ id 163
	.word song_0161, 0                     @ id 164
	.word song_0162, 6                     @ id 165
	.word song_0163, 6                     @ id 166
	.word song_0164, 6                     @ id 167
	.word song_0165, 6                     @ id 168
	.word song_0166, 6                     @ id 169
	.word song_0167, 6                     @ id 170
	.word song_0168, 0                     @ id 171
	.word song_0169, 1                     @ id 172
	.word song_0170, 0                     @ id 173
	.word song_0171, 1                     @ id 174
	.word song_0172, 0                     @ id 175
	.word song_0173, 0                     @ id 176
	.word song_0174, 0                     @ id 177
	.word song_0175, 0                     @ id 178
	.word 0, 0                             @ id 179
	.word song_0176, 2                     @ id 180
	.word song_0177, 2                     @ id 181
	.word song_0178, 2                     @ id 182
	.word song_0179, 2                     @ id 183
	.word song_0180, 0                     @ id 184
	.word song_0181, 0                     @ id 185
	.word song_0182, 0                     @ id 186
	.word song_0183, 0                     @ id 187
	.word song_0184, 0                     @ id 188
	.word song_0185, 0                     @ id 189
	.word song_0186, 0                     @ id 190
	.word song_0187, 0                     @ id 191
	.word song_0188, 0                     @ id 192
	.word song_0189, 0                     @ id 193
	.word song_0190, 2                     @ id 194
	.word song_0191, 0                     @ id 195
	.word song_0192, 1                     @ id 196
	.word song_0193, 1                     @ id 197
	.word song_0194, 1                     @ id 198
	.word song_0195, 1                     @ id 199
	.word song_0196, 1                     @ id 200
	.word song_0197, 1                     @ id 201
	.word song_0198, 0                     @ id 202
	.word song_0199, 0                     @ id 203
	.word song_0200, 0                     @ id 204
	.word song_0201, 1                     @ id 205
	.word song_0202, 0                     @ id 206
	.word song_0203, 0                     @ id 207
	.word song_0204, 0                     @ id 208
	.word song_0205, 0                     @ id 209
	.word song_0206, 0                     @ id 210
	.word song_0207, 0                     @ id 211
	.word song_0208, 0                     @ id 212
	.word song_0209, 0                     @ id 213
	.word song_0210, 1                     @ id 214
	.word song_0211, 1                     @ id 215
	.word song_0212, 0                     @ id 216
	.word song_0213, 1                     @ id 217
	.word song_0214, 0                     @ id 218
	.word song_0215, 0                     @ id 219
	.word song_0216, 0                     @ id 220
	.word song_0217, 0                     @ id 221
	.word song_0218, 1                     @ id 222
	.word song_0219, 0                     @ id 223
	.word song_0220, 1                     @ id 224
	.word song_0221, 1                     @ id 225
	.word song_0222, 0                     @ id 226
	.word song_0223, 1                     @ id 227
	.word song_0224, 0                     @ id 228
	.word song_0225, 1                     @ id 229
	.word song_0226, 0                     @ id 230
	.word song_0227, 1                     @ id 231
	.word song_0228, 0                     @ id 232
	.word song_0229, 1                     @ id 233
	.word song_0230, 0                     @ id 234
	.word song_0231, 1                     @ id 235
	.word song_0232, 0                     @ id 236
	.word song_0233, 0                     @ id 237
	.word song_0234, 0                     @ id 238
	.word song_0235, 1                     @ id 239
	.word song_0236, 0                     @ id 240
	.word song_0237, 1                     @ id 241
	.word song_0238, 0                     @ id 242
	.word song_0239, 1                     @ id 243
	.word song_0240, 0                     @ id 244
	.word song_0241, 1                     @ id 245
	.word song_0242, 0                     @ id 246
	.word song_0243, 0                     @ id 247
	.word song_0244, 0                     @ id 248
	.word song_0245, 1                     @ id 249
	.word song_0246, 0                     @ id 250
	.word song_0247, 1                     @ id 251
	.word song_0248, 0                     @ id 252
	.word song_0249, 1                     @ id 253
	.word song_0250, 0                     @ id 254
	.word song_0251, 1                     @ id 255
	.word song_0252, 0                     @ id 256
	.word song_0253, 0                     @ id 257
	.word song_0254, 1                     @ id 258
	.word song_0255, 0                     @ id 259
	.word song_0256, 0                     @ id 260
	.word song_0257, 1                     @ id 261
	.word song_0258, 1                     @ id 262
	.word song_0259, 2                     @ id 263
	.word song_0260, 1                     @ id 264
	.word song_0261, 0                     @ id 265
	.word song_0262, 0                     @ id 266
	.word song_0263, 0                     @ id 267
	.word song_0264, 0                     @ id 268
	.word song_0265, 1                     @ id 269
	.word song_0266, 0                     @ id 270
	.word song_0267, 1                     @ id 271
	.word song_0268, 0                     @ id 272
	.word song_0269, 1                     @ id 273
	.word song_0270, 0                     @ id 274
	.word song_0271, 1                     @ id 275
	.word song_0272, 0                     @ id 276
	.word song_0273, 1                     @ id 277
	.word song_0274, 0                     @ id 278
	.word song_0275, 0                     @ id 279
	.word song_0276, 1                     @ id 280
	.word song_0277, 0                     @ id 281
	.word song_0278, 4                     @ id 282
	.word song_0279, 0                     @ id 283
	.word song_0280, 0                     @ id 284
	.word song_0281, 0                     @ id 285
	.word song_0282, 0                     @ id 286
	.word song_0283, 0                     @ id 287
	.word song_0284, 0                     @ id 288
	.word song_0285, 0                     @ id 289
	.word song_0286, 0                     @ id 290
	.word song_0287, 0                     @ id 291
	.word song_0288, 0                     @ id 292
	.word song_0289, 0                     @ id 293
	.word song_0290, 0                     @ id 294
	.word song_0291, 1                     @ id 295
	.word song_0292, 0                     @ id 296
	.word song_0293, 1                     @ id 297
	.word song_0294, 0                     @ id 298
	.word song_0295, 0                     @ id 299
	.word song_0296, 7                     @ id 300
	.word song_0297, 7                     @ id 301
	.word song_0298, 4                     @ id 302
	.word song_0299, 4                     @ id 303
	.word song_0300, 5                     @ id 304
	.word song_0301, 5                     @ id 305
	.word song_0302, 5                     @ id 306
	.word song_0303, 5                     @ id 307
	.word song_0304, 5                     @ id 308
	.word song_0305, 5                     @ id 309
	.word song_0306, 6                     @ id 310
	.word song_0307, 6                     @ id 311
	.word song_0308, 5                     @ id 312
	.word song_0309, 7                     @ id 313
	.word song_0310, 7                     @ id 314
	.word song_0311, 5                     @ id 315
	.word song_0312, 4                     @ id 316
	.word song_0313, 4                     @ id 317
	.word song_0314, 4                     @ id 318
	.word song_0315, 7                     @ id 319
	.word song_0316, 6                     @ id 320
	.word song_0317, 6                     @ id 321
	.word song_0318, 6                     @ id 322
	.word song_0319, 4                     @ id 323
	.word song_0320, 4                     @ id 324
	.word song_0321, 4                     @ id 325
	.word song_0322, 4                     @ id 326
	.word song_0323, 4                     @ id 327
	.word song_0324, 4                     @ id 328
	.word song_0325, 4                     @ id 329
	.word song_0326, 4                     @ id 330
	.word song_0327, 4                     @ id 331
	.word song_0328, 4                     @ id 332
	.word song_0329, 4                     @ id 333
	.word song_0330, 5                     @ id 334
	.word song_0331, 0                     @ id 335
	.word song_0332, 4                     @ id 336
	.word song_0333, 5                     @ id 337
	.word song_0334, 5                     @ id 338
	.word song_0335, 5                     @ id 339
	.word song_0336, 5                     @ id 340
	.word song_0337, 5                     @ id 341
	.word song_0338, 5                     @ id 342
	.word song_0339, 5                     @ id 343
	.word song_0340, 5                     @ id 344
	.word song_0341, 1                     @ id 345
	.word song_0342, 4                     @ id 346
	.word song_0343, 5                     @ id 347
	.word song_0344, 4                     @ id 348
	.word song_0345, 4                     @ id 349
	.word song_0346, 4                     @ id 350
	.word song_0347, 4                     @ id 351
	.word song_0348, 4                     @ id 352
	.word song_0349, 4                     @ id 353
	.word song_0350, 4                     @ id 354
	.word song_0351, 4                     @ id 355
	.word song_0352, 4                     @ id 356
	.word song_0353, 4                     @ id 357
	.word song_0354, 4                     @ id 358
	.word song_0355, 4                     @ id 359
	.word song_0356, 6                     @ id 360
	.word song_0357, 5                     @ id 361
	.word song_0358, 5                     @ id 362
	.word song_0359, 5                     @ id 363
	.word song_0360, 5                     @ id 364
	.word song_0361, 4                     @ id 365
	.word song_0362, 4                     @ id 366
	.word song_0363, 4                     @ id 367
	.word song_0364, 6                     @ id 368
	.word song_0365, 4                     @ id 369
	.word song_0366, 6                     @ id 370
	.word song_0367, 6                     @ id 371
	.word song_0368, 7                     @ id 372
	.word 0, 0                             @ id 373
	.word 0, 0                             @ id 374
	.word 0, 0                             @ id 375
	.word 0, 0                             @ id 376
	.word 0, 0                             @ id 377
	.word 0, 0                             @ id 378
	.word 0, 0                             @ id 379
	.word song_0369, 1                     @ id 380
	.word song_0370, 0                     @ id 381
	.word song_0371, 4                     @ id 382
	.word song_0372, 5                     @ id 383
	.word song_0373, 5                     @ id 384
	.word song_0374, 5                     @ id 385
	.word song_0375, 6                     @ id 386
	.word song_0376, 3                     @ id 387
	.word song_0377, 5                     @ id 388
	.word song_0378, 5                     @ id 389
	.word song_0379, 4                     @ id 390
	.word song_0380, 3                     @ id 391
	.word 0, 0                             @ id 392
	.word 0, 0                             @ id 393
	.word 0, 0                             @ id 394
	.word 0, 0                             @ id 395
	.word 0, 0                             @ id 396
	.word 0, 0                             @ id 397
	.word 0, 0                             @ id 398
	.word 0, 0                             @ id 399
	.word song_0381, 3                     @ id 400
	.word song_0382, 3                     @ id 401
	.word song_0383, 3                     @ id 402
	.word song_0384, 3                     @ id 403
	.word song_0385, 7                     @ id 404
	.word song_0386, 7                     @ id 405
	.word song_0387, 7                     @ id 406
	.word song_0388, 4                     @ id 407
	.word song_0389, 4                     @ id 408
	.word song_0390, 4                     @ id 409
	.word song_0391, 5                     @ id 410
	.word song_0392, 6                     @ id 411
	.word song_0393, 5                     @ id 412
	.word song_0394, 4                     @ id 413
	.word song_0395, 5                     @ id 414
	.word song_0396, 4                     @ id 415
	.word song_0397, 4                     @ id 416
	.word song_0398, 7                     @ id 417
	.word song_0399, 7                     @ id 418
	.word song_0400, 7                     @ id 419
	.word song_0401, 4                     @ id 420
	.word song_0402, 6                     @ id 421
	.word song_0403, 6                     @ id 422
	.word song_0404, 7                     @ id 423
	.word song_0405, 7                     @ id 424
	.word song_0406, 7                     @ id 425
	.word song_0407, 7                     @ id 426
	.word song_0408, 2                     @ id 427
	.word song_0409, 7                     @ id 428
	.word song_0410, 7                     @ id 429
	.word song_0411, 7                     @ id 430
	.word song_0412, 2                     @ id 431
	.word song_0413, 3                     @ id 432
	.word song_0414, 3                     @ id 433
	.word song_0415, 3                     @ id 434
	.word song_0416, 7                     @ id 435
	.word song_0417, 7                     @ id 436
	.word song_0418, 7                     @ id 437
	.word song_0419, 4                     @ id 438
	.word song_0420, 4                     @ id 439
	.word song_0421, 3                     @ id 440
	.word song_0422, 3                     @ id 441
	.word song_0423, 4                     @ id 442
	.word song_0424, 3                     @ id 443
	.word song_0425, 3                     @ id 444
	.word song_0426, 3                     @ id 445
	.word song_0427, 3                     @ id 446
	.word song_0428, 7                     @ id 447
	.word song_0429, 7                     @ id 448
	.word song_0430, 7                     @ id 449
	.word song_0431, 4                     @ id 450
	.word song_0432, 5                     @ id 451
	.word song_0433, 4                     @ id 452
	.word song_0434, 5                     @ id 453
	.word song_0435, 4                     @ id 454
	.word song_0436, 6                     @ id 455
	.word song_0437, 7                     @ id 456
	.word song_0438, 7                     @ id 457
	.word song_0439, 7                     @ id 458
	.word song_0440, 4                     @ id 459
	.word song_0441, 7                     @ id 460
	.word song_0442, 7                     @ id 461
	.word song_0443, 7                     @ id 462
	.word song_0444, 4                     @ id 463
	.word song_0445, 4                     @ id 464
	.word song_0446, 5                     @ id 465
	.word 0, 0                             @ id 466
	.word 0, 0                             @ id 467
	.word 0, 0                             @ id 468
	.word 0, 0                             @ id 469
	.word 0, 0                             @ id 470
	.word 0, 0                             @ id 471
	.word 0, 0                             @ id 472
	.word 0, 0                             @ id 473
	.word 0, 0                             @ id 474
	.word 0, 0                             @ id 475
	.word 0, 0                             @ id 476
	.word 0, 0                             @ id 477
	.word 0, 0                             @ id 478
	.word 0, 0                             @ id 479
	.word 0, 0                             @ id 480
	.word song_0447, 4                     @ id 481
	.word song_0448, 4                     @ id 482
	.word song_0449, 4                     @ id 483
	.word song_0450, 4                     @ id 484
	.word song_0451, 4                     @ id 485
	.word song_0452, 4                     @ id 486
	.word song_0453, 4                     @ id 487
	.word song_0454, 4                     @ id 488
	.word song_0455, 4                     @ id 489
	.word song_0456, 4                     @ id 490
	.word song_0457, 4                     @ id 491
	.word song_0458, 4                     @ id 492
	.word song_0459, 4                     @ id 493
	.word song_0460, 4                     @ id 494
	.word song_0461, 5                     @ id 495
	.word song_0462, 4                     @ id 496
	.word 0, 0                             @ id 497
	.word song_0463, 4                     @ id 498
	.word 0, 0                             @ id 499
	.word song_0464, 4                     @ id 500
	.word song_0465, 4                     @ id 501
	.word song_0466, 4                     @ id 502
	.word song_0467, 4                     @ id 503
	.word song_0468, 0                     @ id 504
	.word song_0469, 4                     @ id 505
	.word song_0470, 4                     @ id 506
	.word song_0471, 4                     @ id 507
	.word song_0472, 4                     @ id 508
	.word song_0473, 4                     @ id 509
	.word song_0474, 4                     @ id 510
	.word song_0475, 4                     @ id 511
	.word song_0476, 4                     @ id 512
	.word song_0477, 4                     @ id 513
	.word song_0478, 4                     @ id 514
	.word song_0479, 4                     @ id 515
	.word song_0480, 4                     @ id 516
	.word song_0481, 4                     @ id 517
	.word song_0482, 4                     @ id 518
	.word song_0483, 4                     @ id 519
	.word song_0484, 5                     @ id 520
	.word song_0485, 4                     @ id 521
	.word song_0486, 4                     @ id 522
	.word song_0487, 4                     @ id 523
	.word song_0488, 4                     @ id 524
	.word song_0489, 4                     @ id 525
	.word song_0490, 4                     @ id 526
	.word song_0491, 4                     @ id 527
	.word 0, 0                             @ id 528
	.word 0, 0                             @ id 529
	.word 0, 0                             @ id 530
	.word song_0492, 4                     @ id 531
	.word song_0493, 4                     @ id 532
	.word song_0494, 4                     @ id 533
	.word song_0495, 4                     @ id 534
	.word song_0496, 5                     @ id 535
	.word song_0497, 5                     @ id 536
	.word song_0498, 5                     @ id 537
	.word song_0499, 5                     @ id 538
	.word song_0500, 5                     @ id 539
	.word song_0501, 4                     @ id 540
	.word song_0502, 4                     @ id 541
	.word song_0503, 4                     @ id 542
	.word song_0504, 4                     @ id 543
	.word song_0505, 4                     @ id 544
	.word song_0506, 4                     @ id 545
	.word song_0507, 4                     @ id 546
	.word song_0508, 4                     @ id 547
	.word song_0509, 4                     @ id 548
	.word song_0510, 4                     @ id 549
	.word song_0511, 4                     @ id 550
	.word song_0512, 0                     @ id 551
	.word song_0513, 4                     @ id 552
	.word song_0514, 4                     @ id 553
	.word song_0515, 4                     @ id 554
	.word song_0516, 4                     @ id 555
	.word song_0517, 4                     @ id 556
	.word song_0518, 4                     @ id 557
	.word song_0519, 6                     @ id 558
	.word song_0520, 5                     @ id 559
	.word song_0521, 0                     @ id 560
	.word song_0522, 0                     @ id 561
	.word song_0523, 0                     @ id 562
	.word 0, 0                             @ id 563
	.word song_0524, 0                     @ id 564
	.word song_0525, 0                     @ id 565
	.word song_0526, 0                     @ id 566
	.word song_0527, 0                     @ id 567
	.word song_0528, 4                     @ id 568
	.word song_0529, 0                     @ id 569
	.word song_0530, 4                     @ id 570
	.word song_0531, 4                     @ id 571
	.word song_0532, 5                     @ id 572
	.word song_0533, 4                     @ id 573
	.word song_0534, 4                     @ id 574
	.word song_0535, 0                     @ id 575
	.word song_0536, 0                     @ id 576
	.word song_0537, 0                     @ id 577
	.word song_0538, 2                     @ id 578
	.word 0, 0                             @ id 579
	.word 0, 0                             @ id 580
	.word 0, 0                             @ id 581
	.word 0, 0                             @ id 582
	.word 0, 0                             @ id 583
	.word 0, 0                             @ id 584
	.word 0, 0                             @ id 585
	.word song_0539, 5                     @ id 586
	.word song_0540, 5                     @ id 587
	.word song_0541, 5                     @ id 588
	.word song_0542, 5                     @ id 589
	.word song_0543, 5                     @ id 590
	.word song_0544, 5                     @ id 591
	.word song_0545, 5                     @ id 592
	.word song_0546, 5                     @ id 593
	.word song_0547, 5                     @ id 594
	.word song_0548, 6                     @ id 595
	.word song_0549, 6                     @ id 596
	.word song_0550, 6                     @ id 597
	.word song_0551, 5                     @ id 598
	.word song_0552, 0                     @ id 599
	.word song_0553, 6                     @ id 600
	.word song_0554, 5                     @ id 601
	.word 0, 0                             @ id 602
	.word 0, 0                             @ id 603
	.word 0, 0                             @ id 604
	.word 0, 0                             @ id 605
	.word 0, 0                             @ id 606
	.word 0, 0                             @ id 607
	.word 0, 0                             @ id 608
	.word 0, 0                             @ id 609
	.word 0, 0                             @ id 610
	.word song_0555, 4                     @ id 611
	.word song_0556, 4                     @ id 612
	.word song_0557, 4                     @ id 613
	.word song_0558, 6                     @ id 614
	.word song_0559, 3                     @ id 615
	.word song_0560, 4                     @ id 616
	.word song_0561, 4                     @ id 617
	.word song_0562, 6                     @ id 618
	.word song_0563, 5                     @ id 619
	.word song_0564, 4                     @ id 620
	.word song_0565, 4                     @ id 621
	.word song_0566, 4                     @ id 622
	.word song_0567, 5                     @ id 623
	.word song_0568, 4                     @ id 624
	.word song_0569, 4                     @ id 625
	.word 0, 0                             @ id 626
	.word 0, 0                             @ id 627
	.word 0, 0                             @ id 628
	.word 0, 0                             @ id 629
	.word song_0570, 4                     @ id 630
	.word song_0571, 4                     @ id 631
	.word 0, 0                             @ id 632
	.word 0, 0                             @ id 633
	.word 0, 0                             @ id 634
	.word song_0572, 5                     @ id 635
	.word song_0573, 5                     @ id 636
	.word song_0574, 5                     @ id 637
	.word song_0575, 5                     @ id 638
	.word song_0576, 5                     @ id 639
	.word song_0577, 5                     @ id 640
	.word song_0578, 4                     @ id 641
	.word song_0579, 4                     @ id 642
	.word song_0580, 4                     @ id 643
	.word song_0581, 4                     @ id 644
	.word song_0582, 4                     @ id 645
	.word song_0583, 4                     @ id 646
	.word song_0584, 4                     @ id 647
	.word song_0585, 4                     @ id 648
	.word song_0586, 5                     @ id 649
	.word 0, 0                             @ id 650
	.word song_0587, 4                     @ id 651
	.word song_0588, 4                     @ id 652
	.word song_0589, 4                     @ id 653
	.word song_0590, 5                     @ id 654
	.word song_0591, 4                     @ id 655
	.word song_0592, 4                     @ id 656
	.word song_0593, 4                     @ id 657
	.word song_0594, 6                     @ id 658
	.word song_0595, 6                     @ id 659
	.word song_0596, 5                     @ id 660
	.word song_0597, 5                     @ id 661
	.word song_0598, 5                     @ id 662
	.word song_0599, 4                     @ id 663
	.word song_0600, 5                     @ id 664
	.word song_0601, 4                     @ id 665
	.word song_0602, 0                     @ id 666
	.word 0, 0                             @ id 667
	.word 0, 0                             @ id 668
	.word 0, 0                             @ id 669
	.word song_0603, 5                     @ id 670
	.word song_0604, 5                     @ id 671
	.word 0, 0                             @ id 672
	.word 0, 0                             @ id 673
	.word 0, 0                             @ id 674
	.word song_0605, 6                     @ id 675
	.word song_0606, 4                     @ id 676
	.word song_0607, 4                     @ id 677
	.word song_0608, 5                     @ id 678
	.word song_0609, 4                     @ id 679
	.word song_0610, 6                     @ id 680
	.word song_0611, 5                     @ id 681
	.word song_0612, 6                     @ id 682
	.word song_0613, 4                     @ id 683
	.word song_0614, 5                     @ id 684
	.word song_0615, 5                     @ id 685
	.word song_0616, 5                     @ id 686
	.word song_0617, 5                     @ id 687
	.word song_0618, 5                     @ id 688
	.word song_0619, 5                     @ id 689
	.word song_0620, 5                     @ id 690
	.word song_0621, 6                     @ id 691
	.word song_0622, 6                     @ id 692
	.word song_0623, 6                     @ id 693
	.word song_0624, 5                     @ id 694
	.word song_0625, 4                     @ id 695
	.word song_0626, 4                     @ id 696
	.word song_0627, 5                     @ id 697
	.word song_0628, 3                     @ id 698
	.word 0, 0                             @ id 699
	.word song_0629, 6                     @ id 700
	.word song_0630, 5                     @ id 701
	.word song_0631, 5                     @ id 702
	.word song_0632, 4                     @ id 703
	.word song_0633, 4                     @ id 704
	.word song_0634, 5                     @ id 705
	.word 0, 0                             @ id 706
	.word 0, 0                             @ id 707
	.word 0, 0                             @ id 708
	.word 0, 0                             @ id 709
	.word song_0635, 5                     @ id 710
	.word 0, 0                             @ id 711
	.word 0, 0                             @ id 712
	.word 0, 0                             @ id 713
	.word 0, 0                             @ id 714
	.word song_0636, 4                     @ id 715
	.word song_0637, 5                     @ id 716
	.word song_0638, 5                     @ id 717
	.word song_0639, 6                     @ id 718
	.word 0, 0                             @ id 719
	.word song_0640, 5                     @ id 720
	.word song_0641, 6                     @ id 721
	.word song_0642, 6                     @ id 722
	.word song_0643, 3                     @ id 723
	.word song_0644, 5                     @ id 724
	.word song_0645, 6                     @ id 725
	.word song_0646, 5                     @ id 726
	.word song_0647, 5                     @ id 727
	.word 0, 0                             @ id 728
	.word 0, 0                             @ id 729
	.word song_0648, 5                     @ id 730
	.word song_0649, 5                     @ id 731
	.word song_0650, 6                     @ id 732
	.word song_0651, 6                     @ id 733
	.word song_0652, 6                     @ id 734
	.word song_0653, 6                     @ id 735
	.word song_0654, 0                     @ id 736
	.word song_0655, 6                     @ id 737
	.word song_0656, 5                     @ id 738
	.word song_0657, 6                     @ id 739
	.word 0, 0                             @ id 740
	.word song_0658, 4                     @ id 741
	.word song_0659, 4                     @ id 742
	.word song_0660, 4                     @ id 743
	.word 0, 0                             @ id 744
	.word 0, 0                             @ id 745
	.word song_0661, 5                     @ id 746
	.word song_0662, 5                     @ id 747
	.word song_0663, 5                     @ id 748
	.word song_0664, 4                     @ id 749
	.word song_0665, 6                     @ id 750
	.word song_0666, 4                     @ id 751
	.word song_0667, 6                     @ id 752
	.word song_0668, 5                     @ id 753
	.word song_0669, 6                     @ id 754
	.word song_0670, 5                     @ id 755
	.word song_0671, 3                     @ id 756
	.word song_0672, 5                     @ id 757
	.word song_0673, 5                     @ id 758
	.word song_0674, 6                     @ id 759
	.word song_0675, 5                     @ id 760
	.word song_0676, 5                     @ id 761
	.word song_0677, 5                     @ id 762
	.word song_0678, 5                     @ id 763
	.word song_0679, 5                     @ id 764
	.word song_0680, 5                     @ id 765
	.word song_0681, 6                     @ id 766
	.word song_0682, 5                     @ id 767
	.word song_0683, 6                     @ id 768
	.word song_0684, 4                     @ id 769
	.word song_0685, 4                     @ id 770
	.word song_0686, 5                     @ id 771
	.word song_0687, 5                     @ id 772
	.word song_0688, 5                     @ id 773
	.word song_0689, 6                     @ id 774
	.word song_0690, 5                     @ id 775
	.word song_0691, 5                     @ id 776
	.word song_0692, 5                     @ id 777
	.word song_0693, 5                     @ id 778
	.word song_0694, 5                     @ id 779
	.word song_0695, 4                     @ id 780
	.word song_0696, 5                     @ id 781
	.word song_0697, 5                     @ id 782
	.word song_0698, 5                     @ id 783
	.word song_0699, 6                     @ id 784
	.word song_0700, 5                     @ id 785
	.word song_0701, 6                     @ id 786
	.word song_0702, 5                     @ id 787
	.word song_0703, 5                     @ id 788
	.word song_0704, 6                     @ id 789
	.word song_0705, 5                     @ id 790
	.word song_0706, 5                     @ id 791
	.word song_0707, 4                     @ id 792
	.word 0, 0                             @ id 793
	.word song_0708, 5                     @ id 794
	.word song_0709, 5                     @ id 795
	.word song_0710, 5                     @ id 796
	.word song_0711, 4                     @ id 797
	.word song_0712, 5                     @ id 798
	.word song_0713, 4                     @ id 799
	.word song_0714, 5                     @ id 800
	.word song_0715, 5                     @ id 801
	.word song_0716, 6                     @ id 802
	.word song_0717, 6                     @ id 803
	.word song_0718, 4                     @ id 804
	.word song_0719, 5                     @ id 805
	.word song_0720, 4                     @ id 806
	.word song_0721, 5                     @ id 807
	.word song_0722, 4                     @ id 808
	.word song_0723, 5                     @ id 809
	.word song_0724, 5                     @ id 810
	.word song_0725, 4                     @ id 811
	.word song_0726, 5                     @ id 812
	.word song_0727, 4                     @ id 813
	.word song_0728, 0                     @ id 814
	.word song_0729, 0                     @ id 815
	.word song_0730, 0                     @ id 816
	.word song_0731, 4                     @ id 817
	.word song_0732, 4                     @ id 818
	.word song_0733, 4                     @ id 819
	.word song_0734, 4                     @ id 820
	.word song_0735, 4                     @ id 821
	.word song_0736, 5                     @ id 822
	.word song_0737, 5                     @ id 823
	.word song_0738, 5                     @ id 824
	.word song_0739, 5                     @ id 825
	.word song_0740, 5                     @ id 826
	.word song_0741, 4                     @ id 827
	.word song_0742, 4                     @ id 828
	.word song_0743, 4                     @ id 829
	.word song_0744, 5                     @ id 830
	.word song_0745, 4                     @ id 831
	.word song_0746, 4                     @ id 832
	.word song_0747, 4                     @ id 833
	.word song_0748, 4                     @ id 834
	.word song_0749, 4                     @ id 835
	.word 0, 0                             @ id 836
	.word song_0750, 4                     @ id 837
	.word song_0751, 4                     @ id 838
	.word song_0752, 4                     @ id 839
	.word song_0753, 5                     @ id 840
	.word song_0754, 4                     @ id 841
	.word song_0755, 6                     @ id 842
	.word song_0756, 6                     @ id 843
	.word song_0757, 6                     @ id 844
	.word song_0758, 6                     @ id 845
	.word song_0759, 6                     @ id 846
	.word song_0760, 6                     @ id 847
	.word song_0761, 6                     @ id 848
	.word song_0762, 6                     @ id 849
	.word song_0763, 6                     @ id 850
	.word song_0764, 4                     @ id 851
	.word song_0765, 4                     @ id 852
	.word song_0766, 5                     @ id 853
	.word song_0767, 5                     @ id 854
	.word song_0768, 5                     @ id 855
	.word song_0769, 6                     @ id 856
	.word song_0770, 6                     @ id 857
	.word song_0771, 6                     @ id 858
	.word song_0772, 3                     @ id 859
	.word song_0773, 5                     @ id 860
	.word song_0774, 6                     @ id 861
	.word song_0775, 6                     @ id 862
	.word song_0776, 6                     @ id 863
	.word song_0777, 6                     @ id 864
	.word song_0778, 5                     @ id 865
	.word song_0779, 5                     @ id 866
	.word song_0780, 5                     @ id 867
	.word song_0781, 5                     @ id 868
	.word song_0782, 5                     @ id 869
	.word song_0783, 5                     @ id 870
	.word song_0784, 5                     @ id 871
	.word song_0785, 5                     @ id 872
	.word 0, 0                             @ id 873
	.word 0, 0                             @ id 874
	.word 0, 0                             @ id 875
	.word 0, 0                             @ id 876
	.word 0, 0                             @ id 877
	.word 0, 0                             @ id 878
	.word 0, 0                             @ id 879
	.word 0, 0                             @ id 880
	.word 0, 0                             @ id 881
	.word 0, 0                             @ id 882
	.word 0, 0                             @ id 883
	.word song_0786, 4                     @ id 884
	.word song_0787, 4                     @ id 885
	.word song_0788, 4                     @ id 886
	.word song_0789, 4                     @ id 887
	.word song_0790, 5                     @ id 888
	.word song_0791, 6                     @ id 889
	.word song_0792, 5                     @ id 890
	.word song_0793, 5                     @ id 891
	.word song_0794, 5                     @ id 892
	.word song_0795, 5                     @ id 893
	.word song_0796, 6                     @ id 894
	.word song_0797, 3                     @ id 895
	.word song_0798, 7                     @ id 896
	.word song_0799, 7                     @ id 897
	.word song_0800, 7                     @ id 898
	.word song_0801, 7                     @ id 899
	.word song_0802, 7                     @ id 900
	.word song_0803, 3                     @ id 901
	.word song_0804, 4                     @ id 902
	.word song_0805, 7                     @ id 903
	.word 0, 0                             @ id 904
	.word 0, 0                             @ id 905
	.word 0, 0                             @ id 906
	.word 0, 0                             @ id 907
	.word 0, 0                             @ id 908
	.word 0, 0                             @ id 909
	.word 0, 0                             @ id 910
	.word song_0806, 5                     @ id 911
	.word song_0807, 6                     @ id 912
	.word song_0808, 4                     @ id 913
	.word song_0809, 4                     @ id 914
	.word song_0810, 5                     @ id 915
	.word song_0811, 6                     @ id 916
	.word song_0812, 6                     @ id 917
	.word song_0813, 6                     @ id 918
	.word song_0814, 6                     @ id 919
	.word song_0815, 6                     @ id 920
	.word song_0816, 3                     @ id 921
	.word 0, 0                             @ id 922
	.word 0, 0                             @ id 923
	.word 0, 0                             @ id 924
	.word 0, 0                             @ id 925
	.word 0, 0                             @ id 926
	.word 0, 0                             @ id 927
	.word 0, 0                             @ id 928
	.word 0, 0                             @ id 929
	.word song_0817, 5                     @ id 930
	.word song_0818, 6                     @ id 931
	.word song_0819, 3                     @ id 932
	.word 0, 0                             @ id 933
	.word 0, 0                             @ id 934
	.word 0, 0                             @ id 935
	.word 0, 0                             @ id 936
	.word 0, 0                             @ id 937
	.word 0, 0                             @ id 938
	.word 0, 0                             @ id 939
	.word song_0820, 4                     @ id 940
	.word song_0821, 4                     @ id 941
	.word song_0822, 4                     @ id 942
	.word 0, 0                             @ id 943
	.word 0, 0                             @ id 944
	.word 0, 0                             @ id 945
	.word 0, 0                             @ id 946
	.word 0, 0                             @ id 947
	.word 0, 0                             @ id 948
	.word 0, 0                             @ id 949
	.word song_0823, 4                     @ id 950
	.word song_0824, 5                     @ id 951
	.word song_0825, 5                     @ id 952
	.word song_0826, 5                     @ id 953
	.word song_0827, 5                     @ id 954
	.word song_0828, 5                     @ id 955
	.word song_0829, 5                     @ id 956
	.word song_0830, 4                     @ id 957
	.word song_0831, 4                     @ id 958
	.word 0, 0                             @ id 959
	.word song_0832, 6                     @ id 960
	.word song_0833, 6                     @ id 961
	.word song_0834, 5                     @ id 962
	.word song_0835, 5                     @ id 963
	.word song_0836, 5                     @ id 964
	.word 0, 0                             @ id 965
	.word 0, 0                             @ id 966
	.word 0, 0                             @ id 967
	.word 0, 0                             @ id 968
	.word 0, 0                             @ id 969
	.word song_0837, 5                     @ id 970
	.word song_0838, 5                     @ id 971
	.word song_0839, 5                     @ id 972
	.word song_0840, 5                     @ id 973
	.word song_0841, 5                     @ id 974
	.word song_0842, 5                     @ id 975
	.word song_0843, 5                     @ id 976
	.word song_0844, 4                     @ id 977
	.word song_0845, 6                     @ id 978
	.word song_0846, 6                     @ id 979
	.word song_0847, 6                     @ id 980
	.word song_0848, 6                     @ id 981
	.word song_0849, 6                     @ id 982
	.word song_0850, 6                     @ id 983
	.word song_0851, 3                     @ id 984
	.word song_0852, 3                     @ id 985
	.word song_0853, 5                     @ id 986
	.word song_0854, 6                     @ id 987
	.word song_0855, 3                     @ id 988
	.word 0, 0                             @ id 989
	.word song_0856, 2                     @ id 990
	.word song_0857, 3                     @ id 991
	.word song_0858, 3                     @ id 992
	.word song_0859, 3                     @ id 993
	.word song_0860, 4                     @ id 994
	.word song_0861, 5                     @ id 995
	.word song_0862, 6                     @ id 996
	.word song_0863, 7                     @ id 997
	.word 0, 0                             @ id 998
	.word song_0864, 0                     @ id 999
	.word 0, 0                             @ id 1000
	.word song_0865, 0                     @ id 1001
	.word song_0866, 0                     @ id 1002
	.word song_0867, 0                     @ id 1003
	.word song_0868, 0                     @ id 1004
	.word song_0869, 0                     @ id 1005
	.word song_0870, 0                     @ id 1006
	.word song_0871, 0                     @ id 1007
	.word song_0872, 0                     @ id 1008
	.word song_0873, 0                     @ id 1009
	.word song_0874, 0                     @ id 1010
	.word song_0875, 0                     @ id 1011
	.word song_0876, 0                     @ id 1012
	.word song_0877, 0                     @ id 1013
	.word song_0878, 0                     @ id 1014
	.word song_0879, 0                     @ id 1015
	.word song_0880, 0                     @ id 1016
	.word song_0881, 0                     @ id 1017
	.word song_0882, 0                     @ id 1018
	.word song_0883, 0                     @ id 1019
	.word song_0884, 0                     @ id 1020
	.word song_0885, 0                     @ id 1021
	.word song_0886, 0                     @ id 1022
	.word song_0887, 0                     @ id 1023
	.word song_0888, 0                     @ id 1024
	.word song_0889, 0                     @ id 1025
	.word song_0890, 0                     @ id 1026
	.word song_0891, 0                     @ id 1027
	.word song_0892, 0                     @ id 1028
	.word song_0893, 0                     @ id 1029
	.word song_0894, 0                     @ id 1030
	.word song_0895, 0                     @ id 1031
	.word song_0896, 0                     @ id 1032
	.word song_0897, 0                     @ id 1033
	.word song_0898, 0                     @ id 1034
	.word song_0899, 3                     @ id 1035
	.word song_0900, 3                     @ id 1036
	.word song_0901, 3                     @ id 1037
	.word song_0902, 3                     @ id 1038
	.word song_0903, 0                     @ id 1039
	.word song_0904, 0                     @ id 1040
	.word song_0905, 0                     @ id 1041
	.word song_0906, 0                     @ id 1042
	.word song_0907, 0                     @ id 1043
	.word song_0908, 0                     @ id 1044
	.word song_0909, 0                     @ id 1045
	.word song_0910, 0                     @ id 1046
	.word song_0911, 0                     @ id 1047
	.word song_0912, 0                     @ id 1048
	.word song_0913, 0                     @ id 1049
	.word song_0914, 0                     @ id 1050
	.word song_0915, 0                     @ id 1051
	.word 0, 0                             @ id 1052
	.word song_0916, 0                     @ id 1053
	.word song_0917, 0                     @ id 1054
	.word song_0918, 0                     @ id 1055
	.word song_0919, 0                     @ id 1056
	.word song_0920, 0                     @ id 1057
	.word song_0921, 0                     @ id 1058
	.word song_0922, 0                     @ id 1059
	.word song_0923, 0                     @ id 1060
	.word song_0924, 0                     @ id 1061
	.word song_0925, 0                     @ id 1062
	.word song_0926, 0                     @ id 1063
	.word song_0927, 0                     @ id 1064
	.word song_0928, 0                     @ id 1065
	.word song_0929, 0                     @ id 1066
	.word song_0930, 0                     @ id 1067
	.word song_0931, 0                     @ id 1068
	.word song_0932, 0                     @ id 1069
	.word song_0933, 0                     @ id 1070
	.word song_0934, 0                     @ id 1071
	.word song_0935, 0                     @ id 1072
	.word song_0936, 0                     @ id 1073
	.word song_0937, 0                     @ id 1074
	.word song_0938, 0                     @ id 1075
	.word song_0939, 0                     @ id 1076
	.word song_0940, 0                     @ id 1077
	.word song_0941, 0                     @ id 1078
	.word song_0942, 0                     @ id 1079
	.word song_0943, 0                     @ id 1080
	.word song_0944, 0                     @ id 1081
	.word song_0945, 0                     @ id 1082
	.word song_0946, 0                     @ id 1083
	.word song_0947, 0                     @ id 1084
	.word song_0948, 0                     @ id 1085
	.word song_0949, 0                     @ id 1086
	.word song_0950, 0                     @ id 1087
	.word song_0951, 0                     @ id 1088
	.word song_0952, 0                     @ id 1089
	.word song_0953, 0                     @ id 1090
	.word song_0954, 0                     @ id 1091
	.word song_0955, 0                     @ id 1092
	.word song_0956, 0                     @ id 1093
	.word song_0957, 0                     @ id 1094
	.word song_0958, 0                     @ id 1095
	.word song_0959, 0                     @ id 1096
	.word song_0960, 0                     @ id 1097
	.word song_0961, 0                     @ id 1098
	.word song_0962, 0                     @ id 1099
	.word song_0963, 0                     @ id 1100
	.word song_0964, 0                     @ id 1101
	.word song_0965, 0                     @ id 1102
	.word song_0966, 0                     @ id 1103
	.word song_0967, 0                     @ id 1104
	.word song_0968, 0                     @ id 1105
	.word song_0969, 0                     @ id 1106
	.word 0, 0                             @ id 1107
	.word 0, 0                             @ id 1108
	.word 0, 0                             @ id 1109
	.word 0, 0                             @ id 1110
	.word 0, 0                             @ id 1111
	.word 0, 0                             @ id 1112
	.word 0, 0                             @ id 1113
	.word 0, 0                             @ id 1114
	.word 0, 0                             @ id 1115
	.word 0, 0                             @ id 1116
	.word song_0970, 0                     @ id 1117
	.word song_0971, 0                     @ id 1118
	.word song_0972, 1                     @ id 1119
	.word song_0973, 0                     @ id 1120
	.word song_0974, 1                     @ id 1121
	.word song_0975, 2                     @ id 1122
	.word song_0976, 2                     @ id 1123
	.word song_0977, 0                     @ id 1124
	.word song_0978, 0                     @ id 1125
	.word song_0979, 0                     @ id 1126
	.word song_0980, 0                     @ id 1127
	.word song_0981, 0                     @ id 1128
	.word song_0982, 0                     @ id 1129
	.word song_0983, 0                     @ id 1130
	.word song_0984, 0                     @ id 1131
	.word song_0985, 0                     @ id 1132
	.word song_0986, 0                     @ id 1133
	.word song_0987, 0                     @ id 1134
	.word song_0988, 0                     @ id 1135
	.word song_0989, 0                     @ id 1136
	.word song_0990, 0                     @ id 1137
	.word song_0991, 0                     @ id 1138
	.word song_0992, 0                     @ id 1139
	.word song_0993, 0                     @ id 1140
	.word song_0994, 0                     @ id 1141
	.word song_0995, 1                     @ id 1142
	.word song_0996, 1                     @ id 1143
	.word song_0997, 1                     @ id 1144
	.word 0, 0                             @ id 1145
	.word song_0998, 0                     @ id 1146
	.word song_0999, 0                     @ id 1147
	.word song_1000, 0                     @ id 1148
	.word 0, 0                             @ id 1149
	.word 0, 0                             @ id 1150
	.word 0, 0                             @ id 1151
	.word 0, 0                             @ id 1152
	.word 0, 0                             @ id 1153
	.word 0, 0                             @ id 1154
	.word 0, 0                             @ id 1155
	.word 0, 0                             @ id 1156
	.word 0, 0                             @ id 1157
	.word 0, 0                             @ id 1158
	.word 0, 0                             @ id 1159
	.word 0, 0                             @ id 1160
	.word 0, 0                             @ id 1161
	.word 0, 0                             @ id 1162
	.word 0, 0                             @ id 1163
	.word 0, 0                             @ id 1164
	.word 0, 0                             @ id 1165
	.word 0, 0                             @ id 1166
	.word 0, 0                             @ id 1167
	.word 0, 0                             @ id 1168
	.word 0, 0                             @ id 1169
	.word 0, 0                             @ id 1170
	.word 0, 0                             @ id 1171
	.word 0, 0                             @ id 1172
	.word 0, 0                             @ id 1173
	.word 0, 0                             @ id 1174
	.word 0, 0                             @ id 1175
	.word 0, 0                             @ id 1176
	.word 0, 0                             @ id 1177
	.word 0, 0                             @ id 1178
	.word 0, 0                             @ id 1179
	.word 0, 0                             @ id 1180
	.word 0, 0                             @ id 1181
	.word 0, 0                             @ id 1182
	.word 0, 0                             @ id 1183
	.word 0, 0                             @ id 1184
	.word 0, 0                             @ id 1185
	.word 0, 0                             @ id 1186
	.word 0, 0                             @ id 1187
	.word 0, 0                             @ id 1188
	.word 0, 0                             @ id 1189
	.word 0, 0                             @ id 1190
	.word 0, 0                             @ id 1191
	.word 0, 0                             @ id 1192
	.word 0, 0                             @ id 1193
	.word 0, 0                             @ id 1194
	.word 0, 0                             @ id 1195
	.word 0, 0                             @ id 1196
	.word 0, 0                             @ id 1197
	.word 0, 0                             @ id 1198
	.word 0, 0                             @ id 1199
	.word 0, 0                             @ id 1200
	.word 0, 0                             @ id 1201
	.word 0, 0                             @ id 1202
	.word 0, 0                             @ id 1203
	.word 0, 0                             @ id 1204
	.word 0, 0                             @ id 1205
	.word 0, 0                             @ id 1206
	.word 0, 0                             @ id 1207
	.word 0, 0                             @ id 1208
	.word 0, 0                             @ id 1209
	.word 0, 0                             @ id 1210
	.word 0, 0                             @ id 1211
	.word 0, 0                             @ id 1212
	.word 0, 0                             @ id 1213
	.word 0, 0                             @ id 1214
	.word 0, 0                             @ id 1215
	.word 0, 0                             @ id 1216
	.word 0, 0                             @ id 1217
	.word 0, 0                             @ id 1218
	.word 0, 0                             @ id 1219
	.word 0, 0                             @ id 1220
	.word 0, 0                             @ id 1221
	.word 0, 0                             @ id 1222
	.word 0, 0                             @ id 1223
	.word 0, 0                             @ id 1224
	.word 0, 0                             @ id 1225
	.word 0, 0                             @ id 1226
	.word 0, 0                             @ id 1227
	.word 0, 0                             @ id 1228
	.word 0, 0                             @ id 1229
	.word 0, 0                             @ id 1230
	.word 0, 0                             @ id 1231
	.word 0, 0                             @ id 1232
	.word 0, 0                             @ id 1233
	.word 0, 0                             @ id 1234
	.word 0, 0                             @ id 1235
	.word 0, 0                             @ id 1236
	.word 0, 0                             @ id 1237
	.word 0, 0                             @ id 1238
	.word 0, 0                             @ id 1239
	.word 0, 0                             @ id 1240
	.word 0, 0                             @ id 1241
	.word 0, 0                             @ id 1242
	.word 0, 0                             @ id 1243
	.word 0, 0                             @ id 1244
	.word 0, 0                             @ id 1245
	.word 0, 0                             @ id 1246
	.word 0, 0                             @ id 1247
	.word 0, 0                             @ id 1248
	.word song_1001, 0                     @ id 1249
	.word song_1002, 1                     @ id 1250
	.word song_1003, 1                     @ id 1251
	.word song_1004, 1                     @ id 1252
	.word song_1005, 1                     @ id 1253
	.word song_1006, 1                     @ id 1254
	.word song_1007, 1                     @ id 1255
	.word song_1008, 1                     @ id 1256
	.word song_1009, 3                     @ id 1257
	.word song_1010, 3                     @ id 1258
	.word song_1011, 4                     @ id 1259
	.word song_1012, 3                     @ id 1260
	.word song_1013, 3                     @ id 1261
	.word song_1014, 3                     @ id 1262
	.word 0, 0                             @ id 1263
	.word 0, 0                             @ id 1264
	.word 0, 0                             @ id 1265
	.word 0, 0                             @ id 1266
	.word 0, 0                             @ id 1267
	.word 0, 0                             @ id 1268
	.word 0, 0                             @ id 1269
	.word 0, 0                             @ id 1270
	.word 0, 0                             @ id 1271
	.word 0, 0                             @ id 1272
	.word 0, 0                             @ id 1273
	.word 0, 0                             @ id 1274
	.word 0, 0                             @ id 1275
	.word 0, 0                             @ id 1276
	.word 0, 0                             @ id 1277
	.word 0, 0                             @ id 1278
	.word 0, 0                             @ id 1279
	.word 0, 0                             @ id 1280
	.word 0, 0                             @ id 1281
	.word 0, 0                             @ id 1282
	.word 0, 0                             @ id 1283
	.word 0, 0                             @ id 1284
	.word 0, 0                             @ id 1285
	.word 0, 0                             @ id 1286
	.word 0, 0                             @ id 1287
	.word 0, 0                             @ id 1288
	.word 0, 0                             @ id 1289
	.word 0, 0                             @ id 1290
	.word 0, 0                             @ id 1291
	.word 0, 0                             @ id 1292
	.word 0, 0                             @ id 1293
	.word 0, 0                             @ id 1294
	.word 0, 0                             @ id 1295
	.word song_1015, 6                     @ id 1296
	.word song_1016, 6                     @ id 1297
	.word song_1017, 5                     @ id 1298
	.word song_1018, 4                     @ id 1299
	.word song_1019, 6                     @ id 1300
	.word song_1020, 5                     @ id 1301
	.word song_1021, 4                     @ id 1302
	.word song_1022, 3                     @ id 1303
	.word song_1023, 4                     @ id 1304
	.word song_1024, 6                     @ id 1305
	.word song_1025, 3                     @ id 1306
	.word song_1026, 3                     @ id 1307
	.word song_1027, 3                     @ id 1308
	.word song_1028, 4                     @ id 1309
	.word song_1029, 4                     @ id 1310
	.word song_1030, 4                     @ id 1311
	.word song_1031, 5                     @ id 1312
	.word song_1032, 6                     @ id 1313
	.word song_1033, 7                     @ id 1314
	.word song_1034, 6                     @ id 1315
	.word song_1035, 7                     @ id 1316
	.word song_1036, 4                     @ id 1317
	.word song_1037, 4                     @ id 1318
	.word song_1038, 3                     @ id 1319
	.word song_1039, 3                     @ id 1320
	.word song_1040, 4                     @ id 1321
	.word song_1041, 5                     @ id 1322
	.word song_1042, 4                     @ id 1323
	.word song_1043, 5                     @ id 1324
	.word song_1044, 5                     @ id 1325
	.word song_1045, 6                     @ id 1326
	.word song_1046, 7                     @ id 1327
	.word song_1047, 4                     @ id 1328
	.word song_1048, 4                     @ id 1329
	.word song_1049, 4                     @ id 1330
	.word song_1050, 5                     @ id 1331
	.word song_1051, 4                     @ id 1332
	.word song_1052, 6                     @ id 1333
	.word song_1053, 6                     @ id 1334
	.word song_1054, 6                     @ id 1335
	.word 0, 0                             @ id 1336
	.word 0, 0                             @ id 1337
	.word song_1055, 4                     @ id 1338
	.word song_1056, 6                     @ id 1339
	.word song_1057, 6                     @ id 1340
	.word song_1058, 5                     @ id 1341
	.word song_1059, 6                     @ id 1342
	.word song_1060, 3                     @ id 1343
	.word song_1061, 3                     @ id 1344
	.word song_1062, 5                     @ id 1345
	.word song_1063, 3                     @ id 1346
	.word song_1064, 4                     @ id 1347
	.word song_1065, 3                     @ id 1348
	.word song_1066, 3                     @ id 1349
	.word song_1067, 3                     @ id 1350
	.word song_1068, 3                     @ id 1351
	.word song_1069, 4                     @ id 1352
	.word song_1070, 3                     @ id 1353
	.word song_1071, 4                     @ id 1354
	.word song_1072, 4                     @ id 1355
	.word song_1073, 4                     @ id 1356
	.word song_1074, 4                     @ id 1357
	.word song_1075, 4                     @ id 1358
	.word song_1076, 4                     @ id 1359
	.word song_1077, 4                     @ id 1360
	.word song_1078, 4                     @ id 1361
	.word song_1079, 4                     @ id 1362
	.word song_1080, 4                     @ id 1363
	.word song_1081, 4                     @ id 1364
	.word song_1082, 4                     @ id 1365
	.word song_1083, 4                     @ id 1366
	.word song_1084, 4                     @ id 1367
	.word 0, 0                             @ id 1368
	.word 0, 0                             @ id 1369
	.word song_1085, 4                     @ id 1370
	.word song_1086, 4                     @ id 1371
	.word song_1087, 4                     @ id 1372
	.word song_1088, 4                     @ id 1373
	.word song_1089, 4                     @ id 1374
	.word song_1090, 4                     @ id 1375
	.word song_1091, 4                     @ id 1376
	.word song_1092, 4                     @ id 1377
	.word song_1093, 4                     @ id 1378
	.word song_1094, 4                     @ id 1379
	.word song_1095, 4                     @ id 1380
	.word song_1096, 4                     @ id 1381
	.word song_1097, 4                     @ id 1382
	.word song_1098, 4                     @ id 1383
	.word song_1099, 4                     @ id 1384
	.word song_1100, 4                     @ id 1385
	.word song_1101, 4                     @ id 1386
	.word song_1102, 4                     @ id 1387
	.word song_1103, 4                     @ id 1388
	.word song_1104, 4                     @ id 1389
	.word song_1105, 4                     @ id 1390
	.word song_1106, 4                     @ id 1391
	.word song_1107, 4                     @ id 1392
	.word song_1108, 4                     @ id 1393
	.word song_1109, 4                     @ id 1394
	.word song_1110, 4                     @ id 1395
	.word song_1111, 4                     @ id 1396
	.word song_1112, 4                     @ id 1397
	.word song_1113, 4                     @ id 1398
	.word song_1114, 4                     @ id 1399
	.word song_1115, 7                     @ id 1400
	.word song_1116, 7                     @ id 1401
	.word song_1117, 7                     @ id 1402
	.word song_1118, 7                     @ id 1403
	.word song_1119, 7                     @ id 1404
	.word song_1120, 7                     @ id 1405
	.word song_1121, 7                     @ id 1406
	.word song_1122, 7                     @ id 1407
	.word song_1123, 7                     @ id 1408
	.word song_1124, 7                     @ id 1409
	.word song_1125, 7                     @ id 1410
	.word song_1126, 7                     @ id 1411
	.word song_1127, 7                     @ id 1412
	.word song_1128, 7                     @ id 1413
	.word song_1129, 7                     @ id 1414
	.word song_1130, 7                     @ id 1415
	.word song_1131, 7                     @ id 1416
	.word song_1132, 7                     @ id 1417
	.word song_1133, 7                     @ id 1418
	.word song_1134, 7                     @ id 1419
	.word song_1135, 7                     @ id 1420
	.word song_1136, 7                     @ id 1421
	.word song_1137, 7                     @ id 1422
	.word song_1138, 7                     @ id 1423
	.word song_1139, 7                     @ id 1424
	.word song_1140, 7                     @ id 1425
	.word song_1141, 7                     @ id 1426
	.word song_1142, 7                     @ id 1427
	.word song_1143, 7                     @ id 1428
	.word song_1144, 7                     @ id 1429
	.word song_1145, 7                     @ id 1430
	.word song_1146, 7                     @ id 1431
	.word song_1147, 7                     @ id 1432
	.word song_1148, 7                     @ id 1433
	.word song_1149, 7                     @ id 1434
	.word 0, 0                             @ id 1435
	.word 0, 0                             @ id 1436
	.word 0, 0                             @ id 1437
	.word 0, 0                             @ id 1438
	.word 0, 0                             @ id 1439
	.word 0, 0                             @ id 1440
	.word 0, 0                             @ id 1441
	.word 0, 0                             @ id 1442
	.word 0, 0                             @ id 1443
	.word 0, 0                             @ id 1444
	.word 0, 0                             @ id 1445
	.word 0, 0                             @ id 1446
	.word 0, 0                             @ id 1447
	.word 0, 0                             @ id 1448
	.word 0, 0                             @ id 1449
	.word 0, 0                             @ id 1450
	.word 0, 0                             @ id 1451
	.word 0, 0                             @ id 1452
	.word 0, 0                             @ id 1453
	.word 0, 0                             @ id 1454
	.word song_1150, 7                     @ id 1455
	.word 0, 0                             @ id 1456
	.word 0, 0                             @ id 1457
	.word 0, 0                             @ id 1458
	.word 0, 0                             @ id 1459
	.word 0, 0                             @ id 1460
	.word 0, 0                             @ id 1461
	.word 0, 0                             @ id 1462
	.word 0, 0                             @ id 1463
	.word 0, 0                             @ id 1464
	.word 0, 0                             @ id 1465
	.word 0, 0                             @ id 1466
	.word 0, 0                             @ id 1467
	.word 0, 0                             @ id 1468
	.word 0, 0                             @ id 1469
	.word 0, 0                             @ id 1470
	.word 0, 0                             @ id 1471
	.word 0, 0                             @ id 1472
	.word 0, 0                             @ id 1473
	.word 0, 0                             @ id 1474
	.word 0, 0                             @ id 1475
	.word 0, 0                             @ id 1476
	.word 0, 0                             @ id 1477
	.word 0, 0                             @ id 1478
	.word 0, 0                             @ id 1479
	.word 0, 0                             @ id 1480
	.word 0, 0                             @ id 1481
	.word 0, 0                             @ id 1482
	.word 0, 0                             @ id 1483
	.word 0, 0                             @ id 1484
	.word 0, 0                             @ id 1485
	.word 0, 0                             @ id 1486
	.word 0, 0                             @ id 1487
	.word 0, 0                             @ id 1488
	.word 0, 0                             @ id 1489
	.word 0, 0                             @ id 1490
	.word 0, 0                             @ id 1491
	.word 0, 0                             @ id 1492
	.word 0, 0                             @ id 1493
	.word 0, 0                             @ id 1494
	.word 0, 0                             @ id 1495
	.word 0, 0                             @ id 1496
	.word 0, 0                             @ id 1497
	.word 0, 0                             @ id 1498
	.word 0, 0                             @ id 1499
	.word song_1151, 7                     @ id 1500
	.word song_1152, 7                     @ id 1501
	.word song_1153, 7                     @ id 1502
	.word song_1154, 7                     @ id 1503
	.word song_1155, 7                     @ id 1504
	.word song_1156, 7                     @ id 1505
	.word song_1157, 7                     @ id 1506
	.word song_1158, 7                     @ id 1507
	.word song_1159, 7                     @ id 1508
	.word song_1160, 7                     @ id 1509
	.word song_1161, 7                     @ id 1510
	.word song_1162, 7                     @ id 1511
	.word song_1163, 7                     @ id 1512
	.word 0, 0                             @ id 1513
	.word 0, 0                             @ id 1514
	.word 0, 0                             @ id 1515
	.word 0, 0                             @ id 1516
	.word 0, 0                             @ id 1517
	.word 0, 0                             @ id 1518
	.word 0, 0                             @ id 1519
	.word song_1164, 7                     @ id 1520
	.word song_1165, 7                     @ id 1521
	.word song_1166, 7                     @ id 1522
	.word song_1167, 7                     @ id 1523
	.word song_1168, 7                     @ id 1524
	.word song_1169, 7                     @ id 1525
	.word song_1170, 7                     @ id 1526
	.word song_1171, 7                     @ id 1527
	.word song_1172, 7                     @ id 1528
	.word song_1173, 7                     @ id 1529
	.word 0, 0                             @ id 1530
	.word 0, 0                             @ id 1531
	.word 0, 0                             @ id 1532
	.word 0, 0                             @ id 1533
	.word 0, 0                             @ id 1534
	.word 0, 0                             @ id 1535
	.word 0, 0                             @ id 1536
	.word 0, 0                             @ id 1537
	.word 0, 0                             @ id 1538
	.word 0, 0                             @ id 1539
	.word song_1174, 7                     @ id 1540
	.word song_1175, 7                     @ id 1541
	.word song_1176, 7                     @ id 1542
	.word song_1177, 7                     @ id 1543
	.word song_1178, 7                     @ id 1544
	.word song_1179, 7                     @ id 1545
	.word song_1180, 7                     @ id 1546
	.word song_1181, 7                     @ id 1547
	.word song_1182, 7                     @ id 1548
	.word song_1183, 7                     @ id 1549
	.word song_1184, 7                     @ id 1550
	.word song_1185, 7                     @ id 1551
	.word song_1186, 7                     @ id 1552
	.word song_1187, 7                     @ id 1553
	.word song_1188, 7                     @ id 1554
	.word song_1189, 7                     @ id 1555
	.word 0, 0                             @ id 1556
	.word 0, 0                             @ id 1557
	.word 0, 0                             @ id 1558
	.word 0, 0                             @ id 1559
	.word song_1190, 7                     @ id 1560
	.word song_1191, 7                     @ id 1561
	.word song_1192, 7                     @ id 1562
	.word song_1193, 7                     @ id 1563
	.word song_1194, 7                     @ id 1564
	.word song_1195, 7                     @ id 1565
	.word song_1196, 7                     @ id 1566
	.word song_1197, 7                     @ id 1567
	.word song_1198, 7                     @ id 1568
	.word song_1199, 7                     @ id 1569
	.word song_1200, 7                     @ id 1570
	.word 0, 0                             @ id 1571
	.word 0, 0                             @ id 1572
	.word 0, 0                             @ id 1573
	.word 0, 0                             @ id 1574
	.word 0, 0                             @ id 1575
	.word 0, 0                             @ id 1576
	.word 0, 0                             @ id 1577
	.word 0, 0                             @ id 1578
	.word 0, 0                             @ id 1579
	.word song_1201, 7                     @ id 1580
	.word song_1202, 7                     @ id 1581
	.word song_1203, 7                     @ id 1582
	.word 0, 0                             @ id 1583
	.word 0, 0                             @ id 1584
	.word 0, 0                             @ id 1585
	.word 0, 0                             @ id 1586
	.word 0, 0                             @ id 1587
	.word 0, 0                             @ id 1588
	.word 0, 0                             @ id 1589
	.word song_1204, 8                     @ id 1590
	.word song_1205, 8                     @ id 1591
	.word song_1206, 8                     @ id 1592
	.word song_1207, 8                     @ id 1593
	.word song_1208, 8                     @ id 1594
	.word song_1209, 8                     @ id 1595
	.word song_1210, 8                     @ id 1596
	.word song_1211, 8                     @ id 1597
	.word song_1212, 8                     @ id 1598
	.word song_1213, 8                     @ id 1599
	.word song_1214, 8                     @ id 1600
	.word song_1215, 8                     @ id 1601
	.word song_1216, 8                     @ id 1602
	.word song_1217, 8                     @ id 1603
	.word song_1218, 8                     @ id 1604
	.word song_1219, 8                     @ id 1605
	.word song_1220, 8                     @ id 1606
	.word song_1221, 8                     @ id 1607
	.word song_1222, 8                     @ id 1608
	.word song_1223, 8                     @ id 1609
	.word song_1224, 8                     @ id 1610
	.word song_1225, 8                     @ id 1611
	.word song_1226, 8                     @ id 1612
	.word song_1227, 8                     @ id 1613
	.word 0, 0                             @ id 1614
	.word 0, 0                             @ id 1615
	.word 0, 0                             @ id 1616
	.word 0, 0                             @ id 1617
	.word 0, 0                             @ id 1618
	.word 0, 0                             @ id 1619
	.word song_1228, 7                     @ id 1620
	.word song_1229, 7                     @ id 1621
	.word song_1230, 7                     @ id 1622
	.word song_1231, 7                     @ id 1623
	.word song_1232, 7                     @ id 1624
	.word song_1233, 7                     @ id 1625
	.word song_1234, 7                     @ id 1626
	.word song_1235, 7                     @ id 1627
	.word song_1236, 7                     @ id 1628
	.word song_1237, 7                     @ id 1629
	.word song_1238, 7                     @ id 1630
	.word song_1239, 7                     @ id 1631
	.word song_1240, 7                     @ id 1632
	.word song_1241, 7                     @ id 1633
	.word 0, 0                             @ id 1634
	.word 0, 0                             @ id 1635
	.word 0, 0                             @ id 1636
	.word 0, 0                             @ id 1637
	.word 0, 0                             @ id 1638
	.word 0, 0                             @ id 1639
	.word song_1242, 7                     @ id 1640
	.word song_1243, 7                     @ id 1641
	.word song_1244, 7                     @ id 1642
	.word song_1245, 7                     @ id 1643
	.word song_1246, 7                     @ id 1644
	.word song_1247, 7                     @ id 1645
	.word song_1248, 7                     @ id 1646
	.word song_1249, 7                     @ id 1647
	.word song_1250, 7                     @ id 1648
	.word song_1251, 7                     @ id 1649
	.word 0, 0                             @ id 1650
	.word song_1252, 7                     @ id 1651
	.word song_1253, 7                     @ id 1652
	.word song_1254, 7                     @ id 1653
	.word song_1255, 7                     @ id 1654
	.word song_1256, 7                     @ id 1655
	.word song_1257, 7                     @ id 1656
	.word song_1258, 7                     @ id 1657
	.word song_1259, 7                     @ id 1658
	.word song_1260, 7                     @ id 1659
	.word song_1261, 7                     @ id 1660
	.word 0, 0                             @ id 1661
	.word song_1262, 7                     @ id 1662
	.word song_1263, 7                     @ id 1663
	.word song_1264, 7                     @ id 1664
	.word song_1265, 7                     @ id 1665
	.word song_1266, 7                     @ id 1666
	.word song_1267, 7                     @ id 1667
	.word 0, 0                             @ id 1668
	.word 0, 0                             @ id 1669
	.word song_1268, 8                     @ id 1670
	.word song_1269, 8                     @ id 1671
	.word song_1270, 8                     @ id 1672
	.word song_1271, 8                     @ id 1673
	.word song_1272, 8                     @ id 1674
	.word song_1273, 8                     @ id 1675
	.word song_1274, 8                     @ id 1676
	.word song_1275, 8                     @ id 1677
	.word song_1276, 8                     @ id 1678
	.word song_1277, 8                     @ id 1679
	.word song_1278, 8                     @ id 1680
	.word song_1279, 8                     @ id 1681
	.word song_1280, 8                     @ id 1682
	.word song_1281, 8                     @ id 1683
	.word song_1282, 8                     @ id 1684
	.word song_1283, 8                     @ id 1685
	.word song_1284, 8                     @ id 1686
	.word song_1285, 8                     @ id 1687
	.word song_1286, 8                     @ id 1688
	.word song_1287, 8                     @ id 1689
	.word song_1288, 7                     @ id 1690
	.word song_1289, 7                     @ id 1691
	.word song_1290, 7                     @ id 1692
	.word song_1291, 7                     @ id 1693
	.word song_1292, 7                     @ id 1694
	.word song_1293, 7                     @ id 1695
	.word song_1294, 7                     @ id 1696
	.word song_1295, 7                     @ id 1697
	.word song_1296, 7                     @ id 1698
	.word song_1297, 7                     @ id 1699
	.word song_1298, 7                     @ id 1700
	.word song_1299, 7                     @ id 1701
	.word song_1300, 7                     @ id 1702
	.word song_1301, 7                     @ id 1703
	.word song_1302, 7                     @ id 1704
	.word song_1303, 7                     @ id 1705
	.word song_1304, 7                     @ id 1706
	.word 0, 0                             @ id 1707
	.word 0, 0                             @ id 1708
	.word 0, 0                             @ id 1709
	.word 0, 0                             @ id 1710
	.word 0, 0                             @ id 1711
	.word 0, 0                             @ id 1712
	.word 0, 0                             @ id 1713
	.word 0, 0                             @ id 1714
	.word 0, 0                             @ id 1715
	.word 0, 0                             @ id 1716
	.word 0, 0                             @ id 1717
	.word 0, 0                             @ id 1718
	.word 0, 0                             @ id 1719
	.word 0, 0                             @ id 1720
	.word 0, 0                             @ id 1721
	.word 0, 0                             @ id 1722
	.word 0, 0                             @ id 1723
	.word 0, 0                             @ id 1724
	.word 0, 0                             @ id 1725
	.word 0, 0                             @ id 1726
	.word 0, 0                             @ id 1727
	.word 0, 0                             @ id 1728
	.word 0, 0                             @ id 1729
	.word 0, 0                             @ id 1730
	.word 0, 0                             @ id 1731
	.word 0, 0                             @ id 1732
	.word 0, 0                             @ id 1733
	.word 0, 0                             @ id 1734
	.word 0, 0                             @ id 1735
	.word 0, 0                             @ id 1736
	.word 0, 0                             @ id 1737
	.word 0, 0                             @ id 1738
	.word 0, 0                             @ id 1739
	.word 0, 0                             @ id 1740
	.word 0, 0                             @ id 1741
	.word 0, 0                             @ id 1742
	.word 0, 0                             @ id 1743
	.word 0, 0                             @ id 1744
	.word 0, 0                             @ id 1745
	.word 0, 0                             @ id 1746
	.word 0, 0                             @ id 1747
	.word 0, 0                             @ id 1748
	.word 0, 0                             @ id 1749
	.word 0, 0                             @ id 1750
	.word 0, 0                             @ id 1751
	.word 0, 0                             @ id 1752
	.word 0, 0                             @ id 1753
	.word 0, 0                             @ id 1754
	.word 0, 0                             @ id 1755
	.word 0, 0                             @ id 1756
	.word 0, 0                             @ id 1757
	.word 0, 0                             @ id 1758
	.word 0, 0                             @ id 1759
	.word 0, 0                             @ id 1760
	.word 0, 0                             @ id 1761
	.word 0, 0                             @ id 1762
	.word 0, 0                             @ id 1763
	.word 0, 0                             @ id 1764
	.word 0, 0                             @ id 1765
	.word 0, 0                             @ id 1766
	.word 0, 0                             @ id 1767
	.word 0, 0                             @ id 1768
	.word 0, 0                             @ id 1769
	.word 0, 0                             @ id 1770
	.word 0, 0                             @ id 1771
	.word 0, 0                             @ id 1772
	.word 0, 0                             @ id 1773
	.word 0, 0                             @ id 1774
	.word 0, 0                             @ id 1775
	.word 0, 0                             @ id 1776
	.word 0, 0                             @ id 1777
	.word 0, 0                             @ id 1778
	.word 0, 0                             @ id 1779
	.word 0, 0                             @ id 1780
	.word 0, 0                             @ id 1781
	.word 0, 0                             @ id 1782
	.word 0, 0                             @ id 1783
	.word 0, 0                             @ id 1784
	.word 0, 0                             @ id 1785
	.word 0, 0                             @ id 1786
	.word 0, 0                             @ id 1787
	.word 0, 0                             @ id 1788
	.word 0, 0                             @ id 1789
	.word 0, 0                             @ id 1790
	.word 0, 0                             @ id 1791
	.word 0, 0                             @ id 1792
	.word 0, 0                             @ id 1793
	.word 0, 0                             @ id 1794
	.word 0, 0                             @ id 1795
	.word 0, 0                             @ id 1796
	.word 0, 0                             @ id 1797
	.word 0, 0                             @ id 1798
	.word 0, 0                             @ id 1799
	.word 0, 0                             @ id 1800
	.word 0, 0                             @ id 1801
	.word 0, 0                             @ id 1802
	.word 0, 0                             @ id 1803
	.word 0, 0                             @ id 1804
	.word 0, 0                             @ id 1805
	.word 0, 0                             @ id 1806
	.word 0, 0                             @ id 1807
	.word 0, 0                             @ id 1808
	.word 0, 0                             @ id 1809
	.word song_1305, 3                     @ id 1810
	.word song_1306, 3                     @ id 1811
	.word song_1307, 3                     @ id 1812
	.word song_1308, 3                     @ id 1813
	.word song_1309, 3                     @ id 1814
	.word song_1310, 3                     @ id 1815
	.word song_1311, 3                     @ id 1816
	.word song_1312, 3                     @ id 1817
	.word song_1313, 3                     @ id 1818
	.word song_1314, 3                     @ id 1819
	.word song_1315, 3                     @ id 1820
	.word song_1316, 3                     @ id 1821
	.word song_1317, 7                     @ id 1822
	.word song_1318, 7                     @ id 1823
	.word song_1319, 7                     @ id 1824
	.word song_1320, 3                     @ id 1825
	.word song_1321, 3                     @ id 1826
	.word song_1322, 3                     @ id 1827
	.word song_1323, 3                     @ id 1828
	.word song_1324, 3                     @ id 1829
	.word song_1325, 3                     @ id 1830
	.word song_1326, 7                     @ id 1831
	.word song_1327, 7                     @ id 1832
	.word song_1328, 7                     @ id 1833
	.word song_1329, 7                     @ id 1834
	.word song_1330, 7                     @ id 1835
	.word song_1331, 7                     @ id 1836
	.word song_1332, 3                     @ id 1837
	.word song_1333, 3                     @ id 1838
	.word song_1334, 3                     @ id 1839
	.word song_1335, 1                     @ id 1840
	.word song_1336, 2                     @ id 1841
	.word song_1337, 3                     @ id 1842
	.word song_1338, 4                     @ id 1843
	.word song_1339, 5                     @ id 1844
	.word song_1340, 6                     @ id 1845
	.word song_1341, 7                     @ id 1846

	.global sndLastPlayer
sndLastPlayer:  .word 8              @ number of players - 1
	.global sndConfig
sndConfig:      .byte 1, 3, 127, 0     @ live-MIDI player: enabled, bank, volume, priority
	.word 150                          @ live-MIDI player tempo (BPM)
	.global sndPlayers
sndPlayers:
	.word 0x03000EB4
	.word 0x03000EE4
	.word 0x03000F14
	.word 0x03000F44
	.word 0x03000F74
	.word 0x03000FA4
	.word 0x03000FD4
	.word 0x03001004
	.word 0x03001034
	.global sndPlayerConfig
sndPlayerConfig:   @ {u16 bits (0-4 index, 5-9 channels = max tracks, 10 priority check); u16 0; Chan *chans; Synth *synth; Track *tracks; Player *player}
	player_cfg index=0, channels=12, prio_check=0, chans=0x030022A8, synth=0x03002428, tracks=0x03002450, player=0x03000EB4
	player_cfg index=1, channels=12, prio_check=0, chans=0x03002600, synth=0x03002780, tracks=0x030027A8, player=0x03000EE4
	player_cfg index=2, channels=12, prio_check=0, chans=0x03002958, synth=0x03002AD8, tracks=0x03002B00, player=0x03000F14
	player_cfg index=3, channels=9, prio_check=1, chans=0x03002CB0, synth=0x03002DD0, tracks=0x03002DF8, player=0x03000F44
	player_cfg index=4, channels=5, prio_check=1, chans=0x03002F40, synth=0x03002FE0, tracks=0x03003008, player=0x03000F74
	player_cfg index=5, channels=5, prio_check=1, chans=0x030030C0, synth=0x03003160, tracks=0x03003188, player=0x03000FA4
	player_cfg index=6, channels=5, prio_check=1, chans=0x03003240, synth=0x030032E0, tracks=0x03003308, player=0x03000FD4
	player_cfg index=7, channels=3, prio_check=1, chans=0x030033C0, synth=0x03003420, tracks=0x03003448, player=0x03001004
	player_cfg index=8, channels=3, prio_check=1, chans=0x030034B8, synth=0x03003518, tracks=0x03003540, player=0x03001034
	.global sndGroupCount
sndGroupCount:  .word 9
	.global sndGroups
sndGroups:   @ {Player *player; u32 0; u16 channels; u16 priorityCheck}: sound id -> player (only the pointer is read)
	.word 0x03000EB4, 0
	.hword 12, 0
	.word 0x03000EE4, 0
	.hword 12, 0
	.word 0x03000F14, 0
	.hword 12, 0
	.word 0x03000F44, 0
	.hword 9, 1
	.word 0x03000F74, 0
	.hword 5, 1
	.word 0x03000FA4, 0
	.hword 5, 1
	.word 0x03000FD4, 0
	.hword 5, 1
	.word 0x03001004, 0
	.hword 3, 1
	.word 0x03001034, 0
	.hword 3, 1

	.global sndSampleHeaders
sndSampleHeaders:   @ 711 x {u32 length; u32 rate (Hz); u32 rootKey; u32 loopStart; u32 loopEnd; s8 *pcm}
smp_000:	sample_hdr length=2779, rate=10512, root=55, loop_start=2544, loop_end=2705, pcm=smp_000_pcm   @ loop 2544-2705
smp_001:	sample_hdr length=2471, rate=10512, root=67, loop_start=2245, loop_end=2459, pcm=smp_001_pcm   @ loop 2245-2459
smp_002:	sample_hdr length=4749, rate=13379, root=60, loop_start=1262, loop_end=2693, pcm=smp_002_pcm   @ loop 1262-2693
smp_003:	sample_hdr length=1190, rate=13379, root=55, loop_start=0, loop_end=0, pcm=smp_003_pcm   @ no loop
smp_004:	sample_hdr length=709, rate=13379, root=83, loop_start=1, loop_end=528, pcm=smp_004_pcm   @ loop 1-528
smp_005:	sample_hdr length=7104, rate=13379, root=91, loop_start=1329, loop_end=2720, pcm=smp_005_pcm   @ loop 1329-2720
smp_006:	sample_hdr length=9632, rate=13379, root=115, loop_start=2151, loop_end=3217, pcm=smp_006_pcm   @ loop 2151-3217
smp_007:	sample_hdr length=10636, rate=13379, root=70, loop_start=2827, loop_end=9409, pcm=smp_007_pcm   @ loop 2827-9409
smp_008:	sample_hdr length=1618, rate=13379, root=52, loop_start=227, loop_end=1382, pcm=smp_008_pcm   @ loop 227-1382
smp_009:	sample_hdr length=2261, rate=13379, root=70, loop_start=0, loop_end=0, pcm=smp_009_pcm   @ no loop
smp_010:	sample_hdr length=4348, rate=13379, root=80, loop_start=16, loop_end=3894, pcm=smp_010_pcm   @ loop 16-3894
smp_011:	sample_hdr length=5498, rate=13379, root=72, loop_start=1279, loop_end=2097, pcm=smp_011_pcm   @ loop 1279-2097
smp_012:	sample_hdr length=659, rate=13379, root=60, loop_start=0, loop_end=155, pcm=smp_012_pcm   @ loop 0-155
smp_013:	sample_hdr length=3224, rate=13379, root=52, loop_start=25, loop_end=2173, pcm=smp_013_pcm   @ loop 25-2173
smp_014:	sample_hdr length=9355, rate=10512, root=84, loop_start=5, loop_end=8997, pcm=smp_014_pcm   @ loop 5-8997
smp_015:	sample_hdr length=128, rate=22050, root=60, loop_start=12, loop_end=96, pcm=smp_015_pcm   @ loop 12-96
smp_016:	sample_hdr length=308, rate=13379, root=60, loop_start=0, loop_end=51, pcm=smp_016_pcm   @ loop 0-51
smp_017:	sample_hdr length=9442, rate=10512, root=60, loop_start=1507, loop_end=2842, pcm=smp_017_pcm   @ loop 1507-2842
smp_018:	sample_hdr length=1276, rate=10512, root=57, loop_start=436, loop_end=1161, pcm=smp_018_pcm   @ loop 436-1161
smp_019:	sample_hdr length=9011, rate=10512, root=60, loop_start=2679, loop_end=3566, pcm=smp_019_pcm   @ loop 2679-3566
smp_020:	sample_hdr length=3459, rate=10512, root=57, loop_start=2229, loop_end=2667, pcm=smp_020_pcm   @ loop 2229-2667
smp_021:	sample_hdr length=6710, rate=10512, root=60, loop_start=2446, loop_end=3485, pcm=smp_021_pcm   @ loop 2446-3485
smp_022:	sample_hdr length=1345, rate=10512, root=72, loop_start=212, loop_end=1295, pcm=smp_022_pcm   @ loop 212-1295
smp_023:	sample_hdr length=488, rate=13379, root=60, loop_start=9, loop_end=156, pcm=smp_023_pcm   @ loop 9-156
smp_024:	sample_hdr length=3917, rate=13379, root=60, loop_start=896, loop_end=2206, pcm=smp_024_pcm   @ loop 896-2206
smp_025:	sample_hdr length=1308, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_025_pcm   @ no loop
smp_026:	sample_hdr length=6997, rate=13379, root=60, loop_start=391, loop_end=1978, pcm=smp_026_pcm   @ loop 391-1978
smp_027:	sample_hdr length=4896, rate=10512, root=60, loop_start=948, loop_end=1189, pcm=smp_027_pcm   @ loop 948-1189
smp_028:	sample_hdr length=5030, rate=13379, root=60, loop_start=1240, loop_end=1341, pcm=smp_028_pcm   @ loop 1240-1341
smp_029:	sample_hdr length=3138, rate=13379, root=72, loop_start=494, loop_end=1692, pcm=smp_029_pcm   @ loop 494-1692
smp_030:	sample_hdr length=2252, rate=13379, root=64, loop_start=565, loop_end=1924, pcm=smp_030_pcm   @ loop 565-1924
smp_031:	sample_hdr length=2441, rate=10512, root=55, loop_start=651, loop_end=1000, pcm=smp_031_pcm   @ loop 651-1000
smp_032:	sample_hdr length=24893, rate=10512, root=72, loop_start=534, loop_end=3141, pcm=smp_032_pcm   @ loop 534-3141
smp_033:	sample_hdr length=997, rate=3200, root=60, loop_start=360, loop_end=581, pcm=smp_033_pcm   @ loop 360-581
smp_034:	sample_hdr length=772, rate=3200, root=60, loop_start=244, loop_end=429, pcm=smp_034_pcm   @ loop 244-429
smp_035:	sample_hdr length=1049, rate=3200, root=60, loop_start=138, loop_end=504, pcm=smp_035_pcm   @ loop 138-504
smp_036:	sample_hdr length=1496, rate=3200, root=60, loop_start=464, loop_end=697, pcm=smp_036_pcm   @ loop 464-697
smp_037:	sample_hdr length=948, rate=3200, root=60, loop_start=459, loop_end=609, pcm=smp_037_pcm   @ loop 459-609
smp_038:	sample_hdr length=898, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_038_pcm   @ no loop
smp_039:	sample_hdr length=6119, rate=10512, root=60, loop_start=2098, loop_end=3458, pcm=smp_039_pcm   @ loop 2098-3458
smp_040:	sample_hdr length=7243, rate=10512, root=60, loop_start=1854, loop_end=2625, pcm=smp_040_pcm   @ loop 1854-2625
smp_041:	sample_hdr length=2368, rate=13379, root=72, loop_start=2148, loop_end=2276, pcm=smp_041_pcm   @ loop 2148-2276
smp_042:	sample_hdr length=777, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_042_pcm   @ no loop
smp_043:	sample_hdr length=1713, rate=10512, root=72, loop_start=0, loop_end=1705, pcm=smp_043_pcm   @ loop 0-1705
smp_044:	sample_hdr length=1923, rate=10512, root=72, loop_start=0, loop_end=1921, pcm=smp_044_pcm   @ loop 0-1921
smp_045:	sample_hdr length=2224, rate=13379, root=60, loop_start=1280, loop_end=1689, pcm=smp_045_pcm   @ loop 1280-1689
smp_046:	sample_hdr length=4482, rate=10512, root=60, loop_start=424, loop_end=2032, pcm=smp_046_pcm   @ loop 424-2032
smp_047:	sample_hdr length=4607, rate=10512, root=60, loop_start=178, loop_end=1754, pcm=smp_047_pcm   @ loop 178-1754
smp_048:	sample_hdr length=4789, rate=13379, root=72, loop_start=2124, loop_end=3042, pcm=smp_048_pcm   @ loop 2124-3042
smp_049:	sample_hdr length=4478, rate=10512, root=72, loop_start=2255, loop_end=3360, pcm=smp_049_pcm   @ loop 2255-3360
smp_050:	sample_hdr length=7930, rate=13379, root=60, loop_start=2906, loop_end=4440, pcm=smp_050_pcm   @ loop 2906-4440
smp_051:	sample_hdr length=10653, rate=13379, root=60, loop_start=2410, loop_end=3895, pcm=smp_051_pcm   @ loop 2410-3895
smp_052:	sample_hdr length=5085, rate=10512, root=60, loop_start=2474, loop_end=2997, pcm=smp_052_pcm   @ loop 2474-2997
smp_053:	sample_hdr length=17316, rate=10512, root=60, loop_start=4834, loop_end=6564, pcm=smp_053_pcm   @ loop 4834-6564
smp_054:	sample_hdr length=21710, rate=13379, root=55, loop_start=5211, loop_end=7125, pcm=smp_054_pcm   @ loop 5211-7125
smp_055:	sample_hdr length=2047, rate=13379, root=60, loop_start=899, loop_end=1207, pcm=smp_055_pcm   @ loop 899-1207
smp_056:	sample_hdr length=4952, rate=13379, root=55, loop_start=2411, loop_end=3912, pcm=smp_056_pcm   @ loop 2411-3912
smp_057:	sample_hdr length=4949, rate=7884, root=60, loop_start=4002, loop_end=4213, pcm=smp_057_pcm   @ loop 4002-4213
smp_058:	sample_hdr length=4246, rate=7884, root=55, loop_start=2274, loop_end=2435, pcm=smp_058_pcm   @ loop 2274-2435
smp_059:	sample_hdr length=2261, rate=13379, root=72, loop_start=979, loop_end=1593, pcm=smp_059_pcm   @ loop 979-1593
smp_060:	sample_hdr length=6152, rate=13379, root=60, loop_start=1677, loop_end=3315, pcm=smp_060_pcm   @ loop 1677-3315
smp_061:	sample_hdr length=5937, rate=13379, root=72, loop_start=1077, loop_end=3659, pcm=smp_061_pcm   @ loop 1077-3659
smp_062:	sample_hdr length=1577, rate=5734, root=52, loop_start=68, loop_end=1440, pcm=smp_062_pcm   @ loop 68-1440
smp_063:	sample_hdr length=3982, rate=13379, root=60, loop_start=1472, loop_end=1881, pcm=smp_063_pcm   @ loop 1472-1881
smp_064:	sample_hdr length=6769, rate=10512, root=60, loop_start=715, loop_end=2796, pcm=smp_064_pcm   @ loop 715-2796
smp_065:	sample_hdr length=7017, rate=5734, root=72, loop_start=1222, loop_end=2120, pcm=smp_065_pcm   @ loop 1222-2120
smp_066:	sample_hdr length=2283, rate=13379, root=67, loop_start=527, loop_end=1344, pcm=smp_066_pcm   @ loop 527-1344
smp_067:	sample_hdr length=8230, rate=13379, root=77, loop_start=2376, loop_end=3105, pcm=smp_067_pcm   @ loop 2376-3105
smp_068:	sample_hdr length=4194, rate=10512, root=72, loop_start=638, loop_end=4091, pcm=smp_068_pcm   @ loop 638-4091
smp_069:	sample_hdr length=5169, rate=7884, root=60, loop_start=886, loop_end=3188, pcm=smp_069_pcm   @ loop 886-3188
smp_070:	sample_hdr length=12656, rate=10512, root=48, loop_start=2670, loop_end=4273, pcm=smp_070_pcm   @ loop 2670-4273
smp_071:	sample_hdr length=653, rate=44100, root=60, loop_start=147, loop_end=399, pcm=smp_071_pcm   @ loop 147-399
smp_072:	sample_hdr length=2509, rate=13379, root=69, loop_start=716, loop_end=2430, pcm=smp_072_pcm   @ loop 716-2430
smp_073:	sample_hdr length=3585, rate=13379, root=65, loop_start=101, loop_end=2133, pcm=smp_073_pcm   @ loop 101-2133
smp_074:	sample_hdr length=2449, rate=10512, root=79, loop_start=530, loop_end=1527, pcm=smp_074_pcm   @ loop 530-1527
smp_075:	sample_hdr length=923, rate=10512, root=60, loop_start=316, loop_end=477, pcm=smp_075_pcm   @ loop 316-477
smp_076:	sample_hdr length=1986, rate=10512, root=60, loop_start=455, loop_end=1937, pcm=smp_076_pcm   @ loop 455-1937
smp_077:	sample_hdr length=347, rate=13379, root=67, loop_start=0, loop_end=34, pcm=smp_077_pcm   @ loop 0-34
smp_078:	sample_hdr length=4695, rate=10512, root=60, loop_start=2877, loop_end=3361, pcm=smp_078_pcm   @ loop 2877-3361
smp_079:	sample_hdr length=8923, rate=13379, root=60, loop_start=1330, loop_end=3836, pcm=smp_079_pcm   @ loop 1330-3836
smp_080:	sample_hdr length=1846, rate=13379, root=67, loop_start=898, loop_end=1442, pcm=smp_080_pcm   @ loop 898-1442
smp_081:	sample_hdr length=5470, rate=13379, root=60, loop_start=574, loop_end=2723, pcm=smp_081_pcm   @ loop 574-2723
smp_082:	sample_hdr length=8525, rate=13379, root=60, loop_start=3619, loop_end=4030, pcm=smp_082_pcm   @ loop 3619-4030
smp_083:	sample_hdr length=4137, rate=10512, root=72, loop_start=1101, loop_end=2226, pcm=smp_083_pcm   @ loop 1101-2226
smp_084:	sample_hdr length=2491, rate=10512, root=60, loop_start=81, loop_end=1354, pcm=smp_084_pcm   @ loop 81-1354
smp_085:	sample_hdr length=5763, rate=13379, root=60, loop_start=2017, loop_end=3437, pcm=smp_085_pcm   @ loop 2017-3437
smp_086:	sample_hdr length=1170, rate=13379, root=60, loop_start=110, loop_end=850, pcm=smp_086_pcm   @ loop 110-850
smp_087:	sample_hdr length=836, rate=13379, root=60, loop_start=14, loop_end=720, pcm=smp_087_pcm   @ loop 14-720
smp_088:	sample_hdr length=2539, rate=13379, root=65, loop_start=0, loop_end=0, pcm=smp_088_pcm   @ no loop
smp_089:	sample_hdr length=1898, rate=13379, root=60, loop_start=524, loop_end=1123, pcm=smp_089_pcm   @ loop 524-1123
smp_090:	sample_hdr length=1335, rate=13379, root=60, loop_start=463, loop_end=947, pcm=smp_090_pcm   @ loop 463-947
smp_091:	sample_hdr length=2297, rate=13379, root=60, loop_start=481, loop_end=944, pcm=smp_091_pcm   @ loop 481-944
smp_092:	sample_hdr length=882, rate=13379, root=60, loop_start=100, loop_end=531, pcm=smp_092_pcm   @ loop 100-531
smp_093:	sample_hdr length=456, rate=13379, root=60, loop_start=62, loop_end=272, pcm=smp_093_pcm   @ loop 62-272
smp_094:	sample_hdr length=955, rate=13379, root=60, loop_start=38, loop_end=791, pcm=smp_094_pcm   @ loop 38-791
smp_095:	sample_hdr length=1578, rate=13379, root=65, loop_start=0, loop_end=1577, pcm=smp_095_pcm   @ loop 0-1577
smp_096:	sample_hdr length=4011, rate=13379, root=65, loop_start=752, loop_end=2000, pcm=smp_096_pcm   @ loop 752-2000
smp_097:	sample_hdr length=4428, rate=13379, root=67, loop_start=723, loop_end=2230, pcm=smp_097_pcm   @ loop 723-2230
smp_098:	sample_hdr length=2976, rate=10512, root=60, loop_start=10, loop_end=2258, pcm=smp_098_pcm   @ loop 10-2258
smp_099:	sample_hdr length=2142, rate=13379, root=67, loop_start=9, loop_end=1785, pcm=smp_099_pcm   @ loop 9-1785
smp_100:	sample_hdr length=2162, rate=13379, root=67, loop_start=4, loop_end=1842, pcm=smp_100_pcm   @ loop 4-1842
smp_101:	sample_hdr length=2425, rate=13379, root=67, loop_start=7, loop_end=2205, pcm=smp_101_pcm   @ loop 7-2205
smp_102:	sample_hdr length=1208, rate=13379, root=67, loop_start=4, loop_end=965, pcm=smp_102_pcm   @ loop 4-965
smp_103:	sample_hdr length=2520, rate=13379, root=67, loop_start=1004, loop_end=1965, pcm=smp_103_pcm   @ loop 1004-1965
smp_104:	sample_hdr length=2199, rate=13379, root=67, loop_start=5, loop_end=1664, pcm=smp_104_pcm   @ loop 5-1664
smp_105:	sample_hdr length=3164, rate=13379, root=65, loop_start=2194, loop_end=2867, pcm=smp_105_pcm   @ loop 2194-2867
smp_106:	sample_hdr length=2538, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_106_pcm   @ no loop
smp_107:	sample_hdr length=3826, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_107_pcm   @ no loop
smp_108:	sample_hdr length=1355, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_108_pcm   @ no loop
smp_109:	sample_hdr length=2906, rate=13379, root=60, loop_start=600, loop_end=1887, pcm=smp_109_pcm   @ loop 600-1887
smp_110:	sample_hdr length=1818, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_110_pcm   @ no loop
smp_111:	sample_hdr length=2874, rate=13379, root=60, loop_start=1375, loop_end=1503, pcm=smp_111_pcm   @ loop 1375-1503
smp_112:	sample_hdr length=1151, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_112_pcm   @ no loop
smp_113:	sample_hdr length=3057, rate=13379, root=67, loop_start=1000, loop_end=1627, pcm=smp_113_pcm   @ loop 1000-1627
smp_114:	sample_hdr length=6823, rate=13379, root=62, loop_start=1135, loop_end=2719, pcm=smp_114_pcm   @ loop 1135-2719
smp_115:	sample_hdr length=2671, rate=13379, root=60, loop_start=1077, loop_end=2351, pcm=smp_115_pcm   @ loop 1077-2351
smp_116:	sample_hdr length=2967, rate=10512, root=60, loop_start=434, loop_end=938, pcm=smp_116_pcm   @ loop 434-938
smp_117:	sample_hdr length=598, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_117_pcm   @ no loop
smp_118:	sample_hdr length=8486, rate=13379, root=60, loop_start=1625, loop_end=2928, pcm=smp_118_pcm   @ loop 1625-2928
smp_119:	sample_hdr length=546, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_119_pcm   @ no loop
smp_120:	sample_hdr length=1483, rate=13379, root=60, loop_start=315, loop_end=954, pcm=smp_120_pcm   @ loop 315-954
smp_121:	sample_hdr length=1923, rate=13379, root=60, loop_start=190, loop_end=777, pcm=smp_121_pcm   @ loop 190-777
smp_122:	sample_hdr length=2628, rate=13379, root=65, loop_start=1570, loop_end=2177, pcm=smp_122_pcm   @ loop 1570-2177
smp_123:	sample_hdr length=3103, rate=13379, root=60, loop_start=0, loop_end=2794, pcm=smp_123_pcm   @ loop 0-2794
smp_124:	sample_hdr length=4088, rate=13379, root=65, loop_start=1793, loop_end=2587, pcm=smp_124_pcm   @ loop 1793-2587
smp_125:	sample_hdr length=5451, rate=13379, root=65, loop_start=2115, loop_end=2838, pcm=smp_125_pcm   @ loop 2115-2838
smp_126:	sample_hdr length=4344, rate=13379, root=60, loop_start=595, loop_end=2674, pcm=smp_126_pcm   @ loop 595-2674
smp_127:	sample_hdr length=6678, rate=13379, root=60, loop_start=1410, loop_end=2983, pcm=smp_127_pcm   @ loop 1410-2983
smp_128:	sample_hdr length=1966, rate=5000, root=60, loop_start=125, loop_end=1248, pcm=smp_128_pcm   @ loop 125-1248
smp_129:	sample_hdr length=2197, rate=13379, root=65, loop_start=846, loop_end=1403, pcm=smp_129_pcm   @ loop 846-1403
smp_130:	sample_hdr length=1313, rate=13379, root=65, loop_start=230, loop_end=919, pcm=smp_130_pcm   @ loop 230-919
smp_131:	sample_hdr length=2013, rate=13379, root=65, loop_start=670, loop_end=1527, pcm=smp_131_pcm   @ loop 670-1527
smp_132:	sample_hdr length=1455, rate=13379, root=65, loop_start=571, loop_end=1132, pcm=smp_132_pcm   @ loop 571-1132
smp_133:	sample_hdr length=3906, rate=13379, root=64, loop_start=325, loop_end=1410, pcm=smp_133_pcm   @ loop 325-1410
smp_134:	sample_hdr length=1953, rate=13379, root=67, loop_start=0, loop_end=0, pcm=smp_134_pcm   @ no loop
smp_135:	sample_hdr length=1836, rate=13379, root=64, loop_start=507, loop_end=1371, pcm=smp_135_pcm   @ loop 507-1371
smp_136:	sample_hdr length=5672, rate=13379, root=67, loop_start=2180, loop_end=3798, pcm=smp_136_pcm   @ loop 2180-3798
smp_137:	sample_hdr length=3979, rate=10512, root=60, loop_start=1296, loop_end=1991, pcm=smp_137_pcm   @ loop 1296-1991
smp_138:	sample_hdr length=447, rate=13379, root=60, loop_start=0, loop_end=221, pcm=smp_138_pcm   @ loop 0-221
smp_139:	sample_hdr length=926, rate=13379, root=72, loop_start=14, loop_end=865, pcm=smp_139_pcm   @ loop 14-865
smp_140:	sample_hdr length=3505, rate=13379, root=65, loop_start=0, loop_end=3491, pcm=smp_140_pcm   @ loop 0-3491
smp_141:	sample_hdr length=3531, rate=13379, root=60, loop_start=1556, loop_end=2692, pcm=smp_141_pcm   @ loop 1556-2692
smp_142:	sample_hdr length=1910, rate=13379, root=60, loop_start=644, loop_end=1169, pcm=smp_142_pcm   @ loop 644-1169
smp_143:	sample_hdr length=909, rate=13379, root=67, loop_start=0, loop_end=0, pcm=smp_143_pcm   @ no loop
smp_144:	sample_hdr length=356, rate=13379, root=60, loop_start=0, loop_end=304, pcm=smp_144_pcm   @ loop 0-304
smp_145:	sample_hdr length=1974, rate=13379, root=64, loop_start=5, loop_end=1895, pcm=smp_145_pcm   @ loop 5-1895
smp_146:	sample_hdr length=676, rate=13379, root=60, loop_start=0, loop_end=675, pcm=smp_146_pcm   @ loop 0-675
smp_147:	sample_hdr length=877, rate=13379, root=64, loop_start=1, loop_end=873, pcm=smp_147_pcm   @ loop 1-873
smp_148:	sample_hdr length=2134, rate=13379, root=64, loop_start=4, loop_end=2130, pcm=smp_148_pcm   @ loop 4-2130
smp_149:	sample_hdr length=4028, rate=13379, root=62, loop_start=17, loop_end=2789, pcm=smp_149_pcm   @ loop 17-2789
smp_150:	sample_hdr length=1340, rate=13379, root=60, loop_start=0, loop_end=1340, pcm=smp_150_pcm   @ loop 0-1340
smp_151:	sample_hdr length=2360, rate=13379, root=64, loop_start=0, loop_end=2360, pcm=smp_151_pcm   @ loop 0-2360
smp_152:	sample_hdr length=2424, rate=13379, root=60, loop_start=17, loop_end=2335, pcm=smp_152_pcm   @ loop 17-2335
smp_153:	sample_hdr length=841, rate=10512, root=60, loop_start=0, loop_end=817, pcm=smp_153_pcm   @ loop 0-817
smp_154:	sample_hdr length=1337, rate=13379, root=60, loop_start=2, loop_end=1321, pcm=smp_154_pcm   @ loop 2-1321
smp_155:	sample_hdr length=2769, rate=13379, root=72, loop_start=2, loop_end=2755, pcm=smp_155_pcm   @ loop 2-2755
smp_156:	sample_hdr length=897, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_156_pcm   @ no loop
smp_157:	sample_hdr length=883, rate=13379, root=67, loop_start=41, loop_end=875, pcm=smp_157_pcm   @ loop 41-875
smp_158:	sample_hdr length=1135, rate=13379, root=60, loop_start=53, loop_end=633, pcm=smp_158_pcm   @ loop 53-633
smp_159:	sample_hdr length=2239, rate=10512, root=66, loop_start=1224, loop_end=1430, pcm=smp_159_pcm   @ loop 1224-1430
smp_160:	sample_hdr length=3395, rate=10512, root=66, loop_start=2141, loop_end=2487, pcm=smp_160_pcm   @ loop 2141-2487
smp_161:	sample_hdr length=6066, rate=10512, root=67, loop_start=1591, loop_end=2418, pcm=smp_161_pcm   @ loop 1591-2418
smp_162:	sample_hdr length=4803, rate=13379, root=60, loop_start=930, loop_end=2605, pcm=smp_162_pcm   @ loop 930-2605
smp_163:	sample_hdr length=1827, rate=10512, root=72, loop_start=352, loop_end=1062, pcm=smp_163_pcm   @ loop 352-1062
smp_164:	sample_hdr length=1177, rate=10512, root=72, loop_start=813, loop_end=992, pcm=smp_164_pcm   @ loop 813-992
smp_165:	sample_hdr length=1135, rate=10512, root=72, loop_start=51, loop_end=800, pcm=smp_165_pcm   @ loop 51-800
smp_166:	sample_hdr length=1061, rate=10512, root=72, loop_start=0, loop_end=0, pcm=smp_166_pcm   @ no loop
smp_167:	sample_hdr length=689, rate=10512, root=72, loop_start=0, loop_end=0, pcm=smp_167_pcm   @ no loop
smp_168:	sample_hdr length=1009, rate=10512, root=72, loop_start=0, loop_end=0, pcm=smp_168_pcm   @ no loop
smp_169:	sample_hdr length=2060, rate=10512, root=72, loop_start=948, loop_end=1749, pcm=smp_169_pcm   @ loop 948-1749
smp_170:	sample_hdr length=4635, rate=10512, root=72, loop_start=2645, loop_end=3829, pcm=smp_170_pcm   @ loop 2645-3829
smp_171:	sample_hdr length=2796, rate=10512, root=72, loop_start=1625, loop_end=2338, pcm=smp_171_pcm   @ loop 1625-2338
smp_172:	sample_hdr length=5056, rate=10512, root=72, loop_start=2137, loop_end=2818, pcm=smp_172_pcm   @ loop 2137-2818
smp_173:	sample_hdr length=8052, rate=10512, root=72, loop_start=1375, loop_end=2036, pcm=smp_173_pcm   @ loop 1375-2036
smp_174:	sample_hdr length=1187, rate=10512, root=72, loop_start=25, loop_end=1032, pcm=smp_174_pcm   @ loop 25-1032
smp_175:	sample_hdr length=6675, rate=10512, root=72, loop_start=515, loop_end=1913, pcm=smp_175_pcm   @ loop 515-1913
smp_176:	sample_hdr length=8031, rate=10512, root=72, loop_start=3111, loop_end=4043, pcm=smp_176_pcm   @ loop 3111-4043
smp_177:	sample_hdr length=9502, rate=10512, root=72, loop_start=2598, loop_end=3971, pcm=smp_177_pcm   @ loop 2598-3971
smp_178:	sample_hdr length=1081, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_178_pcm   @ no loop
smp_179:	sample_hdr length=2398, rate=13379, root=72, loop_start=924, loop_end=2211, pcm=smp_179_pcm   @ loop 924-2211
smp_180:	sample_hdr length=2421, rate=13379, root=72, loop_start=852, loop_end=1104, pcm=smp_180_pcm   @ loop 852-1104
smp_181:	sample_hdr length=5488, rate=13379, root=72, loop_start=1155, loop_end=2713, pcm=smp_181_pcm   @ loop 1155-2713
smp_182:	sample_hdr length=2712, rate=13379, root=60, loop_start=333, loop_end=1449, pcm=smp_182_pcm   @ loop 333-1449
smp_183:	sample_hdr length=3344, rate=13379, root=60, loop_start=1465, loop_end=1677, pcm=smp_183_pcm   @ loop 1465-1677
smp_184:	sample_hdr length=450, rate=10512, root=60, loop_start=0, loop_end=345, pcm=smp_184_pcm   @ loop 0-345
smp_185:	sample_hdr length=1121, rate=10512, root=60, loop_start=1, loop_end=823, pcm=smp_185_pcm   @ loop 1-823
smp_186:	sample_hdr length=822, rate=10512, root=60, loop_start=0, loop_end=667, pcm=smp_186_pcm   @ loop 0-667
smp_187:	sample_hdr length=1368, rate=10512, root=67, loop_start=690, loop_end=1004, pcm=smp_187_pcm   @ loop 690-1004
smp_188:	sample_hdr length=1568, rate=10512, root=60, loop_start=359, loop_end=531, pcm=smp_188_pcm   @ loop 359-531
smp_189:	sample_hdr length=851, rate=10512, root=66, loop_start=501, loop_end=633, pcm=smp_189_pcm   @ loop 501-633
smp_190:	sample_hdr length=998, rate=10512, root=66, loop_start=0, loop_end=0, pcm=smp_190_pcm   @ no loop
smp_191:	sample_hdr length=3195, rate=10512, root=72, loop_start=1254, loop_end=2638, pcm=smp_191_pcm   @ loop 1254-2638
smp_192:	sample_hdr length=2815, rate=10512, root=72, loop_start=0, loop_end=2795, pcm=smp_192_pcm   @ loop 0-2795
smp_193:	sample_hdr length=2575, rate=10512, root=67, loop_start=1166, loop_end=2223, pcm=smp_193_pcm   @ loop 1166-2223
smp_194:	sample_hdr length=4220, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_194_pcm   @ no loop
smp_195:	sample_hdr length=1019, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_195_pcm   @ no loop
smp_196:	sample_hdr length=573, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_196_pcm   @ no loop
smp_197:	sample_hdr length=1362, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_197_pcm   @ no loop
smp_198:	sample_hdr length=502, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_198_pcm   @ no loop
smp_199:	sample_hdr length=803, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_199_pcm   @ no loop
smp_200:	sample_hdr length=1460, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_200_pcm   @ no loop
smp_201:	sample_hdr length=702, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_201_pcm   @ no loop
smp_202:	sample_hdr length=1092, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_202_pcm   @ no loop
smp_203:	sample_hdr length=455, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_203_pcm   @ no loop
smp_204:	sample_hdr length=742, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_204_pcm   @ no loop
smp_205:	sample_hdr length=2285, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_205_pcm   @ no loop
smp_206:	sample_hdr length=1585, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_206_pcm   @ no loop
smp_207:	sample_hdr length=2152, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_207_pcm   @ no loop
smp_208:	sample_hdr length=2296, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_208_pcm   @ no loop
smp_209:	sample_hdr length=1846, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_209_pcm   @ no loop
smp_210:	sample_hdr length=1473, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_210_pcm   @ no loop
smp_211:	sample_hdr length=2191, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_211_pcm   @ no loop
smp_212:	sample_hdr length=2027, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_212_pcm   @ no loop
smp_213:	sample_hdr length=0, rate=1000, root=72, loop_start=0, loop_end=0, pcm=smp_213_pcm   @ no loop
smp_214:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_214_pcm   @ no loop
smp_215:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_215_pcm   @ no loop
smp_216:	sample_hdr length=2408, rate=13379, root=66, loop_start=1270, loop_end=1791, pcm=smp_216_pcm   @ loop 1270-1791
smp_217:	sample_hdr length=4488, rate=13379, root=67, loop_start=2321, loop_end=3130, pcm=smp_217_pcm   @ loop 2321-3130
smp_218:	sample_hdr length=1816, rate=13379, root=60, loop_start=19, loop_end=363, pcm=smp_218_pcm   @ loop 19-363
smp_219:	sample_hdr length=3512, rate=13379, root=67, loop_start=0, loop_end=2936, pcm=smp_219_pcm   @ loop 0-2936
smp_220:	sample_hdr length=2538, rate=13379, root=60, loop_start=0, loop_end=1935, pcm=smp_220_pcm   @ loop 0-1935
smp_221:	sample_hdr length=3713, rate=13379, root=60, loop_start=1378, loop_end=1575, pcm=smp_221_pcm   @ loop 1378-1575
smp_222:	sample_hdr length=2568, rate=13379, root=60, loop_start=534, loop_end=1592, pcm=smp_222_pcm   @ loop 534-1592
smp_223:	sample_hdr length=4677, rate=10512, root=64, loop_start=2423, loop_end=2564, pcm=smp_223_pcm   @ loop 2423-2564
smp_224:	sample_hdr length=1776, rate=10512, root=72, loop_start=0, loop_end=1749, pcm=smp_224_pcm   @ loop 0-1749
smp_225:	sample_hdr length=1962, rate=10512, root=72, loop_start=0, loop_end=1897, pcm=smp_225_pcm   @ loop 0-1897
smp_226:	sample_hdr length=327, rate=10512, root=67, loop_start=0, loop_end=307, pcm=smp_226_pcm   @ loop 0-307
smp_227:	sample_hdr length=1502, rate=10512, root=64, loop_start=308, loop_end=764, pcm=smp_227_pcm   @ loop 308-764
smp_228:	sample_hdr length=299, rate=10512, root=64, loop_start=0, loop_end=0, pcm=smp_228_pcm   @ no loop
smp_229:	sample_hdr length=2635, rate=13379, root=72, loop_start=942, loop_end=1895, pcm=smp_229_pcm   @ loop 942-1895
smp_230:	sample_hdr length=460, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_230_pcm   @ no loop
smp_231:	sample_hdr length=249, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_231_pcm   @ no loop
smp_232:	sample_hdr length=635, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_232_pcm   @ no loop
smp_233:	sample_hdr length=1240, rate=10512, root=72, loop_start=11, loop_end=595, pcm=smp_233_pcm   @ loop 11-595
smp_234:	sample_hdr length=5271, rate=13379, root=72, loop_start=616, loop_end=1371, pcm=smp_234_pcm   @ loop 616-1371
smp_235:	sample_hdr length=5091, rate=13379, root=72, loop_start=485, loop_end=1383, pcm=smp_235_pcm   @ loop 485-1383
smp_236:	sample_hdr length=2554, rate=13379, root=72, loop_start=314, loop_end=984, pcm=smp_236_pcm   @ loop 314-984
smp_237:	sample_hdr length=2162, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_237_pcm   @ no loop
smp_238:	sample_hdr length=3022, rate=13379, root=72, loop_start=795, loop_end=1261, pcm=smp_238_pcm   @ loop 795-1261
smp_239:	sample_hdr length=1475, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_239_pcm   @ no loop
smp_240:	sample_hdr length=1941, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_240_pcm   @ no loop
smp_241:	sample_hdr length=3138, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_241_pcm   @ no loop
smp_242:	sample_hdr length=551, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_242_pcm   @ no loop
smp_243:	sample_hdr length=538, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_243_pcm   @ no loop
smp_244:	sample_hdr length=1707, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_244_pcm   @ no loop
smp_245:	sample_hdr length=633, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_245_pcm   @ no loop
smp_246:	sample_hdr length=2779, rate=13379, root=72, loop_start=492, loop_end=1081, pcm=smp_246_pcm   @ loop 492-1081
smp_247:	sample_hdr length=1510, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_247_pcm   @ no loop
smp_248:	sample_hdr length=1234, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_248_pcm   @ no loop
smp_249:	sample_hdr length=2391, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_249_pcm   @ no loop
smp_250:	sample_hdr length=2056, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_250_pcm   @ no loop
smp_251:	sample_hdr length=1563, rate=13379, root=72, loop_start=539, loop_end=1010, pcm=smp_251_pcm   @ loop 539-1010
smp_252:	sample_hdr length=907, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_252_pcm   @ no loop
smp_253:	sample_hdr length=1405, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_253_pcm   @ no loop
smp_254:	sample_hdr length=2769, rate=13379, root=70, loop_start=0, loop_end=0, pcm=smp_254_pcm   @ no loop
smp_255:	sample_hdr length=877, rate=13379, root=72, loop_start=184, loop_end=731, pcm=smp_255_pcm   @ loop 184-731
smp_256:	sample_hdr length=1910, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_256_pcm   @ no loop
smp_257:	sample_hdr length=2120, rate=7884, root=60, loop_start=867, loop_end=1583, pcm=smp_257_pcm   @ loop 867-1583
smp_258:	sample_hdr length=721, rate=7884, root=60, loop_start=24, loop_end=552, pcm=smp_258_pcm   @ loop 24-552
smp_259:	sample_hdr length=2459, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_259_pcm   @ no loop
smp_260:	sample_hdr length=2729, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_260_pcm   @ no loop
smp_261:	sample_hdr length=2339, rate=7884, root=60, loop_start=1658, loop_end=1992, pcm=smp_261_pcm   @ loop 1658-1992
smp_262:	sample_hdr length=2000, rate=7884, root=60, loop_start=838, loop_end=1286, pcm=smp_262_pcm   @ loop 838-1286
smp_263:	sample_hdr length=2742, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_263_pcm   @ no loop
smp_264:	sample_hdr length=2086, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_264_pcm   @ no loop
smp_265:	sample_hdr length=4065, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_265_pcm   @ no loop
smp_266:	sample_hdr length=1279, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_266_pcm   @ no loop
smp_267:	sample_hdr length=1942, rate=7884, root=60, loop_start=950, loop_end=1757, pcm=smp_267_pcm   @ loop 950-1757
smp_268:	sample_hdr length=1260, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_268_pcm   @ no loop
smp_269:	sample_hdr length=1243, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_269_pcm   @ no loop
smp_270:	sample_hdr length=1415, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_270_pcm   @ no loop
smp_271:	sample_hdr length=2995, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_271_pcm   @ no loop
smp_272:	sample_hdr length=3516, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_272_pcm   @ no loop
smp_273:	sample_hdr length=6827, rate=7884, root=60, loop_start=4481, loop_end=5319, pcm=smp_273_pcm   @ loop 4481-5319
smp_274:	sample_hdr length=1578, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_274_pcm   @ no loop
smp_275:	sample_hdr length=2362, rate=7884, root=60, loop_start=1580, loop_end=1731, pcm=smp_275_pcm   @ loop 1580-1731
smp_276:	sample_hdr length=1939, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_276_pcm   @ no loop
smp_277:	sample_hdr length=4219, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_277_pcm   @ no loop
smp_278:	sample_hdr length=2212, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_278_pcm   @ no loop
smp_279:	sample_hdr length=1327, rate=7884, root=60, loop_start=661, loop_end=1238, pcm=smp_279_pcm   @ loop 661-1238
smp_280:	sample_hdr length=3029, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_280_pcm   @ no loop
smp_281:	sample_hdr length=3118, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_281_pcm   @ no loop
smp_282:	sample_hdr length=3374, rate=7884, root=60, loop_start=2574, loop_end=3109, pcm=smp_282_pcm   @ loop 2574-3109
smp_283:	sample_hdr length=3644, rate=7884, root=60, loop_start=2736, loop_end=3346, pcm=smp_283_pcm   @ loop 2736-3346
smp_284:	sample_hdr length=2350, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_284_pcm   @ no loop
smp_285:	sample_hdr length=3566, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_285_pcm   @ no loop
smp_286:	sample_hdr length=2350, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_286_pcm   @ no loop
smp_287:	sample_hdr length=3530, rate=13379, root=72, loop_start=1618, loop_end=2418, pcm=smp_287_pcm   @ loop 1618-2418
smp_288:	sample_hdr length=3601, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_288_pcm   @ no loop
smp_289:	sample_hdr length=4845, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_289_pcm   @ no loop
smp_290:	sample_hdr length=4075, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_290_pcm   @ no loop
smp_291:	sample_hdr length=4909, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_291_pcm   @ no loop
smp_292:	sample_hdr length=3136, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_292_pcm   @ no loop
smp_293:	sample_hdr length=4496, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_293_pcm   @ no loop
smp_294:	sample_hdr length=4948, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_294_pcm   @ no loop
smp_295:	sample_hdr length=1814, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_295_pcm   @ no loop
smp_296:	sample_hdr length=3841, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_296_pcm   @ no loop
smp_297:	sample_hdr length=1623, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_297_pcm   @ no loop
smp_298:	sample_hdr length=3410, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_298_pcm   @ no loop
smp_299:	sample_hdr length=2720, rate=13379, root=72, loop_start=1666, loop_end=2532, pcm=smp_299_pcm   @ loop 1666-2532
smp_300:	sample_hdr length=5999, rate=13379, root=72, loop_start=1142, loop_end=2321, pcm=smp_300_pcm   @ loop 1142-2321
smp_301:	sample_hdr length=4448, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_301_pcm   @ no loop
smp_302:	sample_hdr length=7029, rate=13379, root=72, loop_start=2430, loop_end=3663, pcm=smp_302_pcm   @ loop 2430-3663
smp_303:	sample_hdr length=1742, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_303_pcm   @ no loop
smp_304:	sample_hdr length=3828, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_304_pcm   @ no loop
smp_305:	sample_hdr length=3333, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_305_pcm   @ no loop
smp_306:	sample_hdr length=2067, rate=13379, root=72, loop_start=1111, loop_end=1518, pcm=smp_306_pcm   @ loop 1111-1518
smp_307:	sample_hdr length=3546, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_307_pcm   @ no loop
smp_308:	sample_hdr length=3384, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_308_pcm   @ no loop
smp_309:	sample_hdr length=3998, rate=13379, root=72, loop_start=2779, loop_end=3405, pcm=smp_309_pcm   @ loop 2779-3405
smp_310:	sample_hdr length=3678, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_310_pcm   @ no loop
smp_311:	sample_hdr length=3238, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_311_pcm   @ no loop
smp_312:	sample_hdr length=3415, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_312_pcm   @ no loop
smp_313:	sample_hdr length=3314, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_313_pcm   @ no loop
smp_314:	sample_hdr length=4152, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_314_pcm   @ no loop
smp_315:	sample_hdr length=5846, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_315_pcm   @ no loop
smp_316:	sample_hdr length=3006, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_316_pcm   @ no loop
smp_317:	sample_hdr length=2334, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_317_pcm   @ no loop
smp_318:	sample_hdr length=4594, rate=13379, root=72, loop_start=1407, loop_end=2137, pcm=smp_318_pcm   @ loop 1407-2137
smp_319:	sample_hdr length=2524, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_319_pcm   @ no loop
smp_320:	sample_hdr length=4059, rate=13379, root=72, loop_start=2632, loop_end=3327, pcm=smp_320_pcm   @ loop 2632-3327
smp_321:	sample_hdr length=2446, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_321_pcm   @ no loop
smp_322:	sample_hdr length=2830, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_322_pcm   @ no loop
smp_323:	sample_hdr length=3108, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_323_pcm   @ no loop
smp_324:	sample_hdr length=7686, rate=13379, root=72, loop_start=1064, loop_end=2558, pcm=smp_324_pcm   @ loop 1064-2558
smp_325:	sample_hdr length=1123, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_325_pcm   @ no loop
smp_326:	sample_hdr length=3243, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_326_pcm   @ no loop
smp_327:	sample_hdr length=6407, rate=13379, root=72, loop_start=1765, loop_end=2651, pcm=smp_327_pcm   @ loop 1765-2651
smp_328:	sample_hdr length=4729, rate=13379, root=72, loop_start=2220, loop_end=3095, pcm=smp_328_pcm   @ loop 2220-3095
smp_329:	sample_hdr length=6713, rate=13379, root=72, loop_start=1323, loop_end=2470, pcm=smp_329_pcm   @ loop 1323-2470
smp_330:	sample_hdr length=5389, rate=13379, root=72, loop_start=1469, loop_end=2162, pcm=smp_330_pcm   @ loop 1469-2162
smp_331:	sample_hdr length=8146, rate=13379, root=72, loop_start=3137, loop_end=5276, pcm=smp_331_pcm   @ loop 3137-5276
smp_332:	sample_hdr length=2503, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_332_pcm   @ no loop
smp_333:	sample_hdr length=3386, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_333_pcm   @ no loop
smp_334:	sample_hdr length=2681, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_334_pcm   @ no loop
smp_335:	sample_hdr length=7054, rate=13379, root=72, loop_start=1545, loop_end=2266, pcm=smp_335_pcm   @ loop 1545-2266
smp_336:	sample_hdr length=4106, rate=13379, root=72, loop_start=930, loop_end=2924, pcm=smp_336_pcm   @ loop 930-2924
smp_337:	sample_hdr length=3241, rate=13379, root=72, loop_start=1176, loop_end=2125, pcm=smp_337_pcm   @ loop 1176-2125
smp_338:	sample_hdr length=4037, rate=13379, root=72, loop_start=1203, loop_end=1829, pcm=smp_338_pcm   @ loop 1203-1829
smp_339:	sample_hdr length=6106, rate=13379, root=72, loop_start=1518, loop_end=2435, pcm=smp_339_pcm   @ loop 1518-2435
smp_340:	sample_hdr length=3210, rate=13379, root=72, loop_start=1086, loop_end=2084, pcm=smp_340_pcm   @ loop 1086-2084
smp_341:	sample_hdr length=1790, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_341_pcm   @ no loop
smp_342:	sample_hdr length=2017, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_342_pcm   @ no loop
smp_343:	sample_hdr length=2333, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_343_pcm   @ no loop
smp_344:	sample_hdr length=1743, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_344_pcm   @ no loop
smp_345:	sample_hdr length=2088, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_345_pcm   @ no loop
smp_346:	sample_hdr length=8847, rate=13379, root=72, loop_start=1313, loop_end=2445, pcm=smp_346_pcm   @ loop 1313-2445
smp_347:	sample_hdr length=2246, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_347_pcm   @ no loop
smp_348:	sample_hdr length=2444, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_348_pcm   @ no loop
smp_349:	sample_hdr length=1785, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_349_pcm   @ no loop
smp_350:	sample_hdr length=3019, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_350_pcm   @ no loop
smp_351:	sample_hdr length=3317, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_351_pcm   @ no loop
smp_352:	sample_hdr length=3782, rate=13379, root=72, loop_start=1127, loop_end=1835, pcm=smp_352_pcm   @ loop 1127-1835
smp_353:	sample_hdr length=389, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_353_pcm   @ no loop
smp_354:	sample_hdr length=2656, rate=13379, root=72, loop_start=611, loop_end=1734, pcm=smp_354_pcm   @ loop 611-1734
smp_355:	sample_hdr length=2867, rate=13379, root=72, loop_start=1091, loop_end=1942, pcm=smp_355_pcm   @ loop 1091-1942
smp_356:	sample_hdr length=3981, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_356_pcm   @ no loop
smp_357:	sample_hdr length=3425, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_357_pcm   @ no loop
smp_358:	sample_hdr length=3368, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_358_pcm   @ no loop
smp_359:	sample_hdr length=3912, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_359_pcm   @ no loop
smp_360:	sample_hdr length=1003, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_360_pcm   @ no loop
smp_361:	sample_hdr length=6303, rate=13379, root=69, loop_start=4688, loop_end=5263, pcm=smp_361_pcm   @ loop 4688-5263
smp_362:	sample_hdr length=1463, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_362_pcm   @ no loop
smp_363:	sample_hdr length=2073, rate=13379, root=66, loop_start=0, loop_end=2062, pcm=smp_363_pcm   @ loop 0-2062
smp_364:	sample_hdr length=10978, rate=13379, root=72, loop_start=1220, loop_end=7548, pcm=smp_364_pcm   @ loop 1220-7548
smp_365:	sample_hdr length=2576, rate=13379, root=60, loop_start=978, loop_end=1216, pcm=smp_365_pcm   @ loop 978-1216
smp_366:	sample_hdr length=2870, rate=13379, root=67, loop_start=2169, loop_end=2480, pcm=smp_366_pcm   @ loop 2169-2480
smp_367:	sample_hdr length=5462, rate=13379, root=67, loop_start=1940, loop_end=3774, pcm=smp_367_pcm   @ loop 1940-3774
smp_368:	sample_hdr length=3639, rate=13379, root=67, loop_start=2131, loop_end=2595, pcm=smp_368_pcm   @ loop 2131-2595
smp_369:	sample_hdr length=5084, rate=13379, root=67, loop_start=1348, loop_end=3404, pcm=smp_369_pcm   @ loop 1348-3404
smp_370:	sample_hdr length=2836, rate=13379, root=67, loop_start=0, loop_end=0, pcm=smp_370_pcm   @ no loop
smp_371:	sample_hdr length=1861, rate=13379, root=60, loop_start=0, loop_end=0, pcm=smp_371_pcm   @ no loop
smp_372:	sample_hdr length=2741, rate=13379, root=72, loop_start=1636, loop_end=2489, pcm=smp_372_pcm   @ loop 1636-2489
smp_373:	sample_hdr length=2130, rate=13379, root=67, loop_start=0, loop_end=0, pcm=smp_373_pcm   @ no loop
smp_374:	sample_hdr length=3243, rate=5734, root=60, loop_start=797, loop_end=1913, pcm=smp_374_pcm   @ loop 797-1913
smp_375:	sample_hdr length=636, rate=3200, root=60, loop_start=13, loop_end=449, pcm=smp_375_pcm   @ loop 13-449
smp_376:	sample_hdr length=892, rate=3200, root=60, loop_start=276, loop_end=837, pcm=smp_376_pcm   @ loop 276-837
smp_377:	sample_hdr length=3946, rate=13379, root=67, loop_start=1380, loop_end=2141, pcm=smp_377_pcm   @ loop 1380-2141
smp_378:	sample_hdr length=3140, rate=13379, root=72, loop_start=1653, loop_end=2089, pcm=smp_378_pcm   @ loop 1653-2089
smp_379:	sample_hdr length=3054, rate=7884, root=60, loop_start=643, loop_end=2338, pcm=smp_379_pcm   @ loop 643-2338
smp_380:	sample_hdr length=1968, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_380_pcm   @ no loop
smp_381:	sample_hdr length=1418, rate=13379, root=65, loop_start=0, loop_end=0, pcm=smp_381_pcm   @ no loop
smp_382:	sample_hdr length=1396, rate=13379, root=67, loop_start=826, loop_end=1041, pcm=smp_382_pcm   @ loop 826-1041
smp_383:	sample_hdr length=1199, rate=13379, root=67, loop_start=0, loop_end=0, pcm=smp_383_pcm   @ no loop
smp_384:	sample_hdr length=2200, rate=13379, root=67, loop_start=1026, loop_end=1412, pcm=smp_384_pcm   @ loop 1026-1412
smp_385:	sample_hdr length=1264, rate=13379, root=67, loop_start=265, loop_end=612, pcm=smp_385_pcm   @ loop 265-612
smp_386:	sample_hdr length=1591, rate=13379, root=67, loop_start=0, loop_end=0, pcm=smp_386_pcm   @ no loop
smp_387:	sample_hdr length=4251, rate=7884, root=60, loop_start=2597, loop_end=3671, pcm=smp_387_pcm   @ loop 2597-3671
smp_388:	sample_hdr length=490, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_388_pcm   @ no loop
smp_389:	sample_hdr length=1613, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_389_pcm   @ no loop
smp_390:	sample_hdr length=643, rate=2628, root=60, loop_start=0, loop_end=0, pcm=smp_390_pcm   @ no loop
smp_391:	sample_hdr length=1666, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_391_pcm   @ no loop
smp_392:	sample_hdr length=729, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_392_pcm   @ no loop
smp_393:	sample_hdr length=1461, rate=5734, root=60, loop_start=492, loop_end=1002, pcm=smp_393_pcm   @ loop 492-1002
smp_394:	sample_hdr length=2192, rate=7884, root=60, loop_start=622, loop_end=1346, pcm=smp_394_pcm   @ loop 622-1346
smp_395:	sample_hdr length=1584, rate=7884, root=60, loop_start=395, loop_end=956, pcm=smp_395_pcm   @ loop 395-956
smp_396:	sample_hdr length=1927, rate=7884, root=60, loop_start=289, loop_end=1153, pcm=smp_396_pcm   @ loop 289-1153
smp_397:	sample_hdr length=1775, rate=7884, root=60, loop_start=440, loop_end=863, pcm=smp_397_pcm   @ loop 440-863
smp_398:	sample_hdr length=1269, rate=3200, root=60, loop_start=542, loop_end=999, pcm=smp_398_pcm   @ loop 542-999
smp_399:	sample_hdr length=780, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_399_pcm   @ no loop
smp_400:	sample_hdr length=487, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_400_pcm   @ no loop
smp_401:	sample_hdr length=1528, rate=7884, root=60, loop_start=389, loop_end=1185, pcm=smp_401_pcm   @ loop 389-1185
smp_402:	sample_hdr length=446, rate=3200, root=60, loop_start=0, loop_end=0, pcm=smp_402_pcm   @ no loop
smp_403:	sample_hdr length=1351, rate=7884, root=60, loop_start=411, loop_end=826, pcm=smp_403_pcm   @ loop 411-826
smp_404:	sample_hdr length=1424, rate=7884, root=60, loop_start=231, loop_end=795, pcm=smp_404_pcm   @ loop 231-795
smp_405:	sample_hdr length=2679, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_405_pcm   @ no loop
smp_406:	sample_hdr length=2511, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_406_pcm   @ no loop
smp_407:	sample_hdr length=2069, rate=7884, root=60, loop_start=816, loop_end=1859, pcm=smp_407_pcm   @ loop 816-1859
smp_408:	sample_hdr length=2357, rate=7884, root=60, loop_start=729, loop_end=1926, pcm=smp_408_pcm   @ loop 729-1926
smp_409:	sample_hdr length=2292, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_409_pcm   @ no loop
smp_410:	sample_hdr length=1561, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_410_pcm   @ no loop
smp_411:	sample_hdr length=1749, rate=7884, root=60, loop_start=290, loop_end=1025, pcm=smp_411_pcm   @ loop 290-1025
smp_412:	sample_hdr length=1464, rate=7884, root=60, loop_start=356, loop_end=1193, pcm=smp_412_pcm   @ loop 356-1193
smp_413:	sample_hdr length=1196, rate=5734, root=60, loop_start=195, loop_end=921, pcm=smp_413_pcm   @ loop 195-921
smp_414:	sample_hdr length=1234, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_414_pcm   @ no loop
smp_415:	sample_hdr length=1842, rate=7884, root=60, loop_start=477, loop_end=1254, pcm=smp_415_pcm   @ loop 477-1254
smp_416:	sample_hdr length=1850, rate=7884, root=60, loop_start=462, loop_end=1401, pcm=smp_416_pcm   @ loop 462-1401
smp_417:	sample_hdr length=1655, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_417_pcm   @ no loop
smp_418:	sample_hdr length=4670, rate=7884, root=60, loop_start=431, loop_end=1407, pcm=smp_418_pcm   @ loop 431-1407
smp_419:	sample_hdr length=2276, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_419_pcm   @ no loop
smp_420:	sample_hdr length=1672, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_420_pcm   @ no loop
smp_421:	sample_hdr length=1848, rate=7884, root=60, loop_start=494, loop_end=1399, pcm=smp_421_pcm   @ loop 494-1399
smp_422:	sample_hdr length=1755, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_422_pcm   @ no loop
smp_423:	sample_hdr length=1506, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_423_pcm   @ no loop
smp_424:	sample_hdr length=3715, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_424_pcm   @ no loop
smp_425:	sample_hdr length=1707, rate=7884, root=60, loop_start=267, loop_end=1068, pcm=smp_425_pcm   @ loop 267-1068
smp_426:	sample_hdr length=1727, rate=7884, root=60, loop_start=226, loop_end=1071, pcm=smp_426_pcm   @ loop 226-1071
smp_427:	sample_hdr length=1127, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_427_pcm   @ no loop
smp_428:	sample_hdr length=2803, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_428_pcm   @ no loop
smp_429:	sample_hdr length=2285, rate=7884, root=60, loop_start=481, loop_end=1714, pcm=smp_429_pcm   @ loop 481-1714
smp_430:	sample_hdr length=1336, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_430_pcm   @ no loop
smp_431:	sample_hdr length=1827, rate=7884, root=60, loop_start=632, loop_end=1387, pcm=smp_431_pcm   @ loop 632-1387
smp_432:	sample_hdr length=1875, rate=7884, root=60, loop_start=111, loop_end=881, pcm=smp_432_pcm   @ loop 111-881
smp_433:	sample_hdr length=1634, rate=7884, root=60, loop_start=309, loop_end=1029, pcm=smp_433_pcm   @ loop 309-1029
smp_434:	sample_hdr length=2087, rate=7884, root=60, loop_start=667, loop_end=1326, pcm=smp_434_pcm   @ loop 667-1326
smp_435:	sample_hdr length=1724, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_435_pcm   @ no loop
smp_436:	sample_hdr length=1454, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_436_pcm   @ no loop
smp_437:	sample_hdr length=1638, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_437_pcm   @ no loop
smp_438:	sample_hdr length=2323, rate=7884, root=60, loop_start=635, loop_end=1705, pcm=smp_438_pcm   @ loop 635-1705
smp_439:	sample_hdr length=2918, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_439_pcm   @ no loop
smp_440:	sample_hdr length=3706, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_440_pcm   @ no loop
smp_441:	sample_hdr length=5112, rate=7884, root=60, loop_start=312, loop_end=3580, pcm=smp_441_pcm   @ loop 312-3580
smp_442:	sample_hdr length=2632, rate=7884, root=60, loop_start=1100, loop_end=2185, pcm=smp_442_pcm   @ loop 1100-2185
smp_443:	sample_hdr length=2330, rate=7884, root=60, loop_start=809, loop_end=1943, pcm=smp_443_pcm   @ loop 809-1943
smp_444:	sample_hdr length=3905, rate=7884, root=60, loop_start=2268, loop_end=3843, pcm=smp_444_pcm   @ loop 2268-3843
smp_445:	sample_hdr length=3945, rate=7884, root=60, loop_start=793, loop_end=2234, pcm=smp_445_pcm   @ loop 793-2234
smp_446:	sample_hdr length=10171, rate=7884, root=60, loop_start=2030, loop_end=3733, pcm=smp_446_pcm   @ loop 2030-3733
smp_447:	sample_hdr length=2347, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_447_pcm   @ no loop
smp_448:	sample_hdr length=3949, rate=7884, root=60, loop_start=992, loop_end=2847, pcm=smp_448_pcm   @ loop 992-2847
smp_449:	sample_hdr length=2324, rate=7884, root=60, loop_start=776, loop_end=1927, pcm=smp_449_pcm   @ loop 776-1927
smp_450:	sample_hdr length=1942, rate=7884, root=60, loop_start=463, loop_end=1743, pcm=smp_450_pcm   @ loop 463-1743
smp_451:	sample_hdr length=3385, rate=7884, root=60, loop_start=390, loop_end=1825, pcm=smp_451_pcm   @ loop 390-1825
smp_452:	sample_hdr length=3506, rate=7884, root=60, loop_start=964, loop_end=2308, pcm=smp_452_pcm   @ loop 964-2308
smp_453:	sample_hdr length=872, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_453_pcm   @ no loop
smp_454:	sample_hdr length=3381, rate=10512, root=60, loop_start=1059, loop_end=2071, pcm=smp_454_pcm   @ loop 1059-2071
smp_455:	sample_hdr length=3000, rate=7884, root=60, loop_start=990, loop_end=2357, pcm=smp_455_pcm   @ loop 990-2357
smp_456:	sample_hdr length=2610, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_456_pcm   @ no loop
smp_457:	sample_hdr length=2038, rate=7884, root=60, loop_start=995, loop_end=1976, pcm=smp_457_pcm   @ loop 995-1976
smp_458:	sample_hdr length=2512, rate=7884, root=60, loop_start=1089, loop_end=2006, pcm=smp_458_pcm   @ loop 1089-2006
smp_459:	sample_hdr length=2681, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_459_pcm   @ no loop
smp_460:	sample_hdr length=2707, rate=7884, root=60, loop_start=1393, loop_end=2093, pcm=smp_460_pcm   @ loop 1393-2093
smp_461:	sample_hdr length=4380, rate=7884, root=60, loop_start=1280, loop_end=2843, pcm=smp_461_pcm   @ loop 1280-2843
smp_462:	sample_hdr length=3112, rate=5734, root=60, loop_start=763, loop_end=2013, pcm=smp_462_pcm   @ loop 763-2013
smp_463:	sample_hdr length=1992, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_463_pcm   @ no loop
smp_464:	sample_hdr length=2076, rate=7884, root=60, loop_start=734, loop_end=1546, pcm=smp_464_pcm   @ loop 734-1546
smp_465:	sample_hdr length=1715, rate=7884, root=60, loop_start=50, loop_end=1330, pcm=smp_465_pcm   @ loop 50-1330
smp_466:	sample_hdr length=1881, rate=7884, root=60, loop_start=1014, loop_end=1533, pcm=smp_466_pcm   @ loop 1014-1533
smp_467:	sample_hdr length=1837, rate=7884, root=60, loop_start=989, loop_end=1521, pcm=smp_467_pcm   @ loop 989-1521
smp_468:	sample_hdr length=3635, rate=7884, root=60, loop_start=1223, loop_end=2844, pcm=smp_468_pcm   @ loop 1223-2844
smp_469:	sample_hdr length=1856, rate=7884, root=60, loop_start=678, loop_end=1558, pcm=smp_469_pcm   @ loop 678-1558
smp_470:	sample_hdr length=2033, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_470_pcm   @ no loop
smp_471:	sample_hdr length=1593, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_471_pcm   @ no loop
smp_472:	sample_hdr length=1857, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_472_pcm   @ no loop
smp_473:	sample_hdr length=2135, rate=7884, root=60, loop_start=736, loop_end=1472, pcm=smp_473_pcm   @ loop 736-1472
smp_474:	sample_hdr length=1290, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_474_pcm   @ no loop
smp_475:	sample_hdr length=3191, rate=7884, root=60, loop_start=755, loop_end=1680, pcm=smp_475_pcm   @ loop 755-1680
smp_476:	sample_hdr length=1756, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_476_pcm   @ no loop
smp_477:	sample_hdr length=2524, rate=7884, root=60, loop_start=643, loop_end=1289, pcm=smp_477_pcm   @ loop 643-1289
smp_478:	sample_hdr length=1519, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_478_pcm   @ no loop
smp_479:	sample_hdr length=1540, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_479_pcm   @ no loop
smp_480:	sample_hdr length=1411, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_480_pcm   @ no loop
smp_481:	sample_hdr length=1473, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_481_pcm   @ no loop
smp_482:	sample_hdr length=1332, rate=7884, root=60, loop_start=483, loop_end=1084, pcm=smp_482_pcm   @ loop 483-1084
smp_483:	sample_hdr length=1327, rate=7884, root=60, loop_start=666, loop_end=1309, pcm=smp_483_pcm   @ loop 666-1309
smp_484:	sample_hdr length=1989, rate=7884, root=60, loop_start=0, loop_end=1492, pcm=smp_484_pcm   @ loop 0-1492
smp_485:	sample_hdr length=2009, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_485_pcm   @ no loop
smp_486:	sample_hdr length=359, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_486_pcm   @ no loop
smp_487:	sample_hdr length=2729, rate=7884, root=60, loop_start=1068, loop_end=2026, pcm=smp_487_pcm   @ loop 1068-2026
smp_488:	sample_hdr length=1689, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_488_pcm   @ no loop
smp_489:	sample_hdr length=2595, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_489_pcm   @ no loop
smp_490:	sample_hdr length=1006, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_490_pcm   @ no loop
smp_491:	sample_hdr length=1615, rate=5734, root=60, loop_start=818, loop_end=1213, pcm=smp_491_pcm   @ loop 818-1213
smp_492:	sample_hdr length=1893, rate=7884, root=60, loop_start=517, loop_end=1269, pcm=smp_492_pcm   @ loop 517-1269
smp_493:	sample_hdr length=1999, rate=7884, root=60, loop_start=1188, loop_end=1939, pcm=smp_493_pcm   @ loop 1188-1939
smp_494:	sample_hdr length=4112, rate=7884, root=60, loop_start=2017, loop_end=3105, pcm=smp_494_pcm   @ loop 2017-3105
smp_495:	sample_hdr length=3987, rate=7884, root=60, loop_start=1699, loop_end=2709, pcm=smp_495_pcm   @ loop 1699-2709
smp_496:	sample_hdr length=1714, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_496_pcm   @ no loop
smp_497:	sample_hdr length=1321, rate=5734, root=60, loop_start=0, loop_end=0, pcm=smp_497_pcm   @ no loop
smp_498:	sample_hdr length=1120, rate=5734, root=60, loop_start=339, loop_end=952, pcm=smp_498_pcm   @ loop 339-952
smp_499:	sample_hdr length=1936, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_499_pcm   @ no loop
smp_500:	sample_hdr length=3516, rate=7884, root=60, loop_start=1838, loop_end=3318, pcm=smp_500_pcm   @ loop 1838-3318
smp_501:	sample_hdr length=3623, rate=7884, root=60, loop_start=1607, loop_end=2773, pcm=smp_501_pcm   @ loop 1607-2773
smp_502:	sample_hdr length=3314, rate=7884, root=60, loop_start=1643, loop_end=2963, pcm=smp_502_pcm   @ loop 1643-2963
smp_503:	sample_hdr length=3872, rate=7884, root=60, loop_start=1883, loop_end=2912, pcm=smp_503_pcm   @ loop 1883-2912
smp_504:	sample_hdr length=1161, rate=7884, root=60, loop_start=496, loop_end=1048, pcm=smp_504_pcm   @ loop 496-1048
smp_505:	sample_hdr length=2701, rate=7884, root=60, loop_start=1158, loop_end=2448, pcm=smp_505_pcm   @ loop 1158-2448
smp_506:	sample_hdr length=1242, rate=5734, root=60, loop_start=370, loop_end=722, pcm=smp_506_pcm   @ loop 370-722
smp_507:	sample_hdr length=2931, rate=10512, root=60, loop_start=1695, loop_end=2281, pcm=smp_507_pcm   @ loop 1695-2281
smp_508:	sample_hdr length=1791, rate=7884, root=60, loop_start=813, loop_end=1637, pcm=smp_508_pcm   @ loop 813-1637
smp_509:	sample_hdr length=1115, rate=7884, root=60, loop_start=34, loop_end=780, pcm=smp_509_pcm   @ loop 34-780
smp_510:	sample_hdr length=2061, rate=7884, root=60, loop_start=346, loop_end=1663, pcm=smp_510_pcm   @ loop 346-1663
smp_511:	sample_hdr length=14721, rate=44100, root=60, loop_start=2663, loop_end=9793, pcm=smp_511_pcm   @ loop 2663-9793
smp_512:	sample_hdr length=2689, rate=7884, root=60, loop_start=772, loop_end=2208, pcm=smp_512_pcm   @ loop 772-2208
smp_513:	sample_hdr length=1925, rate=7884, root=60, loop_start=19, loop_end=1566, pcm=smp_513_pcm   @ loop 19-1566
smp_514:	sample_hdr length=1296, rate=5734, root=60, loop_start=175, loop_end=907, pcm=smp_514_pcm   @ loop 175-907
smp_515:	sample_hdr length=1529, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_515_pcm   @ no loop
smp_516:	sample_hdr length=1566, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_516_pcm   @ no loop
smp_517:	sample_hdr length=2885, rate=10512, root=60, loop_start=934, loop_end=2272, pcm=smp_517_pcm   @ loop 934-2272
smp_518:	sample_hdr length=3961, rate=7884, root=60, loop_start=1722, loop_end=2816, pcm=smp_518_pcm   @ loop 1722-2816
smp_519:	sample_hdr length=2685, rate=7884, root=60, loop_start=723, loop_end=1922, pcm=smp_519_pcm   @ loop 723-1922
smp_520:	sample_hdr length=2384, rate=10512, root=60, loop_start=1026, loop_end=2289, pcm=smp_520_pcm   @ loop 1026-2289
smp_521:	sample_hdr length=2371, rate=7884, root=60, loop_start=1585, loop_end=2016, pcm=smp_521_pcm   @ loop 1585-2016
smp_522:	sample_hdr length=2081, rate=7884, root=60, loop_start=745, loop_end=1310, pcm=smp_522_pcm   @ loop 745-1310
smp_523:	sample_hdr length=3297, rate=7884, root=60, loop_start=2476, loop_end=3124, pcm=smp_523_pcm   @ loop 2476-3124
smp_524:	sample_hdr length=2501, rate=7884, root=60, loop_start=671, loop_end=2102, pcm=smp_524_pcm   @ loop 671-2102
smp_525:	sample_hdr length=1552, rate=7884, root=60, loop_start=13, loop_end=1466, pcm=smp_525_pcm   @ loop 13-1466
smp_526:	sample_hdr length=1917, rate=7884, root=60, loop_start=748, loop_end=1428, pcm=smp_526_pcm   @ loop 748-1428
smp_527:	sample_hdr length=2059, rate=7884, root=60, loop_start=498, loop_end=1293, pcm=smp_527_pcm   @ loop 498-1293
smp_528:	sample_hdr length=3638, rate=7884, root=60, loop_start=1592, loop_end=3212, pcm=smp_528_pcm   @ loop 1592-3212
smp_529:	sample_hdr length=2100, rate=10512, root=60, loop_start=12, loop_end=1994, pcm=smp_529_pcm   @ loop 12-1994
smp_530:	sample_hdr length=1834, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_530_pcm   @ no loop
smp_531:	sample_hdr length=2351, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_531_pcm   @ no loop
smp_532:	sample_hdr length=1545, rate=7884, root=60, loop_start=18, loop_end=1436, pcm=smp_532_pcm   @ loop 18-1436
smp_533:	sample_hdr length=1797, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_533_pcm   @ no loop
smp_534:	sample_hdr length=1977, rate=7884, root=60, loop_start=270, loop_end=1654, pcm=smp_534_pcm   @ loop 270-1654
smp_535:	sample_hdr length=4033, rate=7884, root=60, loop_start=1721, loop_end=3158, pcm=smp_535_pcm   @ loop 1721-3158
smp_536:	sample_hdr length=2390, rate=7884, root=60, loop_start=1213, loop_end=2206, pcm=smp_536_pcm   @ loop 1213-2206
smp_537:	sample_hdr length=1890, rate=7884, root=60, loop_start=311, loop_end=1456, pcm=smp_537_pcm   @ loop 311-1456
smp_538:	sample_hdr length=2309, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_538_pcm   @ no loop
smp_539:	sample_hdr length=2530, rate=7884, root=60, loop_start=378, loop_end=1848, pcm=smp_539_pcm   @ loop 378-1848
smp_540:	sample_hdr length=4222, rate=7884, root=60, loop_start=2040, loop_end=3538, pcm=smp_540_pcm   @ loop 2040-3538
smp_541:	sample_hdr length=2139, rate=5734, root=60, loop_start=11, loop_end=1065, pcm=smp_541_pcm   @ loop 11-1065
smp_542:	sample_hdr length=2012, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_542_pcm   @ no loop
smp_543:	sample_hdr length=1872, rate=7884, root=60, loop_start=579, loop_end=1627, pcm=smp_543_pcm   @ loop 579-1627
smp_544:	sample_hdr length=1905, rate=7884, root=60, loop_start=257, loop_end=1437, pcm=smp_544_pcm   @ loop 257-1437
smp_545:	sample_hdr length=3239, rate=10512, root=60, loop_start=1567, loop_end=2640, pcm=smp_545_pcm   @ loop 1567-2640
smp_546:	sample_hdr length=2447, rate=10512, root=60, loop_start=742, loop_end=2226, pcm=smp_546_pcm   @ loop 742-2226
smp_547:	sample_hdr length=2507, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_547_pcm   @ no loop
smp_548:	sample_hdr length=2823, rate=10512, root=60, loop_start=709, loop_end=2269, pcm=smp_548_pcm   @ loop 709-2269
smp_549:	sample_hdr length=2453, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_549_pcm   @ no loop
smp_550:	sample_hdr length=3292, rate=10512, root=60, loop_start=1007, loop_end=2916, pcm=smp_550_pcm   @ loop 1007-2916
smp_551:	sample_hdr length=4182, rate=10512, root=60, loop_start=1363, loop_end=3657, pcm=smp_551_pcm   @ loop 1363-3657
smp_552:	sample_hdr length=2978, rate=10512, root=60, loop_start=0, loop_end=0, pcm=smp_552_pcm   @ no loop
smp_553:	sample_hdr length=2098, rate=7884, root=60, loop_start=492, loop_end=1783, pcm=smp_553_pcm   @ loop 492-1783
smp_554:	sample_hdr length=2388, rate=7884, root=60, loop_start=917, loop_end=1866, pcm=smp_554_pcm   @ loop 917-1866
smp_555:	sample_hdr length=2271, rate=7884, root=60, loop_start=737, loop_end=2006, pcm=smp_555_pcm   @ loop 737-2006
smp_556:	sample_hdr length=1549, rate=7884, root=60, loop_start=136, loop_end=1449, pcm=smp_556_pcm   @ loop 136-1449
smp_557:	sample_hdr length=1473, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_557_pcm   @ no loop
smp_558:	sample_hdr length=1637, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_558_pcm   @ no loop
smp_559:	sample_hdr length=2708, rate=10512, root=60, loop_start=868, loop_end=2155, pcm=smp_559_pcm   @ loop 868-2155
smp_560:	sample_hdr length=2002, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_560_pcm   @ no loop
smp_561:	sample_hdr length=1924, rate=7884, root=60, loop_start=886, loop_end=1742, pcm=smp_561_pcm   @ loop 886-1742
smp_562:	sample_hdr length=2999, rate=10512, root=60, loop_start=435, loop_end=2621, pcm=smp_562_pcm   @ loop 435-2621
smp_563:	sample_hdr length=5022, rate=10512, root=60, loop_start=3578, loop_end=4942, pcm=smp_563_pcm   @ loop 3578-4942
smp_564:	sample_hdr length=2304, rate=7884, root=60, loop_start=490, loop_end=1825, pcm=smp_564_pcm   @ loop 490-1825
smp_565:	sample_hdr length=3068, rate=7884, root=60, loop_start=1564, loop_end=2904, pcm=smp_565_pcm   @ loop 1564-2904
smp_566:	sample_hdr length=3894, rate=7884, root=60, loop_start=2321, loop_end=3549, pcm=smp_566_pcm   @ loop 2321-3549
smp_567:	sample_hdr length=6242, rate=7884, root=60, loop_start=3724, loop_end=5174, pcm=smp_567_pcm   @ loop 3724-5174
smp_568:	sample_hdr length=3786, rate=7884, root=60, loop_start=0, loop_end=0, pcm=smp_568_pcm   @ no loop
smp_569:	sample_hdr length=4294, rate=7884, root=60, loop_start=2619, loop_end=3913, pcm=smp_569_pcm   @ loop 2619-3913
smp_570:	sample_hdr length=3743, rate=7884, root=60, loop_start=1977, loop_end=3130, pcm=smp_570_pcm   @ loop 1977-3130
smp_571:	sample_hdr length=3862, rate=7884, root=60, loop_start=1964, loop_end=3545, pcm=smp_571_pcm   @ loop 1964-3545
smp_572:	sample_hdr length=3849, rate=7884, root=60, loop_start=2830, loop_end=3624, pcm=smp_572_pcm   @ loop 2830-3624
smp_573:	sample_hdr length=3049, rate=7884, root=60, loop_start=1753, loop_end=2875, pcm=smp_573_pcm   @ loop 1753-2875
smp_574:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_574_pcm   @ no loop
smp_575:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_575_pcm   @ no loop
smp_576:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_576_pcm   @ no loop
smp_577:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_577_pcm   @ no loop
smp_578:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_578_pcm   @ no loop
smp_579:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_579_pcm   @ no loop
smp_580:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_580_pcm   @ no loop
smp_581:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_581_pcm   @ no loop
smp_582:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_582_pcm   @ no loop
smp_583:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_583_pcm   @ no loop
smp_584:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_584_pcm   @ no loop
smp_585:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_585_pcm   @ no loop
smp_586:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_586_pcm   @ no loop
smp_587:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_587_pcm   @ no loop
smp_588:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_588_pcm   @ no loop
smp_589:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_589_pcm   @ no loop
smp_590:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_590_pcm   @ no loop
smp_591:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_591_pcm   @ no loop
smp_592:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_592_pcm   @ no loop
smp_593:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_593_pcm   @ no loop
smp_594:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_594_pcm   @ no loop
smp_595:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_595_pcm   @ no loop
smp_596:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_596_pcm   @ no loop
smp_597:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_597_pcm   @ no loop
smp_598:	sample_hdr length=2324, rate=10512, root=60, loop_start=25, loop_end=2016, pcm=smp_598_pcm   @ loop 25-2016
smp_599:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_599_pcm   @ no loop
smp_600:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_600_pcm   @ no loop
smp_601:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_601_pcm   @ no loop
smp_602:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_602_pcm   @ no loop
smp_603:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_603_pcm   @ no loop
smp_604:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_604_pcm   @ no loop
smp_605:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_605_pcm   @ no loop
smp_606:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_606_pcm   @ no loop
smp_607:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_607_pcm   @ no loop
smp_608:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_608_pcm   @ no loop
smp_609:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_609_pcm   @ no loop
smp_610:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_610_pcm   @ no loop
smp_611:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_611_pcm   @ no loop
smp_612:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_612_pcm   @ no loop
smp_613:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_613_pcm   @ no loop
smp_614:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_614_pcm   @ no loop
smp_615:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_615_pcm   @ no loop
smp_616:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_616_pcm   @ no loop
smp_617:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_617_pcm   @ no loop
smp_618:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_618_pcm   @ no loop
smp_619:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_619_pcm   @ no loop
smp_620:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_620_pcm   @ no loop
smp_621:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_621_pcm   @ no loop
smp_622:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_622_pcm   @ no loop
smp_623:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_623_pcm   @ no loop
smp_624:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_624_pcm   @ no loop
smp_625:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_625_pcm   @ no loop
smp_626:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_626_pcm   @ no loop
smp_627:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_627_pcm   @ no loop
smp_628:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_628_pcm   @ no loop
smp_629:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_629_pcm   @ no loop
smp_630:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_630_pcm   @ no loop
smp_631:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_631_pcm   @ no loop
smp_632:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_632_pcm   @ no loop
smp_633:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_633_pcm   @ no loop
smp_634:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_634_pcm   @ no loop
smp_635:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_635_pcm   @ no loop
smp_636:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_636_pcm   @ no loop
smp_637:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_637_pcm   @ no loop
smp_638:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_638_pcm   @ no loop
smp_639:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_639_pcm   @ no loop
smp_640:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_640_pcm   @ no loop
smp_641:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_641_pcm   @ no loop
smp_642:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_642_pcm   @ no loop
smp_643:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_643_pcm   @ no loop
smp_644:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_644_pcm   @ no loop
smp_645:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_645_pcm   @ no loop
smp_646:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_646_pcm   @ no loop
smp_647:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_647_pcm   @ no loop
smp_648:	sample_hdr length=2, rate=3200, root=72, loop_start=0, loop_end=0, pcm=smp_648_pcm   @ no loop
smp_649:	sample_hdr length=2265, rate=5734, root=60, loop_start=1175, loop_end=2133, pcm=smp_649_pcm   @ loop 1175-2133
smp_650:	sample_hdr length=1814, rate=5734, root=60, loop_start=623, loop_end=1722, pcm=smp_650_pcm   @ loop 623-1722
smp_651:	sample_hdr length=1428, rate=5734, root=60, loop_start=66, loop_end=1307, pcm=smp_651_pcm   @ loop 66-1307
smp_652:	sample_hdr length=2988, rate=13379, root=72, loop_start=469, loop_end=1942, pcm=smp_652_pcm   @ loop 469-1942
smp_653:	sample_hdr length=2073, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_653_pcm   @ no loop
smp_654:	sample_hdr length=2675, rate=13379, root=72, loop_start=909, loop_end=1662, pcm=smp_654_pcm   @ loop 909-1662
smp_655:	sample_hdr length=3356, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_655_pcm   @ no loop
smp_656:	sample_hdr length=2917, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_656_pcm   @ no loop
smp_657:	sample_hdr length=6490, rate=13379, root=72, loop_start=1223, loop_end=2183, pcm=smp_657_pcm   @ loop 1223-2183
smp_658:	sample_hdr length=3381, rate=13379, root=79, loop_start=0, loop_end=0, pcm=smp_658_pcm   @ no loop
smp_659:	sample_hdr length=3058, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_659_pcm   @ no loop
smp_660:	sample_hdr length=2934, rate=13379, root=79, loop_start=1805, loop_end=2257, pcm=smp_660_pcm   @ loop 1805-2257
smp_661:	sample_hdr length=1516, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_661_pcm   @ no loop
smp_662:	sample_hdr length=2959, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_662_pcm   @ no loop
smp_663:	sample_hdr length=1944, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_663_pcm   @ no loop
smp_664:	sample_hdr length=1220, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_664_pcm   @ no loop
smp_665:	sample_hdr length=3666, rate=13379, root=72, loop_start=698, loop_end=1657, pcm=smp_665_pcm   @ loop 698-1657
smp_666:	sample_hdr length=2587, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_666_pcm   @ no loop
smp_667:	sample_hdr length=1771, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_667_pcm   @ no loop
smp_668:	sample_hdr length=2535, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_668_pcm   @ no loop
smp_669:	sample_hdr length=627, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_669_pcm   @ no loop
smp_670:	sample_hdr length=2438, rate=13379, root=72, loop_start=460, loop_end=1626, pcm=smp_670_pcm   @ loop 460-1626
smp_671:	sample_hdr length=4606, rate=13379, root=72, loop_start=1072, loop_end=1927, pcm=smp_671_pcm   @ loop 1072-1927
smp_672:	sample_hdr length=1249, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_672_pcm   @ no loop
smp_673:	sample_hdr length=978, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_673_pcm   @ no loop
smp_674:	sample_hdr length=1301, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_674_pcm   @ no loop
smp_675:	sample_hdr length=3753, rate=13379, root=72, loop_start=1713, loop_end=2361, pcm=smp_675_pcm   @ loop 1713-2361
smp_676:	sample_hdr length=3466, rate=13379, root=72, loop_start=1231, loop_end=1660, pcm=smp_676_pcm   @ loop 1231-1660
smp_677:	sample_hdr length=4168, rate=13379, root=72, loop_start=945, loop_end=2065, pcm=smp_677_pcm   @ loop 945-2065
smp_678:	sample_hdr length=2008, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_678_pcm   @ no loop
smp_679:	sample_hdr length=3276, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_679_pcm   @ no loop
smp_680:	sample_hdr length=3338, rate=13379, root=72, loop_start=2013, loop_end=2527, pcm=smp_680_pcm   @ loop 2013-2527
smp_681:	sample_hdr length=2702, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_681_pcm   @ no loop
smp_682:	sample_hdr length=2317, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_682_pcm   @ no loop
smp_683:	sample_hdr length=956, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_683_pcm   @ no loop
smp_684:	sample_hdr length=2441, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_684_pcm   @ no loop
smp_685:	sample_hdr length=3798, rate=13379, root=72, loop_start=1373, loop_end=2089, pcm=smp_685_pcm   @ loop 1373-2089
smp_686:	sample_hdr length=2093, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_686_pcm   @ no loop
smp_687:	sample_hdr length=1814, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_687_pcm   @ no loop
smp_688:	sample_hdr length=2559, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_688_pcm   @ no loop
smp_689:	sample_hdr length=1356, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_689_pcm   @ no loop
smp_690:	sample_hdr length=3494, rate=13379, root=72, loop_start=1098, loop_end=1379, pcm=smp_690_pcm   @ loop 1098-1379
smp_691:	sample_hdr length=3175, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_691_pcm   @ no loop
smp_692:	sample_hdr length=3717, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_692_pcm   @ no loop
smp_693:	sample_hdr length=1080, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_693_pcm   @ no loop
smp_694:	sample_hdr length=1072, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_694_pcm   @ no loop
smp_695:	sample_hdr length=3351, rate=13379, root=72, loop_start=2194, loop_end=2557, pcm=smp_695_pcm   @ loop 2194-2557
smp_696:	sample_hdr length=2316, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_696_pcm   @ no loop
smp_697:	sample_hdr length=2625, rate=13379, root=72, loop_start=1254, loop_end=1619, pcm=smp_697_pcm   @ loop 1254-1619
smp_698:	sample_hdr length=1624, rate=13379, root=72, loop_start=793, loop_end=1385, pcm=smp_698_pcm   @ loop 793-1385
smp_699:	sample_hdr length=1954, rate=13379, root=72, loop_start=977, loop_end=1374, pcm=smp_699_pcm   @ loop 977-1374
smp_700:	sample_hdr length=3979, rate=13379, root=72, loop_start=694, loop_end=1300, pcm=smp_700_pcm   @ loop 694-1300
smp_701:	sample_hdr length=1720, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_701_pcm   @ no loop
smp_702:	sample_hdr length=4005, rate=13379, root=72, loop_start=1002, loop_end=2092, pcm=smp_702_pcm   @ loop 1002-2092
smp_703:	sample_hdr length=1764, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_703_pcm   @ no loop
smp_704:	sample_hdr length=3850, rate=13379, root=72, loop_start=1458, loop_end=2007, pcm=smp_704_pcm   @ loop 1458-2007
smp_705:	sample_hdr length=1598, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_705_pcm   @ no loop
smp_706:	sample_hdr length=2387, rate=13379, root=72, loop_start=1143, loop_end=1505, pcm=smp_706_pcm   @ loop 1143-1505
smp_707:	sample_hdr length=1809, rate=13379, root=72, loop_start=0, loop_end=0, pcm=smp_707_pcm   @ no loop
smp_708:	sample_hdr length=5140, rate=13379, root=72, loop_start=1328, loop_end=1934, pcm=smp_708_pcm   @ loop 1328-1934
smp_709:	sample_hdr length=3687, rate=13379, root=72, loop_start=1935, loop_end=2510, pcm=smp_709_pcm   @ loop 1935-2510
smp_710:	sample_hdr length=5464, rate=13379, root=72, loop_start=1344, loop_end=2194, pcm=smp_710_pcm   @ loop 1344-2194
