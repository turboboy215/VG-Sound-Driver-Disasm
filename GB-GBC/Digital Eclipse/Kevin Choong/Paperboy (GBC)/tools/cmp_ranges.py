import sys
A=open(sys.argv[1],'rb').read(); B=open(sys.argv[2],'rb').read()
R=[(0,0x50,0x55),(0,0x3095,0x3554),(0x3B,0x4000,0x5AB6),(0x3C,0x4000,0x5546),(0x3D,0x4000,0x6569),(0x3E,0x4000,0x6698)]
ok=True
for b,s,e in R:
    o=lambda a: a if a<0x4000 else b*0x4000+a-0x4000
    d=[a for a in range(s,e) if A[o(a)]!=B[o(a)]]
    ok&=not d
    print(f'{b:02X}:{s:04X}-{e-1:04X}', 'OK' if not d else f'{len(d)} diffs, first {d[0]:04X}')
print('BYTE-EXACT' if ok else 'MISMATCH')
