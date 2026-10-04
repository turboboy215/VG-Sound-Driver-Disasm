; ghx_macros.inc - note names and data macros shared by the GHX disassemblies
; Row/playlist note numbers are frequency-table indices: 1 = C-2 (65.4 Hz),
; 13 = C-3 ... (before transpose and the playlist offset are applied).
IF !DEF(GHX_MACROS_INC)
DEF GHX_MACROS_INC EQU 1
DEF ___ EQU 0
DEF C_2 EQU 1
DEF Cs2 EQU 2
DEF D_2 EQU 3
DEF Ds2 EQU 4
DEF E_2 EQU 5
DEF F_2 EQU 6
DEF Fs2 EQU 7
DEF G_2 EQU 8
DEF Gs2 EQU 9
DEF A_2 EQU 10
DEF As2 EQU 11
DEF B_2 EQU 12
DEF C_3 EQU 13
DEF Cs3 EQU 14
DEF D_3 EQU 15
DEF Ds3 EQU 16
DEF E_3 EQU 17
DEF F_3 EQU 18
DEF Fs3 EQU 19
DEF G_3 EQU 20
DEF Gs3 EQU 21
DEF A_3 EQU 22
DEF As3 EQU 23
DEF B_3 EQU 24
DEF C_4 EQU 25
DEF Cs4 EQU 26
DEF D_4 EQU 27
DEF Ds4 EQU 28
DEF E_4 EQU 29
DEF F_4 EQU 30
DEF Fs4 EQU 31
DEF G_4 EQU 32
DEF Gs4 EQU 33
DEF A_4 EQU 34
DEF As4 EQU 35
DEF B_4 EQU 36
DEF C_5 EQU 37
DEF Cs5 EQU 38
DEF D_5 EQU 39
DEF Ds5 EQU 40
DEF E_5 EQU 41
DEF F_5 EQU 42
DEF Fs5 EQU 43
DEF G_5 EQU 44
DEF Gs5 EQU 45
DEF A_5 EQU 46
DEF As5 EQU 47
DEF B_5 EQU 48
DEF C_6 EQU 49
DEF Cs6 EQU 50
DEF D_6 EQU 51
DEF Ds6 EQU 52
DEF E_6 EQU 53
DEF F_6 EQU 54
DEF Fs6 EQU 55
DEF G_6 EQU 56
DEF Gs6 EQU 57
DEF A_6 EQU 58
DEF As6 EQU 59
DEF B_6 EQU 60
DEF C_7 EQU 61
DEF Cs7 EQU 62
DEF D_7 EQU 63

; ---- pattern (track) rows ---------------------------------------------
; A row is 1-3 bytes:  [note | $40 if an instrument byte follows | $80 if an
;                       effect byte follows], [instrument byte], [effect byte]
; instrument byte = instrument number+1 (0 = keep instrument) | volume shift<<6
; effect byte     = parameter<<4 | command  (command in the LOW nibble)
MACRO R      ; R note
    db \1
ENDM
MACRO RI     ; RI note, instrument(1-based, 0=none), volume shift(0-3)
    db (\1) | $40, (\2) | ((\3) << 6)
ENDM
MACRO RF     ; RF note, fx command, fx parameter
    db (\1) | $80, ((\3) << 4) | (\2)
ENDM
MACRO RIF    ; RIF note, instrument, volume shift, fx command, fx parameter
    db (\1) | $C0, (\2) | ((\3) << 6), ((\5) << 4) | (\4)
ENDM
MACRO POS    ; POS track1, tr1, track2, tr2, track3, tr3, track4  (pointer positions)
    dw \1
    db \2
    dw \3
    db \4
    dw \5
    db \6
    dw \7
ENDM
ENDC
