"""Mole Mania sound bank parser (data model)."""
ARGS={0x00:0,0x01:1,0x02:1,0x03:3,0x04:0,0x05:2,0x06:0,0x07:3,0x08:1,0x09:1,0x0A:0,0x0B:0,0x0C:0,
      0x0D:1,0x0E:1,0x0F:1,0x10:1,0x11:1,0x12:0,0x13:0}
SFXARGS={0xF0:0,0xF1:1,0xF2:1,0xF3:1,0xF4:1,0xF5:1,0xF6:1,0xF7:0,0xF8:0,0xF9:0,0xFA:0,0xFF:0}
class Bank:
    def __init__(s,rom,bank,limit=0x8000):
        s.limit=limit
        s.rom=rom; s.bank=bank
        s.g=lambda a: rom[bank*0x4000+a-0x4000]
        s.w=lambda a: s.g(a)<<8|s.g(a+1)
        s.lw=lambda a: s.g(a)|s.g(a+1)<<8
        s.songtab=s.lw(0x40B8); s.sfxtab=s.lw(0x4107); s.envtab=s.lw(0x466D)
        s.dutytab=s.lw(0x461B); s.wavetab=s.lw(0x4EFC); s.noisetab=s.lw(0x44D4)
        s.lenptrs=0x4F37; s.freq_dmg=0x4FD3; s.freq_sgb=0x5067
        assert s.lw(0x4319)==0x4F37 and s.lw(0x45A6)==0x4FD3 and s.lw(0x45AF)==0x5067
        s.unterminated=set(); s.pat_ends=set(); s.items={}   # addr -> (size, kind, info)
        s.labels={}  # addr -> name
        s.parse()
    def add(s,a,size,kind,info=None):
        if a in s.items:
            assert s.items[a][0]==size and s.items[a][1]==kind,(hex(a),s.items[a],size,kind)
            return False
        s.items[a]=(size,kind,info); return True
    def lab(s,a,name):
        if a not in s.labels: s.labels[a]=name
        return s.labels[a]
    def parse(s):
        g,w=s.g,s.w
        # length tables
        s.lab(s.lenptrs,'LengthTables')
        s.lentabs=[w(s.lenptrs+2*i) for i in range(12)]
        for i in range(12): s.add(s.lenptrs+2*i,2,'ptr',s.lentabs[i])
        for i,t in enumerate(s.lentabs):
            s.lab(t,f'LengthTable{i:02d}'); s.add(t,11,'lentab',i)
        s.lab(s.freq_dmg,'FreqTable_DMG'); s.add(s.freq_dmg,148,'freqtab','DMG')
        s.lab(s.freq_sgb,'FreqTable_SGB'); s.add(s.freq_sgb,148,'freqtab','SGB')
        # songs
        s.nsongs=(s.sfxtab-s.songtab)//2
        s.lab(s.songtab,'SongTable')
        s.songs=[]
        for i in range(s.nsongs):
            p=w(s.songtab+2*i); s.add(s.songtab+2*i,2,'ptr',p); s.songs.append(p)
        s.patchan={}; s.pending=[]
        for i,p in enumerate(s.songs):
            s.lab(p,f'Song{i+1:02d}')
            s.parse_steps(p,i+1)
        # sfx
        s.lab(s.sfxtab,'SfxTable')
        s.sfx=[]
        for i in range(88):
            p=w(s.sfxtab+2*i); s.add(s.sfxtab+2*i,2,'ptr',p); s.sfx.append(p)
        for i,p in enumerate(s.sfx): s.lab(p,f'Sfx{i+1:02d}'); s.parse_sfx(p)
        # sequences
        for tab,name,kind in ((s.envtab,'EnvSeq','envseq'),(s.dutytab,'DutySeq','dutyseq')):
            s.lab(tab,name+'Table'); ptrs=[]; i=0
            while not ptrs or tab+2*i<min(ptrs):
                ptrs.append(w(tab+2*i)); s.add(tab+2*i,2,'ptr',ptrs[-1]); i+=1
            setattr(s,kind+'s',ptrs)
            for j,p in enumerate(ptrs):
                s.lab(p,f'{name}{j:02d}'); s.parse_seq(p,kind)
        s.lab(s.wavetab,'WaveTable'); s.waves=[]; i=0
        while not s.waves or s.wavetab+2*i<min(s.waves):
            s.waves.append(w(s.wavetab+2*i)); s.add(s.wavetab+2*i,2,'ptr',s.waves[-1]); i+=1
        for j,p in enumerate(s.waves): s.lab(p,f'Wave{j:02d}'); s.add(p,16,'wave')
        s.lab(s.noisetab,'NoiseTable'); s.add(s.noisetab,16,'noisetab')
        # patterns last: an unterminated pattern stops at the next known item
        s.starts=set(s.items)|set(s.labels)
        for pp,c in s.pending: s.parse_pat(pp,c)
    def parse_steps(s,p,song):
        g,w=s.g,s.w; a=p
        while True:
            v=w(a)
            if v>>8==0: s.add(a,2,'stepend',v&0xff); break
            s.add(a,2,'step',v); s.lab(v,f'Frame_{v:04X}')
            if s.add(v,8,'frame'):
                for c in range(4):
                    pp=w(v+2*c)
                    if pp: s.lab(pp,f'Pat_{pp:04X}'); s.pending.append((pp,c))
            a+=2
    def parse_pat(s,p,ch):
        g=s.g; a=p
        s.patchan.setdefault(p,ch)
        while True:
            if a>=s.limit or (a!=p and (a in s.starts or a in s.labels)):
                s.unterminated.add(p); s.pat_ends.add(a); break
            b=g(a)
            if b<0x20:
                n=ARGS.get(b,0); s.add(a,1+n,'cmd',ch)
                a+=1+n
                if b==0: break
            else:
                s.add(a,1,'ev',ch); a+=1
    def parse_sfx(s,p):
        g=s.g; s.add(p,1,'sfxchan'); a=p+1
        while True:
            b=g(a)
            if b<0x70: s.add(a,1,'sfxwait'); a+=1; continue
            if b<0xF0: s.add(a,1,'sfxnote'); a+=1; continue
            n=SFXARGS[b]; s.add(a,1+n,'sfxcmd'); a+=1+n
            if b==0xF0: break
    def parse_seq(s,p,kind):
        g=s.g; a=p
        while True:
            s.add(a,2,kind) ; 
            if g(a+1)==0xFF: break
            a+=2
    def parse_pat_orphan(s,a,e):
        g=s.g
        while a<e:
            b=g(a)
            if b<0x20: n=ARGS[b]; s.add(a,1+n,'cmd',0); a+=1+n
            else: s.add(a,1,'ev',0); a+=1
