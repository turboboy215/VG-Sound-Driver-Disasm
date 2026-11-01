# PCM check: Python decoder vs the ROM's decoder (run in tools/cpu.py) vs PyBoy's $C300 buffer
import os,sys
sys.path.insert(0,os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools'))
from paths import ROMS,ROOT
VERIFY=os.path.join(ROOT,'verify')+os.sep
from cpu import CPU
from hhpcm import decode
from pyboy import PyBoy
rom=open(ROMS['hh'],'rb').read()
SAMPLES=[0x4414,0x4690,0x48c7]
def py(de):
    cnt=0x10000-(rom[0xe*0x4000+de-0x4000+0]|rom[0xe*0x4000+de-0x4000+1]<<8)
    out,end=decode(rom,0xe*0x4000+de-0x4000+2,cnt)
    return [v|v<<4 for v in out]+[0xff], 0x4000+(end-0xe*0x4000)
def cpu(de):
    c=CPU(rom,0xe); c.d,c.e=de>>8,de&0xff; c.pc=0x2350; c.sp=0xc0f0; n=0
    while c.pc!=0x237c:
        c.step(); n+=1
        if n>5_000_000: raise RuntimeError
    buf=[]; a=0xc300
    while True:
        v=c.mem.get(a); buf.append(v); a+=1
        if v==0xff: break
    return buf,(c.d<<8|c.e),n
emu={}
pb=PyBoy(ROMS['hh'],window='null',sound_emulated=False); pb.set_emulation_speed(0)
isr=[0]; frames={}
def at238f(ctx):
    buf=[]; a=0xc300
    while True:
        v=pb.memory[a]; buf.append(v); a+=1
        if v==0xff: break
    emu[len(emu)]=(buf,pb.frame_count)
def atisr(ctx): isr[0]+=1
pb.hook_register(0,0x238f,at238f,None); pb.hook_register(0,0x23e7,atisr,None)
for f in range(1000):
    if f%200==100: pb.button('start')
    if f%50==25: pb.button('a')
    pb.tick()
    frames[f]=isr[0]
for i,de in enumerate(SAMPLES):
    p,pend=py(de); c,cend,n=cpu(de)
    e,fr=emu.get(i,(None,None))
    print('sample %d at E:%04x: %d bytes, python==cpu %s, end %04x/%04x, ==emulator %s (frame %s), %d instructions'%(i+1,de-1,len(p)-1,p==c,pend,cend,p==e,fr,n))
# timer rate while playing
rates=[frames[f]-frames[f-1] for f in range(1,1000) if frames[f]-frames[f-1]>0]
import collections; print('timer ISR calls per frame while playing:',sorted(collections.Counter(rates).items()))
