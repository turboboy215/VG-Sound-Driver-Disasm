import sys; import os; sys.path.insert(0,os.path.join(os.path.dirname(os.path.abspath(__file__)),'..','tools'))
from pyboy import PyBoy
from pbparse import samples
S=samples()
def run(script, ticks=260):
    """script: {isr_tick: sample_id}. Returns per-ISR list of (tick, copied_ptr|None, slot1ptr, slot2ptr)"""
    pb=PyBoy(os.environ.get('PB_ROM','pb.gbc'),window='null',sound_emulated=False,cgb=True); pb.set_emulation_speed(0)
    m=pb.memory; rf=pb.register_file
    for _ in range(1000): pb.tick()
    tick=[0]; q=[]; log=[]; copied=[None]
    def on_isr(c):
        tick[0]+=1
        if tick[0] in script: q.append(script[tick[0]])
        if copied[0] is not None or tick[0]>1: pass
    def on_copy(c): copied[0]=(m[0xD0C3], rf.HL)   # at $32F6 hl=src
    def on_isr_end(c):
        log.append((tick[0], copied[0], m[0xD0C7]|m[0xD0C8]<<8 if m[0xD0C5] else None, m[0xD0CF]|m[0xD0D0]<<8 if m[0xD0CD] else None, m[0xD0C4], m[0xFF1A]))
        copied[0]=None
    def inject(c):
        if q:
            sid=q.pop(0); sp=rf.SP-2; m[sp]=0x8D; m[sp+1]=0x2F; rf.SP=sp; rf.A=sid; rf.PC=0x3095
    pb.hook_register(0,0x3189,on_isr,None)
    pb.hook_register(0,0x32F6,on_copy,None)
    pb.hook_register(0,0x3313,on_isr_end,None)
    pb.hook_register(0,0x2F8D,inject,None)
    t0=tick[0]
    for _ in range(ticks*2):
        if tick[0]>=ticks: break
        pb.tick()
    pb.stop(); return log
if __name__=='__main__':
    # Test 1: single sample 1 -> blocks start+16 .. ; count
    log=run({10:1},80)
    cp=[l for l in log if l[1]]
    s=S[1]; exp=[s['start']+16*k for k in range(1,99) if s['start']+16*k < s['end']]
    print('T1 sample1 copies',len(cp),'expected',len(exp), 'ptrs match:', [c[1][1] for c in cp]==exp, 'first',hex(cp[0][1][1]),'start',hex(s['start']),'lag ticks',cp[0][0]-10)
    # Test 2: queue. main=0 (prio4, 63 blk); slot1=1 (23 blk) at +3; slot2=2 (147 blk) at +6
    log=run({10:0, 13:1, 16:2},200)
    for l in log:
        if 9<=l[0]<=20 or 30<=l[0]<=40 or 70<=l[0]<=80: print(l[0], (hex(l[1][1]) if l[1] else '-'), hex(l[2]) if l[2] else '-', hex(l[3]) if l[3] else '-', 'prio',l[4])
