import sys, os
from pyboy import PyBoy
from collections import Counter
pb=PyBoy(os.environ.get('PB_ROM','pb.gbc'),window='null',sound_emulated=False,cgb=True); pb.set_emulation_speed(0)
isr=[0]; ly=[]
def h(c):
    isr[0]+=1; ly.append(pb.memory[0xFF44])
pb.hook_register(0,0x3189,h,None)
for f in range(1100): pb.tick()
isr[0]=0; ly.clear(); per=[]
for f in range(600):
    a=isr[0]; pb.tick(); per.append(isr[0]-a)
print(Counter(per), sum(per)/600*59.7275)
print(per[:60]); print(ly[:60])
