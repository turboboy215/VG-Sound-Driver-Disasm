# Every PCM opcode found by tools/hhscript.py: Python decoder vs the ROM decoder (tools/cpu.py)
# vs PyBoy, by redirecting the game's first PCM call (ROM0 $2350) to each sample in turn.
import os,sys
sys.path.insert(0,os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools'))
from paths import ROMS
from cpu import CPU
from hhpcm import decode,SAMPLES
from pyboy import PyBoy
rom=open(ROMS['hh'],'rb').read()
def py(bank,a):
    o=bank*0x4000+a-0x4000; cnt=0x10000-(rom[o+1]|rom[o+2]<<8)
    out,end=decode(rom,o+3,cnt); return [v*0x11 for v in out]+[0xff]
def cpu(bank,a):
    c=CPU(rom,bank); de=a+1; c.d,c.e=de>>8,de&0xff; c.pc=0x2350; c.sp=0xc0f0
    while c.pc!=0x237c: c.step()
    buf=[]; x=0xc300
    while True:
        v=c.mem.get(x); buf.append(v); x+=1
        if v==0xff: return buf
def emu(bank,a):
    pb=PyBoy(ROMS['hh'],window='null',sound_emulated=False); pb.set_emulation_speed(0)
    got={}
    def h2350(ctx):
        if 'done' in got: return
        got['done']=1; pb.memory[0x2100]=bank; pb.memory[0xff8a]=bank; pb.register_file.D=(a+1)>>8; pb.register_file.E=(a+1)&0xff
    def h238f(ctx):
        if 'buf' in got: return
        buf=[]; x=0xc300
        while True:
            v=pb.memory[x]; buf.append(v); x+=1
            if v==0xff: break
        got['buf']=buf
    pb.hook_register(0,0x2350,h2350,None); pb.hook_register(0,0x238f,h238f,None)
    for f in range(1000):
        if 'buf' in got: break
        if f%200==100: pb.button('start')
        if f%50==25: pb.button('a')
        pb.tick()
    pb.stop(save=False)
    return got.get('buf')
for bank,a,name in SAMPLES:
    p=py(bank,a); c=cpu(bank,a); e=emu(bank,a)
    print('%s %02x:%04x %d samples: python==cpu %s, python==emulator %s'%(name,bank,a,len(p)-1,p==c,p==e))
