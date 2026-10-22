import sys, os; sys.path.insert(0, os.path.dirname(__file__))
from ffl1parse import *
def run(start):
    a = start; cnt = 0; t = 0; seen = {}; vis = set(); tempo = []
    while True:
        b = rb(a); n = size(b)
        if b < 0xE0:
            st = (a, cnt)
            if st in seen: return vis, t, seen[st], 'loop', tempo
            seen[st] = t; vis.add(a)
            if b != 0x0F: t += LEN[b & 15]
            a += 1; continue
        vis.add(a)
        if n is None: return vis, t, None, 'crash', tempo
        c = b & 15
        if b == 0xE0: tempo.append((t, rb(a + 1)))
        if b == 0xFF: return vis, t, None, 'end', tempo
        if b >= 0xF0:
            if 9 <= c <= 11: cnt = c - 8
            elif c == 12:
                if cnt: cnt -= 1; a = rw(a + 1); continue
                a += 3; continue
            elif c == 13:
                if cnt == 0: a = rw(a + 1); continue
                a += 3; continue
            elif c == 14: a = rw(a + 1); continue
        a += n
if __name__ == '__main__':
    FPS = 4194304 / 70224
    for i, s in enumerate(songs()):
        parts = []; T = None; tl = []
        for ch in range(3):
            v, t, lt, k, tempo = run(s[ch])
            sc = static_cover(s[ch])
            miss = [x for x in sc if sc[x] == 1 and rb(x) < 0xE0 and x not in v]
            if tempo: tl = tempo
            parts.append(('%d+%d' % (lt, t - lt) if k == 'loop' else '%s@%d' % (k, t)) + (' miss%d' % len(miss) if miss else ''))
        print('%2d' % i, ' | '.join(parts), 'tempo', tl[:6])
