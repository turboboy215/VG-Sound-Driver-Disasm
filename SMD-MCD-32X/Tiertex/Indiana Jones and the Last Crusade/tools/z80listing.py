import subprocess, re, sys, importlib.util
def load(p):
    spec = importlib.util.spec_from_file_location('m', p); m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m); return m
def render(binf, annot, title, org=0):
    A = annot
    with open('/tmp/claude-0/blk.txt','w') as f:
        for i,(s,e,t) in enumerate(A.BLOCKS): f.write('b%d: start 0x%04x end 0x%04x type %s\n' % (i,s,e,t))
    raw = subprocess.run(['z80dasm','-a','-t','-g',str(org),'-b','/tmp/claude-0/blk.txt',binf],capture_output=True,text=True).stdout
    lines = []
    for ln in raw.splitlines():
        m = re.match(r'\t(.*?)\t+;([0-9a-f]{4})\t((?:[0-9a-f]{2} )+)', ln)
        if m: lines.append((int(m.group(2),16), m.group(1).strip(), m.group(3).strip()))
    names = {a:v[0] for a,v in A.LABELS.items()}
    targets = set()
    for a,ins,b in lines:
        m = re.match(r'(jp|jr|call|djnz)\b.*?([0-9a-f]{4,5})h$', ins)
        if m: targets.add(int(m.group(2),16))
        m = re.match(r'(jr|djnz)\b.*?\$([+-]\d+)$', ins)
        if m: targets.add(a + int(m.group(2)))
    for t in targets:
        if t not in names: names[t] = 'loc_%04X' % t
    def sym(v):
        return names.get(v)
    out = ['; ' + l for l in title.splitlines()] + ['']
    for a,n in sorted(A.RAM.items()): out.append('%-16s equ $%04X' % (n, a))
    out.append(''); out.append('\torg $%04X' % org)
    for a,ins,b in lines:
        if a in names:
            hdr = A.LABELS.get(a, (None,None))[1]
            out.append('')
            if hdr:
                for h in hdr.split('\n'): out.append('; ' + h)
            out.append(names[a] + ':')
        def repl_branch(m):
            v = int(m.group(2),16); return m.group(1) + (sym(v) or '$%04X' % v)
        ins2 = re.sub(r'^((?:jp|jr|call|djnz)\b.*?)([0-9a-f]{4,5})h$', repl_branch, ins)
        ins2 = re.sub(r'^((?:jr|djnz)\b.*?)\$([+-]\d+)$', lambda m: m.group(1) + (sym(a + int(m.group(2))) or '$%04X' % (a + int(m.group(2)))), ins2)
        def repl_mem(m):
            v = int(m.group(1),16); n = A.RAM.get(v) or (names.get(v) if v in A.LABELS else None)
            return '(' + (n or '$%04X' % v) + ')'
        ins2 = re.sub(r'\(0?([0-9a-f]{4})h\)', repl_mem, ins2)
        def repl_imm(m):
            v = int(m.group(2),16)
            n = A.RAM.get(v) if (0x0800 <= v <= 0x0A00 or v in (0x1F00,0x2000,0x4000,0x6000)) else None
            if n is None and v in getattr(A,'PTRS',{}): n = A.PTRS[v]
            return m.group(1) + (n or '$%04X' % v)
        ins2 = re.sub(r'^(ld (?:hl|de|bc|ix|iy|sp),)0?([0-9a-f]{4})h$', repl_imm, ins2)
        mm = re.match(r'defw 0?([0-9a-f]{4})h$', ins2)
        if mm and int(mm.group(1),16) and int(mm.group(1),16) in names and int(mm.group(1),16) in A.LABELS: ins2 = 'defw ' + names[int(mm.group(1),16)]
        ins2 = re.sub(r'\b0?([0-9a-f]{2,4})h\b', lambda m: '$' + m.group(1).upper().lstrip('0').rjust(2,'0'), ins2)
        c = A.C.get(a, '')
        out.append('\t%-24s; %04X: %-12s %s' % (ins2, a, b, c))
    return '\n'.join(out) + '\n'

def insns(binf, org=0):
    raw = subprocess.run(['z80dasm','-a','-t','-g',str(org),binf],capture_output=True,text=True).stdout
    L=[]
    for ln in raw.splitlines():
        m = re.match(r'\t(.*?)\t+;([0-9a-f]{4})\t((?:[0-9a-f]{2} )+)', ln)
        if m: L.append((int(m.group(2),16), m.group(1).strip()))
    return L
def addrmap(binA, binB):
    import difflib
    A = insns(binA); B = insns(binB)
    norm = lambda t: re.sub(r'[0-9a-f]{4,5}h|\$[+-]\d+', 'X', t)
    sm = difflib.SequenceMatcher(None, [norm(t) for _,t in A], [norm(t) for _,t in B], autojunk=False)
    M = {}
    for tag,i1,i2,j1,j2 in sm.get_opcodes():
        if tag == 'equal':
            for k in range(i2-i1): M[A[i1+k][0]] = B[j1+k][0]
    return M, sm, A, B
