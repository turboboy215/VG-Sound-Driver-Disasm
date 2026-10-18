"""Paperboy (GBC) sound data parser."""
import os
ROM = open(os.environ.get('PB_ROM', 'pb.gbc'), 'rb').read()   # set PB_ROM to the ROM path
MUSBANK = 0x3B
def off(bank, a): return a if a < 0x4000 else bank * 0x4000 + a - 0x4000
def w(o): return ROM[o] | ROM[o + 1] << 8
SONGTAB, NSONGS = 0x33D4, 17
SAMPTAB, NSAMP = 0x34E4, 14
def songs():
    out = []
    for i in range(NSONGS):
        o = SONGTAB + 16 * i
        out.append(dict(ch1=w(o), ch2=w(o + 2), ch4=w(o + 4), bank=ROM[o + 6]))
    return out
def tone_stream(a, bank=MUSBANK):
    ev = []
    while True:
        o = off(bank, a)
        if ROM[o] == 0xBB: ev.append(('end', a)); return ev, a + 1
        ev.append(('note', a, (ROM[o] << 8) | ROM[o + 1], ROM[o + 2])); a += 3
def noise_stream(a, bank=MUSBANK):
    ev = []
    while True:
        o = off(bank, a)
        if ROM[o] == 0xBB: ev.append(('end', a)); return ev, a + 1
        ev.append(('note', a, ROM[o], ROM[o + 1])); a += 2
def dur(ev): return sum((e[3] or 256) for e in ev if e[0] == 'note')
def samples():
    out = []
    for i in range(NSAMP):
        o = SAMPTAB + 8 * i
        out.append(dict(prio=ROM[o], pad=ROM[o + 1], start=w(o + 2), end=w(o + 4), bank=ROM[o + 6], pad2=ROM[o + 7]))
    return out
