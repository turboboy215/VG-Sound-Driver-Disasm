"""Shared helpers for AJG note naming and macro rendering."""
PITCH = ['C_', 'Csh', 'D_', 'Dsh', 'E_', 'F_', 'Fsh', 'G_', 'Gsh', 'A_', 'Ash', 'B_']

NOTE_MACRO = '''
; ---- pitch names: NOTE <pitch>, <octave> ; byte = (octave - 1) * 12 + pitch
; note byte 12 = C2 = first entry of the period table (65.4 Hz on CH1/CH2).
DEF C_ EQU 0
DEF Csh EQU 1
DEF D_ EQU 2
DEF Dsh EQU 3
DEF E_ EQU 4
DEF F_ EQU 5
DEF Fsh EQU 6
DEF G_ EQU 7
DEF Gsh EQU 8
DEF A_ EQU 9
DEF Ash EQU 10
DEF B_ EQU 11

MACRO NOTE
\tdb (\\2 - 1) * 12 + \\1
ENDM
'''


def note_text(n):
    return 'NOTE %s, %d' % (PITCH[n % 12], n // 12 + 1)


def hx(v):
    return '$%02X' % v
