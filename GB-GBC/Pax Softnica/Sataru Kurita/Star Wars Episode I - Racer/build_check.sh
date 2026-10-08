#!/bin/sh
# Assemble the driver bank and the voice section, link over the original ROM, compare.
# usage: ./build_check.sh [path/to/Star Wars Episode I - Racer (UE) [C][!].gbc]
set -e
ROM="${1:-../Star Wars Episode I - Racer (UE) [C][!].gbc}"
mkdir -p build
rgbasm -Wall -o build/SWR_Bank03.o SWR_Bank03.asm
rgbasm -Wall -o build/SWR_Voice.o SWR_Voice.asm
rgblink -O "$ROM" -o build/swr_rebuilt.gbc -n build/swr_rebuilt.sym build/SWR_Bank03.o build/SWR_Voice.o
if cmp -s "$ROM" build/swr_rebuilt.gbc; then echo "OK: rebuilt ROM is identical"; else echo "MISMATCH"; cmp -l "$ROM" build/swr_rebuilt.gbc | head -20; exit 1; fi
