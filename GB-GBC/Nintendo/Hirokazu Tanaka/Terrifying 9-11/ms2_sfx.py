"""SFX bank of Metal Slug 2 (unlicensed), bank $29.

This is the Link's Awakening DX SFX bank ($1F) reassembled: 3,304 of its 3,329 traced
instructions align with LA's (a few `jr` became `jp`), RAM moved from $D300 to $C800, and the
effect tables were renumbered (some LA effects dropped, others reordered). The names come from
the labelled LA bank via tools/transfer.py; every effect is tagged with its MS2 number and
the number of the LA effect it was copied from."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
import transfer
import ladx_sfx as LS

RAM_BASE = 0xc800
TABLES = ((1, 0x4018, 0x409a, 65), (3, 0x5368, 0x53ae, 35), (4, 0x633f, 0x63b9, 61))


def ms2_ram():
    from ladx_music import RAM
    ram = dict(RAM); ram.update(LS.SFX_RAM)
    return {a - 0xd300 + RAM_BASE: n for a, n in ram.items() if 0xd300 <= a < 0xd400}


def make_cfg(la_rom, rom):
    lr, ltabs, lents, _ = LS.generate(la_rom)
    r = Region(rom, 0x29, 0x4000, 0x8000)
    r.trace([0x4001])
    for ch, i, p, n in TABLES:
        r.jumptable(i, n); r.jumptable(p, n)
    old = transfer.JRJP; transfer.JRJP = True
    pcmap, valmap, m, ns, nd = transfer.align(lr, r)
    transfer.JRJP = old
    m2 = lambda s: {pcmap[a] for a in s if a in pcmap}
    helper = {pcmap[a]: n for a, n in LS.NAMES.items() if a in pcmap and a in lr.code}
    for a in (0x6347, 0x634a):
        if a in pcmap: helper[pcmap[a]] = lr.labels[a]
    helper.update({valmap[a]: n for a, n in LS.NAMES.items() if a in valmap and a not in lr.code
                   and not n.endswith(('Table',)) and a not in (0x6311,)})
    # LA effect each MS2 table entry was copied from
    la_tag = {}
    for tag, (a, b) in lents.items():
        if a in pcmap: la_tag.setdefault(pcmap[a], tag)
    F = LS.Cfg()
    F.STEP6, F.STEP5, F.FMT3 = m2(LS.STEP6), m2(LS.STEP5), m2(LS.FMT3)
    F.FMTBE, F.FMTWAVE, F.PITCH = m2(LS.FMTBE), m2(LS.FMTWAVE), m2(LS.PITCH)
    F.GETPTR = pcmap[0x7a64]
    F.NAMES = {a: n for a, n in helper.items() if not n.startswith('Sfx3_LoadWave6')}
    F.NAMES.update({0x4001: None})
    F.NAMES = {a: n for a, n in F.NAMES.items() if n}
    F.SHARED = {pcmap[a] for a in LS.SHARED if a in pcmap} | {a for a, n in F.NAMES.items() if a in r.code}
    F.COMMENTS = {}
    for a, t in LS.COMMENTS.items():
        b = pcmap.get(a, valmap.get(a))
        if t and b is not None: F.COMMENTS[b] = t
    F.DUMMY = set()
    F.sfx_id = lambda ch, i: i
    F.la_tag = la_tag
    F.stats = (m, ns, nd)

    def build(rom_):
        rr = Region(rom_, 0x29, 0x4000, 0x8000)
        rr.ram = ms2_ram()
        # table blocks first, so that code jumping into a table (see Sfx1_33) is not traced into it
        tables = {}
        for ch, i, p, n in TABLES:
            ents = ([rr.word(i + 2*k) for k in range(n)], [rr.word(p + 2*k) for k in range(n)])
            for t, e in ((i, ents[0]), (p, ents[1])):
                rr.block(t, 2*n, lambda r_, a, e=e: [f'\tdw {r_.sym_addr(x)}' for x in e])
            tables[ch] = ents
        rr.trace([0x4001] + [x for ch in tables for e in tables[ch] for x in e])
        for a, n in F.NAMES.items(): rr.label(a, n)
        rr.label(0x4018, 'Sfx1_InitTable'); rr.label(0x409a, 'Sfx1_PlayTable')
        rr.label(0x5368, 'Sfx3_InitTable'); rr.label(0x53ae, 'Sfx3_PlayTable')
        rr.label(0x633f, 'Sfx4_InitTable'); rr.label(0x63b9, 'Sfx4_PlayTable')
        return rr, tables
    F.build = build
    return F


def generate(la_rom, rom):
    F = make_cfg(la_rom, rom)
    r, tables, entries, datarefs = LS.generate(rom, F)
    r.code_range(0x645b, 0x6462)
    r.code_range(0x79da, 0x79e1)
    for a, n in {0x645a: 'Sfx4_Update.none', 0x645b: 'Unused_LowHealthBeep', 0x79d3: 'Sfx1_DecCounter',
                 0x79da: 'Sfx2_DecCounter_Unused', 0x79e1: 'Sfx3_DecCounter', 0x79e8: 'Sfx4_DecCounter', 0x79ec: 'Sfx_DecCounter',
                 0x43ef: 'Unused_43EF', 0x6264: 'Unused_6264', 0x4000: 'BankTag'}.items():
        r.label(a, n)
    r.comments[0x645a] = 'MS2 replaced LA\'s low-health check (wLowHealthBeep, $C50E) with this ret; the\nrequest code after it is unreferenced.'
    r.comments[0x43ef] = 'unreferenced'; r.comments[0x6264] = 'unreferenced (also unreferenced in LA)'
    r.comments[0x4000] = 'byte $1E: tag byte at the start of the bank (the music bank has $1D)'
    r.comments[0x7a56] = 'Stop everything: music, effects, panning; mute. Ends with LA DX\'s write of 0 to rP1.'
    # pointers copied from LA without relocation: they point at the LA addresses
    r.overrides[0x5d53] = {0: '$7a20'}
    r.eol[0x5d53] = "LA's Sfx4_StopRegs, not relocated: here $7A20 is inside Sfx1_AddPitch"
    r.overrides[0x5485] = {0: '$63cc'}
    r.eol[0x5485] = "LA's SfxWave_63CC, not relocated: here $63CC is inside Sfx4_PlayTable"
    targets = {r.word(0x702d + 2*i) for i in range(11)}
    code_refs = {v for pc, d in r.code.items() for t, v in d[2] if t == 'i16'}
    for x in targets:
        if x in r.labels and x not in code_refs and r.labels[x].startswith('Sfx4_2D_Data_'):
            del r.labels[x]
        datarefs.pop(x, None)
    datarefs.pop(0x702d, None)
    for pc, (l, fmt, args, k) in r.code.items():
        for i, (t, v) in enumerate(args):
            if t in ('jp', 'call') and r.block_of(v) is not None and v not in r.blocks:
                r.overrides.setdefault(pc, {})[i] = f'${v:04x}'
                r.eol[pc] = f"LA's address of Sfx1_StopWithRegs, not relocated: here ${v:04X} is inside a jump table"
                lbl = r.labels.get(v)
                if lbl: del r.labels[v]
    r.block(0x702d, 22, lambda rr, a: ['\tdw ' + ', '.join(f'${rr.word(a+2*i):04x}' for i in range(11))])
    r.comments[0x702d] = ("LA's table for this effect (LA Sfx4_2E), not relocated: the entries are LA addresses\n"
                          "and point at unrelated bytes here")
    for pc in [p for p in r.code if 0x7a1c < p < 0x7a2f]:
        if r.labels.get(pc, '').startswith('Code_'): del r.labels[pc]
    # each effect: which LA effect it was copied from
    for tag, (a, b) in entries.items():
        la = F.la_tag.get(a)
        if a in r.labels and r.labels[a].startswith(tag):
            r.comments[a] = (f'= LA {la}' if la and la != tag else ('same number in LA' if la else 'not in LA'))
    r.block(0x4000, 1, lambda rr, a: ['\tdb $1e'])
    LS.make_spans(r, datarefs, 0x4018, 0x7a56, F)
    return r, tables, entries, datarefs, F
