#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from asmgen import Gen
from engB import walk, walk_penv
from gen_b import ram_symbols, emit_track_items, emit_penv, emit_header
from trace import trace, ranges

ROM = open('bbp.gbc', 'rb').read()
VER = 1
BANK = 2
NAMES = {
    0x4000: 'SndEntry_Update', 0x4003: 'SndEntry_Init', 0x4006: 'SndEntry_Request', 0x4009: 'Snd_Init',
    0x4040: 'Snd_ResetRegs', 0x4050: 'Snd_On', 0x405D: 'Snd_Off', 0x4068: 'Snd_Request', 0x4088: 'Snd_RequestFull',
    0x408A: 'Snd_Update', 0x40AA: 'Snd_CheckSetActive', 0x40BC: 'Snd_UpdateSfx', 0x40E4: 'Snd_UpdateSfxChan',
    0x40F0: 'Snd_UpdateMusic', 0x413C: 'Snd_UpdateMusicChan', 0x415C: 'Snd_LoadChan', 0x417A: 'SndNRx1Table',
    0x417E: 'Snd_SaveChan', 0x4190: 'SndChanPtrTable', 0x41A0: 'Snd_Tick', 0x41A3: 'Snd_TickCount',
    0x41AE: 'Snd_ParseRow', 0x41B4: 'Snd_ParseLoop', 0x41D5: 'SndCmd_Off', 0x41DB: 'Snd_SilenceChan',
    0x41E8: 'Snd_SilenceCh4', 0x41F1: 'Snd_SilenceCh3', 0x41F9: 'Snd_SilenceCh2', 0x4202: 'Snd_SilenceCh1',
    0x420B: 'SndCmd_Rest', 0x420F: 'SndCmd_Noise', 0x4229: 'Snd_Drum', 0x4240: 'Snd_Note', 0x424A: 'Snd_NoteOut',
    0x428F: 'Snd_RowDone', 0x4293: 'Snd_SavePtr', 0x429A: 'Snd_SetLength', 0x429F: 'Snd_Command',
    0x42A2: 'SndCommandTable', 0x42BC: 'SndCmd_End', 0x42C2: 'SndCmd_Jump', 0x42CB: 'SndCmd_Call',
    0x42DC: 'SndCmd_Ret', 0x42E5: 'SndCmd_Loop', 0x42F2: 'SndCmd_EndLoop', 0x4301: 'SndCmd_Tempo',
    0x4313: 'SndCmd_Env', 0x431A: 'SndCmd_PitchEnv', 0x432A: 'SndCmd_Nop', 0x432D: 'SndCmd_Duty',
    0x4342: 'SndCmd_Pan', 0x4349: 'SndCmd_Transpose', 0x4350: 'Snd_PitchEnvStep', 0x43A3: 'Snd_Fade',
    0x43E0: 'Snd_ProcessQueue', 0x4406: 'Snd_HandleRequest', 0x442E: 'Snd_StartSfx', 0x4464: 'Snd_ClearSfx',
    0x4472: 'Snd_SilenceSfxChans', 0x4493: 'Snd_JumpIfActive', 0x4497: 'Snd_StartMusic', 0x44E1: 'Snd_SetMusicFlags',
    0x44EE: 'Snd_SetPointers', 0x4508: 'Snd_SetActive', 0x4518: 'Snd_SysCommand', 0x451B: 'SndSysCmdTable',
    0x452B: 'SndSys_StopAll', 0x453A: 'SndSys_StopMusic', 0x4544: 'Snd_Unused4544', 0x4545: 'SndSys_StopSfx',
    0x454F: 'SndSys_FadeIn', 0x455F: 'SndSys_FadeOut', 0x4563: 'SndSys_VolLow', 0x4568: 'SndSys_VolFull',
    0x456D: 'SndSys_SilenceAll', 0x4579: 'Snd_CalcTempo', 0x4586: 'Snd_Div16x8', 0x45A2: 'SndFreqTable',
    0x4664: 'SndDrumFreqTable', 0x466A: 'SndDrumEnvTable', 0x4670: 'SndMusicWaveTable', 0x480C: 'SndMusicTable',
    0x4832: 'SndSfxPriority', 0x487A: 'SndSfxTable', 0x48E2: 'SndNullTrack',
}
NSONGS = 19
NSFX = 52

def main():
    ram, equ = ram_symbols(VER)
    g = Gen(ROM, BANK, 0x4000, 0x8000)
    g.ram = ram
    for a, n in NAMES.items(): g.lab(a, n)
    g.ptr_ok.update(NAMES.keys())
    insn, tabs = trace(ROM, BANK, [0x4000, 0x4003, 0x4006], {0x42A1: 13, 0x451A: 8})
    code = ranges(insn) + [(0x4544, 0x4545)]
    for s, e in code: g.code_pass1(s, e)
    for s, e in code: g.code(s, e)
    for t, n in tabs.items(): g.dw(t, t + 2 * n, per=4)
    g.db(0x417A, 0x417E); g.dw(0x4190, 0x41A0, per=4)
    a = 0x45A2
    while a < 0x4664:
        n = min(12, (0x4664 - a) // 2)
        g.line(a, 2 * n, '\tdw ' + ', '.join('$%04X' % g.rw(a + 2 * i) for i in range(n))); a += 2 * n
    g.db(0x4664, 0x466A); g.db(0x466A, 0x4670)
    for i in range(13): g.lab(0x4696 + 16 * i, 'SndWave%02X' % i)
    g.dw(0x4670, 0x4696, per=4)
    for i in range(13):
        a = 0x4696 + 16 * i
        g.line(a, 16, '\tdb ' + ', '.join('$%02X' % g.rb(a + k) for k in range(16)))
    for i in range(0, 72, 16):
        n = min(16, 72 - i)
        g.line(0x4832 + i, n, '\tdb ' + ', '.join('$%02X' % g.rb(0x4832 + i + k) for k in range(n)) + '\t; SFX $%02X-$%02X' % (0x80 + i, 0x80 + i + n - 1))
    # walk
    items = {}; labels = {}; tnames = {}; hdrs = []; allpenv = set()
    def addwalk(st):
        it, lb, pe, wv = walk(g.rb, st, VER)
        for k, v in it.items(): items.setdefault(k, v)
        for t, v in lb.items(): labels.setdefault(t, set()).update(v)
        allpenv.update(pe)
        assert not wv
    for kind, base, n, first in (('Mus', 0x480C, NSONGS, 0), ('Sfx', 0x487A, NSFX, 0x80)):
        for i in range(n):
            h = g.rw(base + 2 * i)
            nm = '%s%02X' % (kind, first + i)
            if h not in g.labels: g.lab(h, nm)
            hdrs.append(h)
            m = g.rb(h); k = 0; st = []
            for c in range(4):
                if m >> c & 1:
                    p = g.rw(h + 1 + 2 * k); k += 1
                    tnames.setdefault(p, '%s_Ch%d' % (nm, c + 1)); st.append((p, c))
            addwalk(st)
    for p, nm in tnames.items():
        if p not in g.labels: g.lab(p, nm)
    for t in labels:
        if t not in g.labels: g.lab(t, 'Trk_%04X' % t)
    # pitch envs
    pitems, plabels = walk_penv(g.rb, [p for p, k in allpenv if p])
    for p, k in allpenv:
        if p: g.lab(p, 'SndPitchEnv_%04X' % p)
    for t in plabels:
        if t not in g.labels: g.lab(t, 'SndEnv_%04X' % t)
    pc = set()
    for a, v in pitems.items():
        for x in range(v[0]): pc.add(a + x)
    a = 0x4766
    while a < 0x480C:
        if a in pc: a += 1; continue
        it, lb = walk_penv(g.rb, [a])
        g.lab(a, 'SndEnvUnused_%04X' % a)
        for k2, v in it.items():
            pitems.setdefault(k2, v)
            for x in range(v[0]): pc.add(k2 + x)
        for t in lb:
            if t not in g.labels: g.lab(t, 'SndEnv_%04X' % t)
        a += 1
    # coverage / unused streams
    cov = set()
    def recov():
        cov.clear()
        for a, v in items.items():
            for x in range(v[0]): cov.add(a + x)
        for h in hdrs:
            for x in range(1 + 2 * bin(g.rb(h) & 15).count('1')): cov.add(h + x)
    recov()
    end = max(cov) + 1
    unused = []
    a = 0x48E3
    while a < end:
        if a in cov: a += 1; continue
        unused.append(a)
        addwalk([(a, -1)])
        g.lab(a, 'SndUnused_%04X' % a)
        for t in labels:
            if t not in g.labels: g.lab(t, 'Trk_%04X' % t)
        recov(); a += 1
    end = max(cov) + 1
    g.end = end
    g.dw(0x480C, 0x4832, per=4)
    g.dw(0x487A, 0x48E2, per=8)
    for h in hdrs:
        if h not in g.items: emit_header(g, h)
    emit_track_items(g, items)
    emit_penv(g, pitems)
    src = g.render('Sound Driver B (Burger Burger Pocket)',
        '; Burger Burger Pocket (J) - sound driver B v1, bank $02 $4000-$%04X\n'
        '; Biox. Disassembled for GBAudioLab\\Biox.\n'
        '; Bank-0 helpers used: rst $18 = a = [hl+a] (and a), rst $20 = hl = [hl+2a], rst $00 = inline jump table\n\n'
        'DEF BIOXB_VER EQU 1\nINCLUDE "hardware.inc"\nINCLUDE "bioxB_sound.inc"\n\n; ---- RAM ----\n' % (end - 1) + equ + '\n')
    open('out/BurgerBurgerPocket_sound.asm', 'w').write(src)
    print('end %04X unused' % end, ['%04X' % u for u in unused])
    return end

if __name__ == '__main__':
    main()
