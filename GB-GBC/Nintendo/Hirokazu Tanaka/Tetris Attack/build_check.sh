#!/bin/sh
# Assemble the home routine and banks $07/$08, link them over the original ROM and compare.
ROM=${1:-"../Tetris Attack (U) (V1.1) [S].gb"}
set -e
rgbasm -Wall -I ../common -o ta_home.o TA_Home.asm
rgbasm -Wall -I ../common -o ta_07.o TA_Bank07.asm
rgbasm -Wall -I ../common -o ta_08.o TA_Bank08.asm
rgblink -O "$ROM" -o ta_rebuilt.gb ta_home.o ta_07.o ta_08.o
cmp "$ROM" ta_rebuilt.gb && echo "OK: byte-exact"
