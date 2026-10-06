"""ColinMcRae_PCMIrq.asm: the home-bank timer interrupt that streams PCM into wave RAM."""
import os
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sm83 import decode
from trace import trace
from qtgen import HW
from qtcfg import GAMES, DIR
out = sys.argv[1]
rom = open(DIR + GAMES['cmr']['file'], 'rb').read()
m = rom[:0x8000]
code, labels = trace(m, [0x0050, 0x0238], 0, 0x4000)
ram = {0xC000: 'wRomBank', 0xC167: 'pcmcount', 0xC168: 'pcmcount+1', 0xC169: 'pcmactive', 0xC16A: 'pcmbank',
       0xC16B: 'pcmadr', 0xC16C: 'pcmadr+1', 0xC16E: 'pcmprio', 0x2000: 'rROMB0'}
L = ['; Colin McRae Rally (E) - timer interrupt that plays the QuickThunder PCM channel',
     '; ROM0 $0050 (vector) and $0238-$02DF. Each interrupt copies 16 bytes (32 4-bit samples)',
     '; into wave RAM and restarts channel 3 at NR33/NR34 = $00/$87 (period $700 -> 8192 Hz).',
     '; The timer runs at 4096 Hz / 32 (TMA = $E0); the game runs in double speed, so 256 Hz,',
     '; which is exactly 32 samples x 256 = 8192 samples per second.',
     'INCLUDE "QT_Macros.inc"', 'DEF wRomBank EQU $C000', 'DEF rROMB0 EQU $2000',
     'DEF pcmcount EQU $C167', 'DEF pcmactive EQU $C169', 'DEF pcmbank EQU $C16A', 'DEF pcmadr EQU $C16B',
     'DEF pcmprio EQU $C16E', 'DEF rSTAT EQU $FF41', '']
HW2 = dict(HW); HW2[0xFF41] = 'rSTAT'
for lo, hi, nm in ((0x0050, 0x0053, 'TimerVector'), (0x0238, 0x02E0, 'PcmTimerIrq')):
    L.append('SECTION "%s", ROM0[$%04X]' % (nm, lo))
    L.append('%s::' % nm)
    a = lo
    while a < hi:
        if a in labels and a != lo:
            L.append('.l%04X' % a)
        n, mm, o = decode(m, a)
        if o:
            k, v = o
            if k in ('rel', 'addr16') and (mm.startswith('j') or mm.startswith('call')):
                s = mm.format('PcmTimerIrq' if v == 0x238 else '.l%04X' % v)
            elif k == 'ldh':
                s = mm.format(HW2.get(v, '$%04X' % v))
            elif k in ('addr16', 'imm16'):
                s = mm.format(ram.get(v, HW2.get(v, '$%04X' % v)))
            else:
                s = mm.format('$%02X' % v)
        else:
            s = mm
        L.append('    ' + s)
        a += n
    L.append('')
open(out + '/ColinMcRae_PCMIrq.asm', 'w').write('\n'.join(L) + '\n')
