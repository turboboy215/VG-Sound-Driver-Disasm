"""Runs every song and SFX through the real driver (harness ROM in PyBoy) and
compares the driver RAM after every frame with epoch_model.Model.

usage: python3 epoch_pyboy_check.py ds|dora harness.gb [frames]
"""
import sys
import os
os.environ.setdefault('SDL_VIDEODRIVER', 'dummy')
sys.path.insert(0, os.path.dirname(__file__))
from pyboy import PyBoy
from epoch_cfg import load
from epoch_parse import parse
from epoch_model import Model

key, rom = sys.argv[1], sys.argv[2]
NF = int(sys.argv[3]) if len(sys.argv) > 3 else 2400
g = load(key)
R = parse(g)
RAM, S = g['ram'], g['struct']
FRAMEDONE = 0x018A


def ram_state(pb):
    mem = pb.memory
    glob = [mem[RAM + i] for i in (0, 1, 2, 3, 4, 5, 6, 7)]
    trks = [[mem[RAM + 9 + t * S + i] for i in range(S)] for t in range(6)]
    return glob, trks


def model_state(md):
    glob = [md.music_id, md.sfx_id, md.mtracks, md.stracks, md.mtempo, md.stempo,
            md.pan, md.panflag]
    trks = [md.t[i].m[:S] for i in range(6)]
    return glob, trks


def run(kind, idx, nframes, sfx_at=None, sfx_id=None):
    pb = PyBoy(rom, window='null', sound_emulated=False)
    pb.set_emulation_speed(0)
    md = Model(g)
    md.pan = 0xFF
    md.stop_music()
    md.stop_sfx()
    state = {'n': 0, 'err': None}

    def hook(_):
        n = state['n']
        if state['err'] or n >= nframes:
            state['n'] += 1
            return
        md.output()
        md.update()
        a, b = ram_state(pb), model_state(md)
        if a != b:
            ga, ta = a
            gb_, tb = b
            msg = [f'frame {n}:']
            if ga != gb_:
                msg.append(f'  globals emu {ga} model {gb_}')
            for t in range(6):
                if ta[t] != tb[t]:
                    d = [(i, ta[t][i], tb[t][i]) for i in range(S) if ta[t][i] != tb[t][i]]
                    msg.append(f'  track {t}: (off, emu, model) {[(hex(i), hex(x), hex(y)) for i, x, y in d]}')
            state['err'] = '\n'.join(msg)
        if sfx_at is not None and n == sfx_at:
            pb.memory[0xFF84] = sfx_id
            pb.memory[0xFF83] = 1
            md.play(True, sfx_id)
        state['n'] += 1

    while pb.register_file.PC < 0x100:     # PyBoy runs its boot ROM first
        pb.tick(1, False)
    pb.tick(10, False)                    # harness clears RAM, then waits
    pb.hook_register(0, FRAMEDONE, hook, None)
    pb.memory[0xFF81] = idx
    pb.memory[0xFF82] = 1 if kind == 'sfx' else 0
    pb.memory[0xFF80] = 1
    md.play(kind == 'sfx', idx)
    while state['n'] < nframes and not state['err']:
        pb.tick(10, False)
    pb.stop(save=False)
    return state['err'], state['n']


bad = 0
for kind in ('music', 'sfx'):
    for i in range(len(R[kind])):
        err, n = run(kind, i, NF if kind == 'music' else 600)
        print(f'{kind} {i:02X}: {"OK" if not err else "MISMATCH"} ({min(n, NF)} frames)')
        if err:
            bad += 1
            print(err)
# music with SFX on top (exercises the SFX output path and the NR51 handling)
for i in range(len(R['sfx'])):
    err, n = run('music', 0, 900, sfx_at=200 + 13 * i, sfx_id=i)
    print(f'music 00 + sfx {i:02X}: {"OK" if not err else "MISMATCH"}')
    if err:
        bad += 1
        print(err)
print('mismatches:', bad)
