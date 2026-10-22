"""Walk FFL2_audio.s (WLA-DX) against the ROM: gives every label's address and every symbolic operand's value."""
import sys, os, re
sys.path.insert(0, os.path.dirname(__file__))
from sm83 import decode
def align(src, rom, bank=0x0E):
    r = open(rom, 'rb').read(); base = bank * 0x4000
    pc = 0x4000; labels = {}; syms = {}; problems = []
    for ln, line in enumerate(open(src), 1):
        s = line.split(';')[0].rstrip()
        if not s.strip(): continue
        st = s.strip()
        if st.startswith(('.include', '.bank', '.orga', '.section', '.ends')): continue
        m = re.match(r'^([A-Za-z_]\w*):\s*(.*)$', st)
        if m: labels[m.group(1)] = pc; st = m.group(2).strip()
        st = re.sub(r'^[-+]+\s+', '', st)
        if not st: continue
        if st.startswith('.db'): pc += len(st[3:].split(',')); continue
        if st.startswith(('.dw', '.addr')): pc += 2 * len(st.split(None, 1)[1].split(',')); continue
        l, mn, t, k = decode(r, base + pc - 0x4000, pc)
        # symbolic operand -> numeric value from the ROM instruction
        mm = re.search(r'\(?<?([A-Za-z_][\w.]*)(\+\d+)?\)?', st.split(None, 1)[1]) if ' ' in st else None
        op = st.split()[0]
        if op != mn.split()[0] and not (op in ('ldi', 'ldd') and mn.startswith('ld')) and not (op == 'jp' and mn.startswith('jp')):
            problems.append((ln, '%04X' % pc, st, mn))
        nums = re.findall(r'\$([0-9A-F]{4})', mn)
        if mm and nums and mm.group(1) not in ('a', 'b', 'c', 'd', 'e', 'h', 'l', 'hl', 'de', 'bc', 'sp', 'af', 'nz', 'z', 'nc'):
            v = int(nums[0], 16) - (int(mm.group(2)[1:]) if mm.group(2) else 0)
            syms.setdefault(mm.group(1), set()).add(v)
        elif mm and re.search(r'<([A-Za-z_][\w.]*)', st):
            n = re.search(r'<([A-Za-z_][\w.]*)(\+\d+)?', st)
            nn = re.findall(r'\$(FF[0-9A-F]{2})', mn)
            if nn: syms.setdefault(n.group(1), set()).add(int(nn[0], 16) - (int(n.group(2)[1:]) if n.group(2) else 0))
        # ldh with <sym
        n = re.search(r'<([A-Za-z_][\w.]*)(\+\d+)?', st)
        if n:
            nn = re.findall(r'\$(FF[0-9A-F]{2})', mn)
            if nn: syms.setdefault(n.group(1), set()).add(int(nn[0], 16) - (int(n.group(2)[1:]) if n.group(2) else 0))
        pc += l
    return pc, labels, syms, problems
if __name__ == '__main__':
    end, labels, syms, problems = align(sys.argv[1], sys.argv[2])
    print('end %04X' % end, len(labels), 'labels; problems', problems[:10])
    for k, v in sorted(syms.items(), key=lambda x: min(x[1])):
        if not k[0].isupper() or True: print('%-36s %s' % (k, ' '.join('%04X' % x for x in sorted(v))))
