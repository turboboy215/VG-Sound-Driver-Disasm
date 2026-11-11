#!/usr/bin/env python3
"""rare_gba_midi.py - extract songs from Rare's GBA sound driver (Donkey Kong Country 1/2/3 GBA)
to Standard MIDI Files.

Usage:  rare_gba_midi.py ROM.gba OUTDIR [--song N] [--list]

The driver plays a pre-compiled MIDI stream, so conversion is lossless at the event level:
every note, controller, program change, pitch bend and tempo change maps 1:1 to SMF.
Driver-specific controllers are kept as-is and also annotated with marker meta events:
  CC102 = loop start, CC103 = loop end (per track, infinite), CC104 = start marker (DKC3),
  CC20-23 = per-channel ADSR override (DKC3), CC126/127 = mono/poly.
Program numbers are the raw MIDI programs used by the song; they index the game's own
instrument set (see the data dump), not General MIDI.
"""
import struct, sys, os, argparse

KNOWN = {  # game code -> (song table, sfx table)
    b'A5NP': (0x08562668, 0x08562294),   # Donkey Kong Country (E)
    b'B2DP': (0x0854B5B0, 0x0854B0B0),   # Donkey Kong Country 2 (E)
    b'BDQP': (0x0871F970, 0x0871F644),   # Donkey Kong Country 3 (E)
}

class Rom:
    def __init__(self, path):
        self.d = open(path, 'rb').read()
        self.code = self.d[0xAC:0xB0]
    def u8(self, a): return self.d[a - 0x08000000]
    def u32(self, a): return struct.unpack_from('<I', self.d, a - 0x08000000)[0]

def find_song_table(rom):
    """Song table address for the three known releases (from snd_init's literal pool)."""
    if rom.code in KNOWN: return KNOWN[rom.code][0]
    raise SystemExit('unknown ROM %r - add its song table address to KNOWN' % rom.code)

def song_list(rom, tab):
    out = []
    while True:
        p = rom.u32(tab + 4 * len(out))
        if not (0x08000000 <= p < 0x0A000000): break
        nt, div = rom.u32(p), rom.u32(p + 4)
        if not (1 <= nt <= 16 and 24 <= div <= 1920): break
        out.append(p)
    return out

LEN = {0: 4, 1: 2, 2: 3, 3: 4, 4: 3, 5: 3, 6: 3, 7: 3, 8: 2, 9: 2, 10: 3, 11: 1, 12: 1}

def parse_track(rom, p):
    """Yield (abs_tick, kind, chan, data). Stops at END (cmd 11)."""
    t = 0
    while True:
        b = rom.u8(p); cmd, ch = b & 15, b >> 4
        if cmd not in LEN: raise ValueError('bad command %02X at %08X' % (b, p))
        a = [rom.u8(p + 1 + k) for k in range(LEN[cmd] - 1)]
        p += LEN[cmd]
        if cmd == 0:   yield t, 'tempo', ch, a[0] | a[1] << 8 | a[2] << 16
        elif cmd in (1, 2, 3):
            t += sum(v << (8 * k) for k, v in enumerate(a))
        elif cmd in (4, 5): yield t, 'on', ch, (a[0], a[1])
        elif cmd == 6:  yield t, 'off', ch, (a[0], a[1])
        elif cmd == 7:  yield t, 'cc', ch, (a[0], a[1])
        elif cmd == 8:  yield t, 'prog', ch, a[0]
        elif cmd == 9:  yield t, 'pressure', ch, a[0]
        elif cmd == 10: yield t, 'bend', ch, a[0] | a[1] << 8
        elif cmd == 11: yield t, 'end', ch, None; return

def vlq(n):
    out = [n & 0x7F]; n >>= 7
    while n: out.append(0x80 | (n & 0x7F)); n >>= 7
    return bytes(reversed(out))

def meta(t, txt): return (t, b'\xFF\x06' + vlq(len(txt)) + txt.encode())

def track_to_mtrk(events):
    ev = []
    for t, k, ch, v in events:
        if k == 'tempo': ev.append((t, b'\xFF\x51\x03' + v.to_bytes(3, 'big')))
        elif k == 'on':  ev.append((t, bytes([0x90 | ch, v[0] & 0x7F, v[1] & 0x7F])))
        elif k == 'off': ev.append((t, bytes([0x80 | ch, v[0] & 0x7F, v[1] & 0x7F])))
        elif k == 'cc':
            ev.append((t, bytes([0xB0 | ch, v[0] & 0x7F, v[1] & 0x7F])))
            if v[0] == 102: ev.append(meta(t, 'loopStart'))
            if v[0] == 103: ev.append(meta(t, 'loopEnd'))
            if v[0] == 104: ev.append(meta(t, 'startMarker %d' % v[1]))
        elif k == 'prog': ev.append((t, bytes([0xC0 | ch, v & 0x7F])))
        elif k == 'pressure': ev.append((t, bytes([0xD0 | ch, v & 0x7F])))
        elif k == 'bend': ev.append((t, bytes([0xE0 | ch, v & 0x7F, (v >> 7) & 0x7F])))
        elif k == 'end': last = t
    body = b''; now = 0
    for t, data in ev:  # already in time order
        body += vlq(t - now) + data; now = t
    body += vlq(max(0, last - now)) + b'\xFF\x2F\x00'
    return b'MTrk' + struct.pack('>I', len(body)) + body

def convert(rom, hdr):
    nt, div, tp = rom.u32(hdr), rom.u32(hdr + 4), rom.u32(hdr + 8)
    tracks = [list(parse_track(rom, rom.u32(tp + 4 * k))) for k in range(nt)]
    smf = b'MThd' + struct.pack('>IHHH', 6, 1, nt, div)
    return smf + b''.join(track_to_mtrk(t) for t in tracks), tracks, div

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('rom'); ap.add_argument('outdir', nargs='?')
    ap.add_argument('--song', type=int); ap.add_argument('--list', action='store_true')
    a = ap.parse_args()
    rom = Rom(a.rom); tab = find_song_table(rom); songs = song_list(rom, tab)
    stem = os.path.splitext(os.path.basename(a.rom))[0]
    for i, h in enumerate(songs):
        if a.song is not None and i != a.song: continue
        data, tracks, div = convert(rom, h)
        tempo = next((v for t, k, c, v in tracks[0] if k == 'tempo'), 500000)
        ticks = max(t[-1][0] for t in tracks)
        loops = sum(1 for tr in tracks for e in tr if e[1] == 'cc' and e[3][0] == 102)
        if a.list or not a.outdir:
            print('%3d  hdr %08X  tracks %2d  div %4d  %6.1f BPM  %7.1f s  loop:%s' % (
                i, h, len(tracks), div, 60e6 / tempo, ticks / div * tempo / 1e6, 'yes' if loops else 'no'))
        if a.outdir:
            os.makedirs(a.outdir, exist_ok=True)
            open(os.path.join(a.outdir, '%s_song%02d.mid' % (stem, i)), 'wb').write(data)

if __name__ == '__main__':
    main()
