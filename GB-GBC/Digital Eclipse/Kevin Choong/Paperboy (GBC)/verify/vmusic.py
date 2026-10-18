import sys; import os; sys.path.insert(0,os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','tools'))
from pyboy import PyBoy
from pbparse import *
def model(s, nticks):
    """exact model of the ISR music section"""
    st={'ch1':tone_stream(s['ch1'])[0],'ch2':tone_stream(s['ch2'])[0],'ch4':noise_stream(s['ch4'])[0]}
    pos={k:0 for k in st}; cnt={k:1 for k in st}; out=[]
    for t in range(nticks):
        restarted=0; k_i=0; order=['ch1','ch2','ch4']
        while k_i<3:
            k=order[k_i]; cnt[k]=(cnt[k]-1)&255
            if cnt[k]==0:
                e=st[k][pos[k]]
                if e[0]=='end':
                    for kk in st: pos[kk]=0; cnt[kk]=1
                    k_i=0; restarted+=1; continue
                out.append((t,k,e[2])); cnt[k]=e[3]; pos[k]+=1
            k_i+=1
    return out
def capture(n, frames):
    pb=PyBoy(os.environ.get('PB_ROM','pb.gbc'),window='null',sound_emulated=False,cgb=True); pb.set_emulation_speed(0)
    tick=[-1]; stop=[False]; restarts=[]; ev=[]; started=[False]; rf=pb.register_file; m=pb.memory
    def on_song(c):
        if not started[0]:
            rf.A=n; started[0]=True; tick[0]=-1
            pb.memory[0,0x3318]=0xC9  # neuter SoundStop so attract mode can't kill the timer IRQ
        else:
            sp=rf.SP; rf.PC=m[sp]|m[sp+1]<<8; rf.SP=sp+2; restarts.append(tick[0])  # emulate immediate ret
    def on_tick(c):
        if started[0]: tick[0]+=1
    pb.hook_register(0,0x3114,on_song,None)
    pb.hook_register(0,0x31A3,on_tick,None)
    def stopped(): return stop[0]
    pb.hook_register(0,0x31D9,lambda c: started[0] and ev.append((tick[0],'ch1',m[0xD0A6]<<8|m[0xD0A5])),None)
    pb.hook_register(0,0x3215,lambda c: started[0] and ev.append((tick[0],'ch2',m[0xD0A8]<<8|m[0xD0A7])),None)
    pb.hook_register(0,0x3252,lambda c: started[0] and ev.append((tick[0],'ch4',m[rf.HL])),None)
    for f in range(frames):
        pb.tick()
        if tick[0]>=NT: break
    print('  ignored song requests at ticks',restarts[:5])
    pb.stop(); return ev, tick[0]
NT=int(sys.argv[1]) if len(sys.argv)>1 else 2600
ok=True
for n,s in enumerate(songs()):
    ev,nt=capture(n, 1034+NT*2)
    ev=[e for e in ev if e[0]<nt]
    exp=model(s,nt)
    # CH4 hook reads byte at hl (note byte) -- fine
    same = ev==exp
    ok&=same
    print(n, 'ticks',nt,'events',len(ev),'match' if same else 'MISMATCH', '' if same else next(((i,a,b) for i,(a,b) in enumerate(zip(ev,exp)) if a!=b),len(ev)-len(exp)))
print('ALL OK' if ok else 'FAIL')
