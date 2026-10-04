#!/usr/bin/env python3
"""Compare the linked sections with the ROM: romcheck.py ROM ww_sound.elf"""
import sys, subprocess, os
RANGES = [('.snd_code',   0x080F05B4, 0x080F4988, 'driver code (Thumb + ARM)'),
          ('.snd_rodata', 0x083FD1CC, 0x083FD770, 'driver tables'),
          ('.snd_data',   0x083FD770, 0x0841BE80, 'keymaps, waves, instruments, banks, songs, players, sample headers'),
          ('.snd_midi',   0x0841BE80, 0x0854FC14, 'MIDI files'),
          ('.snd_pcm',    0x08155D74, 0x08316338, 'sample PCM')]
rom = open(sys.argv[1], 'rb').read()
elf = sys.argv[2]
objcopy = os.environ.get('OBJCOPY', 'arm-none-eabi-objcopy')
bad = 0
for sec, lo, hi, what in RANGES:
    out = 'check%s.bin' % sec
    subprocess.check_call([objcopy, '-O', 'binary', '-j', sec, elf, out])
    b = open(out, 'rb').read(); os.remove(out)
    r = rom[lo - 0x08000000:hi - 0x08000000]
    if b == r:
        print('%-12s %08X-%08X %8d bytes  identical   %s' % (sec, lo, hi, len(b), what))
    else:
        bad += 1
        n = next((i for i in range(min(len(b), len(r))) if b[i] != r[i]), min(len(b), len(r)))
        print('%-12s %08X-%08X  DIFFERS (built %d bytes, ROM %d; first difference at %08X)' % (sec, lo, hi, len(b), len(r), lo + n))
sys.exit(1 if bad else 0)
