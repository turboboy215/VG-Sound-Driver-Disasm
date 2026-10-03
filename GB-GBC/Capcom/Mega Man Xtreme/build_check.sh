#!/bin/sh
# Rebuild the sound banks and ROM0 glue of Mega Man Xtreme and compare with the ROM.
set -e
for f in MMX_SoundBank2 MMX_SoundBank3 MMX_SoundBank4 MMX_SoundGlue; do
  rgbasm -Wall -o $f.o $f.asm
done
rgblink -p 0x00 -o mmx_snd.gbc MMX_SoundBank2.o MMX_SoundBank3.o MMX_SoundBank4.o MMX_SoundGlue.o
python3 ../tools/cmp.py "../Megaman Xtreme (U) [C][!].gbc" mmx_snd.gbc 2:4000-7D3E 3:4000-7BE3 4:4000-7886 0:0B39-0B44 0:2A14-2A41
