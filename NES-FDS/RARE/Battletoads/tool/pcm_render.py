#!/usr/bin/env python3
"""Run the Rare PCM generators in a 6502 emulator and save what they write to
$4011 as WAV files (plus a CSV of timing statistics).

usage: pcm_render.py <bt|dd> <rom.nes> <outdir>
"""
import sys, os, wave, struct
from py65.devices.mpu6502 import MPU

CPU_HZ = 1789773.0
OUT_HZ = 44100

GAMES = {
    # play entry, exit routine, zero-page: request, delay, fliprate, seglimit, rng0-3
    'bt': dict(play=0x852B, setvol=0x854E, exit=0x868F, req=0x40, delay=0x3F, flip=0x42, lim=0x4F,
               rng=(0x25, 0x26, 0x27, 0x28), split=None),
    'dd': dict(play=0x895E, setvol=0x8981, exit=0x8ADC, req=0x46, delay=0x45, flip=0x48, lim=0x55,
               rng=(0x2C, 0x2D, 0x2E, 0x2F), split=0x59),
}

# (name, generator id, rate, fliprate, seglimit, volume) - parameters taken from the songs
PRESETS = [
    ('tone_rate11_flip1E', 1, 0x11, 0x1E, 0x14, 3),
    ('tone_rate16_flip00', 1, 0x16, 0x00, 0x00, 3),
    ('tone_rate02_flip00', 1, 0x02, 0x00, 0x00, 3),
    ('noise_rate05', 2, 0x05, 0x00, 0x00, 3),
    ('waveA_rate03', 3, 0x03, 0x00, 0x00, 3),
    ('waveB_rate08', 4, 0x08, 0x00, 0x00, 3),
    ('waveB_rate0E', 4, 0x0E, 0x00, 0x00, 3),
    ('waveB_rate11', 4, 0x11, 0x00, 0x00, 3),
    ('waveB_rate15', 4, 0x15, 0x00, 0x00, 3),
    ('waveC_rate0B', 5, 0x0B, 0x00, 0x00, 3),
    # in-game PCM effects (Battletoads bank-0 sound rows: request, rate, flip rate, limit)
    ('game_tone_r01_f60_l1C', 1, 0x01, 0x60, 0x1C, 3),
    ('game_tone_r01_f70_l28', 1, 0x01, 0x70, 0x28, 3),
    ('game_tone_r01_fC0_l15', 1, 0x01, 0xC0, 0x15, 3),
    ('game_tone_r01_f00_l38', 1, 0x01, 0x00, 0x38, 3),
    ('game_noise_r01_l08', 2, 0x01, 0x00, 0x08, 3),
    ('game_noise_r01_l10', 2, 0x01, 0x00, 0x10, 3),
    ('game_waveA_r01_l4C', 3, 0x01, 0x00, 0x4C, 3),
    ('game_waveB_r01_l1C', 4, 0x01, 0x00, 0x1C, 3),
]

class Mem(bytearray):
    pass

def render(game, rom, gen, rate, flip, lim, vol):
    g = GAMES[game]
    mem = bytearray(0x10000)
    mem[0x8000:0x10000] = rom[16 + 3 * 0x8000:16 + 4 * 0x8000]
    log = []
    class M(list):
        pass
    cpu = MPU()
    cpu.memory = mem
    # trap $4011 writes by polling the byte after each step
    mem[g['req']] = 0x80 | gen
    mem[g['delay']] = rate
    mem[g['flip']] = flip
    mem[g['lim']] = lim
    for i, a in enumerate(g['rng']): mem[a] = (0x5A, 0x3C, 0x91, 0x07)[i]
    if g['split'] is not None: mem[g['split']] = 0xFF
    # call SetVolume(vol) first: push a return address to a BRK-free stop
    def call(pc, a=0, stop=None):
        cpu.a = a; cpu.pc = pc; cpu.sp = 0xFF
        mem[0x01FF] = 0xFF; mem[0x01FE] = 0xFE   # return -> $FFFF (sentinel)
        cpu.sp = 0xFD
        steps = 0
        while True:
            if cpu.pc == 0xFFFF or cpu.pc == stop: return
            before = mem[0x4011]
            mem[0x4011] = 0xEE  # marker
            cyc0 = cpu.processorCycles
            cpu.step()
            if mem[0x4011] != 0xEE:
                log.append((cpu.processorCycles, mem[0x4011]))
            else:
                mem[0x4011] = before
            steps += 1
            if steps > 5_000_000: raise Exception('runaway')
    call(g['setvol'], vol)
    log.clear()
    cpu.processorCycles = 0
    call(g['play'], 0, stop=g['exit'])
    return log

def to_wav(log, path):
    if not log: return 0
    end = log[-1][0] + 2000
    n = int(end / CPU_HZ * OUT_HZ) + 1
    out = []
    j = 0
    cur = 0x40
    for i in range(n):
        t = i / OUT_HZ * CPU_HZ
        while j < len(log) and log[j][0] <= t:
            cur = log[j][1] & 0x7F
            j += 1
        out.append(int((cur - 64) * 400))
    with wave.open(path, 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(OUT_HZ)
        w.writeframes(b''.join(struct.pack('<h', max(-32768, min(32767, v))) for v in out))
    return n

def main():
    game, romfile, outdir = sys.argv[1:4]
    rom = open(romfile, 'rb').read()
    os.makedirs(outdir, exist_ok=True)
    rows = ['name,generator,rate,fliprate,seglimit,samples,duration_ms,avg_sample_rate_hz']
    for name, gen, rate, flip, lim, vol in PRESETS:
        log = render(game, rom, gen, rate, flip, lim, vol)
        to_wav(log, os.path.join(outdir, '%s_%s.wav' % (game, name)))
        dur = (log[-1][0] - log[0][0]) / CPU_HZ if len(log) > 1 else 0
        sr = (len(log) - 1) / dur if dur else 0
        rows.append('%s,%d,$%02X,$%02X,$%02X,%d,%.1f,%.0f' % (name, gen, rate, flip, lim, len(log), dur * 1000, sr))
        print(rows[-1])
    open(os.path.join(outdir, '%s_pcm_stats.csv' % game), 'w').write('\n'.join(rows) + '\n')

if __name__ == '__main__':
    main()
