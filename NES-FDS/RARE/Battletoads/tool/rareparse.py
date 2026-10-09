"""Parsers for Rare NES sound engine data (Battletoads / BT&DD)."""

# kind codes: end, jump, call, ret, rcall (repeat-call), rend (repeat end),
# fixdur (sets fixed duration), fixoff, volon (per-note volume byte), voloff, plain
BT_CMDS = {
 0x00: ('END', 0, 'end'),
 0x01: ('JUMP', 2, 'jump'),
 0x02: ('SFX_CLRFLAG', 0, 'plain'),
 0x03: ('INSTR', 3, 'plain'),
 0x04: ('HOLD', 0, 'plain'),
 0x05: ('REPEAT_END', 0, 'rend'),
 0x06: ('FIXDUR', 1, 'fixdur'),
 0x07: ('FIXDUR_OFF', 0, 'fixoff'),
 0x08: ('VIBRATO', 3, 'plain'),
 0x09: ('VIBRATO_OFF', 0, 'plain'),
 0x0A: ('SLIDE_UP', 5, 'plain'),
 0x0B: ('SLIDE_DOWN', 5, 'plain'),
 0x0C: ('VOLUME', 1, 'plain'),
 0x0D: ('VOL_ENV', 3, 'plain'),
 0x0E: ('TREMOLO', 3, 'plain'),
 0x0F: ('VOL_ENV_OFF', 0, 'plain'),
 0x10: ('TEMPO', 1, 'plain'),
 0x11: ('TEMPO_ADD', 1, 'plain'),
 0x12: ('TRANSPOSE', 1, 'plain'),
 0x13: ('TRANSPOSE_ADD', 1, 'plain'),
 0x14: ('TRANSPOSE_ALL', 1, 'plain'),
 0x15: ('ATTACK_OFF', 0, 'plain'),
 0x16: ('ATTACK_ENV', 3, 'plain'),
 0x17: ('VIBRATO_DLY', 4, 'plain'),
 0x18: ('PCM_TONE', 1, 'plain'),
 0x19: ('PCM_NOISE', 1, 'plain'),
 0x1A: ('PCM_WAVE_A', 1, 'plain'),
 0x1B: ('PCM_WAVE_B', 1, 'plain'),
 0x1C: ('PCM_SETUP', 3, 'plain'),
 0x1D: ('PCM_WAVE_C', 1, 'plain'),
 0x1E: ('REPEAT_CALL', 3, 'rcall'),
 0x1F: ('ECHO', 2, 'echo'),
 0x20: ('ECHO_OFF', 0, 'voloff'),
 0x21: ('FIXDUR_ECHO_OFF', 0, 'fixvoloff'),
 0x22: ('NOTEVOL_ON', 0, 'volon'),
 0x23: ('CALL_A', 2, 'call'),
 0x24: ('CALL_B', 2, 'call'),
 0x25: ('RET_A', 0, 'ret'),
 0x26: ('RET_B', 0, 'ret'),
}

DD_CMDS = {
 0x00: ('END', 0, 'end'),
 0x01: ('JUMP', 2, 'jump'),
 0x02: ('SFX_CLRFLAG', 0, 'plain'),
 0x03: ('INSTR', 3, 'plain'),
 0x04: ('HOLD', 0, 'plain'),
 0x05: ('REPEAT_END', 0, 'rend'),
 0x06: ('FIXDUR', 1, 'fixdur'),
 0x07: ('FIXDUR_OFF', 0, 'fixoff'),
 0x08: ('VIBRATO', 3, 'plain'),
 0x09: ('VIBRATO_OFF', 0, 'plain'),
 0x0A: ('SLIDE_UP', 5, 'plain'),
 0x0B: ('SLIDE_DOWN', 5, 'plain'),
 0x0C: ('VOLUME_BAD', 0, 'plain'),
 0x0D: ('ENV_PRESET', 1, 'plain'),
 0x0E: ('TREMOLO', 3, 'plain'),
 0x0F: ('VOL_ENV_OFF', 0, 'plain'),
 0x10: ('TEMPO', 1, 'plain'),
 0x11: ('TEMPO_ADD', 1, 'plain'),
 0x12: ('TRANSPOSE', 1, 'plain'),
 0x13: ('TRANSPOSE_ADD', 1, 'plain'),
 0x14: ('TRANSPOSE_ALL', 1, 'plain'),
 0x15: ('ATTACK_OFF', 0, 'plain'),
 0x16: ('ATTACK_PRESET', 1, 'plain'),
 0x17: ('VIBRATO_DLY', 4, 'plain'),
 0x18: ('PCM_TONE', 1, 'plain'),
 0x19: ('PCM_NOISE', 1, 'plain'),
 0x1A: ('PCM_WAVE_A', 1, 'plain'),
 0x1B: ('PCM_WAVE_B', 1, 'plain'),
 0x1C: ('PCM_SETUP', 3, 'plain'),
 0x1D: ('PCM_WAVE_C', 1, 'plain'),
 0x1E: ('REPEAT_CALL', 3, 'rcall'),
 0x1F: ('CALL', 2, 'call'),
 0x20: ('RET', 0, 'ret'),
 0x21: ('ECHO', 2, 'plain'),
 0x22: ('ECHO_OFF', 0, 'plain'),
 0x23: ('FIXDUR_ECHO_OFF', 0, 'fixoff'),
 0x24: ('ECHO_TOGGLE', 0, 'plain'),
}
for c in range(0x25, 0x34): DD_CMDS[c] = ('ATTACK_P%X' % (c - 0x25), 0, 'plain')
for c in range(0x34, 0x44): DD_CMDS[c] = ('VOL_%X' % (c - 0x34), 0, 'plain')
for c in range(0x44, 0x4D): DD_CMDS[c] = ('HWLEN_%X' % (c - 0x44), 0, 'plain')
for c in range(0x4D, 0x54): DD_CMDS[c] = ('HWLEN_INSTR_%X' % (c - 0x44), 1, 'plain')

NOTE_NAMES = ['C', 'CS', 'D', 'DS', 'E', 'F', 'FS', 'G', 'GS', 'A', 'AS', 'B']
def note_name(b):
    if b == 0x80: return 'REST'
    n = b - 0x81
    return 'N_%s%d' % (NOTE_NAMES[n % 12], 2 + n // 12)

class TrackParser:
    """Walk track data like the engine does; record the role of every byte."""
    def __init__(self, mem, base, cmds, game):
        self.mem, self.base, self.cmds, self.game = mem, base, cmds, game
        self.ev = {}        # addr -> (kind, size, info)
        self.targets = {}   # addr -> set(kinds) (jump/call targets)
        self.conflicts = []
        self.chan = {}      # addr -> set of channel numbers that execute it
        self.errors = []
    def b(self, a): return self.mem[a - self.base]
    def w(self, a): return self.b(a) | self.b(a + 1) << 8
    def add(self, a, kind, size, info, state):
        old = self.ev.get(a)
        if old and (old[0], old[1]) != (kind, size):
            self.conflicts.append((a, old, (kind, size, info)))
        self.ev[a] = (kind, size, info)
        self.chan.setdefault(a, set()).add(self.curchan)
    def walk(self, start, label, fixdur=0, volmode=0, chan=None):
        self.curchan = chan
        # state: (pc, fixdur, volmode, callstack(tuple), repstack(tuple))
        seen = set()
        todo = [(start, fixdur, volmode, (), ())]
        self.targets.setdefault(start, set()).add(label)
        steps = 0
        while todo:
            pc, fd, vm, cs, rs = todo.pop()
            while True:
                steps += 1
                if steps > 200000: self.errors.append(('runaway', start)); return
                key = (pc, fd, vm, cs, rs)
                if key in seen: break
                seen.add(key)
                op = self.b(pc)
                if op >= 0x80:
                    n = 1 + (1 if vm else 0) + (0 if fd else 1)
                    self.add(pc, 'note', n, (fd, vm), None)
                    pc += n
                    continue
                if op not in self.cmds:
                    self.errors.append(('badop', pc, op)); break
                name, np, kind = self.cmds[op]
                self.add(pc, 'cmd', 1 + np, name, None)
                nxt = pc + 1 + np
                if kind == 'end': break
                if kind == 'jump':
                    t = self.w(pc + 1); self.targets.setdefault(t, set()).add('jump')
                    pc = t; continue
                if kind == 'call':
                    t = self.w(pc + 1); self.targets.setdefault(t, set()).add('call')
                    cs = cs + (nxt,); pc = t; continue
                if kind == 'ret':
                    if not cs: self.errors.append(('ret-empty', pc)); break
                    pc = cs[-1]; cs = cs[:-1]; continue
                if kind == 'rcall':
                    t = self.w(pc + 2); self.targets.setdefault(t, set()).add('rcall')
                    rs = rs + (nxt,); pc = t; continue
                if kind == 'rend':
                    if not rs: self.errors.append(('rend-empty', pc)); break
                    pc = rs[-1]; rs = rs[:-1]; continue
                if kind == 'fixdur': fd = self.b(pc + 1)
                elif kind == 'fixoff': fd = 0
                elif kind == 'volon': vm = 1
                elif kind == 'voloff': vm = 0
                elif kind == 'fixvoloff': fd = 0; vm = 0
                elif kind == 'echo': vm = 1 if self.b(pc + 1) & 0x80 else 0
                pc = nxt

class SfxParser:
    def __init__(self, mem, base, cmds):
        self.mem, self.base, self.cmds = mem, base, cmds
        self.ev = {}
        self.errors = []
    def b(self, a): return self.mem[a - self.base]
    def walk(self, start):
        self.ev[start] = ('sfxhdr', 3, None)
        pc = start + 3
        while True:
            op = self.b(pc)
            if op == 0:
                self.ev[pc] = ('sfxend', 1, None); return
            if op >= 0x10:
                self.ev[pc] = ('sfxstep', 2, None); pc += 2; continue
            name, np, kind = self.cmds[op]
            self.ev[pc] = ('sfxcmd', 1 + np, name)
            if op not in (0x02, 0x04):
                self.errors.append(('sfx-unusual-cmd', pc, name))
                if kind == 'jump': return
            pc += 1 + np
