"""PyBoy check: each dispatched event matches the parsed stream (order, size, time)."""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
sys.argv=[sys.argv[0], sys.argv[1]] + sys.argv[2:]
from pyboy import PyBoy
import parse
parse.d=open(sys.argv[1],'rb').read()
pb=PyBoy(sys.argv[1],window='null',sound_emulated=False,cgb=True)
m=pb.memory
exp={}
for a in (0x4000,0x661A):
    for o,t,c,dat in parse.parse(0x3C,a): exp[0x4000+o%0x4000]=(t,c)
got=[];bad=[]
def disp(ctx):
    hl=pb.register_file.HL  # points at command byte
    ev=hl-2
    clock=m[0xC37C]<<8|m[0xC37D]
    got.append(ev)
    if ev not in exp: bad.append(('unknown',hex(ev),clock))
    elif exp[ev][0]!=clock: bad.append(('time',hex(ev),exp[ev][0],clock))
pb.hook_register(0,0x34EC,disp,None)
for f in range(int(sys.argv[2])):
    if f==4500:
        m[0xC37E]=0x66; m[0xC37F]=0x1A; m[0xC37C]=0; m[0xC37D]=0
    pb.tick()
seq=sorted(exp)
print('dispatched',len(got),'distinct',len(set(got)),'of',len(exp),'bad',len(bad),bad[:5])
# order check: consecutive dispatches follow the stream
idx={a:i for i,a in enumerate(seq)}
jumps=[(hex(a),hex(b)) for a,b in zip(got,got[1:]) if idx.get(b)!=idx.get(a,-9)+1]
print('non-sequential steps',jumps)
