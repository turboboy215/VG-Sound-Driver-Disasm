import sys; sys.path.insert(0,'../tools')
from mmxparse import *
from pyboy import PyBoy
res = []
for bank in (2, 3, 4):
    bk = Bank(bank); mus, sfx = classify(bk)
    p = PyBoy('../out/MegaManXtreme/harness/mmx_harness.gbc', window='null', sound_emulated=False, cgb=True)
    endptr = []
    for f in range(300): p.tick()
    p.hook_register(bank, 0x42D6, lambda c: endptr.append(p.memory[0xCD13] | p.memory[0xCD14] << 8), None)
    for sid, ptr in sfx:
        endptr.clear()
        ev, _ = parse_sfx(bk, ptr)
        ends = sorted(a + 1 for a, e in ev.items() if e[0] == 'SEGEND')
        loop = bk.m(ptr) >> 7
        p.memory[0xC003] = bank; p.memory[0xC002] = sid; p.memory[0xC001] = 1
        p.tick(); p.tick()
        last = None; frames = 0
        for f in range(1500):
            ptrv = p.memory[0xCD13] | p.memory[0xCD14] << 8
            if p.memory[0xCD12] == 0: break
            last = ptrv; frames += 1
            p.tick()
        ended = p.memory[0xCD12] == 0
        ok = (ended and endptr and endptr[-1] in ends) or (not ended and loop)
        res.append((bank, sid, frames, ended, loop, ok))
        if not ended:
            p.memory[0xC002] = 0xF1; p.memory[0xC001] = 1; p.tick(); p.tick()
    p.stop(save=False)
bad = [r for r in res if not r[5]]
print('checked', len(res), 'bad', bad)
print('looping', [(b, '%02X' % s) for b, s, f, e, l, o in res if l])
print('frames bank2', {'%02X' % s: f for b, s, f, e, l, o in res if b == 2})
