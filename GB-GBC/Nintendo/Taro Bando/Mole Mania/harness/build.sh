#!/bin/sh
set -e
cd "$(dirname "$0")"
rgbasm -o harness.o harness.asm
rgblink -p 0xFF -o harness.gb harness.o ../build/MM_Bank07.o ../build/MM_Bank0B.o ../build/MM_Bank1A.o
rgbfix -v -m 0x01 -r 0 -p 0xFF -t MMHARNESS harness.gb
