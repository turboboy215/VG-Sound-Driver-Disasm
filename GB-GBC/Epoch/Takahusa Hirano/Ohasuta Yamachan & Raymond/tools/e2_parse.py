"""Analysis of Epoch "type 2" sound banks (Ohasuta Yamachan & Raymond,
Doraemon - Aruke Aruke Labyrinth, Sylvanian Families - Otogi no Kuni no Pendant).

analyze(game, bank) -> Bank object with code, tables, songs, tracks and a
byte-exact list of items covering $4000..end.
"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from sm83 import disasm  # noqa: E402

ROMDIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..')   # the Epoch2 folder

GAMES = {
    'oha': dict(file='Ohasuta Yamachan & Raymond (J) [C][!].gbc', title='Ohasuta Yamachan & Raymond (J)', ver='A', ram=0xCC,
                sfx=0x08, music=[0x09, 0x0A, 0x0B, 0x0C]),
    'dora3': dict(file='Doraemon - Aruke Aruke Labyrinth (J) [C][!].gbc', title='Doraemon - Aruke Aruke Labyrinth (J)', ver='B', ram=0xDF,
                  sfx=0x05, music=[0x06, 0x07, 0x08, 0x09, 0x2C, 0x2D, 0x3D, 0x3E, 0x3F]),
    'sylv': dict(file='Sylvanian Families - Otogi no Kuni no Pendant (J) [C][!].gbc', title='Sylvanian Families - Otogi no Kuni no Pendant (J)', ver='C', ram=0xCF,
                 sfx=0x7A, music=list(range(0x70, 0x79))),
}

_romcache = {}


def rom(game):
    if game not in _romcache:
        _romcache[game] = open(os.path.join(ROMDIR, GAMES[game]['file']), 'rb').read()
    return _romcache[game]


class Bank:
    pass


def trace(d, base, starts):
    seen = {}
    labels = set(starts)
    todo = list(starts)
    while todo:
        a = todo.pop()
        while 0x4000 <= a < 0x8000 and a not in seen:
            n, t, info = disasm(d, base + a - 0x4000, a)
            seen[a] = (n, t, info)
            tg = info['target']
            if tg is not None and info['kind'] in ('jp', 'jr', 'call') and 0x4000 <= tg < 0x8000:
                labels.add(tg)
                todo.append(tg)
            if info['kind'] in ('ret', 'reti', 'jphl') and not info['cond']:
                break
            if info['kind'] in ('jp', 'jr') and not info['cond']:
                break
            a += n
    return seen, labels


def rd16(d, base, a):
    return d[base + a - 0x4000] | (d[base + a - 0x4000 + 1] << 8)


def analyze(game, bank):
    g = GAMES[game]
    d = rom(game)
    base = bank * 0x4000
    B = Bank()
    B.game, B.bank, B.base, B.rom = game, bank, base, d
    B.is_sfx = (bank == g['sfx'])
    B.ver = g['ver']
    B.ram = g['ram'] << 8
    B.init = rd16(d, base, 0x4001)
    B.update = rd16(d, base, 0x4004)
    B.byte = lambda a: d[base + a - 0x4000]
    seen, labels = trace(d, base, [B.init, B.update])
    B.code = seen
    B.code_labels = labels
    B.code_lo = min(seen)
    B.code_hi = max(a + seen[a][0] for a in seen)
    # ---- table references
    order = sorted(seen)
    B.tables = {}  # role -> (addr_operand, entry size)
    hl_refs = []
    for i, a in enumerate(order):
        t = seen[a][1]
        m = re.match(r'ld hl,\$([0-9A-F]{4})$', t)
        if not m:
            continue
        x = int(m.group(1), 16)
        if not (0x4000 <= x < 0x8000):
            continue
        hl_refs.append(a)
        nxt = [seen[order[j]][1] for j in range(i + 1, min(i + 30, len(order)))]
        if x == 0x4006:
            B.tables['songs'] = x
            continue
        if nxt[0] == 'ld e,a' and nxt[1] == 'ld d,$00':
            B.tables['freq'] = x
            continue
        if nxt[0] == 'ld d,a' and nxt[1].startswith('ld e,$'):
            size = int(nxt[1][6:], 16)
            role = None
            for t2 in nxt[2:]:
                for reg, r in (('$FF10', 'inst1'), ('$FF16', 'inst2'), ('$FF30', 'wave'), ('$FF21', 'noise')):
                    if t2.startswith('ldh [%s]' % reg):
                        role = r
                        break
                if role:
                    break
            if role is None:
                raise ValueError('unknown table at %04X' % a)
            if role in B.tables and B.tables[role] != (x, size):
                raise ValueError('conflict %s' % role)
            B.tables[role] = (x, size)
            continue
        if x == B.tables.get('freq'):
            continue  # noise handler loads the freq table pointer and never uses it
        raise ValueError('unclassified ld hl at %04X: %s' % (a, t))
    B.hl_refs = hl_refs
    B.freq_start = B.tables['freq'] + 2
    # ---- song table: entries indexed by id until the first data/table address
    tbl_end = min([B.tables[r][0] for r in ('inst1', 'inst2', 'wave', 'noise')] +
                  [B.freq_start, B.code_lo])
    n = (tbl_end - 0x4006) // 2
    B.song_tbl = [rd16(d, base, 0x4006 + 2 * i) for i in range(n)]
    B.song_tbl_end = 0x4006 + 2 * n
    # ---- song headers
    B.songs = {}
    for i, h in enumerate(B.song_tbl):
        if h == 0:
            continue
        if h not in B.songs:
            offs = [rd16(d, base, h + 2 * k) for k in range(5)]
            B.songs[h] = dict(ids=[], offs=offs, ptrs=[(h + o) & 0xFFFF for o in offs])
        B.songs[h]['ids'].append(i)
    # ---- tracks
    B.tracks = {}  # addr -> dict(ch, rows, end, song)
    for h, s in sorted(B.songs.items()):
        for ch in range(4):
            p = s['ptrs'][ch]
            if p in B.tracks:
                B.tracks[p]['songs'].append(h)
                continue
            rows, end = parse_track(B, p, ch)
            B.tracks[p] = dict(ch=ch, rows=rows, end=end, songs=[h])
    return B


def track_cmd_set(ch):
    # commands recognised by the driver on each channel (others = note rows)
    if ch == 3:
        return {0xFF, 0xE0, 0xF1, 0xF0}
    return {0xFF, 0xE0, 0xF1, 0xF2, 0xF0}


def parse_track(B, p, ch, limit=0x8000):
    """returns (rows, end_addr). Each row: (addr, bytes, kind, args)."""
    rows = []
    a = p
    cmds = track_cmd_set(ch)
    while a < limit:
        c = B.byte(a)
        if c in cmds:
            if c == 0xFF:
                x = B.byte(a + 1)
                rows.append((a, 2, 'ctl', x))
                a += 2
                if x == 0xFF:
                    return rows, a
                continue
            if c == 0xE0:
                rows.append((a, 2, 'rest', B.byte(a + 1)))
                a += 2
                continue
            if c in (0xF0, 0xF1):
                rows.append((a, 2, 'inst' if c == 0xF0 else 'pan', B.byte(a + 1)))
                a += 2
                continue
            if c == 0xF2:
                mode = B.byte(a + 1)
                if mode == 0:
                    rows.append((a, 2, 'mod', (0, 0, 0, [])))
                    a += 2
                    continue
                delay = B.byte(a + 2)
                cnt = B.byte(a + 3)
                vals = [B.byte(a + 4 + k) for k in range(cnt if cnt else 256)]
                ln = 4 + len(vals)
                rows.append((a, ln, 'mod', (mode, delay, cnt, vals)))
                a += ln
                continue
        rows.append((a, 3, 'note', (c, B.byte(a + 1), B.byte(a + 2))))
        a += 3
    raise ValueError('track overran')


if __name__ == '__main__':
    game = sys.argv[1]
    for bank in [GAMES[game]['sfx']] + GAMES[game]['music']:
        B = analyze(game, bank)
        print('%s %02X %s init %04X upd %04X code %04X-%04X' % (game, bank, 'SFX' if B.is_sfx else 'MUS',
              B.init, B.update, B.code_lo, B.code_hi - 1))
        print('   tables', {k: (('%04X' % v) if isinstance(v, int) else ('%04X/%d' % v)) for k, v in B.tables.items()},
              'songtbl n=%d' % len(B.song_tbl))
        for h, s in sorted(B.songs.items()):
            ends = [B.tracks[s['ptrs'][c]]['end'] for c in range(4)]
            print('   song %04X ids %s ptrs %s ends %s' % (h, s['ids'], ' '.join('%04X' % x for x in s['ptrs']),
                  ' '.join('%04X' % x for x in ends)))
