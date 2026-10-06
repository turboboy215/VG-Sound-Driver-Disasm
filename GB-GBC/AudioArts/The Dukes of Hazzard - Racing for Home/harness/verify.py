"""Run every song (and SFX) of a game in PyBoy through the harness and check that the
driver's pattern and step pointers only ever land on events/steps found by qtparse.

usage: verify.py <game> [frames]"""
import os
import sys
import logging
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'tools'))
os.environ['SDL_VIDEODRIVER'] = 'dummy'
logging.disable(logging.WARNING)
from pyboy import PyBoy
from qtcfg import GAMES
from qtparse import Data, fill_gaps
from qtram import ram_names

g = sys.argv[1]
FR = int(sys.argv[2]) if len(sys.argv) > 2 else 3600
c = GAMES[g]
D = Data(g)
D.run()
fill_gaps(D)
names, _ = ram_names(g)
off = {v: k for k, v in names.items()}
base = c['ram']
PAT = ('note', 'hold', 'keyoff', 'keyon', 'patend', 'songloop', 'sfxend', 'sfxloop')
pat_starts = set(a for a, it in D.items.items() if it.kind in PAT)
step_starts = set(a for a, it in D.items.items() if it.kind == 'step')
step_ends = set(a + it.size for a, it in D.items.items() if it.kind == 'step')
chans = [n for n in (1, 2, 3, 4) if 'seqadr%d' % n in off]

pb = PyBoy(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'harness_%s.gb' % g), window='null', sound_emulated=False)
pb.set_emulation_speed(0)
mem = pb.memory


def rd16(a):
    return mem[a] | mem[a + 1] << 8


def run_song(n, frames, sfx=False):
    mem[0xDFF1] = n
    mem[0xDFF0] = 2 if sfx else 1
    bad = []
    seen = set()
    for f in range(frames):
        pb.tick()
        for ch in chans:
            sa = rd16(base + off['seqadr%d' % ch])
            pa = rd16(base + off['patadr%d' % ch])
            seen.add(sa)
            if f < 2:
                continue
            if sa not in pat_starts and sa != c['tabs']['blankpat']:
                bad.append((f, ch, 'seq', sa))
            if pa not in step_starts and pa not in step_ends and pa != 0:
                bad.append((f, ch, 'step', pa))
        if sfx:
            se = rd16(base + off['seqadre'])
            seen.add(se)
            if se not in pat_starts:
                bad.append((f, 'sfx', 'seq', se))
    return bad, seen


# boot
for _ in range(2000):
    pb.tick()
    if mem[0xDFF2]:
        break
allseen = set()
nbad = 0
for s in D.songs:
    if s.get('invalid'):
        continue
    # silence first (song 0 is the blank song in every game except Carmageddon)
    bad, seen = run_song(s['n'], FR)
    allseen |= seen
    if bad:
        nbad += 1
        print('song %02X: %d bad samples, first %s' % (s['n'], len(bad), ['%s' % (b,) for b in bad[:3]]))
sfxbad = 0
for e in D.sfx:
    bad, seen = run_song(0, 2)   # restart song 0 (blank, except in Carmageddon)
    bad, seen = run_song(e['n'] + (0x1F if g == 'cmr' else 0), 600, sfx=True)
    allseen |= seen
    if bad:
        sfxbad += 1
        print('sfx %02X: %d bad samples, first %s' % (e['n'], len(bad), ['%s' % (b,) for b in bad[:3]]))
evs = set(a for a, it in D.items.items() if it.kind in PAT)
print('%s: %d songs x %d frames, %d SFX x 600 frames: %d songs and %d SFX with pointers off the parse; '
      'pattern positions visited: %d of %d parsed events' % (
          g, sum(1 for s in D.songs if not s.get('invalid')), FR, len(D.sfx), nbad, sfxbad,
          len(allseen & evs), len(evs)))
pb.stop()
