#!/usr/bin/env python3
import sys, os
sys.path.insert(0, os.path.dirname(__file__))
from asmgen import Gen
from engB import walk, walk_penv
from gen_b import ram_symbols, emit_track_items, emit_penv, emit_header, notename
from trace import trace, ranges

ROM = open('daiku.gbc', 'rb').read()
VER = 2
NAMES = {
    0x4000: 'SndEntry_Update', 0x4003: 'SndEntry_Init', 0x4006: 'SndEntry_Request',
    0x4009: 'Snd_Init', 0x4044: 'Snd_ResetRegs', 0x4058: 'Snd_On', 0x4065: 'Snd_Off', 0x4070: 'Snd_Request',
    0x4090: 'Snd_RequestFull', 0x4092: 'Snd_Update', 0x40B2: 'Snd_CheckSetActive', 0x40C4: 'Snd_UpdateSfx',
    0x40E6: 'Snd_UpdateSfxChan', 0x40F2: 'Snd_UpdateMusic', 0x4138: 'Snd_UpdateMusicChan', 0x4158: 'Snd_LoadChan',
    0x4176: 'SndNRx1Table', 0x417A: 'Snd_SaveChan', 0x418C: 'SndChanPtrTable', 0x419C: 'Snd_Tick',
    0x41EF: 'Snd_OctEnvStep', 0x424E: 'Snd_TickCount', 0x4259: 'Snd_ParseRow', 0x425F: 'Snd_ParseLoop',
    0x4280: 'SndCmd_Off', 0x4286: 'Snd_SilenceChan', 0x4298: 'Snd_SilenceCh4', 0x42A1: 'Snd_SilenceCh3',
    0x42A9: 'Snd_SilenceCh2', 0x42B2: 'Snd_SilenceCh1', 0x42BB: 'SndCmd_Rest', 0x42BF: 'SndCmd_Noise',
    0x42D9: 'Snd_Drum', 0x42F0: 'Snd_Note', 0x42FA: 'Snd_NoteOut', 0x4345: 'Snd_RowDone', 0x4351: 'Snd_SavePtr',
    0x4358: 'Snd_SetLength', 0x435D: 'Snd_Command', 0x4360: 'SndCommandTable', 0x4388: 'SndCmd_End',
    0x438E: 'SndCmd_Jump', 0x4397: 'SndCmd_Call', 0x43A8: 'SndCmd_Ret', 0x43B1: 'SndCmd_Loop',
    0x43BE: 'SndCmd_EndLoop', 0x43CD: 'SndCmd_Tempo', 0x43DF: 'SndCmd_Env', 0x43E6: 'SndCmd_PitchEnv',
    0x4403: 'SndCmd_Nop', 0x4406: 'SndCmd_Duty', 0x441B: 'SndCmd_Pan', 0x4422: 'SndCmd_Transpose',
    0x4429: 'SndCmd_Vol', 0x4436: 'SndCmd_EnvLo', 0x4443: 'SndCmd_OctEnv', 0x4460: 'SndCmd_Wave',
    0x448E: 'SndCmd_WaveRestore', 0x44B2: 'SndCmd_Env2', 0x44B9: 'SndCmd_Ch3Len', 0x44CB: 'Snd_Fade',
    0x4508: 'Snd_ProcessQueue', 0x452E: 'Snd_HandleRequest', 0x4551: 'Snd_StartSfx', 0x4587: 'Snd_ClearSfx',
    0x4595: 'Snd_SilenceSfxChans', 0x45B6: 'Snd_JumpIfActive', 0x45BA: 'SndMusicBankTable',
    0x45F2: 'Snd_StartMusic', 0x4656: 'Snd_ClearMusic', 0x4664: 'Snd_SetPointers', 0x467E: 'Snd_SetActive',
    0x468E: 'Snd_SysCommand', 0x4691: 'SndSysCmdTable', 0x46A1: 'SndSys_StopAll', 0x46B0: 'SndSys_StopMusic',
    0x46B9: 'SndSys_StopSfx', 0x46C4: 'SndSys_FadeIn', 0x46D4: 'SndSys_FadeOut', 0x46D8: 'SndSys_VolLow',
    0x46DD: 'SndSys_VolFull', 0x46E2: 'SndSys_SilenceAll', 0x46EE: 'Snd_CalcTempo', 0x46F7: 'Snd_Div16x8',
    0x4713: 'SndFreqTable', 0x47D5: 'SndDrumEnvTable', 0x47E5: 'SndDrumFreqTable', 0x47F5: 'SndMusicWaveTable',
    0x4B0D: 'SndNullTrack', 0x4B0E: 'SndSfxPriority', 0x4B4E: 'SndSfxTable', 0x5311: 'SndMusicTable',
}
SONGS = {0x3C: 12, 0x3D: 14, 0x3E: 2}
BANKEND = {}
NSFX = 64

def mk(bank, s, e):
    g = Gen(ROM, bank, s, e)
    g.ram, _ = ram_symbols(VER)
    return g

def main():
    ram, equ = ram_symbols(VER)
    common = mk(0x3C, 0x4000, 0x5311)
    for a, n in NAMES.items(): common.lab(a, n)
    common.ptr_ok.update(NAMES.keys())
    insn, tabs = trace(ROM, 0x3C, [0x4000, 0x4003, 0x4006], {0x435F: 20, 0x4690: 8})
    code = ranges(insn)
    for s, e in code: common.code_pass1(s, e)
    for s, e in code: common.code(s, e)
    for t, n in tabs.items(): common.dw(t, t + 2 * n, per=4)
    common.db(0x4176, 0x417A)
    common.dw(0x418C, 0x419C, per=4)
    for i in range(28):
        a = 0x45BA + 2 * i
        common.line(a, 2, '\tdb $%02X, $%02X\t; music $%02X: bank, index' % (common.rb(a), common.rb(a + 1), i))
    # freq / drums
    a = 0x4713
    while a < 0x47D5:
        n = min(12, (0x47D5 - a) // 2)
        common.line(a, 2 * n, '\tdw ' + ', '.join('$%04X' % common.rw(a + 2 * i) for i in range(n)))
        a += 2 * n
    common.db(0x47D5, 0x47E5); common.db(0x47E5, 0x47F5)
    # waves
    for i in range(19):
        common.lab(0x481B + 16 * i, 'SndWave%02X' % i)
    common.dw(0x47F5, 0x481B, per=4)
    for i in range(19):
        a = 0x481B + 16 * i
        common.line(a, 16, '\tdb ' + ', '.join('$%02X' % common.rb(a + k) for k in range(16)))
    common.line(0x4B0D, 1, '\tsnd_end')
    for i in range(0, 64, 16):
        common.line(0x4B0E + i, 16, '\tdb ' + ', '.join('$%02X' % common.rb(0x4B0E + i + k) for k in range(16)) + '\t; SFX $%02X-$%02X' % (0x40 + i, 0x4F + i))
    # ---- SFX
    allpenv = set(); waves = set()
    sitems = {}; slabels = {}; names = {}
    hdrs = []
    for i in range(NSFX):
        h = common.rw(0x4B4E + 2 * i)
        common.lab(h, 'Sfx%02X' % (0x40 + i))
        m = common.rb(h)
        k = 0; st = []
        for c in range(4):
            if m >> c & 1:
                p = common.rw(h + 1 + 2 * k); k += 1
                names.setdefault(p, 'Sfx%02X_Ch%d' % (0x40 + i, c + 1)); st.append((p, c))
        hdrs.append(h)
        it, lb, pe, wv = walk(common.rb, st, VER, hi=0x5311)
        sitems.update(it); allpenv |= pe; waves |= wv
        for t, v in lb.items(): slabels.setdefault(t, set()).update(v)
    # ---- songs per bank
    banks = {}
    for bk, n in SONGS.items():
        g = mk(bk, 0x5311, 0x8000)
        g.labels.update(common.labels)
        items = {}; labels = {}; tnames = {}; bh = []
        for i in range(n):
            h = g.rw(0x5311 + 2 * i)
            m = g.rb(h); k = 0; st = []
            bh.append(h)
            for c in range(4):
                if m >> c & 1:
                    p = g.rw(h + 1 + 2 * k); k += 1
                    tnames.setdefault(p, 'Mus%02X_%d_Ch%d' % (bk, i, c + 1)); st.append((p, c))
            it, lb, pe, wv = walk(g.rb, st, VER)
            items.update(it); allpenv |= pe; waves |= wv
            for t, v in lb.items(): labels.setdefault(t, set()).update(v)
        banks[bk] = (g, items, labels, tnames, bh)
    # ---- pitch envelopes (all in the common area?)
    pstarts = [p for p, k in allpenv]
    assert all(p < 0x5311 for p in pstarts), [hex(p) for p in pstarts if p >= 0x5311]
    pitems, plabels = walk_penv(common.rb, pstarts)
    for p, k in sorted(allpenv):
        common.lab(p, ('SndPitchEnv_%04X' if k == 'penv' else 'SndOctEnv_%04X') % p)
    for t in plabels:
        if t not in common.labels: common.lab(t, 'SndEnv_%04X' % t)
    for w in waves:
        assert w in common.labels, hex(w)
    # labels in common from SFX and songs
    for p, nm in names.items(): common.lab(p, nm)
    for t in slabels:
        if t not in common.labels: common.lab(t, 'SndTrk_%04X' % t)
    for bk, (g, items, labels, tnames, bh) in banks.items():
        for t in labels:
            if t < 0x5311 and t not in common.labels: common.lab(t, 'SndTrk_%04X' % t)
        for p, nm in tnames.items():
            if p < 0x5311 and p not in common.labels: common.lab(p, nm)
    # unreferenced in common data area $4BCE-$5311
    cov = set()
    def covd(it):
        for a, v in it.items():
            for x in range(v[0]): cov.add(a + x)
    covd(sitems)
    for h in hdrs:
        m = common.rb(h); n = bin(m & 15).count('1')
        for x in range(1 + 2 * n): cov.add(h + x)
    unused = []
    a = 0x4BCE
    while a < 0x5311:
        if a in cov: a += 1; continue
        unused.append(a)
        it, lb, pe, wv = walk(common.rb, [(a, -1)], VER, hi=0x5311)
        for k2, v in it.items():
            if k2 not in sitems: sitems[k2] = v
        for t in lb:
            if t not in common.labels: common.lab(t, 'SndTrk_%04X' % t)
        common.lab(a, 'SndUnused_%04X' % a)
        covd(it); a += 1
    # unreferenced pitch-env bytes inside $494B-$4B0D
    pc = set()
    for a, v in pitems.items():
        for x in range(v[0]): pc.add(a + x)
    a = 0x494B
    while a < 0x4B0D:
        if a in pc: a += 1; continue
        it, lb = walk_penv(common.rb, [a])
        common.lab(a, 'SndEnvUnused_%04X' % a)
        for k2, v in it.items():
            pitems.setdefault(k2, v)
            for x in range(v[0]): pc.add(k2 + x)
        for t in lb:
            if t not in common.labels: common.lab(t, 'SndEnv_%04X' % t)
        a += 1
    # emit SFX table, headers, tracks, envs
    common.dw(0x4B4E, 0x4BCE, per=8)
    for h in hdrs: emit_header(common, h)
    for t in slabels: pass
    emit_track_items(common, sitems)
    emit_penv(common, pitems)
    src = common.render('x')
    body = src.split('\n', 3)[3]   # drop header + SECTION line
    open('out/Daiku_sound_common.inc', 'w').write(
        '; Daiku no Gensan - Kachikachi no Tonkachi ga Kachi (J): sound driver B v2\n'
        '; Common part, byte-identical in banks $3C, $3D and $3E ($4000-$5310):\n'
        '; driver code, tables, waves, envelopes and all sound effects.\n'
        '; (bank-0 helpers used: rst $10 = a = [hl+a], rst $20 = hl = [hl+2a], rst $28 = inline jump table)\n'
        '; INCLUDEd at the top of each Daiku_sound_bankXX.asm (labels stay file-local).\n\n' + body)
    # per bank files
    for bk, (g, items, labels, tnames, bh) in banks.items():
        g.labels = dict(common.labels)
        for p, nm in tnames.items():
            if p >= 0x5311: g.lab(p, nm)
        for t in labels:
            if t >= 0x5311 and t not in g.labels: g.lab(t, 'Trk%02X_%04X' % (bk, t))
        for i, h in enumerate(bh): g.lab(h, 'Mus%02X_%d' % (bk, i))
        end = max(a + v[0] for a, v in items.items() if a >= 0x5311)
        # unreferenced streams
        cov = set()
        for a, v in items.items():
            for x in range(v[0]): cov.add(a + x)
        for h in bh:
            n = bin(g.rb(h) & 15).count('1')
            for x in range(1 + 2 * n): cov.add(h + x)
        for x in range(0x5311, 0x5311 + 2 * SONGS[bk]): cov.add(x)
        a = 0x5311
        while a < end:
            if a in cov: a += 1; continue
            it, lb, pe, wv = walk(g.rb, [(a, -1)], VER)
            g.lab(a, 'Unused%02X_%04X' % (bk, a))
            for k2, v in it.items():
                items.setdefault(k2, v)
                for x in range(v[0]): cov.add(k2 + x)
            for t in lb:
                if t not in g.labels: g.lab(t, 'Trk%02X_%04X' % (bk, t))
            a += 1
        g.end = end
        g.dw(0x5311, 0x5311 + 2 * SONGS[bk], per=4)
        for h in bh: emit_header(g, h)
        emit_track_items(g, {a: v for a, v in items.items() if a >= 0x5311})
        BANKEND[bk] = end
        src = g.render('Sound bank $%02X' % bk,
            '; Daiku no Gensan (J) - sound bank $%02X ($4000-$%04X)\n'
            '; Biox sound driver B v2. Disassembled for GBAudioLab\\Biox.\n\n'
            'DEF BIOXB_VER EQU 2\nINCLUDE "hardware.inc"\nINCLUDE "bioxB_sound.inc"\n\n'
            '; ---- RAM ----\n' % (bk, end - 1) + equ + '\n' if bk == 0x3C else
            '; Daiku no Gensan (J) - sound bank $%02X ($4000-$%04X)\n'
            '; Biox sound driver B v2. Disassembled for GBAudioLab\\Biox.\n\n'
            'DEF BIOXB_VER EQU 2\nINCLUDE "hardware.inc"\nINCLUDE "bioxB_sound.inc"\n\n'
            '; ---- RAM ----\n' % (bk, end - 1) + equ + '\n')
        lines = src.split('\n')
        # insert the common include right after the SECTION line
        for i, l in enumerate(lines):
            if l.startswith('SECTION'):
                lines[i] = l.replace('ROMX[$5311]', 'ROMX[$4000]')
                lines.insert(i + 1, '\nINCLUDE "Daiku_sound_common.inc"\n')
                break
        open('out/Daiku_sound_bank%02X.asm' % bk, 'w').write('\n'.join(lines))
    print('unused common:', ['%04X' % u for u in unused], 'bank ends', {hex(k): hex(v) for k, v in BANKEND.items()})

if __name__ == '__main__':
    main()
