;; ROM0 glue for the sound driver

INCLUDE "MMX_Sound.inc"

; the driver entry points are the same in banks 2-4
DEF SndJT_Update EQU $4000
DEF SndJT_Play   EQU $4003

SECTION "MMX VBlank sound update", ROM0[$0B39]

;; End of the VBlank handler (the pushed AF holds the interrupted bank)
VBlank_SndUpdate:
	ldh a, [hSndBank]
	ld [rROMB0], a
	call SndJT_Update
	pop af
	ld [rROMB0], a

SECTION "MMX sound glue", ROM0[$2A14]

;; GamePlaySound: plays hSndID from bank hSndBank (restores the caller's bank)
GamePlaySound:
	ld a, [BankNumber]
	push af
	ldh a, [hSndBank]
	ld [rROMB0], a
	ldh a, [hSndID]
	call SndJT_Play
	pop af
	ld [rROMB0], a
	ret

;; GameSelectSoundBank: stop all sound (with bank 2's copy of the driver),
;; then run one update in bank hSndBank
GameSelectSoundBank:
	ld a, [BankNumber]
	push af
	ld a, $02                               ; any sound bank works: the code is the same
	ld [rROMB0], a
	ld a, $F0
	call SndJT_Play
	ldh a, [hSndBank]
	ld [rROMB0], a
	call SndJT_Update
	pop af
	ld [rROMB0], a
	ret
