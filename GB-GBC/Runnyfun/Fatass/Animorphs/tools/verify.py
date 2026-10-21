#!/usr/bin/env python3
"""verify.py ORIGINAL.gbc REBUILT.gbc : compare the driver ranges byte for byte"""
import sys
a=open(sys.argv[1],'rb').read(); b=open(sys.argv[2],'rb').read()
R=[(0,0x05B2,0x062B),(0,0x0649,0x0655)]+[(k,0x4000,0x8000) for k in range(9,0x0F)]+[(0x0F,0x6990,0x8000)]
ok=True
for bank,s,e in R:
    o=bank*0x4000+(s-0x4000 if bank else s); n=e-s
    if b[o:o+n]!=a[o:o+n]:
        ok=False; i=next(i for i in range(n) if a[o+i]!=b[o+i])
        print('MISMATCH %02X:%04X-%04X first at %04X: rom %02X built %02X'%(bank,s,e-1,s+i,a[o+i],b[o+i]))
    else: print('ok %02X:%04X-%04X (%d bytes)'%(bank,s,e-1,n))
print('ALL MATCH' if ok else 'FAILED'); sys.exit(0 if ok else 1)
