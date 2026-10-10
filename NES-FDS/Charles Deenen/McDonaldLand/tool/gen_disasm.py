#!/usr/bin/env python3
"""Generate a ca65 disassembly of the McDonaldLand (E) / M.C. Kids sound engine
(Charles Deenen).  Bank 10 ($8000 window: code + tables + data) and the music
data half that lives in bank 4 ($A000 window).

usage: python gen_disasm.py "McDonaldLand (E) [!].nes" outdir
"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from m6502 import trace, OPS, SIZE

rom = open(sys.argv[1], 'rb').read()
OUT = sys.argv[2] if len(sys.argv) > 2 else '.'
PRG = rom[16:16 + 0x20000]
B10 = PRG[10 * 0x2000:11 * 0x2000]
B04 = PRG[4 * 0x2000:5 * 0x2000]
MEM = B10 + B04                    # $8000-$BFFF as seen by the driver
B = 0x8000
END10 = 0x9C37                     # end of sound data in bank 10 (game data follows)
END04 = 0xB41D                     # end of sound data in bank 4

def r(a): return MEM[a - B]
def w(a): return r(a) | r(a + 1) << 8

# ---------------------------------------------------------------- constants
NSONG, NSFX, NTRACK, NPAT = 14, 26, 81, 132
NMPENV, NVENV, NDENV, NSINS, NSPENV, NINS = 33, 15, 11, 22, 16, 32
NOTES = ['C', 'Cs', 'D', 'Ds', 'E', 'F', 'Fs', 'G', 'Gs', 'A', 'As', 'B']
def note(n): return '%s%d' % (NOTES[n % 12], n // 12 + 2)

# ---------------------------------------------------------------- RAM map
RAM = [  # (addr, name, size, comment)
    (0x00A7, 'zSongTmp', 1, 'song number being started'),
    (0x00A8, 'zDmcFlag', 1, 'vestigial: read by Sound_Update, never set'),
    (0x00A9, 'chActive', 5, '$F0 = running (bit 7), 0 = stopped'),
    (0x00AE, 'zPtr', 2, 'pattern / envelope pointer, also temp'),
    (0x00B0, 'zTmp', 1, 'scratch (track number in Chan_Start)'),
    (0x00B1, 'zTmpX', 1, 'written, never read'),
    (0x00B2, 'zTrkPtr', 2, 'current track pointer'),
    (0x00B4, 'zPEnvPtr', 2, 'current pitch-envelope pointer'),
    (0x00B6, 'zChan', 1, 'channel being updated'),
    (0x00B7, 'chTrackOfs', 5, 'track number * 3'),
    (0x00BC, 'chPerHiWork', 5, 'period high byte (vibrato working copy)'),
    (0x00C1, 'chLegato', 5, 'nonzero = $FE legato prefix on current note'),
    (0x00C6, 'chNote', 5, 'current note (transposed)'),
    (0x00CB, 'chFrame', 5, 'frames since note start'),
    (0x00D0, 'chTickCnt', 5, 'frames until next tick'),
    (0x00D5, 'chSwingCnt', 5, 'fractional-speed counter'),
    (0x00DA, 'chRegOfs', 5, 'APU register offset (0,4,8,12; SFX = hw*4)'),
    (0x00DF, 'zSfxHwCh', 1, 'hardware channel taken by the SFX, 4 = none'),
    (0x00E0, 'zSfxTrack', 1, 'written, never read'),
    (0x00E7, 'chPEnvSel', 5, 'bit7: use instrument pitch env; else env# (0 = none)'),
    (0x00EC, 'chPEnvLoop', 5, 'pitch envelope loop point'),
    (0x00F1, 'chPEnvPos', 5, 'pitch envelope position'),
    (0x00F6, 'chDuty', 5, 'reg0 duty bits (instrument byte 0 / duty env)'),
    (0x07A0, 'chVibCnt', 5, ''),
    (0x07A5, 'chVibDir', 5, '0 = period down (pitch up), 1 = period up'),
    (0x07AA, 'chVibPhase', 5, 'initial quarter-cycle counter'),
    (0x07AF, 'chVibUnused', 5, 'cleared, never read ($07B2 also = DMC vestige)'),
    (0x07B4, 'chVibParam', 5, 'instrument byte 4'),
    (0x07B9, 'chNoteStart', 5, '1 = first frame of note (vibrato reset)'),
    (0x07BE, 'zVibDelay', 1, ''),
    (0x07BF, 'chVEnvLoop', 5, 'volume env loop point ($07C1 = zSlideLo temp)'),
    (0x07C4, 'chVEnvPos', 5, 'volume env position ($07C6 = zSlideHi temp)'),
    (0x7F4C, 'chDEnvLoop', 5, 'duty env loop point'),
    (0x7F51, 'chDEnvPos', 5, 'duty env position'),
    (0x7F56, 'chSlideDelay', 5, ''),
    (0x7F5B, 'chSlideTarget', 5, 'target note, 0 = no slide'),
    (0x7F60, 'chSlideSpeed', 5, ''),
    (0x7F65, 'chSliding', 5, ''),
    (0x7F6A, 'chSpeedLo', 5, 'track speed low nibble'),
    (0x7F6F, 'chSpeedHi', 5, 'track speed high nibble'),
    (0x7F74, 'chPEnvForce', 5, 'nonzero = PENV command on this note'),
    (0x7F79, 'chDuration', 5, 'note length - 1 (ticks)'),
    (0x7F7E, 'chTicksLeft', 5, ''),
    (0x7F83, 'chPatPos', 5, ''),
    (0x7F88, 'chTrackPos', 5, ''),
    (0x7F8D, 'chTranspose', 5, ''),
    (0x7F92, 'chInstr', 5, ''),
    (0x7F97, 'chInstrOfs', 5, 'instrument * 6'),
    (0x7F9C, 'chResting', 5, ''),
    (0x7FA1, 'chLastPerHi', 5, 'last value written to $4003 (write cache)'),
    (0x7FA6, 'chReg0', 5, 'reg0 shadow ($7FA8 = triangle $4008)'),
    (0x7FAB, 'chReg1', 5, 'sweep shadow: never written, always 0'),
    (0x7FB0, 'chPerLo', 5, ''),
    (0x7FB5, 'chPerHi', 5, ''),
    (0x7FBA, 'chVolRow', 5, 'VOL command << 4 (row of VolTable)'),
]
EXTRA_RAM = {0x07C1: 'zSlideLo', 0x07C6: 'zSlideHi', 0x07B2: 'zDmcVestige'}
HW = {0x4000: 'SQ1_VOL', 0x4001: 'SQ1_SWEEP', 0x4002: 'SQ1_LO', 0x4003: 'SQ1_HI',
      0x4004: 'SQ2_VOL', 0x4008: 'TRI_LINEAR', 0x400C: 'NOISE_VOL',
      0x4010: 'DMC_FREQ', 0x4015: 'SND_CHN', 0xA001: 'MMC3_PRG_RAM'}

# ---------------------------------------------------------------- data symbols
DSYM = {}   # addr -> label   (for tables, used for operand naming)
def dsym(a, n): DSYM[a] = n
for a, n in [(0x8000, 'SfxTrackTbl'), (0x801A, 'SfxHwChTbl'), (0x8034, 'SongTbl_Sq1'),
             (0x8042, 'SongTbl_Sq2'), (0x8050, 'SongTbl_Tri'), (0x805E, 'SongTbl_Noise'),
             (0x806C, 'SongTbl_Dmc'), (0x8710, 'DmcSampleTbl'), (0x872C, 'PeriodLo'),
             (0x8771, 'PeriodHi'), (0x87A1, 'VolTable'), (0x88A1, 'PatPtrLo'),
             (0x8925, 'PatPtrHi'), (0x89A9, 'DmcPatPtr'), (0x89C5, 'DmcTrackTbl'),
             (0x89D5, 'TrackTbl'), (0x8AC8, 'PEnvPtrLo'), (0x8AE9, 'PEnvPtrHi'),
             (0x8C10, 'VolEnvOfs'), (0x8C1F, 'VolEnvData'), (0x8D4E, 'DutyEnvOfs'),
             (0x8D59, 'DutyEnvData'), (0x8DF9, 'SfxInstrTbl'), (0x8E7D, 'SfxPEnvPtrLo'),
             (0x8E8D, 'SfxPEnvPtrHi'), (0x901E, 'InstrTbl')]:
    dsym(a, n)

# ---------------------------------------------------------------- code
ENTRIES = {0x807A: 'Music_Play', 0x80C8: 'Sound_Init', 0x81A5: 'Sfx_Play', 0x8237: 'Sound_Update'}
CODE = trace(B10, B, list(ENTRIES) + [0x83DC])   # $83DC-$83E9 is unreachable code
CLAB = dict(ENTRIES)
CLAB.update({
    0x811E: 'Chan_Stop', 0x8145: 'Chan_StopTri', 0x814E: 'Chan_Start', 0x819F: 'Chan_StartDmc',
    0x81A0: 'Sfx_Cancel', 0x8225: 'Sfx_Begin', 0x823E: 'Upd_ChanLoop', 0x8247: 'Upd_Active',
    0x8262: 'Upd_Tick', 0x826A: 'Upd_NextEvent', 0x8276: 'Trk_Read', 0x8279: 'Trk_ReadY',
    0x8293: 'Trk_End', 0x8296: 'Trk_Transpose', 0x82A1: 'Pat_Start', 0x82BF: 'Pat_Cmd',
    0x82C3: 'Pat_Slide', 0x82DD: 'Pat_NotSlide', 0x82E6: 'Pat_ChkEnd', 0x82F5: 'Pat_ChkVol',
    0x8306: 'Pat_ChkRest', 0x8322: 'Pat_RestTri', 0x8327: 'Pat_RestDone', 0x8334: 'Pat_ChkIns',
    0x8342: 'Pat_ChkDur', 0x8355: 'Pat_ChkPEnv', 0x8365: 'Pat_NoPEnv', 0x836A: 'Pat_Note',
    0x8391: 'Note_SetInstr', 0x83AF: 'Note_SfxDuty', 0x83B2: 'Note_SetDuty', 0x83BA: 'Note_Tri',
    0x83BF: 'Note_SetPeriod', 0x83D4: 'Upd_Sustain', 0x83EA: 'Slide_Check', 0x83EF: 'Slide_None',
    0x83F2: 'Slide_Delay', 0x841B: 'Slide_Shift', 0x8425: 'Slide_Go', 0x844F: 'Slide_Arrive',
    0x846B: 'Slide_Up', 0x848E: 'VEnv_Run', 0x8496: 'VEnv_Get', 0x84A3: 'VEnv_GetSfx',
    0x84A6: 'VEnv_Have', 0x84B4: 'VEnv_SetPos', 0x84B7: 'VEnv_Read', 0x84CB: 'VEnv_ChkHold',
    0x84D8: 'VEnv_Value', 0x84EC: 'DEnv_Run', 0x84FA: 'DEnv_Get', 0x8507: 'DEnv_GetSfx',
    0x850A: 'DEnv_Have', 0x8518: 'DEnv_SetPos', 0x851B: 'DEnv_Read', 0x852F: 'DEnv_ChkHold',
    0x853C: 'DEnv_Value', 0x854B: 'PEnv_Run', 0x855C: 'PEnv_GetSfx', 0x855F: 'PEnv_Have',
    0x8574: 'PEnv_SfxPtr', 0x857E: 'PEnv_ChkReset', 0x858B: 'PEnv_Reset', 0x858F: 'PEnv_SetPos',
    0x8591: 'PEnv_Read', 0x85A2: 'PEnv_ChkHold', 0x85AD: 'PEnv_Value', 0x85B4: 'PEnv_Abs',
    0x85B6: 'PEnv_Apply', 0x85D0: 'Vib_Run', 0x85DE: 'Vib_Get', 0x85EB: 'Vib_GetSfx',
    0x85EE: 'Vib_Have', 0x85F3: 'Vib_None', 0x85F6: 'Vib_Active', 0x8617: 'Vib_Step',
    0x8639: 'Vib_ShiftDepth', 0x8643: 'Vib_Delay', 0x8650: 'Vib_DelaySfx', 0x8653: 'Vib_DelayHave',
    0x8683: 'Vib_Dir', 0x8688: 'Vib_Sub', 0x869B: 'Vib_Add', 0x86AB: 'Vib_Store',
    0x83DC: 'Dead_NoiseNoSlide', 0x86AD: 'Upd_IncFrame', 0x86AF: 'Upd_WriteRegs', 0x86C5: 'Upd_WriteLo', 0x86E2: 'Upd_WriteTri',
    0x86EC: 'Upd_NextChan', 0x86F2: 'Upd_DmcVestige', 0x8701: 'Upd_Done', 0x8702: 'Dmc_Stop',
})
for p, (n, m, s, a) in CODE.items():
    if (m == 'rel' or n in ('jsr', 'jmp')) and a not in CLAB and B <= a < 0xA000:
        CLAB[a] = 'L_%04X' % a

CCOM = {  # hand comments
    0x807A: 'Y = song.  Starts the four tone tracks of the song',
    0x80BB: 'DMC column: Chan_Start returns at once for X = 5',
    0x80C8: 'clear driver RAM, silence the APU',
    0x80D4: 'clears $A7-$FB (also the game flag at $FB)',
    0x80DA: 'enable PRG-RAM (state lives at $7F4C-$7FBE)',
    0x80E3: 'clears $7F4C-$7FBE ($7F4B is left alone)',
    0x810C: 'chRegOfs+1..3 = 4, 8, 12 (chRegOfs+0 = 0 from the clear)',
    0x811E: 'X = channel.  Reached by JMP: its RTS ends Sound_Update for this frame',
    0x8136: 'writes $00 to $4003+ofs but keeps chLastPerHi (stale write cache)',
    0x8140: 'SFX finished: give the channel back to the music',
    0x814E: 'A = track number, X = channel',
    0x8163: 'track * 3',
    0x8191: 'chLastPerHi is not reset here either',
    0x81A5: 'X = effect number, >= $7F cancels the running effect',
    0x81CE: 'hardware channel the effect takes over',
    0x823C: 'channels 4 (SFX), 3, 2, 1, 0',
    0x8247: 'fractional speed: every chSpeedLo+1 frames the tick counter is not advanced',
    0x825B: 'tick when the counter is 0',
    0x8262: 'note still sounding?',
    0x827B: '$00-$9F pattern, $A0-$FD transpose, $FE end, $FF loop',
    0x8283: '$FE: stop the channel',
    0x8285: '$FF: loop to the start of the track',
    0x8296: 'carry is clear here: transpose = byte - $A0',
    0x82B6: '$00-$5E = note',
    0x82BF: '$FD target, delay, speed',
    0x82DD: '$FE prefix: legato (keep the pitch envelope running)',
    0x82E6: '$FF: end of pattern, next track entry',
    0x82F5: '$FC vol: VolTable row',
    0x8306: '$E0-$FB rest; length = byte - $E0 ticks ($E0 = 256)',
    0x8334: '$C0-$DF instrument (also selects its pitch envelope)',
    0x8342: '$80-$BF duration = byte - $80 ticks ($80 = 256)',
    0x8355: '$60-$7F explicit pitch envelope (0 = none), forces a restart',
    0x8389: 'dead code: the result is overwritten',
    0x83BF: 'dead load',
    0x83DC: 'unreachable (follows a JMP): would skip slides on noise / SFX-on-noise',
    0x83EA: 'portamento towards chSlideTarget once chSlideDelay ticks have passed',
    0x8415: 'speed = 7 << (chSlideSpeed - 1)',
    0x848E: 'volume envelope (not for triangle)',
    0x8494: 'no-op branch',
    0x84BD: 'envelope bytes: $FD loop point, $FE hold, $FF loop',
    0x84D8: 'scale by the VOL row',
    0x84EC: 'duty envelope (pulse channels only)',
    0x854B: 'pitch / arpeggio envelope',
    0x8595: 'N flag here comes from CMP #$FD, so $7D-$FC count as absolute',
    0x85B6: 'a slide in progress overrides the envelope',
    0x85D0: 'vibrato (not for noise)',
    0x861C: 'depth = (period[n-1] - period[n]) >> ((param >> 4) & 7)',
    0x8653: 'instrument byte 5 high nibble = delay in ticks',
    0x86AF: 'a music channel borrowed by the SFX does not touch the APU',
    0x86BA: 'period high is only written when it changes (avoids phase reset)',
    0x86D5: 'force constant volume + length halt',
    0x86E5: 'force linear-counter control',
    0x86F2: 'vestigial DMC handling; zDmcFlag is never set',
    0x8702: 'vestigial DMC stop',
}

def ramname(a):
    for base, n, sz, c in RAM:
        if base <= a < base + sz:
            return n if a == base else '%s+%d' % (n, a - base)
    if a in EXTRA_RAM: return EXTRA_RAM[a]
    if a in HW: return HW[a]
    if 0x4000 <= a < 0x4018:
        for hb, hn in [(0x4000, 'SQ1_VOL'), ]:
            pass
    return None

def datname(a):
    best = None
    for ba in sorted(DSYM):
        if ba <= a: best = ba
    if best is None: return None
    off = a - best
    if off > 0x120: return None
    return DSYM[best] if off == 0 else '%s+%d' % (DSYM[best], off)

def opname(a, wide):
    if a in CLAB: return CLAB[a]
    n = ramname(a)
    if n: return n
    if 0x4000 <= a < 0x4018:
        return 'APU+$%02X' % (a - 0x4000)
    if a == 0xA001: return HW[a]
    if B <= a < 0xA000:
        n = datname(a)
        if n: return n
    return ('$%04X' if wide else '$%02X') % a

def fmt_ins(n, m, a):
    def L(x, wide): return opname(x, wide)
    pre = lambda x: ('a:' if x < 0x100 else '')
    if m == 'imp': return n
    if m == 'imm': return '%s #$%02X' % (n, a)
    if m == 'zp': return '%s %s' % (n, L(a, 0))
    if m == 'zpx': return '%s %s,x' % (n, L(a, 0))
    if m == 'zpy': return '%s %s,y' % (n, L(a, 0))
    if m == 'izx': return '%s (%s,x)' % (n, L(a, 0))
    if m == 'izy': return '%s (%s),y' % (n, L(a, 0))
    if m == 'ind': return '%s (%s)' % (n, L(a, 1))
    if m == 'rel': return '%s %s' % (n, L(a, 1))
    if m == 'abs': return '%s %s%s' % (n, pre(a), L(a, 1))
    if m == 'abx': return '%s %s%s,x' % (n, pre(a), L(a, 1))
    if m == 'aby': return '%s %s%s,y' % (n, pre(a), L(a, 1))

# ---------------------------------------------------------------- music data model
songs = [[r(0x8034 + c * 14 + s) for c in range(5)] for s in range(NSONG)]
def track(t): a = 0x89D5 + 3 * t; return w(a), r(a + 2)
def patptr(p): return r(0x88A1 + p) | r(0x8925 + p) << 8

OWN = {}           # addr -> object key (for the interleaved data regions)
OBJ = {}           # key -> (start, end, kind, extra)
LAB = {}           # addr -> label for data objects

def claim(a, e, key, kind, extra=None):
    for x in range(a, e):
        if x in OWN and OWN[x] != key:
            raise SystemExit('overlap at %04X: %s vs %s' % (x, OWN[x], key))
        OWN[x] = key
    OBJ[key] = (a, e, kind, extra)

def read_list(a):
    y = 0
    while r(a + y) < 0xFE: y += 1
    return a + y + 1

def pat_events(a):
    """Decode one pattern exactly the way Pat_Start..Pat_Note parse it."""
    ev = []
    while True:
        s = a; b = r(a); tok = []
        def nt(v):  # note byte after a prefix: any value is taken as a note
            return note(v) if v < 0x5F else '$%02X' % v
        if b < 0x5F:
            tok.append(note(b)); a += 1; ev.append((s, a, tok)); continue
        if b == 0xFD:
            tok += ['SLIDE', note(r(a + 1)), str(r(a + 2)), str(r(a + 3)), nt(r(a + 4))]
            a += 5; ev.append((s, a, tok)); continue
        if b == 0xFE:
            tok.append('LEGATO'); a += 1; b = r(a)
        if b == 0xFF:
            tok.append('PEND'); a += 1; ev.append((s, a, tok)); return ev, a
        if b == 0xFC:
            tok += ['VOL', str(r(a + 1))]; a += 2; b = r(a)
        if b >= 0xE0:
            tok.append('REST+%d' % (b - 0xE0) if b < 0xFC else 'REST+$%02X' % (b - 0xE0))
            a += 1; ev.append((s, a, tok)); continue
        if b >= 0xC0:
            tok.append('INS+%d' % (b - 0xC0)); a += 1; b = r(a)
        if b >= 0x80:
            tok.append('DUR+%d' % (b - 0x80) if b < 0xC0 else 'DUR+$%02X' % (b - 0x80))
            a += 1; b = r(a)
            if b == 0xFD:
                tok += ['SLIDE', note(r(a + 1)), str(r(a + 2)), str(r(a + 3)), nt(r(a + 4))]
                a += 5; ev.append((s, a, tok)); continue
        if b >= 0x60:
            tok.append('PENV+%d' % (b - 0x60) if b < 0x80 else 'PENV+$%02X' % (b - 0x60))
            a += 1; b = r(a)
        tok.append(nt(b)); a += 1
        ev.append((s, a, tok))

used_tracks = set()
for s in songs:
    used_tracks.update(t for t in s[:4] if t != 0xFF)
sfx = [(r(0x8000 + i), r(0x801A + i)) for i in range(NSFX)]
used_tracks.update(t for t, c in sfx)
pat_users = {}
for t in range(NTRACK):
    a, sp = track(t)
    if a == 0: continue
    LAB[a] = 'Track_%02X' % t
    e = read_list(a)
    claim(a, e, ('T', t), 'track')
    for x in range(a, e - 1):
        if r(x) < 0xA0: pat_users.setdefault(r(x), set()).add(t)
for p in range(NPAT):
    a = patptr(p)
    if p not in pat_users:
        continue
    LAB[a] = 'Pat_%02X' % p
    ev, e = pat_events(a)
    claim(a, e, ('P', p), 'pat', ev)
# DMC leftovers (format identical to tone patterns; tracks are plain pattern lists)
for i in range(4):
    a = w(0x89C5 + 4 * i)
    LAB[a] = 'DmcTrack_%d' % i
    claim(a, read_list(a), ('DT', i), 'dmctrack')
for i in range(14):
    a = w(0x89A9 + 2 * i)
    LAB[a] = 'DmcPat_%02X' % i
    ev, e = pat_events(a)
    claim(a, e, ('DP', i), 'pat', ev)

# envelopes ---------------------------------------------------------------
def env_end(a, limit=None):
    y = 0
    while r(a + y) not in (0xFE, 0xFF): y += 1
    return a + y + 1

# ---------------------------------------------------------------- writer
out = []
def emit(s=''): out.append(s)
def hexb(bs): return ', '.join('$%02X' % b for b in bs)

emit('; McDonaldLand (E) / M.C. Kids - sound engine by Charles Deenen')
emit('; ca65 source generated by tool/gen_disasm.py; assembles byte-identical to the ROM.')
emit('; Segment BANK10 = PRG bank 10 at $8000-$%04X (code + tables + data),' % (END10 - 1))
emit('; segment BANK04 = PRG bank 4 at $A000-$%04X (more music/SFX data).' % (END04 - 1))
emit('; The game maps both banks (MMC3 R6 = 10, R7 = 4) before every call.')
emit()
emit('.setcpu "6502"')
emit()
emit('; ---------------------------------------------------------------- hardware')
emit('APU            = $4000')
for a, n in sorted(HW.items()):
    emit('%-14s = $%04X' % (n, a))
emit()
emit('; ---------------------------------------------------------------- RAM')
for a, n, sz, c in RAM:
    emit('%-14s = $%04X%s' % (n, a, ('   ; [%d] ' % sz if sz > 1 else '   ; ') + c if (c or sz > 1) else ''))
for a, n in sorted(EXTRA_RAM.items()):
    emit('%-14s = $%04X   ; alias inside an array (slot unused by that routine)' % (n, a))
emit()
emit('; ---------------------------------------------------------------- data encoding')
emit('; track bytes')
emit('TRANSP = $A0          ; TRANSP+n : transpose following patterns by n')
emit('TEND   = $FE          ; stop the channel')
emit('TLOOP  = $FF          ; restart the track')
emit('; pattern bytes (one event = [LEGATO] [VOL v] (REST+n | [INS+i] [DUR+n] [PENV+e] [SLIDE note,delay,speed] note))')
emit('DUR    = $80          ; DUR+n : notes last n ticks from now on (DUR+0 = 256)')
emit('PENV   = $60          ; PENV+e: pitch envelope e for this note (0 = none), restarts it')
emit('INS    = $C0          ; INS+i : instrument i (with its own pitch envelope)')
emit('REST   = $E0          ; REST+n: rest n ticks (REST+0 = 256)')
emit('VOL    = $FC          ; VOL v : volume 0-15 (scales the envelope via VolTable)')
emit('SLIDE  = $FD          ; SLIDE target, delay ticks, speed (7 << (speed-1) per frame)')
emit('LEGATO = $FE          ; do not restart the pitch envelope on the next note')
emit('PEND   = $FF          ; end of pattern')
emit('; envelope bytes')
emit('EMARK  = $FD          ; loop point')
emit('EHOLD  = $FE          ; stop, hold last value')
emit('ELOOP  = $FF          ; jump to the loop point (default: start)')
emit('ABS    = $80          ; pitch env: ABS|note = absolute note, else semitone offset')
emit('; notes (C2 = 0; period table covers C2-G#7)')
for n in range(0x5F):
    emit('%-6s = $%02X' % (note(n), n))
emit()

def emit_code(start, end):
    for p in sorted(x for x in CODE if start <= x < end):
        n, m, s, a = CODE[p]
        if p in CLAB:
            if p in ENTRIES or not CLAB[p].startswith('L_'): emit()
            emit('%s:' % CLAB[p])
        txt = fmt_ins(n, m, a)
        c = CCOM.get(p)
        emit('        %-30s; $%04X%s' % (txt, p, ('  ' + c) if c else ''))

def emit_bytes(a, e, per=16, label=None, comment=None):
    if label: emit('%s:' % label)
    first = True
    for x in range(a, e, per):
        emit('        .byte %s%s' % (hexb(MEM[x - B:min(e, x + per) - B]),
                                 ('   ; ' + comment) if (comment and first) else ''))
        first = False

emit('.segment "BANK10"')
emit()
emit('; $8000 effect -> track, $801A effect -> hardware channel (1 = Sq2, 3 = noise)')
emit('SfxTrackTbl:')
emit('        .byte %s' % ', '.join('$%02X' % t for t, c in sfx[:13]))
emit('        .byte %s' % ', '.join('$%02X' % t for t, c in sfx[13:]))
emit('SfxHwChTbl:')
emit('        .byte %s' % ', '.join('%d' % c for t, c in sfx[:13]))
emit('        .byte %s' % ', '.join('%d' % c for t, c in sfx[13:]))
emit()
emit('; song -> track per channel ($FF = unused).  The DMC column is vestigial:')
emit('; Chan_Start ignores X = 5, and its numbers index DmcTrackTbl.')
for c, n in enumerate(['Sq1', 'Sq2', 'Tri', 'Noise', 'Dmc']):
    emit('SongTbl_%s:' % n)
    emit('        .byte %s' % ', '.join('$%02X' % songs[s][c] for s in range(NSONG)))
emit()
emit_code(0x807A, 0x8710)
emit()
emit('; ---------------------------------------------------------------- tables')
emit('; DmcSampleTbl: 7 x (rate/flags, length, address, initial level?)  - unreferenced,')
emit('; left over from the removed DMC drum track (addresses point at $F000-$F800, now code)')
emit('DmcSampleTbl:')
for i in range(7):
    emit('        .byte %s   ; %d' % (hexb(MEM[0x8710 + 4 * i - B:0x8714 + 4 * i - B]), i))
emit()
emit('; period table, note 0 = C2.  PeriodHi has 69 entries: the last 21 are the')
emit('; first 21 zero bytes of VolTable.')
emit('PeriodLo:')
for x in range(0x872C, 0x8771, 12):
    emit('        .byte %s' % hexb(MEM[x - B:min(0x8771, x + 12) - B]))
emit('PeriodHi:')
for x in range(0x8771, 0x87A1, 12):
    emit('        .byte %s' % hexb(MEM[x - B:min(0x87A1, x + 12) - B]))
emit('; VolTable[row*16 + v] = v * row / 15 (rounded); row = VOL, v = envelope value')
emit('VolTable:')
for i in range(16):
    emit('        .byte %s   ; row %d' % (hexb(MEM[0x87A1 + 16 * i - B:0x87B1 + 16 * i - B]), i))
emit()

def plabel(p):
    a = patptr(p)
    return LAB.get(a) or ('Track_24' if a == track(0x24)[0] else '$%04X' % a)
emit('; pattern pointers.  Entry $7F is unused and points at Track_24.')
emit('PatPtrLo:')
for i in range(0, NPAT, 8):
    emit('        .lobytes %s' % ', '.join(plabel(p) for p in range(i, min(NPAT, i + 8))))
emit('PatPtrHi:')
for i in range(0, NPAT, 8):
    emit('        .hibytes %s' % ', '.join(plabel(p) for p in range(i, min(NPAT, i + 8))))
emit()
emit('; leftovers of the removed DMC drum track: 14 pattern pointers and 4 tracks')
emit('; (pointer, two bytes - probably speed).  Nothing reads these.')
emit('DmcPatPtr:')
for i in range(0, 14, 7):
    emit('        .word %s' % ', '.join('DmcPat_%02X' % j for j in range(i, i + 7)))
emit('DmcTrackTbl:')
for i in range(4):
    emit('        .word DmcTrack_%d' % i)
    emit('        .byte $%02X, $%02X' % (r(0x89C7 + 4 * i), r(0x89C8 + 4 * i)))
emit()
emit('; tracks: pointer + speed byte.  speed $hl: a tick every h+1 frames, and every')
emit('; l+1 frames (l > 0) the tick counter is held for one frame.')
emit('TrackTbl:')
for t in range(NTRACK):
    a, sp = track(t)
    us = []
    for s in range(NSONG):
        for c in range(4):
            if songs[s][c] == t: us.append('song %d %s' % (s, ['Sq1', 'Sq2', 'Tri', 'Noise'][c]))
    for i, (tt, c) in enumerate(sfx):
        if tt == t: us.append('sfx %d' % i)
    emit('        .word %-9s\n        .byte $%02X     ; $%02X %s' % (LAB.get(a, '$0000'), sp, t, ', '.join(us) or 'unused'))
emit()

def penv_tok(v, absok=True):
    if v == 0xFD: return 'EMARK'
    if v == 0xFE: return 'EHOLD'
    if v == 0xFF: return 'ELOOP'
    if v >= 0x80: return 'ABS|%s' % note(v & 0x7F)
    return '%d' % v

def emit_ptr_env_set(lo, hi, n, prefix, title):
    ptrs = [r(lo + i) | r(hi + i) << 8 for i in range(n)]
    emit('; %s: pointers (1-based numbers in the instruments; entry i = env i+1)' % title)
    names = {}
    for i, a in enumerate(ptrs):
        names.setdefault(a, '%s_%02d' % (prefix, i + 1))
    emit(DSYM[lo] + ':')
    for i in range(0, n, 8):
        emit('        .lobytes %s' % ', '.join(names[a] for a in ptrs[i:i + 8]))
    emit(DSYM[hi] + ':')
    for i in range(0, n, 8):
        emit('        .hibytes %s' % ', '.join(names[a] for a in ptrs[i:i + 8]))
    starts = sorted(set(ptrs))
    a = starts[0]
    end = max(env_end(x) for x in starts)
    while a < end:
        if a in names.values() or a in starts:
            emit('%s:' % names[a])
        nxt = min([x for x in starts if x > a] + [env_end(a)])
        toks = [penv_tok(r(x)) for x in range(a, nxt)]
        emit('        .byte %s' % ', '.join(toks))
        a = nxt
    return end

end = emit_ptr_env_set(0x8AC8, 0x8AE9, NMPENV, 'PEnv', 'music pitch / arpeggio envelopes')
assert end == 0x8C10, hex(end)
emit()

def env_tok(v):
    return {0xFD: 'EMARK', 0xFE: 'EHOLD', 0xFF: 'ELOOP'}.get(v, '$%02X' % v)

def emit_ofs_env_set(ofs, data, n, prefix, title, end_addr):
    offs = [r(ofs + i) for i in range(n)]
    emit('; %s: 8-bit offsets into the data block (a position wraps at 256)' % title)
    emit(DSYM[ofs] + ':')
    emit('        .byte %s' % ', '.join('%s_%02d-%s' % (prefix, i + 1, DSYM[data]) for i in range(n)))
    names = {}
    for i, o in enumerate(offs): names.setdefault(data + o, '%s_%02d' % (prefix, i + 1))
    emit(DSYM[data] + ':')
    starts = sorted(names)
    a = data
    while a < end_addr:
        if a in names:
            for i, o in enumerate(offs):
                if data + o == a: emit('%s_%02d:' % (prefix, i + 1))
        nxt = min([x for x in starts if x > a] + [env_end(a), end_addr])
        emit('        .byte %s' % ', '.join(env_tok(r(x)) for x in range(a, nxt)))
        a = nxt

emit_ofs_env_set(0x8C10, 0x8C1F, NVENV, 'VEnv', 'volume envelopes (values 0-15)', 0x8D1F)
emit('; offset 256+: unreachable.  VEnv_12 (used only by the unused instrument 30)')
emit('; runs past offset 255 and wraps into VEnv_01; its intended tail is here,')
emit('; followed by one more envelope that no offset can reach.')
emit('VEnvOrphan:')
emit('        .byte %s' % ', '.join(env_tok(r(x)) for x in range(0x8D1F, 0x8D34)))
emit('VEnvOrphan2:')
emit('        .byte %s' % ', '.join(env_tok(r(x)) for x in range(0x8D34, 0x8D4E)))
emit()
emit_ofs_env_set(0x8D4E, 0x8D59, NDENV, 'DEnv', 'duty envelopes (values = duty bits 7-6)', 0x8DF9)
emit()

def emit_instr(tbl, n, title):
    emit('; %s: 6 bytes each' % title)
    emit(';   0 duty bits (EOR $30)  1 duty env  2 volume env  3 pitch env  (envs 1-based, 0 = none)')
    emit(';   4 vibrato: bits 0-2 speed, bits 4-6 depth shift   5 bits 4-7 vibrato delay (ticks)')
    emit(DSYM[tbl] + ':')
    for i in range(n):
        emit('        .byte %s   ; %d' % (hexb(MEM[tbl + 6 * i - B:tbl + 6 * i + 6 - B]), i))

emit_instr(0x8DF9, NSINS, 'SFX instruments (pitch envelopes from SfxPEnvPtr)')
emit()
end = emit_ptr_env_set(0x8E7D, 0x8E8D, NSPENV, 'SPEnv', 'SFX pitch envelopes')
assert end == 0x901E, hex(end)
emit()
emit_instr(0x901E, NINS, 'music instruments')
emit()

def emit_region(a, e):
    while a < e:
        if a not in OWN:
            b = a
            while b < e and b not in OWN: b += 1
            emit()
            emit_bytes(a, b, label='Orphan_%04X' % a, comment='unreferenced')
            a = b; continue
        key = OWN[a]; s, en, kind, extra = OBJ[key]
        emit()
        emit('%s:' % LAB[a])
        if kind in ('track', 'dmctrack'):
            toks = []
            for x in range(a, en):
                v = r(x)
                toks.append('TEND' if v == 0xFE else 'TLOOP' if v == 0xFF else
                            'TRANSP+%d' % (v - 0xA0) if v >= 0xA0 else '$%02X' % v)
            for i in range(0, len(toks), 12):
                emit('        .byte %s' % ', '.join(toks[i:i + 12]))
        else:
            for (s0, e0, tok) in extra:
                emit('        .byte %s' % ', '.join(tok))
        a = en

emit('; ---------------------------------------------------------------- music data (bank 10)')
emit('; tracks hold pattern numbers; DmcTrack_n hold DmcPat numbers')
emit_region(0x90DE, END10)
emit()
emit('.segment "BANK04"')
emit()
emit('; ---------------------------------------------------------------- music data (bank 4)')
emit_region(0xA000, END04)

src = '\n'.join(out) + '\n'
os.makedirs(OUT, exist_ok=True)
open(os.path.join(OUT, 'mcdonaldland_sound.s'), 'w', newline='\n').write(src)
open(os.path.join(OUT, 'mcdonaldland_sound.cfg'), 'w', newline='\n').write(
    'MEMORY {\n'
    '    B10: start = $8000, size = $%04X, file = "bank10_sound.bin", fill = no;\n'
    '    B04: start = $A000, size = $%04X, file = "bank04_sound.bin", fill = no;\n'
    '}\nSEGMENTS {\n'
    '    BANK10: load = B10, type = ro;\n'
    '    BANK04: load = B04, type = ro;\n}\n' % (END10 - 0x8000, END04 - 0xA000))
print('wrote', len(out), 'lines')
