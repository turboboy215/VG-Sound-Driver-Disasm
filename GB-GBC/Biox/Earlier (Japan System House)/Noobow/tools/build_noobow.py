#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from gen_a import build, emit_freq, emit_waves, emit_vib

NAMES_NOOBOW = {
    0x4000: 'SndEntry_Play', 0x4003: 'SndEntry_TimerUpdate', 0x4006: 'SndEntry_FrameUpdate',
    0x4009: 'SndEntry_Init', 0x400C: 'SndEntry_IsSfxIdle',
    0x400F: 'Snd_IsSfxIdle', 0x401D: 'Snd_Play', 0x408B: 'Snd_PlaySfx', 0x40CC: 'Snd_Unused40CC',
    0x40D5: 'Snd_Init', 0x4117: 'Snd_TimerUpdate', 0x4167: 'Snd_TimerDefer', 0x4172: 'Snd_FrameUpdate',
    0x4181: 'Snd_UpdateSfx2', 0x41C1: 'Snd_UpdateSfx4', 0x41F8: 'Snd_UpdateCh1', 0x4242: 'Snd_UpdateCh2',
    0x42A1: 'Snd_UpdateCh3', 0x42EE: 'Snd_UpdateCh4', 0x433E: 'Snd_ParseTrack', 0x4361: 'Snd_ParseLoop',
    0x43EF: 'Snd_ParseDone', 0x43F9: 'Snd_TrackEnd', 0x43FD: 'Snd_RunCommand', 0x440E: 'SndCommandTable',
    0x444E: 'SndCmd_End', 0x4452: 'SndCmd_EndFF', 0x4456: 'Snd_AddChanOfs', 0x4463: 'Snd_GetReg',
    0x446C: 'SndCmd_Sweep', 0x4476: 'SndCmd_Inst', 0x4485: 'SndCmd_Duty', 0x448F: 'SndCmd_Vibrato',
    0x449E: 'SndCmd_Env', 0x44A8: 'SndCmd_Tempo', 0x44BB: 'SndCmd_UnusedE7', 0x44CA: 'SndCmd_UnusedE8',
    0x44D3: 'SndCmd_Pan', 0x44FF: 'SndPanTable', 0x4503: 'SndCmd_Call', 0x4529: 'SndCmd_Ret',
    0x4543: 'SndCmd_Loop', 0x4565: 'SndCmd_Jump', 0x456B: 'SndCmd_MasterVol', 0x4570: 'SndCmd_Tie',
    0x4571: 'SndCmd_RawNote', 0x4578: 'SndCmd_Slur', 0x457C: 'Snd_NoteEnvelope', 0x45D6: 'Snd_NoteWave',
    0x4608: 'Snd_NoteVibrato', 0x4662: 'Snd_EnvStep', 0x46A5: 'Snd_VibratoStep', 0x472B: 'Snd_NoteFreq',
    0x47C9: 'Snd_FreqOut', 0x4811: 'SndFreqTable', 0x4911: 'SndLengthTable', 0x4921: 'SndEnvTable',
    0x497F: 'SndWaveTable', 0x4A7F: 'SndVibratoTable', 0x4AD7: 'SndMusicTable', 0x6B5B: 'SndSfxTable',
}

def tables(g):
    emit_freq(g, 0x4811, 0x4911)
    g.db(0x4911, 0x4921)
    for a, nm in ((0x4927, 'SndEnv0'), (0x492D, 'SndEnv1'), (0x4956, 'SndEnv2')):
        g.lab(a, nm)
    g.dw(0x4921, 0x4927)
    # envelope sequences: (count, NRx2) pairs ending with count 0
    for s, e in ((0x4927, 0x492D), (0x492D, 0x4956), (0x4956, 0x497F)):
        a = s
        while a < e:
            if g.rb(a) == 0:
                g.line(a, 1, '\tdb $00\t; end'); a += 1; continue
            g.line(a, 2, '\tdb $%02X, $%02X' % (g.rb(a), g.rb(a + 1))); a += 2
    emit_waves(g, 0x497F, 0x4A7F)
    emit_vib(g, 0x4A7F, 0x4AD7)
    g.dw(0x4AD7, 0x4AE7, per=8)
    g.dw(0x6B5B, 0x6B8D, per=8)

CFG = dict(
    rom='noobow.gb', bank=0xF, end=0x6E1D, ver=1, out='out/Noobow_sound.asm', section='Sound Driver A (Noobow)',
    names=NAMES_NOOBOW,
    tables=[0x4811, 0x4911, 0x4921, 0x497F, 0x4A7F, 0x4AD7, 0x6B5B, 0x440E, 0x44FF],
    code=[(0x4000, 0x440E), (0x444E, 0x44FF), (0x4503, 0x4811)],
    code_data=[(0x440E, 0x444E, 'dw'), (0x44FF, 0x4503, 'db')],
    nsongs=8, song_hdr=lambda g, i: g.rw(0x4AD7 + 2 * i),
    nsfx=25, sfx_first=8, sfx_hdr=lambda g, i: g.rw(0x6B5B + 2 * i),
    data=(0x4B27, 0x6E1D), data_tables=[(0x6B5B, 0x6BF1)],
    emit_tables=tables,
    header='''; Noobow (J) - sound driver A, bank $0F $4000-$6E1C
; Biox / Japan System House. Disassembled for GBAudioLab\\Biox.
; Assemble: rgbasm -o noobow.o Noobow_sound.asm ; rgblink -o noobow.gb noobow.o
''',
)

if __name__ == '__main__':
    g, items, unused = build(CFG)
    print('unused streams:', ['%04X' % u for u in unused])
