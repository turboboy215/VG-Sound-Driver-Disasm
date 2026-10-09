import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mkmain import build, verify
import mkheaders
HERE = os.path.dirname(os.path.abspath(__file__))
# default layout: Make\\<roms>, Make\\disasm\\*.s, Make\\disasm\\tool\\*.py
ROMDIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', '..')
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, '..')
GAMES = [
    ('cfg_dt2', 'Duck Tales 2 (E) [!].nes', 0x00000, 'duck_tales_2_sound'),
    ('cfg_cnd2', "Chip 'n Dale Rescue Rangers 2 (E).nes", 0x18000, 'chip_n_dale_2_sound'),
]
for cfgn, rom, off, name in GAMES:
    e, src, data = build(cfgn, os.path.join(ROMDIR, rom), off, getattr(mkheaders, cfgn, None))
    for w in e.warn:
        print(name, 'WARN', w)
    verify(src, e.start, e.end, data[e.start - 0x8000:e.end - 0x8000], name, OUT)
