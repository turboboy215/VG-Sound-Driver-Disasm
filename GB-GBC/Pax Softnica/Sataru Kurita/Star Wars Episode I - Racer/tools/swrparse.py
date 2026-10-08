"""Star Wars Episode I: Racer (GBC) sound bank parser (bank 3)."""
# music: high nibble = command, F-group by low nibble
MUS_F_ARGS={0x0:1,0x3:1,0x4:3,0x5:2}          # F0 env, F3 count, F4 count+addr, F5 addr
SFX_F_ARGS={0x0:1,0x5:2}
class Bank3:
    BANK=3
    SONGTAB=0x575F; NSONGS=11; SFXTAB=0x6C87; NSFX=40
    DRUMTAB=0x5686; NDRUM=5; PENVTAB=0x56B7; NPENV=16
    WAVE=0x718A; FREQ=0x71E2; NFREQ=84; ENGINE_A=0x728A; ENGINE_B=0x749A; NENGINE=264
    LENTABS=[0x719A,0x71A9,0x71B8,0x71C6,0x71D3]
    END=0x76AA
    def __init__(s,rom):
        s.rom=rom
        s.g=lambda a: rom[s.BANK*0x4000+a-0x4000]
        s.lw=lambda a: s.g(a)|s.g(a+1)<<8
        s.items={}; s.labels={}; s.unterminated=set()
        s.parse()
    def add(s,a,size,kind,info=None):
        if a in s.items:
            assert s.items[a][:2]==(size,kind),(hex(a),s.items[a],size,kind)
            return False
        s.items[a]=(size,kind,info); return True
    def lab(s,a,name):
        s.labels.setdefault(a,name); return s.labels[a]
    def parse(s):
        g,lw=s.g,s.lw
        s.lab(s.DRUMTAB,'DrumTable')
        s.drums=[lw(s.DRUMTAB+2*i) for i in range(s.NDRUM)]
        for i,p in enumerate(s.drums):
            s.add(s.DRUMTAB+2*i,2,'ptr',p); s.lab(p,f'Drum{i}'); s.add(p,6,'drum')
        s.lab(s.PENVTAB,'PitchEnvTable')
        s.penvs=[lw(s.PENVTAB+2*i) for i in range(s.NPENV)]
        for i,p in enumerate(s.penvs):
            s.add(s.PENVTAB+2*i,2,'ptr',p)
            s.lab(p,f'PitchEnv{i:02d}'); a=p
            while g(a)!=0xFF: a+=1
            s.add(p,a-p+1,'penv')
        s.lab(s.SONGTAB,'SongTable')
        s.songs=[lw(s.SONGTAB+2*i) for i in range(s.NSONGS)]
        for i,p in enumerate(s.songs):
            s.add(s.SONGTAB+2*i,2,'ptr',p)
            if not p: continue
            s.lab(p,f'Song{i:02d}')
            s.add(p,2,'ptr',lw(p))
            for c in range(4):
                cp=lw(p+2+2*c); s.add(p+2+2*c,2,'ptr',cp)
                s.lab(cp,f'Song{i:02d}_Ch{c+1}'); s.parse_stream(cp,'mus',c)
        s.lab(s.SFXTAB,'SfxTable')
        s.sfx=[lw(s.SFXTAB+2*i) for i in range(s.NSFX)]
        for i,p in enumerate(s.sfx):
            s.add(s.SFXTAB+2*i,2,'ptr',p); s.lab(p,f'Sfx{i+1:02d}')
            s.add(p,4,'sfxhdr'); a=p+4; s.sfxch={}
            for c in range(5):
                if g(a)==0: s.add(a,2,'sfxnone'); a+=2; continue
                s.add(a,4,'sfxch',c); cp=lw(a+2)
                s.lab(cp,f'Sfx{i+1:02d}_{["Ch1","Ch2","Ch3","Ch4","Rumble"][c]}')
                s.parse_stream(cp,'sfx',c); a+=4
        s.lab(s.WAVE,'MusicWave'); s.add(s.WAVE,16,'wave')
        for i,t in enumerate(s.LENTABS):
            s.lab(t,f'LengthTable{i}')
        for i,t in enumerate(s.LENTABS):
            e=s.LENTABS[i+1] if i+1<len(s.LENTABS) else s.FREQ
            s.add(t,e-t,'lentab')
        s.lab(s.FREQ,'FreqTable'); s.add(s.FREQ,2*s.NFREQ,'freq')
        s.lab(s.ENGINE_A,'EngineFreqA'); s.add(s.ENGINE_A,2*s.NENGINE,'engine')
        s.lab(s.ENGINE_B,'EngineFreqB'); s.add(s.ENGINE_B,2*s.NENGINE,'engine')
    def parse_stream(s,p,kind,ch):
        g,lw=s.g,s.lw; todo=[p]
        while todo:
            a=todo.pop()
            while True:
                if a in s.items: break
                b=g(a); hi=b>>4; lo=b&15
                if hi==0xF:
                    n=(MUS_F_ARGS if kind=='mus' else SFX_F_ARGS).get(lo,0)
                    s.add(a,1+n,kind+'cmd',ch)
                    if kind=='mus' and lo==4:
                        t=lw(a+2); s.lab(t,f'L_{t:04X}'); todo.append(t)
                    if lo==5:
                        t=lw(a+1); s.lab(t,f'L_{t:04X}'); todo.append(t); break
                    if (kind=='mus' and lo==6) or (kind=='sfx' and lo==0xF): break
                    a+=1+n; continue
                s.add(a,1,kind+'ev',ch)
                if (kind=='mus' and hi in (0xA,0xE)) or (kind=='sfx' and 0xB<=hi<=0xE):
                    break   # these hang the driver
                a+=1
