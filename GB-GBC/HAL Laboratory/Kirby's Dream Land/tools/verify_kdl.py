"""Verify the KDL parse: build harness from the rebuilt ROM, play everything, check reads.
usage: python3 verify_kdl.py <outdir> [frames_per_song] [frames_per_sfx]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from harness import build_harness, run_verify
from verify_common import find_de_reads, report

out = sys.argv[1]
FR = int(sys.argv[2]) if len(sys.argv) > 2 else 3600
FS = int(sys.argv[3]) if len(sys.argv) > 3 else 1800
model = json.load(open(os.path.join(out, 'model.json')))
rom_rebuilt = os.path.join(out, 'KDL_rebuilt.gb')
rom = open(rom_rebuilt, 'rb').read()
items = {int(k, 16): v for k, v in model['items'].items()}
# the game builds a floor(i*i/2) table at $DC00 (lo bytes, then hi bytes) that Multiply_AxE uses
os.makedirs(os.path.join(out, 'harness'), exist_ok=True)
open(os.path.join(out, 'harness', 'multab.bin'), 'wb').write(bytes([(i * i // 2) & 255 for i in range(256)] + [(i * i // 2) >> 8 for i in range(256)]))
PRE = '''\tld hl, MulTable\n\tld de, $DC00\n\tld bc, 512\n.copy\n\tld a, [hli]\n\tld [de], a\n\tinc de\n\tdec bc\n\tld a, b\n\tor c\n\tjr nz, .copy'''
SECT = '''SECTION "multab", ROMX[$7B00], BANK[5]\nMulTable:\n\tINCBIN "multab.bin"'''
hr = build_harness(out, rom_rebuilt, dict(bank=5, mbc='$2100', pre=PRE, sections=SECT,
                                         init='$4C4A', song='\tcall $4DC5', sfx='\tcall $4C9E', update='\tcall $4E0B',
                                         inc='../KDL_RAM.inc'))
sites = find_de_reads(rom, 5, [(0x4C4A, 0x54DF, items)])
hooks = [(5, a, 'de') for a in sites]
info = model['info']
jobs = [(1, i, FR, 'song%d' % i) for i in range(info['NSONG'])] + [(2, i, FS, 'sfx%d' % i) for i in range(info['NSFX'])]
reads, per = run_verify(hr, hooks, model, jobs)
txt, outside, unread = report('KDL', reads, model['reads'], [(0x78D3, 0x79AB)], per)
print('hook sites:', ' '.join('%04X' % a for a in sites))
print(txt)
# group unread by contiguous runs
runs = []
for a in unread:
    if runs and a == runs[-1][1] + 1:
        runs[-1][1] = a
    else:
        runs.append([a, a])
print('  never-read runs:', ' '.join('%04X-%04X' % (s, e) if s != e else '%04X' % s for s, e in runs[:80]), '...' if len(runs) > 80 else '')
json.dump({'per_job': per, 'outside': {('%04X' % a): sorted(map(str, v)) for a, v in outside.items()},
           'unread': ['%04X' % a for a in unread]}, open(os.path.join(out, 'harness', 'verify_result.json'), 'w'), indent=1)
