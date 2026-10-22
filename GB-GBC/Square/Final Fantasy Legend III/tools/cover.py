import sys; sys.path.insert(0,'tools')
from ffl3parse import *
def static_cover(start,ch):
    seen={}; todo=[start]; ptrs=set()
    while todo:
        a=todo.pop()
        while a not in seen:
            b=rb(a)
            if b<0xE0 or (ch<3 and b<0xF0): seen[a]=1; a+=1; continue
            c=b&15; n=ARGS[c][ch]
            if n is None: seen[a]=1; break
            for i in range(1+n): seen[a+i]=1+i
            if c in (4,8) or (c==0 and ch!=2): ptrs.add((c,rw(a+1)))
            if ch==2 and c==14: ptrs.add((4,rw(a+1))); ptrs.add((8,rw(a+4)))
            if ch<2 and c==14:
                o=1 if ch==0 else 0
                ptrs.add((4,rw(a+1+o))); ptrs.add((0,rw(a+3+o)))
            if ch==3 and c==14: pass
            if c==1: a=rw(a+1); continue
            if c in (2,9): todo.append(rw(a+1))
            if c==11: todo.append(rw(a+2))
            if c==15: break
            a+=1+n
    return seen,ptrs
if __name__=='__main__':
    cov={}; allp=set()
    for i,s in enumerate(songs()):
        for ch in range(4):
            sn,p=static_cover(s[ch],ch); allp|=p
            for a in sn: cov.setdefault(a,set()).add((i+1,ch))
    lo=min(cov); hi=max(cov); print('music stream range %04X-%04X'%(lo,hi))
    a=0x48CF; gaps=[]
    while a<0x66F2:
        if a not in cov:
            b=a
            while b<0x66F2 and b not in cov: b+=1
            gaps.append((a,b)); a=b
        else: a+=1
    for g in gaps: print('uncovered %04X-%04X (%d)'%(g[0],g[1]-1,g[1]-g[0]), r[B+g[0]-0x4000:B+min(g[1],g[0]+24)-0x4000].hex())
    print(sorted(set((k,'%04X'%v) for k,v in allp)))
