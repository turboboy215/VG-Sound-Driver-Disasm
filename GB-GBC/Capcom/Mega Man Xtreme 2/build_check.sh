#!/bin/sh
# Rebuild Mega Man Xtreme 2's sound banks + glue. The driver source and MMX_Sound.inc
# come from ../MegaManXtreme (same engine).
set -e
for f in MMX2_SoundBank2 MMX2_SoundBank3 MMX2_SoundGlue; do
  rgbasm -Wall -I ../MegaManXtreme -o $f.o $f.asm
done
rgblink -p 0x00 -o mmx2_snd.gbc MMX2_SoundBank2.o MMX2_SoundBank3.o MMX2_SoundGlue.o
python3 ../tools/cmp.py "../Megaman Xtreme 2 (U) [C][!].gbc" mmx2_snd.gbc 2:4000-7EF7 3:4000-7E08 0:01D5-01E7 0:0A10-0AB0
