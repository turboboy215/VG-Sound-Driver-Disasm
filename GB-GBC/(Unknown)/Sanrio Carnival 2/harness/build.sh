#!/bin/sh
set -e
cd "$(dirname "$0")"
ROM=${1:-"../../Sanrio Carnival 2 (J).gb"}
cp "$ROM" orig.gb
rgbasm -I ../../common -o harness.o harness.asm
(cd .. && rgbasm -I ../common -o harness/s2.o S2_Sound.asm)
rgblink -o harness.gb harness.o s2.o
rgbfix -v -p 0 harness.gb
rm -f orig.gb
