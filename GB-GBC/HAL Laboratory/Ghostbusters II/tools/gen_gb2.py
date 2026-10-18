"""Generate the Ghostbusters II sound driver sources.
bank 0 $07D4-$084C : request queue (rst $20), init, initial wave / register values
bank 7 $4000-...   : driver code, tables, envelopes, sound headers and streams
usage: python3 gen_gb2.py <rom> <outdir>"""
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from asmgen import AsmGen
from halsnd import Lazy
from halcommon import write_build_check, HW_INC, write

P = 'GB2'
BANK = 7

RAM = {
    0xC511: 'wChPtr', 0xC521: 'wChEnvPtr', 0xC531: 'wChEnvIndex', 0xC539: 'wChWait', 0xC541: 'wChLength',
    0xC549: 'wChEnvWait', 0xC551: 'wChLoopCount', 0xC559: 'wChLoopPtr', 0xC569: 'wChReturnPtr',
    0xC579: 'wChTranspose', 0xC581: 'wChAttenuation', 0xC589: 'wChDuty', 0xC591: 'wChSweep',
    0xC599: 'wChPeriod', 0xC5A9: 'wChNRx4', 0xC5B1: 'wChLastNote', 0xD611: 'wFastMusic',
    0xFFB2: 'hSoundQueueCount', 0xFFB3: 'hSoundQueue', 0xFFBD: 'hActiveChannels', 0xFFBE: 'hChannelsEnded',
    0xFFBF: 'hChMask', 0xFFC0: 'hCurCh', 0xFFC1: 'hCurCh2', 0xFFC2: 'hCurRegOffset', 0xFFC3: 'hStreamPtr',
    0xFFC5: 'hTemp', 0xFFAC: 'hCurBank',
}
WORD_ARRAYS = {0xC511, 0xC521, 0xC559, 0xC569, 0xC599}
EXT = {0x06DA: 'FillBytes', 0x0008: 'RST_CopyBytes', 0x0030: 'RST_Bankswitch'}

CMDS = {0xF0: ('envelope', 1), 0xF1: ('duty', 1), 0xF2: ('attenuate', 1), 0xF3: ('transpose', 1),
        0xF4: ('loop', 1), 0xF5: ('endloop', 0), 0xF6: ('snd_call', 2), 0xF7: ('snd_ret', 0),
        0xF8: ('sweep', 1), 0xF9: ('sweep_off', 0), 0xFA: ('transpose_up', 0), 0xFB: ('snd_jump', 2),
        0xFC: ('snd_nop', 0), 0xFD: ('play_sound', 1), 0xFE: ('snd_end_count', 0), 0xFF: ('snd_end', 0)}
NOTES = ['C_', 'C#', 'D_', 'D#', 'E_', 'F_', 'F#', 'G_', 'G#', 'A_', 'A#', 'B_']


class Gb2Music:
    def __init__(self, g):
        self.g = g
        self.todo = []
        self.kinds = {}
        self.reads = {}
        self.env_used = set()
        self.sounds_queued = set()
        self.cmd_count = {}

    def add(self, a, kind, ch):
        self.todo.append((a, kind, ch))

    def dec(self, a, ch):
        g = self.g
        c = g.b(a)
        noise = (ch & 3) == 3
        if c < 0x80:
            if c == 0x7C:
                return 1, 'rest', False, None
            if noise:
                return 1, 'drum %d' % c, False, None
            if (c & 15) < 12:
                return 1, 'note %s, %d' % (NOTES[c & 15], c >> 4), False, None
            return 1, 'db $%02X ; note %d+%d' % (c, c >> 4, c & 15), False, None
        if c < 0xC0:
            return 1, 'length %d' % (c & 0x3F), False, None
        if c < 0xF0:
            return None   # $C0-$EF would act as $F0-$FF (low nibble only), but the data never uses them
        name, n = CMDS[c]
        self.cmd_count[c] = self.cmd_count.get(c, 0) + 1
        if c in (0xF6, 0xFB):
            t = g.w(a + 1)
            return 3, Lazy(lambda name=name, t=t: '%s %s' % (name, g.sym(t))), c == 0xFB, t
        if n == 0:
            return 1, name, c in (0xF7, 0xFE, 0xFF), None
        v = g.b(a + 1)
        if c == 0xF0:
            self.env_used.add(v)
        if c == 0xFD:
            self.sounds_queued.add(v)
        if c == 0xF1:
            return 2, 'duty $%02X' % v, False, None
        if c == 0xF8:
            return 2, 'sweep $%02X' % v, False, None
        if c == 0xF3:
            return 2, 'transpose %d' % (v - 256 if v & 0x80 else v), False, None
        return 2, '%s %d' % (name, v), False, None

    def run(self):
        g = self.g
        while self.todo:
            a, kind, ch = self.todo.pop(0)
            if a in self.kinds:
                continue
            self.kinds[a] = kind
            while True:
                if a in g.owner:
                    if g.owner[a] != a:
                        g.errors.append('misaligned %04X' % a)
                    break
                r = self.dec(a, ch)
                if r is None:
                    g.errors.append('bad byte %02X at %04X' % (g.b(a), a))
                    g.item(a, 1, 'db $%02X' % g.b(a), 'INVALID')
                    break
                size, txt, stop, t = r
                for k in range(size):
                    self.reads[a + k] = 'main'
                if t is not None:
                    if t not in g.labels:
                        g.label(t, None, 'Sub' if g.b(a) == 0xF6 else 'Seq')
                    self.add(t, kind, ch)
                g.item(a, size, txt)
                if stop:
                    break
                a += size

    def envelope(self, a, end):
        """Envelopes have no terminator: a step of 255 frames is in practice the last one, and the data
        runs on into the next envelope. Each one is emitted up to the next envelope's start."""
        g = self.g
        while a < end:
            if a in g.owner:
                break
            d, v = g.b(a), g.b(a + 1)
            self.reads[a] = self.reads[a + 1] = 'env'
            g.item(a, 2, 'env_step %d, %d' % (d, v) if d != 0xFF else 'env_hold %d' % v)
            a += 2
        return a


def lz(g, fmt, *addrs):
    return Lazy(lambda: fmt % tuple(g.sym(a) for a in addrs))


def build(rom):
    g0 = AsmGen(rom, BANK, 0x07D4, 0x084D)
    g7 = AsmGen(rom, BANK, 0x4000, 0x8000)
    for g in (g0, g7):
        g.ram.update(RAM)
        g.ext.update(EXT)
    # bank 0
    g0.label(0x07D4, 'Sound_Request')
    g0.trace(0x07D4, 'Sound_Request')
    g0.label(0x07FA, 'Sound_Init')
    g0.trace(0x07FA, 'Sound_Init')
    g0.label(0x0813, 'Sound_InitRegs', override=True)
    g0.label(0x0829, 'InitialWave')
    g0.bytes_rows(0x0829, 16)
    g0.label(0x0839, 'InitialRegs')
    g0.data(0x0839, 20, comment='NR10-NR44 (rFF10-rFF23)')
    # bank 7 code
    g7.ext[0x07D4] = 'Sound_Request'
    names = {0x4000: 'Sound_StartQueued', 0x40B9: 'Sound_Update', 0x40C6: 'Sound_NextChannel', 0x40EA: 'Ch_EnvelopeStep',
             0x411B: 'Ch_ApplyEnvelope', 0x418F: 'Ch_ReadStream', 0x41AB: 'Ch_NextByte', 0x41B3: 'Ch_ReadByte',
             0x41E3: 'Ch_SetLength', 0x4215: 'Ch_Note', 0x4269: 'Ch_ToneNote', 0x4306: 'Ch_NoteDone',
             0x432F: 'Ch_Rest', 0x436B: 'Ch_WriteNRx4', 0x437F: 'CommandTable', 0x439F: 'Cmd_Nop',
             0x43A2: 'Ch_ReadArg', 0x43B3: 'Cmd_Envelope', 0x43D7: 'Cmd_Duty', 0x43F5: 'Cmd_Attenuate',
             0x4406: 'Cmd_Transpose', 0x4417: 'Cmd_Loop', 0x443C: 'Cmd_EndLoop', 0x4460: 'Cmd_Call',
             0x448D: 'Cmd_Ret', 0x44A4: 'Cmd_Sweep', 0x44B9: 'Cmd_SweepOff', 0x44C9: 'Cmd_TransposeUp',
             0x44D7: 'Cmd_Jump', 0x44E7: 'Cmd_PlaySound', 0x44F0: 'Cmd_EndCount', 0x44F4: 'Cmd_End',
             0x4545: 'Ch_RestoreMusic', 0x4593: 'Ch_RestoreEnvelope'}
    for a, n in names.items():
        g7.label(a, n)
    g7.trace(0x4000, 'Sound_StartQueued')
    g7.trace(0x40B9, 'Sound_Update')
    for i in range(16):
        t = g7.w(0x437F + 2 * i)
        g7.trace(t, names.get(t))
    for i in range(16):
        g7.item(0x437F + 2 * i, 2, lz(g7, 'dw %s', g7.w(0x437F + 2 * i)), 'command $F%X (and $C%X/$D%X/$E%X)' % (i, i, i, i))
    T = {0x45DC: ('ChannelBits', 8), 0x45E4: ('UnusedByte_45E4', 1), 0x45E5: ('OctaveTable', 8),
         0x45ED: ('RegOffsetTable', 8), 0x4685: ('NoiseTable', 15), 0x46F2: ('NumSounds', 1),
         0x46F3: ('LengthTable', 64)}
    for a, (n, s) in T.items():
        g7.label(a, n)
        if a == 0x46F3:
            for k in range(4):
                g7.data(a + 16 * k, 16, 'db ' + ', '.join('%3d' % g7.b(a + 16 * k + j) for j in range(16)),
                        'lengths %d-%d%s' % (16 * k, 16 * k + 15, ' (fast music: +16 for indices 0-31)' if k == 0 else ''))
        elif a == 0x46F2:
            g7.data(a, 1, 'db %d' % g7.b(a), 'number of sounds (read by the sound-test screen)')
        else:
            g7.bytes_rows(a, s)
    g7.label(0x45F5, 'PeriodTable')
    for i in range(72):
        a = 0x45F5 + 2 * i
        g7.item(a, 2, 'dw $%04X' % g7.w(a), ('C%d' % (2 + i // 12)) if i % 12 == 0 else None)
    # ---- data ----
    m = Gb2Music(g7)
    NS = (0x46F2 - 0x4694) // 2
    g7.label(0x4694, 'SoundTable')
    NE = (0x475B - 0x4733) // 2
    g7.label(0x4733, 'EnvelopeTable')
    for i in range(NE):
        g7.label(g7.w(0x4733 + 2 * i), 'Envelope%02d' % i)
    starts = sorted(set(g7.w(0x4733 + 2 * i) for i in range(NE)))
    for k, a in enumerate(starts):
        m.envelope(a, starts[k + 1] if k + 1 < len(starts) else g7.w(0x4694))
    headers = {}
    for i in range(NS):
        p = g7.w(0x4694 + 2 * i)
        if p in headers:
            continue
        headers[p] = i
        g7.label(p, 'Sound%02d' % i)
        a = p
        while g7.b(a) < 0x80:
            ch = g7.b(a)
            t = g7.w(a + 1)
            nm = 'Sound%02d_%s%d' % (i, 'M' if ch < 4 else 'S', (ch & 3) + 1)
            if t not in g7.labels:
                g7.label(t, nm)
            m.add(t, 'main', ch)
            g7.item(a, 3, lz(g7, 'channel %d, %%s' % ch, t))
            for k in range(3):
                m.reads[a + k] = 'hdr'
            a += 3
        term_shared = a in [g7.w(p + 3 * k + 1) for k in range((a - p) // 3)]
        if term_shared:
            g7.item(a, 1, 'snd_end', 'header terminator, also the stream of every channel above')
        else:
            g7.item(a, 1, 'end_header' if g7.b(a) == 0xFF else 'db $%02X' % g7.b(a))
        m.reads[a] = 'hdr'
    m.run()
    g7.label(0x48D9, 'Sound_SilenceStream', override=True)
    g7.block_comments[0x48C1] = ['; sound 0 is never started (id 0 = empty queue). Its header has no terminator of its own and',
                                 '; runs on into Sound46 (stop the music channels): together they cover channels 4-7 and 0-3.']
    g7.hints[0x401F] = 'cp LOW(hSoundQueueCount)'
    for i in range(NS):
        g7.item(0x4694 + 2 * i, 2, lz(g7, 'dw %s', g7.w(0x4694 + 2 * i)), 'sound %d%s' % (i, ' (unused: ids start at 1)' if i == 0 else ''))
    for i in range(NE):
        g7.item(0x4733 + 2 * i, 2, lz(g7, 'dw %s', g7.w(0x4733 + 2 * i)), 'envelope %d%s' % (i, '' if i in m.env_used else ' (not selected by any stream)'))
    data_end = max(a + it.size for a, it in g7.items.items())
    orphans = []
    for gs, ge in g7.gaps(0x48C1, data_end):
        a, out = gs, []
        while a < ge:
            r = m.dec(a, 0)
            if r is None or a + r[0] > ge:
                out = None
                break
            out.append((a, r))
            a += r[0]
        if out:
            for k, (a, (size, txt, stop, t)) in enumerate(out):
                g7.item(a, size, txt, 'unreferenced stream' if k == 0 else None)
            orphans.append('%04X-%04X' % (gs, ge - 1))
    g7.end = data_end
    info = dict(NS=NS, NE=NE, data_end=data_end, orphans=orphans, queued=sorted(m.sounds_queued), cmd_count={('%02X' % k): v for k, v in m.cmd_count.items()})
    # ram symbol for word arrays (index c*2)
    return g0, g7, m, info


EXTRA = {
    'Sound_Request': ['; Sound_Request (rst $20): a = sound id. Appends it to hSoundQueue (max 10) with interrupts',
                      '; disabled. The queue is consumed by Sound_StartQueued, one id per update.'],
    'Sound_Init': ['; Sound_Init: no channels active, master on, NR50/NR51, wave RAM, all channel registers,',
                   '; wChLastNote[0-7] = $7C (rest).'],
    'Sound_StartQueued': ['; Sound_StartQueued: pop the oldest queued id (id 0 = nothing) and start every channel in its',
                          '; header: [channel, pointer]... terminated by a byte with bit 7 set. Starting a channel',
                          '; resets its transpose and attenuation, sets NR10 = $08 and a wait of 1.'],
    'Sound_Update': ['; Sound_Update (bank 7, called by the game 0, 1 or 2 times per frame): for channels 0-7 with',
                     '; their hActiveChannels bit set: count the note wait down (0 -> read the stream), else count',
                     '; the envelope step down. Channels 0-3 are music, 4-7 SFX on the same hardware channels',
                     '; (channel & 3). hChMask bit 3 is set while the SFX twin of a music channel is active: the',
                     '; music channel keeps running but does not write the hardware. Ends in Sound_StartQueued.'],
    'Ch_ApplyEnvelope': ['; envelope step de: wChEnvWait = env[de], volume = env[de+1]; NRx2 = (volume - attenuation) << 4',
                         '; | 8 and NRx4 = wChNRx4 (retrigger). CH3 uses NR32 = $40 and clears the trigger bit.'],
    'Ch_SetLength': ['; $80-$BF: note length = LengthTable[n & $3F]; music channels add 16 to n < 32 while',
                     '; wFastMusic is set.'],
    'Ch_Note': ['; $00-$7B note (high nibble = octave via OctaveTable, low nibble = semitone, + transpose),',
                '; $7C rest. CH4: the byte indexes NoiseTable directly. Music channels remember the period in',
                '; wChPeriod for Ch_RestoreMusic.'],
    'Cmd_EndCount': ['; $FE: like $FF, and counts hChannelsEnded (never read by the game).'],
    'Cmd_End': ['; $FF: channel off. When an SFX channel ends while its music twin is active, the music',
                '; channel\'s sweep, duty, period and envelope are written back (Ch_RestoreMusic).'],
    'Cmd_PlaySound': ['; $FD n: queue sound n (Sound_Request) - used to chain sounds.'],
}


def ram_inc():
    lines = ['; Ghostbusters II sound RAM', '; per-channel arrays: 8 entries (channels 0-3 music, 4-7 SFX);',
             '; wChPtr, wChEnvPtr, wChLoopPtr, wChReturnPtr and wChPeriod are words indexed by channel*2', '']
    for a in sorted(RAM):
        lines.append('DEF %-20s EQU $%04X' % (RAM[a], a))
    lines.append('')
    lines.append('; game routines used by the sound code')
    for a in sorted(EXT):
        lines.append('DEF %-20s EQU $%04X' % (EXT[a], a))
    return '\n'.join(lines) + '\n'


MACROS = r'''; Ghostbusters II sound data macros

; header: channel 0-3 = music on NR1x-NR4x, 4-7 = SFX on the same hardware (channel & 3)
MACRO channel
	db \1
	dw \2
ENDM
MACRO end_header
	db $FF
ENDM

; notes: semitone constant, octave 0-7 (octave 0 = C2 in PeriodTable)
DEF C_ EQU 0
DEF C# EQU 1
DEF D_ EQU 2
DEF D# EQU 3
DEF E_ EQU 4
DEF F_ EQU 5
DEF F# EQU 6
DEF G_ EQU 7
DEF G# EQU 8
DEF A_ EQU 9
DEF A# EQU 10
DEF B_ EQU 11
MACRO note
	ASSERT (\2) < 8
	db ((\2) << 4) | (\1)
ENDM
MACRO drum          ; CH4: NoiseTable index
	db \1
ENDM
MACRO rest
	db $7C
ENDM
MACRO length        ; LengthTable index 0-63 (applies to the following notes)
	db $80 | (\1)
ENDM

MACRO envelope
	db $F0, \1
ENDM
MACRO duty          ; NRx1 value (OR $3F)
	db $F1, \1
ENDM
MACRO attenuate     ; subtracted from every envelope volume
	db $F2, \1
ENDM
MACRO transpose
	db $F3, \1
ENDM
MACRO loop          ; one level per channel
	db $F4, \1
ENDM
MACRO endloop
	db $F5
ENDM
MACRO snd_call      ; one level per channel
	db $F6
	dw \1
ENDM
MACRO snd_ret
	db $F7
ENDM
MACRO sweep         ; NR10 = n ^ 8 at every note (CH1)
	db $F8, \1
ENDM
MACRO sweep_off     ; NR10 = $08
	db $F9
ENDM
MACRO transpose_up
	db $FA
ENDM
MACRO snd_jump
	db $FB
	dw \1
ENDM
MACRO snd_nop
	db $FC
ENDM
MACRO play_sound    ; queue another sound id
	db $FD, \1
ENDM
MACRO snd_end_count ; end, counting hChannelsEnded
	db $FE
ENDM
MACRO snd_end
	db $FF
ENDM

; envelopes: (frames, volume) pairs; a step of $FF frames ends the envelope (holds 255 frames)
MACRO env_step
	db \1, \2
ENDM
MACRO env_hold
	db $FF, \1
ENDM
'''


def main():
    rom = open(sys.argv[1], 'rb').read()
    out = sys.argv[2]
    g0, g7, m, info = build(rom)
    for g in (g0, g7):
        if g.errors:
            print('\n'.join(g.errors[:30]))
    from halcommon import apply_comments
    apply_comments(g0, EXTRA)
    apply_comments(g7, EXTRA)
    print('data end %04X' % info['data_end'])
    print('gaps b0:', ['%04X-%04X' % x for x in g0.gaps()])
    print('gaps b7:', ['%04X-%04X' % x for x in g7.gaps(0x4000, info['data_end'])])
    write(os.path.join(out, P + '_Bank0.inc'), '; bank 0: request queue, init ($07D4-$084C)\n\n' + g0.emit())
    write(os.path.join(out, P + '_Driver.inc'), '; bank 7: driver code and tables ($4000-$48C0)\n\n' + g7.emit(0x4000, 0x48C1))
    write(os.path.join(out, P + '_Data.inc'), '; bank 7: sound headers and streams ($48C1-$%04X)\n\n' % (info['data_end'] - 1) + g7.emit(0x48C1, info['data_end']))
    write_build_check(out, P)
    write(os.path.join(out, P + '_Macros.inc'), MACROS)
    write(os.path.join(out, P + '_RAM.inc'), ram_inc() + '\n' + HW_INC)
    write(os.path.join(out, P + '_Sound.asm'),
          '; Ghostbusters II - HAL sound driver\n\nINCLUDE "%s_RAM.inc"\nINCLUDE "%s_Macros.inc"\n\n' % (P, P) +
          'SECTION "Sound Bank 0", ROM0[$07D4]\nINCLUDE "%s_Bank0.inc"\n\n' % P +
          'SECTION "Sound Driver", ROMX[$4000], BANK[7]\nINCLUDE "%s_Driver.inc"\nINCLUDE "%s_Data.inc"\n' % (P, P))
    json.dump({'reads': {('%04X' % k): v for k, v in m.reads.items()},
               'items': {('%04X' % a): [it.size, it.kind] for a, it in g7.items.items()}, 'info': info},
              open(os.path.join(out, 'model.json'), 'w'))
    print(info['cmd_count'], 'queued', info['queued'])


if __name__ == '__main__':
    main()
