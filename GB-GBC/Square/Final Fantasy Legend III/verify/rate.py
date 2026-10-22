import os,sys
from pyboy import PyBoy
rom=os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb')
pb=PyBoy(rom,window='null',sound_emulated=False)
cnt={'upd':0,'frames':0}
def h(ctx): cnt['upd']+=1
pb.hook_register(0x0F,0x4006,h,None)
for f in range(1200):
    pb.tick(1,False)
print('updates',cnt['upd'],'frames',1200, 'song req/cur',hex(pb.memory[0xFFBA]),hex(pb.memory[0xFFBB]), 'tempo',hex(pb.memory[0xCB01]))
