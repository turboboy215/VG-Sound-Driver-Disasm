"""Reference model of the Realtime Associates sound driver, written from the
documentation (RTA_SoundDriver.md).  It produces the sequence of sound-register
writes of each call, so it can be compared with the real code in an emulator.
"""

NR = dict(NR10=0xFF10, NR11=0xFF11, NR12=0xFF12, NR13=0xFF13, NR14=0xFF14,
          NR21=0xFF16, NR22=0xFF17, NR23=0xFF18, NR24=0xFF19,
          NR30=0xFF1A, NR32=0xFF1C, NR33=0xFF1D, NR34=0xFF1E,
          NR41=0xFF20, NR42=0xFF21, NR43=0xFF22, NR44=0xFF23,
          NR50=0xFF24, NR51=0xFF25, NR52=0xFF26)
REGBASE = [0xFF10, 0xFF15, 0xFF1A, 0xFF1F]
SFX_SILENCE = [0xFF12, 0xFF17, 0xFF1C, 0xFF21]


class Voice:
    def __init__(self):
        self.timer = self.patch = self.note = self.perlo = self.perhi = self.count = 0


class Model:
    def __init__(self, bk, tables, reads):
        self.bk = bk
        self.t = tables
        self.reads = reads          # iterator over values read from NR52/NR51
        self.out = []
        self.rnd = 0x47
        self.transpose = self.sfxtimer = self.sfxptr = self.waitadd = 0
        self.own = [0, 0, 0, 0]
        self.highpri = 0
        self.ndefs = self.defs = self.musptr = self.mustimer = self.paused = 0
        self.v = [Voice() for _ in range(4)]
        self.prog = [0] * 16

    # ------------------------------------------------------------------ util
    def b(self, a):
        return self.bk.b(a)

    def w(self, reg, val):
        self.out.append(('w', reg, val & 0xFF))

    def read(self, reg):
        kind, val = next(self.reads)
        assert kind == reg, (kind, reg)
        self.out.append(('r', reg, val))
        return val

    def random(self):
        x = self.rnd
        c = ((x >> 5) ^ (x >> 6)) & 1
        self.rnd = ((x << 1) | c) & 0xFF
        return self.rnd

    def sound_ptr(self, i):
        return self.bk.w(self.t['Sounds'] + 2 * (i & 0x3F))

    # ------------------------------------------------------------- interface
    def silence(self):
        for r in (0xFF12, 0xFF17, 0xFF1C, 0xFF21, 0xFF14, 0xFF19, 0xFF1E, 0xFF23):
            self.w(r, 0)
        for v in self.v:
            v.timer = 0

    def power_cycle(self):
        self.silence()
        self.w(NR['NR52'], 0)
        self.w(NR['NR52'], 0xFF)

    def init(self):
        self.power_cycle()
        self.sfxtimer = 0
        self.paused = 0
        self.w(NR['NR50'], 0x77)

    def stop_all(self):
        self.mustimer = 0
        self.sfxtimer = 0
        self.power_cycle()

    def pause_play(self, a):
        self.paused = 1
        self.power_cycle()
        self.play(a)

    def play(self, a):
        if a & 0x80:
            self.silence()
            self.mustimer = 0
            self.paused = 0
            self.music_start(a)
            return
        if not a & 0x40 and self.highpri:
            return
        self.sfxtimer = self.transpose = self.waitadd = 0
        for k in range(4):
            if self.own[k]:
                self.w(SFX_SILENCE[k], 0)
                self.own[k] = 0
        self.highpri = a & 0x40
        self.sfxptr = self.sound_ptr(a)
        self.w(NR['NR50'], 0x77)
        self.w(NR['NR51'], 0xFF)
        self.sfxtimer = 1

    def music_start(self, a):
        h = self.sound_ptr(a)
        self.ndefs = self.b(h)
        self.defs = h + 1
        self.musptr = h + 1 + 2 * self.ndefs
        self.w(NR['NR50'], 0x77)
        self.w(NR['NR51'], 0xFF)
        self.mustimer = 1

    def update(self):
        self.sfx_update()
        self.music_update()

    # ------------------------------------------------------------------- SFX
    def period(self, p, lo, hi):
        s = lo + self.transpose
        return s & 0xFF, ((hi + (s >> 8)) & 0xC7)

    def sfx_update(self):
        if self.sfxtimer == 0:
            self.own = [0, 0, 0, 0]
            self.highpri = 0
            return
        self.sfxtimer -= 1
        if self.sfxtimer:
            return
        p = self.sfxptr
        while True:
            c = self.b(p)
            p += 1
            if c == 0x00:
                self.w(0xFF10, 1)
                self.w(0xFF11, 0)
                self.w(0xFF12, 0)
                self.w(0xFF14, 0)
                self.w(0xFF10, self.b(p))
                self.w(0xFF11, self.b(p + 1))
                self.w(0xFF12, self.b(p + 2))
                lo, hi = self.period(p, self.b(p + 3), self.b(p + 4))
                self.w(0xFF13, lo)
                self.w(0xFF14, hi)
                self.own[0] = 0xFF
                p += 5
            elif c == 0x01:
                self.w(0xFF16, self.b(p))
                self.w(0xFF17, self.b(p + 1))
                lo, hi = self.period(p, self.b(p + 2), self.b(p + 3))
                self.w(0xFF18, lo)
                self.w(0xFF19, hi)
                self.own[1] = 0xFF
                p += 4
            elif c == 0x02:
                pass
            elif c == 0x03:
                for i in range(4):
                    self.w(0xFF20 + i, self.b(p + i))
                self.own[3] = 0xFF
                p += 4
            elif c == 0xFE:
                p = self.bk.w(p)
            elif c == 0xFF:
                self.transpose = self.random() & self.b(p)
                self.waitadd = self.random() & self.b(p + 1)
                p += 2
            else:
                t = c - 4
                self.sfxtimer = t
                if t:
                    self.sfxtimer = (t + self.waitadd) & 0xFF
                self.sfxptr = p
                return

    # ----------------------------------------------------------------- music
    def voice_of(self, prog):
        if prog >= 0x48:
            return 3
        return self.b(self.t['SlotOfs'] + ((prog >> 5) & 3)) // 6

    def music_update(self):
        if self.paused:
            return
        if self.mustimer == 0:
            if self.read('NR52') & 0x0F:
                self.voices()
            return
        self.mustimer -= 1
        if self.mustimer:
            self.voices()
            return
        p = self.musptr
        n = self.ndefs
        while True:
            c = self.b(p)
            if c == 0xFE:
                self.music_start(self.b(p + 1))
                return
            if c == 0xFF:
                self.musptr = p
                self.voices()
                return
            if c < n:
                ch = self.b(self.defs + c)
                note = (self.b(self.defs + n + c) - 3) & 0xFF
                prog = self.prog[ch]
                v = self.v[self.voice_of(prog)]
                v.timer = 1
                v.patch = self.b(self.t['Attack'] + prog)
                v.note = note
                v.count = 1
                p += 1
            elif c < n + 16:
                prog = self.prog[c - n]
                e = self.b(self.t['Release'] + prog)
                if e:
                    v = self.v[self.voice_of(prog)]
                    v.timer = 1
                    v.patch = e
                    v.count = 1
                p += 1
            elif c < n + 32:
                self.prog[c - n - 16] = self.b(p + 1)
                p += 2
            else:
                self.mustimer = c - n - 32
                self.musptr = p + 1
                self.voices()
                return

    def voices(self):
        for k in range(4):
            v = self.v[k]
            if v.timer == 0:
                continue
            v.timer -= 1
            if v.timer:
                continue
            if self.own[k]:
                v.timer = 0
                continue
            P = self.t['Patches'] + 12 * v.patch
            pb = [self.b(P + i) for i in range(12)]
            flags = pb[0]
            if flags & 1:
                pa = self.t['Periods'] + ((2 * v.note) & 0xFF)
                s = pb[1] + self.b(pa)
                v.perlo = s & 0xFF
                v.perhi = (flags & 0x80) | ((self.b(pa + 1) + (s >> 8)) & 0xFF)
            else:
                v.perhi |= flags & 0x80
            s = v.perlo + pb[2]
            v.perlo = s & 0xFF
            v.perhi = (v.perhi + pb[3] + (s >> 8)) & 0xFF
            if v.perhi & 0x38:
                v.perlo = v.perhi = 0
            nr51 = self.read('NR51')
            self.w(NR['NR51'], (nr51 & pb[4]) | pb[5])
            v.timer = pb[6]
            if v.count:
                v.count -= 1
                if v.count == 0:
                    v.patch = pb[7]
                    v.count = pb[8]
            base = REGBASE[k]
            reg = pb[9]
            if reg == 0xFD:
                self.w(0xFF21, pb[10])
                self.w(0xFF22, ((self.v[3].note & 7) << 4) | pb[11])
                self.w(0xFF23, 0x80)
                return
            if reg == 0xFE:
                self.w(0xFF1A, 0)
                for i in range(16):
                    self.w(0xFF30 + i, self.b(self.t['Waves'] + pb[10] + i))
                self.w(0xFF1C, 0x20)
                self.w(0xFF1A, 0x80)
                pv = self.v[2]
                self.w(0xFF1D, pv.perlo)
                self.w(0xFF1E, pv.perhi)
                pv.perhi &= 0x7F
                continue
            if reg != 0xFF:
                self.w(base, reg)
                self.w(base + 1, pb[10])
                self.w(base + 2, pb[11])
            self.w(base + 3, v.perlo)
            self.w(base + 4, v.perhi)
            v.perhi &= 0x7F
