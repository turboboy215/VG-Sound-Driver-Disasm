#!/bin/sh
# Build the test ROM from the rebuilt sources (run from this folder).
set -e
cd "$(dirname "$0")"
mkdir -p obj
for f in TT_Home TT_Driver TT_Music_2E TT_Music_2F TT_Music_30 TT_Music_31 TT_Music_32 TT_Music_33; do
    rgbasm -Wall -I .. -o obj/$f.o ../$f.asm
done
rgbasm -Wall -I .. -o obj/harness.o harness.asm
rgblink -p 0xFF -o harness.gbc obj/harness.o obj/TT_*.o
rgbfix -C -m 0x1B -p 0xFF -v -t TTHARNESS harness.gbc
echo built harness.gbc
