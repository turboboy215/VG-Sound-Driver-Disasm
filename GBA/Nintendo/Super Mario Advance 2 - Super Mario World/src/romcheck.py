#!/usr/bin/env python3
"""Compare every rebuilt section with the ROMs (make check)."""
import subprocess,json,os,sys
HERE=os.path.dirname(os.path.abspath(__file__))
MB={'sma2_mb':('sma2',0xAD9C8),'sma3_mb':('sma3',0x13F8CC),'sma4_mb':('sma4',0xF9E10)}
def section(elf,name):
    out=elf+'.'+name.strip('.')+'.bin'
    subprocess.run(['arm-none-eabi-objcopy','-O','binary','-j',name,elf,out],check=True)
    addr=int(subprocess.run(['arm-none-eabi-objdump','-h',elf],capture_output=True,text=True).stdout.split(name)[1].split()[2],16)
    return addr,open(out,'rb').read()
sys.path.insert(0,os.path.join(HERE,'..','tools'))
from nsnd_data import find_rom
def rom(game): return open(find_rom(game),'rb').read()
ok=True
for b in ['sma2','sma3','sma4','zelda','sma2_mb','sma3_mb','sma4_mb']:
    game,fo=MB.get(b,(b,None))
    d=rom(game)
    for sec,what in [('.snd_code','driver code'),('.snd_rodata','driver tables')]:
        a,got=section(os.path.join(HERE,b+'.elf'),sec)
        off=a-0x08000000 if fo is None else fo+a-0x02000000
        same=got==d[off:off+len(got)]; ok&=same
        print('%-8s %-12s %08X-%08X %7d bytes  %s  %s'%(b,sec,a,a+len(got),len(got),'identical' if same else 'DIFFERENT',what))
for g in ['sma2','sma3','sma4','zelda']:
    d=rom(g)
    for sec,what in [('.snd_config','SndConfig'),('.snd_data','sound data')]:
        a,got=section(os.path.join(HERE,g+'_data.elf'),sec)
        off=a-0x08000000
        same=got==d[off:off+len(got)]; ok&=same
        print('%-8s %-12s %08X-%08X %7d bytes  %s  %s'%(g,sec,a,a+len(got),len(got),'identical' if same else 'DIFFERENT',what))
sys.exit(0 if ok else 1)
