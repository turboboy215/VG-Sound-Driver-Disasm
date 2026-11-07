@ Brownie Brown sound driver, revision 2 (Sword of Mana, AVSP) -- labelled disassembly
@ Rebuilds byte-identical with som_sound.mk. Names are assigned by analysis; see technical reference.
@ sndMixIrq and sndMixFull are copied to IWRAM (0x03003150 / 0x03003750) and normally run there;
@ they only use PC-relative literals and branches, so they are assembled at their ROM addresses.
	.syntax unified
	.cpu arm7tdmi
	.include "som_sound.inc"

	.section .text.som_sound, "ax", %progbits
	.arm

@ ================================================================
@ void sndMixIrq(void)   DMA1/DMA2 IRQ.  Normally runs from the IWRAM copy at 0x03003150
@ (IRQ vector entries 9/10 point there); the ROM wrappers Sound_DmaIrqA/B call this ROM copy.
@   IF = DMA1|DMA2; stop DMA1/2; SAD = sndMixA / sndMixB; restart DMA (0xF640); IE &= ~(DMA1|DMA2)
@   if (sndMixMode) goto IW_sndMixFull (0x03003750 = copy of sndMixFull)
@   else 2-voice path: voices 0 and 1, rate modes x1/x2/x4/x8 by sample repetition (no
@   interpolation); out[i] = (s0*volA0 + s1*volA1 + 0x80) >> 8 (sign-magnitude, no clipping).
@   16 output samples per IRQ per FIFO. FIFO A (sndMixA) = right, FIFO B (sndMixB) = left.
@ ================================================================
	.global sndMixIrq
	.type sndMixIrq, %function
sndMixIrq:
	push {r4, r5, r6, r7, r8}	@ 080A0510
	mov r0, #0x600	@ 080A0514  IF = DMA1|DMA2
	ldr r1, .Lp_REG_IF	@ 080A0518
	strh r0, [r1]	@ 080A051C
	ldr r8, .Lp_REG_SOUND1CNT_L	@ 080A0520
	mov r0, #0x400	@ 080A0524
	strh r0, [r8, #IO_DMA1CNT_H]	@ 080A0528  DMA1CNT_H = 0x400 (stop)
	mov r0, #0x400	@ 080A052C
	strh r0, [r8, #IO_DMA2CNT_H]	@ 080A0530  DMA2CNT_H = 0x400 (stop)
	ldr r0, .Lp_sndMixA	@ 080A0534
	str r0, [r8, #IO_DMA1SAD]	@ 080A0538  DMA1SAD = sndMixA
	ldr r0, .Lp_sndMixB	@ 080A053C
	str r0, [r8, #IO_DMA2SAD]	@ 080A0540  DMA2SAD = sndMixB
	mov r0, #0xf600	@ 080A0544
	add r0, r0, #0x40	@ 080A0548
	strh r0, [r8, #IO_DMA1CNT_H]	@ 080A054C  DMA1CNT_H = 0xF640
	mov r0, #0xf600	@ 080A0550
	add r0, r0, #0x40	@ 080A0554
	strh r0, [r8, #IO_DMA2CNT_H]	@ 080A0558  DMA2CNT_H = 0xF640
	ldr r0, .Lp_REG_IE	@ 080A055C
	ldrh r2, [r0]	@ 080A0560
	mvn r3, #0x600	@ 080A0564
	and r2, r2, r3	@ 080A0568
	strh r2, [r0]	@ 080A056C  IE &= ~(DMA1|DMA2)
	ldr r0, .Lp_sndMixMode	@ 080A0570
	ldrb r1, [r0]	@ 080A0574
	teq r1, #0	@ 080A0578
	beq .Lmix2_voice0	@ 080A057C  mix mode 0: 2 voices
	ldr pc, .Lp_IW_sndMixFull	@ 080A0580  -> 5-voice mixer in IWRAM
.Lmix2_voice0:
	ldr r0, .Lp_sndVoices	@ 080A0584
	ldr r8, .Lp_sndStage	@ 080A0588
	ldr r1, [r0, #VOI_CUR]	@ 080A058C
	ldr r6, [r0, #VOI_END]	@ 080A0590
	cmp r1, r6	@ 080A0594  cur == end ?
	bne .L_080A05A8	@ 080A0598
	ldr r1, [r0, #VOI_LOOP]	@ 080A059C
	cmp r1, r6	@ 080A05A0
	beq .Lmix2_v0silent	@ 080A05A4  loop == end: silent
.L_080A05A8:
	ldrb r2, [r0]	@ 080A05A8
	tst r2, #1	@ 080A05AC
	bne .Lmix2_v0x2	@ 080A05B0
	tst r2, #2	@ 080A05B4
	bne .Lmix2_v0x4	@ 080A05B8
	tst r2, #4	@ 080A05BC
	bne .Lmix2_v0x8	@ 080A05C0
	mov r8, r1	@ 080A05C4  mode 0: mix straight from the sample
	add r1, r1, #0x10	@ 080A05C8
	str r1, [r0, #VOI_CUR]	@ 080A05CC
	b .Lmix2_voice1	@ 080A05D0
.Lmix2_v0x2:
	ldr r2, [r1], #4	@ 080A05D4
	strb r2, [r8]	@ 080A05D8
	strb r2, [r8, #1]	@ 080A05DC
	lsr r2, r2, #8	@ 080A05E0
	strb r2, [r8, #2]	@ 080A05E4
	strb r2, [r8, #3]	@ 080A05E8
	lsr r2, r2, #8	@ 080A05EC
	strb r2, [r8, #4]	@ 080A05F0
	strb r2, [r8, #5]	@ 080A05F4
	lsr r2, r2, #8	@ 080A05F8
	strb r2, [r8, #6]	@ 080A05FC
	strb r2, [r8, #7]	@ 080A0600
	ldr r2, [r1], #4	@ 080A0604
	str r1, [r0, #VOI_CUR]	@ 080A0608
	strb r2, [r8, #8]	@ 080A060C
	strb r2, [r8, #9]	@ 080A0610
	lsr r2, r2, #8	@ 080A0614
	strb r2, [r8, #0xa]	@ 080A0618
	strb r2, [r8, #0xb]	@ 080A061C
	lsr r2, r2, #8	@ 080A0620
	strb r2, [r8, #0xc]	@ 080A0624
	strb r2, [r8, #0xd]	@ 080A0628
	lsr r2, r2, #8	@ 080A062C
	strb r2, [r8, #0xe]	@ 080A0630
	strb r2, [r8, #0xf]	@ 080A0634
	b .Lmix2_voice1	@ 080A0638
.Lmix2_v0x4:
	ldr r2, [r1], #4	@ 080A063C
	str r1, [r0, #VOI_CUR]	@ 080A0640
	strb r2, [r8]	@ 080A0644
	strb r2, [r8, #1]	@ 080A0648
	strb r2, [r8, #2]	@ 080A064C
	strb r2, [r8, #3]	@ 080A0650
	lsr r2, r2, #8	@ 080A0654
	strb r2, [r8, #4]	@ 080A0658
	strb r2, [r8, #5]	@ 080A065C
	strb r2, [r8, #6]	@ 080A0660
	strb r2, [r8, #7]	@ 080A0664
	lsr r2, r2, #8	@ 080A0668
	strb r2, [r8, #8]	@ 080A066C
	strb r2, [r8, #9]	@ 080A0670
	strb r2, [r8, #0xa]	@ 080A0674
	strb r2, [r8, #0xb]	@ 080A0678
	lsr r2, r2, #8	@ 080A067C
	add r2, r2, r2, lsl #8	@ 080A0680
	add r2, r2, r2, lsl #16	@ 080A0684
	str r2, [r8, #0xc]	@ 080A0688
	b .Lmix2_voice1	@ 080A068C
.Lmix2_v0x8:
	ldr r2, [r1], #2	@ 080A0690
	str r1, [r0, #VOI_CUR]	@ 080A0694
	and r3, r2, #0xff	@ 080A0698
	add r3, r3, r3, lsl #8	@ 080A069C
	add r3, r3, r3, lsl #16	@ 080A06A0
	str r3, [r8]	@ 080A06A4
	str r3, [r8, #4]	@ 080A06A8
	and r3, r2, #0xff00	@ 080A06AC
	add r3, r3, r3, lsr #8	@ 080A06B0
	add r3, r3, r3, lsl #16	@ 080A06B4
	str r3, [r8, #8]	@ 080A06B8
	str r3, [r8, #0xc]	@ 080A06BC
	b .Lmix2_voice1	@ 080A06C0
.Lmix2_v0silent:
	ldr r8, .Lp_mixSilence	@ 080A06C4
.Lmix2_voice1:
	mov r7, r8	@ 080A06C8
	ldr r0, .Lp_sndVoices_0x10	@ 080A06CC
	ldr r8, .Lp_sndStage_0x10	@ 080A06D0
	ldr r1, [r0, #VOI_CUR]	@ 080A06D4
	ldr r6, [r0, #VOI_END]	@ 080A06D8
	cmp r1, r6	@ 080A06DC
	bne .L_080A06F0	@ 080A06E0
	ldr r1, [r0, #VOI_LOOP]	@ 080A06E4
	cmp r1, r6	@ 080A06E8
	beq .Lmix2_v1silent	@ 080A06EC
.L_080A06F0:
	ldrb r2, [r0]	@ 080A06F0
	tst r2, #1	@ 080A06F4
	bne .L_080A071C	@ 080A06F8
	tst r2, #2	@ 080A06FC
	bne .L_080A0784	@ 080A0700
	tst r2, #4	@ 080A0704
	bne .L_080A07DC	@ 080A0708
	mov r8, r1	@ 080A070C
	add r1, r1, #0x10	@ 080A0710
	str r1, [r0, #VOI_CUR]	@ 080A0714
	b .Lmix2_mix	@ 080A0718
.L_080A071C:
	ldr r2, [r1], #4	@ 080A071C
	strb r2, [r8]	@ 080A0720
	strb r2, [r8, #1]	@ 080A0724
	lsr r2, r2, #8	@ 080A0728
	strb r2, [r8, #2]	@ 080A072C
	strb r2, [r8, #3]	@ 080A0730
	lsr r2, r2, #8	@ 080A0734
	strb r2, [r8, #4]	@ 080A0738
	strb r2, [r8, #5]	@ 080A073C
	lsr r2, r2, #8	@ 080A0740
	strb r2, [r8, #6]	@ 080A0744
	strb r2, [r8, #7]	@ 080A0748
	ldr r2, [r1], #4	@ 080A074C
	str r1, [r0, #VOI_CUR]	@ 080A0750
	strb r2, [r8, #8]	@ 080A0754
	strb r2, [r8, #9]	@ 080A0758
	lsr r2, r2, #8	@ 080A075C
	strb r2, [r8, #0xa]	@ 080A0760
	strb r2, [r8, #0xb]	@ 080A0764
	lsr r2, r2, #8	@ 080A0768
	strb r2, [r8, #0xc]	@ 080A076C
	strb r2, [r8, #0xd]	@ 080A0770
	lsr r2, r2, #8	@ 080A0774
	strb r2, [r8, #0xe]	@ 080A0778
	strb r2, [r8, #0xf]	@ 080A077C
	b .Lmix2_mix	@ 080A0780
.L_080A0784:
	ldr r2, [r1], #4	@ 080A0784
	str r1, [r0, #VOI_CUR]	@ 080A0788
	strb r2, [r8]	@ 080A078C
	strb r2, [r8, #1]	@ 080A0790
	strb r2, [r8, #2]	@ 080A0794
	strb r2, [r8, #3]	@ 080A0798
	lsr r2, r2, #8	@ 080A079C
	strb r2, [r8, #4]	@ 080A07A0
	strb r2, [r8, #5]	@ 080A07A4
	strb r2, [r8, #6]	@ 080A07A8
	strb r2, [r8, #7]	@ 080A07AC
	lsr r2, r2, #8	@ 080A07B0
	strb r2, [r8, #8]	@ 080A07B4
	strb r2, [r8, #9]	@ 080A07B8
	strb r2, [r8, #0xa]	@ 080A07BC
	strb r2, [r8, #0xb]	@ 080A07C0
	lsr r2, r2, #8	@ 080A07C4
	strb r2, [r8, #0xc]	@ 080A07C8
	strb r2, [r8, #0xd]	@ 080A07CC
	strb r2, [r8, #0xe]	@ 080A07D0
	strb r2, [r8, #0xf]	@ 080A07D4
	b .Lmix2_mix	@ 080A07D8
.L_080A07DC:
	ldr r2, [r1], #2	@ 080A07DC
	str r1, [r0, #VOI_CUR]	@ 080A07E0
	and r3, r2, #0xff	@ 080A07E4
	add r3, r3, r3, lsl #8	@ 080A07E8
	add r3, r3, r3, lsl #16	@ 080A07EC
	str r3, [r8]	@ 080A07F0
	str r3, [r8, #4]	@ 080A07F4
	and r3, r2, #0xff00	@ 080A07F8
	add r3, r3, r3, lsr #8	@ 080A07FC
	add r3, r3, r3, lsl #16	@ 080A0800
	str r3, [r8, #8]	@ 080A0804
	str r3, [r8, #0xc]	@ 080A0808
	b .Lmix2_mix	@ 080A080C
.Lmix2_v1silent:
	ldr r8, .Lp_mixSilence_2	@ 080A0810
.Lmix2_mix:
	ldr r0, .Lp_sndVoices_2	@ 080A0814
	ldr r6, .Lp_sndMixA_2	@ 080A0818
.Lmix2_loop:
	ldrb r1, [r0, #2]	@ 080A081C
	ldrb r2, [r7], #1	@ 080A0820
	tst r2, #0x80	@ 080A0824
	bne .L_080A0878	@ 080A0828
	mul r3, r2, r1	@ 080A082C
	ldrb r1, [r0, #3]	@ 080A0830
	mul r4, r2, r1	@ 080A0834
	ldrb r1, [r0, #0x12]	@ 080A0838
	ldrb r2, [r8], #1	@ 080A083C
	tst r2, #0x80	@ 080A0840
	bne .L_080A08E0	@ 080A0844
	mul r5, r2, r1	@ 080A0848
	add r3, r3, r5	@ 080A084C
	add r3, r3, #0x80	@ 080A0850
	lsr r3, r3, #8	@ 080A0854
	strb r3, [r6]	@ 080A0858
	ldrb r1, [r0, #0x13]	@ 080A085C
	mul r3, r2, r1	@ 080A0860
	add r4, r4, r3	@ 080A0864
	add r4, r4, #0x80	@ 080A0868
	lsr r4, r4, #8	@ 080A086C
	strb r4, [r6, #0x10]	@ 080A0870
	b .Lmix2_next	@ 080A0874
.L_080A0878:
	mov r3, #0x100	@ 080A0878
	sub r2, r3, r2	@ 080A087C
	mul r3, r2, r1	@ 080A0880
	ldrb r1, [r0, #3]	@ 080A0884
	mul r4, r2, r1	@ 080A0888
	ldrb r1, [r0, #0x12]	@ 080A088C
	ldrb r2, [r8], #1	@ 080A0890
	tst r2, #0x80	@ 080A0894
	beq .L_080A0928	@ 080A0898
	mov r5, #0x100	@ 080A089C
	sub r2, r5, r2	@ 080A08A0
	mul r5, r2, r1	@ 080A08A4
	add r3, r3, r5	@ 080A08A8
	add r3, r3, #0x80	@ 080A08AC
	lsr r3, r3, #8	@ 080A08B0
	mov r5, #0	@ 080A08B4
	sub r3, r5, r3	@ 080A08B8
	strb r3, [r6]	@ 080A08BC
	ldrb r1, [r0, #0x13]	@ 080A08C0
	mul r3, r2, r1	@ 080A08C4
	add r4, r4, r3	@ 080A08C8
	add r4, r4, #0x80	@ 080A08CC
	lsr r4, r4, #8	@ 080A08D0
	sub r4, r5, r4	@ 080A08D4
	strb r4, [r6, #0x10]	@ 080A08D8
	b .Lmix2_next	@ 080A08DC
.L_080A08E0:
	mov r5, #0x100	@ 080A08E0
	sub r2, r5, r2	@ 080A08E4
	mul r5, r2, r1	@ 080A08E8
	mov r1, #0	@ 080A08EC
	sub r1, r1, r5	@ 080A08F0
	add r3, r3, r1	@ 080A08F4
	add r3, r3, #0x80	@ 080A08F8
	lsr r3, r3, #8	@ 080A08FC
	strb r3, [r6]	@ 080A0900
	ldrb r1, [r0, #0x13]	@ 080A0904
	mul r3, r2, r1	@ 080A0908
	mov r1, #0	@ 080A090C
	sub r3, r1, r3	@ 080A0910
	add r4, r4, r3	@ 080A0914
	add r4, r4, #0x80	@ 080A0918
	lsr r4, r4, #8	@ 080A091C
	strb r4, [r6, #0x10]	@ 080A0920
	b .Lmix2_next	@ 080A0924
.L_080A0928:
	mov r5, #0	@ 080A0928
	sub r3, r5, r3	@ 080A092C
	sub r4, r5, r4	@ 080A0930
	mul r5, r2, r1	@ 080A0934
	add r3, r3, r5	@ 080A0938
	add r3, r3, #0x80	@ 080A093C
	lsr r3, r3, #8	@ 080A0940
	strb r3, [r6]	@ 080A0944
	ldrb r1, [r0, #0x13]	@ 080A0948
	mul r3, r2, r1	@ 080A094C
	add r4, r4, r3	@ 080A0950
	add r4, r4, #0x80	@ 080A0954
	lsr r4, r4, #8	@ 080A0958
	strb r4, [r6, #0x10]	@ 080A095C
.Lmix2_next:
	add r6, r6, #1	@ 080A0960
	ldr r1, .Lp_sndMixB_2	@ 080A0964
	cmp r1, r6	@ 080A0968
	bne .Lmix2_loop	@ 080A096C
.Lmix_done:
	ldr r3, .Lp_REG_IE	@ 080A0970
	ldrh r4, [r3]	@ 080A0974
	orr r5, r4, #0x600	@ 080A0978  IE |= DMA1|DMA2
	strh r5, [r3]	@ 080A097C
	pop {r4, r5, r6, r7, r8}	@ 080A0980
	bx lr	@ 080A0984

@ mixSilence: 16 zero bytes used as the source of an idle voice.
mixSilence:
	.word 0, 0, 0, 0	@ 080A0988
	.word 0xFFFFF9FF	@ 080A0998
.Lp_REG_IF:
	.word REG_IF	@ 080A099C
.Lp_REG_SOUND1CNT_L:
	.word REG_SOUND1CNT_L	@ 080A09A0
.Lp_sndMixA:
	.word sndMixA	@ 080A09A4
.Lp_sndMixB:
	.word sndMixB	@ 080A09A8
.Lp_REG_IE:
	.word REG_IE	@ 080A09AC
.Lp_sndMixMode:
	.word sndMixMode	@ 080A09B0
.Lp_IW_sndMixFull:
	.word IW_sndMixFull	@ 080A09B4
.Lp_sndVoices:
	.word sndVoices	@ 080A09B8
.Lp_sndStage:
	.word sndStage	@ 080A09BC
.Lp_mixSilence:
	.word mixSilence	@ 080A09C0
.Lp_sndVoices_0x10:
	.word sndVoices+0x10	@ 080A09C4
.Lp_sndStage_0x10:
	.word sndStage+0x10	@ 080A09C8
.Lp_mixSilence_2:
	.word mixSilence	@ 080A09CC
.Lp_sndVoices_2:
	.word sndVoices	@ 080A09D0
.Lp_sndMixA_2:
	.word sndMixA	@ 080A09D4
.Lp_sndMixB_2:
	.word sndMixB	@ 080A09D8

@ ================================================================
@ void sndMixFull(void)  5-voice mixer, executed from IWRAM 0x03003750 (reached by ldr pc).
@   For each voice 0-4: produce 16 samples into sndStage[v]:
@     mode 0  copy 16 bytes            mode bit0 (x2): s, avg(s,next) ...
@     mode bit1 (x4): s, s, avg, avg   mode bit2 (x8): s x4, avg x4
@     (avg = midpoint in offset-binary; looks one byte ahead in the source)
@   then out[i] = (sum_v stage[v][i] * volA[v] + 0x80) >> 8  (and volB for FIFO B).
@   No clipping: a sum outside -128..127 wraps.
@ ================================================================
	.global sndMixFull
	.type sndMixFull, %function
sndMixFull:
	ldr r0, .Lp_sndVoices_3	@ 080A09DC
	ldr r8, .Lp_sndStage_2	@ 080A09E0
.Lfull_voiceLoop:
	ldr r1, [r0, #VOI_CUR]	@ 080A09E4
	ldr r6, [r0, #VOI_END]	@ 080A09E8
	cmp r1, r6	@ 080A09EC
	bne .L_080A0A00	@ 080A09F0
	ldr r1, [r0, #VOI_LOOP]	@ 080A09F4
	cmp r1, r6	@ 080A09F8
	beq .Lfull_silent	@ 080A09FC  idle voice
.L_080A0A00:
	ldrb r2, [r0]	@ 080A0A00
	tst r2, #1	@ 080A0A04
	bne .Lfull_x2	@ 080A0A08
	tst r2, #2	@ 080A0A0C
	bne .Lfull_x4	@ 080A0A10
	tst r2, #4	@ 080A0A14
	bne .Lfull_x8	@ 080A0A18
	ldr r2, [r1], #4	@ 080A0A1C
	str r2, [r8], #4	@ 080A0A20
	ldr r2, [r1], #4	@ 080A0A24
	str r2, [r8], #4	@ 080A0A28
	ldr r2, [r1], #4	@ 080A0A2C
	str r2, [r8], #4	@ 080A0A30
	ldr r2, [r1], #4	@ 080A0A34
	str r2, [r8], #4	@ 080A0A38
	str r1, [r0, #VOI_CUR]	@ 080A0A3C
	b .Lfull_nextVoice	@ 080A0A40
.Lfull_x2:
	ldr r2, [r1], #4	@ 080A0A44
	lsr r3, r2, #8	@ 080A0A48
	lsr r4, r2, #0x10	@ 080A0A4C
	lsr r5, r2, #0x18	@ 080A0A50
	strb r2, [r8]	@ 080A0A54
	strb r3, [r8, #2]	@ 080A0A58
	strb r4, [r8, #4]	@ 080A0A5C
	strb r5, [r8, #6]	@ 080A0A60
	and r2, r2, #0xff	@ 080A0A64
	and r3, r3, #0xff	@ 080A0A68
	and r4, r4, #0xff	@ 080A0A6C
	add r2, r2, #0x80	@ 080A0A70
	add r3, r3, #0x80	@ 080A0A74
	add r4, r4, #0x80	@ 080A0A78
	add r5, r5, #0x80	@ 080A0A7C
	and r2, r2, #0xff	@ 080A0A80
	and r3, r3, #0xff	@ 080A0A84
	and r4, r4, #0xff	@ 080A0A88
	and r5, r5, #0xff	@ 080A0A8C
	add r2, r2, r3	@ 080A0A90
	add r3, r3, r4	@ 080A0A94
	add r4, r4, r5	@ 080A0A98
	lsr r2, r2, #1	@ 080A0A9C
	lsr r3, r3, #1	@ 080A0AA0
	lsr r4, r4, #1	@ 080A0AA4
	sub r2, r2, #0x80	@ 080A0AA8
	sub r3, r3, #0x80	@ 080A0AAC
	sub r4, r4, #0x80	@ 080A0AB0
	strb r2, [r8, #1]	@ 080A0AB4
	strb r3, [r8, #3]	@ 080A0AB8
	strb r4, [r8, #5]	@ 080A0ABC
	ldr r2, [r1], #4	@ 080A0AC0
	str r1, [r0, #VOI_CUR]	@ 080A0AC4
	ldrb r1, [r1]	@ 080A0AC8
	lsr r3, r2, #8	@ 080A0ACC
	lsr r4, r2, #0x10	@ 080A0AD0
	lsr r6, r2, #0x18	@ 080A0AD4
	strb r2, [r8, #8]	@ 080A0AD8
	strb r3, [r8, #0xa]	@ 080A0ADC
	strb r4, [r8, #0xc]	@ 080A0AE0
	strb r6, [r8, #0xe]	@ 080A0AE4
	and r2, r2, #0xff	@ 080A0AE8
	and r3, r3, #0xff	@ 080A0AEC
	and r4, r4, #0xff	@ 080A0AF0
	add r2, r2, #0x80	@ 080A0AF4
	add r3, r3, #0x80	@ 080A0AF8
	add r4, r4, #0x80	@ 080A0AFC
	add r6, r6, #0x80	@ 080A0B00
	add r1, r1, #0x80	@ 080A0B04
	and r2, r2, #0xff	@ 080A0B08
	and r3, r3, #0xff	@ 080A0B0C
	and r4, r4, #0xff	@ 080A0B10
	and r6, r6, #0xff	@ 080A0B14
	and r1, r1, #0xff	@ 080A0B18
	add r5, r5, r2	@ 080A0B1C
	add r2, r2, r3	@ 080A0B20
	add r3, r3, r4	@ 080A0B24
	add r4, r4, r6	@ 080A0B28
	add r6, r6, r1	@ 080A0B2C
	lsr r2, r2, #1	@ 080A0B30
	lsr r3, r3, #1	@ 080A0B34
	lsr r4, r4, #1	@ 080A0B38
	lsr r5, r5, #1	@ 080A0B3C
	lsr r6, r6, #1	@ 080A0B40
	sub r2, r2, #0x80	@ 080A0B44
	sub r3, r3, #0x80	@ 080A0B48
	sub r4, r4, #0x80	@ 080A0B4C
	sub r5, r5, #0x80	@ 080A0B50
	sub r6, r6, #0x80	@ 080A0B54
	strb r2, [r8, #9]	@ 080A0B58
	strb r3, [r8, #0xb]	@ 080A0B5C
	strb r4, [r8, #0xd]	@ 080A0B60
	strb r6, [r8, #0xf]	@ 080A0B64
	strb r5, [r8, #7]	@ 080A0B68
	add r8, r8, #0x10	@ 080A0B6C
	b .Lfull_nextVoice	@ 080A0B70
.Lfull_x4:
	ldr r2, [r1], #4	@ 080A0B74
	str r1, [r0, #VOI_CUR]	@ 080A0B78
	ldrb r1, [r1]	@ 080A0B7C
	lsr r3, r2, #8	@ 080A0B80
	lsr r4, r2, #0x10	@ 080A0B84
	lsr r5, r2, #0x18	@ 080A0B88
	strb r2, [r8]	@ 080A0B8C
	strb r2, [r8, #1]	@ 080A0B90
	strb r3, [r8, #4]	@ 080A0B94
	strb r3, [r8, #5]	@ 080A0B98
	strb r4, [r8, #8]	@ 080A0B9C
	strb r4, [r8, #9]	@ 080A0BA0
	strb r5, [r8, #0xc]	@ 080A0BA4
	strb r5, [r8, #0xd]	@ 080A0BA8
	and r2, r2, #0xff	@ 080A0BAC
	and r3, r3, #0xff	@ 080A0BB0
	and r4, r4, #0xff	@ 080A0BB4
	add r2, r2, #0x80	@ 080A0BB8
	add r3, r3, #0x80	@ 080A0BBC
	add r4, r4, #0x80	@ 080A0BC0
	add r5, r5, #0x80	@ 080A0BC4
	add r1, r1, #0x80	@ 080A0BC8
	and r2, r2, #0xff	@ 080A0BCC
	and r3, r3, #0xff	@ 080A0BD0
	and r4, r4, #0xff	@ 080A0BD4
	and r5, r5, #0xff	@ 080A0BD8
	and r1, r1, #0xff	@ 080A0BDC
	add r2, r2, r3	@ 080A0BE0
	add r3, r3, r4	@ 080A0BE4
	add r4, r4, r5	@ 080A0BE8
	add r5, r5, r1	@ 080A0BEC
	lsr r2, r2, #1	@ 080A0BF0
	lsr r3, r3, #1	@ 080A0BF4
	lsr r4, r4, #1	@ 080A0BF8
	lsr r5, r5, #1	@ 080A0BFC
	sub r2, r2, #0x80	@ 080A0C00
	sub r3, r3, #0x80	@ 080A0C04
	sub r4, r4, #0x80	@ 080A0C08
	sub r5, r5, #0x80	@ 080A0C0C
	strb r2, [r8, #2]	@ 080A0C10
	strb r2, [r8, #3]	@ 080A0C14
	strb r3, [r8, #6]	@ 080A0C18
	strb r3, [r8, #7]	@ 080A0C1C
	strb r4, [r8, #0xa]	@ 080A0C20
	strb r4, [r8, #0xb]	@ 080A0C24
	strb r5, [r8, #0xe]	@ 080A0C28
	strb r5, [r8, #0xf]	@ 080A0C2C
	add r8, r8, #0x10	@ 080A0C30
	b .Lfull_nextVoice	@ 080A0C34
.Lfull_x8:
	ldr r2, [r1], #2	@ 080A0C38
	str r1, [r0, #VOI_CUR]	@ 080A0C3C
	ldrb r1, [r1]	@ 080A0C40
	and r3, r2, #0xff	@ 080A0C44
	add r4, r3, r3, lsl #8	@ 080A0C48
	add r4, r4, r4, lsl #16	@ 080A0C4C
	str r4, [r8]	@ 080A0C50
	lsr r2, r2, #8	@ 080A0C54
	and r2, r2, #0xff	@ 080A0C58
	add r4, r2, r2, lsl #8	@ 080A0C5C
	add r4, r4, r4, lsl #16	@ 080A0C60
	str r4, [r8, #8]	@ 080A0C64
	and r2, r2, #0xff	@ 080A0C68
	and r3, r3, #0xff	@ 080A0C6C
	add r2, r2, #0x80	@ 080A0C70
	add r3, r3, #0x80	@ 080A0C74
	add r1, r1, #0x80	@ 080A0C78
	and r2, r2, #0xff	@ 080A0C7C
	and r3, r3, #0xff	@ 080A0C80
	and r1, r1, #0xff	@ 080A0C84
	add r3, r3, r2	@ 080A0C88
	add r2, r2, r1	@ 080A0C8C
	lsr r2, r2, #1	@ 080A0C90
	lsr r3, r3, #1	@ 080A0C94
	sub r2, r2, #0x80	@ 080A0C98
	sub r3, r3, #0x80	@ 080A0C9C
	strb r3, [r8, #4]	@ 080A0CA0
	strb r3, [r8, #5]	@ 080A0CA4
	strb r3, [r8, #6]	@ 080A0CA8
	strb r3, [r8, #7]	@ 080A0CAC
	strb r2, [r8, #0xc]	@ 080A0CB0
	strb r2, [r8, #0xd]	@ 080A0CB4
	strb r2, [r8, #0xe]	@ 080A0CB8
	strb r2, [r8, #0xf]	@ 080A0CBC
	add r8, r8, #0x10	@ 080A0CC0
	b .Lfull_nextVoice	@ 080A0CC4
.Lfull_silent:
	mov r2, #0	@ 080A0CC8
	str r2, [r8], #4	@ 080A0CCC
	str r2, [r8], #4	@ 080A0CD0
	str r2, [r8], #4	@ 080A0CD4
	str r2, [r8], #4	@ 080A0CD8
.Lfull_nextVoice:
	add r0, r0, #0x10	@ 080A0CDC
	ldr r1, .Lp_sndVoices_0x50	@ 080A0CE0
	cmp r0, r1	@ 080A0CE4  5 voices
	bne .Lfull_voiceLoop	@ 080A0CE8
	ldr r0, .Lp_sndVoices_4	@ 080A0CEC
	ldr r7, .Lp_sndMixA_3	@ 080A0CF0
	ldr r8, .Lp_sndStage_3	@ 080A0CF4
.Lfull_mixLoop:
	ldrb r6, [r0, #2]	@ 080A0CF8
	ldrb r1, [r8]	@ 080A0CFC
	tst r1, #0x80	@ 080A0D00
	bne .L_080A0D18	@ 080A0D04
	mul r4, r1, r6	@ 080A0D08
	ldrb r6, [r0, #3]	@ 080A0D0C
	mul r5, r1, r6	@ 080A0D10
	b .L_080A0D38	@ 080A0D14
.L_080A0D18:
	mov r2, #0x100	@ 080A0D18
	sub r1, r2, r1	@ 080A0D1C
	mul r4, r1, r6	@ 080A0D20
	ldrb r6, [r0, #3]	@ 080A0D24
	mul r5, r1, r6	@ 080A0D28
	mov r2, #0	@ 080A0D2C
	sub r4, r2, r4	@ 080A0D30
	sub r5, r2, r5	@ 080A0D34
.L_080A0D38:
	ldrb r6, [r0, #0x12]	@ 080A0D38
	ldrb r1, [r8, #0x10]	@ 080A0D3C
	tst r1, #0x80	@ 080A0D40
	bne .L_080A0D60	@ 080A0D44
	mul r2, r1, r6	@ 080A0D48
	add r4, r4, r2	@ 080A0D4C
	ldrb r6, [r0, #0x13]	@ 080A0D50
	mul r2, r1, r6	@ 080A0D54
	add r5, r5, r2	@ 080A0D58
	b .L_080A0D88	@ 080A0D5C
.L_080A0D60:
	mov r2, #0x100	@ 080A0D60
	sub r1, r2, r1	@ 080A0D64
	mul r2, r1, r6	@ 080A0D68
	ldrb r6, [r0, #0x13]	@ 080A0D6C
	mul r3, r1, r6	@ 080A0D70
	mov r1, #0	@ 080A0D74
	sub r2, r1, r2	@ 080A0D78
	sub r3, r1, r3	@ 080A0D7C
	add r4, r4, r2	@ 080A0D80
	add r5, r5, r3	@ 080A0D84
.L_080A0D88:
	ldrb r6, [r0, #0x22]	@ 080A0D88
	ldrb r1, [r8, #0x20]	@ 080A0D8C
	tst r1, #0x80	@ 080A0D90
	bne .L_080A0DB0	@ 080A0D94
	mul r2, r1, r6	@ 080A0D98
	add r4, r4, r2	@ 080A0D9C
	ldrb r6, [r0, #0x23]	@ 080A0DA0
	mul r2, r1, r6	@ 080A0DA4
	add r5, r5, r2	@ 080A0DA8
	b .L_080A0DD8	@ 080A0DAC
.L_080A0DB0:
	mov r2, #0x100	@ 080A0DB0
	sub r1, r2, r1	@ 080A0DB4
	mul r2, r1, r6	@ 080A0DB8
	ldrb r6, [r0, #0x23]	@ 080A0DBC
	mul r3, r1, r6	@ 080A0DC0
	mov r1, #0	@ 080A0DC4
	sub r2, r1, r2	@ 080A0DC8
	sub r3, r1, r3	@ 080A0DCC
	add r4, r4, r2	@ 080A0DD0
	add r5, r5, r3	@ 080A0DD4
.L_080A0DD8:
	ldrb r6, [r0, #0x32]	@ 080A0DD8
	ldrb r1, [r8, #0x30]	@ 080A0DDC
	tst r1, #0x80	@ 080A0DE0
	bne .L_080A0E00	@ 080A0DE4
	mul r2, r1, r6	@ 080A0DE8
	add r4, r4, r2	@ 080A0DEC
	ldrb r6, [r0, #0x33]	@ 080A0DF0
	mul r2, r1, r6	@ 080A0DF4
	add r5, r5, r2	@ 080A0DF8
	b .L_080A0E28	@ 080A0DFC
.L_080A0E00:
	mov r2, #0x100	@ 080A0E00
	sub r1, r2, r1	@ 080A0E04
	mul r2, r1, r6	@ 080A0E08
	ldrb r6, [r0, #0x33]	@ 080A0E0C
	mul r3, r1, r6	@ 080A0E10
	mov r1, #0	@ 080A0E14
	sub r2, r1, r2	@ 080A0E18
	sub r3, r1, r3	@ 080A0E1C
	add r4, r4, r2	@ 080A0E20
	add r5, r5, r3	@ 080A0E24
.L_080A0E28:
	ldrb r6, [r0, #0x42]	@ 080A0E28
	ldrb r1, [r8, #0x40]	@ 080A0E2C
	tst r1, #0x80	@ 080A0E30
	bne .L_080A0E50	@ 080A0E34
	mul r2, r1, r6	@ 080A0E38
	add r4, r4, r2	@ 080A0E3C
	ldrb r6, [r0, #0x43]	@ 080A0E40
	mul r2, r1, r6	@ 080A0E44
	add r5, r5, r2	@ 080A0E48
	b .L_080A0E78	@ 080A0E4C
.L_080A0E50:
	mov r2, #0x100	@ 080A0E50
	sub r1, r2, r1	@ 080A0E54
	mul r2, r1, r6	@ 080A0E58
	ldrb r6, [r0, #0x43]	@ 080A0E5C
	mul r3, r1, r6	@ 080A0E60
	mov r1, #0	@ 080A0E64
	sub r2, r1, r2	@ 080A0E68
	sub r3, r1, r3	@ 080A0E6C
	add r4, r4, r2	@ 080A0E70
	add r5, r5, r3	@ 080A0E74
.L_080A0E78:
	add r4, r4, #0x80	@ 080A0E78
	add r5, r5, #0x80	@ 080A0E7C
	lsr r4, r4, #8	@ 080A0E80
	lsr r5, r5, #8	@ 080A0E84
	strb r5, [r7, #0x10]	@ 080A0E88  FIFO B (left)
	strb r4, [r7], #1	@ 080A0E8C  FIFO A (right)
	add r8, r8, #1	@ 080A0E90
	ldr r1, .Lp_sndMixB_3	@ 080A0E94
	cmp r1, r7	@ 080A0E98
	bne .Lfull_mixLoop	@ 080A0E9C
	ldr r3, .Lp_REG_IE_2	@ 080A0EA0
	ldrh r4, [r3]	@ 080A0EA4
	orr r5, r4, #0x600	@ 080A0EA8
	strh r5, [r3]	@ 080A0EAC
	pop {r4, r5, r6, r7, r8}	@ 080A0EB0
	bx lr	@ 080A0EB4
.Lp_sndVoices_3:
	.word sndVoices	@ 080A0EB8
.Lp_sndStage_2:
	.word sndStage	@ 080A0EBC
.Lp_sndVoices_0x50:
	.word sndVoices+0x50	@ 080A0EC0
.Lp_sndVoices_4:
	.word sndVoices	@ 080A0EC4
.Lp_sndMixA_3:
	.word sndMixA	@ 080A0EC8
.Lp_sndStage_3:
	.word sndStage	@ 080A0ECC
.Lp_sndMixB_3:
	.word sndMixB	@ 080A0ED0
.Lp_REG_IE_2:
	.word REG_IE	@ 080A0ED4
	.thumb

@ ================================================================
@ Game-side C glue (Thumb).
@   void Sound_Play(u16 id)   -- skipped when *(u8*)0x02000000 != 0 and id > 0x2F
@   void Sound_Init(void)     -- sndInit, then DMA3-copy 0x80A0510 -> 0x03003150 and
@                                0x80A09DC -> 0x03003750 (0x300 words each; the 2nd overlaps)
@   void Sound_Frame(void); void Sound_DmaIrqA/B(void); void Sound_FadeOut(u8); void Sound_FadeIn(u8)
@ ================================================================
	.global Sound_Play
	.type Sound_Play, %function
Sound_Play:
	push {lr}	@ 080A0ED8
	lsls r0, r0, #0x10	@ 080A0EDA
	lsrs r1, r0, #0x10	@ 080A0EDC
	adds r2, r1, #0	@ 080A0EDE
	ldr r0, .Lp_0x02000000	@ 080A0EE0
	ldrb r0, [r0]	@ 080A0EE2
	cmp r0, #0	@ 080A0EE4
	beq .L_080A0EEC	@ 080A0EE6
	cmp r1, #0x2f	@ 080A0EE8
	bls .L_080A0EF2	@ 080A0EEA
.L_080A0EEC:
	adds r0, r2, #0	@ 080A0EEC
	bl vnr_sndQueueSound_A4	@ 080A0EEE
.L_080A0EF2:
	pop {r0}	@ 080A0EF2
	bx r0	@ 080A0EF4
	movs r0, r0	@ 080A0EF6
.Lp_0x02000000:
	movs r0, r0	@ 080A0EF8
	lsls r0, r0, #8	@ 080A0EFA
	.global Sound_Init
	.type Sound_Init, %function
Sound_Init:
	push {lr}	@ 080A0EFC
	bl vnr_sndInit_AC	@ 080A0EFE
	ldr r0, .Lp_0x040000D4	@ 080A0F02
	ldr r1, .Lp_sndMixIrq	@ 080A0F04
	str r1, [r0]	@ 080A0F06
	ldr r1, .Lp_IW_sndMixIrq	@ 080A0F08
	str r1, [r0, #4]	@ 080A0F0A
	ldr r2, .Lp_0x80000300	@ 080A0F0C
	str r2, [r0, #8]	@ 080A0F0E
	ldr r1, [r0, #8]	@ 080A0F10
	ldr r1, .Lp_sndMixFull	@ 080A0F12
	str r1, [r0]	@ 080A0F14
	ldr r1, .Lp_IW_sndMixFull_2	@ 080A0F16
	str r1, [r0, #4]	@ 080A0F18
	str r2, [r0, #8]	@ 080A0F1A
	ldr r0, [r0, #8]	@ 080A0F1C
	pop {r0}	@ 080A0F1E
	bx r0	@ 080A0F20
	movs r0, r0	@ 080A0F22
.Lp_0x040000D4:
	lsls r4, r2, #3	@ 080A0F24
	lsls r0, r0, #0x10	@ 080A0F26
.Lp_sndMixIrq:
	lsls r0, r2, #0x14	@ 080A0F28
	lsrs r2, r1, #0x20	@ 080A0F2A
.Lp_IW_sndMixIrq:
	adds r1, #0x50	@ 080A0F2C
	lsls r0, r0, #0xc	@ 080A0F2E
.Lp_0x80000300:
	lsls r0, r0, #0xc	@ 080A0F30
	strh r0, [r0]	@ 080A0F32
.Lp_sndMixFull:
	lsrs r4, r3, #7	@ 080A0F34
	lsrs r2, r1, #0x20	@ 080A0F36
.Lp_IW_sndMixFull_2:
	adds r7, #0x50	@ 080A0F38
	lsls r0, r0, #0xc	@ 080A0F3A
	.global Sound_Frame
	.type Sound_Frame, %function
Sound_Frame:
	push {lr}	@ 080A0F3C
	bl vnr_sndFrame_B4	@ 080A0F3E
	pop {r0}	@ 080A0F42
	bx r0	@ 080A0F44
	movs r0, r0	@ 080A0F46
	.global Sound_DmaIrqA
	.type Sound_DmaIrqA, %function
Sound_DmaIrqA:
	push {lr}	@ 080A0F48
	bl vnr_sndMixIrq_BC	@ 080A0F4A
	pop {r0}	@ 080A0F4E
	bx r0	@ 080A0F50
	movs r0, r0	@ 080A0F52
	.global Sound_DmaIrqB
	.type Sound_DmaIrqB, %function
Sound_DmaIrqB:
	push {lr}	@ 080A0F54
	bl vnr_sndMixIrq_C4	@ 080A0F56
	pop {r0}	@ 080A0F5A
	bx r0	@ 080A0F5C
	movs r0, r0	@ 080A0F5E
	.global Sound_FadeOut
	.type Sound_FadeOut, %function
Sound_FadeOut:
	push {lr}	@ 080A0F60
	lsls r0, r0, #0x18	@ 080A0F62
	lsrs r0, r0, #0x18	@ 080A0F64
	bl vnr_sndFadeOut_CC	@ 080A0F66
	pop {r0}	@ 080A0F6A
	bx r0	@ 080A0F6C
	movs r0, r0	@ 080A0F6E
	.global Sound_FadeIn
	.type Sound_FadeIn, %function
Sound_FadeIn:
	push {lr}	@ 080A0F70
	lsls r0, r0, #0x18	@ 080A0F72
	lsrs r0, r0, #0x18	@ 080A0F74
	bl vnr_sndFadeIn_D4	@ 080A0F76
	pop {r0}	@ 080A0F7A
	bx r0	@ 080A0F7C
	movs r0, r0	@ 080A0F7E

@ psgFreqTable[84]: GB frequency values. Note 0 = 0x078 (68.0 Hz, ~C2 + 66 cents);
@ octaves exact. The whole PSG scale is about 2/3 semitone sharp of MV's table.
psgFreqTable:
	.hword 0x078, 0x0E4, 0x14A, 0x1AA, 0x206, 0x25B, 0x2AC, 0x2F9, 0x341, 0x385, 0x3C6, 0x403	@ 080A0F80
	.hword 0x43C, 0x472, 0x4A5, 0x4D5, 0x503, 0x52E, 0x556, 0x57D, 0x5A1, 0x5C3, 0x5E3, 0x601	@ 080A0F98
	.hword 0x61E, 0x639, 0x653, 0x66B, 0x681, 0x697, 0x6AB, 0x6BE, 0x6D0, 0x6E1, 0x6F1, 0x701	@ 080A0FB0
	.hword 0x70F, 0x71C, 0x729, 0x735, 0x741, 0x74B, 0x756, 0x75F, 0x768, 0x771, 0x779, 0x780	@ 080A0FC8
	.hword 0x787, 0x78E, 0x795, 0x79B, 0x7A0, 0x7A6, 0x7AB, 0x7B0, 0x7B4, 0x7B8, 0x7BC, 0x7C0	@ 080A0FE0
	.hword 0x7C4, 0x7C7, 0x7CA, 0x7CD, 0x7D0, 0x7D3, 0x7D5, 0x7D8, 0x7DA, 0x7DC, 0x7DE, 0x7E0	@ 080A0FF8
	.hword 0x7E2, 0x7E4, 0x7E5, 0x7E7, 0x7E8, 0x7E9, 0x7EB, 0x7EC, 0x7ED, 0x7EE, 0x7EF, 0x7F0	@ 080A1010

@ Per-track PSG register addresses (tracks 0-7). Same layout as Magical Vacation.
psgEnvRegTable:
	.word REG_SOUND1CNT_H	@ 080A1028
	.word REG_SOUND2CNT_L	@ 080A102C
	.word REG_SOUND3CNT_H	@ 080A1030
	.word REG_SOUND4CNT_L	@ 080A1034
	.word REG_SOUND1CNT_H	@ 080A1038
	.word REG_SOUND2CNT_L	@ 080A103C
	.word REG_SOUND3CNT_H	@ 080A1040
	.word REG_SOUND4CNT_L	@ 080A1044
psgCtrlRegTable:
	.word REG_SOUND1CNT_X	@ 080A1048
	.word REG_SOUND2CNT_H	@ 080A104C
	.word REG_SOUND3CNT_X	@ 080A1050
	.word REG_SOUND4CNT_H	@ 080A1054
	.word REG_SOUND1CNT_X	@ 080A1058
	.word REG_SOUND2CNT_H	@ 080A105C
	.word REG_SOUND3CNT_X	@ 080A1060
	.word REG_SOUND4CNT_H	@ 080A1064

@ panBitsTable[12] / panMaskTable[12] (SOUNDCNT_L high byte bits / masks).
panBitsTable:
	.byte 0x11, 0x22, 0x44, 0x88, 0x11, 0x22, 0x44, 0x88, 0x11, 0x22, 0x44, 0x88	@ 080A1068
panMaskTable:
	.byte 0xEE, 0xDD, 0xBB, 0x77, 0xEE, 0xDD, 0xBB, 0x77, 0xEE, 0xDD, 0xBB, 0x77	@ 080A1074

@ sndTimerReload: TM0CNT_L = 0xFC00 -> 16384 Hz output; sndIrqMask = ~(DMA1|DMA2).
sndTimerReload:
	.word 0x0000FC00	@ 080A1080
sndIrqMask:
	.word 0xFFFFF9FF	@ 080A1084
	.arm

@ ----------------------------------------------------------------
@ void sndQueueSound(u16 id)   sndQueue[w] = id; w = (w + 2) & 0xF   (8 entries)
@ ----------------------------------------------------------------
	.global sndQueueSound
	.type sndQueueSound, %function
sndQueueSound:
	ldr r1, .Lp_sndQueueWrite	@ 080A1088
	ldrb r2, [r1]	@ 080A108C
	ldr r3, .Lp_sndQueue	@ 080A1090
	strh r0, [r3, r2]	@ 080A1094  queue[w] = id
	add r2, r2, #2	@ 080A1098
	and r2, r2, #0xf	@ 080A109C  w = (w + 2) & 0xF
	strb r2, [r1]	@ 080A10A0
	bx lr	@ 080A10A4

@ ----------------------------------------------------------------
@ void sndFadeIn(u8 n)   resume after a fade-out pause and fade the master volume in.
@   volume = 0; fadeInFrames = n*8 (stored u16, read as u8 -> n >= 32 wraps);
@   step/period as in sndFadeOut; NR50 = 0; every track with flag 0x01 or 0x80 -> flags = 1;
@   TM0CNT_H = 0x80; then queue sound id 0x36.
@ ----------------------------------------------------------------
	.global sndFadeIn
	.type sndFadeIn, %function
sndFadeIn:
	ldr r1, .Lp_sndMaster	@ 080A10A8
	mov r2, #0	@ 080A10AC
	strb r2, [r1]	@ 080A10B0
	lsl r2, r0, #3	@ 080A10B4
	strh r2, [r1, #MST_INFRAMES]	@ 080A10B8  fadeInFrames = n*8
	cmp r0, #0x20	@ 080A10BC
	bmi .L_080A10D8	@ 080A10C0
	strh r2, [r1, #MST_INACC]	@ 080A10C4
	strh r2, [r1, #MST_INPERIOD]	@ 080A10C8
	mov r3, #1	@ 080A10CC
	strb r3, [r1, #MST_STEP]	@ 080A10D0
	b .L_080A111C	@ 080A10D4
.L_080A10D8:
	mov r2, #0x100	@ 080A10D8
	strh r2, [r1, #MST_INACC]	@ 080A10DC
	strh r2, [r1, #MST_INPERIOD]	@ 080A10E0
	lsl r0, r0, #5	@ 080A10E4
	mov r1, #0x20	@ 080A10E8
	mov r2, #6	@ 080A10EC
	mov r3, #0	@ 080A10F0
.L_080A10F4:
	cmp r1, r0	@ 080A10F4
	subpl r1, r1, r0	@ 080A10F8
	addpl r3, r3, #1	@ 080A10FC
	lsr r0, r0, #1	@ 080A1100
	sub r2, r2, #1	@ 080A1104
	teq r2, #0	@ 080A1108
	lslne r3, r3, #1	@ 080A110C
	bne .L_080A10F4	@ 080A1110
	ldr r1, .Lp_sndMaster_2	@ 080A1114
	strb r3, [r1, #MST_STEP]	@ 080A1118
.L_080A111C:
	mov r0, #0	@ 080A111C
	ldr r1, .Lp_REG_SOUND1CNT_L_2	@ 080A1120
	strh r0, [r1, #0x20]	@ 080A1124
	ldr r1, .Lp_sndTracks	@ 080A1128
	ldr r2, .Lp_sndQueueRead	@ 080A112C
.LfadeIn_resume:
	ldrb r0, [r1]	@ 080A1130
	tst r0, #0x81	@ 080A1134  active or paused -> active
	movne r0, #1	@ 080A1138
	moveq r0, #0	@ 080A113C
	strb r0, [r1], #0x38	@ 080A1140
	teq r1, r2	@ 080A1144
	bne .LfadeIn_resume	@ 080A1148
	ldr r3, .Lp_REG_SOUND1CNT_L_2	@ 080A114C
	mov r0, #0x80	@ 080A1150
	strh r0, [r3, #0xa2]	@ 080A1154  TM0CNT_H = 0x80
	mov r0, #0x36	@ 080A1158
	b sndQueueSound	@ 080A115C  tail: queue id 0x36

@ ----------------------------------------------------------------
@ void sndFadeOut(u8 n)  fadeOutFrames = n*8; step = n >= 32 ? 1 (period n*8) : floor(32/n) per frame.
@   At the end all tracks are PAUSED (flags = 0x80 if they were active or paused), not stopped.
@ ----------------------------------------------------------------
	.global sndFadeOut
	.type sndFadeOut, %function
sndFadeOut:
	ldr r1, .Lp_sndMaster_3	@ 080A1160
	lsl r2, r0, #3	@ 080A1164
	strh r2, [r1, #MST_OUTFRAMES]	@ 080A1168
	cmp r0, #0x20	@ 080A116C
	bmi .L_080A1188	@ 080A1170
	strh r2, [r1, #MST_OUTACC]	@ 080A1174
	strh r2, [r1, #MST_OUTPERIOD]	@ 080A1178
	mov r3, #1	@ 080A117C
	strb r3, [r1, #MST_STEP]	@ 080A1180
	bx lr	@ 080A1184
.L_080A1188:
	mov r2, #0x100	@ 080A1188
	strh r2, [r1, #MST_OUTACC]	@ 080A118C
	strh r2, [r1, #MST_OUTPERIOD]	@ 080A1190
	lsl r0, r0, #5	@ 080A1194
	mov r1, #0x20	@ 080A1198
	mov r2, #6	@ 080A119C
	mov r3, #0	@ 080A11A0
.LfadeOut_div:
	cmp r1, r0	@ 080A11A4
	subpl r1, r1, r0	@ 080A11A8
	addpl r3, r3, #1	@ 080A11AC
	lsr r0, r0, #1	@ 080A11B0
	sub r2, r2, #1	@ 080A11B4
	teq r2, #0	@ 080A11B8
	lslne r3, r3, #1	@ 080A11BC
	bne .LfadeOut_div	@ 080A11C0
	ldr r1, .Lp_sndMaster_4	@ 080A11C4
	strb r3, [r1, #MST_STEP]	@ 080A11C8
	bx lr	@ 080A11CC

@ ----------------------------------------------------------------
@ void sndInit(void)
@   SOUNDCNT_X = 0, 0x8F;  TM0CNT_H = 0;  SOUNDCNT_H = 0x8802 (FIFO reset) then 0x210E:
@   PSG 100 %, A/B 100 %, A -> right only, B -> left only, both on timer 0.  SOUNDCNT_L = 0x77.
@   clear 14 tracks, queue, voices/mix buffers (0x03002E0C-0x03002EEB); master volume 0xFF;
@   DMA1 SAD/DAD = sndMixA / FIFO_A, DMA2 SAD/DAD = sndMixB / FIFO_B; TM0CNT_L = 0xFC00.
@ ----------------------------------------------------------------
	.global sndInit
	.type sndInit, %function
sndInit:
	ldr r3, .Lp_REG_SOUND1CNT_L_2	@ 080A11D0
	mov r0, #0	@ 080A11D4
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 080A11D8
	mov r0, #0x8f	@ 080A11DC
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 080A11E0
	mov r0, #0	@ 080A11E4
	strh r0, [r3, #IO_TM0CNT_H]	@ 080A11E8
	ldr r0, .Lp_0x00008802	@ 080A11EC
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 080A11F0  SOUNDCNT_H = 0x8802
	ldr r0, .Lp_0x0000210E	@ 080A11F4
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 080A11F8  SOUNDCNT_H = 0x210E
	mov r0, #0x77	@ 080A11FC
	strh r0, [r3, #IO_SOUNDCNT_L]	@ 080A1200
	ldr r1, .Lp_sndSoundCntL	@ 080A1204
	strh r0, [r1]	@ 080A1208
	mov r0, #0	@ 080A120C
	ldr r1, .Lp_sndTracks_2	@ 080A1210
	ldr r2, .Lp_sndQueueRead_2	@ 080A1214
.L_080A1218:
	strb r0, [r1], #0x38	@ 080A1218
	teq r1, r2	@ 080A121C
	bne .L_080A1218	@ 080A1220
	strh r0, [r1]	@ 080A1224
	str r0, [r1, #2]	@ 080A1228
	str r0, [r1, #6]	@ 080A122C
	ldr r1, .Lp_sndVoices_5	@ 080A1230
	ldr r2, .Lp_0x03002EEC	@ 080A1234
.L_080A1238:
	str r0, [r1], #4	@ 080A1238
	teq r1, r2	@ 080A123C
	bne .L_080A1238	@ 080A1240
	ldr r0, .Lp_sndMaster_5	@ 080A1244
	mov r1, #0xff	@ 080A1248
	str r1, [r0]	@ 080A124C
	ldrh r0, [r3, #IO_SOUNDBIAS]	@ 080A1250
	orr r0, r0, #0	@ 080A1254
	strh r0, [r3, #IO_SOUNDBIAS]	@ 080A1258
	mov r0, #0	@ 080A125C
	strh r0, [r3, #IO_DMA1CNT_H]	@ 080A1260
	mov r0, #0	@ 080A1264
	strh r0, [r3, #IO_DMA2CNT_H]	@ 080A1268
	ldr r0, .Lp_sndMixA_4	@ 080A126C
	str r0, [r3, #IO_DMA1SAD]	@ 080A1270  DMA1SAD
	ldr r0, .Lp_sndMixB_4	@ 080A1274
	str r0, [r3, #IO_DMA2SAD]	@ 080A1278  DMA2SAD
	ldr r0, .Lp_REG_FIFO_A	@ 080A127C
	str r0, [r3, #IO_DMA1DAD]	@ 080A1280  DMA1DAD
	ldr r0, .Lp_REG_FIFO_B	@ 080A1284
	str r0, [r3, #IO_DMA2DAD]	@ 080A1288  DMA2DAD
	ldr r1, .Lp_sndTimerReload	@ 080A128C
	ldr r0, [r1]	@ 080A1290
	strh r0, [r3, #IO_TM0CNT_L]	@ 080A1294  TM0CNT_L = 0xFC00
	bx lr	@ 080A1298

@ ================================================================
@ void sndFrame(void)  once per frame.
@   for (n = 0; n < 13; n++)  -- same per-track update as Magical Vacation (wait / envelope /
@                                 PCM slide for n >= 8).  Track = 0x38 bytes, see som_sound.inc.
@   then fade-in tick (master +0x18) or fade-out tick (master +2), then one queued id.
@   Tracks 0-3 PSG music, 4-7 PSG SE (mute 0-3), 8-12 PCM (voice = track & 7).
@   r7 = track index, r1 = Track*, r6 = REG_SOUND1CNT_L (I/O base) in the parser.
@ ================================================================
	.global sndFrame
	.type sndFrame, %function
sndFrame:
	push {r4, r5, r6, r7}	@ 080A129C
	mov r7, #0	@ 080A12A0
	ldr r1, .Lp_sndTracks_3	@ 080A12A4
.Lframe_trackLoop:
	ldrb r2, [r1]	@ 080A12A8
	tst r2, #1	@ 080A12AC
	beq .Lframe_nextTrack	@ 080A12B0
	ldrb r2, [r1, #TRK_WAIT]	@ 080A12B4
	sub r2, r2, #1	@ 080A12B8
	cmp r2, #0	@ 080A12BC
	beq .Lparse	@ 080A12C0
	strb r2, [r1, #TRK_WAIT]	@ 080A12C4
	ldrb r2, [r1, #TRK_ENVWAIT]	@ 080A12C8
	teq r2, #0	@ 080A12CC
	beq .L_080A12E4	@ 080A12D0
	sub r2, r2, #1	@ 080A12D4
	teq r2, #0	@ 080A12D8
	beq .Lenv_step	@ 080A12DC
	strb r2, [r1, #TRK_ENVWAIT]	@ 080A12E0
.L_080A12E4:
	tst r7, #8	@ 080A12E4
	beq .Lframe_nextTrack	@ 080A12E8
	ldrb r2, [r1, #TRK_DUTY]	@ 080A12EC
	teq r2, #0	@ 080A12F0
	beq .Lframe_nextTrack	@ 080A12F4
	sub r2, r2, #1	@ 080A12F8
	teq r2, #0	@ 080A12FC
	beq .Lpcm_slide	@ 080A1300
	strb r2, [r1, #TRK_DUTY]	@ 080A1304
.Lframe_nextTrack:
	add r1, r1, #0x38	@ 080A1308
	add r7, r7, #1	@ 080A130C
	teq r7, #0xd	@ 080A1310  13 tracks updated
	bne .Lframe_trackLoop	@ 080A1314
	ldr r0, .Lp_sndMaster_6	@ 080A1318
	ldrb r1, [r0, #MST_INFRAMES]	@ 080A131C
	teq r1, #0	@ 080A1320
	bne .LfadeIn_tick	@ 080A1324
	ldrh r1, [r0, #MST_OUTFRAMES]	@ 080A1328
	teq r1, #0	@ 080A132C
	bne .LfadeOut_tick	@ 080A1330
.Lframe_queue:
	ldr r2, .Lp_sndQueueRead_3	@ 080A1334
	ldrb r0, [r2], #1	@ 080A1338
	ldrb r1, [r2], #1	@ 080A133C
	ldrh r3, [r2, r0]	@ 080A1340  id = queue[r]
	teq r3, #0	@ 080A1344  non-zero -> start
	movne r1, r3	@ 080A1348
	bne .Lqueue_start	@ 080A134C
	sub r2, r2, #2	@ 080A1350
	mov r3, #0	@ 080A1354
	teq r0, r1	@ 080A1358
	strne r3, [r2], #4	@ 080A135C
	pop {r4, r5, r6, r7}	@ 080A1360
	bx lr	@ 080A1364
.LfadeIn_tick:
	sub r1, r1, #1	@ 080A1368
	strb r1, [r0, #MST_INFRAMES]	@ 080A136C
	teq r1, #0	@ 080A1370
	beq .LfadeIn_done	@ 080A1374
	ldrh r1, [r0, #MST_INACC]	@ 080A1378
	sub r1, r1, #0x100	@ 080A137C
	tst r1, #0xff00	@ 080A1380
	strhne r1, [r0, #MST_INACC]	@ 080A1384
	bne .Lframe_queue	@ 080A1388
	ldrh r2, [r0, #MST_INPERIOD]	@ 080A138C
	add r1, r1, r2	@ 080A1390
	strh r1, [r0, #MST_INACC]	@ 080A1394
	ldrb r1, [r0]	@ 080A1398
	ldrb r2, [r0, #MST_STEP]	@ 080A139C
	add r1, r1, r2	@ 080A13A0  fade-in: volume += step (clamp 0xFF)
	tst r1, #0xff00	@ 080A13A4
	movne r1, #0xff	@ 080A13A8
	strb r1, [r0]	@ 080A13AC
	lsr r2, r1, #5	@ 080A13B0
	lsl r3, r2, #4	@ 080A13B4
	add r2, r3, r2	@ 080A13B8
	ldr r4, .Lp_sndSoundCntL_2	@ 080A13BC
	ldrh r3, [r4]	@ 080A13C0
	and r3, r3, #0xff00	@ 080A13C4
	orr r3, r3, r2	@ 080A13C8
	strh r3, [r4]	@ 080A13CC
	ldr r6, .Lp_REG_SOUND1CNT_L_2	@ 080A13D0
	strh r3, [r6, #0x20]	@ 080A13D4
	ldr r0, .Lp_sndTracks_0x1C0	@ 080A13D8
	ldr r6, .Lp_sndVoices_6	@ 080A13DC
.LfadeIn_voiceLoop:
	ldrb r2, [r0]	@ 080A13E0
	tst r2, #1	@ 080A13E4
	beq .L_080A1420	@ 080A13E8
	ldrb r3, [r0, #TRK_SWEEP]	@ 080A13EC
	add r4, r1, #1	@ 080A13F0
	mul r5, r4, r3	@ 080A13F4
	ldrb r4, [r0, #TRK_PANBITS]	@ 080A13F8
	add r4, r4, #1	@ 080A13FC
	mul r7, r4, r5	@ 080A1400
	lsr r7, r7, #0x10	@ 080A1404
	strb r7, [r6, #2]	@ 080A1408
	ldrb r4, [r0, #TRK_PANMASK]	@ 080A140C
	add r4, r4, #1	@ 080A1410
	mul r7, r4, r5	@ 080A1414
	lsr r7, r7, #0x10	@ 080A1418
	strb r7, [r6, #3]	@ 080A141C
.L_080A1420:
	add r6, r6, #0x10	@ 080A1420
	add r0, r0, #0x38	@ 080A1424
	ldr r5, .Lp_sndMixA_5	@ 080A1428
	teq r6, r5	@ 080A142C
	bne .LfadeIn_voiceLoop	@ 080A1430
	b .Lframe_queue	@ 080A1434
.LfadeIn_done:
	mov r2, #0xff	@ 080A1438
	strb r2, [r1]	@ 080A143C
	mov r2, #0x77	@ 080A1440
	ldr r4, .Lp_sndSoundCntL_3	@ 080A1444
	ldrh r3, [r4]	@ 080A1448
	and r3, r3, #0xff00	@ 080A144C
	orr r3, r3, r2	@ 080A1450
	strh r3, [r4]	@ 080A1454
	ldr r6, .Lp_REG_SOUND1CNT_L_2	@ 080A1458
	strh r3, [r6, #0x20]	@ 080A145C
	b .Lframe_queue	@ 080A1460
.LfadeOut_tick:
	sub r1, r1, #1	@ 080A1464
	strh r1, [r0, #MST_OUTFRAMES]	@ 080A1468
	teq r1, #0	@ 080A146C
	beq .LfadeOut_done	@ 080A1470
	ldrh r1, [r0, #MST_OUTACC]	@ 080A1474
	sub r1, r1, #0x100	@ 080A1478
	tst r1, #0xff00	@ 080A147C
	strhne r1, [r0, #MST_OUTACC]	@ 080A1480
	bne .Lframe_queue	@ 080A1484
	ldrh r2, [r0, #MST_OUTPERIOD]	@ 080A1488
	add r1, r1, r2	@ 080A148C
	strh r1, [r0, #MST_OUTACC]	@ 080A1490
	ldrb r1, [r0]	@ 080A1494
	ldrb r2, [r0, #MST_STEP]	@ 080A1498
	cmp r1, r2	@ 080A149C
	movmi r1, #0	@ 080A14A0
	subpl r1, r1, r2	@ 080A14A4
	strb r1, [r0]	@ 080A14A8  fade-out: volume -= step (floor 0)
	lsr r2, r1, #5	@ 080A14AC
	lsl r3, r2, #4	@ 080A14B0
	add r2, r3, r2	@ 080A14B4
	ldr r4, .Lp_sndSoundCntL_4	@ 080A14B8
	ldrh r3, [r4]	@ 080A14BC
	and r3, r3, #0xff00	@ 080A14C0
	orr r3, r3, r2	@ 080A14C4
	strh r3, [r4]	@ 080A14C8
	ldr r6, .Lp_REG_SOUND1CNT_L_2	@ 080A14CC
	strh r3, [r6, #0x20]	@ 080A14D0
	ldr r0, .Lp_sndTracks_0x1C0_2	@ 080A14D4
	ldr r6, .Lp_sndVoices_7	@ 080A14D8
.LfadeOut_voiceLoop:
	ldrb r2, [r0]	@ 080A14DC
	tst r2, #1	@ 080A14E0
	beq .L_080A151C	@ 080A14E4
	ldrb r3, [r0, #TRK_SWEEP]	@ 080A14E8
	add r4, r1, #1	@ 080A14EC
	mul r5, r4, r3	@ 080A14F0
	ldrb r4, [r0, #TRK_PANBITS]	@ 080A14F4
	add r4, r4, #1	@ 080A14F8
	mul r7, r4, r5	@ 080A14FC
	lsr r7, r7, #0x10	@ 080A1500
	strb r7, [r6, #2]	@ 080A1504
	ldrb r4, [r0, #TRK_PANMASK]	@ 080A1508
	add r4, r4, #1	@ 080A150C
	mul r7, r4, r5	@ 080A1510
	lsr r7, r7, #0x10	@ 080A1514
	strb r7, [r6, #3]	@ 080A1518
.L_080A151C:
	add r6, r6, #0x10	@ 080A151C
	add r0, r0, #0x38	@ 080A1520
	ldr r5, .Lp_sndMixA_6	@ 080A1524
	teq r6, r5	@ 080A1528
	bne .LfadeOut_voiceLoop	@ 080A152C
	b .Lframe_queue	@ 080A1530
.LfadeOut_done:
	mov r1, #0	@ 080A1534
	strb r1, [r0]	@ 080A1538
	ldr r3, .Lp_REG_SOUND1CNT_L_2	@ 080A153C
	mov r0, #0	@ 080A1540
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 080A1544
	mov r0, #0x8f	@ 080A1548
	strh r0, [r3, #IO_SOUNDCNT_X]	@ 080A154C
	mov r0, #0	@ 080A1550
	strh r0, [r3, #IO_TM0CNT_H]	@ 080A1554
	ldr r0, .Lp_0x00008802	@ 080A1558
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 080A155C
	ldr r0, .Lp_0x0000210E	@ 080A1560
	strh r0, [r3, #IO_SOUNDCNT_H]	@ 080A1564
	mov r0, #0x77	@ 080A1568
	strh r0, [r3, #IO_SOUNDCNT_L]	@ 080A156C
	ldr r1, .Lp_sndSoundCntL_5	@ 080A1570
	strh r0, [r1]	@ 080A1574
	ldr r1, .Lp_sndTracks_4	@ 080A1578
	ldr r2, .Lp_sndQueueRead_4	@ 080A157C
.LfadeOut_pauseLoop:
	ldrb r0, [r1]	@ 080A1580
	tst r0, #0x81	@ 080A1584  active/paused -> paused (0x80)
	movne r0, #0x80	@ 080A1588
	moveq r0, #0	@ 080A158C
	strb r0, [r1], #0x38	@ 080A1590
	teq r1, r2	@ 080A1594
	bne .LfadeOut_pauseLoop	@ 080A1598
	strh r0, [r1]	@ 080A159C
	str r0, [r1, #2]	@ 080A15A0
	str r0, [r1, #6]	@ 080A15A4
	ldr r0, .Lp_sndMaster_7	@ 080A15A8
	mov r1, #0xff	@ 080A15AC
	str r1, [r0]	@ 080A15B0
	b .Lframe_queue	@ 080A15B4

@ ---- ids 0x3B / 0x3D: only start if the noise channel is free:
@   NR42 volume == 0, or track 3 inactive, or track 3 has fewer than 3 frames left.
.Lqueue_noiseGate:
	ldr r2, .Lp_psgEnvRegTable	@ 080A15B8
	ldr r2, [r2, #0xc]	@ 080A15BC
	ldrh r3, [r2]	@ 080A15C0
	tst r3, #0xf000	@ 080A15C4
	bne .Lframe_return	@ 080A15C8
	ldr r2, .Lp_sndTracks_5	@ 080A15CC
	ldrb r3, [r2, #0xa8]	@ 080A15D0
	tst r3, #0x7f	@ 080A15D4
	beq .L_080A15E8	@ 080A15D8
	ldrb r3, [r2, #0xa9]	@ 080A15DC
	cmp r3, #3	@ 080A15E0
	bmi .Lframe_return	@ 080A15E4
.L_080A15E8:
	ldr r2, .Lp_seqSongTable	@ 080A15E8
	ldr r0, [r2, r1, lsl #2]	@ 080A15EC
	b .Lstart_trackLoop	@ 080A15F0
.Lframe_return:
	pop {r4, r5, r6, r7}	@ 080A15F4
	bx lr	@ 080A15F8

@ ---- start sound id (header {u32 slot, u8 *seq, u8 **patterns} ... 0xFF), as in MV.
@   Only slots 4-7 mute their music slot; PCM tracks are never auto-muted (see E8/E9).
.Lqueue_start:
	mov r3, #0	@ 080A15FC
	strh r3, [r2, r0]	@ 080A1600
	add r0, r0, #2	@ 080A1604
	and r0, r0, #0xf	@ 080A1608
	ldr r2, .Lp_sndQueueRead_5	@ 080A160C
	strb r0, [r2]	@ 080A1610
	teq r1, #0x3b	@ 080A1614  id 0x3B
	beq .Lqueue_noiseGate	@ 080A1618
	teq r1, #0x3d	@ 080A161C  id 0x3D
	beq .Lqueue_noiseGate	@ 080A1620
	ldr r2, .Lp_seqSongTable_2	@ 080A1624
	ldr r0, [r2, r1, lsl #2]	@ 080A1628
.Lstart_trackLoop:
	ldr r1, [r0], #4	@ 080A162C
	cmp r1, #0xff	@ 080A1630
	beq .Lstart_done	@ 080A1634
	mov r3, #0x38	@ 080A1638
	ldr r2, .Lp_sndTracks_6	@ 080A163C
	mla r2, r1, r3, r2	@ 080A1640
	ldrb r3, [r2]	@ 080A1644
	orr r3, r3, #1	@ 080A1648
	strb r3, [r2]	@ 080A164C
	ldr r3, [r0], #4	@ 080A1650
	ldr r4, [r0], #4	@ 080A1654
	str r3, [r2, #TRK_PTR]	@ 080A1658
	str r4, [r2, #TRK_PATTERNS]	@ 080A165C
	mov r3, #0	@ 080A1660
	str r3, [r2, #TRK_DUTY]	@ 080A1664
	str r3, [r2, #TRK_LEVEL]	@ 080A1668
	str r3, [r2, #TRK_TRANSP]	@ 080A166C
	mov r3, #1	@ 080A1670
	strb r3, [r2, #TRK_WAIT]	@ 080A1674
	ldr r3, .Lp_panBitsTable	@ 080A1678
	ldrb r4, [r3, r1]!	@ 080A167C
	strb r4, [r2, #TRK_PANBITS]	@ 080A1680
	ldrb r4, [r3, #0xc]	@ 080A1684
	strb r4, [r2, #TRK_PANMASK]	@ 080A1688
	cmp r1, #4	@ 080A168C
	bmi .Lstart_trackLoop	@ 080A1690
	cmp r1, #8	@ 080A1694  slots 4-7 only
	bpl .Lstart_trackLoop	@ 080A1698
	mov r3, #0xe0	@ 080A169C
	sub r2, r2, r3	@ 080A16A0
	ldrb r1, [r2]	@ 080A16A4
	orr r1, r1, #2	@ 080A16A8
	strb r1, [r2]	@ 080A16AC
	b .Lstart_trackLoop	@ 080A16B0
.Lstart_done:
	pop {r4, r5, r6, r7}	@ 080A16B4
	bx lr	@ 080A16B8

@ ---- envelope step (PSG): {frames, nrx2} pairs, as in MV.
.Lenv_step:
	tst r7, #8	@ 080A16BC
	bne .Lenv_stepPcm	@ 080A16C0
	ldr r2, [r1, #TRK_ENVPOS]	@ 080A16C4
	ldrb r0, [r2], #1	@ 080A16C8
	strb r0, [r1, #TRK_ENVWAIT]	@ 080A16CC
	ldrb r3, [r2], #1	@ 080A16D0
	strb r3, [r1, #TRK_LEVEL]	@ 080A16D4
	str r2, [r1, #TRK_ENVPOS]	@ 080A16D8
	ldrb r2, [r1, #TRK_VOLUME]	@ 080A16DC
	sub r3, r3, r2	@ 080A16E0
	tst r3, #0xff0000	@ 080A16E4
	movne r3, #0	@ 080A16E8
	ldrb r2, [r1, #TRK_DUTY]	@ 080A16EC
	add r3, r2, r3, lsl #8	@ 080A16F0
	strh r3, [r1, #TRK_ENVREG]	@ 080A16F4
	ldrb r2, [r1]	@ 080A16F8
	tst r2, #2	@ 080A16FC
	bne .L_080A1724	@ 080A1700
	ldr r2, .Lp_psgEnvRegTable_2	@ 080A1704
	ldr r2, [r2, r7, lsl #2]	@ 080A1708
	strh r3, [r2]	@ 080A170C
	ldr r2, .Lp_psgCtrlRegTable	@ 080A1710
	ldr r2, [r2, r7, lsl #2]	@ 080A1714
	ldrh r3, [r1, #TRK_FREQ]	@ 080A1718
	orr r3, r3, #0x8000	@ 080A171C
	strh r3, [r2]	@ 080A1720
.L_080A1724:
	b .Lframe_nextTrack	@ 080A1724

@ ---- envelope step (PCM): {frames, slide, level}; slide period is fixed at 1 frame,
@   slide bit7 = down, bits0-6 = amount. Voice volumes recomputed (see note-on).
.Lenv_stepPcm:
	ldr r2, [r1, #TRK_ENVPOS]	@ 080A1728
	ldrb r3, [r2], #1	@ 080A172C
	strb r3, [r1, #TRK_ENVWAIT]	@ 080A1730
	mov r3, #1	@ 080A1734  slide period = 1
	strb r3, [r1, #TRK_DUTY]	@ 080A1738
	strb r3, [r1, #TRK_SLIDEPER]	@ 080A173C
	ldrb r3, [r2], #1	@ 080A1740
	strb r3, [r1, #TRK_SLIDE]	@ 080A1744  slide
	ldrb r3, [r2], #1	@ 080A1748
	strb r3, [r1, #TRK_LEVEL]	@ 080A174C  level
	str r2, [r1, #TRK_ENVPOS]	@ 080A1750
	ldrb r2, [r1, #TRK_VOLUME]	@ 080A1754
	add r2, r2, #1	@ 080A1758
	mul r4, r2, r3	@ 080A175C
	lsr r2, r4, #8	@ 080A1760
	strb r2, [r1, #TRK_SWEEP]	@ 080A1764
	ldr r3, .Lp_sndMaster_8	@ 080A1768
	ldrb r4, [r3]	@ 080A176C
	add r4, r4, #1	@ 080A1770
	mul r5, r2, r4	@ 080A1774
	lsr r2, r5, #8	@ 080A1778
	and r3, r7, #7	@ 080A177C
	ldr r4, .Lp_sndVoices_8	@ 080A1780
	add r4, r4, r3, lsl #4	@ 080A1784
	ldrb r3, [r1, #TRK_PANBITS]	@ 080A1788
	add r3, r3, #1	@ 080A178C
	mul r5, r3, r2	@ 080A1790
	lsr r5, r5, #8	@ 080A1794
	strb r5, [r4, #2]	@ 080A1798
	ldrb r3, [r1, #TRK_PANMASK]	@ 080A179C
	add r3, r3, #1	@ 080A17A0
	mul r5, r3, r2	@ 080A17A4
	lsr r5, r5, #8	@ 080A17A8
	strb r5, [r4, #3]	@ 080A17AC
	b .Lframe_nextTrack	@ 080A17B0
.Lpcm_slide:
	ldrb r2, [r1, #TRK_SLIDEPER]	@ 080A17B4
	strb r2, [r1, #TRK_DUTY]	@ 080A17B8
	ldrb r3, [r1, #TRK_SLIDE]	@ 080A17BC
	teq r3, #0	@ 080A17C0
	beq .Lpcm_slideDone	@ 080A17C4
	ldrb r2, [r1, #TRK_LEVEL]	@ 080A17C8
	tst r3, #0x80	@ 080A17CC
	and r3, r3, #0x7f	@ 080A17D0
	addeq r4, r2, r3	@ 080A17D4
	subne r4, r2, r3	@ 080A17D8
	tst r4, #0xff000000	@ 080A17DC
	movne r4, #0	@ 080A17E0
	bne .L_080A17F0	@ 080A17E4
	tst r4, #0xff00	@ 080A17E8
	movne r4, #0xff	@ 080A17EC
.L_080A17F0:
	strb r4, [r1, #TRK_LEVEL]	@ 080A17F0
	ldrb r2, [r1, #TRK_VOLUME]	@ 080A17F4
	add r2, r2, #1	@ 080A17F8
	mul r3, r2, r4	@ 080A17FC
	lsr r2, r3, #8	@ 080A1800
	strb r2, [r1, #TRK_SWEEP]	@ 080A1804
	ldr r3, .Lp_sndMaster_9	@ 080A1808
	ldrb r4, [r3]	@ 080A180C
	add r4, r4, #1	@ 080A1810
	mul r5, r2, r4	@ 080A1814
	lsr r2, r5, #8	@ 080A1818
	and r3, r7, #7	@ 080A181C
	ldr r4, .Lp_sndVoices_9	@ 080A1820
	add r4, r4, r3, lsl #4	@ 080A1824
	ldrb r3, [r1, #TRK_PANBITS]	@ 080A1828
	add r3, r3, #1	@ 080A182C
	mul r5, r3, r2	@ 080A1830
	lsr r5, r5, #8	@ 080A1834
	strb r5, [r4, #2]	@ 080A1838
	ldrb r3, [r1, #TRK_PANMASK]	@ 080A183C
	add r3, r3, #1	@ 080A1840
	mul r5, r3, r2	@ 080A1844
	lsr r5, r5, #8	@ 080A1848
	strb r5, [r4, #3]	@ 080A184C
.Lpcm_slideDone:
	b .Lframe_nextTrack	@ 080A1850

@ ================================================================
@ Sequence parser.  00-7F note, 80-DF length = lengthTable[(b & 0x7F) + 16*t->tempoRow],
@ E0-FF command via seqCmdTable[b & 0x1F].
@ ================================================================
.Lparse:
	ldr r6, .Lp_REG_SOUND1CNT_L_2	@ 080A1854
	ldr r2, [r1, #TRK_PTR]	@ 080A1858
.Lparse_next:
	ldrb r0, [r2], #1	@ 080A185C
	cmp r0, #0x80	@ 080A1860
	bmi .Lnote	@ 080A1864
	cmp r0, #0xe0	@ 080A1868
	bmi .Lparse_length	@ 080A186C
	and r0, r0, #0x1f	@ 080A1870
	ldr r3, .Lp_seqCmdTable	@ 080A1874
	ldr pc, [r3, r0, lsl #2]	@ 080A1878
.Lparse_length:
	and r0, r0, #0x7f	@ 080A187C
	ldrb r4, [r1, #TRK_TEMPOROW]	@ 080A1880
	lsl r4, r4, #4	@ 080A1884  + 16 * tempoRow
	add r0, r0, r4	@ 080A1888
	ldr r3, .Lp_lengthTable	@ 080A188C
	ldrb r0, [r3, r0]	@ 080A1890
	strb r0, [r1, #TRK_LENGTH]	@ 080A1894
	b .Lparse_next	@ 080A1898
.Lnote:
	str r2, [r1, #TRK_PTR]	@ 080A189C
	cmp r7, #3	@ 080A18A0  noise track 3
	beq .Lnote_noise	@ 080A18A4
	cmp r7, #7	@ 080A18A8  noise track 7
	beq .Lnote_noise	@ 080A18AC
	ldrb r3, [r1, #TRK_TRANSP]	@ 080A18B0
	tst r3, #0x80	@ 080A18B4
	addeq r0, r0, r3	@ 080A18B8
	movne r2, #0x100	@ 080A18BC
	subne r2, r2, r3	@ 080A18C0
	subne r0, r0, r2	@ 080A18C4
	and r0, r0, #0x7f	@ 080A18C8
	cmp r7, #8	@ 080A18CC  PCM?
	bpl .Lnote_pcm	@ 080A18D0
	ldr r2, .Lp_psgFreqTable	@ 080A18D4
	lsl r0, r0, #1	@ 080A18D8
	ldrh r5, [r2, r0]	@ 080A18DC
	ldrb r3, [r1, #TRK_DETUNE]	@ 080A18E0
	add r5, r5, r3	@ 080A18E4
.Lnote_psgStore:
	strh r5, [r1, #TRK_FREQ]	@ 080A18E8
	ldrb r2, [r1, #TRK_LENGTH]	@ 080A18EC
	strb r2, [r1, #TRK_WAIT]	@ 080A18F0
	ldr r2, [r1, #TRK_ENV]	@ 080A18F4
	ldrb r3, [r2], #1	@ 080A18F8
	strb r3, [r1, #TRK_ENVWAIT]	@ 080A18FC
	ldrb r3, [r2], #1	@ 080A1900
	str r2, [r1, #TRK_ENVPOS]	@ 080A1904
	ldrb r2, [r1, #TRK_VOLUME]	@ 080A1908
	cmp r3, r2	@ 080A190C
	movmi r3, #8	@ 080A1910
	bmi .L_080A191C	@ 080A1914
	sub r3, r3, r2	@ 080A1918
.L_080A191C:
	ldrb r2, [r1, #TRK_DUTY]	@ 080A191C
	add r3, r2, r3, lsl #8	@ 080A1920
	strh r3, [r1, #TRK_ENVREG]	@ 080A1924
	ldrb r2, [r1]	@ 080A1928
	tst r2, #2	@ 080A192C
	bne .L_080A196C	@ 080A1930
	teq r7, #0	@ 080A1934
	beq .L_080A1944	@ 080A1938
	teq r7, #4	@ 080A193C
	bne .L_080A194C	@ 080A1940
.L_080A1944:
	ldrbeq r0, [r1, #TRK_SWEEP]	@ 080A1944
	strheq r0, [r6]	@ 080A1948
.L_080A194C:
	ldr r2, .Lp_psgEnvRegTable_3	@ 080A194C
	ldr r2, [r2, r7, lsl #2]	@ 080A1950
	strh r3, [r2]	@ 080A1954
	ldr r2, .Lp_psgCtrlRegTable_2	@ 080A1958
	ldr r2, [r2, r7, lsl #2]	@ 080A195C
	orr r5, r5, #0x8000	@ 080A1960
	strh r5, [r2]	@ 080A1964  freq | trigger
	strh r5, [r2]	@ 080A1968  (written twice)
.L_080A196C:
	b .Lframe_nextTrack	@ 080A196C

@ ---- PCM note-on.  n = (note + transpose) & 0x7F; n & 0xC0 -> 47.
@   n <  12: mode 4 (x8), idx n;      n < 24: mode 2 (x4), idx n-12;
@   n <  36: mode 1 (x2), idx n-24;   else  : mode 0 (x1), idx n-36.
@   hdr = t->inst[idx]  (one pre-pitched sample per semitone; output is a fixed 16384 Hz)
@   voice = {mode, mode, volA, volB, start, end, loop}
@   t->pcmVol = (volume+1)*level >> 8
@   volA = ((master+1)*pcmVol * (t->volA+1)) >> 16,  volB likewise with t->volB.
@   If DMA1 is not running, clear the mix buffers, set up DMA1/2 and IE, start DMA.
@   TM0CNT_H = 0x80.
.Lnote_pcm:
	tst r0, #0xc0	@ 080A1970
	movne r0, #0x2f	@ 080A1974  n >= 64 -> 47
	cmp r0, #0xc	@ 080A1978
	movmi r3, r0	@ 080A197C
	movmi r4, #4	@ 080A1980
	bmi .Lnote_pcmVoice	@ 080A1984
	cmp r0, #0x18	@ 080A1988
	submi r3, r0, #0xc	@ 080A198C
	movmi r4, #2	@ 080A1990
	bmi .Lnote_pcmVoice	@ 080A1994
	cmp r0, #0x24	@ 080A1998
	submi r3, r0, #0x18	@ 080A199C
	movmi r4, #1	@ 080A19A0
	bmi .Lnote_pcmVoice	@ 080A19A4
	sub r3, r0, #0x24	@ 080A19A8
	mov r4, #0	@ 080A19AC
.Lnote_pcmVoice:
	ldr r0, .Lp_sndVoices_10	@ 080A19B0
	and r5, r7, #7	@ 080A19B4
	add r0, r0, r5, lsl #4	@ 080A19B8
	strb r4, [r0]	@ 080A19BC
	strb r4, [r0, #VOI_MODE2]	@ 080A19C0
	lsl r3, r3, #2	@ 080A19C4
	ldr r4, [r1, #TRK_INST]	@ 080A19C8
	ldr r4, [r4, r3]	@ 080A19CC  hdr = inst[idx]
	ldr r3, [r4], #4	@ 080A19D0
	str r3, [r0, #VOI_CUR]	@ 080A19D4
	ldr r3, [r4], #4	@ 080A19D8
	str r3, [r0, #VOI_END]	@ 080A19DC
	ldr r3, [r4]	@ 080A19E0
	str r3, [r0, #VOI_LOOP]	@ 080A19E4
	ldrb r3, [r1, #TRK_LENGTH]	@ 080A19E8
	strb r3, [r1, #TRK_WAIT]	@ 080A19EC
	ldr r2, [r1, #TRK_ENV]	@ 080A19F0
	ldrb r3, [r2], #1	@ 080A19F4
	strb r3, [r1, #TRK_ENVWAIT]	@ 080A19F8
	mov r3, #1	@ 080A19FC
	strb r3, [r1, #TRK_DUTY]	@ 080A1A00
	strb r3, [r1, #TRK_SLIDEPER]	@ 080A1A04
	ldrb r3, [r2], #1	@ 080A1A08
	strb r3, [r1, #TRK_SLIDE]	@ 080A1A0C
	ldrb r3, [r2], #1	@ 080A1A10
	strb r3, [r1, #TRK_LEVEL]	@ 080A1A14
	str r2, [r1, #TRK_ENVPOS]	@ 080A1A18
	ldrb r2, [r1, #TRK_VOLUME]	@ 080A1A1C
	add r2, r2, #1	@ 080A1A20
	mul r4, r2, r3	@ 080A1A24
	lsr r2, r4, #8	@ 080A1A28
	strb r2, [r1, #TRK_SWEEP]	@ 080A1A2C
	ldr r3, .Lp_sndMaster_10	@ 080A1A30
	ldrb r4, [r3]	@ 080A1A34
	add r4, r4, #1	@ 080A1A38
	mul r5, r2, r4	@ 080A1A3C
	ldrb r4, [r1, #TRK_PANBITS]	@ 080A1A40
	add r4, r4, #1	@ 080A1A44
	mul r2, r5, r4	@ 080A1A48
	lsr r3, r2, #0x10	@ 080A1A4C
	strb r3, [r0, #VOI_VOLA]	@ 080A1A50  voice volA
	ldrb r4, [r1, #TRK_PANMASK]	@ 080A1A54
	add r4, r4, #1	@ 080A1A58
	mul r2, r5, r4	@ 080A1A5C
	lsr r3, r2, #0x10	@ 080A1A60
	strb r3, [r0, #VOI_VOLB]	@ 080A1A64  voice volB
	ldrh r3, [r6, #IO_DMA1CNT_H]	@ 080A1A68
	tst r3, #0x400	@ 080A1A6C  DMA1 running?
	bne .Lnote_pcmTimer	@ 080A1A70
	mov r3, #0	@ 080A1A74
	ldr r0, .Lp_sndMixA_7	@ 080A1A78
	str r3, [r0], #4	@ 080A1A7C
	str r3, [r0], #4	@ 080A1A80
	str r3, [r0], #4	@ 080A1A84
	str r3, [r0], #4	@ 080A1A88
	str r3, [r0], #4	@ 080A1A8C
	str r3, [r0], #4	@ 080A1A90
	str r3, [r0], #4	@ 080A1A94
	str r3, [r0], #4	@ 080A1A98
	mov r0, #0	@ 080A1A9C
	strh r0, [r6, #IO_DMA1CNT_H]	@ 080A1AA0
	mov r0, #0	@ 080A1AA4
	strh r0, [r6, #IO_DMA2CNT_H]	@ 080A1AA8
	ldr r0, .Lp_sndMixA_8	@ 080A1AAC
	str r0, [r6, #IO_DMA1SAD]	@ 080A1AB0
	ldr r0, .Lp_sndMixB_5	@ 080A1AB4
	str r0, [r6, #IO_DMA2SAD]	@ 080A1AB8
	ldr r0, .Lp_REG_FIFO_A	@ 080A1ABC
	str r0, [r6, #IO_DMA1DAD]	@ 080A1AC0
	ldr r0, .Lp_REG_FIFO_B	@ 080A1AC4
	str r0, [r6, #IO_DMA2DAD]	@ 080A1AC8
	ldr r3, .Lp_REG_IE_3	@ 080A1ACC
	ldrh r4, [r3]	@ 080A1AD0
	orr r5, r4, #0x600	@ 080A1AD4
	strh r5, [r3]	@ 080A1AD8
	mov r0, #0xf600	@ 080A1ADC
	add r0, r0, #0x40	@ 080A1AE0
	strh r0, [r6, #IO_DMA1CNT_H]	@ 080A1AE4
	mov r0, #0xf600	@ 080A1AE8
	add r0, r0, #0x40	@ 080A1AEC
	strh r0, [r6, #IO_DMA2CNT_H]	@ 080A1AF0
.Lnote_pcmTimer:
	mov r0, #0x80	@ 080A1AF4
	strh r0, [r6, #IO_TM0CNT_H]	@ 080A1AF8  TM0CNT_H = 0x80
	b .Lframe_nextTrack	@ 080A1AFC
.Lnote_noise:
	lsl r5, r0, #4	@ 080A1B00
	add r5, r5, r0, lsr #4	@ 080A1B04  NR43 = note<<4 | note>>4
	and r5, r5, #0xff	@ 080A1B08
	b .Lnote_psgStore	@ 080A1B0C

@ seqCmdTable[32] for bytes E0-FF.
seqCmdTable:
	.align 2
	.word cmdEnvJump	@ 080A1B10  cmd 0xE0
	.word cmdInstrument	@ 080A1B14  cmd 0xE1
	.word cmdMixMode	@ 080A1B18  cmd 0xE2
	.word cmdResume	@ 080A1B1C  cmd 0xE3
	.word cmdNop	@ 080A1B20  cmd 0xE4
	.word cmdNop	@ 080A1B24  cmd 0xE5
	.word cmdNop	@ 080A1B28  cmd 0xE6
	.word cmdNop	@ 080A1B2C  cmd 0xE7
	.word cmdUnmuteMusic	@ 080A1B30  cmd 0xE8
	.word cmdMuteMusic	@ 080A1B34  cmd 0xE9
	.word cmdPcmPan	@ 080A1B38  cmd 0xEA
	.word cmdNop	@ 080A1B3C  cmd 0xEB
	.word cmdRestPcm	@ 080A1B40  cmd 0xEC
	.word cmdRestPsg	@ 080A1B44  cmd 0xED
	.word cmdTempoRow	@ 080A1B48  cmd 0xEE
	.word cmdNop	@ 080A1B4C  cmd 0xEF
	.word cmdEnvelope	@ 080A1B50  cmd 0xF0
	.word cmdDuty	@ 080A1B54  cmd 0xF1
	.word cmdVolume	@ 080A1B58  cmd 0xF2
	.word cmdTranspose	@ 080A1B5C  cmd 0xF3
	.word cmdLoopStart	@ 080A1B60  cmd 0xF4
	.word cmdLoopEnd	@ 080A1B64  cmd 0xF5
	.word cmdCall	@ 080A1B68  cmd 0xF6
	.word cmdReturn	@ 080A1B6C  cmd 0xF7
	.word cmdJump	@ 080A1B70  cmd 0xF8
	.word cmdDetune	@ 080A1B74  cmd 0xF9
	.word cmdSweep	@ 080A1B78  cmd 0xFA
	.word cmdSweepOff	@ 080A1B7C  cmd 0xFB
	.word cmdWave	@ 080A1B80  cmd 0xFC
	.word cmdPan	@ 080A1B84  cmd 0xFD
	.word cmdTie	@ 080A1B88  cmd 0xFE
	.word cmdEnd	@ 080A1B8C  cmd 0xFF

@ ---- commands. r1 = Track*, r2 = read pointer, r6 = I/O base, r7 = track.
cmdNop:
	b .Lparse_next	@ 080A1B90
cmdEnvJump:
	ldrb r0, [r2], #1	@ 080A1B94
	ldr r3, .Lp_envelopeTable	@ 080A1B98
	add r3, r3, r0, lsl #2	@ 080A1B9C
	ldr r0, [r3]	@ 080A1BA0
	str r0, [r1, #TRK_ENVPOS]	@ 080A1BA4  E0 nn: envPos = envelopeTable[nn]; envWait = 1; then tie
	mov r3, #1	@ 080A1BA8
	strb r3, [r1, #TRK_ENVWAIT]	@ 080A1BAC
	str r2, [r1, #TRK_PTR]	@ 080A1BB0
	ldrb r2, [r1, #TRK_LENGTH]	@ 080A1BB4
	strb r2, [r1, #TRK_WAIT]	@ 080A1BB8
	b .Lframe_nextTrack	@ 080A1BBC
cmdTempoRow:
	ldrb r0, [r2], #1	@ 080A1BC0
	strb r0, [r1, #TRK_TEMPOROW]	@ 080A1BC4  EE nn: tempo row
	b .Lparse_next	@ 080A1BC8
cmdInstrument:
	ldrb r0, [r2], #1	@ 080A1BCC
	ldr r3, .Lp_instTable	@ 080A1BD0
	ldr r0, [r3, r0, lsl #2]	@ 080A1BD4
	str r0, [r1, #TRK_INST]	@ 080A1BD8  E1 nn: inst = instTable[nn]
	b .Lparse_next	@ 080A1BDC
cmdMixMode:
	ldrb r0, [r2], #1	@ 080A1BE0
	ldr r3, .Lp_sndMixMode_2	@ 080A1BE4
	strb r0, [r3]	@ 080A1BE8  E2 nn: mix mode
	teq r0, #0	@ 080A1BEC
	bne .Lparse_next	@ 080A1BF0
	ldr r3, .Lp_sndTracks_0x230	@ 080A1BF4
	strb r0, [r3]	@ 080A1BF8  0: stop tracks 10-13
	strb r0, [r3, #0x38]	@ 080A1BFC
	strb r0, [r3, #0x70]	@ 080A1C00
	strb r0, [r3, #0xa8]	@ 080A1C04
	b .Lparse_next	@ 080A1C08
cmdResume:
	str r2, [r1, #4]	@ 080A1C0C
	ldr r1, .Lp_sndMaster_11	@ 080A1C10
	mov r2, #0	@ 080A1C14
	strb r2, [r1]	@ 080A1C18  E3: volume 0, fade in over 64 frames, step 4
	mov r2, #0x40	@ 080A1C1C
	strh r2, [r1, #MST_INFRAMES]	@ 080A1C20
	mov r2, #4	@ 080A1C24
	strb r2, [r1, #MST_STEP]	@ 080A1C28
	mov r2, #0x100	@ 080A1C2C
	strh r2, [r1, #MST_INACC]	@ 080A1C30
	strh r2, [r1, #MST_INPERIOD]	@ 080A1C34
	mov r0, #0	@ 080A1C38
	ldr r1, .Lp_REG_SOUND1CNT_L_2	@ 080A1C3C
	strh r0, [r1, #0x20]	@ 080A1C40
	ldr r1, .Lp_sndTracks_7	@ 080A1C44
	ldr r2, .Lp_sndQueueRead_6	@ 080A1C48
.L_080A1C4C:
	ldrb r0, [r1]	@ 080A1C4C
	tst r0, #0x81	@ 080A1C50
	movne r0, #1	@ 080A1C54
	moveq r0, #0	@ 080A1C58
	strb r0, [r1], #0x38	@ 080A1C5C  resume paused tracks
	teq r1, r2	@ 080A1C60
	bne .L_080A1C4C	@ 080A1C64
	ldr r3, .Lp_REG_SOUND1CNT_L_2	@ 080A1C68
	mov r0, #0x80	@ 080A1C6C
	strh r0, [r3, #IO_TM0CNT_H]	@ 080A1C70
	mov r0, #0x36	@ 080A1C74
	ldr r1, .Lp_sndQueueWrite_2	@ 080A1C78
	ldrb r2, [r1]	@ 080A1C7C
	ldr r3, .Lp_sndQueue_2	@ 080A1C80
	strh r0, [r3, r2]	@ 080A1C84
	add r2, r2, #2	@ 080A1C88
	and r2, r2, #7	@ 080A1C8C  queue id 0x36 (NOTE: & 7, not & 0xF)
	strb r2, [r1]	@ 080A1C90
	pop {r4, r5, r6, r7}	@ 080A1C94  returns from sndFrame
	bx lr	@ 080A1C98
cmdUnmuteMusic:
	mov r4, r1	@ 080A1C9C
	sub r4, r4, #0xe0	@ 080A1CA0
	ldrb r3, [r4]	@ 080A1CA4
	and r3, r3, #0x81	@ 080A1CA8
	strb r3, [r4]	@ 080A1CAC  E8: unmute track-4
	b .Lparse_next	@ 080A1CB0
cmdMuteMusic:
	mov r4, r1	@ 080A1CB4
	sub r4, r4, #0xe0	@ 080A1CB8
	ldrb r3, [r4]	@ 080A1CBC
	orr r3, r3, #2	@ 080A1CC0
	strb r3, [r4]	@ 080A1CC4  E9: mute track-4
	b .Lparse_next	@ 080A1CC8
cmdRestPcm:
	str r2, [r1, #TRK_PTR]	@ 080A1CCC
	mov r3, #0	@ 080A1CD0
	strb r3, [r1, #TRK_ENVWAIT]	@ 080A1CD4
	ldrb r2, [r1, #TRK_LENGTH]	@ 080A1CD8
	strb r2, [r1, #TRK_WAIT]	@ 080A1CDC
	ldr r4, .Lp_sndVoices_11	@ 080A1CE0
	and r5, r7, #7	@ 080A1CE4
	add r4, r4, r5, lsl #4	@ 080A1CE8
	str r3, [r4]	@ 080A1CEC  EC: clear the voice
	str r3, [r4, #4]	@ 080A1CF0
	str r3, [r4, #8]	@ 080A1CF4
	str r3, [r4, #0xc]	@ 080A1CF8
	b .Lframe_nextTrack	@ 080A1CFC
cmdRestPsg:
	str r2, [r1, #TRK_PTR]	@ 080A1D00
	mov r3, #0	@ 080A1D04
	strb r3, [r1, #TRK_ENVWAIT]	@ 080A1D08
	ldrb r2, [r1, #TRK_LENGTH]	@ 080A1D0C
	strb r2, [r1, #TRK_WAIT]	@ 080A1D10
	ldrh r2, [r1, #TRK_ENVREG]	@ 080A1D14
	and r2, r2, #0xff	@ 080A1D18
	strh r2, [r1, #TRK_ENVREG]	@ 080A1D1C  ED: envelope byte = 0
	ldrb r2, [r1]	@ 080A1D20
	tst r2, #2	@ 080A1D24
	bne .L_080A1D48	@ 080A1D28
	ldr r2, .Lp_psgEnvRegTable_4	@ 080A1D2C
	ldr r2, [r2, r7, lsl #2]	@ 080A1D30
	strh r3, [r2]	@ 080A1D34
	ldr r2, .Lp_psgCtrlRegTable_3	@ 080A1D38
	ldr r2, [r2, r7, lsl #2]	@ 080A1D3C
	eor r5, r5, #0x8000	@ 080A1D40
	strh r5, [r2]	@ 080A1D44
.L_080A1D48:
	b .Lframe_nextTrack	@ 080A1D48
cmdEnvelope:
	ldrb r0, [r2], #1	@ 080A1D4C
	ldr r3, .Lp_envelopeTable_2	@ 080A1D50
	add r3, r3, r0, lsl #2	@ 080A1D54
	ldr r0, [r3]	@ 080A1D58
	str r0, [r1, #TRK_ENV]	@ 080A1D5C  F0 nn: envelope
	b .Lparse_next	@ 080A1D60
cmdDuty:
	ldrb r0, [r2], #1	@ 080A1D64
	strb r0, [r1, #TRK_DUTY]	@ 080A1D68  F1 nn: duty
	b .Lparse_next	@ 080A1D6C
cmdVolume:
	ldrb r0, [r2], #1	@ 080A1D70
	strb r0, [r1, #TRK_VOLUME]	@ 080A1D74  F2 nn: volume
	b .Lparse_next	@ 080A1D78
cmdTranspose:
	ldrb r0, [r2], #1	@ 080A1D7C
	strb r0, [r1, #TRK_TRANSP]	@ 080A1D80  F3 nn: transpose
	b .Lparse_next	@ 080A1D84
cmdLoopStart:
	ldrb r0, [r2], #1	@ 080A1D88
	strb r0, [r1, #TRK_LOOPCNT]	@ 080A1D8C
	str r2, [r1, #TRK_LOOPPTR]	@ 080A1D90  F4 nn: loop start
	b .Lparse_next	@ 080A1D94
cmdLoopEnd:
	ldrb r0, [r1, #TRK_LOOPCNT]	@ 080A1D98
	sub r0, r0, #1	@ 080A1D9C
	cmp r0, #0	@ 080A1DA0
	strb r0, [r1, #TRK_LOOPCNT]	@ 080A1DA4
	ldrne r2, [r1, #TRK_LOOPPTR]	@ 080A1DA8  F5: loop end
	b .Lparse_next	@ 080A1DAC
cmdCall:
	ldrb r0, [r2], #1	@ 080A1DB0
	ldr r3, [r1, #TRK_PATTERNS]	@ 080A1DB4
	ldr r4, [r3, r0, lsl #2]	@ 080A1DB8
	str r2, [r1, #TRK_RETPTR]	@ 080A1DBC  F6 nn: call
	mov r2, r4	@ 080A1DC0
	b .Lparse_next	@ 080A1DC4
cmdReturn:
	ldr r2, [r1, #TRK_RETPTR]	@ 080A1DC8  F7: return
	b .Lparse_next	@ 080A1DCC
cmdJump:
	ldrb r0, [r2], #1	@ 080A1DD0
	ldr r3, [r1, #TRK_PATTERNS]	@ 080A1DD4
	ldr r4, [r3, r0, lsl #2]	@ 080A1DD8  F8 nn: jump
	mov r2, r4	@ 080A1DDC
	b .Lparse_next	@ 080A1DE0
cmdDetune:
	ldrb r0, [r2], #1	@ 080A1DE4
	strb r0, [r1, #TRK_DETUNE]	@ 080A1DE8  F9 nn: detune
	b .Lparse_next	@ 080A1DEC
cmdSweep:
	ldrb r0, [r2], #1	@ 080A1DF0
	strb r0, [r1, #TRK_SWEEP]	@ 080A1DF4  FA nn: sweep
	b .Lparse_next	@ 080A1DF8
cmdSweepOff:
	mov r0, #0	@ 080A1DFC
	strb r0, [r1, #TRK_SWEEP]	@ 080A1E00  FB: sweep off
	b .Lparse_next	@ 080A1E04
cmdWave:
	ldrb r0, [r2], #1	@ 080A1E08
	ldr r3, .Lp_waveTable	@ 080A1E0C
	ldr r4, [r3, r0, lsl #2]	@ 080A1E10  FC nn: wave
	str r4, [r1, #TRK_WAVE]	@ 080A1E14
	ldrb r3, [r1]	@ 080A1E18
	tst r3, #2	@ 080A1E1C
	bne .Lparse_next	@ 080A1E20
	mov r0, #0x40	@ 080A1E24
	strh r0, [r6, #IO_SOUND3CNT_L]	@ 080A1E28
	mov r3, #0x30	@ 080A1E2C
	add r3, r6, r3	@ 080A1E30
	mov r5, #8	@ 080A1E34
.L_080A1E38:
	ldrh r0, [r4], #2	@ 080A1E38
	strh r0, [r3], #2	@ 080A1E3C
	sub r5, r5, #1	@ 080A1E40
	cmp r5, #0	@ 080A1E44
	bne .L_080A1E38	@ 080A1E48
	mov r0, #0x80	@ 080A1E4C
	strh r0, [r6, #IO_SOUND3CNT_L]	@ 080A1E50
	b .Lparse_next	@ 080A1E54
cmdPan:
	ldrb r0, [r2], #1	@ 080A1E58
	mov r5, #0x11	@ 080A1E5C  FD nn: pan mask 0x11 << (track&3)
	and r4, r7, #3	@ 080A1E60
.L_080A1E64:
	teq r4, #0	@ 080A1E64
	beq .L_080A1E7C	@ 080A1E68
	lsl r0, r0, #1	@ 080A1E6C
	lsl r5, r5, #1	@ 080A1E70
	sub r4, r4, #1	@ 080A1E74
	b .L_080A1E64	@ 080A1E78
.L_080A1E7C:
	eor r5, r5, #0xff	@ 080A1E7C
	strb r0, [r1, #TRK_PANBITS]	@ 080A1E80
	strb r5, [r1, #TRK_PANMASK]	@ 080A1E84
	ldrb r4, [r1]	@ 080A1E88
	tst r4, #2	@ 080A1E8C
	bne .L_080A1EB4	@ 080A1E90
	ldr r3, .Lp_sndSoundCntL_6	@ 080A1E94
	ldrh r4, [r3]	@ 080A1E98
	lsl r5, r5, #8	@ 080A1E9C
	add r5, r5, #0xff	@ 080A1EA0
	and r4, r4, r5	@ 080A1EA4
	orr r4, r4, r0, lsl #8	@ 080A1EA8
	strh r4, [r3]	@ 080A1EAC
	strh r4, [r6, #IO_SOUNDCNT_L]	@ 080A1EB0
.L_080A1EB4:
	b .Lparse_next	@ 080A1EB4
cmdPcmPan:
	ldrb r0, [r2], #1	@ 080A1EB8
	and r3, r0, #0xf	@ 080A1EBC
	and r4, r0, #0xf0	@ 080A1EC0
	lsl r3, r3, #4	@ 080A1EC4
	add r3, r3, #0xf	@ 080A1EC8
	add r4, r4, #0xf	@ 080A1ECC
	tst r3, #0xf0	@ 080A1ED0
	moveq r3, #0	@ 080A1ED4
	tst r4, #0xf0	@ 080A1ED8
	moveq r4, #0	@ 080A1EDC
	strb r3, [r1, #TRK_PANBITS]	@ 080A1EE0  EA nn: volA = lo*16+15, volB = hi*16+15 (nibble 0 -> 0)
	strb r4, [r1, #TRK_PANMASK]	@ 080A1EE4
	b .Lparse_next	@ 080A1EE8
cmdTie:
	str r2, [r1, #TRK_PTR]	@ 080A1EEC
	ldrb r2, [r1, #TRK_LENGTH]	@ 080A1EF0
	strb r2, [r1, #TRK_WAIT]	@ 080A1EF4  FE: tie
	b .Lframe_nextTrack	@ 080A1EF8
cmdEnd:
	ldrb r0, [r1]	@ 080A1EFC
	and r0, r0, #0xfe	@ 080A1F00  FF: end of track
	strb r0, [r1]	@ 080A1F04
	cmp r7, #8	@ 080A1F08
	bpl .Lend_pcm	@ 080A1F0C
	cmp r7, #4	@ 080A1F10
	bmi .L_080A1F1C	@ 080A1F14
	b .Lend_psgSe	@ 080A1F18
.L_080A1F1C:
	tst r0, #2	@ 080A1F1C
	bne .L_080A1F44	@ 080A1F20
.Lend_silence:
	ldr r2, .Lp_psgEnvRegTable_5	@ 080A1F24
	ldr r2, [r2, r7, lsl #2]	@ 080A1F28
	mov r0, #0	@ 080A1F2C
	strh r0, [r2]	@ 080A1F30
	ldr r2, .Lp_psgCtrlRegTable_4	@ 080A1F34
	ldr r2, [r2, r7, lsl #2]	@ 080A1F38
	mov r0, #0x8000	@ 080A1F3C
	strh r0, [r2]	@ 080A1F40
.L_080A1F44:
	b .Lframe_nextTrack	@ 080A1F44
.Lend_psgSe:
	sub r1, r1, #0xe0	@ 080A1F48
	ldrb r3, [r1]	@ 080A1F4C
	and r3, r3, #0xfd	@ 080A1F50  unmute music track
	strb r3, [r1]	@ 080A1F54
	tst r3, #1	@ 080A1F58
	addeq r1, r1, #0xe0	@ 080A1F5C
	beq .Lend_silence	@ 080A1F60
	and r3, r7, #3	@ 080A1F64
	cmp r3, #2	@ 080A1F68
	beq .Lend_restoreWave	@ 080A1F6C
.Lend_restore:
	ldr r5, .Lp_sndSoundCntL_7	@ 080A1F70
	ldrh r4, [r5]	@ 080A1F74
	ldrb r0, [r1, #TRK_PANMASK]	@ 080A1F78
	lsl r0, r0, #8	@ 080A1F7C
	add r0, r0, #0xff	@ 080A1F80
	and r4, r4, r0	@ 080A1F84
	ldrb r0, [r1, #TRK_PANBITS]	@ 080A1F88
	orr r4, r4, r0, lsl #8	@ 080A1F8C
	strh r4, [r5]	@ 080A1F90
	strh r4, [r6, #IO_SOUNDCNT_L]	@ 080A1F94
	ldrh r5, [r1, #TRK_ENVREG]	@ 080A1F98
	ldr r2, .Lp_psgEnvRegTable_6	@ 080A1F9C
	ldr r2, [r2, r7, lsl #2]	@ 080A1FA0
	strh r5, [r2]	@ 080A1FA4
	ldr r2, .Lp_psgCtrlRegTable_5	@ 080A1FA8
	ldr r2, [r2, r7, lsl #2]	@ 080A1FAC
	ldrh r3, [r1, #TRK_FREQ]	@ 080A1FB0
	eor r3, r3, #0x8000	@ 080A1FB4
	strh r3, [r2]	@ 080A1FB8
	teq r7, #4	@ 080A1FBC
	ldrbeq r0, [r1, #TRK_SWEEP]	@ 080A1FC0
	strheq r0, [r6]	@ 080A1FC4
	add r1, r1, #0xe0	@ 080A1FC8
	b .Lframe_nextTrack	@ 080A1FCC
.Lend_restoreWave:
	mov r0, #0x40	@ 080A1FD0
	strh r0, [r6, #IO_SOUND3CNT_L]	@ 080A1FD4
	ldr r4, [r1, #TRK_WAVE]	@ 080A1FD8
	add r3, r6, #0x30	@ 080A1FDC
	mov r5, #8	@ 080A1FE0
.L_080A1FE4:
	ldrh r0, [r4], #2	@ 080A1FE4
	strh r0, [r3], #2	@ 080A1FE8
	sub r5, r5, #1	@ 080A1FEC
	cmp r5, #0	@ 080A1FF0
	bne .L_080A1FE4	@ 080A1FF4
	mov r0, #0x80	@ 080A1FF8
	strh r0, [r6, #IO_SOUND3CNT_L]	@ 080A1FFC
	b .Lend_restore	@ 080A2000
.Lend_pcm:
	and r0, r7, #7	@ 080A2004
	ldr r3, .Lp_sndVoices_12	@ 080A2008
	add r4, r3, r0, lsl #4	@ 080A200C
	mov r0, #0	@ 080A2010
	str r0, [r4], #4	@ 080A2014
	str r0, [r4], #4	@ 080A2018
	str r0, [r4], #4	@ 080A201C
	str r0, [r4], #4	@ 080A2020
	ldr r4, [r3, #4]	@ 080A2024
	ldr r5, [r3, #0x14]	@ 080A2028
	orr r4, r4, r5	@ 080A202C
	tst r4, #0xff	@ 080A2030  voices 0/1 idle? (tests low byte of cur only)
	bne .L_080A204C	@ 080A2034
	moveq r0, #0	@ 080A2038
	strheq r0, [r6, #IO_TM0CNT_H]	@ 080A203C
	strheq r0, [r6, #IO_DMA1CNT_H]	@ 080A2040  stop TM0 and DMA1/2
	moveq r0, #0	@ 080A2044
	strheq r0, [r6, #IO_DMA2CNT_H]	@ 080A2048
.L_080A204C:
	b .Lframe_nextTrack	@ 080A204C
.Lp_sndQueueWrite:
	.word sndQueueWrite	@ 080A2050
.Lp_sndQueue:
	.word sndQueue	@ 080A2054
.Lp_sndMaster:
	.word sndMaster	@ 080A2058
.Lp_sndMaster_2:
	.word sndMaster	@ 080A205C
.Lp_REG_SOUND1CNT_L_2:
	.word REG_SOUND1CNT_L	@ 080A2060
.Lp_sndTracks:
	.word sndTracks	@ 080A2064
.Lp_sndQueueRead:
	.word sndQueueRead	@ 080A2068
.Lp_sndMaster_3:
	.word sndMaster	@ 080A206C
.Lp_sndMaster_4:
	.word sndMaster	@ 080A2070
.Lp_0x00008802:
	.word 0x00008802	@ 080A2074
.Lp_0x0000210E:
	.word 0x0000210E	@ 080A2078
.Lp_sndSoundCntL:
	.word sndSoundCntL	@ 080A207C
.Lp_sndTracks_2:
	.word sndTracks	@ 080A2080
.Lp_sndQueueRead_2:
	.word sndQueueRead	@ 080A2084
.Lp_sndVoices_5:
	.word sndVoices	@ 080A2088
.Lp_0x03002EEC:
	.word 0x03002EEC	@ 080A208C
.Lp_sndMaster_5:
	.word sndMaster	@ 080A2090
.Lp_sndMixA_4:
	.word sndMixA	@ 080A2094
.Lp_sndMixB_4:
	.word sndMixB	@ 080A2098
.Lp_REG_FIFO_A:
	.word REG_FIFO_A	@ 080A209C
.Lp_REG_FIFO_B:
	.word REG_FIFO_B	@ 080A20A0
.Lp_sndTimerReload:
	.word sndTimerReload	@ 080A20A4
.Lp_sndTracks_3:
	.word sndTracks	@ 080A20A8
.Lp_sndMaster_6:
	.word sndMaster	@ 080A20AC
.Lp_sndQueueRead_3:
	.word sndQueueRead	@ 080A20B0
.Lp_sndSoundCntL_2:
	.word sndSoundCntL	@ 080A20B4
.Lp_sndTracks_0x1C0:
	.word sndTracks+0x1C0	@ 080A20B8
.Lp_sndVoices_6:
	.word sndVoices	@ 080A20BC
.Lp_sndMixA_5:
	.word sndMixA	@ 080A20C0
.Lp_sndSoundCntL_3:
	.word sndSoundCntL	@ 080A20C4
.Lp_sndSoundCntL_4:
	.word sndSoundCntL	@ 080A20C8
.Lp_sndTracks_0x1C0_2:
	.word sndTracks+0x1C0	@ 080A20CC
.Lp_sndVoices_7:
	.word sndVoices	@ 080A20D0
.Lp_sndMixA_6:
	.word sndMixA	@ 080A20D4
.Lp_sndSoundCntL_5:
	.word sndSoundCntL	@ 080A20D8
.Lp_sndTracks_4:
	.word sndTracks	@ 080A20DC
.Lp_sndQueueRead_4:
	.word sndQueueRead	@ 080A20E0
.Lp_sndMaster_7:
	.word sndMaster	@ 080A20E4
.Lp_psgEnvRegTable:
	.word psgEnvRegTable	@ 080A20E8
.Lp_sndTracks_5:
	.word sndTracks	@ 080A20EC
.Lp_seqSongTable:
	.word seqSongTable	@ 080A20F0
.Lp_sndQueueRead_5:
	.word sndQueueRead	@ 080A20F4
.Lp_seqSongTable_2:
	.word seqSongTable	@ 080A20F8
.Lp_sndTracks_6:
	.word sndTracks	@ 080A20FC
.Lp_panBitsTable:
	.word panBitsTable	@ 080A2100
.Lp_psgEnvRegTable_2:
	.word psgEnvRegTable	@ 080A2104
.Lp_psgCtrlRegTable:
	.word psgCtrlRegTable	@ 080A2108
.Lp_sndMaster_8:
	.word sndMaster	@ 080A210C
.Lp_sndVoices_8:
	.word sndVoices	@ 080A2110
.Lp_sndMaster_9:
	.word sndMaster	@ 080A2114
.Lp_sndVoices_9:
	.word sndVoices	@ 080A2118
.Lp_seqCmdTable:
	.word seqCmdTable	@ 080A211C
.Lp_lengthTable:
	.word lengthTable	@ 080A2120
.Lp_psgFreqTable:
	.word psgFreqTable	@ 080A2124
.Lp_psgEnvRegTable_3:
	.word psgEnvRegTable	@ 080A2128
.Lp_psgCtrlRegTable_2:
	.word psgCtrlRegTable	@ 080A212C
.Lp_sndVoices_10:
	.word sndVoices	@ 080A2130
.Lp_sndMaster_10:
	.word sndMaster	@ 080A2134
.Lp_sndMixA_7:
	.word sndMixA	@ 080A2138
.Lp_sndMixA_8:
	.word sndMixA	@ 080A213C
.Lp_sndMixB_5:
	.word sndMixB	@ 080A2140
.Lp_REG_IE_3:
	.word REG_IE	@ 080A2144
.Lp_envelopeTable:
	.word envelopeTable	@ 080A2148
.Lp_instTable:
	.word instTable	@ 080A214C
.Lp_sndMixMode_2:
	.word sndMixMode	@ 080A2150
.Lp_sndTracks_0x230:
	.word sndTracks+0x230	@ 080A2154
.Lp_sndMaster_11:
	.word sndMaster	@ 080A2158
.Lp_sndTracks_7:
	.word sndTracks	@ 080A215C
.Lp_sndQueueRead_6:
	.word sndQueueRead	@ 080A2160
.Lp_sndQueueWrite_2:
	.word sndQueueWrite	@ 080A2164
.Lp_sndQueue_2:
	.word sndQueue	@ 080A2168
.Lp_sndVoices_11:
	.word sndVoices	@ 080A216C
.Lp_psgEnvRegTable_4:
	.word psgEnvRegTable	@ 080A2170
.Lp_psgCtrlRegTable_3:
	.word psgCtrlRegTable	@ 080A2174
.Lp_envelopeTable_2:
	.word envelopeTable	@ 080A2178
.Lp_waveTable:
	.word waveTable	@ 080A217C
.Lp_sndSoundCntL_6:
	.word sndSoundCntL	@ 080A2180
.Lp_psgEnvRegTable_5:
	.word psgEnvRegTable	@ 080A2184
.Lp_psgCtrlRegTable_4:
	.word psgCtrlRegTable	@ 080A2188
.Lp_sndSoundCntL_7:
	.word sndSoundCntL	@ 080A218C
.Lp_psgEnvRegTable_6:
	.word psgEnvRegTable	@ 080A2190
.Lp_psgCtrlRegTable_5:
	.word psgCtrlRegTable	@ 080A2194
.Lp_sndVoices_12:
	.word sndVoices	@ 080A2198

@ lengthTable[24*16]: row = t->tempoRow (EE nn); the row is added to (b & 0x7F),
@ so a row is effectively a 16-byte shift of a 96-byte window. Column layout per row as in MV
@ (A = quarter); see data dump for each row's quarter length.
lengthTable:
	.byte   4,   1,   2,   3,   4,   6,   8,  12,  16,  24,  32,  48,  64,  96, 128, 192	@ 080A219C  row 0
	.byte   5,   1,   2,   3,   4,   0,   9,  13,  18,  27,  36,  54,  72, 108, 144, 216	@ 080A21AC  row 1
	.byte   5,   1,   2,   3,   5,   0,  10,  15,  20,  30,  40,  60,  80, 120, 160, 240	@ 080A21BC  row 2
	.byte   6,   1,   2,   3,   5,   0,  11,  16,  22,  33,  44,  66,  88, 132, 176,   0	@ 080A21CC  row 3
	.byte   4,   1,   2,   3,   6,   9,  12,  18,  24,  36,  48,  72,  96, 144, 192,   4	@ 080A21DC  row 4
	.byte   7,   1,   2,   3,   6,   5,  13,  19,  26,  39,  52,  78, 104, 156, 208,   5	@ 080A21EC  row 5
	.byte   7,   1,   2,   3,   7,   4,  14,  21,  28,  42,  56,  84, 112, 168, 224,   5	@ 080A21FC  row 6
	.byte   8,   1,   2,   3,   7,   0,  15,  21,  30,  45,  60,  90, 120, 180, 240,   6	@ 080A220C  row 7
	.byte  10,   1,   2,   3,  10,  11,  21,  22,  16,  24,  32,  48,  64,  96, 128, 192	@ 080A221C  row 8
	.byte  16,  17,  18,  19,  20,  21,  22,  24,  27,  30,  36,  12,  23,  46,  92, 184	@ 080A222C  row 9
	.byte  14,   1,   2,   3,  13,  41,  27,  40,  54,  81, 108, 162, 216,   2,   0,   0	@ 080A223C  row 10
	.byte   0,   1,   2,   3,   7,   7,  10,   9,  28,   0,  56,  84, 112, 168, 224,   0	@ 080A224C  row 11
	.byte  15,  16,  17,  18,  19,  19,  20,  22,  24,  26,  32,  10,  23,  46,  92, 184	@ 080A225C  row 12
	.byte   7,   1,   2,   3,   7,   4,  14,  21,  27,  42,  54,  81, 108, 162, 216,   5	@ 080A226C  row 13
	.byte   7,   1,   2,   3,   6,   8,  12,  13,  25,   0,  50,  75, 100, 150, 200,   5	@ 080A227C  row 14
	.byte  24,  26,  28,  30,   7,   9,  11,  12,  23,  35,  46,  69,  92, 138, 184,   8	@ 080A228C  row 15
	.byte   7,   1,   2,   3,   6,  14,  13,   0,  27,  42,  54,  81, 108, 162, 216,   5	@ 080A229C  row 16
	.byte  18,   5,   0,   0,   0,   0,   0,   0,  36,   0,  72, 108, 144, 216,   0,   0	@ 080A22AC  row 17
	.byte   0,   0,   0,   0,   0,   0,   0,   0,  35,   0,  70, 105, 140, 210,   0,   0	@ 080A22BC  row 18
	.byte  29,  31,  34,  72,   0,   0,   0,   0,  32,  48,  64,  96, 128, 192,   0,   0	@ 080A22CC  row 19
	.byte   0,   0,   0,   0,   0,   0,   0,   0,  40,  60,  80, 120, 224,   0,   0,   0	@ 080A22DC  row 20
	.byte   7,   1,   2,   3,   6,   5,  13,  19,  25,   0,  50,  75, 100, 146, 200,   5	@ 080A22EC  row 21
	.byte  10,   1,   4,   3,   6,   7,  12,  13,  25,   0,  50,  75, 100, 146, 200,   5	@ 080A22FC  row 22
	.byte   5,   1,   2,   3,   5,   0,  10,   9,  19,  28,  38,  57,  76, 114, 152, 228	@ 080A230C  row 23

@ envelopeTable[160]: pointers to envelope scripts (F0 nn / E0 nn).
envelopeTable:
	.word env_259C	@ 080A231C  envelope 0
	.word env_259E	@ 080A2320  envelope 1
	.word env_25A0	@ 080A2324  envelope 2
	.word env_25A2	@ 080A2328  envelope 3
	.word env_25A4	@ 080A232C  envelope 4
	.word env_25A6	@ 080A2330  envelope 5
	.word env_25A8	@ 080A2334  envelope 6
	.word env_25AA	@ 080A2338  envelope 7
	.word env_25AC	@ 080A233C  envelope 8
	.word env_25B4	@ 080A2340  envelope 9
	.word env_25C0	@ 080A2344  envelope 10
	.word env_25C8	@ 080A2348  envelope 11
	.word env_25D0	@ 080A234C  envelope 12
	.word env_25D4	@ 080A2350  envelope 13
	.word env_25D8	@ 080A2354  envelope 14
	.word env_25E2	@ 080A2358  envelope 15
	.word env_25EC	@ 080A235C  envelope 16
	.word env_25EE	@ 080A2360  envelope 17
	.word env_25F0	@ 080A2364  envelope 18
	.word env_25F2	@ 080A2368  envelope 19
	.word env_25F4	@ 080A236C  envelope 20
	.word env_25F8	@ 080A2370  envelope 21
	.word env_25FC	@ 080A2374  envelope 22
	.word env_2600	@ 080A2378  envelope 23
	.word env_2604	@ 080A237C  envelope 24
	.word env_2608	@ 080A2380  envelope 25
	.word env_260C	@ 080A2384  envelope 26
	.word env_2610	@ 080A2388  envelope 27
	.word env_2614	@ 080A238C  envelope 28
	.word env_2618	@ 080A2390  envelope 29
	.word env_261C	@ 080A2394  envelope 30
	.word env_2620	@ 080A2398  envelope 31
	.word env_2620	@ 080A239C  envelope 32
	.word env_2623	@ 080A23A0  envelope 33
	.word env_2629	@ 080A23A4  envelope 34
	.word env_262C	@ 080A23A8  envelope 35
	.word env_2632	@ 080A23AC  envelope 36
	.word env_2638	@ 080A23B0  envelope 37
	.word env_263B	@ 080A23B4  envelope 38
	.word env_2644	@ 080A23B8  envelope 39
	.word env_2647	@ 080A23BC  envelope 40
	.word env_2650	@ 080A23C0  envelope 41
	.word env_2659	@ 080A23C4  envelope 42
	.word env_2662	@ 080A23C8  envelope 43
	.word env_266B	@ 080A23CC  envelope 44
	.word env_2674	@ 080A23D0  envelope 45
	.word env_2677	@ 080A23D4  envelope 46
	.word env_2680	@ 080A23D8  envelope 47
	.word env_2689	@ 080A23DC  envelope 48
	.word env_2695	@ 080A23E0  envelope 49
	.word env_2698	@ 080A23E4  envelope 50
	.word env_269E	@ 080A23E8  envelope 51
	.word env_26A4	@ 080A23EC  envelope 52
	.word env_26AD	@ 080A23F0  envelope 53
	.word env_26B5	@ 080A23F4  envelope 54
	.word env_26BF	@ 080A23F8  envelope 55
	.word env_26C8	@ 080A23FC  envelope 56
	.word env_26CE	@ 080A2400  envelope 57
	.word env_26D4	@ 080A2404  envelope 58
	.word env_26DA	@ 080A2408  envelope 59
	.word env_26E0	@ 080A240C  envelope 60
	.word env_26E6	@ 080A2410  envelope 61
	.word env_26EF	@ 080A2414  envelope 62
	.word env_26F5	@ 080A2418  envelope 63
	.word env_26FB	@ 080A241C  envelope 64
	.word env_2701	@ 080A2420  envelope 65
	.word env_270A	@ 080A2424  envelope 66
	.word env_2710	@ 080A2428  envelope 67
	.word env_2716	@ 080A242C  envelope 68
	.word env_271F	@ 080A2430  envelope 69
	.word env_2725	@ 080A2434  envelope 70
	.word env_272E	@ 080A2438  envelope 71
	.word env_2734	@ 080A243C  envelope 72
	.word env_273A	@ 080A2440  envelope 73
	.word env_2740	@ 080A2444  envelope 74
	.word env_2746	@ 080A2448  envelope 75
	.word env_274F	@ 080A244C  envelope 76
	.word env_2758	@ 080A2450  envelope 77
	.word env_2761	@ 080A2454  envelope 78
	.word env_276A	@ 080A2458  envelope 79
	.word env_2773	@ 080A245C  envelope 80
	.word env_277F	@ 080A2460  envelope 81
	.word env_2785	@ 080A2464  envelope 82
	.word env_278B	@ 080A2468  envelope 83
	.word env_2795	@ 080A246C  envelope 84
	.word env_279B	@ 080A2470  envelope 85
	.word env_27A1	@ 080A2474  envelope 86
	.word env_27A7	@ 080A2478  envelope 87
	.word env_27AF	@ 080A247C  envelope 88
	.word env_27BB	@ 080A2480  envelope 89
	.word env_27C1	@ 080A2484  envelope 90
	.word env_27C7	@ 080A2488  envelope 91
	.word env_27CD	@ 080A248C  envelope 92
	.word env_27D3	@ 080A2490  envelope 93
	.word env_27D9	@ 080A2494  envelope 94
	.word env_27DF	@ 080A2498  envelope 95
	.word env_27E8	@ 080A249C  envelope 96
	.word env_27F4	@ 080A24A0  envelope 97
	.word env_27F6	@ 080A24A4  envelope 98
	.word env_27FF	@ 080A24A8  envelope 99
	.word env_2808	@ 080A24AC  envelope 100
	.word env_280E	@ 080A24B0  envelope 101
	.word env_2814	@ 080A24B4  envelope 102
	.word env_281A	@ 080A24B8  envelope 103
	.word env_2820	@ 080A24BC  envelope 104
	.word env_2829	@ 080A24C0  envelope 105
	.word env_282F	@ 080A24C4  envelope 106
	.word env_2837	@ 080A24C8  envelope 107
	.word env_283B	@ 080A24CC  envelope 108
	.word env_2841	@ 080A24D0  envelope 109
	.word env_2847	@ 080A24D4  envelope 110
	.word env_284F	@ 080A24D8  envelope 111
	.word env_2858	@ 080A24DC  envelope 112
	.word env_2861	@ 080A24E0  envelope 113
	.word env_2867	@ 080A24E4  envelope 114
	.word env_286D	@ 080A24E8  envelope 115
	.word env_2873	@ 080A24EC  envelope 116
	.word env_287C	@ 080A24F0  envelope 117
	.word env_2886	@ 080A24F4  envelope 118
	.word env_2890	@ 080A24F8  envelope 119
	.word env_2894	@ 080A24FC  envelope 120
	.word env_2897	@ 080A2500  envelope 121
	.word env_289D	@ 080A2504  envelope 122
	.word env_28A0	@ 080A2508  envelope 123
	.word env_28A4	@ 080A250C  envelope 124
	.word env_28A8	@ 080A2510  envelope 125
	.word env_28AB	@ 080A2514  envelope 126
	.word env_28AE	@ 080A2518  envelope 127
	.word env_28B4	@ 080A251C  envelope 128
	.word env_28B7	@ 080A2520  envelope 129
	.word env_28BA	@ 080A2524  envelope 130
	.word env_28BD	@ 080A2528  envelope 131
	.word env_28C0	@ 080A252C  envelope 132
	.word env_28C3	@ 080A2530  envelope 133
	.word env_28C6	@ 080A2534  envelope 134
	.word env_28CC	@ 080A2538  envelope 135
	.word env_28D2	@ 080A253C  envelope 136
	.word env_28D6	@ 080A2540  envelope 137
	.word env_28F6	@ 080A2544  envelope 138
	.word env_2916	@ 080A2548  envelope 139
	.word env_2936	@ 080A254C  envelope 140
	.word env_2939	@ 080A2550  envelope 141
	.word env_293C	@ 080A2554  envelope 142
	.word env_293F	@ 080A2558  envelope 143
	.word env_2942	@ 080A255C  envelope 144
	.word env_2945	@ 080A2560  envelope 145
	.word env_2948	@ 080A2564  envelope 146
	.word env_294E	@ 080A2568  envelope 147
	.word env_2954	@ 080A256C  envelope 148
	.word env_2957	@ 080A2570  envelope 149
	.word env_2959	@ 080A2574  envelope 150
	.word env_295B	@ 080A2578  envelope 151
	.word env_2963	@ 080A257C  envelope 152
	.word env_2971	@ 080A2580  envelope 153
	.word env_2977	@ 080A2584  envelope 154
	.word env_2992	@ 080A2588  envelope 155
	.word env_2995	@ 080A258C  envelope 156
	.word env_2995	@ 080A2590  envelope 157
	.word env_2995	@ 080A2594  envelope 158
	.word env_2995	@ 080A2598  envelope 159

@ Envelope script data.
env_259C:
	.byte 0x00, 0xF0	@ 080A259C
env_259E:
	.byte 0x00, 0xF1	@ 080A259E
env_25A0:
	.byte 0x00, 0xF2	@ 080A25A0
env_25A2:
	.byte 0x00, 0xF3	@ 080A25A2
env_25A4:
	.byte 0x00, 0xF4	@ 080A25A4
env_25A6:
	.byte 0x00, 0xF5	@ 080A25A6
env_25A8:
	.byte 0x00, 0xF6	@ 080A25A8
env_25AA:
	.byte 0x00, 0xF7	@ 080A25AA
env_25AC:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0x00, 0xF7	@ 080A25AC
env_25B4:
	.byte 0x01, 0xB0, 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0x50, 0xF0, 0x00, 0xF7	@ 080A25B4
env_25C0:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x80, 0xF0, 0x00, 0xF7	@ 080A25C0
env_25C8:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x28, 0xF0, 0x00, 0xF6	@ 080A25C8
env_25D0:
	.byte 0x04, 0xF2, 0x00, 0xD3	@ 080A25D0
env_25D4:
	.byte 0x09, 0xF3, 0x00, 0xE6	@ 080A25D4
env_25D8:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0xC0, 0xF0, 0x00, 0xF7	@ 080A25D8
env_25E2:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0xA0, 0xF0, 0x00, 0xF7	@ 080A25E2
env_25EC:
	.byte 0x00, 0x20	@ 080A25EC
env_25EE:
	.byte 0x00, 0x80	@ 080A25EE
env_25F0:
	.byte 0x00, 0x40	@ 080A25F0
env_25F2:
	.byte 0x00, 0x60	@ 080A25F2
env_25F4:
	.byte 0x06, 0x40, 0x00, 0x00	@ 080A25F4
env_25F8:
	.byte 0x10, 0x40, 0x00, 0x00	@ 080A25F8
env_25FC:
	.byte 0x18, 0x40, 0x00, 0x00	@ 080A25FC
env_2600:
	.byte 0x0C, 0x40, 0x00, 0x00	@ 080A2600
env_2604:
	.byte 0x08, 0x40, 0x00, 0x00	@ 080A2604
env_2608:
	.byte 0x03, 0x40, 0x00, 0x00	@ 080A2608
env_260C:
	.byte 0x05, 0x40, 0x00, 0x00	@ 080A260C
env_2610:
	.byte 0x0A, 0x40, 0x00, 0x00	@ 080A2610
env_2614:
	.byte 0x07, 0x40, 0x00, 0x00	@ 080A2614
env_2618:
	.byte 0x28, 0x40, 0x00, 0x00	@ 080A2618
env_261C:
	.byte 0x10, 0x60, 0x00, 0x00	@ 080A261C
env_2620:
	.byte 0x00, 0x00, 0xFF	@ 080A2620
env_2623:
	.byte 0x03, 0x10, 0xC0, 0x00, 0x86, 0xFF	@ 080A2623
env_2629:
	.byte 0x00, 0x86, 0xFF	@ 080A2629
env_262C:
	.byte 0x08, 0x0C, 0xA0, 0x00, 0x00, 0xFF	@ 080A262C
env_2632:
	.byte 0x48, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2632
env_2638:
	.byte 0x00, 0x84, 0xFF	@ 080A2638
env_263B:
	.byte 0x08, 0x08, 0xC0, 0xFF, 0x00, 0xFF, 0x00, 0x82, 0xFF	@ 080A263B
env_2644:
	.byte 0x00, 0x82, 0xFF	@ 080A2644
env_2647:
	.byte 0x08, 0x0C, 0xA0, 0x10, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2647
env_2650:
	.byte 0x08, 0x0C, 0xA0, 0x80, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2650
env_2659:
	.byte 0x08, 0x0C, 0xA0, 0xC0, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2659
env_2662:
	.byte 0x08, 0x0C, 0xA0, 0x40, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2662
env_266B:
	.byte 0x08, 0x0C, 0xA0, 0xE0, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A266B
env_2674:
	.byte 0x00, 0x81, 0xFF	@ 080A2674
env_2677:
	.byte 0x08, 0x0C, 0xA0, 0x50, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2677
env_2680:
	.byte 0x08, 0x0C, 0xA0, 0x20, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A2680
env_2689:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0x90, 0xF0, 0x90, 0xF0, 0x00, 0xF7	@ 080A2689
env_2695:
	.byte 0x00, 0x83, 0xFF	@ 080A2695
env_2698:
	.byte 0xC0, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2698
env_269E:
	.byte 0x01, 0xE0, 0x02, 0xF2, 0x00, 0x00	@ 080A269E
env_26A4:
	.byte 0x08, 0x0C, 0xA0, 0xF0, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A26A4
env_26AD:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0x00, 0xF0	@ 080A26AD
env_26B5:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0xF0, 0xF0, 0x00, 0xF7	@ 080A26B5
env_26BF:
	.byte 0x08, 0x0C, 0xA0, 0xA8, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A26BF
env_26C8:
	.byte 0x9C, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A26C8
env_26CE:
	.byte 0xD0, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A26CE
env_26D4:
	.byte 0x1A, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A26D4
env_26DA:
	.byte 0x4E, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A26DA
env_26E0:
	.byte 0x34, 0x00, 0xFF, 0x00, 0x86, 0xFF	@ 080A26E0
env_26E6:
	.byte 0xD0, 0x00, 0xFF, 0x68, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A26E6
env_26EF:
	.byte 0x68, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A26EF
env_26F5:
	.byte 0x68, 0x00, 0xFF, 0x00, 0x8C, 0xFF	@ 080A26F5
env_26FB:
	.byte 0xD0, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A26FB
env_2701:
	.byte 0xD0, 0x00, 0xFF, 0xB6, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A2701
env_270A:
	.byte 0x1A, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A270A
env_2710:
	.byte 0xB6, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A2710
env_2716:
	.byte 0xD0, 0x00, 0xFF, 0xB6, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A2716
env_271F:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x00, 0xF0	@ 080A271F
env_2725:
	.byte 0x08, 0x0C, 0xA0, 0x40, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A2725
env_272E:
	.byte 0x84, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A272E
env_2734:
	.byte 0x34, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A2734
env_273A:
	.byte 0x68, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A273A
env_2740:
	.byte 0x20, 0x04, 0x80, 0x00, 0x00, 0xFF	@ 080A2740
env_2746:
	.byte 0x20, 0x04, 0x80, 0x14, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A2746
env_274F:
	.byte 0x08, 0x0C, 0xA0, 0x2C, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A274F
env_2758:
	.byte 0x20, 0x04, 0x80, 0x48, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A2758
env_2761:
	.byte 0x08, 0x0C, 0xA0, 0x60, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A2761
env_276A:
	.byte 0xA0, 0x01, 0x60, 0x50, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A276A
env_2773:
	.byte 0x40, 0xC0, 0x20, 0xD0, 0x20, 0xE0, 0x20, 0xF0, 0x50, 0xF0, 0x00, 0xF4	@ 080A2773
env_277F:
	.byte 0xF0, 0xF0, 0x50, 0xF0, 0x00, 0xF7	@ 080A277F
env_2785:
	.byte 0x1E, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A2785
env_278B:
	.byte 0x0C, 0xC0, 0x0C, 0xD0, 0x0A, 0xE0, 0x0A, 0xF0, 0x00, 0xF1	@ 080A278B
env_2795:
	.byte 0x2A, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A2795
env_279B:
	.byte 0x40, 0x00, 0xFF, 0x00, 0x81, 0xFF	@ 080A279B
env_27A1:
	.byte 0x6A, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A27A1
env_27A7:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x80, 0xF0, 0x00, 0xF0	@ 080A27A7
env_27AF:
	.byte 0x08, 0x0C, 0xA0, 0xB0, 0x00, 0xFF, 0x45, 0x00, 0xFF, 0x00, 0x8D, 0xFF	@ 080A27AF
env_27BB:
	.byte 0xB8, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A27BB
env_27C1:
	.byte 0xCF, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A27C1
env_27C7:
	.byte 0x73, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A27C7
env_27CD:
	.byte 0xB8, 0x00, 0xFF, 0x00, 0x8D, 0xFF	@ 080A27CD
env_27D3:
	.byte 0xB8, 0x04, 0x80, 0x00, 0x9E, 0xFF	@ 080A27D3
env_27D9:
	.byte 0xA1, 0x00, 0xFF, 0x00, 0x8F, 0xFF	@ 080A27D9
env_27DF:
	.byte 0x08, 0x0C, 0xA0, 0x58, 0x00, 0xFF, 0x00, 0x82, 0xFF	@ 080A27DF
env_27E8:
	.byte 0x08, 0x0C, 0xA0, 0x58, 0x00, 0xFF, 0xC0, 0x00, 0xFF, 0x00, 0x82, 0xFF	@ 080A27E8
env_27F4:
	.byte 0x00, 0xD1	@ 080A27F4
env_27F6:
	.byte 0x08, 0x0C, 0xA0, 0x28, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A27F6
env_27FF:
	.byte 0x08, 0x0C, 0xA0, 0x58, 0x00, 0xFF, 0x00, 0x90, 0xFF	@ 080A27FF
env_2808:
	.byte 0x01, 0xD0, 0x04, 0xF0, 0x00, 0x00	@ 080A2808
env_280E:
	.byte 0xB6, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A280E
env_2814:
	.byte 0x9C, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2814
env_281A:
	.byte 0x4E, 0x00, 0xFF, 0x00, 0x8E, 0xFF	@ 080A281A
env_2820:
	.byte 0x08, 0x0C, 0xA0, 0x2C, 0x00, 0xFF, 0x00, 0x84, 0xFF	@ 080A2820
env_2829:
	.byte 0x08, 0x18, 0x40, 0x00, 0x00, 0xFF	@ 080A2829
env_282F:
	.byte 0x02, 0xC0, 0x02, 0xD0, 0x02, 0xE0, 0x00, 0xF0	@ 080A282F
env_2837:
	.byte 0x09, 0xF4, 0x00, 0x3F	@ 080A2837
env_283B:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x00, 0xF0	@ 080A283B
env_2841:
	.byte 0x36, 0x00, 0xFF, 0x00, 0x8A, 0xFF	@ 080A2841
env_2847:
	.byte 0x01, 0xD0, 0x01, 0xE0, 0x36, 0xF0, 0x00, 0xF3	@ 080A2847
env_284F:
	.byte 0x08, 0x0C, 0xA0, 0x1C, 0x00, 0xFF, 0x00, 0x8F, 0xFF	@ 080A284F
env_2858:
	.byte 0x08, 0x0C, 0xA0, 0x9A, 0x00, 0xFF, 0x00, 0x8C, 0xFF	@ 080A2858
env_2861:
	.byte 0x08, 0x10, 0x80, 0x00, 0x84, 0xFF	@ 080A2861
env_2867:
	.byte 0x10, 0x10, 0x00, 0x00, 0x00, 0xFF	@ 080A2867
env_286D:
	.byte 0x08, 0x10, 0x80, 0x00, 0x85, 0xFF	@ 080A286D
env_2873:
	.byte 0x08, 0x0C, 0xA0, 0x20, 0x00, 0xFF, 0x00, 0x81, 0xFF	@ 080A2873
env_287C:
	.byte 0x0C, 0xF0, 0x0C, 0xE0, 0x0C, 0xD0, 0x0C, 0xC0, 0x00, 0xB0	@ 080A287C
env_2886:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0x06, 0xF0, 0x00, 0xF7	@ 080A2886
env_2890:
	.byte 0x10, 0xF0, 0x00, 0xF7	@ 080A2890
env_2894:
	.byte 0x00, 0x06, 0x00	@ 080A2894
env_2897:
	.byte 0x10, 0x0A, 0x60, 0x00, 0x00, 0xFF	@ 080A2897
env_289D:
	.byte 0x87, 0x81, 0xFF	@ 080A289D
env_28A0:
	.byte 0x01, 0xD0, 0x00, 0xF7	@ 080A28A0
env_28A4:
	.byte 0x01, 0xD0, 0x00, 0xF2	@ 080A28A4
env_28A8:
	.byte 0x60, 0x00, 0x80	@ 080A28A8
env_28AB:
	.byte 0x00, 0x02, 0x80	@ 080A28AB
env_28AE:
	.byte 0x0C, 0x0A, 0x80, 0x00, 0x00, 0xFF	@ 080A28AE
env_28B4:
	.byte 0x00, 0x90, 0xFF	@ 080A28B4
env_28B7:
	.byte 0x00, 0x8E, 0xFF	@ 080A28B7
env_28BA:
	.byte 0x00, 0x8C, 0xFF	@ 080A28BA
env_28BD:
	.byte 0x00, 0x8A, 0xFF	@ 080A28BD
env_28C0:
	.byte 0x00, 0x88, 0xFF	@ 080A28C0
env_28C3:
	.byte 0x00, 0x85, 0xFF	@ 080A28C3
env_28C6:
	.byte 0x12, 0x84, 0xFF, 0x00, 0xA0, 0xB7	@ 080A28C6
env_28CC:
	.byte 0x08, 0x84, 0xFF, 0x00, 0xA0, 0xDF	@ 080A28CC
env_28D2:
	.byte 0x01, 0xF0, 0x00, 0x00	@ 080A28D2
env_28D6:
	.byte 0x03, 0xF0, 0x03, 0xE0, 0x03, 0xD0, 0x03, 0xC0, 0x03, 0xB0, 0x03, 0xA0	@ 080A28D6
	.byte 0x03, 0x90, 0x03, 0x80, 0x03, 0x70, 0x03, 0x60, 0x03, 0x50, 0x03, 0x40	@ 080A28E2
	.byte 0x03, 0x30, 0x03, 0x20, 0x03, 0x10, 0x00, 0x00	@ 080A28EE
env_28F6:
	.byte 0x02, 0xF0, 0x02, 0xE0, 0x02, 0xD0, 0x02, 0xC0, 0x02, 0xB0, 0x02, 0xA0	@ 080A28F6
	.byte 0x02, 0x90, 0x02, 0x80, 0x02, 0x70, 0x02, 0x60, 0x02, 0x50, 0x02, 0x40	@ 080A2902
	.byte 0x02, 0x30, 0x02, 0x20, 0x02, 0x10, 0x00, 0x00	@ 080A290E
env_2916:
	.byte 0x01, 0xF0, 0x01, 0xE0, 0x01, 0xD0, 0x01, 0xC0, 0x01, 0xB0, 0x01, 0xA0	@ 080A2916
	.byte 0x01, 0x90, 0x01, 0x80, 0x01, 0x70, 0x01, 0x60, 0x01, 0x50, 0x01, 0x40	@ 080A2922
	.byte 0x01, 0x30, 0x01, 0x20, 0x01, 0x10, 0x00, 0x00	@ 080A292E
env_2936:
	.byte 0x00, 0x82, 0xFF	@ 080A2936
env_2939:
	.byte 0x00, 0xC0, 0xFF	@ 080A2939
env_293C:
	.byte 0x00, 0x86, 0xC0	@ 080A293C
env_293F:
	.byte 0x00, 0xA0, 0xC0	@ 080A293F
env_2942:
	.byte 0x00, 0x04, 0x80	@ 080A2942
env_2945:
	.byte 0x00, 0x20, 0x00	@ 080A2945
env_2948:
	.byte 0x04, 0x40, 0x00, 0x00, 0x82, 0xFF	@ 080A2948
env_294E:
	.byte 0x04, 0x90, 0x70, 0x00, 0x08, 0x40	@ 080A294E
env_2954:
	.byte 0x00, 0x01, 0x60	@ 080A2954
env_2957:
	.byte 0x00, 0x0F	@ 080A2957
env_2959:
	.byte 0x00, 0x0C	@ 080A2959
env_295B:
	.byte 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0, 0x00, 0xF4	@ 080A295B
env_2963:
	.byte 0x01, 0x90, 0x01, 0xA0, 0x01, 0xB0, 0x01, 0xC0, 0x01, 0xD0, 0x01, 0xE0	@ 080A2963
	.byte 0x00, 0xF0	@ 080A296F
env_2971:
	.byte 0xD0, 0x81, 0xFF, 0x00, 0x00, 0x1F	@ 080A2971
env_2977:
	.byte 0x80, 0x01, 0x80, 0x80, 0x81, 0xFF, 0x80, 0x01, 0x80, 0x80, 0x81, 0xFF	@ 080A2977
	.byte 0x80, 0x01, 0x80, 0x80, 0x81, 0xFF, 0x80, 0x01, 0x80, 0x80, 0x81, 0xFF	@ 080A2983
	.byte 0x00, 0x01, 0x80	@ 080A298F
env_2992:
	.byte 0x00, 0x10, 0x00	@ 080A2992
env_2995:
	.byte 0x00, 0x00, 0x00	@ 080A2995

@ ---- linker-generated Thumb->ARM interworking veneers (bx pc / nop / b target)
	.section .text.som_veneer, "ax", %progbits
	.thumb
	.global vnr_sndQueueSound_A4
vnr_sndQueueSound_A4:
	bx pc	@ 0836D8A4
	nop
	.arm
	b sndQueueSound	@ 0836D8A8
	.thumb
	.global vnr_sndInit_AC
vnr_sndInit_AC:
	bx pc	@ 0836D8AC
	nop
	.arm
	b sndInit	@ 0836D8B0
	.thumb
	.global vnr_sndFrame_B4
vnr_sndFrame_B4:
	bx pc	@ 0836D8B4
	nop
	.arm
	b sndFrame	@ 0836D8B8
	.thumb
	.global vnr_sndMixIrq_BC
vnr_sndMixIrq_BC:
	bx pc	@ 0836D8BC
	nop
	.arm
	b sndMixIrq	@ 0836D8C0
	.thumb
	.global vnr_sndMixIrq_C4
vnr_sndMixIrq_C4:
	bx pc	@ 0836D8C4
	nop
	.arm
	b sndMixIrq	@ 0836D8C8
	.thumb
	.global vnr_sndFadeOut_CC
vnr_sndFadeOut_CC:
	bx pc	@ 0836D8CC
	nop
	.arm
	b sndFadeOut	@ 0836D8D0
	.thumb
	.global vnr_sndFadeIn_D4
vnr_sndFadeIn_D4:
	bx pc	@ 0836D8D4
	nop
	.arm
	b sndFadeIn	@ 0836D8D8
