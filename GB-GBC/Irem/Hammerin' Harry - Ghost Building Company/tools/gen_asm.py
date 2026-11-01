# Assembly generator for the Irem GB sound drivers (Kid Niki / Hammerin' Harry).
# usage: python3 gen_asm.py <kn|hh> <out.asm>
import sys,importlib
sys.path.insert(0,__import__('os').path.join(__import__('os').path.dirname(__import__('os').path.dirname(__import__('os').path.abspath(__file__))),'tools'))
from sm83 import ROM,decode,trace
from iremdata import Walker
NOTES=['C_','Cs','D_','Ds','E_','F_','Fs','G_','Gs','A_','As','B_']
def notename(n): return '%s%d'%(NOTES[n%12],2+n//12)
HW={}
for line in open(__import__('os').path.join(__import__('paths').ROOT,'hardware.inc')):
    p=line.split()
    if len(p)>=4 and p[0]=='DEF' and p[2]=='EQU' and p[1].startswith('rNR') and p[3].startswith('$FF'):
        HW[int(p[3][1:],16)]=p[1]
class Gen:
    def __init__(s,cfg):
        s.cfg=cfg; s.R=ROM(cfg.ROMFILE); s.out=[]
        s.rlab={}   # (bank,addr) -> name
        s.ram=dict(cfg.RAM)
        s.comment=dict(cfg.COMMENTS); s.block=dict(cfg.BLOCKS)
    # ---------------- labels
    def lab(s,bank,a,name=None):
        k=(0 if a<0x4000 else bank,a)
        if name: s.rlab[k]=name
        return s.rlab.get(k)
    def ref(s,bank,a):
        k=(0 if a<0x4000 else bank,a)
        n=s.rlab.get(k)
        if n is None: raise KeyError('no label for %02x:%04x'%k)
        return n
    def emit(s,t=''): s.out.append(t)
    # ---------------- code
    def code_prepare(s,bank,entries,names,tables=()):
        code,labels,calls=trace(s.R,bank,entries,noreturn=(0x28,),nofollow=(0x4000,0x08,0x10,0x18,0x20,0x30) if bank==0 else ())
        if bank==0:
            code={a:v for a,v in code.items() if a<0x4000}
        s.code=getattr(s,'code',{}); s.code.update({(bank,a):v for a,v in code.items()})
        glob=None
        for a,n in names.items(): s.lab(bank,a,n)
        # re-parent named local labels to the global label that precedes them
        g2=None
        for a in sorted(set(code)|set(names)):
            k=(0 if a<0x4000 else bank,a); n=s.rlab.get(k)
            if n and '.' not in n: g2=n
            elif n and '.' in n and g2 and n.split('.')[0]!=g2: s.rlab[k]=g2+'.'+n.split('.',1)[1]
        # local labels for remaining branch targets
        for a in sorted(code):
            k=(0 if a<0x4000 else bank,a)
            if k in s.rlab and not s.rlab[k].startswith('.'): glob=s.rlab[k]
            if a in labels and k not in s.rlab:
                s.rlab[k]=('%s.l%04x'%(glob,a)) if glob else 'L_%04x'%a
        return code
    def fmt_op(s,bank,a,n,m,val,op):
        if op==0xcb or '%s' not in m:
            if op in range(0xc7,0x100,8) and m.startswith('rst'): return 'rst $%02x'%(op&0x38)
            return m.replace('ld [c],a','ldh [c],a').replace('ld a,[c]','ldh a,[c]')
        ov=s.cfg.OPERAND.get((bank,a))
        if ov: return m%ov
        if op in (0x18,0x20,0x28,0x30,0x38,0xc3,0xc2,0xca,0xd2,0xda,0xcd,0xc4,0xcc,0xd4,0xdc):
            return m%s.ref(s.cfg.BANK if (bank==0 and val>=0x4000) else bank,val)
        if m.startswith('ldh'):
            return m%(HW.get(val) or s.ram.get(val) or '$%04x'%val)
        if n==3:
            if val in s.ram: return m%s.ram[val]
            if val>=0xff00: return m%(HW.get(val) or '$%04x'%val)
            k=(0 if val<0x4000 else bank,val)
            if k in s.rlab and not op in (0x01,0x11) or (op in (0x01,0x11,0x21) and k in s.rlab):
                return m%s.rlab[k]
            return m%('$%04x'%val)
        return m%('$%02x'%val)
    def emit_label(s,bank,a):
        if a in s.block.get(bank,{}):
            for l in s.block[bank][a]: s.emit(l)
        k=(0 if a<0x4000 else bank,a)
        n=s.rlab.get(k)
        if n:
            if '.' in n and not n.startswith('L_'): s.emit('.'+n.split('.',1)[1])
            else: s.emit(n+':' + (':' if s.cfg.EXPORT else ''))
    def emit_code(s,bank,lo,hi):
        a=lo
        while a<hi:
            s.emit_label(bank,a)
            n,m,val,op=s.code[(bank,a)]
            t='    '+s.fmt_op(bank,a,n,m,val,op)
            c=s.comment.get((bank,a))
            raw=' '.join('%02x'%s.R.b(bank,a+i) for i in range(n))
            s.emit('%-36s; %04x %s%s'%(t,a,raw.ljust(8),('  '+c) if c else ''))
            a+=n
    # ---------------- data
    def emit_db(s,bank,lo,hi,per=16,cmt=None):
        a=lo
        while a<hi:
            s.emit_label(bank,a)
            e=min(hi,a+per)
            # stop at next label
            for x in range(a+1,e):
                if (bank if x>=0x4000 else 0,x) in s.rlab or x in s.block.get(bank,{}): e=x; break
            c=s.comment.get((bank,a))
            s.emit('%-36s; %04x%s'%('    db '+', '.join('$%02x'%s.R.b(bank,x) for x in range(a,e)),a,('  '+c) if c else ''))
            a=e
    def emit_fill(s,bank,lo,hi):
        v=s.R.b(bank,lo); assert all(s.R.b(bank,x)==v for x in range(lo,hi))
        s.emit_label(bank,lo)
        s.emit('    ds $%x, $%02x%s; %04x-%04x unused'%(hi-lo,v,' '*20,lo,hi-1))
    def emit_dw(s,bank,lo,hi,per=8,labels=False,cmts=None):
        a=lo; i=0
        while a<hi:
            s.emit_label(bank,a)
            e=min(hi,a+2*per)
            vals=[s.R.w(bank,x) for x in range(a,e,2)]
            txt=', '.join(s.ref(bank,v) if labels else '$%04x'%v for v in vals)
            c=(cmts[i] if cmts else None) or s.comment.get((bank,a))
            s.emit('%-36s; %04x%s'%('    dw '+txt,a,('  '+c) if c else '')); a=e; i+=1
    def emit_text(s,bank,lo,hi):
        s.emit_label(bank,lo)
        s.emit('    db "%s"%s; %04x'%(bytes(s.R.b(bank,x) for x in range(lo,hi)).decode(),' '*10,lo))

def stream_labels(g,w,cfg):
    P=cfg.P; names={}
    for i,ps in enumerate(w.idtab):
        for k,p in enumerate(ps):
            if (1,p) not in names: names[(1,p)]='%s_Snd%02X_Ch%d'%(P,i,k+1)
    for a,why in w.labels.items():
        if (1,a) in names: continue
        if any(x.startswith('call') for x in why): names[(1,a)]='%s_Sub_%04X'%(P,a)
        elif any(x.startswith('jump') for x in why): names[(1,a)]='%s_Loop_%04X'%(P,a)
        else: names[(1,a)]='%s_Orphan_%04X'%(P,a)
    for k,v in getattr(cfg,'STREAM_NAMES',{}).items(): names[(1,k)]=v
    g.rlab.update(names)
def emit_streams(g,w,cfg,lo,hi):
    bank=1; a=lo; pend=[]
    def flush():
        if pend:
            g.emit('    db '+', '.join(x[1] for x in pend)); pend.clear()
    while a<hi:
        if (1,a) in g.rlab or a in g.block.get(1,{}):
            flush(); g.emit_label(1,a)
        it=w.items.get(a)
        if it is None:
            # raw byte not reached by any stream
            flush(); e=a+1
            while e<hi and e not in w.items and (1,e) not in g.rlab: e+=1
            g.emit_db(1,a,e); a=e; continue
        n,k=it; x=w.b(a)
        if k=='note':
            chs=w.chan.get(a,{0})
            if x==0x89: t='HOLD'
            elif 4 in chs or 0 in chs or x>=cfg.NPERIODS: t='$%02x'%x
            else: t=notename(x)
            pend.append((a,t))
            if len(pend)>=12: flush()
        elif k=='speed':
            flush(); g.emit('    speed %d'%(x-cfg.SPEEDBASE))
        else:
            flush(); name,kind=cfg.CMDS[x]
            if kind=='b': g.emit('    %s $%02x'%(name,w.b(a+1)))
            elif kind=='w': g.emit('    %s %s'%(name,g.ref(1,w.b(a+1)|w.b(a+2)<<8)))
            else: g.emit('    '+name)
        a+=n
    flush()
def macros(cfg):
    L=['; ---- stream macros','MACRO speed','    db $%02X + (\\1)'%cfg.SPEEDBASE,'ENDM']
    for x,(n,k) in sorted(cfg.CMDS.items()):
        L+=['MACRO '+n,'    db $%02X'%x+(', \\1' if k=='b' else ''),*(['    dw \\1'] if k=='w' else []),'ENDM']
    L+=['DEF HOLD EQU $89','; note names = period table index (note + transpose)']
    for i in range(cfg.NPERIODS): L.append('DEF %s EQU %d'%(notename(i),i))
    return L
def add_orphans(w,lo,hi):
    import copy
    while True:
        gaps=[]; a=lo
        while a<hi:
            if a in w.items: a+=w.items[a][0]; continue
            e=a
            while e<hi and e not in w.items: e+=1
            gaps.append((a,e)); a=e
        added=False
        for gs,ge in gaps:
            t=copy.deepcopy(w)
            try: t.walk(gs,'orphan',0)
            except KeyError: continue
            new=[x for x in t.items if x not in w.items]
            if all(gs<=x and x+t.items[x][0]<=ge for x in new) and new:
                w.items,w.labels,w.chan=t.items,t.labels,t.chan; added=True; break
        if not added: return
def main(game,outfn):
    cfg=importlib.import_module('cfg_'+game)
    g=Gen(cfg)
    w=Walker(game).run()
    for lo,hi in getattr(cfg,'ORPHAN_RANGES',()): add_orphans(w,lo,hi)
    stream_labels(g,w,cfg)
    for d in (cfg.DATA_NAMES,):
        for a,n in d.items(): g.lab(cfg.BANK if a>=0x4000 else 0,a,n)
    for bank,ents in cfg.CODE_ENTRIES.items():
        g.code_prepare(bank,ents,{a:n for a,n in cfg.CODE_NAMES.items() if (a<0x4000)==(bank==0)})
    for l in cfg.HEADER: g.emit(l)
    g.emit('INCLUDE "hardware.inc"'); g.emit('')
    for a,n in sorted(cfg.RAM.items()):
        if '+' not in n: g.emit('DEF %s EQU $%04X'%(n,a))
    for l in getattr(cfg,'EQUS',[]): g.emit(l)
    g.emit('')
    for l in macros(cfg): g.emit(l)
    for sec in cfg.LAYOUT:
        kind=sec[0]
        if kind=='section':
            _,name,bank,addr=sec; g.emit(''); g.emit('SECTION "%s", %s[$%04X]%s'%(name,'ROM0' if bank==0 else 'ROMX',addr,'' if bank==0 else ', BANK[$%X]'%bank)); continue
        _,bank,lo,hi=sec[:4]; opt=sec[4] if len(sec)>4 else {}
        if kind=='code': g.emit_code(bank,lo,hi)
        elif kind=='db': g.emit_db(bank,lo,hi,opt.get('per',16))
        elif kind=='fill': g.emit_fill(bank,lo,hi)
        elif kind=='dw': g.emit_dw(bank,lo,hi,opt.get('per',8),opt.get('labels',False),opt.get('cmts'))
        elif kind=='text': g.emit_text(bank,lo,hi)
        elif kind=='streams': emit_streams(g,w,cfg,lo,hi)
        elif kind=='custom': sec[4](g,w)
    open(outfn,'w').write('\n'.join(g.out)+'\n')
    return g,w
if __name__=='__main__':
    main(sys.argv[1],sys.argv[2])
