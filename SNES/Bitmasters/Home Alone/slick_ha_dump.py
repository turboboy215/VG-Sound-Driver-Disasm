#!/usr/bin/env python3
"""slick_ha_dump.py - dump the song of the EARLIEST SLICK driver (Home Alone, 1991)
from an SPC snapshot: song header at $1400 (I/O command 4 format), 7-byte track
entries, instrument table ($06b6), and a decode of every pattern.

usage: python3 slick_ha_dump.py file.spc [--seq]
"""
import sys
spc = open(sys.argv[1], 'rb').read(); ram = spc[0x100:0x10100]
b = lambda a: ram[a & 0xffff]; w = lambda a: b(a) | b(a + 1) << 8
seq = '--seq' in sys.argv
def vlq2(p):
    v = b(p)
    if v < 0x80: return v, p + 1
    return ((v & 0x7f) << 7) | (b(p + 1) & 0x7f) | 0, p + 2   # same bits as the driver
S = 0x1400
lst = (w(S) + 0x1400) & 0xffff; n = b(S + 2)
pats = [(w(lst + 2 * i) + 0x1400) & 0xffff for i in range(n)]
ntr, fl, t0 = b(S + 3), b(S + 4), b(S + 5)
print('song @%04x: %d patterns %s' % (S, n, ' '.join('%04x' % p for p in pats)))
print('tracks=%d flags=$%02x T0DIV=$%02x (tick %.3f ms)' % (ntr, fl, t0, t0 * 0.125))
stats = {}
for t in range(ntr):
    r = [b(S + 6 + 7 * t + k) for k in range(7)]
    print(' track %d: vol=%02x/%02x instr=%02x (unused %02x) pattern=%d flags=%02x transp=%02x' % (t + 1, *r))
    f = r[5] | fl
    p = pats[r[4]] if r[4] < n else None
    if p is None: continue
    seen = {r[4]}
    d, p = vlq2(p); tm = d; out = []
    for _ in range(4000):
        c = b(p)
        if c == 0xe3: stats['E3'] = stats.get('E3', 0) + 1; out.append('%04x t=%d end' % (p, tm)); break
        if c == 0xe5:
            stats['E5'] = stats.get('E5', 0) + 1; out.append('%04x t=%d sync (wait for all channels)' % (p, tm)); p += 1
            continue   # no delta after E5
        elif c == 0xe1:
            stats['E1'] = stats.get('E1', 0) + 1; p += 1; d, p = vlq2(p); out.append('rest +%d' % d); tm += d; continue
        elif c == 0xe4:
            stats['E4'] = stats.get('E4', 0) + 1; tgt = b(p + 1)
            out.append('%04x t=%d goto pattern %d' % (p, tm, tgt))
            if tgt >= n or tgt in seen: out.append('    (loop)'); break
            seen.add(tgt)
            p = pats[tgt]; d, p = vlq2(p); tm += d; continue
        else:
            stats['note'] = stats.get('note', 0) + 1
            nb, vb = c, b(p + 1); p += 2
            txt = 'note %02x vel %x' % (nb, vb & 15)
            if f:
                g, p = vlq2(p); txt += ' voice %d gate %d' % (vb >> 4, g)
            d, p = vlq2(p); out.append(txt + ' +%d' % d); tm += d
            continue
        d, p = vlq2(p); tm += d
    if seq:
        for o in out: print('    ' + o)
print('events:', stats)
print('\ninstruments ($06b6, 8 bytes: SRCN ADSR1 ADSR2 flags transp ? table ?):')
for i in range(32):
    print('  %02x: %s' % (i, ' '.join('%02x' % x for x in ram[0x6b6 + 8 * i:0x6be + 8 * i])))
