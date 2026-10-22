"""FFL3 (SaGa 3) music stream parser. Bank $0F."""
import sys
import os
ROMF=sys.argv[1] if len(sys.argv)>1 and sys.argv[1].endswith('.gb') else os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb')
r=open(ROMF,'rb').read()
B=0x3c000
def rb(a): return r[B+a-0x4000]
def rw(a): return rb(a)|rb(a+1)<<8
LEN=[rb(0x41be+i) for i in range(16)]
NOTE=['C','C#','D','D#','E','F','F#','G','G#','A','A#','B','tie','rest','rest','rest']
CHN=['CH2','CH1','CH3','CH4']
# arg sizes per channel for $F0-$FF (None = hang); index = cmd&15; CH4 uses table for E0-EF too
ARGS=[ # CH2, CH1, CH3, CH4
 [2,2,1,2],[2,2,2,2],[2,2,2,2],[1,1,1,1],[2,2,2,None],[1,1,None,None],[1,1,1,1],[1,None,None,None],
 [None,None,2,None],[2,2,2,2],[1,1,1,1],[3,3,3,3],[1,None,None,None],[None]*4,[7,6,6,None],[0,0,0,0]]
NAMES=['ENV','JUMP','LOOPA','SETA','PITCHFX','DUTY','PAN','TEMPO','WAVE','LOOPB','SETB','IFA','SKIP1','HANG','INIT','END']
NAMES3=dict(ENV='VOLUME')
def songs(n=20):
    return [[rw(0x482f+8*i+2*c) for c in range(4)] for i in range(n)]
def walk(start,ch):
    """Static linear decode from start following nothing; returns list of (addr,kind,bytes,desc). Stops at END/JUMP-to-earlier."""
    pass
def disasm_linear(a,ch,end=None,stop_at_end=True):
    out=[]
    while True:
        if end is not None and a>=end: break
        b=rb(a)
        if b<0xE0 or (ch<3 and b<0xF0):
            if b<0xE0:
                out.append((a,'note',[b],'%s len=%d(%X)'%(NOTE[b>>4],LEN[b&15],b&15))); a+=1; continue
            if b&8: d=[24,48,72,96,-24,-48,-72,-96][b&7]//24; out.append((a,'oct',[b],'octave %+d'%d))
            else: out.append((a,'oct',[b],'octave =%d'%(b&7)))
            a+=1; continue
        c=b&15; n=ARGS[c][ch]
        if n is None:
            out.append((a,'HANG',[b],'*** invalid on %s: driver hangs ***'%CHN[ch])); break
        args=[rb(a+1+i) for i in range(n)]
        nm=NAMES[c]
        if ch==2 and c==0: nm='VOLUME'
        out.append((a,nm,[b]+args,' '.join('%02X'%x for x in args))); a+=1+n
        if c==15 and stop_at_end: break
    return out,a
def play(start,ch,maxticks=200000,maxevents=200000):
    """Execute stream semantics; yield (tick, addr, event). Counters start at 0."""
    a=start; ca=0; cb=0; oct=0; t=0; ev=0
    tempo=None
    while ev<maxevents and t<maxticks:
        ev+=1
        b=rb(a)
        if b<0xE0:
            yield (t,a,'note',b,oct); t+=LEN[b&15]; a+=1; continue
        if ch<3 and b<0xF0:
            if b&8: oct+= [24,48,72,96,-24,-48,-72,-96][b&7]
            else: oct=(b&7)*24
            oct&=0xFF; a+=1; continue
        c=b&15; n=ARGS[c][ch]
        if n is None: yield (t,a,'hang',b,None); return
        if c==1: yield (t,a,'jump',rw(a+1),None); a=rw(a+1); continue
        if c==2:
            ca=(ca-1)&0xFF
            if ca: a=rw(a+1)
            else: a+=3
            continue
        if c==9:
            cb=(cb-1)&0xFF
            if cb: a=rw(a+1)
            else: a+=3
            continue
        if c==3: ca=rb(a+1); a+=2; continue
        if c==10: cb=rb(a+1); a+=2; continue
        if c==11:
            if rb(a+1)==ca: yield (t,a,'ifa_taken',rw(a+2),ca); a=rw(a+2)
            else: a+=4
            continue
        if c==15: yield (t,a,'end',None,None); return
        if c==7: yield (t,a,'tempo',rb(a+1),None)
        if c==14 and ch==0: yield (t,a,'tempo',rb(a+1),None)
        yield (t,a,'cmd',b,None)
        a+=1+n
    yield (t,a,'limit',None,None)
if __name__=='__main__':
    for i,s in enumerate(songs()):
        print('song %2d'%(i+1),' '.join('%04X'%x for x in s))
