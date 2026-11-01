"""Konami GB driver, third generation (Nemesis II): structured decode of the sound data.
Shared by gen_asm3 and the model. The command language differs from the earlier drivers:
  $FB / $FC   two loop levels: the first $FB marks the loop start, the next $FB n repeats n times
  $FD addr    call (one return slot); a bare $FD inside the subroutine returns
  $FE         first time: mark; next time: jump back to the mark (loop forever)
  $EB n xy    vibrato n with delay x units and depth y ($EB 0: off, two bytes)
  streams starting with $E1 are 'raw' streams: $E1 unit duty sweep, then 2-byte register frames.
A bank profile describes one bank's tables; a game profile lists its banks."""
import collections, os

def _rom(env, name, fallback):
    p = os.environ.get(env)
    if p: return p
    return name if os.path.exists(name) or not os.path.exists(fallback) else fallback

N2_ROM = _rom('KON_ROM_N2', 'Nemesis II - The Return of the Hero (E) [!].gb', 'roms/n2.gb')
_TRK = ['Sfx1', 'Sfx2', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm']
N2 = dict(name='n2', rom=N2_ROM, ntr=7, noise=2, drum=6, ch3=5, trkname=_TRK, banks={
    13: dict(bank=13, orphans=[(0x4310, 2), (0x4317, 0), (0x4326, 2), (0x432D, 0), (0x433C, 2), (0x4343, 0)], idbase=0x00, idmask=0x7F, table=0x4000, count=0x5D, drummap=0x4270, drumcount=13,
             period=0x43D7, waves=0x4481, wavecount=12, vibtab=0x4579, vibcount=15, regbase=0x4F88),
    14: dict(bank=14, orphans=[(0x4126, 2), (0x412D, 0), (0x413C, 2), (0x4143, 0), (0x4152, 2), (0x4159, 0)], idbase=0x80, idmask=0x3F, table=0x4000, count=0x16, drummap=0x4086, drumcount=13,
             period=0x41ED, waves=0x4297, wavecount=14, vibtab=0x4393, vibcount=15, regbase=0x4D9E),
    15: dict(bank=15, orphans=[(0x414A, 2), (0x4151, 0), (0x4160, 2), (0x4167, 0), (0x4176, 2), (0x417D, 0)], idbase=0xC0, idmask=0x3F, table=0x4000, count=0x19, drummap=0x40AA, drumcount=13,
             period=0x4211, waves=0x42BB, wavecount=14, vibtab=0x43B8, vibcount=16, regbase=0x4D8D),
})
PROFILES = dict(n2=N2)
CONFLICTS = {}   # (bank, addr) -> macros: loop bytes read both as a start and as an end

PITCH = ['REST', 'C_', 'C#', 'D_', 'D#', 'E_', 'F_', 'F#', 'G_', 'G#', 'A_', 'A#', 'B_', 'C_HI']


def bank_of_id(sid):
    return 15 if sid >= 0xC0 else 14 if sid >= 0x80 else 13


class Rom:
    def __init__(self, path, bank):
        self.r = open(path, 'rb').read(); self.bank = bank
    def off(self, a):
        return a if a < 0x4000 else self.bank * 0x4000 + a - 0x4000
    def b(self, a):
        return self.r[self.off(a)]
    def w(self, a):
        return self.b(a) | self.b(a + 1) << 8


def trkclass(g, t):
    if t == g['noise']: return 'noise'
    if t == g['drum']: return 'drum'
    if t == g['ch3']: return 'ch3'
    return 'tone'


def decode_event(g, rom, pc, cls, st):
    """st = flow state dict (f = $8F bits, raw = raw stream). -> (length, macro, args, target or None)"""
    op = rom.b(pc)
    f = st['f']
    if op == 0xFB:
        if f & 1: return 2, 'LOOP_END', [rom.b(pc + 1)], None
        return 1, 'LOOP_START', [], None
    if op == 0xFC:
        if f & 2: return 2, 'LOOP2_END', [rom.b(pc + 1)], None
        return 1, 'LOOP2_START', [], None
    if op == 0xFD:
        if f & 4: return 1, 'SND_RET', [], None
        return 3, 'SND_CALL', [rom.w(pc + 1)], rom.w(pc + 1)
    if op == 0xFE:
        if f & 8: return 1, 'SND_LOOP', [], None
        return 1, 'SND_SEGNO', [], None
    if op == 0xFF: return 1, 'SND_END', [], None
    if st['raw']:
        if op == 0xE1 and st.get('rawhead'):
            return 4, 'RAW_HEADER', [rom.b(pc + 1), rom.b(pc + 2), rom.b(pc + 3)], None
        if op == 0x00: return 1, 'RAW_REST', [], None
        if op == 0xE9: return 2, 'SWEEP', [rom.b(pc + 1)], None
        if op == 0xEA: return _ext(rom, pc, cls)
        if op == 0xEB: return 2, 'RAW_UNIT', [rom.b(pc + 1)], None
        if op == 0xEF: return (3 if cls == 'drum' else 2), 'PAN', [rom.b(pc + 1)], None
        return 2, 'RAW_NOTE', [op >> 4, ((op & 15) << 8) | rom.b(pc + 1)], None
    if op == 0xE0:
        u = rom.b(pc + 1)
        if cls == 'drum': return 2, 'DRUM_UNIT', [u], None
        if cls == 'noise':
            v = rom.b(pc + 2); return 3, 'NVOICE', [u, v >> 4, v & 15], None
        v, e = rom.b(pc + 2), rom.b(pc + 3)
        return 4, 'VOICE', [u, v & 15, v >> 4, e & 15, e >> 4], None
    if op >= 0xF0: return 1, 'ATTEN', [op & 15], None
    if 0xE1 <= op <= 0xE6: return 1, 'OCTAVE', [op & 15], None
    if 0xE7 <= op <= 0xEF:
        x = rom.b(pc + 1)
        if op == 0xE7: return 2, 'LEN_UNIT', [x], None
        if op == 0xE8: return 2, 'RELEASE', [x & 15, x >> 4], None
        if op == 0xE9: return 2, 'SWEEP', [x], None
        if op == 0xEA: return _ext(rom, pc, cls)
        if op == 0xEB:
            if x & 15 == 0: return 2, 'VIBRATO_OFF', [x], None     # only the low nibble counts
            y = rom.b(pc + 2)
            return 3, 'VIBRATO', [x, y >> 4, y & 15], None
        if op == 0xED: return 2, 'DUTY_STEP', [x & 15, x >> 4], None
        if op == 0xEE: return 2, 'TEMPO', [x], None
        if op == 0xEF: return (3 if cls == 'drum' else 2), 'PAN', [x], None
        return 2, f'CMD_{op:02X}', [x], None
    if cls == 'noise': return 1, 'NOISE', [op], None
    hi, lo = op >> 4, op & 15
    if hi == 0: return 1, 'REST', [lo], None
    if cls == 'drum': return 1, 'DRUM', [hi, lo], None
    return 1, 'NOTE', [PITCH[hi], lo], None


def _ext(rom, pc, cls):
    x = rom.b(pc + 1); h, l = x >> 4, x & 15
    m = {0: 'TRANSPOSE_UP', 1: 'TRANSPOSE_DOWN', 2: 'EXT_NOP', 3: 'WAVE' if cls == 'ch3' else 'DUTY',
         4: 'AUTOPAN'}.get(h)
    if m is None: return 2, 'RAW', [0xEA, x], None
    return 2, m, [l], None


def note_len(op, unit):
    lo = op & 15
    if lo == 0: return ((unit & 15) << 4) or 256
    L = (lo * unit) & 0xFF
    return L or 256


def walk_stream(g, rom, start, t, owner, own, events, labels, timeline=None, refs=None):
    """Exact simulation of the command reader. Returns dict(kind=end|loop|stall, ticks, loop_tick)."""
    cls = trkclass(g, t)
    st = dict(f=0, raw=rom.b(start) == 0xE1, rawhead=True)
    pc = start; ca = cb = 0; sa = sb = ret = seg = 0; unit = None
    labels.add(start)
    seen = {}; ticks = 0
    while True:
        key = (pc, st['f'], ca, cb, sa, sb, ret, seg, unit, st['rawhead'])
        if key in seen:
            return dict(kind='loop', ticks=ticks, loop_tick=seen[key], loop_pc=pc)
        seen[key] = ticks
        n, mac, args, tgt = decode_event(g, rom, pc, cls, st)
        for i in range(n): own[pc + i].add(owner)
        prev = events.get(pc)
        if prev and prev[:3] != (n, mac, args):
            CONFLICTS.setdefault((rom.bank, pc), set()).update({prev[1], mac})
            if mac.endswith('_END') and not prev[1].endswith('_END'): mac, n, args = prev[1], prev[0], prev[2]
        if not (prev and prev[1].endswith('_START') and mac.endswith('_END')):
            events[pc] = (n, mac, args, cls)
        if tgt is not None:
            labels.add(tgt)
            if refs is not None: refs[tgt].add(owner)
        op = rom.b(pc)
        if op >= 0xFB:
            if mac == 'LOOP_START': st['f'] |= 1; pc += 1; sa = pc
            elif mac == 'LOOP_END':
                ca = (ca + 1) & 0xFF
                if ca == args[0]: ca = 0; st['f'] &= ~1; pc += 2
                else: pc = sa
            elif mac == 'LOOP2_START': st['f'] |= 2; pc += 1; sb = pc
            elif mac == 'LOOP2_END':
                cb = (cb + 1) & 0xFF
                if cb == args[0]: cb = 0; st['f'] &= ~2; pc += 2
                else: pc = sb
            elif mac == 'SND_CALL': st['f'] |= 4; ret = pc + 3; pc = tgt
            elif mac == 'SND_RET': st['f'] &= ~4; pc = ret
            elif mac == 'SND_SEGNO': st['f'] |= 8; pc += 1; seg = pc
            elif mac == 'SND_LOOP': pc = seg
            else: return dict(kind='end', ticks=ticks, loop_tick=None, loop_pc=None)
            st['rawhead'] = True
            continue
        if st['raw']:
            st['rawhead'] = False
            if mac == 'RAW_HEADER': unit = args[0]; pc += n; st['rawhead'] = False; continue
            if mac in ('RAW_REST', 'RAW_NOTE'):
                L = unit if unit else 256
                if timeline is not None: timeline.append((ticks, pc, op, L))
                ticks += L; pc += n; st['rawhead'] = True; continue
            if mac == 'RAW_UNIT': unit = args[0]
            pc += n; st['rawhead'] = True; continue
        if mac in ('VOICE', 'NVOICE', 'DRUM_UNIT', 'LEN_UNIT'):
            unit = args[0]; pc += n; continue
        if op < 0xE0:
            u = unit if unit is not None else 1
            L = u if cls == 'noise' else note_len(op, u)
            if timeline is not None: timeline.append((ticks, pc, op, L))
            ticks += L; pc += 1; continue
        if mac == 'ATTEN' and cls == 'noise':
            return dict(kind='stall', ticks=ticks, loop_tick=None, loop_pc=pc)
        pc += n


def walk_vib(g, rom, start, own, owner):
    """Vibrato reader: 1-byte steps (delay << 4 | neg << 3 | offset), $FB loop point, $FE n, $FF hold."""
    idx = 0; loopidx = 0; cnt = 0; seen = set(); out = {}
    while True:
        st = (idx, loopidx, cnt)
        if st in seen: return out
        seen.add(st)
        a = start + idx
        v = rom.b(a)
        if v == 0xFB:
            out[a] = (1, 'VIB_SEGNO', []); idx = (idx + 1) & 0xFF; loopidx = idx
        elif v == 0xFE:
            n = rom.b(a + 1); out[a] = (2, 'VIB_REPEAT', [n])
            if n == cnt: cnt = 0; idx = (idx + 2) & 0xFF
            else:
                if n != 0xFF: cnt += 1
                idx = loopidx
        elif v == 0xFF:
            out[a] = (1, 'VIB_HOLD', []); own[a].add(owner); return out
        else:
            out[a] = (1, 'VIB_STEP', [v >> 4, (v >> 3) & 1, v & 7]); idx = (idx + 1) & 0xFF
        for i in range(out[a][0]): own[a + i].add(owner)


def analyse(g, bank):
    B = g['banks'][bank]
    rom = Rom(g['rom'], bank)
    own = collections.defaultdict(set)
    events = {}; labels = set(); refs = collections.defaultdict(set)
    snd = {}
    for i in range(1, B['count'] + 1):
        sid = B['idbase'] | i
        h = rom.w(B['table'] + 2 * (i - 1))
        pr, m = rom.b(h), rom.b(h + 1)
        trks = [t for t in range(g['ntr']) if m >> t & 1]
        streams = []
        for k, t in enumerate(trks):
            p = rom.w(h + 2 + 2 * k)
            tl = []
            res = walk_stream(g, rom, p, t, (sid, t), own, events, labels, tl, refs)
            streams.append(dict(t=t, ptr=p, res=res, timeline=tl))
        snd[sid] = dict(hdr=h, prio=pr, mask=m, streams=streams)
    for a, t in B.get('orphans', []):
        walk_stream(g, rom, a, t, ('orphan', a), own, events, labels, None, refs)
    vib = {}
    for i in range(B['vibcount']):
        vib[i + 1] = rom.w(B['vibtab'] + 2 * i)
    vibev = {}
    for i, p in vib.items():
        vibev.update(walk_vib(g, rom, p, own, ('vib', i)))
    return dict(rom=rom, own=own, events=events, labels=labels, refs=refs, snd=snd, vib=vib, vibev=vibev, B=B)
