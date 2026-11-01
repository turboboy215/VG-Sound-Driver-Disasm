# Hammerin' Harry (U) sound driver model: transliteration of bank 1 $4011-$47F1
B1=0x4000
class HHModel:
    def __init__(s,rom):
        s.rom=rom; s.ram={}; s.io=[]
    def rd(s,a):
        if a<0x8000: return s.rom[a] if a<0x4000 else s.rom[a]   # bank 1 = file offset a
        return s.ram.get(a,0) if a>=0xff00 else s.ram[a]
    def wr(s,a,v):
        v&=0xff
        if a>=0xff00: s.io.append((a,v)); s.ram[a]=v; return
        s.ram[a]=v
    def setb(s,a,bit): s.wr(a,s.rd(a)|1<<bit)
    def resb(s,a,bit): s.wr(a,s.rd(a)&~(1<<bit))
    def bit7(s,a): return s.rd(a)&0x80
    # --- $41D5
    def load_req(s,req,base):
        a=s.rd(req)
        if a==0 or a==0xff: return
        s.wr(req,0xff)
        if not base&0x40:
            for x in (0xde5f,0xde6f,0xde7f,0xde8f,0xde9f): s.wr(x,0)
            s.silence_sfx()
        tab=(a*8+0x4a2b)&0xffff; c=base
        for k in range(4):
            s.wr(0xde00|c,1); c+=1
            s.wr(0xde00|c,0); c+=1
            s.wr(0xde00|c,s.rd(tab)); tab+=1; c+=1
            s.wr(0xde00|c,s.rd(tab)); tab+=1; c+=1
            c+=2; s.wr(0xde00|c,0); c=(c+0x0a)&0xff
    def fill47de(s,a):   # $47DE
        for v in (8,0x3f,8): s.wr(a,v); a+=1
        s.fill47e7(a)
    def fill47e7(s,a):
        for v in (0,0,0,0x40,0xc0): s.wr(a,v); a+=1
    def silence_sfx(s):  # $4743
        if s.rd(0xde00):
            s.setb(0xdeb0,0); s.setb(0xdee0,0); s.wr(0xdea0,1); s.wr(0xdec0,1)
            s.fill47de(0xde07)
            s.wr(0xff10,8); s.wr(0xff11,0x3f); s.wr(0xff12,8); s.wr(0xff13,0); s.wr(0xff14,0xc0)
        if s.rd(0xde10):
            s.setb(0xdeb4,0); s.setb(0xdee8,0); s.wr(0xdea4,1); s.wr(0xdec8,1)
            s.fill47de(0xde17)
            s.wr(0xff16,0x3f); s.wr(0xff17,8); s.wr(0xff18,0); s.wr(0xff19,0xc0)
        if s.rd(0xde20):
            s.setb(0xdeb8,0); s.wr(0xdea8,1)
            s.wr(0xde28,0xff); s.wr(0xde29,0); s.fill47e7(0xde2a)
            s.wr(0xff1a,0)
        if s.rd(0xde30):
            s.setb(0xdef8,0); s.wr(0xded8,1)
            s.fill47de(0xde37)
            s.wr(0xff20,0x3f); s.wr(0xff21,8); s.wr(0xff22,0); s.wr(0xff23,0xc0)
    def cleanup(s,t):    # $469B
        k=t>>4
        if k==0:
            s.wr(0xdea0,1); s.wr(0xdec0,1)
            if s.bit7(0xdeb0): s.resb(0xdeb0,0)
            if s.bit7(0xdee0): s.resb(0xdee0,0); s.wr(0xdee2,0)
        elif k==1:
            s.wr(0xdea4,1); s.wr(0xdec8,1)
            if s.bit7(0xdeb4): s.resb(0xdeb4,0)
            if s.bit7(0xdee8): s.resb(0xdee8,0); s.wr(0xdeea,0)
        elif k==2:
            s.wr(0xdea8,1)
            if s.bit7(0xdeb8): s.resb(0xdeb8,0)
        elif k==3:
            s.wr(0xded8,1)
            if s.bit7(0xdef8): s.resb(0xdef8,0); s.wr(0xdefa,0)
        elif k==4: s.wr(0xdeb0,1); s.wr(0xdee0,1)
        elif k==5: s.wr(0xdeb4,1); s.wr(0xdee8,1)
        elif k==6: s.wr(0xdeb8,1)
        elif k==7: s.wr(0xdef8,1)
    # --- $421F
    def step(s,t):
        s.wr(0xde90,t); T=0xde00|t
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
            if a>=0x91: s.wr(T,a-0x91); continue
            k=a-0x80
            if k in (0,1,2,3,8):
                s.wr(T+{0:8,1:7,2:0xb,3:9,8:0xd}[k],s.rd(bc)); bc+=1
            elif k==4: s.wr(0xff24,s.rd(bc)); bc+=1
            elif k==5:
                d=s.rd(T+6); s.wr(T+6,d+1)
                sp=0xdf00|((t+2*d)&0xff)
                e=s.rd(bc); bc+=1; hi=s.rd(bc); bc+=1
                s.wr(sp,bc&0xff); s.wr(0xdf00|((sp+1)&0xff),bc>>8); bc=hi<<8|e
            elif k==6:
                d=s.rd(T+6)
                if d:
                    d-=1; s.wr(T+6,d); sp=0xdf00|((t+2*d)&0xff)
                    bc=s.rd(sp)|s.rd(0xdf00|((sp+1)&0xff))<<8
                else:
                    if s.rd(0xde91)==1:
                        s.cleanup(t); s.wr(T,0)
                        if not (s.rd(0xde40)|s.rd(0xde50)|s.rd(0xde60)|s.rd(0xde70)): s.wr(0xde1f,0)
                    else:
                        s.cleanup(t); s.wr(T,0)
                        s.wr(0xde00|((t+0x6f)&0xff),s.rd(0xde5f))
                        if not (s.rd(0xde00)|s.rd(0xde10)|s.rd(0xde20)|s.rd(0xde30)): s.wr(0xde0f,0)
                    return
            elif k==7: s.wr(T,0); return
            elif k==0xa: s.wr(0xde2f,s.rd(bc)); bc+=1
            elif k==0xb: e=s.rd(bc); hi=s.rd(bc+1); bc=hi<<8|e
            elif k==0xc:
                s.wr(0xff1a,0); src=0x450f+s.rd(bc); bc+=1
                for i in range(16): s.wr(0xff30+i,s.rd(src+i))
            elif k==0xd:
                x=s.rd(bc); bc+=1; E=0xdec0|(t>>1)
                s.wr(E,(0x80 if x else 0)|1)
                v=s.rd(0x4a0c+(x&15))
                s.wr(E+1,v&15); s.wr(E+2,0); s.wr(E+3,0); s.wr(E+4,v>>4); s.wr(E+5,x&15)
            elif k==0xe:
                x=s.rd(bc); bc+=1; V=0xde00|((((t>>4)|(t<<4))&0xff)*4+0xa0)&0xff
                s.wr(V,(0x80 if x else 0)|1); s.wr(V+1,x&15)
            elif k==0xf: s.wr(0xde3f,s.rd(bc)); bc+=1
            elif k==0x10: s.wr(0xde4f,s.rd(bc)); bc+=1
    def owner(s,b):      # $4011 / $4029
        T=0xde00|b
        if s.rd(T)!=0:
            if s.rd(T+1)!=0 or s.rd(T+0xa)==0x89: return None
            return b
        return s.owner2(b+0x40)
    def owner2(s,b):
        T=0xde00|b
        if s.rd(T)==0 or s.rd(T+1)!=0 or s.rd(T+0xa)==0x89: return None
        return b
    def per(s,T):
        e=((s.rd(T+0xa)+s.rd(T+0xb))<<1)&0xff
        return s.rd(0x47f2+e), s.rd(0x47f2+e+1)
    def out12(s,T,nr):   # $40F6
        s.wr(nr,s.rd(T+8)); s.wr(nr+1,s.rd(T+9))
        lo,hi=s.per(T); s.wr(T+0xc,lo); s.wr(nr+2,lo)
        a=hi|s.rd(T+0xd)|0x80; s.wr(nr+3,a); s.wr(T+0xe,a)
    def shadow(s,T):     # $4118
        lo,hi=s.per(T); s.wr(T+0xc,lo); s.wr(T+0xe,hi|s.rd(T+0xd)|0x80)
    def own_bits(s,b,va,ea,vb,eb,clr0,clr1):
        # set 0 owns: enable va/ea (sfx), suspend vb/eb (music)
        if not b&0x40:
            if va: s.resb(va,0)
            if ea: s.resb(ea,0)
            if vb: s.setb(vb,0)
            if eb: s.setb(eb,0)
            for x in clr0: s.wr(x,0)
        else:
            if vb: s.resb(vb,0)
            if eb: s.resb(eb,0)
            if va: s.setb(va,0)
            if ea: s.setb(ea,0)
            for x in clr1: s.wr(x,0)
    def update(s):
        s.wr(0xde5f,s.rd(0xde5f)+1)
        s.load_req(0xde0f,0x00); s.load_req(0xde1f,0x40)
        s.wr(0xde91,0)
        for t in (0,0x10,0x20,0x30): s.step(t)
        s.wr(0xde91,1)
        for t in (0x40,0x50,0x60,0x70): s.step(t)
        # NR51 $467C
        a=((s.rd(0xde00)+s.rd(0xde10)+s.rd(0xde20))&0xff)|s.rd(0xde30)
        c=s.rd(0xde3f) if a else 0
        s.wr(0xff25,(s.rd(0xde2f)&s.rd(0xde4f))|c)
        # CH1 $403D
        b=s.owner(0)
        if b is not None:
            T=0xde00|b; s.wr(0xff10,s.rd(T+7)); s.out12(T,0xff11)
            if not b&0x40:
                s.resb(0xdea0,0); s.resb(0xdec0,0); s.setb(0xdeb0,0); s.setb(0xdee0,0)
                s.wr(0xdec2,0); s.wr(0xdec3,0); s.wr(0xdea2,0)
            else:
                s.resb(0xdeb0,0); s.resb(0xdee0,0); s.setb(0xdea0,0); s.setb(0xdec0,0)
                s.wr(0xdee2,0); s.wr(0xdee3,0); s.wr(0xdeb2,0)
        if s.bit7(0xdee0) and s.owner2(0x40) is not None: s.shadow(0xde40)
        # CH2 $409B
        b=s.owner(0x10)
        if b is not None:
            T=0xde00|b; s.out12(T,0xff16)
            if not b&0x40:
                s.resb(0xdea4,0); s.resb(0xdec8,0); s.setb(0xdeb4,0); s.setb(0xdee8,0)
                s.wr(0xdeca,0); s.wr(0xdecb,0); s.wr(0xdea6,0)
            else:
                s.resb(0xdeb4,0); s.resb(0xdee8,0); s.setb(0xdea4,0); s.setb(0xdec8,0)
                s.wr(0xdeea,0); s.wr(0xdeeb,0); s.wr(0xdeb6,0)
        if s.bit7(0xdee8) and s.owner2(0x50) is not None: s.shadow(0xde50)
        # CH3 $4131
        b=s.owner(0x20)
        if b is not None:
            T=0xde00|b; s.wr(0xff1a,0); s.wr(0xff1a,0x80)
            s.wr(0xff1b,s.rd(T+8)); s.wr(0xff1c,s.rd(T+9))
            lo,hi=s.per(T); s.wr(T+0xc,lo); s.wr(0xff1d,lo); s.wr(0xff1e,hi|0xc0)
            if not b&0x40: s.resb(0xdea8,0); s.setb(0xdeb8,0); s.wr(0xdeaa,0)
            else: s.resb(0xdeb8,0); s.setb(0xdea8,0); s.wr(0xdeba,0)
        # CH4 $4182
        b=s.owner(0x30)
        if b is not None:
            T=0xde00|b
            s.wr(0xff20,s.rd(T+8)); s.wr(0xff21,s.rd(T+9)); s.wr(0xff22,s.rd(T+0xa))
            a=s.rd(T+0xd)|0x80; s.wr(0xff23,a); s.wr(T+0xe,a)
            if not b&0x40:
                s.resb(0xded8,0); s.setb(0xdef8,0); s.wr(0xdeda,0); s.wr(0xdedb,0)
            else:
                s.resb(0xdef8,0); s.setb(0xded8,0); s.wr(0xdefa,0); s.wr(0xdefb,0)
        if s.bit7(0xdef8) and s.owner2(0x70) is not None: s.wr(0xde7e,s.rd(0xde7d)|0x80)
        s.env_tick(); s.vib_tick()
    def env_tick(s):     # $43FF
        for k in range(8):
            E=0xdec0+8*k
            if not s.bit7(E): continue
            fl=s.rd(E); rate=s.rd(E+1); cnt=s.rd(E+2)
            if cnt:
                if cnt==rate: s.wr(E+2,0)
                else: s.wr(E+2,cnt+1)
                continue
            if not fl&1:
                off=s.rd(0x4a1b+s.rd(E+4))
                v=s.rd((0x4994+off+s.rd(E+3))&0xffff)
                if v: s.env_apply(k,v)
            if s.rd(E+3)!=7:
                s.wr(E+3,s.rd(E+3)+1); s.wr(E+2,s.rd(E+2)+1)
    def env_apply(s,k,v):  # $4453
        t=(k*16)&0xff; T=0xde00|t; ch=k&3
        if ch==0:
            s.wr(0xff10,s.rd(T+7)); s.wr(0xff11,s.rd(T+8)); s.wr(0xff12,v)
            s.wr(0xff13,s.rd(T+0xc)); s.wr(0xff14,s.rd(T+0xe))
        elif ch==1:
            s.wr(0xff16,s.rd(T+8)); s.wr(0xff17,v); s.wr(0xff18,s.rd(T+0xc)); s.wr(0xff19,s.rd(T+0xe))
        elif ch==3:
            s.wr(0xff20,s.rd(T+8)); s.wr(0xff21,v); s.wr(0xff22,s.rd(T+0xa)); s.wr(0xff23,s.rd(T+0xe))
    def vib_tick(s):     # $44B6
        for k in range(7):
            V=0xdea0+4*k
            if not s.bit7(V): continue
            fl=s.rd(V); tb=s.rd(V+1)
            if not fl&1:
                off=s.rd((0x498a+tb)&0xffff)
                dlt=s.rd((0x489a+off+s.rd(V+2))&0xffff)
                tl=s.rd(0x460f+k); nr=s.rd(0x4617+k)
                s.wr(0xff00|nr,s.rd(0xde00|tl)+dlt)
            x=s.rd(V+2)+1
            if x>=0x18: x=0x0c
            s.wr(V+2,x)
