"""Align two traced driver code listings by instruction shape to map routine labels."""
import sys, difflib, re
sys.path.insert(0, '.')
from sm83 import decode

def shape(ins):
    t = (ins.mn + ' ' + ins.ops)
    t = re.sub(r'\$[0-9A-F]{4}', 'NN', t)
    return t + (' ->' if ins.kind else '')

def listing(g):
    out = []
    for a in sorted(g.items):
        it = g.items[a]
        if it.kind == 'code':
            out.append((a, shape(it.text)))
    return out

def amap(ga, gb):
    A, B = listing(ga), listing(gb)
    sm = difflib.SequenceMatcher(None, [s for _, s in A], [s for _, s in B], autojunk=False)
    m = {}
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal' or (tag == 'replace' and i2 - i1 == j2 - j1):
            for k in range(i2 - i1):
                m[A[i1 + k][0]] = B[j1 + k][0]
    return m, sm, A, B
