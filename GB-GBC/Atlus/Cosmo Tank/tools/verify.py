"""Assemble CosmoTank_SoundDriver.asm and compare it with bank 4 of the ROM.
usage: python tools/verify.py <rom> <dir with the .asm/.inc>  (rgbasm/rgblink on PATH or RGBDS env var)"""
import os, subprocess, sys, tempfile
rom, d = sys.argv[1], sys.argv[2]
R = os.environ.get('RGBDS', '')
tmp = tempfile.mkdtemp()
subprocess.check_call([os.path.join(R, 'rgbasm'), '-Wall', '-I', d, '-o', os.path.join(tmp, 'ct.o'),
                       os.path.join(d, 'CosmoTank_SoundDriver.asm')])
subprocess.check_call([os.path.join(R, 'rgblink'), '-o', os.path.join(tmp, 'ct.gb'), os.path.join(tmp, 'ct.o')])
a = open(os.path.join(tmp, 'ct.gb'), 'rb').read()[0x10000:0x14000]
b = open(rom, 'rb').read()[0x10000:0x14000]
diff = [i for i in range(0x4000) if a[i] != b[i]]
print(f'bank 4: {len(a)} bytes, {len(diff)} mismatches' + (f', first at ${0x4000 + diff[0]:04X}' if diff else ''))
sys.exit(1 if diff else 0)
