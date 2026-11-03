#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from gen_a import build, emit_freq, emit_waves
from align import amap
from build_noobow import NAMES_NOOBOW

n = open('noobow.gb', 'rb').read(); b = open('bowl.gbc', 'rb').read()
M = amap(n, 0xF, 0x4000, 0x4811, b, 0x1F, 0x4000, 0x4828)
NAMES = {}
for a, nm in NAMES_NOOBOW.items():
    if a in M: NAMES[M[a]] = nm
NAMES.update({0x440C: 'SndCommandTable', 0x4501: 'SndCmd_Call', 0x457D: 'SndCmd_Length',
              0x4828: 'SndFreqTable', 0x48EE: 'SndLengthTable', 0x48FE: 'SndWaveTable',
              0x491E: 'SndSfxTable', 0x513A: 'SndMusicTable'})

def tables(g):
    emit_freq(g, 0x4828, 0x48EE)
    g.db(0x48EE, 0x48FE)
    emit_waves(g, 0x48FE, 0x491E)
    g.line(0x51D4, 4, '\tdw %s, %s\t; orphan header bytes (unreferenced)' % (g.ref(0x4AA7), g.ref(0x4AA7)))
    # empty envelope / vibrato tables: the labels resolved to SndMusicTable
    g.note(0x513A, 'SndEnvTable::\t; (empty - Pocket Bowling has no envelope sequences)')
    g.note(0x513A, 'SndVibratoTable::\t; (empty - Pocket Bowling has no vibrato table)')

CFG = dict(
    rom='bowl.gbc', bank=0x1F, end=0x79DD, ver=2, out='out/PocketBowling_sound.asm',
    section='Sound Driver A (Pocket Bowling)', names=NAMES, direct=True,
    tables=[0x4828, 0x48EE, 0x48FE, 0x491E, 0x513A, 0x440C, 0x44FD],
    code=[(0x4000, 0x440C), (0x444C, 0x44FD), (0x4501, 0x4828)],
    code_data=[(0x440C, 0x444C, 'dw'), (0x44FD, 0x4501, 'db')],
    nsongs=14, song_hdr=lambda g, i: 0x513A + 8 * i,
    nsfx=96, sfx_first=0x0E, sfx_hdr=lambda g, i: 0x491E + 4 * i,
    data=(0x4A9E, 0x79DD), data_tables=[(0x513A, 0x51AA), (0x51D4, 0x51D8)],
    emit_tables=tables,
    header='''; Pocket Bowling (U) - sound driver A, bank $1F $4000-$79DC
; Biox / Japan System House. Disassembled for GBAudioLab\\Biox.
''',
)

if __name__ == '__main__':
    g, items, unused = build(CFG)
    print('unused streams:', ['%04X' % u for u in unused])
    src = open(CFG['out']).read()
    parts = src.split('ld hl,SndMusicTable')
    assert len(parts) == 3, len(parts)
    src = parts[0] + 'ld hl,SndEnvTable' + parts[1] + 'ld hl,SndVibratoTable' + parts[2]
    open(CFG['out'], 'w').write(src)
