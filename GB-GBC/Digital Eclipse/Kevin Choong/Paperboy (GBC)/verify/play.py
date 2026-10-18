import sys, os
from pyboy import PyBoy
pb=PyBoy(os.environ.get('PB_ROM','pb.gbc'),window='null',sound_emulated=False,cgb=True); pb.set_emulation_speed(0)
fr=[0]; log=[]; rf=pb.register_file; pend=[]
def caller(): sp=rf.SP; return pb.memory[sp]|pb.memory[sp+1]<<8
pb.hook_register(0,0x3114,lambda c:(log.append((fr[0],'song',rf.A,hex(caller()),pb.memory[0xC0A2])),pend.append(('song',rf.A))),None)
pb.hook_register(0,0x3095,lambda c:log.append((fr[0],'samp',rf.A,hex(caller()),pb.memory[0xC0A2])),None)
pb.hook_register(0,0x3318,lambda c:log.append((fr[0],'stop',None,hex(caller()),pb.memory[0xC0A2])),None)
import random; random.seed(1)
for f in range(14000):
    fr[0]=f
    if f%90==0: pb.button('start' if f<3000 else random.choice(['a','start','a','b']))
    if 3000<f and f%7==0: pb.button(random.choice(['left','right','up','a']))
    pb.tick()
    if pend:
        k,a=pend.pop(); pend.clear()
        for _ in range(30): pb.tick(); fr[0]+=0
        pb.screen.image.save(f'shots/{f:05d}_{k}{a}.png')
for l in log: print(l)
