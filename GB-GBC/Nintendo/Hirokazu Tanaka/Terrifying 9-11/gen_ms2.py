"""Generate the Metal Slug 2 (unlicensed) sound driver sources: music bank $28, SFX bank $29.
The SFX bank is named by aligning it with the Link's Awakening DX SFX bank, so the LA ROM is
needed as well."""
import sys, os, json, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import ladx_music as LM
import ms2_music as MM, ms2_sfx as MS
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Metal Slug 2 (Unl) [C][f1].gbc')
LAROM = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, '..', "Legend of Zelda, The - Link's Awakening DX (U) (V1.0) [C][!].gbc")
OUT = sys.argv[3] if len(sys.argv) > 3 else HERE
rom = open(ROM, 'rb').read(); la = open(LAROM, 'rb').read()
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
ram_used = {}

def write_bank(r, title, splits, asm, header, incs_pre):
    left = LM.finish(r, None, 0x4000)
    assert not left, [(hex(a), hex(b)) for a, b in left]
    parts = r.emit_split([(a, b) for a, b, _, _ in splits])
    for (a, b, fname, what), body in zip(splits, parts):
        w(fname, f'; {title}: {what}, bank ${r.bank:02X} ${a:04X}-${b-1:04X}\n\n' + body)
    for a, n in r.ram.items():
        if '+' not in n: ram_used[a] = n
    w(asm, f'; {header}\nINCLUDE "GB_Hardware.inc"\nINCLUDE "MS2_RAM.inc"\n' + incs_pre +
      f'\nSECTION "MS2 sound bank ${r.bank:02X}", ROMX[$4000], BANK[${r.bank:02X}]\n' +
      ''.join(f'\tASSERT @ == ${a:04X}\nINCLUDE "{f}"\n' for (a, b, f, _) in splits))

r28, st, merged = MM.build(rom)
write_bank(r28, 'Metal Slug 2 music', [
    (0x4000, 0x4a28, 'MS2_28_Driver.inc', 'music driver and tables'),
    (0x4a28, 0x8000, 'MS2_28_Songs.inc', 'songs')], 'MS2_Bank28.asm', 'Metal Slug 2: music bank $28 (songs 1-10)',
    'INCLUDE "MS2_Macros.inc"\n')
os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
json.dump({'read_pc': r28.labels and {n: a for a, n in r28.labels.items()}['ReadPtrByte'] + 4,
           'spans': [[s, e + 1] for s, e in merged], 'song_ids': list(range(1, 11))},
          open(os.path.join(OUT, 'harness', 'model_28.json'), 'w'))

r29, tabs, ents, drefs, F = MS.generate(la, rom)
for a in range(0xc810, 0xc850): r29.ram.pop(a, None)
r29.ram.update(MM.RAM)
write_bank(r29, 'Metal Slug 2 SFX', [
    (0x4000, 0x411c, 'MS2_29_Main.inc', 'update and effect tables'),
    (0x411c, 0x5338, 'MS2_29_Sfx1.inc', 'ch1 effects'),
    (0x5338, 0x6433, 'MS2_29_Sfx3.inc', 'ch3 effects'),
    (0x6433, 0x799c, 'MS2_29_Sfx4.inc', 'ch4 effects'),
    (0x799c, 0x8000, 'MS2_29_Common.inc', 'shared routines, stop')], 'MS2_Bank29.asm', 'Metal Slug 2: SFX bank $29', '')
lab = {n: a for a, n in r29.labels.items()}
hooks = sorted(pc for pc, (l, fmt, args, k) in r29.code.items()
               if (lab['GetPointer'] <= pc < lab['Sound_Stop'] or lab['Sfx3_CopyWave'] <= pc < lab['Sfx3_CopyWave'] + 13)
               and re.match(r'ld [abcdelh], \[hl', fmt))
json.dump({'hl_pcs': hooks, 'sfxdata': sorted([a, a + sz, r29.labels.get(a, '')] for a, (sz, e) in r29.blocks.items()),
           'patterns': {}, 'list_words': [], 'counts': {'1': 65, '3': 35, '4': 61}},
          open(os.path.join(OUT, 'harness', 'model_29.json'), 'w'))

lines = ['; Metal Slug 2 sound RAM ($C800-$C8FF)', 'IF !DEF(MS2_RAM_INC)', 'DEF MS2_RAM_INC EQU 1']
for a in sorted(ram_used): lines.append(f'DEF {ram_used[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('MS2_RAM.inc', '\n'.join(lines) + '\n')
