import sys
sys.path.insert(0,'tools')
from sm83 import decode
d = None
def dis(bank,a,b):
    global d
    off=(bank*0x4000 if a>=0x4000 else 0)+ (a-0x4000 if a>=0x4000 else a)
    pc=a
    while pc<b:
        n,s,_=decode(d,off,pc)
        print(f'{bank:02X}:{pc:04X}  {d[off:off+n].hex():8} {s}')
        off+=n;pc+=n
if __name__=='__main__':
    # usage: python listing.py <rom> <bank hex> <start hex> <end hex>
    d = open(sys.argv[1], 'rb').read()
    dis(int(sys.argv[2],16),int(sys.argv[3],16),int(sys.argv[4],16))
