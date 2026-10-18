"""Generate the Kirby's Dream Land 2 sound driver sources.
bank 0   $2B97-$30DF : track start, update, stream interpreter, small tables
bank 0   $3F56-$3FE5 : period table
bank $1E $4000-$5DBC : instruments + envelopes (copy), init, SFX start, register output, waves, SFX data,
                       length sets, SFX tables
bank $1F $4000-$7E6B : instruments + envelopes (copy), PlaySong, song data, song table
usage: python3 gen_kdl2.py <rom> <outdir> [kdl rom]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asmgen import AsmGen
from halsnd import HalMusic, HW, Lazy
from halcommon import write_build_check, MACROS_KDL, HW_INC, low_idiom_hints, write, apply_comments
import gen_kdl, align

P = 'KDL2'
SB, MB = 0x1E, 0x1F

RAM = {a - 0xDE00 + 0xCE00: n for a, n in gen_kdl.RAM.items() if 0xDE00 <= a < 0xDF00}
RAM.update({0xDD64: 'wSoundStacks', 0xDDE4: 'wCurSong', 0xDDE5: 'wWaves', 0xDE15: 'wLengthSets',
            0xFF99: 'hRegImage', 0xFFA4: 'hCurBank', 0xFF96: 'hFarBank'})
ARRAYS = {a - 0xDE00 + 0xCE00 for a in gen_kdl.ARRAYS}
EXT = {0x05E5: 'FarCall_E', 0x05F3: 'SwitchBank', 0x0621: 'CopyBytes', 0x293E: 'Multiply_BxC'}
KDL_ROM = None  # set by find_kdl_rom()


def port_names(gk, g, skip=()):
    amap, _, _, _ = align.amap(gk, g)
    for ka, kn in gk.labels.items():
        if ka in amap and not kn.startswith('.') and gk.items.get(ka) and gk.items[ka].kind == 'code' and kn not in skip:
            la = amap[ka]
            if (la not in g.labels or g.labels[la].startswith('.')) and kn not in g.labels.values():
                g.label(la, kn, override=True)


def lz(g, fmt, *addrs):
    return Lazy(lambda: fmt % tuple(g.sym(a) for a in addrs))


def bank_data(g, rom, prefix, ninst, label_inst):
    """Instrument table + envelopes at $4000 of a sound bank."""
    m = HalMusic(g)
    m.pfx = prefix
    g.label(0x4000, label_inst)
    for i in range(ninst):
        a = 0x4000 + 4 * i
        for t in (g.w(a), g.w(a + 2)):
            if t not in g.labels:
                g.label(t, '%sEnv_%04X' % (prefix, t))
            m.add(t, 'env', None)
    return m


def find_kdl_rom(near=None):
    """Routine names are ported from the KDL driver by aligning the code, so the KDL ROM is needed:
    argv[3], or a "Kirby's Dream Land (UE)*.gb" next to the input ROM."""
    import glob
    if len(sys.argv) > 3:
        return sys.argv[3]
    d = os.path.dirname(os.path.abspath(sys.argv[1]))
    c = [f for f in glob.glob(os.path.join(d, '*.gb')) if os.path.basename(f).startswith("Kirby's Dream Land (")]
    if not c:
        sys.exit('need the Kirby\'s Dream Land ROM (pass it as the 3rd argument)')
    return c[0]


def build(rom):
    gk, _, _ = gen_kdl.build(open(KDL_ROM or find_kdl_rom(), 'rb').read())
    g0 = AsmGen(rom, MB, 0x2B97, 0x30E0)
    gP = AsmGen(rom, MB, 0x3F56, 0x3FE6)
    gE = AsmGen(rom, SB, 0x4000, 0x5DBD)
    gF = AsmGen(rom, MB, 0x4000, 0x7E6C)
    allg = (g0, gP, gE, gF)
    for g in allg:
        g.ram.update(RAM)
        g.ext.update(EXT)
    # ---- code ----
    T0 = {0x2BF0: ('HwOffsetTable', 5), 0x2BF5: ('TrackStackTable', 8), 0x3098: ('Ch3VolumeTable', 4),
          0x30C7: ('EnvStackTable', 8), 0x30CF: ('TuningTable', 2), 0x30D1: ('NoiseTable', 15)}
    for a, (n, s) in T0.items():
        g0.label(a, n)
    for a, n in [(0x2B97, 'Sound_StartTrack'), (0x2BFD, 'Sound_Update')]:
        g0.label(a, n)
        g0.trace(a, n)
    TE = {0x4343: ('DefaultRegImage', 20)}
    for a, (n, s) in TE.items():
        gE.label(a, n)
    for a, n in [(0x4232, 'Sound_Init'), (0x4299, 'Sound_PlaySfx'), (0x4368, 'Sound_UpdateSfxAndOutput')]:
        gE.label(a, n)
        gE.trace(a, n)
    gF.label(0x4281, 'MusicDefaultRegImage')
    gF.label(0x4232, 'Sound_PlaySong')
    gF.trace(0x4232, 'Sound_PlaySong')
    port_names(gk, g0, skip=('Sound_PlaySong', 'Sound_Update', 'Sound_StartTrack'))
    port_names(gk, gE, skip=('Sound_PlaySong', 'Sound_Update', 'Sound_Init') + tuple(g0.labels.values()))
    g0.label(0x2C5A, 'Track_Main', override=True)
    gE.label(0x424A, 'Sound_Reset', override=True)
    gE.label(0x4387, 'Sound_WriteRegs', override=True)
    gE.label(0x4357, 'Sound_UpdateSfxChannels', override=True)
    # cross-section externals
    for a, (n, s) in T0.items():
        if a == 0x30CF:
            g0.item(a, 2, 'dw PeriodTable - 6', 'tuning 0: entry 3 of this table is PeriodTable')
        else:
            g0.bytes_rows(a, s)
    gE.bytes_rows(0x4343, 20)
    gF.bytes_rows(0x4281, 20)
    gP.label(0x3F56, 'PeriodTable')
    for i in range(72):
        a = 0x3F56 + 2 * i
        v = (gP.b(a) << 8) | gP.b(a + 1)
        gP.item(a, 2, 'dwbe $%04X' % v, ('C%d' % (2 + i // 12)) if i % 12 == 0 else None)
    g0.hints.update({
        0x2BD5: 'add a, LOW(HwOffsetTable)', 0x2BD8: 'ld h, HIGH(HwOffsetTable)',
        0x2C85: 'add a, LOW(NoiseTable)', 0x2C88: 'ld h, HIGH(NoiseTable)',
        0x2D05: 'add a, LOW(InstrumentTable)', 0x2D08: 'ld d, HIGH(InstrumentTable) ; the same address in both sound banks',
        0x2D1C: 'ld h, HIGH(EnvStackTable)', 0x2D1E: 'ld a, LOW(EnvStackTable)',
        0x2D4D: 'add a, LOW(wLengthSets)', 0x2D52: 'adc a, HIGH(wLengthSets)',
        0x2EFC: 'add a, LOW(TuningTable)', 0x2F01: 'adc a, HIGH(TuningTable)',
        0x2E98: 'ld a, LOW(wSoundStacks)', 0x2E9C: 'ld a, HIGH(wSoundStacks)', 0x2EA5: 'sub LOW(wSoundStacks)',
        0x2BFD: 'ld a, BANK(SongTable)', 0x2C4D: 'ld a, BANK(SfxTable)',
    })
    gE.hints.update({0x4274: 'ld a, BANK(Sound_PlaySong)', 0x4276: 'ld hl, Sound_PlaySong'})

    # ---- SFX bank data ----
    NINS = (gE.w(0x4000) - 0x4000) // 4
    mE = bank_data(gE, rom, 'S', NINS, 'SfxInstrumentTable')
    gE.label(0x446E, 'InitialWaves')
    gE.label(0x5B6F, 'InitialLengthSets')
    for a, n in [(0x5C35, 'SfxTable'), (0x5CF9, 'SfxChannelMasks'), (0x5D5B, 'SfxPriorities')]:
        gE.label(a, n)
    NSFX = (0x5CF9 - 0x5C35) // 2
    for i in range(NSFX):
        p = gE.w(0x5C35 + 2 * i)
        if p in gE.labels:
            continue
        mE.header(p, 'Sfx%02d' % i, 'Sfx%02d' % i)
    mE.run()
    # ---- music bank data ----
    mF = bank_data(gF, rom, '', NINS, 'InstrumentTable')
    gF.label(0x7E0E, 'SongTable')
    NSONG = (0x7E6C - 0x7E0E) // 2
    for i in range(NSONG):
        p = gF.w(0x7E0E + 2 * i)
        mF.header(p, 'Song%02d' % i if p not in gF.labels else None, 'Song%02d' % i)
    mF.run()
    # cross references
    pub = lambda g: {a: n for a, n in g.labels.items() if not n.startswith('.')}
    g0.ext.update({0x4368: 'Sound_UpdateSfxAndOutput'})
    gE.ext.update({0x2B97: 'Sound_StartTrack', 0x3001: 'LoadWave'})
    gF.ext.update({0x2B97: 'Sound_StartTrack'})
    # items
    for g, m, nm in ((gE, mE, 'Sfx'), (gF, mF, 'Song')):
        for i in range(NINS):
            a = 0x4000 + 4 * i
            g.item(a, 4, lz(g, 'instr %s, %s', g.w(a), g.w(a + 2)),
                   'instrument %d%s' % (i, '' if i in m.instruments_used else ' (not used in this bank)'))
    for i in range(NSFX):
        mE.emit_header_items(gE.w(0x5C35 + 2 * i))
        gE.item(0x5C35 + 2 * i, 2, lz(gE, 'dw %s', gE.w(0x5C35 + 2 * i)), 'sfx %d' % i)
        gE.item(0x5CF9 + i, 1, 'db %%%s' % format(gE.b(0x5CF9 + i), '05b'), 'sfx %d' % i)
        gE.item(0x5D5B + i, 1, 'db %d' % gE.b(0x5D5B + i), 'sfx %d' % i)
    for i in range(NSONG):
        mF.emit_header_items(gF.w(0x7E0E + 2 * i))
        gF.item(0x7E0E + 2 * i, 2, lz(gF, 'dw %s', gF.w(0x7E0E + 2 * i)), 'song %d' % i)
    for i in range(3):
        gE.bytes_rows(0x446E + 16 * i, 16, comment='wave %d' % i)
    for i in range(33):
        a = 0x5B6F + 6 * i
        gE.data(a, 6, 'db ' + ', '.join('%3d' % gE.b(a + k) for k in range(6)), 'length set %d' % i)
    oE = mE.orphans()
    oF = mF.orphans()
    low_idiom_hints(g0, ARRAYS, 0xCE, 'wSoundRAM')
    low_idiom_hints(gE, ARRAYS, 0xCE, 'wSoundRAM')
    low_idiom_hints(gF, ARRAYS, 0xCE, 'wSoundRAM')
    for g in (g0, gE, gF):
        apply_comments(g, EXTRA_COMMENTS)
    info = dict(NSONG=NSONG, NSFX=NSFX, NINS=NINS,
                orphans=['1E:%04X-%04X %s' % (a, b - 1, k) for a, b, k in oE] + ['1F:%04X-%04X %s' % (a, b - 1, k) for a, b, k in oF])
    return (g0, gP, gE, gF), (mE, mF), info


EXTRA_COMMENTS = {
    'Sound_Init': ['; Sound_Init (bank $1E, far-called): copy the 3 waves to wWaves and the 33 length sets to',
                   '; wLengthSets (the bank-0 interpreter reads them from RAM whichever bank is mapped), then reset.'],
    'Sound_Reset': ['; reset as in KDL; stopping the music goes through a far call to Sound_PlaySong ($FF).'],
    'Sound_PlaySong': ['; Sound_PlaySong (bank $1F, far-called): e = song, $FF = stop. A request for the song already',
                       '; playing (wCurSong) is ignored. Resets the music image, starts tracks 7 downward.'],
    'Sound_PlaySfx': ['; Sound_PlaySfx (bank $1E, far-called): e = SFX, $FF = stop all SFX. Priority rules as in KDL.'],
    'Sound_Update': ['; Sound_Update (bank 0, once per frame): map bank $1F and run music tracks 7-4, map bank $1E',
                     '; and run SFX tracks 3-0, then jump to Sound_UpdateSfxAndOutput in bank $1E. Streams,',
                     '; instruments and envelopes are read from whichever bank is mapped; the two banks hold',
                     '; identical instrument tables and envelopes at $4000.'],
    'Sound_UpdateSfxAndOutput': ['; free finished SFX channels, recompute wSfxChannels, write the register images.'],
}


def ram_inc():
    lines = ["; Kirby's Dream Land 2 sound RAM ($CE00-$CED4, $DD64-$DEDA)",
             '; per-track arrays: 8 entries, tracks 0-3 = SFX, 4-7 = music', '', 'DEF wSoundRAM            EQU $CE00']
    for a in sorted(RAM):
        lines.append('DEF %-20s EQU $%04X' % (RAM[a], a))
    lines.append('')
    lines.append('; game routines used by the sound code')
    for a in sorted(EXT):
        lines.append('DEF %-20s EQU $%04X' % (EXT[a], a))
    return '\n'.join(lines) + '\n'


def main():
    rom = open(sys.argv[1], 'rb').read()
    out = sys.argv[2]
    (g0, gP, gE, gF), (mE, mF), info = build(rom)
    for g in (g0, gP, gE, gF):
        if g.errors:
            print('\n'.join(g.errors[:30]))
        print('gaps %04X:' % g.start, ['%04X-%04X' % x for x in g.gaps()])
    write(os.path.join(out, P + '_Bank0.inc'), '; bank 0: track start, update, interpreter, tables ($2B97-$30DF)\n\n' + g0.emit())
    write(os.path.join(out, P + '_Periods.inc'), '; bank 0: period table ($3F56-$3FE5)\n\n' + gP.emit())
    write(os.path.join(out, P + '_SfxBank.inc'), '; bank $1E: instruments, envelopes, init/SFX/output code, waves, SFX, length sets ($4000-$5DBC)\n\n' + gE.emit())
    write(os.path.join(out, P + '_MusicBank.inc'), '; bank $1F: instruments, envelopes, PlaySong, songs ($4000-$7E6B)\n\n' + gF.emit())
    write_build_check(out, P)
    write(os.path.join(out, P + '_Macros.inc'), MACROS_KDL)
    write(os.path.join(out, P + '_RAM.inc'), ram_inc() + '\n' + HW_INC)
    write(os.path.join(out, P + '_Sound.asm'),
          "; Kirby's Dream Land 2 - HAL sound driver\n\nINCLUDE \"%s_RAM.inc\"\nINCLUDE \"%s_Macros.inc\"\n\n" % (P, P) +
          'SECTION "Sound Interpreter", ROM0[$2B97]\nINCLUDE "%s_Bank0.inc"\n\n' % P +
          'SECTION "Sound Periods", ROM0[$3F56]\nINCLUDE "%s_Periods.inc"\n\n' % P +
          'SECTION "Sound Engine and SFX", ROMX[$4000], BANK[$1E]\nINCLUDE "%s_SfxBank.inc"\n\n' % P +
          'SECTION "Sound Music", ROMX[$4000], BANK[$1F]\nINCLUDE "%s_MusicBank.inc"\n' % P)
    json.dump({'readsE': {('%04X' % k): v for k, v in mE.reads.items()}, 'readsF': {('%04X' % k): v for k, v in mF.reads.items()},
               'items0': {('%04X' % a): [it.size, it.kind] for a, it in g0.items.items()},
               'info': info}, open(os.path.join(out, 'model.json'), 'w'))


if __name__ == '__main__':
    main()
