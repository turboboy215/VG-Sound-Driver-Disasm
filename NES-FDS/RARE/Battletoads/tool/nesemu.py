"""Minimal AxROM NES harness on py65 for tracing sound code (no real PPU)."""
import sys
from py65.devices.mpu6502 import MPU

CYC_FRAME = 29781
VBL_START = 27393   # cycles into frame where vblank begins (approx. scanline 241)

class Mem:
    def __init__(self, nes): self.nes = nes
    def __getitem__(self, a):
        if isinstance(a, slice):
            return [self[i] for i in range(a.start, a.stop)]
        return self.nes.read(a)
    def __setitem__(self, a, v):
        self.nes.write(a, v)
    def __len__(self): return 0x10000

class NES:
    def __init__(self, prg):
        self.prg = prg
        self.bank = 0
        self.ram = bytearray(0x800)
        self.ppuctrl = 0
        self.vbl = False
        self.apu_log = []     # (frame, cycle, reg, val, pc)
        self.exec_hook = None
        self.mem = Mem(self)
        self.cpu = MPU(memory=self.mem)
        self.frame = 0
        self.frame_start = 0
        self.nmi_pending = False
        self.reads = {}       # rom reads per bank: addr->count
        self.track_reads = False
        self.cpu.pc = self.read(0xFFFC) | self.read(0xFFFD) << 8
        self.joy = 0
        self.joy_shift = 0
    def cyc(self): return self.cpu.processorCycles - self.frame_start
    def read(self, a):
        a &= 0xFFFF
        if a < 0x2000: return self.ram[a & 0x7FF]
        if a < 0x4000:
            r = a & 7
            if r == 2:
                c = self.cyc()
                v = 0
                if self.vbl: v |= 0x80; self.vbl = False
                if 3000 < c < VBL_START: v |= 0x40     # sprite-0 hit during render
                return v
            return 0
        if a < 0x8000:
            if a == 0x4016:
                v = (self.joy >> (7 - self.joy_shift)) & 1 if self.joy_shift < 8 else 1
                self.joy_shift += 1
                return v | 0x40
            if a == 0x4015: return 0
            return 0
        off = self.bank * 0x8000 + (a - 0x8000)
        if self.track_reads:
            k = (self.bank, a); self.reads[k] = self.reads.get(k, 0) + 1
        return self.prg[off]
    def write(self, a, v):
        a &= 0xFFFF
        if a < 0x2000: self.ram[a & 0x7FF] = v; return
        if a < 0x4000:
            if a & 7 == 0:
                if v & 0x80 and not self.ppuctrl & 0x80 and self.vbl: self.nmi_pending = True
                self.ppuctrl = v
            return
        if a < 0x4020:
            if a == 0x4016:
                if v & 1: self.joy_shift = 0
                return
            self.apu_log.append((self.frame, self.cyc(), a, v, self.cpu.pc, self.bank))
            return
        if a >= 0x8000:
            # bus conflict: AND with ROM byte
            rom = self.prg[self.bank * 0x8000 + (a - 0x8000)]
            self.bank = (v & rom) & 7
    def nmi(self):
        c = self.cpu
        c.stPushWord(c.pc)
        c.stPush(c.p & ~c.BREAK | c.UNUSED)
        c.p |= c.INTERRUPT
        c.pc = self.read(0xFFFA) | self.read(0xFFFB) << 8
    def step(self):
        if self.exec_hook: self.exec_hook(self)
        self.cpu.step()
        c = self.cyc()
        if not self.in_vbl_started and c >= VBL_START:
            self.in_vbl_started = True
            self.vbl = True
            if self.ppuctrl & 0x80: self.nmi_pending = True
        if c >= CYC_FRAME:
            self.frame += 1
            self.frame_start += CYC_FRAME
            self.in_vbl_started = False
            self.vbl = False
        if self.nmi_pending:
            self.nmi_pending = False
            self.nmi()
    in_vbl_started = False
    def run_frames(self, n):
        target = self.frame + n
        while self.frame < target:
            self.step()

def load(path):
    d = open(path, 'rb').read()
    return d[16:16 + 0x40000]
