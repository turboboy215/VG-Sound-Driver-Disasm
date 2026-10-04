#!/usr/bin/env python3
"""slick_dump.py - dump SLICK/Audio (Bitmasters, 1994) data from an SPC snapshot.

usage: python3 slick_dump.py file.spc [--seq]

Lists the registered sound banks, every sound (music/SFX) with its header,
the instrument table, the sample directory, and (with --seq) decodes the
sequence data of every track using the command names from SLICK_Engine_Notes.md.
"""
import sys

VCMD = {0xe0: ('nop', 0), 0xe1: ('nop', 0), 0xe2: ('loop', 1), 0xe3: ('end', 0),
        0xe4: ('nop', 0), 0xe5: ('nop', 0), 0xe6: ('program', 1), 0xe7: ('tempo', 1),
        0xe8: ('next_pattern', 0), 0xe9: ('ctrl', 2), 0xea: ('nop', 0),
        0xeb: ('stop_point', 0), 0xec: ('flag_clr', 1), 0xed: ('flag_set', 1),
        0xee: ('flag_inc', 1), 0xef: ('nop', 0)}
NOTES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


class Spc:
    def __init__(self, fn):
        d = open(fn, 'rb').read()
        self.ram = d[0x100:0x10100]

    def b(self, a):
        return self.ram[a & 0xffff]

    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8

    def vlq(self, p):
        v = self.b(p); p += 1
        if v < 0x80:
            return v, p
        v &= 0x7f; c = self.b(p); p += 1
        if c < 0x80:
            return v << 7 | c, p
        d = self.b(p); p += 1
        return v << 14 | (c & 0x7f) << 7 | d, p


def note_name(n):
    return '%s%d' % (NOTES[n % 12], n // 12 - 1)


def banks(s):
    out = []
    for k in range(8):
        st = s.w(0x0297 + 2 * k)
        if st >> 8:
            out.append((k, st, s.w(0x02a7 + 2 * k)))
    return out


def sounds(s, start):
    p = start
    while True:
        sid = s.b(p + 2)
        if sid == 0xff:
            return
        yield p
        size = s.w(p)
        if size == 0:
            return
        p += size


def decode(s, ptr, flags, base, listptr, maxev=4000):
    """yield text lines for one track"""
    visited_pat = 0
    if flags & 4:
        lp = listptr
        ptr = (s.w(lp) + base + 1) & 0xffff
        yield '    [order list @%04x] pattern @%04x' % (lp, ptr - 1)
    d, ptr = s.vlq(ptr)
    t = d
    line = []
    for _ in range(maxev):
        a = ptr
        c = s.b(ptr); ptr += 1
        if c < 0x80:
            txt = 'note %-4s' % note_name(c)
            if not flags & 1:
                txt += ' vel=%02x' % s.b(ptr); ptr += 1
            g, ptr = s.vlq(ptr)
            txt += ' gate=%d' % (g * 2)
        elif c < 0xc0:
            txt = 'ignored %02x %02x' % (c, s.b(ptr)); ptr += 1
        elif c < 0xe0:
            semi = c & 0x1f
            if semi >= 0x10:
                semi -= 0x20
            txt = 'bend %+d+%d/256' % (semi, s.b(ptr)); ptr += 1
        elif c < 0xf0:
            name, n = VCMD[c]
            if c == 0xe2:
                n = 1 if s.b(ptr) == 0 else 0
                name = 'loop_start' if n else 'loop_back'
            args = [s.b(ptr + i) for i in range(n)]
            ptr += n
            txt = name + (' ' + ' '.join('%02x' % x for x in args) if args else '')
            if c == 0xe3 or (c == 0xe2 and not n):
                yield '    %04x t=%-6d %s' % (a, t, txt)
                return
            if c == 0xe8:
                visited_pat += 1
                listptr += 2
                if visited_pat > 64:
                    yield '    ... (order list continues)'
                    return
                ptr = (s.w(listptr) + base + 1) & 0xffff
                yield '    %04x t=%-6d %s' % (a, t, txt)
                yield '    [order list @%04x] pattern @%04x' % (listptr, ptr - 1)
                d, ptr = s.vlq(ptr)
                t += d
                continue
        else:
            yield '    %04x ILLEGAL %02x' % (a, c)
            return
        d, ptr = s.vlq(ptr)
        yield '    %04x t=%-6d %s   (+%d)' % (a, t, txt, d)
        t += d


def main():
    fn = sys.argv[1]
    seq = '--seq' in sys.argv
    s = Spc(fn)
    print('Registered banks:')
    for k, st, en in banks(s):
        print('  slot %d: %04x-%04x' % (k, st, en))
    for k, st, en in banks(s):
        for p in sounds(s, st):
            sid, ntr, tempo, flags, echo = s.b(p + 2), s.b(p + 3), s.b(p + 4), s.b(p + 5), s.b(p + 6)
            th = p + 7 + (12 if echo else 0)
            base = th + 8 * ntr
            print('\nSound $%02x @%04x  tracks=%d tempo=$%02x (%d BPM) flags=$%02x echo=%d'
                  % (sid, p, ntr, tempo, tempo + 40, flags, echo))
            if echo:
                e = [s.b(p + 7 + i) for i in range(12)]
                print('  echo: EDL=%d EVOL=%02x/%02x EFB=%02x FIR=%s' % (e[0], e[1], e[2], e[3],
                      ' '.join('%02x' % x for x in e[4:])))
            for t in range(ntr):
                h = [s.b(th + 8 * t + i) for i in range(8)]
                off = h[6] | h[7] << 8
                print('  track %d: flags=$%02x prio=$%02x vel=$%02x pan=$%02x transp=%d prog=$%02x data=%04x'
                      % (t + 1, h[0], h[1], h[2], h[3], (h[4] ^ 0x80) - 0x80, h[5], (p + off) & 0xffff))
                if seq:
                    fl = h[0] | flags
                    for l in decode(s, (p + off) & 0xffff, fl, base, (p + off) & 0xffff):
                        print(l)
    print('\nInstruments (SRCN ADSR1 ADSR2 flags transp fine flags2 veltrem vib delay):')
    for i in range(128):
        if s.b(0x1e00 + i) != 0xff:
            print('  %02x: ' % i + ' '.join('%02x' % s.b(0x1e00 + 0x80 * k + i) for k in range(10)))
    print('\nSample directory ($2300) - start, loop, base octave from the 27-byte header:')
    for i in range(64):
        st, lp = s.w(0x2300 + 4 * i), s.w(0x2302 + 4 * i)
        if st in (0, 0xffff):
            continue
        print('  %02x: start=%04x loop=%04x base_octave=%d pitch[C]=%04x' % (i, st, lp, s.b(st - 1), s.w(st - 27)))


if __name__ == '__main__':
    main()
