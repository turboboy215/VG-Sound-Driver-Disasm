"""Verify the KDL2 parse in an emulator harness (all songs and SFX), per bank.
usage: python3 verify_kdl2.py <outdir> [frames_per_song] [frames_per_sfx]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from harness import build_harness, run_verify
from verify_common import find_de_reads, report

out = sys.argv[1]
FR = int(sys.argv[2]) if len(sys.argv) > 2 else 3600
FS = int(sys.argv[3]) if len(sys.argv) > 3 else 1800
model = json.load(open(os.path.join(out, 'model.json')))
rom_rebuilt = os.path.join(out, 'KDL2_rebuilt.gb')
rom = open(rom_rebuilt, 'rb').read()
items0 = {int(k, 16): v for k, v in model['items0'].items()}
# the game keeps an i*i table at $D700 (high bytes) / $D800 (low bytes) for its multiply routine ($293E)
os.makedirs(os.path.join(out, 'harness'), exist_ok=True)
open(os.path.join(out, 'harness', 'squares.bin'), 'wb').write(bytes([(i * i) >> 8 for i in range(256)] + [(i * i) & 255 for i in range(256)]))
PRE = '''\tld a, $1E
\tldh [$FFA4], a
\tld hl, Squares
\tld de, $D700
\tld bc, 512
.copy
\tld a, [hli]
\tld [de], a
\tinc de
\tdec bc
\tld a, b
\tor c
\tjr nz, .copy'''
SECT = 'SECTION "squares", ROM0[$0300]\nSquares:\n\tINCBIN "squares.bin"'
SONG = '\tld e, a\n\tld a, $1F\n\tld [$2100], a\n\tldh [$FFA4], a\n\tcall $4232\n\tld a, $1E\n\tldh [$FFA4], a'
SFX = '\tld e, a\n\tld a, $1E\n\tldh [$FFA4], a\n\tcall $4299'
hr = build_harness(out, rom_rebuilt, dict(bank='$1E', mbc='$2100', pre=PRE, sections=SECT, init='$4232', song=SONG, sfx=SFX,
                                         update='\tcall $2BFD\n\tld a, $1E\n\tldh [$FFA4], a', inc='../KDL2_RAM.inc'))
sites0 = find_de_reads(rom, 0x1E, [(0x2B97, 0x30E0, items0)])
hooks = [(0, a, 'de') for a in sites0]
# header reads in PlaySfx (bank $1E) and PlaySong (bank $1F)
for b, a in [(0x1E, 0x42EB), (0x1F, 0x4263)]:
    hooks.append((b, a, 'de'))
info = model['info']
jobs = [(1, i, FR, 'song%d' % i) for i in range(info['NSONG'])] + [(2, i, FS, 'sfx%d' % i) for i in range(info['NSFX'])]
reads, per = run_verify(hr, hooks, model, jobs, bankfn=lambda pb: pb.memory[0xFFA4])
res = {}
for bank, key in ((0x1E, 'readsE'), (0x1F, 'readsF')):
    rb = {a[1]: w for a, w in reads.items() if isinstance(a, tuple) and a[0] == bank}
    allowed = [(0x4000, 0x4000 + 4 * info['NINS'])]
    txt, outside, unread = report('KDL2 bank $%02X' % bank, rb, model[key], allowed, per)
    print(txt)
    runs = []
    for a in unread:
        if runs and a == runs[-1][1] + 1:
            runs[-1][1] = a
        else:
            runs.append([a, a])
    print('  never-read runs:', ' '.join('%04X-%04X' % (s, e) if s != e else '%04X' % s for s, e in runs[:100]))
    res['%02X' % bank] = {'outside': {('%04X' % a): sorted(map(str, v)) for a, v in outside.items()}, 'unread': ['%04X' % a for a in unread]}
other = [a for a in reads if isinstance(a, tuple) and a[0] not in (0x1E, 0x1F)]
print('reads with another bank mapped:', len(other), other[:5])
res['per_job'] = per
json.dump(res, open(os.path.join(out, 'harness', 'verify_result.json'), 'w'), indent=1)
