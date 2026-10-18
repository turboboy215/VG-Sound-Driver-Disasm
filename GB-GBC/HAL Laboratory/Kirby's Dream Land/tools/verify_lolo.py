"""Verify the Lolo parse in an emulator harness (all songs, every pattern variant, all SFX).
usage: python3 verify_lolo.py <outdir> [frames_per_song] [frames_per_sfx]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from harness import build_harness, run_verify
from verify_common import find_de_reads, report

out = sys.argv[1]
FR = int(sys.argv[2]) if len(sys.argv) > 2 else 3600
FS = int(sys.argv[3]) if len(sys.argv) > 3 else 1800
model = json.load(open(os.path.join(out, 'model.json')))
rom_rebuilt = os.path.join(out, 'Lolo_rebuilt.gb')
rom = open(rom_rebuilt, 'rb').read()
items = {int(k, 16): v for k, v in model['items'].items()}
hr = build_harness(out, rom_rebuilt, dict(bank='$0F', mbc='$2100', init='$32E9', song='\tcall $3471', sfx='\tcall $334A',
                                         update='\tcall $34D8', inc='../Lolo_RAM.inc'))
sites = find_de_reads(rom, 0x0F, [(0x32AE, 0x3C17, items)])
hooks = [(0, a, 'de') for a in sites]
info = model['info']
pat_songs = {s for v in info['groups'].values() for s in v}
jobs = []
for i in range(info['NSONG']):
    if i in pat_songs:
        for v in range(5):
            jobs.append((1, i, FR, 'song%d/v%d' % (i, v)))
    else:
        jobs.append((1, i, FR, 'song%d' % i))
jobs += [(2, i, FS, 'sfx%d' % i) for i in range(info['NSFX'])]


# run one batch per pattern variant (wPatternVariant = $C95A is set before every job of the batch)
reads_all, per_all = {}, {}
jobs_by_variant = {}
for j in jobs:
    v = int(j[3].split('/v')[1]) if '/v' in j[3] else 0
    jobs_by_variant.setdefault(v, []).append(j)
for v, js in sorted(jobs_by_variant.items()):
    def st(pb, cmd, arg, v=v):
        pb.memory[0xC95A] = v
    r, per = run_verify(hr, hooks, model, js, setup=st)
    for a, w in r.items():
        reads_all.setdefault(a, set()).update(w)
    per_all.update(per)
txt, outside, unread = report('Lolo', reads_all, model['reads'], [(0x7C9D, 0x7D69)], per_all)
print('hook sites:', ' '.join('%04X' % a for a in sites))
print(txt)
runs = []
for a in unread:
    if runs and a == runs[-1][1] + 1:
        runs[-1][1] = a
    else:
        runs.append([a, a])
print('  never-read runs:', ' '.join('%04X-%04X' % (s, e) if s != e else '%04X' % s for s, e in runs[:100]))
json.dump({'per_job': per_all, 'outside': {('%04X' % a): sorted(map(str, v)) for a, v in outside.items()},
           'unread': ['%04X' % a for a in unread]}, open(os.path.join(out, 'harness', 'verify_result.json'), 'w'), indent=1)
