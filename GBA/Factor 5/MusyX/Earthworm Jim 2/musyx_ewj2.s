@ =============================================================================
@  Factor 5 MusyX for Game Boy Advance -- sound driver code
@  Disassembled from: Earthworm Jim 2 (E) (M5).gba  (AGB-AJ4P)
@  Region: 0x08062830-0x08068BC4  (Thumb C code 0x08062830-0x08068173,
@          hand-written ARM mixer/echo routines 0x08068174-0x08068BC3,
@          which sndInit copies into IWRAM unless config flag bit 3 is set)
@
@  Rebuild (byte-identical to the ROM region):
@    arm-none-eabi-as -mcpu=arm7tdmi -o musyx_ewj2.o musyx_ewj2.s
@    arm-none-eabi-ld -Ttext=0x08062830 -e 0x08062830 -o musyx_ewj2.elf musyx_ewj2.o
@    arm-none-eabi-objcopy -O binary -j .text musyx_ewj2.elf musyx_ewj2.bin
@  Read-only tables live in musyx_ewj2_rodata.s (0x08725BCE and 0x087FFC68).
@
@  External symbols (.equ below) are libgcc helpers and the _call_via_rN
@  veneers linked after the driver; names are inferred from behaviour.
@  Function names are descriptive reconstructions (no symbols in the ROM).
@  Global driver state pointer: [0x03006830] (IWRAM) -> 0x13C-byte struct "G".
@  See the technical reference for the layout of G, voices and data formats.
@ =============================================================================
.syntax unified
.cpu arm7tdmi
.section .text
.global _start
.equ _call_via_r0, 0x08068bd0
.equ _call_via_r1, 0x08068bd4
.equ _call_via_r2, 0x08068bd8
.equ _call_via_r3, 0x08068bdc
.equ _call_via_r4, 0x08068be0
.equ _call_via_r5, 0x08068be4
.equ _call_via_r6, 0x08068be8
.equ _call_via_r7, 0x08068bec
.equ __divsi3, 0x08069040
.equ libgcc_080690d4, 0x080690d4
.equ __fixsfsi, 0x080690d8
.equ __udivsi3, 0x0806924c
.equ __umodsi3, 0x080692c4
.equ __addsf3, 0x08069634
.equ __divsf3, 0x080697f8
.equ __floatsisf, 0x08069ba0
.equ libgcc_08069c00, 0x08069c00
.thumb

.global sndInit
.thumb_func
.type sndInit, %function
sndInit:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r5, r0, #0
	adds r6, r1, #0
	mov r8, r2
	adds r7, r3, #0
	cmp r2, #0
	bne .L08062844
	b .L080629c8
.L08062844:
	cmp r7, #0
	bne .L0806284a
	b .L080629c8
.L0806284a:
	ldr r0, [r6]
	movs r1, #3
	ands r0, r1
	cmp r0, #0
	beq .L08062856
	b .L080629c8
.L08062856:
	ldr r0, [r6, #4]
	ands r0, r1
	cmp r0, #0
	beq .L08062860
	b .L080629c8
.L08062860:
	ldr r0, [r6, #8]
	ands r0, r1
	cmp r0, #0
	beq .L0806286a
	b .L080629c8
.L0806286a:
	ldr r0, [r6, #0xc]
	ands r0, r1
	cmp r0, #0
	beq .L08062874
	b .L080629c8
.L08062874:
	bl psg_HWInit
	ldr r0, L_080629c4
	ldr r1, [r6]
	str r1, [r0]
	movs r4, #0x9e
	lsls r4, r4, #1
	movs r0, #0
.L08062884:
	strb r0, [r1]
	adds r1, #1
	subs r4, #1
	cmp r4, #0
	bne .L08062884
	ldr r3, L_080629c4
	ldr r0, [r3]
	str r7, [r0, #4]
	mov r1, r8
	str r1, [r0]
	movs r1, #1
	str r1, [r0, #0xc]
	adds r0, #0xc2
	movs r1, #0xff
	strb r1, [r0]
	ldr r0, [r3]
	adds r1, #0x19
	adds r2, r0, r1
	ldr r1, [r5, #8]
	str r1, [r2]
	adds r0, #0xc3
	strb r4, [r0]
	ldr r2, [r3]
	movs r1, #0x80
	lsls r1, r1, #1
	strh r1, [r2, #0x14]
	strh r1, [r2, #0x16]
	adds r0, r2, #0
	adds r0, #0xc4
	strh r1, [r0]
	adds r0, #2
	strh r1, [r0]
	ldr r0, [r6]
	movs r4, #0x9e
	lsls r4, r4, #1
	adds r1, r0, r4
	subs r4, #0x20
	adds r0, r2, r4
	str r1, [r0]
	ldrb r2, [r5, #2]
	lsls r0, r2, #4
	adds r0, #0x40
	adds r2, r1, #0
	cmp r0, #0
	beq .L080628ea
	movs r4, #0
.L080628e0:
	strb r4, [r2]
	adds r2, #1
	subs r0, #1
	cmp r0, #0
	bne .L080628e0
.L080628ea:
	ldrb r0, [r5, #2]
	adds r0, #4
	lsls r0, r0, #4
	adds r1, r1, r0
	ldr r0, [r3]
	adds r0, #0xcc
	str r1, [r0]
	ldrb r4, [r5, #2]
	lsls r0, r4, #2
	adds r2, r1, #0
	cmp r0, #0
	beq .L0806290e
	movs r4, #0
.L08062904:
	strb r4, [r2]
	adds r2, #1
	subs r0, #1
	cmp r0, #0
	bne .L08062904
.L0806290e:
	ldrb r2, [r5, #2]
	lsls r0, r2, #2
	adds r1, r1, r0
	ldr r0, [r3]
	adds r0, #0xc8
	str r1, [r0]
	ldrb r4, [r5, #2]
	lsls r0, r4, #3
	subs r0, r0, r4
	lsls r0, r0, #2
	adds r2, r1, #0
	cmp r0, #0
	beq .L08062934
	movs r4, #0
.L0806292a:
	strb r4, [r2]
	adds r2, #1
	subs r0, #1
	cmp r0, #0
	bne .L0806292a
.L08062934:
	ldrb r2, [r5, #2]
	lsls r0, r2, #3
	subs r0, r0, r2
	lsls r0, r0, #2
	adds r1, r1, r0
	ldr r0, [r3]
	adds r0, #0xd4
	str r1, [r0]
	ldrb r4, [r5, #2]
	lsls r0, r4, #2
	adds r2, r1, #0
	cmp r0, #0
	beq .L0806295a
	movs r4, #0
.L08062950:
	strb r4, [r2]
	adds r2, #1
	subs r0, #1
	cmp r0, #0
	bne .L08062950
.L0806295a:
	ldrb r2, [r5, #2]
	lsls r0, r2, #2
	adds r1, r1, r0
	ldr r0, [r3]
	adds r0, #0xd0
	str r1, [r0]
	ldrb r4, [r5, #2]
	lsls r0, r4, #6
	adds r2, r1, #0
	cmp r0, #0
	beq .L0806297c
	movs r4, #0
.L08062972:
	strb r4, [r2]
	adds r2, #1
	subs r0, #1
	cmp r0, #0
	bne .L08062972
.L0806297c:
	ldrb r2, [r5, #2]
	lsls r0, r2, #6
	adds r1, r1, r0
	ldr r0, [r3]
	movs r4, #0x94
	lsls r4, r4, #1
	adds r0, r0, r4
	str r1, [r0]
	ldrb r2, [r5, #2]
	lsls r0, r2, #2
	adds r0, #0x10
	adds r2, r1, #0
	cmp r0, #0
	beq .L080629a4
	movs r3, #0
.L0806299a:
	strb r3, [r2]
	adds r2, #1
	subs r0, #1
	cmp r0, #0
	bne .L0806299a
.L080629a4:
	ldrb r0, [r5, #2]
	adds r0, #4
	lsls r0, r0, #2
	adds r1, r1, r0
	adds r0, r5, #0
	bl seq_Init
	cmp r0, #0
	beq .L080629c8
	adds r0, r5, #0
	adds r1, r6, #0
	bl snd_OutputInit
	movs r0, #1
	b .L080629ca
	.hword 0x0000
L_080629c4:
	.word 0x03006830
.L080629c8:
	movs r0, #0
.L080629ca:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndSetMusicMasterVolume
.thumb_func
.type sndSetMusicMasterVolume, %function
sndSetMusicMasterVolume:
	push {r4, r5, r6, r7, lr}
	lsls r0, r0, #0x18
	lsrs r3, r0, #0x18
	ldr r1, L_08062a60
	ldr r0, [r1]
	adds r2, r0, #0
	adds r2, #0xc4
	ldrh r5, [r2]
	strh r3, [r2]
	adds r4, r1, #0
	cmp r3, #0
	beq .L080629f0
	adds r0, r3, #1
	strh r0, [r2]
.L080629f0:
	ldr r0, [r4]
	adds r0, #0xc4
	ldrh r0, [r0]
	cmp r0, r5
	beq .L08062a5a
	movs r3, #0
	adds r7, r4, #0
	movs r6, #0x80
	lsls r6, r6, #9
	movs r5, #0x80
.L08062a04:
	ldr r0, [r7]
	lsls r1, r3, #2
	adds r0, #0x18
	adds r2, r0, r1
	ldr r1, [r2]
	adds r0, r1, #0
	ands r0, r6
	cmp r0, #0
	bne .L08062a1a
	orrs r1, r5
	str r1, [r2]
.L08062a1a:
	adds r3, #1
	cmp r3, #3
	ble .L08062a04
	movs r3, #0
	ldr r0, [r4]
	ldrb r0, [r0, #8]
	cmp r3, r0
	bge .L08062a5a
	adds r7, r4, #0
	movs r6, #0x80
	lsls r6, r6, #9
	movs r5, #0x80
.L08062a32:
	ldr r0, [r7]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r2, [r0]
	cmp r2, #0
	beq .L08062a50
	ldr r1, [r2, #0x38]
	adds r0, r1, #0
	ands r0, r6
	cmp r0, #0
	bne .L08062a50
	orrs r1, r5
	str r1, [r2, #0x38]
.L08062a50:
	adds r3, #1
	ldr r0, [r4]
	ldrb r0, [r0, #8]
	cmp r3, r0
	blt .L08062a32
.L08062a5a:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
L_08062a60:
	.word 0x03006830

.global sndSetFXMasterVolume
.thumb_func
.type sndSetFXMasterVolume, %function
sndSetFXMasterVolume:
	push {r4, r5, r6, r7, lr}
	lsls r0, r0, #0x18
	lsrs r3, r0, #0x18
	ldr r1, L_08062af0
	ldr r0, [r1]
	adds r2, r0, #0
	adds r2, #0xc6
	ldrh r5, [r2]
	strh r3, [r2]
	adds r4, r1, #0
	cmp r3, #0
	beq .L08062a80
	adds r0, r3, #1
	strh r0, [r2]
.L08062a80:
	ldr r0, [r4]
	adds r0, #0xc6
	ldrh r0, [r0]
	cmp r0, r5
	beq .L08062aea
	movs r3, #0
	adds r7, r4, #0
	movs r6, #0x80
	lsls r6, r6, #9
	movs r5, #0x80
.L08062a94:
	ldr r0, [r7]
	lsls r1, r3, #2
	adds r0, #0x18
	adds r2, r0, r1
	ldr r1, [r2]
	adds r0, r1, #0
	ands r0, r6
	cmp r0, #0
	beq .L08062aaa
	orrs r1, r5
	str r1, [r2]
.L08062aaa:
	adds r3, #1
	cmp r3, #3
	ble .L08062a94
	movs r3, #0
	ldr r0, [r4]
	ldrb r0, [r0, #8]
	cmp r3, r0
	bge .L08062aea
	adds r7, r4, #0
	movs r6, #0x80
	lsls r6, r6, #9
	movs r5, #0x80
.L08062ac2:
	ldr r0, [r7]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r2, [r0]
	cmp r2, #0
	beq .L08062ae0
	ldr r1, [r2, #0x38]
	adds r0, r1, #0
	ands r0, r6
	cmp r0, #0
	beq .L08062ae0
	orrs r1, r5
	str r1, [r2, #0x38]
.L08062ae0:
	adds r3, #1
	ldr r0, [r4]
	ldrb r0, [r0, #8]
	cmp r3, r0
	blt .L08062ac2
.L08062aea:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
L_08062af0:
	.word 0x03006830

.global sndSetEchoParams
.thumb_func
.type sndSetEchoParams, %function
sndSetEchoParams:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	lsls r0, r0, #0x10
	lsrs r6, r0, #0x10
	lsls r1, r1, #0x10
	lsrs r7, r1, #0x10
	lsls r2, r2, #0x10
	lsrs r2, r2, #0x10
	mov r8, r2
	ldr r4, L_08062b60
	ldr r0, [r4]
	adds r0, #0xc3
	ldrb r1, [r0]
	adds r1, #1
	strb r1, [r0]
	movs r5, #0xff
	lsls r1, r1, #0x18
	lsrs r1, r1, #0x18
	cmp r1, #1
	bne .L08062b26
	ldr r0, [r4]
	ldr r0, [r0]
	bl _call_via_r0
.L08062b26:
	ldr r1, [r4]
	movs r2, #0x88
	lsls r2, r2, #1
	adds r0, r1, r2
	strh r6, [r0]
	adds r2, #2
	adds r0, r1, r2
	strh r7, [r0]
	adds r2, #2
	adds r0, r1, r2
	mov r2, r8
	strh r2, [r0]
	adds r1, #0xc3
	ldrb r0, [r1]
	subs r0, #1
	strb r0, [r1]
	ands r0, r5
	cmp r0, #0
	bne .L08062b54
	ldr r0, [r4]
	ldr r0, [r0, #4]
	bl _call_via_r0
.L08062b54:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08062b60:
	.word 0x03006830

.global sndSilence
.thumb_func
.type sndSilence, %function
sndSilence:
	push {r4, r5, r6, r7, lr}
	ldr r2, L_08062c18
	ldr r0, [r2]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	ldr r3, L_08062c1c
	adds r1, r0, r3
	movs r0, #0
	strb r0, [r1]
	movs r4, #0
	ldr r0, [r2]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	bge .L08062bd4
	adds r7, r2, #0
	movs r5, #0
	movs r6, #0
.L08062b8c:
	ldr r2, [r7]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r2, r1
	ldr r1, [r0]
	lsls r0, r4, #4
	adds r0, r0, r1
	str r5, [r0]
	movs r3, #0x94
	lsls r3, r3, #1
	adds r0, r2, r3
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	str r5, [r0]
	adds r0, r4, #0
	bl voice_Silence
	ldr r0, [r7]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	movs r3, #0x88
	lsls r3, r3, #1
	adds r0, r0, r3
	ldr r0, [r0]
	adds r0, r6, r0
	strb r5, [r0, #4]
	adds r6, #0xc
	adds r4, #1
	ldr r0, [r7]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	blt .L08062b8c
.L08062bd4:
	movs r4, #0
	ldr r0, L_08062c18
	ldr r1, [r0]
	adds r6, r0, #0
	ldrb r1, [r1, #8]
	cmp r4, r1
	bge .L08062c08
	adds r5, r6, #0
	movs r3, #0
.L08062be6:
	ldr r2, [r5]
	adds r0, r2, #0
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	str r3, [r0]
	adds r0, r2, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r4, #6
	adds r0, r0, r1
	str r3, [r0, #0x38]
	adds r4, #1
	ldrb r2, [r2, #8]
	cmp r4, r2
	blt .L08062be6
.L08062c08:
	ldr r1, [r6]
	movs r0, #0
	strb r0, [r1, #9]
	bl snd_EchoClear
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
L_08062c18:
	.word 0x03006830
L_08062c1c:
	.word 0x00000151

.global sndQuit
.thumb_func
.type sndQuit, %function
sndQuit:
	push {r4, lr}
	ldr r4, L_08062c70
	ldr r1, [r4]
	adds r1, #0xc3
	ldrb r0, [r1]
	adds r0, #1
	strb r0, [r1]
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #1
	bne .L08062c3e
	ldr r0, [r4]
	ldr r0, [r0]
	bl _call_via_r0
.L08062c3e:
	bl sndSilence
	movs r2, #0
	ldr r1, [r4]
	ldrb r0, [r1, #8]
	cmp r0, #0
	beq .L08062c6a
	movs r3, #0x90
	lsls r3, r3, #1
	adds r0, r1, r3
	ldr r0, [r0]
	adds r3, #0x32
	adds r0, r0, r3
	ldrb r3, [r0]
	cmp r2, r3
	bls .L08062c60
	ldrb r2, [r0]
.L08062c60:
	strb r2, [r1, #8]
	cmp r2, #0
	bne .L08062c6a
	bl sndOutputStop
.L08062c6a:
	pop {r4}
	pop {r0}
	bx r0
L_08062c70:
	.word 0x03006830

.global sndFXStart
.thumb_func
.type sndFXStart, %function
sndFXStart:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #4
	adds r5, r0, #0
	mov r9, r1
	adds r7, r2, #0
	mov r8, r3
	ldr r1, L_08062cf0
	ldr r6, [r1]
	movs r2, #0x8c
	lsls r2, r2, #1
	adds r0, r6, r2
	ldr r2, [r0]
	ldr r0, [r2, #0xc]
	adds r4, r2, r0
	ldr r0, [r4]
	adds r3, r1, #0
	cmp r5, r0
	blo .L08062ca2
	b .L08062d98
.L08062ca2:
	lsls r0, r5, #3
	adds r0, #4
	adds r5, r4, r0
	ldr r0, [r2]
	ldrh r4, [r5]
	lsls r1, r4, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1]
	adds r2, r2, r0
	mov r10, r2
	ldrb r4, [r2]
	cmp r4, #0xff
	bne .L08062cc4
	ldrb r4, [r5, #4]
	cmp r4, #0xff
	beq .L08062ccc
.L08062cc4:
	ldrb r0, [r6, #8]
	adds r0, #4
	cmp r4, r0
	bge .L08062d98
.L08062ccc:
	mov r0, r9
	cmp r0, #0x7f
	ble .L08062cd6
	ldrb r1, [r5, #7]
	mov r9, r1
.L08062cd6:
	cmp r7, #0x7f
	ble .L08062cdc
	ldrb r7, [r5, #5]
.L08062cdc:
	ldr r0, [r3]
	ldrh r0, [r0, #0x16]
	muls r0, r7, r0
	asrs r7, r0, #8
	mov r2, r8
	cmp r2, #0x80
	ble .L08062cf4
	ldrb r0, [r5, #6]
	mov r8, r0
	b .L08062cfe
L_08062cf0:
	.word 0x03006830
.L08062cf4:
	mov r1, r8
	cmp r1, #0x80
	bne .L08062cfe
	movs r2, #0xff
	mov r8, r2
.L08062cfe:
	cmp r4, #3
	bgt .L08062d80
	ldrb r1, [r5, #2]
	movs r0, #1
	adds r2, r4, #0
	bl psg_VoiceAvail
	cmp r0, #0
	beq .L08062d98
	ldr r0, L_08062d50
	ldr r0, [r0]
	movs r2, #0x92
	lsls r2, r2, #1
	adds r1, r0, r2
	ldrh r0, [r1]
	adds r0, #1
	strh r0, [r1]
	lsls r0, r0, #0x10
	cmp r0, #0
	bne .L08062d2a
	movs r0, #1
	strh r0, [r1]
.L08062d2a:
	movs r0, #0x80
	mov r1, r10
	ldrb r1, [r1, #1]
	ands r0, r1
	cmp r0, #0
	bne .L08062d54
	movs r0, #0x80
	lsls r0, r0, #1
	ldrb r2, [r5, #2]
	orrs r0, r2
	str r0, [sp]
	adds r0, r4, #0
	mov r1, r9
	mov r2, r8
	adds r3, r7, #0
	bl psg_VoiceStart
	b .L08062d66
	.hword 0x0000
L_08062d50:
	.word 0x03006830
.L08062d54:
	movs r3, #0x80
	lsls r3, r3, #1
	ldrb r0, [r5, #2]
	orrs r3, r0
	adds r0, r4, #0
	mov r1, r9
	adds r2, r7, #0
	bl psg_VoiceLegato
.L08062d66:
	ldr r3, L_08062d7c
	ldr r1, [r3]
	lsls r0, r4, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0x80
	lsls r2, r2, #9
	orrs r0, r2
	str r0, [r1]
	b .L08062e16
L_08062d7c:
	.word 0x03006830
.L08062d80:
	cmp r4, #0xff
	beq .L08062d86
	subs r4, #4
.L08062d86:
	ldrb r1, [r5, #2]
	movs r0, #1
	movs r2, #0xff
	adds r3, r4, #0
	bl ds_VoiceAlloc
	adds r4, r0, #0
	cmp r4, #0
	bge .L08062d9c
.L08062d98:
	movs r0, #0
	b .L08062e8c
.L08062d9c:
	ldr r0, L_08062de4
	ldr r2, [r0]
	adds r0, r2, #0
	adds r0, #0xd0
	lsls r1, r4, #6
	ldr r0, [r0]
	adds r6, r0, r1
	movs r0, #0x92
	lsls r0, r0, #1
	adds r1, r2, r0
	ldrh r0, [r1]
	adds r0, #1
	strh r0, [r1]
	lsls r0, r0, #0x10
	cmp r0, #0
	bne .L08062dc0
	movs r0, #1
	strh r0, [r1]
.L08062dc0:
	movs r0, #0x80
	mov r1, r10
	ldrb r1, [r1, #1]
	ands r0, r1
	cmp r0, #0
	bne .L08062de8
	movs r0, #0x80
	lsls r0, r0, #1
	ldrb r2, [r5, #2]
	orrs r0, r2
	str r0, [sp]
	adds r0, r6, #0
	mov r1, r9
	mov r2, r8
	adds r3, r7, #0
	bl ds_VoiceStart
	b .L08062dfa
L_08062de4:
	.word 0x03006830
.L08062de8:
	movs r3, #0x80
	lsls r3, r3, #1
	ldrb r0, [r5, #2]
	orrs r3, r0
	adds r0, r6, #0
	mov r1, r9
	adds r2, r7, #0
	bl ds_VoiceLegato
.L08062dfa:
	ldr r0, [r6, #0x38]
	movs r1, #0x80
	lsls r1, r1, #9
	orrs r0, r1
	str r0, [r6, #0x38]
	ldr r2, L_08062e9c
	ldr r0, [r2]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	str r6, [r0]
	adds r4, #4
	adds r3, r2, #0
.L08062e16:
	ldr r0, [r3]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	movs r2, #0x88
	lsls r2, r2, #1
	adds r1, r1, r2
	lsls r0, r4, #1
	adds r0, r0, r4
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r1, r1, r0
	movs r2, #0
	strb r2, [r1, #4]
	movs r0, #0xff
	strb r0, [r1, #5]
	ldrb r0, [r5, #5]
	strb r0, [r1, #6]
	ldrb r0, [r5, #5]
	strb r0, [r1, #8]
	ldrb r0, [r5, #7]
	strb r0, [r1, #7]
	ldr r3, [r3]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r3, r1
	lsls r1, r4, #4
	ldr r0, [r0]
	adds r0, r0, r1
	strh r2, [r0, #8]
	strh r2, [r0, #0xa]
	str r2, [r0, #4]
	mov r1, r10
	adds r1, #4
	str r1, [r0]
	ldrh r1, [r5]
	strh r1, [r0, #0xc]
	ldr r1, [r3, #0xc]
	ldr r0, L_08062ea0
	muls r1, r0, r1
	str r1, [r3, #0xc]
	lsls r1, r1, #0xb
	lsrs r1, r1, #0x11
	movs r0, #0x92
	lsls r0, r0, #1
	adds r2, r3, r0
	lsls r0, r4, #0x10
	ldrh r2, [r2]
	orrs r0, r2
	lsls r1, r1, #0x18
	orrs r0, r1
	movs r2, #0x94
	lsls r2, r2, #1
	adds r1, r3, r2
	ldr r2, [r1]
	lsls r1, r4, #2
	adds r1, r1, r2
	str r0, [r1]
.L08062e8c:
	add sp, #4
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
L_08062e9c:
	.word 0x03006830
L_08062ea0:
	.word 0xa8351d63

.global sndFXVolume
.thumb_func
.type sndFXVolume, %function
sndFXVolume:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	adds r5, r1, #0
	cmp r4, #0
	beq .L08062ecc
	lsrs r3, r4, #0x10
	movs r0, #0xff
	ands r3, r0
	ldr r2, L_08062ed4
	ldr r0, [r2]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r0, [r0]
	adds r6, r2, #0
	cmp r0, r4
	beq .L08062ed8
.L08062ecc:
	movs r0, #1
	rsbs r0, r0, #0
	b .L08062f3c
	.hword 0x0000
L_08062ed4:
	.word 0x03006830
.L08062ed8:
	cmp r5, #0
	bge .L08062ee0
	movs r5, #0
	b .L08062ee6
.L08062ee0:
	cmp r5, #0x7f
	ble .L08062ee6
	movs r5, #0x7f
.L08062ee6:
	cmp r3, #3
	bgt .L08062f08
	lsls r0, r3, #3
	adds r0, #0x94
	ldr r1, [r6]
	adds r2, r1, r0
	ldrb r4, [r2, #7]
	strb r5, [r2, #7]
	ldr r1, [r6]
	lsls r0, r3, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1]
	b .L08062f3a
.L08062f08:
	subs r3, #4
	ldr r0, [r6]
	adds r0, #0xd0
	lsls r3, r3, #6
	ldr r0, [r0]
	adds r0, r0, r3
	adds r2, r0, #0
	adds r2, #0x24
	ldrb r0, [r2, #7]
	lsrs r4, r0, #1
	lsls r1, r5, #1
	strb r1, [r2, #7]
	lsls r0, r1, #0x18
	cmp r0, #0
	beq .L08062f2a
	adds r0, r1, #1
	strb r0, [r2, #7]
.L08062f2a:
	ldr r0, [r6]
	adds r0, #0xd0
	ldr r1, [r0]
	adds r1, r3, r1
	ldr r0, [r1, #0x38]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1, #0x38]
.L08062f3a:
	adds r0, r4, #0
.L08062f3c:
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000

.global sndFXPan
.thumb_func
.type sndFXPan, %function
sndFXPan:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	adds r3, r1, #0
	cmp r4, #0
	beq .L08062f6c
	lsrs r5, r4, #0x10
	movs r0, #0xff
	ands r5, r0
	ldr r2, L_08062f74
	ldr r0, [r2]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r5, #2
	adds r0, r0, r1
	ldr r0, [r0]
	adds r6, r2, #0
	cmp r0, r4
	beq .L08062f78
.L08062f6c:
	movs r0, #1
	rsbs r0, r0, #0
	b .L0806302e
	.hword 0x0000
L_08062f74:
	.word 0x03006830
.L08062f78:
	cmp r3, #0x80
	bne .L08062f80
	movs r3, #0xff
	b .L08062f8e
.L08062f80:
	cmp r3, #0
	bge .L08062f88
	movs r3, #0
	b .L08062f8e
.L08062f88:
	cmp r3, #0x7f
	ble .L08062f8e
	movs r3, #0x7f
.L08062f8e:
	cmp r5, #3
	bgt .L08063000
	movs r0, #0x88
	lsls r0, r0, #0x15
	lsls r0, r5
	lsrs r2, r0, #0x18
	ldr r1, [r6]
	adds r1, #0xc2
	adds r0, r2, #0
	ldrb r1, [r1]
	ands r0, r1
	asrs r0, r5
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	movs r4, #0x2a
	cmp r0, #0x10
	beq .L08062fb8
	movs r4, #0x40
	cmp r0, #1
	bne .L08062fb8
	movs r4, #0x55
.L08062fb8:
	ldr r0, [r6]
	adds r0, #0xc2
	ldrb r1, [r0]
	bics r1, r2
	strb r1, [r0]
	cmp r3, #0xff
	beq .L08062fdc
	cmp r3, #0x29
	bgt .L08062fd0
	movs r0, #0x80
	lsls r0, r0, #0x15
	b .L08062fd8
.L08062fd0:
	cmp r3, #0x55
	ble .L08062fdc
	movs r0, #0x80
	lsls r0, r0, #0x11
.L08062fd8:
	lsls r0, r5
	lsrs r2, r0, #0x18
.L08062fdc:
	ldr r0, [r6]
	adds r0, #0xc2
	ldrb r1, [r0]
	orrs r2, r1
	strb r2, [r0]
	ldr r2, L_08062ffc
	ldrh r0, [r2]
	movs r1, #0xff
	ands r1, r0
	ldr r0, [r6]
	adds r0, #0xc2
	ldrb r0, [r0]
	lsls r0, r0, #8
	orrs r1, r0
	strh r1, [r2]
	b .L08063026
L_08062ffc:
	.word 0x04000080
.L08063000:
	ldr r1, [r6]
	adds r1, #0xd0
	lsls r0, r5, #6
	ldr r2, L_08063034
	adds r0, r0, r2
	ldr r1, [r1]
	adds r2, r1, r0
	adds r0, r2, #0
	adds r0, #0x3c
	ldrb r4, [r0]
	strb r3, [r0]
	lsls r0, r3, #0x18
	lsrs r0, r0, #0x18
	cmp r0, r4
	beq .L08063026
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	orrs r0, r1
	str r0, [r2, #0x38]
.L08063026:
	cmp r4, #0x7f
	ble .L0806302c
	movs r4, #0x80
.L0806302c:
	adds r0, r4, #0
.L0806302e:
	pop {r4, r5, r6}
	pop {r1}
	bx r1
L_08063034:
	.word 0xffffff00

.global sndFXGetPan
.thumb_func
.type sndFXGetPan, %function
sndFXGetPan:
	push {r4, lr}
	adds r3, r0, #0
	cmp r3, #0
	beq .L0806305c
	lsrs r2, r3, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r0, L_08063064
	ldr r4, [r0]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r4, r1
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, r3
	beq .L08063068
.L0806305c:
	movs r0, #1
	rsbs r0, r0, #0
	b .L080630a6
	.hword 0x0000
L_08063064:
	.word 0x03006830
.L08063068:
	cmp r2, #3
	bgt .L08063092
	movs r0, #0x88
	lsls r0, r0, #0x15
	lsls r0, r2
	lsrs r0, r0, #0x18
	adds r1, r4, #0
	adds r1, #0xc2
	ldrb r1, [r1]
	ands r0, r1
	asrs r0, r2
	lsls r0, r0, #0x18
	lsrs r1, r0, #0x18
	movs r0, #0x2a
	cmp r1, #0x10
	beq .L080630a0
	movs r0, #0x40
	cmp r1, #1
	bne .L080630a0
	movs r0, #0x55
	b .L080630a0
.L08063092:
	adds r0, r4, #0
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r1, r1, r0
	subs r1, #0xc4
	ldrb r0, [r1]
.L080630a0:
	cmp r0, #0x7f
	ble .L080630a6
	movs r0, #0x80
.L080630a6:
	pop {r4}
	pop {r1}
	bx r1

.global sndFXPitch
.thumb_func
.type sndFXPitch, %function
sndFXPitch:
	push {r4, r5, r6, lr}
	adds r3, r0, #0
	lsls r1, r1, #0x10
	lsrs r5, r1, #0x10
	adds r6, r5, #0
	cmp r3, #0
	beq .L080630da
	lsrs r2, r3, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r0, L_080630e0
	ldr r1, [r0]
	movs r4, #0x94
	lsls r4, r4, #1
	adds r0, r1, r4
	ldr r0, [r0]
	lsls r4, r2, #2
	adds r0, r4, r0
	ldr r0, [r0]
	cmp r0, r3
	bne .L080630da
	cmp r2, #3
	bne .L080630e4
.L080630da:
	movs r0, #0
	b .L0806311e
	.hword 0x0000
L_080630e0:
	.word 0x03006830
.L080630e4:
	cmp r2, #2
	bgt .L08063102
	lsls r0, r2, #3
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, r1, r0
	ldrh r3, [r0, #0x28]
	strh r5, [r0, #0x28]
	adds r1, #0x18
	adds r1, r1, r4
	ldr r0, [r1]
	movs r2, #0x40
	orrs r0, r2
	str r0, [r1]
	b .L0806311c
.L08063102:
	subs r2, #4
	adds r1, #0xd0
	ldr r0, [r1]
	lsls r2, r2, #6
	adds r0, r2, r0
	ldrh r3, [r0]
	strh r6, [r0]
	ldr r0, [r1]
	adds r2, r2, r0
	ldr r0, [r2, #0x38]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2, #0x38]
.L0806311c:
	adds r0, r3, #0
.L0806311e:
	pop {r4, r5, r6}
	pop {r1}
	bx r1

.global sndStreamStart
.thumb_func
.type sndStreamStart, %function
sndStreamStart:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0x1c
	mov r8, r0
	str r1, [sp, #0x10]
	str r2, [sp, #0x14]
	str r3, [sp, #0x18]
	cmp r0, #3
	bgt .L08063232
	lsls r0, r0, #2
	movs r1, #0x96
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r2, L_08063204
	ldr r1, [r2]
	adds r7, r1, r0
	ldr r0, [r7]
	mov r9, r0
	cmp r0, #0
	bne .L08063232
	movs r1, #0x80
	lsls r1, r1, #5
	mov r10, r1
	movs r0, #1
	movs r2, #0xff
	movs r3, #0xff
	bl ds_VoiceAlloc
	adds r6, r0, #0
	cmp r6, #0
	blt .L08063232
	ldr r2, L_08063204
	ldr r1, [r2]
	adds r0, r1, #0
	adds r0, #0xcc
	ldr r0, [r0]
	lsls r5, r6, #2
	adds r0, r5, r0
	mov r2, r9
	str r2, [r0]
	adds r1, #0xd0
	lsls r0, r6, #6
	ldr r4, [r1]
	adds r4, r4, r0
	mov r0, r10
	str r0, [sp]
	adds r0, r4, #0
	movs r1, #0
	ldr r2, [sp, #0x3c]
	ldr r3, [sp, #0x18]
	bl ds_VoiceStart
	ldr r0, [r4, #0x38]
	movs r1, #0xc0
	lsls r1, r1, #0xa
	orrs r0, r1
	str r0, [r4, #0x38]
	adds r0, r4, #0
	adds r0, #0x3e
	mov r1, r8
	strb r1, [r0]
	ldr r2, L_08063204
	ldr r1, [r2]
	adds r0, r1, #0
	adds r0, #0xd4
	ldr r0, [r0]
	adds r5, r5, r0
	str r4, [r5]
	ldr r0, [sp, #0x10]
	str r0, [r7]
	ldr r2, [sp, #0x14]
	lsls r0, r2, #0xc
	ldrh r1, [r1, #0xa]
	bl __udivsi3
	lsls r0, r0, #0x10
	lsrs r5, r0, #0x10
	lsrs r0, r0, #0x15
	adds r0, #2
	add r2, sp, #8
	add r3, sp, #0xc
	mov r1, r8
	str r1, [sp]
	ldr r4, [r7]
	add r1, sp, #4
	bl _call_via_r4
	adds r4, r0, #0
	ldr r2, L_08063204
	ldr r3, [r2]
	adds r1, r3, #0
	adds r1, #0xc8
	lsls r0, r6, #3
	subs r0, r0, r6
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r2, r1, r0
	strh r5, [r2, #0x14]
	mov r0, r9
	strh r0, [r2, #0x16]
	ldr r0, [sp, #0x40]
	cmp r0, #0
	beq .L08063208
	movs r1, #0x8b
	lsls r1, r1, #1
	adds r0, r3, r1
	ldrb r0, [r0]
	b .L0806320a
	.hword 0x0000
L_08063204:
	.word 0x03006830
.L08063208:
	movs r0, #0
.L0806320a:
	movs r1, #0
	strb r0, [r2, #0x1b]
	str r1, [r2]
	ldr r0, [sp, #4]
	str r0, [r2, #4]
	ldr r0, [sp, #4]
	adds r0, r0, r4
	str r0, [r2, #8]
	str r1, [r2, #0xc]
	str r1, [r2, #0x10]
	adds r0, r6, #0
	bl voice_CalcMixVolume
	lsls r1, r6, #0x10
	mov r2, r8
	orrs r1, r2
	movs r0, #0x80
	lsls r0, r0, #0x18
	orrs r0, r1
	b .L08063234
.L08063232:
	movs r0, #0
.L08063234:
	add sp, #0x1c
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndStreamVolume
.thumb_func
.type sndStreamVolume, %function
sndStreamVolume:
	push {r4, lr}
	adds r4, r1, #0
	cmp r0, #0
	beq .L0806328a
	lsrs r2, r0, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r3, L_08063290
	ldr r0, [r3]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r2, r2, #6
	adds r1, r2, r1
	lsls r0, r4, #1
	adds r1, #0x2b
	strb r0, [r1]
	lsls r0, r0, #0x18
	cmp r0, #0
	beq .L0806327a
	ldr r0, [r3]
	adds r0, #0xd0
	ldr r0, [r0]
	adds r0, r2, r0
	adds r0, #0x2b
	ldrb r1, [r0]
	adds r1, #1
	strb r1, [r0]
.L0806327a:
	ldr r0, [r3]
	adds r0, #0xd0
	ldr r1, [r0]
	adds r1, r2, r1
	ldr r0, [r1, #0x38]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1, #0x38]
.L0806328a:
	pop {r4}
	pop {r0}
	bx r0
L_08063290:
	.word 0x03006830

.global snd_StreamRefill
.thumb_func
.type snd_StreamRefill, %function
snd_StreamRefill:
	push {r4, r5, r6, r7, lr}
	sub sp, #0x10
	adds r5, r1, #0
	ldr r1, L_080632cc
	ldr r2, [r1]
	adds r1, r2, #0
	adds r1, #0xd0
	ldr r1, [r1]
	lsls r0, r0, #6
	adds r0, r0, r1
	adds r0, #0x3e
	ldrb r4, [r0]
	lsls r0, r4, #2
	movs r1, #0x96
	lsls r1, r1, #1
	adds r0, r0, r1
	adds r7, r2, r0
	ldr r2, [r7]
	cmp r2, #0
	bne .L080632d0
	ldr r1, [r5, #4]
	ldr r0, [r5, #8]
	cmp r1, r0
	bhs .L0806333a
	str r2, [r5, #0xc]
	str r2, [r5, #0x10]
	b .L0806333a
	.hword 0x0000
L_080632cc:
	.word 0x03006830
.L080632d0:
	ldr r1, [r5, #8]
	ldr r0, [r5, #4]
	subs r1, r1, r0
	subs r1, #1
	movs r0, #0
	str r0, [r5, #0x10]
	str r0, [r5, #0xc]
	ldrh r2, [r5, #0x14]
	lsls r0, r2, #7
	ldrh r2, [r5, #0x16]
	adds r0, r2, r0
	ldr r2, L_0806331c
	adds r0, r0, r2
	asrs r0, r0, #0xc
	subs r6, r0, r1
	cmp r6, #0
	ble .L0806333a
	add r2, sp, #8
	add r3, sp, #0xc
	str r4, [sp]
	ldr r4, [r7]
	adds r0, r6, #0
	add r1, sp, #4
	bl _call_via_r4
	adds r3, r0, #0
	ldr r2, [sp, #8]
	cmp r2, #0
	bne .L08063324
	ldr r2, [sp, #4]
	adds r1, r2, r3
	ldr r0, [r5, #4]
	cmp r1, r0
	bhs .L08063320
	str r2, [r5, #0xc]
	str r3, [r5, #0x10]
	b .L08063332
	.hword 0x0000
L_0806331c:
	.word 0x00000fff
.L08063320:
	str r1, [r5, #8]
	b .L08063332
.L08063324:
	ldr r0, [sp, #4]
	ldr r1, [sp, #0xc]
	adds r0, r0, r1
	str r0, [r5, #8]
	str r2, [r5, #0xc]
	subs r1, r3, r1
	str r1, [r5, #0x10]
.L08063332:
	cmp r3, r6
	bge .L0806333a
	movs r0, #0
	str r0, [r7]
.L0806333a:
	add sp, #0x10
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global sndSetActiveVoices
.thumb_func
.type sndSetActiveVoices, %function
sndSetActiveVoices:
	push {r4, lr}
	lsls r0, r0, #0x18
	lsrs r1, r0, #0x18
	ldr r0, L_08063374
	ldr r2, [r0]
	ldrb r3, [r2, #8]
	cmp r3, r1
	beq .L08063380
	movs r4, #0x90
	lsls r4, r4, #1
	adds r0, r2, r4
	ldr r0, [r0]
	adds r4, #0x32
	adds r0, r0, r4
	ldrb r4, [r0]
	cmp r1, r4
	bls .L08063368
	ldrb r1, [r0]
.L08063368:
	strb r1, [r2, #8]
	cmp r1, #0
	bne .L08063378
	bl sndOutputStop
	b .L08063380
L_08063374:
	.word 0x03006830
.L08063378:
	cmp r3, #0
	bne .L08063380
	bl sndOutputResume
.L08063380:
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000

.global sndFXKeyOff
.thumb_func
.type sndFXKeyOff, %function
sndFXKeyOff:
	push {lr}
	adds r3, r0, #0
	cmp r3, #0
	beq .L080633bc
	lsrs r2, r3, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r0, L_080633b8
	ldr r0, [r0]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, r3
	bne .L080633bc
	adds r0, r2, #0
	bl voice_KeyOff
	movs r0, #1
	b .L080633be
	.hword 0x0000
L_080633b8:
	.word 0x03006830
.L080633bc:
	movs r0, #0
.L080633be:
	pop {r1}
	bx r1
	.hword 0x0000

.global sndKeyOffAll
.thumb_func
.type sndKeyOffAll, %function
sndKeyOffAll:
	push {r4, r5, r6, lr}
	ldr r0, L_08063408
	ldr r0, [r0]
	movs r1, #0x92
	lsls r1, r1, #1
	adds r6, r0, r1
	movs r5, #0
	movs r4, #0
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r5, r0
	bge .L080633fe
.L080633dc:
	ldr r0, [r6, #4]
	lsls r1, r4, #2
	adds r1, r1, r0
	ldr r0, [r1]
	cmp r0, #0
	beq .L080633f0
	adds r0, r4, #0
	bl voice_KeyOff
	adds r5, #1
.L080633f0:
	adds r4, #1
	ldr r0, L_08063408
	ldr r0, [r0]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	blt .L080633dc
.L080633fe:
	adds r0, r5, #0
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000
L_08063408:
	.word 0x03006830

.global sndFXCheck
.thumb_func
.type sndFXCheck, %function
sndFXCheck:
	adds r3, r0, #0
	cmp r3, #0
	beq .L0806344c
	lsrs r2, r3, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r0, L_08063448
	ldr r0, [r0]
	mov r12, r0
	movs r0, #0x94
	lsls r0, r0, #1
	add r0, r12
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, r3
	bne .L0806344c
	movs r0, #0x8e
	lsls r0, r0, #1
	add r0, r12
	ldr r1, [r0]
	lsls r0, r2, #4
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, #0
	beq .L0806344c
	movs r0, #1
	b .L0806344e
	.hword 0x0000
L_08063448:
	.word 0x03006830
.L0806344c:
	movs r0, #0
.L0806344e:
	bx lr

.global sndFXGetVolume
.thumb_func
.type sndFXGetVolume, %function
sndFXGetVolume:
	push {r4, lr}
	adds r3, r0, #0
	cmp r3, #0
	beq .L08063474
	lsrs r2, r3, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r0, L_0806347c
	ldr r4, [r0]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r4, r1
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, r3
	beq .L08063480
.L08063474:
	movs r0, #1
	rsbs r0, r0, #0
	b .L080634a0
	.hword 0x0000
L_0806347c:
	.word 0x03006830
.L08063480:
	cmp r2, #3
	bgt .L0806348e
	lsls r0, r2, #3
	adds r0, #0x94
	adds r0, r4, r0
	ldrb r0, [r0, #7]
	b .L080634a0
.L0806348e:
	subs r2, #4
	adds r0, r4, #0
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r0, r0, r1
	adds r0, #0x24
	ldrb r0, [r0, #7]
	lsrs r0, r0, #1
.L080634a0:
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000

.global sndFXGetPitch
.thumb_func
.type sndFXGetPitch, %function
sndFXGetPitch:
	push {r4, lr}
	adds r3, r0, #0
	cmp r3, #0
	beq .L080634e4
	lsrs r2, r3, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r0, L_080634dc
	ldr r4, [r0]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r4, r1
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, r3
	bne .L080634e4
	cmp r2, #2
	bgt .L080634e0
	lsls r0, r2, #3
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, r4, r0
	ldrh r0, [r0, #0x28]
	b .L080634f8
L_080634dc:
	.word 0x03006830
.L080634e0:
	cmp r2, #3
	bgt .L080634e8
.L080634e4:
	movs r0, #0
	b .L080634f8
.L080634e8:
	adds r0, r4, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_08063500
	adds r0, r0, r1
	ldrh r0, [r0]
.L080634f8:
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000
L_08063500:
	.word 0xffffff00

.global sndSetReverb
.thumb_func
.type sndSetReverb, %function
sndSetReverb:
	adds r1, r0, #0
	cmp r1, #0
	bne .L0806351c
	ldr r0, L_08063518
	ldr r0, [r0]
	movs r2, #0x8b
	lsls r2, r2, #1
	adds r0, r0, r2
	strb r1, [r0]
	b .L08063534
L_08063518:
	.word 0x03006830
.L0806351c:
	ldr r0, L_08063538
	ldr r2, [r0]
	adds r0, r2, #0
	adds r0, #0xfc
	ldr r1, [r0]
	rsbs r0, r1, #0
	orrs r0, r1
	lsrs r0, r0, #0x1f
	movs r3, #0x8b
	lsls r3, r3, #1
	adds r1, r2, r3
	strb r0, [r1]
.L08063534:
	bx lr
	.hword 0x0000
L_08063538:
	.word 0x03006830

.global sndGetFlags
.thumb_func
.type sndGetFlags, %function
sndGetFlags:
	ldr r0, L_08063544
	ldr r0, [r0]
	ldr r0, [r0, #0x10]
	bx lr
L_08063544:
	.word 0x03006830

.global sndSetFlags
.thumb_func
.type sndSetFlags, %function
sndSetFlags:
	adds r2, r0, #0
	ldr r0, L_08063558
	ldr r1, [r0]
	ldr r0, [r1, #0x10]
	eors r0, r2
	str r2, [r1, #0x10]
	bx lr
	.hword 0x0000
L_08063558:
	.word 0x03006830

.global sndTestFlag
.thumb_func
.type sndTestFlag, %function
sndTestFlag:
	ldr r1, L_08063570
	ldr r2, [r1]
	movs r1, #1
	lsls r1, r0
	ldr r0, [r2, #0x10]
	ands r0, r1
	cmp r0, #0
	beq .L0806356e
	movs r0, #1
.L0806356e:
	bx lr
L_08063570:
	.word 0x03006830

.global sndSetFlag
.thumb_func
.type sndSetFlag, %function
sndSetFlag:
	movs r1, #1
	lsls r1, r0
	ldr r0, L_08063590
	ldr r2, [r0]
	ldr r3, [r2, #0x10]
	adds r0, r3, #0
	orrs r0, r1
	str r0, [r2, #0x10]
	adds r0, r3, #0
	ands r0, r1
	cmp r0, #0
	beq .L0806358e
	movs r0, #1
.L0806358e:
	bx lr
L_08063590:
	.word 0x03006830

.global sndClearFlag
.thumb_func
.type sndClearFlag, %function
sndClearFlag:
	movs r1, #1
	lsls r1, r0
	ldr r0, L_080635b0
	ldr r2, [r0]
	ldr r3, [r2, #0x10]
	adds r0, r3, #0
	bics r0, r1
	str r0, [r2, #0x10]
	adds r0, r3, #0
	ands r0, r1
	cmp r0, #0
	beq .L080635ae
	movs r0, #1
.L080635ae:
	bx lr
L_080635b0:
	.word 0x03006830

.global sndSetSongVelScale
.thumb_func
.type sndSetSongVelScale, %function
sndSetSongVelScale:
	lsls r0, r0, #0x18
	lsrs r1, r0, #0x18
	ldr r0, L_080635c8
	ldr r2, [r0]
	strh r1, [r2, #0x14]
	cmp r1, #0
	beq .L080635c6
	adds r0, r1, #1
	strh r0, [r2, #0x14]
.L080635c6:
	bx lr
L_080635c8:
	.word 0x03006830

.global sndSetFXVelScale
.thumb_func
.type sndSetFXVelScale, %function
sndSetFXVelScale:
	lsls r0, r0, #0x18
	lsrs r1, r0, #0x18
	ldr r0, L_080635e0
	ldr r2, [r0]
	strh r1, [r2, #0x16]
	cmp r1, #0
	beq .L080635de
	adds r0, r1, #1
	strh r0, [r2, #0x16]
.L080635de:
	bx lr
L_080635e0:
	.word 0x03006830

.global sndSetSOUNDCNT_H_lo
.thumb_func
.type sndSetSOUNDCNT_H_lo, %function
sndSetSOUNDCNT_H_lo:
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	ldr r1, L_080635f0
	strb r0, [r1]
	bx lr
	.hword 0x0000
L_080635f0:
	.word 0x04000082

.global sndSetPSGMasterVolume
.thumb_func
.type sndSetPSGMasterVolume, %function
sndSetPSGMasterVolume:
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	ldr r2, L_08063604
	movs r1, #0x77
	ands r0, r1
	strb r0, [r2]
	bx lr
	.hword 0x0000
L_08063604:
	.word 0x04000080

.global snd_memclr
.thumb_func
.type snd_memclr, %function
snd_memclr:
	cmp r1, #0
	beq .L08063618
	movs r2, #0
.L0806360e:
	strb r2, [r0]
	adds r0, #1
	subs r1, #1
	cmp r1, #0
	bne .L0806360e
.L08063618:
	bx lr
	.hword 0x0000

.global snd_memcpy
.thumb_func
.type snd_memcpy, %function
snd_memcpy:
	adds r3, r0, #0
	cmp r2, #0
	beq .L08063630
.L08063622:
	ldrb r0, [r1]
	strb r0, [r3]
	adds r1, #1
	adds r3, #1
	subs r2, #1
	cmp r2, #0
	bne .L08063622
.L08063630:
	bx lr
	.hword 0x0000

.global snd_RandRaw
.thumb_func
.type snd_RandRaw, %function
snd_RandRaw:
	ldr r0, L_08063648
	ldr r2, [r0]
	ldr r1, [r2, #0xc]
	ldr r0, L_0806364c
	muls r0, r1, r0
	str r0, [r2, #0xc]
	lsls r0, r0, #0xb
	lsrs r0, r0, #0x11
	bx lr
	.hword 0x0000
L_08063648:
	.word 0x03006830
L_0806364c:
	.word 0xa8351d63

.global snd_Rand
.thumb_func
.type snd_Rand, %function
snd_Rand:
	push {lr}
	lsls r0, r0, #0x10
	lsrs r3, r0, #0x10
	ldr r0, L_08063678
	ldr r2, [r0]
	ldr r1, [r2, #0xc]
	ldr r0, L_0806367c
	muls r0, r1, r0
	str r0, [r2, #0xc]
	lsls r0, r0, #0xa
	lsrs r0, r0, #0x10
	cmp r0, r3
	bls .L08063674
	adds r1, r3, #0
	bl __umodsi3
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
.L08063674:
	pop {r1}
	bx r1
L_08063678:
	.word 0x03006830
L_0806367c:
	.word 0xa8351d63

.global snd_Unlock
.thumb_func
.type snd_Unlock, %function
snd_Unlock:
	push {lr}
	ldr r2, L_080636a0
	ldr r0, [r2]
	adds r0, #0xc3
	ldrb r1, [r0]
	subs r1, #1
	strb r1, [r0]
	lsls r1, r1, #0x18
	cmp r1, #0
	bne .L0806369c
	ldr r0, [r2]
	ldr r0, [r0, #4]
	bl _call_via_r0
.L0806369c:
	pop {r0}
	bx r0
L_080636a0:
	.word 0x03006830

.global snd_Lock
.thumb_func
.type snd_Lock, %function
snd_Lock:
	push {lr}
	ldr r2, L_080636c8
	ldr r1, [r2]
	adds r1, #0xc3
	ldrb r0, [r1]
	adds r0, #1
	strb r0, [r1]
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #1
	bne .L080636c2
	ldr r0, [r2]
	ldr r0, [r0]
	bl _call_via_r0
.L080636c2:
	pop {r0}
	bx r0
	.hword 0x0000
L_080636c8:
	.word 0x03006830

.global sndStreamActivate
.thumb_func
.type sndStreamActivate, %function
sndStreamActivate:
	push {r4, lr}
	cmp r0, #0
	beq .L080636f4
	lsrs r3, r0, #0x10
	movs r0, #0xff
	ands r3, r0
	ldr r0, L_080636fc
	ldr r2, [r0]
	adds r0, r2, #0
	adds r0, #0xcc
	ldr r0, [r0]
	lsls r4, r3, #2
	adds r4, r4, r0
	adds r2, #0xc8
	lsls r1, r3, #3
	subs r1, r1, r3
	lsls r1, r1, #2
	ldr r0, [r2]
	adds r0, r0, r1
	str r0, [r4]
.L080636f4:
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000
L_080636fc:
	.word 0x03006830

.global sndStreamFree
.thumb_func
.type sndStreamFree, %function
sndStreamFree:
	cmp r0, #0
	beq .L08063738
	ldr r3, L_0806373c
	ands r3, r0
	lsrs r1, r0, #0x10
	movs r0, #0xff
	ands r1, r0
	ldr r0, L_08063740
	ldr r0, [r0]
	mov r12, r0
	adds r0, #0xcc
	ldr r2, [r0]
	lsls r0, r1, #2
	adds r0, r0, r2
	movs r2, #0
	str r2, [r0]
	lsls r3, r3, #2
	movs r0, #0x96
	lsls r0, r0, #1
	add r0, r12
	adds r0, r0, r3
	str r2, [r0]
	mov r0, r12
	adds r0, #0xd0
	ldr r0, [r0]
	lsls r1, r1, #6
	adds r1, r1, r0
	str r2, [r1, #0x38]
.L08063738:
	bx lr
	.hword 0x0000
L_0806373c:
	.word 0x0000ffff
L_08063740:
	.word 0x03006830

.global sndStreamPan
.thumb_func
.type sndStreamPan, %function
sndStreamPan:
	adds r3, r1, #0
	cmp r0, #0
	beq .L08063770
	lsrs r2, r0, #0x10
	movs r0, #0xff
	ands r2, r0
	ldr r1, L_08063774
	ldr r0, [r1]
	adds r0, #0xd0
	ldr r0, [r0]
	lsls r2, r2, #6
	adds r0, r2, r0
	adds r0, #0x3c
	strb r3, [r0]
	ldr r0, [r1]
	adds r0, #0xd0
	ldr r0, [r0]
	adds r2, r2, r0
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	orrs r0, r1
	str r0, [r2, #0x38]
.L08063770:
	bx lr
	.hword 0x0000
L_08063774:
	.word 0x03006830

.global sndStreamReverb
.thumb_func
.type sndStreamReverb, %function
sndStreamReverb:
	push {r4, lr}
	adds r4, r1, #0
	cmp r0, #0
	beq .L080637b0
	lsrs r1, r0, #0x10
	movs r0, #0xff
	ands r1, r0
	ldr r0, L_080637a8
	ldr r3, [r0]
	adds r2, r3, #0
	adds r2, #0xc8
	lsls r0, r1, #3
	subs r0, r0, r1
	lsls r0, r0, #2
	ldr r1, [r2]
	adds r1, r1, r0
	cmp r4, #0
	beq .L080637ac
	movs r0, #0x8b
	lsls r0, r0, #1
	adds r2, r3, r0
	ldrb r0, [r2]
	b .L080637ae
	.hword 0x0000
L_080637a8:
	.word 0x03006830
.L080637ac:
	movs r0, #0
.L080637ae:
	strb r0, [r1, #0x1b]
.L080637b0:
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000

.global sndStreamCalcBlocks
.thumb_func
.type sndStreamCalcBlocks, %function
sndStreamCalcBlocks:
	push {lr}
	lsls r0, r0, #0xc
	ldr r1, L_080637d0
	ldr r1, [r1]
	ldrh r1, [r1, #0xa]
	bl __udivsi3
	lsrs r0, r0, #5
	adds r0, #2
	pop {r1}
	bx r1
	.hword 0x0000
L_080637d0:
	.word 0x03006830

.global psg_HWInit
.thumb_func
.type psg_HWInit, %function
psg_HWInit:
	ldr r1, L_0806384c
	movs r0, #0x80
	strh r0, [r1]
	subs r1, #4
	ldr r0, L_08063850
	str r0, [r1]
	subs r1, #0x20
	movs r0, #8
	strh r0, [r1]
	ldr r0, L_08063854
	movs r2, #0
	strh r2, [r0]
	adds r0, #2
	movs r3, #0x80
	lsls r3, r3, #8
	adds r1, r3, #0
	strh r1, [r0]
	adds r0, #4
	strh r2, [r0]
	adds r0, #4
	strh r1, [r0]
	ldr r1, L_08063858
	movs r0, #0x40
	strh r0, [r1]
	adds r1, #0x20
	movs r0, #7
.L08063808:
	strh r2, [r1]
	adds r1, #2
	subs r0, #1
	cmp r0, #0
	bge .L08063808
	ldr r1, L_08063858
	movs r0, #0
	strh r0, [r1]
	adds r1, #0x20
	movs r2, #0
	movs r0, #7
.L0806381e:
	strh r2, [r1]
	adds r1, #2
	subs r0, #1
	cmp r0, #0
	bge .L0806381e
	ldr r0, L_0806385c
	movs r1, #0
	strh r1, [r0]
	adds r0, #2
	movs r3, #0x80
	lsls r3, r3, #8
	adds r2, r3, #0
	strh r2, [r0]
	strh r1, [r0]
	adds r0, #4
	strh r1, [r0]
	adds r0, #4
	strh r2, [r0]
	ldr r1, L_08063860
	ldr r2, L_08063864
	adds r0, r2, #0
	strh r0, [r1]
	bx lr
L_0806384c:
	.word 0x04000084
L_08063850:
	.word 0x9a0d0000
L_08063854:
	.word 0x04000062
L_08063858:
	.word 0x04000070
L_0806385c:
	.word 0x04000072
L_08063860:
	.word 0x04000080
L_08063864:
	.word 0x0000ff77

.global psg_SetFreq
.thumb_func
.type psg_SetFreq, %function
psg_SetFreq:
	push {r4, r5, r6, r7, lr}
	adds r5, r2, #0
	lsls r0, r0, #0x10
	lsrs r3, r0, #0x10
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	cmp r5, #2
	bgt .L08063908
	lsls r0, r3, #0x10
	ldr r4, L_08063898
	lsls r1, r1, #0x10
	ldr r7, L_0806389c
	lsls r6, r5, #1
	cmp r0, #0
	bge .L080638a6
.L08063886:
	movs r2, #0xa8
	lsls r2, r2, #0xf
	adds r0, r0, r2
	lsrs r3, r0, #0x10
	lsls r0, r3, #0x10
	cmp r0, #0
	blt .L08063886
	b .L080638a6
	.hword 0x0000
L_08063898:
	.word 0x08725bce
L_0806389c:
	.word 0x03006830
.L080638a0:
	ldr r3, L_080638c0
	adds r0, r2, r3
	lsrs r3, r0, #0x10
.L080638a6:
	lsls r2, r3, #0x10
	asrs r0, r2, #0x10
	cmp r0, #0x53
	bgt .L080638a0
	asrs r2, r1, #0x10
	cmp r2, #0
	bne .L080638c4
	lsls r0, r3, #0x10
	asrs r0, r0, #0xf
	adds r0, r0, r4
	ldrh r0, [r0]
	adds r4, r0, #0
	b .L080638e6
L_080638c0:
	.word 0xffac0000
.L080638c4:
	lsls r1, r3, #0x10
	asrs r1, r1, #0xf
	adds r1, r1, r4
	ldrh r0, [r1]
	adds r4, r0, #0
	ldrh r0, [r1, #2]
	ldrh r1, [r1]
	subs r0, r0, r1
	lsls r0, r0, #0x10
	asrs r0, r0, #0x10
	muls r0, r2, r0
	movs r1, #0xff
	bl __divsi3
	adds r0, r4, r0
	lsls r0, r0, #0x10
	lsrs r4, r0, #0x10
.L080638e6:
	ldr r0, [r7]
	adds r0, #0xbc
	adds r0, r0, r6
	ldrh r1, [r0]
	cmp r1, r4
	beq .L08063908
	strh r4, [r0]
	ldr r1, L_08063910
	lsls r0, r5, #2
	adds r0, r0, r1
	ldr r2, [r0]
	ldrh r1, [r2]
	movs r0, #0x80
	lsls r0, r0, #7
	ands r0, r1
	orrs r4, r0
	strh r4, [r2]
.L08063908:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08063910:
	.word 0x087ffc68

.global psg_SetVolume
.thumb_func
.type psg_SetVolume, %function
psg_SetVolume:
	push {r4, r5, lr}
	adds r4, r0, #0
	adds r3, r1, #0
	lsrs r4, r4, #3
	cmp r3, #1
	ble .L08063924
	cmp r3, #3
	bne .L08063968
.L08063924:
	ldr r5, L_0806395c
	ldr r0, [r5]
	lsls r1, r3, #3
	adds r0, r0, r1
	adds r0, #0x9a
	ldrb r1, [r0]
	strb r4, [r0]
	cmp r1, r4
	beq .L080639a2
	ldr r0, L_08063960
	lsls r3, r3, #2
	adds r0, r3, r0
	ldr r2, [r0]
	ldrh r1, [r2]
	ldr r0, L_08063964
	ands r0, r1
	lsls r1, r4, #0xc
	orrs r0, r1
	strh r0, [r2]
	ldr r1, [r5]
	adds r1, #0x18
	adds r1, r1, r3
	ldr r0, [r1]
	movs r2, #0x80
	lsls r2, r2, #2
	orrs r0, r2
	str r0, [r1]
	b .L080639a2
L_0806395c:
	.word 0x03006830
L_08063960:
	.word 0x087ffc78
L_08063964:
	.word 0x00000fff
.L08063968:
	cmp r3, #2
	bne .L080639a2
	ldr r5, L_080639a8
	ldr r0, [r5]
	adds r0, #0xaa
	ldrb r1, [r0]
	strb r4, [r0]
	ldr r0, L_080639ac
	adds r1, r1, r0
	adds r3, r4, r0
	ldrb r1, [r1]
	ldrb r0, [r3]
	cmp r1, r0
	beq .L080639a2
	ldr r0, L_080639b0
	ldr r2, [r0, #8]
	ldrh r1, [r2]
	movs r0, #0xff
	ands r0, r1
	ldrb r3, [r3]
	lsls r1, r3, #8
	orrs r0, r1
	strh r0, [r2]
	ldr r2, [r5]
	ldr r0, [r2, #0x20]
	movs r1, #0x80
	lsls r1, r1, #2
	orrs r0, r1
	str r0, [r2, #0x20]
.L080639a2:
	pop {r4, r5}
	pop {r0}
	bx r0
L_080639a8:
	.word 0x03006830
L_080639ac:
	.word 0x087ffc88
L_080639b0:
	.word 0x087ffc78

.global voice_Silence
.thumb_func
.type voice_Silence, %function
voice_Silence:
	push {r4, r5, lr}
	adds r4, r0, #0
	cmp r4, #3
	bgt .L08063a20
	ldr r0, L_080639f8
	ldr r5, [r0]
	lsls r3, r4, #2
	adds r1, r5, #0
	adds r1, #0x18
	adds r1, r1, r3
	ldr r0, [r1]
	movs r2, #0x22
	rsbs r2, r2, #0
	ands r0, r2
	str r0, [r1]
	cmp r4, #2
	bgt .L080639e6
	lsls r1, r4, #1
	adds r0, r5, #0
	adds r0, #0xbc
	adds r0, r0, r1
	movs r1, #0
	strh r1, [r0]
	cmp r4, #2
	beq .L08063a00
.L080639e6:
	ldr r0, L_080639fc
	adds r0, r3, r0
	ldr r1, [r0]
	movs r2, #0x80
	lsls r2, r2, #4
	adds r0, r2, #0
	strh r0, [r1]
	b .L08063a06
	.hword 0x0000
L_080639f8:
	.word 0x03006830
L_080639fc:
	.word 0x087ffc78
.L08063a00:
	ldr r0, L_08063a18
	ldr r0, [r0, #8]
	strh r1, [r0]
.L08063a06:
	ldr r0, L_08063a1c
	adds r0, r3, r0
	ldr r1, [r0]
	movs r2, #0x80
	lsls r2, r2, #8
	adds r0, r2, #0
	strh r0, [r1]
	b .L08063a44
	.hword 0x0000
L_08063a18:
	.word 0x087ffc78
L_08063a1c:
	.word 0x087ffc68
.L08063a20:
	subs r4, #4
	ldr r0, L_08063a4c
	ldr r2, [r0]
	adds r0, r2, #0
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	movs r1, #0
	str r1, [r0]
	adds r2, #0xd0
	ldr r0, [r2]
	lsls r1, r4, #6
	adds r1, r1, r0
	ldr r0, [r1, #0x38]
	ldr r2, L_08063a50
	ands r0, r2
	str r0, [r1, #0x38]
.L08063a44:
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000
L_08063a4c:
	.word 0x03006830
L_08063a50:
	.word 0xfffffdff

.global voice_SetPan
.thumb_func
.type voice_SetPan, %function
voice_SetPan:
	push {r4, r5, r6, r7, lr}
	adds r4, r1, #0
	lsls r0, r0, #0x18
	lsrs r5, r0, #0x18
	cmp r4, #3
	bgt .L08063ad0
	movs r0, #0x88
	lsls r0, r0, #0x15
	lsls r0, r4
	lsrs r3, r0, #0x18
	ldr r2, L_08063a98
	ldr r0, [r2]
	adds r0, #0xc2
	ldrb r1, [r0]
	bics r1, r3
	strb r1, [r0]
	ldr r0, [r2]
	ldr r6, L_08063a9c
	adds r1, r0, r6
	movs r6, #0x10
	adds r0, r6, #0
	ldrb r1, [r1]
	ands r0, r1
	adds r7, r2, #0
	cmp r0, #0
	bne .L08063aac
	cmp r5, #0xff
	beq .L08063aac
	cmp r5, #0x29
	bhi .L08063aa0
	adds r0, r6, #0
	lsls r0, r4
	lsls r0, r0, #0x18
	b .L08063aaa
L_08063a98:
	.word 0x03006830
L_08063a9c:
	.word 0x00000117
.L08063aa0:
	cmp r5, #0x55
	bls .L08063aac
	movs r0, #0x80
	lsls r0, r0, #0x11
	lsls r0, r4
.L08063aaa:
	lsrs r3, r0, #0x18
.L08063aac:
	ldr r0, [r7]
	adds r0, #0xc2
	ldrb r1, [r0]
	orrs r3, r1
	strb r3, [r0]
	ldr r2, L_08063acc
	ldrh r0, [r2]
	movs r1, #0xff
	ands r1, r0
	ldr r0, [r7]
	adds r0, #0xc2
	ldrb r0, [r0]
	lsls r0, r0, #8
	orrs r1, r0
	strh r1, [r2]
	b .L08063af4
L_08063acc:
	.word 0x04000080
.L08063ad0:
	ldr r0, L_08063afc
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r4, #6
	ldr r2, L_08063b00
	adds r0, r0, r2
	ldr r1, [r1]
	adds r2, r1, r0
	adds r0, r2, #0
	adds r0, #0x3c
	ldrb r1, [r0]
	strb r5, [r0]
	cmp r5, r1
	beq .L08063af4
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	orrs r0, r1
	str r0, [r2, #0x38]
.L08063af4:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08063afc:
	.word 0x03006830
L_08063b00:
	.word 0xffffff00

.global voice_AddPan
.thumb_func
.type voice_AddPan, %function
voice_AddPan:
	push {r4, r5, lr}
	adds r3, r1, #0
	lsls r0, r0, #0x18
	lsrs r5, r0, #0x18
	asrs r4, r0, #0x18
	cmp r4, #0
	beq .L08063bbc
	cmp r3, #3
	bgt .L08063b7a
	movs r0, #0x88
	lsls r0, r0, #0x15
	lsls r0, r3
	lsrs r4, r0, #0x18
	ldr r0, L_08063b5c
	ldr r1, [r0]
	ldr r0, L_08063b60
	adds r2, r1, r0
	movs r0, #0x10
	ldrb r2, [r2]
	ands r0, r2
	cmp r0, #0
	bne .L08063b6c
	adds r1, #0xc2
	adds r0, r4, #0
	ldrb r1, [r1]
	ands r0, r1
	asrs r0, r3
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	movs r1, #0x2a
	cmp r0, #0x10
	beq .L08063b4c
	movs r1, #0x40
	cmp r0, #1
	bne .L08063b4c
	movs r1, #0x55
.L08063b4c:
	lsls r0, r5, #0x18
	asrs r0, r0, #0x18
	adds r1, r1, r0
	cmp r1, #0
	bge .L08063b64
	movs r1, #0
	b .L08063b6e
	.hword 0x0000
L_08063b5c:
	.word 0x03006830
L_08063b60:
	.word 0x00000117
.L08063b64:
	cmp r1, #0x7f
	ble .L08063b6e
	movs r1, #0x7f
	b .L08063b6e
.L08063b6c:
	movs r1, #0x40
.L08063b6e:
	lsls r0, r1, #0x18
	lsrs r0, r0, #0x18
	adds r1, r3, #0
	bl voice_SetPan
	b .L08063bbc
.L08063b7a:
	ldr r0, L_08063ba0
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r3, #6
	ldr r2, L_08063ba4
	adds r0, r0, r2
	ldr r1, [r1]
	adds r2, r1, r0
	adds r1, r2, #0
	adds r1, #0x3c
	ldrb r0, [r1]
	cmp r0, #0xff
	beq .L08063bbc
	ldrb r1, [r1]
	adds r1, r1, r4
	cmp r1, #0
	bge .L08063ba8
	movs r1, #0
	b .L08063bae
L_08063ba0:
	.word 0x03006830
L_08063ba4:
	.word 0xffffff00
.L08063ba8:
	cmp r1, #0x7f
	ble .L08063bae
	movs r1, #0x7f
.L08063bae:
	adds r0, r2, #0
	adds r0, #0x3c
	strb r1, [r0]
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	orrs r0, r1
	str r0, [r2, #0x38]
.L08063bbc:
	pop {r4, r5}
	pop {r0}
	bx r0
	.hword 0x0000

.global mod_UpdPitchSweep
.thumb_func
.type mod_UpdPitchSweep, %function
mod_UpdPitchSweep:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	movs r2, #0
	ldr r0, L_08063c18
	mov r10, r0
	mov r9, r10
.L08063bd6:
	lsls r0, r2, #3
	adds r7, r2, #1
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, #0x28
	mov r8, r0
	movs r5, #4
	lsls r2, r2, #2
	mov r12, r2
	movs r6, #1
.L08063bea:
	mov r1, r9
	ldr r0, [r1]
	add r0, r8
	adds r2, r0, r5
	ldrh r1, [r2, #2]
	movs r3, #2
	ldrsh r0, [r2, r3]
	cmp r0, #0
	beq .L08063c38
	ldrh r0, [r2]
	adds r1, r1, r0
	strh r1, [r2]
	ldrh r4, [r2, #4]
	movs r0, #4
	ldrsh r3, [r2, r0]
	cmp r3, #0
	ble .L08063c1c
	lsls r0, r1, #0x10
	asrs r0, r0, #0x10
	cmp r0, r3
	ble .L08063c28
	b .L08063c24
	.hword 0x0000
L_08063c18:
	.word 0x03006830
.L08063c1c:
	lsls r0, r1, #0x10
	asrs r0, r0, #0x10
	cmp r0, r3
	bge .L08063c28
.L08063c24:
	subs r0, r1, r4
	strh r0, [r2]
.L08063c28:
	mov r1, r9
	ldr r0, [r1]
	adds r0, #0x18
	add r0, r12
	ldr r1, [r0]
	movs r2, #0x40
	orrs r1, r2
	str r1, [r0]
.L08063c38:
	adds r5, #8
	subs r6, #1
	cmp r6, #0
	bge .L08063bea
	adds r2, r7, #0
	cmp r2, #2
	ble .L08063bd6
	movs r2, #0
	b .L08063ca2
.L08063c4a:
	ldr r0, [r1]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r5, [r0]
	adds r7, r2, #1
	cmp r5, #0
	beq .L08063ca0
	adds r2, r5, #4
	movs r6, #1
.L08063c60:
	ldrh r1, [r2, #2]
	movs r3, #2
	ldrsh r0, [r2, r3]
	cmp r0, #0
	beq .L08063c98
	ldrh r0, [r2]
	adds r1, r1, r0
	strh r1, [r2]
	ldrh r4, [r2, #4]
	movs r0, #4
	ldrsh r3, [r2, r0]
	cmp r3, #0
	ble .L08063c84
	lsls r0, r1, #0x10
	asrs r0, r0, #0x10
	cmp r0, r3
	ble .L08063c90
	b .L08063c8c
.L08063c84:
	lsls r0, r1, #0x10
	asrs r0, r0, #0x10
	cmp r0, r3
	bge .L08063c90
.L08063c8c:
	subs r0, r1, r4
	strh r0, [r2]
.L08063c90:
	ldr r0, [r5, #0x38]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r5, #0x38]
.L08063c98:
	adds r2, #8
	subs r6, #1
	cmp r6, #0
	bge .L08063c60
.L08063ca0:
	adds r2, r7, #0
.L08063ca2:
	mov r1, r10
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r2, r0
	blt .L08063c4a
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global mod_SetVibrato
.thumb_func
.type mod_SetVibrato, %function
mod_SetVibrato:
	push {r4, r5, lr}
	adds r5, r0, #0
	adds r4, r1, #0
	cmp r2, #2
	bgt .L08063cec
	ldr r3, L_08063ce8
	ldr r0, [r3]
	lsls r1, r2, #3
	adds r1, r1, r2
	lsls r1, r1, #2
	adds r0, r0, r1
	adds r0, #0x41
	strb r4, [r0]
	ldr r0, [r3]
	adds r0, r0, r1
	lsrs r2, r4, #1
	adds r0, #0x40
	strb r2, [r0]
	ldr r0, [r3]
	adds r0, r0, r1
	strh r5, [r0, #0x3e]
	b .L08063d06
L_08063ce8:
	.word 0x03006830
.L08063cec:
	cmp r2, #3
	ble .L08063d06
	ldr r0, L_08063d0c
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r2, #6
	ldr r1, [r1]
	adds r0, r0, r1
	subs r0, #0xec
	strb r4, [r0, #5]
	lsrs r1, r4, #1
	strb r1, [r0, #4]
	strh r5, [r0, #2]
.L08063d06:
	pop {r4, r5}
	pop {r0}
	bx r0
L_08063d0c:
	.word 0x03006830

.global mod_UpdVibrato
.thumb_func
.type mod_UpdVibrato, %function
mod_UpdVibrato:
	push {r4, r5, r6, r7, lr}
	movs r4, #0
	ldr r0, L_08063d68
	mov r12, r0
	mov r6, r12
	movs r5, #0x28
.L08063d1c:
	ldr r0, [r6]
	adds r2, r0, r5
	adds r1, r2, #0
	adds r1, #0x14
	ldrh r3, [r1, #2]
	movs r7, #2
	ldrsh r0, [r1, r7]
	cmp r0, #0
	beq .L08063d5c
	ldrh r7, [r2, #0x14]
	adds r0, r3, r7
	strh r0, [r2, #0x14]
	ldrb r0, [r1, #4]
	subs r0, #1
	strb r0, [r1, #4]
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #0xff
	bne .L08063d4c
	ldrb r0, [r1, #5]
	strb r0, [r1, #4]
	ldrh r2, [r1, #2]
	rsbs r0, r2, #0
	strh r0, [r1, #2]
.L08063d4c:
	ldr r2, [r6]
	lsls r0, r4, #2
	adds r2, #0x18
	adds r2, r2, r0
	ldr r0, [r2]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2]
.L08063d5c:
	adds r5, #0x24
	adds r4, #1
	cmp r4, #2
	ble .L08063d1c
	movs r4, #0
	b .L08063db2
L_08063d68:
	.word 0x03006830
.L08063d6c:
	ldr r0, [r1]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	ldr r2, [r0]
	cmp r2, #0
	beq .L08063db0
	adds r1, r2, #0
	adds r1, #0x14
	ldrh r3, [r1, #2]
	movs r5, #2
	ldrsh r0, [r1, r5]
	cmp r0, #0
	beq .L08063db0
	ldrh r7, [r2, #0x14]
	adds r0, r3, r7
	strh r0, [r2, #0x14]
	ldrb r0, [r1, #4]
	subs r0, #1
	strb r0, [r1, #4]
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #0xff
	bne .L08063da8
	ldrb r0, [r1, #5]
	strb r0, [r1, #4]
	ldrh r3, [r1, #2]
	rsbs r0, r3, #0
	strh r0, [r1, #2]
.L08063da8:
	ldr r0, [r2, #0x38]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2, #0x38]
.L08063db0:
	adds r4, #1
.L08063db2:
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r4, r0
	blt .L08063d6c
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global mod_SetPortamento
.thumb_func
.type mod_SetPortamento, %function
mod_SetPortamento:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	lsls r0, r0, #0x18
	lsrs r7, r0, #0x18
	mov r12, r7
	lsls r1, r1, #0x10
	lsrs r5, r1, #0x10
	mov r8, r5
	lsls r2, r2, #0x10
	lsrs r6, r2, #0x10
	adds r2, r6, #0
	cmp r3, #2
	bgt .L08063e26
	ldr r0, L_08063e14
	lsls r1, r3, #3
	adds r1, r1, r3
	lsls r2, r1, #2
	adds r1, r2, #0
	adds r1, #0x28
	ldr r0, [r0]
	adds r3, r0, r1
	adds r4, r3, #0
	adds r4, #0x1c
	cmp r7, #0
	beq .L08063e18
	adds r2, r0, r2
	lsls r0, r5, #0x10
	asrs r0, r0, #0x10
	ldrh r5, [r2, #0x28]
	subs r1, r0, r5
	strh r1, [r4, #4]
	movs r5, #0x28
	ldrsh r1, [r2, r5]
	movs r5, #0x1c
	ldrsh r2, [r3, r5]
	adds r1, r1, r2
	subs r0, r0, r1
	adds r1, r6, #0
	b .L08063e76
L_08063e14:
	.word 0x03006830
.L08063e18:
	lsls r0, r5, #0x10
	asrs r0, r0, #0x10
	ldrh r2, [r4, #4]
	adds r1, r2, r0
	strh r1, [r4, #4]
	adds r1, r6, #0
	b .L08063e76
.L08063e26:
	cmp r3, #3
	ble .L08063e7c
	ldr r0, L_08063e60
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r3, #6
	ldr r3, L_08063e64
	adds r0, r0, r3
	ldr r1, [r1]
	adds r3, r1, r0
	adds r4, r3, #0
	adds r4, #0x1c
	mov r0, r12
	cmp r0, #0
	beq .L08063e68
	lsls r0, r5, #0x10
	asrs r0, r0, #0x10
	ldrh r2, [r3]
	subs r1, r0, r2
	strh r1, [r4, #4]
	movs r5, #0
	ldrsh r1, [r3, r5]
	movs r5, #0x1c
	ldrsh r2, [r3, r5]
	adds r1, r1, r2
	subs r0, r0, r1
	adds r1, r6, #0
	b .L08063e76
	.hword 0x0000
L_08063e60:
	.word 0x03006830
L_08063e64:
	.word 0xffffff00
.L08063e68:
	mov r1, r8
	lsls r0, r1, #0x10
	asrs r0, r0, #0x10
	ldrh r3, [r4, #4]
	adds r1, r3, r0
	strh r1, [r4, #4]
	adds r1, r2, #0
.L08063e76:
	bl __divsi3
	strh r0, [r4, #2]
.L08063e7c:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global mod_SetPortaFromLast
.thumb_func
.type mod_SetPortaFromLast, %function
mod_SetPortaFromLast:
	push {r4, r5, r6, r7, lr}
	lsls r0, r0, #0x10
	lsrs r7, r0, #0x10
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	mov r12, r1
	cmp r2, #3
	beq .L08063f00
	ldr r0, L_08063ec4
	ldr r3, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r1, [r0]
	movs r0, #0x88
	lsls r0, r0, #1
	adds r1, r1, r0
	lsls r0, r2, #1
	adds r0, r0, r2
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r4, r1, r0
	cmp r2, #2
	bgt .L08063ec8
	lsls r0, r2, #3
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, #0x28
	adds r6, r3, r0
	b .L08063ed6
L_08063ec4:
	.word 0x03006830
.L08063ec8:
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r2, L_08063f08
	adds r1, r1, r2
	ldr r0, [r0]
	adds r6, r0, r1
.L08063ed6:
	adds r5, r6, #0
	adds r5, #0x1c
	cmp r5, #0
	beq .L08063f00
	movs r0, #0
	strh r0, [r5]
	ldrb r4, [r4, #7]
	lsls r1, r4, #8
	lsls r0, r7, #0x10
	asrs r0, r0, #0x10
	adds r0, r0, r1
	ldrh r4, [r5, #6]
	subs r0, r0, r4
	strh r0, [r5, #4]
	movs r1, #4
	ldrsh r0, [r5, r1]
	mov r1, r12
	bl __divsi3
	strh r0, [r5, #2]
	strh r4, [r6]
.L08063f00:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08063f08:
	.word 0xffffff00

.global mod_UpdPortamento
.thumb_func
.type mod_UpdPortamento, %function
mod_UpdPortamento:
	push {r4, r5, r6, r7, lr}
	mov r7, r9
	mov r6, r8
	push {r6, r7}
	movs r5, #0
	ldr r0, L_08063f54
	mov r8, r0
	mov r12, r8
	movs r7, #0x28
.L08063f1e:
	mov r1, r12
	ldr r0, [r1]
	adds r3, r0, r7
	adds r2, r3, #0
	adds r2, #0x1c
	ldrh r1, [r2, #2]
	movs r4, #2
	ldrsh r0, [r2, r4]
	cmp r0, #0
	beq .L08063f78
	ldrh r0, [r3, #0x1c]
	adds r1, r1, r0
	movs r6, #0
	strh r1, [r3, #0x1c]
	movs r4, #2
	ldrsh r0, [r2, r4]
	cmp r0, #0
	ble .L08063f58
	lsls r1, r1, #0x10
	ldrh r0, [r2, #4]
	mov r9, r0
	lsls r0, r0, #0x10
	cmp r1, r0
	ble .L08063f66
	mov r1, r9
	strh r1, [r3, #0x1c]
	b .L08063f64
L_08063f54:
	.word 0x03006830
.L08063f58:
	lsls r1, r1, #0x10
	ldrh r4, [r2, #4]
	lsls r0, r4, #0x10
	cmp r1, r0
	bge .L08063f66
	strh r4, [r3, #0x1c]
.L08063f64:
	strh r6, [r2, #2]
.L08063f66:
	mov r0, r12
	ldr r2, [r0]
	lsls r0, r5, #2
	adds r2, #0x18
	adds r2, r2, r0
	ldr r0, [r2]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2]
.L08063f78:
	adds r7, #0x24
	adds r5, #1
	cmp r5, #2
	ble .L08063f1e
	movs r5, #0
	b .L08063fd6
.L08063f84:
	ldr r0, [r1]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r5, #2
	adds r0, r0, r1
	ldr r3, [r0]
	cmp r3, #0
	beq .L08063fd4
	adds r2, r3, #0
	adds r2, #0x1c
	movs r1, #2
	ldrsh r0, [r2, r1]
	cmp r0, #0
	beq .L08063fd4
	ldr r0, [r3, #0x38]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r3, #0x38]
	ldrh r4, [r3, #0x1c]
	ldrh r7, [r2, #2]
	adds r1, r4, r7
	movs r6, #0
	strh r1, [r3, #0x1c]
	movs r4, #2
	ldrsh r0, [r2, r4]
	cmp r0, #0
	ble .L08063fc6
	lsls r1, r1, #0x10
	ldrh r4, [r2, #4]
	lsls r0, r4, #0x10
	cmp r1, r0
	ble .L08063fd4
	b .L08063fd0
.L08063fc6:
	lsls r1, r1, #0x10
	ldrh r4, [r2, #4]
	lsls r0, r4, #0x10
	cmp r1, r0
	bge .L08063fd4
.L08063fd0:
	strh r4, [r3, #0x1c]
	strh r6, [r2, #2]
.L08063fd4:
	adds r5, #1
.L08063fd6:
	mov r1, r8
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r5, r0
	blt .L08063f84
	pop {r3, r4}
	mov r8, r3
	mov r9, r4
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

.global mod_UpdPulseSweep
.thumb_func
.type mod_UpdPulseSweep, %function
mod_UpdPulseSweep:
	push {r4, r5, r6, r7, lr}
	ldr r2, L_0806403c
	ldr r1, [r2]
	adds r0, r1, #0
	adds r0, #0xd4
	ldr r5, [r0]
	movs r6, #0
	ldrb r1, [r1, #8]
	cmp r6, r1
	bge .L08064078
	mov r12, r2
	movs r7, #0
.L08064004:
	ldr r2, [r5]
	cmp r2, #0
	beq .L08064068
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	lsls r1, r1, #3
	ands r0, r1
	cmp r0, #0
	beq .L08064068
	adds r3, r2, #0
	adds r3, #0x2c
	movs r1, #0x2c
	ldrsh r0, [r2, r1]
	movs r2, #2
	ldrsh r1, [r3, r2]
	adds r1, r0, r1
	ldrh r4, [r3, #2]
	movs r2, #2
	ldrsh r0, [r3, r2]
	cmp r0, #0
	blt .L08064040
	movs r0, #5
	ldrsb r0, [r3, r0]
	lsls r2, r0, #8
	cmp r1, r2
	blt .L08064052
	b .L0806404a
	.hword 0x0000
L_0806403c:
	.word 0x03006830
.L08064040:
	movs r0, #4
	ldrsb r0, [r3, r0]
	lsls r2, r0, #8
	cmp r1, r2
	bgt .L08064052
.L0806404a:
	lsls r0, r0, #9
	subs r1, r0, r1
	rsbs r0, r4, #0
	strh r0, [r3, #2]
.L08064052:
	strh r1, [r3]
	mov r2, r12
	ldr r0, [r2]
	adds r0, #0xc8
	ldr r2, [r0]
	adds r2, r2, r7
	lsrs r1, r1, #8
	adds r1, #0x10
	ldr r0, [r2]
	adds r0, r0, r1
	str r0, [r2, #0xc]
.L08064068:
	adds r7, #0x1c
	adds r6, #1
	adds r5, #4
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r6, r0
	blt .L08064004
.L08064078:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global mod_UpdLoopScan
.thumb_func
.type mod_UpdLoopScan, %function
mod_UpdLoopScan:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	movs r0, #0
	mov r9, r0
	ldr r1, L_08064098
	ldr r0, [r1]
	mov r10, r1
	b .L08064174
	.hword 0x0000
L_08064098:
	.word 0x03006830
.L0806409c:
	ldr r4, [r1]
	adds r0, r4, #0
	adds r0, #0xd4
	ldr r0, [r0]
	mov r1, r9
	lsls r3, r1, #2
	adds r0, r3, r0
	ldr r2, [r0]
	cmp r2, #0
	beq .L0806416c
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	lsls r1, r1, #4
	ands r0, r1
	cmp r0, #0
	beq .L0806416c
	adds r0, r4, #0
	adds r0, #0xcc
	ldr r0, [r0]
	adds r0, r3, r0
	ldr r7, [r0]
	cmp r7, #0
	beq .L0806416c
	adds r3, r2, #0
	adds r3, #0x2c
	ldrb r0, [r3, #7]
	cmp r0, #0
	bne .L08064168
	ldrb r0, [r3, #6]
	strb r0, [r3, #7]
	ldrh r0, [r3, #4]
	adds r6, r0, #0
	cmp r6, #0
	bne .L08064106
	ldr r1, [r2, #0x38]
	movs r0, #0x80
	lsls r0, r0, #7
	ands r0, r1
	cmp r0, #0
	beq .L080640f8
	ldrh r0, [r3, #2]
	strh r0, [r3, #4]
	ldrh r1, [r2, #0x2c]
	rsbs r0, r1, #0
	strh r0, [r2, #0x2c]
	b .L080640fe
.L080640f8:
	ldr r0, L_08064134
	ands r1, r0
	str r1, [r2, #0x38]
.L080640fe:
	ldrh r0, [r3, #4]
	adds r6, r0, #0
	cmp r6, #0
	beq .L0806416c
.L08064106:
	movs r1, #0
	ldrsh r0, [r3, r1]
	ldr r1, [r7, #0xc]
	adds r5, r1, r0
	movs r0, #0
	mov r8, r0
	ldr r4, [r7]
	adds r2, r4, #0
	adds r2, #0x10
	ldr r0, [r7, #8]
	mov r12, r1
	cmp r12, r0
	bhi .L08064138
	cmp r5, r2
	blo .L08064152
	ldr r1, [r7, #0x10]
	adds r1, r5, r1
	ldr r0, [r4]
	adds r0, r2, r0
	cmp r1, r0
	bls .L0806414c
	b .L08064152
	.hword 0x0000
L_08064134:
	.word 0xffffb7ff
.L08064138:
	ldr r0, [r7, #0x10]
	subs r0, r5, r0
	cmp r0, r2
	blo .L08064148
	ldr r0, [r4]
	adds r0, r2, r0
	cmp r5, r0
	bls .L0806414c
.L08064148:
	movs r1, #1
	mov r8, r1
.L0806414c:
	mov r0, r8
	cmp r0, #0
	beq .L08064160
.L08064152:
	mov r5, r12
	ldrh r1, [r3, #2]
	subs r0, r1, r6
	movs r1, #0
	strh r0, [r3, #2]
	strh r1, [r3, #4]
	b .L08064164
.L08064160:
	subs r0, r6, #1
	strh r0, [r3, #4]
.L08064164:
	str r5, [r7, #0xc]
	b .L0806416c
.L08064168:
	subs r0, #1
	strb r0, [r3, #7]
.L0806416c:
	movs r0, #1
	add r9, r0
	mov r1, r10
	ldr r0, [r1]
.L08064174:
	ldrb r0, [r0, #8]
	cmp r9, r0
	blt .L0806409c
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

.global env_SetADSR
.thumb_func
.type env_SetADSR, %function
env_SetADSR:
	push {r4, r5, r6, lr}
	adds r6, r0, #0
	lsls r1, r1, #0x18
	lsrs r5, r1, #0x18
	cmp r2, #3
	bgt .L080641d0
	ldr r0, L_080641cc
	ldr r4, [r0]
	lsls r1, r2, #2
	adds r0, r4, #0
	adds r0, #0x18
	adds r3, r0, r1
	ldr r1, [r3]
	movs r0, #0x27
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r3]
	movs r0, #9
	cmp r5, #0
	bne .L080641b2
	movs r0, #1
.L080641b2:
	orrs r1, r0
	str r1, [r3]
	lsls r2, r2, #3
	adds r0, r4, r2
	adds r0, #0x98
	movs r1, #0
	strh r1, [r0]
	adds r0, r4, #0
	adds r0, #0x94
	adds r0, r0, r2
	str r6, [r0]
	b .L080641fc
	.hword 0x0000
L_080641cc:
	.word 0x03006830
.L080641d0:
	ldr r0, L_08064204
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r2, #6
	ldr r2, L_08064208
	adds r0, r0, r2
	ldr r1, [r1]
	adds r1, r1, r0
	ldr r3, [r1, #0x38]
	movs r0, #0x27
	rsbs r0, r0, #0
	ands r3, r0
	str r3, [r1, #0x38]
	movs r0, #9
	cmp r5, #0
	bne .L080641f2
	movs r0, #1
.L080641f2:
	orrs r3, r0
	str r3, [r1, #0x38]
	movs r0, #0
	strh r0, [r1, #0x28]
	str r6, [r1, #0x24]
.L080641fc:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
L_08064204:
	.word 0x03006830
L_08064208:
	.word 0xffffff00

.global env_SetFade
.thumb_func
.type env_SetFade, %function
env_SetFade:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r4, r2, #0
	lsls r0, r0, #0x18
	lsrs r6, r0, #0x18
	lsls r1, r1, #0x10
	lsrs r7, r1, #0x10
	cmp r4, #3
	bgt .L08064290
	ldr r3, L_0806428c
	ldr r5, [r3]
	lsls r2, r4, #2
	adds r0, r5, #0
	adds r0, #0x18
	adds r0, r0, r2
	ldr r1, [r0]
	movs r0, #0x21
	ands r1, r0
	mov r8, r3
	mov r12, r2
	lsls r4, r4, #3
	cmp r1, #0
	bne .L0806424e
	adds r0, r5, r4
	movs r1, #0
	cmp r6, #0
	bne .L0806424a
	movs r2, #0xff
	lsls r2, r2, #8
	adds r1, r2, #0
.L0806424a:
	adds r0, #0x98
	strh r1, [r0]
.L0806424e:
	mov r0, r8
	ldr r3, [r0]
	adds r2, r3, #0
	adds r2, #0x18
	add r2, r12
	ldr r0, [r2]
	movs r1, #8
	rsbs r1, r1, #0
	ands r0, r1
	movs r1, #0x20
	orrs r0, r1
	str r0, [r2]
	adds r3, #0x94
	adds r3, r3, r4
	str r7, [r3]
	cmp r6, #0
	bne .L08064274
	rsbs r0, r7, #0
	str r0, [r3]
.L08064274:
	mov r1, r8
	ldr r0, [r1]
	adds r0, r0, r4
	movs r1, #0
	cmp r6, #0
	bne .L08064286
	movs r2, #0xff
	lsls r2, r2, #8
	adds r1, r2, #0
.L08064286:
	adds r0, #0x98
	strh r1, [r0]
	b .L080642d0
L_0806428c:
	.word 0x03006830
.L08064290:
	ldr r0, L_080642dc
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r4, #6
	ldr r2, L_080642e0
	adds r0, r0, r2
	ldr r1, [r1]
	adds r2, r1, r0
	ldr r0, [r2, #0x38]
	movs r1, #0x21
	ands r0, r1
	cmp r0, #0
	bne .L080642b8
	movs r0, #0
	cmp r6, #0
	bne .L080642b6
	movs r1, #0xff
	lsls r1, r1, #8
	adds r0, r1, #0
.L080642b6:
	strh r0, [r2, #0x28]
.L080642b8:
	ldr r0, [r2, #0x38]
	movs r1, #8
	rsbs r1, r1, #0
	ands r0, r1
	movs r1, #0x20
	orrs r0, r1
	str r0, [r2, #0x38]
	str r7, [r2, #0x24]
	cmp r6, #0
	bne .L080642d0
	rsbs r0, r7, #0
	str r0, [r2, #0x24]
.L080642d0:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_080642dc:
	.word 0x03006830
L_080642e0:
	.word 0xffffff00

.global env_Update
.thumb_func
.type env_Update, %function
env_Update:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	movs r0, #0xf0
	lsls r0, r0, #8
	mov r10, r0
	movs r1, #0x94
	mov r9, r1
	movs r2, #0
	mov r12, r2
	movs r3, #3
	mov r8, r3
.L08064300:
	ldr r5, L_08064338
	ldr r2, [r5]
	adds r0, r2, #0
	adds r0, #0x18
	mov r1, r12
	adds r6, r0, r1
	ldr r1, [r6]
	movs r0, #1
	ands r0, r1
	cmp r0, #0
	beq .L080643cc
	mov r3, r9
	adds r5, r2, r3
	adds r7, r5, #4
	ldrh r4, [r5, #4]
	movs r2, #6
	adds r0, r1, #0
	ands r0, r2
	lsrs r0, r0, #1
	cmp r0, #1
	beq .L08064360
	cmp r0, #1
	blo .L0806433c
	cmp r0, #2
	beq .L0806437e
	cmp r0, #3
	beq .L08064390
	b .L080643b2
L_08064338:
	.word 0x03006830
.L0806433c:
	ldr r0, [r5]
	ldrh r0, [r0]
	adds r3, r0, r4
	ldr r0, L_0806435c
	cmp r3, r0
	ble .L0806437a
	movs r0, #7
	rsbs r0, r0, #0
	ands r1, r0
	movs r0, #2
	orrs r1, r0
	str r1, [r6]
	movs r3, #0xff
	lsls r3, r3, #8
	b .L0806437a
	.hword 0x0000
L_0806435c:
	.word 0x0000feff
.L08064360:
	ldr r0, [r5]
	ldrh r2, [r0, #2]
	subs r3, r4, r2
	ldrh r0, [r0, #4]
	cmp r3, r0
	bgt .L0806437a
	adds r3, r0, #0
	movs r0, #7
	rsbs r0, r0, #0
	ands r1, r0
	movs r0, #4
	orrs r1, r0
	str r1, [r6]
.L0806437a:
	strh r3, [r5, #4]
	b .L080643b2
.L0806437e:
	movs r0, #0x10
	ands r0, r1
	cmp r0, #0
	beq .L080643b2
	movs r3, #7
	rsbs r3, r3, #0
	ands r1, r3
	orrs r1, r2
	str r1, [r6]
.L08064390:
	ldr r0, [r5]
	ldrh r5, [r7]
	ldrh r0, [r0, #6]
	subs r3, r5, r0
	cmp r3, #0xff
	bgt .L080643b0
	movs r3, #0
	ldr r1, L_080643c8
	ldr r0, [r1]
	adds r0, #0x18
	add r0, r12
	ldr r1, [r0]
	movs r2, #8
	rsbs r2, r2, #0
	ands r1, r2
	str r1, [r0]
.L080643b0:
	strh r3, [r7]
.L080643b2:
	mov r2, r10
	ands r4, r2
	mov r0, r10
	ldrh r7, [r7]
	ands r0, r7
	cmp r4, r0
	beq .L0806442a
	ldr r3, L_080643c8
	ldr r0, [r3]
	b .L0806441e
	.hword 0x0000
L_080643c8:
	.word 0x03006830
.L080643cc:
	movs r0, #0x20
	ands r0, r1
	cmp r0, #0
	beq .L0806442a
	mov r5, r9
	adds r0, r2, r5
	adds r7, r0, #4
	ldrh r4, [r0, #4]
	ldr r0, [r0]
	adds r3, r4, r0
	cmp r0, #0
	blt .L080643fc
	ldr r0, L_080643f8
	cmp r3, r0
	ble .L0806440e
	movs r0, #0x21
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r6]
	movs r3, #0xff
	lsls r3, r3, #8
	b .L0806440e
L_080643f8:
	.word 0x0000feff
.L080643fc:
	movs r0, #0x80
	lsls r0, r0, #1
	cmp r3, r0
	bgt .L0806440e
	movs r0, #0x21
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r6]
	movs r3, #0
.L0806440e:
	strh r3, [r7]
	mov r0, r10
	ands r4, r0
	ands r3, r0
	cmp r4, r3
	beq .L0806442a
	ldr r1, L_0806449c
	ldr r0, [r1]
.L0806441e:
	adds r0, #0x18
	add r0, r12
	ldr r1, [r0]
	movs r2, #0x80
	orrs r1, r2
	str r1, [r0]
.L0806442a:
	movs r2, #8
	add r9, r2
	movs r3, #4
	add r12, r3
	movs r5, #1
	rsbs r5, r5, #0
	add r8, r5
	mov r0, r8
	cmp r0, #0
	blt .L08064440
	b .L08064300
.L08064440:
	movs r1, #0
	mov r8, r1
	ldr r1, L_0806449c
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r8, r0
	blt .L08064450
	b .L08064578
.L08064450:
	subs r2, #0xf
	mov r9, r2
	movs r6, #0xff
	lsls r6, r6, #8
.L08064458:
	ldr r0, [r1]
	adds r0, #0xd4
	ldr r1, [r0]
	mov r3, r8
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r2, [r0]
	cmp r2, #0
	bne .L0806446c
	b .L08064568
.L0806446c:
	ldr r1, [r2, #0x38]
	movs r0, #1
	ands r0, r1
	cmp r0, #0
	beq .L08064514
	adds r5, r2, #0
	adds r5, #0x24
	adds r7, r2, #0
	adds r7, #0x28
	ldrh r4, [r2, #0x28]
	movs r3, #6
	adds r0, r1, #0
	ands r0, r3
	lsrs r0, r0, #1
	cmp r0, #1
	beq .L080644c0
	cmp r0, #1
	blo .L080644a0
	cmp r0, #2
	beq .L080644dc
	cmp r0, #3
	beq .L080644ec
	b .L08064506
	.hword 0x0000
L_0806449c:
	.word 0x03006830
.L080644a0:
	ldr r0, [r2, #0x24]
	ldrh r0, [r0]
	adds r3, r0, r4
	ldr r0, L_080644bc
	cmp r3, r0
	ble .L080644d8
	mov r5, r9
	ands r1, r5
	movs r0, #2
	orrs r1, r0
	str r1, [r2, #0x38]
	movs r3, #0xff
	lsls r3, r3, #8
	b .L080644d8
L_080644bc:
	.word 0x0000feff
.L080644c0:
	ldr r0, [r2, #0x24]
	ldrh r5, [r0, #2]
	subs r3, r4, r5
	ldrh r0, [r0, #4]
	cmp r3, r0
	bgt .L080644d8
	adds r3, r0, #0
	mov r0, r9
	ands r1, r0
	movs r0, #4
	orrs r1, r0
	str r1, [r2, #0x38]
.L080644d8:
	strh r3, [r2, #0x28]
	b .L08064506
.L080644dc:
	movs r0, #0x10
	ands r0, r1
	cmp r0, #0
	beq .L08064506
	mov r0, r9
	ands r1, r0
	orrs r1, r3
	str r1, [r2, #0x38]
.L080644ec:
	ldr r0, [r5]
	ldrh r1, [r7]
	ldrh r0, [r0, #6]
	subs r3, r1, r0
	cmp r3, #0xff
	bgt .L08064504
	movs r3, #0
	ldr r0, [r2, #0x38]
	movs r1, #8
	rsbs r1, r1, #0
	ands r0, r1
	str r0, [r2, #0x38]
.L08064504:
	strh r3, [r7]
.L08064506:
	ands r4, r6
	adds r0, r6, #0
	ldrh r7, [r7]
	ands r0, r7
	cmp r4, r0
	beq .L08064568
	b .L08064560
.L08064514:
	movs r0, #0x20
	ands r0, r1
	cmp r0, #0
	beq .L08064568
	adds r7, r2, #0
	adds r7, #0x28
	ldrh r4, [r2, #0x28]
	ldr r0, [r2, #0x24]
	adds r3, r4, r0
	cmp r0, #0
	blt .L08064544
	ldr r0, L_08064540
	cmp r3, r0
	ble .L08064556
	movs r0, #0x21
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r2, #0x38]
	movs r3, #0xff
	lsls r3, r3, #8
	b .L08064556
	.hword 0x0000
L_08064540:
	.word 0x0000feff
.L08064544:
	movs r0, #0x80
	lsls r0, r0, #1
	cmp r3, r0
	bgt .L08064556
	movs r0, #0x21
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r2, #0x38]
	movs r3, #0
.L08064556:
	strh r3, [r7]
	ands r4, r6
	ands r3, r6
	cmp r4, r3
	beq .L08064568
.L08064560:
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	orrs r0, r1
	str r0, [r2, #0x38]
.L08064568:
	movs r2, #1
	add r8, r2
	ldr r1, L_08064588
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r8, r0
	bge .L08064578
	b .L08064458
.L08064578:
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08064588:
	.word 0x03006830

.global mod_UpdPanSweep
.thumb_func
.type mod_UpdPanSweep, %function
mod_UpdPanSweep:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	movs r5, #0
	ldr r1, L_080645dc
	ldr r0, [r1]
	mov r12, r1
	ldrb r0, [r0, #8]
	cmp r5, r0
	bge .L0806461e
	movs r7, #0x80
	lsls r7, r7, #6
.L080645a4:
	ldr r0, [r1]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r5, #2
	adds r0, r0, r1
	ldr r3, [r0]
	cmp r3, #0
	beq .L08064612
	mov r8, r3
	ldrh r4, [r3, #0x12]
	movs r0, #0x12
	ldrsh r2, [r3, r0]
	cmp r2, #0
	beq .L08064612
	movs r6, #0xa
	ldrsh r1, [r3, r6]
	adds r0, r2, #0
	adds r1, r1, r0
	cmp r2, #0
	ble .L080645e0
	ldrb r0, [r3, #0x1b]
	lsls r2, r0, #8
	cmp r1, r2
	blt .L080645f8
	subs r0, r1, r2
	subs r1, r2, r0
	b .L080645ec
	.hword 0x0000
L_080645dc:
	.word 0x03006830
.L080645e0:
	ldrb r6, [r3, #0x1a]
	lsls r2, r6, #8
	cmp r1, r2
	bgt .L080645f8
	subs r0, r2, r1
	adds r1, r2, r0
.L080645ec:
	ldr r0, [r3, #0x38]
	ands r0, r7
	cmp r0, #0
	beq .L080645f6
	rsbs r0, r4, #0
.L080645f6:
	strh r0, [r3, #0x12]
.L080645f8:
	mov r0, r8
	strh r1, [r0, #0xa]
	asrs r0, r1, #8
	adds r2, r3, #0
	adds r2, #0x3c
	ldrb r1, [r2]
	cmp r0, r1
	beq .L08064612
	strb r0, [r2]
	ldr r0, [r3, #0x38]
	movs r1, #0x80
	orrs r0, r1
	str r0, [r3, #0x38]
.L08064612:
	adds r5, #1
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r5, r0
	blt .L080645a4
.L0806461e:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0

.global voice_CalcMixVolume
.thumb_func
.type voice_CalcMixVolume, %function
voice_CalcMixVolume:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r5, r0, #0
	ldr r2, L_08064698
	ldr r0, [r2]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r5, #2
	adds r0, r0, r1
	ldr r0, [r0]
	mov r12, r0
	cmp r0, #0
	beq .L08064734
	ldrh r0, [r0, #0x28]
	lsrs r4, r0, #8
	cmp r4, #0
	beq .L0806464e
	adds r4, #1
.L0806464e:
	mov r0, r12
	adds r0, #0x2b
	ldrb r0, [r0]
	muls r0, r4, r0
	lsls r0, r0, #8
	lsrs r4, r0, #0x10
	mov r0, r12
	adds r0, #0x2a
	strb r4, [r0]
	adds r0, #0x12
	ldrb r3, [r0]
	ldr r1, [r2]
	adds r1, #0xc8
	lsls r0, r5, #3
	subs r0, r0, r5
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r7, r1, r0
	lsls r1, r3, #0x18
	lsrs r0, r1, #0x18
	cmp r0, #0x3f
	bhi .L080646a8
	movs r0, #0x40
	subs r0, r0, r3
	ldr r1, L_0806469c
	muls r0, r1, r0
	asrs r0, r0, #6
	ldr r1, L_080646a0
	adds r0, r0, r1
	muls r0, r4, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r6, r0, #0x18
	ldr r0, L_080646a4
	muls r0, r3, r0
	asrs r0, r0, #6
	b .L080646cc
L_08064698:
	.word 0x03006830
L_0806469c:
	.word 0x00004ac8
L_080646a0:
	.word 0x0000b538
L_080646a4:
	.word 0x0000b818
.L080646a8:
	cmp r1, #0
	blt .L080646e8
	movs r0, #0x7f
	subs r0, r0, r3
	ldr r1, L_080646dc
	muls r0, r1, r0
	asrs r0, r0, #6
	muls r0, r4, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r6, r0, #0x18
	adds r1, r3, #0
	subs r1, #0x3f
	ldr r0, L_080646e0
	muls r0, r1, r0
	asrs r0, r0, #6
	ldr r1, L_080646e4
	adds r0, r0, r1
.L080646cc:
	muls r0, r4, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r5, r0, #0x18
	movs r0, #0
	mov r8, r0
	b .L080646f8
	.hword 0x0000
L_080646dc:
	.word 0x0000b818
L_080646e0:
	.word 0x00004ac8
L_080646e4:
	.word 0x0000b538
.L080646e8:
	ldr r0, L_0806470c
	muls r0, r4, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r5, r0, #0x18
	adds r6, r5, #0
	movs r1, #1
	mov r8, r1
.L080646f8:
	mov r1, r12
	ldr r0, [r1, #0x38]
	movs r1, #0x80
	lsls r1, r1, #9
	ands r0, r1
	cmp r0, #0
	beq .L08064710
	ldr r0, [r2]
	adds r0, #0xc6
	b .L08064714
L_0806470c:
	.word 0x0000b538
.L08064710:
	ldr r0, [r2]
	adds r0, #0xc4
.L08064714:
	ldrh r0, [r0]
	adds r4, r0, #0
	bl snd_Lock
	adds r0, r6, #0
	muls r0, r4, r0
	asrs r0, r0, #8
	strb r0, [r7, #0x18]
	adds r0, r5, #0
	muls r0, r4, r0
	asrs r0, r0, #8
	strb r0, [r7, #0x19]
	mov r0, r8
	strb r0, [r7, #0x1a]
	bl snd_Unlock
.L08064734:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global sndHandle
.thumb_func
.type sndHandle, %function
sndHandle:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0xc
	bl macro_Execute
	bl mod_UpdPitchSweep
	bl mod_UpdVibrato
	bl mod_UpdPortamento
	bl mod_UpdPulseSweep
	bl mod_UpdLoopScan
	bl env_Update
	bl mod_UpdPanSweep
	movs r0, #0
	mov r9, r0
	movs r4, #0
.L08064772:
	ldr r0, L_0806481c
	ldr r3, [r0]
	mov r2, r9
	lsls r1, r2, #2
	adds r0, r3, #0
	adds r0, #0x18
	adds r2, r0, r1
	ldr r1, [r2]
	movs r0, #0x40
	ands r0, r1
	cmp r0, #0
	beq .L080647be
	movs r0, #0x41
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r2]
	adds r0, r3, r4
	ldrh r3, [r0, #0x28]
	ldrh r1, [r0, #0x2a]
	adds r2, r3, r1
	ldrh r3, [r0, #0x2c]
	adds r2, r3, r2
	ldrh r1, [r0, #0x34]
	adds r2, r1, r2
	ldrh r3, [r0, #0x3c]
	adds r2, r3, r2
	adds r0, #0x44
	ldrh r0, [r0]
	adds r2, r0, r2
	lsls r2, r2, #0x10
	lsrs r0, r2, #0x18
	movs r1, #0xff
	lsls r1, r1, #0x10
	ands r1, r2
	asrs r1, r1, #0x10
	mov r2, r9
	bl psg_SetFreq
.L080647be:
	adds r4, #0x24
	movs r0, #1
	add r9, r0
	mov r1, r9
	cmp r1, #2
	ble .L08064772
	movs r2, #0
	mov r9, r2
	movs r5, #0
.L080647d0:
	ldr r0, L_0806481c
	ldr r4, [r0]
	adds r0, r4, #0
	adds r0, #0x18
	adds r2, r0, r5
	ldr r1, [r2]
	movs r0, #0x80
	ands r0, r1
	cmp r0, #0
	beq .L08064834
	movs r3, #0x81
	rsbs r3, r3, #0
	ands r3, r1
	str r3, [r2]
	mov r1, r9
	lsls r0, r1, #3
	adds r2, r4, r0
	adds r0, r2, #0
	adds r0, #0x98
	ldrh r0, [r0]
	lsrs r1, r0, #8
	cmp r1, #0
	beq .L08064800
	adds r1, #1
.L08064800:
	adds r0, r2, #0
	adds r0, #0x9b
	ldrb r0, [r0]
	muls r0, r1, r0
	lsls r0, r0, #8
	lsrs r1, r0, #0x10
	movs r0, #0x80
	lsls r0, r0, #9
	ands r3, r0
	cmp r3, #0
	beq .L08064820
	adds r0, r4, #0
	adds r0, #0xc6
	b .L08064824
L_0806481c:
	.word 0x03006830
.L08064820:
	adds r0, r4, #0
	adds r0, #0xc4
.L08064824:
	ldrh r0, [r0]
	muls r0, r1, r0
	lsls r0, r0, #8
	lsrs r1, r0, #0x10
	adds r0, r1, #0
	mov r1, r9
	bl psg_SetVolume
.L08064834:
	ldr r2, L_0806486c
	ldr r3, [r2]
	adds r0, r3, #0
	adds r0, #0x18
	adds r0, r0, r5
	ldr r1, [r0]
	movs r0, #0x80
	lsls r0, r0, #2
	ands r1, r0
	adds r6, r2, #0
	cmp r1, #0
	beq .L08064892
	mov r2, r9
	cmp r2, #3
	beq .L08064874
	ldr r0, L_08064870
	adds r0, r5, r0
	ldr r2, [r0]
	mov r1, r9
	lsls r0, r1, #1
	adds r1, r3, #0
	adds r1, #0xbc
	adds r1, r1, r0
	movs r3, #0x80
	lsls r3, r3, #8
	adds r0, r3, #0
	ldrh r1, [r1]
	b .L08064880
L_0806486c:
	.word 0x03006830
L_08064870:
	.word 0x087ffc68
.L08064874:
	ldr r0, L_0806494c
	ldr r2, [r0, #0xc]
	ldrh r0, [r2]
	movs r3, #0x80
	lsls r3, r3, #8
	adds r1, r3, #0
.L08064880:
	orrs r0, r1
	strh r0, [r2]
	ldr r0, [r6]
	adds r0, #0x18
	adds r0, r0, r5
	ldr r1, [r0]
	ldr r2, L_08064950
	ands r1, r2
	str r1, [r0]
.L08064892:
	adds r5, #4
	movs r0, #1
	add r9, r0
	mov r1, r9
	cmp r1, #3
	ble .L080647d0
	movs r2, #0
	mov r9, r2
	adds r1, r6, #0
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r9, r0
	blt .L080648ae
	b .L08064a78
.L080648ae:
	movs r3, #0
	str r3, [sp]
	movs r0, #0
	str r0, [sp, #4]
	mov r10, r1
.L080648b8:
	ldr r0, [r1]
	adds r0, #0xd4
	ldr r0, [r0]
	ldr r1, [sp, #4]
	adds r0, r1, r0
	ldr r5, [r0]
	cmp r5, #0
	bne .L080648ca
	b .L08064a5c
.L080648ca:
	ldrh r0, [r5, #0x36]
	cmp r0, #0
	beq .L080648e2
	adds r0, r5, #0
	adds r0, #0x3f
	ldrh r2, [r5, #0x36]
	ldrb r0, [r0]
	subs r0, r2, r0
	cmp r0, #0
	bge .L080648e0
	movs r0, #0
.L080648e0:
	strh r0, [r5, #0x36]
.L080648e2:
	ldr r1, [r5, #0x38]
	movs r0, #0x80
	ands r0, r1
	cmp r0, #0
	bne .L080648ee
	b .L080649ee
.L080648ee:
	movs r0, #0x81
	rsbs r0, r0, #0
	ands r1, r0
	str r1, [r5, #0x38]
	ldrh r3, [r5, #0x28]
	lsrs r4, r3, #8
	cmp r4, #0
	beq .L08064900
	adds r4, #1
.L08064900:
	adds r0, r5, #0
	adds r0, #0x2b
	ldrb r0, [r0]
	muls r0, r4, r0
	lsls r0, r0, #8
	lsrs r3, r0, #0x10
	adds r0, r5, #0
	adds r0, #0x2a
	strb r3, [r0]
	ldr r0, [r6]
	adds r0, #0xc8
	ldr r0, [r0]
	ldr r1, [sp]
	adds r0, r0, r1
	mov r8, r0
	adds r2, r5, #0
	adds r2, #0x3c
	ldrb r0, [r2]
	lsls r1, r0, #0x18
	lsrs r0, r1, #0x18
	cmp r0, #0x3f
	bhi .L08064960
	ldrb r2, [r2]
	movs r0, #0x40
	subs r0, r0, r2
	ldr r1, L_08064954
	muls r0, r1, r0
	asrs r0, r0, #6
	ldr r1, L_08064958
	adds r0, r0, r1
	muls r0, r3, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r7, r0, #0x18
	ldr r0, L_0806495c
	muls r0, r2, r0
	asrs r0, r0, #6
	b .L08064984
L_0806494c:
	.word 0x087ffc68
L_08064950:
	.word 0xfffffdff
L_08064954:
	.word 0x00004ac8
L_08064958:
	.word 0x0000b538
L_0806495c:
	.word 0x0000b818
.L08064960:
	cmp r1, #0
	blt .L0806499c
	ldrb r2, [r2]
	movs r0, #0x7f
	subs r0, r0, r2
	ldr r1, L_08064990
	muls r0, r1, r0
	asrs r0, r0, #6
	muls r0, r3, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r7, r0, #0x18
	subs r2, #0x3f
	ldr r0, L_08064994
	muls r0, r2, r0
	asrs r0, r0, #6
	ldr r2, L_08064998
	adds r0, r0, r2
.L08064984:
	muls r0, r3, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r6, r0, #0x18
	movs r2, #0
	b .L080649aa
L_08064990:
	.word 0x0000b818
L_08064994:
	.word 0x00004ac8
L_08064998:
	.word 0x0000b538
.L0806499c:
	ldr r0, L_080649c0
	muls r0, r3, r0
	asrs r0, r0, #0x10
	lsls r0, r0, #0x18
	lsrs r6, r0, #0x18
	adds r7, r6, #0
	movs r2, #1
.L080649aa:
	ldr r0, [r5, #0x38]
	movs r1, #0x80
	lsls r1, r1, #9
	ands r0, r1
	cmp r0, #0
	beq .L080649c4
	mov r3, r10
	ldr r0, [r3]
	adds r0, #0xc6
	b .L080649ca
	.hword 0x0000
L_080649c0:
	.word 0x0000b538
.L080649c4:
	mov r1, r10
	ldr r0, [r1]
	adds r0, #0xc4
.L080649ca:
	ldrh r0, [r0]
	adds r4, r0, #0
	str r2, [sp, #8]
	bl snd_Lock
	adds r0, r7, #0
	muls r0, r4, r0
	asrs r0, r0, #8
	mov r3, r8
	strb r0, [r3, #0x18]
	adds r0, r6, #0
	muls r0, r4, r0
	asrs r0, r0, #8
	strb r0, [r3, #0x19]
	ldr r2, [sp, #8]
	strb r2, [r3, #0x1a]
	bl snd_Unlock
.L080649ee:
	ldr r1, [r5, #0x38]
	movs r0, #0x40
	ands r0, r1
	cmp r0, #0
	beq .L08064a3e
	movs r0, #0x41
	rsbs r0, r0, #0
	ands r0, r1
	str r0, [r5, #0x38]
	movs r1, #0xa0
	lsls r1, r1, #5
	ands r0, r1
	cmp r0, #0
	beq .L08064a3e
	mov r1, r10
	ldr r0, [r1]
	adds r0, #0xc8
	ldr r4, [r0]
	ldr r2, [sp]
	adds r4, r4, r2
	ldrh r3, [r5]
	ldrh r1, [r5, #2]
	adds r0, r3, r1
	ldrh r2, [r5, #4]
	adds r0, r2, r0
	ldrh r3, [r5, #0xc]
	adds r0, r3, r0
	ldrh r1, [r5, #0x14]
	adds r0, r1, r0
	ldrh r2, [r5, #0x1c]
	adds r0, r2, r0
	lsls r0, r0, #0x10
	lsrs r2, r0, #0x10
	ldr r0, [r4]
	lsrs r1, r2, #8
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	bl snd_CalcStep
	strh r0, [r4, #0x14]
.L08064a3e:
	ldr r1, [r5, #0x38]
	movs r0, #0x80
	lsls r0, r0, #8
	ands r1, r0
	ldr r6, L_08064af8
	cmp r1, #0
	beq .L08064a5c
	mov r3, r10
	ldr r0, [r3]
	adds r0, #0xd4
	ldr r0, [r0]
	ldr r1, [sp, #4]
	adds r0, r1, r0
	movs r1, #0
	str r1, [r0]
.L08064a5c:
	ldr r2, [sp]
	adds r2, #0x1c
	str r2, [sp]
	ldr r3, [sp, #4]
	adds r3, #4
	str r3, [sp, #4]
	movs r0, #1
	add r9, r0
	adds r1, r6, #0
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r9, r0
	bge .L08064a78
	b .L080648b8
.L08064a78:
	bl snd_Lock
	movs r1, #0
	mov r9, r1
	ldr r1, L_08064af8
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r9, r0
	bge .L08064ade
	adds r6, r1, #0
	movs r4, #0
.L08064a8e:
	ldr r2, [r1]
	adds r0, r2, #0
	adds r0, #0xd4
	ldr r0, [r0]
	mov r1, r9
	lsls r3, r1, #2
	adds r0, r3, r0
	ldr r5, [r0]
	cmp r5, #0
	beq .L08064ace
	ldr r1, [r5, #0x38]
	movs r0, #0x80
	lsls r0, r0, #2
	ands r0, r1
	cmp r0, #0
	beq .L08064ace
	movs r0, #0xa0
	lsls r0, r0, #5
	ands r0, r1
	cmp r0, #0
	beq .L08064ace
	ldr r0, L_08064afc
	ands r1, r0
	str r1, [r5, #0x38]
	adds r0, r2, #0
	adds r0, #0xcc
	ldr r1, [r0]
	adds r1, r3, r1
	subs r0, #4
	ldr r0, [r0]
	adds r0, r0, r4
	str r0, [r1]
.L08064ace:
	adds r4, #0x1c
	movs r2, #1
	add r9, r2
	adds r1, r6, #0
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	cmp r9, r0
	blt .L08064a8e
.L08064ade:
	bl snd_Unlock
	bl seq_Handle
	add sp, #0xc
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08064af8:
	.word 0x03006830
L_08064afc:
	.word 0xfffffdff

.global psg_SetDuty
.thumb_func
.type psg_SetDuty, %function
psg_SetDuty:
	ldr r2, L_08064b10
	lsls r1, r1, #2
	adds r1, r1, r2
	ldr r1, [r1]
	lsls r0, r0, #6
	strb r0, [r1]
	bx lr
	.hword 0x0000
L_08064b10:
	.word 0x087ffc78

.global psg_SetNoise
.thumb_func
.type psg_SetNoise, %function
psg_SetNoise:
	ldr r1, L_08064b1c
	ldr r1, [r1, #0xc]
	strb r0, [r1]
	bx lr
L_08064b1c:
	.word 0x087ffc68

.global psg_SetHWEnvelope
.thumb_func
.type psg_SetHWEnvelope, %function
psg_SetHWEnvelope:
	push {r4, lr}
	lsls r0, r0, #0x18
	lsrs r4, r0, #0x18
	movs r0, #8
	ands r0, r4
	cmp r0, #0
	bne .L08064b4c
	ldr r0, L_08064b44
	lsls r3, r1, #2
	adds r0, r3, r0
	ldr r2, [r0]
	ldrh r1, [r2]
	ldr r0, L_08064b48
	ands r0, r1
	lsls r1, r4, #8
	orrs r0, r1
	strh r0, [r2]
	b .L08064b5a
L_08064b44:
	.word 0x087ffc78
L_08064b48:
	.word 0x0000f0c0
.L08064b4c:
	ldr r0, L_08064b78
	lsls r2, r1, #2
	adds r0, r2, r0
	ldr r1, [r0]
	lsls r0, r4, #8
	strh r0, [r1]
	adds r3, r2, #0
.L08064b5a:
	ldr r0, L_08064b7c
	ldr r2, [r0]
	adds r2, #0x18
	adds r2, r2, r3
	ldr r0, [r2]
	movs r1, #0xa2
	rsbs r1, r1, #0
	ands r0, r1
	movs r1, #0x80
	lsls r1, r1, #2
	orrs r0, r1
	str r0, [r2]
	pop {r4}
	pop {r0}
	bx r0
L_08064b78:
	.word 0x087ffc78
L_08064b7c:
	.word 0x03006830

.global voice_Trigger
.thumb_func
.type voice_Trigger, %function
voice_Trigger:
	adds r2, r0, #0
	cmp r2, #3
	bgt .L08064ba0
	ldr r0, L_08064b9c
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0xb0
	lsls r2, r2, #2
	orrs r0, r2
	str r0, [r1]
	b .L08064bb8
L_08064b9c:
	.word 0x03006830
.L08064ba0:
	subs r2, #4
	ldr r0, L_08064bbc
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r0, [r0]
	lsls r1, r2, #6
	adds r1, r1, r0
	ldr r0, [r1, #0x38]
	movs r2, #0x80
	lsls r2, r2, #2
	orrs r0, r2
	str r0, [r1, #0x38]
.L08064bb8:
	bx lr
	.hword 0x0000
L_08064bbc:
	.word 0x03006830

.global psg_LoadWave
.thumb_func
.type psg_LoadWave, %function
psg_LoadWave:
	adds r2, r0, #0
	ldr r3, L_08064be4
	ldr r0, [r2]
	cmp r0, #0x10
	bne .L08064bec
	ldr r1, L_08064be8
	movs r0, #0x40
	strb r0, [r1]
	ldr r0, [r2, #0x10]
	stm r3!, {r0}
	ldr r0, [r2, #0x14]
	stm r3!, {r0}
	ldr r0, [r2, #0x18]
	stm r3!, {r0}
	ldr r0, [r2, #0x1c]
	str r0, [r3]
	movs r0, #0x80
	b .L08064c1c
L_08064be4:
	.word 0x04000090
L_08064be8:
	.word 0x04000070
.L08064bec:
	ldr r1, L_08064c20
	movs r0, #0x60
	strb r0, [r1]
	ldr r0, [r2, #0x10]
	str r0, [r3]
	ldr r3, L_08064c24
	ldr r0, [r2, #0x14]
	stm r3!, {r0}
	ldr r0, [r2, #0x18]
	stm r3!, {r0}
	ldr r0, [r2, #0x1c]
	str r0, [r3]
	ldr r3, L_08064c28
	movs r0, #0x20
	strb r0, [r1]
	ldr r0, [r2, #0x20]
	stm r3!, {r0}
	ldr r0, [r2, #0x24]
	stm r3!, {r0}
	ldr r0, [r2, #0x28]
	stm r3!, {r0}
	ldr r0, [r2, #0x2c]
	str r0, [r3]
	movs r0, #0xa0
.L08064c1c:
	strb r0, [r1]
	bx lr
L_08064c20:
	.word 0x04000070
L_08064c24:
	.word 0x04000094
L_08064c28:
	.word 0x04000090

.global mod_SetPitchSweep
.thumb_func
.type mod_SetPitchSweep, %function
mod_SetPitchSweep:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	adds r6, r1, #0
	adds r5, r2, #0
	cmp r3, #2
	bgt .L08064c54
	ldr r0, L_08064c50
	ldr r2, [r0]
	lsls r1, r4, #3
	lsls r0, r3, #3
	adds r0, r0, r3
	lsls r0, r0, #2
	adds r1, r1, r0
	adds r2, r2, r1
	strh r5, [r2, #0x30]
	strh r6, [r2, #0x2e]
	b .L08064c70
	.hword 0x0000
L_08064c50:
	.word 0x03006830
.L08064c54:
	cmp r3, #3
	ble .L08064c70
	ldr r0, L_08064c78
	ldr r0, [r0]
	adds r0, #0xd0
	lsls r1, r3, #6
	ldr r2, L_08064c7c
	adds r1, r1, r2
	ldr r0, [r0]
	adds r0, r0, r1
	lsls r1, r4, #3
	adds r0, r0, r1
	strh r5, [r0, #8]
	strh r6, [r0, #6]
.L08064c70:
	pop {r4, r5, r6}
	pop {r0}
	bx r0
	.hword 0x0000
L_08064c78:
	.word 0x03006830
L_08064c7c:
	.word 0xffffff00

.global voice_KeyOff
.thumb_func
.type voice_KeyOff, %function
voice_KeyOff:
	push {r4, lr}
	adds r2, r0, #0
	ldr r0, L_08064ca0
	ldr r3, [r0]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r3, r1
	lsls r1, r2, #4
	ldr r0, [r0]
	adds r4, r0, r1
	cmp r2, #3
	bgt .L08064ca4
	lsls r0, r2, #2
	adds r0, #0x18
	adds r1, r3, r0
	b .L08064cb0
L_08064ca0:
	.word 0x03006830
.L08064ca4:
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r1, r1, r0
	subs r1, #0xc8
.L08064cb0:
	ldr r2, [r1]
	movs r0, #0x80
	lsls r0, r0, #1
	orrs r2, r0
	str r2, [r1]
	movs r0, #9
	ands r0, r2
	cmp r0, #1
	bne .L08064cdc
	movs r3, #0x10
	orrs r3, r2
	str r3, [r1]
	movs r2, #6
	adds r0, r3, #0
	ands r0, r2
	cmp r0, #2
	bhi .L08064cdc
	movs r0, #7
	rsbs r0, r0, #0
	ands r3, r0
	orrs r3, r2
	str r3, [r1]
.L08064cdc:
	ldr r1, [r4, #4]
	cmp r1, #0
	beq .L08064ce8
	movs r0, #0
	strh r0, [r4, #0xa]
	str r1, [r4]
.L08064ce8:
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000

.global voice_UpdateStep
.thumb_func
.type voice_UpdateStep, %function
voice_UpdateStep:
	push {r4, lr}
	adds r2, r0, #0
	ldr r0, L_08064d44
	ldr r4, [r0]
	adds r0, r4, #0
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	ldr r3, [r0]
	cmp r3, #0
	beq .L08064d3e
	adds r1, r4, #0
	adds r1, #0xc8
	lsls r0, r2, #3
	subs r0, r0, r2
	lsls r0, r0, #2
	ldr r4, [r1]
	adds r4, r4, r0
	ldrh r0, [r3]
	ldrh r1, [r3, #2]
	adds r2, r0, r1
	ldrh r0, [r3, #4]
	adds r2, r0, r2
	ldrh r1, [r3, #0xc]
	adds r2, r1, r2
	ldrh r0, [r3, #0x14]
	adds r2, r0, r2
	ldrh r3, [r3, #0x1c]
	adds r2, r3, r2
	lsls r2, r2, #0x10
	lsrs r2, r2, #0x10
	ldr r0, [r4]
	lsrs r1, r2, #8
	lsls r2, r2, #0x18
	lsrs r2, r2, #0x18
	bl snd_CalcStep
	strh r0, [r4, #0x14]
.L08064d3e:
	pop {r4}
	pop {r0}
	bx r0
L_08064d44:
	.word 0x03006830

.global snd_OutputInit
.thumb_func
.type snd_OutputInit, %function
snd_OutputInit:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0x14
	adds r7, r0, #0
	str r1, [sp]
	ldrb r0, [r7, #2]
	cmp r0, #0
	bne .L08064d62
	movs r0, #0
	b .L080651b4
.L08064d62:
	ldr r4, L_08064db8
	ldr r0, [r4]
	adds r0, #0xcc
	ldr r0, [r0]
	ldrb r2, [r7, #2]
	lsls r1, r2, #2
	bl snd_memclr
	ldr r0, [r4]
	adds r0, #0xc8
	ldr r0, [r0]
	ldrb r3, [r7, #2]
	lsls r1, r3, #3
	subs r1, r1, r3
	lsls r1, r1, #2
	bl snd_memclr
	ldr r0, [r4]
	adds r0, #0xd4
	ldr r0, [r0]
	ldrb r2, [r7, #2]
	lsls r1, r2, #2
	bl snd_memclr
	ldr r0, [r4]
	adds r0, #0xd0
	ldr r0, [r0]
	ldrb r3, [r7, #2]
	lsls r1, r3, #6
	bl snd_memclr
	ldr r0, [r4]
	adds r6, r0, #0
	adds r6, #0xd8
	movs r0, #3
	ldrb r1, [r7, #3]
	ands r0, r1
	cmp r0, #3
	bne .L08064dc4
	ldr r4, L_08064dbc
	ldr r3, L_08064dc0
	b .L08064df0
	.hword 0x0000
L_08064db8:
	.word 0x03006830
L_08064dbc:
	.word arm_MixMono
L_08064dc0:
	.word arm_EchoStereo
.L08064dc4:
	cmp r0, #2
	bne .L08064dd8
	ldr r4, L_08064dd0
	ldr r3, L_08064dd4
	b .L08064df0
	.hword 0x0000
L_08064dd0:
	.word arm_MixMonoInterp
L_08064dd4:
	.word arm_MixMono
.L08064dd8:
	cmp r0, #1
	bne .L08064dec
	ldr r4, L_08064de4
	ldr r3, L_08064de8
	b .L08064df0
	.hword 0x0000
L_08064de4:
	.word arm_MixStereo
L_08064de8:
	.word arm_MixMonoInterp
.L08064dec:
	ldr r4, L_08064e04
	ldr r3, L_08064e08
.L08064df0:
	ldrb r1, [r7, #3]
	movs r0, #2
	ands r0, r1
	cmp r0, #0
	bne .L08064e14
	ldr r2, L_08064e0c
	mov r9, r2
	ldr r5, L_08064e10
	b .L08064e1a
	.hword 0x0000
L_08064e04:
	.word arm_MixStereoInterp
L_08064e08:
	.word arm_MixStereo
L_08064e0c:
	.word arm_OutStereo
L_08064e10:
	.word arm_OutMono
.L08064e14:
	ldr r0, L_08064e2c
	mov r9, r0
	ldr r5, L_08064e30
.L08064e1a:
	movs r0, #2
	ands r0, r1
	cmp r0, #0
	beq .L08064e3c
	ldr r2, L_08064e34
	mov r10, r2
	ldr r0, L_08064e38
	b .L08064e5a
	.hword 0x0000
L_08064e2c:
	.word arm_OutMono
L_08064e30:
	.word arm_MixStereoInterp
L_08064e34:
	.word arm_EchoMono
L_08064e38:
	.word 0x08068bc4
.L08064e3c:
	movs r0, #4
	ands r0, r1
	cmp r0, #0
	beq .L08064e54
	ldr r2, L_08064e4c
	mov r10, r2
	ldr r0, L_08064e50
	b .L08064e5a
L_08064e4c:
	.word arm_EchoStereoHalf
L_08064e50:
	.word arm_EchoMono
.L08064e54:
	ldr r2, L_08064eb8
	mov r10, r2
	ldr r0, L_08064ebc
.L08064e5a:
	mov r12, r0
	movs r0, #8
	ands r0, r1
	cmp r0, #0
	bne .L08064f08
	ldr r1, [sp]
	ldr r2, [r1, #4]
	str r2, [r6]
	adds r1, r4, #0
	adds r0, r6, #0
	adds r0, #0x21
	str r0, [sp, #0xc]
	subs r0, #1
	str r0, [sp, #8]
	movs r0, #0x24
	adds r0, r0, r6
	mov r8, r0
	adds r0, r6, #0
	adds r0, #0x3f
	str r0, [sp, #0x10]
	cmp r1, r3
	bhs .L08064e8e
.L08064e86:
	ldm r1!, {r0}
	stm r2!, {r0}
	cmp r1, r3
	blo .L08064e86
.L08064e8e:
	str r2, [r6, #8]
	mov r1, r9
	cmp r1, r5
	bhs .L08064e9e
.L08064e96:
	ldm r1!, {r0}
	stm r2!, {r0}
	cmp r1, r5
	blo .L08064e96
.L08064e9e:
	ldrb r1, [r7, #3]
	movs r0, #2
	ands r0, r1
	cmp r0, #0
	bne .L08064eb0
	movs r0, #6
	ands r0, r1
	cmp r0, #0
	bne .L08064ec0
.L08064eb0:
	ldr r0, [r6]
	str r0, [r6, #4]
	b .L08064eec
	.hword 0x0000
L_08064eb8:
	.word arm_EchoStereo
L_08064ebc:
	.word arm_EchoStereoHalf
.L08064ec0:
	movs r0, #1
	ands r0, r1
	cmp r0, #0
	bne .L08064ed8
	ldr r4, L_08064ed0
	ldr r3, L_08064ed4
	b .L08064edc
	.hword 0x0000
L_08064ed0:
	.word arm_MixMonoInterp
L_08064ed4:
	.word arm_MixMono
.L08064ed8:
	ldr r4, L_08064f00
	ldr r3, L_08064f04
.L08064edc:
	str r2, [r6, #4]
	adds r1, r4, #0
	cmp r1, r3
	bhs .L08064eec
.L08064ee4:
	ldm r1!, {r0}
	stm r2!, {r0}
	cmp r1, r3
	blo .L08064ee4
.L08064eec:
	str r2, [r6, #0xc]
	mov r1, r10
	cmp r1, r12
	bhs .L08064f4e
.L08064ef4:
	ldm r1!, {r0}
	stm r2!, {r0}
	cmp r1, r12
	blo .L08064ef4
	b .L08064f4e
	.hword 0x0000
L_08064f00:
	.word arm_MixMono
L_08064f04:
	.word arm_EchoStereo
.L08064f08:
	str r4, [r6]
	mov r1, r9
	str r1, [r6, #8]
	ldrb r1, [r7, #3]
	movs r0, #2
	ands r0, r1
	cmp r0, #0
	bne .L08064f20
	movs r0, #6
	ands r0, r1
	cmp r0, #0
	bne .L08064f24
.L08064f20:
	str r4, [r6, #4]
	b .L08064f32
.L08064f24:
	movs r0, #1
	ands r0, r1
	ldr r1, L_08064f68
	cmp r0, #0
	bne .L08064f30
	ldr r1, L_08064f6c
.L08064f30:
	str r1, [r6, #4]
.L08064f32:
	mov r2, r10
	str r2, [r6, #0xc]
	adds r3, r6, #0
	adds r3, #0x21
	str r3, [sp, #0xc]
	adds r0, r6, #0
	adds r0, #0x20
	str r0, [sp, #8]
	movs r1, #0x24
	adds r1, r1, r6
	mov r8, r1
	adds r2, r6, #0
	adds r2, #0x3f
	str r2, [sp, #0x10]
.L08064f4e:
	ldr r3, [sp]
	ldr r1, [r3, #8]
	str r1, [r6, #0x10]
	movs r0, #2
	ldrb r2, [r7, #3]
	ands r0, r2
	cmp r0, #0
	bne .L08064f70
	movs r3, #0x80
	lsls r3, r3, #2
	adds r1, r1, r3
	b .L08064f76
	.hword 0x0000
L_08064f68:
	.word arm_MixMono
L_08064f6c:
	.word arm_MixMonoInterp
.L08064f70:
	movs r0, #0x80
	lsls r0, r0, #1
	adds r1, r1, r0
.L08064f76:
	str r1, [r6, #0x14]
	movs r0, #2
	ldrb r2, [r7, #3]
	ands r0, r2
	cmp r0, #0
	beq .L08064f86
	str r1, [r6, #0x18]
	b .L08064f8e
.L08064f86:
	movs r3, #0xc0
	lsls r3, r3, #1
	adds r0, r1, r3
	str r0, [r6, #0x18]
.L08064f8e:
	ldr r1, [r6, #0x18]
	movs r0, #0xc0
	lsls r0, r0, #1
	adds r1, r1, r0
	str r1, [r6, #0x1c]
	ldr r0, [r6, #0x10]
	subs r1, r1, r0
	bl snd_memclr
	ldr r1, L_0806500c
	mov r10, r1
	ldr r2, [r1]
	ldrb r0, [r7, #2]
	movs r1, #0
	strb r0, [r2, #8]
	ldr r2, [sp, #0xc]
	strb r1, [r2]
	ldrh r1, [r7]
	movs r0, #0x80
	lsls r0, r0, #0x11
	bl __divsi3
	mov r9, r0
	ldr r0, L_08065010
	mov r3, r9
	ands r3, r0
	mov r9, r3
	lsls r4, r3, #0x10
	asrs r4, r4, #0x10
	adds r0, r4, #0
	bl __floatsisf
	adds r2, r0, #0
	cmp r4, #0
	bge .L08064fdc
	ldr r1, L_08065014
	bl __addsf3
	adds r2, r0, #0
.L08064fdc:
	ldr r0, L_08065018
	adds r1, r2, #0
	bl __divsf3
	adds r5, r0, #0
	mov r0, r10
	ldr r4, [r0]
	adds r0, r5, #0
	bl __fixsfsi
	strh r0, [r4, #0xa]
	ldr r0, L_0806501c
	adds r1, r5, #0
	bl __divsf3
	bl __fixsfsi
	adds r1, r0, #0
	ldr r0, L_08065020
	cmp r1, r0
	bhi .L08065024
	movs r4, #0
	b .L0806505c
	.hword 0x0000
L_0806500c:
	.word 0x03006830
L_08065010:
	.word 0x0000ffc0
L_08065014:
	.word 0x47800000
L_08065018:
	.word 0x4b800000
L_0806501c:
	.word 0x51caa7e2
L_08065020:
	.word 0x003b9aca
.L08065024:
	ldr r0, L_08065030
	cmp r1, r0
	bhi .L08065034
	movs r4, #1
	lsrs r1, r1, #6
	b .L0806505c
L_08065030:
	.word 0x0ee6b280
.L08065034:
	ldr r0, L_08065040
	cmp r1, r0
	bhi .L08065044
	movs r4, #2
	lsrs r1, r1, #8
	b .L0806505c
L_08065040:
	.word 0x3b9aca00
.L08065044:
	ldr r0, L_08065054
	cmp r1, r0
	bls .L08065058
	movs r1, #1
	rsbs r1, r1, #0
	mov r10, r1
	b .L080650a4
	.hword 0x0000
L_08065054:
	.word 0xee6b2800
.L08065058:
	movs r4, #3
	lsrs r1, r1, #0xa
.L0806505c:
	cmp r1, #0
	blt .L08065068
	adds r0, r1, #0
	bl __floatsisf
	b .L0806507c
.L08065068:
	movs r0, #1
	ands r0, r1
	lsrs r1, r1, #1
	orrs r0, r1
	bl __floatsisf
	adds r2, r0, #0
	adds r1, r2, #0
	bl __addsf3
.L0806507c:
	adds r2, r0, #0
	ldr r1, L_08065140
	adds r0, r2, #0
	bl __divsf3
	bl libgcc_08069c00
	movs r1, #0x80
	lsls r1, r1, #9
	cmp r0, r1
	bls .L08065094
	adds r0, r1, #0
.L08065094:
	lsls r4, r4, #0x10
	mov r10, r4
	subs r0, r1, r0
	ldr r1, L_08065144
	ands r0, r1
	mov r2, r10
	orrs r2, r0
	mov r10, r2
.L080650a4:
	mov r3, r9
	lsls r0, r3, #0x10
	rsbs r0, r0, #0
	lsrs r0, r0, #0x10
	str r0, [sp, #4]
	lsls r0, r3, #1
	rsbs r0, r0, #0
	strh r0, [r6, #0x22]
	movs r0, #1
	mov r9, r0
	mov r2, r9
	ldr r1, [sp, #8]
	strb r2, [r1]
	ldrh r0, [r7, #4]
	cmp r0, #0
	beq .L08065154
	ldr r3, [sp]
	ldr r1, [r3, #0xc]
	movs r0, #6
	ldrb r2, [r7, #3]
	ands r0, r2
	movs r4, #0x80
	lsls r4, r4, #1
	cmp r0, #0
	beq .L080650d8
	movs r4, #0x80
.L080650d8:
	str r1, [r6, #0x24]
	lsls r5, r4, #1
	adds r1, r1, r5
	mov r3, r8
	str r1, [r3, #4]
	ldr r0, L_08065148
	ldr r0, [r0]
	ldrh r2, [r7, #4]
	ldrh r3, [r0, #0xa]
	adds r1, r2, #0
	muls r1, r3, r1
	adds r0, r1, #0
	movs r1, #0xfa
	lsls r1, r1, #9
	bl __udivsi3
	adds r1, r0, #0
	cmp r1, #0
	bne .L08065100
	movs r1, #1
.L08065100:
	cmp r1, #0xff
	bls .L08065106
	movs r1, #0xff
.L08065106:
	mov r0, r8
	ldr r2, [r0, #4]
	str r2, [r0, #8]
	str r2, [r0, #0xc]
	adds r0, r2, #0
	cmp r1, #1
	bls .L0806511a
	adds r0, r0, r5
	mov r3, r8
	str r0, [r3, #0xc]
.L0806511a:
	muls r1, r4, r1
	lsls r1, r1, #1
	adds r1, r2, r1
	mov r0, r8
	str r1, [r0, #0x10]
	ldr r0, [r6, #0x24]
	subs r1, r1, r0
	bl snd_memclr
	ldr r0, L_0806514c
	mov r1, r8
	strh r0, [r1, #0x14]
	ldr r0, L_08065144
	strh r0, [r1, #0x16]
	ldr r0, L_08065150
	strh r0, [r1, #0x18]
	mov r2, r9
	strb r2, [r1, #0x1a]
	b .L0806515c
L_08065140:
	.word 0x426e6b28
L_08065144:
	.word 0x0000ffff
L_08065148:
	.word 0x03006830
L_0806514c:
	.word 0x00007332
L_08065150:
	.word 0x0000cccc
.L08065154:
	mov r0, r8
	movs r1, #0x1c
	bl snd_memclr
.L0806515c:
	ldrb r0, [r7, #3]
	ldr r3, [sp, #0x10]
	strb r0, [r3]
	ldr r4, L_080651c4
	ldr r3, L_080651c8
	movs r1, #0
	ldr r2, L_080651cc
	movs r0, #7
.L0806516c:
	str r1, [r3]
	str r1, [r2]
	subs r0, #1
	cmp r0, #0
	bge .L0806516c
	ldr r1, L_080651d0
	ldr r0, [r6, #0x14]
	str r0, [r1]
	adds r1, #4
	ldr r0, L_080651c8
	str r0, [r1]
	adds r1, #8
	ldr r0, [r6, #0x18]
	str r0, [r1]
	adds r1, #4
	ldr r0, L_080651cc
	str r0, [r1]
	adds r0, #0x20
	ldr r1, L_080651d4
	str r1, [r0]
	adds r0, #0xc
	str r1, [r0]
	ldr r1, L_080651d8
	movs r0, #0xc0
	lsls r0, r0, #0x10
	mov r2, r10
	orrs r2, r0
	str r2, [r1]
	subs r1, #4
	movs r0, #0x80
	lsls r0, r0, #0x10
	ldr r3, [sp, #4]
	orrs r0, r3
	str r0, [r1]
	ldr r0, [r4]
	ldrh r0, [r0, #0xa]
.L080651b4:
	add sp, #0x14
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
L_080651c4:
	.word 0x03006830
L_080651c8:
	.word 0x040000a0
L_080651cc:
	.word 0x040000a4
L_080651d0:
	.word 0x040000bc
L_080651d4:
	.word 0xb6600004
L_080651d8:
	.word 0x04000104

.global sndOutputStop
.thumb_func
.type sndOutputStop, %function
sndOutputStop:
	push {r4, r5, r6, lr}
	ldr r0, L_0806525c
	ldr r4, [r0]
	adds r6, r4, #0
	adds r6, #0xd8
	bl snd_Lock
	adds r4, #0xf9
	movs r5, #0
	strb r5, [r4]
	ldr r3, L_08065260
	ldrh r2, [r3]
	ldr r1, L_08065264
	adds r0, r1, #0
	ands r0, r2
	strh r0, [r3]
	ldr r2, L_08065268
	ldrh r0, [r2]
	ands r1, r0
	strh r1, [r2]
	subs r2, #0x3c
	ldr r1, L_0806526c
	adds r0, r1, #0
	strh r0, [r2]
	ldr r1, L_08065270
	strh r0, [r1]
	mov r8, r8
	mov r8, r8
	mov r8, r8
	mov r8, r8
	movs r3, #0x88
	lsls r3, r3, #3
	adds r0, r3, #0
	strh r0, [r2]
	strh r0, [r1]
	strh r5, [r2]
	strh r5, [r1]
	subs r1, #0x4f
	movs r0, #0x88
	strb r0, [r1]
	ldr r3, L_08065274
	movs r1, #0
	subs r2, #0x22
	movs r0, #7
.L08065234:
	str r1, [r3]
	str r1, [r2]
	subs r0, #1
	cmp r0, #0
	bge .L08065234
	bl snd_Unlock
	ldr r0, [r6, #0x10]
	ldr r1, [r6, #0x1c]
	subs r1, r1, r0
	bl snd_memclr
	ldr r0, [r6, #0x24]
	ldr r1, [r6, #0x34]
	subs r1, r1, r0
	bl snd_memclr
	pop {r4, r5, r6}
	pop {r0}
	bx r0
L_0806525c:
	.word 0x03006830
L_08065260:
	.word 0x04000106
L_08065264:
	.word 0x0000ff3f
L_08065268:
	.word 0x04000102
L_0806526c:
	.word 0x00008440
L_08065270:
	.word 0x040000d2
L_08065274:
	.word 0x040000a0

.global sndMixFrame
.thumb_func
.type sndMixFrame, %function
sndMixFrame:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0x14
	ldr r5, L_08065360
	ldr r4, [r5]
	ldrb r0, [r4, #8]
	cmp r0, #0
	bne .L08065290
	b .L080653fa
.L08065290:
	adds r7, r4, #0
	adds r7, #0xd8
	ldr r0, [r7]
	str r0, [sp]
	ldr r1, [r7, #4]
	str r1, [sp, #4]
	ldr r2, [r7, #8]
	str r2, [sp, #8]
	ldr r3, [r7, #0xc]
	str r3, [sp, #0xc]
	adds r2, r4, #0
	adds r2, #0xf9
	ldrb r1, [r2]
	cmp r1, #0
	bne .L080652c2
	movs r0, #1
	strb r0, [r2]
	ldr r0, L_08065364
	strh r1, [r0]
	ldr r1, L_08065368
	movs r0, #0xc1
	lsls r0, r0, #0x10
	ldrh r6, [r7, #0x22]
	orrs r0, r6
	str r0, [r1]
.L080652c2:
	adds r3, r4, #0
	adds r3, #0xf8
	ldrb r0, [r3]
	adds r0, #1
	strb r0, [r3]
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	cmp r0, #3
	bne .L080652d8
	movs r0, #0
	strb r0, [r3]
.L080652d8:
	ldrb r0, [r3]
	cmp r0, #1
	bne .L08065312
	ldr r2, L_0806536c
	ldr r1, L_08065370
	adds r0, r1, #0
	strh r0, [r2]
	ldr r1, L_08065374
	strh r0, [r1]
	mov r8, r8
	mov r8, r8
	mov r8, r8
	mov r8, r8
	movs r6, #0x88
	lsls r6, r6, #3
	adds r0, r6, #0
	strh r0, [r2]
	strh r0, [r1]
	subs r1, #0x16
	ldr r0, [r7, #0x14]
	str r0, [r1]
	adds r1, #0xc
	ldr r0, [r7, #0x18]
	str r0, [r1]
	ldr r0, L_08065378
	ldr r1, L_0806537c
	str r1, [r0]
	adds r0, #0xc
	str r1, [r0]
.L08065312:
	movs r2, #0
	ldr r0, [r5]
	movs r1, #0x8b
	lsls r1, r1, #1
	adds r1, r1, r4
	mov r9, r1
	mov r10, r3
	ldrb r0, [r0, #8]
	cmp r2, r0
	bge .L080653d0
	mov r8, r5
.L08065328:
	mov r3, r8
	ldr r0, [r3]
	adds r0, #0xcc
	ldr r0, [r0]
	lsls r6, r2, #2
	adds r0, r6, r0
	ldr r5, [r0]
	cmp r5, #0
	beq .L080653c4
	ldrb r4, [r5, #0x1b]
	cmp r4, #0
	bne .L08065380
	ldr r1, [r7, #0x10]
	adds r0, r5, #0
	str r2, [sp, #0x10]
	ldr r3, [sp]
	bl _call_via_r3
	ldr r2, [sp, #0x10]
	cmp r0, #0
	beq .L080653a0
	mov r1, r8
	ldr r0, [r1]
	adds r0, #0xcc
	ldr r0, [r0]
	adds r0, r6, r0
	str r4, [r0]
	b .L080653a0
L_08065360:
	.word 0x03006830
L_08065364:
	.word 0x04000106
L_08065368:
	.word 0x04000104
L_0806536c:
	.word 0x040000c6
L_08065370:
	.word 0x00008440
L_08065374:
	.word 0x040000d2
L_08065378:
	.word 0x040000c4
L_0806537c:
	.word 0xb6600004
.L08065380:
	ldr r1, [r7, #0x24]
	adds r0, r5, #0
	str r2, [sp, #0x10]
	ldr r3, [sp, #4]
	bl _call_via_r3
	ldr r2, [sp, #0x10]
	cmp r0, #0
	beq .L080653a0
	mov r1, r8
	ldr r0, [r1]
	adds r0, #0xcc
	ldr r0, [r0]
	adds r0, r6, r0
	movs r1, #0
	str r1, [r0]
.L080653a0:
	mov r3, r8
	ldr r0, [r3]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #0xa
	ands r0, r1
	cmp r0, #0
	beq .L080653c4
	adds r0, r2, #0
	adds r1, r5, #0
	str r2, [sp, #0x10]
	bl snd_StreamRefill
	ldr r2, [sp, #0x10]
.L080653c4:
	adds r2, #1
	mov r6, r8
	ldr r0, [r6]
	ldrb r0, [r0, #8]
	cmp r2, r0
	blt .L08065328
.L080653d0:
	mov r1, r9
	ldrb r0, [r1]
	cmp r0, #0
	beq .L080653e4
	adds r0, r7, #0
	adds r0, #0x24
	ldr r1, [r7, #0x10]
	ldr r2, [sp, #0xc]
	bl _call_via_r2
.L080653e4:
	mov r3, r10
	ldrb r3, [r3]
	lsls r0, r3, #7
	ldr r1, [r7, #0x14]
	adds r1, r1, r0
	ldr r2, [r7, #0x18]
	adds r2, r2, r0
	ldr r0, [r7, #0x10]
	ldr r6, [sp, #8]
	bl _call_via_r6
.L080653fa:
	add sp, #0x14
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global snd_CalcTimer
.thumb_func
.type snd_CalcTimer, %function
snd_CalcTimer:
	push {r4, lr}
	adds r1, r0, #0
	lsls r1, r1, #0x10
	lsrs r1, r1, #0x10
	movs r0, #0x80
	lsls r0, r0, #0x11
	bl __udivsi3
	ldr r4, L_08065450
	ands r4, r0
	lsls r4, r4, #0x10
	asrs r4, r4, #0x10
	adds r0, r4, #0
	bl __floatsisf
	adds r2, r0, #0
	cmp r4, #0
	bge .L08065438
	ldr r1, L_08065454
	bl __addsf3
	adds r2, r0, #0
.L08065438:
	ldr r0, L_08065458
	adds r1, r2, #0
	bl __divsf3
	bl __fixsfsi
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000
L_08065450:
	.word 0x0000ffc0
L_08065454:
	.word 0x47800000
L_08065458:
	.word 0x4b800000

.global snd_CalcEchoBlocks
.thumb_func
.type snd_CalcEchoBlocks, %function
snd_CalcEchoBlocks:
	push {lr}
	muls r0, r1, r0
	movs r1, #0xfa
	lsls r1, r1, #9
	bl __udivsi3
	cmp r0, #0
	bne .L0806546e
	movs r0, #1
.L0806546e:
	cmp r0, #0xff
	bls .L08065474
	movs r0, #0xff
.L08065474:
	pop {r1}
	bx r1

.global snd_CalcStep
.thumb_func
.type snd_CalcStep, %function
snd_CalcStep:
	push {r4, r5, lr}
	adds r4, r0, #0
	lsls r1, r1, #0x18
	lsrs r3, r1, #0x18
	adds r1, r3, #0
	lsls r2, r2, #0x18
	lsrs r5, r2, #0x18
	ldrb r0, [r4, #0xa]
	cmp r5, #0
	bne .L080654ba
	cmp r3, r0
	beq .L080654b4
	ldrh r2, [r4, #8]
	cmp r0, r3
	bhs .L080654a0
	ldr r1, L_0806549c
	subs r0, r3, r0
	b .L080654a4
L_0806549c:
	.word 0x087ffd28
.L080654a0:
	ldr r1, L_080654b0
	subs r0, r0, r3
.L080654a4:
	lsls r0, r0, #1
	adds r0, r0, r1
	ldrh r0, [r0]
	adds r3, r0, #0
	muls r3, r2, r3
	b .L080654f8
L_080654b0:
	.word 0x087ffe28
.L080654b4:
	ldrh r4, [r4, #8]
	lsls r3, r4, #0xc
	b .L080654f8
.L080654ba:
	cmp r3, r0
	blo .L080654d8
	ldr r2, L_080654d4
	subs r1, r3, r0
	lsls r0, r1, #1
	adds r0, r0, r2
	ldrh r3, [r0]
	adds r1, #1
	lsls r1, r1, #1
	adds r1, r1, r2
	ldrh r1, [r1]
	subs r0, r1, r3
	b .L080654ec
L_080654d4:
	.word 0x087ffd28
.L080654d8:
	ldr r2, L_08065510
	subs r1, r0, r1
	lsls r0, r1, #1
	adds r0, r0, r2
	ldrh r3, [r0]
	adds r1, #1
	lsls r1, r1, #1
	adds r1, r1, r2
	ldrh r1, [r1]
	subs r0, r3, r1
.L080654ec:
	muls r0, r5, r0
	lsrs r0, r0, #8
	adds r0, r3, r0
	ldrh r4, [r4, #8]
	adds r3, r4, #0
	muls r3, r0, r3
.L080654f8:
	ldr r0, L_08065514
	ldr r0, [r0]
	ldrh r1, [r0, #0xa]
	adds r0, r3, #0
	bl __udivsi3
	adds r3, r0, #0
	lsls r0, r3, #0x10
	lsrs r0, r0, #0x10
	pop {r4, r5}
	pop {r1}
	bx r1
L_08065510:
	.word 0x087ffe28
L_08065514:
	.word 0x03006830

.global snd_EchoClear
.thumb_func
.type snd_EchoClear, %function
snd_EchoClear:
	push {r4, r5, lr}
	ldr r0, L_08065540
	ldr r0, [r0]
	adds r5, r0, #0
	adds r5, #0xfc
	ldr r0, [r5, #4]
	cmp r0, #0
	beq .L0806553a
	ldrb r4, [r5, #0x1a]
	movs r0, #0
	strb r0, [r5, #0x1a]
	ldr r0, [r5]
	ldr r1, [r5, #0x10]
	subs r1, r1, r0
	bl snd_memclr
	strb r4, [r5, #0x1a]
.L0806553a:
	pop {r4, r5}
	pop {r0}
	bx r0
L_08065540:
	.word 0x03006830

.global sndOutputResume
.thumb_func
.type sndOutputResume, %function
sndOutputResume:
	push {r4, lr}
	ldr r0, L_08065598
	ldr r4, [r0]
	adds r4, #0xd8
	bl snd_Lock
	ldr r1, L_0806559c
	movs r0, #0x9a
	strb r0, [r1]
	adds r1, #0x39
	ldr r0, [r4, #0x14]
	str r0, [r1]
	adds r1, #4
	ldr r0, L_080655a0
	str r0, [r1]
	adds r0, #0x24
	ldr r2, L_080655a4
	str r2, [r0]
	adds r1, #8
	ldr r0, [r4, #0x18]
	str r0, [r1]
	adds r1, #4
	ldr r0, L_080655a8
	str r0, [r1]
	adds r0, #0x2c
	str r2, [r0]
	ldr r2, L_080655ac
	ldrh r0, [r2]
	movs r1, #0xc0
	orrs r0, r1
	strh r0, [r2]
	subs r2, #4
	ldrh r0, [r2]
	movs r1, #0x80
	orrs r0, r1
	strh r0, [r2]
	bl snd_Unlock
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000
L_08065598:
	.word 0x03006830
L_0806559c:
	.word 0x04000083
L_080655a0:
	.word 0x040000a0
L_080655a4:
	.word 0xb6600004
L_080655a8:
	.word 0x040000a4
L_080655ac:
	.word 0x04000106

@ macro opcode 0x00 END 0x01 STOP
.global mcmd_END
.thumb_func
.type mcmd_END, %function
mcmd_END:
	push {r4, r5, r6, lr}
	adds r5, r0, #0
	adds r6, r1, #0
	cmp r5, #3
	bgt .L080655d0
	ldr r2, L_080655cc
	ldr r0, [r2]
	lsls r1, r5, #1
	adds r0, #0xb4
	adds r0, r0, r1
	movs r1, #0
	strh r1, [r0]
	b .L080655ea
	.hword 0x0000
L_080655cc:
	.word 0x03006830
.L080655d0:
	subs r2, r5, #4
	ldr r4, L_0806560c
	ldr r1, [r4]
	adds r1, #0xd0
	ldr r0, [r1]
	lsls r2, r2, #6
	adds r0, r2, r0
	movs r3, #0
	strh r3, [r0, #0x34]
	ldr r0, [r1]
	adds r2, r2, r0
	strh r3, [r2, #0x36]
	adds r2, r4, #0
.L080655ea:
	movs r0, #0
	str r0, [r6]
	cmp r5, #3
	ble .L08065614
	ldr r0, [r2]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r5, #6
	adds r0, r0, r1
	ldr r1, L_08065610
	adds r2, r0, r1
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	lsls r1, r1, #8
	orrs r0, r1
	str r0, [r2, #0x38]
	b .L08065626
L_0806560c:
	.word 0x03006830
L_08065610:
	.word 0xffffff00
.L08065614:
	ldr r1, [r2]
	lsls r0, r5, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0x80
	lsls r2, r2, #8
	orrs r0, r2
	str r0, [r1]
.L08065626:
	movs r0, #0
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x02 VOLUME
.global mcmd_VOLUME
.thumb_func
.type mcmd_VOLUME, %function
mcmd_VOLUME:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r5, r0, #0
	adds r7, r1, #0
	ldr r0, [r7]
	mov r12, r0
	cmp r5, #3
	bgt .L08065690
	ldr r3, L_08065668
	lsls r0, r5, #3
	adds r0, #0x94
	ldr r4, [r3]
	adds r6, r4, r0
	lsls r2, r5, #2
	adds r0, r4, #0
	adds r0, #0x18
	adds r0, r0, r2
	ldr r1, [r0]
	movs r0, #0x80
	lsls r0, r0, #9
	ands r1, r0
	mov r8, r3
	cmp r1, #0
	beq .L0806566c
	ldrh r0, [r4, #0x16]
	b .L0806566e
	.hword 0x0000
L_08065668:
	.word 0x03006830
.L0806566c:
	ldrh r0, [r4, #0x14]
.L0806566e:
	cmp r0, #0
	beq .L08065674
	adds r0, #1
.L08065674:
	mov r1, r12
	ldrb r1, [r1, #1]
	muls r0, r1, r0
	lsrs r0, r0, #8
	strb r0, [r6, #7]
	mov r3, r8
	ldr r1, [r3]
	adds r1, #0x18
	adds r1, r1, r2
	ldr r0, [r1]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1]
	b .L080656ee
.L08065690:
	subs r5, #4
	ldr r2, L_080656b8
	ldr r3, [r2]
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r5, #6
	ldr r0, [r0]
	adds r0, r0, r1
	adds r6, r0, #0
	adds r6, #0x24
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #9
	ands r0, r1
	mov r8, r2
	cmp r0, #0
	beq .L080656bc
	ldrh r0, [r3, #0x16]
	b .L080656be
	.hword 0x0000
L_080656b8:
	.word 0x03006830
.L080656bc:
	ldrh r0, [r3, #0x14]
.L080656be:
	cmp r0, #0
	beq .L080656c4
	adds r0, #1
.L080656c4:
	mov r1, r12
	ldrb r1, [r1, #1]
	muls r0, r1, r0
	lsrs r0, r0, #8
	lsls r2, r0, #1
	strb r2, [r6, #7]
	lsls r0, r2, #0x18
	cmp r0, #0
	beq .L080656da
	adds r0, r2, #1
	strb r0, [r6, #7]
.L080656da:
	mov r2, r8
	ldr r0, [r2]
	adds r0, #0xd0
	ldr r0, [r0]
	lsls r1, r5, #6
	adds r1, r1, r0
	ldr r0, [r1, #0x38]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1, #0x38]
.L080656ee:
	ldr r0, [r7]
	adds r0, #2
	str r0, [r7]
	movs r0, #1
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

@ macro opcode 0x05 SILENCE
.global mcmd_SILENCE
.thumb_func
.type mcmd_SILENCE, %function
mcmd_SILENCE:
	push {r4, r5, r6, lr}
	adds r3, r0, #0
	adds r5, r1, #0
	ldr r6, [r5]
	cmp r3, #3
	bgt .L08065724
	ldr r1, L_08065720
	lsls r0, r3, #2
	adds r0, #0x18
	ldr r1, [r1]
	adds r2, r1, r0
	lsls r0, r3, #3
	adds r0, #0x94
	adds r4, r1, r0
	b .L08065760
	.hword 0x0000
L_08065720:
	.word 0x03006830
.L08065724:
	ldr r0, L_0806577c
	ldr r1, [r0]
	adds r0, r1, #0
	adds r0, #0xd4
	ldr r0, [r0]
	lsls r2, r3, #2
	adds r0, r2, r0
	subs r0, #0x10
	ldr r0, [r0]
	cmp r0, #0
	beq .L08065784
	adds r0, r1, #0
	adds r0, #0xcc
	ldr r0, [r0]
	adds r0, r2, r0
	subs r0, #0x10
	ldr r0, [r0]
	cmp r0, #0
	beq .L08065784
	adds r0, r1, #0
	adds r0, #0xd0
	lsls r1, r3, #6
	ldr r2, L_08065780
	adds r1, r1, r2
	ldr r0, [r0]
	adds r0, r0, r1
	adds r2, r0, #0
	adds r2, #0x38
	adds r4, r0, #0
	adds r4, #0x24
.L08065760:
	ldrb r0, [r6, #1]
	cmp r0, #0
	beq .L08065784
	ldr r0, [r2]
	movs r1, #0x21
	ands r0, r1
	cmp r0, #0
	beq .L08065784
	ldrb r0, [r4, #6]
	cmp r0, #0
	beq .L08065784
	movs r0, #0
	b .L08065792
	.hword 0x0000
L_0806577c:
	.word 0x03006830
L_08065780:
	.word 0xffffff00
.L08065784:
	adds r0, r3, #0
	bl voice_Silence
	ldr r0, [r5]
	adds r0, #2
	str r0, [r5]
	movs r0, #1
.L08065792:
	pop {r4, r5, r6}
	pop {r1}
	bx r1

@ macro opcode 0x04 WAIT
.global mcmd_WAIT
.thumb_func
.type mcmd_WAIT, %function
mcmd_WAIT:
	push {r4, r5, r6, r7, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r5, [r4]
	ldrh r0, [r4, #0xa]
	cmp r0, #0
	bne .L0806584c
	ldrh r0, [r5, #2]
	adds r7, r0, #0
	cmp r7, #0
	bne .L080657b0
	b .L080658cc
.L080657b0:
	ldrb r1, [r5, #1]
	movs r0, #1
	ands r0, r1
	adds r6, r1, #0
	cmp r0, #0
	beq .L080657f0
	cmp r2, #3
	bgt .L080657d4
	ldr r0, L_080657d0
	ldr r0, [r0]
	lsls r1, r2, #2
	adds r0, #0x18
	adds r0, r0, r1
	ldr r0, [r0]
	b .L080657e6
	.hword 0x0000
L_080657d0:
	.word 0x03006830
.L080657d4:
	ldr r0, L_08065840
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_08065844
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
.L080657e6:
	movs r1, #0x80
	lsls r1, r1, #1
	ands r0, r1
	cmp r0, #0
	bne .L080658cc
.L080657f0:
	movs r0, #4
	ands r0, r6
	cmp r0, #0
	beq .L0806582c
	cmp r2, #3
	ble .L0806582c
	ldr r0, L_08065840
	ldr r3, [r0]
	adds r0, r3, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_08065844
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #2
	ands r0, r1
	cmp r0, #0
	bne .L0806582c
	adds r0, r3, #0
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	subs r0, #0x10
	ldr r0, [r0]
	cmp r0, #0
	beq .L080658cc
.L0806582c:
	movs r0, #2
	ands r0, r6
	cmp r0, #0
	beq .L08065848
	ldrh r0, [r5, #2]
	bl snd_Rand
	strh r0, [r4, #0xa]
	b .L080658e0
	.hword 0x0000
L_08065840:
	.word 0x03006830
L_08065844:
	.word 0xffffff00
.L08065848:
	strh r7, [r4, #0xa]
	b .L080658e0
.L0806584c:
	ldr r1, L_08065864
	ldrh r3, [r5, #2]
	cmp r3, r1
	beq .L08065868
	subs r0, #1
	strh r0, [r4, #0xa]
	ands r0, r1
	cmp r0, #0
	bne .L08065868
	adds r0, r5, #4
	b .L080658d0
	.hword 0x0000
L_08065864:
	.word 0x0000ffff
.L08065868:
	ldrb r1, [r5, #1]
	movs r0, #1
	ands r0, r1
	adds r6, r1, #0
	cmp r0, #0
	beq .L080658a8
	cmp r2, #3
	bgt .L0806588c
	ldr r0, L_08065888
	ldr r0, [r0]
	lsls r1, r2, #2
	adds r0, #0x18
	adds r0, r0, r1
	ldr r0, [r0]
	b .L0806589e
	.hword 0x0000
L_08065888:
	.word 0x03006830
.L0806588c:
	ldr r0, L_080658d8
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_080658dc
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
.L0806589e:
	movs r1, #0x80
	lsls r1, r1, #1
	ands r0, r1
	cmp r0, #0
	bne .L080658c8
.L080658a8:
	movs r0, #4
	ands r0, r6
	cmp r0, #0
	beq .L080658e0
	cmp r2, #3
	ble .L080658e0
	ldr r0, L_080658d8
	ldr r0, [r0]
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	subs r0, #0x10
	ldr r0, [r0]
	cmp r0, #0
	bne .L080658e0
.L080658c8:
	movs r0, #0
	strh r0, [r4, #0xa]
.L080658cc:
	ldr r0, [r4]
	adds r0, #4
.L080658d0:
	str r0, [r4]
	movs r0, #1
	b .L080658e2
	.hword 0x0000
L_080658d8:
	.word 0x03006830
L_080658dc:
	.word 0xffffff00
.L080658e0:
	movs r0, #0
.L080658e2:
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

@ macro opcode 0x06 LOOP
.global mcmd_LOOP
.thumb_func
.type mcmd_LOOP, %function
mcmd_LOOP:
	push {r4, r5, r6, r7, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r5, [r4]
	ldrh r0, [r4, #8]
	cmp r0, #0
	bne .L0806599e
	ldrh r0, [r5, #2]
	adds r7, r0, #0
	cmp r7, #0
	beq .L08065978
	ldrb r1, [r5, #1]
	movs r0, #1
	ands r0, r1
	adds r6, r1, #0
	cmp r0, #0
	beq .L0806593c
	cmp r2, #3
	bgt .L08065920
	ldr r0, L_0806591c
	ldr r0, [r0]
	lsls r1, r2, #2
	adds r0, #0x18
	adds r0, r0, r1
	ldr r0, [r0]
	b .L08065932
L_0806591c:
	.word 0x03006830
.L08065920:
	ldr r0, L_08065980
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_08065984
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
.L08065932:
	movs r1, #0x80
	lsls r1, r1, #1
	ands r0, r1
	cmp r0, #0
	bne .L08065978
.L0806593c:
	movs r0, #4
	ands r0, r6
	cmp r0, #0
	beq .L08065988
	cmp r2, #3
	ble .L08065988
	ldr r0, L_08065980
	ldr r3, [r0]
	adds r0, r3, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_08065984
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #2
	ands r0, r1
	cmp r0, #0
	bne .L08065988
	adds r0, r3, #0
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	subs r0, #0x10
	ldr r0, [r0]
	cmp r0, #0
	bne .L08065988
.L08065978:
	ldr r0, [r4]
	adds r0, #6
	b .L08065a34
	.hword 0x0000
L_08065980:
	.word 0x03006830
L_08065984:
	.word 0xffffff00
.L08065988:
	movs r0, #2
	ands r0, r6
	cmp r0, #0
	beq .L0806599a
	ldrh r0, [r5, #2]
	bl snd_Rand
	strh r0, [r4, #8]
	b .L08065a2c
.L0806599a:
	strh r7, [r4, #8]
	b .L08065a2c
.L0806599e:
	ldr r1, L_080659b4
	ldrh r3, [r5, #2]
	cmp r3, r1
	beq .L080659b8
	subs r0, #1
	strh r0, [r4, #8]
	ands r0, r1
	cmp r0, #0
	bne .L080659b8
	adds r0, r5, #6
	b .L08065a34
L_080659b4:
	.word 0x0000ffff
.L080659b8:
	ldrb r1, [r5, #1]
	movs r0, #1
	ands r0, r1
	adds r6, r1, #0
	cmp r0, #0
	beq .L080659f8
	cmp r2, #3
	bgt .L080659dc
	ldr r0, L_080659d8
	ldr r0, [r0]
	lsls r1, r2, #2
	adds r0, #0x18
	adds r0, r0, r1
	ldr r0, [r0]
	b .L080659ee
	.hword 0x0000
L_080659d8:
	.word 0x03006830
.L080659dc:
	ldr r0, L_08065a24
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_08065a28
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
.L080659ee:
	movs r1, #0x80
	lsls r1, r1, #1
	ands r0, r1
	cmp r0, #0
	bne .L08065a18
.L080659f8:
	movs r0, #4
	ands r0, r6
	cmp r0, #0
	beq .L08065a2c
	cmp r2, #3
	ble .L08065a2c
	ldr r0, L_08065a24
	ldr r0, [r0]
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r0, r0, r1
	subs r0, #0x10
	ldr r0, [r0]
	cmp r0, #0
	bne .L08065a2c
.L08065a18:
	movs r0, #0
	strh r0, [r4, #8]
	ldr r0, [r4]
	adds r0, #6
	b .L08065a34
	.hword 0x0000
L_08065a24:
	.word 0x03006830
L_08065a28:
	.word 0xffffff00
.L08065a2c:
	movs r3, #4
	ldrsh r1, [r5, r3]
	ldr r0, [r4]
	adds r0, r0, r1
.L08065a34:
	str r0, [r4]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x08 SETPITCH
.global mcmd_SETPITCH
.thumb_func
.type mcmd_SETPITCH, %function
mcmd_SETPITCH:
	push {r4, r5, r6, lr}
	adds r3, r0, #0
	adds r4, r1, #0
	ldr r5, [r4]
	cmp r3, #2
	bgt .L08065a74
	ldr r0, L_08065a70
	ldr r2, [r0]
	lsls r0, r3, #3
	adds r0, r0, r3
	lsls r0, r0, #2
	adds r0, r2, r0
	ldrh r5, [r5, #2]
	ldrh r6, [r0, #0x28]
	subs r1, r5, r6
	strh r1, [r0, #0x2a]
	lsls r0, r3, #2
	adds r2, #0x18
	adds r2, r2, r0
	ldr r0, [r2]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2]
	b .L08065a98
L_08065a70:
	.word 0x03006830
.L08065a74:
	cmp r3, #3
	ble .L08065a98
	ldr r0, L_08065aa8
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r3, #6
	ldr r2, L_08065aac
	adds r0, r0, r2
	ldr r1, [r1]
	adds r1, r1, r0
	ldrh r5, [r5, #2]
	ldrh r6, [r1]
	subs r0, r5, r6
	strh r0, [r1, #2]
	ldr r0, [r1, #0x38]
	movs r2, #0x40
	orrs r0, r2
	str r0, [r1, #0x38]
.L08065a98:
	ldr r0, [r4]
	adds r0, #4
	str r0, [r4]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000
L_08065aa8:
	.word 0x03006830
L_08065aac:
	.word 0xffffff00

@ macro opcode 0x09 ADDPITCH
.global mcmd_ADDPITCH
.thumb_func
.type mcmd_ADDPITCH, %function
mcmd_ADDPITCH:
	push {r4, r5, r6, lr}
	adds r3, r0, #0
	adds r5, r1, #0
	ldr r4, [r5]
	cmp r3, #2
	bgt .L08065b08
	movs r0, #1
	ldrb r1, [r4, #1]
	ands r0, r1
	cmp r0, #0
	beq .L08065adc
	ldr r2, L_08065ad8
	ldr r1, [r2]
	lsls r0, r3, #3
	adds r0, r0, r3
	lsls r0, r0, #2
	adds r1, r1, r0
	ldrh r0, [r4, #2]
	b .L08065aee
	.hword 0x0000
L_08065ad8:
	.word 0x03006830
.L08065adc:
	ldr r2, L_08065b04
	ldr r1, [r2]
	lsls r0, r3, #3
	adds r0, r0, r3
	lsls r0, r0, #2
	adds r1, r1, r0
	ldrh r6, [r1, #0x2a]
	ldrh r4, [r4, #2]
	adds r0, r6, r4
.L08065aee:
	strh r0, [r1, #0x2a]
	ldr r1, [r2]
	lsls r0, r3, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0x40
	orrs r0, r2
	str r0, [r1]
	b .L08065b44
	.hword 0x0000
L_08065b04:
	.word 0x03006830
.L08065b08:
	cmp r3, #3
	ble .L08065b44
	ldr r0, L_08065b2c
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r3, #6
	ldr r2, L_08065b30
	adds r0, r0, r2
	ldr r1, [r1]
	adds r2, r1, r0
	movs r0, #1
	ldrb r6, [r4, #1]
	ands r0, r6
	cmp r0, #0
	beq .L08065b34
	ldrh r0, [r4, #2]
	b .L08065b3a
	.hword 0x0000
L_08065b2c:
	.word 0x03006830
L_08065b30:
	.word 0xffffff00
.L08065b34:
	ldrh r1, [r2, #2]
	ldrh r4, [r4, #2]
	adds r0, r1, r4
.L08065b3a:
	strh r0, [r2, #2]
	ldr r0, [r2, #0x38]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2, #0x38]
.L08065b44:
	ldr r0, [r5]
	adds r0, #4
	str r0, [r5]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000

.global sub_08065b54
.thumb_func
.type sub_08065b54, %function
sub_08065b54:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	adds r6, r0, #0
	mov r9, r2
	mov r10, r3
	ldr r3, L_08065bcc
	ldr r0, [r3]
	mov r12, r0
	adds r0, #0xd0
	lsls r2, r6, #6
	ldr r0, [r0]
	adds r7, r0, r2
	mov r2, r12
	adds r2, #0xc8
	lsls r0, r6, #3
	subs r0, r0, r6
	lsls r0, r0, #2
	ldr r2, [r2]
	adds r4, r2, r0
	mov r0, r12
	adds r0, #0xcc
	ldr r2, [r0]
	lsls r0, r6, #2
	adds r0, r0, r2
	movs r2, #0
	mov r8, r2
	str r2, [r0]
	ldr r0, [r7, #0x38]
	ldr r2, L_08065bd0
	ands r0, r2
	movs r2, #0x80
	lsls r2, r2, #5
	orrs r0, r2
	str r0, [r7, #0x38]
	movs r0, #0x8c
	lsls r0, r0, #1
	add r0, r12
	ldr r2, [r0]
	ldr r0, [r2, #0x1c]
	lsls r1, r1, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1]
	adds r2, r2, r0
	str r2, [r4]
	adds r1, r2, #0
	adds r1, #0x10
	str r1, [r4, #4]
	ldr r5, [r2]
	adds r0, r1, r5
	str r0, [r4, #8]
	ldr r2, [r2, #4]
	cmp r2, #0
	bge .L08065bd4
	mov r0, r8
	str r0, [r4, #0xc]
	b .L08065bda
L_08065bcc:
	.word 0x03006830
L_08065bd0:
	.word 0xffffb3ff
.L08065bd4:
	adds r0, r1, r2
	str r0, [r4, #0xc]
	subs r0, r5, r2
.L08065bda:
	str r0, [r4, #0x10]
	mov r1, r9
	cmp r1, #0
	beq .L08065bee
	ldr r0, [r4, #4]
	adds r2, r0, r1
	ldr r0, [r4, #8]
	cmp r2, r0
	bhs .L08065bee
	str r2, [r4, #4]
.L08065bee:
	movs r0, #0
	movs r1, #0
	strh r1, [r4, #0x16]
	strb r0, [r4, #0x1a]
	adds r0, r7, #0
	adds r0, #0x3d
	ldrb r0, [r0]
	cmp r0, #0
	beq .L08065c0c
	ldr r0, [r3]
	movs r2, #0x8b
	lsls r2, r2, #1
	adds r0, r0, r2
	ldrb r0, [r0]
	b .L08065c0e
.L08065c0c:
	movs r0, #0
.L08065c0e:
	strb r0, [r4, #0x1b]
	adds r0, r6, #0
	bl voice_CalcMixVolume
	mov r0, r10
	cmp r0, #0
	bne .L08065c24
	adds r0, r6, #0
	bl voice_UpdateStep
	b .L08065c34
.L08065c24:
	movs r0, #0x80
	lsls r0, r0, #5
	strh r0, [r4, #0x14]
	ldr r0, [r7, #0x38]
	movs r1, #0x41
	rsbs r1, r1, #0
	ands r0, r1
	str r0, [r7, #0x38]
.L08065c34:
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

@ macro opcode 0x0F STARTSAMPLE
.global mcmd_STARTSAMPLE
.thumb_func
.type mcmd_STARTSAMPLE, %function
mcmd_STARTSAMPLE:
	push {r4, r5, r6, r7, lr}
	adds r3, r0, #0
	adds r6, r1, #0
	ldr r5, [r6]
	cmp r3, #2
	bne .L08065c7c
	ldr r0, L_08065c78
	ldr r0, [r0]
	movs r1, #0x8c
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r2, [r0]
	ldr r0, [r2, #0x1c]
	ldrh r5, [r5, #2]
	lsls r1, r5, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1]
	adds r0, r2, r0
	ldrb r1, [r0, #0xb]
	cmp r1, #1
	bne .L08065cda
	bl psg_LoadWave
	b .L08065cda
	.hword 0x0000
L_08065c78:
	.word 0x03006830
.L08065c7c:
	cmp r3, #3
	ble .L08065cda
	ldrh r0, [r5, #6]
	lsls r4, r0, #0x10
	ldrh r1, [r5, #4]
	orrs r4, r1
	ldrb r7, [r5, #1]
	cmp r4, #0
	beq .L08065ccc
	ldr r0, L_08065cc0
	ldr r0, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	subs r1, #0x10
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r3, #1
	adds r0, r0, r3
	lsls r0, r0, #2
	adds r0, r0, r1
	ldrb r2, [r0, #8]
	cmp r2, #0
	beq .L08065cb0
	adds r2, #1
.L08065cb0:
	movs r0, #0x80
	ands r0, r7
	cmp r0, #0
	bne .L08065cc4
	adds r0, r4, #0
	muls r0, r2, r0
	lsrs r4, r0, #7
	b .L08065ccc
L_08065cc0:
	.word 0x03006830
.L08065cc4:
	adds r0, r4, #0
	muls r0, r2, r0
	lsrs r0, r0, #7
	subs r4, r4, r0
.L08065ccc:
	subs r0, r3, #4
	ldrh r1, [r5, #2]
	movs r3, #1
	ands r3, r7
	adds r2, r4, #0
	bl sub_08065b54
.L08065cda:
	ldr r0, [r6]
	adds r0, #8
	str r0, [r6]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

@ macro opcode 0x12 SAMPLEREGION
.global mcmd_SAMPLEREGION
.thumb_func
.type mcmd_SAMPLEREGION, %function
mcmd_SAMPLEREGION:
	push {r4, r5, r6, r7, lr}
	mov r7, r9
	mov r6, r8
	push {r6, r7}
	adds r2, r0, #0
	mov r9, r1
	ldr r4, [r1]
	cmp r2, #3
	ble .L08065dc0
	subs r2, #4
	ldr r0, L_08065d68
	ldr r3, [r0]
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #5
	ands r0, r1
	cmp r0, #0
	beq .L08065dc0
	adds r1, r3, #0
	adds r1, #0xc8
	lsls r0, r2, #3
	subs r0, r0, r2
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r6, r1, r0
	ldr r0, [r6]
	movs r1, #0x10
	adds r1, r1, r0
	mov r12, r1
	ldrh r1, [r4, #8]
	lsls r3, r1, #0x10
	ldrh r1, [r4, #6]
	orrs r3, r1
	ldrh r1, [r4, #4]
	lsls r2, r1, #0x10
	ldrh r1, [r4, #2]
	orrs r2, r1
	ldr r1, [r0]
	cmp r2, r1
	blo .L08065d44
	movs r2, #0
.L08065d44:
	adds r0, r2, r3
	cmp r0, r1
	blo .L08065d52
	cmp r2, #0
	beq .L08065d50
	subs r2, #1
.L08065d50:
	subs r3, r1, r2
.L08065d52:
	ldr r0, [r6, #0xc]
	mov r8, r0
	ldrb r1, [r4, #1]
	movs r0, #0x80
	ands r0, r1
	cmp r0, #0
	beq .L08065d6c
	ldr r0, [r6]
	ldr r7, [r0]
	b .L08065d6e
	.hword 0x0000
L_08065d68:
	.word 0x03006830
.L08065d6c:
	ldr r7, [r6, #0x10]
.L08065d6e:
	movs r0, #0x7f
	ands r0, r1
	cmp r0, #0
	bne .L08065d92
	mov r1, r12
	adds r5, r1, r2
	cmp r3, #0
	bne .L08065d86
	ldr r0, [r6]
	ldr r0, [r0]
	adds r4, r1, r0
	b .L08065d88
.L08065d86:
	adds r4, r5, r3
.L08065d88:
	cmp r7, #0
	beq .L08065dae
	mov r8, r5
	subs r7, r4, r5
	b .L08065dae
.L08065d92:
	ldr r0, [r6]
	ldr r0, [r0]
	add r0, r12
	adds r1, r2, #1
	subs r5, r0, r1
	subs r4, r5, r3
	cmp r3, #0
	bne .L08065da6
	mov r4, r12
	subs r4, #1
.L08065da6:
	cmp r7, #0
	beq .L08065dae
	mov r8, r5
	subs r7, r5, r4
.L08065dae:
	bl snd_Lock
	str r5, [r6, #4]
	str r4, [r6, #8]
	mov r0, r8
	str r0, [r6, #0xc]
	str r7, [r6, #0x10]
	bl snd_Unlock
.L08065dc0:
	mov r1, r9
	ldr r0, [r1]
	adds r0, #0xa
	str r0, [r1]
	movs r0, #1
	pop {r3, r4}
	mov r8, r3
	mov r9, r4
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x13 PULSESWEEP
.global mcmd_PULSESWEEP
.thumb_func
.type mcmd_PULSESWEEP, %function
mcmd_PULSESWEEP:
	push {r4, r5, r6, r7, lr}
	mov r7, r9
	mov r6, r8
	push {r6, r7}
	adds r5, r0, #0
	mov r8, r1
	ldr r3, [r1]
	cmp r5, #3
	ble .L08065eda
	subs r5, #4
	ldr r0, L_08065e88
	mov r9, r0
	ldr r2, [r0]
	adds r0, r2, #0
	adds r0, #0xd0
	lsls r1, r5, #6
	ldr r0, [r0]
	adds r0, r0, r1
	mov r12, r0
	adds r1, r2, #0
	adds r1, #0xc8
	lsls r0, r5, #3
	subs r0, r0, r5
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r4, r1, r0
	mov r0, r12
	ldr r1, [r0, #0x38]
	movs r7, #0x80
	lsls r7, r7, #3
	adds r6, r1, #0
	ands r6, r7
	cmp r6, #0
	bne .L08065ea6
	ldr r0, L_08065e8c
	ands r1, r0
	orrs r1, r7
	mov r0, r12
	str r1, [r0, #0x38]
	adds r0, r2, #0
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r5, #2
	adds r0, r0, r1
	str r6, [r0]
	mov r1, r12
	adds r1, #0x2c
	ldrb r0, [r3, #2]
	strb r0, [r1, #4]
	ldrb r0, [r3, #3]
	strb r0, [r1, #5]
	ldrh r0, [r3, #4]
	movs r2, #0
	strh r0, [r1, #2]
	ldrb r3, [r3, #1]
	lsls r0, r3, #8
	mov r3, r12
	strh r0, [r3, #0x2c]
	ldr r0, L_08065e90
	str r0, [r4]
	ldrb r1, [r1, #4]
	lsls r1, r1, #0x18
	asrs r1, r1, #0x18
	adds r1, #0x10
	adds r1, r1, r0
	str r1, [r4, #0xc]
	str r1, [r4, #4]
	ldr r0, [r0]
	lsrs r0, r0, #1
	adds r0, r1, r0
	str r0, [r4, #8]
	subs r0, r0, r1
	str r0, [r4, #0x10]
	strh r6, [r4, #0x16]
	strb r2, [r4, #0x1a]
	mov r0, r12
	adds r0, #0x3d
	ldrb r0, [r0]
	cmp r0, #0
	beq .L08065e94
	mov r1, r9
	ldr r0, [r1]
	movs r3, #0x8b
	lsls r3, r3, #1
	adds r0, r0, r3
	ldrb r0, [r0]
	b .L08065e96
	.hword 0x0000
L_08065e88:
	.word 0x03006830
L_08065e8c:
	.word 0xffffe7ff
L_08065e90:
	.word 0x087ffc98
.L08065e94:
	movs r0, #0
.L08065e96:
	strb r0, [r4, #0x1b]
	adds r0, r5, #0
	bl voice_CalcMixVolume
	adds r0, r5, #0
	bl voice_UpdateStep
	b .L08065eda
.L08065ea6:
	mov r1, r12
	adds r1, #0x2c
	ldrb r0, [r3, #2]
	strb r0, [r1, #4]
	ldrb r0, [r3, #3]
	strb r0, [r1, #5]
	ldrh r0, [r3, #4]
	strh r0, [r1, #2]
	mov r0, r12
	movs r3, #0x2c
	ldrsh r2, [r0, r3]
	movs r0, #5
	ldrsb r0, [r1, r0]
	lsls r0, r0, #8
	cmp r2, r0
	ble .L08065ecc
	mov r1, r12
	strh r0, [r1, #0x2c]
	b .L08065eda
.L08065ecc:
	movs r0, #4
	ldrsb r0, [r1, r0]
	lsls r0, r0, #8
	cmp r2, r0
	bge .L08065eda
	mov r3, r12
	strh r0, [r3, #0x2c]
.L08065eda:
	mov r1, r8
	ldr r0, [r1]
	adds r0, #6
	str r0, [r1]
	movs r0, #1
	pop {r3, r4}
	mov r8, r3
	mov r9, r4
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

@ macro opcode 0x14 PULSEVEL
.global mcmd_PULSEVEL
.thumb_func
.type mcmd_PULSEVEL, %function
mcmd_PULSEVEL:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	adds r5, r0, #0
	mov r10, r1
	ldr r7, [r1]
	cmp r5, #3
	bgt .L08065f06
	b .L08066018
.L08065f06:
	subs r5, #4
	ldr r2, L_08065f70
	ldr r3, [r2]
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r5, #6
	ldr r0, [r0]
	adds r0, r0, r1
	mov r9, r0
	adds r1, r3, #0
	adds r1, #0xc8
	lsls r0, r5, #3
	subs r0, r0, r5
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r6, r1, r0
	mov r1, r9
	ldr r0, [r1, #0x38]
	ldr r1, L_08065f74
	ands r0, r1
	movs r1, #0x80
	lsls r1, r1, #3
	orrs r0, r1
	mov r1, r9
	str r0, [r1, #0x38]
	adds r0, r3, #0
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r5, #2
	adds r0, r0, r1
	movs r1, #0
	str r1, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r0, [r0]
	subs r1, #0x10
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r5, #1
	adds r0, r0, r5
	lsls r0, r0, #2
	adds r0, r0, r1
	adds r0, #0x30
	movs r1, #1
	ldrsb r1, [r7, r1]
	ldrb r0, [r0, #6]
	adds r4, r0, r1
	cmp r4, #0
	bgt .L08065f78
	movs r4, #1
	b .L08065f7e
	.hword 0x0000
L_08065f70:
	.word 0x03006830
L_08065f74:
	.word 0xffffe7ff
.L08065f78:
	cmp r4, #0x7f
	ble .L08065f7e
	movs r4, #0x7f
.L08065f7e:
	movs r2, #3
	ldrsb r2, [r7, r2]
	mov r8, r2
	ldrb r7, [r7, #2]
	lsls r7, r7, #0x18
	asrs r7, r7, #0x18
	subs r1, r2, r7
	cmp r1, #0
	bge .L08065fa4
	subs r0, r1, #1
	lsls r0, r0, #0x10
	movs r1, #0x7f
	bl __divsi3
	muls r0, r4, r0
	asrs r0, r0, #0x10
	mov r2, r8
	adds r1, r2, r0
	b .L08065fb4
.L08065fa4:
	adds r0, r1, #1
	lsls r0, r0, #0x10
	movs r1, #0x7f
	bl __divsi3
	muls r0, r4, r0
	asrs r0, r0, #0x10
	adds r1, r7, r0
.L08065fb4:
	mov r0, r9
	adds r0, #0x2c
	movs r3, #0
	strb r1, [r0, #5]
	strb r1, [r0, #4]
	lsls r1, r1, #8
	movs r4, #0
	mov r2, r9
	strh r1, [r2, #0x2c]
	strh r3, [r0, #2]
	ldr r2, L_08066000
	str r2, [r6]
	movs r1, #4
	ldrsb r1, [r0, r1]
	adds r1, #0x10
	adds r1, r1, r2
	str r1, [r6, #0xc]
	str r1, [r6, #4]
	ldr r0, [r2]
	lsrs r0, r0, #1
	adds r0, r1, r0
	str r0, [r6, #8]
	subs r0, r0, r1
	str r0, [r6, #0x10]
	strh r3, [r6, #0x16]
	strb r4, [r6, #0x1a]
	mov r0, r9
	adds r0, #0x3d
	ldrb r0, [r0]
	cmp r0, #0
	beq .L08066008
	ldr r1, L_08066004
	ldr r0, [r1]
	movs r2, #0x8b
	lsls r2, r2, #1
	adds r0, r0, r2
	ldrb r0, [r0]
	b .L0806600a
L_08066000:
	.word 0x087ffc98
L_08066004:
	.word 0x03006830
.L08066008:
	movs r0, #0
.L0806600a:
	strb r0, [r6, #0x1b]
	adds r0, r5, #0
	bl voice_CalcMixVolume
	adds r0, r5, #0
	bl voice_UpdateStep
.L08066018:
	mov r1, r10
	ldr r0, [r1]
	adds r0, #4
	str r0, [r1]
	movs r0, #1
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

@ macro opcode 0x16 RNDPITCH
.global mcmd_RNDPITCH
.thumb_func
.type mcmd_RNDPITCH, %function
mcmd_RNDPITCH:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r5, r0, #0
	mov r8, r1
	ldr r4, [r1]
	cmp r5, #3
	beq .L080660de
	ldrh r0, [r4, #4]
	ldrh r1, [r4, #2]
	subs r7, r0, r1
	cmp r7, #0
	beq .L080660de
	movs r0, #1
	ldrb r2, [r4, #1]
	ands r0, r2
	cmp r0, #0
	beq .L08066062
	lsls r0, r7, #0x10
	lsrs r0, r0, #0x10
	bl snd_Rand
	lsls r0, r0, #0x10
	lsrs r6, r0, #0x10
	b .L0806607c
.L08066062:
	asrs r0, r7, #8
	cmp r0, #0
	bne .L08066070
	adds r0, r4, #6
	mov r1, r8
	str r0, [r1]
	b .L080660e6
.L08066070:
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	bl snd_Rand
	lsls r0, r0, #0x10
	lsrs r6, r0, #8
.L0806607c:
	cmp r5, #3
	bgt .L0806609c
	ldr r1, L_08066098
	lsls r0, r5, #3
	adds r0, r0, r5
	lsls r0, r0, #2
	adds r0, #0x28
	ldr r1, [r1]
	adds r2, r1, r0
	lsls r0, r5, #2
	adds r0, #0x18
	adds r3, r1, r0
	b .L080660b0
	.hword 0x0000
L_08066098:
	.word 0x03006830
.L0806609c:
	ldr r0, L_080660c4
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r5, #6
	ldr r2, L_080660c8
	adds r0, r0, r2
	ldr r1, [r1]
	adds r2, r1, r0
	adds r3, r2, #0
	adds r3, #0x38
.L080660b0:
	movs r0, #2
	ldrb r1, [r4, #1]
	ands r0, r1
	cmp r0, #0
	beq .L080660cc
	asrs r0, r7, #1
	ldrh r4, [r4, #2]
	adds r0, r4, r0
	subs r0, r6, r0
	b .L080660d4
L_080660c4:
	.word 0x03006830
L_080660c8:
	.word 0xffffff00
.L080660cc:
	ldrh r4, [r4, #2]
	adds r0, r4, r6
	ldrh r1, [r2]
	subs r0, r0, r1
.L080660d4:
	strh r0, [r2, #2]
	ldr r0, [r3]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r3]
.L080660de:
	mov r2, r8
	ldr r0, [r2]
	adds r0, #6
	str r0, [r2]
.L080660e6:
	movs r0, #1
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x1A MODOFF
.global mcmd_MODOFF
.thumb_func
.type mcmd_MODOFF, %function
mcmd_MODOFF:
	push {r4, r5, r6, r7, lr}
	adds r3, r0, #0
	mov r12, r1
	ldr r7, [r1]
	cmp r3, #3
	beq .L080661e0
	cmp r3, #3
	bgt .L08066120
	ldr r2, L_0806611c
	lsls r0, r3, #3
	adds r0, r0, r3
	lsls r0, r0, #2
	adds r0, #0x28
	ldr r1, [r2]
	adds r4, r1, r0
	lsls r0, r3, #2
	adds r0, #0x18
	adds r5, r1, r0
	b .L08066134
	.hword 0x0000
L_0806611c:
	.word 0x03006830
.L08066120:
	ldr r2, L_080661f0
	ldr r1, [r2]
	adds r1, #0xd0
	lsls r0, r3, #6
	ldr r4, L_080661f4
	adds r0, r0, r4
	ldr r1, [r1]
	adds r4, r1, r0
	adds r5, r4, #0
	adds r5, #0x38
.L08066134:
	movs r0, #1
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L08066142
	movs r0, #0
	strh r0, [r4, #0x16]
.L08066142:
	movs r0, #2
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L08066150
	movs r0, #0
	strh r0, [r4, #0x1e]
.L08066150:
	movs r0, #4
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L0806615e
	movs r0, #0
	strh r0, [r4, #6]
.L0806615e:
	movs r0, #8
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L0806616c
	movs r0, #0
	strh r0, [r4, #0xe]
.L0806616c:
	movs r0, #0x10
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L080661b0
	cmp r3, #3
	ble .L080661b0
	subs r3, #4
	ldr r0, [r2]
	adds r6, r0, #0
	adds r6, #0xd0
	ldr r0, [r6]
	lsls r2, r3, #6
	adds r3, r2, r0
	ldr r1, [r3, #0x38]
	movs r0, #0x80
	lsls r0, r0, #3
	ands r0, r1
	cmp r0, #0
	beq .L080661b0
	ldr r0, L_080661f8
	ands r1, r0
	str r1, [r3, #0x38]
	ldr r0, [r6]
	adds r0, r0, r2
	adds r1, r0, #0
	adds r1, #0x2c
	ldrh r0, [r0, #0x2c]
	lsls r0, r0, #0x10
	asrs r0, r0, #0x18
	movs r2, #0
	strb r0, [r1, #5]
	strb r0, [r1, #4]
	strh r2, [r1, #2]
.L080661b0:
	movs r0, #0x40
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L080661c6
	ldr r0, [r5]
	ldr r1, L_080661fc
	ands r0, r1
	str r0, [r5]
	movs r0, #0
	strh r0, [r4, #0x12]
.L080661c6:
	movs r0, #0x20
	ldrb r7, [r7, #1]
	ands r0, r7
	cmp r0, #0
	beq .L080661d8
	ldr r0, [r5]
	ldr r1, L_08066200
	ands r0, r1
	str r0, [r5]
.L080661d8:
	ldr r0, [r5]
	movs r1, #0xc0
	orrs r0, r1
	str r0, [r5]
.L080661e0:
	mov r4, r12
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
L_080661f0:
	.word 0x03006830
L_080661f4:
	.word 0xffffff00
L_080661f8:
	.word 0xfffffbff
L_080661fc:
	.word 0xffffdfff
L_08066200:
	.word 0xffffb7ff

@ macro opcode 0x1B MODRESET
.global mcmd_MODRESET
.thumb_func
.type mcmd_MODRESET, %function
mcmd_MODRESET:
	push {r4, r5, lr}
	adds r2, r0, #0
	adds r5, r1, #0
	ldr r4, [r5]
	cmp r2, #3
	beq .L0806628c
	cmp r2, #3
	bgt .L08066230
	ldr r1, L_0806622c
	lsls r0, r2, #3
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, #0x28
	ldr r1, [r1]
	adds r3, r1, r0
	lsls r0, r2, #2
	adds r0, #0x18
	adds r2, r1, r0
	b .L08066244
	.hword 0x0000
L_0806622c:
	.word 0x03006830
.L08066230:
	ldr r0, L_0806629c
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r2, #6
	ldr r2, L_080662a0
	adds r0, r0, r2
	ldr r1, [r1]
	adds r3, r1, r0
	adds r2, r3, #0
	adds r2, #0x38
.L08066244:
	movs r0, #1
	ldrb r1, [r4, #1]
	ands r0, r1
	cmp r0, #0
	beq .L08066254
	movs r0, #0
	strh r0, [r3, #0x14]
	strh r0, [r3, #0x16]
.L08066254:
	movs r0, #2
	ldrb r1, [r4, #1]
	ands r0, r1
	cmp r0, #0
	beq .L08066264
	movs r0, #0
	strh r0, [r3, #0x1c]
	strh r0, [r3, #0x1e]
.L08066264:
	movs r0, #4
	ldrb r1, [r4, #1]
	ands r0, r1
	cmp r0, #0
	beq .L08066274
	movs r0, #0
	strh r0, [r3, #4]
	strh r0, [r3, #6]
.L08066274:
	movs r0, #8
	ldrb r4, [r4, #1]
	ands r0, r4
	cmp r0, #0
	beq .L08066284
	movs r0, #0
	strh r0, [r3, #0xc]
	strh r0, [r3, #0xe]
.L08066284:
	ldr r0, [r2]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2]
.L0806628c:
	ldr r0, [r5]
	adds r0, #2
	str r0, [r5]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000
L_0806629c:
	.word 0x03006830
L_080662a0:
	.word 0xffffff00

@ macro opcode 0x1C LASTNOTE
.global mcmd_LASTNOTE
.thumb_func
.type mcmd_LASTNOTE, %function
mcmd_LASTNOTE:
	push {r4, r5, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r5, [r4]
	cmp r2, #3
	beq .L0806632c
	ldr r0, L_08066304
	ldr r3, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r0, [r0]
	mov r12, r0
	movs r0, #0x88
	lsls r0, r0, #1
	add r0, r12
	ldr r1, [r0]
	lsls r0, r2, #1
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, r0, r1
	ldrb r1, [r0, #5]
	cmp r1, #0xff
	beq .L0806632c
	movs r0, #0x9c
	lsls r0, r0, #1
	add r0, r12
	adds r0, r0, r1
	ldrb r0, [r0]
	cmp r0, #0xff
	beq .L0806632c
	lsls r0, r0, #8
	ldrh r5, [r5, #2]
	adds r0, r5, r0
	lsls r0, r0, #0x10
	lsrs r5, r0, #0x10
	cmp r2, #3
	bgt .L08066308
	lsls r0, r2, #3
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, #0x28
	adds r1, r3, r0
	lsls r0, r2, #2
	adds r0, #0x18
	adds r2, r3, r0
	b .L0806631a
	.hword 0x0000
L_08066304:
	.word 0x03006830
.L08066308:
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r2, L_0806633c
	adds r1, r1, r2
	ldr r0, [r0]
	adds r1, r0, r1
	adds r2, r1, #0
	adds r2, #0x38
.L0806631a:
	lsls r0, r5, #0x10
	asrs r0, r0, #0x10
	ldrh r3, [r1]
	subs r0, r0, r3
	strh r0, [r1, #2]
	ldr r0, [r2]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2]
.L0806632c:
	ldr r0, [r4]
	adds r0, #4
	str r0, [r4]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000
L_0806633c:
	.word 0xffffff00

@ macro opcode 0x1D KEYMAP
.global mcmd_KEYMAP
.thumb_func
.type mcmd_KEYMAP, %function
mcmd_KEYMAP:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r5, r0, #0
	mov r8, r1
	ldr r4, [r1]
	ldr r0, L_080663c0
	ldr r3, [r0]
	movs r1, #0x8c
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r2, [r0]
	ldr r1, [r2]
	adds r1, r2, r1
	ldrh r6, [r4, #2]
	lsls r0, r6, #2
	adds r0, r0, r1
	ldr r0, [r0]
	adds r1, r2, r0
	movs r0, #0
	mov r12, r0
	ldrb r0, [r1, #2]
	cmp r0, #0
	beq .L08066444
	ldrh r7, [r1, #4]
	adds r6, r1, #6
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r0, [r0]
	movs r3, #0x88
	lsls r3, r3, #1
	adds r0, r0, r3
	ldr r1, [r0]
	lsls r0, r5, #1
	adds r0, r0, r5
	lsls r0, r0, #2
	adds r0, r0, r1
	movs r3, #4
	ldrsh r1, [r4, r3]
	ldrb r0, [r0, #7]
	adds r4, r0, r1
	cmp r4, #0
	blt .L080663dc
	cmp r4, r7
	bge .L080663dc
	cmp r5, #2
	bne .L080663c4
	lsls r0, r4, #3
	adds r0, r0, r6
	ldr r1, [r2, #0x1c]
	ldrh r0, [r0]
	lsls r0, r0, #2
	adds r1, r2, r1
	adds r0, r0, r1
	ldr r0, [r0]
	adds r0, r2, r0
	ldrb r1, [r0, #0xb]
	cmp r1, #1
	bne .L080663dc
	bl psg_LoadWave
	b .L080663e2
	.hword 0x0000
L_080663c0:
	.word 0x03006830
.L080663c4:
	cmp r5, #3
	ble .L080663dc
	subs r0, r5, #4
	lsls r2, r4, #3
	adds r2, r2, r6
	ldrh r1, [r2]
	ldrb r3, [r2, #6]
	movs r2, #0
	bl sub_08065b54
	movs r2, #1
	mov r12, r2
.L080663dc:
	mov r3, r12
	cmp r3, #0
	beq .L08066444
.L080663e2:
	lsls r0, r4, #3
	adds r4, r0, r6
	movs r0, #4
	ldrsb r0, [r4, r0]
	adds r1, r5, #0
	bl voice_AddPan
	ldrh r3, [r4, #2]
	movs r6, #2
	ldrsh r0, [r4, r6]
	cmp r0, #0
	beq .L08066444
	cmp r5, #2
	bne .L0806641c
	ldr r0, L_08066418
	ldr r2, [r0]
	adds r1, r2, #0
	adds r1, #0x72
	ldrh r4, [r1]
	adds r0, r3, r4
	strh r0, [r1]
	ldr r0, [r2, #0x20]
	movs r1, #0x40
	orrs r0, r1
	str r0, [r2, #0x20]
	b .L08066444
	.hword 0x0000
L_08066418:
	.word 0x03006830
.L0806641c:
	cmp r5, #3
	ble .L08066444
	ldrb r0, [r4, #6]
	cmp r0, #0
	bne .L08066444
	ldr r0, L_08066458
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r5, #6
	ldr r6, L_0806645c
	adds r0, r0, r6
	ldr r1, [r1]
	adds r1, r1, r0
	ldrh r2, [r1, #2]
	adds r0, r3, r2
	strh r0, [r1, #2]
	ldr r0, [r1, #0x38]
	movs r2, #0x40
	orrs r0, r2
	str r0, [r1, #0x38]
.L08066444:
	mov r3, r8
	ldr r0, [r3]
	adds r0, #6
	str r0, [r3]
	movs r0, #1
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
L_08066458:
	.word 0x03006830
L_0806645c:
	.word 0xffffff00

@ macro opcode 0x1E PLAYMACRO
.global mcmd_PLAYMACRO
.thumb_func
.type mcmd_PLAYMACRO, %function
mcmd_PLAYMACRO:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #0xc
	adds r7, r0, #0
	str r1, [sp, #4]
	ldr r4, [r1]
	ldrb r1, [r4, #5]
	ldr r0, L_080664a0
	ldr r2, [r0]
	ldrb r0, [r2, #8]
	adds r0, #4
	cmp r1, r0
	blt .L08066486
	cmp r1, #0xff
	beq .L08066486
	b .L080666b4
.L08066486:
	cmp r7, #3
	bgt .L080664a4
	lsls r0, r7, #1
	adds r0, #0xb4
	adds r6, r2, r0
	lsls r0, r7, #2
	adds r0, r2, r0
	movs r1, #1
	ldrh r0, [r0, #0x1a]
	ands r0, r1
	mov r9, r0
	b .L080664c0
	.hword 0x0000
L_080664a0:
	.word 0x03006830
.L080664a4:
	adds r2, #0xd0
	lsls r1, r7, #6
	ldr r3, L_080664e8
	adds r0, r1, r3
	ldr r2, [r2]
	adds r0, r2, r0
	adds r6, r0, #0
	adds r6, #0x34
	adds r1, r1, r2
	adds r1, r1, r3
	movs r2, #1
	ldrh r1, [r1, #0x3a]
	ands r1, r2
	mov r9, r1
.L080664c0:
	ldrh r3, [r6]
	mov r8, r3
	ldr r1, L_080664ec
	adds r0, r1, #0
	strh r0, [r6]
	ldrb r2, [r4, #5]
	cmp r2, #3
	bhi .L080664f0
	ldrb r1, [r4, #4]
	ldrb r2, [r4, #5]
	mov r0, r9
	bl psg_VoiceAvail
	movs r5, #1
	rsbs r5, r5, #0
	cmp r0, #0
	beq .L0806650c
	ldrb r5, [r4, #5]
	b .L0806650c
	.hword 0x0000
L_080664e8:
	.word 0xffffff00
L_080664ec:
	.word 0x00007fff
.L080664f0:
	ldrb r5, [r4, #5]
	cmp r5, #0xff
	beq .L080664f8
	subs r5, #4
.L080664f8:
	ldrb r1, [r4, #4]
	mov r0, r9
	movs r2, #0xff
	adds r3, r5, #0
	bl ds_VoiceAlloc
	adds r5, r0, #0
	cmp r5, #0
	blt .L0806650c
	adds r5, #4
.L0806650c:
	mov r3, r8
	strh r3, [r6]
	cmp r5, #0
	bge .L08066516
	b .L080666b4
.L08066516:
	ldr r0, L_0806658c
	ldr r0, [r0]
	mov r12, r0
	movs r0, #0x8c
	lsls r0, r0, #1
	add r0, r12
	ldr r2, [r0]
	ldr r0, [r2]
	ldrh r3, [r4, #6]
	lsls r1, r3, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1]
	adds r2, r2, r0
	str r2, [sp, #8]
	movs r0, #0x90
	lsls r0, r0, #1
	add r0, r12
	ldr r1, [r0]
	movs r0, #0x88
	lsls r0, r0, #1
	adds r1, r1, r0
	lsls r0, r7, #1
	adds r0, r0, r7
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r6, r1, r0
	mov r1, r12
	ldrh r1, [r1, #0x16]
	ldrb r2, [r6, #6]
	adds r0, r1, #0
	muls r0, r2, r0
	asrs r7, r0, #8
	cmp r5, #3
	bgt .L080665d0
	movs r0, #1
	ldrb r3, [r4, #2]
	ands r0, r3
	cmp r0, #0
	bne .L08066590
	movs r0, #3
	ldrsb r0, [r4, r0]
	ldrb r2, [r6, #7]
	adds r1, r2, r0
	ldrb r2, [r4, #4]
	mov r3, r9
	cmp r3, #0
	beq .L0806657c
	movs r0, #0x80
	lsls r0, r0, #1
	adds r2, r2, r0
.L0806657c:
	str r2, [sp]
	adds r0, r5, #0
	movs r2, #0x40
	adds r3, r7, #0
	bl psg_VoiceStart
	b .L080665ae
	.hword 0x0000
L_0806658c:
	.word 0x03006830
.L08066590:
	movs r0, #3
	ldrsb r0, [r4, r0]
	ldrb r2, [r6, #7]
	adds r1, r2, r0
	ldrb r3, [r4, #4]
	mov r0, r9
	cmp r0, #0
	beq .L080665a6
	movs r0, #0x80
	lsls r0, r0, #1
	adds r3, r3, r0
.L080665a6:
	adds r0, r5, #0
	adds r2, r7, #0
	bl psg_VoiceLegato
.L080665ae:
	ldr r3, L_080665cc
	mov r1, r9
	cmp r1, #0
	beq .L08066668
	ldr r1, [r3]
	lsls r0, r5, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0x80
	lsls r2, r2, #9
	orrs r0, r2
	str r0, [r1]
	b .L08066668
	.hword 0x0000
L_080665cc:
	.word 0x03006830
.L080665d0:
	subs r5, #4
	mov r0, r12
	adds r0, #0xd0
	lsls r1, r5, #6
	ldr r0, [r0]
	adds r0, r0, r1
	mov r8, r0
	movs r2, #1
	ldrb r3, [r4, #2]
	ands r2, r3
	cmp r2, #0
	bne .L0806661c
	mov r0, r12
	adds r0, #0xcc
	ldr r0, [r0]
	lsls r1, r5, #2
	adds r0, r1, r0
	str r2, [r0]
	movs r0, #3
	ldrsb r0, [r4, r0]
	ldrb r2, [r6, #7]
	adds r3, r2, r0
	ldrb r2, [r4, #4]
	mov r10, r1
	mov r0, r9
	cmp r0, #0
	beq .L0806660c
	movs r0, #0x80
	lsls r0, r0, #1
	adds r2, r2, r0
.L0806660c:
	str r2, [sp]
	mov r0, r8
	adds r1, r3, #0
	movs r2, #0x40
	adds r3, r7, #0
	bl ds_VoiceStart
	b .L0806663e
.L0806661c:
	movs r0, #3
	ldrsb r0, [r4, r0]
	ldrb r2, [r6, #7]
	adds r1, r2, r0
	ldrb r3, [r4, #4]
	mov r0, r9
	cmp r0, #0
	beq .L08066632
	movs r0, #0x80
	lsls r0, r0, #1
	adds r3, r3, r0
.L08066632:
	mov r0, r8
	adds r2, r7, #0
	bl ds_VoiceLegato
	lsls r1, r5, #2
	mov r10, r1
.L0806663e:
	ldr r3, L_080666d0
	mov r2, r9
	cmp r2, #0
	beq .L0806665a
	ldr r0, [r3]
	adds r0, #0xd0
	ldr r0, [r0]
	lsls r1, r5, #6
	adds r1, r1, r0
	ldr r0, [r1, #0x38]
	movs r2, #0x80
	lsls r2, r2, #9
	orrs r0, r2
	str r0, [r1, #0x38]
.L0806665a:
	ldr r0, [r3]
	adds r0, #0xd4
	ldr r0, [r0]
	add r0, r10
	mov r7, r8
	str r7, [r0]
	adds r5, #4
.L08066668:
	ldr r0, [r3]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	movs r2, #0x88
	lsls r2, r2, #1
	adds r1, r1, r2
	lsls r0, r5, #1
	adds r0, r0, r5
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r1, r1, r0
	movs r2, #0
	strb r2, [r1, #4]
	ldrb r0, [r6, #5]
	strb r0, [r1, #5]
	ldrb r0, [r6, #6]
	strb r0, [r1, #6]
	ldrb r6, [r6, #7]
	ldrb r7, [r4, #3]
	adds r0, r6, r7
	strb r0, [r1, #7]
	ldr r0, [r3]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r0, r1
	lsls r1, r5, #4
	ldr r0, [r0]
	adds r0, r0, r1
	strh r2, [r0, #8]
	strh r2, [r0, #0xa]
	str r2, [r0, #4]
	ldr r1, [sp, #8]
	adds r1, #4
	str r1, [r0]
	ldrh r1, [r4, #6]
	strh r1, [r0, #0xc]
.L080666b4:
	ldr r2, [sp, #4]
	ldr r0, [r2]
	adds r0, #8
	str r0, [r2]
	movs r0, #1
	add sp, #0xc
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000
L_080666d0:
	.word 0x03006830

@ macro opcode 0x2D PANSWEEP
.global mcmd_PANSWEEP
.thumb_func
.type mcmd_PANSWEEP, %function
mcmd_PANSWEEP:
	push {r4, r5, lr}
	adds r2, r0, #0
	adds r5, r1, #0
	ldr r4, [r5]
	cmp r2, #3
	ble .L08066730
	movs r1, #4
	ldrsh r0, [r4, r1]
	cmp r0, #0
	beq .L08066730
	subs r2, #4
	ldr r0, L_08066708
	ldr r0, [r0]
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r3, r0, r1
	adds r1, r3, #0
	adds r2, r3, #0
	adds r2, #0x3c
	ldrb r0, [r2]
	cmp r0, #0xff
	beq .L0806670c
	ldrb r2, [r2]
	lsls r0, r2, #8
	b .L08066712
L_08066708:
	.word 0x03006830
.L0806670c:
	movs r2, #0x80
	lsls r2, r2, #7
	adds r0, r2, #0
.L08066712:
	strh r0, [r1, #0xa]
	ldrh r0, [r4, #4]
	strh r0, [r1, #0x12]
	ldrb r0, [r4, #2]
	strb r0, [r1, #0x1a]
	ldrb r0, [r4, #3]
	strb r0, [r1, #0x1b]
	ldrb r0, [r4, #1]
	cmp r0, #0
	beq .L08066730
	ldr r0, [r3, #0x38]
	movs r1, #0x80
	lsls r1, r1, #6
	orrs r0, r1
	str r0, [r3, #0x38]
.L08066730:
	ldr r0, [r5]
	adds r0, #6
	str r0, [r5]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x2F SCALEVOL
.global mcmd_SCALEVOL
.thumb_func
.type mcmd_SCALEVOL, %function
mcmd_SCALEVOL:
	push {r4, r5, r6, r7, lr}
	adds r4, r0, #0
	adds r6, r1, #0
	ldr r3, [r6]
	ldr r2, L_08066770
	ldr r0, [r2]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	movs r7, #0x88
	lsls r7, r7, #1
	adds r1, r1, r7
	lsls r0, r4, #1
	adds r0, r0, r4
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r5, r1, r0
	ldrb r0, [r3, #1]
	cmp r0, #0
	bne .L08066774
	ldrh r1, [r3, #4]
	ldrb r7, [r5, #6]
	b .L08066778
L_08066770:
	.word 0x03006830
.L08066774:
	ldrh r1, [r3, #4]
	ldrb r7, [r5, #8]
.L08066778:
	adds r0, r1, #0
	muls r0, r7, r0
	asrs r0, r0, #8
	movs r1, #2
	ldrsb r1, [r3, r1]
	adds r3, r0, r1
	cmp r3, #0
	bge .L0806678c
	movs r3, #0
	b .L08066792
.L0806678c:
	cmp r3, #0x7f
	ble .L08066792
	movs r3, #0x7f
.L08066792:
	strb r3, [r5, #6]
	cmp r4, #3
	bgt .L080667b4
	lsls r0, r4, #3
	adds r0, #0x94
	ldr r1, [r2]
	adds r1, r1, r0
	strb r3, [r1, #7]
	ldr r1, [r2]
	lsls r0, r4, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1]
	b .L080667e2
.L080667b4:
	subs r4, #4
	ldr r0, [r2]
	adds r0, #0xd0
	lsls r4, r4, #6
	ldr r0, [r0]
	adds r0, r0, r4
	adds r1, r0, #0
	adds r1, #0x24
	lsls r3, r3, #1
	strb r3, [r1, #7]
	lsls r0, r3, #0x18
	cmp r0, #0
	beq .L080667d2
	adds r0, r3, #1
	strb r0, [r1, #7]
.L080667d2:
	ldr r0, [r2]
	adds r0, #0xd0
	ldr r1, [r0]
	adds r1, r4, r1
	ldr r0, [r1, #0x38]
	movs r2, #0x80
	orrs r0, r2
	str r0, [r1, #0x38]
.L080667e2:
	ldr r0, [r6]
	adds r0, #6
	str r0, [r6]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

@ macro opcode 0x30 LOOPSCAN
.global mcmd_LOOPSCAN
.thumb_func
.type mcmd_LOOPSCAN, %function
mcmd_LOOPSCAN:
	push {r4, r5, r6, r7, lr}
	adds r3, r0, #0
	adds r6, r1, #0
	ldr r5, [r6]
	cmp r3, #3
	ble .L08066874
	subs r3, #4
	ldr r2, L_08066838
	ldr r4, [r2]
	adds r0, r4, #0
	adds r0, #0xd0
	lsls r1, r3, #6
	ldr r0, [r0]
	adds r0, r0, r1
	ldr r1, [r0, #0x38]
	movs r0, #0xa0
	lsls r0, r0, #5
	ands r1, r0
	movs r0, #0x80
	lsls r0, r0, #5
	adds r7, r2, #0
	cmp r1, r0
	bne .L08066874
	ldrb r0, [r5, #1]
	cmp r0, #0
	bne .L0806683c
	adds r0, r4, #0
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r2, [r0]
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	lsls r1, r1, #4
	b .L0806684e
L_08066838:
	.word 0x03006830
.L0806683c:
	adds r0, r4, #0
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r2, [r0]
	ldr r0, [r2, #0x38]
	movs r1, #0x90
	lsls r1, r1, #7
.L0806684e:
	orrs r0, r1
	str r0, [r2, #0x38]
	ldr r0, [r7]
	adds r0, #0xd0
	lsls r1, r3, #6
	ldr r2, [r0]
	adds r2, r2, r1
	adds r1, r2, #0
	adds r1, #0x2c
	ldrh r0, [r5, #4]
	strh r0, [r1, #4]
	ldrh r0, [r5, #4]
	strh r0, [r1, #2]
	ldrb r0, [r5, #6]
	strb r0, [r1, #7]
	ldrb r0, [r5, #6]
	strb r0, [r1, #6]
	ldrh r0, [r5, #2]
	strh r0, [r2, #0x2c]
.L08066874:
	ldr r0, [r6]
	adds r0, #8
	str r0, [r6]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x31 SETWAVE
.global mcmd_SETWAVE
.thumb_func
.type mcmd_SETWAVE, %function
mcmd_SETWAVE:
	push {r4, r5, r6, r7, lr}
	adds r4, r0, #0
	adds r5, r1, #0
	ldr r7, [r5]
	cmp r4, #3
	ble .L0806690a
	subs r4, #4
	ldr r0, L_08066918
	ldr r0, [r0]
	mov r12, r0
	adds r0, #0xd0
	lsls r1, r4, #6
	ldr r0, [r0]
	adds r2, r0, r1
	ldr r0, [r2, #0x38]
	movs r1, #0x80
	lsls r1, r1, #3
	ands r0, r1
	cmp r0, #0
	beq .L0806690a
	adds r6, r2, #0
	adds r6, #0x2c
	mov r1, r12
	adds r1, #0xc8
	lsls r0, r4, #3
	subs r0, r0, r4
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r3, r1, r0
	mov r0, r12
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	movs r1, #0
	str r1, [r0]
	movs r0, #0x8c
	lsls r0, r0, #1
	add r0, r12
	ldr r2, [r0]
	ldr r0, [r2, #0x1c]
	ldrh r7, [r7, #2]
	lsls r1, r7, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1]
	adds r1, r2, r0
	ldr r0, [r1]
	cmp r0, #0x7f
	bls .L0806690a
	str r1, [r3]
	movs r0, #4
	ldrsb r0, [r6, r0]
	adds r0, #0x10
	adds r0, r1, r0
	str r0, [r3, #0xc]
	str r0, [r3, #4]
	adds r0, #0x40
	str r0, [r3, #8]
	movs r0, #0x40
	str r0, [r3, #0x10]
	adds r0, r4, #0
	bl voice_CalcMixVolume
	adds r0, r4, #0
	bl voice_UpdateStep
.L0806690a:
	ldr r0, [r5]
	adds r0, #4
	str r0, [r5]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
L_08066918:
	.word 0x03006830

.global macro_Execute
.thumb_func
.type macro_Execute, %function
macro_Execute:
	push {r4, r5, r6, r7, lr}
	movs r5, #0
	b .L08066960
.L08066922:
	ldr r0, [r1]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	lsls r1, r5, #4
	adds r0, r1, r0
	ldr r0, [r0]
	adds r4, r1, #0
	adds r6, r5, #1
	cmp r0, #0
	beq .L0806695e
	ldr r7, L_08066974
.L0806693c:
	ldr r0, L_08066978
	ldr r0, [r0]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	adds r1, r4, r1
	ldr r0, [r1]
	ldrb r0, [r0]
	lsls r0, r0, #2
	adds r0, r0, r7
	ldr r2, [r0]
	adds r0, r5, #0
	bl _call_via_r2
	cmp r0, #0
	bne .L0806693c
.L0806695e:
	adds r5, r6, #0
.L08066960:
	ldr r1, L_08066978
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r5, r0
	blt .L08066922
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08066974:
	.word 0x087fff28
L_08066978:
	.word 0x03006830

@ macro opcode 0x03 KEYON
.global mcmd_KEYON
.thumb_func
.type mcmd_KEYON, %function
mcmd_KEYON:
	push {r4, r5, r6, lr}
	adds r4, r0, #0
	adds r5, r1, #0
	ldr r6, [r5]
	bl voice_Trigger
	cmp r4, #3
	ble .L080669ba
	ldr r0, L_080669c8
	ldr r1, [r0]
	movs r2, #0x8b
	lsls r2, r2, #1
	adds r0, r1, r2
	ldrb r0, [r0]
	cmp r0, #0
	beq .L080669ba
	adds r0, r1, #0
	adds r0, #0xc8
	ldr r1, [r0]
	lsls r0, r4, #3
	subs r0, r0, r4
	lsls r0, r0, #2
	adds r0, r0, r1
	adds r1, r0, #0
	subs r1, #0x70
	movs r2, #0
	ldrb r0, [r6, #1]
	cmp r0, #0
	bne .L080669b8
	movs r2, #1
.L080669b8:
	strb r2, [r1, #0x1b]
.L080669ba:
	ldr r0, [r5]
	adds r0, #2
	str r0, [r5]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
L_080669c8:
	.word 0x03006830

@ macro opcode 0x07 PANNING
.global mcmd_PANNING
.thumb_func
.type mcmd_PANNING, %function
mcmd_PANNING:
	push {r4, r5, r6, lr}
	adds r6, r0, #0
	adds r5, r1, #0
	ldr r4, [r5]
	ldrb r0, [r4, #2]
	cmp r0, #0
	bne .L080669e4
	ldrb r0, [r4, #1]
	adds r1, r6, #0
	bl voice_SetPan
	b .L08066a10
.L080669e4:
	ldrb r1, [r4, #2]
	lsls r0, r1, #1
	bl snd_Rand
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	ldrb r1, [r4, #2]
	subs r0, r0, r1
	ldrb r4, [r4, #1]
	adds r0, r4, r0
	cmp r0, #0
	bge .L08066a00
	movs r0, #0
	b .L08066a06
.L08066a00:
	cmp r0, #0x7f
	ble .L08066a06
	movs r0, #0x7f
.L08066a06:
	lsls r0, r0, #0x18
	lsrs r0, r0, #0x18
	adds r1, r6, #0
	bl voice_SetPan
.L08066a10:
	ldr r0, [r5]
	adds r0, #4
	str r0, [r5]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x0A VIBRATO
.global mcmd_VIBRATO
.thumb_func
.type mcmd_VIBRATO, %function
mcmd_VIBRATO:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r1, [r4]
	movs r3, #2
	ldrsh r0, [r1, r3]
	ldrb r1, [r1, #1]
	bl mod_SetVibrato
	ldr r0, [r4]
	adds r0, #4
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1

@ macro opcode 0x0B PITCHSWEEP
.global mcmd_PITCHSWEEP
.thumb_func
.type mcmd_PITCHSWEEP, %function
mcmd_PITCHSWEEP:
	push {r4, r5, lr}
	adds r3, r0, #0
	adds r4, r1, #0
	ldr r2, [r4]
	ldrb r0, [r2, #1]
	movs r5, #2
	ldrsh r1, [r2, r5]
	movs r5, #4
	ldrsh r2, [r2, r5]
	bl mod_SetPitchSweep
	ldr r0, [r4]
	adds r0, #6
	str r0, [r4]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1

@ macro opcode 0x0C PORTAMENTO
.global mcmd_PORTAMENTO
.thumb_func
.type mcmd_PORTAMENTO, %function
mcmd_PORTAMENTO:
	push {r4, r5, lr}
	adds r3, r0, #0
	adds r4, r1, #0
	ldr r2, [r4]
	movs r0, #1
	ldrb r1, [r2, #1]
	ands r0, r1
	movs r5, #2
	ldrsh r1, [r2, r5]
	ldrh r2, [r2, #4]
	bl mod_SetPortamento
	ldr r0, [r4]
	adds r0, #6
	str r0, [r4]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x0D GOTO
.global mcmd_GOTO
.thumb_func
.type mcmd_GOTO, %function
mcmd_GOTO:
	ldr r2, [r1]
	ldrh r3, [r2, #4]
	lsls r0, r3, #0x10
	ldrh r3, [r2, #2]
	orrs r0, r3
	adds r2, r2, r0
	str r2, [r1]
	movs r0, #1
	bx lr
	.hword 0x0000

@ macro opcode 0x0E SETADSR
.global mcmd_SETADSR
.thumb_func
.type mcmd_SETADSR, %function
mcmd_SETADSR:
	push {r4, r5, r6, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r5, [r4]
	ldr r0, L_08066ad8
	ldr r0, [r0]
	movs r1, #0x8c
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	ldr r1, [r0, #4]
	ldrh r6, [r5, #2]
	lsls r3, r6, #2
	adds r1, r0, r1
	adds r3, r3, r1
	ldr r1, [r3]
	adds r0, r0, r1
	ldrb r1, [r5, #1]
	bl env_SetADSR
	ldr r0, [r4]
	adds r0, #4
	str r0, [r4]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000
L_08066ad8:
	.word 0x03006830

@ macro opcode 0x10 TRAPKEYOFF
.global mcmd_TRAPKEYOFF
.thumb_func
.type mcmd_TRAPKEYOFF, %function
mcmd_TRAPKEYOFF:
	ldr r2, [r1]
	ldrh r3, [r2, #4]
	lsls r0, r3, #0x10
	ldrh r3, [r2, #2]
	orrs r0, r3
	adds r0, r2, r0
	str r0, [r1, #4]
	adds r2, #6
	str r2, [r1]
	movs r0, #1
	bx lr
	.hword 0x0000

@ macro opcode 0x11 UNTRAPKEYOFF
.global mcmd_UNTRAPKEYOFF
.thumb_func
.type mcmd_UNTRAPKEYOFF, %function
mcmd_UNTRAPKEYOFF:
	movs r0, #0
	str r0, [r1, #4]
	ldr r0, [r1]
	adds r0, #2
	str r0, [r1]
	movs r0, #1
	bx lr
	.hword 0x0000

@ macro opcode 0x15 FADE
.global mcmd_FADE
.thumb_func
.type mcmd_FADE, %function
mcmd_FADE:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r1, [r4]
	ldrb r0, [r1, #1]
	ldrh r1, [r1, #2]
	bl env_SetFade
	ldr r0, [r4]
	adds r0, #4
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x17 SPLITKEY
.global mcmd_SPLITKEY
.thumb_func
.type mcmd_SPLITKEY, %function
mcmd_SPLITKEY:
	push {r4, lr}
	adds r4, r1, #0
	ldr r3, [r4]
	ldr r1, L_08066b58
	ldr r1, [r1]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r1, r1, r2
	ldr r1, [r1]
	subs r2, #0x10
	adds r1, r1, r2
	ldr r2, [r1]
	lsls r1, r0, #1
	adds r1, r1, r0
	lsls r1, r1, #2
	adds r1, r1, r2
	ldrb r1, [r1, #7]
	ldrb r0, [r3, #1]
	cmp r1, r0
	blo .L08066b5c
	ldrh r1, [r3, #4]
	lsls r0, r1, #0x10
	ldrh r2, [r3, #2]
	orrs r0, r2
	adds r0, r3, r0
	b .L08066b5e
L_08066b58:
	.word 0x03006830
.L08066b5c:
	adds r0, r3, #6
.L08066b5e:
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1

@ macro opcode 0x18 SPLITVEL
.global mcmd_SPLITVEL
.thumb_func
.type mcmd_SPLITVEL, %function
mcmd_SPLITVEL:
	push {r4, lr}
	adds r4, r1, #0
	ldr r3, [r4]
	ldr r1, L_08066b9c
	ldr r1, [r1]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r1, r1, r2
	ldr r1, [r1]
	subs r2, #0x10
	adds r1, r1, r2
	ldr r2, [r1]
	lsls r1, r0, #1
	adds r1, r1, r0
	lsls r1, r1, #2
	adds r1, r1, r2
	ldrb r1, [r1, #8]
	ldrb r0, [r3, #1]
	cmp r1, r0
	blo .L08066ba0
	ldrh r1, [r3, #4]
	lsls r0, r1, #0x10
	ldrh r2, [r3, #2]
	orrs r0, r2
	adds r0, r3, r0
	b .L08066ba2
L_08066b9c:
	.word 0x03006830
.L08066ba0:
	adds r0, r3, #6
.L08066ba2:
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1

@ macro opcode 0x19 SPLITRND
.global mcmd_SPLITRND
.thumb_func
.type mcmd_SPLITRND, %function
mcmd_SPLITRND:
	push {r4, r5, lr}
	adds r5, r1, #0
	ldr r4, [r5]
	movs r0, #0xff
	bl snd_Rand
	lsls r0, r0, #0x10
	lsrs r0, r0, #0x10
	ldrb r1, [r4, #1]
	cmp r0, r1
	blo .L08066bd0
	ldrh r0, [r4, #4]
	lsls r1, r0, #0x10
	ldrh r4, [r4, #2]
	orrs r1, r4
	ldr r0, [r5]
	adds r0, r0, r1
	b .L08066bd4
.L08066bd0:
	ldr r0, [r5]
	adds r0, #6
.L08066bd4:
	str r0, [r5]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x1F NOP
.global mcmd_NOP
.thumb_func
.type mcmd_NOP, %function
mcmd_NOP:
	ldr r0, [r1]
	adds r0, #2
	str r0, [r1]
	movs r0, #1
	bx lr
	.hword 0x0000

@ macro opcode 0x20 PSGDUTY
.global mcmd_PSGDUTY
.thumb_func
.type mcmd_PSGDUTY, %function
mcmd_PSGDUTY:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r0, [r4]
	cmp r2, #1
	bgt .L08066c22
	ldrb r0, [r0, #1]
	cmp r0, #0xff
	bne .L08066c1c
	ldr r0, L_08066c30
	ldr r0, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	subs r1, #0x10
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r2, #1
	adds r0, r0, r2
	lsls r0, r0, #2
	adds r0, r0, r1
	ldrb r0, [r0, #6]
	lsrs r0, r0, #5
.L08066c1c:
	adds r1, r2, #0
	bl psg_SetDuty
.L08066c22:
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
L_08066c30:
	.word 0x03006830

@ macro opcode 0x21 NOISEPARAM
.global mcmd_NOISEPARAM
.thumb_func
.type mcmd_NOISEPARAM, %function
mcmd_NOISEPARAM:
	push {r4, lr}
	adds r4, r1, #0
	ldr r1, [r4]
	cmp r0, #3
	bne .L08066c44
	ldrb r0, [r1, #1]
	bl psg_SetNoise
.L08066c44:
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x22 SENDKEYOFF
.global mcmd_SENDKEYOFF
.thumb_func
.type mcmd_SENDKEYOFF, %function
mcmd_SENDKEYOFF:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r0, [r4]
	ldrb r1, [r0, #1]
	ldr r0, L_08066c74
	ldr r0, [r0]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r1, r0
	bge .L08066c78
	adds r0, r1, #0
	bl voice_KeyOff
	b .L08066c82
	.hword 0x0000
L_08066c74:
	.word 0x03006830
.L08066c78:
	cmp r1, #0xff
	bne .L08066c82
	adds r0, r2, #0
	bl voice_KeyOff
.L08066c82:
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1

@ macro opcode 0x23 KEYOFFMACRO
.global mcmd_KEYOFFMACRO
.thumb_func
.type mcmd_KEYOFFMACRO, %function
mcmd_KEYOFFMACRO:
	push {r4, r5, r6, lr}
	adds r5, r1, #0
	ldr r6, [r5]
	movs r4, #0
	b .L08066cbe
.L08066c9a:
	ldr r0, [r1]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r4, #4
	adds r1, r0, r1
	ldr r0, [r1]
	cmp r0, #0
	beq .L08066cbc
	ldrh r1, [r1, #0xc]
	ldrh r0, [r6, #2]
	cmp r1, r0
	bne .L08066cbc
	adds r0, r4, #0
	bl voice_KeyOff
.L08066cbc:
	adds r4, #1
.L08066cbe:
	ldr r1, L_08066cd8
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	blt .L08066c9a
	ldr r0, [r5]
	adds r0, #4
	str r0, [r5]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
L_08066cd8:
	.word 0x03006830

@ macro opcode 0x24 PSGENV
.global mcmd_PSGENV
.thumb_func
.type mcmd_PSGENV, %function
mcmd_PSGENV:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r0, [r4]
	cmp r2, #1
	ble .L08066cec
	cmp r2, #3
	bne .L08066cf4
.L08066cec:
	ldrb r0, [r0, #1]
	adds r1, r2, #0
	bl psg_SetHWEnvelope
.L08066cf4:
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x25 PSGENVOFF
.global mcmd_PSGENVOFF
.thumb_func
.type mcmd_PSGENVOFF, %function
mcmd_PSGENVOFF:
	push {r4, r5, lr}
	adds r4, r0, #0
	adds r5, r1, #0
	cmp r4, #1
	ble .L08066d12
	cmp r4, #3
	bne .L08066d2e
.L08066d12:
	movs r0, #0
	adds r1, r4, #0
	bl psg_SetHWEnvelope
	ldr r0, L_08066d3c
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	movs r2, #0xa0
	lsls r2, r2, #2
	orrs r0, r2
	str r0, [r1]
.L08066d2e:
	ldr r0, [r5]
	adds r0, #2
	str r0, [r5]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
L_08066d3c:
	.word 0x03006830

@ macro opcode 0x26 SETPRIO
.global mcmd_SETPRIO
.thumb_func
.type mcmd_SETPRIO, %function
mcmd_SETPRIO:
	push {r4, lr}
	adds r2, r0, #0
	adds r3, r1, #0
	ldr r4, [r3]
	cmp r2, #3
	bgt .L08066d5c
	ldr r0, L_08066d58
	lsls r1, r2, #1
	adds r1, #0xb4
	ldr r0, [r0]
	adds r1, r0, r1
	b .L08066d6a
L_08066d58:
	.word 0x03006830
.L08066d5c:
	ldr r0, L_08066d88
	ldr r0, [r0]
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r1, r1, r0
	subs r1, #0xcc
.L08066d6a:
	movs r0, #0xff
	lsls r0, r0, #8
	ldrh r2, [r1]
	ands r0, r2
	ldrb r4, [r4, #1]
	orrs r0, r4
	strh r0, [r1]
	ldr r0, [r3]
	adds r0, #2
	str r0, [r3]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000
L_08066d88:
	.word 0x03006830

@ macro opcode 0x27 ADDPRIO
.global mcmd_ADDPRIO
.thumb_func
.type mcmd_ADDPRIO, %function
mcmd_ADDPRIO:
	push {r4, r5, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r5, [r4]
	cmp r2, #3
	bgt .L08066da8
	ldr r0, L_08066da4
	lsls r1, r2, #1
	adds r1, #0xb4
	ldr r0, [r0]
	adds r3, r0, r1
	b .L08066db8
L_08066da4:
	.word 0x03006830
.L08066da8:
	ldr r0, L_08066dd0
	ldr r0, [r0]
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r1, r1, r0
	adds r3, r1, #0
	subs r3, #0xcc
.L08066db8:
	ldrh r1, [r3]
	movs r2, #0xff
	lsls r2, r2, #8
	ands r2, r1
	movs r0, #1
	ldrsb r0, [r5, r0]
	orrs r2, r0
	cmp r2, #0
	bge .L08066dd4
	movs r2, #0
	b .L08066dda
	.hword 0x0000
L_08066dd0:
	.word 0x03006830
.L08066dd4:
	cmp r2, #0xff
	ble .L08066dda
	movs r2, #0xff
.L08066dda:
	movs r0, #0xff
	lsls r0, r0, #8
	ands r0, r1
	lsls r1, r2, #0x18
	lsrs r1, r1, #0x18
	orrs r1, r0
	strh r1, [r3]
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
	.hword 0x0000

@ macro opcode 0x28 SETAGE
.global mcmd_SETAGE
.thumb_func
.type mcmd_SETAGE, %function
mcmd_SETAGE:
	push {r4, lr}
	adds r3, r0, #0
	adds r2, r1, #0
	ldr r4, [r2]
	cmp r3, #3
	ble .L08066e18
	ldr r0, L_08066e28
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r3, #6
	adds r0, r0, r1
	ldr r3, L_08066e2c
	adds r1, r0, r3
	ldrh r0, [r4, #2]
	strh r0, [r1, #0x36]
.L08066e18:
	ldr r0, [r2]
	adds r0, #4
	str r0, [r2]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000
L_08066e28:
	.word 0x03006830
L_08066e2c:
	.word 0xffffff00

@ macro opcode 0x29 ADDAGE
.global mcmd_ADDAGE
.thumb_func
.type mcmd_ADDAGE, %function
mcmd_ADDAGE:
	push {r4, r5, lr}
	adds r2, r0, #0
	adds r3, r1, #0
	ldr r4, [r3]
	cmp r2, #3
	ble .L08066e72
	ldr r0, L_08066e60
	ldr r1, [r0]
	adds r1, #0xd0
	lsls r0, r2, #6
	ldr r2, L_08066e64
	adds r0, r0, r2
	ldr r1, [r1]
	adds r1, r1, r0
	adds r2, r1, #0
	adds r2, #0x36
	movs r5, #2
	ldrsh r0, [r4, r5]
	ldrh r1, [r1, #0x36]
	adds r0, r1, r0
	cmp r0, #0
	bge .L08066e68
	movs r0, #0
	b .L08066e70
L_08066e60:
	.word 0x03006830
L_08066e64:
	.word 0xffffff00
.L08066e68:
	ldr r1, L_08066e80
	cmp r0, r1
	ble .L08066e70
	adds r0, r1, #0
.L08066e70:
	strh r0, [r2]
.L08066e72:
	ldr r0, [r3]
	adds r0, #4
	str r0, [r3]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
L_08066e80:
	.word 0x0000ffff

@ macro opcode 0x2A SETFLAG
.global mcmd_SETFLAG
.thumb_func
.type mcmd_SETFLAG, %function
mcmd_SETFLAG:
	push {r4, lr}
	adds r4, r1, #0
	ldr r3, [r4]
	ldrb r0, [r3, #2]
	cmp r0, #0
	beq .L08066ea4
	ldr r0, L_08066ea0
	ldr r2, [r0]
	movs r1, #1
	ldrb r3, [r3, #3]
	lsls r1, r3
	ldr r0, [r2, #0x10]
	orrs r0, r1
	b .L08066eb2
L_08066ea0:
	.word 0x03006830
.L08066ea4:
	ldr r0, L_08066ec4
	ldr r2, [r0]
	movs r1, #1
	ldrb r3, [r3, #3]
	lsls r1, r3
	ldr r0, [r2, #0x10]
	bics r0, r1
.L08066eb2:
	str r0, [r2, #0x10]
	ldr r0, [r4]
	adds r0, #4
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
	.hword 0x0000
L_08066ec4:
	.word 0x03006830

@ macro opcode 0x2B IFFLAG
.global mcmd_IFFLAG
.thumb_func
.type mcmd_IFFLAG, %function
mcmd_IFFLAG:
	push {r4, lr}
	adds r3, r1, #0
	ldr r2, [r3]
	ldr r0, L_08066eec
	ldr r0, [r0]
	movs r1, #1
	ldrb r4, [r2, #1]
	lsls r1, r4
	ldr r0, [r0, #0x10]
	ands r0, r1
	cmp r0, #0
	beq .L08066ef0
	ldrh r1, [r2, #4]
	lsls r0, r1, #0x10
	ldrh r4, [r2, #2]
	orrs r0, r4
	adds r0, r2, r0
	b .L08066ef2
L_08066eec:
	.word 0x03006830
.L08066ef0:
	adds r0, r2, #6
.L08066ef2:
	str r0, [r3]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1

@ macro opcode 0x2C REVERB
.global mcmd_REVERB
.thumb_func
.type mcmd_REVERB, %function
mcmd_REVERB:
	push {r4, r5, lr}
	adds r2, r0, #0
	adds r3, r1, #0
	ldr r4, [r3]
	cmp r2, #3
	ble .L08066f36
	ldr r0, L_08066f44
	ldr r1, [r0]
	movs r5, #0x8b
	lsls r5, r5, #1
	adds r0, r1, r5
	ldrb r0, [r0]
	cmp r0, #0
	beq .L08066f36
	adds r0, r1, #0
	adds r0, #0xc8
	ldr r1, [r0]
	lsls r0, r2, #3
	subs r0, r0, r2
	lsls r0, r0, #2
	adds r0, r0, r1
	adds r1, r0, #0
	subs r1, #0x70
	movs r2, #0
	ldrb r0, [r4, #1]
	cmp r0, #0
	bne .L08066f34
	movs r2, #1
.L08066f34:
	strb r2, [r1, #0x1b]
.L08066f36:
	ldr r0, [r3]
	adds r0, #2
	str r0, [r3]
	movs r0, #1
	pop {r4, r5}
	pop {r1}
	bx r1
L_08066f44:
	.word 0x03006830

@ macro opcode 0x2E KEYOFF
.global mcmd_KEYOFF
.thumb_func
.type mcmd_KEYOFF, %function
mcmd_KEYOFF:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	cmp r2, #3
	bgt .L08066f64
	ldr r0, L_08066f60
	lsls r1, r2, #2
	adds r1, #0x18
	ldr r0, [r0]
	adds r1, r0, r1
	b .L08066f72
	.hword 0x0000
L_08066f60:
	.word 0x03006830
.L08066f64:
	ldr r0, L_08066fa4
	ldr r0, [r0]
	adds r0, #0xd0
	lsls r1, r2, #6
	ldr r0, [r0]
	adds r1, r1, r0
	subs r1, #0xc8
.L08066f72:
	ldr r3, [r1]
	movs r0, #1
	ands r0, r3
	cmp r0, #0
	beq .L08066f96
	movs r2, #0x10
	orrs r2, r3
	str r2, [r1]
	movs r3, #6
	adds r0, r2, #0
	ands r0, r3
	cmp r0, #2
	bhi .L08066f96
	movs r0, #7
	rsbs r0, r0, #0
	ands r2, r0
	orrs r2, r3
	str r2, [r1]
.L08066f96:
	ldr r0, [r4]
	adds r0, #2
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
L_08066fa4:
	.word 0x03006830

@ macro opcode 0x32 PORTAFROMLAST
.global mcmd_PORTAFROMLAST
.thumb_func
.type mcmd_PORTAFROMLAST, %function
mcmd_PORTAFROMLAST:
	push {r4, lr}
	adds r2, r0, #0
	adds r4, r1, #0
	ldr r1, [r4]
	movs r3, #2
	ldrsh r0, [r1, r3]
	ldrh r1, [r1, #4]
	bl mod_SetPortaFromLast
	ldr r0, [r4]
	adds r0, #6
	str r0, [r4]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1

@ macro opcode 0x33 ADDLOOPLEN
.global mcmd_ADDLOOPLEN
.thumb_func
.type mcmd_ADDLOOPLEN, %function
mcmd_ADDLOOPLEN:
	push {r4, r5, r6, lr}
	adds r2, r0, #0
	adds r5, r1, #0
	ldr r6, [r5]
	cmp r2, #3
	ble .L08067028
	ldr r0, L_08067038
	ldr r3, [r0]
	adds r0, r3, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_0806703c
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #5
	ands r0, r1
	cmp r0, #0
	beq .L08067028
	adds r0, r3, #0
	adds r0, #0xc8
	lsls r1, r2, #3
	subs r1, r1, r2
	lsls r1, r1, #2
	subs r1, #0x70
	ldr r0, [r0]
	adds r2, r0, r1
	ldr r3, [r2, #0xc]
	cmp r3, #0
	beq .L08067028
	ldr r1, [r2]
	ldr r0, [r1]
	adds r0, #0x10
	adds r4, r1, r0
	movs r0, #2
	ldrsh r1, [r6, r0]
	ldr r0, [r2, #0x10]
	adds r1, r0, r1
	cmp r1, #0
	bge .L0806701e
	movs r1, #0
.L0806701e:
	adds r0, r3, r1
	cmp r0, r4
	bls .L08067026
	subs r1, r4, r3
.L08067026:
	str r1, [r2, #0x10]
.L08067028:
	ldr r0, [r5]
	adds r0, #4
	str r0, [r5]
	movs r0, #1
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000
L_08067038:
	.word 0x03006830
L_0806703c:
	.word 0xffffff00

@ macro opcode 0x34 AGESPEED
.global mcmd_AGESPEED
.thumb_func
.type mcmd_AGESPEED, %function
mcmd_AGESPEED:
	push {r4, lr}
	adds r3, r0, #0
	adds r2, r1, #0
	ldr r4, [r2]
	cmp r3, #3
	ble .L0806705e
	ldr r0, L_0806706c
	ldr r0, [r0]
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r3, #6
	adds r0, r0, r1
	ldrb r1, [r4, #1]
	subs r0, #0xc1
	strb r1, [r0]
.L0806705e:
	ldr r0, [r2]
	adds r0, #2
	str r0, [r2]
	movs r0, #1
	pop {r4}
	pop {r1}
	bx r1
L_0806706c:
	.word 0x03006830

@ macro opcode 0x35 SETLOOPLEN
.global mcmd_SETLOOPLEN
.thumb_func
.type mcmd_SETLOOPLEN, %function
mcmd_SETLOOPLEN:
	push {r4, r5, r6, r7, lr}
	adds r2, r0, #0
	adds r7, r1, #0
	ldr r4, [r7]
	cmp r2, #3
	ble .L080670f2
	ldr r0, L_080670d4
	ldr r3, [r0]
	adds r0, r3, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r2, #6
	adds r0, r0, r1
	ldr r1, L_080670d8
	adds r0, r0, r1
	ldr r0, [r0, #0x38]
	movs r1, #0x80
	lsls r1, r1, #5
	ands r0, r1
	cmp r0, #0
	beq .L080670f2
	ldrh r0, [r4, #4]
	lsls r5, r0, #0x10
	ldrh r4, [r4, #2]
	orrs r5, r4
	adds r1, r3, #0
	adds r1, #0xc8
	lsls r0, r2, #3
	subs r0, r0, r2
	lsls r0, r0, #2
	subs r0, #0x70
	ldr r1, [r1]
	adds r4, r1, r0
	ldr r1, [r4]
	ldr r0, [r1]
	adds r0, #0x10
	adds r6, r1, r0
	bl snd_Lock
	ldr r1, [r4, #0xc]
	cmp r1, #0
	bne .L080670dc
	ldr r0, [r4, #4]
	adds r1, r0, r5
	cmp r1, r6
	bls .L080670ce
	subs r5, r6, r0
.L080670ce:
	adds r1, r0, #0
	b .L080670e6
	.hword 0x0000
L_080670d4:
	.word 0x03006830
L_080670d8:
	.word 0xffffff00
.L080670dc:
	adds r0, r1, r5
	cmp r0, r6
	bls .L080670e4
	subs r5, r6, r1
.L080670e4:
	ldr r0, [r4, #4]
.L080670e6:
	adds r0, r0, r5
	str r0, [r4, #8]
	str r5, [r4, #0x10]
	str r1, [r4, #0xc]
	bl snd_Unlock
.L080670f2:
	ldr r0, [r7]
	adds r0, #6
	str r0, [r7]
	movs r0, #1
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global seq_UpdateTempo
.thumb_func
.type seq_UpdateTempo, %function
seq_UpdateTempo:
	push {r4, r5, r6, r7, lr}
	ldr r0, L_08067164
	ldr r4, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r4, r1
	ldr r7, [r0]
	movs r2, #0xa5
	lsls r2, r2, #1
	adds r6, r7, r2
	ldrh r0, [r6]
	lsls r1, r0, #8
	lsls r0, r0, #9
	adds r0, r0, r1
	lsls r0, r0, #5
	movs r1, #0xe1
	lsls r1, r1, #4
	bl __udivsi3
	movs r1, #0xa4
	lsls r1, r1, #1
	adds r5, r7, r1
	ldrh r2, [r5]
	muls r0, r2, r0
	lsrs r0, r0, #0xc
	movs r2, #0xa6
	lsls r2, r2, #1
	adds r1, r7, r2
	strh r0, [r1]
	ldrh r1, [r6]
	lsls r0, r1, #1
	adds r0, r0, r1
	lsls r0, r0, #0x11
	ldrh r2, [r4, #0xa]
	lsls r1, r2, #2
	adds r1, r1, r2
	bl __udivsi3
	lsls r0, r0, #0xc
	ldrh r1, [r5]
	bl __udivsi3
	movs r2, #0xa7
	lsls r2, r2, #1
	adds r1, r7, r2
	strh r0, [r1]
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08067164:
	.word 0x03006830

.global sndSeqLoad
.thumb_func
.type sndSeqLoad, %function
sndSeqLoad:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	adds r4, r0, #0
	ldr r2, L_08067260
	ldr r3, [r2]
	movs r1, #0x8c
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r0, [r0]
	ldr r1, [r0, #0x18]
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, r4
	bhi .L0806718c
	b .L08067314
.L0806718c:
	movs r2, #0x90
	lsls r2, r2, #1
	adds r0, r3, r2
	ldr r7, [r0]
	ldr r3, L_08067264
	adds r1, r7, r3
	movs r0, #0
	strb r0, [r1]
	movs r0, #0x8a
	lsls r0, r0, #1
	adds r3, r7, r0
	ldr r1, L_08067260
	ldr r0, [r1]
	subs r2, #8
	adds r0, r0, r2
	ldr r2, [r0]
	ldr r0, [r2, #0x18]
	lsls r1, r4, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1, #4]
	adds r2, r2, r0
	mov r8, r2
	str r2, [r3]
	movs r3, #0x8c
	lsls r3, r3, #1
	adds r1, r7, r3
	movs r4, #3
.L080671c4:
	ldm r2!, {r0}
	stm r1!, {r0}
	subs r4, #1
	cmp r4, #0
	bge .L080671c4
	movs r4, #0xa4
	lsls r4, r4, #1
	adds r1, r7, r4
	movs r0, #0x80
	lsls r0, r0, #5
	strh r0, [r1]
	movs r4, #0x83
	lsls r4, r4, #3
	add r4, r8
	ldrh r0, [r4]
	movs r2, #0xa5
	lsls r2, r2, #1
	adds r1, r7, r2
	strh r0, [r1]
	ldrh r0, [r4]
	lsls r1, r0, #8
	lsls r0, r0, #9
	adds r0, r0, r1
	lsls r0, r0, #5
	movs r1, #0xe1
	lsls r1, r1, #4
	bl __udivsi3
	movs r3, #0xa6
	lsls r3, r3, #1
	adds r1, r7, r3
	strh r0, [r1]
	ldrh r1, [r4]
	lsls r0, r1, #1
	adds r0, r0, r1
	lsls r0, r0, #0x11
	ldr r3, L_08067260
	ldr r2, [r3]
	ldrh r4, [r2, #0xa]
	lsls r1, r4, #2
	adds r1, r1, r4
	bl __udivsi3
	movs r2, #0xa7
	lsls r2, r2, #1
	adds r1, r7, r2
	strh r0, [r1]
	movs r1, #0x82
	lsls r1, r1, #3
	mov r3, r8
	adds r0, r3, r1
	ldr r0, [r0]
	adds r0, r0, r1
	movs r4, #0x88
	adds r4, r4, r7
	mov r10, r4
	movs r2, #0x8c
	adds r2, r2, r7
	mov r9, r2
	movs r3, #0
	mov r12, r3
	movs r6, #0
	adds r3, r7, #4
	adds r2, r7, #0
	mov r4, r8
	adds r5, r4, r0
	movs r4, #0x10
.L0806724a:
	ldr r0, [r5]
	cmp r0, #0
	beq .L08067268
	movs r1, #0x82
	lsls r1, r1, #3
	adds r0, r0, r1
	add r0, r8
	str r0, [r2]
	ldr r0, [r0]
	lsls r0, r0, #8
	b .L0806726a
L_08067260:
	.word 0x03006830
L_08067264:
	.word 0x00000151
.L08067268:
	str r0, [r2]
.L0806726a:
	str r0, [r3]
	mov r1, r10
	adds r0, r1, r6
	mov r1, r12
	str r1, [r0]
	mov r1, r9
	adds r0, r1, r6
	mov r1, r12
	str r1, [r0]
	adds r6, #8
	adds r3, #8
	adds r2, #8
	adds r5, #4
	subs r4, #1
	cmp r4, #0
	bge .L0806724a
	movs r2, #0xff
	movs r3, #0x94
	lsls r3, r3, #1
	adds r1, r7, r3
	movs r4, #0xf
.L08067294:
	ldrb r0, [r1, #0x10]
	orrs r0, r2
	strb r0, [r1, #0x10]
	ldrb r0, [r1]
	orrs r0, r2
	strb r0, [r1]
	adds r1, #1
	subs r4, #1
	cmp r4, #0
	bge .L08067294
	movs r4, #0
	ldr r6, L_0806730c
	ldr r0, [r6]
	ldrb r0, [r0, #8]
	cmp r4, r0
	bge .L080672f0
	movs r0, #0x88
	lsls r0, r0, #1
	adds r2, r7, r0
	movs r5, #0
	movs r3, #0
.L080672be:
	ldr r0, [r2]
	adds r0, r3, r0
	strb r5, [r0, #4]
	ldr r0, [r2]
	adds r0, r3, r0
	strb r5, [r0, #6]
	ldr r0, [r2]
	adds r0, r3, r0
	strb r5, [r0, #8]
	ldr r0, [r2]
	adds r0, r3, r0
	str r5, [r0]
	ldr r0, [r2]
	adds r0, r3, r0
	strb r5, [r0, #7]
	ldr r0, [r2]
	adds r0, r3, r0
	movs r1, #0xff
	strb r1, [r0, #5]
	adds r3, #0xc
	adds r4, #1
	ldr r0, [r6]
	ldrb r0, [r0, #8]
	cmp r4, r0
	blt .L080672be
.L080672f0:
	movs r1, #0xa8
	lsls r1, r1, #1
	adds r0, r7, r1
	movs r1, #0
	strb r1, [r0]
	ldr r2, L_0806730c
	ldr r0, [r2]
	strb r1, [r0, #9]
	ldr r3, L_08067310
	adds r1, r7, r3
	movs r0, #1
	strb r0, [r1]
	b .L08067316
	.hword 0x0000
L_0806730c:
	.word 0x03006830
L_08067310:
	.word 0x00000151
.L08067314:
	movs r0, #0
.L08067316:
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndSeqStop
.thumb_func
.type sndSeqStop, %function
sndSeqStop:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	mov r8, r0
	ldr r0, L_08067384
	ldr r1, [r0]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r1, r1, r2
	ldr r5, [r1]
	ldr r1, L_08067388
	adds r3, r5, r1
	ldrb r2, [r3]
	movs r1, #3
	ands r1, r2
	mov r12, r0
	cmp r1, #3
	bne .L080673d0
	movs r0, #0xfc
	ands r0, r2
	strb r0, [r3]
	mov r2, r8
	cmp r2, #0
	beq .L080673be
	movs r4, #0
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	bge .L080673be
	movs r2, #0x88
	lsls r2, r2, #1
	adds r6, r5, r2
	movs r5, #0
	movs r7, #0
.L0806736c:
	ldr r0, [r6]
	adds r0, r5, r0
	ldrb r0, [r0, #4]
	cmp r0, #0
	beq .L080673ae
	mov r0, r8
	cmp r0, #1
	bne .L0806738c
	adds r0, r4, #0
	bl voice_KeyOff
	b .L080673a4
L_08067384:
	.word 0x03006830
L_08067388:
	.word 0x00000151
.L0806738c:
	ldr r0, L_080673cc
	ldr r0, [r0]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r4, #4
	adds r0, r0, r1
	str r7, [r0]
	adds r0, r4, #0
	bl voice_Silence
.L080673a4:
	ldr r0, [r6]
	adds r0, r5, r0
	strb r7, [r0, #4]
	ldr r2, L_080673cc
	mov r12, r2
.L080673ae:
	adds r5, #0xc
	adds r4, #1
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	blt .L0806736c
.L080673be:
	mov r2, r12
	ldr r1, [r2]
	movs r0, #0
	strb r0, [r1, #9]
	movs r0, #1
	b .L080673d2
	.hword 0x0000
L_080673cc:
	.word 0x03006830
.L080673d0:
	movs r0, #0
.L080673d2:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndSeqPause
.thumb_func
.type sndSeqPause, %function
sndSeqPause:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	mov r8, r0
	ldr r0, L_08067440
	ldr r1, [r0]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r1, r1, r2
	ldr r5, [r1]
	ldr r1, L_08067444
	adds r3, r5, r1
	ldrb r2, [r3]
	movs r1, #7
	ands r1, r2
	mov r12, r0
	cmp r1, #3
	bne .L08067484
	movs r0, #0xfd
	ands r0, r2
	movs r1, #4
	orrs r0, r1
	strb r0, [r3]
	mov r2, r8
	cmp r2, #0
	beq .L0806747a
	movs r4, #0
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	bge .L0806747a
	movs r2, #0x88
	lsls r2, r2, #1
	adds r6, r5, r2
	movs r5, #0
	movs r7, #0
.L08067428:
	ldr r0, [r6]
	adds r0, r5, r0
	ldrb r0, [r0, #4]
	cmp r0, #0
	beq .L0806746a
	mov r0, r8
	cmp r0, #1
	bne .L08067448
	adds r0, r4, #0
	bl voice_KeyOff
	b .L08067460
L_08067440:
	.word 0x03006830
L_08067444:
	.word 0x00000151
.L08067448:
	ldr r0, L_08067480
	ldr r0, [r0]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r1, [r0]
	lsls r0, r4, #4
	adds r0, r0, r1
	str r7, [r0]
	adds r0, r4, #0
	bl voice_Silence
.L08067460:
	ldr r0, [r6]
	adds r0, r5, r0
	strb r7, [r0, #4]
	ldr r2, L_08067480
	mov r12, r2
.L0806746a:
	adds r5, #0xc
	adds r4, #1
	mov r1, r12
	ldr r0, [r1]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r4, r0
	blt .L08067428
.L0806747a:
	movs r0, #1
	b .L08067486
	.hword 0x0000
L_08067480:
	.word 0x03006830
.L08067484:
	movs r0, #0
.L08067486:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndSeqIsActive
.thumb_func
.type sndSeqIsActive, %function
sndSeqIsActive:
	push {r4, r5, r6, r7, lr}
	ldr r0, L_08067514
	ldr r1, [r0]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r1, r1, r2
	ldr r4, [r1]
	ldr r1, L_08067518
	adds r2, r4, r1
	movs r1, #2
	ldrb r2, [r2]
	ands r1, r2
	adds r5, r0, #0
	cmp r1, #0
	beq .L080674cc
	movs r3, #0
	adds r2, r4, #0
	adds r2, #0x88
	adds r1, r4, #0
.L080674b6:
	ldr r0, [r1]
	cmp r0, #0
	bne .L08067530
	ldr r0, [r2]
	cmp r0, #0
	bne .L08067530
	adds r2, #8
	adds r1, #8
	adds r3, #1
	cmp r3, #0xf
	ble .L080674b6
.L080674cc:
	movs r3, #0
	ldr r0, [r5]
	ldrb r1, [r0, #8]
	adds r1, #4
	cmp r3, r1
	bge .L08067540
	movs r2, #0x88
	lsls r2, r2, #1
	adds r0, r4, r2
	adds r7, r5, #0
	adds r6, r1, #0
	ldr r5, [r0]
.L080674e4:
	lsls r4, r3, #1
	ldrb r0, [r5, #4]
	cmp r0, #0
	bne .L08067530
	ldr r2, [r7]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r2, r1
	ldr r1, [r0]
	lsls r0, r3, #4
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, #0
	beq .L08067538
	cmp r3, #3
	bgt .L0806751c
	adds r0, r2, #0
	adds r0, #0xb4
	adds r0, r0, r4
	ldrh r0, [r0]
	cmp r0, #0xff
	ble .L08067530
	b .L08067538
	.hword 0x0000
L_08067514:
	.word 0x03006830
L_08067518:
	.word 0x00000151
.L0806751c:
	adds r0, r2, #0
	adds r0, #0xd0
	ldr r1, [r0]
	lsls r0, r3, #6
	adds r0, r0, r1
	ldr r2, L_08067534
	adds r0, r0, r2
	ldrh r0, [r0, #0x34]
	cmp r0, #0xff
	bgt .L08067538
.L08067530:
	movs r0, #1
	b .L08067542
L_08067534:
	.word 0xffffff00
.L08067538:
	adds r5, #0xc
	adds r3, #1
	cmp r3, r6
	blt .L080674e4
.L08067540:
	movs r0, #0
.L08067542:
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndSeqSaveState
.thumb_func
.type sndSeqSaveState, %function
sndSeqSaveState:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r6, r0, #0
	movs r1, #3
	ands r0, r1
	cmp r0, #0
	bne .L08067624
	ldr r0, L_0806761c
	mov r8, r0
	ldr r0, [r0]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r0, r0, r2
	ldr r5, [r0]
	ldr r3, L_08067620
	adds r7, r5, r3
	adds r0, r1, #0
	ldrb r4, [r7]
	ands r0, r4
	cmp r0, #1
	bne .L08067624
	adds r0, r6, #0
	adds r1, r5, #0
	movs r2, #0x88
	bl snd_memcpy
	adds r0, r6, #0
	adds r0, #0x88
	adds r1, r5, #0
	adds r1, #0x88
	movs r2, #0x88
	bl snd_memcpy
	movs r4, #0x8a
	lsls r4, r4, #1
	adds r0, r6, r4
	movs r2, #0x8c
	lsls r2, r2, #1
	adds r1, r5, r2
	movs r2, #0x10
	bl snd_memcpy
	movs r3, #0x92
	lsls r3, r3, #1
	adds r0, r6, r3
	movs r2, #0x94
	lsls r2, r2, #1
	adds r1, r5, r2
	movs r2, #0x10
	bl snd_memcpy
	movs r3, #0x9a
	lsls r3, r3, #1
	adds r0, r6, r3
	movs r2, #0x9c
	lsls r2, r2, #1
	adds r1, r5, r2
	movs r2, #0x10
	bl snd_memcpy
	movs r3, #0x88
	lsls r3, r3, #1
	adds r1, r6, r3
	adds r4, r5, r4
	ldr r0, [r4]
	str r0, [r1]
	movs r2, #0xa4
	lsls r2, r2, #1
	adds r0, r5, r2
	ldrh r1, [r0]
	movs r4, #0xa2
	lsls r4, r4, #1
	adds r0, r6, r4
	strh r1, [r0]
	movs r1, #0xa5
	lsls r1, r1, #1
	adds r0, r5, r1
	ldrh r0, [r0]
	adds r4, #2
	adds r3, r6, r4
	strh r0, [r3]
	movs r3, #0xa6
	lsls r3, r3, #1
	adds r0, r5, r3
	ldrh r0, [r0]
	adds r2, r6, r2
	strh r0, [r2]
	movs r2, #0xa7
	lsls r2, r2, #1
	adds r0, r5, r2
	ldrh r0, [r0]
	adds r1, r6, r1
	strh r0, [r1]
	mov r4, r8
	ldr r0, [r4]
	ldrb r0, [r0, #9]
	subs r2, #1
	adds r1, r6, r2
	strb r0, [r1]
	ldrb r0, [r7]
	adds r3, r6, r3
	strb r0, [r3]
	movs r0, #1
	b .L08067626
	.hword 0x0000
L_0806761c:
	.word 0x03006830
L_08067620:
	.word 0x00000151
.L08067624:
	movs r0, #0
.L08067626:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global sndSeqRestoreState
.thumb_func
.type sndSeqRestoreState, %function
sndSeqRestoreState:
	push {r4, r5, r6, r7, lr}
	mov r7, r8
	push {r7}
	adds r6, r0, #0
	movs r0, #3
	ands r0, r6
	cmp r0, #0
	bne .L08067708
	ldr r0, L_08067700
	mov r8, r0
	ldr r0, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r5, [r0]
	ldr r2, L_08067704
	adds r7, r5, r2
	movs r0, #2
	ldrb r3, [r7]
	ands r0, r3
	cmp r0, #0
	bne .L08067708
	adds r0, r5, #0
	adds r1, r6, #0
	movs r2, #0x88
	bl snd_memcpy
	adds r0, r5, #0
	adds r0, #0x88
	adds r1, r6, #0
	adds r1, #0x88
	movs r2, #0x88
	bl snd_memcpy
	movs r1, #0x8c
	lsls r1, r1, #1
	adds r0, r5, r1
	movs r4, #0x8a
	lsls r4, r4, #1
	adds r1, r6, r4
	movs r2, #0x10
	bl snd_memcpy
	movs r2, #0x94
	lsls r2, r2, #1
	adds r0, r5, r2
	movs r3, #0x92
	lsls r3, r3, #1
	adds r1, r6, r3
	movs r2, #0x10
	bl snd_memcpy
	movs r1, #0x9c
	lsls r1, r1, #1
	adds r0, r5, r1
	movs r2, #0x9a
	lsls r2, r2, #1
	adds r1, r6, r2
	movs r2, #0x10
	bl snd_memcpy
	adds r4, r5, r4
	movs r3, #0x88
	lsls r3, r3, #1
	adds r0, r6, r3
	ldr r0, [r0]
	str r0, [r4]
	movs r1, #0xa2
	lsls r1, r1, #1
	adds r0, r6, r1
	ldrh r2, [r0]
	adds r1, #4
	adds r0, r5, r1
	strh r2, [r0]
	movs r2, #0xa3
	lsls r2, r2, #1
	adds r0, r6, r2
	ldrh r3, [r0]
	adds r2, #4
	adds r0, r5, r2
	strh r3, [r0]
	adds r1, r6, r1
	ldrh r3, [r1]
	movs r1, #0xa6
	lsls r1, r1, #1
	adds r0, r5, r1
	strh r3, [r0]
	adds r2, r6, r2
	ldrh r0, [r2]
	movs r3, #0xa7
	lsls r3, r3, #1
	adds r2, r5, r3
	strh r0, [r2]
	mov r0, r8
	ldr r2, [r0]
	subs r3, #1
	adds r0, r6, r3
	ldrb r0, [r0]
	strb r0, [r2, #9]
	adds r1, r6, r1
	ldrb r0, [r1]
	strb r0, [r7]
	movs r0, #1
	b .L0806770a
L_08067700:
	.word 0x03006830
L_08067704:
	.word 0x00000151
.L08067708:
	movs r0, #0
.L0806770a:
	pop {r3}
	mov r8, r3
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global seq_NoteOn
.thumb_func
.type seq_NoteOn, %function
seq_NoteOn:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #8
	mov r9, r0
	mov r10, r1
	mov r8, r2
	str r3, [sp, #4]
	movs r2, #0x9c
	lsls r2, r2, #1
	add r2, r9
	add r2, r10
	movs r0, #0x94
	lsls r0, r0, #1
	add r0, r9
	add r0, r10
	ldrb r1, [r0]
	strb r1, [r2]
	mov r1, sp
	ldrb r1, [r1, #4]
	strb r1, [r0]
	movs r0, #0x8c
	lsls r0, r0, #1
	add r0, r9
	add r0, r10
	ldrb r1, [r0]
	mov r2, r10
	cmp r2, #9
	beq .L0806775e
	movs r0, #0x8a
	lsls r0, r0, #1
	add r0, r9
	lsls r1, r1, #2
	adds r1, #0x10
	b .L0806776c
.L0806775e:
	movs r0, #0x8a
	lsls r0, r0, #1
	add r0, r9
	lsls r1, r1, #2
	movs r3, #0x84
	lsls r3, r3, #2
	adds r1, r1, r3
.L0806776c:
	ldr r0, [r0]
	adds r6, r0, r1
	ldr r0, L_080677f0
	ldr r3, [r0]
	movs r4, #0x8c
	lsls r4, r4, #1
	adds r0, r3, r4
	ldr r2, [r0]
	ldr r0, [r2]
	ldrh r4, [r6]
	lsls r1, r4, #2
	adds r0, r2, r0
	adds r1, r1, r0
	ldr r0, [r1]
	adds r7, r2, r0
	ldrh r1, [r3, #0x14]
	mov r0, r8
	muls r0, r1, r0
	asrs r0, r0, #8
	mov r8, r0
	mov r2, r10
	cmp r2, #3
	bgt .L08067802
	mov r4, r10
	ldrb r3, [r7]
	cmp r3, #3
	bhi .L080677a4
	ldrb r4, [r7]
.L080677a4:
	movs r2, #1
	adds r0, r2, #0
	ldrb r1, [r7, #1]
	ands r0, r1
	cmp r0, #0
	beq .L080677c4
	cmp r4, #1
	bgt .L080677c4
	movs r0, #0xa8
	lsls r0, r0, #1
	add r0, r9
	ldrb r1, [r0]
	adds r4, r4, r1
	ands r4, r2
	eors r1, r2
	strb r1, [r0]
.L080677c4:
	ldrb r1, [r6, #2]
	movs r0, #0
	adds r2, r4, #0
	bl psg_VoiceAvail
	cmp r0, #0
	bne .L080677d4
	b .L080678e4
.L080677d4:
	movs r0, #0x80
	ldrb r2, [r7, #1]
	ands r0, r2
	cmp r0, #0
	bne .L080677f4
	ldrb r0, [r6, #2]
	str r0, [sp]
	adds r0, r4, #0
	ldr r1, [sp, #4]
	movs r2, #0x40
	mov r3, r8
	bl psg_VoiceStart
	b .L0806788c
L_080677f0:
	.word 0x03006830
.L080677f4:
	ldrb r3, [r6, #2]
	adds r0, r4, #0
	ldr r1, [sp, #4]
	mov r2, r8
	bl psg_VoiceLegato
	b .L0806788c
.L08067802:
	ldrb r4, [r7]
	cmp r4, #0xff
	beq .L08067816
	subs r4, #4
	cmp r4, #0
	blt .L08067814
	ldrb r3, [r3, #8]
	cmp r4, r3
	blt .L08067816
.L08067814:
	movs r4, #0xff
.L08067816:
	ldrb r1, [r6, #2]
	ldrb r2, [r6, #3]
	movs r0, #0
	adds r3, r4, #0
	bl ds_VoiceAlloc
	adds r4, r0, #0
	cmp r4, #0
	blt .L080678e4
	ldr r0, L_08067864
	ldr r3, [r0]
	adds r0, r3, #0
	adds r0, #0xd0
	lsls r1, r4, #6
	ldr r0, [r0]
	adds r5, r0, r1
	movs r0, #0x80
	ldrb r1, [r7, #1]
	ands r0, r1
	lsls r0, r0, #0x18
	lsrs r2, r0, #0x18
	cmp r2, #0
	bne .L08067868
	adds r0, r3, #0
	adds r0, #0xcc
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	str r2, [r0]
	ldrb r0, [r6, #2]
	str r0, [sp]
	adds r0, r5, #0
	ldr r1, [sp, #4]
	movs r2, #0x40
	mov r3, r8
	bl ds_VoiceStart
	b .L08067874
	.hword 0x0000
L_08067864:
	.word 0x03006830
.L08067868:
	ldrb r3, [r6, #2]
	adds r0, r5, #0
	ldr r1, [sp, #4]
	mov r2, r8
	bl ds_VoiceLegato
.L08067874:
	ldr r0, L_080678f4
	ldr r0, [r0]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	str r5, [r0]
	adds r4, #4
	adds r1, r5, #0
	adds r1, #0x3d
	movs r0, #1
	strb r0, [r1]
.L0806788c:
	movs r1, #0x88
	lsls r1, r1, #1
	add r1, r9
	lsls r0, r4, #1
	adds r0, r0, r4
	lsls r0, r0, #2
	ldr r1, [r1]
	adds r1, r1, r0
	ldr r0, [sp, #0x28]
	lsls r0, r0, #8
	str r0, [r1]
	movs r2, #0
	mov r3, r10
	strb r3, [r1, #5]
	movs r0, #1
	strb r0, [r1, #4]
	mov r0, r8
	strb r0, [r1, #6]
	strb r0, [r1, #8]
	mov r3, sp
	ldrb r3, [r3, #4]
	strb r3, [r1, #7]
	ldr r0, L_080678f4
	ldr r3, [r0]
	movs r1, #0x8e
	lsls r1, r1, #1
	adds r0, r3, r1
	lsls r1, r4, #4
	ldr r0, [r0]
	adds r0, r0, r1
	strh r2, [r0, #8]
	strh r2, [r0, #0xa]
	str r2, [r0, #4]
	adds r1, r7, #4
	str r1, [r0]
	ldrh r1, [r6]
	strh r1, [r0, #0xc]
	movs r1, #0x94
	lsls r1, r1, #1
	adds r0, r3, r1
	ldr r1, [r0]
	lsls r0, r4, #2
	adds r0, r0, r1
	str r2, [r0]
.L080678e4:
	add sp, #8
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
L_080678f4:
	.word 0x03006830

.global seq_Handle
.thumb_func
.type seq_Handle, %function
seq_Handle:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #4
	ldr r1, L_08067998
	ldr r3, [r1]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r0, r3, r2
	ldr r6, [r0]
	ldr r0, L_0806799c
	adds r2, r6, r0
	movs r0, #2
	ldrb r2, [r2]
	ands r0, r2
	cmp r0, #0
	bne .L08067920
	b .L08067bca
.L08067920:
	movs r1, #0xa6
	lsls r1, r1, #1
	adds r0, r6, r1
	ldrh r0, [r0]
	mov r10, r0
	movs r7, #0
	ldrb r0, [r3, #8]
	adds r0, #4
	cmp r7, r0
	bge .L08067970
	movs r2, #0x88
	lsls r2, r2, #1
	adds r2, r2, r6
	mov r8, r2
	movs r5, #0
.L0806793e:
	mov r3, r8
	ldr r0, [r3]
	adds r4, r0, r5
	ldrb r0, [r4, #4]
	cmp r0, #0
	beq .L08067960
	ldr r0, [r4]
	mov r1, r10
	subs r0, r0, r1
	str r0, [r4]
	cmp r0, #0
	bgt .L08067960
	adds r0, r7, #0
	bl voice_KeyOff
	movs r0, #0
	strb r0, [r4, #4]
.L08067960:
	adds r5, #0xc
	adds r7, #1
	ldr r0, L_08067998
	ldr r0, [r0]
	ldrb r0, [r0, #8]
	adds r0, #4
	cmp r7, r0
	blt .L0806793e
.L08067970:
	movs r7, #0
	movs r2, #0
	mov r9, r2
	movs r3, #0x82
	lsls r3, r3, #3
	mov r12, r3
	adds r4, r6, #0
	mov r8, r2
.L08067980:
	ldr r1, [r4]
	cmp r1, #0
	beq .L08067a78
	ldr r0, [r4, #4]
	mov r2, r10
	subs r0, r0, r2
	str r0, [r4, #4]
	cmp r0, #0
	bgt .L08067a78
	ldr r1, [r1, #4]
	b .L08067a6c
	.hword 0x0000
L_08067998:
	.word 0x03006830
L_0806799c:
	.word 0x00000151
.L080679a0:
	ldr r2, [r4]
	ldr r1, [r2, #4]
	movs r0, #2
	rsbs r0, r0, #0
	adds r5, r2, #0
	cmp r1, r0
	bne .L080679ec
	adds r3, r5, #0
	adds r3, #8
	str r3, [r4]
	ldr r1, L_080679e8
	ldr r0, [r1]
	movs r2, #0x90
	lsls r2, r2, #1
	adds r0, r0, r2
	ldr r0, [r0]
	movs r1, #0x8a
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r2, [r0]
	mov r1, r12
	adds r0, r2, r1
	ldr r0, [r0]
	add r0, r12
	adds r0, r2, r0
	lsls r1, r7, #2
	adds r1, r1, r0
	ldr r0, [r1]
	add r0, r12
	adds r2, r2, r0
	ldr r0, [r5, #8]
	adds r2, r2, r0
	str r2, [r4]
	ldr r1, [r3, #4]
	b .L08067a5a
	.hword 0x0000
L_080679e8:
	.word 0x03006830
.L080679ec:
	movs r2, #0x8a
	lsls r2, r2, #1
	adds r0, r6, r2
	ldr r2, [r0]
	ldr r3, L_08067a24
	adds r0, r2, r3
	ldr r0, [r0]
	subs r3, #4
	adds r0, r0, r3
	adds r0, r2, r0
	lsls r1, r1, #2
	adds r1, r1, r0
	ldr r0, [r1]
	adds r0, r0, r3
	adds r1, r2, r0
	ldrh r0, [r1]
	ldr r2, L_08067a28
	cmp r0, r2
	bne .L08067a2c
	ldrh r3, [r1, #2]
	cmp r3, r0
	bne .L08067a2c
	adds r0, r6, #0
	adds r0, #0x88
	add r0, r8
	mov r1, r9
	str r1, [r0]
	b .L08067a52
L_08067a24:
	.word 0x00000414
L_08067a28:
	.word 0x0000ffff
.L08067a2c:
	adds r0, r6, #0
	adds r0, #0x88
	add r0, r8
	str r1, [r0]
	adds r0, r6, #0
	adds r0, #0x8c
	mov r2, r8
	adds r3, r0, r2
	ldrh r1, [r1]
	lsls r1, r1, #8
	str r1, [r3]
	cmp r7, #3
	bgt .L08067a52
	movs r2, #0xa7
	lsls r2, r2, #1
	adds r0, r6, r2
	ldrh r0, [r0]
	adds r0, r0, r1
	str r0, [r3]
.L08067a52:
	adds r0, r5, #0
	adds r0, #8
	str r0, [r4]
	ldr r1, [r5, #8]
.L08067a5a:
	lsls r1, r1, #8
	ldr r0, [r4, #4]
	adds r0, r0, r1
	str r0, [r4, #4]
	ldr r0, [r4, #4]
	cmp r0, #0
	bgt .L08067a78
	ldr r0, [r4]
	ldr r1, [r0, #4]
.L08067a6c:
	movs r0, #1
	rsbs r0, r0, #0
	cmp r1, r0
	bne .L080679a0
	mov r3, r9
	str r3, [r4]
.L08067a78:
	adds r4, #8
	movs r0, #8
	add r8, r0
	adds r7, #1
	cmp r7, #0x10
	bgt .L08067a86
	b .L08067980
.L08067a86:
	movs r7, #0
.L08067a88:
	lsls r0, r7, #3
	adds r0, #0x88
	adds r5, r6, r0
	ldr r1, [r5]
	adds r2, r7, #1
	mov r9, r2
	cmp r1, #0
	beq .L08067b6a
	ldr r0, [r5, #4]
	mov r3, r10
	subs r0, r0, r3
	str r0, [r5, #4]
	adds r4, r1, #0
	cmp r0, #0
	bgt .L08067b6a
	movs r1, #0x8c
	lsls r1, r1, #1
	adds r0, r6, r1
	adds r0, r0, r7
	mov r8, r0
.L08067ab0:
	movs r0, #2
	ldrsb r0, [r4, r0]
	cmp r0, #0
	ble .L08067b02
	movs r0, #0x80
	ldrb r2, [r4, #3]
	ands r0, r2
	cmp r0, #0
	bne .L08067adc
	ldrh r0, [r4, #4]
	cmp r0, #0
	beq .L08067ad8
	movs r2, #2
	ldrsb r2, [r4, r2]
	ldrb r3, [r4, #3]
	str r0, [sp]
	adds r0, r6, #0
	adds r1, r7, #0
	bl seq_NoteOn
.L08067ad8:
	movs r1, #6
	b .L08067b3a
.L08067adc:
	ldrb r0, [r4, #4]
	mov r3, r8
	strb r0, [r3]
	ldrh r0, [r4, #4]
	cmp r0, #0
	beq .L08067afe
	movs r2, #2
	ldrsb r2, [r4, r2]
	movs r3, #0x7f
	ldrb r0, [r4, #3]
	ands r3, r0
	ldrh r0, [r4, #6]
	str r0, [sp]
	adds r0, r6, #0
	adds r1, r7, #0
	bl seq_NoteOn
.L08067afe:
	movs r1, #8
	b .L08067b3a
.L08067b02:
	cmp r0, #0
	bne .L08067b34
	ldrb r1, [r4, #3]
	movs r0, #0x80
	ands r0, r1
	cmp r0, #0
	bne .L08067b18
	mov r2, r8
	strb r1, [r2]
	movs r1, #4
	b .L08067b3a
.L08067b18:
	movs r2, #0x7f
	ands r2, r1
	ldr r0, L_08067b30
	ldr r0, [r0]
	ldrb r1, [r0, #8]
	cmp r2, r1
	ble .L08067b28
	adds r2, r1, #0
.L08067b28:
	strb r2, [r0, #9]
	movs r1, #4
	b .L08067b3a
	.hword 0x0000
L_08067b30:
	.word 0x03006830
.L08067b34:
	movs r0, #0
	str r0, [r5]
	b .L08067b6a
.L08067b3a:
	ldr r0, [r5]
	adds r0, r0, r1
	str r0, [r5]
	adds r4, r0, #0
	ldrh r1, [r4]
	ldr r0, L_08067b58
	cmp r1, r0
	bne .L08067b5c
	ldrh r3, [r4, #2]
	cmp r3, r1
	bne .L08067b5c
	movs r0, #0
	str r0, [r5, #4]
	str r0, [r5]
	b .L08067b6a
L_08067b58:
	.word 0x0000ffff
.L08067b5c:
	ldrh r0, [r4]
	lsls r1, r0, #8
	ldr r0, [r5, #4]
	adds r0, r0, r1
	str r0, [r5, #4]
	cmp r0, #0
	ble .L08067ab0
.L08067b6a:
	mov r7, r9
	cmp r7, #0xf
	ble .L08067a88
	movs r1, #0x84
	lsls r1, r1, #1
	adds r5, r6, r1
	ldr r1, [r5]
	cmp r1, #0
	beq .L08067bca
	ldr r0, [r5, #4]
	mov r2, r10
	subs r0, r0, r2
	str r0, [r5, #4]
	adds r2, r1, #0
	cmp r0, #0
	bgt .L08067bca
	movs r4, #0
	ldr r7, L_08067bb8
.L08067b8e:
	ldrh r0, [r2, #2]
	movs r3, #0xa5
	lsls r3, r3, #1
	adds r1, r6, r3
	strh r0, [r1]
	bl seq_UpdateTempo
	ldr r1, [r5]
	adds r0, r1, #4
	str r0, [r5]
	adds r2, r0, #0
	ldrh r0, [r2, #2]
	cmp r0, r7
	bne .L08067bbc
	ldrh r1, [r1, #4]
	cmp r1, r0
	bne .L08067bbc
	str r4, [r5, #4]
	str r4, [r5]
	b .L08067bca
	.hword 0x0000
L_08067bb8:
	.word 0x0000ffff
.L08067bbc:
	ldrh r0, [r2]
	lsls r1, r0, #8
	ldr r0, [r5, #4]
	adds r0, r0, r1
	str r0, [r5, #4]
	cmp r0, #0
	ble .L08067b8e
.L08067bca:
	add sp, #4
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000

.global ds_VoiceStart
.thumb_func
.type ds_VoiceStart, %function
ds_VoiceStart:
	push {r4, r5, lr}
	mov r12, r0
	adds r5, r1, #0
	adds r4, r2, #0
	adds r0, #0x3d
	movs r2, #0
	strb r2, [r0]
	movs r0, #0xff
	lsls r0, r0, #8
	mov r1, r12
	strh r0, [r1, #0x28]
	movs r0, #0xc0
	lsls r0, r0, #8
	strh r0, [r1, #0x36]
	adds r1, #0x3f
	movs r0, #1
	strb r0, [r1]
	lsls r3, r3, #1
	subs r1, #0x14
	strb r3, [r1]
	lsls r0, r3, #0x18
	cmp r0, #0
	beq .L08067c0e
	adds r0, r3, #1
	strb r0, [r1]
.L08067c0e:
	mov r3, r12
	adds r3, #0x2a
	movs r0, #0
	strb r0, [r3]
	mov r3, r12
	str r2, [r3, #0x38]
	mov r0, r12
	adds r0, #0x3c
	strb r4, [r0]
	ldr r0, [sp, #0xc]
	strh r0, [r3, #0x34]
	ldrh r4, [r3]
	ldrh r1, [r3, #0x1c]
	adds r0, r4, r1
	strh r0, [r3, #0x22]
	lsls r0, r5, #8
	strh r0, [r3]
	strh r2, [r3, #2]
	strh r2, [r3, #0x1c]
	strh r2, [r3, #0x1e]
	strh r2, [r3, #0x20]
	strh r2, [r3, #0x14]
	strh r2, [r3, #0x16]
	strh r2, [r3, #4]
	strh r2, [r3, #6]
	strh r2, [r3, #0xc]
	strh r2, [r3, #0xe]
	strh r2, [r3, #0x12]
	pop {r4, r5}
	pop {r0}
	bx r0

.global psg_VoiceStart
.thumb_func
.type psg_VoiceStart, %function
psg_VoiceStart:
	push {r4, r5, r6, r7, lr}
	mov r7, r9
	mov r6, r8
	push {r6, r7}
	adds r7, r0, #0
	mov r8, r1
	adds r4, r2, #0
	mov r9, r3
	bl voice_Silence
	lsls r4, r4, #0x18
	lsrs r4, r4, #0x18
	adds r0, r4, #0
	adds r1, r7, #0
	bl voice_SetPan
	ldr r5, L_08067ce0
	ldr r1, [r5]
	lsls r2, r7, #2
	adds r0, r1, #0
	adds r0, #0x18
	adds r0, r0, r2
	movs r3, #0
	str r3, [r0]
	lsls r2, r7, #1
	adds r0, r1, #0
	adds r0, #0xb4
	adds r0, r0, r2
	movs r2, #0
	mov r4, sp
	ldrh r4, [r4, #0x1c]
	strh r4, [r0]
	lsls r4, r7, #3
	adds r0, r4, #0
	adds r0, #0x94
	adds r1, r1, r0
	movs r0, #0xff
	lsls r0, r0, #8
	strh r0, [r1, #4]
	mov r6, r9
	strb r6, [r1, #7]
	strb r2, [r1, #6]
	cmp r7, #2
	bgt .L08067cd2
	adds r1, r4, r7
	lsls r1, r1, #2
	adds r1, #0x28
	ldr r0, [r5]
	adds r0, r0, r1
	ldrh r2, [r0]
	ldrh r4, [r0, #0x1c]
	adds r1, r2, r4
	strh r1, [r0, #0x22]
	mov r6, r8
	lsls r1, r6, #8
	strh r1, [r0]
	strh r3, [r0, #2]
	strh r3, [r0, #0x1c]
	strh r3, [r0, #0x1e]
	strh r3, [r0, #0x20]
	strh r3, [r0, #0x14]
	strh r3, [r0, #0x16]
	strh r3, [r0, #4]
	strh r3, [r0, #6]
	strh r3, [r0, #0xc]
	strh r3, [r0, #0xe]
	strh r3, [r0, #0x12]
.L08067cd2:
	pop {r3, r4}
	mov r8, r3
	mov r9, r4
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
	.hword 0x0000
L_08067ce0:
	.word 0x03006830

.global psg_VoiceLegato
.thumb_func
.type psg_VoiceLegato, %function
psg_VoiceLegato:
	push {r4, r5, r6, r7, lr}
	adds r7, r0, #0
	mov r12, r1
	ldr r6, L_08067d38
	ldr r5, [r6]
	lsls r0, r7, #2
	adds r1, r5, #0
	adds r1, #0x18
	adds r1, r1, r0
	ldr r0, [r1]
	ldr r4, L_08067d3c
	ands r0, r4
	str r0, [r1]
	lsls r4, r7, #3
	adds r5, r5, r4
	adds r5, #0x9b
	strb r2, [r5]
	ldr r6, [r6]
	lsls r1, r7, #1
	adds r0, r6, #0
	adds r0, #0xb4
	adds r0, r0, r1
	strh r3, [r0]
	cmp r7, #3
	beq .L08067d32
	adds r0, r4, r7
	lsls r0, r0, #2
	adds r2, r6, r0
	adds r0, r2, #0
	adds r0, #0x44
	ldrh r1, [r2, #0x28]
	ldrh r0, [r0]
	adds r0, r1, r0
	adds r1, r2, #0
	adds r1, #0x4a
	strh r0, [r1]
	mov r1, r12
	lsls r0, r1, #8
	strh r0, [r2, #0x28]
.L08067d32:
	pop {r4, r5, r6, r7}
	pop {r0}
	bx r0
L_08067d38:
	.word 0x03006830
L_08067d3c:
	.word 0xffff7eef

.global sndSeqStart
.thumb_func
.type sndSeqStart, %function
sndSeqStart:
	ldr r0, L_08067d5c
	ldr r0, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	adds r1, #0x31
	adds r2, r0, r1
	ldrb r1, [r2]
	cmp r1, #1
	beq .L08067d60
	movs r0, #0
	b .L08067d68
	.hword 0x0000
L_08067d5c:
	.word 0x03006830
.L08067d60:
	movs r0, #2
	orrs r0, r1
	strb r0, [r2]
	movs r0, #1
.L08067d68:
	bx lr
	.hword 0x0000

.global sndSeqContinue
.thumb_func
.type sndSeqContinue, %function
sndSeqContinue:
	ldr r0, L_08067d8c
	ldr r0, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r0, [r0]
	adds r1, #0x31
	adds r2, r0, r1
	ldrb r1, [r2]
	movs r0, #7
	ands r0, r1
	cmp r0, #5
	beq .L08067d90
	movs r0, #0
	b .L08067d9c
	.hword 0x0000
L_08067d8c:
	.word 0x03006830
.L08067d90:
	movs r0, #0xfb
	ands r0, r1
	movs r1, #2
	orrs r0, r1
	strb r0, [r2]
	movs r0, #1
.L08067d9c:
	bx lr
	.hword 0x0000

.global sndSeqSpeed
.thumb_func
.type sndSeqSpeed, %function
sndSeqSpeed:
	push {lr}
	lsls r0, r0, #0x10
	lsrs r3, r0, #0x10
	ldr r0, L_08067dd4
	ldr r0, [r0]
	movs r1, #0x90
	lsls r1, r1, #1
	adds r0, r0, r1
	ldr r2, [r0]
	cmp r3, #0
	beq .L08067ddc
	ldr r0, L_08067dd8
	adds r1, r2, r0
	movs r0, #1
	ldrb r1, [r1]
	ands r0, r1
	cmp r0, #0
	beq .L08067ddc
	movs r1, #0xa4
	lsls r1, r1, #1
	adds r0, r2, r1
	strh r3, [r0]
	bl seq_UpdateTempo
	movs r0, #1
	b .L08067dde
L_08067dd4:
	.word 0x03006830
L_08067dd8:
	.word 0x00000151
.L08067ddc:
	movs r0, #0
.L08067dde:
	pop {r1}
	bx r1
	.hword 0x0000

.global sndSeqGetStateSize
.thumb_func
.type sndSeqGetStateSize, %function
sndSeqGetStateSize:
	movs r0, #0xa8
	lsls r0, r0, #1
	bx lr
	.hword 0x0000

.global seq_Init
.thumb_func
.type seq_Init, %function
seq_Init:
	push {r4, r5, r6, lr}
	mov r6, r9
	mov r5, r8
	push {r5, r6}
	mov r9, r0
	adds r5, r1, #0
	ldr r0, L_08067e5c
	mov r8, r0
	ldr r0, [r0]
	movs r6, #0x90
	lsls r6, r6, #1
	adds r0, r0, r6
	str r5, [r0]
	movs r4, #0xaa
	lsls r4, r4, #1
	adds r0, r5, #0
	adds r1, r4, #0
	bl snd_memclr
	adds r4, r5, r4
	mov r2, r8
	ldr r1, [r2]
	adds r1, r1, r6
	ldr r0, [r1]
	movs r2, #0x88
	lsls r2, r2, #1
	adds r0, r0, r2
	str r4, [r0]
	ldr r0, [r1]
	adds r0, r0, r2
	ldr r0, [r0]
	mov r1, r9
	ldrb r2, [r1, #2]
	adds r2, #4
	lsls r1, r2, #1
	adds r1, r1, r2
	lsls r1, r1, #2
	bl snd_memclr
	ldr r2, L_08067e60
	adds r1, r5, r2
	movs r0, #0
	strb r0, [r1]
	mov r1, r9
	ldrb r0, [r1, #2]
	adds r2, #1
	adds r1, r5, r2
	strb r0, [r1]
	movs r0, #1
	pop {r3, r4}
	mov r8, r3
	mov r9, r4
	pop {r4, r5, r6}
	pop {r1}
	bx r1
	.hword 0x0000
L_08067e5c:
	.word 0x03006830
L_08067e60:
	.word 0x00000151

.global ds_VoiceAlloc
.thumb_func
.type ds_VoiceAlloc, %function
ds_VoiceAlloc:
	push {r4, r5, r6, r7, lr}
	adds r7, r1, #0
	cmp r0, #0
	beq .L08067e72
	movs r0, #0x80
	lsls r0, r0, #1
	adds r7, r7, r0
.L08067e72:
	cmp r3, #0xff
	beq .L08067e98
	ldr r0, L_08067e94
	ldr r0, [r0]
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r3, #2
	adds r0, r0, r1
	ldr r0, [r0]
	cmp r0, #0
	beq .L08067e8e
	ldrh r0, [r0, #0x34]
	cmp r0, r7
	bhi .L08067eee
.L08067e8e:
	adds r0, r3, #0
	b .L08067ef2
	.hword 0x0000
L_08067e94:
	.word 0x03006830
.L08067e98:
	movs r0, #0
	mov r12, r0
	adds r3, r7, #1
	movs r6, #0x80
	lsls r6, r6, #9
	ldr r0, L_08067ec8
	ldr r0, [r0]
	ldrb r2, [r0, #9]
	ldrb r5, [r0, #8]
	cmp r2, r5
	bge .L08067ee2
	adds r0, #0xd4
	ldr r1, [r0]
	lsls r0, r2, #2
	adds r4, r0, r1
.L08067eb6:
	ldr r0, [r4]
	cmp r0, #0
	beq .L08067eea
	ldrh r1, [r0, #0x34]
	cmp r1, r3
	bhs .L08067ecc
	adds r3, r1, #0
	ldrh r6, [r0, #0x36]
	b .L08067ed8
L_08067ec8:
	.word 0x03006830
.L08067ecc:
	cmp r1, r3
	bne .L08067eda
	ldrh r0, [r0, #0x36]
	cmp r0, r6
	bhs .L08067eda
	adds r6, r0, #0
.L08067ed8:
	mov r12, r2
.L08067eda:
	adds r4, #4
	adds r2, #1
	cmp r2, r5
	blt .L08067eb6
.L08067ee2:
	cmp r3, r7
	bhi .L08067eee
	mov r0, r12
	b .L08067ef2
.L08067eea:
	adds r0, r2, #0
	b .L08067ef2
.L08067eee:
	movs r0, #1
	rsbs r0, r0, #0
.L08067ef2:
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1

.global psg_VoiceAvail
.thumb_func
.type psg_VoiceAvail, %function
psg_VoiceAvail:
	adds r3, r1, #0
	cmp r0, #0
	beq .L08067f04
	movs r0, #0x80
	lsls r0, r0, #1
	adds r3, r3, r0
.L08067f04:
	ldr r0, L_08067f18
	ldr r0, [r0]
	lsls r1, r2, #1
	adds r0, #0xb4
	adds r0, r0, r1
	ldrh r0, [r0]
	cmp r0, r3
	bls .L08067f1c
	movs r0, #0
	b .L08067f1e
L_08067f18:
	.word 0x03006830
.L08067f1c:
	movs r0, #1
.L08067f1e:
	bx lr

.global ds_VoiceLegato
.thumb_func
.type ds_VoiceLegato, %function
ds_VoiceLegato:
	push {r4, lr}
	mov r12, r0
	adds r4, r1, #0
	movs r0, #0xc0
	lsls r0, r0, #8
	mov r1, r12
	strh r0, [r1, #0x36]
	adds r1, #0x3f
	movs r0, #1
	strb r0, [r1]
	mov r1, r12
	ldr r0, [r1, #0x38]
	ldr r1, L_08067f6c
	ands r0, r1
	mov r1, r12
	str r0, [r1, #0x38]
	lsls r2, r2, #1
	adds r1, #0x2b
	strb r2, [r1]
	lsls r0, r2, #0x18
	cmp r0, #0
	beq .L08067f50
	adds r0, r2, #1
	strb r0, [r1]
.L08067f50:
	mov r2, r12
	strh r3, [r2, #0x34]
	movs r3, #0
	ldrsh r0, [r2, r3]
	movs r3, #0x1c
	ldrsh r1, [r2, r3]
	adds r0, r0, r1
	strh r0, [r2, #0x22]
	lsls r0, r4, #8
	strh r0, [r2]
	pop {r4}
	pop {r0}
	bx r0
	.hword 0x0000
L_08067f6c:
	.word 0xffff7eef

.global sndGetMemSize
.thumb_func
.type sndGetMemSize, %function
sndGetMemSize:
	push {r4, r5, r6, r7, lr}
	mov r7, r10
	mov r6, r9
	mov r5, r8
	push {r5, r6, r7}
	sub sp, #8
	adds r4, r0, #0
	adds r6, r1, #0
	cmp r6, #0
	bne .L08067f88
	movs r0, #0
	b .L08068142
.L08067f88:
	ldrb r2, [r4, #2]
	lsls r0, r2, #4
	adds r0, r0, r2
	lsls r0, r0, #2
	str r0, [sp]
	lsls r0, r2, #5
	mov r10, r0
	adds r1, r2, #4
	lsls r3, r1, #4
	str r3, [sp, #4]
	lsls r0, r1, #1
	adds r0, r0, r1
	lsls r0, r0, #2
	movs r3, #0xaa
	lsls r3, r3, #1
	adds r3, r3, r0
	mov r9, r3
	lsls r1, r1, #2
	adds r1, #8
	mov r8, r1
	cmp r2, #0
	beq .L08067fc6
	movs r7, #0xa0
	lsls r7, r7, #2
	movs r0, #2
	ldrb r1, [r4, #3]
	ands r0, r1
	cmp r0, #0
	bne .L08067fc8
	lsls r7, r7, #1
	b .L08067fc8
.L08067fc6:
	movs r7, #0
.L08067fc8:
	ldrh r0, [r4, #4]
	cmp r0, #0
	beq .L08068028
	ldrb r0, [r4, #2]
	cmp r0, #0
	beq .L08068028
	ldrh r2, [r4]
	ldr r0, L_08067fe4
	cmp r2, r0
	bhi .L08067fe8
	movs r2, #0xfa
	lsls r2, r2, #3
	b .L08067ff0
	.hword 0x0000
L_08067fe4:
	.word 0x000007cf
.L08067fe8:
	ldr r0, L_08068024
	cmp r2, r0
	bls .L08067ff0
	adds r2, r0, #0
.L08067ff0:
	adds r0, r2, #0
	bl snd_CalcTimer
	lsls r0, r0, #0x10
	lsrs r2, r0, #0x10
	ldrh r1, [r4, #4]
	movs r0, #0xfa
	lsls r0, r0, #2
	cmp r1, r0
	bls .L08068006
	adds r1, r0, #0
.L08068006:
	adds r0, r2, #0
	bl snd_CalcEchoBlocks
	lsls r0, r0, #8
	movs r1, #0x80
	lsls r1, r1, #1
	adds r3, r0, r1
	movs r0, #6
	ldrb r1, [r4, #3]
	ands r0, r1
	cmp r0, #0
	bne .L0806802a
	lsls r3, r3, #1
	b .L0806802a
	.hword 0x0000
L_08068024:
	.word 0x00005622
.L08068028:
	movs r3, #0
.L0806802a:
	movs r5, #0
	ldrb r0, [r4, #2]
	cmp r0, #0
	beq .L08068118
	ldrb r1, [r4, #3]
	movs r0, #8
	ands r0, r1
	adds r2, r1, #0
	cmp r0, #0
	bne .L08068118
	movs r0, #1
	ands r0, r2
	cmp r0, #0
	bne .L0806806c
	movs r0, #2
	ands r0, r2
	cmp r0, #0
	bne .L0806805c
	ldr r1, L_08068054
	ldr r0, L_08068058
	b .L08068088
L_08068054:
	.word arm_MixStereo
L_08068058:
	.word arm_MixStereoInterp
.L0806805c:
	ldr r1, L_08068064
	ldr r0, L_08068068
	b .L08068088
	.hword 0x0000
L_08068064:
	.word arm_MixMono
L_08068068:
	.word arm_MixMonoInterp
.L0806806c:
	movs r0, #2
	ands r0, r2
	cmp r0, #0
	bne .L08068084
	ldr r1, L_0806807c
	ldr r0, L_08068080
	b .L08068088
	.hword 0x0000
L_0806807c:
	.word arm_MixMonoInterp
L_08068080:
	.word arm_MixStereo
.L08068084:
	ldr r1, L_08068098
	ldr r0, L_0806809c
.L08068088:
	subs r5, r1, r0
	movs r0, #2
	ands r0, r2
	cmp r0, #0
	bne .L080680a8
	ldr r0, L_080680a0
	ldr r1, L_080680a4
	b .L080680ac
L_08068098:
	.word arm_EchoStereo
L_0806809c:
	.word arm_MixMono
L_080680a0:
	.word arm_OutMono
L_080680a4:
	.word arm_OutStereo
.L080680a8:
	ldr r0, L_080680c0
	ldr r1, L_080680c4
.L080680ac:
	subs r0, r0, r1
	adds r5, r5, r0
	movs r0, #2
	ands r0, r2
	cmp r0, #0
	beq .L080680d0
	ldr r0, L_080680c8
	ldr r1, L_080680cc
	b .L08068114
	.hword 0x0000
L_080680c0:
	.word arm_MixStereoInterp
L_080680c4:
	.word arm_OutMono
L_080680c8:
	.word 0x08068bc4
L_080680cc:
	.word arm_EchoMono
.L080680d0:
	movs r0, #4
	ands r0, r2
	cmp r0, #0
	beq .L08068110
	movs r0, #1
	ands r0, r2
	cmp r0, #0
	bne .L080680f0
	ldr r0, L_080680e8
	ldr r1, L_080680ec
	b .L080680f4
	.hword 0x0000
L_080680e8:
	.word arm_MixMono
L_080680ec:
	.word arm_MixMonoInterp
.L080680f0:
	ldr r0, L_08068100
	ldr r1, L_08068104
.L080680f4:
	subs r0, r0, r1
	adds r5, r5, r0
	ldr r0, L_08068108
	ldr r1, L_0806810c
	b .L08068114
	.hword 0x0000
L_08068100:
	.word arm_EchoStereo
L_08068104:
	.word arm_MixMono
L_08068108:
	.word arm_EchoMono
L_0806810c:
	.word arm_EchoStereoHalf
.L08068110:
	ldr r0, L_08068154
	ldr r1, L_08068158
.L08068114:
	subs r0, r0, r1
	adds r5, r5, r0
.L08068118:
	movs r0, #0x9e
	lsls r0, r0, #1
	add r0, r10
	ldr r1, [sp]
	adds r0, r0, r1
	ldr r1, [sp, #4]
	adds r0, r0, r1
	add r0, r9
	add r0, r8
	str r0, [r6]
	adds r4, r7, #0
	str r4, [r6, #8]
	movs r2, #4
	rsbs r2, r2, #0
	str r3, [r6, #0xc]
	adds r1, r5, #3
	ands r1, r2
	str r1, [r6, #4]
	adds r0, r0, r4
	adds r0, r0, r3
	adds r0, r0, r1
.L08068142:
	add sp, #8
	pop {r3, r4, r5}
	mov r8, r3
	mov r9, r4
	mov r10, r5
	pop {r4, r5, r6, r7}
	pop {r1}
	bx r1
	.hword 0x0000
L_08068154:
	.word arm_EchoStereoHalf
L_08068158:
	.word arm_EchoStereo

.global sndSetMemLayout
.thumb_func
.type sndSetMemLayout, %function
sndSetMemLayout:
	str r1, [r2, #4]
	ldr r3, [r0, #4]
	adds r1, r1, r3
	str r1, [r2]
	ldr r3, [r0]
	adds r1, r1, r3
	str r1, [r2, #8]
	ldr r0, [r0, #8]
	adds r1, r1, r0
	str r1, [r2, #0xc]
	bx lr
	.hword 0x0000
.arm

.global arm_OutStereo
.type arm_OutStereo, %function
arm_OutStereo:
	push {r0, r1, r2, r4, r5, r6, r7, r8, r9, lr}
	mov lr, #0
	mov r9, #0x20
	ldrsh r4, [r0], #4
	ldrsh r5, [r0], #4
	ldrsh r6, [r0], #4
	ldrsh r7, [r0], #-0xc
	cmp r4, #0x7f
	movgt r4, #0x7f
	cmn r4, #0x80
	mvnlt r4, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r4, lsl #24
	cmp r5, #0x7f
	movgt r5, #0x7f
	cmn r5, #0x80
	mvnlt r5, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r5, lsl #24
	cmp r6, #0x7f
	movgt r6, #0x7f
	cmn r6, #0x80
	mvnlt r6, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r6, lsl #24
	cmp r7, #0x7f
	movgt r7, #0x7f
	cmn r7, #0x80
	mvnlt r7, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r7, lsl #24
	str r8, [r1], #4
	ldrsh r4, [r0, #2]
	ldrsh r5, [r0, #6]
	ldrsh r6, [r0, #0xa]
	ldrsh r7, [r0, #0xe]
	str lr, [r0], #4
	str lr, [r0], #4
	str lr, [r0], #4
	str lr, [r0], #4
	cmp r4, #0x7f
	movgt r4, #0x7f
	cmn r4, #0x80
	mvnlt r4, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r4, lsl #24
	cmp r5, #0x7f
	movgt r5, #0x7f
	cmn r5, #0x80
	mvnlt r5, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r5, lsl #24
	cmp r6, #0x7f
	movgt r6, #0x7f
	cmn r6, #0x80
	mvnlt r6, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r6, lsl #24
	cmp r7, #0x7f
	movgt r7, #0x7f
	cmn r7, #0x80
	mvnlt r7, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r7, lsl #24
	str r8, [r2], #4
	subs r9, r9, #1
	bne 0x08068180
	pop {r0, r1, r2, r4, r5, r6, r7, r8, r9, lr}
	bx lr

.global arm_OutMono
.type arm_OutMono, %function
arm_OutMono:
	push {r0, r1, r4, r5, r6, r7, r8, r9, lr}
	mov lr, #0
	mov r9, #0x20
	ldrsh r4, [r0]
	ldrsh r5, [r0, #2]
	ldrsh r6, [r0, #4]
	ldrsh r7, [r0, #6]
	str lr, [r0], #4
	str lr, [r0], #4
	cmp r4, #0x7f
	movgt r4, #0x7f
	cmn r4, #0x80
	mvnlt r4, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r4, lsl #24
	cmp r5, #0x7f
	movgt r5, #0x7f
	cmn r5, #0x80
	mvnlt r5, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r5, lsl #24
	cmp r6, #0x7f
	movgt r6, #0x7f
	cmn r6, #0x80
	mvnlt r6, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r6, lsl #24
	cmp r7, #0x7f
	movgt r7, #0x7f
	cmn r7, #0x80
	mvnlt r7, #0x7f
	lsr r8, r8, #8
	orr r8, r8, r7, lsl #24
	str r8, [r1], #4
	subs r9, r9, #1
	bne 0x08068294
	pop {r0, r1, r4, r5, r6, r7, r8, r9, lr}
	bx lr

.global arm_MixStereoInterp
.type arm_MixStereoInterp, %function
arm_MixStereoInterp:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0, #4]
	ldr r10, [r0, #8]
	ldrh r11, [r0, #0x16]
	ldrh lr, [r0, #0x14]
	ldrb r4, [r0, #0x18]
	ldrb r5, [r0, #0x19]
	cmp r4, #0
	addne r4, r4, #1
	cmp r5, #0
	addne r5, r5, #1
	ldrb r8, [r0, #0x1a]
	ands r8, r8, r8
	rsbne r5, r5, #0
	mvn r8, #0xf000
	mov r9, #0x80
	cmp r10, r2
	bmi 0x08068434
	add r3, r2, #1
	cmp r3, r10
	bhs 0x08068420
	ldrsb r6, [r2]
	ldrsb r7, [r3]
	sub r7, r7, r6
	and r3, r11, r8
	mul r3, r7, r3
	add r3, r6, r3, asr #12
	mul r6, r3, r4
	ldrsh r7, [r1]
	ldrsh r12, [r1, #2]
	add r7, r7, r6, asr #8
	mul r6, r3, r5
	add r12, r12, r6, asr #8
	strh r7, [r1], #2
	strh r12, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x080683c8
	add r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bhs 0x080683e4
	subs r9, r9, #1
	bne 0x08068368
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x080683fc
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	add r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	blo 0x080683c8
	mov r2, r12
	b 0x080683c8
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x08068374
	sub r3, r2, #1
	cmp r3, r10
	bls 0x080684ec
	ldrsb r6, [r2]
	ldrsb r7, [r3]
	sub r7, r7, r6
	and r3, r11, r8
	mul r3, r7, r3
	add r3, r6, r3, asr #12
	mul r6, r3, r4
	ldrsh r7, [r1]
	ldrsh r12, [r1, #2]
	add r7, r7, r6, asr #8
	mul r6, r3, r5
	add r12, r12, r6, asr #8
	strh r7, [r1], #2
	strh r12, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x08068494
	sub r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bls 0x080684b0
	subs r9, r9, #1
	bne 0x08068434
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x080684c8
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	sub r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	bhi 0x08068494
	mov r2, r12
	b 0x08068494
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x08068440

.global arm_MixStereo
.type arm_MixStereo, %function
arm_MixStereo:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0, #4]
	ldr r10, [r0, #8]
	ldrh r11, [r0, #0x16]
	ldrh lr, [r0, #0x14]
	ldrb r4, [r0, #0x18]
	ldrb r5, [r0, #0x19]
	cmp r4, #0
	addne r4, r4, #1
	cmp r5, #0
	addne r5, r5, #1
	ldrb r8, [r0, #0x1a]
	ands r8, r8, r8
	rsbne r5, r5, #0
	mvn r8, #0xf000
	mov r9, #0x80
	cmp r10, r2
	bmi 0x080685e0
	ldrsb r3, [r2]
	mul r6, r3, r4
	ldrsh r7, [r1]
	ldrsh r12, [r1, #2]
	add r7, r7, r6, asr #8
	mul r6, r3, r5
	add r12, r12, r6, asr #8
	strh r7, [r1], #2
	strh r12, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x08068588
	add r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bhs 0x080685a4
	subs r9, r9, #1
	bne 0x08068548
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x080685bc
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	add r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	blo 0x08068588
	mov r2, r12
	b 0x08068588
	ldrsb r3, [r2]
	mul r6, r3, r4
	ldrsh r7, [r1]
	ldrsh r12, [r1, #2]
	add r7, r7, r6, asr #8
	mul r6, r3, r5
	add r12, r12, r6, asr #8
	strh r7, [r1], #2
	strh r12, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x08068620
	sub r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bls 0x0806863c
	subs r9, r9, #1
	bne 0x080685e0
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x08068654
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	sub r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	bhi 0x08068620
	mov r2, r12
	b 0x08068620
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x080685e0

.global arm_MixMonoInterp
.type arm_MixMonoInterp, %function
arm_MixMonoInterp:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0, #4]
	ldr r10, [r0, #8]
	ldrh r11, [r0, #0x16]
	ldrh lr, [r0, #0x14]
	ldrb r4, [r0, #0x18]
	ldrb r5, [r0, #0x19]
	add r4, r4, r5
	cmp r4, #0
	addne r4, r4, #2
	lsr r4, r4, #1
	mvn r8, #0xf000
	mov r9, #0x80
	cmp r10, r2
	bmi 0x08068784
	add r3, r2, #1
	cmp r3, r10
	bhs 0x08068770
	ldrsb r6, [r2]
	ldrsb r7, [r3]
	sub r7, r7, r6
	and r3, r11, r8
	mul r3, r7, r3
	add r3, r6, r3, asr #12
	mul r6, r3, r4
	ldrsh r7, [r1]
	add r7, r7, r6, asr #8
	strh r7, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x08068718
	add r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bhs 0x08068734
	subs r9, r9, #1
	bne 0x080686c8
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x0806874c
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	add r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	blo 0x08068718
	mov r2, r12
	b 0x08068718
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x080686d4
	sub r3, r2, #1
	cmp r3, r10
	bls 0x0806882c
	ldrsb r6, [r2]
	ldrsb r7, [r3]
	sub r7, r7, r6
	and r3, r11, r8
	mul r3, r7, r3
	add r3, r6, r3, asr #12
	mul r6, r3, r4
	ldrsh r7, [r1]
	add r7, r7, r6, asr #8
	strh r7, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x080687d4
	sub r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bls 0x080687f0
	subs r9, r9, #1
	bne 0x08068784
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x08068808
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	sub r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	bhi 0x080687d4
	mov r2, r12
	b 0x080687d4
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x08068790

.global arm_MixMono
.type arm_MixMono, %function
arm_MixMono:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0, #4]
	ldr r10, [r0, #8]
	ldrh r11, [r0, #0x16]
	ldrh lr, [r0, #0x14]
	ldrb r4, [r0, #0x18]
	ldrb r5, [r0, #0x19]
	add r4, r4, r5
	cmp r4, #0
	addne r4, r4, #2
	lsr r4, r4, #1
	mvn r8, #0xf000
	mov r9, #0x80
	cmp r10, r2
	bmi 0x08068924
	add r3, r2, #1
	cmp r3, r10
	bhs 0x08068910
	ldrsb r3, [r2]
	mul r6, r3, r4
	ldrsh r7, [r1]
	add r7, r7, r6, asr #8
	strh r7, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x080688b8
	add r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bhs 0x080688d4
	subs r9, r9, #1
	bne 0x0806887c
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x080688ec
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	add r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	blo 0x080688b8
	mov r2, r12
	b 0x080688b8
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x08068888
	sub r3, r2, #1
	cmp r3, r10
	bls 0x080689b8
	ldrsb r3, [r2]
	mul r6, r3, r4
	ldrsh r7, [r1]
	add r7, r7, r6, asr #8
	strh r7, [r1], #2
	add r11, r11, lr
	cmp r11, #0x1000
	blo 0x08068960
	sub r2, r2, r11, lsr #12
	and r11, r11, r8
	cmp r2, r10
	bls 0x0806897c
	subs r9, r9, #1
	bne 0x08068924
	str r2, [r0, #4]
	strh r11, [r0, #0x16]
	mov r0, #0
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	bne 0x08068994
	mov r0, #1
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
	sub r2, r2, r10
	add r2, r2, r12
	ldr r6, [r0, #0x10]
	sub r10, r12, r6
	str r10, [r0, #8]
	cmp r2, r10
	bhi 0x08068960
	mov r2, r12
	b 0x08068960
	ldr r12, [r0, #0xc]
	ands r12, r12, r12
	moveq r3, r2
	movne r3, r12
	b 0x08068930

.global arm_EchoStereo
.type arm_EchoStereo, %function
arm_EchoStereo:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0]
	ldr r3, [r0, #0xc]
	ldr r4, [r0, #8]
	ldrh r5, [r0, #0x14]
	cmp r5, #0
	addne r5, r5, #1
	ldrh r6, [r0, #0x16]
	cmp r6, #0
	addne r6, r6, #1
	ldrh r7, [r0, #0x18]
	cmp r7, #0
	addne r7, r7, #1
	mov r8, #0x100
	mov r9, #0
	ldrsh r12, [r3], #2
	mul r12, r7, r12
	ldrsh lr, [r2]
	strh r9, [r2], #2
	mla r11, r6, lr, r12
	asr r12, r11, #0x10
	ldrsh r11, [r4]
	muls r11, r5, r11
	addmi r11, r11, #0xff00
	add r11, lr, r11, asr #16
	strh r11, [r4], #2
	ldrsh r11, [r1]
	add r11, r11, r12
	strh r11, [r1], #2
	subs r8, r8, #1
	bne 0x08068a08
	ldr r1, [r0, #4]
	ldr r2, [r0, #0x10]
	cmp r3, r2
	strhs r1, [r0, #0xc]
	strlo r3, [r0, #0xc]
	cmp r4, r2
	strhs r1, [r0, #8]
	strlo r4, [r0, #8]
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr

.global arm_EchoStereoHalf
.type arm_EchoStereoHalf, %function
arm_EchoStereoHalf:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0]
	ldr r3, [r0, #0xc]
	ldr r4, [r0, #8]
	ldrh r5, [r0, #0x14]
	cmp r5, #0
	addne r5, r5, #1
	ldrh r6, [r0, #0x16]
	cmp r6, #0
	addne r6, r6, #1
	ldrh r7, [r0, #0x18]
	cmp r7, #0
	addne r7, r7, #1
	mov r8, #0x80
	mov r9, #0
	ldrsh r12, [r3], #2
	mul r12, r7, r12
	ldrsh lr, [r2]
	strh r9, [r2], #2
	mla r11, r6, lr, r12
	asr r12, r11, #0x10
	ldrsh r11, [r4]
	muls r11, r5, r11
	addmi r11, r11, #0xff00
	add r11, lr, r11, asr #16
	strh r11, [r4], #2
	ldrsh r11, [r1]
	add r11, r11, r12
	strh r11, [r1], #2
	ldrsh r11, [r1]
	add r11, r11, r12
	strh r11, [r1], #2
	subs r8, r8, #1
	bne 0x08068aac
	ldr r1, [r0, #4]
	ldr r2, [r0, #0x10]
	cmp r3, r2
	strhs r1, [r0, #0xc]
	strlo r3, [r0, #0xc]
	cmp r4, r2
	strhs r1, [r0, #8]
	strlo r4, [r0, #8]
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr

.global arm_EchoMono
.type arm_EchoMono, %function
arm_EchoMono:
	push {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	ldr r2, [r0]
	ldr r3, [r0, #0xc]
	ldr r4, [r0, #8]
	ldrh r5, [r0, #0x14]
	cmp r5, #0
	addne r5, r5, #1
	ldrh r6, [r0, #0x16]
	cmp r6, #0
	addne r6, r6, #1
	ldrh r7, [r0, #0x18]
	cmp r7, #0
	addne r7, r7, #1
	mov r8, #0x80
	mov r9, #0
	ldrsh r12, [r3], #2
	mul r12, r7, r12
	ldrsh lr, [r2]
	strh r9, [r2], #2
	mla r11, r6, lr, r12
	asr r12, r11, #0x10
	ldrsh r11, [r4]
	muls r11, r5, r11
	addmi r11, r11, #0xff00
	add r11, lr, r11, asr #16
	strh r11, [r4], #2
	ldrsh r11, [r1]
	add r11, r11, r12
	strh r11, [r1], #2
	subs r8, r8, #1
	bne 0x08068b5c
	ldr r1, [r0, #4]
	ldr r2, [r0, #0x10]
	cmp r3, r2
	strhs r1, [r0, #0xc]
	strlo r3, [r0, #0xc]
	cmp r4, r2
	strhs r1, [r0, #8]
	strlo r4, [r0, #8]
	pop {r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11, r12, lr}
	bx lr
