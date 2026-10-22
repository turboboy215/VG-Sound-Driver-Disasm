"""FFL1 (SaGa 1) music stream model. Bank 7."""
import sys, os
ROMF = os.environ.get('FFL1_ROM', 'Final Fantasy Legend, The (U) [!].gb')
if not os.path.exists(ROMF): ROMF = 'ffl1.gb'
r = open(ROMF, 'rb').read()
B = 7 * 0x4000
def rb(a): return r[B + a - 0x4000]
def rw(a): return rb(a) | rb(a + 1) << 8
NSONG = 18
LEN = [rb(0x4403 + i) for i in range(16)]       # index 15 reads the first byte of NoteFreqTable ($2C)
NOTE = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B', 'rest', 'tie', '?E', '?F']
CHN = ['CH1', 'CH2', 'CH3']
def songs(): return [[rw(0x462F + 6 * i + 2 * c) for c in range(3)] for i in range(NSONG)]
def size(b):
    if b < 0xE0: return 1
    if b == 0xE0: return 2
    if b < 0xF0: return 1
    c = b & 15
    return {0: 1, 1: 1, 2: 1, 3: 1, 4: 1, 5: 2, 6: None, 7: 2, 8: 2, 9: 1, 10: 1, 11: 1, 12: 3, 13: 3, 14: 3, 15: 1}[c]
def decode(a):
    b = rb(a); n = size(b)
    if b < 0xE0: return n, 'note', '%s len=%d' % (NOTE[b >> 4], LEN[b & 15])
    if b == 0xE0: return n, 'TEMPO', '%d' % rb(a + 1)
    if b < 0xF0: return n, 'VOL', '%d' % (b & 15)
    c = b & 15
    if c <= 4: return n, 'OCT', '%d' % c
    nm = {5: 'NR11', 6: 'CRASH', 7: 'INSTR', 8: 'WAVE', 9: 'LOOP1', 10: 'LOOP2', 11: 'LOOP3', 12: 'LOOPJMP', 13: 'IFDONE', 14: 'JUMP', 15: 'END'}[c]
    if c == 7:
        v = rb(a + 1); return n, nm, '%s %d' % (['vol', 'pitch', 'duty', 'pan'][v >> 6], v & 63)
    if n == 3: return n, nm, '%04X' % rw(a + 1)
    if n == 2: return n, nm, '%02X' % rb(a + 1)
    return n, nm, ''
def static_cover(start):
    seen = {}; todo = [start]
    while todo:
        a = todo.pop()
        while a not in seen:
            b = rb(a); n = size(b)
            if n is None: seen[a] = 1; break
            for i in range(n): seen[a + i] = i + 1
            c = b & 15
            if b >= 0xF0 and c == 14: a = rw(a + 1); continue
            if b >= 0xF0 and c in (12, 13): todo.append(rw(a + 1))
            if b == 0xFF: break
            a += n
    return seen
def play(start, maxticks=100000, maxev=500000):
    """yield (t, addr, kind, byte) in stream order; t = cumulative length (ticks)."""
    a = start; cnt = 0; t = 0; ev = 0
    while t < maxticks and ev < maxev:
        ev += 1
        b = rb(a); n = size(b)
        if b < 0xE0:
            yield (t, a, 'note', b)
            if b != 0x0F: t += LEN[b & 15]
            a += 1; continue
        if n is None: yield (t, a, 'crash', b); return
        c = b & 15
        if b == 0xE0: yield (t, a, 'tempo', rb(a + 1)); a += 2; continue
        if b == 0xFF: yield (t, a, 'end', b); return
        if b >= 0xF0:
            if 9 <= c <= 11: cnt = c - 8
            elif c == 12:
                if cnt == 0: a += 3; continue
                cnt -= 1; a = rw(a + 1); continue
            elif c == 13:
                if cnt != 0: a += 3; continue
                a = rw(a + 1); continue
            elif c == 14: a = rw(a + 1); continue
        a += n
    yield (t, a, 'limit', None)
