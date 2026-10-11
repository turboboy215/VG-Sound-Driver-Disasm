"""Play every song of the rebuilt music bank $1D and every effect of the SFX bank $1F, and check
every pattern / list read and every data read made through the shared SFX routines."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
m = json.load(open(os.path.join(HERE, 'model_1D.json')))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=0x1d, model=os.path.join(HERE, 'model_1D.json'),
           pat_pc=m['pat_pc'], list_pc=m['list_pc'], hl_pcs=[], song_req=0xc000, stop_value=0xff, songs=0,
           song_ids=m['song_ids'], warmup=150, sfx=[])
text, bad1 = run_check(cfg, coverage_frames=int(sys.argv[1]) if len(sys.argv) > 1 else 0)
print('music bank $1D\n' + text)
m = json.load(open(os.path.join(HERE, 'model_1F.json')))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=0x1f, model=os.path.join(HERE, 'model_1F.json'),
           pat_pc=0, list_pc=0, hl_pcs=m['hl_pcs'], song_req=0xc000, stop_value=0xff, songs=0, song_ids=[],
           warmup=150, sfx=[(n, {0xde60: 0xc001, 0xde70: 0xc002, 0xde78: 0xc003}[a], ids) for n, a, ids in m['sfx']])
text, bad2 = run_check(cfg)
print('SFX bank $1F\n' + text)
print('ALL problems:', bad1 + bad2)
