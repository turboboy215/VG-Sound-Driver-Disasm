# Walks Hammerin' Harry's script bytecode (interpreter ROM0 $2344, table $221F) to find every PCM opcode ($1A).
import sys,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from cpu import CPU
from hhpcm import decode
from paths import ROMS
rom=open(ROMS['hh'],'rb').read()
def b(bank,a): return rom[a if a<0x4000 else bank*0x4000+a-0x4000]
HANDLER={k:(b(0,0x2220+k)<<8|b(0,0x221f+k)) for k in range(0,0x26,2)}
class BCPU(CPU):
    def wr(s,a,v):
        if 0x2000<=a<0x4000: s.bank=v&0x1f or 1; return
        if a<0x8000: return
        CPU.wr(s,a,v)
def run_handler(op,bank,de):
    c=BCPU(rom,bank); c.d,c.e=de>>8,de&0xff; c.sp=0xc0f0; c.mem[0xff41]=0; c.mem[0xff8a]=bank
    c.call(HANDLER[op],limit=3_000_000)
    return c.d<<8|c.e
def walk(entries):
    seen=set(); pcm=[]; work=list(entries); calls=[]
    while work:
        bank,de=work.pop()
        while (bank,de) not in seen:
            seen.add((bank,de)); op=b(bank,de); at=de; de+=1
            if op>=0x26 or op&1: calls.append(('bad',bank,at,op)); break
            if op in (0x00,0x12): break   # end / return from a called script
            if op==0x0e: de=b(bank,de)|b(bank,de+1)<<8; continue
            if op==0x10:
                nb=b(bank,de); na=b(bank,de+1)|b(bank,de+2)<<8; work.append((nb,na)); calls.append(('call',bank,at,nb,na)); de+=3; continue
            if op==0x24:
                work.append((bank,b(bank,de+2)|b(bank,de+3)<<8)); de+=4; continue
            if op==0x1c:
                t=de+1; lo=0x10000; n=0
                while t+1<lo:
                    w=b(bank,t)|b(bank,t+1)<<8
                    if not (0x4000<=w<0x8000) or (w<=t and w>at): break
                    work.append((bank,w)); lo=min(lo,w) if w>t else lo; t+=2; n+=1
                calls.append(('switch',bank,at,n)); break
            if op==0x0c: de+=3; continue
            if op==0x1a:
                cnt=0x10000-(b(bank,de)|b(bank,de+1)<<8)
                off=bank*0x4000+de+2-0x4000
                out,e=decode(rom,off,cnt); pcm.append((bank,at,cnt)); de=0x4000+e-bank*0x4000; continue
            if op in (0x02,): de+=2; continue
            if op in (0x08,0x1e,0x20): continue
            if op==0x0a: de+=5; continue
            if op==0x14: de+=3; continue
            de=run_handler(op,bank,de)
    return pcm,calls,seen
if __name__=='__main__':
    E=[(0xf,0x4000),(0xd,0x4000),(0xe,0x4023),(0xe,0x43a4),(0xe,0x4000),(0xa,0x4000),(0xf,0x5456),(0xf,0x660e),(0xe,0x6bdc)]
    pcm,calls,seen=walk(E)
    for x in calls: print(*[('%02x'%y if isinstance(y,int) and y<256 else ('%04x'%y if isinstance(y,int) else y)) for y in x])
    for bk,a,cnt in sorted(set(pcm)): print('PCM %02x:%04x %d samples %.3f s'%(bk,a,cnt,cnt/4228))
