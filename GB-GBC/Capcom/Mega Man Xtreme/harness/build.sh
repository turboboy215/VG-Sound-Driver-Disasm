#!/bin/sh
set -e
cd "$(dirname "$0")/.."
for f in MMX_SoundBank2 MMX_SoundBank3 MMX_SoundBank4; do rgbasm -Wall -o $f.o $f.asm; done
rgbasm -Wall -o harness/harness.o harness/harness.asm
rgblink -p 0x00 -o harness/mmx_harness.gbc MMX_SoundBank2.o MMX_SoundBank3.o MMX_SoundBank4.o harness/harness.o
rgbfix -C -v -m 0x19 -p 0x00 harness/mmx_harness.gbc
