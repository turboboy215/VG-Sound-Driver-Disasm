#!/bin/sh
# Assemble the sound driver, link it over the original ROM, and compare.
# usage: sh build_check.sh <original rom>      (rgbasm/rgblink on PATH, or RGBDS=<dir>)
ROM="$1"
RGB="${RGBDS:+$RGBDS/}"
set -e
cd "$(dirname "$0")"
${RGB}rgbasm -Wall -o Lolo_Sound.o Lolo_Sound.asm
${RGB}rgblink -O "$ROM" -o Lolo_rebuilt.gb Lolo_Sound.o
if cmp -s "$ROM" Lolo_rebuilt.gb; then echo "OK: Lolo byte-exact"; else echo "MISMATCH"; cmp -l "$ROM" Lolo_rebuilt.gb | head; exit 1; fi
