"""Generate the Tetris Attack (GB) sound sources: home routine $1500-$1644, bank $07 (SFX engine +
music driver copy for songs $1D-$23), bank $08 (music driver for songs $01-$1C)."""
import sys, os, json, re
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE); sys.path.insert(0, os.path.join(HERE, '..', 'LADX')); sys.path.insert(0, os.path.join(HERE, '..', 'tools'))
from gbdis import Region
import transfer
import ta_music as TM, ta_sfx as TS
ROM = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..', 'Tetris Attack (U) (V1.1) [S].gb')
OUT = sys.argv[2] if len(sys.argv) > 2 else HERE
rom = open(ROM, 'rb').read()
def w(name, body): open(os.path.join(OUT, name), 'w').write(body)


def hexrows(rr, a, n, per=16):
    return ['\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(min(per, n-i))) for i in range(0, n, per)]


def fill_gaps(r, lo, hi):
    """unclaimed bytes: fills become ds, the rest db rows under an Unused_ label"""
    cov = set()
    for pc, d in r.code.items(): cov.update(range(pc, pc + d[0]))
    for b, (s, e) in r.blocks.items(): cov.update(range(b, b + s))
    a = lo; gaps = []
    while a < hi:
        if a not in cov:
            b = a
            while b < hi and b not in cov and (b == a or b not in r.labels): b += 1
            gaps.append((a, b)); a = b
        else: a += 1
    for a, b in gaps:
        vals = {r.byte(x) for x in range(a, b)}
        if len(vals) == 1 and b - a >= 4:
            v = vals.pop()
            r.block(a, b - a, lambda rr, a, n=b-a, v=v: [f'\tds {n}, ${v:02x}'])
        else:
            if a not in r.labels: r.label(a, f'Unused_{a:04X}', 'unreferenced')
            r.block(a, b - a, lambda rr, a, n=b-a: hexrows(rr, a, n))
    return gaps


def local_names(r):
    cnt = {}; parent = None
    for a in sorted(r.labels):
        n = r.labels[a]
        if n.startswith('Code_') and parent:
            cnt[parent] = cnt.get(parent, -1) + 1
            r.labels[a] = f'{parent}.l{cnt[parent]}'
        elif '.' not in n and a in r.code:
            parent = n


def split_emit(r, splits, title, asm, header):
    parts = r.emit_split([(a, b) for a, b, _, _ in splits])
    for (a, b, f, what), body in zip(splits, parts):
        w(f, f'; {title}: {what}, ${a:04X}-${b-1:04X}\n\n' + body)
    w(asm, f'; {header}\nINCLUDE "GB_Hardware.inc"\nINCLUDE "TA_RAM.inc"\nINCLUDE "TA_Macros.inc"\n\n' +
      (f'SECTION "TA sound bank ${r.bank:02X}", ROMX[$4000], BANK[${r.bank:02X}]\n' if r.bank else 'SECTION "TA sound home", ROM0[$1500]\n') +
      ''.join(f'\tASSERT @ == ${a:04X}\nINCLUDE "{f}"\n' for a, b, f, _ in splits))


def music_model(r, songs, ids, name):
    lab = {n: a for a, n in r.labels.items()}
    os.makedirs(os.path.join(OUT, 'harness'), exist_ok=True)
    json.dump({'pat_pc': lab['ReadPtrByte'] + 4, 'list_pc': lab['CopyWordIndirect'] + 4, 'song_ids': ids,
               'patterns': {f'{p:04x}': [p, songs.pat_events[p][1]] for p in songs.pat_events},
               'list_words': sorted(set(sum(([a, a+1] + ([a+2, a+3] if songs.list_words[a][0] == 'loop' else []) for a in songs.list_words), []))),
               'sfxdata': []}, open(os.path.join(OUT, 'harness', name), 'w'))

# ---------------------------------------------------------------- bank $08
r8, s8 = TM.gen_8(rom)
DRM_WAVES = ("unreferenced: Dr. Mario's six waves (its $6BC3-$6C22), in Dr. Mario's order, then the first\n"
             "bytes of a Dr. Mario-style length-table area")
VIB_PAD = ("the 30 zero bytes that follow Dr. Mario's wobble table. Here NoteFrames / 2 never exceeds\n"
           "127 and VibratoTable has 135 bytes, so they are never read")
r8.label(0x488e, 'Unused_DrMarioWaves', DRM_WAVES)
r8.label(0x4755, 'VibratoTable_Pad', VIB_PAD)
r8.block(0x4755, 30, lambda rr, a: ['\tds 30, $00'])
r8.label(0x7ca0, 'Unused_Waves_7CA0', 'unreferenced waves')
r8.label(0x7cd0, 'Unused_Wave_7CD0', 'unreferenced wave')
r8.label(0x7c70, 'DummySongHeader', 'songs $1D-$23 point here: never started in this bank (the bytes are a wave)')
fill_gaps(r8, 0x4000, 0x8000)
local_names(r8)
music_model(r8, s8, list(range(1, 0x1d)), 'model_08.json')
split_emit(r8, [(0x4000, 0x495c, 'TA_08_Driver.inc', 'music driver and tables'), (0x495c, 0x8000, 'TA_08_Songs.inc', 'songs $01-$1C')],
           'Tetris Attack music, bank $08', 'TA_Bank08.asm', 'Tetris Attack: bank $08, music driver copy A (songs $01-$1C)')

# ---------------------------------------------------------------- bank $07
r7, ents, kinds = TS.build(rom)
ref = Region(rom, 7, 0x4000, 0x8000); ref.trace([0x6bc2, 0x68d7])
pm, vm, m, a, b = transfer.align(r8, ref)
names7, _ = transfer.transfer_labels(r8, ref, pm, vm, {})
names7 = {k: v for k, v in names7.items() if k >= 0x67a9 and not v.startswith(('Code_', 'Data_', 'Song', 'Pattern', 'Wave', 'Length'))}
com7 = {}
for k, t in TM.COMMENTS_8.items():
    if k in pm and pm[k] >= 0x67a9: com7[pm[k]] = t
    elif k in vm and vm[k] >= 0x67a9: com7[vm[k]] = t
com7[0x6816] = 'songs $01-$23; this bank plays $1D-$23, the others point at a dummy header'
names7.update({0x685c: 'Unused_SetRegs', 0x68ab: 'Music_SaveState_Unused', 0x68bf: 'Music_RestoreState_Unused', 0x6ce0: 'Music_Trigger.unused', 0x67a3: 'Music_StartFadeOut'})
com7.update({0x67a3: 'unreferenced: start the fade-out (wFadeStep = 1). The game sets wFadeStep itself (home $0545).',
             0x685c: 'unreferenced: the SFX register writers and Sfx_GetInitPointer of the LA-style SFX code',
             0x68ab: 'unreferenced: save / restore the music state (as bank $08)', 0x6ce0: 'unreachable: ld b, $33 / ld a, $1D / write NR10'})
r7, s7 = TM.build(rom, 7, names7, com7, [0x6bc2, 0x68d7], 0x6816, TM.song_id_7, 0x6e99, 0x6f2b, 0x6f63, 0x702a, 0x6da3, 0x6e2a,
                  0x6994, 35, 0x67f7, region=r7, first=0x1d, count=7, extra_code=[(0x685c, 0x6882), (0x68ab, 0x68d4), (0x6ce0, 0x6ce7), (0x67a3, 0x67a9)])
TS.stream_blocks(r7, kinds, 0x4fc2, 0x67a9)
r7.label(0x5c5a, 'Unused_Ch1Stream_5C5A', 'unreferenced ch1 stream (6-byte rows, last frame byte $FF)')
r7.block(0x5c5a, 42, lambda rr, a: ['\tdb ' + ', '.join(f'${rr.byte(a+i+k):02x}' for k in range(6)) for i in range(0, 42, 6)])
r7.label(0x6f63, 'Unused_DrMarioWaves', DRM_WAVES)
r7.label(0x6e2a, 'VibratoTable_Pad', VIB_PAD)
r7.block(0x6e2a, 30, lambda rr, a: ['\tds 30, $00'])
r7.label(0x7f31, 'Unused_7F31', "unreferenced: the same 16 bytes as bank $08's Wave_7C80")
r7.label(0x7031, 'DummySongHeader', 'songs $01-$1C point here: never started in this bank')
gaps7 = fill_gaps(r7, 0x4000, 0x8000)
local_names(r7)
music_model(r7, s7, list(range(0x1d, 0x24)), 'model_07.json')
print('bank 7 gaps', [(hex(a), b - a) for a, b in gaps7 if b - a > 0][:60])
split_emit(r7, [(0x4000, 0x4255, 'TA_07_Engine.inc', 'SFX engine entry, tables'),
                (0x4255, 0x4fc2, 'TA_07_SfxInit.inc', 'SFX init routines and stream player'),
                (0x4fc2, 0x67a3, 'TA_07_SfxData.inc', 'SFX streams'),
                (0x67a3, 0x7031, 'TA_07_Driver.inc', 'music driver copy B and tables'),
                (0x7031, 0x8000, 'TA_07_Songs.inc', 'songs $1D-$23')],
           'Tetris Attack SFX and music, bank $07', 'TA_Bank07.asm', 'Tetris Attack: bank $07, SFX engine and music driver copy B (songs $1D-$23)')
hooks = sorted(pc for pc, (l, fmt, args, k) in r7.code.items() if pc in (0x407f,))
json.dump({'hl_pcs': [0x407f], 'sfxdata': sorted([a, a + sz, r7.labels.get(a, '')] for a, (sz, e) in r7.blocks.items() if a < 0x67a9),
           'patterns': {}, 'list_words': []}, open(os.path.join(OUT, 'harness', 'model_07sfx.json'), 'w'))

# ---------------------------------------------------------------- home routine $1500-$1644
h = Region(rom, 0, 0x1500, 0x1645)
h.ram = dict(TS.RAM)
h.trace([0x1500])
HN = {0x1500: 'Sound_Frame', 0x1515: 'Sound_Frame.update', 0x1539: 'Sound_Frame.bank08', 0x154e: 'Sound_Frame.bank07',
      0x1561: 'Sound_Frame.clearRequests', 0x157b: 'Sound_Pause', 0x1591: 'Sound_Unpause', 0x15a7: 'Sound_Frame.newSong',
      0x15b6: 'Sound_Frame.start08', 0x15cc: 'Sound_Frame.start07',
      0x15e2: 'Home_ReleaseCh1', 0x15eb: 'Home_TakeCh1', 0x15fc: 'Home_ReleaseCh2', 0x1605: 'Home_TakeCh2',
      0x1615: 'Home_ReleaseCh3', 0x161e: 'Home_TakeCh3', 0x162c: 'Home_ReleaseCh4', 0x1635: 'Home_TakeCh4'}
for a, n in HN.items(): h.label(a, n)
h.comments[0x1500] = ('Called once per frame by the game (home $0253 / $0291). wPauseRequest 1 = pause (take and\n'
                      'silence all channels), 2 = resume. Then: SFX (bank $07: Sfx_Update, Noise_Update), a new\n'
                      'song request (songs below $1D start in bank $08, others in bank $07; the song already\n'
                      'playing is not restarted), the music of the bank that owns the playing song, and the\n'
                      'requests are cleared, except a song request $1C or $22 which stays set.')
h.code_range(0x1537, 0x1539); h.comments[0x1537] = 'unreachable: jr $1561'
h.code_range(0x15b3, 0x15b6); h.comments[0x15b3] = 'unreachable'
for n, a in (('Rom_MBC_Bank', 0x2100),): h.extern[a] = 'rROMB0'
h.extern[0xfffd] = 'hRomBank'
hparts = h.emit(0x1500, 0x1645)
hparts = hparts.replace('[$2100]', '[rROMB0]').replace('[$fffd]', '[hRomBank]')
w('TA_Home.inc', '; Tetris Attack: sound routine in the home bank, $1500-$1644\n\n' + hparts)
w('TA_Home.asm', '; Tetris Attack: home-bank sound routine\nINCLUDE "GB_Hardware.inc"\nINCLUDE "TA_RAM.inc"\n'
  'DEF rROMB0 EQU $2100\nDEF hRomBank EQU $FFFD\n\nSECTION "TA sound home", ROM0[$1500]\nINCLUDE "TA_Home.inc"\n\tASSERT @ == $1645\n')

# ---------------------------------------------------------------- RAM
ram = dict(TS.RAM)
lines = ['; Tetris Attack sound RAM ($D300-$D40F)', 'IF !DEF(TA_RAM_INC)', 'DEF TA_RAM_INC EQU 1']
for a in sorted(ram):
    if '+' not in ram[a]: lines.append(f'DEF {ram[a]:<20} EQU ${a:04X}')
lines.append('ENDC')
w('TA_RAM.inc', '\n'.join(lines) + '\n')
