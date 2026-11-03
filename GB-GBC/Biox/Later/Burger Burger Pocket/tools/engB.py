"""Engine B (Burger Burger Pocket = v1, Daiku no Gensan = v2) track walker."""

def spec(ver):
    if ver == 2:
        return dict(lenmax=0x80, notebase=0x80, notemax=0xD4, drumbase=0xD4, drummax=0xE4,
                    cmds={0xE4: ('snd_noise', 3, ''), 0xE5: ('snd_hold', 1, ''), 0xE6: ('snd_off', 0, ''),
                          0xE7: ('snd_end', 0, 'end'), 0xE8: ('snd_jump', 2, 'jump'), 0xE9: ('snd_call', 2, 'call'),
                          0xEA: ('snd_ret', 0, 'ret'), 0xEB: ('snd_loop', 1, ''), 0xEC: ('snd_endloop', 0, ''),
                          0xED: ('snd_tempo', 1, ''), 0xEE: ('snd_env', 1, ''), 0xEF: ('snd_pitchenv', 2, 'penv'),
                          0xF0: ('snd_nop', 0, ''), 0xF1: ('snd_duty', 1, ''), 0xF2: ('snd_pan', 1, ''),
                          0xF3: ('snd_transpose', 1, ''), 0xF4: ('snd_vol', 1, ''), 0xF5: ('snd_envlo', 1, ''),
                          0xF6: ('snd_octenv', 2, 'oenv'), 0xF7: ('snd_wave', 2, 'wave'), 0xF8: ('snd_wave_restore', 0, ''),
                          0xF9: ('snd_env2', 1, ''), 0xFA: ('snd_ch3len', 1, '')})
    return dict(lenmax=0x32, notebase=0x32, notemax=0x90, drumbase=0x90, drummax=0xED,
                cmds={0xED: ('snd_noise', 3, ''), 0xEE: ('snd_hold', 1, ''), 0xEF: ('snd_off', 0, ''),
                      0xF0: ('snd_end', 0, 'end'), 0xF1: ('snd_jump', 2, 'jump'), 0xF2: ('snd_call', 2, 'call'),
                      0xF3: ('snd_ret', 0, 'ret'), 0xF4: ('snd_loop', 1, ''), 0xF5: ('snd_endloop', 0, ''),
                      0xF6: ('snd_tempo', 1, ''), 0xF7: ('snd_env', 1, ''), 0xF8: ('snd_pitchenv', 2, 'penv'),
                      0xF9: ('snd_nop', 0, ''), 0xFA: ('snd_duty', 1, ''), 0xFB: ('snd_pan', 1, ''),
                      0xFC: ('snd_transpose', 1, '')})

def walk(rb, starts, ver, lo=0x4000, hi=0x8000):
    sp = spec(ver)
    items = {}; labels = {}; penvs = set(); waves = set()
    todo = list(starts)
    while todo:
        a, ch = todo.pop()
        if not (lo <= a < hi): continue
        while a not in items:
            b = rb(a)
            if b < sp['lenmax']:
                items[a] = (1, 'len', b, ch); a += 1
            elif b < sp['notemax']:
                items[a] = (1, 'note', b - sp['notebase'], ch); a += 1
            elif b < sp['drummax']:
                items[a] = (1, 'drum', b - sp['drumbase'], ch); a += 1
            elif b in sp['cmds']:
                name, n, kind = sp['cmds'][b]
                args = [rb(a + 1 + i) for i in range(n)]
                items[a] = (1 + n, 'cmd', (b, name, args, kind), ch)
                if kind in ('end', 'ret'):
                    break
                if kind in ('jump', 'call'):
                    t = args[0] | args[1] << 8
                    labels.setdefault(t, set()).add(kind); todo.append((t, ch))
                    if kind == 'jump': break
                if kind in ('penv', 'oenv'):
                    t = args[0] | args[1] << 8
                    if t: penvs.add((t, kind))
                if kind == 'wave':
                    waves.add(args[0] | args[1] << 8)
                a += 1 + n
            else:
                items[a] = (1, 'bad', b, ch)
                break
    return items, labels, penvs, waves

def walk_penv(rb, starts):
    """pitch/octave envelope byte streams: $80 stop, $81 ptr jump, else data byte."""
    items = {}; labels = set()
    todo = [s for s in starts]
    while todo:
        a = todo.pop()
        while a not in items:
            b = rb(a)
            if b == 0x80:
                items[a] = (1, 'stop', None); break
            if b == 0x81:
                t = rb(a + 1) | rb(a + 2) << 8
                items[a] = (3, 'jump', t); labels.add(t); todo.append(t); break
            items[a] = (1, 'val', b); a += 1
    return items, labels
