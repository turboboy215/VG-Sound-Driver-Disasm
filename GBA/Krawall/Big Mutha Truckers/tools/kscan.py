#!/usr/bin/env python3
"""Independent Krawall data scanner (does not reuse Unkrawerter heuristics).
Finds sample lists, instrument lists and module headers in a GBA ROM."""
import sys, struct, json

def u32(b, o): return struct.unpack_from('<I', b, o)[0]
def u16(b, o): return struct.unpack_from('<H', b, o)[0]

def isptr(v, size):
    return (v & 0xFE000000) == 0x08000000 and (v & 0x1FFFFFF) < size

def sample_ok(rom, o):
    if o + 18 > len(rom): return None
    ll, end, c2 = struct.unpack_from('<III', rom, o)
    ft, rn, vol, pan, loop, hq = struct.unpack_from('<bbBbBB', rom, o + 12)
    if not isptr(end, len(rom)): return None
    e = end & 0x1FFFFFF
    size = e - (o + 18)
    if size <= 0 or size > 0x200000: return None
    if ll > size: return None
    if loop > 2 or hq > 1 or vol > 64: return None
    if c2 == 0 or c2 > 200000: return None
    if loop == 0 and ll != 0: return None
    return dict(off=o, loopLength=ll, size=size, c2Freq=c2, fineTune=ft, relNote=rn,
                vol=vol, pan=pan, loop=loop, hq=hq)

def instr_ok(rom, o, nsamp):
    if o + 302 > len(rom): return False
    smp = struct.unpack_from('<96H', rom, o)
    if max(smp) >= max(nsamp, 1) + 4096: return False
    for env in (o + 192, o + 244):
        mx, sus, ls, fl = rom[env + 48:env + 52]
        if mx > 11 or sus > 11 or ls > 11 or fl > 7: return False
    return True

def scan_ptr_lists(rom, minlen=2):
    n = len(rom)
    res = []
    i = 0
    while i < n - 4:
        if isptr(u32(rom, i), n):
            j = i
            while j < n - 4 and isptr(u32(rom, j), n): j += 4
            cnt = (j - i) // 4
            if cnt >= minlen: res.append((i, cnt))
            i = j
        else:
            i += 4
    return res

def find_sample_list(rom, lists):
    best = None
    for (o, c) in lists:
        good = 0
        for k in range(c):
            if sample_ok(rom, u32(rom, o + 4 * k) & 0x1FFFFFF): good += 1
            else: break
        if good >= 4 and (best is None or good > best[1]): best = (o, good)
    return best

def find_instr_list(rom, lists, nsamp, sample_list_off):
    best = None
    for (o, c) in lists:
        if o == sample_list_off: continue
        good = 0
        for k in range(c):
            a = u32(rom, o + 4 * k) & 0x1FFFFFF
            if instr_ok(rom, a, nsamp) and not sample_ok(rom, a): good += 1
            else: break
        if good >= 2 and (best is None or good > best[1]): best = (o, good)
    return best

def pattern_ok(rom, a, old):
    if a + 0x22 > len(rom): return None
    idx = struct.unpack_from('<16H', rom, a)
    if idx[0] != 0: return None
    rows = rom[a + 32] if old else u16(rom, a + 32)
    if rows == 0 or rows > 1024: return None
    # index must be non-decreasing for the populated part
    nidx = min(16, (rows + 3) // 4)
    for k in range(1, nidx):
        if idx[k] < idx[k - 1]: return None
    return rows

def module_at(rom, o, old):
    n = len(rom)
    if o + 0x170 > n: return None
    ch, nord, rst = rom[o], rom[o + 1], rom[o + 2]
    if not (1 <= ch <= 32) or nord == 0: return None
    order = rom[o + 3:o + 3 + 256]
    if any(order[nord:]): return None
    if rst >= nord and rst != 0: return None
    songidx = rom[o + 0x123:o + 0x163]
    if songidx[0] != 0: return None
    vg, spd, bpm = rom[o + 0x163], rom[o + 0x164], rom[o + 0x165]
    flags = rom[o + 0x166:o + 0x16C]
    if spd == 0 or bpm < 32: return None
    if any(f > 1 for f in flags[:5]) or flags[5] != 0: return None
    real = [x for x in order[:nord] if x < 254]
    if not real: return None
    npat = max(real) + 1
    pats = []
    for k in range(npat):
        p = u32(rom, o + 0x16C + 4 * k)
        if not isptr(p, n): return None
        r = pattern_ok(rom, p & 0x1FFFFFF, old)
        if r is None: return None
        pats.append((p & 0x1FFFFFF, r))
    # pan list beyond channels should be zero
    pan = struct.unpack_from('<32b', rom, o + 0x103)
    if any(pan[ch:]): return None
    return dict(off=o, channels=ch, numOrders=nord, songRestart=rst,
                order=list(order[:nord]), songIndex=[x for x in songidx],
                volGlobal=vg, speed=spd, bpm=bpm, flags=list(flags),
                npat=npat, patterns=pats, pan=list(pan[:ch]))

def scan_modules(rom, old):
    mods = []
    n = len(rom)
    # fast prefilter: order region tail of 0s; check every 4-aligned pos
    for o in range(0, n - 0x170, 4):
        c = rom[o]
        if c == 0 or c > 32: continue
        if rom[o + 1] == 0: continue
        if rom[o + 0x16B] != 0: continue
        if rom[o + 0x123] != 0: continue
        m = module_at(rom, o, old)
        if m: mods.append(m)
    return mods

if __name__ == '__main__':
    path = sys.argv[1]
    old = len(sys.argv) > 2 and sys.argv[2] == 'old'
    rom = open(path, 'rb').read()
    lists = scan_ptr_lists(rom)
    sl = find_sample_list(rom, lists)
    out = dict(rom=path)
    if sl:
        out['sampleList'] = dict(off=sl[0], count=sl[1])
        il = find_instr_list(rom, lists, sl[1], sl[0])
        if il: out['instrList'] = dict(off=il[0], count=il[1])
    mods = scan_modules(rom, old)
    out['modules'] = mods
    json.dump(out, open(sys.argv[3] if len(sys.argv) > 3 else '/dev/stdout', 'w'), default=int)
