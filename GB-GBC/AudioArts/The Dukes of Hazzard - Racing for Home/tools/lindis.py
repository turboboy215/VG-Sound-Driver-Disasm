import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode
def dis(mem, start, end, base=0):
    pc=start
    while pc<end:
        n,m,o=decode(mem,pc)
        bs=' '.join('%02X'%mem[pc+i] for i in range(n))
        if m is None: s='db $%02X'%mem[pc]
        else:
            if o:
                k,v=o
                s=m.format('$%04X'%v if k in('imm16','addr16','rel','ldh') else '$%02X'%v)
            else: s=m
        print('%05X %04X  %-10s %s'%(pc+base,pc if pc<0x4000 else (pc&0x3fff)|0x4000,bs,s))
        pc+=n
if __name__=='__main__':
    f=sys.argv[1]; a=int(sys.argv[2],16); b=int(sys.argv[3],16)
    d=open(f,'rb').read()
    dis(d,a,b)
