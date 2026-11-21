"""Normalized code diff between two version-4 drivers.
usage: v4diff.py romA bankA jtA tabA cntA romB bankB jtB tabB cntB [end]
(end: last driver address compared, hex; default 4B20. Die Maus-based builds: 4C74)"""
import sys, re, difflib
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from bank import view
from sm83 import decode, fmt
from codetrace import trace

def lst(path, bank, jt, tab, cnt, extra=()):
    v = view(path, bank)
    ents = list(extra)
    a = jt
    while v[a] == 0xC3:
        ents.append(v[a+1] | v[a+2] << 8); a += 3
    ents += [v[tab+2*i] | v[tab+2*i+1] << 8 for i in range(cnt)]
    code, xr, _ = trace(v, ents)
    out = []
    for a in sorted(code):
        if 0x4000 <= a < END:
            n, t, val, f = decode(v, a)
            txt = fmt(t, val)
            out.append((a, txt, re.sub(r'\$[0-9A-F]{4}', 'W', txt)))
    return out

END = int(sys.argv[11], 16) if len(sys.argv) > 11 else 0x4B20
A = lst(sys.argv[1], int(sys.argv[2]), int(sys.argv[3], 16), int(sys.argv[4], 16), int(sys.argv[5]))
B = lst(sys.argv[6], int(sys.argv[7]), int(sys.argv[8], 16), int(sys.argv[9], 16), int(sys.argv[10]))
sm = difflib.SequenceMatcher(None, [x[2] for x in A], [x[2] for x in B], autojunk=False)
for op, i1, i2, j1, j2 in sm.get_opcodes():
    if op == 'equal':
        continue
    print('%s A %s / B %s' % (op, '%04X' % A[i1][0] if i1 < len(A) else '-', '%04X' % B[j1][0] if j1 < len(B) else '-'))
    for x in A[i1:i2]: print('   - %04X %s' % (x[0], x[1]))
    for x in B[j1:j2]: print('   + %04X %s' % (x[0], x[1]))
