@ WarioWare, Inc. (E) sound driver: code 0x080F05B4-0x080F4988
@ Generated from the ROM and hand-annotated; every name is assigned (the ROM has no symbols).
@ Rebuilds byte-identical to the ROM (see ww.mk / romcheck.py).

	.include "ww_sound.inc"
	.syntax unified
	.section .snd_code, "ax", %progbits


@ ==================================================================================================
@  MIXER  (0x080F05B4-0x080F1560)
@  The inner loops are ARM code that mixRoutinesStereo/Mono list; mixLoadRoutines copies one list to
@  IWRAM (gMixRamCode, 0x03006910) and records each copy's address in gMixRamRoutines[]. The Thumb
@  wrappers load the registers and jump to routine k through mixCallRamRoutine(k). The ARM loops keep
@  local variables in words inside their own code (pc-relative str/ldr), so they only work from RAM.
@  Routine index:  0 reverb   1 downmix   2 direct (step 1.0)   3 interpolating   4 point   5 filter
@ ==================================================================================================

	.global mixRoutinesStereo
mixRoutinesStereo:   @ {u16 isThumb (2 = end), u16 byteSize, void *src}: ARM loops copied to IWRAM by mixCopyRoutineList
	.hword 0, mixArm_ReverbMono - mixArm_ReverbStereo          @ routine 0
	.word mixArm_ReverbStereo
	.hword 0, mixArm_DownmixMono - mixArm_DownmixStereo        @ routine 1
	.word mixArm_DownmixStereo
	.hword 0, mixVoiceDirect_veneer - mixArm_VoiceDirectStereo @ routine 2
	.word mixArm_VoiceDirectStereo
	.hword 0, mixArm_VoiceInterpMono - mixArm_VoiceInterpStereo@ routine 3
	.word mixArm_VoiceInterpStereo
	.hword 0, mixArm_VoicePointMono - mixArm_VoicePointStereo  @ routine 4
	.word mixArm_VoicePointStereo
	.hword 0, mixFilter_veneer - mixArm_Filter                 @ routine 5
	.word mixArm_Filter
	.hword 2                                    @ end of list
	.hword 0

	.global mixRoutinesMono
mixRoutinesMono:   @ {u16 isThumb (2 = end), u16 byteSize, void *src}: ARM loops copied to IWRAM by mixCopyRoutineList
	.hword 0, mixDownmix - mixArm_ReverbMono                   @ routine 0
	.word mixArm_ReverbMono
	.hword 0, mixReverbDownmix_veneer - mixArm_DownmixMono     @ routine 1
	.word mixArm_DownmixMono
	.hword 0, 0x0                                              @ routine 2 (size 0: nothing copied, alias of routine 3)
	.word mixVoiceDirect_veneer
	.hword 0, mixVoiceInterp_veneer - mixArm_VoiceInterpMono   @ routine 3
	.word mixArm_VoiceInterpMono
	.hword 0, mixVoicePoint_veneer - mixArm_VoicePointMono     @ routine 4
	.word mixArm_VoicePointMono
	.hword 2                                    @ end of list

@ --------------------------------------------------------------------------------------------------
@ mixLoadRoutines  (080F0612, Thumb)
@   void mixLoadRoutines(int mode)          // mode 0 = stereo, else mono (only mode 0 is used)
@   {   mixCopyRoutineList(mode == 0 ? mixRoutinesStereo : mixRoutinesMono); }
@   Note: the Thumb code starts at +2; the halfword before it is the mono list's end marker.
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixLoadRoutines
mixLoadRoutines:
	push {lr}
	cmp r0, #0
	bne .L_080F061C
	ldr r0, .L_080F062C                        @ = 0x080F05B4
	b .L_080F061E
.L_080F061C:
	ldr r0, .L_080F0630                        @ = 0x080F05E8
.L_080F061E:
	bl mixLoadRoutines_veneer
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ mixLoadRoutines_veneer  (080F0626, Thumb)
@   Veneer: bx to mixCopyRoutineList (Thumb).
@ --------------------------------------------------------------------------------------------------
	.global mixLoadRoutines_veneer
mixLoadRoutines_veneer:
	ldr r1, .L_080F0634                        @ = mixCopyRoutineList
	adds r1, #1
	bx r1
.L_080F062C:
	.word 0x080F05B4
.L_080F0630:
	.word 0x080F05E8
.L_080F0634:
	.word mixCopyRoutineList

@ --------------------------------------------------------------------------------------------------
@ mixCopyRoutineList  (080F0638, Thumb)
@   void mixCopyRoutineList(const RoutineEntry *e)   // e = {u16 isThumb, u16 size, void *src}
@   {
@       u32 *slot = gMixRamRoutines;  u32 *dst = gMixRamCode;
@       for (; e->isThumb != 2; e++) mixCopyRoutine(e);   // *slot++ = dst + isThumb; copy (size+3)/4 words
@   }
@   The mono list has only 5 entries (no filter) and a size-0 entry that makes routine 2 an alias of routine 3.
@ --------------------------------------------------------------------------------------------------
	.global mixCopyRoutineList
mixCopyRoutineList:
	push {r4, r5, r6, r7, lr}
	adds r1, r0, #0
	ldr r4, .L_080F0680                        @ = gMixRamRoutines
	ldr r6, .L_080F0684                        @ = gMixRamCode
.L_080F0640:
	ldrh r3, [r1]
	cmp r3, #2
	beq .L_080F0652
	ldrh r7, [r1, #2]
	ldr r5, [r1, #4]
	bl mixCopyRoutine
	adds r1, #8
	b .L_080F0640
.L_080F0652:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ mixCopyRoutine  (080F0658, Thumb)
@   inline part of mixCopyRoutineList: *slot++ = (u32)dst + e->isThumb; copy (e->size + 3) / 4 words src -> dst.
@ --------------------------------------------------------------------------------------------------
	.global mixCopyRoutine
mixCopyRoutine:
	adds r0, r3, r6
	str r0, [r4]
	adds r4, #4
	adds r7, #3
	lsrs r7, r7, #2
	bne .L_080F0666
	bx lr
.L_080F0666:
	ldr r0, [r5]
	str r0, [r6]
	adds r5, #4
	adds r6, #4
	subs r7, #1
	bne .L_080F0666
	bx lr

@ --------------------------------------------------------------------------------------------------
@ mixCallRamRoutine  (080F0674, Thumb)
@   void mixCallRamRoutine(int index /* r0 */)   // jumps (bx) to gMixRamRoutines[index]; r1 is preserved,
@                                                // all other registers were loaded by the caller
@ --------------------------------------------------------------------------------------------------
	.global mixCallRamRoutine
mixCallRamRoutine:
	push {r1}
	lsls r0, r0, #2
	ldr r1, .L_080F0688                        @ = gMixRamRoutines
	ldr r0, [r0, r1]
	pop {r1}
	bx r0
.L_080F0680:
	.word gMixRamRoutines
.L_080F0684:
	.word gMixRamCode
.L_080F0688:
	.word gMixRamRoutines

@ --------------------------------------------------------------------------------------------------
@ mixVoiceInterp  (080F068C, Thumb)
@   int mixVoiceInterp(int n, Voice *v)       // resampling with linear interpolation (routine 3)
@   {
@       if (n == 0) return;
@       vol = v->vol + gMixVolBoost;
@       r6 = acc; r7 = v->pcm; r8 = v->end;   sb = v->gainR * vol >> 7;  sl = v->gainL * vol >> 7;
@       fp = v->pos;  ip = v->step << 10 | n;  r4 = v->loopStart - v->end;      // negative loop length or 0
@       alive = RAM routine 3;                      // mixArm_VoiceInterpStereo
@       v->flags = (v->flags & ~1) | alive;  v->pos = fp;
@   }
@ --------------------------------------------------------------------------------------------------
	.global mixVoiceInterp
mixVoiceInterp:
	orrs r0, r0
	bne .L_080F0692
	bx lr
.L_080F0692:
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	mov r4, ip
	push {r4}
	adds r5, r0, #0
	push {r1}
	ldr r6, .L_080F0A20                        @ = gMixBufPtr
	ldr r6, [r6]
	ldr r7, [r1, #4]
	ldr r0, [r1, #0x14]
	mov r8, r0
	movs r0, #3
	ldrsb r2, [r1, r0]
	movs r0, #2
	ldrsb r3, [r1, r0]
	ldrb r0, [r1, #1]
	ldr r4, .L_080F0A24                        @ = gMixVolBoost
	ldrh r4, [r4]
	adds r0, r0, r4
	muls r2, r0, r2
	asrs r2, r2, #7
	muls r3, r0, r3
	asrs r3, r3, #7
	mov sb, r2
	mov sl, r3
	ldr r0, [r1, #0xc]
	mov fp, r0
	ldr r0, [r1, #0x18]
	lsls r0, r0, #0xa
	orrs r0, r5
	mov ip, r0
	mov r0, r8
	ldr r4, [r1, #0x10]
	subs r4, r4, r0
	movs r0, #3
	bl mixVoiceInterp_veneer
	pop {r1}
	ldrb r2, [r1]
	movs r3, #1
	bics r2, r3
	orrs r2, r0
	strb r2, [r1]
	mov r0, fp
	str r0, [r1, #0xc]
	pop {r4}
	mov ip, r4
	pop {r4, r5, r6, r7}
	mov r8, r4
	mov sb, r5
	mov sl, r6
	mov fp, r7
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ mixArm_VoiceInterpStereo  (080F0708, ARM)
@   ARM, runs from IWRAM.  4 samples per pass while the end is not reached:
@       for (;;) {
@           if (pos + 4 * step >= end) goto tail;
@           repeat 4: s = pcm[pos >> 14];  s += (pcm[(pos >> 14) + 1] - s) * (pos & 0x3FC0) >> 14;
@                     acc[0] += s * sb;  acc[1] += s * sl;  acc += 2;  pos += step;
@           if (--n == 0) return 1;
@       }
@   tail: if (loopLen) { 4 samples, after each: while (pos >= end) pos += loopLen;  if (--n == 0) return 1; loop }
@         else       { mix single samples while (pos < end);  return 0;   /* voice finished */ }
@   The interpolation reads the byte after pos, i.e. pcm[end] at the loop end (not pcm[loopStart]).
@ --------------------------------------------------------------------------------------------------
	.arm
	.global mixArm_VoiceInterpStereo
mixArm_VoiceInterpStereo:
	str lr, [pc, #0x184]                       @ local variable at .L_080F0894
	str r4, [pc, #0x184]                       @ local variable at .L_080F0898
.L_080F0710:
	add r0, fp, ip, lsr #8
	cmp r0, r8
	bhs .L_080F07E4
	ldm r6, {r0, r1, r2, r3}
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r2, r4, sb, r2
	mla r3, r4, sl, r3
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1, r2, r3}
	ldm r6, {r0, r1, r2, r3}
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r2, r4, sb, r2
	mla r3, r4, sl, r3
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1, r2, r3}
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne .L_080F0710
	mov r0, #1
	ldr lr, .L_080F0894                        @ = 0x00000000
	bx lr
.L_080F07E4:
	ldr r2, .L_080F0898                        @ = 0x00000000
	cmp r2, #0
	beq .L_080F0850
	mov r3, #4
.L_080F07F4:
	ldm r6, {r0, r1}
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1}
.L_080F0824:
	cmp fp, r8
	addhs fp, fp, r2
	bhs .L_080F0824
	subs r3, r3, #1
	bne .L_080F07F4
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne .L_080F0710
	mov r0, #1
	ldr lr, .L_080F0894                        @ = 0x00000000
	bx lr
.L_080F0850:
	ldm r6, {r0, r1}
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1}
	cmp fp, r8
	blo .L_080F0850
	mov r0, #0
	ldr lr, .L_080F0894                        @ = 0x00000000
	bx lr
.L_080F0894:
	.word 0x00000000
.L_080F0898:
	.word 0x00000000

@ --------------------------------------------------------------------------------------------------
@ mixArm_VoiceInterpMono  (080F089C, ARM)
@   ARM, mono variant of mixArm_VoiceInterpStereo (one accumulator word per sample, gain sb).
@   Its looping tail adds "s * sl" to r1 and stores only r0 (harmless leftovers of the stereo version).
@ --------------------------------------------------------------------------------------------------
	.global mixArm_VoiceInterpMono
mixArm_VoiceInterpMono:
	str lr, [pc, #0x16c]                       @ local variable at .L_080F0A10
	str r4, [pc, #0x16c]                       @ local variable at .L_080F0A14
.L_080F08A4:
	add r0, fp, ip, lsr #8
	cmp r0, r8
	bhs .L_080F0960
	ldm r6, {r0, r1, r2, r3}
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	add fp, fp, ip, lsr #10
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r1, r4, sb, r1
	add fp, fp, ip, lsr #10
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r2, r4, sb, r2
	add fp, fp, ip, lsr #10
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r3, r4, sb, r3
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1, r2, r3}
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne .L_080F08A4
	mov r0, #1
	ldr lr, .L_080F0A10                        @ = 0x00000000
	bx lr
.L_080F0960:
	ldr r2, .L_080F0A14                        @ = 0x00000000
	cmp r2, #0
	beq .L_080F09CC
	mov r3, #4
.L_080F0970:
	ldr r0, [r6]
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	str r0, [r6], #4
.L_080F09A0:
	cmp fp, r8
	addhs fp, fp, r2
	bhs .L_080F09A0
	subs r3, r3, #1
	bne .L_080F0970
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne .L_080F08A4
	mov r0, #1
	ldr lr, .L_080F0A10                        @ = 0x00000000
	bx lr
.L_080F09CC:
	ldr r0, [r6]
	add lr, r7, fp, lsr #14
	ldrsb r4, [lr], #1
	ldrsb r5, [lr]
	sub r5, r5, r4
	and lr, fp, #0x3fc0
	mul r5, lr, r5
	add r4, r4, r5, asr #14
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	str r0, [r6], #4
	cmp fp, r8
	blo .L_080F09CC
	mov r0, #0
	ldr lr, .L_080F0A10                        @ = 0x00000000
	bx lr
.L_080F0A10:
	.word 0x00000000
.L_080F0A14:
	.word 0x00000000

@ --------------------------------------------------------------------------------------------------
@ mixVoiceInterp_veneer  (080F0A18, Thumb)
@   Veneer: bx to mixCallRamRoutine.
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixVoiceInterp_veneer
mixVoiceInterp_veneer:
	ldr r1, .L_080F0A28                        @ = mixCallRamRoutine
	adds r1, #1
	bx r1
	.hword 0x0000
.L_080F0A20:
	.word gMixBufPtr
.L_080F0A24:
	.word gMixVolBoost
.L_080F0A28:
	.word mixCallRamRoutine

@ --------------------------------------------------------------------------------------------------
@ mixReverb  (080F0A2C, Thumb)
@   void mixReverb(int n)                      // routine 0: acc = echo of the output written one ring ago
@   {
@       if (n == 0) return;
@       r6 = gRingBufR + gRingWritePos*4;                             // right ring at the write position
@       r7 = gRingBufL + (gRingWritePos*4 + gReverbDelay*4) % (gRingWords*4);
@       r8 = gReverbLevel >> gReverbLpShift;  r2 = gReverbHpShift;  r3 = gReverbLpShift;
@       RAM routine 0 (mixArm_ReverbStereo)
@   }
@ --------------------------------------------------------------------------------------------------
	.global mixReverb
mixReverb:
	orrs r0, r0
	bne .L_080F0A32
	bx lr
.L_080F0A32:
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	mov r4, ip
	push {r4}
	adds r4, r0, #0
	ldr r5, .L_080F0E1C                        @ = gMixBufPtr
	ldr r5, [r5]
	ldr r0, .L_080F0E20                        @ = gRingWritePos
	ldr r0, [r0]
	lsls r0, r0, #2
	ldr r6, .L_080F0E24                        @ = gRingBufR
	ldr r6, [r6]
	ldr r7, .L_080F0E28                        @ = gRingBufL
	ldr r7, [r7]
	adds r6, r6, r0
	ldr r1, .L_080F0E2C                        @ = gReverbDelay
	ldr r1, [r1]
	lsls r1, r1, #2
	adds r0, r0, r1
	ldr r1, .L_080F0E30                        @ = gRingWords
	ldr r1, [r1]
	lsls r1, r1, #2
	cmp r0, r1
	blo .L_080F0A6C
	subs r0, r0, r1
.L_080F0A6C:
	adds r7, r7, r0
	ldr r0, .L_080F0E34                        @ = gReverbLevel
	ldr r0, [r0]
	ldr r2, .L_080F0E38                        @ = gReverbHpShift
	ldr r2, [r2]
	ldr r3, .L_080F0E3C                        @ = gReverbLpShift
	ldr r3, [r3]
	lsrs r0, r3
	mov r8, r0
	ldr r0, .L_080F0E40                        @ = gRingWords
	ldr r0, [r0]
	lsls r0, r0, #2
	mov sb, r0
	ldr r1, .L_080F0E44                        @ = gRingBufR
	ldr r1, [r1]
	mov sl, r1
	ldr r1, .L_080F0E48                        @ = gRingBufL
	ldr r1, [r1]
	mov fp, r1
	eors r0, r0
	bl mixReverbDownmix_veneer
	pop {r4}
	mov ip, r4
	pop {r4, r5, r6, r7}
	mov r8, r4
	mov sb, r5
	mov sl, r6
	mov fp, r7
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ mixArm_ReverbStereo  (080F0AAC, ARM)
@   ARM:  for each of n*4 samples, for each side (state in gReverbState[4]):
@           x  = ring[...] (s8, the output from ~gRingWords*4 samples ago)
@           hp = hp - (hp >> hpShift) + x;   y = x - (hp >> hpShift);          // DC-blocking high-pass
@           lp = lp - (lp >> lpShift) + y;   acc = lp * level;                  // low-pass, gain 2^lpShift
@       The accumulator is overwritten (this is the first thing mixed in each block).
@       Ring pointers wrap at the end of the ring buffers.
@ --------------------------------------------------------------------------------------------------
	.arm
	.global mixArm_ReverbStereo
mixArm_ReverbStereo:
	str lr, [pc, #0x158]                       @ local variable at .L_080F0C0C
	str sl, [pc, #0x158]                       @ local variable at .L_080F0C10
	str fp, [pc, #0x158]                       @ local variable at .L_080F0C14
	add sl, sb, sl
	add fp, sb, fp
	mov sb, r2
	mov lr, r3
	mov r1, r4
	ldr r0, .L_080F0C18                        @ = gReverbState
	ldr r2, [r0], #4
	ldr r3, [r0], #4
	ldr ip, [r0], #4
	ldr r4, [r0]
.L_080F0AE0:
	str r1, [pc, #0x134]                       @ local variable at .L_080F0C1C
	ldrsb r0, [r6], #1
	sub r2, r2, r2, asr sb
	add r2, r0, r2
	sub r0, r0, r2, asr sb
	sub r3, r3, r3, asr lr
	add r3, r0, r3
	mul r0, r8, r3
	ldrsb r1, [r7], #1
	sub ip, ip, ip, asr sb
	add ip, r1, ip
	sub r1, r1, ip, asr sb
	sub r4, r4, r4, asr lr
	add r4, r1, r4
	mul r1, r8, r4
	stm r5!, {r0, r1}
	ldrsb r0, [r6], #1
	sub r2, r2, r2, asr sb
	add r2, r0, r2
	sub r0, r0, r2, asr sb
	sub r3, r3, r3, asr lr
	add r3, r0, r3
	mul r0, r8, r3
	ldrsb r1, [r7], #1
	sub ip, ip, ip, asr sb
	add ip, r1, ip
	sub r1, r1, ip, asr sb
	sub r4, r4, r4, asr lr
	add r4, r1, r4
	mul r1, r8, r4
	stm r5!, {r0, r1}
	ldrsb r0, [r6], #1
	sub r2, r2, r2, asr sb
	add r2, r0, r2
	sub r0, r0, r2, asr sb
	sub r3, r3, r3, asr lr
	add r3, r0, r3
	mul r0, r8, r3
	ldrsb r1, [r7], #1
	sub ip, ip, ip, asr sb
	add ip, r1, ip
	sub r1, r1, ip, asr sb
	sub r4, r4, r4, asr lr
	add r4, r1, r4
	mul r1, r8, r4
	stm r5!, {r0, r1}
	ldrsb r0, [r6], #1
	sub r2, r2, r2, asr sb
	add r2, r0, r2
	sub r0, r0, r2, asr sb
	sub r3, r3, r3, asr lr
	add r3, r0, r3
	mul r0, r8, r3
	ldrsb r1, [r7], #1
	sub ip, ip, ip, asr sb
	add ip, r1, ip
	sub r1, r1, ip, asr sb
	sub r4, r4, r4, asr lr
	add r4, r1, r4
	mul r1, r8, r4
	stm r5!, {r0, r1}
	cmp r6, sl
	ldrhs r6, .L_080F0C10                      @ = 0x00000000
	cmp r7, fp
	ldrhs r7, .L_080F0C14                      @ = 0x00000000
	ldr r1, .L_080F0C1C                        @ = 0x00000000
	subs r1, r1, #1
	bne .L_080F0AE0
	ldr r0, .L_080F0C18                        @ = gReverbState
	str r2, [r0], #4
	str r3, [r0], #4
	str ip, [r0], #4
	str r4, [r0]
	ldr lr, .L_080F0C0C                        @ = 0x00000000
	bx lr
.L_080F0C0C:
	.word 0x00000000
.L_080F0C10:
	.word 0x00000000
.L_080F0C14:
	.word 0x00000000
.L_080F0C18:
	.word gReverbState
.L_080F0C1C:
	.word 0x00000000

@ --------------------------------------------------------------------------------------------------
@ mixArm_ReverbMono  (080F0C20, ARM)
@   ARM, mono variant of mixArm_ReverbStereo (one ring, one filter state).
@ --------------------------------------------------------------------------------------------------
	.global mixArm_ReverbMono
mixArm_ReverbMono:
	mov r7, r2
	mov fp, r3
	ldr r0, .L_080F0CD0                        @ = gReverbState
	ldr r2, [r0], #4
	ldr r3, [r0], #4
	add sl, sb, sl
.L_080F0C38:
	ldrsb r0, [r6], #1
	sub r2, r2, r2, asr r7
	add r2, r0, r2
	sub r0, r0, r2, asr r7
	sub r3, r3, r3, asr fp
	add r3, r0, r3
	mul r0, r8, r3
	ldrsb r1, [r6], #1
	sub r2, r2, r2, asr r7
	add r2, r1, r2
	sub r1, r1, r2, asr r7
	sub r3, r3, r3, asr fp
	add r3, r1, r3
	mul r1, r8, r3
	stm r5!, {r0, r1}
	ldrsb r0, [r6], #1
	sub r2, r2, r2, asr r7
	add r2, r0, r2
	sub r0, r0, r2, asr r7
	sub r3, r3, r3, asr fp
	add r3, r0, r3
	mul r0, r8, r3
	ldrsb r1, [r6], #1
	sub r2, r2, r2, asr r7
	add r2, r1, r2
	sub r1, r1, r2, asr r7
	sub r3, r3, r3, asr fp
	add r3, r1, r3
	mul r1, r8, r3
	stm r5!, {r0, r1}
	cmp r6, sl
	subhs r6, r6, sb
	subs r4, r4, #1
	bne .L_080F0C38
	ldr r0, .L_080F0CD0                        @ = gReverbState
	str r2, [r0], #4
	str r3, [r0], #4
	bx lr
.L_080F0CD0:
	.word gReverbState

@ --------------------------------------------------------------------------------------------------
@ mixDownmix  (080F0CD4, Thumb)
@   void mixDownmix(int n)                     // routine 1: acc -> 8-bit ring buffers
@   {
@       if (n == 0) return;
@       r7 = acc; r8 = gRingBufR + gRingWritePos*4; sb = gRingBufL + gRingWritePos*4;
@       sl = end of gRingBufR; fp = gClipTable; ip = 0x1FF;  r6 = n;
@       RAM routine 1 (mixArm_DownmixStereo)
@   }
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixDownmix
mixDownmix:
	orrs r0, r0
	bne .L_080F0CDA
	bx lr
.L_080F0CDA:
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	mov r4, ip
	push {r4}
	adds r6, r0, #0
	ldr r7, .L_080F0E4C                        @ = gMixBufPtr
	ldr r7, [r7]
	ldr r0, .L_080F0E50                        @ = gRingWritePos
	ldr r0, [r0]
	lsls r0, r0, #2
	ldr r1, .L_080F0E54                        @ = gRingBufR
	ldr r1, [r1]
	adds r4, r1, #0
	ldr r2, .L_080F0E58                        @ = gRingBufL
	ldr r2, [r2]
	adds r5, r2, #0
	adds r1, r1, r0
	adds r2, r2, r0
	mov r8, r1
	mov sb, r2
	ldr r0, .L_080F0E5C                        @ = gRingWords
	ldr r0, [r0]
	lsls r0, r0, #2
	ldr r1, .L_080F0E60                        @ = gRingBufR
	ldr r1, [r1]
	adds r0, r0, r1
	mov sl, r0
	ldr r0, .L_080F0E64                        @ = gClipTable
	mov fp, r0
	ldr r0, .L_080F0E68                        @ = 0x000001FF
	mov ip, r0
	movs r0, #1
	bl mixReverbDownmix_veneer
	pop {r4}
	mov ip, r4
	pop {r4, r5, r6, r7}
	mov r8, r4
	mov sb, r5
	mov sl, r6
	mov fp, r7
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ mixArm_DownmixStereo  (080F0D3C, ARM)
@   ARM: for 4 samples per word:  out = gClipTable[(acc >> 7) & 0x1FF]   (saturates to -128..127)
@        right samples (even acc words) -> gRingBufR, left (odd) -> gRingBufL, wrapping at the ring end.
@ --------------------------------------------------------------------------------------------------
	.arm
	.global mixArm_DownmixStereo
mixArm_DownmixStereo:
	str r4, [pc, #0x80]                        @ local variable at .L_080F0DC4
	str r5, [pc, #0x80]                        @ local variable at .L_080F0DC8
.L_080F0D44:
	ldm r7!, {r0, r1, r2, r3}
	and r0, ip, r0, lsr #7
	and r1, ip, r1, lsr #7
	and r2, ip, r2, lsr #7
	and r3, ip, r3, lsr #7
	ldrb r0, [fp, r0]
	ldrb r1, [fp, r1]
	ldrb r2, [fp, r2]
	ldrb r3, [fp, r3]
	orr r4, r0, r2, lsl #8
	orr r5, r1, r3, lsl #8
	ldm r7!, {r0, r1, r2, r3}
	and r0, ip, r0, lsr #7
	and r1, ip, r1, lsr #7
	and r2, ip, r2, lsr #7
	and r3, ip, r3, lsr #7
	ldrb r0, [fp, r0]
	ldrb r1, [fp, r1]
	ldrb r2, [fp, r2]
	ldrb r3, [fp, r3]
	orr r4, r4, r0, lsl #16
	orr r4, r4, r2, lsl #24
	orr r5, r5, r1, lsl #16
	orr r5, r5, r3, lsl #24
	str r4, [r8], #4
	str r5, [sb], #4
	cmp r8, sl
	ldrhs r8, .L_080F0DC4                      @ = 0x00000000
	ldrhs sb, .L_080F0DC8                      @ = 0x00000000
	subs r6, r6, #1
	bne .L_080F0D44
	bx lr
.L_080F0DC4:
	.word 0x00000000
.L_080F0DC8:
	.word 0x00000000

@ --------------------------------------------------------------------------------------------------
@ mixArm_DownmixMono  (080F0DCC, ARM)
@   ARM, mono variant of mixArm_DownmixStereo.
@ --------------------------------------------------------------------------------------------------
	.global mixArm_DownmixMono
mixArm_DownmixMono:
	ldm r7!, {r0, r1, r2, r3}
	and r0, ip, r0, lsr #7
	and r1, ip, r1, lsr #7
	and r2, ip, r2, lsr #7
	and r3, ip, r3, lsr #7
	ldrb r0, [fp, r0]
	ldrb r1, [fp, r1]
	ldrb r2, [fp, r2]
	ldrb r3, [fp, r3]
	orr r0, r0, r1, lsl #8
	orr r0, r0, r2, lsl #16
	orr r0, r0, r3, lsl #24
	str r0, [r8], #4
	cmp r8, sl
	movhs r8, r4
	subs r6, r6, #1
	bne mixArm_DownmixMono
	bx lr

@ --------------------------------------------------------------------------------------------------
@ mixReverbDownmix_veneer  (080F0E14, Thumb)
@   Veneer: bx to mixCallRamRoutine (used by mixReverb and mixDownmix).
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixReverbDownmix_veneer
mixReverbDownmix_veneer:
	ldr r1, .L_080F0E6C                        @ = mixCallRamRoutine
	adds r1, #1
	bx r1
	.hword 0x0000
.L_080F0E1C:
	.word gMixBufPtr
.L_080F0E20:
	.word gRingWritePos
.L_080F0E24:
	.word gRingBufR
.L_080F0E28:
	.word gRingBufL
.L_080F0E2C:
	.word gReverbDelay
.L_080F0E30:
	.word gRingWords
.L_080F0E34:
	.word gReverbLevel
.L_080F0E38:
	.word gReverbHpShift
.L_080F0E3C:
	.word gReverbLpShift
.L_080F0E40:
	.word gRingWords
.L_080F0E44:
	.word gRingBufR
.L_080F0E48:
	.word gRingBufL
.L_080F0E4C:
	.word gMixBufPtr
.L_080F0E50:
	.word gRingWritePos
.L_080F0E54:
	.word gRingBufR
.L_080F0E58:
	.word gRingBufL
.L_080F0E5C:
	.word gRingWords
.L_080F0E60:
	.word gRingBufR
.L_080F0E64:
	.word gClipTable
.L_080F0E68:
	.word 0x000001FF
.L_080F0E6C:
	.word mixCallRamRoutine

@ --------------------------------------------------------------------------------------------------
@ mixVoiceDirect  (080F0E70, Thumb)
@   int mixVoiceDirect(int n, Voice *v)        // routine 2: step is exactly 1.0 (voice flag 2 clear)
@   {
@       if (n == 0) return;
@       r7 = v->pcm + (v->pos >> 14);  sl = v->pcm + (v->end >> 14);  fp = (v->loopStart - v->end) >> 14;
@       r8 = gainR * vol >> 7;  sb = gainL * vol >> 7;  r5 = n * 4 samples;
@       alive = RAM routine 2;  v->flags = (v->flags & ~1) | alive;  v->pos = (r7 - v->pcm) << 14;
@   }
@   In mono mode routine 2 is an alias of the interpolating routine, which expects other registers
@   (latent: mode 1 is never used).
@ --------------------------------------------------------------------------------------------------
	.global mixVoiceDirect
mixVoiceDirect:
	orrs r0, r0
	bne .L_080F0E76
	bx lr
.L_080F0E76:
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	mov r4, ip
	push {r4}
	adds r5, r0, #0
	lsls r5, r5, #2
	ldr r6, .L_080F1020                        @ = gMixBufPtr
	ldr r6, [r6]
	ldr r0, [r1, #4]
	ldr r7, [r1, #0xc]
	lsrs r7, r7, #0xe
	adds r7, r7, r0
	ldr r3, [r1, #0x10]
	lsrs r3, r3, #0xe
	ldr r2, [r1, #0x14]
	lsrs r2, r2, #0xe
	subs r3, r3, r2
	adds r2, r2, r0
	mov sl, r2
	mov fp, r3
	movs r0, #3
	ldrsb r2, [r1, r0]
	movs r0, #2
	ldrsb r3, [r1, r0]
	ldrb r0, [r1, #1]
	ldr r4, .L_080F1024                        @ = gMixVolBoost
	ldrh r4, [r4]
	adds r0, r0, r4
	muls r2, r0, r2
	asrs r2, r2, #7
	muls r3, r0, r3
	asrs r3, r3, #7
	mov r8, r2
	mov sb, r3
	push {r1}
	movs r0, #2
	bl mixVoiceDirect_veneer
	pop {r1}
	ldrb r2, [r1]
	movs r3, #1
	bics r2, r3
	orrs r2, r0
	strb r2, [r1]
	ldr r0, [r1, #4]
	subs r7, r7, r0
	lsls r7, r7, #0xe
	str r7, [r1, #0xc]
	pop {r4}
	mov ip, r4
	pop {r4, r5, r6, r7}
	mov r8, r4
	mov sb, r5
	mov sl, r6
	mov fp, r7
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ mixArm_VoiceDirectStereo  (080F0EF4, ARM)
@   ARM: copies samples 1:1 (no resampling). While the source is word aligned it reads 4 samples per
@   ldr; otherwise one at a time. At the end: pcm += loopLen (negative) if looping, else return 0.
@ --------------------------------------------------------------------------------------------------
	.arm
	.global mixArm_VoiceDirectStereo
mixArm_VoiceDirectStereo:
	str lr, [pc, #0x118]                       @ local variable at .L_080F1014
.L_080F0EF8:
	ands r0, r7, #3
	bne .L_080F0FD0
	sub r4, sl, r7
	cmp r4, r5
	movhs r4, r5
	lsrs r4, r4, #2
	beq .L_080F0FD0
	sub r5, r5, r4, lsl #2
	tst r4, #1
	addne r4, r4, #1
	bne .L_080F0F74
.L_080F0F24:
	ldr ip, [r7], #4
	ldm r6, {r0, r1, r2, r3}
	lsl lr, ip, #0x18
	asr lr, lr, #0x18
	mla r0, r8, lr, r0
	mla r1, sb, lr, r1
	lsl lr, ip, #0x10
	asr lr, lr, #0x18
	mla r2, r8, lr, r2
	mla r3, sb, lr, r3
	stm r6!, {r0, r1, r2, r3}
	ldm r6, {r0, r1, r2, r3}
	lsl lr, ip, #8
	asr lr, lr, #0x18
	mla r0, r8, lr, r0
	mla r1, sb, lr, r1
	asr lr, ip, #0x18
	mla r2, r8, lr, r2
	mla r3, sb, lr, r3
	stm r6!, {r0, r1, r2, r3}
.L_080F0F74:
	ldr ip, [r7], #4
	ldm r6, {r0, r1, r2, r3}
	lsl lr, ip, #0x18
	asr lr, lr, #0x18
	mla r0, r8, lr, r0
	mla r1, sb, lr, r1
	lsl lr, ip, #0x10
	asr lr, lr, #0x18
	mla r2, r8, lr, r2
	mla r3, sb, lr, r3
	stm r6!, {r0, r1, r2, r3}
	ldm r6, {r0, r1, r2, r3}
	lsl lr, ip, #8
	asr lr, lr, #0x18
	mla r0, r8, lr, r0
	mla r1, sb, lr, r1
	asr lr, ip, #0x18
	mla r2, r8, lr, r2
	mla r3, sb, lr, r3
	stm r6!, {r0, r1, r2, r3}
	subs r4, r4, #2
	bne .L_080F0F24
	b .L_080F0FE8
.L_080F0FD0:
	ldrsb ip, [r7], #1
	ldm r6, {r0, r1}
	mla r0, r8, ip, r0
	mla r1, sb, ip, r1
	stm r6!, {r0, r1}
	sub r5, r5, #1
.L_080F0FE8:
	cmp r7, sl
	blo .L_080F1000
	mov r0, #0
	cmp fp, #0
	beq .L_080F100C
	add r7, r7, fp
.L_080F1000:
	cmp r5, #0
	bne .L_080F0EF8
	mov r0, #1
.L_080F100C:
	ldr lr, .L_080F1014                        @ = 0x00000000
	bx lr
.L_080F1014:
	.word 0x00000000

@ --------------------------------------------------------------------------------------------------
@ mixVoiceDirect_veneer  (080F1018, Thumb)
@   Veneer: bx to mixCallRamRoutine.
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixVoiceDirect_veneer
mixVoiceDirect_veneer:
	ldr r1, .L_080F1028                        @ = mixCallRamRoutine
	adds r1, #1
	bx r1
	.hword 0x0000
.L_080F1020:
	.word gMixBufPtr
.L_080F1024:
	.word gMixVolBoost
.L_080F1028:
	.word mixCallRamRoutine

@ --------------------------------------------------------------------------------------------------
@ mixVoicePoint  (080F102C, Thumb)
@   int mixVoicePoint(int n, Voice *v)         // routine 4: resampling without interpolation (flags 2 and 4)
@   Same set-up as mixVoiceInterp; mixes pcm[pos >> 14] (nearest lower sample).
@ --------------------------------------------------------------------------------------------------
	.global mixVoicePoint
mixVoicePoint:
	orrs r0, r0
	bne .L_080F1032
	bx lr
.L_080F1032:
	push {r4, r5, r6, r7, lr}
	mov r4, r8
	mov r5, sb
	mov r6, sl
	mov r7, fp
	push {r4, r5, r6, r7}
	mov r4, ip
	push {r4}
	adds r5, r0, #0
	push {r1}
	ldr r6, .L_080F1288                        @ = gMixBufPtr
	ldr r6, [r6]
	ldr r7, [r1, #4]
	ldr r0, [r1, #0x14]
	mov r8, r0
	movs r0, #3
	ldrsb r2, [r1, r0]
	movs r0, #2
	ldrsb r3, [r1, r0]
	ldrb r0, [r1, #1]
	ldr r4, .L_080F128C                        @ = gMixVolBoost
	ldrh r4, [r4]
	adds r0, r0, r4
	muls r2, r0, r2
	asrs r2, r2, #7
	muls r3, r0, r3
	asrs r3, r3, #7
	mov sb, r2
	mov sl, r3
	ldr r0, [r1, #0xc]
	mov fp, r0
	ldr r0, [r1, #0x18]
	lsls r0, r0, #0xa
	orrs r0, r5
	mov ip, r0
	mov r0, r8
	ldr r5, [r1, #0x10]
	subs r5, r5, r0
	movs r0, #4
	bl mixVoicePoint_veneer
	pop {r1}
	ldrb r2, [r1]
	movs r3, #1
	bics r2, r3
	orrs r2, r0
	strb r2, [r1]
	mov r0, fp
	str r0, [r1, #0xc]
	pop {r4}
	mov ip, r4
	pop {r4, r5, r6, r7}
	mov r8, r4
	mov sb, r5
	mov sl, r6
	mov fp, r7
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ mixArm_VoicePointStereo  (080F10A8, ARM)
@   ARM: as mixArm_VoiceInterpStereo without the interpolation.
@ --------------------------------------------------------------------------------------------------
	.arm
	.global mixArm_VoicePointStereo
mixArm_VoicePointStereo:
	add r0, fp, ip, lsr #8
	cmp r0, r8
	bhs .L_080F1128
	ldm r6, {r0, r1, r2, r3}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r2, r4, sb, r2
	mla r3, r4, sl, r3
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1, r2, r3}
	ldm r6, {r0, r1, r2, r3}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r2, r4, sb, r2
	mla r3, r4, sl, r3
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1, r2, r3}
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne mixArm_VoicePointStereo
	mov r0, #1
	bx lr
.L_080F1128:
	cmp r5, #0
	beq .L_080F1178
	mov r3, #4
.L_080F1134:
	ldm r6, {r0, r1}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1}
.L_080F1150:
	cmp fp, r8
	addhs fp, fp, r5
	bhs .L_080F1150
	subs r3, r3, #1
	bne .L_080F1134
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne mixArm_VoicePointStereo
	mov r0, #1
	bx lr
.L_080F1178:
	ldm r6, {r0, r1}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	mla r1, r4, sl, r1
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1}
	cmp fp, r8
	blo .L_080F1178
	mov r0, #0
	bx lr

@ --------------------------------------------------------------------------------------------------
@ mixArm_VoicePointMono  (080F11A4, ARM)
@   ARM, mono variant of mixArm_VoicePointStereo.
@   Bug (latent, mono only): the 2nd and 4th samples of each group are computed as "s*sb + r2" instead of
@   "+ r1"/"+ r3", so they overwrite instead of accumulate.
@ --------------------------------------------------------------------------------------------------
	.global mixArm_VoicePointMono
mixArm_VoicePointMono:
	add r0, fp, ip, lsr #8
	cmp r0, r8
	bhs .L_080F120C
	ldm r6, {r0, r1, r2, r3}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	add fp, fp, ip, lsr #10
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r1, r4, sb, r2
	add fp, fp, ip, lsr #10
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r2, r4, sb, r2
	add fp, fp, ip, lsr #10
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r3, r4, sb, r2
	add fp, fp, ip, lsr #10
	stm r6!, {r0, r1, r2, r3}
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne mixArm_VoicePointMono
	mov r0, #1
	bx lr
.L_080F120C:
	cmp r5, #0
	beq .L_080F1258
	mov r3, #4
.L_080F1218:
	ldm r6, {r0}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	add fp, fp, ip, lsr #10
	stm r6!, {r0}
.L_080F1230:
	cmp fp, r8
	addhs fp, fp, r5
	bhs .L_080F1230
	subs r3, r3, #1
	bne .L_080F1218
	sub ip, ip, #1
	ands r0, ip, #0xff
	bne mixArm_VoicePointMono
	mov r0, #1
	bx lr
.L_080F1258:
	ldm r6, {r0}
	add r4, r7, fp, lsr #14
	ldrsb r4, [r4]
	mla r0, r4, sb, r0
	add fp, fp, ip, lsr #10
	stm r6!, {r0}
	cmp fp, r8
	blo .L_080F1258
	mov r0, #0
	bx lr

@ --------------------------------------------------------------------------------------------------
@ mixVoicePoint_veneer  (080F1280, Thumb)
@   Veneer: bx to mixCallRamRoutine.
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixVoicePoint_veneer
mixVoicePoint_veneer:
	ldr r1, .L_080F1290                        @ = mixCallRamRoutine
	adds r1, #1
	bx r1
	.hword 0x0000
.L_080F1288:
	.word gMixBufPtr
.L_080F128C:
	.word gMixVolBoost
.L_080F1290:
	.word mixCallRamRoutine

@ --------------------------------------------------------------------------------------------------
@ mixFilter  (080F1294, Thumb)
@   void mixFilter(int n, MixFilter *f)        // routine 5: one-pole filter over the accumulator
@   {   if (n == 0) return;  r4 = f->cutoff (u8); r2 = f->stateR; r3 = f->stateL;  RAM routine 5;  store states; }
@ --------------------------------------------------------------------------------------------------
	.global mixFilter
mixFilter:
	orrs r0, r0
	bne .L_080F129A
	bx lr
.L_080F129A:
	push {r4, r5, r6, r7, lr}
	ldrb r4, [r1]
	adds r5, r0, #0
	ldr r2, [r1, #4]
	ldr r3, [r1, #8]
	ldr r6, .L_080F1410                        @ = gMixBufPtr
	ldr r6, [r6]
	push {r1}
	movs r0, #5
	bl mixFilter_veneer
	pop {r1}
	str r2, [r1, #4]
	str r3, [r1, #8]
	pop {r4, r5, r6, r7, pc}

@ --------------------------------------------------------------------------------------------------
@ mixArm_Filter  (080F12B8, ARM)
@   ARM:  c < 0x80: low-pass,  a = 2*c:        y = (x*(256 - a) + y_prev*a) >> 8
@          c >= 0x80: high-pass, a = 2*(c-0x80):  y = x - lowpass_a(x)
@          applied to both sides, 4 stereo samples per pass.
@ --------------------------------------------------------------------------------------------------
	.arm
	.global mixArm_Filter
mixArm_Filter:
	push {r8, sb, sl, fp, lr}
	mov lr, r5
	mov ip, r6
	cmp r4, #0x80
	bhs .L_080F1358
	lsl r4, r4, #1
	mov r0, r4
	rsb r1, r4, #0x100
.L_080F12D8:
	ldm ip, {r4, r5, r6, r7, r8, sb, sl, fp}
	mul r4, r1, r4
	mla r4, r0, r2, r4
	asr r4, r4, #8
	mul r5, r1, r5
	mla r5, r0, r3, r5
	asr r5, r5, #8
	mul r6, r1, r6
	mla r6, r0, r4, r6
	asr r6, r6, #8
	mul r7, r1, r7
	mla r7, r0, r5, r7
	asr r7, r7, #8
	mul r8, r1, r8
	mla r8, r0, r6, r8
	asr r8, r8, #8
	mul sb, r1, sb
	mla sb, r0, r7, sb
	asr sb, sb, #8
	mul sl, r1, sl
	mla sl, r0, r8, sl
	asr sl, sl, #8
	mul fp, r1, fp
	mla fp, r0, sb, fp
	asr fp, fp, #8
	stm ip!, {r4, r5, r6, r7, r8, sb, sl, fp}
	mov r2, sl
	mov r3, fp
	subs lr, lr, #1
	bne .L_080F12D8
	pop {r8, sb, sl, fp, lr}
	bx lr
.L_080F1358:
	sub r4, r4, #0x80
	lsl r4, r4, #1
	mov r0, r4
	rsb r1, r4, #0x100
.L_080F1368:
	ldm ip, {r4, r5, r6, r7}
	mul r8, r1, r4
	mla r8, r0, r2, r8
	sub r4, r4, r8, asr #8
	asr r2, r8, #8
	mul r8, r1, r5
	mla r8, r0, r3, r8
	sub r5, r5, r8, asr #8
	asr r3, r8, #8
	mul r8, r1, r6
	mla r8, r0, r2, r8
	sub r6, r6, r8, asr #8
	asr r2, r8, #8
	mul r8, r1, r7
	mla r8, r0, r3, r8
	sub r7, r7, r8, asr #8
	asr r3, r8, #8
	stm ip!, {r4, r5, r6, r7}
	ldm ip, {r4, r5, r6, r7}
	mul r8, r1, r4
	mla r8, r0, r2, r8
	sub r4, r4, r8, asr #8
	asr r2, r8, #8
	mul r8, r1, r5
	mla r8, r0, r3, r8
	sub r5, r5, r8, asr #8
	asr r3, r8, #8
	mul r8, r1, r6
	mla r8, r0, r2, r8
	sub r6, r6, r8, asr #8
	asr r2, r8, #8
	mul r8, r1, r7
	mla r8, r0, r3, r8
	sub r7, r7, r8, asr #8
	asr r3, r8, #8
	stm ip!, {r4, r5, r6, r7}
	subs lr, lr, #1
	bne .L_080F1368
	pop {r8, sb, sl, fp, lr}
	bx lr

@ --------------------------------------------------------------------------------------------------
@ mixFilter_veneer  (080F1408, Thumb)
@ --------------------------------------------------------------------------------------------------
	.thumb
	.global mixFilter_veneer
mixFilter_veneer:
	ldr r1, .L_080F1414                        @ = mixCallRamRoutine
	adds r1, #1
	bx r1
	.hword 0x0000
.L_080F1410:
	.word gMixBufPtr
.L_080F1414:
	.word mixCallRamRoutine

@ --------------------------------------------------------------------------------------------------
@ sndDma2Irq  (080F1418, Thumb)
@   void sndDma2Irq(void)                      // DMA2 interrupt: one FIFO refill = 16 samples = 4 words
@   {
@       if (!gMixEnabled) return;
@       restart = 0;
@       if ((gRingReadPos += 4) >= gRingWords) gRingReadPos -= gRingWords;
@       if (gRingReadPos == gRingWritePos) {                  // underrun: the mixer has not caught up
@           gRingReadPos = (gRingReadPos ? gRingReadPos : gRingWords) - 4;   // play the last 16 samples again
@           restart = 1;
@       }
@       if (gRingReadPos == 0) restart = 1;                   // wrapped: point the DMA back at the ring start
@       if (restart) { stop DMA1/DMA2; source = ring + gRingReadPos*4; restart them (per gMixMode) }
@   }
@ --------------------------------------------------------------------------------------------------
	.global sndDma2Irq
sndDma2Irq:
	push {r4, r5, r6, lr}
	sub sp, #4
	ldr r0, .L_080F145C                        @ = gMixEnabled
	ldrh r0, [r0]
	cmp r0, #0
	bne .L_080F1426
	b .L_080F1548
.L_080F1426:
	movs r4, #0
	ldr r1, .L_080F1460                        @ = gRingReadPos
	ldr r0, [r1]
	adds r0, #4
	str r0, [r1]
	ldr r3, .L_080F1464                        @ = gRingWords
	ldr r2, [r1]
	ldr r0, [r3]
	adds r5, r1, #0
	cmp r2, r0
	blo .L_080F1444
	ldr r0, [r5]
	ldr r1, [r3]
	subs r0, r0, r1
	str r0, [r5]
.L_080F1444:
	ldr r0, .L_080F1468                        @ = gRingWritePos
	ldr r1, [r5]
	ldr r0, [r0]
	cmp r1, r0
	bne .L_080F1474
	adds r1, r5, #0
	ldr r0, [r5]
	cmp r0, #0
	beq .L_080F146C
	ldr r0, [r5]
	b .L_080F146E
	.hword 0x0000
.L_080F145C:
	.word gMixEnabled
.L_080F1460:
	.word gRingReadPos
.L_080F1464:
	.word gRingWords
.L_080F1468:
	.word gRingWritePos
.L_080F146C:
	ldr r0, [r3]
.L_080F146E:
	subs r0, #4
	str r0, [r1]
	movs r4, #1
.L_080F1474:
	adds r6, r5, #0
	ldr r0, [r6]
	cmp r0, #0
	bne .L_080F147E
	movs r4, #1
.L_080F147E:
	cmp r4, #0
	beq .L_080F1548
	ldr r0, .L_080F1494                        @ = gMixMode
	ldr r0, [r0]
	cmp r0, #1
	beq .L_080F14DC
	cmp r0, #1
	blo .L_080F1498
	cmp r0, #2
	beq .L_080F150C
	b .L_080F1548
.L_080F1494:
	.word gMixMode
.L_080F1498:
	ldr r3, .L_080F14C8                        @ = REG_DMA1CNT_H
	movs r0, #0
	strh r0, [r3]
	ldr r4, .L_080F14CC                        @ = REG_DMA2CNT_H
	strh r0, [r4]
	ldr r2, .L_080F14D0                        @ = REG_DMA1SAD
	ldr r0, .L_080F14D4                        @ = gRingBufR
	ldr r1, [r6]
	lsls r1, r1, #2
	ldr r0, [r0]
	adds r0, r0, r1
	str r0, [r2]
	adds r2, #0xc
	ldr r0, .L_080F14D8                        @ = gRingBufL
	ldr r1, [r6]
	lsls r1, r1, #2
	ldr r0, [r0]
	adds r0, r0, r1
	str r0, [r2]
	movs r1, #0xb6
	lsls r1, r1, #8
	adds r0, r1, #0
	b .L_080F1534
	.hword 0x0000
.L_080F14C8:
	.word REG_DMA1CNT_H
.L_080F14CC:
	.word REG_DMA2CNT_H
.L_080F14D0:
	.word REG_DMA1SAD
.L_080F14D4:
	.word gRingBufR
.L_080F14D8:
	.word gRingBufL
.L_080F14DC:
	ldr r3, .L_080F1500                        @ = REG_DMA2CNT_H
	movs r0, #0
	strh r0, [r3]
	ldr r2, .L_080F1504                        @ = REG_DMA2SAD
	ldr r0, .L_080F1508                        @ = gRingBufR
	ldr r1, [r6]
	lsls r1, r1, #2
	ldr r0, [r0]
	adds r0, r0, r1
	str r0, [r2]
	movs r1, #0xf6
	lsls r1, r1, #8
	adds r0, r1, #0
	strh r0, [r3]
	movs r0, #0
	str r0, [sp]
	str r0, [sp]
	b .L_080F1548
.L_080F1500:
	.word REG_DMA2CNT_H
.L_080F1504:
	.word REG_DMA2SAD
.L_080F1508:
	.word gRingBufR
.L_080F150C:
	ldr r3, .L_080F1550                        @ = REG_DMA1CNT_H
	movs r0, #0
	strh r0, [r3]
	ldr r4, .L_080F1554                        @ = REG_DMA2CNT_H
	strh r0, [r4]
	ldr r2, .L_080F1558                        @ = REG_DMA1SAD
	ldr r1, .L_080F155C                        @ = gRingBufR
	ldr r0, [r5]
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r0, r1, r0
	str r0, [r2]
	adds r2, #0xc
	ldr r0, [r5]
	lsls r0, r0, #2
	adds r1, r1, r0
	str r1, [r2]
	movs r2, #0xb6
	lsls r2, r2, #8
	adds r0, r2, #0
.L_080F1534:
	strh r0, [r3]
	movs r1, #0
	str r1, [sp]
	str r1, [sp]
	movs r2, #0xf6
	lsls r2, r2, #8
	adds r0, r2, #0
	strh r0, [r4]
	str r1, [sp]
	str r1, [sp]
.L_080F1548:
	add sp, #4
	pop {r4, r5, r6}
	pop {r0}
	bx r0
.L_080F1550:
	.word REG_DMA1CNT_H
.L_080F1554:
	.word REG_DMA2CNT_H
.L_080F1558:
	.word REG_DMA1SAD
.L_080F155C:
	.word gRingBufR

@ ==================================================================================================
@  MIXER VOICES AND FRAME MIXING (0x080F1560-0x080F1DE0)
@  One Voice (0x20 bytes) per mixer channel; note slot i of gNotes always drives voice i.
@ ==================================================================================================

@ --------------------------------------------------------------------------------------------------
@ voiceSetSample  (080F1560, Thumb)
@   void voiceSetSample(int i, const SampleHeader *s)
@   {
@       Voice *v = &gMixVoices[i];
@       v->flags &= ~1;   v->pcm = s->pcm;   v->lengthWords = s->length >> 2;      // lengthWords is never read
@       if (s->loopStart | s->loopEnd) { v->loopStart = s->loopStart << 14;  v->end = s->loopEnd << 14; }
@       else                           { v->loopStart = v->end = s->length << 14; }
@       // base step (18.14) at the sample's root key, rounded up:
@       v->baseStep = ((u64)s->rate << 28) + freq[s->rootKey] * gMixRate - 1) / (freq[s->rootKey] * gMixRate);
@   }                                   // freq = sndKeyFreqTable (always the default table here)
@ --------------------------------------------------------------------------------------------------
	.global voiceSetSample
voiceSetSample:
	push {r4, r5, r6, lr}
	adds r3, r1, #0
	ldr r1, .L_080F1594                        @ = gMixVoices
	lsls r0, r0, #5
	ldr r1, [r1]
	adds r6, r1, r0
	ldrb r1, [r6]
	movs r0, #2
	rsbs r0, r0, #0
	ands r0, r1
	strb r0, [r6]
	ldr r0, [r3, #0x14]
	str r0, [r6, #4]
	ldr r0, [r3]
	lsrs r0, r0, #2
	str r0, [r6, #8]
	ldr r1, [r3, #0xc]
	ldr r0, [r3, #0x10]
	orrs r0, r1
	cmp r0, #0
	beq .L_080F1598
	lsls r0, r1, #0xe
	str r0, [r6, #0x10]
	ldr r0, [r3, #0x10]
	b .L_080F15A0
	.hword 0x0000
.L_080F1594:
	.word gMixVoices
.L_080F1598:
	ldr r0, [r3]
	lsls r0, r0, #0xe
	str r0, [r6, #0x10]
	ldr r0, [r3]
.L_080F15A0:
	lsls r0, r0, #0xe
	str r0, [r6, #0x14]
	ldr r1, .L_080F15E0                        @ = sndKeyFreqTable
	ldr r0, [r3, #8]
	lsls r0, r0, #1
	adds r0, r0, r1
	ldrh r1, [r0]
	ldr r0, .L_080F15E4                        @ = gMixRate
	ldr r0, [r0]
	adds r2, r0, #0
	muls r2, r1, r2
	ldr r0, [r3, #4]
	movs r1, #0
	lsrs r5, r0, #4
	lsls r4, r1, #0x1c
	adds r1, r5, #0
	orrs r1, r4
	lsls r0, r0, #0x1c
	movs r3, #0
	adds r0, r0, r2
	adcs r1, r3
	movs r4, #1
	rsbs r4, r4, #0
	asrs r5, r4, #0x1f
	adds r0, r0, r4
	adcs r1, r5
	bl __udivdi3
	str r0, [r6, #0x1c]
	pop {r4, r5, r6}
	pop {r0}
	bx r0
.L_080F15E0:
	.word sndKeyFreqTable
.L_080F15E4:
	.word gMixRate

@ --------------------------------------------------------------------------------------------------
@ voiceStart  (080F15E8, Thumb)
@   void voiceStart(int i)  { v->pos = 0; v->flags |= 1; }
@ --------------------------------------------------------------------------------------------------
	.global voiceStart
voiceStart:
	ldr r1, .L_080F1600                        @ = gMixVoices
	ldr r1, [r1]
	lsls r0, r0, #5
	adds r0, r0, r1
	movs r1, #0
	str r1, [r0, #0xc]
	ldrb r1, [r0]
	movs r2, #1
	orrs r1, r2
	strb r1, [r0]
	bx lr
	.hword 0x0000
.L_080F1600:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ voiceStop  (080F1604, Thumb)
@   void voiceStop(int i)   { v->flags &= ~1; }
@ --------------------------------------------------------------------------------------------------
	.global voiceStop
voiceStop:
	ldr r1, .L_080F1618                        @ = gMixVoices
	ldr r1, [r1]
	lsls r0, r0, #5
	adds r0, r0, r1
	ldrb r2, [r0]
	movs r1, #2
	rsbs r1, r1, #0
	ands r1, r2
	strb r1, [r0]
	bx lr
.L_080F1618:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ voiceSetPan  (080F161C, Thumb)
@   void voiceSetPan(int i, int left, int right)  { v->gainL = left; v->gainR = right; }   // s8, right may be negative
@ --------------------------------------------------------------------------------------------------
	.global voiceSetPan
voiceSetPan:
	push {r4, lr}
	ldr r4, .L_080F1634                        @ = gMixVoices
	ldr r3, [r4]
	lsls r0, r0, #5
	adds r3, r0, r3
	strb r1, [r3, #2]
	ldr r1, [r4]
	adds r0, r0, r1
	strb r2, [r0, #3]
	pop {r4}
	pop {r0}
	bx r0
.L_080F1634:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ voiceSetVolume  (080F1638, Thumb)
@   void voiceSetVolume(int i, int vol)  { v->vol = vol; }
@ --------------------------------------------------------------------------------------------------
	.global voiceSetVolume
voiceSetVolume:
	ldr r2, .L_080F1644                        @ = gMixVoices
	ldr r2, [r2]
	lsls r0, r0, #5
	adds r0, r0, r2
	strb r1, [r0, #1]
	bx lr
.L_080F1644:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ voiceSetPitch  (080F1648, Thumb)
@   void voiceSetPitch(int i, u32 freq)         // freq in the Hz units of sndKeyFreqTable
@   {
@       if (freq == 0) { v->step = 0x4000; v->flags &= ~2; }          // "F" instruments: native rate, 1:1 copy
@       else { v->step = (u64)v->baseStep * freq >> 14;                 // __muldi3
@              v->flags = (v->flags & ~2) | (v->step != 0x4000) << 1; } // flag 2 = needs resampling
@   }
@ --------------------------------------------------------------------------------------------------
	.global voiceSetPitch
voiceSetPitch:
	push {r4, r5, lr}
	adds r5, r1, #0
	ldr r1, .L_080F1668                        @ = gMixVoices
	lsls r0, r0, #5
	ldr r1, [r1]
	adds r4, r1, r0
	cmp r5, #0
	bne .L_080F166C
	movs r0, #0x80
	lsls r0, r0, #7
	str r0, [r4, #0x18]
	ldrb r1, [r4]
	movs r0, #3
	rsbs r0, r0, #0
	ands r0, r1
	b .L_080F169A
.L_080F1668:
	.word gMixVoices
.L_080F166C:
	ldr r0, [r4, #0x1c]
	movs r1, #0
	adds r2, r5, #0
	movs r3, #0
	bl __muldi3
	lsls r3, r1, #0x12
	lsrs r2, r0, #0xe
	adds r0, r3, #0
	orrs r0, r2
	str r0, [r4, #0x18]
	movs r2, #0x80
	lsls r2, r2, #7
	eors r2, r0
	rsbs r1, r2, #0
	orrs r1, r2
	lsrs r1, r1, #0x1f
	lsls r1, r1, #1
	ldrb r2, [r4]
	movs r0, #3
	rsbs r0, r0, #0
	ands r0, r2
	orrs r0, r1
.L_080F169A:
	strb r0, [r4]
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ voiceSetNoInterp  (080F16A4, Thumb)
@   void voiceSetNoInterp(int i, int on)  { v->flags = (v->flags & ~4) | (on & 1) << 2; }
@ --------------------------------------------------------------------------------------------------
	.global voiceSetNoInterp
voiceSetNoInterp:
	ldr r2, .L_080F16C0                        @ = gMixVoices
	ldr r2, [r2]
	lsls r0, r0, #5
	adds r0, r0, r2
	movs r2, #1
	ands r1, r2
	lsls r1, r1, #2
	ldrb r3, [r0]
	movs r2, #5
	rsbs r2, r2, #0
	ands r2, r3
	orrs r2, r1
	strb r2, [r0]
	bx lr
.L_080F16C0:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ voiceSetWet  (080F16C4, Thumb)
@   void voiceSetWet(int i, int on)       { v->flags = (v->flags & ~8) | (on & 1) << 3; }   // mixed before the master filter
@ --------------------------------------------------------------------------------------------------
	.global voiceSetWet
voiceSetWet:
	ldr r2, .L_080F16E0                        @ = gMixVoices
	ldr r2, [r2]
	lsls r0, r0, #5
	adds r0, r0, r2
	movs r2, #1
	ands r1, r2
	lsls r1, r1, #3
	ldrb r3, [r0]
	movs r2, #9
	rsbs r2, r2, #0
	ands r2, r3
	orrs r2, r1
	strb r2, [r0]
	bx lr
.L_080F16E0:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ mixInit  (080F16E4, Thumb)
@   void mixInit(int mode, int rate, int ringBytes, s8 *ring, int blockLen, s32 *acc, int nVoices, Voice *voices)
@   {   // WarioWare: mixInit(0, 13379, 0x620, 0x03001068, 128, 0x03001CA8, 8, 0x030020A8)
@       gMixMode = mode; gMixRate = rate; gRingWords = ringBytes / 4; gRingBufR = ring;
@       gRingBufL = ring + gRingWords*4; gMixBlockLen = blockLen; gMixBufPtr = acc;
@       gMixNumVoices = nVoices; gMixVoices = voices;
@       gMixSamplesPerFrame = rate / 60;           // 222
@       gMixTimerReload = 0xFFFED9 / rate;          // 1253 cycles -> 13 389.6 Hz actual output rate
@       clear gReverbState, gMixFilter; gReverbDelay = 0; gReverbHpShift = 4; gReverbLpShift = 2;
@       gMixFilterPrev = 0; gFilterGain = 4; stop DMA1/DMA2; gRingWritePos = gRingReadPos = 0;
@       mixLoadRoutines(mode);
@       gClipTable[i] = i <= 127 ? i : i <= 255 ? 127 : i < 384 ? -128 : i - 512;   gClipTable[0x1FF] = 0;
@       for each voice: flags &= ~1, gainL = gainR = -128;
@       clear both ring buffers; gMixEnabled = 1; mixFrame();              // pre-fill
@       REG_SOUNDCNT_X = 0x80;
@       mode 0: SOUNDCNT_H = 0xA90E (FIFO A -> right, FIFO B -> left, timer 0); DMA1: ringR -> FIFO A (0xB600),
@               DMA2: ringL -> FIFO B (0xF600, IRQ)
@       mode 1: SOUNDCNT_H = 0xB80E (FIFO B both sides); DMA2: ringR -> FIFO B
@       mode 2: SOUNDCNT_H = 0xBB0E (both FIFOs both sides); DMA1 and DMA2 both from ringR
@       REG_SOUNDCNT_L = 0xBB77;  REG_TM0CNT = -gMixTimerReload, started
@   }
@ --------------------------------------------------------------------------------------------------
	.global mixInit
mixInit:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #4
	mov sb, r0
	adds r5, r1, #0
	ldr r4, [sp, #0x24]
	ldr r6, [sp, #0x28]
	ldr r0, [sp, #0x2c]
	mov r8, r0
	ldr r7, [sp, #0x30]
	ldr r0, .L_080F17CC                        @ = gMixMode
	mov r1, sb
	str r1, [r0]
	ldr r0, .L_080F17D0                        @ = gMixRate
	str r5, [r0]
	ldr r1, .L_080F17D4                        @ = gRingWords
	lsrs r2, r2, #2
	str r2, [r1]
	ldr r0, .L_080F17D8                        @ = gRingBufR
	str r3, [r0]
	ldr r2, .L_080F17DC                        @ = gRingBufL
	ldr r0, [r1]
	lsls r0, r0, #2
	adds r3, r3, r0
	str r3, [r2]
	ldr r0, .L_080F17E0                        @ = gMixBlockLen
	str r4, [r0]
	ldr r0, .L_080F17E4                        @ = gMixBufPtr
	str r6, [r0]
	ldr r0, .L_080F17E8                        @ = gMixNumVoices
	mov r2, r8
	strh r2, [r0]
	ldr r0, .L_080F17EC                        @ = gMixVoices
	str r7, [r0]
	ldr r4, .L_080F17F0                        @ = gMixSamplesPerFrame
	adds r0, r5, #0
	movs r1, #0x3c
	bl __udivsi3
	str r0, [r4]
	ldr r4, .L_080F17F4                        @ = gMixTimerReload
	ldr r0, .L_080F17F8                        @ = 0x00FFFED9
	adds r1, r5, #0
	bl __udivsi3
	str r0, [r4]
	ldr r1, .L_080F17FC                        @ = gReverbLevel
	movs r0, #0
	str r0, [r1]
	movs r4, #0
	ldr r2, .L_080F1800                        @ = gReverbDelay
	ldr r3, .L_080F1804                        @ = gReverbHpShift
	ldr r5, .L_080F1808                        @ = gReverbLpShift
	ldr r7, .L_080F180C                        @ = gMixFilterPrev
	ldr r0, .L_080F1810                        @ = gFilterGain
	mov r8, r0
	ldr r1, .L_080F1814                        @ = gRingReadPos
	mov ip, r1
	ldr r6, .L_080F1818                        @ = gRingWritePos
	ldr r0, .L_080F181C                        @ = mixLoadRoutines
	mov sl, r0
	movs r0, #0
	ldr r1, .L_080F1820                        @ = gReverbState
.L_080F1768:
	stm r1!, {r0}
	adds r4, #1
	cmp r4, #3
	bls .L_080F1768
	movs r0, #0
	str r0, [r2]
	movs r0, #4
	str r0, [r3]
	movs r0, #2
	str r0, [r5]
	movs r4, #0
	movs r0, #0
	ldr r1, .L_080F1824                        @ = gMixFilter
.L_080F1782:
	stm r1!, {r0}
	adds r4, #1
	cmp r4, #2
	bls .L_080F1782
	movs r0, #0
	strb r0, [r7]
	movs r0, #4
	mov r1, r8
	strb r0, [r1]
	ldr r0, .L_080F1828                        @ = REG_DMA1CNT_H
	movs r1, #0
	strh r1, [r0]
	adds r0, #0xc
	strh r1, [r0]
	movs r0, #0
	str r0, [r6]
	ldr r0, [r6]
	mov r2, ip
	str r0, [r2]
	movs r1, #1
	mov r3, sl
	orrs r1, r3
	mov r0, sb
	bl _call_via_r1
	ldr r6, .L_080F182C                        @ = gClipTable
	movs r4, #0
	movs r5, #0x7f
	adds r2, r6, #0
	ldr r3, .L_080F1830                        @ = 0xFFFFFE00
.L_080F17BE:
	cmp r4, #0xff
	bhi .L_080F1834
	cmp r4, #0x7f
	bls .L_080F183E
	strb r5, [r2]
	b .L_080F184A
	.hword 0x0000
.L_080F17CC:
	.word gMixMode
.L_080F17D0:
	.word gMixRate
.L_080F17D4:
	.word gRingWords
.L_080F17D8:
	.word gRingBufR
.L_080F17DC:
	.word gRingBufL
.L_080F17E0:
	.word gMixBlockLen
.L_080F17E4:
	.word gMixBufPtr
.L_080F17E8:
	.word gMixNumVoices
.L_080F17EC:
	.word gMixVoices
.L_080F17F0:
	.word gMixSamplesPerFrame
.L_080F17F4:
	.word gMixTimerReload
.L_080F17F8:
	.word 0x00FFFED9
.L_080F17FC:
	.word gReverbLevel
.L_080F1800:
	.word gReverbDelay
.L_080F1804:
	.word gReverbHpShift
.L_080F1808:
	.word gReverbLpShift
.L_080F180C:
	.word gMixFilterPrev
.L_080F1810:
	.word gFilterGain
.L_080F1814:
	.word gRingReadPos
.L_080F1818:
	.word gRingWritePos
.L_080F181C:
	.word mixLoadRoutines
.L_080F1820:
	.word gReverbState
.L_080F1824:
	.word gMixFilter
.L_080F1828:
	.word REG_DMA1CNT_H
.L_080F182C:
	.word gClipTable
.L_080F1830:
	.word 0xFFFFFE00
.L_080F1834:
	adds r1, r4, r3
	movs r0, #0x81
	rsbs r0, r0, #0
	cmp r1, r0
	bls .L_080F1842
.L_080F183E:
	strb r4, [r2]
	b .L_080F184A
.L_080F1842:
	movs r1, #0x80
	rsbs r1, r1, #0
	adds r0, r1, #0
	strb r0, [r2]
.L_080F184A:
	adds r2, #1
	adds r4, #1
	ldr r1, .L_080F18DC                        @ = 0x000001FF
	cmp r4, r1
	bls .L_080F17BE
	adds r1, r6, r1
	movs r0, #0
	strb r0, [r1]
	movs r4, #0
	ldr r7, .L_080F18E0                        @ = gMixNumVoices
	ldr r2, .L_080F18E4                        @ = gRingWords
	mov ip, r2
	ldr r3, .L_080F18E8                        @ = gMixEnabled
	mov sl, r3
	ldrh r0, [r7]
	cmp r4, r0
	bhs .L_080F1894
	ldr r6, .L_080F18EC                        @ = gMixVoices
	movs r1, #2
	rsbs r1, r1, #0
	mov r8, r1
	movs r5, #0x80
.L_080F1876:
	ldr r1, [r6]
	lsls r2, r4, #5
	adds r1, r2, r1
	ldrb r3, [r1]
	mov r0, r8
	ands r0, r3
	strb r0, [r1]
	ldr r0, [r6]
	adds r2, r2, r0
	strb r5, [r2, #3]
	strb r5, [r2, #2]
	adds r4, #1
	ldrh r2, [r7]
	cmp r4, r2
	blo .L_080F1876
.L_080F1894:
	movs r4, #0
	mov r3, ip
	ldr r0, [r3]
	cmp r4, r0
	bhs .L_080F18BC
	ldr r7, .L_080F18F0                        @ = gRingBufR
	ldr r6, .L_080F18F4                        @ = gRingBufL
	movs r5, #0
.L_080F18A4:
	ldr r2, [r7]
	lsls r1, r4, #2
	adds r2, r1, r2
	ldr r0, [r6]
	adds r1, r1, r0
	str r5, [r1]
	ldr r0, [r1]
	str r0, [r2]
	adds r4, #1
	ldr r0, [r3]
	cmp r4, r0
	blo .L_080F18A4
.L_080F18BC:
	movs r0, #1
	mov r3, sl
	strh r0, [r3]
	bl mixFrame
	ldr r1, .L_080F18F8                        @ = REG_SOUNDCNT_X
	movs r0, #0x80
	strb r0, [r1]
	mov r0, sb
	cmp r0, #1
	beq .L_080F1954
	cmp r0, #1
	blo .L_080F18FC
	cmp r0, #2
	beq .L_080F19A0
	b .L_080F19E2
.L_080F18DC:
	.word 0x000001FF
.L_080F18E0:
	.word gMixNumVoices
.L_080F18E4:
	.word gRingWords
.L_080F18E8:
	.word gMixEnabled
.L_080F18EC:
	.word gMixVoices
.L_080F18F0:
	.word gRingBufR
.L_080F18F4:
	.word gRingBufL
.L_080F18F8:
	.word REG_SOUNDCNT_X
.L_080F18FC:
	ldr r1, .L_080F1938                        @ = REG_SOUNDCNT_H
	ldr r2, .L_080F193C                        @ = 0x0000A90E
	adds r0, r2, #0
	strh r0, [r1]
	ldr r4, .L_080F1940                        @ = REG_FIFO_A
	movs r2, #0
	str r2, [r4]
	ldr r3, .L_080F1944                        @ = REG_FIFO_B
	str r2, [r3]
	adds r1, #0x3a
	ldr r0, .L_080F1948                        @ = gRingBufR
	ldr r0, [r0]
	str r0, [r1]
	adds r1, #0xc
	ldr r0, .L_080F194C                        @ = gRingBufL
	ldr r0, [r0]
	str r0, [r1]
	ldr r0, .L_080F1950                        @ = REG_DMA1DAD
	str r4, [r0]
	adds r0, #0xc
	str r3, [r0]
	subs r1, #2
	movs r3, #0xb6
	lsls r3, r3, #8
	adds r0, r3, #0
	strh r0, [r1]
	str r2, [sp]
	str r2, [sp]
	b .L_080F1972
	.hword 0x0000
.L_080F1938:
	.word REG_SOUNDCNT_H
.L_080F193C:
	.word 0x0000A90E
.L_080F1940:
	.word REG_FIFO_A
.L_080F1944:
	.word REG_FIFO_B
.L_080F1948:
	.word gRingBufR
.L_080F194C:
	.word gRingBufL
.L_080F1950:
	.word REG_DMA1DAD
.L_080F1954:
	ldr r1, .L_080F1984                        @ = REG_SOUNDCNT_H
	ldr r2, .L_080F1988                        @ = 0x0000B80E
	adds r0, r2, #0
	strh r0, [r1]
	ldr r0, .L_080F198C                        @ = REG_FIFO_A
	movs r2, #0
	str r2, [r0]
	ldr r3, .L_080F1990                        @ = REG_FIFO_B
	str r2, [r3]
	adds r1, #0x46
	ldr r0, .L_080F1994                        @ = gRingBufR
	ldr r0, [r0]
	str r0, [r1]
	ldr r0, .L_080F1998                        @ = REG_DMA2DAD
	str r3, [r0]
.L_080F1972:
	ldr r1, .L_080F199C                        @ = REG_DMA2CNT_H
	movs r3, #0xf6
	lsls r3, r3, #8
	adds r0, r3, #0
	strh r0, [r1]
	str r2, [sp]
	str r2, [sp]
	b .L_080F19E2
	.hword 0x0000
.L_080F1984:
	.word REG_SOUNDCNT_H
.L_080F1988:
	.word 0x0000B80E
.L_080F198C:
	.word REG_FIFO_A
.L_080F1990:
	.word REG_FIFO_B
.L_080F1994:
	.word gRingBufR
.L_080F1998:
	.word REG_DMA2DAD
.L_080F199C:
	.word REG_DMA2CNT_H
.L_080F19A0:
	ldr r1, .L_080F1A10                        @ = REG_SOUNDCNT_H
	ldr r2, .L_080F1A14                        @ = 0x0000BB0E
	adds r0, r2, #0
	strh r0, [r1]
	ldr r5, .L_080F1A18                        @ = REG_FIFO_A
	movs r3, #0
	str r3, [r5]
	ldr r4, .L_080F1A1C                        @ = REG_FIFO_B
	str r3, [r4]
	ldr r2, .L_080F1A20                        @ = REG_DMA1SAD
	ldr r0, .L_080F1A24                        @ = gRingBufR
	ldr r1, [r0]
	str r1, [r2]
	ldr r0, .L_080F1A28                        @ = REG_DMA2SAD
	str r1, [r0]
	subs r0, #8
	str r5, [r0]
	adds r0, #0xc
	str r4, [r0]
	ldr r1, .L_080F1A2C                        @ = REG_DMA1CNT_H
	movs r2, #0xb6
	lsls r2, r2, #8
	adds r0, r2, #0
	strh r0, [r1]
	str r3, [sp]
	str r3, [sp]
	adds r1, #0xc
	movs r2, #0xf6
	lsls r2, r2, #8
	adds r0, r2, #0
	strh r0, [r1]
	str r3, [sp]
	str r3, [sp]
.L_080F19E2:
	ldr r1, .L_080F1A30                        @ = REG_SOUNDCNT_L
	ldr r3, .L_080F1A34                        @ = 0x0000BB77
	adds r0, r3, #0
	strh r0, [r1]
	ldr r2, .L_080F1A38                        @ = REG_TM0CNT_H
	movs r0, #0
	strh r0, [r2]
	adds r1, #0x80
	ldr r0, .L_080F1A3C                        @ = gMixTimerReload
	ldr r0, [r0]
	rsbs r0, r0, #0
	strh r0, [r1]
	movs r0, #0x80
	strh r0, [r2]
	add sp, #4
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F1A10:
	.word REG_SOUNDCNT_H
.L_080F1A14:
	.word 0x0000BB0E
.L_080F1A18:
	.word REG_FIFO_A
.L_080F1A1C:
	.word REG_FIFO_B
.L_080F1A20:
	.word REG_DMA1SAD
.L_080F1A24:
	.word gRingBufR
.L_080F1A28:
	.word REG_DMA2SAD
.L_080F1A2C:
	.word REG_DMA1CNT_H
.L_080F1A30:
	.word REG_SOUNDCNT_L
.L_080F1A34:
	.word 0x0000BB77
.L_080F1A38:
	.word REG_TM0CNT_H
.L_080F1A3C:
	.word gMixTimerReload

@ --------------------------------------------------------------------------------------------------
@ mixFrame  (080F1A40, Thumb)
@   void mixFrame(void)                         // called once per frame by sndMain
@   {
@       if (!gMixEnabled) return;
@       const MixFn fn[4] = { mixVoiceDirect, mixVoiceInterp, mixVoicePoint, mixFilter };
@       target = min((gMixSamplesPerFrame + 259) >> 2, gRingWords);          // words to keep queued
@       queued = (gRingWritePos - gRingReadPos) mod gRingWords;
@       todo   = target > queued ? target - queued : 0;
@       c = (u8)gMixFilter.cutoff;
@       if (gMixFilterPrev >= 0 && (s8)c < 0) gMixFilter.state = 0;                 // became high-pass
@       if (gMixFilterPrev <  0 && (s8)c >= 0) gMixFilter.state = last accumulator sample;  // became low-pass
@       gMixFilterPrev = c;
@       while (todo) {
@           n = min(todo, gMixBlockLen / 4);
@           mixReverb(n);                                  // accumulator := echo
@           silent = 1; wet = 0;
@           for each voice v with (v->flags & 9) == 9 {   // active + wet
@               silent = 0; wet = 1;
@               gMixVolBoost = c & 0x80 ? ((256 - c) * v->vol * gFilterGain) >> 7 : 0;
@               (!(v->flags & 2) ? mixVoiceDirect : v->flags & 4 ? mixVoicePoint : mixVoiceInterp)(n, v);
@           }
@           if (wet) mixFilter(n, &gMixFilter);            // filter = echo + wet voices
@           gMixVolBoost = 0;
@           for each voice v with (v->flags & 9) == 1 { silent = 0; mix as above }   // dry voices
@           gClipTable[0x1FF] = silent ? 0 : -1;           // lets a decaying echo settle at 0, not -1
@           mixDownmix(n);
@           gRingWritePos = (gRingWritePos + n) mod gRingWords;
@           gMixVcount = REG_VCOUNT;  todo -= n;
@       }
@   }
@ --------------------------------------------------------------------------------------------------
	.global mixFrame
mixFrame:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0x20
	ldr r0, .L_080F1AC8                        @ = gMixEnabled
	ldrh r0, [r0]
	cmp r0, #0
	bne .L_080F1A56
	b .L_080F1CDA
.L_080F1A56:
	ldr r0, .L_080F1ACC                        @ = mixVoiceDirect
	str r0, [sp]
	movs r0, #1
	ldr r1, [sp]
	orrs r1, r0
	str r1, [sp]
	ldr r2, .L_080F1AD0                        @ = mixVoiceInterp
	orrs r2, r0
	str r2, [sp, #4]
	ldr r1, .L_080F1AD4                        @ = mixVoicePoint
	orrs r1, r0
	str r1, [sp, #8]
	ldr r2, .L_080F1AD8                        @ = mixFilter
	orrs r2, r0
	str r2, [sp, #0xc]
	ldr r0, .L_080F1ADC                        @ = gMixVoices
	ldr r0, [r0]
	str r0, [sp, #0x14]
	ldr r0, .L_080F1AE0                        @ = gMixSamplesPerFrame
	ldr r0, [r0]
	ldr r1, .L_080F1AE4                        @ = 0x00000103
	adds r0, r0, r1
	lsrs r3, r0, #2
	ldr r4, .L_080F1AE8                        @ = gRingWords
	ldr r0, [r4]
	cmp r3, r0
	bls .L_080F1A8E
	ldr r3, [r4]
.L_080F1A8E:
	ldr r0, .L_080F1AEC                        @ = gRingWritePos
	ldr r1, .L_080F1AF0                        @ = gRingReadPos
	ldr r2, [r0]
	ldr r0, [r1]
	subs r2, r2, r0
	cmp r2, #0
	bge .L_080F1AA0
	ldr r0, [r4]
	adds r2, r2, r0
.L_080F1AA0:
	movs r4, #0
	cmp r3, r2
	ble .L_080F1AA8
	subs r4, r3, r2
.L_080F1AA8:
	ldr r2, .L_080F1AF4                        @ = gMixFilter
	ldrb r0, [r2]
	mov r8, r0
	ldr r0, .L_080F1AF8                        @ = gMixFilterPrev
	movs r1, #0
	ldrsb r1, [r0, r1]
	adds r3, r0, #0
	cmp r1, #0
	blt .L_080F1AFC
	mov r1, r8
	lsls r0, r1, #0x18
	cmp r0, #0
	bge .L_080F1B1E
	movs r0, #0
	str r0, [r2, #4]
	b .L_080F1B1C
.L_080F1AC8:
	.word gMixEnabled
.L_080F1ACC:
	.word mixVoiceDirect
.L_080F1AD0:
	.word mixVoiceInterp
.L_080F1AD4:
	.word mixVoicePoint
.L_080F1AD8:
	.word mixFilter
.L_080F1ADC:
	.word gMixVoices
.L_080F1AE0:
	.word gMixSamplesPerFrame
.L_080F1AE4:
	.word 0x00000103
.L_080F1AE8:
	.word gRingWords
.L_080F1AEC:
	.word gRingWritePos
.L_080F1AF0:
	.word gRingReadPos
.L_080F1AF4:
	.word gMixFilter
.L_080F1AF8:
	.word gMixFilterPrev
.L_080F1AFC:
	mov r1, r8
	lsls r0, r1, #0x18
	cmp r0, #0
	blt .L_080F1B1E
	ldr r0, .L_080F1BB4                        @ = gMixBlockLen
	ldr r0, [r0]
	ldr r1, .L_080F1BB8                        @ = gMixBufPtr
	ldr r1, [r1]
	lsls r0, r0, #2
	adds r0, r0, r1
	adds r1, r0, #0
	subs r1, #8
	ldr r1, [r1]
	str r1, [r2, #4]
	subs r0, #4
	ldr r0, [r0]
.L_080F1B1C:
	str r0, [r2, #8]
.L_080F1B1E:
	mov r2, r8
	strb r2, [r3]
	cmp r4, #0
	bne .L_080F1B28
	b .L_080F1CDA
.L_080F1B28:
	ldr r0, .L_080F1BB4                        @ = gMixBlockLen
	ldr r0, [r0]
	lsrs r6, r0, #2
	cmp r6, r4
	bls .L_080F1B34
	adds r6, r4, #0
.L_080F1B34:
	ldr r1, .L_080F1BBC                        @ = mixReverb
	movs r0, #1
	orrs r1, r0
	adds r0, r6, #0
	bl _call_via_r1
	movs r0, #1
	str r0, [sp, #0x10]
	movs r1, #0
	str r1, [sp, #0x18]
	ldr r0, .L_080F1BC0                        @ = gMixFilter
	ldrb r0, [r0]
	mov r8, r0
	mov sb, r1
	movs r7, #0
	subs r4, r4, r6
	str r4, [sp, #0x1c]
	ldr r2, .L_080F1BC4                        @ = gMixNumVoices
	ldrh r2, [r2]
	cmp r7, r2
	bhs .L_080F1BFC
	movs r0, #0x80
	lsls r0, r0, #1
	mov r1, r8
	subs r1, r0, r1
	mov sl, r1
	ldr r5, [sp, #0x14]
	adds r4, r5, #0
.L_080F1B6C:
	ldrb r1, [r5]
	movs r0, #9
	ands r0, r1
	cmp r0, #9
	bne .L_080F1BEE
	movs r2, #0
	str r2, [sp, #0x10]
	movs r0, #1
	str r0, [sp, #0x18]
	mov r1, r8
	lsls r0, r1, #0x18
	cmp r0, #0
	bge .L_080F1B98
	ldrb r0, [r5, #1]
	mov r1, sl
	muls r1, r0, r1
	ldr r0, .L_080F1BC8                        @ = gFilterGain
	ldrb r0, [r0]
	muls r0, r1, r0
	lsls r0, r0, #9
	lsrs r0, r0, #0x10
	mov sb, r0
.L_080F1B98:
	ldr r0, .L_080F1BCC                        @ = gMixVolBoost
	mov r2, sb
	strh r2, [r0]
	ldrb r1, [r5]
	movs r0, #2
	ands r0, r1
	cmp r0, #0
	bne .L_080F1BD0
	adds r0, r6, #0
	adds r1, r4, #0
	ldr r2, [sp]
	bl _call_via_r2
	b .L_080F1BEE
.L_080F1BB4:
	.word gMixBlockLen
.L_080F1BB8:
	.word gMixBufPtr
.L_080F1BBC:
	.word mixReverb
.L_080F1BC0:
	.word gMixFilter
.L_080F1BC4:
	.word gMixNumVoices
.L_080F1BC8:
	.word gFilterGain
.L_080F1BCC:
	.word gMixVolBoost
.L_080F1BD0:
	movs r0, #4
	ands r0, r1
	cmp r0, #0
	beq .L_080F1BE4
	adds r0, r6, #0
	adds r1, r4, #0
	ldr r2, [sp, #8]
	bl _call_via_r2
	b .L_080F1BEE
.L_080F1BE4:
	adds r0, r6, #0
	adds r1, r4, #0
	ldr r2, [sp, #4]
	bl _call_via_r2
.L_080F1BEE:
	adds r5, #0x20
	adds r4, #0x20
	adds r7, #1
	ldr r0, .L_080F1C40                        @ = gMixNumVoices
	ldrh r0, [r0]
	cmp r7, r0
	blo .L_080F1B6C
.L_080F1BFC:
	ldr r1, [sp, #0x18]
	cmp r1, #0
	beq .L_080F1C0C
	adds r0, r6, #0
	ldr r1, .L_080F1C44                        @ = gMixFilter
	ldr r2, [sp, #0xc]
	bl _call_via_r2
.L_080F1C0C:
	ldr r1, .L_080F1C48                        @ = gMixVolBoost
	movs r0, #0
	strh r0, [r1]
	movs r7, #0
	ldr r0, .L_080F1C40                        @ = gMixNumVoices
	ldrh r0, [r0]
	cmp r7, r0
	bhs .L_080F1C76
	ldr r4, [sp, #0x14]
.L_080F1C1E:
	ldrb r1, [r4]
	movs r0, #9
	ands r0, r1
	cmp r0, #1
	bne .L_080F1C6A
	movs r2, #0
	str r2, [sp, #0x10]
	movs r0, #2
	ands r0, r1
	cmp r0, #0
	bne .L_080F1C4C
	adds r0, r6, #0
	adds r1, r4, #0
	ldr r2, [sp]
	bl _call_via_r2
	b .L_080F1C6A
.L_080F1C40:
	.word gMixNumVoices
.L_080F1C44:
	.word gMixFilter
.L_080F1C48:
	.word gMixVolBoost
.L_080F1C4C:
	movs r0, #4
	ands r0, r1
	cmp r0, #0
	beq .L_080F1C60
	adds r0, r6, #0
	adds r1, r4, #0
	ldr r2, [sp, #8]
	bl _call_via_r2
	b .L_080F1C6A
.L_080F1C60:
	adds r0, r6, #0
	adds r1, r4, #0
	ldr r2, [sp, #4]
	bl _call_via_r2
.L_080F1C6A:
	adds r4, #0x20
	adds r7, #1
	ldr r0, .L_080F1CA4                        @ = gMixNumVoices
	ldrh r0, [r0]
	cmp r7, r0
	blo .L_080F1C1E
.L_080F1C76:
	ldr r0, .L_080F1CA8                        @ = gClipTable
	movs r1, #0
	ldr r2, [sp, #0x10]
	cmp r2, #0
	bne .L_080F1C86
	movs r2, #1
	rsbs r2, r2, #0
	adds r1, r2, #0
.L_080F1C86:
	ldr r2, .L_080F1CAC                        @ = 0x000001FF
	adds r0, r0, r2
	strb r1, [r0]
	ldr r1, .L_080F1CB0                        @ = mixDownmix
	movs r0, #1
	orrs r1, r0
	adds r0, r6, #0
	bl _call_via_r1
	ldr r0, .L_080F1CB4                        @ = gRingWritePos
	ldr r0, [r0]
	adds r1, r0, r6
	ldr r2, .L_080F1CB8                        @ = gRingWords
	b .L_080F1CC0
	.hword 0x0000
.L_080F1CA4:
	.word gMixNumVoices
.L_080F1CA8:
	.word gClipTable
.L_080F1CAC:
	.word 0x000001FF
.L_080F1CB0:
	.word mixDownmix
.L_080F1CB4:
	.word gRingWritePos
.L_080F1CB8:
	.word gRingWords
.L_080F1CBC:
	ldr r0, [r2]
	subs r1, r1, r0
.L_080F1CC0:
	ldr r0, [r2]
	cmp r1, r0
	bhs .L_080F1CBC
	ldr r0, .L_080F1CEC                        @ = gRingWritePos
	str r1, [r0]
	ldr r4, [sp, #0x1c]
	ldr r1, .L_080F1CF0                        @ = gMixVcount
	ldr r0, .L_080F1CF4                        @ = REG_VCOUNT
	ldrh r0, [r0]
	strh r0, [r1]
	cmp r4, #0
	beq .L_080F1CDA
	b .L_080F1B28
.L_080F1CDA:
	add sp, #0x20
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F1CEC:
	.word gRingWritePos
.L_080F1CF0:
	.word gMixVcount
.L_080F1CF4:
	.word REG_VCOUNT

@ --------------------------------------------------------------------------------------------------
@ mixDmaStop  (080F1CF8, Thumb)
@   void mixDmaStop(void)   (not called)  { gMixEnabled = 0; stop DMA1 (unless mode 1) and DMA2, re-arm their
@   FIFO timing bits; }
@ --------------------------------------------------------------------------------------------------
	.global mixDmaStop
mixDmaStop:
	push {lr}
	sub sp, #4
	ldr r1, .L_080F1D40                        @ = gMixEnabled
	movs r0, #0
	strh r0, [r1]
	ldr r0, .L_080F1D44                        @ = gMixMode
	ldr r0, [r0]
	cmp r0, #1
	beq .L_080F1D22
	ldr r1, .L_080F1D48                        @ = REG_DMA1CNT_L
	ldr r0, .L_080F1D4C                        @ = 0x84400004
	str r0, [r1]
	movs r0, #0
	str r0, [sp]
	movs r0, #1
	str r0, [sp]
	adds r1, #2
	movs r2, #0x80
	lsls r2, r2, #3
	adds r0, r2, #0
	strh r0, [r1]
.L_080F1D22:
	ldr r1, .L_080F1D50                        @ = REG_DMA2CNT_L
	ldr r0, .L_080F1D4C                        @ = 0x84400004
	str r0, [r1]
	movs r0, #0
	str r0, [sp]
	movs r0, #1
	str r0, [sp]
	adds r1, #2
	movs r2, #0x80
	lsls r2, r2, #3
	adds r0, r2, #0
	strh r0, [r1]
	add sp, #4
	pop {r0}
	bx r0
.L_080F1D40:
	.word gMixEnabled
.L_080F1D44:
	.word gMixMode
.L_080F1D48:
	.word REG_DMA1CNT_L
.L_080F1D4C:
	.word 0x84400004
.L_080F1D50:
	.word REG_DMA2CNT_L

@ --------------------------------------------------------------------------------------------------
@ mixSetReverb  (080F1D54, Thumb)
@   void mixSetReverb(int level, int delay, int lpShift, int hpShift)  { set gReverbLevel/Delay/LpShift/HpShift; }
@ --------------------------------------------------------------------------------------------------
	.global mixSetReverb
mixSetReverb:
	push {r4, lr}
	ldr r4, .L_080F1D6C                        @ = gReverbLevel
	str r0, [r4]
	ldr r0, .L_080F1D70                        @ = gReverbDelay
	str r1, [r0]
	ldr r0, .L_080F1D74                        @ = gReverbLpShift
	str r2, [r0]
	ldr r0, .L_080F1D78                        @ = gReverbHpShift
	str r3, [r0]
	pop {r4}
	pop {r0}
	bx r0
.L_080F1D6C:
	.word gReverbLevel
.L_080F1D70:
	.word gReverbDelay
.L_080F1D74:
	.word gReverbLpShift
.L_080F1D78:
	.word gReverbHpShift

@ --------------------------------------------------------------------------------------------------
@ voiceIsActive  (080F1D7C, Thumb)
@   int voiceIsActive(int i)  { return gMixVoices[i].flags & 1; }
@ --------------------------------------------------------------------------------------------------
	.global voiceIsActive
voiceIsActive:
	ldr r1, .L_080F1D8C                        @ = gMixVoices
	ldr r1, [r1]
	lsls r0, r0, #5
	adds r0, r0, r1
	ldrb r0, [r0]
	lsls r0, r0, #0x1f
	lsrs r0, r0, #0x1f
	bx lr
.L_080F1D8C:
	.word gMixVoices

@ --------------------------------------------------------------------------------------------------
@ mixSetFilter  (080F1D90, Thumb)
@   void mixSetFilter(int c)  { gMixFilter.cutoff = c; }      // s32; its low byte is used: <0x80 low-pass, >=0x80 high-pass
@ --------------------------------------------------------------------------------------------------
	.global mixSetFilter
mixSetFilter:
	ldr r1, .L_080F1D98                        @ = gMixFilter
	str r0, [r1]
	bx lr
	.hword 0x0000
.L_080F1D98:
	.word gMixFilter

@ --------------------------------------------------------------------------------------------------
@ mixSetFilterGain  (080F1D9C, Thumb)
@   void mixSetFilterGain(int g)  { gFilterGain = g; }        // volume boost of wet voices in high-pass mode
@ --------------------------------------------------------------------------------------------------
	.global mixSetFilterGain
mixSetFilterGain:
	ldr r1, .L_080F1DA4                        @ = gFilterGain
	strb r0, [r1]
	bx lr
	.hword 0x0000
.L_080F1DA4:
	.word gFilterGain

@ --------------------------------------------------------------------------------------------------
@ mixClearEffects  (080F1DA8, Thumb)
@   void mixClearEffects(void)
@   {   gMixFilter = {0, 0, 0}; gMixFilterPrev = 0; acc[last two words] = 0; }
@ --------------------------------------------------------------------------------------------------
	.global mixClearEffects
mixClearEffects:
	ldr r0, .L_080F1DD0                        @ = gMixFilter
	movs r2, #0
	str r2, [r0, #8]
	str r2, [r0, #4]
	str r2, [r0]
	ldr r0, .L_080F1DD4                        @ = gMixFilterPrev
	strb r2, [r0]
	ldr r0, .L_080F1DD8                        @ = gMixBlockLen
	ldr r0, [r0]
	ldr r1, .L_080F1DDC                        @ = gMixBufPtr
	ldr r1, [r1]
	lsls r0, r0, #2
	adds r0, r0, r1
	adds r1, r0, #0
	subs r1, #8
	subs r0, #4
	str r2, [r0]
	str r2, [r1]
	bx lr
	.hword 0x0000
.L_080F1DD0:
	.word gMixFilter
.L_080F1DD4:
	.word gMixFilterPrev
.L_080F1DD8:
	.word gMixBlockLen
.L_080F1DDC:
	.word gMixBufPtr

@ ==================================================================================================
@  SYNTH: channels, notes, instruments, envelopes, LFO, pitch (0x080F1DE0-0x080F3034)
@  A Synth holds up to 31 MIDI-like channels (Chan, 0x20 bytes). A Note (0x20 bytes) is a playing key;
@  sampled notes live in gNotes[gNumNotes] (8) and map 1:1 to mixer voices, PSG notes in gPsgNotes[4].
@ ==================================================================================================

@ --------------------------------------------------------------------------------------------------
@ chanLfoTick  (080F1DE0, Thumb)
@   void chanLfoTick(Synth *s, int ci)          // once per frame per channel
@   {
@       Chan *c = &s->chans[ci];
@       if (c->lfoDelayCount) { c->lfoDelayCount--; c->lfoPhase = 0; } else c->lfoPhase += c->lfoSpeed;
@       c->lfoValue = sndSineTable[c->lfoPhase >> 8] * c->modDepth >> 8;        // -127..127
@       trem = 0x80;
@       if (c->lfoType == 1) trem = clamp(0x80 + c->lfoValue, 0, 0xA0);         // tremolo
@       if (c->lfoType == 2) chanUpdatePan(s, ci);                               // auto-pan
@       c->gain = (s->volume * c->volume * c->expression * trem >> 21) & 0x7F;
@       if (c->randomKey && c->randomKeyRate) { if (!c->randomKeyCount) c->randomKeyCount = c->randomKeyRate;
@                                               c->randomKeyCount--; }
@   }
@ --------------------------------------------------------------------------------------------------
	.global chanLfoTick
chanLfoTick:
	push {r4, r5, r6, lr}
	adds r6, r0, #0
	adds r3, r1, #0
	lsls r1, r3, #5
	ldr r0, [r6, #0x18]
	adds r4, r0, r1
	ldrb r0, [r4, #0x15]
	cmp r0, #0
	beq .L_080F1DFC
	subs r0, #1
	movs r1, #0
	strb r0, [r4, #0x15]
	strh r1, [r4, #0x12]
	b .L_080F1E04
.L_080F1DFC:
	ldrh r0, [r4, #0x10]
	ldrh r1, [r4, #0x12]
	adds r0, r0, r1
	strh r0, [r4, #0x12]
.L_080F1E04:
	ldr r1, [r4, #4]
	lsls r1, r1, #0xb
	lsrs r1, r1, #0x19
	ldr r2, .L_080F1E94                        @ = sndSineTable
	ldrh r0, [r4, #0x12]
	lsrs r0, r0, #8
	lsls r0, r0, #1
	adds r0, r0, r2
	movs r2, #0
	ldrsh r0, [r0, r2]
	muls r0, r1, r0
	asrs r0, r0, #8
	strb r0, [r4, #0xd]
	movs r5, #0x80
	ldrb r1, [r4, #7]
	lsls r0, r1, #0x1a
	lsrs r0, r0, #0x1e
	cmp r0, #1
	bne .L_080F1E3E
	movs r0, #0xd
	ldrsb r0, [r4, r0]
	adds r5, r0, #0
	adds r5, #0x80
	cmp r5, #0
	bge .L_080F1E38
	movs r5, #0
.L_080F1E38:
	cmp r5, #0xa0
	ble .L_080F1E3E
	movs r5, #0xa0
.L_080F1E3E:
	lsls r0, r1, #0x1a
	lsrs r0, r0, #0x1e
	cmp r0, #2
	bne .L_080F1E4E
	adds r0, r6, #0
	adds r1, r3, #0
	bl chanUpdatePan
.L_080F1E4E:
	ldrb r1, [r6]
	ldrh r0, [r4, #2]
	lsls r0, r0, #0x12
	lsrs r0, r0, #0x19
	muls r1, r0, r1
	ldrh r0, [r4, #4]
	lsls r0, r0, #0x12
	lsrs r0, r0, #0x19
	muls r0, r1, r0
	muls r0, r5, r0
	asrs r0, r0, #0x15
	movs r1, #0x7f
	ands r0, r1
	lsls r0, r0, #0xe
	ldr r1, [r4, #8]
	ldr r2, .L_080F1E98                        @ = 0xFFE03FFF
	ands r1, r2
	orrs r1, r0
	str r1, [r4, #8]
	ldrb r0, [r4, #0x1c]
	cmp r0, #0
	beq .L_080F1E8E
	ldrb r1, [r4, #0x1d]
	cmp r1, #0
	beq .L_080F1E8E
	ldrb r0, [r4, #0x1e]
	cmp r0, #0
	bne .L_080F1E88
	strb r1, [r4, #0x1e]
.L_080F1E88:
	ldrb r0, [r4, #0x1e]
	subs r0, #1
	strb r0, [r4, #0x1e]
.L_080F1E8E:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
.L_080F1E94:
	.word sndSineTable
.L_080F1E98:
	.word 0xFFE03FFF

@ --------------------------------------------------------------------------------------------------
@ synthLfoTick  (080F1E9C, Thumb)
@   void synthLfoTick(Synth *s)  { for (i = 0; i < s->nChans; i++) chanLfoTick(s, i); }
@ --------------------------------------------------------------------------------------------------
	.global synthLfoTick
synthLfoTick:
	push {r4, r5, lr}
	adds r5, r0, #0
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	movs r4, #0
	cmp r0, #0
	beq .L_080F1EBE
.L_080F1EAA:
	adds r0, r5, #0
	adds r1, r4, #0
	bl chanLfoTick
	adds r4, #1
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r4, r0
	blo .L_080F1EAA
.L_080F1EBE:
	pop {r4, r5}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ chanReleaseAll  (080F1EC4, Thumb)
@   void chanReleaseAll(Synth *s, int ci)      // every note of the channel -> envelope state 4 (fast release)
@   {   for sampled and PSG notes with note->chan == &s->chans[ci] and active: note->envState = 4; }
@ --------------------------------------------------------------------------------------------------
	.global chanReleaseAll
chanReleaseAll:
	push {r4, r5, r6, r7, lr}
	lsls r1, r1, #5
	ldr r0, [r0, #0x18]
	adds r4, r0, r1
	movs r3, #0
	ldr r0, .L_080F1F28                        @ = gNumNotes
	ldr r7, .L_080F1F2C                        @ = gPsgNotes
	ldrh r1, [r0]
	cmp r3, r1
	bhs .L_080F1EFC
	ldr r6, .L_080F1F30                        @ = gNotes
	movs r5, #4
	adds r2, r0, #0
.L_080F1EDE:
	ldr r1, [r6]
	lsls r0, r3, #5
	adds r1, r0, r1
	ldrb r0, [r1]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F1EF4
	ldr r0, [r1, #0xc]
	cmp r0, r4
	bne .L_080F1EF4
	strb r5, [r1, #0x1c]
.L_080F1EF4:
	adds r3, #1
	ldrh r0, [r2]
	cmp r3, r0
	blo .L_080F1EDE
.L_080F1EFC:
	movs r3, #0
	movs r5, #4
	adds r2, r7, #0
	adds r2, #0xc
	ldr r1, .L_080F1F2C                        @ = gPsgNotes
.L_080F1F06:
	ldrb r0, [r1]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F1F16
	ldr r0, [r2]
	cmp r0, r4
	bne .L_080F1F16
	strb r5, [r1, #0x1c]
.L_080F1F16:
	adds r2, #0x20
	adds r1, #0x20
	adds r3, #1
	cmp r3, #3
	bls .L_080F1F06
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F1F28:
	.word gNumNotes
.L_080F1F2C:
	.word gPsgNotes
.L_080F1F30:
	.word gNotes

@ --------------------------------------------------------------------------------------------------
@ chanKillAll  (080F1F34, Thumb)
@   void chanKillAll(Synth *s, int ci)         // silence immediately
@   {   sampled notes of the channel: active = 0, voiceStop;  PSG notes: envState = 3, level = 0; }
@ --------------------------------------------------------------------------------------------------
	.global chanKillAll
chanKillAll:
	push {r4, r5, r6, lr}
	lsls r1, r1, #5
	ldr r0, [r0, #0x18]
	adds r5, r0, r1
	movs r4, #0
	ldr r0, .L_080F1FAC                        @ = gNumNotes
	ldrh r0, [r0]
	cmp r4, r0
	bhs .L_080F1F78
	movs r0, #2
	rsbs r0, r0, #0
	adds r6, r0, #0
.L_080F1F4C:
	ldr r0, .L_080F1FB0                        @ = gNotes
	ldr r1, [r0]
	lsls r0, r4, #5
	adds r1, r0, r1
	ldrb r2, [r1]
	lsls r0, r2, #0x1f
	cmp r0, #0
	beq .L_080F1F6E
	ldr r0, [r1, #0xc]
	cmp r0, r5
	bne .L_080F1F6E
	adds r0, r2, #0
	ands r0, r6
	strb r0, [r1]
	adds r0, r4, #0
	bl voiceStop
.L_080F1F6E:
	adds r4, #1
	ldr r0, .L_080F1FAC                        @ = gNumNotes
	ldrh r0, [r0]
	cmp r4, r0
	blo .L_080F1F4C
.L_080F1F78:
	movs r4, #0
	ldr r0, .L_080F1FB4                        @ = gPsgNotes
	adds r2, r0, #0
	adds r2, #0xc
	adds r1, r0, #0
	movs r6, #3
	movs r3, #0xff
.L_080F1F86:
	ldrb r0, [r1]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F1F9C
	ldr r0, [r2]
	cmp r0, r5
	bne .L_080F1F9C
	strb r6, [r1, #0x1c]
	ldr r0, [r1, #0x1c]
	ands r0, r3
	str r0, [r1, #0x1c]
.L_080F1F9C:
	adds r2, #0x20
	adds r1, #0x20
	adds r4, #1
	cmp r4, #3
	bls .L_080F1F86
	pop {r4, r5, r6}
	pop {r0}
	bx r0
.L_080F1FAC:
	.word gNumNotes
.L_080F1FB0:
	.word gNotes
.L_080F1FB4:
	.word gPsgNotes

@ --------------------------------------------------------------------------------------------------
@ synthReleaseAll  (080F1FB8, Thumb)
@   void synthReleaseAll(Synth *s)  { for each channel chanReleaseAll(s, i); }
@ --------------------------------------------------------------------------------------------------
	.global synthReleaseAll
synthReleaseAll:
	push {r4, r5, lr}
	adds r5, r0, #0
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	movs r4, #0
	cmp r0, #0
	beq .L_080F1FDA
.L_080F1FC6:
	adds r0, r5, #0
	adds r1, r4, #0
	bl chanReleaseAll
	adds r4, #1
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r4, r0
	blo .L_080F1FC6
.L_080F1FDA:
	pop {r4, r5}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ synthKillAll  (080F1FE0, Thumb)
@   void synthKillAll(Synth *s)     { for each channel chanKillAll(s, i); }
@ --------------------------------------------------------------------------------------------------
	.global synthKillAll
synthKillAll:
	push {r4, r5, lr}
	adds r5, r0, #0
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	movs r4, #0
	cmp r0, #0
	beq .L_080F2002
.L_080F1FEE:
	adds r0, r5, #0
	adds r1, r4, #0
	bl chanKillAll
	adds r4, #1
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r4, r0
	blo .L_080F1FEE
.L_080F2002:
	pop {r4, r5}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ synthSetPriority  (080F2008, Thumb)
@   void synthSetPriority(Synth *s, int p)     // song priority -> base of every channel's voice priority
@   {   s->priority = p;  for each channel chanSetPriority(s, i, 0); }
@ --------------------------------------------------------------------------------------------------
	.global synthSetPriority
synthSetPriority:
	push {r4, r5, lr}
	adds r5, r0, #0
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x13
	ldr r0, [r5, #0x14]
	movs r2, #0x1f
	ands r0, r2
	orrs r0, r1
	str r0, [r5, #0x14]
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	movs r4, #0
	cmp r0, #0
	beq .L_080F203A
.L_080F2024:
	adds r0, r5, #0
	adds r1, r4, #0
	movs r2, #0
	bl chanSetPriority
	adds r4, #1
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r4, r0
	blo .L_080F2024
.L_080F203A:
	pop {r4, r5}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ chanReset  (080F2040, Thumb)
@   void chanReset(Chan *c)
@   {   flags (bits 0-1) = 0; program = 0; bankSelect = 0; volume = 100; pan = 64; expression = 127; field6 = 0;
@       modDepth = 0; lfoType = 0; vibRange = 1; lfoSpeed = 0x3C00; lfoPhase = 0; lfoDelay = lfoDelayCount = 0;
@       lfoValue = 0; bend = 0x2000; bendRange = 2; priority = 0; wet = invert = 0;
@       randomPitchBase = randomPitchCur = 0x100; randomPitchRange = 0; randomKey = randomKeyRate = randomKeyCount = 0; }
@ --------------------------------------------------------------------------------------------------
	.global chanReset
chanReset:
	push {r4, r5, lr}
	ldrb r2, [r0]
	movs r1, #2
	rsbs r1, r1, #0
	ands r1, r2
	movs r2, #3
	rsbs r2, r2, #0
	ands r1, r2
	strb r1, [r0]
	ldrh r2, [r0]
	ldr r1, .L_080F20FC                        @ = 0xFFFFFE03
	ands r1, r2
	strh r1, [r0]
	ldr r1, [r0]
	ldr r2, .L_080F2100                        @ = 0xFF8001FF
	ands r1, r2
	str r1, [r0]
	ldrh r2, [r0, #2]
	ldr r1, .L_080F2104                        @ = 0xFFFFC07F
	ands r1, r2
	movs r3, #0xc8
	lsls r3, r3, #6
	adds r2, r3, #0
	orrs r1, r2
	strh r1, [r0, #2]
	ldrb r2, [r0, #4]
	movs r1, #0x80
	rsbs r1, r1, #0
	ands r1, r2
	movs r2, #0x40
	orrs r1, r2
	strb r1, [r0, #4]
	ldrh r1, [r0, #4]
	movs r5, #0xfe
	lsls r5, r5, #6
	adds r2, r5, #0
	orrs r1, r2
	strh r1, [r0, #4]
	ldrh r2, [r0, #6]
	ldr r1, .L_080F2108                        @ = 0xFFFFF01F
	ands r1, r2
	strh r1, [r0, #6]
	ldr r1, [r0, #4]
	ldr r2, .L_080F210C                        @ = 0xFFE03FFF
	ands r1, r2
	str r1, [r0, #4]
	ldrb r2, [r0, #7]
	movs r1, #0x31
	rsbs r1, r1, #0
	ands r1, r2
	strb r1, [r0, #7]
	movs r4, #0
	movs r1, #1
	strb r1, [r0, #0xc]
	movs r3, #0
	movs r1, #0xf0
	lsls r1, r1, #6
	strh r1, [r0, #0x10]
	strh r4, [r0, #0x12]
	strb r3, [r0, #0x14]
	strb r3, [r0, #0x15]
	strb r3, [r0, #0xd]
	ldrh r2, [r0, #8]
	ldr r1, .L_080F2110                        @ = 0xFFFFC000
	ands r1, r2
	movs r5, #0x80
	lsls r5, r5, #6
	adds r2, r5, #0
	orrs r1, r2
	strh r1, [r0, #8]
	movs r1, #2
	strb r1, [r0, #0xf]
	ldrh r2, [r0, #0xa]
	ldr r1, .L_080F2114                        @ = 0xFFFFE01F
	ands r1, r2
	strh r1, [r0, #0xa]
	ldrb r2, [r0, #3]
	movs r1, #0x41
	rsbs r1, r1, #0
	ands r1, r2
	movs r2, #0x7f
	ands r1, r2
	strb r1, [r0, #3]
	movs r1, #0x80
	lsls r1, r1, #1
	strh r1, [r0, #0x1a]
	strh r1, [r0, #0x16]
	strh r4, [r0, #0x18]
	strb r3, [r0, #0x1c]
	strb r3, [r0, #0x1d]
	strb r3, [r0, #0x1e]
	pop {r4, r5}
	pop {r0}
	bx r0
.L_080F20FC:
	.word 0xFFFFFE03
.L_080F2100:
	.word 0xFF8001FF
.L_080F2104:
	.word 0xFFFFC07F
.L_080F2108:
	.word 0xFFFFF01F
.L_080F210C:
	.word 0xFFE03FFF
.L_080F2110:
	.word 0xFFFFC000
.L_080F2114:
	.word 0xFFFFE01F

@ --------------------------------------------------------------------------------------------------
@ synthInit  (080F2118, Thumb)
@   void synthInit(Synth *s, int nChans, Chan *chans)
@   {   s->volume = 100; s->transpose = 0; s->pan = 0; s->tune = 0; s->field6 = 0x1400;
@       s->freqTable = sndKeyFreqTable; s->nChans = nChans; s->chans = chans; chanReset() each;
@       s->priority = 0; s->scale[0..11] = 0; }
@ --------------------------------------------------------------------------------------------------
	.global synthInit
synthInit:
	push {r4, r5, r6, r7, lr}
	adds r6, r0, #0
	adds r7, r1, #0
	adds r3, r2, #0
	movs r1, #0
	movs r0, #0x64
	strb r0, [r6]
	strb r1, [r6, #1]
	strb r1, [r6, #2]
	strh r1, [r6, #4]
	movs r0, #0xa0
	lsls r0, r0, #5
	strh r0, [r6, #6]
	ldr r0, .L_080F2180                        @ = sndKeyFreqTable
	str r0, [r6, #0xc]
	movs r0, #0x1f
	adds r1, r7, #0
	ands r1, r0
	ldrb r2, [r6, #0x14]
	movs r0, #0x20
	rsbs r0, r0, #0
	ands r0, r2
	orrs r0, r1
	strb r0, [r6, #0x14]
	str r3, [r6, #0x18]
	movs r5, #0
	cmp r5, r7
	bhs .L_080F2160
	adds r4, r3, #0
.L_080F2152:
	adds r0, r4, #0
	bl chanReset
	adds r4, #0x20
	adds r5, #1
	cmp r5, r7
	blo .L_080F2152
.L_080F2160:
	ldr r0, [r6, #0x14]
	movs r1, #0x1f
	ands r0, r1
	str r0, [r6, #0x14]
	movs r5, #0
	adds r1, r6, #0
	adds r1, #0x1c
	movs r2, #0
.L_080F2170:
	adds r0, r1, r5
	strb r2, [r0]
	adds r5, #1
	cmp r5, #0xb
	bls .L_080F2170
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
.L_080F2180:
	.word sndKeyFreqTable

@ --------------------------------------------------------------------------------------------------
@ synthSetBank  (080F2184, Thumb)
@   void synthSetBank(Synth *s, Instrument **bank)  { s->bank = bank; }
@ --------------------------------------------------------------------------------------------------
	.global synthSetBank
synthSetBank:
	str r1, [r0, #0x10]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ noteCalcPitch  (080F2188, Thumb)
@   u32 noteCalcPitch(Note *n)                  // returns the playback frequency (Hz units of sndKeyFreqTable)
@   {
@       if (n->inst->type == 'F') return 0;          // fixed: play at the sample's own rate
@       Synth *s = n->synth;  Chan *c = n->chan;  f = n->freq;
@       if (c->flags & 2) return f;                 // "no pitch modifiers" (nothing sets this flag)
@       if (c->randomKey && c->randomKeyRate && c->randomKeyCount == 0) {           // re-randomise held note
@           k = n->key + s->transpose + sndRandom(2*c->randomKey + 1) - c->randomKey;
@           k += s->scale[k mod 12]; wrap k into 0..127 by octaves;
@           n->freq = f = synthKeyToFreq(s, k); recompute n->bendDown, n->bendUp, n->vibSpan;
@       }
@       if (c->bend != 0x2000) {                     // exponential interpolation across the bend span
@           b = c->bend;  span = b < 0x2000 ? n->bendDown : n->bendUp;
@           if (b < 0x2000) f -= span; else b -= 0x2000;
@           q = b / 682;  r = b % 682;               // 682 = 8192/12
@           f += span * (T[q] + (T[q+1] - T[q]) * r / 682) >> 16;          // T = sndSemitoneTable
@       }
@       if (s->tune) {                               // s->tune = semitones in 8.8
@           k = s->tune >> 8 (signed);  while (k > 11) { f <<= 1; k -= 12; }  while (k < 0) { f >>= 1; k += 12; }
@           f += f * (T[k] + ((T[k+1] - T[k]) * (s->tune & 0xFF) >> 8)) >> 16;
@       }
@       if (c->lfoType == 0) f += c->lfoValue * n->vibSpan >> 5;            // vibrato
@       if (c->randomPitchCur != 0x100) f = f * c->randomPitchCur >> 8;
@       return f;
@   }
@ --------------------------------------------------------------------------------------------------
	.global noteCalcPitch
noteCalcPitch:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	adds r7, r0, #0
	ldr r0, [r7, #4]
	ldrb r0, [r0]
	cmp r0, #0x46
	bne .L_080F21A0
	movs r0, #0
	b .L_080F2354
.L_080F21A0:
	ldr r0, [r7, #8]
	mov sl, r0
	ldr r1, [r7, #0xc]
	mov sb, r1
	ldr r0, [r7]
	lsrs r6, r0, #0xf
	ldrb r0, [r1]
	lsls r0, r0, #0x1e
	cmp r0, #0
	bge .L_080F21B6
	b .L_080F2352
.L_080F21B6:
	mov r2, sb
	ldrb r4, [r2, #0x1c]
	cmp r4, #0
	beq .L_080F2264
	ldrb r0, [r2, #0x1d]
	cmp r0, #0
	beq .L_080F2264
	ldrb r0, [r2, #0x1e]
	cmp r0, #0
	bne .L_080F2264
	lsls r0, r4, #1
	adds r0, #1
	bl sndRandom
	ldrb r1, [r7]
	lsrs r1, r1, #1
	adds r1, r1, r0
	subs r1, r1, r4
	mov r3, sl
	movs r0, #1
	ldrsb r0, [r3, r0]
	adds r5, r1, r0
	adds r0, r5, #0
	mov r4, sl
	adds r4, #0x1c
	cmp r5, #0
	bge .L_080F21F2
.L_080F21EC:
	adds r5, #0xc
	cmp r0, #0
	blt .L_080F21EC
.L_080F21F2:
	movs r1, #0xc
	bl __modsi3
	adds r0, r4, r0
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r5, r5, r0
	cmp r5, #0
	bge .L_080F2210
.L_080F2206:
	adds r5, #0xc
	cmp r5, #0
	blt .L_080F2206
	b .L_080F2210
.L_080F220E:
	subs r5, #0xc
.L_080F2210:
	cmp r5, #0x7f
	bgt .L_080F220E
	mov r0, sl
	adds r1, r5, #0
	bl synthKeyToFreq
	adds r6, r0, #0
	lsls r2, r6, #0xf
	ldr r0, [r7]
	ldr r1, .L_080F2280                        @ = 0x00007FFF
	ands r0, r1
	orrs r0, r2
	str r0, [r7]
	mov r0, sb
	ldrb r4, [r0, #0xf]
	subs r1, r5, r4
	mov r0, sl
	bl synthKeyToFreq
	ldr r1, [r7]
	lsrs r1, r1, #0xf
	subs r1, r1, r0
	strh r1, [r7, #0x10]
	adds r4, r5, r4
	mov r0, sl
	adds r1, r4, #0
	bl synthKeyToFreq
	ldr r1, [r7]
	lsrs r1, r1, #0xf
	subs r0, r0, r1
	strh r0, [r7, #0x12]
	mov r2, sb
	ldrb r1, [r2, #0xc]
	adds r1, r5, r1
	mov r0, sl
	bl synthKeyToFreq
	ldr r1, [r7]
	lsrs r1, r1, #0xf
	subs r0, r0, r1
	strh r0, [r7, #0x14]
.L_080F2264:
	mov r3, sb
	ldrh r0, [r3, #8]
	lsls r0, r0, #0x12
	lsrs r5, r0, #0x12
	movs r0, #0x80
	lsls r0, r0, #6
	cmp r5, r0
	beq .L_080F22D4
	subs r0, #1
	cmp r5, r0
	bgt .L_080F2284
	ldrh r0, [r7, #0x10]
	mov r8, r0
	b .L_080F2288
.L_080F2280:
	.word 0x00007FFF
.L_080F2284:
	ldrh r1, [r7, #0x12]
	mov r8, r1
.L_080F2288:
	ldr r0, .L_080F2294                        @ = 0x00001FFF
	cmp r5, r0
	bgt .L_080F2298
	mov r2, r8
	subs r6, r6, r2
	b .L_080F229C
.L_080F2294:
	.word 0x00001FFF
.L_080F2298:
	ldr r3, .L_080F22FC                        @ = 0xFFFFE000
	adds r5, r5, r3
.L_080F229C:
	ldr r4, .L_080F2300                        @ = 0x000002AA
	adds r0, r5, #0
	adds r1, r4, #0
	bl __divsi3
	adds r2, r0, #0
	adds r0, r2, #0
	muls r0, r4, r0
	subs r3, r5, r0
	ldr r1, .L_080F2304                        @ = sndSemitoneTable
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r5, [r0]
	adds r0, r2, #1
	lsls r0, r0, #2
	adds r0, r0, r1
	ldr r0, [r0]
	subs r0, r0, r5
	muls r0, r3, r0
	adds r1, r4, #0
	bl __udivsi3
	adds r0, r5, r0
	mov r1, r8
	muls r1, r0, r1
	adds r0, r1, #0
	lsrs r0, r0, #0x10
	adds r6, r6, r0
.L_080F22D4:
	mov r2, sl
	ldrh r1, [r2, #4]
	lsls r0, r1, #0x10
	mov r3, sb
	ldrb r4, [r3, #7]
	ldrh r2, [r3, #0x1a]
	mov r8, r2
	cmp r0, #0
	beq .L_080F232A
	asrs r2, r0, #0x18
	movs r3, #0xff
	ands r3, r1
	ldr r1, .L_080F2304                        @ = sndSemitoneTable
.L_080F22EE:
	cmp r2, #0xb
	bls .L_080F230E
	cmp r2, #0
	bge .L_080F2308
	asrs r6, r6, #1
	adds r2, #0xc
	b .L_080F22EE
.L_080F22FC:
	.word 0xFFFFE000
.L_080F2300:
	.word 0x000002AA
.L_080F2304:
	.word sndSemitoneTable
.L_080F2308:
	lsls r6, r6, #1
	subs r2, #0xc
	b .L_080F22EE
.L_080F230E:
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r5, [r0]
	adds r0, r2, #1
	lsls r0, r0, #2
	adds r0, r0, r1
	ldr r0, [r0]
	subs r0, r0, r5
	muls r0, r3, r0
	lsrs r0, r0, #8
	adds r0, r5, r0
	muls r0, r6, r0
	lsrs r0, r0, #0x10
	adds r6, r6, r0
.L_080F232A:
	lsls r0, r4, #0x1a
	lsrs r0, r0, #0x1e
	cmp r0, #0
	bne .L_080F2342
	mov r3, sb
	movs r1, #0xd
	ldrsb r1, [r3, r1]
	movs r2, #0x14
	ldrsh r0, [r7, r2]
	muls r0, r1, r0
	asrs r0, r0, #5
	adds r6, r6, r0
.L_080F2342:
	movs r0, #0x80
	lsls r0, r0, #1
	cmp r8, r0
	beq .L_080F2352
	mov r3, sb
	ldrh r0, [r3, #0x1a]
	muls r0, r6, r0
	asrs r6, r0, #8
.L_080F2352:
	adds r0, r6, #0
.L_080F2354:
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ noteCalcVolume  (080F2364, Thumb)
@   int noteCalcVolume(Note *n)  { return n->chan->gain * n->velocity * (n->env >> 24) >> 14; }   // 0..127
@ --------------------------------------------------------------------------------------------------
	.global noteCalcVolume
noteCalcVolume:
	ldr r1, [r0, #0xc]
	ldr r2, [r1, #8]
	lsls r2, r2, #0xb
	lsrs r2, r2, #0x19
	ldrb r1, [r0, #1]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	muls r1, r2, r1
	ldrb r0, [r0, #0x1f]
	muls r0, r1, r0
	lsrs r0, r0, #0xe
	bx lr

@ --------------------------------------------------------------------------------------------------
@ noteEnvelopeTick  (080F237C, Thumb)
@   int noteEnvelopeTick(Note *n)              // once per frame; levels are 7.16 (0x7F0000 = full)
@   {
@       Instrument *i = n->inst;  lvl = n->env >> 8;  done = 0;
@       switch (n->env & 0xFF) {
@       case 0: lvl += i->attack;       if (lvl > 0x7EFFFF) { lvl = 0x7F0000; state = 1; }  break;
@       case 1: lvl -= i->decay;        if (lvl <= i->sustain) { lvl = i->sustain; state = 2; } break;
@       case 2: lvl -= i->sustainRate;  if (lvl > 0x7EFFFF) { lvl = 0x7F0000; break; }  goto end_check;
@       case 3: lvl -= i->release;      goto end_check;                      // note off
@       case 4: lvl -= i->release ? i->release : 0x60000;  goto end_check;   // stopped by the sequencer
@       end_check: if (lvl <= 0) { lvl = 0; done = 1; }
@       }
@       n->env = lvl << 8 | state;  return done;
@   }
@ --------------------------------------------------------------------------------------------------
	.global noteEnvelopeTick
noteEnvelopeTick:
	push {r4, r5, lr}
	movs r5, #0
	ldr r3, [r0, #4]
	adds r4, r0, #0
	adds r4, #0x1c
	ldr r1, [r0, #0x1c]
	lsrs r2, r1, #8
	ldrb r0, [r0, #0x1c]
	cmp r0, #4
	bhi .L_080F240C
	lsls r0, r0, #2
	ldr r1, .L_080F239C                        @ = 0x080F23A0
	adds r0, r0, r1
	ldr r0, [r0]
	mov pc, r0
	.hword 0x0000
.L_080F239C:
	.word 0x080F23A0
	.word .L_080F23B4
	.word .L_080F23CC
	.word .L_080F23DE
	.word .L_080F23F4
	.word .L_080F23F8
.L_080F23B4:
	ldr r0, [r3, #0x10]
	adds r2, r2, r0
	ldr r0, .L_080F23C8                        @ = 0x007EFFFF
	cmp r2, r0
	ble .L_080F240C
	movs r2, #0xfe
	lsls r2, r2, #0xf
	movs r0, #1
	strb r0, [r4]
	b .L_080F240C
.L_080F23C8:
	.word 0x007EFFFF
.L_080F23CC:
	ldr r0, [r3, #0x14]
	subs r2, r2, r0
	ldr r0, [r3, #0xc]
	cmp r2, r0
	bgt .L_080F240C
	adds r2, r0, #0
	movs r0, #2
	strb r0, [r4]
	b .L_080F240C
.L_080F23DE:
	ldr r0, [r3, #0x18]
	subs r2, r2, r0
	ldr r0, .L_080F23F0                        @ = 0x007EFFFF
	cmp r2, r0
	ble .L_080F2404
	movs r2, #0xfe
	lsls r2, r2, #0xf
	b .L_080F240C
	.hword 0x0000
.L_080F23F0:
	.word 0x007EFFFF
.L_080F23F4:
	ldr r0, [r3, #0x1c]
	b .L_080F2402
.L_080F23F8:
	ldr r0, [r3, #0x1c]
	cmp r0, #0
	bne .L_080F2402
	movs r0, #0xc0
	lsls r0, r0, #0xb
.L_080F2402:
	subs r2, r2, r0
.L_080F2404:
	cmp r2, #0
	bgt .L_080F240C
	movs r2, #0
	movs r5, #1
.L_080F240C:
	lsls r1, r2, #8
	ldrb r0, [r4]
	orrs r0, r1
	str r0, [r4]
	adds r0, r5, #0
	pop {r4, r5}
	pop {r1}
	bx r1

@ --------------------------------------------------------------------------------------------------
@ noteUpdate  (080F241C, Thumb)
@   void noteUpdate(int i)                      // once per frame per sampled note
@   {
@       Note *n = &gNotes[i];
@       if (!(n->flags & 1)) return;
@       if (!voiceIsActive(i)) { n->flags &= ~1; return; }          // one-shot sample ended
@       n->isNew = 0;
@       if (!(n->chan->flags & 2)) voiceSetPitch(i, noteCalcPitch(n));
@       voiceSetVolume(i, noteCalcVolume(n));                        // uses the level before this tick
@       if (noteEnvelopeTick(n)) { voiceStop(i); n->flags &= ~1; }
@   }
@ --------------------------------------------------------------------------------------------------
	.global noteUpdate
noteUpdate:
	push {r4, r5, lr}
	adds r5, r0, #0
	ldr r0, .L_080F2484                        @ = gNotes
	lsls r1, r5, #5
	ldr r0, [r0]
	adds r4, r0, r1
	ldrb r0, [r4]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F247E
	adds r0, r5, #0
	bl voiceIsActive
	cmp r0, #0
	beq .L_080F2474
	movs r0, #0
	strb r0, [r4, #0x17]
	ldr r0, [r4, #0xc]
	ldrb r0, [r0]
	lsls r0, r0, #0x1e
	cmp r0, #0
	blt .L_080F2456
	adds r0, r4, #0
	bl noteCalcPitch
	adds r1, r0, #0
	adds r0, r5, #0
	bl voiceSetPitch
.L_080F2456:
	adds r0, r4, #0
	bl noteCalcVolume
	adds r1, r0, #0
	adds r0, r5, #0
	bl voiceSetVolume
	adds r0, r4, #0
	bl noteEnvelopeTick
	cmp r0, #0
	beq .L_080F247E
	adds r0, r5, #0
	bl voiceStop
.L_080F2474:
	ldrb r1, [r4]
	movs r0, #2
	rsbs r0, r0, #0
	ands r0, r1
	strb r0, [r4]
.L_080F247E:
	pop {r4, r5}
	pop {r0}
	bx r0
.L_080F2484:
	.word gNotes

@ --------------------------------------------------------------------------------------------------
@ noteUpdateAll  (080F2488, Thumb)
@   void noteUpdateAll(void)  { for (i = 0; i < gNumNotes; i++) noteUpdate(i);  psgUpdateAll(); }
@ --------------------------------------------------------------------------------------------------
	.global noteUpdateAll
noteUpdateAll:
	push {r4, r5, lr}
	movs r4, #0
	ldr r0, .L_080F24B0                        @ = gNumNotes
	ldrh r1, [r0]
	cmp r4, r1
	bhs .L_080F24A4
	adds r5, r0, #0
.L_080F2496:
	adds r0, r4, #0
	bl noteUpdate
	adds r4, #1
	ldrh r0, [r5]
	cmp r4, r0
	blo .L_080F2496
.L_080F24A4:
	bl psgUpdateAll
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F24B0:
	.word gNumNotes

@ --------------------------------------------------------------------------------------------------
@ noteInit  (080F24B4, Thumb)
@   void noteInit(int count, Note *mem)  { gNumNotes = count; gNotes = mem; clear active flags; }
@ --------------------------------------------------------------------------------------------------
	.global noteInit
noteInit:
	push {r4, r5, r6, lr}
	ldr r2, .L_080F24EC                        @ = gNumNotes
	strh r0, [r2]
	ldr r0, .L_080F24F0                        @ = gNotes
	str r1, [r0]
	movs r3, #0
	ldrh r1, [r2]
	cmp r3, r1
	bhs .L_080F24E4
	adds r5, r0, #0
	movs r6, #2
	rsbs r6, r6, #0
	adds r4, r2, #0
.L_080F24CE:
	ldr r0, [r5]
	lsls r1, r3, #5
	adds r1, r1, r0
	ldrb r2, [r1]
	adds r0, r6, #0
	ands r0, r2
	strb r0, [r1]
	adds r3, #1
	ldrh r0, [r4]
	cmp r3, r0
	blo .L_080F24CE
.L_080F24E4:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F24EC:
	.word gNumNotes
.L_080F24F0:
	.word gNotes

@ --------------------------------------------------------------------------------------------------
@ noteFindPlaying  (080F24F4, Thumb)
@   int noteFindPlaying(Chan *c, int key)     // first active note of (c, key) not yet released, else -1
@ --------------------------------------------------------------------------------------------------
	.global noteFindPlaying
noteFindPlaying:
	push {r4, r5, r6, r7, lr}
	adds r6, r0, #0
	lsls r1, r1, #0x18
	lsrs r5, r1, #0x18
	ldr r1, .L_080F2534                        @ = gNotes
	ldr r2, [r1]
	movs r3, #0
	ldr r0, .L_080F2538                        @ = gNumNotes
	ldrh r0, [r0]
	cmp r3, r0
	bge .L_080F2544
	adds r7, r1, #0
	adds r4, r0, #0
.L_080F250E:
	ldrb r1, [r2]
	lsls r0, r1, #0x1f
	cmp r0, #0
	beq .L_080F253C
	ldr r0, [r2, #0xc]
	cmp r0, r6
	bne .L_080F253C
	lsrs r0, r1, #1
	cmp r0, r5
	bne .L_080F253C
	lsls r0, r3, #5
	ldr r1, [r7]
	adds r1, r1, r0
	ldrb r0, [r1, #0x1c]
	cmp r0, #3
	beq .L_080F253C
	adds r0, r3, #0
	b .L_080F2548
	.hword 0x0000
.L_080F2534:
	.word gNotes
.L_080F2538:
	.word gNumNotes
.L_080F253C:
	adds r3, #1
	adds r2, #0x20
	cmp r3, r4
	blt .L_080F250E
.L_080F2544:
	movs r0, #1
	rsbs r0, r0, #0
.L_080F2548:
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ noteFindFree  (080F2550, Thumb)
@   int noteFindFree(void)   // first inactive note slot, else -1
@ --------------------------------------------------------------------------------------------------
	.global noteFindFree
noteFindFree:
	push {lr}
	movs r2, #0
	ldr r0, .L_080F2570                        @ = gNumNotes
	ldrh r1, [r0]
	cmp r2, r1
	bge .L_080F2580
	ldr r0, .L_080F2574                        @ = gNotes
	adds r3, r1, #0
	ldr r1, [r0]
.L_080F2562:
	ldrb r0, [r1]
	lsls r0, r0, #0x1f
	cmp r0, #0
	bne .L_080F2578
	adds r0, r2, #0
	b .L_080F2584
	.hword 0x0000
.L_080F2570:
	.word gNumNotes
.L_080F2574:
	.word gNotes
.L_080F2578:
	adds r1, #0x20
	adds r2, #1
	cmp r2, r3
	blt .L_080F2562
.L_080F2580:
	movs r0, #1
	rsbs r0, r0, #0
.L_080F2584:
	pop {r1}
	bx r1

@ --------------------------------------------------------------------------------------------------
@ noteFindQuietestReleased  (080F2588, Thumb)
@   int noteFindQuietestReleased(void)          // released note (state 3) with the lowest gain*velocity, else -1
@ --------------------------------------------------------------------------------------------------
	.global noteFindQuietestReleased
noteFindQuietestReleased:
	push {r4, r5, r6, lr}
	movs r5, #1
	rsbs r5, r5, #0
	ldr r4, .L_080F25D8                        @ = 0x00003F01
	movs r3, #0
	ldr r0, .L_080F25DC                        @ = gNumNotes
	ldrh r1, [r0]
	cmp r3, r1
	bge .L_080F25CE
	ldr r0, .L_080F25E0                        @ = gNotes
	adds r6, r1, #0
	ldr r2, [r0]
.L_080F25A0:
	ldrb r0, [r2]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F25C6
	ldrb r0, [r2, #0x1c]
	cmp r0, #3
	bne .L_080F25C6
	ldr r0, [r2, #0xc]
	ldr r1, [r0, #8]
	lsls r1, r1, #0xb
	lsrs r1, r1, #0x19
	ldrb r0, [r2, #1]
	lsls r0, r0, #0x19
	lsrs r0, r0, #0x19
	muls r1, r0, r1
	cmp r1, r4
	bhs .L_080F25C6
	adds r4, r1, #0
	adds r5, r3, #0
.L_080F25C6:
	adds r2, #0x20
	adds r3, #1
	cmp r3, r6
	blt .L_080F25A0
.L_080F25CE:
	adds r0, r5, #0
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000
.L_080F25D8:
	.word 0x00003F01
.L_080F25DC:
	.word gNumNotes
.L_080F25E0:
	.word gNotes

@ --------------------------------------------------------------------------------------------------
@ noteFindQuietest  (080F25E4, Thumb)
@   int noteFindQuietest(void)   (not called)  // active note with the lowest gain*velocity
@ --------------------------------------------------------------------------------------------------
	.global noteFindQuietest
noteFindQuietest:
	push {r4, r5, r6, lr}
	movs r6, #1
	rsbs r6, r6, #0
	ldr r4, .L_080F262C                        @ = 0x00003F01
	movs r3, #0
	ldr r0, .L_080F2630                        @ = gNumNotes
	ldrh r1, [r0]
	cmp r3, r1
	bge .L_080F2624
	ldr r0, .L_080F2634                        @ = gNotes
	adds r5, r1, #0
	ldr r2, [r0]
.L_080F25FC:
	ldrb r0, [r2]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F261C
	ldr r0, [r2, #0xc]
	ldr r1, [r0, #8]
	lsls r1, r1, #0xb
	lsrs r1, r1, #0x19
	ldrb r0, [r2, #1]
	lsls r0, r0, #0x19
	lsrs r0, r0, #0x19
	muls r1, r0, r1
	cmp r1, r4
	bhs .L_080F261C
	adds r4, r1, #0
	adds r6, r3, #0
.L_080F261C:
	adds r2, #0x20
	adds r3, #1
	cmp r3, r5
	blt .L_080F25FC
.L_080F2624:
	adds r0, r6, #0
	pop {r4, r5, r6}
	pop {r1}
	bx r1
.L_080F262C:
	.word 0x00003F01
.L_080F2630:
	.word gNumNotes
.L_080F2634:
	.word gNotes

@ --------------------------------------------------------------------------------------------------
@ noteFindStealable  (080F2638, Thumb)
@   int noteFindStealable(int prio, u32 loud)   // prio of the new note, loud = its gain*velocity
@   {
@       best = -1; limit = prio;
@       for each active note n:
@           if (n->prio > limit) continue;
@           if (n->prio < limit) { limit = n->prio; best = n; continue; }       // lower priority wins
@           if (limit == prio && n->isNew && gain*vel(n) > loud) continue;     // keep louder notes started this frame
@           if (best < 0 || gain*vel(best) > gain*vel(n)) best = n;             // equal priority: quietest
@       return best;
@   }
@ --------------------------------------------------------------------------------------------------
	.global noteFindStealable
noteFindStealable:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #4
	str r1, [sp]
	lsls r0, r0, #0x18
	lsrs r5, r0, #0x18
	mov sl, r5
	movs r7, #1
	rsbs r7, r7, #0
	movs r6, #0
	ldr r0, .L_080F26CC                        @ = gNumNotes
	ldrh r0, [r0]
	cmp r6, r0
	bge .L_080F26E4
	ldr r1, .L_080F26D0                        @ = gNotes
	mov r8, r1
	mov ip, r6
	ldr r4, [r1]
	mov sb, r0
.L_080F2664:
	ldrb r0, [r4]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F26D8
	ldrb r0, [r4, #0x16]
	cmp r0, r5
	bhi .L_080F26D8
	cmp r0, r5
	bne .L_080F26D4
	cmp r5, sl
	bne .L_080F2696
	ldrb r0, [r4, #0x17]
	cmp r0, #0
	beq .L_080F2696
	ldrb r1, [r4, #1]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	ldr r0, [r4, #0xc]
	ldr r0, [r0, #8]
	lsls r0, r0, #0xb
	lsrs r0, r0, #0x19
	muls r1, r0, r1
	ldr r0, [sp]
	cmp r1, r0
	bhi .L_080F26D8
.L_080F2696:
	cmp r7, #0
	blt .L_080F26D6
	mov r1, r8
	ldr r2, [r1]
	lsls r0, r7, #5
	adds r0, r0, r2
	ldrb r1, [r0, #1]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	ldr r0, [r0, #0xc]
	ldr r0, [r0, #8]
	lsls r0, r0, #0xb
	lsrs r0, r0, #0x19
	adds r3, r1, #0
	muls r3, r0, r3
	add r2, ip
	ldrb r1, [r2, #1]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	ldr r0, [r2, #0xc]
	ldr r0, [r0, #8]
	lsls r0, r0, #0xb
	lsrs r0, r0, #0x19
	muls r1, r0, r1
	cmp r3, r1
	bls .L_080F26D8
	b .L_080F26D6
.L_080F26CC:
	.word gNumNotes
.L_080F26D0:
	.word gNotes
.L_080F26D4:
	ldrb r5, [r4, #0x16]
.L_080F26D6:
	adds r7, r6, #0
.L_080F26D8:
	movs r0, #0x20
	add ip, r0
	adds r4, #0x20
	adds r6, #1
	cmp r6, sb
	blt .L_080F2664
.L_080F26E4:
	adds r0, r7, #0
	add sp, #4
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanNoteOff  (080F26F8, Thumb)
@   void chanNoteOff(Synth *s, int ci, int key)
@   {   while ((i = noteFindPlaying(&s->chans[ci], key)) >= 0) gNotes[i].envState = 3;
@       PSG notes of this channel and key: envState = 3; }
@ --------------------------------------------------------------------------------------------------
	.global chanNoteOff
chanNoteOff:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r6, r0, #0
	lsls r2, r2, #0x18
	lsrs r5, r2, #0x18
	lsls r7, r1, #5
	adds r4, r7, #0
	ldr r0, .L_080F272C                        @ = gNotes
	mov r8, r0
.L_080F270C:
	ldr r0, [r6, #0x18]
	adds r0, r0, r4
	adds r1, r5, #0
	bl noteFindPlaying
	adds r2, r0, #0
	cmp r2, #0
	blt .L_080F2730
	lsls r0, r2, #5
	mov r2, r8
	ldr r1, [r2]
	adds r1, r1, r0
	movs r0, #3
	strb r0, [r1, #0x1c]
	b .L_080F270C
	.hword 0x0000
.L_080F272C:
	.word gNotes
.L_080F2730:
	ldr r4, .L_080F2768                        @ = gPsgNotes
	movs r0, #3
	mov r8, r0
	movs r2, #3
.L_080F2738:
	ldrb r3, [r4]
	lsls r0, r3, #0x1f
	cmp r0, #0
	beq .L_080F2754
	ldr r0, [r6, #0x18]
	adds r0, r0, r7
	ldr r1, [r4, #0xc]
	cmp r1, r0
	bne .L_080F2754
	lsrs r0, r3, #1
	cmp r0, r5
	bne .L_080F2754
	mov r0, r8
	strb r0, [r4, #0x1c]
.L_080F2754:
	subs r2, #1
	adds r4, #0x20
	cmp r2, #0
	bge .L_080F2738
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F2768:
	.word gPsgNotes

@ --------------------------------------------------------------------------------------------------
@ noteAlloc  (080F276C, Thumb)
@   int noteAlloc(Chan *c, int key, int vel)
@   {   if ((i = noteFindFree()) >= 0) return i;
@       if ((i = noteFindQuietestReleased()) >= 0) return i;
@       return noteFindStealable(c->priority, c->gain * vel); }
@ --------------------------------------------------------------------------------------------------
	.global noteAlloc
noteAlloc:
	push {r4, r5, lr}
	adds r4, r0, #0
	lsls r2, r2, #0x18
	lsrs r5, r2, #0x18
	bl noteFindFree
	cmp r0, #0
	bge .L_080F279E
	bl noteFindQuietestReleased
	cmp r0, #0
	bge .L_080F279E
	ldrh r0, [r4, #0xa]
	lsls r0, r0, #0x13
	lsrs r0, r0, #0x18
	ldr r1, [r4, #8]
	lsls r1, r1, #0xb
	lsrs r1, r1, #0x19
	muls r1, r5, r1
	bl noteFindStealable
	cmp r0, #0
	bge .L_080F279E
	movs r0, #1
	rsbs r0, r0, #0
.L_080F279E:
	pop {r4, r5}
	pop {r1}
	bx r1

@ --------------------------------------------------------------------------------------------------
@ panRightGain  (080F27A4, Thumb)
@   int panRightGain(int pan)  { return pan <= 63 ? pan * 2 : 127; }
@ --------------------------------------------------------------------------------------------------
	.global panRightGain
panRightGain:
	push {lr}
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #0x3f
	bhi .L_080F27B4
	lsls r0, r0, #0x19
	lsrs r0, r0, #0x18
	b .L_080F27B6
.L_080F27B4:
	movs r0, #0x7f
.L_080F27B6:
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ panLeftGain  (080F27BC, Thumb)
@   int panLeftGain(int pan)   { return pan >= 64 ? (127 - pan) * 2 : 127; }
@ --------------------------------------------------------------------------------------------------
	.global panLeftGain
panLeftGain:
	push {lr}
	lsls r0, r0, #0x18
	lsrs r1, r0, #0x18
	cmp r1, #0x3f
	bls .L_080F27D0
	movs r0, #0x7f
	subs r0, r0, r1
	lsls r0, r0, #0x19
	lsrs r0, r0, #0x18
	b .L_080F27D2
.L_080F27D0:
	movs r0, #0x7f
.L_080F27D2:
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ synthKeyToFreq  (080F27D8, Thumb)
@   u16 synthKeyToFreq(Synth *s, s8 key)  { if (key < 0) key = key <= -66 ? 127 : 0;  return s->freqTable[key]; }   // 128..190 count as too high
@ --------------------------------------------------------------------------------------------------
	.global synthKeyToFreq
synthKeyToFreq:
	push {lr}
	lsls r1, r1, #0x18
	lsrs r2, r1, #0x18
	cmp r1, #0
	bge .L_080F27EC
	movs r1, #0
	cmp r2, #0xbe
	bhi .L_080F27EA
	movs r1, #0x7f
.L_080F27EA:
	adds r2, r1, #0
.L_080F27EC:
	ldr r0, [r0, #0xc]
	lsls r1, r2, #1
	adds r1, r1, r0
	ldrh r0, [r1]
	pop {r1}
	bx r1

@ --------------------------------------------------------------------------------------------------
@ chanNoteOn  (080F27F8, Thumb)
@   void chanNoteOn(Synth *s, int ci, int key, int vel)
@   {
@       if (vel == 0) { chanNoteOff(s, ci, key); return; }
@       Chan *c = &s->chans[ci];
@       if (c->flags & 1) return;                                     // channel muted (no setter is used)
@       Instrument *ins = s->bank[c->program];  if (!ins) return;
@       drum = 0;
@       if (ins->type == 'R') { drum = 1; ins = ins->table[key - ins->base]; }            // drum map
@       else if (ins->type == 'S') ins = ins->table[ins->keymap[key - ins->base]];        // key split
@       if (!ins || ins->type == 'R' || ins->type == 'S') return;
@       if (ins->type == 'P' || ins->type == 'Q') { psg = 1; n = &gPsgNotes[ins->psg & 3]; }
@       else { psg = 0; if ((i = noteAlloc(c, key, vel)) < 0) return; n = &gNotes[i]; }
@       if (!drum) { k = key + s->transpose; pan = 0; }
@       else       { k = ins->key; pan = ins->pan == 127 ? 0 : ins->pan; }
@       if ((u32)k > 127) return;
@       if (!psg && ins->type == 'F') k = ins->sample->rootKey;
@       n->flags &= ~1;
@       if (c->randomKey) { k += sndRandom(2*c->randomKey + 1) - c->randomKey;  k += s->scale[k mod 12];
@                           wrap into 0..127 by octaves; }
@       n->freq = synthKeyToFreq(s, k);
@       if (psg && (ins->psg & 3) == 3) n->freq = k;                  // noise: the key selects the divider
@       n->bendDown = n->freq - synthKeyToFreq(s, k - c->bendRange);
@       n->bendUp   = synthKeyToFreq(s, k + c->bendRange) - n->freq;
@       n->vibSpan  = synthKeyToFreq(s, k + c->vibRange) - n->freq;
@       n->key = key; n->velocity = vel; n->chan = c; n->panOffset = pan; n->prio = c->priority;
@       n->isNew = 1; n->synth = s; n->env = ins->envStart << 8 | 0; n->inst = ins;
@       if (c->randomPitchRange) c->randomPitchCur = c->randomPitchBase + sndRandom(c->randomPitchRange);
@       if (psg) psgTrigger(ins->psg & 3);
@       else {
@           voiceStop(i); voiceSetSample(i, ins->sample); voiceSetVolume(i, noteCalcVolume(n));
@           p = clamp(chanGetPan(s, ci) + pan, 0, 127);
@           voiceSetPan(i, panLeftGain(p), panRightGain(p) * (c->invert ? -1 : 1));
@           voiceSetPitch(i, noteCalcPitch(n));  voiceSetNoInterp(i, ins->nointerp);
@           voiceSetWet(i, c->wet);  voiceStart(i);
@       }
@       c->lfoDelayCount = c->lfoDelay;  n->flags |= 1;
@   }
@ --------------------------------------------------------------------------------------------------
	.global chanNoteOn
chanNoteOn:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0x20
	mov sb, r0
	str r1, [sp]
	lsls r2, r2, #0x18
	lsrs r5, r2, #0x18
	lsls r3, r3, #0x18
	lsrs r3, r3, #0x18
	str r3, [sp, #4]
	cmp r3, #0
	bne .L_080F281E
	adds r2, r5, #0
	bl chanNoteOff
	b .L_080F2B50
.L_080F281E:
	ldr r0, [sp]
	lsls r1, r0, #5
	mov r2, sb
	ldr r0, [r2, #0x18]
	adds r0, r0, r1
	mov r8, r0
	ldrb r0, [r0]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F2834
	b .L_080F2B50
.L_080F2834:
	mov r3, r8
	ldrh r0, [r3]
	movs r1, #0xfe
	lsls r1, r1, #1
	ldr r2, [r2, #0x10]
	ands r1, r0
	adds r1, r1, r2
	ldr r2, [r1]
	cmp r2, #0
	bne .L_080F284A
	b .L_080F2B50
.L_080F284A:
	movs r4, #0
	ldrb r0, [r2]
	cmp r0, #0x52
	beq .L_080F285A
	cmp r0, #0x53
	beq .L_080F2866
	adds r1, r0, #0
	b .L_080F2890
.L_080F285A:
	movs r4, #1
	ldr r0, [r2]
	lsrs r0, r0, #8
	subs r0, r5, r0
	ldr r1, [r2, #4]
	b .L_080F2874
.L_080F2866:
	ldr r1, [r2]
	lsrs r1, r1, #8
	subs r1, r5, r1
	ldr r0, [r2, #4]
	adds r0, r0, r1
	ldrb r0, [r0]
	ldr r1, [r2, #8]
.L_080F2874:
	lsls r0, r0, #2
	adds r0, r0, r1
	ldr r2, [r0]
	cmp r2, #0
	bne .L_080F2880
	b .L_080F2B50
.L_080F2880:
	ldrb r1, [r2]
	adds r0, r1, #0
	subs r0, #0x52
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #1
	bhi .L_080F2890
	b .L_080F2B50
.L_080F2890:
	adds r0, r1, #0
	subs r0, #0x50
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #1
	bhi .L_080F28B4
	str r2, [sp, #0x14]
	movs r0, #1
	str r0, [sp, #0xc]
	adds r0, r2, #0
	adds r0, #0x20
	ldrb r0, [r0]
	lsls r0, r0, #0x1e
	lsrs r0, r0, #0x19
	ldr r1, .L_080F28B0                        @ = gPsgNotes
	b .L_080F28D4
.L_080F28B0:
	.word gPsgNotes
.L_080F28B4:
	str r2, [sp, #0x10]
	movs r1, #0
	str r1, [sp, #0xc]
	mov r0, r8
	adds r1, r5, #0
	ldr r2, [sp, #4]
	bl noteAlloc
	str r0, [sp, #8]
	cmp r0, #0
	bge .L_080F28CC
	b .L_080F2B50
.L_080F28CC:
	ldr r0, .L_080F28E8                        @ = gNotes
	ldr r2, [sp, #8]
	lsls r1, r2, #5
	ldr r0, [r0]
.L_080F28D4:
	adds r7, r0, r1
	cmp r4, #0
	bne .L_080F28EC
	mov r3, sb
	movs r0, #1
	ldrsb r0, [r3, r0]
	adds r6, r5, r0
	movs r0, #0
	mov sl, r0
	b .L_080F2922
.L_080F28E8:
	.word gNotes
.L_080F28EC:
	ldr r1, [sp, #0xc]
	cmp r1, #0
	beq .L_080F28F8
	ldr r2, [sp, #0x14]
	ldrb r6, [r2, #1]
	b .L_080F2900
.L_080F28F8:
	ldr r3, [sp, #0x10]
	ldrb r0, [r3, #1]
	lsls r0, r0, #0x19
	lsrs r6, r0, #0x19
.L_080F2900:
	ldr r0, [sp, #0xc]
	cmp r0, #0
	beq .L_080F2910
	ldr r1, [sp, #0x14]
	movs r2, #2
	ldrsh r1, [r1, r2]
	mov sl, r1
	b .L_080F2918
.L_080F2910:
	ldr r3, [sp, #0x10]
	movs r0, #2
	ldrsh r3, [r3, r0]
	mov sl, r3
.L_080F2918:
	mov r1, sl
	cmp r1, #0x7f
	bne .L_080F2922
	movs r2, #0
	mov sl, r2
.L_080F2922:
	cmp r6, #0x7f
	bls .L_080F2928
	b .L_080F2B50
.L_080F2928:
	ldr r3, [sp, #0xc]
	cmp r3, #0
	bne .L_080F293A
	ldr r1, [sp, #0x10]
	ldrb r0, [r1]
	cmp r0, #0x46
	bne .L_080F293A
	ldr r0, [r1, #4]
	ldr r6, [r0, #8]
.L_080F293A:
	ldrb r1, [r7]
	movs r0, #2
	rsbs r0, r0, #0
	ands r0, r1
	strb r0, [r7]
	mov r2, r8
	ldrb r4, [r2, #0x1c]
	lsls r5, r5, #1
	str r5, [sp, #0x18]
	adds r3, r7, #0
	adds r3, #0x1c
	str r3, [sp, #0x1c]
	cmp r4, #0
	beq .L_080F2994
	lsls r0, r4, #1
	adds r0, #1
	bl sndRandom
	subs r0, r0, r4
	adds r6, r6, r0
	adds r0, r6, #0
	mov r4, sb
	adds r4, #0x1c
	cmp r6, #0
	bge .L_080F2972
.L_080F296C:
	adds r0, #0xc
	cmp r0, #0
	blt .L_080F296C
.L_080F2972:
	movs r1, #0xc
	bl __modsi3
	adds r0, r4, r0
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r6, r6, r0
	cmp r6, #0
	bge .L_080F2990
.L_080F2986:
	adds r6, #0xc
	cmp r6, #0
	blt .L_080F2986
	b .L_080F2990
.L_080F298E:
	subs r6, #0xc
.L_080F2990:
	cmp r6, #0x7f
	bgt .L_080F298E
.L_080F2994:
	lsls r1, r6, #0x18
	lsrs r1, r1, #0x18
	mov r0, sb
	bl synthKeyToFreq
	lsls r0, r0, #0xf
	ldr r2, [r7]
	ldr r3, .L_080F2A54                        @ = 0x00007FFF
	ands r2, r3
	orrs r2, r0
	str r2, [r7]
	ldr r0, [sp, #0xc]
	cmp r0, #0
	beq .L_080F29C8
	ldr r0, [sp, #0x14]
	adds r0, #0x20
	ldrb r0, [r0]
	lsls r0, r0, #0x1e
	lsrs r0, r0, #0x1e
	cmp r0, #3
	bne .L_080F29C8
	lsls r1, r6, #0xf
	adds r0, r3, #0
	ands r0, r2
	orrs r0, r1
	str r0, [r7]
.L_080F29C8:
	mov r1, r8
	ldrb r4, [r1, #0xf]
	subs r1, r6, r4
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	mov r0, sb
	bl synthKeyToFreq
	ldr r1, [r7]
	lsrs r1, r1, #0xf
	subs r1, r1, r0
	movs r5, #0
	strh r1, [r7, #0x10]
	adds r4, r4, r6
	lsls r4, r4, #0x18
	lsrs r4, r4, #0x18
	mov r0, sb
	adds r1, r4, #0
	bl synthKeyToFreq
	ldr r1, [r7]
	lsrs r1, r1, #0xf
	subs r0, r0, r1
	strh r0, [r7, #0x12]
	mov r2, r8
	ldrb r1, [r2, #0xc]
	adds r1, r1, r6
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	mov r0, sb
	bl synthKeyToFreq
	ldr r1, [r7]
	lsrs r1, r1, #0xf
	subs r0, r0, r1
	strh r0, [r7, #0x14]
	ldrb r1, [r7]
	movs r3, #1
	adds r0, r3, #0
	ands r0, r1
	ldr r1, [sp, #0x18]
	orrs r0, r1
	strb r0, [r7]
	movs r0, #0x7f
	ldr r1, [sp, #4]
	ands r1, r0
	ldrb r2, [r7, #1]
	movs r0, #0x80
	rsbs r0, r0, #0
	ands r0, r2
	orrs r0, r1
	strb r0, [r7, #1]
	mov r2, r8
	str r2, [r7, #0xc]
	mov r0, sl
	strh r0, [r7, #0x18]
	ldrh r0, [r2, #0xa]
	lsrs r0, r0, #5
	strb r0, [r7, #0x16]
	strb r3, [r7, #0x17]
	mov r1, sb
	str r1, [r7, #8]
	ldr r2, [sp, #0x1c]
	strb r5, [r7, #0x1c]
	ldr r3, [sp, #0xc]
	cmp r3, #0
	beq .L_080F2A58
	ldr r0, [sp, #0x14]
	ldr r1, [r0, #8]
	b .L_080F2A5C
.L_080F2A54:
	.word 0x00007FFF
.L_080F2A58:
	ldr r3, [sp, #0x10]
	ldr r1, [r3, #8]
.L_080F2A5C:
	lsls r1, r1, #8
	ldrb r0, [r2]
	orrs r0, r1
	str r0, [r2]
	ldr r0, [sp, #0xc]
	cmp r0, #0
	bne .L_080F2A70
	ldr r1, [sp, #0x10]
	str r1, [r7, #4]
	b .L_080F2A74
.L_080F2A70:
	ldr r2, [sp, #0x14]
	str r2, [r7, #4]
.L_080F2A74:
	mov r3, r8
	ldrh r0, [r3, #0x18]
	cmp r0, #0
	beq .L_080F2A88
	bl sndRandom
	mov r2, r8
	ldrh r1, [r2, #0x16]
	adds r1, r1, r0
	strh r1, [r2, #0x1a]
.L_080F2A88:
	ldr r3, [sp, #0xc]
	cmp r3, #0
	beq .L_080F2A9E
	ldr r0, [sp, #0x14]
	adds r0, #0x20
	ldrb r0, [r0]
	lsls r0, r0, #0x1e
	lsrs r0, r0, #0x1e
	bl psgTrigger
	b .L_080F2B42
.L_080F2A9E:
	ldr r0, [sp, #8]
	bl voiceStop
	ldr r0, [sp, #0x10]
	ldr r1, [r0, #4]
	ldr r0, [sp, #8]
	bl voiceSetSample
	adds r0, r7, #0
	bl noteCalcVolume
	adds r1, r0, #0
	ldr r0, [sp, #8]
	bl voiceSetVolume
	mov r1, r8
	ldrb r0, [r1, #3]
	lsrs r0, r0, #7
	movs r6, #1
	cmp r0, #0
	beq .L_080F2ACA
	subs r6, #2
.L_080F2ACA:
	mov r0, sb
	ldr r1, [sp]
	bl chanGetPan
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	add sl, r0
	mov r2, sl
	cmp r2, #0
	bge .L_080F2AE2
	movs r3, #0
	mov sl, r3
.L_080F2AE2:
	mov r0, sl
	cmp r0, #0x7f
	ble .L_080F2AEC
	movs r1, #0x7f
	mov sl, r1
.L_080F2AEC:
	mov r2, sl
	lsls r4, r2, #0x18
	lsrs r4, r4, #0x18
	adds r0, r4, #0
	bl panLeftGain
	adds r5, r0, #0
	lsls r5, r5, #0x18
	lsrs r5, r5, #0x18
	adds r0, r4, #0
	bl panRightGain
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	adds r2, r0, #0
	muls r2, r6, r2
	ldr r0, [sp, #8]
	adds r1, r5, #0
	bl voiceSetPan
	adds r0, r7, #0
	bl noteCalcPitch
	adds r1, r0, #0
	ldr r0, [sp, #8]
	bl voiceSetPitch
	ldr r3, [sp, #0x10]
	ldrb r1, [r3, #1]
	lsrs r1, r1, #7
	ldr r0, [sp, #8]
	bl voiceSetNoInterp
	mov r0, r8
	ldrb r1, [r0, #3]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x1f
	ldr r0, [sp, #8]
	bl voiceSetWet
	ldr r0, [sp, #8]
	bl voiceStart
.L_080F2B42:
	mov r1, r8
	ldrb r0, [r1, #0x14]
	strb r0, [r1, #0x15]
	ldrb r0, [r7]
	movs r1, #1
	orrs r0, r1
	strb r0, [r7]
.L_080F2B50:
	add sp, #0x20
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ chanSetPitchBend  (080F2B60, Thumb)
@   void chanSetPitchBend(Synth *s, int ci, int v)  { s->chans[ci].bend = v & 0x3FFF; }      // 0x2000 = centre
@ --------------------------------------------------------------------------------------------------
	.global chanSetPitchBend
chanSetPitchBend:
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	lsls r2, r2, #0x12
	lsrs r2, r2, #0x12
	ldrh r3, [r1, #8]
	ldr r0, .L_080F2B78                        @ = 0xFFFFC000
	ands r0, r3
	orrs r0, r2
	strh r0, [r1, #8]
	bx lr
	.hword 0x0000
.L_080F2B78:
	.word 0xFFFFC000

@ --------------------------------------------------------------------------------------------------
@ chanSetVolume  (080F2B7C, Thumb)
@   void chanSetVolume(Synth *s, int ci, int v)     { c->volume = v & 0x7F; }                // CC7
@ --------------------------------------------------------------------------------------------------
	.global chanSetVolume
chanSetVolume:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #0x7f
	ands r2, r0
	lsls r2, r2, #7
	ldrh r3, [r1, #2]
	ldr r0, .L_080F2B98                        @ = 0xFFFFC07F
	ands r0, r3
	orrs r0, r2
	strh r0, [r1, #2]
	bx lr
.L_080F2B98:
	.word 0xFFFFC07F

@ --------------------------------------------------------------------------------------------------
@ chanSetPan  (080F2B9C, Thumb)
@   void chanSetPan(Synth *s, int ci, int v)        { c->pan = v & 0x7F; chanUpdatePan(s, ci); }   // CC10
@ --------------------------------------------------------------------------------------------------
	.global chanSetPan
chanSetPan:
	push {r4, r5, lr}
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r3, [r0, #0x18]
	lsls r4, r1, #5
	adds r4, r4, r3
	movs r3, #0x7f
	ands r2, r3
	ldrb r5, [r4, #4]
	movs r3, #0x80
	rsbs r3, r3, #0
	ands r3, r5
	orrs r3, r2
	strb r3, [r4, #4]
	bl chanUpdatePan
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanGetPan  (080F2BC4, Thumb)
@   int chanGetPan(Synth *s, int ci)
@   {   p = c->pan + (s->pan >> 1);  if (c->lfoType == 2) p += c->lfoValue >> 1;  return clamp(p, 0, 127); }
@ --------------------------------------------------------------------------------------------------
	.global chanGetPan
chanGetPan:
	push {lr}
	lsls r1, r1, #5
	ldr r2, [r0, #0x18]
	adds r2, r2, r1
	ldrb r1, [r2, #4]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x19
	ldrb r0, [r0, #2]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x19
	adds r1, r1, r0
	ldrb r0, [r2, #7]
	lsls r0, r0, #0x1a
	lsrs r0, r0, #0x1e
	cmp r0, #2
	bne .L_080F2BEC
	ldrb r0, [r2, #0xd]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x19
	adds r1, r1, r0
.L_080F2BEC:
	cmp r1, #0
	bge .L_080F2BF2
	movs r1, #0
.L_080F2BF2:
	cmp r1, #0x7f
	ble .L_080F2BF8
	movs r1, #0x7f
.L_080F2BF8:
	lsls r0, r1, #0x18
	lsrs r0, r0, #0x18
	pop {r1}
	bx r1

@ --------------------------------------------------------------------------------------------------
@ chanUpdatePan  (080F2C00, Thumb)
@   void chanUpdatePan(Synth *s, int ci)        // re-pan every sampled note of the channel
@   {   base = chanGetPan(s, ci); sign = c->invert ? -1 : 1;
@       for each active note n on c: p = clamp(base + n->panOffset, 0, 127);
@                                    voiceSetPan(i, panLeftGain(p), panRightGain(p) * sign); }
@ --------------------------------------------------------------------------------------------------
	.global chanUpdatePan
chanUpdatePan:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	adds r5, r0, #0
	adds r4, r1, #0
	bl chanGetPan
	lsls r0, r0, #0x18
	lsrs r6, r0, #0x18
	lsls r4, r4, #5
	ldr r0, [r5, #0x18]
	adds r0, r0, r4
	mov sb, r0
	ldrb r0, [r0, #3]
	lsrs r0, r0, #7
	movs r1, #1
	mov sl, r1
	cmp r0, #0
	beq .L_080F2C30
	movs r0, #1
	rsbs r0, r0, #0
	mov sl, r0
.L_080F2C30:
	movs r1, #0
	mov r8, r1
	ldr r0, .L_080F2C3C                        @ = gNotes
	ldr r7, [r0]
	b .L_080F2C8C
	.hword 0x0000
.L_080F2C3C:
	.word gNotes
.L_080F2C40:
	ldrb r0, [r7]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F2C86
	ldr r0, [r7, #0xc]
	cmp r0, sb
	bne .L_080F2C86
	movs r1, #0x18
	ldrsh r0, [r7, r1]
	adds r6, r6, r0
	cmp r6, #0
	bge .L_080F2C5A
	movs r6, #0
.L_080F2C5A:
	cmp r6, #0x7f
	ble .L_080F2C60
	movs r6, #0x7f
.L_080F2C60:
	lsls r4, r6, #0x18
	lsrs r4, r4, #0x18
	adds r0, r4, #0
	bl panLeftGain
	adds r5, r0, #0
	lsls r5, r5, #0x18
	lsrs r5, r5, #0x18
	adds r0, r4, #0
	bl panRightGain
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	mov r2, sl
	muls r2, r0, r2
	mov r0, r8
	adds r1, r5, #0
	bl voiceSetPan
.L_080F2C86:
	movs r0, #1
	add r8, r0
	adds r7, #0x20
.L_080F2C8C:
	ldr r0, .L_080F2CA4                        @ = gNumNotes
	ldrh r0, [r0]
	cmp r8, r0
	blt .L_080F2C40
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F2CA4:
	.word gNumNotes

@ --------------------------------------------------------------------------------------------------
@ chanSetProgram  (080F2CA8, Thumb)
@   void chanSetProgram(Synth *s, int ci, int p)   { c->program = p & 0x7F; }
@ --------------------------------------------------------------------------------------------------
	.global chanSetProgram
chanSetProgram:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #0x7f
	ands r2, r0
	lsls r2, r2, #2
	ldrh r3, [r1]
	ldr r0, .L_080F2CC4                        @ = 0xFFFFFE03
	ands r0, r3
	orrs r0, r2
	strh r0, [r1]
	bx lr
.L_080F2CC4:
	.word 0xFFFFFE03

@ --------------------------------------------------------------------------------------------------
@ chanSetExpression  (080F2CC8, Thumb)
@   void chanSetExpression(Synth *s, int ci, int v) { c->expression = v & 0x7F; }            // CC11
@ --------------------------------------------------------------------------------------------------
	.global chanSetExpression
chanSetExpression:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #0x7f
	ands r2, r0
	lsls r2, r2, #7
	ldrh r3, [r1, #4]
	ldr r0, .L_080F2CE4                        @ = 0xFFFFC07F
	ands r0, r3
	orrs r0, r2
	strh r0, [r1, #4]
	bx lr
.L_080F2CE4:
	.word 0xFFFFC07F

@ --------------------------------------------------------------------------------------------------
@ chanSetBankSelect  (080F2CE8, Thumb)
@   void chanSetBankSelect(Synth *s, int ci, int v)   // CC0 (v | 0x8000: MSB) and CC32 (LSB)
@   {   14-bit value in c->bankSelect;  nothing reads it (the bank comes from the song table). }
@ --------------------------------------------------------------------------------------------------
	.global chanSetBankSelect
chanSetBankSelect:
	push {r4, r5, lr}
	adds r4, r0, #0
	adds r5, r1, #0
	lsls r2, r2, #0x10
	lsrs r2, r2, #0x10
	ldr r1, [r4, #0x18]
	lsls r0, r5, #5
	adds r0, r0, r1
	ldr r0, [r0]
	lsls r0, r0, #9
	lsrs r3, r0, #0x12
	movs r0, #0x80
	lsls r0, r0, #8
	ands r0, r2
	cmp r0, #0
	beq .L_080F2D18
	movs r0, #0xfe
	lsls r0, r0, #6
	ands r3, r0
	lsls r0, r2, #7
	orrs r3, r0
	lsls r0, r3, #0x10
	lsrs r3, r0, #0x10
	b .L_080F2D1E
.L_080F2D18:
	movs r0, #0x7f
	ands r3, r0
	orrs r3, r2
.L_080F2D1E:
	ldr r0, [r4, #0x18]
	lsls r2, r5, #5
	adds r2, r2, r0
	ldr r0, .L_080F2D3C                        @ = 0x00003FFF
	ands r3, r0
	lsls r3, r3, #9
	ldr r0, [r2]
	ldr r1, .L_080F2D40                        @ = 0xFF8001FF
	ands r0, r1
	orrs r0, r3
	str r0, [r2]
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F2D3C:
	.word 0x00003FFF
.L_080F2D40:
	.word 0xFF8001FF

@ --------------------------------------------------------------------------------------------------
@ chanSetFlag0  (080F2D44, Thumb)
@   void chanSetFlag0(Synth *s, int ci, int v)  (not called)  { c->flags bit 0 = v; }   // mutes note-ons
@ --------------------------------------------------------------------------------------------------
	.global chanSetFlag0
chanSetFlag0:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #1
	ands r2, r0
	ldrb r3, [r1]
	movs r0, #2
	rsbs r0, r0, #0
	ands r0, r3
	orrs r0, r2
	strb r0, [r1]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ chanSetModDepth  (080F2D60, Thumb)
@   void chanSetModDepth(Synth *s, int ci, int v)   { c->modDepth = v & 0x7F; }             // CC1
@ --------------------------------------------------------------------------------------------------
	.global chanSetModDepth
chanSetModDepth:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #0x7f
	ands r2, r0
	lsls r2, r2, #0xe
	ldr r0, [r1, #4]
	ldr r3, .L_080F2D7C                        @ = 0xFFE03FFF
	ands r0, r3
	orrs r0, r2
	str r0, [r1, #4]
	bx lr
.L_080F2D7C:
	.word 0xFFE03FFF

@ --------------------------------------------------------------------------------------------------
@ chanSetField6  (080F2D80, Thumb)
@   void chanSetField6(Synth *s, int ci, int v)  (not called)  { c->field6 = v & 0x7F; }   // never read
@ --------------------------------------------------------------------------------------------------
	.global chanSetField6
chanSetField6:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #0x7f
	ands r2, r0
	lsls r2, r2, #5
	ldrh r3, [r1, #6]
	ldr r0, .L_080F2D9C                        @ = 0xFFFFF01F
	ands r0, r3
	orrs r0, r2
	strh r0, [r1, #6]
	bx lr
.L_080F2D9C:
	.word 0xFFFFF01F

@ --------------------------------------------------------------------------------------------------
@ chanSetWet  (080F2DA0, Thumb)
@   void chanSetWet(Synth *s, int ci, int v)        { c->wet = v & 1; }        // CC72: notes go through the master filter
@ --------------------------------------------------------------------------------------------------
	.global chanSetWet
chanSetWet:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #1
	ands r2, r0
	lsls r2, r2, #6
	ldrb r3, [r1, #3]
	movs r0, #0x41
	rsbs r0, r0, #0
	ands r0, r3
	orrs r0, r2
	strb r0, [r1, #3]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanSetLfoType  (080F2DC0, Thumb)
@   void chanSetLfoType(Synth *s, int ci, int v)    { c->lfoType = v & 3; }    // CC22: 0 vibrato, 1 tremolo, 2 auto-pan
@ --------------------------------------------------------------------------------------------------
	.global chanSetLfoType
chanSetLfoType:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	movs r0, #3
	ands r2, r0
	lsls r2, r2, #4
	ldrb r3, [r1, #7]
	movs r0, #0x31
	rsbs r0, r0, #0
	ands r0, r3
	orrs r0, r2
	strb r0, [r1, #7]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanSetVibRange  (080F2DE0, Thumb)
@   void chanSetVibRange(Synth *s, int ci, int v)  (not called)  { c->vibRange = v; }
@ --------------------------------------------------------------------------------------------------
	.global chanSetVibRange
chanSetVibRange:
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	strb r2, [r1, #0xc]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanSetLfoSpeed  (080F2DEC, Thumb)
@   void chanSetLfoSpeed(Synth *s, int ci, int v)   { c->lfoSpeed = v << 8; }  // CC21 (phase step per frame / 256)
@ --------------------------------------------------------------------------------------------------
	.global chanSetLfoSpeed
chanSetLfoSpeed:
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	lsls r2, r2, #8
	strh r2, [r1, #0x10]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ chanSetLfoDelay  (080F2DF8, Thumb)
@   void chanSetLfoDelay(Synth *s, int ci, int v)   { c->lfoDelay = v; }       // CC26, frames
@ --------------------------------------------------------------------------------------------------
	.global chanSetLfoDelay
chanSetLfoDelay:
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	strb r2, [r1, #0x14]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanSetBendRange  (080F2E04, Thumb)
@   void chanSetBendRange(Synth *s, int ci, int v)  { c->bendRange = v; }      // CC20, semitones
@ --------------------------------------------------------------------------------------------------
	.global chanSetBendRange
chanSetBendRange:
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	strb r2, [r1, #0xf]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanSetInvert  (080F2E10, Thumb)
@   void chanSetInvert(Synth *s, int ci, int v)     { c->invert = v; chanSetPan(s, ci, c->pan); }   // CC75: right side phase-inverted
@ --------------------------------------------------------------------------------------------------
	.global chanSetInvert
chanSetInvert:
	push {r4, r5, r6, lr}
	ldr r4, [r0, #0x18]
	lsls r5, r1, #5
	adds r4, r5, r4
	lsls r2, r2, #7
	ldrb r6, [r4, #3]
	movs r3, #0x7f
	ands r3, r6
	orrs r3, r2
	strb r3, [r4, #3]
	ldr r2, [r0, #0x18]
	adds r5, r5, r2
	ldrb r2, [r5, #4]
	lsls r2, r2, #0x19
	lsrs r2, r2, #0x19
	bl chanSetPan
	pop {r4, r5, r6}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ chanSetPriority  (080F2E38, Thumb)
@   void chanSetPriority(Synth *s, int ci, int v)   { c->priority = (v + s->priority) & 0xFF; }     // CC33
@ --------------------------------------------------------------------------------------------------
	.global chanSetPriority
chanSetPriority:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r3, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r3
	ldr r0, [r0, #0x14]
	lsrs r0, r0, #5
	adds r2, r2, r0
	movs r0, #0xff
	ands r2, r0
	lsls r2, r2, #5
	ldrh r3, [r1, #0xa]
	ldr r0, .L_080F2E5C                        @ = 0xFFFFE01F
	ands r0, r3
	orrs r0, r2
	strh r0, [r1, #0xa]
	bx lr
	.hword 0x0000
.L_080F2E5C:
	.word 0xFFFFE01F

@ --------------------------------------------------------------------------------------------------
@ chanSetRandomPitch  (080F2E60, Thumb)
@   void chanSetRandomPitch(Synth *s, int ci, int v)          // CC82
@   {   c->randomPitchBase = 0x8000 / (v + 128);  c->randomPitchRange = 0x10000 / (256 - v) - c->randomPitchBase;
@       c->randomPitchCur = 0x100; }         // each note-on picks a factor in [128/(128+v), 256/(256-v)]
@ --------------------------------------------------------------------------------------------------
	.global chanSetRandomPitch
chanSetRandomPitch:
	push {r4, r5, r6, lr}
	mov r6, sb
	mov r5, r8
	push {r5, r6}
	adds r6, r0, #0
	adds r5, r1, #0
	lsls r4, r2, #0x18
	lsrs r4, r4, #0x18
	adds r1, r4, #0
	adds r1, #0x80
	movs r0, #0x80
	lsls r0, r0, #8
	bl __udivsi3
	mov r8, r0
	movs r0, #0x80
	lsls r0, r0, #1
	mov sb, r0
	subs r4, r0, r4
	movs r0, #0x80
	lsls r0, r0, #9
	adds r1, r4, #0
	bl __udivsi3
	ldr r1, [r6, #0x18]
	lsls r5, r5, #5
	adds r1, r5, r1
	mov r2, r8
	strh r2, [r1, #0x16]
	ldr r1, [r6, #0x18]
	adds r1, r5, r1
	mov r2, r8
	subs r0, r0, r2
	strh r0, [r1, #0x18]
	ldr r0, [r6, #0x18]
	adds r5, r5, r0
	mov r0, sb
	strh r0, [r5, #0x1a]
	pop {r3, r4}
	mov r8, r3
	mov sb, r4
	pop {r4, r5, r6}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ chanSetRandomKey  (080F2EB8, Thumb)
@   void chanSetRandomKey(Synth *s, int ci, int v)      { c->randomKey = v; }             // CC83: +-v semitones, snapped by s->scale
@ --------------------------------------------------------------------------------------------------
	.global chanSetRandomKey
chanSetRandomKey:
	ldr r0, [r0, #0x18]
	lsls r1, r1, #5
	adds r1, r1, r0
	strb r2, [r1, #0x1c]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ chanSetRandomKeyRate  (080F2EC4, Thumb)
@   void chanSetRandomKeyRate(Synth *s, int ci, int v)  { c->randomKeyRate = c->randomKeyCount = v; }  // CC84: re-roll every v frames
@ --------------------------------------------------------------------------------------------------
	.global chanSetRandomKeyRate
chanSetRandomKeyRate:
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	ldr r3, [r0, #0x18]
	lsls r1, r1, #5
	adds r3, r1, r3
	strb r2, [r3, #0x1d]
	ldr r0, [r0, #0x18]
	adds r1, r1, r0
	strb r2, [r1, #0x1e]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ synthSetTranspose  (080F2ED8, Thumb)
@   void synthSetTranspose(Synth *s, int v)  (not called)  { s->transpose = v; }
@ --------------------------------------------------------------------------------------------------
	.global synthSetTranspose
synthSetTranspose:
	strb r1, [r0, #1]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ synthSetVolume  (080F2EDC, Thumb)
@   void synthSetVolume(Synth *s, int v)  { s->volume = v; }
@ --------------------------------------------------------------------------------------------------
	.global synthSetVolume
synthSetVolume:
	strb r1, [r0]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ synthSetPan  (080F2EE0, Thumb)
@   void synthSetPan(Synth *s, int v)     { s->pan = v; for each channel chanUpdatePan(s, i); }
@ --------------------------------------------------------------------------------------------------
	.global synthSetPan
synthSetPan:
	push {r4, r5, lr}
	adds r5, r0, #0
	strb r1, [r5, #2]
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	movs r4, #0
	cmp r0, #0
	beq .L_080F2F04
.L_080F2EF0:
	adds r0, r5, #0
	adds r1, r4, #0
	bl chanUpdatePan
	adds r4, #1
	ldrb r0, [r5, #0x14]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r4, r0
	blo .L_080F2EF0
.L_080F2F04:
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ synthSetTune  (080F2F0C, Thumb)
@   void synthSetTune(Synth *s, int v)    { s->tune = v; }     // semitones in 8.8
@ --------------------------------------------------------------------------------------------------
	.global synthSetTune
synthSetTune:
	strh r1, [r0, #4]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ synthSetBendRange  (080F2F10, Thumb)
@   void synthSetBendRange(Synth *s, int v)  (not called)  { every channel: bendRange = v; }
@ --------------------------------------------------------------------------------------------------
	.global synthSetBendRange
synthSetBendRange:
	push {r4, lr}
	adds r3, r0, #0
	lsls r1, r1, #0x18
	lsrs r4, r1, #0x18
	ldrb r0, [r3, #0x14]
	lsls r0, r0, #0x1b
	movs r2, #0
	cmp r0, #0
	beq .L_080F2F36
.L_080F2F22:
	ldr r0, [r3, #0x18]
	lsls r1, r2, #5
	adds r1, r1, r0
	strb r4, [r1, #0xf]
	adds r2, #1
	ldrb r0, [r3, #0x14]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r2, r0
	blo .L_080F2F22
.L_080F2F36:
	pop {r4}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ synthSetField6  (080F2F3C, Thumb)
@   void synthSetField6(Synth *s, int v)     (not called)  { s->field6 = v; }
@ --------------------------------------------------------------------------------------------------
	.global synthSetField6
synthSetField6:
	strh r1, [r0, #6]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ synthSetFreqTable  (080F2F40, Thumb)
@   void synthSetFreqTable(Synth *s, u16 *t) (not called)  { s->freqTable = t; }
@ --------------------------------------------------------------------------------------------------
	.global synthSetFreqTable
synthSetFreqTable:
	str r1, [r0, #0xc]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ sweepInit  (080F2F44, Thumb)
@   void sweepInit(Sweep *w, int delay, int fadeIn, int period, int phase, int maxPhase)   // from SysEx 00
@   {   w->state = 0; w->out = 0; w->acc = 0; w->delay = delay; w->fadeIn = fadeIn;
@       w->rate = 0x10000 / period; w->phase = phase; w->maxPhase = maxPhase; }
@ --------------------------------------------------------------------------------------------------
	.global sweepInit
sweepInit:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	ldr r5, [sp, #0x10]
	ldr r6, [sp, #0x14]
	lsls r3, r3, #0x18
	lsrs r3, r3, #0x18
	lsls r5, r5, #0x18
	lsrs r5, r5, #0x18
	lsls r6, r6, #0x18
	lsrs r6, r6, #0x18
	movs r0, #0
	strb r0, [r4, #6]
	strb r0, [r4, #7]
	str r0, [r4, #8]
	strb r1, [r4]
	strb r2, [r4, #1]
	movs r0, #0x80
	lsls r0, r0, #9
	adds r1, r3, #0
	bl __divsi3
	strh r0, [r4, #2]
	strb r5, [r4, #4]
	strb r6, [r4, #5]
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ sweepStart  (080F2F7C, Thumb)
@   void sweepStart(Sweep *w)  { w->state = 1; w->acc = 0; w->out = 0; }
@ --------------------------------------------------------------------------------------------------
	.global sweepStart
sweepStart:
	movs r2, #0
	movs r1, #1
	strb r1, [r0, #6]
	str r2, [r0, #8]
	strb r2, [r0, #7]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ sweepStop  (080F2F88, Thumb)
@   void sweepStop(Sweep *w)   { w->state = 0; w->acc = 0; w->out = 0; }
@ --------------------------------------------------------------------------------------------------
	.global sweepStop
sweepStop:
	movs r1, #0
	strb r1, [r0, #6]
	str r1, [r0, #8]
	strb r1, [r0, #7]
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ sweepTick  (080F2F94, Thumb)
@   void sweepTick(Sweep *w, int ticks8)       // ticks8 = MIDI ticks this frame << 8 (24 per beat)
@   {
@       switch (w->state) {
@       case 0: w->out = 0; return;
@       case 1: w->acc += ticks8; w->out = 0; if ((w->acc >> 8) >= w->delay) { w->acc = 0; w->state = 2; } return;
@       case 2: case 3:
@           w->acc += ticks8;  t = w->acc >> 8;  ph = t * w->rate >> 8;
@           if (w->maxPhase && ph > w->maxPhase) ph = w->maxPhase;             // one-shot sweep
@           o = clamp(sndSineTable[(ph + w->phase) & 0xFF] >> 1, -128, 127);
@           if (w->state == 2) { if (t < w->fadeIn) o = o * t / w->fadeIn; else w->state = 3; }
@           w->out = o;
@       }
@   }
@ --------------------------------------------------------------------------------------------------
	.global sweepTick
sweepTick:
	push {r4, lr}
	adds r4, r0, #0
	ldrb r0, [r4, #6]
	cmp r0, #1
	beq .L_080F2FCA
	cmp r0, #1
	bgt .L_080F2FA8
	cmp r0, #0
	beq .L_080F2FC6
	b .L_080F302E
.L_080F2FA8:
	cmp r0, #3
	bgt .L_080F302E
	ldr r0, [r4, #8]
	adds r0, r0, r1
	str r0, [r4, #8]
	lsrs r3, r0, #8
	ldrh r0, [r4, #2]
	muls r0, r3, r0
	asrs r2, r0, #8
	ldrb r0, [r4, #5]
	cmp r0, #0
	beq .L_080F2FE6
	cmp r2, r0
	bls .L_080F2FE6
	b .L_080F2FE4
.L_080F2FC6:
	strb r0, [r4, #7]
	b .L_080F302E
.L_080F2FCA:
	ldr r0, [r4, #8]
	adds r0, r0, r1
	str r0, [r4, #8]
	movs r1, #0
	strb r1, [r4, #7]
	lsrs r0, r0, #8
	ldrb r2, [r4]
	cmp r0, r2
	blo .L_080F302E
	str r1, [r4, #8]
	movs r0, #2
	strb r0, [r4, #6]
	b .L_080F302E
.L_080F2FE4:
	adds r2, r0, #0
.L_080F2FE6:
	ldrb r0, [r4, #4]
	adds r2, r2, r0
	ldr r1, .L_080F3024                        @ = sndSineTable
	movs r0, #0xff
	ands r0, r2
	lsls r0, r0, #1
	adds r0, r0, r1
	ldrh r0, [r0]
	lsls r0, r0, #0x10
	asrs r2, r0, #0x11
	cmp r2, #0x7f
	ble .L_080F3000
	movs r2, #0x7f
.L_080F3000:
	movs r0, #0x80
	rsbs r0, r0, #0
	cmp r2, r0
	bge .L_080F300A
	adds r2, r0, #0
.L_080F300A:
	ldrb r0, [r4, #6]
	cmp r0, #2
	bne .L_080F302C
	ldrb r1, [r4, #1]
	cmp r3, r1
	bge .L_080F3028
	adds r0, r2, #0
	muls r0, r3, r0
	bl __divsi3
	adds r2, r0, #0
	b .L_080F302C
	.hword 0x0000
.L_080F3024:
	.word sndSineTable
.L_080F3028:
	movs r0, #3
	strb r0, [r4, #6]
.L_080F302C:
	strb r2, [r4, #7]
.L_080F302E:
	pop {r4}
	pop {r0}
	bx r0

@ ==================================================================================================
@  RANDOM NUMBERS AND PSG (0x080F3034-0x080F3490)
@ ==================================================================================================

@ --------------------------------------------------------------------------------------------------
@ sndRandom  (080F3034, Thumb)
@   u16 sndRandom(u16 n)  { gSndRandSeed = gSndRandSeed * 109 + 1021;  return n * gSndRandSeed >> 16; }   // 0..n-1
@ --------------------------------------------------------------------------------------------------
	.global sndRandom
sndRandom:
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	ldr r2, .L_080F3050                        @ = gSndRandSeed
	ldrh r3, [r2]
	movs r1, #0x6d
	muls r1, r3, r1
	ldr r3, .L_080F3054                        @ = 0x000003FD
	adds r1, r1, r3
	strh r1, [r2]
	ldrh r1, [r2]
	muls r0, r1, r0
	lsrs r0, r0, #0x10
	bx lr
	.hword 0x0000
.L_080F3050:
	.word gSndRandSeed
.L_080F3054:
	.word 0x000003FD

@ --------------------------------------------------------------------------------------------------
@ psgInit  (080F3058, Thumb)
@   void psgInit(void)
@   {   gPsgNotes[0..3].flags &= ~1;  gPsgRetrig[0..3] = 0;
@       *(u8 *)gPsgLastWave = 0;       // bug: writes through a pointer that holds 0 at this point
@   }
@ --------------------------------------------------------------------------------------------------
	.global psgInit
psgInit:
	push {r4, r5, lr}
	movs r3, #0
	ldr r5, .L_080F3090                        @ = gPsgLastWave
	movs r4, #2
	rsbs r4, r4, #0
	ldr r2, .L_080F3094                        @ = gPsgNotes
.L_080F3064:
	ldrb r1, [r2]
	adds r0, r4, #0
	ands r0, r1
	strb r0, [r2]
	adds r2, #0x20
	adds r3, #1
	cmp r3, #3
	bls .L_080F3064
	movs r3, #0
	ldr r2, .L_080F3098                        @ = gPsgRetrig
	movs r1, #0
.L_080F307A:
	adds r0, r3, r2
	strb r1, [r0]
	adds r3, #1
	cmp r3, #3
	bls .L_080F307A
	ldr r1, [r5]
	movs r0, #0
	strb r0, [r1]
	pop {r4, r5}
	pop {r0}
	bx r0
.L_080F3090:
	.word gPsgLastWave
.L_080F3094:
	.word gPsgNotes
.L_080F3098:
	.word gPsgRetrig

@ --------------------------------------------------------------------------------------------------
@ psgTrigger  (080F309C, Thumb)
@   void psgTrigger(int ch)  { gPsgRetrig[ch] = 1; gPsgLastVol[ch] = 0xFFFF; gPsgLastFreq[ch] = 0xFFFF; }   // force a full register write
@ --------------------------------------------------------------------------------------------------
	.global psgTrigger
psgTrigger:
	ldr r1, .L_080F30BC                        @ = gPsgRetrig
	adds r1, r0, r1
	movs r2, #1
	strb r2, [r1]
	ldr r1, .L_080F30C0                        @ = gPsgLastVol
	lsls r0, r0, #1
	adds r1, r0, r1
	ldr r2, .L_080F30C4                        @ = 0x0000FFFF
	strh r2, [r1]
	ldr r1, .L_080F30C8                        @ = gPsgLastFreq
	adds r0, r0, r1
	movs r1, #1
	rsbs r1, r1, #0
	strh r1, [r0]
	bx lr
	.hword 0x0000
.L_080F30BC:
	.word gPsgRetrig
.L_080F30C0:
	.word gPsgLastVol
.L_080F30C4:
	.word 0x0000FFFF
.L_080F30C8:
	.word gPsgLastFreq

@ --------------------------------------------------------------------------------------------------
@ psgFreqToReg  (080F30CC, Thumb)
@   int psgFreqToReg(u32 f)  { return f ? clamp(2048 - (0x400000 / f >> 5), 0, 2047) : 0; }   // 2048 - 131072/f
@ --------------------------------------------------------------------------------------------------
	.global psgFreqToReg
psgFreqToReg:
	push {lr}
	adds r1, r0, #0
	cmp r1, #0
	bne .L_080F30D8
	movs r0, #0
	b .L_080F30F6
.L_080F30D8:
	movs r0, #0x80
	lsls r0, r0, #0xf
	bl __udivsi3
	lsrs r0, r0, #5
	movs r1, #0x80
	lsls r1, r1, #4
	subs r0, r1, r0
	cmp r0, #0
	bge .L_080F30EE
	movs r0, #0
.L_080F30EE:
	ldr r1, .L_080F30FC                        @ = 0x000007FF
	cmp r0, r1
	ble .L_080F30F6
	adds r0, r1, #0
.L_080F30F6:
	pop {r1}
	bx r1
	.hword 0x0000
.L_080F30FC:
	.word 0x000007FF

@ --------------------------------------------------------------------------------------------------
@ psgVolToReg  (080F3100, Thumb)
@   int psgVolToReg(int v)   { v >>= 3; return min(v + v / 2, 15); }         // 0..127 -> 0..15
@ --------------------------------------------------------------------------------------------------
	.global psgVolToReg
psgVolToReg:
	push {lr}
	adds r1, r0, #0
	lsrs r1, r1, #3
	lsrs r0, r1, #1
	adds r1, r1, r0
	cmp r1, #0xf
	bls .L_080F3110
	movs r1, #0xf
.L_080F3110:
	adds r0, r1, #0
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ psgUpdate  (080F3118, Thumb)
@   void psgUpdate(int ch)                      // once per frame; ch 0/1 square, 2 wave, 3 noise
@   {
@       Note *n = &gPsgNotes[ch];  if (!(n->flags & 1)) return;
@       Instrument *i = n->inst;  len = i->psg >> 2 & 0xFF;             // low byte of the CNT_H/CNT_L register
@       if (len && !gPsgRetrig[ch] && !(REG_SOUNDCNT_X & 1 << ch)) {     // the hardware length ran out
@           *psgRegA[ch] = 0; *psgRegB[ch] = 0x8000; gPsgLastVol[ch] = 0; gPsgLastFreq[ch] = 0x8000;
@           n->flags &= ~1; return;
@       }
@       if (ch <= 2) { freq = psgFreqToReg(noteCalcPitch(n)); if (len) freq |= 0x4000; }        // length enable
@       else           freq = psgNoiseTable[clamp(n->freq, 21, 80) - 21] | (i->psg >> 16 & ~7); // n->freq = key
@       vol = psgVolToReg(noteCalcVolume(n));
@       trig = vol != gPsgLastVol[ch] ? 0x8000 : 0;          // a new volume only takes effect on a trigger
@       if (vol == gPsgLastVol[ch] && freq == gPsgLastFreq[ch]) goto env;
@       duty = i->psg >> 17 & 3;
@       switch (ch) {
@       case 0: if (gPsgRetrig[0]) { REG_SOUND1CNT_L = (i->psg >> 10 & 0x7F) ?: 8;
@                                    CNT_H = vol << 12 | duty << 6 | len; CNT_X = freq | trig; delay; CNT_X = freq | 0x8000; break; }
@               if (i->psg >> 10 & 0x7F) break;               // sweeping: leave the running note alone
@               /* fall through */
@       case 1: *psgRegA[ch] = vol << 12 | duty << 6 | len;  *psgRegB[ch] = freq | trig; break;
@       case 2: if (gPsgRetrig[2]) { REG_SOUNDCNT_L = 0xFF77; freq |= 0x8000;
@                                    if (gPsgLastWave != i->wave) { copy 16 bytes to REG_WAVE_RAM; SOUND3CNT_L = 0x80; } }
@               SOUND3CNT_H = psgWaveVolTable[vol >> 2] | len;  SOUND3CNT_X = freq;  break;
@       case 3: SOUND4CNT_L = vol << 12 | len;  SOUND4CNT_H = freq | trig; break;
@       }
@       gPsgLastVol[ch] = vol; gPsgLastFreq[ch] = freq;
@   env:
@       gPsgRetrig[ch] = 0;
@       if (noteEnvelopeTick(n)) { *psgRegA[ch] = 0; *psgRegB[ch] = 0x8000; last vol/freq = 0/0x8000; n->flags &= ~1; }
@   }
@   gPsgLastWave is compared but never written, so the wave RAM is reloaded on every wave-channel note.
@ --------------------------------------------------------------------------------------------------
	.global psgUpdate
psgUpdate:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #8
	adds r7, r0, #0
	lsls r1, r7, #5
	ldr r0, .L_080F319C                        @ = gPsgNotes
	adds r1, r1, r0
	mov r8, r1
	ldrb r0, [r1]
	lsls r0, r0, #0x1f
	cmp r0, #0
	bne .L_080F3138
	b .L_080F33CE
.L_080F3138:
	ldr r0, .L_080F31A0                        @ = psgRegA
	lsls r1, r7, #2
	adds r0, r1, r0
	ldr r0, [r0]
	mov sl, r0
	ldr r0, .L_080F31A4                        @ = psgRegB
	adds r1, r1, r0
	ldr r1, [r1]
	mov sb, r1
	mov r0, r8
	ldr r6, [r0, #4]
	ldrh r0, [r6, #0x20]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x18
	cmp r0, #0
	beq .L_080F31B8
	ldr r0, .L_080F31A8                        @ = gPsgRetrig
	adds r0, r7, r0
	ldrb r0, [r0]
	cmp r0, #0
	bne .L_080F31B8
	ldr r0, .L_080F31AC                        @ = REG_SOUNDCNT_X
	ldrh r0, [r0]
	adds r2, r0, #0
	lsrs r2, r7
	movs r0, #1
	ands r2, r0
	cmp r2, #0
	beq .L_080F3174
	b .L_080F33CE
.L_080F3174:
	ldr r0, .L_080F31B0                        @ = gPsgLastVol
	lsls r1, r7, #1
	adds r0, r1, r0
	strh r2, [r0]
	mov r0, sl
	strh r2, [r0]
	ldr r0, .L_080F31B4                        @ = gPsgLastFreq
	adds r1, r1, r0
	movs r0, #0x80
	lsls r0, r0, #8
	strh r0, [r1]
	mov r1, sb
	strh r0, [r1]
	mov r2, r8
	ldrb r1, [r2]
	movs r0, #2
	rsbs r0, r0, #0
	ands r0, r1
	strb r0, [r2]
	b .L_080F33CE
.L_080F319C:
	.word gPsgNotes
.L_080F31A0:
	.word psgRegA
.L_080F31A4:
	.word psgRegB
.L_080F31A8:
	.word gPsgRetrig
.L_080F31AC:
	.word REG_SOUNDCNT_X
.L_080F31B0:
	.word gPsgLastVol
.L_080F31B4:
	.word gPsgLastFreq
.L_080F31B8:
	cmp r7, #2
	bhi .L_080F31D8
	mov r0, r8
	bl noteCalcPitch
	bl psgFreqToReg
	adds r5, r0, #0
	ldrh r0, [r6, #0x20]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x18
	cmp r0, #0
	beq .L_080F31FA
	movs r0, #0x80
	lsls r0, r0, #7
	b .L_080F31F8
.L_080F31D8:
	mov r1, r8
	ldr r0, [r1]
	lsrs r1, r0, #0xf
	cmp r1, #0x14
	bhi .L_080F31E4
	movs r1, #0x15
.L_080F31E4:
	cmp r1, #0x50
	bls .L_080F31EA
	movs r1, #0x50
.L_080F31EA:
	ldr r0, .L_080F3244                        @ = psgNoiseTable
	subs r1, #0x15
	adds r1, r1, r0
	ldrb r5, [r1]
	ldrh r0, [r6, #0x22]
	lsrs r0, r0, #3
	lsls r0, r0, #3
.L_080F31F8:
	orrs r5, r0
.L_080F31FA:
	mov r0, r8
	bl noteCalcVolume
	bl psgVolToReg
	mov ip, r0
	ldr r0, .L_080F3248                        @ = gPsgLastVol
	lsls r3, r7, #1
	adds r0, r3, r0
	ldrh r2, [r0]
	mov r1, ip
	eors r1, r2
	rsbs r0, r1, #0
	orrs r0, r1
	asrs r4, r0, #0x1f
	movs r0, #0x80
	lsls r0, r0, #8
	ands r4, r0
	str r3, [sp, #4]
	cmp ip, r2
	bne .L_080F3230
	ldr r0, .L_080F324C                        @ = gPsgLastFreq
	adds r0, r3, r0
	ldrh r0, [r0]
	cmp r5, r0
	bne .L_080F3230
	b .L_080F3394
.L_080F3230:
	cmp r7, #1
	beq .L_080F32C2
	cmp r7, #1
	blo .L_080F3250
	cmp r7, #2
	beq .L_080F32EA
	cmp r7, #3
	bne .L_080F3242
	b .L_080F336C
.L_080F3242:
	b .L_080F3384
.L_080F3244:
	.word psgNoiseTable
.L_080F3248:
	.word gPsgLastVol
.L_080F324C:
	.word gPsgLastFreq
.L_080F3250:
	ldr r0, .L_080F32B0                        @ = gPsgRetrig
	adds r1, r7, r0
	ldrb r1, [r1]
	cmp r1, #0
	beq .L_080F32B8
	ldr r0, [r6, #0x20]
	lsls r0, r0, #0xf
	lsrs r0, r0, #0x19
	movs r1, #8
	cmp r0, #0
	beq .L_080F3268
	adds r1, r0, #0
.L_080F3268:
	ldr r0, .L_080F32B4                        @ = REG_SOUND1CNT_L
	strh r1, [r0]
	mov r2, ip
	lsls r1, r2, #0xc
	adds r0, r6, #0
	adds r0, #0x22
	ldrb r0, [r0]
	lsls r0, r0, #0x1d
	lsrs r0, r0, #0x1e
	lsls r0, r0, #6
	orrs r1, r0
	ldrh r0, [r6, #0x20]
	lsrs r0, r0, #2
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	orrs r0, r1
	mov r1, sl
	strh r0, [r1]
	orrs r4, r5
	mov r2, sb
	strh r4, [r2]
	movs r0, #0
	str r0, [sp]
	str r0, [sp]
	str r0, [sp]
	str r0, [sp]
	str r0, [sp]
	str r0, [sp]
	str r0, [sp]
	str r0, [sp]
	adds r0, r5, #0
	movs r1, #0x80
	lsls r1, r1, #8
	orrs r0, r1
	strh r0, [r2]
	b .L_080F3384
.L_080F32B0:
	.word gPsgRetrig
.L_080F32B4:
	.word REG_SOUND1CNT_L
.L_080F32B8:
	ldr r0, [r6, #0x20]
	lsls r0, r0, #0xf
	lsrs r0, r0, #0x19
	cmp r0, #0
	bne .L_080F3384
.L_080F32C2:
	mov r2, ip
	lsls r0, r2, #0xc
	adds r1, r6, #0
	adds r1, #0x22
	ldrb r1, [r1]
	lsls r1, r1, #0x1d
	lsrs r1, r1, #0x1e
	lsls r1, r1, #6
	orrs r0, r1
	ldrh r1, [r6, #0x20]
	lsrs r1, r1, #2
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	orrs r1, r0
	mov r0, sl
	strh r1, [r0]
	orrs r4, r5
	mov r1, sb
	strh r4, [r1]
	b .L_080F3384
.L_080F32EA:
	ldr r0, .L_080F3350                        @ = gPsgRetrig
	ldrb r1, [r0, #2]
	cmp r1, #0
	beq .L_080F332E
	ldr r1, .L_080F3354                        @ = REG_SOUNDCNT_L
	ldr r2, .L_080F3358                        @ = 0x0000FF77
	adds r0, r2, #0
	strh r0, [r1]
	movs r0, #0x80
	lsls r0, r0, #8
	orrs r5, r0
	ldr r0, .L_080F335C                        @ = gPsgLastWave
	ldr r0, [r0]
	ldr r3, [r6, #4]
	cmp r0, r3
	beq .L_080F332E
	ldr r2, .L_080F3360                        @ = REG_WAVE_RAM
	adds r1, r3, #0
	ldm r1!, {r0}
	stm r2!, {r0}
	ldr r0, [r3, #4]
	stm r2!, {r0}
	adds r1, #4
	ldm r1!, {r0}
	stm r2!, {r0}
	ldr r0, [r1]
	str r0, [r2]
	ldr r2, .L_080F3364                        @ = REG_SOUND3CNT_L
	ldrh r1, [r2]
	movs r0, #0x40
	bics r0, r1
	movs r1, #0x80
	orrs r0, r1
	strh r0, [r2]
.L_080F332E:
	ldr r0, .L_080F3368                        @ = psgWaveVolTable
	mov r2, ip
	lsrs r1, r2, #2
	lsls r1, r1, #1
	adds r1, r1, r0
	ldrh r0, [r6, #0x20]
	lsrs r0, r0, #2
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	ldrh r1, [r1]
	orrs r0, r1
	mov r1, sl
	strh r0, [r1]
	mov r2, sb
	strh r5, [r2]
	b .L_080F3384
	.hword 0x0000
.L_080F3350:
	.word gPsgRetrig
.L_080F3354:
	.word REG_SOUNDCNT_L
.L_080F3358:
	.word 0x0000FF77
.L_080F335C:
	.word gPsgLastWave
.L_080F3360:
	.word REG_WAVE_RAM
.L_080F3364:
	.word REG_SOUND3CNT_L
.L_080F3368:
	.word psgWaveVolTable
.L_080F336C:
	mov r0, ip
	lsls r1, r0, #0xc
	ldrh r0, [r6, #0x20]
	lsrs r0, r0, #2
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	orrs r0, r1
	mov r1, sl
	strh r0, [r1]
	orrs r4, r5
	mov r2, sb
	strh r4, [r2]
.L_080F3384:
	ldr r0, .L_080F33E0                        @ = gPsgLastVol
	ldr r1, [sp, #4]
	adds r0, r1, r0
	mov r2, ip
	strh r2, [r0]
	ldr r0, .L_080F33E4                        @ = gPsgLastFreq
	adds r0, r1, r0
	strh r5, [r0]
.L_080F3394:
	ldr r1, .L_080F33E8                        @ = gPsgRetrig
	adds r0, r7, r1
	movs r4, #0
	strb r4, [r0]
	mov r0, r8
	bl noteEnvelopeTick
	cmp r0, #0
	beq .L_080F33CE
	ldr r0, .L_080F33E0                        @ = gPsgLastVol
	ldr r2, [sp, #4]
	adds r0, r2, r0
	strh r4, [r0]
	mov r0, sl
	strh r4, [r0]
	ldr r0, .L_080F33E4                        @ = gPsgLastFreq
	adds r0, r2, r0
	movs r1, #0x80
	lsls r1, r1, #8
	strh r1, [r0]
	mov r2, sb
	strh r1, [r2]
	mov r0, r8
	ldrb r1, [r0]
	movs r0, #2
	rsbs r0, r0, #0
	ands r0, r1
	mov r1, r8
	strb r0, [r1]
.L_080F33CE:
	add sp, #8
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F33E0:
	.word gPsgLastVol
.L_080F33E4:
	.word gPsgLastFreq
.L_080F33E8:
	.word gPsgRetrig

@ --------------------------------------------------------------------------------------------------
@ psgUpdateAll  (080F33EC, Thumb)
@   void psgUpdateAll(void)
@   {   cnt = 0;
@       for (ch = 0; ch < 4; ch++) { psgUpdate(ch); cnt >>= 1;
@           if (active) { p = n->chan->pan; if (p <= 64) cnt |= 0x8000;  if (p >= 64) cnt |= 0x0800; } }
@       REG_SOUNDCNT_L = cnt | 0x77;           // hard left/right/both by pan, master volume 7
@   }
@ --------------------------------------------------------------------------------------------------
	.global psgUpdateAll
psgUpdateAll:
	push {r4, r5, r6, lr}
	ldr r6, .L_080F3444                        @ = gPsgNotes
	movs r4, #0
	movs r5, #0
.L_080F33F4:
	adds r0, r5, #0
	bl psgUpdate
	lsrs r4, r4, #1
	ldrb r0, [r6]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F342C
	ldr r0, [r6, #0xc]
	ldrb r0, [r0, #4]
	lsls r0, r0, #0x19
	lsrs r1, r0, #0x19
	cmp r1, #0x40
	bgt .L_080F341C
	movs r2, #0x80
	lsls r2, r2, #8
	adds r0, r2, #0
	orrs r4, r0
	lsls r0, r4, #0x10
	lsrs r4, r0, #0x10
.L_080F341C:
	cmp r1, #0x3f
	ble .L_080F342C
	movs r1, #0x80
	lsls r1, r1, #4
	adds r0, r1, #0
	orrs r4, r0
	lsls r0, r4, #0x10
	lsrs r4, r0, #0x10
.L_080F342C:
	adds r6, #0x20
	adds r5, #1
	cmp r5, #3
	bls .L_080F33F4
	movs r0, #0x77
	orrs r4, r0
	ldr r0, .L_080F3448                        @ = REG_SOUNDCNT_L
	strh r4, [r0]
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F3444:
	.word gPsgNotes
.L_080F3448:
	.word REG_SOUNDCNT_L

@ --------------------------------------------------------------------------------------------------
@ readBE16  (080F344C, Thumb)
@   u16 readBE16(const u8 *p)
@ --------------------------------------------------------------------------------------------------
	.global readBE16
readBE16:
	ldrb r1, [r0]
	lsls r1, r1, #8
	ldrb r0, [r0, #1]
	orrs r0, r1
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ readBE32  (080F3458, Thumb)
@   u32 readBE32(const u8 *p)
@ --------------------------------------------------------------------------------------------------
	.global readBE32
readBE32:
	adds r2, r0, #0
	ldrb r0, [r2]
	lsls r0, r0, #0x18
	ldrb r1, [r2, #1]
	lsls r1, r1, #0x10
	orrs r0, r1
	ldrb r1, [r2, #2]
	lsls r1, r1, #8
	orrs r0, r1
	ldrb r1, [r2, #3]
	orrs r0, r1
	bx lr

@ --------------------------------------------------------------------------------------------------
@ strLen8  (080F3470, Thumb)
@   u8 strLen8(const char *s)
@ --------------------------------------------------------------------------------------------------
	.global strLen8
strLen8:
	push {lr}
	adds r2, r0, #0
	movs r1, #0
	ldrb r0, [r2]
	cmp r0, #0
	beq .L_080F348A
.L_080F347C:
	adds r0, r1, #1
	lsls r0, r0, #0x18
	lsrs r1, r0, #0x18
	adds r0, r2, r1
	ldrb r0, [r0]
	cmp r0, #0
	bne .L_080F347C
.L_080F348A:
	adds r0, r1, #0
	pop {r1}
	bx r1

@ ==================================================================================================
@  PLAYERS, MIDI SEQUENCER AND PUBLIC API (0x080F3490-0x080F4988)
@  A Player plays one Standard MIDI File (format 1) on one Synth. Track k drives synth channel k:
@  the channel nibble of the MIDI status bytes is ignored.
@ ==================================================================================================

@ --------------------------------------------------------------------------------------------------
@ playerStart  (080F3490, Thumb)
@   void playerStart(Player *p, const SongEntry *e)
@   {
@       if (playerIsPlaying(p) && p->prioCheck && !p->paused && p->song->priority > e->priority) return;
@       Synth *s = p->synth;
@       synthKillAll(s);  synthInit(s, s->nChans, s->chans);
@       synthSetBank(s, sndBankTable[e->bank]);  synthSetVolume(s, e->volume);  synthSetPriority(s, e->priority);
@       p->song = e;
@       m = e->midi + 4;  hdrLen = readBE32(m);                           // "MThd"
@       p->nTracks = min(readBE16(m + 6), p->maxTracks);  p->ppqn = readBE16(m + 8);
@       m += 4 + hdrLen;
@       for each track t: { m += 4; len = readBE32(m); m += 4; t->active = 1; t->start = m;
@                           t->ptr = m; t->time = readVarLen(&t->ptr) << 8; t->snapStatus = 0;
@                           t->snapPtr = t->ptr; t->snapTime = t->time; m += len; }
@       p->looped = 0; p->paused = 0; p->tickRate = 1; p->tempoScale = p->volume = 0x100;
@       p->fadeMode = 0; p->fade = 0x8000; p->fadeStep = 0;
@       p->loopStartText = "["; p->loopStartLen = 1; p->loopEndText = "]"; p->loopEndLen = 1;
@       p->reverb[0..3] = 0x40;
@   }
@   The tempo is not reset: tickRate = 1 until the first tempo meta-event (every song has one at tick 0).
@ --------------------------------------------------------------------------------------------------
	.global playerStart
playerStart:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0x14
	adds r6, r0, #0
	adds r5, r1, #0
	bl playerIsPlaying
	cmp r0, #0
	beq .L_080F34C6
	ldr r0, [r6]
	ldr r1, .L_080F3638                        @ = 0x00200800
	ands r0, r1
	movs r1, #0x80
	lsls r1, r1, #0xe
	cmp r0, r1
	bne .L_080F34C6
	ldr r0, [r6, #0xc]
	ldrh r1, [r0, #6]
	lsrs r1, r1, #6
	ldrh r0, [r5, #6]
	lsrs r0, r0, #6
	cmp r1, r0
	ble .L_080F34C6
	b .L_080F3628
.L_080F34C6:
	ldr r4, [r6, #4]
	adds r0, r4, #0
	bl synthKillAll
	ldrb r1, [r4, #0x14]
	lsls r1, r1, #0x1b
	lsrs r1, r1, #0x1b
	ldr r2, [r4, #0x18]
	adds r0, r4, #0
	bl synthInit
	ldr r1, .L_080F363C                        @ = sndBankTable
	ldrh r0, [r5, #4]
	lsls r0, r0, #0x11
	lsrs r0, r0, #0x16
	lsls r0, r0, #2
	adds r0, r0, r1
	ldr r1, [r0]
	adds r0, r4, #0
	bl synthSetBank
	ldr r1, [r5, #4]
	lsls r1, r1, #0xa
	lsrs r1, r1, #0x19
	adds r0, r4, #0
	bl synthSetVolume
	ldrh r1, [r5, #6]
	lsrs r1, r1, #6
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	adds r0, r4, #0
	bl synthSetPriority
	str r5, [r6, #0xc]
	ldr r5, [r5]
	adds r5, #4
	adds r0, r5, #0
	bl readBE32
	adds r7, r0, #0
	adds r5, #4
	adds r0, r5, #2
	bl readBE16
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	movs r4, #0x1f
	ands r0, r4
	lsls r0, r0, #5
	ldrh r1, [r6]
	ldr r3, .L_080F3640                        @ = 0xFFFFFC1F
	adds r2, r3, #0
	ands r2, r1
	orrs r2, r0
	strh r2, [r6]
	lsls r1, r2, #0x16
	lsrs r1, r1, #0x1b
	ldrb r0, [r6]
	lsls r0, r0, #0x1b
	lsrs r0, r0, #0x1b
	cmp r1, r0
	ble .L_080F354E
	ands r0, r4
	lsls r0, r0, #5
	ands r2, r3
	orrs r2, r0
	strh r2, [r6]
.L_080F354E:
	adds r0, r5, #4
	bl readBE16
	strh r0, [r6, #0x22]
	adds r5, r5, r7
	ldr r4, [r6, #8]
	movs r0, #0
	mov r8, r0
	ldrh r0, [r6]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	movs r1, #0x20
	adds r1, r1, r6
	mov sb, r1
	movs r7, #0x21
	adds r7, r7, r6
	mov sl, r7
	adds r1, r6, #0
	adds r1, #0x2c
	str r1, [sp, #4]
	adds r7, r6, #0
	adds r7, #0x2d
	str r7, [sp, #8]
	adds r1, #2
	str r1, [sp, #0xc]
	adds r7, #2
	str r7, [sp, #0x10]
	cmp r8, r0
	bhs .L_080F35D0
.L_080F3588:
	adds r5, #4
	adds r0, r5, #0
	bl readBE32
	adds r7, r0, #0
	adds r5, #4
	str r5, [sp]
	adds r5, r5, r7
	ldrb r0, [r4]
	movs r1, #1
	orrs r0, r1
	strb r0, [r4]
	ldr r0, [sp]
	str r0, [r4, #4]
	mov r0, sp
	bl readVarLen
	lsls r0, r0, #8
	str r0, [r4, #0xc]
	ldr r3, [sp]
	str r3, [r4, #8]
	ldrh r1, [r4, #2]
	ldr r7, .L_080F3644                        @ = 0xFFFFFC03
	adds r2, r7, #0
	ands r1, r2
	strh r1, [r4, #2]
	str r3, [r4, #0x18]
	str r0, [r4, #0x1c]
	adds r4, #0x24
	movs r0, #1
	add r8, r0
	ldrh r0, [r6]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r8, r0
	blo .L_080F3588
.L_080F35D0:
	ldrb r1, [r6, #1]
	movs r0, #5
	rsbs r0, r0, #0
	ands r0, r1
	movs r1, #9
	rsbs r1, r1, #0
	ands r0, r1
	strb r0, [r6, #1]
	movs r0, #1
	str r0, [r6, #0x10]
	movs r2, #0
	adds r0, #0xff
	strh r0, [r6, #0x24]
	strh r0, [r6, #0x26]
	ldrb r1, [r6, #3]
	movs r0, #0x39
	rsbs r0, r0, #0
	ands r0, r1
	strb r0, [r6, #3]
	movs r0, #0x80
	lsls r0, r0, #8
	strh r0, [r6, #0x28]
	strh r2, [r6, #0x2a]
	ldr r0, .L_080F3648                        @ = seqLoopStartMarker
	str r0, [r6, #0x18]
	bl strLen8
	mov r1, sb
	strb r0, [r1]
	ldr r0, .L_080F364C                        @ = seqLoopEndMarker
	str r0, [r6, #0x1c]
	bl strLen8
	mov r7, sl
	strb r0, [r7]
	movs r0, #0x40
	ldr r1, [sp, #4]
	strb r0, [r1]
	ldr r7, [sp, #8]
	strb r0, [r7]
	ldr r1, [sp, #0xc]
	strb r0, [r1]
	ldr r7, [sp, #0x10]
	strb r0, [r7]
.L_080F3628:
	add sp, #0x14
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
.L_080F3638:
	.word 0x00200800
.L_080F363C:
	.word sndBankTable
.L_080F3640:
	.word 0xFFFFFC1F
.L_080F3644:
	.word 0xFFFFFC03
.L_080F3648:
	.word seqLoopStartMarker
.L_080F364C:
	.word seqLoopEndMarker

@ --------------------------------------------------------------------------------------------------
@ sndPlay  (080F3650, Thumb)
@   void sndPlay(u16 id)                        // the only way the game starts sounds
@   {   const SoundId *e = &sndSoundIdTable[id];  playerStart(sndGroups[e->group].player, e->song); }
@ --------------------------------------------------------------------------------------------------
	.global sndPlay
sndPlay:
	push {lr}
	lsls r0, r0, #0x10
	ldr r3, .L_080F3674                        @ = sndGroups
	ldr r1, .L_080F3678                        @ = 0x084140CC
	lsrs r0, r0, #0xd
	adds r0, r0, r1
	ldrh r2, [r0, #4]
	lsls r1, r2, #1
	adds r1, r1, r2
	lsls r1, r1, #2
	adds r1, r1, r3
	ldr r2, [r1]
	ldr r1, [r0]
	adds r0, r2, #0
	bl playerStart
	pop {r0}
	bx r0
.L_080F3674:
	.word sndGroups
.L_080F3678:
	.word 0x084140CC

@ --------------------------------------------------------------------------------------------------
@ playerStop  (080F367C, Thumb)
@   void playerStop(Player *p)  { synthReleaseAll(p->synth); p->song = 0; }
@ --------------------------------------------------------------------------------------------------
	.global playerStop
playerStop:
	push {r4, lr}
	adds r4, r0, #0
	ldr r0, [r4, #4]
	bl synthReleaseAll
	movs r0, #0
	str r0, [r4, #0xc]
	pop {r4}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerSetPause  (080F3690, Thumb)
@   void playerSetPause(Player *p, int on)  { p->paused = on & 1; if (on) synthKillAll(p->synth); }
@ --------------------------------------------------------------------------------------------------
	.global playerSetPause
playerSetPause:
	push {r4, lr}
	adds r4, r0, #0
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	movs r0, #1
	adds r2, r1, #0
	ands r2, r0
	lsls r2, r2, #3
	ldrb r3, [r4, #1]
	movs r0, #9
	rsbs r0, r0, #0
	ands r0, r3
	orrs r0, r2
	strb r0, [r4, #1]
	cmp r1, #0
	beq .L_080F36B6
	ldr r0, [r4, #4]
	bl synthKillAll
.L_080F36B6:
	pop {r4}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerIsPlaying  (080F36BC, Thumb)
@   int playerIsPlaying(Player *p)  { return p->song && any track active; }
@ --------------------------------------------------------------------------------------------------
	.global playerIsPlaying
playerIsPlaying:
	push {lr}
	adds r1, r0, #0
	ldr r0, [r1, #0xc]
	cmp r0, #0
	bne .L_080F36CC
	b .L_080F36EC
.L_080F36C8:
	movs r0, #1
	b .L_080F36EE
.L_080F36CC:
	movs r2, #0
	ldrh r0, [r1]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r2, r0
	bhs .L_080F36EC
	adds r3, r0, #0
	ldr r1, [r1, #8]
.L_080F36DC:
	ldrb r0, [r1]
	lsls r0, r0, #0x1f
	cmp r0, #0
	bne .L_080F36C8
	adds r1, #0x24
	adds r2, #1
	cmp r2, r3
	blo .L_080F36DC
.L_080F36EC:
	movs r0, #0
.L_080F36EE:
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ playerPause  (080F36F4, Thumb)
@   void playerPause(Player *p)   { playerSetPause(p, 1); }
@ --------------------------------------------------------------------------------------------------
	.global playerPause
playerPause:
	push {lr}
	movs r1, #1
	bl playerSetPause
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerResume  (080F3700, Thumb)
@   void playerResume(Player *p)  { playerSetPause(p, 0); }
@ --------------------------------------------------------------------------------------------------
	.global playerResume
playerResume:
	push {lr}
	movs r1, #0
	bl playerSetPause
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ sndPauseAll  (080F370C, Thumb)
@   void sndPauseAll(void)   { for each of the 9 players playerSetPause(p, 1); }
@ --------------------------------------------------------------------------------------------------
	.global sndPauseAll
sndPauseAll:
	push {r4, r5, r6, lr}
	movs r4, #0
	ldr r1, .L_080F3734                        @ = sndLastPlayer
	ldr r0, [r1]
	cmp r4, r0
	bhi .L_080F372C
	ldr r6, .L_080F3738                        @ = sndPlayers
	adds r5, r1, #0
.L_080F371C:
	ldm r6!, {r0}
	movs r1, #1
	bl playerSetPause
	adds r4, #1
	ldr r0, [r5]
	cmp r4, r0
	bls .L_080F371C
.L_080F372C:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F3734:
	.word sndLastPlayer
.L_080F3738:
	.word sndPlayers

@ --------------------------------------------------------------------------------------------------
@ sndResumeAll  (080F373C, Thumb)
@   void sndResumeAll(void)  { for each of the 9 players playerSetPause(p, 0); }
@ --------------------------------------------------------------------------------------------------
	.global sndResumeAll
sndResumeAll:
	push {r4, r5, r6, lr}
	movs r4, #0
	ldr r1, .L_080F3764                        @ = sndLastPlayer
	ldr r0, [r1]
	cmp r4, r0
	bhi .L_080F375C
	ldr r6, .L_080F3768                        @ = sndPlayers
	adds r5, r1, #0
.L_080F374C:
	ldm r6!, {r0}
	movs r1, #0
	bl playerSetPause
	adds r4, #1
	ldr r0, [r5]
	cmp r4, r0
	bls .L_080F374C
.L_080F375C:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F3764:
	.word sndLastPlayer
.L_080F3768:
	.word sndPlayers

@ --------------------------------------------------------------------------------------------------
@ playerSetVolume  (080F376C, Thumb)
@   void playerSetVolume(Player *p, int unused, int v)  { p->volume = v; }   // 0x100 = 1.0
@ --------------------------------------------------------------------------------------------------
	.global playerSetVolume
playerSetVolume:
	strh r2, [r0, #0x26]
	bx lr

@ --------------------------------------------------------------------------------------------------
@ playerSetTune  (080F3770, Thumb)
@   void playerSetTune(Player *p, int unused, int v)    { synthSetTune(p->synth, v); }
@ --------------------------------------------------------------------------------------------------
	.global playerSetTune
playerSetTune:
	push {lr}
	ldr r0, [r0, #4]
	lsls r1, r2, #0x10
	asrs r1, r1, #0x10
	bl synthSetTune
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerSetPan  (080F3780, Thumb)
@   void playerSetPan(Player *p, int unused, int v)     { synthSetPan(p->synth, v); }
@ --------------------------------------------------------------------------------------------------
	.global playerSetPan
playerSetPan:
	push {lr}
	ldr r0, [r0, #4]
	lsls r1, r2, #0x18
	asrs r1, r1, #0x18
	bl synthSetPan
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ sndPauseSound  (080F3790, Thumb)
@   void sndPauseSound(u16 id)  (not called)  { pause every player whose current song is sndSoundIdTable[id].song }
@ --------------------------------------------------------------------------------------------------
	.global sndPauseSound
sndPauseSound:
	push {r4, r5, r6, lr}
	lsls r0, r0, #0x10
	ldr r1, .L_080F37CC                        @ = 0x084140CC
	lsrs r0, r0, #0xd
	adds r0, r0, r1
	ldr r6, [r0]
	movs r4, #0
	ldr r0, .L_080F37D0                        @ = sndLastPlayer
	ldr r0, [r0]
	cmp r4, r0
	bhi .L_080F37C6
	ldr r5, .L_080F37D4                        @ = sndPlayers
.L_080F37A8:
	ldr r1, [r5]
	cmp r1, #0
	beq .L_080F37BA
	ldr r0, [r1, #0xc]
	cmp r0, r6
	bne .L_080F37BA
	adds r0, r1, #0
	bl playerPause
.L_080F37BA:
	adds r5, #4
	adds r4, #1
	ldr r0, .L_080F37D0                        @ = sndLastPlayer
	ldr r0, [r0]
	cmp r4, r0
	bls .L_080F37A8
.L_080F37C6:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
.L_080F37CC:
	.word 0x084140CC
.L_080F37D0:
	.word sndLastPlayer
.L_080F37D4:
	.word sndPlayers

@ --------------------------------------------------------------------------------------------------
@ memEqual  (080F37D8, Thumb)
@   int memEqual(const u8 *a, const u8 *b, int n)
@ --------------------------------------------------------------------------------------------------
	.global memEqual
memEqual:
	push {r4, r5, lr}
	adds r5, r0, #0
	adds r4, r1, #0
	movs r3, #0
	cmp r3, r2
	bhs .L_080F37FA
.L_080F37E4:
	adds r0, r5, r3
	adds r1, r4, r3
	ldrb r0, [r0]
	ldrb r1, [r1]
	cmp r0, r1
	beq .L_080F37F4
	movs r0, #0
	b .L_080F37FC
.L_080F37F4:
	adds r3, #1
	cmp r3, r2
	blo .L_080F37E4
.L_080F37FA:
	movs r0, #1
.L_080F37FC:
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ calcTickRate  (080F3804, Thumb)
@   u32 calcTickRate(u16 bpm, u16 scale, u16 ppqn)  { return bpm * scale * ppqn / 3600; }   // MIDI ticks per frame << 8, 60 frames/s
@ --------------------------------------------------------------------------------------------------
	.global calcTickRate
calcTickRate:
	push {lr}
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	lsls r2, r2, #0x10
	lsrs r2, r2, #0x10
	muls r0, r1, r0
	muls r0, r2, r0
	movs r1, #0xe1
	lsls r1, r1, #4
	bl __udivsi3
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ playerSetTempoScale  (080F3824, Thumb)
@   void playerSetTempoScale(Player *p, u16 scale)
@   {   p->tempoScale = scale; p->tickRate = calcTickRate(p->tempo, scale, p->ppqn) ?: 1; }
@ --------------------------------------------------------------------------------------------------
	.global playerSetTempoScale
playerSetTempoScale:
	push {r4, lr}
	adds r4, r0, #0
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	strh r1, [r4, #0x24]
	ldr r0, [r4]
	lsls r0, r0, #0xb
	lsrs r0, r0, #0x17
	ldrh r2, [r4, #0x22]
	bl calcTickRate
	cmp r0, #0
	bne .L_080F3840
	movs r0, #1
.L_080F3840:
	str r0, [r4, #0x10]
	pop {r4}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerFade  (080F3848, Thumb)
@   void playerFade(Player *p, int mode, int frames)   // mode 0 none, 1 in, 2 out+stop, 3 out+pause
@   {
@       switch (mode) {
@       case 0: p->fade = 0x8000; p->fadeStep = 0; break;
@       case 1: if (!frames) frames = 1; if (!p->fadeMode) p->fade = 0; p->fadeStep = 0x8000 / frames; p->paused = 0; break;
@       case 2: case 3:
@           if (!frames) { mode == 2 ? playerStop(p) : playerPause(p); break; }
@           if (!p->fadeMode) p->fade = 0x8000;  p->fadeStep = 0x8000 / frames;
@       }
@       p->fadeMode = mode;
@   }
@ --------------------------------------------------------------------------------------------------
	.global playerFade
playerFade:
	push {r4, r5, lr}
	adds r4, r0, #0
	lsls r1, r1, #0x10
	lsrs r5, r1, #0x10
	lsls r2, r2, #0x10
	lsrs r1, r2, #0x10
	cmp r5, #1
	beq .L_080F3880
	cmp r5, #1
	bgt .L_080F3862
	cmp r5, #0
	beq .L_080F3876
	b .L_080F38CC
.L_080F3862:
	cmp r5, #3
	bgt .L_080F38CC
	cmp r1, #0
	beq .L_080F38BA
	ldrb r0, [r4, #3]
	lsls r0, r0, #0x1a
	lsrs r0, r0, #0x1d
	cmp r0, #0
	bne .L_080F38AE
	b .L_080F38A8
.L_080F3876:
	movs r0, #0x80
	lsls r0, r0, #8
	strh r0, [r4, #0x28]
	strh r5, [r4, #0x2a]
	b .L_080F38CC
.L_080F3880:
	cmp r1, #0
	bne .L_080F3886
	movs r1, #1
.L_080F3886:
	ldrb r0, [r4, #3]
	lsls r0, r0, #0x1a
	lsrs r0, r0, #0x1d
	cmp r0, #0
	bne .L_080F3892
	strh r0, [r4, #0x28]
.L_080F3892:
	movs r0, #0x80
	lsls r0, r0, #8
	bl __divsi3
	strh r0, [r4, #0x2a]
	ldrb r1, [r4, #1]
	movs r0, #9
	rsbs r0, r0, #0
	ands r0, r1
	strb r0, [r4, #1]
	b .L_080F38CC
.L_080F38A8:
	movs r0, #0x80
	lsls r0, r0, #8
	strh r0, [r4, #0x28]
.L_080F38AE:
	movs r0, #0x80
	lsls r0, r0, #8
	bl __divsi3
	strh r0, [r4, #0x2a]
	b .L_080F38CC
.L_080F38BA:
	cmp r5, #2
	bne .L_080F38C6
	adds r0, r4, #0
	bl playerStop
	b .L_080F38CC
.L_080F38C6:
	adds r0, r4, #0
	bl playerPause
.L_080F38CC:
	movs r0, #7
	adds r1, r5, #0
	ands r1, r0
	lsls r1, r1, #3
	ldrb r2, [r4, #3]
	movs r0, #0x39
	rsbs r0, r0, #0
	ands r0, r2
	orrs r0, r1
	strb r0, [r4, #3]
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ playerFadeOutStop  (080F38E8, Thumb)
@   void playerFadeOutStop(Player *p, u16 t)   { playerFade(p, 2, t << 4 & 0xFFFF); }
@ --------------------------------------------------------------------------------------------------
	.global playerFadeOutStop
playerFadeOutStop:
	push {lr}
	lsls r2, r1, #0x14
	lsrs r2, r2, #0x10
	movs r1, #2
	bl playerFade
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerFadeOutPause  (080F38F8, Thumb)
@   void playerFadeOutPause(Player *p, u16 t)  { playerFade(p, 3, t << 4 & 0xFFFF); }
@ --------------------------------------------------------------------------------------------------
	.global playerFadeOutPause
playerFadeOutPause:
	push {lr}
	lsls r2, r1, #0x14
	lsrs r2, r2, #0x10
	movs r1, #3
	bl playerFade
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ playerFadeIn  (080F3908, Thumb)
@   void playerFadeIn(Player *p, u16 t)        { playerFade(p, 1, t << 4 & 0xFFFF); }
@ --------------------------------------------------------------------------------------------------
	.global playerFadeIn
playerFadeIn:
	push {lr}
	lsls r2, r1, #0x14
	lsrs r2, r2, #0x10
	movs r1, #1
	bl playerFade
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ seqSysEx  (080F3918, Thumb)
@   void seqSysEx(Player *p, const u8 *d)       // d = SysEx data after the length
@   {
@       switch (*d++) {
@       case 0: mixClearEffects(); gSweepMode = 0; gSweepDepth = d[0] * 2;
@               sweepInit(&gSweep, d[1]*2, d[2]*2, d[3]*2, d[4]*2, d[5]*2);  mixSetFilterGain(d[6]);
@               gSweepPlayer = p; break;
@       case 1: for (i = 0; i < 12; i++) p->synth->scale[i] = d[i] - 0x40; break;      // random-key scale
@       }
@   }
@ --------------------------------------------------------------------------------------------------
	.global seqSysEx
seqSysEx:
	push {r4, r5, r6, lr}
	sub sp, #8
	adds r6, r0, #0
	adds r5, r1, #0
	ldr r1, [r6, #4]
	ldrb r4, [r5]
	adds r5, #1
	cmp r4, #0
	beq .L_080F3930
	cmp r4, #1
	beq .L_080F3984
	b .L_080F399A
.L_080F3930:
	bl mixClearEffects
	ldr r0, .L_080F3974                        @ = gSweepMode
	strb r4, [r0]
	ldr r1, .L_080F3978                        @ = gSweepDepth
	ldrb r0, [r5]
	lsls r0, r0, #1
	strb r0, [r1]
	ldr r0, .L_080F397C                        @ = gSweep
	ldrb r1, [r5, #1]
	lsls r1, r1, #0x19
	lsrs r1, r1, #0x18
	ldrb r2, [r5, #2]
	lsls r2, r2, #0x19
	lsrs r2, r2, #0x18
	ldrb r3, [r5, #3]
	lsls r3, r3, #0x19
	lsrs r3, r3, #0x18
	ldrb r4, [r5, #4]
	lsls r4, r4, #0x19
	lsrs r4, r4, #0x18
	str r4, [sp]
	ldrb r4, [r5, #5]
	lsls r4, r4, #0x19
	lsrs r4, r4, #0x18
	str r4, [sp, #4]
	bl sweepInit
	ldrb r0, [r5, #6]
	bl mixSetFilterGain
	ldr r0, .L_080F3980                        @ = gSweepPlayer
	str r6, [r0]
	b .L_080F399A
.L_080F3974:
	.word gSweepMode
.L_080F3978:
	.word gSweepDepth
.L_080F397C:
	.word gSweep
.L_080F3980:
	.word gSweepPlayer
.L_080F3984:
	movs r2, #0
	adds r3, r1, #0
	adds r3, #0x1c
.L_080F398A:
	adds r1, r3, r2
	adds r0, r5, r2
	ldrb r0, [r0]
	subs r0, #0x40
	strb r0, [r1]
	adds r2, #1
	cmp r2, #0xb
	bls .L_080F398A
.L_080F399A:
	add sp, #8
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ seqMetaEvent  (080F39A4, Thumb)
@   int seqMetaEvent(Player *p, const u8 **pp)    // *pp points at the type byte; returns 1 at end of track
@   {
@       type = *(*pp)++;  len = readVarLen(pp);  data = *pp;  *pp += len;
@       if (type == 0x2F) return 1;
@       if (type == 0x06) {                                            // marker
@           if (len == p->loopStartLen && memEqual(p->loopStartText, data, len)) gSeqLoopStartHit = 1;
@           else if (len == p->loopEndLen && memEqual(p->loopEndText, data, len) && p->looped) gSeqLoopEndHit = 1;
@       }
@       if (type == 0x51) {                                            // tempo
@           p->tempo = 60000000 / (d0 << 16 | d1 << 8 | d2);           // whole BPM, 9 bits
@           gSeqNewTickRate = calcTickRate(p->tempo, p->tempoScale, p->ppqn);
@       }
@       return 0;
@   }
@ --------------------------------------------------------------------------------------------------
	.global seqMetaEvent
seqMetaEvent:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	sub sp, #4
	adds r6, r0, #0
	adds r4, r1, #0
	ldr r0, [r4]
	str r0, [sp]
	ldrb r5, [r0]
	mov r8, r5
	adds r0, #1
	str r0, [sp]
	mov r0, sp
	bl readVarLen
	adds r7, r0, #0
	ldr r2, [sp]
	adds r0, r2, r7
	str r0, [r4]
	cmp r5, #0x2f
	beq .L_080F3A2C
	cmp r5, #0x2f
	bgt .L_080F39D8
	cmp r5, #6
	beq .L_080F39E0
	b .L_080F3A64
.L_080F39D8:
	mov r0, r8
	cmp r0, #0x51
	beq .L_080F3A30
	b .L_080F3A64
.L_080F39E0:
	adds r0, r6, #0
	adds r0, #0x20
	ldrb r0, [r0]
	cmp r7, r0
	bne .L_080F3A00
	ldr r0, [r6, #0x18]
	adds r1, r2, #0
	adds r2, r7, #0
	bl memEqual
	cmp r0, #0
	beq .L_080F3A00
	ldr r1, .L_080F39FC                        @ = gSeqLoopStartHit
	b .L_080F3A22
.L_080F39FC:
	.word gSeqLoopStartHit
.L_080F3A00:
	adds r0, r6, #0
	adds r0, #0x21
	ldrb r0, [r0]
	cmp r7, r0
	bne .L_080F3A64
	ldr r0, [r6, #0x1c]
	ldr r1, [sp]
	adds r2, r7, #0
	bl memEqual
	cmp r0, #0
	beq .L_080F3A64
	ldrb r0, [r6, #1]
	lsls r0, r0, #0x1d
	cmp r0, #0
	bge .L_080F3A64
	ldr r1, .L_080F3A28                        @ = gSeqLoopEndHit
.L_080F3A22:
	movs r0, #1
	strb r0, [r1]
	b .L_080F3A64
.L_080F3A28:
	.word gSeqLoopEndHit
.L_080F3A2C:
	movs r0, #1
	b .L_080F3A66
.L_080F3A30:
	ldrb r1, [r2]
	lsls r1, r1, #0x10
	ldrb r0, [r2, #1]
	lsls r0, r0, #8
	orrs r1, r0
	ldrb r0, [r2, #2]
	orrs r1, r0
	ldr r0, .L_080F3A74                        @ = 0x03938700
	bl __udivsi3
	ldr r2, .L_080F3A78                        @ = 0x000001FF
	ands r2, r0
	lsls r2, r2, #0xc
	ldr r1, [r6]
	ldr r3, .L_080F3A7C                        @ = 0xFFE00FFF
	ands r1, r3
	orrs r1, r2
	str r1, [r6]
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	ldrh r1, [r6, #0x24]
	ldrh r2, [r6, #0x22]
	bl calcTickRate
	ldr r1, .L_080F3A80                        @ = gSeqNewTickRate
	str r0, [r1]
.L_080F3A64:
	movs r0, #0
.L_080F3A66:
	add sp, #4
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000
.L_080F3A74:
	.word 0x03938700
.L_080F3A78:
	.word 0x000001FF
.L_080F3A7C:
	.word 0xFFE00FFF
.L_080F3A80:
	.word gSeqNewTickRate

@ --------------------------------------------------------------------------------------------------
@ seqControlChange  (080F3A84, Thumb)
@   void seqControlChange(Player *p, int ci, int cc, int v)
@   {
@       Synth *s = p->synth;
@       switch (cc) {                       // everything not listed is ignored
@       case  0: chanSetBankSelect(s, ci, v | 0x8000); break;      case 32: chanSetBankSelect(s, ci, v); break;
@       case  1: chanSetModDepth(s, ci, v); break;                 case  7: chanSetVolume(s, ci, v); break;
@       case 10: chanSetPan(s, ci, v); break;                      case 11: chanSetExpression(s, ci, v); break;
@       case 14: gGameVarIndex = v; break;
@       case 16: if (gGameVarIndex < gGameVarCount) gGameVars[gGameVarIndex] = v; break;   // tells the game code
@       case 20: chanSetBendRange(s, ci, v); break;                case 21: chanSetLfoSpeed(s, ci, v); break;
@       case 22: chanSetLfoType(s, ci, v); break;                  case 26: chanSetLfoDelay(s, ci, v); break;
@       case 33: chanSetPriority(s, ci, v); break;                 case 72: chanSetWet(s, ci, v); break;
@       case 73: gSweepMode = v; if (v == 0 || v == 1) sweepStop(&gSweep);
@                else if (v == 2) { mixClearEffects(); sweepStart(&gSweep); } break;
@       case 74: gSweepMode = 0; sweepStop(&gSweep); mixClearEffects(); mixSetFilter(v*2 - 128); break;
@       case 75: chanSetInvert(s, ci, v); break;                   case 76: gSweepDepth = v * 2; break;
@       case 77: mixSetFilterGain(v); break;
@       case 78: case 79: case 80: case 81: p->reverb[cc - 78] = v; break;
@       case 82: chanSetRandomPitch(s, ci, v); break;              case 83: chanSetRandomKey(s, ci, v); break;
@       case 84: chanSetRandomKeyRate(s, ci, v); break;
@       }
@   }
@ --------------------------------------------------------------------------------------------------
	.global seqControlChange
seqControlChange:
	push {r4, r5, r6, lr}
	adds r6, r0, #0
	adds r4, r1, #0
	lsls r2, r2, #0x18
	lsrs r0, r2, #0x18
	lsls r3, r3, #0x18
	lsrs r5, r3, #0x18
	ldr r3, [r6, #4]
	cmp r0, #0x54
	bls .L_080F3A9A
	b .L_080F3D7E
.L_080F3A9A:
	lsls r0, r0, #2
	ldr r1, .L_080F3AA4                        @ = 0x080F3AA8
	adds r0, r0, r1
	ldr r0, [r0]
	mov pc, r0
.L_080F3AA4:
	.word 0x080F3AA8
	.word .L_080F3BFC
	.word .L_080F3C10
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3C1C
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3C28
	.word .L_080F3C34
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3C88
	.word .L_080F3D7E
	.word .L_080F3C94
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3C40
	.word .L_080F3C4C
	.word .L_080F3C58
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3C64
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3C70
	.word .L_080F3C7C
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3D7E
	.word .L_080F3CB8
	.word .L_080F3CC4
	.word .L_080F3CF8
	.word .L_080F3D30
	.word .L_080F3D1C
	.word .L_080F3D28
	.word .L_080F3D3C
	.word .L_080F3D44
	.word .L_080F3D4C
	.word .L_080F3D54
	.word .L_080F3D5C
	.word .L_080F3D68
	.word .L_080F3D74
.L_080F3BFC:
	movs r1, #0x80
	lsls r1, r1, #8
	adds r0, r1, #0
	adds r2, r5, #0
	orrs r2, r0
	adds r0, r3, #0
	adds r1, r4, #0
	bl chanSetBankSelect
	b .L_080F3D7E
.L_080F3C10:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetModDepth
	b .L_080F3D7E
.L_080F3C1C:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetVolume
	b .L_080F3D7E
.L_080F3C28:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetPan
	b .L_080F3D7E
.L_080F3C34:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetExpression
	b .L_080F3D7E
.L_080F3C40:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetBendRange
	b .L_080F3D7E
.L_080F3C4C:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetLfoSpeed
	b .L_080F3D7E
.L_080F3C58:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetLfoType
	b .L_080F3D7E
.L_080F3C64:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetLfoDelay
	b .L_080F3D7E
.L_080F3C70:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetBankSelect
	b .L_080F3D7E
.L_080F3C7C:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetPriority
	b .L_080F3D7E
.L_080F3C88:
	ldr r0, .L_080F3C90                        @ = gGameVarIndex
	strh r5, [r0]
	b .L_080F3D7E
	.hword 0x0000
.L_080F3C90:
	.word gGameVarIndex
.L_080F3C94:
	ldr r2, .L_080F3CAC                        @ = gGameVarIndex
	ldr r1, .L_080F3CB0                        @ = gGameVarCount
	ldrh r0, [r2]
	ldrh r1, [r1]
	cmp r0, r1
	bhs .L_080F3D7E
	adds r1, r0, #0
	ldr r0, .L_080F3CB4                        @ = gGameVars
	ldr r0, [r0]
	adds r0, r0, r1
	strb r5, [r0]
	b .L_080F3D7E
.L_080F3CAC:
	.word gGameVarIndex
.L_080F3CB0:
	.word gGameVarCount
.L_080F3CB4:
	.word gGameVars
.L_080F3CB8:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetWet
	b .L_080F3D7E
.L_080F3CC4:
	ldr r0, .L_080F3CD8                        @ = gSweepMode
	strb r5, [r0]
	cmp r5, #0
	blt .L_080F3D7E
	cmp r5, #1
	ble .L_080F3CDC
	cmp r5, #2
	beq .L_080F3CE8
	b .L_080F3D7E
	.hword 0x0000
.L_080F3CD8:
	.word gSweepMode
.L_080F3CDC:
	ldr r0, .L_080F3CE4                        @ = gSweep
	bl sweepStop
	b .L_080F3D7E
.L_080F3CE4:
	.word gSweep
.L_080F3CE8:
	bl mixClearEffects
	ldr r0, .L_080F3CF4                        @ = gSweep
	bl sweepStart
	b .L_080F3D7E
.L_080F3CF4:
	.word gSweep
.L_080F3CF8:
	ldr r1, .L_080F3D14                        @ = gSweepMode
	movs r0, #0
	strb r0, [r1]
	ldr r0, .L_080F3D18                        @ = gSweep
	bl sweepStop
	bl mixClearEffects
	lsls r0, r5, #1
	subs r0, #0x80
	bl mixSetFilter
	b .L_080F3D7E
	.hword 0x0000
.L_080F3D14:
	.word gSweepMode
.L_080F3D18:
	.word gSweep
.L_080F3D1C:
	ldr r1, .L_080F3D24                        @ = gSweepDepth
	lsls r0, r5, #1
	strb r0, [r1]
	b .L_080F3D7E
.L_080F3D24:
	.word gSweepDepth
.L_080F3D28:
	adds r0, r5, #0
	bl mixSetFilterGain
	b .L_080F3D7E
.L_080F3D30:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetInvert
	b .L_080F3D7E
.L_080F3D3C:
	adds r0, r6, #0
	adds r0, #0x2c
	strb r5, [r0]
	b .L_080F3D7E
.L_080F3D44:
	adds r0, r6, #0
	adds r0, #0x2d
	strb r5, [r0]
	b .L_080F3D7E
.L_080F3D4C:
	adds r0, r6, #0
	adds r0, #0x2e
	strb r5, [r0]
	b .L_080F3D7E
.L_080F3D54:
	adds r0, r6, #0
	adds r0, #0x2f
	strb r5, [r0]
	b .L_080F3D7E
.L_080F3D5C:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetRandomPitch
	b .L_080F3D7E
.L_080F3D68:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetRandomKey
	b .L_080F3D7E
.L_080F3D74:
	adds r0, r3, #0
	adds r1, r4, #0
	adds r2, r5, #0
	bl chanSetRandomKeyRate
.L_080F3D7E:
	pop {r4, r5, r6}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ seqQueueNote  (080F3D84, Thumb)
@   void seqQueueNote(int ci, int key, int vel)     // up to 20 per track and tick; the rest are dropped
@   {   if (gNoteQueueLen < 20) gNoteQueue[gNoteQueueLen++] = { ci & 15, key & 0x7F, vel & 0x7F }; }
@ --------------------------------------------------------------------------------------------------
	.global seqQueueNote
seqQueueNote:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	adds r5, r1, #0
	adds r6, r2, #0
	ldr r1, .L_080F3DD8                        @ = gNoteQueueLen
	ldrh r0, [r1]
	adds r3, r0, #0
	cmp r3, #0x13
	bhi .L_080F3DD0
	adds r0, #1
	strh r0, [r1]
	lsls r3, r3, #2
	ldr r0, .L_080F3DDC                        @ = gNoteQueue
	adds r3, r3, r0
	movs r0, #0xf
	ands r4, r0
	ldrb r1, [r3]
	movs r0, #0x10
	rsbs r0, r0, #0
	ands r0, r1
	orrs r0, r4
	strb r0, [r3]
	movs r0, #0x7f
	ands r5, r0
	lsls r2, r5, #4
	ldrh r1, [r3]
	ldr r0, .L_080F3DE0                        @ = 0xFFFFF80F
	ands r0, r1
	orrs r0, r2
	strh r0, [r3]
	movs r1, #0x7f
	ands r1, r6
	lsls r1, r1, #0xb
	ldr r0, [r3]
	ldr r2, .L_080F3DE4                        @ = 0xFFFC07FF
	ands r0, r2
	orrs r0, r1
	str r0, [r3]
.L_080F3DD0:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F3DD8:
	.word gNoteQueueLen
.L_080F3DDC:
	.word gNoteQueue
.L_080F3DE0:
	.word 0xFFFFF80F
.L_080F3DE4:
	.word 0xFFFC07FF

@ --------------------------------------------------------------------------------------------------
@ seqTrackEvent  (080F3DE8, Thumb)
@   int seqTrackEvent(Player *p, int t)          // one event; returns 1 at end of track
@   {
@       Track *tr = &p->tracks[t];  const u8 *d = tr->ptr;
@       if (*d & 0x80) tr->status = *d++;                              // running status otherwise
@       st = tr->status;
@       if (st >= 0xF0) {
@           if ((st & 15) == 0) { len = readVarLen(&d); seqSysEx(p, d); d += len; }
@           else if ((st & 15) == 15) { if (seqMetaEvent(p, &d)) { chanSetLfoSpeed(p->synth, t, 0); return 1; } }
@           else { len = readVarLen(&d); d += len; }
@       } else switch (st & 0xF0) {                                    // channel = track index t
@       case 0x80: seqQueueNote(t, d[0], 0); d += 2; break;
@       case 0x90: seqQueueNote(t, d[0], d[1]); d += 2; break;
@       case 0xA0: d += 2; break;
@       case 0xB0: seqControlChange(p, t, d[0], d[1]); d += 2; break;
@       case 0xC0: chanSetProgram(p->synth, t, d[0]); d += 1; break;
@       case 0xD0: d += 1; break;
@       case 0xE0: chanSetPitchBend(p->synth, t, (d[0] & 0x7F) | (d[1] & 0x7F) << 7); d += 2; break;
@       }
@       tr->ptr = d;  return 0;
@   }
@ --------------------------------------------------------------------------------------------------
	.global seqTrackEvent
seqTrackEvent:
	push {r4, r5, r6, lr}
	sub sp, #4
	adds r5, r0, #0
	adds r4, r1, #0
	lsls r0, r4, #3
	adds r0, r0, r4
	lsls r0, r0, #2
	ldr r1, [r5, #8]
	adds r6, r1, r0
	ldr r3, [r6, #8]
	str r3, [sp]
	ldrb r2, [r3]
	movs r0, #0x80
	ands r0, r2
	cmp r0, #0
	beq .L_080F3E18
	lsls r2, r2, #2
	ldrh r1, [r6]
	ldr r0, .L_080F3E3C                        @ = 0xFFFFFC03
	ands r0, r1
	orrs r0, r2
	strh r0, [r6]
	adds r0, r3, #1
	str r0, [sp]
.L_080F3E18:
	ldrh r0, [r6]
	lsls r0, r0, #0x16
	lsrs r2, r0, #0x18
	cmp r2, #0xef
	bls .L_080F3E70
	movs r0, #0xf
	ands r0, r2
	cmp r0, #0
	beq .L_080F3E40
	cmp r0, #0xf
	beq .L_080F3E56
	mov r0, sp
	bl readVarLen
	adds r4, r0, #0
	ldr r0, [sp]
	adds r0, r0, r4
	b .L_080F3F06
.L_080F3E3C:
	.word 0xFFFFFC03
.L_080F3E40:
	mov r0, sp
	bl readVarLen
	adds r4, r0, #0
	ldr r1, [sp]
	adds r0, r5, #0
	bl seqSysEx
	ldr r0, [sp]
	adds r0, r0, r4
	b .L_080F3F06
.L_080F3E56:
	adds r0, r5, #0
	mov r1, sp
	bl seqMetaEvent
	cmp r0, #0
	beq .L_080F3F08
	ldr r0, [r5, #4]
	adds r1, r4, #0
	movs r2, #0
	bl chanSetLfoSpeed
	movs r0, #1
	b .L_080F3F0E
.L_080F3E70:
	movs r0, #0xf0
	ands r0, r2
	cmp r0, #0xb0
	beq .L_080F3EC0
	cmp r0, #0xb0
	bgt .L_080F3E90
	cmp r0, #0x90
	beq .L_080F3EB2
	cmp r0, #0x90
	bgt .L_080F3E8A
	cmp r0, #0x80
	beq .L_080F3EA4
	b .L_080F3F08
.L_080F3E8A:
	cmp r0, #0xa0
	beq .L_080F3F02
	b .L_080F3F08
.L_080F3E90:
	cmp r0, #0xd0
	beq .L_080F3EE2
	cmp r0, #0xd0
	bgt .L_080F3E9E
	cmp r0, #0xc0
	beq .L_080F3ED0
	b .L_080F3F08
.L_080F3E9E:
	cmp r0, #0xe0
	beq .L_080F3EE8
	b .L_080F3F08
.L_080F3EA4:
	ldr r0, [sp]
	ldrb r1, [r0]
	adds r0, r4, #0
	movs r2, #0
	bl seqQueueNote
	b .L_080F3F02
.L_080F3EB2:
	ldr r0, [sp]
	ldrb r1, [r0]
	ldrb r2, [r0, #1]
	adds r0, r4, #0
	bl seqQueueNote
	b .L_080F3F02
.L_080F3EC0:
	ldr r0, [sp]
	ldrb r2, [r0]
	ldrb r3, [r0, #1]
	adds r0, r5, #0
	adds r1, r4, #0
	bl seqControlChange
	b .L_080F3F02
.L_080F3ED0:
	ldr r0, [r5, #4]
	ldr r1, [sp]
	ldrb r2, [r1]
	adds r1, r4, #0
	bl chanSetProgram
	ldr r0, [sp]
	adds r0, #1
	b .L_080F3F06
.L_080F3EE2:
	ldr r0, [sp]
	adds r0, #1
	b .L_080F3F06
.L_080F3EE8:
	ldr r3, [sp]
	ldrb r1, [r3]
	movs r0, #0x7f
	adds r2, r0, #0
	ands r2, r1
	ldrb r1, [r3, #1]
	ands r0, r1
	lsls r0, r0, #7
	orrs r2, r0
	ldr r0, [r5, #4]
	adds r1, r4, #0
	bl chanSetPitchBend
.L_080F3F02:
	ldr r0, [sp]
	adds r0, #2
.L_080F3F06:
	str r0, [sp]
.L_080F3F08:
	ldr r0, [sp]
	str r0, [r6, #8]
	movs r0, #0
.L_080F3F0E:
	add sp, #4
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ seqTrackTick  (080F3F18, Thumb)
@   void seqTrackTick(Player *p, int t)
@   {
@       Track *tr = &p->tracks[t];  if (!tr->active) return;
@       noteOn = 0;  gNoteQueueLen = 0;
@       while (tr->time < p->tickRate) {                    // all events due in this frame
@           if (seqTrackEvent(p, t)) { tr->active = 0; chanReleaseAll(p->synth, t); return; }
@           dt = readVarLen(&tr->ptr);
@           if (dt) {                                       // notes are applied after all events of their tick
@               for each queued q: q.vel ? (chanNoteOn(p->synth, q.ch, q.key, q.vel), noteOn = 1)
@                                        : chanNoteOff(p->synth, q.ch, q.key);
@               gNoteQueueLen = 0;
@           }
@           tr->time += dt << 8;
@       }
@       tr->time -= p->tickRate;
@       if (noteOn && p->synth->chans[t].wet && gSweepMode == 1) { mixClearEffects(); sweepStart(&gSweep); }
@   }
@ --------------------------------------------------------------------------------------------------
	.global seqTrackTick
seqTrackTick:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #4
	adds r4, r0, #0
	mov r8, r1
	lsls r0, r1, #3
	add r0, r8
	lsls r0, r0, #2
	ldr r1, [r4, #8]
	adds r5, r1, r0
	ldrb r0, [r5]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F4014
	movs r0, #0
	str r0, [sp]
	ldr r0, .L_080F3F4C                        @ = gNoteQueueLen
	mov r1, sp
	ldrh r1, [r1]
	strh r1, [r0]
	ldr r1, [r5, #0xc]
	b .L_080F3FDC
	.hword 0x0000
.L_080F3F4C:
	.word gNoteQueueLen
.L_080F3F50:
	adds r0, r4, #0
	mov r1, r8
	bl seqTrackEvent
	cmp r0, #0
	beq .L_080F3F72
	ldrb r0, [r5]
	movs r2, #2
	rsbs r2, r2, #0
	adds r1, r2, #0
	ands r0, r1
	strb r0, [r5]
	ldr r0, [r4, #4]
	mov r1, r8
	bl chanReleaseAll
	b .L_080F4014
.L_080F3F72:
	adds r0, r5, #0
	adds r0, #8
	bl readVarLen
	mov sb, r0
	cmp r0, #0
	beq .L_080F3FD2
	ldr r7, .L_080F3F8C                        @ = gNoteQueue
	movs r6, #0
	ldr r0, .L_080F3F90                        @ = gNoteQueueLen
	mov sl, r0
	b .L_080F3FC6
	.hword 0x0000
.L_080F3F8C:
	.word gNoteQueue
.L_080F3F90:
	.word gNoteQueueLen
.L_080F3F94:
	ldr r2, [r7]
	lsls r0, r2, #0xe
	lsrs r3, r0, #0x19
	cmp r3, #0
	beq .L_080F3FB2
	ldr r0, [r4, #4]
	lsls r1, r2, #0x1c
	lsrs r1, r1, #0x1c
	lsls r2, r2, #0x15
	lsrs r2, r2, #0x19
	bl chanNoteOn
	movs r1, #1
	str r1, [sp]
	b .L_080F3FC0
.L_080F3FB2:
	ldr r0, [r4, #4]
	lsls r1, r2, #0x1c
	lsrs r1, r1, #0x1c
	lsls r2, r2, #0x15
	lsrs r2, r2, #0x19
	bl chanNoteOff
.L_080F3FC0:
	adds r6, #1
	adds r7, #4
	ldr r0, .L_080F4024                        @ = gNoteQueueLen
.L_080F3FC6:
	ldrh r0, [r0]
	cmp r6, r0
	blo .L_080F3F94
	movs r0, #0
	mov r2, sl
	strh r0, [r2]
.L_080F3FD2:
	mov r1, sb
	lsls r0, r1, #8
	ldr r1, [r5, #0xc]
	adds r1, r1, r0
	str r1, [r5, #0xc]
.L_080F3FDC:
	ldr r0, [r4, #0x10]
	cmp r1, r0
	blo .L_080F3F50
	ldr r0, [r5, #0xc]
	ldr r1, [r4, #0x10]
	subs r0, r0, r1
	str r0, [r5, #0xc]
	ldr r2, [sp]
	cmp r2, #0
	beq .L_080F4014
	ldr r0, [r4, #4]
	mov r2, r8
	lsls r1, r2, #5
	ldr r0, [r0, #0x18]
	adds r0, r0, r1
	ldrb r0, [r0, #3]
	lsls r0, r0, #0x19
	cmp r0, #0
	bge .L_080F4014
	ldr r0, .L_080F4028                        @ = gSweepMode
	ldrb r0, [r0]
	cmp r0, #1
	bne .L_080F4014
	bl mixClearEffects
	ldr r0, .L_080F402C                        @ = gSweep
	bl sweepStart
.L_080F4014:
	add sp, #4
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
.L_080F4024:
	.word gNoteQueueLen
.L_080F4028:
	.word gSweepMode
.L_080F402C:
	.word gSweep

@ --------------------------------------------------------------------------------------------------
@ playerFadeTick  (080F4030, Thumb)
@   void playerFadeTick(Player *p)
@   {
@       switch (p->fadeMode) {
@       case 1: p->fade += p->fadeStep; if (p->fade >= 0x8000) { p->fadeMode = 0; p->fade = 0x8000; p->fadeStep = 0; } break;
@       case 2: if (p->fade < p->fadeStep) { p->fadeMode = 0; p->fade = 0; playerStop(p); } else p->fade -= p->fadeStep; break;
@       case 3: if (p->fade < p->fadeStep) { p->fade = 0; playerSetPause(p, 1); }     else p->fade -= p->fadeStep; break;
@       }
@       synthSetVolume(p->synth, (p->song->volume * p->volume >> 8) * (p->fade >> 8) >> 7);
@   }
@   Mode 3 stays active at level 0, so the player is paused again every frame until a new playerFade.
@ --------------------------------------------------------------------------------------------------
	.global playerFadeTick
playerFadeTick:
	push {r4, lr}
	adds r4, r0, #0
	ldrb r2, [r4, #3]
	lsls r0, r2, #0x1a
	lsrs r0, r0, #0x1d
	cmp r0, #1
	beq .L_080F404C
	cmp r0, #1
	ble .L_080F40A4
	cmp r0, #2
	beq .L_080F406E
	cmp r0, #3
	beq .L_080F408A
	b .L_080F40A4
.L_080F404C:
	ldrh r0, [r4, #0x2a]
	ldrh r1, [r4, #0x28]
	adds r0, r0, r1
	strh r0, [r4, #0x28]
	lsls r0, r0, #0x10
	cmp r0, #0
	bge .L_080F40A4
	movs r0, #0x39
	rsbs r0, r0, #0
	ands r0, r2
	strb r0, [r4, #3]
	movs r0, #0x80
	lsls r0, r0, #8
	strh r0, [r4, #0x28]
	movs r0, #0
	strh r0, [r4, #0x2a]
	b .L_080F40A4
.L_080F406E:
	ldrh r1, [r4, #0x28]
	ldrh r0, [r4, #0x2a]
	cmp r1, r0
	bhs .L_080F40A0
	movs r0, #0x39
	rsbs r0, r0, #0
	ands r0, r2
	strb r0, [r4, #3]
	movs r0, #0
	strh r0, [r4, #0x28]
	adds r0, r4, #0
	bl playerStop
	b .L_080F40A4
.L_080F408A:
	ldrh r1, [r4, #0x28]
	ldrh r0, [r4, #0x2a]
	cmp r1, r0
	bhs .L_080F40A0
	movs r0, #0
	strh r0, [r4, #0x28]
	adds r0, r4, #0
	movs r1, #1
	bl playerSetPause
	b .L_080F40A4
.L_080F40A0:
	subs r0, r1, r0
	strh r0, [r4, #0x28]
.L_080F40A4:
	ldr r0, [r4, #0xc]
	ldr r0, [r0, #4]
	lsls r0, r0, #0xa
	lsrs r0, r0, #0x19
	ldrh r1, [r4, #0x26]
	muls r1, r0, r1
	asrs r1, r1, #8
	ldrh r0, [r4, #0x28]
	lsrs r0, r0, #8
	muls r1, r0, r1
	asrs r1, r1, #7
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	ldr r0, [r4, #4]
	bl synthSetVolume
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ playerTick  (080F40CC, Thumb)
@   void playerTick(Player *p)
@   {
@       if (!p->song || p->paused) return;
@       gSeqNewTickRate = 0; gSeqLoopEndHit = 0; gSeqLoopStartHit = 0;
@       for (t = 0; t < p->nTracks; t++) seqTrackTick(p, t);
@       if (gSeqLoopEndHit) {                                   // "]": back to the loop start, same frame
@           for each track: active = loopActive; status = loopStatus; ptr = loopPtr; time = loopTime;
@                           chanReleaseAll(p->synth, t);
@           for each track: seqTrackTick(p, t);
@       }
@       if (!p->looped) {
@           if (gSeqLoopStartHit) {                             // "[": keep the state from the start of this frame
@               for each track: loopActive = active; loopStatus = snapStatus; loopPtr = snapPtr; loopTime = snapTime;
@               p->savedTickRate = p->tickRate; p->looped = 1;
@           } else
@               for each track: snapStatus = status; snapPtr = ptr; snapTime = time;
@       }
@       if (gSeqNewTickRate) p->tickRate = gSeqNewTickRate;
@       if (no track active) p->song = 0;
@   }
@   savedTickRate is never read: a tempo change inside the loop is not undone by the jump.
@ --------------------------------------------------------------------------------------------------
	.global playerTick
playerTick:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r5, r0, #0
	ldr r0, [r5, #0xc]
	cmp r0, #0
	bne .L_080F40DC
	b .L_080F4288
.L_080F40DC:
	ldrb r0, [r5, #1]
	lsls r0, r0, #0x1c
	lsrs r1, r0, #0x1f
	cmp r1, #0
	beq .L_080F40E8
	b .L_080F4288
.L_080F40E8:
	ldr r7, [r5, #8]
	ldr r0, .L_080F40FC                        @ = gSeqNewTickRate
	str r1, [r0]
	ldr r0, .L_080F4100                        @ = gSeqLoopEndHit
	strb r1, [r0]
	ldr r0, .L_080F4104                        @ = gSeqLoopStartHit
	strb r1, [r0]
	movs r6, #0
	b .L_080F4112
	.hword 0x0000
.L_080F40FC:
	.word gSeqNewTickRate
.L_080F4100:
	.word gSeqLoopEndHit
.L_080F4104:
	.word gSeqLoopStartHit
.L_080F4108:
	adds r0, r5, #0
	adds r1, r6, #0
	bl seqTrackTick
	adds r6, #1
.L_080F4112:
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	blo .L_080F4108
	ldr r0, .L_080F417C                        @ = gSeqLoopEndHit
	ldrb r0, [r0]
	cmp r0, #0
	beq .L_080F4198
	movs r6, #0
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	bhs .L_080F4176
	adds r4, r7, #0
.L_080F4132:
	ldrb r1, [r4]
	lsls r2, r1, #0x1e
	lsrs r2, r2, #0x1f
	movs r3, #2
	rsbs r3, r3, #0
	adds r0, r3, #0
	ands r1, r0
	orrs r1, r2
	strb r1, [r4]
	ldr r0, [r4]
	lsls r0, r0, #0xe
	lsrs r0, r0, #0x18
	lsls r0, r0, #2
	ldrh r1, [r4]
	ldr r3, .L_080F4180                        @ = 0xFFFFFC03
	adds r2, r3, #0
	ands r1, r2
	orrs r1, r0
	strh r1, [r4]
	ldr r0, [r4, #0x10]
	str r0, [r4, #8]
	ldr r0, [r4, #0x14]
	str r0, [r4, #0xc]
	ldr r0, [r5, #4]
	adds r1, r6, #0
	bl chanReleaseAll
	adds r4, #0x24
	adds r6, #1
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	blo .L_080F4132
.L_080F4176:
	movs r6, #0
	b .L_080F418E
	.hword 0x0000
.L_080F417C:
	.word gSeqLoopEndHit
.L_080F4180:
	.word 0xFFFFFC03
.L_080F4184:
	adds r0, r5, #0
	adds r1, r6, #0
	bl seqTrackTick
	adds r6, #1
.L_080F418E:
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	blo .L_080F4184
.L_080F4198:
	ldrb r0, [r5, #1]
	lsls r0, r0, #0x1d
	ldr r1, .L_080F4204                        @ = gSeqNewTickRate
	mov r8, r1
	cmp r0, #0
	blt .L_080F424E
	ldr r0, .L_080F4208                        @ = gSeqLoopStartHit
	ldrb r0, [r0]
	cmp r0, #0
	beq .L_080F4210
	movs r6, #0
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	bhs .L_080F424E
	movs r4, #3
	rsbs r4, r4, #0
	adds r3, r7, #0
.L_080F41BE:
	ldrb r2, [r3]
	lsls r1, r2, #0x1f
	lsrs r1, r1, #0x1f
	lsls r1, r1, #1
	adds r0, r4, #0
	ands r0, r2
	orrs r0, r1
	strb r0, [r3]
	ldrh r0, [r3, #2]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x18
	lsls r0, r0, #0xa
	ldr r1, [r3]
	ldr r2, .L_080F420C                        @ = 0xFFFC03FF
	ands r1, r2
	orrs r1, r0
	str r1, [r3]
	ldr r0, [r3, #0x18]
	str r0, [r3, #0x10]
	ldr r0, [r3, #0x1c]
	str r0, [r3, #0x14]
	ldr r0, [r5, #0x10]
	str r0, [r5, #0x14]
	ldrb r0, [r5, #1]
	movs r1, #4
	orrs r0, r1
	strb r0, [r5, #1]
	adds r3, #0x24
	adds r6, #1
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	blo .L_080F41BE
	b .L_080F424E
.L_080F4204:
	.word gSeqNewTickRate
.L_080F4208:
	.word gSeqLoopStartHit
.L_080F420C:
	.word 0xFFFC03FF
.L_080F4210:
	movs r6, #0
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	bhs .L_080F424E
	movs r4, #0xff
	ldr r3, .L_080F4294                        @ = 0xFFFFFC03
	mov ip, r3
	adds r3, r7, #0
.L_080F4224:
	ldrh r1, [r3]
	lsls r1, r1, #0x16
	lsrs r1, r1, #0x18
	ands r1, r4
	lsls r1, r1, #2
	ldrh r2, [r3, #2]
	mov r0, ip
	ands r0, r2
	orrs r0, r1
	strh r0, [r3, #2]
	ldr r0, [r3, #8]
	str r0, [r3, #0x18]
	ldr r0, [r3, #0xc]
	str r0, [r3, #0x1c]
	adds r3, #0x24
	adds r6, #1
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	blo .L_080F4224
.L_080F424E:
	mov r1, r8
	ldr r0, [r1]
	cmp r0, #0
	beq .L_080F4258
	str r0, [r5, #0x10]
.L_080F4258:
	ldr r7, [r5, #8]
	movs r1, #1
	movs r6, #0
	ldrh r0, [r5]
	lsls r0, r0, #0x16
	lsrs r0, r0, #0x1b
	cmp r6, r0
	bhs .L_080F4280
	adds r2, r0, #0
.L_080F426A:
	ldrb r0, [r7]
	lsls r0, r0, #0x1f
	cmp r0, #0
	beq .L_080F4274
	movs r1, #0
.L_080F4274:
	adds r6, #1
	adds r7, #0x24
	cmp r6, r2
	bhs .L_080F4280
	cmp r1, #0
	bne .L_080F426A
.L_080F4280:
	cmp r1, #0
	beq .L_080F4288
	movs r0, #0
	str r0, [r5, #0xc]
.L_080F4288:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F4294:
	.word 0xFFFFFC03

@ --------------------------------------------------------------------------------------------------
@ sndMain  (080F4298, Thumb)
@   void sndMain(void)                          // called once per frame from the game's main loop
@   {
@       gSndVcountStart = REG_VCOUNT;
@       rv = gReverbBase;                                           // {level, delay, lpShift, hpShift}
@       for (k = 0; k <= sndLastPlayer; k++) {
@           Player *p = sndPlayers[k]; if (!p) continue;
@           playerFadeTick(p); playerTick(p); synthLfoTick(p->synth);
@           if (p->song) { rv[0] += 2*p->reverb[0] - 128; rv[1..3] += p->reverb[1..3] - 64; }
@       }
@       if (sndConfig.liveEnabled && gLivePlayer) { liveTick(); same reverb sum for gLivePlayer; }
@       if (gSweepPlayer && gSweepMode) {
@           sweepTick(&gSweep, calcTickRate(gSweepPlayer->tempo, gSweepPlayer->tempoScale, 24));
@           mixSetFilter(gSweep.out * gSweepDepth >> 8);
@       }
@       noteUpdateAll();
@       gSndVcountEnd = REG_VCOUNT;
@       mixSetReverb(clamp(rv[0], 0, 127), clamp(rv[1]...), clamp(rv[2]...), clamp(rv[3]...));
@       mixFrame();
@   }
@ --------------------------------------------------------------------------------------------------
	.global sndMain
sndMain:
	push {r4, r5, r6, r7, lr}
	mov r7, sb
	mov r6, r8
	push {r6, r7}
	ldr r0, .L_080F42C4                        @ = gReverbBase
	movs r6, #0
	ldrsb r6, [r0, r6]
	movs r7, #1
	ldrsb r7, [r0, r7]
	movs r1, #2
	ldrsb r1, [r0, r1]
	mov r8, r1
	ldrb r0, [r0, #3]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	mov sb, r0
	ldr r1, .L_080F42C8                        @ = gSndVcountStart
	ldr r0, .L_080F42CC                        @ = REG_VCOUNT
	ldrh r0, [r0]
	strh r0, [r1]
	movs r5, #0
	b .L_080F433C
.L_080F42C4:
	.word gReverbBase
.L_080F42C8:
	.word gSndVcountStart
.L_080F42CC:
	.word REG_VCOUNT
.L_080F42D0:
	ldr r1, .L_080F4440                        @ = sndPlayers
	lsls r0, r5, #2
	adds r0, r0, r1
	ldr r4, [r0]
	cmp r4, #0
	beq .L_080F433A
	adds r0, r4, #0
	bl playerFadeTick
	adds r0, r4, #0
	bl playerTick
	ldr r0, [r4, #4]
	bl synthLfoTick
	ldr r0, [r4, #0xc]
	cmp r0, #0
	beq .L_080F433A
	adds r1, r6, #0
	subs r1, #0x80
	adds r0, r4, #0
	adds r0, #0x2c
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	lsls r0, r0, #1
	adds r6, r1, r0
	adds r1, r7, #0
	subs r1, #0x40
	adds r0, r4, #0
	adds r0, #0x2d
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r7, r1, r0
	mov r1, r8
	subs r1, #0x40
	adds r0, r4, #0
	adds r0, #0x2e
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r1, r1, r0
	mov r8, r1
	mov r1, sb
	subs r1, #0x40
	adds r0, r4, #0
	adds r0, #0x2f
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r1, r1, r0
	mov sb, r1
.L_080F433A:
	adds r5, #1
.L_080F433C:
	ldr r0, .L_080F4444                        @ = sndLastPlayer
	ldr r0, [r0]
	cmp r5, r0
	bls .L_080F42D0
	ldr r0, .L_080F4448                        @ = gLivePlayer
	ldr r4, [r0]
	ldr r0, .L_080F444C                        @ = sndConfig
	ldrb r0, [r0]
	cmp r0, #0
	beq .L_080F439E
	cmp r4, #0
	beq .L_080F439E
	bl liveTick
	adds r1, r6, #0
	subs r1, #0x80
	adds r0, r4, #0
	adds r0, #0x2c
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	lsls r0, r0, #1
	adds r6, r1, r0
	adds r1, r7, #0
	subs r1, #0x40
	adds r0, r4, #0
	adds r0, #0x2d
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r7, r1, r0
	mov r1, r8
	subs r1, #0x40
	adds r0, r4, #0
	adds r0, #0x2e
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r1, r1, r0
	mov r8, r1
	mov r1, sb
	subs r1, #0x40
	adds r0, r4, #0
	adds r0, #0x2f
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	adds r1, r1, r0
	mov sb, r1
.L_080F439E:
	ldr r0, .L_080F4450                        @ = gSweepPlayer
	ldr r1, [r0]
	cmp r1, #0
	beq .L_080F43D6
	ldr r0, .L_080F4454                        @ = gSweepMode
	ldrb r0, [r0]
	cmp r0, #0
	beq .L_080F43D6
	ldr r0, [r1]
	lsls r0, r0, #0xb
	lsrs r0, r0, #0x17
	ldrh r1, [r1, #0x24]
	movs r2, #0x18
	bl calcTickRate
	adds r1, r0, #0
	ldr r4, .L_080F4458                        @ = gSweep
	adds r0, r4, #0
	bl sweepTick
	movs r1, #7
	ldrsb r1, [r4, r1]
	ldr r0, .L_080F445C                        @ = gSweepDepth
	ldrb r0, [r0]
	muls r0, r1, r0
	asrs r0, r0, #8
	bl mixSetFilter
.L_080F43D6:
	bl noteUpdateAll
	ldr r0, .L_080F4460                        @ = gSndVcountEnd
	ldr r1, .L_080F4464                        @ = REG_VCOUNT
	ldrh r1, [r1]
	strh r1, [r0]
	cmp r6, #0
	bge .L_080F43E8
	movs r6, #0
.L_080F43E8:
	cmp r6, #0x7f
	ble .L_080F43EE
	movs r6, #0x7f
.L_080F43EE:
	cmp r7, #0
	bge .L_080F43F4
	movs r7, #0
.L_080F43F4:
	cmp r7, #0x7f
	ble .L_080F43FA
	movs r7, #0x7f
.L_080F43FA:
	mov r0, r8
	cmp r0, #0
	bge .L_080F4404
	movs r1, #0
	mov r8, r1
.L_080F4404:
	mov r0, r8
	cmp r0, #0x7f
	ble .L_080F440E
	movs r1, #0x7f
	mov r8, r1
.L_080F440E:
	mov r0, sb
	cmp r0, #0
	bge .L_080F4418
	movs r1, #0
	mov sb, r1
.L_080F4418:
	mov r0, sb
	cmp r0, #0x7f
	ble .L_080F4422
	movs r1, #0x7f
	mov sb, r1
.L_080F4422:
	adds r0, r6, #0
	adds r1, r7, #0
	mov r2, r8
	mov r3, sb
	bl mixSetReverb
	bl mixFrame
	pop {r3, r4}
	mov r8, r3
	mov sb, r4
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F4440:
	.word sndPlayers
.L_080F4444:
	.word sndLastPlayer
.L_080F4448:
	.word gLivePlayer
.L_080F444C:
	.word sndConfig
.L_080F4450:
	.word gSweepPlayer
.L_080F4454:
	.word gSweepMode
.L_080F4458:
	.word gSweep
.L_080F445C:
	.word gSweepDepth
.L_080F4460:
	.word gSndVcountEnd
.L_080F4464:
	.word REG_VCOUNT

@ --------------------------------------------------------------------------------------------------
@ sndSetReverbBase  (080F4468, Thumb)
@   void sndSetReverbBase(int level, int delay, int lpShift, int hpShift)   // game: (0x23, 2, 2, 4)
@ --------------------------------------------------------------------------------------------------
	.global sndSetReverbBase
sndSetReverbBase:
	push {r4, lr}
	ldr r4, .L_080F447C                        @ = gReverbBase
	strb r0, [r4]
	strb r1, [r4, #1]
	strb r2, [r4, #2]
	strb r3, [r4, #3]
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F447C:
	.word gReverbBase

@ --------------------------------------------------------------------------------------------------
@ sndNop  (080F4480, Thumb)
@   void sndNop(void)  { }    // called every frame by the game
@ --------------------------------------------------------------------------------------------------
	.global sndNop
sndNop:
	bx lr
	.hword 0x0000

@ --------------------------------------------------------------------------------------------------
@ playerInit  (080F4484, Thumb)
@   void playerInit(Player *p, Synth *s, int maxTracks, Track *tracks, int prioCheck)
@   {   p->song = 0; p->synth = s; p->maxTracks = maxTracks; p->tracks = tracks; p->prioCheck = prioCheck; }
@ --------------------------------------------------------------------------------------------------
	.global playerInit
playerInit:
	push {r4, r5, lr}
	ldr r5, [sp, #0xc]
	movs r4, #0
	str r4, [r0, #0xc]
	str r1, [r0, #4]
	movs r1, #0x1f
	ands r2, r1
	ldrb r4, [r0]
	movs r1, #0x20
	rsbs r1, r1, #0
	ands r1, r4
	orrs r1, r2
	strb r1, [r0]
	str r3, [r0, #8]
	movs r1, #1
	ands r5, r1
	lsls r5, r5, #5
	ldrb r2, [r0, #2]
	movs r1, #0x21
	rsbs r1, r1, #0
	ands r1, r2
	orrs r1, r5
	strb r1, [r0, #2]
	pop {r4, r5}
	pop {r0}
	bx r0

@ --------------------------------------------------------------------------------------------------
@ readVarLen  (080F44B8, Thumb)
@   u32 readVarLen(const u8 **pp)   // MIDI variable-length quantity
@ --------------------------------------------------------------------------------------------------
	.global readVarLen
readVarLen:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	ldr r2, [r4]
	movs r3, #0
	movs r6, #0x7f
	movs r5, #0x80
.L_080F44C4:
	ldrb r1, [r2]
	adds r2, #1
	lsls r3, r3, #7
	adds r0, r1, #0
	ands r0, r6
	orrs r3, r0
	ands r1, r5
	cmp r1, #0
	bne .L_080F44C4
	str r2, [r4]
	adds r0, r3, #0
	pop {r4, r5, r6}
	pop {r1}
	bx r1

@ --------------------------------------------------------------------------------------------------
@ liveInit  (080F44E0, Thumb)
@   void liveInit(Player *p, Synth *s, int nChans, Chan *chans, void *buf, ...)   (not called)
@   Sets up the live-MIDI player of sndConfig: bank sndConfig.bank, volume, priority, tempo; gLivePlayer = p.
@ --------------------------------------------------------------------------------------------------
	.global liveInit
liveInit:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	sub sp, #4
	adds r7, r0, #0
	mov r8, r1
	adds r5, r2, #0
	adds r6, r3, #0
	ldr r0, .L_080F45AC                        @ = sndConfig
	ldrb r0, [r0]
	cmp r0, #0
	beq .L_080F459E
	adds r0, r6, #0
	adds r1, r5, #0
	ldr r2, [sp, #0x1c]
	bl synthInit
	ldr r1, .L_080F45B0                        @ = sndBankTable
	ldr r0, .L_080F45B4                        @ = 0x08417A89
	ldrb r0, [r0]
	lsls r0, r0, #2
	adds r0, r0, r1
	ldr r1, [r0]
	adds r0, r6, #0
	bl synthSetBank
	ldr r0, .L_080F45B8                        @ = 0x08417A8A
	ldrb r1, [r0]
	adds r0, r6, #0
	bl synthSetVolume
	ldr r4, .L_080F45BC                        @ = 0x08417A8B
	ldrb r1, [r4]
	adds r0, r6, #0
	bl synthSetPriority
	ldrb r0, [r4]
	str r0, [sp]
	adds r0, r7, #0
	adds r1, r6, #0
	adds r2, r5, #0
	mov r3, r8
	bl playerInit
	movs r0, #0
	mov r8, r0
	movs r5, #0
	movs r1, #0x80
	lsls r1, r1, #1
	strh r1, [r7, #0x24]
	strh r1, [r7, #0x26]
	ldrb r2, [r7, #3]
	movs r0, #0x39
	rsbs r0, r0, #0
	ands r0, r2
	strb r0, [r7, #3]
	movs r0, #0x80
	lsls r0, r0, #8
	strh r0, [r7, #0x28]
	strh r5, [r7, #0x2a]
	ldr r4, .L_080F45C0                        @ = 0x08417A8C
	ldrb r3, [r4]
	lsls r3, r3, #0xc
	ldr r0, [r7]
	ldr r2, .L_080F45C4                        @ = 0xFFE00FFF
	ands r0, r2
	orrs r0, r3
	str r0, [r7]
	ldrb r0, [r4]
	movs r2, #0x18
	bl calcTickRate
	str r0, [r7, #0x10]
	adds r1, r7, #0
	adds r1, #0x2c
	movs r0, #0x40
	strb r0, [r1]
	adds r1, #1
	strb r0, [r1]
	adds r1, #1
	strb r0, [r1]
	adds r1, #1
	strb r0, [r1]
	ldr r0, .L_080F45C8                        @ = gLivePlayer
	str r7, [r0]
	ldr r0, .L_080F45CC                        @ = gLiveSynth
	str r6, [r0]
	ldr r1, .L_080F45D0                        @ = gLiveBuf
	ldr r0, [sp, #0x20]
	str r0, [r1]
	ldr r0, .L_080F45D4                        @ = gLiveBufLen
	strh r5, [r0]
	ldr r0, .L_080F45D8                        @ = gLiveRunStatus
	mov r1, r8
	strb r1, [r0]
.L_080F459E:
	add sp, #4
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F45AC:
	.word sndConfig
.L_080F45B0:
	.word sndBankTable
.L_080F45B4:
	.word 0x08417A89
.L_080F45B8:
	.word 0x08417A8A
.L_080F45BC:
	.word 0x08417A8B
.L_080F45C0:
	.word 0x08417A8C
.L_080F45C4:
	.word 0xFFE00FFF
.L_080F45C8:
	.word gLivePlayer
.L_080F45CC:
	.word gLiveSynth
.L_080F45D0:
	.word gLiveBuf
.L_080F45D4:
	.word gLiveBufLen
.L_080F45D8:
	.word gLiveRunStatus

@ --------------------------------------------------------------------------------------------------
@ liveMidiInput  (080F45DC, Thumb)
@   void liveMidiInput(const u8 *d, int n)  (not called)  // append raw MIDI bytes to gLiveBuf (512 max)
@ --------------------------------------------------------------------------------------------------
	.global liveMidiInput
liveMidiInput:
	push {r4, r5, r6, lr}
	adds r3, r0, #0
	adds r2, r1, #0
	cmp r2, #0
	beq .L_080F4614
	ldr r4, .L_080F461C                        @ = gLiveBufLen
	ldrh r0, [r4]
	ldr r1, .L_080F4620                        @ = 0x000001FF
	cmp r0, r1
	bhi .L_080F4614
	ldr r6, .L_080F4624                        @ = gLiveBuf
	adds r5, r1, #0
.L_080F45F4:
	ldrh r1, [r4]
	adds r0, r1, #1
	strh r0, [r4]
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	ldr r0, [r6]
	adds r0, r0, r1
	ldrb r1, [r3]
	strb r1, [r0]
	adds r3, #1
	subs r2, #1
	cmp r2, #0
	beq .L_080F4614
	ldrh r0, [r4]
	cmp r0, r5
	bls .L_080F45F4
.L_080F4614:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
.L_080F461C:
	.word gLiveBufLen
.L_080F4620:
	.word 0x000001FF
.L_080F4624:
	.word gLiveBuf

@ --------------------------------------------------------------------------------------------------
@ liveParse  (080F4628, Thumb)
@   void liveParse(void)                        // parse gLiveBuf as a MIDI byte stream (real channels);
@   note on/off are queued, CC -> seqControlChange, program, bend, SysEx; an incomplete message stays in the buffer
@ --------------------------------------------------------------------------------------------------
	.global liveParse
liveParse:
	push {r4, r5, r6, r7, lr}
	mov r7, sl
	mov r6, sb
	mov r5, r8
	push {r5, r6, r7}
	ldr r1, .L_080F4678                        @ = gLivePlayer
	ldr r1, [r1]
	mov sl, r1
	ldr r1, .L_080F467C                        @ = gLiveBuf
	ldr r7, [r1]
	ldr r1, .L_080F4680                        @ = gLiveBufLen
	ldrh r5, [r1]
	movs r1, #0
	mov sb, r1
	cmp r5, #0
	bne .L_080F464A
	b .L_080F47B6
.L_080F464A:
	ldrb r3, [r7]
	movs r1, #0
	ldrsb r1, [r7, r1]
	cmp r1, #0
	bge .L_080F468E
	movs r2, #0xf0
	ands r2, r3
	movs r1, #0xf
	mov r8, r1
	ands r1, r3
	mov r8, r1
	adds r1, r7, #1
	mov ip, r1
	movs r4, #1
	ldr r6, .L_080F4684                        @ = gLiveRunStatus
	adds r1, r2, #0
	adds r1, #0x80
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	cmp r1, #0x6f
	bhi .L_080F4688
	strb r3, [r6]
	b .L_080F46A2
.L_080F4678:
	.word gLivePlayer
.L_080F467C:
	.word gLiveBuf
.L_080F4680:
	.word gLiveBufLen
.L_080F4684:
	.word gLiveRunStatus
.L_080F4688:
	movs r1, #0
	strb r1, [r6]
	b .L_080F46A2
.L_080F468E:
	ldr r1, .L_080F46C4                        @ = gLiveRunStatus
	ldrb r1, [r1]
	movs r2, #0xf0
	ands r2, r1
	movs r3, #0xf
	mov r8, r3
	ands r3, r1
	mov r8, r3
	mov ip, r7
	movs r4, #0
.L_080F46A2:
	adds r6, r4, #1
	adds r4, #2
	mov r1, ip
	ldrb r3, [r1]
	ldrb r1, [r1, #1]
	mov ip, r1
	cmp r2, #0xb0
	beq .L_080F470C
	cmp r2, #0xb0
	bgt .L_080F46CE
	cmp r2, #0x90
	beq .L_080F46F6
	cmp r2, #0x90
	bgt .L_080F46C8
	cmp r2, #0x80
	beq .L_080F46E6
	b .L_080F47A6
.L_080F46C4:
	.word gLiveRunStatus
.L_080F46C8:
	cmp r2, #0xa0
	beq .L_080F4706
	b .L_080F47A6
.L_080F46CE:
	cmp r2, #0xd0
	beq .L_080F4730
	cmp r2, #0xd0
	bgt .L_080F46DC
	cmp r2, #0xc0
	beq .L_080F471E
	b .L_080F47A6
.L_080F46DC:
	cmp r2, #0xe0
	beq .L_080F4740
	cmp r2, #0xf0
	beq .L_080F475E
	b .L_080F47A6
.L_080F46E6:
	cmp r5, r4
	blo .L_080F4734
	mov r0, r8
	adds r1, r3, #0
	movs r2, #0
	bl seqQueueNote
	b .L_080F479A
.L_080F46F6:
	cmp r5, r4
	blo .L_080F476C
	mov r0, r8
	adds r1, r3, #0
	mov r2, ip
	bl seqQueueNote
	b .L_080F479A
.L_080F4706:
	cmp r5, r4
	blo .L_080F4734
	b .L_080F479A
.L_080F470C:
	cmp r5, r4
	blo .L_080F476C
	mov r0, sl
	mov r1, r8
	adds r2, r3, #0
	mov r3, ip
	bl seqControlChange
	b .L_080F479A
.L_080F471E:
	cmp r5, r6
	blo .L_080F4734
	mov r1, sl
	ldr r0, [r1, #4]
	mov r1, r8
	adds r2, r3, #0
	bl chanSetProgram
	b .L_080F473A
.L_080F4730:
	cmp r5, r6
	bhs .L_080F473A
.L_080F4734:
	movs r3, #1
	mov sb, r3
	b .L_080F47AA
.L_080F473A:
	adds r7, r7, r6
	subs r5, r5, r6
	b .L_080F47AA
.L_080F4740:
	cmp r5, r4
	blo .L_080F476C
	movs r0, #0x7f
	ands r3, r0
	mov r1, ip
	ands r1, r0
	lsls r0, r1, #7
	orrs r3, r0
	mov r1, sl
	ldr r0, [r1, #4]
	mov r1, r8
	adds r2, r3, #0
	bl chanSetPitchBend
	b .L_080F479A
.L_080F475E:
	mov r3, r8
	cmp r3, #0
	beq .L_080F4772
	cmp r3, #3
	bhi .L_080F47A6
	cmp r5, #1
	bhi .L_080F47A0
.L_080F476C:
	movs r1, #1
	mov sb, r1
	b .L_080F47AA
.L_080F4772:
	movs r4, #1
	adds r1, r7, #1
	cmp r4, r5
	bhs .L_080F4794
	movs r0, #1
	ldrsb r0, [r7, r0]
	cmp r0, #0
	blt .L_080F4794
.L_080F4782:
	adds r4, #1
	cmp r4, r5
	bhs .L_080F4794
	adds r0, r7, r4
	ldrb r0, [r0]
	lsls r0, r0, #0x18
	asrs r0, r0, #0x18
	cmp r0, #0
	bge .L_080F4782
.L_080F4794:
	mov r0, sl
	bl seqSysEx
.L_080F479A:
	adds r7, r7, r4
	subs r5, r5, r4
	b .L_080F47AA
.L_080F47A0:
	adds r7, #2
	subs r5, #2
	b .L_080F47AA
.L_080F47A6:
	adds r7, #1
	subs r5, #1
.L_080F47AA:
	cmp r5, #0
	beq .L_080F47B6
	mov r3, sb
	cmp r3, #0
	bne .L_080F47B6
	b .L_080F464A
.L_080F47B6:
	movs r4, #0
	ldr r6, .L_080F47E0                        @ = gLiveBufLen
	cmp r4, r5
	bhs .L_080F47D0
	ldr r3, .L_080F47E4                        @ = gLiveBuf
.L_080F47C0:
	ldr r1, [r3]
	adds r1, r1, r4
	adds r2, r7, r4
	ldrb r2, [r2]
	strb r2, [r1]
	adds r4, #1
	cmp r4, r5
	blo .L_080F47C0
.L_080F47D0:
	strh r5, [r6]
	pop {r3, r4, r5}
	mov r8, r3
	mov sb, r4
	mov sl, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
.L_080F47E0:
	.word gLiveBufLen
.L_080F47E4:
	.word gLiveBuf

@ --------------------------------------------------------------------------------------------------
@ liveTick  (080F47E8, Thumb)
@   void liveTick(void)  { synthLfoTick(gLiveSynth); liveParse(); apply the note queue (as seqTrackTick); }
@ --------------------------------------------------------------------------------------------------
	.global liveTick
liveTick:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	ldr r7, .L_080F484C                        @ = gLiveSynth
	ldr r0, [r7]
	bl synthLfoTick
	movs r0, #0
	mov r8, r0
	ldr r4, .L_080F4850                        @ = gNoteQueueLen
	mov r0, r8
	strh r0, [r4]
	bl liveParse
	ldr r5, .L_080F4854                        @ = gNoteQueue
	movs r6, #0
	ldrh r4, [r4]
	cmp r8, r4
	bhs .L_080F4876
	adds r4, r7, #0
.L_080F4810:
	ldr r2, [r5]
	lsls r0, r2, #0xe
	lsrs r3, r0, #0x19
	cmp r3, #0
	beq .L_080F485C
	ldr r0, [r4]
	lsls r1, r2, #0x1c
	lsrs r1, r1, #0x1c
	lsls r2, r2, #0x15
	lsrs r2, r2, #0x19
	bl chanNoteOn
	ldr r0, [r4]
	ldr r1, [r5]
	lsls r1, r1, #0x1c
	lsrs r1, r1, #0x17
	ldr r0, [r0, #0x18]
	adds r0, r0, r1
	ldrb r0, [r0, #3]
	lsls r0, r0, #0x19
	cmp r0, #0
	bge .L_080F486A
	ldr r0, .L_080F4858                        @ = gSweepMode
	ldrb r0, [r0]
	cmp r0, #1
	bne .L_080F486A
	movs r0, #1
	mov r8, r0
	b .L_080F486A
	.hword 0x0000
.L_080F484C:
	.word gLiveSynth
.L_080F4850:
	.word gNoteQueueLen
.L_080F4854:
	.word gNoteQueue
.L_080F4858:
	.word gSweepMode
.L_080F485C:
	ldr r0, [r4]
	lsls r1, r2, #0x1c
	lsrs r1, r1, #0x1c
	lsls r2, r2, #0x15
	lsrs r2, r2, #0x19
	bl chanNoteOff
.L_080F486A:
	adds r6, #1
	adds r5, #4
	ldr r0, .L_080F4890                        @ = gNoteQueueLen
	ldrh r0, [r0]
	cmp r6, r0
	blo .L_080F4810
.L_080F4876:
	mov r0, r8
	cmp r0, #0
	beq .L_080F4886
	bl mixClearEffects
	ldr r0, .L_080F4894                        @ = gSweep
	bl sweepStart
.L_080F4886:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
.L_080F4890:
	.word gNoteQueueLen
.L_080F4894:
	.word gSweep

@ --------------------------------------------------------------------------------------------------
@ sndInit  (080F4898, Thumb)
@   void sndInit(void)
@   {
@       mixInit(0, 13379, 0x620, gSndRingBuf, 128, gSndMixBuf, 8, gSndVoiceMem);
@       psgInit();  noteInit(8, gSndNoteMem);
@       for (k = 0; k < 9; k++) { const PlayerConfig *c = &sndPlayerConfig[k];
@           synthInit(c->synth, c->channels, c->chans);  playerInit(c->player, c->synth, c->channels, c->tracks, c->prioCheck); }
@       gGameVars = gGameVarsDefault (0x03000EAF); gGameVarCount = 4; clear the 4 game variables;
@       gSweepMode = 0; gSweepPlayer = 0; gReverbBase = {0,0,0,0}; gLivePlayer = 0;
@   }
@ --------------------------------------------------------------------------------------------------
	.global sndInit
sndInit:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	sub sp, #0x10
	ldr r1, .L_080F4954                        @ = 0x00003443
	movs r2, #0xc4
	lsls r2, r2, #3
	ldr r3, .L_080F4958                        @ = gSndRingBuf
	movs r0, #0x80
	str r0, [sp]
	ldr r0, .L_080F495C                        @ = gSndMixBuf
	str r0, [sp, #4]
	movs r0, #8
	str r0, [sp, #8]
	ldr r0, .L_080F4960                        @ = gSndVoiceMem
	str r0, [sp, #0xc]
	movs r0, #0
	bl mixInit
	bl psgInit
	ldr r1, .L_080F4964                        @ = gSndNoteMem
	movs r0, #8
	bl noteInit
	movs r5, #0
	ldr r6, .L_080F4968                        @ = sndPlayerConfig
	mov r8, r6
	movs r7, #0
.L_080F48D2:
	mov r4, r8
	adds r4, #8
	adds r4, r7, r4
	ldr r0, [r4]
	ldrh r1, [r6]
	lsls r1, r1, #0x16
	lsrs r1, r1, #0x1b
	mov r2, r8
	adds r2, #4
	adds r2, r7, r2
	ldr r2, [r2]
	bl synthInit
	mov r0, r8
	adds r0, #0x10
	adds r0, r7, r0
	ldr r0, [r0]
	ldr r1, [r4]
	ldrh r2, [r6]
	lsls r2, r2, #0x16
	lsrs r2, r2, #0x1b
	ldr r3, [r6, #0xc]
	ldrb r4, [r6, #1]
	lsrs r4, r4, #2
	str r4, [sp]
	bl playerInit
	adds r6, #0x14
	adds r7, #0x14
	adds r5, #1
	cmp r5, #8
	bls .L_080F48D2
	ldr r2, .L_080F496C                        @ = gGameVars
	ldr r0, .L_080F4970                        @ = gGameVarsDefault
	str r0, [r2]
	ldr r1, .L_080F4974                        @ = gGameVarCount
	movs r0, #4
	strh r0, [r1]
	movs r5, #0
	ldr r4, .L_080F4978                        @ = gSweepMode
	ldr r6, .L_080F497C                        @ = gSweepPlayer
	ldr r1, .L_080F4980                        @ = gReverbBase
	ldr r7, .L_080F4984                        @ = gLivePlayer
	movs r3, #0
.L_080F492A:
	ldr r0, [r2]
	adds r0, r0, r5
	strb r3, [r0]
	adds r5, #1
	cmp r5, #3
	bls .L_080F492A
	movs r0, #0
	strb r0, [r4]
	movs r0, #0
	str r0, [r6]
	strb r0, [r1]
	strb r0, [r1, #1]
	strb r0, [r1, #2]
	strb r0, [r1, #3]
	str r0, [r7]
	add sp, #0x10
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
.L_080F4954:
	.word 0x00003443
.L_080F4958:
	.word gSndRingBuf
.L_080F495C:
	.word gSndMixBuf
.L_080F4960:
	.word gSndVoiceMem
.L_080F4964:
	.word gSndNoteMem
.L_080F4968:
	.word sndPlayerConfig
.L_080F496C:
	.word gGameVars
.L_080F4970:
	.word gGameVarsDefault
.L_080F4974:
	.word gGameVarCount
.L_080F4978:
	.word gSweepMode
.L_080F497C:
	.word gSweepPlayer
.L_080F4980:
	.word gReverbBase
.L_080F4984:
	.word gLivePlayer

