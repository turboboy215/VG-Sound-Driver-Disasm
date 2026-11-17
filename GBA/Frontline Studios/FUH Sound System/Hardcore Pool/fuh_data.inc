@ fuh_data.inc -- macros and symbols for fuh_data.s

@ instrument: {loopStart, loopEnd (0 = one-shot), volume 0..64, PCM header}
	.macro INSTR ls, le, vol, pcm
	.word \ls, \le, \vol, \pcm
	.endm

@ one pattern event (one channel of one row)
	.macro ev n=-1, i=0, v=-1, fx=0, p=0
	.set _ev_f, (\fx) << 2
	.if (\n) >= 0
	.set _ev_f, _ev_f | 0x01
	.endif
	.if (\v) >= 0
	.set _ev_f, _ev_f | 0x80
	.endif
	.byte _ev_f
	.if (\n) >= 0
	.hword \n
	.byte \i
	.endif
	.if (\v) >= 0
	.byte \v
	.endif
	.if (\fx) != 0
	.byte \p
	.endif
	.endm

@ effect numbers (flags bits 2-6); see fuh-technical-reference.md section 9.3
	.equ FX_STORE, 1
	.equ FX_PORTA_UP, 2
	.equ FX_PORTA_DN, 3
	.equ FX_TONEPORTA, 4
	.equ FX_VOLUME, 5
	.equ FX_VOLSLIDE, 6
	.equ FX_VIBRATO, 7
	.equ FX_VIBRATO2, 8
	.equ FX_SPEED, 9
	.equ FX_NOP10, 10
	.equ FX_NOP11, 11
	.equ FX_VIBVOLSLIDE, 12
	.equ FX_NOP13, 13
	.equ FX_JUMP, 14
	.equ FX_OFFSET, 15
	.equ FX_NOP16, 16
	.equ FX_NOP17, 17
	.equ FX_NOP18, 18
	.equ FX_NOP19, 19
	.equ FX_NOP20, 20
	.equ FX_NOP21, 21
	.equ FX_NOP22, 22
	.equ FX_NOP23, 23
	.equ FX_NOP24, 24
	.equ FX_NOP25, 25
	.equ FX_NOP26, 26
	.equ FX_NOP27, 27
	.equ FX_NOP28, 28
	.equ FX_NOP29, 29
	.equ FX_NOP30, 30
	.equ FX_NOP31, 31

@ notes as XM linear periods: period = 7680 - 64 * note, C_0 = note 0; C_4 = 4608 = 8363 Hz
	.equ C_0, 7680
	.equ Cs0, 7616
	.equ D_0, 7552
	.equ Ds0, 7488
	.equ E_0, 7424
	.equ F_0, 7360
	.equ Fs0, 7296
	.equ G_0, 7232
	.equ Gs0, 7168
	.equ A_0, 7104
	.equ As0, 7040
	.equ B_0, 6976
	.equ C_1, 6912
	.equ Cs1, 6848
	.equ D_1, 6784
	.equ Ds1, 6720
	.equ E_1, 6656
	.equ F_1, 6592
	.equ Fs1, 6528
	.equ G_1, 6464
	.equ Gs1, 6400
	.equ A_1, 6336
	.equ As1, 6272
	.equ B_1, 6208
	.equ C_2, 6144
	.equ Cs2, 6080
	.equ D_2, 6016
	.equ Ds2, 5952
	.equ E_2, 5888
	.equ F_2, 5824
	.equ Fs2, 5760
	.equ G_2, 5696
	.equ Gs2, 5632
	.equ A_2, 5568
	.equ As2, 5504
	.equ B_2, 5440
	.equ C_3, 5376
	.equ Cs3, 5312
	.equ D_3, 5248
	.equ Ds3, 5184
	.equ E_3, 5120
	.equ F_3, 5056
	.equ Fs3, 4992
	.equ G_3, 4928
	.equ Gs3, 4864
	.equ A_3, 4800
	.equ As3, 4736
	.equ B_3, 4672
	.equ C_4, 4608
	.equ Cs4, 4544
	.equ D_4, 4480
	.equ Ds4, 4416
	.equ E_4, 4352
	.equ F_4, 4288
	.equ Fs4, 4224
	.equ G_4, 4160
	.equ Gs4, 4096
	.equ A_4, 4032
	.equ As4, 3968
	.equ B_4, 3904
	.equ C_5, 3840
	.equ Cs5, 3776
	.equ D_5, 3712
	.equ Ds5, 3648
	.equ E_5, 3584
	.equ F_5, 3520
	.equ Fs5, 3456
	.equ G_5, 3392
	.equ Gs5, 3328
	.equ A_5, 3264
	.equ As5, 3200
	.equ B_5, 3136
	.equ C_6, 3072
	.equ Cs6, 3008
	.equ D_6, 2944
	.equ Ds6, 2880
	.equ E_6, 2816
	.equ F_6, 2752
	.equ Fs6, 2688
	.equ G_6, 2624
	.equ Gs6, 2560
	.equ A_6, 2496
	.equ As6, 2432
	.equ B_6, 2368
	.equ C_7, 2304
	.equ Cs7, 2240
	.equ D_7, 2176
	.equ Ds7, 2112
	.equ E_7, 2048
	.equ F_7, 1984
	.equ Fs7, 1920
	.equ G_7, 1856
	.equ Gs7, 1792
	.equ A_7, 1728
	.equ As7, 1664
	.equ B_7, 1600
	.equ C_8, 1536
	.equ Cs8, 1472
	.equ D_8, 1408
	.equ Ds8, 1344
	.equ E_8, 1280
	.equ F_8, 1216
	.equ Fs8, 1152
	.equ G_8, 1088
	.equ Gs8, 1024
	.equ A_8, 960
	.equ As8, 896
	.equ B_8, 832
	.equ C_9, 768
	.equ Cs9, 704
	.equ D_9, 640
	.equ Ds9, 576
	.equ E_9, 512
	.equ F_9, 448
	.equ Fs9, 384
	.equ G_9, 320
	.equ Gs9, 256
	.equ A_9, 192
	.equ As9, 128
	.equ B_9, 64
