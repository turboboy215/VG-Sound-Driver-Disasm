"""Build the two harness ROMs from the original ROMs (in the AJG folder).
Needs rgbasm/rgblink (RGBDS 0.9.1) on PATH.  usage: python build_harness.py"""
import os
import subprocess
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)


def find(name):
    for d in (ROOT, os.path.join(ROOT, 'roms')):
        p = os.path.join(d, name)
        if os.path.exists(p):
            return p
    raise SystemExit('ROM not found: ' + name)


for asm, rom, out, start in (('harness_popup.asm', 'Pop Up (U) [!].gb', 'popup_harness.gb', 0x7E60),
                             ('harness_bombjack.asm', 'Bomb Jack (U).gb', 'bombjack_harness.gb', 0x7A10)):
    base = os.path.join(HERE, asm[:-4])
    subprocess.check_call(['rgbasm', '-Wall', '-o', base + '.o', os.path.join(HERE, asm)])
    subprocess.check_call(['rgblink', '-t', '-n', base + '.sym', '-o', base + '.gb', base + '.o'])
    h = open(base + '.gb', 'rb').read()
    o = open(find(rom), 'rb').read()
    r = bytearray(o)
    r[0x101:0x104] = h[0x101:0x104]
    assert not any(o[start:0x8000]), 'free space not empty'
    r[start:0x8000] = h[start:0x8000]
    open(os.path.join(HERE, out), 'wb').write(r)
    tick = [l.split()[0] for l in open(base + '.sym') if l.strip().endswith(' TickDone')][0]
    open(os.path.join(HERE, out + '.tickdone'), 'w').write(tick.split(':')[1])
    for ext in ('.o', '.gb'):
        os.remove(base + ext)
    print('built', out, 'TickDone =', tick)
