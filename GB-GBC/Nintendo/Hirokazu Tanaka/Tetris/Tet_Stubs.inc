; Tetris sound driver: entry points, $7FF0-$7FFF

; Entry points: update, stop (Dr. Mario adds init at $7FF6).
	jp Sound_Update

	jp Sound_Stop

	ds 10, 0	; unused
