"""Play every song and effect on the rebuilt Super Mario Land driver and check every data read."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=3, model=os.path.join(HERE, 'model.json'),
           pat_pc=0x6d47, list_pc=0x6c7b,
           hl_pcs=[0x6af2, 0x69db, 0x6a84, 0x6b1c],
           song_req=0xdfe8, song_play=0xdfe9, stop_value=0xff, songs=19, warmup=600,
           sfx=[('ch1 SFX', 0xdfe0, 11), ('ch4 SFX', 0xdff8, 4), ('ch3 SFX', 0xdff0, 1)])
text, bad = run_check(cfg, coverage_frames=int(sys.argv[1]) if len(sys.argv) > 1 else 0)
print(text)
