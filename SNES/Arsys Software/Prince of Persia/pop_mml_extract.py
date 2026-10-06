#!/usr/bin/env python3
"""Arsys (Prince of Persia SFC) sound driver - song/MML extractor.

Usage: python3 pop_mml_extract.py file.spc [--base 1A80|3680] [--sfx]

Dumps the song header, per-channel order lists, the ASCII MML phrases
(with tick counts per phrase and per loop) and the 11-byte instrument table.
--sfx also dumps the SFX bank at $1560 (8 slots of raw MML) and the SFX
instrument table at $1872.
"""
import sys

def load(path):
    d = open(path, 'rb').read()
    return d[0x100:0x10100] if d[:27] == b'SNES-SPC700 Sound File Data' else d

def w(r, a): return r[a] | r[a + 1] << 8

def phrase(r, a):
    return r[a:r.index(0, a)].decode('latin1')

def phrase_ticks(mml, L, sfx=False):
    """Count ticks consumed by a phrase. L = current sticky default length."""
    i, t, n = 0, 0, len(mml)
    def num(i):
        j = i
        while j < n and mml[j].isdigit(): j += 1
        return (int(mml[i:j]) if j > i else None), j
    while i < n:
        c = chr(ord(mml[i]) & 0x7F); i += 1
        if c == '%':                      # comment until next '%'
            i = mml.index('%', i) + 1; continue
        if c in '#"':                     # sharp prefix: next char is the note
            i += 1; c = 'C'
        if c in 'ABCDEFGRS':
            v, i = num(i)
            if v is not None: L = v       # lengths are sticky
            t += L if L else 1            # length 0 is treated as 1 tick
        elif c == '$':
            v, i = num(i)
            if i < n and mml[i] == ',': v, i = num(i + 1)
        elif c in '@HIJKLMNOPQTUVW()=':
            v, i = num(i)
    return t, L

INST_FIELDS = 'SRCN ADSR1 ADSR2 TremDepth TremPeriod VibDepth VibPeriod LFOmode VibDelay Tune(lo,hi)'

def dump_insts(r, a, count):
    print('  idx  ' + INST_FIELDS)
    for i in range(count):
        e = r[a + i * 11:a + i * 11 + 11]
        tune = e[9] | e[10] << 8
        if tune >= 0x8000: tune -= 0x10000
        print('  @%-3d %02X   %02X    %02X    %3d %3d   %3d %3d   %02X  %3d   %+d'
              % (i, e[0], e[1] | 0x80, e[2], e[3], e[4], e[5], e[6], e[7], e[8], tune))

def dump_song(r, base):
    inst = base + w(r, base)
    mask = r[base + 2]
    print('; Song @ $%04X   instrument table @ $%04X   channel mask %02X' % (base, inst, mask))
    maxinst = 0
    for ch in range(8):
        if not mask & (1 << ch): continue
        lo = base + w(r, base + 3 + 2 * ch)
        print('\n; ---- Channel %d  (order list @ $%04X) ----' % (ch, lo))
        p, L, total, loopstart, intro = lo, 16, 0, None, 0
        entries = []
        while True:
            cnt, off = r[p], w(r, p + 1)
            if cnt == 0xFE:
                tgt = base + off
                print('; FE -> loop to order entry @ $%04X' % tgt)
                loopstart = tgt; break
            if cnt in (0x00, 0xFF):
                print('; %02X -> %s' % (cnt, 'stop all' if cnt == 0 else 'channel end')); break
            if off == 0:
                p += 3; continue
            m = phrase(r, base + off)
            tt = 0
            for _ in range(cnt):
                x, L = phrase_ticks(m, L); tt += x
            entries.append((p, tt))
            for k in range(len(m)):
                if m[k] == '@':
                    j = k + 1
                    while j < len(m) and m[j].isdigit(): j += 1
                    if j > k + 1: maxinst = max(maxinst, int(m[k + 1:j]))
            print('x%-2d $%04X  %5d ticks  %s' % (cnt, base + off, tt, m))
            p += 3
        if loopstart is not None:
            intro = sum(t for a, t in entries if a < loopstart)
            loop = sum(t for a, t in entries if a >= loopstart)
            print('; intro %d ticks, loop %d ticks' % (intro, loop))
    print('\n; ---- Instruments (11 bytes each) ----')
    dump_insts(r, inst, maxinst + 1)

def dump_sfx(r):
    bank = 0x1560
    print('\n; ==== SFX bank @ $1560 (instrument table @ $%04X) ====' % (bank + w(r, bank)))
    for s in range(8):
        a = bank + w(r, bank + 2 + 2 * s)
        if r[a] in (0x00, 0xFF): continue
        print('slot %d @ $%04X: %s' % (s, a, phrase(r, a)))
    dump_insts(r, bank + w(r, bank), 46)

if __name__ == '__main__':
    args = sys.argv[1:]
    if not args: print(__doc__); sys.exit(1)
    r = load(args[0])
    base = 0x1A80
    if '--base' in args: base = int(args[args.index('--base') + 1], 16)
    dump_song(r, base)
    if '--sfx' in args: dump_sfx(r)
