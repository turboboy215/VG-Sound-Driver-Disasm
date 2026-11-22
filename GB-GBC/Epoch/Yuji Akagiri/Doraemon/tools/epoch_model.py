"""Python model of the Epoch sound driver, written from the documentation.
Used to check the documented format against the real code in PyBoy."""


class Track:
    def __init__(self):
        self.m = [0] * 0x20      # raw struct bytes, same layout as the driver


class Model:
    def __init__(self, g):
        self.g = g
        self.b = g['b']
        self.w = g['w']
        self.v2 = g['ver'] == 2
        self.S = g['struct']
        self.limit = g['volsteps'] - 1
        self.t = [Track() for _ in range(6)]
        self.music_id = self.sfx_id = 0
        self.mtracks = self.stracks = 0
        self.mtempo = self.stempo = 0
        self.pan = 0xFF
        self.panflag = 0
        self.mlen = self.slen = 0

    # ---- helpers on struct words
    @staticmethod
    def gw(m, o):
        return m[o] | (m[o + 1] << 8)

    @staticmethod
    def sw(m, o, v):
        m[o] = v & 0xFF
        m[o + 1] = (v >> 8) & 0xFF

    def stop_music(self):
        self.mtracks = 4
        for i in range(4):
            self.t[i].m[0] = 4

    def stop_sfx(self):
        self.stracks = 2
        for i in (4, 5):
            self.t[i].m[0] = 4

    def play(self, sfx, idx):
        w, b = self.w, self.b
        tab = self.g['sfx'] if sfx else self.g['music']
        h = w(tab + 2 * idx)
        if sfx:
            self.sfx_id = idx
            self.stracks = 2
            self.stempo = b(h)
            self.slen = w(h + 1)
            trs = (4, 5)
        else:
            self.music_id = idx
            self.mtracks = 4
            self.mtempo = b(h)
            self.mlen = w(h + 1)
            trs = (0, 1, 2, 3)
        for k, ti in enumerate(trs):
            m = self.t[ti].m
            p = w(h + 3 + 2 * k)
            m[0] = 1
            self.sw(m, 1, p)
            if p == 0:
                m[0] = 4
                continue
            self.sw(m, 3, 0)
            m[0x11] = 0
            if self.v2:
                self.sw(m, 0x1E, p)
        if sfx:
            self.panflag = 2

    # ---- SndUpdate
    def update(self):
        if self.panflag == 2:
            self.panflag = 1
        for idx in range(6):
            m = self.t[idx].m
            c = m[0] & 3
            if c == 0:
                continue
            tempo = self.mtempo if idx < 4 else self.stempo
            cnt = self.gw(m, 3) - tempo
            self.sw(m, 3, cnt)
            if cnt >= 0:
                self.envelope(m, c, tempo, idx)
                continue
            self.parse(m, idx, tempo)

    def envelope(self, m, c, tempo, idx):
        if c != 2:
            return
        mode = m[0xB]
        if mode == 0:
            return
        if mode == 1:
            m[0xD] = (m[0xD] - 1) & 0xFF
            if m[0xD]:
                return
            m[0xD] = m[0xC]
            de = (self.gw(m, 0xE) + m[0x10]) & 0xFFFF
            if m[0x10] < self.limit:
                m[0x10] += 1
            v = self.b(de)
            m[8] = (m[8] & 0x0F) | ((v << 4) & 0xF0)
            m[0] = 6
            return
        if mode == 2:
            m[0xD] = (m[0xD] - 1) & 0xFF     # never releases (driver bug)
            return
        gc = self.gw(m, 0xE) - tempo
        self.sw(m, 0xE, gc)
        if gc < 0:
            m[0] = 5

    def parse(self, m, idx, tempo):
        b, w = self.b, self.w
        de = self.gw(m, 1)
        noise = idx in (3, 5)
        while True:
            c = b(de)
            if c == 0xF0:
                k = b(de + 1)
                de += 2
                if noise:
                    continue
                p = w(self.g['inst'] + 2 * k)
                for i in range(5):
                    m[6 + i] = b(p + i)
                mode = b(p + 5)
                m[0xB] = mode
                if mode == 1:
                    m[0xC] = m[0xD] = b(p + 6)
                    self.sw(m, 0xE, p + 7)
                    m[0x10] = 0
                elif mode == 2:
                    m[0xC] = m[0xD] = b(p + 6)
                elif mode >= 3:
                    self.sw(m, 0xC, b(p + 6) * tempo)
                continue
            if c < 0xE0:
                break
            if c == 0xFF or (c == 0xFE and not self.v2 and False):
                m[0] = 4
                return                              # pointer not saved
            if c == 0xFE and self.v2:
                de = self.gw(m, 0x1E)
                m[0x11] = 0
                continue
            if c == 0xE0:
                d = m[0x11]
                m[0x11] = d + 1
                f = 0x12 + 4 * d
                m[f] = 1
                m[f + 1] = b(de + 1)
                self.sw(m, f + 2, de + 2)
                de += 2
                continue
            if c == 0xE1:
                f = 0x12 + 4 * (m[0x11] - 1)
                m[f] = (m[f] + 1) & 0xFF
                n = m[f + 1]
                if (not self.v2 and n == 0) or n - m[f] >= 0:
                    de = self.gw(m, f + 2)
                else:
                    de += 1
                    m[0x11] -= 1
                continue
            if c == 0xE2:
                f = 0x12 + 4 * (m[0x11] - 1)
                pas, n = m[f], m[f + 1]
                while True:
                    x = b(de)
                    de += 1
                    if x == 0xE2:
                        y = b(de)
                        de += 1
                        if y == pas:
                            break
                        continue
                    if x >= 0xE0:
                        if x != 0xE1:
                            de += 1
                        continue
                    if x >= 0xD0:
                        de += 2
                    if x & 0x0F == 6:
                        de += 1
                if pas == n:
                    m[0x11] -= 1
                continue
            # other command: pan
            self.pan = b(de + 1)
            self.panflag = 1
            de += 2
        # ---- row
        hi, lo = c >> 4, c & 0xF
        if hi == 0xD:
            ln = w(de + 1)
            de += 2
        else:
            lt = self.mlen if idx < 4 else self.slen
            ln = w(lt + 2 * hi)
        self.sw(m, 3, self.gw(m, 3) + (ln * 8 & 0xFFFF))
        if lo == 9:
            de += 1
            self.sw(m, 1, de)
            return
        if lo == 8:
            m[0] = 5
            de += 1
            self.sw(m, 1, de)
            return
        if lo == 6:
            de += 1
            n = b(de)
        else:
            n = (m[5] + (lo if lo < 8 else lo - 16)) & 0xFF
        m[5] = n
        if noise:
            p = self.g['drum'] + 4 * (n - 0x34)
            for i in range(4):
                m[7 + i] = b(p + i)
        else:
            f = w(self.g['freq'] - 0x20 + ((2 * n) & 0xFF))
            m[9] = f & 0xFF
            m[0xA] = (m[0xA] & 0xF8) | ((f >> 8) & 7)
            mode = m[0xB]
            if mode in (1, 2):
                m[0xD] = m[0xC]
                if mode == 1:
                    v = b(self.gw(m, 0xE))
                    m[0x10] = 0
                    m[8] = (m[8] & 0x0F) | ((v << 4) & 0xF0)
            elif mode >= 3:
                self.sw(m, 0xE, self.gw(m, 3) - self.gw(m, 0xC))
        m[0] = 6
        de += 1
        self.sw(m, 1, de)

    # ---- SndOutput (state changes only)
    def _out(self, ti, sfx):
        m = self.t[ti].m
        if m[0] < 4:
            return
        m[0] -= 4
        if m[0] == 0:
            if sfx:
                self.stracks = (self.stracks - 1) & 0xFF
                if self.stracks == 0:
                    self.panflag = 1
                    self.sfx_id = 0xFF
            else:
                self.mtracks = (self.mtracks - 1) & 0xFF
                if self.mtracks == 0:
                    self.music_id = 0xFF

    def _hold(self, ti):
        m = self.t[ti].m
        if m[0] == 4:
            m[0] = 0
            self.mtracks = (self.mtracks - 1) & 0xFF
            if self.mtracks == 0:
                self.music_id = 0xFF
        elif m[0]:
            m[0] = 1

    def output(self):
        if self.stracks == 0:
            if self.panflag == 1:
                self.panflag = 0
            for i in range(4):
                self._out(i, False)
            return
        if self.panflag == 1:
            self.panflag = 0
        self._hold(0)
        self._out(4, True)
        self._out(1, False)
        self._out(2, False)
        self._hold(3)
        self._out(5, True)
