"""Transfer names from a labelled Region to another Region holding a related version of the code.

Instructions are compared as skeletons (mnemonic + operand kinds, 8-bit immediates kept, addresses
dropped). difflib aligns the two instruction streams; matched instructions map code addresses
one to one, and their address operands vote for a RAM / data address mapping."""
import difflib, collections

JRJP = False
def skeleton(d):
    l, fmt, args, k = d
    if JRJP and fmt.startswith('jr '): fmt = 'jp ' + fmt[3:]
    vals = []
    for t, v in args:
        if t == 'i8': vals.append(f'${v:02x}')
        elif t == 'io': vals.append(f'io{v & 0xff:02x}')
        elif t == 'rst': vals.append(f'${v:02x}')
        elif JRJP and t == 'rel': vals.append('JP')
        else: vals.append(t.upper())
    return fmt.format(*vals)

def align(src, dst, lo_s=None, hi_s=None, lo_d=None, hi_d=None):
    sp = [pc for pc in sorted(src.code) if (lo_s is None or lo_s <= pc < hi_s)]
    dp = [pc for pc in sorted(dst.code) if (lo_d is None or lo_d <= pc < hi_d)]
    st = [skeleton(src.code[p]) for p in sp]
    dt = [skeleton(dst.code[p]) for p in dp]
    sm = difflib.SequenceMatcher(None, st, dt, autojunk=False)
    pcmap = {}
    votes = collections.defaultdict(collections.Counter)
    for i, j, n in sm.get_matching_blocks():
        if n < 3: continue
        for k in range(n):
            a, b = sp[i+k], dp[j+k]
            pcmap[a] = b
            for (t1, v1), (t2, v2) in zip(src.code[a][2], dst.code[b][2]):
                if t1 in ('a16', 'i16', 'jp', 'call', 'rel') and (t1 == t2 or (JRJP and {t1, t2} == {'jp', 'rel'})):
                    votes[v1][v2] += 1
    valmap = {v: c.most_common(1)[0][0] for v, c in votes.items()}
    matched = sum(1 for _ in pcmap)
    return pcmap, valmap, matched, len(sp), len(dp)

def transfer_labels(src, dst, pcmap, valmap, ram_names, data_ok=True):
    """returns (code_labels, ram_names_dst, data_labels) for dst"""
    code = {}
    for a, name in src.labels.items():
        if a in pcmap: code[pcmap[a]] = name
        elif data_ok and a in valmap and a not in src.code and src.inreg(a):
            code.setdefault(valmap[a], name)
    ram = {}
    for a, name in ram_names.items():
        if a in valmap:
            ram.setdefault(valmap[a], name)
    return code, ram
