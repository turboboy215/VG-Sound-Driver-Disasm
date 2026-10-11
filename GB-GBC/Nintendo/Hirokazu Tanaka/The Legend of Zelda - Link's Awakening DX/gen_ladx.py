"""Generate the Link's Awakening DX sound driver sources: music banks $1B / $1E, SFX bank $1F."""
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import ladx_music as M
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', "Legend of Zelda, The - Link's Awakening DX (U) (V1.0) [C][!].gbc")
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
ram_used = {}

def write_bank(r, prefix, title, splits):
    left = M.finish(r, None, splits[1][0])
    assert not left, [(hex(a), hex(b)) for a, b in left]
    parts = r.emit_split([(a, b) for a, b, _, _ in splits])
    incs = []
    for (a, b, fname, what), body in zip(splits, parts):
        w(fname, f'; {title}: {what}, bank ${r.bank:02X} ${a:04X}-${b-1:04X}\n\n' + body)
        incs.append(fname)
    for a, n in r.ram.items():
        if '+' not in n: ram_used[a] = n
    return incs

def music_model(r, songs, song_ids):
    lab = {n: a for a, n in r.labels.items()}
    rd = lab['ReadPtrByte']; cw = lab['CopyWordIndirect']
    os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
    json.dump({'pat_pc': rd + 4, 'list_pc': cw + 4, 'song_ids': song_ids,
               'patterns': {f'{p:04x}': [p, songs.pat_events[p][1] + (1 if p in songs.unterminated and r.byte(songs.pat_events[p][1]) == 0 else 0)] for p in songs.pat_events},
               'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if songs.list_words[a][0] == 'loop' else []) for a in songs.list_words), []))),
               'sfxdata': []}, open(os.path.join(OUT, 'harness', f'model_{r.bank:02X}.json'), 'w'))

def music_bank(r, tag, title, songs_text):
    lab = {n: a for a, n in r.labels.items()}
    drv_end = lab['ReleaseEnvelopes'] + 7
    stop = lab['Sound_Stop']
    clear_ret = max(pc for pc in r.code if pc >= stop) + 1
    stop_end = min(a for a in r.labels if a >= clear_ret)
    inc = write_bank(r, tag, title, [
        (0x4000, drv_end, f'{tag}_Driver.inc', 'music driver and tables'),
        (drv_end, stop, f'{tag}_Songs1.inc', 'songs'),
        (stop, stop_end, f'{tag}_Stop.inc', 'stop routines'),
        (stop_end, 0x8000, f'{tag}_Songs2.inc', 'songs')])
    w(f'LA_Bank{r.bank:02X}.asm', f"; {title} ({songs_text})\n"
      'INCLUDE "GB_Hardware.inc"\nINCLUDE "LA_RAM.inc"\nINCLUDE "LA_Macros.inc"\n\n'
      f'SECTION "LA sound bank ${r.bank:02X}", ROMX[$4000], BANK[${r.bank:02X}]\n' +
      ''.join(f'INCLUDE "{f}"\n' for f in inc))

r1b, s1b = M.gen_1b(rom)
music_model(r1b, s1b, [i for i in range(1, 0x70) if 1 <= i <= 0x10 or 0x31 <= i <= 0x40 or 0x61 <= i <= 0x6f])
music_bank(r1b, 'LA_1B', "Link's Awakening DX music, bank $1B", 'songs $01-$10, $31-$40, $61-$6F')
r1e, s1e, st = M.gen_1e(rom, r1b)
music_model(r1e, s1e, [i for i in range(1, 0x70) if 0x11 <= i <= 0x30 or 0x41 <= i <= 0x60])
music_bank(r1e, 'LA_1E', "Link's Awakening DX music, bank $1E", 'songs $11-$30, $41-$60')

# ---------------------------------------------------------------- bank $1F
import ladx_sfx as S
r1f, tabs, ents, drefs = S.generate(rom)
S.finish(r1f, drefs)
lab = {n: a for a, n in r1f.labels.items()}
inc1f = write_bank(r1f, 'LA_1F', "Link's Awakening DX SFX, bank $1F", [
    (0x4000, 0x4204, 'LA_1F_Main.inc', 'init, update and effect tables'),
    (0x4204, 0x53ed, 'LA_1F_Sfx1.inc', 'ch1 effects'),
    (0x53ed, 0x63ec, 'LA_1F_Sfx3.inc', 'ch3 effects'),
    (0x63ec, 0x7a64, 'LA_1F_Sfx4.inc', 'ch4 effects'),
    (0x7a64, 0x8000, 'LA_1F_Common.inc', 'shared routines, stop, volume')])
w('LA_Bank1F.asm', "; Link's Awakening DX: SFX bank $1F\n"
  'INCLUDE "GB_Hardware.inc"\nINCLUDE "LA_RAM.inc"\n\n'
  'SECTION "LA sound bank $1F", ROMX[$4000], BANK[$1F]\n' + ''.join(f'INCLUDE "{f}"\n' for f in inc1f))

import re
hooks = sorted(pc for pc, (l, fmt, args, k) in r1f.code.items()
               if (0x7a64 <= pc < 0x7b5c or 0x6347 <= pc < 0x6354) and re.match(r'ld [abcdelh], \[hl', fmt))
json.dump({'hl_pcs': hooks, 'sfxdata': sorted([a, a + sz, r1f.labels.get(a, '')] for a, (sz, e) in r1f.blocks.items()),
           'patterns': {}, 'list_words': [], 'counts': {'1': 65, '3': 35, '4': 64}},
          open(os.path.join(OUT, 'harness', 'model_1F.json'), 'w'))

# ---------------------------------------------------------------- RAM
lines = ["; Link's Awakening DX sound RAM ($D300-$D3FF) and HRAM", 'IF !DEF(LA_RAM_INC)', 'DEF LA_RAM_INC EQU 1']
for a in sorted(ram_used):
    lines.append(f'DEF {ram_used[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('LA_RAM.inc', '\n'.join(lines) + '\n')
