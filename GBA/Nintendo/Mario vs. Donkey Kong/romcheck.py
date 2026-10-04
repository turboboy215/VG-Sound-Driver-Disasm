#!/usr/bin/env python3
"""Compare every section of the linked driver with the ROM.
usage: romcheck.py mvdk_sound.elf "Mario vs. Donkey Kong (E) (M5).gba" """
import sys,subprocess,tempfile,os
elf,rom=sys.argv[1],sys.argv[2]
R=open(rom,'rb').read()
out=subprocess.run(['arm-none-eabi-objdump','-h',elf],capture_output=True,text=True).stdout
ok=True
for line in out.splitlines():
    f=line.split()
    if len(f)>=7 and f[1].startswith('.snd_'):
        name,size,vma=f[1],int(f[2],16),int(f[3],16)
        with tempfile.TemporaryDirectory() as t:
            p=os.path.join(t,'s.bin')
            subprocess.run(['arm-none-eabi-objcopy','-O','binary','--only-section='+name,elf,p],check=True)
            b=open(p,'rb').read()
        ref=R[vma-0x08000000:vma-0x08000000+size]
        bad=[i for i in range(size) if b[i]!=ref[i]]
        print('%-14s %08X-%08X %8d bytes  %s'%(name,vma,vma+size,size,'OK' if not bad else 'MISMATCH at %08X (%d bytes)'%(vma+bad[0],len(bad))))
        ok&=not bad
print('ALL SECTIONS MATCH' if ok else 'DIFFERENCES FOUND'); sys.exit(0 if ok else 1)
