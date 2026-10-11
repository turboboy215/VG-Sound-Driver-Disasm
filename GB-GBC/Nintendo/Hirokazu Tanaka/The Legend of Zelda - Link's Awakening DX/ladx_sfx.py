"""SFX half of the Link's Awakening DX sound driver (bank $1F).

Three effect channels, each with an init table and a per-frame table indexed by the request:
  ch1 (wSfx1Request, square effects, may also use ch2)   65 effects
  ch3 (wSfx3Request, wave effects)                        35 effects
  ch4 (wSfx4Request, noise effects)                       64 effects
Effects are code: an init routine writes a register image and a frame count, the per-frame
routine counts frames down and writes the next image or adds a pitch offset."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
from ladx_music import RAM

SFX_RAM = {
 0xd3bc:'wSfx1Counter', 0xd3bd:'wSfxCounter2', 0xd3be:'wSfx3Counter', 0xd3bf:'wSfx4Counter',
 0xd3c0:'wSfx1Pitch', 0xd3c1:'wSfx1Pitch+1', 0xd3c2:'wSfx2Pitch', 0xd3c3:'wSfx2Pitch+1', 0xd3c4:'wSfx3Pitch', 0xd3c5:'wSfx3Pitch+1',
 0xd3c6:'wSfx1Priority', 0xd3c7:'wSfxPriority2', 0xd3c8:'wSfx3Priority', 0xd3c9:'wSfx4Priority',
 0xd3d6:'wSfx1Var2', 0xd3d7:'wSfx1Var3', 0xd3d8:'wSfx1Var4', 0xd3dc:'wSfxVarDC',
 0xd3e2:'wSfx1Var5', 0xd3e3:'wSfxVarE3', 0xd3e4:'wSfxVarE4', 0xd3e5:'wSfxVarE5',
 0xffa8:'hVolumeFadeOut', 0xffa9:'hVolumeLeft', 0xffaa:'hVolumeRight', 0xffab:'hVolumeFadeIn',
 0xfff2:'hSfx1Request', 0xfff3:'hSfx3Request', 0xfff4:'hSfx4Request',
 0xc50e:'wLowHealthBeep',
}

NAMES = {
 0x4009:'Sfx_Init', 0x400c:'Sfx_Init.clear', 0x401e:'Sfx_Update',
 0x4100:'Sfx1_InitTable', 0x4182:'Sfx1_PlayTable',
 0x4204:'Sfx1_Update', 0x4216:'Sfx1_Update.start', 0x421c:'Sfx1_Update.playing', 0x4223:'Sfx1_Update.dispatch',
 0x5395:'Sfx1_StartPriority', 0x539a:'Sfx1_Start', 0x53b5:'Sfx1_StopWithRegs', 0x53bb:'Sfx1_Stop', 0x53df:'Sfx1_WritePeriod',
 0x53e6:'Sfx1_Refuse',
 0x53ed:'Sfx3_Update', 0x53ff:'Sfx3_Update.start', 0x5405:'Sfx3_Update.playing', 0x540c:'Sfx3_Update.dispatch',
 0x541b:'Sfx3_InitTable', 0x5461:'Sfx3_PlayTable',
 0x62f3:'Sfx3_StartPriority', 0x62f8:'Sfx3_Start', 0x6327:'Sfx3_StopWithRegs', 0x632d:'Sfx3_Stop',
 0x635a:'Sfx3_LoadWave', 0x637e:'Sfx3_WritePeriod', 0x6385:'Sfx3_Refuse',
 0x63ec:'Sfx4_InitTable', 0x646c:'Sfx4_PlayTable',
 0x64ec:'Sfx4_Update', 0x6500:'Sfx4_Update.playing', 0x6508:'Sfx4_Update.dispatch', 0x6512:'Sfx4_Update.lowHealth',
 0x79e4:'Sfx4_StartPriority', 0x79e9:'Sfx4_Start', 0x7a01:'Sfx4_StopWithRegs', 0x7a07:'Sfx4_Stop', 0x7a20:'Sfx4_StopRegs', 0x53d9:'Sfx1_StopRegs', 0x6354:'Sfx3_StopRegs',
 0x7a25:'Sfx4_WriteNR43', 0x7a2c:'Sfx4_Refuse', 0x7a33:'Sfx4_StartWithCh2', 0x7a51:'Sfx4_StopWithCh2',
 0x7a64:'GetPointer', 0x7a71:'Sfx_DecTimer', 0x7a75:'Sfx_IncStep',
 0x7a79:'SetRegs_Ch1', 0x7a7f:'SetRegs_Ch2', 0x7a85:'SetRegs_Ch3', 0x7a8b:'SetRegs_Ch4', 0x7a91:'SetRegs_Copy',
 0x7a9a:'Sfx1_DecCounter', 0x7aa0:'Sfx2_DecCounter_Unused', 0x7aa6:'Sfx3_DecCounter', 0x7aac:'Sfx4_DecCounter', 0x7ab2:'Sfx_DecCounter',
 0x7ab7:'Sfx1_LoadPitch', 0x7abd:'Sfx3_LoadPitch', 0x7ac1:'Sfx_LoadPitch', 0x7ad0:'Sfx2_LoadPitch',
 0x7ae1:'Sfx1_AddPitch', 0x7aeb:'Sfx3_AddPitch', 0x7af5:'Sfx_AddPitch', 0x7b11:'Sfx2_AddPitch',
 0x7b5c:'Sound_Stop', 0x7f80:'Sound_Volume', 0x7f95:'Sound_Volume.right', 0x7f9e:'Sound_Volume.fadeIn',
 0x7fb4:'Sound_Volume.fadeInRight', 0x7fbe:'Sound_Volume.write', 0x7fd7:'Sound_Volume.req3', 0x7fe2:'Sound_Volume.req4',
 0x7fed:'Sound_Volume.done',
}
SHARED = {a for a in NAMES if a >= 0x7a00 or a in (0x5395, 0x539a, 0x53b5, 0x53bb, 0x53df, 0x53e6, 0x62f3, 0x62f8, 0x6327, 0x632d,
          0x635a, 0x6347, 0x6360, 0x6365, 0x636a, 0x636f, 0x6374, 0x6379, 0x637e, 0x6385, 0x79e4, 0x79e9, 0x4204, 0x53ed, 0x64ec)}

COMMENTS = {
 0x4000: 'Entry points (same order as the music banks): init, stop, update.',
 0x4009: 'Clear $D300-$D3FF and switch the APU on (same routine as the music banks\').',
 0x401e: 'Called once per frame before the music banks: ch1, ch3 and ch4 effects, then clear\nthe SFX requests.',
 0x4204: 'Request 1 always starts; any other request is refused while a priority effect plays\n(wSfx1Priority).',
 0x5395: 'Start a ch1 effect: hl = 5 register bytes (NR10-NR14) + frames. The music channel is\nflagged as taken (wCh1Flags bit 7). Priority: later requests are refused until it ends.',
 0x53b5: 'End a ch1 effect: optionally write a register image first, then give ch1 back to the\nmusic.',
 0x53e6: 'A refused request is dropped and the playing effect continues.',
 0x53ed: 'Request $14 always starts; others are refused while a priority effect plays. Nothing\nruns while the music has paused the ch3 SFX (wCh3SfxPaused, command $96).',
 0x62f8: 'Start a ch3 effect: hl = NR30-NR34 + frames; the wave is loaded by the effect itself.',
 0x632d: 'End a ch3 effect and tell the music to reload its wave (wReloadWave).',
 0x64ec: 'With no ch4 effect playing, a non-zero wLowHealthBeep keeps requesting effect $1E.',
 0x79e9: 'Start a ch4 effect: hl = NR41-NR44 + frames.',
 0x7a33: 'Start a ch4 effect that also takes ch2 away from the music (wCh2Flags bit 7).',
 0x7a64: 'hl = table, a = 1-based index: hl = table[a-1]',
 0x7a71: 'de = timer: decrement (Z when it reaches 0). bc = step: increment, a = new step.',
 0x7a79: 'Write a register image (b bytes from NRx0/NRx1) and store the following byte as the new\ntimer ([de]).',
 0x7a9a: 'Count down an effect\'s private counter; Z at 0.',
 0x7ab7: 'Copy the period of a register image (hl) into the effect\'s pitch variable.',
 0x7ae1: 'Add a big-endian offset (table[step-1]) to the effect\'s period and write NRx3/NRx4.',
 0x7b5c: 'Stop everything: music, effects, panning; mute. The DX version ends with a write of 0\nto rP1 and then runs through $380 bytes of nop into Sound_Volume.',
 0x7c00: None,
 0x7f80: 'DX addition, called by the game every frame (and reached from Sound_Stop): master volume\nfades (hVolumeFadeOut / hVolumeFadeIn step NR50 down / up every 4 / 2 frames), then\ncopy the HRAM SFX requests into wSfx1Request / wSfx3Request / wSfx4Request.',
}


WAVES = [0x638c + 16*i for i in range(6)]


def build(rom):
    r = Region(rom, 0x1f, 0x4000, 0x8000)
    ram = dict(RAM); ram.update(SFX_RAM); r.ram = ram
    r.trace([0x4000, 0x4003, 0x4006, 0x7f80])
    I1 = r.jumptable(0x4100, 65); P1 = r.jumptable(0x4182, 65)
    I3 = r.jumptable(0x541b, 35); P3 = r.jumptable(0x5461, 35)
    I4 = r.jumptable(0x63ec, 64); P4 = r.jumptable(0x646c, 64)
    r.code_range(0x7aa0, 0x7aa6)     # unreferenced: counter for ch2
    for a, n in NAMES.items(): r.label(a, n)
    r.label(0x6311, 'Unused_6311', 'unreferenced')
    r.label(0x6347, 'Sfx3_CopyWave'); r.label(0x634a, 'Sfx3_CopyWave.loop')
    for w in WAVES:
        r.label(w, f'SfxWave_{w:04X}')
        r.block(w, 16, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(16))])
    for pc, (l, fmt, args, k) in r.code.items():
        if fmt.startswith('ld hl, ') and args[0][1] in WAVES and 0x6347 < pc < 0x6385:
            r.label(pc, f'Sfx3_LoadWave{args[0][1]:04X}')
    tables = {1: (I1, P1), 3: (I3, P3), 4: (I4, P4)}
    return r, tables


# consumers of `ld hl, X`: the routine that reads X decides the row size
STEP6 = {0x7a79, 0x7a85, 0x5395, 0x539a, 0x53b5, 0x62f3, 0x62f8, 0x6327}        # 5 registers + frames
STEP5 = {0x7a7f, 0x7a8b, 0x79e4, 0x79e9, 0x7a01, 0x7a33}                        # 4 registers + frames
FMT3 = {0x53df, 0x637e, 0x7a25}                                                 # 2 registers + frames
FMTBE = {0x7ae1, 0x7aeb, 0x7b11}                                                # big-endian period offsets
FMTWAVE = {0x635a, 0x6347, 0x6360, 0x6365, 0x636a, 0x636f, 0x6374, 0x6379}
PITCH = {0x7ab7, 0x7abd, 0x7ad0}                                                # register image (pitch read from it)


def owned(r, entries, shared):
    seen = set(); work = list(entries)
    while work:
        pc = work.pop()
        while pc not in seen and pc in r.code and pc not in shared:
            seen.add(pc)
            l, fmt, args, k = r.code[pc]
            if args and args[0][0] in ('rel', 'jp', 'call'):
                t = args[0][1]
                if t in r.code and t not in shared: work.append(t)
                if k in ('jr', 'jp'): break
            if k in ('ret', 'jphl'): break
            pc += l
    return seen


def consumer(r, pc, F=None):
    F = F or LA
    """first known routine reached after `ld hl, X` at pc (following jr/jp); (target, via GetPointer)"""
    q = pc + r.code[pc][0]; gp = False
    KNOWN = F.STEP6 | F.STEP5 | F.FMT3 | F.FMTBE | F.FMTWAVE | F.PITCH
    for _ in range(12):
        if q in KNOWN: return q, gp
        if q not in r.code: return None, gp
        l, fmt, args, k = r.code[q]
        if any(fmt.startswith(x) for x in ('ld hl', 'inc hl', 'dec hl', 'pop hl', 'add hl', 'ld h,', 'ld l,')) or '[hl+]' in fmt or '[hl-]' in fmt:
            return None, gp
        if args and args[0][0] in ('jp', 'call', 'rel'):
            t = args[0][1]
            if t == F.GETPTR: gp = True; q += l; continue
            if t in KNOWN: return t, gp
            if k in ('jr', 'jp'): q = t; continue
        if k in ('ret', 'jphl', 'jr', 'jp'): return None, gp
        q += l
    return None, gp


def name_effects(r, tables, F=None):
    F = F or LA
    shared = set(F.SHARED)
    entries = {}
    for ch, (I, P) in tables.items():
        for i, (a, b) in enumerate(zip(I, P)):
            sid = F.sfx_id(ch, i+1)
            if sid is None or (a in F.DUMMY and b in F.DUMMY): continue
            tag = f'Sfx{ch}_{sid:02X}'
            entries[tag] = (a, b)
            for e, kind in ((a, 'Init'), (b, 'Play')):
                if e in shared: continue
                if e not in r.labels: r.label(e, f'{tag}_{kind}')
    # code reachable from more than one effect becomes a shared routine named after its first user
    users = {}
    for tag, (a, b) in entries.items():
        for pc in owned(r, [a, b], shared):
            users.setdefault(pc, []).append(tag)
    owner = {}
    for tag, (a, b) in entries.items():
        k = 0
        own = sorted(owned(r, [a, b], shared))
        for pc in own:
            for t, v in r.code[pc][2]:
                if t in ('rel', 'jp', 'call') and v in r.code and v not in r.labels and v not in shared:
                    if len(set(users.get(v, [tag]))) > 1:
                        r.label(v, f'{tag}_Shared_{v:04X}')
                    else:
                        cands = [x for x in (a, b) if x <= v and r.labels.get(x, '').startswith(tag)]
                        if cands:
                            r.label(v, f'{r.labels[max(cands)]}.l{k}'); k += 1
                        else:
                            r.label(v, f'{tag}_Code_{v:04X}')
                if t in ('i16', 'a16') and r.inreg(v) and v not in r.code:
                    owner.setdefault(v, (tag, pc))
    return entries, owner


def rowsize(t, F=None):
    F = F or LA
    if t in F.STEP6: return 6
    if t in F.STEP5: return 5
    if t in F.FMT3: return 3
    if t in F.FMTBE: return 2
    if t in F.FMTWAVE: return 16
    if t in F.PITCH: return 6
    return 16


def make_spans(r, datarefs, lo, hi, F=None):
    starts = sorted(a for a in r.labels if lo <= a < hi and a not in r.code and r.block_of(a) is None)
    for s in starts:
        e = s + 1
        while e < hi and e not in r.code and e not in r.labels and r.block_of(e) is None: e += 1
        t, gp = datarefs.get(s, (None, False))
        if gp and (e - s) % 2 == 0:
            n = (e - s) // 2
            ents = [r.word(s + 2*i) for i in range(n)]
            if all(r.inreg(x) and x not in r.code for x in ents):
                r.block(s, e - s, lambda rr, a, n=n: ['\tdw ' + ', '.join(rr.sym_addr(rr.word(a+2*i)) for i in range(n))])
                continue
        rs = rowsize(t, F)
        def em(rr, a, size=e-s, rs=rs):
            out = []; i = 0
            while i < size:
                n = min(rs, size - i)
                out.append('\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(n)))
                i += n
            return out
        r.block(s, e - s, em)


def generate(rom, F=None):
    F = F or LA
    r, tables = F.build(rom)
    entries, owner = name_effects(r, tables, F)
    r.collect_refs()
    datarefs = {}
    for pc, (l, fmt, args, k) in r.code.items():
        if fmt.startswith('ld hl, ') and args[0][0] == 'i16' and r.inreg(args[0][1]) and args[0][1] not in r.code:
            datarefs[args[0][1]] = consumer(r, pc, F)
    # pointer tables: their entries are data rows of the same format
    for a, (t, gp) in list(datarefs.items()):
        if gp:
            k = 0
            while True:
                x = r.word(a + 2*k)
                if not r.inreg(x) or x in r.code or (k and a + 2*k in r.labels): break
                datarefs.setdefault(x, (t, False))
                if x not in r.labels:
                    tg = owner.get(a, (None,))[0]
                    r.label(x, f'{tg}_Data_{x:04X}' if tg else f'Data_{x:04X}')
                k += 1
                if k > 40: break
    for a, (tag, pc) in owner.items():
        if a not in F.NAMES and (a not in r.labels or r.labels[a].startswith('Data_')):
            r.label(a, f'{tag}_Data_{a:04X}')
    for a, t in F.COMMENTS.items():
        if t: r.comments[a] = t
    return r, tables, entries, datarefs


def finish(r, datarefs):
    r.block(0x4032, 0x4100 - 0x4032, lambda rr, a: ['\tds $4100 - $4032, 0\t; unused'])
    r.block(0x7c00, 0x380, lambda rr, a: ['\tREPT $380\t; nop slide from Sound_Stop into Sound_Volume', '\tnop', '\tENDR'])
    make_spans(r, datarefs, 0x4100, 0x7b5c, LA)
    r.block(0x7fee, 0x12, lambda rr, a: ['\tds $8000 - $7FEE, 0\t; unused'])


class Cfg:
    pass

LA = Cfg()
LA.STEP6, LA.STEP5, LA.FMT3, LA.FMTBE, LA.FMTWAVE, LA.PITCH = STEP6, STEP5, FMT3, FMTBE, FMTWAVE, PITCH
LA.GETPTR = 0x7a64
LA.SHARED, LA.NAMES, LA.COMMENTS = SHARED, NAMES, COMMENTS
LA.DUMMY = set()
LA.sfx_id = lambda ch, i: i
LA.build = build
