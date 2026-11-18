"""Reference model of the Cosmo Tank sound driver, written from CosmoTank_SoundDriver.md.
Produces the sound-register writes of each SndUpdate call, in order."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from ct import Rom, SOUND_TABLE, PERIODS, LENTAB, ENVTAB, REGTAB, PANTAB

NRX2 = [0x12, 0x17, 0x1C, 0x21]
NRX4 = [0x14, 0x19, 0x1E, 0x23]


def swap(x):
    return ((x << 4) | (x >> 4)) & 0xFF


class Track:
    def __init__(self):
        self.flags = 0
        self.timer = 0
        self.envcount = 0
        self.envpos = 0
        self.atten = 0
        self.fine = 0
        self.transpose = 0
        self.ptr = 0
        self.length = 0
        self.nrx1 = 0
        self.plo = 0
        self.phi = 0
        self.env = 0


class Model:
    def __init__(self, rom):
        self.rom = rom
        self.bank0 = rom.d[:0x4000]  # wave pointers below $4000 read bank 0 (the harness's bank 0 in emucheck)
        self.t = [Track() for _ in range(8)]
        self.queue = []          # queued ids, last = next started
        self.sweep_save = 0
        self.wave_ptr = 0
        self.pan = [0] * 8
        self.vol = [0] * 8
        self.retp = [0] * 8
        self.loopc = [0] * 8
        self.loopp = [0] * 8
        self.nr51 = 0
        self.ch3_dac = False
        self.ch3_on = False
        self.w = []
        self.nr52_reads = []
        self.fix_volbug = False  # True: envelope volume to its own track (sensitivity check)
        self.cur = 0             # wCurTrack: set only when a track reads events (or an SFX ends)

    # ---- hardware ----
    def wr(self, reg, val):
        val &= 0xFF
        self.w.append((reg, val))
        if reg == 0x25:
            self.nr51 = val
        elif reg == 0x1A:
            self.ch3_dac = bool(val & 0x80)
            if not self.ch3_dac:
                self.ch3_on = False
        elif reg == 0x1E and val & 0x80 and self.ch3_dac:
            self.ch3_on = True

    def set_pan(self, n):
        p = self.pan[n]
        self.wr(0x25, (self.nr51 & ~p & ~swap(p)) | p)

    def load_wave(self, addr):
        self.wr(0x1C, 0)
        self.wr(0x1A, 0)
        self.wr(0x1E, 0x80)
        for i in range(16):
            a = addr + i
            self.wr(0x30 + i, self.bank0[a] if a < 0x4000 else self.rom.b(a))
        self.wr(0x1A, 0x80)

    # ---- API ----
    def init(self):
        self.wr(0x26, 0x80)
        self.wr(0x1A, 0x80)
        for r in NRX2:
            self.wr(r, 0x08)
        for r in NRX4:
            self.wr(r, 0x80)
        self.wr(0x24, 0x77)
        self.wr(0x10, 0)
        self.wr(0x25, 0)
        for t in self.t:
            t.flags = 0

    def update(self):
        self.w = []
        for n in range(7, -1, -1):
            t = self.t[n]
            if not t.flags & 1:
                continue
            t.timer = (t.timer - 1) & 0xFF
            if t.timer == 0:
                self.events(n)
                continue
            t.envcount = (t.envcount - 1) & 0xFF
            if t.envcount:
                continue
            t.envpos += 2
            t.envcount = self.rom.b(t.envpos - 1)
            v = self.rom.b(t.envpos) - t.atten
            v = max(v, 0)
            self.vol[n if self.fix_volbug else self.cur] = v   # driver bug: stale wCurTrack, not n
            if t.flags & 0x80:
                continue
            self.wr(NRX2[n & 3], v)
            self.wr(NRX4[n & 3], t.phi)
        self.start_queued()
        return self.w

    def start_queued(self):
        if not self.queue:
            return
        sid = self.queue.pop()
        if (sid * 2) & 0xFF == 0:
            self.init()
            return
        p = self.rom.w(SOUND_TABLE + ((sid * 2) & 0xFF))
        while self.rom.b(p) != 0xFF:
            n = self.rom.b(p)
            if n >= 4:
                self.t[n - 4].flags |= 0x80
            t = self.t[n]
            t.flags = (t.flags | 1) & 0x81
            t.timer = 1
            t.atten = t.fine = t.transpose = 0
            t.ptr = self.rom.w(p + 1)
            p += 3

    # ---- events ----
    def events(self, n):
        t = self.t[n]
        rom = self.rom
        self.cur = n
        guard = 0
        while True:
            guard += 1
            if guard > 100000:
                raise RuntimeError(f'track {n}: event loop never reaches a note (ptr ${t.ptr:04X})')
            t.ptr = (t.ptr + 1) & 0xFFFF
            x = rom.b(t.ptr)
            if x < 0x80:
                return self.note(n, x)
            if x < 0xC0:
                t.length = rom.b(LENTAB + (x & 0x3F))
                continue
            if x < 0xE0:
                self.pan[n] = rom.b(PANTAB + (x & 0x1F) + (n & 3))
                continue
            c = x & 0x0F
            arg = rom.b(t.ptr + 1)
            if c == 0x0:
                t.env = rom.w(ENVTAB + ((arg * 2) & 0xFF)); t.ptr += 1
            elif c == 0x1:
                t.nrx1 = arg; t.ptr += 1
            elif c == 0x2:
                t.atten = arg; t.ptr += 1
            elif c == 0x3:
                t.transpose = arg; t.ptr += 1
            elif c == 0x4:
                t.ptr += 1; self.loopc[n] = arg; self.loopp[n] = t.ptr
            elif c == 0x5:
                self.loopc[n] = (self.loopc[n] - 1) & 0xFF
                if self.loopc[n]:
                    t.ptr = self.loopp[n]
            elif c == 0x6:
                self.retp[n] = t.ptr + 2
                t.ptr = rom.w(t.ptr + 1) - 1
            elif c == 0x7:
                t.ptr = self.retp[n]
            elif c == 0x8:
                t.ptr = rom.w(t.ptr + 1) - 1
            elif c == 0x9:
                t.fine = arg; t.ptr += 1
            elif c in (0xA, 0xB):
                v = arg if c == 0xA else 0
                if c == 0xA:
                    t.ptr += 1
                if n != 0:
                    self.wr(0x10, v)
                else:
                    self.sweep_save = v
                    t.flags = (t.flags | 4) if c == 0xA else (t.flags & ~4)
                    if not t.flags & 0x80:
                        self.wr(0x10, v)
            elif c == 0xC:
                a = rom.w(t.ptr + 1); t.ptr += 2
                if n == 6:
                    self.load_wave(a)
                else:
                    self.wave_ptr = a
                    if not t.flags & 0x80:
                        self.load_wave(a)
            elif c in (0xD, 0xF):
                return self.end(n)
            # 0xE: nop

    def note(self, n, x):
        t = self.t[n]
        rom = self.rom
        t.timer = t.length
        if x == 0x54:
            self.vol[n] = 8
            t.flags |= 2
            if not t.flags & 0x80:
                p = self.pan[n]
                self.wr(0x25, self.nr51 & ~p & ~swap(p))
            return
        if n & 3 == 3:
            t.plo, t.phi = swap(x), 0x80
        else:
            per = rom.w(PERIODS + (((x + t.transpose) * 2) & 0xFF)) + t.fine
            lo, hi = per & 0xFF, (per >> 8) & 0xFF
            if n & 3 == 2:
                self.nr52_reads.append(self.ch3_on)
            if not (n & 3 == 2 and self.ch3_on):
                hi |= 0x80
            t.plo, t.phi = lo, hi
        e = t.env
        t.envcount = rom.b(e)
        t.envpos = e + 1
        v = rom.b(e + 1) - t.atten
        if v < 0:
            v = 0x08 if n & 3 == 3 else 0
        self.vol[n] = v
        if t.flags & 0x80:
            return
        if n & 3 == 3:
            self.wr(0x21, v)
            self.set_pan(n)
            self.wr(0x22, t.plo)
            self.wr(0x23, 0x80)
        else:
            self.wr(NRX2[n & 3], v)
            self.wr(NRX2[n & 3] - 1, t.nrx1)
            self.set_pan(n)
            self.wr(NRX4[n & 3] - 1, t.plo)
            self.wr(NRX4[n & 3], t.phi)

    def end(self, n):
        t = self.t[n]
        t.flags &= ~1
        m = n & 3
        if n < 4:
            if not t.flags & 0x80:
                self.wr(NRX2[m], 0x08)
                self.wr(NRX4[m], 0x80)
            return
        mt = self.t[m]
        mt.flags &= ~0x80
        if not mt.flags & 1:
            self.wr(NRX2[m], 0x08)
            self.wr(NRX4[m], 0x80)
            return
        self.cur = m
        if n == 4:
            self.wr(0x10, self.sweep_save if mt.flags & 4 else 0)
        if m == 2:
            self.load_wave(self.wave_ptr)
        self.set_pan(m)
        self.wr(NRX2[m], self.vol[m])
        self.wr(NRX4[m] - 1, mt.plo)
        self.wr(NRX4[m], mt.phi | 0x80)
