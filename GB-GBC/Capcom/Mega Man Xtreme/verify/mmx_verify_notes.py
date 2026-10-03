import sys; sys.path.insert(0,'../tools')
from mmxparse import *
from pyboy import PyBoy
OCT = [0x00,0x0C,0x18,0x24,0x30,0x3C,0x48,0x54,0x18,0x24,0x30,0x3C,0x48,0x54,0x60,0x6C]
def expected(bk, start, ch, n):
    ev, _ = parse_music(bk, start)
    pc = start; out = []; flags = 0; tr = 0; gtr = 0; slide = 0; prev = 0; cnt = {0x17: 0, 0x18: 0}; steps = 0
    CTR = {0x0E: 0x17, 0x0F: 0x18, 0x10: 0x17, 0x11: 0x17, 0x12: 0x17, 0x13: 0x18, 0x14: 0x17, 0x15: 0x17}
    while len(out) < n and steps < 200000:
        steps += 1
        e = ev[pc]
        if e[0] == 'NOTE':
            L, p = e[2], e[3]
            if flags & 0x10 and not (flags & 0x20): flags &= ~0x10
            if p:
                if ch == 3: b = ((flags & 0x0F) << 4) | p
                else:
                    b = p + OCT[flags & 0x0F] + gtr + tr
                    b &= 0xFF
                    if b >= 0x55: b = 0x54
                    note = b
                    if slide and prev and prev != note: b = prev
                    prev = note
                if not (flags & 0x80): out.append(b)
                flags = (flags & 0x7F) | ((flags & 0x40) << 1)
            pc += 1; continue
        c, args = e[2], e[3]
        if c == 0: flags ^= 0x20
        elif c == 1: flags ^= 0x40
        elif c == 2: flags |= 0x10
        elif c == 3: flags ^= 0x08
        elif c == 4: flags = (flags & 0x97) | args[0]
        elif c == 9: flags = (flags & 0xF8) | args[0]
        elif c == 0xA: gtr = (args[0] ^ 0x80) - 0x80
        elif c == 0xB: tr = (args[0] ^ 0x80) - 0x80
        elif c == 0xD: slide = args[0]
        elif 0x0E <= c <= 0x15:
            k = CTR[c]; t = args[1] << 8 | args[2]
            if c < 0x12:
                if cnt[k] == 0: cnt[k] = args[0]; pc = t; continue
                cnt[k] -= 1
                if cnt[k] == 0: pc += 4; continue
                pc = t; continue
            else:
                if cnt[k] == 1:
                    cnt[k] = 0; flags = (flags & 0x97) | args[0]; pc = t; continue
                pc += 4; continue
        elif c == 0x16: pc = args[0] << 8 | args[1]; continue
        elif c == 0x17: break
        pc += e[1]
    return out

def run(bank, sid, frames, rom='../out/MegaManXtreme/harness/mmx_harness.gbc'):
    p = PyBoy(rom, window='null', sound_emulated=False, cgb=True)
    got = {0: [], 5: [], 10: [], 15: []}
    def on_note(ctx):
        if p.memory[0xCD00] & 4: return   # SFX pass
        got[p.memory[0xCD01]].append(p.register_file.B)
    p.hook_register(bank, 0x464F, on_note, None)
    for f in range(300): p.tick()
    p.memory[0xC003] = bank; p.memory[0xC002] = sid; p.memory[0xC001] = 1
    for f in range(frames): p.tick()
    p.stop(save=False)
    bk = Bank(bank); hdr = bk.ids()[sid][1]
    res = []
    for ci, ch in enumerate((0, 5, 10, 15)):
        start = bk.bew(hdr + 1 + 2*ci)
        n = len(got[ch])
        e = expected(bk, start, ci, n)
        ok = got[ch] == e[:n]
        if not ok:
            k = next(i for i in range(n) if i >= len(e) or got[ch][i] != e[i])
            res.append('ch%d %d DIFF@%d got %s exp %s' % (ci+1, n, k, got[ch][k:k+4], e[k:k+4]))
        else: res.append('ch%d %d ok' % (ci+1, n))
    return res

if __name__ == '__main__':
    for bank in (2, 3, 4):
        mus, _ = classify(Bank(bank))
        for sid, _ in mus:
            print(bank, '%02X' % sid, run(bank, sid, int(sys.argv[1]) if len(sys.argv) > 1 else 2400), flush=True)
