import os
from pyboy import PyBoy
pb=PyBoy(os.environ.get('FFL1_ROM','Final Fantasy Legend, The (U) [!].gb'),window='null',sound_emulated=False)
m=pb.memory; seen={}; cnt={'u':0,'i':0,'ticks':0,'start':0}
def mk(n):
    def h(ctx):
        sp=pb.register_file.SP; ra=m[sp]|m[sp+1]<<8
        seen[(n,ra)]=seen.get((n,ra),0)+1
    return h
pb.hook_register(7,0x4003,mk('upd'),None); pb.hook_register(7,0x4000,mk('init'),None)
pb.hook_register(7,0x4030,mk('upd30'),None); pb.hook_register(7,0x4006,mk('init06'),None)
pb.hook_register(7,0x4059,mk('start'),None); pb.hook_register(7,0x40CD,mk('tick'),None)
F=1500
for f in range(F): pb.tick(1,False)
print({('%s'%a,'%04X'%b):c for (a,b),c in seen.items()}, 'frames',F)
print('FFE0..EE', ' '.join('%02X'%m[0xFFE0+i] for i in range(15)))
