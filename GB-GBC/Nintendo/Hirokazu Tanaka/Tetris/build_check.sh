#!/bin/sh
# Assemble Tet_Sound.asm, link it over the original ROM and compare.
ROM=${1:-"../Tetris (W) (V1.1) [!].gb"}
set -e
rgbasm -Wall -I ../common -o tet.o Tet_Sound.asm
rgblink -O "$ROM" -o tet_rebuilt.gb tet.o
cmp "$ROM" tet_rebuilt.gb && echo "OK: byte-exact"
