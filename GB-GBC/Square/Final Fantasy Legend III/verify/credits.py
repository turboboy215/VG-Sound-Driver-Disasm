"""Force song 7 in PyBoy and watch the real driver reach the coda at $4C11 and the end."""
import os
from pyboy import PyBoy
pb=PyBoy(os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb'),window='null',sound_emulated=False)
for f in range(600): pb.tick(1,False)
m=pb.memory
m[0xFFBA]=7
ups=[0]; hits={}
def h(ctx):
    ups[0]+=1
    p=m[0xCB09]|m[0xCB0A]<<8
    if 0x4C11<=p<=0x4C64 and 'coda' not in hits: hits['coda']=(ups[0],p,m[0xCB01])
    for nm,a in (('CH2',0xCB05),('CH1',0xCB1D),('CH3',0xCB35),('CH4',0xCB4D)):
        if m[a]==0xFF and nm not in hits: hits[nm]=ups[0]
pb.hook_register(0x0F,0x4006,h,None)
f=0
while f<32000 and len([k for k in hits if k.startswith('CH')])<4:
    pb.tick(1,False); f+=1
    if m[0xFFBB]!=7: print('song changed to',m[0xFFBB],'at frame',f); break
FPS=4194304/70224
print('driver calls',ups[0])
for k,v in hits.items():
    u=v[0] if isinstance(v,tuple) else v
    print(k,v,'%.1f s'%(u/FPS))
print('frames run', f, 'driver calls', ups[0])
