; =============================================================================
; Mega Man Xtreme (GBC) - sound bank 3
; Driver (shared source) + this bank's pointer table, music and SFX.
; Byte-exact for 3:$4000-$7BE3 (the rest of the bank is $00, $7FFE = bank number).
; Music present in this bank has a nonzero pointer; the SFX ($1E-$7D) are in
; all three banks (same data at bank-specific addresses).
; =============================================================================

INCLUDE "MMX_Sound.inc"

SECTION "MMX Sound bank 3", ROMX[$4000], BANK[3]

INCLUDE "MMX_SoundDriver.inc"

SndPointerTable:
	db $00, $00                             ; $00
	db $00, $00                             ; $01
	db $00, $00                             ; $02
	db $00, $00                             ; $03
	db $00, $00                             ; $04
	db $00, $00                             ; $05
	db $00, $00                             ; $06
	db $00, $00                             ; $07
	db $00, $00                             ; $08
	db $00, $00                             ; $09
	db $00, $00                             ; $0A
	BEPTR Music0B                           ; $0B
	BEPTR Music0C                           ; $0C
	BEPTR Music0D                           ; $0D
	BEPTR Music0E                           ; $0E
	BEPTR Music0F                           ; $0F
	db $00, $00                             ; $10
	db $00, $00                             ; $11
	db $00, $00                             ; $12
	db $00, $00                             ; $13
	db $00, $00                             ; $14
	db $00, $00                             ; $15
	db $00, $00                             ; $16
	db $00, $00                             ; $17
	db $00, $00                             ; $18
	db $00, $00                             ; $19
	db $00, $00                             ; $1A
	db $00, $00                             ; $1B
	BEPTR Music1C                           ; $1C
	BEPTR Music1D                           ; $1D
	BEPTR Sfx1E                             ; $1E
	BEPTR Sfx1F                             ; $1F
	BEPTR Sfx20                             ; $20
	BEPTR Sfx21                             ; $21
	BEPTR Sfx22                             ; $22
	BEPTR Sfx23                             ; $23
	BEPTR Sfx24                             ; $24
	BEPTR Sfx25                             ; $25
	BEPTR Sfx26                             ; $26
	BEPTR Sfx27                             ; $27
	BEPTR Sfx28                             ; $28
	BEPTR Sfx29                             ; $29
	BEPTR Sfx2A                             ; $2A
	BEPTR Sfx2B                             ; $2B
	BEPTR Sfx2C                             ; $2C
	BEPTR Sfx2D                             ; $2D
	BEPTR Sfx2E                             ; $2E
	BEPTR Sfx2F                             ; $2F
	BEPTR Sfx30                             ; $30
	BEPTR Sfx31                             ; $31
	BEPTR Sfx32                             ; $32
	BEPTR Sfx33                             ; $33
	BEPTR Sfx34                             ; $34
	BEPTR Sfx35                             ; $35
	BEPTR Sfx36                             ; $36
	BEPTR Sfx37                             ; $37
	BEPTR Sfx38                             ; $38
	BEPTR Sfx39                             ; $39
	BEPTR Sfx3A                             ; $3A
	BEPTR Sfx3B                             ; $3B
	BEPTR Sfx3C                             ; $3C
	BEPTR Sfx3D                             ; $3D
	BEPTR Sfx3E                             ; $3E
	BEPTR Sfx3F                             ; $3F
	BEPTR Sfx40                             ; $40
	BEPTR Sfx41                             ; $41
	BEPTR Sfx42                             ; $42
	BEPTR Sfx43                             ; $43
	BEPTR Sfx44                             ; $44
	BEPTR Sfx45                             ; $45
	BEPTR Sfx46                             ; $46
	BEPTR Sfx47                             ; $47
	BEPTR Sfx48                             ; $48
	BEPTR Sfx49                             ; $49
	BEPTR Sfx4A                             ; $4A
	BEPTR Sfx4B                             ; $4B
	BEPTR Sfx4C                             ; $4C
	BEPTR Sfx4D                             ; $4D
	BEPTR Sfx4E                             ; $4E
	BEPTR Sfx4F                             ; $4F
	BEPTR Sfx50                             ; $50
	BEPTR Sfx51                             ; $51
	BEPTR Sfx52                             ; $52
	BEPTR Sfx53                             ; $53
	BEPTR Sfx54                             ; $54
	BEPTR Sfx55                             ; $55
	BEPTR Sfx56                             ; $56
	BEPTR Sfx57                             ; $57
	BEPTR Sfx58                             ; $58
	BEPTR Sfx59                             ; $59
	BEPTR Sfx5A                             ; $5A
	BEPTR Sfx5B                             ; $5B
	BEPTR Sfx5C                             ; $5C
	BEPTR Sfx5D                             ; $5D
	BEPTR Sfx5E                             ; $5E
	BEPTR Sfx5F                             ; $5F
	BEPTR Sfx60                             ; $60
	BEPTR Sfx61                             ; $61
	BEPTR Sfx62                             ; $62
	BEPTR Sfx63                             ; $63
	BEPTR Sfx64                             ; $64
	BEPTR Sfx65                             ; $65
	BEPTR Sfx66                             ; $66
	BEPTR Sfx67                             ; $67
	BEPTR Sfx68                             ; $68
	BEPTR Sfx69                             ; $69
	BEPTR Sfx6A                             ; $6A
	BEPTR Sfx6B                             ; $6B
	BEPTR Sfx6C                             ; $6C
	BEPTR Sfx6D                             ; $6D
	BEPTR Sfx6E                             ; $6E
	BEPTR Sfx6F                             ; $6F
	BEPTR Sfx70                             ; $70
	BEPTR Sfx71                             ; $71
	BEPTR Sfx72                             ; $72
	BEPTR Sfx73                             ; $73
	BEPTR Sfx74                             ; $74
	BEPTR Sfx75                             ; $75
	BEPTR Sfx76                             ; $76
	BEPTR Sfx77                             ; $77
	BEPTR Sfx78                             ; $78
	BEPTR Sfx79                             ; $79
	BEPTR Sfx7A                             ; $7A
	BEPTR Sfx7B                             ; $7B
	BEPTR Sfx7C                             ; $7C
	BEPTR Sfx7D                             ; $7D

INCLUDE "MMX_SoundCommon.inc"


;; Music $0B
Music0B:
	db $00
	BEPTR Music0B_Ch1
	BEPTR Music0B_Ch2
	BEPTR Music0B_Ch3
	BEPTR Music0B_Ch4
Music0B_Ch1:
	OCTAVE 0
	HOLD 200
	INSTR 4
	DETUNE 1
.l4F5A:
	FLAGS $40
	TEMPO $022E
	DUTY $40
	PAN $11
	VOLUME $0A
	NOTE N4, 25       ; C_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N2, 25       ; C_4
	INSTR 4
	CONNECT
	NOTE N8, 24       ; B_3
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 24       ; B_3
	INSTR 4
	CONNECT
	NOTE N8, 23       ; A#3
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 23       ; A#3
	INSTR 4
	CONNECT
	NOTE N2, 21       ; G#3
	NOTE N2, 21       ; G#3
	INSTR 8
	NOTE N2, 21       ; G#3
	CONNECT
	NOTE N2, 21       ; G#3
	DUTY $80
	PAN $10
	INSTR 4
	REST N16
	DOTTED
	CONNECT
	OCTUP
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 16      ; D#5
	DOTTED
	CONNECT
	NOTE N16, 16      ; D#5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N8, 18       ; F_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N8, 18       ; F_5
	PAN $11
	INSTR 4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	REST N8
	PAN $10
	DOTTED
	NOTE N8, 18       ; F_5
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 8
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N16, 6       ; F_4
	INSTR 4
	DOTTED
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	DOTTED
	CONNECT
	NOTE N8, 8        ; G_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N8, 8        ; G_4
	DUTY $40
	INSTR 4
	NOTE N16, 11      ; A#4
	NOTE N16, 13      ; C_5
	DOTTED
	CONNECT
	NOTE N16, 11      ; A#4
	DOTTED
	CONNECT
	NOTE N16, 11      ; A#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	INSTR 4
	NOTE N8, 8        ; G_4
	NOTE N8, 4        ; D#4
	REST N8
	NOTE N8, 5        ; E_4
	REST N16
	REST N16
	DUTY $80
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	CONNECT
	NOTE N8, 3        ; D_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 3        ; D_4
	INSTR 4
	NOTE N16, 1       ; C_4
	NOTE N16, 3       ; D_4
	DOTTED
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 3        ; D_4
	NOTE N8, 4        ; D#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	CONNECT
	NOTE N16, 3       ; D_4
	CONNECT
	NOTE N16, 3       ; D_4
	DUTY $40
	NOTE N16, 15      ; D_5
	NOTE N16, 13      ; C_5
	NOTE N16, 11      ; A#4
	NOTE N8, 13       ; C_5
	NOTE N16, 15      ; D_5
	CONNECT
	NOTE N8, 11       ; A#4
	INSTR 8
	DOTTED
	NOTE N4, 11       ; A#4
	NOTE N16, 11      ; A#4
	DOTTED
	CONNECT
	NOTE N8, 11       ; A#4
	REST N16
	DUTY $00
	INSTR 4
	DOTTED
	NOTE N8, 3        ; D_4
	OCTUP
	NOTE N8, 23       ; A#3
	DOTTED
	NOTE N8, 20       ; G_3
	DUTY $80
	INSTR 8
	PAN $11
	VOLUME $06
	CONNECT
	NOTE N8, 29       ; E_4
	CONNECT
	NOTE N8, 29       ; E_4
	VOLUME $0B
	HOLD 180
	INSTR 4
	DOTTED
	NOTE N8, 30       ; F_4
	DOTTED
	NOTE N8, 30       ; F_4
	DOTTED
	NOTE N4, 30       ; F_4
	HOLD 220
	OCTUP
	NOTE N4, 9        ; G#4
	CONNECT
	NOTE N8, 8        ; G_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_4
	INSTR 4
	CONNECT
	NOTE N8, 7        ; F#4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 7        ; F#4
	HOLD 180
	INSTR 4
	DOTTED
	NOTE N8, 6        ; F_4
	DOTTED
	NOTE N8, 6        ; F_4
	NOTE N8, 6        ; F_4
	CONNECT
	NOTE N4, 6        ; F_4
	INSTR 8
	NOTE N4, 6        ; F_4
	NOTE N4, 6        ; F_4
	CONNECT
	NOTE N4, 6        ; F_4
	REST N8
	INSTR 4
	CONNECT
	NOTE N8, 4        ; D#4
	INSTR 8
	CONNECT
	NOTE N8, 4        ; D#4
	INSTR 4
	NOTE N8, 5        ; E_4
	DOTTED
	NOTE N8, 6        ; F_4
	DOTTED
	NOTE N8, 6        ; F_4
	HOLD 220
	DOTTED
	NOTE N4, 6        ; F_4
	NOTE N4, 16       ; D#5
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	HOLD 180
	INSTR 4
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	CONNECT
	NOTE N8, 13       ; C_5
	INSTR 8
	DOTTED
	NOTE N4, 13       ; C_5
	DOTTED
	NOTE N4, 13       ; C_5
	DOTTED
	NOTE N4, 13       ; C_5
	CONNECT
	NOTE N4, 13       ; C_5
	DOTTED
	REST N16
	PAN $10
	VOLUME $07
	INSTR 4
.l50AC:
	FLAGS $00
	NOTE N16, 30      ; F_4
	NOTE N16, 31      ; F#4
	LOOP2 7, .l50AC
	VOLUME $08
.l50B6:
	FLAGS $00
	NOTE N16, 30      ; F_4
	NOTE N16, 31      ; F#4
	LOOP2 7, .l50B6
	VOLUME $09
.l50C0:
	FLAGS $08
	NOTE N16, 18      ; F_5
	NOTE N16, 19      ; F#5
	LOOP2 7, .l50C0
	VOLUME $0A
.l50CA:
	FLAGS $08
	NOTE N16, 18      ; F_5
	NOTE N16, 19      ; F#5
	LOOP2 3, .l50CA
	VOLUME $0B
.l50D4:
	FLAGS $08
	NOTE N16, 18      ; F_5
	NOTE N16, 19      ; F#5
	LOOP2 2, .l50D4
	NOTE N32, 18      ; F_5
	OCTAVE 0
	JUMP .l4F5A
	END                ; unreachable
Music0B_Ch2:
	OCTAVE 0
	HOLD 200
.l50E7:
	FLAGS $40
	TEMPO $022E
	DUTY $00
	VOLUME $0D
	INSTR 4
	DOTTED
	NOTE N4, 28       ; D#4
	INSTR 8
	NOTE N2, 28       ; D#4
	CONNECT
	NOTE N8, 28       ; D#4
	INSTR 4
	CONNECT
	NOTE N4, 27       ; D_4
	INSTR 8
	CONNECT
	NOTE N4, 27       ; D_4
	INSTR 4
	CONNECT
	NOTE N4, 26       ; C#4
	INSTR 8
	CONNECT
	NOTE N4, 26       ; C#4
	INSTR 4
	CONNECT
	NOTE N2, 25       ; C_4
	NOTE N2, 25       ; C_4
	INSTR 8
	NOTE N2, 25       ; C_4
	CONNECT
	NOTE N2, 25       ; C_4
	DUTY $80
	INSTR 4
	DOTTED
	CONNECT
	OCTUP
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 16      ; D#5
	DOTTED
	CONNECT
	NOTE N16, 16      ; D#5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N8, 18       ; F_5
	INSTR 8
	CONNECT
	NOTE N4, 18       ; F_5
	INSTR 4
	VOLUME $09
	NOTE N16, 13      ; C_5
	NOTE N16, 13      ; C_5
	NOTE N16, 13      ; C_5
	REST N16
	VOLUME $0D
	DOTTED
	NOTE N8, 18       ; F_5
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N8, 9        ; G#4
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 4
	CONNECT
	NOTE N16, 4       ; D#4
	CONNECT
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 11       ; A#4
	NOTE N8, 9        ; G#4
	DOTTED
	CONNECT
	NOTE N8, 8        ; G_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N8, 8        ; G_4
	DUTY $40
	INSTR 4
	NOTE N16, 11      ; A#4
	NOTE N16, 13      ; C_5
	DOTTED
	CONNECT
	NOTE N16, 11      ; A#4
	DOTTED
	CONNECT
	NOTE N16, 11      ; A#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	NOTE N8, 8        ; G_4
	NOTE N8, 4        ; D#4
	REST N8
	NOTE N8, 5        ; E_4
	REST N8
	DUTY $80
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	CONNECT
	NOTE N8, 3        ; D_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 3        ; D_4
	INSTR 4
	NOTE N16, 1       ; C_4
	NOTE N16, 3       ; D_4
	DOTTED
	NOTE N8, 4        ; D#4
	DOTTED
	NOTE N8, 3        ; D_4
	NOTE N8, 4        ; D#4
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N16, 9       ; G#4
	INSTR 4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	DOTTED
	CONNECT
	NOTE N16, 4       ; D#4
	NOTE N8, 3        ; D_4
	DUTY $40
	NOTE N16, 15      ; D_5
	NOTE N16, 13      ; C_5
	NOTE N16, 11      ; A#4
	NOTE N8, 13       ; C_5
	NOTE N16, 15      ; D_5
	CONNECT
	NOTE N8, 11       ; A#4
	INSTR 8
	DOTTED
	NOTE N4, 11       ; A#4
	NOTE N8, 11       ; A#4
	CONNECT
	NOTE N8, 11       ; A#4
	REST N16
	DUTY $00
	INSTR 4
	DOTTED
	NOTE N8, 3        ; D_4
	OCTUP
	NOTE N8, 23       ; A#3
	NOTE N4, 20       ; G_3
	DUTY $80
	INSTR 8
	CONNECT
	OCTUP
	NOTE N8, 12       ; B_4
	CONNECT
	NOTE N8, 12       ; B_4
	HOLD 160
	INSTR 4
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N4, 13       ; C_5
	HOLD 200
	NOTE N4, 16       ; D#5
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#5
	HOLD 140
	INSTR 4
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	CONNECT
	NOTE N4, 13       ; C_5
	INSTR 8
	NOTE N4, 13       ; C_5
	NOTE N4, 13       ; C_5
	CONNECT
	NOTE N4, 13       ; C_5
	REST N8
	INSTR 4
	CONNECT
	NOTE N8, 11       ; A#4
	INSTR 8
	CONNECT
	NOTE N8, 11       ; A#4
	INSTR 4
	NOTE N8, 12       ; B_4
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N8, 13       ; C_5
	DOTTED
	NOTE N4, 13       ; C_5
	HOLD 200
	NOTE N4, 21       ; G#5
	INSTR 4
	CONNECT
	NOTE N4, 20       ; G_5
	INSTR 8
	CONNECT
	NOTE N4, 20       ; G_5
	INSTR 4
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 8
	CONNECT
	NOTE N4, 19       ; F#5
	HOLD 160
	INSTR 4
	DOTTED
	NOTE N8, 18       ; F_5
	DOTTED
	NOTE N8, 18       ; F_5
	NOTE N8, 18       ; F_5
	CONNECT
	NOTE N8, 18       ; F_5
	INSTR 8
	DOTTED
	NOTE N4, 18       ; F_5
	DOTTED
	NOTE N4, 18       ; F_5
	DOTTED
	NOTE N4, 18       ; F_5
	CONNECT
	NOTE N4, 18       ; F_5
	DUTY $80
	INSTR 4
	VOLUME $09
.l522A:
	FLAGS $00
	NOTE N16, 30      ; F_4
	NOTE N16, 31      ; F#4
	LOOP2 7, .l522A
	VOLUME $0A
.l5234:
	FLAGS $00
	NOTE N16, 30      ; F_4
	NOTE N16, 31      ; F#4
	LOOP2 7, .l5234
	VOLUME $0B
.l523E:
	FLAGS $08
	NOTE N16, 18      ; F_5
	NOTE N16, 19      ; F#5
	LOOP2 7, .l523E
	VOLUME $0D
.l5248:
	FLAGS $08
	NOTE N16, 18      ; F_5
	NOTE N16, 19      ; F#5
	LOOP2 3, .l5248
	VOLUME $0E
.l5252:
	FLAGS $08
	NOTE N16, 18      ; F_5
	NOTE N16, 19      ; F#5
	LOOP2 3, .l5252
	OCTAVE 0
	JUMP .l50E7
	END                ; unreachable
Music0B_Ch3:
	OCTAVE 0
	VOLUME $03
	INSTR 16
	TRANSP -12
	HOLD 200
	DUTY $80
.l526C:
	FLAGS $00
	TEMPO $022E
.l5271:
	FLAGS $00
	NOTE N8, 30       ; F_4
	OCTUP
	NOTE N16, 18      ; F_5
	DOTTED
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	DOTTED
	NOTE N8, 6        ; F_4
	DOTTED
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N16, 18      ; F_5
	DOTTED
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	DOTTED
	NOTE N8, 11       ; A#4
	DOTTED
	NOTE N8, 9        ; G#4
	NOTE N8, 5        ; E_4
	LOOP2 1, .l5271
.l528C:
	FLAGS $00
.l528E:
	FLAGS $00
	NOTE N16, 30      ; F_4
	REST N16
	NOTE N16, 30      ; F_4
	NOTE N16, 30      ; F_4
	LOOP3 2, .l528E
	NOTE N16, 30      ; F_4
	NOTE N8, 28       ; D#4
	NOTE N16, 28      ; D#4
	LOOP2 5, .l528C
.l529F:
	FLAGS $00
	NOTE N16, 28      ; D#4
	REST N16
	NOTE N16, 28      ; D#4
	NOTE N16, 28      ; D#4
	LOOP2 2, .l529F
	NOTE N16, 28      ; D#4
	OCTUP
	NOTE N8, 11       ; A#4
	NOTE N16, 3       ; D_4
.l52AD:
	FLAGS $00
	NOTE N16, 28      ; D#4
	REST N16
	NOTE N16, 28      ; D#4
	NOTE N16, 28      ; D#4
	LOOP2 2, .l52AD
	NOTE N16, 28      ; D#4
	DOTTED
	OCTUP
	NOTE N8, 12       ; B_4
.l52BB:
	FLAGS $00
	NOTE N16, 30      ; F_4
	NOTE N16, 30      ; F_4
	OCTUP
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	NOTE N16, 7       ; F#4
	NOTE N16, 7       ; F#4
	LOOP2 15, .l52BB
.l52CA:
	FLAGS $00
	NOTE N8, 30       ; F_4
	OCTUP
	NOTE N16, 18      ; F_5
	DOTTED
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	DOTTED
	NOTE N8, 6        ; F_4
	DOTTED
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	NOTE N8, 6        ; F_4
	NOTE N16, 18      ; F_5
	DOTTED
	NOTE N8, 4        ; D#4
	NOTE N8, 5        ; E_4
	DOTTED
	NOTE N8, 11       ; A#4
	DOTTED
	NOTE N8, 9        ; G#4
	NOTE N8, 5        ; E_4
	LOOP2 1, .l52CA
	OCTAVE 0
	JUMP .l526C
	END                ; unreachable
Music0B_Ch4:
	OCTAVE 0
	VOLUME $06
	HOLD 50
.l52F1:
	FLAGS $00
	TEMPO $022E
.l52F6:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N8, 9
	NOTE N16, 9
	INSTR 14
	NOTE N8, 13
	LOOP1 6, .l52F6
	INSTR 14
	TRIPLET
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	REST N16
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
.l5317:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	REST N16
	NOTE N16, 9
	INSTR 14
	NOTE N8, 13
	LOOP1 14, .l5317
	INSTR 10
	NOTE N8, 9
	INSTR 14
	TRIPLET
	NOTE N32, 14
	NOTE N32, 14
	NOTE N32, 14
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
.l533A:
	FLAGS $00
.l533C:
	FLAGS $00
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 9
	LOOP1 14, .l533C
	INSTR 14
	TRIPLET
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	LOOP2 1, .l533A
.l5357:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	REST N16
	NOTE N16, 9
	INSTR 14
	NOTE N8, 13
	LOOP1 7, .l5357
	OCTAVE 0
	JUMP .l52F1
	END                ; unreachable

;; Music $0C
Music0C:
	db $00
	BEPTR Music0C_Ch1
	BEPTR Music0C_Ch2
	BEPTR Music0C_Ch3
	BEPTR Music0C_Ch4
Music0C_Ch1:
	OCTAVE 0
.l537C:
	FLAGS $00
	TEMPO $0216
	VOLUME $0D
	PAN $11
	HOLD 200
	INSTR 7
	DUTY $40
	DETUNE -1
	NOTE N8, 24       ; B_3
	NOTE N8, 27       ; D_4
	NOTE N8, 26       ; C#4
	NOTE N8, 24       ; B_3
	NOTE N4, 29       ; E_4
	NOTE N8, 26       ; C#4
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N8, 27       ; D_4
	NOTE N8, 24       ; B_3
	NOTE N8, 26       ; C#4
	NOTE N8, 22       ; A_3
	NOTE N4, 20       ; G_3
	NOTE N4, 22       ; A_3
	NOTE N8, 24       ; B_3
	NOTE N8, 27       ; D_4
	NOTE N8, 26       ; C#4
	NOTE N8, 24       ; B_3
	NOTE N4, 29       ; E_4
	NOTE N8, 26       ; C#4
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N8, 27       ; D_4
	NOTE N8, 24       ; B_3
	NOTE N8, 26       ; C#4
	NOTE N8, 22       ; A_3
	NOTE N4, 20       ; G_3
	NOTE N4, 22       ; A_3
	NOTE N8, 24       ; B_3
	NOTE N8, 27       ; D_4
	NOTE N8, 26       ; C#4
	NOTE N8, 24       ; B_3
	NOTE N4, 29       ; E_4
	NOTE N8, 26       ; C#4
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N8, 27       ; D_4
	NOTE N8, 24       ; B_3
	NOTE N8, 26       ; C#4
	NOTE N8, 22       ; A_3
	NOTE N4, 20       ; G_3
	NOTE N4, 22       ; A_3
	NOTE N8, 24       ; B_3
	NOTE N8, 27       ; D_4
	NOTE N8, 26       ; C#4
	NOTE N8, 24       ; B_3
	NOTE N4, 29       ; E_4
	NOTE N8, 26       ; C#4
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N8, 27       ; D_4
	NOTE N8, 24       ; B_3
	NOTE N8, 26       ; C#4
	NOTE N8, 22       ; A_3
	NOTE N4, 20       ; G_3
	NOTE N4, 22       ; A_3
	VOLUME $08
	DUTY $80
	INSTR 6
	TRIPLET
	OCTUP
	NOTE N16, 21      ; G#5
	NOTE N16, 22      ; A_5
	NOTE N16, 23      ; A#5
	DOTTED
	TRIPLET
	CONNECT
	NOTE N4, 24       ; B_5
	INSTR 8
	NOTE N2, 24       ; B_5
	DOTTED
	CONNECT
	NOTE N4, 24       ; B_5
	REST N8
	INSTR 6
	CONNECT
	NOTE N4, 24       ; B_5
	INSTR 8
	NOTE N4, 24       ; B_5
	CONNECT
	NOTE N2, 24       ; B_5
	REST N4
	VOLUME $0A
	PAN $10
	INSTR 4
	NOTE N4, 11       ; A#4
	NOTE N32, 10      ; A_4
	DOTTED
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	NOTE N32, 12      ; B_4
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 5
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 17       ; E_5
	REST N8
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 4
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 4
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N2, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	NOTE N32, 8       ; G_4
	DOTTED
	CONNECT
	NOTE N16, 10      ; A_4
	INSTR 8
	NOTE N4, 10       ; A_4
	CONNECT
	NOTE N4, 10       ; A_4
	REST N8
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N32, 14      ; C#5
	DOTTED
	CONNECT
	NOTE N16, 15      ; D_5
	NOTE N4, 15       ; D_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	NOTE N32, 14      ; C#5
	TRIPLET
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N64, 15      ; D_5
	INSTR 4
	TRIPLET
	NOTE N32, 16      ; D#5
	TRIPLET
	CONNECT
	NOTE N2, 17       ; E_5
	NOTE N64, 17      ; E_5
	INSTR 8
	DOTTED
	TRIPLET
	CONNECT
	NOTE N4, 17       ; E_5
	INSTR 4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 8
	NOTE N8, 10       ; A_4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 4
	NOTE N32, 10      ; A_4
	TRIPLET
	CONNECT
	NOTE N2, 12       ; B_4
	NOTE N64, 12      ; B_4
	INSTR 8
	TRIPLET
	NOTE N2, 12       ; B_4
	CONNECT
	NOTE N2, 12       ; B_4
	REST N2
	INSTR 4
	NOTE N32, 10      ; A_4
	DOTTED
	CONNECT
	NOTE N8, 12       ; B_4
	NOTE N32, 12      ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 5
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 17       ; E_5
	REST N8
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 8
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 4
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	NOTE N8, 14       ; C#5
	CONNECT
	NOTE N8, 17       ; E_5
	INSTR 8
	CONNECT
	NOTE N8, 17       ; E_5
	INSTR 4
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 8
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N32, 10      ; A_4
	DOTTED
	CONNECT
	NOTE N16, 12      ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	NOTE N16, 12      ; B_4
	REST N16
	NOTE N4, 12       ; B_4
	DOTTED
	NOTE N4, 7        ; F#4
	NOTE N32, 8       ; G_4
	DOTTED
	CONNECT
	NOTE N8, 10       ; A_4
	CONNECT
	NOTE N32, 10      ; A_4
	NOTE N16, 10      ; A_4
	REST N16
	NOTE N32, 8       ; G_4
	DOTTED
	CONNECT
	NOTE N8, 10       ; A_4
	CONNECT
	NOTE N32, 10      ; A_4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	DOTTED
	CONNECT
	NOTE N4, 12       ; B_4
	NOTE N2, 12       ; B_4
	INSTR 8
	NOTE N8, 12       ; B_4
	CONNECT
	NOTE N2, 12       ; B_4
	REST N8
	DUTY $40
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N32, 10      ; A_4
	DOTTED
	CONNECT
	NOTE N16, 12      ; B_4
	NOTE N4, 12       ; B_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 8        ; G_4
	INSTR 8
	CONNECT
	NOTE N4, 8        ; G_4
	INSTR 4
	NOTE N32, 9       ; G#4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 8
	TRIPLET
	NOTE N2, 10       ; A_4
	CONNECT
	NOTE N64, 10      ; A_4
	INSTR 4
	TRIPLET
	NOTE N32, 12      ; B_4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	NOTE N32, 14      ; C#5
	REST N16
	NOTE N32, 14      ; C#5
	DOTTED
	CONNECT
	NOTE N16, 15      ; D_5
	INSTR 8
	NOTE N1, 15       ; D_5
	CONNECT
	NOTE N2, 15       ; D_5
	REST N2
	INSTR 4
	NOTE N4, 12       ; B_4
	NOTE N32, 12      ; B_4
	REST N32
	REST N16
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 8        ; G_4
	INSTR 8
	CONNECT
	NOTE N4, 8        ; G_4
	INSTR 4
	NOTE N2, 10       ; A_4
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#5
	DOTTED
	NOTE N16, 14      ; C#5
	CONNECT
	NOTE N32, 14      ; C#5
	OCTAVE 0
	JUMP .l537C
	END                ; unreachable
Music0C_Ch2:
	OCTAVE 0
.l5536:
	FLAGS $00
	TEMPO $0216
	VOLUME $0D
	DUTY $40
	HOLD 200
	INSTR 4
	PAN $10
	DETUNE 0
	NOTE N32, 22      ; A_3
	DOTTED
	NOTE N16, 24      ; B_3
	NOTE N32, 22      ; A_3
	TRIPLET
	CONNECT
	NOTE N1, 24       ; B_3
	NOTE N16, 24      ; B_3
	CONNECT
	NOTE N64, 24      ; B_3
	TRIPLET
	NOTE N8, 24       ; B_3
	REST N8
	NOTE N16, 24      ; B_3
	REST N16
	NOTE N8, 24       ; B_3
	REST N8
	NOTE N4, 25       ; C_4
	NOTE N32, 26      ; C#4
	DOTTED
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N32, 27      ; D_4
	NOTE N32, 22      ; A_3
	TRIPLET
	CONNECT
	NOTE N2, 24       ; B_3
	CONNECT
	NOTE N64, 24      ; B_3
	TRIPLET
	NOTE N32, 22      ; A_3
	TRIPLET
	CONNECT
	NOTE N2, 24       ; B_3
	CONNECT
	NOTE N64, 24      ; B_3
	TRIPLET
	NOTE N32, 22      ; A_3
	DOTTED
	CONNECT
	NOTE N8, 24       ; B_3
	NOTE N32, 24      ; B_3
	CONNECT
	NOTE N8, 24       ; B_3
	NOTE N16, 24      ; B_3
	REST N16
	NOTE N8, 24       ; B_3
	REST N8
	NOTE N4, 25       ; C_4
	NOTE N32, 26      ; C#4
	DOTTED
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N32, 27      ; D_4
	NOTE N32, 22      ; A_3
	DOTTED
	NOTE N16, 24      ; B_3
	NOTE N32, 22      ; A_3
	TRIPLET
	CONNECT
	NOTE N1, 24       ; B_3
	NOTE N16, 24      ; B_3
	CONNECT
	NOTE N64, 24      ; B_3
	TRIPLET
	NOTE N8, 24       ; B_3
	REST N8
	NOTE N16, 24      ; B_3
	REST N16
	NOTE N8, 24       ; B_3
	REST N8
	NOTE N4, 25       ; C_4
	NOTE N32, 26      ; C#4
	DOTTED
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N32, 27      ; D_4
	NOTE N32, 22      ; A_3
	TRIPLET
	CONNECT
	NOTE N2, 24       ; B_3
	CONNECT
	NOTE N64, 24      ; B_3
	TRIPLET
	NOTE N32, 22      ; A_3
	TRIPLET
	CONNECT
	NOTE N2, 24       ; B_3
	CONNECT
	NOTE N64, 24      ; B_3
	TRIPLET
	NOTE N32, 22      ; A_3
	DOTTED
	CONNECT
	NOTE N8, 24       ; B_3
	NOTE N32, 24      ; B_3
	CONNECT
	NOTE N8, 24       ; B_3
	NOTE N16, 24      ; B_3
	REST N16
	NOTE N8, 24       ; B_3
	REST N8
	NOTE N4, 25       ; C_4
	NOTE N32, 26      ; C#4
	DOTTED
	CONNECT
	NOTE N8, 27       ; D_4
	CONNECT
	NOTE N32, 27      ; D_4
	HOLD 150
	PAN $11
	TRIPLET
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	TRIPLET
	NOTE N32, 18      ; F_3
	DOTTED
	CONNECT
	NOTE N8, 19       ; F#3
	CONNECT
	NOTE N32, 19      ; F#3
	TRIPLET
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	TRIPLET
	NOTE N32, 18      ; F_3
	DOTTED
	CONNECT
	NOTE N8, 19       ; F#3
	CONNECT
	NOTE N32, 19      ; F#3
	NOTE N32, 18      ; F_3
	CONNECT
	NOTE N8, 20       ; G_3
	CONNECT
	NOTE N32, 20      ; G_3
	NOTE N16, 20      ; G_3
	NOTE N4, 20       ; G_3
	TRIPLET
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	TRIPLET
	NOTE N32, 18      ; F_3
	DOTTED
	CONNECT
	NOTE N8, 19       ; F#3
	CONNECT
	NOTE N32, 19      ; F#3
	TRIPLET
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	NOTE N8, 19       ; F#3
	TRIPLET
	NOTE N32, 18      ; F_3
	DOTTED
	CONNECT
	NOTE N8, 19       ; F#3
	CONNECT
	NOTE N32, 19      ; F#3
	NOTE N32, 16      ; D#3
	CONNECT
	NOTE N8, 18       ; F_3
	CONNECT
	NOTE N32, 18      ; F_3
	NOTE N16, 18      ; F_3
	NOTE N4, 18       ; F_3
	DUTY $80
	HOLD 200
	INSTR 4
	OCTUP
	NOTE N32, 14      ; C#5
	DOTTED
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N32, 15      ; D_5
	INSTR 4
	NOTE N8, 14       ; C#5
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 17       ; E_5
	REST N8
	CONNECT
	NOTE N8, 19       ; F#5
	INSTR 8
	NOTE N4, 19       ; F#5
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 4
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	CONNECT
	NOTE N8, 17       ; E_5
	INSTR 8
	CONNECT
	NOTE N2, 17       ; E_5
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 8
	CONNECT
	NOTE N2, 10       ; A_4
	INSTR 4
	REST N8
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	CONNECT
	NOTE N8, 12       ; B_4
	NOTE N4, 12       ; B_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	DOTTED
	NOTE N4, 12       ; B_4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N2, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 8
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 4
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 8
	NOTE N4, 12       ; B_4
	NOTE N2, 12       ; B_4
	CONNECT
	NOTE N2, 12       ; B_4
	VOLUME $08
	INSTR 4
	OCTUP
	NOTE N16, 12      ; B_2
	NOTE N16, 12      ; B_2
	NOTE N16, 15      ; D_3
	NOTE N16, 14      ; C#3
	REST N16
	NOTE N16, 14      ; C#3
	NOTE N8, 13       ; C_3
	VOLUME $0D
	OCTUP
	NOTE N32, 13      ; C_5
	DOTTED
	CONNECT
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N32, 15      ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 17       ; E_5
	REST N8
	NOTE N32, 17      ; E_5
	DOTTED
	CONNECT
	NOTE N16, 19      ; F#5
	NOTE N4, 19       ; F#5
	INSTR 8
	CONNECT
	NOTE N4, 19       ; F#5
	REST N8
	INSTR 4
	NOTE N32, 18      ; F_5
	DOTTED
	CONNECT
	NOTE N8, 20       ; G_5
	CONNECT
	NOTE N32, 20      ; G_5
	NOTE N8, 19       ; F#5
	CONNECT
	NOTE N4, 17       ; E_5
	INSTR 8
	CONNECT
	NOTE N4, 17       ; E_5
	REST N8
	INSTR 4
	NOTE N4, 14       ; C#5
	CONNECT
	NOTE N8, 17       ; E_5
	NOTE N4, 17       ; E_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 17       ; E_5
	INSTR 4
	NOTE N8, 19       ; F#5
	NOTE N8, 17       ; E_5
	CONNECT
	NOTE N8, 15       ; D_5
	NOTE N4, 15       ; D_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	DOTTED
	NOTE N4, 12       ; B_4
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	REST N8
	INSTR 4
	CONNECT
	NOTE N8, 17       ; E_5
	INSTR 8
	CONNECT
	NOTE N8, 17       ; E_5
	REST N8
	INSTR 4
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N2, 15       ; D_5
	REST N2
	REST N8
	DUTY $40
	INSTR 4
	NOTE N8, 19       ; F#5
	NOTE N8, 17       ; E_5
	CONNECT
	NOTE N8, 15       ; D_5
	NOTE N8, 15       ; D_5
	INSTR 8
	NOTE N4, 15       ; D_5
	CONNECT
	NOTE N8, 15       ; D_5
	REST N8
	INSTR 4
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 8
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 4
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	NOTE N1, 12       ; B_4
	CONNECT
	NOTE N2, 12       ; B_4
	REST N2
	INSTR 4
	NOTE N4, 15       ; D_5
	NOTE N32, 15      ; D_5
	REST N32
	REST N16
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 4
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	NOTE N2, 14       ; C#5
	DOTTED
	CONNECT
	NOTE N4, 10       ; A_4
	DOTTED
	NOTE N16, 10      ; A_4
	CONNECT
	NOTE N32, 10      ; A_4
	OCTAVE 0
	JUMP .l5536
	END                ; unreachable
Music0C_Ch3:
	OCTAVE 0
.l571D:
	FLAGS $08
	TEMPO $0216
	VOLUME $03
	DUTY $C0
	INSTR 16
	TRANSP -12
	PAN $11
	HOLD 250
	NOTE N8, 12       ; B_4
	DOTTED
	NOTE N2, 12       ; B_4
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	DOTTED
	NOTE N4, 12       ; B_4
	HOLD 160
	NOTE N4, 13       ; C_5
	NOTE N4, 15       ; D_5
	HOLD 250
	NOTE N8, 12       ; B_4
	DOTTED
	NOTE N2, 12       ; B_4
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	DOTTED
	NOTE N4, 12       ; B_4
	HOLD 160
	NOTE N4, 13       ; C_5
	NOTE N4, 15       ; D_5
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 15       ; D_5
	NOTE N8, 15       ; D_5
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 12       ; B_4
	VOLUME $02
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	VOLUME $03
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 15       ; D_5
	NOTE N8, 15       ; D_5
	TRIPLET
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	TRIPLET
	NOTE N4, 12       ; B_4
	TRIPLET
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	TRIPLET
	NOTE N4, 12       ; B_4
	DOTTED
	NOTE N8, 13       ; C_5
	NOTE N16, 13      ; C_5
	NOTE N4, 13       ; C_5
	TRIPLET
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	TRIPLET
	NOTE N4, 12       ; B_4
	TRIPLET
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	TRIPLET
	NOTE N4, 12       ; B_4
	DOTTED
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N4, 11       ; A#4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 150
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 15      ; D_5
	NOTE N16, 14      ; C#5
	REST N16
	NOTE N16, 14      ; C#5
	NOTE N8, 13       ; C_5
	HOLD 150
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 15      ; D_5
	NOTE N16, 14      ; C#5
	REST N16
	NOTE N16, 14      ; C#5
	NOTE N8, 13       ; C_5
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 200
	NOTE N8, 8        ; G_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 200
	NOTE N8, 10       ; A_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 80
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 200
	NOTE N8, 12       ; B_4
	HOLD 150
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 15      ; D_5
	NOTE N16, 14      ; C#5
	REST N16
	NOTE N16, 14      ; C#5
	NOTE N8, 13       ; C_5
	HOLD 150
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 15      ; D_5
	NOTE N16, 14      ; C#5
	REST N16
	NOTE N16, 14      ; C#5
	NOTE N8, 13       ; C_5
	HOLD 160
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 240
	NOTE N8, 8        ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	REST N16
	NOTE N16, 8       ; G_4
	HOLD 160
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 240
	NOTE N8, 8        ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	REST N16
	NOTE N16, 8       ; G_4
	HOLD 160
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 240
	NOTE N8, 10       ; A_4
	NOTE N16, 22      ; A_5
	NOTE N16, 10      ; A_4
	REST N16
	NOTE N16, 10      ; A_4
	HOLD 160
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 240
	NOTE N8, 10       ; A_4
	NOTE N16, 22      ; A_5
	NOTE N16, 10      ; A_4
	REST N16
	NOTE N16, 10      ; A_4
	HOLD 160
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 240
	NOTE N8, 12       ; B_4
	NOTE N16, 24      ; B_5
	NOTE N16, 12      ; B_4
	REST N16
	NOTE N16, 12      ; B_4
	HOLD 160
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 240
	NOTE N8, 12       ; B_4
	NOTE N16, 24      ; B_5
	NOTE N16, 12      ; B_4
	REST N16
	NOTE N16, 12      ; B_4
	HOLD 160
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 240
	NOTE N8, 12       ; B_4
	NOTE N16, 24      ; B_5
	NOTE N16, 12      ; B_4
	REST N16
	NOTE N16, 12      ; B_4
	HOLD 160
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	HOLD 240
	NOTE N8, 12       ; B_4
	NOTE N16, 24      ; B_5
	NOTE N16, 12      ; B_4
	REST N16
	NOTE N16, 12      ; B_4
	HOLD 160
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 240
	NOTE N8, 8        ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	REST N16
	NOTE N16, 8       ; G_4
	HOLD 160
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
	HOLD 240
	NOTE N8, 8        ; G_4
	NOTE N16, 20      ; G_5
	NOTE N16, 8       ; G_4
	REST N16
	NOTE N16, 8       ; G_4
	HOLD 160
	NOTE N16, 10      ; A_4
	NOTE N16, 10      ; A_4
	HOLD 240
	NOTE N8, 10       ; A_4
	NOTE N16, 22      ; A_5
	NOTE N16, 10      ; A_4
	REST N16
	NOTE N16, 10      ; A_4
	NOTE N16, 22      ; A_5
	NOTE N16, 10      ; A_4
	REST N16
	NOTE N16, 10      ; A_4
	REST N16
	NOTE N16, 10      ; A_4
	NOTE N8, 10       ; A_4
	OCTAVE 0
	JUMP .l571D
	END                ; unreachable
Music0C_Ch4:
	OCTAVE 0
.l59DE:
	FLAGS $00
	TEMPO $0216
	VOLUME $06
	DUTY $00
	INSTR 14
	HOLD 40
	DETUNE 0
	PAN $11
	NOTE N4, 13
	INSTR 10
	NOTE N4, 9
	REST N4
	NOTE N4, 9
	REST N4
	NOTE N4, 9
	REST N4
	INSTR 14
	NOTE N8, 13
	CONNECT
	NOTE N8, 13
	CONNECT
	NOTE N4, 13
	REST N8
	INSTR 10
	NOTE N4, 9
	REST N8
	NOTE N4, 9
	REST N8
	NOTE N4, 9
	REST N8
	NOTE N4, 9
	INSTR 14
	NOTE N4, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 15
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 15
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 15
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 15
	NOTE N8, 13
	NOTE N8, 13
	NOTE N8, 13
	NOTE N4, 13
	INSTR 10
	NOTE N4, 9
	NOTE N4, 9
	NOTE N4, 9
	NOTE N4, 9
	INSTR 14
	TRIPLET
	NOTE N8, 13
	NOTE N8, 13
	NOTE N8, 13
	TRIPLET
	NOTE N4, 13
	INSTR 10
	NOTE N4, 9
	NOTE N4, 9
	NOTE N4, 9
	NOTE N4, 9
	INSTR 14
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	INSTR 14
	TRIPLET
	NOTE N32, 15
	NOTE N32, 15
	NOTE N32, 15
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	OCTAVE 0
	JUMP .l59DE
	END                ; unreachable

;; Music $0D
Music0D:
	db $00
	BEPTR Music0D_Ch1
	BEPTR Music0D_Ch2
	BEPTR Music0D_Ch3
	BEPTR Music0D_Ch4
Music0D_Ch1:
	OCTAVE 0
	INSTR 4
	HOLD 200
	DETUNE -1
.l5D66:
	FLAGS $08
	TEMPO $0249
.l5D6B:
	FLAGS $08
	VOLUME $0B
	DUTY $40
	PAN $11
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	DOTTED
	REST N8
	PAN $10
	NOTE N32, 20      ; G_5
	DOTTED
	CONNECT
	NOTE N8, 21       ; G#5
	CONNECT
	NOTE N32, 21      ; G#5
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N32, 18      ; F_5
	CONNECT
	NOTE N8, 20       ; G_5
	CONNECT
	NOTE N32, 20      ; G_5
	PAN $11
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	DOTTED
	REST N8
	PAN $10
	NOTE N4, 19       ; F#5
	NOTE N8, 9        ; G#4
	NOTE N32, 16      ; D#5
	CONNECT
	NOTE N8, 18       ; F_5
	CONNECT
	NOTE N32, 18      ; F_5
	LOOP2 1, .l5D6B
	DUTY $80
	PAN $11
	NOTE N8, 4        ; D#4
	VOLUME $09
	NOTE N8, 4        ; D#4
	VOLUME $0B
	PAN $10
	REST N16
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N16
	PAN $11
	CONNECT
	NOTE N8, 3        ; D_4
	INSTR 8
	CONNECT
	NOTE N8, 3        ; D_4
	VOLUME $09
	INSTR 4
	NOTE N8, 3        ; D_4
	REST N16
	VOLUME $0B
	PAN $10
	NOTE N32, 11      ; A#4
	DOTTED
	NOTE N16, 12      ; B_4
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 8       ; G_4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 7        ; F#4
	NOTE N16, 8       ; G_4
	PAN $11
	NOTE N8, 4        ; D#4
	VOLUME $09
	NOTE N8, 4        ; D#4
	REST N16
	PAN $10
	VOLUME $0B
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N16
	PAN $11
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 8
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 4
	VOLUME $09
	NOTE N8, 6        ; F_4
	REST N16
	PAN $10
	VOLUME $0B
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	REST N8
	NOTE N32, 8       ; G_4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 12       ; B_4
	NOTE N16, 9       ; G#4
	PAN $11
	NOTE N8, 4        ; D#4
	VOLUME $09
	NOTE N8, 4        ; D#4
	REST N16
	VOLUME $0B
	PAN $10
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N16
	PAN $11
	CONNECT
	NOTE N8, 3        ; D_4
	INSTR 8
	CONNECT
	NOTE N8, 3        ; D_4
	INSTR 4
	VOLUME $09
	NOTE N8, 3        ; D_4
	REST N16
	VOLUME $0B
	PAN $10
	NOTE N32, 15      ; D_5
	DOTTED
	NOTE N16, 16      ; D#5
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 8       ; G_4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 7        ; F#4
	NOTE N16, 8       ; G_4
	PAN $11
	NOTE N8, 4        ; D#4
	VOLUME $09
	NOTE N16, 4       ; D#4
	VOLUME $0B
	PAN $10
	NOTE N32, 15      ; D_5
	DOTTED
	NOTE N16, 16      ; D#5
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N16
	PAN $11
	CONNECT
	NOTE N8, 6        ; F_4
	INSTR 8
	CONNECT
	NOTE N8, 6        ; F_4
	VOLUME $09
	INSTR 4
	NOTE N16, 6       ; F_4
	VOLUME $0B
	PAN $10
	NOTE N8, 9        ; G#4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 7       ; F#4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 7        ; F#4
	NOTE N16, 8       ; G_4
	DUTY $40
	VOLUME $0A
.l5E4D:
	FLAGS $08
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	NOTE N16, 14      ; C#5
	NOTE N16, 10      ; A_4
	LOOP1 3, .l5E4D
.l5E73:
	FLAGS $00
	VOLUME $0F
	NOTE N4, 21       ; G#3
	NOTE N16, 21      ; G#3
	REST N16
	DOTTED
	NOTE N4, 21       ; G#3
	NOTE N8, 21       ; G#3
	REST N8
	NOTE N8, 21       ; G#3
	REST N8
	NOTE N16, 21      ; G#3
	REST N16
	DOTTED
	NOTE N4, 21       ; G#3
	NOTE N16, 21      ; G#3
	REST N16
	NOTE N8, 21       ; G#3
	LOOP1 1, .l5E73
	OCTAVE 0
	JUMP .l5D66
	END                ; unreachable
Music0D_Ch2:
	OCTAVE 0
	VOLUME $0D
	INSTR 4
	HOLD 160
.l5E99:
	FLAGS $08
	TEMPO $0249
.l5E9E:
	FLAGS $08
	DUTY $40
	NOTE N8, 21       ; G#5
	NOTE N8, 20       ; G_5
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N32, 20      ; G_5
	DOTTED
	CONNECT
	NOTE N8, 21       ; G#5
	CONNECT
	NOTE N32, 21      ; G#5
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N32, 18      ; F_5
	DOTTED
	CONNECT
	NOTE N8, 20       ; G_5
	CONNECT
	NOTE N32, 20      ; G_5
	NOTE N8, 19       ; F#5
	NOTE N4, 18       ; F_5
	NOTE N4, 19       ; F#5
	NOTE N8, 9        ; G#4
	NOTE N32, 16      ; D#5
	DOTTED
	CONNECT
	NOTE N8, 18       ; F_5
	CONNECT
	NOTE N32, 18      ; F_5
	LOOP2 1, .l5E9E
	DUTY $80
	NOTE N32, 7       ; F#4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 16       ; D#5
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N8
	TRIPLET
	NOTE N32, 12      ; B_4
	DOTTED
	TRIPLET
	CONNECT
	NOTE N16, 14      ; C#5
	INSTR 8
	TRIPLET
	NOTE N64, 14      ; C#5
	TRIPLET
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	NOTE N8, 14       ; C#5
	NOTE N32, 11      ; A#4
	DOTTED
	NOTE N16, 12      ; B_4
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 8       ; G_4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 7        ; F#4
	NOTE N8, 8        ; G_4
	REST N8
	NOTE N32, 15      ; D_5
	DOTTED
	NOTE N16, 16      ; D#5
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 12      ; B_4
	DOTTED
	CONNECT
	NOTE N16, 14      ; C#5
	INSTR 8
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	REST N8
	NOTE N32, 8       ; G_4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	NOTE N32, 7       ; F#4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 16       ; D#5
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N8
	TRIPLET
	NOTE N32, 12      ; B_4
	DOTTED
	TRIPLET
	CONNECT
	NOTE N16, 14      ; C#5
	INSTR 8
	TRIPLET
	NOTE N64, 14      ; C#5
	TRIPLET
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N32, 15      ; D_5
	DOTTED
	NOTE N16, 16      ; D#5
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 8       ; G_4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 7        ; F#4
	NOTE N8, 8        ; G_4
	REST N8
	NOTE N32, 15      ; D_5
	DOTTED
	NOTE N16, 16      ; D#5
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 12       ; B_4
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 10      ; A_4
	DOTTED
	CONNECT
	NOTE N16, 12      ; B_4
	INSTR 8
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 4
	NOTE N8, 9        ; G#4
	NOTE N8, 14       ; C#5
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N32, 7       ; F#4
	DOTTED
	NOTE N16, 9       ; G#4
	NOTE N8, 7        ; F#4
	NOTE N8, 8        ; G_4
	INSTR 4
	DUTY $40
	NOTE N8, 7        ; F#4
	NOTE N8, 8        ; G_4
	NOTE N32, 13      ; C_5
	TRIPLET
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 8
	NOTE N64, 15      ; D_5
	DOTTED
	TRIPLET
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	NOTE N32, 16      ; D#5
	DOTTED
	CONNECT
	NOTE N16, 18      ; F_5
	INSTR 8
	CONNECT
	NOTE N4, 18       ; F_5
	INSTR 4
	NOTE N32, 15      ; D_5
	DOTTED
	CONNECT
	NOTE N16, 17      ; E_5
	INSTR 8
	CONNECT
	NOTE N4, 17       ; E_5
	INSTR 4
	NOTE N32, 12      ; B_4
	DOTTED
	CONNECT
	NOTE N16, 14      ; C#5
	INSTR 8
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	NOTE N8, 11       ; A#4
	NOTE N32, 21      ; G#5
	DOTTED
	CONNECT
	NOTE N8, 23       ; A#5
	INSTR 8
	NOTE N32, 23      ; A#5
	DOTTED
	CONNECT
	NOTE N4, 23       ; A#5
	INSTR 4
	NOTE N8, 22       ; A_5
	NOTE N8, 16       ; D#5
	NOTE N8, 17       ; E_5
	VOLUME $0A
	NOTE N8, 22       ; A_5
	NOTE N8, 16       ; D#5
	NOTE N8, 17       ; E_5
	VOLUME $0D
	NOTE N8, 22       ; A_5
	NOTE N8, 17       ; E_5
	NOTE N8, 15       ; D_5
	NOTE N8, 11       ; A#4
	NOTE N8, 10       ; A_4
	NOTE N8, 11       ; A#4
	NOTE N8, 15       ; D_5
	NOTE N8, 11       ; A#4
	NOTE N8, 10       ; A_4
	NOTE N8, 11       ; A#4
	NOTE N8, 14       ; C#5
	NOTE N8, 10       ; A_4
	NOTE N8, 9        ; G#4
	NOTE N8, 10       ; A_4
	NOTE N8, 14       ; C#5
	NOTE N8, 10       ; A_4
	NOTE N8, 9        ; G#4
	NOTE N8, 10       ; A_4
	NOTE N8, 15       ; D_5
	NOTE N8, 11       ; A#4
	NOTE N8, 10       ; A_4
	NOTE N8, 11       ; A#4
	NOTE N8, 18       ; F_5
	NOTE N8, 11       ; A#4
	NOTE N8, 10       ; A_4
	NOTE N8, 11       ; A#4
.l5FA6:
	FLAGS $08
	NOTE N8, 14       ; C#5
	NOTE N8, 10       ; A_4
	NOTE N8, 17       ; E_5
	NOTE N8, 10       ; A_4
	LOOP2 1, .l5FA6
	REST N1
	REST N1
	REST N1
	REST N4
	REST N4
	REST N4
	REST N8
	REST N16
	DOTTED
	REST N32
	TRIPLET
	REST N64
	OCTAVE 0
	JUMP .l5E99
	END                ; unreachable
Music0D_Ch3:
	OCTAVE 0
	INSTR 2
	TRANSP -12
	HOLD 240
	DUTY $00
.l5FCC:
	FLAGS $08
	TEMPO $0249
.l5FD1:
	FLAGS $08
	VOLUME $03
	NOTE N8, 9        ; G#4
	REST N8
	HOLD 80
	NOTE N16, 21      ; G#5
	REST N16
	HOLD 200
	DOTTED
	NOTE N4, 9        ; G#4
	NOTE N4, 9        ; G#4
	NOTE N8, 9        ; G#4
	REST N8
	HOLD 80
	NOTE N16, 21      ; G#5
	REST N16
	HOLD 200
	DOTTED
	NOTE N4, 9        ; G#4
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N8, 9        ; G#4
	LOOP2 1, .l5FD1
.l5FF1:
	FLAGS $08
	HOLD 240
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N8, 9        ; G#4
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N4, 9        ; G#4
	LOOP2 7, .l5FF1
.l6001:
	FLAGS $48
	HOLD 200
	DOTTED
	NOTE N2, 11       ; A#4
	CONNECT
	NOTE N8, 11       ; A#4
	HOLD 80
	NOTE N16, 11      ; A#4
	HOLD 250
	REST N16
	NOTE N1, 10       ; A_4
	LOOP2 1, .l6001
.l6014:
	FLAGS $08
	HOLD 200
.l6018:
	FLAGS $08
	VOLUME $03
	NOTE N8, 11       ; A#4
	VOLUME $02
	NOTE N8, 11       ; A#4
	LOOP3 3, .l6018
.l6024:
	FLAGS $08
	VOLUME $03
	NOTE N8, 10       ; A_4
	VOLUME $02
	NOTE N8, 10       ; A_4
	LOOP3 3, .l6024
	LOOP2 1, .l6014
.l6034:
	FLAGS $08
	HOLD 240
	NOTE N4, 9        ; G#4
	HOLD 120
	NOTE N16, 9       ; G#4
	REST N16
	HOLD 240
	DOTTED
	NOTE N4, 9        ; G#4
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N8, 9        ; G#4
	REST N8
	NOTE N16, 9       ; G#4
	REST N16
	DOTTED
	NOTE N4, 9        ; G#4
	NOTE N16, 9       ; G#4
	REST N16
	NOTE N8, 9        ; G#4
	LOOP2 1, .l6034
	OCTAVE 0
	JUMP .l5FCC
	END                ; unreachable
Music0D_Ch4:
	OCTAVE 0
	VOLUME $06
	HOLD 100
.l605C:
	FLAGS $00
	TEMPO $0249
.l6061:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 15
	LOOP1 11, .l6061
.l6079:
	FLAGS $00
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	LOOP1 7, .l6079
.l6098:
	FLAGS $00
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 13
	LOOP1 3, .l6098
	OCTAVE 0
	JUMP .l605C
	END                ; unreachable

;; Music $0E
Music0E:
	db $00
	BEPTR Music0E_Ch1
	BEPTR Music0E_Ch2
	BEPTR Music0E_Ch3
	BEPTR Music0E_Ch4
Music0E_Ch1:
	OCTAVE 1
	TEMPO $022E
	HOLD 200
	VOLUME $0B
	INSTR 4
	DUTY $40
	DOTTED
	REST N4
	NOTE N32, 29      ; E_5
	DOTTED
	NOTE N16, 30      ; F_5
	OCTUP
	NOTE N8, 11       ; A#5
	NOTE N8, 18       ; F_6
	CONNECT
	NOTE N16, 16      ; D#6
	INSTR 8
	NOTE N16, 16      ; D#6
	CONNECT
	NOTE N8, 16       ; D#6
	INSTR 4
	NOTE N8, 15       ; D_6
	NOTE N8, 13       ; C_6
	NOTE N8, 15       ; D_6
	CONNECT
	NOTE N8, 16       ; D#6
	CONNECT
	NOTE N8, 16       ; D#6
	CONNECT
	NOTE N4, 9        ; G#5
	INSTR 8
	NOTE N8, 9        ; G#5
	DOTTED
	CONNECT
	NOTE N8, 9        ; G#5
	INSTR 4
	NOTE N16, 18      ; F_6
	NOTE N16, 18      ; F_6
	REST N16
	CONNECT
	NOTE N16, 18      ; F_6
	NOTE N4, 18       ; F_6
	INSTR 11
	DOTTED
	NOTE N4, 18       ; F_6
	CONNECT
	NOTE N16, 18      ; F_6
	REST N16
	INSTR 4
	NOTE N16, 18      ; F_6
	NOTE N16, 18      ; F_6
	REST N16
	CONNECT
	NOTE N4, 18       ; F_6
	INSTR 11
	DOTTED
	NOTE N4, 18       ; F_6
	CONNECT
	NOTE N16, 18      ; F_6
	REST N16
	INSTR 4
	NOTE N8, 18       ; F_6
	NOTE N16, 23      ; A#6
	END
Music0E_Ch2:
	OCTAVE 1
	TEMPO $022E
	VOLUME $0A
	INSTR 7
	HOLD 200
	DUTY $80
	DOTTED
	REST N4
	NOTE N32, 22      ; A_4
	DOTTED
	NOTE N16, 23      ; A#4
	NOTE N8, 30       ; F_5
	OCTUP
	NOTE N8, 11       ; A#5
	OCTUP
	NOTE N16, 18      ; F_4
	NOTE N16, 23      ; A#4
	NOTE N8, 30       ; F_5
	OCTUP
	NOTE N8, 8        ; G_5
	NOTE N8, 6        ; F_5
	NOTE N16, 8       ; G_5
	NOTE N16, 8       ; G_5
	CONNECT
	NOTE N8, 9        ; G#5
	CONNECT
	NOTE N8, 9        ; G#5
	DOTTED
	CONNECT
	NOTE N8, 4        ; D#5
	DOTTED
	CONNECT
	NOTE N8, 4        ; D#5
	NOTE N16, 6       ; F_5
	NOTE N16, 4       ; D#5
	NOTE N16, 4       ; D#5
	DOTTED
	NOTE N8, 2        ; C#5
	NOTE N4, 11       ; A#5
	NOTE N16, 6       ; F_5
	NOTE N8, 6        ; F_5
	NOTE N16, 4       ; D#5
	NOTE N8, 4        ; D#5
	NOTE N16, 2       ; C#5
	NOTE N16, 2       ; C#5
	REST N16
	NOTE N16, 2       ; C#5
	NOTE N16, 2       ; C#5
	REST N16
	NOTE N4, 4        ; D#5
	NOTE N16, 6       ; F_5
	NOTE N8, 6        ; F_5
	NOTE N16, 4       ; D#5
	NOTE N8, 4        ; D#5
	NOTE N16, 4       ; D#5
	NOTE N16, 4       ; D#5
	NOTE N8, 6        ; F_5
	DOTTED
	NOTE N16, 18      ; F_6
	END
Music0E_Ch3:
	OCTAVE 0
	TEMPO $022E
	VOLUME $03
	HOLD 180
	INSTR 16
	DUTY $80
	DOTTED
	REST N4
	TRANSP -12
	OCTUP
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N8, 11       ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N16, 11      ; A#4
	NOTE N8, 9        ; G#4
	NOTE N8, 9        ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	NOTE N8, 9        ; G#4
	NOTE N8, 9        ; G#4
	NOTE N16, 9       ; G#4
	NOTE N8, 9        ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	NOTE N16, 9       ; G#4
	HOLD 230
	NOTE N4, 7        ; F#4
	NOTE N16, 14      ; C#5
	NOTE N8, 14       ; C#5
	NOTE N16, 21      ; G#5
	NOTE N8, 21       ; G#5
	NOTE N16, 23      ; A#5
	NOTE N16, 23      ; A#5
	REST N16
	NOTE N16, 19      ; F#5
	NOTE N16, 19      ; F#5
	REST N16
	NOTE N4, 9        ; G#4
	NOTE N16, 16      ; D#5
	NOTE N8, 16       ; D#5
	NOTE N16, 21      ; G#5
	NOTE N8, 21       ; G#5
	NOTE N16, 25      ; C_6
	NOTE N16, 25      ; C_6
	NOTE N8, 9        ; G#4
	DOTTED
	NOTE N16, 11      ; A#4
	END
Music0E_Ch4:
	OCTAVE 0
	TEMPO $022E
	HOLD 200
	VOLUME $07
	INSTR 10
	INSTR 14
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N8, 13
.l61A3:
	FLAGS $00
	INSTR 10
	NOTE N16, 9
	REST N16
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 9
	REST N16
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 9
	LOOP1 3, .l61A3
	INSTR 14
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N8, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 9
	REST N16
	NOTE N16, 13
	INSTR 14
	NOTE N16, 13
	REST N16
	INSTR 10
	NOTE N16, 9
	NOTE N16, 9
	REST N16
	NOTE N16, 13
	INSTR 14
	NOTE N16, 13
	NOTE N16, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	NOTE N8, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 9
	REST N16
	NOTE N16, 13
	NOTE N16, 13
	REST N16
	INSTR 14
	NOTE N8, 13
	NOTE N8, 13
	INSTR 10
	NOTE N4, 13
	END

;; Music $0F
Music0F:
	db $00
	BEPTR Music0F_Ch1
	BEPTR Music0F_Ch2
	BEPTR Music0F_Ch3
	BEPTR Music0F_Ch4
Music0F_Ch1:
	OCTAVE 0
	HOLD 200
	VOLUME $0B
	DETUNE -2
	PAN $10
.l61FE:
	FLAGS $00
	TEMPO $0266
	DUTY $80
	INSTR 4
	REST N8
	CONNECT
	OCTUP
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N8, 15       ; D_5
	NOTE N4, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 4
	NOTE N8, 17       ; E_5
	NOTE N8, 15       ; D_5
	NOTE N4, 14       ; C#5
	CONNECT
	NOTE N8, 7        ; F#4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 7        ; F#4
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	DOTTED
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 8
	NOTE N2, 12       ; B_4
	CONNECT
	NOTE N8, 12       ; B_4
	PAN $11
	INSTR 4
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N4, 15       ; D_5
	NOTE N8, 15       ; D_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 15       ; D_5
	REST N8
	INSTR 4
	NOTE N8, 17       ; E_5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N8, 14       ; C#5
	CONNECT
	NOTE N16, 14      ; C#5
	REST N16
	DOTTED
	NOTE N4, 7        ; F#4
	REST N8
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	CONNECT
	NOTE N8, 12       ; B_4
	NOTE N8, 12       ; B_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 12       ; B_4
	REST N8
	INSTR 4
	DOTTED
	NOTE N4, 21       ; G#5
	PAN $10
	DUTY $40
	REST N8
	NOTE N32, 14      ; C#5
	DOTTED
	CONNECT
	NOTE N16, 15      ; D_5
	INSTR 8
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 4
	NOTE N16, 15      ; D_5
	REST N16
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 8
	NOTE N4, 15       ; D_5
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	DOTTED
	NOTE N4, 17       ; E_5
	NOTE N8, 19       ; F#5
	REST N8
	NOTE N8, 20       ; G_5
	REST N8
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 4
	NOTE N4, 17       ; E_5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 8
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 4
	CONNECT
	NOTE N8, 8        ; G_4
	INSTR 8
	CONNECT
	NOTE N4, 8        ; G_4
	INSTR 4
	CONNECT
	NOTE N8, 10       ; A_4
	INSTR 8
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 4
	NOTE N4, 12       ; B_4
	NOTE N32, 12      ; B_4
	DOTTED
	REST N16
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	NOTE N8, 12       ; B_4
	REST N8
	NOTE N8, 14       ; C#5
	REST N8
	NOTE N32, 13      ; C_5
	TRIPLET
	CONNECT
	NOTE N1, 15       ; D_5
	NOTE N16, 15      ; D_5
	NOTE N64, 15      ; D_5
	INSTR 8
	TRIPLET
	NOTE N4, 15       ; D_5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 4
	NOTE N32, 14      ; C#5
	NOTE N32, 13      ; C_5
	NOTE N32, 12      ; B_4
	NOTE N32, 11      ; A#4
	NOTE N32, 10      ; A_4
	NOTE N32, 9       ; G#4
	NOTE N32, 8       ; G_4
	NOTE N32, 7       ; F#4
	NOTE N32, 6       ; F_4
	NOTE N32, 5       ; E_4
	NOTE N32, 4       ; D#4
	NOTE N32, 3       ; D_4
	REST N1
	REST N1
.l62E8:
	FLAGS $08
	HOLD 1
	NOTE N4, 24       ; B_5
	NOTE N4, 24       ; B_5
	NOTE N2, 24       ; B_5
	LOOP2 1, .l62E8
.l62F3:
	FLAGS $08
	HOLD 200
	NOTE N32, 17      ; E_5
	CONNECT
	NOTE N8, 19       ; F#5
	CONNECT
	NOTE N32, 19      ; F#5
	NOTE N16, 12      ; B_4
	NOTE N4, 12       ; B_4
	DOTTED
	NOTE N8, 13       ; C_5
	NOTE N16, 13      ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 20       ; G_5
	LOOP2 3, .l62F3
	NOTE N32, 17      ; E_5
	TRIPLET
	CONNECT
	NOTE N1, 19       ; F#5
	NOTE N16, 19      ; F#5
	NOTE N64, 19      ; F#5
	INSTR 8
	TRIPLET
	NOTE N4, 19       ; F#5
	CONNECT
	NOTE N1, 19       ; F#5
	OCTAVE 0
	JUMP .l61FE
	END                ; unreachable
Music0F_Ch2:
	OCTAVE 0
	VOLUME $0D
	HOLD 200
.l631F:
	FLAGS $48
	TEMPO $0266
	DUTY $80
	INSTR 4
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N4, 15       ; D_5
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 4
	NOTE N8, 17       ; E_5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N8, 7        ; F#4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 7        ; F#4
	INSTR 4
	NOTE N8, 15       ; D_5
	NOTE N8, 14       ; C#5
	CONNECT
	NOTE N8, 12       ; B_4
	NOTE N4, 12       ; B_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N2, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	CONNECT
	NOTE N8, 17       ; E_5
	INSTR 8
	CONNECT
	NOTE N4, 17       ; E_5
	INSTR 4
	CONNECT
	NOTE N4, 19       ; F#5
	NOTE N8, 19       ; F#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	REST N8
	INSTR 4
	NOTE N8, 20       ; G_5
	NOTE N8, 19       ; F#5
	CONNECT
	NOTE N8, 17       ; E_5
	CONNECT
	NOTE N16, 17      ; E_5
	REST N16
	DOTTED
	NOTE N4, 10       ; A_4
	REST N8
	NOTE N8, 19       ; F#5
	NOTE N8, 17       ; E_5
	CONNECT
	NOTE N8, 15       ; D_5
	NOTE N8, 15       ; D_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 15       ; D_5
	REST N8
	INSTR 4
	DOTTED
	NOTE N4, 24       ; B_5
	DUTY $40
	NOTE N32, 14      ; C#5
	DOTTED
	CONNECT
	NOTE N16, 15      ; D_5
	INSTR 8
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 4
	NOTE N16, 15      ; D_5
	REST N16
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 8
	DOTTED
	NOTE N4, 15       ; D_5
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 4
	DOTTED
	NOTE N4, 17       ; E_5
	NOTE N8, 19       ; F#5
	REST N8
	NOTE N8, 20       ; G_5
	REST N8
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 19       ; F#5
	INSTR 4
	NOTE N4, 17       ; E_5
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	CONNECT
	NOTE N4, 10       ; A_4
	INSTR 8
	NOTE N4, 10       ; A_4
	CONNECT
	NOTE N16, 10      ; A_4
	REST N16
	INSTR 4
	CONNECT
	NOTE N8, 12       ; B_4
	INSTR 8
	CONNECT
	NOTE N4, 12       ; B_4
	INSTR 4
	CONNECT
	NOTE N8, 14       ; C#5
	INSTR 8
	CONNECT
	NOTE N4, 14       ; C#5
	INSTR 4
	NOTE N4, 15       ; D_5
	NOTE N32, 15      ; D_5
	DOTTED
	REST N16
	CONNECT
	NOTE N8, 17       ; E_5
	INSTR 8
	CONNECT
	NOTE N4, 17       ; E_5
	INSTR 4
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 17       ; E_5
	REST N8
	NOTE N32, 17      ; E_5
	TRIPLET
	CONNECT
	NOTE N1, 19       ; F#5
	NOTE N16, 19      ; F#5
	NOTE N64, 19      ; F#5
	INSTR 8
	TRIPLET
	NOTE N4, 19       ; F#5
	NOTE N8, 19       ; F#5
	CONNECT
	NOTE N2, 19       ; F#5
	INSTR 4
	NOTE N32, 18      ; F_5
	NOTE N32, 17      ; E_5
	NOTE N32, 16      ; D#5
	NOTE N32, 15      ; D_5
	NOTE N32, 14      ; C#5
	NOTE N32, 13      ; C_5
	NOTE N32, 12      ; B_4
	NOTE N32, 11      ; A#4
	NOTE N32, 10      ; A_4
	NOTE N32, 9       ; G#4
	NOTE N32, 8       ; G_4
	NOTE N32, 7       ; F#4
.l6409:
	FLAGS $00
	NOTE N32, 22      ; A_3
	CONNECT
	NOTE N8, 24       ; B_3
	CONNECT
	NOTE N32, 24      ; B_3
	NOTE N16, 19      ; F#3
	NOTE N8, 19       ; F#3
	REST N8
	DOTTED
	NOTE N8, 20       ; G_3
	NOTE N16, 20      ; G_3
	NOTE N8, 20       ; G_3
	NOTE N8, 22       ; A_3
	LOOP2 3, .l6409
.l641C:
	FLAGS $00
	NOTE N32, 29      ; E_4
	CONNECT
	NOTE N8, 31       ; F#4
	CONNECT
	NOTE N32, 31      ; F#4
	NOTE N16, 24      ; B_3
	NOTE N8, 24       ; B_3
	REST N8
	DOTTED
	NOTE N8, 25       ; C_4
	NOTE N16, 25      ; C_4
	NOTE N8, 25       ; C_4
	OCTUP
	NOTE N8, 8        ; G_4
	LOOP2 3, .l641C
	NOTE N32, 5       ; E_4
	TRIPLET
	CONNECT
	NOTE N1, 7        ; F#4
	NOTE N16, 7       ; F#4
	NOTE N64, 7       ; F#4
	INSTR 8
	TRIPLET
	NOTE N4, 7        ; F#4
	CONNECT
	NOTE N1, 7        ; F#4
	OCTAVE 0
	JUMP .l631F
	END                ; unreachable
Music0F_Ch3:
	OCTAVE 0
	VOLUME $03
	INSTR 16
	TRANSP -12
	DUTY $80
.l644C:
	FLAGS $08
	TEMPO $0266
.l6451:
	FLAGS $08
	HOLD 180
.l6455:
	FLAGS $08
	NOTE N8, 12       ; B_4
	NOTE N8, 19       ; F#5
	NOTE N8, 24       ; B_5
	LOOP3 1, .l6455
	NOTE N8, 12       ; B_4
	HOLD 250
	NOTE N16, 19      ; F#5
	NOTE N16, 24      ; B_5
	HOLD 180
.l6465:
	FLAGS $08
	NOTE N8, 11       ; A#4
	NOTE N8, 19       ; F#5
	NOTE N8, 23       ; A#5
	LOOP3 1, .l6465
	NOTE N8, 11       ; A#4
	HOLD 250
	NOTE N16, 19      ; F#5
	NOTE N16, 23      ; A#5
	HOLD 180
.l6475:
	FLAGS $08
	NOTE N8, 10       ; A_4
	NOTE N8, 19       ; F#5
	NOTE N8, 22       ; A_5
	LOOP3 1, .l6475
	NOTE N8, 10       ; A_4
	HOLD 250
	NOTE N16, 19      ; F#5
	NOTE N16, 22      ; A_5
	HOLD 180
	NOTE N8, 9        ; G#4
	NOTE N8, 17       ; E_5
	NOTE N8, 21       ; G#5
	NOTE N16, 17      ; E_5
	NOTE N16, 21      ; G#5
	NOTE N8, 24       ; B_5
	NOTE N8, 21       ; G#5
	NOTE N8, 17       ; E_5
	NOTE N8, 9        ; G#4
	LOOP2 1, .l6451
	HOLD 250
	NOTE N4, 8        ; G_4
	HOLD 80
	NOTE N8, 20       ; G_5
	HOLD 200
	NOTE N4, 8        ; G_4
	NOTE N4, 20       ; G_5
	HOLD 120
	NOTE N8, 8        ; G_4
	NOTE N8, 8        ; G_4
	HOLD 240
	DOTTED
	NOTE N8, 8        ; G_4
	NOTE N16, 20      ; G_5
	HOLD 120
	NOTE N8, 15       ; D_5
	NOTE N4, 8        ; G_4
	NOTE N4, 8        ; G_4
	HOLD 250
	NOTE N4, 7        ; F#4
	HOLD 80
	NOTE N8, 19       ; F#5
	HOLD 200
	NOTE N4, 7        ; F#4
	NOTE N4, 19       ; F#5
	HOLD 120
	NOTE N8, 7        ; F#4
	NOTE N8, 7        ; F#4
	HOLD 200
	DOTTED
	NOTE N8, 7        ; F#4
	NOTE N16, 19      ; F#5
	HOLD 120
	NOTE N8, 14       ; C#5
	NOTE N4, 7        ; F#4
	NOTE N4, 7        ; F#4
	HOLD 250
	NOTE N4, 8        ; G_4
	HOLD 80
	NOTE N8, 20       ; G_5
	HOLD 200
	NOTE N4, 8        ; G_4
	NOTE N4, 20       ; G_5
	HOLD 120
	NOTE N8, 8        ; G_4
	NOTE N8, 8        ; G_4
	HOLD 200
	DOTTED
	NOTE N8, 8        ; G_4
	NOTE N16, 20      ; G_5
	HOLD 120
	NOTE N8, 15       ; D_5
	NOTE N4, 10       ; A_4
	NOTE N4, 10       ; A_4
	HOLD 200
	NOTE N4, 12       ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	NOTE N2, 12       ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	NOTE N4, 12       ; B_4
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
	CONNECT
	NOTE N2, 12       ; B_4
	CONNECT
	NOTE N16, 12      ; B_4
	NOTE N16, 12      ; B_4
.l64EA:
	FLAGS $08
	DOTTED
	NOTE N8, 12       ; B_4
	NOTE N16, 7       ; F#4
	NOTE N4, 7        ; F#4
	DOTTED
	NOTE N8, 8        ; G_4
	NOTE N16, 8       ; G_4
	NOTE N8, 8        ; G_4
	NOTE N8, 10       ; A_4
	LOOP2 7, .l64EA
	NOTE N16, 12      ; B_4
	HOLD 250
	DOTTED
	CONNECT
	NOTE N2, 12       ; B_4
	DOTTED
	NOTE N8, 12       ; B_4
	CONNECT
	NOTE N2, 12       ; B_4
	NOTE N2, 10       ; A_4
	OCTAVE 0
	JUMP .l644C
	END                ; unreachable
Music0F_Ch4:
	OCTAVE 0
	VOLUME $06
	HOLD 50
.l6510:
	FLAGS $00
	TEMPO $0266
.l6515:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N8, 13
	LOOP1 6, .l6515
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	TRIPLET
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	TRIPLET
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	INSTR 14
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
.l6549:
	FLAGS $00
	INSTR 10
	NOTE N16, 9
	REST N16
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	REST N16
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	REST N16
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 5, .l6549
.l6569:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	NOTE N8, 9
	LOOP1 1, .l6569
.l6584:
	FLAGS $00
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 9
	NOTE N16, 15
	LOOP1 31, .l6584
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 9
	NOTE N8, 13
	NOTE N8, 9
	NOTE N8, 15
	NOTE N8, 9
	NOTE N8, 13
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N8, 15
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 9
	NOTE N16, 9
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	INSTR 14
	NOTE N16, 13
	NOTE N16, 13
	OCTAVE 0
	JUMP .l6510
	END                ; unreachable

;; Music $1C
Music1C:
	db $00
	BEPTR Music1C_Ch1
	BEPTR Music1C_Ch2
	BEPTR Music1C_Ch3
	BEPTR Music1C_Ch4
Music1C_Ch1:
	OCTAVE 0
	TEMPO $0249
	HOLD 180
	INSTR 4
	VOLUME $0B
	DETUNE -1
	DUTY $00
	OCTUP
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
.l65D4:
	FLAGS $08
	VOLUME $0B
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	LOOP1 4, .l65D4
	VOLUME $0B
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N4, 13       ; C_5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
.l65E7:
	FLAGS $08
	VOLUME $0B
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	LOOP1 4, .l65E7
	VOLUME $0B
	NOTE N4, 6        ; F_4
	NOTE N4, 3        ; D_4
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
.l65F9:
	FLAGS $08
	VOLUME $0B
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	LOOP1 4, .l65F9
	VOLUME $0B
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N4, 13       ; C_5
	NOTE N8, 15       ; D_5
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	REST N8
	NOTE N8, 11       ; A#4
	NOTE N8, 11       ; A#4
	REST N8
	NOTE N8, 10       ; A_4
	NOTE N8, 10       ; A_4
	REST N8
	DOTTED
	NOTE N8, 8        ; G_4
	REST N16
	NOTE N4, 6        ; F_4
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
.l661C:
	FLAGS $08
	VOLUME $0B
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	LOOP1 4, .l661C
	VOLUME $0B
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N4, 13       ; C_5
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
.l662F:
	FLAGS $08
	VOLUME $0B
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	LOOP1 4, .l662F
	VOLUME $0B
	NOTE N4, 6        ; F_4
	NOTE N4, 3        ; D_4
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
.l6641:
	FLAGS $08
	VOLUME $0B
	NOTE N8, 8        ; G_4
	VOLUME $0A
	NOTE N8, 8        ; G_4
	LOOP1 4, .l6641
	VOLUME $0B
	NOTE N8, 11       ; A#4
	NOTE N8, 8        ; G_4
	NOTE N4, 13       ; C_5
	DUTY $40
	NOTE N8, 16       ; D#5
	NOTE N8, 16       ; D#5
	REST N8
	NOTE N8, 18       ; F_5
	NOTE N8, 18       ; F_5
	REST N8
	NOTE N8, 20       ; G_5
	NOTE N8, 20       ; G_5
	REST N8
	NOTE N8, 24       ; B_5
	NOTE N4, 24       ; B_5
	NOTE N4, 20       ; G_5
	NOTE N4, 18       ; F_5
	CONNECT
	NOTE N4, 20       ; G_5
	INSTR 8
	NOTE N4, 20       ; G_5
	NOTE N4, 20       ; G_5
	CONNECT
	NOTE N16, 20      ; G_5
	INSTR 4
	NOTE N8, 18       ; F_5
	NOTE N16, 20      ; G_5
	END
Music1C_Ch2:
	OCTAVE 0
	TEMPO $0249
	INSTR 4
	HOLD 180
	VOLUME $0C
	DUTY $00
	NOTE N8, 28       ; D#4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
.l667F:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	VOLUME $0D
	NOTE N8, 25       ; C_4
	VOLUME $0C
	NOTE N8, 25       ; C_4
	LOOP1 1, .l667F
	DUTY $80
	INSTR 6
	VOLUME $0D
	OCTUP
	NOTE N4, 11       ; A#4
	NOTE N4, 10       ; A_4
	DOTTED
	NOTE N4, 9        ; G#4
	CONNECT
	NOTE N8, 8        ; G_4
	NOTE N2, 8        ; G_4
	INSTR 8
	CONNECT
	NOTE N2, 8        ; G_4
	DUTY $00
	INSTR 4
	OCTUP
	NOTE N4, 23       ; A#3
	NOTE N4, 20       ; G_3
	VOLUME $0C
	NOTE N8, 28       ; D#4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
.l66AC:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	VOLUME $0D
	NOTE N8, 25       ; C_4
	VOLUME $0C
	NOTE N8, 25       ; C_4
	LOOP1 1, .l66AC
	DUTY $80
	INSTR 6
	VOLUME $0D
	OCTUP
	NOTE N4, 11       ; A#4
	NOTE N4, 13       ; C_5
	DOTTED
	NOTE N4, 9        ; G#4
	CONNECT
	NOTE N8, 8        ; G_4
	NOTE N2, 8        ; G_4
	INSTR 8
	CONNECT
	NOTE N2, 8        ; G_4
	INSTR 4
	DUTY $00
	DOTTED
	NOTE N8, 1        ; C_4
	REST N16
	OCTUP
	NOTE N4, 23       ; A#3
	VOLUME $0C
	NOTE N8, 28       ; D#4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
.l66DB:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	VOLUME $0D
	NOTE N8, 25       ; C_4
	VOLUME $0C
	NOTE N8, 25       ; C_4
	LOOP1 1, .l66DB
	DUTY $80
	INSTR 6
	VOLUME $0D
	OCTUP
	NOTE N4, 11       ; A#4
	NOTE N4, 10       ; A_4
	DOTTED
	NOTE N4, 9        ; G#4
	CONNECT
	NOTE N8, 8        ; G_4
	NOTE N2, 8        ; G_4
	INSTR 8
	CONNECT
	NOTE N2, 8        ; G_4
	DUTY $00
	INSTR 4
	OCTUP
	NOTE N4, 23       ; A#3
	NOTE N4, 20       ; G_3
	VOLUME $0C
	NOTE N8, 28       ; D#4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
.l6708:
	FLAGS $00
	NOTE N8, 25       ; C_4
	NOTE N8, 25       ; C_4
	VOLUME $0D
	NOTE N8, 25       ; C_4
	VOLUME $0C
	NOTE N8, 25       ; C_4
	LOOP1 1, .l6708
	NOTE N8, 28       ; D#4
	NOTE N8, 25       ; C_4
	NOTE N4, 30       ; F_4
	DUTY $40
	VOLUME $0E
	OCTUP
	NOTE N8, 8        ; G_4
	VOLUME $0B
	NOTE N8, 8        ; G_4
	REST N8
	VOLUME $0E
	NOTE N8, 10       ; A_4
	VOLUME $0B
	NOTE N8, 10       ; A_4
	REST N8
	VOLUME $0E
	NOTE N8, 12       ; B_4
	VOLUME $0B
	NOTE N8, 12       ; B_4
	REST N8
	VOLUME $0D
	CONNECT
	NOTE N8, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N4, 15       ; D_5
	INSTR 4
	NOTE N4, 13       ; C_5
	NOTE N4, 11       ; A#4
	CONNECT
	NOTE N4, 13       ; C_5
	INSTR 8
	NOTE N4, 13       ; C_5
	NOTE N4, 13       ; C_5
	CONNECT
	NOTE N16, 13      ; C_5
	INSTR 4
	NOTE N8, 11       ; A#4
	NOTE N16, 13      ; C_5
	END
Music1C_Ch3:
	OCTAVE 0
	TEMPO $0249
	HOLD 180
	INSTR 16
	VOLUME $03
	TRANSP -12
	OCTUP
	NOTE N8, 11       ; A#4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 16       ; D#5
	NOTE N8, 13       ; C_5
	NOTE N4, 18       ; F_5
	NOTE N8, 11       ; A#4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 6        ; F_4
	NOTE N4, 8        ; G_4
	NOTE N8, 11       ; A#4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 16       ; D#5
	NOTE N8, 13       ; C_5
	NOTE N4, 18       ; F_5
	NOTE N8, 20       ; G_5
	NOTE N8, 20       ; G_5
	REST N8
	NOTE N8, 18       ; F_5
	NOTE N4, 18       ; F_5
	NOTE N8, 16       ; D#5
	NOTE N8, 16       ; D#5
	REST N8
	NOTE N8, 15       ; D_5
	NOTE N4, 15       ; D_5
	NOTE N8, 13       ; C_5
	REST N8
	NOTE N4, 11       ; A#4
	NOTE N8, 11       ; A#4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 16       ; D#5
	NOTE N8, 13       ; C_5
	NOTE N4, 18       ; F_5
	NOTE N8, 11       ; A#4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 6        ; F_4
	NOTE N4, 8        ; G_4
	NOTE N8, 11       ; A#4
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N4, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 13       ; C_5
	NOTE N8, 16       ; D#5
	NOTE N8, 13       ; C_5
	NOTE N4, 18       ; F_5
	NOTE N8, 20       ; G_5
	NOTE N8, 20       ; G_5
	REST N8
	NOTE N8, 18       ; F_5
	NOTE N4, 18       ; F_5
	NOTE N8, 15       ; D_5
	NOTE N8, 15       ; D_5
	REST N8
	NOTE N8, 20       ; G_5
	NOTE N4, 20       ; G_5
	NOTE N4, 18       ; F_5
	NOTE N4, 11       ; A#4
	CONNECT
	NOTE N2, 13       ; C_5
	NOTE N4, 13       ; C_5
	CONNECT
	NOTE N16, 13      ; C_5
	NOTE N8, 11       ; A#4
	NOTE N16, 13      ; C_5
	END
Music1C_Ch4:
	OCTAVE 0
	TEMPO $0249
	HOLD 50
	VOLUME $06
.l67D4:
	FLAGS $00
.l67D6:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N16, 13
	NOTE N16, 13
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 9
	NOTE N16, 13
	NOTE N16, 9
	NOTE N16, 13
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 13
	NOTE N16, 13
	LOOP1 5, .l67D6
.l67F3:
	FLAGS $00
	INSTR 14
	NOTE N16, 13
	NOTE N16, 14
	INSTR 10
	NOTE N16, 13
	LOOP1 7, .l67F3
	INSTR 14
	TRIPLET
	NOTE N32, 13
	NOTE N32, 13
	NOTE N32, 13
	TRIPLET
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	NOTE N16, 13
	LOOP2 1, .l67D4
.l6812:
	FLAGS $00
	INSTR 14
	NOTE N16, 13
	NOTE N16, 14
	INSTR 10
	NOTE N16, 13
	LOOP3 3, .l6812
	NOTE N16, 13
	INSTR 14
	NOTE N8, 13
	NOTE N8, 13
	END

;; Music $1D
Music1D:
	db $00
	BEPTR Music1D_Ch1
	BEPTR Music1D_Ch2
	BEPTR Music1D_Ch3
	BEPTR Music1D_Ch4
Music1D_Ch1:
	OCTAVE 0
	TEMPO $010B
	HOLD 200
	INSTR 10
	VOLUME $09
	DUTY $80
.l683B:
	FLAGS $08
.l683D:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP2 3, .l683D
.l684F:
	FLAGS $00
	PAN $10
	NOTE N16, 28      ; D#4
	PAN $01
	OCTUP
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP2 3, .l684F
.l6862:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 13      ; C_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 13      ; C_5
	LOOP2 3, .l6862
.l6874:
	FLAGS $08
	PAN $10
	NOTE N16, 10      ; A_4
	PAN $01
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 13      ; C_5
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP2 3, .l6874
	LOOP3 2, .l683B
.l688A:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l688A
.l689C:
	FLAGS $00
	PAN $10
	NOTE N16, 28      ; D#4
	PAN $01
	OCTUP
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l689C
.l68AF:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 13      ; C_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 13      ; C_5
	LOOP1 3, .l68AF
.l68C1:
	FLAGS $00
	PAN $10
	NOTE N16, 31      ; F#4
	PAN $01
	OCTUP
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 10      ; A_4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l68C1
.l68D4:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l68D4
.l68E6:
	FLAGS $00
	PAN $10
	NOTE N16, 28      ; D#4
	PAN $01
	OCTUP
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l68E6
.l68F9:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 13      ; C_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 13      ; C_5
	LOOP1 3, .l68F9
.l690B:
	FLAGS $08
	PAN $10
	NOTE N16, 10      ; A_4
	PAN $01
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 13      ; C_5
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l690B
.l691D:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l691D
.l692F:
	FLAGS $00
	PAN $10
	NOTE N16, 28      ; D#4
	PAN $01
	OCTUP
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 11      ; A#4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l692F
.l6942:
	FLAGS $08
	PAN $10
	NOTE N16, 8       ; G_4
	PAN $01
	NOTE N16, 13      ; C_5
	PAN $10
	NOTE N16, 16      ; D#5
	PAN $01
	NOTE N16, 13      ; C_5
	LOOP1 3, .l6942
.l6954:
	FLAGS $00
	PAN $10
	NOTE N16, 31      ; F#4
	PAN $01
	OCTUP
	NOTE N16, 15      ; D_5
	PAN $10
	NOTE N16, 10      ; A_4
	PAN $01
	NOTE N16, 15      ; D_5
	LOOP1 3, .l6954
	PAN $10
.l6969:
	FLAGS $08
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 8       ; G_4
	LOOP1 4, .l6969
	NOTE N16, 15      ; D_5
.l6973:
	FLAGS $08
	NOTE N16, 16      ; D#5
	NOTE N16, 11      ; A#4
	NOTE N16, 8       ; G_4
	LOOP1 4, .l6973
	NOTE N16, 16      ; D#5
.l697D:
	FLAGS $08
	NOTE N16, 13      ; C_5
	NOTE N16, 10      ; A_4
	NOTE N16, 6       ; F_4
	LOOP1 4, .l697D
	NOTE N16, 13      ; C_5
	NOTE N8, 16       ; D#5
	REST N8
	NOTE N2, 15       ; D_5
	REST N8
	NOTE N8, 11       ; A#4
.l698C:
	FLAGS $08
	NOTE N16, 15      ; D_5
	NOTE N16, 11      ; A#4
	NOTE N16, 8       ; G_4
	LOOP1 4, .l698C
	NOTE N16, 15      ; D_5
.l6996:
	FLAGS $08
	NOTE N16, 16      ; D#5
	NOTE N16, 11      ; A#4
	NOTE N16, 8       ; G_4
	LOOP1 4, .l6996
	NOTE N16, 16      ; D#5
.l69A0:
	FLAGS $08
	NOTE N16, 13      ; C_5
	NOTE N16, 10      ; A_4
	NOTE N16, 6       ; F_4
	LOOP1 4, .l69A0
	NOTE N16, 13      ; C_5
.l69AA:
	FLAGS $08
	NOTE N16, 8       ; G_4
	NOTE N16, 4       ; D#4
	OCTUP
	NOTE N16, 23      ; A#3
	LOOP1 4, .l69AA
	OCTUP
	NOTE N16, 8       ; G_4
.l69B6:
	FLAGS $08
	NOTE N16, 8       ; G_4
	NOTE N16, 2       ; C#4
	OCTUP
	NOTE N16, 23      ; A#3
	LOOP1 4, .l69B6
	OCTUP
	NOTE N16, 8       ; G_4
	NOTE N16, 8       ; G_4
.l69C3:
	FLAGS $00
	NOTE N16, 25      ; C_4
	NOTE N16, 28      ; D#4
	OCTUP
	NOTE N16, 8       ; G_4
	LOOP1 2, .l69C3
	NOTE N16, 4       ; D#4
	NOTE N16, 1       ; C_4
	NOTE N16, 10      ; A_4
	NOTE N16, 11      ; A#4
	NOTE N8, 7        ; F#4
	CONNECT
	NOTE N8, 3        ; D_4
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 3        ; D_4
	END
Music1D_Ch2:
	OCTAVE 1
	TEMPO $010B
	HOLD 200
	VOLUME $0A
	PAN $01
	DUTY $80
	DETUNE -1
	TRIPLET
	REST N8
	INSTR 6
	DOTTED
	TRIPLET
	CONNECT
	NOTE N4, 20       ; G_4
	INSTR 11
	CONNECT
	NOTE N2, 20       ; G_4
	INSTR 4
	TRIPLET
	CONNECT
	NOTE N16, 18      ; F_4
	CONNECT
	NOTE N8, 18       ; F_4
	INSTR 6
	DOTTED
	TRIPLET
	CONNECT
	NOTE N4, 16       ; D#4
	INSTR 11
	CONNECT
	NOTE N2, 16       ; D#4
	INSTR 4
	TRIPLET
	CONNECT
	NOTE N16, 15      ; D_4
	CONNECT
	NOTE N8, 15       ; D_4
	INSTR 6
	TRIPLET
	CONNECT
	NOTE N2, 13       ; C_4
	INSTR 11
	DOTTED
	NOTE N4, 13       ; C_4
	TRIPLET
	NOTE N16, 13      ; C_4
	CONNECT
	NOTE N8, 13       ; C_4
	INSTR 6
	TRIPLET
	CONNECT
	NOTE N2, 15       ; D_4
	INSTR 11
	DOTTED
	NOTE N4, 15       ; D_4
	TRIPLET
	CONNECT
	NOTE N16, 15      ; D_4
	PAN $11
	DETUNE 0
	DUTY $40
	VOLUME $0D
	INSTR 5
	TRIPLET
	CONNECT
	OCTUP
	NOTE N4, 11       ; A#5
	INSTR 11
	CONNECT
	NOTE N2, 11       ; A#5
	REST N8
	INSTR 4
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N8, 11       ; A#5
	NOTE N16, 10      ; A_5
	INSTR 4
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 11
	NOTE N2, 8        ; G_5
	CONNECT
	NOTE N16, 8       ; G_5
	DOTTED
	REST N4
	INSTR 4
	NOTE N16, 8       ; G_5
	NOTE N16, 10      ; A_5
	NOTE N8, 11       ; A#5
	NOTE N8, 10       ; A_5
	NOTE N8, 11       ; A#5
	NOTE N16, 13      ; C_6
	CONNECT
	NOTE N16, 10      ; A_5
	INSTR 11
	NOTE N8, 10       ; A_5
	CONNECT
	NOTE N4, 10       ; A_5
	REST N8
	DUTY $80
	INSTR 4
	DOTTED
	NOTE N8, 10       ; A_5
	DOTTED
	NOTE N8, 11       ; A#5
	NOTE N8, 13       ; C_6
	NOTE N4, 8        ; G_5
	NOTE N4, 10       ; A_5
	NOTE N4, 11       ; A#5
	NOTE N16, 13      ; C_6
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 6       ; F_5
	NOTE N8, 10       ; A_5
	NOTE N16, 11      ; A#5
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 8
	NOTE N2, 8        ; G_5
	CONNECT
	NOTE N16, 8       ; G_5
	REST N4
	INSTR 4
	NOTE N8, 8        ; G_5
	NOTE N8, 10       ; A_5
	NOTE N8, 11       ; A#5
	CONNECT
	NOTE N8, 13       ; C_6
	INSTR 8
	CONNECT
	NOTE N4, 13       ; C_6
	INSTR 4
	NOTE N16, 11      ; A#5
	CONNECT
	NOTE N4, 10       ; A_5
	INSTR 8
	NOTE N2, 10       ; A_5
	CONNECT
	NOTE N8, 10       ; A_5
	REST N16
	DUTY $00
	INSTR 6
	NOTE N4, 8        ; G_5
	NOTE N4, 10       ; A_5
	NOTE N4, 11       ; A#5
	NOTE N16, 13      ; C_6
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 6       ; F_5
	NOTE N8, 10       ; A_5
	NOTE N16, 11      ; A#5
	NOTE N8, 13       ; C_6
	NOTE N8, 10       ; A_5
	CONNECT
	NOTE N16, 6       ; F_5
	INSTR 8
	CONNECT
	NOTE N4, 6        ; F_5
	REST N8
	INSTR 6
	NOTE N8, 6        ; F_5
	TRIPLET
	NOTE N64, 7       ; F#5
	DOTTED
	TRIPLET
	CONNECT
	NOTE N16, 8       ; G_5
	TRIPLET
	CONNECT
	NOTE N32, 8       ; G_5
	TRIPLET
	NOTE N16, 6       ; F_5
	NOTE N8, 8        ; G_5
	NOTE N8, 6        ; F_5
	NOTE N8, 8        ; G_5
	REST N16
	NOTE N4, 11       ; A#5
	NOTE N16, 13      ; C_6
	CONNECT
	NOTE N16, 10      ; A_5
	NOTE N8, 10       ; A_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 10       ; A_5
	INSTR 6
	NOTE N4, 15       ; D_6
	NOTE N4, 13       ; C_6
	CONNECT
	NOTE N8, 11       ; A#5
	INSTR 8
	CONNECT
	NOTE N4, 11       ; A#5
	INSTR 4
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	INSTR 6
	CONNECT
	NOTE N4, 11       ; A#5
	INSTR 8
	CONNECT
	NOTE N16, 11      ; A#5
	INSTR 4
	NOTE N8, 8        ; G_5
	NOTE N16, 10      ; A_5
	NOTE N8, 11       ; A#5
	NOTE N16, 10      ; A_5
	NOTE N8, 8        ; G_5
	NOTE N8, 10       ; A_5
	DOTTED
	NOTE N8, 6        ; F_5
	NOTE N4, 8        ; G_5
	NOTE N16, 8       ; G_5
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N8, 13       ; C_6
	NOTE N8, 10       ; A_5
	NOTE N8, 6        ; F_5
	TRIPLET
	NOTE N64, 9       ; G#5
	CONNECT
	NOTE N4, 10       ; A_5
	INSTR 8
	NOTE N64, 10      ; A_5
	TRIPLET
	CONNECT
	NOTE N4, 10       ; A_5
	INSTR 4
	NOTE N16, 11      ; A#5
	NOTE N16, 13      ; C_6
	CONNECT
	NOTE N8, 10       ; A_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 10       ; A_5
	DUTY $80
	INSTR 10
	DOTTED
	NOTE N8, 7        ; F#5
	DOTTED
	NOTE N8, 8        ; G_5
	NOTE N8, 10       ; A_5
	NOTE N4, 8        ; G_5
	NOTE N16, 8       ; G_5
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N8, 10       ; A_5
	NOTE N16, 11      ; A#5
	NOTE N8, 13       ; C_6
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 8       ; G_5
	NOTE N16, 10      ; A_5
	NOTE N8, 11       ; A#5
	NOTE N16, 10      ; A_5
	DOTTED
	NOTE N8, 6        ; F_5
	NOTE N4, 8        ; G_5
	NOTE N8, 8        ; G_5
	NOTE N8, 11       ; A#5
	NOTE N16, 8       ; G_5
	TRIPLET
	NOTE N64, 12      ; B_5
	CONNECT
	NOTE N16, 13      ; C_6
	NOTE N64, 13      ; C_6
	TRIPLET
	CONNECT
	NOTE N16, 13      ; C_6
	NOTE N16, 11      ; A#5
	NOTE N8, 8        ; G_5
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 8       ; G_5
	NOTE N8, 10       ; A_5
	NOTE N16, 11      ; A#5
	NOTE N4, 13       ; C_6
	NOTE N16, 13      ; C_6
	CONNECT
	NOTE N16, 15      ; D_6
	INSTR 8
	CONNECT
	NOTE N4, 15       ; D_6
	INSTR 6
	CONNECT
	NOTE N8, 10       ; A_5
	INSTR 8
	CONNECT
	NOTE N2, 10       ; A_5
	REST N16
	INSTR 10
	NOTE N32, 7       ; F#5
	NOTE N32, 8       ; G_5
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 10
	NOTE N16, 6       ; F_5
	NOTE N16, 8       ; G_5
	NOTE N16, 11      ; A#5
	NOTE N16, 8       ; G_5
	NOTE N16, 13      ; C_6
	NOTE N16, 11      ; A#5
	CONNECT
	NOTE N16, 8       ; G_5
	INSTR 8
	NOTE N4, 8        ; G_5
	CONNECT
	NOTE N2, 8        ; G_5
	INSTR 10
	NOTE N16, 8       ; G_5
	TRIPLET
	NOTE N64, 9       ; G#5
	TRIPLET
	CONNECT
	NOTE N4, 10       ; A_5
	TRIPLET
	NOTE N16, 10      ; A_5
	INSTR 8
	NOTE N64, 10      ; A_5
	TRIPLET
	CONNECT
	NOTE N2, 10       ; A_5
	INSTR 10
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N16, 11      ; A#5
	NOTE N8, 13       ; C_6
	REST N8
	TRIPLET
	NOTE N64, 14      ; C#6
	DOTTED
	TRIPLET
	CONNECT
	NOTE N8, 15       ; D_6
	TRIPLET
	NOTE N16, 15      ; D_6
	NOTE N64, 15      ; D_6
	INSTR 8
	TRIPLET
	CONNECT
	NOTE N2, 15       ; D_6
	INSTR 10
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	NOTE N8, 8        ; G_5
	NOTE N16, 6       ; F_5
	NOTE N16, 8       ; G_5
	NOTE N16, 13      ; C_6
	NOTE N8, 11       ; A#5
	NOTE N16, 15      ; D_6
	NOTE N16, 11      ; A#5
	NOTE N8, 8        ; G_5
	NOTE N8, 10       ; A_5
	NOTE N16, 6       ; F_5
	NOTE N16, 4       ; D#5
	NOTE N16, 3       ; D_5
	NOTE N8, 1        ; C_5
	NOTE N16, 3       ; D_5
	NOTE N8, 6        ; F_5
	DOTTED
	CONNECT
	NOTE N8, 8        ; G_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	INSTR 10
	TRIPLET
	NOTE N64, 9       ; G#5
	DOTTED
	TRIPLET
	CONNECT
	NOTE N16, 10      ; A_5
	TRIPLET
	NOTE N32, 10      ; A_5
	INSTR 8
	DOTTED
	TRIPLET
	CONNECT
	NOTE N4, 10       ; A_5
	INSTR 10
	CONNECT
	NOTE N8, 6        ; F_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 6        ; F_5
	INSTR 10
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	DOTTED
	CONNECT
	NOTE N16, 8       ; G_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	PAN $01
	VOLUME $07
	INSTR 10
.l6BBB:
	FLAGS $00
	NOTE N16, 20      ; G_4
	NOTE N16, 16      ; D#4
	NOTE N16, 11      ; A#3
	LOOP1 1, .l6BBB
	NOTE N32, 20      ; G_4
	PAN $11
	VOLUME $0D
	OCTUP
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	DOTTED
	CONNECT
	NOTE N16, 8       ; G_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	VOLUME $07
	INSTR 10
	PAN $01
.l6BDA:
	FLAGS $00
	NOTE N16, 20      ; G_4
	NOTE N16, 14      ; C#4
	NOTE N16, 11      ; A#3
	LOOP1 1, .l6BDA
	NOTE N32, 20      ; G_4
	PAN $11
	VOLUME $0D
	OCTUP
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	CONNECT
	NOTE N8, 8        ; G_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	REST N8
	INSTR 10
	NOTE N16, 7       ; F#5
	NOTE N16, 8       ; G_5
	NOTE N16, 11      ; A#5
	NOTE N16, 10      ; A_5
	CONNECT
	NOTE N8, 8        ; G_5
	INSTR 8
	DOTTED
	CONNECT
	NOTE N4, 8        ; G_5
	END
Music1D_Ch3:
	OCTAVE 0
	TEMPO $010B
	HOLD 200
	VOLUME $02
.l6C0A:
	FLAGS $48
	INSTR 8
	INSTR 9
	DOTTED
	NOTE N4, 20       ; G_5
	INSTR 8
	CONNECT
	NOTE N2, 20       ; G_5
	INSTR 9
	NOTE N8, 18       ; F_5
	DOTTED
	CONNECT
	NOTE N4, 16       ; D#5
	INSTR 8
	CONNECT
	NOTE N2, 16       ; D#5
	INSTR 9
	NOTE N8, 15       ; D_5
	CONNECT
	NOTE N2, 13       ; C_5
	INSTR 8
	CONNECT
	NOTE N2, 13       ; C_5
	INSTR 9
	CONNECT
	NOTE N2, 15       ; D_5
	INSTR 8
	CONNECT
	NOTE N2, 15       ; D_5
	LOOP1 1, .l6C0A
	INSTR 16
	VOLUME $03
	DOTTED
	OCTUP
	NOTE N2, 20       ; G_3
	REST N8
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N2, 16       ; D#3
	REST N8
	NOTE N8, 15       ; D_3
	NOTE N1, 13       ; C_3
	NOTE N1, 15       ; D_3
	DOTTED
	NOTE N2, 20       ; G_3
	REST N8
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N2, 16       ; D#3
	REST N8
	NOTE N8, 15       ; D_3
	DOTTED
	NOTE N2, 13       ; C_3
	REST N16
	NOTE N16, 11      ; A#2
	NOTE N16, 13      ; C_3
	CONNECT
	NOTE N16, 15      ; D_3
	CONNECT
	NOTE N2, 15       ; D_3
	DOTTED
	NOTE N8, 19       ; F#3
	DOTTED
	NOTE N8, 20       ; G_3
	NOTE N8, 22       ; A_3
	DOTTED
	NOTE N2, 20       ; G_3
	REST N8
	NOTE N8, 18       ; F_3
	DOTTED
	NOTE N2, 16       ; D#3
	REST N8
	NOTE N8, 15       ; D_3
	NOTE N1, 13       ; C_3
	NOTE N2, 15       ; D_3
	REST N16
	NOTE N16, 22      ; A_3
	NOTE N16, 25      ; C_4
	NOTE N16, 22      ; A_3
	NOTE N16, 23      ; A#3
	NOTE N16, 22      ; A_3
	NOTE N16, 20      ; G_3
	NOTE N16, 18      ; F_3
.l6C6C:
	FLAGS $00
	NOTE N8, 20       ; G_3
	LOOP1 6, .l6C6C
	NOTE N8, 18       ; F_3
.l6C74:
	FLAGS $00
	NOTE N8, 16       ; D#3
	LOOP1 6, .l6C74
	NOTE N8, 15       ; D_3
.l6C7C:
	FLAGS $00
	NOTE N8, 13       ; C_3
	LOOP1 5, .l6C7C
	NOTE N16, 13      ; C_3
	NOTE N16, 11      ; A#2
	NOTE N16, 13      ; C_3
	CONNECT
	NOTE N16, 15      ; D_3
	CONNECT
	NOTE N16, 15      ; D_3
.l6C8A:
	FLAGS $00
	NOTE N16, 15      ; D_3
	REST N16
	LOOP1 2, .l6C8A
	NOTE N16, 15      ; D_3
	DOTTED
	NOTE N8, 19       ; F#3
	DOTTED
	NOTE N8, 20       ; G_3
	NOTE N8, 22       ; A_3
.l6C98:
	FLAGS $00
	NOTE N8, 20       ; G_3
	LOOP1 5, .l6C98
	NOTE N16, 20      ; G_3
	NOTE N8, 23       ; A#3
	NOTE N16, 20      ; G_3
.l6CA2:
	FLAGS $00
	NOTE N8, 25       ; C_4
	LOOP1 5, .l6CA2
	NOTE N16, 25      ; C_4
	NOTE N8, 23       ; A#3
	NOTE N16, 20      ; G_3
.l6CAC:
	FLAGS $00
	NOTE N8, 18       ; F_3
	LOOP1 5, .l6CAC
	NOTE N16, 18      ; F_3
	NOTE N8, 22       ; A_3
	NOTE N16, 25      ; C_4
	NOTE N8, 28       ; D#4
	REST N8
	NOTE N2, 27       ; D_4
	NOTE N16, 22      ; A_3
	NOTE N16, 20      ; G_3
	NOTE N8, 18       ; F_3
.l6CBC:
	FLAGS $00
	NOTE N8, 20       ; G_3
	LOOP1 5, .l6CBC
	NOTE N16, 20      ; G_3
	NOTE N8, 23       ; A#3
	NOTE N16, 20      ; G_3
.l6CC6:
	FLAGS $00
	NOTE N8, 25       ; C_4
	LOOP1 5, .l6CC6
	NOTE N16, 25      ; C_4
	NOTE N8, 23       ; A#3
	NOTE N16, 20      ; G_3
.l6CD0:
	FLAGS $00
	NOTE N8, 18       ; F_3
	LOOP1 3, .l6CD0
	NOTE N8, 15       ; D_3
.l6CD8:
	FLAGS $00
	NOTE N8, 15       ; D_3
	NOTE N16, 15      ; D_3
	LOOP1 1, .l6CD8
.l6CE0:
	FLAGS $00
	NOTE N8, 16       ; D#3
	LOOP1 7, .l6CE0
.l6CE7:
	FLAGS $00
	NOTE N8, 14       ; C#3
	LOOP1 7, .l6CE7
.l6CEE:
	FLAGS $00
	NOTE N8, 13       ; C_3
	LOOP1 3, .l6CEE
	NOTE N8, 10       ; A_2
	NOTE N8, 10       ; A_2
	NOTE N8, 11       ; A#2
	NOTE N8, 13       ; C_3
	NOTE N2, 8        ; G_2
	END
Music1D_Ch4:
	OCTAVE 0
	TEMPO $010B
	HOLD 50
	VOLUME $06
	REST N1
	REST N1
	REST N1
	REST N1
	INSTR 10
.l6D0A:
	FLAGS $00
	REST N4
	NOTE N4, 9
	REST N4
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 3, .l6D0A
.l6D16:
	FLAGS $00
	REST N4
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 6, .l6D16
	INSTR 14
	REST N8
	NOTE N8, 15
	NOTE N8, 14
	NOTE N8, 13
.l6D26:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N8, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 14, .l6D26
	INSTR 10
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	NOTE N16, 15
	NOTE N16, 14
	NOTE N16, 13
.l6D42:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 5, .l6D42
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N8, 9
	NOTE N8, 9
	NOTE N16, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	REST N16
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	REST N16
	INSTR 14
	NOTE N16, 13
	NOTE N16, 13
.l6D70:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 5, .l6D70
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 9
	TRIPLET
	NOTE N32, 15
	NOTE N32, 15
	NOTE N32, 15
	INSTR 14
	TRIPLET
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	REST N16
	REST N16
	INSTR 14
	NOTE N16, 13
	INSTR 10
	NOTE N16, 15
	REST N16
	NOTE N16, 9
	INSTR 14
	NOTE N8, 13
.l6DA2:
	FLAGS $00
	INSTR 10
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 5, .l6DA2
.l6DB4:
	FLAGS $00
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
.l6DBD:
	FLAGS $00
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	LOOP1 2, .l6DBD
	LOOP2 1, .l6DB4
	INSTR 14
	NOTE N8, 13
	INSTR 10
	NOTE N16, 15
	NOTE N16, 15
	NOTE N8, 9
	NOTE N16, 15
	NOTE N16, 15
	NOTE N16, 9
	TRIPLET
	NOTE N32, 15
	NOTE N32, 15
	NOTE N32, 15
	TRIPLET
	NOTE N16, 13
	INSTR 14
	NOTE N16, 13
	REST N16
	NOTE N16, 15
	NOTE N16, 14
	NOTE N16, 13
	NOTE N4, 13
	REST N4
	END

;; SFX $1E
Sfx1E:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $3A, $0B, $07, $60  ; CH4: instr 58, vol $0B, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $07, $07, $60       ; CH4: vol $07, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $04, $07, $60       ; CH4: vol $04, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $01, $07, $60       ; CH4: vol $01, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $01, $07, $60       ; CH4: vol $01, slide $07, noise 96
	SFX_END

;; SFX $1F
Sfx1F:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $3A, $01, $07, $60  ; CH4: instr 58, vol $01, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $02, $07, $60       ; CH4: vol $02, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $04, $07, $60       ; CH4: vol $04, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $08, $07, $60       ; CH4: vol $08, slide $07, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 4, %1000         ; CH4
	db $0C, $0B, $07, $60       ; CH4: vol $0B, slide $07, noise 96
	SFX_END

;; SFX $20
Sfx20:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 2, %1001         ; CH1+CH4
	db $0F, $16, $C0, $05, $0F, $2D; CH1: instr 22, duty $C0, vol $05, slide $0F, note 45
	db $0D, $15, $08, $BE, $50  ; CH4: instr 21, vol $08, slide $BE, noise 80
	SEGMENT $FF, %010
	SEG_HOLD $43
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $16, $08, $00, $6D  ; CH4: instr 22, vol $08, slide $00, noise 109
	SFX_END

;; SFX $21
Sfx21:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $25
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $17, $0D, $E4, $6E  ; CH4: instr 23, vol $0D, slide $E4, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $44
	SEG_FRAMES 42, %1000        ; CH4
	db $05, $18, $0A, $42       ; CH4: instr 24, vol $0A, noise 66
	SFX_END

;; SFX $22
Sfx22:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $19, $0C, $FF, $1B  ; CH4: instr 25, vol $0C, slide $FF, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $19, $0C, $FF, $1D  ; CH4: instr 25, vol $0C, slide $FF, noise 29
	SFX_END

;; SFX $23
Sfx23:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $3A, $0B, $8B, $1B  ; CH4: instr 58, vol $0B, slide $8B, noise 27
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 20, %1000        ; CH4
	db $0D, $15, $0B, $B2, $2E  ; CH4: instr 21, vol $0B, slide $B2, noise 46
	SFX_END

;; SFX $24
Sfx24:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $17, $0D, $D0, $6E  ; CH4: instr 23, vol $0D, slide $D0, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $1A, $0D, $A0, $2E  ; CH4: instr 26, vol $0D, slide $A0, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $15, $0D, $A0, $2D  ; CH4: instr 21, vol $0D, slide $A0, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 35, %1000        ; CH4
	db $0D, $15, $0D, $A0, $2D  ; CH4: instr 21, vol $0D, slide $A0, noise 45
	SFX_END

;; SFX $25
Sfx25:
	SFX_PRIORITY 15, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1F, $0E, $FF, $1C  ; CH4: instr 31, vol $0E, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $19, $0E, $02, $1D  ; CH4: instr 25, vol $0E, slide $02, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $15, $0E, $FF, $2C  ; CH4: instr 21, vol $0E, slide $FF, noise 44
	SEGMENT $FF, %010
	SEG_HOLD $7B
	SEG_FRAMES 31, %1000        ; CH4
	db $0D, $15, $0E, $00, $2C  ; CH4: instr 21, vol $0E, slide $00, noise 44
	SFX_END

;; SFX $26
Sfx26:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $16, $09, $A0, $7E  ; CH4: instr 22, vol $09, slide $A0, noise 126
	SFX_END

;; SFX $27
Sfx27:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $19, $0F, $FB, $21  ; CH4: instr 25, vol $0F, slide $FB, noise 33
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $19, $0F, $C3, $21  ; CH4: instr 25, vol $0F, slide $C3, noise 33
	SFX_END

;; SFX $28
Sfx28:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $3A
	SEG_FRAMES 110, %0110       ; CH2+CH3
	db $1F, $17, $40, $0A, $9B, $DB, $20; CH2: instr 23, duty $40, vol $0A, slide $9B, detune $DB, note 32
	db $1F, $1D, $02, $E6, $9B, $F8, $2E; CH3: instr 29, duty $02, vol $E6, slide $9B, detune $F8, note 46
	SFX_END

;; SFX $29
Sfx29:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $16
	SEG_FRAMES 32, %1001        ; CH1+CH4
	db $0D, $17, $07, $87, $19  ; CH1: instr 23, vol $07, slide $87, note 25
	db $0D, $16, $0E, $84, $3B  ; CH4: instr 22, vol $0E, slide $84, noise 59
	SFX_END

;; SFX $2A
Sfx2A:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $0C
	SEG_FRAMES 13, %1001        ; CH1+CH4
	db $0D, $16, $09, $0F, $2D  ; CH1: instr 22, vol $09, slide $0F, note 45
	db $0D, $15, $0C, $BE, $50  ; CH4: instr 21, vol $0C, slide $BE, noise 80
	SEGMENT $FF, %010
	SEG_HOLD $0A
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $16, $0B, $00, $6D  ; CH4: instr 22, vol $0B, slide $00, noise 109
	SFX_END

;; SFX $2B
Sfx2B:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 4, %1001         ; CH1+CH4
	db $0D, $16, $0A, $0F, $2D  ; CH1: instr 22, vol $0A, slide $0F, note 45
	db $0D, $15, $0D, $FF, $6E  ; CH4: instr 21, vol $0D, slide $FF, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $29
	SEG_FRAMES 41, %1000        ; CH4
	db $0D, $15, $0C, $91, $70  ; CH4: instr 21, vol $0C, slide $91, noise 112
	SFX_END

;; SFX $2C
Sfx2C:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 4, %1000         ; CH4
	db $1D, $15, $06, $29, $D4, $7F; CH4: instr 21, vol $06, slide $29, detune $D4, noise 127
	SEGMENT $FF, %010
	SEG_HOLD $17
	SEG_FRAMES 19, %1000        ; CH4
	db $1D, $19, $06, $16, $D4, $7F; CH4: instr 25, vol $06, slide $16, detune $D4, noise 127
	SFX_END

;; SFX $2D
Sfx2D:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $07, $15, $80, $07, $40  ; CH1: instr 21, duty $80, vol $07, note 64
	db $05, $16, $0B, $4D       ; CH4: instr 22, vol $0B, noise 77
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 5, %1001         ; CH1+CH4
	db $06, $80, $07, $4E       ; CH1: duty $80, vol $07, note 78
	db $04, $0B, $33            ; CH4: vol $0B, noise 51
	SFX_END

;; SFX $2E
Sfx2E:
	SFX_PRIORITY 22, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $0F, $15, $80, $0F, $1C, $0B; CH1: instr 21, duty $80, vol $0F, slide $1C, note 11
	db $1F, $15, $40, $0F, $1C, $FC, $02; CH2: instr 21, duty $40, vol $0F, slide $1C, detune $FC, note 2
	db $0D, $1E, $0F, $9A, $2B  ; CH4: instr 30, vol $0F, slide $9A, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 26, %0011        ; CH1+CH2
	db $0F, $1E, $80, $0F, $FF, $12; CH1: instr 30, duty $80, vol $0F, slide $FF, note 18
	db $1F, $16, $40, $0D, $DC, $FC, $18; CH2: instr 22, duty $40, vol $0D, slide $DC, detune $FC, note 24
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0F, $1E, $80, $0D, $FF, $12; CH1: instr 30, duty $80, vol $0D, slide $FF, note 18
	db $1F, $16, $40, $0B, $16, $FC, $28; CH2: instr 22, duty $40, vol $0B, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0F, $1E, $80, $0B, $FF, $12; CH1: instr 30, duty $80, vol $0B, slide $FF, note 18
	db $1F, $16, $40, $09, $16, $FC, $28; CH2: instr 22, duty $40, vol $09, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0F, $1E, $80, $09, $FF, $12; CH1: instr 30, duty $80, vol $09, slide $FF, note 18
	db $1F, $16, $40, $07, $16, $FC, $28; CH2: instr 22, duty $40, vol $07, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0F, $1E, $80, $07, $FF, $12; CH1: instr 30, duty $80, vol $07, slide $FF, note 18
	db $1F, $16, $40, $05, $16, $FC, $28; CH2: instr 22, duty $40, vol $05, slide $16, detune $FC, note 40
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0F, $1E, $80, $05, $FF, $12; CH1: instr 30, duty $80, vol $05, slide $FF, note 18
	db $1F, $16, $40, $03, $16, $FC, $28; CH2: instr 22, duty $40, vol $03, slide $16, detune $FC, note 40
	SFX_END

;; SFX $2F
Sfx2F:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 2, %1001         ; CH1+CH4
	db $0F, $15, $80, $0B, $10, $14; CH1: instr 21, duty $80, vol $0B, slide $10, note 20
	db $0D, $19, $0B, $FF, $1C  ; CH4: instr 25, vol $0B, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $15, $80, $0B, $16, $14; CH1: instr 21, duty $80, vol $0B, slide $16, note 20
	db $0D, $19, $0B, $FF, $1C  ; CH4: instr 25, vol $0B, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $38
	SEG_FRAMES 61, %1000        ; CH4
	db $0D, $1F, $0B, $9E, $6F  ; CH4: instr 31, vol $0B, slide $9E, noise 111
	SFX_END

;; SFX $30
Sfx30:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 2, %0001         ; CH1
	db $07, $17, $C0, $0C, $2F  ; CH1: instr 23, duty $C0, vol $0C, note 47
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $03
	SEG_FRAMES 2, %0001         ; CH1
	db $07, $17, $C0, $07, $2F  ; CH1: instr 23, duty $C0, vol $07, note 47
	SFX_END

;; SFX $31
Sfx31:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $15, $80, $09, $38  ; CH1: instr 21, duty $80, vol $09, note 56
	db $07, $15, $80, $09, $31  ; CH2: instr 21, duty $80, vol $09, note 49
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $07, $15, $80, $09, $38  ; CH1: instr 21, duty $80, vol $09, note 56
	db $07, $15, $80, $09, $31  ; CH2: instr 21, duty $80, vol $09, note 49
	SFX_END

;; SFX $32
Sfx32:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $07, $17, $C0, $09, $30  ; CH1: instr 23, duty $C0, vol $09, note 48
	db $17, $17, $C0, $09, $FE, $30; CH2: instr 23, duty $C0, vol $09, detune $FE, note 48
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $09, $2C       ; CH1: duty $C0, vol $09, note 44
	db $16, $C0, $09, $FE, $2C  ; CH2: duty $C0, vol $09, detune $FE, note 44
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $04, $2C       ; CH1: duty $C0, vol $04, note 44
	db $16, $C0, $04, $FE, $2C  ; CH2: duty $C0, vol $04, detune $FE, note 44
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $06, $C0, $02, $2C       ; CH1: duty $C0, vol $02, note 44
	db $16, $C0, $02, $FE, $2C  ; CH2: duty $C0, vol $02, detune $FE, note 44
	SFX_END

;; SFX $33
Sfx33:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $17, $06, $EF, $2F  ; CH4: instr 23, vol $06, slide $EF, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $11
	SEG_FRAMES 21, %1000        ; CH4
	db $0D, $16, $06, $EF, $2F  ; CH4: instr 22, vol $06, slide $EF, noise 47
	SFX_END

;; SFX $34
Sfx34:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $0B
	SEG_FRAMES 11, %1000        ; CH4
	db $0D, $1B, $0B, $DD, $6F  ; CH4: instr 27, vol $0B, slide $DD, noise 111
	SFX_END

;; SFX $35
Sfx35:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $15, $0E, $9A, $3D  ; CH4: instr 21, vol $0E, slide $9A, noise 61
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 36, %1000        ; CH4
	db $0D, $1B, $0E, $D3, $44  ; CH4: instr 27, vol $0E, slide $D3, noise 68
	SFX_END

;; SFX $36
Sfx36:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0C, $73, $53; CH1: instr 33, duty $C0, vol $0C, slide $73, note 83
	db $0D, $16, $0C, $84, $2F  ; CH4: instr 22, vol $0C, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0C, $73, $53; CH1: instr 33, duty $C0, vol $0C, slide $73, note 83
	db $0D, $16, $0C, $84, $2F  ; CH4: instr 22, vol $0C, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $6E
	SEG_FRAMES 20, %1001        ; CH1+CH4
	db $0C, $0C, $09, $53       ; CH1: vol $0C, slide $09, note 83
	db $09, $20, $86, $3E       ; CH4: instr 32, slide $86, noise 62
	SFX_END

;; SFX $37
Sfx37:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $C9
	SEG_FRAMES 8, %1000         ; CH4
	db $0D, $19, $0E, $8A, $5E  ; CH4: instr 25, vol $0E, slide $8A, noise 94
	SEGMENT $FF, %010
	SEG_HOLD $1F
	SEG_FRAMES 31, %1000        ; CH4
	db $0D, $1B, $0E, $88, $2B  ; CH4: instr 27, vol $0E, slide $88, noise 43
	SFX_END

;; SFX $38
Sfx38:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $1F, $0A, $0C, $0C  ; CH4: instr 31, vol $0A, slide $0C, noise 12
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $1F, $06, $0C, $0D  ; CH4: instr 31, vol $06, slide $0C, noise 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1000         ; CH4
	db $0D, $1F, $06, $0C, $0E  ; CH4: instr 31, vol $06, slide $0C, noise 14
	SFX_END

;; SFX $39
Sfx39:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0D, $73, $53; CH1: instr 33, duty $C0, vol $0D, slide $73, note 83
	db $0D, $16, $0D, $84, $2F  ; CH4: instr 22, vol $0D, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0D, $73, $53; CH1: instr 33, duty $C0, vol $0D, slide $73, note 83
	db $0D, $16, $09, $84, $2F  ; CH4: instr 22, vol $09, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0D, $73, $53; CH1: instr 33, duty $C0, vol $0D, slide $73, note 83
	db $0D, $16, $08, $84, $2F  ; CH4: instr 22, vol $08, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $6E
	SEG_FRAMES 20, %1001        ; CH1+CH4
	db $0C, $0D, $09, $53       ; CH1: vol $0D, slide $09, note 83
	db $0D, $20, $05, $86, $3E  ; CH4: instr 32, vol $05, slide $86, noise 62
	SFX_END

;; SFX $3A
Sfx3A:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $20, $0C, $84, $2F  ; CH4: instr 32, vol $0C, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0C, $73, $53; CH1: instr 33, duty $C0, vol $0C, slide $73, note 83
	db $0D, $20, $0C, $84, $2F  ; CH4: instr 32, vol $0C, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $FF
	SEG_FRAMES 3, %1001         ; CH1+CH4
	db $0F, $21, $C0, $0C, $73, $53; CH1: instr 33, duty $C0, vol $0C, slide $73, note 83
	db $0D, $20, $0C, $84, $2F  ; CH4: instr 32, vol $0C, slide $84, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $64
	SEG_FRAMES 17, %1001        ; CH1+CH4
	db $0C, $0C, $09, $53       ; CH1: vol $0C, slide $09, note 83
	db $0D, $20, $08, $86, $3E  ; CH4: instr 32, vol $08, slide $86, noise 62
	SFX_END

;; SFX $3B
Sfx3B:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $7C
	SEG_FRAMES 124, %1000       ; CH4
	db $0D, $1E, $09, $02, $5E  ; CH4: instr 30, vol $09, slide $02, noise 94
	SFX_END

;; SFX $3C
Sfx3C:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $16, $08, $FF, $3F  ; CH4: instr 22, vol $08, slide $FF, noise 63
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $15, $80, $04, $35  ; CH1: instr 21, duty $80, vol $04, note 53
	db $17, $15, $80, $04, $02, $35; CH2: instr 21, duty $80, vol $04, detune $02, note 53
	SFX_END

;; SFX $3D
Sfx3D:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 5, %0011         ; CH1+CH2
	db $0F, $15, $C0, $0E, $0C, $0D; CH1: instr 21, duty $C0, vol $0E, slide $0C, note 13
	db $1F, $15, $C0, $0E, $0C, $F6, $0D; CH2: instr 21, duty $C0, vol $0E, slide $0C, detune $F6, note 13
	SEGMENT $FF, %010
	SEG_HOLD $3D
	SEG_FRAMES 110, %0011       ; CH1+CH2
	db $0F, $17, $C0, $0D, $94, $15; CH1: instr 23, duty $C0, vol $0D, slide $94, note 21
	db $1F, $17, $C0, $0D, $94, $F6, $15; CH2: instr 23, duty $C0, vol $0D, slide $94, detune $F6, note 21
	SFX_END

;; SFX $3E
Sfx3E:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0001         ; CH1
	db $07, $17, $80, $08, $34  ; CH1: instr 23, duty $80, vol $08, note 52
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0001         ; CH1
	db $07, $17, $80, $06, $34  ; CH1: instr 23, duty $80, vol $06, note 52
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $07, $17, $80, $08, $2B  ; CH1: instr 23, duty $80, vol $08, note 43
	db $17, $17, $80, $08, $FE, $2B; CH2: instr 23, duty $80, vol $08, detune $FE, note 43
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $17, $80, $04, $2B  ; CH1: instr 23, duty $80, vol $04, note 43
	db $17, $17, $80, $04, $FE, $2B; CH2: instr 23, duty $80, vol $04, detune $FE, note 43
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $17, $80, $02, $2B  ; CH1: instr 23, duty $80, vol $02, note 43
	db $17, $17, $80, $02, $FE, $2B; CH2: instr 23, duty $80, vol $02, detune $FE, note 43
	SFX_END

;; SFX $3F
Sfx3F:
	SFX_PRIORITY 9, 0
.l72AC:
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $05, $17, $08, $34       ; CH1: instr 23, vol $08, note 52
	SEGMENT $FF, %011
	SEG_LOOP 65, .l72AC
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SFX_END

;; SFX $40
Sfx40:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $08
	SEG_FRAMES 8, %0001         ; CH1
	db $0D, $1B, $0F, $C1, $09  ; CH1: instr 27, vol $0F, slide $C1, note 9
	SFX_END

;; SFX $41
Sfx41:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 4, %1000         ; CH4
	db $1D, $17, $09, $C1, $D4, $3C; CH4: instr 23, vol $09, slide $C1, detune $D4, noise 60
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 19, %1000        ; CH4
	db $1D, $15, $09, $00, $D4, $7F; CH4: instr 21, vol $09, slide $00, detune $D4, noise 127
	SFX_END

;; SFX $42
Sfx42:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 8, %1000         ; CH4
	db $0D, $19, $0F, $9C, $5E  ; CH4: instr 25, vol $0F, slide $9C, noise 94
	SEGMENT $FF, %010
	SEG_HOLD $2E
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $1B, $0F, $00, $2B  ; CH4: instr 27, vol $0F, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $41
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0F, $00, $2A       ; CH4: vol $0F, slide $00, noise 42
	SEGMENT $FF, %010
	SEG_HOLD $41
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0F, $00, $2B       ; CH4: vol $0F, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 60, %1000        ; CH4
	db $0C, $0F, $00, $2A       ; CH4: vol $0F, slide $00, noise 42
	SFX_END

;; SFX $43
Sfx43:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $17, $80, $0C, $29  ; CH1: instr 23, duty $80, vol $0C, note 41
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0001         ; CH1
	db $07, $17, $80, $07, $29  ; CH1: instr 23, duty $80, vol $07, note 41
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0001         ; CH1
	db $07, $17, $80, $04, $29  ; CH1: instr 23, duty $80, vol $04, note 41
	SFX_END

;; SFX $44
Sfx44:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $12
	SEG_FRAMES 24, %0011        ; CH1+CH2
	db $0D, $1F, $0E, $8C, $07  ; CH1: instr 31, vol $0E, slide $8C, note 7
	db $1D, $1F, $0E, $8C, $FA, $07; CH2: instr 31, vol $0E, slide $8C, detune $FA, note 7
	SEGMENT $FF, %010
	SEG_HOLD $2D
	SEG_FRAMES 61, %0011        ; CH1+CH2
	db $0D, $19, $0E, $35, $06  ; CH1: instr 25, vol $0E, slide $35, note 6
	db $1D, $19, $0E, $35, $FE, $06; CH2: instr 25, vol $0E, slide $35, detune $FE, note 6
	SFX_END

;; SFX $45
Sfx45:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 19, %1000        ; CH4
	db $0D, $23, $0C, $A7, $2C  ; CH4: instr 35, vol $0C, slide $A7, noise 44
	SFX_END

;; SFX $46
Sfx46:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $A6
	SEG_FRAMES 166, %1000       ; CH4
	db $05, $24, $0A, $1A       ; CH4: instr 36, vol $0A, noise 26
	SFX_END

;; SFX $47
Sfx47:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $F7
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $1F, $0B, $B2, $3F  ; CH4: instr 31, vol $0B, slide $B2, noise 63
	SEGMENT $FF, %010
	SEG_HOLD $79
	SEG_FRAMES 31, %1000        ; CH4
	db $0D, $1F, $0B, $B2, $3E  ; CH4: instr 31, vol $0B, slide $B2, noise 62
	SFX_END

;; SFX $48
Sfx48:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 11, %1001        ; CH1+CH4
	db $0F, $1B, $C0, $0D, $C6, $19; CH1: instr 27, duty $C0, vol $0D, slide $C6, note 25
	db $0D, $1E, $0B, $CF, $21  ; CH4: instr 30, vol $0B, slide $CF, noise 33
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 10, %1001        ; CH1+CH4
	db $0E, $C0, $09, $C6, $19  ; CH1: duty $C0, vol $09, slide $C6, note 25
	db $0C, $07, $CF, $21       ; CH4: vol $07, slide $CF, noise 33
	SFX_END

;; SFX $49
Sfx49:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $0E
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $1A, $40, $0C, $21  ; CH1: instr 26, duty $40, vol $0C, note 33
	db $17, $1A, $40, $0C, $F9, $21; CH2: instr 26, duty $40, vol $0C, detune $F9, note 33
	SEGMENT $FF, %000
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $07, $1A, $40, $08, $21  ; CH1: instr 26, duty $40, vol $08, note 33
	db $17, $1A, $40, $08, $F9, $21; CH2: instr 26, duty $40, vol $08, detune $F9, note 33
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $07, $1A, $40, $08, $21  ; CH1: instr 26, duty $40, vol $08, note 33
	db $17, $1A, $40, $08, $F9, $21; CH2: instr 26, duty $40, vol $08, detune $F9, note 33
	SFX_END

;; SFX $4A
Sfx4A:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $1D
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1E, $0C, $9B, $6F  ; CH4: instr 30, vol $0C, slide $9B, noise 111
	SEGMENT $FF, %010
	SEG_HOLD $41
	SEG_FRAMES 15, %1000        ; CH4
	db $0D, $1E, $0C, $9B, $2E  ; CH4: instr 30, vol $0C, slide $9B, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 15, %1000        ; CH4
	db $0D, $1E, $0C, $9B, $2F  ; CH4: instr 30, vol $0C, slide $9B, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 60, %1000        ; CH4
	db $0D, $1E, $0C, $9B, $30  ; CH4: instr 30, vol $0C, slide $9B, noise 48
	SFX_END

;; SFX $4B
Sfx4B:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $12
	SEG_FRAMES 18, %0011        ; CH1+CH2
	db $0D, $1F, $0E, $8C, $07  ; CH1: instr 31, vol $0E, slide $8C, note 7
	db $1D, $1F, $0E, $8C, $FA, $07; CH2: instr 31, vol $0E, slide $8C, detune $FA, note 7
	SFX_END

;; SFX $4C
Sfx4C:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0001         ; CH1
	db $07, $1A, $80, $0B, $2E  ; CH1: instr 26, duty $80, vol $0B, note 46
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $06, $2E  ; CH1: instr 26, duty $80, vol $06, note 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $02, $2E  ; CH1: instr 26, duty $80, vol $02, note 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $02, $2E  ; CH1: instr 26, duty $80, vol $02, note 46
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $02, $2E  ; CH1: instr 26, duty $80, vol $02, note 46
	SFX_END

;; SFX $4D
Sfx4D:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1E, $0A, $FF, $1C  ; CH4: instr 30, vol $0A, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1011         ; CH1+CH2+CH4
	db $07, $15, $C0, $09, $3B  ; CH1: instr 21, duty $C0, vol $09, note 59
	db $07, $15, $C0, $09, $3B  ; CH2: instr 21, duty $C0, vol $09, note 59
	db $0C, $0A, $FF, $1C       ; CH4: vol $0A, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $65
	SEG_FRAMES 36, %0011        ; CH1+CH2
	db $06, $C0, $09, $41       ; CH1: duty $C0, vol $09, note 65
	db $06, $C0, $09, $41       ; CH2: duty $C0, vol $09, note 65
	SFX_END

;; SFX $4E
Sfx4E:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $19, $0E, $FF, $1C  ; CH4: instr 25, vol $0E, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $09
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $1B, $0D, $00, $2B  ; CH4: instr 27, vol $0D, slide $00, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $09
	SEG_FRAMES 6, %1000         ; CH4
	db $0C, $0C, $00, $2B       ; CH4: vol $0C, slide $00, noise 43
	SFX_END

;; SFX $4F
Sfx4F:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $19, $0C, $FF, $1C  ; CH4: instr 25, vol $0C, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $0A
	SEG_FRAMES 5, %1000         ; CH4
	db $0D, $19, $0A, $9C, $60  ; CH4: instr 25, vol $0A, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $06
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $1B, $0C, $03, $2B  ; CH4: instr 27, vol $0C, slide $03, noise 43
	SFX_END

;; SFX $50
Sfx50:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 6, %1001         ; CH1+CH4
	db $0F, $1B, $40, $09, $B3, $32; CH1: instr 27, duty $40, vol $09, slide $B3, note 50
	db $0D, $19, $0D, $FF, $52  ; CH4: instr 25, vol $0D, slide $FF, noise 82
	SEGMENT $FF, %010
	SEG_HOLD $1C
	SEG_FRAMES 36, %1001        ; CH1+CH4
	db $0D, $15, $07, $A4, $35  ; CH1: instr 21, vol $07, slide $A4, note 53
	db $0D, $15, $0B, $A5, $45  ; CH4: instr 21, vol $0B, slide $A5, noise 69
	SFX_END

;; SFX $51
Sfx51:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $15, $0A, $E4, $1D  ; CH4: instr 21, vol $0A, slide $E4, noise 29
	SEGMENT $FF, %010
	SEG_HOLD $25
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $17, $0A, $E4, $6E  ; CH4: instr 23, vol $0A, slide $E4, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $44
	SEG_FRAMES 26, %1000        ; CH4
	db $05, $18, $09, $3E       ; CH4: instr 24, vol $09, noise 62
	SFX_END

;; SFX $52
Sfx52:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $16
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $15, $09, $4A, $59  ; CH4: instr 21, vol $09, slide $4A, noise 89
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1100         ; CH3+CH4
	db $0F, $1C, $02, $C9, $AC, $12; CH3: instr 28, duty $02, vol $C9, slide $AC, note 18
	db $0D, $1A, $08, $D9, $2D  ; CH4: instr 26, vol $08, slide $D9, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 15, %1000        ; CH4
	db $0C, $09, $FF, $45       ; CH4: vol $09, slide $FF, noise 69
	SFX_END

;; SFX $53
Sfx53:
	SFX_PRIORITY 15, 0
.l751D:
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $07, $15, $C0, $06, $22  ; CH1: instr 21, duty $C0, vol $06, note 34
	db $05, $15, $08, $2D       ; CH4: instr 21, vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $06, $C0, $06, $3C       ; CH1: duty $C0, vol $06, note 60
	db $04, $08, $41            ; CH4: vol $08, noise 65
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %011
	SEG_LOOP 4, .l751D
	SEG_HOLD $0B
	SEG_FRAMES 1, %0000
	SFX_END

;; SFX $54
Sfx54:
	SFX_PRIORITY 15, 0
	SEGMENT $FF, %010
	SEG_HOLD $5B
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $19, $0B, $FF, $1C  ; CH4: instr 25, vol $0B, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $0A
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $15, $C0, $07, $20  ; CH1: instr 21, duty $C0, vol $07, note 32
	db $07, $15, $C0, $09, $40  ; CH2: instr 21, duty $C0, vol $09, note 64
	db $0D, $19, $0F, $9C, $60  ; CH4: instr 25, vol $0F, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $06
	SEG_FRAMES 6, %1011         ; CH1+CH2+CH4
	db $06, $C0, $05, $2C       ; CH1: duty $C0, vol $05, note 44
	db $06, $C0, $07, $4B       ; CH2: duty $C0, vol $07, note 75
	db $0D, $1B, $0F, $03, $2B  ; CH4: instr 27, vol $0F, slide $03, noise 43
	SFX_END

;; SFX $55
Sfx55:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $07, $15, $C0, $0A, $38  ; CH1: instr 21, duty $C0, vol $0A, note 56
	db $17, $15, $C0, $0A, $FF, $38; CH2: instr 21, duty $C0, vol $0A, detune $FF, note 56
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0000
	SEGMENT $FF, %010
	SEG_HOLD $08
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $07, $1D, $C0, $0A, $3D  ; CH1: instr 29, duty $C0, vol $0A, note 61
	db $17, $1D, $C0, $0A, $FF, $3D; CH2: instr 29, duty $C0, vol $0A, detune $FF, note 61
	SEGMENT $FF, %010
	SEG_HOLD $08
	SEG_FRAMES 1, %0011         ; CH1+CH2
	db $07, $1D, $C0, $0A, $42  ; CH1: instr 29, duty $C0, vol $0A, note 66
	db $17, $1D, $C0, $0A, $FF, $42; CH2: instr 29, duty $C0, vol $0A, detune $FF, note 66
	SEGMENT $FF, %010
	SEG_HOLD $6B
	SEG_FRAMES 41, %0011        ; CH1+CH2
	db $07, $15, $C0, $0A, $42  ; CH1: instr 21, duty $C0, vol $0A, note 66
	db $17, $15, $C0, $0A, $FF, $42; CH2: instr 21, duty $C0, vol $0A, detune $FF, note 66
	SFX_END

;; SFX $56
Sfx56:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0001         ; CH1
	db $07, $1F, $C0, $04, $05  ; CH1: instr 31, duty $C0, vol $04, note 5
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0001         ; CH1
	db $07, $17, $C0, $08, $05  ; CH1: instr 23, duty $C0, vol $08, note 5
	SEGMENT $FF, %010
	SEG_HOLD $0B
	SEG_FRAMES 11, %0001        ; CH1
	db $07, $17, $C0, $0F, $05  ; CH1: instr 23, duty $C0, vol $0F, note 5
	SFX_END

;; SFX $57
Sfx57:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $0D, $25  ; CH1: instr 26, duty $80, vol $0D, note 37
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $0B, $31  ; CH1: instr 26, duty $80, vol $0B, note 49
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0001         ; CH1
	db $07, $1A, $80, $0D, $25  ; CH1: instr 26, duty $80, vol $0D, note 37
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 5, %0001         ; CH1
	db $07, $1A, $80, $0B, $31  ; CH1: instr 26, duty $80, vol $0B, note 49
	SFX_END

;; SFX $58
Sfx58:
	SFX_PRIORITY 22, 0
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $0D, $19, $09, $A0, $14  ; CH1: instr 25, vol $09, slide $A0, note 20
	db $0D, $1F, $07, $E8, $1E  ; CH2: instr 31, vol $07, slide $E8, note 30
	db $0D, $15, $03, $9D, $20  ; CH4: instr 21, vol $03, slide $9D, noise 32
	SEGMENT $FF, %010
	SEG_HOLD $15
	SEG_FRAMES 23, %1010        ; CH2+CH4
	db $0C, $0A, $E8, $1E       ; CH2: vol $0A, slide $E8, note 30
	db $0C, $0A, $9D, $20       ; CH4: vol $0A, slide $9D, noise 32
	SFX_END

;; SFX $59
Sfx59:
	SFX_PRIORITY 22, 0
	SEGMENT $FF, %010
	SEG_HOLD $06
	SEG_FRAMES 6, %1010         ; CH2+CH4
	db $0D, $1F, $06, $CE, $2F  ; CH2: instr 31, vol $06, slide $CE, note 47
	db $0D, $15, $06, $9D, $1F  ; CH4: instr 21, vol $06, slide $9D, noise 31
	SEGMENT $FF, %010
	SEG_HOLD $15
	SEG_FRAMES 21, %1010        ; CH2+CH4
	db $0C, $09, $E8, $1E       ; CH2: vol $09, slide $E8, note 30
	db $0C, $0B, $9D, $1F       ; CH4: vol $0B, slide $9D, noise 31
	SFX_END

;; SFX $5A
Sfx5A:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 4, %0001         ; CH1
	db $0F, $16, $C0, $0F, $F5, $22; CH1: instr 22, duty $C0, vol $0F, slide $F5, note 34
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 7, %0001         ; CH1
	db $0E, $C0, $09, $F5, $22  ; CH1: duty $C0, vol $09, slide $F5, note 34
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 9, %0001         ; CH1
	db $0E, $C0, $05, $F5, $22  ; CH1: duty $C0, vol $05, slide $F5, note 34
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0001         ; CH1
	db $0E, $C0, $02, $F5, $22  ; CH1: duty $C0, vol $02, slide $F5, note 34
	SFX_END

;; SFX $5B
Sfx5B:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 9, %0011         ; CH1+CH2
	db $0F, $16, $80, $0F, $FF, $0D; CH1: instr 22, duty $80, vol $0F, slide $FF, note 13
	db $1F, $16, $80, $0F, $FF, $04, $0D; CH2: instr 22, duty $80, vol $0F, slide $FF, detune $04, note 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %0011         ; CH1+CH2
	db $0E, $80, $0C, $FF, $0D  ; CH1: duty $80, vol $0C, slide $FF, note 13
	db $1E, $80, $0C, $FF, $04, $0D; CH2: duty $80, vol $0C, slide $FF, detune $04, note 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 9, %0011         ; CH1+CH2
	db $0E, $80, $07, $FF, $0D  ; CH1: duty $80, vol $07, slide $FF, note 13
	db $1E, $80, $07, $FF, $04, $0D; CH2: duty $80, vol $07, slide $FF, detune $04, note 13
	SFX_END

;; SFX $5C
Sfx5C:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %0011         ; CH1+CH2
	db $07, $17, $40, $06, $08  ; CH1: instr 23, duty $40, vol $06, note 8
	db $17, $17, $40, $06, $FB, $08; CH2: instr 23, duty $40, vol $06, detune $FB, note 8
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %0011         ; CH1+CH2
	db $06, $40, $08, $08       ; CH1: duty $40, vol $08, note 8
	db $16, $40, $08, $FB, $08  ; CH2: duty $40, vol $08, detune $FB, note 8
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %0011         ; CH1+CH2
	db $06, $40, $0B, $08       ; CH1: duty $40, vol $0B, note 8
	db $16, $40, $0B, $FB, $08  ; CH2: duty $40, vol $0B, detune $FB, note 8
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %0011         ; CH1+CH2
	db $06, $40, $0D, $08       ; CH1: duty $40, vol $0D, note 8
	db $16, $40, $0D, $FB, $08  ; CH2: duty $40, vol $0D, detune $FB, note 8
	SEGMENT $FF, %010
	SEG_HOLD $3D
	SEG_FRAMES 105, %0011       ; CH1+CH2
	db $0E, $40, $0F, $50, $08  ; CH1: duty $40, vol $0F, slide $50, note 8
	db $1E, $40, $0F, $50, $FB, $08; CH2: duty $40, vol $0F, slide $50, detune $FB, note 8
	SFX_END

;; SFX $5D
Sfx5D:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $19, $08, $FF, $1C  ; CH4: instr 25, vol $08, slide $FF, noise 28
	SEGMENT $FF, %010
	SEG_HOLD $0A
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $15, $C0, $02, $1F  ; CH1: instr 21, duty $C0, vol $02, note 31
	db $07, $15, $C0, $03, $3F  ; CH2: instr 21, duty $C0, vol $03, note 63
	db $0D, $19, $0C, $9C, $60  ; CH4: instr 25, vol $0C, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 4, %1011         ; CH1+CH2+CH4
	db $06, $C0, $01, $2B       ; CH1: duty $C0, vol $01, note 43
	db $06, $C0, $02, $4A       ; CH2: duty $C0, vol $02, note 74
	db $0D, $1B, $0C, $03, $2B  ; CH4: instr 27, vol $0C, slide $03, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1011         ; CH1+CH2+CH4
	db $00, $2C                 ; CH1: note 44
	db $00, $4B                 ; CH2: note 75
	db $05, $1B, $0C, $2B       ; CH4: instr 27, vol $0C, noise 43
	SFX_END

;; SFX $5E
Sfx5E:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 16, %1000        ; CH4
	db $0D, $15, $07, $46, $38  ; CH4: instr 21, vol $07, slide $46, noise 56
	SFX_END

;; SFX $5F
Sfx5F:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $3C
	SEG_FRAMES 60, %1000        ; CH4
	db $0D, $20, $0F, $97, $30  ; CH4: instr 32, vol $0F, slide $97, noise 48
	SFX_END

;; SFX $60
Sfx60:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $24, $07, $8A, $2B  ; CH4: instr 36, vol $07, slide $8A, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $19, $0B, $BE, $2D  ; CH4: instr 25, vol $0B, slide $BE, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0C, $0C, $0C, $2D       ; CH4: vol $0C, slide $0C, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 7, %1000         ; CH4
	db $0C, $0B, $14, $2B       ; CH4: vol $0B, slide $14, noise 43
	SFX_END

;; SFX $61
Sfx61:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $17, $0F, $D0, $6E  ; CH4: instr 23, vol $0F, slide $D0, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $73
	SEG_FRAMES 88, %1000        ; CH4
	db $0D, $19, $0F, $84, $1B  ; CH4: instr 25, vol $0F, slide $84, noise 27
	SFX_END

;; SFX $62
Sfx62:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $36
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $1E, $07, $FB, $2F  ; CH4: instr 30, vol $07, slide $FB, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %0000
	SEGMENT $FF, %010
	SEG_HOLD $05
	SEG_FRAMES 12, %1000        ; CH4
	db $0D, $16, $0B, $9E, $3F  ; CH4: instr 22, vol $0B, slide $9E, noise 63
	SFX_END

;; SFX $63
Sfx63:
	SFX_PRIORITY 11, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $15, $07, $A2, $22  ; CH4: instr 21, vol $07, slide $A2, noise 34
	SEGMENT $FF, %010
	SEG_HOLD $35
	SEG_FRAMES 51, %1011        ; CH1+CH2+CH4
	db $0F, $1F, $C0, $0F, $BB, $07; CH1: instr 31, duty $C0, vol $0F, slide $BB, note 7
	db $1F, $1F, $80, $0F, $BB, $F5, $11; CH2: instr 31, duty $80, vol $0F, slide $BB, detune $F5, note 17
	db $0C, $0C, $A2, $22       ; CH4: vol $0C, slide $A2, noise 34
	SFX_END

;; SFX $64
Sfx64:
	SFX_PRIORITY 22, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 18, %0011        ; CH1+CH2
	db $0F, $3A, $40, $0D, $01, $19; CH1: instr 58, duty $40, vol $0D, slide $01, note 25
	db $07, $3A, $40, $0D, $19  ; CH2: instr 58, duty $40, vol $0D, note 25
	SEGMENT $FF, %010
	SEG_HOLD $7D
	SEG_FRAMES 125, %0111       ; CH1+CH2+CH3
	db $0E, $40, $0D, $81, $19  ; CH1: duty $40, vol $0D, slide $81, note 25
	db $06, $40, $0D, $19       ; CH2: duty $40, vol $0D, note 25
	db $07, $1E, $03, $FF, $2B  ; CH3: instr 30, duty $03, vol $FF, note 43
	SFX_END

;; SFX $65
Sfx65:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $36
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $1E, $07, $FB, $2F  ; CH4: instr 30, vol $07, slide $FB, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $16, $0D, $9E, $40  ; CH4: instr 22, vol $0D, slide $9E, noise 64
	SFX_END

;; SFX $66
Sfx66:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $15, $0D, $FF, $2D  ; CH4: instr 21, vol $0D, slide $FF, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $19, $08, $D0, $3F  ; CH4: instr 25, vol $08, slide $D0, noise 63
	SFX_END

;; SFX $67
Sfx67:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $15, $08, $FF, $2D  ; CH4: instr 21, vol $08, slide $FF, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $15, $09, $FF, $3E  ; CH4: instr 21, vol $09, slide $FF, noise 62
	SFX_END

;; SFX $68
Sfx68:
	SFX_PRIORITY 9, 0
.l7838:
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 16, %0110        ; CH2+CH3
	db $1F, $20, $C0, $0F, $A8, $FB, $01; CH2: instr 32, duty $C0, vol $0F, slide $A8, detune $FB, note 1
	db $0F, $1D, $03, $FA, $81, $0A; CH3: instr 29, duty $03, vol $FA, slide $81, note 10
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %0000
	SEGMENT $FF, %010
	SEG_HOLD $07
	SEG_FRAMES 16, %0110        ; CH2+CH3
	db $0E, $C0, $0F, $A3, $09  ; CH2: duty $C0, vol $0F, slide $A3, note 9
	db $0E, $03, $FA, $81, $0D  ; CH3: duty $03, vol $FA, slide $81, note 13
	SEGMENT $FF, %011
	SEG_LOOP 12, .l7838
	SEG_HOLD $0C
	SEG_FRAMES 0, %0000
	SFX_END

;; SFX $69
Sfx69:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 8, %1001         ; CH1+CH4
	db $0F, $1B, $C0, $0C, $C6, $23; CH1: instr 27, duty $C0, vol $0C, slide $C6, note 35
	db $0D, $1E, $08, $CF, $21  ; CH4: instr 30, vol $08, slide $CF, noise 33
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 10, %1001        ; CH1+CH4
	db $0E, $C0, $07, $C6, $21  ; CH1: duty $C0, vol $07, slide $C6, note 33
	db $0C, $04, $CF, $21       ; CH4: vol $04, slide $CF, noise 33
	SFX_END

;; SFX $6A
Sfx6A:
	SFX_PRIORITY 12, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $17, $0F, $D0, $6E  ; CH4: instr 23, vol $0F, slide $D0, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $64
	SEG_FRAMES 100, %1000       ; CH4
	db $0D, $19, $0F, $84, $1B  ; CH4: instr 25, vol $0F, slide $84, noise 27
	SFX_END

;; SFX $6B
Sfx6B:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $0D
	SEG_FRAMES 4, %1000         ; CH4
	db $0D, $17, $0E, $FF, $6E  ; CH4: instr 23, vol $0E, slide $FF, noise 110
	SEGMENT $FF, %010
	SEG_HOLD $29
	SEG_FRAMES 41, %1000        ; CH4
	db $0D, $17, $0E, $8F, $70  ; CH4: instr 23, vol $0E, slide $8F, noise 112
	SFX_END

;; SFX $6C
Sfx6C:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $15, $0B, $2D       ; CH4: instr 21, vol $0B, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $08, $2D       ; CH4: instr 31, vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 6, %1001         ; CH1+CH4
	db $0F, $15, $C0, $08, $8E, $3C; CH1: instr 21, duty $C0, vol $08, slide $8E, note 60
	db $04, $08, $41            ; CH4: vol $08, noise 65
	SFX_END

;; SFX $6D
Sfx6D:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 7, %1001         ; CH1+CH4
	db $05, $17, $06, $3C       ; CH1: instr 23, vol $06, note 60
	db $05, $1F, $08, $2F       ; CH4: instr 31, vol $08, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $04, $06, $3C            ; CH1: vol $06, note 60
	db $04, $08, $2D            ; CH4: vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $04, $06, $3C            ; CH1: vol $06, note 60
	db $04, $08, $2F            ; CH4: vol $08, noise 47
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $04, $06, $3C            ; CH1: vol $06, note 60
	db $04, $08, $2D            ; CH4: vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $04, $06, $3C            ; CH1: vol $06, note 60
	db $04, $08, $2F            ; CH4: vol $08, noise 47
	SFX_END

;; SFX $6E
Sfx6E:
	SFX_PRIORITY 9, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1000         ; CH4
	db $05, $15, $08, $2D       ; CH4: instr 21, vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $15, $08, $2D       ; CH4: instr 21, vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $15, $08, $2D       ; CH4: instr 21, vol $08, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $15, $08, $2D       ; CH4: instr 21, vol $08, noise 45
	SFX_END

;; SFX $6F
Sfx6F:
	SFX_PRIORITY 21, 0
	SEGMENT $FF, %010
	SEG_HOLD $A6
	SEG_FRAMES 166, %1000       ; CH4
	db $05, $24, $0D, $19       ; CH4: instr 36, vol $0D, noise 25
	SFX_END

;; SFX $70
Sfx70:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP 3
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $3A, $80, $08, $FF, $2A; CH1: instr 58, duty $80, vol $08, detune $FF, note 42
	db $07, $3A, $80, $08, $2A  ; CH2: instr 58, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $3A, $80, $08, $01, $2A; CH1: instr 58, duty $80, vol $08, detune $01, note 42
	db $07, $3A, $80, $08, $2A  ; CH2: instr 58, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $3A, $80, $08, $FF, $2A; CH1: instr 58, duty $80, vol $08, detune $FF, note 42
	db $07, $3A, $80, $08, $2A  ; CH2: instr 58, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $3A, $80, $08, $FF, $2A; CH1: instr 58, duty $80, vol $08, detune $FF, note 42
	db $17, $3A, $80, $08, $FE, $2A; CH2: instr 58, duty $80, vol $08, detune $FE, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $3A, $80, $08, $01, $2A; CH1: instr 58, duty $80, vol $08, detune $01, note 42
	db $07, $3A, $80, $08, $2A  ; CH2: instr 58, duty $80, vol $08, note 42
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $17, $3A, $80, $08, $01, $2A; CH1: instr 58, duty $80, vol $08, detune $01, note 42
	db $17, $3A, $80, $08, $FE, $2A; CH2: instr 58, duty $80, vol $08, detune $FE, note 42
	SFX_END

;; SFX $71
Sfx71:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $15, $09, $06, $5D  ; CH4: instr 21, vol $09, slide $06, noise 93
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 6, %1000         ; CH4
	db $0D, $15, $09, $06, $5D  ; CH4: instr 21, vol $09, slide $06, noise 93
	SFX_END

;; SFX $72
Sfx72:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $15, $C0, $04, $20  ; CH1: instr 21, duty $C0, vol $04, note 32
	db $07, $15, $C0, $06, $40  ; CH2: instr 21, duty $C0, vol $06, note 64
	db $0D, $19, $09, $9C, $60  ; CH4: instr 25, vol $09, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1011         ; CH1+CH2+CH4
	db $07, $15, $C0, $04, $20  ; CH1: instr 21, duty $C0, vol $04, note 32
	db $07, $15, $C0, $06, $40  ; CH2: instr 21, duty $C0, vol $06, note 64
	db $0D, $19, $09, $9C, $60  ; CH4: instr 25, vol $09, slide $9C, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1011         ; CH1+CH2+CH4
	db $06, $C0, $02, $2C       ; CH1: duty $C0, vol $02, note 44
	db $06, $C0, $04, $4B       ; CH2: duty $C0, vol $04, note 75
	db $0D, $1B, $01, $03, $2B  ; CH4: instr 27, vol $01, slide $03, noise 43
	SFX_END

;; SFX $73
Sfx73:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1001         ; CH1+CH4
	db $0F, $21, $C0, $07, $73, $53; CH1: instr 33, duty $C0, vol $07, slide $73, note 83
	db $0D, $15, $07, $8C, $5F  ; CH4: instr 21, vol $07, slide $8C, noise 95
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %1001         ; CH1+CH4
	db $0E, $C0, $06, $09, $53  ; CH1: duty $C0, vol $06, slide $09, note 83
	db $05, $15, $06, $60       ; CH4: instr 21, vol $06, noise 96
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $15, $01, $62       ; CH4: instr 21, vol $01, noise 98
	SFX_END

;; SFX $74
Sfx74:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1F, $0A, $8A, $2D  ; CH4: instr 31, vol $0A, slide $8A, noise 45
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1F, $07, $8A, $2C  ; CH4: instr 31, vol $07, slide $8A, noise 44
	SEGMENT $FF, %010
	SEG_HOLD $06
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1F, $05, $8A, $2E  ; CH4: instr 31, vol $05, slide $8A, noise 46
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 3, %1000         ; CH4
	db $0D, $1F, $04, $8A, $2D  ; CH4: instr 31, vol $04, slide $8A, noise 45
	SFX_END

;; SFX $75
Sfx75:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $0A, $0D       ; CH4: instr 31, vol $0A, noise 13
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $0A, $0E       ; CH4: instr 31, vol $0A, noise 14
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $0A, $0D       ; CH4: instr 31, vol $0A, noise 13
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $0A, $0E       ; CH4: instr 31, vol $0A, noise 14
	SEGMENT $FF, %010
	SEG_HOLD $02
	SEG_FRAMES 2, %0000
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $0A, $0D       ; CH4: instr 31, vol $0A, noise 13
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $05, $1F, $0A, $0E       ; CH4: instr 31, vol $0A, noise 14
	SFX_END

;; SFX $76
Sfx76:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 4, %0011         ; CH1+CH2
	db $1D, $3A, $09, $83, $04, $23; CH1: instr 58, vol $09, slide $83, detune $04, note 35
	db $0D, $3A, $09, $83, $17  ; CH2: instr 58, vol $09, slide $83, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 15, %0011        ; CH1+CH2
	db $0C, $0D, $01, $23       ; CH1: vol $0D, slide $01, note 35
	db $0C, $0D, $00, $17       ; CH2: vol $0D, slide $00, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 13, %0011        ; CH1+CH2
	db $04, $0A, $23            ; CH1: vol $0A, note 35
	db $0C, $0A, $83, $17       ; CH2: vol $0A, slide $83, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 8, %0011         ; CH1+CH2
	db $04, $07, $23            ; CH1: vol $07, note 35
	db $04, $07, $17            ; CH2: vol $07, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %0011         ; CH1+CH2
	db $04, $05, $23            ; CH1: vol $05, note 35
	db $04, $05, $17            ; CH2: vol $05, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 3, %0011         ; CH1+CH2
	db $04, $01, $23            ; CH1: vol $01, note 35
	db $04, $01, $17            ; CH2: vol $01, note 23
	SFX_END

;; SFX $77
Sfx77:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0101         ; CH1+CH3
	db $0F, $22, $C0, $0B, $0B, $25; CH1: instr 34, duty $C0, vol $0B, slide $0B, note 37
	db $0F, $25, $03, $FA, $09, $2F; CH3: instr 37, duty $03, vol $FA, slide $09, note 47
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 25, %0101        ; CH1+CH3
	db $0F, $22, $C0, $0B, $88, $25; CH1: instr 34, duty $C0, vol $0B, slide $88, note 37
	db $0F, $25, $03, $F5, $8B, $2F; CH3: instr 37, duty $03, vol $F5, slide $8B, note 47
	SFX_END

;; SFX $78
Sfx78:
	SFX_PRIORITY 13, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -2
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $1D, $3A, $09, $83, $04, $23; CH1: instr 58, vol $09, slide $83, detune $04, note 35
	db $0D, $3A, $09, $83, $17  ; CH2: instr 58, vol $09, slide $83, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $1D, $3A, $0A, $83, $04, $23; CH1: instr 58, vol $0A, slide $83, detune $04, note 35
	db $0D, $3A, $0A, $83, $17  ; CH2: instr 58, vol $0A, slide $83, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $0C, $0E, $01, $23       ; CH1: vol $0E, slide $01, note 35
	db $0C, $0E, $00, $17       ; CH2: vol $0E, slide $00, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $04, $0B, $23            ; CH1: vol $0B, note 35
	db $0C, $0B, $83, $17       ; CH2: vol $0B, slide $83, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $04, $08, $23            ; CH1: vol $08, note 35
	db $04, $08, $17            ; CH2: vol $08, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $04, $05, $23            ; CH1: vol $05, note 35
	db $04, $05, $17            ; CH2: vol $05, note 23
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 2, %0011         ; CH1+CH2
	db $04, $01, $23            ; CH1: vol $01, note 35
	db $04, $01, $17            ; CH2: vol $01, note 23
	SFX_END

;; SFX $79
Sfx79:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $04
	SEG_FRAMES 2, %1000         ; CH4
	db $0D, $15, $0A, $BE, $50  ; CH4: instr 21, vol $0A, slide $BE, noise 80
	SEGMENT $FF, %010
	SEG_HOLD $43
	SEG_FRAMES 10, %1000        ; CH4
	db $0D, $16, $0A, $00, $6D  ; CH4: instr 22, vol $0A, slide $00, noise 109
	SFX_END

;; SFX $7A
Sfx7A:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 12, %1001        ; CH1+CH4
	db $07, $3A, $C0, $0F, $0C  ; CH1: instr 58, duty $C0, vol $0F, note 12
	db $05, $1F, $04, $0A       ; CH4: instr 31, vol $04, noise 10
	SFX_END

;; SFX $7B
Sfx7B:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 5, %1000         ; CH4
	db $0D, $2F, $0A, $C1, $2B  ; CH4: instr 47, vol $0A, slide $C1, noise 43
	SEGMENT $FF, %010
	SEG_HOLD $01
	SEG_FRAMES 1, %1000         ; CH4
	db $0D, $17, $0A, $BC, $10  ; CH4: instr 23, vol $0A, slide $BC, noise 16
	SFX_END

;; SFX $7C
Sfx7C:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %110
	SEG_HOLD $0E
	SEG_TRANSP -1
	SEG_FRAMES 14, %0001        ; CH1
	db $0D, $15, $0F, $FF, $02  ; CH1: instr 21, vol $0F, slide $FF, note 2
	SEGMENT $FF, %010
	SEG_HOLD $13
	SEG_FRAMES 19, %0001        ; CH1
	db $0C, $0F, $7F, $02       ; CH1: vol $0F, slide $7F, note 2
	SFX_END

;; SFX $7D
Sfx7D:
	SFX_PRIORITY 10, 0
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -1
	SEG_FRAMES 4, %0001         ; CH1
	db $0F, $15, $80, $0F, $FF, $15; CH1: instr 21, duty $80, vol $0F, slide $FF, note 21
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -1
	SEG_FRAMES 2, %0001         ; CH1
	db $0F, $15, $80, $0E, $FF, $0C; CH1: instr 21, duty $80, vol $0E, slide $FF, note 12
	SEGMENT $FF, %000
	SEG_FRAMES 0, %0000
	SEGMENT $FF, %110
	SEG_HOLD $01
	SEG_TRANSP -1
	SEG_FRAMES 2, %0001         ; CH1
	db $0F, $15, $80, $0C, $FF, $04; CH1: instr 21, duty $80, vol $0C, slide $FF, note 4
	SFX_END
