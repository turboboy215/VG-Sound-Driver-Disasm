"""SFX engine of Tetris Attack (GB), bank $07 $4000-$67A8.

Not the Tanaka effect design (stream pointers are even stored big-endian, high byte first): an effect's init routine points up to four channel streams (and a wave
stream) at data, and one routine plays all of them. Each stream is a list of register images, each
followed by a frame count; a frame count of $FF ends the stream:
  ch1: NR10-NR14 + frames          (6-byte rows)
  ch2: NR21-NR24 + frames          (5)
  ch3: flag, NR31-NR34 + frames    (6; flag $FF = load the next 16 bytes of the wave stream first)
  ch4: NR42, NR43 + frames         (3; the 4-register form exists but is never reached)
A second slot (wSfx3Request = 1) plays one fixed noise stream (NR42, NR43 + frames)."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
from ta_music import RAM as MRAM

RAM = dict(MRAM)
RAM.update({
 0xd3a6: 'wSfxFramesCh1', 0xd3a7: 'wSfxFramesCh2', 0xd3a8: 'wSfxFramesCh3', 0xd3a9: 'wSfxFramesCh4', 0xd3ae: 'wSfxMode',
 0xd3b9: 'wSfxPtrCh1', 0xd3ba: 'wSfxPtrCh1+1', 0xd3bb: 'wSfxPtrCh2', 0xd3bc: 'wSfxPtrCh2+1', 0xd3bd: 'wSfxPtrCh3', 0xd3be: 'wSfxPtrCh3+1',
 0xd3bf: 'wSfxPtrCh4', 0xd3c0: 'wSfxPtrCh4+1', 0xd3c1: 'wSfxWavePtr', 0xd3c2: 'wSfxWavePtr+1', 0xd3cd: 'wNoiseFrames',
 0xd3df: 'wNoisePtr', 0xd3e0: 'wNoisePtr+1', 0xd3e3: 'wSfxPriority',
})

NAMES = {
 0x4000: 'Sound_StopMusic', 0x400d: 'Music_ClearState',
 0x4054: 'Sfx_MuteAll', 0x4073: 'JumpTable', 0x407f: 'WriteRegs', 0x4086: 'FillBytes',
 0x408b: 'SetStreamCh1', 0x4094: 'SetStreamCh2', 0x409d: 'SetStreamCh4', 0x40a6: 'SetNoiseStream', 0x40af: 'RestoreWave',
 0x40b4: 'RestoreWave.loop', 0x40bd: 'ReleaseCh1', 0x40c6: 'TakeCh1', 0x40d7: 'ReleaseCh2', 0x40e0: 'TakeCh2',
 0x40f0: 'ReleaseCh3', 0x40f9: 'TakeCh3', 0x4107: 'ReleaseCh4', 0x4110: 'TakeCh4',
 0x4120: 'SfxPriorityTable', 0x4178: 'Sfx_Update', 0x417f: 'Sfx_Update.play', 0x4187: 'Sfx_Update.request', 0x41af: 'Sfx_Update.dispatch',
 0x41b3: 'SfxInitTable',
 0x4d8e: 'Noise_Update', 0x4dad: 'Noise_Update.playing', 0x4de0: 'Noise_Update.next', 0x4dee: 'Noise_Update.done',
 0x4def: 'Sfx_PlayStreams', 0x4e02: 'Sfx_PlayStreams.ch2', 0x4e09: 'Sfx_PlayStreams.ch3', 0x4e10: 'Sfx_PlayStreams.ch4',
 0x4e17: 'Sfx_PlayStreams.active', 0x4e2b: 'Sfx_PlayStreams.ch1', 0x4e4e: 'Sfx_PlayStreams.ch1End', 0x4e6d: 'Sfx_PlayStreams.ch1Next',
 0x4e7b: 'Sfx_PlayStreams.ch1NoSweep', 0x4e87: 'Sfx_PlayStreams.ch2Play', 0x4ebf: 'Sfx_PlayStreams.ch2Next',
 0x4ecd: 'Sfx_PlayStreams.ch3Play', 0x4eea: 'Sfx_PlayStreams.ch3Regs', 0x4f0e: 'Sfx_PlayStreams.ch3End', 0x4f20: 'Sfx_PlayStreams.ch3Next',
 0x4f2e: 'Sfx_PlayStreams.ch3Wave', 0x4f4e: 'Sfx_PlayStreams.ch4Play', 0x4f71: 'Sfx_PlayStreams.ch4End', 0x4f8d: 'Sfx_PlayStreams.ch4Next',
 0x4f9b: 'Sfx_PlayStreams.ch4Short', 0x4fab: 'Sfx_PlayStreams.done',
}
COMMENTS = {
 0x4000: 'Stop the music (same routine as bank $08\'s, without the SFX channel checks).',
 0x4054: 'Silence all four channels (registers only; called by effects that take every channel).',
 0x4073: 'Jump through the table that follows the call: a = 0-based index.',
 0x407f: 'Write b bytes from hl to the registers from c.',
 0x40af: 'unreferenced: reload the music\'s wave from the copy at wWaveCopy.',
 0x40bd: 'Give a channel back to the music (Flags bit 7) / take it (and silence it).',
 0x4120: 'one byte per effect $00-$50: an effect starts only if its value is <= the priority of the\none playing (wSfxPriority, $FF = none). Then $FF padding.',
 0x4178: 'Called once per frame (from the home routine $1500). wSfx1Request = effect $01-$50.',
 0x41b3: 'effect init routines, $00-$50 (dw table read by JumpTable)',
 0x4d8e: 'Slot 2: wSfx3Request = 1 plays the noise stream NoiseStream_6300 on ch4 (2 registers + frames).',
 0x4def: 'Play every active stream (wSfxActive bits 3-0 = ch1-ch4). wSfxChannels holds the channels a\nnew effect starts; while ch4 plays wSfxMode = $10 (short ch4 rows). A stream that ends gives\nits channel back to the music unless the game is paused (wPaused).',
 0x4f2e: 'ch3 row with flag $FF: switch ch3 off, load the next 16 bytes of the wave stream.',
 0x4f0e: 'ch3 stream end: restore the music\'s wave.',
}

SETTER = {0x408b: 'ch1', 0x4094: 'ch2', 0x409d: 'ch4', 0x40a6: 'noise'}
ROWS = {'ch1': 6, 'ch2': 5, 'ch3': 6, 'ch4': 3, 'noise': 3, 'wave': 16}


def build(rom):
    r = Region(rom, 7, 0x4000, 0x8000)
    r.ram = dict(RAM)
    r.trace([0x4000, 0x4178, 0x4d8e])
    ents = r.jumptable(0x41b3, 81)
    r.code_range(0x40af, 0x40bd)
    for x in (0x43cf, 0x494e, 0x49f3, 0x4c18, 0x4c34, 0x4c50, 0x4c90):
        r.code_range(x, x + 1); r.comments[x] = 'unreachable'
    for a, n in NAMES.items(): r.label(a, n)
    for a, t in COMMENTS.items(): r.comments[a] = t
    seen = {}
    for i, e in enumerate(ents):
        if e in seen:
            r.comments[e] = (r.comments.get(e, '') + f'\nalso effect ${i:02X}').strip(); continue
        seen[e] = i
        if e not in r.labels or r.labels[e].startswith('Code_'): r.label(e, f'Sfx_{i:02X}')
    r.block(0x4120, 0x4178 - 0x4120, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+k):02x}' for k in range(i, min(i+16, 81))) + f'\t; ${i:02x}-'
                                                    for i in range(0, 81, 16)] + ['\tds 7, $ff'])
    # stream typing from the init routines
    kinds = {}
    pcs = sorted(r.code)
    for j, pc in enumerate(pcs):
        l, fmt, args, k = r.code[pc]
        if fmt.startswith(('ld hl, ', 'ld bc, ', 'ld de, ')) and args[0][0] == 'i16' and r.inreg(args[0][1]):
            v = args[0][1]
            nxt = r.code.get(pcs[j+1]) if j + 1 < len(pcs) else None
            if nxt and nxt[2] and nxt[2][0][0] == 'call' and nxt[2][0][1] in SETTER:
                kinds[v] = SETTER[nxt[2][0][1]]
            elif nxt and nxt[1] == 'ld a, h':
                n2 = r.code.get(pcs[j+2])
                PTR = {0xd3b9: 'ch1', 0xd3bb: 'ch2', 0xd3bd: 'ch3', 0xd3bf: 'ch4', 0xd3c1: 'wave', 0xd3df: 'noise'}
                if n2 and n2[2] and n2[2][0][1] in PTR: kinds[v] = PTR[n2[2][0][1]]
    owner = {}
    cur = None
    for pc in pcs:
        n = r.labels.get(pc, '')
        if n.startswith('Sfx_') and '.' not in n: cur = n
        if n and not n.startswith(('Sfx_', 'Code_')) and '.' not in n: cur = None
        for t, v in r.code[pc][2]:
            if t == 'i16' and v in kinds and cur: owner.setdefault(v, cur)
    for v, kd in kinds.items():
        nm = {'wave': 'WaveStream', 'noise': 'NoiseStream'}.get(kd, f'{owner.get(v, "Sfx")}_{kd.capitalize()}')
        r.label(v, f'{nm}_{v:04X}' if kd in ('wave', 'noise') else nm)
    return r, ents, kinds


def stream_blocks(r, kinds, lo, hi):
    """one block per stream: rows of the channel's size up to the $FF frame byte"""
    starts = sorted(kinds)
    for s in starts:
        kd = kinds[s]; n = ROWS[kd]
        if kd == 'wave':
            e = s + 16
            while e + 16 <= hi and e not in kinds and e not in r.code and r.block_of(e) is None and e not in r.labels: e += 16
        else:
            e = s
            while True:
                if r.byte(e + n - 1) == 0xff: e += n; break
                e += n
        if any(r.block_of(x) is not None for x in (s, e - 1)): continue
        def em(rr, a, e=e, n=n, kd=kd):
            out = []; q = a
            while q < e:
                k = min(n, e - q)
                out.append('\tdb ' + ', '.join(f'${rr.byte(q+i):02x}' for i in range(k)) + ('\t; end' if kd != 'wave' and q + k == e else ''))
                q += k
            return out
        r.block(s, e - s, em)
