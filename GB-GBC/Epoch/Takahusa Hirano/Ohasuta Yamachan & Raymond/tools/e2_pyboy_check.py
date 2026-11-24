"""Cross-check e2_cpu.py against PyBoy.

The game ROM is copied and its bank 0 replaced by a small harness that
calls $4000 (init) or $4003 (update) in a chosen bank whenever Python asks
(HRAM $FF80 = 1/2, $FF81 = bank). The same calls are made in e2_cpu, and the
256 bytes of driver RAM are compared after every call.

python e2_pyboy_check.py [game ...]
"""
import os
import sys
import tempfile

sys.path.insert(0, os.path.dirname(__file__))
from e2_parse import analyze, GAMES, rom  # noqa: E402
from e2_cpu import CPU  # noqa: E402
import e2_check  # noqa: E402

HARNESS = bytes([
    # $0150
    0xF3,                    # di
    0x31, 0x00, 0xC1,        # ld sp,$C100
    0xAF,                    # xor a
    0xE0, 0x80,              # ldh [$FF80],a
    # $0157 loop:
    0xF0, 0x80,              # ldh a,[$FF80]
    0xB7,                    # or a
    0x28, 0xFB,              # jr z,loop
    0x47,                    # ld b,a
    0xF0, 0x81,              # ldh a,[$FF81]
    0xEA, 0x00, 0x20,        # ld [$2000],a
    0x78,                    # ld a,b
    0xFE, 0x01,              # cp 1
    0x20, 0x05,              # jr nz,+5
    0xCD, 0x00, 0x40,        # call $4000
    0x18, 0x03,              # jr +3
    0xCD, 0x03, 0x40,        # call $4003
    0xAF,                    # xor a
    0xE0, 0x80,              # ldh [$FF80],a
    0x18, 0xE3,              # jr loop
])


def make_rom(game):
    d = bytearray(rom(game))
    for a in range(0x0000, 0x0100):
        d[a] = 0xFF
    for a in range(0x0150, 0x4000):
        d[a] = 0x00
    d[0x0100:0x0104] = bytes([0x00, 0xC3, 0x50, 0x01])
    d[0x0150:0x0150 + len(HARNESS)] = HARNESS
    # header checksum
    x = 0
    for a in range(0x134, 0x14D):
        x = (x - d[a] - 1) & 0xFF
    d[0x14D] = x
    return bytes(d)


def main(games):
    from pyboy import PyBoy
    bad = 0
    for game in games:
        d = make_rom(game)
        path = os.path.join(tempfile.gettempdir(), 'e2_harness_%s.gbc' % game)
        open(path, 'wb').write(d)
        pb = PyBoy(path, window='null', sound_emulated=False)
        pb.set_emulation_speed(0)
        for _ in range(400):
            pb.tick()
        ram = GAMES[game]['ram'] << 8
        cpu = CPU(d)
        cpu.sp = 0xC100
        cpu.io[0x26] = 0x80
        for i in range(0x100):        # same starting RAM on both sides
            cpu.wram[ram - 0xC000 + i] = pb.memory[ram + i]
        g = GAMES[game]
        runs = []
        for mb in g['music'][:3]:
            B = analyze(game, mb)
            for h in sorted(B.songs)[:2]:
                runs.append(('mus', mb, B.songs[h]['ids'][0]))
        S = analyze(game, g['sfx'])
        sfx_ids = sorted(set(s['ids'][0] for s in S.songs.values()))
        calls = 0
        mism = 0
        for kind, bank, sid in runs:
            seq = [('set', 0x01, 0xFF), ('set', 0x00, sid), (1, bank)]
            for f in range(1500):
                if f == 200:
                    seq += [('set', 0x01, sfx_ids[(sid + 1) % len(sfx_ids)]), (1, g['sfx'])]
                if e2_check.SFX_FIRST[game]:
                    seq += [(2, g['sfx']), (2, bank)]
                else:
                    seq += [(2, bank), (2, g['sfx'])]
            for it in seq:
                if it[0] == 'set':
                    pb.memory[ram + it[1]] = it[2]
                    cpu.wram[ram - 0xC000 + it[1]] = it[2]
                    continue
                act, bank = it
                pb.memory[0xFF81] = bank
                pb.memory[0xFF80] = act
                n = 0
                while pb.memory[0xFF80] != 0:
                    pb.tick()
                    n += 1
                    if n > 5:
                        raise RuntimeError('harness stuck')
                cpu.bank = bank
                cpu.call(0x4000 if act == 1 else 0x4003)
                cpu.log = []
                calls += 1
                a = [pb.memory[ram + i] for i in range(0x100)]
                b = list(cpu.wram[ram - 0xC000:ram - 0xC000 + 0x100])
                if a != b:
                    mism += 1
                    if mism <= 3:
                        diff = [(i, a[i], b[i]) for i in range(0x100) if a[i] != b[i]]
                        print(game, 'call %d bank %02X act %d: %s' % (calls, bank, act, diff[:6]))
                    for i in range(0x100):       # resync and go on
                        cpu.wram[ram - 0xC000 + i] = a[i]
        pb.stop(save=False)
        print('%s: %d driver calls in PyBoy and e2_cpu, %d with RAM differences' % (game, calls, mism))
        bad += mism
    return bad


if __name__ == '__main__':
    sys.exit(1 if main(sys.argv[1:] or list(GAMES)) else 0)
