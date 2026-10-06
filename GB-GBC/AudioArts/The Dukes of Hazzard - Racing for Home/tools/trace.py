import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode, flow
def trace(mem, entries, lo, hi, off=0):
    """mem indexed by file offset; addresses are CPU addresses; off = fileoffset - cpuaddr"""
    code=set(); labels=set(entries); todo=list(entries)
    while todo:
        a=todo.pop()
        while lo<=a<hi and a not in code:
            n,t,ft=flow(mem,a+off)
            for i in range(n): code.add(a+i)
            for x in t:
                labels.add(x)
                if lo<=x<hi: todo.append(x)
            if not ft: break
            a+=n
    return code,labels
def listing(mem, code, labels, lo, hi, off=0, compact=True):
    out=[]; a=lo
    while a<hi:
        if a in code:
            n,m,o=decode(mem,a+off)
            if a in labels: out.append('L%04X:'%a)
            if o:
                k,v=o; s=m.format(('L%04X'%v if v in labels else '$%04X'%v) if k in('rel','addr16','imm16','ldh') else '$%02X'%v)
            else: s=m
            out.append('    '+s); a+=n
        else:
            b=a
            while a<hi and a not in code: a+=1
            out.append('    ; data $%04X-$%04X (%d bytes)'%(b,a-1,a-b))
    return out
if __name__=='__main__':
    f=sys.argv[1]; off=int(sys.argv[2],16); lo=int(sys.argv[3],16); hi=int(sys.argv[4],16)
    ents=[int(x,16) for x in sys.argv[5:]]
    mem=open(f,'rb').read()
    c,l=trace(mem,ents,lo,hi,off)
    print('\n'.join(listing(mem,c,l,lo,hi,off)))
