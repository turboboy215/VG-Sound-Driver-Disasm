"""Quirk check: after an SFX ends, CH1 stays out of NR51 until its pan sequence steps again."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import ffl1parse as P
pb = PyBoy(P.ROMF, window='null', sound_emulated=True)
m = pb.memory
for f in range(900): pb.tick(1, False)
sfx = int(os.environ.get('SFX', '1'))
m[0xFFE4] = sfx
log = []
for f in range(400):
    pb.tick(1, False)
    log.append((f, m[0xFF25], m[0xCE00] & 1, m[0xCE17], m[0xCE1C]))
prev = None
for f, nr51, busy, pt, pan in log:
    st = (nr51 & 0x11, busy)
    if st != prev: print('frame %3d NR51=%02X CH1bits=%02X sfx=%d panTimer=%d pan=%02X' % (f, nr51, nr51 & 0x11, busy, pt, pan)); prev = st
