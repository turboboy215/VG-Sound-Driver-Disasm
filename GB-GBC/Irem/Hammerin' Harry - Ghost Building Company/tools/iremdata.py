# Irem GB sound data walker (Kid Niki / Hammerin' Harry)
import sys
sys.path.insert(0,__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.dirname(__import__('os').path.abspath(__file__))),'tools'))
from sm83 import ROM
CFG={
 'kn':dict(rom='kn.gb',bank=1,table=0x7d00,nids=32,speedbase=0x90,
     args={0x80:1,0x81:1,0x82:1,0x83:1,0x84:1,0x85:2,0x86:0,0x87:0,0x88:1,0x89:0,0x8a:1,0x8b:2,0x8c:1,0x8d:1,0x8e:1,0x8f:1}),
 'hh':dict(rom='hh.gb',bank=1,table=0x4a2b,nids=None,speedbase=0x91,
     args={0x80:1,0x81:1,0x82:1,0x83:1,0x84:1,0x85:2,0x86:0,0x87:0,0x88:1,0x89:0,0x8a:1,0x8b:2,0x8c:1,0x8d:1,0x8e:1,0x8f:1,0x90:1}),
}
CALL,RET,STOP,JUMP,HOLD=0x85,0x86,0x87,0x8b,0x89
class Walker:
    def __init__(s,g):
        s.c=CFG[g]; from paths import ROMS; s.r=ROM(ROMS[g]); s.bank=s.c['bank']
        s.items={}   # addr -> (len, kind)
        s.labels={}  # addr -> set of reasons
        s.chan={}    # addr -> set of channels (1-4)
    def b(s,a): return s.r.b(s.bank,a)
    def walk(s,a,why,ch=0):
        s.labels.setdefault(a,set()).add(why)
        work=[a]; seen=set()
        while work:
            a=work.pop()
            while (a,ch) not in seen:
                seen.add((a,ch)); s.chan.setdefault(a,set()).add(ch)
                if a in s.items:
                    n,k=s.items[a]
                    x=s.b(a)
                    if k=='cmd' and x in (CALL,JUMP):
                        work.append(s.b(a+1)|s.b(a+2)<<8)
                        if x==JUMP: break
                    if k=='cmd' and x in (RET,STOP): break
                    a+=n; continue
                x=s.b(a)
                if x<0x80 or x==HOLD: s.items[a]=(1,'note'); a+=1; continue
                if x>=s.c['speedbase']: s.items[a]=(1,'speed'); a+=1; continue
                n=s.c['args'][x]; s.items[a]=(1+n,'cmd'); 
                if x in (CALL,JUMP):
                    t=s.b(a+1)|s.b(a+2)<<8
                    s.labels.setdefault(t,set()).add('%s from %04x'%('call' if x==CALL else 'jump',a))
                    work.append(t)
                    if x==JUMP: break
                a+=1+n
                if x in (RET,STOP): break
    def ids(s):
        t=s.c['table']; n=s.c['nids']
        if n is None:
            # entries until first pointed stream
            ptrs=[]; i=0
            while True:
                a=t+8*i
                if ptrs and a>=min(ptrs): break
                ptrs+= [s.r.w(s.bank,a+2*k) for k in range(4)]; i+=1
            n=i
        return [[s.r.w(s.bank,t+8*i+2*k) for k in range(4)] for i in range(n)]
    def run(s):
        s.idtab=s.ids()
        for i,ps in enumerate(s.idtab):
            for k,p in enumerate(ps): s.walk(p,'id %02x ch%d'%(i,k+1),k+1)
        return s
if __name__=='__main__':
    w=Walker(sys.argv[1]).run()
    print('ids',len(w.idtab))
    lo=min(w.items); hi=max(a+w.items[a][0] for a in w.items)
    print('range %04x-%04x'%(lo,hi))
    a=lo; 
    cov=sorted(w.items); prev=lo
    for a in cov:
        if a>prev: print('gap %04x-%04x'%(prev,a), bytes(w.b(x) for x in range(prev,min(a,prev+24))).hex())
        prev=max(prev,a+w.items[a][0])
