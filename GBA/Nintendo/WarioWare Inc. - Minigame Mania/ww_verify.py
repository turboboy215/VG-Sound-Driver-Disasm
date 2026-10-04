#!/usr/bin/env python3
"""Check the documented instrument / sample / pitch / volume / envelope model against the ROM's own driver.

  ww_verify.py ROM [N]      runs N songs with drum maps or key splits plus N random songs, 12 s each

At every voiceSetSample call (a sampled note-on) it compares the instrument and sample the driver chose with
ww_tool.Rom.resolve(bank, program, key), and the note frequency and pan offset. Every frame it recomputes
each playing voice's base step, step (bend, vibrato, random pitch), volume and envelope from the model.
Needs ww_tool.py and ww_emu.py next to it, and unicorn.
"""
import sys, os, collections, random
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import ww_tool, ww_emu
from unicorn import UC_HOOK_CODE
from unicorn.arm_const import UC_ARM_REG_R0, UC_ARM_REG_R1

NOTES, VOICES = 0x030021A8, 0x030020A8
stats = collections.Counter(); examples = collections.defaultdict(list)

def main():
    path = sys.argv[1]; N = int(sys.argv[2]) if len(sys.argv) > 2 else 25
    rom = ww_tool.Rom(path); raw = open(path, 'rb').read()
    FREQ = [rom.u16(0x083FD1CC + 2 * k) for k in range(128)]
    T = [rom.u32(0x083FD2CC + 4 * q) for q in range(14)]
    s16 = lambda x: x - 65536 if x > 32767 else x
    s8 = lambda x: x - 256 if x > 127 else x
    cur = {'bank': 0}; last = {}

    def on_set_sample(u, addr, size, e):
        i = u.reg_read(UC_ARM_REG_R0); hdr = u.reg_read(UC_ARM_REG_R1)
        n = NOTES + 32 * i
        key = e.r8(n) >> 1; ch = e.r32(n + 0xC); prog = (e.r16(ch) >> 2) & 0x7F
        tr = s8(e.r8(e.r32(n + 8) + 1))
        ins, k, pan = rom.resolve(cur['bank'], prog, key)
        ok = ins is not None and ins['addr'] == e.r32(n + 4) and ins['ptr'] == hdr
        stats['note-on: instrument and sample'] += 1
        if not ok:
            stats['note-on: instrument MISMATCH'] += 1; examples['inst'].append((cur['bank'], prog, key)); return
        if not e.r8(ch + 0x1C):                                   # no random key
            f = e.r32(n) >> 15; kk = k if pan is not None else key + tr
            stats['note-on: frequency'] += 1
            if f != FREQ[kk]: stats['note-on: frequency MISMATCH'] += 1
            stats['note-on: pan offset'] += 1
            if s16(e.r16(n + 0x18)) != (pan or 0): stats['note-on: pan offset MISMATCH'] += 1

    def per_frame(e, f):
        for i in range(8):
            n = NOTES + 32 * i; v = VOICES + 32 * i
            if not (e.r8(n) & 1) or not (e.r8(v) & 1): continue
            ins = rom.inst(e.r32(n + 4)); s = rom.sample(rom.sample_index(ins['ptr']))
            base = ((s['rate'] << 28) + FREQ[s['root']] * 13379 - 1) // (FREQ[s['root']] * 13379)
            stats['frame: base step'] += 1
            if e.r32(v + 0x1C) != base: stats['frame: base step MISMATCH'] += 1
            ch = e.r32(n + 0xC); syn = e.r32(n + 8); pf = e.r32(n) >> 15
            bend = e.r16(ch + 8) & 0x3FFF; lfo = s8(e.r8(ch + 0xD)); lfotype = (e.r8(ch + 7) >> 4) & 3
            rp = e.r16(ch + 0x1A)
            if e.r16(syn + 4) == 0:                               # synth tune is 0 in all songs
                if bend != 0x2000:
                    b = bend; span = s16(e.r16(n + 0x10)) if b < 0x2000 else s16(e.r16(n + 0x12))
                    if b < 0x2000: pf -= span
                    else: b -= 0x2000
                    q, r = divmod(b, 682)
                    pf += (span * (T[q] + (T[q + 1] - T[q]) * r // 682)) >> 16
                if lfotype == 0: pf += (lfo * s16(e.r16(n + 0x14))) >> 5
                if rp != 0x100: pf = pf * rp >> 8
                stats['frame: step (bend, vibrato, random pitch)'] += 1
                if e.r32(v + 0x18) != (base * (pf & 0xFFFFFFFF) >> 14) & 0xFFFFFFFF:
                    stats['frame: step MISMATCH'] += 1
            gain = (e.r32(ch + 8) >> 14) & 0x7F; vel = e.r8(n + 1) & 0x7F
            env = e.r32(n + 0x1C); state, lvl = env & 0xFF, env >> 8
            key = (i, e.r32(n + 4), e.r8(n)); pos = e.r32(v + 0xC)
            if key in last and last[key][2] == f - 1 and pos >= last[key][3]:
                pst, plv = last[key][:2]
                stats['frame: volume'] += 1
                if e.r8(v + 1) != gain * vel * (plv >> 16) >> 14: stats['frame: volume MISMATCH (re-struck note)'] += 1
                L, st = plv, pst
                if st == 0:
                    L += ins['attack']
                    if L > 0x7EFFFF: L, st = 0x7F0000, 1
                elif st == 1:
                    L -= ins['decay']
                    if L <= ins['sustain']: L, st = ins['sustain'], 2
                else:
                    L -= ins['sustain_rate'] if st == 2 else ins['release'] if (st == 3 or ins['release']) else 0x60000
                    if st == 2 and L > 0x7EFFFF: L = 0x7F0000
                    elif L <= 0: L = 0
                if state != pst and state in (3, 4): stats['frame: envelope (released this frame, skipped)'] += 1
                else:
                    stats['frame: envelope'] += 1
                    if (state, lvl) != (st, L): stats['frame: envelope MISMATCH (re-struck note)'] += 1
            last[key] = (state, lvl, f, pos)

    ids = {}
    for sid in range(rom.u32(ww_tool.ID_TABLE)):
        ent = rom.u32(ww_tool.ID_TABLE + 4 + 8 * sid)
        if ent: ids.setdefault(ent, sid)
    songs = [rom.song(k) for k in range(ww_tool.NSONGS)]
    special = []
    for s in songs:
        div, tracks = ww_tool.parse_smf(rom.midi_bytes(s['midi']))
        progs = {pl[0] for tb in tracks for t, st, pl in ww_tool.track_events(tb) if st < 0xF0 and st & 0xF0 == 0xC0}
        b = rom.bank(s['bank'])
        if {rom.inst(b[p])['type'] for p in progs if p < len(b) and b[p]} & {'R', 'S'}: special.append(s)
    random.seed(7)
    sel = special[:N] + random.sample(songs, N)
    for s in sel:
        cur['bank'] = s['bank']
        e = ww_emu.Emu(raw)
        e.u.hook_add(UC_HOOK_CODE, on_set_sample, e, 0x080F1560, 0x080F1560)
        ww_emu.render(raw, ids[s['addr']], 12, per_frame, emu=e)
    print('%d songs (%d with drum maps / key splits), 12 s each' % (len(sel), len(special[:N])))
    for k, v in sorted(stats.items()): print('  %-52s %7d' % (k, v))

if __name__ == '__main__':
    main()
