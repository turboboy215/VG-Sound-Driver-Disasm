#!/bin/sh
# Assemble S2_Sound.asm, link it over the original ROM and compare.
ROM=${1:-"../Sanrio Carnival 2 (J).gb"}
set -e
rgbasm -Wall -I ../common -o s2.o S2_Sound.asm
rgblink -O "$ROM" -o s2_rebuilt.gb s2.o
cmp "$ROM" s2_rebuilt.gb && echo "OK: byte-exact"
