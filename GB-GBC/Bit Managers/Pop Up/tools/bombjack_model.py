"""Independent Python model of the Bomb Jack (AJG v2) sound driver.

Written from the documented behaviour (BombJack_SoundDriver.md), on a 64 KB
memory image with the game's RAM layout.  Compared tick by tick against the
real code in PyBoy (verify/vmodel.py).
"""

C4, C5, C6, C7 = 0xC4, 0xC5, 0xC6, 0xC7


class Stop(Exception):
    pass


class BombJackModel:
    def __init__(self, rom, mem):
        self.rom = rom
        self.m = bytearray(mem)
        self.hw = {}

    # ---------------------------------------------------------- helpers
    def f(self, h, o):
        return self.m[(h << 8) | o]

    def sf(self, h, o, v):
        self.m[(h << 8) | o] = v & 0xFF

    def g(self, a):
        return self.m[a]

    def sg(self, a, v):
        self.m[a] = v & 0xFF

    def reg(self, r, v):
        v &= 0xFF
        self.m[0xFF00 | r] = v
        self.hw[r] = v

    def bit(self, h, o, b):
        return (self.f(h, o) >> b) & 1

    def setbit(self, h, o, b, on):
        v = self.f(h, o)
        self.sf(h, o, (v | (1 << b)) if on else (v & ~(1 << b)))

    def w16(self, a):
        return self.rom[a] | (self.rom[a + 1] << 8)

    # ---------------------------------------------------------- API
    def snd_init(self):
        for h, src in ((C4, 0x6069), (C5, 0x6075), (C6, 0x6081), (C7, 0x6081)):
            for i in range(12):
                self.sf(h, i, self.rom[src + i])
            for o in range(0x0C, 0x3D):
                self.sf(h, o, 0)
        self.reg(0x25, 0xFF)
        self.sg(0xC31E, 0xFF)
        self.stop_all()

    def stop_all(self):
        self.sg(0xC338, 0); self.sg(0xC32A, 0); self.sg(0xC332, 0)
        for h in (C4, C5, C6, C7):
            self.reset_channel(h)
        self.sg(0xC31D, 0)
        self.reg(0x21, 0)

    def reset_channel(self, h):
        for o in (0x10, 0x0B, 0x04, 0x0E, 0x2E, 0x2B, 0x0F, 0x31, 0x3B):
            self.sf(h, o, 0)
        self.sf(h, 0x05, 1)
        self.sf(h, 0x32, 1)
        r = self.f(h, 0x0A)
        self.reg(r, 0)
        self.reg(r + 2, 0x80)
        if h in (C6, C7):
            self.sg(0xC31B, self.g(0xC31B) + 1)

    def start_music_ch(self, h, de):
        self.reset_channel(h)
        self.sf(h, 0x10, 1)
        self.sf(h, 0x02, self.rom[de]); self.sf(h, 0x03, self.rom[de + 1])
        de += 2
        self.sf(h, 0x00, de & 0xFF); self.sf(h, 0x01, de >> 8)

    SONGS = {1: ((C6, 0x611E), (C4, 0x6134), (C5, 0x614A)),
             2: ((C6, 0x6449), (C4, 0x6451), (C5, 0x6459)),
             3: ((C6, 0x6501), (C4, 0x6507), (C5, 0x650D)),
             4: ((C6, 0x659F), (C4, 0x65E3), (C5, 0x6627)),
             5: ((C6, 0x7472), (C5, 0x748E), (C4, 0x74B0))}

    def play_song(self, n):
        self.stop_all()
        if n == 1:
            if self.g(0xFF82) == 0:
                self.stop_all()
                for h, de in self.SONGS[1]:
                    self.start_music_ch(h, de)
        else:
            for h, de in self.SONGS[n]:
                self.start_music_ch(h, de)
        if n == 5:
            t, at = 0x7930, 0x79E2
        else:
            t, at = 0x7344, 0x740C
        self.sg(0xC31F, t & 0xFF); self.sg(0xC320, t >> 8)
        self.sg(0xC321, at & 0xFF); self.sg(0xC322, at >> 8)
        self.reg(0x24, 0x77)

    def play_sound(self, b):
        cur = self.g(0xC710)
        if cur and cur < b:
            return
        if b in (0x0B, 0x0C, 0x0E):
            self.reg(0x24, 0x77)
        elif b in (1, 4):
            if self.g(0xFF82) == 0:
                self.reg(0x24, 0x77)
            else:
                self.reg(0x24, self.rom[0x5F2F + (self.g(0xFFC0) >> 3)])
        else:
            if self.g(0xFF82):
                self.reg(0x24, self.rom[0x5F2F + (self.g(0xC001) >> 3)])
        if self.g(0xC710):
            self.reset_channel(C7)
        self.sg(0xC710, b)
        p = self.w16(0x5F3F + ((2 * b) & 0xFF))
        self.sf(C7, 0x02, p & 0xFF); self.sf(C7, 0x03, p >> 8)
        try:
            self.read_stream(C7, p)
        except Stop:
            pass

    def start_fade(self, speed, table):
        self.sg(0xC337, speed)
        self.sg(0xC325, table & 0xFF); self.sg(0xC326, table >> 8)
        self.sg(0xC335, 0); self.sg(0xC336, 0); self.sg(0xC338, 1)

    # ---------------------------------------------------------- tick
    def snd_tick(self):
        self.reg(0x26, 0x80)
        self.do_fade()
        for h in (C4, C5, C6, C7):
            self.channel_tick(h)
        self.sg(0xC32C, self.g(0xC32C) - 1)
        if self.g(0xC32C) == 0:
            self.drum_step()
        self.noise_seq_tick()
        self.output(C4)
        self.output(C5)
        self.output(C7 if self.g(0xC710) else C6)

    def do_fade(self):
        if self.g(0xFF99):
            return
        if not self.g(0xC338):
            if self.m[0xFF24]:
                self.reg(0x24, 0x77)
            return
        if self.g(0xC336):
            self.sg(0xC336, self.g(0xC336) - 1)
            return
        while True:
            p = ((self.g(0xC326) << 8) | self.g(0xC325)) + self.g(0xC335)
            x = self.rom[p & 0xFFFF]
            if x == 0x68:
                self.sg(0xC335, 0)
                continue
            break
        if x == 0xFF:
            self.sg(0xC338, 0)
            return
        self.reg(0x24, x)
        self.sg(0xC335, self.g(0xC335) + 1)
        self.sg(0xC336, self.g(0xC337))

    def cycle(self, h, base, actions):
        """auto-pan / auto-duty: fields base (reload), base+1 (counter), base+2 (step)"""
        if not self.f(h, base):
            return
        c = (self.f(h, base + 1) - 1) & 0xFF
        if c:
            self.sf(h, base + 1, c)
            return
        self.sf(h, base + 1, self.f(h, base))
        x = self.f(h, base + 2)
        self.sf(h, base + 2, x + 1)
        if x < len(actions) - 1:
            actions[x]()
        else:
            self.sf(h, base + 2, 1)
            actions[-1]()

    def set_pan(self, h, b, c):
        if h == C7:
            return
        for _ in range({C5: 1, C6: 2}.get(h, 0)):
            b = ((b << 1) | (b >> 7)) & 0xFF
            c = ((c << 1) | (c >> 7)) & 0xFF
        v = (self.g(0xC31E) | c) & b
        self.sg(0xC31E, v)
        self.reg(0x25, v)

    def pan_c(self, h): self.set_pan(h, 0xFF, 0x11)
    def pan_r(self, h): self.set_pan(h, 0xEF, 0x01)
    def pan_l(self, h): self.set_pan(h, 0xFE, 0x10)

    def set_duty(self, h, c):
        if h == C5:
            self.reg(0x16, c)
        elif h == C4:
            self.reg(0x11, c)

    def channel_tick(self, h):
        if not self.f(h, 0x10):
            return
        self.cycle(h, 0x2E, [lambda: self.set_duty(h, 0xC0), lambda: self.set_duty(h, 0x00),
                             lambda: self.set_duty(h, 0xC0), lambda: self.set_duty(h, 0x80)])
        self.cycle(h, 0x2B, [lambda: self.pan_c(h), lambda: self.pan_r(h),
                             lambda: self.pan_c(h), lambda: self.pan_l(h), lambda: self.pan_c(h)])
        if self.f(h, 0x0E):
            n = (self.f(h, 0x0C) + self.f(h, 0x0E)) & 0xFF
            self.sf(h, 0x0C, n)
            self.set_note_freq(h, n)
        self.do_envelope(h)
        self.do_arp(h)
        self.do_vibrato(h)
        de = self.f(h, 0x02) | (self.f(h, 0x03) << 8)
        self.check_release(h, de)
        self.sf(h, 0x05, self.f(h, 0x05) - 1)
        if self.f(h, 0x05):
            return
        try:
            self.read_stream(h, de)
        except Stop:
            pass

    def set_note_freq(self, h, a):
        c = (a + 0xF4) & 0xFF
        a = c if h == C7 else (self.g(0xC31D) + c) & 0xFF
        a = (a + self.f(h, 0x0F)) & 0xFF
        p = 0x5C29 + ((2 * a) & 0xFF)
        self.sf(h, 0x07, self.rom[p])
        self.sf(h, 0x09, self.rom[p + 1])

    def do_envelope(self, h):
        if self.f(h, 0x27):
            if not self.f(h, 0x29):
                return
            self.sf(h, 0x29, self.f(h, 0x29) - 1)
            if self.f(h, 0x29):
                return
            self.sf(h, 0x31, self.f(h, 0x2A))
            self.sf(h, 0x32, 1)
            return
        for flag, cnt, rel, step, up in ((0x12, 0x1A, 0x1B, 0x13, True), (0x15, 0x1C, 0x1D, 0x16, False),
                                         (0x19, 0x1E, 0x1F, 0x18, False)):
            if not self.f(h, flag):
                continue
            self.sf(h, cnt, self.f(h, cnt) - 1)
            if self.f(h, cnt):
                return
            self.sf(h, cnt, self.f(h, rel))
            if flag != 0x19:
                self.sf(h, flag, self.f(h, flag) - 1)
            if up:
                v = (self.f(h, step) + self.f(h, 0x0B)) & 0xFF
                self.sf(h, 0x0B, 15 if v >= 15 else v)
            else:
                self.sf(h, 0x0B, max(self.f(h, 0x0B) - self.f(h, step), 0))
            return

    def do_arp(self, h):
        if not self.bit(h, 0x04, 0):
            return
        while True:
            p = (self.f(h, 0x1F) | (self.f(h, 0x20) << 8)) + self.f(h, 0x21)
            a = self.rom[p & 0xFFFF]
            if a == 0x68:
                self.sf(h, 0x21, 0)
                continue
            if a == 0xFF:
                self.sf(h, 0x21, self.f(h, 0x21) - 1)
                continue
            break
        self.sf(h, 0x21, self.f(h, 0x21) + 1)
        self.set_note_freq(h, (a + self.f(h, 0x0C)) & 0xFF)

    def do_vibrato(self, h):
        if not self.bit(h, 0x04, 3):
            return
        if self.f(h, 0x22):
            self.sf(h, 0x22, self.f(h, 0x22) - 1)
            return
        self.sf(h, 0x24, self.f(h, 0x24) - 1)
        if self.bit(h, 0x04, 6):
            if self.f(h, 0x24) == 0:
                self.sf(h, 0x24, self.f(h, 0x25)); self.setbit(h, 0x04, 6, 0); return
            lo = self.f(h, 0x07) + self.f(h, 0x23)
            self.sf(h, 0x07, lo)
            if lo > 0xFF:
                self.sf(h, 0x09, self.f(h, 0x09) + 1)
        else:
            if self.f(h, 0x24) == 0:
                self.sf(h, 0x24, self.f(h, 0x25)); self.setbit(h, 0x04, 6, 1); return
            lo = self.f(h, 0x07) - self.f(h, 0x23)
            self.sf(h, 0x07, lo)
            if lo < 0:
                self.sf(h, 0x09, self.f(h, 0x09) - 1)

    def check_release(self, h, de):
        if not self.bit(h, 0x04, 1) or self.bit(h, 0x04, 2):
            return
        if self.f(h, 0x05) != self.f(h, 0x39):
            return
        if self.rom[de] == 0x63:
            return
        if h in (C6, C7):
            self.sf(h, 0x0B, self.f(h, 0x3A) >> 4)
        else:
            self.sf(h, 0x31, self.f(h, 0x3A))
            self.sf(h, 0x32, 1)
        self.setbit(h, 0x04, 2, 1)

    def drum_step(self):
        while True:
            if not self.g(0xC32A):
                return
            self.sg(0xC32C, self.g(0xC32B))
            p = ((self.g(0xC327) << 8) | self.g(0xC328)) + self.g(0xC329)
            self.sg(0xC329, self.g(0xC329) + 1)
            x = self.rom[p & 0xFFFF]
            if x == 0xFF:
                self.sg(0xC329, 0)
                continue
            break
        if x == 1:
            self.noise_seq(0x5968, 0x5970)
        elif x == 2:
            self.noise_seq(0x5977, 0x597F)
        elif x == 3:
            self.noise_seq(0x5986, 0x5989)
        elif x in (4, 5, 6, 7):
            self.drum_hit(x)

    def noise_seq(self, t43, t42):
        self.sg(0xC332, 1)
        self.sg(0xC32D, t43 >> 8); self.sg(0xC32E, t43 & 0xFF)
        self.sg(0xC32F, t42 >> 8); self.sg(0xC330, t42 & 0xFF)
        self.sg(0xC331, 0)

    def drum_hit(self, x):
        if x == 7:
            self.reg(0x20, 0x3A); self.reg(0x21, 0xF1); self.reg(0x22, 0x00); self.reg(0x23, 0xC0)
            return
        n41, n42, n43 = {4: (0x00, 0xA2, 0x03), 5: (0x00, 0xC1, 0x00), 6: (0x40, 0xD1, 0x01)}[x]
        self.reg(0x20, n41); self.reg(0x21, n42); self.reg(0x22, n43); self.reg(0x23, 0x80)

    def noise_seq_tick(self):
        if not self.g(0xC332):
            return
        i = self.g(0xC331)
        t43 = (self.g(0xC32D) << 8) | self.g(0xC32E)
        t42 = (self.g(0xC32F) << 8) | self.g(0xC330)
        x = self.rom[t43 + i]
        if x == 0xFF:
            self.sg(0xC331, 0); self.sg(0xC332, 0)
            return
        self.reg(0x22, x)
        self.reg(0x21, self.rom[t42 + i])
        self.reg(0x23, 0x80)
        self.sg(0xC331, i + 1)

    def output(self, h):
        if not self.f(h, 0x10):
            return
        self.reg(self.f(h, 0x06), self.f(h, 0x07))
        hi = self.f(h, 0x09) & 7
        sh = 0xC318 + (h - C4)
        if self.g(sh) != hi:
            self.reg(self.f(h, 0x08), hi)
            self.sg(sh, hi)
        r = self.f(h, 0x0A)
        c = self.f(h, 0x0B)
        if not self.f(h, 0x27):
            if r == 0x1C:
                x = self.rom[0x5E59 + (c & 0x0F)]
                if self.g(0xC31B) != x:
                    self.sg(0xC31B, x)
                    self.reg(0x1C, x)
                return
            self.reg(r, (c & 0x0F) << 4)
        else:
            if not self.f(h, 0x32):
                return
            self.sf(h, 0x32, 0)
            self.reg(r, self.f(h, 0x31))
        if h == C4:
            self.reg(0x14, self.g(0xC318) | 0x80)
        else:
            self.reg(0x19, self.g(0xC319) | 0x80)

    # ---------------------------------------------------------- stream
    def wait(self, h, de):
        self.sf(h, 0x05, self.f(h, 0x0D))
        self.sf(h, 0x02, de & 0xFF); self.sf(h, 0x03, de >> 8)
        raise Stop()

    def read_stream(self, h, de):
        rom = self.rom
        while True:
            if self.g(0xC31C) == 0xC9:
                return de
            a = rom[de]
            de += 1
            if a < 0x60:
                self.sf(h, 0x0C, a)
                self.sf(h, 0x02, de & 0xFF); self.sf(h, 0x03, de >> 8)
                self.set_note_freq(h, a)
                self.sf(h, 0x21, 0)
                self.do_arp(h)
                if self.f(h, 0x27):
                    self.sf(h, 0x31, self.f(h, 0x27)); self.sf(h, 0x32, 1)
                    self.sf(h, 0x29, self.f(h, 0x28))
                self.sf(h, 0x05, self.f(h, 0x0D))
                self.sf(h, 0x24, self.f(h, 0x25) >> 1)
                self.sf(h, 0x22, self.f(h, 0x26))
                self.setbit(h, 0x04, 6, 0)
                self.setbit(h, 0x04, 2, 0)
                self.sf(h, 0x0B, self.f(h, 0x17))
                for src in (0x11, 0x14):
                    v = self.f(h, src)
                    self.sf(h, src + 1, v & 0x0F)
                    self.sf(h, src + 2, v >> 4)
                raise Stop()
            de = self.command(h, a, de)

    def command(self, h, a, de):
        rom = self.rom
        if a >= 0xC7:
            self.sf(h, 0x0D, a - 0xC6)
            return de
        if a >= 0xB7:
            self.sf(h, 0x27, 0)
            self.sf(h, 0x17, a - 0xB7)
            self.sf(h, 0x11, rom[de]); self.sf(h, 0x14, rom[de + 1])
            x = rom[de + 2]
            self.sf(h, 0x1A, x >> 4); self.sf(h, 0x1B, x >> 4)
            self.sf(h, 0x1C, x & 15); self.sf(h, 0x1D, x & 15)
            return de + 3
        if a >= 0xA7:
            self.sf(h, 0x17, a - 0xA7)
            return de
        if a >= 0x98:
            t = self.g(0xC321) | (self.g(0xC322) << 8)
            p = (t + 2 * (a - 0x98)) & 0xFFFF
            self.sf(h, 0x1F, rom[p]); self.sf(h, 0x20, rom[p + 1])
            self.sf(h, 0x21, 0)
            self.setbit(h, 0x04, 0, 1)
            return de
        if a >= 0x7E:
            return self.instrument(h, a, de)
        return self.table_cmd(h, a, de, True)

    def instrument(self, h, a, de):
        rom = self.rom
        self.setbit(h, 0x04, 3, 0); self.setbit(h, 0x04, 0, 0)
        for o in (0x0E, 0x2B, 0x2E, 0x27):
            self.sf(h, o, 0)
        self.pan_c(h)
        self.set_duty(h, 0x80)
        t = self.g(0xC31F) | (self.g(0xC320) << 8)
        p = (t + (((a - 0x7D) * 2) & 0xFF)) & 0xFFFF
        ip = rom[p] | (rom[p + 1] << 8)
        self.sg(0xC31C, 0xC9)
        while True:
            b = rom[ip]
            ip += 1
            if b in (0x66, 0x68):
                self.sg(0xC31C, 0)
                return de
            if b >= 0x98:
                ip = self.command(h, b, ip)
            else:
                ip = self.table_cmd(h, b, ip, False)

    def table_cmd(self, h, a, de, in_stream):
        rom = self.rom
        if a == 0x60:
            self.sf(h, 0x0E, rom[de]); return de + 1
        if a in (0x61, 0x63):
            self.wait(h, de)
        if a == 0x62:
            self.sf(h, 0x22, rom[de]); self.sf(h, 0x23, rom[de + 1])
            self.sf(h, 0x24, rom[de + 2]); self.sf(h, 0x25, rom[de + 2])
            self.sf(h, 0x26, self.f(h, 0x22))
            self.setbit(h, 0x04, 3, 1); self.setbit(h, 0x04, 6, 1)
            return de + 3
        if a == 0x64:
            self.sf(h, 0x0B, 0)
            if h not in (C6, C7):
                self.sf(h, 0x31, 0); self.sf(h, 0x32, 1)
            self.wait(h, de)
        if a == 0x65:
            self.stop_all(); return de
        if a == 0x66:
            self.pan_c(h)
            if h == C7:
                self.restore_music_wave()
            self.reset_channel(h)
            raise Stop()
        if a == 0x67:
            self.sg(0xC31D, rom[de]); return de + 1
        if a in (0x68, 0x69):
            if a == 0x69:
                self.sf(h, 0x00, rom[de]); self.sf(h, 0x01, rom[de + 1]); de += 2
            while True:
                if self.f(h, 0x3B):
                    p = self.f(h, 0x3B) | (self.f(h, 0x3C) << 8)
                    self.sf(h, 0x3B, 0)
                    self.sf(h, 0x02, p & 0xFF); self.sf(h, 0x03, p >> 8)
                    return p
                bc = self.f(h, 0x00) | (self.f(h, 0x01) << 8)
                p = rom[bc] | (rom[bc + 1] << 8)
                bc += 2
                if p:
                    self.sf(h, 0x00, bc & 0xFF); self.sf(h, 0x01, bc >> 8)
                    self.sf(h, 0x02, p & 0xFF); self.sf(h, 0x03, p >> 8)
                    return p
                self.sf(h, 0x00, rom[bc]); self.sf(h, 0x01, rom[bc + 1])
        if a == 0x6A:
            self.sf(h, 0x0D, rom[de]); return de + 1
        if a == 0x6B:
            x = rom[de]
            if x == 0:
                self.sg(0xC32A, 0)
                return de + 1
            self.sg(0xC32B, x)
            self.sg(0xC328, rom[de + 1]); self.sg(0xC327, rom[de + 2])
            self.sg(0xC329, 0); self.sg(0xC32A, 1); self.sg(0xC32C, 1)
            return de + 3
        if a == 0x6C:
            self.pan_c(h); return de
        if a == 0x6D:
            self.pan_r(h); return de
        if a == 0x6E:
            self.pan_l(h); return de
        if a in (0x6F, 0x70, 0x71):
            self.set_duty(h, {0x6F: 0x80, 0x70: 0xC0, 0x71: 0x00}[a]); return de
        if a == 0x72:
            x = rom[de]
            self.sf(h, 0x31, x); self.sf(h, 0x32, 1); self.sf(h, 0x27, x)
            y = rom[de + 1]
            if y == 0:
                self.sf(h, 0x28, 0); self.sf(h, 0x29, 0)
                return de + 2
            self.sf(h, 0x28, y); self.sf(h, 0x29, y)
            self.sf(h, 0x2A, rom[de + 2])
            return de + 3
        if a == 0x73:
            x = rom[de]; self.sf(h, 0x2B, x); self.sf(h, 0x2C, x); self.sf(h, 0x2D, 0); return de + 1
        if a == 0x74:
            x = rom[de]; self.sf(h, 0x2E, x); self.sf(h, 0x2F, x); self.sf(h, 0x30, 0); return de + 1
        if a == 0x75:
            p = rom[de] | (rom[de + 1] << 8)
            if h == C6:
                self.sg(0xC323, rom[de]); self.sg(0xC324, rom[de + 1])
                if self.g(0xC710):
                    return de + 2
            self.load_wave(p)
            return de + 2
        if a == 0x76:
            self.sf(h, 0x0F, rom[de]); return de + 1
        if a == 0x77:
            x = rom[de]
            if x == 0:
                self.setbit(h, 0x04, 1, 0)
                return de + 1
            self.sf(h, 0x39, x); self.sf(h, 0x3A, rom[de + 1])
            self.setbit(h, 0x04, 1, 1)
            return de + 2
        if a == 0x78:
            self.setbit(h, 0x04, 0, 0); return de
        if a in (0x79, 0x7A):
            if a == 0x7A:
                r = de + 2
                self.sf(h, 0x3B, r & 0xFF); self.sf(h, 0x3C, r >> 8)
            p = rom[de] | (rom[de + 1] << 8)
            self.sf(h, 0x02, p & 0xFF); self.sf(h, 0x03, p >> 8)
            return p
        if a == 0x7B:
            self.noise_seq(0x5977, 0x597F); return de
        if a == 0x7C:
            self.noise_seq(0x5986, 0x5989); return de
        if a == 0x7D:
            self.drum_hit(7); return de
        raise ValueError('cmd %02X' % a)

    def restore_music_wave(self):
        self.reg(0x1A, 0)
        p = self.g(0xC323) | (self.g(0xC324) << 8)
        for i in range(16):
            self.reg(0x30 + i, self.rom[p + i])
        self.reg(0x1C, self.g(0xC60B))
        v = self.g(0xC31A) | 0x80
        self.reg(0x1A, v)
        self.reg(0x1E, v)

    def load_wave(self, p):
        self.reg(0x1A, 0)
        for i in range(16):
            self.reg(0x30 + i, self.rom[p + i])
        v = self.g(0xC31A) | 0x80
        self.reg(0x1A, v)
        self.reg(0x1E, v)
