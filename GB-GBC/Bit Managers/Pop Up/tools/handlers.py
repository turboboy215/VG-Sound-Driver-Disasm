"""Print each command handler of a v3 driver. usage: handlers.py rom bank first_cmd count table"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from bank import view
from sm83 import decode, fmt

def body(v, a, maxn=40):
    out = []
    seen = set()
    for _ in range(maxn):
        if a in seen: break
        seen.add(a)
        n, t, val, f = decode(v, a)
        out.append(f'    {a:04X}: {fmt(t, val)}')
        if f and f[0] in ('ret', 'jp', 'jr', 'jphl'):
            break
        a += n
    return out

if __name__ == '__main__':
    path, bank, first, cnt, tab = sys.argv[1], int(sys.argv[2]), int(sys.argv[3], 16), int(sys.argv[4]), int(sys.argv[5], 16)
    v = view(path, bank)
    for i in range(cnt):
        h = v[tab + 2 * i] | (v[tab + 2 * i + 1] << 8)
        print(f'${first + i:02X} -> {h:04X}')
        print('\n'.join(body(v, h)))
