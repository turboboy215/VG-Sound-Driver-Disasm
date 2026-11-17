"""Generate RGBDS disassemblies of the Realtime Associates sound driver banks.

usage: python gen_rta.py <Zoop ROM> <SROTJ ROM> [outdir]

Writes:
  Zoop_SoundDriver.asm         bank 3 of Zoop (U)
  SROTJ_SoundDriver_Bank4.asm  bank 4 of Star Wars - Super Return of the Jedi (U)
  SROTJ_SoundDriver_Bank5.asm  bank 5 of the same ROM
"""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode  # noqa: E402
from rta import Bank, parse_song, parse_sfx  # noqa: E402

# ---------------------------------------------------------------------------
# Names (Zoop addresses; SROTJ addresses are derived by walking both copies)

CODE_LABELS = {
    0x4001: 'SndJumpTable',
    0x400D: 'SndInit',
    0x401C: 'SndPausePlay',
    0x402A: 'SndStopAll',
    0x4031: 'SndPowerCycle',
    0x403A: 'SndUpdate',
    0x4041: 'SfxUpdate',
    0x4057: '.running',
    0x4064: '.readEvent',
    0x4091: '.rand',
    0x40A3: '.jump',
    0x40A9: '.noise',
    0x40BC: '.wave',
    0x40BE: '.pulse2',
    0x40DD: '.pulse1',
    0x410A: '.savePtr',
    0x4113: 'MusicUpdate',
    0x4127: '.tick',
    0x4136: '.readEvent',
    0x4160: '.noteOn',
    0x419E: '.setVoiceOn',
    0x41AE: '.release',
    0x41DE: '.setVoiceRel',
    0x41E9: '.releaseDone',
    0x41ED: '.program',
    0x41FE: '.goto',
    0x4203: 'UpdateVoices',
    0x4209: '.loop',
    0x4221: '.step',
    0x426C: '.keepPitch',
    0x4276: '.addDelta',
    0x428A: '.pan',
    0x42B2: '.noChain',
    0x42B3: '.regs',
    0x42CE: '.loadWave',
    0x42E2: '.copyWave',
    0x42FA: '.noise',
    0x4311: '.periodOnly',
    0x4314: '.writePeriod',
    0x4316: '.writePeriodHL',
    0x4320: '.next',
    0x432E: 'SndPlay',
    0x433C: '.startSfx',
    0x4353: '.freeCh2',
    0x4360: '.freeCh3',
    0x436D: '.freeCh4',
    0x437A: '.setSfx',
    0x43A1: '.playMusic',
    0x43B5: 'MusicStart',
    0x43E9: 'SndRandom',
    0x43F5: '.shift',
    0x43FA: 'SndSilence',
}

CODE_COMMENTS = {
    0x4001: 'SndUpdate: call once per tick',
    0x4004: 'SndPlay: a = sound id',
    0x4007: 'SndStopAll',
    0x400A: 'SndPausePlay: pause the music, then play a',
    0x400D: 'init / resume',
    0x4064: 'SFX event loop',
    0x407E: 'n >= 4: wait n-4 frames (0 = end)',
    0x4136: 'music event loop',
    0x413B: '$FE id: start song id',
    0x4140: '$FF: end (the stream stays here)',
    0x4143: 'note-def index (< numDefs)?',
    0x4147: 'release, MIDI channel 0-15?',
    0x414C: 'program change, MIDI channel 0-15?',
    0x4151: 'otherwise: wait',
    0x4188: 'programs $48+ use the noise voice',
    0x4247: 'flags bit 0: set the period from the note',
    0x4280: 'period overflowed past 11 bits: zero it',
    0x428E: 'NR51 = (NR51 & and) | or',
    0x4298: 'hl = the voice (pushed bc)',
    0x42B7: 'reg cmd: $FD noise, $FE wave, $FF period only',
    0x42F1: 'write the period to NR33/NR34',
    0x4310: 'returns from UpdateVoices (ch4 is the last voice)',
    0x432F: 'bit 7: music',
    0x4333: 'bit 6: high priority, always plays',
    0x4337: 'a high-priority SFX is running',
}

# RAM (Zoop WRAM; SROTJ HRAM = Zoop + $208A)
RAM_VARS = [
    (0xDF00, 1, 'wSndRandom'),
    (0xDF01, 1, 'wSndUnused01'),
    (0xDF02, 1, 'wSfxTranspose'),
    (0xDF03, 1, 'wSfxTimer'),
    (0xDF04, 2, 'wSfxPtr'),
    (0xDF06, 1, 'wSfxWaitAdd'),
    (0xDF07, 1, 'wSfxOwnCh1'),
    (0xDF08, 1, 'wSfxOwnCh2'),
    (0xDF09, 1, 'wSfxOwnCh3'),
    (0xDF0A, 1, 'wSfxOwnCh4'),
    (0xDF0B, 1, 'wSfxHighPri'),
    (0xDF0C, 1, 'wMusNumDefs'),
    (0xDF0D, 2, 'wMusDefs'),
    (0xDF0F, 2, 'wMusPtr'),
    (0xDF11, 1, 'wMusTimer'),
    (0xDF12, 1, 'wMusUnused12'),
    (0xDF13, 1, 'wMusUnused13'),
    (0xDF14, 1, 'wMusPaused'),
    (0xDF15, 1, 'wMusWave'),
    (0xDF16, 6, 'wVoice1'),
    (0xDF1C, 6, 'wVoice2'),
    (0xDF22, 6, 'wVoice3'),
    (0xDF28, 6, 'wVoice4'),
    (0xDF2E, 16, 'wChanProg'),
]
VOICE_FIELDS = ['VOICE_TIMER', 'VOICE_PATCH', 'VOICE_NOTE', 'VOICE_PERLO', 'VOICE_PERHI', 'VOICE_COUNT']

HW = {0xFF10 + i: n for i, n in enumerate(
    'NR10 NR11 NR12 NR13 NR14 NR20 NR21 NR22 NR23 NR24 NR30 NR31 NR32 NR33 NR34 '
    'NR40 NR41 NR42 NR43 NR44 NR50 NR51 NR52'.split())}
HW = {a: 'r' + n for a, n in HW.items()}
HW[0xFF30] = '_AUD3WAVERAM'
HW[0xFF20] = 'rNR41'
HW[0xFF21] = 'rNR42'
HW[0xFF22] = 'rNR43'
HW[0xFF23] = 'rNR44'
HW[0xFF1F] = 'rNR40'

NOTE_NAMES = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']


def note_name(v):
    """v = note value in a song's note-def table; period index v-3, 0 = C2."""
    if v > 83:
        return '$%02X' % v
    s = v - 3 + 24  # semitones above C0
    return '%s%d' % (NOTE_NAMES[s % 12], s // 12)


def hx(v, w=2):
    return '$%0*X' % (w, v)


# ---------------------------------------------------------------------------

class Driver:
    def __init__(self, data, bank, hram):
        self.bk = Bank(data, bank)
        self.bank = bank
        self.hram = hram
        self.ramofs = 0x208A if hram else 0
        self.t = self.bk.find_tables()
        self.code_end = self.t['Waves']

    # -- mapping Zoop code addresses to this copy
    def build_labels(self, zoop):
        zm = lambda a: zoop.bk.b(a)  # noqa: E731
        mm = self.bk.b
        za, ma = 0x4001, 0x4001
        amap = {}
        while za < zoop.code_end:
            amap[za] = ma
            zl = decode(zm, za)[0]
            ml = decode(mm, ma)[0]
            za += zl
            ma += ml
        assert ma == self.code_end, (hex(ma), hex(self.code_end))
        self.labels = {amap[a]: n for a, n in CODE_LABELS.items()}
        self.comments = {amap[a]: c for a, c in CODE_COMMENTS.items()}
        self.globals = {}
        cur = None
        for a in sorted(self.labels):
            n = self.labels[a]
            if not n.startswith('.'):
                cur = n
            self.globals[a] = cur
        t = self.t
        self.tables = {t['Waves']: 'Waves', t['Periods']: 'Periods', t['RegBase']: 'RegBase',
                       t['SlotOfs']: 'VoiceOfs', t['Attack']: 'ProgAttack', t['Release']: 'ProgRelease',
                       t['Patches']: 'Patches', t['Sounds']: 'SoundTable'}

    def ram_name(self, a):
        z = a - self.ramofs
        for base, size, name in RAM_VARS:
            if base <= z < base + size:
                if self.hram:
                    name = 'h' + name[1:]
                off = z - base
                if name[1:].startswith('Voice') and off:
                    return '%s + %s' % (name, VOICE_FIELDS[off])
                return name if off == 0 else '%s + %d' % (name, off)
        return None

    def opname(self, scope):
        def f(w, kind):
            if kind in ('jr', 'jp', 'jpend', 'call', 'jrend'):
                n = self.labels.get(w)
                if n is None:
                    return hx(w, 4)
                if n.startswith('.') and self.globals[w] != scope:
                    return self.globals[w] + n
                return n
            if w in self.tables:
                return self.tables[w]
            if w in HW:
                return HW[w]
            r = self.ram_name(w)
            if r:
                return r
            return hx(w, 4)
        return f

    def code(self, out):
        a = 0x4001
        scope = None
        while a < self.code_end:
            if a in self.labels:
                n = self.labels[a]
                if not n.startswith('.'):
                    scope = n
                    out.append('')
                out.append(n + ':' if n.startswith('.') else n + ':')
            ln, txt, kind, tgt = decode(self.bk.b, a, self.opname(scope))
            # immediates that are register addresses or RAM written via ld r16
            raw = ' '.join('%02X' % self.bk.b(a + i) for i in range(ln))
            c = self.comments.get(a)
            line = '\t%-28s; %04X: %s' % (txt, a, raw)
            if c:
                line += '  ' + c
            out.append(line)
            a += ln


def db_lines(bk, a, end, per=16, comment=None):
    out = []
    while a < end:
        n = min(per, end - a)
        out.append('\tdb ' + ', '.join(hx(bk.b(a + i)) for i in range(n)))
        a += n
    return out


def gen_bank(drv, game, songs_named, out_inc_name):
    bk = drv.bk
    t = drv.t
    o = []
    o.append('; ' + '-' * 75)
    o.append('; %s, bank %d: Realtime Associates sound driver (David Warhol)' % (game, drv.bank))
    o.append('; Generated by tools/gen_rta.py; rebuilds byte-exact with RGBDS.')
    o.append('; ' + '-' * 75)
    o.append('')
    o.append('INCLUDE "%s"' % out_inc_name)
    o.append('')
    if drv.hram:
        o.append('INCLUDE "rta_hram.inc"')
    else:
        o.append('INCLUDE "rta_wram.inc"')
    o.append('')
    o.append('SECTION "RTA sound bank %d", ROMX[$4000], BANK[%d]' % (drv.bank, drv.bank))
    o.append('')
    if drv.hram:
        o.append('\tdb %s ; bank number: every bank of this ROM starts with it (the game\'s bank trampoline reads it)' % hx(bk.b(0x4000)))
    else:
        o.append('\tdb %s ; not read by the driver or the game' % hx(bk.b(0x4000)))
    drv.code(o)

    # --- tables
    o.append('')
    o.append('; ' + '=' * 75)
    o.append('; Tables (identical in both games)')
    o.append('')
    o.append('Waves: ; 4 CH3 waves, selected by a patch reg cmd $FE (byte offset)')
    for i in range(4):
        a = t['Waves'] + 16 * i
        o.append('\tdb ' + ', '.join(hx(bk.b(a + j)) for j in range(16)) + ' ; +$%02X' % (16 * i))
    o.append('')
    o.append('Periods: ; 81 GB periods, index 0 = C2 (65.4 Hz on CH1/CH2)')
    for i in range(81):
        a = t['Periods'] + 2 * i
        o.append('\tdw %s ; %2d %s' % (hx(bk.w(a), 4), i, note_name(i + 3)))
    o.append('')
    o.append('RegBase: ; register block of each voice (NRx0)')
    o.append('\tdw ' + ', '.join(HW.get(bk.w(t['RegBase'] + 2 * i), hx(bk.w(t['RegBase'] + 2 * i), 4)) for i in range(4)))
    o.append('VoiceOfs: ; wVoice1 offset of the voice for programs $00-$1F, $20-$3F, $40-$47 (the 4th entry is unused)')
    o.append('\tdb ' + ', '.join(hx(bk.b(t['SlotOfs'] + i)) for i in range(4)))
    for nm, key in (('ProgAttack', 'Attack'), ('ProgRelease', 'Release')):
        o.append('')
        o.append('%s: ; patch started by a %s, per program (%s)' % (
            nm, 'note-on' if nm == 'ProgAttack' else 'release',
            '74 programs' if nm == 'ProgAttack' else '0 = none'))
        for r in range(0, 74, 8):
            n = min(8, 74 - r)
            o.append('\tdb ' + ', '.join('%3d' % bk.b(t[key] + r + i) for i in range(n)) + ' ; programs $%02X-$%02X' % (r, r + n - 1))
    o.append('')
    o.append('Patches: ; 97 x 12 bytes, see the patch macro in rta_sound.inc')
    o.append(';\t      flags ofs  delta  and  or   dur next cnt  reg  r1   r2')
    for i in range(97):
        a = t['Patches'] + 12 * i
        b = [bk.b(a + j) for j in range(12)]
        delta = b[2] | b[3] << 8
        dstr = str(delta - 0x10000) if delta >= 0x8000 else str(delta)
        o.append('\tpatch %s, %s, %5s, %s, %s, %3d, %3d, %3d, %s, %s, %s ; %2d' % (
            hx(b[0]), hx(b[1]), dstr, hx(b[4]), hx(b[5]), b[6], b[7], b[8], hx(b[9]), hx(b[10]), hx(b[11]), i))

    # --- sound table
    ptrs = bk.sound_table(t['Sounds'])
    names = {}
    for i, p in enumerate(ptrs):
        kind = 'Song' if songs_named(i, p) else 'Sfx'
        names.setdefault(p, []).append('%s%02X' % (kind, i))
    o.append('')
    o.append('SoundTable: ; sound id & $3F (bit 7 of the id = music)')
    for i, p in enumerate(ptrs):
        kind = 'Song' if songs_named(i, p) else 'Sfx'
        o.append('\tdw %s%02X' % (kind, i))

    # --- SFX + songs, by address
    uniq = sorted(names)
    data_end = None
    for k, p in enumerate(uniq):
        nxt = uniq[k + 1] if k + 1 < len(uniq) else None
        o.append('')
        for n in names[p]:
            o.append(n + ':')
        if names[p][0].startswith('Song'):
            s = parse_song(bk, p)
            assert nxt is None or s['end'] == nxt, (hex(p), hex(s['end']), hex(nxt))
            o.extend(song_lines(s))
            data_end = s['end']
        else:
            o.extend(sfx_lines(bk, p, nxt, names))
            data_end = nxt
    # leftover
    if data_end < 0x8000:
        e = 0x8000
        while e > data_end and bk.b(e - 1) == 0xFF:
            e -= 1
        if e > data_end:
            o.append('')
            o.append('; $%04X-$%04X: not sound data. Leftover bytes from the build (graphics, maps, text),' % (data_end, e - 1))
            o.append('; never read by the driver; kept for a byte-exact bank.')
            o.append('Leftover:')
            o.extend(db_lines(bk, data_end, e))
        if e < 0x8000:
            o.append('\tds $%04X - @, $FF' % 0x8000)
    return o, ptrs, names


def song_lines(s):
    o = []
    n = s['n']
    o.append('\tsong_header %d' % n)
    for r in range(0, n, 16):
        m = min(16, n - r)
        o.append('\tdb ' + ', '.join('%2d' % c for c in s['chan'][r:r + m]) + ' ; MIDI channel, defs %d-%d' % (r, r + m - 1))
    for r in range(0, n, 16):
        m = min(16, n - r)
        o.append('\tdb ' + ', '.join(note_name(v) for v in s['note'][r:r + m]) + ' ; note, defs %d-%d' % (r, r + m - 1))
    frame = 0
    for a, k, args in s['events']:
        if k == 'note':
            i = args[0]
            o.append('\tnote %2d ; ch%d %s' % (i, s['chan'][i], note_name(s['note'][i])))
        elif k == 'off':
            o.append('\trelease %d' % args[0])
        elif k == 'prog':
            o.append('\tprogram %d, %s' % (args[0], hx(args[1])))
        elif k == 'wait':
            frame += args[0]
            o.append('\twait %d ; -> %d' % (args[0], frame))
        elif k == 'goto':
            o.append('\tsong_goto %s' % hx(args[0]))
        elif k == 'end':
            o.append('\tsong_end')
    return o


def sfx_lines(bk, p, nxt, names):
    o = []
    a = p
    stop = nxt if nxt is not None else 0x8000
    while a < stop:
        f = parse_sfx(bk, a)
        ev = f['events']
        done = False
        for (ea, k, args) in ev:
            ln = {'sq1': 6, 'sq2': 5, 'wav': 1, 'noi': 5, 'jump': 3, 'rand': 3, 'end': 1, 'wait': 1}[k]
            if ea + ln > stop:
                o.append('\tdb ' + ', '.join(hx(bk.b(x)) for x in range(ea, stop)) +
                         ' ; read as sfx_pulse1 %s: runs into the next SFX (see the doc)' % ', '.join(
                             hx(bk.b(x)) for x in range(ea + 1, ea + 6)))
                a = stop
                done = True
                break
            if k == 'sq1':
                o.append('\tsfx_pulse1 %s, %s, %s, %s' % (hx(args[0]), hx(args[1]), hx(args[2]), hx(args[3] | args[4] << 8, 4)))
            elif k == 'sq2':
                o.append('\tsfx_pulse2 %s, %s, %s' % (hx(args[0]), hx(args[1]), hx(args[2] | args[3] << 8, 4)))
            elif k == 'wav':
                o.append('\tsfx_wave')
            elif k == 'noi':
                o.append('\tsfx_noise %s' % ', '.join(hx(x) for x in args))
            elif k == 'jump':
                o.append('\tsfx_jump %s' % names[args[0]][0])
            elif k == 'rand':
                o.append('\tsfx_random %s, %s' % (hx(args[0]), hx(args[1])))
            elif k == 'wait':
                o.append('\tsfx_wait %d' % args[0])
            elif k == 'end':
                o.append('\tsfx_end')
            a = ea + ln
        if done:
            break
        if a < stop:
            o.append('\tdb ' + ', '.join(hx(bk.b(x)) for x in range(a, stop)) + ' ; unreferenced')
            a = stop
    return o


def ram_inc(hram):
    o = []
    pfx = 'h' if hram else 'w'
    ofs = 0x208A if hram else 0
    o.append('; Driver RAM, %s (62 bytes; the game clears it and seeds the random byte with $47)' % (
        'HRAM $FF8A-$FFC7 (Star Wars - Super Return of the Jedi)' if hram else 'WRAM $DF00-$DF3D (Zoop)'))
    o.append('')
    for base, size, name in RAM_VARS:
        o.append('DEF %-14s EQU $%04X ; %d' % (pfx + name[1:], base + ofs, size))
    return o


def main():
    zrom, srom = sys.argv[1], sys.argv[2]
    outdir = sys.argv[3] if len(sys.argv) > 3 else '.'
    zd = open(zrom, 'rb').read()
    sd = open(srom, 'rb').read()
    zoop = Driver(zd, 3, False)
    zoop.build_labels(zoop)
    jobs = [('Zoop (U)', zoop, 'Zoop_SoundDriver.asm')]
    for b in (4, 5):
        dv = Driver(sd, b, True)
        dv.build_labels(zoop)
        jobs.append(('Star Wars - Super Return of the Jedi (U)', dv, 'SROTJ_SoundDriver_Bank%d.asm' % b))

    def songs_named(i, p, _cache={}):
        return None

    for game, dv, fn in jobs:
        bk = dv.bk
        ptrs = bk.sound_table(dv.t['Sounds'])
        # entries whose data parses as a song that ends exactly where the next one starts
        uniq = sorted(set(ptrs))
        is_song = {}
        for k, p in enumerate(uniq):
            nxt = uniq[k + 1] if k + 1 < len(uniq) else None
            s = parse_song(bk, p)
            last = s['events'][-1][1]
            ok = last in ('goto', 'end') and (s['end'] == nxt if nxt else s['end'] <= 0x8000)
            # SFX region comes first; once songs start, all following entries are songs
            is_song[p] = ok and all(is_song.get(q, True) or q < p for q in uniq[:k]) and (
                k + 1 == len(uniq) or ok)
        # the song block is the tail of entries that all parse as songs
        first_song = None
        for k in range(len(uniq) - 1, -1, -1):
            if is_song[uniq[k]]:
                first_song = uniq[k]
            else:
                break
        fn_song = lambda i, p: p >= first_song  # noqa: E731
        lines, _, _ = gen_bank(dv, game, fn_song, 'rta_sound.inc')
        with open(os.path.join(outdir, fn), 'w', newline='\n') as f:
            f.write('\n'.join(lines) + '\n')
    src = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'inc_static.txt')
    with open(src) as f, open(os.path.join(outdir, 'rta_sound.inc'), 'w', newline='\n') as g:
        g.write(f.read())
    for hram in (False, True):
        with open(os.path.join(outdir, 'rta_hram.inc' if hram else 'rta_wram.inc'), 'w', newline='\n') as f:
            f.write('\n'.join(ram_inc(hram)) + '\n')


if __name__ == '__main__':
    main()
