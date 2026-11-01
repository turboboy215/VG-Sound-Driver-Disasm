# Per-track intro/loop lengths (in driver updates = VBlanks) for the Irem GB drivers.
# usage: python3 iremlen.py <kn|hh> [-v]
import sys; sys.path.insert(0,__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.dirname(__import__('os').path.abspath(__file__))),'tools'))
from iremdata import Walker,CFG
def track_len(w,start,kn):
    sb=w.c['speedbase']; args=w.c['args']
    ptr=start; stack=[]; speed=1; t=0; seen={}
    row_start=True
    while True:
        key=(ptr,tuple(stack),speed)
        if key in seen: return ('loop',seen[key],t-seen[key])
        seen[key]=t
        while True:
            x=w.b(ptr); ptr+=1
            if x<0x80 or x==0x89: t+=speed; break
            if x>=sb: speed=x-sb; continue
            if x==0x85:
                tgt=w.b(ptr)|w.b(ptr+1)<<8; ptr+=2
                if kn: stack=[ptr]      # one level: a nested call overwrites the return
                else: stack.append(ptr)
                ptr=tgt; continue
            if x==0x86:
                if stack: ptr=stack.pop(); continue
                return ('endset' if kn else 'end',t)
            if x==0x87: return ('stop',t)
            if x==0x8b: ptr=w.b(ptr)|w.b(ptr+1)<<8; continue
            ptr+=args[x]
def fmt(r):
    if r[0]=='loop': return 'intro %d + loop %d'%(r[1],r[2])
    return '%s at %d'%(r[0],r[1])
if __name__=='__main__':
    g=sys.argv[1]; w=Walker(g).run(); kn=(g=='kn')
    for i,ps in enumerate(w.idtab):
        rs=[track_len(w,p,kn) for p in ps]
        if kn:
            ends=[r[1] for r in rs if r[0]=='endset']
            if ends:   # the first $86 ends all four tracks
                m=min(ends); rs=[('endset',m) if (r[0]!='stop' or r[1]>m) else r for r in rs]
        print('id $%02X: '%i+' | '.join('ch%d %s'%(k+1,fmt(r)) for k,r in enumerate(rs)))
