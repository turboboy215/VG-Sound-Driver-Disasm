#!/bin/sh
# Assemble DrM_Sound.asm, link it over the original ROM and compare.
ROM=${1:-"../Dr. Mario (W) (V1.0) [!].gb"}
set -e
rgbasm -Wall -I ../common -o drm.o DrM_Sound.asm
rgblink -O "$ROM" -o drm_rebuilt.gb drm.o
cmp "$ROM" drm_rebuilt.gb && echo "OK: byte-exact"
