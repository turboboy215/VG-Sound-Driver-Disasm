"""gen_asm.py ROM OUT.s SYMS - regenerate a Rare GBA driver source.
SYMS = dkc1_syms | dkc2_syms | dkc3_syms (the module next to this script). Needs capstone."""
import sys,struct,capstone,re,os
sys.path.insert(0,os.path.dirname(os.path.abspath(__file__)))
import importlib
S=importlib.import_module(sys.argv[3] if len(sys.argv)>3 else os.environ.get('SYMS','dkc1_syms'))
T=S.TABLES
ROM=open(sys.argv[1],'rb').read()
OUT=sys.argv[2]
B=0x08000000
def u32(a): return struct.unpack_from('<I',ROM,a-B)[0]
def u16(a): return struct.unpack_from('<H',ROM,a-B)[0]
csA=capstone.Cs(capstone.CS_ARCH_ARM,capstone.CS_MODE_ARM); csA.detail=False
csT=capstone.Cs(capstone.CS_ARCH_ARM,capstone.CS_MODE_THUMB)
def mode_of(a): return 'a' if S.ARM_RANGE[0]<=a<S.ARM_RANGE[1] else 't' if S.THUMB_RANGE[0]<=a<S.THUMB_RANGE[1] else None
def dis1(a):
    m=mode_of(a)
    cs=csA if m=='a' else csT
    n=4 if m=='a' else 4
    for i in cs.disasm(ROM[a-B:a-B+n],a):
        return i
    return None
code={}      # addr -> insn
lits={}      # addr -> size (4)
labels={}    # addr -> name
for a,(n,m,c) in S.FUNCS.items(): labels[a]=n
for a,(n,c) in S.DATA.items(): labels[a]=n
seeds=list(S.FUNCS.keys())
# jump table targets
for t,(cnt,base) in S.JUMP_TABLES.items():
    for k in range(cnt):
        off=u32(t+4*k); 
        if off&0x80000000: off-=1<<32
        tgt=base+off; seeds.append(tgt); labels.setdefault(tgt,None)
        lits[t+4*k]=('jt',base)
def is_branch(i): return i.mnemonic.split('.')[0] in ('b','bl') or re.match(r'^b(l)?(eq|ne|cs|hs|cc|lo|mi|pl|vs|vc|hi|ls|ge|lt|gt|le)$',i.mnemonic)
work=list(seeds)
while work:
    a=work.pop()
    while True:
        if a in code or not mode_of(a) or a in lits: break
        i=dis1(a)
        if i is None: print('undecodable',hex(a)); break
        m=mode_of(a)
        code[a]=i
        mn=i.mnemonic; ops=i.op_str
        nxt=a+i.size
        # literal loads
        if mn.startswith('ldr') and '[pc' in ops:
            mm=re.search(r'\[pc, #(-?0x[0-9a-f]+|-?\d+)\]',ops)
            imm=int(mm.group(1),0) if mm else 0
            la=((a+(4 if m=='t' else 8))&~3)+imm
            lits[la]=('lit',None); labels.setdefault(la,None)
            if 'pc,' in ops.split('[')[0]:  # ldr pc,=... (absolute jump)
                tv=u32(la)&~1
                if S.REGION[0]<=tv<S.REGION[1]: labels.setdefault(tv,None); work.append(tv)
                break
        cond_end=False
        if is_branch(i):
            tgt=int(ops.lstrip('#'),16)
            labels.setdefault(tgt,None); work.append(tgt)
            if mn in ('b',): break
        if mn in ('bx',) : 
            # call veneer?  (mov lr, r0 within previous 3 insns)
            prev=[code.get(a-k) for k in (2,4,6)]
            if m=='t' and any(p is not None and p.mnemonic=='mov' and p.op_str.startswith('lr,') for p in prev):
                labels.setdefault(nxt,None); a=nxt; continue
            if m=='a' and code.get(a-4) is not None and code[a-4].op_str.startswith('lr, pc'):
                a=nxt; continue
            break
        if mn=='pop' and 'pc' in ops: break
        if mn=='mov' and ops.startswith('pc,'): break
        if mn=='ldr' and ops.startswith('pc,'): break
        if mn in ('add','sub') and ops.startswith('pc, pc, #'):
            imm=int(ops.split('#')[1],0); tgt=a+8+(imm if mn=='add' else -imm)
            labels.setdefault(tgt,None); work.append(tgt); break
        if mn=='add' and ops.startswith('pc,'): break
        if mn.startswith('ldm') and 'pc' in ops: break
        a=nxt
# name unnamed labels
for a in list(labels):
    if labels[a] is None: labels[a]=('L_%07X' if a not in lits else 'lit_%07X')%(a&0xFFFFFFF)
# --- symbolic values ---
def ram_sym(v):
    for (a,sz,n,c) in S.RAM:
        if a<=v<a+sz: return n if v==a else '%s+0x%X'%(n,v-a)
    return None
IW0,IW1=S.IWRAM_CODE_BASE,S.IWRAM_CODE_BASE+S.IWRAM_CODE_SIZE
def sym_val(v,ctx=None):
    if v in getattr(S,'ALIASES',{}): return S.ALIASES[v]
    if v in S.CONST: return S.CONST[v]
    if IW0<=v<IW1:
        r=v-IW0+S.IWRAM_CODE_ROM
        if r in labels: return '(%s - iwram_code_start + IWRAM_CODE_BASE)'%labels[r]
    if S.REGION[0]<=v<S.REGION[1] or S.REGION[0]<=(v&~1)<S.REGION[1]:
        r=v&~1
        if r in labels: return labels[r]+('+1' if v&1 else '')
    if v in S.EXT: return S.EXT[v][0]
    if v in S.HW: return S.HW[v]
    s=ram_sym(v)
    if s: return s
    return '0x%08X'%v
lines=[]
P=lines.append
P('@ ==========================================================================')
P('@ Rare GBA sound driver (%s) - reconstructed source'%S.TITLE)
P('@ ROM 0x%08X-0x%08X. Assembles byte-identical with:'%S.REGION)
P('@   arm-none-eabi-as -mcpu=arm7tdmi -o %s.o %s.s'%(S.STEM,S.STEM))
P('@   arm-none-eabi-ld -Ttext=0x%08X -o %s.elf %s.o'%(S.REGION[0],S.STEM,S.STEM))
P('@   arm-none-eabi-objcopy -O binary %s.elf %s.bin'%(S.STEM,S.STEM))
P('@ The ARM block (iwram_code_start..iwram_code_end) is copied to IWRAM 0x%08X'%S.IWRAM_CODE_BASE)
P('@ by snd_init and runs there; (x - iwram_code_start + IWRAM_CODE_BASE) is the run-time address.')
P('@ Labels, names and comments are reverse-engineered, not original symbols.')
P('@ ==========================================================================')
P('\t.syntax unified')
P('\t.cpu arm7tdmi')
P('\t.text')
P('')
P('\t.equ IWRAM_CODE_BASE, 0x%08X'%S.IWRAM_CODE_BASE)

P('')
P('@ ---- hardware registers ----')
for v,n in sorted(S.HW.items(),key=lambda x:x[0]): P('\t.equ %-22s 0x%08X'%(n+',',v))
P('@ ---- constants ----')
for v,n in S.CONST.items(): P('\t.equ %-22s 0x%08X'%(n+',',v))
P('@ ---- game data outside the driver ----')
for v,(n,c) in sorted(S.EXT.items()): P('\t.equ %-22s 0x%08X   @ %s'%(n+',',v,c))
P('@ ---- IWRAM variables ----')
for a,sz,n,c in S.RAM: P('\t.equ %-22s 0x%08X   @ %s'%(n+',',a,c))
P('')
# emit
def fmt_ins(a,i):
    m=mode_of(a); mn=i.mnemonic; ops=i.op_str
    if mn.startswith('ldr') and '[pc' in ops:
        mm=re.search(r'\[pc, #(-?0x[0-9a-f]+|-?\d+)\]',ops)
        imm=int(mm.group(1),0) if mm else 0
        la=((a+(4 if m=='t' else 8))&~3)+imm
        ops=ops[:ops.index('[pc')]+labels[la]
        return '%s %s'%(mn,ops), '= '+sym_val(u32(la))
    if is_branch(i):
        tgt=int(ops.lstrip('#'),16); return '%s %s'%(mn,labels[tgt]),None
    if mn in ('add','sub') and ops.startswith('pc, pc, #'):
        imm=int(ops.split('#')[1],0); tgt=a+8+(imm if mn=='add' else -imm)
        return '%s %s'%(mn,ops),'-> '+labels[tgt]
    if mn=='add' and re.match(r'^(r\d+|ip|sb|sl|fp), pc, #',ops):
        imm=int(ops.split('#')[1],0); tgt=a+8 if m=='a' else (a+4)&~3
        return '%s %s'%(mn,ops),'= '+labels.get(tgt+imm,hex(tgt+imm))
    return '%s %s'%(mn,ops),None
a=S.REGION[0]; curmode=None
order=[]
while a<S.REGION[1]:
    m=mode_of(a)
    if a==S.IWRAM_CODE_ROM: P('\t.balign 4'); P('iwram_code_start:')
    if a==S.ARM_RANGE[1]: P('iwram_code_end:'); P('')
    want='.arm' if m=='a' else '.thumb' if m=='t' else None
    if want and want!=curmode and (a in code or True):
        P('\t'+want); curmode=want
    if a in S.FUNCS and a in S.LOCAL and S.LOCAL[a]:
        P(''); P('@ '+S.LOCAL[a])
    elif a in S.FUNCS:
        n,mm,c=S.FUNCS[a]
        P('')
        P('@ ------------------------------------------------------------------')
        if mm=='a': P('@ %s   ROM 0x%08X / IWRAM 0x%08X (ARM)'%(n,a,a-S.IWRAM_CODE_ROM+IW0))
        else: P('@ %s   ROM 0x%08X (Thumb)'%(n,a))
        if c:
            for cl in c.split('\n'): P('@ '+cl.strip())
        P('@ ------------------------------------------------------------------')
        if mm=='t': P('\t.thumb_func')
        if n.startswith('snd_'): P('\t.global %s'%n)
    if a in S.DATA:
        n,c=S.DATA[a]; P(''); P('@ %s: %s'%(n,c))
    if a in labels and labels[a]: P('%s:'%labels[a])
    if a in code:
        i=code[a]; txt,cmt=fmt_ins(a,i)
        c2=S.COMMENTS.get(a)
        cm=' ; '.join(x for x in (cmt,c2) if x)
        P('\t%-36s @ %08X%s'%(txt,a,('  '+cm) if cm else ''))
        order.append((a,i.size,m))
        a+=i.size; continue
    # data
    if a in lits:
        kind,base=lits[a]
        if kind=='jt': P('\t.word %s - %s'%(labels[u32(a)+base if not u32(a)&0x80000000 else base+u32(a)-(1<<32)],labels[base]))
        else:
            v=u32(a)
            if a==S.REGION[0]: P('\t.word iwram_code_end - iwram_code_start')
            else: P('\t.word %s'%sym_val(v))
        order.append((a,4,'d')); a+=4; continue
    # tables
    if a==T['pitch']:
        for k in range(0,128,4): P('\t.word '+', '.join('0x%08X'%u32(a+4*(k+j)) for j in range(4)))
        a+=512; continue
    if a==T['adsr']:
        for k in range(0,100,10): P('\t.byte '+', '.join('%3d'%ROM[a-B+k+j] for j in range(10)))
        a+=100; continue
    if a==T['lfo']:
        for k in range(0,257,4):
            n=min(4,257-k); P('\t.word '+', '.join('0x%08X'%u32(a+4*(k+j)) for j in range(n)))
        a+=257*4; continue
    if a>=T['strings']:
        e=ROM.index(b'\0',a-B)+B
        if e>a:
            s=ROM[a-B:e-B].decode('ascii').replace('\\','\\\\').replace('"','\\"').replace('\n','\\n')
            P('\t.asciz "%s"'%s); a=e+1; continue
        P('\t.byte 0'); a+=1; continue
    # stray halfword/word inside code regions
    if m=='t' or (a%4): P('\t.hword 0x%04X'%u16(a)); a+=2; continue
    P('\t.word 0x%08X'%u32(a)); a+=4
P('')
open(OUT,'w').write('\n'.join(lines)+'\n')
print('code insns',len(code),'lits',len(lits),'labels',len(labels))
