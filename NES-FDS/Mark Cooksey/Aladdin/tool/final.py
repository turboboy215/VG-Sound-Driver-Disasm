import sys, importlib; sys.path.insert(0,'.')
from main import *
GAMES = [
  ('cfg_dl', '/tmp/w/dl.nes', 0x0000, 0x4000, 'dragons_lair_sound'),
  ('cfg_jm', '/tmp/w/jm.nes', 0x16000, 0x2000, 'joe_and_mac_sound'),
  ('cfg_al', '/tmp/w/alad.nes', 0x0000, 0x8000, 'aladdin_sound'),
]
import headers
ok = True
res = {}
for cfgn, rom, off, size, name in GAMES:
    e, src = build(cfgn, rom, off, 0x8000, size, '.', getattr(headers, cfgn, None))
    for w in e.warn: print(name, 'WARN', w)
    prg = open(rom,'rb').read()[16:]
    orig = prg[off + e.start - 0x8000: off + e.end - 0x8000]
    ok &= verify(src, e.start, e.end, orig, name, '/tmp/w/out')
    res[name] = e
