@ ===========================================================================
@  mvdk_sound_thumb.s  -  Mario vs. Donkey Kong (E) (M5), sound driver (Thumb part)
@  ROM 0x080725D8-0x08074F40 (10 600 bytes, 71 functions)
@
@  Nintendo Software Technology's driver for this game: an XM-style module player
@  and a sample SFX player that software-mix into a 16384 Hz 8-bit stereo stream
@  (FIFO A = left, FIFO B = right, Timer 1), plus an unused PSG sequencer.
@  GCC-compiled Thumb; the inner loops are ARM (mvdk_sound_arm.s) copied to IWRAM.
@
@  Host hook-up in the game:
@    sndInit(heap, 0x15A4, 3, 3, 8)   0x08031A54   3 SFX voices, 8 music voices
@    VBlank IRQ (0x08033E74):  sndVBlank() first, ... , sndFrame() last
@    DMA1 IRQ  -> sndDmaIrq      Timer 0 IRQ -> psgTimerIrq
@  Songs: musPlaySong(n, vol, loop) with n an index into musSongTable (70 songs).
@  SFX:   sfxPlay(id, flags, prio, pan, wide, vol, pitch), id into sfxTable (254).
@
@  All names are invented; the ROM has no symbols. Pseudo-C above each function
@  uses the structure fields defined in mvdk_sound.inc.
@  Build: make -f mvdk.mk check ROM="Mario vs. Donkey Kong (E) (M5).gba"
@ ===========================================================================

	.include "mvdk_sound.inc"
	.syntax unified
	.section .snd_thumb, "ax", %progbits
	.thumb

@ libgcc / BIOS helpers the driver calls (outside this range)
	.thumb_set _call_via_r0, 0x080758DC
	.thumb_set _call_via_r1, 0x080758E0
	.thumb_set _call_via_r2, 0x080758E4
	.thumb_set _call_via_r3, 0x080758E8
	.thumb_set _call_via_r4, 0x080758EC
	.thumb_set _call_via_r5, 0x080758F0
	.thumb_set __divsi3, 0x08075918
	.thumb_set __modsi3, 0x080759B0
	.thumb_set swiCpuSet, 0x08074F40
	.thumb_set swiLZ77UnCompVram, 0x08074F44
	.thumb_set swiLZ77UnCompWram, 0x08074F48

@ ============================================================================
@ void sfxMixVoice(SfxVoice *v, s16 *mix, int n)          [called by sndFrame]
@ Mixes one SFX voice into the 16-bit stereo mix buffer.
@   SfxEntry *e = v->sfx;  u32 end = e->length << 14;
@   int dry = v->vol * (128 - v->wide) >> 7;
@   int r = v->pan * dry >> 7,  l = (128 - v->pan) * dry >> 7;
@   if (v->wide > 4) {                       // stereo widening: second tap, see sfxMixVoiceWide
@       u32 p = sfxMixVoiceWide(v, mix, n);
@       if (dry == 0) { if (p >= end) v->flags = 0; else v->pos = p; return; }
@   }
@   MixArgs a = { mix, e->data, v->pos, v->step,
@                 (v->flags & 4) ? e->loopEnd << 14 : end,                  // loop / one-shot end
@                 (v->flags & 4) ? (e->loopEnd - e->loopStart) << 15 : 0,    // loop length*2, bit0 = 0 (forward)
@                 n, sndPanLaw[l], sndPanLaw[r] };
@   gSndMixSpanFn(&a);                        // sndArmB_MixSpan
@   v->pos = a.pos;
@   if (a.pos >= end) { v->flags = 0; musReleaseVoice(&gSnd->player, v - gSnd->voices); }
@ Note: when the dry volume is 0 and the wide tap ran, the voice ends without musReleaseVoice, so the
@ music voice it reserved stays reserved until another SFX uses and frees that slot.
@ ============================================================================
	thumb_func_start sfxMixVoice
sfxMixVoice: @ 0x080725D8
	push {r4, r5, r6, r7, lr}            @ 080725D8
	mov r7, sl                           @ 080725DA
	mov r6, sb                           @ 080725DC
	mov r5, r8                           @ 080725DE
	push {r5, r6, r7}                    @ 080725E0
	sub sp, #0x24                        @ 080725E2
	adds r4, r0, #0                      @ 080725E4
	mov sb, r1                           @ 080725E6
	mov sl, r2                           @ 080725E8
	ldr r0, [r4, #0x10]                  @ 080725EA
	ldr r0, [r0]                         @ 080725EC
	lsls r0, r0, #0xe                    @ 080725EE
	mov r8, r0                           @ 080725F0
	ldrb r2, [r4, #3]                    @ 080725F2
	ldrb r3, [r4, #2]                    @ 080725F4
	movs r1, #0x80                       @ 080725F6
	subs r0, r1, r3                      @ 080725F8
	muls r0, r2, r0                      @ 080725FA
	asrs r5, r0, #7                      @ 080725FC
	ldrb r6, [r4, #1]                    @ 080725FE
	subs r7, r1, r6                      @ 08072600
	adds r0, r6, #0                      @ 08072602
	muls r0, r5, r0                      @ 08072604
	asrs r6, r0, #7                      @ 08072606
	adds r0, r7, #0                      @ 08072608
	muls r0, r5, r0                      @ 0807260A
	asrs r7, r0, #7                      @ 0807260C
	cmp r3, #4                           @ 0807260E
	bls .L0807262C                       @ 08072610
	adds r0, r4, #0                      @ 08072612
	mov r1, sb                           @ 08072614
	mov r2, sl                           @ 08072616
	bl sfxMixVoiceWide                   @ 08072618
	cmp r5, #0                           @ 0807261C
	bne .L0807262C                       @ 0807261E
	cmp r0, r8                           @ 08072620
	blo .L08072628                       @ 08072622
	strb r5, [r4]                        @ 08072624
	b .L080726B6                         @ 08072626
.L08072628:
	str r0, [r4, #8]                     @ 08072628
	b .L080726B6                         @ 0807262A
.L0807262C:
	ldr r2, [r4, #0x10]                  @ 0807262C
	ldr r1, .Lp08072668                  @ 0807262E
	lsls r0, r7, #1                      @ 08072630
	adds r0, r0, r1                      @ 08072632
	ldrh r7, [r0]                        @ 08072634
	lsls r0, r6, #1                      @ 08072636
	adds r0, r0, r1                      @ 08072638
	ldrh r6, [r0]                        @ 0807263A
	mov r0, sb                           @ 0807263C
	str r0, [sp]                         @ 0807263E
	ldr r0, [r2, #4]                     @ 08072640
	str r0, [sp, #4]                     @ 08072642
	ldr r0, [r4, #8]                     @ 08072644
	str r0, [sp, #8]                     @ 08072646
	ldr r0, [r4, #0xc]                   @ 08072648
	str r0, [sp, #0xc]                   @ 0807264A
	ldrb r1, [r4]                        @ 0807264C
	movs r0, #4                          @ 0807264E
	ands r0, r1                          @ 08072650
	lsls r0, r0, #0x18                   @ 08072652
	lsrs r0, r0, #0x18                   @ 08072654
	cmp r0, #0                           @ 08072656
	beq .L0807266C                       @ 08072658
	ldr r0, [r2, #0x18]                  @ 0807265A
	lsls r1, r0, #0xe                    @ 0807265C
	str r1, [sp, #0x10]                  @ 0807265E
	ldr r1, [r2, #0x14]                  @ 08072660
	subs r0, r0, r1                      @ 08072662
	lsls r0, r0, #0xf                    @ 08072664
	b .L08072670                         @ 08072666
.Lp08072668:	.word sndPanLaw
.L0807266C:
	mov r1, r8                           @ 0807266C
	str r1, [sp, #0x10]                  @ 0807266E
.L08072670:
	str r0, [sp, #0x14]                  @ 08072670
	mov r2, sl                           @ 08072672
	str r2, [sp, #0x18]                  @ 08072674
	str r7, [sp, #0x1c]                  @ 08072676
	str r6, [sp, #0x20]                  @ 08072678
	ldr r0, .Lp080726C8                  @ 0807267A
	ldr r1, [r0]                         @ 0807267C
	mov r0, sp                           @ 0807267E
	bl _call_via_r1                      @ 08072680
	ldr r0, [sp, #8]                     @ 08072684
	str r0, [r4, #8]                     @ 08072686
	cmp r0, r8                           @ 08072688
	blo .L080726B6                       @ 0807268A
	movs r0, #0                          @ 0807268C
	strb r0, [r4]                        @ 0807268E
	ldr r0, .Lp080726CC                  @ 08072690
	ldr r1, [r0]                         @ 08072692
	ldr r3, .Lp080726D0                  @ 08072694
	adds r0, r1, r3                      @ 08072696
	ldr r3, .Lp080726D4                  @ 08072698
	adds r2, r4, r3                      @ 0807269A
	subs r2, r2, r1                      @ 0807269C
	lsls r1, r2, #1                      @ 0807269E
	adds r1, r1, r2                      @ 080726A0
	lsls r2, r1, #4                      @ 080726A2
	adds r1, r1, r2                      @ 080726A4
	lsls r2, r1, #8                      @ 080726A6
	adds r1, r1, r2                      @ 080726A8
	lsls r2, r1, #0x10                   @ 080726AA
	adds r1, r1, r2                      @ 080726AC
	rsbs r1, r1, #0                      @ 080726AE
	asrs r1, r1, #2                      @ 080726B0
	bl musReleaseVoice                   @ 080726B2
.L080726B6:
	add sp, #0x24                        @ 080726B6
	pop {r3, r4, r5}                     @ 080726B8
	mov r8, r3                           @ 080726BA
	mov sb, r4                           @ 080726BC
	mov sl, r5                           @ 080726BE
	pop {r4, r5, r6, r7}                 @ 080726C0
	pop {r0}                             @ 080726C2
	bx r0                                @ 080726C4
	.align 2, 0
.Lp080726C8:	.word gSndMixSpanFn
.Lp080726CC:	.word gSnd
.Lp080726D0:	.word SND_PLAYER
.Lp080726D4:	.word -SND_VOICES

@ ============================================================================
@ u32 sfxMixVoiceWide(SfxVoice *v, s16 *mix, int n)
@ The "wide" part of an SFX voice: the same sample, 1/4 sample ahead, at volume vol*wide/128, panned
@ towards the centre and with the right channel phase-inverted. Returns the new position of the dry tap.
@   int w = v->vol * v->wide >> 7;
@   int l = sndPanLaw[((128 - v->pan) / 2 + 64) * w >> 7];
@   int r = -sndPanLaw[(v->pan / 2 + 64) * w >> 7];
@   MixArgs a = { mix, e->data, v->pos + 0x1000, v->step, loop ? e->loopEnd << 14 : e->length << 14,
@                 loop ? (e->loopEnd - e->loopStart) << 15 : 0, n, l, r };
@   gSndMixSpanFn(&a);
@   return a.pos - 0x1000;
@ ============================================================================
	thumb_func_start sfxMixVoiceWide
sfxMixVoiceWide: @ 0x080726D8
	push {r4, r5, r6, r7, lr}            @ 080726D8
	mov r7, r8                           @ 080726DA
	push {r7}                            @ 080726DC
	sub sp, #0x24                        @ 080726DE
	mov r8, r2                           @ 080726E0
	ldr r7, [r0, #0x10]                  @ 080726E2
	ldr r2, [r7]                         @ 080726E4
	lsls r2, r2, #0xe                    @ 080726E6
	mov ip, r2                           @ 080726E8
	ldrb r3, [r0, #3]                    @ 080726EA
	ldrb r2, [r0, #2]                    @ 080726EC
	adds r4, r3, #0                      @ 080726EE
	muls r4, r2, r4                      @ 080726F0
	asrs r4, r4, #7                      @ 080726F2
	ldrb r3, [r0, #1]                    @ 080726F4
	movs r2, #0x80                       @ 080726F6
	subs r5, r2, r3                      @ 080726F8
	asrs r2, r5, #1                      @ 080726FA
	adds r5, r2, #0                      @ 080726FC
	adds r5, #0x40                       @ 080726FE
	lsrs r3, r3, #1                      @ 08072700
	adds r6, r3, #0                      @ 08072702
	adds r6, #0x40                       @ 08072704
	adds r2, r5, #0                      @ 08072706
	muls r2, r4, r2                      @ 08072708
	asrs r5, r2, #7                      @ 0807270A
	adds r2, r6, #0                      @ 0807270C
	muls r2, r4, r2                      @ 0807270E
	asrs r6, r2, #7                      @ 08072710
	ldr r3, .Lp08072754                  @ 08072712
	lsls r2, r5, #1                      @ 08072714
	adds r2, r2, r3                      @ 08072716
	ldrh r5, [r2]                        @ 08072718
	lsls r2, r6, #1                      @ 0807271A
	adds r2, r2, r3                      @ 0807271C
	ldrh r2, [r2]                        @ 0807271E
	rsbs r6, r2, #0                      @ 08072720
	str r1, [sp]                         @ 08072722
	ldr r1, [r7, #4]                     @ 08072724
	str r1, [sp, #4]                     @ 08072726
	ldr r1, [r0, #8]                     @ 08072728
	movs r2, #0x80                       @ 0807272A
	lsls r2, r2, #5                      @ 0807272C
	adds r1, r1, r2                      @ 0807272E
	str r1, [sp, #8]                     @ 08072730
	ldr r1, [r0, #0xc]                   @ 08072732
	str r1, [sp, #0xc]                   @ 08072734
	ldrb r1, [r0]                        @ 08072736
	movs r0, #4                          @ 08072738
	ands r0, r1                          @ 0807273A
	lsls r0, r0, #0x18                   @ 0807273C
	lsrs r0, r0, #0x18                   @ 0807273E
	cmp r0, #0                           @ 08072740
	beq .L08072758                       @ 08072742
	ldr r0, [r7, #0x18]                  @ 08072744
	lsls r1, r0, #0xe                    @ 08072746
	str r1, [sp, #0x10]                  @ 08072748
	ldr r1, [r7, #0x14]                  @ 0807274A
	subs r0, r0, r1                      @ 0807274C
	lsls r0, r0, #0xf                    @ 0807274E
	b .L0807275C                         @ 08072750
	.align 2, 0
.Lp08072754:	.word sndPanLaw
.L08072758:
	mov r1, ip                           @ 08072758
	str r1, [sp, #0x10]                  @ 0807275A
.L0807275C:
	str r0, [sp, #0x14]                  @ 0807275C
	mov r2, r8                           @ 0807275E
	str r2, [sp, #0x18]                  @ 08072760
	str r5, [sp, #0x1c]                  @ 08072762
	str r6, [sp, #0x20]                  @ 08072764
	ldr r0, .Lp08072784                  @ 08072766
	ldr r1, [r0]                         @ 08072768
	mov r0, sp                           @ 0807276A
	bl _call_via_r1                      @ 0807276C
	ldr r0, [sp, #8]                     @ 08072770
	ldr r1, .Lp08072788                  @ 08072772
	adds r0, r0, r1                      @ 08072774
	str r0, [sp, #8]                     @ 08072776
	add sp, #0x24                        @ 08072778
	pop {r3}                             @ 0807277A
	mov r8, r3                           @ 0807277C
	pop {r4, r5, r6, r7}                 @ 0807277E
	pop {r1}                             @ 08072780
	bx r1                                @ 08072782
.Lp08072784:	.word gSndMixSpanFn
.Lp08072788:	.word 0xFFFFF000

@ ============================================================================
@ void sndInit(void *heap, u32 heapSize, int nSfxVoices, u8 unused, u8 maxMusicVoices)
@ MvDK: sndInit(malloc(0x15A4), 0x15A4, 3, 3, 8) at 0x08031A54.
@   if (!nSfxVoices) nSfxVoices = 1;
@   sndHeapInit(heap, heapSize);
@   s = gSnd = sndHeapAlloc(SND_STATE_SIZE + (nSfxVoices - 1) * VC_SIZE);
@   s->player.maxVoices = maxMusicVoices;
@   gSndClearFn = (u8*)s + SND_ARMA;   DMA3: copy 0x74 halfwords from sndArmA_Clear32 (0xE8 bytes; the last
@   gSndDownmixFn / gSndDmaIrqFn        12 are the start of the unused sndArmA_OldMixSpan)
@   gSndMixSpanFn = (u8*)s + SND_ARMB; DMA3: copy 0x1C8 halfwords from sndArmB_MixSpan (0x390 bytes; the
@   gSndMixChannelFn                    last 0x2C bytes are unrelated Thumb code that follows it in ROM)
@   s->nVoices = nSfxVoices; s->unused4 = maxMusicVoices; s->unused3 = unused;
@   s->flags = 0x12 (stereo, "swapped"); s->playBuf = s->nextBuf = s->lastMixed = 2; s->mixBuf = 0;
@   s->irqCount = 18;
@   SOUNDCNT_X = 0x80; SOUNDCNT_L = 0;
@   SOUNDCNT_H = 0xDE0C          // FIFO A -> left only, FIFO B -> right only, both 100 %, both Timer 1
@   DMA1DAD = FIFO_A; DMA2DAD = FIFO_B; DMA1SAD = buffers[2].L; DMA2SAD = buffers[2].R;
@   DMA1CNT = DMA2CNT = 0xF6600004 // enable, IRQ, FIFO timing, 32-bit, repeat
@   TM1CNT = 0x0080FC00           // 16 777 216 / 1024 = 16 384 Hz
@   REG_IE |= 0x600               // DMA1 and DMA2 IRQ (the game routes DMA2 to a dummy handler)
@   psgInit();
@ ============================================================================
	thumb_func_start sndInit
sndInit: @ 0x0807278C
	push {r4, r5, r6, r7, lr}            @ 0807278C
	mov r7, sb                           @ 0807278E
	mov r6, r8                           @ 08072790
	push {r6, r7}                        @ 08072792
	adds r7, r2, #0                      @ 08072794
	mov sb, r3                           @ 08072796
	cmp r7, #0                           @ 08072798
	bne .L0807279E                       @ 0807279A
	movs r7, #1                          @ 0807279C
.L0807279E:
	bl sndHeapInit                       @ 0807279E
	ldr r5, .Lp080728B0                  @ 080727A2
	subs r1, r7, #1                      @ 080727A4
	lsls r0, r1, #2                      @ 080727A6
	adds r0, r0, r1                      @ 080727A8
	lsls r0, r0, #2                      @ 080727AA
	ldr r1, .Lp080728B4                  @ 080727AC
	adds r0, r0, r1                      @ 080727AE
	bl sndHeapAlloc                      @ 080727B0
	str r0, [r5]                         @ 080727B4
	ldr r2, .Lp080728B8                  @ 080727B6
	adds r0, r0, r2                      @ 080727B8
	movs r3, #0                          @ 080727BA
	mov r8, r3                           @ 080727BC
	mov r1, sp                           @ 080727BE
	ldrb r1, [r1, #0x1c]                 @ 080727C0
	strb r1, [r0]                        @ 080727C2
	ldr r0, .Lp080728BC                  @ 080727C4
	ldr r6, [r5]                         @ 080727C6
	movs r3, #0xb5                       @ 080727C8
	lsls r3, r3, #4                      @ 080727CA
	adds r2, r6, r3                      @ 080727CC
	str r2, [r0]                         @ 080727CE
	ldr r1, .Lp080728C0                  @ 080727D0
	ldr r3, .Lp080728C4                  @ 080727D2
	str r3, [r1]                         @ 080727D4
	str r2, [r1, #4]                     @ 080727D6
	ldr r0, .Lp080728C8                  @ 080727D8
	str r0, [r1, #8]                     @ 080727DA
	ldr r0, [r1, #8]                     @ 080727DC
	ldr r4, .Lp080728CC                  @ 080727DE
	ldr r0, .Lp080728D0                  @ 080727E0
	subs r0, r0, r3                      @ 080727E2
	adds r0, r2, r0                      @ 080727E4
	str r0, [r4]                         @ 080727E6
	ldr r4, .Lp080728D4                  @ 080727E8
	ldr r0, .Lp080728D8                  @ 080727EA
	subs r0, r0, r3                      @ 080727EC
	adds r2, r2, r0                      @ 080727EE
	str r2, [r4]                         @ 080727F0
	ldr r0, .Lp080728DC                  @ 080727F2
	ldr r3, .Lp080728E0                  @ 080727F4
	adds r2, r6, r3                      @ 080727F6
	str r2, [r0]                         @ 080727F8
	ldr r3, .Lp080728E4                  @ 080727FA
	str r3, [r1]                         @ 080727FC
	str r2, [r1, #4]                     @ 080727FE
	ldr r0, .Lp080728E8                  @ 08072800
	str r0, [r1, #8]                     @ 08072802
	ldr r0, [r1, #8]                     @ 08072804
	ldr r1, .Lp080728EC                  @ 08072806
	ldr r0, .Lp080728F0                  @ 08072808
	subs r0, r0, r3                      @ 0807280A
	adds r2, r2, r0                      @ 0807280C
	str r2, [r1]                         @ 0807280E
	strb r7, [r6]                        @ 08072810
	ldr r0, [r5]                         @ 08072812
	mov r1, sp                           @ 08072814
	ldrb r1, [r1, #0x1c]                 @ 08072816
	strb r1, [r0, #4]                    @ 08072818
	ldr r0, [r5]                         @ 0807281A
	mov r2, sb                           @ 0807281C
	strb r2, [r0, #3]                    @ 0807281E
	ldr r0, [r5]                         @ 08072820
	movs r2, #0x12                       @ 08072822
	strb r2, [r0, #1]                    @ 08072824
	ldr r1, [r5]                         @ 08072826
	movs r0, #2                          @ 08072828
	strb r0, [r1, #7]                    @ 0807282A
	strb r0, [r1, #6]                    @ 0807282C
	strb r0, [r1, #8]                    @ 0807282E
	ldr r0, [r5]                         @ 08072830
	mov r3, r8                           @ 08072832
	strb r3, [r0, #5]                    @ 08072834
	ldr r0, [r5]                         @ 08072836
	strb r2, [r0, #2]                    @ 08072838
	ldr r1, .Lp080728F4                  @ 0807283A
	movs r0, #0x80                       @ 0807283C
	strh r0, [r1]                        @ 0807283E
	ldr r0, .Lp080728F8                  @ 08072840
	mov r1, r8                           @ 08072842
	strh r1, [r0]                        @ 08072844
	ldr r1, .Lp080728FC                  @ 08072846
	ldr r2, .Lp08072900                  @ 08072848
	adds r0, r2, #0                      @ 0807284A
	strh r0, [r1]                        @ 0807284C
	adds r1, #0x3e                       @ 0807284E
	ldr r0, .Lp08072904                  @ 08072850
	str r0, [r1]                         @ 08072852
	adds r1, #0xc                        @ 08072854
	adds r0, #4                          @ 08072856
	str r0, [r1]                         @ 08072858
	ldr r3, .Lp08072908                  @ 0807285A
	ldr r1, [r5]                         @ 0807285C
	ldrb r2, [r1, #6]                    @ 0807285E
	lsls r0, r2, #3                      @ 08072860
	adds r0, r0, r2                      @ 08072862
	lsls r0, r0, #6                      @ 08072864
	adds r0, #0x10                       @ 08072866
	adds r0, r1, r0                      @ 08072868
	str r0, [r3]                         @ 0807286A
	adds r3, #0xc                        @ 0807286C
	ldrb r2, [r1, #6]                    @ 0807286E
	lsls r0, r2, #3                      @ 08072870
	adds r0, r0, r2                      @ 08072872
	lsls r0, r0, #6                      @ 08072874
	adds r0, #0x10                       @ 08072876
	adds r1, r1, r0                      @ 08072878
	movs r0, #0x90                       @ 0807287A
	lsls r0, r0, #1                      @ 0807287C
	adds r1, r1, r0                      @ 0807287E
	str r1, [r3]                         @ 08072880
	ldr r0, .Lp0807290C                  @ 08072882
	ldr r1, .Lp08072910                  @ 08072884
	str r1, [r0]                         @ 08072886
	adds r0, #0xc                        @ 08072888
	str r1, [r0]                         @ 0807288A
	ldr r1, .Lp08072914                  @ 0807288C
	ldr r0, .Lp08072918                  @ 0807288E
	str r0, [r1]                         @ 08072890
	ldr r2, .Lp0807291C                  @ 08072892
	ldrh r0, [r2]                        @ 08072894
	movs r3, #0xc0                       @ 08072896
	lsls r3, r3, #3                      @ 08072898
	adds r1, r3, #0                      @ 0807289A
	orrs r0, r1                          @ 0807289C
	strh r0, [r2]                        @ 0807289E
	bl psgInit                           @ 080728A0
	pop {r3, r4}                         @ 080728A4
	mov r8, r3                           @ 080728A6
	mov sb, r4                           @ 080728A8
	pop {r4, r5, r6, r7}                 @ 080728AA
	pop {r0}                             @ 080728AC
	bx r0                                @ 080728AE
.Lp080728B0:	.word gSnd
.Lp080728B4:	.word SND_STATE_SIZE
.Lp080728B8:	.word SND_PLAYER+PL_maxVoices
.Lp080728BC:	.word gSndClearFn
.Lp080728C0:	.word REG_DMA3SAD
.Lp080728C4:	.word sndArmA_Clear32
.Lp080728C8:	.word 0x80000074
.Lp080728CC:	.word gSndDownmixFn
.Lp080728D0:	.word sndArmA_Downmix
.Lp080728D4:	.word gSndDmaIrqFn
.Lp080728D8:	.word sndArmA_DmaIrq
.Lp080728DC:	.word gSndMixSpanFn
.Lp080728E0:	.word SND_ARMB
.Lp080728E4:	.word sndArmB_MixSpan
.Lp080728E8:	.word 0x800001C8
.Lp080728EC:	.word gSndMixChannelFn
.Lp080728F0:	.word sndArmB_MixChannel
.Lp080728F4:	.word REG_SOUNDCNT_X
.Lp080728F8:	.word REG_SOUNDCNT_L
.Lp080728FC:	.word REG_SOUNDCNT_H
.Lp08072900:	.word 0x0000DE0C
.Lp08072904:	.word REG_FIFO_A
.Lp08072908:	.word REG_DMA1SAD
.Lp0807290C:	.word REG_DMA1CNT
.Lp08072910:	.word 0xF6600004
.Lp08072914:	.word REG_TM1CNT
.Lp08072918:	.word 0x0080FC00
.Lp0807291C:	.word REG_IE

@ ============================================================================
@ void sndFrame(void)                                      [end of the game's VBlank IRQ, 0x08033EFC]
@ Mixes one 288-sample buffer. Runs only when the DMA swapped buffers since the previous VBlank.
@   s = gSnd;
@   if (!s || (s->flags & 1) || (s->flags & 8)) return;
@   b = s->mixBuf; mix = s->mix16; s->flags |= 8;
@   t = gSndCpuTimer;                                       // profiling, the timer is never written
@   gSndClearFn(mix, 288);
@   if (s->player.order != -1 && s->player.module)
@       for (i = 0; i < 288; ) i += musMix(&s->player, mix + 2 * i, 288 - i);
@   for (k = 0; k < s->nVoices; k++)
@       if ((s->voices[k].flags & 3) && (s->voices[k].flags & 1)) sfxMixVoice(&s->voices[k], mix, 288);
@   gSndDownmixFn(mix, s->buffers[b].L, s->buffers[b].R, 288);
@   s->lastMixed = b;  s->mixBuf = (b + 1 > 2) ? 0 : b + 1;
@   gSndCpuLast = gSndCpuTimer - t; gSndCpuTotal += gSndCpuLast;
@   s->flags &= ~8;
@ ============================================================================
	thumb_func_start sndFrame
sndFrame: @ 0x08072920
	push {r4, r5, r6, r7, lr}            @ 08072920
	mov r7, sl                           @ 08072922
	mov r6, sb                           @ 08072924
	mov r5, r8                           @ 08072926
	push {r5, r6, r7}                    @ 08072928
	sub sp, #8                           @ 0807292A
	ldr r6, .Lp08072A48                  @ 0807292C
	ldr r4, [r6]                         @ 0807292E
	cmp r4, #0                           @ 08072930
	bne .L08072936                       @ 08072932
	b .L08072A36                         @ 08072934
.L08072936:
	ldrb r2, [r4, #1]                    @ 08072936
	movs r0, #1                          @ 08072938
	ands r0, r2                          @ 0807293A
	cmp r0, #0                           @ 0807293C
	bne .L08072A36                       @ 0807293E
	movs r0, #8                          @ 08072940
	ands r0, r2                          @ 08072942
	cmp r0, #0                           @ 08072944
	bne .L08072A36                       @ 08072946
	ldrb r5, [r4, #5]                    @ 08072948
	movs r0, #0xda                       @ 0807294A
	lsls r0, r0, #3                      @ 0807294C
	adds r0, r0, r4                      @ 0807294E
	mov r8, r0                           @ 08072950
	lsls r0, r5, #3                      @ 08072952
	adds r0, r0, r5                      @ 08072954
	lsls r0, r0, #6                      @ 08072956
	adds r0, #0x10                       @ 08072958
	adds r0, r0, r4                      @ 0807295A
	mov sl, r0                           @ 0807295C
	movs r1, #0x90                       @ 0807295E
	lsls r1, r1, #1                      @ 08072960
	mov r3, sl                           @ 08072962
	adds r3, r3, r1                      @ 08072964
	str r3, [sp]                         @ 08072966
	ldr r0, .Lp08072A4C                  @ 08072968
	ldr r0, [r0]                         @ 0807296A
	str r0, [sp, #4]                     @ 0807296C
	adds r7, r1, #0                      @ 0807296E
	movs r0, #8                          @ 08072970
	orrs r0, r2                          @ 08072972
	strb r0, [r4, #1]                    @ 08072974
	ldr r0, .Lp08072A50                  @ 08072976
	ldr r2, [r0]                         @ 08072978
	mov r0, r8                           @ 0807297A
	bl _call_via_r2                      @ 0807297C
	ldr r2, [r6]                         @ 08072980
	ldr r1, .Lp08072A54                  @ 08072982
	adds r0, r2, r1                      @ 08072984
	movs r3, #0                          @ 08072986
	ldrsh r1, [r0, r3]                   @ 08072988
	movs r0, #1                          @ 0807298A
	rsbs r0, r0, #0                      @ 0807298C
	cmp r1, r0                           @ 0807298E
	beq .L080729B6                       @ 08072990
	ldr r1, .Lp08072A58                  @ 08072992
	adds r0, r2, r1                      @ 08072994
	ldr r0, [r0]                         @ 08072996
	cmp r0, #0                           @ 08072998
	beq .L080729B6                       @ 0807299A
	movs r4, #0                          @ 0807299C
.L0807299E:
	ldr r0, .Lp08072A48                  @ 0807299E
	ldr r0, [r0]                         @ 080729A0
	ldr r2, .Lp08072A58                  @ 080729A2
	adds r0, r0, r2                      @ 080729A4
	lsls r1, r4, #2                      @ 080729A6
	add r1, r8                           @ 080729A8
	subs r2, r7, r4                      @ 080729AA
	bl musMix                            @ 080729AC
	adds r4, r4, r0                      @ 080729B0
	cmp r4, r7                           @ 080729B2
	blo .L0807299E                       @ 080729B4
.L080729B6:
	movs r4, #0                          @ 080729B6
	ldr r1, .Lp08072A48                  @ 080729B8
	ldr r0, [r1]                         @ 080729BA
	adds r3, r5, #1                      @ 080729BC
	mov sb, r3                           @ 080729BE
	ldrb r0, [r0]                        @ 080729C0
	cmp r4, r0                           @ 080729C2
	bhs .L080729F6                       @ 080729C4
	ldr r6, .Lp08072A5C                  @ 080729C6
.L080729C8:
	ldr r0, [r1]                         @ 080729C8
	adds r2, r0, r6                      @ 080729CA
	ldrb r1, [r2]                        @ 080729CC
	movs r0, #3                          @ 080729CE
	ands r0, r1                          @ 080729D0
	cmp r0, #0                           @ 080729D2
	beq .L080729E8                       @ 080729D4
	movs r0, #1                          @ 080729D6
	ands r0, r1                          @ 080729D8
	cmp r0, #0                           @ 080729DA
	beq .L080729E8                       @ 080729DC
	adds r0, r2, #0                      @ 080729DE
	mov r1, r8                           @ 080729E0
	adds r2, r7, #0                      @ 080729E2
	bl sfxMixVoice                       @ 080729E4
.L080729E8:
	adds r6, #0x14                       @ 080729E8
	adds r4, #1                          @ 080729EA
	ldr r1, .Lp08072A48                  @ 080729EC
	ldr r0, [r1]                         @ 080729EE
	ldrb r0, [r0]                        @ 080729F0
	cmp r4, r0                           @ 080729F2
	blo .L080729C8                       @ 080729F4
.L080729F6:
	ldr r0, .Lp08072A60                  @ 080729F6
	ldr r4, [r0]                         @ 080729F8
	mov r0, r8                           @ 080729FA
	mov r1, sl                           @ 080729FC
	ldr r2, [sp]                         @ 080729FE
	adds r3, r7, #0                      @ 08072A00
	bl _call_via_r4                      @ 08072A02
	ldr r3, .Lp08072A48                  @ 08072A06
	ldr r0, [r3]                         @ 08072A08
	strb r5, [r0, #8]                    @ 08072A0A
	mov r5, sb                           @ 08072A0C
	cmp r5, #2                           @ 08072A0E
	bls .L08072A14                       @ 08072A10
	movs r5, #0                          @ 08072A12
.L08072A14:
	ldr r0, [r3]                         @ 08072A14
	strb r5, [r0, #5]                    @ 08072A16
	ldr r2, .Lp08072A64                  @ 08072A18
	ldr r0, .Lp08072A4C                  @ 08072A1A
	ldr r1, [r0]                         @ 08072A1C
	ldr r0, [sp, #4]                     @ 08072A1E
	subs r1, r1, r0                      @ 08072A20
	str r1, [r2]                         @ 08072A22
	ldr r2, .Lp08072A68                  @ 08072A24
	ldr r0, [r2]                         @ 08072A26
	adds r0, r0, r1                      @ 08072A28
	str r0, [r2]                         @ 08072A2A
	ldr r2, [r3]                         @ 08072A2C
	ldrb r1, [r2, #1]                    @ 08072A2E
	movs r0, #0xf7                       @ 08072A30
	ands r0, r1                          @ 08072A32
	strb r0, [r2, #1]                    @ 08072A34
.L08072A36:
	add sp, #8                           @ 08072A36
	pop {r3, r4, r5}                     @ 08072A38
	mov r8, r3                           @ 08072A3A
	mov sb, r4                           @ 08072A3C
	mov sl, r5                           @ 08072A3E
	pop {r4, r5, r6, r7}                 @ 08072A40
	pop {r0}                             @ 08072A42
	bx r0                                @ 08072A44
	.align 2, 0
.Lp08072A48:	.word gSnd
.Lp08072A4C:	.word gSndCpuTimer
.Lp08072A50:	.word gSndClearFn
.Lp08072A54:	.word SND_PLAYER+PL_order
.Lp08072A58:	.word SND_PLAYER
.Lp08072A5C:	.word SND_VOICES
.Lp08072A60:	.word gSndDownmixFn
.Lp08072A64:	.word gSndCpuLast
.Lp08072A68:	.word gSndCpuTotal

@ ============================================================================
@ void sndVBlank(void)                                     [start of the game's VBlank IRQ, 0x08033E8C]
@   s = gSnd; if (!s) return;
@   if (s->flags & 2) {                  // the DMA IRQ swapped buffers since the last VBlank
@       s->flags &= ~3;
@       s->nextBuf = s->lastMixed;       // queue the newest buffer for the next swap
@   } else {
@       s->flags |= 1;                   // nothing was consumed: sndFrame will skip this frame
@       if (!(s->flags & 4)) sndDmaStart();
@   }
@ ============================================================================
	thumb_func_start sndVBlank
sndVBlank: @ 0x08072A6C
	push {lr}                            @ 08072A6C
	ldr r1, .Lp08072A90                  @ 08072A6E
	ldr r3, [r1]                         @ 08072A70
	cmp r3, #0                           @ 08072A72
	beq .L08072AAA                       @ 08072A74
	ldrb r2, [r3, #1]                    @ 08072A76
	movs r0, #2                          @ 08072A78
	ands r0, r2                          @ 08072A7A
	cmp r0, #0                           @ 08072A7C
	beq .L08072A94                       @ 08072A7E
	movs r0, #0xfc                       @ 08072A80
	ands r0, r2                          @ 08072A82
	strb r0, [r3, #1]                    @ 08072A84
	ldr r1, [r1]                         @ 08072A86
	ldrb r0, [r1, #8]                    @ 08072A88
	strb r0, [r1, #7]                    @ 08072A8A
	b .L08072AAA                         @ 08072A8C
	.align 2, 0
.Lp08072A90:	.word gSnd
.L08072A94:
	movs r0, #1                          @ 08072A94
	orrs r0, r2                          @ 08072A96
	strb r0, [r3, #1]                    @ 08072A98
	ldr r0, [r1]                         @ 08072A9A
	ldrb r1, [r0, #1]                    @ 08072A9C
	movs r0, #4                          @ 08072A9E
	ands r0, r1                          @ 08072AA0
	cmp r0, #0                           @ 08072AA2
	bne .L08072AAA                       @ 08072AA4
	bl sndDmaStart                       @ 08072AA6
.L08072AAA:
	pop {r0}                             @ 08072AAA
	bx r0                                @ 08072AAC
	.align 2, 0

@ ============================================================================
@ int sfxPlay(int id, u8 flags, u8 prio, u8 pan, u8 wide, int vol, int pitch)    [366 call sites]
@ flags: 4 = loop, 8 = restart the voice if this SFX is already playing,
@        0x10 = if already playing, return its handle instead of starting another.
@ prio: 0..15 (> 15 = the entry's default). pitch: 0 = entry rate, > 0 = rate*pitch/8192, < 0 = -pitch Hz.
@ Returns the voice handle, or -1.
@   SfxEntry *e = &sfxTable[id];
@   if (prio > 15) prio = e->prio;
@   if (!(s->flags & 0x10)) { pan = 64; wide = 0; }         // mono
@   if (e->length == 1) { sfxStopPriority(prio, 0); return -1; }   // "stop" entries (24 in MvDK)
@   step = pitch == 0 ? e->rate : pitch > 0 ? e->rate * pitch >> 13 : -pitch;
@   vol = vol * e->volume >> 7;
@   prio <<= 4;
@   if (flags & 0x18) {
@       for each voice v:
@           if (v active) {
@               if (v->sfx == e) { if (flags & 8) { pick = v; break; } return v->handle; }
@               if (no free voice seen yet && (v->flags & 0xF0) < best) { best = v->flags & 0xF0; pick = v; }
@           } else if (no free voice seen yet) { pick = v; free seen = 1; }
@   } else {
@       for each voice v: if (!active) { pick = v; break; }
@                         if ((v->flags & 0xF0) < best) { best = v->flags & 0xF0; pick = v; }
@   }
@   if (!pick) return -1;                     // (best starts at prio: only lower priorities are stolen)
@   pick->sfx = e; pick->pan = pan; pick->wide = wide;
@   pick->flags = prio | 1 | ((flags & 0x18) ? flags & 4 : flags);   // 2nd path ORs the whole flags byte
@   pick->vol = vol; pick->pos = 0; pick->step = step << 14 >> 14;
@   pick->handle = s->handleSeq++ & 0x7FFFFFFF;
@   musReserveVoice(&s->player, pick - s->voices);          // the SFX takes a music mixing voice
@   return pick->handle;
@ ============================================================================
	thumb_func_start sfxPlay
sfxPlay: @ 0x08072AB0
	push {r4, r5, r6, r7, lr}            @ 08072AB0
	mov r7, sl                           @ 08072AB2
	mov r6, sb                           @ 08072AB4
	mov r5, r8                           @ 08072AB6
	push {r5, r6, r7}                    @ 08072AB8
	sub sp, #0x14                        @ 08072ABA
	ldr r4, [sp, #0x34]                  @ 08072ABC
	ldr r5, [sp, #0x3c]                  @ 08072ABE
	mov r8, r5                           @ 08072AC0
	lsls r1, r1, #0x18                   @ 08072AC2
	lsrs r1, r1, #0x18                   @ 08072AC4
	str r1, [sp]                         @ 08072AC6
	lsls r2, r2, #0x18                   @ 08072AC8
	lsrs r5, r2, #0x18                   @ 08072ACA
	lsls r3, r3, #0x18                   @ 08072ACC
	lsrs r3, r3, #0x18                   @ 08072ACE
	str r3, [sp, #4]                     @ 08072AD0
	lsls r4, r4, #0x18                   @ 08072AD2
	lsrs r4, r4, #0x18                   @ 08072AD4
	str r4, [sp, #8]                     @ 08072AD6
	movs r1, #0                          @ 08072AD8
	mov sb, r1                           @ 08072ADA
	ldr r2, .Lp08072B1C                  @ 08072ADC
	ldr r6, [r2]                         @ 08072ADE
	ldrb r3, [r6]                        @ 08072AE0
	mov sl, r3                           @ 08072AE2
	str r1, [sp, #0xc]                   @ 08072AE4
	lsls r1, r0, #3                      @ 08072AE6
	subs r1, r1, r0                      @ 08072AE8
	lsls r1, r1, #2                      @ 08072AEA
	ldr r0, .Lp08072B20                  @ 08072AEC
	adds r1, r1, r0                      @ 08072AEE
	mov ip, r1                           @ 08072AF0
	cmp r5, #0xf                         @ 08072AF2
	bls .L08072AF8                       @ 08072AF4
	ldrb r5, [r1, #0x12]                 @ 08072AF6
.L08072AF8:
	ldrb r1, [r6, #1]                    @ 08072AF8
	movs r0, #0x10                       @ 08072AFA
	ands r0, r1                          @ 08072AFC
	cmp r0, #0                           @ 08072AFE
	bne .L08072B0A                       @ 08072B00
	movs r2, #0x40                       @ 08072B02
	str r2, [sp, #4]                     @ 08072B04
	movs r3, #0                          @ 08072B06
	str r3, [sp, #8]                     @ 08072B08
.L08072B0A:
	mov r1, ip                           @ 08072B0A
	ldr r0, [r1]                         @ 08072B0C
	cmp r0, #1                           @ 08072B0E
	bne .L08072B24                       @ 08072B10
	adds r0, r5, #0                      @ 08072B12
	movs r1, #0                          @ 08072B14
	bl sfxStopPriority                   @ 08072B16
	b .L08072CD8                         @ 08072B1A
.Lp08072B1C:	.word gSnd
.Lp08072B20:	.word sfxTable
.L08072B24:
	lsls r0, r5, #0x1c                   @ 08072B24
	lsrs r5, r0, #0x18                   @ 08072B26
	adds r7, r5, #0                      @ 08072B28
	ldr r2, .Lp08072B3C                  @ 08072B2A
	adds r3, r6, r2                      @ 08072B2C
	mov r0, r8                           @ 08072B2E
	cmp r0, #0                           @ 08072B30
	bne .L08072B40                       @ 08072B32
	mov r1, ip                           @ 08072B34
	ldr r1, [r1, #8]                     @ 08072B36
	mov r8, r1                           @ 08072B38
	b .L08072B5E                         @ 08072B3A
.Lp08072B3C:	.word SND_VOICES
.L08072B40:
	mov r2, r8                           @ 08072B40
	cmp r2, #0                           @ 08072B42
	ble .L08072B54                       @ 08072B44
	mov r1, ip                           @ 08072B46
	ldr r0, [r1, #8]                     @ 08072B48
	mov r2, r8                           @ 08072B4A
	muls r2, r0, r2                      @ 08072B4C
	adds r0, r2, #0                      @ 08072B4E
	lsrs r0, r0, #0xd                    @ 08072B50
	b .L08072B5C                         @ 08072B52
.L08072B54:
	mov r0, r8                           @ 08072B54
	cmp r0, #0                           @ 08072B56
	bge .L08072B5E                       @ 08072B58
	rsbs r0, r0, #0                      @ 08072B5A
.L08072B5C:
	mov r8, r0                           @ 08072B5C
.L08072B5E:
	mov r1, ip                           @ 08072B5E
	ldrh r0, [r1, #0x10]                 @ 08072B60
	ldr r2, [sp, #0x38]                  @ 08072B62
	muls r0, r2, r0                      @ 08072B64
	lsrs r0, r0, #7                      @ 08072B66
	str r0, [sp, #0x38]                  @ 08072B68
	movs r0, #0x18                       @ 08072B6A
	ldr r1, [sp]                         @ 08072B6C
	ands r0, r1                          @ 08072B6E
	cmp r0, #0                           @ 08072B70
	beq .L08072C30                       @ 08072B72
	movs r6, #0                          @ 08072B74
	cmp r6, sl                           @ 08072B76
	bhs .L08072BCA                       @ 08072B78
	movs r0, #8                          @ 08072B7A
	ands r0, r1                          @ 08072B7C
	lsls r0, r0, #0x18                   @ 08072B7E
	lsrs r0, r0, #0x18                   @ 08072B80
	str r0, [sp, #0x10]                  @ 08072B82
.L08072B84:
	adds r4, r3, #0                      @ 08072B84
	ldrb r2, [r4]                        @ 08072B86
	movs r0, #3                          @ 08072B88
	ands r0, r2                          @ 08072B8A
	cmp r0, #0                           @ 08072B8C
	beq .L08072BB6                       @ 08072B8E
	movs r1, #0xf0                       @ 08072B90
	ands r1, r2                          @ 08072B92
	ldr r0, [r4, #0x10]                  @ 08072B94
	cmp r0, ip                           @ 08072B96
	bne .L08072BA6                       @ 08072B98
	ldr r2, [sp, #0x10]                  @ 08072B9A
	cmp r2, #0                           @ 08072B9C
	bne .L08072BA2                       @ 08072B9E
	b .L08072CD4                         @ 08072BA0
.L08072BA2:
	mov sb, r4                           @ 08072BA2
	b .L08072BCA                         @ 08072BA4
.L08072BA6:
	ldr r0, [sp, #0xc]                   @ 08072BA6
	cmp r0, #0                           @ 08072BA8
	bne .L08072BC2                       @ 08072BAA
	cmp r1, r7                           @ 08072BAC
	bhs .L08072BC2                       @ 08072BAE
	adds r7, r1, #0                      @ 08072BB0
	mov sb, r4                           @ 08072BB2
	b .L08072BC2                         @ 08072BB4
.L08072BB6:
	ldr r1, [sp, #0xc]                   @ 08072BB6
	cmp r1, #0                           @ 08072BB8
	bne .L08072BC2                       @ 08072BBA
	mov sb, r4                           @ 08072BBC
	movs r2, #1                          @ 08072BBE
	str r2, [sp, #0xc]                   @ 08072BC0
.L08072BC2:
	adds r6, #1                          @ 08072BC2
	adds r3, #0x14                       @ 08072BC4
	cmp r6, sl                           @ 08072BC6
	blo .L08072B84                       @ 08072BC8
.L08072BCA:
	mov r3, sb                           @ 08072BCA
	cmp r3, #0                           @ 08072BCC
	bne .L08072BD2                       @ 08072BCE
	b .L08072CD8                         @ 08072BD0
.L08072BD2:
	mov r4, sb                           @ 08072BD2
	mov r0, ip                           @ 08072BD4
	str r0, [r4, #0x10]                  @ 08072BD6
	movs r2, #0                          @ 08072BD8
	movs r1, #1                          @ 08072BDA
	movs r0, #4                          @ 08072BDC
	ldr r3, [sp]                         @ 08072BDE
	ands r0, r3                          @ 08072BE0
	orrs r5, r0                          @ 08072BE2
	orrs r5, r1                          @ 08072BE4
	strb r5, [r4]                        @ 08072BE6
	mov r5, sp                           @ 08072BE8
	ldrb r5, [r5, #4]                    @ 08072BEA
	strb r5, [r4, #1]                    @ 08072BEC
	mov r0, sp                           @ 08072BEE
	ldrb r0, [r0, #8]                    @ 08072BF0
	strb r0, [r4, #2]                    @ 08072BF2
	add r1, sp, #0x38                    @ 08072BF4
	ldrb r1, [r1]                        @ 08072BF6
	strb r1, [r4, #3]                    @ 08072BF8
	str r2, [r4, #8]                     @ 08072BFA
	mov r2, r8                           @ 08072BFC
	lsls r0, r2, #0xe                    @ 08072BFE
	asrs r0, r0, #0xe                    @ 08072C00
	str r0, [r4, #0xc]                   @ 08072C02
	ldr r5, .Lp08072C20                  @ 08072C04
	ldr r3, [r5]                         @ 08072C06
	ldr r1, [r3, #0xc]                   @ 08072C08
	ldr r0, .Lp08072C24                  @ 08072C0A
	ands r0, r1                          @ 08072C0C
	str r0, [r4, #4]                     @ 08072C0E
	adds r1, #1                          @ 08072C10
	str r1, [r3, #0xc]                   @ 08072C12
	ldr r1, .Lp08072C28                  @ 08072C14
	adds r0, r3, r1                      @ 08072C16
	ldr r5, .Lp08072C2C                  @ 08072C18
	adds r2, r4, r5                      @ 08072C1A
	b .L08072CA6                         @ 08072C1C
	.align 2, 0
.Lp08072C20:	.word gSnd
.Lp08072C24:	.word 0x7FFFFFFF
.Lp08072C28:	.word SND_PLAYER
.Lp08072C2C:	.word -SND_VOICES
.L08072C30:
	movs r6, #0                          @ 08072C30
	movs r4, #3                          @ 08072C32
	movs r2, #0xf0                       @ 08072C34
	b .L08072C3C                         @ 08072C36
.L08072C38:
	adds r6, #1                          @ 08072C38
	adds r3, #0x14                       @ 08072C3A
.L08072C3C:
	cmp r6, sl                           @ 08072C3C
	bhs .L08072C5A                       @ 08072C3E
	ldrb r1, [r3]                        @ 08072C40
	adds r0, r4, #0                      @ 08072C42
	ands r0, r1                          @ 08072C44
	cmp r0, #0                           @ 08072C46
	beq .L08072C58                       @ 08072C48
	adds r0, r2, #0                      @ 08072C4A
	ands r0, r1                          @ 08072C4C
	cmp r0, r7                           @ 08072C4E
	bhs .L08072C38                       @ 08072C50
	adds r7, r0, #0                      @ 08072C52
	mov sb, r3                           @ 08072C54
	b .L08072C38                         @ 08072C56
.L08072C58:
	mov sb, r3                           @ 08072C58
.L08072C5A:
	mov r0, sb                           @ 08072C5A
	cmp r0, #0                           @ 08072C5C
	beq .L08072CD8                       @ 08072C5E
	mov r4, sb                           @ 08072C60
	mov r1, ip                           @ 08072C62
	str r1, [r4, #0x10]                  @ 08072C64
	movs r1, #0                          @ 08072C66
	movs r0, #1                          @ 08072C68
	ldr r2, [sp]                         @ 08072C6A
	orrs r5, r2                          @ 08072C6C
	orrs r5, r0                          @ 08072C6E
	strb r5, [r4]                        @ 08072C70
	mov r3, sp                           @ 08072C72
	ldrb r3, [r3, #4]                    @ 08072C74
	strb r3, [r4, #1]                    @ 08072C76
	mov r5, sp                           @ 08072C78
	ldrb r5, [r5, #8]                    @ 08072C7A
	strb r5, [r4, #2]                    @ 08072C7C
	add r0, sp, #0x38                    @ 08072C7E
	ldrb r0, [r0]                        @ 08072C80
	strb r0, [r4, #3]                    @ 08072C82
	str r1, [r4, #8]                     @ 08072C84
	mov r1, r8                           @ 08072C86
	lsls r0, r1, #0xe                    @ 08072C88
	asrs r0, r0, #0xe                    @ 08072C8A
	str r0, [r4, #0xc]                   @ 08072C8C
	ldr r2, .Lp08072CC4                  @ 08072C8E
	ldr r3, [r2]                         @ 08072C90
	ldr r1, [r3, #0xc]                   @ 08072C92
	ldr r0, .Lp08072CC8                  @ 08072C94
	ands r0, r1                          @ 08072C96
	str r0, [r4, #4]                     @ 08072C98
	adds r1, #1                          @ 08072C9A
	str r1, [r3, #0xc]                   @ 08072C9C
	ldr r5, .Lp08072CCC                  @ 08072C9E
	adds r0, r3, r5                      @ 08072CA0
	ldr r1, .Lp08072CD0                  @ 08072CA2
	adds r2, r4, r1                      @ 08072CA4
.L08072CA6:
	subs r2, r2, r3                      @ 08072CA6
	lsls r1, r2, #1                      @ 08072CA8
	adds r1, r1, r2                      @ 08072CAA
	lsls r2, r1, #4                      @ 08072CAC
	adds r1, r1, r2                      @ 08072CAE
	lsls r2, r1, #8                      @ 08072CB0
	adds r1, r1, r2                      @ 08072CB2
	lsls r2, r1, #0x10                   @ 08072CB4
	adds r1, r1, r2                      @ 08072CB6
	rsbs r1, r1, #0                      @ 08072CB8
	asrs r1, r1, #2                      @ 08072CBA
	bl musReserveVoice                   @ 08072CBC
	ldr r0, [r4, #4]                     @ 08072CC0
	b .L08072CDC                         @ 08072CC2
.Lp08072CC4:	.word gSnd
.Lp08072CC8:	.word 0x7FFFFFFF
.Lp08072CCC:	.word SND_PLAYER
.Lp08072CD0:	.word -SND_VOICES
.L08072CD4:
	ldr r0, [r3, #4]                     @ 08072CD4
	b .L08072CDC                         @ 08072CD6
.L08072CD8:
	movs r0, #1                          @ 08072CD8
	rsbs r0, r0, #0                      @ 08072CDA
.L08072CDC:
	add sp, #0x14                        @ 08072CDC
	pop {r3, r4, r5}                     @ 08072CDE
	mov r8, r3                           @ 08072CE0
	mov sb, r4                           @ 08072CE2
	mov sl, r5                           @ 08072CE4
	pop {r4, r5, r6, r7}                 @ 08072CE6
	pop {r1}                             @ 08072CE8
	bx r1                                @ 08072CEA

@ ============================================================================
@ void sndDmaIrq(void)                                     [IRQ table entry 9 (DMA1), 0x08078F70]
@   gSndDmaIrqFn();                           // sndArmA_DmaIrq in RAM
@ ============================================================================
	thumb_func_start sndDmaIrq
sndDmaIrq: @ 0x08072CEC
	push {lr}                            @ 08072CEC
	ldr r0, .Lp08072CFC                  @ 08072CEE
	ldr r0, [r0]                         @ 08072CF0
	bl _call_via_r0                      @ 08072CF2
	pop {r0}                             @ 08072CF6
	bx r0                                @ 08072CF8
	.align 2, 0
.Lp08072CFC:	.word gSndDmaIrqFn

@ ============================================================================
@ void sndDmaStop(void)                                    [game, 0x08008BDA]
@   DMA1CNT = DMA2CNT = 0; gSnd->flags |= 4;
@ ============================================================================
	thumb_func_start sndDmaStop
sndDmaStop: @ 0x08072D00
	ldr r0, .Lp08072D18                  @ 08072D00
	movs r1, #0                          @ 08072D02
	str r1, [r0]                         @ 08072D04
	adds r0, #0xc                        @ 08072D06
	str r1, [r0]                         @ 08072D08
	ldr r0, .Lp08072D1C                  @ 08072D0A
	ldr r2, [r0]                         @ 08072D0C
	ldrb r1, [r2, #1]                    @ 08072D0E
	movs r0, #4                          @ 08072D10
	orrs r0, r1                          @ 08072D12
	strb r0, [r2, #1]                    @ 08072D14
	bx lr                                @ 08072D16
.Lp08072D18:	.word REG_DMA1CNT
.Lp08072D1C:	.word gSnd

@ ============================================================================
@ void sndDmaStart(void)                                   [sndVBlank]
@   gSnd->flags &= ~4; DMA1CNT = DMA2CNT = 0xF6600004;
@   (Rewrites the control words of a running DMA without stopping it first; the source address is not
@    reloaded, so after sndDmaStop the sound resumes wherever the DMA had stopped.)
@ ============================================================================
	thumb_func_start sndDmaStart
sndDmaStart: @ 0x08072D20
	ldr r0, .Lp08072D38                  @ 08072D20
	ldr r2, [r0]                         @ 08072D22
	ldrb r1, [r2, #1]                    @ 08072D24
	movs r0, #0xfb                       @ 08072D26
	ands r0, r1                          @ 08072D28
	strb r0, [r2, #1]                    @ 08072D2A
	ldr r0, .Lp08072D3C                  @ 08072D2C
	ldr r1, .Lp08072D40                  @ 08072D2E
	str r1, [r0]                         @ 08072D30
	adds r0, #0xc                        @ 08072D32
	str r1, [r0]                         @ 08072D34
	bx lr                                @ 08072D36
.Lp08072D38:	.word gSnd
.Lp08072D3C:	.word REG_DMA1CNT
.Lp08072D40:	.word 0xF6600004

@ ============================================================================
@ void sfxStopAll(void)                                    [10 call sites]
@   for (k = 0; k < s->nVoices; k++) { s->voices[k].flags = 0; musReleaseVoice(&s->player, k); }
@ ============================================================================
	thumb_func_start sfxStopAll
sfxStopAll: @ 0x08072D44
	push {r4, r5, r6, lr}                @ 08072D44
	movs r4, #0                          @ 08072D46
	ldr r1, .Lp08072D80                  @ 08072D48
	ldr r0, [r1]                         @ 08072D4A
	ldrb r0, [r0]                        @ 08072D4C
	cmp r4, r0                           @ 08072D4E
	bge .L08072D7A                       @ 08072D50
	adds r5, r1, #0                      @ 08072D52
	movs r6, #0                          @ 08072D54
.L08072D56:
	ldr r0, [r5]                         @ 08072D56
	adds r0, r0, r6                      @ 08072D58
	ldr r1, .Lp08072D84                  @ 08072D5A
	adds r0, r0, r1                      @ 08072D5C
	movs r1, #0                          @ 08072D5E
	strb r1, [r0]                        @ 08072D60
	ldr r0, [r5]                         @ 08072D62
	ldr r1, .Lp08072D88                  @ 08072D64
	adds r0, r0, r1                      @ 08072D66
	adds r1, r4, #0                      @ 08072D68
	bl musReleaseVoice                   @ 08072D6A
	adds r6, #0x14                       @ 08072D6E
	adds r4, #1                          @ 08072D70
	ldr r0, [r5]                         @ 08072D72
	ldrb r0, [r0]                        @ 08072D74
	cmp r4, r0                           @ 08072D76
	blt .L08072D56                       @ 08072D78
.L08072D7A:
	pop {r4, r5, r6}                     @ 08072D7A
	pop {r0}                             @ 08072D7C
	bx r0                                @ 08072D7E
.Lp08072D80:	.word gSnd
.Lp08072D84:	.word SND_VOICES
.Lp08072D88:	.word SND_PLAYER

@ ============================================================================
@ void sfxStopAllExcept(int id)                            [game, 0x08008BB6]
@   for each voice k: if (voices[k].sfx != &sfxTable[id]) { flags = 0; musReleaseVoice(player, k); }
@ ============================================================================
	thumb_func_start sfxStopAllExcept
sfxStopAllExcept: @ 0x08072D8C
	push {r4, r5, r6, r7, lr}            @ 08072D8C
	lsls r1, r0, #3                      @ 08072D8E
	subs r1, r1, r0                      @ 08072D90
	lsls r1, r1, #2                      @ 08072D92
	ldr r0, .Lp08072DE0                  @ 08072D94
	adds r7, r1, r0                      @ 08072D96
	movs r5, #0                          @ 08072D98
	ldr r1, .Lp08072DE4                  @ 08072D9A
	ldr r0, [r1]                         @ 08072D9C
	ldrb r0, [r0]                        @ 08072D9E
	cmp r5, r0                           @ 08072DA0
	bge .L08072DD8                       @ 08072DA2
	adds r6, r1, #0                      @ 08072DA4
	movs r4, #0                          @ 08072DA6
.L08072DA8:
	ldr r1, [r6]                         @ 08072DA8
	ldr r2, .Lp08072DE8                  @ 08072DAA
	adds r0, r1, r2                      @ 08072DAC
	adds r0, r0, r4                      @ 08072DAE
	ldr r0, [r0]                         @ 08072DB0
	cmp r0, r7                           @ 08072DB2
	beq .L08072DCC                       @ 08072DB4
	adds r0, r1, r4                      @ 08072DB6
	ldr r1, .Lp08072DEC                  @ 08072DB8
	adds r0, r0, r1                      @ 08072DBA
	movs r1, #0                          @ 08072DBC
	strb r1, [r0]                        @ 08072DBE
	ldr r0, [r6]                         @ 08072DC0
	ldr r2, .Lp08072DF0                  @ 08072DC2
	adds r0, r0, r2                      @ 08072DC4
	adds r1, r5, #0                      @ 08072DC6
	bl musReleaseVoice                   @ 08072DC8
.L08072DCC:
	adds r4, #0x14                       @ 08072DCC
	adds r5, #1                          @ 08072DCE
	ldr r0, [r6]                         @ 08072DD0
	ldrb r0, [r0]                        @ 08072DD2
	cmp r5, r0                           @ 08072DD4
	blt .L08072DA8                       @ 08072DD6
.L08072DD8:
	pop {r4, r5, r6, r7}                 @ 08072DD8
	pop {r0}                             @ 08072DDA
	bx r0                                @ 08072DDC
	.align 2, 0
.Lp08072DE0:	.word sfxTable
.Lp08072DE4:	.word gSnd
.Lp08072DE8:	.word SND_VOICES+VC_sfx
.Lp08072DEC:	.word SND_VOICES
.Lp08072DF0:	.word SND_PLAYER

@ ============================================================================
@ void sfxStopLooping(void)                                [10 call sites]
@   for each voice k: if (voices[k].flags & 4) { flags = 0; musReleaseVoice(player, k); }
@ ============================================================================
	thumb_func_start sfxStopLooping
sfxStopLooping: @ 0x08072DF4
	push {r4, r5, r6, lr}                @ 08072DF4
	movs r4, #0                          @ 08072DF6
	ldr r1, .Lp08072E3C                  @ 08072DF8
	ldr r0, [r1]                         @ 08072DFA
	ldrb r0, [r0]                        @ 08072DFC
	cmp r4, r0                           @ 08072DFE
	bge .L08072E34                       @ 08072E00
	adds r5, r1, #0                      @ 08072E02
	movs r6, #0                          @ 08072E04
.L08072E06:
	ldr r0, [r5]                         @ 08072E06
	adds r0, r0, r6                      @ 08072E08
	ldr r1, .Lp08072E40                  @ 08072E0A
	adds r2, r0, r1                      @ 08072E0C
	ldrb r1, [r2]                        @ 08072E0E
	movs r0, #4                          @ 08072E10
	ands r0, r1                          @ 08072E12
	cmp r0, #0                           @ 08072E14
	beq .L08072E28                       @ 08072E16
	movs r0, #0                          @ 08072E18
	strb r0, [r2]                        @ 08072E1A
	ldr r0, [r5]                         @ 08072E1C
	ldr r1, .Lp08072E44                  @ 08072E1E
	adds r0, r0, r1                      @ 08072E20
	adds r1, r4, #0                      @ 08072E22
	bl musReleaseVoice                   @ 08072E24
.L08072E28:
	adds r6, #0x14                       @ 08072E28
	adds r4, #1                          @ 08072E2A
	ldr r0, [r5]                         @ 08072E2C
	ldrb r0, [r0]                        @ 08072E2E
	cmp r4, r0                           @ 08072E30
	blt .L08072E06                       @ 08072E32
.L08072E34:
	pop {r4, r5, r6}                     @ 08072E34
	pop {r0}                             @ 08072E36
	bx r0                                @ 08072E38
	.align 2, 0
.Lp08072E3C:	.word gSnd
.Lp08072E40:	.word SND_VOICES
.Lp08072E44:	.word SND_PLAYER

@ ============================================================================
@ int sfxSetPan(int handle, u8 pan, u8 wide)               [3 call sites]
@   v = active voice with v->handle == handle; if (!v) return -1;
@   if (!stereo) { pan = 64; wide = 0; }
@   v->pan = pan; v->wide = wide; return handle;
@ ============================================================================
	thumb_func_start sfxSetPan
sfxSetPan: @ 0x08072E48
	push {r4, r5, r6, r7, lr}            @ 08072E48
	mov r7, r8                           @ 08072E4A
	push {r7}                            @ 08072E4C
	adds r5, r0, #0                      @ 08072E4E
	mov ip, r1                           @ 08072E50
	adds r7, r2, #0                      @ 08072E52
	ldr r1, .Lp08072E8C                  @ 08072E54
	ldr r0, [r1]                         @ 08072E56
	ldrb r4, [r0]                        @ 08072E58
	ldr r2, .Lp08072E90                  @ 08072E5A
	adds r3, r0, r2                      @ 08072E5C
	movs r2, #0                          @ 08072E5E
	mov r8, r1                           @ 08072E60
	cmp r2, r4                           @ 08072E62
	bge .L08072E80                       @ 08072E64
	movs r6, #3                          @ 08072E66
.L08072E68:
	ldrb r1, [r3]                        @ 08072E68
	adds r0, r6, #0                      @ 08072E6A
	ands r0, r1                          @ 08072E6C
	cmp r0, #0                           @ 08072E6E
	beq .L08072E78                       @ 08072E70
	ldr r0, [r3, #4]                     @ 08072E72
	cmp r0, r5                           @ 08072E74
	beq .L08072E82                       @ 08072E76
.L08072E78:
	adds r2, #1                          @ 08072E78
	adds r3, #0x14                       @ 08072E7A
	cmp r2, r4                           @ 08072E7C
	blt .L08072E68                       @ 08072E7E
.L08072E80:
	movs r3, #0                          @ 08072E80
.L08072E82:
	cmp r3, #0                           @ 08072E82
	bne .L08072E94                       @ 08072E84
	movs r0, #1                          @ 08072E86
	rsbs r0, r0, #0                      @ 08072E88
	b .L08072EB0                         @ 08072E8A
.Lp08072E8C:	.word gSnd
.Lp08072E90:	.word SND_VOICES
.L08072E94:
	mov r1, r8                           @ 08072E94
	ldr r0, [r1]                         @ 08072E96
	ldrb r1, [r0, #1]                    @ 08072E98
	movs r0, #0x10                       @ 08072E9A
	ands r0, r1                          @ 08072E9C
	cmp r0, #0                           @ 08072E9E
	bne .L08072EA8                       @ 08072EA0
	movs r2, #0x40                       @ 08072EA2
	mov ip, r2                           @ 08072EA4
	movs r7, #0                          @ 08072EA6
.L08072EA8:
	mov r0, ip                           @ 08072EA8
	strb r0, [r3, #1]                    @ 08072EAA
	strb r7, [r3, #2]                    @ 08072EAC
	adds r0, r5, #0                      @ 08072EAE
.L08072EB0:
	pop {r3}                             @ 08072EB0
	mov r8, r3                           @ 08072EB2
	pop {r4, r5, r6, r7}                 @ 08072EB4
	pop {r1}                             @ 08072EB6
	bx r1                                @ 08072EB8
	.align 2, 0

@ ============================================================================
@ void sfxStop(int handle)                                 [17 call sites]
@   v = active voice with that handle; if (v) { v->flags = 0; musReleaseVoice(player, v - voices); }
@ ============================================================================
	thumb_func_start sfxStop
sfxStop: @ 0x08072EBC
	push {r4, r5, r6, r7, lr}            @ 08072EBC
	adds r5, r0, #0                      @ 08072EBE
	ldr r1, .Lp08072F24                  @ 08072EC0
	ldr r0, [r1]                         @ 08072EC2
	ldrb r4, [r0]                        @ 08072EC4
	ldr r3, .Lp08072F28                  @ 08072EC6
	adds r2, r0, r3                      @ 08072EC8
	movs r3, #0                          @ 08072ECA
	adds r7, r1, #0                      @ 08072ECC
	cmp r3, r4                           @ 08072ECE
	bge .L08072EEC                       @ 08072ED0
	movs r6, #3                          @ 08072ED2
.L08072ED4:
	ldrb r1, [r2]                        @ 08072ED4
	adds r0, r6, #0                      @ 08072ED6
	ands r0, r1                          @ 08072ED8
	cmp r0, #0                           @ 08072EDA
	beq .L08072EE4                       @ 08072EDC
	ldr r0, [r2, #4]                     @ 08072EDE
	cmp r0, r5                           @ 08072EE0
	beq .L08072EEE                       @ 08072EE2
.L08072EE4:
	adds r3, #1                          @ 08072EE4
	adds r2, #0x14                       @ 08072EE6
	cmp r3, r4                           @ 08072EE8
	blt .L08072ED4                       @ 08072EEA
.L08072EEC:
	movs r2, #0                          @ 08072EEC
.L08072EEE:
	cmp r2, #0                           @ 08072EEE
	beq .L08072F1C                       @ 08072EF0
	ldr r1, .Lp08072F2C                  @ 08072EF2
	adds r0, r2, r1                      @ 08072EF4
	ldr r1, [r7]                         @ 08072EF6
	subs r0, r0, r1                      @ 08072EF8
	lsls r1, r0, #1                      @ 08072EFA
	adds r1, r1, r0                      @ 08072EFC
	lsls r0, r1, #4                      @ 08072EFE
	adds r1, r1, r0                      @ 08072F00
	lsls r0, r1, #8                      @ 08072F02
	adds r1, r1, r0                      @ 08072F04
	lsls r0, r1, #0x10                   @ 08072F06
	adds r1, r1, r0                      @ 08072F08
	rsbs r1, r1, #0                      @ 08072F0A
	asrs r1, r1, #2                      @ 08072F0C
	movs r0, #0                          @ 08072F0E
	strb r0, [r2]                        @ 08072F10
	ldr r0, [r7]                         @ 08072F12
	ldr r2, .Lp08072F30                  @ 08072F14
	adds r0, r0, r2                      @ 08072F16
	bl musReleaseVoice                   @ 08072F18
.L08072F1C:
	pop {r4, r5, r6, r7}                 @ 08072F1C
	pop {r0}                             @ 08072F1E
	bx r0                                @ 08072F20
	.align 2, 0
.Lp08072F24:	.word gSnd
.Lp08072F28:	.word SND_VOICES
.Lp08072F2C:	.word -SND_VOICES
.Lp08072F30:	.word SND_PLAYER

@ ============================================================================
@ void sfxStopId(int id)                                   [50 call sites]
@   for each voice k with (flags & 1) && sfx == &sfxTable[id]: flags = 0; musReleaseVoice(player, k);
@ ============================================================================
	thumb_func_start sfxStopId
sfxStopId: @ 0x08072F34
	push {r4, r5, r6, r7, lr}            @ 08072F34
	mov r7, r8                           @ 08072F36
	push {r7}                            @ 08072F38
	movs r7, #1                          @ 08072F3A
	lsls r1, r0, #3                      @ 08072F3C
	subs r1, r1, r0                      @ 08072F3E
	lsls r1, r1, #2                      @ 08072F40
	ldr r0, .Lp08072F8C                  @ 08072F42
	adds r1, r1, r0                      @ 08072F44
	mov r8, r1                           @ 08072F46
	ldr r0, .Lp08072F90                  @ 08072F48
	ldr r0, [r0]                         @ 08072F4A
	ldr r1, .Lp08072F94                  @ 08072F4C
	adds r4, r0, r1                      @ 08072F4E
	ldrb r6, [r0]                        @ 08072F50
	movs r5, #0                          @ 08072F52
	cmp r5, r6                           @ 08072F54
	bge .L08072F80                       @ 08072F56
.L08072F58:
	ldrb r0, [r4]                        @ 08072F58
	ands r0, r7                          @ 08072F5A
	cmp r0, r7                           @ 08072F5C
	bne .L08072F78                       @ 08072F5E
	ldr r0, [r4, #0x10]                  @ 08072F60
	cmp r0, r8                           @ 08072F62
	bne .L08072F78                       @ 08072F64
	movs r0, #0                          @ 08072F66
	strb r0, [r4]                        @ 08072F68
	ldr r0, .Lp08072F90                  @ 08072F6A
	ldr r0, [r0]                         @ 08072F6C
	ldr r1, .Lp08072F98                  @ 08072F6E
	adds r0, r0, r1                      @ 08072F70
	adds r1, r5, #0                      @ 08072F72
	bl musReleaseVoice                   @ 08072F74
.L08072F78:
	adds r5, #1                          @ 08072F78
	adds r4, #0x14                       @ 08072F7A
	cmp r5, r6                           @ 08072F7C
	blt .L08072F58                       @ 08072F7E
.L08072F80:
	pop {r3}                             @ 08072F80
	mov r8, r3                           @ 08072F82
	pop {r4, r5, r6, r7}                 @ 08072F84
	pop {r0}                             @ 08072F86
	bx r0                                @ 08072F88
	.align 2, 0
.Lp08072F8C:	.word sfxTable
.Lp08072F90:	.word gSnd
.Lp08072F94:	.word SND_VOICES
.Lp08072F98:	.word SND_PLAYER

@ ============================================================================
@ void sfxStopPriority(int prio, int all)                  [sfxPlay, game]
@   mask = all ? 1 : 5;        // all == 0: only looping voices
@   for each voice k with (flags & mask) == mask && (flags & 0xF0) == (prio << 4):
@       flags = 0; musReleaseVoice(player, k);
@ ============================================================================
	thumb_func_start sfxStopPriority
sfxStopPriority: @ 0x08072F9C
	push {r4, r5, r6, r7, lr}            @ 08072F9C
	mov r7, r8                           @ 08072F9E
	push {r7}                            @ 08072FA0
	lsls r1, r1, #0x18                   @ 08072FA2
	movs r7, #1                          @ 08072FA4
	ldr r2, .Lp08072FF8                  @ 08072FA6
	ldr r2, [r2]                         @ 08072FA8
	ldr r3, .Lp08072FFC                  @ 08072FAA
	adds r4, r2, r3                      @ 08072FAC
	ldrb r6, [r2]                        @ 08072FAE
	lsls r0, r0, #0x1c                   @ 08072FB0
	lsrs r0, r0, #0x18                   @ 08072FB2
	mov r8, r0                           @ 08072FB4
	cmp r1, #0                           @ 08072FB6
	bne .L08072FBC                       @ 08072FB8
	movs r7, #5                          @ 08072FBA
.L08072FBC:
	movs r5, #0                          @ 08072FBC
	cmp r5, r6                           @ 08072FBE
	bge .L08072FEE                       @ 08072FC0
.L08072FC2:
	ldrb r1, [r4]                        @ 08072FC2
	adds r0, r7, #0                      @ 08072FC4
	ands r0, r1                          @ 08072FC6
	cmp r0, r7                           @ 08072FC8
	bne .L08072FE6                       @ 08072FCA
	movs r0, #0xf0                       @ 08072FCC
	ands r0, r1                          @ 08072FCE
	cmp r0, r8                           @ 08072FD0
	bne .L08072FE6                       @ 08072FD2
	movs r0, #0                          @ 08072FD4
	strb r0, [r4]                        @ 08072FD6
	ldr r0, .Lp08072FF8                  @ 08072FD8
	ldr r0, [r0]                         @ 08072FDA
	ldr r1, .Lp08073000                  @ 08072FDC
	adds r0, r0, r1                      @ 08072FDE
	adds r1, r5, #0                      @ 08072FE0
	bl musReleaseVoice                   @ 08072FE2
.L08072FE6:
	adds r5, #1                          @ 08072FE6
	adds r4, #0x14                       @ 08072FE8
	cmp r5, r6                           @ 08072FEA
	blt .L08072FC2                       @ 08072FEC
.L08072FEE:
	pop {r3}                             @ 08072FEE
	mov r8, r3                           @ 08072FF0
	pop {r4, r5, r6, r7}                 @ 08072FF2
	pop {r0}                             @ 08072FF4
	bx r0                                @ 08072FF6
.Lp08072FF8:	.word gSnd
.Lp08072FFC:	.word SND_VOICES
.Lp08073000:	.word SND_PLAYER

@ ============================================================================
@ void sndShutdown(void)                                   [game, 0x08037A54]
@   DMA1CNT = DMA2CNT = 0; SOUNDCNT_X = 0; TM1CNT = 0; sndHeapReset(); gSnd = NULL;
@   (Timer 0 and its PSG IRQ, and the IE bits, are left running.)
@ ============================================================================
	thumb_func_start sndShutdown
sndShutdown: @ 0x08073004
	push {r4, lr}                        @ 08073004
	ldr r0, .Lp08073028                  @ 08073006
	movs r4, #0                          @ 08073008
	str r4, [r0]                         @ 0807300A
	adds r0, #0xc                        @ 0807300C
	str r4, [r0]                         @ 0807300E
	subs r0, #0x4c                       @ 08073010
	strh r4, [r0]                        @ 08073012
	adds r0, #0x80                       @ 08073014
	str r4, [r0]                         @ 08073016
	bl sndHeapReset                      @ 08073018
	ldr r0, .Lp0807302C                  @ 0807301C
	str r4, [r0]                         @ 0807301E
	pop {r4}                             @ 08073020
	pop {r0}                             @ 08073022
	bx r0                                @ 08073024
	.align 2, 0
.Lp08073028:	.word REG_DMA1CNT
.Lp0807302C:	.word gSnd

@ ============================================================================
@ void musPlayModule(Module *m)                            [unused]
@   musStart(&gSnd->player, m);     // leaves the song paused (order -1) at volume 0
@ ============================================================================
	thumb_func_start musPlayModule
musPlayModule: @ 0x08073030
	push {lr}                            @ 08073030
	adds r1, r0, #0                      @ 08073032
	ldr r0, .Lp08073044                  @ 08073034
	ldr r0, [r0]                         @ 08073036
	ldr r2, .Lp08073048                  @ 08073038
	adds r0, r0, r2                      @ 0807303A
	bl musStart                          @ 0807303C
	pop {r0}                             @ 08073040
	bx r0                                @ 08073042
.Lp08073044:	.word gSnd
.Lp08073048:	.word SND_PLAYER

@ ============================================================================
@ void musPlayModule2(Module *m)                           [unused, identical to musPlayModule]
@ ============================================================================
	thumb_func_start musPlayModule2
musPlayModule2: @ 0x0807304C
	push {lr}                            @ 0807304C
	adds r1, r0, #0                      @ 0807304E
	ldr r0, .Lp08073060                  @ 08073050
	ldr r0, [r0]                         @ 08073052
	ldr r2, .Lp08073064                  @ 08073054
	adds r0, r0, r2                      @ 08073056
	bl musStart                          @ 08073058
	pop {r0}                             @ 0807305C
	bx r0                                @ 0807305E
.Lp08073060:	.word gSnd
.Lp08073064:	.word SND_PLAYER

@ ============================================================================
@ void musRestart(void)                                    [unused]
@   musReset(&gSnd->player);
@ ============================================================================
	thumb_func_start musRestart
musRestart: @ 0x08073068
	push {lr}                            @ 08073068
	ldr r0, .Lp0807307C                  @ 0807306A
	ldr r0, [r0]                         @ 0807306C
	ldr r1, .Lp08073080                  @ 0807306E
	adds r0, r0, r1                      @ 08073070
	bl musReset                          @ 08073072
	pop {r0}                             @ 08073076
	bx r0                                @ 08073078
	.align 2, 0
.Lp0807307C:	.word gSnd
.Lp08073080:	.word SND_PLAYER

@ ============================================================================
@ u16 musGetSongVolume(int song)  { return musSongTable[song].volume; }          [7 call sites]
@ ============================================================================
	thumb_func_start musGetSongVolume
musGetSongVolume: @ 0x08073084
	ldr r2, .Lp08073094                  @ 08073084
	lsls r1, r0, #1                      @ 08073086
	adds r1, r1, r0                      @ 08073088
	lsls r1, r1, #2                      @ 0807308A
	adds r1, r1, r2                      @ 0807308C
	ldrh r0, [r1, #4]                    @ 0807308E
	bx lr                                @ 08073090
	.align 2, 0
.Lp08073094:	.word musSongTable

@ ============================================================================
@ Module *musGetSongModule(int song) { return musSongTable[song].module; }       [7 call sites]
@ ============================================================================
	thumb_func_start musGetSongModule
musGetSongModule: @ 0x08073098
	ldr r2, .Lp080730A8                  @ 08073098
	lsls r1, r0, #1                      @ 0807309A
	adds r1, r1, r0                      @ 0807309C
	lsls r1, r1, #2                      @ 0807309E
	adds r1, r1, r2                      @ 080730A0
	ldr r0, [r1]                         @ 080730A2
	bx lr                                @ 080730A4
	.align 2, 0
.Lp080730A8:	.word musSongTable

@ ============================================================================
@ u8 *musGetSongVoiceMap(int song) { return musSongTable[song].voiceMap; }      [7 call sites]
@ ============================================================================
	thumb_func_start musGetSongVoiceMap
musGetSongVoiceMap: @ 0x080730AC
	adds r1, r0, #0                      @ 080730AC
	lsls r0, r1, #1                      @ 080730AE
	adds r0, r0, r1                      @ 080730B0
	lsls r0, r0, #2                      @ 080730B2
	ldr r1, .Lp080730BC                  @ 080730B4
	adds r0, r0, r1                      @ 080730B6
	bx lr                                @ 080730B8
	.align 2, 0
.Lp080730BC:	.word musSongTable+6

@ ============================================================================
@ void musPlayModuleEx(Module *m, int vol, int loop, u8 *voiceMap)              [5 call sites]
@   musStart(&gSnd->player, m); musSetParams(&gSnd->player, vol, loop, voiceMap);
@   (The game uses it with the three getters above to play songs with its own volume.)
@ ============================================================================
	thumb_func_start musPlayModuleEx
musPlayModuleEx: @ 0x080730C0
	push {r4, r5, r6, lr}                @ 080730C0
	mov r6, sl                           @ 080730C2
	mov r5, sb                           @ 080730C4
	mov r4, r8                           @ 080730C6
	push {r4, r5, r6}                    @ 080730C8
	adds r6, r0, #0                      @ 080730CA
	mov r8, r1                           @ 080730CC
	mov sb, r2                           @ 080730CE
	mov sl, r3                           @ 080730D0
	ldr r5, .Lp080730FC                  @ 080730D2
	ldr r0, [r5]                         @ 080730D4
	ldr r4, .Lp08073100                  @ 080730D6
	adds r0, r0, r4                      @ 080730D8
	adds r1, r6, #0                      @ 080730DA
	bl musStart                          @ 080730DC
	ldr r0, [r5]                         @ 080730E0
	adds r0, r0, r4                      @ 080730E2
	mov r1, r8                           @ 080730E4
	mov r2, sb                           @ 080730E6
	mov r3, sl                           @ 080730E8
	bl musSetParams                      @ 080730EA
	pop {r3, r4, r5}                     @ 080730EE
	mov r8, r3                           @ 080730F0
	mov sb, r4                           @ 080730F2
	mov sl, r5                           @ 080730F4
	pop {r4, r5, r6}                     @ 080730F6
	pop {r0}                             @ 080730F8
	bx r0                                @ 080730FA
.Lp080730FC:	.word gSnd
.Lp08073100:	.word SND_PLAYER

@ ============================================================================
@ int musGetCurrentSong(void)                               [9 call sites]
@   if (musIsStopped()) return -1;
@   for (i = 0; i < musSongCount; i++) if (musSongTable[i].module == player.module) return i;
@   return -2;
@ ============================================================================
	thumb_func_start musGetCurrentSong
musGetCurrentSong: @ 0x08073104
	push {r4, lr}                        @ 08073104
	bl musIsStopped                      @ 08073106
	cmp r0, #0                           @ 0807310A
	beq .L08073118                       @ 0807310C
	movs r0, #1                          @ 0807310E
	rsbs r0, r0, #0                      @ 08073110
	b .L08073142                         @ 08073112
.L08073114:
	adds r0, r2, #0                      @ 08073114
	b .L08073142                         @ 08073116
.L08073118:
	movs r2, #0                          @ 08073118
	ldr r0, .Lp08073148                  @ 0807311A
	ldrh r1, [r0]                        @ 0807311C
	cmp r2, r1                           @ 0807311E
	bge .L0807313E                       @ 08073120
	ldr r0, .Lp0807314C                  @ 08073122
	ldr r0, [r0]                         @ 08073124
	ldr r3, .Lp08073150                  @ 08073126
	adds r0, r0, r3                      @ 08073128
	ldr r4, [r0]                         @ 0807312A
	adds r3, r1, #0                      @ 0807312C
	ldr r1, .Lp08073154                  @ 0807312E
.L08073130:
	ldr r0, [r1]                         @ 08073130
	cmp r4, r0                           @ 08073132
	beq .L08073114                       @ 08073134
	adds r1, #0xc                        @ 08073136
	adds r2, #1                          @ 08073138
	cmp r2, r3                           @ 0807313A
	blt .L08073130                       @ 0807313C
.L0807313E:
	movs r0, #2                          @ 0807313E
	rsbs r0, r0, #0                      @ 08073140
.L08073142:
	pop {r4}                             @ 08073142
	pop {r1}                             @ 08073144
	bx r1                                @ 08073146
.Lp08073148:	.word musSongCount
.Lp0807314C:	.word gSnd
.Lp08073150:	.word SND_PLAYER
.Lp08073154:	.word musSongTable

@ ============================================================================
@ Module *musGetModule(void) { return gSnd->player.module; }                   [game]
@ ============================================================================
	thumb_func_start musGetModule
musGetModule: @ 0x08073158
	ldr r0, .Lp08073164                  @ 08073158
	ldr r0, [r0]                         @ 0807315A
	ldr r1, .Lp08073168                  @ 0807315C
	adds r0, r0, r1                      @ 0807315E
	ldr r0, [r0]                         @ 08073160
	bx lr                                @ 08073162
.Lp08073164:	.word gSnd
.Lp08073168:	.word SND_PLAYER

@ ============================================================================
@ void musPlaySong(int song, int vol, int loop)            [43 call sites]
@   e = &musSongTable[song];
@   musStart(&gSnd->player, e->module);
@   musSetParams(&gSnd->player, e->volume * vol >> 7, loop, e->voiceMap);
@ ============================================================================
	thumb_func_start musPlaySong
musPlaySong: @ 0x0807316C
	push {r4, r5, r6, r7, lr}            @ 0807316C
	mov r7, sl                           @ 0807316E
	mov r6, sb                           @ 08073170
	mov r5, r8                           @ 08073172
	push {r5, r6, r7}                    @ 08073174
	adds r3, r0, #0                      @ 08073176
	adds r7, r1, #0                      @ 08073178
	mov sl, r2                           @ 0807317A
	ldr r0, .Lp080731C0                  @ 0807317C
	mov sb, r0                           @ 0807317E
	ldr r0, [r0]                         @ 08073180
	ldr r1, .Lp080731C4                  @ 08073182
	mov r8, r1                           @ 08073184
	add r0, r8                           @ 08073186
	ldr r5, .Lp080731C8                  @ 08073188
	lsls r4, r3, #1                      @ 0807318A
	adds r4, r4, r3                      @ 0807318C
	lsls r4, r4, #2                      @ 0807318E
	adds r6, r4, r5                      @ 08073190
	ldr r1, [r6]                         @ 08073192
	bl musStart                          @ 08073194
	ldrh r0, [r6, #4]                    @ 08073198
	muls r0, r7, r0                      @ 0807319A
	asrs r7, r0, #7                      @ 0807319C
	mov r1, sb                           @ 0807319E
	ldr r0, [r1]                         @ 080731A0
	add r0, r8                           @ 080731A2
	adds r5, #6                          @ 080731A4
	adds r4, r4, r5                      @ 080731A6
	adds r1, r7, #0                      @ 080731A8
	mov r2, sl                           @ 080731AA
	adds r3, r4, #0                      @ 080731AC
	bl musSetParams                      @ 080731AE
	pop {r3, r4, r5}                     @ 080731B2
	mov r8, r3                           @ 080731B4
	mov sb, r4                           @ 080731B6
	mov sl, r5                           @ 080731B8
	pop {r4, r5, r6, r7}                 @ 080731BA
	pop {r0}                             @ 080731BC
	bx r0                                @ 080731BE
.Lp080731C0:	.word gSnd
.Lp080731C4:	.word SND_PLAYER
.Lp080731C8:	.word musSongTable

@ ============================================================================
@ void musStop(void)                                       [44 call sites]
@   if (player.order >= 0) player.savedOrder = player.order;  player.order = -2;
@ ============================================================================
	thumb_func_start musStop
musStop: @ 0x080731CC
	push {r4, r5, lr}                    @ 080731CC
	ldr r4, .Lp080731F8                  @ 080731CE
	ldr r1, [r4]                         @ 080731D0
	ldr r3, .Lp080731FC                  @ 080731D2
	adds r0, r1, r3                      @ 080731D4
	ldrh r2, [r0]                        @ 080731D6
	movs r5, #0                          @ 080731D8
	ldrsh r0, [r0, r5]                   @ 080731DA
	cmp r0, #0                           @ 080731DC
	blt .L080731E8                       @ 080731DE
	movs r5, #0xa6                       @ 080731E0
	lsls r5, r5, #5                      @ 080731E2
	adds r0, r1, r5                      @ 080731E4
	strh r2, [r0]                        @ 080731E6
.L080731E8:
	ldr r0, [r4]                         @ 080731E8
	adds r0, r0, r3                      @ 080731EA
	ldr r1, .Lp08073200                  @ 080731EC
	strh r1, [r0]                        @ 080731EE
	pop {r4, r5}                         @ 080731F0
	pop {r0}                             @ 080731F2
	bx r0                                @ 080731F4
	.align 2, 0
.Lp080731F8:	.word gSnd
.Lp080731FC:	.word SND_PLAYER+PL_order
.Lp08073200:	.word 0x0000FFFE

@ ============================================================================
@ void musPause(void)                                      [game]
@   if (player.order >= 0) { player.savedOrder = player.order; player.order = -1; }
@ ============================================================================
	thumb_func_start musPause
musPause: @ 0x08073204
	push {r4, lr}                        @ 08073204
	ldr r0, .Lp0807322C                  @ 08073206
	ldr r2, [r0]                         @ 08073208
	ldr r0, .Lp08073230                  @ 0807320A
	adds r1, r2, r0                      @ 0807320C
	ldrh r3, [r1]                        @ 0807320E
	movs r4, #0                          @ 08073210
	ldrsh r0, [r1, r4]                   @ 08073212
	cmp r0, #0                           @ 08073214
	blt .L08073224                       @ 08073216
	movs r4, #0xa6                       @ 08073218
	lsls r4, r4, #5                      @ 0807321A
	adds r0, r2, r4                      @ 0807321C
	strh r3, [r0]                        @ 0807321E
	ldr r0, .Lp08073234                  @ 08073220
	strh r0, [r1]                        @ 08073222
.L08073224:
	pop {r4}                             @ 08073224
	pop {r0}                             @ 08073226
	bx r0                                @ 08073228
	.align 2, 0
.Lp0807322C:	.word gSnd
.Lp08073230:	.word SND_PLAYER+PL_order
.Lp08073234:	.word 0x0000FFFF

@ ============================================================================
@ void musResume(void)                                     [game]
@   if (player.order == -1) player.order = player.savedOrder;
@ ============================================================================
	thumb_func_start musResume
musResume: @ 0x08073238
	ldr r0, .Lp08073258                  @ 08073238
	ldr r2, [r0]                         @ 0807323A
	ldr r0, .Lp0807325C                  @ 0807323C
	adds r3, r2, r0                      @ 0807323E
	movs r0, #0                          @ 08073240
	ldrsh r1, [r3, r0]                   @ 08073242
	movs r0, #1                          @ 08073244
	rsbs r0, r0, #0                      @ 08073246
	cmp r1, r0                           @ 08073248
	bne .L08073256                       @ 0807324A
	movs r1, #0xa6                       @ 0807324C
	lsls r1, r1, #5                      @ 0807324E
	adds r0, r2, r1                      @ 08073250
	ldrh r0, [r0]                        @ 08073252
	strh r0, [r3]                        @ 08073254
.L08073256:
	bx lr                                @ 08073256
.Lp08073258:	.word gSnd
.Lp0807325C:	.word SND_PLAYER+PL_order

@ ============================================================================
@ int musIsStopped(void) { return player.order == -2; }
@ ============================================================================
	thumb_func_start musIsStopped
musIsStopped: @ 0x08073260
	movs r2, #0                          @ 08073260
	ldr r0, .Lp0807327C                  @ 08073262
	ldr r0, [r0]                         @ 08073264
	ldr r1, .Lp08073280                  @ 08073266
	adds r0, r0, r1                      @ 08073268
	movs r3, #0                          @ 0807326A
	ldrsh r1, [r0, r3]                   @ 0807326C
	movs r0, #2                          @ 0807326E
	rsbs r0, r0, #0                      @ 08073270
	cmp r1, r0                           @ 08073272
	bne .L08073278                       @ 08073274
	movs r2, #1                          @ 08073276
.L08073278:
	adds r0, r2, #0                      @ 08073278
	bx lr                                @ 0807327A
.Lp0807327C:	.word gSnd
.Lp08073280:	.word SND_PLAYER+PL_order

@ ============================================================================
@ int sfxCountActive(void)                                 [unused]
@   return number of voices with (flags & 3) != 0;
@ ============================================================================
	thumb_func_start sfxCountActive
sfxCountActive: @ 0x08073284
	push {r4, r5, lr}                    @ 08073284
	ldr r0, .Lp080732B8                  @ 08073286
	ldr r0, [r0]                         @ 08073288
	ldrb r1, [r0]                        @ 0807328A
	movs r4, #0                          @ 0807328C
	ldr r2, .Lp080732BC                  @ 0807328E
	adds r3, r0, r2                      @ 08073290
	cmp r4, r1                           @ 08073292
	bge .L080732AE                       @ 08073294
	movs r5, #3                          @ 08073296
	adds r2, r1, #0                      @ 08073298
.L0807329A:
	ldrb r1, [r3]                        @ 0807329A
	adds r0, r5, #0                      @ 0807329C
	ands r0, r1                          @ 0807329E
	cmp r0, #0                           @ 080732A0
	beq .L080732A6                       @ 080732A2
	adds r4, #1                          @ 080732A4
.L080732A6:
	subs r2, #1                          @ 080732A6
	adds r3, #0x14                       @ 080732A8
	cmp r2, #0                           @ 080732AA
	bne .L0807329A                       @ 080732AC
.L080732AE:
	adds r0, r4, #0                      @ 080732AE
	pop {r4, r5}                         @ 080732B0
	pop {r1}                             @ 080732B2
	bx r1                                @ 080732B4
	.align 2, 0
.Lp080732B8:	.word gSnd
.Lp080732BC:	.word SND_VOICES

@ ============================================================================
@ int sfxIsDone(int handle)                                [5 call sites]
@   return no active voice has this handle;
@ ============================================================================
	thumb_func_start sfxIsDone
sfxIsDone: @ 0x080732C0
	push {r4, r5, r6, lr}                @ 080732C0
	adds r5, r0, #0                      @ 080732C2
	ldr r0, .Lp080732EC                  @ 080732C4
	ldr r0, [r0]                         @ 080732C6
	ldrb r4, [r0]                        @ 080732C8
	ldr r1, .Lp080732F0                  @ 080732CA
	adds r2, r0, r1                      @ 080732CC
	movs r3, #0                          @ 080732CE
	cmp r3, r4                           @ 080732D0
	bge .L080732FC                       @ 080732D2
	movs r6, #3                          @ 080732D4
.L080732D6:
	ldrb r1, [r2]                        @ 080732D6
	adds r0, r6, #0                      @ 080732D8
	ands r0, r1                          @ 080732DA
	cmp r0, #0                           @ 080732DC
	beq .L080732F4                       @ 080732DE
	ldr r0, [r2, #4]                     @ 080732E0
	cmp r0, r5                           @ 080732E2
	bne .L080732F4                       @ 080732E4
	adds r0, r2, #0                      @ 080732E6
	b .L080732FE                         @ 080732E8
	.align 2, 0
.Lp080732EC:	.word gSnd
.Lp080732F0:	.word SND_VOICES
.L080732F4:
	adds r3, #1                          @ 080732F4
	adds r2, #0x14                       @ 080732F6
	cmp r3, r4                           @ 080732F8
	blt .L080732D6                       @ 080732FA
.L080732FC:
	movs r0, #0                          @ 080732FC
.L080732FE:
	movs r1, #0                          @ 080732FE
	cmp r0, #0                           @ 08073300
	bne .L08073306                       @ 08073302
	movs r1, #1                          @ 08073304
.L08073306:
	adds r0, r1, #0                      @ 08073306
	pop {r4, r5, r6}                     @ 08073308
	pop {r1}                             @ 0807330A
	bx r1                                @ 0807330C
	.align 2, 0

@ ============================================================================
@ int sndIsStereo(void) { return (gSnd->flags & 0x10) >> 4; }                  [unused]
@ ============================================================================
	thumb_func_start sndIsStereo
sndIsStereo: @ 0x08073310
	ldr r0, .Lp08073320                  @ 08073310
	ldr r0, [r0]                         @ 08073312
	ldrb r1, [r0, #1]                    @ 08073314
	movs r0, #0x10                       @ 08073316
	ands r0, r1                          @ 08073318
	lsls r0, r0, #0x18                   @ 0807331A
	lsrs r0, r0, #0x1c                   @ 0807331C
	bx lr                                @ 0807331E
.Lp08073320:	.word gSnd

@ ============================================================================
@ void sndSetStereo(int on) { gSnd->flags = (gSnd->flags & ~0x10) | on << 4; }   [4 call sites]
@ ============================================================================
	thumb_func_start sndSetStereo
sndSetStereo: @ 0x08073324
	push {r4, lr}                        @ 08073324
	ldr r4, .Lp08073344                  @ 08073326
	ldr r3, [r4]                         @ 08073328
	ldrb r2, [r3, #1]                    @ 0807332A
	movs r1, #0xef                       @ 0807332C
	ands r1, r2                          @ 0807332E
	strb r1, [r3, #1]                    @ 08073330
	ldr r2, [r4]                         @ 08073332
	lsls r0, r0, #4                      @ 08073334
	ldrb r1, [r2, #1]                    @ 08073336
	orrs r0, r1                          @ 08073338
	strb r0, [r2, #1]                    @ 0807333A
	pop {r4}                             @ 0807333C
	pop {r0}                             @ 0807333E
	bx r0                                @ 08073340
	.align 2, 0
.Lp08073344:	.word gSnd

@ ============================================================================
@ void sndHeapInit(u8 *base, u32 size)
@   gSndHeapBase = base; gSndHeapSize = size; gSndHeapUsed = 0; memset(base, 0, size) (byte loop);
@ ============================================================================
	thumb_func_start sndHeapInit
sndHeapInit: @ 0x08073348
	push {r4, r5, lr}                    @ 08073348
	ldr r3, .Lp08073378                  @ 0807334A
	str r0, [r3]                         @ 0807334C
	ldr r5, .Lp0807337C                  @ 0807334E
	str r1, [r5]                         @ 08073350
	ldr r2, .Lp08073380                  @ 08073352
	movs r0, #0                          @ 08073354
	str r0, [r2]                         @ 08073356
	movs r2, #0                          @ 08073358
	cmp r2, r1                           @ 0807335A
	bhs .L08073372                       @ 0807335C
	adds r4, r3, #0                      @ 0807335E
	movs r3, #0                          @ 08073360
	adds r1, r5, #0                      @ 08073362
.L08073364:
	ldr r0, [r4]                         @ 08073364
	adds r0, r0, r2                      @ 08073366
	strb r3, [r0]                        @ 08073368
	adds r2, #1                          @ 0807336A
	ldr r0, [r1]                         @ 0807336C
	cmp r2, r0                           @ 0807336E
	blo .L08073364                       @ 08073370
.L08073372:
	pop {r4, r5}                         @ 08073372
	pop {r0}                             @ 08073374
	bx r0                                @ 08073376
.Lp08073378:	.word gSndHeapBase
.Lp0807337C:	.word gSndHeapSize
.Lp08073380:	.word gSndHeapUsed

@ ============================================================================
@ void *sndHeapAlloc(u32 n)                   bump allocator, no alignment
@   p = gSndHeapBase + gSndHeapUsed;
@   if (gSndHeapUsed + n > gSndHeapSize) return NULL;
@   gSndHeapUsed += n; return p;
@ ============================================================================
	thumb_func_start sndHeapAlloc
sndHeapAlloc: @ 0x08073384
	ldr r1, .Lp080733A0                  @ 08073384
	ldr r3, .Lp080733A4                  @ 08073386
	ldr r2, [r1]                         @ 08073388
	ldr r1, [r3]                         @ 0807338A
	adds r2, r2, r1                      @ 0807338C
	adds r1, r1, r0                      @ 0807338E
	ldr r0, .Lp080733A8                  @ 08073390
	ldr r0, [r0]                         @ 08073392
	cmp r1, r0                           @ 08073394
	bhi .L080733AC                       @ 08073396
	str r1, [r3]                         @ 08073398
	adds r0, r2, #0                      @ 0807339A
	b .L080733AE                         @ 0807339C
	.align 2, 0
.Lp080733A0:	.word gSndHeapBase
.Lp080733A4:	.word gSndHeapUsed
.Lp080733A8:	.word gSndHeapSize
.L080733AC:
	movs r0, #0                          @ 080733AC
.L080733AE:
	bx lr                                @ 080733AE

@ ============================================================================
@ void sndHeapReset(void) { gSndHeapBase = NULL; }
@ ============================================================================
	thumb_func_start sndHeapReset
sndHeapReset: @ 0x080733B0
	ldr r1, .Lp080733B8                  @ 080733B0
	movs r0, #0                          @ 080733B2
	str r0, [r1]                         @ 080733B4
	bx lr                                @ 080733B6
.Lp080733B8:	.word gSndHeapBase

@ ============================================================================
@ int musAllocVoice(MusPlayer *P, MusChannel *c)           [musReadRow, on a note]
@ Music channels (up to 16) share P->maxVoices (8) mixing voices; SFX can reserve voices (owner == 1).
@   if (P->nChannels <= P->maxVoices) {            // fixed mapping: channel n -> voice n
@       i = c - P->chan;
@       if (P->voiceOwner[i] == 1) return 0;       // taken by an SFX: the note stays silent
@   } else {                                       // steal: free voice, else the quietest one that
@       i = -1; quietest = c->voice;               // is quieter than the new note
@       for (k = 0; k < P->maxVoices; k++) {
@           o = P->voiceOwner[k];
@           if (!o) { i = k; break; }
@           if (o != 1 && o->voice < quietest) { quietest = o->voice; i = k; }
@       }
@       if (i < 0) return 0;
@   }
@   if (P->voiceOwner[i]) P->voiceOwner[i]->voice &= ~1;
@   P->voiceOwner[i] = c; c->voice |= 1; return 1;
@ ============================================================================
	thumb_func_start musAllocVoice
musAllocVoice: @ 0x080733BC
	push {r4, r5, r6, r7, lr}            @ 080733BC
	adds r3, r0, #0                      @ 080733BE
	adds r7, r1, #0                      @ 080733C0
	ldrb r5, [r7, #0x1d]                 @ 080733C2
	ldr r0, .Lp08073400                  @ 080733C4
	adds r6, r3, r0                      @ 080733C6
	movs r1, #1                          @ 080733C8
	rsbs r1, r1, #0                      @ 080733CA
	ldr r2, .Lp08073404                  @ 080733CC
	adds r0, r3, r2                      @ 080733CE
	adds r2, #1                          @ 080733D0
	adds r4, r3, r2                      @ 080733D2
	ldrb r0, [r0]                        @ 080733D4
	ldrb r2, [r4]                        @ 080733D6
	cmp r0, r2                           @ 080733D8
	bhi .L08073408                       @ 080733DA
	subs r1, r7, #4                      @ 080733DC
	subs r1, r1, r3                      @ 080733DE
	lsls r0, r1, #3                      @ 080733E0
	subs r0, r0, r1                      @ 080733E2
	lsls r0, r0, #2                      @ 080733E4
	subs r0, r0, r1                      @ 080733E6
	lsls r1, r0, #9                      @ 080733E8
	subs r1, r1, r0                      @ 080733EA
	lsls r0, r1, #0x12                   @ 080733EC
	adds r1, r1, r0                      @ 080733EE
	rsbs r1, r1, #0                      @ 080733F0
	asrs r1, r1, #2                      @ 080733F2
	lsls r0, r1, #2                      @ 080733F4
	adds r0, r0, r6                      @ 080733F6
	ldr r0, [r0]                         @ 080733F8
	cmp r0, #1                           @ 080733FA
	bne .L0807344A                       @ 080733FC
	b .L08073474                         @ 080733FE
.Lp08073400:	.word PL_voiceOwner
.Lp08073404:	.word PL_nChannels
.L08073408:
	movs r2, #0                          @ 08073408
	ldrb r4, [r4]                        @ 0807340A
	cmp r2, r4                           @ 0807340C
	bge .L0807344A                       @ 0807340E
	ldr r4, .Lp08073420                  @ 08073410
	adds r0, r3, r4                      @ 08073412
	ldr r0, [r0]                         @ 08073414
	cmp r0, #0                           @ 08073416
	bne .L08073424                       @ 08073418
	movs r1, #0                          @ 0807341A
	b .L0807344E                         @ 0807341C
	.align 2, 0
.Lp08073420:	.word PL_voiceOwner
.L08073424:
	cmp r0, #1                           @ 08073424
	beq .L08073432                       @ 08073426
	ldrb r0, [r0, #0x1d]                 @ 08073428
	cmp r0, r5                           @ 0807342A
	bge .L08073432                       @ 0807342C
	adds r5, r0, #0                      @ 0807342E
	adds r1, r2, #0                      @ 08073430
.L08073432:
	adds r2, #1                          @ 08073432
	ldr r4, .Lp08073470                  @ 08073434
	adds r0, r3, r4                      @ 08073436
	ldrb r0, [r0]                        @ 08073438
	cmp r2, r0                           @ 0807343A
	bge .L0807344A                       @ 0807343C
	lsls r0, r2, #2                      @ 0807343E
	adds r0, r0, r6                      @ 08073440
	ldr r0, [r0]                         @ 08073442
	cmp r0, #0                           @ 08073444
	bne .L08073424                       @ 08073446
	adds r1, r2, #0                      @ 08073448
.L0807344A:
	cmp r1, #0                           @ 0807344A
	blt .L08073474                       @ 0807344C
.L0807344E:
	lsls r0, r1, #2                      @ 0807344E
	adds r3, r0, r6                      @ 08073450
	ldr r2, [r3]                         @ 08073452
	cmp r2, #0                           @ 08073454
	beq .L08073460                       @ 08073456
	ldrb r1, [r2, #0x1d]                 @ 08073458
	movs r0, #0xfe                       @ 0807345A
	ands r0, r1                          @ 0807345C
	strb r0, [r2, #0x1d]                 @ 0807345E
.L08073460:
	str r7, [r3]                         @ 08073460
	ldrb r1, [r7, #0x1d]                 @ 08073462
	movs r0, #1                          @ 08073464
	orrs r0, r1                          @ 08073466
	strb r0, [r7, #0x1d]                 @ 08073468
	movs r0, #1                          @ 0807346A
	b .L08073476                         @ 0807346C
	.align 2, 0
.Lp08073470:	.word PL_maxVoices
.L08073474:
	movs r0, #0                          @ 08073474
.L08073476:
	pop {r4, r5, r6, r7}                 @ 08073476
	pop {r1}                             @ 08073478
	bx r1                                @ 0807347A

@ ============================================================================
@ void musReadRow(MusPlayer *P)                            [musMix, at the first sample of a row]
@ Decodes one packed row (IT-style "mask" packing) and applies it.
@   p = P->patPtr; rowMask = 0;
@   while ((b = *p++) != 0) {
@       ch = (b & 0x3F) - 1; if (ch > 15) continue;
@       rowMask |= 1 << ch; c = &P->chan[ch];
@       mask = (b & 0x80) ? *p++ : c->mask;
@       slot = musFxMemSlot[c->cmd];                       // remember the previous row's parameter
@       if (slot <= 7 && c->param) c->fxMem[slot] = c->param;
@       c->param = c->cmd = c->volcol = c->note = c->ins = 0; c->pancol = 0x80;
@       if (mask & 0x02) c->ins = c->insLast = *p++;  else if (mask & 0x20) c->ins = c->insLast;
@       if (c->ins) {
@           c->insPtr = &musInstruments[P->module->insMap[c->ins - 1]];
@           if (c->insPtr->pan & 0x80) c->pan = c->insPtr->pan & 0x7F;
@           if (c->smpPtr) { c->vol = c->baseVol = c->smpPtr->vol;          // volume of the *previous* sample
@                            if (!(c->smpPtr->pan & 0x80)) c->pan = c->smpPtr->pan; }
@       }
@       if (mask & 0x04) { c->volcol = *p++; c->pancol = *p++; }  else if (mask & 0x40) { from last }
@       if (mask & 0x08) { c->cmd = *p++; c->param = *p++; }      else if (mask & 0x80) { from last }
@       if (c->cmd) { slot = musFxMemSlot[c->cmd]; if (slot <= 7 && !c->param) c->param = c->fxMem[slot]; }
@       if (mask & 0x01) c->note = c->noteLast = *p++;           else if (mask & 0x10) c->note = c->noteLast;
@       if (c->note) {
@           if (c->note <= 120) {
@               if (c->cmd == 3 || c->cmd == 5)               // tone portamento: only set the target
@                   c->portaTgt = 7680 - c->finetune/2 - (c->note - 13 + c->smpPtr->relNote) * 64;
@               else {
@                   n = c->note;
@                   if (c->insPtr) {
@                       I = c->insPtr; S = &I->samples[I->keymap[n - 1]];
@                       if (I->pan & 0x80) c->pan = I->pan & 0x7F;
@                       c->autoVib = S->vibType <= 2 ? 0 : -1;
@                       c->pos = 0; c->dir = 1; c->smpPtr = S;
@                       if (!(S->pan & 0x80)) c->pan = S->pan;
@                       c->vol = S->vol; c->finetune = S->finetune;
@                       c->mixVol = (c->chanVol * I->vol >> 6) * S->amp >> 6;
@                       c->volEnv = {64 << 8, 0, 0}; c->panEnv = {32 << 8, 0, 0};
@                       n += S->relNote;
@                   }
@                   c->fade = 0xFFFF; c->fadeSpd = 0;
@                   c->period = c->basePer = 7680 - c->finetune/2 - (n - 13) * 64;
@                   c->baseVol = c->vol;
@                   if (c->voice & 1) c->voice = c->vol << 1 | 1;
@                   else { c->voice = c->vol << 1; musAllocVoice(P, c); }
@               }
@           } else if (c->note == 121) {                      // key off
@               if (c->insPtr) c->fadeSpd = c->insPtr->fadeout * 2 | 1;
@           } else c->vol = 0;                                // note cut; baseVol is kept, so the next
@                                                             // tick restores the volume (bug, unused)
@           if (c->cmd == 4 || c->cmd == 6) c->autoVib = -1;  // vibrato disables auto-vibrato
@       }
@       if (!(c->pancol & 0x80)) c->pan = c->pancol;
@       musRowEffect(P, c); musVolumeColumn(c);
@       c->mask = mask;
@   }
@   P->rowMask = rowMask; P->patPtr = p;
@ ============================================================================
	thumb_func_start musReadRow
musReadRow: @ 0x0807347C
	push {r4, r5, r6, r7, lr}            @ 0807347C
	mov r7, sl                           @ 0807347E
	mov r6, sb                           @ 08073480
	mov r5, r8                           @ 08073482
	push {r5, r6, r7}                    @ 08073484
	sub sp, #0x10                        @ 08073486
	str r0, [sp]                         @ 08073488
	adds r1, r0, #0                      @ 0807348A
	adds r1, #4                          @ 0807348C
	str r1, [sp, #4]                     @ 0807348E
	movs r2, #0                          @ 08073490
	str r2, [sp, #8]                     @ 08073492
	ldr r3, .Lp080734E0                  @ 08073494
	adds r1, r0, r3                      @ 08073496
	ldr r5, [r1]                         @ 08073498
	ldrb r2, [r5]                        @ 0807349A
	adds r5, #1                          @ 0807349C
	cmp r2, #0                           @ 0807349E
	bne .L080734A4                       @ 080734A0
	b .L0807383C                         @ 080734A2
.L080734A4:
	movs r6, #0                          @ 080734A4
	mov sl, r6                           @ 080734A6
.L080734A8:
	movs r1, #0x3f                       @ 080734A8
	ands r1, r2                          @ 080734AA
	subs r1, #1                          @ 080734AC
	lsls r1, r1, #0x18                   @ 080734AE
	lsrs r1, r1, #0x18                   @ 080734B0
	cmp r1, #0xf                         @ 080734B2
	bls .L080734B8                       @ 080734B4
	b .L08073832                         @ 080734B6
.L080734B8:
	movs r0, #1                          @ 080734B8
	lsls r0, r1                          @ 080734BA
	ldr r3, [sp, #8]                     @ 080734BC
	orrs r3, r0                          @ 080734BE
	str r3, [sp, #8]                     @ 080734C0
	movs r0, #0x4c                       @ 080734C2
	muls r0, r1, r0                      @ 080734C4
	ldr r6, [sp, #4]                     @ 080734C6
	adds r4, r6, r0                      @ 080734C8
	movs r0, #0x80                       @ 080734CA
	ands r2, r0                          @ 080734CC
	cmp r2, #0                           @ 080734CE
	beq .L080734E4                       @ 080734D0
	ldrb r1, [r5]                        @ 080734D2
	mov r8, r1                           @ 080734D4
	adds r5, #1                          @ 080734D6
	adds r2, r4, #0                      @ 080734D8
	adds r2, #0x25                       @ 080734DA
	str r2, [sp, #0xc]                   @ 080734DC
	b .L080734EE                         @ 080734DE
.Lp080734E0:	.word PL_patPtr
.L080734E4:
	adds r0, r4, #0                      @ 080734E4
	adds r0, #0x25                       @ 080734E6
	ldrb r3, [r0]                        @ 080734E8
	mov r8, r3                           @ 080734EA
	str r0, [sp, #0xc]                   @ 080734EC
.L080734EE:
	ldr r1, .Lp08073538                  @ 080734EE
	ldrb r0, [r4, #0x18]                 @ 080734F0
	adds r0, r0, r1                      @ 080734F2
	ldrb r2, [r0]                        @ 080734F4
	adds r6, r1, #0                      @ 080734F6
	cmp r2, #7                           @ 080734F8
	bgt .L0807350A                       @ 080734FA
	ldrb r1, [r4, #0x1a]                 @ 080734FC
	cmp r1, #0                           @ 080734FE
	beq .L0807350A                       @ 08073500
	adds r0, r4, #0                      @ 08073502
	adds r0, #0x34                       @ 08073504
	adds r0, r0, r2                      @ 08073506
	strb r1, [r0]                        @ 08073508
.L0807350A:
	mov r0, sl                           @ 0807350A
	strb r0, [r4, #0x1a]                 @ 0807350C
	strb r0, [r4, #0x18]                 @ 0807350E
	strb r0, [r4, #0x14]                 @ 08073510
	strb r0, [r4, #0x12]                 @ 08073512
	strb r0, [r4, #0x10]                 @ 08073514
	movs r1, #0x80                       @ 08073516
	rsbs r1, r1, #0                      @ 08073518
	strb r1, [r4, #0x16]                 @ 0807351A
	movs r0, #2                          @ 0807351C
	mov r2, r8                           @ 0807351E
	ands r0, r2                          @ 08073520
	cmp r0, #0                           @ 08073522
	beq .L0807353C                       @ 08073524
	ldrb r0, [r5]                        @ 08073526
	strb r0, [r4, #0x12]                 @ 08073528
	ldrb r1, [r5]                        @ 0807352A
	movs r0, #0xff                       @ 0807352C
	ands r0, r1                          @ 0807352E
	strb r0, [r4, #0x13]                 @ 08073530
	adds r5, #1                          @ 08073532
	b .L0807354A                         @ 08073534
	.align 2, 0
.Lp08073538:	.word musFxMemSlot
.L0807353C:
	movs r0, #0x20                       @ 0807353C
	mov r3, r8                           @ 0807353E
	ands r0, r3                          @ 08073540
	cmp r0, #0                           @ 08073542
	beq .L080735AC                       @ 08073544
	ldrb r0, [r4, #0x13]                 @ 08073546
	strb r0, [r4, #0x12]                 @ 08073548
.L0807354A:
	ldr r0, [sp]                         @ 0807354A
	ldr r1, [r0]                         @ 0807354C
	ldrb r0, [r4, #0x12]                 @ 0807354E
	subs r0, #1                          @ 08073550
	lsls r0, r0, #1                      @ 08073552
	movs r2, #0xa2                       @ 08073554
	lsls r2, r2, #1                      @ 08073556
	adds r1, r1, r2                      @ 08073558
	adds r1, r1, r0                      @ 0807355A
	movs r3, #0                          @ 0807355C
	ldrsh r1, [r1, r3]                   @ 0807355E
	lsls r0, r1, #2                      @ 08073560
	adds r0, r0, r1                      @ 08073562
	lsls r0, r0, #4                      @ 08073564
	subs r0, r0, r1                      @ 08073566
	lsls r0, r0, #2                      @ 08073568
	ldr r1, .Lp080735D4                  @ 0807356A
	adds r0, r1, r0                      @ 0807356C
	str r0, [r4, #0x3c]                  @ 0807356E
	ldrb r1, [r0, #0x17]                 @ 08073570
	movs r3, #0x80                       @ 08073572
	adds r0, r3, #0                      @ 08073574
	ands r0, r1                          @ 08073576
	cmp r0, #0                           @ 08073578
	beq .L08073586                       @ 0807357A
	movs r0, #0x7f                       @ 0807357C
	ands r0, r1                          @ 0807357E
	adds r1, r4, #0                      @ 08073580
	adds r1, #0x2d                       @ 08073582
	strb r0, [r1]                        @ 08073584
.L08073586:
	ldr r2, [r4, #0x40]                  @ 08073586
	cmp r2, #0                           @ 08073588
	beq .L080735AC                       @ 0807358A
	ldrb r1, [r2, #0xc]                  @ 0807358C
	adds r0, r4, #0                      @ 0807358E
	adds r0, #0x2c                       @ 08073590
	strb r1, [r0]                        @ 08073592
	ldrb r1, [r2, #0xc]                  @ 08073594
	subs r0, #8                          @ 08073596
	strb r1, [r0]                        @ 08073598
	ldr r0, [r4, #0x40]                  @ 0807359A
	ldrb r1, [r0, #0x10]                 @ 0807359C
	adds r0, r3, #0                      @ 0807359E
	ands r0, r1                          @ 080735A0
	cmp r0, #0                           @ 080735A2
	bne .L080735AC                       @ 080735A4
	adds r0, r4, #0                      @ 080735A6
	adds r0, #0x2d                       @ 080735A8
	strb r1, [r0]                        @ 080735AA
.L080735AC:
	movs r0, #4                          @ 080735AC
	mov r2, r8                           @ 080735AE
	ands r0, r2                          @ 080735B0
	cmp r0, #0                           @ 080735B2
	beq .L080735D8                       @ 080735B4
	ldrb r0, [r5]                        @ 080735B6
	strb r0, [r4, #0x14]                 @ 080735B8
	ldrb r1, [r5]                        @ 080735BA
	movs r0, #0xff                       @ 080735BC
	ands r0, r1                          @ 080735BE
	strb r0, [r4, #0x15]                 @ 080735C0
	adds r5, #1                          @ 080735C2
	ldrb r0, [r5]                        @ 080735C4
	strb r0, [r4, #0x16]                 @ 080735C6
	ldrb r1, [r5]                        @ 080735C8
	movs r0, #0xff                       @ 080735CA
	ands r0, r1                          @ 080735CC
	strb r0, [r4, #0x17]                 @ 080735CE
	adds r5, #1                          @ 080735D0
	b .L080735EA                         @ 080735D2
.Lp080735D4:	.word musInstruments
.L080735D8:
	movs r0, #0x40                       @ 080735D8
	mov r3, r8                           @ 080735DA
	ands r0, r3                          @ 080735DC
	cmp r0, #0                           @ 080735DE
	beq .L080735EA                       @ 080735E0
	ldrb r0, [r4, #0x15]                 @ 080735E2
	strb r0, [r4, #0x14]                 @ 080735E4
	ldrb r0, [r4, #0x17]                 @ 080735E6
	strb r0, [r4, #0x16]                 @ 080735E8
.L080735EA:
	movs r0, #8                          @ 080735EA
	mov r1, r8                           @ 080735EC
	ands r0, r1                          @ 080735EE
	cmp r0, #0                           @ 080735F0
	beq .L0807362A                       @ 080735F2
	ldrb r0, [r5]                        @ 080735F4
	strb r0, [r4, #0x18]                 @ 080735F6
	ldrb r1, [r5]                        @ 080735F8
	movs r0, #0xff                       @ 080735FA
	ands r0, r1                          @ 080735FC
	strb r0, [r4, #0x19]                 @ 080735FE
	adds r5, #1                          @ 08073600
	ldrb r3, [r5]                        @ 08073602
	strb r3, [r4, #0x1a]                 @ 08073604
	ldrb r1, [r5]                        @ 08073606
	movs r0, #0xff                       @ 08073608
	ands r0, r1                          @ 0807360A
	strb r0, [r4, #0x1b]                 @ 0807360C
	adds r5, #1                          @ 0807360E
	ldrb r0, [r4, #0x18]                 @ 08073610
	adds r0, r0, r6                      @ 08073612
	ldrb r2, [r0]                        @ 08073614
	cmp r2, #7                           @ 08073616
	bgt .L0807363C                       @ 08073618
	lsls r0, r3, #0x18                   @ 0807361A
	cmp r0, #0                           @ 0807361C
	bne .L0807363C                       @ 0807361E
	adds r0, r4, #0                      @ 08073620
	adds r0, #0x34                       @ 08073622
	adds r0, r0, r2                      @ 08073624
	ldrb r0, [r0]                        @ 08073626
	b .L0807363A                         @ 08073628
.L0807362A:
	mov r0, r8                           @ 0807362A
	movs r2, #0x80                       @ 0807362C
	ands r0, r2                          @ 0807362E
	cmp r0, #0                           @ 08073630
	beq .L0807363C                       @ 08073632
	ldrb r0, [r4, #0x19]                 @ 08073634
	strb r0, [r4, #0x18]                 @ 08073636
	ldrb r0, [r4, #0x1b]                 @ 08073638
.L0807363A:
	strb r0, [r4, #0x1a]                 @ 0807363A
.L0807363C:
	movs r0, #1                          @ 0807363C
	mov r3, r8                           @ 0807363E
	ands r0, r3                          @ 08073640
	cmp r0, #0                           @ 08073642
	beq .L08073656                       @ 08073644
	ldrb r0, [r5]                        @ 08073646
	strb r0, [r4, #0x10]                 @ 08073648
	ldrb r1, [r5]                        @ 0807364A
	movs r0, #0xff                       @ 0807364C
	ands r0, r1                          @ 0807364E
	strb r0, [r4, #0x11]                 @ 08073650
	adds r5, #1                          @ 08073652
	b .L08073666                         @ 08073654
.L08073656:
	movs r0, #0x10                       @ 08073656
	mov r6, r8                           @ 08073658
	ands r0, r6                          @ 0807365A
	cmp r0, #0                           @ 0807365C
	bne .L08073662                       @ 0807365E
	b .L0807380E                         @ 08073660
.L08073662:
	ldrb r0, [r4, #0x11]                 @ 08073662
	strb r0, [r4, #0x10]                 @ 08073664
.L08073666:
	ldrb r0, [r4, #0x10]                 @ 08073666
	cmp r0, #0x78                        @ 08073668
	bls .L0807366E                       @ 0807366A
	b .L080737D8                         @ 0807366C
.L0807366E:
	mov ip, r0                           @ 0807366E
	ldrb r0, [r4, #0x18]                 @ 08073670
	cmp r0, #3                           @ 08073672
	beq .L0807367A                       @ 08073674
	cmp r0, #5                           @ 08073676
	bne .L080736A4                       @ 08073678
.L0807367A:
	mov r2, ip                           @ 0807367A
	lsls r1, r2, #0x10                   @ 0807367C
	asrs r1, r1, #0x10                   @ 0807367E
	subs r1, #0xc                        @ 08073680
	ldr r0, [r4, #0x40]                  @ 08073682
	movs r2, #0x11                       @ 08073684
	ldrsb r2, [r0, r2]                   @ 08073686
	adds r2, r2, r1                      @ 08073688
	ldrb r1, [r4, #0x1c]                 @ 0807368A
	lsls r1, r1, #0x18                   @ 0807368C
	asrs r1, r1, #0x19                   @ 0807368E
	movs r3, #0xf0                       @ 08073690
	lsls r3, r3, #5                      @ 08073692
	adds r0, r3, #0                      @ 08073694
	subs r0, r0, r1                      @ 08073696
	lsls r2, r2, #0x10                   @ 08073698
	asrs r2, r2, #0xa                    @ 0807369A
	subs r0, r0, r2                      @ 0807369C
	adds r0, #0x40                       @ 0807369E
	strh r0, [r4, #0x2a]                 @ 080736A0
	b .L080737FC                         @ 080736A2
.L080736A4:
	ldr r0, [r4, #0x3c]                  @ 080736A4
	adds r3, r4, #0                      @ 080736A6
	adds r3, #0x2c                       @ 080736A8
	cmp r0, #0                           @ 080736AA
	beq .L08073774                       @ 080736AC
	adds r3, r0, #0                      @ 080736AE
	mov r6, ip                           @ 080736B0
	lsls r0, r6, #0x10                   @ 080736B2
	asrs r0, r0, #0x10                   @ 080736B4
	adds r0, r3, r0                      @ 080736B6
	ldrb r1, [r0, #0x1b]                 @ 080736B8
	movs r0, #0x9c                       @ 080736BA
	lsls r0, r0, #1                      @ 080736BC
	adds r2, r3, r0                      @ 080736BE
	lsls r0, r1, #1                      @ 080736C0
	adds r0, r0, r1                      @ 080736C2
	lsls r0, r0, #4                      @ 080736C4
	ldr r1, [r2]                         @ 080736C6
	adds r6, r1, r0                      @ 080736C8
	ldrb r1, [r3, #0x17]                 @ 080736CA
	movs r0, #0x80                       @ 080736CC
	ands r0, r1                          @ 080736CE
	cmp r0, #0                           @ 080736D0
	beq .L080736DE                       @ 080736D2
	movs r0, #0x7f                       @ 080736D4
	ands r0, r1                          @ 080736D6
	adds r1, r4, #0                      @ 080736D8
	adds r1, #0x2d                       @ 080736DA
	strb r0, [r1]                        @ 080736DC
.L080736DE:
	adds r0, r6, #0                      @ 080736DE
	adds r0, #0x28                       @ 080736E0
	ldrb r0, [r0]                        @ 080736E2
	cmp r0, #2                           @ 080736E4
	bhi .L080736F2                       @ 080736E6
	adds r0, r4, #0                      @ 080736E8
	adds r0, #0x46                       @ 080736EA
	mov r1, sl                           @ 080736EC
	strh r1, [r0]                        @ 080736EE
	b .L080736FA                         @ 080736F0
.L080736F2:
	adds r1, r4, #0                      @ 080736F2
	adds r1, #0x46                       @ 080736F4
	ldr r0, .Lp080737C0                  @ 080736F6
	strh r0, [r1]                        @ 080736F8
.L080736FA:
	movs r7, #0                          @ 080736FA
	str r7, [r4, #0x20]                  @ 080736FC
	movs r2, #0                          @ 080736FE
	mov sb, r2                           @ 08073700
	movs r0, #1                          @ 08073702
	strh r0, [r4, #0x1e]                 @ 08073704
	str r6, [r4, #0x40]                  @ 08073706
	ldrb r1, [r6, #0x10]                 @ 08073708
	movs r0, #0x80                       @ 0807370A
	ands r0, r1                          @ 0807370C
	cmp r0, #0                           @ 0807370E
	bne .L08073718                       @ 08073710
	adds r0, r4, #0                      @ 08073712
	adds r0, #0x2d                       @ 08073714
	strb r1, [r0]                        @ 08073716
.L08073718:
	ldrb r0, [r6, #0xc]                  @ 08073718
	adds r2, r4, #0                      @ 0807371A
	adds r2, #0x2c                       @ 0807371C
	strb r0, [r2]                        @ 0807371E
	ldrb r0, [r6, #0xe]                  @ 08073720
	strb r0, [r4, #0x1c]                 @ 08073722
	adds r0, r4, #0                      @ 08073724
	adds r0, #0x2e                       @ 08073726
	movs r1, #0                          @ 08073728
	ldrsb r1, [r0, r1]                   @ 0807372A
	ldrb r0, [r3, #0x16]                 @ 0807372C
	muls r0, r1, r0                      @ 0807372E
	asrs r0, r0, #6                      @ 08073730
	adds r3, r4, #0                      @ 08073732
	adds r3, #0x2f                       @ 08073734
	strb r0, [r3]                        @ 08073736
	movs r1, #0                          @ 08073738
	ldrsb r1, [r3, r1]                   @ 0807373A
	ldrb r0, [r6, #0xd]                  @ 0807373C
	muls r0, r1, r0                      @ 0807373E
	asrs r0, r0, #6                      @ 08073740
	strb r0, [r3]                        @ 08073742
	movs r3, #0x80                       @ 08073744
	lsls r3, r3, #7                      @ 08073746
	strh r3, [r4]                        @ 08073748
	strh r7, [r4, #4]                    @ 0807374A
	mov r6, sb                           @ 0807374C
	strb r6, [r4, #2]                    @ 0807374E
	adds r0, r4, #0                      @ 08073750
	adds r0, #8                          @ 08073752
	movs r1, #0x80                       @ 08073754
	lsls r1, r1, #6                      @ 08073756
	strh r1, [r4, #8]                    @ 08073758
	strh r7, [r0, #4]                    @ 0807375A
	strb r6, [r0, #2]                    @ 0807375C
	ldr r0, [r4, #0x40]                  @ 0807375E
	movs r1, #0x11                       @ 08073760
	ldrsb r1, [r0, r1]                   @ 08073762
	mov r3, ip                           @ 08073764
	lsls r0, r3, #0x10                   @ 08073766
	asrs r0, r0, #0x10                   @ 08073768
	adds r0, r0, r1                      @ 0807376A
	lsls r0, r0, #0x10                   @ 0807376C
	lsrs r0, r0, #0x10                   @ 0807376E
	mov ip, r0                           @ 08073770
	adds r3, r2, #0                      @ 08073772
.L08073774:
	mov r6, ip                           @ 08073774
	lsls r2, r6, #0x10                   @ 08073776
	ldr r0, .Lp080737C0                  @ 08073778
	strh r0, [r4, #0x30]                 @ 0807377A
	mov r0, sl                           @ 0807377C
	strh r0, [r4, #0x32]                 @ 0807377E
	movs r1, #0x1c                       @ 08073780
	ldrsb r1, [r4, r1]                   @ 08073782
	lsrs r0, r1, #0x1f                   @ 08073784
	adds r1, r1, r0                      @ 08073786
	asrs r1, r1, #1                      @ 08073788
	movs r6, #0xf0                       @ 0807378A
	lsls r6, r6, #5                      @ 0807378C
	adds r0, r6, #0                      @ 0807378E
	subs r0, r0, r1                      @ 08073790
	ldr r1, .Lp080737C4                  @ 08073792
	adds r2, r2, r1                      @ 08073794
	asrs r2, r2, #0xa                    @ 08073796
	subs r0, r0, r2                      @ 08073798
	adds r0, #0x40                       @ 0807379A
	strh r0, [r4, #0x26]                 @ 0807379C
	strh r0, [r4, #0x28]                 @ 0807379E
	ldrb r1, [r3]                        @ 080737A0
	adds r0, r4, #0                      @ 080737A2
	adds r0, #0x24                       @ 080737A4
	movs r6, #0                          @ 080737A6
	strb r1, [r0]                        @ 080737A8
	ldrb r1, [r4, #0x1d]                 @ 080737AA
	movs r2, #1                          @ 080737AC
	movs r0, #1                          @ 080737AE
	ands r0, r1                          @ 080737B0
	cmp r0, #0                           @ 080737B2
	beq .L080737C8                       @ 080737B4
	ldrb r0, [r3]                        @ 080737B6
	lsls r0, r0, #1                      @ 080737B8
	orrs r0, r2                          @ 080737BA
	strb r0, [r4, #0x1d]                 @ 080737BC
	b .L080737FC                         @ 080737BE
.Lp080737C0:	.word 0x0000FFFF
.Lp080737C4:	.word 0xFFF40000
.L080737C8:
	ldrb r0, [r3]                        @ 080737C8
	lsls r0, r0, #1                      @ 080737CA
	strb r0, [r4, #0x1d]                 @ 080737CC
	ldr r0, [sp]                         @ 080737CE
	adds r1, r4, #0                      @ 080737D0
	bl musAllocVoice                     @ 080737D2
	b .L080737FC                         @ 080737D6
.L080737D8:
	cmp r0, #0x79                        @ 080737D8
	bne .L080737F4                       @ 080737DA
	ldr r0, [r4, #0x3c]                  @ 080737DC
	cmp r0, #0                           @ 080737DE
	beq .L080737FC                       @ 080737E0
	movs r2, #0x9a                       @ 080737E2
	lsls r2, r2, #1                      @ 080737E4
	adds r0, r0, r2                      @ 080737E6
	ldrh r0, [r0]                        @ 080737E8
	lsls r0, r0, #1                      @ 080737EA
	movs r1, #1                          @ 080737EC
	orrs r0, r1                          @ 080737EE
	strh r0, [r4, #0x32]                 @ 080737F0
	b .L080737FC                         @ 080737F2
.L080737F4:
	adds r0, r4, #0                      @ 080737F4
	adds r0, #0x2c                       @ 080737F6
	mov r3, sl                           @ 080737F8
	strb r3, [r0]                        @ 080737FA
.L080737FC:
	ldrb r0, [r4, #0x18]                 @ 080737FC
	cmp r0, #4                           @ 080737FE
	beq .L08073806                       @ 08073800
	cmp r0, #6                           @ 08073802
	bne .L0807380E                       @ 08073804
.L08073806:
	adds r1, r4, #0                      @ 08073806
	adds r1, #0x46                       @ 08073808
	ldr r0, .Lp0807385C                  @ 0807380A
	strh r0, [r1]                        @ 0807380C
.L0807380E:
	ldrb r1, [r4, #0x16]                 @ 0807380E
	movs r0, #0x80                       @ 08073810
	ands r0, r1                          @ 08073812
	cmp r0, #0                           @ 08073814
	bne .L0807381E                       @ 08073816
	adds r0, r4, #0                      @ 08073818
	adds r0, #0x2d                       @ 0807381A
	strb r1, [r0]                        @ 0807381C
.L0807381E:
	ldr r0, [sp]                         @ 0807381E
	adds r1, r4, #0                      @ 08073820
	bl musRowEffect                      @ 08073822
	adds r0, r4, #0                      @ 08073826
	bl musVolumeColumn                   @ 08073828
	mov r1, r8                           @ 0807382C
	ldr r6, [sp, #0xc]                   @ 0807382E
	strb r1, [r6]                        @ 08073830
.L08073832:
	ldrb r2, [r5]                        @ 08073832
	adds r5, #1                          @ 08073834
	cmp r2, #0                           @ 08073836
	beq .L0807383C                       @ 08073838
	b .L080734A8                         @ 0807383A
.L0807383C:
	ldr r2, [sp]                         @ 0807383C
	ldr r3, .Lp08073860                  @ 0807383E
	adds r1, r2, r3                      @ 08073840
	ldr r6, [sp, #8]                     @ 08073842
	str r6, [r1]                         @ 08073844
	subs r3, #0x18                       @ 08073846
	adds r1, r2, r3                      @ 08073848
	str r5, [r1]                         @ 0807384A
	add sp, #0x10                        @ 0807384C
	pop {r3, r4, r5}                     @ 0807384E
	mov r8, r3                           @ 08073850
	mov sb, r4                           @ 08073852
	mov sl, r5                           @ 08073854
	pop {r4, r5, r6, r7}                 @ 08073856
	pop {r1}                             @ 08073858
	bx r1                                @ 0807385A
.Lp0807385C:	.word 0x0000FFFF
.Lp08073860:	.word PL_rowMask

@ ============================================================================
@ void musEnvelopeTick(EnvState *e, Envelope *env, int released)   [once per tick per channel]
@   if (e->value & 1) return;                                    // finished
@   cur = e->idx & 15; next = e->idx >> 4;
@   if (!released && (env->type & 2) && cur == env->sustain) return;   // hold at the sustain point
@   if (e->tick != env->points[next].x) {                        // between points
@       e->value += env->slope[cur] * 2;                         // slope is stored in (y << 7) per tick
@       e->tick++;
@       return;
@   }
@   cur = next; e->idx = next << 4 | next;                       // arrived at point "next"
@   if (!(env->type & 4)) e->idx = (cur + 1) << 4 | cur;
@   else if (cur == env->loopEnd) {
@       e->idx = next << 4 | env->loopStart; e->tick = env->points[env->loopStart].x;
@       if (cur == env->loopStart) e->idx = env->loopStart * 0x11;
@   }   /* else: loop flag set but not at the loop end -> "next" is not advanced and the envelope
@          stays on this point for ever (bug; no MvDK instrument has a looped envelope) */
@   e->value = env->points[cur].y << 8;                          // cur = the loop END after a jump
@   if ((e->idx >> 4) == env->count) e->value |= 1;              // past the last point: done
@ The tick counter is not advanced on the tick that lands on a point, so every envelope segment lasts
@ one tick longer than written.
@ ============================================================================
	thumb_func_start musEnvelopeTick
musEnvelopeTick: @ 0x08073864
	push {r4, r5, r6, r7, lr}            @ 08073864
	adds r4, r0, #0                      @ 08073866
	adds r5, r1, #0                      @ 08073868
	ldrh r1, [r4]                        @ 0807386A
	movs r0, #1                          @ 0807386C
	ands r0, r1                          @ 0807386E
	cmp r0, #0                           @ 08073870
	bne .L08073938                       @ 08073872
	ldrb r0, [r4, #2]                    @ 08073874
	movs r6, #0xf                        @ 08073876
	ands r6, r0                          @ 08073878
	adds r7, r0, #0                      @ 0807387A
	cmp r2, #0                           @ 0807387C
	bne .L08073898                       @ 0807387E
	adds r0, r5, #0                      @ 08073880
	adds r0, #0x35                       @ 08073882
	ldrb r1, [r0]                        @ 08073884
	movs r0, #2                          @ 08073886
	ands r0, r1                          @ 08073888
	cmp r0, #0                           @ 0807388A
	beq .L08073898                       @ 0807388C
	adds r0, r5, #0                      @ 0807388E
	adds r0, #0x31                       @ 08073890
	ldrb r0, [r0]                        @ 08073892
	cmp r6, r0                           @ 08073894
	beq .L08073938                       @ 08073896
.L08073898:
	lsrs r1, r7, #4                      @ 08073898
	lsls r0, r1, #2                      @ 0807389A
	adds r0, r5, r0                      @ 0807389C
	ldrh r2, [r4, #4]                    @ 0807389E
	ldrh r0, [r0]                        @ 080738A0
	cmp r2, r0                           @ 080738A2
	bne .L08073922                       @ 080738A4
	movs r0, #0xf0                       @ 080738A6
	mov ip, r0                           @ 080738A8
	mov r3, ip                           @ 080738AA
	ands r3, r7                          @ 080738AC
	orrs r3, r1                          @ 080738AE
	strb r3, [r4, #2]                    @ 080738B0
	movs r7, #0xf                        @ 080738B2
	adds r2, r3, #0                      @ 080738B4
	ands r2, r7                          @ 080738B6
	adds r6, r2, #0                      @ 080738B8
	adds r0, r5, #0                      @ 080738BA
	adds r0, #0x35                       @ 080738BC
	ldrb r1, [r0]                        @ 080738BE
	movs r0, #4                          @ 080738C0
	ands r0, r1                          @ 080738C2
	cmp r0, #0                           @ 080738C4
	beq .L080738FA                       @ 080738C6
	adds r0, r5, #0                      @ 080738C8
	adds r0, #0x34                       @ 080738CA
	ldrb r0, [r0]                        @ 080738CC
	cmp r6, r0                           @ 080738CE
	bne .L08073902                       @ 080738D0
	mov r2, ip                           @ 080738D2
	ands r2, r3                          @ 080738D4
	adds r0, r5, #0                      @ 080738D6
	adds r0, #0x33                       @ 080738D8
	ldrb r0, [r0]                        @ 080738DA
	orrs r2, r0                          @ 080738DC
	strb r2, [r4, #2]                    @ 080738DE
	adds r3, r2, #0                      @ 080738E0
	ands r3, r7                          @ 080738E2
	lsls r1, r3, #2                      @ 080738E4
	adds r1, r5, r1                      @ 080738E6
	ldrh r1, [r1]                        @ 080738E8
	strh r1, [r4, #4]                    @ 080738EA
	lsls r0, r0, #0x18                   @ 080738EC
	lsrs r0, r0, #0x18                   @ 080738EE
	cmp r6, r0                           @ 080738F0
	bne .L08073902                       @ 080738F2
	lsls r0, r2, #4                      @ 080738F4
	orrs r0, r3                          @ 080738F6
	b .L08073900                         @ 080738F8
.L080738FA:
	adds r0, r6, #1                      @ 080738FA
	lsls r0, r0, #4                      @ 080738FC
	orrs r0, r2                          @ 080738FE
.L08073900:
	strb r0, [r4, #2]                    @ 08073900
.L08073902:
	lsls r0, r6, #2                      @ 08073902
	adds r0, r5, r0                      @ 08073904
	ldrh r0, [r0, #2]                    @ 08073906
	lsls r2, r0, #8                      @ 08073908
	strh r2, [r4]                        @ 0807390A
	ldrb r0, [r4, #2]                    @ 0807390C
	adds r1, r5, #0                      @ 0807390E
	adds r1, #0x30                       @ 08073910
	lsrs r0, r0, #4                      @ 08073912
	ldrb r1, [r1]                        @ 08073914
	cmp r0, r1                           @ 08073916
	bne .L08073938                       @ 08073918
	movs r0, #1                          @ 0807391A
	orrs r2, r0                          @ 0807391C
	strh r2, [r4]                        @ 0807391E
	b .L08073938                         @ 08073920
.L08073922:
	lsls r1, r6, #1                      @ 08073922
	adds r0, r5, #0                      @ 08073924
	adds r0, #0x36                       @ 08073926
	adds r0, r0, r1                      @ 08073928
	ldrh r0, [r0]                        @ 0807392A
	lsls r0, r0, #1                      @ 0807392C
	ldrh r1, [r4]                        @ 0807392E
	adds r0, r0, r1                      @ 08073930
	strh r0, [r4]                        @ 08073932
	adds r0, r2, #1                      @ 08073934
	strh r0, [r4, #4]                    @ 08073936
.L08073938:
	pop {r4, r5, r6, r7}                 @ 08073938
	pop {r0}                             @ 0807393A
	bx r0                                @ 0807393C
	.align 2, 0

@ ============================================================================
@ void musTickVolume(MusChannel *c)          [first slice of every tick, channels with a cell in the row]
@   if (c->fadeSpd >> 1) { c->fade -= c->fadeSpd >> 1; if (c->fade < 0) c->fade = 0; }
@   switch (c->volcol & 0xF0) {                       // volume column slides, on every tick incl. tick 0
@       case 0x60: c->vol -= c->volcol & 15; break;   case 0x70: c->vol += c->volcol & 15; break;
@       case 0xD0: c->pan -= c->volcol & 15; break;   case 0xE0: c->pan += c->volcol & 15; break;
@   }
@   if (c->insPtr->volEnv.type & 1) musEnvelopeTick(&c->volEnv, &c->insPtr->volEnv, c->fadeSpd & 1);
@   if (c->insPtr->panEnv.type & 1) musEnvelopeTick(&c->panEnv, &c->insPtr->panEnv, c->fadeSpd & 1);
@ Only called for channels that have a cell in the current row (see musMixSlice), so the fadeout
@ after a key-off only advances on such rows.
@ ============================================================================
	thumb_func_start musTickVolume
musTickVolume: @ 0x08073940
	push {r4, r5, lr}                    @ 08073940
	adds r4, r0, #0                      @ 08073942
	ldrb r2, [r4, #0x14]                 @ 08073944
	ldrh r0, [r4, #0x32]                 @ 08073946
	lsrs r0, r0, #1                      @ 08073948
	cmp r0, #0                           @ 0807394A
	beq .L0807395E                       @ 0807394C
	ldrh r1, [r4, #0x30]                 @ 0807394E
	subs r1, r1, r0                      @ 08073950
	cmp r1, #0                           @ 08073952
	bge .L0807395C                       @ 08073954
	movs r0, #0                          @ 08073956
	strh r0, [r4, #0x30]                 @ 08073958
	b .L0807395E                         @ 0807395A
.L0807395C:
	strh r1, [r4, #0x30]                 @ 0807395C
.L0807395E:
	movs r0, #0xf0                       @ 0807395E
	ands r0, r2                          @ 08073960
	cmp r0, #0xd0                        @ 08073962
	beq .L08073998                       @ 08073964
	cmp r0, #0xd0                        @ 08073966
	bgt .L08073974                       @ 08073968
	cmp r0, #0x60                        @ 0807396A
	beq .L0807398A                       @ 0807396C
	cmp r0, #0x70                        @ 0807396E
	beq .L0807397A                       @ 08073970
	b .L080739B6                         @ 08073972
.L08073974:
	cmp r0, #0xe0                        @ 08073974
	beq .L080739A8                       @ 08073976
	b .L080739B6                         @ 08073978
.L0807397A:
	adds r0, r4, #0                      @ 0807397A
	adds r0, #0x2c                       @ 0807397C
	movs r1, #0xf                        @ 0807397E
	ands r2, r1                          @ 08073980
	ldrb r3, [r0]                        @ 08073982
	adds r1, r2, r3                      @ 08073984
	strb r1, [r0]                        @ 08073986
	b .L080739B6                         @ 08073988
.L0807398A:
	adds r1, r4, #0                      @ 0807398A
	adds r1, #0x2c                       @ 0807398C
	movs r0, #0xf                        @ 0807398E
	ands r2, r0                          @ 08073990
	ldrb r0, [r1]                        @ 08073992
	subs r0, r0, r2                      @ 08073994
	b .L080739B4                         @ 08073996
.L08073998:
	adds r3, r4, #0                      @ 08073998
	adds r3, #0x2d                       @ 0807399A
	movs r0, #0xf                        @ 0807399C
	ands r2, r0                          @ 0807399E
	ldrb r0, [r3]                        @ 080739A0
	subs r0, r0, r2                      @ 080739A2
	strb r0, [r3]                        @ 080739A4
	b .L080739B6                         @ 080739A6
.L080739A8:
	adds r1, r4, #0                      @ 080739A8
	adds r1, #0x2d                       @ 080739AA
	movs r0, #0xf                        @ 080739AC
	ands r2, r0                          @ 080739AE
	ldrb r3, [r1]                        @ 080739B0
	adds r0, r2, r3                      @ 080739B2
.L080739B4:
	strb r0, [r1]                        @ 080739B4
.L080739B6:
	ldr r2, [r4, #0x3c]                  @ 080739B6
	adds r0, r2, #0                      @ 080739B8
	adds r0, #0xc9                       @ 080739BA
	ldrb r1, [r0]                        @ 080739BC
	movs r5, #1                          @ 080739BE
	adds r0, r5, #0                      @ 080739C0
	ands r0, r1                          @ 080739C2
	cmp r0, #0                           @ 080739C4
	beq .L080739D8                       @ 080739C6
	adds r1, r2, #0                      @ 080739C8
	adds r1, #0x94                       @ 080739CA
	ldrh r0, [r4, #0x32]                 @ 080739CC
	adds r2, r5, #0                      @ 080739CE
	ands r2, r0                          @ 080739D0
	adds r0, r4, #0                      @ 080739D2
	bl musEnvelopeTick                   @ 080739D4
.L080739D8:
	ldr r2, [r4, #0x3c]                  @ 080739D8
	ldr r1, .Lp08073A00                  @ 080739DA
	adds r0, r2, r1                      @ 080739DC
	ldrb r1, [r0]                        @ 080739DE
	adds r0, r5, #0                      @ 080739E0
	ands r0, r1                          @ 080739E2
	cmp r0, #0                           @ 080739E4
	beq .L080739FA                       @ 080739E6
	adds r0, r4, #0                      @ 080739E8
	adds r0, #8                          @ 080739EA
	adds r1, r2, #0                      @ 080739EC
	adds r1, #0xe4                       @ 080739EE
	ldrh r3, [r4, #0x32]                 @ 080739F0
	adds r2, r5, #0                      @ 080739F2
	ands r2, r3                          @ 080739F4
	bl musEnvelopeTick                   @ 080739F6
.L080739FA:
	pop {r4, r5}                         @ 080739FA
	pop {r0}                             @ 080739FC
	bx r0                                @ 080739FE
.Lp08073A00:	.word INS_panEnv+ENV_type

@ ============================================================================
@ void fxArpeggio(MusChannel *c, s16 *mix, int n)          effect 0xy
@   if (c->param) {
@       off[3] = { 0, musArpOffsets[x], musArpOffsets[y] };
@       c->period = max(40, c->basePer - off[gMusTick % 3]);
@   }
@ Every tick handler ends with the same mixing tail:
@   save = c->pan; if (!stereo) c->pan = 32; gMusCurChannel = c;
@   gSndMixChannelFn(c, mix, n, gMusTickPos == 0); c->pan = save;
@ ============================================================================
	thumb_func_start fxArpeggio
fxArpeggio: @ 0x08073A04
	push {r4, r5, r6, r7, lr}            @ 08073A04
	mov r7, sl                           @ 08073A06
	mov r6, sb                           @ 08073A08
	mov r5, r8                           @ 08073A0A
	push {r5, r6, r7}                    @ 08073A0C
	sub sp, #0xc                         @ 08073A0E
	adds r5, r0, #0                      @ 08073A10
	mov ip, r1                           @ 08073A12
	mov r8, r2                           @ 08073A14
	ldrb r4, [r5, #0x1a]                 @ 08073A16
	cmp r4, #0                           @ 08073A18
	bne .L08073A68                       @ 08073A1A
	adds r6, r5, #0                      @ 08073A1C
	adds r6, #0x2d                       @ 08073A1E
	movs r7, #0                          @ 08073A20
	ldrsb r7, [r6, r7]                   @ 08073A22
	ldr r0, .Lp08073A58                  @ 08073A24
	ldr r0, [r0]                         @ 08073A26
	ldrb r1, [r0, #1]                    @ 08073A28
	movs r0, #0x10                       @ 08073A2A
	ands r0, r1                          @ 08073A2C
	cmp r0, #0                           @ 08073A2E
	bne .L08073A36                       @ 08073A30
	movs r0, #0x20                       @ 08073A32
	strb r0, [r6]                        @ 08073A34
.L08073A36:
	ldr r0, .Lp08073A5C                  @ 08073A36
	str r5, [r0]                         @ 08073A38
	ldr r4, .Lp08073A60                  @ 08073A3A
	movs r3, #0                          @ 08073A3C
	ldr r0, .Lp08073A64                  @ 08073A3E
	ldr r0, [r0]                         @ 08073A40
	cmp r0, #0                           @ 08073A42
	bne .L08073A48                       @ 08073A44
	movs r3, #1                          @ 08073A46
.L08073A48:
	ldr r4, [r4]                         @ 08073A48
	adds r0, r5, #0                      @ 08073A4A
	mov r1, ip                           @ 08073A4C
	mov r2, r8                           @ 08073A4E
	bl _call_via_r4                      @ 08073A50
	strb r7, [r6]                        @ 08073A54
	b .L08073AF0                         @ 08073A56
.Lp08073A58:	.word gSnd
.Lp08073A5C:	.word gMusCurChannel
.Lp08073A60:	.word gSndMixChannelFn
.Lp08073A64:	.word gMusTickPos
.L08073A68:
	ldr r0, .Lp08073B00                  @ 08073A68
	ldr r3, [r0]                         @ 08073A6A
	adds r7, r5, #0                      @ 08073A6C
	adds r7, #0x2d                       @ 08073A6E
	ldr r0, .Lp08073B04                  @ 08073A70
	mov sb, r0                           @ 08073A72
	ldr r1, .Lp08073B08                  @ 08073A74
	mov sl, r1                           @ 08073A76
	ldr r6, .Lp08073B0C                  @ 08073A78
	lsrs r0, r4, #4                      @ 08073A7A
	cmp r3, #2                           @ 08073A7C
	ble .L08073A86                       @ 08073A7E
.L08073A80:
	subs r3, #3                          @ 08073A80
	cmp r3, #2                           @ 08073A82
	bgt .L08073A80                       @ 08073A84
.L08073A86:
	movs r2, #0x28                       @ 08073A86
	ldrsh r1, [r5, r2]                   @ 08073A88
	str r1, [sp]                         @ 08073A8A
	movs r2, #0xf                        @ 08073A8C
	lsls r0, r0, #2                      @ 08073A8E
	adds r0, r0, r6                      @ 08073A90
	ldr r0, [r0]                         @ 08073A92
	subs r0, r1, r0                      @ 08073A94
	str r0, [sp, #4]                     @ 08073A96
	ands r4, r2                          @ 08073A98
	lsls r0, r4, #2                      @ 08073A9A
	adds r0, r0, r6                      @ 08073A9C
	ldr r0, [r0]                         @ 08073A9E
	subs r1, r1, r0                      @ 08073AA0
	str r1, [sp, #8]                     @ 08073AA2
	lsls r0, r3, #2                      @ 08073AA4
	add r0, sp                           @ 08073AA6
	ldr r0, [r0]                         @ 08073AA8
	strh r0, [r5, #0x26]                 @ 08073AAA
	lsls r0, r0, #0x10                   @ 08073AAC
	asrs r0, r0, #0x10                   @ 08073AAE
	cmp r0, #0x27                        @ 08073AB0
	bgt .L08073AB8                       @ 08073AB2
	movs r0, #0x28                       @ 08073AB4
	strh r0, [r5, #0x26]                 @ 08073AB6
.L08073AB8:
	adds r2, r7, #0                      @ 08073AB8
	movs r6, #0                          @ 08073ABA
	ldrsb r6, [r2, r6]                   @ 08073ABC
	mov r1, sb                           @ 08073ABE
	ldr r0, [r1]                         @ 08073AC0
	ldrb r1, [r0, #1]                    @ 08073AC2
	movs r0, #0x10                       @ 08073AC4
	ands r0, r1                          @ 08073AC6
	cmp r0, #0                           @ 08073AC8
	bne .L08073AD0                       @ 08073ACA
	movs r0, #0x20                       @ 08073ACC
	strb r0, [r2]                        @ 08073ACE
.L08073AD0:
	mov r2, sl                           @ 08073AD0
	str r5, [r2]                         @ 08073AD2
	movs r3, #0                          @ 08073AD4
	ldr r1, .Lp08073B10                  @ 08073AD6
	ldr r0, [r1]                         @ 08073AD8
	cmp r0, #0                           @ 08073ADA
	bne .L08073AE0                       @ 08073ADC
	movs r3, #1                          @ 08073ADE
.L08073AE0:
	ldr r2, .Lp08073B14                  @ 08073AE0
	ldr r4, [r2]                         @ 08073AE2
	adds r0, r5, #0                      @ 08073AE4
	mov r1, ip                           @ 08073AE6
	mov r2, r8                           @ 08073AE8
	bl _call_via_r4                      @ 08073AEA
	strb r6, [r7]                        @ 08073AEE
.L08073AF0:
	add sp, #0xc                         @ 08073AF0
	pop {r3, r4, r5}                     @ 08073AF2
	mov r8, r3                           @ 08073AF4
	mov sb, r4                           @ 08073AF6
	mov sl, r5                           @ 08073AF8
	pop {r4, r5, r6, r7}                 @ 08073AFA
	pop {r0}                             @ 08073AFC
	bx r0                                @ 08073AFE
.Lp08073B00:	.word gMusTick
.Lp08073B04:	.word gSnd
.Lp08073B08:	.word gMusCurChannel
.Lp08073B0C:	.word musArpOffsets
.Lp08073B10:	.word gMusTickPos
.Lp08073B14:	.word gSndMixChannelFn

@ ============================================================================
@ void fxPortaUp(MusChannel *c, s16 *mix, int n)           effect 1xx (memory slot 0)
@   p = c->param ? c->param : c->fxMem[0];
@   if (gMusTick) { c->period = max(40, c->period - p * 4); c->basePer = c->period; }
@   mix (see fxArpeggio)
@ ============================================================================
	thumb_func_start fxPortaUp
fxPortaUp: @ 0x08073B18
	push {r4, r5, r6, r7, lr}            @ 08073B18
	adds r3, r0, #0                      @ 08073B1A
	mov ip, r1                           @ 08073B1C
	ldrb r1, [r3, #0x1a]                 @ 08073B1E
	cmp r1, #0                           @ 08073B20
	bne .L08073B28                       @ 08073B22
	adds r0, #0x34                       @ 08073B24
	ldrb r1, [r0]                        @ 08073B26
.L08073B28:
	ldr r0, .Lp08073B88                  @ 08073B28
	ldr r0, [r0]                         @ 08073B2A
	cmp r0, #0                           @ 08073B2C
	beq .L08073B48                       @ 08073B2E
	lsls r1, r1, #2                      @ 08073B30
	ldrh r0, [r3, #0x26]                 @ 08073B32
	subs r0, r0, r1                      @ 08073B34
	strh r0, [r3, #0x26]                 @ 08073B36
	lsls r0, r0, #0x10                   @ 08073B38
	asrs r0, r0, #0x10                   @ 08073B3A
	cmp r0, #0x27                        @ 08073B3C
	bgt .L08073B44                       @ 08073B3E
	movs r0, #0x28                       @ 08073B40
	strh r0, [r3, #0x26]                 @ 08073B42
.L08073B44:
	ldrh r0, [r3, #0x26]                 @ 08073B44
	strh r0, [r3, #0x28]                 @ 08073B46
.L08073B48:
	adds r5, r3, #0                      @ 08073B48
	adds r5, #0x2d                       @ 08073B4A
	movs r7, #0                          @ 08073B4C
	ldrsb r7, [r5, r7]                   @ 08073B4E
	ldr r0, .Lp08073B8C                  @ 08073B50
	ldr r0, [r0]                         @ 08073B52
	ldrb r1, [r0, #1]                    @ 08073B54
	movs r0, #0x10                       @ 08073B56
	ands r0, r1                          @ 08073B58
	cmp r0, #0                           @ 08073B5A
	bne .L08073B62                       @ 08073B5C
	movs r0, #0x20                       @ 08073B5E
	strb r0, [r5]                        @ 08073B60
.L08073B62:
	ldr r0, .Lp08073B90                  @ 08073B62
	str r3, [r0]                         @ 08073B64
	ldr r4, .Lp08073B94                  @ 08073B66
	movs r6, #0                          @ 08073B68
	ldr r0, .Lp08073B98                  @ 08073B6A
	ldr r0, [r0]                         @ 08073B6C
	cmp r0, #0                           @ 08073B6E
	bne .L08073B74                       @ 08073B70
	movs r6, #1                          @ 08073B72
.L08073B74:
	ldr r4, [r4]                         @ 08073B74
	adds r0, r3, #0                      @ 08073B76
	mov r1, ip                           @ 08073B78
	adds r3, r6, #0                      @ 08073B7A
	bl _call_via_r4                      @ 08073B7C
	strb r7, [r5]                        @ 08073B80
	pop {r4, r5, r6, r7}                 @ 08073B82
	pop {r0}                             @ 08073B84
	bx r0                                @ 08073B86
.Lp08073B88:	.word gMusTick
.Lp08073B8C:	.word gSnd
.Lp08073B90:	.word gMusCurChannel
.Lp08073B94:	.word gSndMixChannelFn
.Lp08073B98:	.word gMusTickPos

@ ============================================================================
@ void fxPortaDown(MusChannel *c, s16 *mix, int n)         effect 2xx (memory slot 1)
@   p = c->param ? c->param : c->fxMem[1];
@   if (gMusTick) { c->period = min(7680, c->period + p * 4); c->basePer = c->period; }
@   mix
@ ============================================================================
	thumb_func_start fxPortaDown
fxPortaDown: @ 0x08073B9C
	push {r4, r5, r6, r7, lr}            @ 08073B9C
	adds r3, r0, #0                      @ 08073B9E
	mov ip, r1                           @ 08073BA0
	ldrb r1, [r3, #0x1a]                 @ 08073BA2
	cmp r1, #0                           @ 08073BA4
	bne .L08073BAC                       @ 08073BA6
	adds r0, #0x35                       @ 08073BA8
	ldrb r1, [r0]                        @ 08073BAA
.L08073BAC:
	ldr r0, .Lp08073C10                  @ 08073BAC
	ldr r0, [r0]                         @ 08073BAE
	cmp r0, #0                           @ 08073BB0
	beq .L08073BCE                       @ 08073BB2
	lsls r0, r1, #2                      @ 08073BB4
	ldrh r1, [r3, #0x26]                 @ 08073BB6
	adds r0, r0, r1                      @ 08073BB8
	strh r0, [r3, #0x26]                 @ 08073BBA
	lsls r0, r0, #0x10                   @ 08073BBC
	asrs r0, r0, #0x10                   @ 08073BBE
	movs r1, #0xf0                       @ 08073BC0
	lsls r1, r1, #5                      @ 08073BC2
	cmp r0, r1                           @ 08073BC4
	ble .L08073BCA                       @ 08073BC6
	strh r1, [r3, #0x26]                 @ 08073BC8
.L08073BCA:
	ldrh r0, [r3, #0x26]                 @ 08073BCA
	strh r0, [r3, #0x28]                 @ 08073BCC
.L08073BCE:
	adds r5, r3, #0                      @ 08073BCE
	adds r5, #0x2d                       @ 08073BD0
	movs r7, #0                          @ 08073BD2
	ldrsb r7, [r5, r7]                   @ 08073BD4
	ldr r0, .Lp08073C14                  @ 08073BD6
	ldr r0, [r0]                         @ 08073BD8
	ldrb r1, [r0, #1]                    @ 08073BDA
	movs r0, #0x10                       @ 08073BDC
	ands r0, r1                          @ 08073BDE
	cmp r0, #0                           @ 08073BE0
	bne .L08073BE8                       @ 08073BE2
	movs r0, #0x20                       @ 08073BE4
	strb r0, [r5]                        @ 08073BE6
.L08073BE8:
	ldr r0, .Lp08073C18                  @ 08073BE8
	str r3, [r0]                         @ 08073BEA
	ldr r4, .Lp08073C1C                  @ 08073BEC
	movs r6, #0                          @ 08073BEE
	ldr r0, .Lp08073C20                  @ 08073BF0
	ldr r0, [r0]                         @ 08073BF2
	cmp r0, #0                           @ 08073BF4
	bne .L08073BFA                       @ 08073BF6
	movs r6, #1                          @ 08073BF8
.L08073BFA:
	ldr r4, [r4]                         @ 08073BFA
	adds r0, r3, #0                      @ 08073BFC
	mov r1, ip                           @ 08073BFE
	adds r3, r6, #0                      @ 08073C00
	bl _call_via_r4                      @ 08073C02
	strb r7, [r5]                        @ 08073C06
	pop {r4, r5, r6, r7}                 @ 08073C08
	pop {r0}                             @ 08073C0A
	bx r0                                @ 08073C0C
	.align 2, 0
.Lp08073C10:	.word gMusTick
.Lp08073C14:	.word gSnd
.Lp08073C18:	.word gMusCurChannel
.Lp08073C1C:	.word gSndMixChannelFn
.Lp08073C20:	.word gMusTickPos

@ ============================================================================
@ void fxTonePorta(MusChannel *c, s16 *mix, int n)         effect 3xx (memory slot 2)
@   s = (c->param ? c->param : c->fxMem[2]) * 4;
@   if (gMusTick && c->portaTgt) {
@       move c->period towards c->portaTgt by s; on arrival period = target, portaTgt = 0;
@       c->period = c->basePer = period;
@   }
@   mix
@ ============================================================================
	thumb_func_start fxTonePorta
fxTonePorta: @ 0x08073C24
	push {r4, r5, r6, r7, lr}            @ 08073C24
	adds r5, r0, #0                      @ 08073C26
	mov ip, r1                           @ 08073C28
	ldrb r4, [r5, #0x1a]                 @ 08073C2A
	movs r0, #0x26                       @ 08073C2C
	ldrsh r1, [r5, r0]                   @ 08073C2E
	movs r0, #0x2a                       @ 08073C30
	ldrsh r3, [r5, r0]                   @ 08073C32
	cmp r4, #0                           @ 08073C34
	bne .L08073C3E                       @ 08073C36
	adds r0, r5, #0                      @ 08073C38
	adds r0, #0x36                       @ 08073C3A
	ldrb r4, [r0]                        @ 08073C3C
.L08073C3E:
	lsls r4, r4, #2                      @ 08073C3E
	ldr r0, .Lp08073C58                  @ 08073C40
	ldr r0, [r0]                         @ 08073C42
	cmp r0, #0                           @ 08073C44
	beq .L08073C6C                       @ 08073C46
	cmp r3, #0                           @ 08073C48
	beq .L08073C66                       @ 08073C4A
	cmp r1, r3                           @ 08073C4C
	ble .L08073C5C                       @ 08073C4E
	subs r1, r1, r4                      @ 08073C50
	cmp r1, r3                           @ 08073C52
	bgt .L08073C66                       @ 08073C54
	b .L08073C62                         @ 08073C56
.Lp08073C58:	.word gMusTick
.L08073C5C:
	adds r1, r1, r4                      @ 08073C5C
	cmp r1, r3                           @ 08073C5E
	blt .L08073C66                       @ 08073C60
.L08073C62:
	adds r1, r3, #0                      @ 08073C62
	movs r3, #0                          @ 08073C64
.L08073C66:
	strh r1, [r5, #0x26]                 @ 08073C66
	strh r1, [r5, #0x28]                 @ 08073C68
	strh r3, [r5, #0x2a]                 @ 08073C6A
.L08073C6C:
	adds r6, r5, #0                      @ 08073C6C
	adds r6, #0x2d                       @ 08073C6E
	movs r7, #0                          @ 08073C70
	ldrsb r7, [r6, r7]                   @ 08073C72
	ldr r0, .Lp08073CAC                  @ 08073C74
	ldr r0, [r0]                         @ 08073C76
	ldrb r1, [r0, #1]                    @ 08073C78
	movs r0, #0x10                       @ 08073C7A
	ands r0, r1                          @ 08073C7C
	cmp r0, #0                           @ 08073C7E
	bne .L08073C86                       @ 08073C80
	movs r0, #0x20                       @ 08073C82
	strb r0, [r6]                        @ 08073C84
.L08073C86:
	ldr r0, .Lp08073CB0                  @ 08073C86
	str r5, [r0]                         @ 08073C88
	ldr r4, .Lp08073CB4                  @ 08073C8A
	movs r3, #0                          @ 08073C8C
	ldr r0, .Lp08073CB8                  @ 08073C8E
	ldr r0, [r0]                         @ 08073C90
	cmp r0, #0                           @ 08073C92
	bne .L08073C98                       @ 08073C94
	movs r3, #1                          @ 08073C96
.L08073C98:
	ldr r4, [r4]                         @ 08073C98
	adds r0, r5, #0                      @ 08073C9A
	mov r1, ip                           @ 08073C9C
	bl _call_via_r4                      @ 08073C9E
	strb r7, [r6]                        @ 08073CA2
	pop {r4, r5, r6, r7}                 @ 08073CA4
	pop {r0}                             @ 08073CA6
	bx r0                                @ 08073CA8
	.align 2, 0
.Lp08073CAC:	.word gSnd
.Lp08073CB0:	.word gMusCurChannel
.Lp08073CB4:	.word gSndMixChannelFn
.Lp08073CB8:	.word gMusTickPos

@ ============================================================================
@ void fxVibrato(MusChannel *c, s16 *mix, int n)           effect 4xy (memory slot 3)
@   p = c->param ? c->param : c->fxMem[3];
@   c->period = clamp(c->basePer + (sndVibratoTables[c->vibWave][c->vibPos] * (p & 15) * 2 >> 16), 40, 7680);
@   c->vibPos = (c->vibPos + (p >> 4)) & 63;        // advances on tick 0 as well
@   mix
@ ============================================================================
	thumb_func_start fxVibrato
fxVibrato: @ 0x08073CBC
	push {r4, r5, r6, r7, lr}            @ 08073CBC
	mov r7, r8                           @ 08073CBE
	push {r7}                            @ 08073CC0
	mov ip, r0                           @ 08073CC2
	adds r7, r1, #0                      @ 08073CC4
	mov r8, r2                           @ 08073CC6
	ldrb r3, [r0, #0x1a]                 @ 08073CC8
	movs r1, #0x28                       @ 08073CCA
	ldrsh r2, [r0, r1]                   @ 08073CCC
	adds r0, #0x44                       @ 08073CCE
	ldrb r0, [r0]                        @ 08073CD0
	lsls r0, r0, #8                      @ 08073CD2
	ldr r1, .Lp08073D14                  @ 08073CD4
	adds r5, r0, r1                      @ 08073CD6
	mov r0, ip                           @ 08073CD8
	adds r0, #0x48                       @ 08073CDA
	movs r1, #0                          @ 08073CDC
	ldrsh r4, [r0, r1]                   @ 08073CDE
	cmp r3, #0                           @ 08073CE0
	bne .L08073CE8                       @ 08073CE2
	subs r0, #0x11                       @ 08073CE4
	ldrb r3, [r0]                        @ 08073CE6
.L08073CE8:
	movs r0, #0xf                        @ 08073CE8
	adds r1, r3, #0                      @ 08073CEA
	ands r1, r0                          @ 08073CEC
	lsls r1, r1, #1                      @ 08073CEE
	asrs r3, r3, #4                      @ 08073CF0
	ands r3, r0                          @ 08073CF2
	lsls r0, r4, #2                      @ 08073CF4
	adds r0, r0, r5                      @ 08073CF6
	ldr r0, [r0]                         @ 08073CF8
	muls r0, r1, r0                      @ 08073CFA
	asrs r0, r0, #0x10                   @ 08073CFC
	adds r0, r2, r0                      @ 08073CFE
	mov r1, ip                           @ 08073D00
	strh r0, [r1, #0x26]                 @ 08073D02
	lsls r0, r0, #0x10                   @ 08073D04
	asrs r0, r0, #0x10                   @ 08073D06
	cmp r0, #0x27                        @ 08073D08
	bgt .L08073D18                       @ 08073D0A
	movs r0, #0x28                       @ 08073D0C
	strh r0, [r1, #0x26]                 @ 08073D0E
	b .L08073D24                         @ 08073D10
	.align 2, 0
.Lp08073D14:	.word sndVibratoTables
.L08073D18:
	movs r1, #0xf0                       @ 08073D18
	lsls r1, r1, #5                      @ 08073D1A
	cmp r0, r1                           @ 08073D1C
	ble .L08073D24                       @ 08073D1E
	mov r0, ip                           @ 08073D20
	strh r1, [r0, #0x26]                 @ 08073D22
.L08073D24:
	adds r4, r4, r3                      @ 08073D24
	movs r0, #0x3f                       @ 08073D26
	ands r4, r0                          @ 08073D28
	mov r0, ip                           @ 08073D2A
	adds r0, #0x48                       @ 08073D2C
	strh r4, [r0]                        @ 08073D2E
	mov r5, ip                           @ 08073D30
	adds r5, #0x2d                       @ 08073D32
	movs r6, #0                          @ 08073D34
	ldrsb r6, [r5, r6]                   @ 08073D36
	ldr r0, .Lp08073D78                  @ 08073D38
	ldr r0, [r0]                         @ 08073D3A
	ldrb r1, [r0, #1]                    @ 08073D3C
	movs r0, #0x10                       @ 08073D3E
	ands r0, r1                          @ 08073D40
	cmp r0, #0                           @ 08073D42
	bne .L08073D4A                       @ 08073D44
	movs r0, #0x20                       @ 08073D46
	strb r0, [r5]                        @ 08073D48
.L08073D4A:
	ldr r0, .Lp08073D7C                  @ 08073D4A
	mov r1, ip                           @ 08073D4C
	str r1, [r0]                         @ 08073D4E
	ldr r4, .Lp08073D80                  @ 08073D50
	movs r3, #0                          @ 08073D52
	ldr r0, .Lp08073D84                  @ 08073D54
	ldr r0, [r0]                         @ 08073D56
	cmp r0, #0                           @ 08073D58
	bne .L08073D5E                       @ 08073D5A
	movs r3, #1                          @ 08073D5C
.L08073D5E:
	ldr r4, [r4]                         @ 08073D5E
	mov r0, ip                           @ 08073D60
	adds r1, r7, #0                      @ 08073D62
	mov r2, r8                           @ 08073D64
	bl _call_via_r4                      @ 08073D66
	strb r6, [r5]                        @ 08073D6A
	pop {r3}                             @ 08073D6C
	mov r8, r3                           @ 08073D6E
	pop {r4, r5, r6, r7}                 @ 08073D70
	pop {r0}                             @ 08073D72
	bx r0                                @ 08073D74
	.align 2, 0
.Lp08073D78:	.word gSnd
.Lp08073D7C:	.word gMusCurChannel
.Lp08073D80:	.word gSndMixChannelFn
.Lp08073D84:	.word gMusTickPos

@ ============================================================================
@ void fxTonePortaVolSlide(MusChannel *c, s16 *mix, int n) effect 5xy
@   slide = (x ? x : -y);  speed = c->fxMem[2] * 4;
@   if (gMusTick) { tone portamento as fxTonePorta; c->vol = clamp(c->vol + slide, 0, 64); c->baseVol = c->vol; }
@   mix
@ ============================================================================
	thumb_func_start fxTonePortaVolSlide
fxTonePortaVolSlide: @ 0x08073D88
	push {r4, r5, r6, r7, lr}            @ 08073D88
	mov r7, r8                           @ 08073D8A
	push {r7}                            @ 08073D8C
	mov ip, r0                           @ 08073D8E
	adds r7, r1, #0                      @ 08073D90
	mov r8, r2                           @ 08073D92
	adds r0, #0x36                       @ 08073D94
	ldrb r4, [r0]                        @ 08073D96
	mov r0, ip                           @ 08073D98
	ldrb r2, [r0, #0x1a]                 @ 08073D9A
	movs r1, #0x2a                       @ 08073D9C
	ldrsh r3, [r0, r1]                   @ 08073D9E
	movs r5, #0x26                       @ 08073DA0
	ldrsh r1, [r0, r5]                   @ 08073DA2
	movs r0, #0xf0                       @ 08073DA4
	ands r0, r2                          @ 08073DA6
	cmp r0, #0                           @ 08073DA8
	beq .L08073DB0                       @ 08073DAA
	lsrs r0, r2, #4                      @ 08073DAC
	b .L08073DB6                         @ 08073DAE
.L08073DB0:
	movs r0, #0xf                        @ 08073DB0
	ands r0, r2                          @ 08073DB2
	rsbs r0, r0, #0                      @ 08073DB4
.L08073DB6:
	adds r2, r0, #0                      @ 08073DB6
	lsls r4, r4, #2                      @ 08073DB8
	ldr r0, .Lp08073DD4                  @ 08073DBA
	ldr r0, [r0]                         @ 08073DBC
	cmp r0, #0                           @ 08073DBE
	beq .L08073E10                       @ 08073DC0
	cmp r3, #0                           @ 08073DC2
	beq .L08073DE2                       @ 08073DC4
	cmp r1, r3                           @ 08073DC6
	bge .L08073DD8                       @ 08073DC8
	adds r1, r1, r4                      @ 08073DCA
	cmp r1, r3                           @ 08073DCC
	blt .L08073DE2                       @ 08073DCE
	b .L08073DDE                         @ 08073DD0
	.align 2, 0
.Lp08073DD4:	.word gMusTick
.L08073DD8:
	subs r1, r1, r4                      @ 08073DD8
	cmp r1, r3                           @ 08073DDA
	bgt .L08073DE2                       @ 08073DDC
.L08073DDE:
	adds r1, r3, #0                      @ 08073DDE
	movs r3, #0                          @ 08073DE0
.L08073DE2:
	mov r0, ip                           @ 08073DE2
	strh r3, [r0, #0x2a]                 @ 08073DE4
	strh r1, [r0, #0x26]                 @ 08073DE6
	strh r1, [r0, #0x28]                 @ 08073DE8
	mov r1, ip                           @ 08073DEA
	adds r1, #0x2c                       @ 08073DEC
	ldrb r0, [r1]                        @ 08073DEE
	adds r0, r0, r2                      @ 08073DF0
	strb r0, [r1]                        @ 08073DF2
	lsls r0, r0, #0x18                   @ 08073DF4
	asrs r0, r0, #0x18                   @ 08073DF6
	cmp r0, #0                           @ 08073DF8
	bge .L08073E00                       @ 08073DFA
	movs r0, #0                          @ 08073DFC
	b .L08073E06                         @ 08073DFE
.L08073E00:
	cmp r0, #0x40                        @ 08073E00
	ble .L08073E08                       @ 08073E02
	movs r0, #0x40                       @ 08073E04
.L08073E06:
	strb r0, [r1]                        @ 08073E06
.L08073E08:
	ldrb r1, [r1]                        @ 08073E08
	mov r0, ip                           @ 08073E0A
	adds r0, #0x24                       @ 08073E0C
	strb r1, [r0]                        @ 08073E0E
.L08073E10:
	mov r5, ip                           @ 08073E10
	adds r5, #0x2d                       @ 08073E12
	movs r6, #0                          @ 08073E14
	ldrsb r6, [r5, r6]                   @ 08073E16
	ldr r0, .Lp08073E58                  @ 08073E18
	ldr r0, [r0]                         @ 08073E1A
	ldrb r1, [r0, #1]                    @ 08073E1C
	movs r0, #0x10                       @ 08073E1E
	ands r0, r1                          @ 08073E20
	cmp r0, #0                           @ 08073E22
	bne .L08073E2A                       @ 08073E24
	movs r0, #0x20                       @ 08073E26
	strb r0, [r5]                        @ 08073E28
.L08073E2A:
	ldr r0, .Lp08073E5C                  @ 08073E2A
	mov r1, ip                           @ 08073E2C
	str r1, [r0]                         @ 08073E2E
	ldr r4, .Lp08073E60                  @ 08073E30
	movs r3, #0                          @ 08073E32
	ldr r0, .Lp08073E64                  @ 08073E34
	ldr r0, [r0]                         @ 08073E36
	cmp r0, #0                           @ 08073E38
	bne .L08073E3E                       @ 08073E3A
	movs r3, #1                          @ 08073E3C
.L08073E3E:
	ldr r4, [r4]                         @ 08073E3E
	mov r0, ip                           @ 08073E40
	adds r1, r7, #0                      @ 08073E42
	mov r2, r8                           @ 08073E44
	bl _call_via_r4                      @ 08073E46
	strb r6, [r5]                        @ 08073E4A
	pop {r3}                             @ 08073E4C
	mov r8, r3                           @ 08073E4E
	pop {r4, r5, r6, r7}                 @ 08073E50
	pop {r0}                             @ 08073E52
	bx r0                                @ 08073E54
	.align 2, 0
.Lp08073E58:	.word gSnd
.Lp08073E5C:	.word gMusCurChannel
.Lp08073E60:	.word gSndMixChannelFn
.Lp08073E64:	.word gMusTickPos

@ ============================================================================
@ void fxVibratoVolSlide(MusChannel *c, s16 *mix, int n)   effect 6xy
@   vibrato with c->fxMem[3] as in fxVibrato (every tick);
@   if (gMusTick) { c->vol = clamp(c->vol + (x ? x : -y), 0, 64); c->baseVol = c->vol; }
@   mix
@ ============================================================================
	thumb_func_start fxVibratoVolSlide
fxVibratoVolSlide: @ 0x08073E68
	push {r4, r5, r6, r7, lr}            @ 08073E68
	mov r7, r8                           @ 08073E6A
	push {r7}                            @ 08073E6C
	mov ip, r0                           @ 08073E6E
	adds r7, r1, #0                      @ 08073E70
	mov r8, r2                           @ 08073E72
	adds r0, #0x37                       @ 08073E74
	ldrb r4, [r0]                        @ 08073E76
	mov r0, ip                           @ 08073E78
	movs r1, #0x28                       @ 08073E7A
	ldrsh r6, [r0, r1]                   @ 08073E7C
	ldrb r5, [r0, #0x1a]                 @ 08073E7E
	adds r0, #0x44                       @ 08073E80
	ldrb r0, [r0]                        @ 08073E82
	lsls r0, r0, #8                      @ 08073E84
	ldr r1, .Lp08073EA0                  @ 08073E86
	adds r2, r0, r1                      @ 08073E88
	mov r0, ip                           @ 08073E8A
	adds r0, #0x48                       @ 08073E8C
	movs r1, #0                          @ 08073E8E
	ldrsh r3, [r0, r1]                   @ 08073E90
	movs r0, #0xf0                       @ 08073E92
	ands r0, r5                          @ 08073E94
	cmp r0, #0                           @ 08073E96
	beq .L08073EA4                       @ 08073E98
	lsrs r0, r5, #4                      @ 08073E9A
	b .L08073EAA                         @ 08073E9C
	.align 2, 0
.Lp08073EA0:	.word sndVibratoTables
.L08073EA4:
	movs r0, #0xf                        @ 08073EA4
	ands r0, r5                          @ 08073EA6
	rsbs r0, r0, #0                      @ 08073EA8
.L08073EAA:
	adds r5, r0, #0                      @ 08073EAA
	movs r0, #0xf                        @ 08073EAC
	adds r1, r4, #0                      @ 08073EAE
	ands r1, r0                          @ 08073EB0
	lsls r1, r1, #1                      @ 08073EB2
	asrs r4, r4, #4                      @ 08073EB4
	ands r4, r0                          @ 08073EB6
	lsls r0, r3, #2                      @ 08073EB8
	adds r0, r0, r2                      @ 08073EBA
	ldr r0, [r0]                         @ 08073EBC
	muls r0, r1, r0                      @ 08073EBE
	asrs r0, r0, #0x10                   @ 08073EC0
	adds r0, r6, r0                      @ 08073EC2
	mov r1, ip                           @ 08073EC4
	strh r0, [r1, #0x26]                 @ 08073EC6
	lsls r0, r0, #0x10                   @ 08073EC8
	asrs r0, r0, #0x10                   @ 08073ECA
	cmp r0, #0x27                        @ 08073ECC
	bgt .L08073ED6                       @ 08073ECE
	movs r0, #0x28                       @ 08073ED0
	strh r0, [r1, #0x26]                 @ 08073ED2
	b .L08073EE2                         @ 08073ED4
.L08073ED6:
	movs r1, #0xf0                       @ 08073ED6
	lsls r1, r1, #5                      @ 08073ED8
	cmp r0, r1                           @ 08073EDA
	ble .L08073EE2                       @ 08073EDC
	mov r0, ip                           @ 08073EDE
	strh r1, [r0, #0x26]                 @ 08073EE0
.L08073EE2:
	adds r3, r3, r4                      @ 08073EE2
	movs r0, #0x3f                       @ 08073EE4
	ands r3, r0                          @ 08073EE6
	mov r0, ip                           @ 08073EE8
	adds r0, #0x48                       @ 08073EEA
	strh r3, [r0]                        @ 08073EEC
	ldr r0, .Lp08073F0C                  @ 08073EEE
	ldr r0, [r0]                         @ 08073EF0
	cmp r0, #0                           @ 08073EF2
	beq .L08073F20                       @ 08073EF4
	mov r1, ip                           @ 08073EF6
	adds r1, #0x2c                       @ 08073EF8
	ldrb r0, [r1]                        @ 08073EFA
	adds r0, r0, r5                      @ 08073EFC
	strb r0, [r1]                        @ 08073EFE
	lsls r0, r0, #0x18                   @ 08073F00
	asrs r0, r0, #0x18                   @ 08073F02
	cmp r0, #0                           @ 08073F04
	bge .L08073F10                       @ 08073F06
	movs r0, #0                          @ 08073F08
	b .L08073F16                         @ 08073F0A
.Lp08073F0C:	.word gMusTick
.L08073F10:
	cmp r0, #0x40                        @ 08073F10
	ble .L08073F18                       @ 08073F12
	movs r0, #0x40                       @ 08073F14
.L08073F16:
	strb r0, [r1]                        @ 08073F16
.L08073F18:
	ldrb r1, [r1]                        @ 08073F18
	mov r0, ip                           @ 08073F1A
	adds r0, #0x24                       @ 08073F1C
	strb r1, [r0]                        @ 08073F1E
.L08073F20:
	mov r5, ip                           @ 08073F20
	adds r5, #0x2d                       @ 08073F22
	movs r6, #0                          @ 08073F24
	ldrsb r6, [r5, r6]                   @ 08073F26
	ldr r0, .Lp08073F68                  @ 08073F28
	ldr r0, [r0]                         @ 08073F2A
	ldrb r1, [r0, #1]                    @ 08073F2C
	movs r0, #0x10                       @ 08073F2E
	ands r0, r1                          @ 08073F30
	cmp r0, #0                           @ 08073F32
	bne .L08073F3A                       @ 08073F34
	movs r0, #0x20                       @ 08073F36
	strb r0, [r5]                        @ 08073F38
.L08073F3A:
	ldr r0, .Lp08073F6C                  @ 08073F3A
	mov r1, ip                           @ 08073F3C
	str r1, [r0]                         @ 08073F3E
	ldr r4, .Lp08073F70                  @ 08073F40
	movs r3, #0                          @ 08073F42
	ldr r0, .Lp08073F74                  @ 08073F44
	ldr r0, [r0]                         @ 08073F46
	cmp r0, #0                           @ 08073F48
	bne .L08073F4E                       @ 08073F4A
	movs r3, #1                          @ 08073F4C
.L08073F4E:
	ldr r4, [r4]                         @ 08073F4E
	mov r0, ip                           @ 08073F50
	adds r1, r7, #0                      @ 08073F52
	mov r2, r8                           @ 08073F54
	bl _call_via_r4                      @ 08073F56
	strb r6, [r5]                        @ 08073F5A
	pop {r3}                             @ 08073F5C
	mov r8, r3                           @ 08073F5E
	pop {r4, r5, r6, r7}                 @ 08073F60
	pop {r0}                             @ 08073F62
	bx r0                                @ 08073F64
	.align 2, 0
.Lp08073F68:	.word gSnd
.Lp08073F6C:	.word gMusCurChannel
.Lp08073F70:	.word gSndMixChannelFn
.Lp08073F74:	.word gMusTickPos

@ ============================================================================
@ void fxTremolo(MusChannel *c, s16 *mix, int n)           effect 7xy (memory slot 5)
@   p = c->param ? c->param : c->fxMem[5];
@   c->vol = clamp(c->baseVol + (sndVibratoTables[c->tremWave][c->tremPos] * (p & 15) * 4 >> 16), 0, 64);
@   c->tremPos = (c->tremPos + (p >> 4)) & 63;
@   mix
@ ============================================================================
	thumb_func_start fxTremolo
fxTremolo: @ 0x08073F78
	push {r4, r5, r6, r7, lr}            @ 08073F78
	mov r7, r8                           @ 08073F7A
	push {r7}                            @ 08073F7C
	mov ip, r0                           @ 08073F7E
	adds r7, r1, #0                      @ 08073F80
	mov r8, r2                           @ 08073F82
	ldrb r3, [r0, #0x1a]                 @ 08073F84
	adds r0, #0x24                       @ 08073F86
	movs r2, #0                          @ 08073F88
	ldrsb r2, [r0, r2]                   @ 08073F8A
	adds r0, #0x21                       @ 08073F8C
	ldrb r0, [r0]                        @ 08073F8E
	lsls r0, r0, #8                      @ 08073F90
	ldr r1, .Lp08073FD0                  @ 08073F92
	adds r5, r0, r1                      @ 08073F94
	mov r0, ip                           @ 08073F96
	adds r0, #0x4a                       @ 08073F98
	movs r1, #0                          @ 08073F9A
	ldrsh r4, [r0, r1]                   @ 08073F9C
	cmp r3, #0                           @ 08073F9E
	bne .L08073FA6                       @ 08073FA0
	subs r0, #0x11                       @ 08073FA2
	ldrb r3, [r0]                        @ 08073FA4
.L08073FA6:
	movs r0, #0xf                        @ 08073FA6
	adds r1, r3, #0                      @ 08073FA8
	ands r1, r0                          @ 08073FAA
	lsls r1, r1, #2                      @ 08073FAC
	asrs r3, r3, #4                      @ 08073FAE
	ands r3, r0                          @ 08073FB0
	lsls r0, r4, #2                      @ 08073FB2
	adds r0, r0, r5                      @ 08073FB4
	ldr r0, [r0]                         @ 08073FB6
	muls r0, r1, r0                      @ 08073FB8
	asrs r0, r0, #0x10                   @ 08073FBA
	adds r0, r2, r0                      @ 08073FBC
	mov r1, ip                           @ 08073FBE
	adds r1, #0x2c                       @ 08073FC0
	strb r0, [r1]                        @ 08073FC2
	lsls r0, r0, #0x18                   @ 08073FC4
	asrs r0, r0, #0x18                   @ 08073FC6
	cmp r0, #0                           @ 08073FC8
	bge .L08073FD4                       @ 08073FCA
	movs r0, #0                          @ 08073FCC
	b .L08073FDA                         @ 08073FCE
.Lp08073FD0:	.word sndVibratoTables
.L08073FD4:
	cmp r0, #0x40                        @ 08073FD4
	ble .L08073FDC                       @ 08073FD6
	movs r0, #0x40                       @ 08073FD8
.L08073FDA:
	strb r0, [r1]                        @ 08073FDA
.L08073FDC:
	adds r4, r4, r3                      @ 08073FDC
	movs r0, #0x3f                       @ 08073FDE
	ands r4, r0                          @ 08073FE0
	mov r0, ip                           @ 08073FE2
	adds r0, #0x4a                       @ 08073FE4
	strh r4, [r0]                        @ 08073FE6
	mov r5, ip                           @ 08073FE8
	adds r5, #0x2d                       @ 08073FEA
	movs r6, #0                          @ 08073FEC
	ldrsb r6, [r5, r6]                   @ 08073FEE
	ldr r0, .Lp08074030                  @ 08073FF0
	ldr r0, [r0]                         @ 08073FF2
	ldrb r1, [r0, #1]                    @ 08073FF4
	movs r0, #0x10                       @ 08073FF6
	ands r0, r1                          @ 08073FF8
	cmp r0, #0                           @ 08073FFA
	bne .L08074002                       @ 08073FFC
	movs r0, #0x20                       @ 08073FFE
	strb r0, [r5]                        @ 08074000
.L08074002:
	ldr r0, .Lp08074034                  @ 08074002
	mov r1, ip                           @ 08074004
	str r1, [r0]                         @ 08074006
	ldr r4, .Lp08074038                  @ 08074008
	movs r3, #0                          @ 0807400A
	ldr r0, .Lp0807403C                  @ 0807400C
	ldr r0, [r0]                         @ 0807400E
	cmp r0, #0                           @ 08074010
	bne .L08074016                       @ 08074012
	movs r3, #1                          @ 08074014
.L08074016:
	ldr r4, [r4]                         @ 08074016
	mov r0, ip                           @ 08074018
	adds r1, r7, #0                      @ 0807401A
	mov r2, r8                           @ 0807401C
	bl _call_via_r4                      @ 0807401E
	strb r6, [r5]                        @ 08074022
	pop {r3}                             @ 08074024
	mov r8, r3                           @ 08074026
	pop {r4, r5, r6, r7}                 @ 08074028
	pop {r0}                             @ 0807402A
	bx r0                                @ 0807402C
	.align 2, 0
.Lp08074030:	.word gSnd
.Lp08074034:	.word gMusCurChannel
.Lp08074038:	.word gSndMixChannelFn
.Lp0807403C:	.word gMusTickPos

@ ============================================================================
@ void fxVolumeSlide(MusChannel *c, s16 *mix, int n)       effect Axy (no memory: A00 does nothing)
@   if (gMusTick) { c->vol = clamp(c->vol + (x ? x : -y), 0, 64); c->baseVol = c->vol; }
@   mix
@ ============================================================================
	thumb_func_start fxVolumeSlide
fxVolumeSlide: @ 0x08074040
	push {r4, r5, r6, r7, lr}            @ 08074040
	adds r6, r0, #0                      @ 08074042
	mov ip, r1                           @ 08074044
	ldrb r1, [r6, #0x1a]                 @ 08074046
	movs r0, #0xf0                       @ 08074048
	ands r0, r1                          @ 0807404A
	cmp r0, #0                           @ 0807404C
	beq .L08074054                       @ 0807404E
	lsrs r3, r1, #4                      @ 08074050
	b .L0807405A                         @ 08074052
.L08074054:
	movs r0, #0xf                        @ 08074054
	ands r1, r0                          @ 08074056
	rsbs r3, r1, #0                      @ 08074058
.L0807405A:
	ldr r0, .Lp08074078                  @ 0807405A
	ldr r0, [r0]                         @ 0807405C
	cmp r0, #0                           @ 0807405E
	beq .L0807408C                       @ 08074060
	adds r1, r6, #0                      @ 08074062
	adds r1, #0x2c                       @ 08074064
	ldrb r0, [r1]                        @ 08074066
	adds r0, r0, r3                      @ 08074068
	strb r0, [r1]                        @ 0807406A
	lsls r0, r0, #0x18                   @ 0807406C
	asrs r0, r0, #0x18                   @ 0807406E
	cmp r0, #0                           @ 08074070
	bge .L0807407C                       @ 08074072
	movs r0, #0                          @ 08074074
	b .L08074082                         @ 08074076
.Lp08074078:	.word gMusTick
.L0807407C:
	cmp r0, #0x40                        @ 0807407C
	ble .L08074084                       @ 0807407E
	movs r0, #0x40                       @ 08074080
.L08074082:
	strb r0, [r1]                        @ 08074082
.L08074084:
	ldrb r1, [r1]                        @ 08074084
	adds r0, r6, #0                      @ 08074086
	adds r0, #0x24                       @ 08074088
	strb r1, [r0]                        @ 0807408A
.L0807408C:
	adds r5, r6, #0                      @ 0807408C
	adds r5, #0x2d                       @ 0807408E
	movs r7, #0                          @ 08074090
	ldrsb r7, [r5, r7]                   @ 08074092
	ldr r0, .Lp080740CC                  @ 08074094
	ldr r0, [r0]                         @ 08074096
	ldrb r1, [r0, #1]                    @ 08074098
	movs r0, #0x10                       @ 0807409A
	ands r0, r1                          @ 0807409C
	cmp r0, #0                           @ 0807409E
	bne .L080740A6                       @ 080740A0
	movs r0, #0x20                       @ 080740A2
	strb r0, [r5]                        @ 080740A4
.L080740A6:
	ldr r0, .Lp080740D0                  @ 080740A6
	str r6, [r0]                         @ 080740A8
	ldr r4, .Lp080740D4                  @ 080740AA
	movs r3, #0                          @ 080740AC
	ldr r0, .Lp080740D8                  @ 080740AE
	ldr r0, [r0]                         @ 080740B0
	cmp r0, #0                           @ 080740B2
	bne .L080740B8                       @ 080740B4
	movs r3, #1                          @ 080740B6
.L080740B8:
	ldr r4, [r4]                         @ 080740B8
	adds r0, r6, #0                      @ 080740BA
	mov r1, ip                           @ 080740BC
	bl _call_via_r4                      @ 080740BE
	strb r7, [r5]                        @ 080740C2
	pop {r4, r5, r6, r7}                 @ 080740C4
	pop {r0}                             @ 080740C6
	bx r0                                @ 080740C8
	.align 2, 0
.Lp080740CC:	.word gSnd
.Lp080740D0:	.word gMusCurChannel
.Lp080740D4:	.word gSndMixChannelFn
.Lp080740D8:	.word gMusTickPos

@ ============================================================================
@ void musMixSlice(MusPlayer *P, s16 *mix, int n)          [musMix; n never crosses a tick boundary]
@   for (ch = 0; ch < P->nChannels; ch++) {
@       c = &P->chan[ch];
@       if (!c->insPtr || !c->period) continue;
@       inRow = P->rowMask >> ch & 1;
@       if (gMusTickPos) {                                 // rest of a tick: just mix
@           if (inRow && c->cmd == 0x26 && gMusTick < c->param) continue;      // note delay
@           mix(c);
@       } else if (!inRow) {                               // tick start, no cell in this row
@           c->period = c->basePer; c->vol = c->baseVol;
@           envelopes (as musTickVolume, but no fadeout and no volume-column slides);
@           c->basePer = c->period; c->baseVol = c->vol;
@           mix(c);
@       } else {                                           // tick start, channel has a cell
@           c->period = c->basePer; c->vol = c->baseVol;
@           musTickVolume(c);
@           c->basePer = c->period; c->baseVol = c->vol;
@           musTickFxTable[c->cmd](c, mix, n);             // the handler mixes
@       }
@   }
@ ============================================================================
	thumb_func_start musMixSlice
musMixSlice: @ 0x080740DC
	push {r4, r5, r6, r7, lr}            @ 080740DC
	mov r7, sl                           @ 080740DE
	mov r6, sb                           @ 080740E0
	mov r5, r8                           @ 080740E2
	push {r5, r6, r7}                    @ 080740E4
	sub sp, #0xc                         @ 080740E6
	str r0, [sp]                         @ 080740E8
	str r1, [sp, #4]                     @ 080740EA
	mov sl, r2                           @ 080740EC
	ldr r1, .Lp08074190                  @ 080740EE
	adds r0, r0, r1                      @ 080740F0
	ldrb r0, [r0]                        @ 080740F2
	mov sb, r0                           @ 080740F4
	ldr r2, [sp]                         @ 080740F6
	adds r1, #2                          @ 080740F8
	adds r0, r2, r1                      @ 080740FA
	ldrb r0, [r0]                        @ 080740FC
	str r0, [sp, #8]                     @ 080740FE
	ldr r0, .Lp08074194                  @ 08074100
	ldr r0, [r0]                         @ 08074102
	cmp r0, #0                           @ 08074104
	beq .L080741A8                       @ 08074106
	movs r2, #0                          @ 08074108
	mov r8, r2                           @ 0807410A
	cmp r8, sb                           @ 0807410C
	blo .L08074112                       @ 0807410E
	b .L080742C4                         @ 08074110
.L08074112:
	movs r0, #0x4c                       @ 08074112
	mov r1, r8                           @ 08074114
	muls r1, r0, r1                      @ 08074116
	adds r0, r1, #0                      @ 08074118
	adds r0, #4                          @ 0807411A
	ldr r2, [sp]                         @ 0807411C
	adds r6, r2, r0                      @ 0807411E
	ldr r0, [r6, #0x3c]                  @ 08074120
	cmp r0, #0                           @ 08074122
	beq .L08074186                       @ 08074124
	movs r1, #0x26                       @ 08074126
	ldrsh r0, [r6, r1]                   @ 08074128
	cmp r0, #0                           @ 0807412A
	beq .L08074186                       @ 0807412C
	ldr r0, [sp, #8]                     @ 0807412E
	mov r2, r8                           @ 08074130
	asrs r0, r2                          @ 08074132
	movs r1, #1                          @ 08074134
	ands r0, r1                          @ 08074136
	cmp r0, #0                           @ 08074138
	beq .L0807414C                       @ 0807413A
	ldrb r7, [r6, #0x18]                 @ 0807413C
	cmp r7, #0x26                        @ 0807413E
	bne .L0807414C                       @ 08074140
	ldr r0, .Lp08074198                  @ 08074142
	ldr r0, [r0]                         @ 08074144
	ldrb r1, [r6, #0x1a]                 @ 08074146
	cmp r0, r1                           @ 08074148
	blo .L08074186                       @ 0807414A
.L0807414C:
	adds r5, r6, #0                      @ 0807414C
	adds r5, #0x2d                       @ 0807414E
	movs r7, #0                          @ 08074150
	ldrsb r7, [r5, r7]                   @ 08074152
	ldr r0, .Lp0807419C                  @ 08074154
	ldr r0, [r0]                         @ 08074156
	ldrb r1, [r0, #1]                    @ 08074158
	movs r0, #0x10                       @ 0807415A
	ands r0, r1                          @ 0807415C
	cmp r0, #0                           @ 0807415E
	bne .L08074166                       @ 08074160
	movs r0, #0x20                       @ 08074162
	strb r0, [r5]                        @ 08074164
.L08074166:
	ldr r0, .Lp080741A0                  @ 08074166
	str r6, [r0]                         @ 08074168
	ldr r4, .Lp080741A4                  @ 0807416A
	movs r3, #0                          @ 0807416C
	ldr r0, .Lp08074194                  @ 0807416E
	ldr r0, [r0]                         @ 08074170
	cmp r0, #0                           @ 08074172
	bne .L08074178                       @ 08074174
	movs r3, #1                          @ 08074176
.L08074178:
	ldr r4, [r4]                         @ 08074178
	adds r0, r6, #0                      @ 0807417A
	ldr r1, [sp, #4]                     @ 0807417C
	mov r2, sl                           @ 0807417E
	bl _call_via_r4                      @ 08074180
	strb r7, [r5]                        @ 08074184
.L08074186:
	movs r2, #1                          @ 08074186
	add r8, r2                           @ 08074188
	cmp r8, sb                           @ 0807418A
	blo .L08074112                       @ 0807418C
	b .L080742C4                         @ 0807418E
.Lp08074190:	.word PL_nChannels
.Lp08074194:	.word gMusTickPos
.Lp08074198:	.word gMusTick
.Lp0807419C:	.word gSnd
.Lp080741A0:	.word gMusCurChannel
.Lp080741A4:	.word gSndMixChannelFn
.L080741A8:
	movs r0, #0                          @ 080741A8
	mov r8, r0                           @ 080741AA
	cmp r8, sb                           @ 080741AC
	blo .L080741B2                       @ 080741AE
	b .L080742C4                         @ 080741B0
.L080741B2:
	movs r0, #0x4c                       @ 080741B2
	mov r1, r8                           @ 080741B4
	muls r1, r0, r1                      @ 080741B6
	adds r0, r1, #0                      @ 080741B8
	adds r0, #4                          @ 080741BA
	ldr r2, [sp]                         @ 080741BC
	adds r6, r2, r0                      @ 080741BE
	ldr r0, [r6, #0x3c]                  @ 080741C0
	cmp r0, #0                           @ 080741C2
	beq .L080742BA                       @ 080741C4
	movs r1, #0x26                       @ 080741C6
	ldrsh r0, [r6, r1]                   @ 080741C8
	cmp r0, #0                           @ 080741CA
	beq .L080742BA                       @ 080741CC
	ldr r0, [sp, #8]                     @ 080741CE
	mov r2, r8                           @ 080741D0
	asrs r0, r2                          @ 080741D2
	movs r4, #1                          @ 080741D4
	ands r0, r4                          @ 080741D6
	cmp r0, #0                           @ 080741D8
	bne .L08074288                       @ 080741DA
	ldrh r0, [r6, #0x28]                 @ 080741DC
	strh r0, [r6, #0x26]                 @ 080741DE
	adds r7, r6, #0                      @ 080741E0
	adds r7, #0x24                       @ 080741E2
	ldrb r0, [r7]                        @ 080741E4
	adds r5, r6, #0                      @ 080741E6
	adds r5, #0x2c                       @ 080741E8
	strb r0, [r5]                        @ 080741EA
	ldr r2, [r6, #0x3c]                  @ 080741EC
	adds r0, r2, #0                      @ 080741EE
	adds r0, #0xc9                       @ 080741F0
	ldrb r1, [r0]                        @ 080741F2
	adds r0, r4, #0                      @ 080741F4
	ands r0, r1                          @ 080741F6
	cmp r0, #0                           @ 080741F8
	beq .L0807420C                       @ 080741FA
	adds r1, r2, #0                      @ 080741FC
	adds r1, #0x94                       @ 080741FE
	ldrh r0, [r6, #0x32]                 @ 08074200
	adds r2, r4, #0                      @ 08074202
	ands r2, r0                          @ 08074204
	adds r0, r6, #0                      @ 08074206
	bl musEnvelopeTick                   @ 08074208
.L0807420C:
	ldr r2, [r6, #0x3c]                  @ 0807420C
	ldr r1, .Lp08074274                  @ 0807420E
	adds r0, r2, r1                      @ 08074210
	ldrb r1, [r0]                        @ 08074212
	adds r0, r4, #0                      @ 08074214
	ands r0, r1                          @ 08074216
	cmp r0, #0                           @ 08074218
	beq .L0807422E                       @ 0807421A
	adds r0, r6, #0                      @ 0807421C
	adds r0, #8                          @ 0807421E
	adds r1, r2, #0                      @ 08074220
	adds r1, #0xe4                       @ 08074222
	ldrh r3, [r6, #0x32]                 @ 08074224
	adds r2, r4, #0                      @ 08074226
	ands r2, r3                          @ 08074228
	bl musEnvelopeTick                   @ 0807422A
.L0807422E:
	ldrh r0, [r6, #0x26]                 @ 0807422E
	strh r0, [r6, #0x28]                 @ 08074230
	ldrb r0, [r5]                        @ 08074232
	strb r0, [r7]                        @ 08074234
	adds r5, r6, #0                      @ 08074236
	adds r5, #0x2d                       @ 08074238
	movs r7, #0                          @ 0807423A
	ldrsb r7, [r5, r7]                   @ 0807423C
	ldr r0, .Lp08074278                  @ 0807423E
	ldr r0, [r0]                         @ 08074240
	ldrb r1, [r0, #1]                    @ 08074242
	movs r0, #0x10                       @ 08074244
	ands r0, r1                          @ 08074246
	cmp r0, #0                           @ 08074248
	bne .L08074250                       @ 0807424A
	movs r0, #0x20                       @ 0807424C
	strb r0, [r5]                        @ 0807424E
.L08074250:
	ldr r0, .Lp0807427C                  @ 08074250
	str r6, [r0]                         @ 08074252
	ldr r4, .Lp08074280                  @ 08074254
	movs r3, #0                          @ 08074256
	ldr r0, .Lp08074284                  @ 08074258
	ldr r0, [r0]                         @ 0807425A
	cmp r0, #0                           @ 0807425C
	bne .L08074262                       @ 0807425E
	movs r3, #1                          @ 08074260
.L08074262:
	ldr r4, [r4]                         @ 08074262
	adds r0, r6, #0                      @ 08074264
	ldr r1, [sp, #4]                     @ 08074266
	mov r2, sl                           @ 08074268
	bl _call_via_r4                      @ 0807426A
	strb r7, [r5]                        @ 0807426E
	b .L080742BA                         @ 08074270
	.align 2, 0
.Lp08074274:	.word INS_panEnv+ENV_type
.Lp08074278:	.word gSnd
.Lp0807427C:	.word gMusCurChannel
.Lp08074280:	.word gSndMixChannelFn
.Lp08074284:	.word gMusTickPos
.L08074288:
	ldrb r7, [r6, #0x18]                 @ 08074288
	ldrh r0, [r6, #0x28]                 @ 0807428A
	strh r0, [r6, #0x26]                 @ 0807428C
	adds r5, r6, #0                      @ 0807428E
	adds r5, #0x24                       @ 08074290
	ldrb r0, [r5]                        @ 08074292
	adds r4, r6, #0                      @ 08074294
	adds r4, #0x2c                       @ 08074296
	strb r0, [r4]                        @ 08074298
	adds r0, r6, #0                      @ 0807429A
	bl musTickVolume                     @ 0807429C
	ldrh r0, [r6, #0x26]                 @ 080742A0
	strh r0, [r6, #0x28]                 @ 080742A2
	ldrb r0, [r4]                        @ 080742A4
	strb r0, [r5]                        @ 080742A6
	ldr r1, .Lp080742D4                  @ 080742A8
	lsls r0, r7, #2                      @ 080742AA
	adds r0, r0, r1                      @ 080742AC
	ldr r3, [r0]                         @ 080742AE
	adds r0, r6, #0                      @ 080742B0
	ldr r1, [sp, #4]                     @ 080742B2
	mov r2, sl                           @ 080742B4
	bl _call_via_r3                      @ 080742B6
.L080742BA:
	movs r2, #1                          @ 080742BA
	add r8, r2                           @ 080742BC
	cmp r8, sb                           @ 080742BE
	bhs .L080742C4                       @ 080742C0
	b .L080741B2                         @ 080742C2
.L080742C4:
	add sp, #0xc                         @ 080742C4
	pop {r3, r4, r5}                     @ 080742C6
	mov r8, r3                           @ 080742C8
	mov sb, r4                           @ 080742CA
	mov sl, r5                           @ 080742CC
	pop {r4, r5, r6, r7}                 @ 080742CE
	pop {r0}                             @ 080742D0
	bx r0                                @ 080742D2
.Lp080742D4:	.word musTickFxTable

@ ============================================================================
@ void musRowEffect(MusPlayer *P, MusChannel *c)           [musReadRow] row-time part of the effects
@   x = c->param;
@   switch (c->cmd) {
@   case 0x08: c->pan = (s8)x;         break;   // 8xx raw: 65..127 = hard right, 128..255 = negative
@                                               //          and clamped to hard left by the mixer
@   case 0x09: c->pos = x << 22;       break;   // 9xx sample offset (x*256 samples)
@   case 0x0B: P->order = (P->loop & 1) ? x : -2; P->row = 0; break;   // Bxx; stops the song if not looping
@   case 0x0C: c->baseVol = min((s8)x, 64); break;  // Cxx (x >= 0x80 is negative -> silent)
@   case 0x0D: P->order = P->lastOrder + 1; if (P->order >= songLen) P->order = loop ? restart : -2;
@              P->row = (x >> 4) * 10 + (x & 15); break;             // Dxx, decimal
@   case 0x0F: if (!x) break;
@              if (x <= 0x20) P->speed = x; else P->tickHz = x * 50 / 125;
@              P->rowLen = (P->speed << 14) / P->tickHz; P->tickLen = P->rowLen / P->speed;
@              if (P->rowLen == 945 && P->tickLen == 315) P->rowLen = 944;  // dead store, rowLen unused
@              break;
@   case 0x17: c->basePer -= x; clamp >= 40;   break;   // X1x extra fine porta up
@   case 0x18: c->basePer += x; clamp <= 7680; break;   // X2x extra fine porta down
@   case 0x1A: c->basePer -= x * 4; clamp >= 40;   break;   // E1x fine porta up (no memory)
@   case 0x1B: c->basePer += x * 4; clamp <= 7680; break;   // E2x fine porta down
@   case 0x1D: if (x <= 3) c->vibPos = 0;  c->vibWave = (x & 3) == 3 ? 0 : x & 3;  break;   // E4x
@   case 0x20: if (x <= 3) c->tremPos = 0; c->tremWave = (x & 3) == 3 ? 0 : x & 3; break;   // E7x
@   case 0x21: c->pan = x;                     break;   // E8x: 0..15 on the 0..64 scale
@   case 0x23: c->baseVol = min(c->baseVol + x, 64); break;   // EAx
@   case 0x24: c->baseVol = max(c->baseVol - x, 0);  break;   // EBx
@   }
@ Effect numbers 0x10-0x27 are the converter's own: Exy becomes 0x19+x, X1x/X2x become 0x17/0x18.
@ ============================================================================
	thumb_func_start musRowEffect
musRowEffect: @ 0x080742D8
	push {r4, r5, r6, lr}                @ 080742D8
	adds r6, r0, #0                      @ 080742DA
	adds r3, r1, #0                      @ 080742DC
	ldrb r0, [r3, #0x18]                 @ 080742DE
	ldrb r2, [r3, #0x1a]                 @ 080742E0
	subs r0, #8                          @ 080742E2
	cmp r0, #0x1c                        @ 080742E4
	bls .L080742EA                       @ 080742E6
	b .L08074568                         @ 080742E8
.L080742EA:
	lsls r0, r0, #2                      @ 080742EA
	ldr r1, .Lp080742F4                  @ 080742EC
	adds r0, r0, r1                      @ 080742EE
	ldr r0, [r0]                         @ 080742F0
	mov pc, r0                           @ 080742F2
.Lp080742F4:	.word musRowEffect_jt
	.align 2, 0
musRowEffect_jt: @ switch on cmd-8 (0x08..0x24)
	.word .L0807436C @ cmd 0x08
	.word .L08074374 @ cmd 0x09
	.word .L08074568 @ cmd 0x0A
	.word .L080744E0 @ cmd 0x0B
	.word .L0807437A @ cmd 0x0C
	.word .L0807451C @ cmd 0x0D
	.word .L08074568 @ cmd 0x0E
	.word .L08074430 @ cmd 0x0F
	.word .L08074568 @ cmd 0x10
	.word .L08074568 @ cmd 0x11
	.word .L08074568 @ cmd 0x12
	.word .L08074568 @ cmd 0x13
	.word .L08074568 @ cmd 0x14
	.word .L08074568 @ cmd 0x15
	.word .L08074568 @ cmd 0x16
	.word .L08074402 @ cmd 0x17
	.word .L08074418 @ cmd 0x18
	.word .L08074568 @ cmd 0x19
	.word .L08074384 @ cmd 0x1A
	.word .L0807438C @ cmd 0x1B
	.word .L08074568 @ cmd 0x1C
	.word .L08074394 @ cmd 0x1D
	.word .L08074568 @ cmd 0x1E
	.word .L08074568 @ cmd 0x1F
	.word .L080743B2 @ cmd 0x20
	.word .L0807436C @ cmd 0x21
	.word .L08074568 @ cmd 0x22
	.word .L080743D0 @ cmd 0x23
	.word .L080743EA @ cmd 0x24
.L0807436C:
	adds r0, r3, #0                      @ 0807436C
	adds r0, #0x2d                       @ 0807436E
	strb r2, [r0]                        @ 08074370
	b .L08074568                         @ 08074372
.L08074374:
	lsls r0, r2, #0x16                   @ 08074374
	str r0, [r3, #0x20]                  @ 08074376
	b .L08074568                         @ 08074378
.L0807437A:
	adds r1, r3, #0                      @ 0807437A
	adds r1, #0x24                       @ 0807437C
	strb r2, [r1]                        @ 0807437E
	lsls r0, r2, #0x18                   @ 08074380
	b .L080743DC                         @ 08074382
.L08074384:
	lsls r1, r2, #2                      @ 08074384
	ldrh r0, [r3, #0x28]                 @ 08074386
	subs r0, r0, r1                      @ 08074388
	b .L08074406                         @ 0807438A
.L0807438C:
	lsls r0, r2, #2                      @ 0807438C
	ldrh r1, [r3, #0x28]                 @ 0807438E
	adds r0, r0, r1                      @ 08074390
	b .L0807441C                         @ 08074392
.L08074394:
	cmp r2, #3                           @ 08074394
	bgt .L080743A0                       @ 08074396
	adds r1, r3, #0                      @ 08074398
	adds r1, #0x48                       @ 0807439A
	movs r0, #0                          @ 0807439C
	strh r0, [r1]                        @ 0807439E
.L080743A0:
	movs r0, #3                          @ 080743A0
	ands r2, r0                          @ 080743A2
	cmp r2, #3                           @ 080743A4
	bne .L080743AA                       @ 080743A6
	movs r2, #0                          @ 080743A8
.L080743AA:
	adds r0, r3, #0                      @ 080743AA
	adds r0, #0x44                       @ 080743AC
	strb r2, [r0]                        @ 080743AE
	b .L08074568                         @ 080743B0
.L080743B2:
	cmp r2, #3                           @ 080743B2
	bgt .L080743BE                       @ 080743B4
	adds r1, r3, #0                      @ 080743B6
	adds r1, #0x4a                       @ 080743B8
	movs r0, #0                          @ 080743BA
	strh r0, [r1]                        @ 080743BC
.L080743BE:
	movs r0, #3                          @ 080743BE
	ands r2, r0                          @ 080743C0
	cmp r2, #3                           @ 080743C2
	bne .L080743C8                       @ 080743C4
	movs r2, #0                          @ 080743C6
.L080743C8:
	adds r0, r3, #0                      @ 080743C8
	adds r0, #0x45                       @ 080743CA
	strb r2, [r0]                        @ 080743CC
	b .L08074568                         @ 080743CE
.L080743D0:
	adds r1, r3, #0                      @ 080743D0
	adds r1, #0x24                       @ 080743D2
	ldrb r0, [r1]                        @ 080743D4
	adds r0, r0, r2                      @ 080743D6
	strb r0, [r1]                        @ 080743D8
	lsls r0, r0, #0x18                   @ 080743DA
.L080743DC:
	asrs r0, r0, #0x18                   @ 080743DC
	cmp r0, #0x40                        @ 080743DE
	bgt .L080743E4                       @ 080743E0
	b .L08074568                         @ 080743E2
.L080743E4:
	movs r0, #0x40                       @ 080743E4
	strb r0, [r1]                        @ 080743E6
	b .L08074568                         @ 080743E8
.L080743EA:
	adds r1, r3, #0                      @ 080743EA
	adds r1, #0x24                       @ 080743EC
	ldrb r0, [r1]                        @ 080743EE
	subs r0, r0, r2                      @ 080743F0
	strb r0, [r1]                        @ 080743F2
	lsls r0, r0, #0x18                   @ 080743F4
	cmp r0, #0                           @ 080743F6
	blt .L080743FC                       @ 080743F8
	b .L08074568                         @ 080743FA
.L080743FC:
	movs r0, #0                          @ 080743FC
	strb r0, [r1]                        @ 080743FE
	b .L08074568                         @ 08074400
.L08074402:
	ldrh r0, [r3, #0x28]                 @ 08074402
	subs r0, r0, r2                      @ 08074404
.L08074406:
	strh r0, [r3, #0x28]                 @ 08074406
	lsls r0, r0, #0x10                   @ 08074408
	asrs r0, r0, #0x10                   @ 0807440A
	cmp r0, #0x27                        @ 0807440C
	ble .L08074412                       @ 0807440E
	b .L08074568                         @ 08074410
.L08074412:
	movs r0, #0x28                       @ 08074412
	strh r0, [r3, #0x28]                 @ 08074414
	b .L08074568                         @ 08074416
.L08074418:
	ldrh r0, [r3, #0x28]                 @ 08074418
	adds r0, r0, r2                      @ 0807441A
.L0807441C:
	strh r0, [r3, #0x28]                 @ 0807441C
	lsls r0, r0, #0x10                   @ 0807441E
	asrs r0, r0, #0x10                   @ 08074420
	movs r1, #0xf0                       @ 08074422
	lsls r1, r1, #5                      @ 08074424
	cmp r0, r1                           @ 08074426
	bgt .L0807442C                       @ 08074428
	b .L08074568                         @ 0807442A
.L0807442C:
	strh r1, [r3, #0x28]                 @ 0807442C
	b .L08074568                         @ 0807442E
.L08074430:
	cmp r2, #0                           @ 08074430
	beq .L080744AC                       @ 08074432
	cmp r2, #0x20                        @ 08074434
	bgt .L08074474                       @ 08074436
	ldr r0, .Lp08074468                  @ 08074438
	adds r4, r6, r0                      @ 0807443A
	strh r2, [r4]                        @ 0807443C
	movs r1, #0xa1                       @ 0807443E
	lsls r1, r1, #3                      @ 08074440
	adds r5, r6, r1                      @ 08074442
	movs r2, #0                          @ 08074444
	ldrsh r0, [r4, r2]                   @ 08074446
	lsls r0, r0, #0xe                    @ 08074448
	ldr r2, .Lp0807446C                  @ 0807444A
	adds r1, r6, r2                      @ 0807444C
	movs r2, #0                          @ 0807444E
	ldrsh r1, [r1, r2]                   @ 08074450
	bl __divsi3                          @ 08074452
	str r0, [r5]                         @ 08074456
	ldr r1, .Lp08074470                  @ 08074458
	adds r5, r6, r1                      @ 0807445A
	movs r2, #0                          @ 0807445C
	ldrsh r1, [r4, r2]                   @ 0807445E
	bl __divsi3                          @ 08074460
	str r0, [r5]                         @ 08074464
	b .L080744AC                         @ 08074466
.Lp08074468:	.word PL_speed
.Lp0807446C:	.word PL_tickHz
.Lp08074470:	.word PL_tickLen
.L08074474:
	movs r0, #0x32                       @ 08074474
	muls r0, r2, r0                      @ 08074476
	movs r1, #0x7d                       @ 08074478
	bl __divsi3                          @ 0807447A
	ldr r2, .Lp080744D0                  @ 0807447E
	adds r1, r6, r2                      @ 08074480
	strh r0, [r1]                        @ 08074482
	movs r0, #0xa1                       @ 08074484
	lsls r0, r0, #3                      @ 08074486
	adds r4, r6, r0                      @ 08074488
	adds r2, #2                          @ 0807448A
	adds r5, r6, r2                      @ 0807448C
	movs r2, #0                          @ 0807448E
	ldrsh r0, [r5, r2]                   @ 08074490
	lsls r0, r0, #0xe                    @ 08074492
	movs r2, #0                          @ 08074494
	ldrsh r1, [r1, r2]                   @ 08074496
	bl __divsi3                          @ 08074498
	str r0, [r4]                         @ 0807449C
	ldr r1, .Lp080744D4                  @ 0807449E
	adds r4, r6, r1                      @ 080744A0
	movs r2, #0                          @ 080744A2
	ldrsh r1, [r5, r2]                   @ 080744A4
	bl __divsi3                          @ 080744A6
	str r0, [r4]                         @ 080744AA
.L080744AC:
	movs r0, #0xa1                       @ 080744AC
	lsls r0, r0, #3                      @ 080744AE
	adds r2, r6, r0                      @ 080744B0
	ldr r1, [r2]                         @ 080744B2
	ldr r0, .Lp080744D8                  @ 080744B4
	cmp r1, r0                           @ 080744B6
	bne .L08074568                       @ 080744B8
	ldr r1, .Lp080744D4                  @ 080744BA
	adds r0, r6, r1                      @ 080744BC
	ldr r1, [r0]                         @ 080744BE
	ldr r0, .Lp080744DC                  @ 080744C0
	cmp r1, r0                           @ 080744C2
	bne .L08074568                       @ 080744C4
	movs r0, #0xec                       @ 080744C6
	lsls r0, r0, #2                      @ 080744C8
	str r0, [r2]                         @ 080744CA
	b .L08074568                         @ 080744CC
	.align 2, 0
.Lp080744D0:	.word PL_tickHz
.Lp080744D4:	.word PL_tickLen
.Lp080744D8:	.word 0x000003B1
.Lp080744DC:	.word 0x0000013B
.L080744E0:
	ldr r1, .Lp080744F8                  @ 080744E0
	adds r0, r6, r1                      @ 080744E2
	ldrh r1, [r0]                        @ 080744E4
	movs r0, #1                          @ 080744E6
	ands r0, r1                          @ 080744E8
	cmp r0, #0                           @ 080744EA
	beq .L08074500                       @ 080744EC
	ldr r1, .Lp080744FC                  @ 080744EE
	adds r0, r6, r1                      @ 080744F0
	strh r2, [r0]                        @ 080744F2
	b .L08074508                         @ 080744F4
	.align 2, 0
.Lp080744F8:	.word PL_loop
.Lp080744FC:	.word PL_order
.L08074500:
	ldr r2, .Lp08074510                  @ 08074500
	adds r1, r6, r2                      @ 08074502
	ldr r0, .Lp08074514                  @ 08074504
	strh r0, [r1]                        @ 08074506
.L08074508:
	ldr r0, .Lp08074518                  @ 08074508
	adds r1, r6, r0                      @ 0807450A
	movs r0, #0                          @ 0807450C
	b .L08074566                         @ 0807450E
.Lp08074510:	.word PL_order
.Lp08074514:	.word 0x0000FFFE
.Lp08074518:	.word PL_row
.L0807451C:
	movs r1, #0x9e                       @ 0807451C
	lsls r1, r1, #3                      @ 0807451E
	adds r0, r6, r1                      @ 08074520
	ldrh r0, [r0]                        @ 08074522
	adds r0, #1                          @ 08074524
	adds r1, #2                          @ 08074526
	adds r3, r6, r1                      @ 08074528
	strh r0, [r3]                        @ 0807452A
	movs r1, #0                          @ 0807452C
	ldrsh r0, [r3, r1]                   @ 0807452E
	ldr r4, [r6]                         @ 08074530
	ldrh r1, [r4, #0x34]                 @ 08074532
	cmp r0, r1                           @ 08074534
	blt .L08074554                       @ 08074536
	ldr r1, .Lp0807454C                  @ 08074538
	adds r0, r6, r1                      @ 0807453A
	ldrh r1, [r0]                        @ 0807453C
	movs r0, #1                          @ 0807453E
	ands r0, r1                          @ 08074540
	cmp r0, #0                           @ 08074542
	beq .L08074550                       @ 08074544
	ldrh r0, [r4, #0x36]                 @ 08074546
	b .L08074552                         @ 08074548
	.align 2, 0
.Lp0807454C:	.word PL_loop
.L08074550:
	ldr r0, .Lp08074570                  @ 08074550
.L08074552:
	strh r0, [r3]                        @ 08074552
.L08074554:
	asrs r1, r2, #4                      @ 08074554
	lsls r0, r1, #2                      @ 08074556
	adds r0, r0, r1                      @ 08074558
	lsls r0, r0, #1                      @ 0807455A
	movs r1, #0xf                        @ 0807455C
	ands r2, r1                          @ 0807455E
	adds r0, r0, r2                      @ 08074560
	ldr r2, .Lp08074574                  @ 08074562
	adds r1, r6, r2                      @ 08074564
.L08074566:
	strh r0, [r1]                        @ 08074566
.L08074568:
	pop {r4, r5, r6}                     @ 08074568
	pop {r0}                             @ 0807456A
	bx r0                                @ 0807456C
	.align 2, 0
.Lp08074570:	.word 0x0000FFFE
.Lp08074574:	.word PL_row

@ ============================================================================
@ void musVolumeColumn(MusChannel *c)                      [musReadRow] row-time volume column
@   v = c->volcol; x = v & 15;
@   switch (v & 0xF0) {
@   case 0x80: c->baseVol -= x; break;                 // fine volume down
@   case 0x90: c->baseVol += x; break;                 // fine volume up
@   case 0xA0: c->fxMem[3] = c->fxMem[3] & 15 | x << 4; break;    // vibrato speed
@   case 0xB0: if (x <= 3) c->vibPos = 0; c->vibWave = (x & 3) == 3 ? 0 : x & 3; break;
@                                                      // should be vibrato depth; sets the waveform
@   case 0xC0: c->pan = x; break;                      // 0..15, should be x*4 on this 0..64 scale
@   default:   if (v - 0x10 <= 0x3F) c->baseVol = v - 0x10;   // 0x10..0x4F; 0x50 (volume 64) is ignored
@   }
@ ============================================================================
	thumb_func_start musVolumeColumn
musVolumeColumn: @ 0x08074578
	push {r4, lr}                        @ 08074578
	adds r2, r0, #0                      @ 0807457A
	ldrb r1, [r2, #0x14]                 @ 0807457C
	movs r0, #0xf0                       @ 0807457E
	ands r0, r1                          @ 08074580
	movs r4, #0xf                        @ 08074582
	adds r3, r1, #0                      @ 08074584
	ands r3, r4                          @ 08074586
	cmp r0, #0x90                        @ 08074588
	beq .L080745C8                       @ 0807458A
	cmp r0, #0x90                        @ 0807458C
	bhi .L0807459A                       @ 0807458E
	cmp r0, #0x10                        @ 08074590
	beq .L080745AC                       @ 08074592
	cmp r0, #0x80                        @ 08074594
	beq .L080745BC                       @ 08074596
	b .L080745AC                         @ 08074598
.L0807459A:
	cmp r0, #0xb0                        @ 0807459A
	beq .L080745E4                       @ 0807459C
	cmp r0, #0xb0                        @ 0807459E
	bhi .L080745A8                       @ 080745A0
	cmp r0, #0xa0                        @ 080745A2
	beq .L080745D4                       @ 080745A4
	b .L080745AC                         @ 080745A6
.L080745A8:
	cmp r0, #0xc0                        @ 080745A8
	beq .L08074600                       @ 080745AA
.L080745AC:
	subs r0, #0x10                       @ 080745AC
	cmp r0, #0x3f                        @ 080745AE
	bhi .L08074606                       @ 080745B0
	subs r1, #0x10                       @ 080745B2
	adds r0, r2, #0                      @ 080745B4
	adds r0, #0x24                       @ 080745B6
	strb r1, [r0]                        @ 080745B8
	b .L08074606                         @ 080745BA
.L080745BC:
	adds r1, r2, #0                      @ 080745BC
	adds r1, #0x24                       @ 080745BE
	ldrb r0, [r1]                        @ 080745C0
	subs r0, r0, r3                      @ 080745C2
	strb r0, [r1]                        @ 080745C4
	b .L08074606                         @ 080745C6
.L080745C8:
	adds r1, r2, #0                      @ 080745C8
	adds r1, #0x24                       @ 080745CA
	ldrb r0, [r1]                        @ 080745CC
	adds r0, r0, r3                      @ 080745CE
	strb r0, [r1]                        @ 080745D0
	b .L08074606                         @ 080745D2
.L080745D4:
	adds r2, #0x37                       @ 080745D4
	ldrb r1, [r2]                        @ 080745D6
	adds r0, r4, #0                      @ 080745D8
	ands r0, r1                          @ 080745DA
	lsls r1, r3, #4                      @ 080745DC
	orrs r0, r1                          @ 080745DE
	strb r0, [r2]                        @ 080745E0
	b .L08074606                         @ 080745E2
.L080745E4:
	cmp r3, #3                           @ 080745E4
	bhi .L080745F0                       @ 080745E6
	adds r1, r2, #0                      @ 080745E8
	adds r1, #0x48                       @ 080745EA
	movs r0, #0                          @ 080745EC
	strh r0, [r1]                        @ 080745EE
.L080745F0:
	movs r0, #3                          @ 080745F0
	ands r3, r0                          @ 080745F2
	cmp r3, #3                           @ 080745F4
	bne .L080745FA                       @ 080745F6
	movs r3, #0                          @ 080745F8
.L080745FA:
	adds r0, r2, #0                      @ 080745FA
	adds r0, #0x44                       @ 080745FC
	b .L08074604                         @ 080745FE
.L08074600:
	adds r0, r2, #0                      @ 08074600
	adds r0, #0x2d                       @ 08074602
.L08074604:
	strb r3, [r0]                        @ 08074604
.L08074606:
	pop {r4}                             @ 08074606
	pop {r0}                             @ 08074608
	bx r0                                @ 0807460A

@ ============================================================================
@ void musStart(MusPlayer *P, Module *m)
@   P->order = -1; P->module = m;
@   for (ch = 0; ch < 16; ch++) { memset(&P->chan[ch], 0, CH_SIZE);
@       P->chan[ch].chanVol = m->chanSet[ch].vol; P->chan[ch].pan = m->chanSet[ch].pan; }
@   for (i = 7; i >= 0; i--) P->voiceOwner[i] = 0;   // also drops voices reserved by playing SFX
@   if (P->maxVoices > 7) P->maxVoices = 8;
@   P->nChannels = min(m->nChan, 16);
@   P->volume = 0; P->loop = 0;
@   musReset(P);
@   P->order = -1;                                   // paused until musSetParams
@ ============================================================================
	thumb_func_start musStart
musStart: @ 0x0807460C
	push {r4, r5, r6, r7, lr}            @ 0807460C
	mov r7, r8                           @ 0807460E
	push {r7}                            @ 08074610
	adds r6, r0, #0                      @ 08074612
	ldr r0, .Lp080746D0                  @ 08074614
	adds r2, r6, r0                      @ 08074616
	ldr r0, .Lp080746D4                  @ 08074618
	strh r0, [r2]                        @ 0807461A
	str r1, [r6]                         @ 0807461C
	movs r5, #0                          @ 0807461E
	movs r1, #0                          @ 08074620
	mov ip, r1                           @ 08074622
	movs r2, #0                          @ 08074624
	mov r8, r2                           @ 08074626
.L08074628:
	movs r0, #0x4c                       @ 08074628
	adds r3, r5, #0                      @ 0807462A
	muls r3, r0, r3                      @ 0807462C
	adds r3, r3, r6                      @ 0807462E
	adds r3, #4                          @ 08074630
	lsls r1, r5, #1                      @ 08074632
	ldr r0, [r6]                         @ 08074634
	adds r1, r1, r0                      @ 08074636
	movs r7, #0x91                       @ 08074638
	lsls r7, r7, #2                      @ 0807463A
	adds r1, r1, r7                      @ 0807463C
	adds r4, r3, #0                      @ 0807463E
	movs r2, #0                          @ 08074640
.L08074642:
	adds r0, r4, r2                      @ 08074642
	mov r7, ip                           @ 08074644
	strb r7, [r0]                        @ 08074646
	adds r2, #1                          @ 08074648
	cmp r2, #0x4b                        @ 0807464A
	bls .L08074642                       @ 0807464C
	ldrb r0, [r1]                        @ 0807464E
	adds r2, r3, #0                      @ 08074650
	adds r2, #0x2e                       @ 08074652
	strb r0, [r2]                        @ 08074654
	ldrb r0, [r1, #1]                    @ 08074656
	subs r2, #1                          @ 08074658
	strb r0, [r2]                        @ 0807465A
	adds r0, r3, #0                      @ 0807465C
	adds r0, #0x44                       @ 0807465E
	mov r1, r8                           @ 08074660
	strb r1, [r0]                        @ 08074662
	adds r0, #1                          @ 08074664
	strb r1, [r0]                        @ 08074666
	adds r5, #1                          @ 08074668
	cmp r5, #0xf                         @ 0807466A
	ble .L08074628                       @ 0807466C
	movs r1, #0                          @ 0807466E
	movs r5, #7                          @ 08074670
	movs r2, #0x9c                       @ 08074672
	lsls r2, r2, #3                      @ 08074674
	adds r0, r6, r2                      @ 08074676
.L08074678:
	str r1, [r0]                         @ 08074678
	subs r0, #4                          @ 0807467A
	subs r5, #1                          @ 0807467C
	cmp r5, #0                           @ 0807467E
	bge .L08074678                       @ 08074680
	movs r5, #8                          @ 08074682
	ldr r7, .Lp080746D8                  @ 08074684
	adds r1, r6, r7                      @ 08074686
	ldrb r0, [r1]                        @ 08074688
	cmp r0, #7                           @ 0807468A
	bls .L08074690                       @ 0807468C
	strb r5, [r1]                        @ 0807468E
.L08074690:
	ldr r0, [r6]                         @ 08074690
	ldrh r0, [r0, #0x38]                 @ 08074692
	ldr r2, .Lp080746DC                  @ 08074694
	adds r1, r6, r2                      @ 08074696
	movs r2, #0                          @ 08074698
	strb r0, [r1]                        @ 0807469A
	lsls r0, r0, #0x18                   @ 0807469C
	lsrs r0, r0, #0x18                   @ 0807469E
	cmp r0, #0xf                         @ 080746A0
	bls .L080746A8                       @ 080746A2
	movs r0, #0x10                       @ 080746A4
	strb r0, [r1]                        @ 080746A6
.L080746A8:
	movs r7, #0x9d                       @ 080746A8
	lsls r7, r7, #3                      @ 080746AA
	adds r0, r6, r7                      @ 080746AC
	strh r2, [r0]                        @ 080746AE
	ldr r1, .Lp080746E0                  @ 080746B0
	adds r0, r6, r1                      @ 080746B2
	strh r2, [r0]                        @ 080746B4
	adds r0, r6, #0                      @ 080746B6
	bl musReset                          @ 080746B8
	ldr r2, .Lp080746D0                  @ 080746BC
	adds r1, r6, r2                      @ 080746BE
	ldr r0, .Lp080746D4                  @ 080746C0
	strh r0, [r1]                        @ 080746C2
	pop {r3}                             @ 080746C4
	mov r8, r3                           @ 080746C6
	pop {r4, r5, r6, r7}                 @ 080746C8
	pop {r0}                             @ 080746CA
	bx r0                                @ 080746CC
	.align 2, 0
.Lp080746D0:	.word PL_order
.Lp080746D4:	.word 0x0000FFFF
.Lp080746D8:	.word PL_maxVoices
.Lp080746DC:	.word PL_nChannels
.Lp080746E0:	.word PL_loop

@ ============================================================================
@ void musReset(MusPlayer *P)
@   P->tick = P->tickPos = 0;
@   P->tickHz = m->bpm * 50 / 125;  P->speed = m->speed;
@   P->rowLen = (P->speed << 14) / P->tickHz;  P->tickLen = P->rowLen / P->speed;
@   P->row = P->lastRow = 0; P->rowMask = 0; P->lastOrder = -1; P->savedOrder = -1; P->order = 0;
@   for (i = 0; i < P->maxVoices; i++) if (P->voiceOwner[i] != 1) P->voiceOwner[i] = 0;
@ ============================================================================
	thumb_func_start musReset
musReset: @ 0x080746E4
	push {r4, r5, r6, r7, lr}            @ 080746E4
	adds r7, r0, #0                      @ 080746E6
	movs r1, #0xa0                       @ 080746E8
	lsls r1, r1, #3                      @ 080746EA
	adds r0, r7, r1                      @ 080746EC
	movs r6, #0                          @ 080746EE
	str r6, [r0]                         @ 080746F0
	ldr r2, .Lp08074794                  @ 080746F2
	adds r0, r7, r2                      @ 080746F4
	str r6, [r0]                         @ 080746F6
	ldr r0, [r7]                         @ 080746F8
	adds r0, #0x40                       @ 080746FA
	ldrh r1, [r0]                        @ 080746FC
	movs r0, #0x32                       @ 080746FE
	muls r0, r1, r0                      @ 08074700
	movs r1, #0x7d                       @ 08074702
	bl __divsi3                          @ 08074704
	ldr r2, .Lp08074798                  @ 08074708
	adds r1, r7, r2                      @ 0807470A
	strh r0, [r1]                        @ 0807470C
	ldr r0, [r7]                         @ 0807470E
	ldrh r0, [r0, #0x3e]                 @ 08074710
	adds r2, #2                          @ 08074712
	adds r4, r7, r2                      @ 08074714
	strh r0, [r4]                        @ 08074716
	movs r0, #0xa1                       @ 08074718
	lsls r0, r0, #3                      @ 0807471A
	adds r5, r7, r0                      @ 0807471C
	movs r2, #0                          @ 0807471E
	ldrsh r0, [r4, r2]                   @ 08074720
	lsls r0, r0, #0xe                    @ 08074722
	movs r2, #0                          @ 08074724
	ldrsh r1, [r1, r2]                   @ 08074726
	bl __divsi3                          @ 08074728
	str r0, [r5]                         @ 0807472C
	ldr r1, .Lp0807479C                  @ 0807472E
	adds r5, r7, r1                      @ 08074730
	movs r2, #0                          @ 08074732
	ldrsh r1, [r4, r2]                   @ 08074734
	bl __divsi3                          @ 08074736
	str r0, [r5]                         @ 0807473A
	ldr r1, .Lp080747A0                  @ 0807473C
	adds r0, r7, r1                      @ 0807473E
	strh r6, [r0]                        @ 08074740
	ldr r2, .Lp080747A4                  @ 08074742
	adds r0, r7, r2                      @ 08074744
	strh r6, [r0]                        @ 08074746
	adds r1, #6                          @ 08074748
	adds r0, r7, r1                      @ 0807474A
	str r6, [r0]                         @ 0807474C
	subs r2, #4                          @ 0807474E
	adds r1, r7, r2                      @ 08074750
	ldr r0, .Lp080747A8                  @ 08074752
	strh r0, [r1]                        @ 08074754
	movs r0, #0x9f                       @ 08074756
	lsls r0, r0, #3                      @ 08074758
	adds r1, r7, r0                      @ 0807475A
	movs r0, #1                          @ 0807475C
	rsbs r0, r0, #0                      @ 0807475E
	strh r0, [r1]                        @ 08074760
	ldr r1, .Lp080747AC                  @ 08074762
	adds r0, r7, r1                      @ 08074764
	strh r6, [r0]                        @ 08074766
	movs r2, #0                          @ 08074768
	adds r1, #9                          @ 0807476A
	adds r0, r7, r1                      @ 0807476C
	ldrb r1, [r0]                        @ 0807476E
	cmp r2, r1                           @ 08074770
	bge .L0807478E                       @ 08074772
	movs r4, #0                          @ 08074774
	adds r3, r0, #0                      @ 08074776
	ldr r0, .Lp080747B0                  @ 08074778
	adds r1, r7, r0                      @ 0807477A
.L0807477C:
	ldr r0, [r1]                         @ 0807477C
	cmp r0, #1                           @ 0807477E
	beq .L08074784                       @ 08074780
	str r4, [r1]                         @ 08074782
.L08074784:
	adds r1, #4                          @ 08074784
	adds r2, #1                          @ 08074786
	ldrb r0, [r3]                        @ 08074788
	cmp r2, r0                           @ 0807478A
	blt .L0807477C                       @ 0807478C
.L0807478E:
	pop {r4, r5, r6, r7}                 @ 0807478E
	pop {r0}                             @ 08074790
	bx r0                                @ 08074792
.Lp08074794:	.word PL_tickPos
.Lp08074798:	.word PL_tickHz
.Lp0807479C:	.word PL_tickLen
.Lp080747A0:	.word PL_row
.Lp080747A4:	.word PL_lastRow
.Lp080747A8:	.word 0x0000FFFF
.Lp080747AC:	.word PL_order
.Lp080747B0:	.word PL_voiceOwner

@ ============================================================================
@ int musMix(MusPlayer *P, s16 *mix, int n)                [sndFrame] returns samples mixed (<= n)
@   m = P->module;
@   if (P->order < 0) return n;
@   if (P->tickPos == 0 && P->tick == 0) {                 // first sample of a row
@       if (P->lastOrder != P->order) P->patPtr = (u8*)m + m->patTab[m->orders[P->order]].offset;
@       P->lastOrder = P->order; P->lastRow = P->row; P->row++;
@       if (P->row >= m->patTab[m->orders[P->lastOrder]].rows) {     // this is the last row: advance
@           P->row = 0;
@           do { if (++P->order >= m->songLen) { if (P->loop & 1) { P->lastOrder = -1;
@                      P->order = m->restart; } else P->order = -2; break; } }
@           while (m->orders[P->order] >= m->nPat);        // skip invalid order entries
@       }
@   }
@   gMusVolume = P->volume;
@   if (P->tickPos == 0 && P->tick == 0) musReadRow(P);
@   if (P->tickPos + n >= P->tickLen) n = P->tickLen - P->tickPos;
@   gMusTick = P->tick; gMusTickPos = P->tickPos;
@   musMixSlice(P, mix, n);
@   P->volume = gMusVolume;
@   if ((P->tickPos += n) >= P->tickLen) { P->tickPos = 0; if (++P->tick >= P->speed) P->tick = 0; }
@   return n;
@ Note: the pattern pointer is only reloaded when the order changes, so a Bxx that jumps to the order
@ already playing keeps reading past the end of the pattern.
@ ============================================================================
	thumb_func_start musMix
musMix: @ 0x080747B4
	push {r4, r5, r6, r7, lr}            @ 080747B4
	mov r7, sl                           @ 080747B6
	mov r6, sb                           @ 080747B8
	mov r5, r8                           @ 080747BA
	push {r5, r6, r7}                    @ 080747BC
	sub sp, #8                           @ 080747BE
	adds r4, r0, #0                      @ 080747C0
	mov sl, r1                           @ 080747C2
	mov sb, r2                           @ 080747C4
	ldr r3, [r4]                         @ 080747C6
	ldr r0, .Lp080747D8                  @ 080747C8
	adds r5, r4, r0                      @ 080747CA
	movs r2, #0                          @ 080747CC
	ldrsh r1, [r5, r2]                   @ 080747CE
	cmp r1, #0                           @ 080747D0
	bge .L080747F0                       @ 080747D2
	b .L08074936                         @ 080747D4
	.align 2, 0
.Lp080747D8:	.word PL_order
.L080747DC:
	movs r5, #0x9e                       @ 080747DC
	lsls r5, r5, #3                      @ 080747DE
	adds r0, r4, r5                      @ 080747E0
	ldr r1, .Lp080747EC                  @ 080747E2
	strh r1, [r0]                        @ 080747E4
	ldrh r0, [r3, #0x36]                 @ 080747E6
	b .L080748C0                         @ 080747E8
	.align 2, 0
.Lp080747EC:	.word 0x0000FFFF
.L080747F0:
	ldr r2, .Lp08074880                  @ 080747F0
	adds r0, r4, r2                      @ 080747F2
	ldr r6, [r0]                         @ 080747F4
	subs r2, #4                          @ 080747F6
	adds r0, r4, r2                      @ 080747F8
	ldr r7, [r0]                         @ 080747FA
	movs r0, #0x44                       @ 080747FC
	adds r0, r0, r3                      @ 080747FE
	mov r8, r0                           @ 08074800
	cmp r6, #0                           @ 08074802
	bne .L08074850                       @ 08074804
	cmp r7, #0                           @ 08074806
	bne .L08074850                       @ 08074808
	subs r2, #0x10                       @ 0807480A
	adds r2, r2, r4                      @ 0807480C
	mov ip, r2                           @ 0807480E
	movs r0, #0                          @ 08074810
	ldrsh r2, [r2, r0]                   @ 08074812
	cmp r2, r1                           @ 08074814
	beq .L08074838                       @ 08074816
	ldr r1, .Lp08074884                  @ 08074818
	adds r1, r4, r1                      @ 0807481A
	str r1, [sp, #4]                     @ 0807481C
	movs r2, #0                          @ 0807481E
	ldrsh r0, [r5, r2]                   @ 08074820
	add r0, r8                           @ 08074822
	ldrb r1, [r0]                        @ 08074824
	lsls r1, r1, #3                      @ 08074826
	movs r2, #0xa2                       @ 08074828
	lsls r2, r2, #2                      @ 0807482A
	adds r0, r3, r2                      @ 0807482C
	adds r0, r0, r1                      @ 0807482E
	ldr r0, [r0]                         @ 08074830
	adds r0, r3, r0                      @ 08074832
	ldr r1, [sp, #4]                     @ 08074834
	str r0, [r1]                         @ 08074836
.L08074838:
	ldrh r0, [r5]                        @ 08074838
	mov r2, ip                           @ 0807483A
	strh r0, [r2]                        @ 0807483C
	ldr r5, .Lp08074888                  @ 0807483E
	adds r1, r4, r5                      @ 08074840
	ldrh r2, [r1]                        @ 08074842
	subs r5, #2                          @ 08074844
	adds r0, r4, r5                      @ 08074846
	strh r2, [r0]                        @ 08074848
	ldrh r0, [r1]                        @ 0807484A
	adds r0, #1                          @ 0807484C
	strh r0, [r1]                        @ 0807484E
.L08074850:
	movs r1, #0x9e                       @ 08074850
	lsls r1, r1, #3                      @ 08074852
	adds r0, r4, r1                      @ 08074854
	movs r2, #0                          @ 08074856
	ldrsh r0, [r0, r2]                   @ 08074858
	add r0, r8                           @ 0807485A
	ldrb r0, [r0]                        @ 0807485C
	lsls r0, r0, #3                      @ 0807485E
	movs r5, #0xa1                       @ 08074860
	lsls r5, r5, #2                      @ 08074862
	adds r0, r0, r5                      @ 08074864
	adds r0, r3, r0                      @ 08074866
	adds r1, #6                          @ 08074868
	adds r2, r4, r1                      @ 0807486A
	movs r5, #0                          @ 0807486C
	ldrsh r1, [r2, r5]                   @ 0807486E
	ldr r0, [r0]                         @ 08074870
	ldr r5, .Lp0807488C                  @ 08074872
	mov ip, r5                           @ 08074874
	cmp r1, r0                           @ 08074876
	blo .L080748C2                       @ 08074878
	movs r0, #0                          @ 0807487A
	strh r0, [r2]                        @ 0807487C
	b .L0807489A                         @ 0807487E
.Lp08074880:	.word PL_tickPos
.Lp08074884:	.word PL_patPtr
.Lp08074888:	.word PL_row
.Lp0807488C:	.word gMusVolume
.L08074890:
	add r0, r8                           @ 08074890
	ldrb r0, [r0]                        @ 08074892
	ldrh r1, [r3, #0x3a]                 @ 08074894
	cmp r0, r1                           @ 08074896
	blo .L080748C2                       @ 08074898
.L0807489A:
	ldr r5, .Lp08074948                  @ 0807489A
	adds r2, r4, r5                      @ 0807489C
	ldrh r0, [r2]                        @ 0807489E
	adds r0, #1                          @ 080748A0
	movs r5, #0                          @ 080748A2
	strh r0, [r2]                        @ 080748A4
	movs r1, #0                          @ 080748A6
	ldrsh r0, [r2, r1]                   @ 080748A8
	ldrh r1, [r3, #0x34]                 @ 080748AA
	cmp r0, r1                           @ 080748AC
	blt .L08074890                       @ 080748AE
	ldr r1, .Lp0807494C                  @ 080748B0
	adds r0, r4, r1                      @ 080748B2
	ldrh r1, [r0]                        @ 080748B4
	movs r0, #1                          @ 080748B6
	ands r0, r1                          @ 080748B8
	cmp r0, #0                           @ 080748BA
	bne .L080747DC                       @ 080748BC
	ldr r0, .Lp08074950                  @ 080748BE
.L080748C0:
	strh r0, [r2]                        @ 080748C0
.L080748C2:
	movs r2, #0x9d                       @ 080748C2
	lsls r2, r2, #3                      @ 080748C4
	adds r0, r4, r2                      @ 080748C6
	movs r5, #0                          @ 080748C8
	ldrsh r0, [r0, r5]                   @ 080748CA
	mov r1, ip                           @ 080748CC
	str r0, [r1]                         @ 080748CE
	cmp r6, #0                           @ 080748D0
	bne .L080748DE                       @ 080748D2
	cmp r7, #0                           @ 080748D4
	bne .L080748DE                       @ 080748D6
	adds r0, r4, #0                      @ 080748D8
	bl musReadRow                        @ 080748DA
.L080748DE:
	mov r2, sb                           @ 080748DE
	adds r0, r6, r2                      @ 080748E0
	ldr r1, .Lp08074954                  @ 080748E2
	adds r5, r4, r1                      @ 080748E4
	ldr r1, [r5]                         @ 080748E6
	cmp r0, r1                           @ 080748E8
	blt .L080748F0                       @ 080748EA
	subs r1, r1, r6                      @ 080748EC
	mov sb, r1                           @ 080748EE
.L080748F0:
	ldr r0, .Lp08074958                  @ 080748F0
	str r7, [r0]                         @ 080748F2
	ldr r0, .Lp0807495C                  @ 080748F4
	str r6, [r0]                         @ 080748F6
	adds r0, r4, #0                      @ 080748F8
	mov r1, sl                           @ 080748FA
	mov r2, sb                           @ 080748FC
	bl musMixSlice                       @ 080748FE
	ldr r0, .Lp08074960                  @ 08074902
	ldr r1, [r0]                         @ 08074904
	movs r2, #0x9d                       @ 08074906
	lsls r2, r2, #3                      @ 08074908
	adds r0, r4, r2                      @ 0807490A
	strh r1, [r0]                        @ 0807490C
	add r6, sb                           @ 0807490E
	ldr r0, [r5]                         @ 08074910
	cmp r6, r0                           @ 08074912
	blt .L08074928                       @ 08074914
	movs r6, #0                          @ 08074916
	adds r7, #1                          @ 08074918
	ldr r5, .Lp08074964                  @ 0807491A
	adds r0, r4, r5                      @ 0807491C
	movs r1, #0                          @ 0807491E
	ldrsh r0, [r0, r1]                   @ 08074920
	cmp r7, r0                           @ 08074922
	blt .L08074928                       @ 08074924
	movs r7, #0                          @ 08074926
.L08074928:
	ldr r2, .Lp08074968                  @ 08074928
	adds r0, r4, r2                      @ 0807492A
	str r6, [r0]                         @ 0807492C
	movs r5, #0xa0                       @ 0807492E
	lsls r5, r5, #3                      @ 08074930
	adds r0, r4, r5                      @ 08074932
	str r7, [r0]                         @ 08074934
.L08074936:
	mov r0, sb                           @ 08074936
	add sp, #8                           @ 08074938
	pop {r3, r4, r5}                     @ 0807493A
	mov r8, r3                           @ 0807493C
	mov sb, r4                           @ 0807493E
	mov sl, r5                           @ 08074940
	pop {r4, r5, r6, r7}                 @ 08074942
	pop {r1}                             @ 08074944
	bx r1                                @ 08074946
.Lp08074948:	.word PL_order
.Lp0807494C:	.word PL_loop
.Lp08074950:	.word 0x0000FFFE
.Lp08074954:	.word PL_tickLen
.Lp08074958:	.word gMusTick
.Lp0807495C:	.word gMusTickPos
.Lp08074960:	.word gMusVolume
.Lp08074964:	.word PL_speed
.Lp08074968:	.word PL_tickPos

@ ============================================================================
@ void musPlayPacked(MusPlayer *P, void *lz77Module)       [unused]
@   P->module = NULL; LZ77UnCompWram(lz77Module, (void*)0x02000000); musStart(P, (Module*)0x02000000);
@ ============================================================================
	thumb_func_start musPlayPacked
musPlayPacked: @ 0x0807496C
	push {r4, r5, lr}                    @ 0807496C
	adds r5, r0, #0                      @ 0807496E
	adds r0, r1, #0                      @ 08074970
	movs r4, #0x80                       @ 08074972
	lsls r4, r4, #0x12                   @ 08074974
	movs r1, #0                          @ 08074976
	str r1, [r5]                         @ 08074978
	adds r1, r4, #0                      @ 0807497A
	bl swiLZ77UnCompWram                 @ 0807497C
	adds r0, r5, #0                      @ 08074980
	adds r1, r4, #0                      @ 08074982
	bl musStart                          @ 08074984
	pop {r4, r5}                         @ 08074988
	pop {r0}                             @ 0807498A
	bx r0                                @ 0807498C
	.align 2, 0

@ ============================================================================
@ void musSetParams(MusPlayer *P, int vol, int loop, u8 *voiceMap)
@   P->volume = vol; P->loop = loop;
@   if (voiceMap) copy 3 bytes to P->voiceMap; else P->voiceMap = {0, 0, 0};
@   musReset(P);                                     // order = 0: starts playing
@ ============================================================================
	thumb_func_start musSetParams
musSetParams: @ 0x08074990
	push {r4, r5, lr}                    @ 08074990
	adds r5, r0, #0                      @ 08074992
	movs r4, #0x9d                       @ 08074994
	lsls r4, r4, #3                      @ 08074996
	adds r0, r5, r4                      @ 08074998
	strh r1, [r0]                        @ 0807499A
	ldr r1, .Lp080749C0                  @ 0807499C
	adds r0, r5, r1                      @ 0807499E
	strh r2, [r0]                        @ 080749A0
	cmp r3, #0                           @ 080749A2
	beq .L080749C4                       @ 080749A4
	movs r2, #0                          @ 080749A6
	movs r0, #0xa2                       @ 080749A8
	lsls r0, r0, #3                      @ 080749AA
	adds r4, r5, r0                      @ 080749AC
.L080749AE:
	adds r0, r4, r2                      @ 080749AE
	adds r1, r3, r2                      @ 080749B0
	ldrb r1, [r1]                        @ 080749B2
	strb r1, [r0]                        @ 080749B4
	adds r2, #1                          @ 080749B6
	cmp r2, #2                           @ 080749B8
	ble .L080749AE                       @ 080749BA
	b .L080749D6                         @ 080749BC
	.align 2, 0
.Lp080749C0:	.word PL_loop
.L080749C4:
	movs r1, #0                          @ 080749C4
	movs r2, #2                          @ 080749C6
	ldr r3, .Lp080749E4                  @ 080749C8
	adds r0, r5, r3                      @ 080749CA
.L080749CC:
	strb r1, [r0]                        @ 080749CC
	subs r0, #1                          @ 080749CE
	subs r2, #1                          @ 080749D0
	cmp r2, #0                           @ 080749D2
	bge .L080749CC                       @ 080749D4
.L080749D6:
	adds r0, r5, #0                      @ 080749D6
	bl musReset                          @ 080749D8
	pop {r4, r5}                         @ 080749DC
	pop {r0}                             @ 080749DE
	bx r0                                @ 080749E0
	.align 2, 0
.Lp080749E4:	.word PL_voiceMap+2

@ ============================================================================
@ void musReserveVoice(MusPlayer *P, int sfxVoice)          [sfxPlay]
@   i = P->voiceMap[sfxVoice] ? P->voiceMap[sfxVoice] - 1 : 7 - sfxVoice;
@   if (P->voiceOwner[i] > 1) P->voiceOwner[i]->voice &= ~1;   // the music channel goes silent
@   P->voiceOwner[i] = 1;
@ ============================================================================
	thumb_func_start musReserveVoice
musReserveVoice: @ 0x080749E8
	adds r3, r0, #0                      @ 080749E8
	movs r2, #0xa2                       @ 080749EA
	lsls r2, r2, #3                      @ 080749EC
	adds r0, r3, r2                      @ 080749EE
	adds r2, r0, r1                      @ 080749F0
	ldrb r0, [r2]                        @ 080749F2
	cmp r0, #0                           @ 080749F4
	bne .L080749FE                       @ 080749F6
	movs r0, #7                          @ 080749F8
	subs r1, r0, r1                      @ 080749FA
	b .L08074A02                         @ 080749FC
.L080749FE:
	ldrb r0, [r2]                        @ 080749FE
	subs r1, r0, #1                      @ 08074A00
.L08074A02:
	lsls r1, r1, #2                      @ 08074A02
	ldr r2, .Lp08074A20                  @ 08074A04
	adds r0, r3, r2                      @ 08074A06
	adds r3, r0, r1                      @ 08074A08
	ldr r2, [r3]                         @ 08074A0A
	cmp r2, #1                           @ 08074A0C
	bls .L08074A18                       @ 08074A0E
	ldrb r1, [r2, #0x1d]                 @ 08074A10
	movs r0, #0xfe                       @ 08074A12
	ands r0, r1                          @ 08074A14
	strb r0, [r2, #0x1d]                 @ 08074A16
.L08074A18:
	movs r0, #1                          @ 08074A18
	str r0, [r3]                         @ 08074A1A
	bx lr                                @ 08074A1C
	.align 2, 0
.Lp08074A20:	.word PL_voiceOwner

@ ============================================================================
@ void musReleaseVoice(MusPlayer *P, int sfxVoice)          [SFX end / stop]
@   i = as in musReserveVoice;  if (P->voiceOwner[i] == 1) P->voiceOwner[i] = 0;
@   (The muted music channel only gets a voice back at its next note.)
@ ============================================================================
	thumb_func_start musReleaseVoice
musReleaseVoice: @ 0x08074A24
	adds r3, r0, #0                      @ 08074A24
	movs r2, #0xa2                       @ 08074A26
	lsls r2, r2, #3                      @ 08074A28
	adds r0, r3, r2                      @ 08074A2A
	adds r2, r0, r1                      @ 08074A2C
	ldrb r0, [r2]                        @ 08074A2E
	cmp r0, #0                           @ 08074A30
	bne .L08074A3A                       @ 08074A32
	movs r0, #7                          @ 08074A34
	subs r1, r0, r1                      @ 08074A36
	b .L08074A3E                         @ 08074A38
.L08074A3A:
	ldrb r0, [r2]                        @ 08074A3A
	subs r1, r0, #1                      @ 08074A3C
.L08074A3E:
	lsls r0, r1, #2                      @ 08074A3E
	ldr r2, .Lp08074A54                  @ 08074A40
	adds r1, r3, r2                      @ 08074A42
	adds r1, r1, r0                      @ 08074A44
	ldr r0, [r1]                         @ 08074A46
	cmp r0, #1                           @ 08074A48
	bne .L08074A50                       @ 08074A4A
	movs r0, #0                          @ 08074A4C
	str r0, [r1]                         @ 08074A4E
.L08074A50:
	bx lr                                @ 08074A50
	.align 2, 0
.Lp08074A54:	.word PL_voiceOwner

@ ============================================================================
@ void fxNone(MusChannel *c, s16 *mix, int n)             effects without tick work (and 8, 9, B-F ...)
@   mix
@ ============================================================================
	thumb_func_start fxNone
fxNone: @ 0x08074A58
	push {r4, r5, r6, r7, lr}            @ 08074A58
	mov r7, r8                           @ 08074A5A
	push {r7}                            @ 08074A5C
	adds r3, r0, #0                      @ 08074A5E
	adds r7, r1, #0                      @ 08074A60
	adds r5, r3, #0                      @ 08074A62
	adds r5, #0x2d                       @ 08074A64
	movs r0, #0                          @ 08074A66
	ldrsb r0, [r5, r0]                   @ 08074A68
	mov r8, r0                           @ 08074A6A
	ldr r0, .Lp08074AAC                  @ 08074A6C
	ldr r0, [r0]                         @ 08074A6E
	ldrb r1, [r0, #1]                    @ 08074A70
	movs r0, #0x10                       @ 08074A72
	ands r0, r1                          @ 08074A74
	cmp r0, #0                           @ 08074A76
	bne .L08074A7E                       @ 08074A78
	movs r0, #0x20                       @ 08074A7A
	strb r0, [r5]                        @ 08074A7C
.L08074A7E:
	ldr r0, .Lp08074AB0                  @ 08074A7E
	str r3, [r0]                         @ 08074A80
	ldr r4, .Lp08074AB4                  @ 08074A82
	movs r6, #0                          @ 08074A84
	ldr r0, .Lp08074AB8                  @ 08074A86
	ldr r0, [r0]                         @ 08074A88
	cmp r0, #0                           @ 08074A8A
	bne .L08074A90                       @ 08074A8C
	movs r6, #1                          @ 08074A8E
.L08074A90:
	ldr r4, [r4]                         @ 08074A90
	adds r0, r3, #0                      @ 08074A92
	adds r1, r7, #0                      @ 08074A94
	adds r3, r6, #0                      @ 08074A96
	bl _call_via_r4                      @ 08074A98
	mov r0, r8                           @ 08074A9C
	strb r0, [r5]                        @ 08074A9E
	pop {r3}                             @ 08074AA0
	mov r8, r3                           @ 08074AA2
	pop {r4, r5, r6, r7}                 @ 08074AA4
	pop {r0}                             @ 08074AA6
	bx r0                                @ 08074AA8
	.align 2, 0
.Lp08074AAC:	.word gSnd
.Lp08074AB0:	.word gMusCurChannel
.Lp08074AB4:	.word gSndMixChannelFn
.Lp08074AB8:	.word gMusTickPos

@ ============================================================================
@ void fxRetrig(MusChannel *c, s16 *mix, int n)            effect 0x22 = E9x (memory slot 6)
@   x = c->param ? c->param : c->fxMem[6];
@   if (gMusTick % (x + 1) == x) c->pos = 0;          // every x+1 ticks (FT2: every x ticks)
@   mix
@ ============================================================================
	thumb_func_start fxRetrig
fxRetrig: @ 0x08074ABC
	push {r4, r5, r6, r7, lr}            @ 08074ABC
	mov r7, sb                           @ 08074ABE
	mov r6, r8                           @ 08074AC0
	push {r6, r7}                        @ 08074AC2
	adds r5, r0, #0                      @ 08074AC4
	mov r8, r1                           @ 08074AC6
	mov sb, r2                           @ 08074AC8
	ldrb r4, [r5, #0x1a]                 @ 08074ACA
	cmp r4, #0                           @ 08074ACC
	bne .L08074AD4                       @ 08074ACE
	adds r0, #0x3a                       @ 08074AD0
	ldrb r4, [r0]                        @ 08074AD2
.L08074AD4:
	ldr r0, .Lp08074B2C                  @ 08074AD4
	adds r1, r4, #1                      @ 08074AD6
	ldr r0, [r0]                         @ 08074AD8
	bl __modsi3                          @ 08074ADA
	cmp r0, r4                           @ 08074ADE
	bne .L08074AE6                       @ 08074AE0
	movs r0, #0                          @ 08074AE2
	str r0, [r5, #0x20]                  @ 08074AE4
.L08074AE6:
	adds r6, r5, #0                      @ 08074AE6
	adds r6, #0x2d                       @ 08074AE8
	movs r7, #0                          @ 08074AEA
	ldrsb r7, [r6, r7]                   @ 08074AEC
	ldr r0, .Lp08074B30                  @ 08074AEE
	ldr r0, [r0]                         @ 08074AF0
	ldrb r1, [r0, #1]                    @ 08074AF2
	movs r0, #0x10                       @ 08074AF4
	ands r0, r1                          @ 08074AF6
	cmp r0, #0                           @ 08074AF8
	bne .L08074B00                       @ 08074AFA
	movs r0, #0x20                       @ 08074AFC
	strb r0, [r6]                        @ 08074AFE
.L08074B00:
	ldr r0, .Lp08074B34                  @ 08074B00
	str r5, [r0]                         @ 08074B02
	ldr r4, .Lp08074B38                  @ 08074B04
	movs r3, #0                          @ 08074B06
	ldr r0, .Lp08074B3C                  @ 08074B08
	ldr r0, [r0]                         @ 08074B0A
	cmp r0, #0                           @ 08074B0C
	bne .L08074B12                       @ 08074B0E
	movs r3, #1                          @ 08074B10
.L08074B12:
	ldr r4, [r4]                         @ 08074B12
	adds r0, r5, #0                      @ 08074B14
	mov r1, r8                           @ 08074B16
	mov r2, sb                           @ 08074B18
	bl _call_via_r4                      @ 08074B1A
	strb r7, [r6]                        @ 08074B1E
	pop {r3, r4}                         @ 08074B20
	mov r8, r3                           @ 08074B22
	mov sb, r4                           @ 08074B24
	pop {r4, r5, r6, r7}                 @ 08074B26
	pop {r0}                             @ 08074B28
	bx r0                                @ 08074B2A
.Lp08074B2C:	.word gMusTick
.Lp08074B30:	.word gSnd
.Lp08074B34:	.word gMusCurChannel
.Lp08074B38:	.word gSndMixChannelFn
.Lp08074B3C:	.word gMusTickPos

@ ============================================================================
@ void fxNoteCut(MusChannel *c, s16 *mix, int n)           effect 0x25 = ECx (memory slot 7)
@   x = c->param ? c->param : c->fxMem[7];
@   if (gMusTick == x) c->vol = c->baseVol = 0;
@   mix
@ ============================================================================
	thumb_func_start fxNoteCut
fxNoteCut: @ 0x08074B40
	push {r4, r5, r6, r7, lr}            @ 08074B40
	mov ip, r0                           @ 08074B42
	adds r7, r1, #0                      @ 08074B44
	ldrb r1, [r0, #0x1a]                 @ 08074B46
	cmp r1, #0                           @ 08074B48
	bne .L08074B50                       @ 08074B4A
	adds r0, #0x3b                       @ 08074B4C
	ldrb r1, [r0]                        @ 08074B4E
.L08074B50:
	ldr r0, .Lp08074BA4                  @ 08074B50
	ldr r0, [r0]                         @ 08074B52
	cmp r0, r1                           @ 08074B54
	bne .L08074B64                       @ 08074B56
	mov r0, ip                           @ 08074B58
	adds r0, #0x2c                       @ 08074B5A
	movs r1, #0                          @ 08074B5C
	strb r1, [r0]                        @ 08074B5E
	subs r0, #8                          @ 08074B60
	strb r1, [r0]                        @ 08074B62
.L08074B64:
	mov r5, ip                           @ 08074B64
	adds r5, #0x2d                       @ 08074B66
	movs r6, #0                          @ 08074B68
	ldrsb r6, [r5, r6]                   @ 08074B6A
	ldr r0, .Lp08074BA8                  @ 08074B6C
	ldr r0, [r0]                         @ 08074B6E
	ldrb r1, [r0, #1]                    @ 08074B70
	movs r0, #0x10                       @ 08074B72
	ands r0, r1                          @ 08074B74
	cmp r0, #0                           @ 08074B76
	bne .L08074B7E                       @ 08074B78
	movs r0, #0x20                       @ 08074B7A
	strb r0, [r5]                        @ 08074B7C
.L08074B7E:
	ldr r0, .Lp08074BAC                  @ 08074B7E
	mov r1, ip                           @ 08074B80
	str r1, [r0]                         @ 08074B82
	ldr r4, .Lp08074BB0                  @ 08074B84
	movs r3, #0                          @ 08074B86
	ldr r0, .Lp08074BB4                  @ 08074B88
	ldr r0, [r0]                         @ 08074B8A
	cmp r0, #0                           @ 08074B8C
	bne .L08074B92                       @ 08074B8E
	movs r3, #1                          @ 08074B90
.L08074B92:
	ldr r4, [r4]                         @ 08074B92
	mov r0, ip                           @ 08074B94
	adds r1, r7, #0                      @ 08074B96
	bl _call_via_r4                      @ 08074B98
	strb r6, [r5]                        @ 08074B9C
	pop {r4, r5, r6, r7}                 @ 08074B9E
	pop {r0}                             @ 08074BA0
	bx r0                                @ 08074BA2
.Lp08074BA4:	.word gMusTick
.Lp08074BA8:	.word gSnd
.Lp08074BAC:	.word gMusCurChannel
.Lp08074BB0:	.word gSndMixChannelFn
.Lp08074BB4:	.word gMusTickPos

@ ============================================================================
@ void fxNoteDelay(MusChannel *c, s16 *mix, int n)         effect 0x26 = EDx (memory slot 4)
@   x = c->param ? c->param : c->fxMem[4];
@   if (gMusTick >= x) mix;
@   (The note was already started at the row; the channel is just not mixed, so the previous note is
@    silenced too.)
@ ============================================================================
	thumb_func_start fxNoteDelay
fxNoteDelay: @ 0x08074BB8
	push {r4, r5, r6, r7, lr}            @ 08074BB8
	adds r3, r0, #0                      @ 08074BBA
	mov ip, r1                           @ 08074BBC
	ldrb r1, [r3, #0x1a]                 @ 08074BBE
	cmp r1, #0                           @ 08074BC0
	bne .L08074BC8                       @ 08074BC2
	adds r0, #0x38                       @ 08074BC4
	ldrb r1, [r0]                        @ 08074BC6
.L08074BC8:
	ldr r0, .Lp08074C10                  @ 08074BC8
	ldr r0, [r0]                         @ 08074BCA
	cmp r0, r1                           @ 08074BCC
	blt .L08074C0A                       @ 08074BCE
	adds r5, r3, #0                      @ 08074BD0
	adds r5, #0x2d                       @ 08074BD2
	movs r7, #0                          @ 08074BD4
	ldrsb r7, [r5, r7]                   @ 08074BD6
	ldr r0, .Lp08074C14                  @ 08074BD8
	ldr r0, [r0]                         @ 08074BDA
	ldrb r1, [r0, #1]                    @ 08074BDC
	movs r0, #0x10                       @ 08074BDE
	ands r0, r1                          @ 08074BE0
	cmp r0, #0                           @ 08074BE2
	bne .L08074BEA                       @ 08074BE4
	movs r0, #0x20                       @ 08074BE6
	strb r0, [r5]                        @ 08074BE8
.L08074BEA:
	ldr r0, .Lp08074C18                  @ 08074BEA
	str r3, [r0]                         @ 08074BEC
	ldr r4, .Lp08074C1C                  @ 08074BEE
	movs r6, #0                          @ 08074BF0
	ldr r0, .Lp08074C20                  @ 08074BF2
	ldr r0, [r0]                         @ 08074BF4
	cmp r0, #0                           @ 08074BF6
	bne .L08074BFC                       @ 08074BF8
	movs r6, #1                          @ 08074BFA
.L08074BFC:
	ldr r4, [r4]                         @ 08074BFC
	adds r0, r3, #0                      @ 08074BFE
	mov r1, ip                           @ 08074C00
	adds r3, r6, #0                      @ 08074C02
	bl _call_via_r4                      @ 08074C04
	strb r7, [r5]                        @ 08074C08
.L08074C0A:
	pop {r4, r5, r6, r7}                 @ 08074C0A
	pop {r0}                             @ 08074C0C
	bx r0                                @ 08074C0E
.Lp08074C10:	.word gMusTick
.Lp08074C14:	.word gSnd
.Lp08074C18:	.word gMusCurChannel
.Lp08074C1C:	.word gSndMixChannelFn
.Lp08074C20:	.word gMusTickPos

@ ============================================================================
@ void psgInit(void)                                       [sndInit]
@   SOUNDCNT_L = 0xCC00;           // PSG 3 and 4 on both sides, master PSG volume 0 (lowest)
@   SOUNDCNT_H |= 2;               // PSG at 100 %
@   for (i = 0; i < 4; i++) *psgRegTab[i].reg1 = *psgRegTab[i].reg2 = 0;
@   gPsgSeq.state = 0; gPsgSeq.data = 0; gPsgSeq.pos = 0; gPsgSeq.wait = 0;
@   TM0CNT = 0x00C1FC00;           // 16 777 216 / 64 / 1024 = 256 Hz, IRQ
@   REG_IE |= 8;                   // Timer 0 -> psgTimerIrq (IRQ table entry 4)
@ The sequencer is never started (psgPlay is unused), so this IRQ runs 256 times a second for nothing.
@ ============================================================================
	thumb_func_start psgInit
psgInit: @ 0x08074C24
	push {r4, lr}                        @ 08074C24
	ldr r2, .Lp08074C84                  @ 08074C26
	ldrh r0, [r2]                        @ 08074C28
	movs r3, #0xcc                       @ 08074C2A
	lsls r3, r3, #8                      @ 08074C2C
	adds r1, r3, #0                      @ 08074C2E
	orrs r0, r1                          @ 08074C30
	strh r0, [r2]                        @ 08074C32
	ldrh r1, [r2]                        @ 08074C34
	movs r0, #0xff                       @ 08074C36
	lsls r0, r0, #8                      @ 08074C38
	ands r0, r1                          @ 08074C3A
	strh r0, [r2]                        @ 08074C3C
	adds r2, #2                          @ 08074C3E
	ldrh r0, [r2]                        @ 08074C40
	movs r1, #2                          @ 08074C42
	orrs r0, r1                          @ 08074C44
	strh r0, [r2]                        @ 08074C46
	ldr r4, .Lp08074C88                  @ 08074C48
	movs r3, #0                          @ 08074C4A
	ldr r1, .Lp08074C8C                  @ 08074C4C
	movs r2, #3                          @ 08074C4E
.L08074C50:
	ldr r0, [r1]                         @ 08074C50
	strh r3, [r0]                        @ 08074C52
	ldr r0, [r1, #4]                     @ 08074C54
	strh r3, [r0]                        @ 08074C56
	adds r1, #0xc                        @ 08074C58
	subs r2, #1                          @ 08074C5A
	cmp r2, #0                           @ 08074C5C
	bge .L08074C50                       @ 08074C5E
	movs r0, #0                          @ 08074C60
	ldrb r1, [r4]                        @ 08074C62
	strb r0, [r4]                        @ 08074C64
	str r0, [r4, #0x3c]                  @ 08074C66
	str r0, [r4, #0x34]                  @ 08074C68
	str r0, [r4, #0x38]                  @ 08074C6A
	ldr r1, .Lp08074C90                  @ 08074C6C
	ldr r0, .Lp08074C94                  @ 08074C6E
	str r0, [r1]                         @ 08074C70
	ldr r2, .Lp08074C98                  @ 08074C72
	ldrh r0, [r2]                        @ 08074C74
	movs r1, #8                          @ 08074C76
	orrs r0, r1                          @ 08074C78
	strh r0, [r2]                        @ 08074C7A
	pop {r4}                             @ 08074C7C
	pop {r0}                             @ 08074C7E
	bx r0                                @ 08074C80
	.align 2, 0
.Lp08074C84:	.word REG_SOUNDCNT_L
.Lp08074C88:	.word gPsgSeq
.Lp08074C8C:	.word psgRegTab
.Lp08074C90:	.word REG_TM0CNT
.Lp08074C94:	.word 0x00C1FC00
.Lp08074C98:	.word REG_IE

@ ============================================================================
@ void psgTimerIrq(void)                                   [Timer 0 IRQ, 256 Hz]
@ PsgSeq (gPsgSeq): u8 state (0 off, 1 paused, 2 playing), u8 busy, u16 soundcntL,
@                   {s32 value, s32 speed, s32 target} slide[3], u32 pos, u32 wait, PsgData *data
@ PsgData: u8 wave[32 nibbles], ... u16 freq[3] at +0x20, u16 count at +0x26,
@          events at +0x28: {u16 delay, u8 channel, u8 type, u16 a, u16 b}
@   if (state != 2 || busy || pos >= data->count) return;
@   busy = 1;
@   for (j = 0; j < 3; j++) {                     // frequency slides for PSG 1, 2, 3
@       if (!slide[j].speed) slide[j].value = slide[j].target;
@       else { slide[j].value += speed; if (reached target) { value = target; speed = 0; } }
@       *psgRegTab[j].reg2 = *psgRegTab[j].reg2 & psgRegTab[j].mask | slide[j].value >> 9;
@   }
@   if (wait) wait--;
@   else for (e = &data->events[pos]; e < end; e++) {
@       if (e != first && e->delay) break;
@       if (e->type == 0) { *psgRegTab[e->channel].reg1 = e->a;
@                           *psgRegTab[e->channel].reg2 = slide[e->channel].value >> 9 | e->b; }
@       else if (e->type == 1) { slide[e->channel].target = (e->a & 0x7FF) << 9;
@                                slide[e->channel].speed = (s32)(e->a | e->b << 16) >> 11; }
@   }
@   if (end reached) state = 0; else { pos = e - data->events; wait = e->delay; }
@   busy = 0;
@ ============================================================================
	thumb_func_start psgTimerIrq
psgTimerIrq: @ 0x08074C9C
	push {r4, r5, r6, r7, lr}            @ 08074C9C
	mov r7, sb                           @ 08074C9E
	mov r6, r8                           @ 08074CA0
	push {r6, r7}                        @ 08074CA2
	ldr r0, .Lp08074CEC                  @ 08074CA4
	ldrb r1, [r0]                        @ 08074CA6
	adds r5, r0, #0                      @ 08074CA8
	cmp r1, #2                           @ 08074CAA
	beq .L08074CB0                       @ 08074CAC
	b .L08074DE6                         @ 08074CAE
.L08074CB0:
	ldrb r0, [r5, #1]                    @ 08074CB0
	cmp r0, #0                           @ 08074CB2
	beq .L08074CB8                       @ 08074CB4
	b .L08074DE6                         @ 08074CB6
.L08074CB8:
	ldr r1, [r5, #0x3c]                  @ 08074CB8
	ldr r0, [r5, #0x34]                  @ 08074CBA
	ldrh r1, [r1, #0x26]                 @ 08074CBC
	cmp r0, r1                           @ 08074CBE
	blo .L08074CC4                       @ 08074CC0
	b .L08074DE6                         @ 08074CC2
.L08074CC4:
	ldrb r0, [r5, #1]                    @ 08074CC4
	movs r0, #1                          @ 08074CC6
	strb r0, [r5, #1]                    @ 08074CC8
	adds r0, r5, #4                      @ 08074CCA
	mov sb, r0                           @ 08074CCC
	ldr r1, .Lp08074CF0                  @ 08074CCE
	mov r8, r1                           @ 08074CD0
	movs r0, #0                          @ 08074CD2
	mov ip, r0                           @ 08074CD4
	movs r6, #0                          @ 08074CD6
	movs r7, #2                          @ 08074CD8
.L08074CDA:
	mov r1, sb                           @ 08074CDA
	adds r4, r6, r1                      @ 08074CDC
	ldr r1, [r4, #4]                     @ 08074CDE
	cmp r1, #0                           @ 08074CE0
	bne .L08074CF4                       @ 08074CE2
	ldr r0, [r4, #8]                     @ 08074CE4
	str r0, [r4]                         @ 08074CE6
	b .L08074D18                         @ 08074CE8
	.align 2, 0
.Lp08074CEC:	.word gPsgSeq
.Lp08074CF0:	.word psgRegTab
.L08074CF4:
	cmp r1, #0                           @ 08074CF4
	ble .L08074D06                       @ 08074CF6
	ldr r0, [r4]                         @ 08074CF8
	adds r0, r0, r1                      @ 08074CFA
	str r0, [r4]                         @ 08074CFC
	ldr r1, [r4, #8]                     @ 08074CFE
	cmp r0, r1                           @ 08074D00
	blt .L08074D18                       @ 08074D02
	b .L08074D12                         @ 08074D04
.L08074D06:
	ldr r0, [r4]                         @ 08074D06
	adds r0, r0, r1                      @ 08074D08
	str r0, [r4]                         @ 08074D0A
	ldr r1, [r4, #8]                     @ 08074D0C
	cmp r0, r1                           @ 08074D0E
	bgt .L08074D18                       @ 08074D10
.L08074D12:
	mov r0, ip                           @ 08074D12
	str r0, [r4, #4]                     @ 08074D14
	str r1, [r4]                         @ 08074D16
.L08074D18:
	mov r1, r8                           @ 08074D18
	adds r0, r6, r1                      @ 08074D1A
	ldr r3, [r0, #4]                     @ 08074D1C
	ldrh r2, [r3]                        @ 08074D1E
	ldrh r1, [r0, #8]                    @ 08074D20
	ands r1, r2                          @ 08074D22
	ldr r0, [r4]                         @ 08074D24
	asrs r0, r0, #9                      @ 08074D26
	orrs r1, r0                          @ 08074D28
	strh r1, [r3]                        @ 08074D2A
	adds r6, #0xc                        @ 08074D2C
	subs r7, #1                          @ 08074D2E
	cmp r7, #0                           @ 08074D30
	bge .L08074CDA                       @ 08074D32
	ldr r0, [r5, #0x38]                  @ 08074D34
	cmp r0, #0                           @ 08074D36
	beq .L08074D3E                       @ 08074D38
	subs r0, #1                          @ 08074D3A
	b .L08074DDE                         @ 08074D3C
.L08074D3E:
	ldr r0, [r5, #0x34]                  @ 08074D3E
	lsls r0, r0, #3                      @ 08074D40
	adds r0, #0x28                       @ 08074D42
	ldr r1, [r5, #0x3c]                  @ 08074D44
	adds r3, r1, r0                      @ 08074D46
	ldrh r0, [r1, #0x26]                 @ 08074D48
	lsls r0, r0, #3                      @ 08074D4A
	adds r0, #0x28                       @ 08074D4C
	adds r4, r1, r0                      @ 08074D4E
	mov sb, r5                           @ 08074D50
	adds r7, r5, #4                      @ 08074D52
	adds r6, r5, #0                      @ 08074D54
	adds r6, #8                          @ 08074D56
	b .L08074D60                         @ 08074D58
.L08074D5A:
	ldrh r0, [r3]                        @ 08074D5A
	cmp r0, #0                           @ 08074D5C
	bne .L08074DC2                       @ 08074D5E
.L08074D60:
	ldrb r0, [r3, #3]                    @ 08074D60
	cmp r0, #0                           @ 08074D62
	bne .L08074D92                       @ 08074D64
	ldrb r1, [r3, #2]                    @ 08074D66
	lsls r0, r1, #1                      @ 08074D68
	adds r0, r0, r1                      @ 08074D6A
	lsls r0, r0, #2                      @ 08074D6C
	add r0, r8                           @ 08074D6E
	ldr r2, [r0, #4]                     @ 08074D70
	ldrh r1, [r2]                        @ 08074D72
	ldr r1, [r0]                         @ 08074D74
	ldrh r0, [r3, #4]                    @ 08074D76
	strh r0, [r1]                        @ 08074D78
	ldrb r1, [r3, #2]                    @ 08074D7A
	lsls r0, r1, #1                      @ 08074D7C
	adds r0, r0, r1                      @ 08074D7E
	lsls r0, r0, #2                      @ 08074D80
	adds r0, r0, r7                      @ 08074D82
	ldr r0, [r0]                         @ 08074D84
	lsls r0, r0, #7                      @ 08074D86
	lsrs r0, r0, #0x10                   @ 08074D88
	ldrh r1, [r3, #6]                    @ 08074D8A
	orrs r0, r1                          @ 08074D8C
	strh r0, [r2]                        @ 08074D8E
	b .L08074DBC                         @ 08074D90
.L08074D92:
	cmp r0, #1                           @ 08074D92
	bne .L08074DBC                       @ 08074D94
	ldrb r0, [r3, #2]                    @ 08074D96
	lsls r1, r0, #1                      @ 08074D98
	adds r1, r1, r0                      @ 08074D9A
	lsls r1, r1, #2                      @ 08074D9C
	mov r0, sb                           @ 08074D9E
	adds r0, #0xc                        @ 08074DA0
	adds r1, r1, r0                      @ 08074DA2
	ldrh r0, [r3, #4]                    @ 08074DA4
	lsls r0, r0, #0x15                   @ 08074DA6
	lsrs r0, r0, #0xc                    @ 08074DA8
	str r0, [r1]                         @ 08074DAA
	ldrb r0, [r3, #2]                    @ 08074DAC
	lsls r1, r0, #1                      @ 08074DAE
	adds r1, r1, r0                      @ 08074DB0
	lsls r1, r1, #2                      @ 08074DB2
	adds r1, r1, r6                      @ 08074DB4
	ldr r0, [r3, #4]                     @ 08074DB6
	asrs r0, r0, #0xb                    @ 08074DB8
	str r0, [r1]                         @ 08074DBA
.L08074DBC:
	adds r3, #8                          @ 08074DBC
	cmp r3, r4                           @ 08074DBE
	blo .L08074D5A                       @ 08074DC0
.L08074DC2:
	cmp r3, r4                           @ 08074DC2
	blo .L08074DD0                       @ 08074DC4
	ldrb r0, [r5]                        @ 08074DC6
	movs r0, #0                          @ 08074DC8
	strb r0, [r5]                        @ 08074DCA
	ldrb r1, [r5, #1]                    @ 08074DCC
	b .L08074DE4                         @ 08074DCE
.L08074DD0:
	adds r0, r3, #0                      @ 08074DD0
	subs r0, #0x28                       @ 08074DD2
	ldr r1, [r5, #0x3c]                  @ 08074DD4
	subs r0, r0, r1                      @ 08074DD6
	asrs r0, r0, #3                      @ 08074DD8
	str r0, [r5, #0x34]                  @ 08074DDA
	ldrh r0, [r3]                        @ 08074DDC
.L08074DDE:
	str r0, [r5, #0x38]                  @ 08074DDE
	ldrb r0, [r5, #1]                    @ 08074DE0
	movs r0, #0                          @ 08074DE2
.L08074DE4:
	strb r0, [r5, #1]                    @ 08074DE4
.L08074DE6:
	pop {r3, r4}                         @ 08074DE6
	mov r8, r3                           @ 08074DE8
	mov sb, r4                           @ 08074DEA
	pop {r4, r5, r6, r7}                 @ 08074DEC
	pop {r0}                             @ 08074DEE
	bx r0                                @ 08074DF0
	.align 2, 0

@ ============================================================================
@ void psgPlay(PsgData *d, int vol, int pan)               [unused]
@   psgStop(); pos = 0; wait = d->events[0].delay; data = d;
@   vol = min(vol >> 4, 7); split vol into left/right by pan (0..127); soundcntL = right << 4 | left;
@   SOUND3CNT_L = 0x60; copy d->wave (16 bytes) into both wave RAM banks; SOUND3CNT_L = 0xA0;
@   for (j = 0; j < 3; j++) slide[j].value = slide[j].target = d->freq[j] << 9;
@   SOUNDCNT_L = SOUNDCNT_L & 0xFF00 | soundcntL; state = 2;
@ ============================================================================
	thumb_func_start psgPlay
psgPlay: @ 0x08074DF4
	push {r4, r5, r6, r7, lr}            @ 08074DF4
	mov r7, r8                           @ 08074DF6
	push {r7}                            @ 08074DF8
	adds r6, r0, #0                      @ 08074DFA
	adds r4, r1, #0                      @ 08074DFC
	adds r5, r2, #0                      @ 08074DFE
	bl psgStop                           @ 08074E00
	ldr r1, .Lp08074E28                  @ 08074E04
	movs r0, #0                          @ 08074E06
	str r0, [r1, #0x34]                  @ 08074E08
	ldrh r0, [r6, #0x28]                 @ 08074E0A
	str r0, [r1, #0x38]                  @ 08074E0C
	str r6, [r1, #0x3c]                  @ 08074E0E
	asrs r4, r4, #4                      @ 08074E10
	cmp r4, #7                           @ 08074E12
	ble .L08074E18                       @ 08074E14
	movs r4, #7                          @ 08074E16
.L08074E18:
	adds r1, r4, #0                      @ 08074E18
	cmp r5, #0x3f                        @ 08074E1A
	bgt .L08074E2C                       @ 08074E1C
	adds r0, r1, #0                      @ 08074E1E
	muls r0, r5, r0                      @ 08074E20
	asrs r1, r0, #6                      @ 08074E22
	b .L08074E38                         @ 08074E24
	.align 2, 0
.Lp08074E28:	.word gPsgSeq
.L08074E2C:
	cmp r5, #0x40                        @ 08074E2C
	ble .L08074E38                       @ 08074E2E
	movs r0, #0x80                       @ 08074E30
	subs r0, r0, r5                      @ 08074E32
	muls r0, r1, r0                      @ 08074E34
	asrs r4, r0, #6                      @ 08074E36
.L08074E38:
	ldr r2, .Lp08074EC0                  @ 08074E38
	lsls r0, r4, #4                      @ 08074E3A
	orrs r0, r1                          @ 08074E3C
	strh r0, [r2, #2]                    @ 08074E3E
	ldr r1, .Lp08074EC4                  @ 08074E40
	movs r0, #0x60                       @ 08074E42
	strh r0, [r1]                        @ 08074E44
	movs r3, #0                          @ 08074E46
	adds r7, r2, #0                      @ 08074E48
	movs r0, #0x20                       @ 08074E4A
	adds r0, r0, r6                      @ 08074E4C
	mov ip, r0                           @ 08074E4E
	mov r8, r1                           @ 08074E50
	movs r5, #0x20                       @ 08074E52
.L08074E54:
	ldr r1, .Lp08074EC8                  @ 08074E54
	adds r4, r3, #0                      @ 08074E56
	adds r4, #8                          @ 08074E58
	cmp r3, r4                           @ 08074E5A
	bge .L08074E74                       @ 08074E5C
	lsls r0, r3, #1                      @ 08074E5E
	adds r2, r0, r6                      @ 08074E60
	subs r3, r4, r3                      @ 08074E62
.L08074E64:
	ldrh r0, [r2]                        @ 08074E64
	strh r0, [r1]                        @ 08074E66
	adds r1, #2                          @ 08074E68
	adds r2, #2                          @ 08074E6A
	subs r3, #1                          @ 08074E6C
	cmp r3, #0                           @ 08074E6E
	bne .L08074E64                       @ 08074E70
	adds r3, r4, #0                      @ 08074E72
.L08074E74:
	mov r0, r8                           @ 08074E74
	strh r5, [r0]                        @ 08074E76
	cmp r3, #0xf                         @ 08074E78
	ble .L08074E54                       @ 08074E7A
	ldr r0, .Lp08074EC4                  @ 08074E7C
	movs r1, #0xa0                       @ 08074E7E
	strh r1, [r0]                        @ 08074E80
	ldr r0, .Lp08074EC0                  @ 08074E82
	mov r2, ip                           @ 08074E84
	adds r1, r0, #4                      @ 08074E86
	movs r3, #2                          @ 08074E88
.L08074E8A:
	ldrh r0, [r2]                        @ 08074E8A
	lsls r0, r0, #9                      @ 08074E8C
	str r0, [r1]                         @ 08074E8E
	str r0, [r1, #8]                     @ 08074E90
	adds r2, #2                          @ 08074E92
	adds r1, #0xc                        @ 08074E94
	subs r3, #1                          @ 08074E96
	cmp r3, #0                           @ 08074E98
	bge .L08074E8A                       @ 08074E9A
	ldr r2, .Lp08074ECC                  @ 08074E9C
	ldrh r1, [r2]                        @ 08074E9E
	movs r0, #0xff                       @ 08074EA0
	lsls r0, r0, #8                      @ 08074EA2
	ands r0, r1                          @ 08074EA4
	strh r0, [r2]                        @ 08074EA6
	ldrh r0, [r2]                        @ 08074EA8
	ldrh r1, [r7, #2]                    @ 08074EAA
	orrs r0, r1                          @ 08074EAC
	strh r0, [r2]                        @ 08074EAE
	ldrb r0, [r7]                        @ 08074EB0
	movs r0, #2                          @ 08074EB2
	strb r0, [r7]                        @ 08074EB4
	pop {r3}                             @ 08074EB6
	mov r8, r3                           @ 08074EB8
	pop {r4, r5, r6, r7}                 @ 08074EBA
	pop {r0}                             @ 08074EBC
	bx r0                                @ 08074EBE
.Lp08074EC0:	.word gPsgSeq
.Lp08074EC4:	.word REG_SOUND3CNT_L
.Lp08074EC8:	.word REG_WAVE_RAM
.Lp08074ECC:	.word REG_SOUNDCNT_L

@ ============================================================================
@ void psgPause(void)   [unused]  if (state == 2) { state = 1; SOUNDCNT_L &= 0xFF00; }
@ ============================================================================
	thumb_func_start psgPause
psgPause: @ 0x08074ED0
	ldr r1, .Lp08074EEC                  @ 08074ED0
	ldrb r0, [r1]                        @ 08074ED2
	cmp r0, #2                           @ 08074ED4
	bne .L08074EEA                       @ 08074ED6
	ldrb r0, [r1]                        @ 08074ED8
	movs r0, #1                          @ 08074EDA
	strb r0, [r1]                        @ 08074EDC
	ldr r2, .Lp08074EF0                  @ 08074EDE
	ldrh r1, [r2]                        @ 08074EE0
	movs r0, #0xff                       @ 08074EE2
	lsls r0, r0, #8                      @ 08074EE4
	ands r0, r1                          @ 08074EE6
	strh r0, [r2]                        @ 08074EE8
.L08074EEA:
	bx lr                                @ 08074EEA
.Lp08074EEC:	.word gPsgSeq
.Lp08074EF0:	.word REG_SOUNDCNT_L

@ ============================================================================
@ void psgResume(void)  [unused]  if (state == 1) { state = 2; SOUNDCNT_L = SOUNDCNT_L & 0xFF00 | soundcntL; }
@ ============================================================================
	thumb_func_start psgResume
psgResume: @ 0x08074EF4
	ldr r3, .Lp08074F18                  @ 08074EF4
	ldrb r0, [r3]                        @ 08074EF6
	cmp r0, #1                           @ 08074EF8
	bne .L08074F16                       @ 08074EFA
	ldrb r0, [r3]                        @ 08074EFC
	movs r0, #2                          @ 08074EFE
	strb r0, [r3]                        @ 08074F00
	ldr r2, .Lp08074F1C                  @ 08074F02
	ldrh r1, [r2]                        @ 08074F04
	movs r0, #0xff                       @ 08074F06
	lsls r0, r0, #8                      @ 08074F08
	ands r0, r1                          @ 08074F0A
	strh r0, [r2]                        @ 08074F0C
	ldrh r0, [r2]                        @ 08074F0E
	ldrh r1, [r3, #2]                    @ 08074F10
	orrs r0, r1                          @ 08074F12
	strh r0, [r2]                        @ 08074F14
.L08074F16:
	bx lr                                @ 08074F16
.Lp08074F18:	.word gPsgSeq
.Lp08074F1C:	.word REG_SOUNDCNT_L

@ ============================================================================
@ void psgStop(void)              state = 0; SOUNDCNT_L &= 0xFF00;
@ ============================================================================
	thumb_func_start psgStop
psgStop: @ 0x08074F20
	ldr r1, .Lp08074F38                  @ 08074F20
	ldrb r0, [r1]                        @ 08074F22
	movs r0, #0                          @ 08074F24
	strb r0, [r1]                        @ 08074F26
	ldr r2, .Lp08074F3C                  @ 08074F28
	ldrh r1, [r2]                        @ 08074F2A
	movs r0, #0xff                       @ 08074F2C
	lsls r0, r0, #8                      @ 08074F2E
	ands r0, r1                          @ 08074F30
	strh r0, [r2]                        @ 08074F32
	bx lr                                @ 08074F34
	.align 2, 0
.Lp08074F38:	.word gPsgSeq
.Lp08074F3C:	.word REG_SOUNDCNT_L
