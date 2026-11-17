"""Assemble the generated .asm files and compare them with the ROMs.

usage: python verify.py <Zoop ROM> <SROTJ ROM> [asmdir]
needs rgbasm/rgblink on PATH
"""
import os
import subprocess
import sys
import tempfile


def build(asmdir, files, tmp, name):
    objs = []
    for f in files:
        o = os.path.join(tmp, f + '.o')
        subprocess.run(['rgbasm', '-Wall', '-I', asmdir, '-o', o, os.path.join(asmdir, f)], check=True)
        objs.append(o)
    rom = os.path.join(tmp, name)
    subprocess.run(['rgblink', '-p', '0xFF', '-o', rom] + objs, check=True)
    return open(rom, 'rb').read()


def compare(orig, built, bank, label):
    a = bank * 0x4000
    o = orig[a:a + 0x4000]
    b = built[a:a + 0x4000]
    bad = [i for i in range(0x4000) if i >= len(b) or o[i] != b[i]]
    print('%-40s bank %d $4000-$7FFF: %5d bytes, %d mismatches%s' % (
        label, bank, 0x4000, len(bad), '' if not bad else ' (first at $%04X)' % (0x4000 + bad[0])))
    return not bad


def main():
    zrom, srom = sys.argv[1], sys.argv[2]
    asmdir = sys.argv[3] if len(sys.argv) > 3 else '.'
    ok = True
    with tempfile.TemporaryDirectory() as tmp:
        z = build(asmdir, ['Zoop_SoundDriver.asm'], tmp, 'zoop.gb')
        ok &= compare(open(zrom, 'rb').read(), z, 3, 'Zoop_SoundDriver.asm')
        s = build(asmdir, ['SROTJ_SoundDriver_Bank4.asm', 'SROTJ_SoundDriver_Bank5.asm'], tmp, 'srotj.gb')
        so = open(srom, 'rb').read()
        ok &= compare(so, s, 4, 'SROTJ_SoundDriver_Bank4.asm')
        ok &= compare(so, s, 5, 'SROTJ_SoundDriver_Bank5.asm')
    print('OK' if ok else 'FAILED')
    sys.exit(0 if ok else 1)


if __name__ == '__main__':
    main()
