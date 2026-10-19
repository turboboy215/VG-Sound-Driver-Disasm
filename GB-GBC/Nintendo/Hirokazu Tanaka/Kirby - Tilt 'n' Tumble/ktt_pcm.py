"""PCM sample player of Kirby Tilt 'n' Tumble (home bank) and a WAV exporter for its samples.

The game plays 3-bit samples through the master volume: ch3 outputs a constant level (wave RAM all
$FF, NR32 = 100%, period $7DB) while a timer interrupt writes each sample to both halves of NR50.
Each byte holds two samples, bits 6-4 then bits 2-0 (bits 7 and 3 are never set). The timer runs
from the 16384 Hz clock (TAC = 7) with the CPU in double speed, so 32768 Hz: TMA $FC gives 8192
samples a second (samples 0-5), TMA $FB 6553.6 (samples 6-7).

The interrupt vector ($0050) jumps to a 6-byte trampoline in HRAM ($FFE5): `ld hl, <next byte>`,
`jp PcmIrq_High` / `jp PcmIrq_Low`; the handlers rewrite the jump target and the pointer, so no
register or RAM has to hold the play position between interrupts. Sound driver updates are
skipped while a sample plays (hPcmState = 1); when it ends the driver is told through wPcmDone."""
import os, sys, struct, wave
HERE = os.path.dirname(os.path.abspath(__file__))
for p in ('', '../tools'):
    sys.path.insert(0, os.path.join(HERE, p))
from gbdis import Region

HRAM = {0xffa1: 'hRomBank', 0xffe5: 'hPcmTrampoline', 0xffe6: 'hPcmPointer', 0xffe7: 'hPcmPointer+1', 0xffe9: 'hPcmHandler',
        0xffeb: 'hPcmBank', 0xffec: 'hPcmEnd', 0xffed: 'hPcmEnd+1', 0xffee: 'hPcmState', 0xde8b: 'wPcmDone'}
START_TABLE, END_TABLE, COUNT = 0x0dac, 0x0dc4, 8
RATE_FAST, RATE_SLOW = 32768 / 4, 32768 / 5


def samples(rom):
    out = []
    for i in range(COUNT):
        a = rom[START_TABLE + 3*i] | rom[START_TABLE + 3*i + 1] << 8
        bank = rom[START_TABLE + 3*i + 2]
        end = rom[END_TABLE + 3*i] | rom[END_TABLE + 3*i + 1] << 8
        out.append(dict(index=i, request=3*i, bank=bank, start=a, end=end, rate=RATE_SLOW if 3*i >= 0x12 else RATE_FAST))
    return out


def decode_sample(rom, s):
    """3-bit levels, in play order; the byte at the end address is played too (the end test is
    `hl > end` after the increment)"""
    off = s['bank'] * 0x4000 + s['start'] - 0x4000
    data = rom[off:off + s['end'] - s['start'] + 1]
    lv = []
    for b in data:
        lv.append((b >> 4) & 7); lv.append(b & 7)
    return lv


def export_wavs(rom, outdir):
    os.makedirs(outdir, exist_ok=True)
    rows = []
    for s in samples(rom):
        lv = decode_sample(rom, s)
        name = f'ktt_pcm{s["index"]}_{s["bank"]:02X}_{s["start"]:04X}.wav'
        with wave.open(os.path.join(outdir, name), 'wb') as w:
            w.setnchannels(1); w.setsampwidth(1); w.setframerate(int(round(s['rate'])))
            w.writeframes(bytes(round(v * 255 / 7) for v in lv))
        rows.append((s, name, len(lv) / s['rate']))
    return rows


def gen_home(rom):
    """byte-exact source of the PCM routines in the home bank"""
    parts = []
    r = Region(rom, 0, 0x0050, 0x0055); r.ram = dict(HRAM)
    r.trace([0x0050])
    r.label(0x0050, 'TimerVector'); r.comments[0x0050] = 'Timer interrupt: continue in the HRAM trampoline.'
    r.extern = {0xffe5: 'hPcmTrampoline'}
    parts.append(('$0050', 'Timer vector', r.emit()))
    r = Region(rom, 0, 0x0353, 0x03bd); r.ram = dict(HRAM)
    r.trace([0x0356, 0x0370])
    names = {0x0353: 'Unknown_0353', 0x0356: 'PcmIrq_High', 0x0370: 'PcmIrq_Low', 0x0389: 'PcmIrq_Low.sameHigh',
             0x038e: 'PcmIrq_Low.end', 0x03ab: 'PcmIrq_Low.next'}
    for a, n in names.items(): r.label(a, n)
    r.comments.update({
     0x0353: 'not part of the player (3 bytes before it)',
     0x0356: 'First sample of the byte (bits 6-4) to both halves of NR50, then point the trampoline at\nPcmIrq_Low. The sample bank is mapped for the read and hRomBank restored afterwards.',
     0x0370: 'Second sample (bits 2-0), next byte. Past hPcmEnd: hPcmState = 2, timer interrupt off,\nwPcmDone = 1 (WRAM bank 7) for the sound driver, NR50 = $77.',
     0x03ab: 'Save the pointer in the trampoline\'s `ld hl` and point it back at PcmIrq_High.',
    })
    r.block(0x0353, 3, lambda rr, a: ['\tdb $01, $02, $04'])
    r.overrides[0x0364] = {0: 'LOW(PcmIrq_Low)'}; r.overrides[0x03b1] = {0: 'LOW(PcmIrq_High)'}
    r.extern = {0x2100: '$2100'}
    parts.append(('$0353', 'PCM timer interrupt handlers', r.emit()))
    r = Region(rom, 0, 0x0dac, 0x0e61); r.ram = dict(HRAM)
    r.trace([0x0ddc])
    r.label(0x0dac, 'PcmStartTable'); r.label(0x0dc4, 'PcmEndTable'); r.label(0x0ddc, 'PlayPcm')
    r.label(0x0e1f, 'PlayPcm.wave'); r.label(0x0e58, 'PlayPcm.rate')
    r.extern = {0x0356: 'PcmIrq_High'}
    r.overrides.update({0x0dfb: {0: '$21'}, 0x0e02: {0: '$c3'}, 0x0e05: {0: 'LOW(PcmIrq_High)'}, 0x0e08: {0: 'HIGH(PcmIrq_High)'}})
    r.eol.update({0x0dfb: 'ld hl, start', 0x0e02: 'jp PcmIrq_High'})
    r.comments.update({
     0x0dac: 'sample n at index 3n: address, bank',
     0x0dc4: 'last byte of sample n (played too), bank (not read)',
     0x0ddc: 'a = 3 * sample number. Ignored while hPcmState is non-zero. Builds the trampoline\n(`ld hl, start` / `jp PcmIrq_High`), mutes ch1 / ch2 / ch4 (not for sample 0), fills wave\nRAM with $FF and starts ch3 at full level, period $7DB. hPcmState = 1: the main loop\nenables the timer interrupt and stops calling the sound driver. Timer: 32768 Hz (TAC = 7,\ndouble speed) / 4 = 8192 Hz, or / 5 = 6553.6 Hz for samples 6 and 7.',
    })
    def tab(rr, a):
        out = []
        for i in range(COUNT):
            q = a + 3*i
            out.append(f'\tdw ${rr.word(q):04x}\n\tdb ${rr.byte(q+2):02x}\t; sample {i}')
        return out
    r.block(0x0dac, 24, tab); r.block(0x0dc4, 24, tab)
    parts.append(('$0DAC', 'PCM sample tables and player', r.emit()))
    body = "; Kirby Tilt 'n' Tumble: PCM sample player (home bank)\nINCLUDE \"GB_Hardware.inc\"\n\n"
    body += ''.join(f'DEF {n:<16} EQU ${a:04X}\n' for a, n in sorted(HRAM.items()) if '+' not in n) + '\n'
    for addr, what, text in parts:
        body += f'SECTION "KTT {what}", ROM0[{addr}]\n' + text + '\n'
    return body
