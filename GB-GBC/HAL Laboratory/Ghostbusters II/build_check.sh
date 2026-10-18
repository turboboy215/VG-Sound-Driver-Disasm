#!/bin/sh
# Assemble the sound driver, link it over the original ROM, and compare.
# usage: sh build_check.sh <original rom>      (rgbasm/rgblink on PATH, or RGBDS=<dir>)
ROM="$1"
RGB="${RGBDS:+$RGBDS/}"
set -e
cd "$(dirname "$0")"
${RGB}rgbasm -Wall -o GB2_Sound.o GB2_Sound.asm
${RGB}rgblink -O "$ROM" -o GB2_rebuilt.gb GB2_Sound.o
if cmp -s "$ROM" GB2_rebuilt.gb; then echo "OK: GB2 byte-exact"; else echo "MISMATCH"; cmp -l "$ROM" GB2_rebuilt.gb | head; exit 1; fi
