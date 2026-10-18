"""Generate the Adventures of Lolo sound driver sources.
bank 0 $32AE-$3FFF : far-call wrappers, driver code, tables, song/SFX/pattern tables
bank $0F $4000-$7DD4: waves, headers, streams, envelopes, instruments, length sets
usage: python3 gen_lolo.py <rom> <outdir> [kdl rom]"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asmgen import AsmGen
from halsnd import HalMusic, HW, Lazy
from halcommon import write_build_check, MACROS_KDL, HW_INC, low_idiom_hints, write, apply_comments
import gen_kdl, align

P = 'Lolo'
MBANK = 0x0F
A0, A1 = 0x32AE, 0x4000        # bank 0 part
B0, B1 = 0x4000, 0x7DD5        # bank 15 part

RAM = {a - 0xDE00 + 0xC800: n for a, n in gen_kdl.RAM.items() if 0xDE00 <= a < 0xDF00}
RAM.update({0xC8D2: 'wSoundStacks', 0xC952: 'wCurWave', 0xC953: 'wSoundUnused53', 0xC954: 'wSoundUnused54',
            0xC955: 'wPatternGroup', 0xC956: 'wPatternTimer', 0xC957: 'wPatternPeriod', 0xC958: 'wPatternRow',
            0xC959: 'wPatternRows', 0xC95A: 'wPatternVariant', 0xC95B: 'wSfxTranspose',
            0xFF8A: 'hRegImage', 0xC5FC: 'wCurBank', 0xC6EA: 'wSoundBusy'})
ARRAYS = {a - 0xDE00 + 0xC800 for a in gen_kdl.ARRAYS}


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
    gA = AsmGen(rom, MBANK, A0, A1)
    gB = AsmGen(rom, MBANK, B0, B1)
    for g in (gA, gB):
        g.ram.update(RAM)
    T = {
        0x33FF: ('DefaultRegImage', 20), 0x346C: ('HwOffsetTable', 5), 0x3B05: ('Ch3VolumeTable', 4),
        0x3BC4: ('UnusedImageBaseTable', 8), 0x3BCC: ('TrackStackTable', 8), 0x3BD4: ('EnvStackTable', 8),
        0x3BDC: ('TuningTable', 2), 0x3BDE: ('NoiseTable', 15), 0x3BED: ('InitialWave', 16),
    }
    for a, (n, size) in T.items():
        gA.label(a, n)
    entries = [(0x32AE, 'Sound_PlaySfxFar'), (0x32C5, 'Sound_PlaySongFar'), (0x32DC, 'Sound_InitFar'),
               (0x32E9, 'Sound_Init'), (0x334A, 'Sound_PlaySfx'), (0x3471, 'Sound_PlaySong'), (0x34D8, 'Sound_Update')]
    for a, n in entries:
        gA.label(a, n)
    for a, n in entries:
        gA.trace(a, n)
    # port routine names from KDL by aligning the code
    gk, _, _ = gen_kdl.build(open(KDL_ROM or find_kdl_rom(), 'rb').read())
    amap, _, _, _ = align.amap(gk, gA)
    for ka, kn in gk.labels.items():
        if ka in amap and not kn.startswith('.') and gk.items.get(ka) and gk.items[ka].kind == 'code':
            la = amap[ka]
            if (la not in gA.labels or gA.labels[la].startswith('.')) and kn not in gA.labels.values():
                gA.label(la, kn, override=True)
    gA.label(0x355A, 'Sound_UpdateTracks', override=True)
    gA.label(0x3BFD, 'Multiply_BxE', override=True)
    gA.label(0x3B2C, 'Track_RegAddrAbs', override=True)
    gA.label(0x382D, 'Cmd_BaseNote', override=True)
    gA.ext[0x0030] = 'RST_Bankswitch'

    for a, (n, size) in T.items():
        if a == 0x3BDC:
            gA.item(a, 2, 'dw PeriodTable - 6', 'tuning 0: entry 3 of this table is PeriodTable')
        else:
            gA.bytes_rows(a, size)
    gA.label(0x3B34, 'PeriodTable')
    for i in range(72):
        a = 0x3B34 + 2 * i
        v = (gA.b(a) << 8) | gA.b(a + 1)
        gA.item(a, 2, 'dwbe $%04X' % v, (gen_kdl.NOTE_NAMES[0] + str(2 + i // 12)) if i % 12 == 0 else None)
    H = {
        0x3451: 'add a, LOW(HwOffsetTable)', 0x3454: 'ld h, HIGH(HwOffsetTable)',
        0x36D7: 'add a, LOW(NoiseTable)', 0x36DA: 'ld h, HIGH(NoiseTable)',
        0x3757: 'add a, LOW(InstrumentTable)', 0x375A: 'ld d, HIGH(InstrumentTable)',
        0x3770: 'ld a, LOW(EnvStackTable)', 0x376E: 'ld h, HIGH(EnvStackTable)',
        0x379F: 'add a, LOW(LengthSets)', 0x37A4: 'adc a, HIGH(LengthSets)',
        0x3969: 'add a, LOW(TuningTable)', 0x396E: 'adc a, HIGH(TuningTable)',
        0x3A55: 'ld hl, Wave0', 0x3840: 'add a, LOW(wSfxTranspose)', 0x3843: 'ld h, HIGH(wSfxTranspose)',
        0x3905: 'ld a, LOW(wSoundStacks)', 0x3909: 'ld a, HIGH(wSoundStacks)', 0x3912: 'sub LOW(wSoundStacks)',
        0x3542: 'ld a, [TrackStackTable + 4]', 0x3548: 'ld a, [TrackStackTable + 5]',
        0x354E: 'ld a, [TrackStackTable + 6]', 0x3554: 'ld a, [TrackStackTable + 7]',
    }
    gA.hints.update(H)

    # ---- tables in bank 0 ----
    NSONG = (0x3C87 - 0x3C17) // 2
    NSFX = (0x3CBD - 0x3C87) // 2
    for a, n in [(0x3C17, 'SongTable'), (0x3C87, 'SfxTable'), (0x3CBD, 'SfxChannelMasks'), (0x3CD8, 'SfxPriorities'),
                 (0x3CF3, 'SongPatternGroups'), (0x3D2B, 'SongPatternPeriods'), (0x3D63, 'PatternTables')]:
        gA.label(a, n)
    m = HalMusic(gB)
    gB.label(0x7C9D, 'InstrumentTable')
    gB.label(0x7D69, 'LengthSets')
    for i in range(3):
        gB.label(0x4000 + 16 * i, 'Wave%d' % i)
        gB.bytes_rows(0x4000 + 16 * i, 16)
    headers = {}
    for i in range(NSONG):
        p = gA.w(0x3C17 + 2 * i)
        n, tr = m.header(p, 'Song%02d' % i if p not in gB.labels else None, 'Song%02d' % i)
        headers[('song', i)] = (p, tr)
    for i in range(NSFX):
        p = gA.w(0x3C87 + 2 * i)
        if p in gB.labels:
            continue
        n, tr = m.header(p, 'Sfx%02d' % i, 'Sfx%02d' % i)
    NINS = (0x7D69 - 0x7C9D) // 4
    for i in range(NINS):
        a = 0x7C9D + 4 * i
        for t in (gB.w(a), gB.w(a + 2)):
            if t not in gB.labels:
                gB.label(t, 'Env_%04X' % t)
            m.add(t, 'env', None)
    # pattern tables: group g, variant v -> PatternTables[g*5+v] -> 8 rows of 4 track pointers (header order)
    groups = {}
    for i in range(NSONG):
        gr = gA.b(0x3CF3 + i)
        if gr != 0xFF:
            groups.setdefault(gr, []).append(i)
    NPT = (0x3D77 - 0x3D63) // 2
    pat_hw = {}
    for k in range(NPT):
        tp = gA.w(0x3D63 + 2 * k)
        gr, v = divmod(k, 5)
        song = groups[gr][0]
        tr = headers[('song', song)][1]
        gA.label(tp, 'Pattern_G%dV%d' % (gr, v))
        for row in range(8):
            for e in range(4):
                a = tp + row * 8 + e * 2
                ptr = gA.w(a)
                hw = tr[e][1]
                if ptr not in gB.labels:
                    gB.label(ptr, 'Pat_G%dV%dR%d_%s' % (gr, v, row, HW[hw]))
                m.add(ptr, 'main', hw)
    m.run()
    info = dict(NSONG=NSONG, NSFX=NSFX, NINS=NINS, groups={str(k): v for k, v in groups.items()})
    # cross-section symbols
    gA.ext.update({a: n for a, n in gB.labels.items() if not n.startswith('.')})
    gB.ext.update({a: n for a, n in gA.labels.items() if not n.startswith('.')})
    for i in range(NSONG):
        m.emit_header_items(gA.w(0x3C17 + 2 * i))
    for i in range(NSFX):
        m.emit_header_items(gA.w(0x3C87 + 2 * i))
    for i in range(NINS):
        a = 0x7C9D + 4 * i
        gB.item(a, 4, _lz(gB, 'instr %s, %s', gB.w(a), gB.w(a + 2)),
                'instrument %d%s' % (i, '' if i in m.instruments_used else ' (not used by any song or SFX)'))
    for i in range(18):
        gB.data(0x7D69 + 6 * i, 6, 'db ' + ', '.join('%3d' % gB.b(0x7D69 + 6 * i + k) for k in range(6)), 'length set %d' % i)
    for i in range(NSONG):
        gA.item(0x3C17 + 2 * i, 2, _lz(gA, 'dw %s', gA.w(0x3C17 + 2 * i)), 'song %d' % i)
    for i in range(NSFX):
        gA.item(0x3C87 + 2 * i, 2, _lz(gA, 'dw %s', gA.w(0x3C87 + 2 * i)), 'sfx %d' % i)
    for i in range(NSFX):
        gA.item(0x3CBD + i, 1, 'db %%%s' % format(gA.b(0x3CBD + i), '05b'), 'sfx %d' % i)
    for i in range(NSFX):
        gA.item(0x3CD8 + i, 1, 'db %d' % gA.b(0x3CD8 + i), 'sfx %d' % i)
    for i in range(NSONG):
        v = gA.b(0x3CF3 + i)
        gA.item(0x3CF3 + i, 1, 'db %s' % ('NO_PATTERNS' if v == 0xFF else str(v)), 'song %d' % i)
    for i in range(NSONG):
        gA.item(0x3D2B + i, 1, 'db $%02X' % gA.b(0x3D2B + i), 'song %d' % i)
    for k in range(NPT):
        gA.item(0x3D63 + 2 * k, 2, _lz(gA, 'dw %s', gA.w(0x3D63 + 2 * k)), 'group %d, variant %d' % divmod(k, 5))
    for k in range(NPT):
        tp = gA.w(0x3D63 + 2 * k)
        for row in range(8):
            a = tp + row * 8
            gA.item(a, 8, _lz(gA, 'dw %s, %s, %s, %s', *[gA.w(a + 2 * e) for e in range(4)]), 'row %d' % row)
    gA.data(0x3FF7, 9, comment='not referenced by the sound code')
    orph = m.orphans()
    info['orphans'] = ['%04X-%04X %s' % (a, b - 1, k) for a, b, k in orph]
    low_idiom_hints(gA, ARRAYS, 0xC8, 'wSoundRAM')
    apply_comments(gA, EXTRA_COMMENTS)
    return gA, gB, m, info


EXTRA_COMMENTS = {
    'Sound_PlaySfxFar': ['; Far wrappers: switch to the music bank ($0F) with rst $30, call, restore the bank.'],
    'Sound_PlaySong': ['; Sound_PlaySong: a = song ($FF = stop). Also sets up the pattern sequencer: wPatternGroup =',
                       '; SongPatternGroups[song] ($FF = none), wPatternPeriod = SongPatternPeriods[song], 8 rows.',
                       '; Then starts the header\'s tracks from track 7 downward.'],
    'Sound_Update': ['; Sound_Update (timer interrupt): pattern sequencer first. If the song has a pattern group,',
                     '; every wPatternPeriod ticks the row advances (mod 8) and tracks 7..4 are re-pointed to',
                     '; PatternTables[group*5 + wPatternVariant] row entries 0..3, with wait = 1 and their',
                     '; call/loop stacks reset. The game changes wPatternVariant to switch arrangements.'],
    'Cmd_BaseNote': ['; $F5: SFX tracks (0-3) add wSfxTranspose[channel] to the argument (game-set pitch offset).'],
    'Multiply_BxE': ['; b = b*e/256 (shift-and-add), used for the gate release time.'],
}

KDL_ROM = None  # set by find_kdl_rom()


def _lz(g, fmt, *addrs):
    return Lazy(lambda: fmt % tuple(g.sym(a) for a in addrs))


def ram_inc():
    lines = ['; Adventures of Lolo sound RAM ($C800-$C95E)',
             '; per-track arrays: 8 entries, tracks 0-3 = SFX, 4-7 = music', '', 'DEF wSoundRAM            EQU $C800']
    for a in sorted(RAM):
        lines.append('DEF %-20s EQU $%04X' % (RAM[a], a))
    lines.append('DEF NO_PATTERNS EQU $FF')
    return '\n'.join(lines) + '\n'


def main():
    rom = open(sys.argv[1], 'rb').read()
    out = sys.argv[2]
    gA, gB, m, info = build(rom)
    errs = gA.errors + gB.errors
    if errs:
        print('\n'.join(errs[:50]))
    print('gaps A:', ['%04X-%04X' % x for x in gA.gaps()])
    print('gaps B:', ['%04X-%04X' % x for x in gB.gaps()])
    write(os.path.join(out, P + '_Driver.inc'), '; bank 0: far wrappers, driver code and tables ($32AE-$3C16)\n\n' + gA.emit(A0, 0x3C17))
    write(os.path.join(out, P + '_Tables.inc'), '; bank 0: song, SFX and pattern tables ($3C17-$3FFF)\n\n' + gA.emit(0x3C17, A1))
    write(os.path.join(out, P + '_Data.inc'), '; bank $0F: waves, songs, SFX, envelopes, instruments, length sets ($4000-$7DD4)\n\n' + gB.emit(B0, B1))
    write_build_check(out, P)
    write(os.path.join(out, P + '_Macros.inc'), MACROS_KDL)
    write(os.path.join(out, P + '_RAM.inc'), ram_inc() + '\n' + HW_INC)
    write(os.path.join(out, P + '_Sound.asm'),
          '; Adventures of Lolo - HAL sound driver\n\nINCLUDE "%s_RAM.inc"\nINCLUDE "%s_Macros.inc"\n\n' % (P, P) +
          'SECTION "Sound Driver", ROM0[$%04X]\n\nINCLUDE "%s_Driver.inc"\nINCLUDE "%s_Tables.inc"\n\n' % (A0, P, P) +
          'SECTION "Sound Data", ROMX[$%04X], BANK[$%02X]\n\nINCLUDE "%s_Data.inc"\n' % (B0, MBANK, P))
    items = {('%04X' % a): [it.size, it.kind] for a, it in gA.items.items()}
    itemsB = {('%04X' % a): [it.size, it.kind] for a, it in gB.items.items()}
    json.dump({'reads': {('%04X' % k): v for k, v in m.reads.items()}, 'items': items, 'itemsB': itemsB,
               'info': info}, open(os.path.join(out, 'model.json'), 'w'))


if __name__ == '__main__':
    main()
