"""gbdis: SM83 disassembler / RGBDS source emitter for byte-exact rebuilds of a ROM region.

Usage pattern (see the per-game generators):
    d = Region(rom, bank, start, end)
    d.trace([entry points])           # recursive code trace
    d.code_range(a, b)                # force linear code (dead code)
    d.label(addr, name)               # name things
    d.block(addr, size, emitter)      # structured data
    text = d.emit()
"""
import re

R8 = ['b','c','d','e','h','l','[hl]','a']
R16 = ['bc','de','hl','sp']
R16S = ['bc','de','hl','af']
CC = ['nz','z','nc','c']
ALU = ['add a,','adc a,','sub','sbc a,','and','xor','or','cp']
ROT = ['rlc','rrc','rl','rr','sla','sra','swap','srl']

HWREGS = {
 0xff00:'rP1',0xff01:'rSB',0xff02:'rSC',0xff04:'rDIV',0xff05:'rTIMA',0xff06:'rTMA',0xff07:'rTAC',0xff0f:'rIF',
 0xff10:'rNR10',0xff11:'rNR11',0xff12:'rNR12',0xff13:'rNR13',0xff14:'rNR14',
 0xff16:'rNR21',0xff17:'rNR22',0xff18:'rNR23',0xff19:'rNR24',
 0xff1a:'rNR30',0xff1b:'rNR31',0xff1c:'rNR32',0xff1d:'rNR33',0xff1e:'rNR34',
 0xff20:'rNR41',0xff21:'rNR42',0xff22:'rNR43',0xff23:'rNR44',
 0xff24:'rNR50',0xff25:'rNR51',0xff26:'rNR52',
 0xff40:'rLCDC',0xff41:'rSTAT',0xff42:'rSCY',0xff43:'rSCX',0xff44:'rLY',0xff45:'rLYC',0xff46:'rDMA',
 0xff47:'rBGP',0xff48:'rOBP0',0xff49:'rOBP1',0xff4a:'rWY',0xff4b:'rWX',0xff4d:'rKEY1',0xff4f:'rVBK',
 0xff70:'rSVBK',0xffff:'rIE'}
for i in range(16): HWREGS[0xff30+i] = f'_AUD3WAVERAM+{i}' if i else '_AUD3WAVERAM'

def hx8(v): return f'${v:02x}'
def hx16(v): return f'${v:04x}'

def decode(rom, off, pc):
    """-> (length, fmt, args, kind)
    fmt uses {0},{1}.. for args; args are tuples (type, value):
      ('i8',v) ('i16',v) ('a16',v) ('io',v) ('rel',target) ('jp',target) ('call',target) ('rst',v) ('sp8',v)
    kind: None, 'jr','jp','jrc','jpc','call','ret','retc','jphl','rst','bad','stop'"""
    op = rom[off]
    b1 = rom[off+1] if off+1 < len(rom) else 0
    b2 = rom[off+2] if off+2 < len(rom) else 0
    w = b1 | (b2<<8)
    rel = (pc + 2 + (b1-256 if b1>127 else b1)) & 0xffff
    if op == 0x00: return 1,'nop',[],None
    if op == 0x10: return 2,'stop',[],'stop'
    if op == 0x76: return 1,'halt',[],None
    if op == 0xCB:
        x=b1>>6; y=(b1>>3)&7; z=b1&7
        if x==0: return 2,f'{ROT[y]} {R8[z]}',[],None
        return 2,f'{["","bit","res","set"][x]} {y}, {R8[z]}',[],None
    x=op>>6; y=(op>>3)&7; z=op&7; p=y>>1; q=y&1
    if x==1: return 1,f'ld {R8[y]}, {R8[z]}',[],None
    if x==2: return 1,f'{ALU[y]} {R8[z]}',[],None
    if x==0:
        if z==0:
            if y==1: return 3,'ld [{0}], sp',[('a16',w)],None
            if y==3: return 2,'jr {0}',[('rel',rel)],'jr'
            if y>=4: return 2,f'jr {CC[y-4]}, {{0}}',[('rel',rel)],'jrc'
        if z==1:
            if q==0: return 3,f'ld {R16[p]}, {{0}}',[('i16',w)],None
            return 1,f'add hl, {R16[p]}',[],None
        if z==2:
            m = ['[bc]','[de]','[hl+]','[hl-]'][p]
            return 1,(f'ld {m}, a' if q==0 else f'ld a, {m}'),[],None
        if z==3: return 1,f'{"inc" if q==0 else "dec"} {R16[p]}',[],None
        if z==4: return 1,f'inc {R8[y]}',[],None
        if z==5: return 1,f'dec {R8[y]}',[],None
        if z==6: return 2,f'ld {R8[y]}, {{0}}',[('i8',b1)],None
        if z==7: return 1,['rlca','rrca','rla','rra','daa','cpl','scf','ccf'][y],[],None
    if x==3:
        if z==0:
            if y<4: return 1,f'ret {CC[y]}',[],'retc'
            if y==4: return 2,'ldh [{0}], a',[('io',0xff00|b1)],None
            if y==5: return 2,'add sp, {0}',[('sp8',b1)],None
            if y==6: return 2,'ldh a, [{0}]',[('io',0xff00|b1)],None
            if y==7: return 2,'ld hl, sp + {0}',[('sp8',b1)],None
        if z==1:
            if q==0: return 1,f'pop {R16S[p]}',[],None
            return 1,['ret','reti','jp hl','ld sp, hl'][p],[],('ret' if p<2 else ('jphl' if p==2 else None))
        if z==2:
            if y<4: return 3,f'jp {CC[y]}, {{0}}',[('jp',w)],'jpc'
            if y==4: return 1,'ldh [c], a',[],None
            if y==5: return 3,'ld [{0}], a',[('a16',w)],None
            if y==6: return 1,'ldh a, [c]',[],None
            if y==7: return 3,'ld a, [{0}]',[('a16',w)],None
        if z==3:
            if y==0: return 3,'jp {0}',[('jp',w)],'jp'
            if y==6: return 1,'di',[],None
            if y==7: return 1,'ei',[],None
            return 1,'db {0}',[('i8',op)],'bad'
        if z==4:
            if y<4: return 3,f'call {CC[y]}, {{0}}',[('call',w)],'call'
            return 1,'db {0}',[('i8',op)],'bad'
        if z==5:
            if q==0: return 1,f'push {R16S[p]}',[],None
            if p==0: return 3,'call {0}',[('call',w)],'call'
            return 1,'db {0}',[('i8',op)],'bad'
        if z==6: return 2,f'{ALU[y]} {{0}}',[('i8',b1)],None
        if z==7: return 1,'rst {0}',[('rst',y*8)],'rst'
    return 1,'db {0}',[('i8',op)],'bad'


class Region:
    def __init__(self, rom, bank, start, end, home_names=None):
        self.rom = rom; self.bank = bank; self.start = start; self.end = end
        self.code = {}          # pc -> decoded
        self.labels = {}        # addr -> name (exact)
        self.locals = {}        # addr -> local label name (.foo) attached to previous global
        self.blocks = {}        # addr -> (size, emitter)  emitter(region, addr) -> list of lines
        self.comments = {}      # addr -> comment text (line before)
        self.eol = {}           # addr -> end-of-line comment
        self.ram = {}           # addr -> name
        self.ram_struct = []    # (base, size, field_names{off:name}, prefix)
        self.consts = {}        # value-> name not used automatically
        self.overrides = {}     # pc -> {argindex: text}
        self.extern = home_names or {}  # addresses outside the region (home bank) -> names
        self.dead = set()       # code start addresses flagged as unreferenced
        self.noncode_refs = {}  # addr -> set of pcs referencing (for data labels)
        self.autoprefix = {}    # addr -> prefix for auto label
        self.section_breaks = {}
        self.exported = set()

    # ---- helpers
    def off(self, addr):
        if addr < 0x4000: return addr
        return self.bank*0x4000 + addr - 0x4000
    def byte(self, addr): return self.rom[self.off(addr)]
    def word(self, addr): return self.byte(addr) | self.byte(addr+1)<<8
    def inreg(self, a): return self.start <= a < self.end

    def label(self, addr, name, comment=None):
        self.labels[addr] = name
        if comment: self.comments[addr] = comment
    def block(self, addr, size, emitter):
        self.blocks[addr] = (size, emitter)

    def trace(self, entries, stop=()):
        work = list(entries)
        while work:
            pc = work.pop(); prev = None
            while True:
                if pc in self.code or not self.inreg(pc): break
                if any(b <= pc < b+s for b,(s,e) in self.blocks.items()): break
                d = decode(self.rom, self.off(pc), pc)
                self.code[pc] = d
                l, fmt, args, k = d
                tgt = args[0][1] if args and args[0][0] in ('rel','jp','call') else None
                if k in ('jr','jp'):
                    if tgt is not None and self.inreg(tgt): work.append(tgt)
                    break
                if k in ('jrc','jpc','call'):
                    if self.inreg(tgt) and tgt not in stop: work.append(tgt)
                if k in ('ret','jphl','bad','stop'): break
                # `ret nz` / `ret z` followed by the opposite conditional jump: the jump always happens
                if k in ('jrc', 'jpc') and prev and prev[3] == 'retc' and {prev[1].split()[1], fmt.split()[1].rstrip(',')} in ({'z', 'nz'}, {'c', 'nc'}):
                    break
                prev = d
                pc += l

    def code_range(self, a, b):
        pc = a
        while pc < b:
            d = decode(self.rom, self.off(pc), pc)
            self.code[pc] = d
            pc += d[0]
        assert pc == b, f'code_range {a:04x}-{b:04x} ends at {pc:04x}'

    def jumptable(self, addr, n, name=None, entry_names=None):
        """n little-endian code pointers; traces them and emits dw Label lines"""
        ents = [self.word(addr+2*i) for i in range(n)]
        self.trace([e for e in ents if self.inreg(e)])
        def em(r, a, ents=ents):
            return [f'\tdw {r.sym_addr(e)}' for e in ents]
        self.block(addr, 2*n, em)
        if name: self.label(addr, name)
        if entry_names:
            for e, nm in zip(ents, entry_names):
                if nm and e not in self.labels: self.label(e, nm)
        return ents

    # ---- symbol resolution
    def block_of(self, a):
        for b,(s,e) in self.blocks.items():
            if b <= a < b+s: return b
        return None

    def ensure_label(self, a, prefix=None):
        if a in self.labels: return self.labels[a]
        if a in self.code:
            p = prefix or self.autoprefix.get(a) or 'Code'
        else:
            p = prefix or self.autoprefix.get(a) or 'Data'
        name = f'{p}_{a:04X}'
        self.labels[a] = name
        return name

    def ram_sym(self, a):
        if a in self.ram: return self.ram[a]
        for base, size, fields, prefix in self.ram_struct:
            if base <= a < base+size:
                o = a-base
                if o in fields: return f'{prefix}{fields[o]}'
        return None

    def sym_addr(self, a, allow_mid=True):
        """symbol for an address used as a pointer/target"""
        if a in self.labels: return self.labels[a]
        if self.inreg(a):
            b = self.block_of(a)
            if b is not None and a != b:
                # nearest label at or before a inside the block
                cands = [x for x in self.labels if b <= x <= a]
                base = max(cands) if cands else b
                return f'{self.ensure_label(base)}+{a-base}'
            return self.ensure_label(a)
        if a in self.extern: return self.extern[a]
        r = self.ram_sym(a)
        if r: return r
        if a in HWREGS: return HWREGS[a]
        return hx16(a)

    def render_arg(self, pc, i, arg):
        t, v = arg
        ov = self.overrides.get(pc, {})
        if i in ov: return ov[i]
        if t == 'i8': return hx8(v)
        if t == 'sp8': return hx8(v)
        if t == 'rst': return hx8(v)
        if t in ('rel','jp','call'):
            if self.inreg(v):
                n = self.sym_addr(v)
                if '.' in n and '+' not in n and n.split('.',1)[0] == getattr(self, '_scope', None):
                    return '.' + n.split('.',1)[1]
                return n
            return self.extern.get(v, hx16(v))
        if t == 'io':
            if v in HWREGS: return HWREGS[v]
            rs = self.ram_sym(v)
            return rs if rs else hx16(v)
        if t == 'a16':
            if v in HWREGS: return HWREGS[v]
            return self.sym_addr(v)
        if t == 'i16':
            if self.inreg(v) and (v in self.labels or v in self.code or self.block_of(v) is not None or v in self.noncode_refs):
                return self.sym_addr(v)
            r = self.ram_sym(v)
            if r: return r
            if v in self.extern: return self.extern[v]
            return hx16(v)
        raise ValueError(t)

    def collect_refs(self, data_ptr_ok=lambda pc, v: True):
        """Make labels for every code target and for in-region pointers used by code."""
        for pc, (l, fmt, args, k) in self.code.items():
            for i, (t, v) in enumerate(args):
                if i in self.overrides.get(pc, {}): continue
                if t in ('rel','jp','call') and self.inreg(v):
                    self.ensure_label(v, 'Code' if v in self.code else 'Data')
                if t in ('a16',) and self.inreg(v):
                    self.noncode_refs.setdefault(v,set()).add(pc)
                if t == 'i16' and self.inreg(v) and data_ptr_ok(pc, v):
                    self.noncode_refs.setdefault(v,set()).add(pc)
        for v in list(self.noncode_refs):
            if v not in self.labels and self.block_of(v) is None:
                self.ensure_label(v)

    # ---- emission
    def fix_scopes(self):
        """local labels must follow their parent global label; otherwise make them global"""
        cur = None
        for a in sorted(self.labels):
            n = self.labels[a]
            if '.' in n:
                if n.split('.',1)[0] != cur:
                    self.labels[a] = n.replace('.', '_', 1)
            else:
                cur = n

    def emit(self, start=None, end=None):
        self._emit(self.start, self.end)          # first pass creates every label
        self.fix_scopes()
        return self._emit(start or self.start, end or self.end)

    def emit_split(self, ranges):
        self._emit(self.start, self.end)
        self.fix_scopes()
        return [self._emit(a, b) for a, b in ranges]

    def _emit(self, start, end):
        out = []
        pc = start
        glob = [a for a in sorted(self.labels) if a <= start and '.' not in self.labels[a]]
        self._scope = self.labels[glob[-1]] if glob else None
        def lab(a):
            lines = []
            if a in self.comments:
                for c in self.comments[a].split('\n'): lines.append(f'; {c}' if c else ';')
            if a in self.labels:
                nm = self.labels[a]
                if '.' in nm:
                    lines.append('.' + nm.split('.',1)[1] + ':')
                else:
                    self._scope = nm
                    lines.append(f'{nm}:' + ('::' if nm in self.exported else '')[:0])
            return lines
        while pc < end:
            if pc in self.blocks:
                size, em = self.blocks[pc]
                assert pc + size <= end, f'block {pc:04x}+{size} crosses emit range end {end:04x}'
                out += lab(pc)
                body = em(self, pc)
                out += body
                pc += size
                continue
            if pc in self.code:
                out += lab(pc)
                l, fmt, args, k = self.code[pc]
                txt = fmt.format(*[self.render_arg(pc, i, a) for i, a in enumerate(args)])
                c = self.eol.get(pc)
                out.append(f'\t{txt}' + (f'\t; {c}' if c else ''))
                pc += l
                if k in ('jp','jr','ret','jphl') and pc not in self.labels and pc in self.code:
                    pass
                if k in ('jp','jr','ret','jphl'): out.append('')
                continue
            # raw gap: run until next label/code/block
            out += lab(pc)
            run = [pc]
            q = pc+1
            while q < end and q not in self.code and q not in self.blocks and q not in self.labels and len(run) < 16:
                run.append(q); q += 1
            c = self.eol.get(pc)
            out.append('\tdb ' + ', '.join(hx8(self.byte(a)) for a in run) + (f'\t; {c}' if c else ''))
            pc = q
        return '\n'.join(out) + '\n'

def find_jumptables(r):
    """addresses T used as `ld hl,T ... jp hl` (within 4 instructions)"""
    pcs = sorted(r.code)
    out = set()
    for i, pc in enumerate(pcs):
        l, fmt, args, k = r.code[pc]
        if fmt.startswith('ld hl, ') and args and args[0][0] == 'i16' and r.inreg(args[0][1]):
            for j in range(i+1, min(i+5, len(pcs))):
                f2 = r.code[pcs[j]]
                if f2[1] == 'jp hl': out.add(args[0][1]); break
                if f2[3] in ('jp', 'jr', 'ret'): break
    return out

def gap_code_candidates(r, lo=None, hi=None, minlen=3):
    """linear-decode raw gaps; report tails that decode to instructions ending in jp/jr/ret into known code"""
    lo = lo or r.start; hi = hi or r.end
    out = []
    a = lo
    while a < hi:
        if a in r.code or r.block_of(a) is not None:
            a += r.code[a][0] if a in r.code else 1; continue
        b = a
        while b < hi and b not in r.code and r.block_of(b) is None: b += 1
        # try every start inside the gap
        for s in range(a, b):
            pc = s; ok = True; n = 0
            while pc < b:
                l, fmt, args, k = decode(r.rom, r.off(pc), pc)
                if k == 'bad': ok = False; break
                n += 1
                if k in ('jp', 'jr', 'ret'):
                    tgt = args[0][1] if args else None
                    if pc + l == b and (k == 'ret' or tgt in r.code) and n >= minlen:
                        out.append((s, b, n))
                    break
                pc += l
            if out and out[-1][0] == s: break
        a = b
    return out
