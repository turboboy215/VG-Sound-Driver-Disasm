"""Generate byte-exact RGBDS sources for the Pokemon Puzzle Challenge sound system.

usage: python3 tools/ppcgen.py <rom> <outdir>
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(__file__))
import ppcparse as P
from emit import Listing
from codegen import Symbols, CodeRegion
import ppcnames as N
import ppcram
import ppcmacros

NOTE_NAMES = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']


def note_name(n):
    return f'{NOTE_NAMES[n % 12]}{n // 12 + 2}'


def signed(v):
    return (v ^ 0x80) - 0x80


class Gen:
    def __init__(self, rom_path, out):
        self.rom = P.load(rom_path)
        self.out = out
        self.S = Symbols()
        self.ram, _ = ppcram.ram_symbols()
        self.S.ram = self.ram
        self.L = {}
        self.code = []
        self.late = []      # callables run after code labels exist
        self.stats = {}

    def rw(self, bank, a):
        return P.rw(bank, a)

    def rb(self, bank, a):
        return P.rb(bank, a)

    def name(self, bank, a):
        return self.S.rom_name(bank, a)

    def setname(self, bank, a, n, force=False):
        if force or self.S.rom_name(bank, a) is None:
            self.S.set(bank, a, n)
        return self.S.rom_name(bank, a)

    # ------------------------------------------------------------------ listings
    def listings(self):
        mk = lambda key, bank, s, e, title: self.L.__setitem__(key, Listing(title, bank, s, e, self.rom))
        mk('home', 0, 0x128D, 0x1B16, 'home')
        mk(0x20, 0x20, 0x4000, 0x771E, 'bank20')
        mk(0x21, 0x21, 0x4000, 0x7A3F, 'bank21')
        mk(0x7F, 0x7F, 0x4000, 0x730F, 'bank7F')
        for b in (0x22, 0x23, 0x24, 0x25, 0x26, 0x7C, 0x7D, 0x7E):
            mk(b, b, 0x4000, bank_end(self.rom, b), f'bank{b:02X}')

    # ------------------------------------------------------------------ names
    def base_names(self):
        for a, n in N.HOME_NAMES.items():
            self.S.set(0, a, n)
        for a, n in N.HOME_EXTERN.items():
            self.S.set(0, a, n)
        for a, n in N.bank20_names(self.rom).items():
            self.S.set(0x20, a, n)
        for a, n in N.SFXA_NAMES.items():
            self.S.set(0x21, a, n)
        o = 0x21 * 0x4000 - 0x4000
        cmdn = {}
        for ch in range(4):
            for b, (nm, _) in P.SFXA_CMDS[ch].items():
                cmdn[(ch + 1, b & 0x1F)] = nm
        for ch, t in N.SFXA_TABLES.items():
            for k in range(32):
                h = P.rw(0x21, t + 2 * k)
                if h and self.S.rom_name(0x21, h) is None:
                    nm = cmdn.get((ch, k), f'x{k:02X}')
                    nm = ''.join(p.capitalize() for p in nm.split('_'))
                    if nm.startswith('Duty'):
                        nm = 'Duty'
                    if nm.startswith('Pan'):
                        nm = 'Pan'
                    if nm.startswith('Lfsr'):
                        nm = 'LfsrMode'
                    self.S.set(0x21, h, f'Sfx{ch}_Cmd{nm}')
        for a, n in N.SFXB_NAMES.items():
            self.S.set(0x7F, a, n)

    # ------------------------------------------------------------------ code
    def region(self, key, prefix, lo, hi, entries, local_ok=True):
        L = self.L[key]
        cr = CodeRegion(L, self.S, prefix, local_ok)
        cr.lo, cr.hi = lo, hi
        cr.inrange = lambda a, lo=lo, hi=hi: lo <= a < hi
        cr.trace(entries)
        self.code.append(cr)
        return cr

    def code_all(self):
        R = self.rom
        # home
        home_entries = [a for a in N.HOME_NAMES if a < 0x16DD or 0x1A25 <= a < 0x1ADA or a >= 0x1AEE]
        self.home = self.region('home', 'Home', 0x128D, 0x1B16, home_entries)
        # bank $20 main code
        e20 = [a for a in N.bank20_names(R) if 0x4000 <= a < 0x590E and a not in (0x4273, 0x4798, 0x4CBD, 0x51DE, 0x5735)]
        self.c20 = self.region(0x20, 'B20', 0x4000, 0x590E, e20 + [0x52A2])
        for t in N.MUS_TABLES.values():
            for k in range(46):
                self.c20.add_ref(t + 2 * k, P.rw(0x20, t + 2 * k))
        for k in range(11):
            self.c20.add_ref(0x5735 + 2 * k, P.rw(0x20, 0x5735 + 2 * k))
        # drum routines (all labels global)
        drums = [P.rw(0x20, P.DRUM_TABLE + 2 * k) for k in range(P.DRUM_N)]
        self.cdrum = self.region(0x20, 'Drum', 0x5A6D, 0x6230, drums, local_ok=False)
        while True:
            new = []
            for pc, (l, fmt, kind, v) in self.cdrum.instr.items():
                if R[0x20 * 0x4000 + pc - 0x4000] == 0x11 and 0x5A6D <= v < 0x6230 and v not in self.cdrum.instr:
                    new.append(v)
            if not new:
                break
            self.cdrum.trace(new)
        for pc, (l, fmt, kind, v) in list(self.cdrum.instr.items()):
            if R[0x20 * 0x4000 + pc - 0x4000] == 0x11 and 0x5A6D <= v < 0x6230:
                self.cdrum.add_ref(pc, v)
        for k, d in enumerate(drums):
            self.cdrum.add_ref(P.DRUM_TABLE + 2 * k, d)
        # bank $21
        e21 = [a for a in N.SFXA_NAMES if a < 0x48E5 and a not in (0x417F, 0x4277, 0x4459, 0x463B, 0x47F9)]
        self.c21 = self.region(0x21, 'B21', 0x4000, 0x48E5, e21)
        for t in N.SFXA_TABLES.values():
            for k in range(32):
                h = P.rw(0x21, t + 2 * k)
                if h:
                    self.c21.add_ref(t + 2 * k, h)
                    self.c21.trace([h])
        # bank $7F engine B
        self.c7f = self.region(0x7F, 'B7F', 0x4942, 0x4CCF, [0x4942, 0x4A1C, 0x4AEF, 0x4B9E, 0x4C03, 0x4C5C])

    def code_finish(self):
        # drums first (all global), then the rest
        for cr in [self.cdrum] + [c for c in self.code if c is not self.cdrum]:
            cr.assign_labels()
        for cr in self.code:
            cr.emit()
        # jump tables in code regions
        L = self.L[0x20]
        for ch, t in N.MUS_TABLES.items():
            lines = []
            for k in range(46):
                h = P.rw(0x20, t + 2 * k)
                lines.append(f'\tdw {self.name(0x20, h)}' + f'  ; ${0xD2 + k:02X} {N.MUS_CMD_NAMES[k]}')
            L.add(t, 92, lines)
        lines = []
        for k in range(11):
            h = P.rw(0x20, 0x5735 + 2 * k)
            lines.append(f'\tdw {self.name(0x20, h)}  ; step {k}')
        L.add(0x5735, 22, lines)
        L = self.L[0x21]
        for ch, t in N.SFXA_TABLES.items():
            lines = []
            for k in range(32):
                h = P.rw(0x21, t + 2 * k)
                lines.append(f'\tdw {self.name(0x21, h) if h else 0}  ; ${0xE0 + k:02X}')
            L.add(t, 64, lines)
        L.add(0x417F, 8, ['\tdw wMusCh1Flags, wMusCh2Flags, wMusCh3Flags, wMusCh4Flags'])
        for f in self.late:
            f()

    # ------------------------------------------------------------------ home tables
    def home_tables(self):
        L = self.L['home']
        lines = []
        for n in range(72):
            v = P.rw(0, 0x16DD + 2 * n)
            lines.append(f'\tdw ${v:04X}  ; {note_name(n)}  {131072 / (2048 - v):8.2f} Hz')
        L.add(0x16DD, 144, lines)
        lines = []
        for n in range(72):
            row = self.rom[0x176D + 8 * n:0x176D + 8 * n + 8]
            lines.append('\tdb ' + ', '.join(f'{b:3d}' for b in row) + f'  ; {note_name(n)}')
        L.add(0x176D, 576, lines)
        for base in (0x19AD, 0x19E9):
            lines = []
            for k in range(0, 60, 12):
                lines.append('\tdb ' + ', '.join(f'${b:02X}' for b in self.rom[base + k:base + k + 12]) + f'  ; {k}-{k+11}')
            L.add(base, 60, lines)
        # PCM table
        lines = []
        for i in range(4):
            a = 0x1ADA + 5 * i
            lines.append(f'\tPCM_ENTRY PcmSample{i}, PCM{i}_LEN')
        L.add(0x1ADA, 20, lines)

    # ------------------------------------------------------------------ bank $20 data
    def bank20_data(self):
        L = self.L[0x20]
        B = 0x20
        # song table
        songs = P.song_table()
        self.song_table = songs
        lines = []
        for i, bk, a in songs:
            lines.append(f'\tSONG_ENTRY @SONG@{bk:02X}_{a:04X}  ; ${i:02X}')
        self.song_lines = lines
        L.add(P.SONG_TABLE, 3 * P.NUM_SONGS, [])  # filled late
        self.late.append(self._song_table_late)
        self.S.ranges.append((B, P.SONG_TABLE, P.SONG_TABLE + 3 * P.NUM_SONGS, 'SongTable'))
        # drum table (code labels exist late)
        def drum_late():
            lines = [f'\tdw {self.name(B, P.rw(B, P.DRUM_TABLE + 2 * k))}  ; drum {k}' for k in range(P.DRUM_N)]
            L.add(P.DRUM_TABLE, 2 * P.DRUM_N, lines)
        self.late.append(drum_late)
        # envelope table + sequences
        hits = {}
        ptrs = [P.rw(B, P.ENV_TABLE + 2 * k) for k in range(2 * P.ENV_N)]
        for p in ptrs:
            if p:
                P.parse_env(p, hits)
                self.setname(B, p, f'Env_{p:04X}')
        # orphans
        cov = set()
        for a, (l, k) in hits.items():
            cov.update(range(a, a + l))
        a = 0x6700
        while a < P.WAVE_TABLE:
            if a not in cov:
                self.setname(B, a, f'EnvUnused_{a:04X}')
                P.parse_env(a, hits)
                for x, (l, k) in hits.items():
                    cov.update(range(x, x + l))
            a += 1
        lines = []
        for k in range(P.ENV_N):
            at, rl = ptrs[2 * k], ptrs[2 * k + 1]
            lines.append(f'\tENV_ENTRY {self.name(B, at) if at else 0}, {self.name(B, rl) if rl else 0}  ; {k}')
        L.add(P.ENV_TABLE, 4 * P.ENV_N, lines)
        self.emit_runs(L, hits, self.fmt_env, simple=('len', 'wait'))
        # waves
        lines = []
        for k in range(P.WAVE_N):
            w = self.rom[B * 0x4000 + P.WAVE_TABLE - 0x4000 + 16 * k:][:16]
            lines.append('\tdb ' + ', '.join(f'${x:02X}' for x in w) + f'  ; wave {k}')
        L.add(P.WAVE_TABLE, 16 * P.WAVE_N, lines)
        # pitch macros
        hits = {}
        pms = [P.rw(B, P.PM_TABLE + 2 * k) for k in range(P.PM_N)]
        for p in pms:
            P.parse_pm(p, hits)
            self.setname(B, p, f'PMac_{p:04X}')
        for a, (l, k) in list(hits.items()):
            if k == 'jump':
                t = P.rw(B, a + 1)
                self.setname(B, t, f'PMac_{t:04X}')
        cov = set()
        for a, (l, k) in hits.items():
            cov.update(range(a, a + l))
        a = 0x747D
        while a < 0x771E:
            if a not in cov:
                self.setname(B, a, f'PMacUnused_{a:04X}')
                P.parse_pm(a, hits)
                for x, (l, k) in hits.items():
                    cov.update(range(x, x + l))
            a += 1
        for a, (l, k) in list(hits.items()):
            if k == 'jump':
                t = P.rw(B, a + 1)
                self.setname(B, t, f'PMac_{t:04X}')
        L.add(P.PM_TABLE, 2 * P.PM_N, [f'\tdw {self.name(B, p)}  ; {k}' for k, p in enumerate(pms)])
        self.emit_runs(L, hits, self.fmt_pm, simple=('step', 'delta'))
        for a in (P.SONG_TABLE, P.DRUM_TABLE, P.ENV_TABLE, P.WAVE_TABLE, P.PM_TABLE):
            L.label(a, self.name(B, a))

    def _song_table_late(self):
        L = self.L[0x20]
        lines = []
        for i, bk, a in self.song_table:
            lines.append(f'\tSONG_ENTRY {self.name(bk, a)}  ; ${i:02X}')
        L.items[P.SONG_TABLE] = (3 * P.NUM_SONGS, lines)

    def fmt_env(self, B, a, kind):
        b = self.rb(B, a)
        if kind == 'end':
            return 'ENV_END', None
        if kind == 'vol':
            return f'ENV_VOL ${b:02X}', None
        if kind == 'len':
            return f'ENV_LEN {b & 0x7F}', 'len'
        return f'ENV_WAIT {b}', 'wait'

    def fmt_pm(self, B, a, kind):
        b = self.rb(B, a)
        if kind == 'end':
            return 'PM_END', None
        if kind == 'jump':
            return f'PM_GOTO {self.name(B, P.rw(B, a + 1))}', None
        if kind == 'step':
            return f'PM_SPEED {b}', 'step'
        return f'PM_DELTA {b - 0x85}', 'delta'

    def emit_runs(self, L, hits, fmt, simple=(), group=8):
        """hits: addr -> (len, kind, ...). Consecutive 'simple' items with the same macro are merged."""
        B = L.bank
        addrs = sorted(hits)
        i = 0
        while i < len(addrs):
            a = addrs[i]
            l = hits[a][0]
            kind = hits[a][1]
            text, grp = fmt(B, a, kind)
            if grp is None or text.startswith('db '):
                L.add(a, l, '\t' + text)
                i += 1
                continue
            # merge run of same macro family
            parts = [text.split(' ', 1)[1]]
            mac = text.split(' ', 1)[0]
            tot = l
            j = i + 1
            while j < len(addrs) and len(parts) < group:
                b = addrs[j]
                if b != a + tot or b in L.labels or self.S.rom_name(B, b):
                    break
                t2, g2 = fmt(B, b, hits[b][1])
                if g2 is None or t2.split(' ', 1)[0] != mac:
                    break
                parts.append(t2.split(' ', 1)[1])
                tot += hits[b][0]
                j += 1
            if len(parts) == 1:
                L.add(a, l, '\t' + text)
            else:
                L.add(a, tot, f'\t{mac} ' + ', '.join(parts))
            i = j
        for a in hits:
            n = self.S.rom_name(B, a)
            if n:
                L.label(a, n)

    # ------------------------------------------------------------------ music data
    def music_data(self):
        songs = P.song_table()
        ref = {}
        for i, bk, a in songs:
            ref.setdefault((bk, a), []).append(i)
        self.slots = ref
        smp = []
        for i in range(4):
            a = 0x1ADA + 5 * i
            smp.append((self.rom[a + 2], self.rom[a] | self.rom[a + 1] << 8, self.rom[a + 3] | self.rom[a + 4] << 8))
        self.samples = smp
        self.music_summary = []
        for bk in (0x7C, 0x7D, 0x7E, 0x7F, 0x22, 0x23, 0x24, 0x25, 0x26):
            L = self.L[bk]
            lo = 0x4CCF if bk == 0x7F else 0x4000
            hi = L.end
            known = sorted(a for (b, a) in ref if b == bk)
            heads = find_songs(bk, lo, hi, known)
            self.music_bank(L, bk, lo, hi, heads, ref)

    def music_bank(self, L, bk, lo, hi, heads, ref):
        hits = {}     # addr -> [len, kind, set(ch)]
        starts = {}
        cov = {}
        conflicts = []

        def walk(start, ch):
            work = [start]
            while work:
                pc = work.pop()
                while True:
                    if pc in hits:
                        hits[pc][2].add(ch)
                        break
                    if pc in cov:
                        conflicts.append(pc)
                        break
                    if not (lo <= pc < hi):
                        conflicts.append(pc)
                        break
                    b = self.rb(bk, pc)
                    if b == 0:
                        n, kind = 1, 'end'
                    elif b < 0xD2:
                        n, kind = 1, 'ev'
                    elif b in (0xD2, 0xD3):
                        n, kind = 1, 'ev'
                    else:
                        n, kind = 1 + P.CMD_ARGS[b], 'cmd'
                    hits[pc] = [n, kind, {ch}]
                    for j in range(n):
                        cov[pc + j] = pc
                    if kind == 'end':
                        break
                    if b == 0xE7:
                        t = self.rw(bk, pc + 1)
                        starts.setdefault(t, f'M{bk:02X}_{t:04X}')
                        work.append(t)
                        break
                    if b == 0xEC or 0xE8 <= b <= 0xEB:
                        t = self.rw(bk, pc + (1 if b == 0xEC else 2))
                        starts.setdefault(t, f'M{bk:02X}_{t:04X}')
                        work.append(t)
                    if b == 0xED:
                        break
                    pc += n
                    if 0xE8 <= b <= 0xEB:
                        pc += 1    # the engine skips one more byte when a loop ends

        headers = []
        for a in heads:
            slots = ref.get((bk, a))
            if slots:
                nm = f'Song_{slots[0]:02X}'
                extra = [f'Song_{s:02X}' for s in slots[1:] if s < 0x21 or s in (0x4F, 0x50, 0x54)]
            else:
                nm = f'Unused{bk:02X}_{a:04X}'
                extra = []
            self.setname(bk, a, nm, force=True)
            headers.append((a, nm, extra))
            for j in range(8):
                cov[a + j] = a
        for a, nm, extra in headers:
            for k in range(4):
                p = self.rw(bk, a + 2 * k)
                if p:
                    starts[p] = f'{nm}_Ch{k+1}' if p not in starts or starts[p].startswith('M') else starts[p]
                    walk(p, k)
        # samples
        for i, (sb, sa, sl) in enumerate(self.samples):
            if sb == bk:
                for j in range(sl):
                    cov[sa + j] = sa
        self._pre_orphan = set(hits)
        # orphans
        orphans = []
        a = lo
        while a < hi:
            if a not in cov:
                before = dict(cov)
                nconf = len(conflicts)
                walk(a, -1)
                if len(conflicts) > nconf:
                    # roll back: treat as raw bytes
                    for x in list(hits):
                        if x not in before and x >= a:
                            for j in range(hits[x][0]):
                                cov.pop(x + j, None)
                            del hits[x]
                    del conflicts[nconf:]
                    cov[a] = a   # raw
                    a += 1
                    continue
                starts.setdefault(a, f'Orphan{bk:02X}_{a:04X}')
                orphans.append(a)
            a += 1
        for t, n in starts.items():
            self.setname(bk, t, n)
        # emit headers
        for a, nm, extra in headers:
            L.label(a, nm)
            for e in extra:
                L.label(a, e)
            ps = [self.rw(bk, a + 2 * k) for k in range(4)]
            L.add(a, 8, '\tSONG_HEADER ' + ', '.join(self.name(bk, p) if p else '0' for p in ps))
        for i, (sb, sa, sl) in enumerate(self.samples):
            if sb == bk:
                L.label(sa, f'PcmSample{i}')
                self.setname(bk, sa, f'PcmSample{i}')
                L.add(sa, sl, f'\tINCBIN "pcm/PcmSample{i}.bin"  ; {sl} bytes, 2-bit PCM (see Pcm_Play)')
                os.makedirs(os.path.join(self.out, 'pcm'), exist_ok=True)
                off = sb * 0x4000 + sa - 0x4000
                open(os.path.join(self.out, 'pcm', f'PcmSample{i}.bin'), 'wb').write(self.rom[off:off + sl])
        for t in starts:
            L.label(t, self.name(bk, t))
        self.emit_music_hits(L, bk, hits, self._pre_orphan)
        self.music_summary.append((bk, headers, orphans, conflicts))

    def emit_music_hits(self, L, bk, hits, real=None):
        addrs = sorted(hits)
        i = 0
        while i < len(addrs):
            a = addrs[i]
            n, kind, chs = hits[a]
            if kind == 'ev':
                parts = []
                tot = 0
                j = i
                while j < len(addrs) and len(parts) < 12:
                    b = addrs[j]
                    if b != a + tot or (j > i and b in L.labels):
                        break
                    if hits[b][1] != 'ev':
                        break
                    parts.append(self.fmt_ev(bk, b, hits[b][2]))
                    tot += 1
                    j += 1
                L.add(a, tot, '\tdb ' + ', '.join(parts), 'mus' if a in real else 'mus_orphan')
                i = j
                continue
            L.add(a, n, '\t' + self.fmt_mcmd(bk, a), 'mus' if a in real else 'mus_orphan')
            i += 1

    def fmt_ev(self, bk, a, chs):
        b = self.rb(bk, a)
        if b < 0x6D:
            return str(b)
        if b < 0x8A:
            return f'DRM{b - 0x6D:02}'
        if b < 0xD2:
            if chs == {3}:
                return f'NZ{b - 0x8A:02}'
            return note_name(b - 0x8A)
        return 'REST' if b == 0xD2 else 'HOLD'

    def fmt_mcmd(self, bk, a):
        b = self.rb(bk, a)
        x = self.rb(bk, a + 1)
        if b == 0:
            return 'TRACK_END'
        simple = {0xD4: 'PITCHMAC', 0xD6: 'TEMPO', 0xD8: 'ENVELOPE', 0xDA: 'MASTERVOL', 0xE2: 'WAVE',
                  0xE5: 'GATE'}
        if b in simple:
            return f'{simple[b]} {x}'
        if b == 0xE6:
            return f'NRX2 ${x:02X}'
        if b in (0xD7, 0xE3, 0xE4):
            return f'{ {0xD7: "TRANSPOSE", 0xE3: "DETUNE", 0xE4: "PITCH_DETUNE"}[b]} {signed(x)}'
        zero = {0xD5: 'PITCHMAC_OFF', 0xD9: 'ENVELOPE_OFF', 0xDB: 'PAN_RIGHT', 0xDC: 'PAN_LEFT',
                0xDD: 'PAN_CENTRE', 0xED: 'RETSUB', 0xFE: 'RETRIG'}
        if b in zero:
            return zero[b]
        if 0xDE <= b <= 0xE1:
            return f'DUTY {b - 0xDE}'
        if b == 0xE7:
            return f'GOTO {self.name(bk, self.rw(bk, a + 1))}'
        if b == 0xEC:
            return f'GOSUB {self.name(bk, self.rw(bk, a + 1))}'
        if 0xE8 <= b <= 0xEB:
            return f'LOOP {b - 0xE7}, {x}, {self.name(bk, self.rw(bk, a + 2))}'
        if 0xEE <= b <= 0xFD:
            d = b - 0xEE - 8 if b < 0xF6 else b - 0xF5
            return f'NUDGE {d}'
        if b == 0xFF:
            return f'SLIDE {x}, {signed(self.rb(bk, a + 2))}, ${self.rw(bk, a + 3):04X}'
        raise ValueError(f'{bk:02X}:{a:04X} {b:02X}')

    # ------------------------------------------------------------------ SFX engine A data
    def sfxa_data(self):
        B = 0x21
        L = self.L[B]
        hits = {}
        chan_of = {}
        names = {}

        def start(ch, a, nm):
            if a not in names:
                names[a] = nm
            P.parse_sfxa(ch, a, hits)

        multi = []
        for k in range(P.SFXA_MULTI_N):
            ent = []
            for ch in range(4):
                a, pr = P.sfxa_ptr(P.rw(B, P.SFXA_MULTI + 8 * k + 2 * ch))
                ent.append((a, pr))
                if a:
                    start(ch, a, f'SfxM{k+1:02}_Ch{ch+1}')
            multi.append(ent)
        singles = {}
        for ch, (t, n) in enumerate(P.SFXA_TABLES):
            ents = []
            for k in range(n):
                a, pr = P.sfxa_ptr(P.rw(B, t + 2 * k))
                ents.append((a, pr))
                if a:
                    start(ch, a, f'Sfx{ch+1}_{k:02}')
            singles[ch] = ents
        # call targets
        for a, (l, kind, ch) in list(hits.items()):
            if kind == 'cmd' and self.rb(B, a) == 0xE0:
                t = P.rw(B, a + 1)
                names.setdefault(t, f'SfxSub_{t:04X}')
        # orphans: channel = channel of the nearest preceding stream byte (or the table owning the region)
        cov = {}
        for a, (l, kind, ch) in hits.items():
            for j in range(l):
                cov[a + j] = ch
        tables = [(P.SFXA_MULTI, P.SFXA_MULTI + 8 * P.SFXA_MULTI_N)] + [(t, t + 2 * n) for t, n in P.SFXA_TABLES]
        for s, e in tables:
            for x in range(s, e):
                cov[x] = 'T'
        region_ch = {0x6F05: 1, 0x6F38: 2}
        self.sfx_orphans = []
        self._sfx_real = set(hits)
        self.sfx_truncated = set()
        a = 0x4A9D
        last = 0
        while a < L.end:
            if a in cov:
                if isinstance(cov[a], int):
                    last = cov[a]
                a += 1
                continue
            g_end = a
            while g_end < L.end and g_end not in cov:
                g_end += 1
            best = None
            order = [region_ch[a]] if a in region_ch else [last] + [c for c in range(4) if c != last]
            for ch in order:
                trial = {}
                try:
                    bad = P.parse_sfxa(ch, a, trial)
                except IndexError:
                    continue
                if bad or not all((a <= x < g_end) or x in hits for x in trial):
                    # last resort: a stream cut off by the next table (no end byte)
                    trial = {}
                    bad = P.parse_sfxa(ch, a, trial, limit=g_end)
                    if bad or any(x + v[0] > g_end for x, v in trial.items() if a <= x < g_end) or \
                            not all((a <= x < g_end) or x in hits for x in trial):
                        continue
                    if sum(v[0] for x, v in trial.items() if a <= x < g_end) != g_end - a:
                        continue
                    self.sfx_truncated.add(a)
                score = sum(v[0] for x, v in trial.items() if a <= x < g_end)
                if best is None or score > best[0]:
                    best = (score, ch, trial)
            okk = best is not None
            if okk:
                _, ch, trial = best
                for x, v in trial.items():
                    if x in hits:
                        continue
                    hits[x] = v
                    for j in range(v[0]):
                        cov[x + j] = ch
                names.setdefault(a, f'SfxUnused{ch+1}_{a:04X}')
                self.sfx_orphans.append((a, ch))
                for x, (l, kind, c2) in trial.items():
                    if kind == 'cmd' and self.rb(B, x) == 0xE0:
                        t = P.rw(B, x + 1)
                        names.setdefault(t, f'SfxSub_{t:04X}')
            else:
                cov[a] = 'raw'
                a += 1
        for a, n in names.items():
            self.setname(B, a, n)
        # waves
        L.add(0x48E5, 64, ['\tdb ' + ', '.join(f'${x:02X}' for x in self.rom[B * 0x4000 + 0x48E5 - 0x4000 + 16 * k:][:16]) + f'  ; wave {k}' for k in range(4)])
        L.label(0x48E5, 'SfxWaves')
        # tables
        def ptrtxt(a, pr):
            return f'{pr}, {self.name(B, a) if a else 0}'
        lines = []
        for k, ent in enumerate(multi):
            prs = {pr for a, pr in ent}
            if len(prs) == 1:
                lines.append(f'\tSFXM_ENTRY {ent[0][1]}, ' + ', '.join(self.name(B, a) if a else '0' for a, _ in ent) + f'  ; {k+1}')
            else:
                lines.append('\tSFX_PTR ' + ' / '.join(ptrtxt(a, pr) for a, pr in ent))
                raise ValueError('mixed priorities')
        L.add(P.SFXA_MULTI, 8 * P.SFXA_MULTI_N, lines)
        L.label(P.SFXA_MULTI, 'SfxMultiTable')
        for ch, (t, n) in enumerate(P.SFXA_TABLES):
            lines = [f'\tSFX_PTR {ptrtxt(a, pr)}  ; {k}' for k, (a, pr) in enumerate(singles[ch])]
            L.add(t, 2 * n, lines)
            L.label(t, self.name(B, t))
        # streams
        self.emit_sfxa(L, hits)

    def emit_sfxa(self, L, hits):
        B = L.bank
        addrs = sorted(hits)
        i = 0
        while i < len(addrs):
            a = addrs[i]
            l, kind, ch = hits[a]
            if kind == 'ev':
                parts = []
                j = i
                while j < len(addrs) and len(parts) < 12:
                    b = addrs[j]
                    if b != a + len(parts) or (j > i and (b in L.labels or self.name(B, b))) or hits[b][1] != 'ev':
                        break
                    v = self.rb(B, b)
                    parts.append(str(v) if v < 0x8A else (f'NZ{v-0x8A:02}' if ch == 3 else note_name(v - 0x8A)))
                    j += 1
                L.add(a, len(parts), '\tdb ' + ', '.join(parts), 'sfx' if a in self._sfx_real else 'sfx_orphan')
                i = j
                continue
            L.add(a, l, '\t' + self.fmt_sfxa(B, a, ch), 'sfx' if a in self._sfx_real else 'sfx_orphan')
            i += 1
        for a in hits:
            n = self.name(B, a)
            if n:
                L.label(a, n)

    def fmt_sfxa(self, B, a, ch):
        b = self.rb(B, a)
        if b == 0:
            return 'SFX_END'
        if 0xD2 <= b < 0xE0:
            return f'db ${b:02X}  ; stops like SFX_END'
        nm, n = P.SFXA_CMDS[ch][b]
        x = self.rb(B, a + 1)
        c = ch + 1
        if nm == 'call':
            return f'SFX_CALL {self.name(B, P.rw(B, a + 1))}'
        if nm == 'ret':
            return 'SFX_RET'
        if nm == 'loop':
            return f'SFX_LOOP {x}'
        if nm == 'endloop':
            return 'SFX_ENDLOOP'
        if nm.startswith('pan'):
            return {'pan_l': 'SFX_PAN_LEFT', 'pan_r': 'SFX_PAN_RIGHT', 'pan_c': 'SFX_PAN_CENTRE'}[nm]
        if nm == 'slide':
            return f'SFX_SLIDE {signed(x)}, {self.rb(B, a + 2)}'
        if nm.startswith('duty'):
            return f'SFX{c}_DUTY {nm[-1]}'
        if nm in ('lfsr15', 'lfsr7'):
            return f'SFX4_{nm.upper()}'
        if n == 0:
            return f'SFX{c}_{nm.upper()}'
        if nm in ('transpose', 'fine'):
            return f'SFX{c}_{nm.upper()} {signed(x)}'
        if nm in ('length', 'wave'):
            return f'SFX{c}_{nm.upper()} {x}'
        return f'SFX{c}_{nm.upper()} ${x:02X}'

    # ------------------------------------------------------------------ SFX engine B data
    def sfxb_data(self):
        B = 0x7F
        L = self.L[B]
        n = P.sfxb_count()
        ents = [P.rw(B, 0x4000 + 2 * k) for k in range(n)]
        hits = {}
        for k, h in enumerate(ents):
            if not h:
                continue
            self.setname(B, h, f'SfxB_{k:02}')
        for k, h in enumerate(ents):
            if not h or h in hits:
                continue
            nm = self.name(B, h)
            hits[h] = (8, 'hdr', None)
            for ch, off in ((0, 0), (1, 2), (2, 6)):
                p = P.rw(B, h + off)
                if p:
                    self.setname(B, p, f'{nm}_{["Ch1", "Ch2", "Ch4"][ch]}')
                    P.parse_sfxb(ch, p, hits)
        L.add(0x4000, 2 * n, [f'\tdw {self.name(B, h) if h else 0}  ; {k}' for k, h in enumerate(ents)])
        L.label(0x4000, 'SfxB_Table')
        for a in sorted(hits):
            l, kind, ch = hits[a]
            if kind == 'hdr':
                ps = [P.rw(B, a + 2 * j) for j in range(4)]
                assert ps[2] == 0
                L.add(a, 8, f'\tSFXB_HEADER {self.name(B, ps[0]) if ps[0] else 0}, {self.name(B, ps[1]) if ps[1] else 0}, {self.name(B, ps[3]) if ps[3] else 0}')
            elif kind == 'end':
                L.add(a, 1, '\tSFXB_END')
            elif kind == 'cmd':
                b = self.rb(B, a)
                x = self.rb(B, a + 1)
                if b == 0xFE:
                    L.add(a, 2, f'\tSFXB_DUTYSEQ %{x:08b}')
                else:
                    L.add(a, 2, f'\tSFXB_SWEEP ${x:02X}')
            else:
                r = [self.rb(B, a + j) for j in range(l)]
                if ch == 2:
                    L.add(a, 3, f'\tSFXB_NOISE {r[0]}, ${r[1]:02X}, ${r[2]:02X}')
                else:
                    L.add(a, 4, f'\tSFXB_NOTE {r[0]}, ${r[1]:02X}, ${r[2]:02X}, ${r[3]:02X}')
            nm = self.name(B, a)
            if nm:
                L.label(a, nm)

    # ------------------------------------------------------------------ output
    def write(self):
        os.makedirs(self.out, exist_ok=True)
        files = []
        hdr = ['INCLUDE "GB_Hardware.inc"', 'INCLUDE "PPC_RAM.inc"', 'INCLUDE "PPC_Macros.inc"', '']
        sect = {
            'home': ('PPC_Home.asm', 'SECTION "Sound home code", ROM0[$128D]'),
            0x20: ('PPC_Bank20.asm', 'SECTION "Music engine", ROMX[$4000], BANK[$20]'),
            0x21: ('PPC_Bank21.asm', 'SECTION "SFX engine A", ROMX[$4000], BANK[$21]'),
            0x7F: ('PPC_Bank7F.asm', 'SECTION "SFX engine B and music", ROMX[$4000], BANK[$7F]'),
        }
        for b in (0x22, 0x23, 0x24, 0x25, 0x26, 0x7C, 0x7D, 0x7E):
            sect[b] = (f'PPC_Bank{b:02X}.asm', f'SECTION "Music bank ${b:02X}", ROMX[$4000], BANK[${b:02X}]')
        for key, (fn, s) in sect.items():
            L = self.L[key]
            body = L.render()
            text = [f'; {fn}: generated by tools/ppcgen.py from Pokemon Puzzle Challenge (E) (M5) [C][!].gbc', ''] + hdr + [s, ''] + body
            open(os.path.join(self.out, fn), 'w').write('\n'.join(text) + '\n')
            files.append(fn)
        open(os.path.join(self.out, 'PPC_RAM.inc'), 'w').write(ppcram.ram_inc())
        open(os.path.join(self.out, 'GB_Hardware.inc'), 'w').write(ppcram.hw_inc())
        lens = ''.join(f'DEF PCM{i}_LEN EQU {sl}\n' for i, (sb, sa, sl) in enumerate(self.samples))
        open(os.path.join(self.out, 'PPC_Macros.inc'), 'w').write(ppcmacros.MACROS + '\n' + lens)
        import json
        model = {}
        for key, L in self.L.items():
            k = 'home' if key == 'home' else f'{key:02X}'
            model[k] = {'bank': L.bank, 'start': L.start, 'end': L.end,
                        'items': sorted([a, l, L.kinds.get(a, 'data')] for a, (l, _) in L.items.items())}
        os.makedirs(os.path.join(self.out, 'build'), exist_ok=True)
        json.dump(model, open(os.path.join(self.out, 'build', 'model.json'), 'w'))
        return files

    def add_comments(self):
        for (bk, a), lines in N.COMMENTS.items():
            key = 'home' if bk == 0 else bk
            L = self.L[key]
            if L.start <= a < L.end:
                L.comments.setdefault(a, []).extend(['', *('; ' + t for t in lines)])

    def run(self):
        self.listings()
        self.base_names()
        self.code_all()
        self.home_tables()
        self.bank20_data()
        self.music_data()
        self.sfxa_data()
        self.sfxb_data()
        self.code_finish()
        self.add_comments()
        return self.write()


def bank_end(rom, bk):
    d = rom[bk * 0x4000:(bk + 1) * 0x4000]
    i = len(d)
    while i and d[i - 1] == 0xFF:
        i -= 1
    return 0x4000 + i


def valid_header(bk, a):
    ps = [P.rw(bk, a + 2 * k) for k in range(4)]
    if ps[0] != a + 8:
        return False
    for p in ps:
        if p and not (a + 8 <= p < 0x8000):
            return False
    try:
        for p in ps:
            if p:
                h = {}
                P.parse_track(bk, p, h)
                if any(not (0x4000 <= x < 0x8000) for x in h):
                    return False
    except Exception:
        return False
    return True


def find_songs(bk, lo, hi, known):
    hs = set(known)

    def cov(hs):
        c = set()
        for a in hs:
            c.update(range(a, a + 8))
            for k in range(4):
                p = P.rw(bk, a + 2 * k)
                if p:
                    h = {}
                    P.parse_track(bk, p, h)
                    for x, (l, kd) in h.items():
                        c.update(range(x, x + l))
        return c
    c = cov(hs)
    for a in range(lo, hi - 8):
        if a in c:
            continue
        if P.rw(bk, a) == a + 8 and valid_header(bk, a):
            hs.add(a)
            c = cov(hs)
    return sorted(hs)


if __name__ == '__main__':
    g = Gen(sys.argv[1], sys.argv[2])
    files = g.run()
    for bk, headers, orphans, conflicts in g.music_summary:
        print(f'bank {bk:02X}: {len(headers)} songs, {len(orphans)} orphan blocks, conflicts {[hex(c) for c in conflicts]}')
    print('sfx orphans', len(g.sfx_orphans))
    print('\n'.join(files))
