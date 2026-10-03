#!/bin/sh
# Rebuild the DuckTales sound code/data and compare with the ROM (needs "../Duck Tales (E) [!].gb").
set -e
rgbasm -Wall -o dt.o DuckTales_SoundDriver.asm
rgblink -p 0xFF -o dt_snd.gb dt.o
python3 ../tools/cmp.py "../Duck Tales (E) [!].gb" dt_snd.gb 0:0183-0194 0:0212-0220 0:0725-0743 2:4026-60F8 2:615F-6197
