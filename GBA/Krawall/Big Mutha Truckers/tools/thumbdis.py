import capstone,struct,sys
r=open(sys.argv[1],'rb').read()
md=capstone.Cs(capstone.CS_ARCH_ARM,capstone.CS_MODE_THUMB)
a=int(sys.argv[2],16)&0x1ffffff; n=int(sys.argv[3],16)
for i in md.disasm(r[a:a+n],0x08000000+a):
    extra=''
    if i.mnemonic.startswith('ldr') and 'pc' in i.op_str and '#' in i.op_str:
        try:
            off=int(i.op_str.split('#')[1].rstrip(']'),16)
            la=((i.address+4)&~3)+off
            extra=' ; =0x%08x'%struct.unpack_from('<I',r,la-0x08000000)[0]
        except Exception: pass
    print('%08x: %-8s %s%s'%(i.address,i.mnemonic,i.op_str,extra))
