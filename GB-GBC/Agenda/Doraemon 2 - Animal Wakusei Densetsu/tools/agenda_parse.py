import os
# Data walker for the Agenda sound driver
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from agenda_cfg import load
# command arg byte counts ($A0-$B7)
ARGS={0xA0:0,0xA1:0,0xA2:0,0xA3:0,0xA4:0,0xA5:1,0xA6:1,0xA7:1,0xA8:2,0xA9:1,0xAA:1,0xAB:2,
      0xAC:3,0xAD:2,0xAE:3,0xAF:1,0xB0:1,0xB1:1,0xB2:1,0xB3:2,0xB4:1,0xB5:0,0xB6:1,0xB7:4}
class Walker:
    def __init__(s,g):
        s.c=load(g); s.b=s.c['b']; s.w=s.c['w']
        s.region={}   # addr -> (kind, length, info)
        s.labels={}   # addr -> name
        s.tracks={}   # start addr -> (owner, channel)
        s.rows={}     # addr -> (len, kind, data)
        s.kits={}     # kit addr -> set of indexes
        s.notes_by_kit={}
        s.errors=[]
    def mark(s,a,n,kind,info=None):
        for k in range(n):
            if a+k in s.region and s.region[a+k][0]!=kind:
                s.errors.append('overlap %04X %s/%s'%(a+k,s.region[a+k][0],kind))
            s.region[a+k]=(kind,a,info)
    def pairs(s,a,kind):
        # (value,duration) pairs until duration $FE/$FF
        start=a
        while True:
            d=s.b(a+1); a+=2
            if d>=0xFE: break
        s.mark(start,a-start,kind)
        return a
    def track(s,a,ch,owner):
        if (a,ch) in s.tracks: return
        s.tracks[(a,ch)]=owner
        rest=s.c['rest']
        while True:
            if a in s.rows: return  # already walked
            if a>=s.c['end']: return
            op=s.b(a)
            if op<0x80:
                n=1
                if 0x80<=s.b(a+1)<0xA0: n=2
                s.rows[a]=(n,'note',ch)
                if ch==3 and op!=rest and s.kit is not None:
                    s.kits.setdefault(s.kit,set()).add((op-0x0A)&7)
                s.mark(a,n,'track'); a+=n; continue
            if op<0xA0 or op>0xB7:
                s.errors.append('bad op %02X at %04X'%(op,a)); s.rows[a]=(1,'bad',ch); s.mark(a,1,'track'); a+=1; continue
            n=1+ARGS[op]
            s.rows[a]=(n,'cmd',ch); s.mark(a,n,'track')
            if op==0xA8: s.pairs(s.w(a+1),'env')
            elif op in (0xAB,0xAD):
                p=s.w(a+1)
                if ch==0: s.pairs(p,'sweep')
                elif ch==3: s.kit=p; s.kits.setdefault(p,set())
                else: s.errors.append('AB on ch%d at %04X'%(ch,a))
            elif op==0xAE:
                p=s.w(a+2); s.mark(p,4,"waveptr"); s.mark(s.w(p),16,'wave')
            elif op==0xAC:
                s.track(s.w(a+2),ch,owner)
            elif op==0xB3:
                s.track(s.w(a+1),ch,owner); return
            if op in (0xA0,0xB5): return
            if op==0xA9 and s.b(a+1)==0xFF: return   # 255-pass loop: treated as endless
            a+=n
    def run(s):
        c=s.c; w=s.w; b=s.b
        s.kit=None
        for i in range(c['music_n']):
            for ch in range(4):
                s.kit=None
                s.track(w(c['music_tab']+8*i+2*ch),ch,('M',i))
        for i in range(c['sfx_n']):
            h=w(c['sfx_tab']+2*i)
            s.mark(h,2,'sfxhdr')
            s.kit=None
            s.track(h+2,b(h),('S',i))
        for ch in range(4): s.track(w(c['silent_tab']+2*ch),ch,('Silent',))
        # kits: entries are (seq ptr, env ptr)
        for k,idx in s.kits.items():
            for i in range(8):
                s.mark(k+4*i,4,'kit')
                s.pairs(w(k+4*i),'noiseseq'); s.pairs(w(k+4*i+2),'env')
        return s
if __name__=='__main__':
    s=Walker(sys.argv[1]).run(); c=s.c
    print('errors',s.errors[:20],len(s.errors))
    print('kits',{hex(k):sorted(v) for k,v in s.kits.items()})
    # gaps
    a=c['music_tab']; gaps=[]
    while a<c['end']:
        if a not in s.region:
            g=a
            while a<c['end'] and a not in s.region: a+=1
            gaps.append((g,a))
        else: a+=1
    for g,e in gaps: print('gap %04X-%04X'%(g,e), bytes(c['b'](x) for x in range(g,min(e,g+24))).hex())

def fill_gaps(s):
    """classify bytes no reference reaches"""
    c=s.c; b=s.b; w=s.w
    # explicit seeds: unreferenced songs / sfx
    for kind,arg in c.get('extra',[]):
        if kind=='song':
            for ch,a in enumerate(arg): s.kit=None; s.track(a,ch,('U',arg[0]))
        elif kind=='sfx':
            s.mark(arg,2,'sfxhdr'); s.kit=None; s.track(arg+2,b(arg),('US',arg))
    for k in list(s.kits):
        for i in range(8):
            s.mark(k+4*i,4,'kit'); s.pairs(w(k+4*i),'noiseseq'); s.pairs(w(k+4*i+2),'env')
    s.mark(c['music_tab'],8*c['music_n'],'musictab')
    s.mark(c['sfx_tab'],2*c['sfx_n'],'sfxtab')
    first_track=min(a for (a,ch) in s.tracks if a>c['music_tab'])
    def next_gap():
        a=c['music_tab']
        while a<c['end']:
            if a not in s.region:
                g=a
                while a<c['end'] and a not in s.region: a+=1
                return g,a
            a+=1
        return None
    while True:
        r=next_gap()
        if not r: break
        x,e=r
        if x>=first_track:
            if e-x==1 and b(x)==0xA0: s.mark(x,1,'deadend')
            else: s.mark(x,e-x,'raw')
            continue
        if x+4<=e and w(x+2)==0x0001 and 0x4000<=w(x)<c['end']:
            s.mark(x,4,'waveptr')
            if w(x) not in s.region: s.mark(w(x),16,'wave')
            continue
        y=x; ok=False
        while y+2<=e:
            y+=2
            if b(y-1)>=0xFE: ok=True; break
        if ok: s.mark(x,y-x,'pairs'); continue
        # head of a list whose tail is referenced separately
        nxt=s.region.get(e)
        if (e-x)%2==0 and nxt and nxt[0] in ('env','sweep','noiseseq','pairs') and all(b(x+k+1)<0xFE for k in range(0,e-x,2)):
            s.mark(x,e-x,'pairs'); continue
        s.mark(x,e-x,'raw')
    return s
