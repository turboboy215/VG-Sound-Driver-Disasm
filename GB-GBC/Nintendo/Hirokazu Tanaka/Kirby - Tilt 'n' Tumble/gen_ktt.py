"""Generate the Kirby Tilt 'n' Tumble sound driver sources: music banks $0E / $0F, SFX banks $11 / $14,
and the PCM player in the home bank."""
import sys, os, json
HERE = os.path.dirname(os.path.abspath(__file__))
for p in ('', '../SMBDX', '../LADX', '../tools'):
    sys.path.insert(0, os.path.join(HERE, p))
import ladx_music as LM
import ktt_music as KM
import ktt_sfx as KS
import ktt_pcm as KP
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', "Kirby's Tilt 'n' Tumble (U) [C][!].gbc")
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)
ram_used = {}
models = {}


def write_bank(r, title, splits, asm, header, incs_pre='INCLUDE "KTT_Macros.inc"\n'):
    left = LM.finish(r, None, 0x4000)
    assert not left, [(hex(a), hex(b)) for a, b in left]
    parts = r.emit_split([(a, b) for a, b, _, _ in splits])
    for (a, b, fname, what), body in zip(splits, parts):
        w(fname, f'; {title}: {what}, bank ${r.bank:02X} ${a:04X}-${b-1:04X}\n\n' + body)
    for a, n in r.ram.items():
        if '+' not in n: ram_used[a] = n
    w(asm, f'; {header}\nINCLUDE "GB_Hardware.inc"\nINCLUDE "KTT_RAM.inc"\n' + incs_pre +
      f'\nSECTION "KTT sound bank ${r.bank:02X}", ROMX[$4000], BANK[${r.bank:02X}]\n' + ''.join(f'\tASSERT @ == ${a:04X}\nINCLUDE "{f}"\n' for (a, b, f, _) in splits))


def music_model(r, s, song_ids):
    lab = {n: a for a, n in r.labels.items()}
    return {'pat_pc': lab['ReadPtrByte'] + 4, 'list_pc': lab['CopyWordIndirect'] + 4, 'song_ids': song_ids,
            'patterns': {f'{p:04x}': [p, s.pat_events[p][1] + (1 if p in s.unterminated and r.byte(s.pat_events[p][1]) == 0 else 0)] for p in s.pat_events},
            'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if s.list_words[a][0] in ('loop', 'cmd') else []) for a in s.list_words), []))),
            'sfxdata': []}


# ---------------------------------------------------------------- music, banks $0E / $0F
r0e, s0e = KM.gen_0e(rom)
r0f, s0f, st = KM.gen_0f(rom, r0e)
print(f'bank $0F: {st[0]} of {st[2]} instructions aligned with bank $0E')
for r, s, ids, rng in ((r0e, s0e, list(range(0x01, 0x40)), '$01-$3F'), (r0f, s0f, list(range(0x40, 0x80)), '$40-$7F')):
    b = r.bank
    write_bank(r, "Kirby Tilt 'n' Tumble music", [
        (0x4000, 0x5000, f'KTT_{b:02X}_Driver.inc', 'music driver and tables'),
        (0x5000, 0x8000, f'KTT_{b:02X}_Songs.inc', 'songs')], f'KTT_Bank{b:02X}.asm', f"Kirby Tilt 'n' Tumble: music bank ${b:02X} (songs {rng})")
    models[f'{b:02X}'] = music_model(r, s, [i for i in ids if r.word(0x4043 + 2*(i-1)) in s.headers])

# ---------------------------------------------------------------- SFX, banks $11 / $14
r11, t11, e11, d11 = KS.generate_11(rom)
r14, t14, e14, d14, st14 = KS.generate_14(rom, r11)
print(f'bank $14: {st14[0]} of {st14[2]} helper instructions aligned with bank $11')
for r, eff, com, rng in ((r11, 0x454a, 0x788d, '$01-$7F'), (r14, 0x4296, 0x5afe, '$80-$97')):
    b = r.bank
    write_bank(r, "Kirby Tilt 'n' Tumble SFX", [
        (0x4000, eff, f'KTT_{b:02X}_Main.inc', 'init, update, tables'),
        (eff, com, f'KTT_{b:02X}_Effects.inc', 'effects'),
        (com, 0x8000, f'KTT_{b:02X}_Common.inc', 'slot dispatch, shared routines, priorities, stop')], f'KTT_Bank{b:02X}.asm',
        f"Kirby Tilt 'n' Tumble: SFX bank ${b:02X} (effects {rng})", incs_pre='')
import re
def sfx_model(r, tables, ids):
    hooks = sorted(pc for pc, (l, fmt, args, k) in r.code.items() if re.match(r'ld [abcdelh], \[hl', fmt) and
                   (r.labels.get(max(x for x in r.labels if x <= pc), '').startswith(('Set', 'Sfx_', 'Sfx1_L', 'Sfx2_L', 'Sfx3_L', 'Sfx1_A', 'Sfx2_A', 'Sfx3_A', 'Sfx1_Sw', 'Sfx2_Sw', 'GetPointer'))))
    return {'hl_pcs': hooks, 'sfxdata': sorted([a, a + sz, r.labels.get(a, '')] for a, (sz, e) in r.blocks.items()),
            'patterns': {}, 'list_words': [], 'sfx': ids}
models['11'] = sfx_model(r11, t11, [['slot 1', 0xde60, list(range(1, 0x80))], ['slot 2', 0xde70, list(range(1, 0x40))],
                                    ['slot 3', 0xde80, list(range(1, 9))], ['slot 4', 0xde78, list(range(1, 0x29))]])
models['14'] = sfx_model(r14, t14, [['slot 1', 0xde60, list(range(0x80, 0x98))], ['slot 2', 0xde70, list(range(0x80, 0x90))],
                                    ['slot 3', 0xde80, list(range(0x80, 0x88))], ['slot 4', 0xde78, list(range(0x80, 0x91))]])

os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
for key, m in models.items():
    json.dump(m, open(os.path.join(OUT, 'harness', f'model_{key}.json'), 'w'))

# ---------------------------------------------------------------- PCM player (home bank) and the samples as WAV
w('KTT_Home.asm', KP.gen_home(rom))
for s, name, secs in KP.export_wavs(rom, os.path.join(OUT, 'pcm')):
    print(f'sample {s["index"]}: bank ${s["bank"]:02X} ${s["start"]:04X}-${s["end"]:04X}, {s["rate"]:.1f} Hz, {secs:.2f} s -> pcm/{name}')

lines = ["; Kirby Tilt 'n' Tumble sound RAM ($DE00-$DEFF, WRAM bank 7)", 'IF !DEF(KTT_RAM_INC)', 'DEF KTT_RAM_INC EQU 1']
for a in sorted(ram_used): lines.append(f'DEF {ram_used[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('KTT_RAM.inc', '\n'.join(lines) + '\n')
