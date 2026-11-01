"""Konami early GB driver: structured decode of sound data (shared by gen_asm and the model).
Game profiles describe where the tables are and which track numbers have special roles."""
import collections, os

def _rom(env, name, fallback):
    p = os.environ.get(env)
    if p: return p
    return name if os.path.exists(name) or not os.path.exists(fallback) else fallback

CVA = dict(name='cva', rom=_rom('KON_ROM_CVA', 'Castlevania Adventure, The (E) [!].gb', 'roms/cva.gb'), bank=2, table=0x4916, count=0x31, ntr=6,
           noise=1, drum=5, ch3=4, vibtab=0x4A9F, vibcount=11, drummap=0x4A6A, drumcount=4,
           period=0x481D, autopan=True,
           trkname=['Sfx1', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm'])
MM = dict(name='mm', rom=_rom('KON_ROM_MM', 'Motocross Maniacs (E) [!].gb', 'roms/mm.gb'), bank=1, table=0x6F30, count=0x20, ntr=7,
          noise=2, drum=6, ch3=5, vibtab=0x7061, vibcount=15, drummap=0x7002, drumcount=13,
          period=0x6DCE, autopan=False,
          trkname=['Sfx1', 'Sfx2', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm'])

# later variant (fade-out, per-game extras); see kmodel2.py
NEM = dict(name='nem', rom=_rom('KON_ROM_NEM', 'Nemesis (E) [!].gb', 'roms/nem.gb'), bank=7, table=0x67CE, count=0x39, ntr=7,
           noise=2, drum=6, ch3=5, vibtab=0x47E9, vibcount=15, drummap=0x6984, drumcount=13,
           period=0x4040, autopan=True, late=True, walk_first=[0x22],
           trkname=['Sfx1', 'Sfx2', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm'])
CV2 = dict(name='cv2', rom=_rom('KON_ROM_CV2', "Castlevania II - Belmont's Revenge (U) [!].gb", 'roms/cv2.gb'), bank=7,
           table=0x4A7B, count=0x6B, ntr=7,
           noise=2, drum=6, ch3=5, vibtab=0x4A0B, vibcount=15, drummap=0x4DC3, drumcount=13,
           period=0x4025, autopan=True, late=True, dutystep=True,
           trkname=['Sfx1', 'Sfx2', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm'])
BOS = dict(name='bos', rom=_rom('KON_ROM_BOS', 'Blades of Steel (E) [!].gb', 'roms/bos.gb'), bank=7,
           table=0x4B49, count=0x33, ntr=7,
           noise=2, drum=6, ch3=5, vibtab=0x5267, vibcount=15, drummap=0x5229, drumcount=11,
           period=0x4025, autopan=True, late=True, dutystep=True, glide=True,
           orphans=[(0x4D0C, 2), (0x6270, 3), (0x637E, 3), (0x63FB, 5)],
           trkname=['Sfx1', 'Sfx2', 'SfxN', 'Ch1', 'Ch2', 'Ch3', 'Drm'])
PROFILES = dict(cva=CVA, mm=MM, nem=NEM, cv2=CV2, bos=BOS)

PITCH = ['REST', 'C_', 'C#', 'D_', 'D#', 'E_', 'F_', 'F#', 'G_', 'G#', 'A_', 'A#', 'B_', 'C_HI']


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


def decode_event(g, rom, pc, cls):
    """-> (length, macro, args, target or None)"""
    op = rom.b(pc)
    if op == 0xFB: return 1, 'SND_SEGNO', [], None
    if op == 0xFC: return 1, 'SND_RET', [], None
    if op == 0xFD: return 3, 'SND_CALL', [rom.w(pc + 1)], rom.w(pc + 1)
    if op == 0xFE:
        n = rom.b(pc + 1)
        if n == 0xFF: return 4, 'SND_JUMP', [rom.w(pc + 2)], rom.w(pc + 2)
        return 2, 'SND_REPEAT', [n], None
    if op == 0xFF: return 1, 'SND_END', [], None
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
        if op == 0xEA:
            h, l = x >> 4, x & 15
            m = {0: 'TRANSPOSE_UP', 1: 'TRANSPOSE_DOWN', 2: 'VIBRATO',
                 3: 'WAVE' if cls == 'ch3' else 'DUTY',
                 4: 'AUTOPAN' if g['autopan'] else 'EXT_NOP',
                 5: 'GLIDE' if g.get('glide') else None}.get(h)
            if m is None: return 2, 'RAW', [op, x], None
            return 2, m, [l], None
        if op == 0xED and g.get('dutystep'):
            return 2, 'DUTY_STEP', [x & 15, x >> 4], None
        if op == 0xEE: return 2, 'TEMPO', [x], None
        if op == 0xEF: return 2, 'PAN', [x], None
        return 2, f'CMD_{op:02X}', [x], None
    # note byte
    if cls == 'noise': return 1, 'NOISE', [op], None
    hi, lo = op >> 4, op & 15
    if hi == 0: return 1, 'REST', [lo], None
    if cls == 'drum': return 1, 'DRUM', [hi, lo], None
    return 1, 'NOTE', [PITCH[hi], lo], None


def walk_stream(g, rom, start, t, owner, own, events, labels, timeline=None, refs=None):
    """Exact simulation of the command reader. State = (pc, segno, loopcnt, ret).
    Returns dict(kind=end|loop, ticks, loop_tick, loop_pc)."""
    cls = trkclass(g, t)
    pc = start; segno = 0; cnt = 0; ret = 0; unit = None
    labels.add(start)
    seen = {}
    ticks = 0
    while True:
        st = (pc, segno, cnt, ret, unit)
        if st in seen:
            return dict(kind='loop', ticks=ticks, loop_tick=seen[st], loop_pc=pc)
        seen[st] = ticks
        n, mac, args, tgt = decode_event(g, rom, pc, cls)
        for i in range(n): own[pc + i].add(owner)
        prev = events.get(pc)
        if prev and prev[:3] != (n, mac, args):
            print(f'!! event conflict at {pc:04X}: {prev} vs {(n, mac, args)}')
        events[pc] = (n, mac, args, cls)
        if tgt is not None:
            labels.add(tgt)
            if refs is not None: refs[tgt].add(owner)
        op = rom.b(pc)
        if mac == 'SND_SEGNO': pc += 1; segno = pc
        elif mac == 'SND_RET':
            if ret == 0 and owner[0] == 'orphan':
                return dict(kind='ret', ticks=ticks, loop_tick=None, loop_pc=None)
            pc = ret
        elif mac == 'SND_CALL': ret = pc + 3; pc = tgt
        elif mac == 'SND_JUMP': pc = tgt
        elif mac == 'SND_REPEAT':
            if (cnt + 1) & 0xFF == args[0]: cnt = 0; pc += 2
            else: cnt = (cnt + 1) & 0xFF; pc = segno
        elif mac == 'SND_END':
            return dict(kind='end', ticks=ticks, loop_tick=None, loop_pc=None)
        elif op == 0xE0 or op == 0xE7:
            unit = rom.b(pc + 1); pc += n
        elif op < 0xE0:
            u = unit if unit is not None else 1     # orphans start without a unit
            if cls == 'noise': L = u
            else: L = ((op & 15) * u) & 0xFF
            if L == 0: L = 256
            if timeline is not None: timeline.append((ticks, pc, op, L))
            ticks += L; pc += 1
        else:
            pc += n


def walk_vib(g, rom, start, own, owner):
    """Simulate the vibrato table reader; mark bytes. Returns list of (addr, n, macro, args)."""
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
            out[a] = (1, 'VIB_HOLD', []);
            for i in range(1): own[a + i].add(owner)
            return out
        else:
            lo = rom.b(a + 1)
            out[a] = (2, 'VIB_STEP', [v >> 4, (v >> 3) & 1, ((v & 7) << 8) | lo])
            idx = (idx + 2) & 0xFF
        for i in range(out[a][0]): own[a + i].add(owner)


def analyse(g):
    rom = Rom(g['rom'], g['bank'])
    own = collections.defaultdict(set)
    events = {}; labels = set(); refs = collections.defaultdict(set)
    snd = {}
    order = list(g.get('walk_first', [])) + [i for i in range(1, g['count'] + 1) if i not in g.get('walk_first', [])]
    for sid in order:
        h = rom.w(g['table'] + 2 * (sid - 1))
        pr, m = rom.b(h), rom.b(h + 1)
        trks = [t for t in range(g['ntr']) if m >> t & 1]
        streams = []
        for k, t in enumerate(trks):
            p = rom.w(h + 2 + 2 * k)
            tl = []
            res = walk_stream(g, rom, p, t, (sid, t), own, events, labels, tl, refs)
            streams.append(dict(t=t, ptr=p, res=res, timeline=tl))
        snd[sid] = dict(hdr=h, prio=pr, mask=m, streams=streams)
    for a, t in g.get('orphans', []):        # unreferenced streams, decoded for readability
        walk_stream(g, rom, a, t, ('orphan', a), own, events, labels, None, refs)
    vib = {}
    for i in range(g['vibcount']):
        p = rom.w(g['vibtab'] + 2 * i)
        vib[i + 1] = p
    vibev = {}
    for i, p in vib.items():
        vibev.update(walk_vib(g, rom, p, own, ('vib', i)))
    snd = dict(sorted(snd.items()))
    return dict(rom=rom, own=own, events=events, labels=labels, refs=refs, snd=snd,
                vib=vib, vibev=vibev)
