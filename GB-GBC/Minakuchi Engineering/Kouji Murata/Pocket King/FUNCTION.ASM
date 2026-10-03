;Routines the sound engine calls in ROM0.
;
;GetSeqByte is how every byte of channel data is read: the track's own ROM
;bank (offset $2E of its RAM block) is mapped in, the byte at BC is read, and
;the engine's bank is mapped back. SetRomBank is the game's generic MBC5
;bank-select helper.

SECTION "SetRomBank", ROM0[$1499]
SetRomBank:
	ld [$2000], a					;Bank number (low 8 bits)
	ret

SECTION "GetSeqByte", ROM0[$3FBB]
GetSeqByte:
	push hl
	ld hl, $002E					;This track's channel data bank
	add hl, de
	ld a, [hl]
	sub BankOffset					;$0E/$0F in the data, banks 1/2 here
	call SetRomBank
	ld a, [bc]						;Read the byte
	push af
	ld a, PlayerBank1				;Map the engine bank back in
	call SetRomBank
	pop af
	pop hl
	ret
