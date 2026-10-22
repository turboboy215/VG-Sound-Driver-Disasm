import os
from pyboy import PyBoy
pb=PyBoy(os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb'),window='null',sound_emulated=False)
seen={}
def h(ctx):
    sp=pb.register_file.SP
    ra=pb.memory[sp]|pb.memory[sp+1]<<8
    ra2=pb.memory[sp+2]|pb.memory[sp+3]<<8
    seen[(ra,ra2)]=seen.get((ra,ra2),0)+1
pb.hook_register(0x0F,0x4006,h,None)
for f in range(1500): pb.tick(1,False)
print({('%04X'%a,'%04X'%b):c for (a,b),c in seen.items()})
print(' '.join('%02X'%pb.memory[0xC0B9+i] for i in range(6)))
