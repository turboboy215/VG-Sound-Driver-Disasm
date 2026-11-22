import os
# Python model of the Agenda sound driver, written from Agenda_SoundDriver.md.
# Keeps the driver RAM (struct page + save page + 16 HRAM bytes) and the sound
# registers it writes. agenda_pyboy_check.py compares it with the real code.
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from agenda_cfg import load

CHANNEL_MASK = [0xFE, 0xFD, 0xFB, 0xF7]


class Model:
    def __init__(s, g):
        c = s.c = load(g)
        s.v2 = c['version'] == 2
        s.rest = c['rest']
        s.page = bytearray(0x100)      # wSndTracks page
        s.save = bytearray(0x100)      # wSndSave page
        s.h = bytearray(16)            # HRAM
        s.reg = {}                     # last value written to each $FFxx register
        s.wave = bytearray(16)

    # ---- helpers
    def rom(s, a): return s.c['b'](a & 0xFFFF)
    def romw(s, a): return s.rom(a) | s.rom(a + 1) << 8
    def H(s, i): return s.h[i]
    def SH(s, i, v): s.h[i] = v & 0xFF
    @property
    def ch(s): return s.h[0]
    @property
    def o(s): return s.h[1]
    def get(s, off): return s.page[(s.o + off) & 0xFF]
    def set(s, off, v): s.page[(s.o + off) & 0xFF] = v & 0xFF
    def getw(s, off): return s.get(off) | s.get(off + 1) << 8
    def setw(s, off, v): s.set(off, v); s.set(off + 1, v >> 8)
    def wr(s, r, v):
        s.reg[r] = v & 0xFF
    def rdreg(s, r): return s.reg.get(r, 0)

    def regs(s):
        ch = s.ch
        if ch == 0: return 0x81, 0x13
        if ch == 1: return 0x82, 0x18
        if ch == 2: return 0x84, 0x1D
        return 0x88, 0x22

    # ---- entry points
    def init(s):
        s.wr(0x26, 0); s.wr(0x26, 0x8F); s.wr(0x25, 0xFF); s.wr(0x24, 0x77)
        for i in range(0x14): s.wr(0x10 + i, s.rom(s.c['init_regs'] + i))
        s.h[4] = 0; s.h[5] = 0; s.h[8] = 0; s.h[0xC] = 0
        for i in range(5): s.page[i * 0x30 + 0x0E] = 0
        s.stop_music()

    def stop_music(s):
        if s.v2: s.end_sfx()
        s.start_music(s.c['silent_tab'])

    def play_music(s, i):
        s.h[0xD] = i
        s.start_music(s.c['music_tab'] + 8 * i)

    def play_sfx(s, i):
        s.h[0xB] = i
        s.start_sfx(s.c['sfx_tab'] + 2 * i)

    def save_music(s):
        s.save[:] = s.page
        s.save[0xF0:0x100] = s.h
        s.h[4] &= 0xF0
        s.stop_music()

    def restore_music(s):
        s.page[:] = s.save
        s.h[:] = s.save[0xF0:0x100]

    def start_music(s, tab):
        s.h[4] &= 0xF0
        s.h[3] = 4; s.h[2] = 4
        for i in range(4): s.init_track(i, s.romw(tab + 2 * i))
        s.wr(0x1A, 0x80)
        s.wr(0x1C, 0); s.wr(0x1A, 0)
        s.h[4] |= 0x0F

    def start_music_ptrs(s, ptrs):
        s.h[4] &= 0xF0
        s.h[3] = 4; s.h[2] = 4
        for i in range(4): s.init_track(i, ptrs[i])
        s.wr(0x1A, 0x80); s.wr(0x1C, 0); s.wr(0x1A, 0)
        s.h[4] |= 0x0F

    def end_sfx(s):
        sv0, sv1 = s.h[0], s.h[1]
        s.h[0] = s.h[8]; s.h[1] = 0xC0; s.h[9] = 0
        s.cmd_end(0)
        s.h[1] = sv1; s.h[0] = sv0

    def start_sfx(s, entry):
        hdr = s.romw(entry)
        ch = s.rom(hdr); pri = s.rom(hdr + 1)
        if pri < s.h[0xC]: return
        if s.h[4] & 0x10: s.end_sfx()
        s.h[0xC] = pri
        s.h[8] = ch
        s.page[(ch * 0x30 + 0x0E) & 0xFF] |= 1
        s.init_track(4, hdr + 2)
        s.h[4] |= 0x10

    def init_track(s, i, de):
        base = (i * 0x30) & 0xFF
        keep = s.page[(base + 0x0E) & 0xFF] & 1
        for k in range(0x30): s.page[(base + k) & 0xFF] = 0
        s.page[(base + 0x0E) & 0xFF] = keep
        for off in (0, 2):
            s.page[(base + off) & 0xFF] = de & 0xFF; s.page[(base + off + 1) & 0xFF] = de >> 8
        s.page[(base + 0x0F) & 0xFF] = 1; s.page[(base + 0x10) & 0xFF] = 1; s.page[(base + 0x11) & 0xFF] = 0x0C

    # ---- frame update
    def update(s):
        if s.h[3] != s.h[2]:
            s.h[3] = (s.h[3] + 1) & 0xFF
        else:
            s.h[3] = 0; s.h[0] = 0; s.h[1] = 0
            b = s.h[4]
            while True:
                if b & 1:
                    s.h[9] = s.get(0x0E) & 1
                    s.tick()
                b >>= 1
                s.h[1] = (s.h[1] + 0x30) & 0xFF
                s.h[0] = (s.h[0] + 1) & 0xFF
                if s.h[0] >= 4: break
        if not (s.h[4] & 0x10): return
        s.h[0xF] = (s.h[0xF] + 1) & 0xFF
        if s.h[0xF] & 1: return
        s.h[0] = s.h[8]; s.h[9] = 0; s.h[1] = 0xC0
        s.tick()

    def tick(s):
        s.h[0xA] = 0
        n = (s.get(0x10) - 1) & 0xFF; s.set(0x10, n)
        if n == 0:
            s.new_row(); return
        g = s.get(0x19)
        if g == 0: return
        g = (g - 1) & 0xFF; s.set(0x19, g)
        if g == 0:
            s.note_off(); return
        if s.get(0x0E) & 0x80: return
        if s.ch != 2: s.env_tick()
        if s.ch == 3: s.seq_tick()
        if s.ch < 2: s.vib_tick()
        s.output()

    def new_row(s):
        s.set(0x0E, s.get(0x0E) & 0x7F)
        s.h[6] = 0
        de = s.getw(0x02)
        while True:
            a = s.rom(de); de = (de + 1) & 0xFFFF
            if a < 0x80:
                old = s.get(0x14); s.set(0x14, a); s.set(0x17, old)
                de = s.play_note(a, de)
                break
            de = s.command(a, de)
            if s.o == 0xC0:
                if s.h[4] & 0x10: continue
                break
            if s.h[4] & (1 << s.ch if s.ch < 3 else 8): continue
            break
        s.setw(0x02, de)
        s.output()

    def output(s):
        if s.h[0xA] == 0: return
        if s.h[9]: return
        hi = 0
        if s.ch != 3:
            if s.ch == 2:
                s.wr(0x1C, s.get(0x11)); s.wr(0x1A, 0x80)
            hi = s.get(0x0B)
        d, e = s.regs()
        s.wr(e + 1, 0x80 | hi)

    def note_off(s):
        if s.h[9]: return
        if s.ch == 2:
            s.wr(0x1C, 0); s.wr(0x1A, 0); return
        d, e = s.regs()
        s.wr(e - 1, 8); s.wr(e + 1, 0x80)

    def key_on(s):
        if s.h[9]: return
        s.h[0xA] = 1
        s.write_freq()

    def write_freq(s):
        d, e = s.regs()
        if s.ch == 3:
            s.drum_init(); return
        s.wr(e, s.get(0x0A)); s.wr(e + 1, s.get(0x0B))

    def play_note(s, a, de):
        if a == s.rest:
            s.set(0x0E, s.get(0x0E) & ~2)
            s.note_off()
        else:
            s.calc_freq()
            f = s.get(0x0E)
            keyon = True
            if s.h[6]:
                if f & 2: keyon = s.get(0x14) != s.get(0x17)
                else: s.set(0x0E, f | 2)
            else:
                if f & 2:
                    s.set(0x0E, f & ~2)
                    keyon = s.get(0x14) != s.get(0x17)
            if keyon:
                s.note_off(); s.key_on()
                if s.ch == 0: s.sweep_init()
                if s.ch != 2: s.volume_init()
                if s.ch < 2: s.vib_init()
        x = s.rom(de)
        if 0x80 <= x < 0xA0:
            L = s.rom(s.c['len_tab'] + x - 0x80); de = (de + 1) & 0xFFFF
        else:
            L = s.get(0x0F)
        s.set(0x10, L)
        g = s.get(0x18)
        if g:
            b = L >> 3
            if b == 0: b = 1
            L = (b * g) & 0xFF
        s.set(0x19, L)
        return de

    def calc_freq(s):
        n = s.get(0x14); bc = 0
        if n >= 0x24:
            idx = (n - 0x24 + s.get(0x15)) & 0xFF
            hl = s.romw(s.c['freq_tab'] + 2 * idx)
            c = s.get(0x16)
            bc = (hl + (c | (0xFF00 if c & 0x80 else 0))) & 0xFFFF
        s.setw(0x0A, bc)

    def vib_tick(s):
        mode = s.get(0x25)
        if mode == 0: return
        dl = s.get(0x26)
        if dl:
            s.set(0x26, dl - 1); return
        r = (s.get(0x2A) - 1) & 0xFF; s.set(0x2A, r)
        if r: return
        s.set(0x2A, s.get(0x2B))
        c = s.get(0x24)
        if mode == 1:
            hh = (s.get(0x28) - 1) & 0xFF; s.set(0x28, hh)
            if hh == 0:
                s.set(0x28, s.get(0x29))
                c = (-c) & 0xFF; s.set(0x24, c)
            s.set(0x16, s.get(0x16) + c)
        elif mode == 2:
            s.set(0x16, s.get(0x16) - c)
        else:
            s.set(0x16, s.get(0x16) + c)
        if s.h[9]: return
        s.calc_freq()
        if s.ch == 2: s.key_on()
        else: s.write_freq()

    def vib_init(s):
        if s.get(0x25) == 0: return
        s.set(0x24, s.get(0x2C)); s.set(0x26, s.get(0x27)); s.set(0x2A, s.get(0x2B))
        s.set(0x28, s.get(0x29)); s.set(0x16, 0)

    def volume_init(s):
        if s.h[9]: return
        d, e = s.regs()
        v = s.get(0x11); sw = ((v << 4) | (v >> 4)) & 0xFF
        s.wr(e - 1, (s.rdreg(e - 1) & 0x0F) | sw)
        s.wr(e - 2, s.get(0x12))
        if not (s.get(0x0E) & 4): return
        s.set(0x0E, s.get(0x0E) | 0x20)
        s.env_start()

    def env_start(s):
        s.setw(0x1C, s.getw(0x04))
        return s.env_next()

    def env_next(s):
        bc = s.getw(0x1C)
        e = s.rom(bc); d = s.rom(bc + 1)
        s.setw(0x1C, bc + 2)
        s.set(0x23, e); s.set(0x22, d)
        if d >= 0xFE: return d
        if s.h[9]: return d
        r = 0x12 if s.ch == 0 else 0x17 if s.ch == 1 else 0x21
        s.wr(r, e)
        return d

    def env_tick(s):
        if not (s.get(0x0E) & 0x20): return
        n = (s.get(0x22) - 1) & 0xFF; s.set(0x22, n)
        if n: return
        d = s.env_next()
        if d == 0xFE:
            s.env_start(); return
        if d == 0xFF:
            s.set(0x0E, s.get(0x0E) & ~0x20); return
        if s.h[9]: return
        s.h[0xA] = 1

    def sweep_init(s):
        s.start_seq(s.getw(0x0C))

    def drum_init(s):
        bc = s.getw(0x0C)
        idx = (((s.get(0x14) - 0x0A) & 7) * 4) & 0xFF
        hl = (bc + idx) & 0xFFFF
        seq = s.romw(hl)
        s.set_envelope(s.romw(hl + 2))
        s.start_seq(seq)

    def start_seq(s, bc):
        s.setw(0x1E, bc)
        f = s.get(0x0E)
        if not (f & 8): return
        s.set(0x0E, f | 0x10)
        s.seq_next()

    def seq_next(s):
        bc = s.getw(0x1E)
        e = s.rom(bc); d = s.rom(bc + 1)
        s.setw(0x1E, bc + 2)
        s.set(0x21, e); s.set(0x20, d)
        if d >= 0xFE: return d
        if s.h[9]: return d
        s.wr(0x22 if s.ch == 3 else 0x10, e)
        return d

    def seq_tick(s):
        if not (s.get(0x0E) & 0x10): return
        n = (s.get(0x20) - 1) & 0xFF; s.set(0x20, n)
        if n: return
        d = s.seq_next()
        if d == 0xFE:
            s.drum_init(); return
        if d == 0xFF:
            s.set(0x0E, s.get(0x0E) & ~0x10); return
        if s.h[9]: return
        s.h[0xA] = 1

    def set_envelope(s, bc):
        s.setw(0x04, bc)
        s.set(0x0E, s.get(0x0E) | 4)

    def set_pan(s, a):
        a &= 0xFF
        if a == 1: b = 0x01
        elif a == 2: b = 0x10
        else: b = 0x11
        c = 0xEE
        for _ in range(s.ch):
            b = ((b << 1) | (b >> 7)) & 0xFF
            c = ((c << 1) | (c >> 7)) & 0xFF
        if s.h[9]: return
        s.wr(0x25, (s.rdreg(0x25) & c) | b)

    def stop_channel(s):
        s.h[4] &= CHANNEL_MASK[s.ch] if s.ch < 4 else 0xF7

    # ---- commands (de points after the command byte; returns new de)
    def command(s, a, de):
        if s.v2 and not (0xA0 <= a < 0xB8): return de
        if not (0xA0 <= a < 0xB8): raise Exception('command $%02X in v1 data' % a)
        rd = s.rom
        if a == 0xA0: return s.cmd_end(de)
        if a == 0xA1: s.h[4] &= 0x7F; return de
        if a == 0xA2: s.h[4] |= 0x80; return de
        if a == 0xA3:
            s.set(0x1A, 0); s.setw(0x08, de); return de
        if a == 0xA4: s.h[6] = 1; return de
        if a == 0xA5:
            x = rd(de); s.set(0x0F, rd(s.c['len_tab'] + ((x - 0x80) & 0xFF))); return de + 1
        if a == 0xA6:
            x = rd(de)
            if s.ch == 2: x = rd(s.c['wavevol_tab'] + x)
            s.set(0x11, x); return de + 1
        if a == 0xA7:
            x = rd(de); s.set(0x13, x); s.set_pan(x & 3); return de + 1
        if a == 0xA8:
            s.set_envelope(s.romw(de)); return de + 2
        if a == 0xA9:
            n = rd(de); de += 1
            cnt = (s.get(0x1A) + 1) & 0xFF; s.set(0x1A, cnt)
            if cnt >= n: return de
            return s.getw(0x08)
        if a == 0xAA:
            x = rd(de)
            if s.ch >= 2: return de + 1
            sw = ((x << 4) | (x >> 4)) & 0xFF
            s.set(0x12, (sw * 4) & 0xFF); return de + 1
        if a in (0xAB, 0xAD):
            s.setw(0x0C, s.romw(de)); s.set(0x0E, s.get(0x0E) | 8); return de + 2
        if a == 0xAC:
            s.set(0x1B, rd(de)); de += 1
            s.setw(0x06, de); return s.romw(de)
        if a == 0xAE:
            de += 1
            p = s.romw(de); de += 2
            hl = s.romw(p)
            if s.h[9]: return de
            s.wr(0x1A, 0)
            for i in range(16): s.wave[i] = rd(hl + i)
            s.wr(0x1A, 0x80); s.h[0xA] = 0x80
            return de
        if a == 0xAF:
            x = rd(de)
            if s.o != 0xC0: s.h[2] = x; s.h[3] = x
            return de + 1
        if a == 0xB0: s.set(0x16, rd(de)); return de + 1
        if a == 0xB1: s.set(0x15, rd(de)); return de + 1
        if a == 0xB2: s.set(0x18, rd(de) & 7); return de + 1
        if a == 0xB3: return s.romw(de)
        if a == 0xB4: s.h[5] = rd(de); return de + 1
        if a == 0xB5:
            n = (s.get(0x1B) - 1) & 0xFF; s.set(0x1B, n)
            if n == 0: return (s.getw(0x06) + 2) & 0xFFFF
            return s.romw(s.getw(0x06))
        if a == 0xB6:
            x = rd(de); s.h[7] = x; s.wr(0x24, x); return de + 1
        if a == 0xB7:
            x = rd(de)
            s.set(0x2C, x & 0x3F); s.set(0x25, x >> 6)
            s.set(0x27, rd(de + 1)); s.set(0x2B, rd(de + 2)); s.set(0x29, rd(de + 3))
            s.set(0x16, 0)
            return de + 4

    def cmd_end(s, de):
        if s.o == 0xC0:
            s.note_off()
            s.h[4] &= ~0x10 & 0xFF
            s.h[0xC] = 0
            ch = s.h[8]
            if ch == 0:
                s.wr(0x14, 0x08); r = 0x12
            elif ch == 1: r = 0x17
            elif ch == 2: r = None
            else: r = 0x21
            if r is not None:
                s.wr(r, 8); s.wr(r + 2, 0x80)
            base = (ch * 0x30) & 0xFF
            f = s.page[(base + 0x0E) & 0xFF]
            f = (f & ~1 | 0x80) & 0xFF
            s.page[(base + 0x0E) & 0xFF] = f
            s.set_pan(f)               # the bug: TRK_FLAGS used as the pan value
            return de
        if s.h[4] & 0x80:
            s.note_off(); s.stop_channel(); return de
        de = s.getw(0x00)
        s.setw(0x02, de)
        if s.rom(de) == 0xA0: s.stop_channel()
        return de
