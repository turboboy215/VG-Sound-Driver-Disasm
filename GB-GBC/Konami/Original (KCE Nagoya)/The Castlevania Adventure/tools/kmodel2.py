"""Behavioural model of the later Konami GB driver variant (Nemesis, Castlevania II - Belmont's Revenge,
Blades of Steel).
Written from the disassembly, used to cross-check the emulator tick by tick (verify/vmodel2.py).
Track state is kept in byte arrays laid out like the game's RAM (field = L - $80) so it can be compared directly."""
import kdata

F = dict(id=0, prio=1, ptr=2, len=4, flags=5, loop=6, vib=7, transp=8, atten=9, vofs=0xA,
         vlcnt=0xC, unit=0xD, oct=0xE, period=0xF, vol=0x11, duty=0x12, env=0x13, gate=0x14,
         rel=0x15, vtim=0x16, vrel=0x17, c3tim=0x18, c3rel=0x19, lvl=0x1B, segno=0x1C, ret=0x1E,
         vptr=0x20, vidx=0x22, vlidx=0x23,
         dcnt=0x24, dduty=0x25, dticks=0x26, pan=0x35,          # Belmont's Revenge (+ duty step in BoS)
         glen=0x27, gloct=0x28, gltgt=0x29, glcur=0x2B, glstart=0x2D, gldir=0x2E, gldelta=0x2F,
         gltim=0x31, glrel=0x32, glstep=0x33, glloop=0x34)    # Blades of Steel glide
WORD = {'ptr', 'vofs', 'period', 'segno', 'ret', 'vptr', 'gltgt', 'glcur', 'gldelta'}

# per-game constants
GAME = {
    'nem': dict(tsize=0x25, waves=0x69EE, pausesnd=0x2C, basetab=[0, 5, 0xF, 0, 5, 0xA, 0xF],
                fadeshift=0x3F),
    'cv2': dict(tsize=0x37, waves=0x4993, pausesnd=0x06, basetab=[0, 5, 0xF, 0, 5, 0xA, 0xF],
                fadeshift=0x1F),
    'bos': dict(tsize=0x37, waves=0x513B, pausesnd=0x06, basetab=[0, 5, 0xF, 0, 5, 0xA, 0xF],
                fadeshift=0x0F),
}
NEM_LOCKOUT = 0x5B64          # countdown per id $2E-$32
NEM_PANMASK = [0xEE, 0xDD, 0x77, 0xEE, 0xDD, 0xBB, 0xFF]   # bits KEPT by PAN on each track
CV2_PANBITS = [0x11, 0x22, 0x88, 0x11, 0x22, 0x44, 0x88]   # bits WRITTEN by PAN on each track


class Track:
    def __init__(self, size):
        object.__setattr__(self, 'm', bytearray(size))
    def __getattr__(self, k):
        o = F[k]
        return self.m[o] | (self.m[o + 1] << 8) if k in WORD else self.m[o]
    def __setattr__(self, k, v):
        o = F[k]
        if k in WORD: self.m[o] = v & 0xFF; self.m[o + 1] = (v >> 8) & 0xFF
        else: self.m[o] = v & 0xFF


def swap(a): return ((a << 4) | (a >> 4)) & 0xFF


class Driver:
    def __init__(self, g):
        self.g = g; self.bos = g['name'] == 'bos'
        self.cv2 = g['name'] in ('cv2', 'bos')    # request groups / abort, duty step, VBlank globals
        self.rawpan = g['name'] == 'cv2'          # TRK_PAN raw bits (BoS went back to Nemesis' PAN)
        self.k = GAME[g['name']]
        self.rom = kdata.Rom(g['rom'], g['bank'])
        self.t = [Track(self.k['tsize']) for _ in range(7)]
        self.sh = bytearray(0x14)
        self.nr51 = 0; self.acc = 0; self.tempo = 0; self.skip = 0; self.queue = 0
        self.sweep = 0; self.hold = 0
        self.lock = 0                         # Nemesis jingle lockout countdown
        self.fadeid = 0; self.fadecnt = 0; self.fadelvl = 0
        self.reject = 0                       # Belmont's Revenge: last start refused
        self.reqid = 0; self.reqprio = 0
        self.hw = {}
        self.wave = bytearray(16)
        self.trig = []
        self.tick_no = 0
        self.pause = 0; self.gamevar = 0      # Nemesis: $C081 (picks the follow-up of sound $14)
        self.cur = 0

    def b(self, a): return self.rom.b(a)
    def w(self, a): return self.rom.w(a)
    @property
    def base(self): return self.k['basetab'][self.cur]

    # ------------------------------------------------------------- register access
    def blocked(self):
        c = self.cur
        return (c == 3 and self.t[0].id != 0) or (c == 4 and self.t[1].id != 0)

    def write(self, reg, v):
        if self.blocked(): return
        idx = self.base + reg
        if (self.t[self.cur].flags & 0x40) or self.sh[idx] != v:
            self.sh[idx] = v; self.hwwrite(0xFF10 + idx, v)

    def hwwrite(self, a, v):
        self.hw[a] = v
        if 0xFF30 <= a < 0xFF40: self.wave[a - 0xFF30] = v

    def trigger(self):
        if self.blocked(): return
        idx = self.base + 4
        self.hwwrite(0xFF10 + idx, self.sh[idx] | 0x80)
        self.trig.append((self.tick_no, self.base))

    def write_duty(self, T):
        """WriteDuty: NRx1 = duty << 4 from track T, or the wave (duty-1) on CH3 (by register base)."""
        if self.base == 0x0A:
            n = (T.duty - 1) & 0xFF
            p = self.w(self.k['waves'] + ((2 * n) & 0xFF))
            for i in range(16): self.hwwrite(0xFF30 + i, self.b(p + i))
        else:
            self.write(1, swap(T.duty))

    # ------------------------------------------------------------- update
    def update(self):
        self.tick_no += 1
        self.fade_tick()
        if not self.cv2 and self.lock: self.lock -= 1
        self.skip = 0
        s = self.acc + self.tempo
        self.acc = s & 0xFF
        if s > 0xFF: self.skip = 1
        for c in range(7):
            self.cur = c
            if self.pause:
                if c != 1: continue
                if self.t[1].id != self.k['pausesnd']: break
            elif c == 3 and (self.hold or self.skip):
                break
            if self.t[c].id: self.track_tick(c)
        if self.queue:
            q = self.queue; self.queue = 0; self.play(q)

    def fade_tick(self):
        if self.pause: return
        if self.cv2:
            if not self.fadeid & 0x80: return
        elif not self.fadeid: return
        self.fadecnt = (self.fadecnt + 1) & 0xFF
        if self.fadecnt & self.k['fadeshift']: return
        self.fadelvl += 1
        if self.fadelvl != 5: return
        if self.cv2:
            self.queue = self.fadeid & 0x7F
            if self.bos and self.queue < 5:
                self.stop(); return
            self.fadelvl = 0; self.fadeid = 0
            return
        self.queue = self.fadeid
        if self.fadeid < 7:
            self.stop(); return
        self.fadelvl = 0; self.fadeid = 0

    def track_tick(self, c):
        T = self.t[c]
        T.len = T.len - 1
        if T.len == 0:
            T.flags = T.flags & 0x7E
            if c == 5:
                self.sh[0x0A] = 0; self.hwwrite(0xFF1A, 0)
            self.read_cmds(c)
            return
        if self.cv2 and T.flags & 0x10:
            T.dcnt = T.dcnt + 1
            if T.dcnt == T.dticks: self.write_duty(T)
        if T.rel >= T.len: T.flags |= 1
        if T.flags & 0x80: return
        if c in (2, 6): return
        if self.bos:
            # GlideTick and GlideOrVibrato jump into the tail of TrackTick with their return address
            # still on the stack, so the tail (release check / CH3 decay) runs again on return.
            if self.glide_tick(c): self.tail(c)
            if T.flags & 0x20: self.tail(c)
            else: self.vib_tick(c)
            self.tail(c); return
        self.vib_tick(c)
        self.tail(c)

    def tail(self, c):
        T = self.t[c]
        if c == 5:
            self.ch3_decay(c); return
        if T.rel == T.len:
            self.write(2, T.lvl | T.env); self.trigger()

    def glide_tick(self, c):
        """BoS GlideTick ($4410). True = the timer is still running (jumps to the tail)."""
        T = self.t[c]
        if not T.flags & 0x20: return False
        if T.glstart == 0 or T.glstart < T.len: return False
        T.gltim = T.gltim - 1
        if T.gltim: return True
        T.gltim = T.glrel
        d = T.glstep
        if T.gldir & 1: d = (-d) & 0xFFFF
        T.glcur = (T.glcur + d) & 0xFFFF
        p = T.glcur
        self.write(3, p & 0xFF); self.write(4, p >> 8)
        return False

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
        v = swap(((a << 1) | 1) & 0xFF) if a < 4 else 0
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
        a = (T.vptr + T.vidx) & 0xFFFF
        while True:
            v = self.b(a)
            if v == 0xFB:
                T.vidx = T.vidx + 1; T.vlidx = T.vidx; a += 1; continue
            if v == 0xFE:
                n = self.b(a + 1)
                if n == T.vlcnt:
                    T.vlcnt = 0; T.vidx = T.vidx + 2; a += 2; continue
                if n != 0xFF: T.vlcnt = T.vlcnt + 1
                T.vidx = T.vlidx; a = (T.vptr + T.vidx) & 0xFFFF; continue
            if v == 0xFF: return
            T.vtim = v >> 4; T.vrel = v >> 4
            if v & 8: T.flags |= 8
            elif self.bos: T.flags &= 0xF7
            T.vofs = ((v & 7) << 8) | self.b(a + 1)
            T.vidx = T.vidx + 2
            return

    def write_period(self, c, T=None):
        T = T or self.t[c]
        o = T.vofs
        if T.flags & 8: o = (-o) & 0xFFFF
        p = (T.period + o) & 0xFFFF
        self.write(3, p & 0xFF); self.write(4, p >> 8)

    def pan_apply(self, c, T):
        """Belmont's Revenge: NR51 bits of this track = its stored pan byte (dropped while blocked)."""
        m = CV2_PANBITS[c]
        a = self.nr51 & (~m & 0xFF); cc = T.pan & m
        if self.blocked(): return
        self.nr51 = a | cc; self.hwwrite(0xFF25, self.nr51)

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
                    else:
                        T.loop = T.loop + 1
                        if T.loop == n: T.loop = 0; p += 1
                        else: p = T.segno
                else:
                    self.end_track(c); return
                continue
            if op == 0xE0:
                p += 1; T.unit = self.b(p)
                if c == 6: p += 1; continue
                p += 1; x = self.b(p)
                if c == 2:
                    T.env = x & 15; T.vol = x >> 4
                    self.write(2, x); self.trigger(); p += 1; continue
                T.vol = x & 15; T.duty = x >> 4; self.write_duty(T)
                p += 1; x = self.b(p); T.env = x & 15; T.gate = x >> 4; p += 1; continue
            if (op & 0xF0) < 0xE0:
                T.ptr = p; self.note(c, op); return
            if (op & 0xF0) == 0xF0:
                T.atten = op & 15
                if c == 2:
                    T.lvl = swap(((T.vol & 15) - T.atten) & 0xFF)
                    self.write(2, T.lvl | T.env); self.trigger()
                p += 1; continue
            if op < 0xE7:
                T.oct = (op & 15) - 1
                if self.bos: T.gloct = T.oct
                p += 1; continue
            p += 1; x = self.b(p)
            if op == 0xE7: T.unit = x
            elif op == 0xE8: T.env = x & 15; T.gate = x >> 4
            elif op == 0xE9: self.sweep = x; self.write(0, x)
            elif op == 0xEA:
                h, l = x >> 4, x & 15
                if h == 0: T.transp = l
                elif h == 1: T.transp = (-l) & 0xFF
                elif h == 2:
                    T.vib = l
                    if l == 0: T.vofs = 0
                    else:
                        T.vptr = self.w(self.g['vibtab'] + ((2 * ((l - 1) & 0xFF)) & 0xFF))
                        T.vlcnt = 0
                elif h == 3: T.duty = l; self.write_duty(T)
                elif h == 4: T.flags = (l | 2) if l else 0      # overwrites the whole flags byte
                elif h == 5 and self.bos:
                    if l: T.flags |= 0x20; T.glen = l
                    else: T.flags &= 0xDF
                else: raise RuntimeError(f'EA {x:02X}')
            elif op == 0xED and self.cv2:
                if x: T.flags |= 0x10; T.dduty = x & 15; T.dticks = x >> 4
                else: T.flags &= 0xEF
            elif op == 0xEE: self.tempo = x
            elif op == 0xEF:
                if self.rawpan:
                    if c == 6: p += 2; continue      # skips one byte too many
                    T.pan = x; self.pan_apply(c, T)
                elif not (c == 3 and self.t[0].id):
                    m = NEM_PANMASK[c]
                    self.nr51 = (self.nr51 & m) | (swap(x) & (~m & 0xFF))
                    self.hwwrite(0xFF25, self.nr51)
            p += 1

    def note(self, c, op):
        T = self.t[c]
        if T.flags & 2:                     # autopan
            if self.rawpan:
                if c != 2:
                    T.pan = swap(T.pan); self.pan_apply(c, T)
            else:
                m = NEM_PANMASK[c]
                self.nr51 = ((~m & 0xFF) & swap(self.nr51)) | (self.nr51 & m)
                self.hwwrite(0xFF25, self.nr51)
        T.ptr = T.ptr + 1
        if c == 2:
            T.len = T.unit; self.write(3, op); self.write(4, 0); return
        T.len = ((op & 15) * T.unit) & 0xFF
        if op & 0xF0 == 0:
            T.flags |= 0xC0; self.write(2, 0); return
        if c == 6:
            self.play(self.b(self.g['drummap'] + (op >> 4) - 1)); return
        if self.cv2 and c != 5:
            T.dcnt = 0
            if T.flags & 0x10: self.write(1, swap(T.dduty))
        T.rel = T.len - 1 if T.gate == 15 else (T.len * T.gate) >> 4
        T.vlcnt = 0
        o = (T.oct * 12) & 0xFF
        idx = (((op >> 4) - 1) + T.transp + o) & 0xFF
        T.period = self.w(self.g['period'] + 2 * idx)
        if self.bos:
            T.glcur = T.period
            if T.flags & 0x20: self.glide_setup(c)
        if T.vib:
            T.vidx = 0; self.vib_step(c)
        self.write_period(c)
        T.flags &= 0xBF
        if c == 5:
            self.sh[0x0A] = 0x80; self.hwwrite(0xFF1A, 0x80)
            T.c3tim = T.env; T.c3rel = T.env
            a = ((self.fadelvl >> 1) + T.atten + (((T.vol & 15) >> 1) & 3)) & 0xFF
            if a >= 4: a = 0
            T.lvl = a
            v = (a << 5) & 0xFF
        else:
            a = (self.fadelvl + T.atten) & 0xFF
            v = (T.vol & 15) - a
            if v < 0: v = 0
            T.lvl = swap(v & 0xFF); v = T.lvl
        self.write(2, v); self.trigger()

    def glide_setup(self, c):
        """BoS: look ahead for the next note and set up a slide to it ($47E0-$4969)."""
        T = self.t[c]
        p = (T.ptr - 1) & 0xFFFF            # the note byte
        p += 1
        while True:
            op = self.b(p)
            if op == 0xFB: p += 1; T.segno = p; continue
            if op == 0xFC: p = T.ret; continue
            if op == 0xFD:
                tg = self.w(p + 1); p += 3; T.ret = p; p = tg; continue
            if op == 0xFE:
                p += 1; n = self.b(p)
                if n == 0xFF: p = self.w(p + 1); continue
                T.glloop = T.glloop + 1
                if n == T.glloop: T.glloop = 0; p += 1; continue
                p = T.segno; continue
            if op == 0xFF:
                T.flags &= 0xDF; return
            if op == 0xE0: p += 4; continue
            hi = op & 0xF0
            if hi < 0xE0: break
            if hi == 0xF0: p += 1; continue
            if op >= 0xE7: p += 2; continue
            T.gloct = (op & 15) - 1; p += 1
        o = (T.gloct * 12) & 0xFF
        idx = (((op >> 4) - 1) + T.transp + o) & 0xFF
        T.gltgt = self.w(self.g['period'] + 2 * idx)
        b = (T.glen * T.unit) & 0xFF
        T.glstart = (T.len - b) & 0xFF
        if T.glstart == 0: return
        tg, pr = T.gltgt, T.period
        if tg == pr:
            T.glstep = 0; T.gltim = 0xFF; T.glrel = 0xFF; return
        if tg > pr: T.gldir &= 0xFE; T.gldelta = (tg - pr) & 0xFFFF
        else: T.gldir |= 1; T.gldelta = (pr - tg) & 0xFFFF
        lo, hi = T.gldelta & 0xFF, T.gldelta >> 8; st = T.glstart
        if hi == 0 and lo == st:
            T.glstep = 1; T.gltim = 1; T.glrel = 1; return
        def subs(a, c, b):                  # sub c / inc b until borrow (8-bit)
            while True:
                a -= c; b = (b + 1) & 0xFF
                if a < 0: return a & 0xFF, b
        if hi == 0 and lo < st:
            _, n = subs(st, lo, 0)
            T.glstep = 1; T.gltim = n; T.glrel = n; return
        a, b = subs(lo, st, 0)
        while hi:
            a, b = subs(a, st, b); hi -= 1
        T.glstep = b; T.gltim = 1; T.glrel = 1

    def end_track(self, c):
        T = self.t[c]
        if not self.cv2:
            if T.id == 0x37: self.queue = 0x34
            elif T.id == 0x21: self.queue = 0x36
            elif T.id == 0x14: self.queue = 0x34 if self.gamevar == 2 else 0x33
        T.id = 0; T.prio = 0
        self.write(2, 0)
        if c == 5:
            self.hwwrite(0xFF1A, 0); return
        if c == 1: mt = self.t[4]
        elif c == 0:
            self.hwwrite(0xFF10, 0); mt = self.t[3]
        else: return
        if mt.id:
            self.write_duty(mt)
            p = mt.period
            self.write(3, p & 0xFF); self.write(4, p >> 8)

    # ------------------------------------------------------------- play
    def header(self, sid):
        return self.w(self.g['table'] + 2 * (sid - 1))

    def play(self, sid):
        self.reqid = sid
        if sid == 0: return self.stop()
        if not self.cv2:
            if sid not in (0x2C, 0x13):
                if self.lock: return
                if sid >= 0x2E:
                    if sid < 0x33: self.lock = self.w(NEM_LOCKOUT + 2 * (sid - 0x2E))
                    self.fadeid = 0; self.fadelvl = 0
            if sid == 0x0F and self.t[0].id == 0x0F: return
        h = self.header(sid)
        self.reqprio = self.b(h); m = self.b(h + 1); p = h + 2
        groups = [[0], [1, 2], [3, 4, 5, 6]] if self.cv2 else [[0, 1, 2, 3, 4, 5, 6]]
        nrbits = [0x11, 0x22, 0x88, 0x11, 0x22, 0x44, 0]
        for grp in groups:
            for c in grp:
                if not m >> c & 1: continue
                if c == 0 or (c == 3 and not self.t[0].id):
                    self.hwwrite(0xFF10, 8); self.sh[0] = 8
                self.nr51 |= nrbits[c]
                ptr = self.w(p); p += 2
                self.start(c, ptr)
            if self.cv2 and grp != [3, 4, 5, 6] and self.reject:
                self.reject = 0; return
        self.hwwrite(0xFF25, self.nr51)

    def start(self, c, ptr):
        T = self.t[c]
        if self.reqprio < T.prio:
            self.reject = 1; return
        T.prio = self.reqprio; T.id = self.reqid; T.ptr = ptr; T.len = 1; T.flags = 0x40
        for i in range(6, 0x0D): T.m[i] = 0
        self.reject = 0

    def stop(self):
        for T in self.t:
            for i in range(len(T.m)): T.m[i] = 0
        self.sh[:] = bytes(0x14)
        self.acc = self.tempo = self.skip = self.queue = self.sweep = self.hold = 0
        self.lock = self.fadeid = self.fadecnt = self.fadelvl = self.reject = 0
        self.reqid = self.reqprio = 0
        self.nr51 = 0xFF
        for a in (0xFF12, 0xFF17, 0xFF1C, 0xFF21):
            self.hwwrite(a, 0)
