"""Render the six driver code blocks (music/SFX x versions A/B/C) as RGBDS
include files with labels, RAM names and register names.

The code is identical in every bank of a version except for the addresses of
the tables it reads, so each bank file INCLUDEs the same text and defines the
table labels itself.
"""
import difflib
import os
import re
import sys

sys.path.insert(0, os.path.dirname(__file__))
from e2_parse import analyze, GAMES  # noqa: E402
from e2_names import RAM_BY_OFF, HW, MUS_A, MUS_A_COMMENTS, SFX_A, SFX_A_COMMENTS, LABEL_OVR, COMMENT_OVR  # noqa: E402

REPR = {  # version -> (game, music bank, sfx bank)
    'A': ('oha', 0x09, 0x08),
    'B': ('dora3', 0x06, 0x05),
    'C': ('sylv', 0x70, 0x7A),
}


def norm_list(B):
    out = []
    for a in sorted(B.code):
        t = B.code[a][1]
        t = re.sub(r'\$([0-9A-F]{4})', lambda m: '@' if 0x4000 <= int(m.group(1), 16) < 0x8000 else
                   ('W%02X' % (int(m.group(1), 16) & 0xFF) if (int(m.group(1), 16) >> 8) == (B.ram >> 8) else m.group(0)), t)
        out.append((a, t))
    return out


def table_role(B, order, i):
    """role of the ld hl,imm at order[i]"""
    a = order[i]
    t = B.code[a][1]
    x = int(t[-4:], 16)
    nxt = [B.code[order[j]][1] for j in range(i + 1, min(i + 30, len(order)))]
    if x == 0x4006:
        return 'songs'
    if nxt[0] == 'ld e,a' and nxt[1] == 'ld d,$00':
        return 'freq'
    if nxt[0] == 'ld d,a' and nxt[1].startswith('ld e,$'):
        for t2 in nxt[2:]:
            for reg, r in (('$FF10', 'inst1'), ('$FF16', 'inst2'), ('$FF30', 'wave'), ('$FF21', 'noise')):
                if t2.startswith('ldh [%s]' % reg):
                    return r
    if x == B.tables.get('freq'):
        return 'freq_unused'
    raise ValueError(t)


def table_labels(B):
    """address -> label name for the tables of a bank (one label per address)."""
    lab = {}
    lab[0x4006] = 'SongTable'
    lab[B.freq_start] = 'FreqTable'
    t = B.tables
    order = [('noise', 'NoiseTable'), ('wave', 'WaveTable'), ('inst2', 'Ch2InstTable'), ('inst1', 'Ch1InstTable')]
    for role, name in order:  # noise first, so shared SFX tables are called NoiseTable
        x = t[role][0]
        if x not in lab:
            lab[x] = name
    return lab


def build(version, kind):
    game, mb, sb = REPR[version]
    B = analyze(game, mb if kind == 'mus' else sb)
    names_a = MUS_A if kind == 'mus' else SFX_A
    comm_a = MUS_A_COMMENTS if kind == 'mus' else SFX_A_COMMENTS
    if version == 'A':
        amap = {a: a for a in B.code}
    else:
        BA = analyze('oha', 0x09 if kind == 'mus' else 0x08)
        la, lx = norm_list(BA), norm_list(B)
        sm = difflib.SequenceMatcher(None, [t for _, t in la], [t for _, t in lx], autojunk=False)
        amap = {}
        for blk in sm.get_matching_blocks():
            for k in range(blk.size):
                amap[lx[blk.b + k][0]] = la[blk.a + k][0]
        # entry points, and targets of aligned jumps, correspond as well
        amap.setdefault(B.init, BA.init)
        amap.setdefault(B.update, BA.update)
        for ax, aa in list(amap.items()):
            tx, ta = B.code[ax][2]['target'], BA.code[aa][2]['target']
            if tx is not None and ta is not None and 0x4000 <= tx < 0x8000 and 0x4000 <= ta < 0x8000:
                if tx not in amap and ta in BA.code_labels:
                    amap[tx] = ta
    order = sorted(B.code)
    start = order[0]
    # ---- label names
    targets = set(B.code_labels)
    labels = {}
    scope_of = {}
    cur_global = None
    pending_auto = {}
    for a in order:
        if a in targets:
            an = amap.get(a)
            nm = names_a.get(an, (None, None))[0] if an is not None else None
            ovr = LABEL_OVR.get((version, kind), {}).get(a - order[0])
            if ovr:
                nm = ovr
            if nm is None:
                cnt = pending_auto.get(cur_global, 0) + 1
                pending_auto[cur_global] = cnt
                nm = '.x%d' % cnt
            if not nm.startswith('.'):
                cur_global = nm
            else:
                # avoid duplicate local names within one scope
                used = {labels[b] for b in labels if scope_of.get(b) == cur_global}
                base, k = nm, 2
                while nm in used:
                    nm = '%s%d' % (base, k)
                    k += 1
            labels[a] = nm
        scope_of[a] = cur_global
    tl = table_labels(B)
    lines = []
    for i, a in enumerate(order):
        n, t, info = B.code[a]
        an = amap.get(a)
        if a in labels:
            nm = labels[a]
            hdr = names_a.get(an, (None, None))[1] if an is not None else None
            if not nm.startswith('.'):
                lines.append('')
                if hdr:
                    lines.append('; ' + hdr)
                lines.append('%s:' % nm)
            else:
                lines.append('%s:' % nm)
        # operand rendering
        txt = t
        if info['target'] is not None and info['kind'] in ('jp', 'jr', 'call') and 0x4000 <= info['target'] < 0x8000:
            tg = info['target']
            tn = labels[tg]
            if tn.startswith('.') and scope_of[tg] != scope_of[a]:
                tn = scope_of[tg] + tn
            txt = re.sub(r'\$[0-9A-F]{4}$', tn, txt)
        m = re.match(r'ld hl,\$([0-9A-F]{4})$', t)
        if m and 0x4000 <= int(m.group(1), 16) < 0x8000:
            x = int(m.group(1), 16)
            role = table_role(B, order, i)
            if role in ('freq', 'freq_unused'):
                txt = 'ld hl,FreqTable - 2'
            else:
                txt = 'ld hl,%s' % tl[x]
        def ramsub(mm):
            v = int(mm.group(1), 16)
            if v >> 8 == B.ram >> 8:
                return RAM_BY_OFF[v & 0xFF]
            if v in HW:
                return HW[v]
            return mm.group(0)
        if not (info['kind'] in ('jp', 'jr', 'call')):
            txt = re.sub(r'\$([0-9A-F]{4})', ramsub, txt)
        com = '+$%03X' % (a - start)
        extra = comm_a.get(an) if an is not None else None
        co = COMMENT_OVR.get((version, kind), {})
        if (a - start) in co:
            extra = co[a - start]
        if extra:
            com += '  ' + extra
        lines.append('    %-34s; %s' % (txt, com))
    return dict(B=B, lines=lines, labels=labels, start=start, end=B.code_hi, tables=tl)


HEADER = {
    'mus': 'Epoch sound driver type 2, version %s: music driver (one copy in every music bank)',
    'sfx': 'Epoch sound driver type 2, version %s: SFX driver',
}


def render(version, kind):
    r = build(version, kind)
    B = r['B']
    out = ['; ' + HEADER[kind] % version,
           '; Generated by tools/e2_gen.py from %s.' % GAMES[B.game]['title'],
           ';',
           '; Comments give the offset from the first instruction. The bank file that',
           '; INCLUDEs this defines SOUND_RAM and the table labels used below.',
           ]
    out += r['lines']
    return '\n'.join(out) + '\n', r


if __name__ == '__main__':
    v, k = sys.argv[1], sys.argv[2]
    print(render(v, k)[0])
