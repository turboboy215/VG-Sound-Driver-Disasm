"""Song 3 (one-shot with a ritardando ending): real driver run to the end."""
import os, sys
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', 'tools'))
from pyboy import PyBoy
import ffl1parse as P
pb = PyBoy(P.ROMF, window='null', sound_emulated=False)
m = pb.memory
for f in range(600): pb.tick(1, False)
m[0xFFE0] = 0; pb.tick(8, False); m[0xFFE0] = int(os.environ.get('SONG', '3'))
FPS = 4194304 / 70224; ends = {}
while m[0xCE00] & 0x80: pb.tick(1, False)
for f in range(1, 40000):
    pb.tick(1, False)
    for c in range(3):
        if m[0xCE00 + 32 * c] & 0x80 and c not in ends: ends[c] = f
    if len(ends) == 3: break
print({P.CHN[c]: '%d frames = %.1f s' % (v, v / FPS) for c, v in ends.items()})
