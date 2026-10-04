#!/usr/bin/env python3
"""Decoder for the Smurfs 2 (GB) sound driver data (bank 4).

Usage: smparse.py rom.gb            -> text dump (SongData.txt)
       import smparse; smparse.walk_all(rom) -> coverage info for the .asm generator
"""
import sys

BANK = 4
SONG_TABLE = 0x5E68
N_SONGS = 13          # 0..12 are real; 13/14 read the SFX table
SFX_TABLE = 0x5F38
N_SFX = 18
PAT_TABLE = 0x5F80
FREQ_BASE = 0x42D6    # driver indexes FREQ_BASE + 2*pitch
FREQ_FIRST = 0x432C   # first real period (pitch $2B)
FREQ_END = 0x4396
TONE_INS = 0x4154     # 2-byte entries, indexed by voice +$0C
NOISE_INS = 0x4161    # 3-byte entries, indexed by (note>>3)&15
NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


class Rom:
    def __init__(self, data):
        self.d = data

    def b(self, a):
        return self.d[BANK * 0x4000 + a - 0x4000] if a >= 0x4000 else self.d[a]

    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8


def pitch_name(p):
    """pitch index -> note name. pitch $2B = G2 (period $02C6)."""
    n = p - 0x2B + 7 + 2 * 12   # semitones from C0
    return '%s%d' % (NOTE_NAMES[n % 12], n // 12)


def read_dur(r, a):
    x = r.b(a)
    if x & 0x80:
        return (x & 0x7F) * 2 + r.b(a + 1) * 256, a + 2
    return x * 2, a + 1


def walk_pattern(r, a, base, noise=False):
    """Walk one pattern stream. Returns list of events and end address (exclusive).
    base: pitch register value (+9) at entry. Event tuples: (addr, len, kind, info, dur)."""
    ev = []
    p = base
    start = a
    d, a2 = read_dur(r, a)
    ev.append((a, a2 - a, 'delay', None, d))
    a = a2
    while True:
        x = r.b(a)
        if x == 0:
            ev.append((a, 1, 'end', None, None))
            return ev, a + 1, p
        if x < 7:
            prm = r.b(a + 1)
            d, a2 = read_dur(r, a + 2)
            ev.append((a, a2 - a, 'cmd', (x, prm), d))
            a = a2
            continue
        at = a
        tr = 0
        if x == 7 and not noise:
            tr = r.b(a + 1)
            if tr >= 0x80:
                tr -= 256
            p = (p + tr) & 0xFF
            a += 2
            x = r.b(a)
        vol = x & 7
        step = ((x >> 3) & 0x1F) - 16
        if noise:
            info = ('drum', (x >> 3) & 15, vol, tr)
        else:
            p = (p + step) & 0xFF
            info = ('note', p, vol, step, tr)
        d, a2 = read_dur(r, a + 1)
        ev.append((at, a2 - at, 'note', info, d))
        a = a2


def walk_order(r, a):
    """Walk an order list until $00. Returns entries and end address."""
    ent = []
    while True:
        x = r.b(a)
        if x == 0:
            ent.append((a, 1, 'end', None))
            return ent, a + 1
        if x & 0x80:
            v = ((x << 8 | r.b(a + 1)) << 1) & 0xFFFF
            ent.append((a, 2, 'rest', v))
        else:
            t = x + 0x52
            base = t >> 1
            pat = (t & 1) << 8 | r.b(a + 1)
            ent.append((a, 2, 'play', (base, pat)))
        a += 2


def collect(r):
    """Return dict of all streams: songs, sfx, patterns with first-use info."""
    songs = []
    for s in range(N_SONGS):
        h = SONG_TABLE + 16 * s
        songs.append([(r.w(h + 4 * c), r.w(h + 4 * c + 2)) for c in range(4)])
    sfx = []
    for s in range(N_SFX):
        h = SFX_TABLE + 4 * s
        sfx.append((r.w(h), r.w(h + 2)))
    return songs, sfx


def pattern_ptr(r, n):
    return r.w(PAT_TABLE + 2 * n)


def walk_all(r):
    songs, sfx = collect(r)
    orders = {}
    patuse = {}   # pattern -> set of (context, noise)
    lists = set()
    for s, chans in enumerate(songs):
        for c, (o, l) in enumerate(chans):
            lists.add(o)
            lists.add(l)
            for ol in (o, l):
                for key in [ol]:
                    pass
            for ol in {o, l}:
                orders.setdefault(ol, set()).add(('song', s, c))
    for s, (o, l) in enumerate(sfx):
        orders.setdefault(o, set()).add(('sfx', s, 4))
        orders.setdefault(l, set()).add(('sfx', s, 4))
    olists = {}
    for o in sorted(orders):
        ent, end = walk_order(r, o)
        olists[o] = (ent, end)
        noise = any(ctx[2] == 3 for ctx in orders[o])
        for e in ent:
            if e[2] == 'play':
                base, pat = e[3]
                for ctx in orders[o]:
                    nz = ctx[2] == 3 or (ctx[0] == 'sfx' and sfx_is_noise(r, ctx[1]))
                    patuse.setdefault(pat, set()).add((ctx, nz, base))
    return songs, sfx, orders, olists, patuse


def sfx_is_noise(r, n):
    o = r.w(SFX_TABLE + 4 * n)
    return (r.b(o) >> 1) == 1


def main():
    rom = Rom(open(sys.argv[1], 'rb').read())
    songs, sfx, orders, olists, patuse = walk_all(rom)
    out = []
    P = out.append
    P('Smurfs 2 / The Smurfs Travel the World (GB) - decoded sound data (bank 4)')
    P('Durations are in timer units; each tick subtracts (256 - speed). Pitch $2B = G2.')
    P('')
    P('== Tables ==')
    P('ToneInstruments ($%04X, index = command 1 param): NRx1, NRx2 low bits' % TONE_INS)
    for i in range(8):
        P('  %d: %02X %02X' % (i, rom.b(TONE_INS + 2 * i), rom.b(TONE_INS + 2 * i + 1)))
    P('NoiseInstruments ($%04X, index = note bits 3-6): NR41, NR42 low bits, NR43' % NOISE_INS)
    for i in range(9):
        a = NOISE_INS + 3 * i
        P('  %d: %02X %02X %02X' % (i, rom.b(a), rom.b(a + 1), rom.b(a + 2)))
    P('FreqTable ($%04X): pitch $2B-$5F' % FREQ_FIRST)
    for i in range(53):
        P('  $%02X %-4s $%04X' % (0x2B + i, pitch_name(0x2B + i), rom.w(FREQ_FIRST + 2 * i)))
    P('')
    P('Game speeds: songs 0/2/3/5/10/11/12 $F3, 1 $F2, 4 $F4, 6 $F2, 7 $F6, 8 $F1, 9 $EF')
    P('')
    P('== Songs (table $%04X, 16 bytes each: 4 x (order list, loop list)) ==' % SONG_TABLE)
    for s, ch in enumerate(songs):
        P('Song %2d: ' % s + '  '.join('%s %04X/%04X' % (n, o, l) for n, (o, l) in zip(['CH1', 'CH2', 'CH3', 'CH4'], ch)))
    P('')
    P('== SFX (table $%04X, 4 bytes each: order list, loop list) ==' % SFX_TABLE)
    for s, (o, l) in enumerate(sfx):
        P('SFX %2d: %04X/%04X  %s' % (s, o, l, 'noise (CH4)' if sfx_is_noise(rom, s) else 'tone (CH1)'))
    P('')
    P('== Order lists ==')
    for o in sorted(olists):
        ent, end = olists[o]
        ctx = ', '.join('%s %d %s' % (c[0], c[1], 'SFX' if c[0] == 'sfx' else 'CH%d' % (c[2] + 1)) for c in sorted(orders[o]))
        P('%04X-%04X  (%s)' % (o, end - 1, ctx))
        for a, ln, k, v in ent:
            if k == 'play':
                P('   %04X  play pattern %3d  base pitch $%02X (%s)' % (a, v[1], v[0], pitch_name(v[0])))
            elif k == 'rest':
                P('   %04X  rest %d' % (a, v))
            else:
                P('   %04X  end -> loop list' % a)
    P('')
    P('== Patterns (table $%04X) ==' % PAT_TABLE)
    npat = max(patuse) + 1
    for n in range(npat):
        a = pattern_ptr(rom, n)
        uses = patuse.get(n)
        if not uses:
            P('Pattern %3d @%04X: unused' % (n, a))
            continue
        noise = any(u[1] for u in uses)
        base = sorted({u[2] for u in uses})
        evx, _, _ = walk_pattern(rom, a, 0x40, noise)
        kind = 'NOISE' if noise else 'tone'
        if not any(e[2] == 'note' for e in evx):
            kind = 'rest '
        P('Pattern %3d @%04X  %s  base %s  used by %s' % (
            n, a, kind, ','.join('$%02X' % b for b in base),
            ', '.join(sorted({'%s%d/%s' % (u[0][0], u[0][1], 'SFX' if u[0][0] == 'sfx' else 'CH%d' % (u[0][2] + 1)) for u in uses}))))
        ev, end, _ = walk_pattern(rom, a, base[0], noise)
        for at, ln, k, info, dur in ev:
            if k == 'delay':
                P('     %04X  delay %d' % (at, dur))
            elif k == 'end':
                P('     %04X  end' % at)
            elif k == 'cmd':
                c, prm = info
                nm = {1: 'instrument', 3: 'set +0A (unused)', 4: 'set +0B (unused)'}.get(c, 'no-op')
                P('     %04X  cmd %d %s $%02X   wait %d' % (at, c, nm, prm, dur))
            else:
                if info[0] == 'drum':
                    P('     %04X  drum %2d vol %2d%s   wait %d' % (at, info[1], info[2] * 2 + 1 if info[2] else 0,
                                                          ' (esc %+d)' % info[3] if info[3] else '', dur))
                else:
                    _, p, v, st, tr = info
                    P('     %04X  %-4s (%+3d%s) vol %2d   wait %d' % (
                        at, pitch_name(p) if 0x2B <= p < 0x60 else '?%02X' % p, st,
                        ' esc %+d' % tr if tr else '', v * 2 + 1 if v else 0, dur))
    P('')
    P('== Coverage ==')
    P('$4396-$60E5 (%d bytes): patterns, order lists, SilentSong ($439B), SongTable ($5E68, 13 songs),' % (0x60E6 - 0x4396))
    P('SfxTable ($5F38, 18 SFX), PatternTable ($5F80, %d patterns). gen_asm.py asserts there are no gaps' % npat)
    P('or overlaps, and the generated .asm rebuilds the bank byte-exact.')
    print('\n'.join(out))


if __name__ == '__main__':
    main()
