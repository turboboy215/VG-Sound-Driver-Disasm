import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtcompare import load, pat_events

def chan_info(D, p):
    a = p; n = 0; ticks = 0
    while n < 2000:
        it = D.items.get(a)
        if it is None or it.kind != 'step':
            return n, ticks, 'falls through at $%04X' % a
        pa = D.w(D.c['tabs']['pattab'] + 2 * it.f['pat'])
        ev = pat_events(D, pa)
        ticks += sum(e[1] if e[0] in ('N', 'hold', 'keyoff', 'keyon') else 0 for e in ev)
        n += 1
        if ev and ev[-1][0] == 'songloop':
            t = D.items[[x for x in D.items if False] or 0] if False else None
            # find the songloop target
            b = pa
            while D.items[b].kind != 'songloop':
                b += D.items[b].size
            tgt = D.items[b].f['target']
            return n, ticks, 'loop to step %d' % ((tgt - p) // D.c['step']) if p <= tgt < a + it.size else 'jump $%04X' % tgt
        a += it.size
    return n, ticks, '?'

if __name__ == '__main__':
    for g in sys.argv[1:]:
        D = load(g)
        print('==', g)
        for s in D.songs:
            if s.get('invalid'):
                print('| `$%02X` | - | not a valid entry |' % s['n']); continue
            parts = []
            for ch in (1, 2, 3, 4):
                if ch in s['chans']:
                    n, t, e = chan_info(D, s['chans'][ch])
                    parts.append('%d: %d steps/%d ticks, %s' % (ch, n, t, e))
            print('| `$%02X` | %s | %s |' % (s['n'], s['tempo'] if s['tempo'] is not None else 7, '; '.join(parts)))
