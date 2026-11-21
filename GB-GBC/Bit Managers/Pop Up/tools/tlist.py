"""Traced banked listing: tlist.py rom bank start end [extra entries hex...]
Entries: API jump table at $404A + 37-entry command table at $4000, plus extras."""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from bank import view
from sm83 import decode, fmt
from codetrace import trace
v = view(sys.argv[1], int(sys.argv[2])); s, e = int(sys.argv[3], 16), int(sys.argv[4], 16)
w = lambda a: v[a] | v[a+1] << 8
ents = [int(x, 16) for x in sys.argv[5:]]
a = 0x404A
while v[a] == 0xC3: ents.append(w(a+1)); a += 3
ents += [w(0x4000 + 2*i) for i in range(37)]
code, _, _ = trace(v, ents)
a = s
while a < e:
    if a in code:
        n, t, val, f = decode(v, a)
        print('%04X  %-12s %s' % (a, v[a:a+n].hex(), fmt(t, val))); a += n
    else:
        print('%04X  .db %02X' % (a, v[a])); a += 1
