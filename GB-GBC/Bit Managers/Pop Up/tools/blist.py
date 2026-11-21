"""Banked mixed listing. usage: blist.py rom bank start end [extra entries...]
Entries: bank-start jump table (jp nnnn run) + command table (given by --tab addr count)."""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from bank import view
from sm83 import decode, fmt
from codetrace import trace

def jt_entries(v, a=0x4000):
    out=[]
    while v[a]==0xC3:
        out.append(v[a+1]|v[a+2]<<8); a+=3
    return out, a

def run(path, bank, s, e, ents, tab=None):
    v=view(path,bank)
    j,_=jt_entries(v)
    ents=list(ents)+j
    if tab:
        ta,cnt=tab
        ents+=[v[ta+2*i]|v[ta+2*i+1]<<8 for i in range(cnt)]
    code,xr,jp=trace(v,ents)
    a=s
    while a<e:
        if a in code:
            n,t,val,f=decode(v,a)
            if a in xr: print(f'L{a:04X}: <'+','.join('%04X'%x for x in sorted(xr[a])))
            print(f'  {a:04X}: {v[a:a+n].hex(" "):9s} {fmt(t,val)}')
            a+=n
        else:
            b=a
            while b<e and b not in code and b-a<16: b+=1
            print(f'  {a:04X}: .db {v[a:b].hex(" ")}')
            a=b
    return code
if __name__=='__main__':
    p,b,s,e=sys.argv[1],int(sys.argv[2]),int(sys.argv[3],16),int(sys.argv[4],16)
    tab=None; ex=[]
    for x in sys.argv[5:]:
        if x.startswith('tab='):
            ta,c=x[4:].split(','); tab=(int(ta,16),int(c))
        else: ex.append(int(x,16))
    run(p,b,s,e,ex,tab)
