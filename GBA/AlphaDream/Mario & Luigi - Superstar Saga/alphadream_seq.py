#!/usr/bin/env python3
"""AlphaDream GBA sound driver: reference sequence parser.

Covers the three driver revisions found in
  * Hamtaro - Rainbow Rescue          (rev A: 3-byte notes, fade commands)
  * Minna no Soft Series - Happy Trump 20,
    Hamtaro - Ham-Ham Games           (rev B: 3-byte notes, SFX priority, FA)
  * Mario & Luigi - Superstar Saga    (rev C: 2-byte notes, F1 = volume)

Tables are found from code signatures, so no per-game addresses are needed.
See alphadream-technical-reference.md for the format.

usage: alphadream_seq.py ROM                 summary + song list
       alphadream_seq.py ROM --song N        event listing of song N
       alphadream_seq.py ROM --sfx N         event listing of sound effect N
"""
import re
import struct
import sys

ROM = 0x08000000


class Rom:
    def __init__(self, path):
        self.d = open(path, 'rb').read()

    def b(self, a): return self.d[a - ROM]
    def u16(self, a): return struct.unpack_from('<H', self.d, a - ROM)[0]
    def s16(self, a): return struct.unpack_from('<h', self.d, a - ROM)[0]
    def s8(self, a): return struct.unpack_from('<b', self.d, a - ROM)[0]
    def u32(self, a): return struct.unpack_from('<I', self.d, a - ROM)[0]
    def isptr(self, v): return ROM <= v < ROM + len(self.d)

    def ldr_literal(self, a):
        """value loaded by the Thumb 'ldr rX, [pc, #imm]' at address a"""
        h = self.u16(a)
        assert h >> 11 == 0b01001, hex(a)
        return self.u32(((a + 4) & ~3) + (h & 0xFF) * 4)


# (regex over ROM bytes, offset of the 'ldr rX,[pc,#imm]' from the match start)
SIGS = {
    'song_table':   [(rb'.\x48[\xad\xa4]\x00[\x2d\x24]\x18[\x2d\x24]\x68[\xa8\xa0]\x46', 0)],
    'sfx_table':    [(rb'.\x48\x42\x46\x91\x00\x09\x18\x0c\x68\xa1\x46', 0),        # rev A, C
                     (rb'.\x49\x98\x00\x40\x18\x04\x68\xa2\x46.\x48', 0)],          # rev B
    'sfx_priority': [(rb'.\x49\x98\x00\x40\x18\x04\x68\xa2\x46.\x48', 10)],         # rev B only
    'inst_table':   [(rb'.\x4a\x41\x00\x89\x18\x09\x88\x89\x18\x01\x30', 0)],
    'sample_table': [(rb'.\x49\x50\x04\xc0\x0b\x0f\x58\x7f\x18', 0)],
    'op_table':     [(rb'\xe0\x38\x0a\x1c\x1f\x28..\x80\x00..\x40\x18', 10)],
}


def locate(rom):
    """find the driver tables and the revision; returns a dict (or None)"""
    t = {}
    for name, sigs in SIGS.items():
        for rx, off in sigs:
            for m in re.finditer(rx, rom.d, re.S):
                a = ROM + m.start() + off
                if a & 1:
                    continue
                try:
                    v = rom.ldr_literal(a)
                except AssertionError:
                    continue
                if rom.isptr(v):          # ROM copy (skip EWRAM multiboot copies)
                    t.setdefault(name, v)
                    break
            if name in t:
                break
    if 'op_table' not in t or 'song_table' not in t:
        return None
    ops = [rom.u32(t['op_table'] + 4 * i) for i in range(32)]
    note_default = ops[6]                                  # E6 is always "not a command"
    t['vel_notes'] = ops[0x11] == note_default             # F1 unused -> 3-byte notes
    t['fa_priority'] = ops[0x1A] != note_default           # FA = SFX channel priority
    t['rev'] = 'C' if not t['vel_notes'] else ('B' if t['fa_priority'] else 'A')
    # table sizes: pointer runs (the song table is NULL- or SFX-table-terminated)
    def run(a, stop=None):
        n = 0
        while a + 4 * n != stop and rom.isptr(rom.u32(a + 4 * n)):
            n += 1
        return n
    t['n_songs'] = run(t['song_table'], t.get('sfx_table'))
    t['n_sfx'] = run(t['sfx_table']) if 'sfx_table' in t else 0
    return t


def header(rom, a):
    """song / SFX header: u16 track mask, then one u16 offset per set bit"""
    mask = rom.u16(a)
    tracks, p = [], a + 2
    for ch in range(12):
        if mask >> ch & 1:
            tracks.append((ch, a + rom.u16(p)))
            p += 2
    return mask, tracks


OP_ARGS = {0xE0: 3, 0xE1: 0, 0xE2: 0, 0xE3: 3, 0xE4: 0, 0xE5: 0,
           0xF0: 1, 0xF1: 1, 0xF2: 1, 0xF3: 1, 0xF4: 1, 0xF5: 1, 0xF6: 1, 0xF9: 1}
OP_NAME = {0xE0: 'PITCH_LFO', 0xE1: 'PITCH_LFO_ON', 0xE2: 'PITCH_LFO_OFF',
           0xE3: 'VOL_LFO', 0xE4: 'VOL_LFO_ON', 0xE5: 'VOL_LFO_OFF',
           0xF0: 'PROGRAM', 0xF1: 'VOLUME', 0xF2: 'PAN', 0xF3: 'DETUNE',
           0xF4: 'BEND_RANGE', 0xF5: 'BEND', 0xF6: 'REST', 0xF7: 'NOTE_OFF',
           0xF8: 'GOTO', 0xF9: 'SPEED', 0xFA: 'SFX_PRIORITY', 0xFF: 'END'}


def events(rom, t, a, max_events=200000):
    """Walk one track as the driver does (jumps and loop counters followed).

    Yields (tick, address, name, args).  Stops at END, or at the first jump that
    returns to an address already played (the loop point; reported as
    ('LOOP', target)).  'NOTE' args: key, length (0 = tie), velocity or None, and
    the extra delay that follows (rest byte / tie wait) or None.
    """
    vel = t['vel_notes']
    tick, p, seen = 0, a, set()
    rest_follows = False            # track flag 0x20 (set by a key with bit 7)
    counters = [0, 0, 0, 0]
    for _ in range(max_events):
        c = rom.b(p)
        if c == 0xFF:
            yield tick, p, 'END', ()
            return
        if c == 0xF8:
            tgt = p + 3 + rom.s16(p + 1)
            if tgt in seen:
                yield tick, p, 'LOOP', (tgt,)
                return
            yield tick, p, 'GOTO', (tgt,)
            p = tgt
            continue
        seen.add(p)
        if 0xE8 <= c <= 0xEF:                            # never used by the four games
            n, off, i = rom.b(p + 1), rom.s16(p + 2), c & 3
            p += 4
            counters[i] += 1
            if c < 0xEC:                                 # loop A
                if counters[i] > n:
                    p += off
                else:
                    counters[i] = 0
            elif counters[i] <= n:                       # loop B
                p += off
                counters[i] = 0
            yield tick, p, 'LOOP_%s%d' % ('A' if c < 0xEC else 'B', c & 3), (n, off)
            continue
        if c == 0xFA and t['fa_priority']:
            yield tick, p, 'SFX_PRIORITY', (rom.b(p + 1),)
            p += 2
            continue
        if c in OP_ARGS and not (c == 0xF1 and vel):
            n = OP_ARGS[c]
            args = tuple(rom.b(p + 1 + i) for i in range(n))
            yield tick, p, OP_NAME[c], args
            p += 1 + n
            if c == 0xF6:
                tick += args[0]
            continue
        if c == 0xF7:
            p += 1
            extra = None
            if rest_follows:
                extra = rom.b(p)
                p += 1
            yield tick, p - 1, 'NOTE_OFF', (extra,)
            if extra:
                tick += extra
            continue
        # note: E6/E7/FA-FE (rev-dependent) also land here, as in the driver
        length, key = c, rom.b(p + 1)
        velocity = rom.b(p + 2) if vel else None
        q = p + (3 if vel else 2)
        extra = None
        if length == 0:                                  # tie / legato
            if key & 0x80:
                extra = rom.b(q)
                q += 1
        else:
            if key & 0x80:
                rest_follows = True
            if rest_follows:
                extra = rom.b(q)
                q += 1
        yield tick, p, 'NOTE', (key & 0x7F, length, velocity, extra)
        tick += length + (extra or 0)
        p = q


def summary(rom, t, a):
    """(track count, length in ticks, loop tick or None, first SPEED, programs)"""
    mask, trs = header(rom, a)
    length, loop, speed, progs = 0, None, None, set()
    for ch, ta in trs:
        start = {}
        last = 0
        for tick, p, name, args in events(rom, t, ta):
            start.setdefault(p, tick)
            last = tick
            if name == 'SPEED' and speed is None:
                speed = args[0]
            if name == 'PROGRAM':
                progs.add(args[0])
            if name == 'LOOP':
                loop = start.get(args[0]) if loop is None else loop
        length = max(length, last)
    return mask, len(trs), length, loop, speed, sorted(progs)


def bpm(speed, divisor=75, ppqn=48, fps=16777216 / 280896):
    """tempo implied by SPEED with the default divisor (ticks/frame = speed/75)"""
    return speed / divisor * fps * 60 / ppqn


def main(argv):
    rom = Rom(argv[1])
    t = locate(rom)
    if not t:
        print('AlphaDream driver not found')
        return 1
    print('revision %s  (%s notes%s)' % (t['rev'], '3-byte' if t['vel_notes'] else '2-byte',
                                       ', SFX priority' if t['fa_priority'] else ''))
    for k in ('song_table', 'sfx_table', 'sfx_priority', 'inst_table', 'sample_table', 'op_table'):
        if k in t:
            print('  %-13s %08X' % (k, t[k]))
    print('  songs %d, sfx %d' % (t['n_songs'], t['n_sfx']))
    if len(argv) > 3 and argv[2] in ('--song', '--sfx'):
        tbl = t['song_table'] if argv[2] == '--song' else t['sfx_table']
        a = rom.u32(tbl + 4 * int(argv[3], 0))
        mask, trs = header(rom, a)
        print('header %08X  mask %03X' % (a, mask))
        for ch, ta in trs:
            print('\n  track %d (channel %d) @ %08X' % (ch, ch, ta))
            for tick, p, name, args in events(rom, t, ta):
                print('    %6d  %08X  %-12s %s' % (tick, p, name, ' '.join(str(x) for x in args)))
        return 0
    for i in range(t['n_songs']):
        a = rom.u32(t['song_table'] + 4 * i)
        mask, n, length, loop, speed, progs = summary(rom, t, a)
        print('  song %3d  %08X  mask %03X  tracks %2d  len %6d  loop %-6s speed %s' % (
            i, a, mask, n, length, '-' if loop is None else loop, speed))
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv))
