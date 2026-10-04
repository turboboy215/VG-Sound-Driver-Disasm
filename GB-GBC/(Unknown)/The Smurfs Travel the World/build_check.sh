#!/bin/sh
# assemble and compare with the ROM
set -e
rgbasm -Wall -o snd.o Smurfs2_SoundDriver.asm
rgblink -p 0xFF -o snd.gb snd.o
python3 - "$1" <<'P'
import sys
a=open('snd.gb','rb').read(); b=open(sys.argv[1],'rb').read()
ok=True
for lo,hi in ((0x28FD,0x2981),(0x10000,0x120E6)):
    d=[i for i in range(lo,hi) if a[i]!=b[i]]
    print('%05X-%05X: %d bytes, %d differ'%(lo,hi-1,hi-lo,len(d)))
    ok &= not d
print('BYTE-EXACT' if ok else 'MISMATCH'); sys.exit(0 if ok else 1)
P
