import sys
a=open(sys.argv[1],'rb').read(); b=open(sys.argv[2],'rb').read()
RANGES=[(0x1F27,0x1F45),(0x3C000,0x3C000+0x6BAF-0x4000)]
ok=True
for s,e in RANGES:
    d=[i for i in range(s,e) if a[i]!=b[i]]
    print('%05X-%05X: %s'%(s,e-1,'OK' if not d else '%d diffs, first %05X (%02X vs %02X)'%(len(d),d[0],a[d[0]],b[d[0]])))
    ok&=not d
sys.exit(0 if ok else 1)
