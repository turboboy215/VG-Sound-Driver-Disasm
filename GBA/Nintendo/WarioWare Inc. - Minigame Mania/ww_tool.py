#!/usr/bin/env python3
"""WarioWare, Inc. (E) sound data tool.

  ww_tool.py extract ROM [DIR]     midi/*.mid + ww_sample_pcm.bin (needed by ww.mk)
  ww_tool.py dump    ROM [OUT]     full decoded dump (songs, instruments, banks, samples, per-song MIDI use)
  ww_tool.py summary ROM [OUT]     the same without the per-song MIDI section
  ww_tool.py wav     ROM DIR       the 711 samples as WAV (8-bit, 'smpl' chunk with root key and loop)
  ww_tool.py midi    ROM DIR       the 1342 MIDI files rewritten for General-MIDI-style players (see below)
  ww_tool.py sf2     ROM OUT.sf2   the instrument banks as a SoundFont 2 (bank number = driver bank)

All names are assigned by the analysis; the only names in the ROM are the song name strings.
"""
import sys, os, struct, collections, math, wave

# ---------------------------------------------------------------- ROM layout (WarioWare, Inc. (E), AZWP)
BANK_TABLE   = 0x08405310   # Instrument **[16]
NBANKS       = 16
BANK_END     = 0x08405310   # the banks are packed back to back, the last one ends at the bank table
SONG_TABLE   = 0x0840BB10   # 1342 x 20 bytes
NSONGS       = 1342
SONG_PTRS    = 0x084123E8   # u32 maxId; SongEntry *[maxId+1]
ID_TABLE     = 0x084140C8   # u32 count; {SongEntry *, u32 group}[count]
PLAYER_CFG   = 0x08417AB4
GROUPS       = 0x08417B6C
SMP_HEADERS  = 0x08417BD8   # 711 x 24 bytes
NSAMPLES     = 711
PCM_START, PCM_END = 0x08155D74, 0x08316338
KEY_FREQ     = 0x083FD1CC   # u16[128] Hz
MIX_RATE     = 13379
FRAME_HZ     = 59.7275

class Rom:
    def __init__(self, path):
        self.d = open(path, 'rb').read()
        if self.d[0xAC:0xB0] != b'AZWP':
            print('warning: game code is %r, expected AZWP (WarioWare, Inc. (E))' % self.d[0xAC:0xB0], file=sys.stderr)
    def u8(self, a): return self.d[a - 0x08000000]
    def u16(self, a): return struct.unpack_from('<H', self.d, a - 0x08000000)[0]
    def s16(self, a): return struct.unpack_from('<h', self.d, a - 0x08000000)[0]
    def u32(self, a): return struct.unpack_from('<I', self.d, a - 0x08000000)[0]
    def be16(self, a): return struct.unpack_from('>H', self.d, a - 0x08000000)[0]
    def be32(self, a): return struct.unpack_from('>I', self.d, a - 0x08000000)[0]
    def blk(self, a, n): return self.d[a - 0x08000000:a - 0x08000000 + n]
    def cstr(self, a):
        e = self.d.index(b'\0', a - 0x08000000)
        return self.d[a - 0x08000000:e].decode('latin1')

    # ---- banks / instruments ----
    def banks(self):
        return [self.u32(BANK_TABLE + 4 * i) for i in range(NBANKS)]
    def bank_len(self, i):
        b = self.banks(); s = sorted(set(b))
        nxt = min([x for x in s if x > b[i]] + [BANK_END])
        return (nxt - b[i]) // 4
    def bank(self, i):
        b = self.banks()[i]
        return [self.u32(b + 4 * k) for k in range(self.bank_len(i))]
    def inst(self, p):
        t = self.u8(p)
        r = dict(addr=p, type=chr(t))
        if t in (0x41, 0x46, 0x50, 0x51):
            r.update(key=self.u8(p + 1) & 0x7F, nointerp=self.u8(p + 1) >> 7, pan=self.s16(p + 2), ptr=self.u32(p + 4),
                     env_start=self.u32(p + 8), sustain=self.u32(p + 12), attack=self.u32(p + 16), decay=self.u32(p + 20),
                     sustain_rate=self.u32(p + 24), release=self.u32(p + 28))
            if t in (0x50, 0x51):
                r['psg'] = self.u32(p + 32)
        elif t == 0x52:
            r.update(base=self.u32(p) >> 8, table=self.u32(p + 4))
        elif t == 0x53:
            r.update(base=self.u32(p) >> 8, keymap=self.u32(p + 4), table=self.u32(p + 8))
        return r
    def resolve(self, bankno, prog, key):
        """Instrument actually played for (bank, program, key), following R/S like chanNoteOn."""
        b = self.banks()[bankno]
        p = self.u32(b + 4 * prog)
        if not p: return None, key, None
        ins = self.inst(p); pan = None
        if ins['type'] == 'R':
            p = self.u32(ins['table'] + 4 * (key - ins['base']))
            if not p: return None, key, None
            sub = self.inst(p)
            if sub['type'] in 'RS': return None, key, None
            pan = 0 if sub['pan'] == 127 else sub['pan']
            return sub, sub['key'], pan
        if ins['type'] == 'S':
            idx = self.u8(ins['keymap'] + key - ins['base'])
            p = self.u32(ins['table'] + 4 * idx)
            if not p: return None, key, None
            sub = self.inst(p)
            if sub['type'] in 'RS': return None, key, None
            return sub, key, None
        return ins, key, None

    # ---- samples ----
    def sample(self, k):
        h = SMP_HEADERS + 24 * k
        return dict(index=k, addr=h, length=self.u32(h), rate=self.u32(h + 4), root=self.u32(h + 8),
                    loop_start=self.u32(h + 12), loop_end=self.u32(h + 16), data=self.u32(h + 20))
    def sample_index(self, hdr):
        return (hdr - SMP_HEADERS) // 24

    # ---- songs ----
    def song(self, k):
        a = SONG_TABLE + 20 * k
        w = self.u32(a + 4)
        return dict(index=k, addr=a, midi=self.u32(a), bank=(w >> 5) & 0x3FF, volume=(w >> 15) & 0x7F,
                    priority=(w >> 22) & 0x3FF, low=w & 31, w8=self.u32(a + 8), name=self.cstr(self.u32(a + 12)),
                    id=self.u32(a + 16))
    def midi_bytes(self, m):
        hl = self.be32(m + 4); a = m + 8 + hl
        for t in range(self.be16(m + 10)):
            a += 8 + self.be32(a + 4)
        return self.blk(m, a - m)
    def groups_of_ids(self):
        n = self.u32(ID_TABLE); g = {}
        for k in range(n):
            e = self.u32(ID_TABLE + 4 + 8 * k)
            if e: g.setdefault(e, set()).add(self.u32(ID_TABLE + 8 + 8 * k))
        return g

def midi_file_name(s):
    return '%04d_%s.mid' % (s['index'], s['name'])

# ---------------------------------------------------------------- MIDI parsing (driver semantics)
def varlen(b, p):
    v = 0
    while True:
        c = b[p]; p += 1; v = (v << 7) | (c & 0x7F)
        if not c & 0x80: return v, p

def parse_smf(b):
    ntr = struct.unpack_from('>H', b, 10)[0]; div = struct.unpack_from('>H', b, 12)[0]
    p = 8 + struct.unpack_from('>I', b, 4)[0]; tracks = []
    for t in range(ntr):
        L = struct.unpack_from('>I', b, p + 4)[0]
        tracks.append(b[p + 8:p + 8 + L]); p += 8 + L
    return div, tracks

def track_events(tb):
    """(tick, status, payload) with running status resolved; payload = data bytes, or (type, bytes) for meta"""
    p = 0; t = 0; rs = 0
    while p < len(tb):
        dt, p = varlen(tb, p); t += dt
        if tb[p] & 0x80: rs = tb[p]; p += 1
        st = rs
        if st == 0xFF:
            typ = tb[p]; L, q = varlen(tb, p + 1)
            yield t, st, (typ, tb[q:q + L]); p = q + L; rs = 0
        elif st in (0xF0, 0xF7):
            L, q = varlen(tb, p); yield t, st, tb[q:q + L]; p = q + L; rs = 0
        else:
            n = 1 if st & 0xF0 in (0xC0, 0xD0) else 2
            yield t, st, tb[p:p + n]; p += n

def write_varlen(v):
    out = [v & 0x7F]; v >>= 7
    while v: out.append(0x80 | (v & 0x7F)); v >>= 7
    return bytes(reversed(out))

# ---------------------------------------------------------------- text output
def env_desc(i):
    def frames(rate, span):
        if span <= 0: return 0
        if rate <= 0: return None
        return -(-span // rate)
    a = frames(i['attack'], 0x7F0000 - i['env_start'])
    dcy = frames(i['decay'], 0x7F0000 - i['sustain'])
    rel = frames(i['release'], i['sustain'] if i['sustain'] else 0x7F0000)
    f = lambda n: 'hold' if n is None else '%d fr' % n
    sr = i['sustain_rate']
    return 'A %s  D %s -> S %.1f/127  %s  R %s' % (f(a), f(dcy), i['sustain'] / 65536,
                                                  'sustain decays %d fr' % frames(sr, i['sustain']) if sr else 'sustain held', f(rel))

def psg_desc(i):
    w = i['psg']; ch = w & 3
    s = ['square 1', 'square 2', 'wave', 'noise'][ch]
    s += ', CNT_H low byte 0x%02X' % ((w >> 2) & 0xFF)
    if ch == 0: s += ', sweep 0x%02X' % ((w >> 10) & 0x7F)
    if ch in (0, 1): s += ', duty %d' % ((w >> 17) & 3)
    if ch == 2: s += ', wave %08X' % i['ptr']
    if ch == 3: s += ', NR43 or-bits 0x%X' % (((w >> 16) >> 3) << 3)
    return s

def cmd_dump(rom, out, with_songs=True):
    P = lambda s='': out.write(s + '\n')
    P('WarioWare, Inc. (E) sound data  (decoded by ww_tool.py; names assigned, song names are ROM strings)')
    P('=' * 100)
    P()
    P('Players (sndPlayerConfig 0x%08X)' % PLAYER_CFG)
    for k in range(9):
        a = PLAYER_CFG + 20 * k; c = rom.u16(a)
        P('  player %d: channels %2d, priority check %d, player RAM %08X, synth %08X, channels %08X, tracks %08X'
          % (c & 31, (c >> 5) & 31, (c >> 10) & 1, rom.u32(a + 16), rom.u32(a + 8), rom.u32(a + 4), rom.u32(a + 12)))
    P()
    gi = rom.groups_of_ids()
    P('Songs (sndSongTable 0x%08X): index, id, group(s), bank, volume, priority, MIDI, tracks, name' % SONG_TABLE)
    for k in range(NSONGS):
        s = rom.song(k); m = s['midi']
        P('  %4d id %4d grp %-5s bank %d vol %3d prio %3d  MIDI %08X (%5d bytes, %d tracks)  %s'
          % (k, s['id'], ','.join(map(str, sorted(gi.get(s['addr'], [])))) or '-', s['bank'], s['volume'], s['priority'],
             m, len(rom.midi_bytes(m)), rom.be16(m + 10), s['name']))
    P()
    P('Banks (sndBankTable 0x%08X)' % BANK_TABLE)
    for i in range(NBANKS):
        ent = rom.bank(i)
        P()
        P('  bank %2d at %08X, %d entries' % (i, rom.banks()[i], len(ent)))
        for k, p in enumerate(ent):
            if not p: continue
            ins = rom.inst(p)
            t = ins['type']
            if t == 'A':
                sm = rom.sample(rom.sample_index(ins['ptr']))
                P('    %3d %08X A  sample %3d (%5d Hz, root %3d, %6d smp%s)  key %d  %s'
                  % (k, p, sm['index'], sm['rate'], sm['root'], sm['length'],
                     ', loop %d-%d' % (sm['loop_start'], sm['loop_end']) if sm['loop_start'] or sm['loop_end'] else '',
                     ins['key'], env_desc(ins)))
            elif t == 'P':
                P('    %3d %08X P  %s  key %d  %s' % (k, p, psg_desc(ins), ins['key'], env_desc(ins)))
            elif t == 'R':
                bi = rom.banks().index(ins['table']) if ins['table'] in rom.banks() else -1
                P('    %3d %08X R  drum map: key k -> bank %d [k - %d]' % (k, p, bi, ins['base']))
            elif t == 'S':
                bi = rom.banks().index(ins['table']) if ins['table'] in rom.banks() else -1
                km = rom.blk(ins['keymap'], 72)
                runs = []; s0 = 0
                for j in range(1, 73):
                    if j == 72 or km[j] != km[s0]:
                        runs.append('%d-%d:%d' % (ins['base'] + s0, ins['base'] + j - 1, km[s0])); s0 = j
                P('    %3d %08X S  key split -> bank %d, keymap %08X  %s' % (k, p, bi, ins['keymap'], ' '.join(runs)))
    P()
    P('Samples (sndSampleHeaders 0x%08X): 8-bit signed PCM' % SMP_HEADERS)
    for k in range(NSAMPLES):
        s = rom.sample(k)
        lp = 'loop %6d-%6d' % (s['loop_start'], s['loop_end']) if s['loop_start'] or s['loop_end'] else 'no loop'
        P('  %3d  hdr %08X  pcm %08X  %6d smp  %5d Hz  root %3d  %s' % (k, s['addr'], s['data'], s['length'], s['rate'], s['root'], lp))
    if not with_songs: return
    P()
    P('Per-song MIDI use (track k drives synth channel k; the status byte channel is ignored)')
    for k in range(NSONGS):
        s = rom.song(k)
        div, tracks = parse_smf(rom.midi_bytes(s['midi']))
        P()
        P('  %4d %s  (bank %d, %d tracks)' % (k, s['name'], s['bank'], len(tracks)))
        for ti, tb in enumerate(tracks):
            progs = []; keys = collections.Counter(); ccs = collections.Counter(); metas = []; notes = 0; end = 0
            prog = 0
            for t, st, pl in track_events(tb):
                end = t
                if st == 0xFF:
                    typ, data = pl
                    if typ in (1, 3, 6): metas.append('%d:%s' % (t, data.decode('latin1')))
                    elif typ == 0x51: metas.append('%d:tempo %.1f' % (t, 60000000 / int.from_bytes(data, 'big')))
                elif st >= 0xF0: metas.append('%d:sysex %s' % (t, pl.hex()))
                else:
                    hi = st & 0xF0
                    if hi == 0xC0: prog = pl[0]; progs.append(prog)
                    elif hi == 0x90 and pl[1]: keys[(prog, pl[0])] += 1; notes += 1
                    elif hi == 0xB0: ccs[pl[0]] += 1
            ins_used = collections.Counter()
            for (pg, key), n in keys.items():
                i, _, _ = rom.resolve(s['bank'], pg, key)
                ins_used['%s@%08X' % (i['type'], i['addr']) if i else 'none(p%d k%d)' % (pg, key)] += n
            P('    trk %d: %d notes, end tick %d, programs %s, CCs %s' % (ti, notes, end, sorted(set(progs)) or '-',
              ' '.join('%d:%d' % kv for kv in sorted(ccs.items())) or '-'))
            if ins_used: P('           instruments: ' + ', '.join('%s x%d' % kv for kv in sorted(ins_used.items())))
            if metas: P('           meta: ' + ' | '.join(metas[:12]) + (' ...' if len(metas) > 12 else ''))

# ---------------------------------------------------------------- extraction and exports
def cmd_extract(rom, outdir):
    os.makedirs(os.path.join(outdir, 'midi'), exist_ok=True)
    for k in range(NSONGS):
        s = rom.song(k)
        open(os.path.join(outdir, 'midi', midi_file_name(s)), 'wb').write(rom.midi_bytes(s['midi']))
    open(os.path.join(outdir, 'ww_sample_pcm.bin'), 'wb').write(rom.blk(PCM_START, PCM_END - PCM_START))
    print('wrote %d MIDI files and ww_sample_pcm.bin to %s' % (NSONGS, outdir))

def pcm_s8(rom, s):
    return rom.blk(s['data'], s['length'])

def cmd_wav(rom, outdir):
    os.makedirs(outdir, exist_ok=True)
    for k in range(NSAMPLES):
        s = rom.sample(k)
        data = bytes((b + 128) & 0xFF for b in pcm_s8(rom, s))
        fn = os.path.join(outdir, 'smp_%03d_%dHz_root%d.wav' % (k, s['rate'], s['root']))
        with open(fn, 'wb') as f:
            fmt = struct.pack('<HHIIHH', 1, 1, s['rate'], s['rate'], 1, 8)
            loops = s['loop_start'] or s['loop_end']
            smpl = struct.pack('<9I', 0, 0, int(1e9 / s['rate']), s['root'], 0, 0, 0, 1 if loops else 0, 0)
            if loops:
                smpl += struct.pack('<6I', 0, 0, s['loop_start'], s['loop_end'] - 1, 0, 0)
            chunks = b'fmt ' + struct.pack('<I', len(fmt)) + fmt
            chunks += b'data' + struct.pack('<I', len(data)) + data + (b'\0' if len(data) & 1 else b'')
            chunks += b'smpl' + struct.pack('<I', len(smpl)) + smpl
            f.write(b'RIFF' + struct.pack('<I', 4 + len(chunks)) + b'WAVE' + chunks)
    print('wrote %d WAV files to %s' % (NSAMPLES, outdir))

def gm_channel(track):
    """driver channel (= track index) -> MIDI channel for export; skip channel 9 (GM drums)"""
    c = track if track < 9 else track + 1
    return c & 15

def cmd_midi(rom, outdir):
    """Rewrite each song so that a normal MIDI player driven by ww.sf2 sounds close to the driver:
       - every channel event is moved to channel gm_channel(track) (the driver ignores the status channel);
       - bank select (CC0 = driver bank, CC32 = 0) is inserted at the start of each track;
       - CC20 (driver: pitch-bend range) becomes RPN 0 + data entry;
       - the driver-only controllers (CC14/16/21/22/26/33/72-84) are dropped; everything else is kept."""
    os.makedirs(outdir, exist_ok=True)
    DROP = {13, 14, 16, 21, 22, 26, 33, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 0, 32}
    for k in range(NSONGS):
        s = rom.song(k)
        div, tracks = parse_smf(rom.midi_bytes(s['midi']))
        out_tracks = []
        for ti, tb in enumerate(tracks):
            ch = gm_channel(ti)
            evs = []
            if ti > 0:
                evs.append((0, bytes([0xB0 | ch, 0, s['bank']])))
                evs.append((0, bytes([0xB0 | ch, 32, 0])))
                evs.append((0, bytes([0xC0 | ch, 0])))            # driver channels start at program 0
                evs.append((0, bytes([0xB0 | ch, 101, 0, 0xB0 | ch, 100, 0, 0xB0 | ch, 6, 2, 0xB0 | ch, 38, 0])))
            for t, st, pl in track_events(tb):
                if st == 0xFF:
                    typ, data = pl
                    if typ == 0x2F: continue
                    evs.append((t, bytes([0xFF, typ]) + write_varlen(len(data)) + data))
                elif st >= 0xF0:
                    evs.append((t, bytes([st]) + write_varlen(len(pl)) + pl))
                else:
                    hi = st & 0xF0
                    if hi == 0xB0 and pl[0] == 20:
                        evs.append((t, bytes([0xB0 | ch, 101, 0, 0xB0 | ch, 100, 0, 0xB0 | ch, 6, pl[1], 0xB0 | ch, 38, 0])))
                        continue
                    if hi == 0xB0 and pl[0] in DROP: continue
                    evs.append((t, bytes([hi | ch]) + bytes(pl)))
            end = max([t for t, _ in evs], default=0)
            tb2 = bytearray(); last = 0
            for t, ev in evs:
                # multi-event blobs (the inserted CC sequences) are split into separate zero-delta events
                if ev[0] & 0xF0 == 0xB0 and len(ev) > 3:
                    for j in range(0, len(ev), 3):
                        tb2 += write_varlen(t - last if j == 0 else 0) + ev[j:j + 3]
                else:
                    tb2 += write_varlen(t - last) + ev
                last = t
            tb2 += write_varlen(end - last) + b'\xFF\x2F\x00'
            out_tracks.append(bytes(tb2))
        body = b'MThd' + struct.pack('>IHHH', 6, 1, len(out_tracks), div)
        for tb2 in out_tracks: body += b'MTrk' + struct.pack('>I', len(tb2)) + tb2
        open(os.path.join(outdir, midi_file_name(s)), 'wb').write(body)
    print('wrote %d MIDI files to %s' % (NSONGS, outdir))

# ---------------------------------------------------------------- SoundFont export
def sf2_chunk(cid, data):
    return cid + struct.pack('<I', len(data)) + data + (b'\0' if len(data) & 1 else b'')
def sf2_list(lid, body):
    return b'LIST' + struct.pack('<I', 4 + len(body)) + lid + body

def secs_to_tc(sec):
    if sec <= 0.001: return -12000
    return max(-12000, min(8000, int(round(1200 * math.log2(sec)))))

def psg_wave(rom, ins):
    """one looped period (or noise burst) of a PSG instrument, 8-bit signed, with its 'rate' and root key"""
    w = ins['psg']; ch = w & 3
    if ch in (0, 1):
        duty = (w >> 17) & 3 if ch == 0 else (w >> 17) & 3
        high = [4, 8, 16, 24][duty]
        per = bytes([0x60 if i < high else 0xA0 for i in range(32)])
        return per, 32 * 440, 69, True      # 32 samples per period at A4
    if ch == 2:
        raw = rom.blk(ins['ptr'], 16) if ins['ptr'] else bytes(16)
        nib = []
        for b in raw: nib += [b >> 4, b & 15]
        per = bytes(((n - 8) * 14) & 0xFF for n in nib)
        return per, 32 * 440, 69, True
    import random
    r = random.Random(1234)
    per = bytes(r.choice((0x60, 0xA0)) for _ in range(8192))
    return per, 22050, 60, True

def cmd_sf2(rom, outpath):
    """Presets: bank B / program P for the program banks 1-3 (as used by the songs).
       A instruments -> one zone; S -> one zone per keymap run; R (drum maps) -> one zone per key with the
       sub-instrument's fixed key and pan; P (PSG) -> synthesized square / wave / noise loops.
       Envelopes: attack/decay/release converted from frames (60 Hz linear steps) to seconds; sustain level to
       attenuation (the driver's envelope is linear in amplitude, SoundFont decay is linear in dB, so the shapes
       only roughly match)."""
    samples = []       # (name, pcm s8 bytes, rate, root, loop_start, loop_end)
    smp_index = {}
    def add_sample(key, name, pcm, rate, root, ls, le):
        if key in smp_index: return smp_index[key]
        smp_index[key] = len(samples)
        samples.append((name, pcm, rate, root, ls, le)); return smp_index[key]
    def sample_for(ins):
        if ins['type'] == 'A':
            k = rom.sample_index(ins['ptr']); s = rom.sample(k)
            return add_sample(('A', k), 'smp%03d' % k, pcm_s8(rom, s), s['rate'], s['root'], s['loop_start'], s['loop_end']), \
                   bool(s['loop_start'] or s['loop_end'])
        per, rate, root, lp = psg_wave(rom, ins)
        k = ('P', ins['psg'] & 3, (ins['psg'] >> 17) & 3, ins['ptr'])
        return add_sample(k, 'psg%d_%d' % (ins['psg'] & 3, len(samples)), per, rate, root, 0, len(per)), True

    def gens_for(ins, lo, hi, fixed_key=None, pan=None):
        g = [(43, lo | (hi << 8))]            # keyRange first
        def fr2s(rate, span):
            if span <= 0: return 0.0
            if rate <= 0: return 100.0
            return math.ceil(span / rate) / FRAME_HZ
        att = fr2s(ins['attack'], 0x7F0000 - ins['env_start'])
        dec = fr2s(ins['decay'], 0x7F0000 - ins['sustain'])
        rel = fr2s(ins['release'], ins['sustain'] if ins['sustain'] else 0x7F0000)
        lvl = max(ins['sustain'], 1) / 0x7F0000
        sus_cb = min(1440, int(round(-200 * math.log10(lvl))))
        if ins['sustain_rate'] > 0 and ins['sustain']:
            sus_cb = 1440; dec = dec + fr2s(ins['sustain_rate'], ins['sustain'])
        g += [(34, secs_to_tc(att)), (36, secs_to_tc(dec)), (37, sus_cb), (38, secs_to_tc(rel))]
        if pan is not None and pan != 0:
            g.append((17, max(-500, min(500, int(pan * 500 / 64)))))
        if fixed_key is not None:
            g.append((46, fixed_key))           # keynum
        si, looped = sample_for(ins)
        if looped: g.append((54, 1))
        s = samples[si]
        return g, si

    presets = []   # (name, bank, prog, [zones]) zone = (gens, sample index)
    for b in (1, 2, 3):
        for prog, p in enumerate(rom.bank(b)[:128]):
            if not p: continue
            ins = rom.inst(p); zones = []
            if ins['type'] in 'AP':
                zones.append(gens_for(ins, 0, 127))
            elif ins['type'] == 'S':
                km = rom.blk(ins['keymap'], 72); tab = ins['table']
                s0 = 0
                for j in range(1, 73):
                    if j == 72 or km[j] != km[s0]:
                        sp = rom.u32(tab + 4 * km[s0])
                        if sp:
                            sub = rom.inst(sp)
                            if sub['type'] in 'AP':
                                zones.append(gens_for(sub, ins['base'] + s0, ins['base'] + j - 1))
                        s0 = j
            elif ins['type'] == 'R':
                tab = ins['table']
                bi = rom.banks().index(tab)
                for j in range(rom.bank_len(bi)):
                    sp = rom.u32(tab + 4 * j)
                    key = ins['base'] + j
                    if not sp or key > 127: continue
                    sub = rom.inst(sp)
                    if sub['type'] not in 'AP': continue
                    zones.append(gens_for(sub, key, key, fixed_key=sub['key'],
                                          pan=0 if sub['pan'] == 127 else sub['pan']))
            if zones:
                presets.append(('b%d p%d %s' % (b, prog, ins['type']), b, prog, zones))

    # ---- build sdta (16-bit), shdr
    smpl = bytearray(); shdr = b''
    for name, pcm, rate, root, ls, le in samples:
        start = len(smpl) // 2
        for c in pcm:
            v = c - 256 if c > 127 else c
            smpl += struct.pack('<h', v * 256)
        n = len(pcm)
        if not (ls or le): ls, le = 0, n
        smpl += bytes(46 * 2)
        shdr += struct.pack('<20sIIIIIBbHH', name.encode()[:19], start, start + n, start + ls, start + le, rate, root, 0, 0, 1)
    shdr += struct.pack('<20sIIIIIBbHH', b'EOS', 0, 0, 0, 0, 0, 0, 0, 0, 0)
    # ---- instruments: one SF2 instrument per preset
    inst = b''; ibag = b''; igen = b''; ibag_i = 0; igen_i = 0
    phdr = b''; pbag = b''; pgen = b''; pbag_i = 0; pgen_i = 0
    for ii, (name, b, prog, zones) in enumerate(presets):
        inst += struct.pack('<20sH', name.encode()[:19], ibag_i)
        for gens, si in zones:
            ibag += struct.pack('<HH', igen_i, 0); ibag_i += 1
            for op, amt in gens:
                igen += struct.pack('<Hh' if amt < 0 else '<HH', op, amt); igen_i += 1
            igen += struct.pack('<HH', 53, si); igen_i += 1
        phdr += struct.pack('<20sHHHIII', name.encode()[:19], prog, b, pbag_i, 0, 0, 0)
        pbag += struct.pack('<HH', pgen_i, 0); pbag_i += 1
        pgen += struct.pack('<HH', 41, ii); pgen_i += 1
    inst += struct.pack('<20sH', b'EOI', ibag_i)
    ibag += struct.pack('<HH', igen_i, 0); igen += struct.pack('<HH', 0, 0)
    phdr += struct.pack('<20sHHHIII', b'EOP', 0, 0, pbag_i, 0, 0, 0)
    pbag += struct.pack('<HH', pgen_i, 0); pgen += struct.pack('<HH', 0, 0)
    pmod = struct.pack('<HHhHH', 0, 0, 0, 0, 0); imod = pmod
    info = sf2_list(b'INFO', sf2_chunk(b'ifil', struct.pack('<HH', 2, 1)) + sf2_chunk(b'isng', b'EMU8000\0') +
                    sf2_chunk(b'INAM', b'WarioWare Inc sound banks\0'))
    sdta = sf2_list(b'sdta', sf2_chunk(b'smpl', bytes(smpl)))
    pdta = sf2_list(b'pdta', sf2_chunk(b'phdr', phdr) + sf2_chunk(b'pbag', pbag) + sf2_chunk(b'pmod', pmod) +
                    sf2_chunk(b'pgen', pgen) + sf2_chunk(b'inst', inst) + sf2_chunk(b'ibag', ibag) +
                    sf2_chunk(b'imod', imod) + sf2_chunk(b'igen', igen) + sf2_chunk(b'shdr', shdr))
    body = b'sfbk' + info + sdta + pdta
    open(outpath, 'wb').write(b'RIFF' + struct.pack('<I', len(body)) + body)
    print('wrote %s: %d presets, %d samples' % (outpath, len(presets), len(samples)))

def main():
    if len(sys.argv) < 3:
        print(__doc__); sys.exit(1)
    cmd, rom = sys.argv[1], Rom(sys.argv[2])
    arg = sys.argv[3] if len(sys.argv) > 3 else None
    if cmd == 'extract': cmd_extract(rom, arg or '.')
    elif cmd in ('dump', 'summary'):
        out = open(arg, 'w') if arg else sys.stdout
        cmd_dump(rom, out, with_songs=(cmd == 'dump'))
    elif cmd == 'wav': cmd_wav(rom, arg or 'ww_wav')
    elif cmd == 'midi': cmd_midi(rom, arg or 'ww_midi')
    elif cmd == 'sf2': cmd_sf2(rom, arg or 'ww.sf2')
    else:
        print(__doc__); sys.exit(1)

if __name__ == '__main__':
    main()
