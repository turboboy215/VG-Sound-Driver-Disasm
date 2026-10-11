"""Data model for the Pokemon Puzzle Challenge music format."""
import struct

ROM = None


def load(path):
    global ROM
    ROM = open(path, 'rb').read()
    return ROM


def rb(bank, a):
    return ROM[bank * 0x4000 + a - 0x4000] if a >= 0x4000 else ROM[a]


def rw(bank, a):
    return rb(bank, a) | rb(bank, a + 1) << 8


SONG_TABLE = 0x590E
NUM_SONGS = 0x61

# arg byte counts of commands $D2-$FF
CMD_ARGS = {0xD2: 0, 0xD3: 0, 0xD4: 1, 0xD5: 0, 0xD6: 1, 0xD7: 1, 0xD8: 1, 0xD9: 0, 0xDA: 1,
            0xDB: 0, 0xDC: 0, 0xDD: 0, 0xDE: 0, 0xDF: 0, 0xE0: 0, 0xE1: 0, 0xE2: 1, 0xE3: 1,
            0xE4: 1, 0xE5: 1, 0xE6: 1, 0xE7: 2, 0xE8: 3, 0xE9: 3, 0xEA: 3, 0xEB: 3, 0xEC: 2,
            0xED: 0, 0xFE: 0, 0xFF: 4}
for c in range(0xEE, 0xFE):
    CMD_ARGS[c] = 0


def song_table():
    out = []
    for i in range(NUM_SONGS):
        a = SONG_TABLE + 3 * i
        out.append((i, rb(0x20, a + 2), rw(0x20, a)))
    return out


def parse_track(bank, start, hits):
    """Walk a channel track, following jumps/calls/loops. hits: dict addr->(len,kind).
    Returns list of problems."""
    work = [start]
    probs = []
    while work:
        pc = work.pop()
        while True:
            if pc in hits:
                break
            b = rb(bank, pc)
            if b == 0:
                hits[pc] = (1, 'end')
                break
            if b < 0xD2:
                hits[pc] = (1, 'ev')
                pc += 1
                continue
            n = CMD_ARGS[b]
            hits[pc] = (1 + n, 'cmd')
            if b == 0xE7:
                work.append(rw(bank, pc + 1))
                break
            if 0xE8 <= b <= 0xEB:
                work.append(rw(bank, pc + 2))
                pc += 4  # engine skips count+3 on exit
                # mark the skipped byte separately
                continue
            if b == 0xEC:
                work.append(rw(bank, pc + 1))
                pc += 3
                continue
            if b == 0xED:
                break
            pc += 1 + n
    return probs


# ---------------- SFX engine A (bank $21) ----------------
SFXA_BANK = 0x21
SFXA_MULTI = 0x4925
SFXA_MULTI_N = 47
SFXA_TABLES = [(0x60A4, 64), (0x6EE5, 16), (0x6F28, 8), (0x7106, 24)]
# per channel: cmd byte -> (name, nargs)
_common = {0xE0: ('call', 2), 0xE1: ('ret', 0), 0xE2: ('loop', 1), 0xE3: ('endloop', 0),
           0xE4: ('pan_l', 0), 0xE5: ('pan_r', 0), 0xE6: ('pan_c', 0)}
SFXA_CMDS = [
    {**_common, **{0xE7: ('slide', 2), 0xF0: ('duty0', 0), 0xF1: ('duty1', 0), 0xF2: ('duty2', 0), 0xF3: ('duty3', 0),
                     0xF4: ('length', 1), 0xF5: ('length_off', 0), 0xF6: ('env', 1), 0xF7: ('trigger', 0),
                     0xF8: ('off', 0), 0xF9: ('transpose', 1), 0xFA: ('sweep', 1), 0xFB: ('fine', 1)}},
    {**_common, **{0xE7: ('slide', 2), 0xF0: ('duty0', 0), 0xF1: ('duty1', 0), 0xF2: ('duty2', 0), 0xF3: ('duty3', 0),
                     0xF4: ('length', 1), 0xF5: ('length_off', 0), 0xF6: ('env', 1), 0xF7: ('trigger', 0),
                     0xF8: ('off', 0), 0xF9: ('transpose', 1), 0xFA: ('fine', 1)}},
    {**_common, **{0xE7: ('slide', 2), 0xF0: ('wave', 1), 0xF1: ('length', 1), 0xF2: ('length_off', 0),
                     0xF3: ('level', 1), 0xF4: ('trigger', 0), 0xF5: ('off', 0), 0xF6: ('transpose', 1),
                     0xF7: ('fine', 1)}},
    {**_common, **{0xF0: ('lfsr15', 0), 0xF1: ('lfsr7', 0), 0xF2: ('length', 1), 0xF3: ('length_off', 0),
                     0xF4: ('env', 1), 0xF5: ('trigger', 0), 0xF6: ('off', 0), 0xF7: ('transpose', 1)}},
]


def sfxa_ptr(p):
    """raw table word -> (addr or None, priority)"""
    return (((p & 0x3FFF) | 0x4000) if p & 0x3FFF else None), p >> 14


def parse_sfxa(ch, start, hits, bank=SFXA_BANK, limit=None):
    cmds = SFXA_CMDS[ch]
    work = [start]
    bad = []
    while work:
        pc = work.pop()
        while True:
            if pc in hits or (limit is not None and pc >= limit):
                break
            b = rb(bank, pc)
            if b == 0 or 0xD2 <= b < 0xE0:
                hits[pc] = (1, 'end', ch)
                break
            if b < 0xE0:
                hits[pc] = (1, 'ev', ch)
                pc += 1
                continue
            if b not in cmds:
                bad.append(pc)
                hits[pc] = (1, 'bad', ch)
                break
            name, n = cmds[b]
            hits[pc] = (1 + n, 'cmd', ch)
            if name == 'call':
                work.append(rw(bank, pc + 1))
            if name == 'ret':
                break
            pc += 1 + n
    return bad


# ---------------- SFX engine B (bank $7F) ----------------
SFXB_BANK = 0x7F
SFXB_TABLE = 0x4000


def sfxb_count():
    # table of words until first pointed header
    a = SFXB_TABLE
    mn = 0x8000
    n = 0
    while a < mn:
        p = rw(SFXB_BANK, a)
        if p:
            mn = min(mn, p)
        a += 2
        n += 1
    return n


def parse_sfxb(ch, start, hits, bank=SFXB_BANK):
    """ch: 0=ch1 (4-byte rows), 1=ch2 (3-byte rows: len,NR22,NR23? ...), 2=ch4 (3-byte rows)"""
    rowlen = {0: 4, 1: 4, 2: 3}[ch]
    pc = start
    while True:
        if pc in hits:
            return
        b = rb(bank, pc)
        if b == 0xFF:
            hits[pc] = (1, 'end', ch)
            return
        if b in (0xFE, 0xFD):
            hits[pc] = (2, 'cmd', ch)
            pc += 2
            continue
        hits[pc] = (rowlen, 'row', ch)
        pc += rowlen


# ---------------- bank $20 instrument data ----------------
ENV_TABLE = 0x6230
ENV_N = 308
WAVE_TABLE = 0x6F71
WAVE_N = 73
PM_TABLE = 0x7401
PM_N = 62
DRUM_TABLE = 0x5A31
DRUM_N = 30


def parse_env(start, hits, bank=0x20):
    pc = start
    while pc not in hits:
        b = rb(bank, pc)
        if b == 0:
            hits[pc] = (1, 'end')
            return
        hits[pc] = (1, 'vol')
        pc += 1
        while rb(bank, pc) & 0x80:
            hits[pc] = (1, 'len')
            pc += 1
        hits[pc] = (1, 'wait')
        pc += 1


def parse_pm(start, hits, bank=0x20):
    work = [start]
    while work:
        pc = work.pop()
        while pc not in hits:
            b = rb(bank, pc)
            if b == 0:
                hits[pc] = (1, 'end')
                break
            if b == 0x64:
                hits[pc] = (3, 'jump')
                work.append(rw(bank, pc + 1))
                break
            hits[pc] = (1, 'step' if b < 0x64 else 'delta')
            pc += 1
