"""Generate the Super Mario Bros. Deluxe sound driver sources: music bank $1D, SFX bank $1F."""
import sys, os, json, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
import ladx_music as LM
import smbdx_music as SM, smbdx_sfx as SS
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Super Mario Bros. Deluxe (U) (V1.0) [C][!].gbc')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
ram_used = {}

def write_bank(r, title, splits, asm, header, incs_pre='INCLUDE "SMB_Macros.inc"\n'):
    left = LM.finish(r, None, 0x4000)
    assert not left, [(hex(a), hex(b)) for a, b in left]
    parts = r.emit_split([(a, b) for a, b, _, _ in splits])
    incs = []
    for (a, b, fname, what), body in zip(splits, parts):
        w(fname, f'; {title}: {what}, bank ${r.bank:02X} ${a:04X}-${b-1:04X}\n\n' + body)
        incs.append(fname)
    for a, n in r.ram.items():
        if '+' not in n: ram_used[a] = n
    w(asm, f'; {header}\nINCLUDE "GB_Hardware.inc"\nINCLUDE "SMB_RAM.inc"\n' + incs_pre +
      f'\nSECTION "SMB DX sound bank ${r.bank:02X}", ROMX[$4000], BANK[${r.bank:02X}]\n' + ''.join(f'\tASSERT @ == ${a:04X}\nINCLUDE "{f}"\n' for (a, b, f, _) in splits))

# ---------------------------------------------------------------- music, bank $1D
r1d, s1d = SM.gen_1d(rom)
r1d.ram = dict(SS.RAM)
write_bank(r1d, 'Super Mario Bros. Deluxe music', [
    (0x4000, 0x4d96, 'SMB_1D_Driver.inc', 'music driver and tables'),
    (0x4d96, 0x4da2, 'SMB_1D_Songs1.inc', 'silent list'),
    (0x4da2, 0x5000, 'SMB_1D_Stop.inc', 'stop routines'),
    (0x5000, 0x8000, 'SMB_1D_Songs2.inc', 'songs')], 'SMB_Bank1D.asm', 'Super Mario Bros. Deluxe: music bank $1D (songs $62-$7F)')
os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
lab = {n: a for a, n in r1d.labels.items()}
json.dump({'pat_pc': lab['ReadPtrByte'] + 4, 'list_pc': lab['CopyWordIndirect'] + 4, 'song_ids': list(range(0x62, 0x80)),
           'patterns': {f'{p:04x}': [p, s1d.pat_events[p][1] + (1 if p in s1d.unterminated and r1d.byte(s1d.pat_events[p][1]) == 0 else 0)] for p in s1d.pat_events},
           'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if s1d.list_words[a][0] == 'loop' else []) for a in s1d.list_words), []))),
           'sfxdata': []}, open(os.path.join(OUT, 'harness', 'model_1D.json'), 'w'))

# ---------------------------------------------------------------- SFX, bank $1F
r1f, tabs, ents, drefs = SS.generate(rom)
write_bank(r1f, 'Super Mario Bros. Deluxe SFX', [
    (0x4000, 0x43a2, 'SMB_1F_Main.inc', 'init, update, tables'),
    (0x43a2, 0x448c, 'SMB_1F_Sfx1Start.inc', 'slot 1 dispatch'),
    (0x448c, 0x4737, 'SMB_1F_Sfx2Start.inc', 'slot 2 dispatch'),
    (0x4737, 0x485a, 'SMB_1F_Sfx4Start.inc', 'slot 4 dispatch, start / stop'),
    (0x485a, 0x67f1, 'SMB_1F_Effects.inc', 'effects'),
    (0x67f1, 0x8000, 'SMB_1F_Common.inc', 'note requests, shared routines, stop')], 'SMB_Bank1F.asm',
    'Super Mario Bros. Deluxe: SFX bank $1F', incs_pre='')
hooks = sorted(pc for pc, (l, fmt, args, k) in r1f.code.items()
               if (0x6838 <= pc < 0x68fb or 0x41b6 <= pc < 0x41c2 or 0x45fd <= pc < 0x460a) and re.match(r'ld [abcdelh], \[hl', fmt))
json.dump({'hl_pcs': hooks, 'sfxdata': sorted([a, a + sz, r1f.labels.get(a, '')] for a, (sz, e) in r1f.blocks.items()),
           'patterns': {}, 'list_words': [],
           'sfx': [['slot 1', 0xde60, list(range(0x42, 0x79)) + list(range(0x80, 0xa7))], ['slot 2', 0xde70, list(range(1, 5)) + list(range(0x24, 0x3e))],
                   ['slot 4', 0xde78, list(range(0x3e, 0x49))]]},
          open(os.path.join(OUT, 'harness', 'model_1F.json'), 'w'))

lines = ['; Super Mario Bros. Deluxe sound RAM ($DE00-$DEFF)', 'IF !DEF(SMB_RAM_INC)', 'DEF SMB_RAM_INC EQU 1']
for a in sorted(ram_used): lines.append(f'DEF {ram_used[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('SMB_RAM.inc', '\n'.join(lines) + '\n')
