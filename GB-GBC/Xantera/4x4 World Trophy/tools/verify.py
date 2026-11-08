"""Assemble 4x4WorldTrophy_sound.asm and compare it with the ROM.

usage: python tools/verify.py "4x4 World Trophy (E) (M5) [C][!].gbc"
(run from the folder holding the .asm/.inc files; rgbasm/rgblink on PATH)
"""
import subprocess, sys, os, tempfile
rom = open(sys.argv[1], 'rb').read()
tmp = tempfile.mkdtemp()
o, g = os.path.join(tmp, 'x.o'), os.path.join(tmp, 'x.gb')
subprocess.check_call(['rgbasm', '-o', o, '4x4WorldTrophy_sound.asm'])
subprocess.check_call(['rgblink', '-p', '0xFF', '-o', g, o])
out = open(g, 'rb').read()
ok = True
for name, a, b in (('bank 00 $3343-$3918', 0x3343, 0x3919),
                   ('bank 3C $4000-$6D3B', 0x3C * 0x4000, 0x3C * 0x4000 + 0x2D3C)):
    bad = sum(1 for i in range(a, b) if rom[i] != out[i])
    print('%s: %d bytes, %d mismatches' % (name, b - a, bad))
    ok &= bad == 0
sys.exit(0 if ok else 1)
