"""Generic byte-exact RGBDS asm generator for small GB ROM regions.

A Gen holds: rom, sections, code entry points, labels, comments, data items.
Data items are callables that render lines; they get a `ref` function that
turns an address into a label expression.
"""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from sm83 import decode, fmt, _s8
from codetrace import trace

HW = {
    0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13', 0x14: 'rNR14',
    0x16: 'rNR21', 0x17: 'rNR22', 0x18: 'rNR23', 0x19: 'rNR24',
    0x1A: 'rNR30', 0x1B: 'rNR31', 0x1C: 'rNR32', 0x1D: 'rNR33', 0x1E: 'rNR34',
    0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44',
    0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52', 0x30: '_AUD3WAVERAM',
    0x05: 'rTIMA', 0x06: 'rTMA', 0x07: 'rTAC', 0xFF: 'rIE', 0x44: 'rLY',
    0x40: 'rLCDC', 0x41: 'rSTAT', 0x47: 'rBGP', 0x48: 'rOBP0', 0x49: 'rOBP1',
}


class Gen:
    def __init__(self, rom):
        self.rom = rom
        self.sections = []          # (name, start, end_exclusive, comment)
        self.entries = []
        self.labels = {}            # addr -> name
        self.comments = {}          # addr -> eol comment
        self.blocks = {}            # addr -> block comment text (before label)
        self.items = {}             # addr -> (len, render(ref)->list[str])
        self.symbols = {}           # addr (>=$8000) -> name   (RAM / HRAM)
        self.consts = {}            # addr (<$8000, outside sections) -> name
        self.operand = {}           # addr -> replacement operand text for code
        self.code = {}
        self.header = ''
        self.macros = ''

    # ---------------------------------------------------------------
    def in_sections(self, a):
        return any(s <= a < e for _, s, e, _ in self.sections)

    def analyse(self, stop=()):
        code, xr, _ = trace(self.rom, self.entries, stop)
        self.code = {a: n for a, n in code.items() if self.in_sections(a)}
        for a in self.code:
            n, t, v, f = decode(self.rom, a)
            if f and f[0] in ('jp', 'jpc', 'jr', 'jrc', 'call', 'callc'):
                tgt = f[1]
                if self.in_sections(tgt):
                    self.labels.setdefault(tgt, 'L%04X' % tgt)
                elif tgt not in self.consts:
                    self.consts[tgt] = 'X%04X' % tgt

    def ref(self, a, exact_only=False):
        if a in self.labels:
            return self.labels[a]
        if a in self.consts:
            return self.consts[a]
        if exact_only:
            return None
        # find containing labelled item or code
        best = None
        for s in self.labels:
            if s <= a and (best is None or s > best):
                best = s
        if best is not None and a - best < 0x100 and self.in_sections(a):
            # only if no other item boundary between (keep it simple)
            return '%s+%d' % (self.labels[best], a - best)
        return '$%04X' % a

    # ---------------------------------------------------------------
    def code_line(self, a):
        rom = self.rom
        n, t, v, f = decode(rom, a)
        if a in self.operand:
            text = t.replace('{}', self.operand[a]).replace('{b}', self.operand[a]).replace('{h}', self.operand[a])
        elif f and f[0] in ('jp', 'jpc', 'jr', 'jrc', 'call', 'callc'):
            text = fmt(t, v, self.ref(f[1]))
        elif f and f[0] == 'rst':
            text = t
        elif '{h}' in t:
            nm = HW.get(v) or self.symbols.get(0xFF00 + v)
            text = t.replace('{h}', nm if nm else '$FF%02X' % v)
        elif '{}' in t:
            if v >= 0x8000 and v in self.symbols:
                text = fmt(t, v, self.symbols[v])
            elif v < 0x8000 and (v in self.labels) and t.startswith(('ld bc', 'ld de', 'ld hl', 'ld sp')):
                text = fmt(t, v, self.labels[v])
            elif v >= 0x8000 and t.startswith(('ld [', 'ld a, [')):
                nm = self.symbols.get(v)
                text = fmt(t, v, nm if nm else '$%04X' % v)
            else:
                text = fmt(t, v)
        else:
            text = fmt(t, v)
        if text.startswith('ld hl, sp+'):
            text = text.replace('sp+-', 'sp-').replace('sp+', 'sp+')
        if text.startswith('stop'):
            text = 'db $10, $%02X ; stop' % rom[a + 1]
        if 'illegal' in text:
            text = 'db $%02X ; illegal opcode' % rom[a]
        return n, text

    def emit(self):
        out = [self.header, self.macros]
        # symbols
        used_consts = sorted(self.consts.items())
        if used_consts:
            out.append('; ---- routines outside the disassembled ranges ----')
            for a, nm in used_consts:
                out.append(f'DEF {nm} EQU ${a:04X}')
            out.append('')
        if self.symbols:
            out.append('; ---- RAM / HRAM ----')
            for a, nm in sorted(self.symbols.items()):
                out.append(f'DEF {nm} EQU ${a:04X}')
            out.append('')
        out.append('; ---- hardware registers (subset of hardware.inc) ----')
        for v, nm in sorted(HW.items()):
            out.append(f'DEF {nm} EQU $FF{v:02X}')
        out.append('')
        for name, s, e, comment in self.sections:
            out.append('')
            if comment:
                for ln in comment.strip('\n').split('\n'):
                    out.append('; ' + ln if ln else ';')
            sect = 'ROM0' if s < 0x4000 else 'ROMX'
            if sect == 'ROM0':
                out.append(f'SECTION "{name}", ROM0[${s:04X}]')
            else:
                out.append(f'SECTION "{name}", ROMX[${s:04X}], BANK[{getattr(self, "bank", 1)}]')
            out.append('')
            a = s
            while a < e:
                if a in self.blocks:
                    out.append('')
                    for ln in self.blocks[a].strip('\n').split('\n'):
                        out.append('; ' + ln if ln else ';')
                if a in self.labels:
                    out.append(self.labels[a] + ':')
                c = self.comments.get(a)
                if a in self.code:
                    n, text = self.code_line(a)
                    line = '\t' + text
                    if c:
                        line = line.ljust(36) + '; ' + c
                    out.append(line)
                    a += n
                elif a in self.items:
                    n, render = self.items[a]
                    lines = render(self.ref)
                    for i, ln in enumerate(lines):
                        if i == 0 and c:
                            ln = ln.ljust(36) + '; ' + c
                        out.append('\t' + ln)
                    a += n
                else:
                    b = a + 1
                    while (b < e and b not in self.code and b not in self.items and
                           b not in self.labels and b not in self.blocks and b - a < 16):
                        b += 1
                    line = '\tdb ' + ', '.join('$%02X' % x for x in self.rom[a:b])
                    if c:
                        line = line.ljust(36) + '; ' + c
                    out.append(line)
                    a = b
        return '\n'.join(out) + '\n'

    def check_overlaps(self):
        """Items/code must not overlap each other."""
        occ = {}
        bad = []
        for a, n in self.code.items():
            for i in range(n):
                if a + i in occ:
                    bad.append((a + i, occ[a + i], 'code %04X' % a))
                occ[a + i] = 'code %04X' % a
        for a, (n, _) in self.items.items():
            for i in range(n):
                if a + i in occ:
                    bad.append((a + i, occ[a + i], 'item %04X' % a))
                occ[a + i] = 'item %04X' % a
        return bad
