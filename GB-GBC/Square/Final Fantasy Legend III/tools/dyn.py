import sys; sys.path.insert(0,'tools')
from ffl3parse import *
from cover import static_cover
def run(start,ch,limit=2000000):
    """Exact-ish model: returns visited addrs, first-loop info."""
    a=start; ca=0; cb=0; oct=0; t=0; states={}; visited=set(); evs=0
    while True:
        b=rb(a)
        if b<0xE0:
            st=(a,ca,cb,oct)
            if st in states: return visited,t,states[st],'loop',a
            states[st]=t; visited.add(a); t+=LEN[b&15]; a+=1; continue
        visited.add(a)
        if ch<3 and b<0xF0:
            oct=(oct+[24,48,72,96,-24,-48,-72,-96][b&7])&0xFF if b&8 else (b&7)*24; a+=1; continue
        c=b&15; n=ARGS[c][ch]
        evs+=1
        if evs>limit: return visited,t,None,'cmdloop',a
        if n is None: return visited,t,None,'hang',a
        if c==1: a=rw(a+1); continue
        if c in(2,9):
            if c==2: ca=(ca-1)&0xFF; z=ca
            else: cb=(cb-1)&0xFF; z=cb
            a=rw(a+1) if z else a+3; continue
        if c==3: ca=rb(a+1)
        if c==10: cb=rb(a+1)
        if c==11:
            a=rw(a+2) if rb(a+1)==ca else a+4; continue
        if c==15: return visited,t,None,'end',a
        a+=1+n
if __name__=='__main__':
    for i,s in enumerate(songs()):
        res=[]
        for ch in range(4):
            v,t,lt,kind,a=run(s[ch],ch)
            sc,_=static_cover(s[ch],ch)
            notes_static={x for x in sc if sc[x]==1 and (rb(x)<0xE0)}
            miss=sorted(x for x in notes_static if x not in v)
            res.append('%s:%s t=%d loopAt=%s missNotes=%d%s'%(CHN[ch],kind,t,lt,len(miss),(' [%04X..%04X]'%(miss[0],miss[-1]) if miss else '')))
        print('song %2d |'%(i+1),' | '.join(res))
