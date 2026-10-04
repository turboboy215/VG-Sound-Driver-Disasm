from pyboy import PyBoy
pb=PyBoy('h.gb',window='null',sound_emulated=False); M=pb.memory
ev=[]
def nh(ctx):
    # which voice? find return address: stack top inside SndRunVoice chain (no calls) 
    sp=pb.register_file.SP; ra=M[sp]|M[sp+1]<<8
    ev.append((pb.frame_count,'noise',{0x40B3:'CH4',0x40D4:'SFX'}.get(ra,hex(ra)),M[0xDFAC]))
pb.hook_register(4,0x41C7,nh,None)
for i in range(120): pb.tick()
def cmd(k,n,s):
    M[0xC001]=n;M[0xC002]=s;M[0xC000]=k
    while M[0xC000]: pb.tick()
cmd(1,11,0xF3)
for i in range(300): pb.tick()
f=pb.frame_count
cmd(2,12,0xE0)
for i in range(120): pb.tick()
for e in ev:
    if e[0]>=f-40: print(e)
