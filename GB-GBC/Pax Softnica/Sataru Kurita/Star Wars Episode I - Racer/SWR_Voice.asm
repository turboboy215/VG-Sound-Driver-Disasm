; Voice sample player, bank $05:$5075-$6E21

INCLUDE "GB_Hardware.inc"
INCLUDE "SWR_RAM.inc"

SECTION "SWR voice", ROMX[$5075], BANK[$05]

; Far entry (rst $20 from Voice_Play): play VoiceSample, 4 bits per sample,
; by rewriting the volume of all four channels; ends at the $80 byte.
Voice_PlaySample::
	ld a, [wSoundEnable]
	and a
	jp z, Voice_Silent
	ld a, $80
	ldh [rNR52], a
	xor a
	ldh [rNR51], a
	ld a, $77
	ldh [rNR50], a
	ld a, $FF
	ldh [rNR51], a
	ld a, $8F
	ldh [rNR52], a
	ld a, $08
	ldh [rNR10], a
	ld a, $C0
	ldh [rNR11], a
	ld a, $F0
	ldh [rNR12], a
	ld a, $FF
	ldh [rNR13], a
	ld a, $87
	ldh [rNR14], a
	ld a, $C0
	ldh [rNR21], a
	ld a, $F0
	ldh [rNR22], a
	ld a, $FF
	ldh [rNR23], a
	ld a, $87
	ldh [rNR24], a
	xor a
	ldh [rNR41], a
	ld a, $F0
	ldh [rNR42], a
	ld a, $D7
	ldh [rNR43], a
	ld a, $80
	ldh [rNR44], a
	ld hl, _AUD3WAVERAM
	ld a, $FF
.l50C7:
	ld [hli], a
	bit 6, l
	jr z, .l50C7
	xor a
	ldh [$FF31], a
	ld a, $FF
	ldh [rNR33], a
	ld a, $80
	ldh [rNR30], a
	ld a, $87
	ldh [rNR34], a
	ld hl, VoiceSample
	ld d, $00
.l50E0:
	ld a, [hli]
	cp $80
	jr z, Voice_Delay.l5137
	ld b, a
	call Voice_Delay
	and $F0
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	swap a
	ld e, a
	push hl
	ld hl, VoiceCh3Level
	add hl, de
	ld a, [hl]
	ldh [rNR32], a
	pop hl
	ld a, $87
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ldh [rNR34], a
	ld a, b
	swap a
	call Voice_Delay
	and $F0
	ldh [rNR12], a
	ldh [rNR22], a
	ldh [rNR42], a
	swap a
	ld e, a
	push hl
	ld hl, VoiceCh3Level
	add hl, de
	ld a, [hl]
	ldh [rNR32], a
	pop hl
	ld a, $87
	ldh [rNR14], a
	ldh [rNR24], a
	ldh [rNR44], a
	ldh [rNR34], a
	jr .l50E0

Voice_Delay:
	push af
	ld a, $20
.l5130:
	dec a
	cp $00
	jr nz, .l5130
	pop af
	ret
.l5137:
	rst $28

; Far entry when wSoundEnable is 0: the same delays without sound.
Voice_Silent::
	ld hl, VoiceSample
	ld d, $00
.l513D:
	ld a, [hli]
	cp $80
	jr z, Voice_SilentDelay.l5151
	call Voice_SilentDelay
	jr .l513D

Voice_SilentDelay:
	push af
	ld a, $5A
.l514A:
	dec a
	cp $00
	jr nz, .l514A
	pop af
	ret
.l5151:
	rst $28

VoiceCh3Level:
	db $00, $00, $00, $00, $60, $60, $60, $60, $40, $40, $40, $40, $20, $20, $20, $20

; 4-bit samples, high nibble first, about 8 kHz in double speed
VoiceSample:
	INCBIN "pcm/VoiceSample.bin"
	db $80 ; end

ASSERT @ == $6E22

