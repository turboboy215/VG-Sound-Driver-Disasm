"""Shared emitter helpers: code listing with labels."""
import sys; sys.path.insert(0,'tools')
from gbdis import decode
def hx(v,n=2): return f'${v:0{n}X}'
class CodeEmitter:
    """names: addr->global label; code: dict pc->Ins; sym16(v,ins)->str or None"""
    def __init__(s,get,code,names,sym16,symhram,data_blocks,comments=None):
        s.get=get; s.code=code; s.names=dict(names); s.sym16=sym16; s.symhram=symhram
        s.data=data_blocks  # addr -> (size, list_of_lines)
        s.comments=comments or {}
        s.ext={}
        s.farcall=lambda ins: f'rst $20\n\tdw ${ins.far[0]:04X}\n\tdb ${ins.far[1]:02X}'
        s.targets=set()
        for ins in code.values():
            if ins.kind in('rel','jp','call') : s.targets.add(ins.val)
        s.globals=sorted(s.names)
    def owner(s,a):
        import bisect
        i=bisect.bisect_right(s.globals,a)-1
        return s.names[s.globals[i]] if i>=0 else None
    def ref(s,t,cur):
        if t in s.names: return s.names[t]
        if t in s.ext: return s.ext[t]
        o=s.owner(t)
        loc=f'.l{t:04X}'
        return loc if o==cur else f'{o}{loc}'
    def emit(s,start,end,extra_locals=()):
        out=[]; pc=start; cur=None
        while pc<end:
            if pc in s.names:
                cur=s.names[pc]
                if out and out[-1]!='': out.append('')
                if pc in s.comments: out+= ['; '+l for l in s.comments[pc].split('\n')]
                out.append(f'{cur}:')
            elif pc in s.targets or pc in extra_locals:
                out.append(f'.l{pc:04X}:')
            if pc in s.data:
                sz,lines=s.data[pc]; out+=['\t'+l for l in lines]; pc+=sz; continue
            ins=s.code.get(pc)
            if ins is None:
                out.append(f'\tdb ${s.get(pc):02X} ; unreached'); pc+=1; continue
            t=ins.text
            if t=='FARCALL': txt=s.farcall(ins)
            elif ins.kind is None: txt=t
            elif ins.kind in('rel','jp','call'):
                txt=t.format(s.ref(ins.val,cur))
            elif ins.kind=='hram': txt=t.format(s.symhram(ins.val))
            elif ins.kind=='imm8': txt=t.format(hx(ins.val))
            else:
                v=s.sym16(ins.val,ins); txt=t.format(v if v else hx(ins.val,4))
            out.append(f'\t{txt}')
            pc+=ins.size
        return out
