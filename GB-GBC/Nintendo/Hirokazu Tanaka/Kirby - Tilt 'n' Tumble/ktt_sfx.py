"""SFX half of the Kirby Tilt 'n' Tumble sound driver (banks $11 and $14).

Built like the Link's Awakening DX SFX bank (effects are code; per-slot init and per-frame jump
tables; shared register-image / counter / pitch helpers), but with four request slots, one per
channel, and a priority byte per effect instead of LA's hard-wired priority rules:
  wSfx1Request ($DE60) ch1     bank $11: $01-$7F   bank $14: $80-$97
  wSfx2Request ($DE70) ch2     bank $11: $01-$3F   bank $14: $80-$8F
  wSfx3Request ($DE80) ch3     bank $11: $01-$08   bank $14: $80-$87
  wSfx4Request ($DE78) ch4     bank $11: $01-$28   bank $14: $80-$90
A request starts when its priority is at least that of the slot's playing effect. Both banks run
every frame (bank $11 first); bank $14 clears the four requests afterwards.
New helpers: a software pitch sweep for ch1 / ch2 (NR10-style, computed on the wave period), and
register writers that skip zero bytes. Bank $11 is labelled by hand; bank $14 holds a relocated
copy of the same helper library and gets its names by alignment."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
for p in ('', '../SMBDX', '../LADX', '../tools'):
    sys.path.insert(0, os.path.join(HERE, p))
from gbdis import Region, decode
import ladx_sfx as LS
from transfer import align
from ktt_music import RAM as MUSIC_RAM

RAM = dict(MUSIC_RAM)

T11 = {1: (0x4100, 0x41fe, 127), 2: (0x42fc, 0x437a, 63), 3: (0x43f8, 0x4408, 8), 4: (0x4418, 0x4468, 40)}
T14 = {1: (0x4100, 0x4130, 24), 2: (0x4160, 0x4180, 16), 3: (0x41a0, 0x41b0, 8), 4: (0x41c0, 0x41e2, 17)}

NAMES_11 = {
 0x4009: 'Sfx_Init', 0x400c: 'Sfx_Init.clear', 0x401f: 'Sfx_Init.regs', 0x4026: 'Sfx_Init.copy', 0x402e: 'Sfx_Init.done',
 0x4033: 'Sfx_InitRegs', 0x4060: 'Sfx_Update', 0x407a: 'Sfx_Update.restartSong', 0x4086: 'Sfx_Update.noPcm', 0x4092: 'Sfx_Update.slots',
 0x4100: 'Sfx1_InitTable', 0x41fe: 'Sfx1_PlayTable', 0x42fc: 'Sfx2_InitTable', 0x437a: 'Sfx2_PlayTable',
 0x43f8: 'Sfx3_InitTable', 0x4408: 'Sfx3_PlayTable', 0x4418: 'Sfx4_InitTable', 0x4468: 'Sfx4_PlayTable',
 0x44b8: 'SfxNoteTable_Unused',
 0x788d: 'SetRegsSkip0_Ch1', 0x7896: 'SetRegsSkip0_Ch2', 0x789f: 'SetRegsSkip0_Ch3_Unused', 0x78a8: 'SetRegsSkip0_Ch4',
 0x78b1: 'SetRegsSkip0_Copy', 0x78b6: 'SetRegsSkip0_Copy.next', 0x78bd: 'Sfx1_Update', 0x78df: 'Sfx1_Update.start', 0x78e9: 'Sfx1_Refuse', 0x78ed: 'Sfx1_Continue', 0x78f0: 'Sfx1_Continue.playing',
 0x78fa: 'Sfx1_Dispatch',
 0x7904: 'Sfx1_StartVar_Unused', 0x7909: 'Sfx1_Start', 0x790f: 'Sfx1_StartSweep', 0x7915: 'Sfx1_Take',
 0x7933: 'Sfx1_StopSilent', 0x793d: 'Sfx1_Stop', 0x7943: 'Sfx1_Release', 0x7966: 'Sfx1_StopRegs',
 0x796c: 'Sfx1_WritePeriod_Unused', 0x7976: 'Sfx2_WritePeriod_Unused', 0x7980: 'SetRegsPartial_Ch1',
 0x798a: 'SetRegsPartial_Ch1.nr11', 0x7990: 'SetRegsPartial_Ch1.nr12', 0x7996: 'SetRegsPartial_Ch1.nr13',
 0x799f: 'Sfx2_Update', 0x79c5: 'Sfx2_Update.start', 0x79cf: 'Sfx2_Refuse', 0x79d3: 'Sfx2_Continue', 0x79d6: 'Sfx2_Continue.playing',
 0x79e0: 'Sfx2_Dispatch',
 0x79ea: 'Sfx2_Start', 0x79f0: 'Sfx2_StartSweep', 0x79f6: 'Sfx2_Take', 0x7a14: 'Sfx2_Stop', 0x7a1a: 'Sfx2_Release',
 0x7a2d: 'Sfx2_StopRegs', 0x7a32: 'SetRegsPartial_Ch2_Unused', 0x7a3c: 'SetRegsPartial_Ch2_Unused.nr22', 0x7a42: 'SetRegsPartial_Ch2_Unused.nr23',
 0x7a4b: 'Sfx3_Update', 0x7a71: 'Sfx3_Update.start', 0x7a7b: 'Sfx3_Refuse', 0x7a7f: 'Sfx3_Continue', 0x7a82: 'Sfx3_Continue.playing',
 0x7a8c: 'Sfx3_Dispatch',
 0x7a96: 'Sfx3_Start', 0x7a9c: 'Sfx3_StartSweep_Unused', 0x7aa2: 'Sfx3_Take', 0x7ab8: 'Sfx3_Stop', 0x7abe: 'Sfx3_Release',
 0x7ad9: 'Sfx3_StopRegs', 0x7adf: 'Sfx3_LoadWave', 0x7ae5: 'Sfx3_LoadWave.loop',
 0x7aef: 'Sfx4_Update', 0x7b15: 'Sfx4_Update.start', 0x7b1f: 'Sfx4_Refuse', 0x7b23: 'Sfx4_Continue', 0x7b26: 'Sfx4_Continue.playing',
 0x7b30: 'Sfx4_Dispatch',
 0x7b3a: 'Sfx4_Start', 0x7b52: 'Sfx4_Stop', 0x7b58: 'Sfx4_Release', 0x7b71: 'Sfx4_StopRegs', 0x7b76: 'Sfx4_WriteNR43_Unused',
 0x7b80: 'SetRegsPartial_Ch4', 0x7b8a: 'SetRegsPartial_Ch4.nr42', 0x7b90: 'SetRegsPartial_Ch4.nr43', 0x7b99: 'SetRegsPartial_Ch4.frames',
 0x7b9c: 'GetPointer', 0x7ba9: 'Sfx_DecTimer', 0x7bad: 'Sfx_IncStep',
 0x7bb1: 'SetRegs_Ch1', 0x7bba: 'SetRegs_Ch2', 0x7bc3: 'SetRegs_Ch3', 0x7bcc: 'SetRegs_Ch4', 0x7bd5: 'SetRegs_Copy',
 0x7bde: 'Sfx1_DecCounter', 0x7be4: 'Sfx2_DecCounter', 0x7bea: 'Sfx3_DecCounter', 0x7bf0: 'Sfx4_DecCounter_Unused', 0x7bf6: 'Sfx_DecCounter',
 0x7bfb: 'Sfx1_LoadPitch', 0x7c01: 'Sfx3_LoadPitch', 0x7c05: 'Sfx_LoadPitch', 0x7c14: 'Sfx2_LoadPitch',
 0x7c25: 'Sfx1_AddPitch', 0x7c2f: 'Sfx3_AddPitch', 0x7c39: 'Sfx_AddPitch', 0x7c55: 'Sfx2_AddPitch',
 0x7c5f: 'Sfx1_SweepStart', 0x7c88: 'Sfx1_Sweep', 0x7c9a: 'Sfx1_Sweep.step', 0x7cc1: 'Sfx1_Sweep.shift', 0x7cc8: 'Sfx1_Sweep.sign', 0x7cd4: 'Sfx1_Sweep.add',
 0x7ce6: 'Sfx2_SweepStart', 0x7d04: 'Sfx2_Sweep', 0x7d16: 'Sfx2_Sweep.step', 0x7d3d: 'Sfx2_Sweep.shift', 0x7d44: 'Sfx2_Sweep.sign', 0x7d50: 'Sfx2_Sweep.add',
 0x7d62: 'Sfx3_SweepStart_Unused', 0x7d82: 'Sfx3_Sweep_Unused', 0x7d94: 'Sfx3_Sweep_Unused.step', 0x7dbb: 'Sfx3_Sweep_Unused.shift',
 0x7dc2: 'Sfx3_Sweep_Unused.sign', 0x7dce: 'Sfx3_Sweep_Unused.add',
 0x7de0: 'SfxPriorityTable',
 0x7f0f: 'Sound_Stop',
}
UNUSED_CODE_11 = ((0x789f, 0x78a8), (0x7904, 0x7909), (0x796c, 0x7980), (0x7a32, 0x7a4b), (0x7a9c, 0x7aa2), (0x7b76, 0x7b80), (0x7bf0, 0x7bf6),
                  (0x7d62, 0x7de0))
HELPERS_11 = (0x788d, 0x7f9c)
STOPREGS = {'Sfx1_StopRegs': 6, 'Sfx2_StopRegs': 5, 'Sfx3_StopRegs': 6, 'Sfx4_StopRegs': 5}

COMMENTS_11 = {
 0x4000: 'Entry points (same order as the music banks): init, stop, update.',
 0x4009: 'Clear $DE00-$DEFF, switch the APU on and write the register list Sfx_InitRegs (count,\nfirst register, values; 0 ends it). The only sound init the game calls (at boot).',
 0x4060: 'Called once per frame after both music banks, before bank $14. wPcmDone is set by the\nhome-bank PCM player when a sample ends (and by the game in a few other places): request\nslot-1 effect $53, and if a hurry jingle had been started (wHurryJingle) restart the song\nthat was playing, in hurry mode when wHurryJingle = 1. While wHurryJingle = 1 and no\nsample has just ended, effect $52 is requested every frame.',
 0x4100: 'effects $01-$7F',
 0x42fc: 'effects $01-$3F',
 0x43f8: 'effects $01-$08',
 0x4418: 'effects $01-$28',
 0x44b8: 'unreferenced: copy of the music note table (SMB DX used it for its "note" requests)',
 0x78bd: 'Slot 1: requests $01-$7F (bank $14: $80-$97). A request starts if its priority\n(SfxPriorityTable) is at least the playing effect\'s; otherwise it is dropped. Effects also\njump back in here to chain into another effect.',
 0x7904: 'unreferenced',
 0x788d: 'Like SetRegs_ChN, but a zero byte leaves its register alone (SMB DX\'s SetRegsSkip0).',
 0x789f: 'unreferenced',
 0x7909: 'Start a ch1 effect: take ch1 from the music (wCh1Flags bit 7), write hl = NR10-NR14 +\nframes.',
 0x790f: 'Same, with the software sweep (Sfx1_SweepStart) instead of the hardware NR10.',
 0x7933: 'NR12 = $11, retrigger, then release ch1.',
 0x793d: 'End a ch1 effect: write Sfx1_StopRegs, clear the slot (priority too) and the ch1 transpose\nbyte wChTranspose+0, NR10 = 8, give ch1 back to the music.',
 0x7966: 'NR10-NR14 + frames written by Sfx1_Stop',
 0x796c: 'unreferenced: write NR13/NR14 + frames (LA\'s Sfx1_WritePeriod)',
 0x7980: 'Like SetRegs_Ch1, but a zero NR10/NR11/NR12 byte leaves its register alone (NR13/NR14\nare always written). The ch2 / ch4 versions skip zeros in NR21/NR22 and NR41/NR42/NR44.',
 0x799f: 'Slot 2: requests $01-$3F (bank $14: $80-$8F).',
 0x7a32: 'unreferenced: SetRegsPartial for ch2',
 0x7a4b: 'Slot 3 (ch3, back from LA): requests $01-$08 (bank $14: $80-$87).',
 0x7ab8: 'End a ch3 effect and tell the music to reload its wave (wReloadWave).',
 0x7adf: 'Copy 16 bytes at hl to wave RAM (ch3 off first).',
 0x7aef: 'Slot 4: requests $01-$28 (bank $14: $80-$90).',
 0x7b76: 'unreferenced: write NR43/NR44 + frames',
 0x7b9c: 'hl = table, a = 1-based index: hl = table[a-1]',
 0x7ba9: 'de = timer: decrement (Z when it reaches 0). bc = step: increment, a = new step.',
 0x7bb1: 'Write a register image (b bytes from NRx0/NRx1) and store the following byte as the\nslot\'s timer.',
 0x7bde: 'Count down an effect\'s private counter; Z at 0.',
 0x7bfb: 'Copy the period of a register image (hl) into the effect\'s pitch variable.',
 0x7c25: 'Add a big-endian offset (table[step-1]) to the effect\'s period and write NRx3/NRx4.',
 0x7c5f: 'Software sweep, ch1. hl = image: byte 0 is an NR10-style sweep byte (bits 5-4 period in\nframes, bit 3 down, bits 2-0 shift); bytes 1-4 go to NR11-NR14 (NR10 = 8), byte 5 = frames.',
 0x7c88: 'Every <period> frames: period += (($7FF - period) >> shift), negated when bit 3 is set.\nThe step is a fraction of 2048 - period, i.e. of the wave length, so the glide is even in\npitch like the hardware sweep but computed the other way round.',
 0x7d62: 'unreferenced: the same sweep for ch3',
 0x7de0: 'Priority of every effect, one table for both SFX banks: slot 1 $01-$97, slot 2 $01-$8F,\nslot 3 $01-$87, slot 4 $01-$90. Bank $11 reads the entries up to $7F, bank $14 the rest.',
 0x7f0f: 'Stop everything: music and effects, panning, fades; mute.',
}

PRIO = [(1, 151), (2, 79), (3, 16), (4, 57)]


def sfx_cfg(names, helpers, unused, tables, notetab, prio, sid, dummy=()):
    F = LS.Cfg()
    inv = {n: a for a, n in names.items()}
    g = lambda n: inv[n]
    F.STEP6 = {g('SetRegs_Ch1'), g('SetRegs_Ch3'), g('Sfx1_Start'), g('Sfx3_Start'), g('Sfx1_StartSweep'), g('Sfx1_SweepStart'),
               g('Sfx2_StartSweep'), g('Sfx2_SweepStart'), g('SetRegsPartial_Ch1')}
    F.STEP5 = {g('SetRegs_Ch2'), g('SetRegs_Ch4'), g('Sfx2_Start'), g('Sfx4_Start'), g('SetRegsPartial_Ch4')}
    F.FMT3 = set()
    F.FMTBE = {g('Sfx1_AddPitch'), g('Sfx2_AddPitch'), g('Sfx3_AddPitch'), g('Sfx_AddPitch')}
    F.FMTWAVE = {g('Sfx3_LoadWave')}
    F.PITCH = {g('Sfx1_LoadPitch'), g('Sfx2_LoadPitch'), g('Sfx3_LoadPitch')}
    F.GETPTR = g('GetPointer')
    F.SHARED = {a for a in names if helpers[0] <= a < helpers[1]} | set(dummy)
    F.NAMES = names
    F.DUMMY = set(dummy)
    F.sfx_id = sid
    return F


def build_11(rom):
    r = Region(rom, 0x11, 0x4000, 0x8000)
    r.ram = dict(RAM)
    r.trace([0x4000, 0x4003, 0x4006])
    tables = {ch: (r.jumptable(i, n), r.jumptable(p, n)) for ch, (i, p, n) in T11.items()}
    for a, b in UNUSED_CODE_11: r.code_range(a, b)
    for a, n in NAMES_11.items(): r.label(a, n)
    stopregs(r, NAMES_11)
    return r, tables


def stopregs(r, names):
    for a, n in names.items():
        if n in STOPREGS:
            r.block(a, STOPREGS[n], lambda rr, a, k=STOPREGS[n]: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(k))])


def common_blocks(r, notetab, prio_base, pr_names):
    r.block(0x4033, 0x2d, lambda rr, a: ['\tdb $10, LOW(_AUD3WAVERAM)\t; wave RAM: 16 bytes', '\tds 16, 0',
                                         '\tdb $05, LOW(rNR10), $08, $c0, $00, $00, $80',
                                         '\tdb $04, LOW(rNR21), $c0, $00, $00, $80',
                                         '\tdb $05, LOW(rNR30), $00, $00, $00, $00, $00',
                                         '\tdb $04, LOW(rNR41), $00, $00, $00, $80', '\tdb $00'])
    r.block(notetab, 146, lambda rr, a: [f'\tdw ${rr.word(a+2*i):04x}' for i in range(73)])
    for a in [x for x in r.labels if notetab < x < notetab + 146]: del r.labels[a]
    a = prio_base
    for slot, n in PRIO:
        lo = 1
        r.label(a, 'SfxPriorityTable' if slot == 1 else f'SfxPriorityTable_Slot{slot}')
        def em(rr, a, n=n, slot=slot):
            out = []
            for i in range(0, n, 16):
                out.append('\tdb ' + ', '.join(f'${rr.byte(a+j):02x}' for j in range(i, min(i+16, n))) + f'\t; slot {slot}: ${i+1:02x}-${min(i+16, n):02x}')
            return out
        r.block(a, n, em)
        for x in [x for x in r.labels if a < x < a + n]: del r.labels[x]
        a += n


def finish_bank(r, datarefs, F, lo, hi):
    zero_start = max(pc + r.code[pc][0] for pc in r.code if pc < 0x4100)
    r.block(zero_start, 0x4100 - zero_start, lambda rr, a: [f'\tds $4100 - ${a:04X}, 0\t; unused'])
    LS.make_spans(r, datarefs, lo, hi, F)
    last = max(pc + r.code[pc][0] for pc in r.code)
    last = max(last, max(b + s for b, (s, e) in r.blocks.items()))
    if last < 0x8000:
        r.block(last, 0x8000 - last, lambda rr, a: [f'\tds $8000 - ${a:04X}, 0\t; unused'])


def generate_11(rom):
    F = sfx_cfg(NAMES_11, HELPERS_11, UNUSED_CODE_11, T11, 0x44b8, 0x7de0, lambda ch, i: i)
    F.build = build_11
    F.COMMENTS = COMMENTS_11
    r, tables, entries, datarefs = LS.generate(rom, F)
    common_blocks(r, 0x44b8, 0x7de0, None)
    for a, b in UNUSED_CODE_11: r.comments.setdefault(a, 'unreferenced')
    finish_bank(r, datarefs, F, 0x4100, 0x7f0f)
    return r, tables, entries, datarefs


def generate_14(rom, r11):
    # names: align the helper library of bank $14 against bank $11's
    rr = Region(rom, 0x14, 0x4000, 0x8000)
    rr.trace([0x4000, 0x4003, 0x4006])
    tabs = {ch: (rr.jumptable(i, n), rr.jumptable(p, n)) for ch, (i, p, n) in T14.items()}
    pcmap, valmap, m, ns, nd = align(r11, rr, HELPERS_11[0], HELPERS_11[1], 0x5afe, 0x8000)
    p0, v0, m0, _, _ = align(r11, rr, 0x4000, 0x40a3, 0x4000, 0x4100)
    def shift(a):
        cand = [x for x in pcmap if x <= a]
        p = max(cand) if cand else min(pcmap)
        return a + pcmap[p] - p
    names = {}
    def shift_prev(a):
        c = [x for x in pcmap if x < a]
        p = max(c) if c else min(pcmap)
        return a + pcmap[p] - p
    for a, n in sorted(NAMES_11.items()):
        if HELPERS_11[0] <= a < HELPERS_11[1]:
            b = pcmap.get(a)
            if b is None or b in names: b = shift_prev(a)
            assert rom[0x11*0x4000 + a - 0x4000] == rom[0x14*0x4000 + b - 0x4000], (n, hex(a), hex(b))
            names[b] = n
        elif a < 0x4060:
            names[a] = n
    names.update({0x4060: 'Sfx_Update', 0x4204: 'SfxNoteTable_Unused',
                  0x4100: 'Sfx1_InitTable', 0x4130: 'Sfx1_PlayTable', 0x4160: 'Sfx2_InitTable', 0x4180: 'Sfx2_PlayTable',
                  0x41a0: 'Sfx3_InitTable', 0x41b0: 'Sfx3_PlayTable', 0x41c0: 'Sfx4_InitTable', 0x41e2: 'Sfx4_PlayTable'})
    gp = shift(0x7b9c)
    names[gp] = 'GetPointer'; names[gp + 1] = 'GetPointer0'
    unused = [(shift(a), shift(a) + b - a) for a, b in UNUSED_CODE_11 if a >= HELPERS_11[0]]
    helpers = (shift(HELPERS_11[0]), 0x8000)
    prio = shift(0x7de0)
    stop = shift(0x7f0f)
    comments = {}
    for a, t in COMMENTS_11.items():
        if HELPERS_11[0] <= a < HELPERS_11[1]: comments[pcmap.get(a, shift(a))] = t
        elif a < 0x4060: comments[a] = t
    comments.update({
     0x4060: 'Called once per frame after bank $11: the four slots for effects $80 and up, then clear\nthe requests.',
     0x4100: 'effects $80-$97 (indexed from 0: request & $7F)', 0x4160: 'effects $80-$8F', 0x41a0: 'effects $80-$87', 0x41c0: 'effects $80-$90',
     0x4204: 'unreferenced: copy of the music note table',
     gp: 'hl = table, a = 1-based index: hl = table[a-1]. GetPointer0 (the dispatchers): a = 0-based.',
    })
    for ch, nm in ((1, 'Sfx1'), (2, 'Sfx2'), (3, 'Sfx3'), (4, 'Sfx4')):
        a = shift({1: 0x78bd, 2: 0x799f, 3: 0x7a4b, 4: 0x7aef}[ch])
        comments[a] = f'Slot {ch}: requests ' + {1: '$80-$97', 2: '$80-$8F', 3: '$80-$87', 4: '$80-$90'}[ch] + ' (bank $11 handles the ones below $80).'
    dead = []
    def build_14(rom):
        r = Region(rom, 0x14, 0x4000, 0x8000)
        r.ram = dict(RAM)
        r.trace([0x4000, 0x4003, 0x4006])
        tables = {ch: (r.jumptable(i, n), r.jumptable(p, n)) for ch, (i, p, n) in T14.items()}
        for a, n in names.items(): r.label(a, n)
        stopregs(r, names)
        # helpers no effect of this bank uses are not reached by the trace: decode them too
        cov = set()
        for pc, d in r.code.items(): cov.update(range(pc, pc + d[0]))
        for b, (sz, e) in r.blocks.items(): cov.update(range(b, b + sz))
        a = helpers[0]
        while a < prio:
            if a in cov: a += 1; continue
            b = a
            while b < prio and b not in cov: b += 1
            pc = a
            while pc < b:
                pc += decode(rom, 0x14*0x4000 + pc - 0x4000, pc)[0]
            if pc == b:
                r.code_range(a, b); dead.append((a, b))
            a = b
        return r, tables
    F = sfx_cfg(names, helpers, unused, T14, 0x4204, prio, lambda ch, i: 0x7f + i)
    F.GETPTR = gp
    F.build = build_14
    F.COMMENTS = comments
    r, tables, entries, datarefs = LS.generate(rom, F)
    common_blocks(r, 0x4204, prio, None)
    for a, b in dead:
        r.comments.setdefault(a, 'unreferenced in this bank')
        if a not in r.labels: r.label(a, f'Unused_{a:04X}')
    finish_bank(r, datarefs, F, 0x4100, stop)
    return r, tables, entries, datarefs, (m, ns, nd, m0)
