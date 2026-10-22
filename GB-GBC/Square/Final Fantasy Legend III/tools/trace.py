import sys; sys.path.insert(0,'tools')
from sm83 import decode
import os
r=open(os.environ.get('FFL3_ROM', 'Final Fantasy Legend III (U) [!].gb'),'rb').read()
BANK=0xF; base=BANK*0x4000
def off(a): return a-0x4000+base if a>=0x4000 else a
def trace(entries, extra_tables=()):
    code={}; todo=list(entries)
    while todo:
        pc=todo.pop()
        while pc not in code and 0x4000<=pc<0x8000:
            l,m,t,k=decode(r,off(pc),pc)
            code[pc]=(l,m,t,k)
            if k in('jmp','cjmp','call') and t is not None and t>=0x4000: todo.append(t)
            if k in('jmp','ret','jphl','bad'): break
            pc+=l
    return code
if __name__=='__main__':
    ents=[int(x,16) for x in sys.argv[1:]] or [0x4000,0x4003]
    code=trace(ents)
    last=None
    for pc in sorted(code):
        l,m,t,k=code[pc]
        if last is not None and pc!=last: print('------ gap %04X-%04X'%(last,pc-1))
        print('%04X %-8s %s'%(pc,r[off(pc):off(pc)+l].hex(),m))
        last=pc+l
