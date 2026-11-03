#!/usr/bin/env python3
"""Generate RGBDS source for Biox sound driver B (Burger Burger Pocket v1, Daiku no Gensan v2)."""
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from asmgen import Gen
from engB import walk, walk_penv

NOTE = ['C', 'Cs', 'D', 'Ds', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'As', 'B']
def notename(n):
    return '%s_%d' % (NOTE[n % 12], n // 12 + 2)

def ram_symbols(v):
    ram = {}
    def blk(base, name, size):
        for i in range(size):
            ram[base + i] = name if i == 0 else '%s+$%02X' % (name, i) if size > 9 else '%s+%d' % (name, i)
    blk(0xFFD0, 'hSndCurMusic', 1); blk(0xFFD1, 'hSndCurSfx', 1); blk(0xFFD2, 'hSndTempo', 1)
    blk(0xFFD3, 'hSndTempoStep', 2); blk(0xFFD5, 'hSndTempoAcc', 2); blk(0xFFD7, 'hSndTicks', 1)
    if v == 2:
        f = [(0xFFD8, 'hSndFlags', 1), (0xFFD9, 'hSndPtr', 2), (0xFFDB, 'hSndCount', 1), (0xFFDC, 'hSndLength', 1),
             (0xFFDD, 'hSndLoopCount', 1), (0xFFDE, 'hSndLoopPtr', 2), (0xFFE0, 'hSndRetPtr', 2), (0xFFE2, 'hSndUnusedE2', 6),
             (0xFFE8, 'hSndPEnvStart', 2), (0xFFEA, 'hSndPEnvPtr', 2), (0xFFEC, 'hSndFreq', 2), (0xFFEE, 'hSndEnv', 1),
             (0xFFEF, 'hSndDuty', 1), (0xFFF0, 'hSndTranspose', 1)]
        blk(0xFFC1, 'hSndPause', 1); blk(0xFFC8, 'hCurRomBank', 1); blk(0xFFAA, 'hCurRomBank2', 1)
        mus = 0xD44C; size = 0x19; sfx = 0xD4B0; misc = 0xD514
        names = [(0xD514, 'wSndQueue', 8), (0xD51C, 'wSndQueuePtr', 2), (0xD51E, 'wSndQueueCount', 1),
                 (0xD51F, 'wSndNRx1', 1), (0xD520, 'wSndChanIdx', 1), (0xD521, 'wSndFadeMode', 1),
                 (0xD522, 'wSndFadeUnused', 1), (0xD523, 'wSndFadeTimer', 1), (0xD524, 'wSndWavePtr', 2),
                 (0xD526, 'wSndWaveSaved', 2)]
    else:
        f = [(0xFFD8, 'hSndFlags', 1), (0xFFD9, 'hSndPtr', 2), (0xFFDB, 'hSndCount', 1), (0xFFDC, 'hSndLength', 1),
             (0xFFDD, 'hSndLoopCount', 1), (0xFFDE, 'hSndLoopPtr', 2), (0xFFE0, 'hSndRetPtr', 2), (0xFFE2, 'hSndUnusedE2', 6),
             (0xFFE8, 'hSndPEnvPtr', 2), (0xFFEA, 'hSndFreq', 2), (0xFFEC, 'hSndEnv', 1), (0xFFED, 'hSndDuty', 1),
             (0xFFEE, 'hSndTranspose', 1), (0xFFEF, 'hSndUnusedEF', 1)]
        blk(0xFFBA, 'hSndPause', 1)
        mus = 0xC001; size = 0x18; sfx = 0xC061; misc = 0xC0C1
        names = [(0xC0C1, 'wSndQueue', 8), (0xC0C9, 'wSndQueuePtr', 2), (0xC0CB, 'wSndQueueCount', 1),
                 (0xC0CC, 'wSndNRx1', 1), (0xC0CD, 'wSndChanIdx', 1), (0xC0CE, 'wSndFadeMode', 1),
                 (0xC0CF, 'wSndFadeUnused', 1), (0xC0D0, 'wSndFadeTimer', 1)]
    for a, n, s in f: blk(a, n, s)
    for k in range(4):
        blk(mus + size * k, 'wSndMus%d' % (k + 1), size)
        blk(sfx + size * k, 'wSndSfx%d' % (k + 1), size)
    for a, n, s in names: blk(a, n, s)
    equ = []
    seen = set()
    for a in sorted(ram):
        nm = ram[a]
        if '+' in nm: continue
        equ.append('DEF %-15s EQU $%04X' % (nm, a))
    return ram, '\n'.join(equ) + '\n'

def emit_track_items(g, items, noisech=()):
    for a in sorted(items):
        if a in g.items: continue
        n, k, info, ch = items[a]
        if k == 'len':
            nxt = a + 1
            if nxt in items and items[nxt][1] == 'note' and nxt not in g.labels:
                g.line(a, 2, '\tsnd_note %s, %d' % (notename(items[nxt][2]), info))
            else:
                g.line(a, 1, '\tsnd_len %d' % info)
        elif k == 'note':
            g.line(a, 1, '\tsnd_note %s' % notename(info))
        elif k == 'drum':
            g.line(a, 1, '\tsnd_drum %d' % info)
        elif k == 'bad':
            g.line(a, 1, '\tdb $%02X\t; invalid command (crashes the driver)' % info)
        else:
            b, name, args, kind = info
            if kind in ('jump', 'call', 'penv', 'oenv', 'wave'):
                t = args[0] | args[1] << 8
                g.line(a, n, '\t%s %s' % (name, g.ref(t) if t else '0'))
            elif name == 'snd_noise':
                g.line(a, n, '\tsnd_noise %d, $%02X, $%02X' % tuple(args))
            elif name in ('snd_loop',):
                g.line(a, n, '\tsnd_loop %d' % args[0])
            elif name == 'snd_tempo':
                g.line(a, n, '\tsnd_tempo %d' % args[0])
            else:
                g.line(a, n, '\t%s%s' % (name, (' ' + ', '.join('$%02X' % x for x in args)) if args else ''))

def emit_penv(g, pitems):
    for a in sorted(pitems):
        if a in g.items: continue
        n, k, v = pitems[a]
        if k == 'stop': g.line(a, 1, '\tenv_stop')
        elif k == 'jump': g.line(a, 3, '\tenv_jump %s' % g.ref(v))
    # values: group runs
    for a in sorted(pitems):
        if a in g.items: continue
        if pitems[a][1] != 'val': continue
        e = a
        while e in pitems and pitems[e][1] == 'val' and e not in g.items and (e == a or e not in g.labels): e += 1
        vals = []
        for x in range(a, e):
            v = pitems[x][2]
            vals.append('%d' % (v - 256 if v >= 128 else v))
        g.line(a, e - a, '\tdb ' + ', '.join(vals))

def emit_header(g, h):
    m = g.rb(h)
    n = bin(m & 15).count('1')
    ptrs = [g.rw(h + 1 + 2 * i) for i in range(n)]
    k = n
    # a header can be shorter than its mask says (the track starts inside it)
    for i in range(n):
        if any((h + 1 + 2 * i + d) in g.labels for d in (0, 1)):
            k = i; break
    txt = '\tdb $%02X\t; channel mask' % m
    if k:
        txt += '\n\tdw %s' % ', '.join(g.ref(p) if p in g.labels else '$%04X' % p for p in ptrs[:k])
    if k < n:
        txt += '\t; mask has %d channels: the last %d pointer(s) are read from the track bytes below (%s)' % (
            n, n - k, ', '.join('$%04X' % p for p in ptrs[k:]))
    g.line(h, 1 + 2 * k, txt)
    return ptrs, m
