#!/bin/sh
# Build the test ROM from the rebuilt sound sections. usage: sh harness/build.sh [rgbds dir]
set -e
RGB="${1:-}"; [ -n "$RGB" ] && RGB="$RGB/"
cd "$(dirname "$0")/.."
mkdir -p build
for f in PPC_Home PPC_Bank20 PPC_Bank21 PPC_Bank7F PPC_Bank22 PPC_Bank23 PPC_Bank24 PPC_Bank25 PPC_Bank26 PPC_Bank7C PPC_Bank7D PPC_Bank7E; do
  ${RGB}rgbasm -Wall -o build/$f.o $f.asm
done
${RGB}rgbasm -Wall -I . -o build/harness.o harness/harness.asm
${RGB}rgblink -p 0xFF -n build/harness.sym -o build/harness.gbc build/harness.o build/PPC_*.o
${RGB}rgbfix -C -m 0x1B -r 0x03 -t PPCHARNESS -p 0xFF -v build/harness.gbc
echo "built build/harness.gbc"
