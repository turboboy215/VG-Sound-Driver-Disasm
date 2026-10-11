"""Play every song of the rebuilt music banks $1B and $1E and check every data read."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
frames = int(sys.argv[1]) if len(sys.argv) > 1 else 0
total = 0
for bank in ('1B', '1E'):
    m = json.load(open(os.path.join(HERE, f'model_{bank}.json')))
    cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=int(bank, 16), model=os.path.join(HERE, f'model_{bank}.json'),
               pat_pc=m['pat_pc'], list_pc=m['list_pc'], hl_pcs=[], song_req=0xc000, stop_value=0xff, songs=0,
               song_ids=m['song_ids'], warmup=150, sfx=[])
    text, bad = run_check(cfg, coverage_frames=frames)
    print(f'bank ${bank}\n' + text); total += bad
print('ALL BANKS problems:', total)
