#!/bin/sh
# Assemble the sound driver, link it over the original ROM, and compare.
# usage: sh build_check.sh <original rom>      (rgbasm/rgblink on PATH, or RGBDS=<dir>)
ROM="$1"
RGB="${RGBDS:+$RGBDS/}"
set -e
cd "$(dirname "$0")"
${RGB}rgbasm -Wall -o KDL_Sound.o KDL_Sound.asm
${RGB}rgblink -O "$ROM" -o KDL_rebuilt.gb KDL_Sound.o
if cmp -s "$ROM" KDL_rebuilt.gb; then echo "OK: KDL byte-exact"; else echo "MISMATCH"; cmp -l "$ROM" KDL_rebuilt.gb | head; exit 1; fi
