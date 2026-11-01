# Small SM83 interpreter used to run the real driver code on a RAM snapshot.
class CPU:
    def __init__(s,rom,bank=1):
        s.rom=rom; s.bank=bank; s.mem={}; s.io=[]
        s.a=s.b=s.c=s.d=s.e=s.h=s.l=0; s.f=0; s.sp=0xcff0; s.pc=0
    def rd(s,a):
        a&=0xffff
        if a<0x4000: return s.rom[a]
        if a<0x8000: return s.rom[s.bank*0x4000+a-0x4000]
        return s.mem.get(a,0)
    def wr(s,a,v):
        a&=0xffff; v&=0xff
        if a<0x8000: raise RuntimeError('ROM write %04x=%02x at %04x'%(a,v,s.pc))
        if a>=0xff00 and a<0xff80: s.io.append((a,v))
        s.mem[a]=v
    def fz(s): return s.f&0x80
    def fc(s): return s.f&0x10
    def setf(s,z,n,h,c): s.f=(0x80 if z else 0)|(0x40 if n else 0)|(0x20 if h else 0)|(0x10 if c else 0)
    def r8(s,i):
        return [s.b,s.c,s.d,s.e,s.h,s.l,None,s.a][i] if i!=6 else s.rd(s.h<<8|s.l)
    def w8(s,i,v):
        v&=0xff
        if i==0: s.b=v
        elif i==1: s.c=v
        elif i==2: s.d=v
        elif i==3: s.e=v
        elif i==4: s.h=v
        elif i==5: s.l=v
        elif i==6: s.wr(s.h<<8|s.l,v)
        else: s.a=v
    def rp(s,i):
        return [s.b<<8|s.c,s.d<<8|s.e,s.h<<8|s.l,s.sp][i]
    def wp(s,i,v):
        v&=0xffff
        if i==0: s.b,s.c=v>>8,v&0xff
        elif i==1: s.d,s.e=v>>8,v&0xff
        elif i==2: s.h,s.l=v>>8,v&0xff
        else: s.sp=v
    def fetch(s): v=s.rd(s.pc); s.pc=(s.pc+1)&0xffff; return v
    def fetch16(s): lo=s.fetch(); return lo|s.fetch()<<8
    def push(s,v): s.sp=(s.sp-1)&0xffff; s.wr(s.sp,v>>8); s.sp=(s.sp-1)&0xffff; s.wr(s.sp,v&0xff)
    def pop(s): lo=s.rd(s.sp); s.sp=(s.sp+1)&0xffff; hi=s.rd(s.sp); s.sp=(s.sp+1)&0xffff; return hi<<8|lo
    def cond(s,i): return [not s.fz(), s.fz(), not s.fc(), s.fc()][i]
    def alu(s,op,v):
        a=s.a
        if op==0: r=a+v; s.setf((r&0xff)==0,0,(a&15)+(v&15)>15,r>0xff); s.a=r&0xff
        elif op==1: c=1 if s.fc() else 0; r=a+v+c; s.setf((r&0xff)==0,0,(a&15)+(v&15)+c>15,r>0xff); s.a=r&0xff
        elif op==2: r=a-v; s.setf((r&0xff)==0,1,(a&15)<(v&15),r<0); s.a=r&0xff
        elif op==3: c=1 if s.fc() else 0; r=a-v-c; s.setf((r&0xff)==0,1,(a&15)<(v&15)+c,r<0); s.a=r&0xff
        elif op==4: s.a=a&v; s.setf(s.a==0,0,1,0)
        elif op==5: s.a=a^v; s.setf(s.a==0,0,0,0)
        elif op==6: s.a=a|v; s.setf(s.a==0,0,0,0)
        else: r=a-v; s.setf((r&0xff)==0,1,(a&15)<(v&15),r<0)
    def cb(s):
        op=s.fetch(); i=op&7; x=op>>6; y=(op>>3)&7; v=s.r8(i)
        if x==0:
            c=s.fc()!=0
            if y==0: r=((v<<1)|(v>>7))&0xff; nc=v>>7
            elif y==1: r=((v>>1)|(v<<7))&0xff; nc=v&1
            elif y==2: r=((v<<1)|c)&0xff; nc=v>>7
            elif y==3: r=(v>>1)|(c<<7); nc=v&1
            elif y==4: r=(v<<1)&0xff; nc=v>>7
            elif y==5: r=(v>>1)|(v&0x80); nc=v&1
            elif y==6: r=((v<<4)|(v>>4))&0xff; nc=0
            else: r=v>>1; nc=v&1
            s.setf(r==0,0,0,nc); s.w8(i,r)
        elif x==1: s.f=(s.f&0x10)|0x20|(0 if v&(1<<y) else 0x80)
        elif x==2: s.w8(i,v&~(1<<y))
        else: s.w8(i,v|(1<<y))
    def call(s,addr,ret_sentinel=0xfffe,limit=200000):
        s.push(ret_sentinel); s.pc=addr; n=0
        while s.pc!=ret_sentinel:
            s.step(); n+=1
            if n>limit: raise RuntimeError('runaway at %04x'%s.pc)
        return n
    def step(s):
        op=s.fetch()
        if op==0x00: return
        if op==0xcb: return s.cb()
        x=op>>6; y=(op>>3)&7; z=op&7; p=y>>1; q=y&1
        if x==1:
            if op==0x76: return
            return s.w8(y,s.r8(z))
        if x==2: return s.alu(y,s.r8(z))
        if x==0:
            if z==0:
                if y==0: return
                if y==1: a=s.fetch16(); s.wr(a,s.sp&0xff); s.wr(a+1,s.sp>>8); return
                if y==3: d=s.fetch(); s.pc=(s.pc+(d-256 if d>127 else d))&0xffff; return
                if y>=4:
                    d=s.fetch()
                    if s.cond(y-4): s.pc=(s.pc+(d-256 if d>127 else d))&0xffff
                    return
                raise RuntimeError('op %02x'%op)
            if z==1:
                if q==0: return s.wp(p,s.fetch16())
                hl=s.rp(2); v=s.rp(p); r=hl+v
                s.f=(s.f&0x80)|(0x20 if (hl&0xfff)+(v&0xfff)>0xfff else 0)|(0x10 if r>0xffff else 0); s.wp(2,r); return
            if z==2:
                if p==0: ad=s.rp(0)
                elif p==1: ad=s.rp(1)
                else:
                    ad=s.rp(2); s.wp(2,ad+(1 if p==2 else -1))
                if q==0: s.wr(ad,s.a)
                else: s.a=s.rd(ad)
                return
            if z==3: s.wp(p,s.rp(p)+(1 if q==0 else -1)); return
            if z==4: v=(s.r8(y)+1)&0xff; s.f=(s.f&0x10)|(0x80 if v==0 else 0)|(0x20 if v&15==0 else 0); return s.w8(y,v)
            if z==5: v=(s.r8(y)-1)&0xff; s.f=(s.f&0x10)|0x40|(0x80 if v==0 else 0)|(0x20 if v&15==15 else 0); return s.w8(y,v)
            if z==6: return s.w8(y,s.fetch())
            if z==7:
                a=s.a
                if y==0: s.a=((a<<1)|(a>>7))&0xff; s.setf(0,0,0,a>>7)
                elif y==1: s.a=((a>>1)|(a<<7))&0xff; s.setf(0,0,0,a&1)
                elif y==2: s.a=((a<<1)|(1 if s.fc() else 0))&0xff; s.setf(0,0,0,a>>7)
                elif y==3: s.a=(a>>1)|(0x80 if s.fc() else 0); s.setf(0,0,0,a&1)
                elif y==5: s.a=a^0xff; s.f|=0x60
                elif y==6: s.f=(s.f&0x80)|0x10
                elif y==7: s.f=(s.f&0x80)|(0 if s.fc() else 0x10)
                else: raise RuntimeError('daa')
                return
        # x==3
        if op in (0xc0,0xc8,0xd0,0xd8):
            if s.cond(y): s.pc=s.pop()
            return
        if op in (0xc9,0xd9): s.pc=s.pop(); return
        if op in (0xc1,0xd1,0xe1,0xf1):
            v=s.pop()
            if op==0xf1: s.a,s.f=v>>8,v&0xf0
            else: s.wp(p,v)
            return
        if op in (0xc5,0xd5,0xe5,0xf5):
            s.push((s.a<<8|s.f) if op==0xf5 else s.rp(p)); return
        if op==0xc3: s.pc=s.fetch16(); return
        if op in (0xc2,0xca,0xd2,0xda):
            a=s.fetch16()
            if s.cond(y): s.pc=a
            return
        if op==0xcd: a=s.fetch16(); s.push(s.pc); s.pc=a; return
        if op in (0xc4,0xcc,0xd4,0xdc):
            a=s.fetch16()
            if s.cond(y): s.push(s.pc); s.pc=a
            return
        if op==0xe9: s.pc=s.h<<8|s.l; return
        if z==6: return s.alu(y,s.fetch())
        if z==7: s.push(s.pc); s.pc=y*8; return
        if op==0xe0: s.wr(0xff00|s.fetch(),s.a); return
        if op==0xf0: s.a=s.rd(0xff00|s.fetch()); return
        if op==0xe2: s.wr(0xff00|s.c,s.a); return
        if op==0xf2: s.a=s.rd(0xff00|s.c); return
        if op==0xea: s.wr(s.fetch16(),s.a); return
        if op==0xfa: s.a=s.rd(s.fetch16()); return
        if op in (0xf3,0xfb): return
        if op==0xf9: s.sp=s.rp(2); return
        raise RuntimeError('unhandled op %02x at %04x'%(op,(s.pc-1)&0xffff))
