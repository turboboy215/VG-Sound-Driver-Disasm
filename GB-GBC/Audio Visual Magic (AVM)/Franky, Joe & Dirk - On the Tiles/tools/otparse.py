#!/usr/bin/env python3
"""On the Tiles - Franky, Joe & Dirk (GB): sound data decoder.

Usage: python3 otparse.py "On the Tiles - Franky, Joe & Dirk (E) [!].gb" > OnTheTiles_SongData.txt

Walks the four music modules, the instrument table and the SFX table in
bank 1 exactly the way the driver does, and prints a tracker-style listing
plus a byte-coverage report for the sound data area ($4A91-$615E).
"""
import struct, sys
from collections import Counter

ROM = open(sys.argv[1], 'rb').read()
BANK = 1
def fo(a):            # bank-1 address -> file offset
    return a if a < 0x4000 else BANK * 0x4000 + (a - 0x4000)
def b(a):  return ROM[fo(a)]
def w(a):  return struct.unpack_from('<H', ROM, fo(a))[0]
def sb(x): return x - 256 if x >= 128 else x

FREQ_TABLE, NOISE_SHIFT, VOICE_CFG, VOL_TABLE = 0x4A91, 0x4B51, 0x4BB1, 0x4BC3
INSTR_TABLE, INSTR_COUNT, SFX_TABLE, SFX_COUNT = 0x5CB0, 11, 0x5DBD, 17
SONGS = [  # (address, game song id in $C2D1, callers)
    (0x4C10, 1, '0:$0293 (boot / MUSIC ON), 0:$26A0 (MUSIC ON toggle)'),
    (0x5175, 2, '0:$2D25'),
    (0x5610, 3, '0:$0B52, 0:$19C6'),
    (0x570F, '4/5/6', '0:$07A6/$07AD/$07B4 (level start, id from level table 1:$6807)'),
]
NOTES = ['C-', 'C#', 'D-', 'D#', 'E-', 'F-', 'F#', 'G-', 'G#', 'A-', 'A#', 'B-']
def nname(i): return NOTES[i % 12] + str(2 + i // 12)
FX = {0: 'arpeggio', 1: 'porta up', 2: 'porta down', 7: 'short row (no param)',
      8: 'stop music', 0xB: 'position jump', 0xC: 'set volume', 0xD: 'pattern break',
      0xF: 'set speed'}

covered = {}
def cover(a, n, what):
    for i in range(n):
        covered[a + i] = what

out = []
P = out.append

# ---------------------------------------------------------------- tables
P('On the Tiles - Franky, Joe & Dirk (GB) - decoded sound data (bank 1)')
P('=' * 72)
P('')
P('Frequency table $4A91: 96 periods, index 0 = C2')
ft = [w(FREQ_TABLE + 2 * i) for i in range(96)]
cover(FREQ_TABLE, 192, 'freq')
for r in range(0, 96, 12):
    P('  %-4s ' % nname(r) + ' '.join('%03X' % x for x in ft[r:r + 12]))
P('')
P('Noise shift table $4B51 (96 bytes, NR43 = value<<4 | $0F; never reaches NR43, see doc):')
cover(NOISE_SHIFT, 96, 'noise')
P('  ' + ' '.join('%X' % b(NOISE_SHIFT + i) for i in range(96)))
P('')
P('Voice config $4BB1 (copied to voice +2..+7 at song start):')
cover(VOICE_CFG, 18, 'voicecfg')
for v in range(3):
    c = [b(VOICE_CFG + 6 * v + i) for i in range(6)]
    P('  voice %d -> CH%d: period slot +%d, volume slot +%d, masks tone AND %02X / OR %02X, noise AND %02X / OR %02X'
      % (v, v + 1, *c))
P('')
P('Volume table $4BC3 (effect C param -> 0..15), 77 bytes (65 used by params $00-$40):')
cover(VOL_TABLE, 77, 'voltable')
P('  ' + ' '.join('%X' % b(VOL_TABLE + i) for i in range(77)))
P('')

# ---------------------------------------------------------------- instruments
def rel_table(a, stop_ff=False):
    """pitch/noise table: signed steps, $80 = hold, $81 n = loop to start+n"""
    s, items = a, []
    while True:
        x = b(a)
        if x == 0x80:
            items.append('hold'); a += 1; break
        if x == 0x81:
            items.append('loop->%d' % b(a + 1)); a += 2; break
        items.append('%+d' % sb(x)); a += 1
    return items, a - s

def env_table(a):
    s, items = a, []
    while True:
        if b(a) == 0xFF:
            items.append('hold'); a += 1; break
        items.append('%d:%d' % (b(a + 1), b(a) + 1)); a += 2   # volume:ticks
    return items, a - s

P('Instruments (table $5CB0, 11 entries, 13-byte records because every song has the $FF prefix)')
P('Pitch/noise tables: cumulative semitone steps, one per tick; $80 = hold, $81 n = loop to entry n.')
P('Volume envelopes: volume:ticks pairs (stored as ticks-1, volume); $FF = hold last volume.')
P('-' * 72)
ptrs = [w(INSTR_TABLE + 2 * i) for i in range(INSTR_COUNT)]
cover(INSTR_TABLE, 2 * INSTR_COUNT, 'instr table')
recs = sorted(set(ptrs) | {0x5CED})
tables_seen = {}
for r in recs:
    by = [b(r + i) for i in range(13)]
    cover(r, 13, 'instr')
    users = [i + 1 for i, p in enumerate(ptrs) if p == r]
    pt, nt, vt = w(r + 7), w(r + 9), w(r + 11)
    P('$%04X  used as %s' % (r, ', '.join('%d' % u for u in users) if users else 'UNREFERENCED'))
    P('   bytes: ' + ' '.join('%02X' % x for x in by))
    P('   transpose %+d, noise burst %s, vibrato %s, fine vol %d'
      % (sb(by[0]), ('%d ticks value $%02X' % (by[1], by[2])) if by[1] else 'off',
         ('depth %d speed %d delay %d' % (by[3] >> 4, by[3] & 15, by[4])) if by[3] else 'off', by[5]))
    for name, p, fn in (('pitch', pt, rel_table), ('noise', nt, rel_table), ('volume', vt, env_table)):
        if p:
            items, n = fn(p)
            tables_seen[p] = (name, n)
            cover(p, n, name + ' tbl')
            P('   %-6s $%04X: %s' % (name, p, ' '.join(items)))
        else:
            P('   %-6s none%s' % (name, ' (tone channel stays disabled)' if name == 'pitch' else ''))
P('')
# unreferenced bytes between tables
P('Unreferenced sub-tables in $5D3B-$5DBC:')
a = 0x5D3B
while a < 0x5DBD:
    if a in covered:
        a += 1; continue
    items, n = rel_table(a)
    P('   $%04X (%d bytes) as pitch table: %s' % (a, n, ' '.join(items)))
    cover(a, n, 'unref tbl'); a += n
P('')

# ---------------------------------------------------------------- songs
def walk(a):
    rows, r = [], 0
    while r < 64:
        x = b(a)
        if x & 0x80:
            n = max(x & 0x7F, 1)
            rows.append((r, a, None, n)); a += 1; r += n; continue
        y = b(a + 1); fx = y & 15
        prm = None if fx == 7 else b(a + 2)
        rows.append((r, a, (x & 0x3F, x & 0x40, y >> 4, fx, prm), 1))
        a += 2 if fx == 7 else 3; r += 1
    return rows, a, r

fxcount, notecount, inscount = Counter(), Counter(), Counter()
for addr, sid, callers in SONGS:
    base = addr + 2 if b(addr) == 0xFF else addr
    L, rst = b(base), b(base + 1)
    orders = [b(base + 6 + i) for i in range(L)]
    npat = max(orders) + 1
    P('=' * 72)
    P('Song $%04X  (game id $C2D1 = %s; started from %s)' % (addr, sid, callers))
    P('  prefix %s  transpose %d' % ('FF' if base != addr else 'none', sb(b(addr + 1)) if base != addr else 0))
    P('  length %d, restart %d, data offset $%04X, module size $%04X (not read by driver)'
      % (L, rst, w(base + 2), w(base + 4)))
    P('  orders: ' + ' '.join('%d' % o for o in orders))
    cover(addr, base + 0x86 - addr, 'song hdr')
    offs = []
    i = 0
    while True:
        v = w(base + 0x86 + 2 * i); offs.append(v); i += 1
        if v == 0: break
    cover(base + 0x86, 2 * len(offs), 'pat table')
    P('  pattern offset table: ' + ' '.join('$%04X' % v for v in offs))
    for p in range(npat):
        pa = base + offs[p]
        starts = [pa + 4, pa + w(pa) + 4, pa + w(pa + 2) + 4]
        cover(pa, 4, 'pat hdr')
        P('')
        P('  Pattern %d @ $%04X   voice streams: %s' % (p, pa, ' '.join('$%04X' % s for s in starts)))
        grid = {}
        for v in range(3):
            rows, e, r = walk(starts[v])
            cover(starts[v], e - starts[v], 'pattern')
            assert r == 64, (hex(addr), p, v, r)
            nxt = starts[v + 1] if v < 2 else base + offs[p + 1]
            assert e == nxt, (hex(e), hex(nxt))
            for (row, ra, ev, n) in rows:
                if ev is None:
                    grid.setdefault(row, ['', '', ''])[v] = '(%d empty)' % n if n > 1 else ''
                    continue
                note, b6, ins, fx, prm = ev
                s = (nname(note) if note != 0x3F else '...') + (' %X' % ins if ins else ' .')
                s += ' %X%s' % (fx, '..' if prm is None else '%02X' % prm)
                if b6: s += '*'
                grid.setdefault(row, ['', '', ''])[v] = s
                if note != 0x3F: notecount[note] += 1
                if ins: inscount[ins] += 1
                if fx or (prm): fxcount[fx] += 1
        for row in sorted(grid):
            P('   %02d | %-16s| %-16s| %-16s' % (row, *grid[row]))
    # pad byte
    end = base + offs[npat]
    if end in covered: pass
    else:
        cover(end, 1, 'pad'); P('')
        P('  pad byte $%04X = $%02X' % (end, b(end)))
    P('')

P('=' * 72)
P('Effect use across all songs: ' + ', '.join('%X (%s) x%d' % (k, FX.get(k, 'ignored'), v)
                                             for k, v in sorted(fxcount.items())))
P('Instrument use: ' + ', '.join('%d x%d' % kv for kv in sorted(inscount.items())))
P('Row note range: %s .. %s' % (nname(min(notecount)), nname(max(notecount))))
P('')

# ---------------------------------------------------------------- SFX
P('=' * 72)
P('SFX table $5DBD (17 entries). Frame = 3 bytes c, d, e, one frame per tick on CH2.')
P('  vol = c>>4; period = ((~c & $15) & 7)<<8 | ~d  (bit 9 can never be set);')
P('  e: bit7 noise on (index e&$1F), bit6 tone on, bit5 end')
cover(SFX_TABLE, 2 * SFX_COUNT, 'sfx table')
# "ld c, id" addresses in bank 0; each is followed by call $1B42 (PlaySfx wrapper)
SFX_CALLERS = {2: '0:$1B6B (after SndReset)', 3: '0:$1570', 4: '0:$14B8, 0:$2B50 (after SndReset)',
               5: '0:$138B', 7: '0:$1482', 8: '0:$175D', 9: '0:$1ACD', 10: '0:$1187',
               12: '0:$221B, $226A, $22BC, $2314', 15: '0:$15C5',
               16: '0:$2252, $22A1, $22F9, $2351'}
for i in range(SFX_COUNT):
    a = w(SFX_TABLE + 2 * i); s = a; fr = []
    while True:
        c, d_, e = b(a), b(a + 1), b(a + 2); fr.append((c, d_, e)); a += 3
        if e & 0x20: break
    cover(s, a - s, 'sfx')
    P('')
    P('SFX %2d @ $%04X  %d frames  callers: %s' % (i, s, len(fr), SFX_CALLERS.get(i, 'none found')))
    for c, d_, e in fr:
        per = ((((c ^ 0xFF) & 0x15) & 7) << 8) | (d_ ^ 0xFF)
        per7 = (((c ^ 0xFF) & 7) << 8) | (d_ ^ 0xFF)
        parts = ['vol %2d' % (c >> 4)]
        parts.append(('tone $%03X %6.1f Hz' % (per, 131072 / (2048 - per))) if e & 0x40 else 'tone off           ')
        if per != per7 and e & 0x40: parts.append('(&7 would be $%03X)' % per7)
        if e & 0x80: parts.append('noise %d' % (e & 0x1F))
        if e & 0x20: parts.append('END')
        P('   %02X %02X %02X  ' % (c, d_, e) + '  '.join(parts))
P('')
P('$5E6C-$5E7F: unreferenced. Together with the byte before it ($5E6B = $F0) it is a complete')
P('copy of SFX 8 that ends properly in 00 00 20. SFX 8 itself (at $5E57) has no end frame of its')
P('own: its 7th frame borrows that $F0 as its e byte, and $F0 has bit 5 set, so it stops there.')
cover(0x5E6C, 0x5E80 - 0x5E6C, 'sfx8 copy')
P('')

# ---------------------------------------------------------------- coverage
P('=' * 72)
P('Coverage of $4A91-$615E:')
lo, hi = 0x4A91, 0x615F
miss = [a for a in range(lo, hi) if a not in covered]
P('  %d of %d bytes accounted for' % (hi - lo - len(miss), hi - lo))
if miss:
    runs, st = [], miss[0]
    for x, y in zip(miss, miss[1:] + [None]):
        if y != x + 1:
            runs.append((st, x)); st = y
    for s, e in runs:
        P('  not covered: $%04X-$%04X: %s' % (s, e, ' '.join('%02X' % b(a) for a in range(s, e + 1))))
print('\n'.join(out))
