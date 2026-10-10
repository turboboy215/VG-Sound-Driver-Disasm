# Minimal py65 harness: bank 10 at $8000, bank 4 at $A000; logs APU writes.
import sys
from py65.devices.mpu6502 import MPU
from py65.memory import ObservableMemory
class Sim:
    def __init__(s, b10, b4):
        s.mem = ObservableMemory(); s.log = []; s.frame = 0
        for i, v in enumerate(b10): s.mem[0x8000+i] = v
        for i, v in enumerate(b4): s.mem[0xA000+i] = v
        s.mem.subscribe_to_write(range(0x4000, 0x4018), s._w)
        s.cpu = MPU(memory=s.mem)
    def _w(s, a, v): s.log.append((s.frame, a, v))
    def call(s, addr, a=0, x=0, y=0):
        c = s.cpu; c.a, c.x, c.y = a, x, y
        c.sp = 0xFF; s.mem[0x1FF] = 0xFF; s.mem[0x1FE] = 0xFE  # return to $FFFF
        c.sp = 0xFD; c.pc = addr; n = 0
        while c.pc != 0xFFFF:
            c.step(); n += 1
            if n > 200000: raise RuntimeError('runaway at %04X' % c.pc)
        return n
