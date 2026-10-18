"""Export Paperboy (GBC) samples to WAV.
usage: python3 pbsamples.py <rom> <outdir>
  sample_XX_raw3121.wav : every nibble of the table range, 8-bit, at the data rate (32 x 97.52 Hz = 3120.8 Hz)
  sample_XX_ingame.wav  : 44.1 kHz render of what the driver actually outputs:
                          block 0 skipped, one block per timer tick (10.254 ms), CH3 retriggered each tick
                          at period $5CB (3711.8 Hz), so each block plays nibbles 1..31,0 then wraps for ~6 more.
"""
import sys, os, wave, struct
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
if len(sys.argv) > 1: os.environ['PB_ROM'] = sys.argv[1]
from pbparse import ROM, off, samples

TICK_HZ = 8192 / 84                 # timer IRQ rate in CGB double speed
CH3_HZ = 2097152 / (2048 - 0x5CB)   # CH3 sample clock
OUT_HZ = 44100

def nibbles(data):
    for b in data:
        yield b >> 4; yield b & 15

def write_wav(path, rate, vals):
    with wave.open(path, 'wb') as f:
        f.setnchannels(1); f.setsampwidth(1); f.setframerate(int(round(rate)))
        f.writeframes(bytes(vals))

def to_u8(n): return max(0, min(255, int(round((n - 7.5) * 16 + 128))))

def render_ingame(s):
    data = ROM[off(s['bank'], s['start']):off(s['bank'], s['end'] + 16)]  # driver may read up to 15 bytes past end
    blocks = [data[16 * k:16 * k + 16] for k in range(1, 9999) if s['start'] + 16 * k < s['end']]
    out = []; t_out = 0.0; dt = 1 / OUT_HZ; buf = 7.5; t = 0.0
    for blk in blocks:
        nib = list(nibbles(blk))
        t_end = t + 1 / TICK_HZ
        # first period outputs the stale buffer, then positions 1,2,...,31,0,1,...
        while t_out < t_end:
            k = int((t_out - t) * CH3_HZ)            # periods elapsed since trigger
            v = buf if k == 0 else nib[k % 32]
            out.append(to_u8(v)); t_out += dt
        k_last = int((t_end - t) * CH3_HZ)
        buf = nib[k_last % 32] if k_last else buf
        t = t_end
    return out

def main():
    rom, outdir = sys.argv[1], sys.argv[2]
    os.makedirs(outdir, exist_ok=True)
    rows = []
    for i, s in enumerate(samples()):
        raw = ROM[off(s['bank'], s['start']):off(s['bank'], s['end'])]
        write_wav(os.path.join(outdir, f'sample_{i:02d}_raw3121.wav'), 32 * TICK_HZ, [to_u8(n) for n in nibbles(raw)])
        write_wav(os.path.join(outdir, f'sample_{i:02d}_ingame.wav'), OUT_HZ, render_ingame(s))
        nb = len([k for k in range(1, 9999) if s['start'] + 16 * k < s['end']])
        rows.append((i, s['prio'], s['bank'], s['start'], s['end'], len(raw), nb, nb / TICK_HZ))
    for r in rows:
        print('%2d prio %d bank $%02X $%04X-$%04X %5d bytes %3d blocks %.3f s' % r)

if __name__ == '__main__':
    main()
