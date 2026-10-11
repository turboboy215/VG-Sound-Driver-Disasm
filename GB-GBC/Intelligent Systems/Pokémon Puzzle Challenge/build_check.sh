#!/bin/sh
# Assemble every sound source, link over the original ROM and compare.
# usage: sh build_check.sh <original rom> [rgbds dir]
set -e
ROM="$1"; RGB="${2:-}"
[ -n "$RGB" ] && RGB="$RGB/"
cd "$(dirname "$0")"
mkdir -p build
OBJS=""
for f in PPC_Home PPC_Bank20 PPC_Bank21 PPC_Bank7F PPC_Bank22 PPC_Bank23 PPC_Bank24 PPC_Bank25 PPC_Bank26 PPC_Bank7C PPC_Bank7D PPC_Bank7E; do
  ${RGB}rgbasm -Wall -o build/$f.o $f.asm
  OBJS="$OBJS build/$f.o"
done
${RGB}rgblink -O "$ROM" -n build/ppc.sym -o build/ppc.gbc $OBJS
if cmp -s "$ROM" build/ppc.gbc; then echo "OK: rebuilt ROM is identical"; else echo "MISMATCH"; cmp -l "$ROM" build/ppc.gbc | head; exit 1; fi
