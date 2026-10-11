"""Render the 2-bit PCM samples to WAV by modelling Pcm_Play ($1A25) cycle by cycle.

usage: python3 tools/pcm2wav.py <pcm dir> [--cgb]

Pcm_Play writes only NR32 (ch3 output level) while ch3 plays an all-$F wave, so the output is a DC
level: mute / 25 % / 50 % / 100 % of 15. Each byte = two samples (bits 5-4 level, 7-6 extra hold;
bits 1-0 level, 3-2 extra hold). Timing comes from the instruction cycle counts of the loop:
DMG: 1,048,576 M-cycles/s, Pcm_Delay = 22 cycles incl. the call, the 'call z' checks not taken.
--cgb: double speed (2,097,152 M-cycles/s), hConsoleType = $11, so every 'call z, Pcm_Delay' is
taken; Pcm_Delay = 24 cycles + call (assumes d != 0; d is left over from the caller).
"""
import os
import struct
import sys
import wave

LEVEL = {0: 0, 1: 15, 2: 7, 3: 3}   # NR32 code -> DAC input with an all-$F wave


def events(data, cgb):
    U = 6 + (24 if cgb else 16)          # call Pcm_Delay
    CZ = U if cgb else 3                 # 'call z, Pcm_Delay': taken only on CGB
    t = 0
    out = []

    def hold(n):
        # jr z,skip (3) if n == 0; else jr not taken (2) + n x [inc e, dec e, call z, call, dec a, jr nz]
        if n == 0:
            return 3
        return 2 + n * (2 + CZ + U + 1 + 3) - 1

    for i, b in enumerate(data):
        t += 2 + CZ + 6 + 3              # inc e/dec e, call z, ld/and/sla, ldh [NR32]
        out.append((t, (b >> 4) & 3))
        t += 12 + hold(b >> 6)
        t += 2 + CZ + 8 + 3              # inc e/dec e, call z, ld/and/sla/swap, ldh [NR32]
        out.append((t, b & 3))
        t += 8 + hold((b >> 2) & 3)
        t += 4 + (3 if i < len(data) - 1 else 2)   # dec bc, ld a,c, or b, jr nz
    return out, t


def render(data, cgb, rate=44100):
    clock = 2097152 if cgb else 1048576
    ev, total = events(data, cgb)
    n = int(total * rate / clock) + 1
    acc = [0.0] * n
    # box-filter the level steps into output samples
    lvl = 15
    prev = 0
    for t, code in ev + [(total, None)]:
        a, b = prev * rate / clock, t * rate / clock
        i = int(a)
        while a < b:
            e = min(b, i + 1)
            acc[i] += (e - a) * lvl
            a = e
            i += 1
        prev = t
        if code is not None:
            lvl = LEVEL[code]
    # DC-blocking high-pass (like the console's output capacitor), then scale
    y = []
    x1 = y1 = 0.0
    R = 0.999
    for x in acc:
        v = x - x1 + R * y1
        x1, y1 = x, v
        y.append(v)
    peak = max(1e-9, max(abs(v) for v in y))
    pcm = b''.join(struct.pack('<h', int(v / peak * 30000)) for v in y)
    return pcm, total / clock, len(ev) * clock / total


if __name__ == '__main__':
    d = sys.argv[1]
    cgb = '--cgb' in sys.argv
    for k in range(4):
        data = open(os.path.join(d, f'PcmSample{k}.bin'), 'rb').read()
        pcm, secs, sr = render(data, cgb)
        fn = os.path.join(d, f'PcmSample{k}{"_cgb" if cgb else ""}.wav')
        w = wave.open(fn, 'wb')
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(44100)
        w.writeframes(pcm)
        w.close()
        print(f'{fn}: {secs:.3f} s, average {sr:.0f} samples/s')
