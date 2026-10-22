import sys; sys.path.insert(0,'tools')
from ffl3parse import rb,rw
NSFX=65
def sfx_cover(a,noise):
    seen=set(); todo=[a]
    while todo:
        a=todo.pop()
        while a not in seen:
            d=rb(a); seen.add(a)
            if d==0: break
            if d==0xEF:
                seen|={a+1,a+2}; todo.append(rw(a+1)); a+=3; continue
            if d>=0xF0: a+=1; continue
            n=2 if noise else 5
            for i in range(n): seen.add(a+1+i)
            a+=1+n
    return seen
if __name__=='__main__':
    allc=set()
    for i in range(NSFX):
        t=rw(0x66F2+2*i); n=rw(0x6774+2*i)
        st=sfx_cover(t,0) if t else set(); sn=sfx_cover(n,1) if n else set()
        allc|=st|sn
        print('sfx %2d tone %04X (%d) noise %04X (%d)'%(i+1,t,len(st),n,len(sn)))
    print('sfx data %04X-%04X'%(min(allc),max(allc)))
    a=min(allc)
    gaps=[x for x in range(min(allc),max(allc)) if x not in allc]
    print('gaps',len(gaps), ['%04X'%g for g in gaps[:40]])
