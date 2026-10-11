"""Play every song (bank $08: $01-$1C, bank $07: $1D-$23) and every effect ($01-$50, and the noise
slot) of the rebuilt Tetris Attack sound code; check every pattern / list read and every stream read."""
import os, sys, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
from playcheck import run_check
total = 0
for bank, model in ((8, 'model_08.json'), (7, 'model_07.json')):
    m = json.load(open(os.path.join(HERE, model)))
    cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=bank, model=os.path.join(HERE, model), pat_pc=m['pat_pc'], list_pc=m['list_pc'],
               hl_pcs=[], song_req=0xd368, stop_value=0xff, songs=0, song_ids=m['song_ids'], warmup=150, sfx=[])
    text, bad = run_check(cfg); total += bad
    print(f'music bank ${bank:02X}\n' + text)
m = json.load(open(os.path.join(HERE, 'model_07sfx.json')))
cfg = dict(rom=os.path.join(HERE, 'harness.gb'), bank=7, model=os.path.join(HERE, 'model_07sfx.json'), pat_pc=0, list_pc=0,
           hl_pcs=m['hl_pcs'], song_req=0xd368, stop_value=0xff, songs=0, song_ids=[], warmup=150, rom_only=True,
           sfx=[('effects', 0xd360, list(range(1, 0x51))), ('noise slot', 0xd370, [1])])
text, bad = run_check(cfg, frames_sfx=400); total += bad
print('SFX bank $07\n' + text)
print('ALL problems:', total)
