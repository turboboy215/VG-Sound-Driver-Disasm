#!/bin/sh
set -e
cd "$(dirname "$0")/.."
for f in MMX2_SoundBank2 MMX2_SoundBank3; do rgbasm -Wall -I ../MegaManXtreme -o $f.o $f.asm; done
rgbasm -Wall -I ../MegaManXtreme -o harness/harness.o harness/harness.asm
rgblink -p 0x00 -o harness/mmx2_harness.gbc MMX2_SoundBank2.o MMX2_SoundBank3.o harness/harness.o
rgbfix -C -v -m 0x19 -p 0x00 harness/mmx2_harness.gbc
