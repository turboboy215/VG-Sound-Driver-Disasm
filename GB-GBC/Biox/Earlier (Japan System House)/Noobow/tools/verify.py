import sys,subprocess,os
RG=''   # folder holding rgbasm/rgblink ('' = on PATH)
def verify(asm, rom, ranges, wd='out'):
    o='/tmp/claude-0/v.o'; g='/tmp/claude-0/v.gb'
    r=subprocess.run([RG+'rgbasm','-o',o,os.path.basename(asm)],cwd=wd,capture_output=True,text=True)
    if r.returncode: print(r.stderr[:3000]); return False
    r=subprocess.run([RG+'rgblink','-p','0xFF','-o',g,o],capture_output=True,text=True)
    if r.returncode: print(r.stderr[:3000]); return False
    a=open(g,'rb').read(); b=open(rom,'rb').read()
    tot=0; bad=0
    for bank,s,e in ranges:
        off=bank*0x4000-0x4000 if bank else 0
        for x in range(s,e):
            tot+=1
            if a[off+x]!=b[off+x]:
                if bad<10: print('mismatch %02X:%04X built %02X rom %02X'%(bank,x,a[off+x],b[off+x]))
                bad+=1
    print('%s: %d bytes checked, %d mismatches'%(asm,tot,bad)); return bad==0
if __name__=='__main__':
    import ast
    verify(sys.argv[1],sys.argv[2],ast.literal_eval(sys.argv[3]))
