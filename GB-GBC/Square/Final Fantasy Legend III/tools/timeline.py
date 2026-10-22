import sys; sys.path.insert(0,'tools')
from ffl3parse import *
FPS=4194304/70224
def seconds_ticks(song,maxt=40000):
    """Return list of (tick, event) for CH2 including tempo changes; compute frame time for each tick."""
    s=songs()[song-1]
    # initial tempo from INIT on CH2 if first command is INIT
    ev=list(play(s[0],0,maxticks=maxt))
    tempos=[(t,v) for t,a,k,v,_ in ev if k=='tempo']
    end=[t for t,a,k,v,_ in ev if k in('end','limit')][-1]
    return tempos,end,ev
def tick_to_time(tempos,T):
    # simulate frames: divider starts $FF, tempo from start; each carry => 2 ticks
    div=0xFF; tempo=0x3C; ticks=0; frame=0; ti=0; times={}
    # tempo command at tick t applies when the stream reaches it (at tick t processing)
    while ticks<T:
        frame+=1
        div+=tempo
        if div>255:
            div-=256
            for _ in range(2):
                while ti<len(tempos) and tempos[ti][0]<=ticks: tempo=tempos[ti][1]; ti+=1
                ticks+=1
    return frame/FPS
if __name__=='__main__':
    n=int(sys.argv[1])
    tempos,end,ev=seconds_ticks(n)
    print('tempos',tempos[:30],'end tick',end)
    for t,a,k,v,_ in ev:
        if a in [int(x,16) for x in sys.argv[2:]]: print('reach %04X at tick %d = %.1f s'%(a,t,tick_to_time(tempos,t)))
    print('total %.1f s'%tick_to_time(tempos,end))
