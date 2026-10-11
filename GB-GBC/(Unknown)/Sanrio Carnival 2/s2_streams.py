"""Static walkers for the Sanrio Carnival 2 music and SFX streams (bank 1).

Music byte roles: 'note' (<$80), 'len' (packed length byte read when the note repeat counter runs out),
'cmd' ($80-$9F) and 'op' (operand). The packed length byte belongs to the note before it is read, so a
note's length byte depends on the counter state: the walker follows every channel from its song start
through jumps, calls and returns with the counter, and checks that each byte gets one role."""

# operand count per command $80-$9F (None = no handler)
OPS = {0x80: 2, 0x81: 1, 0x82: 1, 0x8f: 2, 0x93: 2}
for c in range(0x83, 0x8f): OPS[c] = 1
for c in range(0x94, 0x98): OPS[c] = 2
for c in range(0x98, 0xa0): OPS[c] = 0
SONG_TABLE, NSONGS = 0x6db2, 16


class Conflict(Exception): pass


class MusicWalk:
    def __init__(self, rom):
        self.rom = rom
        self.role = {}          # addr -> role
        self.targets = {}       # addr -> set of kinds ('song', 'jump', 'call')
        self.refs = {}          # cmd addr -> target
        self.operands = {}      # cmd -> set of operand values
        self.chan_of = {}       # addr -> set of channels
        self.songs = []
        self.owner = {}         # addr -> (song, ch) that reaches it first

    def b(self, a): return self.rom[a]

    def setrole(self, a, r):
        o = self.role.get(a)
        if o and o != r: raise Conflict(f'${a:04X}: {o} vs {r}')
        self.role[a] = r

    def walk(self, start, ch, tag=None):
        seen = set()
        todo = [(start, 1, ())]
        while todo:
            pc, cnt, stack = todo.pop()
            while True:
                key = (pc, cnt, stack)
                if key in seen: break
                seen.add(key)
                self.chan_of.setdefault(pc, set()).add(ch)
                self.owner.setdefault(pc, tag)
                c = self.b(pc)
                if c < 0x80:
                    self.setrole(pc, 'note'); pc += 1
                    cnt -= 1
                    if cnt == 0:
                        self.setrole(pc, 'len'); cnt = (self.b(pc) & 15) + 1; pc += 1
                    continue
                if c not in OPS: raise Conflict(f'${pc:04X}: bad command ${c:02X}')
                self.setrole(pc, 'cmd')
                n = OPS[c]
                for i in range(n): self.setrole(pc + 1 + i, 'op')
                if n == 1: self.operands.setdefault(c, set()).add(self.b(pc + 1))
                if n == 2:
                    v = self.b(pc + 1) | self.b(pc + 2) << 8
                    self.operands.setdefault(c, set()).add(v)
                    self.refs[pc] = v
                if c == 0x93:
                    self.targets.setdefault(v, set()).add('jump'); pc = v; continue
                if 0x94 <= c <= 0x97:
                    self.targets.setdefault(v, set()).add('call')
                    stack = stack + (pc + 3,); pc = v; continue
                if 0x98 <= c <= 0x9b:
                    pc = stack[-1]; stack = stack[:-1]; continue
                if c >= 0x9c: break
                pc += 1 + n

    def run(self):
        for s in range(NSONGS):
            ptrs = [self.b(SONG_TABLE + 8*s + 2*i) | self.b(SONG_TABLE + 8*s + 2*i + 1) << 8 for i in range(4)]
            self.songs.append(ptrs)
            for ch, p in enumerate(ptrs):
                if p >> 8:
                    self.targets.setdefault(p, set()).add('song')
                    self.walk(p, ch, (s, ch))
        return self


def sfx_tables(rom):
    out = []
    for t in (0x6a99, 0x6aa9, 0x6ab9, 0x6ac9):
        out.append([rom[t + 2*i] | rom[t + 2*i + 1] << 8 for i in range(8)])
    return out


def sfx_parse(rom, start):
    """-> list of (addr, kind, bytes); kinds: mask, regs, music, end, chmask, wait"""
    out = [(start, 'mask', [rom[start]])]
    pc = start + 1
    while True:
        c = rom[pc]
        if c < 0x40:
            n = (c & 1) + (c >> 1 & 1) + (c >> 2 & 1) + 2 * (c >> 3 & 1)
            out.append((pc, 'regs', list(rom[pc:pc + 1 + n]))); pc += 1 + n
        elif c < 0x60: out.append((pc, 'music', [c])); pc += 1
        elif c < 0x70: out.append((pc, 'end', [c])); return out
        elif c < 0x80: out.append((pc, 'chmask', [c])); pc += 1
        else: out.append((pc, 'wait', [c])); pc += 1


if __name__ == '__main__':
    import sys
    rom = open(sys.argv[1], 'rb').read()
    m = MusicWalk(rom).run()
    lo, hi = min(m.role), max(m.role)
    print('music bytes', hex(lo), hex(hi), len(m.role))
    for c in sorted(m.operands): print(hex(c), sorted(hex(x) for x in m.operands[c]))
    gaps = []; a = lo
    while a <= hi:
        if a not in m.role:
            b = a
            while b <= hi and b not in m.role: b += 1
            gaps.append((hex(a), b - a)); a = b
        else: a += 1
    print('gaps', gaps)
    for t, tab in enumerate(sfx_tables(rom)):
        for i, s in enumerate(tab):
            p = sfx_parse(rom, s)
            print(t, i, hex(s), hex(p[-1][0] + len(p[-1][2])), ' '.join(k for _, k, _ in p)[:100])
