#!/usr/bin/env python3
"""Reproduce two driver bugs in emulation (needs py65: pip install py65).
usage: python tool/check_bugs.py "../McDonaldLand (E) [!].nes"
"""
import os, sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sim import Sim
prg = open(sys.argv[1], 'rb').read()[16:]
b10, b4 = prg[10 * 0x2000:11 * 0x2000], prg[4 * 0x2000:5 * 0x2000]
MUSIC_PLAY, SOUND_INIT, SFX_PLAY, UPDATE = 0x807A, 0x80C8, 0x81A5, 0x8237

# 1. An effect ending (or any track hitting TEND) returns from Sound_Update early:
#    the channels after it in the loop (lower numbers) miss that frame.
S = Sim(b10, b4); S.call(SOUND_INIT); S.call(MUSIC_PLAY, y=2)
seen = set(); S.mem.subscribe_to_write([0xD5], lambda a, v: seen.add(S.frame))
end = None
for f in range(400):
    S.frame = f
    if f == 100: S.call(SFX_PLAY, x=1)
    was = S.mem[0xAD]; S.call(UPDATE)
    if was & 0x80 and not S.mem[0xAD] & 0x80: end = f
print('1) song 2 + effect 1: effect ends on frame %d; Sq1 counter updated that frame: %s'
      % (end, end in seen))

# 2. Stale $4003/$4007 write cache: after an effect releases Sq2, the music's
#    period high byte is not rewritten until it changes.
for song, sid in ((2, 1), (1, 1), (4, 1), (9, 4)):
    S = Sim(b10, b4); S.call(SOUND_INIT); S.call(MUSIC_PLAY, y=song)
    hw = {}; bad = []
    for f in range(600):
        S.frame = f
        if f == 150: S.call(SFX_PLAY, x=sid)
        n0 = len(S.log); S.call(UPDATE)
        for _, a, v in S.log[n0:]: hw[a] = v
        if S.mem[0xDF] != 1 and S.mem[0xAA] & 0x80 and 0x4007 in hw:
            if (S.mem[0x7FB6] & 7) != (hw[0x4007] & 7): bad.append(f)
    print('2) song %d + effect %d: Sq2 plays with wrong period-high on frames %s' % (song, sid, bad))
