"""Behavioural model of the third-generation Konami GB driver (Nemesis II).
Written from the disassembly (bank 14 copy, with the bank 13/15 differences) and used to cross-check
the emulator tick by tick (verify/vmodel3.py). State lives in a RAM image `m` at the game's addresses,
so the comparison is direct.

One update = the ROM0 loop over the 7 tracks; each track is handled by the copy of the track code in
the bank its sound id belongs to (id < $80: bank 13, $80-$BF: bank 14, >= $C0: bank 15)."""
import kdata3

# globals
IDX, BASE, TEMPO, ACC, PHASE, TACT, SKIP = 0xC0BB, 0xC0BC, 0xC0BD, 0xC0BE, 0xC0BF, 0xC0C0, 0xC0C1
NR51, SWEEP, REQID, REQPRIO, RVAL, RIDX, HOLD = 0xC0C3, 0xC0C4, 0xC0C5, 0xC0C6, 0xC0C7, 0xC0C8, 0xC0C9
FADE, FSTEP, FTIM, FLVL, REFUSED, HALF = 0xC0CB, 0xC0CC, 0xC0CD, 0xC0CE, 0xC0CF, 0xC0D0
RFADE, RFTIM, RFLVL = 0xC0D3, 0xC0D4, 0xC0D5
SH = 0xC1B7
PAUSE = 0xC794
PANBITS = [0x11, 0x22, 0x88, 0x11, 0x22, 0x44, 0x88]
REGBASE = [0x00, 0x05, 0x0F, 0x00, 0x05, 0x0A, 0x0F]


def swap(a): return ((a << 4) | (a >> 4)) & 0xFF


class Driver:
    def __init__(self, g):
        self.g = g
        self.r = open(g['rom'], 'rb').read()
        self.m = bytearray(0x10000)
        self.hw = {}; self.wave = bytearray(16); self.trig = []; self.tick_no = 0
        self.bank = 13        # bank of the track code currently running

    # ------------------------------------------------------------- memory helpers
    def rb(self, a, bank=None):
        bank = self.bank if bank is None else bank
        return self.r[a if a < 0x4000 else bank * 0x4000 + a - 0x4000]
    def rw(self, a, bank=None):
        return self.rb(a, bank) | self.rb(a + 1, bank) << 8
    def B(self, bank=None): return self.g['banks'][self.bank if bank is None else bank]
    @property
    def cur(self): return self.m[IDX]
    def t(self, L, c=None):
        c = self.cur if c is None else c
        return ((0xC0 + c) << 8) | L
    def tw(self, L, c=None):
        a = self.t(L, c); return self.m[a] | self.m[a + 1] << 8
    def tws(self, L, v, c=None):
        a = self.t(L, c); self.m[a] = v & 0xFF; self.m[a + 1] = (v >> 8) & 0xFF
    def hwwrite(self, a, v):
        self.hw[a] = v
        if 0xFF30 <= a < 0xFF40: self.wave[a - 0xFF30] = v

    # ------------------------------------------------------------- register access
    def blocked(self):
        c = self.cur
        return (c == 3 and self.m[0xC080] != 0) or (c == 4 and self.m[0xC180] != 0)

    def write(self, reg, v):
        """WriteReg: callers always set wRegVal / wRegIdx first."""
        m = self.m
        m[RVAL] = v & 0xFF; m[RIDX] = reg
        if self.blocked(): return
        i = (m[BASE] + reg) & 0xFF
        force = m[self.t(0x85)] & 0x40
        if force or m[SH + i] != v:
            m[SH + i] = v; self.hwwrite(0xFF10 + i, v)

    def trigger(self):
        m = self.m
        if self.blocked(): return
        m[RIDX] = 4
        i = (m[BASE] + 4) & 0xFF
        self.hwwrite(0xFF10 + i, m[SH + i] | 0x80)
        self.trig.append((self.tick_no, m[BASE]))

    def write_bc(self, p):
        self.write(3, p & 0xFF); self.write(4, (p >> 8) & 0xFF)

    def write_duty(self, page=None):
        """WriteDuty: NRx1 = duty << 4 from TRK_DUTY of `page` (default: current track), or on the CH3
        register base the wave (duty - 1) copied straight into wave RAM."""
        m = self.m
        d = m[(page << 8 | 0x97) if page else self.t(0x97)]
        if m[BASE] == 0x0A:
            n = (d - 1) & 0xFF
            p = self.rw(self.B()['waves'] + ((2 * n) & 0xFF))
            for i in range(16): self.hwwrite(0xFF30 + i, self.rb(p + i))
        else:
            self.write(1, swap(d))

    def pan_bits(self, page=None):
        """GetPanBits: (wNR51 without this track's bits, TRK_PAN & this track's bits); page = whose PAN."""
        m = self.m
        bits = PANBITS[self.cur]
        pan = m[(page << 8 | 0xB6) if page else self.t(0xB6)]
        return m[NR51] & (~bits & 0xFF), pan & bits

    def apply_pan(self, page=None, check=True):
        a, c = self.pan_bits(page)
        if check and self.blocked(): return
        self.m[NR51] = a | c; self.hwwrite(0xFF25, a | c)

    # ------------------------------------------------------------- ROM0: requests
    def play(self, a):
        """ROM0 PlaySound ($09B2)."""
        m = self.m
        m[REQID] = a
        if a == 0: return self.stop_all()
        if a == 0x96: self.stop_all()
        m[REQID] = a
        if a == 0x56 and m[0xC080] == a: return
        bank = kdata3.bank_of_id(a)
        idx = a & (0x7F if bank == 13 else 0x3F)
        h = self.rw(0x3FFE + 2 * idx, bank)
        m[REQPRIO] = self.rb(h, bank); mask = self.rb(h + 1, bank); de = h + 2
        if mask & 1: de = self.start_sfx1(de, bank)
        if m[REFUSED]: m[REFUSED] = 0; return
        if mask & 2: de = self.start_simple(1, 0x22, de, bank)
        if mask & 4: de = self.start_sfxn(de, bank)
        if m[REFUSED]: m[REFUSED] = 0; return
        if mask & 8:
            if m[0xC080] == 0: self.hwwrite(0xFF10, 8); m[SH] = 8
            de = self.start_simple(3, 0x11, de, bank)
        if mask & 0x10:
            m[NR51] |= 0x22
            for a_ in range(0xC0BD, 0xC0C2): m[a_] = 0
            m[FADE] = 0
            de = self.start_track(4, de, bank, rom0=True)
        if mask & 0x20: de = self.start_simple(5, 0x44, de, bank)
        if mask & 0x40: de = self.start_simple(6, 0x88, de, bank)
        self.hwwrite(0xFF25, m[NR51])

    def start_simple(self, c, bits, de, bank):
        self.m[NR51] |= bits
        return self.start_track(c, de, bank, rom0=True)

    def start_sfx1(self, de, bank, rom0=True):
        m = self.m
        if m[REQPRIO] >= m[0xC081]:
            m[0xC081] = m[REQPRIO]
            self.hwwrite(0xFF10, 8); m[SH] = 8
            m[NR51] |= 0x11
        return self.start_track(0, de, bank, rom0)

    def start_sfxn(self, de, bank, rom0=True, prestore=True):
        m = self.m
        if m[REQPRIO] >= m[0xC281]:
            if prestore: m[0xC281] = m[REQPRIO]
            m[NR51] |= 0x88
        return self.start_track(2, de, bank, rom0)

    def start_track(self, c, de, bank, rom0):
        """StartTrack. A refused track keeps DE (the next track gets its pointer) and gets TRK_PAN = $FF."""
        m = self.m
        T = ((0xC0 + c) << 8) | 0x80
        if m[REQPRIO] < m[T + 1]:
            if rom0: m[REFUSED] = 1
            m[T + 0x36] = 0xFF
            return de
        m[T + 1] = m[REQPRIO]; m[T] = m[REQID]
        m[T + 2] = self.rb(de, bank); m[T + 3] = self.rb(de + 1, bank); de += 2
        m[T + 4] = 1; m[T + 5] = 0x40
        for i in range(6, 0x10): m[T + i] = 0
        p = m[T + 2] | m[T + 3] << 8
        if self.rb(p, bank) == 0xE1: m[T + 6] |= 0x30
        else: m[T + 6] &= 0xCF
        if rom0: m[REFUSED] = 0
        m[T + 0x36] = 0xFF
        return de

    def stop_all(self, local=False):
        m = self.m
        for c in ((0, 2) if local else range(7)):
            T = ((0xC0 + c) << 8) | 0x80
            for i in range(0x38): m[T + i] = 0
        for i in range(0x14): m[SH + i] = 0
        for a in range(0xC0BB, 0xC0DC): m[a] = 0
        m[NR51] = 0xFF
        if local:
            self.fade_step(); return
        for a in (0xFF12, 0xFF17, 0xFF21, 0xFF1C): self.hwwrite(a, 0)

    def local_play(self, a):
        """Bank PlaySound ($4437 in bank 14): used for drum hits. Only Sfx1 (when the mask is 5) and SfxN."""
        m = self.m
        m[REQID] = a
        if a == 0: return self.stop_all(local=True)
        idx = a & self.B()['idmask']
        h = self.rw(0x3FFE + 2 * idx)
        m[REQPRIO] = self.rb(h); mask = self.rb(h + 1); de = h + 2
        if mask == 5: de = self.start_sfx1(de, self.bank, rom0=False)
        de = self.start_sfxn(de, self.bank, rom0=False, prestore=False)
        self.hwwrite(0xFF25, m[NR51])

    # ------------------------------------------------------------- ROM0: update
    def update(self):
        m = self.m
        self.tick_no += 1
        while True:
            c = m[IDX]
            sid = m[((0xC0 + c) << 8) | 0x80]
            self.bank = kdata3.bank_of_id(sid)
            self.track_entry()
            m[IDX] = (m[IDX] + 1) & 0xFF
            if m[IDX] == 7: break
        m[IDX] = 0
        if m[RFADE]:
            if m[RFTIM]: m[RFTIM] -= 1
            else:
                m[RFTIM] = 0xFF; m[RFLVL] = (m[RFLVL] + 1) & 0xFF
                if m[RFLVL] == 5: m[RFADE] = m[RFTIM] = m[RFLVL] = 0
        if m[PAUSE] & 1: return
        if m[HALF] == 1: m[HALF] = 0
        else: m[HALF] = (m[HALF] + 1) & 0xFF

    def track_entry(self):
        m = self.m; c = self.cur
        if m[PAUSE] & 1:
            if self.bank != 13: return
            if m[self.t(0x80)] != 0x5D: return
        if c >= 3:
            if m[SKIP]:
                if m[PHASE] == 3: m[SKIP] = 0
                else: m[PHASE] += 1; return
            elif m[TEMPO] == 0: m[TACT] = 0
            else:
                m[TACT] = 1
                if m[PHASE] != 3: m[PHASE] += 1
                else:
                    m[PHASE] = 0
                    s = m[ACC] + m[TEMPO]; m[ACC] = s & 0xFF
                    if s > 0xFF:
                        m[ACC] = m[TEMPO]; m[SKIP] = 1; return
                    m[SKIP] = 0
            p = m[HALF]
            if self.bank == 15: pa, pb = (6, 4), (5, 3)
            else: pa, pb = (3, 4), (5, 6)
            # half rate: phase 0 runs one pair of music tracks, phase 1 the other
            if p == 0 and c in pa: self.fade_step()
            elif p == 1 and c in pb: self.fade_step()
            else: return
        if m[self.t(0x80)] == 0: return
        self.track_tick()

    def fade_step(self):
        """Music fade ($451A): every $70 calls (two per tick) one step; at 5 the drums stop, at 7 CH3,
        at 9 CH1/CH2 and the fade ends. Each step is also one more attenuation (wFadeLevel)."""
        m = self.m
        if m[FADE] == 0:
            m[FTIM] = m[FLVL] = m[FSTEP] = m[FADE] = 0; return
        m[FTIM] = (m[FTIM] + 1) & 0xFF
        if m[FTIM] != 0x70: return
        m[FTIM] = 0; m[FLVL] = (m[FLVL] + 1) & 0xFF; m[FSTEP] = (m[FSTEP] + 1) & 0xFF
        s = m[FSTEP]
        if s == 5: m[0xC680] = m[0xC681] = 0; return
        if s == 7:
            m[0xC580] = m[0xC581] = 0; self.hwwrite(0xFF1C, 0); self.hwwrite(0xFF1A, 0); return
        if s != 9: return
        m[0xC380] = m[0xC381] = 0; m[0xC3A0] = 0
        if m[0xC080] == 0: self.hwwrite(0xFF12, 8); self.hwwrite(0xFF14, 0x80)
        m[0xC480] = m[0xC481] = 0; m[0xC4A0] = 0
        if m[0xC180] == 0: self.hwwrite(0xFF17, 8); self.hwwrite(0xFF19, 0x80)
        m[FTIM] = m[FLVL] = m[FSTEP] = m[FADE] = 0

    # ------------------------------------------------------------- track tick
    def track_tick(self):
        m = self.m; c = self.cur; t = self.t
        m[BASE] = REGBASE[c]
        de = self.tw(0x82)
        m[t(0x84)] = (m[t(0x84)] - 1) & 0xFF
        if m[t(0x84)] == 0:
            m[t(0x86)] &= 0xF3
            if c == 5: m[SH + 0x0A] = 0; self.hwwrite(0xFF1A, 0)
            self.read_cmds(de); return
        if m[t(0x86)] & 0x18: return
        if c in (2, 6): return
        if m[t(0x85)] & 0x10:
            m[t(0xB4)] = (m[t(0xB4)] - 1) & 0xFF
            if m[t(0xB4)] == 0:
                m[t(0x97)] = m[t(0xB3)]; self.write_duty()
        if m[t(0x9A)] >= m[t(0x84)]: m[t(0x86)] |= 4
        if m[t(0x85)] & 4:
            if m[t(0xAF)]: m[t(0xAF)] -= 1
            else: self.vib_tick()
        if c != 5:
            if m[t(0x9A)] != m[t(0x84)]: return
            self.write(2, m[t(0x98)] | m[t(0xA0)]); self.trigger(); return
        # CH3 decay
        if not m[t(0x86)] & 4: return
        if m[t(0x98)] == 0: self.write(2, 0); return
        m[t(0x9D)] = (m[t(0x9D)] - 1) & 0xFF
        if m[t(0x9D)]: return
        m[t(0x9D)] = m[t(0x9E)]
        a = m[t(0xA0)]
        if a == 0: self.write(2, 0); return
        a = (a + 1) & 3; m[t(0xA0)] = a
        if a == 0: self.write(2, 0); return
        a = (a + m[t(0x8B)]) & 0xFF
        v = swap(((a << 1) | 1) & 0xFF) if a < 4 else 0       # rla takes the carry of cp 4: NR32 bit 4 set
        self.write(2, v)

    def vib_tick(self):
        m = self.m; t = self.t
        if m[t(0x9B)]: m[t(0x9B)] -= 1; return
        self.vib_step(); self.write_period()

    def vib_step(self):
        m = self.m; t = self.t
        while True:
            bc = (self.tw(0xA9) + m[t(0xAB)]) & 0xFFFF
            while True:
                v = self.rb(bc)
                if v == 0xFB:
                    m[t(0xAB)] = (m[t(0xAB)] + 1) & 0xFF; m[t(0xAC)] = m[t(0xAB)]; bc += 1; continue
                if v == 0xFE:
                    bc += 1; n = self.rb(bc)
                    if n == m[t(0x8E)]:
                        m[t(0x8E)] = 0; m[t(0xAB)] = (m[t(0xAB)] + 1) & 0xFF; bc += 1; continue
                    if n != 0xFF: m[t(0x8E)] = (m[t(0x8E)] + 1) & 0xFF
                    m[t(0xAB)] = m[t(0xAC)]
                    break                       # re-read from the loop point
                if v == 0xFF: return
                m[t(0x9B)] = m[t(0x9C)] = v >> 4
                if v & 8: m[t(0x85)] |= 8
                else: m[t(0x85)] &= 0xF7
                o = v & 7
                if m[t(0xAD)]: o = (o * m[t(0xAD)]) & 0xFF
                m[t(0x8C)] = o
                m[t(0xAB)] = (m[t(0xAB)] + 1) & 0xFF
                return

    def write_period(self):
        m = self.m; t = self.t
        o = self.tw(0x8C)
        if m[t(0x85)] & 8: o = (-o) & 0xFFFF
        self.write_bc((self.tw(0x92) + o) & 0xFFFF)

    # ------------------------------------------------------------- command reader
    def read_cmds(self, de):
        m = self.m; c = self.cur; t = self.t
        while True:
            op = self.rb(de)
            if op >= 0xFB:
                de += 1
                f = m[t(0x8F)]
                if op == 0xFB or op == 0xFC:
                    bit, cnt, sav = (1, 0x87, 0xA1) if op == 0xFB else (2, 0x88, 0xA3)
                    if not f & bit:
                        m[t(0x8F)] |= bit; self.tws(sav, de); continue
                    n = self.rb(de)
                    m[t(cnt)] = (m[t(cnt)] + 1) & 0xFF
                    if n == m[t(cnt)]:
                        m[t(cnt)] = 0; m[t(0x8F)] &= ~bit & 0xFF; de += 1; continue
                    de = self.tw(sav); continue
                if op == 0xFD:
                    if not f & 4:
                        m[t(0x8F)] |= 4
                        tg = self.rw(de); de += 2; self.tws(0xA5, de); de = tg; continue
                    de = self.tw(0xA5); m[t(0x8F)] &= 0xFB; continue
                if op == 0xFE:
                    if not f & 8: m[t(0x8F)] |= 8; self.tws(0xA7, de); continue
                    de = self.tw(0xA7); continue
                self.end_track(); return
            if m[t(0x86)] & 0x20:
                r = self.raw_reader(de)
                if r is None: return
                de = r; continue
            if op == 0xE0:
                de += 1; m[t(0x90)] = self.rb(de)
                if c == 6: de += 1; continue
                de += 1; x = self.rb(de)
                if c == 2:
                    m[t(0x98)] = x & 15; m[t(0x96)] = x >> 4
                    self.write(2, x); self.trigger(); de += 1; continue
                m[t(0x96)] = x & 15; m[t(0x97)] = x >> 4; m[t(0xB3)] = x >> 4
                self.write_duty()
                de += 1; x = self.rb(de)
                m[t(0x98)] = x & 15; m[t(0x99)] = x >> 4
                de += 1; continue
            hi = op & 0xF0
            if hi < 0xE0:
                self.note(de, op); return
            if hi == 0xF0:
                m[t(0x8B)] = op & 15
                if c == 2: return                 # noise SFX: stops reading without saving the pointer
                de += 1; continue
            if op < 0xE7:
                m[t(0x91)] = ((op & 15) - 1) & 0xFF; de += 1; continue
            de += 1; x = self.rb(de)
            de = self.cmd_e7(op, x, de)

    def cmd_e7(self, op, x, de):
        """$E7-$EF handlers; DE points at the argument. Returns DE of the next command."""
        m = self.m; c = self.cur; t = self.t
        if op == 0xE7: m[t(0x90)] = x
        elif op == 0xE8: m[t(0x98)] = x & 15; m[t(0x99)] = x >> 4
        elif op == 0xE9: m[SWEEP] = x; self.write(0, x)
        elif op == 0xEA:
            h, l = x >> 4, x & 15
            if h == 0: m[t(0x8A)] = l
            elif h == 1: m[t(0x8A)] = (-l) & 0xFF
            elif h == 2: pass
            elif h == 3: m[t(0xB3)] = l; m[t(0x97)] = l; self.write_duty()
            elif h == 4:
                if l: m[t(0x85)] |= 2
                else: m[t(0x85)] &= 0xFD
            else: raise RuntimeError(f'EA {x:02X}')
        elif op == 0xEB:
            n = x & 15
            m[t(0x89)] = n
            if n == 0:
                m[t(0x8C)] = m[t(0x8D)] = 0; m[t(0x85)] &= 0xFB
            else:
                m[t(0x85)] |= 4
                de += 1; y = self.rb(de)
                a = y >> 4; m[t(0xAE)] = a
                if a:
                    u = m[t(0x90)]; a = u
                    for _ in range(y >> 4): a = (a + u) & 0xFF
                m[t(0xAF)] = m[t(0xB0)] = a
                m[t(0xAD)] = y & 15
                self.tws(0xA9, self.rw(self.B()['vibtab'] + ((2 * (n - 1)) & 0xFF)))
                m[t(0x8E)] = 0
        elif op == 0xEC: pass
        elif op == 0xED:
            if x & 0xF0 == 0:
                m[t(0x97)] = m[t(0xB3)]; m[t(0x85)] &= 0xEF
            else:
                m[t(0x85)] |= 0x10; m[t(0xB4)] = m[t(0xB5)] = x >> 4; m[t(0xB2)] = x & 15
        elif op == 0xEE: m[TEMPO] = m[ACC] = x
        elif op == 0xEF:
            if c == 6: return de + 2              # skips one byte too many
            m[t(0xB6)] = x; self.apply_pan()
        return de + 1

    def raw_reader(self, de):
        """Raw stream reader ($4DA5). Returns DE to continue with the flow commands, or None when done."""
        m = self.m; t = self.t
        while True:
            m[t(0x9A)] = 0
            if self.rb(de) == 0xE1:
                de += 1; m[t(0x90)] = self.rb(de)
                de += 1; m[t(0x97)] = self.rb(de) & 15; self.write_duty()
                de += 1; self.write(0, self.rb(de))
                de += 1
            op = self.rb(de)
            if op == 0:
                self.tws(0x82, de + 1)
                m[t(0x86)] |= 8; m[t(0x84)] = m[t(0x90)]; self.write(2, 0); return None
            if op >= 0xE7:
                if op >= 0xFB: return de
                if op < 0xF0 and op in (0xE9, 0xEA, 0xEB, 0xEF):
                    de += 1; x = self.rb(de)
                    if op == 0xEB: m[t(0x90)] = x; de += 1
                    else: de = self.cmd_e7(op, x, de)
                    if self.rb(de) >= 0xFB: return de
                    continue
            self.apply_pan(check=False)
            m[t(0x84)] = m[t(0x90)]
            m[t(0x96)] = op & 0xF0; m[t(0x95)] = op & 15
            de += 1; m[t(0x94)] = self.rb(de)
            self.write_bc(m[t(0x94)] | m[t(0x95)] << 8)
            self.tws(0x82, de + 1)
            self.write(2, m[t(0x96)]); self.trigger()
            return None

    def note(self, de, op):
        m = self.m; c = self.cur; t = self.t
        if m[t(0x85)] & 2:
            if c != 2:
                m[t(0xB6)] = swap(m[t(0xB6)]); self.apply_pan()
        self.tws(0x82, de + 1)
        if c == 2:
            m[t(0x84)] = m[t(0x90)]; self.write_bc(op | 0x8000); return
        lo = op & 15; u = m[t(0x90)]
        m[t(0x84)] = swap(u & 15) if lo == 0 else (lo * u) & 0xFF
        if op & 0xF0 == 0:
            m[t(0x86)] |= 8; self.write(2, 0); return
        m[t(0x86)] &= 0xF7
        if c == 6:
            i = (op >> 4) - 1
            self.local_play(self.rb(self.B()['drummap'] + i)); return
        if m[t(0x85)] & 0x10:
            m[t(0xB4)] = m[t(0xB5)]; m[t(0x97)] = m[t(0xB2)]; self.write_duty()
        g = m[t(0x99)]; L = m[t(0x84)]
        if g == 15: rel = (L - 1) & 0xFF
        else:
            a = 0
            for _ in range(4):
                cy = g & 1; g >>= 1
                if cy: a += L
                a >>= 1
            rel = a
        m[t(0x9A)] = rel; m[t(0x8E)] = 0
        o = (m[t(0x91)] * 12) & 0xFF
        i = (((op >> 4) - 1) + m[t(0x8A)] + o) & 0xFF
        self.tws(0x92, self.rw(self.B()['period'] + 2 * i))
        if m[t(0x85)] & 4:
            m[t(0xAF)] = m[t(0xB0)]; m[t(0xAB)] = 0; self.vib_step()
        self.write_period()
        self.write(2, self.note_volume()); self.trigger()

    def note_volume(self):
        m = self.m; c = self.cur; t = self.t
        m[t(0x85)] &= 0xBF
        if c == 5:
            m[SH + 0x0A] = 0x80; self.hwwrite(0xFF1A, 0x80)
            m[t(0x9D)] = m[t(0x9E)] = m[t(0x98)]
            a = ((m[FLVL] >> 1) + m[t(0x8B)] + (((m[t(0x96)] & 15) >> 1) & 3)) & 0xFF
            if a >= 4: a = 0
            m[t(0xA0)] = a
            return (a << 5) & 0xFF
        f = m[FLVL] if (c >= 3 or self.bank == 15) else 0    # bank 15: older code, fades SFX too
        v = (m[t(0x96)] & 15) - ((f + m[t(0x8B)]) & 0xFF)
        if v < 0: v = 0
        m[t(0xA0)] = swap(v & 0xFF)
        return m[t(0xA0)]

    def end_track(self):
        m = self.m; c = self.cur; t = self.t
        m[t(0x80)] = m[t(0x81)] = 0
        self.write(2, 0)
        if c == 5: self.hwwrite(0xFF1A, 0); return
        if c == 2: return
        if c == 1: page = 0xC4
        elif c == 0: self.hwwrite(0xFF10, 0); page = 0xC3
        else: return
        if m[page << 8 | 0x80] == 0: return
        self.write_duty(page)
        self.apply_pan(page)
        self.write_bc(m[page << 8 | 0x92] | m[page << 8 | 0x93] << 8)
