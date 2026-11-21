"""Independent Python model of the Pop Up (AJG v1) sound driver.

Written from the documented behaviour (PopUp_SoundDriver.md), operating on a
64 KB memory image (same RAM layout as the game) plus a dict of the sound
registers it writes.  Compared tick by tick against the real code in PyBoy.
"""

C1, C2, C3, C4 = 0xC1, 0xC2, 0xC3, 0xC4
SFX_ID = 0xC430


class Stop(Exception):
    """ends ReadStream for this tick (wait / note / end)"""


class Abort(Exception):
    """'pop af' executed with a non-handler return on the stack: rest of SndUpdate skipped"""


class PopUpModel:
    def __init__(self, rom, mem):
        self.rom = rom
        self.m = bytearray(mem)
        self.hw = {}
        self.in_handler = False   # whether the current command was entered by 'call'

    # ---------------------------------------------------------- helpers
    def f(self, h, o):
        return self.m[(h << 8) | o]

    def sf(self, h, o, v):
        self.m[(h << 8) | o] = v & 0xFF

    def hr(self, a):
        return self.m[0xFF00 | a]

    def hw_(self, a, v):
        v &= 0xFF
        self.m[0xFF00 | a] = v
        self.hw[a] = v

    def hs(self, a, v):     # HRAM variable
        self.m[0xFF00 | a] = v & 0xFF

    def w16(self, a):
        return self.rom[a] | (self.rom[a + 1] << 8)

    def setbit(self, h, o, b, on):
        v = self.f(h, o)
        self.sf(h, o, (v | (1 << b)) if on else (v & ~(1 << b)))

    def bit(self, h, o, b):
        return (self.f(h, o) >> b) & 1

    # ---------------------------------------------------------- registers
    def write_reg(self, idx, c):
        if idx >= 13:
            return
        if idx == 0:
            self.hw_(0x13, c)
        elif idx in (1, 3, 5):
            sh = {1: 0xE5, 3: 0xE6, 5: 0xE7}[idx]
            reg = {1: 0x14, 3: 0x19, 5: 0x1E}[idx]
            c &= 7
            if self.hr(sh) != c:
                self.hs(sh, c)
                self.hw_(reg, c | 0x80)
        elif idx == 2:
            self.hw_(0x18, c)
        elif idx == 4:
            self.hw_(0x1D, c)
        elif idx in (8, 9):
            sh, reg, hi, trig = (0xE0, 0x12, 0xE5, 0x14) if idx == 8 else (0xE1, 0x17, 0xE6, 0x19)
            c &= 0x0F
            if self.hr(sh) != c:
                self.hs(sh, c)
                self.hw_(reg, (c << 4) & 0xF0)
                self.hw_(trig, self.hr(hi) | 0x80)
        elif idx == 10:
            v = self.rom[0x5988 + (c & 0x0F)]
            if self.hr(0xE2) != v:
                self.hs(0xE2, v)
                self.hw_(0x1C, v)
                self.hw_(0x1E, self.hr(0xE7) | 0x80)
        # 6, 7, 11, 12: no-ops

    # ---------------------------------------------------------- API
    def stop_all(self):
        self.hs(0xF5, 0)
        self.hs(0xED, 0xBF)
        for h in (C1, C2, C3, C4):
            self.reset_channel(h)
        self.hs(0xE9, 0)
        self.hs(0xDF, 0)
        self.hw_(0x25, 0)
        self.hs(0xF1, 0)

    def reset_channel(self, h):
        for o in (0x30, 0x0B, 0x2E, 0x34, 0x35, 0x36, 0x37, 0x38, 0x2F, 0x17, 0x18, 0x04, 0x15):
            self.sf(h, o, 0)
        self.sf(h, 0x16, 1)
        self.sf(h, 0x05, 1)

    def start_music_ch(self, h, de):
        self.reset_channel(h)
        self.sf(h, 0x30, 1)
        self.sf(h, 0x02, self.rom[de])
        self.sf(h, 0x03, self.rom[de + 1])
        de += 2
        self.sf(h, 0x00, de & 0xFF)
        self.sf(h, 0x01, de >> 8)

    def play_song(self, n):
        self.hs(0xC2, self.m[0xFFFF])   # save IE (and restore: unchanged)
        self.stop_all()
        if n == 1:
            self.start_music_ch(C1, 0x59CE)
            self.start_music_ch(C3, 0x59FC)
            self.start_music_ch(C2, 0x5A2A)
        else:
            self.start_music_ch(C3, 0x5E65)
            self.start_music_ch(C2, 0x5E6B)
            self.start_music_ch(C1, 0x5E71)
        self.hw_(0x25, 0xFF)
        self.hs(0xF1, 0xFF)

    def stop_sfx(self):
        self.hs(0xED, self.hr(0xEE))
        self.hs(0xDF, 0)
        self.reset_channel(C4)

    def play_sound(self, a, caller_h=0xD0):
        if self.hr(0xDF):
            self.sf(caller_h, 0x39, 0)
            return
        if self.m[SFX_ID]:
            self.stop_sfx()
        self.m[SFX_ID] = a
        self.hs(0xEE, self.hr(0xED))
        p = self.w16(0x5FD3 + ((2 * a) & 0xFF))
        self.sf(C4, 0x02, p & 0xFF)
        self.sf(C4, 0x03, p >> 8)
        try:
            self.read_stream(C4, p, top='playsound')
        except Stop:
            pass

    # ---------------------------------------------------------- tick
    def snd_update(self):
        self.hw_(0x24, 0xFF)
        self.hw_(0x26, 0x8F)
        try:
            for h in (C1, C2, C3, C4):
                self.channel_tick(h)
        except Abort:
            return
        if not self.hr(0xF5):
            return
        self.output(C2)
        self.output(C3)
        self.output(C4 if self.m[SFX_ID] else C1)

    def channel_tick(self, h):
        if not self.f(h, 0x30):
            return
        if not (self.hr(0xED) & self.f(h, 0x20)):
            self.hs(0xEC, self.f(h, 0x07))
        de = self.f(h, 0x02) | (self.f(h, 0x03) << 8)
        self.do_arp(h)
        self.sf(h, 0x05, self.f(h, 0x05) - 1)
        if self.f(h, 0x05) == 0:
            try:
                self.read_stream(h, de, top='tick')
            except Stop:
                pass
            return
        # glide
        if self.f(h, 0x15):
            n = (self.f(h, 0x0C) + self.f(h, 0x15)) & 0xFF
            self.sf(h, 0x0C, n)
            self.set_note_freq(h, n)
        # release point
        if self.f(h, 0x16) == self.f(h, 0x05) and self.rom[de] != 0x6B:
            self.sf(h, 0x18, 1)
            self.setbit(h, 0x04, 1, 0)
        self.do_envelope(h)
        if self.bit(h, 0x04, 1):
            self.slide_step(h)
        if self.bit(h, 0x04, 2):
            self.slide_step(h)
        self.do_vibrato(h, de)
        if self.bit(h, 0x04, 5):
            v = self.m[0xC10B]
            self.sf(h, 0x0B, v)
            lo = self.m[0xC107] + (v & 7)
            self.sf(h, 0x07, lo)
            self.sf(h, 0x09, self.m[0xC109] + (lo >> 8))

    def do_arp(self, h):
        if not self.bit(h, 0x04, 0):
            return
        while True:
            p = (self.f(h, 0x21) | (self.f(h, 0x22) << 8)) + self.f(h, 0x23)
            a = self.rom[p & 0xFFFF]
            if a == 0x73:
                self.sf(h, 0x23, 1)
                continue
            if a == 0xFF:
                self.sf(h, 0x2E, 1)
                a = 0
            else:
                self.sf(h, 0x23, self.f(h, 0x23) + 1)
            break
        self.set_note_freq(h, (a + self.f(h, 0x0C)) & 0xFF)

    def set_note_freq(self, h, a):
        c = (a + 0xF4) & 0xFF
        if h == C3:
            c = (c + 0xDC) & 0xFF
        a = (self.hr(0xE9) + c) & 0xFF
        if h == C4:
            a = (a - self.hr(0xE9)) & 0xFF
        p = 0x57AD + ((2 * a) & 0xFF)
        self.sf(h, 0x07, self.rom[p])
        self.sf(h, 0x09, self.rom[p + 1])
        if self.bit(h, 0x04, 2):
            fr = (self.f(h, 0x07) | (self.f(h, 0x09) << 8)) + (self.f(h, 0x27) | (self.f(h, 0x28) << 8))
            self.sf(h, 0x09, (fr >> 8) & 0xFF)
            self.sf(h, 0x07, fr & 0xFF)
            self.sf(h, 0x26, self.f(h, 0x29))

    def do_envelope(self, h):
        if self.f(h, 0x0F):
            self.sf(h, 0x19, self.f(h, 0x19) - 1)
            if self.f(h, 0x19):
                return
            self.sf(h, 0x19, self.f(h, 0x1A))
            self.sf(h, 0x0F, self.f(h, 0x0F) - 1)
            v = (self.f(h, 0x10) + self.f(h, 0x0B)) & 0xFF
            self.sf(h, 0x0B, 15 if v >= 15 else v)
        elif self.f(h, 0x12):
            self.sf(h, 0x1B, self.f(h, 0x1B) - 1)
            if self.f(h, 0x1B):
                return
            self.sf(h, 0x1B, self.f(h, 0x1C))
            self.sf(h, 0x12, self.f(h, 0x12) - 1)
            v = self.f(h, 0x0B) - self.f(h, 0x13)
            self.sf(h, 0x0B, max(v, 0))
        elif self.f(h, 0x18):
            self.sf(h, 0x1D, self.f(h, 0x1D) - 1)
            if self.f(h, 0x1D):
                return
            self.sf(h, 0x1D, self.f(h, 0x1E))
            v = self.f(h, 0x0B) - self.f(h, 0x17)
            self.sf(h, 0x0B, max(v, 0))

    def slide_step(self, h):
        self.sf(h, 0x26, self.f(h, 0x26) - 1)
        if self.f(h, 0x26) & 0x80:
            self.sf(h, 0x26, self.f(h, 0x26) + 1)
            return
        fr = self.f(h, 0x07) | (self.f(h, 0x09) << 8)
        st = self.f(h, 0x24) | (self.f(h, 0x25) << 8)
        if self.f(h, 0x25) & 0x80:
            fr = fr - (st & 0x7FFF)
        else:
            fr = fr + st
        self.sf(h, 0x07, fr & 0xFF)
        self.sf(h, 0x09, (fr >> 8) & 0xFF)

    def do_vibrato(self, h, de):
        if not self.bit(h, 0x04, 3):
            return
        if self.rom[de - 1] != 0x6B:
            a = (self.f(h, 0x0D) - self.f(h, 0x2A)) & 0xFF
            if a < self.f(h, 0x05):
                return
        fr = self.f(h, 0x07) | (self.f(h, 0x09) << 8)
        self.sf(h, 0x2C, self.f(h, 0x2C) - 1)
        if self.bit(h, 0x04, 6):
            if self.f(h, 0x2C) == 0:
                self.sf(h, 0x2C, self.f(h, 0x2D))
                self.setbit(h, 0x04, 6, 0)
                return
            lo = self.f(h, 0x07) + self.f(h, 0x2B)
            self.sf(h, 0x07, lo)
            if lo > 0xFF:
                self.sf(h, 0x09, self.f(h, 0x09) + 1)
        else:
            if self.f(h, 0x2C) == 0:
                self.sf(h, 0x2C, self.f(h, 0x2D))
                self.setbit(h, 0x04, 6, 1)
                return
            lo = self.f(h, 0x07) - self.f(h, 0x2B)
            self.sf(h, 0x07, lo)
            if lo < 0:
                self.sf(h, 0x09, self.f(h, 0x09) - 1)

    def vol_table(self, h):
        a = self.f(h, 0x0B)
        if not self.bit(h, 0x34, 0):
            return a
        while True:
            p = (self.f(h, 0x31) | (self.f(h, 0x32) << 8)) + self.f(h, 0x33)
            self.sf(h, 0x33, self.f(h, 0x33) + 1)
            x = self.rom[p]
            if x == 0xFF:
                self.sf(h, 0x33, self.f(h, 0x33) - 1)
                x = self.rom[p - 1]
            if x == 0x73:
                self.sf(h, 0x33, 0)
                continue
            break
        return max(a - x, 0)

    def output(self, h):
        self.write_reg(self.f(h, 0x06), self.f(h, 0x07))
        self.write_reg(self.f(h, 0x08), self.f(h, 0x09))
        e = self.f(h, 0x0A)
        c = self.vol_table(h)
        if self.f(h, 0x37):
            c = self.f(h, 0x37)
        if self.f(h, 0x2F) and c == 0x0F:
            self.write_reg(e, 0x10)
            return
        a = max(c - self.f(h, 0x38), 0)
        att = self.hr(0xEF) if (h == C4 and self.m[0xC339] == 0) else self.hr(0xF0)
        self.write_reg(e, max(a - att, 0))

    # ---------------------------------------------------------- stream
    def get_mask(self, h):
        return self.hr(0xED) | self.f(h, 0x1F) | self.f(h, 0x20)

    def store_mask(self, h, c):
        if h == C3 and self.m[SFX_ID]:
            self.hs(0xEE, c)
        else:
            self.hs(0xED, c)

    def wait(self, h, de, top):
        """Cmd_Wait tail ('pop af' + save)."""
        self.sf(h, 0x05, self.f(h, 0x0D))
        self.sf(h, 0x02, de & 0xFF)
        self.sf(h, 0x03, de >> 8)
        if not self.in_handler:
            # popped the caller of ReadStream instead of the handler return
            if top == 'tick':
                raise Abort()
            raise NotImplementedError('wait from PlaySound first tick')
        raise Stop()

    def read_stream(self, h, de, top):
        rom = self.rom
        while True:
            if self.hr(0xE8) == 0xC9:
                return de
            a = rom[de]
            de += 1
            if a < 0x60:
                if self.bit(h, 0x2E, 0):
                    self.sf(h, 0x23, 0)
                    self.sf(h, 0x2E, 0)
                if self.bit(h, 0x39, 0):
                    self.sf(h, 0x39, 0)
                    self.stop_sfx()
                    c = self.get_mask(h) & ~self.f(h, 0x1F) & 0xFF
                    self.store_mask(h, c)
                if self.bit(h, 0x3C, 0):
                    self.sf(h, 0x3C, 0)
                    self.sf(h, 0x31, self.f(h, 0x3A))
                    self.sf(h, 0x32, self.f(h, 0x3B))
                    self.sf(h, 0x34, self.f(h, 0x3D))
                if h == C1:
                    self.hs(0xF4, 1)
                self.sf(h, 0x0C, a)
                self.sf(h, 0x33, 0)
                self.sf(h, 0x02, de & 0xFF)
                self.sf(h, 0x03, de >> 8)
                self.set_note_freq(h, a)
                self.sf(h, 0x0B, self.f(h, 0x14))
                self.sf(h, 0x05, self.f(h, 0x0D))
                self.sf(h, 0x18, 0)
                self.sf(h, 0x2C, self.f(h, 0x2D) >> 1)
                for src, lo, hi in ((0x0E, 0x0F, 0x10), (0x11, 0x12, 0x13)):
                    v = self.f(h, src)
                    self.sf(h, lo, v & 0x0F)
                    self.sf(h, hi, v >> 4)
                raise Stop()
            de = self.command(h, a, de, top)

    def command(self, h, a, de, top):
        rom = self.rom
        if a >= 0xDF:
            self.sf(h, 0x0D, a - 0xDE)
            return de
        if a >= 0xCF:
            self.sf(h, 0x14, a - 0xCF)
            self.sf(h, 0x0E, rom[de])
            self.sf(h, 0x11, rom[de + 1])
            x = rom[de + 2]
            self.sf(h, 0x19, x >> 4); self.sf(h, 0x1A, x >> 4)
            self.sf(h, 0x1B, x & 15); self.sf(h, 0x1C, x & 15)
            return de + 3
        if a >= 0xBF:
            self.sf(h, 0x14, a - 0xBF)
            return de
        if a >= 0xB0:
            p = 0x5FAE + 2 * (a - 0xB0)
            self.sf(h, 0x21, rom[p]); self.sf(h, 0x22, rom[p + 1])
            self.sf(h, 0x23, 0)
            self.setbit(h, 0x04, 0, 1)
            return de
        if a >= 0x9A:
            self.sf(h, 0x39, 1)
            self.play_sound(a - 0x9A, h)
            self.in_handler = False
            self.wait(h, de, top)
        if a >= 0x80:
            return self.instrument(h, a, de, top)
        self.in_handler = True
        try:
            return self.table_cmd(h, a, de, top)
        finally:
            self.in_handler = False

    def instrument(self, h, a, de, top):
        rom = self.rom
        if a in (0x82, 0x83):
            self.hw_(0x21, 0xF1); self.hw_(0x22, 0x60); self.hw_(0x23, 0x80)
        self.setbit(h, 0x04, 3, 0)
        self.setbit(h, 0x04, 0, 0)
        self.sf(h, 0x15, 0); self.sf(h, 0x34, 0); self.sf(h, 0x3D, 0)
        idx = a - 0x7F
        p = 0x5EC2 + ((2 * idx) & 0xFF)
        ip = rom[p] | (rom[p + 1] << 8)
        self.hs(0xE8, 0xC9)
        while True:
            b = rom[ip]
            ip += 1
            if b in (0x70, 0x73):
                self.hs(0xE8, 0)
                return de
            if b >= 0xB0:
                ip = self.command(h, b, ip, 'instr')
            else:
                self.in_handler = True
                ip = self.table_cmd(h, b, ip, 'instr')
                self.in_handler = False

    def table_cmd(self, h, a, de, top):
        rom = self.rom
        if a == 0x60:
            self.sf(h, 0x15, rom[de]); return de + 1
        if a == 0x61:
            self.sf(h, 0x16, rom[de])
            x = rom[de + 1]
            self.sf(h, 0x1D, x >> 4); self.sf(h, 0x1E, x >> 4); self.sf(h, 0x17, x & 15)
            return de + 2
        if a == 0x62:
            self.setbit(h, 0x04, 0, 0); self.sf(h, 0x2E, 0); self.sf(h, 0x34, 0); return de
        if a == 0x63:
            for i in range(3):
                self.sf(h, 0x24 + i, rom[de + i])
            self.setbit(h, 0x04, 1, 1)
            return de + 3
        if a == 0x64:
            self.sf(h, 0x27, rom[de]); self.sf(h, 0x28, rom[de + 1])
            self.sf(h, 0x24, rom[de + 2]); self.sf(h, 0x25, rom[de + 3])
            self.sf(h, 0x29, rom[de + 4])
            self.setbit(h, 0x04, 2, 1)
            return de + 5
        if a == 0x65:
            self.setbit(h, 0x04, 2, 0); return de
        if a == 0x66:
            self.sf(h, 0x2A, rom[de]); self.sf(h, 0x2B, rom[de + 1])
            self.sf(h, 0x2C, rom[de + 2]); self.sf(h, 0x2D, rom[de + 2])
            self.setbit(h, 0x04, 3, 1); self.setbit(h, 0x04, 6, 1)
            return de + 3
        if a == 0x67:
            self.setbit(h, 0x04, 3, 0); return de
        if a in (0x68, 0x69, 0x6A):
            c = self.get_mask(h)
            m = {0x68: self.f(h, 0x1F), 0x69: self.f(h, 0x20), 0x6A: self.f(h, 0x1F) | self.f(h, 0x20)}[a]
            self.store_mask(h, c & ~m & 0xFF)
            return de
        if a == 0x6B:
            self.wait(h, de, top)
        if a == 0x6C:
            self.sf(h, 0x0B, 0)
            if self.f(h, 0x39):
                self.sf(h, 0x39, 0)
                self.stop_sfx()
            self.wait(h, de, top)
        if a == 0x6D:
            self.stop_all(); return de
        if a == 0x6E:
            self.setbit(h, 0x04, 5, 1); return de
        if a == 0x6F:
            self.setbit(h, 0x04, 5, 0); return de
        if a == 0x70:
            self.hs(0xED, self.hr(0xEE))
            self.hs(0xDF, 0)
            self.reset_channel(h)
            raise Stop()
        if a == 0x71:
            self.sf(h, 0x15, 0); return de
        if a == 0x72:
            self.hs(0xE9, rom[de]); return de + 1
        if a in (0x73, 0x74):
            if a == 0x74:
                self.sf(h, 0x00, rom[de]); self.sf(h, 0x01, rom[de + 1]); de += 2
            while True:
                bc = self.f(h, 0x00) | (self.f(h, 0x01) << 8)
                p = rom[bc] | (rom[bc + 1] << 8)
                bc += 2
                if p:
                    self.sf(h, 0x00, bc & 0xFF); self.sf(h, 0x01, bc >> 8)
                    self.sf(h, 0x02, p & 0xFF); self.sf(h, 0x03, p >> 8)
                    return p
                self.sf(h, 0x00, rom[bc]); self.sf(h, 0x01, rom[bc + 1])
        if a == 0x75:
            self.sf(h, 0x38, rom[de]); return de + 1
        if a == 0x76:
            self.sf(h, 0x0D, rom[de]); return de + 1
        if a == 0x77:
            self.sf(h, 0x3A, self.f(h, 0x31)); self.sf(h, 0x3B, self.f(h, 0x32)); self.sf(h, 0x3D, self.f(h, 0x34))
            self.sf(h, 0x31, 0xEF); self.sf(h, 0x32, 0x55); self.sf(h, 0x33, 0)
            self.sf(h, 0x3C, 1); self.sf(h, 0x34, 1)
            self.wait(h, de, top)
        if a == 0x78:
            self.hw_(0x21, 0xF1); self.hw_(0x22, 0x0A); self.hw_(0x20, 0x39); self.hw_(0x23, 0xC0)
            return de
        if a in (0x79, 0x7A, 0x7B):
            b, c = {0x79: (0xFF, 0x11), 0x7A: (0xEF, 0x01), 0x7B: (0xFE, 0x10)}[a]
            rot = {C2: 1, C3: 2}.get(h, 0)
            for _ in range(rot):
                b = ((b << 1) | (b >> 7)) & 0xFF
                c = ((c << 1) | (c >> 7)) & 0xFF
            v = (self.hr(0xF1) | c) & b
            self.hs(0xF1, v)
            self.hw_(0x25, v)
            return de
        if a in (0x7C, 0x7D, 0x7E):
            c = {0x7C: 0x80, 0x7D: 0xC0, 0x7E: 0x00}[a]
            if h == C2:
                self.hs(0xF3, c); self.hw_(0x16, c)
            elif h == C1:
                self.hs(0xF2, c); self.hw_(0x11, c)
            return de
        if a == 0x7F:
            self.hw_(0x21, 0xF2); self.hw_(0x22, 0x80); self.hw_(0x23, 0x80)
            return de
        raise ValueError('cmd %02X' % a)

    def snd_tick(self):
        """one iteration of the harness loop (mirrors the game's VBlank hook)"""
        if self.hr(0xF5):
            self.snd_update()
