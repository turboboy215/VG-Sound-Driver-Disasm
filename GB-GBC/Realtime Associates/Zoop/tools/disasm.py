"""Plain listing: python disasm.py <rom> <bank hex> <start hex> <end hex>"""
import sys
sys.path.insert(0, __file__.rsplit('/',1)[0])
from sm83 import decode
def run(rom, bank, start, end):
    d=open(rom,'rb').read()
    def mem(a):
        if a<0x4000: return d[a]
        return d[bank*0x4000 + a-0x4000]
    pc=start
    while pc<end:
        ln,txt,k,t=decode(mem,pc)
        print('%02X:%04X  %-12s %s'%(bank,pc,' '.join('%02X'%mem(pc+i) for i in range(ln)),txt))
        pc+=ln
if __name__=='__main__':
    run(sys.argv[1],int(sys.argv[2],16),int(sys.argv[3],16),int(sys.argv[4],16))
