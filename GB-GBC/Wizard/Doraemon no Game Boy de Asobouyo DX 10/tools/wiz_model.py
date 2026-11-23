"""Python model of the Wizard sound driver, written from Wizard_SoundDriver.md.
RAM is modelled as a flat dict of absolute WRAM addresses so stack overruns behave like the real thing."""
import sys
sys.path.insert(0, __file__.rsplit('/', 1)[0])
from wiz_cfg import GAMES

NOPITCH = False  # True disables pitch envelopes (sanity check for the PyBoy test)
SZ = 0x22
F_PTR, F_LEN, F_GATE, F_VOL, F_DUTY, F_FLAGS, F_PER, F_SP, F_STACK, F_RET = 0, 2, 4, 6, 9, 0x0A, 0x0B, 0x0D, 0x0F, 0x18
F_VPOS, F_VENV, F_PPOS, F_PENV, F_VOFS = 0x1B, 0x1C, 0x1E, 0x1F, 0x21
NRX2 = [0x12, 0x17, 0x1C, 0x21] * 2


def swap(a):
    return ((a << 4) | (a >> 4)) & 0xFF


class Model:
    def __init__(self, key, rom, game_flag=0):
        self.c = c = GAMES[key]
        self.rom = rom
        self.v2 = c['version'] == 2
        self.game_flag = game_flag
        self.B = c['wram']
        self.TR = self.B + 0x14
        self.ram = {a: 0 for a in range(self.B, self.TR + 8 * SZ)}
        self.reg = {}            # last written value per register (low byte of $FFxx)
        self.ch_on = [False] * 4  # NR52 status bits
        self.wave = [0] * 16

    # --- memory helpers ---
    def r4(self, a): return self.rom[c4(a, self.c)]
    def w4(self, a): return self.r4(a) | self.r4(a + 1) << 8
    def r0(self, a): return self.rom[a] if a < 0x4000 else self.r4(a)
    def w0(self, a): return self.r0(a) | self.r0(a + 1) << 8

    def g(self, a): return self.ram[a]
    def s(self, a, v): self.ram[a] = v & 0xFF
    def gw(self, a): return self.ram[a] | self.ram[a + 1] << 8
    def sw(self, a, v): self.ram[a] = v & 0xFF; self.ram[a + 1] = (v >> 8) & 0xFF

    def st(self, i): return self.TR + i * SZ
    V = property(lambda self: {k: self.B + o for k, o in dict(pause=0, pan=1, mvol=9, fade=10, rate=11, cnt=12,
                                                                  idx=15, last=16, note=17, raw=18, act=19).items()})

    def wr(self, r, v):
        v &= 0xFF
        self.reg[r] = v
        hw = {0x14: 0, 0x19: 1, 0x1E: 2, 0x23: 3}.get(r)
        if hw is not None and v & 0x80:
            dac = (self.reg.get(0x1A, 0) & 0x80) if hw == 2 else (self.reg.get(NRX2[hw], 0) & 0xF8)
            self.ch_on[hw] = bool(dac)
        if r in (0x12, 0x17, 0x21) and not v & 0xF8:
            self.ch_on[{0x12: 0, 0x17: 1, 0x21: 3}[r]] = False
        if r == 0x1A and not v & 0x80:
            self.ch_on[2] = False

    def rd(self, r):
        if r == 0x26:
            return 0x80 | sum(1 << i for i in range(4) if self.ch_on[i])
        if r == 0x1C:
            return 0x9F | (self.reg.get(0x1C, 0) & 0x60)
        return self.reg.get(r, 0)

    # --- entry points ---
    def init(self):
        V = self.V
        self.wr(0x26, 0x80); self.wr(0x25, 0)
        self.s(V['mvol'], 0x77); self.wr(0x24, 0x77)
        self.wr(0x1A, self.rd(0x1A) | 0x80)
        self.s(V['act'], 0)
        for i in range(8):
            self.s(self.st(i) + F_FLAGS, 0)
        a = 0x11
        for i in range(4):
            self.s(V['pan'] + i, a); self.s(V['pan'] + 4 + i, a); a = (a << 1) & 0xFF

    def pause(self): self.s(self.V['pause'], 1)
    def resume(self): self.s(self.V['pause'], 0)

    def fade(self, a):
        V = self.V
        self.s(V['rate'], a); self.s(V['fade'], 1); self.s(V['cnt'], 0)

    def set_volofs(self, a, b):
        for i in range(8):
            if b >> i & 1:
                self.s(self.st(i) + F_VOFS, a)

    def stop(self, keep=0):
        V = self.V
        c = self.g(V['act']) & keep
        self.s(V['act'], c)
        c = keep
        e = 0xEE
        for hw in range(4):
            if not (c & 1) or not (c & 0x10):
                self.wr(0x25, self.rd(0x25) & e)
            c >>= 1
            e = ((e << 1) | (e >> 7)) & 0xFF
        self.s(V['fade'], 0)
        self.s(V['mvol'], 0x77); self.wr(0x24, 0x77)

    def play(self, sid):
        V = self.V
        hdr = self.w4(self.c['sndtab'] + 2 * sid)
        mask = self.r4(hdr)
        self.s(V['last'], mask)
        if self.v2:
            if not mask & 0xF0:
                if self.game_flag:
                    return
                self.wr(0x25, 0)
        elif not mask & 0x80:
            self.wr(0x25, 0)
        q = hdr + 1
        for i in range(8):
            if mask >> i & 1:
                self.init_track(i, self.w4(q)); q += 2
        if mask & 0xF0:
            self.s(V['act'], self.g(V['act']) | mask)
        else:
            self.s(V['act'], mask)

    def init_track(self, i, t):
        b = self.st(i)
        self.sw(b + F_PTR, t)
        self.sw(b + F_LEN, 1); self.sw(b + F_GATE, 1)
        for o in range(6, 10): self.s(b + o, 0)
        self.s(b + F_FLAGS, 6)
        self.sw(b + F_SP, b + F_STACK)
        for o in range(0x1B, 0x21): self.s(b + o, 0)

    # --- per frame ---
    def update(self):
        V = self.V
        if self.g(V['fade']) == 1:
            cnt = (self.g(V['cnt']) + 1) & 0xFF
            self.s(V['cnt'], cnt)
            if cnt >= self.g(V['rate']):
                self.s(V['cnt'], 0)
                mv = self.g(V['mvol'])
                d = mv & 7
                if d: d -= 1
                e = mv & 0x70
                if e: e -= 0x10
                mv = e | d | (mv & 0x88)
                self.s(V['mvol'], mv); self.wr(0x24, mv)
        self.s(V['idx'], 0)
        c = self.g(V['act'])
        for i in range(8):
            if c >> i & 1:
                if i >= 4 or not (self.g(V['pause']) & 1):
                    self.tick(i)
            self.s(V['idx'], i + 1)
        b = self.g(V['act'])
        for i in range(8):
            self.output(i, b >> i)

    def tick(self, i):
        b = self.st(i)
        gate = self.gw(b + F_GATE)
        if gate:
            gate -= 1
            self.sw(b + F_GATE, gate)
            if gate:
                self.s(b + F_VPOS, self.g(b + F_VPOS) + 1)
                self.s(b + F_PPOS, self.g(b + F_PPOS) + 1)
            else:
                f = self.g(b + F_FLAGS)
                self.s(b + F_FLAGS, (f & ~1) | 8)
                self.s(b + F_VPOS, 0); self.s(b + F_PPOS, 0)
        ln = self.gw(b + F_LEN)
        if ln:
            ln -= 1
            self.sw(b + F_LEN, ln)
            if ln:
                return
        self.read(i)

    def read(self, i):
        V = self.V
        b = self.st(i)
        while True:
            p = self.gw(b + F_PTR)
            a = self.r4(p)
            if a >= 0x80:
                if not self.command(i, b, p, a):
                    return
                continue
            if a == 0x7D:
                p += 1; a = self.r4(p)
            self.s(V['note'], a)
            L = self.r4(p + 1)
            G = self.r4(p + 2)
            p += 2
            self.sw(b + F_PTR, p)
            self.s(b + F_LEN, L)
            self.s(b + F_GATE, L + 1 if G == 0x7E else L)
            note = a
            if self.g(V['raw']) == 0x7D:
                self.sw(b + F_PER, note)
            elif note == 0x7E:
                return
            elif note == 0x7F:
                self.s(b + F_FLAGS, (self.g(b + F_FLAGS) | 8) & ~1)
                return
            elif self.g(V['idx']) == 3:
                self.sw(b + F_PER, note)
            else:
                self.sw(b + F_PER, self.w4(self.c['freq'] + 2 * note))
            self.s(b + F_FLAGS, self.g(b + F_FLAGS) | 5)
            return

    def command(self, i, b, p, a):
        V = self.V
        c = self.c
        idx = self.g(V['idx'])
        arg = self.r4(p + 1)
        if a == 0x80:
            self.s(b + F_FLAGS, self.g(b + F_FLAGS) & ~9)
            self.wr(0x25, self.rd(0x25) & self.r4(c['nr51clr'] + idx))
            self.s(V['act'], self.g(V['act']) & self.r4(c['actclr'] + idx))
            return False
        if a == 0x81:
            self.sw(b, p + 2)
            self.s(b + F_VOL, swap(arg) | (self.g(b + F_VOL) & 0x0F))
        elif a == 0x82:
            self.sw(b, p + 2)
            sp = self.gw(b + F_SP)
            self.s(sp, arg); self.s(sp + 1, (p + 2) & 0xFF); self.s(sp + 2, (p + 2) >> 8)
            self.sw(b + F_SP, sp + 3)
        elif a == 0x83:
            self.sw(b, p + 1)
            de = (self.gw(b + F_SP) - 3) & 0xFFFF
            n = (self.g(de) - 1) & 0xFF
            self.s(de, n)
            if n:
                self.sw(b, self.gw(de + 1))
            else:
                self.sw(b + F_SP, de)
        elif a == 0x84:
            self.sw(b, p + 2)
            w = self.w0(c['wavetab'] + 2 * arg)
            if self.rd(0x26) & 4:
                self.wr(0x25, self.rd(0x25) & 0xBB)
                self.wr(0x1C, 0)
            self.wave = [self.r0(w + k) for k in range(16)]
            self.wr(0x1C, (self.rd(0x1C) & 0x9F) | 0x20)
        elif a == 0x85:
            self.sw(b, self.w4(p + 1))
        elif a == 0x86:
            self.sw(b, self.w4(p + 1))
            self.sw(b + F_RET, p + 3)
        elif a == 0x87:
            self.sw(b, self.gw(b + F_RET))
        elif a == 0x88:
            self.sw(b, p + 2)
            self.s(b + F_VPOS, 0); self.sw(b + F_VENV, self.w0(c['envtab'] + 2 * arg))
        elif a == 0x89:
            self.sw(b, p + 2)
            self.s(b + F_PPOS, 0); self.sw(b + F_PENV, self.w0(c['pitchtab'] + 2 * arg))
        elif a in (0x8A, 0x8B, 0x8C):
            self.sw(b, p + 1)
            v = self.r4(c['pantab'] + idx)
            v &= {0x8A: 0xF0, 0x8B: 0x0F, 0x8C: 0xFF}[a]
            self.s(V['pan'] + idx, v)
        elif 0x8D <= a <= 0x8F:
            self.sw(b, p + 1)
        elif 0x90 <= a <= 0x93:
            self.sw(b, p + 1)
            self.s(b + F_DUTY, (swap(a) << 2) & 0xC0)
        else:
            raise ValueError(f'command {a:02X} at {p:04X}')
        return True

    def level(self, b):
        v = ((self.g(b + F_VOL) >> 4) + self.g(b + F_VOFS)) & 0xFF
        if v >= 0x10:
            v = 0 if v >= 0xF0 else 0x0F
        return v

    def output(self, i, bm):
        V = self.V
        c = self.c
        if i < 4:
            if self.g(V['pause']):
                return
            if bm & 0x10:
                return
        if not bm & 1:
            return
        b = self.st(i)
        hw = i & 3
        r2 = NRX2[i]
        f = self.g(b + F_FLAGS)
        if not f & 1:
            if f & 8:
                self.s(b + F_FLAGS, f & ~8)
                self.wr(0x25, self.rd(0x25) & self.r4(c['nr51clr'] + i))
            return
        # pitch envelope
        while self.g(b + F_PENV + 1) and not NOPITCH:
            pos = self.g(b + F_PPOS)
            v = self.r0((self.gw(b + F_PENV) + pos) & 0xFFFF)
            if v == 0x81:
                self.s(b + F_PPOS, 0); continue
            if v == 0x80:
                self.s(b + F_PPOS, pos - 1); continue
            per = self.gw(b + F_PER)
            new = (per + (v - 256 if v & 0x80 else v)) & 0xFFFF
            self.sw(b + F_PER, new)
            self.wr(r2 + 1, new & 0xFF)
            self.wr(r2 + 2, (per >> 8 if v & 0x80 else new >> 8) & 7)
            break
        # volume envelope
        while True:
            if not self.g(b + F_VENV + 1):
                return self.output_noenv(i, b, hw, r2)
            pos = self.g(b + F_VPOS)
            v = self.r0((self.gw(b + F_VENV) + pos) & 0xFFFF)
            if v == 0x80:
                self.s(b + F_VPOS, pos - 1); continue
            if v == 0x81:
                self.s(b + F_VPOS, 0); continue
            break
        lev = self.r4(c['voltab'] + 16 * self.level(b) + v)
        self.wr(0x25, self.rd(0x25) | self.g(V['pan'] + i))
        if r2 == 0x1C:
            self.wr(r2, self.r4(c['wavevol'] + (lev & 0x0F)))
        else:
            self.wr(r2, swap(lev))
        if r2 - 1 < 0x1A:
            self.wr(r2 - 1, self.g(b + F_DUTY))
        self.s(b + F_FLAGS, self.g(b + F_FLAGS) & ~8)
        per = self.gw(b + F_PER)
        self.wr(r2 + 1, per & 0xFF)
        if hw >= 2 and self.ch_on[hw]:
            self.wr(r2 + 2, per >> 8)
        else:
            self.wr(r2 + 2, (per >> 8) | 0x80)

    def output_noenv(self, i, b, hw, r2):
        V = self.V
        self.s(b + F_FLAGS, self.g(b + F_FLAGS) & ~9)
        if r2 - 1 < 0x1A:
            self.wr(r2 - 1, self.g(b + F_DUTY))
        self.wr(0x25, self.rd(0x25) | self.g(V['pan'] + i))
        lv = self.level(b)
        if r2 == 0x1C:
            self.wr(r2, self.r4(self.c['wavevol'] + lv))
        else:
            self.wr(r2, swap(lv))
        per = self.gw(b + F_PER)
        self.wr(r2 + 1, per & 0xFF)
        self.wr(r2 + 2, (per >> 8) | 0x80)


def c4(a, cfg):
    return cfg['bank'] * 0x4000 + a - 0x4000
