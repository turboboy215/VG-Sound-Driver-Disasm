#!/usr/bin/env python3
"""Render a song with the ROM's own sound driver (runs the ARM/Thumb code in Unicorn).

  ww_emu.py ROM SONG SECONDS OUT.wav      SONG = sound id (number) or song name (e.g. m_BGM_Title_01)

Calls sndInit, sndSetReverbBase(0x23, 2, 2, 4) (as the game does), sndPlay(id), then per frame sndMain()
and 14 DMA2 interrupts (224 samples); the samples the DMA would send to the FIFOs are written to a
stereo 8-bit WAV at 13 379 Hz. Needs: pip install unicorn
"""
import sys, struct, wave
from unicorn import Uc, UC_ARCH_ARM, UC_MODE_THUMB
from unicorn.arm_const import *

STOP = 0x02030000
SND_INIT, SND_PLAY, SND_MAIN, DMA2_IRQ, SET_REVERB = 0x080F4898, 0x080F3650, 0x080F4298, 0x080F1418, 0x080F4468
RING_R, RING_L, RING_READ = 0x030065A4, 0x03007228, 0x03007210

class Emu:
    def __init__(self, rom):
        u = self.u = Uc(UC_ARCH_ARM, UC_MODE_THUMB)
        for base, size in ((0, 0x4000), (0x02000000, 0x40000), (0x03000000, 0x8000), (0x04000000, 0x1000), (0x08000000, 0x1000000)):
            u.mem_map(base, size)
        u.mem_write(0x08000000, rom)
        u.mem_write(STOP, b'\xfe\xe7')                    # b .
    def call(self, addr, *args):
        u = self.u
        for r, v in zip((UC_ARM_REG_R0, UC_ARM_REG_R1, UC_ARM_REG_R2, UC_ARM_REG_R3), args):
            u.reg_write(r, v & 0xFFFFFFFF)
        u.reg_write(UC_ARM_REG_SP, 0x03007E00)
        u.reg_write(UC_ARM_REG_LR, STOP | 1)
        u.emu_start(addr | 1, STOP, count=50_000_000)
        return u.reg_read(UC_ARM_REG_R0)
    def r8(self, a): return self.u.mem_read(a, 1)[0]
    def r16(self, a): return struct.unpack('<H', self.u.mem_read(a, 2))[0]
    def r32(self, a): return struct.unpack('<I', self.u.mem_read(a, 4))[0]

def find_id(rom, song):
    if song.isdigit(): return int(song)
    n = struct.unpack_from('<I', rom, 0x4140C8)[0]
    for i in range(n):
        e = struct.unpack_from('<I', rom, 0x4140CC + 8 * i)[0]
        if not e: continue
        nm = struct.unpack_from('<I', rom, e - 0x08000000 + 12)[0] - 0x08000000
        if rom[nm:rom.index(b'\0', nm)].decode('latin1') == song: return i
    raise SystemExit('no song named %r' % song)

def render(rom, sound_id, seconds, frame_cb=None, emu=None):
    e = emu or Emu(rom)
    e.call(SND_INIT)
    e.call(SET_REVERB, 0x23, 2, 2, 4)
    e.call(SND_PLAY, sound_id)
    ringR, ringL = e.r32(RING_R), e.r32(RING_L)
    L, R = bytearray(), bytearray()
    for f in range(int(seconds * 59.7275)):
        e.call(SND_MAIN)
        if frame_cb: frame_cb(e, f)
        for k in range(14):
            pos = e.r32(RING_READ)
            R += e.u.mem_read(ringR + pos * 4, 16); L += e.u.mem_read(ringL + pos * 4, 16)
            e.call(DMA2_IRQ)
    return e, L, R

def main():
    if len(sys.argv) != 5:
        print(__doc__); sys.exit(1)
    rom = open(sys.argv[1], 'rb').read()
    sid = find_id(rom, sys.argv[2])
    e, L, R = render(rom, sid, float(sys.argv[3]))
    w = wave.open(sys.argv[4], 'wb'); w.setnchannels(2); w.setsampwidth(1); w.setframerate(13379)
    w.writeframes(bytes(b for l, r in zip(L, R) for b in ((l + 128) & 0xFF, (r + 128) & 0xFF)))
    w.close()
    print('sound id %d -> %s (%.1f s)' % (sid, sys.argv[4], len(L) / 13379))

if __name__ == '__main__':
    main()
