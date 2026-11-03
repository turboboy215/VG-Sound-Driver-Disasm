"""Engine A (Noobow / Pocket Bowling) track walker."""
# arg counts for $E0-$FF; None = ends track
def cmd_table(ver):
    t = {}
    END = None
    names = {
        0xE0: ('sA_end', 0, 'end'), 0xE1: ('sA_sweep', 1, ''), 0xE2: ('sA_inst', 1, ''),
        0xE3: ('sA_duty', 1, ''), 0xE4: ('sA_vibrato', 1, ''), 0xE5: ('sA_env', 1, ''),
        0xE6: ('sA_tempo', 1, ''), 0xE7: ('sA_tempodelta_neg', 2, ''), 0xE8: ('sA_tempodelta', 2, ''),
        0xEB: ('sA_pan', 1, ''), 0xEE: ('sA_call', 2, 'call'), 0xEF: ('sA_ret', 0, 'ret'),
        0xF0: ('sA_loop', 4, 'loop'), 0xF1: ('sA_jump', 2, 'jump'), 0xF2: ('sA_mastervol', 1, ''),
        0xF3: ('sA_tie', 0, ''), 0xF4: ('sA_rawnote', 0, 'raw'), 0xF5: ('sA_slur', 0, ''),
    }
    if ver >= 2:
        names[0xFE] = ('sA_length', 1, '')
    return names

def walk(rom, bank, starts, ver):
    """starts: list of (addr, chan_hint). returns dict addr->(size, kind, info), set of labels"""
    base = bank * 0x4000 - 0x4000
    def rb(a): return rom[base + a]
    cmds = cmd_table(ver)
    items = {}
    labels = {}
    todo = list(starts)
    seen = set()
    while todo:
        a, ch = todo.pop()
        if (a, ch) in seen or a in items and items[a][1] != 'note' and False:
            continue
        seen.add((a, ch))
        if not (0x4000 <= a < 0x8000):
            continue
        while True:
            if a in items:
                break
            b = rb(a)
            if b < 0xA0:
                items[a] = (1, 'note', (b, ch))
                a += 1
            elif b < 0xB0:
                items[a] = (1, 'len', b & 0xF)
                a += 1
            elif b < 0xE0:
                items[a] = (1, 'endbad', b)
                break
            else:
                c = cmds.get(b)
                if c is None:
                    items[a] = (1, 'end', b)
                    break
                name, n, kind = c
                args = [rb(a + 1 + i) for i in range(n)]
                items[a] = (1 + n, 'cmd', (b, name, args, kind))
                if kind == 'end':
                    break
                if kind == 'ret':
                    break
                if kind in ('call', 'jump'):
                    t = args[0] | args[1] << 8
                    labels.setdefault(t, set()).add(kind)
                    todo.append((t, ch))
                    if kind == 'jump':
                        break
                if kind == 'loop':
                    t = args[2] | args[3] << 8
                    labels.setdefault(t, set()).add('loop')
                    todo.append((t, ch))
                if kind == 'raw':
                    # next byte is a raw note value, followed optionally by length
                    items[a + 1] = (1, 'rawnote', (rb(a + 1), ch))
                    a += 2
                    continue
                a += 1 + n
    return items, labels
