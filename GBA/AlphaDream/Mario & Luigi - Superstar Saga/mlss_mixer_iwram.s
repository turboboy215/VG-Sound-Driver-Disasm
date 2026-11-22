@ ============================================================================
@ AlphaDream GBA sound driver - IWRAM mixer loops (Mario & Luigi: Superstar Saga)
@ Stored LZ77-compressed at ROM 0x0819B580 (snd_MixerCodeLZ) and unpacked by
@ snd_InitHardware with BIOS SWI 0x11 to 0x03001080 (344 bytes, ARM state).
@ Reassembles byte-identically to the unpacked image:
@   arm-none-eabi-as -mcpu=arm7tdmi -o mix.o mlss_mixer_iwram.s
@   arm-none-eabi-ld -Ttext=0x03001080 -o mix.elf mix.o
@   arm-none-eabi-objcopy -O binary mix.elf mix.bin
@ Accumulator words hold two 16-bit lanes: low = right, high = left. Samples
@ are read as unsigned bytes; snd_MixFrame passes the summed (vol << 7) bias
@ in r5 so mix_Output can remove the +0x80 offset of every voice.
@ ============================================================================
    .syntax unified
    .cpu arm7tdmi
    .arm
    .text

@ mix_Resample: r1=sample data, fp=position (22.10), ip=step, r4=packed vol (R | L<<16), sb=accumulator, r2=count; acc += u8 sample * vol
    .global mix_Resample
mix_Resample:
    push {r5, r6, r7, r8, sl, lr}            @ 03001080
    subs r2, r2, #7                          @ 03001084
    blt .L_030010F0                          @ 03001088
.L_0300108C:
    ldm sb, {r3, r5, r6, r7, r8, sl, lr}     @ 0300108C
    ldrb r0, [r1, fp, lsr #10]               @ 03001090
    add fp, fp, ip                           @ 03001094
    mla r3, r0, r4, r3                       @ 03001098
    ldrb r0, [r1, fp, lsr #10]               @ 0300109C
    add fp, fp, ip                           @ 030010A0
    mla r5, r0, r4, r5                       @ 030010A4
    ldrb r0, [r1, fp, lsr #10]               @ 030010A8
    add fp, fp, ip                           @ 030010AC
    mla r6, r0, r4, r6                       @ 030010B0
    ldrb r0, [r1, fp, lsr #10]               @ 030010B4
    add fp, fp, ip                           @ 030010B8
    mla r7, r0, r4, r7                       @ 030010BC
    ldrb r0, [r1, fp, lsr #10]               @ 030010C0
    add fp, fp, ip                           @ 030010C4
    mla r8, r0, r4, r8                       @ 030010C8
    ldrb r0, [r1, fp, lsr #10]               @ 030010CC
    add fp, fp, ip                           @ 030010D0
    mla sl, r0, r4, sl                       @ 030010D4
    ldrb r0, [r1, fp, lsr #10]               @ 030010D8
    add fp, fp, ip                           @ 030010DC
    mla lr, r0, r4, lr                       @ 030010E0
    stm sb!, {r3, r5, r6, r7, r8, sl, lr}    @ 030010E4
    subs r2, r2, #7                          @ 030010E8
    bgt .L_0300108C                          @ 030010EC
.L_030010F0:
    adds r2, r2, #7                          @ 030010F0
    beq .L_03001114                          @ 030010F4
.L_030010F8:
    ldm sb, {r3}                             @ 030010F8
    ldrb r0, [r1, fp, lsr #10]               @ 030010FC
    mla r3, r0, r4, r3                       @ 03001100
    add fp, fp, ip                           @ 03001104
    stm sb!, {r3}                            @ 03001108
    subs r2, r2, #1                          @ 0300110C
    bgt .L_030010F8                          @ 03001110
.L_03001114:
    pop {r5, r6, r7, r8, sl, lr}             @ 03001114
    bx lr                                    @ 03001118

@ mix_AddConstant: sb=accumulator, sl=count, r4=constant; pads a channel that ended (keeps the unsigned-sample bias balanced)
    .global mix_AddConstant
mix_AddConstant:
    push {r5, r6, r7, r8, sl, lr}            @ 0300111C
    subs sl, sl, #8                          @ 03001120
    blt .L_03001158                          @ 03001124
.L_03001128:
    ldm sb, {r0, r2, r3, r5, r6, r7, r8, lr} @ 03001128
    add r0, r0, r4                           @ 0300112C
    add r2, r2, r4                           @ 03001130
    add r3, r3, r4                           @ 03001134
    add r5, r5, r4                           @ 03001138
    add r6, r6, r4                           @ 0300113C
    add r7, r7, r4                           @ 03001140
    add r8, r8, r4                           @ 03001144
    add lr, lr, r4                           @ 03001148
    stm sb!, {r0, r2, r3, r5, r6, r7, r8, lr} @ 0300114C
    subs sl, sl, #8                          @ 03001150
    bgt .L_03001128                          @ 03001154
.L_03001158:
    adds sl, sl, #8                          @ 03001158
    beq .L_03001174                          @ 0300115C
.L_03001160:
    ldm sb, {r0}                             @ 03001160
    add r0, r0, r4                           @ 03001164
    stm sb!, {r0}                            @ 03001168
    subs sl, sl, #1                          @ 0300116C
    bgt .L_03001160                          @ 03001170
.L_03001174:
    pop {r5, r6, r7, r8, sl, lr}             @ 03001174
    bx lr                                    @ 03001178

@ mix_Output: ip=accumulator (cleared as read), r5=bias, r4=0xFF00FF00, r1=left buffer (FIFO A), r2=right buffer (FIFO B), sl=count; 4 samples per pass
    .global mix_Output
mix_Output:
    push {r4, r5, r6, r7, r8, sb, sl, fp, lr} @ 0300117C
.L_03001180:
    ldm ip, {r0, r3, fp, lr}                 @ 03001180
    rsb r0, r5, r0                           @ 03001184
    rsb r3, r5, r3                           @ 03001188
    rsb fp, r5, fp                           @ 0300118C
    rsb lr, r5, lr                           @ 03001190
    and r0, r4, r0, ror #16                  @ 03001194
    and r3, r4, r3, ror #16                  @ 03001198
    and fp, r4, fp                           @ 0300119C
    and lr, r4, lr                           @ 030011A0
    add r0, r3, r0, lsr #8                   @ 030011A4
    add r3, lr, fp, lsr #8                   @ 030011A8
    stm ip!, {r6, r7, r8, sb}                @ 030011AC
    lsr fp, r0, #0x10                        @ 030011B0
    add fp, fp, r3, lsl #16                  @ 030011B4
    str fp, [r2], #4                         @ 030011B8
    eor r0, r0, r3                           @ 030011BC
    eor r0, r0, fp, ror #16                  @ 030011C0
    str r0, [r1], #4                         @ 030011C4
    subs sl, sl, #4                          @ 030011C8
    bne .L_03001180                          @ 030011CC
    pop {r4, r5, r6, r7, r8, sb, sl, fp, lr} @ 030011D0
    bx lr                                    @ 030011D4
