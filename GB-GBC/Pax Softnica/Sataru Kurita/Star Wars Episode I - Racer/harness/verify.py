"""Play every song and SFX of the rebuilt bank in PyBoy and check that every
event the driver reads is one the parser found.
usage: python verify.py <original ROM> [frames per song]
Hooks: Music_ReadEvent's read ($4552) and Sfx_ReadEvent's read ($510D)."""
import sys, os, logging
HERE=os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE,'..','tools'))
logging.disable(logging.CRITICAL)
from pyboy import PyBoy
from swrparse import Bank3
ROM=open(sys.argv[1],'rb').read()
FR=int(sys.argv[2]) if len(sys.argv)>2 else 7200
B=Bank3(ROM)
mus={a for a,(sz,k,i) in B.items.items() if k in('musev','muscmd')}
sfx={a for a,(sz,k,i) in B.items.items() if k in('sfxev','sfxcmd')}
pb=PyBoy(os.path.join(HERE,'harness.gbc'),window='null',sound_emulated=False,cgb=True)
M=pb.memory; R=pb.register_file
mreads=[]; sreads=[]
pb.hook_register(3,0x4552,lambda c: mreads.append(R.HL),None)
pb.hook_register(3,0x510D,lambda c: sreads.append(R.HL),None)
def tick(n=1):
    for _ in range(n): pb.tick(1,False)
def cmd(c):
    M[0xFF80]=c; tick(2)
while M[0xFF81]<5: tick()
def run(kind,n,frames):
    cmd(4)
    mreads.clear(); sreads.clear()
    if kind=='song': M[0xCB0A]=n; cmd(1)
    else: M[0xCB92]=n; cmd(2)
    c0=M[0xFF81]; tick(frames)
    alive=(M[0xFF81]-c0)&0xFF
    return [a for a in mreads if a not in mus],[a for a in sreads if a not in sfx],set(mreads),set(sreads),alive,M[0xCB0A]
total=0; rm=set(); rs=set()
for s in range(1,B.NSONGS):
    bm,bs,m,sr,alive,cur=run('song',s,FR); rm|=m; total+=len(bm)+len(bs)
    print(f'song {s:2d}: {len(m)} distinct music events read, {len(bm)} off the parse {[hex(x) for x in bm[:4]]}'+('' if cur else ', stopped')+('' if alive else ', HUNG'))
for s in range(1,B.NSFX+1):
    bm,bs,m,sr,alive,cur=run('sfx',s,600); rs|=sr; total+=len(bm)+len(bs)
    if bs or bm or not alive: print(f'SFX {s}: {len(bs)} off the parse {[hex(x) for x in bs[:4]]}'+('' if alive else ', HUNG'))
musstarts={a for a,(sz,k,i) in B.items.items() if k in('musev','muscmd')}
sfxstarts={a for a,(sz,k,i) in B.items.items() if k in('sfxev','sfxcmd')}
print(f'music events read {len(rm&musstarts)}/{len(musstarts)}, SFX events read {len(rs&sfxstarts)}/{len(sfxstarts)}')
# fade-out, engine and voice: only check that the driver keeps running
cmd(4); M[0xCB0A]=1; cmd(1); tick(120); M[0xCB74]=1; cmd(3); tick(200)
print('fade-out: song', M[0xCB0A], '(0 = stopped), fade step', M[0xCB72])
cmd(4); M[0xD486]=0x40; M[0xD586]=0x60; M[0xD49D]=0x80; M[0xD49E]=4; M[0xD59D]=0x40; M[0xD59E]=6; M[0xCBCB]=1
c0=M[0xFF81]; tick(300); print('engine: updates (mod 256)', (M[0xFF81]-c0)&0xFF, 'rival volume %02X, rival pitch %02X, player pitch %02X, noise shift %d'%(M[0xCBD4],M[0xCBDD],M[0xCBDC],M[0xCBE6]))
M[0xCBCB]=0; M[0xCBF3]=1; c0=M[0xFF81]; tick(600); print('voice: updates after', (M[0xFF81]-c0)&0xFF, 'request', M[0xCBF3])
print('TOTAL off the parse:',total)
