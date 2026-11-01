# Minimal SM83 decoder + recursive tracer (uses mgbdis tables)
import sys
from sm83_ops import instructions, cb_instructions
SIZE={'d8':1,'a8':1,'r8':1,'d16':2,'a16':2}
def ilen(op):
    if op==0xcb: return 2
    m=instructions.get(op,'')
    for k,v in SIZE.items():
        if k in m: return 1+v
    if m.startswith('ldh') and ('a8' in m): return 2
    return 1
class ROM:
    def __init__(s,fn): s.d=open(fn,'rb').read()
    def off(s,bank,a): return a if a<0x4000 else bank*0x4000+(a-0x4000)
    def b(s,bank,a): return s.d[s.off(bank,a)]
    def w(s,bank,a): return s.b(bank,a)|s.b(bank,a+1)<<8
def decode(rom,bank,a):
    op=rom.b(bank,a)
    if op==0xcb:
        return 2,cb_instructions[rom.b(bank,a+1)],None,0xcb
    m=instructions.get(op,'db $%02x'%op); n=ilen(op); val=None; nxt=[]
    if n==2:
        v=rom.b(bank,a+1)
        if 'r8' in m:
            v=v-256 if v>127 else v; val=(a+2+v)&0xffff
            m=m.replace('pc+r8','%s') if 'pc+r8' in m else m.replace('r8','%d'%v)
            if 'sp+r8' in m or 'sp,' in m: pass
        elif 'a8' in m: val=0xff00|v; m=m.replace('a8','%s')
        else: val=v; m=m.replace('d8','%s')
    elif n==3:
        val=rom.w(bank,a+1); m=m.replace('a16','%s').replace('d16','%s')
    return n,m,val,op
FLOW_END={0xc3,0xe9,0x18,0xc9,0xd9}
def targets(n,m,val,op,a):
    """returns (fallthrough?, [branch targets], is_call)"""
    if isinstance(op,str) or op is None: return True,[],False
    if op in (0xc3,0x18): return False,[val],False
    if op in (0xc2,0xca,0xd2,0xda,0x20,0x28,0x30,0x38): return True,[val],False
    if op in (0xcd,0xc4,0xcc,0xd4,0xdc): return True,[val],True
    if op in (0xc9,0xd9,0xe9): return False,[],False
    if op & 0xc7 ==0xc7 : return True,[op&0x38],True
    return True,[],False
def trace(rom,bank,entries,limit=None,noreturn=(),nofollow=()):
    code={}; labels=set(); work=list(entries); calls=set()
    while work:
        a=work.pop()
        while a not in code:
            if limit and not (limit[0]<=a<limit[1]) and a>=0x4000: break
            n,m,val,op=decode(rom,bank,a)
            code[a]=(n,m,val,op)
            ft,tg,ic=targets(n,m,val,op,a)
            for t in tg:
                labels.add(t)
                if ic: calls.add(t)
                if t not in noreturn and t not in nofollow: work.append(t)
            if ic and tg and tg[0] in noreturn: break
            if not ft: break
            a+=n
    return code,labels,calls

def fmt(m,val,labels=None):
    if '%s' not in m: return m
    if labels and val in labels: return m%labels[val]
    if 'ldh' in m and val is not None and val>=0xff00: return m%('$ff%02x'%(val&0xff))
    if val is not None and val<0x100 and ('d8' not in m): pass
    return m%(('$%02x' if val<0x100 else '$%04x')%val)
def listing(rom,bank,code,lo,hi,labels=None):
    out=[]
    for a in sorted(code):
        if lo<=a<hi:
            n,m,val,op=code[a]
            out.append('%04x: %-9s %s'%(a,' '.join('%02x'%rom.b(bank,a+i) for i in range(n)),fmt(m,val,labels)))
    return out
