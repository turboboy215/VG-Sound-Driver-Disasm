#!/usr/bin/env python3
"""Generate Smurfs2_SoundDriver.asm: header + hand-written code part + decoded data."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from smparse import *

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

HEADER = r'''; =============================================================================
; The Smurfs Travel the World / "Smurfs 2, The (E) (M4).gb" - sound driver
; Bank 4, $4000-$60E5: driver code, tables, 13 songs, 18 SFX, 179 patterns.
; ROM0 $28FD-$2980: the game's glue routines.
;
; Rebuild (byte-exact against the ROM: 0:$28FD-$2980 and 4:$4000-$60E5):
;   rgbasm -o snd.o Smurfs2_SoundDriver.asm
;   rgblink -p 0xFF -o snd.gb snd.o
; =============================================================================

INCLUDE "hardware.inc"

; ---- RAM ($DF00-$DFAD) ------------------------------------------------------
DEF VOICE_SIZE      EQU $1B     ; bytes per voice block (only +$00-+$0C used)
DEF VOICE_TIMER     EQU $00     ; word, counts up; events are read while < 0
DEF VOICE_STREAM    EQU $02     ; word, pattern stream pointer
DEF VOICE_ORDER     EQU $04     ; word, order list pointer
DEF VOICE_LOOP      EQU $06     ; word, loop list pointer
                                ; +$08 never written or read
DEF VOICE_PITCH     EQU $09     ; current pitch (FreqTable index + $2B)
DEF VOICE_UNUSED_A  EQU $0A     ; set by command 3, never read
DEF VOICE_UNUSED_B  EQU $0B     ; set by command 4, never read
DEF VOICE_INSTR     EQU $0C     ; ToneInstruments index (command 1)
                                ; +$0D-+$1A copied every tick, never used

DEF wWork           EQU $DF00   ; work copy of the voice being processed
DEF wCh1            EQU $DF1B
DEF wCh2            EQU $DF36
DEF wCh3            EQU $DF51
DEF wSfx            EQU $DF6C
DEF wCh4            EQU $DF87
DEF wRegNRx1        EQU $DFA2   ; register image built by ToneNoteHandler
DEF wRegNRx2        EQU $DFA3
DEF wRegNRx3        EQU $DFA4
DEF wRegNRx4        EQU $DFA5   ; 0 = no note this tick
DEF wNoteHandler    EQU $DFA6   ; "jp ToneNoteHandler / NoiseNoteHandler"
DEF wSpeed          EQU $DFA9   ; music speed: timer += speed - 256 per tick
DEF wSfxSpeed       EQU $DFAA
DEF wSpeedSave      EQU $DFAB
DEF wSfxMode        EQU $DFAC   ; 0 none, 1 noise (CH4), 2 tone (CH1)
DEF wListNotEnded   EQU $DFAD   ; $FF, cleared when an order list wraps

DEF SFXMODE_NOISE   EQU 1
DEF SFXMODE_TONE    EQU 2
DEF PITCH_MIN       EQU $2B     ; FreqTable[0] = G2

; ---- stream macros ----------------------------------------------------------
; A wait of n timer units is 0nnnnnnn (n/2, n < 256) or 1nnnnnnn hh (long).
MACRO _W
    IF \1 & 1
        FAIL "odd wait"
    ENDC
    db (\1) >> 1
ENDM
MACRO _WL
    db $80 | (((\1) & $FF) >> 1), (\1) >> 8
ENDM

; DELAY / DELAYL n          - first byte(s) of every pattern
MACRO DELAY
    _W \1
ENDM
MACRO DELAYL
    _WL \1
ENDM
; NOTE / NOTEL step, vol, wait - pitch += step (-15..15), vol 0-7 (0, 3, 5 ... 15)
MACRO NOTE
    db (((\1) + 16) << 3) | (\2)
    _W \3
ENDM
MACRO NOTEL
    db (((\1) + 16) << 3) | (\2)
    _WL \3
ENDM
; TRANSP t                  - pitch += t, the next NOTE follows (escape $07)
MACRO TRANSP
    db 7, LOW(\1)
ENDM
; DRUM / DRUML idx, vol, wait - CH4: NoiseInstruments[idx], vol 0-7 (1, 3 ... 15)
MACRO DRUM
    db ((\1) << 3) | (\2)
    _W \3
ENDM
MACRO DRUML
    db ((\1) << 3) | (\2)
    _WL \3
ENDM
; INSTR / INSTRL n, wait    - command 1
MACRO INSTR
    db 1, \1
    _W \2
ENDM
MACRO INSTRL
    db 1, \1
    _WL \2
ENDM
; CMD c, param, wait        - commands 2-6 (unused by the data)
MACRO CMD
    db \1, \2
    _W \3
ENDM
MACRO ENDPAT
    db 0
ENDM

; ---- order list macros ------------------------------------------------------
; PLAY pattern, pitch       - t = 2*pitch + (pattern >> 8) - $52, must be 1-$7F
MACRO PLAY
    DEF _t = 2 * (\2) + ((\1) >> 8) - $52
    IF _t < 1 || _t > $7F
        FAIL "PLAY out of range"
    ENDC
    db _t, LOW(\1)
    PURGE _t
ENDM
; OREST n                   - rest of n units (n even, < $10000)
MACRO OREST
    db $80 | ((\1) >> 9), ((\1) >> 1) & $FF
ENDM
MACRO ENDLIST
    db 0
ENDM

'''


def note_name(p):
    return pitch_name(p) if 0x2B <= p <= 0x5F else '?$%02X' % p


def main():
    romp = os.path.join(ROOT, 'rom.gb')
    if not os.path.exists(romp):
        romp = os.path.join(ROOT, 'Smurfs 2, The (E) (M4).gb')
    rom = Rom(open(romp, 'rb').read())
    songs, sfx, orders, olists, patuse = walk_all(rom)
    npat = max(patuse) + 1
    out = [HEADER, open(os.path.join(ROOT, 'code_part.asm')).read()]
    P = out.append

    # ---- labels for order lists
    labels = {}
    for s, ch in enumerate(songs):
        for c, (o, l) in enumerate(ch):
            labels.setdefault(o, 'Song%02d_Ch%d' % (s, c + 1))
    for s, (o, l) in enumerate(sfx):
        labels.setdefault(o, 'Sfx%02d' % s)
    for s, ch in enumerate(songs):
        for c, (o, l) in enumerate(ch):
            labels.setdefault(l, 'Song%02d_Ch%d_Loop' % (s, c + 1))
    labels[0x4398] = 'SilentOrder'

    # ---- region map: addr -> (kind, info)
    regions = []
    for n in range(npat):
        a = pattern_ptr(rom, n)
        uses = patuse[n]
        nz = {u[1] for u in uses}
        base = sorted({u[2] for u in uses})
        ev, end, _ = walk_pattern(rom, a, base[0], nz == {True})
        if len(nz) > 1 and any(e[2] == 'note' for e in ev):
            raise SystemExit('pattern %d used as tone and noise' % n)
        regions.append((a, end, 'pat', (n, ev, base, uses, nz == {True})))
    ostarts = sorted(olists)
    seen = set()
    for o in ostarts:
        ent, end = olists[o]
        if any(o >= r[0] and o < r[1] for r in regions if r[2] == 'ord'):
            continue
        regions.append((o, end, 'ord', ent))
    regions.append((0x439B, 0x43AB, 'silentsong', None))
    regions.append((0x5E68, 0x5E68 + 13 * 16, 'songtab', None))
    regions.append((0x5F38, 0x5F80, 'sfxtab', None))
    regions.append((0x5F80, 0x5F80 + 2 * npat, 'pattab', None))
    regions.sort()
    pos = 0x4396
    for a, b, k, info in regions:
        if a != pos:
            raise SystemExit('gap/overlap at %04X (expected %04X) %s' % (a, pos, k))
        pos = b
    assert pos == 0x60E6, hex(pos)

    P('\n; =============================================================================')
    P('; Music / SFX data ($4396-$60E5)')
    P('; =============================================================================\n')
    for a, b, k, info in regions:
        if k == 'pat':
            n, ev, base, uses, noise = info
            users = ', '.join(sorted({'%s %d %s' % (u[0][0], u[0][1], 'SFX' if u[0][0] == 'sfx' else 'CH%d' % (u[0][2] + 1)) for u in uses}))
            if n == 0:
                users = 'silence (SilentOrder, i.e. every non-looping song/SFX end)'
            P('Pat_%03d: ; %s, %s%s' % (n, 'noise' if noise else 'tone', users,
                                        '' if noise else ', entry pitch ' + '/'.join(note_name(x) for x in base)))
            for at, ln, kind, inf, dur in ev:
                raw = rom.b(at)
                if at == 0x4397:
                    P('SilentStream:: ; InitVoice start stream and order-list rests')
                if kind == 'delay':
                    P('    %s %d' % ('DELAYL' if raw & 0x80 else 'DELAY', dur))
                elif kind == 'end':
                    P('    ENDPAT')
                elif kind == 'cmd':
                    c, prm = inf
                    lng = rom.b(at + 2) & 0x80
                    if c == 1:
                        P('    %s %d, %d' % ('INSTRL' if lng else 'INSTR', prm, dur))
                    else:
                        P('    CMD %d, $%02X, %d%s' % (c, prm, dur, ' ; LONG!' if lng else ''))
                        assert not lng
                elif inf[0] == 'drum':
                    lng = rom.b(at + 1) & 0x80
                    P('    %s %d, %d, %d' % ('DRUML' if lng else 'DRUM', inf[1], inf[2], dur))
                else:
                    _, p, v, st, tr = inf
                    nb = at + (2 if tr or rom.b(at) == 7 else 0)
                    if rom.b(at) == 7:
                        P('    TRANSP %d' % tr)
                    lng = rom.b(nb + 1) & 0x80
                    P('    %-5s %d, %d, %d%s; %s' % ('NOTEL' if lng else 'NOTE', st, v, dur,
                                                   ' ' * max(1, 6 - len(str(dur))), note_name(p)))
            P('')
        elif k == 'ord':
            ent = info
            P('%s: ; %s' % (labels[a], ', '.join(sorted('%s %d %s' % (c[0], c[1], 'SFX' if c[0] == 'sfx' else 'CH%d' % (c[2] + 1)) for c in orders.get(a, [])))))
            for at, ln, kind, v in ent:
                if at != a and at in labels:
                    P('%s: ; %s' % (labels[at], ', '.join(sorted('%s %d CH%d' % (c[0], c[1], c[2] + 1) for c in orders.get(at, [])))))
                if kind == 'play':
                    P('    PLAY %d, $%02X' % (v[1], v[0]))
                elif kind == 'rest':
                    P('    OREST %d' % v)
                else:
                    P('    ENDLIST')
            P('')
        elif k == 'silentsong':
            P('SilentSong: ; SndInit, and SndPlaySong with song > 14')
            P('    REPT 4')
            P('    dw SilentOrder, SilentOrder')
            P('    ENDR')
            P('')
        elif k == 'songtab':
            P('SongTable: ; 16 bytes per song: (order list, loop list) for CH1, CH2, CH3, CH4')
            P('; SndPlaySong accepts 13 and 14 too: they read the SFX table below.')
            for s, ch in enumerate(songs):
                P('    dw ' + ', '.join('%s, %s' % (labels[o], labels[l]) for o, l in ch) + ' ; %d' % s)
            P('')
        elif k == 'sfxtab':
            P('SfxTable: ; (order list, loop list); noise SFX start with PLAY x, $2A')
            for s, (o, l) in enumerate(sfx):
                P('    dw %s, %s ; %d%s' % (labels[o], labels[l], s, ' noise' if sfx_is_noise(rom, s) else ''))
            P('')
        elif k == 'pattab':
            P('PatternTable:')
            for i in range(0, npat, 8):
                P('    dw ' + ', '.join('Pat_%03d' % j for j in range(i, min(npat, i + 8))))
            P('')
    P(open(os.path.join(ROOT, 'glue_part.asm')).read())
    open(os.path.join(ROOT, 'Smurfs2_SoundDriver.asm'), 'w').write('\n'.join(out))


if __name__ == '__main__':
    main()
