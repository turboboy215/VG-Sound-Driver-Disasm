#!/bin/sh
# Assemble SML2_Sound.asm, link it over the original ROM and compare.
ROM=${1:-"../Super Mario Land 2 - 6 Golden Coins (UE) (V1.0) [!].gb"}
set -e
rgbasm -Wall -I ../common -o sml2.o SML2_Sound.asm
rgblink -O "$ROM" -o sml2_rebuilt.gb sml2.o
cmp "$ROM" sml2_rebuilt.gb && echo "OK: byte-exact"
