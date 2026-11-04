#!/usr/bin/env python3
"""Compare two ARM ELF relocatable objects after resolving relocations at fixed
section addresses. Reports per-section identity and symbol differences.
usage: verify_gbass.py original/gbass.o rebuilt/gbass.o"""
import sys, struct
from elftools.elf.elffile import ELFFile

BASE = {'.text': 0x08000000, '.rodata': 0x08100000, '.data': 0x08200000,
        '.slowram': 0x02000000, '.medram3': 0x03001000, '.medram2': 0x03002000,
        '.medram1': 0x03003000, '.fastram': 0x03004000}
EXT = {'_call_via_r3': 0x09000000, '__divsi3': 0x09000100, '__muldi3': 0x09000200}

def load(path):
    e = ELFFile(open(path, 'rb'))
    secs = list(e.iter_sections())
    syms = list(e.get_section_by_name('.symtab').iter_symbols())
    def symval(s):
        shn = s['st_shndx']
        if shn == 'SHN_UNDEF':
            return EXT[s.name]
        if shn == 'SHN_ABS':
            return s['st_value']
        return BASE[secs[shn].name] + (s['st_value'] & ~1 if s['st_info']['type'] in ('STT_FUNC', 'STT_LOPROC') else s['st_value'])
    out = {}
    for name in BASE:
        sec = e.get_section_by_name(name)
        if sec is None:
            continue
        if sec['sh_type'] == 'SHT_NOBITS':
            out[name] = b'\0' * sec['sh_size']; continue
        d = bytearray(sec.data())
        rs = e.get_section_by_name('.rel' + name)
        if rs:
            for r in rs.iter_relocations():
                if r['r_info_type'] in (0, 40):
                    continue
                s = syms[r['r_info_sym']]
                S = symval(s)
                if s['st_info']['type'] in ('STT_FUNC', 'STT_LOPROC') or (s['st_info']['type'] == 'STT_FUNC'):
                    thumb = 1
                else:
                    thumb = 0
                off = r['r_offset']; P = BASE[name] + off; t = r['r_info_type']
                if t == 2:
                    A = struct.unpack_from('<I', d, off)[0]
                    if s['st_info']['type'] in ('STT_FUNC',) and s['st_value'] & 1:
                        S |= 1
                    struct.pack_into('<I', d, off, (S + A) & 0xffffffff)
                elif t == 10:
                    hi, lo = struct.unpack_from('<HH', d, off)
                    A = (((hi & 0x7ff) << 12) | ((lo & 0x7ff) << 1))
                    if A & 0x400000: A -= 0x800000
                    v = S + A - P
                    struct.pack_into('<HH', d, off, 0xf000 | ((v >> 12) & 0x7ff), 0xf800 | ((v >> 1) & 0x7ff))
                elif t == 1:
                    w = struct.unpack_from('<I', d, off)[0]
                    A = (w & 0xffffff) << 2
                    if A & 0x2000000: A -= 0x4000000
                    v = S + A - P
                    struct.pack_into('<I', d, off, (w & 0xff000000) | ((v >> 2) & 0xffffff))
                else:
                    raise SystemExit('reloc type %d' % t)
        out[name] = bytes(d)
    symset = {}
    for s in syms:
        if not s.name or s['st_info']['type'] in ('STT_SECTION', 'STT_FILE'):
            continue
        if (s.name.startswith('$') and len(s.name) <= 3) or s.name == '.gcc2_compiled.':
            continue
        if s['st_shndx'] == 'SHN_UNDEF':
            continue
        shn = s['st_shndx']
        sec = 'ABS' if shn == 'SHN_ABS' else secs[shn].name
        func = s['st_info']['type'] in ('STT_FUNC', 'STT_LOPROC')
        symset[s.name] = (sec, s['st_value'] & ~1 if func else s['st_value'], s['st_info']['bind'], func, s['st_size'])
    return out, symset

a, sa = load(sys.argv[1]); b, sb = load(sys.argv[2])
ok = True
for name in BASE:
    if name not in a:
        continue
    x, y = a[name], b.get(name)
    if y is None:
        print(name, 'MISSING'); ok = False; continue
    if x == y:
        print('%-9s identical (%d bytes)' % (name, len(x)))
    else:
        ok = False
        diffs = [i for i in range(min(len(x), len(y))) if x[i] != y[i]]
        print('%-9s DIFFER len %d vs %d, %d bytes differ, first at %s' % (name, len(x), len(y), len(diffs), [hex(i) for i in diffs[:20]]))
        if name == '.text' and '--fallback' in sys.argv:
            hs = sorted(set(i & ~1 for i in diffs))
            open(sys.argv[sys.argv.index('--fallback') + 1], 'a').write(' '.join('%x' % h for h in hs) + '\n')
missing = set(sa) - set(sb); extra = set(sb) - set(sa)
diff = [k for k in set(sa) & set(sb) if sa[k][:4] != sb[k][:4] or (sa[k][4] != sb[k][4])]
print('symbols: %d original, %d rebuilt, missing %d, extra %d, differing %d' % (len(sa), len(sb), len(missing), len(extra), len(diff)))
for k in sorted(missing)[:10]: print('  missing', k, sa[k])
for k in sorted(extra)[:10]: print('  extra', k, sb[k])
for k in sorted(diff)[:10]: print('  diff', k, sa[k], sb[k])
if missing or extra or diff:
    ok = False
print('RESULT:', 'IDENTICAL' if ok else 'MISMATCH')
