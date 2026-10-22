import sys, os; sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode
r=open(os.environ.get('FFL1_ROM','Final Fantasy Legend, The (U) [!].gb'),'rb').read()
BANK=7; base=BANK*0x4000
def off(a): return a-0x4000+base if a>=0x4000 else a
def trace(entries):
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
def show(code,lo=0x4000,hi=0x8000):
    last=None
    for pc in sorted(code):
        if not lo<=pc<hi: continue
        l,m,t,k=code[pc]
        if last is not None and pc!=last: print('------ gap %04X-%04X'%(last,pc-1))
        print('%04X %-8s %s'%(pc,r[off(pc):off(pc)+l].hex(),m)); last=pc+l
if __name__=='__main__':
    show(trace([int(x,16) for x in sys.argv[1:]] or [0x4000,0x4003]))
