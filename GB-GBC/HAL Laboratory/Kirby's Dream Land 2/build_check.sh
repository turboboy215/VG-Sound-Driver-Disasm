#!/bin/sh
# Assemble the sound driver, link it over the original ROM, and compare.
# usage: sh build_check.sh <original rom>      (rgbasm/rgblink on PATH, or RGBDS=<dir>)
ROM="$1"
RGB="${RGBDS:+$RGBDS/}"
set -e
cd "$(dirname "$0")"
${RGB}rgbasm -Wall -o KDL2_Sound.o KDL2_Sound.asm
${RGB}rgblink -O "$ROM" -o KDL2_rebuilt.gb KDL2_Sound.o
if cmp -s "$ROM" KDL2_rebuilt.gb; then echo "OK: KDL2 byte-exact"; else echo "MISMATCH"; cmp -l "$ROM" KDL2_rebuilt.gb | head; exit 1; fi
