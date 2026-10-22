import sys, os; sys.path.insert(0, os.path.dirname(__file__))
from ffl1parse import *
n = int(sys.argv[1]); s = songs()[n]
for ch in range(3):
    print('=== song %d %s @%04X' % (n, CHN[ch], s[ch]))
    sc = static_cover(s[ch]); a = s[ch]; hi = max(sc)
    line = []; la = None
    while a <= hi:
        if a not in sc or sc[a] != 1:
            a += 1; continue
        l, k, d = decode(a)
        if k == 'note':
            if not line: la = a
            nm, ln = d.split(' len=')
            line.append('%s%s' % ({'rest': 'r', 'tie': '~'}.get(nm, nm), ln))
        else:
            if line: print('%04X    ' % la, ' '.join(line)); line = []
            print('%04X %-8s %s' % (a, k, d))
        a += l or 1
    if line: print('%04X    ' % la, ' '.join(line))
