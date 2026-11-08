# Assemble each .asm with rgbasm/rgblink (on PATH) and compare the sound regions with the ROMs.
# usage: verify.py <Workboy ROM> <Double Dragon 3 ROM> <Pyramids of Ra ROM>   (run from the folder with the .asm files)
import subprocess, sys
jobs=[('Workboy_sound',sys.argv[1],[(0,0x0B76,0x0B99),(0,0x33B1,0x38CD),(0,0x398E,0x3FAD),(3,0x461E,0x47A2)]),
      ('DoubleDragon3_sound',sys.argv[2],[(0,0x3AD2,0x4000),(7,0x4000,0x5B59)]),
      ('PyramidsOfRa_sound',sys.argv[3],[(2,0x4000,0x8000)])]
for name,rom,regs in jobs:
    subprocess.check_call(['rgbasm','-o',name+'.o',name+'.asm'])
    subprocess.check_call(['rgblink','-p','0xFF','-o',name+'.gb',name+'.o'])
    a=open(name+'.gb','rb').read(); b=open(rom,'rb').read(); tot=bad=0
    for bank,lo,hi in regs:
        for x in range(lo,hi):
            o=x if x<0x4000 else bank*0x4000+x-0x4000
            tot+=1; bad+=a[o]!=b[o]
    print('%-20s %6d bytes checked, %d mismatches'%(name,tot,bad))
