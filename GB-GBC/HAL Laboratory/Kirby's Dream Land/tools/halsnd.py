"""HAL Laboratory GB sound engine: music/SFX data parser (KDL-family command set).

Main stream byte  LLLNNNNN
    LLL 0-5 : length index into the current length set (wTrkLengthSet + LLL)
    LLL 6   : explicit length, next byte = frames
    LLL 7   : command ($E0-$FF)
    NNNNN   : tone tracks: signed offset from wTrkBaseNote, $10 = rest
              noise track: bit4 = keep NR43 (no new drum), low nibble = drum ($F = rest)
Envelope (macro) stream bytes
    000wwwww wait w frames
    001Wssss pitch += s (signed nibble), W = then wait 1 frame
    010Wvvvv envelope volume = v
    011Wssss envelope volume += s
    100Wxxxx duty (bits 0-1, ch1/2/4) / wave number (ch3)
    $F0 xx   reg 0 of the channel (NR10 / NR30)
    $F8..$FD flow control (own stack), $FF end
"""

HW = {0x00: 'CH1', 0x04: 'CH2', 0x10: 'CH3', 0x0C: 'CH4'}


def s5(v):
    v &= 0x1F
    return v - 32 if v & 0x10 else v


def s4(v):
    v &= 0x0F
    return v - 16 if v & 8 else v


class HalMusic:
    # command -> (name, argsize) for the main stream
    MAIN_CMDS = {
        0xE1: ('sync', 1), 0xE2: ('frequency', 2), 0xE3: ('detune', 1),
        0xF0: ('volume', 1), 0xF1: ('volume_add', 1), 0xF2: ('length_set', 1), 0xF3: ('hold', 1),
        0xF4: ('gate', 1), 0xF5: ('base_note', 1), 0xF6: ('instrument', 1), 0xF7: ('tuning', 1),
        0xF8: ('snd_jump', 2), 0xFA: ('snd_call', 2), 0xFB: ('snd_ret', 0), 0xFC: ('snd_loop', 1), 0xFD: ('snd_endloop', 0),
        0xFE: ('pan', 1), 0xFF: ('snd_end', 0),
    }
    ENV_CMDS = {0xF0: ('env_reg0', 1), 0xF8: ('env_jump', 2), 0xFA: ('env_call', 2), 0xFB: ('env_ret', 0),
                0xFC: ('env_loop', 1), 0xFD: ('env_endloop', 0), 0xFF: ('env_end', 0)}

    def __init__(self, g, read=None):
        self.g = g                      # AsmGen used for the data region
        self.rd = read or g.b           # byte reader for data addresses
        self.todo = []
        self.kinds = {}                 # stream start -> kind
        self.hwof = {}                  # stream start -> hw
        self.reads = {}                 # addr -> 'main'/'env'/'hdr' (expected read sites)
        self.notes_in = set()
        self.instruments_used = set()
        self.static_instruments = set()
        self.extra_main_cmds = {}
        self.pan_sites = []
        self.pfx = ''

    # --- names ---
    def lab(self, a, name=None, prefix='Seq'):
        return self.g.label(a, name, self.pfx + prefix)

    def ptr(self, a):
        return self.g.sym(a)

    # --- headers ---
    def header(self, a, name, ident):
        g = self.g
        n = self.rd(a)
        self.lab(a, name)
        g.item(a, 1, 'db %d' % n, 'tracks')
        self.reads[a] = 'hdr'
        tracks = []
        for i in range(n):
            p = a + 1 + 3 * i
            ptr = self.rd(p) | (self.rd(p + 1) << 8)
            hw = self.rd(p + 2)
            tn = '%s_%s' % (ident, HW.get(hw, 'HW%02X' % hw))
            if tn in self.g.labels.values():
                tn = '%s_%d' % (tn, i)
            if ptr not in self.g.labels:
                self.lab(ptr, tn)
            tracks.append((ptr, hw))
            self.add(ptr, 'main', hw)
            for k in range(3):
                self.reads[p + k] = 'hdr'
        return n, tracks

    def emit_header_items(self, a):
        g = self.g
        n = self.rd(a)
        for i in range(n):
            p = a + 1 + 3 * i
            ptr = self.rd(p) | (self.rd(p + 1) << 8)
            hw = self.rd(p + 2)
            g.item(p, 3, Lazy(lambda ptr=ptr, hw=hw: 'track %s, %s' % (g.sym(ptr), HW.get(hw, '$%02X' % hw))))

    def add(self, a, kind, hw):
        if (a, kind) in self.kinds.items():
            return
        self.todo.append((a, kind, hw))

    # --- walkers ---
    def run(self):
        while self.todo:
            a, kind, hw = self.todo.pop(0)
            if a in self.kinds:
                if self.kinds[a] != kind:
                    self.g.errors.append('stream %04X used as %s and %s' % (a, self.kinds[a], kind))
                continue
            self.kinds[a] = kind
            self.hwof[a] = hw
            self.walk(a, kind, hw)

    # ---- pure decoders: return (size, text, stop, target) ----
    def dec_main(self, a, hw, commit=True):
        g = self.g
        noise = (hw == 0x0C)
        c = self.rd(a)
        if (c & 0xE0) == 0xE0:
            if c in self.extra_main_cmds:
                return self.extra_main_cmds[c](self, a, hw, commit)
            if c not in self.MAIN_CMDS:
                return None
            name, n = self.MAIN_CMDS[c]
            if c in (0xF8, 0xFA):
                t = self.rd(a + 1) | (self.rd(a + 2) << 8)
                return 3, Lazy(lambda name=name, t=t: '%s %s' % (name, g.sym(t))), c == 0xF8, t
            if n == 0:
                return 1, name, c in (0xFF, 0xFB), None
            if n == 1:
                v = self.rd(a + 1)
                if c == 0xF6:
                    if commit:
                        self.instruments_used.add(v & 0x7F)
                        if v & 0x80:
                            self.static_instruments.add(v & 0x7F)
                    txt = 'instrument %d%s' % (v & 0x7F, ', STATIC' if v & 0x80 else '')
                elif c in (0xF1, 0xE3):
                    txt = '%s %d' % (name, v - 256 if v & 0x80 else v)
                elif c == 0xFE:
                    if commit:
                        self.pan_sites.append((a, hw, v))
                    txt = 'pan %s' % ({1: 'PAN_L', 2: 'PAN_R', 3: 'PAN_LR', 0: 'PAN_OFF'}.get(v, '$%02X' % v))
                elif c == 0xF0:
                    txt = 'volume %d' % v if v < 16 else 'volume $%02X' % v
                else:
                    txt = '%s %d' % (name, v) if c in (0xF2, 0xF3, 0xF4, 0xFC) else '%s $%02X' % (name, v)
                return 2, txt, False, None
            v = self.rd(a + 1) | (self.rd(a + 2) << 8)
            return 3, '%s $%04X' % (name, v), False, None
        L = c >> 5
        nn = c & 0x1F
        if L == 6:
            ln = self.rd(a + 1)
            if noise:
                txt = 'drum_x %d, %d' % (nn, ln) if nn != 0x0F else 'drest_x %d' % ln
            else:
                txt = 'rest_x %d' % ln if nn == 0x10 else 'note_x %d, %d' % (s5(nn), ln)
            return 2, txt, False, None
        if noise:
            txt = 'drum %d, %d' % (nn, L) if nn != 0x0F else 'drest %d' % L
        else:
            txt = 'rest %d' % L if nn == 0x10 else 'note %d, %d' % (s5(nn), L)
        return 1, txt, False, None

    def dec_env(self, a, hw, commit=True):
        g = self.g
        c = self.rd(a)
        top = c & 0xE0
        if top == 0x00:
            return 1, 'env_wait %d' % (c & 0x1F), False, None
        if top in (0x20, 0x40, 0x60, 0x80):
            w = ', WAIT' if c & 0x10 else ''
            if top == 0x20:
                t = 'env_pitch %d%s' % (s4(c), w)
            elif top == 0x40:
                t = 'env_vol %d%s' % (c & 15, w)
            elif top == 0x60:
                t = 'env_vol_add %d%s' % (s4(c), w)
            else:
                t = 'env_timbre %d%s' % (c & 15, w)
            return 1, t, False, None
        if c not in self.ENV_CMDS:
            return None
        name, n = self.ENV_CMDS[c]
        if c in (0xF8, 0xFA):
            t = self.rd(a + 1) | (self.rd(a + 2) << 8)
            return 3, Lazy(lambda name=name, t=t: '%s %s' % (name, g.sym(t))), c == 0xF8, t
        if n == 0:
            return 1, name, c in (0xFF, 0xFB), None
        v = self.rd(a + 1)
        return 2, '%s %s' % (name, ('$%02X' % v) if c == 0xF0 else str(v)), False, None

    def walk(self, a, kind, hw):
        g = self.g
        dec = self.dec_main if kind == 'main' else self.dec_env
        while True:
            if a in g.owner:
                if g.owner[a] != a:
                    g.errors.append('%s stream misaligned at %04X' % (kind, a))
                return
            r = dec(a, hw)
            if r is None:
                g.errors.append('bad %s byte %02X at %04X' % (kind, self.rd(a), a))
                g.item(a, 1, 'db $%02X' % self.rd(a), 'INVALID')
                return
            size, txt, stop, t = r
            for k in range(size):
                self.reads[a + k] = kind
            if t is not None:
                if t not in g.labels:
                    self.lab(t, None, ('Sub' if self.rd(a) == 0xFA else 'Seq') if kind == 'main' else 'Env')
                self.add(t, kind, hw)
            g.item(a, size, txt)
            if stop:
                return
            a += size

    def walk_main(self, a, hw):
        self.walk(a, 'main', hw)

    def walk_env(self, a, hw):
        self.walk(a, 'env', hw)

    def orphans(self, kinds=('main', 'env'), hw=0x00):
        """Decode unparsed gaps that decode cleanly (ending exactly at the gap end) as unreferenced streams."""
        g = self.g
        done = []
        for s, e in g.gaps():
            order = list(kinds)
            if self.reads.get(s - 1) == 'env' and 'env' in order:
                order.remove('env')
                order.insert(0, 'env')
            for kind in order:
                dec = self.dec_main if kind == 'main' else self.dec_env
                a, out, ok = s, [], True
                while a < e:
                    r = dec(a, hw, commit=False)
                    if r is None or a + r[0] > e:
                        ok = False
                        break
                    out.append((a, r))
                    a += r[0]
                if ok and out:
                    first = True
                    for a, (size, txt, stop, t) in out:
                        if t is not None and t not in g.labels:
                            self.lab(t, None, 'Seq' if kind == 'main' else 'Env')
                        g.item(a, size, txt, ('unreferenced (%s)' % ('stream' if kind == 'main' else 'envelope')) if first else None)
                        first = stop
                    done.append((s, e, kind))
                    break
        return done


class Lazy:
    """Item text resolved at emit time (labels may be added later)."""
    def __init__(self, f):
        self.f = f

    def __str__(self):
        return self.f()
