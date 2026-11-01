"""Behavioural model of the TMNT II: Back from the Sewers sound driver (fourth Konami GB generation).
Written from the disassembly and used to cross-check the emulator update by update (verify/vmodel4.py).
State lives in a RAM image `m` at the game's addresses. Every register write is logged in `writes`
as (update, register, value), so the comparison covers the exact write sequence.

Per update (256 Hz): the three SFX tracks, plus one music track in turn (Ch1, Ch2, Ch3, Drm), each
run by the bank its sound id came from (id >= $C0: bank 15, else bank 14)."""

READMASK = {0x10: 0x80, 0x11: 0x3F, 0x12: 0x00, 0x13: 0xFF, 0x14: 0xBF, 0x16: 0x3F, 0x17: 0x00,
            0x18: 0xFF, 0x19: 0xBF, 0x1A: 0x7F, 0x1B: 0xFF, 0x1C: 0x9F, 0x1D: 0xFF, 0x1E: 0xBF,
            0x20: 0xFF, 0x21: 0x00, 0x22: 0x00, 0x23: 0xBF, 0x24: 0x00, 0x25: 0x00, 0x26: 0x70}
PCM = {0x9A: 0x6A1A, 0x9B: 0x6FFB, 0x9C: 0x74DC, 0x9D: 0x77ED}
BANK = {14: dict(stab=0x49C8, ptab=0x48A4, waves=0x4968, vibtab=0x4E6F, octtab=0x447C),
        15: dict(stab=0x4975, ptab=0x47BD, waves=0x4867, vibtab=0x4C2B, octtab=0x43E2)}


def swap(a): return ((a << 4) | (a >> 4)) & 0xFF


class Driver:
    def __init__(self, rom):
        self.r = open(rom, 'rb').read()
        self.m = bytearray(0x10000)
        self.hw = bytearray(0x100)          # $FFxx as written
        self.writes = []; self.tick_no = 0
        self.bank = 14; self.P = 0xC0; self.D = 0
        self.ramreads = 0

    # ------------------------------------------------------------- helpers
    def rb(self, a, bank=None):
        a &= 0xFFFF
        if a >= 0x8000:                     # stream/vibrato pointers that leave the ROM read RAM
            self.ramreads += 1
            if 0xE000 <= a < 0xFE00: a -= 0x2000
            return self.m[a]
        bank = self.bank if bank is None else bank
        return self.r[a if a < 0x4000 else bank * 0x4000 + a - 0x4000]
    def rw(self, a, bank=None): return self.rb(a, bank) | self.rb(a + 1, bank) << 8
    def T(self, L, P=None): return ((self.P if P is None else P) << 8) | L
    def g(self, L, P=None): return self.m[self.T(L, P)]
    def s(self, L, v, P=None): self.m[self.T(L, P)] = v & 0xFF
    def gw(self, L, P=None): return self.g(L, P) | self.g(L + 1, P) << 8
    def sw(self, L, v, P=None): self.s(L, v, P); self.s(L + 1, v >> 8, P)
    def setb(self, L, mask, P=None): self.s(L, self.g(L, P) | mask, P)
    def resb(self, L, mask, P=None): self.s(L, self.g(L, P) & ~mask, P)
    def B(self): return BANK[self.bank]

    def hwwrite(self, reg, v):
        reg &= 0xFF; v &= 0xFF
        self.hw[reg] = v
        self.writes.append((self.tick_no, reg, v))

    def hwread(self, reg):
        reg &= 0xFF
        if reg == 0x00: return 0xC0 | (self.hw[0] & 0x30) | 0x0F      # joypad, nothing pressed
        return self.hw[reg] | READMASK.get(reg, 0)

    # ------------------------------------------------------------- register writes
    def write_checked(self, c, a):
        """$484C: music Ch1 is blocked while Sfx1 plays, music Ch3 while Sfx2 plays. True = written."""
        D = self.D
        if D == 0x00 and self.m[0xC081]: return False
        if D == 0x22 and self.m[0xC181]: return False
        self.hwwrite(c, a); return True

    def write_period(self, de):
        """$4773"""
        self.s(0x96, de); self.s(0x97, (de >> 8) & 7)
        c = self.g(0xC4)
        if not self.write_checked(c, de & 0xFF): return
        self.hwwrite(c + 1, (de >> 8) & 7)

    def note_vol(self, a):
        """$47A9: NRx2 = a; written (and the channel retriggered) only if it differs from what the
        register reads back, except on CH1 while the sweep value isn't 8. CH3 is never retriggered here."""
        c = self.g(0xC3)
        self.s(0x99, a)
        if self.hwread(c) == a:
            if self.D & 15: return
            v = self.g(0x90) if self.bank == 14 else self.hwread(0x10) & 0x7F
            if v == 8: return
            c = self.g(0xC3)
        if not self.write_checked(c, self.g(0x99)): return
        if self.D & 15 == 2: return
        self.hwwrite(self.g(0xC5), self.g(0x97) | 0x80)

    def noise_vol(self, a):
        """$47DC"""
        self.s(0x99, a); self.hwwrite(self.g(0xC3), a)
        self.hwwrite(self.g(0xC5), self.g(0x97) | 0x80)

    def write_duty(self, b):
        """$47ED: NRx1, or on CH3 load wave (b >> 4) unless it's already loaded (wWaveId)."""
        m = self.m
        if self.D & 15 == 2:
            if self.D == 0x22 and m[0xC181]: return
            if m[0xC0D5] == b: return
            self.s(0x9B, b); m[0xC0D5] = b
            self.hwwrite(0x1A, 0)
            p = self.rw(self.B()['waves'] + 2 * swap(b))
            for i in range(16): self.hwwrite(0x30 + i, self.rb(p + i))
            self.hwwrite(0x1C, 0); self.hwwrite(0x1A, 0x80)
            self.hwwrite(self.g(0xC5), self.g(0x97) | 0x80)
            return
        self.s(0x9B, b)
        self.write_checked(self.g(0xC2), b)

    def pan_both(self):
        """$44DE"""
        b = (0x11 << (self.D & 15)) & 0xFF
        a = self.hwread(0x25) | b
        self.s(0xA0, b)
        self.write_checked(0x25, a)

    def pan_side(self, l0):
        """$4515 (l0 = $01, right) / $4536 (l0 = $10, left)"""
        b, l = 0xEE, l0
        for _ in range(self.D & 15):
            b = ((b << 1) | (b >> 7)) & 0xFF; l = ((l << 1) | (l >> 7)) & 0xFF
        a = (self.hwread(0x25) & b) | l
        self.s(0xA0, l if (self.bank == 14 or l0 == 0x10) else 0x0B)
        self.write_checked(0x25, a)

    def autopan(self):
        """$4509: alternate left / right on every note."""
        if self.g(0x86) & 2: self.resb(0x86, 2); self.pan_side(0x01)
        else: self.setb(0x86, 2); self.pan_side(0x10)

    # ------------------------------------------------------------- ROM0: requests
    def play(self, a):
        """ROM0 PlaySound ($04D2)."""
        m = self.m
        m[0xC0CF] = a
        if a == 0:
            self.bank = 14; self.stop_all(); return
        if 0x9A <= a < 0x9E:
            self.pcm(a); return
        if a < 0xC0: self.bank = 14; tab = 0x49C8; i = a
        else: self.bank = 15; tab = 0x4975; i = a - 0xC0
        h = self.rw(tab + 2 * i)
        prio = self.rb(h); m[0xC0CE] = prio; b = self.rb(h + 1); de = h + 2
        for k, P in ((0, 0xC0), (1, 0xC1), (2, 0xC2)):
            if b >> k & 1 and prio < m[P << 8 | 0x80]: b = 0
        for k, P in ((0, 0xC0), (1, 0xC1), (2, 0xC2)):
            if b >> k & 1: de = self.start_track(P, de, sfx=True)
        m[0xC0D6] = 0
        if not b & 8: return
        if prio < m[0xC380]: return
        for a_ in (0xC0CC, 0xC0D4, 0xC0D3, 0xC0D2, 0xC0CB): m[a_] = 0
        self.hwwrite(0x10, 8)
        for k, P in ((3, 0xC3), (4, 0xC4), (5, 0xC5), (6, 0xC6)):
            if b >> k & 1: de = self.start_track(P, de)

    def start_track(self, P, de, sfx=False, drum_id=None):
        """ROM0 $05BB/$05E6 (and the bank's $42B7 for drum hits): NRx2 = 0 on the track's channel."""
        m = self.m
        self.s(0x80, m[0xC0CE], P)
        self.s(0x81, m[0xC0CF] if drum_id is None else drum_id, P)
        self.s(0x82, self.rb(de), P); self.s(0x83, self.rb(de + 1), P); de += 2
        self.s(0x84, 1, P)
        for L in range(0x85, 0x91): self.s(L, 0, P)
        m[0xC0D5] = 0
        self.hwwrite(self.g(0xC3, P), 0)
        if sfx or drum_id is not None:
            if P == 0xC0: self.s(0x90, 8, P); self.hwwrite(0x10, 8)
            if P == 0xC2: self.s(0xA0, 0x88, P); self.hwwrite(0x25, self.hwread(0x25) | 0x88)
        return de

    def pcm(self, a):
        """ROM0 $04E1 + bank 14 $6990: 1-bit PCM through NR32, interrupts off, until a $DD byte."""
        m = self.m
        p = PCM[a]
        m[0xC0D8] = p & 0xFF; m[0xC0D9] = p >> 8
        self.bank = 14
        for reg, v in ((0x26, 0x8F), (0x25, 0xFF), (0x24, 0x77), (0x1A, 0)):
            self.hwwrite(reg, v)
        for i in range(16): self.hwwrite(0x30 + i, self.rb(0x6A0A + i))
        for reg, v in ((0x1A, 0x80), (0x1B, 0), (0x1C, 0x20), (0x1D, 0), (0x1E, 0x80)):
            self.hwwrite(reg, v)
        hl = p
        while True:
            d = self.rb(hl); hl += 1
            if d == 0xDD: break
            a_ = 0; cy = 0
            for _ in range(8):
                ncy = d & 1; d = (d >> 1) | (cy << 7); cy = ncy        # rr d
                for _ in range(3):                                      # rra x3
                    ncy = a_ & 1; a_ = (a_ >> 1) | (cy << 7); cy = ncy
                self.hwwrite(0x1C, a_)
        self.hwwrite(0x1C, 0); m[0xC0D5] = 0

    def stop_all(self):
        """bank 14 $4878"""
        m = self.m
        for P in (0xC0, 0xC1):
            self.s(0x80, 0, P); self.s(0x81, 0, P); self.resb(0x85, 2, P)
        for P in (0xC2, 0xC3, 0xC4, 0xC5, 0xC6):
            self.s(0x80, 0, P); self.s(0x81, 0, P)
        for reg in (0x12, 0x17, 0x1A, 0x1C, 0x21): self.hwwrite(reg, 8)
        for reg in (0x14, 0x19, 0x23): self.hwwrite(reg, 0x80)
        self.hwwrite(0x25, 0xFF)

    # ------------------------------------------------------------- ROM0: update
    def update(self):
        m = self.m
        self.tick_no += 1
        p = m[0xC794] & 1
        if p != m[0xC0D1]:
            m[0xC0D1] = p; self.pause_edge(p)
        if not m[0xC794] & 1:
            slot = m[0xC0CB] & 3
            if slot == 0:
                self.fade(); self.tempo(); self.track_entry(0xC3, 0x00)
            else:
                self.track_entry(*((0xC4, 0x11), (0xC5, 0x22), (0xC6, 0x34))[slot - 1])
            m[0xC0CB] = (m[0xC0CB] + 1) & 0xFF
        self.track_entry(0xC2, 0x63); self.track_entry(0xC1, 0x52); self.track_entry(0xC0, 0x40)

    def track_entry(self, P, D):
        self.m[0xC0CA] = D
        sid = self.m[P << 8 | 0x81]
        if sid == 0: return
        self.bank = 15 if sid >= 0xC0 else 14
        self.P = P; self.D = D
        self.track_tick()

    def pause_edge(self, p):
        m = self.m
        if p:
            m[0xC281] = m[0xC280] = 0
            for reg, v in ((0x21, 8), (0x23, 0x80), (0x17, 8), (0x19, 0x80)): self.hwwrite(reg, v)
            return
        m[0xC081] = m[0xC080] = 0
        for reg, v in ((0x10, 8), (0x12, 8), (0x14, 0x80)): self.hwwrite(reg, v)
        m[0xC181] = m[0xC180] = 0
        self.hwwrite(0x1C, 0)
        m[0xC281] = m[0xC280] = 0
        self.hwwrite(0x21, 8); self.hwwrite(0x23, 0x80)
        self.hwwrite(0x25, (self.hwread(0x25) & 0xEE) | m[0xC3A0])
        c = m[0xC3C4]; self.hwwrite(c, m[0xC396]); self.hwwrite(c + 1, m[0xC397] & 7)
        m[0xC385] |= 0x24; m[0xC485] |= 0x04; m[0xC585] |= 0x24
        self.hwwrite(0x25, (self.hwread(0x25) & 0xBB) | m[0xC5A0])
        c = m[0xC5C4]; self.hwwrite(c, m[0xC596]); self.hwwrite(c + 1, m[0xC597] & 7)

    def tempo(self):
        """$0727: wTempoAcc += wTempo once per four updates; a carry makes the four music tracks skip
        their next tick (bit 4 of TRK_FLAGS)."""
        m = self.m
        t = m[0xC0CC]
        if t == 0: return
        s_ = m[0xC0CD] + t; m[0xC0CD] = s_ & 0xFF
        for P in (0xC3, 0xC4, 0xC5, 0xC6):
            if s_ > 0xFF: m[P << 8 | 0x85] |= 0x10
            else: m[P << 8 | 0x85] &= 0xEF

    def fade(self):
        """$0754: wFadeLevel += $10 every wFadeRate calls (one per four updates); at $40 the drums stop,
        at $70 everything stops."""
        m = self.m
        r = m[0xC0D4]
        if r == 0: return
        m[0xC0D2] = (m[0xC0D2] + 1) & 0xFF
        if m[0xC0D2] != r: return
        m[0xC0D2] = 0
        m[0xC0D3] = (m[0xC0D3] + 0x10) & 0xFF
        v = m[0xC0D3]
        if v == 0x40: m[0xC681] = m[0xC680] = 0; return
        if v != 0x70: return
        m[0xC0D3] = m[0xC0D4] = m[0xC0D2] = 0
        if m[0xC081] == 0: self.hwwrite(0x12, 8); self.hwwrite(0x14, 0x80)
        m[0xC381] = m[0xC380] = 0; m[0xC481] = m[0xC480] = 0
        self.hwwrite(0x17, 8); self.hwwrite(0x19, 0x80)
        if m[0xC181] == 0: self.hwwrite(0x1A, 0); self.hwwrite(0x1C, 0)
        m[0xC581] = m[0xC580] = 0

    # ------------------------------------------------------------- track tick
    def track_tick(self):
        g, s = self.g, self.s
        f = g(0x85)
        if f & 0x10: return
        if f & 0x20:
            self.resb(0x85, 0x20); self.write_duty(g(0x9B))
        s(0x84, g(0x84) - 1)
        if g(0x84):
            self.sustain(); return
        self.read_cmds(self.gw(0x82))

    def save_ptr(self, de): self.sw(0x82, de + 1)

    def read_cmds(self, de):
        g, s = self.g, self.s
        b14 = self.bank == 14
        while True:
            a = self.rb(de)
            if a >= 0xE0:
                de = self.command(de, a)
                if de is None: return
                continue
            if b14 and g(0x85) & 2: self.raw_note(de); return
            if self.D == 0x63: self.noise_note(de); return
            self.resb(0x85, 4)
            self.save_ptr(de)
            lo = a & 15; u = g(0x92)
            L = swap(u) & 0xF0 if lo == 0 else (lo * u) & 0xFF
            s(0x84, L)
            if a & 0xF0 == 0:
                self.setb(0x85, 1); self.note_vol(8); return
            self.resb(0x85, 1)
            if self.D == 0x34: self.drum_note(a); return
            gt = g(0x9C)
            s(0x9D, (L * gt) >> 4 if gt else 0)
            if g(0x8E):
                s(0x8F, g(0x8E)); self.write_duty(g(0x90))
            if g(0x86) & 1: self.autopan()
            c = (((a >> 4) << 1) + g(0x93) + g(0x8D)) & 0xFF
            de_p = self.rw(self.B()['ptab'] + c)
            if g(0x8A): de_p = (de_p + self.gw(0x8A)) & 0xFFFF
            self.sw(0x94, de_p)
            if g(0x88):
                self.resb(0x87, 0x30); self.setb(0x86, 4)
                self.sw(0xA3, self.gw(0xA1)); s(0xA5, 1); s(0xA7, g(0xA6))
                if g(0xA6) == 0: de_p = self.vib_step(self.gw(0xA1))
            self.write_period(de_p)
            if b14 and g(0x90): self.hwwrite(0x10, g(0x90))
            v = g(0x98) - g(0x8C)
            v2 = (v & 0xFF) - self.m[0xC0D3]
            self.note_vol(v2 & 0xFF if v2 >= 0 else 8)   # only the second subtraction's borrow counts
            return

    def raw_note(self, de):
        """bank 14 $4303: 2-byte frames vol << 4 | period high, period low."""
        self.s(0x84, self.g(0x92))
        a = self.rb(de)
        if a == 0: self.save_ptr(de); self.note_vol(8); return
        v = a & 0xF0; c = a & 15
        de += 1; lo = self.rb(de); self.save_ptr(de)
        self.write_period(c << 8 | lo); self.note_vol(v)

    def noise_note(self, de):
        """$4323"""
        self.s(0x84, self.g(0x92))
        a = self.rb(de)
        if a == 0: self.save_ptr(de); self.note_vol(8); return
        if self.g(0x85) & 8:
            v = (a & 15) << 4
            de += 1; n43 = self.rb(de); self.save_ptr(de)
            self.write_period(n43)
            c = self.g(0xC3); self.s(0x99, v)
            if self.hwread(c) == v: return
            self.hwwrite(c, v); self.hwwrite(self.g(0xC5), self.g(0x97) | 0x80)
            return
        self.save_ptr(de); self.write_period(a)

    def drum_note(self, a):
        """$428B: start sound (hi nibble) of this bank's table on the SFX tracks."""
        m = self.m
        n = a >> 4
        m[0xC0CF] = n
        h = self.rw(self.B()['stab'] + 2 * n)
        m[0xC0CE] = self.rb(h); b = self.rb(h + 1); de = h + 2
        sid = n | 0xC0 if self.bank == 15 else n
        for k, P in ((0, 0xC0), (1, 0xC1), (2, 0xC2)):
            if b >> k & 1:
                if m[0xC0CE] < m[P << 8 | 0x80]: de += 2
                else: de = self.start_track(P, de, drum_id=sid)

    def command(self, de, op):
        """$4364; returns DE of the next byte to read, or None when reading stops."""
        g, s, m = self.g, self.s, self.m
        de += 1; c = op - 0xE0
        if c == 0: return self.voice(de)
        if self.bank == 14 and g(0x85) & 2:
            if c < 7 or 0x10 <= c < 0x18: self.raw_note(de - 1); return None
        elif c < 7:
            s(0x93, self.rb(self.B()['octtab'] + c)); return de
        a = self.rb(de)
        if op == 0xE7: s(0x92, a)
        elif op == 0xE8: s(0x9C, a >> 4); s(0x9E, a & 15)
        elif op == 0xE9:
            if self.bank == 14: s(0x90, a & 0x7F); self.hwwrite(0x10, a & 0x7F)
            else: self.hwwrite(0x10, a)
        elif op == 0xEA:
            h, l = a >> 4, a & 15
            if h == 0: s(0x9A, l << 4); self.write_duty(g(0x9A))
            elif h == 1: self.pan_both()
            elif h == 2: self.pan_side(0x01)
            elif h == 3: self.pan_side(0x10)
            elif h == 4: self.setb(0x86, 3)
            elif h == 5: self.setb(0x86, 1); self.resb(0x86, 2)
            elif h == 6: self.resb(0x86, 1); self.pan_both()
            elif h == 7: s(0x8D, l << 1)
            elif h == 8: s(0x8D, (-(l << 1)) & 0xFF if l else 0)
            else: raise RuntimeError(f'EA {a:02X}')
        elif op == 0xEB:
            s(0x88, a)
            if a:
                self.sw(0xA1, self.rw(self.B()['vibtab'] + 2 * (a & 0x7F)))
                de += 1; y = self.rb(de)
                x = y >> 4; u = g(0x92)
                s(0xA6, (x * u) & 0xFF if x else 0); s(0xA8, y & 15)
        elif op == 0xEC: pass
        elif op == 0xED:
            s(0x91, a & 0xF0); s(0x90, a & 15); s(0x8F, a & 15)
            if a & 15 == 0: self.write_duty(g(0x9A))
        elif op == 0xEE: m[0xC0CC] = a; m[0xC0CD] = 0
        elif op == 0xEF: s(0x8A, a); s(0x8B, 0xFF if a & 0x80 else 0)
        elif op <= 0xF7:
            s(0x8C, (op & 15) << 4); return de
        elif op <= 0xF9:
            v = swap(a); s(0x98, v)
            if self.D == 0x63:
                if not g(0x85) & 8: self.noise_vol(v)
            else: s(0x8C, 0)
        elif op == 0xFA: return a | self.rb(de + 1) << 8
        elif op in (0xFB, 0xFC):
            bit, ptr, cnt = (1, 0xB8, 0xBA) if op == 0xFB else (2, 0xBB, 0xBD)
            if g(0x87) & bit:
                s(cnt, g(cnt) + 1)
                if g(cnt) == a: s(cnt, 0); self.resb(0x87, bit); return de + 1
                return self.gw(ptr)
            self.setb(0x87, bit); self.sw(ptr, de); s(cnt, 0); return de
        elif op == 0xFD:
            if g(0x87) & 4: self.resb(0x87, 4); return self.gw(0xC0)
            self.setb(0x87, 4)
            hi = self.rb(de + 1); self.sw(0xC0, de + 2); return a | hi << 8
        elif op == 0xFE:
            if g(0x87) & 8: return self.gw(0xBE)
            self.setb(0x87, 8); self.sw(0xBE, de); return de
        elif op == 0xFF: self.end_track(); return None
        return de + 1

    def voice(self, de):
        """$43F1: E0 unit|raw<<7, ..."""
        g, s = self.g, self.s
        b1 = self.rb(de); s(0x92, b1 & 0x7F); de += 1
        if b1 & 0x80:
            if self.D == 0x63: self.setb(0x85, 8); return de
            if self.bank == 15: return de
            self.setb(0x85, 2)
            s(0x9A, self.rb(de)); self.write_duty(g(0x9A)); de += 1
            if self.D & 15 == 0: self.hwwrite(0x10, self.rb(de))
            self.pan_both(); return de + 1
        if self.D == 0x63:
            self.resb(0x85, 8); self.noise_vol(self.rb(de)); return de + 1
        self.resb(0x85, 2)
        b2 = self.rb(de)
        s(0x9A, b2 & 0xF0); self.write_duty(g(0x9A)); s(0x98, (b2 & 15) << 4)
        de += 1; b3 = self.rb(de)
        s(0x9C, b3 >> 4); s(0x9E, b3 & 15)
        self.pan_both(); s(0x8C, 0)
        return de + 1

    def sustain(self):
        """$411D: duty step, vibrato, release, CH3 decay, retrigger after an SFX."""
        g, s = self.g, self.s
        if self.bank == 14 and g(0x85) & 2: return
        if self.D in (0x63, 0x34): return
        if g(0x85) & 1: return
        if g(0x8E):
            s(0x8F, g(0x8F) - 1)
            if g(0x8F) == 0: self.write_duty(g(0x9A))
        if g(0x88) and g(0x86) & 4:
            if g(0xA7): s(0xA7, g(0xA7) - 1)
            else:
                s(0xA5, g(0xA5) - 1)
                if g(0xA5) == 0: self.write_period(self.vib_step(self.gw(0xA3)))
        L = g(0x84); R = g(0x9D)
        if self.D == 0x22:
            if L < R:
                e = g(0x9E)
                if e == 0: self.note_vol(0); return
                s(0x9F, g(0x9F) - 1)
                if g(0x9F): return
                s(0x9F, g(0x9E))
                v = g(0x99) + 0x20
                if v >= 0xA0: return
                self.note_vol(v); return
            if L == R: s(0x9F, g(0x9E)); return
        else:
            if L == R:
                e = g(0x9E)
                if e == 0: self.note_vol(8); return
                c = g(0xC3)
                if self.write_checked(c, e | g(0x99)): self.hwwrite(g(0xC5), g(0x97) | 0x80)
                return
            if L < R: return
        if not g(0x85) & 4: return
        if L < 0x80: return
        self.resb(0x85, 4); self.note_vol(g(0x99))

    def vib_step(self, bc):
        """$41DC: returns the period to write."""
        g, s = self.g, self.s
        while True:
            a = self.rb(bc)
            if a == 0xFF: self.resb(0x86, 4); return self.gw(0x96)
            if a == 0xFE:
                if g(0x87) & 0x20: bc = self.gw(0xAC); continue
                self.setb(0x87, 0x20); bc += 1; self.sw(0xAC, bc); continue
            if a == 0xFB:
                bc += 1
                if g(0x87) & 0x10:
                    s(0xAB, g(0xAB) + 1)
                    if g(0xAB) == self.rb(bc):
                        s(0xAB, 0); self.resb(0x87, 0x10); bc += 1; continue
                    bc = self.gw(0xA9); continue
                self.setb(0x87, 0x10); self.sw(0xA9, bc); s(0xAB, 0); continue
            s(0xA5, a >> 4)
            bc += 1; self.sw(0xA3, bc)
            lo = a & 15
            if lo == 0: return self.gw(0x94)
            e, d = lo, 0
            if lo & 8:
                lo &= 7
                if lo == 0: return self.gw(0x94)
                e, d = (-lo) & 0xFF, 0xFF
            if g(0xA8): e = (e * g(0xA8)) & 0xFF
            return (self.gw(0x94) + (d << 8 | e)) & 0xFFFF

    def end_track(self):
        """$46E7"""
        g, s, m = self.g, self.s, self.m
        sid = g(0x81)
        s(0x81, 0); s(0x80, 0)
        if self.bank == 14 and sid == 0x9E: self.silence(); return
        D = self.D
        if D == 0x34: return
        if D == 0x52:
            self.resb(0x85, 2)
            if m[0xC581]: self.restore(0xC5)
        elif D == 0x40:
            self.resb(0x85, 2); self.hwwrite(0x10, 8)
            if m[0xC381]: self.restore(0xC3)
        elif D == 0x63:
            self.resb(0x85, 8)
        self.silence()

    def restore(self, Q):
        """$4741: give the channel back to the music track Q (retrigger flags, NR51 bits, period)."""
        P = self.P
        self.P = Q
        self.setb(0x85, 0x24)
        b = 0xEE
        for _ in range(self.D & 15): b = ((b << 1) | (b >> 7)) & 0xFF
        self.hwwrite(0x25, (self.hwread(0x25) & b) | self.g(0xA0))
        self.write_period(self.gw(0x96))
        self.P = P

    def silence(self):
        """$4789"""
        if self.D & 15 == 2: self.write_checked(0x1C, 0); return
        if self.write_checked(self.g(0xC3), 8): self.hwwrite(self.g(0xC5), 0x80)
