; Sanrio Carnival 2 sound, bank $01: SFX streams, $6AD9-$6CFF

; every unused table entry
Sfx_None:
	sfx_channels %0000
	sfx_end %0000
; slot 1 effect 0
Sfx1_0:
	sfx_channels %0001
	sfx_music $11	; hold the music
	sfx_regs 1, %1111, $78, $bf, $c0, $83, $07	; NR10=$78 NR11=$bf NR12=$c0 freq $783
	sfx_wait 3
	sfx_regs 1, %1000, $59, $07	; freq $759
	sfx_wait 3
	sfx_regs 1, %1000, $83, $07	; freq $783
	sfx_wait 3
	sfx_end %1111
; slot 1 effect 1
Sfx1_1:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $c0, $59, $07	; NR10=$78 NR11=$bf NR12=$c0 freq $759
	sfx_wait 3
	sfx_regs 1, %1000, $83, $07	; freq $783
	sfx_wait 3
	sfx_regs 1, %1000, $59, $07	; freq $759
	sfx_wait 3
	sfx_music $10	; resume the music
	sfx_end %0001
; slot 1 effect 2
Sfx1_2:
	sfx_channels %1001
	sfx_regs 1, %1111, $78, $bf, $c0, $c1, $07	; NR10=$78 NR11=$bf NR12=$c0 freq $7c1
	sfx_wait 1
	sfx_regs 4, %1110, $3f, $c0, $54, $00	; NR41=$3f NR42=$c0 NR43=$54 NR44=$00
	sfx_wait 3
	sfx_regs 1, %1000, $c8, $07	; freq $7c8
	sfx_wait 4
	sfx_regs 1, %1000, $c1, $07	; freq $7c1
	sfx_wait 1
	sfx_regs 4, %1100, $c7, $55, $00	; NR42=$c7 NR43=$55 NR44=$00
	sfx_wait 4
	sfx_regs 1, %1000, $c8, $07	; freq $7c8
	sfx_wait 4
	sfx_regs 1, %1000, $c1, $07	; freq $7c1
	sfx_wait 4
	sfx_regs 1, %1000, $c8, $07	; freq $7c8
	sfx_wait 4
	sfx_regs 1, %1000, $c1, $07	; freq $7c1
	sfx_wait 4
	sfx_regs 1, %1000, $c8, $07	; freq $7c8
	sfx_wait 4
	sfx_regs 1, %1100, $80, $00, $00	; NR12=$80 freq $000
	sfx_wait 40
	sfx_end %1001
; slot 1 effect 3
Sfx1_3:
	sfx_channels %1000
	sfx_regs 4, %1110, $3f, $c0, $54, $00	; NR41=$3f NR42=$c0 NR43=$54 NR44=$00
	sfx_wait 8
	sfx_regs 4, %1100, $c7, $55, $00	; NR42=$c7 NR43=$55 NR44=$00
	sfx_wait 64
	sfx_end %1000
; slot 1 effect 4
Sfx1_4:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $c0, $c1, $07	; NR10=$78 NR11=$bf NR12=$c0 freq $7c1
	sfx_wait 1
	sfx_regs 1, %1000, $c5, $07	; freq $7c5
	sfx_wait 1
	sfx_end %0001
; slot 1 effect 5
Sfx1_5:
	sfx_channels %0001
	sfx_regs 1, %1111, $37, $bf, $c4, $06, $07	; NR10=$37 NR11=$bf NR12=$c4 freq $706
	sfx_wait 16
	sfx_regs 1, %1100, $c4, $06, $07	; NR12=$c4 freq $706
	sfx_wait 16
	sfx_regs 1, %1100, $c4, $06, $07	; NR12=$c4 freq $706
	sfx_wait 16
	sfx_regs 1, %1100, $c4, $06, $07	; NR12=$c4 freq $706
	sfx_wait 16
	sfx_regs 1, %1100, $c4, $06, $07	; NR12=$c4 freq $706
	sfx_wait 16
	sfx_end %0001
; slot 1 effect 6
Sfx1_6:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $c1, $c1, $07	; NR10=$78 NR11=$bf NR12=$c1 freq $7c1
	sfx_wait 5
	sfx_regs 1, %1100, $c1, $ce, $07	; NR12=$c1 freq $7ce
	sfx_wait 5
	sfx_regs 1, %1100, $c1, $a7, $07	; NR12=$c1 freq $7a7
	sfx_wait 5
	sfx_regs 1, %1100, $c1, $ce, $07	; NR12=$c1 freq $7ce
	sfx_wait 5
	sfx_end %0001
; slot 1 effect 7
Sfx1_7:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $c1, $c1, $07	; NR10=$78 NR11=$bf NR12=$c1 freq $7c1
	sfx_wait 4
	sfx_end %0001
; slot 2 effect 1
Sfx2_1:
	sfx_channels %0011
	sfx_regs 1, %1111, $78, $bf, $c0, $90, $07	; NR10=$78 NR11=$bf NR12=$c0 freq $790
	sfx_regs 2, %1110, $bf, $c0, $7b, $07	; NR21=$bf NR22=$c0 freq $77b
	sfx_wait 6
	sfx_regs 1, %1000, $9d, $07	; freq $79d
	sfx_regs 2, %1000, $8a, $07	; freq $78a
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_regs 2, %1100, $08, $00, $00	; NR22=$08 freq $000
	sfx_wait 6
	sfx_regs 1, %1100, $c0, $90, $07	; NR12=$c0 freq $790
	sfx_regs 2, %1100, $c0, $7b, $07	; NR22=$c0 freq $77b
	sfx_wait 6
	sfx_regs 1, %1000, $9d, $07	; freq $79d
	sfx_regs 2, %1000, $8a, $07	; freq $78a
	sfx_wait 6
	sfx_regs 1, %1000, $90, $07	; freq $790
	sfx_regs 2, %1000, $7b, $07	; freq $77b
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_regs 2, %1100, $08, $00, $00	; NR22=$08 freq $000
	sfx_wait 6
	sfx_regs 1, %1100, $c0, $9d, $07	; NR12=$c0 freq $79d
	sfx_regs 2, %1100, $c0, $83, $07	; NR22=$c0 freq $783
	sfx_wait 6
	sfx_regs 1, %1000, $ac, $07	; freq $7ac
	sfx_regs 2, %1000, $7b, $07	; freq $77b
	sfx_wait 6
	sfx_end %0011
; slot 3 effect 0
Sfx3_0:
	sfx_channels %0001
	sfx_regs 1, %1111, $56, $bf, $c4, $06, $07	; NR10=$56 NR11=$bf NR12=$c4 freq $706
	sfx_wait 4
	sfx_regs 1, %1000, $b2, $06	; freq $6b2
	sfx_wait 4
	sfx_regs 1, %1000, $08, $06	; freq $608
	sfx_wait 4
	sfx_regs 1, %1000, $08, $06	; freq $608
	sfx_wait 4
	sfx_end %0001
; slot 2 effect 2
Sfx2_2:
	sfx_channels %0001
	sfx_regs 1, %1111, $77, $bf, $c4, $06, $07	; NR10=$77 NR11=$bf NR12=$c4 freq $706
	sfx_wait 6
	sfx_regs 1, %1000, $b2, $06	; freq $6b2
	sfx_wait 6
	sfx_regs 1, %1000, $08, $06	; freq $608
	sfx_wait 6
	sfx_regs 1, %1000, $63, $05	; freq $563
	sfx_wait 6
	sfx_regs 1, %1000, $16, $04	; freq $416
	sfx_wait 6
	sfx_regs 1, %1000, $c7, $02	; freq $2c7
	sfx_wait 8
	sfx_end %0001
; slot 3 effect 1
Sfx3_1:
	sfx_channels %1000
	sfx_regs 4, %1110, $3f, $c0, $57, $00	; NR41=$3f NR42=$c0 NR43=$57 NR44=$00
	sfx_wait 4
	sfx_regs 4, %1000, $56, $00	; NR43=$56 NR44=$00
	sfx_wait 4
	sfx_regs 4, %1000, $55, $00	; NR43=$55 NR44=$00
	sfx_wait 4
	sfx_end %1000
; slot 3 effect 2
Sfx3_2:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $f1, $21, $07	; NR10=$78 NR11=$bf NR12=$f1 freq $721
	sfx_wait 4
	sfx_end %0001
; slot 3 effect 3
Sfx3_3:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $f1, $06, $07	; NR10=$78 NR11=$bf NR12=$f1 freq $706
	sfx_wait 4
	sfx_regs 1, %1100, $f1, $14, $07	; NR12=$f1 freq $714
	sfx_wait 4
	sfx_end %0001
; slot 3 effect 4
Sfx3_4:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $f1, $9d, $07	; NR10=$78 NR11=$bf NR12=$f1 freq $79d
	sfx_wait 2
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 1
	sfx_regs 1, %1100, $f1, $9d, $07	; NR12=$f1 freq $79d
	sfx_wait 2
	sfx_end %0001
; slot 2 effect 0
Sfx2_0:
	sfx_channels %0001
	sfx_regs 1, %1111, $78, $bf, $f0, $c1, $07	; NR10=$78 NR11=$bf NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_regs 1, %1100, $f0, $c1, $07	; NR12=$f0 freq $7c1
	sfx_wait 6
	sfx_regs 1, %1100, $08, $00, $00	; NR12=$08 freq $000
	sfx_wait 2
	sfx_end %0001
	ds $66, $00
