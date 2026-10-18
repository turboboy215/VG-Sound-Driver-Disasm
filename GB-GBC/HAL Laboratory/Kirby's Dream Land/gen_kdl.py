"""Generate the Kirby's Dream Land sound driver sources (bank 5, $4C4A-$7ABF).
usage: python3 gen_kdl.py <rom> <outdir>"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asmgen import AsmGen
from halsnd import HalMusic, HW
from halcommon import write_build_check, MACROS_KDL, HW_INC, low_idiom_hints, write, apply_comments

BANK, START, END = 5, 0x4C4A, 0x7AC0
P = 'KDL'

RAM = {
    0xDE00: 'wSoundSync',  # = wSoundRAM
    0xDE01: 'wSfxAttenuation', 0xDE02: 'wMusicAttenuation', 0xDE03: 'wSfxChannels', 0xDE04: 'wSfxNewMask',
    0xDE06: 'wHwRegs', 0xDE1A: 'wSfxRegs', 0xDE2E: 'wMusicRegs',
    0xDE42: 'wTrkPan', 0xDE4A: 'wTrkHwOffset', 0xDE52: 'wTrkWait', 0xDE5A: 'wTrkPtrLo', 0xDE62: 'wTrkPtrHi',
    0xDE6A: 'wTrkEnvWait', 0xDE72: 'wTrkEnvPtrLo', 0xDE7A: 'wTrkEnvPtrHi', 0xDE82: 'wTrkRelease',
    0xDE8A: 'wTrkBaseNote', 0xDE92: 'wTrkGate', 0xDE9A: 'wTrkVolume', 0xDEA2: 'wTrkInstrument',
    0xDEAA: 'wTrkLengthSet', 0xDEB2: 'wTrkTuning', 0xDEBA: 'wTrkStack', 0xDEC2: 'wTrkEnvStack',
    0xDECA: 'wSfxMask', 0xDECE: 'wSfxPriority', 0xDED2: 'wCurWave', 0xDED3: 'wSoundUnusedD3', 0xDED4: 'wSoundUnusedD4',
    0xDF00: 'wSoundStacks', 0xDF80: 'wRegImage',
}
ARRAYS = {0xDE42, 0xDE4A, 0xDE52, 0xDE5A, 0xDE62, 0xDE6A, 0xDE72, 0xDE7A, 0xDE82, 0xDE8A, 0xDE92, 0xDE9A,
          0xDEA2, 0xDEAA, 0xDEB2, 0xDEBA, 0xDEC2, 0xDECA, 0xDECE, 0xDE00}


def build(rom):
    g = AsmGen(rom, BANK, START, END)
    g.ram.update(RAM)
    g.ext.update({})

    # ---- driver tables (inside the code area) ----
    T = {
        0x4D53: ('DefaultRegImage', 20), 0x4DC0: ('HwOffsetTable', 5), 0x5398: ('Ch3VolumeTable', 16),
        0x5486: ('UnusedImageBaseTable', 8), 0x548E: ('TrackStackTable', 8), 0x5496: ('EnvStackTable', 8),
        0x549E: ('TuningTable', 2), 0x54A0: ('NoiseTable', 15),
    }
    for a, (n, size) in T.items():
        g.label(a, n)
    # code
    for a, n in [(0x4C4A, 'Sound_Init'), (0x4C9E, 'Sound_PlaySfx'), (0x4DC5, 'Sound_PlaySong'), (0x4E0B, 'Sound_Update')]:
        g.trace(a, n)
    names = {
        0x4D1B: 'Sound_UpdateSfxChannels', 0x4D2C: 'Sound_StopSfx', 0x4D67: 'Sound_StartTrack',
        0x4E76: 'Sound_WriteRegs', 0x4F5D: 'Track_Main', 0x4F67: 'Track_MainNextByte', 0x4F68: 'Track_MainRead',
        0x4FB6: 'Track_Rest', 0x4FCD: 'Track_NoteOn', 0x4FC6: 'Track_NoteDone', 0x4FFB: 'Track_StartEnvelope',
        0x5006: 'Track_LoadEnvelope', 0x5008: 'Track_LoadEnvelopeA', 0x5038: 'Track_ReadLength',
        0x5064: 'Track_Command', 0x5198: 'Track_Flow', 0x51AE: 'Stream_Flow', 0x51F9: 'Track_SetNote',
        0x5215: 'Track_SetPeriod', 0x5235: 'Track_Release', 0x524F: 'Track_Env', 0x5259: 'Track_EnvNextByte',
        0x525A: 'Track_EnvRead', 0x527B: 'Track_EnvWaitFlag', 0x5305: 'LoadWave', 0x533B: 'Track_SetVolume',
        0x5347: 'Track_ApplyVolume', 0x53A8: 'SignExtendNibble', 0x53B6: 'Track_AddPeriod',
        0x53C2: 'Track_RegAddr', 0x53CA: 'Track_RegAddrA', 0x53CB: 'Track_RegAddrAbs', 0x53D3: 'Multiply_AxE',
    }
    for a, n in names.items():
        g.label(a, n, override=True)
    g.ext[0x4D53] = 'DefaultRegImage'

    for a, (n, size) in T.items():
        if a == 0x549E:
            g.item(a, 2, 'dw PeriodTable - 6', 'tuning 0: entry 3 of this table is PeriodTable')
        elif a == 0x54A0:
            g.bytes_rows(a, size)
        else:
            g.bytes_rows(a, size)
    g.label(0x53F6, 'PeriodTable')
    for i in range(72):
        a = 0x53F6 + 2 * i
        v = (g.b(a) << 8) | g.b(a + 1)
        g.item(a, 2, 'dwbe $%04X' % v, NOTE_NAMES[i % 12] + str(2 + i // 12) if i % 12 == 0 else None)
    for i in range(3):
        a = 0x54AF + 16 * i
        g.label(a, 'Wave%d' % i)
        g.bytes_rows(a, 16)

    # hints for split-address table lookups
    H = {
        0x4DA5: 'add a, LOW(HwOffsetTable)', 0x4DA8: 'ld h, HIGH(HwOffsetTable)',
        0x4F88: 'add a, LOW(NoiseTable)', 0x4F8B: 'ld h, HIGH(NoiseTable)',
        0x5009: 'add a, LOW(InstrumentTable)', 0x500C: 'ld d, HIGH(InstrumentTable)',
        0x5022: 'ld a, LOW(EnvStackTable)', 0x5020: 'ld h, HIGH(EnvStackTable)',
        0x5051: 'add a, LOW(LengthSets)', 0x5056: 'adc a, HIGH(LengthSets)',
        0x5200: 'add a, LOW(TuningTable)', 0x5205: 'adc a, HIGH(TuningTable)',
        0x52EC: 'ld hl, Wave0', 0x4C6C: 'ld hl, InitialWave',
    }
    g.hints.update(H)

    # ---- music / sfx data ----
    m = HalMusic(g)
    g.label(0x78D3, 'InstrumentTable')
    g.label(0x79AB, 'LengthSets')
    g.label(0x79F3, 'SongTable')
    g.label(0x7A19, 'SfxTable')
    g.label(0x7A61, 'SfxChannelMasks')
    g.label(0x7A85, 'SfxPriorities')
    g.label(0x7AA9, 'InitialWave')
    NSONG = (0x7A19 - 0x79F3) // 2
    NSFX = (0x7A61 - 0x7A19) // 2
    NINS = (0x79AB - 0x78D3) // 4
    for i in range(NSONG):
        p = g.w(0x79F3 + 2 * i)
        m.header(p, 'Song%02d' % i if p not in g.labels else None, 'Song%02d' % i)
    for i in range(NSFX):
        p = g.w(0x7A19 + 2 * i)
        if p in g.labels:
            continue
        m.header(p, 'Sfx%02d' % i, 'Sfx%02d' % i)
    for i in range(NINS):
        a = 0x78D3 + 4 * i
        att, rel = g.w(a), g.w(a + 2)
        for t, k in ((att, 'Attack'), (rel, 'Release')):
            if t not in g.labels:
                g.label(t, 'Env_%04X' % t)
            m.add(t, 'env', None)
    m.run()
    for i in range(NSONG):
        m.emit_header_items(g.w(0x79F3 + 2 * i))
    for i in range(NSFX):
        m.emit_header_items(g.w(0x7A19 + 2 * i))
    for i in range(NINS):
        a = 0x78D3 + 4 * i
        g.item(a, 4, _lz(g, 'instr %s, %s', g.w(a), g.w(a + 2)), 'instrument %d' % i)
    for i in range(12):
        g.data(0x79AB + 6 * i, 6, 'db ' + ', '.join('%3d' % g.b(0x79AB + 6 * i + k) for k in range(6)), 'length set %d' % i)
    for i in range(NSONG):
        g.item(0x79F3 + 2 * i, 2, _lz(g, 'dw %s', g.w(0x79F3 + 2 * i)), 'song %d' % i)
    for i in range(NSFX):
        g.item(0x7A19 + 2 * i, 2, _lz(g, 'dw %s', g.w(0x7A19 + 2 * i)), 'sfx %d' % i)
    for i in range(NSFX):
        g.item(0x7A61 + i, 1, 'db %%%s' % format(g.b(0x7A61 + i), '04b'), 'sfx %d' % i)
    for i in range(NSFX):
        g.item(0x7A85 + i, 1, 'db %d' % g.b(0x7A85 + i), 'sfx %d' % i)
    g.bytes_rows(0x7AA9, 16)
    low_idiom_hints(g, ARRAYS, 0xDE, 'wSoundRAM')
    g.item(0x6B6D, 2, 'db $F0, $DE', 'unreachable (after snd_ret)')
    g.item(0x6DB3, 1, 'snd_end', 'unreachable (after snd_jump)')
    g.data(0x7AB9, 7, comment='padding')
    for i in range(NINS):
        a = 0x78D3 + 4 * i
        if i not in m.instruments_used:
            g.items[a].comment += ' (not used by any song or SFX)'
    apply_comments(g)
    return g, m, dict(NSONG=NSONG, NSFX=NSFX, NINS=NINS)


NOTE_NAMES = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B']


def _lz(g, fmt, *addrs):
    from halsnd import Lazy
    return Lazy(lambda: fmt % tuple(g.sym(a) for a in addrs))


def ram_inc():
    lines = ['; Kirby\'s Dream Land sound RAM ($DE00-$DF80)', '; per-track arrays: 8 entries, tracks 0-3 = SFX, 4-7 = music', '', 'DEF wSoundRAM            EQU $DE00']
    seen = set()
    for a in sorted(RAM):
        n = RAM[a]
        lines.append('DEF %-20s EQU $%04X' % (n, a))
    return '\n'.join(lines) + '\n'


def main():
    rom = open(sys.argv[1], 'rb').read()
    out = sys.argv[2]
    g, m, info = build(rom)
    if g.errors:
        print('\n'.join(g.errors[:50]))
    gaps = g.gaps()
    print('gaps:', [('%04X-%04X' % gp) for gp in gaps])
    code_end = 0x54DF
    hdr = '; Kirby\'s Dream Land - HAL sound driver, bank 5 ($%04X-$%04X)\n\n' % (START, END - 1)
    write(os.path.join(out, P + '_Driver.inc'), '; driver code and tables ($4C4A-$54DE)\n\n' + g.emit(START, code_end))
    write(os.path.join(out, P + '_Data.inc'), '; songs, SFX, envelopes, instrument/length/song/SFX tables ($54DF-$7ABF)\n\n' + g.emit(code_end, END))
    write_build_check(out, P)
    write(os.path.join(out, P + '_Macros.inc'), MACROS_KDL)
    write(os.path.join(out, P + '_RAM.inc'), ram_inc() + '\n' + HW_INC)
    write(os.path.join(out, P + '_Sound.asm'),
          hdr + 'INCLUDE "%s_RAM.inc"\nINCLUDE "%s_Macros.inc"\n\n' % (P, P) +
          'SECTION "Sound Driver", ROMX[$%04X], BANK[%d]\n\n' % (START, BANK) +
          'INCLUDE "%s_Driver.inc"\nINCLUDE "%s_Data.inc"\n' % (P, P))
    json.dump({'reads': {('%04X' % k): v for k, v in m.reads.items()},
               'items': {('%04X' % a): [it.size, it.kind] for a, it in g.items.items()},
               'info': info}, open(os.path.join(out, 'model.json'), 'w'))


if __name__ == '__main__':
    main()
