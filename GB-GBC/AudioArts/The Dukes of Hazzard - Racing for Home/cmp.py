import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from qtcfg import GAMES, load, DIR
g=sys.argv[1]; rom=open(sys.argv[2],'rb').read(); end=int(sys.argv[3],16)
c=GAMES[g]; m,_=load(g)
bank=c['bank'] if c['bank'] is not None else 1
b=rom[bank*0x4000:bank*0x4000+0x4000]
diff=[a for a in range(0x4000,end) if b[a-0x4000]!=m[a]]
print(g,'compare $4000-$%04X:'%(end-1),'OK' if not diff else '%d diffs, first $%04X'%(len(diff),diff[0]))
for a in diff[:10]: print('  $%04X rom %02X built %02X'%(a,m[a],b[a-0x4000]))
if g == 'cmr':
    full = open(DIR + c['file'], 'rb').read()
    for bank, lo, hi in ((0x7D, 0x57AE, 0x7ABC), (0x7E, 0x4000, 0x8000), (0x7F, 0x4000, 0x8000)):
        o = bank * 0x4000 - 0x4000
        d = [a for a in range(lo, hi) if full[o + a] != rom[o + a]]
        print('  PCM bank $%02X $%04X-$%04X:' % (bank, lo, hi - 1), 'OK' if not d else '%d diffs' % len(d))
