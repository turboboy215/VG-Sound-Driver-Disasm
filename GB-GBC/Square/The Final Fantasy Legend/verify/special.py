"""Special song ($FFE2): play song 15 over the title song, check that the title song resumes where it was."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import ffl1parse as P
pb = PyBoy(P.ROMF, window='null', sound_emulated=False)
m = pb.memory
for f in range(900): pb.tick(1, False)
snap = bytes(m[0xCE00 + i] for i in range(0x60)); tempo = m[0xFFEA]
print('before: song', m[0xFFE0], 'tempo', tempo, 'ptrs', ['%04X' % (m[0xCE02 + 32 * c] | m[0xCE03 + 32 * c] << 8) for c in range(3)])
m[0xFFE2] = 15
for f in range(1, 2000):
    pb.tick(1, False)
    if f == 3: print('during: song', m[0xFFE0], 'active', m[0xFFE3], 'tempo', m[0xFFEA], '| saved copy == title state at the request:', bytes(m[0xCE60 + i] for i in range(0x60)) == snap)
    if m[0xFFE3] == 0 and f > 3:
        print('resumed at frame', f, 'song', m[0xFFE0], 'tempo', m[0xFFEA], 'ptrs',
              ['%04X' % (m[0xCE02 + 32 * c] | m[0xCE03 + 32 * c] << 8) for c in range(3)])
        break
