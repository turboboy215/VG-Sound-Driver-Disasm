#!/usr/bin/env python3
"""Decode every Krawall module/pattern found by kscan.py and validate the format
assumptions (sample signedness, loop modes, note packing, row counts, effects)."""
import sys, json, struct, collections

def u32(b, o): return struct.unpack_from('<I', b, o)[0]

def samples(rom, listoff, count):
    out = []
    for k in range(count):
        a = u32(rom, listoff + 4 * k) & 0x1FFFFFF
        ll, end, c2 = struct.unpack_from('<III', rom, a)
        ft, rn, vol, pan, loop, hq = struct.unpack_from('<bbBbBB', rom, a + 12)
        e = end & 0x1FFFFFF
        out.append(dict(addr=a, ll=ll, size=e - a - 18, c2=c2, ft=ft, rn=rn, vol=vol, pan=pan,
                        loop=loop, hq=hq, pad=rom[e:e + 69], data=rom[a + 18:e]))
    return out

def decode_pattern(rom, a, old, nsamp, packing):
    """packing: 'new', 'old_be' (note<<9|ins, hi byte first), 'old_tcrf' (ins<<7|note)"""
    rows = rom[a + 32] if old else struct.unpack_from('<H', rom, a + 32)[0]
    p = a + (0x21 if old else 0x22)
    start = p
    idx = struct.unpack_from('<16H', rom, a)
    cells = []
    row = 0
    bad = 0
    newrow = True
    while row < rows:
        if newrow and row % 4 == 0 and row // 4 < 16 and idx[row // 4] != p - start:
            bad += 1
        newrow = False
        f = rom[p]; p += 1
        if f == 0:
            row += 1; newrow = True; continue
        ch = f & 31
        note = ins = vol = eff = op = None
        if f & 32:
            b0, b1 = rom[p], rom[p + 1]; p += 2
            if packing == 'new':
                note, ins = b0, b1
                if note & 0x80:
                    ins |= rom[p] << 8; p += 1; note &= 0x7F
            elif packing == 'old_be':
                w = (b0 << 8) | b1
                note, ins = w >> 9, w & 0x1FF
            else:  # TCRF wording: high 9 bits instrument, low 7 bits note
                w = (b0 << 8) | b1
                ins, note = w >> 7, w & 0x7F
            if ins > nsamp: bad += 1
            if note not in range(0, 121) and note != 127: bad += 1
        if f & 64:
            vol = rom[p]; p += 1
        if f & 128:
            eff, op = rom[p], rom[p + 1]; p += 2
            if eff > 50: bad += 1
        cells.append((row, ch, note, ins, vol, eff, op))
        if len(cells) > 100000: bad += 1000; break
    return dict(rows=rows, len=p - start, bad=bad, cells=cells)

if __name__ == '__main__':
    rom = open(sys.argv[1], 'rb').read()
    scan = json.load(open(sys.argv[2]))
    old = sys.argv[3] == 'old'
    packings = ['new'] if not old else ['old_be', 'old_tcrf']
    sl = scan['sampleList']
    S = samples(rom, sl['off'], sl['count'])
    print(f"samples={len(S)}")
    print(" loop modes:", collections.Counter(s['loop'] for s in S))
    print(" hq flags:", collections.Counter(s['hq'] for s in S))
    print(" c2Freq top:", collections.Counter(s['c2'] for s in S).most_common(5))
    print(" ft/rn nonzero:", sum(1 for s in S if s['ft'] or s['rn']))
    print(" pan values:", collections.Counter(s['pan'] for s in S).most_common(5))
    unl = [s for s in S if s['loop'] == 0]
    print(f" unlooped pad all 0x80: {sum(1 for s in unl if set(s['pad']) == {0x80})}/{len(unl)}")
    lp = [s for s in S if s['loop'] == 1]
    ok = sum(1 for s in lp if s['pad'] == (s['data'][s['size'] - s['ll']:] * 80)[:69])
    print(f" fwd-loop pad == loop restart data: {ok}/{len(lp)}")
    print(f" loopLength>=512 for looped: {sum(1 for s in lp if s['ll'] >= 512)}/{len(lp)}")
    # signedness: mean of sample bytes
    allb = b''.join(s['data'][:4096] for s in S)
    import statistics
    print(f" mean byte (unsigned view) = {statistics.mean(allb):.1f} (128 => unsigned PCM, ~0/255 split => signed)")
    for pk in packings:
        tot = bad = 0
        effc = collections.Counter(); volc = collections.Counter(); notes = collections.Counter()
        maxins = 0
        for m in scan['modules']:
            for (pa, r) in m['patterns']:
                d = decode_pattern(rom, pa, old, len(S), pk)
                tot += 1; bad += (d['bad'] > 0)
                for c in d['cells']:
                    if c[5] is not None: effc[c[5]] += 1
                    if c[4] is not None: volc[c[4] >> 4] += 1
                    if c[2] is not None: notes[c[2]] += 1
                    if c[3]: maxins = max(maxins, c[3])
        print(f"[{pk}] patterns={tot} with-errors={bad} maxIns={maxins} noteRange={min(notes) if notes else None}..{max(notes) if notes else None} noteoff(127)={notes.get(127,0)}")
        print(f"   effects used: {sorted(effc.items())}")
        print(f"   volcol hi-nibble: {sorted(volc.items())}")
