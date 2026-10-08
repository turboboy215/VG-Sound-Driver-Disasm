; Star Wars Episode I: Racer (GBC) sound driver: data constants and macros

IF !DEF(SWR_MACROS_INC)
DEF SWR_MACROS_INC EQU 1

; ---- one-byte events (music and SFX streams) ---------------------------
; $0n note: semitone n above the channel octave (wOctave)
DEF _C     EQU $00
DEF _Cs    EQU $01
DEF _D     EQU $02
DEF _Ds    EQU $03
DEF _E     EQU $04
DEF _F     EQU $05
DEF _Fs    EQU $06
DEF _G     EQU $07
DEF _Gs    EQU $08
DEF _A     EQU $09
DEF _As    EQU $0A
DEF _B     EQU $0B
DEF _HiC   EQU $0C
DEF _HiCs  EQU $0D
DEF _HiD   EQU $0E
DEF _HiDs  EQU $0F
; $1n length = length table[n] (then keep reading)
DEF LEN0   EQU $10
DEF LEN1   EQU $11
DEF LEN2   EQU $12
DEF LEN3   EQU $13
DEF LEN4   EQU $14
DEF LEN5   EQU $15
DEF LEN6   EQU $16
DEF LEN7   EQU $17
DEF LEN8   EQU $18
DEF LEN9   EQU $19
DEF LEN10  EQU $1A
DEF LEN11  EQU $1B
DEF LEN12  EQU $1C
DEF LEN13  EQU $1D
DEF LEN14  EQU $1E
DEF LEN15  EQU $1F
; $2n rest, length = length table[n]; $30 rest with the current length
DEF REST0  EQU $20
DEF REST1  EQU $21
DEF REST2  EQU $22
DEF REST3  EQU $23
DEF REST4  EQU $24
DEF REST5  EQU $25
DEF REST6  EQU $26
DEF REST7  EQU $27
DEF REST8  EQU $28
DEF REST9  EQU $29
DEF REST10 EQU $2A
DEF REST11 EQU $2B
DEF REST12 EQU $2C
DEF REST13 EQU $2D
DEF REST14 EQU $2E
DEF REST15 EQU $2F
DEF RESTC  EQU $30
; $40 octave up, $41-$4F octave down
DEF OCT_UP EQU $40
DEF OCT_DN EQU $41
; $5n octave n (semitone base 12 * n)
DEF OCT0   EQU $50
DEF OCT1   EQU $51
DEF OCT2   EQU $52
DEF OCT3   EQU $53
DEF OCT4   EQU $54
DEF OCT5   EQU $55
DEF OCT6   EQU $56
DEF OCT7   EQU $57
; $60 volume +1, $61-$6F volume -1; $7n volume n
DEF VOL_UP EQU $60
DEF VOL_DN EQU $61
DEF VOL0   EQU $70
DEF VOL1   EQU $71
DEF VOL2   EQU $72
DEF VOL3   EQU $73
DEF VOL4   EQU $74
DEF VOL5   EQU $75
DEF VOL6   EQU $76
DEF VOL7   EQU $77
DEF VOL8   EQU $78
DEF VOL9   EQU $79
DEF VOL10  EQU $7A
DEF VOL11  EQU $7B
DEF VOL12  EQU $7C
DEF VOL13  EQU $7D
DEF VOL14  EQU $7E
DEF VOL15  EQU $7F
; $8n duty, written at once: $80-$83 = ch1 duty 0-3, $84-$87 = ch2 duty 0-3 (any stream)
DEF DUTY1_0 EQU $80
DEF DUTY1_1 EQU $81
DEF DUTY1_2 EQU $82
DEF DUTY1_3 EQU $83
DEF DUTY2_0 EQU $84
DEF DUTY2_1 EQU $85
DEF DUTY2_2 EQU $86
DEF DUTY2_3 EQU $87
; $9n pan the stream's channel, written to NR51 at once
DEF PAN_L  EQU $90
DEF PAN_R  EQU $91
DEF PAN_LR EQU $92
; $An (SFX) rumble pattern n
DEF RUMBLE_OFF EQU $A0
DEF RUMBLE1 EQU $A1
DEF RUMBLE2 EQU $A2
DEF RUMBLE3 EQU $A3
DEF RUMBLE4 EQU $A4
; $Bn (music, ch4) drum n
DEF DRUM0  EQU $B0
DEF DRUM1  EQU $B1
DEF DRUM2  EQU $B2
DEF DRUM3  EQU $B3
DEF DRUM4  EQU $B4
; $Cn (music) gate: the last n frames of each note are silent
DEF GATE0  EQU $C0
DEF GATE1  EQU $C1
DEF GATE2  EQU $C2
DEF GATE3  EQU $C3
DEF GATE4  EQU $C4
DEF GATE5  EQU $C5
DEF GATE6  EQU $C6
DEF GATE7  EQU $C7
DEF GATE8  EQU $C8
DEF GATE9  EQU $C9
DEF GATE10 EQU $CA
DEF GATE11 EQU $CB
DEF GATE12 EQU $CC
DEF GATE13 EQU $CD
DEF GATE14 EQU $CE
DEF GATE15 EQU $CF
; $Dn (music, ch1/ch2) pitch envelope n; $D0 off
DEF PENV_OFF EQU $D0
DEF PENV1  EQU $D1
DEF PENV2  EQU $D2
DEF PENV3  EQU $D3
DEF PENV4  EQU $D4
DEF PENV5  EQU $D5
DEF PENV6  EQU $D6
DEF PENV7  EQU $D7
DEF PENV8  EQU $D8
DEF PENV9  EQU $D9
DEF PENV10 EQU $DA
DEF PENV11 EQU $DB
DEF PENV12 EQU $DC
DEF PENV13 EQU $DD
DEF PENV14 EQU $DE
DEF PENV15 EQU $DF

; ---- $Fx commands ------------------------------------------------------
MACRO ENV ; NRx2; a value below $10 keeps the current volume
	db $F0, \1
ENDM
MACRO LOOP ; repeat to the matching ENDLOOP (4 levels per channel)
	db $F2
ENDM
MACRO ENDLOOP ; total number of passes
	db $F3, \1
ENDM
MACRO JUMP_N ; count, target: jump back count times, then fall through
	db $F4, \1
	dw \2
ENDM
MACRO JUMP
	db $F5
	dw \1
ENDM
MACRO STOP_MUSIC
	db $F6
ENDM
MACRO FADE_STEP ; NR50 - $11
	db $F7
ENDM
MACRO MASTER_RESET ; NR50 = $77
	db $F8
ENDM
MACRO SFX_END
	db $FF
ENDM

; ---- structures ---------------------------------------------------------
MACRO SONG ; length table, ch1, ch2, ch3, ch4
	dw \1, \2, \3, \4, \5
ENDM
MACRO SFX_HEADER ; flags (bit 0: don't restart while playing), ?, chained SFX, ?
	db \1, \2, \3, \4
ENDM
MACRO SFX_TRACK ; priority, ?, stream
	db \1, \2
	dw \3
ENDM
MACRO SFX_NO_TRACK ; ?
	db $00, \1
ENDM
MACRO DRUMDEF ; frames, (unread), NR42=NR43 for the first hit, (unread), NR42, NR43
	db \1, \2, \3, \4, \5, \6
ENDM

ENDC
