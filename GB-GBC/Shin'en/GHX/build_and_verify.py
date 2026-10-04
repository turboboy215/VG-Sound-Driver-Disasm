#!/usr/bin/env python3
"""Assemble every GHX disassembly with RGBDS and compare each section with the
original ROM it came from.

Usage:  python build_and_verify.py [path to the folder holding the ROMs]
        (default: the parent folder of this script)
Needs rgbasm and rgblink (RGBDS 0.9 or newer) on the PATH.
"""
import os, re, subprocess, sys, tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
ROMDIR = sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(HERE)

FILES = [
    ('ghx_example_sample.asm',                 'GHX Example Sample (PD) [C].gbc'),
    ('ghx_tombraider_bank7F_v2.0207.asm',      'Tomb Raider (UE) (M5) [C][!].gbc'),
    ('ghx_tombraider_bank7E_v00218.asm',       'Tomb Raider (UE) (M5) [C][!].gbc'),
    ('ghx_tombraider_bank0_pcm.asm',           'Tomb Raider (UE) (M5) [C][!].gbc'),
    ('ghx_jimmywhite_cueball_v00530.asm',      "Jimmy White's Cueball (E) [C][!].gbc"),
    ('ghx_spongebob_lostspatula_v01206t.asm',  'SpongeBob SquarePants - Legend of the Lost Spatula (U) [C][!].gbc'),
]

def sections(mapfile):
    """yield (file offset, size, name) for every section in an rgblink map file"""
    bank = 0
    for line in open(mapfile, encoding='utf-8', errors='replace'):
        m = re.match(r'\s*ROM[0X] bank #(\d+):', line)
        if m: bank = int(m.group(1)); continue
        m = re.match(r'\s*SECTION: \$([0-9a-fA-F]+)-\$([0-9a-fA-F]+) \(\$([0-9a-fA-F]+) bytes\) \["(.*)"\]', line)
        if m:
            start = int(m.group(1), 16); size = int(m.group(3), 16)
            off = start if start < 0x4000 else bank * 0x4000 + start - 0x4000
            yield off, size, m.group(4)

ok_all = True
with tempfile.TemporaryDirectory() as tmp:
    for asm, romname in FILES:
        rom = open(os.path.join(ROMDIR, romname), 'rb').read()
        obj = os.path.join(tmp, 'x.o'); out = os.path.join(tmp, 'x.gb'); mp = os.path.join(tmp, 'x.map')
        r = subprocess.run(['rgbasm', '-I', HERE, '-o', obj, os.path.join(HERE, asm)], capture_output=True, text=True)
        if r.returncode: print(asm, 'ASSEMBLY FAILED\n', r.stderr); ok_all = False; continue
        r = subprocess.run(['rgblink', '-m', mp, '-o', out, obj], capture_output=True, text=True)
        if r.returncode: print(asm, 'LINK FAILED\n', r.stderr); ok_all = False; continue
        img = open(out, 'rb').read()
        total = 0; bad = 0
        for off, size, name in sections(mp):
            total += size
            if img[off:off + size] != rom[off:off + size]:
                bad += 1; ok_all = False
                diff = next(i for i in range(size) if img[off + i] != rom[off + i])
                print('  MISMATCH in section "%s" at file offset $%X' % (name, off + diff))
        print('%-42s %7d bytes in sections: %s' % (asm, total, 'identical' if not bad else '%d section(s) differ' % bad))
print('ALL OK' if ok_all else 'SOME FILES DIFFER')
