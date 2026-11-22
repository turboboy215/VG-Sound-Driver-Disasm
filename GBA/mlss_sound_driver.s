@ ============================================================================
@ AlphaDream GBA sound driver - Mario & Luigi: Superstar Saga (E) (A88P)
@ ROM range 0x0819B2D8-0x0819CBFF (code, tables, LZ77 mixer); song data follows
@ at 0x0819CC00.  Reassembles byte-identically:
@   arm-none-eabi-as -mcpu=arm7tdmi -o drv.o mlss_sound_driver.s
@   arm-none-eabi-ld -Ttext=0x0819B2D8 -o drv.elf drv.o
@   arm-none-eabi-objcopy -O binary drv.elf drv.bin
@ All names are assigned by this analysis (no symbols exist in the ROM).
@ See alphadream-technical-reference.md (GBA Audio Disassembly project).
@ ============================================================================
    .syntax unified
    .cpu arm7tdmi
    .text

    .equ _call_via_r1, 0x081DBB40
    .equ __divsi3, 0x081DBB78
    .equ __udivsi3, 0x081DBCE8

@ RAM used (absolute)
@   0x03007FF0  u32  pointer to the driver work area (0x02000480 in this game)
@   0x03001080  IWRAM mixer loops (unpacked from snd_MixerCodeLZ)
@   0x030011D8  u8[3] double-buffer flags {half0 mixed, half1 mixed, playing half}
@   0x030011E0  u32[264] stereo mix accumulator
@   0x03001600/0x03001708  left (FIFO A) halves, 0x03001810/0x03001918 right (FIFO B)
@   0x03001B50  8 x 16-byte DirectSound channel records
@
@ Work area (work = [0x03007FF0])
@   +0x000 tracks: player p (0 = SFX, 1-2 = music), track t at 0x180*p + 0x20*t
@   +0x480 u16 command ring[8]   +0x490/+0x492 read/write index
@   +0x494 u8 player flags[3]    +0x498 u16 player volume[3]   +0x4A4 u32 tempo divisor[3]
@   +0x4B0 u16 SFX id per player-0 track[12]   +0x4C8 PSG state[4] x 12 bytes
@   +0x4F4 u16 noise NR43        +0x4F8 u8 loaded wave pattern
@ Track (0x20): +0 u16 flags (1 active, 2 muted, 0x20 rest byte follows notes,
@   0x40 tie, 0x80 note on, 0x100 pitch LFO, 0x800 volume LFO), +2 speed,
@   +3 tempo acc, +4 data ptr, +8 u16 read offset, +0xA wait, +0xB key,
@   +0xC program, +0xD volume, +0xE pan, +0xF bend range, +0x10 s8 bend,
@   +0x11 s8 detune, +0x12 channel, +0x13 player, +0x14-0x17 volume LFO
@   (depth, half-period, delay, counter), +0x18-0x1B pitch LFO, +0x1C-0x1F loops
@ DS channel (16): +0 status (0x80 start, 0x81 A, 0x82 D, 0x83 S, |0x40 release),
@   +1 env, +2 u16 sample (bit 15 fixed pitch), +4 u32 pos (22.10),
@   +8 right vol, +9 left vol, +0xA u16 pitch (fine, key), +0xC A D S R
@ Channel vtable: [0] note on, [1] note on, [2] volume, [3] pan, [4] pitch,
@   [5] note off, [6] restore
    .thumb


@ ---------------------------------------------------------------------------
@ snd_CalcStep: pitch (key<<8|fine) + sample rate -> 22.10 resample step
    .global snd_CalcStep
    .thumb_func
snd_CalcStep:
    mov ip, r0                               @ 0819B2D8
    adr r3, snd_KeyOctaveMap                 @ 0819B2DA
    ldrb r1, [r1, r3]                        @ 0819B2DC
    adr r3, snd_PitchTable                   @ 0819B2DE
    lsls r0, r1, #0x1c                       @ 0819B2E0
    lsrs r0, r0, #0x1a                       @ 0819B2E2
    adds r0, r0, r3                          @ 0819B2E4
    ldr r3, [r0]                             @ 0819B2E6
    ldr r0, [r0, #4]                         @ 0819B2E8
    subs r0, r0, r3                          @ 0819B2EA
    muls r0, r2, r0                          @ 0819B2EC
    lsrs r0, r0, #8                          @ 0819B2EE
    adds r3, r3, r0                          @ 0819B2F0
    lsrs r1, r1, #4                          @ 0819B2F2
    lsrs r3, r1                              @ 0819B2F4
    ldr r2, .Lit_0819B30C                    @ 0819B2F6
    bx pc                                    @ 0819B2F8
    .hword 0x0000   @ pad after bx pc
    .arm
.L_0819B2FC:
    umull r0, r1, ip, r3                     @ 0819B2FC
    umull r3, r0, r1, r2                     @ 0819B300
    add r0, r0, r1                           @ 0819B304
    bx lr                                    @ 0819B308
.Lit_0819B30C: .word 0x0A080000

@ u32[13]: 2^(n/12) * 2^23, n = 0..12
    .align 2, 0
snd_PitchTable:
    .word 0x00800000
    .word 0x00879C7C
    .word 0x008FACD6
    .word 0x009837F0
    .word 0x00A14517
    .word 0x00AADC08
    .word 0x00B504F3
    .word 0x00BFC886
    .word 0x00CB2FF5
    .word 0x00D744FC
    .word 0x00E411F0
    .word 0x00F1A1BF
    .word 0x01000000

@ u8[128]: key -> (octave shift << 4) | semitone
    .align 2, 0
snd_KeyOctaveMap:
    .byte 0xA0, 0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7, 0xA8, 0xA9, 0xAA, 0xAB, 0x90, 0x91, 0x92, 0x93
    .byte 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0x9B, 0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87
    .byte 0x88, 0x89, 0x8A, 0x8B, 0x70, 0x71, 0x72, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x7B
    .byte 0x60, 0x61, 0x62, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69, 0x6A, 0x6B, 0x50, 0x51, 0x52, 0x53
    .byte 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x5B, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47
    .byte 0x48, 0x49, 0x4A, 0x4B, 0x30, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x3B
    .byte 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x10, 0x11, 0x12, 0x13
    .byte 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x1B, 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07
    .thumb

@ ---------------------------------------------------------------------------
@ snd_MixFrame: mix the 8 DirectSound channels into one 264-sample frame
    .global snd_MixFrame
    .thumb_func
snd_MixFrame:
    push {r4, r5, r6, r7, lr}                @ 0819B3C4
    mov r7, sl                               @ 0819B3C6
    mov r6, sb                               @ 0819B3C8
    mov r5, r8                               @ 0819B3CA
    push {r5, r6, r7}                        @ 0819B3CC
    push {r2, r3}                            @ 0819B3CE
    movs r5, #0                              @ 0819B3D0
    ldr r6, .Lit_0819B710                    @ 0819B3D2
    movs r7, #8                              @ 0819B3D4
    mov sb, r0                               @ 0819B3D6
    mov sl, r1                               @ 0819B3D8
.L_0819B3DA:
    ldrb r0, [r6]                            @ 0819B3DA
    cmp r0, #0                               @ 0819B3DC
    beq .L_0819B440                          @ 0819B3DE
    cmp r0, #0x80                            @ 0819B3E0
    beq .L_0819B3FE                          @ 0819B3E2
    ldrb r1, [r6, #1]                        @ 0819B3E4
    cmp r0, #0x81                            @ 0819B3E6
    beq .L_0819B404                          @ 0819B3E8
    cmp r0, #0x82                            @ 0819B3EA
    beq .L_0819B412                          @ 0819B3EC
    cmp r0, #0x83                            @ 0819B3EE
    beq .L_0819B426                          @ 0819B3F0
    ldrb r2, [r6, #0xf]                      @ 0819B3F2
    subs r1, r1, r2                          @ 0819B3F4
    bhi .L_0819B424                          @ 0819B3F6
    movs r0, #0                              @ 0819B3F8
    strb r0, [r6]                            @ 0819B3FA
    b .L_0819B440                            @ 0819B3FC
.L_0819B3FE:
    adds r0, #1                              @ 0819B3FE
    ldrb r1, [r6, #0xc]                      @ 0819B400
    b .L_0819B422                            @ 0819B402
.L_0819B404:
    ldrb r2, [r6, #0xc]                      @ 0819B404
    adds r1, r1, r2                          @ 0819B406
    cmp r1, #0xff                            @ 0819B408
    bmi .L_0819B424                          @ 0819B40A
    movs r1, #0xff                           @ 0819B40C
    adds r0, #1                              @ 0819B40E
    b .L_0819B422                            @ 0819B410
.L_0819B412:
    ldrb r2, [r6, #0xd]                      @ 0819B412
    subs r1, r1, r2                          @ 0819B414
    bhs .L_0819B41E                          @ 0819B416
    ldrb r2, [r6, #0xe]                      @ 0819B418
    cmp r0, r2                               @ 0819B41A
    bhi .L_0819B424                          @ 0819B41C
.L_0819B41E:
    adds r0, #1                              @ 0819B41E
    ldrb r1, [r6, #0xe]                      @ 0819B420
.L_0819B422:
    strb r0, [r6]                            @ 0819B422
.L_0819B424:
    strb r1, [r6, #1]                        @ 0819B424
.L_0819B426:
    ldrb r4, [r6, #9]                        @ 0819B426
    lsls r4, r4, #0x10                       @ 0819B428
    ldrb r0, [r6, #8]                        @ 0819B42A
    orrs r4, r0                              @ 0819B42C
    muls r4, r1, r4                          @ 0819B42E
    lsrs r4, r4, #8                          @ 0819B430
    movs r0, #0xff                           @ 0819B432
    lsls r0, r0, #8                          @ 0819B434
    bics r4, r0                              @ 0819B436
    lsls r1, r4, #7                          @ 0819B438
    adds r5, r5, r1                          @ 0819B43A
    bl snd_MixChannel                        @ 0819B43C
.L_0819B440:
    adds r6, #0x10                           @ 0819B440
    subs r7, #1                              @ 0819B442
    bne .L_0819B3DA                          @ 0819B444
    pop {r1, r2}                             @ 0819B446
    mov ip, sb                               @ 0819B448
    movs r0, #0xff                           @ 0819B44A
    lsls r4, r0, #0x10                       @ 0819B44C
    adds r4, r4, r0                          @ 0819B44E
    lsls r4, r4, #8                          @ 0819B450
    movs r6, #0                              @ 0819B452
    movs r7, #0                              @ 0819B454
    mov r8, r6                               @ 0819B456
    mov sb, r6                               @ 0819B458
    ldr r0, .Lit_0819B714                    @ 0819B45A
    bl snd_CallR0                            @ 0819B45C
    pop {r3, r4, r5}                         @ 0819B460
    mov r8, r3                               @ 0819B462
    mov sb, r4                               @ 0819B464
    mov sl, r5                               @ 0819B466
    pop {r4, r5, r6, r7, pc}                 @ 0819B468
    .hword 0x0000   @ 0819B46A alignment

@ ---------------------------------------------------------------------------
@ snd_MixChannel: resample one channel into the stereo accumulator (calls IWRAM loops)
    .global snd_MixChannel
    .thumb_func
snd_MixChannel:
    push {r4, r5, r6, r7, lr}                @ 0819B46C
    mov r7, sl                               @ 0819B46E
    mov r5, sb                               @ 0819B470
    mov r3, r8                               @ 0819B472
    push {r3, r5, r7}                        @ 0819B474
    ldrh r2, [r6, #2]                        @ 0819B476
    ldr r1, .Lit_0819B718                    @ 0819B478
    lsls r0, r2, #0x11                       @ 0819B47A
    lsrs r0, r0, #0xf                        @ 0819B47C
    ldr r7, [r1, r0]                         @ 0819B47E
    adds r7, r7, r1                          @ 0819B480
    lsls r2, r2, #0x11                       @ 0819B482
    blo .L_0819B48E                          @ 0819B484
    ldr r0, [r7, #4]                         @ 0819B486
    movs r1, #0x3c                           @ 0819B488
    movs r2, #0                              @ 0819B48A
    b .L_0819B494                            @ 0819B48C
.L_0819B48E:
    ldr r0, [r7, #4]                         @ 0819B48E
    ldrb r1, [r6, #0xb]                      @ 0819B490
    ldrb r2, [r6, #0xa]                      @ 0819B492
.L_0819B494:
    bl snd_CalcStep                          @ 0819B494
    mov ip, r0                               @ 0819B498
    ldr r0, [r6, #4]                         @ 0819B49A
    mov fp, r0                               @ 0819B49C
.L_0819B49E:
    ldr r0, [r7, #0xc]                       @ 0819B49E
    lsls r0, r0, #0xa                        @ 0819B4A0
    mov r1, fp                               @ 0819B4A2
    subs r0, r0, r1                          @ 0819B4A4
    add r0, ip                               @ 0819B4A6
    subs r0, #1                              @ 0819B4A8
    mov r2, sl                               @ 0819B4AA
    mov r1, ip                               @ 0819B4AC
    muls r1, r2, r1                          @ 0819B4AE
    cmp r1, r0                               @ 0819B4B0
    blo .L_0819B4BC                          @ 0819B4B2
    mov r1, ip                               @ 0819B4B4
    bl __udivsi3                             @ 0819B4B6
    adds r2, r0, #0                          @ 0819B4BA
.L_0819B4BC:
    movs r0, #0                              @ 0819B4BC
    subs r0, r0, r2                          @ 0819B4BE
    add sl, r0                               @ 0819B4C0
    adds r1, r7, #0                          @ 0819B4C2
    adds r1, #0x10                           @ 0819B4C4
    ldr r0, .Lit_0819B71C                    @ 0819B4C6
    bl snd_CallR0                            @ 0819B4C8
    ldr r0, [r7, #0xc]                       @ 0819B4CC
    lsls r0, r0, #0xa                        @ 0819B4CE
    cmp fp, r0                               @ 0819B4D0
    blt .L_0819B502                          @ 0819B4D2
    ldrb r1, [r7, #3]                        @ 0819B4D4
    movs r0, #0x40                           @ 0819B4D6
    ands r0, r1                              @ 0819B4D8
    beq .L_0819B4EE                          @ 0819B4DA
    ldr r0, [r7, #8]                         @ 0819B4DC
    ldr r1, [r7, #0xc]                       @ 0819B4DE
    subs r0, r0, r1                          @ 0819B4E0
    lsls r0, r0, #0xa                        @ 0819B4E2
    add fp, r0                               @ 0819B4E4
    mov r0, sl                               @ 0819B4E6
    cmp r0, #0                               @ 0819B4E8
    beq .L_0819B502                          @ 0819B4EA
    b .L_0819B49E                            @ 0819B4EC
.L_0819B4EE:
    movs r0, #0                              @ 0819B4EE
    strb r0, [r6]                            @ 0819B4F0
    mov r0, sl                               @ 0819B4F2
    cmp r0, #0                               @ 0819B4F4
    beq .L_0819B502                          @ 0819B4F6
    movs r0, #0x80                           @ 0819B4F8
    muls r4, r0, r4                          @ 0819B4FA
    ldr r0, .Lit_0819B720                    @ 0819B4FC
    bl snd_CallR0                            @ 0819B4FE
.L_0819B502:
    mov r0, fp                               @ 0819B502
    str r0, [r6, #4]                         @ 0819B504
    pop {r3, r4, r5}                         @ 0819B506
    mov r8, r3                               @ 0819B508
    mov sb, r4                               @ 0819B50A
    mov sl, r5                               @ 0819B50C
    pop {r4, r5, r6, r7, pc}                 @ 0819B50E

@ ---------------------------------------------------------------------------
@ snd_InitHardware: unpack IWRAM mixer, set SOUNDCNT/DMA1/DMA2/Timer0 (15768 Hz)
    .global snd_InitHardware
    .thumb_func
snd_InitHardware:
    adr r0, snd_MixerCodeLZ                  @ 0819B510
    ldr r1, .Lit_0819B724                    @ 0819B512
    svc #0x11                                @ 0819B514
    ldr r0, .Lit_0819B728                    @ 0819B516
    movs r1, #0                              @ 0819B518
    movs r2, #0x10                           @ 0819B51A
.L_0819B51C:
    stm r0!, {r1}                            @ 0819B51C
    subs r2, #1                              @ 0819B51E
    bne .L_0819B51C                          @ 0819B520
    ldr r0, .Lit_0819B72C                    @ 0819B522
    movs r1, #1                              @ 0819B524
    strb r1, [r0]                            @ 0819B526
    strb r1, [r0, #1]                        @ 0819B528
    movs r2, #0                              @ 0819B52A
    strb r2, [r0, #2]                        @ 0819B52C
    ldr r3, .Lit_0819B730                    @ 0819B52E
    movs r0, #0x80                           @ 0819B530
    strh r0, [r3, #0x24]                     @ 0819B532
    movs r1, #0x42                           @ 0819B534
    lsls r1, r1, #8                          @ 0819B536
    strh r1, [r3, #0x28]                     @ 0819B538
    movs r0, #0x88                           @ 0819B53A
    lsls r0, r0, #8                          @ 0819B53C
    strh r0, [r3, #0x22]                     @ 0819B53E
    movs r0, #0                              @ 0819B540
    movs r1, #8                              @ 0819B542
.L_0819B544:
    str r0, [r3, #0x40]                      @ 0819B544
    str r0, [r3, #0x44]                      @ 0819B546
    subs r1, #1                              @ 0819B548
    bne .L_0819B544                          @ 0819B54A
    ldr r2, .Lit_0819B734                    @ 0819B54C
    movs r0, #0x40                           @ 0819B54E
    adds r0, r0, r3                          @ 0819B550
    str r0, [r2, #0x10]                      @ 0819B552
    adds r0, #4                              @ 0819B554
    str r0, [r2, #0x1c]                      @ 0819B556
    ldr r0, .Lit_0819B738                    @ 0819B558
    str r0, [r2, #0xc]                       @ 0819B55A
    ldr r0, .Lit_0819B73C                    @ 0819B55C
    str r0, [r2, #0x18]                      @ 0819B55E
    movs r0, #0xb6                           @ 0819B560
    movs r1, #4                              @ 0819B562
    lsls r0, r0, #0x18                       @ 0819B564
    orrs r0, r1                              @ 0819B566
    str r0, [r2, #0x14]                      @ 0819B568
    str r0, [r2, #0x20]                      @ 0819B56A
    ldr r1, .Lit_0819B740                    @ 0819B56C
    strh r1, [r3, #0x22]                     @ 0819B56E
    ldr r2, .Lit_0819B744                    @ 0819B570
    movs r0, #0                              @ 0819B572
    strh r0, [r2, #2]                        @ 0819B574
    ldr r1, .Lit_0819B748                    @ 0819B576
    strh r1, [r2]                            @ 0819B578
    movs r0, #0x80                           @ 0819B57A
    strh r0, [r2, #2]                        @ 0819B57C
    bx lr                                    @ 0819B57E

@ LZ77 (BIOS SWI 0x11) ARM mixer, unpacks to 0x03001080 (344 bytes); see mlss_mixer_iwram.s
    .align 2, 0
snd_MixerCodeLZ:
    .byte 0x10, 0x58, 0x01, 0x00, 0x00, 0xE0, 0x45, 0x2D, 0xE9, 0x07, 0x20, 0x52, 0xE2, 0x00, 0x18, 0x00
    .byte 0x00, 0xBA, 0xE8, 0x45, 0x99, 0xE8, 0x00, 0x2B, 0x05, 0xD1, 0xE7, 0x0C, 0xB0, 0x8B, 0xE0, 0x09
    .byte 0x90, 0x34, 0x23, 0xE0, 0x60, 0x0B, 0x54, 0x25, 0x70, 0x0B, 0x24, 0x64, 0x26, 0x70, 0x0B, 0x74
    .byte 0x27, 0x70, 0x0B, 0x84, 0x28, 0x90, 0x70, 0x0B, 0xA4, 0x2A, 0x70, 0x0B, 0xE4, 0x2E, 0xE0, 0xE8
    .byte 0x10, 0x45, 0xA9, 0xE8, 0x10, 0x63, 0xE6, 0xFF, 0xFF, 0xCA, 0x00, 0x07, 0x20, 0x92, 0xE2, 0x06
    .byte 0x00, 0x00, 0x0A, 0x38, 0x08, 0x00, 0x30, 0x6B, 0x10, 0x67, 0x10, 0x27, 0x08, 0x00, 0xA9, 0x28
    .byte 0xE8, 0x01, 0x00, 0x23, 0xF8, 0x00, 0x23, 0xE0, 0x45, 0xBD, 0x04, 0xE8, 0x1E, 0xFF, 0x2F, 0xE1
    .byte 0x10, 0x9B, 0x08, 0xA0, 0x10, 0x5A, 0xE2, 0x0B, 0x00, 0x9B, 0xED, 0x41, 0x99, 0xE8, 0x00, 0x04
    .byte 0x00, 0x80, 0xE0, 0x04, 0x20, 0x82, 0xE0, 0x00, 0x04, 0x30, 0x83, 0xE0, 0x04, 0x50, 0x85, 0xE0
    .byte 0x00, 0x04, 0x60, 0x86, 0xE0, 0x04, 0x70, 0x87, 0xE0, 0x00, 0x04, 0x80, 0x88, 0xE0, 0x04, 0xE0
    .byte 0x8E, 0xE0, 0x0A, 0xED, 0x41, 0xA9, 0xE8, 0x10, 0x2F, 0xF3, 0x00, 0x43, 0x08, 0x0B, 0xA0, 0x9A
    .byte 0xE2, 0x04, 0x00, 0x67, 0x01, 0x00, 0x67, 0x10, 0x37, 0x68, 0x01, 0x10, 0x5F, 0x00, 0x1B, 0xFA
    .byte 0x80, 0x5F, 0xF0, 0x4F, 0x2D, 0x00, 0xE9, 0x09, 0x48, 0x9C, 0xE8, 0x00, 0x00, 0x65, 0x00, 0xE0
    .byte 0x03, 0x30, 0x65, 0xE0, 0x0B, 0xB0, 0x65, 0x00, 0xE0, 0x0E, 0xE0, 0x65, 0xE0, 0x60, 0x08, 0x04
    .byte 0x0A, 0xE0, 0x63, 0x38, 0x04, 0x00, 0x0F, 0x04, 0x00, 0x0F, 0x04, 0x00, 0xE0, 0x20, 0x04, 0x83
    .byte 0xE0, 0x2B, 0x34, 0x8E, 0x00, 0xE0, 0xC0, 0x03, 0xAC, 0xE8, 0x20, 0xB8, 0xA0, 0x00, 0xE1, 0x03
    .byte 0xB8, 0x8B, 0xE0, 0x04, 0xB0, 0x82, 0x00, 0xE4, 0x03, 0x00, 0x20, 0xE0, 0x6B, 0x08, 0x20, 0x02
    .byte 0xE0, 0x04, 0x00, 0x81, 0xE4, 0x04, 0x00, 0x5B, 0xEB, 0x04, 0xFF, 0xFF, 0x1A, 0xF0, 0x4F, 0x30
    .byte 0x5B, 0x00, 0x00, 0x00

@ ---------------------------------------------------------------------------
@ snd_CallR0: bx r0 (call IWRAM ARM routine)
    .global snd_CallR0
    .thumb_func
snd_CallR0:
    bx r0                                    @ 0819B6A4

@ ---------------------------------------------------------------------------
@ snd_VCountIRQ: per-frame IRQ: flip output half, rearm DMA at wrap
    .global snd_VCountIRQ
    .thumb_func
snd_VCountIRQ:
    ldr r3, .Lit_0819B74C                    @ 0819B6A6
    movs r2, #0                              @ 0819B6A8
    ldrb r0, [r3, #2]                        @ 0819B6AA
    movs r1, #1                              @ 0819B6AC
    eors r0, r1                              @ 0819B6AE
    strb r0, [r3, #2]                        @ 0819B6B0
    strb r2, [r3, r0]                        @ 0819B6B2
    bne .L_0819B6D2                          @ 0819B6B4
    ldr r3, .Lit_0819B734                    @ 0819B6B6
    ldr r1, .Lit_0819B750                    @ 0819B6B8
    strh r1, [r3, #0x16]                     @ 0819B6BA
    strh r1, [r3, #0x22]                     @ 0819B6BC
    mov r8, r8                               @ 0819B6BE
    mov r8, r8                               @ 0819B6C0
    ldr r1, .Lit_0819B754                    @ 0819B6C2
    strh r1, [r3, #0x16]                     @ 0819B6C4
    strh r1, [r3, #0x22]                     @ 0819B6C6
    mov r8, r8                               @ 0819B6C8
    movs r1, #0xb6                           @ 0819B6CA
    lsls r1, r1, #8                          @ 0819B6CC
    strh r1, [r3, #0x16]                     @ 0819B6CE
    strh r1, [r3, #0x22]                     @ 0819B6D0
.L_0819B6D2:
    bx lr                                    @ 0819B6D2

@ ---------------------------------------------------------------------------
@ snd_MixIfNeeded: mix the half of the double buffer that is not playing
    .global snd_MixIfNeeded
    .thumb_func
snd_MixIfNeeded:
    ldr r3, .Lit_0819B758                    @ 0819B6D4
    ldrb r1, [r3]                            @ 0819B6D6
    cmp r1, #0                               @ 0819B6D8
    bne .L_0819B6EA                          @ 0819B6DA
    ldrb r0, [r3, #2]                        @ 0819B6DC
    cmp r0, #0                               @ 0819B6DE
    beq .L_0819B6EA                          @ 0819B6E0
    movs r1, #1                              @ 0819B6E2
    strb r1, [r3]                            @ 0819B6E4
    ldr r2, .Lit_0819B75C                    @ 0819B6E6
    b .L_0819B6FC                            @ 0819B6E8
.L_0819B6EA:
    ldrb r2, [r3, #1]                        @ 0819B6EA
    cmp r2, #0                               @ 0819B6EC
    bne .L_0819B70E                          @ 0819B6EE
    ldrb r0, [r3, #2]                        @ 0819B6F0
    cmp r0, #1                               @ 0819B6F2
    beq .L_0819B70E                          @ 0819B6F4
    movs r1, #1                              @ 0819B6F6
    strb r1, [r3, #1]                        @ 0819B6F8
    ldr r2, .Lit_0819B760                    @ 0819B6FA
.L_0819B6FC:
    ldr r0, .Lit_0819B764                    @ 0819B6FC
    movs r1, #0x21                           @ 0819B6FE
    lsls r1, r1, #3                          @ 0819B700
    adds r3, r1, r1                          @ 0819B702
    adds r3, r3, r2                          @ 0819B704
    push {lr}                                @ 0819B706
    bl snd_MixFrame                          @ 0819B708
    pop {pc}                                 @ 0819B70C
.L_0819B70E:
    bx lr                                    @ 0819B70E
.Lit_0819B710: .word 0x03001B50
.Lit_0819B714: .word 0x0300117C
.Lit_0819B718: .word 0x08A82088
.Lit_0819B71C: .word 0x03001080
.Lit_0819B720: .word 0x0300111C
.Lit_0819B724: .word 0x03001080
.Lit_0819B728: .word 0x03001B50
.Lit_0819B72C: .word 0x030011D8
.Lit_0819B730: .word 0x04000060
.Lit_0819B734: .word 0x040000B0
.Lit_0819B738: .word 0x03001600
.Lit_0819B73C: .word 0x03001810
.Lit_0819B740: .word 0x0000120E
.Lit_0819B744: .word 0x04000100
.Lit_0819B748: .word 0xFFFFFBD8
.Lit_0819B74C: .word 0x030011D8
.Lit_0819B750: .word 0x00008440
.Lit_0819B754: .word 0x00000440
.Lit_0819B758: .word 0x030011D8
.Lit_0819B75C: .word 0x03001600
.Lit_0819B760: .word 0x03001708
.Lit_0819B764: .word 0x030011E0

@ ---------------------------------------------------------------------------
@ trk_ResetLfo1: note-on: restart volume LFO (delay)
    .global trk_ResetLfo1
    .thumb_func
trk_ResetLfo1:
    ldrh r2, [r0]                            @ 0819B768
    ldr r1, .Lit_0819B778                    @ 0819B76A
    ands r1, r2                              @ 0819B76C
    strh r1, [r0]                            @ 0819B76E
    ldrb r1, [r0, #0x16]                     @ 0819B770
    strb r1, [r0, #0x17]                     @ 0819B772
    bx lr                                    @ 0819B774
    .hword 0x0000   @ 0819B776 alignment
.Lit_0819B778: .word 0x0000CFFF

@ ---------------------------------------------------------------------------
@ trk_TickLfo1: volume LFO tick (square wave)
    .global trk_TickLfo1
    .thumb_func
trk_TickLfo1:
    push {r4, lr}                            @ 0819B77C
    adds r2, r0, #0                          @ 0819B77E
    adds r4, r1, #0                          @ 0819B780
    ldrb r0, [r2, #0x17]                     @ 0819B782
    cmp r0, #0                               @ 0819B784
    beq .L_0819B78E                          @ 0819B786
    subs r0, #1                              @ 0819B788
    strb r0, [r2, #0x17]                     @ 0819B78A
    b .L_0819B7BA                            @ 0819B78C
.L_0819B78E:
    ldrb r0, [r2, #0x15]                     @ 0819B78E
    strb r0, [r2, #0x17]                     @ 0819B790
    ldrh r3, [r2]                            @ 0819B792
    movs r1, #0x80                           @ 0819B794
    lsls r1, r1, #5                          @ 0819B796
    adds r0, r1, #0                          @ 0819B798
    ands r0, r3                              @ 0819B79A
    cmp r0, #0                               @ 0819B79C
    beq .L_0819B7B4                          @ 0819B79E
    movs r1, #0x80                           @ 0819B7A0
    lsls r1, r1, #6                          @ 0819B7A2
    adds r0, r1, #0                          @ 0819B7A4
    eors r0, r3                              @ 0819B7A6
    strh r0, [r2]                            @ 0819B7A8
    ldr r1, [r4, #8]                         @ 0819B7AA
    adds r0, r2, #0                          @ 0819B7AC
    bl _call_via_r1                          @ 0819B7AE
    b .L_0819B7BA                            @ 0819B7B2
.L_0819B7B4:
    adds r0, r1, #0                          @ 0819B7B4
    orrs r0, r3                              @ 0819B7B6
    strh r0, [r2]                            @ 0819B7B8
.L_0819B7BA:
    pop {r4}                                 @ 0819B7BA
    pop {r0}                                 @ 0819B7BC
    bx r0                                    @ 0819B7BE

@ ---------------------------------------------------------------------------
@ trk_Lfo1Value: current volume-LFO offset (+/-depth)
    .global trk_Lfo1Value
    .thumb_func
trk_Lfo1Value:
    push {lr}                                @ 0819B7C0
    adds r1, r0, #0                          @ 0819B7C2
    ldrh r2, [r1]                            @ 0819B7C4
    movs r0, #0x80                           @ 0819B7C6
    lsls r0, r0, #5                          @ 0819B7C8
    ands r0, r2                              @ 0819B7CA
    cmp r0, #0                               @ 0819B7CC
    beq .L_0819B7E4                          @ 0819B7CE
    movs r0, #0x80                           @ 0819B7D0
    lsls r0, r0, #6                          @ 0819B7D2
    ands r0, r2                              @ 0819B7D4
    cmp r0, #0                               @ 0819B7D6
    beq .L_0819B7E0                          @ 0819B7D8
    ldrb r0, [r1, #0x14]                     @ 0819B7DA
    rsbs r0, r0, #0                          @ 0819B7DC
    b .L_0819B7E6                            @ 0819B7DE
.L_0819B7E0:
    ldrb r0, [r1, #0x14]                     @ 0819B7E0
    b .L_0819B7E6                            @ 0819B7E2
.L_0819B7E4:
    movs r0, #0                              @ 0819B7E4
.L_0819B7E6:
    pop {r1}                                 @ 0819B7E6
    bx r1                                    @ 0819B7E8
    .hword 0x0000   @ 0819B7EA alignment

@ ---------------------------------------------------------------------------
@ trk_ResetLfo2: note-on: restart pitch LFO (delay)
    .global trk_ResetLfo2
    .thumb_func
trk_ResetLfo2:
    ldrh r2, [r0]                            @ 0819B7EC
    ldr r1, .Lit_0819B7FC                    @ 0819B7EE
    ands r1, r2                              @ 0819B7F0
    strh r1, [r0]                            @ 0819B7F2
    ldrb r1, [r0, #0x1a]                     @ 0819B7F4
    strb r1, [r0, #0x1b]                     @ 0819B7F6
    bx lr                                    @ 0819B7F8
    .hword 0x0000   @ 0819B7FA alignment
.Lit_0819B7FC: .word 0x0000F9FF

@ ---------------------------------------------------------------------------
@ trk_TickLfo2: pitch LFO tick (square wave)
    .global trk_TickLfo2
    .thumb_func
trk_TickLfo2:
    push {r4, lr}                            @ 0819B800
    adds r2, r0, #0                          @ 0819B802
    adds r4, r1, #0                          @ 0819B804
    ldrb r0, [r2, #0x1b]                     @ 0819B806
    cmp r0, #0                               @ 0819B808
    beq .L_0819B812                          @ 0819B80A
    subs r0, #1                              @ 0819B80C
    strb r0, [r2, #0x1b]                     @ 0819B80E
    b .L_0819B83E                            @ 0819B810
.L_0819B812:
    ldrb r0, [r2, #0x19]                     @ 0819B812
    strb r0, [r2, #0x1b]                     @ 0819B814
    ldrh r3, [r2]                            @ 0819B816
    movs r1, #0x80                           @ 0819B818
    lsls r1, r1, #2                          @ 0819B81A
    adds r0, r1, #0                          @ 0819B81C
    ands r0, r3                              @ 0819B81E
    cmp r0, #0                               @ 0819B820
    beq .L_0819B838                          @ 0819B822
    movs r1, #0x80                           @ 0819B824
    lsls r1, r1, #3                          @ 0819B826
    adds r0, r1, #0                          @ 0819B828
    eors r0, r3                              @ 0819B82A
    strh r0, [r2]                            @ 0819B82C
    ldr r1, [r4, #0x10]                      @ 0819B82E
    adds r0, r2, #0                          @ 0819B830
    bl _call_via_r1                          @ 0819B832
    b .L_0819B83E                            @ 0819B836
.L_0819B838:
    adds r0, r1, #0                          @ 0819B838
    orrs r0, r3                              @ 0819B83A
    strh r0, [r2]                            @ 0819B83C
.L_0819B83E:
    pop {r4}                                 @ 0819B83E
    pop {r0}                                 @ 0819B840
    bx r0                                    @ 0819B842

@ ---------------------------------------------------------------------------
@ trk_Lfo2Value: current pitch-LFO offset (+/-depth)
    .global trk_Lfo2Value
    .thumb_func
trk_Lfo2Value:
    push {lr}                                @ 0819B844
    adds r1, r0, #0                          @ 0819B846
    ldrh r2, [r1]                            @ 0819B848
    movs r0, #0x80                           @ 0819B84A
    lsls r0, r0, #2                          @ 0819B84C
    ands r0, r2                              @ 0819B84E
    cmp r0, #0                               @ 0819B850
    beq .L_0819B868                          @ 0819B852
    movs r0, #0x80                           @ 0819B854
    lsls r0, r0, #3                          @ 0819B856
    ands r0, r2                              @ 0819B858
    cmp r0, #0                               @ 0819B85A
    beq .L_0819B864                          @ 0819B85C
    ldrb r0, [r1, #0x18]                     @ 0819B85E
    rsbs r0, r0, #0                          @ 0819B860
    b .L_0819B86A                            @ 0819B862
.L_0819B864:
    ldrb r0, [r1, #0x18]                     @ 0819B864
    b .L_0819B86A                            @ 0819B866
.L_0819B868:
    movs r0, #0                              @ 0819B868
.L_0819B86A:
    pop {r1}                                 @ 0819B86A
    bx r1                                    @ 0819B86C
    .hword 0x0000   @ 0819B86E alignment

@ ---------------------------------------------------------------------------
@ ds_SetPitch: vtable[4]: DirectSound pitch
    .global ds_SetPitch
    .thumb_func
ds_SetPitch:
    push {r4, r5, lr}                        @ 0819B870
    adds r5, r0, #0                          @ 0819B872
    ldrb r0, [r5, #0xb]                      @ 0819B874
    lsls r4, r0, #8                          @ 0819B876
    movs r1, #0x10                           @ 0819B878
    ldrsb r1, [r5, r1]                       @ 0819B87A
    ldrb r0, [r5, #0xf]                      @ 0819B87C
    lsls r0, r0, #1                          @ 0819B87E
    muls r0, r1, r0                          @ 0819B880
    adds r0, r4, r0                          @ 0819B882
    lsls r0, r0, #0x10                       @ 0819B884
    lsrs r4, r0, #0x10                       @ 0819B886
    movs r0, #0x11                           @ 0819B888
    ldrsb r0, [r5, r0]                       @ 0819B88A
    adds r0, r4, r0                          @ 0819B88C
    lsls r0, r0, #0x10                       @ 0819B88E
    lsrs r4, r0, #0x10                       @ 0819B890
    ldrh r1, [r5]                            @ 0819B892
    movs r0, #0x80                           @ 0819B894
    lsls r0, r0, #1                          @ 0819B896
    ands r0, r1                              @ 0819B898
    cmp r0, #0                               @ 0819B89A
    beq .L_0819B8AA                          @ 0819B89C
    adds r0, r5, #0                          @ 0819B89E
    bl trk_Lfo2Value                         @ 0819B8A0
    adds r0, r4, r0                          @ 0819B8A4
    lsls r0, r0, #0x10                       @ 0819B8A6
    lsrs r4, r0, #0x10                       @ 0819B8A8
.L_0819B8AA:
    ldrb r0, [r5, #0x12]                     @ 0819B8AA
    lsls r0, r0, #4                          @ 0819B8AC
    ldr r1, .Lit_0819B8BC                    @ 0819B8AE
    adds r0, r0, r1                          @ 0819B8B0
    strh r4, [r0]                            @ 0819B8B2
    pop {r4, r5}                             @ 0819B8B4
    pop {r0}                                 @ 0819B8B6
    bx r0                                    @ 0819B8B8
    .hword 0x0000   @ 0819B8BA alignment
.Lit_0819B8BC: .word 0x03001B5A

@ ---------------------------------------------------------------------------
@ ds_NoteOn: vtable[0]/[1]: DirectSound note on
    .global ds_NoteOn
    .thumb_func
ds_NoteOn:
    push {r4, r5, r6, r7, lr}                @ 0819B8C0
    adds r6, r0, #0                          @ 0819B8C2
    ldrb r0, [r6, #0x12]                     @ 0819B8C4
    lsls r0, r0, #4                          @ 0819B8C6
    ldr r1, .Lit_0819B904                    @ 0819B8C8
    adds r4, r0, r1                          @ 0819B8CA
    movs r7, #0                              @ 0819B8CC
    strb r7, [r4]                            @ 0819B8CE
    ldrb r0, [r6, #0xc]                      @ 0819B8D0
    ldrb r1, [r6, #0xb]                      @ 0819B8D2
    bl inst_Lookup                           @ 0819B8D4
    adds r5, r0, #0                          @ 0819B8D8
    cmp r5, #0                               @ 0819B8DA
    beq .L_0819B8FE                          @ 0819B8DC
    adds r0, r6, #0                          @ 0819B8DE
    bl ds_SetPitch                           @ 0819B8E0
    ldrh r0, [r5, #2]                        @ 0819B8E4
    strh r0, [r4, #2]                        @ 0819B8E6
    ldrb r0, [r5, #4]                        @ 0819B8E8
    strb r0, [r4, #0xc]                      @ 0819B8EA
    ldrb r0, [r5, #5]                        @ 0819B8EC
    strb r0, [r4, #0xd]                      @ 0819B8EE
    ldrb r0, [r5, #6]                        @ 0819B8F0
    strb r0, [r4, #0xe]                      @ 0819B8F2
    ldrb r0, [r5, #7]                        @ 0819B8F4
    strb r0, [r4, #0xf]                      @ 0819B8F6
    str r7, [r4, #4]                         @ 0819B8F8
    movs r0, #0x80                           @ 0819B8FA
    strb r0, [r4]                            @ 0819B8FC
.L_0819B8FE:
    pop {r4, r5, r6, r7}                     @ 0819B8FE
    pop {r0}                                 @ 0819B900
    bx r0                                    @ 0819B902
.Lit_0819B904: .word 0x03001B50

@ ---------------------------------------------------------------------------
@ ds_SetVolume: vtable[2]/[3]: DirectSound volume + pan
    .global ds_SetVolume
    .thumb_func
ds_SetVolume:
    push {r4, r5, r6, r7, lr}                @ 0819B908
    adds r5, r0, #0                          @ 0819B90A
    ldrb r1, [r5, #0xe]                      @ 0819B90C
    movs r0, #0xe                            @ 0819B90E
    ldrsb r0, [r5, r0]                       @ 0819B910
    cmp r0, #0                               @ 0819B912
    blt .L_0819B91C                          @ 0819B914
    movs r7, #0x7f                           @ 0819B916
    ldrb r6, [r5, #0xe]                      @ 0819B918
    b .L_0819B926                            @ 0819B91A
.L_0819B91C:
    movs r0, #0xff                           @ 0819B91C
    subs r0, r0, r1                          @ 0819B91E
    lsls r0, r0, #0x18                       @ 0819B920
    lsrs r7, r0, #0x18                       @ 0819B922
    movs r6, #0x7f                           @ 0819B924
.L_0819B926:
    ldrb r4, [r5, #0xd]                      @ 0819B926
    ldrh r1, [r5]                            @ 0819B928
    movs r0, #0x80                           @ 0819B92A
    lsls r0, r0, #4                          @ 0819B92C
    ands r0, r1                              @ 0819B92E
    cmp r0, #0                               @ 0819B930
    beq .L_0819B94A                          @ 0819B932
    adds r0, r5, #0                          @ 0819B934
    bl trk_Lfo1Value                         @ 0819B936
    adds r4, r4, r0                          @ 0819B93A
    cmp r4, #0                               @ 0819B93C
    bge .L_0819B944                          @ 0819B93E
    movs r4, #0                              @ 0819B940
    b .L_0819B94A                            @ 0819B942
.L_0819B944:
    cmp r4, #0xff                            @ 0819B944
    ble .L_0819B94A                          @ 0819B946
    movs r4, #0xff                           @ 0819B948
.L_0819B94A:
    ldr r0, .Lit_0819B98C                    @ 0819B94A
    ldr r1, [r0]                             @ 0819B94C
    ldrb r0, [r5, #0x13]                     @ 0819B94E
    lsls r0, r0, #1                          @ 0819B950
    movs r2, #0x93                           @ 0819B952
    lsls r2, r2, #3                          @ 0819B954
    adds r1, r1, r2                          @ 0819B956
    adds r1, r1, r0                          @ 0819B958
    ldrh r0, [r1]                            @ 0819B95A
    lsrs r0, r0, #8                          @ 0819B95C
    adds r0, #1                              @ 0819B95E
    muls r0, r4, r0                          @ 0819B960
    asrs r4, r0, #8                          @ 0819B962
    adds r0, r4, #1                          @ 0819B964
    adds r1, r7, #0                          @ 0819B966
    muls r1, r0, r1                          @ 0819B968
    asrs r1, r1, #8                          @ 0819B96A
    adds r2, r6, #0                          @ 0819B96C
    muls r2, r0, r2                          @ 0819B96E
    asrs r2, r2, #8                          @ 0819B970
    ldr r3, .Lit_0819B990                    @ 0819B972
    ldrb r0, [r5, #0x12]                     @ 0819B974
    lsls r0, r0, #4                          @ 0819B976
    adds r0, r0, r3                          @ 0819B978
    strb r1, [r0, #8]                        @ 0819B97A
    ldrb r0, [r5, #0x12]                     @ 0819B97C
    lsls r0, r0, #4                          @ 0819B97E
    adds r0, r0, r3                          @ 0819B980
    strb r2, [r0, #9]                        @ 0819B982
    pop {r4, r5, r6, r7}                     @ 0819B984
    pop {r0}                                 @ 0819B986
    bx r0                                    @ 0819B988
    .hword 0x0000   @ 0819B98A alignment
.Lit_0819B98C: .word 0x03007FF0
.Lit_0819B990: .word 0x03001B50

@ ---------------------------------------------------------------------------
@ ds_NoteOff: vtable[5]: DirectSound release
    .global ds_NoteOff
    .thumb_func
ds_NoteOff:
    ldr r2, .Lit_0819B9A8                    @ 0819B994
    ldrb r1, [r0, #0x12]                     @ 0819B996
    lsls r1, r1, #4                          @ 0819B998
    adds r1, r1, r2                          @ 0819B99A
    ldrb r2, [r1]                            @ 0819B99C
    movs r0, #0x40                           @ 0819B99E
    orrs r0, r2                              @ 0819B9A0
    strb r0, [r1]                            @ 0819B9A2
    bx lr                                    @ 0819B9A4
    .hword 0x0000   @ 0819B9A6 alignment
.Lit_0819B9A8: .word 0x03001B50

@ ---------------------------------------------------------------------------
@ ds_Restore: vtable[6]: re-apply pitch and volume
    .global ds_Restore
    .thumb_func
ds_Restore:
    push {r4, lr}                            @ 0819B9AC
    adds r4, r0, #0                          @ 0819B9AE
    bl ds_SetPitch                           @ 0819B9B0
    adds r0, r4, #0                          @ 0819B9B4
    bl ds_SetVolume                          @ 0819B9B6
    pop {r4}                                 @ 0819B9BA
    pop {r0}                                 @ 0819B9BC
    bx r0                                    @ 0819B9BE

@ ---------------------------------------------------------------------------
@ inst_Lookup: (program, key) -> 8-byte key-split entry or NULL
    .global inst_Lookup
    .thumb_func
inst_Lookup:
    push {lr}                                @ 0819B9C0
    adds r3, r1, #0                          @ 0819B9C2
    ldr r2, .Lit_0819B9EC                    @ 0819B9C4
    lsls r1, r0, #1                          @ 0819B9C6
    adds r1, r1, r2                          @ 0819B9C8
    ldrh r1, [r1]                            @ 0819B9CA
    adds r1, r1, r2                          @ 0819B9CC
    adds r0, #1                              @ 0819B9CE
    lsls r0, r0, #1                          @ 0819B9D0
    adds r0, r0, r2                          @ 0819B9D2
    ldrh r0, [r0]                            @ 0819B9D4
    adds r2, r0, r2                          @ 0819B9D6
    cmp r1, r2                               @ 0819B9D8
    beq .L_0819B9F6                          @ 0819B9DA
.L_0819B9DC:
    ldrb r0, [r1]                            @ 0819B9DC
    cmp r0, r3                               @ 0819B9DE
    bgt .L_0819B9F0                          @ 0819B9E0
    ldrb r0, [r1, #1]                        @ 0819B9E2
    cmp r0, r3                               @ 0819B9E4
    blt .L_0819B9F0                          @ 0819B9E6
    adds r0, r1, #0                          @ 0819B9E8
    b .L_0819B9F8                            @ 0819B9EA
.Lit_0819B9EC: .word 0x0821E2AC
.L_0819B9F0:
    adds r1, #8                              @ 0819B9F0
    cmp r1, r2                               @ 0819B9F2
    bne .L_0819B9DC                          @ 0819B9F4
.L_0819B9F6:
    movs r0, #0                              @ 0819B9F6
.L_0819B9F8:
    pop {r1}                                 @ 0819B9F8
    bx r1                                    @ 0819B9FA

@ ---------------------------------------------------------------------------
@ psg_InitRegs: SOUNDCNT_L/X, PSG master volume, wave restart
    .global psg_InitRegs
    .thumb_func
psg_InitRegs:
    ldr r1, .Lit_0819BA2C                    @ 0819B9FC
    movs r0, #0x77                           @ 0819B9FE
    strb r0, [r1]                            @ 0819BA00
    adds r1, #4                              @ 0819BA02
    movs r0, #0x8f                           @ 0819BA04
    strb r0, [r1]                            @ 0819BA06
    ldr r2, .Lit_0819BA30                    @ 0819BA08
    ldrh r1, [r2]                            @ 0819BA0A
    ldr r0, .Lit_0819BA34                    @ 0819BA0C
    ands r0, r1                              @ 0819BA0E
    movs r1, #2                              @ 0819BA10
    orrs r0, r1                              @ 0819BA12
    strh r0, [r2]                            @ 0819BA14
    ldr r1, .Lit_0819BA38                    @ 0819BA16
    movs r0, #0x80                           @ 0819BA18
    strb r0, [r1]                            @ 0819BA1A
    ldr r0, .Lit_0819BA3C                    @ 0819BA1C
    ldr r0, [r0]                             @ 0819BA1E
    movs r1, #0x9f                           @ 0819BA20
    lsls r1, r1, #3                          @ 0819BA22
    adds r0, r0, r1                          @ 0819BA24
    movs r1, #0xff                           @ 0819BA26
    strb r1, [r0]                            @ 0819BA28
    bx lr                                    @ 0819BA2A
.Lit_0819BA2C: .word 0x04000080
.Lit_0819BA30: .word 0x04000082
.Lit_0819BA34: .word 0x0000FFFC
.Lit_0819BA38: .word 0x04000065
.Lit_0819BA3C: .word 0x03007FF0

@ ---------------------------------------------------------------------------
@ psg_KeyToFreq: 8.8 key -> GB frequency register value
    .global psg_KeyToFreq
    .thumb_func
psg_KeyToFreq:
    push {r4, lr}                            @ 0819BA40
    lsls r0, r0, #0x10                       @ 0819BA42
    lsrs r3, r0, #0x18                       @ 0819BA44
    movs r1, #0xff                           @ 0819BA46
    lsls r1, r1, #0x10                       @ 0819BA48
    ands r1, r0                              @ 0819BA4A
    lsrs r4, r1, #0x10                       @ 0819BA4C
    subs r3, #0x24                           @ 0819BA4E
    cmp r3, #0                               @ 0819BA50
    blt .L_0819BA80                          @ 0819BA52
    ldr r2, .Lit_0819BA7C                    @ 0819BA54
    lsls r0, r3, #1                          @ 0819BA56
    adds r0, r0, r2                          @ 0819BA58
    ldrh r1, [r0]                            @ 0819BA5A
    adds r0, r3, #1                          @ 0819BA5C
    lsls r0, r0, #1                          @ 0819BA5E
    adds r0, r0, r2                          @ 0819BA60
    ldrh r0, [r0]                            @ 0819BA62
    subs r0, r0, r1                          @ 0819BA64
    muls r0, r4, r0                          @ 0819BA66
    lsrs r0, r0, #8                          @ 0819BA68
    adds r1, r1, r0                          @ 0819BA6A
    movs r2, #0x80                           @ 0819BA6C
    lsls r2, r2, #4                          @ 0819BA6E
    adds r0, r2, #0                          @ 0819BA70
    subs r0, r0, r1                          @ 0819BA72
    lsls r0, r0, #0x10                       @ 0819BA74
    lsrs r0, r0, #0x10                       @ 0819BA76
    b .L_0819BA82                            @ 0819BA78
    .hword 0x0000   @ 0819BA7A alignment
.Lit_0819BA7C: .word 0x0821DA80
.L_0819BA80:
    movs r0, #0                              @ 0819BA80
.L_0819BA82:
    pop {r4}                                 @ 0819BA82
    pop {r1}                                 @ 0819BA84
    bx r1                                    @ 0819BA86

@ ---------------------------------------------------------------------------
@ noise_KeyToNr43: key -> noise NR43 byte
    .global noise_KeyToNr43
    .thumb_func
noise_KeyToNr43:
    push {lr}                                @ 0819BA88
    adds r1, r0, #0                          @ 0819BA8A
    cmp r1, #0x14                            @ 0819BA8C
    bgt .L_0819BA94                          @ 0819BA8E
    movs r0, #0xd7                           @ 0819BA90
    b .L_0819BAAA                            @ 0819BA92
.L_0819BA94:
    cmp r1, #0x50                            @ 0819BA94
    bgt .L_0819BAA8                          @ 0819BA96
    ldr r0, .Lit_0819BAA4                    @ 0819BA98
    subs r1, #0x15                           @ 0819BA9A
    adds r1, r1, r0                          @ 0819BA9C
    ldrb r0, [r1]                            @ 0819BA9E
    b .L_0819BAAA                            @ 0819BAA0
    .hword 0x0000   @ 0819BAA2 alignment
.Lit_0819BAA4: .word 0x0821DB4C
.L_0819BAA8:
    movs r0, #0                              @ 0819BAA8
.L_0819BAAA:
    pop {r1}                                 @ 0819BAAA
    bx r1                                    @ 0819BAAC
    .hword 0x0000   @ 0819BAAE alignment

@ ---------------------------------------------------------------------------
@ wave_Load: copy 16-byte wave pattern n into wave RAM
    .global wave_Load
    .thumb_func
wave_Load:
    lsls r0, r0, #4                          @ 0819BAB0
    ldr r1, .Lit_0819BB00                    @ 0819BAB2
    adds r0, r0, r1                          @ 0819BAB4
    ldr r3, .Lit_0819BB04                    @ 0819BAB6
    movs r1, #0xc0                           @ 0819BAB8
    strb r1, [r3]                            @ 0819BABA
    ldr r1, .Lit_0819BB08                    @ 0819BABC
    ldrh r2, [r0]                            @ 0819BABE
    strh r2, [r1]                            @ 0819BAC0
    adds r0, #2                              @ 0819BAC2
    adds r1, #2                              @ 0819BAC4
    ldrh r2, [r0]                            @ 0819BAC6
    strh r2, [r1]                            @ 0819BAC8
    adds r0, #2                              @ 0819BACA
    adds r1, #2                              @ 0819BACC
    ldrh r2, [r0]                            @ 0819BACE
    strh r2, [r1]                            @ 0819BAD0
    adds r0, #2                              @ 0819BAD2
    adds r1, #2                              @ 0819BAD4
    ldrh r2, [r0]                            @ 0819BAD6
    strh r2, [r1]                            @ 0819BAD8
    adds r0, #2                              @ 0819BADA
    adds r1, #2                              @ 0819BADC
    ldrh r2, [r0]                            @ 0819BADE
    strh r2, [r1]                            @ 0819BAE0
    adds r0, #2                              @ 0819BAE2
    adds r1, #2                              @ 0819BAE4
    ldrh r2, [r0]                            @ 0819BAE6
    strh r2, [r1]                            @ 0819BAE8
    adds r0, #2                              @ 0819BAEA
    adds r1, #2                              @ 0819BAEC
    ldrh r2, [r0]                            @ 0819BAEE
    strh r2, [r1]                            @ 0819BAF0
    adds r1, #2                              @ 0819BAF2
    ldrh r0, [r0, #2]                        @ 0819BAF4
    strh r0, [r1]                            @ 0819BAF6
    movs r0, #0x80                           @ 0819BAF8
    strb r0, [r3]                            @ 0819BAFA
    bx lr                                    @ 0819BAFC
    .hword 0x0000   @ 0819BAFE alignment
.Lit_0819BB00: .word 0x0821EC3E
.Lit_0819BB04: .word 0x04000070
.Lit_0819BB08: .word 0x04000090

@ ---------------------------------------------------------------------------
@ psg_SetPitch: vtable[4]: square/wave pitch
    .global psg_SetPitch
    .thumb_func
psg_SetPitch:
    push {r4, r5, lr}                        @ 0819BB0C
    adds r5, r0, #0                          @ 0819BB0E
    ldrb r0, [r5, #0xb]                      @ 0819BB10
    lsls r4, r0, #8                          @ 0819BB12
    movs r1, #0x10                           @ 0819BB14
    ldrsb r1, [r5, r1]                       @ 0819BB16
    ldrb r0, [r5, #0xf]                      @ 0819BB18
    muls r0, r1, r0                          @ 0819BB1A
    adds r0, r4, r0                          @ 0819BB1C
    lsls r0, r0, #0x10                       @ 0819BB1E
    lsrs r4, r0, #0x10                       @ 0819BB20
    movs r0, #0x11                           @ 0819BB22
    ldrsb r0, [r5, r0]                       @ 0819BB24
    adds r0, r4, r0                          @ 0819BB26
    lsls r0, r0, #0x10                       @ 0819BB28
    lsrs r4, r0, #0x10                       @ 0819BB2A
    ldrh r1, [r5]                            @ 0819BB2C
    movs r0, #0x80                           @ 0819BB2E
    lsls r0, r0, #1                          @ 0819BB30
    ands r0, r1                              @ 0819BB32
    cmp r0, #0                               @ 0819BB34
    beq .L_0819BB44                          @ 0819BB36
    adds r0, r5, #0                          @ 0819BB38
    bl trk_Lfo2Value                         @ 0819BB3A
    adds r0, r4, r0                          @ 0819BB3E
    lsls r0, r0, #0x10                       @ 0819BB40
    lsrs r4, r0, #0x10                       @ 0819BB42
.L_0819BB44:
    adds r0, r4, #0                          @ 0819BB44
    bl psg_KeyToFreq                         @ 0819BB46
    ldr r1, .Lit_0819BB6C                    @ 0819BB4A
    ldr r3, [r1]                             @ 0819BB4C
    ldrb r1, [r5, #0x12]                     @ 0819BB4E
    movs r2, #3                              @ 0819BB50
    ands r2, r1                              @ 0819BB52
    lsls r1, r2, #1                          @ 0819BB54
    adds r1, r1, r2                          @ 0819BB56
    lsls r1, r1, #2                          @ 0819BB58
    adds r3, r3, r1                          @ 0819BB5A
    movs r1, #0x9a                           @ 0819BB5C
    lsls r1, r1, #3                          @ 0819BB5E
    adds r3, r3, r1                          @ 0819BB60
    strh r0, [r3]                            @ 0819BB62
    pop {r4, r5}                             @ 0819BB64
    pop {r0}                                 @ 0819BB66
    bx r0                                    @ 0819BB68
    .hword 0x0000   @ 0819BB6A alignment
.Lit_0819BB6C: .word 0x03007FF0

@ ---------------------------------------------------------------------------
@ noise_SetPitch: vtable[4]: noise pitch
    .global noise_SetPitch
    .thumb_func
noise_SetPitch:
    push {lr}                                @ 0819BB70
    ldrb r0, [r0, #0xb]                      @ 0819BB72
    bl noise_KeyToNr43                       @ 0819BB74
    ldr r1, .Lit_0819BB8C                    @ 0819BB78
    ldr r1, [r1]                             @ 0819BB7A
    lsls r0, r0, #0x18                       @ 0819BB7C
    lsrs r0, r0, #0x18                       @ 0819BB7E
    ldr r2, .Lit_0819BB90                    @ 0819BB80
    adds r1, r1, r2                          @ 0819BB82
    strh r0, [r1]                            @ 0819BB84
    pop {r0}                                 @ 0819BB86
    bx r0                                    @ 0819BB88
    .hword 0x0000   @ 0819BB8A alignment
.Lit_0819BB8C: .word 0x03007FF0
.Lit_0819BB90: .word 0x000004F4

@ ---------------------------------------------------------------------------
@ psg_NoteOff: vtable[5]: PSG envelope -> release state
    .global psg_NoteOff
    .thumb_func
psg_NoteOff:
    ldr r1, .Lit_0819BBB0                    @ 0819BB94
    ldr r2, [r1]                             @ 0819BB96
    ldrb r0, [r0, #0x12]                     @ 0819BB98
    movs r1, #3                              @ 0819BB9A
    ands r1, r0                              @ 0819BB9C
    lsls r0, r1, #1                          @ 0819BB9E
    adds r0, r0, r1                          @ 0819BBA0
    lsls r0, r0, #2                          @ 0819BBA2
    adds r2, r2, r0                          @ 0819BBA4
    ldr r0, .Lit_0819BBB4                    @ 0819BBA6
    adds r2, r2, r0                          @ 0819BBA8
    movs r0, #5                              @ 0819BBAA
    strb r0, [r2]                            @ 0819BBAC
    bx lr                                    @ 0819BBAE
.Lit_0819BBB0: .word 0x03007FF0
.Lit_0819BBB4: .word 0x000004CF

@ ---------------------------------------------------------------------------
@ psg_NoteOn: vtable[0]/[1]: square/noise note on
    .global psg_NoteOn
    .thumb_func
psg_NoteOn:
    push {r4, lr}                            @ 0819BBB8
    adds r4, r0, #0                          @ 0819BBBA
    ldrb r0, [r4, #0xc]                      @ 0819BBBC
    ldrb r1, [r4, #0xb]                      @ 0819BBBE
    bl inst_Lookup                           @ 0819BBC0
    adds r3, r0, #0                          @ 0819BBC4
    cmp r3, #0                               @ 0819BBC6
    beq .L_0819BBFA                          @ 0819BBC8
    ldr r2, .Lit_0819BC00                    @ 0819BBCA
    ldrb r0, [r4, #0x12]                     @ 0819BBCC
    movs r1, #3                              @ 0819BBCE
    ands r1, r0                              @ 0819BBD0
    lsls r0, r1, #1                          @ 0819BBD2
    adds r0, r0, r1                          @ 0819BBD4
    lsls r0, r0, #2                          @ 0819BBD6
    movs r1, #0x99                           @ 0819BBD8
    lsls r1, r1, #3                          @ 0819BBDA
    adds r0, r0, r1                          @ 0819BBDC
    ldr r1, [r2]                             @ 0819BBDE
    adds r1, r1, r0                          @ 0819BBE0
    ldrb r0, [r3, #4]                        @ 0819BBE2
    strb r0, [r1]                            @ 0819BBE4
    ldrb r0, [r3, #5]                        @ 0819BBE6
    strb r0, [r1, #1]                        @ 0819BBE8
    ldrb r0, [r3, #6]                        @ 0819BBEA
    strb r0, [r1, #2]                        @ 0819BBEC
    ldrb r0, [r3, #7]                        @ 0819BBEE
    strb r0, [r1, #3]                        @ 0819BBF0
    ldrh r0, [r3, #2]                        @ 0819BBF2
    strb r0, [r1, #6]                        @ 0819BBF4
    movs r0, #1                              @ 0819BBF6
    strb r0, [r1, #7]                        @ 0819BBF8
.L_0819BBFA:
    pop {r4}                                 @ 0819BBFA
    pop {r0}                                 @ 0819BBFC
    bx r0                                    @ 0819BBFE
.Lit_0819BC00: .word 0x03007FF0

@ ---------------------------------------------------------------------------
@ wave_NoteOn: vtable[0]/[1]: wave channel note on
    .global wave_NoteOn
    .thumb_func
wave_NoteOn:
    push {r4, lr}                            @ 0819BC04
    ldrb r2, [r0, #0xc]                      @ 0819BC06
    ldrb r1, [r0, #0xb]                      @ 0819BC08
    adds r0, r2, #0                          @ 0819BC0A
    bl inst_Lookup                           @ 0819BC0C
    adds r1, r0, #0                          @ 0819BC10
    cmp r1, #0                               @ 0819BC12
    beq .L_0819BC3E                          @ 0819BC14
    ldr r4, .Lit_0819BC44                    @ 0819BC16
    ldr r0, [r4]                             @ 0819BC18
    movs r3, #0x9f                           @ 0819BC1A
    lsls r3, r3, #3                          @ 0819BC1C
    adds r2, r0, r3                          @ 0819BC1E
    ldrh r1, [r1, #2]                        @ 0819BC20
    ldrb r0, [r2]                            @ 0819BC22
    cmp r0, r1                               @ 0819BC24
    beq .L_0819BC34                          @ 0819BC26
    strb r1, [r2]                            @ 0819BC28
    ldr r0, [r4]                             @ 0819BC2A
    adds r0, r0, r3                          @ 0819BC2C
    ldrb r0, [r0]                            @ 0819BC2E
    bl wave_Load                             @ 0819BC30
.L_0819BC34:
    ldr r0, [r4]                             @ 0819BC34
    ldr r1, .Lit_0819BC48                    @ 0819BC36
    adds r0, r0, r1                          @ 0819BC38
    movs r1, #1                              @ 0819BC3A
    strb r1, [r0]                            @ 0819BC3C
.L_0819BC3E:
    pop {r4}                                 @ 0819BC3E
    pop {r0}                                 @ 0819BC40
    bx r0                                    @ 0819BC42
.Lit_0819BC44: .word 0x03007FF0
.Lit_0819BC48: .word 0x000004E7

@ ---------------------------------------------------------------------------
@ psg_SetPan: vtable[3]: PSG pan via SOUNDCNT_L enables
    .global psg_SetPan
    .thumb_func
psg_SetPan:
    push {r4, r5, r6, lr}                    @ 0819BC4C
    ldrb r1, [r0, #0x12]                     @ 0819BC4E
    movs r2, #3                              @ 0819BC50
    ands r2, r1                              @ 0819BC52
    movs r1, #0x80                           @ 0819BC54
    lsls r1, r1, #0x11                       @ 0819BC56
    lsls r1, r2                              @ 0819BC58
    lsrs r3, r1, #0x18                       @ 0819BC5A
    ldr r5, .Lit_0819BC88                    @ 0819BC5C
    ldrb r2, [r5]                            @ 0819BC5E
    lsls r4, r3, #4                          @ 0819BC60
    adds r1, r3, #0                          @ 0819BC62
    orrs r1, r4                              @ 0819BC64
    adds r6, r2, #0                          @ 0819BC66
    bics r6, r1                              @ 0819BC68
    adds r1, r6, #0                          @ 0819BC6A
    ldrb r0, [r0, #0xe]                      @ 0819BC6C
    cmp r0, #0x80                            @ 0819BC6E
    bhi .L_0819BC74                          @ 0819BC70
    orrs r1, r3                              @ 0819BC72
.L_0819BC74:
    cmp r0, #0x7e                            @ 0819BC74
    bls .L_0819BC7E                          @ 0819BC76
    orrs r1, r4                              @ 0819BC78
    lsls r0, r1, #0x18                       @ 0819BC7A
    lsrs r1, r0, #0x18                       @ 0819BC7C
.L_0819BC7E:
    strb r1, [r5]                            @ 0819BC7E
    pop {r4, r5, r6}                         @ 0819BC80
    pop {r0}                                 @ 0819BC82
    bx r0                                    @ 0819BC84
    .hword 0x0000   @ 0819BC86 alignment
.Lit_0819BC88: .word 0x04000081

@ ---------------------------------------------------------------------------
@ psg_SetVolume: vtable[2]: PSG volume (0-15)
    .global psg_SetVolume
    .thumb_func
psg_SetVolume:
    push {r4, lr}                            @ 0819BC8C
    ldr r1, .Lit_0819BCC4                    @ 0819BC8E
    ldr r3, [r1]                             @ 0819BC90
    ldrb r2, [r0, #0x12]                     @ 0819BC92
    movs r1, #3                              @ 0819BC94
    ands r1, r2                              @ 0819BC96
    lsls r2, r1, #1                          @ 0819BC98
    adds r2, r2, r1                          @ 0819BC9A
    lsls r2, r2, #2                          @ 0819BC9C
    adds r2, r3, r2                          @ 0819BC9E
    ldrb r1, [r0, #0x13]                     @ 0819BCA0
    lsls r1, r1, #1                          @ 0819BCA2
    movs r4, #0x93                           @ 0819BCA4
    lsls r4, r4, #3                          @ 0819BCA6
    adds r3, r3, r4                          @ 0819BCA8
    adds r3, r3, r1                          @ 0819BCAA
    ldrh r1, [r3]                            @ 0819BCAC
    lsrs r1, r1, #8                          @ 0819BCAE
    adds r1, #1                              @ 0819BCB0
    ldrb r0, [r0, #0xd]                      @ 0819BCB2
    muls r0, r1, r0                          @ 0819BCB4
    asrs r0, r0, #0xc                        @ 0819BCB6
    ldr r1, .Lit_0819BCC8                    @ 0819BCB8
    adds r2, r2, r1                          @ 0819BCBA
    strb r0, [r2]                            @ 0819BCBC
    pop {r4}                                 @ 0819BCBE
    pop {r0}                                 @ 0819BCC0
    bx r0                                    @ 0819BCC2
.Lit_0819BCC4: .word 0x03007FF0
.Lit_0819BCC8: .word 0x000004CC

@ ---------------------------------------------------------------------------
@ psg_Restore: vtable[6]: re-apply PSG pitch, volume, pan
    .global psg_Restore
    .thumb_func
psg_Restore:
    push {r4, lr}                            @ 0819BCCC
    adds r4, r0, #0                          @ 0819BCCE
    bl psg_SetPitch                          @ 0819BCD0
    adds r0, r4, #0                          @ 0819BCD4
    bl psg_SetVolume                         @ 0819BCD6
    adds r0, r4, #0                          @ 0819BCDA
    bl psg_SetPan                            @ 0819BCDC
    pop {r4}                                 @ 0819BCE0
    pop {r0}                                 @ 0819BCE2
    bx r0                                    @ 0819BCE4
    .hword 0x0000   @ 0819BCE6 alignment

@ ---------------------------------------------------------------------------
@ psg_CurrentVolume: estimate current hardware envelope volume
    .global psg_CurrentVolume
    .thumb_func
psg_CurrentVolume:
    push {r4, lr}                            @ 0819BCE8
    ldr r1, .Lit_0819BD0C                    @ 0819BCEA
    ldr r2, [r1]                             @ 0819BCEC
    lsls r1, r0, #1                          @ 0819BCEE
    adds r1, r1, r0                          @ 0819BCF0
    lsls r1, r1, #2                          @ 0819BCF2
    adds r2, r2, r1                          @ 0819BCF4
    ldr r1, .Lit_0819BD10                    @ 0819BCF6
    adds r0, r2, r1                          @ 0819BCF8
    ldrb r3, [r0]                            @ 0819BCFA
    lsrs r4, r3, #4                          @ 0819BCFC
    movs r0, #0xf                            @ 0819BCFE
    ands r0, r3                              @ 0819BD00
    cmp r0, #0                               @ 0819BD02
    bne .L_0819BD14                          @ 0819BD04
    adds r0, r4, #0                          @ 0819BD06
    b .L_0819BD4E                            @ 0819BD08
    .hword 0x0000   @ 0819BD0A alignment
.Lit_0819BD0C: .word 0x03007FF0
.Lit_0819BD10: .word 0x000004D2
.L_0819BD14:
    movs r1, #7                              @ 0819BD14
    ands r1, r3                              @ 0819BD16
    movs r0, #8                              @ 0819BD18
    ands r3, r0                              @ 0819BD1A
    cmp r3, #0                               @ 0819BD1C
    beq .L_0819BD38                          @ 0819BD1E
    ldr r3, .Lit_0819BD34                    @ 0819BD20
    adds r0, r2, r3                          @ 0819BD22
    ldrb r0, [r0]                            @ 0819BD24
    bl __divsi3                              @ 0819BD26
    adds r4, r4, r0                          @ 0819BD2A
    cmp r4, #0xf                             @ 0819BD2C
    ble .L_0819BD4A                          @ 0819BD2E
    movs r4, #0xf                            @ 0819BD30
    b .L_0819BD4A                            @ 0819BD32
.Lit_0819BD34: .word 0x000004CD
.L_0819BD38:
    ldr r3, .Lit_0819BD54                    @ 0819BD38
    adds r0, r2, r3                          @ 0819BD3A
    ldrb r0, [r0]                            @ 0819BD3C
    bl __divsi3                              @ 0819BD3E
    subs r4, r4, r0                          @ 0819BD42
    cmp r4, #0                               @ 0819BD44
    bge .L_0819BD4A                          @ 0819BD46
    movs r4, #0                              @ 0819BD48
.L_0819BD4A:
    lsls r0, r4, #0x18                       @ 0819BD4A
    lsrs r0, r0, #0x18                       @ 0819BD4C
.L_0819BD4E:
    pop {r4}                                 @ 0819BD4E
    pop {r1}                                 @ 0819BD50
    bx r1                                    @ 0819BD52
.Lit_0819BD54: .word 0x000004CD

@ ---------------------------------------------------------------------------
@ psg_UpdateEnvelope: per-frame software ADSR for PSG channel n
    .global psg_UpdateEnvelope
    .thumb_func
psg_UpdateEnvelope:
    push {r4, r5, r6, r7, lr}                @ 0819BD58
    mov r7, r8                               @ 0819BD5A
    push {r7}                                @ 0819BD5C
    sub sp, #0x30                            @ 0819BD5E
    adds r6, r0, #0                          @ 0819BD60
    mov r1, sp                               @ 0819BD62
    ldr r0, .Lit_0819BDC4                    @ 0819BD64
    ldm r0!, {r2, r3, r4}                    @ 0819BD66
    stm r1!, {r2, r3, r4}                    @ 0819BD68
    ldr r0, [r0]                             @ 0819BD6A
    str r0, [r1]                             @ 0819BD6C
    add r3, sp, #0x10                        @ 0819BD6E
    adds r1, r3, #0                          @ 0819BD70
    ldr r0, .Lit_0819BDC8                    @ 0819BD72
    ldm r0!, {r2, r5, r7}                    @ 0819BD74
    stm r1!, {r2, r5, r7}                    @ 0819BD76
    ldr r0, [r0]                             @ 0819BD78
    str r0, [r1]                             @ 0819BD7A
    add r2, sp, #0x20                        @ 0819BD7C
    adds r1, r2, #0                          @ 0819BD7E
    ldr r0, .Lit_0819BDCC                    @ 0819BD80
    ldm r0!, {r4, r5, r7}                    @ 0819BD82
    stm r1!, {r4, r5, r7}                    @ 0819BD84
    ldr r0, [r0]                             @ 0819BD86
    str r0, [r1]                             @ 0819BD88
    ldr r1, .Lit_0819BDD0                    @ 0819BD8A
    lsls r0, r6, #1                          @ 0819BD8C
    adds r0, r0, r6                          @ 0819BD8E
    lsls r0, r0, #2                          @ 0819BD90
    movs r4, #0x99                           @ 0819BD92
    lsls r4, r4, #3                          @ 0819BD94
    adds r0, r0, r4                          @ 0819BD96
    ldr r1, [r1]                             @ 0819BD98
    adds r5, r1, r0                          @ 0819BD9A
    ldrb r0, [r5, #0xa]                      @ 0819BD9C
    adds r7, r3, #0                          @ 0819BD9E
    mov r8, r2                               @ 0819BDA0
    cmp r0, #0                               @ 0819BDA2
    beq .L_0819BDB2                          @ 0819BDA4
    ldrb r1, [r5, #5]                        @ 0819BDA6
    adds r0, r1, #0                          @ 0819BDA8
    cmp r0, #0xff                            @ 0819BDAA
    beq .L_0819BDB2                          @ 0819BDAC
    adds r0, r1, #1                          @ 0819BDAE
    strb r0, [r5, #5]                        @ 0819BDB0
.L_0819BDB2:
    ldrb r0, [r5, #7]                        @ 0819BDB2
    cmp r0, #6                               @ 0819BDB4
    bls .L_0819BDBA                          @ 0819BDB6
    b .L_0819BFE0                            @ 0819BDB8
.L_0819BDBA:
    lsls r0, r0, #2                          @ 0819BDBA
    ldr r1, .Lit_0819BDD4                    @ 0819BDBC
    adds r0, r0, r1                          @ 0819BDBE
    ldr r0, [r0]                             @ 0819BDC0
    mov pc, r0                               @ 0819BDC2
.Lit_0819BDC4: .word 0x0821DBF8
.Lit_0819BDC8: .word 0x0821DC08
.Lit_0819BDCC: .word 0x0821DC18
.Lit_0819BDD0: .word 0x03007FF0
.Lit_0819BDD4: .word psg_EnvStateTable

    .align 2, 0
psg_EnvStateTable:
    .word .L_0819BFE0   @ state 0
    .word .L_0819BDF4   @ state 1
    .word .L_0819BE50   @ state 2
    .word .L_0819BED8   @ state 3
    .word .L_0819BFB2   @ state 4
    .word .L_0819BF40   @ state 5
    .word .L_0819BFA4   @ state 6
.L_0819BDF4:
    ldrb r0, [r5, #7]                        @ 0819BDF4
    adds r0, #1                              @ 0819BDF6
    strb r0, [r5, #7]                        @ 0819BDF8
    ldrb r0, [r5]                            @ 0819BDFA
    cmp r0, #0xff                            @ 0819BDFC
    beq .L_0819BE80                          @ 0819BDFE
    movs r0, #0                              @ 0819BE00
    strb r0, [r5, #5]                        @ 0819BE02
    lsls r2, r6, #2                          @ 0819BE04
    adds r0, r7, r2                          @ 0819BE06
    ldr r3, [r0]                             @ 0819BE08
    ldrb r1, [r5]                            @ 0819BE0A
    movs r0, #0xff                           @ 0819BE0C
    subs r0, r0, r1                          @ 0819BE0E
    asrs r0, r0, #5                          @ 0819BE10
    movs r1, #8                              @ 0819BE12
    orrs r0, r1                              @ 0819BE14
    strb r0, [r5, #0xa]                      @ 0819BE16
    movs r1, #0xff                           @ 0819BE18
    ands r0, r1                              @ 0819BE1A
    strb r0, [r3]                            @ 0819BE1C
    mov r7, sp                               @ 0819BE1E
    adds r0, r7, r2                          @ 0819BE20
    ldr r3, [r0]                             @ 0819BE22
    ldr r0, .Lit_0819BE4C                    @ 0819BE24
    ldr r0, [r0]                             @ 0819BE26
    movs r1, #0x9a                           @ 0819BE28
    lsls r1, r1, #3                          @ 0819BE2A
    adds r0, r0, r1                          @ 0819BE2C
    ldrh r0, [r0]                            @ 0819BE2E
    movs r4, #0x80                           @ 0819BE30
    lsls r4, r4, #8                          @ 0819BE32
    adds r1, r4, #0                          @ 0819BE34
    orrs r0, r1                              @ 0819BE36
    strh r0, [r3]                            @ 0819BE38
    add r2, r8                               @ 0819BE3A
    ldr r2, [r2]                             @ 0819BE3C
    cmp r2, #0                               @ 0819BE3E
    bne .L_0819BE44                          @ 0819BE40
    b .L_0819BFE0                            @ 0819BE42
.L_0819BE44:
    ldrb r0, [r5, #6]                        @ 0819BE44
    lsls r0, r0, #6                          @ 0819BE46
    strb r0, [r2]                            @ 0819BE48
    b .L_0819BFE0                            @ 0819BE4A
.Lit_0819BE4C: .word 0x03007FF0
.L_0819BE50:
    adds r0, r6, #0                          @ 0819BE50
    bl psg_CurrentVolume                     @ 0819BE52
    lsls r0, r0, #0x18                       @ 0819BE56
    lsrs r4, r0, #0x18                       @ 0819BE58
    ldrb r0, [r5, #4]                        @ 0819BE5A
    cmp r4, r0                               @ 0819BE5C
    bhs .L_0819BE80                          @ 0819BE5E
    lsls r0, r6, #2                          @ 0819BE60
    add r0, sp                               @ 0819BE62
    ldr r2, [r0]                             @ 0819BE64
    ldr r0, .Lit_0819BE7C                    @ 0819BE66
    ldr r1, [r0]                             @ 0819BE68
    lsls r0, r6, #1                          @ 0819BE6A
    adds r0, r0, r6                          @ 0819BE6C
    lsls r0, r0, #2                          @ 0819BE6E
    adds r1, r1, r0                          @ 0819BE70
    movs r3, #0x9a                           @ 0819BE72
    lsls r3, r3, #3                          @ 0819BE74
    adds r1, r1, r3                          @ 0819BE76
    b .L_0819BFCA                            @ 0819BE78
    .hword 0x0000   @ 0819BE7A alignment
.Lit_0819BE7C: .word 0x03007FF0
.L_0819BE80:
    movs r0, #0                              @ 0819BE80
    strb r0, [r5, #5]                        @ 0819BE82
    lsls r2, r6, #2                          @ 0819BE84
    adds r0, r7, r2                          @ 0819BE86
    ldr r3, [r0]                             @ 0819BE88
    ldrb r0, [r5, #1]                        @ 0819BE8A
    movs r1, #0xff                           @ 0819BE8C
    subs r1, r1, r0                          @ 0819BE8E
    asrs r1, r1, #5                          @ 0819BE90
    ldrb r0, [r5, #4]                        @ 0819BE92
    lsls r0, r0, #4                          @ 0819BE94
    orrs r1, r0                              @ 0819BE96
    strb r1, [r5, #0xa]                      @ 0819BE98
    movs r0, #0xff                           @ 0819BE9A
    ands r1, r0                              @ 0819BE9C
    strb r1, [r3]                            @ 0819BE9E
    mov r4, sp                               @ 0819BEA0
    adds r0, r4, r2                          @ 0819BEA2
    ldr r3, [r0]                             @ 0819BEA4
    ldr r0, .Lit_0819BED4                    @ 0819BEA6
    ldr r1, [r0]                             @ 0819BEA8
    lsls r0, r6, #1                          @ 0819BEAA
    adds r0, r0, r6                          @ 0819BEAC
    lsls r0, r0, #2                          @ 0819BEAE
    adds r1, r1, r0                          @ 0819BEB0
    movs r7, #0x9a                           @ 0819BEB2
    lsls r7, r7, #3                          @ 0819BEB4
    adds r1, r1, r7                          @ 0819BEB6
    ldrh r0, [r1]                            @ 0819BEB8
    movs r4, #0x80                           @ 0819BEBA
    lsls r4, r4, #8                          @ 0819BEBC
    adds r1, r4, #0                          @ 0819BEBE
    orrs r0, r1                              @ 0819BEC0
    strh r0, [r3]                            @ 0819BEC2
    add r2, r8                               @ 0819BEC4
    ldr r2, [r2]                             @ 0819BEC6
    cmp r2, #0                               @ 0819BEC8
    beq .L_0819BF98                          @ 0819BECA
    ldrb r0, [r5, #6]                        @ 0819BECC
    lsls r0, r0, #6                          @ 0819BECE
    strb r0, [r2]                            @ 0819BED0
    b .L_0819BF98                            @ 0819BED2
.Lit_0819BED4: .word 0x03007FF0
.L_0819BED8:
    adds r0, r6, #0                          @ 0819BED8
    bl psg_CurrentVolume                     @ 0819BEDA
    lsls r0, r0, #0x18                       @ 0819BEDE
    lsrs r4, r0, #0x18                       @ 0819BEE0
    ldrb r1, [r5, #4]                        @ 0819BEE2
    ldrb r0, [r5, #2]                        @ 0819BEE4
    muls r0, r1, r0                          @ 0819BEE6
    lsrs r1, r0, #8                          @ 0819BEE8
    cmp r4, r1                               @ 0819BEEA
    bls .L_0819BF0C                          @ 0819BEEC
    lsls r0, r6, #2                          @ 0819BEEE
    add r0, sp                               @ 0819BEF0
    ldr r2, [r0]                             @ 0819BEF2
    ldr r0, .Lit_0819BF08                    @ 0819BEF4
    ldr r1, [r0]                             @ 0819BEF6
    lsls r0, r6, #1                          @ 0819BEF8
    adds r0, r0, r6                          @ 0819BEFA
    lsls r0, r0, #2                          @ 0819BEFC
    adds r1, r1, r0                          @ 0819BEFE
    movs r5, #0x9a                           @ 0819BF00
    lsls r5, r5, #3                          @ 0819BF02
    adds r1, r1, r5                          @ 0819BF04
    b .L_0819BFCA                            @ 0819BF06
.Lit_0819BF08: .word 0x03007FF0
.L_0819BF0C:
    movs r0, #0                              @ 0819BF0C
    strb r0, [r5, #5]                        @ 0819BF0E
    lsls r3, r6, #2                          @ 0819BF10
    adds r0, r7, r3                          @ 0819BF12
    ldr r2, [r0]                             @ 0819BF14
    lsls r0, r1, #4                          @ 0819BF16
    strb r0, [r5, #0xa]                      @ 0819BF18
    movs r1, #0xff                           @ 0819BF1A
    ands r0, r1                              @ 0819BF1C
    strb r0, [r2]                            @ 0819BF1E
    mov r7, sp                               @ 0819BF20
    adds r0, r7, r3                          @ 0819BF22
    ldr r2, [r0]                             @ 0819BF24
    ldr r0, .Lit_0819BF3C                    @ 0819BF26
    ldr r1, [r0]                             @ 0819BF28
    lsls r0, r6, #1                          @ 0819BF2A
    adds r0, r0, r6                          @ 0819BF2C
    lsls r0, r0, #2                          @ 0819BF2E
    adds r1, r1, r0                          @ 0819BF30
    movs r0, #0x9a                           @ 0819BF32
    lsls r0, r0, #3                          @ 0819BF34
    adds r1, r1, r0                          @ 0819BF36
    ldrh r0, [r1]                            @ 0819BF38
    b .L_0819BF8E                            @ 0819BF3A
.Lit_0819BF3C: .word 0x03007FF0
.L_0819BF40:
    adds r0, r6, #0                          @ 0819BF40
    bl psg_CurrentVolume                     @ 0819BF42
    lsls r0, r0, #0x18                       @ 0819BF46
    lsrs r4, r0, #0x18                       @ 0819BF48
    movs r2, #0                              @ 0819BF4A
    strb r2, [r5, #5]                        @ 0819BF4C
    ldrb r1, [r5, #3]                        @ 0819BF4E
    movs r0, #0xff                           @ 0819BF50
    subs r0, r0, r1                          @ 0819BF52
    asrs r1, r0, #5                          @ 0819BF54
    cmp r1, #0                               @ 0819BF56
    beq .L_0819BF5E                          @ 0819BF58
    cmp r4, #0                               @ 0819BF5A
    bne .L_0819BF6A                          @ 0819BF5C
.L_0819BF5E:
    lsls r0, r6, #2                          @ 0819BF5E
    adds r0, r7, r0                          @ 0819BF60
    ldr r0, [r0]                             @ 0819BF62
    strb r2, [r0]                            @ 0819BF64
    strb r2, [r5, #7]                        @ 0819BF66
    b .L_0819BFE0                            @ 0819BF68
.L_0819BF6A:
    lsls r2, r6, #2                          @ 0819BF6A
    adds r0, r7, r2                          @ 0819BF6C
    ldr r3, [r0]                             @ 0819BF6E
    lsls r0, r4, #4                          @ 0819BF70
    orrs r0, r1                              @ 0819BF72
    strb r0, [r5, #0xa]                      @ 0819BF74
    movs r1, #0xff                           @ 0819BF76
    ands r0, r1                              @ 0819BF78
    strb r0, [r3]                            @ 0819BF7A
    mov r7, sp                               @ 0819BF7C
    adds r0, r7, r2                          @ 0819BF7E
    ldr r2, [r0]                             @ 0819BF80
    ldr r0, .Lit_0819BFA0                    @ 0819BF82
    ldr r0, [r0]                             @ 0819BF84
    movs r1, #0x9a                           @ 0819BF86
    lsls r1, r1, #3                          @ 0819BF88
    adds r0, r0, r1                          @ 0819BF8A
    ldrh r0, [r0]                            @ 0819BF8C
.L_0819BF8E:
    movs r3, #0x80                           @ 0819BF8E
    lsls r3, r3, #8                          @ 0819BF90
    adds r1, r3, #0                          @ 0819BF92
    orrs r0, r1                              @ 0819BF94
    strh r0, [r2]                            @ 0819BF96
.L_0819BF98:
    ldrb r0, [r5, #7]                        @ 0819BF98
    adds r0, #1                              @ 0819BF9A
    strb r0, [r5, #7]                        @ 0819BF9C
    b .L_0819BFE0                            @ 0819BF9E
.Lit_0819BFA0: .word 0x03007FF0
.L_0819BFA4:
    adds r0, r6, #0                          @ 0819BFA4
    bl psg_CurrentVolume                     @ 0819BFA6
    lsls r0, r0, #0x18                       @ 0819BFAA
    lsrs r4, r0, #0x18                       @ 0819BFAC
    cmp r4, #0                               @ 0819BFAE
    beq .L_0819BFD4                          @ 0819BFB0
.L_0819BFB2:
    lsls r0, r6, #2                          @ 0819BFB2
    add r0, sp                               @ 0819BFB4
    ldr r2, [r0]                             @ 0819BFB6
    ldr r0, .Lit_0819BFD0                    @ 0819BFB8
    ldr r1, [r0]                             @ 0819BFBA
    lsls r0, r6, #1                          @ 0819BFBC
    adds r0, r0, r6                          @ 0819BFBE
    lsls r0, r0, #2                          @ 0819BFC0
    adds r1, r1, r0                          @ 0819BFC2
    movs r4, #0x9a                           @ 0819BFC4
    lsls r4, r4, #3                          @ 0819BFC6
    adds r1, r1, r4                          @ 0819BFC8
.L_0819BFCA:
    ldrh r0, [r1]                            @ 0819BFCA
    strh r0, [r2]                            @ 0819BFCC
    b .L_0819BFE0                            @ 0819BFCE
.Lit_0819BFD0: .word 0x03007FF0
.L_0819BFD4:
    lsls r0, r6, #2                          @ 0819BFD4
    adds r0, r7, r0                          @ 0819BFD6
    ldr r0, [r0]                             @ 0819BFD8
    strb r4, [r5, #0xa]                      @ 0819BFDA
    strb r4, [r0]                            @ 0819BFDC
    strb r4, [r5, #7]                        @ 0819BFDE
.L_0819BFE0:
    add sp, #0x30                            @ 0819BFE0
    pop {r3}                                 @ 0819BFE2
    mov r8, r3                               @ 0819BFE4
    pop {r4, r5, r6, r7}                     @ 0819BFE6
    pop {r0}                                 @ 0819BFE8
    bx r0                                    @ 0819BFEA

@ ---------------------------------------------------------------------------
@ wave_Update: per-frame wave-channel state machine
    .global wave_Update
    .thumb_func
wave_Update:
    push {r4, lr}                            @ 0819BFEC
    ldr r0, .Lit_0819C00C                    @ 0819BFEE
    ldr r0, [r0]                             @ 0819BFF0
    movs r1, #0x9c                           @ 0819BFF2
    lsls r1, r1, #3                          @ 0819BFF4
    adds r3, r0, r1                          @ 0819BFF6
    ldrb r0, [r3, #7]                        @ 0819BFF8
    cmp r0, #1                               @ 0819BFFA
    beq .L_0819C010                          @ 0819BFFC
    cmp r0, #1                               @ 0819BFFE
    ble .L_0819C052                          @ 0819C000
    cmp r0, #2                               @ 0819C002
    beq .L_0819C03C                          @ 0819C004
    cmp r0, #5                               @ 0819C006
    beq .L_0819C048                          @ 0819C008
    b .L_0819C052                            @ 0819C00A
.Lit_0819C00C: .word 0x03007FF0
.L_0819C010:
    ldr r2, .Lit_0819C034                    @ 0819C010
    ldrh r0, [r3, #8]                        @ 0819C012
    movs r4, #0x80                           @ 0819C014
    lsls r4, r4, #8                          @ 0819C016
    adds r1, r4, #0                          @ 0819C018
    orrs r0, r1                              @ 0819C01A
    strh r0, [r2]                            @ 0819C01C
    subs r2, #2                              @ 0819C01E
    ldr r1, .Lit_0819C038                    @ 0819C020
    ldrb r0, [r3, #4]                        @ 0819C022
    lsrs r0, r0, #2                          @ 0819C024
    adds r0, r0, r1                          @ 0819C026
    ldrb r0, [r0]                            @ 0819C028
    lsls r0, r0, #8                          @ 0819C02A
    strh r0, [r2]                            @ 0819C02C
    ldrb r0, [r3, #7]                        @ 0819C02E
    adds r0, #1                              @ 0819C030
    b .L_0819C050                            @ 0819C032
.Lit_0819C034: .word 0x04000074
.Lit_0819C038: .word 0x0821DC28
.L_0819C03C:
    ldr r1, .Lit_0819C044                    @ 0819C03C
    ldrh r0, [r3, #8]                        @ 0819C03E
    strh r0, [r1]                            @ 0819C040
    b .L_0819C052                            @ 0819C042
.Lit_0819C044: .word 0x04000074
.L_0819C048:
    ldr r0, .Lit_0819C058                    @ 0819C048
    movs r1, #0                              @ 0819C04A
    strb r1, [r0]                            @ 0819C04C
    movs r0, #0                              @ 0819C04E
.L_0819C050:
    strb r0, [r3, #7]                        @ 0819C050
.L_0819C052:
    pop {r4}                                 @ 0819C052
    pop {r0}                                 @ 0819C054
    bx r0                                    @ 0819C056
.Lit_0819C058: .word 0x04000073

@ ---------------------------------------------------------------------------
@ psg_UpdateAll: per-frame PSG update (ch1, ch2, wave, noise)
    .global psg_UpdateAll
    .thumb_func
psg_UpdateAll:
    push {lr}                                @ 0819C05C
    movs r0, #0                              @ 0819C05E
    bl psg_UpdateEnvelope                    @ 0819C060
    movs r0, #1                              @ 0819C064
    bl psg_UpdateEnvelope                    @ 0819C066
    bl wave_Update                           @ 0819C06A
    movs r0, #3                              @ 0819C06E
    bl psg_UpdateEnvelope                    @ 0819C070
    pop {r0}                                 @ 0819C074
    bx r0                                    @ 0819C076

@ ---------------------------------------------------------------------------
@ snd_Nop: dummy vtable entry (muted tracks)
    .global snd_Nop
    .thumb_func
snd_Nop:
    bx lr                                    @ 0819C078
    .hword 0x0000   @ 0819C07A alignment

@ ---------------------------------------------------------------------------
@ snd_Init: set work area (0x03007FF0) and reset players
    .global snd_Init
    .thumb_func
snd_Init:
    push {r4, r5, r6, lr}                    @ 0819C07C
    ldr r4, .Lit_0819C100                    @ 0819C07E
    str r0, [r4]                             @ 0819C080
    bl psg_InitRegs                          @ 0819C082
    ldr r0, [r4]                             @ 0819C086
    ldr r1, .Lit_0819C104                    @ 0819C088
    adds r2, r0, r1                          @ 0819C08A
    movs r3, #0                              @ 0819C08C
    movs r1, #0                              @ 0819C08E
    strh r1, [r2]                            @ 0819C090
    movs r2, #0x92                           @ 0819C092
    lsls r2, r2, #3                          @ 0819C094
    adds r0, r0, r2                          @ 0819C096
    strh r1, [r0]                            @ 0819C098
    ldr r0, [r4]                             @ 0819C09A
    ldr r1, .Lit_0819C108                    @ 0819C09C
    adds r0, r0, r1                          @ 0819C09E
    movs r1, #1                              @ 0819C0A0
    strb r1, [r0]                            @ 0819C0A2
    ldr r0, [r4]                             @ 0819C0A4
    adds r2, #5                              @ 0819C0A6
    adds r0, r0, r2                          @ 0819C0A8
    strb r3, [r0]                            @ 0819C0AA
    ldr r0, [r4]                             @ 0819C0AC
    ldr r1, .Lit_0819C10C                    @ 0819C0AE
    adds r0, r0, r1                          @ 0819C0B0
    strb r3, [r0]                            @ 0819C0B2
    ldr r0, [r4]                             @ 0819C0B4
    adds r2, #0xf                            @ 0819C0B6
    adds r0, r0, r2                          @ 0819C0B8
    movs r1, #0x4b                           @ 0819C0BA
    str r1, [r0]                             @ 0819C0BC
    movs r3, #0                              @ 0819C0BE
    movs r6, #0                              @ 0819C0C0
.L_0819C0C2:
    ldr r0, [r4]                             @ 0819C0C2
    lsls r2, r3, #1                          @ 0819C0C4
    movs r1, #0x93                           @ 0819C0C6
    lsls r1, r1, #3                          @ 0819C0C8
    adds r0, r0, r1                          @ 0819C0CA
    adds r0, r0, r2                          @ 0819C0CC
    ldr r1, .Lit_0819C110                    @ 0819C0CE
    strh r1, [r0]                            @ 0819C0D0
    movs r1, #0                              @ 0819C0D2
    adds r5, r3, #1                          @ 0819C0D4
    adds r2, r2, r3                          @ 0819C0D6
    lsls r2, r2, #7                          @ 0819C0D8
.L_0819C0DA:
    ldr r0, [r4]                             @ 0819C0DA
    adds r0, r0, r2                          @ 0819C0DC
    strh r6, [r0]                            @ 0819C0DE
    ldr r0, [r4]                             @ 0819C0E0
    adds r0, r0, r2                          @ 0819C0E2
    strb r1, [r0, #0x12]                     @ 0819C0E4
    ldr r0, [r4]                             @ 0819C0E6
    adds r0, r0, r2                          @ 0819C0E8
    strb r3, [r0, #0x13]                     @ 0819C0EA
    adds r2, #0x20                           @ 0819C0EC
    adds r1, #1                              @ 0819C0EE
    cmp r1, #0xb                             @ 0819C0F0
    ble .L_0819C0DA                          @ 0819C0F2
    adds r3, r5, #0                          @ 0819C0F4
    cmp r3, #2                               @ 0819C0F6
    ble .L_0819C0C2                          @ 0819C0F8
    pop {r4, r5, r6}                         @ 0819C0FA
    pop {r0}                                 @ 0819C0FC
    bx r0                                    @ 0819C0FE
.Lit_0819C100: .word 0x03007FF0
.Lit_0819C104: .word 0x00000492
.Lit_0819C108: .word 0x00000494
.Lit_0819C10C: .word 0x00000496
.Lit_0819C110: .word 0x0000FFFF

@ ---------------------------------------------------------------------------
@ trk_Init: reset a track to defaults and point it at its data
    .global trk_Init
    .thumb_func
trk_Init:
    push {r4, lr}                            @ 0819C114
    movs r3, #0                              @ 0819C116
    movs r4, #0                              @ 0819C118
    movs r2, #0x83                           @ 0819C11A
    strh r2, [r0]                            @ 0819C11C
    str r1, [r0, #4]                         @ 0819C11E
    strh r4, [r0, #8]                        @ 0819C120
    movs r1, #0x78                           @ 0819C122
    strb r1, [r0, #2]                        @ 0819C124
    strb r3, [r0, #3]                        @ 0819C126
    strb r3, [r0, #0xc]                      @ 0819C128
    movs r1, #0x7f                           @ 0819C12A
    strb r1, [r0, #0xe]                      @ 0819C12C
    movs r1, #1                              @ 0819C12E
    strb r1, [r0, #0xa]                      @ 0819C130
    movs r1, #0xc8                           @ 0819C132
    strb r1, [r0, #0xd]                      @ 0819C134
    strb r3, [r0, #0x10]                     @ 0819C136
    movs r1, #2                              @ 0819C138
    strb r1, [r0, #0xf]                      @ 0819C13A
    strb r3, [r0, #0x11]                     @ 0819C13C
    pop {r4}                                 @ 0819C13E
    pop {r0}                                 @ 0819C140
    bx r0                                    @ 0819C142

@ ---------------------------------------------------------------------------
@ trk_Stop: release the track note
    .global trk_Stop
    .thumb_func
trk_Stop:
    push {r4, lr}                            @ 0819C144
    adds r4, r1, #0                          @ 0819C146
    ldrh r1, [r4]                            @ 0819C148
    movs r0, #2                              @ 0819C14A
    ands r0, r1                              @ 0819C14C
    cmp r0, #0                               @ 0819C14E
    bne .L_0819C174                          @ 0819C150
    movs r0, #0x80                           @ 0819C152
    ands r0, r1                              @ 0819C154
    cmp r0, #0                               @ 0819C156
    beq .L_0819C16C                          @ 0819C158
    ldr r1, .Lit_0819C17C                    @ 0819C15A
    ldrb r0, [r4, #0x12]                     @ 0819C15C
    lsls r0, r0, #2                          @ 0819C15E
    adds r0, r0, r1                          @ 0819C160
    ldr r0, [r0]                             @ 0819C162
    ldr r1, [r0, #0x14]                      @ 0819C164
    adds r0, r4, #0                          @ 0819C166
    bl _call_via_r1                          @ 0819C168
.L_0819C16C:
    ldrh r0, [r4]                            @ 0819C16C
    movs r1, #2                              @ 0819C16E
    orrs r0, r1                              @ 0819C170
    strh r0, [r4]                            @ 0819C172
.L_0819C174:
    pop {r4}                                 @ 0819C174
    pop {r0}                                 @ 0819C176
    bx r0                                    @ 0819C178
    .hword 0x0000   @ 0819C17A alignment
.Lit_0819C17C: .word 0x08A82058

@ ---------------------------------------------------------------------------
@ plr_Stop: stop all tracks of a player
    .global plr_Stop
    .thumb_func
plr_Stop:
    push {r4, r5, r6, lr}                    @ 0819C180
    adds r6, r0, #0                          @ 0819C182
    movs r5, #0                              @ 0819C184
    ldr r0, .Lit_0819C1C4                    @ 0819C186
    lsls r1, r6, #1                          @ 0819C188
    adds r1, r1, r6                          @ 0819C18A
    lsls r1, r1, #7                          @ 0819C18C
    ldr r0, [r0]                             @ 0819C18E
    adds r4, r0, r1                          @ 0819C190
.L_0819C192:
    ldrh r1, [r4]                            @ 0819C192
    movs r0, #1                              @ 0819C194
    ands r0, r1                              @ 0819C196
    cmp r0, #0                               @ 0819C198
    beq .L_0819C1A4                          @ 0819C19A
    adds r0, r5, #0                          @ 0819C19C
    adds r1, r4, #0                          @ 0819C19E
    bl trk_Stop                              @ 0819C1A0
.L_0819C1A4:
    adds r5, #1                              @ 0819C1A4
    adds r4, #0x20                           @ 0819C1A6
    cmp r5, #0xb                             @ 0819C1A8
    ble .L_0819C192                          @ 0819C1AA
    ldr r0, .Lit_0819C1C4                    @ 0819C1AC
    ldr r1, [r0]                             @ 0819C1AE
    ldr r0, .Lit_0819C1C8                    @ 0819C1B0
    adds r1, r1, r0                          @ 0819C1B2
    adds r1, r1, r6                          @ 0819C1B4
    ldrb r2, [r1]                            @ 0819C1B6
    movs r0, #0xfe                           @ 0819C1B8
    ands r0, r2                              @ 0819C1BA
    strb r0, [r1]                            @ 0819C1BC
    pop {r4, r5, r6}                         @ 0819C1BE
    pop {r0}                                 @ 0819C1C0
    bx r0                                    @ 0819C1C2
.Lit_0819C1C4: .word 0x03007FF0
.Lit_0819C1C8: .word 0x00000494

@ ---------------------------------------------------------------------------
@ plr_SetTempoDiv: player tempo divisor (default 75)
    .global plr_SetTempoDiv
    .thumb_func
plr_SetTempoDiv:
    ldr r2, .Lit_0819C1DC                    @ 0819C1CC
    ldr r2, [r2]                             @ 0819C1CE
    lsls r0, r0, #2                          @ 0819C1D0
    ldr r3, .Lit_0819C1E0                    @ 0819C1D2
    adds r2, r2, r3                          @ 0819C1D4
    adds r2, r2, r0                          @ 0819C1D6
    str r1, [r2]                             @ 0819C1D8
    bx lr                                    @ 0819C1DA
.Lit_0819C1DC: .word 0x03007FF0
.Lit_0819C1E0: .word 0x000004A4

@ ---------------------------------------------------------------------------
@ plr_StartSong: start song n on player p
    .global plr_StartSong
    .thumb_func
plr_StartSong:
    push {r4, r5, r6, r7, lr}                @ 0819C1E4
    mov r7, r8                               @ 0819C1E6
    push {r7}                                @ 0819C1E8
    adds r4, r0, #0                          @ 0819C1EA
    adds r5, r1, #0                          @ 0819C1EC
    bl plr_Stop                              @ 0819C1EE
    adds r0, r4, #0                          @ 0819C1F2
    movs r1, #0x4b                           @ 0819C1F4
    bl plr_SetTempoDiv                       @ 0819C1F6
    ldr r6, .Lit_0819C24C                    @ 0819C1FA
    ldr r1, [r6]                             @ 0819C1FC
    ldr r3, .Lit_0819C250                    @ 0819C1FE
    adds r1, r1, r3                          @ 0819C200
    adds r1, r1, r4                          @ 0819C202
    ldrb r2, [r1]                            @ 0819C204
    movs r0, #1                              @ 0819C206
    orrs r0, r2                              @ 0819C208
    strb r0, [r1]                            @ 0819C20A
    ldr r1, [r6]                             @ 0819C20C
    adds r1, r1, r3                          @ 0819C20E
    adds r1, r1, r4                          @ 0819C210
    ldrb r2, [r1]                            @ 0819C212
    movs r0, #0xfd                           @ 0819C214
    ands r0, r2                              @ 0819C216
    strb r0, [r1]                            @ 0819C218
    ldr r0, .Lit_0819C254                    @ 0819C21A
    lsls r5, r5, #2                          @ 0819C21C
    adds r5, r5, r0                          @ 0819C21E
    ldr r5, [r5]                             @ 0819C220
    mov r8, r5                               @ 0819C222
    lsls r0, r4, #1                          @ 0819C224
    adds r0, r0, r4                          @ 0819C226
    lsls r0, r0, #7                          @ 0819C228
    ldr r1, [r6]                             @ 0819C22A
    adds r4, r1, r0                          @ 0819C22C
    ldrh r6, [r5]                            @ 0819C22E
    adds r5, #2                              @ 0819C230
    movs r7, #0xb                            @ 0819C232
.L_0819C234:
    movs r0, #1                              @ 0819C234
    ands r0, r6                              @ 0819C236
    cmp r0, #0                               @ 0819C238
    beq .L_0819C258                          @ 0819C23A
    ldrh r1, [r5]                            @ 0819C23C
    add r1, r8                               @ 0819C23E
    adds r5, #2                              @ 0819C240
    adds r0, r4, #0                          @ 0819C242
    bl trk_Init                              @ 0819C244
    b .L_0819C25A                            @ 0819C248
    .hword 0x0000   @ 0819C24A alignment
.Lit_0819C24C: .word 0x03007FF0
.Lit_0819C250: .word 0x00000494
.Lit_0819C254: .word 0x0821DC50
.L_0819C258:
    strh r0, [r4]                            @ 0819C258
.L_0819C25A:
    adds r4, #0x20                           @ 0819C25A
    lsrs r6, r6, #1                          @ 0819C25C
    subs r7, #1                              @ 0819C25E
    cmp r7, #0                               @ 0819C260
    bge .L_0819C234                          @ 0819C262
    pop {r3}                                 @ 0819C264
    mov r8, r3                               @ 0819C266
    pop {r4, r5, r6, r7}                     @ 0819C268
    pop {r0}                                 @ 0819C26A
    bx r0                                    @ 0819C26C
    .hword 0x0000   @ 0819C26E alignment

@ ---------------------------------------------------------------------------
@ plr_Resume: set player active bit
    .global plr_Resume
    .thumb_func
plr_Resume:
    ldr r1, .Lit_0819C284                    @ 0819C270
    ldr r1, [r1]                             @ 0819C272
    ldr r2, .Lit_0819C288                    @ 0819C274
    adds r1, r1, r2                          @ 0819C276
    adds r1, r1, r0                          @ 0819C278
    ldrb r2, [r1]                            @ 0819C27A
    movs r0, #1                              @ 0819C27C
    orrs r0, r2                              @ 0819C27E
    strb r0, [r1]                            @ 0819C280
    bx lr                                    @ 0819C282
.Lit_0819C284: .word 0x03007FF0
.Lit_0819C288: .word 0x00000494

@ ---------------------------------------------------------------------------
@ plr_SetVolume: player volume (0-255)
    .global plr_SetVolume
    .thumb_func
plr_SetVolume:
    push {r4, r5, r6, r7, lr}                @ 0819C28C
    adds r3, r0, #0                          @ 0819C28E
    ldr r5, .Lit_0819C2F4                    @ 0819C290
    ldr r2, [r5]                             @ 0819C292
    lsls r6, r3, #1                          @ 0819C294
    movs r0, #0x93                           @ 0819C296
    lsls r0, r0, #3                          @ 0819C298
    adds r2, r2, r0                          @ 0819C29A
    adds r2, r2, r6                          @ 0819C29C
    lsls r0, r1, #8                          @ 0819C29E
    adds r0, r0, r1                          @ 0819C2A0
    strh r0, [r2]                            @ 0819C2A2
    ldr r0, [r5]                             @ 0819C2A4
    ldr r1, .Lit_0819C2F8                    @ 0819C2A6
    adds r0, r0, r1                          @ 0819C2A8
    adds r0, r0, r3                          @ 0819C2AA
    ldrb r1, [r0]                            @ 0819C2AC
    movs r0, #1                              @ 0819C2AE
    ands r0, r1                              @ 0819C2B0
    cmp r0, #0                               @ 0819C2B2
    beq .L_0819C2EE                          @ 0819C2B4
    movs r4, #0                              @ 0819C2B6
    adds r7, r5, #0                          @ 0819C2B8
    adds r0, r6, r3                          @ 0819C2BA
    lsls r5, r0, #7                          @ 0819C2BC
.L_0819C2BE:
    ldr r0, [r7]                             @ 0819C2BE
    adds r0, r0, r5                          @ 0819C2C0
    lsls r1, r4, #5                          @ 0819C2C2
    adds r2, r0, r1                          @ 0819C2C4
    ldrh r1, [r2]                            @ 0819C2C6
    movs r0, #1                              @ 0819C2C8
    ands r0, r1                              @ 0819C2CA
    cmp r0, #0                               @ 0819C2CC
    beq .L_0819C2E8                          @ 0819C2CE
    movs r0, #2                              @ 0819C2D0
    ands r0, r1                              @ 0819C2D2
    cmp r0, #0                               @ 0819C2D4
    bne .L_0819C2E8                          @ 0819C2D6
    ldr r1, .Lit_0819C2FC                    @ 0819C2D8
    lsls r0, r4, #2                          @ 0819C2DA
    adds r0, r0, r1                          @ 0819C2DC
    ldr r0, [r0]                             @ 0819C2DE
    ldr r1, [r0, #8]                         @ 0819C2E0
    adds r0, r2, #0                          @ 0819C2E2
    bl _call_via_r1                          @ 0819C2E4
.L_0819C2E8:
    adds r4, #1                              @ 0819C2E8
    cmp r4, #0xb                             @ 0819C2EA
    ble .L_0819C2BE                          @ 0819C2EC
.L_0819C2EE:
    pop {r4, r5, r6, r7}                     @ 0819C2EE
    pop {r0}                                 @ 0819C2F0
    bx r0                                    @ 0819C2F2
.Lit_0819C2F4: .word 0x03007FF0
.Lit_0819C2F8: .word 0x00000494
.Lit_0819C2FC: .word 0x08A82058

@ ---------------------------------------------------------------------------
@ sfx_Start: start sound effect n on player 0
    .global sfx_Start
    .thumb_func
sfx_Start:
    push {r4, r5, r6, r7, lr}                @ 0819C300
    mov r7, sb                               @ 0819C302
    mov r6, r8                               @ 0819C304
    push {r6, r7}                            @ 0819C306
    mov r8, r0                               @ 0819C308
    ldr r0, .Lit_0819C35C                    @ 0819C30A
    mov r2, r8                               @ 0819C30C
    lsls r1, r2, #2                          @ 0819C30E
    adds r1, r1, r0                          @ 0819C310
    ldr r4, [r1]                             @ 0819C312
    mov sb, r4                               @ 0819C314
    ldrh r5, [r4]                            @ 0819C316
    adds r4, #2                              @ 0819C318
    ldr r0, .Lit_0819C360                    @ 0819C31A
    ldr r6, [r0]                             @ 0819C31C
    movs r7, #0                              @ 0819C31E
.L_0819C320:
    movs r0, #1                              @ 0819C320
    ands r0, r5                              @ 0819C322
    cmp r0, #0                               @ 0819C324
    beq .L_0819C346                          @ 0819C326
    ldrh r1, [r4]                            @ 0819C328
    add r1, sb                               @ 0819C32A
    adds r4, #2                              @ 0819C32C
    adds r0, r6, #0                          @ 0819C32E
    bl trk_Init                              @ 0819C330
    ldr r0, .Lit_0819C360                    @ 0819C334
    ldr r0, [r0]                             @ 0819C336
    lsls r1, r7, #1                          @ 0819C338
    movs r2, #0x96                           @ 0819C33A
    lsls r2, r2, #3                          @ 0819C33C
    adds r0, r0, r2                          @ 0819C33E
    adds r0, r0, r1                          @ 0819C340
    mov r1, r8                               @ 0819C342
    strh r1, [r0]                            @ 0819C344
.L_0819C346:
    adds r7, #1                              @ 0819C346
    adds r6, #0x20                           @ 0819C348
    lsrs r5, r5, #1                          @ 0819C34A
    cmp r7, #0xb                             @ 0819C34C
    ble .L_0819C320                          @ 0819C34E
    pop {r3, r4}                             @ 0819C350
    mov r8, r3                               @ 0819C352
    mov sb, r4                               @ 0819C354
    pop {r4, r5, r6, r7}                     @ 0819C356
    pop {r0}                                 @ 0819C358
    bx r0                                    @ 0819C35A
.Lit_0819C35C: .word 0x0821DD20
.Lit_0819C360: .word 0x03007FF0

@ ---------------------------------------------------------------------------
@ sfx_Stop: stop sound effect n
    .global sfx_Stop
    .thumb_func
sfx_Stop:
    push {r4, r5, r6, r7, lr}                @ 0819C364
    adds r6, r0, #0                          @ 0819C366
    movs r5, #0                              @ 0819C368
    ldr r0, .Lit_0819C3AC                    @ 0819C36A
    ldr r4, [r0]                             @ 0819C36C
    ldr r0, .Lit_0819C3B0                    @ 0819C36E
    adds r7, r0, #0                          @ 0819C370
.L_0819C372:
    ldrh r1, [r4]                            @ 0819C372
    movs r0, #1                              @ 0819C374
    ands r0, r1                              @ 0819C376
    cmp r0, #0                               @ 0819C378
    beq .L_0819C39E                          @ 0819C37A
    ldr r0, .Lit_0819C3AC                    @ 0819C37C
    ldr r0, [r0]                             @ 0819C37E
    lsls r1, r5, #1                          @ 0819C380
    movs r2, #0x96                           @ 0819C382
    lsls r2, r2, #3                          @ 0819C384
    adds r0, r0, r2                          @ 0819C386
    adds r0, r0, r1                          @ 0819C388
    ldrh r0, [r0]                            @ 0819C38A
    cmp r0, r6                               @ 0819C38C
    bne .L_0819C39E                          @ 0819C38E
    adds r0, r5, #0                          @ 0819C390
    adds r1, r4, #0                          @ 0819C392
    bl trk_Stop                              @ 0819C394
    ldrh r0, [r4]                            @ 0819C398
    ands r0, r7                              @ 0819C39A
    strh r0, [r4]                            @ 0819C39C
.L_0819C39E:
    adds r5, #1                              @ 0819C39E
    adds r4, #0x20                           @ 0819C3A0
    cmp r5, #0xb                             @ 0819C3A2
    ble .L_0819C372                          @ 0819C3A4
    pop {r4, r5, r6, r7}                     @ 0819C3A6
    pop {r0}                                 @ 0819C3A8
    bx r0                                    @ 0819C3AA
.Lit_0819C3AC: .word 0x03007FF0
.Lit_0819C3B0: .word 0x0000FFFE

@ ---------------------------------------------------------------------------
@ sfx_StopAll: stop every track of player 0
    .global sfx_StopAll
    .thumb_func
sfx_StopAll:
    push {r4, r5, r6, lr}                    @ 0819C3B4
    movs r5, #0                              @ 0819C3B6
    ldr r0, .Lit_0819C3E8                    @ 0819C3B8
    ldr r4, [r0]                             @ 0819C3BA
    ldr r0, .Lit_0819C3EC                    @ 0819C3BC
    adds r6, r0, #0                          @ 0819C3BE
.L_0819C3C0:
    ldrh r1, [r4]                            @ 0819C3C0
    movs r0, #1                              @ 0819C3C2
    ands r0, r1                              @ 0819C3C4
    cmp r0, #0                               @ 0819C3C6
    beq .L_0819C3D8                          @ 0819C3C8
    adds r0, r5, #0                          @ 0819C3CA
    adds r1, r4, #0                          @ 0819C3CC
    bl trk_Stop                              @ 0819C3CE
    ldrh r0, [r4]                            @ 0819C3D2
    ands r0, r6                              @ 0819C3D4
    strh r0, [r4]                            @ 0819C3D6
.L_0819C3D8:
    adds r5, #1                              @ 0819C3D8
    adds r4, #0x20                           @ 0819C3DA
    cmp r5, #0xb                             @ 0819C3DC
    ble .L_0819C3C0                          @ 0819C3DE
    pop {r4, r5, r6}                         @ 0819C3E0
    pop {r0}                                 @ 0819C3E2
    bx r0                                    @ 0819C3E4
    .hword 0x0000   @ 0819C3E6 alignment
.Lit_0819C3E8: .word 0x03007FF0
.Lit_0819C3EC: .word 0x0000FFFE

@ ---------------------------------------------------------------------------
@ snd_ProcessQueue: drain the 8-entry command ring
    .global snd_ProcessQueue
    .thumb_func
snd_ProcessQueue:
    push {r4, lr}                            @ 0819C3F0
    b .L_0819C4C2                            @ 0819C3F2
.L_0819C3F4:
    ldr r1, [r3]                             @ 0819C3F4
    adds r2, r1, r2                          @ 0819C3F6
    movs r3, #0                              @ 0819C3F8
    ldrsh r0, [r2, r3]                       @ 0819C3FA
    lsls r0, r0, #1                          @ 0819C3FC
    movs r4, #0x90                           @ 0819C3FE
    lsls r4, r4, #3                          @ 0819C400
    adds r1, r1, r4                          @ 0819C402
    adds r1, r1, r0                          @ 0819C404
    ldrh r3, [r1]                            @ 0819C406
    ldrh r0, [r2]                            @ 0819C408
    adds r0, #1                              @ 0819C40A
    movs r1, #7                              @ 0819C40C
    ands r0, r1                              @ 0819C40E
    strh r0, [r2]                            @ 0819C410
    lsrs r0, r3, #0xc                        @ 0819C412
    cmp r0, #9                               @ 0819C414
    bhi .L_0819C4C2                          @ 0819C416
    lsls r0, r0, #2                          @ 0819C418
    ldr r1, .Lit_0819C424                    @ 0819C41A
    adds r0, r0, r1                          @ 0819C41C
    ldr r0, [r0]                             @ 0819C41E
    mov pc, r0                               @ 0819C420
    .hword 0x0000   @ 0819C422 alignment
.Lit_0819C424: .word snd_CommandTable

    .align 2, 0
snd_CommandTable:
    .word .L_0819C450   @ cmd 0
    .word .L_0819C462   @ cmd 1
    .word .L_0819C46E   @ cmd 2
    .word .L_0819C4C2   @ cmd 3
    .word .L_0819C4C2   @ cmd 4
    .word .L_0819C48C   @ cmd 5
    .word .L_0819C49C   @ cmd 6
    .word .L_0819C4AC   @ cmd 7
    .word .L_0819C4B2   @ cmd 8
    .word .L_0819C47A   @ cmd 9
.L_0819C450:
    lsrs r0, r3, #8                          @ 0819C450
    movs r1, #0xf                            @ 0819C452
    ands r0, r1                              @ 0819C454
    movs r1, #0xff                           @ 0819C456
    ands r3, r1                              @ 0819C458
    adds r1, r3, #0                          @ 0819C45A
    bl plr_StartSong                         @ 0819C45C
    b .L_0819C4C2                            @ 0819C460
.L_0819C462:
    lsrs r0, r3, #8                          @ 0819C462
    movs r1, #0xf                            @ 0819C464
    ands r0, r1                              @ 0819C466
    bl plr_Stop                              @ 0819C468
    b .L_0819C4C2                            @ 0819C46C
.L_0819C46E:
    lsrs r0, r3, #8                          @ 0819C46E
    movs r1, #0xf                            @ 0819C470
    ands r0, r1                              @ 0819C472
    bl plr_Resume                            @ 0819C474
    b .L_0819C4C2                            @ 0819C478
.L_0819C47A:
    lsrs r0, r3, #8                          @ 0819C47A
    movs r1, #0xf                            @ 0819C47C
    ands r0, r1                              @ 0819C47E
    movs r1, #0xff                           @ 0819C480
    ands r3, r1                              @ 0819C482
    adds r1, r3, #0                          @ 0819C484
    bl plr_SetVolume                         @ 0819C486
    b .L_0819C4C2                            @ 0819C48A
.L_0819C48C:
    ldr r0, .Lit_0819C498                    @ 0819C48C
    ands r3, r0                              @ 0819C48E
    adds r0, r3, #0                          @ 0819C490
    bl sfx_Start                             @ 0819C492
    b .L_0819C4C2                            @ 0819C496
.Lit_0819C498: .word 0x00000FFF
.L_0819C49C:
    ldr r0, .Lit_0819C4A8                    @ 0819C49C
    ands r3, r0                              @ 0819C49E
    adds r0, r3, #0                          @ 0819C4A0
    bl sfx_Stop                              @ 0819C4A2
    b .L_0819C4C2                            @ 0819C4A6
.Lit_0819C4A8: .word 0x00000FFF
.L_0819C4AC:
    bl sfx_StopAll                           @ 0819C4AC
    b .L_0819C4C2                            @ 0819C4B0
.L_0819C4B2:
    lsrs r0, r3, #8                          @ 0819C4B2
    movs r1, #0xf                            @ 0819C4B4
    ands r0, r1                              @ 0819C4B6
    movs r1, #0xff                           @ 0819C4B8
    ands r3, r1                              @ 0819C4BA
    adds r1, r3, #0                          @ 0819C4BC
    bl plr_SetTempoDiv                       @ 0819C4BE
.L_0819C4C2:
    ldr r3, .Lit_0819C4E4                    @ 0819C4C2
    ldr r0, [r3]                             @ 0819C4C4
    movs r2, #0x92                           @ 0819C4C6
    lsls r2, r2, #3                          @ 0819C4C8
    adds r1, r0, r2                          @ 0819C4CA
    ldr r4, .Lit_0819C4E8                    @ 0819C4CC
    adds r0, r0, r4                          @ 0819C4CE
    movs r4, #0                              @ 0819C4D0
    ldrsh r1, [r1, r4]                       @ 0819C4D2
    movs r4, #0                              @ 0819C4D4
    ldrsh r0, [r0, r4]                       @ 0819C4D6
    cmp r1, r0                               @ 0819C4D8
    bne .L_0819C3F4                          @ 0819C4DA
    pop {r4}                                 @ 0819C4DC
    pop {r0}                                 @ 0819C4DE
    bx r0                                    @ 0819C4E0
    .hword 0x0000   @ 0819C4E2 alignment
.Lit_0819C4E4: .word 0x03007FF0
.Lit_0819C4E8: .word 0x00000492

@ ---------------------------------------------------------------------------
@ snd_QueueCommand: append a 16-bit command to the ring
    .global snd_QueueCommand
    .thumb_func
snd_QueueCommand:
    push {r4, r5, lr}                        @ 0819C4EC
    ldr r4, .Lit_0819C51C                    @ 0819C4EE
    ldr r2, [r4]                             @ 0819C4F0
    ldr r3, .Lit_0819C520                    @ 0819C4F2
    adds r1, r2, r3                          @ 0819C4F4
    movs r5, #0                              @ 0819C4F6
    ldrsh r1, [r1, r5]                       @ 0819C4F8
    lsls r1, r1, #1                          @ 0819C4FA
    movs r5, #0x90                           @ 0819C4FC
    lsls r5, r5, #3                          @ 0819C4FE
    adds r2, r2, r5                          @ 0819C500
    adds r2, r2, r1                          @ 0819C502
    strh r0, [r2]                            @ 0819C504
    ldr r2, [r4]                             @ 0819C506
    adds r2, r2, r3                          @ 0819C508
    ldrh r0, [r2]                            @ 0819C50A
    adds r0, #1                              @ 0819C50C
    movs r1, #7                              @ 0819C50E
    ands r0, r1                              @ 0819C510
    strh r0, [r2]                            @ 0819C512
    movs r0, #0                              @ 0819C514
    pop {r4, r5}                             @ 0819C516
    pop {r1}                                 @ 0819C518
    bx r1                                    @ 0819C51A
.Lit_0819C51C: .word 0x03007FF0
.Lit_0819C520: .word 0x00000492

@ ---------------------------------------------------------------------------
@ trk_Step: advance one track by one frame (sequencer)
    .global trk_Step
    .thumb_func
trk_Step:
    push {r4, r5, r6, r7, lr}                @ 0819C524
    mov r7, r8                               @ 0819C526
    push {r7}                                @ 0819C528
    adds r5, r0, #0                          @ 0819C52A
    adds r7, r1, #0                          @ 0819C52C
    adds r4, r2, #0                          @ 0819C52E
    ldrh r1, [r5]                            @ 0819C530
    movs r0, #0x80                           @ 0819C532
    ands r0, r1                              @ 0819C534
    cmp r0, #0                               @ 0819C536
    beq .L_0819C560                          @ 0819C538
    movs r0, #0x80                           @ 0819C53A
    lsls r0, r0, #1                          @ 0819C53C
    ands r0, r1                              @ 0819C53E
    cmp r0, #0                               @ 0819C540
    beq .L_0819C54C                          @ 0819C542
    adds r0, r5, #0                          @ 0819C544
    adds r1, r7, #0                          @ 0819C546
    bl trk_TickLfo2                          @ 0819C548
.L_0819C54C:
    ldrh r1, [r5]                            @ 0819C54C
    movs r0, #0x80                           @ 0819C54E
    lsls r0, r0, #4                          @ 0819C550
    ands r0, r1                              @ 0819C552
    cmp r0, #0                               @ 0819C554
    beq .L_0819C560                          @ 0819C556
    adds r0, r5, #0                          @ 0819C558
    adds r1, r7, #0                          @ 0819C55A
    bl trk_TickLfo1                          @ 0819C55C
.L_0819C560:
    ldrb r1, [r5, #3]                        @ 0819C560
    ldrb r0, [r5, #2]                        @ 0819C562
    adds r1, r1, r0                          @ 0819C564
    movs r0, #0                              @ 0819C566
    mov r8, r0                               @ 0819C568
    cmp r1, r4                               @ 0819C56A
    ble .L_0819C578                          @ 0819C56C
.L_0819C56E:
    movs r2, #1                              @ 0819C56E
    add r8, r2                               @ 0819C570
    subs r1, r1, r4                          @ 0819C572
    cmp r1, r4                               @ 0819C574
    bgt .L_0819C56E                          @ 0819C576
.L_0819C578:
    strb r1, [r5, #3]                        @ 0819C578
    mov r0, r8                               @ 0819C57A
    cmp r0, #0                               @ 0819C57C
    bne .L_0819C582                          @ 0819C57E
    b .L_0819C92E                            @ 0819C580
.L_0819C582:
    ldrb r0, [r5, #0xa]                      @ 0819C582
    mov r1, r8                               @ 0819C584
    subs r1, r1, r0                          @ 0819C586
    mov r8, r1                               @ 0819C588
    cmp r1, #0                               @ 0819C58A
    bge .L_0819C594                          @ 0819C58C
    rsbs r0, r1, #0                          @ 0819C58E
    strb r0, [r5, #0xa]                      @ 0819C590
    b .L_0819C92E                            @ 0819C592
.L_0819C594:
    ldrh r1, [r5]                            @ 0819C594
    movs r0, #0xc0                           @ 0819C596
    ands r0, r1                              @ 0819C598
    cmp r0, #0x80                            @ 0819C59A
    bne .L_0819C5CC                          @ 0819C59C
    ldr r0, .Lit_0819C5C8                    @ 0819C59E
    ands r0, r1                              @ 0819C5A0
    strh r0, [r5]                            @ 0819C5A2
    ldr r1, [r7, #0x14]                      @ 0819C5A4
    adds r0, r5, #0                          @ 0819C5A6
    bl _call_via_r1                          @ 0819C5A8
    ldrh r1, [r5]                            @ 0819C5AC
    movs r0, #0x20                           @ 0819C5AE
    ands r0, r1                              @ 0819C5B0
    cmp r0, #0                               @ 0819C5B2
    beq .L_0819C5CC                          @ 0819C5B4
    ldrh r1, [r5, #8]                        @ 0819C5B6
    adds r0, r1, #1                          @ 0819C5B8
    strh r0, [r5, #8]                        @ 0819C5BA
    lsls r1, r1, #0x10                       @ 0819C5BC
    lsrs r1, r1, #0x10                       @ 0819C5BE
    ldr r0, [r5, #4]                         @ 0819C5C0
    adds r0, r0, r1                          @ 0819C5C2
    b .L_0819C850                            @ 0819C5C4
    .hword 0x0000   @ 0819C5C6 alignment
.Lit_0819C5C8: .word 0x0000FF3F
.L_0819C5CC:
    ldrh r0, [r5, #8]                        @ 0819C5CC
    adds r1, r0, #1                          @ 0819C5CE
    strh r1, [r5, #8]                        @ 0819C5D0
    lsls r0, r0, #0x10                       @ 0819C5D2
    lsrs r0, r0, #0x10                       @ 0819C5D4
    ldr r1, [r5, #4]                         @ 0819C5D6
    adds r0, r1, r0                          @ 0819C5D8
    ldrb r6, [r0]                            @ 0819C5DA
    adds r0, r6, #0                          @ 0819C5DC
    subs r0, #0xe0                           @ 0819C5DE
    adds r2, r1, #0                          @ 0819C5E0
    cmp r0, #0x1f                            @ 0819C5E2
    bhi .L_0819C674                          @ 0819C5E4
    lsls r0, r0, #2                          @ 0819C5E6
    ldr r1, .Lit_0819C5F0                    @ 0819C5E8
    adds r0, r0, r1                          @ 0819C5EA
    ldr r0, [r0]                             @ 0819C5EC
    mov pc, r0                               @ 0819C5EE
.Lit_0819C5F0: .word trk_OpcodeTable

    .align 2, 0
trk_OpcodeTable:
    .word .L_0819C71C   @ E0 pitch LFO params
    .word .L_0819C74C   @ E1 pitch LFO on
    .word .L_0819C754   @ E2 pitch LFO off
    .word .L_0819C760   @ E3 volume LFO params
    .word .L_0819C790   @ E4 volume LFO on
    .word .L_0819C79E   @ E5 volume LFO off
    .word .L_0819C674   @ E6 (not a command: parsed as a note)
    .word .L_0819C674   @ E7 (not a command: parsed as a note)
    .word .L_0819C87C   @ E8 loop A0
    .word .L_0819C87C   @ E9 loop A1
    .word .L_0819C87C   @ EA loop A2
    .word .L_0819C87C   @ EB loop A3
    .word .L_0819C8CA   @ EC loop B0
    .word .L_0819C8CA   @ ED loop B1
    .word .L_0819C8CA   @ EE loop B2
    .word .L_0819C8CA   @ EF loop B3
    .word .L_0819C7AC   @ F0 program
    .word .L_0819C7D4   @ F1 volume
    .word .L_0819C7EA   @ F2 pan
    .word .L_0819C800   @ F3 detune
    .word .L_0819C814   @ F4 bend range
    .word .L_0819C828   @ F5 bend
    .word .L_0819C844   @ F6 rest
    .word .L_0819C594   @ F7 note off
    .word .L_0819C856   @ F8 goto
    .word .L_0819C7C0   @ F9 speed
    .word .L_0819C674   @ FA (not a command: parsed as a note)
    .word .L_0819C674   @ FB (not a command: parsed as a note)
    .word .L_0819C674   @ FC (not a command: parsed as a note)
    .word .L_0819C674   @ FD (not a command: parsed as a note)
    .word .L_0819C674   @ FE (not a command: parsed as a note)
    .word .L_0819C918   @ FF end
.L_0819C674:
    ldrh r0, [r5, #8]                        @ 0819C674
    adds r1, r0, #1                          @ 0819C676
    strh r1, [r5, #8]                        @ 0819C678
    lsls r0, r0, #0x10                       @ 0819C67A
    lsrs r0, r0, #0x10                       @ 0819C67C
    adds r0, r2, r0                          @ 0819C67E
    ldrb r4, [r0]                            @ 0819C680
    movs r0, #0x7f                           @ 0819C682
    ands r0, r4                              @ 0819C684
    strb r0, [r5, #0xb]                      @ 0819C686
    ldrh r1, [r5]                            @ 0819C688
    movs r0, #0x40                           @ 0819C68A
    ands r0, r1                              @ 0819C68C
    cmp r0, #0                               @ 0819C68E
    beq .L_0819C6A8                          @ 0819C690
    ldr r1, [r7, #0x10]                      @ 0819C692
    adds r0, r5, #0                          @ 0819C694
    bl _call_via_r1                          @ 0819C696
    ldrh r1, [r5]                            @ 0819C69A
    ldr r0, .Lit_0819C6A4                    @ 0819C69C
    ands r0, r1                              @ 0819C69E
    b .L_0819C6E0                            @ 0819C6A0
    .hword 0x0000   @ 0819C6A2 alignment
.Lit_0819C6A4: .word 0x0000FFBF
.L_0819C6A8:
    movs r0, #0x80                           @ 0819C6A8
    lsls r0, r0, #4                          @ 0819C6AA
    ands r0, r1                              @ 0819C6AC
    cmp r0, #0                               @ 0819C6AE
    beq .L_0819C6B8                          @ 0819C6B0
    adds r0, r5, #0                          @ 0819C6B2
    bl trk_ResetLfo1                         @ 0819C6B4
.L_0819C6B8:
    ldrh r1, [r5]                            @ 0819C6B8
    movs r0, #0x80                           @ 0819C6BA
    lsls r0, r0, #1                          @ 0819C6BC
    ands r0, r1                              @ 0819C6BE
    cmp r0, #0                               @ 0819C6C0
    beq .L_0819C6CA                          @ 0819C6C2
    adds r0, r5, #0                          @ 0819C6C4
    bl trk_ResetLfo2                         @ 0819C6C6
.L_0819C6CA:
    ldr r1, [r7, #0x10]                      @ 0819C6CA
    adds r0, r5, #0                          @ 0819C6CC
    bl _call_via_r1                          @ 0819C6CE
    ldr r1, [r7]                             @ 0819C6D2
    adds r0, r5, #0                          @ 0819C6D4
    bl _call_via_r1                          @ 0819C6D6
    ldrh r1, [r5]                            @ 0819C6DA
    movs r0, #0x80                           @ 0819C6DC
    orrs r0, r1                              @ 0819C6DE
.L_0819C6E0:
    strh r0, [r5]                            @ 0819C6E0
    cmp r6, #0                               @ 0819C6E2
    bne .L_0819C708                          @ 0819C6E4
    ldrh r0, [r5]                            @ 0819C6E6
    movs r1, #0x40                           @ 0819C6E8
    orrs r1, r0                              @ 0819C6EA
    strh r1, [r5]                            @ 0819C6EC
    movs r0, #0x80                           @ 0819C6EE
    ands r4, r0                              @ 0819C6F0
    cmp r4, #0                               @ 0819C6F2
    bne .L_0819C6F8                          @ 0819C6F4
    b .L_0819C5CC                            @ 0819C6F6
.L_0819C6F8:
    ldrh r1, [r5, #8]                        @ 0819C6F8
    adds r0, r1, #1                          @ 0819C6FA
    strh r0, [r5, #8]                        @ 0819C6FC
    lsls r1, r1, #0x10                       @ 0819C6FE
    lsrs r1, r1, #0x10                       @ 0819C700
    ldr r0, [r5, #4]                         @ 0819C702
    adds r0, r0, r1                          @ 0819C704
    b .L_0819C850                            @ 0819C706
.L_0819C708:
    movs r0, #0x80                           @ 0819C708
    ands r4, r0                              @ 0819C70A
    cmp r4, #0                               @ 0819C70C
    beq .L_0819C718                          @ 0819C70E
    ldrh r1, [r5]                            @ 0819C710
    movs r0, #0x20                           @ 0819C712
    orrs r0, r1                              @ 0819C714
    strh r0, [r5]                            @ 0819C716
.L_0819C718:
    strb r6, [r5, #0xa]                      @ 0819C718
    b .L_0819C582                            @ 0819C71A
.L_0819C71C:
    ldrh r0, [r5, #8]                        @ 0819C71C
    adds r1, r0, #1                          @ 0819C71E
    strh r1, [r5, #8]                        @ 0819C720
    lsls r0, r0, #0x10                       @ 0819C722
    lsrs r0, r0, #0x10                       @ 0819C724
    ldr r2, [r5, #4]                         @ 0819C726
    adds r0, r2, r0                          @ 0819C728
    ldrb r0, [r0]                            @ 0819C72A
    strb r0, [r5, #0x18]                     @ 0819C72C
    adds r0, r1, #1                          @ 0819C72E
    strh r0, [r5, #8]                        @ 0819C730
    lsls r1, r1, #0x10                       @ 0819C732
    lsrs r1, r1, #0x10                       @ 0819C734
    adds r1, r2, r1                          @ 0819C736
    ldrb r1, [r1]                            @ 0819C738
    strb r1, [r5, #0x19]                     @ 0819C73A
    adds r1, r0, #1                          @ 0819C73C
    strh r1, [r5, #8]                        @ 0819C73E
    lsls r0, r0, #0x10                       @ 0819C740
    lsrs r0, r0, #0x10                       @ 0819C742
    adds r2, r2, r0                          @ 0819C744
    ldrb r0, [r2]                            @ 0819C746
    strb r0, [r5, #0x1a]                     @ 0819C748
    b .L_0819C5CC                            @ 0819C74A
.L_0819C74C:
    ldrh r1, [r5]                            @ 0819C74C
    movs r2, #0x80                           @ 0819C74E
    lsls r2, r2, #1                          @ 0819C750
    b .L_0819C796                            @ 0819C752
.L_0819C754:
    ldrh r1, [r5]                            @ 0819C754
    ldr r0, .Lit_0819C75C                    @ 0819C756
    b .L_0819C7A2                            @ 0819C758
    .hword 0x0000   @ 0819C75A alignment
.Lit_0819C75C: .word 0x0000FEFF
.L_0819C760:
    ldrh r0, [r5, #8]                        @ 0819C760
    adds r1, r0, #1                          @ 0819C762
    strh r1, [r5, #8]                        @ 0819C764
    lsls r0, r0, #0x10                       @ 0819C766
    lsrs r0, r0, #0x10                       @ 0819C768
    ldr r2, [r5, #4]                         @ 0819C76A
    adds r0, r2, r0                          @ 0819C76C
    ldrb r0, [r0]                            @ 0819C76E
    strb r0, [r5, #0x14]                     @ 0819C770
    adds r0, r1, #1                          @ 0819C772
    strh r0, [r5, #8]                        @ 0819C774
    lsls r1, r1, #0x10                       @ 0819C776
    lsrs r1, r1, #0x10                       @ 0819C778
    adds r1, r2, r1                          @ 0819C77A
    ldrb r1, [r1]                            @ 0819C77C
    strb r1, [r5, #0x15]                     @ 0819C77E
    adds r1, r0, #1                          @ 0819C780
    strh r1, [r5, #8]                        @ 0819C782
    lsls r0, r0, #0x10                       @ 0819C784
    lsrs r0, r0, #0x10                       @ 0819C786
    adds r2, r2, r0                          @ 0819C788
    ldrb r0, [r2]                            @ 0819C78A
    strb r0, [r5, #0x16]                     @ 0819C78C
    b .L_0819C5CC                            @ 0819C78E
.L_0819C790:
    ldrh r1, [r5]                            @ 0819C790
    movs r2, #0x80                           @ 0819C792
    lsls r2, r2, #4                          @ 0819C794
.L_0819C796:
    adds r0, r2, #0                          @ 0819C796
    orrs r0, r1                              @ 0819C798
    strh r0, [r5]                            @ 0819C79A
    b .L_0819C5CC                            @ 0819C79C
.L_0819C79E:
    ldrh r1, [r5]                            @ 0819C79E
    ldr r0, .Lit_0819C7A8                    @ 0819C7A0
.L_0819C7A2:
    ands r0, r1                              @ 0819C7A2
    strh r0, [r5]                            @ 0819C7A4
    b .L_0819C5CC                            @ 0819C7A6
.Lit_0819C7A8: .word 0x0000F7FF
.L_0819C7AC:
    ldrh r1, [r5, #8]                        @ 0819C7AC
    adds r0, r1, #1                          @ 0819C7AE
    strh r0, [r5, #8]                        @ 0819C7B0
    lsls r1, r1, #0x10                       @ 0819C7B2
    lsrs r1, r1, #0x10                       @ 0819C7B4
    ldr r0, [r5, #4]                         @ 0819C7B6
    adds r0, r0, r1                          @ 0819C7B8
    ldrb r0, [r0]                            @ 0819C7BA
    strb r0, [r5, #0xc]                      @ 0819C7BC
    b .L_0819C5CC                            @ 0819C7BE
.L_0819C7C0:
    ldrh r1, [r5, #8]                        @ 0819C7C0
    adds r0, r1, #1                          @ 0819C7C2
    strh r0, [r5, #8]                        @ 0819C7C4
    lsls r1, r1, #0x10                       @ 0819C7C6
    lsrs r1, r1, #0x10                       @ 0819C7C8
    ldr r0, [r5, #4]                         @ 0819C7CA
    adds r0, r0, r1                          @ 0819C7CC
    ldrb r0, [r0]                            @ 0819C7CE
    strb r0, [r5, #2]                        @ 0819C7D0
    b .L_0819C5CC                            @ 0819C7D2
.L_0819C7D4:
    ldrh r1, [r5, #8]                        @ 0819C7D4
    adds r0, r1, #1                          @ 0819C7D6
    strh r0, [r5, #8]                        @ 0819C7D8
    lsls r1, r1, #0x10                       @ 0819C7DA
    lsrs r1, r1, #0x10                       @ 0819C7DC
    ldr r0, [r5, #4]                         @ 0819C7DE
    adds r0, r0, r1                          @ 0819C7E0
    ldrb r0, [r0]                            @ 0819C7E2
    strb r0, [r5, #0xd]                      @ 0819C7E4
    ldr r1, [r7, #8]                         @ 0819C7E6
    b .L_0819C83C                            @ 0819C7E8
.L_0819C7EA:
    ldrh r1, [r5, #8]                        @ 0819C7EA
    adds r0, r1, #1                          @ 0819C7EC
    strh r0, [r5, #8]                        @ 0819C7EE
    lsls r1, r1, #0x10                       @ 0819C7F0
    lsrs r1, r1, #0x10                       @ 0819C7F2
    ldr r0, [r5, #4]                         @ 0819C7F4
    adds r0, r0, r1                          @ 0819C7F6
    ldrb r0, [r0]                            @ 0819C7F8
    strb r0, [r5, #0xe]                      @ 0819C7FA
    ldr r1, [r7, #0xc]                       @ 0819C7FC
    b .L_0819C83C                            @ 0819C7FE
.L_0819C800:
    ldrh r1, [r5, #8]                        @ 0819C800
    adds r0, r1, #1                          @ 0819C802
    strh r0, [r5, #8]                        @ 0819C804
    lsls r1, r1, #0x10                       @ 0819C806
    lsrs r1, r1, #0x10                       @ 0819C808
    ldr r0, [r5, #4]                         @ 0819C80A
    adds r0, r0, r1                          @ 0819C80C
    ldrb r0, [r0]                            @ 0819C80E
    strb r0, [r5, #0x11]                     @ 0819C810
    b .L_0819C5CC                            @ 0819C812
.L_0819C814:
    ldrh r1, [r5, #8]                        @ 0819C814
    adds r0, r1, #1                          @ 0819C816
    strh r0, [r5, #8]                        @ 0819C818
    lsls r1, r1, #0x10                       @ 0819C81A
    lsrs r1, r1, #0x10                       @ 0819C81C
    ldr r0, [r5, #4]                         @ 0819C81E
    adds r0, r0, r1                          @ 0819C820
    ldrb r0, [r0]                            @ 0819C822
    strb r0, [r5, #0xf]                      @ 0819C824
    b .L_0819C83A                            @ 0819C826
.L_0819C828:
    ldrh r1, [r5, #8]                        @ 0819C828
    adds r0, r1, #1                          @ 0819C82A
    strh r0, [r5, #8]                        @ 0819C82C
    lsls r1, r1, #0x10                       @ 0819C82E
    lsrs r1, r1, #0x10                       @ 0819C830
    ldr r0, [r5, #4]                         @ 0819C832
    adds r0, r0, r1                          @ 0819C834
    ldrb r0, [r0]                            @ 0819C836
    strb r0, [r5, #0x10]                     @ 0819C838
.L_0819C83A:
    ldr r1, [r7, #0x10]                      @ 0819C83A
.L_0819C83C:
    adds r0, r5, #0                          @ 0819C83C
    bl _call_via_r1                          @ 0819C83E
    b .L_0819C5CC                            @ 0819C842
.L_0819C844:
    ldrh r0, [r5, #8]                        @ 0819C844
    adds r1, r0, #1                          @ 0819C846
    strh r1, [r5, #8]                        @ 0819C848
    lsls r0, r0, #0x10                       @ 0819C84A
    lsrs r0, r0, #0x10                       @ 0819C84C
    adds r0, r2, r0                          @ 0819C84E
.L_0819C850:
    ldrb r0, [r0]                            @ 0819C850
    strb r0, [r5, #0xa]                      @ 0819C852
    b .L_0819C582                            @ 0819C854
.L_0819C856:
    ldrh r0, [r5, #8]                        @ 0819C856
    adds r1, r0, #1                          @ 0819C858
    strh r1, [r5, #8]                        @ 0819C85A
    lsls r0, r0, #0x10                       @ 0819C85C
    lsrs r0, r0, #0x10                       @ 0819C85E
    ldr r2, [r5, #4]                         @ 0819C860
    adds r0, r2, r0                          @ 0819C862
    ldrb r4, [r0]                            @ 0819C864
    adds r3, r1, #1                          @ 0819C866
    strh r3, [r5, #8]                        @ 0819C868
    lsls r1, r1, #0x10                       @ 0819C86A
    lsrs r1, r1, #0x10                       @ 0819C86C
    adds r2, r2, r1                          @ 0819C86E
    ldrb r0, [r2]                            @ 0819C870
    lsls r0, r0, #8                          @ 0819C872
    orrs r4, r0                              @ 0819C874
    adds r3, r3, r4                          @ 0819C876
    strh r3, [r5, #8]                        @ 0819C878
    b .L_0819C5CC                            @ 0819C87A
.L_0819C87C:
    ldrh r0, [r5, #8]                        @ 0819C87C
    adds r1, r0, #1                          @ 0819C87E
    strh r1, [r5, #8]                        @ 0819C880
    lsls r0, r0, #0x10                       @ 0819C882
    lsrs r0, r0, #0x10                       @ 0819C884
    ldr r2, [r5, #4]                         @ 0819C886
    adds r0, r2, r0                          @ 0819C888
    ldrb r3, [r0]                            @ 0819C88A
    adds r0, r1, #1                          @ 0819C88C
    strh r0, [r5, #8]                        @ 0819C88E
    lsls r1, r1, #0x10                       @ 0819C890
    lsrs r1, r1, #0x10                       @ 0819C892
    adds r1, r2, r1                          @ 0819C894
    ldrb r4, [r1]                            @ 0819C896
    adds r1, r0, #1                          @ 0819C898
    strh r1, [r5, #8]                        @ 0819C89A
    lsls r0, r0, #0x10                       @ 0819C89C
    lsrs r0, r0, #0x10                       @ 0819C89E
    adds r2, r2, r0                          @ 0819C8A0
    ldrb r0, [r2]                            @ 0819C8A2
    lsls r0, r0, #8                          @ 0819C8A4
    orrs r4, r0                              @ 0819C8A6
    movs r0, #3                              @ 0819C8A8
    ands r6, r0                              @ 0819C8AA
    adds r0, r5, #0                          @ 0819C8AC
    adds r0, #0x1c                           @ 0819C8AE
    adds r1, r0, r6                          @ 0819C8B0
    ldrb r0, [r1]                            @ 0819C8B2
    adds r0, #1                              @ 0819C8B4
    strb r0, [r1]                            @ 0819C8B6
    cmp r3, r0                               @ 0819C8B8
    bge .L_0819C8C4                          @ 0819C8BA
    ldrh r0, [r5, #8]                        @ 0819C8BC
    adds r0, r0, r4                          @ 0819C8BE
    strh r0, [r5, #8]                        @ 0819C8C0
    b .L_0819C5CC                            @ 0819C8C2
.L_0819C8C4:
    movs r0, #0                              @ 0819C8C4
    strb r0, [r1]                            @ 0819C8C6
    b .L_0819C5CC                            @ 0819C8C8
.L_0819C8CA:
    ldrh r0, [r5, #8]                        @ 0819C8CA
    adds r1, r0, #1                          @ 0819C8CC
    strh r1, [r5, #8]                        @ 0819C8CE
    lsls r0, r0, #0x10                       @ 0819C8D0
    lsrs r0, r0, #0x10                       @ 0819C8D2
    ldr r2, [r5, #4]                         @ 0819C8D4
    adds r0, r2, r0                          @ 0819C8D6
    ldrb r3, [r0]                            @ 0819C8D8
    adds r0, r1, #1                          @ 0819C8DA
    strh r0, [r5, #8]                        @ 0819C8DC
    lsls r1, r1, #0x10                       @ 0819C8DE
    lsrs r1, r1, #0x10                       @ 0819C8E0
    adds r1, r2, r1                          @ 0819C8E2
    ldrb r4, [r1]                            @ 0819C8E4
    adds r1, r0, #1                          @ 0819C8E6
    strh r1, [r5, #8]                        @ 0819C8E8
    lsls r0, r0, #0x10                       @ 0819C8EA
    lsrs r0, r0, #0x10                       @ 0819C8EC
    adds r2, r2, r0                          @ 0819C8EE
    ldrb r0, [r2]                            @ 0819C8F0
    lsls r0, r0, #8                          @ 0819C8F2
    orrs r4, r0                              @ 0819C8F4
    movs r0, #3                              @ 0819C8F6
    ands r6, r0                              @ 0819C8F8
    adds r0, r5, #0                          @ 0819C8FA
    adds r0, #0x1c                           @ 0819C8FC
    adds r2, r0, r6                          @ 0819C8FE
    ldrb r0, [r2]                            @ 0819C900
    adds r0, #1                              @ 0819C902
    strb r0, [r2]                            @ 0819C904
    cmp r3, r0                               @ 0819C906
    bge .L_0819C90C                          @ 0819C908
    b .L_0819C5CC                            @ 0819C90A
.L_0819C90C:
    ldrh r0, [r5, #8]                        @ 0819C90C
    adds r0, r0, r4                          @ 0819C90E
    movs r1, #0                              @ 0819C910
    strh r0, [r5, #8]                        @ 0819C912
    strb r1, [r2]                            @ 0819C914
    b .L_0819C5CC                            @ 0819C916
.L_0819C918:
    ldrh r1, [r5]                            @ 0819C918
    movs r0, #0x80                           @ 0819C91A
    ands r0, r1                              @ 0819C91C
    cmp r0, #0                               @ 0819C91E
    beq .L_0819C92A                          @ 0819C920
    ldr r1, [r7, #0x14]                      @ 0819C922
    adds r0, r5, #0                          @ 0819C924
    bl _call_via_r1                          @ 0819C926
.L_0819C92A:
    movs r0, #0                              @ 0819C92A
    strh r0, [r5]                            @ 0819C92C
.L_0819C92E:
    pop {r3}                                 @ 0819C92E
    mov r8, r3                               @ 0819C930
    pop {r4, r5, r6, r7}                     @ 0819C932
    pop {r0}                                 @ 0819C934
    bx r0                                    @ 0819C936

@ ---------------------------------------------------------------------------
@ snd_UpdatePlayers: per-frame: players 0-2, channel arbitration
    .global snd_UpdatePlayers
    .thumb_func
snd_UpdatePlayers:
    push {r4, r5, r6, r7, lr}                @ 0819C938
    mov r7, sl                               @ 0819C93A
    mov r6, sb                               @ 0819C93C
    mov r5, r8                               @ 0819C93E
    push {r5, r6, r7}                        @ 0819C940
    sub sp, #4                               @ 0819C942
    movs r0, #0                              @ 0819C944
    mov sb, r0                               @ 0819C946
    movs r2, #0                              @ 0819C948
.L_0819C94A:
    ldr r3, .Lit_0819C9AC                    @ 0819C94A
    ldr r0, [r3]                             @ 0819C94C
    ldr r1, .Lit_0819C9B0                    @ 0819C94E
    adds r0, r0, r1                          @ 0819C950
    adds r0, r0, r2                          @ 0819C952
    ldrb r1, [r0]                            @ 0819C954
    movs r0, #1                              @ 0819C956
    ands r0, r1                              @ 0819C958
    adds r1, r2, #1                          @ 0819C95A
    str r1, [sp]                             @ 0819C95C
    cmp r0, #0                               @ 0819C95E
    beq .L_0819CA0E                          @ 0819C960
    movs r6, #0                              @ 0819C962
    lsls r0, r2, #1                          @ 0819C964
    mov r8, r3                               @ 0819C966
    lsls r7, r2, #2                          @ 0819C968
    adds r0, r0, r2                          @ 0819C96A
    lsls r0, r0, #7                          @ 0819C96C
    mov sl, r0                               @ 0819C96E
.L_0819C970:
    mov r1, r8                               @ 0819C970
    ldr r0, [r1]                             @ 0819C972
    add r0, sl                               @ 0819C974
    lsls r1, r6, #5                          @ 0819C976
    adds r4, r0, r1                          @ 0819C978
    ldrh r2, [r4]                            @ 0819C97A
    movs r1, #1                              @ 0819C97C
    adds r0, r1, #0                          @ 0819C97E
    ands r0, r2                              @ 0819C980
    cmp r0, #0                               @ 0819C982
    beq .L_0819CA08                          @ 0819C984
    lsls r1, r6                              @ 0819C986
    mov r0, sb                               @ 0819C988
    ands r0, r1                              @ 0819C98A
    cmp r0, #0                               @ 0819C98C
    beq .L_0819C9BC                          @ 0819C98E
    movs r0, #2                              @ 0819C990
    orrs r0, r2                              @ 0819C992
    strh r0, [r4]                            @ 0819C994
    mov r1, r8                               @ 0819C996
    ldr r0, [r1]                             @ 0819C998
    ldr r1, .Lit_0819C9B4                    @ 0819C99A
    adds r0, r0, r1                          @ 0819C99C
    adds r0, r0, r7                          @ 0819C99E
    ldr r2, [r0]                             @ 0819C9A0
    adds r0, r4, #0                          @ 0819C9A2
    ldr r1, .Lit_0819C9B8                    @ 0819C9A4
    bl trk_Step                              @ 0819C9A6
    b .L_0819CA08                            @ 0819C9AA
.Lit_0819C9AC: .word 0x03007FF0
.Lit_0819C9B0: .word 0x00000494
.Lit_0819C9B4: .word 0x000004A4
.Lit_0819C9B8: .word 0x0821DC2C
.L_0819C9BC:
    mov r0, sb                               @ 0819C9BC
    orrs r0, r1                              @ 0819C9BE
    mov sb, r0                               @ 0819C9C0
    ldr r0, .Lit_0819CA24                    @ 0819C9C2
    lsls r1, r6, #2                          @ 0819C9C4
    adds r1, r1, r0                          @ 0819C9C6
    ldr r5, [r1]                             @ 0819C9C8
    movs r0, #2                              @ 0819C9CA
    ands r0, r2                              @ 0819C9CC
    cmp r0, #0                               @ 0819C9CE
    beq .L_0819C9F4                          @ 0819C9D0
    ldr r1, .Lit_0819CA28                    @ 0819C9D2
    adds r0, r1, #0                          @ 0819C9D4
    ands r0, r2                              @ 0819C9D6
    strh r0, [r4]                            @ 0819C9D8
    ldr r1, [r5, #0x18]                      @ 0819C9DA
    adds r0, r4, #0                          @ 0819C9DC
    bl _call_via_r1                          @ 0819C9DE
    ldrh r1, [r4]                            @ 0819C9E2
    movs r0, #0x80                           @ 0819C9E4
    ands r0, r1                              @ 0819C9E6
    cmp r0, #0                               @ 0819C9E8
    beq .L_0819C9F4                          @ 0819C9EA
    ldr r1, [r5]                             @ 0819C9EC
    adds r0, r4, #0                          @ 0819C9EE
    bl _call_via_r1                          @ 0819C9F0
.L_0819C9F4:
    mov r1, r8                               @ 0819C9F4
    ldr r0, [r1]                             @ 0819C9F6
    ldr r1, .Lit_0819CA2C                    @ 0819C9F8
    adds r0, r0, r1                          @ 0819C9FA
    adds r0, r0, r7                          @ 0819C9FC
    ldr r2, [r0]                             @ 0819C9FE
    adds r0, r4, #0                          @ 0819CA00
    adds r1, r5, #0                          @ 0819CA02
    bl trk_Step                              @ 0819CA04
.L_0819CA08:
    adds r6, #1                              @ 0819CA08
    cmp r6, #0xb                             @ 0819CA0A
    ble .L_0819C970                          @ 0819CA0C
.L_0819CA0E:
    ldr r2, [sp]                             @ 0819CA0E
    cmp r2, #2                               @ 0819CA10
    ble .L_0819C94A                          @ 0819CA12
    add sp, #4                               @ 0819CA14
    pop {r3, r4, r5}                         @ 0819CA16
    mov r8, r3                               @ 0819CA18
    mov sb, r4                               @ 0819CA1A
    mov sl, r5                               @ 0819CA1C
    pop {r4, r5, r6, r7}                     @ 0819CA1E
    pop {r0}                                 @ 0819CA20
    bx r0                                    @ 0819CA22
.Lit_0819CA24: .word 0x08A82058
.Lit_0819CA28: .word 0x0000FFFD
.Lit_0819CA2C: .word 0x000004A4

@ ---------------------------------------------------------------------------
@ snd_Frame: per-frame entry: queue, sequencer, PSG
    .global snd_Frame
    .thumb_func
snd_Frame:
    push {lr}                                @ 0819CA30
    bl snd_ProcessQueue                      @ 0819CA32
    bl snd_UpdatePlayers                     @ 0819CA36
    bl psg_UpdateAll                         @ 0819CA3A
    pop {r0}                                 @ 0819CA3E
    bx r0                                    @ 0819CA40
    .hword 0x0000   @ 0819CA42 alignment

@ ---------------------------------------------------------------------------
@ m_PlaySong: API: cmd 0 (player, song)
    .global m_PlaySong
    .thumb_func
m_PlaySong:
    push {lr}                                @ 0819CA44
    lsls r0, r0, #8                          @ 0819CA46
    orrs r0, r1                              @ 0819CA48
    lsls r0, r0, #0x10                       @ 0819CA4A
    lsrs r0, r0, #0x10                       @ 0819CA4C
    bl snd_QueueCommand                      @ 0819CA4E
    pop {r1}                                 @ 0819CA52
    bx r1                                    @ 0819CA54
    .hword 0x0000   @ 0819CA56 alignment

@ ---------------------------------------------------------------------------
@ m_StopPlayer: API: cmd 1
    .global m_StopPlayer
    .thumb_func
m_StopPlayer:
    push {lr}                                @ 0819CA58
    lsls r0, r0, #8                          @ 0819CA5A
    movs r2, #0x80                           @ 0819CA5C
    lsls r2, r2, #5                          @ 0819CA5E
    adds r1, r2, #0                          @ 0819CA60
    orrs r0, r1                              @ 0819CA62
    lsls r0, r0, #0x10                       @ 0819CA64
    lsrs r0, r0, #0x10                       @ 0819CA66
    bl snd_QueueCommand                      @ 0819CA68
    pop {r1}                                 @ 0819CA6C
    bx r1                                    @ 0819CA6E

@ ---------------------------------------------------------------------------
@ m_ResumePlayer: API: cmd 2
    .global m_ResumePlayer
    .thumb_func
m_ResumePlayer:
    push {lr}                                @ 0819CA70
    lsls r0, r0, #8                          @ 0819CA72
    movs r2, #0x80                           @ 0819CA74
    lsls r2, r2, #6                          @ 0819CA76
    adds r1, r2, #0                          @ 0819CA78
    orrs r0, r1                              @ 0819CA7A
    lsls r0, r0, #0x10                       @ 0819CA7C
    lsrs r0, r0, #0x10                       @ 0819CA7E
    bl snd_QueueCommand                      @ 0819CA80
    pop {r1}                                 @ 0819CA84
    bx r1                                    @ 0819CA86

@ ---------------------------------------------------------------------------
@ m_SetPlayerVolume: API: cmd 9
    .global m_SetPlayerVolume
    .thumb_func
m_SetPlayerVolume:
    push {lr}                                @ 0819CA88
    lsls r0, r0, #8                          @ 0819CA8A
    ldr r3, .Lit_0819CAA0                    @ 0819CA8C
    adds r2, r3, #0                          @ 0819CA8E
    orrs r0, r2                              @ 0819CA90
    orrs r0, r1                              @ 0819CA92
    lsls r0, r0, #0x10                       @ 0819CA94
    lsrs r0, r0, #0x10                       @ 0819CA96
    bl snd_QueueCommand                      @ 0819CA98
    pop {r1}                                 @ 0819CA9C
    bx r1                                    @ 0819CA9E
.Lit_0819CAA0: .word 0xFFFF9000

@ ---------------------------------------------------------------------------
@ m_PlaySfx: API: cmd 5
    .global m_PlaySfx
    .thumb_func
m_PlaySfx:
    push {lr}                                @ 0819CAA4
    movs r2, #0xa0                           @ 0819CAA6
    lsls r2, r2, #7                          @ 0819CAA8
    adds r1, r2, #0                          @ 0819CAAA
    orrs r0, r1                              @ 0819CAAC
    lsls r0, r0, #0x10                       @ 0819CAAE
    lsrs r0, r0, #0x10                       @ 0819CAB0
    bl snd_QueueCommand                      @ 0819CAB2
    pop {r1}                                 @ 0819CAB6
    bx r1                                    @ 0819CAB8
    .hword 0x0000   @ 0819CABA alignment

@ ---------------------------------------------------------------------------
@ m_StopSfx: API: cmd 6
    .global m_StopSfx
    .thumb_func
m_StopSfx:
    push {lr}                                @ 0819CABC
    movs r2, #0xc0                           @ 0819CABE
    lsls r2, r2, #7                          @ 0819CAC0
    adds r1, r2, #0                          @ 0819CAC2
    orrs r0, r1                              @ 0819CAC4
    lsls r0, r0, #0x10                       @ 0819CAC6
    lsrs r0, r0, #0x10                       @ 0819CAC8
    bl snd_QueueCommand                      @ 0819CACA
    pop {r1}                                 @ 0819CACE
    bx r1                                    @ 0819CAD0
    .hword 0x0000   @ 0819CAD2 alignment

@ ---------------------------------------------------------------------------
@ m_StopAllSfx: API: cmd 7
    .global m_StopAllSfx
    .thumb_func
m_StopAllSfx:
    push {lr}                                @ 0819CAD4
    movs r0, #0xe0                           @ 0819CAD6
    lsls r0, r0, #7                          @ 0819CAD8
    bl snd_QueueCommand                      @ 0819CADA
    pop {r1}                                 @ 0819CADE
    bx r1                                    @ 0819CAE0
    .hword 0x0000   @ 0819CAE2 alignment

@ ---------------------------------------------------------------------------
@ m_SetTempoDiv: API: cmd 8
    .global m_SetTempoDiv
    .thumb_func
m_SetTempoDiv:
    push {lr}                                @ 0819CAE4
    lsls r0, r0, #8                          @ 0819CAE6
    ldr r3, .Lit_0819CAFC                    @ 0819CAE8
    adds r2, r3, #0                          @ 0819CAEA
    orrs r0, r2                              @ 0819CAEC
    orrs r0, r1                              @ 0819CAEE
    lsls r0, r0, #0x10                       @ 0819CAF0
    lsrs r0, r0, #0x10                       @ 0819CAF2
    bl snd_QueueCommand                      @ 0819CAF4
    pop {r1}                                 @ 0819CAF8
    bx r1                                    @ 0819CAFA
.Lit_0819CAFC: .word 0xFFFF8000

@ ---------------------------------------------------------------------------
@ m_GetActivePlayers: bitmask of players with a sounding track
    .global m_GetActivePlayers
    .thumb_func
m_GetActivePlayers:
    push {r4, r5, r6, r7, lr}                @ 0819CB00
    mov r7, sl                               @ 0819CB02
    mov r6, sb                               @ 0819CB04
    mov r5, r8                               @ 0819CB06
    push {r5, r6, r7}                        @ 0819CB08
    movs r6, #0                              @ 0819CB0A
    movs r3, #0                              @ 0819CB0C
    ldr r0, .Lit_0819CB4C                    @ 0819CB0E
    mov sb, r0                               @ 0819CB10
    ldr r1, [r0]                             @ 0819CB12
    mov ip, r1                               @ 0819CB14
    ldr r0, .Lit_0819CB50                    @ 0819CB16
    add r0, ip                               @ 0819CB18
    mov sl, r0                               @ 0819CB1A
    movs r1, #1                              @ 0819CB1C
    mov r8, r1                               @ 0819CB1E
.L_0819CB20:
    mov r1, sl                               @ 0819CB20
    adds r0, r1, r3                          @ 0819CB22
    ldrb r1, [r0]                            @ 0819CB24
    mov r0, r8                               @ 0819CB26
    ands r0, r1                              @ 0819CB28
    adds r7, r3, #1                          @ 0819CB2A
    cmp r0, #0                               @ 0819CB2C
    beq .L_0819CB7A                          @ 0819CB2E
    movs r4, #0                              @ 0819CB30
    lsls r2, r3, #1                          @ 0819CB32
    adds r0, r2, r3                          @ 0819CB34
    lsls r0, r0, #7                          @ 0819CB36
    add r0, ip                               @ 0819CB38
    ldrh r1, [r0]                            @ 0819CB3A
    mov r0, r8                               @ 0819CB3C
    ands r0, r1                              @ 0819CB3E
    adds r5, r2, #0                          @ 0819CB40
    cmp r0, #0                               @ 0819CB42
    beq .L_0819CB54                          @ 0819CB44
    mov r0, r8                               @ 0819CB46
    b .L_0819CB76                            @ 0819CB48
    .hword 0x0000   @ 0819CB4A alignment
.Lit_0819CB4C: .word 0x03007FF0
.Lit_0819CB50: .word 0x00000494
.L_0819CB54:
    adds r4, #1                              @ 0819CB54
    cmp r4, #0xb                             @ 0819CB56
    bgt .L_0819CB7A                          @ 0819CB58
    mov r0, sb                               @ 0819CB5A
    ldr r2, [r0]                             @ 0819CB5C
    lsls r1, r4, #5                          @ 0819CB5E
    adds r0, r5, r3                          @ 0819CB60
    lsls r0, r0, #7                          @ 0819CB62
    adds r1, r1, r0                          @ 0819CB64
    adds r2, r2, r1                          @ 0819CB66
    ldrh r1, [r2]                            @ 0819CB68
    movs r2, #1                              @ 0819CB6A
    adds r0, r2, #0                          @ 0819CB6C
    ands r0, r1                              @ 0819CB6E
    cmp r0, #0                               @ 0819CB70
    beq .L_0819CB54                          @ 0819CB72
    adds r0, r2, #0                          @ 0819CB74
.L_0819CB76:
    lsls r0, r3                              @ 0819CB76
    orrs r6, r0                              @ 0819CB78
.L_0819CB7A:
    adds r3, r7, #0                          @ 0819CB7A
    cmp r3, #2                               @ 0819CB7C
    ble .L_0819CB20                          @ 0819CB7E
    adds r0, r6, #0                          @ 0819CB80
    pop {r3, r4, r5}                         @ 0819CB82
    mov r8, r3                               @ 0819CB84
    mov sb, r4                               @ 0819CB86
    mov sl, r5                               @ 0819CB88
    pop {r4, r5, r6, r7}                     @ 0819CB8A
    pop {r1}                                 @ 0819CB8C
    bx r1                                    @ 0819CB8E

@ ---------------------------------------------------------------------------
@ m_GetSfxTracks: bitmask of player-0 tracks playing SFX n
    .global m_GetSfxTracks
    .thumb_func
m_GetSfxTracks:
    push {r4, r5, r6, lr}                    @ 0819CB90
    adds r4, r0, #0                          @ 0819CB92
    movs r6, #0                              @ 0819CB94
    ldr r0, .Lit_0819CBF8                    @ 0819CB96
    ldr r2, [r0]                             @ 0819CB98
    ldr r1, .Lit_0819CBFC                    @ 0819CB9A
    adds r0, r2, r1                          @ 0819CB9C
    ldrb r1, [r0]                            @ 0819CB9E
    movs r5, #1                              @ 0819CBA0
    adds r0, r5, #0                          @ 0819CBA2
    ands r0, r1                              @ 0819CBA4
    cmp r0, #0                               @ 0819CBA6
    beq .L_0819CBF0                          @ 0819CBA8
    movs r3, #0                              @ 0819CBAA
    ldrh r1, [r2]                            @ 0819CBAC
    adds r0, r5, #0                          @ 0819CBAE
    ands r0, r1                              @ 0819CBB0
    cmp r0, #0                               @ 0819CBB2
    beq .L_0819CBC8                          @ 0819CBB4
    movs r5, #0x96                           @ 0819CBB6
    lsls r5, r5, #3                          @ 0819CBB8
    adds r0, r2, r5                          @ 0819CBBA
    ldrh r0, [r0]                            @ 0819CBBC
    cmp r0, r4                               @ 0819CBBE
    bne .L_0819CBF0                          @ 0819CBC0
.L_0819CBC2:
    movs r0, #1                              @ 0819CBC2
    lsls r0, r3                              @ 0819CBC4
    orrs r6, r0                              @ 0819CBC6
.L_0819CBC8:
    adds r3, #1                              @ 0819CBC8
    cmp r3, #0xb                             @ 0819CBCA
    bgt .L_0819CBF0                          @ 0819CBCC
    ldr r0, .Lit_0819CBF8                    @ 0819CBCE
    ldr r2, [r0]                             @ 0819CBD0
    lsls r0, r3, #5                          @ 0819CBD2
    adds r0, r2, r0                          @ 0819CBD4
    ldrh r1, [r0]                            @ 0819CBD6
    movs r0, #1                              @ 0819CBD8
    ands r0, r1                              @ 0819CBDA
    cmp r0, #0                               @ 0819CBDC
    beq .L_0819CBC8                          @ 0819CBDE
    lsls r0, r3, #1                          @ 0819CBE0
    movs r5, #0x96                           @ 0819CBE2
    lsls r5, r5, #3                          @ 0819CBE4
    adds r1, r2, r5                          @ 0819CBE6
    adds r1, r1, r0                          @ 0819CBE8
    ldrh r0, [r1]                            @ 0819CBEA
    cmp r0, r4                               @ 0819CBEC
    beq .L_0819CBC2                          @ 0819CBEE
.L_0819CBF0:
    adds r0, r6, #0                          @ 0819CBF0
    pop {r4, r5, r6}                         @ 0819CBF2
    pop {r1}                                 @ 0819CBF4
    bx r1                                    @ 0819CBF6
.Lit_0819CBF8: .word 0x03007FF0
.Lit_0819CBFC: .word 0x00000494
