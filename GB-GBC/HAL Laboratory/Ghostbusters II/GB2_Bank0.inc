; bank 0: request queue, init ($07D4-$084C)


; Sound_Request (rst $20): a = sound id. Appends it to hSoundQueue (max 10) with interrupts
; disabled. The queue is consumed by Sound_StartQueued, one id per update.
Sound_Request:
	push hl                     ; 07D4
	push de                     ; 07D5
	push bc                     ; 07D6
	ld e, a                     ; 07D7
	ldh a, [rIE]                ; 07D8
	push af                     ; 07DA
	xor a                       ; 07DB
	ldh [rIE], a                ; 07DC
	ld hl, hSoundQueueCount     ; 07DE
	ld c, [hl]                  ; 07E1
	ld b, $00                   ; 07E2
	ld a, c                     ; 07E4
	cp $0A                      ; 07E5
	jr nc, .l_07F3              ; 07E7
	ld a, e                     ; 07E9
	ld hl, hSoundQueue          ; 07EA
	add hl, bc                  ; 07ED
	ld [hl], a                  ; 07EE
	ld hl, hSoundQueueCount     ; 07EF
	inc [hl]                    ; 07F2
.l_07F3:
	pop af                      ; 07F3
	ldh [rIE], a                ; 07F4
	pop bc                      ; 07F6
	pop de                      ; 07F7
	pop hl                      ; 07F8
	ret                         ; 07F9


; Sound_Init: no channels active, master on, NR50/NR51, wave RAM, all channel registers,
; wChLastNote[0-7] = $7C (rest).
Sound_Init:
	xor a                       ; 07FA
	ldh [hActiveChannels], a    ; 07FB
	ld a, $80                   ; 07FD
	ldh [rNR52], a              ; 07FF
	ld a, $77                   ; 0801
	ldh [rNR50], a              ; 0803
	ld a, $FF                   ; 0805
	ldh [rNR51], a              ; 0807
	ld hl, InitialWave          ; 0809
	ld de, _AUD3WAVERAM         ; 080C
	ld bc, $0010                ; 080F
	rst $08                     ; 0812
Sound_InitRegs:
	ld hl, InitialRegs          ; 0813
	ld de, rNR10                ; 0816
	ld bc, $0014                ; 0819
	rst $08                     ; 081C
	ld hl, wChLastNote          ; 081D
	ld e, $7C                   ; 0820
	ld bc, RST_CopyBytes        ; 0822
	call FillBytes              ; 0825
	ret                         ; 0828

InitialWave:
	db $FF, $EE, $DD, $CC, $BB, $AA, $99, $88, $77, $66, $55, $44, $33, $22, $11, $00
InitialRegs:
	db $08, $00, $08, $00, $80, $00, $00, $08, $00, $80, $80, $00, $00, $00, $80, $00, $00, $08, $00, $80  ; NR10-NR44 (rFF10-rFF23)
