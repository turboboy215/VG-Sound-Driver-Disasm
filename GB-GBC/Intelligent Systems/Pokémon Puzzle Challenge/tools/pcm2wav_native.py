"""Convert the 2-bit PCM samples to WAV at their native rate, without resampling.

usage: python3 tools/pcm2wav_native.py <pcm dir>

Pcm_Play's loop is built from steps of ~31 M-cycles (DMG): a sample with hold n lasts
(1 + n) steps (measured 31/32, 60/61, 91/92, 122/123 cycles). So each byte expands to
exact sample counts at 1,048,576 / 31 = 33,825 Hz:
    first sample : level bits 5-4, repeated 1 + bits 7-6 times
    second sample: level bits 1-0, repeated 1 + bits 3-2 times
Levels are the raw ch3 output (NR32 code with an all-$F wave): mute 0, 25 % 3, 50 % 7,
100 % 15, written as 8-bit unsigned (x17), DC offset kept as on the hardware's DAC input.
"""
import os
import sys
import wave

RATE = 1048576 // 31          # 33825 Hz
LEVEL = {0: 0, 1: 15, 2: 7, 3: 3}


def expand(data):
    out = bytearray()
    for b in data:
        out += bytes([LEVEL[(b >> 4) & 3] * 17]) * (1 + (b >> 6))
        out += bytes([LEVEL[b & 3] * 17]) * (1 + ((b >> 2) & 3))
    return bytes(out)


if __name__ == '__main__':
    d = sys.argv[1]
    for k in range(4):
        data = open(os.path.join(d, f'PcmSample{k}.bin'), 'rb').read()
        pcm = expand(data)
        fn = os.path.join(d, f'PcmSample{k}_native.wav')
        w = wave.open(fn, 'wb')
        w.setnchannels(1)
        w.setsampwidth(1)
        w.setframerate(RATE)
        w.writeframes(pcm)
        w.close()
        print(f'{fn}: {len(pcm)} samples, {len(pcm) / RATE:.3f} s at {RATE} Hz')
