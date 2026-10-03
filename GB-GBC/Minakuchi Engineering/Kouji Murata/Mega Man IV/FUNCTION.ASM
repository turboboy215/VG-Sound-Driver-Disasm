;Misc. code for functions outside of audio data.
;
;The game-specific routine at the start of audio bank $02 calls three
;routines that live in the game's own ROM0 bank. They are stubbed out here
;so that the audio banks assemble and run on their own.

SECTION "Function 1", ROM0[$01C5]
StageMacro1:
	ret

SECTION "Function 2", ROM0[$0222]
StageMacro2:
	ret

SECTION "Function 3", ROM0[$0225]
StageMacro3:
	ret
