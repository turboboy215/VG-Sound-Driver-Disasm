# Shared asm emitter for the Source/Ra generators.
import sys
import os; sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode

HWREG={0x10:'rNR10',0x11:'rNR11',0x12:'rNR12',0x13:'rNR13',0x14:'rNR14',
 0x16:'rNR21',0x17:'rNR22',0x18:'rNR23',0x19:'rNR24',0x1A:'rNR30',0x1B:'rNR31',
 0x1C:'rNR32',0x1D:'rNR33',0x1E:'rNR34',0x20:'rNR41',0x21:'rNR42',0x22:'rNR43',
 0x23:'rNR44',0x24:'rNR50',0x25:'rNR51',0x26:'rNR52',0x30:'_AUD3WAVERAM'}

class Rom:
    def __init__(s,path): s.d=open(path,'rb').read()
    def off(s,bank,a): return a if a<0x4000 else bank*0x4000+a-0x4000
    def b(s,bank,a): return s.d[s.off(bank,a)]
    def w(s,bank,a): o=s.off(bank,a); return s.d[o]|s.d[o+1]<<8
    def bytes(s,bank,a,n): o=s.off(bank,a); return s.d[o:o+n]

def hx(v,n=2): return ('$%0'+str(n)+'X')%v

def code_lines(rom,bank,lo,hi,labels,ram,comments=None,imm_labels=None):
    """linear disassembly lo..hi (must be pure code). labels: addr->name (ROM),
    ram: addr->name, imm_labels: addr->name used for ld rr,nnnn immediates."""
    comments=comments or {}; imm_labels=imm_labels or {}
    out=[]; a=lo
    def lab(t): 
        if t in labels: return labels[t]
        raise KeyError('no label for %04X (from %04X)'%(t,a))
    while a<hi:
        if a in labels and a!=lo: out.append('%s:'%labels[a])
        o=rom.off(bank,a); l,t,info=decode(rom.d,o)
        if info=='bad': raise ValueError('bad opcode at %02X:%04X'%(bank,a))
        if info and info[0]=='jr':
            tg=(a+2+info[2])&0xFFFF; t='jr '+(info[1]+', ' if info[1] else '')+lab(tg)
        elif info and info[0] in ('jp','call'):
            t=info[0]+' '+(info[1]+', ' if info[1] else '')+lab(info[2])
        elif info and info[0]=='ldh':
            n=info[1]; nm=HWREG.get(n,'$FF%02X'%n)
            t=t.replace('[$%02X]'%n,'[%s]'%nm)
        elif info and info[0]=='mem':
            v=info[1]
            if v in ram: t=t.replace('[$%04X]'%v,'[%s]'%ram[v])
        elif info and info[0]=='imm16':
            v=info[1]
            if v in imm_labels: t=t.replace('$%04X'%v,imm_labels[v])
            elif v in ram: t=t.replace('$%04X'%v,ram[v])
        c=comments.get(a)
        out.append('\t%s%s'%(t,('\t; '+c) if c else ''))
        a+=l
    return out

def db_lines(bs,per=16):
    return ['\tdb '+', '.join(hx(x) for x in bs[i:i+per]) for i in range(0,len(bs),per)]

def ram_equs(ram,comments={}):
    out=[]
    for a in sorted(ram):
        c=comments.get(a)
        out.append('DEF %-22s EQU $%04X%s'%(ram[a],a,('\t; '+c) if c else ''))
    return out

NOTE_NAMES=['C_','Cs','D_','Ds','E_','F_','Fs','G_','Gs','A_','As','B_']

def code_lines2(rom,bank,lo,hi,labels,ram,comments=None,imm_labels=None):
    """like code_lines but supports local labels ('.x') with scope resolution.
    labels: addr->name; names starting with '.' are local to the previous global."""
    comments=comments or {}; imm_labels=imm_labels or {}
    # scope map
    scope={}; cur=None
    for a in sorted(labels):
        if not labels[a].startswith('.'): cur=labels[a]
        scope[a]=cur
    def ref(t,curscope):
        if t not in labels: raise KeyError('no label for %04X'%t)
        n=labels[t]
        if n.startswith('.'):
            return n if scope[t]==curscope else scope[t]+n
        return n
    out=[]; a=lo; cs=None
    for x in sorted(labels):
        if x<=lo and not labels[x].startswith('.'): cs=labels[x]
    while a<hi:
        if a in labels:
            if not labels[a].startswith('.'): cs=labels[a]
            out.append('%s:'%labels[a])
        o=rom.off(bank,a); l,t,info=decode(rom.d,o)
        if info=='bad': raise ValueError('bad opcode at %02X:%04X'%(bank,a))
        if info and info[0]=='jr':
            tg=(a+2+info[2])&0xFFFF; t='jr '+(info[1]+', ' if info[1] else '')+ref(tg,cs)
        elif info and info[0] in ('jp','call'):
            t=info[0]+' '+(info[1]+', ' if info[1] else '')+ref(info[2],cs)
        elif info and info[0]=='ldh':
            n=info[1]; nm=HWREG.get(n,'$FF%02X'%n)
            t=t.replace('[$%02X]'%n,'[%s]'%nm)
        elif info and info[0]=='mem':
            v=info[1]
            if v in ram: t=t.replace('[$%04X]'%v,'[%s]'%ram[v])
        elif info and info[0]=='imm16':
            v=info[1]
            if v in imm_labels: t=t.replace('$%04X'%v,imm_labels[v])
        c=comments.get(a)
        out.append('\t%s%s'%(t,('\t; '+c) if c else ''))
        a+=l
    return out
