"""Shared RGBDS header text: hardware EQUs and sound-data macros."""

HW_EQU = """\
; ---------------------------------------------------------------- hardware
DEF rNR10 EQU $FF10
DEF rNR11 EQU $FF11
DEF rNR12 EQU $FF12
DEF rNR13 EQU $FF13
DEF rNR14 EQU $FF14
DEF rNR21 EQU $FF16
DEF rNR22 EQU $FF17
DEF rNR23 EQU $FF18
DEF rNR24 EQU $FF19
DEF rNR30 EQU $FF1A
DEF rNR31 EQU $FF1B
DEF rNR32 EQU $FF1C
DEF rNR33 EQU $FF1D
DEF rNR34 EQU $FF1E
DEF rNR41 EQU $FF20
DEF rNR42 EQU $FF21
DEF rNR43 EQU $FF22
DEF rNR44 EQU $FF23
DEF rNR50 EQU $FF24
DEF rNR51 EQU $FF25
DEF rNR52 EQU $FF26
DEF _AUD3WAVERAM EQU $FF30
DEF rIE EQU $FFFF
"""

MACROS = """\
; ---------------------------------------------------------------- sound data macros
; Pitch names for NOTE (high nibble of a note byte). C_HI = C of the next octave.
DEF C_ EQU 1
DEF C# EQU 2
DEF D_ EQU 3
DEF D# EQU 4
DEF E_ EQU 5
DEF F_ EQU 6
DEF F# EQU 7
DEF G_ EQU 8
DEF G# EQU 9
DEF A_ EQU 10
DEF A# EQU 11
DEF B_ EQU 12
DEF C_HI EQU 13

; sound header: priority, track mask, then one dw per set mask bit (low bit first)
MACRO SND_HEADER
	db \\1, \\2
ENDM
; $00-$DF: note. hi = pitch 1-13 (0 = rest), lo = length multiplier (x LEN_UNIT; 0 = x256 -> 0 = 256 ticks)
MACRO NOTE
	db (\\1 << 4) | \\2
ENDM
MACRO REST
	db \\1
ENDM
; drum track: hi = index into the drum map (plays that sound id), lo = length multiplier
MACRO DRUM
	db (\\1 << 4) | \\2
ENDM
; noise SFX track: whole byte -> NR43, length = LEN_UNIT, no retrigger
MACRO NOISE
	db \\1
ENDM
; $E0 unit, vol|duty<<4, env|gate<<4 (tone tracks; on CH3: vol = level code, duty = wave #)
MACRO VOICE
	db $E0, \\1, (\\3 << 4) | \\2, (\\5 << 4) | \\4
ENDM
; $E0 unit, vol<<4|env (noise SFX track: written straight to NR42 + retrigger)
MACRO NVOICE
	db $E0, \\1, (\\2 << 4) | \\3
ENDM
; $E0 unit (drum track)
MACRO DRUM_UNIT
	db $E0, \\1
ENDM
; $E1-$E6: octave 1-6 (pitch index += (n-1)*12)
MACRO OCTAVE
	db $E0 | \\1
ENDM
MACRO LEN_UNIT
	db $E7, \\1
ENDM
; $E8: release envelope (NRx2 low nibble) and gate (16ths, $F = release after 1st tick, 0 = never)
MACRO RELEASE
	db $E8, (\\2 << 4) | \\1
ENDM
; $E9: write NRx0 (sweep on CH1)
MACRO SWEEP
	db $E9, \\1
ENDM
; $EA xy: extended command x with 4-bit argument y
MACRO TRANSPOSE_UP
	db $EA, $00 | \\1
ENDM
MACRO TRANSPOSE_DOWN
	db $EA, $10 | \\1
ENDM
MACRO VIBRATO
	db $EA, $20 | \\1
ENDM
MACRO DUTY
	db $EA, $30 | \\1
ENDM
MACRO WAVE
	db $EA, $30 | \\1
ENDM
MACRO AUTOPAN
	db $EA, $40 | \\1
ENDM
MACRO EXT_NOP
	db $EA, $40 | \\1
ENDM
; $EB-$ED: no-ops that skip one argument byte
MACRO CMD_EB
	db $EB, \\1
ENDM
MACRO CMD_EC
	db $EC, \\1
ENDM
MACRO CMD_ED
	db $ED, \\1
ENDM
; $EE: tempo (music skip accumulator increment)
MACRO TEMPO
	db $EE, \\1
ENDM
; $EF: NR51 bits for this track's channel (argument is nibble-swapped)
MACRO PAN
	db $EF, \\1
ENDM
; $F0-$FA: volume attenuation
MACRO ATTEN
	db $F0 | \\1
ENDM
; flow control
MACRO SND_SEGNO
	db $FB
ENDM
MACRO SND_RET
	db $FC
ENDM
MACRO SND_CALL
	db $FD
	dw \\1
ENDM
MACRO SND_REPEAT
	db $FE, \\1
ENDM
MACRO SND_JUMP
	db $FE, $FF
	dw \\1
ENDM
MACRO SND_END
	db $FF
ENDM
; vibrato table: delay (ticks, 0 = 256), negate flag (sticky), 11-bit period offset
MACRO VIB_STEP
	db (\\1 << 4) | (\\2 << 3) | HIGH(\\3), LOW(\\3)
ENDM
MACRO VIB_SEGNO
	db $FB
ENDM
MACRO VIB_REPEAT
	db $FE, \\1
ENDM
MACRO VIB_HOLD
	db $FF
ENDM
"""


def ram_equ(ram):
    out = ['; ---------------------------------------------------------------- RAM']
    for a, n, s in ram:
        if '+' in n: continue
        out.append(f'DEF {n} EQU ${a:04X}' + (f' ; {s} bytes' if s > 2 else ''))
    return out
