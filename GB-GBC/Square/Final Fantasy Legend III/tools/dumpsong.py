import sys; sys.path.insert(0,'tools')
from ffl3parse import *
def dump(n,ends=None):
    s=songs()[n-1]
    for ch in range(4):
        print('=== song %d %s @%04X'%(n,CHN[ch],s[ch]))
        out,a=disasm_linear(s[ch],ch,end=(ends[ch] if ends else None),stop_at_end=ends is None)
        line=[]; la=None
        for ad,k,bs,d in out:
            if k=='note':
                if not line: la=ad
                line.append('%s%d'%(NOTE[bs[0]>>4].replace('rest','r').replace('tie','~'),LEN[bs[0]&15])); continue
            if line: print('%04X    '%la,' '.join(line)); line=[]
            print('%04X %-8s %s'%(ad,k,d))
        if line: print('%04X    '%la,' '.join(line))
if __name__=='__main__':
    n=int(sys.argv[1]); ends=[int(x,16) for x in sys.argv[2:]] or None
    dump(n,ends)
