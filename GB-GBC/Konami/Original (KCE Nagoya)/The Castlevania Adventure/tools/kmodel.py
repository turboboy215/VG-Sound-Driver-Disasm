"""Behavioural model of the Konami early GB sound driver (Castlevania Adventure / Motocross Maniacs).
Written from the documented semantics, used to cross-check the emulator tick by tick.
Track state is kept in byte arrays laid out like the game's RAM so it can be compared directly."""
import kdata

F_CVA = dict(id=0, prio=1, ptr=2, len=4, flags=5, loop=6, vib=7, transp=8, atten=9, vofs=0xA,
             unit=0xC, oct=0xD, period=0xE, vol=0x10, duty=0x11, env=0x12, gate=0x13, rel=0x14,
             vtim=0x15, vrel=0x16, c3tim=0x17, c3rel=0x18, lvl=0x1A, segno=0x1B, ret=0x1D,
             vptr=0x1F, vidx=0x21, vlidx=0x22, vlcnt=0x23)
F_MM = dict(id=0, prio=1, ptr=2, len=4, flags=5, loop=6, vib=7, transp=8, atten=9, vofs=0xA,
            vlcnt=0xC, unit=0xD, oct=0xE, period=0xF, vol=0x11, duty=0x12, env=0x13, gate=0x14,
            rel=0x15, vtim=0x16, vrel=0x17, c3tim=0x18, c3rel=0x19, lvl=0x1B, segno=0x1C, ret=0x1E,
            vptr=0x20, vidx=0x22, vlidx=0x23)
WORD = {'ptr', 'vofs', 'period', 'segno', 'ret', 'vptr'}


class Track:
    def __init__(self, fmap, size=0x25):
        self.f = fmap; self.m = bytearray(size)
    def __getattr__(self, k):
        if k in ('f', 'm'): raise AttributeError
        o = self.f[k]
        return self.m[o] | (self.m[o + 1] << 8) if k in WORD else self.m[o]
    def __setattr__(self, k, v):
        if k in ('f', 'm'): return object.__setattr__(self, k, v)
        o = self.f[k]
        if k in WORD: self.m[o] = v & 0xFF; self.m[o + 1] = (v >> 8) & 0xFF
        else: self.m[o] = v & 0xFF


def swap(a): return ((a << 4) | (a >> 4)) & 0xFF


class Driver:
    def __init__(self, g):
        self.g = g; self.mm = g['name'] == 'mm'
        self.rom = kdata.Rom(g['rom'], g['bank'])
        self.n = g['ntr']
        self.t = [Track(F_MM if self.mm else F_CVA) for _ in range(self.n)]
        self.base = [0, 5, 0xF, 0, 5, 0xA, 0xF] if self.mm else [0, 0xF, 0, 5, 0xA, 0xF]
        self.mask = [0xEE, 0xDD, 0x77, 0xEE, 0xDD, 0xBB, 0xFF] if self.mm else [0xEE, 0x77, 0xEE, 0xDD, 0xBB, 0xFF]
        self.sh = bytearray(0x14)
        self.nr51 = 0; self.acc = 0; self.tempo = 0; self.skip = 0; self.parity = 0
        self.queue = 0
        self.hw = {}                    # last value written to each HW register
        self.wave = bytearray(16)
        self.trig = []                  # (tick, channel base) of every trigger
        self.tick_no = 0
        self.pause = 0; self.course = 1; self.engine = 0
        self.noise = g['noise']; self.drum = g['drum']; self.ch3 = g['ch3']
        self.sfx1, self.mus1 = (0, 3) if self.mm else (0, 2)
        self.cur = 0

    # ------------------------------------------------------------- register access
    def blocked(self):
        c = self.cur
        if self.mm:
            return (c == 3 and self.t[0].id) or (c == 4 and self.t[1].id)
        return c == 2 and self.t[0].id

    def write(self, reg, v, force_flags=None):
        if self.blocked(): return
        idx = self.base[self.cur] + reg
        fl = self.t[self.cur].flags if force_flags is None else force_flags
        if (fl & 0x40) or self.sh[idx] != v:
            self.sh[idx] = v; self.hwwrite(0xFF10 + idx, v)

    def hwwrite(self, a, v):
        self.hw[a] = v
        if 0xFF30 <= a < 0xFF40: self.wave[a - 0xFF30] = v

    def trigger(self):
        if self.blocked(): return
        idx = self.base[self.cur] + 4
        self.hwwrite(0xFF10 + idx, self.sh[idx] | 0x80)
        self.trig.append((self.tick_no, self.base[self.cur]))

    def b(self, a): return self.rom.b(a)
    def w(self, a): return self.rom.w(a)

    # ------------------------------------------------------------- update
    def update(self):
        self.tick_no += 1
        g = self.g
        self.skip = 0
        s = self.acc + self.tempo
        self.acc = s & 0xFF
        if s > 0xFF: self.skip = 1
        if self.mm:
            for c in range(7):
                self.cur = c
                if self.pause:
                    if c != 1: continue
                    if self.t[1].id != 8: break
                else:
                    if self.t[3].id == 9:
                        if c == 4 and self.skip: break
                    elif c == 3 and self.skip: break
                if self.t[c].id: self.track_tick(c)
            if self.queue:
                q = self.queue; self.queue = 0; self.play(q)
        else:
            for c in range(6):
                self.cur = c
                if self.pause:
                    if c != 0: continue
                    if self.t[0].id != 5: break
                elif c == 2:
                    self.parity = (self.parity + 1) & 0xFF
                    if not self.parity & 1: break
                    if self.skip: break
                if self.t[c].id: self.track_tick(c)

    def track_tick(self, c):
        T = self.t[c]
        T.len = T.len - 1
        if T.len == 0:
            T.flags = T.flags & (0x7E)
            if c == self.ch3:
                self.sh[0x0A] = 0; self.hwwrite(0xFF1A, 0)
            self.read_cmds(c)
            return
        if T.rel >= T.len: T.flags |= 1
        if T.flags & 0x80: return
        if c == self.noise or (self.mm and c == self.drum): return
        self.vib_tick(c)
        if c == self.ch3:
            self.ch3_decay(c); return
        if T.rel == T.len:
            v = 0 if T.env == 0 else (swap(((T.vol & 15) - T.atten) & 0xFF) | T.env)
            self.write(2, v); self.trigger()

    def ch3_decay(self, c):
        T = self.t[c]
        if not T.flags & 1: return
        if T.env == 0:
            self.write(2, 0); return
        T.c3tim = T.c3tim - 1
        if T.c3tim: return
        T.c3tim = T.c3rel
        a = T.lvl
        if a == 0: self.write(2, 0); return
        a = (a + 1) & 3; T.lvl = a
        if a == 0: self.write(2, 0); return
        a = (a + T.atten) & 0xFF
        if a < 4:   # carry from cp $04 is rotated into bit 0, then swap -> bit 4
            v = swap(((a << 1) | 1) & 0xFF)
        else:
            v = 0
        self.write(2, v)

    def vib_tick(self, c):
        T = self.t[c]
        if not T.vib: return
        T.vtim = T.vtim - 1
        if T.vtim: return
        T.vtim = T.vrel
        self.vib_step(c); self.write_period(c)

    def vib_step(self, c):
        T = self.t[c]
        while True:
            a = (T.vptr + T.vidx) & 0xFFFF
            v = self.b(a)
            if v == 0xFB:
                T.vidx = T.vidx + 1; T.vlidx = T.vidx; continue
            if v == 0xFE:
                n = self.b(a + 1)
                if n == T.vlcnt:
                    T.vlcnt = 0; T.vidx = T.vidx + 2; continue
                if n != 0xFF: T.vlcnt = T.vlcnt + 1
                T.vidx = T.vlidx; continue
            if v == 0xFF: return
            T.vtim = v >> 4; T.vrel = v >> 4
            if v & 8: T.flags |= 8
            T.vofs = ((v & 7) << 8) | self.b(a + 1)
            T.vidx = T.vidx + 2
            return

    def write_period(self, c):
        T = self.t[c]
        if self.mm and T.id == 9:
            T.vofs = (self.engine << 3) & 0xFFFF
        o = T.vofs
        if T.flags & 8: o = (-o) & 0xFFFF
        p = (T.period + o) & 0xFFFF
        self.write(3, p & 0xFF); self.write(4, p >> 8)

    def write_duty(self, c, duty):
        if self.base[c] == 0x0A:
            n = (duty - 1) & 0xFF
            if self.mm:
                p = self.w(0x6E8E + ((2 * n) & 0xFF))
            else:
                p = self.w(0x48DD + ((2 * n) & 0xFF))
            for i in range(16): self.hwwrite(0xFF30 + i, self.b(p + i))
        else:
            self.write(1, swap(duty))

    # ------------------------------------------------------------- command reader
    def read_cmds(self, c):
        T = self.t[c]; p = T.ptr
        while True:
            op = self.b(p)
            if op >= 0xFB:
                p += 1
                if op == 0xFB: T.segno = p
                elif op == 0xFC: p = T.ret
                elif op == 0xFD:
                    tg = self.w(p); p += 2; T.ret = p; p = tg
                elif op == 0xFE:
                    n = self.b(p)
                    if n == 0xFF: p = self.w(p + 1)
                    elif (T.loop + 1) & 0xFF == n: T.loop = 0; p += 1
                    else: T.loop = T.loop + 1; p = T.segno
                else:
                    self.end_track(c); return
                continue
            if op == 0xE0:
                p += 1; T.unit = self.b(p)
                if c == self.drum: p += 1; continue
                p += 1
                x = self.b(p)
                if c == self.noise:
                    T.env = x & 15; T.vol = x >> 4
                    self.write(2, x); self.trigger(); p += 1; continue
                T.vol = x & 15; T.duty = x >> 4; self.write_duty(c, T.duty)
                p += 1; x = self.b(p); T.env = x & 15; T.gate = x >> 4; p += 1; continue
            if (op & 0xF0) < 0xE0:
                T.ptr = p; self.note(c, op); return
            if (op & 0xF0) == 0xF0:
                T.atten = op & 15
                if c == self.noise:
                    v = swap(((T.vol & 15) - T.atten) & 0xFF)
                    if self.mm: T.lvl = v
                    self.write(2, v | T.env); self.trigger()
                p += 1; continue
            if op < 0xE7:
                T.oct = (op & 15) - 1; p += 1; continue
            p += 1; x = self.b(p)
            if op == 0xE7: T.unit = x
            elif op == 0xE8: T.env = x & 15; T.gate = x >> 4
            elif op == 0xE9: self.write(0, x)
            elif op == 0xEA:
                h, l = x >> 4, x & 15
                if h == 0: T.transp = l
                elif h == 1: T.transp = (-l) & 0xFF
                elif h == 2:
                    T.vib = l
                    T.vptr = self.w(self.g['vibtab'] + ((2 * ((l - 1) & 0xFF)) & 0xFF))
                    if self.mm: T.vlcnt = 0
                elif h == 3: T.duty = l; self.write_duty(c, l)
                elif h == 4:
                    if not self.mm:
                        T.flags = (T.flags | 2) if l else (T.flags & 0xFD)
                else: raise RuntimeError(f'EA {x:02X}')
            elif op == 0xEE: self.tempo = x
            elif op == 0xEF:
                skip = (c == self.mus1 and self.t[self.sfx1].id)
                if not skip:
                    m = self.mask[c]
                    self.nr51 = (self.nr51 & m) | (swap(x) & (~m & 0xFF))
                    self.hwwrite(0xFF25, self.nr51)
            p += 1

    def note(self, c, op):
        T = self.t[c]
        if not self.mm and T.flags & 2:
            m = self.mask[c]
            self.nr51 = ((~m & 0xFF) & swap(self.nr51)) | (self.nr51 & m)
            self.hwwrite(0xFF25, self.nr51)
        T.ptr = T.ptr + 1
        if c == self.noise:
            T.len = T.unit; self.write(3, op); self.write(4, 0); return
        n = op & 15
        T.len = (n * T.unit) & 0xFF
        if op & 0xF0 == 0:
            T.flags |= 0xC0; self.write(2, 0); self.write(4, 0x80); return
        if c == self.drum:
            sid = self.b(self.g['drummap'] + (op >> 4) - 1)
            self.play(sid); return
        if T.gate == 15: T.rel = T.len - 1
        else: T.rel = (T.len * T.gate) >> 4
        T.vlcnt = 0
        o = (T.oct * 12) & 0xFF if T.oct else 0
        idx = (((op >> 4) - 1) + T.transp + o) & 0xFF
        T.period = self.w(self.g['period'] + 2 * idx)
        if T.vib:
            T.vidx = 0; self.vib_step(c)
        self.write_period(c)
        T.flags &= 0xBF
        if c == self.ch3:
            self.sh[0x0A] = 0x80; self.hwwrite(0xFF1A, 0x80)
            T.c3tim = T.env; T.c3rel = T.env
            a = ((T.vol & 15) >> 1) & 3; T.lvl = a
            a = (a + T.atten) & 0xFF
            v = (a << 5) & 0xF0 if a < 4 else 0
            self.write(2, v); self.trigger()
        else:
            v = swap(((T.vol & 15) - T.atten) & 0xFF)
            if self.mm: T.lvl = v
            self.write(2, v); self.trigger()

    def end_track(self, c):
        T = self.t[c]
        if self.mm:
            if T.id == 0x11:
                self.queue = self.b(0x678D + ((self.course - 1) & 0xFF))
            T.id = 0; T.prio = 0
            self.write(2, 0); self.trigger()
            if c == 1: mt = self.t[4]
            elif c == 0:
                self.hwwrite(0xFF10, 0); mt = self.t[3]
            else: return
            if mt.id:
                self.write_duty(c, mt.duty)
                p = mt.period
                self.write(3, p & 0xFF); self.write(4, p >> 8)
            return
        T.id = 0; T.prio = 0
        self.write(2, 0)
        T.flags = 0x40
        self.write(4, 0x80)
        if c == 0 and self.t[2].id:
            T.duty = self.t[2].duty          # wCurDuty = slot 2's stored duty
            self.write_duty(c, T.duty)
            self.hwwrite(0xFF10, 0)

    # ------------------------------------------------------------- play
    def play(self, sid):
        if sid == 0: return self.stop()
        g = self.g
        h = self.w(g['table'] + 2 * (sid - 1))
        prio = self.b(h); m = self.b(h + 1); p = h + 2
        if self.mm:
            order = [(0, 0x11, 0), (1, 0x22, 1), (2, 0x88, 2), (3, 0x11, 3), (4, 0x22, 4), (5, 0x44, 5), (6, 0, 6)]
        else:
            order = [(0, 0x11, 0), (1, 0x88, 1), (2, 0x11, 2), (3, 0x22, 3), (4, 0x44, 4), (5, 0, 5)]
        for bit, nr, c in order:
            if not m >> bit & 1: continue
            if c == self.sfx1 or (c == self.mus1 and not self.t[self.sfx1].id):
                self.hwwrite(0xFF10, 8); self.sh[0] = 8
            if nr: self.nr51 = (self.nr51 & (~nr & 0xFF)) | nr
            T = self.t[c]
            ptr = self.w(p); p += 2
            if prio >= T.prio:
                T.prio = prio; T.id = sid; T.ptr = ptr; T.len = 1; T.flags = 0x40
                for i in range(6, 0x0D if self.mm else 0x0C): T.m[i] = 0
        self.hwwrite(0xFF25, self.nr51)

    def stop(self):
        for T in self.t:
            for i in range(0x25): T.m[i] = 0
        self.sh[:] = bytes(0x14)
        self.nr51 = 0; self.acc = 0; self.tempo = 0; self.skip = 0
        if self.mm: self.queue = 0; self.engine = 0
        for a, v in ((0xFF12, 0), (0xFF14, 0x80), (0xFF17, 0), (0xFF19, 0x80), (0xFF1C, 0),
                     (0xFF21, 0), (0xFF23, 0x80)):
            self.hwwrite(a, v)
