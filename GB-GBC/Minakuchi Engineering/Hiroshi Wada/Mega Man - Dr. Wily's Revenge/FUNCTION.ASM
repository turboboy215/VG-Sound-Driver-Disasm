;Mega Man: Dr. Wily's Revenge audio disassembly (functions)
;Disassembly by Will Trowbridge

SECTION "Jumps", ROM0[$0159]
JumpRNG:
	jp FuncRNG
JumpUnk1:
	jp 0
JumpUnk2:
	jp 0
JumpFill:
	jp FuncFill


SECTION "Function1", ROM0[$167E]
FuncFill:
	push af
	
.FuncFill2
	ld a, [hl+]
	ld [de], a
	inc de
	dec bc
	ld a, b
	or c
	jr nz, .FuncFill2
	pop af
	ret
	
SECTION "Function2", ROM0[$1758]
FuncRNG:
	push hl
	ld hl, $DFAF
	inc [hl]
	ld a, [hl]
	add a, $6F
	ld l, a
	ld a, $17
	adc 0
	ld h, a
	ld a, [$DFAE]
	xor [hl]
	ld [$DFAE], a
	pop hl
	ret