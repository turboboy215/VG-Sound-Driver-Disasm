"""Map Dragon Slayer code addresses -> Doraemon code addresses (instruction alignment)."""
import difflib, re, sys
sys.path.insert(0, 'tools')
import sm83
from epoch_cfg import load

def insts(g, s, e):
    out = []; pc = s
    while pc < e:
        l, t, k, tg = sm83.ins(g['data'], pc, g['base'])
        out.append((pc, t)); pc += l
    return out

def code_ranges(g):
    return [(g['start'], g['wave'][0]), (g['wave'][1], g['code_end'])]

def amap():
    ds, do = load('ds'), load('dora')
    A = []; B = []
    for (s, e) in code_ranges(ds): A += insts(ds, s, e)
    for (s, e) in code_ranges(do): B += insts(do, s, e)
    n = lambda t: re.sub(r'\$[0-9A-F]{2,4}', '$X', t)
    sm = difflib.SequenceMatcher(None, [n(x[1]) for x in A], [n(x[1]) for x in B], autojunk=False)
    m = {}
    for tag, i1, i2, j1, j2 in sm.get_opcodes():
        if tag == 'equal' or (tag == 'replace' and i2 - i1 == j2 - j1):
            for k in range(i2 - i1): m[A[i1 + k][0]] = B[j1 + k][0]
    m[ds['wave'][0]] = do['wave'][0]
    return m

if __name__ == '__main__':
    m = amap()
    for a in [0x7038,0x704D,0x706B,0x7089,0x70E0,0x70EF,0x7141,0x7155,0x7167,0x7175,0x7189,0x71AF,0x722A,0x735E,0x736C,0x7380,0x7423,0x74A3,0x74A4,0x74B5,0x75F9]:
        print(f'{a:04X} -> {m.get(a,0):04X}')
