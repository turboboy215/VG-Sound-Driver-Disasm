"""Walk the Wizard sound data: sound table, headers, tracks, envelope/wave tables."""
import struct, sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from wiz_cfg import GAMES

ARGS = {0x80: 0, 0x81: 1, 0x82: 1, 0x83: 0, 0x84: 1, 0x85: 2, 0x86: 2, 0x87: 0, 0x88: 1, 0x89: 1,
        0x8A: 0, 0x8B: 0, 0x8C: 0, 0x8D: 0, 0x8E: 0, 0x8F: 0, 0x90: 0, 0x91: 0, 0x92: 0, 0x93: 0}


class Game:
    def __init__(self, key, root='.'):
        self.key = key
        self.cfg = c = GAMES[key]
        self.rom = open(f'{root}/{c["rom"]}', 'rb').read()
        self.base = c['bank'] * 0x4000 - 0x4000

    def b4(self, a):
        return self.rom[self.base + a]

    def w4(self, a):
        return self.b4(a) | self.b4(a + 1) << 8

    def b0(self, a):
        return self.rom[a]

    def w0(self, a):
        return self.rom[a] | self.rom[a + 1] << 8

    def sound_table(self):
        t = self.cfg['sndtab']
        ptrs = []
        i = 0
        while True:
            a = t + 2 * i
            if ptrs and a >= min(ptrs):
                break
            ptrs.append(self.w4(a))
            i += 1
        return ptrs

    def header(self, p):
        mask = self.b4(p)
        tracks = []
        q = p + 1
        for bit in range(8):
            if mask >> bit & 1:
                tracks.append((bit, self.w4(q)))
                q += 2
        return mask, tracks, q

    def walk(self, start, rows, refs, sub=False):
        """rows: addr -> (len, kind, args). refs collects (kind, value)."""
        work = [(start, sub)]
        while work:
            pc, insub = work.pop()
            while pc not in rows:
                b = self.b4(pc)
                if b < 0x80:
                    if b == 0x7D:
                        rows[pc] = (3, 'raw', (self.b4(pc + 1), self.b4(pc + 2)))
                        pc += 3
                    else:
                        rows[pc] = (2, 'note', (b, self.b4(pc + 1)))
                        pc += 2
                    continue
                if b not in ARGS:
                    raise ValueError(f'{self.key}: bad command {b:02X} at {pc:04X}')
                n = ARGS[b]
                if n == 2:
                    arg = (self.w4(pc + 1),)
                elif n == 1:
                    arg = (self.b4(pc + 1),)
                else:
                    arg = ()
                rows[pc] = (1 + n, 'cmd', (b,) + arg)
                if b == 0x84: refs.add(('wave', arg[0]))
                if b == 0x88: refs.add(('env', arg[0]))
                if b == 0x89: refs.add(('pitch', arg[0]))
                if b == 0x85:
                    refs.add(('label', arg[0]))
                    work.append((arg[0], insub))
                    break
                if b == 0x86:
                    refs.add(('sub', arg[0]))
                    work.append((arg[0], True))
                if b == 0x80 or b == 0x87:
                    break
                pc += 1 + n
        return rows


def collect(g):
    tab = g.sound_table()
    rows, refs = {}, set()
    headers = {}
    trackstarts = {}
    for i, p in enumerate(tab):
        if p in headers:
            continue
        mask, tracks, end = g.header(p)
        headers[p] = (mask, tracks, end)
        for bit, t in tracks:
            trackstarts.setdefault(t, []).append((i, bit))
            g.walk(t, rows, refs)
    return tab, headers, trackstarts, rows, refs


if __name__ == '__main__':
    for key in sys.argv[1:] or ['dx10', 'quiz']:
        g = Game(key)
        tab, headers, ts, rows, refs = collect(g)
        print(key, 'entries', len(tab), 'headers', len(headers), 'tracks', len(ts), 'rows', len(rows))
        lo = min(headers); hi = max(a + rows[a][0] for a in rows)
        cov = set()
        for p, (m, t, e) in headers.items():
            cov |= set(range(p, e))
        for a, (l, *_) in rows.items():
            cov |= set(range(a, a + l))
        print(' data %04X-%04X' % (lo, hi))
        gaps = []
        s = None
        for a in range(lo, hi):
            if a not in cov:
                s = a if s is None else s
            elif s is not None:
                gaps.append((s, a)); s = None
        print(' gaps', ['%04X-%04X' % x for x in gaps])
        print(' refs', sorted(r for r in refs if r[0] in ('wave', 'env', 'pitch')))
        masks = {}
        for i, p in enumerate(tab):
            masks.setdefault(headers[p][0], []).append(i)
        print(' masks', {'%02X' % k: len(v) for k, v in masks.items()})


def fill_gaps(g, tab, headers, ts, rows, refs, lo, hi):
    """Classify bytes not reached from the sound table: unreferenced headers (+ their tracks)
    and unreachable rows after a jump/end. Returns dict extra_headers, set dead_starts."""
    extra = {}
    dead = set()
    while True:
        cov = set()
        for p, (m, t, e) in list(headers.items()) + list(extra.items()):
            cov |= set(range(p, e))
        for a, (l, *_) in rows.items():
            cov |= set(range(a, a + l))
        gap = next((a for a in range(lo, hi) if a not in cov), None)
        if gap is None:
            return extra, dead
        m, tracks, e = g.header(gap)
        if m and all(e <= t < hi and (t not in cov or t in rows) for _, t in tracks) and e <= hi and not any(x in cov for x in range(gap, e)):
            extra[gap] = (m, tracks, e)
            for bit, t in tracks:
                ts.setdefault(t, []).append((None, bit))
                g.walk(t, rows, refs)
        else:
            dead.add(gap)
            g.walk(gap, rows, refs)
