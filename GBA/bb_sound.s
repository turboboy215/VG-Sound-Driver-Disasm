@ Brownie Brown sound driver (Magical Vacation, AMVJ) -- labelled disassembly
@ Rebuilds byte-identical with bb_sound.mk. Names are assigned by analysis; see technical reference.
	.syntax unified
	.cpu arm7tdmi
	.include "bb_sound.inc"

	.section .text.bb_sound, "ax", %progbits
	.thumb

@ ================================================================
@ Game-side C glue (Thumb). Each wrapper BLs a linker veneer that switches to ARM.
@   void Sound_Play(u16 id);   void Sound_Init(void);   void Sound_Frame(void);  (VBlank)
@   void Sound_FifoAIrq(void); void Sound_FifoBIrq(void);  (DMA1 / DMA2 IRQ)
@   void Sound_FadeOut(u8 n);
@ ================================================================
	.global Sound_Play
	.type Sound_Play, %function
Sound_Play:
	push {lr}	@ 0805B564
	lsls r0, r0, #0x10	@ 0805B566
	lsrs r0, r0, #0x10	@ 0805B568
	bl vnr_sndQueueSound	@ 0805B56A
	pop {r0}	@ 0805B56E
	bx r0	@ 0805B570
	movs r0, r0	@ 0805B572
	.global Sound_Init
	.type Sound_Init, %function
Sound_Init:
	push {lr}	@ 0805B574
	bl vnr_sndInit	@ 0805B576
	pop {r0}	@ 0805B57A
	bx r0	@ 0805B57C
	movs r0, r0	@ 0805B57E
	.global Sound_Frame
	.type Sound_Frame, %function
Sound_Frame:
	push {lr}	@ 0805B580
	bl vnr_sndFrame	@ 0805B582
	pop {r0}	@ 0805B586
	bx r0	@ 0805B588
	movs r0, r0	@ 0805B58A
	.global Sound_FifoAIrq
	.type Sound_FifoAIrq, %function
Sound_FifoAIrq:
	push {lr}	@ 0805B58C
	bl vnr_sndFifoAIrq	@ 0805B58E
	pop {r0}	@ 0805B592
	bx r0	@ 0805B594
	movs r0, r0	@ 0805B596
	.global Sound_FifoBIrq
	.type Sound_FifoBIrq, %function
Sound_FifoBIrq:
	push {lr}	@ 0805B598
	bl vnr_sndFifoBIrq	@ 0805B59A
	pop {r0}	@ 0805B59E
	bx r0	@ 0805B5A0
	movs r0, r0	@ 0805B5A2
	.global Sound_FadeOut
	.type Sound_FadeOut, %function
Sound_FadeOut:
	push {lr}	@ 0805B5A4
	lsls r0, r0, #0x18	@ 0805B5A6
	lsrs r0, r0, #0x18	@ 0805B5A8
	bl vnr_sndFadeOut	@ 0805B5AA
	pop {r0}	@ 0805B5AE
	bx r0	@ 0805B5B0
	movs r0, r0	@ 0805B5B2

@ psgFreqTable[84]: GB frequency register values, note 0 = C2 (65.4 Hz on the square
@ channels; the wave channel sounds one octave lower). Trigger bit is added by the driver.
psgFreqTable:
	.hword 0x02C, 0x09D, 0x107, 0x16B, 0x1C9, 0x223, 0x277, 0x2C7, 0x312, 0x358, 0x39B, 0x3DA	@ 0805B5B4
	.hword 0x416, 0x44E, 0x483, 0x4B5, 0x4E5, 0x511, 0x53B, 0x563, 0x589, 0x5AC, 0x5CE, 0x5ED	@ 0805B5CC
	.hword 0x60B, 0x627, 0x642, 0x65B, 0x672, 0x689, 0x69E, 0x6B2, 0x6C4, 0x6D6, 0x6E7, 0x6F7	@ 0805B5E4
	.hword 0x706, 0x714, 0x721, 0x72D, 0x739, 0x744, 0x74F, 0x759, 0x762, 0x76B, 0x773, 0x77B	@ 0805B5FC
	.hword 0x783, 0x78A, 0x790, 0x797, 0x79D, 0x7A2, 0x7A7, 0x7AC, 0x7B1, 0x7B6, 0x7BA, 0x7BE	@ 0805B614
	.hword 0x7C1, 0x7C5, 0x7C8, 0x7CB, 0x7CE, 0x7D1, 0x7D4, 0x7D6, 0x7D9, 0x7DB, 0x7DD, 0x7DF	@ 0805B62C
	.hword 0x7E1, 0x7E2, 0x7E4, 0x7E6, 0x7E7, 0x7E9, 0x7EA, 0x7EB, 0x7EC, 0x7ED, 0x7EE, 0x7EF	@ 0805B644

@ Per-track PSG register addresses (tracks 0-7; 4-7 alias 0-3).
@ psgEnvRegTable: NRx2 / duty-length (CNT_H) register; psgCtrlRegTable: frequency/trigger (CNT_X) register.
@ NOTE: commands ED/FD on PCM tracks 8-11 index past these 8 entries (driver quirk).
psgEnvRegTable:
	.word REG_SOUND1CNT_H	@ 0805B65C
	.word REG_SOUND2CNT_L	@ 0805B660
	.word REG_SOUND3CNT_H	@ 0805B664
	.word REG_SOUND4CNT_L	@ 0805B668
	.word REG_SOUND1CNT_H	@ 0805B66C
	.word REG_SOUND2CNT_L	@ 0805B670
	.word REG_SOUND3CNT_H	@ 0805B674
	.word REG_SOUND4CNT_L	@ 0805B678
psgCtrlRegTable:
	.word REG_SOUND1CNT_X	@ 0805B67C
	.word REG_SOUND2CNT_H	@ 0805B680
	.word REG_SOUND3CNT_X	@ 0805B684
	.word REG_SOUND4CNT_H	@ 0805B688
	.word REG_SOUND1CNT_X	@ 0805B68C
	.word REG_SOUND2CNT_H	@ 0805B690
	.word REG_SOUND3CNT_X	@ 0805B694
	.word REG_SOUND4CNT_H	@ 0805B698

@ panBitsTable[12] / panMaskTable[12]: SOUNDCNT_L high-byte enable bits per track and the
@ AND mask that clears them. Copied into track +0x2A/+0x2B when a sound starts.
panBitsTable:
	.byte 0x11, 0x22, 0x44, 0x88, 0x11, 0x22, 0x44, 0x88, 0x11, 0x22, 0x44, 0x88	@ 0805B69C
panMaskTable:
	.byte 0xEE, 0xDD, 0xBB, 0x77, 0xEE, 0xDD, 0xBB, 0x77, 0xEE, 0xDD, 0xBB, 0x77	@ 0805B6A8

@ pcmPitchTable[85*12]: timer reload values. Index = note*12 + detune (1/12 semitone).
@ Output rate = 16777216 / (0x10000 - v) = 1024 * 2^(index/144) Hz (index 0 -> 1024 Hz).
pcmPitchTable:
	.hword 0xC000, 0xC04F, 0xC09D, 0xC0EB, 0xC138, 0xC186, 0xC1D2, 0xC21F, 0xC26B, 0xC2B7, 0xC302, 0xC34D	@ 0805B6B4  note 0
	.hword 0xC398, 0xC3E2, 0xC42C, 0xC475, 0xC4BE, 0xC507, 0xC550, 0xC598, 0xC5E0, 0xC627, 0xC66E, 0xC6B5	@ 0805B6CC  note 1
	.hword 0xC6FC, 0xC742, 0xC787, 0xC7CD, 0xC812, 0xC857, 0xC89B, 0xC8DF, 0xC923, 0xC966, 0xC9A9, 0xC9EC	@ 0805B6E4  note 2
	.hword 0xCA2F, 0xCA71, 0xCAB3, 0xCAF4, 0xCB35, 0xCB76, 0xCBB7, 0xCBF7, 0xCC37, 0xCC77, 0xCCB6, 0xCCF5	@ 0805B6FC  note 3
	.hword 0xCD34, 0xCD72, 0xCDB1, 0xCDEE, 0xCE2C, 0xCE69, 0xCEA6, 0xCEE3, 0xCF1F, 0xCF5B, 0xCF97, 0xCFD3	@ 0805B714  note 4
	.hword 0xD00E, 0xD049, 0xD083, 0xD0BE, 0xD0F8, 0xD132, 0xD16B, 0xD1A5, 0xD1DE, 0xD216, 0xD24F, 0xD287	@ 0805B72C  note 5
	.hword 0xD2BF, 0xD2F6, 0xD32E, 0xD365, 0xD39C, 0xD3D2, 0xD409, 0xD43F, 0xD474, 0xD4AA, 0xD4DF, 0xD514	@ 0805B744  note 6
	.hword 0xD549, 0xD57E, 0xD5B2, 0xD5E6, 0xD61A, 0xD64D, 0xD680, 0xD6B3, 0xD6E6, 0xD719, 0xD74B, 0xD77D	@ 0805B75C  note 7
	.hword 0xD7AF, 0xD7E0, 0xD812, 0xD843, 0xD874, 0xD8A4, 0xD8D5, 0xD905, 0xD935, 0xD964, 0xD994, 0xD9C3	@ 0805B774  note 8
	.hword 0xD9F2, 0xDA21, 0xDA4F, 0xDA7E, 0xDAAC, 0xDADA, 0xDB07, 0xDB35, 0xDB62, 0xDB8F, 0xDBBC, 0xDBE8	@ 0805B78C  note 9
	.hword 0xDC15, 0xDC41, 0xDC6D, 0xDC99, 0xDCC4, 0xDCEF, 0xDD1B, 0xDD45, 0xDD70, 0xDD9B, 0xDDC5, 0xDDEF	@ 0805B7A4  note 10
	.hword 0xDE19, 0xDE43, 0xDE6C, 0xDE95, 0xDEBE, 0xDEE7, 0xDF10, 0xDF38, 0xDF61, 0xDF89, 0xDFB1, 0xDFD8	@ 0805B7BC  note 11
	.hword 0xE000, 0xE027, 0xE04E, 0xE075, 0xE09C, 0xE0C3, 0xE0E9, 0xE10F, 0xE135, 0xE15B, 0xE181, 0xE1A6	@ 0805B7D4  note 12
	.hword 0xE1CC, 0xE1F1, 0xE216, 0xE23B, 0xE25F, 0xE284, 0xE2A8, 0xE2CC, 0xE2F0, 0xE314, 0xE337, 0xE35B	@ 0805B7EC  note 13
	.hword 0xE37E, 0xE3A1, 0xE3C4, 0xE3E6, 0xE409, 0xE42B, 0xE44E, 0xE470, 0xE491, 0xE4B3, 0xE4D5, 0xE4F6	@ 0805B804  note 14
	.hword 0xE517, 0xE538, 0xE559, 0xE57A, 0xE59B, 0xE5BB, 0xE5DB, 0xE5FC, 0xE61C, 0xE63B, 0xE65B, 0xE67B	@ 0805B81C  note 15
	.hword 0xE69A, 0xE6B9, 0xE6D8, 0xE6F7, 0xE716, 0xE735, 0xE753, 0xE771, 0xE790, 0xE7AE, 0xE7CC, 0xE7E9	@ 0805B834  note 16
	.hword 0xE807, 0xE824, 0xE842, 0xE85F, 0xE87C, 0xE899, 0xE8B6, 0xE8D2, 0xE8EF, 0xE90B, 0xE927, 0xE943	@ 0805B84C  note 17
	.hword 0xE95F, 0xE97B, 0xE997, 0xE9B2, 0xE9CE, 0xE9E9, 0xEA04, 0xEA1F, 0xEA3A, 0xEA55, 0xEA70, 0xEA8A	@ 0805B864  note 18
	.hword 0xEAA4, 0xEABF, 0xEAD9, 0xEAF3, 0xEB0D, 0xEB27, 0xEB40, 0xEB5A, 0xEB73, 0xEB8C, 0xEBA5, 0xEBBE	@ 0805B87C  note 19
	.hword 0xEBD7, 0xEBF0, 0xEC09, 0xEC21, 0xEC3A, 0xEC52, 0xEC6A, 0xEC82, 0xEC9A, 0xECB2, 0xECCA, 0xECE2	@ 0805B894  note 20
	.hword 0xECF9, 0xED10, 0xED28, 0xED3F, 0xED56, 0xED6D, 0xED84, 0xED9A, 0xEDB1, 0xEDC8, 0xEDDE, 0xEDF4	@ 0805B8AC  note 21
	.hword 0xEE0A, 0xEE20, 0xEE36, 0xEE4C, 0xEE62, 0xEE78, 0xEE8D, 0xEEA3, 0xEEB8, 0xEECD, 0xEEE2, 0xEEF8	@ 0805B8C4  note 22
	.hword 0xEF0C, 0xEF21, 0xEF36, 0xEF4B, 0xEF5F, 0xEF74, 0xEF88, 0xEF9C, 0xEFB0, 0xEFC4, 0xEFD8, 0xEFEC	@ 0805B8DC  note 23
	.hword 0xF000, 0xF014, 0xF027, 0xF03B, 0xF04E, 0xF061, 0xF075, 0xF088, 0xF09B, 0xF0AE, 0xF0C0, 0xF0D3	@ 0805B8F4  note 24
	.hword 0xF0E6, 0xF0F8, 0xF10B, 0xF11D, 0xF130, 0xF142, 0xF154, 0xF166, 0xF178, 0xF18A, 0xF19C, 0xF1AD	@ 0805B90C  note 25
	.hword 0xF1BF, 0xF1D0, 0xF1E2, 0xF1F3, 0xF204, 0xF216, 0xF227, 0xF238, 0xF249, 0xF25A, 0xF26A, 0xF27B	@ 0805B924  note 26
	.hword 0xF28C, 0xF29C, 0xF2AD, 0xF2BD, 0xF2CD, 0xF2DE, 0xF2EE, 0xF2FE, 0xF30E, 0xF31E, 0xF32E, 0xF33D	@ 0805B93C  note 27
	.hword 0xF34D, 0xF35D, 0xF36C, 0xF37C, 0xF38B, 0xF39A, 0xF3AA, 0xF3B9, 0xF3C8, 0xF3D7, 0xF3E6, 0xF3F5	@ 0805B954  note 28
	.hword 0xF403, 0xF412, 0xF421, 0xF42F, 0xF43E, 0xF44C, 0xF45B, 0xF469, 0xF477, 0xF486, 0xF494, 0xF4A2	@ 0805B96C  note 29
	.hword 0xF4B0, 0xF4BE, 0xF4CB, 0xF4D9, 0xF4E7, 0xF4F5, 0xF502, 0xF510, 0xF51D, 0xF52A, 0xF538, 0xF545	@ 0805B984  note 30
	.hword 0xF552, 0xF55F, 0xF56C, 0xF579, 0xF586, 0xF593, 0xF5A0, 0xF5AD, 0xF5BA, 0xF5C6, 0xF5D3, 0xF5DF	@ 0805B99C  note 31
	.hword 0xF5EC, 0xF5F8, 0xF604, 0xF611, 0xF61D, 0xF629, 0xF635, 0xF641, 0xF64D, 0xF659, 0xF665, 0xF671	@ 0805B9B4  note 32
	.hword 0xF67D, 0xF688, 0xF694, 0xF69F, 0xF6AB, 0xF6B6, 0xF6C2, 0xF6CD, 0xF6D9, 0xF6E4, 0xF6EF, 0xF6FA	@ 0805B9CC  note 33
	.hword 0xF705, 0xF710, 0xF71B, 0xF726, 0xF731, 0xF73C, 0xF747, 0xF751, 0xF75C, 0xF767, 0xF771, 0xF77C	@ 0805B9E4  note 34
	.hword 0xF786, 0xF791, 0xF79B, 0xF7A5, 0xF7B0, 0xF7BA, 0xF7C4, 0xF7CE, 0xF7D8, 0xF7E2, 0xF7EC, 0xF7F6	@ 0805B9FC  note 35
	.hword 0xF800, 0xF80A, 0xF814, 0xF81D, 0xF827, 0xF831, 0xF83A, 0xF844, 0xF84D, 0xF857, 0xF860, 0xF86A	@ 0805BA14  note 36
	.hword 0xF873, 0xF87C, 0xF885, 0xF88F, 0xF898, 0xF8A1, 0xF8AA, 0xF8B3, 0xF8BC, 0xF8C5, 0xF8CE, 0xF8D7	@ 0805BA2C  note 37
	.hword 0xF8DF, 0xF8E8, 0xF8F1, 0xF8FA, 0xF902, 0xF90B, 0xF913, 0xF91C, 0xF924, 0xF92D, 0xF935, 0xF93E	@ 0805BA44  note 38
	.hword 0xF946, 0xF94E, 0xF956, 0xF95F, 0xF967, 0xF96F, 0xF977, 0xF97F, 0xF987, 0xF98F, 0xF997, 0xF99F	@ 0805BA5C  note 39
	.hword 0xF9A7, 0xF9AE, 0xF9B6, 0xF9BE, 0xF9C5, 0xF9CD, 0xF9D5, 0xF9DC, 0xF9E4, 0xF9EB, 0xF9F3, 0xF9FA	@ 0805BA74  note 40
	.hword 0xFA02, 0xFA09, 0xFA10, 0xFA18, 0xFA1F, 0xFA26, 0xFA2D, 0xFA35, 0xFA3C, 0xFA43, 0xFA4A, 0xFA51	@ 0805BA8C  note 41
	.hword 0xFA58, 0xFA5F, 0xFA66, 0xFA6D, 0xFA73, 0xFA7A, 0xFA81, 0xFA88, 0xFA8F, 0xFA95, 0xFA9C, 0xFAA3	@ 0805BAA4  note 42
	.hword 0xFAA9, 0xFAB0, 0xFAB6, 0xFABD, 0xFAC3, 0xFACA, 0xFAD0, 0xFAD6, 0xFADD, 0xFAE3, 0xFAE9, 0xFAF0	@ 0805BABC  note 43
	.hword 0xFAF6, 0xFAFC, 0xFB02, 0xFB08, 0xFB0E, 0xFB15, 0xFB1B, 0xFB21, 0xFB27, 0xFB2D, 0xFB32, 0xFB38	@ 0805BAD4  note 44
	.hword 0xFB3E, 0xFB44, 0xFB4A, 0xFB50, 0xFB55, 0xFB5B, 0xFB61, 0xFB67, 0xFB6C, 0xFB72, 0xFB77, 0xFB7D	@ 0805BAEC  note 45
	.hword 0xFB83, 0xFB88, 0xFB8E, 0xFB93, 0xFB99, 0xFB9E, 0xFBA3, 0xFBA9, 0xFBAE, 0xFBB3, 0xFBB9, 0xFBBE	@ 0805BB04  note 46
	.hword 0xFBC3, 0xFBC8, 0xFBCE, 0xFBD3, 0xFBD8, 0xFBDD, 0xFBE2, 0xFBE7, 0xFBEC, 0xFBF1, 0xFBF6, 0xFBFB	@ 0805BB1C  note 47
	.hword 0xFC00, 0xFC05, 0xFC0A, 0xFC0F, 0xFC14, 0xFC18, 0xFC1D, 0xFC22, 0xFC27, 0xFC2B, 0xFC30, 0xFC35	@ 0805BB34  note 48
	.hword 0xFC39, 0xFC3E, 0xFC43, 0xFC47, 0xFC4C, 0xFC50, 0xFC55, 0xFC59, 0xFC5E, 0xFC62, 0xFC67, 0xFC6B	@ 0805BB4C  note 49
	.hword 0xFC70, 0xFC74, 0xFC78, 0xFC7D, 0xFC81, 0xFC85, 0xFC8A, 0xFC8E, 0xFC92, 0xFC96, 0xFC9B, 0xFC9F	@ 0805BB64  note 50
	.hword 0xFCA3, 0xFCA7, 0xFCAB, 0xFCAF, 0xFCB3, 0xFCB7, 0xFCBB, 0xFCBF, 0xFCC3, 0xFCC7, 0xFCCB, 0xFCCF	@ 0805BB7C  note 51
	.hword 0xFCD3, 0xFCD7, 0xFCDB, 0xFCDF, 0xFCE3, 0xFCE7, 0xFCEA, 0xFCEE, 0xFCF2, 0xFCF6, 0xFCF9, 0xFCFD	@ 0805BB94  note 52
	.hword 0xFD01, 0xFD05, 0xFD08, 0xFD0C, 0xFD0F, 0xFD13, 0xFD17, 0xFD1A, 0xFD1E, 0xFD21, 0xFD25, 0xFD28	@ 0805BBAC  note 53
	.hword 0xFD2C, 0xFD2F, 0xFD33, 0xFD36, 0xFD3A, 0xFD3D, 0xFD41, 0xFD44, 0xFD47, 0xFD4B, 0xFD4E, 0xFD51	@ 0805BBC4  note 54
	.hword 0xFD55, 0xFD58, 0xFD5B, 0xFD5E, 0xFD62, 0xFD65, 0xFD68, 0xFD6B, 0xFD6E, 0xFD72, 0xFD75, 0xFD78	@ 0805BBDC  note 55
	.hword 0xFD7B, 0xFD7E, 0xFD81, 0xFD84, 0xFD87, 0xFD8A, 0xFD8D, 0xFD90, 0xFD93, 0xFD96, 0xFD99, 0xFD9C	@ 0805BBF4  note 56
	.hword 0xFD9F, 0xFDA2, 0xFDA5, 0xFDA8, 0xFDAB, 0xFDAE, 0xFDB0, 0xFDB3, 0xFDB6, 0xFDB9, 0xFDBC, 0xFDBF	@ 0805BC0C  note 57
	.hword 0xFDC1, 0xFDC4, 0xFDC7, 0xFDCA, 0xFDCC, 0xFDCF, 0xFDD2, 0xFDD4, 0xFDD7, 0xFDDA, 0xFDDC, 0xFDDF	@ 0805BC24  note 58
	.hword 0xFDE2, 0xFDE4, 0xFDE7, 0xFDE9, 0xFDEC, 0xFDEE, 0xFDF1, 0xFDF4, 0xFDF6, 0xFDF9, 0xFDFB, 0xFDFE	@ 0805BC3C  note 59
	.hword 0xFE00, 0xFE03, 0xFE05, 0xFE08, 0xFE0A, 0xFE0D, 0xFE0F, 0xFE11, 0xFE14, 0xFE16, 0xFE19, 0xFE1B	@ 0805BC54  note 60
	.hword 0xFE1D, 0xFE20, 0xFE22, 0xFE24, 0xFE26, 0xFE29, 0xFE2B, 0xFE2D, 0xFE2F, 0xFE32, 0xFE34, 0xFE36	@ 0805BC6C  note 61
	.hword 0xFE38, 0xFE3B, 0xFE3D, 0xFE3F, 0xFE41, 0xFE43, 0xFE45, 0xFE47, 0xFE4A, 0xFE4C, 0xFE4E, 0xFE50	@ 0805BC84  note 62
	.hword 0xFE52, 0xFE54, 0xFE56, 0xFE58, 0xFE5A, 0xFE5C, 0xFE5E, 0xFE60, 0xFE62, 0xFE64, 0xFE66, 0xFE68	@ 0805BC9C  note 63
	.hword 0xFE6A, 0xFE6C, 0xFE6E, 0xFE70, 0xFE72, 0xFE74, 0xFE76, 0xFE78, 0xFE79, 0xFE7B, 0xFE7D, 0xFE7F	@ 0805BCB4  note 64
	.hword 0xFE81, 0xFE83, 0xFE85, 0xFE86, 0xFE88, 0xFE8A, 0xFE8C, 0xFE8E, 0xFE8F, 0xFE91, 0xFE93, 0xFE95	@ 0805BCCC  note 65
	.hword 0xFE96, 0xFE98, 0xFE9A, 0xFE9C, 0xFE9D, 0xFE9F, 0xFEA1, 0xFEA2, 0xFEA4, 0xFEA6, 0xFEA7, 0xFEA9	@ 0805BCE4  note 66
	.hword 0xFEAB, 0xFEAC, 0xFEAE, 0xFEB0, 0xFEB1, 0xFEB3, 0xFEB5, 0xFEB6, 0xFEB8, 0xFEB9, 0xFEBB, 0xFEBC	@ 0805BCFC  note 67
	.hword 0xFEBE, 0xFEC0, 0xFEC1, 0xFEC3, 0xFEC4, 0xFEC6, 0xFEC7, 0xFEC9, 0xFECA, 0xFECC, 0xFECD, 0xFECF	@ 0805BD14  note 68
	.hword 0xFED0, 0xFED2, 0xFED3, 0xFED4, 0xFED6, 0xFED7, 0xFED9, 0xFEDA, 0xFEDC, 0xFEDD, 0xFEDE, 0xFEE0	@ 0805BD2C  note 69
	.hword 0xFEE1, 0xFEE3, 0xFEE4, 0xFEE5, 0xFEE7, 0xFEE8, 0xFEE9, 0xFEEB, 0xFEEC, 0xFEED, 0xFEEF, 0xFEF0	@ 0805BD44  note 70
	.hword 0xFEF1, 0xFEF3, 0xFEF4, 0xFEF5, 0xFEF6, 0xFEF8, 0xFEF9, 0xFEFA, 0xFEFC, 0xFEFD, 0xFEFE, 0xFEFF	@ 0805BD5C  note 71
	.hword 0xFF00, 0xFF02, 0xFF03, 0xFF04, 0xFF05, 0xFF07, 0xFF08, 0xFF09, 0xFF0A, 0xFF0B, 0xFF0D, 0xFF0E	@ 0805BD74  note 72
	.hword 0xFF0F, 0xFF10, 0xFF11, 0xFF12, 0xFF13, 0xFF15, 0xFF16, 0xFF17, 0xFF18, 0xFF19, 0xFF1A, 0xFF1B	@ 0805BD8C  note 73
	.hword 0xFF1C, 0xFF1E, 0xFF1F, 0xFF20, 0xFF21, 0xFF22, 0xFF23, 0xFF24, 0xFF25, 0xFF26, 0xFF27, 0xFF28	@ 0805BDA4  note 74
	.hword 0xFF29, 0xFF2A, 0xFF2B, 0xFF2C, 0xFF2D, 0xFF2E, 0xFF2F, 0xFF30, 0xFF31, 0xFF32, 0xFF33, 0xFF34	@ 0805BDBC  note 75
	.hword 0xFF35, 0xFF36, 0xFF37, 0xFF38, 0xFF39, 0xFF3A, 0xFF3B, 0xFF3C, 0xFF3D, 0xFF3E, 0xFF3F, 0xFF40	@ 0805BDD4  note 76
	.hword 0xFF41, 0xFF42, 0xFF43, 0xFF43, 0xFF44, 0xFF45, 0xFF46, 0xFF47, 0xFF48, 0xFF49, 0xFF4A, 0xFF4B	@ 0805BDEC  note 77
	.hword 0xFF4B, 0xFF4C, 0xFF4D, 0xFF4E, 0xFF4F, 0xFF50, 0xFF51, 0xFF51, 0xFF52, 0xFF53, 0xFF54, 0xFF55	@ 0805BE04  note 78
	.hword 0xFF56, 0xFF56, 0xFF57, 0xFF58, 0xFF59, 0xFF5A, 0xFF5B, 0xFF5B, 0xFF5C, 0xFF5D, 0xFF5E, 0xFF5E	@ 0805BE1C  note 79
	.hword 0xFF5F, 0xFF60, 0xFF61, 0xFF62, 0xFF62, 0xFF63, 0xFF64, 0xFF65, 0xFF65, 0xFF66, 0xFF67, 0xFF68	@ 0805BE34  note 80
	.hword 0xFF68, 0xFF69, 0xFF6A, 0xFF6A, 0xFF6B, 0xFF6C, 0xFF6D, 0xFF6D, 0xFF6E, 0xFF6F, 0xFF6F, 0xFF70	@ 0805BE4C  note 81
	.hword 0xFF71, 0xFF72, 0xFF72, 0xFF73, 0xFF74, 0xFF74, 0xFF75, 0xFF76, 0xFF76, 0xFF77, 0xFF78, 0xFF78	@ 0805BE64  note 82
	.hword 0xFF79, 0xFF7A, 0xFF7A, 0xFF7B, 0xFF7B, 0xFF7C, 0xFF7D, 0xFF7D, 0xFF7E, 0xFF7F, 0xFF7F, 0xFF80	@ 0805BE7C  note 83
	.hword 0xFF80, 0xFF81, 0xFF82, 0xFF82, 0xFF83, 0xFF84, 0xFF84, 0xFF85, 0xFF85, 0xFF86, 0xFF87, 0xFF87	@ 0805BE94  note 84
	.arm

@ ----------------------------------------------------------------
@ void sndQueueSound(u16 id)   (r0 = id)
@     sndQueue[sndQueueWrite] = id; sndQueueWrite = (sndQueueWrite + 2) & 7;
@     4-entry ring of u16 ids. sndFrame starts at most one queued id per frame.
@ ----------------------------------------------------------------
	.global sndQueueSound
	.type sndQueueSound, %function
sndQueueSound:
	ldr r1, .Lp_sndQueueWrite	@ 0805BEAC  r1 = &sndQueueWrite
	ldrb r2, [r1]	@ 0805BEB0
	ldr r3, .Lp_sndQueue	@ 0805BEB4
	strh r0, [r3, r2]	@ 0805BEB8  sndQueue[w] = id
	add r2, r2, #2	@ 0805BEBC
	and r2, r2, #7	@ 0805BEC0  w = (w + 2) & 7
	strb r2, [r1]	@ 0805BEC4
	bx lr	@ 0805BEC8

@ ----------------------------------------------------------------
@ void sndFadeOut(u8 n)        fade the master volume to 0 over 8*n frames, then stop all.
@     sndMaster.fadeFrames = n*8;
@     if (n >= 32) { fadeAcc = fadePeriod = n*8;  step = 1; }   // 1 level every n*8/256 frames
@     else         { fadeAcc = fadePeriod = 0x100; step = ~32/n (6-bit binary division); }  // per frame
@ ----------------------------------------------------------------
	.global sndFadeOut
	.type sndFadeOut, %function
sndFadeOut:
	ldr r1, .Lp_sndMaster	@ 0805BECC
	lsl r2, r0, #3	@ 0805BED0
	strh r2, [r1, #2]	@ 0805BED4  fadeFrames = n*8
	cmp r0, #0x20	@ 0805BED8  n >= 32 ?
	bmi .Lfade_short	@ 0805BEDC
	str r2, [r1, #4]	@ 0805BEE0
	str r2, [r1, #8]	@ 0805BEE4
	mov r3, #1	@ 0805BEE8
	strb r3, [r1, #1]	@ 0805BEEC  step = 1
	bx lr	@ 0805BEF0
.Lfade_short:
	mov r2, #0x100	@ 0805BEF4
	str r2, [r1, #4]	@ 0805BEF8
	str r2, [r1, #8]	@ 0805BEFC
	lsl r0, r0, #5	@ 0805BF00
	mov r1, #0x20	@ 0805BF04
	mov r2, #6	@ 0805BF08
	mov r3, #0	@ 0805BF0C
.Lfade_divLoop:
	cmp r1, r0	@ 0805BF10
	subpl r1, r1, r0	@ 0805BF14
	addpl r3, r3, #1	@ 0805BF18
	lsr r0, r0, #1	@ 0805BF1C
	sub r2, r2, #1	@ 0805BF20
	teq r2, #0	@ 0805BF24
	lslne r3, r3, #1	@ 0805BF28
	bne .Lfade_divLoop	@ 0805BF2C
	ldr r1, .Lp_sndMaster_2	@ 0805BF30
	strb r3, [r1, #1]	@ 0805BF34  step = quotient
	bx lr	@ 0805BF38

@ ----------------------------------------------------------------
@ void sndInit(void)
@     SOUNDCNT_H = 0xC80E (reset FIFOs) then 0x730E: PSG 100 %, A/B 100 %, A+B both sides,
@                  A on timer 0, B on timer 1.  SOUNDCNT_L = 0x77 (shadowed in sndSoundCntL).
@     SOUNDCNT_X = 0 then 0x8F.  Silence all four PSG channels (env 0, trigger).
@     All 12 tracks inactive, queue empty, timers 0/1 stopped, sndMaster.volume = 0xFF.
@     NOTE: one of the 0x8000 writes goes to 0x0400007A (unused) instead of SOUND4CNT_H.
@ ----------------------------------------------------------------
	.global sndInit
	.type sndInit, %function
sndInit:
	ldr r3, .Lp_REG_SOUND1CNT_L	@ 0805BF3C
	ldr r0, .Lp_0x0000C80E	@ 0805BF40
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 0805BF44  SOUNDCNT_H = 0xC80E (FIFO reset)
	ldr r0, .Lp_0x0000730E	@ 0805BF48
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 0805BF4C  SOUNDCNT_H = 0x730E
	mov r0, #0x77	@ 0805BF50
	strh r0, [r3, #IO_SOUNDCNT_L]	@ 0805BF54  SOUNDCNT_L = 0x77
	ldr r1, .Lp_sndSoundCntL	@ 0805BF58
	strh r0, [r1]	@ 0805BF5C
	mov r0, #0	@ 0805BF60
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 0805BF64
	mov r0, #0x8f	@ 0805BF68
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 0805BF6C  SOUNDCNT_X = 0x8F (master on)
	mov r0, #0	@ 0805BF70
	strh r0, [r3, #IO_SOUND1CNT_H]	@ 0805BF74
	strh r0, [r3, #IO_SOUND2CNT_L]	@ 0805BF78
	strh r0, [r3, #IO_SOUND4CNT_L]	@ 0805BF7C
	strh r0, [r3, #IO_SOUND3CNT_H]	@ 0805BF80
	strh r0, [r3]	@ 0805BF84
	mov r0, #0x8000	@ 0805BF88
	strh r0, [r3, #IO_SOUND1CNT_X]	@ 0805BF8C
	strh r0, [r3, #IO_SOUND2CNT_H]	@ 0805BF90
	strh r0, [r3, #IO_SOUND3CNT_X]	@ 0805BF94
	strh r0, [r3, #IO_UNUSED_7A]	@ 0805BF98  writes 0x0400007A (unused) -- intended SOUND4CNT_H?
	mov r0, #0	@ 0805BF9C
	ldr r1, .Lp_sndTracks	@ 0805BFA0
.Linit_clearTracks:
	strb r0, [r1], #0x38	@ 0805BFA4  track.flags = 0, step 0x38
	ldr r2, .Lp_sndQueueRead	@ 0805BFA8
	teq r1, r2	@ 0805BFAC
	bne .Linit_clearTracks	@ 0805BFB0
	strh r0, [r1]	@ 0805BFB4
	str r0, [r1, #2]	@ 0805BFB8
	str r0, [r1, #6]	@ 0805BFBC
	strh r0, [r3, #IO_TM0CNT_H]	@ 0805BFC0  TM0CNT_H = 0
	strh r0, [r3, #IO_TM1CNT_H]	@ 0805BFC4  TM1CNT_H = 0
	ldr r0, .Lp_sndMaster_3	@ 0805BFC8
	mov r1, #0xff	@ 0805BFCC
	str r1, [r0]	@ 0805BFD0  sndMaster: volume 0xFF, step/fade 0
	bx lr	@ 0805BFD4

@ ----------------------------------------------------------------
@ void sndFifoAIrq(void)       DMA1 IRQ. Feeds FIFO A with one 32-bit word (4 s8 samples).
@     The game never sets DMA1 SAD/DAD; DMA1 (0xF600: FIFO timing, IRQ) acts only as the
@     "FIFO A wants data" interrupt and the CPU writes the samples itself.
@     w = *stream.cur++;  if (stream.cur == stream.end) { if (loop == end) stop TM0 else cur = loop; }
@     each byte s: s' = round(s * (stream.vol + 1) / 256)   (sign-magnitude, +0x80 rounding)
@     FIFO_A = s'0 | s'1<<8 ; FIFO_A+2 = s'2 | s'3<<8
@ ----------------------------------------------------------------
	.global sndFifoAIrq
	.type sndFifoAIrq, %function
sndFifoAIrq:
	stmdb sp!, {r4}	@ 0805BFD8
	mov r0, #0x200	@ 0805BFDC
	ldr r1, .Lp_REG_IF	@ 0805BFE0
	strh r0, [r1]	@ 0805BFE4  IF = DMA1 (ack)
	ldr r0, .Lp_sndStreamA	@ 0805BFE8
	ldr r1, [r0]	@ 0805BFEC
	ldr r2, [r1], #4	@ 0805BFF0  w = *cur++
	str r1, [r0]	@ 0805BFF4
	ldr r3, [r0, #4]	@ 0805BFF8
	teq r1, r3	@ 0805BFFC  cur == end ?
	beq .LfifoA_end	@ 0805C000
.LfifoA_word:
	ldrb r3, [r0, #0xc]	@ 0805C004  scale = vol + 1
	add r3, r3, #1	@ 0805C008
	and r0, r2, #0xff	@ 0805C00C
	tst r0, #0x80	@ 0805C010
	beq .L_0805C03C	@ 0805C014
	mvn r0, r0	@ 0805C018
	add r0, r0, #1	@ 0805C01C
	and r0, r0, #0xff	@ 0805C020
	mul r1, r0, r3	@ 0805C024
	tst r1, #0x80	@ 0805C028
	addne r1, r1, #0x100	@ 0805C02C
	mvn r1, r1	@ 0805C030
	add r1, r1, #1	@ 0805C034
	b .L_0805C048	@ 0805C038
.L_0805C03C:
	mul r1, r0, r3	@ 0805C03C
	tst r1, #0x80	@ 0805C040
	addne r1, r1, #0x100	@ 0805C044
.L_0805C048:
	and r0, r2, #0xff00	@ 0805C048
	tst r0, #0x8000	@ 0805C04C
	beq .L_0805C078	@ 0805C050
	mvn r0, r0	@ 0805C054
	add r0, r0, #1	@ 0805C058
	and r0, r0, #0xff00	@ 0805C05C
	mul r4, r0, r3	@ 0805C060
	tst r4, #0x8000	@ 0805C064
	addne r4, r4, #0x10000	@ 0805C068
	mvn r4, r4	@ 0805C06C
	add r4, r4, #1	@ 0805C070
	b .L_0805C084	@ 0805C074
.L_0805C078:
	mul r4, r0, r3	@ 0805C078
	tst r4, #0x8000	@ 0805C07C
	addne r4, r4, #0x10000	@ 0805C080
.L_0805C084:
	lsr r0, r4, #8	@ 0805C084
	and r0, r0, #0xff00	@ 0805C088
	add r0, r0, r1, lsr #8	@ 0805C08C
	ldr r1, .Lp_REG_FIFO_A	@ 0805C090
	strh r0, [r1]	@ 0805C094  FIFO_A = bytes 0,1
	lsr r2, r2, #0x10	@ 0805C098
	and r0, r2, #0xff	@ 0805C09C
	tst r0, #0x80	@ 0805C0A0
	beq .L_0805C0CC	@ 0805C0A4
	mvn r0, r0	@ 0805C0A8
	add r0, r0, #1	@ 0805C0AC
	and r0, r0, #0xff	@ 0805C0B0
	mul r1, r0, r3	@ 0805C0B4
	tst r1, #0x80	@ 0805C0B8
	addne r1, r1, #0x100	@ 0805C0BC
	mvn r1, r1	@ 0805C0C0
	add r1, r1, #1	@ 0805C0C4
	b .L_0805C0D8	@ 0805C0C8
.L_0805C0CC:
	mul r1, r0, r3	@ 0805C0CC
	tst r1, #0x80	@ 0805C0D0
	addne r1, r1, #0x100	@ 0805C0D4
.L_0805C0D8:
	and r0, r2, #0xff00	@ 0805C0D8
	tst r0, #0x8000	@ 0805C0DC
	beq .L_0805C108	@ 0805C0E0
	mvn r0, r0	@ 0805C0E4
	add r0, r0, #1	@ 0805C0E8
	and r0, r0, #0xff00	@ 0805C0EC
	mul r4, r0, r3	@ 0805C0F0
	tst r4, #0x8000	@ 0805C0F4
	addne r4, r4, #0x10000	@ 0805C0F8
	mvn r4, r4	@ 0805C0FC
	add r4, r4, #1	@ 0805C100
	b .L_0805C114	@ 0805C104
.L_0805C108:
	mul r4, r0, r3	@ 0805C108
	tst r4, #0x8000	@ 0805C10C
	addne r4, r4, #0x10000	@ 0805C110
.L_0805C114:
	lsr r0, r4, #8	@ 0805C114
	and r0, r0, #0xff00	@ 0805C118
	add r0, r0, r1, lsr #8	@ 0805C11C
	ldr r1, .Lp_REG_FIFO_A_2	@ 0805C120
	strh r0, [r1]	@ 0805C124  FIFO_A+2 = bytes 2,3
.LfifoA_ret:
	ldm sp!, {r4}	@ 0805C128
	bx lr	@ 0805C12C
.LfifoA_end:
	ldr r3, [r0, #8]	@ 0805C130  loop pointer
	teq r1, r3	@ 0805C134
	strne r3, [r0]	@ 0805C138  loop != end: cur = loop, play word
	bne .LfifoA_word	@ 0805C13C
	mov r0, #0	@ 0805C140
	ldr r1, .Lp_REG_TM0CNT_H	@ 0805C144
	strh r0, [r1]	@ 0805C148  stop timer 0
	b .LfifoA_ret	@ 0805C14C

@ ----------------------------------------------------------------
@ void sndFifoBIrq(void)       DMA2 IRQ. Same as sndFifoAIrq for FIFO B / sndStreamB / timer 1.
@ ----------------------------------------------------------------
	.global sndFifoBIrq
	.type sndFifoBIrq, %function
sndFifoBIrq:
	stmdb sp!, {r4}	@ 0805C150
	mov r0, #0x400	@ 0805C154
	ldr r1, .Lp_REG_IF	@ 0805C158
	strh r0, [r1]	@ 0805C15C  IF = DMA2 (ack)
	ldr r0, .Lp_sndStreamB	@ 0805C160
	ldr r1, [r0]	@ 0805C164
	ldr r2, [r1], #4	@ 0805C168
	str r1, [r0]	@ 0805C16C
	ldr r3, [r0, #4]	@ 0805C170
	teq r1, r3	@ 0805C174
	beq .LfifoB_end	@ 0805C178
.LfifoB_word:
	ldr r3, [r0, #0xc]	@ 0805C17C
	add r3, r3, #1	@ 0805C180
	and r0, r2, #0xff	@ 0805C184
	tst r0, #0x80	@ 0805C188
	beq .L_0805C1B4	@ 0805C18C
	mvn r0, r0	@ 0805C190
	add r0, r0, #1	@ 0805C194
	and r0, r0, #0xff	@ 0805C198
	mul r1, r0, r3	@ 0805C19C
	tst r1, #0x80	@ 0805C1A0
	addne r1, r1, #0x100	@ 0805C1A4
	mvn r1, r1	@ 0805C1A8
	add r1, r1, #1	@ 0805C1AC
	b .L_0805C1C0	@ 0805C1B0
.L_0805C1B4:
	mul r1, r0, r3	@ 0805C1B4
	tst r1, #0x80	@ 0805C1B8
	addne r1, r1, #0x100	@ 0805C1BC
.L_0805C1C0:
	and r0, r2, #0xff00	@ 0805C1C0
	tst r0, #0x8000	@ 0805C1C4
	beq .L_0805C1F0	@ 0805C1C8
	mvn r0, r0	@ 0805C1CC
	add r0, r0, #1	@ 0805C1D0
	and r0, r0, #0xff00	@ 0805C1D4
	mul r4, r0, r3	@ 0805C1D8
	tst r4, #0x8000	@ 0805C1DC
	addne r4, r4, #0x10000	@ 0805C1E0
	mvn r4, r4	@ 0805C1E4
	add r4, r4, #1	@ 0805C1E8
	b .L_0805C1FC	@ 0805C1EC
.L_0805C1F0:
	mul r4, r0, r3	@ 0805C1F0
	tst r4, #0x8000	@ 0805C1F4
	addne r4, r4, #0x10000	@ 0805C1F8
.L_0805C1FC:
	lsr r0, r4, #8	@ 0805C1FC
	and r0, r0, #0xff00	@ 0805C200
	add r0, r0, r1, lsr #8	@ 0805C204
	ldr r1, .Lp_REG_FIFO_B	@ 0805C208
	strh r0, [r1]	@ 0805C20C
	lsr r2, r2, #0x10	@ 0805C210
	and r0, r2, #0xff	@ 0805C214
	tst r0, #0x80	@ 0805C218
	beq .L_0805C244	@ 0805C21C
	mvn r0, r0	@ 0805C220
	add r0, r0, #1	@ 0805C224
	and r0, r0, #0xff	@ 0805C228
	mul r1, r0, r3	@ 0805C22C
	tst r1, #0x80	@ 0805C230
	addne r1, r1, #0x100	@ 0805C234
	mvn r1, r1	@ 0805C238
	add r1, r1, #1	@ 0805C23C
	b .L_0805C250	@ 0805C240
.L_0805C244:
	mul r1, r0, r3	@ 0805C244
	tst r1, #0x80	@ 0805C248
	addne r1, r1, #0x100	@ 0805C24C
.L_0805C250:
	and r0, r2, #0xff00	@ 0805C250
	tst r0, #0x8000	@ 0805C254
	beq .L_0805C280	@ 0805C258
	mvn r0, r0	@ 0805C25C
	add r0, r0, #1	@ 0805C260
	and r0, r0, #0xff00	@ 0805C264
	mul r4, r0, r3	@ 0805C268
	tst r4, #0x8000	@ 0805C26C
	addne r4, r4, #0x10000	@ 0805C270
	mvn r4, r4	@ 0805C274
	add r4, r4, #1	@ 0805C278
	b .L_0805C28C	@ 0805C27C
.L_0805C280:
	mul r4, r0, r3	@ 0805C280
	tst r4, #0x8000	@ 0805C284
	addne r4, r4, #0x10000	@ 0805C288
.L_0805C28C:
	lsr r0, r4, #8	@ 0805C28C
	and r0, r0, #0xff00	@ 0805C290
	add r0, r0, r1, lsr #8	@ 0805C294
	ldr r1, .Lp_REG_FIFO_B_2	@ 0805C298
	strh r0, [r1]	@ 0805C29C
.LfifoB_ret:
	ldm sp!, {r4}	@ 0805C2A0
	bx lr	@ 0805C2A4
.LfifoB_end:
	ldr r3, [r0, #8]	@ 0805C2A8
	teq r1, r3	@ 0805C2AC
	strne r3, [r0]	@ 0805C2B0
	bne .LfifoB_word	@ 0805C2B4
	mov r0, #0	@ 0805C2B8
	ldr r1, .Lp_REG_TM1CNT_H	@ 0805C2BC
	strh r0, [r1]	@ 0805C2C0  stop timer 1
	b .LfifoB_ret	@ 0805C2C4

@ ================================================================
@ void sndFrame(void)          once per frame (VBlank)
@   for (n = 0; n < 12; n++) { Track *t = &sndTracks[n];
@       if (!(t->flags & 1)) continue;
@       if (--t->wait == 0) { parse(t); continue; }        // .Lparse
@       if (t->envWait && --t->envWait == 0) envStep(t);   // .Lenv_step / .Lenv_stepPcm
@       if (n >= 8 && t->slideWait && --t->slideWait == 0) pcmSlide(t);
@   }
@   fade tick (sndMaster), then start one queued sound id.
@   Track = 0x38 bytes, see bb_sound.inc.  Tracks 0-3 PSG music, 4-7 PSG SE (mute 0-3),
@   8/9 PCM music (FIFO A/B), 10/11 PCM SE (mute 8/9). r7 = track index, r1 = Track*,
@   r8 = REG_SOUND1CNT_L (I/O base) inside the parser.
@ ================================================================
	.global sndFrame
	.type sndFrame, %function
sndFrame:
	push {r4, r5, r6, r7, r8}	@ 0805C2C8
	mov r7, #0	@ 0805C2CC
	ldr r1, .Lp_sndTracks_2	@ 0805C2D0
.Lframe_trackLoop:
	ldrb r2, [r1]	@ 0805C2D4
	tst r2, #1	@ 0805C2D8  active?
	beq .Lframe_nextTrack	@ 0805C2DC
	ldrb r2, [r1, #TRK_WAIT]	@ 0805C2E0
	sub r2, r2, #1	@ 0805C2E4  --wait
	cmp r2, #0	@ 0805C2E8
	beq .Lparse	@ 0805C2EC  wait expired -> parse
	strb r2, [r1, #TRK_WAIT]	@ 0805C2F0
	ldrb r2, [r1, #TRK_ENVWAIT]	@ 0805C2F4
	teq r2, #0	@ 0805C2F8  envWait == 0: hold
	beq .Lframe_slideTick	@ 0805C2FC
	sub r2, r2, #1	@ 0805C300
	cmp r2, #0	@ 0805C304
	beq .Lenv_step	@ 0805C308  -> envelope step
	strb r2, [r1, #TRK_ENVWAIT]	@ 0805C30C
.Lframe_slideTick:
	tst r7, #8	@ 0805C310  PCM tracks only
	beq .Lframe_nextTrack	@ 0805C314
	ldrb r2, [r1, #TRK_DUTY]	@ 0805C318
	teq r2, #0	@ 0805C31C
	beq .Lframe_nextTrack	@ 0805C320
	sub r2, r2, #1	@ 0805C324
	teq r2, #0	@ 0805C328
	beq .Lpcm_slide	@ 0805C32C  -> PCM slide
	strb r2, [r1, #TRK_DUTY]	@ 0805C330
.Lframe_nextTrack:
	add r1, r1, #0x38	@ 0805C334
	add r7, r7, #1	@ 0805C338
	teq r7, #0xc	@ 0805C33C  12 tracks
	bne .Lframe_trackLoop	@ 0805C340

@ ---- master fade (sndMaster: +0 volume, +1 step, +2 frames left, +4 acc 8.8, +8 period 8.8)
	ldr r0, .Lp_sndMaster_4	@ 0805C344
	ldrh r1, [r0, #2]	@ 0805C348
	teq r1, #0	@ 0805C34C  fade active?
	bne .Lfade_tick	@ 0805C350
.Lframe_queue:
	ldr r2, .Lp_sndQueueRead_2	@ 0805C354
	ldrb r0, [r2], #1	@ 0805C358
	ldrb r1, [r2], #1	@ 0805C35C
	cmp r0, r1	@ 0805C360
	bne .Lqueue_start	@ 0805C364  queue not empty -> start a sound
	pop {r4, r5, r6, r7, r8}	@ 0805C368
	bx lr	@ 0805C36C
.Lfade_tick:
	sub r1, r1, #1	@ 0805C370
	strh r1, [r0, #2]	@ 0805C374
	teq r1, #0	@ 0805C378
	beq .Lfade_done	@ 0805C37C  fade finished -> stop everything
	ldrh r1, [r0, #4]	@ 0805C380
	sub r1, r1, #0x100	@ 0805C384  acc -= 1.0
	tst r1, #0xff00	@ 0805C388
	strhne r1, [r0, #4]	@ 0805C38C
	bne .Lframe_queue	@ 0805C390
	ldrh r2, [r0, #8]	@ 0805C394  acc += period
	add r1, r1, r2	@ 0805C398
	strh r1, [r0, #4]	@ 0805C39C
	ldrb r1, [r0]	@ 0805C3A0
	ldrb r2, [r0, #1]	@ 0805C3A4
	cmp r1, r2	@ 0805C3A8
	movmi r1, #0	@ 0805C3AC
	subpl r1, r1, r2	@ 0805C3B0  volume -= step (floor 0)
	strb r1, [r0]	@ 0805C3B4
	lsr r2, r1, #5	@ 0805C3B8
	lsl r3, r2, #4	@ 0805C3BC  NR50 = (vol>>5) * 0x11
	add r2, r3, r2	@ 0805C3C0
	ldr r4, .Lp_sndSoundCntL_2	@ 0805C3C4
	ldrh r3, [r4]	@ 0805C3C8
	and r3, r3, #0xff00	@ 0805C3CC
	orr r3, r3, r2	@ 0805C3D0
	strh r3, [r4]	@ 0805C3D4
	ldr r8, .Lp_REG_SOUND1CNT_L	@ 0805C3D8
	strh r3, [r8, #IO_SOUNDCNT_L]	@ 0805C3DC
	ldr r0, .Lp_sndTracks_0x1C0	@ 0805C3E0  PCM tracks 8-11
	mov r6, #8	@ 0805C3E4
.Lfade_pcmLoop:
	ldrb r2, [r0]	@ 0805C3E8
	tst r2, #1	@ 0805C3EC
	beq .Lfade_pcmNext	@ 0805C3F0
	ldrb r3, [r0, #TRK_SWEEP]	@ 0805C3F4
	add r4, r1, #1	@ 0805C3F8
	mul r5, r4, r3	@ 0805C3FC
	tst r5, #0x80	@ 0805C400  stream vol = (vol+1)*t.vol25 >> 8 (rounded)
	addne r5, r5, #0x100	@ 0805C404
	lsr r3, r5, #8	@ 0805C408
	tst r2, #2	@ 0805C40C
	bne .Lfade_pcmNext	@ 0805C410
	ldr r2, .Lp_sndStreamA_0xC	@ 0805C414
	tst r6, #1	@ 0805C418
	streq r3, [r2]	@ 0805C41C
	strne r3, [r2, #0x10]	@ 0805C420
.Lfade_pcmNext:
	add r6, r6, #1	@ 0805C424
	add r0, r0, #0x38	@ 0805C428
	teq r6, #0xc	@ 0805C42C
	bne .Lfade_pcmLoop	@ 0805C430
	b .Lframe_queue	@ 0805C434
.Lfade_done:
	ldr r3, .Lp_REG_SOUND1CNT_L	@ 0805C438
	ldr r0, .Lp_0x0000C80E	@ 0805C43C
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 0805C440
	ldr r0, .Lp_0x0000730E	@ 0805C444
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 0805C448
	mov r0, #0	@ 0805C44C
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 0805C450
	mov r0, #0x8f	@ 0805C454
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 0805C458
	mov r0, #0x77	@ 0805C45C
	strh r0, [r3, #IO_SOUNDCNT_L]	@ 0805C460
	ldr r1, .Lp_sndSoundCntL_3	@ 0805C464
	strh r0, [r1]	@ 0805C468
	mov r0, #0	@ 0805C46C
	strh r0, [r3, #IO_SOUND1CNT_H]	@ 0805C470
	strh r0, [r3, #IO_SOUND2CNT_L]	@ 0805C474
	strh r0, [r3, #IO_SOUND4CNT_L]	@ 0805C478
	mov r0, #0	@ 0805C47C
	strh r0, [r3, #IO_SOUND3CNT_H]	@ 0805C480
	strh r0, [r3]	@ 0805C484
	mov r0, #0x8000	@ 0805C488
	strh r0, [r3, #IO_SOUND1CNT_X]	@ 0805C48C
	strh r0, [r3, #IO_SOUND2CNT_H]	@ 0805C490
	strh r0, [r3, #IO_SOUND3CNT_X]	@ 0805C494
	strh r0, [r3, #IO_UNUSED_7A]	@ 0805C498
	mov r0, #0	@ 0805C49C
	ldr r1, .Lp_sndTracks_3	@ 0805C4A0
.Lfade_clearTracks:
	strb r0, [r1], #0x38	@ 0805C4A4
	ldr r2, .Lp_sndQueueRead_3	@ 0805C4A8
	teq r1, r2	@ 0805C4AC
	bne .Lfade_clearTracks	@ 0805C4B0
	strh r0, [r3, #IO_TM0CNT_H]	@ 0805C4B4
	strh r0, [r3, #IO_TM1CNT_H]	@ 0805C4B8
	ldr r0, .Lp_sndMaster_5	@ 0805C4BC
	mov r1, #0xff	@ 0805C4C0
	str r1, [r0]	@ 0805C4C4
	b .Lframe_queue	@ 0805C4C8

@ ---- start sound id: hdr = seqSongTable[id];  { u32 track, u8 *seq, u8 **patterns } ... 0xFF
@   t->flags |= 1; t->ptr = seq; t->patterns = patterns; clear +0x24..+0x2F; t->wait = 1;
@   t->panBits = panBitsTable[track]; t->panMask = panMaskTable[track];
@   track 4-7 sets flag 2 (muted) on track-4; track 10/11 on track-2.
.Lqueue_start:
	mov r1, #0	@ 0805C4CC
	ldrh r1, [r2, r0]	@ 0805C4D0  id = sndQueue[r]
	mov r3, #0	@ 0805C4D4
	strh r3, [r2, r0]	@ 0805C4D8  clear slot
	add r0, r0, #2	@ 0805C4DC
	and r0, r0, #7	@ 0805C4E0  r = (r + 2) & 7
	ldr r2, .Lp_sndQueueRead_4	@ 0805C4E4
	strb r0, [r2]	@ 0805C4E8
	ldr r2, .Lp_seqSongTable	@ 0805C4EC
	ldr r0, [r2, r1, lsl #2]	@ 0805C4F0  hdr = seqSongTable[id]
.Lstart_trackLoop:
	ldr r1, [r0], #4	@ 0805C4F4
	cmp r1, #0xff	@ 0805C4F8  end of header (0xFF)
	beq .Lframe_return	@ 0805C4FC
	mov r3, #0x38	@ 0805C500
	ldr r2, .Lp_sndTracks_4	@ 0805C504
	mla r2, r1, r3, r2	@ 0805C508  t = &sndTracks[track]
	ldrb r3, [r2]	@ 0805C50C
	orr r3, r3, #1	@ 0805C510
	strb r3, [r2]	@ 0805C514
	ldr r3, [r0], #4	@ 0805C518
	ldr r4, [r0], #4	@ 0805C51C
	str r3, [r2, #TRK_PTR]	@ 0805C520  t->ptr
	str r4, [r2, #TRK_PATTERNS]	@ 0805C524  t->patterns
	mov r3, #0	@ 0805C528
	str r3, [r2, #TRK_DUTY]	@ 0805C52C
	str r3, [r2, #TRK_LEVEL]	@ 0805C530
	str r3, [r2, #TRK_TRANSP]	@ 0805C534
	mov r3, #1	@ 0805C538
	strb r3, [r2, #TRK_WAIT]	@ 0805C53C  t->wait = 1
	ldr r3, .Lp_panBitsTable	@ 0805C540
	ldrb r4, [r3, r1]!	@ 0805C544
	strb r4, [r2, #TRK_PANBITS]	@ 0805C548  t->panBits
	ldrb r4, [r3, #0xc]	@ 0805C54C
	strb r4, [r2, #TRK_PANMASK]	@ 0805C550  t->panMask
	cmp r1, #4	@ 0805C554
	bmi .Lstart_trackLoop	@ 0805C558
	cmp r1, #8	@ 0805C55C
	movmi r3, #0xe0	@ 0805C560
	bmi .Lstart_muteMusic	@ 0805C564
	b .Lstart_pcmSe	@ 0805C568
.Lstart_muteMusic:
	sub r2, r2, r3	@ 0805C56C
	ldrb r1, [r2]	@ 0805C570
	orr r1, r1, #2	@ 0805C574  mute music track (flag 2)
	strb r1, [r2]	@ 0805C578
	b .Lstart_trackLoop	@ 0805C57C
.Lstart_pcmSe:
	cmp r1, #0xa	@ 0805C580
	movpl r3, #0x70	@ 0805C584
	bmi .Lstart_trackLoop	@ 0805C588
	b .Lstart_muteMusic	@ 0805C58C
.Lframe_return:
	pop {r4, r5, r6, r7, r8}	@ 0805C590
	bx lr	@ 0805C594

@ ---- envelope step (PSG): { u8 frames, u8 nrx2 } pairs from t->envPos. frames 0 = hold.
@   value is attenuated by t->volume (subtract, floor 0) and the channel is retriggered.
.Lenv_step:
	tst r7, #8	@ 0805C598
	bne .Lenv_stepPcm	@ 0805C59C
	ldr r2, [r1, #TRK_ENVPOS]	@ 0805C5A0
	ldrb r0, [r2], #1	@ 0805C5A4
	strb r0, [r1, #TRK_ENVWAIT]	@ 0805C5A8  t->envWait = frames
	ldrb r3, [r2], #1	@ 0805C5AC
	strb r3, [r1, #TRK_LEVEL]	@ 0805C5B0  t->level = nrx2
	str r2, [r1, #TRK_ENVPOS]	@ 0805C5B4
	ldrb r2, [r1]	@ 0805C5B8
	tst r2, #2	@ 0805C5BC
	bne .Lenv_stepDone	@ 0805C5C0
	ldrb r2, [r1, #TRK_VOLUME]	@ 0805C5C4
	sub r3, r3, r2	@ 0805C5C8  nrx2 - t->volume
	tst r3, #0xff0000	@ 0805C5CC
	movne r3, #0	@ 0805C5D0
	ldrb r2, [r1, #TRK_DUTY]	@ 0805C5D4
	add r3, r2, r3, lsl #8	@ 0805C5D8
	strh r3, [r1, #TRK_ENVREG]	@ 0805C5DC  t->envReg = duty | env<<8
	ldr r2, .Lp_psgEnvRegTable	@ 0805C5E0
	ldr r2, [r2, r7, lsl #2]	@ 0805C5E4
	strh r3, [r2]	@ 0805C5E8
	ldr r2, .Lp_psgCtrlRegTable	@ 0805C5EC
	ldr r2, [r2, r7, lsl #2]	@ 0805C5F0
	ldrh r3, [r1, #TRK_FREQ]	@ 0805C5F4
	orr r3, r3, #0x8000	@ 0805C5F8
	strh r3, [r2]	@ 0805C5FC  retrigger (bit 15)
.Lenv_stepDone:
	b .Lframe_nextTrack	@ 0805C600

@ ---- envelope step (PCM): { u8 frames, u8 slide (hi: period, lo: bit3 down, bits0-2 amount), u8 level }
.Lenv_stepPcm:
	ldr r2, [r1, #TRK_ENVPOS]	@ 0805C604
	ldrb r3, [r2], #1	@ 0805C608
	strb r3, [r1, #TRK_ENVWAIT]	@ 0805C60C
	ldrb r3, [r2], #1	@ 0805C610
	lsr r4, r3, #4	@ 0805C614  slide period = hi nibble
	strb r4, [r1, #TRK_DUTY]	@ 0805C618
	strb r4, [r1, #TRK_SLIDEPER]	@ 0805C61C
	and r3, r3, #0xf	@ 0805C620
	strb r3, [r1, #TRK_SLIDE]	@ 0805C624  slide = lo nibble
	ldrb r3, [r2], #1	@ 0805C628
	strb r3, [r1, #TRK_LEVEL]	@ 0805C62C  t->level
	str r2, [r1, #TRK_ENVPOS]	@ 0805C630
	ldrb r2, [r1, #TRK_VOLUME]	@ 0805C634
	add r2, r2, #1	@ 0805C638
	mul r4, r2, r3	@ 0805C63C
	lsr r2, r4, #8	@ 0805C640
	strb r2, [r1, #TRK_SWEEP]	@ 0805C644  t->pcmVol = (volume+1)*level >> 8
	ldrb r3, [r1]	@ 0805C648
	tst r3, #2	@ 0805C64C
	bne .Lenv_pcmDone	@ 0805C650
	ldr r3, .Lp_sndMaster_6	@ 0805C654
	ldrb r4, [r3]	@ 0805C658
	mul r5, r2, r4	@ 0805C65C
	lsr r2, r5, #8	@ 0805C660
	tst r7, #1	@ 0805C664
	ldreq r3, .Lp_sndStreamA_0xC_2	@ 0805C668
	ldrne r3, .Lp_sndStreamB_0xC	@ 0805C66C
	str r2, [r3]	@ 0805C670  stream.vol (master, no +1)
.Lenv_pcmDone:
	b .Lframe_nextTrack	@ 0805C674

@ ---- PCM volume slide: every t->slidePeriod frames level +/-= amount (clamped 0..255)
.Lpcm_slide:
	ldrb r2, [r1, #TRK_SLIDEPER]	@ 0805C678
	strb r2, [r1, #TRK_DUTY]	@ 0805C67C
	ldrb r3, [r1, #TRK_SLIDE]	@ 0805C680
	tst r3, #0xf	@ 0805C684
	beq .Lpcm_slideDone	@ 0805C688
	ldrb r2, [r1, #TRK_LEVEL]	@ 0805C68C
	tst r3, #8	@ 0805C690  bit 3: slide down
	and r3, r3, #7	@ 0805C694
	addeq r4, r2, r3	@ 0805C698
	subne r4, r2, r3	@ 0805C69C
	tst r4, #0xff000000	@ 0805C6A0
	movne r4, #0	@ 0805C6A4
	bne .Lpcm_slideStore	@ 0805C6A8
	tst r4, #0xff00	@ 0805C6AC
	movne r4, #0xff	@ 0805C6B0
.Lpcm_slideStore:
	strb r4, [r1, #TRK_LEVEL]	@ 0805C6B4
	ldrb r2, [r1, #TRK_VOLUME]	@ 0805C6B8
	add r2, r2, #1	@ 0805C6BC
	mul r3, r2, r4	@ 0805C6C0
	lsr r2, r3, #8	@ 0805C6C4
	strb r2, [r1, #TRK_SWEEP]	@ 0805C6C8
	ldrb r3, [r1]	@ 0805C6CC
	tst r3, #2	@ 0805C6D0
	bne .Lenv_pcmDone	@ 0805C6D4
	ldr r3, .Lp_sndMaster_7	@ 0805C6D8
	ldrb r4, [r3]	@ 0805C6DC
	add r4, r4, #1	@ 0805C6E0
	mul r5, r2, r4	@ 0805C6E4
	lsr r2, r5, #8	@ 0805C6E8
	tst r7, #1	@ 0805C6EC
	ldreq r3, .Lp_sndStreamA_0xC_3	@ 0805C6F0
	ldrne r3, .Lp_sndStreamB_0xC_2	@ 0805C6F4
	str r2, [r3]	@ 0805C6F8
.Lpcm_slideDone:
	b .Lframe_nextTrack	@ 0805C6FC

@ ================================================================
@ Sequence parser.
@   00-7F  note (followed by nothing; length is the current t->length)
@   80-DF  length = lengthTable[b & 0x7F]  (sticky; six rows of 16 = six fixed tempi)
@   E0-FF  command via seqCmdTable[b & 0x1F]
@ ================================================================
.Lparse:
	ldr r8, .Lp_REG_SOUND1CNT_L	@ 0805C700
	ldr r2, [r1, #TRK_PTR]	@ 0805C704
.Lparse_next:
	ldrb r0, [r2], #1	@ 0805C708
	cmp r0, #0x80	@ 0805C70C  < 0x80: note
	bmi .Lnote	@ 0805C710
	cmp r0, #0xe0	@ 0805C714  >= 0xE0: command
	bmi .Lparse_length	@ 0805C718
	and r0, r0, #0x1f	@ 0805C71C
	ldr r3, .Lp_seqCmdTable	@ 0805C720
	ldr pc, [r3, r0, lsl #2]	@ 0805C724  dispatch
.Lparse_length:
	and r0, r0, #0x7f	@ 0805C728
	ldr r3, .Lp_lengthTable	@ 0805C72C
	ldrb r0, [r3, r0]	@ 0805C730
	strb r0, [r1, #TRK_LENGTH]	@ 0805C734  t->length
	b .Lparse_next	@ 0805C738

@ ---- note on.  PSG (tracks 0-7):  noise channel (track&3 == 3): NR43 = swapnibbles(note).
@   else freq = psgFreqTable[(note + transpose) & 0x7F] + detune.
@   PCM (tracks 8-11): reload = pcmPitchTable[((note + transpose) & 0x7F)*12 + (s8)detune].
.Lnote:
	str r2, [r1, #TRK_PTR]	@ 0805C73C
	cmp r7, #8	@ 0805C740  PSG or PCM
	bmi .Lnote_psg	@ 0805C744
	b .Lnote_pcm	@ 0805C748
.Lnote_psg:
	and r2, r7, #3	@ 0805C74C
	cmp r2, #3	@ 0805C750
	beq .Lnote_noise	@ 0805C754  track&3 == 3: noise
	ldrb r3, [r1, #TRK_TRANSP]	@ 0805C758
	tst r3, #0x80	@ 0805C75C
	addeq r0, r0, r3	@ 0805C760
	mvnne r2, r3	@ 0805C764
	addne r2, r2, #1	@ 0805C768
	andne r2, r2, #0x7f	@ 0805C76C
	subne r0, r0, r2	@ 0805C770
	and r0, r0, #0x7f	@ 0805C774
	ldr r2, .Lp_psgFreqTable	@ 0805C778
	lsl r0, r0, #1	@ 0805C77C
	ldrh r5, [r2, r0]	@ 0805C780
	ldrb r3, [r1, #TRK_DETUNE]	@ 0805C784  + detune (unsigned)
	add r5, r5, r3	@ 0805C788
.Lnote_psgStore:
	strh r5, [r1, #TRK_FREQ]	@ 0805C78C  t->freq
	ldrb r2, [r1, #TRK_LENGTH]	@ 0805C790
	strb r2, [r1, #TRK_WAIT]	@ 0805C794  t->wait = length
	ldr r2, [r1, #TRK_ENV]	@ 0805C798
	ldrb r3, [r2], #1	@ 0805C79C
	strb r3, [r1, #TRK_ENVWAIT]	@ 0805C7A0  t->envWait
	ldrb r3, [r2], #1	@ 0805C7A4
	str r2, [r1, #TRK_ENVPOS]	@ 0805C7A8
	ldrb r2, [r1, #TRK_VOLUME]	@ 0805C7AC
	cmp r3, r2	@ 0805C7B0
	movmi r3, #8	@ 0805C7B4  below volume: 0x08 (silent, DAC on)
	bmi .Lnote_psgEnv	@ 0805C7B8
	sub r3, r3, r2	@ 0805C7BC
.Lnote_psgEnv:
	ldrb r2, [r1, #TRK_DUTY]	@ 0805C7C0
	add r3, r2, r3, lsl #8	@ 0805C7C4
	strh r3, [r1, #TRK_ENVREG]	@ 0805C7C8
	ldrb r2, [r1]	@ 0805C7CC
	tst r2, #2	@ 0805C7D0
	bne .Lnote_done	@ 0805C7D4
	teq r7, #0	@ 0805C7D8
	beq .Lnote_sweep	@ 0805C7DC
	teq r7, #4	@ 0805C7E0
	bne .Lnote_psgWrite	@ 0805C7E4
.Lnote_sweep:
	ldrbeq r0, [r1, #TRK_SWEEP]	@ 0805C7E8
	strheq r0, [r8]	@ 0805C7EC  tracks 0/4: SOUND1CNT_L = sweep
.Lnote_psgWrite:
	ldr r2, .Lp_psgEnvRegTable_2	@ 0805C7F0
	ldr r2, [r2, r7, lsl #2]	@ 0805C7F4
	strh r3, [r2]	@ 0805C7F8
	ldr r2, .Lp_psgCtrlRegTable_2	@ 0805C7FC
	ldr r2, [r2, r7, lsl #2]	@ 0805C800
	eor r5, r5, #0x8000	@ 0805C804
	strh r5, [r2]	@ 0805C808  freq | trigger
.Lnote_done:
	b .Lframe_nextTrack	@ 0805C80C
.Lnote_pcm:
	ldrb r3, [r1, #TRK_TRANSP]	@ 0805C810
	tst r3, #0x80	@ 0805C814
	beq .Lnote_pcmIndex	@ 0805C818
	mov r2, #0xff	@ 0805C81C
	mvn r4, r2	@ 0805C820
	add r3, r4, r3	@ 0805C824
.Lnote_pcmIndex:
	add r0, r0, r3	@ 0805C828
	and r0, r0, #0x7f	@ 0805C82C
	lsl r2, r0, #2	@ 0805C830
	add r0, r2, r0, lsl #3	@ 0805C834
	ldrb r3, [r1, #TRK_DETUNE]	@ 0805C838
	tst r3, #0x80	@ 0805C83C  s8 detune
	ldrne r2, .Lp_0xFFFFFF00	@ 0805C840
	addne r3, r2, r3	@ 0805C844
	add r0, r0, r3	@ 0805C848
	ldr r2, .Lp_pcmPitchTable	@ 0805C84C
	lsl r0, r0, #1	@ 0805C850
	ldrh r0, [r2, r0]	@ 0805C854
	strh r0, [r1, #TRK_FREQ]	@ 0805C858  t->freq = timer reload
	ldrb r2, [r1, #TRK_LENGTH]	@ 0805C85C
	strb r2, [r1, #TRK_WAIT]	@ 0805C860
	ldr r2, [r1, #TRK_ENV]	@ 0805C864
	ldrb r3, [r2], #1	@ 0805C868
	strb r3, [r1, #TRK_ENVWAIT]	@ 0805C86C
	ldrb r3, [r2], #1	@ 0805C870
	lsr r4, r3, #4	@ 0805C874
	strb r4, [r1, #TRK_DUTY]	@ 0805C878
	strb r4, [r1, #TRK_SLIDEPER]	@ 0805C87C
	and r3, r3, #0xf	@ 0805C880
	strb r3, [r1, #TRK_SLIDE]	@ 0805C884
	ldrb r3, [r2], #1	@ 0805C888
	strb r3, [r1, #TRK_LEVEL]	@ 0805C88C
	str r2, [r1, #TRK_ENVPOS]	@ 0805C890
	ldrb r2, [r1, #TRK_VOLUME]	@ 0805C894
	add r2, r2, #1	@ 0805C898
	mul r4, r2, r3	@ 0805C89C
	lsr r2, r4, #8	@ 0805C8A0
	strb r2, [r1, #TRK_SWEEP]	@ 0805C8A4
	ldrb r2, [r1]	@ 0805C8A8
	tst r2, #2	@ 0805C8AC
	bne .Lnote_pcmDone	@ 0805C8B0
	mov r4, #0	@ 0805C8B4
	tst r7, #1	@ 0805C8B8
	strheq r4, [r8, #IO_TM0CNT_H]	@ 0805C8BC
	strhne r4, [r8, #IO_TM1CNT_H]	@ 0805C8C0
	ldr r4, [r1, #TRK_SMPSTART]	@ 0805C8C4  sample start
	bne .Lnote_pcmB	@ 0805C8C8
	ldrh r3, [r4], #2	@ 0805C8CC
	strh r3, [r8, #IO_FIFO_A]	@ 0805C8D0  prime FIFO A with 4 raw bytes
	ldrh r3, [r4], #2	@ 0805C8D4
	strh r3, [r8, #IO_FIFO_A+2]	@ 0805C8D8
	ldr r5, .Lp_sndStreamA_2	@ 0805C8DC
	str r4, [r5], #4	@ 0805C8E0
	ldr r4, [r1, #TRK_SMPEND]	@ 0805C8E4
	str r4, [r5], #4	@ 0805C8E8
	ldr r4, [r1, #TRK_SMPLOOP]	@ 0805C8EC
	str r4, [r5], #4	@ 0805C8F0
	ldrb r4, [r1, #TRK_SWEEP]	@ 0805C8F4
	str r4, [r5]	@ 0805C8F8  stream.vol = t->pcmVol
	mov r5, #0x200	@ 0805C8FC
	ldr r3, .Lp_REG_IE	@ 0805C900
	ldrh r4, [r3]	@ 0805C904
	orr r5, r4, r5	@ 0805C908
	strh r5, [r3]	@ 0805C90C  IE |= DMA1
	strh r0, [r8, #IO_TM0CNT_L]	@ 0805C910  TM0CNT_L = reload
	mov r0, #0xf600	@ 0805C914
	strh r0, [r8, #IO_DMA1CNT_H]	@ 0805C918  DMA1CNT_H = 0xF600
	mov r0, #0x80	@ 0805C91C
	strh r0, [r8, #IO_TM0CNT_H]	@ 0805C920  TM0CNT_H = 0x80 (start)
.Lnote_pcmDone:
	b .Lframe_nextTrack	@ 0805C924
.Lnote_pcmB:
	ldrh r3, [r4], #2	@ 0805C928
	strh r3, [r8, #IO_FIFO_B]	@ 0805C92C
	ldrh r3, [r4], #2	@ 0805C930
	strh r3, [r8, #IO_FIFO_B+2]	@ 0805C934
	ldr r5, .Lp_sndStreamB_2	@ 0805C938
	str r4, [r5], #4	@ 0805C93C
	ldr r4, [r1, #TRK_SMPEND]	@ 0805C940
	str r4, [r5], #4	@ 0805C944
	ldr r4, [r1, #TRK_SMPLOOP]	@ 0805C948
	str r4, [r5], #4	@ 0805C94C
	ldrb r4, [r1, #TRK_SWEEP]	@ 0805C950
	str r4, [r5]	@ 0805C954
	mov r5, #0x400	@ 0805C958
	ldr r3, .Lp_REG_IE	@ 0805C95C
	ldrh r4, [r3]	@ 0805C960
	orr r5, r4, r5	@ 0805C964
	strh r5, [r3]	@ 0805C968  IE |= DMA2
	strh r0, [r8, #IO_TM1CNT_L]	@ 0805C96C
	mov r0, #0xf600	@ 0805C970
	strh r0, [r8, #IO_DMA2CNT_H]	@ 0805C974  DMA2CNT_H = 0xF600
	mov r0, #0x80	@ 0805C978
	strh r0, [r8, #IO_TM1CNT_H]	@ 0805C97C
	b .Lframe_nextTrack	@ 0805C980
.Lnote_noise:
	lsl r5, r0, #4	@ 0805C984
	add r5, r5, r0, lsr #4	@ 0805C988  NR43 = note<<4 | note>>4
	and r5, r5, #0xff	@ 0805C98C
	b .Lnote_psgStore	@ 0805C990

@ seqCmdTable[32] for bytes E0-FF. E2-E9 duplicate F2-F9; MV data only uses E1, EC, ED, F0-FF.
seqCmdTable:
	.align 2
	.word cmdNop	@ 0805C994  cmd 0xE0
	.word cmdSample	@ 0805C998  cmd 0xE1
	.word cmdVolume	@ 0805C99C  cmd 0xE2
	.word cmdTranspose	@ 0805C9A0  cmd 0xE3
	.word cmdLoopStart	@ 0805C9A4  cmd 0xE4
	.word cmdLoopEnd	@ 0805C9A8  cmd 0xE5
	.word cmdCall	@ 0805C9AC  cmd 0xE6
	.word cmdReturn	@ 0805C9B0  cmd 0xE7
	.word cmdJump	@ 0805C9B4  cmd 0xE8
	.word cmdDetune	@ 0805C9B8  cmd 0xE9
	.word cmdNop	@ 0805C9BC  cmd 0xEA
	.word cmdNop	@ 0805C9C0  cmd 0xEB
	.word cmdRestPcm	@ 0805C9C4  cmd 0xEC
	.word cmdRestPsg	@ 0805C9C8  cmd 0xED
	.word cmdNop	@ 0805C9CC  cmd 0xEE
	.word cmdEnd	@ 0805C9D0  cmd 0xEF
	.word cmdEnvelope	@ 0805C9D4  cmd 0xF0
	.word cmdDuty	@ 0805C9D8  cmd 0xF1
	.word cmdVolume	@ 0805C9DC  cmd 0xF2
	.word cmdTranspose	@ 0805C9E0  cmd 0xF3
	.word cmdLoopStart	@ 0805C9E4  cmd 0xF4
	.word cmdLoopEnd	@ 0805C9E8  cmd 0xF5
	.word cmdCall	@ 0805C9EC  cmd 0xF6
	.word cmdReturn	@ 0805C9F0  cmd 0xF7
	.word cmdJump	@ 0805C9F4  cmd 0xF8
	.word cmdDetune	@ 0805C9F8  cmd 0xF9
	.word cmdSweep	@ 0805C9FC  cmd 0xFA
	.word cmdSweepOff	@ 0805CA00  cmd 0xFB
	.word cmdWave	@ 0805CA04  cmd 0xFC
	.word cmdPan	@ 0805CA08  cmd 0xFD
	.word cmdTie	@ 0805CA0C  cmd 0xFE
	.word cmdEnd	@ 0805CA10  cmd 0xFF

@ ---- commands. On entry r1 = Track*, r2 = read pointer (after the command byte), r7 = track.
cmdNop:
	b .Lparse_next	@ 0805CA14
cmdTie:
	str r2, [r1, #TRK_PTR]	@ 0805CA18  FE: tie -- wait length, no retrigger
	ldrb r2, [r1, #TRK_LENGTH]	@ 0805CA1C
	strb r2, [r1, #TRK_WAIT]	@ 0805CA20
	b .Lframe_nextTrack	@ 0805CA24
cmdSample:
	ldrb r0, [r2], #1	@ 0805CA28
	ldr r3, .Lp_smpTable	@ 0805CA2C
	ldr r0, [r3, r0, lsl #2]	@ 0805CA30  E1 nn: hdr = smpTable[nn]
	ldr r3, [r0], #4	@ 0805CA34
	str r3, [r1, #TRK_SMPSTART]	@ 0805CA38
	ldr r3, [r0], #4	@ 0805CA3C
	str r3, [r1, #TRK_SMPEND]	@ 0805CA40
	ldr r3, [r0], #4	@ 0805CA44
	str r3, [r1, #TRK_SMPLOOP]	@ 0805CA48
	b .Lparse_next	@ 0805CA4C
cmdRestPcm:
	str r2, [r1, #TRK_PTR]	@ 0805CA50
	mov r3, #0	@ 0805CA54
	strb r3, [r1, #TRK_ENVWAIT]	@ 0805CA58  EC: rest (PCM) -- envWait = 0
	ldrb r2, [r1, #TRK_LENGTH]	@ 0805CA5C
	strb r2, [r1, #TRK_WAIT]	@ 0805CA60
	ldrb r2, [r1]	@ 0805CA64
	tst r2, #2	@ 0805CA68
	bne .LrestPsg_done	@ 0805CA6C
	mov r0, #0	@ 0805CA70
	tst r7, #1	@ 0805CA74
	strheq r0, [r8, #IO_TM0CNT_H]	@ 0805CA78  stop TM0 (even track) / TM1 (odd)
	strhne r0, [r8, #IO_TM1CNT_H]	@ 0805CA7C
	b .Lframe_nextTrack	@ 0805CA80
cmdRestPsg:
	str r2, [r1, #TRK_PTR]	@ 0805CA84
	mov r3, #0	@ 0805CA88
	strb r3, [r1, #TRK_ENVWAIT]	@ 0805CA8C  ED: rest (PSG)
	ldrb r2, [r1, #TRK_LENGTH]	@ 0805CA90
	strb r2, [r1, #TRK_WAIT]	@ 0805CA94
	ldrh r2, [r1, #TRK_ENVREG]	@ 0805CA98
	and r2, r2, #0xff	@ 0805CA9C
	strh r2, [r1, #TRK_ENVREG]	@ 0805CAA0  envelope byte = 0
	ldrb r2, [r1]	@ 0805CAA4
	tst r2, #2	@ 0805CAA8
	bne .LrestPsg_done	@ 0805CAAC
	ldr r2, .Lp_psgEnvRegTable_3	@ 0805CAB0
	ldr r2, [r2, r7, lsl #2]	@ 0805CAB4
	strh r3, [r2]	@ 0805CAB8
	ldr r2, .Lp_psgCtrlRegTable_3	@ 0805CABC
	ldr r2, [r2, r7, lsl #2]	@ 0805CAC0
	eor r5, r5, #0x8000	@ 0805CAC4  r5 is stale here (harmless: env 0)
	strh r5, [r2]	@ 0805CAC8
.LrestPsg_done:
	b .Lframe_nextTrack	@ 0805CACC
cmdEnvelope:
	ldrb r0, [r2], #1	@ 0805CAD0
	ldr r3, .Lp_envelopeTable	@ 0805CAD4
	add r3, r3, r0, lsl #2	@ 0805CAD8
	ldr r0, [r3]	@ 0805CADC
	str r0, [r1, #TRK_ENV]	@ 0805CAE0  F0 nn: t->env = envelopeTable[nn]
	b .Lparse_next	@ 0805CAE4
cmdDuty:
	ldrb r0, [r2], #1	@ 0805CAE8
	strb r0, [r1, #TRK_DUTY]	@ 0805CAEC  F1 nn: duty/length byte
	b .Lparse_next	@ 0805CAF0
cmdVolume:
	ldrb r0, [r2], #1	@ 0805CAF4
	strb r0, [r1, #TRK_VOLUME]	@ 0805CAF8  F2 nn: volume
	b .Lparse_next	@ 0805CAFC
cmdTranspose:
	ldrb r0, [r2], #1	@ 0805CB00
	strb r0, [r1, #TRK_TRANSP]	@ 0805CB04  F3 nn: transpose (s8)
	b .Lparse_next	@ 0805CB08
cmdLoopStart:
	ldrb r0, [r2], #1	@ 0805CB0C
	strb r0, [r1, #TRK_LOOPCNT]	@ 0805CB10
	str r2, [r1, #TRK_LOOPPTR]	@ 0805CB14  F4 nn: loop count, loop start
	b .Lparse_next	@ 0805CB18
cmdLoopEnd:
	ldrb r0, [r1, #TRK_LOOPCNT]	@ 0805CB1C
	sub r0, r0, #1	@ 0805CB20
	cmp r0, #0	@ 0805CB24
	strb r0, [r1, #TRK_LOOPCNT]	@ 0805CB28  F5: if (--count) ptr = loopStart
	ldrne r2, [r1, #TRK_LOOPPTR]	@ 0805CB2C
	b .Lparse_next	@ 0805CB30
cmdCall:
	ldrb r0, [r2], #1	@ 0805CB34
	ldr r3, [r1, #TRK_PATTERNS]	@ 0805CB38
	ldr r4, [r3, r0, lsl #2]	@ 0805CB3C
	str r2, [r1, #TRK_RETPTR]	@ 0805CB40  F6 nn: return = ptr; ptr = patterns[nn]
	mov r2, r4	@ 0805CB44
	b .Lparse_next	@ 0805CB48
cmdReturn:
	ldr r2, [r1, #TRK_RETPTR]	@ 0805CB4C  F7: return
	b .Lparse_next	@ 0805CB50
cmdJump:
	ldrb r0, [r2], #1	@ 0805CB54
	ldr r3, [r1, #TRK_PATTERNS]	@ 0805CB58
	ldr r4, [r3, r0, lsl #2]	@ 0805CB5C  F8 nn: ptr = patterns[nn]
	mov r2, r4	@ 0805CB60
	b .Lparse_next	@ 0805CB64
cmdDetune:
	ldrb r0, [r2], #1	@ 0805CB68
	strb r0, [r1, #TRK_DETUNE]	@ 0805CB6C  F9 nn: detune
	b .Lparse_next	@ 0805CB70
cmdSweep:
	ldrb r0, [r2], #1	@ 0805CB74
	strb r0, [r1, #TRK_SWEEP]	@ 0805CB78  FA nn: sweep (SOUND1CNT_L)
	b .Lparse_next	@ 0805CB7C
cmdSweepOff:
	mov r0, #0	@ 0805CB80
	strb r0, [r1, #TRK_SWEEP]	@ 0805CB84  FB: sweep off
	b .Lparse_next	@ 0805CB88
cmdWave:
	ldrb r0, [r2], #1	@ 0805CB8C
	ldr r3, .Lp_waveTable	@ 0805CB90
	ldr r4, [r3, r0, lsl #2]	@ 0805CB94  FC nn: wave = waveTable[nn]
	str r4, [r1, #TRK_SMPLOOP]	@ 0805CB98
	ldrb r3, [r1]	@ 0805CB9C
	tst r3, #2	@ 0805CBA0
	bne .Lparse_next	@ 0805CBA4
	mov r0, #0x40	@ 0805CBA8
	strh r0, [r8, #IO_SOUND3CNT_L]	@ 0805CBAC  SOUND3CNT_L = 0x40 (bank select)
	mov r3, #0x30	@ 0805CBB0
	add r3, r8, r3	@ 0805CBB4
	mov r5, #8	@ 0805CBB8
.Lwave_copy:
	ldrh r0, [r4], #2	@ 0805CBBC
	strh r0, [r3], #2	@ 0805CBC0
	sub r5, r5, #1	@ 0805CBC4
	cmp r5, #0	@ 0805CBC8
	bne .Lwave_copy	@ 0805CBCC
	mov r0, #0x80	@ 0805CBD0
	strh r0, [r8, #IO_SOUND3CNT_L]	@ 0805CBD4  SOUND3CNT_L = 0x80
	b .Lparse_next	@ 0805CBD8
cmdPan:
	ldrb r0, [r2], #1	@ 0805CBDC
	mov r5, #0x11	@ 0805CBE0  FD nn: mask 0x11 << (track&3)
	and r4, r7, #3	@ 0805CBE4
.Lpan_shift:
	teq r4, #0	@ 0805CBE8
	beq .Lpan_store	@ 0805CBEC
	lsl r0, r0, #1	@ 0805CBF0
	lsl r5, r5, #1	@ 0805CBF4
	sub r4, r4, #1	@ 0805CBF8
	b .Lpan_shift	@ 0805CBFC
.Lpan_store:
	eor r5, r5, #0xff	@ 0805CC00
	strb r0, [r1, #TRK_PANBITS]	@ 0805CC04
	strb r5, [r1, #TRK_PANMASK]	@ 0805CC08
	ldrb r4, [r1]	@ 0805CC0C
	tst r4, #2	@ 0805CC10
	bne .Lpan_done	@ 0805CC14
	ldr r3, .Lp_sndSoundCntL_4	@ 0805CC18
	ldrh r4, [r3]	@ 0805CC1C
	lsl r5, r5, #8	@ 0805CC20
	add r5, r5, #0xff	@ 0805CC24
	and r4, r4, r5	@ 0805CC28
	orr r4, r4, r0, lsl #8	@ 0805CC2C
	strh r4, [r3]	@ 0805CC30
	strh r4, [r8, #IO_SOUNDCNT_L]	@ 0805CC34  SOUNDCNT_L
.Lpan_done:
	b .Lparse_next	@ 0805CC38
cmdEnd:
	ldrb r0, [r1]	@ 0805CC3C
	and r0, r0, #0xfe	@ 0805CC40  FF/EF: end of track (flags &= ~1)
	strb r0, [r1]	@ 0805CC44
	cmp r7, #8	@ 0805CC48
	bmi .L_0805CC54	@ 0805CC4C
	b .Lend_pcm	@ 0805CC50
.L_0805CC54:
	cmp r7, #4	@ 0805CC54
	bmi .Lend_psgMusic	@ 0805CC58
	b .Lend_psgSe	@ 0805CC5C
.Lend_psgMusic:
	tst r0, #2	@ 0805CC60
	bne .Lend_done	@ 0805CC64
.Lend_silence:
	ldr r2, .Lp_psgEnvRegTable_4	@ 0805CC68
	ldr r2, [r2, r7, lsl #2]	@ 0805CC6C
	mov r0, #0	@ 0805CC70
	strh r0, [r2]	@ 0805CC74
	ldr r2, .Lp_psgCtrlRegTable_4	@ 0805CC78
	ldr r2, [r2, r7, lsl #2]	@ 0805CC7C
	mov r0, #0x8000	@ 0805CC80
	strh r0, [r2]	@ 0805CC84
.Lend_done:
	b .Lframe_nextTrack	@ 0805CC88
.Lend_psgSe:
	sub r1, r1, #0xe0	@ 0805CC8C
	ldrb r3, [r1]	@ 0805CC90
	and r3, r3, #0xd	@ 0805CC94  unmute music track (clear flag 2)
	strb r3, [r1]	@ 0805CC98
	tst r3, #1	@ 0805CC9C
	addeq r1, r1, #0xe0	@ 0805CCA0
	beq .Lend_silence	@ 0805CCA4
	and r3, r7, #3	@ 0805CCA8
	cmp r3, #2	@ 0805CCAC
	beq .Lend_restoreWave	@ 0805CCB0
.Lend_restore:
	ldrb r0, [r1, #TRK_PANBITS]	@ 0805CCB4
	ldrb r5, [r1, #TRK_PANMASK]	@ 0805CCB8
	ldr r6, .Lp_sndSoundCntL_5	@ 0805CCBC
	ldrh r4, [r6]	@ 0805CCC0
	lsl r5, r5, #8	@ 0805CCC4
	add r5, r5, #0xff	@ 0805CCC8
	and r4, r4, r5	@ 0805CCCC
	orr r4, r4, r0, lsl #8	@ 0805CCD0
	strh r4, [r6]	@ 0805CCD4
	strh r4, [r8, #IO_SOUNDCNT_L]	@ 0805CCD8
	ldrh r6, [r1, #TRK_ENVREG]	@ 0805CCDC
	ldr r2, .Lp_psgEnvRegTable_5	@ 0805CCE0
	ldr r2, [r2, r7, lsl #2]	@ 0805CCE4
	strh r6, [r2]	@ 0805CCE8
	ldr r2, .Lp_psgCtrlRegTable_5	@ 0805CCEC
	ldr r2, [r2, r7, lsl #2]	@ 0805CCF0
	ldrh r3, [r1, #TRK_FREQ]	@ 0805CCF4
	eor r3, r3, #0x8000	@ 0805CCF8
	strh r3, [r2]	@ 0805CCFC
	teq r7, #4	@ 0805CD00
	ldrbeq r0, [r1, #TRK_SWEEP]	@ 0805CD04
	strheq r0, [r8]	@ 0805CD08
	add r1, r1, #0xe0	@ 0805CD0C
	b .Lframe_nextTrack	@ 0805CD10
.Lend_restoreWave:
	mov r0, #0x40	@ 0805CD14
	strh r0, [r8, #IO_SOUND3CNT_L]	@ 0805CD18
	ldr r4, [r1, #TRK_SMPLOOP]	@ 0805CD1C
	add r3, r8, #0x30	@ 0805CD20
	mov r5, #8	@ 0805CD24
.Lend_waveCopy:
	ldrh r0, [r4], #2	@ 0805CD28
	strh r0, [r3], #2	@ 0805CD2C
	sub r5, r5, #1	@ 0805CD30
	cmp r5, #0	@ 0805CD34
	bne .Lend_waveCopy	@ 0805CD38
	mov r0, #0x80	@ 0805CD3C
	strh r0, [r8, #IO_SOUND3CNT_L]	@ 0805CD40
	b .Lend_restore	@ 0805CD44
.Lend_pcm:
	cmp r7, #0xa	@ 0805CD48
	bmi .Lend_pcmMusic	@ 0805CD4C
	b .Lend_pcmSe	@ 0805CD50
.Lend_pcmMusic:
	tst r0, #2	@ 0805CD54
	bne .Lend_pcmDone	@ 0805CD58
	b .Lend_pcmStop	@ 0805CD5C
.Lend_pcmSe:
	sub r2, r1, #0x70	@ 0805CD60
	ldrb r3, [r2]	@ 0805CD64
	and r3, r3, #0xfd	@ 0805CD68  unmute PCM music track
	strb r3, [r2]	@ 0805CD6C
.Lend_pcmStop:
	mov r0, #0	@ 0805CD70
	tst r7, #1	@ 0805CD74
	strheq r0, [r8, #IO_TM0CNT_H]	@ 0805CD78
	strhne r0, [r8, #IO_TM1CNT_H]	@ 0805CD7C
.Lend_pcmDone:
	b .Lframe_nextTrack	@ 0805CD80
.Lp_sndQueueWrite:
	.word sndQueueWrite	@ 0805CD84
.Lp_sndQueue:
	.word sndQueue	@ 0805CD88
.Lp_sndMaster:
	.word sndMaster	@ 0805CD8C
.Lp_sndMaster_2:
	.word sndMaster	@ 0805CD90
.Lp_REG_SOUND1CNT_L:
	.word REG_SOUND1CNT_L	@ 0805CD94
.Lp_0x0000C80E:
	.word 0x0000C80E	@ 0805CD98
.Lp_0x0000730E:
	.word 0x0000730E	@ 0805CD9C
.Lp_sndSoundCntL:
	.word sndSoundCntL	@ 0805CDA0
.Lp_sndTracks:
	.word sndTracks	@ 0805CDA4
.Lp_sndQueueRead:
	.word sndQueueRead	@ 0805CDA8
.Lp_sndMaster_3:
	.word sndMaster	@ 0805CDAC
.Lp_REG_IF:
	.word REG_IF	@ 0805CDB0
.Lp_sndStreamA:
	.word sndStreamA	@ 0805CDB4
.Lp_REG_FIFO_A:
	.word REG_FIFO_A	@ 0805CDB8
.Lp_REG_FIFO_A_2:
	.word REG_FIFO_A+2	@ 0805CDBC
.Lp_REG_TM0CNT_H:
	.word REG_TM0CNT_H	@ 0805CDC0
.Lp_sndStreamB:
	.word sndStreamB	@ 0805CDC4
.Lp_REG_FIFO_B:
	.word REG_FIFO_B	@ 0805CDC8
.Lp_REG_FIFO_B_2:
	.word REG_FIFO_B+2	@ 0805CDCC
.Lp_REG_TM1CNT_H:
	.word REG_TM1CNT_H	@ 0805CDD0
.Lp_sndTracks_2:
	.word sndTracks	@ 0805CDD4
.Lp_sndMaster_4:
	.word sndMaster	@ 0805CDD8
.Lp_sndQueueRead_2:
	.word sndQueueRead	@ 0805CDDC
.Lp_sndSoundCntL_2:
	.word sndSoundCntL	@ 0805CDE0
.Lp_sndTracks_0x1C0:
	.word sndTracks+0x1C0	@ 0805CDE4
.Lp_sndStreamA_0xC:
	.word sndStreamA+0xC	@ 0805CDE8
.Lp_sndSoundCntL_3:
	.word sndSoundCntL	@ 0805CDEC
.Lp_sndTracks_3:
	.word sndTracks	@ 0805CDF0
.Lp_sndQueueRead_3:
	.word sndQueueRead	@ 0805CDF4
.Lp_sndMaster_5:
	.word sndMaster	@ 0805CDF8
.Lp_sndQueueRead_4:
	.word sndQueueRead	@ 0805CDFC
.Lp_seqSongTable:
	.word seqSongTable	@ 0805CE00
.Lp_sndTracks_4:
	.word sndTracks	@ 0805CE04
.Lp_panBitsTable:
	.word panBitsTable	@ 0805CE08
.Lp_psgEnvRegTable:
	.word psgEnvRegTable	@ 0805CE0C
.Lp_psgCtrlRegTable:
	.word psgCtrlRegTable	@ 0805CE10
.Lp_sndMaster_6:
	.word sndMaster	@ 0805CE14
.Lp_sndStreamA_0xC_2:
	.word sndStreamA+0xC	@ 0805CE18
.Lp_sndStreamB_0xC:
	.word sndStreamB+0xC	@ 0805CE1C
.Lp_sndMaster_7:
	.word sndMaster	@ 0805CE20
.Lp_sndStreamA_0xC_3:
	.word sndStreamA+0xC	@ 0805CE24
.Lp_sndStreamB_0xC_2:
	.word sndStreamB+0xC	@ 0805CE28
.Lp_seqCmdTable:
	.word seqCmdTable	@ 0805CE2C
.Lp_lengthTable:
	.word lengthTable	@ 0805CE30
.Lp_psgFreqTable:
	.word psgFreqTable	@ 0805CE34
.Lp_psgEnvRegTable_2:
	.word psgEnvRegTable	@ 0805CE38
.Lp_psgCtrlRegTable_2:
	.word psgCtrlRegTable	@ 0805CE3C
.Lp_0xFFFFFF00:
	.word 0xFFFFFF00	@ 0805CE40
.Lp_pcmPitchTable:
	.word pcmPitchTable	@ 0805CE44
.Lp_sndStreamA_2:
	.word sndStreamA	@ 0805CE48
.Lp_REG_IE:
	.word REG_IE	@ 0805CE4C
.Lp_sndStreamB_2:
	.word sndStreamB	@ 0805CE50
.Lp_smpTable:
	.word smpTable	@ 0805CE54
.Lp_psgEnvRegTable_3:
	.word psgEnvRegTable	@ 0805CE58
.Lp_psgCtrlRegTable_3:
	.word psgCtrlRegTable	@ 0805CE5C
.Lp_envelopeTable:
	.word envelopeTable	@ 0805CE60
.Lp_waveTable:
	.word waveTable	@ 0805CE64
.Lp_sndSoundCntL_4:
	.word sndSoundCntL	@ 0805CE68
.Lp_psgEnvRegTable_4:
	.word psgEnvRegTable	@ 0805CE6C
.Lp_psgCtrlRegTable_4:
	.word psgCtrlRegTable	@ 0805CE70
.Lp_sndSoundCntL_5:
	.word sndSoundCntL	@ 0805CE74
.Lp_psgEnvRegTable_5:
	.word psgEnvRegTable	@ 0805CE78
.Lp_psgCtrlRegTable_5:
	.word psgCtrlRegTable	@ 0805CE7C

@ lengthTable[96]: note/rest length in frames for bytes 0x80-0xDF.
@ row 0 (80-8F) quarter=32, row 1 (90-9F) 40, row 2 (A0-AF) 48, row 3 (B0-BF) 56, row 4 (C0-CF) 36, row 5 (D0-DF) 44.
@ column: 4=1/32 6=1/16 8=1/8 A=1/4 C=1/2 E=1/1, odd = dotted (x1.5).
lengthTable:
	.byte   0,   1,   2,   3,   4,   6,   8,  12,  16,  24,  32,  48,  64,  96, 128, 192	@ 0805CE80  0x80-0x8F
	.byte  13,   0,   0,   8,   5,   7,  10,  15,  20,  30,  40,  60,  80, 120, 160, 240	@ 0805CE90  0x90-0x9F
	.byte   0,   0,   0,   0,   6,   9,  12,  18,  24,  36,  48,  72,  96, 144, 192,   0	@ 0805CEA0  0xA0-0xAF
	.byte   0,   0,   0,   0,   7,  11,  14,  21,  28,  40,  56,  84, 112, 168, 224,   0	@ 0805CEB0  0xB0-0xBF
	.byte   0,   0,   0,   0,   4,   5,   9,  14,  18,  27,  36,  54,  72, 108, 144, 216	@ 0805CEC0  0xC0-0xCF
	.byte   0,   0,   0,   0,   6,   0,  11,  16,  22,  33,  44,  66,  88, 132, 176,   0	@ 0805CED0  0xD0-0xDF

@ envelopeTable[72]: pointers to envelope scripts (F0 nn). 0-15/48-63: square/noise
@ {frames, NRx2}; 16-31: wave {frames, NR32}; 32-47 and 64-71: PCM {frames, slide, level}.
envelopeTable:
	.word env_D000	@ 0805CEE0  envelope 0
	.word env_D002	@ 0805CEE4  envelope 1
	.word env_D004	@ 0805CEE8  envelope 2
	.word env_D006	@ 0805CEEC  envelope 3
	.word env_D008	@ 0805CEF0  envelope 4
	.word env_D00A	@ 0805CEF4  envelope 5
	.word env_D00C	@ 0805CEF8  envelope 6
	.word env_D00E	@ 0805CEFC  envelope 7
	.word env_D010	@ 0805CF00  envelope 8
	.word env_D012	@ 0805CF04  envelope 9
	.word env_D016	@ 0805CF08  envelope 10
	.word env_D01A	@ 0805CF0C  envelope 11
	.word env_D022	@ 0805CF10  envelope 12
	.word env_D026	@ 0805CF14  envelope 13
	.word env_D028	@ 0805CF18  envelope 14
	.word env_D03A	@ 0805CF1C  envelope 15
	.word env_D090	@ 0805CF20  envelope 16
	.word env_D092	@ 0805CF24  envelope 17
	.word env_D094	@ 0805CF28  envelope 18
	.word env_D096	@ 0805CF2C  envelope 19
	.word env_D098	@ 0805CF30  envelope 20
	.word env_D09C	@ 0805CF34  envelope 21
	.word env_D0A0	@ 0805CF38  envelope 22
	.word env_D0A4	@ 0805CF3C  envelope 23
	.word env_D0A8	@ 0805CF40  envelope 24
	.word env_D0AC	@ 0805CF44  envelope 25
	.word env_D0AC	@ 0805CF48  envelope 26
	.word env_D0AC	@ 0805CF4C  envelope 27
	.word env_D0AC	@ 0805CF50  envelope 28
	.word env_D0AC	@ 0805CF54  envelope 29
	.word env_D0AC	@ 0805CF58  envelope 30
	.word env_D0AC	@ 0805CF5C  envelope 31
	.word env_D0AE	@ 0805CF60  envelope 32
	.word env_D0B1	@ 0805CF64  envelope 33
	.word env_D0BD	@ 0805CF68  envelope 34
	.word env_D0C9	@ 0805CF6C  envelope 35
	.word env_D0D2	@ 0805CF70  envelope 36
	.word env_D0D8	@ 0805CF74  envelope 37
	.word env_D0DE	@ 0805CF78  envelope 38
	.word env_D0E1	@ 0805CF7C  envelope 39
	.word env_D0FF	@ 0805CF80  envelope 40
	.word env_D105	@ 0805CF84  envelope 41
	.word env_D10B	@ 0805CF88  envelope 42
	.word env_D10E	@ 0805CF8C  envelope 43
	.word env_D114	@ 0805CF90  envelope 44
	.word env_D11A	@ 0805CF94  envelope 45
	.word env_D120	@ 0805CF98  envelope 46
	.word env_D126	@ 0805CF9C  envelope 47
	.word env_D03C	@ 0805CFA0  envelope 48
	.word env_D03E	@ 0805CFA4  envelope 49
	.word env_D04E	@ 0805CFA8  envelope 50
	.word env_D06E	@ 0805CFAC  envelope 51
	.word env_D08E	@ 0805CFB0  envelope 52
	.word env_D08E	@ 0805CFB4  envelope 53
	.word env_D08E	@ 0805CFB8  envelope 54
	.word env_D08E	@ 0805CFBC  envelope 55
	.word env_D03C	@ 0805CFC0  envelope 56
	.word env_D03E	@ 0805CFC4  envelope 57
	.word env_D04E	@ 0805CFC8  envelope 58
	.word env_D06E	@ 0805CFCC  envelope 59
	.word env_D08E	@ 0805CFD0  envelope 60
	.word env_D08E	@ 0805CFD4  envelope 61
	.word env_D08E	@ 0805CFD8  envelope 62
	.word env_D08E	@ 0805CFDC  envelope 63
	.word env_D12C	@ 0805CFE0  envelope 64
	.word env_D135	@ 0805CFE4  envelope 65
	.word env_D2CD	@ 0805CFE8  envelope 66
	.word env_D2D3	@ 0805CFEC  envelope 67
	.word env_D2D3	@ 0805CFF0  envelope 68
	.word env_D2D3	@ 0805CFF4  envelope 69
	.word env_D2D3	@ 0805CFF8  envelope 70
	.word env_D2D3	@ 0805CFFC  envelope 71

@ Envelope script data.
env_D000:
	.byte 0x00, 0xF0	@ 0805D000
env_D002:
	.byte 0x00, 0xF1	@ 0805D002
env_D004:
	.byte 0x00, 0xF2	@ 0805D004
env_D006:
	.byte 0x00, 0xF3	@ 0805D006
env_D008:
	.byte 0x00, 0xF4	@ 0805D008
env_D00A:
	.byte 0x00, 0xF5	@ 0805D00A
env_D00C:
	.byte 0x00, 0xF6	@ 0805D00C
env_D00E:
	.byte 0x00, 0xF7	@ 0805D00E
env_D010:
	.byte 0x00, 0xE0	@ 0805D010
env_D012:
	.byte 0x30, 0xE0, 0x00, 0xE7	@ 0805D012
env_D016:
	.byte 0x12, 0xF4, 0x00, 0xC6	@ 0805D016
env_D01A:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x12, 0xF4, 0x00, 0xC6	@ 0805D01A
env_D022:
	.byte 0x12, 0xF4, 0x00, 0xD6	@ 0805D022
env_D026:
	.byte 0x00, 0xC0	@ 0805D026
env_D028:
	.byte 0x08, 0x10, 0x08, 0x20, 0x08, 0x30, 0x08, 0x40, 0x08, 0x50, 0x08, 0x40	@ 0805D028
	.byte 0x08, 0x30, 0x08, 0x20, 0x00, 0x10	@ 0805D034
env_D03A:
	.byte 0x00, 0x0F	@ 0805D03A
env_D03C:
	.byte 0x00, 0x3F	@ 0805D03C
env_D03E:
	.byte 0x80, 0xF0, 0x10, 0xE0, 0x10, 0xD0, 0x10, 0xC0, 0x20, 0xB0, 0x30, 0xA0	@ 0805D03E
	.byte 0x40, 0x90, 0x00, 0x80	@ 0805D04A
env_D04E:
	.byte 0x08, 0xF0, 0x08, 0xE0, 0x08, 0xD0, 0x08, 0xC0, 0x08, 0xB0, 0x08, 0xA0	@ 0805D04E
	.byte 0x08, 0x90, 0x08, 0x80, 0x08, 0x70, 0x08, 0x60, 0x08, 0x50, 0x08, 0x40	@ 0805D05A
	.byte 0x08, 0x30, 0x08, 0x20, 0x08, 0x10, 0x00, 0x00	@ 0805D066
env_D06E:
	.byte 0x04, 0xF0, 0x04, 0xE0, 0x04, 0xD0, 0x04, 0xC0, 0x04, 0xB0, 0x04, 0xA0	@ 0805D06E
	.byte 0x04, 0x90, 0x04, 0x80, 0x05, 0x70, 0x05, 0x60, 0x05, 0x50, 0x05, 0x40	@ 0805D07A
	.byte 0x05, 0x30, 0x05, 0x20, 0x05, 0x10, 0x00, 0x00	@ 0805D086
env_D08E:
	.byte 0xFF, 0xF0	@ 0805D08E
env_D090:
	.byte 0x00, 0x20	@ 0805D090
env_D092:
	.byte 0x00, 0x80	@ 0805D092
env_D094:
	.byte 0x00, 0x40	@ 0805D094
env_D096:
	.byte 0x00, 0x60	@ 0805D096
env_D098:
	.byte 0x06, 0x40, 0x00, 0x00	@ 0805D098
env_D09C:
	.byte 0x10, 0x40, 0x00, 0x00	@ 0805D09C
env_D0A0:
	.byte 0x18, 0x40, 0x00, 0x00	@ 0805D0A0
env_D0A4:
	.byte 0x0C, 0x40, 0x00, 0x00	@ 0805D0A4
env_D0A8:
	.byte 0x08, 0x40, 0x00, 0x00	@ 0805D0A8
env_D0AC:
	.byte 0xFF, 0x20	@ 0805D0AC
env_D0AE:
	.byte 0x00, 0x00, 0xFF	@ 0805D0AE
env_D0B1:
	.byte 0x01, 0x00, 0x40, 0x01, 0x00, 0x80, 0x38, 0x00, 0xFF, 0x00, 0x1C, 0xFF	@ 0805D0B1
env_D0BD:
	.byte 0x01, 0x00, 0x40, 0x01, 0x00, 0x80, 0x10, 0x00, 0xFF, 0x00, 0x1C, 0xFF	@ 0805D0BD
env_D0C9:
	.byte 0x01, 0x00, 0x40, 0x01, 0x00, 0x80, 0x00, 0x1C, 0xFF	@ 0805D0C9
env_D0D2:
	.byte 0x38, 0x00, 0xFF, 0x00, 0x1C, 0xFF	@ 0805D0D2
env_D0D8:
	.byte 0x08, 0x00, 0xFF, 0x00, 0x1F, 0x80	@ 0805D0D8
env_D0DE:
	.byte 0x00, 0x1E, 0xFF	@ 0805D0DE
env_D0E1:
	.byte 0x01, 0x1F, 0xFF, 0x01, 0x1F, 0x90, 0x01, 0x1F, 0x80, 0x01, 0x1F, 0x70	@ 0805D0E1
	.byte 0x01, 0x1F, 0x60, 0x01, 0x1F, 0x50, 0x01, 0x1F, 0x40, 0x01, 0x1F, 0x30	@ 0805D0ED
	.byte 0x01, 0x1F, 0x20, 0x00, 0x1F, 0x10	@ 0805D0F9
env_D0FF:
	.byte 0x01, 0x1F, 0xFF, 0x00, 0x1F, 0x00	@ 0805D0FF
env_D105:
	.byte 0x08, 0x1F, 0xFF, 0x00, 0x1F, 0x80	@ 0805D105
env_D10B:
	.byte 0x00, 0x1A, 0xFF	@ 0805D10B
env_D10E:
	.byte 0x78, 0x00, 0xFF, 0x00, 0x1F, 0x80	@ 0805D10E
env_D114:
	.byte 0x10, 0x00, 0xFF, 0x00, 0x1C, 0x80	@ 0805D114
env_D11A:
	.byte 0x30, 0x12, 0x00, 0x00, 0x19, 0x60	@ 0805D11A
env_D120:
	.byte 0x40, 0x12, 0x00, 0x00, 0x19, 0x80	@ 0805D120
env_D126:
	.byte 0x06, 0x1F, 0xFF, 0x00, 0x1E, 0xA0	@ 0805D126
env_D12C:
	.byte 0xFF, 0x21, 0x00, 0xFF, 0x21, 0x80, 0x00, 0x1A, 0xFF	@ 0805D12C
env_D135:
	.byte 0x01, 0x00, 0xFF, 0x01, 0x00, 0xFE, 0x01, 0x00, 0xFD, 0x01, 0x00, 0xFC	@ 0805D135
	.byte 0x01, 0x00, 0xFB, 0x01, 0x00, 0xFA, 0x01, 0x00, 0xF9, 0x01, 0x00, 0xF8	@ 0805D141
	.byte 0x01, 0x00, 0xEF, 0x01, 0x00, 0xEE, 0x01, 0x00, 0xED, 0x01, 0x00, 0xEC	@ 0805D14D
	.byte 0x01, 0x00, 0xEB, 0x01, 0x00, 0xEA, 0x01, 0x00, 0xE9, 0x01, 0x00, 0xE8	@ 0805D159
	.byte 0x01, 0x00, 0xDF, 0x01, 0x00, 0xDE, 0x01, 0x00, 0xDD, 0x01, 0x00, 0xDC	@ 0805D165
	.byte 0x01, 0x00, 0xDB, 0x01, 0x00, 0xDA, 0x01, 0x00, 0xD9, 0x01, 0x00, 0xD8	@ 0805D171
	.byte 0x01, 0x00, 0xCF, 0x01, 0x00, 0xCE, 0x01, 0x00, 0xCD, 0x01, 0x00, 0xCC	@ 0805D17D
	.byte 0x01, 0x00, 0xCB, 0x01, 0x00, 0xCA, 0x01, 0x00, 0xC9, 0x01, 0x00, 0xC8	@ 0805D189
	.byte 0x01, 0x00, 0xBF, 0x01, 0x00, 0xBE, 0x01, 0x00, 0xBD, 0x01, 0x00, 0xBC	@ 0805D195
	.byte 0x01, 0x00, 0xBB, 0x01, 0x00, 0xBA, 0x01, 0x00, 0xB9, 0x01, 0x00, 0xB8	@ 0805D1A1
	.byte 0x01, 0x00, 0xAF, 0x01, 0x00, 0xAE, 0x01, 0x00, 0xAD, 0x01, 0x00, 0xAC	@ 0805D1AD
	.byte 0x01, 0x00, 0xAB, 0x01, 0x00, 0xAA, 0x01, 0x00, 0xA9, 0x01, 0x00, 0xA8	@ 0805D1B9
	.byte 0x01, 0x00, 0x9F, 0x01, 0x00, 0x9E, 0x01, 0x00, 0x9D, 0x01, 0x00, 0x9C	@ 0805D1C5
	.byte 0x01, 0x00, 0x9B, 0x01, 0x00, 0x9A, 0x01, 0x00, 0x99, 0x01, 0x00, 0x98	@ 0805D1D1
	.byte 0x01, 0x00, 0x8F, 0x01, 0x00, 0x8E, 0x01, 0x00, 0x8D, 0x01, 0x00, 0x8C	@ 0805D1DD
	.byte 0x01, 0x00, 0x8B, 0x01, 0x00, 0x8A, 0x01, 0x00, 0x89, 0x01, 0x00, 0x88	@ 0805D1E9
	.byte 0x01, 0x00, 0x7F, 0x01, 0x00, 0x7E, 0x01, 0x00, 0x7D, 0x01, 0x00, 0x7C	@ 0805D1F5
	.byte 0x01, 0x00, 0x7B, 0x01, 0x00, 0x7A, 0x01, 0x00, 0x79, 0x01, 0x00, 0x78	@ 0805D201
	.byte 0x01, 0x00, 0x6F, 0x01, 0x00, 0x6E, 0x01, 0x00, 0x6D, 0x01, 0x00, 0x6C	@ 0805D20D
	.byte 0x01, 0x00, 0x6B, 0x01, 0x00, 0x6A, 0x01, 0x00, 0x69, 0x01, 0x00, 0x68	@ 0805D219
	.byte 0x01, 0x00, 0x5F, 0x01, 0x00, 0x5E, 0x01, 0x00, 0x5D, 0x01, 0x00, 0x5C	@ 0805D225
	.byte 0x01, 0x00, 0x5B, 0x01, 0x00, 0x5A, 0x01, 0x00, 0x59, 0x01, 0x00, 0x58	@ 0805D231
	.byte 0x01, 0x00, 0x4F, 0x01, 0x00, 0x4E, 0x01, 0x00, 0x4D, 0x01, 0x00, 0x4C	@ 0805D23D
	.byte 0x01, 0x00, 0x4B, 0x01, 0x00, 0x4A, 0x01, 0x00, 0x49, 0x01, 0x00, 0x48	@ 0805D249
	.byte 0x01, 0x00, 0x3F, 0x01, 0x00, 0x3E, 0x01, 0x00, 0x3D, 0x01, 0x00, 0x3C	@ 0805D255
	.byte 0x01, 0x00, 0x3B, 0x01, 0x00, 0x3A, 0x01, 0x00, 0x39, 0x01, 0x00, 0x38	@ 0805D261
	.byte 0x01, 0x00, 0x2F, 0x01, 0x00, 0x2E, 0x01, 0x00, 0x2D, 0x01, 0x00, 0x2C	@ 0805D26D
	.byte 0x01, 0x00, 0x2B, 0x01, 0x00, 0x2A, 0x01, 0x00, 0x29, 0x01, 0x00, 0x28	@ 0805D279
	.byte 0x01, 0x00, 0x1F, 0x01, 0x00, 0x1E, 0x01, 0x00, 0x1D, 0x01, 0x00, 0x1C	@ 0805D285
	.byte 0x01, 0x00, 0x1B, 0x01, 0x00, 0x1A, 0x01, 0x00, 0x19, 0x01, 0x00, 0x18	@ 0805D291
	.byte 0x01, 0x00, 0x0F, 0x01, 0x00, 0x0E, 0x01, 0x00, 0x0D, 0x01, 0x00, 0x0C	@ 0805D29D
	.byte 0x01, 0x00, 0x0B, 0x01, 0x00, 0x0A, 0x01, 0x00, 0x09, 0x01, 0x00, 0x08	@ 0805D2A9
	.byte 0x01, 0x00, 0x07, 0x01, 0x00, 0x06, 0x01, 0x00, 0x05, 0x01, 0x00, 0x04	@ 0805D2B5
	.byte 0x01, 0x00, 0x03, 0x01, 0x00, 0x02, 0x01, 0x00, 0x01, 0x00, 0x00, 0x00	@ 0805D2C1
env_D2CD:
	.byte 0x02, 0x1F, 0xFF, 0x00, 0x1F, 0xC0	@ 0805D2CD
env_D2D3:
	.byte 0x06, 0x1F, 0xFF, 0x00, 0x1E, 0xA0, 0x00, 0x00, 0x00	@ 0805D2D3

@ ---- linker-generated Thumb->ARM interworking veneers (bx pc / nop / b target)
	.section .text.bb_veneer, "ax", %progbits
	.thumb
	.global vnr_sndQueueSound
vnr_sndQueueSound:
	bx pc	@ 080C2044
	nop
	.arm
	b sndQueueSound	@ 080C2048
	.thumb
	.global vnr_sndInit
vnr_sndInit:
	bx pc	@ 080C204C
	nop
	.arm
	b sndInit	@ 080C2050
	.thumb
	.global vnr_sndFrame
vnr_sndFrame:
	bx pc	@ 080C2054
	nop
	.arm
	b sndFrame	@ 080C2058
	.thumb
	.global vnr_sndFifoAIrq
vnr_sndFifoAIrq:
	bx pc	@ 080C205C
	nop
	.arm
	b sndFifoAIrq	@ 080C2060
	.thumb
	.global vnr_sndFifoBIrq
vnr_sndFifoBIrq:
	bx pc	@ 080C2064
	nop
	.arm
	b sndFifoBIrq	@ 080C2068
	.thumb
	.global vnr_sndFadeOut
vnr_sndFadeOut:
	bx pc	@ 080C206C
	nop
	.arm
	b sndFadeOut	@ 080C2070
