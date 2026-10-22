import os
from pyboy import PyBoy
pb=PyBoy(os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb'),window='null',sound_emulated=False)
m=pb.memory; log=[]
def mk(n):
    def h(ctx):
        sp=pb.register_file.SP
        log.append((n,pb.frame_count if hasattr(pb,'frame_count') else 0,'%04X'%(m[sp]|m[sp+1]<<8)))
    return h
for a,n in ((0x4003,'init'),(0x4031,'reset'),(0x4065,'play'),(0x4759,'sfx')):
    pb.hook_register(0x0F,a,mk(n),None)
for f in range(1500): pb.tick(1,False)
print(log[:20])
