"""Play every song and effect on the rebuilt Super Mario Land 2 driver and check every data read.
Requests go through WRAM mailboxes ($C000-$C003): PyBoy writes to cartridge RAM were not reliably
seen by the CPU once a song was playing."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=4, model=os.path.join(HERE, 'model.json'),
           pat_pc=0x555f, list_pc=0x544d,
           hl_pcs=[0x51ad, 0x51af, 0x51d3, 0x51d9, 0x5208, 0x520b, 0x522f, 0x5231, 0x52aa, 0x5aac, 0x5aae, 0x58ed, 0x5777],
           song_req=0xc000, song_play=0xa469, stop_value=0xff, songs=42, warmup=600,
           sfx=[('ch1 SFX', 0xc001, 24), ('ch3 SFX', 0xc002, 24), ('ch4 SFX', 0xc003, 11)])   # WRAM mailboxes, see harness.asm
text, bad = run_check(cfg, coverage_frames=int(sys.argv[1]) if len(sys.argv) > 1 else 0)
print(text)
