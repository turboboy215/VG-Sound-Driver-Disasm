"""Normalized code listing for v3 drivers (for cross-game diffing)."""
import sys, re
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from bank import view
from sm83 import decode, fmt
from codetrace import trace

def listing(v, ents, s, e):
    code, xr, jp = trace(v, ents)
    out = []
    for a in sorted(code):
        if s <= a < e:
            n, t, val, f = decode(v, a)
            out.append((a, fmt(t, val), a in xr))
    return out, code

def norm(txt, pages):
    t = re.sub(r'\$[0-9A-F]{4}', 'W', txt)
    for i, p in enumerate(pages):
        t = t.replace('$%02X' % p, 'PG%d' % i)
    t = t.replace('ldh [$FF9', 'ld [W').replace('ldh [$FFA', 'ld [W').replace('ldh [$FFB', 'ld [W')
    t = re.sub(r'ld \[W.\]', 'ld [W]', t)
    t = re.sub(r'ldh a, \[\$FF[9AB].\]', 'ld a, [W]', t)
    return t
