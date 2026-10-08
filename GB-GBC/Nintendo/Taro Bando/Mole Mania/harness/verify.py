"""Play every song and SFX of the rebuilt banks in PyBoy and check every byte
the driver reads against the parser.
usage: python verify.py <original ROM> [frames per song]
A hook on the driver's pattern read (Pat_Read, $439A) and SFX read (Sfx_Read,
$4CD9) records each address read.  Music reads must fall on pattern bytes
(events and command arguments); the one read that may fall past the end of
an unterminated pattern is the gate-end look-ahead for TIE ($4553), which
only compares the byte.  SFX reads must fall on SFX bytes."""
import sys, os, logging
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tools'))
logging.disable(logging.CRITICAL)
from pyboy import PyBoy
from mmparse import Bank
ROM=open(sys.argv[1],'rb').read()
FR=int(sys.argv[2]) if len(sys.argv)>2 else 3600
END={0x07:0x7FFF,0x0B:0x7FDF,0x1A:0x6831}
pb=PyBoy(os.path.join(os.path.dirname(os.path.abspath(__file__)),'harness.gb'),window='null',sound_emulated=False)
M=pb.memory; R=pb.register_file
reads=[]; peeks=[]; sreads=[]
def h_read(ctx): reads.append(R.HL)
def h_peek(ctx): peeks.append(reads.pop() if reads else None)
def h_sread(ctx): sreads.append(R.HL)
for bk in (0x07,0x0B,0x1A):
    pb.hook_register(bk,0x439A,h_read,None)
    pb.hook_register(bk,0x4556,h_peek,None)
    pb.hook_register(bk,0x4CD9,h_sread,None)
def tick(n=1):
    for _ in range(n): pb.tick(1,False)
while M[0xFF81]<5: tick()
def run(bk,cov,scov,ends,sgb,kind,num,frames):
    M[0xFF80]=bk; M[0xC0A0]=0x80 if sgb else 0
    M[0xDC00]=0; M[0xDC01]=1; M[0xDC02]=0x0F; tick(2)
    reads.clear(); peeks.clear(); sreads.clear()
    if kind=='song': M[0xDC00]=num
    else:
        n=num-1; M[0xDC03+n//8]|=1<<(n%8)
    tick(frames)
    bad=[a for a in reads if a not in cov]
    badp=[a for a in peeks if a is not None and a not in cov and a not in ends]
    bads=[a for a in sreads if a not in scov]
    return bad,badp,bads,set(reads),set(sreads),M[0xDC10],len([a for a in peeks if a in ends])
total=0
for bk in (0x07,0x0B,0x1A):
    B=Bank(ROM,bk,END[bk])
    cov=set(); scov=set(); starts=set(); sstarts=set()
    for a,(sz,k,i) in B.items.items():
        if k in('ev','cmd'): cov|=set(range(a,a+sz)); starts.add(a)
        if k.startswith('sfx'): scov|=set(range(a,a+sz)); sstarts.add(a)
    ra=set(); rs=set(); nend=0
    for sgb in (0,1):
        for s in range(1,B.nsongs+1):
            bad,badp,bads,r,_,cur,pe=run(bk,cov,scov,B.pat_ends,sgb,'song',s,FR); ra|=r; nend+=pe
            total+=len(bad)+len(badp)
            if bad or badp: print(f'bank ${bk:02X} song {s:2d} sgb={sgb}: {len(bad)} reads off the parse {[hex(x) for x in bad[:5]]}, {len(badp)} look-aheads {[hex(x) for x in badp[:5]]}')
    for s in range(1,89):
        bad,badp,bads,r,sr,cur,pe=run(bk,cov,scov,B.pat_ends,0,'sfx',s,600); rs|=sr; total+=len(bads)
        if bads: print(f'bank ${bk:02X} SFX {s}: {len(bads)} reads off the parse {[hex(x) for x in bads[:5]]}')
    print(f'bank ${bk:02X}: {B.nsongs} songs x {FR} frames x (DMG, SGB), 88 SFX x 600 frames; '
          f'pattern events read {len(ra&starts)}/{len(starts)}, SFX events read {len(rs&sstarts)}/{len(sstarts)}, '
          f'look-aheads past an unterminated pattern {nend}')
print('TOTAL reads off the parse:',total)
