#!/usr/bin/env python3
"""Assemble mcdonaldland_sound.s with ca65/ld65 and compare with the ROM.
usage (from the disasm folder): python tool/verify.py "../McDonaldLand (E) [!].nes"
"""
import os, subprocess, sys
here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
rom = open(sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, '..', 'McDonaldLand (E) [!].nes'), 'rb').read()[16:]
os.chdir(here)
subprocess.check_call(['ca65', 'mcdonaldland_sound.s', '-o', 'mcdonaldland_sound.o'])
subprocess.check_call(['ld65', '-C', 'mcdonaldland_sound.cfg', 'mcdonaldland_sound.o'])
ok = True
for f, bank in (('bank10_sound.bin', 10), ('bank04_sound.bin', 4)):
    b = open(f, 'rb').read()
    ref = rom[bank * 0x2000: bank * 0x2000 + len(b)]
    same = b == ref
    ok &= same
    print('%-17s %5d bytes  %s' % (f, len(b), 'identical' if same else 'DIFFERS'))
sys.exit(0 if ok else 1)
