"""Generic RGBDS source generator for one ROMX bank region."""
import re
from sm83dis import decode

class Gen:
    def __init__(self, rom, bank, start, end):
        self.rom = rom; self.bank = bank; self.start = start; self.end = end
        self.base = bank * 0x4000 - 0x4000 if bank else 0
        self.labels = {}      # addr -> name
        self.items = {}       # addr -> (size, [lines])  lines already formatted (no indent handling)
        self.pre = {}         # addr -> list of comment/blank lines before label
        self.ram = {}         # addr -> symbol for RAM/HRAM
        self.consts = {}      # name -> value (emitted as EQU)
        self.codelabels = set()
        self.ptr_ok = set()   # addresses allowed to be labelised in ld r16,imm
        self.hw = {0xFF04:'rDIV',0xFF05:'rTIMA',0xFF06:'rTMA',0xFF07:'rTAC',0xFF10:'rNR10',0xFF11:'rNR11',0xFF12:'rNR12',
            0xFF13:'rNR13',0xFF14:'rNR14',0xFF16:'rNR21',0xFF17:'rNR22',0xFF18:'rNR23',0xFF19:'rNR24',0xFF1A:'rNR30',
            0xFF1B:'rNR31',0xFF1C:'rNR32',0xFF1D:'rNR33',0xFF1E:'rNR34',0xFF20:'rNR41',0xFF21:'rNR42',0xFF22:'rNR43',
            0xFF23:'rNR44',0xFF24:'rNR50',0xFF25:'rNR51',0xFF26:'rNR52',0xFF44:'rLY',0xFFFF:'rIE',0x2000:'rROMB0'}
    def rb(self, a): return self.rom[self.base + a]
    def rw(self, a): return self.rb(a) | self.rb(a + 1) << 8
    def lab(self, a, name=None):
        if name:
            self.labels[a] = name
        elif a not in self.labels:
            self.labels[a] = 'Snd_%04X' % a
        return self.labels[a]
    def ref(self, a):
        if a in self.labels: return self.labels[a]
        return '$%04X' % a
    def note(self, a, text):
        self.pre.setdefault(a, []).append(text)

    # ---------- code ----------
    def code_pass1(self, s, e):
        a = s
        m = lambda x: self.rom[self.base + x] if 0x4000 <= x < 0x8000 else self.rom[x]
        while a < e:
            n, t, tgt = decode(m, a)
            if tgt is not None and self.start <= tgt < self.end:
                self.lab(tgt)
                self.codelabels.add(tgt)
            a += n
    def code(self, s, e):
        a = s
        m = lambda x: self.rom[self.base + x] if 0x4000 <= x < 0x8000 else self.rom[x]
        while a < e:
            n, t, tgt = decode(m, a)
            if a + n > e:
                raise Exception('code overruns %04X' % a)
            t = self.fix(t, tgt)
            raw = ' '.join('%02X' % m(a + i) for i in range(n))
            self.items[a] = (n, ['\t%s' % t])
            a += n
    def fix(self, t, tgt):
        if t.startswith('db '):
            return t
        if tgt is not None:
            t = t.replace('$%04X' % tgt, self.ref(tgt))
        # ldh with hram
        mm = re.search(r'\[\$(FF[0-9A-F]{2})\]', t)
        if mm:
            v = int(mm.group(1), 16)
            if v in self.ram:
                t = t.replace('$' + mm.group(1), self.ram[v])
            elif v in self.hw:
                t = t.replace('$' + mm.group(1), self.hw[v])
        mm = re.search(r'\[\$([0-9A-F]{4})\]', t)
        if mm:
            v = int(mm.group(1), 16)
            if v in self.ram:
                t = t.replace('$' + mm.group(1), self.ram[v])
            elif v in self.hw:
                t = t.replace('$' + mm.group(1), self.hw[v])
        mm = re.match(r'ld (bc|de|hl),\$([0-9A-F]{4})$', t)
        if mm:
            v = int(mm.group(2), 16)
            if v in self.ptr_ok and v in self.labels:
                t = 'ld %s,%s' % (mm.group(1), self.labels[v])
            elif v in self.ram and v >= 0xC000:
                t = 'ld %s,%s' % (mm.group(1), self.ram[v])
        return t

    # ---------- data ----------
    def db(self, s, e, per=16, comment=None):
        a = s
        while a < e:
            n = min(per, e - a)
            # don't cross labels
            for k in range(1, n):
                if a + k in self.labels or a + k in self.pre:
                    n = k; break
            self.items[a] = (n, ['\tdb ' + ', '.join('$%02X' % self.rb(a + i) for i in range(n)) + (('\t; ' + comment) if comment else '')])
            a += n
    def dw(self, s, e, per=8, labelize=True):
        a = s
        while a < e:
            n = min(per, (e - a) // 2)
            for k in range(1, n):
                if a + 2 * k in self.labels:
                    n = k; break
            vals = []
            for i in range(n):
                v = self.rw(a + 2 * i)
                vals.append(self.ref(v) if labelize else '$%04X' % v)
            self.items[a] = (2 * n, ['\tdw ' + ', '.join(vals)])
            a += 2 * n
    def line(self, a, size, text):
        self.items[a] = (size, [text] if isinstance(text, str) else text)

    # ---------- output ----------
    def render(self, section_name, header=''):
        out = []
        out.append(header)
        out.append('SECTION "%s", ROMX[$%04X], BANK[$%X]' % (section_name, self.start, self.bank))
        out.append('')
        a = self.start
        while a < self.end:
            if a in self.pre:
                out.extend(self.pre[a])
            if a in self.labels:
                out.append('%s:' % self.labels[a])
            if a not in self.items:
                # fill with db until next item/label
                b = a + 1
                while b < self.end and b not in self.items and b not in self.labels and b not in self.pre:
                    b += 1
                self.db(a, b)
            n, lines = self.items[a]
            for k in range(1, n):
                if a + k in self.labels:
                    raise Exception('label %s inside item at %04X' % (self.labels[a + k], a))
            out.extend(lines)
            a += n
        return '\n'.join(out) + '\n'
