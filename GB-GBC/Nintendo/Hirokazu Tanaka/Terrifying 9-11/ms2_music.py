"""Music bank of Metal Slug 2 (unlicensed), bank $28.

The engine around the sequencer is Link's Awakening DX's music driver (bank $1B): same RAM
layout (moved from $D300 to $C800), channel loop, effects (vibrato, drop, ch3 fades), release
envelopes, note / noise / vibrato tables and stop routines, mostly with `jr` turned into `jp`.
The sequencer and the song format were replaced:
  - a song header is a list of (channel, stream pointer) pairs instead of LA's section lists
  - a stream is a byte code with an octave / speed state: note bytes $00-$BF carry a semitone
    (high nibble) and a length multiplier (low nibble); commands $C0-$FF
Several LA routines the new sequencer no longer uses are still in the bank, unreferenced."""
import sys, os
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
import ladx_music as LM

BASE = 0xc800
RAM = {a - 0xd300 + BASE: n for a, n in LM.RAM.items() if 0xd300 <= a < 0xd400 and not a in range(0xd310, 0xd350)}
CHF = {0: 'StreamPtr', 1: 'StreamPtr+1', 2: 'OctaveSpeed', 3: 'Counter', 4: 'Transpose', 6: 'InstrEnv', 7: 'InstrRelease',
       8: 'InstrDuty', 9: 'Freq', 10: 'Freq+1', 11: 'Sounding', 12: 'MarkPtr', 13: 'MarkPtr+1', 14: 'NoteFrames', 15: 'Flags'}
for n in range(4):
    for o, f in CHF.items(): RAM[BASE + 0x10 + 0x10*n + o] = f'wCh{n+1}{f}'
RAM.update({0xc836: 'wCh3WaveOffset', 0xc838: 'wCh3Level', 0xc8ce: 'wMusicDisabled', 0xc806: 'wReleaseFrameBase'})
for a in (0xc836, 0xc837): pass

NAMES = {
 0x4000: 'BankTag', 0x400a: 'Music_Update', 0x4015: 'Music_Update.play', 0x4019: 'Music_ClearRequests', 0x4027: 'Music_Update.start',
 0x4038: 'Music_Init', 0x403b: 'Music_Init.clear',
 0x404e: 'MusicDrum_Update', 0x4061: 'MusicDrum_Update.start', 0x406c: 'MusicDrum_Update.playing',
 0x407a: 'MusicDrum_StartRegs', 0x407f: 'MusicDrum_EndRegs', 0x4084: 'MusicDrum_WriteRegs', 0x4088: 'MusicDrum_WriteRegs.loop',
 0x4092: 'GetPointer', 0x409f: 'Unused_LoadWave', 0x40a2: 'Unused_LoadWave.loop', 0x40ad: 'StopSfx4', 0x40c9: 'Unused_MusicStop',
 0x40f5: 'Music_StartSong', 0x4112: 'Music_LoadWave', 0x412c: 'Music_LoadWave.loop', 0x413a: 'Music_LoadWave.done',
 0x413b: 'Music_SetLength', 0x4145: 'Music_SetLength.add', 0x4151: 'Music_SetLength.release', 0x4171: 'Music_SetLength.store',
 0x4177: 'Music_SetLength.storeRelease',
 0x4181: 'Unused_CopyWordIndirect', 0x418c: 'Unused_CopyWord',
 0x4192: 'Music_LoadHeader', 0x41bb: 'Music_LoadHeader.load', 0x41c0: 'Music_LoadHeader.channel',
 0x41e7: 'Unused_CmdInstrumentWave', 0x41f9: 'Unused_CmdInstrument',
 0x4221: 'Music_ChannelDone', 0x4225: 'IncPtr', 0x422b: 'IncPtr.store', 0x4231: 'Unused_IncPtr2', 0x423b: 'ReadPtrByte',
 0x4241: 'Music_Sustain', 0x425c: 'Music_Sustain.effects',
 0x4274: 'Music_Effects_ret', 0x4276: 'Music_Effects', 0x429c: 'Music_Effects.drop', 0x42c5: 'Music_Effects.ch3', 0x42de: 'Music_Effects.pitch',
 0x42fe: 'ReadPitch', 0x430b: 'Music_Vibrato', 0x4325: 'Music_Vibrato.apply', 0x4346: 'Music_Vibrato.wrap', 0x434e: 'Music_Vibrato.first',
 0x4354: 'Music_Drop', 0x4361: 'Music_Drop.apply', 0x436b: 'Music_Drop.next',
 0x4371: 'GetNoteFreq', 0x437c: 'WritePitch', 0x438d: 'IndexByChannel',
 0x4396: 'Music_Ch3FadeOut', 0x43ce: 'Music_Ch3Fade.write', 0x43d3: 'IncByteBC', 0x43d7: 'Music_Ch3FadeIn',
 0x4408: 'Music_Release', 0x4433: 'Music_Release.ch2', 0x4457: 'Music_ReleaseWrite', 0x446a: 'ReleaseEnvelopes',
 0x4471: 'Cmd_Rest', 0x448e: 'Cmd_Rest.noise', 0x449d: 'Cmd_Instrument', 0x44d3: 'Music_Command',
 0x451e: 'Cmd_Speed', 0x4532: 'Cmd_Ch3FadeOutOn', 0x453a: 'Cmd_Ch3FadesOff', 0x4548: 'Cmd_Ch3FadeInOn', 0x4550: 'Cmd_Transpose',
 0x455f: 'Cmd_DropOn', 0x4567: 'Cmd_DropOff', 0x456f: 'Cmd_Ch3SfxPause', 0x4577: 'Cmd_Ch3SfxResume', 0x457f: 'Cmd_Poke',
 0x4595: 'Music_FlowCommand', 0x45a7: 'Cmd_Mark', 0x45b5: 'Cmd_Jump', 0x45c4: 'Cmd_RepeatMark', 0x45dc: 'Cmd_RepeatMark.done',
 0x45e2: 'Cmd_RepeatMark.first', 0x45e9: 'Cmd_RepeatMark.back',
 0x45f4: 'Music_Play', 0x4609: 'Music_ChannelLoop', 0x4619: 'Music_ReadEvent', 0x4650: 'Music_Note.addTranspose',
 0x4653: 'Music_Note.octave', 0x4666: 'Music_Note.octaveLoop', 0x4677: 'Music_Note.lookup',
 0x4694: 'Music_Trigger', 0x46bb: 'Music_Trigger.fadeIn', 0x46cb: 'Music_Trigger.ch3Restart', 0x46d0: 'Music_Trigger.ch3',
 0x46e9: 'Music_Trigger.ch2', 0x46ee: 'Music_Trigger.ch1', 0x46f0: 'Music_Trigger.readInstr', 0x4704: 'Music_Trigger.duty',
 0x4712: 'Music_Trigger.write', 0x471f: 'Music_Trigger.done', 0x4723: 'Music_NextChannel', 0x4737: 'Music_NoiseNote',
 0x4745: 'Music_NoiseNote.copy', 0x4754: 'Music_NextChannel.allDone',
 0x4761: 'VibratoTable', 0x4789: 'NoteTable', 0x481b: 'NoiseTable', 0x4858: 'Unused_LengthTables',
 0x48de: 'Sound_Stop', 0x48fc: 'Sound_StopMusic', 0x4909: 'Music_ClearState', 0x4988: 'WaveTable', 0x4a28: 'SongTable',
}

COMMENTS = {
 0x4000: 'byte $1D: tag byte at the start of the bank (the SFX bank has $1E)',
 0x4001: 'Entry points: update, init, stop (LA: init, stop, update).',
 0x400a: 'Called once per frame before the SFX bank. A new song request re-initialises the whole\nsound RAM and the APU first.',
 0x4019: 'Clear all four request bytes.',
 0x404e: 'ch4 "drum" effect 1 from LA, kept although no MS2 song uses ch4.',
 0x409f: 'unreferenced: LA\'s LoadWave',
 0x40c9: 'unreferenced: LA\'s Music_Stop (song request $FF)',
 0x40f5: 'Songs 1-10. Nothing starts while wMusicDisabled is set.',
 0x4112: 'ch3 instrument: wave = WaveTable + InstrEnv (a byte offset), loaded unless a ch3 SFX\nplays.',
 0x413b: 'Counter += (speed + 1) * (length nibble + 1), then - 1. The release point is computed as\nin LA: InstrRelease bit 7 = half, bit 6 = a quarter, otherwise three quarters (at least\n2).',
 0x4181: 'unreferenced: LA\'s CopyWordIndirect and CopyWord',
 0x4192: 'Header: count - 1, then (channel 0-3, stream pointer) per channel; bit 15 of the\npointer is masked off. LA\'s ch4 effect exceptions are kept.',
 0x41e7: 'unreferenced: LA\'s $9D command',
 0x4231: 'unreferenced: LA\'s IncPtr2',
 0x4241: 'Frame without a new event: count down, ch3 50% drop 6 frames before the end, effects,\nrelease envelope.',
 0x4276: 'Pitch effect from the low nibble of InstrDuty: 1 = vibrato after 24 frames, other\nnon-zero = period - 1 per frame. Then drop and the ch3 fades (LA bank $1B).',
 0x4396: 'As in LA, but nothing happens on a rest (wCh3Sounding = 0).',
 0x446a: 'NRx2 at the release point, index = low nibble of InstrRelease',
 0x4471: '$C0-$CF: rest, length nibble as for notes. ch4 is silenced directly.',
 0x449d: '$D0-$DF xx yy zz: speed = low nibble; InstrEnv, InstrRelease, InstrDuty = xx, yy, zz.',
 0x44d3: '$E0-$E5: octave = low nibble. $E6-$EF: see below. $F0 and above: Music_FlowCommand.',
 0x451e: '$E6 xx: speed = xx.',
 0x4532: '$E7: ch3 fade-out on. $E8: both ch3 fades off. $E9: ch3 fade-in on.',
 0x4550: '$EA xx: transpose = xx (signed, in semitones).',
 0x455f: '$EB / $EC: drop on / off. Unlike LA there is one flag (wDrop) for all channels.',
 0x456f: '$ED / $EE: pause / resume the ch3 SFX.',
 0x457f: '$EF xx yy: write xx to $C8yy.',
 0x4595: '$FB: mark. $FD xx yy: jump to yyxx. $FE xx: go back to the mark xx more times.\nAny other byte from $F0 up stops the music (Sound_Stop).',
 0x45b5: 'Only the low byte of the operand pointer is incremented (inc c): an operand straddling a\n256-byte page would be read wrongly. None does.',
 0x45f4: 'Music: four 16-byte channel structures at wCh1StreamPtr + $10*n.',
 0x4619: 'Note $00-$BF: high nibble = semitone, low nibble = length. NoteTable index =\n(5 - octave) * 12 + semitone + transpose (entry 1 = C2).',
 0x4694: 'Write the note. A channel with Sounding = 0 (rest) gets NRx2 = $08.',
 0x4737: 'ch4: NoiseTable + 5 * index, 5 bytes: NR42, -, NR41, NR43, NR44.',
 0x4761: 'vibrato: 20 big-endian period offsets (LA\'s table)',
 0x4858: 'unreferenced: LA\'s length tables (the last one lacks its final byte)',
 0x48de: 'Stop everything this bank controls (LA\'s Sound_Stop).',
 0x4988: '10 waves; INSTR on ch3 gives the byte offset ($00, $10, ... $90)',
}

UNUSED_CODE = [(0x409f, 0x40ad), (0x40c9, 0x40f5), (0x4181, 0x4192), (0x41e7, 0x4221), (0x4231, 0x423b)]


class Streams:
    """parse the MS2 song byte code"""
    def __init__(self, r):
        self.r = r; self.seg = {}; self.events = {}; self.targets = set(); self.chan_of = {}; self.ends = {}

    def parse(self, start, ch):
        r = self.r; work = [start]
        while work:
            a = work.pop()
            if a in self.seg: continue
            self.seg[a] = None; self.chan_of.setdefault(a, ch)
            while True:
                if a in self.events: break
                b = r.byte(a)
                if b < 0xc0: ev = ('note', 1)
                elif b < 0xd0: ev = ('rest', 1)
                elif b < 0xe0: ev = ('instr', 4)
                elif b < 0xe6: ev = ('octave', 1)
                elif b in (0xe6, 0xea, 0xfe): ev = ({0xe6: 'speed', 0xea: 'transpose', 0xfe: 'repeat'}[b], 2)
                elif b == 0xef: ev = ('poke', 3)
                elif b == 0xfb: ev = ('mark', 1)
                elif b == 0xfd: ev = ('jump', 3)
                elif b >= 0xf0: ev = ('stop', 1)
                else: ev = ('cmd', 1)
                self.events[a] = (ev[0], ev[1], ch)
                if ev[0] == 'jump':
                    t = r.word(a+1) & 0x7fff
                    self.targets.add(t); work.append(t); self.chan_of.setdefault(t, ch)
                    self.ends[a] = a + 3
                    break
                if ev[0] == 'stop':
                    self.ends[a] = a + 1
                    break
                a += ev[1]


def build(rom):
    r = Region(rom, 0x28, 0x4000, 0x8000)
    r.ram = dict(RAM)
    r.trace([0x4001, 0x4004, 0x4007])
    for a, b in UNUSED_CODE: r.code_range(a, b)
    for a, n in NAMES.items(): r.label(a, n)
    for a, t in COMMENTS.items(): r.comments[a] = t
    hexb = lambda rr, a, n: '\tdb ' + ', '.join(f'${rr.byte(a+i):02x}' for i in range(n))
    r.block(0x4000, 1, lambda rr, a: ['\tdb $1d'])
    r.block(0x407a, 5, lambda rr, a: [hexb(rr, a, 5) + '\t; NR41-NR44, frames'])
    r.block(0x407f, 5, lambda rr, a: [hexb(rr, a, 5) + '\t; NR41-NR44, frames'])
    r.block(0x446a, 7, lambda rr, a: [hexb(rr, a, 7)])
    r.block(0x4761, 40, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+2*i):02x}, ${rr.byte(a+2*i+1):02x}' for i in range(k, k+4)) for k in range(0, 20, 4)])
    r.block(0x4789, 146, lambda rr, a: [f'\tdw ${rr.word(a):04x}\t; index 0'] + [f'\tdw ${rr.word(a+2+2*i):04x}\t; {LM.note_name(2+2*i)}' for i in range(72)])
    r.block(0x481b, 61, lambda rr, a: [hexb(rr, a+5*k, 5) + f'\t; {k}' for k in range(12)] + [hexb(rr, a+60, 1)])
    r.block(0x4858, 0x48de - 0x4858, lambda rr, a: [hexb(rr, a+15*k, min(15, 0x48de - 0x4858 - 15*k)) for k in range(9)])
    r.block(0x4988, 160, lambda rr, a: [hexb(rr, a+16*k, 16) + f'\t; ${16*k:02x}' for k in range(10)])
    r.block(0x4a28, 20, lambda rr, a: [f'\tdw {rr.sym_addr(rr.word(a+2*i))}\t; song {i+1}' for i in range(10)])
    st = Streams(r)
    for i in range(10):
        h = r.word(0x4a28 + 2*i); n = r.byte(h) + 1
        r.label(h, f'Song{i+1:02d}_Header')
        for k in range(n):
            ch = r.byte(h + 1 + 3*k); p = r.word(h + 2 + 3*k) & 0x7fff
            if p not in r.labels: r.label(p, f'Song{i+1:02d}_Ch{ch+1}')
            st.parse(p, ch)
        def hdr(rr, a, n=n):
            out = [f'\tdb {n} - 1\t; channels']
            for k in range(n):
                ch = rr.byte(a + 1 + 3*k); w = rr.word(a + 2 + 3*k)
                out.append(f'\tSTREAM {ch}, {rr.sym_addr(w & 0x7fff)}' + (' | $8000' if w & 0x8000 else ''))
            return out
        r.block(h, 1 + 3*n, hdr)
    for t in st.targets:
        if t not in r.labels: r.label(t, f'Stream_{t:04X}')
    # spans: from each segment start to its end, merged
    spans = []
    for s in sorted(st.seg):
        a = s
        while a in st.events and a not in st.ends: a += st.events[a][1]
        if a in st.ends: spans.append([s, st.ends[a]])
    spans.sort(); merged = []
    for s, e in spans:
        if merged and s <= merged[-1][1]: merged[-1][1] = max(merged[-1][1], e)
        else: merged.append([s, e])
    def emit_stream(rr, a, end):
        lines = []; cur = []; q = a
        def flush():
            if cur: lines.append('\tdb ' + ', '.join(cur)); cur.clear()
        while q < end:
            if q != a and q in rr.labels:
                flush(); lines.append(rr.labels[q] + ':')
            kind, size, ch = st.events[q]
            b = rr.byte(q)
            if kind == 'note':
                cur.append(f'N{b >> 4}x{(b & 15) + 1}')
                if len(cur) >= 12: flush()
            elif kind == 'rest':
                cur.append(f'R{(b & 15) + 1}')
                if len(cur) >= 12: flush()
            else:
                flush()
                if kind == 'instr': lines.append(f'\tINSTR {b & 15}, ${rr.byte(q+1):02x}, ${rr.byte(q+2):02x}, ${rr.byte(q+3):02x}')
                elif kind == 'octave': lines.append(f'\tOCTAVE {b & 15}')
                elif kind == 'speed': lines.append(f'\tSPEED {rr.byte(q+1)}')
                elif kind == 'transpose':
                    v = rr.byte(q+1); lines.append(f'\tTRANSPOSE {v - 256 if v > 127 else v}')
                elif kind == 'repeat': lines.append(f'\tREPEAT_MARK {rr.byte(q+1)}')
                elif kind == 'poke': lines.append(f'\tPOKE ${rr.byte(q+1):02x}, ${0xc800 + rr.byte(q+2):04x}')
                elif kind == 'mark': lines.append('\tMARK')
                elif kind == 'jump':
                    w = rr.word(q+1)
                    lines.append(f'\tJUMP {rr.sym_addr(w & 0x7fff)}' + (' | $8000' if w & 0x8000 else ''))
                elif kind == 'stop': lines.append('\tEND_SONG' if b == 0xff else f'\tdb ${b:02x}\t; stops the music')
                else:
                    lines.append('\t' + {0xe7: 'CH3_FADEOUT_ON', 0xe8: 'CH3_FADES_OFF', 0xe9: 'CH3_FADEIN_ON', 0xeb: 'DROP_ON',
                                         0xec: 'DROP_OFF', 0xed: 'CH3_SFX_PAUSE', 0xee: 'CH3_SFX_RESUME'}[b])
            q += size
        flush()
        return lines
    starts = {s for s, e in merged}
    for s, e in merged:
        pad = r.byte(e) == 0 and e not in starts and e not in r.labels
        def em(rr, a, e=e, pad=pad):
            out = emit_stream(rr, a, e)
            if pad: out.append('\tdb $00\t; never read')
            return out
        r.block(s, e - s + pad, em)
    r.label(0x6010, 'NotSound_Tiles', 'not sound data: 2bpp tiles (a 1bpp font with $FF in every other byte),\n$6010-$775F')
    r.block(0x6010, 0x7760 - 0x6010, lambda rr, a: [hexb(rr, a+16*k, 16) for k in range((0x7760 - 0x6010) // 16)])
    r.collect_refs()
    return r, st, merged
