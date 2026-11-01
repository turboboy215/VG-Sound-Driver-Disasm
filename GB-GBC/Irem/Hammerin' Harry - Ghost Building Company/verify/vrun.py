# Model-vs-emulator verification for the Irem GB sound drivers.
# usage: python3 vrun.py <kn|hh> <updates> [script.json]
import os,sys
sys.path.insert(0,os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))),'tools'))
from paths import ROMS,ROOT
VERIFY=os.path.join(ROOT,'verify')+os.sep
import sys,json
from pyboy import PyBoy
from sm83 import ROM,decode
G=sys.argv[1]; NUPD=int(sys.argv[2]); SCRIPT=json.load(open(sys.argv[3])) if len(sys.argv)>3 else {}
if 'rom' in SCRIPT: SCRIPT['rom']=os.path.join(VERIFY,SCRIPT['rom'])
if G=='kn':
    from knmodel import KNModel as Model
    ROMF=SCRIPT.get('rom',ROMS['kn']); ENTRY=(1,0x7e50); RET=(0,0x01af); RAM=range(0xc800,0xc900)
    CODE=[(1,0x7a00,0x7c36),(1,0x7e50,0x7eb8)]; REQ={'sfx':0xc80e,'mus':0xc81e}
else:
    from hhmodel import HHModel as Model
    ROMF=SCRIPT.get('rom',ROMS['hh']); ENTRY=(1,0x4000); RET=(0,0x0c00); RAM=range(0xde00,0xe000)
    CODE=[(1,0x4011,0x47f2)]; REQ={'sfx':0xde0f,'mus':0xde1f}
rom=open(ROMF,'rb').read(); R=ROM(ROMF)
pb=PyBoy(ROMF,window='null',sound_emulated=False); pb.set_emulation_speed(0)
M=pb.memory
st={'upd':0,'model':None,'io':[],'bad':0,'checked':0,'active':False}
pokes={}
for k,v in SCRIPT.get('pokes',{}).items(): pokes.setdefault(int(k),[]).extend(v)
drop=SCRIPT.get('drop_game',False)
from cpu import CPU
def entry(ctx):
    u=st['upd']
    if u%500==0 and SCRIPT.get('progress',0): print('upd',u,'frame',pb.frame_count,flush=True)
    if drop:
        for a in REQ.values():
            if M[a] not in (0,0xff): M[a]=0xff
    for p in pokes.get(u,[]):
        if p[0]=='clr':
            for a in range(int(p[1],16),int(p[2],16)): M[a]=0
        else: M[REQ[p[0]] if p[0] in REQ else int(p[0],16)]=p[1]
    snap={a:M[a] for a in RAM}
    m=Model(rom); m.ram.update(snap); m.update()
    c=CPU(rom,1); c.mem.update(snap); c.sp=0xcff0 if G=='kn' else 0xc0f0
    c.call(ENTRY[1])
    st['model']=m; st['cpu']=c; st['active']=True
def ret(ctx):
    if not st['active']: return
    st['active']=False; m=st['model']; c=st['cpu']; u=st['upd']; st['upd']+=1
    d1=[(a,M[a],m.ram.get(a),c.mem.get(a)) for a in RAM if not (M[a]==m.ram.get(a)==c.mem.get(a))]
    iod=c.io!=m.io
    st['checked']+=1; st['writes']=st.get('writes',0)+len(c.io)
    if d1 or iod:
        st['bad']+=1
        if st['bad']<=5:
            print('MISMATCH upd',u,'frame',pb.frame_count)
            for d in d1[:12]: print('  ram %04x emu %02x model %s cpu %s'%d)
            if iod:
                print('  io cpu  ',' '.join('%02x=%02x'%(a&0xff,v) for a,v in c.io[:48]))
                print('  io model',' '.join('%02x=%02x'%(a&0xff,v) for a,v in m.io[:48]))
pb.hook_register(ENTRY[0],ENTRY[1],entry,None)
pb.hook_register(RET[0],RET[1],ret,None)
nh=0
buttons=SCRIPT.get('buttons',[])
import random; random.seed(SCRIPT.get('seed',1))
f=0
while st['upd']<NUPD and f<NUPD*3+2000:
    for b in buttons:
        if f%b[1]==b[2]: pb.button(b[0])
    pb.tick(); f+=1
print('%s: %d updates checked, %d mismatching, %d register writes, %d frames'%(G,st['checked'],st['bad'],st.get('writes',0),f))
