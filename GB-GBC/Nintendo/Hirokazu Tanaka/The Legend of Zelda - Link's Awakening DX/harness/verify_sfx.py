"""Play every effect of the rebuilt SFX bank $1F and check that every data read made through the
shared routines (register images, pointer tables, pitch tables, waves) lands in a data block."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
m = json.load(open(os.path.join(HERE, 'model_1F.json')))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=0x1f, model=os.path.join(HERE, 'model_1F.json'),
           pat_pc=0x0000, list_pc=0x0000, hl_pcs=m['hl_pcs'], song_req=0xc000, stop_value=0xff, songs=0, song_ids=[],
           warmup=150, sfx=[('ch1 SFX', 0xc001, m['counts']['1']), ('ch3 SFX', 0xc002, m['counts']['3']), ('ch4 SFX', 0xc003, m['counts']['4'])])
text, bad = run_check(cfg, frames_sfx=int(sys.argv[1]) if len(sys.argv) > 1 else 600)
print(text)
