"""Per-game statistics for the documentation."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtparse import Data, fill_gaps
from qtcfg import GAMES

def stats(g):
    D = Data(g); D.run(); fill_gaps(D)
    it = D.items
    kinds = {}
    for a, x in it.items():
        k = x.kind.split(':')[0] if not x.kind.startswith('ins') else x.kind
        kinds[k] = kinds.get(k, 0) + 1
    used_pats = set(p for p in D.pat_uses)
    rows = []
    for s in D.songs:
        if s.get('invalid'):
            rows.append((s['n'], None)); continue
        chs = []
        for ch in (1, 2, 3, 4):
            if ch in s['chans']:
                p = s['chans'][ch]
                # count steps until songloop
                n = 0; a = p; loop = None
                while a in it and it[a].kind == 'step':
                    n += 1; a += it[a].size
                chs.append('%d:%d' % (ch, n))
        rows.append((s['n'], dict(tempo=s['tempo'], mask=s['mask'], chs=chs, at=s['at'])))
    unused_ins = [x for x in it.values() if x.kind.startswith('ins') and not x.f.get('used')]
    return D, kinds, rows, used_pats, unused_ins

if __name__ == '__main__':
    for g in (sys.argv[1:] or GAMES):
        D, kinds, rows, used, uins = stats(g)
        print('==', g, 'songs', D.nsongs, 'sfx', D.nsfx, 'patterns', D.npat, 'used by songs', len(used),
              'ins', D.nins, 'noise', D.nins4, 'unused/orphan ins records', len(uins), 'bad ins ptrs', len(D.bad_ins))
        print('  region $%04X-$%04X' % (min(D.owner), D.region_end), 'kinds', kinds)
        for n, r in rows:
            print('  song %02X' % n, r)
        print('  sfx', [(e['n'], e['ch'], e['pri']) for e in D.sfx])
        print('  bad', D.bad_ins)
