"""Mixed code/data listing using tracer coverage. usage: listing.py rom start end entry...  """
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode, fmt
from codetrace import trace

rom = open(sys.argv[1], 'rb').read()
s, e = int(sys.argv[2], 16), int(sys.argv[3], 16)
ents = [int(x, 16) for x in sys.argv[4:]]
code, xr, _ = trace(rom, ents)
a = s
while a < e:
    if a in code:
        n, t, v, f = decode(rom, a)
        lab = ' <' + ','.join('%04X' % x for x in sorted(xr[a])) if a in xr else ''
        if a in xr:
            print(f'L{a:04X}:{lab}')
        print(f'  {a:04X}: {rom[a:a+n].hex(" "):9s} {fmt(t, v)}')
        a += n
    else:
        b = a
        while b < e and b not in code and b - a < 16:
            b += 1
        print(f'  {a:04X}: .db {rom[a:b].hex(" ")}')
        a = b
