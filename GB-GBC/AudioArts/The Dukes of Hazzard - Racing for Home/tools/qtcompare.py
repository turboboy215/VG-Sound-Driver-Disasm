"""Structural comparison of two games' sound data (songs, SFX, instruments)."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtparse import Data, fill_gaps

def load(g):
    D = Data(g); D.run(); fill_gaps(D); return D

def pat_events(D, a):
    ev = []
    while a in D.items:
        it = D.items[a]
        if it.kind == 'note': ev.append(('N', it.f['dur'], it.f['note'], it.f['ins']))
        elif it.kind in ('hold', 'keyoff', 'keyon'): ev.append((it.kind, it.f['dur']))
        else:
            ev.append((it.kind,)); break
        a += it.size
    return ev

def song_flat(D, p):
    out = []; a = p; n = 0
    while a in D.items and D.items[a].kind == 'step' and n < 400:
        st = D.items[a]
        pa = D.w(D.c['tabs']['pattab'] + 2 * st.f['pat'])
        out.append((st.f['tr'], tuple(pat_events(D, pa))))
        a += st.size; n += 1
        if out[-1][1] and out[-1][1][-1][0] == 'songloop':
            break
    return out

def table_vals(D, a, n=64):
    v = []
    for _ in range(n):
        it = D.items.get(a)
        if it is None: break
        if it.kind == 'tend': v.append(('L', D.items.get(it.f['target']) and it.f['target'] - a)); break
        v.append(tuple(D.m[a:a + it.size])); a += it.size
    return tuple(v)

def ins_sig(D, i, noise=False):
    tab = D.c['tabs']['instab4' if noise else 'instab']
    p = D.w(tab + 2 * i)
    it = D.items.get(p)
    if not it or not it.kind.startswith('ins'): return None
    typ = it.kind[4:]
    b = D.m[p:p + it.size]
    w = lambda o: D.w(p + o)
    if typ == 'tone': return (typ, tuple(b[:3]), table_vals(D, (w(3) + 1) & 0xFFFF), table_vals(D, (w(5) + 2) & 0xFFFF), table_vals(D, (w(7) + 1) & 0xFFFF))
    if typ == 'wave': return (typ, table_vals(D, w(0) + 1), table_vals(D, w(2) + 1), table_vals(D, w(4) + 1), table_vals(D, w(6) + 2), table_vals(D, w(8) + 1))
    return (typ, tuple(b[:3]), table_vals(D, w(3) + 1), table_vals(D, w(5) + 1))

if __name__ == '__main__':
    A, B = load(sys.argv[1]), load(sys.argv[2])
    print('songs', A.nsongs, B.nsongs, 'sfx', A.nsfx, B.nsfx, 'pats', A.npat, B.npat, 'ins', A.nins, B.nins, A.nins4, B.nins4)
    for sa, sb in zip(A.songs, B.songs):
        if sa.get('invalid') or sb.get('invalid'): print('song', sa['n'], 'invalid'); continue
        for ch in (1, 2, 3, 4):
            if ch not in sa['chans']: continue
            fa, fb = song_flat(A, sa['chans'][ch]), song_flat(B, sb['chans'].get(ch, 0))
            # compare ignoring instrument numbering
            same = fa == fb
            print('song %d ch%d: steps %d/%d %s' % (sa['n'], ch, len(fa), len(fb), 'identical' if same else 'DIFFERENT'))
            if not same:
                for k, (x, y) in enumerate(zip(fa, fb)):
                    if x != y:
                        print('   first diff at step', k, 'tr', x[0], y[0]); 
                        for e1, e2 in zip(x[1], y[1]):
                            if e1 != e2: print('    ', e1, e2); break
                        break
        print('  tempo', sa['tempo'], sb['tempo'], 'wave same', A.m[sa['wave']:sa['wave']+16] == B.m[sb['wave']:sb['wave']+16] if sa['wave'] and sb['wave'] else None)
    for ea, eb in zip(A.sfx, B.sfx):
        pa, pb = pat_events(A, ea['ptr']), pat_events(B, eb['ptr'])
        if pa != pb or ea['ch'] != eb['ch']: print('sfx %02X differs:' % ea['n'], pa[:4], pb[:4], ea['ch'], eb['ch'])
    nd = 0
    for i in range(min(A.nins, B.nins)):
        if ins_sig(A, i) != ins_sig(B, i): nd += 1; print('ins %02X differs' % i, ins_sig(A, i) and ins_sig(A,i)[:2], ins_sig(B, i) and ins_sig(B,i)[:2])
    for i in range(min(A.nins4, B.nins4)):
        if ins_sig(A, i, True) != ins_sig(B, i, True): print('noise ins %02X differs' % i, ins_sig(A, i, True) and ins_sig(A,i,True)[:2], ins_sig(B, i, True) and ins_sig(B,i,True)[:2])
