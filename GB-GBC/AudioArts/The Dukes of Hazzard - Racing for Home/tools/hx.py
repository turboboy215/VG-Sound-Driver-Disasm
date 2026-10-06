import os
import sys
f=sys.argv[1]; a=int(sys.argv[2],16); n=int(sys.argv[3],16); base=int(sys.argv[4],16) if len(sys.argv)>4 else a
d=open(f,'rb').read()
for i in range(a,a+n,16):
    print('%05X %04X: '%(i,base+i-a)+' '.join('%02X'%b for b in d[i:min(i+16,a+n)]))
