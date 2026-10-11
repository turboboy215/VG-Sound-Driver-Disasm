#!/bin/sh
# Assemble SML_Sound.asm, link it over the original ROM and compare.
ROM=${1:-"../Super Mario Land (W) (V1.0) [!].gb"}
set -e
rgbasm -Wall -I ../common -o sml.o SML_Sound.asm
rgblink -O "$ROM" -o sml_rebuilt.gb sml.o
cmp "$ROM" sml_rebuilt.gb && echo "OK: byte-exact"
