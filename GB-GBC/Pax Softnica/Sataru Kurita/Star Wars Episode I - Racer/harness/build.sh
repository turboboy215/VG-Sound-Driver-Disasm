#!/bin/sh
# usage: harness/build.sh [original ROM]   (run ./build_check.sh first)
# The ROM is needed because the harness copies the home-bank routines the
# driver calls (far call/return, bank switching, rumble, distance) from it.
set -e
ROM="$(realpath "${1:-$(dirname "$0")/../../Star Wars Episode I - Racer (UE) [C][!].gbc}")"
cd "$(dirname "$0")"
cp "$ROM" rom.gbc
rgbasm -o harness.o harness.asm
rgblink -p 0xFF -o harness.gbc harness.o ../build/SWR_Bank03.o ../build/SWR_Voice.o
rgbfix -v -C -m 0x19 -p 0xFF -t SWRHARNESS harness.gbc
rm rom.gbc
