"""Verify the Ghostbusters II parse in an emulator harness (every sound id, normal and fast music).
usage: python3 verify_gb2.py <outdir> [frames_per_sound]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from harness import build_harness, run_verify
from verify_common import report

out = sys.argv[1]
FR = int(sys.argv[2]) if len(sys.argv) > 2 else 3600
model = json.load(open(os.path.join(out, 'model.json')))
rom_rebuilt = os.path.join(out, 'GB2_rebuilt.gb')
EXTRA = '\tcp 3\n\tjr nz, .done\n\tcall $07FA'
hr = build_harness(out, rom_rebuilt, dict(bank='7', mbc='$2100', init='$07FA', song='\tcall $07D4', sfx='\tcall $07D4',
                                         extra=EXTRA, update='\tcall $40B9', inc='../GB2_RAM.inc'))
# every byte the interpreter reads goes through hStreamPtr + de with `ld a,[hl]`; hook those instructions (hl = address)
# header: $4044 channel, $4089 pointer low, $409E pointer high; envelope: $4128 frames, $413C volume,
# $45B7 volume on restore; stream: $41BD byte, $41CD command, $41EA length, $43B1 argument
SITES = [0x4044, 0x4089, 0x409E, 0x4128, 0x413C, 0x45B7, 0x41BD, 0x41CD, 0x41EA, 0x43B1]
hooks = [(7, a, 'hl') for a in SITES]
info = model['info']
reads_all, per_all = {}, {}
for fast in (0, 1):
    jobs = [(1, i, FR, 'sound%d%s' % (i, '/fast' if fast else '')) for i in range(1, info['NS'])]
    def st(pb, cmd, arg, fast=fast):
        pb.memory[0xD611] = fast
    r, per = run_verify(hr, hooks, model, jobs, setup=st, stop=[(3, 0)])
    for a, w in r.items():
        reads_all.setdefault(a, set()).update(w)
    per_all.update(per)
txt, outside, unread = report('GB2', reads_all, model['reads'], [], per_all)
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
