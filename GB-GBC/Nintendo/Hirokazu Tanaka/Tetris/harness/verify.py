"""Play every song and effect of the rebuilt Tetris driver and check every data read."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
m = json.load(open(os.path.join(HERE, 'model.json')))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=1, model=os.path.join(HERE, 'model.json'),
           pat_pc=m['pat_pc'], list_pc=m['list_pc'], hl_pcs=m['hl_pcs'], song_req=0xdfe8, stop_value=0xff, songs=17, warmup=150,
           sfx=[('ch1 SFX', 0xdfe0, 8), ('ch3 SFX', 0xdff0, 2), ('ch4 SFX', 0xdff8, 4)])
text, bad = run_check(cfg, frames_song=int(sys.argv[1]) if len(sys.argv) > 1 else 3600)
print(text)
