"""Generate RGBDS sources for the Cosmo Tank sound bank (bank 4).
usage: python gen_ct.py <rom> <outdir>"""
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode
from ct import (Rom, headers, decode_stream, SOUND_TABLE, NUM_SOUNDS, PERIODS, LENTAB,
                ENVTAB, REGTAB, PANTAB, CMDS)

CODE_RANGES = [(0x4000, 0x4265), (0x4285, 0x4466)]
CMDTAB = 0x4265
COMMENTS = {
    0x4000: ['SndInit: APU on, every channel silenced (NRx2 = $08, NRx4 = $80), NR50 = $77, NR10 = NR51 = 0,',
             'all 8 track flags cleared. Called by the game (bank 0 $161B) and by sound id 0 (and $80).'],
    0x4031: ['SndStartQueued: start at most one queued id per frame (the last one queued).',
             'Header = {track, pointer-1} until $FF. Track 4-7 (SFX) set bit 7 (muted) on track - 4.',
             'flags = (flags | 1) & $81, timer = 1, atten = fine = transpose = 0.'],
    0x407C: ['SndUpdate: once per frame (VBlank, bank 0 $160D). Tracks 7..0, then SndStartQueued.',
             'Per active track: timer--; at 0 read events. Otherwise envelope count--; at 0 next pair:',
             'NRx2 = max(vol - atten, 0) and NRx4 = period hi (trigger), unless muted.',
             'BUG: the new volume goes to wTrackVol + [wCurTrack], which is stale here.'],
    0x40D5: ['SndReadEvents: read until a note, rest or end.',
             '$00-$53 note, $54 rest, $80-$BF length, $C0-$DF pan, $E0-$FF commands (CmdTable).'],
    0x412F: ['EvRest: wTrackVol = 8, flags bit 1; unless muted, clear the track\'s NR51 bits.'],
    0x415D: ['EvNote: timer = length. Period = Periods[note + transpose] + fine; trigger bit unless',
             'it is a CH3 track and NR52 says CH3 is still on. Envelope restarts at its first pair.',
             'Unless muted: NRx2, NRx1, NR51, NRx3, NRx4.'],
    0x4215: ['EvNoise: NR43 = note byte with its nibbles swapped; no transpose. NR42, NR51, NR43, NR44 = $80.'],
    0x43AD: ['LoadWave(hl): NR32 = 0, NR30 = 0, NR34 = $80, 16 bytes to wave RAM, NR30 = $80.'],
    0x43C8: ['CmdEnd ($FD/$FF): track off. Music track: silence its channel unless muted.',
             'SFX track: unmute track - 4; if that music track is still active restore NR10 (CH1),',
             'the wave (CH3), NR51, NRx2 = wTrackVol, NRx3/NRx4 + trigger; otherwise silence the channel.'],
}
EXPORTS = {0x4000, 0x407C}  # SndInit, SndUpdate (called from bank 0)

NAMES = {
    0x4000: 'SndInit', 0x402B: 'SndInit_ClearLoop',
    0x4031: 'SndStartQueued', 0x404E: 'SndStart_TrackLoop', 0x4060: 'SndStart_SetTrack',
    0x407C: 'SndUpdate', 0x407E: 'SndUpdate_NextTrackH', 0x4080: 'SndUpdate_NextTrack',
    0x40A4: 'SndEnvStep_VolOk',
    0x40D5: 'SndReadEvents', 0x40DF: 'SndNextEvent', 0x40E0: 'SndReadEvent',
    0x40FD: 'EvLength', 0x410E: 'EvPan', 0x412F: 'EvRest', 0x415D: 'EvNote',
    0x419C: 'EvNote_Trigger', 0x41A0: 'EvNote_StorePeriod', 0x41BC: 'EvNote_VolOk',
    0x420D: 'EvNote_Muted', 0x420E: 'SndTrackDone', 0x4215: 'EvNoise', 0x4233: 'EvNoise_VolOk',
    0x4285: 'CmdNop', 0x4289: 'CmdEnv', 0x42A6: 'CmdDuty', 0x42B1: 'CmdAtten', 0x42C0: 'CmdTranspose',
    0x42CB: 'CmdLoopStart', 0x42E1: 'CmdLoopEnd', 0x42F3: 'CmdLoopEnd_Done', 0x42F7: 'CmdCall',
    0x430E: 'CmdRet', 0x431E: 'CmdJump', 0x4329: 'CmdFine', 0x4336: 'CmdSweep', 0x4346: 'CmdSweep_Music',
    0x4356: 'CmdSweep_Done', 0x435C: 'CmdSweepOff', 0x4369: 'CmdSweepOff_Music', 0x437A: 'CmdSweepOff_Done',
    0x4380: 'CmdWave', 0x43A0: 'CmdWave_Sfx', 0x43A6: 'CmdWave_Load', 0x43A9: 'CmdWave_Done',
    0x43AD: 'LoadWave', 0x43BA: 'LoadWave_Loop',
    0x43C8: 'CmdEnd', 0x43D9: 'CmdEnd_Silence', 0x43EC: 'CmdEnd_Done', 0x43F3: 'CmdEnd_Sfx',
    0x440A: 'CmdEnd_SetSweep', 0x440C: 'CmdEnd_Restore', 0x445D: 'ReloadMusicWave',
    0x4265: 'CmdTable',
}

DATA_NAMES = {PERIODS: 'Periods', SOUND_TABLE: 'SoundTable', LENTAB: 'LengthTable',
              ENVTAB: 'EnvTable', REGTAB: 'RegTable', PANTAB: 'PanTable', 0x5A9C: 'Leftover'}

WRAM = [  # (addr, name, size, comment)
    (0xDF00, 'wTracks', 0x80, '8 tracks x 16 bytes (0-3 music CH1-CH4, 4-7 SFX CH1-CH4)'),
    (0xDF80, 'wSndQueueCount', 1, 'number of queued ids (rst $30 adds, max 4)'),
    (0xDF81, 'wSndQueue', 4, 'queued ids; the last one is started first'),
    (0xDF85, 'wSndUnused85', 6, 'not used by the driver'),
    (0xDF8B, 'wCurTrack', 1, 'track being processed'),
    (0xDF8C, 'wSweepSave', 1, 'NR10 of music track 0 (restored after a CH1 SFX)'),
    (0xDF8D, 'wWavePtr', 2, 'wave of music track 2 (restored after a CH3 SFX)'),
    (0xDF8F, 'wSndUnused8F', 1, 'not used by the driver'),
    (0xDF90, 'wTrackPan', 8, 'NR51 bits of each track'),
    (0xDF98, 'wTrackVol', 8, 'current NRx2 value of each track'),
    (0xDFA0, 'wCallStack', 16, 'return pointer of each track (2 bytes)'),
    (0xDFB0, 'wLoopStack', 24, 'loop count + pointer of each track (3 bytes)'),
]
IMM_SYMS = {0xDF80: 'wSndQueueCount', 0xDF8B: 'wCurTrack', 0xDF8C: 'wSweepSave', 0xDF8D: 'wWavePtr',
            0xDF90: 'wTrackPan', 0xDF98: 'wTrackVol', 0xDFA0: 'wCallStack', 0xDFB0: 'wLoopStack',
            0xDF00: 'wTracks'}
HW = {0x10: 'rNR10', 0x11: 'rNR11', 0x12: 'rNR12', 0x13: 'rNR13', 0x14: 'rNR14', 0x16: 'rNR21',
      0x17: 'rNR22', 0x18: 'rNR23', 0x19: 'rNR24', 0x1A: 'rNR30', 0x1B: 'rNR31', 0x1C: 'rNR32',
      0x1D: 'rNR33', 0x1E: 'rNR34', 0x20: 'rNR41', 0x21: 'rNR42', 0x22: 'rNR43', 0x23: 'rNR44',
      0x24: 'rNR50', 0x25: 'rNR51', 0x26: 'rNR52'}

NOTE_NAMES = ['C_', 'Cs', 'D_', 'Ds', 'E_', 'F_', 'Fs', 'G_', 'Gs', 'A_', 'As', 'B_']


def note_name(n):
    return f'{NOTE_NAMES[n % 12]}{n // 12 + 2}'


def code_lines(rom, labels):
    out = []
    for a0, a1 in CODE_RANGES:
        if a0 == 0x4285:
            out.append('')
            out.append('; command handlers ($E0-$EF / $F0-$FF), entered with hl = track +9 pushed, de = command byte')
        pc = a0
        while pc < a1:
            if pc in COMMENTS:
                out.append('')
                out += ['; ' + c for c in COMMENTS[pc]]
            if pc in labels:
                out.append(f'{labels[pc]}' + ('::' if pc in EXPORTS else ':'))
            n, s, info = decode(rom.d, 4 * 0x4000 + pc - 0x4000, pc)
            raw = rom.bytes(pc, n)
            s = sub_syms(s, info, labels)
            out.append(f'\t{s:<34}; {pc:04X}')
            pc += n
        if a1 == CMDTAB:
            out.append('')
            out.append('CmdTable: ; low nibble of $E0-$FF')
            for i in range(16):
                t = rom.w(CMDTAB + 2 * i)
                nm = CMDS[i][0]
                out.append(f'\tdw {labels[t]:<26}; ${i:X}: {nm}')
    return out


def sub_syms(s, info, labels):
    if 'target' in info and info.get('kind') != 'rst':
        t = info['target']
        s = s.replace('${:04X}'.format(t), labels[t])
        return s
    m = re.search(r'ldh (\[\$([0-9A-F]{2})\]|a, \[\$([0-9A-F]{2})\])', s)
    if m:
        r = int(m.group(2) or m.group(3), 16)
        return s.replace('${:02X}'.format(r), HW[0xFF00 + r - 0xFF00 if False else r]) if r in HW else s
    if 'imm16' in info:
        v = info['imm16']
        sym = IMM_SYMS.get(v) or DATA_NAMES.get(v) or labels.get(v)
        if sym:
            s = s.replace('${:04X}'.format(v), sym)
        return s
    if s in ('ld h, $DF', 'ld b, $DF'):
        return s.replace('$DF', 'HIGH(wTracks)')
    if s == 'ld c, $30':
        return 'ld c, LOW(_AUD3WAVERAM)'
    return s


def main():
    rom = Rom(sys.argv[1])
    outdir = sys.argv[2]
    labels = dict(NAMES)
    # any branch target in code not yet named
    for a0, a1 in CODE_RANGES:
        pc = a0
        while pc < a1:
            n, s, info = decode(rom.d, 4 * 0x4000 + pc - 0x4000, pc)
            if 'target' in info and info.get('kind') != 'rst' and info['target'] not in labels:
                labels[info['target']] = 'Snd_%04X' % info['target']
            pc += n
    for i in range(16):
        assert rom.w(CMDTAB + 2 * i) in labels
    labels.update(DATA_NAMES)

    # ---- sound data ----
    hdrs = headers(rom)
    ev = {}       # addr -> (len, kind, args)
    evtracks = {}  # addr -> set of track numbers
    entry = {}    # addr -> label (stream entry points, call/jump targets)
    for sid, a, tr in hdrs:
        for t, p in tr:
            e, ls = decode_stream(rom, p + 1, t)
            for k, v in e.items():
                ev[k] = v
                evtracks.setdefault(k, set()).add(t)
            for l in ls:
                entry.setdefault(l, None)
    hdr_at = {}
    for sid, a, tr in hdrs:
        hdr_at.setdefault(a, []).append(sid)
    # names for headers
    for a, sids in hdr_at.items():
        labels[a] = 'Sound%02X' % sids[0]
    for sid, a, tr in hdrs:
        for t, p in tr:
            if p + 1 not in labels:
                labels[p + 1] = 'Sound%02X_T%d' % (sid, t)
    for k in sorted(entry):
        if k not in labels:
            labels[k] = 'Seq_%04X' % k
    # envelopes and waves
    envs = sorted(set(rom.w(ENVTAB + 2 * i) for i in range(16)))
    for i in range(16):
        a = rom.w(ENVTAB + 2 * i)
        labels.setdefault(a, 'Env%X' % i)
    waves = [0x45D8, 0x45E8, 0x45F8, 0x4608]
    for i, a in enumerate(waves):
        labels[a] = 'Wave%d' % i

    L = []
    L.append('; Cosmo Tank (U) - Atlus sound driver (Tsukasa Masuko), ROM bank 4 $4000-$7FFF')
    L.append('; generated by tools/gen_ct.py; rebuilds the bank byte-exact (RGBDS 0.9.1)')
    L.append('')
    L.append('INCLUDE "cosmotank_sound.inc"')
    L.append('')
    L.append('SECTION "Sound driver", ROMX[$4000], BANK[4]')
    L.append('')
    L += code_lines(rom, labels)

    # tables
    L.append('')
    L.append('Periods: ; 84 GB periods, C_2 ($002C, 65.4 Hz) .. B_8')
    for i in range(84):
        if i % 12 == 0:
            L.append(f'\tdw ' + ', '.join('${:04X}'.format(rom.w(PERIODS + 2 * j)) for j in range(i, i + 12))
                     + f' ; octave {i // 12 + 2}')
    L.append('')
    L.append(f'SoundTable: ; {NUM_SOUNDS} sound ids (id 0 = stop all, never read)')
    for i in range(NUM_SOUNDS):
        L.append(f'\tdw {labels[rom.w(SOUND_TABLE + 2 * i)]:<14}; ${i:02X}')
    L.append('')
    L.append('LengthTable: ; $80-$BF: note length in frames (0 = 256)')
    for i in range(0, 64, 16):
        L.append('\tdb ' + ', '.join('%3d' % rom.b(LENTAB + j) for j in range(i, i + 16)) + f' ; ${0x80 + i:02X}')
    L.append('')
    L.append('EnvTable: ; $E0 n')
    for i in range(16):
        L.append(f'\tdw {labels[rom.w(ENVTAB + 2 * i)]:<8}; {i}')
    L.append('')
    L.append('; envelopes: {frames, NRx2} pairs, the volume is NRx2 - atten; every step re-triggers')
    a = 0x45B6
    while a < 0x45D8:
        if a in labels:
            L.append(f'{labels[a]}:')
        L.append(f'\tenv_step {rom.b(a)}, ${rom.b(a + 1):02X}')
        a += 2
    L.append('')
    for i, w in enumerate(waves):
        L.append(f'{labels[w]}:' + (' ; not used' if w == 0x45E8 else ''))
        L.append('\tdb ' + ', '.join('$%02X' % x for x in rom.bytes(w, 16)))

    # sound data
    L.append('')
    L.append('; ---- sounds: headers and track streams ----')
    a = 0x4618
    while a < REGTAB:
        if a in hdr_at:
            L.append('')
            L.append(f'{labels[a]}: ; ' + ', '.join('$%02X' % s for s in hdr_at[a]))
            while rom.b(a) != 0xFF:
                t, p = rom.b(a), rom.w(a + 1)
                L.append(f'\ttrack {t}, {labels[p + 1]}')
                a += 3
            if a in ev:  # header terminator also read as an event (empty track)
                L.append(f'EmptyTrack: ; an event pointing here ends at once')
                labels[a] = 'EmptyTrack'
            L.append('\thdr_end')
            a += 1
            continue
        if a not in ev:
            raise SystemExit('unparsed byte at %04X' % a)
        if a in labels and a not in hdr_at:
            L.append(f'{labels[a]}:')
        n, kind, args = ev[a]
        trk = evtracks[a]
        noise = all(t & 3 == 3 for t in trk)
        if kind == 'note':
            v = args[0]
            if noise:
                L.append(f'\tnoise ${(v << 4 | v >> 4) & 0xFF:02X}')
            elif v < 0x54:
                L.append(f'\tnote {note_name(v)}')
            else:
                L.append(f'\tdb ${v:02X} ; note beyond the period table')
        elif kind == 'rest':
            L.append('\trest')
        elif kind == 'len':
            L.append(f'\tlen ${args[0]:02X} ; {rom.b(LENTAB + args[0]) or 256}')
        elif kind == 'pan':
            L.append('\tpan ' + {0: 'PAN_C', 4: 'PAN_R', 8: 'PAN_L'}.get(args[0], '$%02X' % args[0]))
        else:
            name = kind
            b = rom.b(a)
            pre = '' if b >= 0xF0 else ''
            if name in ('call', 'jump'):
                t = args[0] | args[1] << 8
                L.append(f'\tseq_{name} {labels[t]}')
            elif name == 'wave':
                t = args[0] | args[1] << 8
                L.append(f'\twave {labels[t]}')
            elif name in ('duty', 'atten', 'transpose', 'loop_start', 'fine', 'sweep', 'env'):
                v = args[0]
                if name == 'transpose' and v >= 0x80:
                    L.append(f'\ttranspose {v - 256}')
                elif name in ('loop_start', 'env', 'fine'):
                    L.append(f'\t{name} {v}')
                else:
                    L.append(f'\t{name} ${v:02X}')
            else:
                L.append(f'\t{name}' if name in ('loop_end', 'sweep_off') else f'\tseq_{name}')
            if b < 0xF0:
                raise SystemExit('unexpected $E0-$EF command at %04X' % a)
        a += n

    L.append('')
    L.append('RegTable: ; per track: NRx2, NRx4 (low bytes)')
    for t in range(8):
        L.append(f'\tdb LOW({HW[rom.b(REGTAB + 2 * t)]}), LOW({HW[rom.b(REGTAB + 2 * t + 1)]}) ; track {t}')
    L.append('')
    L.append('PanTable: ; (pan & $1F) + (track & 3)')
    for i in range(0, 16, 4):
        L.append('\tdb ' + ', '.join('$%02X' % rom.b(PANTAB + j) for j in range(i, i + 4)))
    L.append('')
    L.append('Leftover: ; $5A9C-$7FFF: fill, never read by the driver')
    lo = rom.bytes(0x5A9C, 0x8000 - 0x5A9C)
    i = 0
    while i < len(lo):
        j = i
        while j < len(lo) and lo[j] == lo[i]:
            j += 1
        if j - i >= 8:
            L.append(f'\tds {j - i}, ${lo[i]:02X}')
            i = j
        else:
            k = min(i + 16, len(lo))
            # stop before a long run
            m = i
            while m < k:
                r = m
                while r < len(lo) and lo[r] == lo[m]:
                    r += 1
                if r - m >= 8 and m > i:
                    break
                m += 1
            k = max(m, i + 1)
            L.append('\tdb ' + ', '.join('$%02X' % x for x in lo[i:k]))
            i = k
    open(os.path.join(outdir, 'CosmoTank_SoundDriver.asm'), 'w', newline='\n').write('\n'.join(L) + '\n')
    inc = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), 'inc_static.txt')).read()
    w = ['', '; ---- WRAM ($DF00-$DFC7) ----']
    for a, n, s, c in WRAM:
        w.append(f'DEF {n:<16} EQU ${a:04X} ; {s:>3} bytes: {c}')
    open(os.path.join(outdir, 'cosmotank_sound.inc'), 'w', newline='\n').write(inc + '\n'.join(w) + '\n')


if __name__ == '__main__':
    main()
