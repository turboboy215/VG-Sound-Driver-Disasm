"""Play every song of the rebuilt music bank $28 and every effect of the SFX bank $29; check every
stream read and every data read made through the shared SFX routines."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
m = json.load(open(os.path.join(HERE, 'model_28.json')))
json.dump({'patterns': {str(a): [a, b] for a, b in m['spans']}, 'list_words': [], 'sfxdata': []},
          open(os.path.join(HERE, 'model_28_check.json'), 'w'))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=0x28, model=os.path.join(HERE, 'model_28_check.json'),
           pat_pc=m['read_pc'], list_pc=0, hl_pcs=[], song_req=0xc000, stop_value=0xff, songs=0,
           song_ids=m['song_ids'], warmup=150, sfx=[])
text, bad1 = run_check(cfg, coverage_frames=int(sys.argv[1]) if len(sys.argv) > 1 else 0)
print('music bank $28\n' + text)
m = json.load(open(os.path.join(HERE, 'model_29.json')))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=0x29, model=os.path.join(HERE, 'model_29.json'),
           pat_pc=0, list_pc=0, hl_pcs=m['hl_pcs'], song_req=0xc000, stop_value=0xff, songs=0, song_ids=[], warmup=150,
           sfx=[('ch1 SFX', 0xc001, m['counts']['1']), ('ch3 SFX', 0xc002, m['counts']['3']), ('ch4 SFX', 0xc003, m['counts']['4'])])
text, bad2 = run_check(cfg)
print('SFX bank $29\n' + text)
print('ALL problems:', bad1 + bad2)
