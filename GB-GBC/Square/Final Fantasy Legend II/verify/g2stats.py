"""Per-song tempo, intro and loop length (ticks / seconds) for ffa or ffl2."""
import sys, os; sys.path.insert(0, os.path.dirname(__file__))
import g2
FPS = 4194304 / 70224
def run(g, start, ch):
    a = start; A = 0; B = g.initB; t = 0; seen = {}; tempos = []
    for _ in range(3000000):
        b = g.rb(a)
        if b < 0xD0:
            st = (a, A, B)
            if st in seen: return 'loop', seen[st], t, tempos
            seen[st] = t; t += g.LEN[b >> 4]; a += 1; continue
        if b < 0xE0: a += 1; continue
        if b == 0xFF: return 'end', None, t, tempos
        c = b & 15; n = g.args[c][ch]
        if n is None: return 'crash', None, t, tempos
        if n == g2.H:
            if g.key == 'ffa': return 'hang', None, t, tempos
            a += 1; continue
        if c == 1: a = g.rw(a + 1); continue
        if c in (2, 9):
            if c == 2: A = (A - 1) & 255; z = A
            else: B = (B - 1) & 255; z = B
            a = g.rw(a + 1) if z else a + 3; continue
        if c == 3: A = g.rb(a + 1)
        if c == 10: B = g.rb(a + 1)
        if c == 11: a = g.rw(a + 2) if g.rb(a + 1) == A else a + 4; continue
        if c == 7 and ch == 0: tempos.append((t, g.rb(a + 1)))
        a += 1 + n
    return 'limit', None, t, tempos
if __name__ == '__main__':
    g = g2.Game(sys.argv[1]); g.LEN = [g.rb({'ffa': 0x424A, 'ffl2': 0x4244}[g.key] + i) for i in range(13)]
    for i, s in enumerate(g.songs):
        res = [run(g, s[ch], ch) for ch in range(3)]
        tempos = res[0][3]; T = tempos[0][1] if tempos else None
        parts = []
        for k, lt, t, _ in res:
            parts.append('%d+%d' % (lt, t - lt) if k == 'loop' else '%s@%d' % (k, t))
        loops = [(t - lt, lt) for k, lt, t, _ in res if k == 'loop']
        if loops and T:
            L = max(x[0] for x in loops); I = max(x[1] for x in loops)
            Tl = [v for tt, v in tempos if tt <= I]; Tl = Tl[-1] if Tl else T
            desc = 'loop %.1f s' % (L * 128 / (Tl * FPS))
        elif T:
            tmax = max(t for k, lt, t, _ in res); desc = 'one-shot %.1f s' % (tmax * 128 / (T * FPS))
        else: desc = ''
        print('$%02X tempo %s %s | %s | %s' % (i + 1, '$%02X' % T if T else '-', [('$%02X' % v) for tt, v in tempos[1:4]], ' '.join(parts), desc))
