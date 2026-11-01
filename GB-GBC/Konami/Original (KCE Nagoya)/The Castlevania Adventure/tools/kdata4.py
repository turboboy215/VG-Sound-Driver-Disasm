"""Konami GB driver, fourth generation (TMNT II: Back from the Sewers): decode of the sound data.
Shared by gen_asm3 (through the profile's 'decoder') and the length tools.
Flow commands are those of Nemesis II ($FB/$FC loop markers, $FD call/return, $FE mark/jump), plus
$FA addr (jump). Track classes: tone (Sfx1, Ch1, Ch2), wave (Sfx2, Ch3), noise (SfxN), drum."""
import collections, os

def _rom(env, name, fallback):
    p = os.environ.get(env)
    if p: return p
    return name if os.path.exists(name) or not os.path.exists(fallback) else fallback

TM2_ROM = _rom('KON_ROM_TM2', 'Teenage Mutant Hero Turtles - Back from the Sewers (E) [!].gb', 'roms/tm2.gb')
_TRK = ['Sfx1', 'Sfx2', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm']
TM2 = dict(name='tm2', rom=TM2_ROM, ntr=7, trkname=_TRK, decoder='kdata4',
           cls=['tone', 'wave', 'noise', 'tone', 'tone', 'wave', 'drum'], banks={
    14: dict(bank=14, idbase=0x00, table=0x49C8, first=1, count=0x9E, period=0x48A4, waves=0x4968,
             vibtab=0x4E6F, vibcount=2, raw=True, pcm=(0x9A, 0x9D)),
    15: dict(bank=15, idbase=0xC0, table=0x4975, first=1, count=0x33, period=0x47BD, waves=0x4867,
             vibtab=0x4C2B, vibcount=14, raw=False),
})
PROFILES = dict(tm2=TM2)
CONFLICTS = {}

PITCH = ['REST', 'C_', 'C#', 'D_', 'D#', 'E_', 'F_', 'F#', 'G_', 'G#', 'A_', 'A#', 'B_', 'C_HI']
EXT = {0: 'DUTY', 1: 'PAN_BOTH', 2: 'PAN_RIGHT', 3: 'PAN_LEFT', 4: 'AUTOPAN_R', 5: 'AUTOPAN_L',
       6: 'AUTOPAN_OFF', 7: 'TRANSPOSE_UP', 8: 'TRANSPOSE_DOWN'}


def bank_of_id(sid): return 15 if sid >= 0xC0 else 14


class Rom:
    def __init__(self, path, bank):
        self.r = open(path, 'rb').read(); self.bank = bank
    def off(self, a): return a if a < 0x4000 else self.bank * 0x4000 + a - 0x4000
    def b(self, a): return self.r[self.off(a)]
    def w(self, a): return self.b(a) | self.b(a + 1) << 8


def decode_event(g, B, rom, pc, cls, st):
    """st: f = loop/call/mark flags, raw = raw frames (bank 14 tone/wave), hold = noise hold mode."""
    op = rom.b(pc); f = st['f']
    raw = st['raw'] and cls != 'noise'
    if op == 0xFB: return (2, 'LOOP_END', [rom.b(pc + 1)], None) if f & 1 else (1, 'LOOP_START', [], None)
    if op == 0xFC: return (2, 'LOOP2_END', [rom.b(pc + 1)], None) if f & 2 else (1, 'LOOP2_START', [], None)
    if op == 0xFD: return (1, 'SND_RET', [], None) if f & 4 else (3, 'SND_CALL', [rom.w(pc + 1)], rom.w(pc + 1))
    if op == 0xFE: return (1, 'SND_LOOP', [], None) if f & 8 else (1, 'SND_SEGNO', [], None)
    if op == 0xFF: return 1, 'SND_END', [], None
    if op == 0xFA: return 3, 'SND_JUMP', [rom.w(pc + 1)], rom.w(pc + 1)
    if op == 0xE0:
        b1 = rom.b(pc + 1)
        if b1 & 0x80:
            if cls == 'noise': return 2, 'NVOICE_HOLD', [b1 & 0x7F], None
            if not B['raw']: return 2, 'VOICE_FLAG', [b1 & 0x7F], None
            return 4, 'RAW_VOICE', [b1 & 0x7F, rom.b(pc + 2), rom.b(pc + 3)], None
        if cls == 'noise': return 3, 'NVOICE', [b1, rom.b(pc + 2)], None
        b2, b3 = rom.b(pc + 2), rom.b(pc + 3)
        return 4, 'VOICE', [b1, b2 >> 4, b2 & 15, b3 >> 4, b3 & 15], None
    if raw and (0xE1 <= op <= 0xE6 or 0xF0 <= op <= 0xF7 or op < 0xE0):
        if op == 0: return 1, 'RAW_REST', [], None
        return 2, 'RAW_NOTE', [op >> 4, ((op & 15) << 8) | rom.b(pc + 1)], None
    if 0xE1 <= op <= 0xE6: return 1, 'OCTAVE', [op & 15], None
    if 0xF0 <= op <= 0xF7: return 1, 'ATTEN', [op & 15], None
    if op >= 0xE7:
        x = rom.b(pc + 1)
        if op == 0xE7: return 2, 'LEN_UNIT', [x], None
        if op == 0xE8: return 2, 'RELEASE', [x >> 4, x & 15], None
        if op == 0xE9: return 2, 'SWEEP', [x], None
        if op == 0xEA:
            m = EXT.get(x >> 4)
            if m is None: return 2, 'RAW', [op, x], None
            if m == 'DUTY' and cls == 'wave': m = 'WAVE'
            return 2, m, [x & 15], None
        if op == 0xEB:
            if x == 0: return 2, 'VIBRATO_OFF', [], None
            y = rom.b(pc + 2); return 3, 'VIBRATO', [x, y >> 4, y & 15], None
        if op == 0xEE: return 2, 'TEMPO', [x], None
        if op == 0xEF: return 2, 'DETUNE', [x], None
        if op in (0xF8, 0xF9): return 2, f'VOLUME{"_F9" if op == 0xF9 else ""}', [x], None
        return 2, f'CMD_{op:02X}', [x], None
    if cls == 'noise':
        if st['hold']:
            if op == 0: return 1, 'NOISE_REST', [], None
            return 2, 'NOISE_HOLD', [op & 15, rom.b(pc + 1)], None
        return (1, 'NOISE_REST', [], None) if op == 0 else (1, 'NOISE', [op], None)
    hi, lo = op >> 4, op & 15
    if hi == 0: return 1, 'REST', [lo], None
    if cls == 'drum': return 1, 'DRUM', [hi, lo], None
    return 1, 'NOTE', [PITCH[hi], lo], None


def note_len(op, unit):
    lo = op & 15
    L = ((unit & 15) << 4) if lo == 0 else (lo * unit) & 0xFF
    return L or 256


def walk_stream(g, B, rom, start, t, owner, own, events, labels, timeline=None, refs=None):
    cls = g['cls'][t]
    st = dict(f=0, raw=False, hold=False)
    pc = start; ca = cb = 0; sa = sb = ret = seg = 0; unit = None
    labels.add(start); seen = {}; ticks = 0
    while True:
        key = (pc, st['f'], st['raw'], st['hold'], ca, cb, sa, sb, ret, seg, unit)
        if key in seen: return dict(kind='loop', ticks=ticks, loop_tick=seen[key], loop_pc=pc)
        seen[key] = ticks
        if pc >= 0x8000: return dict(kind='ram', ticks=ticks, loop_tick=None, loop_pc=pc)
        n, mac, args, tgt = decode_event(g, B, rom, pc, cls, st)
        for i in range(n): own[pc + i].add(owner)
        prev = events.get(pc)
        if prev and prev[:3] != (n, mac, args):
            CONFLICTS.setdefault((rom.bank, pc), set()).update({prev[1], mac})
        if not (prev and prev[1].endswith('_START') and mac.endswith('_END')):
            events[pc] = (n, mac, args, cls)
        if tgt is not None:
            labels.add(tgt)
            if refs is not None: refs[tgt].add(owner)
        op = rom.b(pc)
        if mac == 'LOOP_START': st['f'] |= 1; pc += 1; sa = pc; continue
        if mac == 'LOOP_END':
            ca = (ca + 1) & 0xFF
            if ca == args[0]: ca = 0; st['f'] &= ~1; pc += 2
            else: pc = sa
            continue
        if mac == 'LOOP2_START': st['f'] |= 2; pc += 1; sb = pc; continue
        if mac == 'LOOP2_END':
            cb = (cb + 1) & 0xFF
            if cb == args[0]: cb = 0; st['f'] &= ~2; pc += 2
            else: pc = sb
            continue
        if mac == 'SND_CALL': st['f'] |= 4; ret = pc + 3; pc = tgt; continue
        if mac == 'SND_RET': st['f'] &= ~4; pc = ret; continue
        if mac == 'SND_SEGNO': st['f'] |= 8; pc += 1; seg = pc; continue
        if mac == 'SND_LOOP': pc = seg; continue
        if mac == 'SND_JUMP': pc = tgt; continue
        if mac == 'SND_END': return dict(kind='end', ticks=ticks, loop_tick=None, loop_pc=None)
        if mac in ('VOICE', 'NVOICE', 'NVOICE_HOLD', 'RAW_VOICE', 'VOICE_FLAG', 'LEN_UNIT'):
            unit = args[0] & 0x7F
            if mac == 'RAW_VOICE': st['raw'] = True
            elif mac == 'VOICE': st['raw'] = False
            if mac == 'NVOICE_HOLD': st['hold'] = True
            elif mac == 'NVOICE': st['hold'] = False
            pc += n; continue
        if mac in ('NOTE', 'REST', 'DRUM', 'NOISE', 'NOISE_REST', 'NOISE_HOLD', 'RAW_NOTE', 'RAW_REST'):
            u = unit if unit is not None else 1
            L = (u or 256) if mac in ('NOISE', 'NOISE_REST', 'NOISE_HOLD', 'RAW_NOTE', 'RAW_REST') else note_len(op, u)
            if timeline is not None: timeline.append((ticks, pc, op, L))
            ticks += L; pc += n; continue
        pc += n


def walk_vib(rom, start, own, owner):
    """Vibrato reader: 1-byte steps (delay << 4 | neg << 3 | offset), $FB/$FB n loop, $FE mark/jump, $FF end."""
    out = {}; pc = start; f = 0; cnt = 0; sa = seg = 0; seen = set()
    while True:
        key = (pc, f, cnt)
        if key in seen or pc >= 0x8000: return out
        seen.add(key)
        v = rom.b(pc)
        if v == 0xFF: out[pc] = (1, 'VIB_END', []); own[pc].add(owner); return out
        if v == 0xFE:
            out[pc] = (1, 'VIB_MARK', []); own[pc].add(owner)
            if f & 2: pc = seg
            else: f |= 2; pc += 1; seg = pc
            continue
        if v == 0xFB:
            if f & 1:
                n = rom.b(pc + 1); out[pc] = (2, 'VIB_LOOP_END', [n]); own[pc].add(owner); own[pc + 1].add(owner)
                cnt += 1
                if cnt == n: cnt = 0; f &= ~1; pc += 2
                else: pc = sa
            else:
                out[pc] = (1, 'VIB_LOOP_START', []); own[pc].add(owner); f |= 1; pc += 1; sa = pc
            continue
        out[pc] = (1, 'VIB_STEP', [v >> 4, (v >> 3) & 1, v & 7]); own[pc].add(owner); pc += 1


def analyse(g, bank):
    B = g['banks'][bank]
    rom = Rom(g['rom'], bank)
    own = collections.defaultdict(set); events = {}; labels = set(); refs = collections.defaultdict(set)
    snd = {}
    for i in range(B['first'], B['count'] + 1):
        sid = B['idbase'] | i
        h = rom.w(B['table'] + 2 * i)
        pr, m = rom.b(h), rom.b(h + 1)
        trks = [t for t in range(g['ntr']) if m >> t & 1]
        streams = []
        for k, t in enumerate(trks):
            p = rom.w(h + 2 + 2 * k); tl = []
            res = walk_stream(g, B, rom, p, t, (sid, t), own, events, labels, tl, refs)
            streams.append(dict(t=t, ptr=p, res=res, timeline=tl))
        snd[sid] = dict(hdr=h, prio=pr, mask=m, streams=streams)
    for a, t in B.get('orphans', []):
        walk_stream(g, B, rom, a, t, ('orphan', a), own, events, labels, None, refs)
    vib = {i: rom.w(B['vibtab'] + 2 * i) for i in range(1, B['vibcount'] + 1)}
    vibev = {}
    for i, p in vib.items(): vibev.update(walk_vib(rom, p, own, ('vib', i)))
    return dict(rom=rom, own=own, events=events, labels=labels, refs=refs, snd=snd, vib=vib, vibev=vibev, B=B)
