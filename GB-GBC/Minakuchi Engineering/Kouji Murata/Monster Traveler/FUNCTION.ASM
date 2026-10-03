;Routine the sound engine calls in ROM0.
;
;GetSeqByte is how every byte of channel data is read. The bank a track's data
;lives in is copied out of its RAM block into SeqBank before the track is
;stepped, so this routine just maps that bank in, reads the byte at BC and maps
;the engine bank back. $FF9C is the game's own copy of the current ROM bank.

SECTION "GetSeqByte", ROM0[$3E4C]
GetSeqByte:
	ld a, [SeqBank]					;Bank this track's data is stored in
	sub BankOffset
	ldh [$FF9C], a
	ld [$2000], a					;Bank number (low 8 bits)
	ld a, [bc]						;Read the byte
	push af
	ld a, PlayerBank1				;Map the engine bank back in
	ldh [$FF9C], a
	ld [$2000], a
	pop af
	ret
