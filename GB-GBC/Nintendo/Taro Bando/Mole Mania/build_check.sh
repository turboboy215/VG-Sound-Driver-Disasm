#!/bin/sh
# Assemble the three sound banks, link them over the original ROM and compare.
# usage: ./build_check.sh [path/to/Mole Mania (U) [S][!].gb]
set -e
ROM="${1:-../Mole Mania (U) [S][!].gb}"
mkdir -p build
for b in 07 0B 1A; do
  rgbasm -Wall -o build/MM_Bank$b.o MM_Bank$b.asm
done
rgblink -O "$ROM" -o build/mm_rebuilt.gb -n build/mm_rebuilt.sym build/MM_Bank07.o build/MM_Bank0B.o build/MM_Bank1A.o
if cmp -s "$ROM" build/mm_rebuilt.gb; then echo "OK: rebuilt ROM is identical"; else echo "MISMATCH"; cmp -l "$ROM" build/mm_rebuilt.gb | head -20; exit 1; fi
