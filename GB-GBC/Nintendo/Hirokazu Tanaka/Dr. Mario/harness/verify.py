"""Play every song and effect on the rebuilt Dr. Mario driver and check every data read."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=1, model=os.path.join(HERE, 'model.json'),
           pat_pc=0x67c9, list_pc=0x6704,
           hl_pcs=[0x64d2, 0x629a, 0x62aa, 0x6315, 0x631f, 0x6360, 0x636a, 0x63a2, 0x63ac, 0x63f1, 0x64fd],
           song_req=0xdfe8, song_play=0xdfe9, stop_value=0xff, songs=10, warmup=600,
           sfx=[('ch1 SFX', 0xdfe0, 14), ('ch4 SFX', 0xdff8, 3)])
text, bad = run_check(cfg, coverage_frames=int(sys.argv[1]) if len(sys.argv) > 1 else 0)
print(text)
