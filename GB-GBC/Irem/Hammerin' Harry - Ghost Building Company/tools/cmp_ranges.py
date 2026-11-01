# compare bank:start-end ranges (hex, end inclusive) of two ROMs
import sys
a=open(sys.argv[1],'rb').read(); b=open(sys.argv[2],'rb').read(); bad=0
for r in sys.argv[3:]:
    bk,rg=r.split(':'); lo,hi=(int(x,16) for x in rg.split('-')); bk=int(bk,16)
    off=lambda x: x if x<0x4000 else bk*0x4000+x-0x4000
    for x in range(lo,hi+1):
        if off(x)>=len(a) or a[off(x)]!=b[off(x)]:
            bad+=1
            if bad<10: print('diff %02x:%04x built %s orig %02x'%(bk,x,'%02x'%a[off(x)] if off(x)<len(a) else '--',b[off(x)]))
    print(r,'OK' if not bad else '%d differences'%bad)
sys.exit(1 if bad else 0)
