import sys; sys.path.insert(0,'../tools')
from mmxparse import Bank, classify, parse_sfx
from mmx_verify_notes import expected
from pyboy import PyBoy
R = open('../mmx2.gbc','rb').read()
ROM = '../out/MegaManXtreme2/harness/mmx2_harness.gbc'
def boot():
    p = PyBoy(ROM, window='null', sound_emulated=False, cgb=True)
    for f in range(300): p.tick()
    return p
def music(bank, sid, frames):
    p = boot(); got = {0: [], 5: [], 10: [], 15: []}
    def on_note(ctx):
        if p.memory[0xCD00] & 4: return
        got[p.memory[0xCD01]].append(p.register_file.B)
    p.hook_register(bank, 0x464F, on_note, None)
    p.memory[0xC003] = bank; p.memory[0xC002] = sid; p.memory[0xC001] = 1
    for f in range(frames): p.tick()
    p.stop(save=False)
    bk = Bank(bank, R); hdr = dict(bk.ids())[sid]; res = []
    for ci, ch in enumerate((0, 5, 10, 15)):
        n = len(got[ch]); e = expected(bk, bk.bew(hdr + 1 + 2*ci), ci, n)
        res.append('%d%s' % (n, '' if got[ch] == e[:n] else '!DIFF'))
    return res
bad = []
for bank in (2, 3):
    for sid, _ in classify(Bank(bank, R))[0]:
        r = music(bank, sid, 3600); print(bank, '%02X' % sid, r, flush=True)
        if any('DIFF' in x for x in r): bad.append((bank, sid))
print('music bad', bad)
# SFX
res = []
for bank in (2, 3):
    bk = Bank(bank, R); p = boot(); endptr = []
    p.hook_register(bank, 0x42D6, lambda c: endptr.append(p.memory[0xCD13] | p.memory[0xCD14] << 8), None)
    for sid, ptr in classify(bk)[1]:
        endptr.clear()
        ev, _ = parse_sfx(bk, ptr); ends = {a + 1 for a, e in ev.items() if e[0] == 'SEGEND'}
        p.memory[0xC003] = bank; p.memory[0xC002] = sid; p.memory[0xC001] = 1; p.tick(); p.tick()
        n = 0
        while p.memory[0xCD12] and n < 2000: p.tick(); n += 1
        res.append((bank, sid, n, bool(endptr) and endptr[-1] in ends))
print('sfx checked', len(res), 'bad', [r for r in res if not r[3]])
print('frames', {'%02X' % s: n for b, s, n, ok in res if b == 2})
