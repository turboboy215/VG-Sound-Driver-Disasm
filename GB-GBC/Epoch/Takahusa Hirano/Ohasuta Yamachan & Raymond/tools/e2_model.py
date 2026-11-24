"""Python model of the Epoch type-2 music and SFX drivers, written from
Epoch2_SoundDriver.md. It keeps the driver RAM (256 bytes at SOUND_RAM plus
one spare page for buffer overruns), the sound registers and a log of every
register write, so it can be compared with the real code run by e2_cpu.py.
"""

NR = dict(NR10=0xFF10, NR11=0xFF11, NR12=0xFF12, NR13=0xFF13, NR14=0xFF14,
          NR21=0xFF16, NR22=0xFF17, NR23=0xFF18, NR24=0xFF19,
          NR30=0xFF1A, NR31=0xFF1B, NR32=0xFF1C, NR33=0xFF1D, NR34=0xFF1E,
          NR42=0xFF21, NR43=0xFF22, NR44=0xFF23, NR50=0xFF24, NR51=0xFF25, NR52=0xFF26)
VOLREG = [0xFF12, 0xFF17, None, 0xFF21]
LOREG = [0xFF13, 0xFF18, 0xFF1D]
HIREG = [0xFF14, 0xFF19, 0xFF1E]
END_FLAG = [0x03, 0x0C, 0x30, 0xC0]


class Hang(Exception):
    pass


class Machine:
    """shared state: RAM page(s), sound registers, write log"""

    def __init__(self, ram_base):
        self.base = ram_base
        self.ram = bytearray(0x200)
        self.io = bytearray(0x80)
        self.io[0x26] = 0x80
        self.log = []

    def w(self, reg, v):
        v &= 0xFF
        self.log.append((reg, v))
        if reg == 0xFF26:
            if not (v & 0x80):
                for r in range(0x10, 0x26):
                    self.io[r] = 0
            self.io[0x26] = v & 0x80
            return
        if not (self.io[0x26] & 0x80) and reg < 0xFF26:
            return
        self.io[reg - 0xFF00] = v

    def r(self, reg):
        return self.io[reg - 0xFF00]


class Driver:
    """one copy of the driver: music (sfx=False) or SFX (sfx=True)"""

    def __init__(self, m, rom, bank, tables, version, sfx):
        self.m, self.rom, self.bank, self.T, self.v, self.sfx = m, rom, bank, tables, version, sfx
        o = 0x85 if sfx else 0x00
        # RAM layout (offsets)
        if sfx:
            self.ID = 0x01
            self.HDR = (0x85, 0x86)
            self.ENV = [0x87, 0x89]
            self.REST = [0x88, 0x8A]
            self.LEVEL, self.WFLAG = 0x8B, 0x8C
            self.D42, self.D43, self.D44 = 0x8D, 0x8E, 0x8F
            self.CNT = 0x90
            self.FREQ = 0x94
            self.PTR = 0x9A
            self.LOOP = 0xA2
            self.END = 0xAA
            self.MODE = 0xAE
            self.DLY, self.DLYI, self.MCNT, self.MCNTI = 0xB1, 0xB4, 0xB7, 0xBA
            self.MPTR = 0xBD
            self.BUF = [0xC3, 0xD5, 0xE7]
            self.ENDP = (0xFC, 0xFD)
            self.BUSY = 0xF9
        else:
            self.ID = 0x00
            self.HDR = (0x02, 0x03)
            self.ENV = [0x04, 0x06]
            self.REST = [0x05, 0x07]
            self.LEVEL, self.WFLAG = 0x08, 0x09
            self.D42, self.D43, self.D44 = 0x0A, 0x0B, 0x0C
            self.CNT = 0x0D
            self.FREQ = 0x11
            self.PTR = 0x17
            self.LOOP = 0x1F
            self.END = 0x27
            self.MODE = 0x2B
            self.DLY, self.DLYI, self.MCNT, self.MCNTI = 0x2E, 0x31, 0x34, 0x37
            self.MPTR = 0x3A
            self.BUF = [0x4E, 0x60, 0x72]
            self.ENDP = (0xFA, 0xFB)
            self.BUSY = 0xF8
            self.INST = 0x44
            self.PAN = 0x4A
            self.NOISEP = 0xFE
        del o

    # ------------------------------------------------------------ helpers
    def rb(self, a):
        a &= 0xFFFF
        if a < 0x4000:
            return self.rom[a]
        if a < 0x8000:
            return self.rom[self.bank * 0x4000 + a - 0x4000]
        return self.read_ram(a)

    def read_ram(self, a):
        # only reached by garbage pointers; RAM/IO the way e2_cpu sees it
        raise Hang('read of $%04X outside ROM' % a)

    def R(self, off):
        return self.m.ram[off]

    def W(self, off, v):
        self.m.ram[off] = v & 0xFF

    def get16be(self, off):
        return (self.R(off) << 8) | self.R(off + 1)

    def set16be(self, off, v):
        self.W(off, v >> 8)
        self.W(off + 1, v)

    def lock(self, k):
        return self.R(0x40 + k)

    def set_lock(self, k, v):
        self.W(0x40 + k, v)

    def ram_addr_to_off(self, a):
        return a - self.m.base

    # ------------------------------------------------------------ init
    def init(self):
        m = self.m
        if self.v == 'C':
            self.W(self.BUSY, 1)
        if not self.sfx:
            if self.v in 'AB':
                m.w(NR['NR52'], 0)
                m.w(NR['NR52'], 0x80)
            else:
                if self.lock(0) != 1:
                    m.w(NR['NR12'], 0)
                if self.lock(1) != 1:
                    m.w(NR['NR22'], 0)
                if self.lock(2) != 1:
                    m.w(NR['NR30'], 0)
                if self.lock(3) != 1:
                    m.w(NR['NR42'], 0)
                    m.w(NR['NR43'], 0)
                m.w(NR['NR52'], 0x80)
            m.w(NR['NR50'], 0x77)
            m.w(NR['NR51'], 0xFF)
        idx = self.R(self.ID)
        tbl = 0x4006
        for i in range(idx + 1):
            lo, hi = self.rb(tbl + 2 * i), self.rb(tbl + 2 * i + 1)
        self.W(self.HDR[1], lo)
        self.W(self.HDR[0], hi)
        hdr = lo | (hi << 8)
        for k in range(4):
            off = self.rb(hdr + 2 * k) | (self.rb(hdr + 2 * k + 1) << 8)
            self.set16be(self.PTR + 2 * k, (off + hdr) & 0xFFFF)
        # word 5: stored lo, hi then read back as hi, lo
        lo5, hi5 = self.rb(hdr + 8), self.rb(hdr + 9)
        v = (((lo5 << 8) | hi5) + hdr) & 0xFFFF
        self.W(self.ENDP[0], v >> 8)
        self.W(self.ENDP[1], v)
        for k in range(4):
            self.W(self.CNT + k, 0)
            self.W(self.END + k, 0)
        for k in range(3):
            self.W(self.MODE + k, 0)
        if self.sfx:
            for k in range(4):
                self.set_lock(k, 2)
        else:
            if self.v in 'AB':
                for k in range(4):
                    self.set_lock(k, 0)
            for k in range(4):
                self.W(self.PAN + k, 0)
        if self.v == 'C':
            self.W(self.BUSY, 0)

    # ------------------------------------------------------------ update
    def update(self):
        if self.v == 'C' and self.R(self.BUSY) == 1:
            return
        if self.R(self.ID) == 0xFF:
            return
        for k in range(4):
            self.channel(k)
        if (self.R(self.END) | self.R(self.END + 1) | self.R(self.END + 2) | self.R(self.END + 3)) == 0xFF:
            self.W(self.ID, 0xFF)

    def channel(self, k):
        if self.R(self.END + k):
            return
        cnt = self.R(self.CNT + k)
        if cnt:
            self.W(self.CNT + k, cnt - 1)
            if k == 3:
                return
            if not self.sfx:
                lk = self.lock(k)
                if (lk == 1) if self.v == 'C' else (lk != 0):
                    return
            if self.R(self.MODE + k) == 0:
                return
            d = self.R(self.DLY + k)
            if d:
                self.W(self.DLY + k, d - 1)
                return
            self.modulate(k)
            return
        steps = 0
        while True:
            steps += 1
            if steps > 10000:
                raise Hang('ch%d' % (k + 1))
            p = self.get16be(self.PTR + 2 * k)
            c = self.rb(p)
            if c == 0xFF:
                x = self.rb(p + 1)
                if x == 0:
                    self.set16be(self.PTR + 2 * k, p + 2)
                    self.set16be(self.LOOP + 2 * k, p + 2)
                    continue
                if x == 1:
                    self.set16be(self.PTR + 2 * k, self.get16be(self.LOOP + 2 * k))
                    continue
                if x == 0xFF:
                    self.W(self.END + k, END_FLAG[k])
                    if self.sfx:
                        if self.v == 'A' or self.lock(k) != 0:
                            self.set_lock(k, 2)
                    return
                raise Hang('$FF $%02X' % x)
            if c == 0xE0:
                self.rest(k)
                self.length(k, p + 1)
                return
            if c == 0xF1:
                if self.sfx and self.v == 'C':
                    self.set_lock(k, 1)
                self.pan_cmd(k, self.rb(p + 1))
                self.set16be(self.PTR + 2 * k, p + 2)
                continue
            if c == 0xF2 and k != 3:
                if self.sfx and self.v == 'C':
                    self.set_lock(k, 1)
                self.mod_cmd(k, p)
                continue
            if c == 0xF0:
                if k == 3:
                    raise Hang('$F0 on ch4')
                if self.sfx and self.v == 'C':
                    self.set_lock(k, 1)
                self.inst_cmd(k, self.rb(p + 1))
                self.set16be(self.PTR + 2 * k, p + 2)
                continue
            self.note(k, c, self.rb(p + 1))
            self.length(k, p + 2)
            return

    def length(self, k, q):
        self.W(self.CNT + k, self.rb(q) - 1)
        self.set16be(self.PTR + 2 * k, q + 1)
        if k < 3:
            self.set16be(self.MPTR + 2 * k, self.m.base + self.BUF[k])
            self.W(self.DLY + k, self.R(self.DLYI + k))
            self.W(self.MCNT + k, self.R(self.MCNTI + k))

    # ------------------------------------------------------------ rows
    def freq(self, c):
        idx = (c + (0 if self.sfx else 1)) & 0xFF
        a = self.T['freq'] - 2 + 2 * idx
        return self.rb(a) | (self.rb(a + 1) << 8)

    def note(self, k, c, vol):
        m = self.m
        if k == 3:
            self.load_drum(c)
            lk = self.lock(3)
            if not self.sfx:
                if lk == 1:
                    return
                if lk == 2:
                    self.restore(3)
            m.w(NR['NR42'], (m.r(NR['NR42']) & 0x0F) | ((vol << 4) & 0xF0))
            m.w(NR['NR44'], self.R(self.D44) | 0x80)
            if self.sfx:
                self.set_lock(3, 1)
            return
        f = self.freq(c)
        self.W(self.FREQ + 2 * k, f)
        self.W(self.FREQ + 2 * k + 1, f >> 8)
        if k == 2:
            if self.sfx:
                m.w(NR['NR30'], 0)
                if self.v in 'BC':
                    m.w(NR['NR31'], 0)
                m.w(NR['NR32'], self.R(self.LEVEL))
                m.w(NR['NR30'], 0x80)
                m.w(NR['NR33'], f)
                m.w(NR['NR34'], (f >> 8) | 0x80)
                self.set_lock(2, 1)
                return
            m.w(NR['NR30'], 0)
            m.w(NR['NR31'], 0)
            lk = self.lock(2)
            if lk == 1:
                return
            if lk == 2:
                self.restore(2)
            m.w(NR['NR32'], self.R(self.LEVEL))
            m.w(NR['NR33'], f)
            m.w(NR['NR30'], 0x80)
            m.w(NR['NR34'], (f >> 8) | 0x80)
            return
        if not self.sfx:
            lk = self.lock(k)
            if lk == 1:
                return
            if lk == 2:
                self.restore(k)
        vr = VOLREG[k]
        m.w(vr, (m.r(vr) & 0x0F) | ((vol << 4) & 0xF0))
        m.w(LOREG[k], f)
        m.w(HIREG[k], (f >> 8) | 0x80)
        if self.sfx:
            self.set_lock(k, 1)

    def rest(self, k):
        m = self.m
        if k < 2:
            rb = self.R(self.REST[k])
            if rb == 0:
                return
            if not self.sfx and self.lock(k) == 1:
                return
            vr = VOLREG[k]
            m.w(vr, 0)
            m.w(vr, self.R(self.ENV[k]))
            m.w(HIREG[k], rb)
        elif k == 2:
            if self.R(self.WFLAG) == 0:
                return
            if not self.sfx and self.lock(2) == 1:
                return
            m.w(NR['NR30'], 0)
        else:
            if self.R(self.D44) == 0:
                return
            if not self.sfx and self.lock(3) == 1:
                return
            m.w(NR['NR42'], 0)
            m.w(NR['NR43'], 0)
            m.w(NR['NR42'], self.R(self.D42))
            m.w(NR['NR43'], self.R(self.D43))
            m.w(NR['NR44'], self.R(self.D44))
        if self.sfx:
            self.set_lock(k, 2)
            if self.v == 'C' and k < 3:
                self.W(self.MODE + k, 0)

    # ------------------------------------------------------------ commands
    def apply_pan(self, k, v, cmd):
        """cmd=True: $F1 handler; False: music restore"""
        m = self.m
        both, rbit, lbit = 0x11 << k, 1 << k, 0x10 << k
        if self.v == 'C' and not (self.sfx and cmd):
            if v == 0:
                m.w(NR['NR51'], m.r(NR['NR51']) | both)
            elif v == 1:
                m.w(NR['NR51'], (m.r(NR['NR51']) | both) & ~rbit)
            elif v == 2:
                m.w(NR['NR51'], (m.r(NR['NR51']) | both) & ~lbit)
            return
        if cmd:
            m.w(NR['NR51'], m.r(NR['NR51']) | both)
        elif v == 0:
            m.w(NR['NR51'], m.r(NR['NR51']) | both)
        if v == 1:
            m.w(NR['NR51'], m.r(NR['NR51']) & ~rbit)
        elif v == 2:
            m.w(NR['NR51'], m.r(NR['NR51']) & ~lbit)

    def pan_cmd(self, k, v):
        if self.sfx:
            self.apply_pan(k, v, True)
            return
        self.W(self.PAN + k, v)
        if self.lock(k) == 0:
            self.apply_pan(k, v, True)

    def mod_cmd(self, k, p):
        mode = self.rb(p + 1)
        self.W(self.MODE + k, mode)
        if mode == 0:
            self.set16be(self.PTR + 2 * k, p + 2)
            return
        self.W(self.DLY + k, self.rb(p + 2))
        self.W(self.DLYI + k, self.rb(p + 2))
        n = self.rb(p + 3)
        self.W(self.MCNT + k, n)
        self.W(self.MCNTI + k, n)
        self.set16be(self.MPTR + 2 * k, self.m.base + self.BUF[k])
        cnt = n if n else 256
        for i in range(cnt):
            self.m.ram[self.BUF[k] + i] = self.rb(p + 4 + i)
        self.set16be(self.PTR + 2 * k, p + 4 + cnt)

    def table_for(self, k):
        if k == 0:
            return self.T['inst1'], 4
        if k == 1:
            return self.T['inst2'], 3
        return self.T['wave'], 18

    def inst_cmd(self, k, n):
        m = self.m
        base, size = self.table_for(k)
        e = (base + n * size) & 0xFFFF
        if not self.sfx:
            self.set16be(self.INST + 2 * k, e)
            if self.lock(k) != 0:
                return
        self.load_inst(k, e)

    def load_inst(self, k, e):
        m = self.m
        b = [self.rb(e + i) for i in range(18 if k == 2 else 4)]
        if k == 0:
            m.w(NR['NR10'], b[0])
            m.w(NR['NR11'], b[1])
            m.w(NR['NR12'], b[2])
            self.W(self.ENV[0], b[2])
            self.W(self.REST[0], b[3])
        elif k == 1:
            m.w(NR['NR21'], b[0])
            m.w(NR['NR22'], b[1])
            self.W(self.ENV[1], b[1])
            self.W(self.REST[1], b[2])
        else:
            if self.v in 'BC':
                m.w(NR['NR30'], 0)
            self.W(self.LEVEL, b[0])
            self.W(self.WFLAG, b[1])
            for i in range(16):
                m.w(0xFF30 + i, b[2 + i])
            m.w(NR['NR30'], 0x80)

    def load_drum(self, c):
        m = self.m
        e = (self.T['noise'] + 3 * c) & 0xFFFF
        if not self.sfx:
            self.set16be(self.NOISEP, e)
            if self.lock(3) != 0:
                return
        b = [self.rb(e + i) for i in range(3)]
        m.w(NR['NR42'], b[0])
        self.W(self.D42, b[0])
        m.w(NR['NR43'], b[1])
        self.W(self.D43, b[1])
        self.W(self.D44, b[2])

    def restore(self, k):
        """music only: lock was 2 at a note"""
        self.apply_pan(k, self.R(self.PAN + k), False)
        if k < 3:
            self.load_inst(k, self.get16be(self.INST + 2 * k))
            if self.v in 'BC':
                self.set16be(self.MPTR + 2 * k, self.m.base + self.BUF[k])
                self.W(self.DLY + k, self.R(self.DLYI + k))
                self.W(self.MCNT + k, self.R(self.MCNTI + k))
        else:
            e = self.get16be(self.NOISEP)
            b = [self.rb(e + i) for i in range(3)]
            self.m.w(NR['NR42'], b[0])
            self.W(self.D42, b[0])
            self.m.w(NR['NR43'], b[1])
            self.W(self.D43, b[1])
            self.W(self.D44, b[2])
        self.set_lock(k, 0)

    # ------------------------------------------------------------ modulation
    def modulate(self, k):
        m = self.m
        mode = self.R(self.MODE + k)
        sub = mode in (3, 5)
        guard = 0
        while True:
            guard += 1
            if guard > 3:
                raise Hang('empty modulation list')
            n = self.R(self.MCNT + k)
            if n:
                self.W(self.MCNT + k, n - 1)
                mp = self.get16be(self.MPTR + 2 * k)
                d = self.m.ram[mp - self.m.base]
                lo, hi = self.R(self.FREQ + 2 * k), self.R(self.FREQ + 2 * k + 1)
                r = lo - d if sub else lo + d
                m.w(LOREG[k], r)
                if r < 0:
                    m.w(HIREG[k], hi - 1)
                elif r > 0xFF:
                    m.w(HIREG[k], hi + 1)
                self.set16be(self.MPTR + 2 * k, mp + 1)
                return
            if mode in (4, 5):
                return
            self.set16be(self.MPTR + 2 * k, self.m.base + self.BUF[k])
            self.W(self.MCNT + k, self.R(self.MCNTI + k))
