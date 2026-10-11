"""Code tracing + label assignment + rendering into a Listing."""
from emit import decode, flow

INLINE_CALLS = {0x09A6: 3}   # FarCall: dw addr, db bank follow the call


class Symbols:
    """Global symbol space: (bank, addr) -> name for ROM; addr -> name for RAM/HW."""

    def __init__(self):
        self.rom = {}        # (bank, addr) -> name
        self.ram = {}        # addr -> name
        self.ranges = []     # (bank, start, end, name) for Label+offset
        self.need_global = set()   # (bank, addr)

    def rom_name(self, bank, a):
        if a < 0x4000:
            return self.rom.get((0, a))
        return self.rom.get((bank, a))

    def set(self, bank, a, name):
        if a < 0x4000:
            bank = 0
        self.rom[(bank, a)] = name

    def range_name(self, bank, a):
        if a < 0x4000:
            bank = 0
        for b, s, e, n in self.ranges:
            if b == bank and s <= a < e:
                return n if a == s else f'{n} + {a - s}'
        return None


class CodeRegion:
    def __init__(self, listing, syms, prefix, local_ok=True):
        self.L = listing
        self.S = syms
        self.prefix = prefix
        self.instr = {}      # pc -> (len, fmt, kind, value)
        self.refs = []       # (src, target)
        self.inline = {}     # pc -> bytes count of inline data after call
        self.local_ok = local_ok
        self.extra_data = {}  # addr -> (length, lines-callable)

    @property
    def bank(self):
        return self.L.bank

    def inrange(self, a):
        return self.L.start <= a < self.L.end

    def trace(self, entries, stop=()):
        rom = self.L.rom
        work = list(entries)
        while work:
            pc = work.pop()
            while True:
                if pc in self.instr or not self.inrange(pc) or pc in stop:
                    break
                i = self.L.off(pc)
                l, fmt, kind, v = decode(rom, i, pc)
                if fmt is None or kind == 'stop':
                    raise ValueError(f'{self.L.name}: illegal/stop at {pc:04X}')
                self.instr[pc] = (l, fmt, kind, v)
                ln, falls, tg = flow(rom, i, pc)
                for t in tg:
                    self.refs.append((pc, t))
                    if self.inrange(t):
                        work.append(t)
                if kind == 'call' and v in INLINE_CALLS:
                    n = INLINE_CALLS[v]
                    self.inline[pc + l] = n
                    tgt = rom[i + 3] | rom[i + 4] << 8
                    self.refs.append((pc + l, ('far', tgt, rom[i + 5])))
                    pc += l + n
                    continue
                if not falls:
                    break
                pc += l

    def add_ref(self, src, tgt):
        self.refs.append((src, tgt))

    # ---- labels ----
    def assign_labels(self):
        """Give every in-range reference target a label; promote to global when scopes differ."""
        S = self.S
        b = self.bank
        targets = set()
        for src, t in self.refs:
            if isinstance(t, int) and self.inrange(t):
                targets.add(t)
        for (bk, a) in list(S.need_global):
            if (bk == b or (b == 0 and bk == 0)) and self.inrange(a):
                targets.add(a)
        globs = {a for (bk, a) in S.rom if (bk == b or (a < 0x4000 and b == 0)) and self.inrange(a)}
        for (bk, a) in S.need_global:
            if bk == b and self.inrange(a) and S.rom_name(b, a) is None:
                S.set(b, a, f'{self.prefix}_{a:04X}')
                globs.add(a)
        changed = True
        while changed:
            changed = False
            gl = sorted(globs)

            def scope(x):
                best = None
                for g in gl:
                    if g <= x:
                        best = g
                    else:
                        break
                return best
            for src, t in self.refs:
                if not isinstance(t, int) or not self.inrange(t) or t in globs:
                    continue
                if not self.local_ok or scope(src) != scope(t) or scope(t) is None:
                    S.set(b, t, f'{self.prefix}_{t:04X}')
                    globs.add(t)
                    changed = True
        self.locals = {t for t in targets if t not in globs}
        for a in sorted(globs):
            n = S.rom_name(b, a)
            if n:
                self.L.label(a, n)
        for t in self.locals:
            self.L.label(t, f'.l{t:04X}')

    # ---- operands ----
    def resolve(self, kind, v, pc):
        S = self.S
        b = self.bank
        if kind in ('rel', 'jp', 'call'):
            if self.inrange(v) and v in getattr(self, 'locals', ()):
                return f'.l{v:04X}'
            n = S.rom_name(b, v) if v < 0x8000 else S.ram.get(v)
            if n:
                return n
            return f'${v:04X}'
        if kind == 'imm16':
            if v >= 0x8000:
                n = S.ram.get(v)
                return n if n else f'${v:04X}'
            n = S.rom_name(b, v)
            if n and (v >= 0x4000 or v >= 0x0100):
                return n
            r = S.range_name(b, v)
            if r and v >= 0x100:
                return r
            return f'${v:04X}'
        if kind == 'mem16':
            n = S.ram.get(v)
            return n if n else f'${v:04X}'
        if kind == 'ldh':
            n = S.ram.get(v)
            return n if n else f'${v:04X}'
        if kind == 'n8':
            return f'${v:02X}'
        if kind == 'n8s':
            return str((v ^ 0x80) - 0x80)
        raise ValueError(kind)

    def emit(self):
        rom = self.L.rom
        for pc, (l, fmt, kind, v) in self.instr.items():
            text = fmt if kind is None else fmt.format(self.resolve(kind, v, pc))
            self.L.add(pc, l, '\t' + text, 'code')
        for pc, n in self.inline.items():
            i = self.L.off(pc)
            tgt = rom[i] | rom[i + 1] << 8
            bk = rom[i + 2]
            nm = self.S.rom_name(bk, tgt)
            if nm:
                self.L.add(pc, 3, [f'\tdw {nm}', f'\tdb BANK({nm})'], 'data')
            else:
                self.L.add(pc, 3, [f'\tdw ${tgt:04X}', f'\tdb ${bk:02X}'])
