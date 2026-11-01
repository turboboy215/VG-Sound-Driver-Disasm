# Kid Niki (J) sound driver model: transliteration of bank 1 $7A00-$7EB7
class KNModel:
    def __init__(s,rom):
        s.rom=rom              # bytes of the ROM
        s.ram={}               # addr -> byte (C800-C8FF)
        s.io=[]                # (addr, val) register writes in order
    def rd(s,a):
        if a<0x4000: return s.rom[a]
        if a<0x8000: return s.rom[0x4000+a-0x4000]   # bank 1
        if 0xff30<=a<0xff40: return s.ram.get(a,0)
        return s.ram[a]
    def wr(s,a,v):
        v&=0xff
        if a>=0xff00: s.io.append((a,v)); return
        s.ram[a]=v
    # ---- request loader $7A9F
    def load_req(s,req,base):
        a=s.rd(req)
        if a==0 or a==0xff: return
        s.wr(req,0xff)
        l=(a<<3)&0xff; tab=0x7d00|l
        c=base&0xff
        for k in range(4):
            s.wr(0xc800|c,1); c+=1
            s.wr(0xc800|c,0); c+=1
            s.wr(0xc800|c,s.rd(tab)); tab+=1; c+=1
            s.wr(0xc800|c,s.rd(tab)); tab+=1; c+=1
            c+=2
            s.wr(0xc800|c,0)
            c=(c+0x0a)&0xff
    # ---- track step $7AD8
    def step(s,t):
        s.wr(0xc890,t)
        T=0xc800|t
        if s.rd(T)==0: return
        cnt=(s.rd(T+1)+1)&0xff; s.wr(T+1,cnt)
        if s.rd(T)!=cnt: return
        s.wr(T+1,0)
        bc=s.rd(T+2)|s.rd(T+3)<<8
        guard=0
        while True:
            guard+=1
            if guard>5000: raise RuntimeError('parse loop at %04x'%bc)
            a=s.rd(bc); bc=(bc+1)&0xffff
            if a<0x80 or a==0x89:
                s.wr(T+0xa,a); s.wr(T+2,bc&0xff); s.wr(T+3,bc>>8); return
            if a>=0x90:
                s.wr(T,a-0x90); continue
            k=a&15
            if k in (0,1,2,3,8):
                off={0:8,1:7,2:0xb,3:9,8:0xc}[k]
                s.wr(T+off,s.rd(bc)); bc+=1
            elif k in (4,0xd): bc+=1
            elif k==5:
                e=s.rd(bc); bc+=1; hi=s.rd(bc); bc+=1
                s.wr(T+4,bc&0xff); s.wr(T+5,bc>>8); bc=hi<<8|e; s.wr(T+6,1)
            elif k==6:
                if s.rd(T+6):
                    s.wr(T+6,0); bc=s.rd(T+4)|s.rd(T+5)<<8
                else:
                    if s.rd(0xc891)==1:
                        for x in (0x40,0x50,0x60,0x70): s.wr(0xc800|x,0)
                        s.wr(0xc81e,0)
                    else:
                        for x in (0x00,0x10,0x20,0x30): s.wr(0xc800|x,0)
                        s.wr(0xc80e,0)
                    return
            elif k==7: s.wr(T,0); return
            elif k==0xa: s.wr(0xc80f,s.rd(bc)); bc+=1
            elif k==0xb: e=s.rd(bc); hi=s.rd(bc+1); bc=hi<<8|e
            elif k==0xc:
                s.wr(0xff1a,0); l=s.rd(bc); bc+=1
                src=0x7e00|l
                for i in range(16): s.wr(0xff30+i,s.rd((src+i)&0xffff))
            elif k==0xe: s.wr(0xff24,s.rd(bc)); bc+=1
            elif k==0xf: s.wr(0xc81f,s.rd(bc)); bc+=1
    # ---- owner test $7A00: returns track base low byte or None
    def owner(s,b):
        T=0xc800|b
        if s.rd(T)!=0:
            if s.rd(T+1)!=0: return None
            if s.rd(T+0xa)==0x89: return None
            return b
        b=(b+0x40)&0xff; T=0xc800|b
        if s.rd(T)==0: return None
        if s.rd(T+1)!=0: return None
        if s.rd(T+0xa)==0x89: return None
        return b
    def period(s,T):
        a=((s.rd(T+0xa)+s.rd(T+0xb))<<1)&0xff
        return s.rd(0x7f00|a), s.rd(0x7f00|((a+1)&0xff))
    def update(s):
        s.load_req(0xc80e,0x00); s.load_req(0xc81e,0x40)
        s.wr(0xc891,0)
        for t in (0,0x10,0x20,0x30): s.step(t)
        s.wr(0xc891,1)
        for t in (0x40,0x50,0x60,0x70): s.step(t)
        # NR51 $7E9B
        a=(s.rd(0xc800)+s.rd(0xc810)+s.rd(0xc820)+s.rd(0xc830))&0xff
        if a: a=s.rd(0xc81f)
        s.wr(0xff25,s.rd(0xc80f)|a)
        # CH1
        b=s.owner(0)
        if b is not None:
            T=0xc800|b
            s.wr(0xff10,s.rd(T+7)); s.wr(0xff11,s.rd(T+8)); s.wr(0xff12,s.rd(T+9))
            lo,hi=s.period(T); s.wr(0xff13,lo); s.wr(0xff14,hi|s.rd(T+0xc)|0x80)
        b=s.owner(0x10)
        if b is not None:
            T=0xc800|b
            s.wr(0xff16,s.rd(T+8)); s.wr(0xff17,s.rd(T+9))
            lo,hi=s.period(T); s.wr(0xff18,lo); s.wr(0xff19,hi|s.rd(T+0xc)|0x80)
        s.wr(0xff1a,0x80)
        b=s.owner(0x20)
        if b is not None:
            T=0xc800|b
            s.wr(0xff1b,s.rd(T+8)); s.wr(0xff1c,s.rd(T+9))
            lo,hi=s.period(T); s.wr(0xff1d,lo); s.wr(0xff1e,hi|0xc0)
        b=s.owner(0x30)
        if b is not None:
            T=0xc800|b
            s.wr(0xff21,s.rd(T+9)); s.wr(0xff22,s.rd(T+0xa)); s.wr(0xff23,0x80)
