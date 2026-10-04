import capstone, re
def render(rom, sections, labels, comments, title, data_notes={}):
    md = capstone.Cs(capstone.CS_ARCH_M68K, capstone.CS_MODE_M68K_000); md.skipdata = True
    out = ['; ' + l for l in title.splitlines()] + ['']
    labels = dict(labels)
    for (s0, e0, _) in sections:
        for i in md.disasm(rom[s0:e0], s0):
            if re.match(r'^(b[a-z]{2}|bra|bsr|db[a-z]{1,2}|jsr|jmp)(\.[bwl])?$', i.mnemonic):
                m = re.search(r'\$([0-9a-f]+)$', i.op_str)
                if m:
                    v = int(m.group(1), 16)
                    if any(a <= v < b for a, b, _ in sections) and v not in labels: labels[v] = ('loc_%06X' % v, None)
    for (s, e, name) in sections:
        out += ['', ';' + '=' * 78, '; ' + name, ';' + '=' * 78]
        for i in md.disasm(rom[s:e], s):
            a = i.address
            if a in labels:
                n, h = labels[a]
                out.append('')
                if h:
                    for hl in h.split('\n'): out.append('; ' + hl)
                out.append(n + ':')
            ops = i.op_str
            def rp(m):
                v = int(m.group(1), 16)
                if v in labels: return labels[v][0]
                return m.group(0)
            ops = re.sub(r'\$([0-9a-f]+)(?=\.l|\b(?![(.]))', rp, ops)
            ops = re.sub(r'\$([0-9a-f]+)', lambda m: '$' + m.group(1).upper(), ops)
            ins = ('%s %s' % (i.mnemonic, ops)).strip()
            out.append('\t%-40s; %06X: %-20s %s' % (ins, a, i.bytes.hex(), comments.get(a, '')))
    return '\n'.join(out) + '\n'
