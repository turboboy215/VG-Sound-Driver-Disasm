"""Small SM83 interpreter for running the sound driver code from the ROM.

Only what a sound driver needs: ROM bank 0 + one switchable bank, 8 KB WRAM,
HRAM and the sound registers. Every write to $FF10-$FF3F is logged. Reads of
sound registers return the last value written (NR52 power-off clears
NR10-NR51, as on hardware).
"""


class Halt(Exception):
    pass


class CPU:
    def __init__(self, rom):
        self.rom = rom
        self.bank = 1
        self.wram = bytearray(0x2000)
        self.hram = bytearray(0x80)
        self.io = bytearray(0x80)
        self.log = []
        self.a = self.f = self.b = self.c = self.d = self.e = self.h = self.l = 0
        self.sp = 0xDFF0
        self.pc = 0
        self.steps = 0
        self.cov = None

    # ---------------------------------------------------------- memory
    def rd(self, a):
        if a < 0x4000:
            return self.rom[a]
        if a < 0x8000:
            return self.rom[self.bank * 0x4000 + a - 0x4000]
        if 0xC000 <= a < 0xE000:
            return self.wram[a - 0xC000]
        if 0xFF00 <= a < 0xFF80:
            return self.io[a - 0xFF00]
        if 0xFF80 <= a < 0xFFFF:
            return self.hram[a - 0xFF80]
        raise RuntimeError('read %04X at pc %04X' % (a, self.pc))

    def wr(self, a, v):
        v &= 0xFF
        if a < 0x8000:
            raise RuntimeError('ROM write %04X at pc %04X' % (a, self.pc))
        if 0xC000 <= a < 0xE000:
            self.wram[a - 0xC000] = v
            return
        if 0xFF10 <= a < 0xFF40:
            self.log.append((a, v))
            if a == 0xFF26:
                if not (v & 0x80):
                    for r in range(0x10, 0x26):
                        self.io[r] = 0
                self.io[0x26] = v & 0x80
                return
            if not (self.io[0x26] & 0x80) and a < 0xFF26:
                return  # registers ignore writes while sound is off
            self.io[a - 0xFF00] = v
            return
        if 0xFF80 <= a < 0xFFFF:
            self.hram[a - 0xFF80] = v
            return
        raise RuntimeError('write %04X at pc %04X' % (a, self.pc))

    # ---------------------------------------------------------- helpers
    def r8(self, i):
        return (self.b, self.c, self.d, self.e, self.h, self.l, None, self.a)[i] if i != 6 else self.rd(self.hl)

    def w8(self, i, v):
        v &= 0xFF
        if i == 0:
            self.b = v
        elif i == 1:
            self.c = v
        elif i == 2:
            self.d = v
        elif i == 3:
            self.e = v
        elif i == 4:
            self.h = v
        elif i == 5:
            self.l = v
        elif i == 6:
            self.wr(self.hl, v)
        else:
            self.a = v

    @property
    def hl(self):
        return (self.h << 8) | self.l

    @hl.setter
    def hl(self, v):
        self.h, self.l = (v >> 8) & 0xFF, v & 0xFF

    @property
    def bc(self):
        return (self.b << 8) | self.c

    @bc.setter
    def bc(self, v):
        self.b, self.c = (v >> 8) & 0xFF, v & 0xFF

    @property
    def de(self):
        return (self.d << 8) | self.e

    @de.setter
    def de(self, v):
        self.d, self.e = (v >> 8) & 0xFF, v & 0xFF

    @property
    def af(self):
        return (self.a << 8) | self.f

    @af.setter
    def af(self, v):
        self.a, self.f = (v >> 8) & 0xFF, v & 0xF0

    def get16(self, p):
        return (self.bc, self.de, self.hl, self.sp)[p]

    def set16(self, p, v):
        v &= 0xFFFF
        if p == 0:
            self.bc = v
        elif p == 1:
            self.de = v
        elif p == 2:
            self.hl = v
        else:
            self.sp = v

    def flags(self, z, n, h, c):
        self.f = (0x80 if z else 0) | (0x40 if n else 0) | (0x20 if h else 0) | (0x10 if c else 0)

    def fz(self):
        return bool(self.f & 0x80)

    def fc(self):
        return bool(self.f & 0x10)

    def cond(self, y):
        return (not self.fz(), self.fz(), not self.fc(), self.fc())[y]

    def imm8(self):
        v = self.rd(self.pc)
        self.pc = (self.pc + 1) & 0xFFFF
        return v

    def imm16(self):
        lo = self.imm8()
        return lo | (self.imm8() << 8)

    def push(self, v):
        self.sp = (self.sp - 1) & 0xFFFF
        self.wr(self.sp, v >> 8)
        self.sp = (self.sp - 1) & 0xFFFF
        self.wr(self.sp, v & 0xFF)

    def pop(self):
        lo = self.rd(self.sp)
        hi = self.rd((self.sp + 1) & 0xFFFF)
        self.sp = (self.sp + 2) & 0xFFFF
        return lo | (hi << 8)

    def alu(self, y, v):
        a = self.a
        cin = 1 if self.fc() else 0
        if y in (0, 1):
            c = cin if y == 1 else 0
            r = a + v + c
            self.flags((r & 0xFF) == 0, 0, ((a & 15) + (v & 15) + c) > 15, r > 0xFF)
            self.a = r & 0xFF
        elif y in (2, 3, 7):
            c = cin if y == 3 else 0
            r = a - v - c
            self.flags((r & 0xFF) == 0, 1, ((a & 15) - (v & 15) - c) < 0, r < 0)
            if y != 7:
                self.a = r & 0xFF
        elif y == 4:
            self.a = a & v
            self.flags(self.a == 0, 0, 1, 0)
        elif y == 5:
            self.a = a ^ v
            self.flags(self.a == 0, 0, 0, 0)
        elif y == 6:
            self.a = a | v
            self.flags(self.a == 0, 0, 0, 0)

    # ---------------------------------------------------------- execution
    def call(self, addr, max_steps=2000000):
        """call addr with a sentinel return address; run until it returns"""
        self.push(0xFFFE)
        self.pc = addr
        n = 0
        while self.pc != 0xFFFE:
            self.step()
            n += 1
            if n > max_steps:
                raise Halt('no return after %d steps (pc %04X)' % (n, self.pc))
        return n

    def step(self):
        if self.cov is not None:
            self.cov.add((self.bank, self.pc))
        op = self.imm8()
        x, y, z = op >> 6, (op >> 3) & 7, op & 7
        p, q = y >> 1, y & 1
        if op == 0xCB:
            cb = self.imm8()
            x2, y2, z2 = cb >> 6, (cb >> 3) & 7, cb & 7
            v = self.r8(z2)
            if x2 == 0:
                c = self.fc()
                if y2 == 0:
                    r = ((v << 1) | (v >> 7)) & 0xFF
                    co = v >> 7
                elif y2 == 1:
                    r = ((v >> 1) | (v << 7)) & 0xFF
                    co = v & 1
                elif y2 == 2:
                    r = ((v << 1) | c) & 0xFF
                    co = v >> 7
                elif y2 == 3:
                    r = (v >> 1) | (c << 7)
                    co = v & 1
                elif y2 == 4:
                    r = (v << 1) & 0xFF
                    co = v >> 7
                elif y2 == 5:
                    r = (v >> 1) | (v & 0x80)
                    co = v & 1
                elif y2 == 6:
                    r = ((v << 4) | (v >> 4)) & 0xFF
                    co = 0
                else:
                    r = v >> 1
                    co = v & 1
                self.flags(r == 0, 0, 0, co)
                self.w8(z2, r)
            elif x2 == 1:
                self.f = (self.f & 0x10) | 0x20 | (0 if (v >> y2) & 1 else 0x80)
            elif x2 == 2:
                self.w8(z2, v & ~(1 << y2))
            else:
                self.w8(z2, v | (1 << y2))
            return
        if x == 1:
            if op == 0x76:
                raise Halt('halt')
            self.w8(y, self.r8(z))
            return
        if x == 2:
            self.alu(y, self.r8(z))
            return
        if x == 0:
            if z == 0:
                if y == 0:
                    return
                if y == 3 or y >= 4:
                    off = self.imm8()
                    off = off - 256 if off > 127 else off
                    if y == 3 or self.cond(y - 4):
                        self.pc = (self.pc + off) & 0xFFFF
                    return
                raise RuntimeError('op %02X' % op)
            if z == 1:
                if q == 0:
                    self.set16(p, self.imm16())
                else:
                    hl, v = self.hl, self.get16(p)
                    r = hl + v
                    self.f = (self.f & 0x80) | (0x20 if ((hl & 0xFFF) + (v & 0xFFF)) > 0xFFF else 0) | (0x10 if r > 0xFFFF else 0)
                    self.hl = r & 0xFFFF
                return
            if z == 2:
                if p == 0:
                    ad = self.bc
                elif p == 1:
                    ad = self.de
                else:
                    ad = self.hl
                    self.hl = (ad + (1 if p == 2 else -1)) & 0xFFFF
                if q == 0:
                    self.wr(ad, self.a)
                else:
                    self.a = self.rd(ad)
                return
            if z == 3:
                self.set16(p, self.get16(p) + (1 if q == 0 else -1))
                return
            if z in (4, 5):
                v = self.r8(y)
                if z == 4:
                    r = (v + 1) & 0xFF
                    self.f = (self.f & 0x10) | (0x80 if r == 0 else 0) | (0x20 if (v & 15) == 15 else 0)
                else:
                    r = (v - 1) & 0xFF
                    self.f = (self.f & 0x10) | 0x40 | (0x80 if r == 0 else 0) | (0x20 if (v & 15) == 0 else 0)
                self.w8(y, r)
                return
            if z == 6:
                self.w8(y, self.imm8())
                return
            if z == 7:
                a = self.a
                if y == 0:
                    self.a = ((a << 1) | (a >> 7)) & 0xFF
                    self.flags(0, 0, 0, a >> 7)
                elif y == 1:
                    self.a = ((a >> 1) | (a << 7)) & 0xFF
                    self.flags(0, 0, 0, a & 1)
                elif y == 2:
                    self.a = ((a << 1) | (1 if self.fc() else 0)) & 0xFF
                    self.flags(0, 0, 0, a >> 7)
                elif y == 3:
                    self.a = (a >> 1) | (0x80 if self.fc() else 0)
                    self.flags(0, 0, 0, a & 1)
                elif y == 5:
                    self.a = a ^ 0xFF
                    self.f |= 0x60
                elif y == 6:
                    self.f = (self.f & 0x80) | 0x10
                elif y == 7:
                    self.f = (self.f & 0x80) | (0 if self.fc() else 0x10)
                else:
                    raise RuntimeError('daa')
                return
        # x == 3
        if z == 0:
            if y < 4:
                if self.cond(y):
                    self.pc = self.pop()
                return
            if y == 4:
                self.wr(0xFF00 + self.imm8(), self.a)
                return
            if y == 6:
                self.a = self.rd(0xFF00 + self.imm8())
                return
            raise RuntimeError('op %02X' % op)
        if z == 1:
            if q == 0:
                v = self.pop()
                if p == 3:
                    self.af = v
                else:
                    self.set16(p, v)
                return
            if p == 0:
                self.pc = self.pop()
                return
            if p == 2:
                self.pc = self.hl
                return
            raise RuntimeError('op %02X' % op)
        if z == 2:
            if y < 4:
                t = self.imm16()
                if self.cond(y):
                    self.pc = t
                return
            if y == 5:
                self.wr(self.imm16(), self.a)
                return
            if y == 7:
                self.a = self.rd(self.imm16())
                return
            if y == 4:
                self.wr(0xFF00 + self.c, self.a)
                return
            if y == 6:
                self.a = self.rd(0xFF00 + self.c)
                return
        if z == 3:
            if y == 0:
                self.pc = self.imm16()
                return
            if y in (6, 7):
                return  # di / ei
            raise RuntimeError('op %02X' % op)
        if z == 4:
            t = self.imm16()
            if y < 4 and self.cond(y):
                self.push(self.pc)
                self.pc = t
            elif y >= 4:
                raise RuntimeError('op %02X' % op)
            return
        if z == 5:
            if q == 0:
                self.push(self.af if p == 3 else self.get16(p))
                return
            if p == 0:
                t = self.imm16()
                self.push(self.pc)
                self.pc = t
                return
            raise RuntimeError('op %02X' % op)
        if z == 6:
            self.alu(y, self.imm8())
            return
        self.push(self.pc)
        self.pc = y * 8
