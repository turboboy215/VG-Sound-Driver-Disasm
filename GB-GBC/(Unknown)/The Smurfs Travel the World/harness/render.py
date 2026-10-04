import sys, wave, numpy as np
from pyboy import PyBoy
RET={0x4016:'CH1',0x4033:'SFX',0x4060:'CH2',0x407E:'CH3',0x40B3:'CH4',0x40D4:'SFX'}
def run(kind, num, speed, maxframes, until_loop=True, wav=None):
    pb=PyBoy('h.gb',window='null',sound_emulated=wav is not None)
    M=pb.memory
    loops={}
    writes=[]
    def le(ctx):
        sp=pb.register_file.SP; ra=M[sp]|M[sp+1]<<8
        loops.setdefault(RET.get(ra,hex(ra)),pb.frame_count)
    pb.hook_register(4,0x41BC,le,None)
    for i in range(120): pb.tick()
    M[0xC001]=num; M[0xC002]=speed; M[0xC000]=kind
    while M[0xC000]: pb.tick()
    loops.clear()
    f0=pb.frame_count
    audio=[]
    for i in range(maxframes):
        pb.tick()
        if wav is not None: audio.append(pb.sound.ndarray.copy())
        if kind==2 and M[0xDFAC]==0 and i>2:
            for j in range(30):
                pb.tick(); audio.append(pb.sound.ndarray.copy()) if wav is not None else None
            break
        if until_loop and len(loops)>=4: break
    n=pb.frame_count-f0
    if wav:
        a=np.concatenate(audio).astype(np.int16)*256
        w=wave.open(wav,'wb'); w.setnchannels(2); w.setsampwidth(2); w.setframerate(pb.sound.sample_rate); w.writeframes(a.tobytes()); w.close()
    pb.stop(save=False)
    return n,{k:v-f0 for k,v in loops.items()}
if __name__=='__main__':
    speeds={0:0xF3,1:0xF2,2:0xF3,4:0xF4,5:0xF3,9:0xEF,10:0xF3,12:0xF3}
    for s in range(13):
        n,l=run(1,s,speeds.get(s,0xF3),60*400)
        print('song',s,'frames',n,l)
